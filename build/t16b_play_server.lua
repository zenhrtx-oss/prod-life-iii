-- Server, during play: grant XP up to level 4 and the Roll FX + Swing Unit gear (Studio-only hook).
local p = game:GetService("Players"):GetPlayers()[1]; assert(p, "no player")
local hook = game:GetService("ServerScriptService").OK._StudioTestHook
local Cfg = require(game:GetService("ReplicatedStorage").OK.Config)
local prof = hook:Invoke("GetProfile", p.UserId)
local need = Cfg.Levels[4] - prof.xp
if need > 0 then hook:Invoke("AddXP", p.UserId, need, nil) end
local after = hook:Invoke("GetProfile", p.UserId)
assert(after.level == 4, "level after grant: " .. tostring(after.level))
assert(hook:Invoke("GrantGear", p.UserId, "rollfx,swing"), "gear grant failed")
local t0 = os.clock(); while not ((p:GetAttribute("Unlocked") or ""):find("Swing")) and os.clock() - t0 < 2 do task.wait(0.05) end
assert((p:GetAttribute("Unlocked") or ""):find("Rolls") and p:GetAttribute("Unlocked"):find("Swing"), "Unlocked attribute not updated: " .. tostring(p:GetAttribute("Unlocked")))
return "T16B OK: level " .. prof.level .. " -> 4; Roll FX and Swing Unit granted"
