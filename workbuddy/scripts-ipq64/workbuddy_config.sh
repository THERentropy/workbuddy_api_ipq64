#!/bin/sh
# ============================================================================
# workbuddy_config.sh —— 插件主控制脚本
#
#   workbuddy_config.sh start|stop|restart|web_submit|watchdog|iptables
#
# 开机自启由 /koolshare/init.d/S98workbuddy.sh 软链到本脚本调用 start。
# ============================================================================

source /koolshare/scripts/base.sh
source /koolshare/scripts/workbuddy_env.sh

MODULE=workbuddy
NAME="WorkBuddy 网关"

iptables_add() {
	port="$1"
	iptables -D INPUT -p tcp --dport "${port}" -j ACCEPT >/dev/null 2>&1
	iptables -D INPUT -p tcp --dport "${port}" -i br0 -j ACCEPT >/dev/null 2>&1
	if [ "$(dbus get workbuddy_wan)" = "1" ]; then
		iptables -I INPUT -p tcp --dport "${port}" -j ACCEPT >/dev/null 2>&1
	else
		iptables -I INPUT -p tcp --dport "${port}" -i br0 -j ACCEPT >/dev/null 2>&1
	fi
}

iptables_del() {
	port="$1"
	iptables -D INPUT -p tcp --dport "${port}" -j ACCEPT >/dev/null 2>&1
	iptables -D INPUT -p tcp --dport "${port}" -i br0 -j ACCEPT >/dev/null 2>&1
}

# render_config 把所有可视化设置渲染成上游 config.json。
# wb2api-ctl 会保留未知字段，升级上游后新增配置不会被抹掉。
#
# 说明（对齐 panel 版上游）：
#   - 夜猫子由旧键 workbuddy_cat_* 更名为 workbuddy_blackcat_*，旧键作为兜底读一次；
#   - 开学季任务已并入签到排程（上游自行处理），不再单独渲染 school_* 配置；
#   - 余额后台刷新/连败降权/国际版在途/出站指纹为 panel 版新增项。
render_config() {
	mkdir -p "${WB_DATA_DIR}"
	# 输出重定向到服务日志：/_api/ 的响应体只能是结尾的 {"result":<id>}，
	# 让 cfg render 的 JSON 漏到 stdout 会把响应体变成非法 JSON
	"${WB_CTL}" cfg render \
		>>"${WB_SERVICE_LOG}" 2>&1 \
		"--upstream-port=${WB_UPSTREAM_PORT}" \
		"--api-key=${WB_UPSTREAM_KEY}" \
		"--max-body-mb=$(dbus_default workbuddy_max_body_mb 8)" \
		"--soft-rate=$(dbus_default workbuddy_soft_rate 600s)" \
		"--soft-rate-max=$(dbus_default workbuddy_soft_rate_max 2h)" \
		"--checkin-hours=$(dbus_default workbuddy_checkin_hours 9,21)" \
		"--travel-hours=$(dbus_default workbuddy_travel_hours 9,21)" \
		"--activity-hours=$(dbus_default workbuddy_activity_hours 10)" \
		"--keepalive-hours=$(dbus_default workbuddy_keepalive_hours 22)" \
		"--blackcat-hours=$(dbus_default workbuddy_blackcat_hours "$(dbus_default workbuddy_cat_hours 23)")" \
		"--checkin-enabled=$(dbus_default workbuddy_checkin_enabled 1)" \
		"--travel-enabled=$(dbus_default workbuddy_travel_enabled 1)" \
		"--activity-enabled=$(dbus_default workbuddy_activity_enabled 1)" \
		"--keepalive-enabled=$(dbus_default workbuddy_keepalive_enabled 1)" \
		"--blackcat-enabled=$(dbus_default workbuddy_blackcat_enabled "$(dbus_default workbuddy_cat_enabled 1)")" \
		"--balance-refresh-enabled=$(dbus_default workbuddy_balance_refresh 1)" \
		"--balance-refresh-minutes=$(dbus_default workbuddy_balance_refresh_min 5)" \
		"--global-enabled=$(dbus_default workbuddy_global_enabled 1)" \
		"--global-chat-base=$(dbus get workbuddy_global_chat_base)" \
		"--global-billing-base=$(dbus get workbuddy_global_billing_base)" \
		"--timeout=$(dbus_default workbuddy_timeout 120)" \
		"--header-timeout=$(dbus_default workbuddy_header_timeout 120)" \
		"--idle-timeout=$(dbus_default workbuddy_idle_timeout 300)" \
		"--user-agent=$(dbus get workbuddy_user_agent)" \
		"--client-version=$(dbus get workbuddy_client_version)" \
		"--cli-version=$(dbus get workbuddy_cli_version)" \
		"--client-name=$(dbus_default workbuddy_client_name WorkBuddy)" \
		"--device-token=$(dbus get workbuddy_device_token)" \
		"--device-token-file=$(dbus get workbuddy_device_token_file)" \
		"--passthrough-ip=$(dbus_default workbuddy_passthrough_ip 0)" \
		"--sanitize=$(dbus_default workbuddy_sanitize 1)" \
		"--prompt-mode=$(dbus_default workbuddy_prompt_mode passthrough)" \
		"--prompt-file=$(dbus get workbuddy_prompt_file)" \
		"--max-in-flight=$(dbus_default workbuddy_max_in_flight 3)" \
		"--max-in-flight-global=$(dbus_default workbuddy_max_in_flight_global 2)" \
		"--breaker-threshold=$(dbus_default workbuddy_breaker_threshold 3)" \
		"--breaker-cooldown=$(dbus_default workbuddy_breaker_cooldown 30m)" \
		"--breaker-cooldown-max=$(dbus_default workbuddy_breaker_cooldown_max 6h)" \
		"--degrade-threshold=$(dbus_default workbuddy_degrade_threshold 5)" \
		"--degrade-cooldown=$(dbus_default workbuddy_degrade_cooldown 10m)" \
		"--degrade-cooldown-max=$(dbus_default workbuddy_degrade_cooldown_max 2h)" \
		"--idle-weight=$(dbus_default workbuddy_idle_weight 0.5)" \
		"--idle-weight-max=$(dbus_default workbuddy_idle_weight_max 5)" \
		"--expiring-soon=$(dbus_default workbuddy_expiring_soon 168h)" \
		"--sticky=$(dbus_default workbuddy_sticky 1)" \
		"--sticky-ttl=$(dbus_default workbuddy_sticky_ttl 30m)" \
		"--sticky-gc=$(dbus_default workbuddy_sticky_gc 5m)"
}

