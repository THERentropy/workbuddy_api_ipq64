#!/bin/sh
# ============================================================================
# install.sh —— workbuddy 插件安装脚本（koolshare ipq64 软件中心）
# ============================================================================

source /koolshare/scripts/base.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'

DIR=$(cd $(dirname $0); pwd)
module=workbuddy
MODEL=
FW_TYPE_CODE=
FW_TYPE_NAME=

get_model() {
	local ODMPID=$(nvram get odmpid 2>/dev/null)
	local PRODUCTID=$(nvram get productid 2>/dev/null)
	if [ -n "${ODMPID}" ]; then
		MODEL="${ODMPID}"
	else
		MODEL="${PRODUCTID}"
	fi
}

get_fw_type() {
	local KS_TAG=$(nvram get extendno 2>/dev/null | grep -Eo "kool.+")
	if [ -d "/koolshare" ]; then
		if [ -n "${KS_TAG}" ]; then
			FW_TYPE_CODE="2"
			FW_TYPE_NAME="${KS_TAG}官改固件"
		else
			FW_TYPE_CODE="4"
			FW_TYPE_NAME="koolshare梅林改版固件"
		fi
	else
		FW_TYPE_CODE="1"
		FW_TYPE_NAME="华硕官方固件"
	fi
}

# platform_test —— 只放行 ipq64（aarch64）平台的 koolshare 软件中心
platform_test() {
	local ARCH=$(uname -m)
	local LINUX_VER=$(uname -r | awk -F"." '{print $1$2}')
	local VALID=$(cat ${DIR}/.valid 2>/dev/null)
	if [ -d "/koolshare" ] && [ -f "/koolshare/scripts/base.sh" ] \
		&& [ "${LINUX_VER}" -ge "41" ] \
		&& [ "${ARCH}" = "aarch64" -o "${ARCH}" = "arm64" -o "${ARCH}" = "armv8l" ]; then
		echo_date 机型："${MODEL} ${FW_TYPE_NAME}（${ARCH} / 内核$(uname -r)）符合安装要求，开始安装插件！"
		if [ "${VALID}" != "ipq64" ]; then
			echo_date "警告：安装包平台标识为 [${VALID}]，请确认下载的是 ipq64 版本"
		fi
	else
		exit_install 1
	fi
}

exit_install() {
	local state=$1
	case $state in
		1)
			echo_date "本插件适用于【koolshare ipq64 软件中心】固件平台！"
			echo_date "你的固件平台不能安装！！!"
			echo_date "支持平台：https://github.com/koolshare/rogsoft（ipq64 分支）"
			echo_date "退出安装！"
			rm -rf /tmp/${module}* >/dev/null 2>&1
			exit 1
			;;
		0|*)
			rm -rf /tmp/${module}* >/dev/null 2>&1
			exit 0
			;;
	esac
}

