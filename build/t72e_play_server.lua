-- Server, during play (Wave 2 Task 4; after t72d): puts t72a's staging back, whatever happened in between: the walk-ins,
-- the phone, the career, the life (its Reset also clears the roster), the sessions and the daily streak. Quiet goes off last.
local Players, SSS = game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi, ph = SOK:WaitForChild("_StudioWalkInHook", 5), SOK:WaitForChild("_StudioPhoneHook", 5)
local career, life, test = SOK:WaitForChild("_StudioCareerHook", 5), SOK:WaitForChild("_StudioLifeHook", 5), SOK:WaitForChild("_StudioTestHook", 5)
assert(wi and ph and career and life and test, "a Studio hook is missing")
assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
assert(wi:Invoke("Reset", uid) == true, "WalkIns Reset failed")
assert(ph:Invoke("Reset", uid) == true, "Phone Reset failed")
assert(career:Invoke("Reset", uid) == true, "Career Reset failed")
assert(life:Invoke("Reset", uid) == true, "Life Reset failed")
assert(test:Invoke("ResetSessions", uid) == true, "ResetSessions failed")
assert(test:Invoke("ResetDaily", uid, 0, nil) == true, "ResetDaily failed")
assert(ph:Invoke("Quiet", uid, false) == true, "Quiet(false) failed")
return "T72E PLAY OK: staging put back"
