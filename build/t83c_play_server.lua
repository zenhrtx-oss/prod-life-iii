-- Server, during play (Wave 3 Task 5c-2; launch audit A4), after t83b: the lobby cooldown that t83b's cancel started,
-- seen from the server. (1) It runs Config.Cypher.CancelCooldown seconds from the cancel (the hook's State.cooldown, a
-- few seconds gone by now), and it is server-wide: a pretend producer's Join, the board's own path, is refused "busy"
-- and opens nothing. (2) ClearCooldown lifts it: two pretend producers open a lobby, and the round cancelled in its build
-- (nothing submitted) starts no cooldown. Then the cleanup: the cypher idle, no cooldown, Quiet off, WalkIns reset, back
-- in the lounge.
-- This file continues t83a/t83b, like t82c, so it has no fresh() of its own.
local Players, SSS, RS = game:GetService("Players"), game:GetService("ServerScriptService"), game:GetService("ReplicatedStorage")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local cy = SOK:WaitForChild("_StudioCypherHook", 5); assert(cy, "no _StudioCypherHook")
local CY = RS.OK:WaitForChild("Cypher", 5); assert(CY, "no RS.OK.Cypher")
local Config = require(RS.OK.Config)
local LOUNGE = Vector3.new(24, 3, 0)
local out = {}

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function phase() return CY:GetAttribute("Phase") end
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

local function run()
	-- 1. the cooldown, and it holds the board's path for everyone
	local st = cy:Invoke("State")
	assert(type(st.cooldown) == "number", "the cypher hook's State reports no lobby cooldown (the 5c-2 BeatBattles)")
	local cd = (Config.Cypher or {}).CancelCooldown
	assert(cd == 60, "Config.Cypher.CancelCooldown is " .. tostring(cd) .. ", want 60")
	assert(st.cooldown > cd - 40 and st.cooldown <= cd, "no lobby cooldown on the server after t83b's lobby was cancelled for too few (State.cooldown "
		.. tostring(st.cooldown) .. ", want a few seconds under " .. cd .. ")")
	assert(st.phase == "idle", "the cypher is at " .. tostring(st.phase) .. " after t83b, want idle")
	local j = cy:Invoke("Join", -8301, "Cooldown Test")
	assert(type(j) == "table" and j.ok == false and j.reason == "busy" and phase() == "idle", "a pretend producer's Join in the cooldown answered "
		.. tostring(type(j) == "table" and j.reason) .. " (Phase " .. tostring(phase()) .. "), want busy and no lobby")
	table.insert(out, string.format("1 cooldown %.1f s left of %d; a pretend producer's Join: busy, no lobby", st.cooldown, cd))

	-- 2. lifted, a lobby opens again; a round cancelled in its build starts no cooldown
	assert(cy:Invoke("ClearCooldown") == true and cy:Invoke("State").cooldown == 0, "ClearCooldown did not lift the cooldown")
	local a, b = cy:Invoke("Join", -8302, "Cooldown A"), cy:Invoke("Join", -8303, "Cooldown B")
	assert(a and a.ok and b and b.ok and phase() == "lobby", "two pretend producers did not open a lobby after ClearCooldown (" .. tostring(a and a.reason) .. ")")
	cy:Invoke("Skip")
	assert(waitFor(function() return phase() == "build" end, 3), "the lobby of two did not move to the build (Phase " .. tostring(phase()) .. ")")
	cy:Invoke("Skip")
	assert(waitFor(function() return phase() == "reveal" end, 3), "the build with nothing submitted did not end (Phase " .. tostring(phase()) .. ")")
	assert(string.find(CY:GetAttribute("Result") or "", "not enough beats", 1, true), "the build ended with '" .. tostring(CY:GetAttribute("Result"))
		.. "', want the cancel for too few beats")
	assert(cy:Invoke("State").cooldown == 0, "a round cancelled in its build started a lobby cooldown (" .. tostring(cy:Invoke("State").cooldown) .. " s)")
	cy:Invoke("Skip")
	assert(waitFor(function() return phase() == "idle" end, 3), "the cypher did not idle after the build's cancel")
	table.insert(out, "2 ClearCooldown: two producers opened a lobby; its build, cancelled with nothing submitted, started no cooldown")
end

local ok, err = pcall(run)
pcall(function()
	local t0 = os.clock()
	while cy:Invoke("State").phase ~= "idle" and os.clock() - t0 < 10 do cy:Invoke("Skip"); task.wait(0.4) end
	if cy:Invoke("State").phase == "idle" then CY:SetAttribute("Phase", "idle") end
	cy:Invoke("ClearCooldown")
	ph:Invoke("Quiet", uid, false)
	wi:Invoke("Reset", uid)
end)
pcall(teleport, LOUNGE)
if not ok then error(err, 0) end
return "T83C PLAY OK\n" .. table.concat(out, "\n")
