package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
)

// normDuration 把页面里常见的 "30s / 10m / 2h / 1d" 归一化成 Go duration 字符串。
// 上游 config.json 用的是 Go 原生 duration，这里只是放宽输入格式。
func normDuration(s string) (string, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return "", fmt.Errorf("时长不能为空")
	}
	if strings.HasSuffix(s, "d") {
		n, err := strconv.Atoi(strings.TrimSuffix(s, "d"))
		if err != nil || n <= 0 {
			return "", fmt.Errorf("时长格式错误: %s", s)
		}
		return strconv.Itoa(n*24) + "h", nil
	}
	for _, suf := range []string{"ms", "s", "m", "h"} {
		if strings.HasSuffix(s, suf) {
			n, err := strconv.Atoi(strings.TrimSuffix(s, suf))
			if err != nil || n <= 0 {
				return "", fmt.Errorf("时长格式错误: %s", s)
			}
			return s, nil
		}
	}
	if _, err := strconv.Atoi(s); err == nil {
		return s + "s", nil
	}
	return "", fmt.Errorf("时长格式错误（支持 30s / 10m / 2h / 1d）: %s", s)
}

// parseHours 解析 "9,21" 这类整点列表，去重排序并校验 0-23。
func parseHours(s string) ([]int, error) {
	seen := map[int]bool{}
	out := []int{}
	for _, p := range strings.Split(s, ",") {
		p = strings.TrimSpace(p)
		if p == "" {
			continue
		}
		n, err := strconv.Atoi(p)
		if err != nil || n < 0 || n > 23 {
			return nil, fmt.Errorf("时刻必须是 0-23 的整数: %q", p)
		}
		if !seen[n] {
			seen[n] = true
			out = append(out, n)
		}
	}
	sort.Ints(out)
	return out, nil
}

func setPath(m map[string]any, dotted string, val any) {
	parts := strings.Split(dotted, ".")
	cur := m
	for i, p := range parts {
		if i == len(parts)-1 {
			cur[p] = val
			return
		}
		next, ok := cur[p].(map[string]any)
		if !ok {
			next = map[string]any{}
			cur[p] = next
		}
		cur = next
	}
}

func getPath(m map[string]any, dotted string) any {
	cur := m
	parts := strings.Split(dotted, ".")
	for i, p := range parts {
		if i == len(parts)-1 {
			return cur[p]
		}
		next, ok := cur[p].(map[string]any)
		if !ok {
			return nil
		}
		cur = next
	}
	return nil
}

func cmdCfg(args []string) error {
	if len(args) == 0 {
		return fmt.Errorf("usage: wb2api-ctl cfg <render|show|path>")
	}
	e := loadEnv()
	switch args[0] {
	case "render":
		return cfgRender(e, args[1:])
	case "show":
		return cfgShow(e)
	case "path":
		printJSON(map[string]any{"ok": true, "path": filepath.Join(e.DataDir, "config.json")})
		return nil
	default:
		return fmt.Errorf("未知子命令: %s", args[0])
	}
}

func cfgShow(e *Env) error {
	p := filepath.Join(e.DataDir, "config.json")
	b, err := os.ReadFile(p)
	if err != nil {
		return err
	}
	var m map[string]any
	if err := json.Unmarshal(b, &m); err != nil {
		return fmt.Errorf("解析 config.json 失败（拒绝覆盖真实文件）: %w", err)
	}
	printJSON(map[string]any{"ok": true, "path": p, "config": m})
	return nil
}

