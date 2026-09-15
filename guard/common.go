package main

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

const (
	defaultDataDir      = "/koolshare/etc/workbuddy"
	defaultListen       = ":17863"
	defaultUpstreamPort = 7863
	defaultBinDir       = "/koolshare/bin"
)

// Env 运行期配置，全部来自环境变量（由 workbuddy_config.sh 从 dbus 注入）。
type Env struct {
	DataDir      string
	Listen       string
	UpstreamURL  string
	UpstreamPort int
	UpstreamKey  string
	BinDir       string
	AuditDays    int
	AuditMaxMB   int
}

func envStr(k, def string) string {
	if v := strings.TrimSpace(os.Getenv(k)); v != "" {
		return v
	}
	return def
}

func envInt(k string, def int) int {
	v := strings.TrimSpace(os.Getenv(k))
	if v == "" {
		return def
	}
	n, err := strconv.Atoi(v)
	if err != nil {
		return def
	}
	return n
}

func loadEnv() *Env {
	port := envInt("WB_UPSTREAM_PORT", defaultUpstreamPort)
	up := strings.TrimSpace(os.Getenv("WB_UPSTREAM"))
	if up == "" {
		up = fmt.Sprintf("http://127.0.0.1:%d", port)
	}
	up = strings.TrimRight(up, "/")
	return &Env{
		DataDir:      envStr("WB_DATA_DIR", defaultDataDir),
		Listen:       envStr("WB_LISTEN", defaultListen),
		UpstreamURL:  up,
		UpstreamPort: port,
		UpstreamKey:  os.Getenv("WB_UPSTREAM_KEY"),
		BinDir:       envStr("WB_BIN_DIR", defaultBinDir),
		AuditDays:    envInt("WB_AUDIT_DAYS", 7),
		AuditMaxMB:   envInt("WB_AUDIT_MAX_MB", 8),
	}
}

func (e *Env) path(parts ...string) string {
	return filepath.Join(append([]string{e.DataDir}, parts...)...)
}

func (e *Env) bin(name string) string {
	return filepath.Join(e.BinDir, name)
}

// ensureDirs 建立数据目录下的固定布局。
func (e *Env) ensureDirs() error {
	dirs := []string{
		e.DataDir,
		e.path("auths"),
		e.path("data"),
		e.path("audit"),
	}
	for _, d := range dirs {
		if err := os.MkdirAll(d, 0755); err != nil {
			return fmt.Errorf("创建目录 %s 失败: %w", d, err)
		}
	}
	return nil
}

// atomicWrite 写临时文件后 rename，避免写入中途断电留下半个文件。
func atomicWrite(path string, data []byte, perm os.FileMode) error {
	if err := os.MkdirAll(filepath.Dir(path), 0755); err != nil {
		return err
	}
	tmp := path + ".tmp"
	f, err := os.OpenFile(tmp, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, perm)
	if err != nil {
		return err
	}
	if _, err = f.Write(data); err != nil {
		f.Close()
		os.Remove(tmp)
		return err
	}
	if err = f.Sync(); err != nil {
		f.Close()
		os.Remove(tmp)
		return err
	}
	if err = f.Close(); err != nil {
		os.Remove(tmp)
		return err
	}
	if err = os.Chmod(tmp, perm); err != nil {
		os.Remove(tmp)
		return err
	}
	return os.Rename(tmp, path)
}

func writeJSONFile(path string, v any, perm os.FileMode) error {
	data, err := json.MarshalIndent(v, "", "  ")
	if err != nil {
		return err
	}
	data = append(data, '\n')
	return atomicWrite(path, data, perm)
}

func readJSONFile(path string, v any) error {
	b, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	return json.Unmarshal(b, v)
}

func printJSON(v any) {
	enc := json.NewEncoder(os.Stdout)
	enc.SetEscapeHTML(false)
	_ = enc.Encode(v)
}

func sha256Hex(s string) string {
	sum := sha256.Sum256([]byte(s))
	return hex.EncodeToString(sum[:])
}

func randomHex(n int) string {
	buf := make([]byte, n)
	if _, err := rand.Read(buf); err != nil {
		return ""
	}
	return hex.EncodeToString(buf)
}

// ---- JSON 弱类型取值：上游字段可能是 string 也可能是 number ----

func asString(v any) string {
	switch t := v.(type) {
	case nil:
		return ""
	case string:
		return t
	case float64:
		return strconv.FormatInt(int64(t), 10)
	case int:
		return strconv.Itoa(t)
	case int64:
		return strconv.FormatInt(t, 10)
	case json.Number:
		return t.String()
	case bool:
		return strconv.FormatBool(t)
	default:
		return fmt.Sprintf("%v", t)
	}
}

func asInt64(v any) int64 {
	switch t := v.(type) {
	case float64:
		return int64(t)
	case int:
		return int64(t)
	case int64:
		return t
	case json.Number:
		n, _ := t.Int64()
		return n
	case string:
		n, _ := strconv.ParseInt(strings.TrimSpace(t), 10, 64)
		return n
	default:
		return 0
	}
}

func asFloat64(v any) float64 {
	switch t := v.(type) {
	case float64:
		return t
	case float32:
		return float64(t)
	case int:
		return float64(t)
	case int64:
		return float64(t)
	case json.Number:
		f, _ := t.Float64()
		return f
	case string:
		f, _ := strconv.ParseFloat(strings.TrimSpace(t), 64)
		return f
	default:
		return 0
	}
}

func splitCSV(s string) []string {
	out := []string{}
	for _, p := range strings.Split(s, ",") {
		p = strings.TrimSpace(p)
		if p != "" {
			out = append(out, p)
		}
	}
	return out
}

// tailLines 读取文件最后 n 行（文件不大，直接整体读入）。
func tailLines(path string, n int) ([]string, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	s := strings.TrimRight(string(b), "\n")
	if s == "" {
		return []string{}, nil
	}
	lines := strings.Split(s, "\n")
	if len(lines) > n {
		lines = lines[len(lines)-n:]
	}
	return lines, nil
}
