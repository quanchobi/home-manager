#!/usr/bin/env bash
# Start FreeCAD (snap) inside a private niri-agent session and wait for the
# FreeCAD MCP addon's XML-RPC server on 127.0.0.1:9875.
# Idempotent: exits 0 immediately if the RPC server already answers.
set -euo pipefail

SESSION="${1:-freecad}"
PORT=9875

ping_rpc() {
  python3 - "$PORT" <<'EOF' 2>/dev/null
import sys, socket, xmlrpc.client
socket.setdefaulttimeout(3)
sys.exit(0 if xmlrpc.client.ServerProxy(f"http://127.0.0.1:{sys.argv[1]}").ping() else 1)
EOF
}

if ping_rpc; then
  echo "FreeCAD RPC already up on :$PORT"
  exit 0
fi

# Reuse a healthy session; replace a dead one.
state=$(niri-agent list | python3 -c '
import json, sys
s = [x for x in json.load(sys.stdin) if x["name"] == sys.argv[1]]
print("none" if not s else ("ok" if s[0]["alive"] and s[0]["bus_alive"] else "dead"))' "$SESSION")
if [ "$state" = dead ]; then niri-agent stop "$SESSION" >/dev/null; fi
if [ "$state" != ok ]; then niri-agent start "$SESSION" --size 1600x1000 >/dev/null; fi

# Snap FreeCAD needs the host bus: on the private bus snapd cannot create its
# systemd transient scope and FreeCAD exits immediately.
niri-agent run --host-bus "$SESSION" -- freecad >/dev/null

for _ in $(seq 90); do
  if ping_rpc; then
    echo "FreeCAD RPC up on :$PORT (niri-agent session '$SESSION')"
    exit 0
  fi
  sleep 1
done
echo "FreeCAD RPC did not come up within 90s; check auto_start_rpc in ~/snap/freecad/common/freecad_mcp_settings.json" >&2
exit 1
