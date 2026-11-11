-- Server, during play (after t47d): two pretend producers open a cypher lobby, so the phase leaves idle while the
-- walk-in card is still waiting.
local SSS, RS = game:GetService("ServerScriptService"), game:GetService("ReplicatedStorage")
local p = game:GetService("Players"):GetPlayers()[1]; assert(p, "no player")
local cy = SSS.OK._StudioCypherHook; local CY = RS.OK.Cypher
local wi = SSS.OK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook")
local pend = wi:Invoke("Pending", p.UserId)
assert(pend and pend.arrived, "the walk-in from t47c should have arrived and be waiting")
assert(CY:GetAttribute("Phase") == "idle", "cypher not idle before the join: " .. tostring(CY:GetAttribute("Phase")))
local a = cy:Invoke("Join", -4701, "Walk Test A"); local b = cy:Invoke("Join", -4702, "Walk Test B")
assert(a and a.ok and b and b.ok, "pretend producers could not open a lobby")
assert(CY:GetAttribute("Phase") ~= "idle", "phase still idle after two joins")
return "T47E PLAY OK: cypher " .. CY:GetAttribute("Phase") .. " with Walk Test A and B; the walk-in is still waiting"
