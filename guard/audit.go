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
	"time"
)

// AuditRecord 一次调用的审计行，按天追加写入 JSONL。
// 路由器上不引入 SQLite/cgo，纯文本追加最省资源。
type AuditRecord struct {
	TS         int64   `json:"ts"`
	KeyID      string  `json:"key_id"`
	KeyName    string  `json:"key_name"`
	RemoteIP   string  `json:"ip"`
	Model      string  `json:"model"`
	Path       string  `json:"path"`
	Stream     bool    `json:"stream"`
	Status     int     `json:"status"`
	FirstByte  int64   `json:"first_byte_ms"`
	TotalMS    int64   `json:"total_ms"`
	PromptTok  int     `json:"prompt_tokens"`
	CompTok    int     `json:"completion_tokens"`
	Credit     float64 `json:"credit"` // 上游 usage.credit，未返回为 -1
	Err        string  `json:"err,omitempty"`
	Truncated  bool    `json:"truncated,omitempty"`
	Oversize   bool    `json:"oversize,omitempty"`
	KeyLimited bool    `json:"key_limited,omitempty"`
}

func auditDir(e *Env) string { return filepath.Join(e.DataDir, "audit") }

func auditFile(e *Env, t time.Time) string {
	return filepath.Join(auditDir(e), "audit-"+t.Format("20060102")+".jsonl")
}

func appendAudit(e *Env, rec AuditRecord) error {
	if err := os.MkdirAll(auditDir(e), 0755); err != nil {
		return err
	}
	p := auditFile(e, time.Unix(rec.TS, 0))

	// 写入前先看体积，超限就先滚动，避免单文件写爆 jffs
	if fi, err := os.Stat(p); err == nil && e.AuditMaxMB > 0 {
		if fi.Size() > int64(e.AuditMaxMB)*1024*1024 {
			rotated := strings.TrimSuffix(p, ".jsonl") + "." + strconv.FormatInt(time.Now().Unix(), 10) + ".jsonl"
			_ = os.Rename(p, rotated)
		}
	}

	data, err := json.Marshal(rec)
	if err != nil {
		return err
	}
	f, err := os.OpenFile(p, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		return err
	}
	defer f.Close()
	_, err = f.Write(append(data, '\n'))
	return err
}

// auditFiles 列出最近 days 天的审计文件（含滚动出来的副本），按时间倒序。
func auditFiles(e *Env, days int) ([]string, error) {
	dir := auditDir(e)
	entries, err := os.ReadDir(dir)
	if err != nil {
		if os.IsNotExist(err) {
			return []string{}, nil
		}
		return nil, err
	}
	cutoff := time.Now().AddDate(0, 0, -(days - 1)).Format("20060102")
	out := []string{}
	for _, en := range entries {
		if en.IsDir() {
			continue
		}
		n := en.Name()
		if !strings.HasPrefix(n, "audit-") || !strings.HasSuffix(n, ".jsonl") {
			continue
		}
		// audit-YYYYMMDD...
		if len(n) < 14 {
			continue
		}
		day := n[6:14]
		if day < cutoff {
			continue
		}
		out = append(out, filepath.Join(dir, n))
	}
	sort.Sort(sort.Reverse(sort.StringSlice(out)))
	return out, nil
}

func readAuditLines(files []string) ([]AuditRecord, error) {
	recs := []AuditRecord{}
	for _, f := range files {
		fh, err := os.Open(f)
		if err != nil {
			continue
		}
		dec := json.NewDecoder(fh)
		for dec.More() {
			var r AuditRecord
			if err := dec.Decode(&r); err != nil {
				break
			}
			recs = append(recs, r)
		}
		fh.Close()
	}
	sort.Slice(recs, func(i, j int) bool { return recs[i].TS < recs[j].TS })
	return recs, nil
}

