package main

import (
	"bytes"
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"os/signal"
	"path/filepath"
	"strings"
	"sync"
	"syscall"
	"time"
)

const (
	maxBodyBytes   = 8 << 20 // 与上游 max_body_mb=8 对齐
	ringBufferSize = 64 << 10
	maxInFlight    = 64
)

// ring 有界环形缓冲：只保留响应末尾若干字节用于抓取 usage，
// 既不缓存整条 SSE 流，又能拿到结尾的用量数据。
type ring struct {
	buf  []byte
	pos  int
	full bool
}

func newRing(n int) *ring { return &ring{buf: make([]byte, n)} }

func (r *ring) Write(p []byte) (int, error) {
	for _, b := range p {
		r.buf[r.pos] = b
		r.pos++
		if r.pos >= len(r.buf) {
			r.pos = 0
			r.full = true
		}
	}
	return len(p), nil
}

func (r *ring) bytes() []byte {
	if !r.full {
		return r.buf[:r.pos]
	}
	out := make([]byte, len(r.buf))
	copy(out, r.buf[r.pos:])
	copy(out[len(r.buf)-r.pos:], r.buf[:r.pos])
	return out
}

type sniffRC struct {
	io.ReadCloser
	ring *ring
}

func (s *sniffRC) Read(p []byte) (int, error) {
	n, err := s.ReadCloser.Read(p)
	if n > 0 {
		_, _ = s.ring.Write(p[:n])
	}
	return n, err
}

// reqState 单次请求的可变状态。
type reqState struct {
	start     time.Time
	status    int
	firstMS   int64
	firstSet  bool
	ring      *ring
	errMsg    string
	promptTok int
	compTok   int
	credit    float64
}

type stateKey struct{}

type guard struct {
	mu       sync.Mutex
	env      *Env
	keys     *keyStore
	policy   *Policy
	allow    []*cidr
	deny     []*cidr
	ipSeen   map[string]map[string]int64
	tokDelta map[string]int64
	useDelta map[string]int64
	dirty    bool
	sem      chan struct{}
	bornAt   time.Time
	mtimeKey int64
	mtimePol int64
	upstream *url.URL
	proxy    *httputil.ReverseProxy
}

func newGuard(e *Env) (*guard, error) {
	up, err := url.Parse(e.UpstreamURL)
	if err != nil {
		return nil, fmt.Errorf("上游地址非法: %w", err)
	}
	if err := e.ensureDirs(); err != nil {
		return nil, err
	}
	ks, err := loadKeys(e)
	if err != nil {
		return nil, err
	}
	pol, err := loadPolicy(e)
	if err != nil {
		return nil, err
	}
	g := &guard{
		env:      e,
		keys:     ks,
		policy:   pol,
		ipSeen:   map[string]map[string]int64{},
		tokDelta: map[string]int64{},
		useDelta: map[string]int64{},
		sem:      make(chan struct{}, maxInFlight),
		bornAt:   time.Now(),
		upstream: up,
	}
	if err := g.recompile(); err != nil {
		return nil, err
	}
	g.stampMtime()
	g.buildProxy()
	return g, nil
}

func (g *guard) stampMtime() {
	if fi, err := os.Stat(keysPath(g.env)); err == nil {
		g.mtimeKey = fi.ModTime().UnixNano()
	}
	if fi, err := os.Stat(policyPath(g.env)); err == nil {
		g.mtimePol = fi.ModTime().UnixNano()
	}
}

// reloadIfChanged 密钥库/策略被 shell 改动后热加载，无需重启服务。
func (g *guard) reloadIfChanged() {
	g.mu.Lock()
	defer g.mu.Unlock()
	changed := false
	if fi, err := os.Stat(keysPath(g.env)); err == nil && fi.ModTime().UnixNano() != g.mtimeKey {
		if ks, err := loadKeys(g.env); err == nil {
			g.keys = ks
			changed = true
		}
		g.mtimeKey = fi.ModTime().UnixNano()
	}
	if fi, err := os.Stat(policyPath(g.env)); err == nil && fi.ModTime().UnixNano() != g.mtimePol {
		if p, err := loadPolicy(g.env); err == nil {
			g.policy = p
			changed = true
		}
		g.mtimePol = fi.ModTime().UnixNano()
	}
	if changed {
		_ = g.recompile()
	}
}

func (g *guard) recompile() error {
	allow, err := compileCIDRs(g.policy.IPAllow)
	if err != nil {
		return err
	}
	deny, err := compileCIDRs(g.policy.IPDeny)
	if err != nil {
		return err
	}
	g.allow, g.deny = allow, deny
	return nil
}

