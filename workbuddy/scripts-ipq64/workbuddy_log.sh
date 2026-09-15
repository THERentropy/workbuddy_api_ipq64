#!/bin/sh
# ============================================================================
# workbuddy_log.sh —— 审计日志与服务日志
#   workbuddy_log.sh tail --n=200 --days=2 [--key=kid-x] [--model=glm-5.2] [--status=200] [--err]
#   workbuddy_log.sh stat --days=7
#   workbuddy_log.sh clean
#   workbuddy_log.sh service          → 服务运行日志最后 200 行
# ============================================================================

source /koolshare/scripts/base.sh
source /koolshare/scripts/workbuddy_env.sh

case "$1" in
	service)
		"${WB_CTL}" log service | wb_out workbuddy_servicelog.json
		;;
	*)
		"${WB_CTL}" log "$@" | wb_out workbuddy_log.json
		;;
esac

wb_respond
