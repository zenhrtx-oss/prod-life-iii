-- Server, during play (the Your Rooms plan, Task 6; preflight F3): the staging for t105d, which a client can't do itself.
-- From the file's fresh() (unseated in the lounge, Quiet on, the phone, WalkIns, Career and Life reset, no hint seen, the
-- rooms hook's Reset: a slot claimed, the plot rebuilt), held (WalkInsPaused true): WakeUp puts the player in their
-- bedroom; request j1 is made active (so a delivery gets past the request check to the station check); then the bedroom's
-- OwnerId is set to -10501 and its OwnerName to "Test Owner 7" (preflight m19: set directly), and the hook's MayUse on the
-- bedroom's laptop answers false, "Test Owner 7". The staging is left in place for t105d; t105e puts it back (a rooms
-- Reset rebuilds the plot with the player's own OwnerId). On any error here the staging is undone at once (the owner put
-- back, unseated in the lounge, the rooms Reset, everything reset, Quiet off) and the error rethrown.
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
local OTHER_ID, OTHER_NAME = -10501, "Test Owner 7" -- t105a's and t105d's
local RED = " (before the R-T6 sync: the expected red)"
local staged -- { room, id, name }

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
local function fresh(label)
	unseat()
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, label .. ": Quiet(true) failed")
	assert(ph:Invoke("Reset", uid) == true, label .. ": phone Reset failed")
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	assert(life:Invoke("Reset", uid) == true, label .. ": Life Reset failed")
	assert(test:Invoke("ResetHints", uid) == true, label .. ": ResetHints failed")
	assert(call("Reset") == true, label .. ": the rooms hook's Reset failed (no slot, or the plot did not build)")
end

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh("stage")
	assert(call("WakeUp") == true, "WakeUp returned false")
	local st = call("Station")
	assert(typeof(st) == "Instance", "the hook's Station answered " .. tostring(st) .. ", want the bedroom's laptop")
	local bed = st:FindFirstAncestor("Room_bedroom")
	assert(bed and bed:IsA("Model"), "the bedroom's laptop is not inside a Room_bedroom Model: " .. st:GetFullName())
	assert(bed:FindFirstChild("RackSpot"), "Room_bedroom has no RackSpot" .. RED)
	assert(test:Invoke("SetActiveRequest", uid, "j1") == true, "SetActiveRequest(j1) failed")
	staged = { room = bed, id = bed:GetAttribute("OwnerId"), name = bed:GetAttribute("OwnerName") }
	assert(staged.id == uid, "the bedroom's OwnerId is " .. tostring(staged.id) .. " before the staging, want " .. uid)
	bed:SetAttribute("OwnerId", OTHER_ID); bed:SetAttribute("OwnerName", OTHER_NAME)
	local ok, name = rooms:Invoke("MayUse", uid, st)
	assert(ok == false and name == OTHER_NAME, "staged: the hook's MayUse on the laptop answered " .. tostring(ok) .. ", " .. tostring(name)
		.. "; want false, " .. OTHER_NAME .. RED)
	return "T105C PLAY OK\nthe player in their bedroom (" .. bed:GetFullName() .. "), request j1 active; the bedroom staged as OwnerId "
		.. OTHER_ID .. ", OwnerName " .. OTHER_NAME .. " (MayUse false, the name) for t105d"
end

local ok, msg = pcall(run)
if not ok then
	pcall(function()
		local s = staged
		if s and s.room.Parent then s.room:SetAttribute("OwnerId", s.id); s.room:SetAttribute("OwnerName", s.name) end
	end)
	pcall(unseat)
	pcall(teleport, LOUNGE)
	pcall(function() rooms:Invoke("Reset", uid) end)
	pcall(function()
		test:Invoke("SetActiveRequest", uid, nil)
		wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
		test:Invoke("ResetHints", uid); ph:Invoke("Quiet", uid, false)
	end)
	error(msg, 0)
end
return msg