func cfgRender(e *Env, args []string) error {
	fs := flag.NewFlagSet("cfg render", flag.ContinueOnError)
	fs.SetOutput(os.Stderr)

	upPort := fs.Int("upstream-port", e.UpstreamPort, "上游监听端口（仅绑定 127.0.0.1）")
	apiKey := fs.String("api-key", e.UpstreamKey, "上游 api_key")
	maxBodyMB := fs.Int("max-body-mb", 8, "请求体上限 MB")

	softRate := fs.String("soft-rate", "600s", "软限流冷却基数")
	softRateMax := fs.String("soft-rate-max", "2h", "软限流退避上限")

	checkinH := fs.String("checkin-hours", "9,21", "签到时刻")
	travelH := fs.String("travel-hours", "9,21", "猫猫旅行时刻")
	activityH := fs.String("activity-hours", "10", "活跃上报时刻")
	keepaliveH := fs.String("keepalive-hours", "22", "token 保活时刻")
	schoolH := fs.String("school-hours", "12", "开学季任务时刻")
	catH := fs.String("cat-hours", "1", "夜猫子任务时刻")

	checkinOn := fs.Bool("checkin-enabled", true, "签到开关")
	travelOn := fs.Bool("travel-enabled", true, "猫猫旅行开关")
	activityOn := fs.Bool("activity-enabled", true, "活跃上报开关")
	keepaliveOn := fs.Bool("keepalive-enabled", true, "保活开关")
	schoolOn := fs.Bool("school-enabled", true, "开学季开关")
	catOn := fs.Bool("cat-enabled", true, "夜猫子开关")

	globalOn := fs.Bool("global-enabled", true, "国际版开关")
	timeout := fs.Int("timeout", 120, "上游超时秒")
	clientName := fs.String("client-name", "WorkBuddy", "上游 client_name")
	sanitize := fs.Bool("sanitize", true, "指纹脱敏")
	promptMode := fs.String("prompt-mode", "passthrough", "提示词模式 passthrough|custom")
	promptFile := fs.String("prompt-file", "", "自定义提示词文件")

	maxInFlight := fs.Int("max-in-flight", 3, "单账号最大在途请求")
	breakerThreshold := fs.Int("breaker-threshold", 3, "连续失败熔断阈值")
	breakerCooldown := fs.String("breaker-cooldown", "30m", "熔断冷却")
	breakerCooldownMax := fs.String("breaker-cooldown-max", "6h", "熔断冷却封顶")
	idleWeight := fs.Float64("idle-weight", 0.5, "闲置补偿权重")
	idleWeightMax := fs.Float64("idle-weight-max", 5.0, "闲置补偿上限")
	expiringSoon := fs.String("expiring-soon", "168h", "快过期积分窗口，0 关闭")

	stickyOn := fs.Bool("sticky", true, "会话粘性")
	stickyTTL := fs.String("sticky-ttl", "30m", "会话绑定时长")
	stickyGC := fs.String("sticky-gc", "5m", "会话清理周期")

	if err := fs.Parse(args); err != nil {
		return err
	}

	// ---- 校验（非法值直接拒绝，绝不写坏配置文件）----
	if *upPort <= 0 || *upPort > 65535 {
		return fmt.Errorf("上游端口非法: %d", *upPort)
	}
	if *maxBodyMB <= 0 || *maxBodyMB > 64 {
		return fmt.Errorf("请求体上限非法: %d", *maxBodyMB)
	}
	dur := map[string]string{
		"soft-rate": *softRate, "soft-rate-max": *softRateMax,
		"breaker-cooldown": *breakerCooldown, "breaker-cooldown-max": *breakerCooldownMax,
		"sticky-ttl": *stickyTTL, "sticky-gc": *stickyGC,
	}
	for k, v := range dur {
		if _, err := normDuration(v); err != nil {
			return fmt.Errorf("%s: %w", k, err)
		}
	}
	var expiring string
	if strings.TrimSpace(*expiringSoon) != "" && strings.TrimSpace(*expiringSoon) != "0" {
		s, err := normDuration(*expiringSoon)
		if err != nil {
			return fmt.Errorf("expiring-soon: %w", err)
		}
		expiring = s
	} else {
		expiring = "0s"
	}
	if *promptMode != "passthrough" && *promptMode != "custom" {
		return fmt.Errorf("prompt-mode 只能是 passthrough 或 custom")
	}
	hours := map[string][]int{}
	raw := map[string]string{
		"checkin": *checkinH, "travel": *travelH, "activity": *activityH,
		"keepalive": *keepaliveH, "school": *schoolH, "cat": *catH,
	}
	for k, v := range raw {
		h, err := parseHours(v)
		if err != nil {
			return fmt.Errorf("%s-hours: %w", k, err)
		}
		hours[k] = h
	}

	// ---- 读取现有配置，未知字段原样保留 ----
	cfgPath := filepath.Join(e.DataDir, "config.json")
	cfg := map[string]any{}
	if b, err := os.ReadFile(cfgPath); err == nil {
		if err := json.Unmarshal(b, &cfg); err != nil {
			return fmt.Errorf("现有 config.json 解析失败（拒绝覆盖真实文件）: %w", err)
		}
	} else if !os.IsNotExist(err) {
		return err
	}

	nd := func(s string) string { v, _ := normDuration(s); return v }

	// 安全基线：上游只允许监听回环，外网一律由 wb2api-ctl serve 代理。
	setPath(cfg, "listen", fmt.Sprintf("127.0.0.1:%d", *upPort))
	setPath(cfg, "api_key", *apiKey)
	setPath(cfg, "auth_dir", e.path("auths"))
	setPath(cfg, "state_file", e.path("data", "state.json"))
	setPath(cfg, "server.max_body_mb", *maxBodyMB)
	setPath(cfg, "cooldown.soft_rate", nd(*softRate))
	setPath(cfg, "cooldown.soft_rate_max", nd(*softRateMax))
	setPath(cfg, "schedule.checkin_hours", hours["checkin"])
	setPath(cfg, "schedule.travel_hours", hours["travel"])
	setPath(cfg, "schedule.activity_hours", hours["activity"])
	setPath(cfg, "schedule.keepalive_hours", hours["keepalive"])
	setPath(cfg, "schedule.school_hours", hours["school"])
	setPath(cfg, "schedule.cat_hours", hours["cat"])
	setPath(cfg, "schedule.checkin_enabled", *checkinOn)
	setPath(cfg, "schedule.travel_enabled", *travelOn)
	setPath(cfg, "schedule.activity_enabled", *activityOn)
	setPath(cfg, "schedule.keepalive_enabled", *keepaliveOn)
	setPath(cfg, "schedule.school_enabled", *schoolOn)
	setPath(cfg, "schedule.cat_enabled", *catOn)
	setPath(cfg, "global.enabled", *globalOn)
	setPath(cfg, "upstream.timeout_seconds", *timeout)
	setPath(cfg, "upstream.header_timeout_seconds", *timeout)
	setPath(cfg, "upstream.idle_timeout_seconds", 300)
	setPath(cfg, "upstream.client_name", *clientName)
	setPath(cfg, "features.sanitize_blacklist_fingerprints", *sanitize)
	setPath(cfg, "prompt.mode", *promptMode)
	setPath(cfg, "prompt.file", *promptFile)
	setPath(cfg, "pool.max_in_flight", *maxInFlight)
	setPath(cfg, "pool.breaker_threshold", *breakerThreshold)
	setPath(cfg, "pool.breaker_cooldown", nd(*breakerCooldown))
	setPath(cfg, "pool.breaker_cooldown_max", nd(*breakerCooldownMax))
	setPath(cfg, "pool.idle_weight_per_hour", *idleWeight)
	setPath(cfg, "pool.idle_weight_max", *idleWeightMax)
	setPath(cfg, "pool.expiring_soon", expiring)
	setPath(cfg, "session_sticky.enabled", *stickyOn)
	setPath(cfg, "session_sticky.ttl", nd(*stickyTTL))
	setPath(cfg, "session_sticky.gc_interval", nd(*stickyGC))

	if err := writeJSONFile(cfgPath, cfg, 0600); err != nil {
		return err
	}

	printJSON(map[string]any{
		"ok":     true,
		"path":   cfgPath,
		"listen": getPath(cfg, "listen"),
	})
	return nil
}
