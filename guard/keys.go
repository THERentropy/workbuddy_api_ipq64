package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// KeyEntry 一把分发密钥。明文只在创建时输出一次，库中仅存 SHA-256。
type KeyEntry struct {
	ID         string   `json:"id"`
	Name       string   `json:"name"`
	Hash       string   `json:"hash"`
	Prefix     string   `json:"prefix"`
	Enabled    bool     `json:"enabled"`
	ExpiresAt  int64    `json:"expires_at"` // 0 = 永不过期
	MaxIPs     int      `json:"max_ips"`    // 24h 内最大来源 IP 数，0 = 不限
	IPAllow    []string `json:"ip_allow"`
	Models     []string `json:"models"`
	TokenQuota int64    `json:"token_quota"` // 0 = 不限
	TokenUsed  int64    `json:"token_used"`
	CreatedAt  int64    `json:"created_at"`
	LastUsedAt int64    `json:"last_used_at"`
}

type keyStore struct {
	Keys []KeyEntry `json:"keys"`
}

// Policy 全局入站 IP 管控。
type Policy struct {
	IPAllow []string `json:"ip_allow"`
	IPDeny  []string `json:"ip_deny"`
}

func keysPath(e *Env) string   { return filepath.Join(e.DataDir, "keys.json") }
func policyPath(e *Env) string { return filepath.Join(e.DataDir, "guard.json") }

func loadKeys(e *Env) (*keyStore, error) {
	ks := &keyStore{}
	if err := readJSONFile(keysPath(e), ks); err != nil {
		if os.IsNotExist(err) {
			return ks, nil
		}
		return nil, fmt.Errorf("keys.json 解析失败: %w", err)
	}
	if ks.Keys == nil {
		ks.Keys = []KeyEntry{}
	}
	return ks, nil
}

func saveKeys(e *Env, ks *keyStore) error {
	return writeJSONFile(keysPath(e), ks, 0600)
}

func loadPolicy(e *Env) (*Policy, error) {
	p := &Policy{}
	if err := readJSONFile(policyPath(e), p); err != nil {
		if os.IsNotExist(err) {
			return p, nil
		}
		return nil, fmt.Errorf("guard.json 解析失败: %w", err)
	}
	return p, nil
}

func savePolicy(e *Env, p *Policy) error {
	return writeJSONFile(policyPath(e), p, 0644)
}

// publicView 去掉 hash，供页面展示。
func publicView(k KeyEntry) map[string]any {
	return map[string]any{
		"id":           k.ID,
		"name":         k.Name,
		"prefix":       k.Prefix,
		"enabled":      k.Enabled,
		"expires_at":   k.ExpiresAt,
		"expired":      k.ExpiresAt > 0 && k.ExpiresAt < time.Now().Unix(),
		"max_ips":      k.MaxIPs,
		"ip_allow":     k.IPAllow,
		"models":       k.Models,
		"token_quota":  k.TokenQuota,
		"token_used":   k.TokenUsed,
		"created_at":   k.CreatedAt,
		"last_used_at": k.LastUsedAt,
	}
}