# set_skin 通过固件 CSS 主色判断皮肤：ROG 红 / TUF 橙 / TS 青 / ASUSWRT
set_skin() {
	local UI_TYPE=ASUSWRT
	local SC_SKIN=$(nvram get sc_skin 2>/dev/null)
	local ROG_FLAG=$(grep -o "680516" /www/form_style.css 2>/dev/null | head -n1)
	local TUF_FLAG=$(grep -o "D0982C" /www/form_style.css 2>/dev/null | head -n1)
	local TS_FLAG=$(grep -o "2ED9C3" /www/css/difference.css 2>/dev/null | head -n1)
	[ -n "${TS_FLAG}" ] && UI_TYPE="TS"
	[ -n "${TUF_FLAG}" ] && UI_TYPE="TUF"
	[ -n "${ROG_FLAG}" ] && UI_TYPE="ROG"

	echo_date "安装 ${UI_TYPE} 皮肤！"
	# 皮肤靠 Module_${module}.asp 里带 /* W3C xxxcss */ 标记的 4 行 CSS 区分，
	# 安装时删掉其余三行，只留一条生效。
	case "${UI_TYPE}" in
		ROG)
			sed -i '/asuscss/d; /tufcss/d; /tscss/d' /koolshare/webs/Module_${module}.asp >/dev/null 2>&1
			;;
		TUF)
			sed -i '/asuscss/d; /rogcss/d; /tscss/d' /koolshare/webs/Module_${module}.asp >/dev/null 2>&1
			;;
		TS)
			sed -i '/asuscss/d; /rogcss/d; /tufcss/d' /koolshare/webs/Module_${module}.asp >/dev/null 2>&1
			;;
		*)
			sed -i '/rogcss/d; /tufcss/d; /tscss/d' /koolshare/webs/Module_${module}.asp >/dev/null 2>&1
			;;
	esac
	if [ -z "${SC_SKIN}" ] || [ "${SC_SKIN}" != "${UI_TYPE}" ]; then
		nvram set sc_skin="${UI_TYPE}" 2>/dev/null
		nvram commit 2>/dev/null
	fi
}

# dbus_set_default <key> <value> —— 仅在没有值时写入，升级不覆盖用户配置
dbus_set_default() {
	if [ -z "$(dbus get $1)" ]; then
		dbus set $1="$2"
	fi
}

