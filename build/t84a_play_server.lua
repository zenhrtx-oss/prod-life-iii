-- Server, during play (Wave 3 Task 5c-2; launch audit A5/A12), before t84b: the file's own fresh() (unseated in the
-- lounge, WalkIns paused and reset, Career and Life Reset, ResetHints), then the cypher idle (each phase skipped, at most
-- 10 s) so the monitors are not reserved for a round. Then the monitor hook's spy on Flips.Judge armed from zero and
-- the player's flip-check stamp cleared, for t84b's sends; t84c reads the spy and takes it off.
-- fresh() deviates from the standard one on purpose: no Quiet, since t84b only calls remotes, which a phone card can't hold.
local Players, SSS, RS = game:GetService("Players"), game:GetService("ServerScriptService"), game:GetService("ReplicatedStorage")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local cy = SOK:WaitForChild("_StudioCypherHook", 5); assert(cy, "no _StudioCypherHook")
local mon = SOK:WaitForChild("_StudioMonitorHook", 5); assert(mon, "no _StudioMonitorHook")
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
local function fresh(label)
	local c = p.Character; local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum and hum.Sit then hum.Sit = false; task.wait(0.4) end
	teleport(LOUNGE)
	assert(wi:Invoke("Pause", uid, true) == true and wi:Invoke("Reset", uid) == true, label .. ": WalkIns Pause / Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	assert(life:Invoke("Reset", uid) == true, label .. ": Life Reset failed")
	assert(test:Invoke("ResetHints", uid) == true, label .. ": ResetHints failed")
	local t0 = os.clock()
	while cy:Invoke("State").phase ~= "idle" and os.clock() - t0 < 10 do cy:Invoke("Skip"); task.wait(0.4) end
	assert(cy:Invoke("State").phase == "idle", label .. ": the cypher did not get back to idle (" .. tostring(cy:Invoke("State").phase) .. ")")
	RS.OK.Cypher:SetAttribute("Phase", "idle")
	assert(RS.OK.NowPlaying:GetAttribute("Reserved") ~= true, label .. ": the monitors are still reserved for a cypher round")
	assert(mon:Invoke("SpyJudge") == true, label .. ": the monitor hook has no SpyJudge (the 5c-2 fix1 Main)")
	assert(mon:Invoke("ClearFlipCheck", uid) == true, label .. ": the monitor hook could not clear the player's flip-check stamp")
end

local ok, err = pcall(fresh, "t84a")
if not ok then
	pcall(function() mon:Invoke("UnspyJudge") end)
	error(err, 0)
end
return "T84A PLAY OK: unseated in the lounge; WalkIns paused and reset; Career and Life reset; no hints seen; the cypher idle, the monitors not reserved;"
	.. " the spy on Flips.Judge armed; the flip-check stamp cleared"