func (g *guard) findKey(hash string) *KeyEntry {
	for i := range g.keys.Keys {
		if g.keys.Keys[i].Hash == hash {
			return &g.keys.Keys[i]
		}
	}
	return nil
}

// flush 把内存用量增量合并回磁盘（先重读磁盘，避免覆盖 shell 新增的密钥）。
func (g *guard) flush() error {
	g.mu.Lock()
	dirty := g.dirty
	tok, use := g.tokDelta, g.useDelta
	g.tokDelta = map[string]int64{}
	g.useDelta = map[string]int64{}
	g.dirty = false
	g.mu.Unlock()

	if !dirty {
		return nil
	}
	ks, err := loadKeys(g.env)
	if err != nil {
		return err
	}
	for i := range ks.Keys {
		if d, ok := tok[ks.Keys[i].ID]; ok {
			ks.Keys[i].TokenUsed += d
		}
		if t, ok := use[ks.Keys[i].ID]; ok && t > ks.Keys[i].LastUsedAt {
			ks.Keys[i].LastUsedAt = t
		}
	}
	return saveKeys(g.env, ks)
}

func (g *guard) noteUsage(id string, tokens int64, at time.Time) {
	g.mu.Lock()
	g.tokDelta[id] += tokens
	if at.Unix() > g.useDelta[id] {
		g.useDelta[id] = at.Unix()
	}
	g.dirty = true
	g.mu.Unlock()
}

// checkIPLimit 24h 内来源 IP 数限制，纯内存计数（重启清零，零写盘）。
func (g *guard) checkIPLimit(k *KeyEntry, ip string) error {
	if k.MaxIPs <= 0 {
		return nil
	}
	g.mu.Lock()
	defer g.mu.Unlock()
	now := time.Now().Unix()
	m := g.ipSeen[k.ID]
	if m == nil {
		m = map[string]int64{}
		g.ipSeen[k.ID] = m
	}
	for k2, t := range m {
		if now-t > 86400 {
			delete(m, k2)
		}
	}
	if _, ok := m[ip]; ok {
		m[ip] = now
		return nil
	}
	if len(m) >= k.MaxIPs {
		return fmt.Errorf("超出最大来源 IP 数 %d", k.MaxIPs)
	}
	m[ip] = now
	return nil
}

func (g *guard) buildProxy() {
	g.proxy = &httputil.ReverseProxy{
		FlushInterval: -1, // 立即 flush，保证 SSE 不被缓冲
		Director: func(req *http.Request) {
			req.URL.Scheme = g.upstream.Scheme
			req.URL.Host = g.upstream.Host
			req.Host = g.upstream.Host
			req.Header.Del("Authorization")
			if g.env.UpstreamKey != "" {
				req.Header.Set("Authorization", "Bearer "+g.env.UpstreamKey)
			}
		},
		ModifyResponse: func(resp *http.Response) error {
			if st, ok := resp.Request.Context().Value(stateKey{}).(*reqState); ok {
				st.status = resp.StatusCode
				st.firstMS = time.Since(st.start).Milliseconds()
				st.firstSet = true
				resp.Body = &sniffRC{ReadCloser: resp.Body, ring: st.ring}
			}
			return nil
		},
		ErrorHandler: func(w http.ResponseWriter, r *http.Request, err error) {
			if st, ok := r.Context().Value(stateKey{}).(*reqState); ok {
				st.status = http.StatusBadGateway
				st.errMsg = err.Error()
				if !st.firstSet {
					st.firstMS = time.Since(st.start).Milliseconds()
					st.firstSet = true
				}
			}
			writeErrJSON(w, http.StatusBadGateway, "上游不可达: "+err.Error())
		},
	}
}

func writeErrJSON(w http.ResponseWriter, code int, msg string) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(code)
	_ = json.NewEncoder(w).Encode(map[string]any{
		"error": map[string]any{"message": msg, "type": "wb2api_guard_error", "code": code},
	})
}

// extractUsage 从响应尾部抓取最后一个 usage 对象（SSE 与非流式都适用）。
func extractUsage(b []byte) map[string]any {
	s := string(b)
	idx := strings.LastIndex(s, "\"usage\"")
	if idx < 0 {
		return nil
	}
	rel := strings.Index(s[idx:], "{")
	if rel < 0 {
		return nil
	}
	dec := json.NewDecoder(bytes.NewReader(b[idx+rel:]))
	m := map[string]any{}
	if err := dec.Decode(&m); err != nil {
		return nil
	}
	return m
}

