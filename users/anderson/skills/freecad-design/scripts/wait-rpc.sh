#!/usr/bin/env bash
# Wait for the FreeCAD MCP addon's XML-RPC server on 127.0.0.1:9875, once FreeCAD
# was launched in the niri-computer-use background desktop. Exits 0 as soon as it
# answers, 1 after 90 s.
set -euo pipefail

PORT=9875

ping_rpc() {
  python3 - "$PORT" <<'EOF' 2>/dev/null
import sys, socket, xmlrpc.client
socket.setdefaulttimeout(3)
sys.exit(0 if xmlrpc.client.ServerProxy(f"http://127.0.0.1:{sys.argv[1]}").ping() else 1)
EOF
}

for _ in $(seq 90); do
  if ping_rpc; then
    echo "FreeCAD RPC up on :$PORT"
    exit 0
  fi
  sleep 1
done
echo "FreeCAD RPC did not come up within 90s; check auto_start_rpc in ~/snap/freecad/common/freecad_mcp_settings.json" >&2
exit 1
