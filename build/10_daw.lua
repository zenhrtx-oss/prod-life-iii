-- 10: beat maker STRUCTURE only: remotes and the Samples folder built from DAWConfig. Sources live in ../src (tools/sync.py).
-- (The pre-src version is kept as _legacy_10_daw_pre_src.lua.txt; do not run it.)
local function freshRequire(mod) local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name; local ok, res = pcall(require, c); c:Destroy(); if not ok then error(res) end; return res end
local RS = game:GetService("ReplicatedStorage")
local OK = RS.OK
local function ensure(parent, class, name) local i = parent:FindFirstChild(name); if not i or i.ClassName ~= class then if i then i:Destroy() end; i = Instance.new(class); i.Name = name; i.Parent = parent end; return i end
for _, n in ipairs({"DAW_Save", "DAW_Broadcast", "Session_Get", "Session_Pick", "Session_Deliver", "Gear_Get", "Gear_Buy", "Gear_Equip", "Fire_Send", "Card_Get", "Cypher_Join", "Cypher_Submit", "Cypher_Vote"}) do ensure(OK.Remotes, "RemoteFunction", n) end
ensure(OK.Remotes, "RemoteEvent", "DAW_Stop")
ensure(OK, "Folder", "NowPlaying")
local cfg = freshRequire(OK.Modules.DAWConfig)
local samples = OK:FindFirstChild("Samples"); if samples then samples:Destroy() end
samples = Instance.new("Folder"); samples.Name = "Samples"; samples.Parent = OK
for _, tr in ipairs(cfg.Tracks) do local s = Instance.new("Sound"); s.Name = tr.Name; s.SoundId = tr.SoundId; s.Volume = tr.Volume; s.Parent = samples end
-- kit folders: Samples.Kits.<kit>.<Track> (tracks a kit does not override fall back to the default sample)
local kits = Instance.new("Folder"); kits.Name = "Kits"; kits.Parent = samples
local nk = 0
for _, k in ipairs(cfg.Kits or {}) do
  if k.sounds then
    local f = Instance.new("Folder"); f.Name = k.id; f.Parent = kits
    for track, sd in pairs(k.sounds) do local s = Instance.new("Sound"); s.Name = track; s.SoundId = sd.id; s.Volume = sd.volume or 0.7; s.Parent = f; nk += 1 end
  end
end
-- keys voices: Samples.Voices.<voice id> (the piano roll's instruments)
local voices = Instance.new("Folder"); voices.Name = "Voices"; voices.Parent = samples
local nv = 0
for _, v in ipairs(cfg.Voices or {}) do local s = Instance.new("Sound"); s.Name = v.id; s.SoundId = v.SoundId; s.Volume = v.Volume or 0.8; s.Parent = voices; nv += 1 end
return "10 structure ok: samples=" .. (#samples:GetChildren() - 2) .. ", kit sounds=" .. nk .. ", voices=" .. nv