func (g *guard) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodOptions {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.WriteHeader(http.StatusNoContent)
		return
	}
	if r.URL.Path == "/healthz" {
		_, _, herr := httpGet(g.env.UpstreamURL+"/healthz", "", 3*time.Second)
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		_ = json.NewEncoder(w).Encode(map[string]any{
			"ok":          true,
			"service":     "wb2api-ctl",
			"version":     version,
			"uptime_sec":  int64(time.Since(g.bornAt).Seconds()),
			"upstream":    g.env.UpstreamURL,
			"upstream_ok": herr == nil,
		})
		return
	}

	// 上游内嵌面板（panel 版上游）的静态资源匿名放行：HTML / JS 本身不含任何密钥，
	// 上游也是匿名提供；否则浏览器直接打开 /panel/ 会被下面的密钥校验挡成 401，
	// 页面根本加载不出来。真正的数据接口 /panel/api/* 仍走下面的插件密钥鉴权
	// （面板里填任意一把分发密钥即可，转发时会被替换成上游 api_key）。
	if r.Method == http.MethodGet && (r.URL.Path == "/panel" || r.URL.Path == "/panel/" || r.URL.Path == "/panel/app.js") {
		g.proxy.ServeHTTP(w, r)
		return
	}

	g.reloadIfChanged()

	select {
	case g.sem <- struct{}{}:
		defer func() { <-g.sem }()
	default:
		writeErrJSON(w, http.StatusServiceUnavailable, "并发超限，请稍后重试")
		return
	}

	start := time.Now()
	st := &reqState{start: start, ring: newRing(ringBufferSize), status: http.StatusBadGateway, credit: -1}
	r = r.WithContext(context.WithValue(r.Context(), stateKey{}, st))

	ip := clientIP(r)
	ipStr := ""
	if ip != nil {
		ipStr = ip.String()
	}

	// ---- 全局 IP 管控 ----
	g.mu.Lock()
	allow, deny := g.allow, g.deny
	g.mu.Unlock()
	if ip != nil && matchAny(deny, ip) {
		writeErrJSON(w, http.StatusForbidden, "来源 IP 在黑名单中")
		g.audit(r, st, nil, ipStr, "", false, http.StatusForbidden, start, "ip denied")
		return
	}
	if ip != nil && len(allow) > 0 && !matchAny(allow, ip) {
		writeErrJSON(w, http.StatusForbidden, "来源 IP 不在白名单中")
		g.audit(r, st, nil, ipStr, "", false, http.StatusForbidden, start, "ip not allowed")
		return
	}

	// ---- 密钥鉴权 ----
	token := bearerToken(r)
	if token == "" {
		w.Header().Set("WWW-Authenticate", "Bearer")
		writeErrJSON(w, http.StatusUnauthorized, "缺少 Bearer 密钥")
		g.audit(r, st, nil, ipStr, "", false, http.StatusUnauthorized, start, "missing key")
		return
	}
	g.mu.Lock()
	k := g.findKey(sha256Hex(token))
	g.mu.Unlock()
	if k == nil {
		writeErrJSON(w, http.StatusUnauthorized, "密钥无效")
		g.audit(r, st, nil, ipStr, "", false, http.StatusUnauthorized, start, "invalid key")
		return
	}
	if !k.Enabled {
		writeErrJSON(w, http.StatusForbidden, "密钥已停用")
		g.audit(r, st, k, ipStr, "", false, http.StatusForbidden, start, "key disabled")
		return
	}
	if k.ExpiresAt > 0 && k.ExpiresAt < time.Now().Unix() {
		writeErrJSON(w, http.StatusForbidden, "密钥已过期")
		g.audit(r, st, k, ipStr, "", false, http.StatusForbidden, start, "key expired")
		return
	}
	if ip != nil && len(k.IPAllow) > 0 {
		if cs, err := compileCIDRs(k.IPAllow); err == nil && !matchAny(cs, ip) {
			writeErrJSON(w, http.StatusForbidden, "该密钥不允许来自此 IP")
			g.audit(r, st, k, ipStr, "", false, http.StatusForbidden, start, "key ip not allowed")
			return
		}
	}
	if err := g.checkIPLimit(k, ipStr); err != nil {
		writeErrJSON(w, http.StatusForbidden, err.Error())
		g.audit(r, st, k, ipStr, "", false, http.StatusForbidden, start, err.Error())
		return
	}

	// ---- 读请求体：取 model / stream 做白名单与审计 ----
	model := ""
	stream := false
	body := []byte(nil)
	if r.Body != nil {
		b, err := io.ReadAll(io.LimitReader(r.Body, maxBodyBytes+1))
		if err != nil {
			writeErrJSON(w, http.StatusBadRequest, "读取请求体失败")
			return
		}
		if len(b) > maxBodyBytes {
			writeErrJSON(w, http.StatusRequestEntityTooLarge, "请求体超过 8MB")
			return
		}
		body = b
		if len(b) > 0 {
			var payload map[string]any
			if json.Unmarshal(b, &payload) == nil {
				model, _ = payload["model"].(string)
				stream, _ = payload["stream"].(bool)
			}
		}
	}
	if len(k.Models) > 0 && model != "" && !containsFold(k.Models, model) {
		writeErrJSON(w, http.StatusForbidden, "该密钥不允许调用模型 "+model)
		g.audit(r, st, k, ipStr, model, stream, http.StatusForbidden, start, "model not allowed")
		return
	}
	if k.TokenQuota > 0 && k.TokenUsed >= k.TokenQuota {
		writeErrJSON(w, http.StatusTooManyRequests, "该密钥 Token 配额已用尽")
		g.audit(r, st, k, ipStr, model, stream, http.StatusTooManyRequests, start, "quota exceeded")
		return
	}

	r.Body = io.NopCloser(bytes.NewReader(body))
	r.ContentLength = int64(len(body))

	g.proxy.ServeHTTP(w, r)

	// ---- 收尾：抓 usage、写审计 ----
	if usage := extractUsage(st.ring.bytes()); usage != nil {
		st.promptTok = int(asInt64(usage["prompt_tokens"]))
		st.compTok = int(asInt64(usage["completion_tokens"]))
		if v, ok := usage["credit"]; ok {
			st.credit = asFloat64(v)
		}
	}
	if st.status == 0 {
		st.status = http.StatusBadGateway
	}
	g.noteUsage(k.ID, int64(st.promptTok+st.compTok), start)
	g.audit(r, st, k, ipStr, model, stream, st.status, start, st.errMsg)
}

