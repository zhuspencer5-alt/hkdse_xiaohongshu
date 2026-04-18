#!/bin/bash
# 停止 webapp 和 xhs-mcp
set -e
cd "$(dirname "$0")"

stop_pid_file() {
  local f="$1"
  local label="$2"
  if [ -f "$f" ]; then
    local pid
    pid=$(cat "$f")
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" && echo "🛑 stopped $label (PID=$pid)"
    else
      echo "  $label PID=$pid 已不在了"
    fi
    rm -f "$f"
  else
    echo "  $label 没找到 PID 文件 ($f)"
  fi
}

stop_pid_file "webapp/.webapp.pid" "webapp"
stop_pid_file "xhs-mcp/.xhs-mcp.pid" "xhs-mcp"

# 兜底: 按端口杀
for port in 8080 18060; do
  pids=$(lsof -nP -i:$port -sTCP:LISTEN -t 2>/dev/null || true)
  if [ -n "$pids" ]; then
    echo "🛑 端口 $port 还在监听, 强制 kill: $pids"
    kill $pids 2>/dev/null || true
  fi
done

echo "✅ 全部已停止"
