#!/bin/bash
# 打印当前 Studio 在局域网内可用的访问地址
# 用法: bash share-link.sh

set -e

PORT="${PORT:-8080}"
LAN_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "")
HOSTNAME=$(scutil --get LocalHostName 2>/dev/null || hostname -s)

echo ""
echo "================================================================"
echo "  📡 質心 XHS Studio · 局域网访问地址"
echo "================================================================"
echo ""

# 检测服务是否在跑
if ! lsof -nP -i:$PORT -sTCP:LISTEN >/dev/null 2>&1; then
  echo "  ⚠️  Studio 没在跑! 先在另一个 terminal 启动:"
  echo "      cd webapp && source .venv/bin/activate && python app.py"
  echo ""
  exit 1
fi

if ! lsof -nP -i:18060 -sTCP:LISTEN >/dev/null 2>&1; then
  echo "  ⚠️  xhs-mcp 没在跑! 先启动:"
  echo "      cd xhs-mcp && ./xiaohongshu-mcp-darwin-arm64 -port :18060"
  echo ""
fi

echo "  本地访问 (你自己):"
echo "    http://localhost:$PORT/studio"
echo ""

if [ -n "$LAN_IP" ]; then
  echo "  📱 同事用 IP 访问 (推荐):"
  echo "    http://$LAN_IP:$PORT/studio"
  echo ""
fi

echo "  💻 同事用 hostname 访问 (Mac/iPhone 友好):"
echo "    http://$HOSTNAME.local:$PORT/studio"
echo ""

echo "================================================================"
echo "  ⚠️  共用提醒:"
echo "    1. 所有人发文都从「你」这个小红书账号出去"
echo '    2. 所有人都消耗「你」的 OpenRouter 余额 (~$0.17/篇)'
echo "    3. 别同时跑批量, 容易撞限流"
echo "================================================================"
echo ""
