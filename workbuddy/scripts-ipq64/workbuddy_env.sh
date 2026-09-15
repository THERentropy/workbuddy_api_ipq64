#!/bin/sh
# ============================================================================
# workbuddy_env.sh —— 公共环境：从 dbus 载入配置并导出给 wb2api-ctl
# 被其余 workbuddy_*.sh source，不直接执行。
# ============================================================================

WB_MODULE=workbuddy
# 二进制以 .gz 常驻 jffs，运行时解压到 /tmp（内存盘）：
# 既省闪存空间，又避免 UPX 在 aarch64 静态二进制上的 SIGILL 问题。
WB_GZ_DIR=/koolshare/bin
WB_BIN_DIR=/tmp/wb-bin
WB_SERVICE_LOG=/tmp/workbuddy.log
WB_TMP_DIR=/tmp

# wb_prep <name> —— 按需把 <name>.gz 解压到运行目录，返回可执行文件路径。
# 三个关键点（都是被实际故障教育出来的）：
#   1. 只有解压结果「非空」才替换目标文件 —— 否则 0 字节文件被 chmod 后
#      会被当成可用二进制，执行时静默无输出，极难排查；
#   2. gzip / zcat / gunzip 依次尝试 —— 不同固件 busybox 开启的小程序不同；
#   3. 错误写进服务日志而不是丢进 /dev/null，方便排障。
wb_prep() {
	mkdir -p "${WB_BIN_DIR}" 2>/dev/null
	if [ -f "${WB_GZ_DIR}/$1.gz" ]; then
		dst="${WB_BIN_DIR}/$1"
		if [ ! -s "${dst}" ] || [ "${WB_GZ_DIR}/$1.gz" -nt "${dst}" ]; then
			rm -f "${dst}.tmp" 2>/dev/null
			gzip -dc "${WB_GZ_DIR}/$1.gz" > "${dst}.tmp" 2>>"${WB_SERVICE_LOG}" \
				|| zcat "${WB_GZ_DIR}/$1.gz" > "${dst}.tmp" 2>>"${WB_SERVICE_LOG}" \
				|| gunzip -c "${WB_GZ_DIR}/$1.gz" > "${dst}.tmp" 2>>"${WB_SERVICE_LOG}"
			chmod 0755 "${dst}.tmp" 2>/dev/null
			if [ -s "${dst}.tmp" ]; then
				mv -f "${dst}.tmp" "${dst}" 2>/dev/null
			else
				echo "【$(date '+%Y-%m-%d %H:%M:%S')】 解压 $1 失败：输出为空（gzip/zcat/gunzip 均不可用？/tmp 空间不足？）" >> "${WB_SERVICE_LOG}"
				rm -f "${dst}.tmp" 2>/dev/null
			fi
		fi
		if [ -s "${dst}" ]; then
			echo "${dst}"
			return 0
		fi
	fi
	# 兼容未压缩部署（例如手动放置的二进制）
	if [ -s "${WB_GZ_DIR}/$1" ]; then
		chmod 0755 "${WB_GZ_DIR}/$1" 2>/dev/null
		echo "${WB_GZ_DIR}/$1"
		return 0
	fi
	echo "${WB_BIN_DIR}/$1"
}

WB_CTL=$(wb_prep wb2api-ctl)
WB_UPSTREAM_BIN=$(wb_prep wb2api)
# 软件中心的 httpd 把 /_temp/ 映射到 /tmp/upload/（不是 /tmp/！）
# 参考 rogsoft 的 fakehttp/dockroot 插件：脚本写 /tmp/upload/x.log，页面读 /_temp/x.log
WB_UPLOAD_DIR=/tmp/upload

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
export WB_AUDIT_DAYS=$(dbus_default workbuddy_audit_days 3)
export WB_AUDIT_MAX_MB=$(dbus_default workbuddy_audit_max_mb 2)
export WB_SERVICE_LOG
export WB_UPLOAD_DIR

# wb_file <文件名> —— 结果文件的真实路径
wb_file() {
	echo "${WB_UPLOAD_DIR}/$1"
}

# wb_out <文件名> —— 把 stdin 落成 /tmp/upload/<文件名>，页面通过 /_temp/<文件名> 读取。
# 同时在 /tmp 与 /www/_temp（少数固件）各留一份兜底。
wb_out() {
	mkdir -p "${WB_UPLOAD_DIR}" 2>/dev/null
	f="${WB_UPLOAD_DIR}/$1"
	cat > "${f}"
	cp -f "${f}" "${WB_TMP_DIR}/$1" 2>/dev/null
	# /www 是 httpd 的站点根，写一份到这里可以让 /_temp/<file> 直接命中；
	# /www 一般在内存盘上，不产生闪存写入。
	mkdir -p /www/_temp 2>/dev/null
	cp -f "${f}" "/www/_temp/$1" 2>/dev/null
	echo "${f}"
}

# wb_result_clear —— 动作开始前清掉上一次的结果。
# 页面是轮询取结果的，不清的话等待期间会读到「上一次」的旧值，界面会显示错东西。
wb_result_clear() {
	dbus set workbuddy_last_result="" >/dev/null 2>&1
}

# wb_result <文件名> —— 在 wb_out 基础上，把较短的结果同步写进 dbus。
# 不同固件 httpd 的 /_temp/ 映射目录可能不同（/tmp/upload/、/tmp/、/www/_temp/），
# 页面若三个文件都取不到，就退回读 dbus 的 workbuddy_last_result，保证关键操作不中断。
wb_result() {
	f=$(wb_out "$1")
	sz=$(wc -c < "${f}" 2>/dev/null)
	if [ -n "$sz" ] && [ "$sz" -lt 4000 ]; then
		dbus set workbuddy_last_result="$(cat "${f}")" >/dev/null 2>&1
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
