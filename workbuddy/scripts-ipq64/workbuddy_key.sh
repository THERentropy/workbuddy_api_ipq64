#!/bin/sh
# ============================================================================
# workbuddy_key.sh —— 多密钥分发与全局 IP 策略
#   workbuddy_key.sh add   --name=手机 --days=30 --max-ips=3 --ip-allow=192.168.1.0/24 --models=glm-5.2 --quota=1000000
#   workbuddy_key.sh list
#   workbuddy_key.sh del   --id=kid-xxxx
#   workbuddy_key.sh enable|disable --id=kid-xxxx
#   workbuddy_key.sh policy show
#   workbuddy_key.sh policy set --ip-allow=... --ip-deny=...
# ============================================================================

source /koolshare/scripts/base.sh
source /koolshare/scripts/workbuddy_env.sh

case "$1" in
	policy)
		shift
		"${WB_CTL}" policy "$@" | wb_result workbuddy_policy.json
		;;
	*)
		"${WB_CTL}" key "$@" | wb_result workbuddy_key.json
		;;
esac
