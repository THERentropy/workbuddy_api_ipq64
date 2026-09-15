package main

import (
	"bytes"
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

// authFile 与上游 internal/auth 读取格式严格一致，字段名不可改动。
type authFile struct {
	Account struct {
		UID          string `json:"uid"`
		EnterpriseID string `json:"enterpriseId"`
		Nickname     string `json:"nickname"`
	} `json:"account"`
	Auth struct {
		AccessToken  string `json:"accessToken"`
		RefreshToken string `json:"refreshToken"`
		ExpiresAt    int64  `json:"expiresAt"`
		Domain       string `json:"domain"`
		Realm        string `json:"realm"`
	} `json:"auth"`
}

// runBin 执行同目录下的 Go 工具，返回 stdout（stderr 并入错误信息）。
func runBin(bin string, timeout time.Duration, args ...string) (string, error) {
	if _, err := os.Stat(bin); err != nil {
		return "", fmt.Errorf("二进制不存在: %s", bin)
	}
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	var out, errb bytes.Buffer
	cmd := exec.CommandContext(ctx, bin, args...)
	cmd.Stdout = &out
	cmd.Stderr = &errb
	if err := cmd.Run(); err != nil {
		msg := strings.TrimSpace(errb.String())
		if msg == "" {
			msg = err.Error()
		}
		return out.String(), fmt.Errorf("%s 执行失败: %s", filepath.Base(bin), msg)
	}
	return out.String(), nil
}

// extractJSON 从可能夹带日志的输出里抠出第一段 JSON 对象。
func extractJSON(s string) string {
	s = strings.TrimSpace(s)
	if strings.HasPrefix(s, "{") {
		return s
	}
	i := strings.Index(s, "{")
	j := strings.LastIndex(s, "}")
	if i >= 0 && j > i {
		return s[i : j+1]
	}
	return s
}

func cmdLogin(args []string) error {
	if len(args) == 0 {
		return fmt.Errorf("usage: wb2api-ctl login <url|poll> [--realm=cn|global]")
	}
	e := loadEnv()
	if err := e.ensureDirs(); err != nil {
		return err
	}

	fs := flag.NewFlagSet("login", flag.ContinueOnError)
	fs.SetOutput(os.Stderr)
	realm := fs.String("realm", "cn", "域: cn|global")
	if err := fs.Parse(args[1:]); err != nil {
		return err
	}
	if *realm != "cn" && *realm != "global" {
		return fmt.Errorf("realm 只能是 cn 或 global")
	}

	bin := e.bin("wb2api-login")
	switch args[0] {
	case "url":
		out, err := runBin(bin, 30*time.Second, "--realm="+*realm, "url")
		if err != nil {
			return err
		}
		url := strings.TrimSpace(out)
		if url == "" {
			return fmt.Errorf("获取授权链接失败：上游返回空")
		}
		printJSON(map[string]any{"ok": true, "realm": *realm, "url": url})
		return nil

	case "poll":
		out, err := runBin(bin, 180*time.Second, "--realm="+*realm, "poll")
		if err != nil {
			return err
		}
		var raw map[string]any
		if err := json.Unmarshal([]byte(extractJSON(out)), &raw); err != nil {
			return fmt.Errorf("解析登录结果失败: %w（原始输出：%.200s）", err, strings.TrimSpace(out))
		}

		uid := asString(raw["uid"])
		if uid == "" {
			return fmt.Errorf("未获取到 uid，请确认已在浏览器完成登录")
		}
		token := asString(raw["access_token"])
		if token == "" {
			return fmt.Errorf("未获取到 access_token")
		}
		expiresIn := asInt64(raw["expires_in"])
		if expiresIn <= 0 {
			expiresIn = 2592000 // 上游未给出时给 30 天兜底
		}

		var af authFile
		af.Account.UID = uid
		af.Account.EnterpriseID = asString(raw["enterprise_id"])
		af.Account.Nickname = asString(raw["nickname"])
		af.Auth.AccessToken = token
		af.Auth.RefreshToken = asString(raw["refresh_token"])
		af.Auth.ExpiresAt = time.Now().Unix() + expiresIn
		af.Auth.Domain = asString(raw["domain"])
		af.Auth.Realm = *realm

		authDir := e.path("auths")
		if err := os.MkdirAll(authDir, 0755); err != nil {
			return err
		}
		file := filepath.Join(authDir, "workbuddy-"+uid+".json")
		action := "新增"
		if _, err := os.Stat(file); err == nil {
			action = "覆盖"
		}
		// 凭证明文落盘，权限 0600
		if err := writeJSONFile(file, af, 0600); err != nil {
			return err
		}

		printJSON(map[string]any{
			"ok":         true,
			"action":     action,
			"uid":        uid,
			"nickname":   af.Account.Nickname,
			"realm":      *realm,
			"expires_at": af.Auth.ExpiresAt,
			"file":       file,
		})
		return nil

	default:
		return fmt.Errorf("未知子命令: %s", args[0])
	}
}

func cmdAccount(args []string) error {
	if len(args) == 0 {
		return fmt.Errorf("usage: wb2api-ctl account <list|remove|signin>")
	}
	e := loadEnv()
	if err := e.ensureDirs(); err != nil {
		return err
	}

	switch args[0] {
	case "list":
		authDir := e.path("auths")
		entries, err := os.ReadDir(authDir)
		if err != nil && !os.IsNotExist(err) {
			return err
		}
		type item struct {
			UID       string `json:"uid"`
			Nickname  string `json:"nickname"`
			Realm     string `json:"realm"`
			ExpiresAt int64  `json:"expires_at"`
			Expired   bool   `json:"expired"`
			File      string `json:"file"`
		}
		now := time.Now().Unix()
		list := []item{}
		for _, en := range entries {
			if en.IsDir() || !strings.HasPrefix(en.Name(), "workbuddy-") || !strings.HasSuffix(en.Name(), ".json") {
				continue
			}
			p := filepath.Join(authDir, en.Name())
			var af authFile
			if err := readJSONFile(p, &af); err != nil {
				continue
			}
			exp := af.Auth.ExpiresAt > 0 && af.Auth.ExpiresAt < now
			list = append(list, item{
				UID:       af.Account.UID,
				Nickname:  af.Account.Nickname,
				Realm:     af.Auth.Realm,
				ExpiresAt: af.Auth.ExpiresAt,
				Expired:   exp,
				File:      en.Name(),
			})
		}
		printJSON(map[string]any{"ok": true, "auth_dir": authDir, "accounts": list})
		return nil

	case "remove":
		fs := flag.NewFlagSet("account remove", flag.ContinueOnError)
		fs.SetOutput(os.Stderr)
		uid := fs.String("uid", "", "账号 UID")
		if err := fs.Parse(args[1:]); err != nil {
			return err
		}
		if *uid == "" {
			return fmt.Errorf("--uid 必填")
		}
		p := filepath.Join(e.path("auths"), "workbuddy-"+*uid+".json")
		if err := os.Remove(p); err != nil {
			return err
		}
		printJSON(map[string]any{"ok": true, "removed": *uid})
		return nil

	case "signin":
		// 签到要遍历全部账号，耗时较长；控制在 httpd 超时（一般 120s）以内
		out, err := runBin(e.bin("wb2api-signin"), 110*time.Second, e.path("auths"))
		if err != nil {
			return err
		}
		printJSON(map[string]any{"ok": true, "output": strings.TrimSpace(out)})
		return nil

	default:
		return fmt.Errorf("未知子命令: %s", args[0])
	}
}
