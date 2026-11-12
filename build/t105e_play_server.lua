-- Server, during play (the Your Rooms plan, Task 6): puts back what t105c staged for t105d, so no later file finds the
-- player's bedroom owned by someone else or request j1 still active (the next file a "--play t10" run takes,
-- t10_play_client, has no fresh() of its own). Unseated in the lounge, held (WalkInsPaused true): the rooms hook's Reset
-- rebuilds the plot for its owner, so the bedroom's OwnerId and OwnerName are the player's again (checked), and its
-- laptop answers MayUse true; the active request is cleared (SetActiveRequest nil); the phone, WalkIns, Career and Life
-- are reset, no hint seen, Quiet off.
local Players, SSS = game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local rooms = SOK:WaitForChild("_StudioRoomsHook", 5); assert(rooms, "no _StudioRoomsHook (is Systems/Rooms synced and started?)")
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local LOUNGE = Vector3.new(24, 3, 0)

local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function root() local c = p.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = p.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function teleport(pos) -- the test's own move; checked, and tried once more if the client's position won
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
local function unseat()
	local h = hum()
	if h and (h.Sit or h.SeatPart) then h.Sit = false; task.wait(0.4) end
end
local function call(cmd, a, b) return rooms:Invoke(cmd, uid, a, b) end

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	unseat()
	teleport(LOUNGE) -- first, so the rebuild never happens under the player
	assert(call("Reset") == true, "the rooms hook's Reset failed (no slot, or the plot did not build)")
	local st = call("Station")
	assert(typeof(st) == "Instance", "the hook's Station answered " .. tostring(st) .. " after the Reset, want the bedroom's laptop")
	local bed = st:FindFirstAncestor("Room_bedroom")
	assert(bed, "the bedroom's laptop is not inside a Room_bedroom Model: " .. st:GetFullName())
	assert(bed:GetAttribute("OwnerId") == uid and bed:GetAttribute("OwnerName") == p.DisplayName, string.format(
		"after the Reset the bedroom's OwnerId / OwnerName are %s / %s, want %d / %s", tostring(bed:GetAttribute("OwnerId")),
		tostring(bed:GetAttribute("OwnerName")), uid, p.DisplayName))
	local ok = rooms:Invoke("MayUse", uid, st)
	assert(ok == true, "after the Reset the hook's MayUse on the bedroom's laptop answered " .. tostring(ok) .. ", want true")
	assert(test:Invoke("SetActiveRequest", uid, nil) == true, "SetActiveRequest(nil) failed")
	return "T105E PLAY OK\nthe plot rebuilt for its owner (OwnerId " .. uid .. ", MayUse true), the active request cleared"
end

local okRun, msg = pcall(run)
pcall(unseat)
pcall(teleport, LOUNGE)
pcall(function()
	if not okRun then rooms:Invoke("Reset", uid); test:Invoke("SetActiveRequest", uid, nil) end
	wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
	test:Invoke("ResetHints", uid); ph:Invoke("Quiet", uid, false)
end)
if not okRun then error(msg, 0) end
return msg
