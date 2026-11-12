-- Server, during play (the Day One plan, Task 4: Day One on screen), stage for t123b. Through the Studio hooks, held
-- (WalkInsPaused true: the join path starts no chain). First, before anything changes, the test hook's ProfileMark
-- notes the profile (money, XP and level, gear, the gate logs, the tour, the hints, the sessions) and the tour's steps
-- go into the player attribute _T123Tour ("<got ids>|done|skipped"): t123e, the run's tail, puts both back. Then the
-- file's fresh(): unseated in the lounge (24, 3, 0), Quiet on (kept on through t123d; t123e turns it off), the phone,
-- WalkIns, Career and Life reset, no hint seen, the rooms hook's Reset (a slot claimed, the plot rebuilt), the DayOne
-- hook's Reset, ResetTour and ResetSessions. Then WakeUp: the player at their bedroom's Spawn (PlaceOf <slot>/bedroom,
-- InPlot and PlotSlot the slot), the tour reset (nothing got, not done). Then the DayOne hook's Start answers "dayone"
-- and sends card 1 at once: the hook's Open names it, Sent holds its "arrive" (source "dayone", header DAY ONE, walk
-- SKIP, three choices) and DayOneBusy is true. It is left open, with the tour reset and the player in the bedroom, for
-- t123b. Under deferred signals the resets' handlers run a frame late, so reads after them settle first.
-- On any error: unseated in the lounge, then the DayOne Reset; the note and the profile mark stay for t123e, which puts
-- them back; the error is rethrown.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local d1 = SOK:WaitForChild("_StudioDayOneHook", 5); assert(d1, "no _StudioDayOneHook (is Systems/DayOne synced and started?)")
local rooms = SOK:WaitForChild("_StudioRoomsHook", 5); assert(rooms, "no _StudioRoomsHook (is Systems/Rooms synced and started?)")
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local D = require(RS.OK.Data.DayOne)
local LOUNGE = Vector3.new(24, 3, 0)
local STEPS = { "open", "take", "deliver", "monitors", "gear" } -- Tour.Steps' ids in order (t120 pins them)
local T0 = os.clock()
local out = {}

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function root() local c = p.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = p.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function teleport(pos) -- checked, and tried once more if the client's position won
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
local function call(cmd, a, b, c) return d1:Invoke(cmd, uid, a, b, c) end
local function tourNow()
	local pr = test:Invoke("GetProfile", uid)
	local t = type(pr) == "table" and type(pr.tour) == "table" and pr.tour or {}
	return { done = t.done == true, skipped = t.skipped == true, got = type(t.got) == "table" and t.got or {} }
end
local function tourNote(t) -- "<got ids>|done|skipped" (t123e reads it back)
	local ids = {}
	for _, id in ipairs(STEPS) do if t.got[id] then table.insert(ids, id) end end
	return table.concat(ids, ",") .. "|" .. (t.done and "done" or "") .. "|" .. (t.skipped and "skipped" or "")
end
local function placeNow()
	local pl = rooms:Invoke("PlaceOf", uid)
	return type(pl) == "table" and (tostring(pl.slot) .. "/" .. tostring(pl.kind)) or tostring(pl)
end
local function kinds(list)
	local t = {}
	for _, e in ipairs(list) do table.insert(t, tostring(e.kind) .. (e.id and (":" .. tostring(e.id)) or "")) end
	return #t > 0 and table.concat(t, ", ") or "nothing"
end

local function fresh()
	unseat()
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, "fresh: Quiet(true) failed")
	assert(ph:Invoke("Reset", uid) == true, "fresh: phone Reset failed")
	assert(wi:Invoke("Reset", uid) == true, "fresh: WalkIns Reset failed")
	assert(career:Invoke("Reset", uid) == true, "fresh: Career Reset failed")
	assert(life:Invoke("Reset", uid) == true, "fresh: Life Reset failed")
	assert(test:Invoke("ResetHints", uid) == true, "fresh: ResetHints failed")
	assert(rooms:Invoke("Reset", uid) == true, "fresh: the rooms hook's Reset failed (no slot, or the plot did not build)")
	assert(call("Reset") == true, "fresh: the DayOne hook's Reset answered something else than true")
	assert(test:Invoke("ResetTour", uid) == true, "fresh: ResetTour failed")
	assert(test:Invoke("ResetSessions", uid) == true, "fresh: ResetSessions failed")
