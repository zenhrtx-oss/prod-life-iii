-- Server, during play (Wave 3 Task 5c-2; launch audit A7), before t86b: the file's own fresh() (unseated in the lounge,
-- Quiet on, WalkIns, Career and Life Reset, ResetHints), then a session that can't save, with no store: the test hook's
-- SaveFlags flags the player's profile _loadFailed (as a load whose every attempt failed) and sets
-- DataService.Persistent (as a live server with a store; Studio Play has none, so nothing is written either way).
-- DataService.Saving is then false. What both were is kept on the player (_T86Was*) for t86c, which puts them back
-- and turns Quiet off; on an error here they go back at once and the error is rethrown.
local Players, SSS = game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
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
	assert(ph:Invoke("Quiet", uid, true) == true, label .. ": Quiet(true) failed")
	assert(wi:Invoke("Pause", uid, true) == true and wi:Invoke("Reset", uid) == true, label .. ": WalkIns Pause / Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	assert(life:Invoke("Reset", uid) == true, label .. ": Life Reset failed")
	assert(test:Invoke("ResetHints", uid) == true, label .. ": ResetHints failed")
end

local function run()
	fresh("t86a")
	local r = test:Invoke("SaveFlags", uid, { loadFailed = true, persistent = true })
	assert(type(r) == "table" and type(r.was) == "table", "the test hook has no SaveFlags (the 5c-2 Main)")
	p:SetAttribute("_T86WasLoadFailed", r.was.loadFailed == true)
	p:SetAttribute("_T86WasPersistent", r.was.persistent == true)
	assert(r.saving == false, "DataService.Saving is " .. tostring(r.saving) .. " for a profile flagged _loadFailed on a store")
	return string.format("flagged _loadFailed (was %s), Persistent on (was %s): Saving false", tostring(r.was.loadFailed), tostring(r.was.persistent))
end

local ok, msg = pcall(run)
if not ok then
	pcall(function()
		local was = p:GetAttribute("_T86WasPersistent")
		if was ~= nil then test:Invoke("SaveFlags", uid, { loadFailed = p:GetAttribute("_T86WasLoadFailed") == true, persistent = was }) end
		p:SetAttribute("_T86WasLoadFailed", nil); p:SetAttribute("_T86WasPersistent", nil)
		ph:Invoke("Quiet", uid, false)
	end)
	error(msg, 0)
end
return "T86A PLAY OK: unseated in the lounge; Quiet on; WalkIns, Career and Life reset; no hints seen; " .. msg
