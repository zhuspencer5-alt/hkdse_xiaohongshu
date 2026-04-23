#!/bin/bash
# 質心 XHS Studio · 一键启动脚本
# 用法 (在 repo 根目录):
#     bash start.sh
#
# 启动 xhs-mcp + webapp, 后台跑, 日志写到各自目录
# 停止: bash stop.sh

set -e
cd "$(dirname "$0")"
ROOT="$(pwd)"

# 检测平台
OS=$(uname -s)
ARCH=$(uname -m)
case "$OS-$ARCH" in
  Darwin-arm64)  PLATFORM="darwin-arm64" ;;
  Darwin-x86_64) PLATFORM="darwin-amd64" ;;
  Linux-x86_64)  PLATFORM="linux-amd64"  ;;
  Linux-aarch64) PLATFORM="linux-arm64"  ;;
  *) echo "❌ 不支持的平台: $OS-$ARCH"; exit 1 ;;
esac

MCP_BIN="xhs-mcp/xiaohongshu-mcp-$PLATFORM"
LOGIN_BIN="xhs-mcp/xiaohongshu-login-$PLATFORM"
COOKIES="xhs-mcp/cookies.json"

# 检查二进制
if [ ! -x "$MCP_BIN" ]; then
  echo "❌ 找不到 $MCP_BIN, 先跑 bash install.sh"; exit 1
fi
if [ ! -f "webapp/config/app_config.json" ]; then
  echo "❌ 找不到 webapp/config/app_config.json, 先跑 bash install.sh"; exit 1
fi
# 检查 cookies
if [ ! -f "$COOKIES" ]; then
  echo "⚠️  $COOKIES 不存在, 你还没扫码登录小红书"
  echo "   先跑: cd xhs-mcp && ./xiaohongshu-login-$PLATFORM"
  echo "   (扫完再跑本脚本)"
  exit 1
fi

# 轮询某个端口直到 LISTEN, 或超时. 比固定 sleep 更鲁棒
# (首次启动 webapp 时 uvicorn 会触发 `npm exec` 装 jina-mcp-tools, 可能 15-30s).
# 用法: wait_for_listen <port> <timeout_sec> <name>
wait_for_listen() {
  local port="$1" timeout="$2" name="$3"
  local i=0
  while [ "$i" -lt "$timeout" ]; do
    if lsof -nP -i:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
    i=$((i + 1))
    # 每 5 秒打一次心跳, 让用户知道还在等 (不刷屏)
    if [ $((i % 5)) -eq 0 ]; then
      echo "   ⏳ 仍在等 $name 起来 ... ($i/${timeout}s)"
    fi
  done
  return 1
}

# 启动 xhs-mcp
if lsof -nP -i:18060 -sTCP:LISTEN >/dev/null 2>&1; then
  echo "🟢 xhs-mcp 已在 :18060 跑着, 跳过"
else
  echo "🚀 启动 xhs-mcp ..."
  cd xhs-mcp
  nohup "./xiaohongshu-mcp-$PLATFORM" -port :18060 > xhs-mcp.log 2>&1 &
  echo $! > .xhs-mcp.pid
  cd "$ROOT"
  if wait_for_listen 18060 15 xhs-mcp; then
    echo "   ✅ xhs-mcp 已起 (PID=$(cat xhs-mcp/.xhs-mcp.pid), log=xhs-mcp/xhs-mcp.log)"
  else
    echo "   ❌ xhs-mcp 15s 内未监听 :18060, 看日志: xhs-mcp/xhs-mcp.log"
    exit 1
  fi
fi

# 启动 webapp
if lsof -nP -i:8080 -sTCP:LISTEN >/dev/null 2>&1; then
  echo "🟢 webapp 已在 :8080 跑着, 跳过"
else
  echo "🚀 启动 webapp ..."
  cd webapp
  # shellcheck disable=SC1091
  source .venv/bin/activate
  nohup python app.py > app.log 2>&1 &
  echo $! > .webapp.pid
  cd "$ROOT"
  # 60s 给 npm 首次装 jina-mcp-tools / tavily-remote 留充裕时间
  if wait_for_listen 8080 60 webapp; then
    echo "   ✅ webapp 已起 (PID=$(cat webapp/.webapp.pid), log=webapp/app.log)"
  else
    echo "   ❌ webapp 60s 内未监听 :8080, 看日志: webapp/app.log"
    exit 1
  fi
fi

echo ""
echo "================================================================"
echo "  🎉 全部启动完成!"
echo "================================================================"
echo ""
echo "  本地访问:    http://localhost:8080/studio"

LAN_IP=$(ipconfig getifaddr en0 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}' || echo "")
if [ -n "$LAN_IP" ]; then
  echo "  局域网访问:  http://$LAN_IP:8080/studio  (同 wifi 同事可访问)"
fi

echo ""
echo "  停止:        bash stop.sh"
echo "  实时日志:    tail -f webapp/app.log xhs-mcp/xhs-mcp.log"
echo ""

# 自动开浏览器 (macOS 才有 open)
if command -v open >/dev/null 2>&1; then
  sleep 1
  open "http://localhost:8080/studio"
fi
