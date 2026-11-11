-- Edit: drum kits: every kit has its gear item, the sample folders match the config, the 808 stays shared.
local RS = game:GetService("ReplicatedStorage")
local function freshRequire(mod) local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name; local ok, r = pcall(require, c); c:Destroy(); if not ok then error(r) end; return r end
local Cfg = freshRequire(RS.OK.Modules.DAWConfig)
local Config = freshRequire(RS.OK.Config)
local gear = {}; for _, it in ipairs(Config.Gear) do gear[it.id] = it end
local kitsFolder = RS.OK.Samples:FindFirstChild("Kits"); assert(kitsFolder, "Samples.Kits missing (run build/10_daw.lua)")
local n = 0
for _, k in ipairs(Cfg.Kits) do
  if k.sounds then
    local g = gear[k.gear]; assert(g and g.kind == "kit" and g.kit == k.id and g.price > 0, "kit " .. k.id .. " has no gear item")
    assert(k.sounds["808"] == nil, "kits must not replace the 808")
    local f = kitsFolder:FindFirstChild(k.id); assert(f, "no sample folder for " .. k.id)
    for track, sd in pairs(k.sounds) do
      local s = f:FindFirstChild(track); assert(s and s:IsA("Sound") and s.SoundId == sd.id, "sample " .. k.id .. "/" .. track .. " wrong")
      n += 1
    end
  end
end
assert(Cfg.KitById("studio") and Cfg.KitById("tape") and not Cfg.KitById("nope"), "KitById")
assert(Config.Gear[#Config.Gear].id == "plate_legend", "the top-tier item must stay last")
return "T27 OK: " .. (#Cfg.Kits - 1) .. " kits, " .. n .. " kit sounds in Samples.Kits matching the config, each sold at the rack; the 808 is shared"