func cmdKey(args []string) error {
	if len(args) == 0 {
		return fmt.Errorf("usage: wb2api-ctl key <add|list|del|enable|disable>")
	}
	e := loadEnv()
	if err := e.ensureDirs(); err != nil {
		return err
	}

	switch args[0] {
	case "add":
		fs := flag.NewFlagSet("key add", flag.ContinueOnError)
		fs.SetOutput(os.Stderr)
		name := fs.String("name", "", "密钥名称")
		days := fs.Int("days", 0, "有效天数，0=永久")
		maxIPs := fs.Int("max-ips", 0, "24h 内最大来源 IP 数，0=不限")
		ipAllow := fs.String("ip-allow", "", "IP 白名单，逗号分隔 CIDR")
		models := fs.String("models", "", "模型白名单，逗号分隔")
		quota := fs.Int64("quota", 0, "Token 配额，0=不限")
		if err := fs.Parse(args[1:]); err != nil {
			return err
		}
		if *days < 0 {
			return fmt.Errorf("有效天数不能为负")
		}
		allow := splitCSV(*ipAllow)
		if _, err := compileCIDRs(allow); err != nil {
			return err
		}

		plain := "sk-" + randomHex(16)
		if len(plain) < 20 {
			return fmt.Errorf("随机数生成失败")
		}
		now := time.Now()
		ent := KeyEntry{
			ID:         "kid-" + randomHex(8),
			Name:       *name,
			Hash:       sha256Hex(plain),
			Prefix:     plain[:8],
			Enabled:    true,
			ExpiresAt:  0,
			MaxIPs:     *maxIPs,
			IPAllow:    allow,
			Models:     splitCSV(*models),
			TokenQuota: *quota,
			CreatedAt:  now.Unix(),
		}
		if *days > 0 {
			ent.ExpiresAt = now.AddDate(0, 0, *days).Unix()
		}

		ks, err := loadKeys(e)
		if err != nil {
			return err
		}
		ks.Keys = append(ks.Keys, ent)
		if err := saveKeys(e, ks); err != nil {
			return err
		}
		printJSON(map[string]any{
			"ok":        true,
			"plaintext": plain, // 唯一一次明文，页面提示用户立即保存
			"key":       publicView(ent),
		})
		return nil

	case "list":
		ks, err := loadKeys(e)
		if err != nil {
			return err
		}
		out := []map[string]any{}
		for _, k := range ks.Keys {
			out = append(out, publicView(k))
		}
		printJSON(map[string]any{"ok": true, "keys": out})
		return nil

	case "del", "enable", "disable":
		fs := flag.NewFlagSet("key "+args[0], flag.ContinueOnError)
		fs.SetOutput(os.Stderr)
		id := fs.String("id", "", "密钥 ID")
		if err := fs.Parse(args[1:]); err != nil {
			return err
		}
		if *id == "" {
			return fmt.Errorf("--id 必填")
		}
		ks, err := loadKeys(e)
		if err != nil {
			return err
		}
		found := false
		remain := []KeyEntry{}
		for _, k := range ks.Keys {
			if k.ID != *id {
				remain = append(remain, k)
				continue
			}
			found = true
			switch args[0] {
			case "del":
				// 丢弃即可
			case "enable":
				k.Enabled = true
				remain = append(remain, k)
			case "disable":
				k.Enabled = false
				remain = append(remain, k)
			}
		}
		if !found {
			return fmt.Errorf("未找到密钥: %s", *id)
		}
		ks.Keys = remain
		if err := saveKeys(e, ks); err != nil {
			return err
		}
		printJSON(map[string]any{"ok": true, "action": args[0], "id": *id})
		return nil

	default:
		return fmt.Errorf("未知子命令: %s", args[0])
	}
}

func cmdPolicy(args []string) error {
	if len(args) == 0 {
		return fmt.Errorf("usage: wb2api-ctl policy <show|set>")
	}
	e := loadEnv()
	if err := e.ensureDirs(); err != nil {
		return err
	}
	p, err := loadPolicy(e)
	if err != nil {
		return err
	}

	switch args[0] {
	case "show":
		printJSON(map[string]any{"ok": true, "ip_allow": p.IPAllow, "ip_deny": p.IPDeny})
		return nil

	case "set":
		fs := flag.NewFlagSet("policy set", flag.ContinueOnError)
		fs.SetOutput(os.Stderr)
		allow := fs.String("ip-allow", "", "全局 IP 白名单，逗号分隔 CIDR，空=不限")
		deny := fs.String("ip-deny", "", "全局 IP 黑名单，逗号分隔 CIDR")
		if err := fs.Parse(args[1:]); err != nil {
			return err
		}
		a := splitCSV(*allow)
		d := splitCSV(*deny)
		if _, err := compileCIDRs(a); err != nil {
			return fmt.Errorf("ip-allow: %w", err)
		}
		if _, err := compileCIDRs(d); err != nil {
			return fmt.Errorf("ip-deny: %w", err)
		}
		p.IPAllow, p.IPDeny = a, d
		if err := savePolicy(e, p); err != nil {
			return err
		}
		printJSON(map[string]any{"ok": true, "ip_allow": p.IPAllow, "ip_deny": p.IPDeny})
		return nil

	default:
		return fmt.Errorf("未知子命令: %s", args[0])
	}
}

// stripSensitive 供日志/错误信息使用，避免把完整 ID 打进日志。
func stripSensitive(s string) string {
	if len(s) > 8 {
		return s[:8] + "..."
	}
	return strings.Repeat("*", len(s))
}