end

local function run()
	-- the profile and the tour as found, before anything changes (t123e puts them back)
	local mk = test:Invoke("ProfileMark", uid)
	assert(mk == true, "the test hook's ProfileMark answered " .. tostring(mk) .. ", want true (sync ServerScriptService/OK/Main: D1-T3 fix 1)")
	local before = tourNow()
	p:SetAttribute("_T123Tour", tourNote(before))
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh()
	local info = rooms:Invoke("Plot", uid)
	local k = type(info) == "table" and info.slot
	assert(k, "the rooms hook's Plot answered " .. tostring(info) .. ", want the player's slot")

	-- the wake-up: in the bedroom, the tour reset
	unseat()
	assert(rooms:Invoke("WakeUp", uid) == true, "WakeUp returned false")
	task.wait(0.3) -- the resets' late handlers (Tour.Changed "reset": no chain) run
	local want = k .. "/bedroom"
	waitFor(function() return placeNow() == want end, 3)
	assert(placeNow() == want, "after WakeUp PlaceOf is " .. placeNow() .. ", want " .. want)
	assert(rooms:Invoke("InPlot", uid) == k and p:GetAttribute("InPlot") == k and p:GetAttribute("PlotSlot") == k,
		"in the bedroom InPlot is " .. tostring(p:GetAttribute("InPlot")) .. " and PlotSlot " .. tostring(p:GetAttribute("PlotSlot")) .. ", want both " .. k)
	local t = tourNow()
	assert(not t.done and next(t.got) == nil, "the tour after ResetTour is " .. tourNote(t) .. ", want nothing got")
	local s0 = call("State")
	assert(type(s0) == "table" and not s0.running and s0.card == nil, "after the DayOne Reset a chain runs (card " .. tostring(type(s0) == "table" and s0.card and s0.card.id) .. "), want none")
	call("Sent") -- drained
	table.insert(out, string.format("profile marked; tour noted '%s'; fresh; woke up in Plot_%02d's bedroom (InPlot %d), tour reset", tourNote(before), k, k))

	-- card 1, sent at once
	local n = call("Start")
	assert(n == "dayone", "Start answered " .. tostring(n) .. ", want dayone")
	local open = call("Open")
	assert(type(open) == "table" and open.id == "dayone", "the hook's Open answers " .. tostring(type(open) == "table" and open.id or open) .. " after Start, want dayone")
	local l = call("Sent")
	local arr
	for _, e in ipairs(type(l) == "table" and l or {}) do if e.kind == "arrive" and e.id == "dayone" then arr = e end end
	assert(arr and type(arr.payload) == "table" and type(arr.payload.card) == "table", "Start sent " .. kinds(type(l) == "table" and l or {}) .. ", want arrive:dayone")
	local pl = arr.payload
	assert(pl.source == "dayone" and pl.header == D.Header and pl.walk == D.Skip, "card 1's payload has source " .. tostring(pl.source) .. ", header "
		.. tostring(pl.header) .. ", walk " .. tostring(pl.walk) .. "; want dayone, " .. D.Header .. ", " .. D.Skip)
	assert(pl.card.id == "day1_dayone" and type(pl.card.choices) == "table" and #pl.card.choices == 3, "card 1 is " .. tostring(pl.card.id) .. " with "
		.. tostring(type(pl.card.choices) == "table" and #pl.card.choices) .. " choices, want day1_dayone with 3")
	assert(arr.token == open.token, "the arrive's token " .. tostring(arr.token) .. " is not the open card's " .. tostring(open.token))
	assert(waitFor(function() return p:GetAttribute("DayOneBusy") == true end, 2), "DayOneBusy is " .. tostring(p:GetAttribute("DayOneBusy")) .. " with card 1 open, want true")
	table.insert(out, "Start: card 1 (day1_dayone, DAY ONE, SKIP, 3 choices) sent and open, DayOneBusy true; left open for t123b")
	return table.concat(out, "\n")
end

local ok, msg = pcall(run)
if not ok then
	pcall(unseat)
	pcall(teleport, LOUNGE)
	pcall(function() rooms:Invoke("InPlot", uid) end) -- InPlot read now, not at the 1 s loop
	pcall(function() d1:Invoke("Reset", uid) end) -- the last step (ruling F6)
	error(msg, 0)
end
return string.format("T123A PLAY OK (%.1f s)\n", os.clock() - T0) .. msg
