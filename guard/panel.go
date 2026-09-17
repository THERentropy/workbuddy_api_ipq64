package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"
)

// panel 版上游（linguo2625469/workbuddy2api-panel）内嵌了 /panel/ 管理面板，
// 成长任务「一键完成」、开学季闭环、任务扫描/执行队列都挂在 /panel/api/* 上。
//
// 路由器页面够不到这些接口：上游按本项目约定只监听 127.0.0.1（对外一律走
// wb2api-ctl serve 代理）。所以由本工具在本地转一手——带上游 api_key、
// 把面板的错误形状统一成插件通用的 {"ok":false,"err":...}，shell 只负责搬运。
//
// 安全边界：只放行 /panel/api/ 前缀，避免这个子命令退化成任意路径代理。
const panelAPIPrefix = "/panel/api/"

func cmdPanel(args []string) error {
	if len(args) == 0 {
		return fmt.Errorf("usage: wb2api-ctl panel </panel/api/路径> [--post=<json>] [--timeout=秒]")
	}
	e := loadEnv()
	path := strings.TrimSpace(args[0])
	if !strings.HasPrefix(path, panelAPIPrefix) {
		return fmt.Errorf("路径必须以 %s 开头：%s", panelAPIPrefix, path)
	}

	fs := flag.NewFlagSet("panel", flag.ContinueOnError)
	fs.SetOutput(os.Stderr)
	post := fs.String("post", "", "POST 请求体（合法 JSON，留空则用 GET）")
	timeout := fs.Int("timeout", 120, "超时秒（扫描/队列启动可能较慢）")
	if err := fs.Parse(args[1:]); err != nil {
		return err
	}
	if *timeout <= 0 || *timeout > 900 {
		return fmt.Errorf("timeout 非法: %d（1-900 秒）", *timeout)
	}

	method := http.MethodGet
	var body io.Reader
	if s := strings.TrimSpace(*post); s != "" {
		if !json.Valid([]byte(s)) {
			return fmt.Errorf("--post 不是合法 JSON")
		}
		method, body = http.MethodPost, strings.NewReader(s)
	}

	req, err := http.NewRequest(method, e.UpstreamURL+path, body)
	if err != nil {
		return err
	}
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	if e.UpstreamKey != "" {
		req.Header.Set("Authorization", "Bearer "+e.UpstreamKey)
	}

	cli := &http.Client{Timeout: time.Duration(*timeout) * time.Second}
	resp, err := cli.Do(req)
	if err != nil {
		return fmt.Errorf("请求上游面板失败（上游网关可能未启动）: %w", err)
	}
	defer resp.Body.Close()
	b, err := io.ReadAll(io.LimitReader(resp.Body, 8<<20))
	if err != nil {
		return err
	}

	var m map[string]any
	if err := json.Unmarshal(b, &m); err != nil {
		return fmt.Errorf("上游面板返回非 JSON（HTTP %d）: %.200s", resp.StatusCode, string(b))
	}
	// 面板错误是 {"ok":false,"error":"..."}，统一成插件的 err 字段，
	// 页面侧才能用同一套 (d.ok / d.err) 判断，不必区分两种形状。
	if resp.StatusCode >= 400 || m["ok"] == false {
		msg := asString(m["error"])
		if msg == "" {
			msg = asString(m["err"])
		}
		if msg == "" {
			msg = fmt.Sprintf("HTTP %d", resp.StatusCode)
		}
		if resp.StatusCode == http.StatusNotFound {
			msg += "（上游二进制不含该面板接口，请确认构建自 workbuddy2api-panel）"
		}
		printJSON(map[string]any{"ok": false, "err": msg})
		return nil
	}
	if _, has := m["ok"]; !has {
		m["ok"] = true
	}
	printJSON(m)
	return nil
}
