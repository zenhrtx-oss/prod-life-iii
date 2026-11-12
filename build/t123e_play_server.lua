-- Server, during play (the Day One plan, Task 4; preflight F7), the tail of t123a-d: puts back what they staged, so the
-- files after it (t124*, t12_, then t17b, whose first check wants the hub PC outlined) find the player in the lounge
-- with the tour and the profile as t123a found them. One Play session runs the whole sorted list, so this runs even when
-- an earlier t123 file failed. In t122a's cleanup order:
--   the hold on (WalkInsPaused true); the DayOne Reset (no chain sees what follows); any room play stopped; unseated and
--   moved to the lounge (24, 3, 0), where the beat maker and any panel close; InPlot read now (the rooms hook's InPlot:
--   presence, not the 1 s loop), so TourUI outlines the hub's target again; WalkIns, the phone, Career and Life reset, no
--   hint seen, ResetSessions; ResetTour, then the steps t123a noted in _T123Tour done again (so the client's pill gets
--   the restored tour); Quiet off; a final DayOne Reset (ruling F6); then the test hook's ProfileRestore (t123a's
--   ProfileMark: money, XP and level, gear, the gate logs, the tour, the hints, the sessions) and the career hook's
--   Publish. Then _T123Tour is cleared.
-- Checks, after all of that: t123a's note was there (else nothing could be put back: did t123a fail before it?),
-- ProfileRestore answered true, DayOneBusy nil and no chain, InPlot 0 and the player within 2 studs of the lounge, and
-- the tour as noted. Marker "T123E PLAY OK".
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
local LOUNGE = Vector3.new(24, 3, 0)
local STEPS = { "open", "take", "deliver", "monitors", "gear" } -- Tour.Steps' ids in order (t120 pins them)
local T0 = os.clock()

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
local function tourNow()
	local pr = test:Invoke("GetProfile", uid)
	local t = type(pr) == "table" and type(pr.tour) == "table" and pr.tour or {}
	return { done = t.done == true, skipped = t.skipped == true, got = type(t.got) == "table" and t.got or {} }
end
local function tourNote(t) -- as t123a writes it: "<got ids>|done|skipped"
	local ids = {}
	for _, id in ipairs(STEPS) do if t.got[id] then table.insert(ids, id) end end
	return table.concat(ids, ",") .. "|" .. (t.done and "done" or "") .. "|" .. (t.skipped and "skipped" or "")
end
-- t123a's note read back: { done, skipped, got = { [id] = true } }, or nil
local function parse(note)
	if type(note) ~= "string" then return nil end
	local ids, done, skipped = string.match(note, "^([^|]*)|([^|]*)|([^|]*)$")
	if not ids then return nil end
	local got = {}
	for id in string.gmatch(ids, "[^,]+") do got[id] = true end
	return { done = done == "done", skipped = skipped == "skipped", got = got }
end

local note = p:GetAttribute("_T123Tour")
local before = parse(note)
local steps = {}
local function try(label, fn) -- every step runs, whatever failed before it; failures are reported at the end
	local ok, err = pcall(fn)
	if not ok then table.insert(steps, label .. ": " .. tostring(err)) end
end
try("hold", function() RS.OK:SetAttribute("WalkInsPaused", true) end)
try("DayOne Reset", function() d1:Invoke("Reset", uid) end) -- first: no chain sees the tour restored
pcall(function() rooms:Invoke("Stop", uid) end) -- any room play of the player's (none is fine)
try("unseat", unseat)
try("lounge", function() teleport(LOUNGE) end) -- the beat maker and any panel close out here
local inPlot
try("InPlot", function() inPlot = rooms:Invoke("InPlot", uid) end) -- presence now, not at the 1 s loop
try("resets", function()
	wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
	test:Invoke("ResetHints", uid); test:Invoke("ResetSessions", uid)
end)
try("tour", function()
	test:Invoke("ResetTour", uid)
	if before then
		for _, id in ipairs(STEPS) do
			if before.done or before.got[id] then test:Invoke("TourAdvance", uid, id) end
		end
	end
end)
try("Quiet off", function() ph:Invoke("Quiet", uid, false) end)
task.wait(0.3) -- the restore's late handlers run (no chain: nothing)
try("final DayOne Reset", function() d1:Invoke("Reset", uid) end) -- the last Day One step (F6)
local restored
try("ProfileRestore", function() restored = test:Invoke("ProfileRestore", uid) end)
try("Publish", function() career:Invoke("Publish", uid) end) -- Career_Get's cached Money dropped, the career attributes sent again
p:SetAttribute("_T123Tour", nil)

-- the checks
assert(before ~= nil, "no _T123Tour note on the player (t123a writes it first, with its ProfileMark: did t123a fail before it?); "
	.. "the lounge and the resets are done, but the tour and the profile could not be put back")
assert(#steps == 0, "the put-back hit " .. #steps .. " error(s): " .. table.concat(steps, "; "))
assert(restored == true, "the test hook's ProfileRestore answered " .. tostring(restored) .. ", want true (t123a's ProfileMark)")
local busyLeft = p:GetAttribute("DayOneBusy")
assert(busyLeft == nil, "DayOneBusy is " .. tostring(busyLeft) .. " after the final DayOne Reset, want nil")
local s = d1:Invoke("State", uid)
assert(type(s) == "table" and not s.running and s.card == nil, "a Day One chain still runs after the put-back (card " .. tostring(type(s) == "table" and s.card and s.card.id) .. ")")
assert(inPlot == 0 and p:GetAttribute("InPlot") == 0, "InPlot is " .. tostring(p:GetAttribute("InPlot")) .. " (the hook read " .. tostring(inPlot) .. ") in the lounge, want 0")
local r = root()
assert(r and flat(r.Position - LOUNGE) < 2, "the player is at " .. tostring(r and r.Position) .. ", want the lounge " .. tostring(LOUNGE))
local after = tourNow()
local want = tourNote(before)
assert(tourNote(after) == want, "the tour is '" .. tourNote(after) .. "' after the put-back, want '" .. want .. "' as t123a noted it")
return string.format("T123E PLAY OK (%.1f s): the player in the lounge (InPlot 0), no Day One chain, the tour '%s' and the profile as t123a found them",
	os.clock() - T0, want)