install_now() {
	local TITLE="WorkBuddy 网关"
	local DESCR="CodeBuddy 账号池转 OpenAI 兼容 API"
	local PLVER=$(cat ${DIR}/version)

	# ---- 安装前先停服务 ----
	if [ -f "/koolshare/scripts/${module}_config.sh" ]; then
		echo_date "安装前先关闭${TITLE}插件，以保证更新成功！"
		sh /koolshare/scripts/${module}_config.sh stop >/dev/null 2>&1
	fi

	# ---- 清理旧文件 ----
	rm -rf /koolshare/bin/wb2api >/dev/null 2>&1
	rm -rf /koolshare/bin/wb2api-ctl >/dev/null 2>&1
	rm -rf /koolshare/bin/wb2api-login >/dev/null 2>&1
	rm -rf /koolshare/bin/wb2api-signin >/dev/null 2>&1
	rm -rf /koolshare/bin/wb2api-credit >/dev/null 2>&1
	rm -rf /koolshare/res/icon-${module}.png >/dev/null 2>&1
	rm -rf /koolshare/scripts/${module}_*.sh >/dev/null 2>&1
	rm -rf /koolshare/scripts/uninstall_${module}.sh >/dev/null 2>&1
	rm -rf /koolshare/webs/Module_${module}.asp >/dev/null 2>&1
	find /koolshare/init.d -name "*${module}*" | xargs rm -rf >/dev/null 2>&1

	# ---- 落地文件 ----
	echo_date "安装插件相关文件..."
	cd /tmp
	cp -rf /tmp/${module}/bin/* /koolshare/bin/
	cp -rf /tmp/${module}/res/* /koolshare/res/
	cp -rf /tmp/${module}/scripts/* /koolshare/scripts/
	cp -rf /tmp/${module}/webs/* /koolshare/webs/
	cp -rf /tmp/${module}/uninstall.sh /koolshare/scripts/uninstall_${module}.sh

	# ---- 权限 ----
	chmod 0755 /koolshare/bin/wb2api >/dev/null 2>&1
	chmod 0755 /koolshare/bin/wb2api-ctl >/dev/null 2>&1
	chmod 0755 /koolshare/bin/wb2api-login >/dev/null 2>&1
	chmod 0755 /koolshare/bin/wb2api-signin >/dev/null 2>&1
	chmod 0755 /koolshare/bin/wb2api-credit >/dev/null 2>&1
	chmod 0755 /koolshare/scripts/${module}_*.sh >/dev/null 2>&1
	chmod 0755 /koolshare/scripts/uninstall_${module}.sh >/dev/null 2>&1

	# ---- 开机自启 ----
	if [ ! -L "/koolshare/init.d/S98${module}.sh" ]; then
		ln -sf /koolshare/scripts/${module}_config.sh /koolshare/init.d/S98${module}.sh
	fi

	# ---- 皮肤 ----
	set_skin

	# ---- 默认参数（只补空值，升级不覆盖）----
	echo_date "设置插件默认参数..."
	dbus set ${module}_version="${PLVER}"
	dbus set softcenter_module_${module}_version="${PLVER}"
	dbus set softcenter_module_${module}_install="1"
	dbus set softcenter_module_${module}_name="${module}"
	dbus set softcenter_module_${module}_title="${TITLE}"
	dbus set softcenter_module_${module}_description="${DESCR}"

	dbus_set_default ${module}_enable "0"
	dbus_set_default ${module}_auto_start "1"
	dbus_set_default ${module}_wan "0"
	dbus_set_default ${module}_firewall "1"
	dbus_set_default ${module}_watchdog "1"
	dbus_set_default ${module}_listen_port "17863"
	dbus_set_default ${module}_upstream_port "7863"
	dbus_set_default ${module}_data_dir "/koolshare/etc/${module}"
	dbus_set_default ${module}_audit_days "7"
	dbus_set_default ${module}_audit_max_mb "8"
	dbus_set_default ${module}_max_body_mb "8"
	dbus_set_default ${module}_soft_rate "600s"
	dbus_set_default ${module}_soft_rate_max "2h"
	dbus_set_default ${module}_checkin_hours "9,21"
	dbus_set_default ${module}_travel_hours "9,21"
	dbus_set_default ${module}_activity_hours "10"
	dbus_set_default ${module}_keepalive_hours "22"
	dbus_set_default ${module}_school_hours "12"
	dbus_set_default ${module}_cat_hours "1"
	dbus_set_default ${module}_checkin_enabled "1"
	dbus_set_default ${module}_travel_enabled "1"
	dbus_set_default ${module}_activity_enabled "1"
	dbus_set_default ${module}_keepalive_enabled "1"
	dbus_set_default ${module}_school_enabled "1"
	dbus_set_default ${module}_cat_enabled "1"
	dbus_set_default ${module}_global_enabled "1"
	dbus_set_default ${module}_timeout "120"
	dbus_set_default ${module}_client_name "WorkBuddy"
	dbus_set_default ${module}_sanitize "1"
	dbus_set_default ${module}_prompt_mode "passthrough"
	dbus_set_default ${module}_max_in_flight "3"
	dbus_set_default ${module}_breaker_threshold "3"
	dbus_set_default ${module}_breaker_cooldown "30m"
	dbus_set_default ${module}_breaker_cooldown_max "6h"
	dbus_set_default ${module}_idle_weight "0.5"
	dbus_set_default ${module}_idle_weight_max "5"
	dbus_set_default ${module}_expiring_soon "168h"
	dbus_set_default ${module}_sticky "1"
	dbus_set_default ${module}_sticky_ttl "30m"
	dbus_set_default ${module}_sticky_gc "5m"

	# ---- 数据目录与看门狗 ----
	mkdir -p "$(dbus get ${module}_data_dir)"
	if [ "$(dbus get ${module}_watchdog)" = "1" ]; then
		cru a ${module}_watchdog "*/5 * * * * /koolshare/scripts/${module}_config.sh watchdog"
	fi

	# ---- 恢复运行状态 ----
	if [ "$(dbus get ${module}_enable)" = "1" ]; then
		echo_date "安装完毕，重新启用${TITLE}插件！"
		sh /koolshare/scripts/${module}_config.sh start >/dev/null 2>&1
	fi

	echo_date "${TITLE}插件安装完毕！"
	exit_install
}

install() {
	get_model
	get_fw_type
	platform_test
	install_now
}

install
