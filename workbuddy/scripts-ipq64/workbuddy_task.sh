#!/bin/sh
# ============================================================================
# workbuddy_task.sh —— 成长任务 / 开学季待办（走上游内嵌面板 /panel/api/*）
#
#   workbuddy_task.sh scan           → workbuddy_tasks.json      全账号待办扫描（只读）
#   workbuddy_task.sh run [--conc=N] → workbuddy_task_run.json   把待办排队执行（异步）
#   workbuddy_task.sh queue          → workbuddy_task_queue.json 队列进度（轮询用）
#
# 说明：
#   - 这三个接口来自 panel 版上游（linguo2625469/workbuddy2api-panel）内嵌的
#     /panel/api/*；换成不带面板的上游时，scan/run 会返回「上游二进制不含该面板接口」；
#   - 扫描与队列启动是同步 HTTP，逐账号调上游，账号多时偏慢，故 --timeout 放宽；
#   - 队列是异步的：run 立刻返回，进度靠 queue 轮询（页面每 2 秒取一次）。
# ============================================================================

source /koolshare/scripts/base.sh
source /koolshare/scripts/workbuddy_env.sh

action="$1"
[ $# -ge 1 ] && shift

case "${action}" in
	scan)
		out=workbuddy_tasks.json
		;;
	run)
		out=workbuddy_task_run.json
		;;
	*)
		out=workbuddy_task_queue.json
		;;
esac

# 页面是轮询取结果的：不清旧值的话，等待期间会先读到上一次的结果
wb_result_clear "${out}"

case "${action}" in
	scan)
		"${WB_CTL}" panel /panel/api/tasks/scan_all --post='{}' --timeout=180 \
			| wb_result "${out}"
		;;
	run)
		# 并发只允许 1-3：账号内串行、账号间并发，太高容易撞上游风控
		conc=1
		for a in "$@"; do
			case "${a}" in
				--conc=*) conc="${a#--conc=}" ;;
			esac
		done
		case "${conc}" in
			'' | *[!0-9]*) conc=1 ;;
		esac
		if [ "${conc}" -lt 1 ]; then conc=1; fi
		if [ "${conc}" -gt 3 ]; then conc=3; fi
		wb_log "成长任务队列启动（并发 ${conc}）"
		"${WB_CTL}" panel /panel/api/tasks/run_queue \
			--post="{\"concurrency\":${conc},\"growth\":true,\"school\":true}" \
			--timeout=120 | wb_result "${out}"
		;;
	queue)
		"${WB_CTL}" panel /panel/api/tasks/queue --timeout=30 | wb_out "${out}"
		;;
	*)
		echo '{"ok":false,"err":"用法: workbuddy_task.sh <scan|run|queue>"}' | wb_result "${out}"
		;;
esac

wb_respond
