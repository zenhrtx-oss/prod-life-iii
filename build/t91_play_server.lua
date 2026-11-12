-- Server, during play (Wave 3 Task 5d; launch audit A14): while a visitor walks, his figure is posed about 15-20 times a
-- second, not on every Heartbeat (each pose writes every part's CFrame, replicated to every client). The file's own
-- fresh() (unseated in the lounge, Quiet on, the phone's pops dropped, WalkIns, Career and Life reset, ResetHints,
-- SetRecent({})) with the scheduler held; then a visitor of its own through Modules/Visitor (as t42), slowed to WalkSpeed
-- 4 so the window is mid-walk, is watched for 1.5 s from 0.3 s after he spawns: his Torso's CFrame, read on every
-- Heartbeat, changes 12-22 times a second (today it changes on every frame, about 60), he still walks (his Torso moves
-- 3 studs or more) and he has not arrived. He is destroyed at the end, also on an error.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local Visitor = require(RS.OK.Modules.Visitor)
local W = require(RS.OK.Config).WalkIns
local LOUNGE = Vector3.new(24, 3, 0)
local WINDOW = 1.5

local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function root() local c = p.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function teleport(pos) -- server-side; checked, and tried once more if the client's position won
	for _ = 1, 2 do
		local c = p.Character or p.CharacterAdded:Wait()
		c:WaitForChild("HumanoidRootPart", 5)
		c:PivotTo(CFrame.new(pos))
		task.wait(0.3)
		local r = root()
		if r and flat(r.Position - pos) < 2 then return r end
	end
	error("teleport to " .. tostring(pos) .. " did not take")
end
local function fresh(label)
	local c = p.Character; local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum and hum.Sit then hum.Sit = false; task.wait(0.4) end
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, label .. ": Quiet(true) failed")
	assert(ph:Invoke("Reset", uid) == true, label .. ": phone Reset failed")
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	assert(life:Invoke("Reset", uid) == true, label .. ": Life Reset failed")
	assert(test:Invoke("ResetHints", uid) == true, label .. ": ResetHints failed")
	assert(type(test:Invoke("SetRecent", uid, {})) == "table", label .. ": SetRecent({}) failed")
end

local h
local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh("start")
	local w = table.clone(W)
	w.WalkSpeed = 4
	h = Visitor.Spawn({ id = "t91_walker", name = "T91 WALKER", style = "test visitor", color = { 255, 60, 160 }, sig = "none" }, p, { walkins = w })
	task.wait(0.3)
	local torso = h.Model:FindFirstChild("Torso")
	assert(torso and h.Model.PrimaryPart == torso, "the walker has no Torso PrimaryPart")
	assert(not h.Arrived, "he arrived within 0.3 s")
	local last, changes, frames, start = torso.CFrame, 0, 0, torso.Position
	local t0 = os.clock()
	while os.clock() - t0 < WINDOW do
		RunService.Heartbeat:Wait()
		frames += 1
		local now = torso.CFrame
		if now ~= last then changes += 1; last = now end
	end
	local elapsed = os.clock() - t0
	local hz, fps, moved = changes / elapsed, frames / elapsed, (torso.Position - start).Magnitude
	assert(not h.Arrived, string.format("he arrived inside the %.1f s window: the window must be mid-walk", WINDOW))
	assert(moved >= 3, string.format("he moved %.1f studs in %.1f s: he is not walking", moved, elapsed))
	assert(hz >= 12 and hz <= 22, string.format("his figure was posed %d times in %.2f s while he walked: %.1f a second at %.0f Heartbeats a second (want about 15-20: launch audit A14, not every Heartbeat)",
		changes, elapsed, hz, fps))
	return string.format("T91 PLAY OK: walking, his figure posed %d times in %.2f s (%.1f Hz at %.0f fps; A14), moved %.1f studs", changes, elapsed, hz, fps, moved)
end

local ok, res = pcall(run)
if h then pcall(h.Destroy, h) end
pcall(teleport, LOUNGE)
if not ok then error(res, 0) end
return res
