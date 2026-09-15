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

case "${action}" in
	url)
		out=workbuddy_login_url.json
		"${WB_CTL}" login "$@" | wb_out "${out}"
		;;
	poll)
		out=workbuddy_login_poll.json
		"${WB_CTL}" login "$@" | wb_out "${out}"
		# 落盘成功后重启上游，让新凭证立刻进入账号池
		if grep -q '"ok":true' "$(wb_file ${out})" 2>/dev/null; then
			wb_log "新增/更新账号凭证，重启服务加载"
			/koolshare/scripts/workbuddy_config.sh restart
		fi
		;;
	remove|signin)
		out=workbuddy_action.json
		"${WB_CTL}" account "$@" | wb_out "${out}"
		if grep -q '"ok":true' "$(wb_file ${out})" 2>/dev/null; then
			/koolshare/scripts/workbuddy_config.sh restart
		fi
		;;
	*)
		"${WB_CTL}" account "$@" | wb_out workbuddy_accounts.json
		;;
esac
