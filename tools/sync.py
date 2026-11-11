#!/usr/bin/env python3
"""Sync src/ into the open Roblox Studio place through the Studio MCP (Rojo-like, one direction).

  python3 tools/sync.py            # sync every changed file
  python3 tools/sync.py --dry      # report what would change, write nothing
  python3 tools/sync.py --force    # overwrite scripts edited by hand in Studio (drift)
  python3 tools/sync.py PATTERN    # only files whose path contains PATTERN

File naming: X.lua -> ModuleScript, X.server.lua -> Script, X.client.lua -> LocalScript.
Folder path under src/ = path under the service (StarterPlayer/StarterPlayerScripts/... for client scripts).
Drift: src/.sync_manifest.json stores the checksum last written for each path. If Studio's current
Source matches neither that checksum nor the new file, the script was edited in Studio: it is skipped
(reported DRIFT) unless --force.
"""
import json, pathlib, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "src"
MANIFEST = SRC / ".sync_manifest.json"
MCP = pathlib.Path(__file__).resolve().parent / "mcp_call.py"
CHUNK = 24000

def checksum(s: str) -> int:
    h = 0
    for b in s.encode("utf-8"):
        h = (h * 31 + b) % 2147483647
    return h

def classify(p: pathlib.Path):
    n = p.name
    if n.endswith(".server.lua"): return "Script", n[:-11]
    if n.endswith(".client.lua"): return "LocalScript", n[:-11]
    return "ModuleScript", n[:-4]

def long_bracket(s: str) -> str:
    n = 1
    while ("]" + "=" * n + "]") in s: n += 1
    eq = "=" * n
    return "[" + eq + "[\n" + s + "]" + eq + "]"

def lua_str(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'

LUA_HEAD = r'''
local function sum(s) local h = 0; for i = 1, #s do h = (h * 31 + string.byte(s, i)) % 2147483647 end; return h end
local function svc(first, second)
  local s = game:GetService(first)
  if second then s = s:FindFirstChild(second) or error("missing " .. first .. "." .. second) end
  return s
end
local out = {}
for _, f in ipairs(FILES) do
  local segs = f.segs
  local node, start
  if segs[1] == "StarterPlayer" then node = svc("StarterPlayer", "StarterPlayerScripts"); start = 3 else node = svc(segs[1]); start = 2 end
  for i = start, #segs - 1 do
    local c = node:FindFirstChild(segs[i])
    if not c then c = Instance.new("Folder"); c.Name = segs[i]; c.Parent = node end
    node = c
  end
  local name = segs[#segs]
  local inst = node:FindFirstChild(name)
  local status
  if inst and inst.ClassName ~= f.class then inst:Destroy(); inst = nil; status = "recreated" end
  if inst then
    local cur = sum(inst.Source)
    if cur == f.sum then status = "unchanged"
    elseif f.expect and cur ~= f.expect and not FORCE then status = "DRIFT studio=" .. cur .. " manifest=" .. tostring(f.expect)
    elseif not DRY then inst.Source = f.src; status = "updated" else status = "would-update" end
  else
    if DRY then status = "would-create" else
      inst = Instance.new(f.class); inst.Name = name; inst.Source = f.src; inst.Parent = node; status = status or "created"
    end
  end
  if inst and inst:IsA("BaseScript") and not DRY and status ~= "unchanged" and not status:find("DRIFT") then inst.Disabled = false end
  table.insert(out, f.path .. "\t" .. status)
end
return table.concat(out, "\n")
'''

def run_lua(code: str) -> str:
    tmp = ROOT / "tools" / "_sync_chunk.lua"
    tmp.write_text(code)
    r = subprocess.run([sys.executable, "-I", str(MCP), "--luau", str(tmp)], capture_output=True, text=True, timeout=300)
    tmp.unlink(missing_ok=True)
    return r.stdout.strip()

def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dry, force = "--dry" in sys.argv, "--force" in sys.argv
    guard = subprocess.run([sys.executable, "-I", str(MCP), "--luau", str(ROOT / "tools" / "guard.lua")], capture_output=True, text=True, timeout=120).stdout.strip()
    if not guard.startswith("GUARD OK"):
        print("REFUSING TO SYNC:", guard or "no response from Studio"); sys.exit(2)
    manifest = json.loads(MANIFEST.read_text()) if MANIFEST.exists() else {}
    files = []
    for p in sorted(SRC.rglob("*.lua")):
        rel = p.relative_to(SRC)
        cls, name = classify(p)
        path = "/".join(list(rel.parent.parts) + [name])
        if args and not any(a in path for a in args): continue
        src = p.read_text()
        files.append({"path": path, "class": cls, "src": src, "sum": checksum(src), "expect": manifest.get(path)})
    chunks, cur, size = [], [], 0
    for f in files:
        if cur and size + len(f["src"]) > CHUNK: chunks.append(cur); cur, size = [], 0
        cur.append(f); size += len(f["src"])
    if cur: chunks.append(cur)
    results = []
    for ch in chunks:
        entries = []
        for f in ch:
            segs = "{" + ", ".join(lua_str(s) for s in f["path"].split("/")) + "}"
            exp = str(f["expect"]) if f["expect"] is not None else "nil"
            entries.append("{path=%s, segs=%s, class=%s, sum=%d, expect=%s, src=%s}" % (lua_str(f["path"]), segs, lua_str(f["class"]), f["sum"], exp, long_bracket(f["src"])))
        code = "local DRY = %s\nlocal FORCE = %s\nlocal FILES = {\n%s\n}\n%s" % ("true" if dry else "false", "true" if force else "false", ",\n".join(entries), LUA_HEAD)
        out = run_lua(code)
        if "\t" not in out:
            print("SYNC ERROR:", out[:600]); sys.exit(1)
        results += out.splitlines()
    bysum = {f["path"]: f["sum"] for f in files}
    drift = 0
    for line in results:
        path, status = line.split("\t", 1)
        if status in ("unchanged", "updated", "created", "recreated") and not dry: manifest[path] = bysum[path]
        if status.startswith("DRIFT"): drift += 1
        if status != "unchanged" or "-v" in sys.argv: print(f"{status:<14} {path}")
    if not dry: MANIFEST.write_text(json.dumps(manifest, indent=1, sort_keys=True))
    print(f"sync: {len(results)} files, {sum(1 for l in results if l.endswith('unchanged'))} unchanged, {drift} drift" + (" (dry run)" if dry else ""))
    sys.exit(1 if drift else 0)

if __name__ == "__main__":
    main()
