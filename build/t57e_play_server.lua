-- Server, during play (after t57d: nothing open, the player at the studio PC; Review Focus 1): a pop and a walk-in
-- land in the same server call, back to back: Pop dm_dojabat (the client opens it at once), then Spawn navx_placement
-- (he walks to the player in the control room and arrives while the DM is open). t57f checks the client never shows
-- both cards.
local Players, SSS = game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
assert(#ph:Invoke("Pending", uid) == 0 and ph:Invoke("Busy", uid) == false, "pops or PhoneBusy left from t57d")
assert(wi:Invoke("Pending", uid) == nil, "a visit is still in flight before the spawn")
local t0 = os.clock()
local token = ph:Invoke("Pop", uid, "dm_dojabat")
local spawned = wi:Invoke("Spawn", uid, "navx_placement")
local took = os.clock() - t0
assert(type(token) == "string", "Pop(dm_dojabat) did not send")
assert(spawned == true, "Spawn(navx_placement) refused (is the player in the hub?)")
assert(took < 0.2, string.format("the pop and the spawn took %.2f s (want them within 0.2 s)", took))
local pend = wi:Invoke("Pending", uid)
assert(pend and pend.id == "navx_placement", "Spawn(navx_placement) left no pending visit: " .. tostring(pend and pend.id))
local pops = ph:Invoke("Pending", uid)
assert(#pops == 1 and pops[1].id == "dm_dojabat", "the DM is not pending: " .. #pops)
return string.format("T57E PLAY OK: dm_dojabat popped and navx_placement spawned %.2f s apart; he is walking in", took)
