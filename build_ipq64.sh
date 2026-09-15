#!/bin/sh
# ============================================================================
# build_ipq64.sh —— 打包 koolshare ipq64 软件中心离线安装包
#
# 产出（仓库根目录）：
#   workbuddy.tar.gz   离线安装包（软件中心「离线安装」直接使用）
#   version            插件版本号 + 安装包 md5
#   config.json.js     软件中心插件元数据
#
# 前置条件：workbuddy/bin_64/ 下需已放好 CI 交叉编译的 arm64 静态二进制
#   wb2api  wb2api-login  wb2api-signin  wb2api-credit  wb2api-ctl
# （见 .github/workflows/build-ipq64.yml）
# ============================================================================

set -e

DIR=$(cd "$(dirname "$0")"; pwd)
MODULE=workbuddy
PLATFORM=ipq64
ARCH=64

TITLE="WorkBuddy 网关"
DESCRIPTION="CodeBuddy 账号池转 OpenAI 兼容 API"
HOME_URL="Module_${MODULE}.asp"
TAGS="AI"
AUTHOR="ipq64"

VERSION=$(cat "${DIR}/${MODULE}/version")

echo "==> build ${MODULE} ${VERSION} for ${PLATFORM}"

# ---------------- 准备构建目录 ----------------
rm -rf "${DIR}/${MODULE}.tar.gz" "${DIR}/build"
mkdir -p "${DIR}/build"
cp -rf "${DIR}/${MODULE}" "${DIR}/build/"
cd "${DIR}/build/${MODULE}"

# 平台标识：软件中心靠 .valid 文件内容拒绝异平台离线包
echo "${PLATFORM}" > .valid

# 二进制 / 平台脚本落地为统一目录名
if [ ! -d "bin_${ARCH}" ]; then
	echo "ERROR: 缺少 bin_${ARCH}/，请先编译 arm64 静态二进制"
	exit 1
fi
cp -rf "bin_${ARCH}" bin
cp -rf "scripts-${PLATFORM}" scripts
rm -rf bin_* scripts-*
find . -name '.gitkeep' -delete

# 换行符统一为 LF（Windows 检出会带 CRLF，路由器 busybox 无法执行）
for f in $(find . -type f); do
	case "$f" in
		*.png) continue ;;
	esac
	tr -d '\r' < "$f" > "$f.tmp" && mv "$f.tmp" "$f"
done

chmod 0755 install.sh uninstall.sh
chmod 0755 scripts/*
chmod 0755 bin/*

# ---------------- 打包 ----------------
cd "${DIR}/build"
tar -zcf "${MODULE}.tar.gz" "${MODULE}"
mv "${DIR}/build/${MODULE}.tar.gz" "${DIR}/"

# ---------------- 元数据 ----------------
cd "${DIR}"
MD5=$(md5sum "${MODULE}.tar.gz" | awk '{print $1}')
DATE=$(date +%Y-%m-%d_%H:%M:%S)

cat > version <<EOF
${VERSION}
${MD5}
EOF

cat > config.json.js <<EOF
{
"version":"${VERSION}",
"md5":"${MD5}",
"home_url":"${HOME_URL}",
"title":"${TITLE}",
"description":"${DESCRIPTION}",
"tags":"${TAGS}",
"author":"${AUTHOR}",
"link":"",
"changelog":"",
"build_date":"${DATE}"
}
EOF

cat version
echo "==> build ok: ${MODULE}.tar.gz"