func cmdLog(args []string) error {
	if len(args) == 0 {
		return fmt.Errorf("usage: wb2api-ctl log <tail|stat|clean>")
	}
	e := loadEnv()
	if err := e.ensureDirs(); err != nil {
		return err
	}

	switch args[0] {
	case "service":
		// 服务运行日志（/tmp/workbuddy.log），不落数据目录，避免写坏闪存
		p := os.Getenv("WB_SERVICE_LOG")
		if p == "" {
			p = "/tmp/workbuddy.log"
		}
		lines, err := tailLines(p, 200)
		if err != nil {
			lines = []string{}
		}
		printJSON(map[string]any{"ok": true, "path": p, "lines": lines})
		return nil

	case "tail":
		fs := flag.NewFlagSet("log tail", flag.ContinueOnError)
		fs.SetOutput(os.Stderr)
		n := fs.Int("n", 200, "返回条数")
		days := fs.Int("days", 2, "回溯天数")
		key := fs.String("key", "", "按密钥 ID 过滤")
		model := fs.String("model", "", "按模型过滤")
		status := fs.Int("status", 0, "按状态码过滤，0=不过滤")
		onlyErr := fs.Bool("err", false, "只看失败")
		if err := fs.Parse(args[1:]); err != nil {
			return err
		}
		files, err := auditFiles(e, *days)
		if err != nil {
			return err
		}
		recs, err := readAuditLines(files)
		if err != nil {
			return err
		}
		filtered := []AuditRecord{}
		for _, r := range recs {
			if *key != "" && r.KeyID != *key {
				continue
			}
			if *model != "" && r.Model != *model {
				continue
			}
			if *status != 0 && r.Status != *status {
				continue
			}
			if *onlyErr && r.Status >= 200 && r.Status < 300 {
				continue
			}
			filtered = append(filtered, r)
		}
		if len(filtered) > *n {
			filtered = filtered[len(filtered)-*n:]
		}
		printJSON(map[string]any{
			"ok":      true,
			"total":   len(recs),
			"count":   len(filtered),
			"limited": len(recs) > *n,
			"records": filtered,
		})
		return nil

	case "stat":
		fs := flag.NewFlagSet("log stat", flag.ContinueOnError)
		fs.SetOutput(os.Stderr)
		days := fs.Int("days", 7, "统计天数")
		if err := fs.Parse(args[1:]); err != nil {
			return err
		}
		files, err := auditFiles(e, *days)
		if err != nil {
			return err
		}
		recs, err := readAuditLines(files)
		if err != nil {
			return err
		}

		total := len(recs)
		ok := 0
		var firstByteSum, creditSum int64
		var promptTok, compTok int64
		byDay := map[string]int{}
		byKey := map[string]int{}
		byModel := map[string]int{}
		byStatus := map[string]int{}
		creditByKey := map[string]float64{}
		for _, r := range recs {
			day := time.Unix(r.TS, 0).Format("2006-01-02")
			byDay[day]++
			label := r.KeyName
			if label == "" {
				label = r.KeyID
			}
			byKey[label]++
			if r.Model != "" {
				byModel[r.Model]++
			}
			byStatus[strconv.Itoa(r.Status)]++
			firstByteSum += r.FirstByte
			promptTok += int64(r.PromptTok)
			compTok += int64(r.CompTok)
			if r.Credit > 0 {
				creditSum += int64(r.Credit)
				creditByKey[label] += r.Credit
			}
			if r.Status >= 200 && r.Status < 300 {
				ok++
			}
		}
		avgFirst := int64(0)
		rate := 0.0
		if total > 0 {
			avgFirst = firstByteSum / int64(total)
			rate = float64(ok) / float64(total) * 100
		}
		printJSON(map[string]any{
			"ok":            true,
			"days":          *days,
			"total":         total,
			"success":       ok,
			"success_rate":  rate,
			"avg_first_ms":  avgFirst,
			"credit_total":  creditSum,
			"prompt_tokens": promptTok,
			"comp_tokens":   compTok,
			"by_day":        byDay,
			"by_key":        byKey,
			"by_model":      byModel,
			"by_status":     byStatus,
			"credit_by_key": creditByKey,
		})
		return nil

	case "clean":
		dir := auditDir(e)
		entries, err := os.ReadDir(dir)
		if err != nil && !os.IsNotExist(err) {
			return err
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
		printJSON(map[string]any{"ok": true, "removed": removed, "retention_days": e.AuditDays})
		return nil

	default:
		return fmt.Errorf("未知子命令: %s", args[0])
	}
}
