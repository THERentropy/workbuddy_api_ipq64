package main

import (
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
)

// cmdMigrate 把整个数据目录搬到新位置（例如从 jffs 迁到 U 盘），
// 迁移完成后由 shell 更新 dbus 里的路径并重启服务。
func cmdMigrate(args []string) error {
	fs := flag.NewFlagSet("migrate", flag.ContinueOnError)
	fs.SetOutput(os.Stderr)
	deleteOld := fs.Bool("delete-old", false, "迁移成功后删除旧目录")
	if err := fs.Parse(args); err != nil {
		return err
	}
	if fs.NArg() < 1 {
		return fmt.Errorf("usage: wb2api-ctl migrate <新数据目录> [--delete-old]")
	}

	e := loadEnv()
	old := e.DataDir
	newDir := strings.TrimRight(fs.Arg(0), "/")
	if newDir == "" {
		return fmt.Errorf("新数据目录不能为空")
	}
	if newDir == old {
		return fmt.Errorf("新目录与当前目录相同，无需迁移")
	}
	if strings.HasPrefix(newDir, old+"/") {
		return fmt.Errorf("新目录不能是当前目录的子目录")
	}

	// 目标必须是可写目录（父目录存在即可）
	if fi, err := os.Stat(newDir); err == nil {
		if !fi.IsDir() {
			return fmt.Errorf("目标已存在且不是目录: %s", newDir)
		}
	} else {
		if parent := filepath.Dir(newDir); parent != "" {
			if pfi, err := os.Stat(parent); err != nil || !pfi.IsDir() {
				return fmt.Errorf("目标父目录不存在: %s", parent)
			}
		}
	}

	if err := os.MkdirAll(filepath.Join(newDir, "auths"), 0755); err != nil {
		return fmt.Errorf("创建目标目录失败: %w", err)
	}
	if err := os.MkdirAll(filepath.Join(newDir, "data"), 0755); err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Join(newDir, "audit"), 0755); err != nil {
		return err
	}

	copied := 0
	failed := 0
	err := filepath.Walk(old, func(p string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		rel, err := filepath.Rel(old, p)
		if err != nil {
			return err
		}
		dst := filepath.Join(newDir, rel)
		if info.IsDir() {
			return os.MkdirAll(dst, 0755)
		}
		if err := copyFile(p, dst, info.Mode().Perm()); err != nil {
			failed++
			return nil // 单个文件失败不中断整体迁移
		}
		copied++
		return nil
	})
	if err != nil {
		return err
	}

	// 校验：关键文件必须到位
	need := []string{"keys.json", "guard.json", "config.json"}
	missing := []string{}
	for _, n := range need {
		if _, err := os.Stat(filepath.Join(old, n)); err != nil {
			continue // 旧目录本来就没有，不算缺失
		}
		if _, err := os.Stat(filepath.Join(newDir, n)); err != nil {
			missing = append(missing, n)
		}
	}
	if len(missing) > 0 {
		return fmt.Errorf("迁移校验失败，缺少文件: %s（旧数据未删除）", strings.Join(missing, ", "))
	}

	if *deleteOld && failed == 0 {
		_ = os.RemoveAll(old)
	}

	printJSON(map[string]any{
		"ok":         true,
		"from":       old,
		"to":         newDir,
		"copied":     copied,
		"failed":     failed,
		"old_removed": *deleteOld && failed == 0,
	})
	return nil
}

func copyFile(src, dst string, perm os.FileMode) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()
	out, err := os.OpenFile(dst, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, perm)
	if err != nil {
		return err
	}
	if _, err := io.Copy(out, in); err != nil {
		out.Close()
		return err
	}
	return out.Close()
}
