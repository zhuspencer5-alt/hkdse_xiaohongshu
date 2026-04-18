#!/bin/bash
# 質心 XHS Studio · 一键安装脚本
# 用法 (在 repo 根目录):
#     bash install.sh
#
# 自动:
#   1. 检测平台 (mac arm64 / mac intel / linux x64 / linux arm64)
#   2. 下载 xhs-mcp 二进制到 xhs-mcp/
#   3. 创建 webapp/.venv 装 Python 依赖
#   4. 复制 app_config.example.json -> app_config.json (如不存在)

set -e

cd "$(dirname "$0")"
ROOT="$(pwd)"

echo ""
echo "================================================================"
echo "  📦 質心 XHS Studio · 一键安装"
echo "================================================================"
echo ""

# ---------- 0. 依赖检查 ----------
need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "❌ 缺少 $1, 请先装: $2"
    exit 1
  fi
}
need_cmd python3 "https://www.python.org/downloads/  (建议 3.11+)"
need_cmd curl "macOS/Linux 自带, 一般不用装"
need_cmd tar "macOS/Linux 自带"

# ---------- 1. 检测平台 ----------
OS=$(uname -s)
ARCH=$(uname -m)
case "$OS-$ARCH" in
  Darwin-arm64)  PLATFORM="darwin-arm64" ;;
  Darwin-x86_64) PLATFORM="darwin-amd64" ;;
  Linux-x86_64)  PLATFORM="linux-amd64"  ;;
  Linux-aarch64) PLATFORM="linux-arm64"  ;;
  *) echo "❌ 不支持的平台: $OS-$ARCH"; exit 1 ;;
esac
echo "🔍 平台: $PLATFORM"

# ---------- 2. 下载 xhs-mcp 二进制 ----------
mkdir -p xhs-mcp
cd xhs-mcp
if [ ! -x "xiaohongshu-mcp-$PLATFORM" ] || [ ! -x "xiaohongshu-login-$PLATFORM" ]; then
  echo ""
  echo "📥 下载 xhs-mcp 二进制 ..."
  ASSET="xiaohongshu-mcp-$PLATFORM.tar.gz"
  URL="https://github.com/xpzouying/xiaohongshu-mcp/releases/latest/download/$ASSET"
  echo "   $URL"
  curl -fL --progress-bar -o "$ASSET" "$URL"
  echo "📦 解压 ..."
  tar xzf "$ASSET"
  rm "$ASSET"
  chmod +x "xiaohongshu-mcp-$PLATFORM" "xiaohongshu-login-$PLATFORM" 2>/dev/null || true
  echo "✅ xhs-mcp 二进制就绪"
else
  echo "✅ xhs-mcp 二进制已存在, 跳过下载"
fi
cd "$ROOT"

# ---------- 3. Python venv ----------
echo ""
echo "🐍 设置 Python 环境 ..."
cd webapp
if [ ! -d ".venv" ]; then
  python3 -m venv .venv
  echo "  ✅ 创建 .venv"
fi
# shellcheck disable=SC1091
source .venv/bin/activate
pip install --quiet --upgrade pip
echo "  📦 装依赖 (requirements.txt) ..."
pip install --quiet -r requirements.txt
echo "  ✅ Python 依赖就绪"
cd "$ROOT"

# ---------- 4. 配置文件 ----------
echo ""
CONFIG_FILE="webapp/config/app_config.json"
EXAMPLE_FILE="webapp/config/app_config.example.json"
if [ ! -f "$CONFIG_FILE" ]; then
  cp "$EXAMPLE_FILE" "$CONFIG_FILE"
  echo "📝 已创建 $CONFIG_FILE"
  echo "   ⚠️  请打开它把 sk-or-v1-YOUR... 替换成自己的 OpenRouter Key"
  echo "   👉 注册地址: https://openrouter.ai (充 \$10 够跑 50 篇)"
else
  echo "✅ $CONFIG_FILE 已存在, 跳过 (没动你的 key)"
fi

# ---------- 5. 完成 ----------
echo ""
echo "================================================================"
echo "  ✅ 安装完成!"
echo "================================================================"
echo ""
echo "下一步:"
echo ""
echo "  1) 编辑 $CONFIG_FILE 填上你的 OpenRouter Key"
echo ""
echo "  2) 扫码登录小红书 (一次性):"
echo "       cd xhs-mcp && ./xiaohongshu-login-$PLATFORM"
echo "       (弹 Chromium 显示二维码 → 用手机小红书 App 扫码)"
echo ""
echo "  3) 启动:"
echo "       bash start.sh"
echo "     或两个 terminal 手动跑:"
echo "       cd xhs-mcp && ./xiaohongshu-mcp-$PLATFORM"
echo "       cd webapp && source .venv/bin/activate && python app.py"
echo ""
echo "  4) 浏览器开:  http://localhost:8080/studio"
echo ""
