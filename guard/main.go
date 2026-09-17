// Command wb2api-ctl 是 workbuddy 插件在路由器上的「瑞士军刀」。
//
// 路由器上既没有 python3 也没有 jq，busybox 的 sed/awk 解析 JSON 极不可靠，
// 因此所有需要读写 JSON 的动作（上游配置渲染、OAuth 登录落盘、账号状态查询、
// 密钥库、审计日志）全部收敛到这个静态二进制里，shell 脚本只负责搬运。
//
// 子命令：
//   serve    反向代理网关：多密钥鉴权 + 限流 + 审计，转发到上游 127.0.0.1:7863
//   cfg      渲染 / 查看上游 config.json
//   login    OAuth 登录编排（url / poll）
//   account  账号列表 / 删除 / 手动签到
//   status   查询上游 /healthz、/status、/v1/models
//   key      多密钥分发（add / list / del / enable / disable）
//   policy   全局入站 IP 白黑名单
//   log      审计日志 tail / stat / clean
//   migrate  数据目录迁移
//   panel    透传上游内嵌面板的 /panel/api/*（成长任务扫描 / 一键完成队列）
//
// 约定：所有子命令都向 stdout 输出一行 JSON（成功 {"ok":true,...}，失败
// {"ok":false,"err":"..."} 且退出码非 0），便于脚本直接重定向成页面可读文件。
package main

import (
	"fmt"
	"os"
)

var version = "1.0.0"

func usage() {
	fmt.Fprintf(os.Stderr, `wb2api-ctl %s — workbuddy 插件控制工具

用法:
  wb2api-ctl serve    [--listen=:17863]
  wb2api-ctl cfg      <render|show|path> [flags]
  wb2api-ctl login    <url|poll> [--realm=cn|global]
  wb2api-ctl account  <list|remove|signin> [--uid=xxx]
  wb2api-ctl status   [models]
  wb2api-ctl key      <add|list|del|enable|disable> [flags]
  wb2api-ctl policy   <show|set> [--ip-allow=cidr,cidr] [--ip-deny=cidr,cidr]
  wb2api-ctl log      <tail|stat|clean> [flags]
  wb2api-ctl migrate  <新数据目录> [--delete-old]
  wb2api-ctl panel    </panel/api/路径> [--post=<json>] [--timeout=秒]
  wb2api-ctl version

环境变量:
  WB_DATA_DIR       数据目录（默认 /koolshare/etc/workbuddy）
  WB_LISTEN         对外监听地址（默认 :17863）
  WB_UPSTREAM_PORT  上游监听端口（默认 7863，仅绑定 127.0.0.1）
  WB_UPSTREAM_KEY   上游 api_key
  WB_BIN_DIR        二进制目录（默认 /koolshare/bin）
  WB_AUDIT_DAYS     审计日志保留天数（默认 7）
  WB_AUDIT_MAX_MB   单个审计日志文件上限 MB（默认 8）
`, version)
}

func main() {
	if len(os.Args) < 2 {
		usage()
		os.Exit(2)
	}

	var err error
	switch os.Args[1] {
	case "serve":
		err = cmdServe(os.Args[2:])
	case "cfg":
		err = cmdCfg(os.Args[2:])
	case "login":
		err = cmdLogin(os.Args[2:])
	case "account":
		err = cmdAccount(os.Args[2:])
	case "status":
		err = cmdStatus(os.Args[2:])
	case "key":
		err = cmdKey(os.Args[2:])
	case "policy":
		err = cmdPolicy(os.Args[2:])
	case "log":
		err = cmdLog(os.Args[2:])
	case "migrate":
		err = cmdMigrate(os.Args[2:])
	case "panel":
		err = cmdPanel(os.Args[2:])
	case "version", "-v", "--version":
		printJSON(map[string]any{"ok": true, "version": version})
		return
	default:
		usage()
		os.Exit(2)
	}

	if err != nil {
		printJSON(map[string]any{"ok": false, "err": err.Error()})
		os.Exit(1)
	}
}
