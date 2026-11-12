-- Server, during play (Wave 3 Task 5c-2; launch audit A6), before t85b: the file's own fresh() (unseated in the lounge,
-- WalkIns paused and reset, Career and Life Reset, ResetHints). A reset career has no placement and no sponsor, so
-- every Career_Unlock t85b sends for studio_two or sponsor_tv is refused for its needs and changes nothing.
-- fresh() deviates from the standard one on purpose: no Quiet, since t85b only calls remotes, which a phone card can't hold.
local Players, SSS = game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
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
	assert(wi:Invoke("Pause", uid, true) == true and wi:Invoke("Reset", uid) == true, label .. ": WalkIns Pause / Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	assert(life:Invoke("Reset", uid) == true, label .. ": Life Reset failed")
	assert(test:Invoke("ResetHints", uid) == true, label .. ": ResetHints failed")
	local have = career:Invoke("Get", uid)
	assert(have and (have.placements or 0) == 0 and have.sponsor == nil and not (have.gates or {}).studio_two, label
		.. ": the reset career has a placement, a sponsor or studio_two")
end

local ok, err = pcall(fresh, "t85a") -- nothing of this file's to put back on an error
if not ok then error(err, 0) end
return "T85A PLAY OK: unseated in the lounge; WalkIns paused and reset; a reset career (no placement, no sponsor, no studio_two); no hints seen"
