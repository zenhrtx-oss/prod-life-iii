-- Server, during play (after t22b): the listener got the tap XP; now the player's own beat airs and a pretend listener
-- gives it FIRE: the producer gets +1 FIRE (attribute, nameplate) and Config.Cred.Sources.Fire.amount ($30).
local SSS, RS = game:GetService("ServerScriptService"), game:GetService("ReplicatedStorage")
local mon = SSS.OK._StudioMonitorHook; local NP = RS.OK.NowPlaying
local hook = SSS.OK._StudioTestHook
local Config = require(RS.OK.Config)
local p = game:GetService("Players"):GetPlayers()[1]
local prof = hook:Invoke("GetProfile", p.UserId)
assert(prof.xp == p:GetAttribute("_T22XP") + 2, "listener tap XP not paid: " .. (prof.xp - p:GetAttribute("_T22XP")))
mon:Invoke("Cancel", -2201)
task.wait(3.3)
local r = mon:Invoke("Enqueue", p.UserId, p.DisplayName, require(RS.OK.Modules.DAWConfig).DefaultPattern, 120)
assert(r.ok and r.position == 0 and NP:GetAttribute("OwnerId") == p.UserId, "the player's beat did not air")
local fire0, cred0 = p:GetAttribute("FireTotal") or 0, prof.cred or 0
mon:Invoke("FireAs", -2202)
assert(p:GetAttribute("FireTotal") == fire0 + 1 and hook:Invoke("GetProfile", p.UserId).cred == cred0 + Config.Cred.Sources.Fire.amount, "producer side of FIRE wrong")
return "T22C OK: listener +2 XP for the tap; producer +1 FIRE and +$" .. Config.Cred.Sources.Fire.amount