start() {
	if [ "$(dbus get workbuddy_enable)" != "1" ]; then
		wb_log "插件未启用，跳过启动"
		return 0
	fi

	render_config
	wb_log "启动 ${NAME}"

	# ---- 上游网关：只监听 127.0.0.1，外网一律由 wb2api-ctl 代理 ----
	up_pid=$(wb_pidof "${WB_UPSTREAM_BIN}")
	if [ -z "${up_pid}" ]; then
		cd "${WB_DATA_DIR}"
		nohup "${WB_UPSTREAM_BIN}" -config "${WB_DATA_DIR}/config.json" >> "${WB_SERVICE_LOG}" 2>&1 &
		sleep 2
	fi

	# ---- 自研代理层：多密钥鉴权 + 审计 ----
	ctl_pid=$(wb_pidof "${WB_CTL}")
	if [ -z "${ctl_pid}" ]; then
		nohup "${WB_CTL}" serve --listen="${WB_LISTEN}" >> "${WB_SERVICE_LOG}" 2>&1 &
		sleep 1
	fi

	if [ "$(dbus_default workbuddy_firewall 1)" = "1" ]; then
		iptables_add "${WB_LISTEN_PORT}"
	fi
	wb_log "启动完成 上游=127.0.0.1:${WB_UPSTREAM_PORT} 对外=${WB_LISTEN}"
	return 0
}

stop() {
	wb_log "停止 ${NAME}"
	for p in $(pidof wb2api-ctl 2>/dev/null); do kill "${p}" >/dev/null 2>&1; done
	for p in $(pidof wb2api 2>/dev/null); do kill "${p}" >/dev/null 2>&1; done
	sleep 1
	for p in $(pidof wb2api-ctl 2>/dev/null); do kill -9 "${p}" >/dev/null 2>&1; done
	for p in $(pidof wb2api 2>/dev/null); do kill -9 "${p}" >/dev/null 2>&1; done
	iptables_del "${WB_LISTEN_PORT}"
	return 0
}

restart() {
	stop
	sleep 1
	start
}

# watchdog 由 cru 每 5 分钟调用，进程掉了自动拉起
watchdog() {
	if [ "$(dbus get workbuddy_enable)" != "1" ]; then
		return 0
	fi
	if [ "$(dbus_default workbuddy_watchdog 1)" != "1" ]; then
		return 0
	fi
	if [ -z "$(wb_pidof "${WB_UPSTREAM_BIN}")" ] || [ -z "$(wb_pidof "${WB_CTL}")" ]; then
		wb_log "watchdog 检测到服务已退出，尝试拉起"
		start
	fi
}

# web_submit 软件中心保存设置后调用：dbus 字段已由软件中心写好
web_submit() {
	render_config
	if [ "$(dbus get workbuddy_enable)" = "1" ]; then
		restart
	else
		stop
	fi
	if [ "$(dbus_default workbuddy_watchdog 1)" = "1" ]; then
		cru a workbuddy_watchdog "*/5 * * * * /koolshare/scripts/workbuddy_config.sh watchdog" >/dev/null 2>&1
	else
		cru d workbuddy_watchdog >/dev/null 2>&1
	fi
	echo "{\"ok\":true}" | wb_out workbuddy_action.json
}

case "$1" in
	start)
		start
		;;
	stop)
		stop
		;;
	restart)
		restart
		;;
	watchdog)
		watchdog
		;;
	web_submit)
		web_submit
		;;
	iptables)
		iptables_add "${WB_LISTEN_PORT}"
		;;
	*)
		echo "usage: $0 {start|stop|restart|watchdog|web_submit|iptables}"
		exit 1
		;;
esac

wb_respond
