-- Server, during play (the Day One plan, Task 5: coach marks and the first delivery in your bedroom), after t124b played
-- the whole first minute from the client (Make it now, BOUNCE made yours and delivered at the bedroom laptop for 3 stars,
-- On my speakers, Save it). The server's side of it, then the tail of t124a-c: it puts back what they staged, so the files
-- after it (t12_, then t17b, whose first check wants the hub PC outlined; preflight F7) find the player in the lounge with
-- the tour and the profile as t124a found them. One Play session runs the whole sorted list, so this runs even when t124b
-- failed; its checks then fail, and the put-back still runs in full.
-- Checks (the hold stays on, so the timer card 3 armed hasn't counted down):
-- (1) the tour done, not skipped; d1 unpaid with no haggle (Make it now: the DayOne hook's State, d1 nil or paid false);
--     the money exactly t124a's note (_T124Money) + the starter brief's 3-star pay (reward.cred x 1.5: $600; t124a
--     cleared today's Delivery counts, and card 2's room play, the tour's reward and Save it pay no money); DayOneBusy
--     false and the chain ended.
-- (2) the walk-in timer within Config.DayOne.VisitAfter (WalkIns.ArmFirst at the chain's end); in the bedroom
--     (PlaceOf <slot>/bedroom) a Poke starts a visit whose Data/WalkIns card has first = true.
-- The put-back, every step tried whatever failed before it (t123e's order): the hold on; the DayOne Reset (no chain sees
-- what follows); the visit expired (WalkIns' hook Expire) and none pending; any room play stopped; unseated and moved to
-- the lounge (24, 3, 0), where the beat maker and any panel close; InPlot read now (the rooms hook's InPlot), so TourUI
-- outlines the hub's target again; WalkIns, the phone, Career and Life reset, no hint seen, ResetSessions; ResetTour, then
-- the steps t124a noted in _T124Tour done again (so the client's pill gets the restored tour); Quiet off; a final
-- DayOne Reset (ruling F6); then the test hook's ProfileRestore (t124a's ProfileMark: money, XP and level, gear, the gate
-- logs, the tour, the hints, the sessions; this replaces the plan's GrantCred / TakeCred of the difference) and the career
-- hook's Publish. Then _T124Tour and _T124Money are cleared. After all of that: t124a's note was there, ProfileRestore
-- answered true, DayOneBusy nil and no chain, no visit pending, InPlot 0 and the player within 2 studs of the lounge, and
-- the tour as noted. The first failure (the checks', else the put-back's) is rethrown. Marker "T124C PLAY OK".
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
local Config = require(RS.OK.Config)
local C = Config.DayOne
local Rules = require(RS.OK.Modules.DayOneRules)
local Artists = require(RS.OK.Data.Artists)
local Content = require(RS.OK.Data.WalkIns)
local Format = require(RS.OK.Modules.Format)
local LOUNGE = Vector3.new(24, 3, 0)
local STEPS = { "open", "take", "deliver", "monitors", "gear" } -- Tour.Steps' ids in order (t120 pins them)
local STARTER = Rules.Starter(Artists.Briefs)
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
local function prof() return test:Invoke("GetProfile", uid) end
local function money() local pr = prof(); return tonumber(type(pr) == "table" and pr.cred) or 0 end
local function tourNow()
	local pr = prof()
	local t = type(pr) == "table" and type(pr.tour) == "table" and pr.tour or {}
	return { done = t.done == true, skipped = t.skipped == true, got = type(t.got) == "table" and t.got or {} }
end
local function tourNote(t) -- as t124a writes it: "<got ids>|done|skipped"
	local ids = {}
	for _, id in ipairs(STEPS) do if t.got[id] then table.insert(ids, id) end end
	return table.concat(ids, ",") .. "|" .. (t.done and "done" or "") .. "|" .. (t.skipped and "skipped" or "")
end
-- t124a's note read back: { done, skipped, got = { [id] = true } }, or nil
local function parse(note)
	if type(note) ~= "string" then return nil end
	local ids, done, skipped = string.match(note, "^([^|]*)|([^|]*)|([^|]*)$")
	if not ids then return nil end
	local got = {}
	for id in string.gmatch(ids, "[^,]+") do got[id] = true end
	return { done = done == "done", skipped = skipped == "skipped", got = got }
end
local function placeNow()
	local pl = rooms:Invoke("PlaceOf", uid)
	return type(pl) == "table" and (tostring(pl.slot) .. "/" .. tostring(pl.kind)) or tostring(pl)
end

local note = p:GetAttribute("_T124Tour")
local before = parse(note)
local noted = p:GetAttribute("_T124Money")

local function run()
	assert(STARTER and STARTER.reward, "Data/Artists has no single starter brief with a reward")
	assert(type(noted) == "number", "no _T124Money note on the player (t124a writes it before Start: did t124a fail?)")
	local pay = math.floor(STARTER.reward.cred * 1.5 + 0.5) -- Contracts.Deliver's first delivery at 3 stars
	-- 1. the tour, d1 and the money
	local t = tourNow()
	assert(t.done and not t.skipped, "the tour is '" .. tourNote(t) .. "', want done and not skipped (t124b's card 3 Save it: Tour.Finish; did t124b fail?)")
	local s = call("State")
	assert(type(s) == "table", "the DayOne hook's State answered " .. tostring(s) .. ", want a table")
	local d = s.d1
	assert(not (d and d.paid) and not (d and d.haggle), "d1 is paid " .. tostring(d and d.paid) .. ", haggle " .. tostring(d and d.haggle)
		.. "; want unpaid with no haggle (Make it now)")
	local want = noted + pay
	waitFor(function() return money() == want end, 2)
	local got = money()
	assert(got == want, string.format("money is %s, want %s (t124a's %s + %s, %s's 3-star pay; %+d off)", Format.Money(got), Format.Money(want),
		Format.Money(noted), Format.Money(pay), STARTER.id, got - want))
	assert(waitFor(function() return p:GetAttribute("DayOneBusy") == false end, 2), "DayOneBusy is " .. tostring(p:GetAttribute("DayOneBusy")) .. " after the tour, want false")
	assert(not s.running and s.card == nil and s.pending == nil, "the chain still runs after the tour (card " .. tostring(s.card and s.card.id) .. ", pending "
		.. tostring(s.pending and s.pending.id) .. ")")
	table.insert(out, string.format("1 the tour done; d1 unpaid, no haggle; money %s = %s + %s; DayOneBusy false, the chain ended", Format.Money(got), Format.Money(noted), Format.Money(pay)))

	-- 2. the first visitor
	local rem = wi:Invoke("GetRemaining", uid)
	assert(type(rem) == "number" and rem >= C.VisitAfter[1] and rem <= C.VisitAfter[2], "the walk-in timer is " .. tostring(rem)
		.. " after Day One, want " .. C.VisitAfter[1] .. ".." .. C.VisitAfter[2] .. " (WalkIns.ArmFirst at the chain's end)")
	local info = rooms:Invoke("Plot", uid)
	local k = type(info) == "table" and info.slot
	assert(k, "the rooms hook's Plot answered " .. tostring(info) .. ", want the player's slot")
	local where = k .. "/bedroom"
	waitFor(function() return placeNow() == where end, 3)
	assert(placeNow() == where, "PlaceOf is " .. placeNow() .. " before the Poke, want " .. where)
	local poke = wi:Invoke("Poke", uid)
	assert(poke == true, "a Poke in the bedroom after Day One answered " .. tostring(poke) .. ", want a visit")
	local v = wi:Invoke("Pending", uid)
	local card = v and Content.CardById[v.id]
	assert(card and card.first == true, "the first visit is " .. tostring(v and v.id) .. ", want a Data/WalkIns card with first = true")
	table.insert(out, string.format("2 the walk-in timer %s (VisitAfter %d..%d); Poke in %s -> %s (first)", tostring(rem), C.VisitAfter[1], C.VisitAfter[2], placeNow(), v.id))
	return table.concat(out, "\n")
end

local ok, msg = pcall(run)

-- the put-back, every step tried (t123e's order)
local steps = {}
local function try(label, fn)
	local good, err = pcall(fn)
	if not good then table.insert(steps, label .. ": " .. tostring(err)) end
end
try("hold", function() RS.OK:SetAttribute("WalkInsPaused", true) end)
try("DayOne Reset", function() call("Reset") end) -- first: no chain sees the tour restored
try("Expire", function() if wi:Invoke("Pending", uid) ~= nil then wi:Invoke("Expire", uid) end end)
pcall(function() rooms:Invoke("Stop", uid) end) -- the room play card 2 started (none is fine)
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
try("final DayOne Reset", function() call("Reset") end) -- the last Day One step (F6)
local restored
try("ProfileRestore", function() restored = test:Invoke("ProfileRestore", uid) end)
try("Publish", function() career:Invoke("Publish", uid) end) -- Career_Get's cached Money dropped, the career attributes sent again
p:SetAttribute("_T124Tour", nil)
p:SetAttribute("_T124Money", nil)
if not ok then error(msg .. (#steps > 0 and ("\n(the put-back also hit: " .. table.concat(steps, "; ") .. ")") or ""), 0) end

-- the put-back's checks
assert(before ~= nil, "no _T124Tour note on the player (t124a writes it first, with its ProfileMark: did t124a fail before it?); "
	.. "the lounge and the resets are done, but the tour and the profile could not be put back")
assert(#steps == 0, "the put-back hit " .. #steps .. " error(s): " .. table.concat(steps, "; "))
assert(restored == true, "the test hook's ProfileRestore answered " .. tostring(restored) .. ", want true (t124a's ProfileMark)")
local busyLeft = p:GetAttribute("DayOneBusy")
assert(busyLeft == nil, "DayOneBusy is " .. tostring(busyLeft) .. " after the final DayOne Reset, want nil")
local s = call("State")
assert(type(s) == "table" and not s.running and s.card == nil, "a Day One chain still runs after the put-back (card " .. tostring(type(s) == "table" and s.card and s.card.id) .. ")")
assert(wi:Invoke("Pending", uid) == nil, "a walk-in is still pending after Expire and the WalkIns Reset")
assert(inPlot == 0 and p:GetAttribute("InPlot") == 0, "InPlot is " .. tostring(p:GetAttribute("InPlot")) .. " (the hook read " .. tostring(inPlot) .. ") in the lounge, want 0")
local r = root()
assert(r and flat(r.Position - LOUNGE) < 2, "the player is at " .. tostring(r and r.Position) .. ", want the lounge " .. tostring(LOUNGE))
local after = tourNow()
local wantTour = tourNote(before)
assert(tourNote(after) == wantTour, "the tour is '" .. tourNote(after) .. "' after the put-back, want '" .. wantTour .. "' as t124a noted it")
return string.format("T124C PLAY OK (%.1f s)\n", os.clock() - T0) .. msg
	.. string.format("\nput back: the player in the lounge (InPlot 0), no Day One chain, no visit, the tour '%s' and the profile as t124a found them", wantTour)