func (g *guard) audit(r *http.Request, st *reqState, k *KeyEntry, ipStr, model string, stream bool, status int, start time.Time, errMsg string) {
	id, name := "", ""
	if k != nil {
		id, name = k.ID, k.Name
	}
	rec := AuditRecord{
		TS:        start.Unix(),
		KeyID:     id,
		KeyName:   name,
		RemoteIP:  ipStr,
		Model:     model,
		Path:      r.URL.Path,
		Stream:    stream,
		Status:    status,
		FirstByte: st.firstMS,
		TotalMS:   time.Since(start).Milliseconds(),
		PromptTok: st.promptTok,
		CompTok:   st.compTok,
		Credit:    st.credit,
		Err:       errMsg,
	}
	_ = appendAudit(g.env, rec)
}

func bearerToken(r *http.Request) string {
	h := r.Header.Get("Authorization")
	if h == "" {
		h = r.Header.Get("X-Api-Key")
	}
	if strings.HasPrefix(strings.ToLower(h), "bearer ") {
		return strings.TrimSpace(h[7:])
	}
	return strings.TrimSpace(h)
}

func containsFold(list []string, s string) bool {
	for _, v := range list {
		if strings.EqualFold(strings.TrimSpace(v), s) {
			return true
		}
	}
	return false
}

// cleanAudit 清理超过保留天数的审计文件。
func cleanAudit(e *Env) int {
	dir := auditDir(e)
	entries, err := os.ReadDir(dir)
	if err != nil {
		return 0
	}
	cutoff := time.Now().AddDate(0, 0, -e.AuditDays).Format("20060102")
	removed := 0
	for _, en := range entries {
		n := en.Name()
		if len(n) < 14 || !strings.HasPrefix(n, "audit-") {
			continue
		}
		if n[6:14] < cutoff {
			if err := os.Remove(filepath.Join(dir, n)); err == nil {
				removed++
			}
		}
	}
	return removed
}

func cmdServe(args []string) error {
	e := loadEnv()
	fs := flag.NewFlagSet("serve", flag.ContinueOnError)
	fs.SetOutput(os.Stderr)
	listen := fs.String("listen", e.Listen, "监听地址")
	if err := fs.Parse(args); err != nil {
		return err
	}
	e.Listen = *listen

	g, err := newGuard(e)
	if err != nil {
		return err
	}

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		ticker := time.NewTicker(30 * time.Second)
		defer ticker.Stop()
		for {
			select {
			case <-ticker.C:
				_ = g.flush()
			case <-stop:
				_ = g.flush()
				os.Exit(0)
			}
		}
	}()
	go func() {
		gc := time.NewTicker(6 * time.Hour)
		for range gc.C {
			cleanAudit(e)
		}
	}()

	srv := &http.Server{
		Addr:              e.Listen,
		Handler:           g,
		ReadHeaderTimeout: 30 * time.Second,
	}
	fmt.Fprintf(os.Stderr, "wb2api-ctl %s listen=%s upstream=%s data=%s\n",
		version, e.Listen, e.UpstreamURL, e.DataDir)
	return srv.ListenAndServe()
}
