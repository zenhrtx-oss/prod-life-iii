-- Server, during play (after t27b): two pretend producers open a cypher lobby.
local SSS, RS = game:GetService("ServerScriptService"), game:GetService("ReplicatedStorage")
local cy = SSS.OK._StudioCypherHook; local NP = RS.OK.NowPlaying
local t0 = os.clock(); while NP:GetAttribute("Active") and os.clock() - t0 < 25 do task.wait(0.2) end
assert(RS.OK.Cypher:GetAttribute("Phase") == "idle", "cypher not idle")
local a = cy:Invoke("Join", -2801, "Cy Test"); local b = cy:Invoke("Join", -2802, "Dee Test")
assert(a.ok and a.phase == "lobby" and b.ok, "pretend producers could not open a lobby")
assert(not cy:Invoke("Join", -2801, "Cy Test").ok, "joined twice")
return "T28 PLAY OK: lobby open with Cy Test and Dee Test"
