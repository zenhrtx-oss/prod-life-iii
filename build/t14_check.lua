-- Edit: publish readiness. PASS items are done; PENDING USER items need you (publish, API access, settings).
local RS, MS, DSS = game:GetService("ReplicatedStorage"), game:GetService("MarketplaceService"), game:GetService("DataStoreService")
local function freshRequire(mod) local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name; local ok, r = pcall(require, c); c:Destroy(); if not ok then error(r) end; return r end
local Config, DAW = freshRequire(RS.OK.Config), freshRequire(RS.OK.Modules.DAWConfig)
local lines, pending = {}, {}
-- every sound the experience plays must belong to Roblox's licensed library accounts
local ids = {}
for _, tr in ipairs(DAW.Tracks) do ids[tr.SoundId] = "DAW " .. tr.Name end
for _, k in ipairs(DAW.Kits or {}) do for track, sd in pairs(k.sounds or {}) do ids[sd.id] = "Kit " .. k.id .. " " .. track end end
for _, v in ipairs(DAW.Voices or {}) do ids[v.SoundId] = "Voice " .. v.id end
for kind, def in pairs(Config.SFX) do ids[def.id] = "SFX " .. kind end
local bad = {}
for sid, what in pairs(ids) do
  local num = tonumber(sid:match("%d+"))
  local ok, info = pcall(function() return MS:GetProductInfo(num, Enum.InfoType.Asset) end)
  local cid = ok and info and info.Creator and info.Creator.CreatorTargetId
  if not (cid and Config.LicensedCreators[cid]) then table.insert(bad, what .. " " .. sid .. " creator=" .. tostring(cid)) end
end
assert(#bad == 0, "sounds not from the licensed library: " .. table.concat(bad, "; "))
local n = 0; for _ in pairs(ids) do n += 1 end
table.insert(lines, "PASS " .. n .. " sounds, all from APMOfficial / ProSoundEffects")
-- no enabled scripts anywhere in ServerStorage (backups and snapshots must be inert)
local live = 0; for _, d in ipairs(game:GetService("ServerStorage"):GetDescendants()) do if d:IsA("BaseScript") and not d.Disabled then live += 1 end end
assert(live == 0, live .. " enabled scripts in ServerStorage")
table.insert(lines, "PASS no enabled scripts in ServerStorage")
-- player cap
local maxP = game:GetService("Players").MaxPlayers
if maxP > 0 and maxP <= 12 then table.insert(lines, "PASS MaxPlayers " .. maxP) else table.insert(pending, "MaxPlayers is " .. maxP .. " (set 10-12 in Game Settings > Places for one studio)") end
-- publish and saving
if game.PlaceId == 0 then table.insert(pending, "place not published (PlaceId 0): Save to Roblox, then Publish") else table.insert(lines, "PASS published, PlaceId " .. game.PlaceId) end
local okDS = game.PlaceId ~= 0 and pcall(function() return DSS:GetDataStore(Config.DataStoreName):GetAsync("_probe") end)
if okDS then table.insert(lines, "PASS DataStore reachable") else table.insert(pending, "DataStore not reachable: publish, then Game Settings > Security > Enable Studio Access to API Services") end
local content = Config.Content and Config.Content.ShowExplicitTitles
table.insert(pending, "titles decision: ShowExplicitTitles = " .. tostring(content) .. " (your call; set false to hide the masked titles)")
return "T14 OK (publish readiness)\n" .. table.concat(lines, "\n") .. "\nPENDING USER:\n- " .. table.concat(pending, "\n- ")
