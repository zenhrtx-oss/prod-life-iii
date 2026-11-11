-- Server, during play (after t21d): a pretend producer's beat airs at 120 BPM (2 s bars); note the player's XP.
local SSS, RS = game:GetService("ServerScriptService"), game:GetService("ReplicatedStorage")
local mon = SSS.OK._StudioMonitorHook; local NP = RS.OK.NowPlaying
local p = game:GetService("Players"):GetPlayers()[1]
local hook = SSS.OK._StudioTestHook
local t0 = os.clock(); while NP:GetAttribute("Active") and os.clock() - t0 < 25 do task.wait(0.2) end
task.wait(3.2)
local r = mon:Invoke("Enqueue", -2201, "Fay Test", require(RS.OK.Modules.DAWConfig).DefaultPattern, 120)
assert(r.ok and r.position == 0, "pretend airing failed")
p:SetAttribute("_T22XP", hook:Invoke("GetProfile", p.UserId).xp)
return "T22 PLAY OK: Fay Test on air"
