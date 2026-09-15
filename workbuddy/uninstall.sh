#!/bin/sh
# ============================================================================
# uninstall.sh —— workbuddy 插件卸载脚本
#   默认保留数据目录（凭证 / 密钥 / 审计日志）；
#   如需连同数据一起删除：sh uninstall.sh --purge
# ============================================================================

source /koolshare/scripts/base.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'

module=workbuddy
PURGE=0
if [ "$1" = "--purge" ]; then
	PURGE=1
fi

DATA_DIR=$(dbus get ${module}_data_dir)
[ -z "${DATA_DIR}" ] && DATA_DIR="/koolshare/etc/${module}"
LISTEN_PORT=$(dbus get ${module}_listen_port)
[ -z "${LISTEN_PORT}" ] && LISTEN_PORT="17863"

echo_date "卸载 WorkBuddy 网关插件..."

# ---- 停服务 ----
if [ -f "/koolshare/scripts/${module}_config.sh" ]; then
	sh /koolshare/scripts/${module}_config.sh stop >/dev/null 2>&1
fi
for p in $(pidof wb2api-ctl 2>/dev/null); do kill -9 "${p}" >/dev/null 2>&1; done
for p in $(pidof wb2api 2>/dev/null); do kill -9 "${p}" >/dev/null 2>&1; done

# ---- 防火墙与定时任务 ----
iptables -D INPUT -p tcp --dport "${LISTEN_PORT}" -j ACCEPT >/dev/null 2>&1
iptables -D INPUT -p tcp --dport "${LISTEN_PORT}" -i br0 -j ACCEPT >/dev/null 2>&1
cru d ${module}_watchdog >/dev/null 2>&1

# ---- 删除文件（用通配符，避免以后新增脚本忘记加进列表）----
rm -rf /koolshare/bin/wb2api* >/dev/null 2>&1
rm -rf /tmp/wb-bin >/dev/null 2>&1
rm -rf /koolshare/res/icon-${module}.png >/dev/null 2>&1
rm -rf /koolshare/scripts/${module}_* >/dev/null 2>&1
rm -rf /koolshare/scripts/uninstall_${module}.sh >/dev/null 2>&1
rm -rf /koolshare/webs/Module_${module}.asp >/dev/null 2>&1
find /koolshare/init.d -name "*${module}*" | xargs rm -rf >/dev/null 2>&1
# 结果文件在两处：/tmp/upload/（httpd 的 /_temp/）与 /tmp/（兜底副本）
rm -rf /tmp/${module}_* /tmp/${module}.log >/dev/null 2>&1
rm -rf /tmp/upload/${module}_* >/dev/null 2>&1

# ---- 清理 dbus ----
for key in $(dbus list ${module} | cut -d= -f1); do
	dbus remove ${key} >/dev/null 2>&1
done
dbus remove softcenter_module_${module}_version >/dev/null 2>&1
dbus remove softcenter_module_${module}_install >/dev/null 2>&1
dbus remove softcenter_module_${module}_name >/dev/null 2>&1
dbus remove softcenter_module_${module}_title >/dev/null 2>&1
dbus remove softcenter_module_${module}_description >/dev/null 2>&1

# ---- 数据目录 ----
if [ "${PURGE}" = "1" ]; then
	echo_date "已删除数据目录：${DATA_DIR}"
	rm -rf "${DATA_DIR}" >/dev/null 2>&1
else
	echo_date "已保留数据目录：${DATA_DIR}（如需彻底删除请手动执行 rm -rf）"
fi

echo_date "WorkBuddy 网关插件卸载完成！"
