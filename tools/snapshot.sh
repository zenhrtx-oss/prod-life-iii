#!/bin/sh
# Clone Workspace.OKStudio (+ a disabled copy of the runtime) into ServerStorage.OK_Versions. Usage: tools/snapshot.sh NAME
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; N="${1:?name}"
sed "s/SNAPSHOT_NAME/$N/" "$ROOT/build/snapshot_version.lua" > "$ROOT/tools/_snap.lua" && python3 -I "$ROOT/tools/mcp_call.py" --luau "$ROOT/tools/_snap.lua" 2>/dev/null; rm -f "$ROOT/tools/_snap.lua"
