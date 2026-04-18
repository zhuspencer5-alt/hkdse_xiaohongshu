#!/bin/bash
# 扫码登录小红书 (一次性)
# 用法: bash login.sh
set -e
cd "$(dirname "$0")"

OS=$(uname -s); ARCH=$(uname -m)
case "$OS-$ARCH" in
  Darwin-arm64)  PLATFORM="darwin-arm64" ;;
  Darwin-x86_64) PLATFORM="darwin-amd64" ;;
  Linux-x86_64)  PLATFORM="linux-amd64"  ;;
  Linux-aarch64) PLATFORM="linux-arm64"  ;;
  *) echo "❌ 不支持的平台: $OS-$ARCH"; exit 1 ;;
esac

LOGIN_BIN="xhs-mcp/xiaohongshu-login-$PLATFORM"
if [ ! -x "$LOGIN_BIN" ]; then
  echo "❌ 找不到 $LOGIN_BIN, 先跑 bash install.sh"
  exit 1
fi

echo ""
echo "================================================================"
echo "  📱 扫码登录小红书"
echo "================================================================"
echo ""
echo "  即将弹出 Chromium 窗口显示二维码,"
echo "  请用手机小红书 App 扫码 (设置 → 我 → 扫一扫)"
echo "  看到 '登录成功' 即可关闭窗口"
echo ""

# 如果有旧 cookies 先停掉跑着的 mcp 实例 (不然占用浏览器实例)
if [ -f "xhs-mcp/.xhs-mcp.pid" ]; then
  PID=$(cat "xhs-mcp/.xhs-mcp.pid")
  if kill -0 "$PID" 2>/dev/null; then
    echo "⏸  先停 xhs-mcp 释放浏览器 ..."
    kill "$PID" 2>/dev/null || true
    sleep 1
  fi
fi

cd xhs-mcp
rm -f cookies.json
"./xiaohongshu-login-$PLATFORM"

if [ -f cookies.json ]; then
  echo ""
  echo "✅ 登录成功! cookies 已保存到 xhs-mcp/cookies.json"
  echo "   下一步: bash start.sh"
else
  echo ""
  echo "⚠️  没看到 cookies.json, 登录可能失败, 重试一次"
  exit 1
fi
