#!/bin/sh
# ============================================================================
# workbuddy_account.sh —— 账号纳管
#   workbuddy_account.sh list
#   workbuddy_account.sh url   --realm=cn
#   workbuddy_account.sh poll  --realm=cn
#   workbuddy_account.sh remove --uid=xxx
#   workbuddy_account.sh signin
# 参数由软件中心 POST /_api/ 的 params 数组原样透传。
# ============================================================================

source /koolshare/scripts/base.sh
source /koolshare/scripts/workbuddy_env.sh

action="$1"

# 1) 定好结果文件名
# 2) 用到的二进制按需解压（wb2api-ctl 是按 WB_BIN_DIR 找 login/signin 的）
# 3) 清掉上一次的结果 —— 页面是轮询取结果的，不清的话等待期间会先读到旧值
case "${action}" in
	url)
		out=workbuddy_login_url.json
		wb_prep wb2api-login >/dev/null
		;;
	poll)
		out=workbuddy_login_poll.json
		wb_prep wb2api-login >/dev/null
		;;
	signin)
		out=workbuddy_action.json
		wb_prep wb2api-signin >/dev/null
		;;
	balance)
		# 全量刷新余额走上游内嵌面板：顺带解冻余额已恢复的冷却账号
		out=workbuddy_action.json
		;;
	remove)
		out=workbuddy_action.json
		;;
	*)
		out=workbuddy_accounts.json
		;;
esac
wb_result_clear "${out}"

case "${action}" in
	url)
		"${WB_CTL}" login "$@" | wb_result "${out}"
		;;
	poll)
		"${WB_CTL}" login "$@" | wb_result "${out}"
		# 落盘成功后重启上游，让新凭证立刻进入账号池
		if grep -q '"ok":true' "$(wb_file ${out})" 2>/dev/null; then
			wb_log "新增/更新账号凭证，重启服务加载"
			/koolshare/scripts/workbuddy_config.sh restart
		fi
		;;
	balance)
		"${WB_CTL}" panel /panel/api/balance_all --post='{}' --timeout=120 | wb_result "${out}"
		;;
	remove|signin)
		"${WB_CTL}" account "$@" | wb_result "${out}"
		if grep -q '"ok":true' "$(wb_file ${out})" 2>/dev/null; then
			/koolshare/scripts/workbuddy_config.sh restart
		fi
		;;
	*)
		"${WB_CTL}" account "$@" | wb_result "${out}"
		;;
esac

wb_respond
