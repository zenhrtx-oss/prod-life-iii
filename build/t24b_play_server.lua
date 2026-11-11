-- Server, during play (after t24): pretend the player took yesterday's daily and never delivered it.
local p = game:GetService("Players"):GetPlayers()[1]
local hook = game:GetService("ServerScriptService").OK._StudioTestHook
local DR = require(game:GetService("ReplicatedStorage").OK.Modules.DailyRequests)
local id = "d" .. DR.PrevDay(DR.Day(os.time())) .. "_1"
assert(hook:Invoke("SetActiveRequest", p.UserId, id), "could not set the stale daily")
p:SetAttribute("_T24Stale", id)
return "T24B OK: active request set to yesterday's " .. id
