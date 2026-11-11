-- Server, during play (after t47b chose and opened the beat maker): spawn LIL NAV X's placement card again; he walks
-- to the player at the studio PC while the beat maker is open.
local p = game:GetService("Players"):GetPlayers()[1]; assert(p, "no player")
local wi = game:GetService("ServerScriptService").OK:WaitForChild("_StudioWalkInHook", 5)
assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
wi:Invoke("Spawn", p.UserId, "navx_placement")
local pend = wi:Invoke("Pending", p.UserId)
assert(pend and pend.id == "navx_placement", "Spawn(navx_placement) left no pending visit (t47b's choice should have cleared the last one)")
return "T47C PLAY OK: navx_placement walking in again"
