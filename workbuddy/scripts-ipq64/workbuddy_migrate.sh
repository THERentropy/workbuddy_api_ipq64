#!/bin/sh
# ============================================================================
# workbuddy_migrate.sh —— 数据目录迁移
#   workbuddy_migrate.sh /tmp/mnt/sda1/workbuddy [--delete-old]
# 迁移成功后写回 dbus 并重启服务。
# ============================================================================

source /koolshare/scripts/base.sh
source /koolshare/scripts/workbuddy_env.sh

TARGET="$1"
if [ -z "${TARGET}" ]; then
	echo '{"ok":false,"err":"缺少目标目录"}' | wb_out workbuddy_migrate.json
	exit 1
fi

"${WB_CTL}" migrate "$@" | wb_out workbuddy_migrate.json

if grep -q '"ok":true' "${WB_TMP_DIR}/workbuddy_migrate.json" 2>/dev/null; then
	dbus set workbuddy_data_dir="${TARGET}"
	wb_log "数据目录已迁移到 ${TARGET}"
	/koolshare/scripts/workbuddy_config.sh restart
else
	wb_log "数据目录迁移失败：${TARGET}"
fi
