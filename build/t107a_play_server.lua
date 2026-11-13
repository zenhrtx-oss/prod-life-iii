-- Server, during play (the Your Rooms plan, Task 8: the story hands you upgrades), through the Studio hooks. Three existing
-- story outcomes give the desk monitors (spk_monitors) free (Data/WalkIns' outcome `gift`; rooms copy 5): mom_busy choice 1
-- (a walk-in: "Give her the full tour."), rep_headphones choice 1 (a walk-in: "Sign it. $300.") and mishap_keys choice 2 (a
-- phone card, the STUDIO app: "Ask around the building."). Systems/WalkIns' and Systems/Phone's apply call WalkIns.Gift:
-- Gear.Grant, and when it granted, the toast "NEW GEAR: DESK MONITORS" (the gear's name upper-cased). The body runs held
-- (WalkInsPaused true) from the file's own fresh(): unseated in the lounge, Quiet on, the phone, WalkIns, Career and Life
-- reset, no hint seen, the rooms hook's Reset (a slot claimed, the plot rebuilt).
-- Nothing here calls a system module of its own: a test's require may not be the live module, so (as t106a, t122a) the
-- state is read through the hooks. Ownership is the profile's gear (the test hook's GetProfile, a copy: read only) and the
-- player's Gear attribute; the gift path on its own is the walk-in hook's Gift(uid, gearId) (WalkIns.Gift: Gear.Grant and its
-- toast); the toast is read from the walk-in hook's Sent, where Studio logs it as { kind = "toast", payload = { text } }
-- (WalkIns.Gift does, for a phone gift too: the one helper sends both), the way Systems/Rooms logs its own toasts (a server
-- test can't see a FireClient). Before each route the gear is reset (ResetGear: the gift starts unowned), the bedroom holds
-- no speaker models and the WalkIn cred count is cleared (the career hook's ResetCredCount) so the deal's $300 pays whole.
-- (0) the content and the config: the three outcomes carry gift "spk_monitors" (live Data/WalkIns), Config.Gear has the row
--     (the monitors, kind speakers, with needs), and its name upper-cased is the toast ("NEW GEAR: DESK MONITORS", copy
--     5.7). The tour is reset (a Bought would finish its "gear" step, which Tour listens for).
-- (1) the gift path on its own (the hook's Gift): this career has fewer followers than the row's needs (so the gift skips
--     the rack's gates); an unknown id and a non-string answer false, own nothing and send no toast; "spk_monitors" answers
--     true: owned, the Gear attribute lists it, exactly one toast "NEW GEAR: DESK MONITORS", no money moved; a second
--     answers false with no toast and changes nothing; the bedroom's speakers rebuild to tier 2 (RoomSpeaker_L and _R,
--     exactly two) and the rooms hook's SpeakerTier reads 2.
-- (2) each route forced to its gift outcome (SetRng; walk-in Spawn + Choose, phone Pop / Open / Choose), from ResetGear with
--     no speaker models: the outcome lands (its key), the monitors are owned, exactly one toast "NEW GEAR: DESK MONITORS" was
--     sent, the money moved by the outcome's own pay only (0, $300, 0: the gift moves none), the Gear attribute lists the
--     monitors, SpeakerTier reads 2 and the bedroom's speakers rebuild to tier 2 (exactly two models). Then the same outcome
--     again with the monitors already yours: it lands again, no second toast, still owned, still two tier 2 models, money by
--     the outcome's own pay again.
-- (3) a gift is only on the good side: mishap_keys' choice 2 forced to its bad roll ("missing") owns nothing, sends no toast.
-- (4) no gift was a purchase: the tour's "gear" step (finished by Gear.Bought, which Tour listens for) is still undone.
-- On any error, and after success: unseated in the lounge, the rooms Reset, everything else reset (hold on, Quiet off), then
-- the test hook's ProfileRestore (its ProfileMark is run()'s first step: money, XP and level, gear, the gate logs, the tour,
-- the hints and the sessions: the gear, the money and the tour are put back exactly) and the career hook's Publish; the
-- error is rethrown. After a clean cleanup the gear is checked against what it was. The whole run takes under 90 s (one
-- plot build and about 4 walk-in arrivals); the elapsed time is printed.
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
local Config = require(RS.OK.Config) -- data only
local Content = require(RS.OK.Data.WalkIns) -- data only
local LOUNGE = Vector3.new(24, 3, 0)
local GEAR_ID = "spk_monitors"
local RED = " (before the R-T8 sync of Data/WalkIns, Systems/Gear, Systems/WalkIns and Systems/Phone: the expected red)"
local out = {}
local T0 = os.clock()
local gearBefore -- noted first thing in run(); checked after the cleanup

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
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
local function listHas(attr, id) return ("," .. tostring(p:GetAttribute(attr) or "") .. ","):find("," .. id .. ",", 1, true) ~= nil end
local function stats() return career:Invoke("Get", uid) end
local function money() return stats().money end
local function pending() return wi:Invoke("Pending", uid) end
local function arrived() local r = pending(); return r ~= nil and r.arrived == true end
-- the profile's gear as ids (GetProfile is a copy through the hook: read only)
local function ownedGear()
	local prof = test:Invoke("GetProfile", uid)
	local ids = {}
	local g = type(prof) == "table" and type(prof.gear) == "table" and prof.gear or {}
	for id, on in pairs(g) do if on == true then table.insert(ids, id) end end
	table.sort(ids)
	return ids
end
local function owns() return table.find(ownedGear(), GEAR_ID) ~= nil end
local function tourGot()
	local prof = test:Invoke("GetProfile", uid)
	local t = type(prof) == "table" and type(prof.tour) == "table" and prof.tour or {}
	return type(t.got) == "table" and t.got or {}
end
-- the bedroom's speaker models: how many (RoomSpeaker_L / _R) and their tiers as text ("2,2")
local function bedroom()
	local info = call("Plot")
	local k = type(info) == "table" and info.slot
	local folder = workspace:FindFirstChild("OK_Plots")
	local plot = k and folder and folder:FindFirstChild(string.format("Plot_%02d", k))
	return plot and plot:FindFirstChild("Room_bedroom")
end
local function speakers()
	local bed = bedroom()
	local n, tiers = 0, {}
	if bed then
		for _, c in ipairs(bed:GetChildren()) do
			if c.Name == "RoomSpeaker_L" or c.Name == "RoomSpeaker_R" then n += 1; table.insert(tiers, tostring(c:GetAttribute("Tier"))) end
		end
	end
	table.sort(tiers)
	return n, table.concat(tiers, ",")
end
local function noSpeakers() local n = speakers(); return n == 0 end
local function tier2() local n, t = speakers(); return n == 2 and t == "2,2" end
-- the NEW GEAR toasts the walk-in hook logged since its last Sent (the read drains it; other sends are dropped)
local function toasts()
	local list = {}
	for _, e in ipairs(wi:Invoke("Sent", uid)) do
		if e.kind == "toast" then table.insert(list, type(e.payload) == "table" and e.payload.text or "?") end
	end
	return list
end
local function say(list) return #list == 0 and "none" or ("'" .. table.concat(list, "', '") .. "'") end
-- the file's own fresh(): unseated in the lounge, Quiet on, the phone, WalkIns, Career and Life reset, no hint seen, the rooms hook's Reset
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
-- the gift starts unowned: no visit or pop in flight, the gear reset, the bedroom's speakers gone, the deal's cred count free
local function unowned(label)
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed") -- the phone's reset runs with it
	assert(test:Invoke("ResetGear", uid) == true, label .. ": ResetGear failed")
	assert(not owns() and not listHas("Gear", GEAR_ID), label .. ": " .. GEAR_ID .. " is still owned after ResetGear")
	assert(waitFor(noSpeakers, 5), label .. ": the bedroom still holds speaker models 5 s after ResetGear (" .. select(2, speakers()) .. ")")
	assert(career:Invoke("ResetCredCount", uid, "WalkIn") == true, label .. ": the career hook's ResetCredCount(WalkIn) failed")
	wi:Invoke("Sent", uid) -- drained: a toast read after this is this step's
end

-- one route to its gift outcome: the result of the choice made, forced. A walk-in Spawns and walks in; a phone card is popped
-- and opened (Quiet is on: no pop or result reaches the live client). `roll` is the phone roll's SetRng value (1 = good, 100 = bad)
local function play(r, label, roll)
	wi:Invoke("Sent", uid) -- drained: the toast read after this is this choice's
	local result
	if r.phone then
		local token = ph:Invoke("Pop", uid, r.id)
		assert(type(token) == "string", label .. ": Pop(" .. r.id .. ") sent nothing")
		assert(ph:Invoke("Open", uid, token) == true, label .. ": the DM did not open")
		assert(ph:Invoke("SetRng", uid, { roll or 1 }) == true, label .. ": the phone's SetRng failed") -- just before the roll it forces
		local res = ph:Invoke("Choose", uid, token, r.choice)
		assert(res and res.ok == true and type(res.result) == "table", label .. ": phone Choose " .. r.choice .. " refused: " .. tostring(res and res.reason))
		result = res.result
	else
		assert(wi:Invoke("Spawn", uid, r.id) == true, label .. ": Spawn(" .. r.id .. ") refused (is the player in the hub?)")
		assert(waitFor(arrived, 15), label .. ": " .. r.id .. " did not arrive within 15 s")
		local rec = pending()
		assert(rec and rec.id == r.id, label .. ": the visit in flight is " .. tostring(rec and rec.id) .. ", want " .. r.id)
		local res = wi:Invoke("Choose", uid, rec.token, r.choice)
		assert(res and res.ok == true and type(res.result) == "table", label .. ": Choose " .. r.choice .. " refused: " .. tostring(res and res.reason))
		result = res.result
	end
	return result
end
-- the room's speakers at tier 2 (exactly two models), waited for
local function assertTier2(label)
	assert(call("SpeakerTier") == 2, label .. ": the rooms hook's SpeakerTier answered " .. tostring(call("SpeakerTier")) .. ", want 2")
	local got = waitFor(tier2, 5)
	local n, tiers = speakers()
	assert(got, label .. ": the bedroom's speakers did not rebuild to tier 2 within 5 s (" .. n .. " models, tiers '" .. tiers .. "')")
end
-- the gift landed: its outcome's key, owned, exactly one toast, the money moved by the outcome's own pay only, the Gear attribute
-- and the room's speakers at tier 2
local function assertGranted(r, result, m0, label)
	assert(result.key == r.key, label .. ": the outcome landed '" .. tostring(result.key) .. "', want '" .. r.key .. "'")
	assert(owns(), label .. ": " .. GEAR_ID .. " is not owned after the gift outcome" .. RED)
	local list = toasts()
	assert(#list == 1 and list[1] == r.toast, label .. ": the toasts sent were " .. say(list) .. ", want exactly '" .. r.toast .. "'" .. RED)
	local credCount = (((test:Invoke("GetProfile", uid) or {}).credLog or {}).count or {}).WalkIn
	assert(money() - m0 == r.pay, string.format("%s: money moved %+d, want the outcome's own %+d (the gift moves none; WalkIn cred count %s of %d)",
		label, money() - m0, r.pay, tostring(credCount), Config.Cred.Sources.WalkIn.dailyMax))
	assert(listHas("Gear", GEAR_ID), label .. ": the Gear attribute reads '" .. tostring(p:GetAttribute("Gear")) .. "', want it to list " .. GEAR_ID)
	assertTier2(label)
end

local function run()
	local mk = test:Invoke("ProfileMark", uid) -- first, before anything changes (the cleanup's ProfileRestore)
	assert(mk == true, "the test hook's ProfileMark answered " .. tostring(mk) .. ", want true (sync ServerScriptService/OK/Main: D1-T3 fix 1)")
	gearBefore = ownedGear()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")

	-- 0. the content and the config
	local row
	for _, it in ipairs(Config.Gear) do if it.id == GEAR_ID then row = it end end
	assert(row and row.name == "Desk monitors" and row.kind == "speakers" and row.needs and row.needs.followers, "Config.Gear has no spk_monitors row named 'Desk monitors' with followers needs (Task 7)")
	local TOAST = "NEW GEAR: " .. string.upper(row.name)
	assert(TOAST == "NEW GEAR: DESK MONITORS", "the toast reads '" .. TOAST .. "', want 'NEW GEAR: DESK MONITORS' (copy 5.7)")
	local ROUTES = {
		{ id = "mom_busy", choice = 1, key = "tour", pay = 0, toast = TOAST },
		{ id = "rep_headphones", choice = 1, key = "signed", toast = TOAST },
		{ id = "mishap_keys", choice = 2, key = "found", pay = 0, phone = true, toast = TOAST },
	}
	for _, r in ipairs(ROUTES) do
		local card = Content.CardById[r.id]
		local good = card and card.choices[r.choice] and card.choices[r.choice].good
		assert(good and good.key == r.key, r.id .. " choice " .. r.choice .. " has no good outcome '" .. r.key .. "'")
		assert(good.gift == GEAR_ID, r.id .. " choice " .. r.choice .. ".good.gift is " .. tostring(good.gift) .. ", want " .. GEAR_ID .. RED)
		if r.pay == nil then r.pay = good.money or 0 end
	end
	assert(ROUTES[2].pay == 300, "rep_headphones' good outcome pays $" .. ROUTES[2].pay .. ", want 300")
	fresh("start")
	assert(test:Invoke("ResetTour", uid) == true, "ResetTour failed") -- the tour's "gear" step undone: only a Bought could finish it
	assert(tourGot().gear ~= true, "the tour's gear step is done after ResetTour")
	table.insert(out, "0 the three outcomes carry gift " .. GEAR_ID .. "; the toast is '" .. TOAST .. "'")

	-- 1. the gift path on its own (the walk-in hook's Gift: WalkIns.Gift, Gear.Grant and the toast, on the live modules)
	unowned("gift")
	local followers = stats().followers
	assert(followers < row.needs.followers, "1: this career has " .. followers .. " followers, want fewer than the monitors' " .. row.needs.followers .. " (the gift skips the gate)")
	assert(wi:Invoke("Gift", uid, "no_such_item") == false, "1: Gift of an unknown id did not answer false" .. RED)
	assert(wi:Invoke("Gift", uid, 42) == false, "1: Gift of a non-string did not answer false")
	assert(not owns() and #toasts() == 0, "1: a refused Gift left the monitors owned or sent a toast")
	local m1 = money()
	assert(wi:Invoke("Gift", uid, GEAR_ID) == true, "1: Gift(" .. GEAR_ID .. ") did not answer true" .. RED)
	assert(owns() and listHas("Gear", GEAR_ID), "1: after Gift the monitors are not owned / not in the Gear attribute")
	local list1 = toasts()
	assert(#list1 == 1 and list1[1] == TOAST, "1: Gift sent the toasts " .. say(list1) .. ", want exactly '" .. TOAST .. "'")
	assert(money() == m1, "1: Gift moved the money " .. m1 .. " -> " .. money())
	assert(wi:Invoke("Gift", uid, GEAR_ID) == false, "1: a second Gift of an owned item did not answer false")
	assert(#toasts() == 0 and owns() and money() == m1, "1: the second Gift sent a toast or changed the monitors or the money")
	assertTier2("1")
	table.insert(out, "1 Gift: " .. followers .. " followers (under " .. row.needs.followers .. "), unknown / non-string false, " .. GEAR_ID .. " true (owned, Gear attribute, one toast, money "
		.. m1 .. " unchanged), again false and silent, speakers tier 2")

	-- 2. each route to its gift, then the same outcome with the monitors already yours
	for i, r in ipairs(ROUTES) do
		local tag = "2." .. i .. " " .. r.id
		unowned(tag)
		local m0 = money()
		local result = play(r, tag, 1)
		assertGranted(r, result, m0, tag)
		-- the same outcome again: owned already, so no second toast, and nothing else changes
		assert(wi:Invoke("Reset", uid) == true, tag .. ": WalkIns Reset failed")
		local m2 = money()
		local again = play(r, tag .. " again", 1)
		assert(again.key == r.key, tag .. " again: the outcome landed '" .. tostring(again.key) .. "', want '" .. r.key .. "'")
		local list = toasts()
		assert(#list == 0, tag .. " again: the monitors were already owned, but the toasts sent were " .. say(list) .. ", want none")
		assert(owns() and listHas("Gear", GEAR_ID), tag .. " again: the monitors are no longer owned")
		assert(money() - m2 == r.pay, string.format("%s again: money moved %+d, want the outcome's own %+d", tag, money() - m2, r.pay))
		task.wait(0.3)
		local n, tiers = speakers()
		assert(n == 2 and tiers == "2,2", tag .. " again: the bedroom holds " .. n .. " speaker models (tiers " .. tiers .. "), want exactly 2 at tier 2")
		table.insert(out, string.format("%s choice %d (%s): owned, one toast '%s', money %+d (the outcome's own), speakers tier 2; again: no toast, still owned, money %+d",
			tag, r.choice, r.phone and "phone" or "walk-in", r.toast, r.pay, r.pay))
	end

	-- 3. a gift is only on the good side: the find's bad roll owns nothing and sends no toast
	unowned("bad roll")
	local bad = play(ROUTES[3], "bad roll", 100)
	assert(bad.key == "missing", "3: mishap_keys choice 2 forced to the bad roll landed '" .. tostring(bad.key) .. "', want 'missing'")
	local list = toasts()
	assert(#list == 0 and not owns() and not listHas("Gear", GEAR_ID), "3: the bad roll sent " .. say(list) .. " and left the monitors owned = " .. tostring(owns()))
	table.insert(out, "3 mishap_keys choice 2 on the bad roll (missing): nothing owned, no toast")

	-- 4. no gift was a purchase
	task.wait(0.3) -- deferred signals: a Bought would have run its listeners by now
	assert(tourGot().gear ~= true, "4: the tour's gear step is done after the gifts: Gear.Bought fired (a gift is not the tour's buy-gear step)")
	table.insert(out, "4 the tour's gear step is still undone (no Gear.Bought)")
end

local ok, msg = pcall(run)
pcall(unseat)
pcall(teleport, LOUNGE) -- first, so the rebuild below never happens under the player
pcall(function() rooms:Invoke("Reset", uid) end)
pcall(function()
	wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
	test:Invoke("ResetHints", uid)
	ph:Invoke("Quiet", uid, false)
end)
-- the profile as ProfileMark noted it: the gear, the money, the gate logs and the tour put back
local restored
pcall(function() restored = test:Invoke("ProfileRestore", uid) end)
pcall(function() career:Invoke("Publish", uid) end) -- Career_Get's cached Money dropped, the career attributes sent again
if not ok then error(msg, 0) end
assert(restored == true, "cleanup: the test hook's ProfileRestore answered " .. tostring(restored) .. ", want true")
local gearAfter = ownedGear()
assert(table.concat(gearAfter, ",") == table.concat(gearBefore or {}, ","), "cleanup: the gear reads '" .. table.concat(gearAfter, ",") .. "', want what it was: '" .. table.concat(gearBefore or {}, ",") .. "'")
local elapsed = os.clock() - T0
assert(elapsed < 90, string.format("the run took %.1f s, want under 90", elapsed))
return "T107A PLAY OK\n" .. table.concat(out, "\n") .. string.format("\nelapsed %.1f s", elapsed)
