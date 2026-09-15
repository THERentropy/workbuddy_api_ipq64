#!/bin/sh
# ============================================================================
# workbuddy_status.sh —— 状态查询
#   workbuddy_status.sh            → /tmp/workbuddy_status.json（账号池）
#   workbuddy_status.sh models     → /tmp/workbuddy_models.json（可用模型）
# 同时输出 /tmp/workbuddy_runtime.json（进程与运行信息）
# ============================================================================

source /koolshare/scripts/base.sh
source /koolshare/scripts/workbuddy_env.sh

# --dbus：由页面在「文件通道取不到」时追加，此时把结果同步写进 dbus 兜底。
# 正常情况不写，避免 30 秒一次的状态轮询频繁写 nvram。
USE_DBUS=0
for a in "$@"; do
	[ "${a}" = "--dbus" ] && USE_DBUS=1
done

case "$1" in
	models)
		if [ "${USE_DBUS}" = "1" ]; then
			"${WB_CTL}" status models | wb_result workbuddy_models.json
		else
			"${WB_CTL}" status models | wb_out workbuddy_models.json
		fi
		;;
	*)
		if [ "${USE_DBUS}" = "1" ]; then
			"${WB_CTL}" status | wb_result workbuddy_status.json
		else
			"${WB_CTL}" status | wb_out workbuddy_status.json
		fi
		;;
esac

up=$(wb_pidof "${WB_UPSTREAM_BIN}")
ctl=$(wb_pidof "${WB_CTL}")

printf '{"ok":true,"enable":"%s","upstream_pid":"%s","ctl_pid":"%s","listen_port":"%s","upstream_port":"%s","data_dir":"%s","version":"%s","auto_start":"%s","wan":"%s","watchdog":"%s"}\n' \
	"$(dbus get workbuddy_enable)" \
	"${up}" "${ctl}" \
	"${WB_LISTEN_PORT}" "${WB_UPSTREAM_PORT}" \
	"$(wb_esc "${WB_DATA_DIR}")" \
	"$(dbus get workbuddy_version)" \
	"$(dbus get workbuddy_auto_start)" \
	"$(dbus get workbuddy_wan)" \
	"$(dbus_default workbuddy_watchdog 1)" | wb_out workbuddy_runtime.json

wb_respond
