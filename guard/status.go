package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

func httpGet(url, bearer string, timeout time.Duration) (int, []byte, error) {
	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		return 0, nil, err
	}
	if bearer != "" {
		req.Header.Set("Authorization", "Bearer "+bearer)
	}
	cli := &http.Client{Timeout: timeout}
	resp, err := cli.Do(req)
	if err != nil {
		return 0, nil, err
	}
	defer resp.Body.Close()
	b, err := io.ReadAll(io.LimitReader(resp.Body, 4<<20))
	return resp.StatusCode, b, err
}

func getJSONMap(url, bearer string, timeout time.Duration) (map[string]any, error) {
	code, body, err := httpGet(url, bearer, timeout)
	if err != nil {
		return nil, err
	}
	if code < 200 || code >= 300 {
		return nil, fmt.Errorf("上游返回 %d: %.200s", code, string(body))
	}
	m := map[string]any{}
	if err := json.Unmarshal(body, &m); err != nil {
		return nil, fmt.Errorf("上游返回非 JSON: %w", err)
	}
	return m, nil
}

func cmdStatus(args []string) error {
	e := loadEnv()
	mode := ""
	if len(args) > 0 {
		mode = args[0]
	}

	// 先探活：/healthz 不需要鉴权，用它区分「没启动」和「鉴权失败」
	health, herr := getJSONMap(e.UpstreamURL+"/healthz", "", 5*time.Second)
	if herr != nil {
		printJSON(map[string]any{
			"ok":       true,
			"running":  false,
			"reachable": false,
			"err":      herr.Error(),
			"accounts": []any{},
		})
		return nil
	}

	if mode == "ping" {
		printJSON(map[string]any{"ok": true, "running": true, "health": health})
		return nil
	}

	if mode == "models" {
		m, err := getJSONMap(e.UpstreamURL+"/v1/models", e.UpstreamKey, 15*time.Second)
		if err != nil {
			return err
		}
		printJSON(map[string]any{"ok": true, "raw": m})
		return nil
	}

	st, err := getJSONMap(e.UpstreamURL+"/status", e.UpstreamKey, 10*time.Second)
	if err != nil {
		return err
	}
	accounts, _ := st["accounts"].([]any)
	if accounts == nil {
		accounts = []any{}
	}
	printJSON(map[string]any{
		"ok":              true,
		"running":         true,
		"reachable":       true,
		"total":           asInt64(st["total"]),
		"healthy":         asInt64(st["healthy"]),
		"cooling":         asInt64(st["cooling"]),
		"disabled":        asInt64(st["disabled"]),
		"in_flight_full":  asInt64(st["in_flight_full"]),
		"sticky_sessions": asInt64(st["sticky_sessions"]),
		"redis_mode":      asString(st["redis_mode"]),
		"accounts":        accounts,
	})
	return nil
}
