-- Server, during play (after t23d): the streak bonus (Config.Daily.StreakBonus[3]) was paid with the daily.
local p = game:GetService("Players"):GetPlayers()[1]
local hook = game:GetService("ServerScriptService").OK._StudioTestHook
local Config = require(game:GetService("ReplicatedStorage").OK.Config)
local prof = hook:Invoke("GetProfile", p.UserId)
assert(prof.daily.streak == 3, "streak " .. tostring(prof.daily.streak))
local gain = prof.cred - p:GetAttribute("_T23Cred")
local stars = 0; for _, s in pairs(prof.daily.done) do stars = s end
local expect = math.floor(Config.Daily.Cred * (stars >= 3 and 1.5 or 1) + 0.5) + Config.Daily.StreakBonus[3]
assert(gain == expect, "expected +" .. expect .. " Cred (daily + 3-day bonus), got +" .. gain)
return "T23E OK: streak 3 paid the daily and the " .. Config.Daily.StreakBonus[3] .. " Cred bonus (+" .. gain .. ")"
