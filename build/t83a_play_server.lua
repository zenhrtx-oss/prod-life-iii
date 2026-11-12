-- Server, during play (Wave 3 Task 5c-2; launch audit A2/A4), before t83b: the file's own fresh() (unseated in the
-- lounge, Quiet on, WalkIns, Career and Life Reset, ResetHints), then the cypher idle (each phase skipped, at most 10 s)
-- with no lobby cooldown (the cypher hook's ClearCooldown) and the player in no round. Quiet stays on through t83b;
-- t83c turns it off. On any error Quiet goes off and the error is rethrown.
local Players, SSS, RS = game:GetService("Players"), game:GetService("ServerScriptService"), game:GetService("ReplicatedStorage")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local cy = SOK:WaitForChild("_StudioCypherHook", 5); assert(cy, "no _StudioCypherHook")
local CY = RS.OK:WaitForChild("Cypher", 5); assert(CY, "no RS.OK.Cypher")
local LOUNGE = Vector3.new(24, 3, 0)

local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function teleport(pos) -- server-side; checked, and tried once more if the client's position won
	for _ = 1, 2 do
		local c = p.Character or p.CharacterAdded:Wait()
		c:WaitForChild("HumanoidRootPart", 5)
		c:PivotTo(CFrame.new(pos))
		task.wait(0.3)
		local r = c:FindFirstChild("HumanoidRootPart")
		if r and flat(r.Position - pos) < 2 then return r end
	end
	error("teleport to " .. tostring(pos) .. " did not take")
end
-- the file's own fresh(): unseated and in the lounge, Quiet on, WalkIns, Career and Life reset, no hint seen; the cypher
-- idle with no lobby cooldown
local function fresh(label)
	local c = p.Character; local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum and hum.Sit then hum.Sit = false; task.wait(0.4) end
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, label .. ": Quiet(true) failed")
	assert(wi:Invoke("Pause", uid, true) == true and wi:Invoke("Reset", uid) == true, label .. ": WalkIns Pause / Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	assert(life:Invoke("Reset", uid) == true, label .. ": Life Reset failed")
	assert(test:Invoke("ResetHints", uid) == true, label .. ": ResetHints failed")
	local t0 = os.clock()
	while cy:Invoke("State").phase ~= "idle" and os.clock() - t0 < 10 do cy:Invoke("Skip"); task.wait(0.4) end
	assert(cy:Invoke("State").phase == "idle", label .. ": the cypher did not get back to idle (" .. tostring(cy:Invoke("State").phase) .. ")")
	CY:SetAttribute("Phase", "idle") -- the system is idle: a Phase another file set by hand goes back with it
	assert(cy:Invoke("ClearCooldown") == true, label .. ": the cypher hook has no ClearCooldown (the 5c-2 Main and BeatBattles)")
	assert(p:GetAttribute("CypherIn") == nil, label .. ": the player is still marked in round " .. tostring(p:GetAttribute("CypherIn")))
end

local ok, err = pcall(fresh, "t83a")
if not ok then
	pcall(function() ph:Invoke("Quiet", uid, false) end)
	error(err, 0)
end
return "T83A PLAY OK: unseated in the lounge; Quiet on for t83b; WalkIns, Career and Life reset; no hints seen; the cypher idle, no lobby cooldown"
