-- Server, during play (after t23b): the daily paid once; then pretend yesterday ended a 2-day streak.
local p = game:GetService("Players"):GetPlayers()[1]
local hook = game:GetService("ServerScriptService").OK._StudioTestHook
local DR = require(game:GetService("ReplicatedStorage").OK.Modules.DailyRequests)
local Config = require(game:GetService("ReplicatedStorage").OK.Config)
local prof = hook:Invoke("GetProfile", p.UserId)
local today = DR.Day(os.time())
local stars
for id, s in pairs(prof.daily.done) do stars = s end
assert(stars and prof.daily.streak == 1 and prof.daily.day == today, "daily not recorded")
local mult = stars >= 3 and 1.5 or 1
local credGain = prof.cred - p:GetAttribute("_T23Cred")
assert(credGain == math.floor(Config.Daily.Cred * mult + 0.5), "daily Cred wrong: +" .. credGain .. " for " .. stars .. " stars")
assert(prof.xp - p:GetAttribute("_T23XP") >= math.floor(Config.Daily.XP * mult + 0.5), "daily XP not paid")
assert(hook:Invoke("ResetDaily", p.UserId, 2, DR.PrevDay(today)), "reset failed")
p:SetAttribute("_T23Cred", hook:Invoke("GetProfile", p.UserId).cred)
return "T23C OK: daily paid +" .. credGain .. " Cred once; streak set to 2 ending yesterday"
