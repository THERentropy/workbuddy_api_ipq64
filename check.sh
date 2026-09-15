#!/bin/sh
# ============================================================================
# check.sh —— 本地自检：脚本语法 + Go 静态检查 + 打包结构校验
# 需要：sh（busybox ash / dash 均可）、go 1.22+
# ============================================================================

set -e
DIR=$(cd "$(dirname "$0")"; pwd)
cd "${DIR}"

FAIL=0
note() { echo "==> $*"; }
fail() { echo "    [FAIL] $*"; FAIL=1; }

note "1/4 shell 语法检查（POSIX sh）"
for f in workbuddy/scripts-ipq64/*.sh workbuddy/install.sh workbuddy/uninstall.sh build_ipq64.sh; do
	if sh -n "$f" 2>/tmp/wb_check_err; then
		echo "    ok  $f"
	else
		fail "$f"
		cat /tmp/wb_check_err
	fi
done

note "2/4 Go 静态检查"
if command -v go >/dev/null 2>&1; then
	(cd guard && go vet ./...) || fail "go vet"
else
	echo "    跳过（未安装 go）"
fi

note "3/4 打包结构校验"
BIN_COUNT=$(find workbuddy/bin_64 -type f ! -name '.gitkeep' 2>/dev/null | wc -l | tr -d ' ')
if [ "${BIN_COUNT}" = "0" ]; then
	echo "    跳过打包（workbuddy/bin_64/ 下没有二进制，CI 会自动填入）"
else
	if command -v go >/dev/null 2>&1; then
		(cd guard && GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o ../workbuddy/bin_64/wb2api-ctl .)
	fi
	sh build_ipq64.sh >/dev/null
	echo "    安装包内容："
	tar -tzf workbuddy.tar.gz | sed 's/^/      /'
	for need in workbuddy/.valid workbuddy/install.sh workbuddy/uninstall.sh \
		workbuddy/webs/Module_workbuddy.asp workbuddy/res/icon-workbuddy.png \
		workbuddy/scripts/workbuddy_config.sh workbuddy/scripts/workbuddy_status.sh \
		workbuddy/scripts/workbuddy_account.sh workbuddy/scripts/workbuddy_key.sh \
		workbuddy/scripts/workbuddy_log.sh workbuddy/scripts/workbuddy_migrate.sh \
		workbuddy/scripts/workbuddy_env.sh; do
		if tar -tzf workbuddy.tar.gz | grep -qx "${need}"; then
			echo "    ok  ${need}"
		else
			fail "安装包缺少 ${need}"
		fi
	done
	if tar -tzf workbuddy.tar.gz | grep -q "bin_"; then
		fail "安装包内不应残留 bin_* 目录"
	fi
fi

note "4/4 .valid 内容"
if [ "$(cat workbuddy/.valid)" = "ipq64" ]; then
	echo "    ok  ipq64"
else
	fail ".valid 内容应为 ipq64"
fi

if [ "${FAIL}" = "1" ]; then
	echo "==> 自检未通过"
	exit 1
fi
echo "==> 自检通过"
