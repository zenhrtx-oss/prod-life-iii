-- Server, during play (after t47f): end the cypher round (Skip each phase until idle, at most 30 s); the walk-in is
-- still waiting for t47h.
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
local pend = wi:Invoke("Pending", p.UserId)
assert(pend and pend.arrived, "the walk-in should still be waiting after the cypher")
return string.format("T47G PLAY OK: cypher idle after %d skips (%.1f s); the walk-in is still waiting", skips, os.clock() - t1)
