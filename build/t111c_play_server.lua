-- Server, during play (the Your Rooms plan, Task 12; preflight F3): the staging for t111d, which a client can't do itself.
-- After t111b's home delivery, held (WalkInsPaused true), nothing reset but the sessions: unseated; ResetSessions (so
-- t111b's beat, now the sessions' `last`, doesn't make t111d's same 8 pads a copy) and request j1 active again
-- (SetActiveRequest); WakeUp puts the player in their bedroom, then they are moved to the bedroom's stand spot
-- (room-local (2, 0, -3), t105b's and t124a's), where the hook's StationOf names the bedroom's laptop and the hook's
-- Booth of that laptop answers false (a room with no booth). t111e puts everything back. Nothing is staged without
-- t111a's _T111Tour note (t111a failed and put the profile back itself). On any error here: the full put-back (t111e's)
-- and the error rethrown.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local rooms = SOK:WaitForChild("_StudioRoomsHook", 5); assert(rooms, "no _StudioRoomsHook (is Systems/Rooms synced and started?)")
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local DAWCfg = require(RS.OK.Modules.DAWConfig)
local Tour = require(RS.OK.Systems.Tour) -- its Steps only
local LOUNGE = Vector3.new(24, 3, 0)
local BED_STAND = Vector3.new(2, 0, -3) -- room-local (t105b's, t124a's)
local RED = " (before the R-T12 sync of Systems/Rooms: the expected red)"

local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function show(v) local okJ, js = pcall(function() return game:GetService("HttpService"):JSONEncode(v) end); return okJ and js or tostring(v) end
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
local function parseTour(note)
	if type(note) ~= "string" then return nil end
	local ids, done, skipped = string.match(note, "^([^|]*)|([^|]*)|([^|]*)$")
	if not ids then return nil end
	local got = {}
	for id in string.gmatch(ids, "[^,]+") do got[id] = true end
	return { got = got, done = done == "done", skipped = skipped == "skipped" }
end
local function restoreTour(before)
	test:Invoke("ResetTour", uid)
	if not before then return end
	if before.skipped then test:Invoke("TourSkip", uid); return end
	for _, s in ipairs(Tour.Steps) do
		if before.done or before.got[s.id] then test:Invoke("TourAdvance", uid, s.id) end
	end
end
-- t111e's put-back, every step tried
local function putBack()
	local steps = {}
	local function try(label, fn)
		local good, err = pcall(fn)
		if not good then table.insert(steps, label .. ": " .. tostring(err)) end
	end
	try("hold", function() wi:Invoke("Pause", uid, true) end)
	try("stop", function() rooms:Invoke("Stop", uid) end)
	try("unseat", unseat)
	try("lounge", function() teleport(LOUNGE) end)
	try("resets", function()
		wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
		test:Invoke("ResetHints", uid); test:Invoke("ResetSessions", uid)
	end)
	try("rooms Reset", function() rooms:Invoke("Reset", uid) end)
	try("tour", function() restoreTour(parseTour(p:GetAttribute("_T111Tour"))) end)
	try("Quiet off", function() ph:Invoke("Quiet", uid, false) end)
	local restored
	try("ProfileRestore", function() restored = test:Invoke("ProfileRestore", uid) end)
	try("Publish", function() career:Invoke("Publish", uid) end)
	p:SetAttribute("_T111Tour", nil)
	return restored, steps
end

local function run()
	-- t111a's note first: without it t111a failed and already put the profile back, so nothing here may stage a delivery
	-- that no ProfileRestore would take back
	assert(parseTour(p:GetAttribute("_T111Tour")) ~= nil, "no _T111Tour note on the player: t111a failed (and put everything back), so t111d is not staged")
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	unseat()
	assert(test:Invoke("ResetSessions", uid) == true, "ResetSessions failed")
	assert(test:Invoke("SetActiveRequest", uid, "j1") == true, "SetActiveRequest(j1) failed")
	assert(call("WakeUp") == true, "WakeUp returned false")
	local st = call("Station", "bedroom")
	assert(typeof(st) == "Instance", "the hook's Station(bedroom) answered " .. tostring(st))
	local bed = st:FindFirstAncestor("Room_bedroom")
	assert(bed, "the bedroom's laptop is not inside a Room_bedroom Model: " .. st:GetFullName())
	teleport((bed:GetPivot() * CFrame.new(BED_STAND)).Position + Vector3.new(0, 3, 0))
	local reach = DAWCfg.CloseDistance + 4
	local d = (root().Position - st.Position).Magnitude
	assert(d <= reach, string.format("the bedroom stand spot is %.1f studs from the laptop, past StationOf's reach %d", d, reach))
	local so = call("StationOf")
	assert(type(so) == "table" and so.inst == st and so.room == bed, "StationOf at the bedroom stand spot is " .. show(so) .. ", want the bedroom laptop")
	local b = call("Booth", st)
	assert(b == false, "the hook's Booth of the bedroom laptop answered " .. show(b) .. ", want false (no booth)" .. RED)
	return string.format("T111C PLAY OK\nsessions reset, j1 active; the player at the bedroom stand spot (%.1f studs from the laptop; StationOf the bedroom's), Booth false", d)
end

local ok, msg = pcall(run)
if not ok then
	local restored, steps = putBack()
	error(msg .. (#steps > 0 and ("\n(the put-back also hit: " .. table.concat(steps, "; ") .. ")") or "")
		.. (restored ~= true and "\n(ProfileRestore answered " .. tostring(restored) .. ")" or ""), 0)
end
return msg
