#!/bin/sh
# ============================================================================
# workbuddy_env.sh —— 公共环境：从 dbus 载入配置并导出给 wb2api-ctl
# 被其余 workbuddy_*.sh source，不直接执行。
# ============================================================================

WB_MODULE=workbuddy

# ============================================================================
# 软件中心 /_api/ 的参数约定（实机验证 + 官方 aliddns_config.sh 印证）
#
#   脚本收到的「第一个参数是请求 id」，真正的 params 从 $2 开始：
#     POST {"id":1234,"method":"workbuddy_account.sh","params":["list"]}
#       → workbuddy_account.sh 收到：1234 list
#   官方脚本的写法就是  case $2 in <flag>) http_response "$1" ;; esac
#
#   所以每个入口脚本开头都要丢掉这个 id（wb_strip_id），结束时再把 id
#   回给页面（wb_respond）—— 页面据此确认脚本真的被执行了，而不是静默失败。
# ============================================================================
WB_REQ_ID="$1"

# 就地丢掉请求 id。本文件是被各入口脚本 source 的，此时位置参数就是
# 调用脚本自己的；在 source 上下文里 shift 会直接作用到调用脚本，
# 所以各脚本不需要再各自处理一次。
# 判断依据是「第一个参数是纯数字且后面还有参数」，因此手工执行
# （ssh 里直接跑，如 `workbuddy_account.sh url --realm=cn`）不受影响。
if [ $# -ge 2 ]; then
	case "$1" in
		'' | *[!0-9]*) ;;
		*) shift ;;
	esac
fi

# wb_respond —— 按官方约定把请求 id 回给页面：{"result":<id>}
wb_respond() {
	case "${WB_REQ_ID}" in
		'' | *[!0-9]*) return 0 ;;
	esac
	echo "{\"result\":${WB_REQ_ID}}"
}
# 二进制以 .gz 常驻 jffs，运行时解压到 /tmp（内存盘）：
# 既省闪存空间，又避免 UPX 在 aarch64 静态二进制上的 SIGILL 问题。
WB_GZ_DIR=/koolshare/bin
WB_BIN_DIR=/tmp/wb-bin
WB_SERVICE_LOG=/tmp/workbuddy.log
WB_TMP_DIR=/tmp

# 二进制体积下限（字节）。4 个二进制最小的也有 4.9MB，
# 低于 1MB 一律视为解压残缺，宁可报错也不要交出半个文件。
WB_MIN_BIN_SIZE=1048576

# wb_prep <name> —— 按需把 <name>.gz 解压到运行目录，返回可执行文件路径。
# 四个关键点（都是被实际故障教育出来的）：
#   1. gzip / zcat / gunzip 依次尝试 —— 不同固件 busybox 开启的小程序不同；
#   2. 只有解压结果「非空且体积合理」才替换目标文件 —— 否则 0 字节或截断的文件
#      被 chmod 后会被当成可用二进制，执行时静默无输出，极难排查；
#   3. 错误写进服务日志而不是丢进 /dev/null，方便排障；
#   4. 没有 .gz 就直接用同名 ELF —— 兼容 UPX 包与手动部署。
wb_prep() {
	mkdir -p "${WB_BIN_DIR}" 2>/dev/null
	if [ -f "${WB_GZ_DIR}/$1.gz" ]; then
		dst="${WB_BIN_DIR}/$1"
		if [ "${WB_GZ_DIR}/$1.gz" -nt "${dst}" ] || [ ! -f "${dst}" ] \
			|| [ "$(wc -c < "${dst}" 2>/dev/null)" -lt "${WB_MIN_BIN_SIZE}" ]; then
			rm -f "${dst}.tmp" 2>/dev/null
			gzip -dc "${WB_GZ_DIR}/$1.gz" > "${dst}.tmp" 2>>"${WB_SERVICE_LOG}" \
				|| zcat "${WB_GZ_DIR}/$1.gz" > "${dst}.tmp" 2>>"${WB_SERVICE_LOG}" \
				|| gunzip -c "${WB_GZ_DIR}/$1.gz" > "${dst}.tmp" 2>>"${WB_SERVICE_LOG}"
			sz=$(wc -c < "${dst}.tmp" 2>/dev/null)
			[ -z "${sz}" ] && sz=0
			if [ "${sz}" -ge "${WB_MIN_BIN_SIZE}" ]; then
				chmod 0755 "${dst}.tmp" 2>/dev/null
				mv -f "${dst}.tmp" "${dst}" 2>/dev/null
			else
				echo "【$(date '+%Y-%m-%d %H:%M:%S')】 解压 $1 失败：只得到 ${sz} 字节（应 ≥ ${WB_MIN_BIN_SIZE}）。可能 gzip/zcat/gunzip 均不可用，或 /tmp 空间不足。" >> "${WB_SERVICE_LOG}"
				rm -f "${dst}.tmp" 2>/dev/null
				echo "${WB_BIN_DIR}/$1"
				return 1
			fi
		fi
		if [ -s "${dst}" ]; then
			echo "${dst}"
			return 0
		fi
	fi
	# 兼容未压缩部署（UPX 包 / 手动放置的 ELF）。
	# 必须软链一份到 WB_BIN_DIR：wb2api-ctl 是自己按 WB_BIN_DIR 找 login/signin 的，
	# 只返回 /koolshare/bin 的路径会让它报「二进制不存在: /tmp/wb-bin/wb2api-login」。
	if [ -s "${WB_GZ_DIR}/$1" ]; then
		chmod 0755 "${WB_GZ_DIR}/$1" 2>/dev/null
		ln -sf "${WB_GZ_DIR}/$1" "${WB_BIN_DIR}/$1" 2>/dev/null
		if [ -s "${WB_BIN_DIR}/$1" ]; then
			echo "${WB_BIN_DIR}/$1"
		else
			echo "${WB_GZ_DIR}/$1"
		fi
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
# 同时在 /tmp 留一份兜底。
# ★ 不要往 stdout 写任何东西：/_api/ 的响应体只能是结尾的 {"result":<id>}，
#   多一行路径就不是合法 JSON，页面会判定请求失败。
wb_out() {
	mkdir -p "${WB_UPLOAD_DIR}" 2>/dev/null
	f="${WB_UPLOAD_DIR}/$1"
	cat > "${f}"
	cp -f "${f}" "${WB_TMP_DIR}/$1" 2>/dev/null
}

# wb_result_clear <文件名> —— 动作开始前清掉上一次的结果（结果文件 + dbus 通道）。
# 页面是轮询取结果的，不清的话等待期间会读到「上一次」的旧值，界面会显示错东西。
wb_result_clear() {
	rm -f "${WB_UPLOAD_DIR}/$1" "${WB_TMP_DIR}/$1" 2>/dev/null
	dbus set workbuddy_last_result="" >/dev/null 2>&1
}

# wb_result <文件名> —— 在 wb_out 基础上，把较短的结果同步写进 dbus。
# 不同固件 httpd 的 /_temp/ 映射目录可能不同（/tmp/upload/、/tmp/、/www/_temp/），
# 页面若三个文件都取不到，就退回读 dbus 的 workbuddy_last_result，保证关键操作不中断。
wb_result() {
	wb_out "$1"
	f=$(wb_file "$1")
	sz=$(wc -c < "${f}" 2>/dev/null)
	if [ -n "$sz" ] && [ "$sz" -lt 4000 ]; then
		dbus set workbuddy_last_result="$(cat "${f}")" >/dev/null 2>&1
	fi
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
