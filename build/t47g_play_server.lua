-- Server, during play (after t47f): the cypher still idle. t47f changed the Phase and the player's CypherIn on its client
-- only, so the server's are as t47e found them; a round that is somehow running is skipped through each phase (at most
-- 30 s). The walk-in is still pending for t47h, its card open since t47f's lobby.
local SSS, RS = game:GetService("ServerScriptService"), game:GetService("ReplicatedStorage")
local p = game:GetService("Players"):GetPlayers()[1]; assert(p, "no player")
local cy = SSS.OK._StudioCypherHook; local CY = RS.OK.Cypher
local wi = SSS.OK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook")
local t1, skips = os.clock(), 0
while (CY:GetAttribute("Phase") or "idle") ~= "idle" and os.clock() - t1 < 30 do
  cy:Invoke("Skip"); skips += 1
  task.wait(0.6)
end
assert((CY:GetAttribute("Phase") or "idle") == "idle", "cypher still " .. tostring(CY:GetAttribute("Phase")) .. " after 30 s of skips")
assert(p:GetAttribute("CypherIn") == nil, "the player is marked in cypher round " .. tostring(p:GetAttribute("CypherIn")) .. " on the server")
local pend = wi:Invoke("Pending", p.UserId)
assert(pend and pend.arrived, "the walk-in should still be pending after the cypher")
return string.format("T47G PLAY OK: cypher idle (%d skips), the player in no round; the walk-in is still pending", skips)
