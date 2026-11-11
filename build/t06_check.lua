local function freshRequire(mod) -- edit-mode require caches modules across runs; load a clone so edits take effect
  local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name
  local ok, res = pcall(require, c); c:Destroy(); if not ok then error(res) end; return res
end
local RS = game:GetService("ReplicatedStorage")
local ok = RS.OK
-- fresh clones: a cached require would hide a module broken by a later edit
for _, path in ipairs({"Config", "Modules.Interactions", "Modules.UITheme", "Modules.PanelUI", "Modules.HUD", "Modules.TourUI", "Modules.RequestUI", "Modules.BoothArtist", "Modules.BriefCheck", "Modules.DailyRequests", "Modules.FireButton", "Modules.Nameplate",
  "Data.Credits", "Data.Artists", "Systems.README", "Systems.DAW", "Systems.Gear", "Systems.Contracts", "Systems.Stations", "Systems.Tour", "Systems.Tycoon", "Systems.Profiles", "Systems.BeatBattles", "Systems.Flips", "Systems.Funnel", "Systems.Dailies", "Systems.Reactions", "Systems.Collab", "Systems.Networking", "Modules.LifeRules", "Systems.Life"}) do
  local node = ok; for seg in path:gmatch("[^%.]+") do node = node[seg] end
  local good, err = pcall(freshRequire, node); assert(good, path .. " failed: " .. tostring(err))
end
for _, n in ipairs({"DataService", "LightingService", "InteractionService", "MonitorService", "SystemLoader"}) do
  local good, err = pcall(freshRequire, game.ServerScriptService.OK.Services[n]); assert(good, n .. " failed: " .. tostring(err))
end
assert(#freshRequire(ok.Data.Credits) == 0, "Data.Credits should be empty since Prod Life III (OK's credits were removed)")
assert(game.ServerScriptService.OK.Main:IsA("Script") and not game.ServerScriptService.OK.Main.Disabled, "Main missing/disabled")
assert(game.StarterPlayer.StarterPlayerScripts.OK.ClientMain:IsA("LocalScript"), "ClientMain missing")
local ints = freshRequire(ok.Modules.Interactions); local n = 0; for _ in pairs(ints) do n += 1 end; assert(n == 11, "kinds != 11 (7 + Station + GearRack + Cypher + StudioTwoDoor): " .. n)
return "T06 OK: modules load, credits=" .. #require(ok.Data.Credits)
