-- Server, during play: grant 120 XP to the test player through the LIVE DataService (Studio-only hook) to cross a level.
local p = game:GetService("Players"):GetPlayers()[1]; assert(p, "no player")
local hook = game:GetService("ServerScriptService").OK:FindFirstChild("_StudioTestHook"); assert(hook, "test hook missing (Main not running in Studio?)")
local before = hook:Invoke("GetProfile", p.UserId)
local lv0, xp0 = before.level, before.xp
local need = 0; local Cfg = require(game:GetService("ReplicatedStorage").OK.Config)
local nextTh = Cfg.Levels[lv0 + 1]; need = nextTh and (nextTh - xp0) or 1
local gained = hook:Invoke("AddXP", p.UserId, need, nil)
local after = hook:Invoke("GetProfile", p.UserId)
assert(gained == need and after.level == lv0 + 1, "level did not go up")
p:SetAttribute("_ExpectLevel", after.level)
return string.format("T15 OK: +%d XP took level %d -> %d", gained, lv0, after.level)
