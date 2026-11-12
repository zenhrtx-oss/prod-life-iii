-- Server, during play (Wave 3 Task 5c-1), after t82b: the cleanup t82a's staging left for the end. Its fresh() is the
-- restore: unseated in the lounge and Quiet off (t82a turned it on for t82b), pass or fail.
local Players, SSS = game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local ph = SSS.OK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local LOUNGE = Vector3.new(24, 3, 0)

local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function fresh()
	local c = p.Character or p.CharacterAdded:Wait()
	local hum = c:FindFirstChildOfClass("Humanoid")
	if hum and hum.Sit then hum.Sit = false; task.wait(0.4) end
	assert(ph:Invoke("Quiet", uid, false) == true, "Quiet(false) failed")
	c:WaitForChild("HumanoidRootPart", 5)
	c:PivotTo(CFrame.new(LOUNGE)); task.wait(0.3)
	local r = c:FindFirstChild("HumanoidRootPart")
	assert(r and flat(r.Position - LOUNGE) < 2, "teleport to the lounge did not take")
end

local ok, err = pcall(fresh)
if not ok then
	pcall(function() ph:Invoke("Quiet", uid, false) end)
	error(err, 0)
end
return "T82C PLAY OK: Quiet off, back in the lounge"
