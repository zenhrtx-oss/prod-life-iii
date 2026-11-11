-- Server, during play (after t19b): taking Ava off the air lets Bo on after the gap, which moves the player to #2;
-- taking Bo off puts the player's beat on air.
local SSS, RS = game:GetService("ServerScriptService"), game:GetService("ReplicatedStorage")
local mon = SSS.OK._StudioMonitorHook
local NP = RS.OK.NowPlaying
local p = game:GetService("Players"):GetPlayers()[1]
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
assert(mon:Invoke("Cancel", -1901) == "stopped", "Ava was not on air")
assert(waitFor(function() return NP:GetAttribute("Active") and NP:GetAttribute("OwnerName") == "Bo Test" end, 5), "Bo did not follow Ava")
assert(NP:GetAttribute("QueueIds") == tostring(p.UserId), "player should be next: " .. tostring(NP:GetAttribute("QueueIds")))
task.wait(1.0) -- let the client see its new place ("Up next")
assert(mon:Invoke("Cancel", -1902) == "stopped", "Bo was not on air")
assert(waitFor(function() return NP:GetAttribute("Active") and NP:GetAttribute("OwnerId") == p.UserId end, 5), "the player's beat did not air after Bo")
return "T19C OK: Ava stopped, Bo aired after the gap, player moved up, then aired"
