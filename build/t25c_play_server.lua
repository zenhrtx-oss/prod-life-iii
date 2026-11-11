-- Server, during play (after t25b): the weekly paid once with the 3-star rate.
local p = game:GetService("Players"):GetPlayers()[1]
local hook = game:GetService("ServerScriptService").OK._StudioTestHook
local Config = require(game:GetService("ReplicatedStorage").OK.Config)
local prof = hook:Invoke("GetProfile", p.UserId)
local gain = prof.cred - p:GetAttribute("_T25Cred")
assert(gain == math.floor(Config.Weekly.Cred * 1.5 + 0.5), "weekly Cred +" .. gain)
assert(prof.weekly and prof.weekly.stars == 3 and #prof.plaques == 1, "weekly record wrong")
return "T25C OK: weekly paid +" .. gain .. " Cred once (3-star rate) and recorded the plaque"
