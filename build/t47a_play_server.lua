-- Server, during play (walk-ins Task 7, before t47b): the scheduler paused, the player's walk-ins reset, the player in
-- the lounge at (24, 3, 0), the next roll forced to 1, and LIL NAV X's single follow-up (navx_single: a news strip and
-- three choices, the tallest card) spawned for t47b. Its news is rolled on arrival with that 1: HIT.
local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local wi = game:GetService("ServerScriptService").OK:WaitForChild("_StudioWalkInHook", 5)
assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local uid = p.UserId
wi:Invoke("Pause", uid, true)
wi:Invoke("Reset", uid)
assert(wi:Invoke("Pending", uid) == nil, "a visit is still in flight after Reset")
local char = p.Character; local root = char and char:FindFirstChild("HumanoidRootPart"); assert(root, "no character")
local hum = char:FindFirstChildOfClass("Humanoid")
if hum and hum.Sit then hum.Sit = false; task.wait(0.4) end
root.CFrame = CFrame.new(24, 3, 0); task.wait(0.3)
wi:Invoke("SetRng", uid, { 1 })
wi:Invoke("Spawn", uid, "navx_single")
local pend = wi:Invoke("Pending", uid)
assert(pend and pend.id == "navx_single", "Spawn(navx_single) left no pending visit: " .. tostring(pend and pend.id))
return "T47A PLAY OK: paused, reset, player at (24, 3, 0), next roll 1, navx_single walking in"
