-- Server, during play (after t47d): the walk-in card is still waiting and the cypher is idle, on the server and in its
-- Phase attribute. t47f drives the Phase (and the player's CypherIn) on its own client only, and puts them back there,
-- so no selection of these files can leave the server's walk-ins or phone pops held (launch audit A2/A4).
local SSS, RS = game:GetService("ServerScriptService"), game:GetService("ReplicatedStorage")
local p = game:GetService("Players"):GetPlayers()[1]; assert(p, "no player")
local cy = SSS.OK._StudioCypherHook; local CY = RS.OK.Cypher
local wi = SSS.OK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook")
local pend = wi:Invoke("Pending", p.UserId)
assert(pend and pend.arrived, "the walk-in from t47c should have arrived and be waiting")
assert(CY:GetAttribute("Phase") == "idle" and cy:Invoke("State").phase == "idle", "cypher not idle before the case: " .. tostring(CY:GetAttribute("Phase")))
assert(p:GetAttribute("CypherIn") == nil, "the player is marked in cypher round " .. tostring(p:GetAttribute("CypherIn")))
return "T47E PLAY OK: the cypher idle, the player in no round; the walk-in is still waiting"
