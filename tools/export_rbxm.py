#!/usr/bin/env python3
"""Export the open place's content as .rbxm model files (one per service) plus lighting settings, as an offline backup.
Studio's MCP cannot save the place itself; SerializationService can serialize the children of each service.
usage: python3 -I tools/export_rbxm.py [outdir]"""
import base64, json, pathlib, subprocess, sys, time
ROOT = pathlib.Path(__file__).resolve().parent.parent
MCP = ROOT / "tools" / "mcp_call.py"
SERVICES = ["Workspace", "Lighting", "ReplicatedStorage", "ServerScriptService", "ServerStorage", "StarterGui", "StarterPack", "StarterPlayer", "SoundService", "Teams"]
CHUNK = 60000  # base64 chars per call (the MCP reply is truncated well above this)
LUA = r'''
local svcName, chunk, size = SVC, CHUNK_I, CHUNK_N
local SS = game:GetService("SerializationService")
local svc = game:GetService(svcName)
_G.__okExport = _G.__okExport or {}
local b64 = _G.__okExport[svcName]
if not b64 or chunk == 0 then
  local kids = {}
  for _, c in ipairs(svc:GetChildren()) do
    if not c:IsA("Camera") and not c:IsA("Terrain") and not c:IsA("Player") then
      local ok = pcall(function() SS:SerializeInstancesAsync({ c }) end)
      if ok then table.insert(kids, c) end
    end
  end
  if #kids == 0 then _G.__okExport[svcName] = ""; return "EMPTY" end
  local buf = SS:SerializeInstancesAsync(kids)
  local n = buffer.len(buf)
  local A = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  local out, i = table.create(math.ceil(n / 3)), 0
  while i < n do
    local b0 = buffer.readu8(buf, i)
    local b1 = i + 1 < n and buffer.readu8(buf, i + 1) or 0
    local b2 = i + 2 < n and buffer.readu8(buf, i + 2) or 0
    local v = b0 * 65536 + b1 * 256 + b2
    local c1, c2, c3, c4 = bit32.rshift(v, 18), bit32.band(bit32.rshift(v, 12), 63), bit32.band(bit32.rshift(v, 6), 63), bit32.band(v, 63)
    local s = A:sub(c1 + 1, c1 + 1) .. A:sub(c2 + 1, c2 + 1) .. (i + 1 < n and A:sub(c3 + 1, c3 + 1) or "=") .. (i + 2 < n and A:sub(c4 + 1, c4 + 1) or "=")
    table.insert(out, s)
    i += 3
  end
  b64 = table.concat(out)
  _G.__okExport[svcName] = b64
  local names = {}
  for _, c in ipairs(kids) do table.insert(names, c.Name) end
  _G.__okExport[svcName .. "#names"] = table.concat(names, ",")
end
if b64 == "" then return "EMPTY" end
local total = math.ceil(#b64 / size)
return "CHUNK " .. chunk .. "/" .. total .. " " .. (_G.__okExport[svcName .. "#names"] or "") .. "\n" .. b64:sub(chunk * size + 1, (chunk + 1) * size)
'''
LIGHT = r'''
local L = game:GetService("Lighting")
local t = {}
for _, p in ipairs({ "Ambient", "OutdoorAmbient", "Brightness", "ClockTime", "ExposureCompensation", "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "GlobalShadows", "ShadowSoftness", "FogEnd", "FogStart", "FogColor", "ColorShift_Top", "ColorShift_Bottom" }) do
  local ok, v = pcall(function() return L[p] end)
  if ok then t[p] = tostring(v) end
end
t.Technology = tostring(L.Technology)
return game:GetService("HttpService"):JSONEncode(t)
'''
def mcp_luau(code):
    tmp = ROOT / "tools" / "_export_tmp.lua"
    tmp.write_text(code)
    r = subprocess.run([sys.executable, "-I", str(MCP), "--luau", str(tmp)], capture_output=True, text=True, timeout=300)
    tmp.unlink()
    out = r.stdout
    lines = [l for l in out.splitlines() if not l.startswith("STUDIO_ID") and not l.startswith("studios=")]
    return "\n".join(lines)
def main():
    out = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "places" / ("export_" + time.strftime("%Y-%m-%d_%H%M"))
    out.mkdir(parents=True, exist_ok=True)
    manifest = {"exported": time.strftime("%Y-%m-%d %H:%M:%S"), "services": {}}
    for svc in SERVICES:
        parts, total, names, i = [], None, "", 0
        while True:
            code = LUA.replace("SVC", json.dumps(svc)).replace("CHUNK_I", str(i)).replace("CHUNK_N", str(CHUNK))
            res = mcp_luau(code)
            if "EMPTY" in res.splitlines()[0:1] or res.strip().endswith("EMPTY"):
                break
            head, _, body = res.partition("\n")
            if not head.startswith("CHUNK"):
                raise SystemExit(f"{svc}: unexpected reply: {res[:300]}")
            _, frac, *rest = head.split(" ")
            names = rest[0] if rest else ""
            k, total = map(int, frac.split("/"))
            body = body.strip()
            expect = CHUNK if k + 1 < total else None
            if expect is not None and len(body) != expect:
                raise SystemExit(f"{svc}: chunk {k} came back with {len(body)} chars, expected {expect}")
            parts.append(body)
            i += 1
            if i >= total: break
        if not parts:
            print(f"{svc}: nothing to export"); continue
        data = base64.b64decode("".join(parts))
        assert data[:8] == b"<roblox!", f"{svc}: not a binary model"
        (out / f"{svc}.rbxm").write_bytes(data)
        manifest["services"][svc] = {"bytes": len(data), "children": names.split(",") if names else []}
        print(f"{svc}: {len(data)} bytes in {total} chunk(s): {names}")
    (out / "Lighting_properties.json").write_text(mcp_luau(LIGHT).strip())
    (out / "manifest.json").write_text(json.dumps(manifest, indent=2))
    (out / "README.txt").write_text("Offline backup of the OK Studio place, exported through SerializationService (the Studio MCP cannot save places).\n"
        "Each <Service>.rbxm holds that service's children. To restore into an empty place: right-click the service in the\n"
        "Explorer > Insert from File, pick the matching .rbxm. Lighting_properties.json lists the Lighting settings to re-apply.\n")
    print("export done:", out)
main()
