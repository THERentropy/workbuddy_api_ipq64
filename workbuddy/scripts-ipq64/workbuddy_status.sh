#!/bin/sh
# ============================================================================
# workbuddy_status.sh —— 状态查询
#   workbuddy_status.sh            → /tmp/workbuddy_status.json（账号池）
#   workbuddy_status.sh models     → /tmp/workbuddy_models.json（可用模型）
# 同时输出 /tmp/workbuddy_runtime.json（进程与运行信息）
# ============================================================================

source /koolshare/scripts/base.sh
source /koolshare/scripts/workbuddy_env.sh

case "$1" in
	models)
		"${WB_CTL}" status models | wb_out workbuddy_models.json
		;;
	*)
		"${WB_CTL}" status | wb_out workbuddy_status.json
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
