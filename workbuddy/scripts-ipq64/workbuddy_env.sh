#!/bin/sh
# ============================================================================
# workbuddy_env.sh —— 公共环境：从 dbus 载入配置并导出给 wb2api-ctl
# 被其余 workbuddy_*.sh source，不直接执行。
# ============================================================================

WB_MODULE=workbuddy
WB_BIN_DIR=/koolshare/bin
WB_CTL=${WB_BIN_DIR}/wb2api-ctl
WB_UPSTREAM_BIN=${WB_BIN_DIR}/wb2api
WB_SERVICE_LOG=/tmp/workbuddy.log
WB_TMP_DIR=/tmp

# dbus_default <key> <default> —— 读取 dbus，空值回落到默认值
dbus_default() {
	v=$(dbus get "$1")
	if [ -z "$v" ]; then
		v="$2"
	fi
	echo "$v"
}

WB_DATA_DIR=$(dbus_default workbuddy_data_dir /koolshare/etc/workbuddy)
WB_UPSTREAM_PORT=$(dbus_default workbuddy_upstream_port 7863)
WB_LISTEN_PORT=$(dbus_default workbuddy_listen_port 17863)
WB_UPSTREAM_KEY=$(dbus get workbuddy_api_key)

export WB_DATA_DIR
export WB_UPSTREAM_PORT
export WB_UPSTREAM_KEY
export WB_BIN_DIR
export WB_LISTEN=":${WB_LISTEN_PORT}"
export WB_UPSTREAM="http://127.0.0.1:${WB_UPSTREAM_PORT}"
export WB_AUDIT_DAYS=$(dbus_default workbuddy_audit_days 7)
export WB_AUDIT_MAX_MB=$(dbus_default workbuddy_audit_max_mb 8)

# wb_out <文件名> —— 把 stdin 落成 /tmp/<文件名>（httpd 通过 /_temp/ 暴露）。
# 部分固件把 _temp 放在 /www 下，这里同步一份，保证页面一定能读到。
wb_out() {
	f="${WB_TMP_DIR}/$1"
	cat > "${f}"
	if [ -d "/www/_temp" ]; then
		cp -f "${f}" "/www/_temp/$1" 2>/dev/null
	fi
	echo "${f}"
}

# wb_log <文本> —— 服务日志写 /tmp（内存盘），避免频繁写 jffs。
wb_log() {
	echo "【$(date '+%Y-%m-%d %H:%M:%S')】 $*" >> "${WB_SERVICE_LOG}"
	wb_rotate_log
}

wb_rotate_log() {
	if [ -f "${WB_SERVICE_LOG}" ]; then
		sz=$(wc -c < "${WB_SERVICE_LOG}" 2>/dev/null)
		if [ -n "$sz" ] && [ "$sz" -gt 524288 ]; then
			tail -c 262144 "${WB_SERVICE_LOG}" > "${WB_SERVICE_LOG}.tmp" 2>/dev/null
			mv -f "${WB_SERVICE_LOG}.tmp" "${WB_SERVICE_LOG}" 2>/dev/null
		fi
	fi
}

# wb_pidof <二进制路径> —— 取主进程 PID（busybox pidof 只认进程名，故取 basename）
wb_pidof() {
	pidof "$(basename "$1")" 2>/dev/null | awk '{print $1}'
}

# wb_esc <文本> —— 转义后用于拼 JSON 字符串
wb_esc() {
	printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}
