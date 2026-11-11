-- Server, during play (Wave 3 Task 4 fix round 1; design 4.2), after t78b: the cold spell's edges. The file's own fresh()
-- (as t78a's: unseated in the lounge, Quiet on, WalkIns Reset, Career Reset, Life Reset with the career day DAY = 6,
-- ResetHints, SetRecent({}), the tour done, one walk-in counted). The body runs held (WalkInsPaused true) except the two
-- short windows below, where the hold is false (present: no burst, no heal, no Life day loop) so the phone's 1 s loop runs.
-- (1) cold_news waits for the tour (F11): ResetTour, then SetLastDay(DAY - 3) and ColdCheck: cold "quiet", and nothing is
--     queued; the tour finished (TourAdvance) still queues nothing under the hold; with the hold false the phone's loop
--     (Career.SendColdNews) queues it within 3 s.
-- (2) A dropped card comes back (A): the phone hook's Reset drops it (as a respawn's dropAll does): none pending, cold.news
--     still false; the next ColdCheck queues it again. Opened, cold.news turns true, and neither a check nor 2 s of the
--     loop queues it again.
-- (3) A 2-star delivery while cold doesn't thaw (F8): RecordDelivery(P2, 140, 2): still cold, the story still ends with
--     "cold", no LifeBanner; lastDay is DAY (written while cold).
-- (4) A passed delivery writes lastDay on a warm career (F9): SetCold(nil), SetLastDay(DAY - 2), RecordDelivery(P3, 150,
--     2): lastDay DAY, warm, no story line, no banner.
-- (5) A quiet spell that ends deep in the red re-arms (C): a quiet spell, a real Take to -70 while cold (stays "quiet"),
--     a 3-star RecordDelivery: warm with rearm true, and the next check at -70 stays warm.
-- (6) The arrive header (E): cold again ("quiet"), today set to 5, navx_placement spawned: his arrive payload has today 6
--     and max 6 (never "6 OF 2"); walked away.
-- Everything is reset at the end, pass or fail (hold true, WalkIns, Career, Life, hints, recent beats, the tour done,
-- Quiet off), and an error is rethrown.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local Tour = require(RS.OK.Systems.Tour)
local LOUNGE = Vector3.new(24, 3, 0)
local WALKER = "navx_placement"
local DAY = 6
local function pat(ch) return string.rep("0", 120) .. string.rep(ch, 8) end
local P2, P3, P4 = pat("2"), pat("3"), pat("4")
local out = {}
local T0 = os.clock()

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function root() local c = p.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function teleport(pos)
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
local function cold()
	local c = career:Invoke("Cold", uid)
	assert(type(c) == "table", "Cold(uid) returned " .. typeof(c) .. " (before the Task 4 sync of Systems/Career it returns nil)")
	return c
end
local function show(c)
	local s = c.cold
	return string.format("{ %s, rearm %s, lastDay %s }", s and string.format("cold %s since %s news %s", tostring(s.reason), tostring(s.since), tostring(s.news)) or "warm",
		tostring(c.rearm), tostring(c.lastDay))
end
local function check() career:Invoke("ColdCheck", uid, "check"); return cold() end
local function setLastDay(d, label) assert(career:Invoke("SetLastDay", uid, d) == true, label .. ": SetLastDay(" .. tostring(d) .. ") failed") end
local function deliver(pattern, bpm, stars, label)
	assert(test:Invoke("RecordDelivery", uid, pattern, bpm, stars) == true, label .. ": RecordDelivery(" .. stars .. " stars) failed")
end
local function coldPops()
	local list = {}
	for _, e in ipairs(ph:Invoke("Pending", uid)) do if e.id == "cold_news" then table.insert(list, e) end end
	return list
end
local function popsSent()
	local n = 0
	for _, e in ipairs(ph:Invoke("Sent", uid)) do if e.kind == "pop" then n += 1 end end
	return n
end
local function banners()
	local list = {}
	for _, e in ipairs(life:Invoke("Sent", uid)) do if e.kind == "LifeBanner" then table.insert(list, tostring(e.payload and e.payload.text)) end end
	return list
end
local function story()
	local st = life:Invoke("State", uid)
	local list = st and st.story or {}
	local e = list[#list]
	return #list, e and e.k
end
local function advanceTour() for _, s in ipairs(Tour.Steps) do test:Invoke("TourAdvance", uid, s.id) end end
local function tourDone() local t = test:Invoke("GetProfile", uid).tour; return type(t) == "table" and t.done == true end
-- `fn` with the hold false (the 1 s loops tick; no burst, heal or Life day loop), the hold back to true on every exit
local function unheld(label, fn)
	local ok, res = pcall(function()
		assert(wi:Invoke("Pause", uid, false) == true, label .. ": Pause(false) failed")
		return fn()
	end)
	assert(wi:Invoke("Pause", uid, true) == true, label .. ": Pause(true) failed")
	if not ok then error(res, 0) end
	return res
end
local function fresh(label)
	local c = p.Character; local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum and hum.Sit then hum.Sit = false; task.wait(0.4) end
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, label .. ": Quiet(true) failed")
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	assert(life:Invoke("Reset", uid) == true, label .. ": Life Reset failed")
	assert(life:Invoke("SetDay", uid, DAY) == true, label .. ": Life SetDay(" .. DAY .. ") failed")
	assert(test:Invoke("ResetHints", uid) == true, label .. ": ResetHints failed")
	assert(type(test:Invoke("SetRecent", uid, {})) == "table", label .. ": SetRecent({}) failed")
	advanceTour()
	assert(tourDone(), label .. ": the tour is not done after TourAdvance")
	assert(wi:Invoke("AdvanceVisits", uid, 1) == true, label .. ": AdvanceVisits failed")
	ph:Invoke("Sent", uid); life:Invoke("Sent", uid)
	local c0 = cold()
	assert(c0.cold == nil and c0.lastDay == nil, label .. ": after the resets want warm with no lastDay, got " .. show(c0))
end

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh("tour")

	-- 1. cold_news waits for the tour; the phone's loop queues it once the tour is done
	assert(test:Invoke("ResetTour", uid) == true and not tourDone(), "tour: ResetTour failed")
	setLastDay(DAY - 3, "tour")
	local c1 = check()
	assert(c1.cold and c1.cold.reason == "quiet" and c1.cold.news == false, "tour: want cold quiet with no news, got " .. show(c1))
	assert(#coldPops() == 0 and popsSent() == 0, "tour: cold_news was queued before the tour was done")
	advanceTour()
	assert(tourDone(), "tour: the tour is not done after TourAdvance")
	assert(#coldPops() == 0, "tour: cold_news was queued under the hold without a check (only the loop or a check sends it)")
	local looped = unheld("tour loop", function() return waitFor(function() return #coldPops() == 1 end, 3) end)
	assert(looped, "tour: the phone's loop did not queue cold_news within 3 s of the tour's end")
	assert(#coldPops() == 1 and popsSent() == 1, "tour: want exactly one cold_news queued by the loop")
	table.insert(out, "1 cold before the tour: nothing queued; tour done: the loop queued one cold_news")

	-- 2. a dropped card comes back; shown, it never comes again this spell
	assert(ph:Invoke("Reset", uid) == true, "drop: the phone hook's Reset failed")
	assert(#coldPops() == 0, "drop: the phone's Reset left cold_news pending")
	local c2 = cold()
	assert(c2.cold and c2.cold.news == false, "drop: cold.news should stay false for a card never shown, got " .. show(c2))
	ph:Invoke("Sent", uid) -- the drop's expire
	check()
	local again = coldPops()
	assert(#again == 1 and popsSent() == 1, "drop: the next ColdCheck did not queue the dropped cold_news again")
	assert(ph:Invoke("Open", uid, again[1].token) == true, "drop: Open(cold_news) failed")
	local c2b = check()
	assert(c2b.cold and c2b.cold.news == true, "shown: cold.news is not true after the card opened: " .. show(c2b))
	ph:Invoke("Sent", uid)
	local none = unheld("shown loop", function() task.wait(2); return #coldPops() == 0 end)
	assert(none and popsSent() == 0, "shown: the loop queued cold_news again after it was shown")
	table.insert(out, "2 dropped (phone Reset): news false, the next check queued it again; opened: news true, no check or 2 s of the loop queued it again")

	-- 3. a 2-star delivery while cold doesn't thaw; it still writes lastDay
	banners()
	local n0, k0 = story()
	setLastDay(DAY - 4, "2 stars")
	deliver(P2, 140, 2, "2 stars")
	local c3 = cold()
	local n3, k3 = story()
	assert(c3.cold and c3.cold.reason == "quiet", "2 stars: a 2-star delivery ended the spell: " .. show(c3))
	assert(n3 == n0 and k3 == "cold" and k0 == "cold", "2 stars: the story changed (" .. tostring(k0) .. " -> " .. tostring(k3) .. ", " .. n0 .. " -> " .. n3 .. " lines)")
	assert(#banners() == 0, "2 stars: a banner went out")
	assert(c3.lastDay == DAY, "2 stars: the passed delivery should write lastDay " .. DAY .. " while cold, got " .. tostring(c3.lastDay))
	table.insert(out, "3 2-star delivery while cold: " .. show(c3) .. ", no thaw line, no banner")

	-- 4. a passed delivery writes lastDay on a warm career, no thaw involved
	assert(career:Invoke("SetCold", uid, nil, false) == true, "warm: SetCold(nil) failed")
	setLastDay(DAY - 2, "warm")
	local n4 = story()
	deliver(P3, 150, 2, "warm")
	local c4 = cold()
	assert(c4.cold == nil and c4.lastDay == DAY, "warm: a 2-star delivery on a warm career should write lastDay " .. DAY .. ", got " .. show(c4))
	assert(story() == n4 and #banners() == 0, "warm: a delivery on a warm career logged a line or sent a banner")
	table.insert(out, "4 warm, lastDay " .. (DAY - 2) .. ", 2-star delivery: " .. show(c4))

	-- 5. a quiet spell that ends deep in the red re-arms: no "aura" relapse on the next check
	setLastDay(DAY - 3, "deep")
	local c5 = check()
	assert(c5.cold and c5.cold.reason == "quiet", "deep: want cold quiet, got " .. show(c5))
	assert(career:Invoke("Take", uid, "aura", 70) == 70, "deep: Take 70 failed")
	local c5b = cold()
	assert(c5b.cold and c5b.cold.reason == "quiet", "deep: Aura -70 while cold should keep the quiet spell, got " .. show(c5b))
	deliver(P4, 160, 3, "deep")
	local c5c = cold()
	assert(c5c.cold == nil and c5c.rearm == true, "deep: a 3-star thaw at -70 should re-arm (ruling C), got " .. show(c5c))
	local c5d = check()
	assert(c5d.cold == nil and c5d.rearm == true, "deep: the check after a thaw at -70 re-chilled it: " .. show(c5d))
	table.insert(out, "5 quiet spell, Take to -70, 3-star thaw: " .. show(c5c) .. "; the next check " .. show(c5d))

	-- 6. the arrive header never reads more visits than its cap
	setLastDay(DAY - 3, "header")
	local c6 = check()
	assert(c6.cold and c6.cold.reason == "quiet", "header: want cold quiet, got " .. show(c6))
	assert(wi:Invoke("DailyMaxFor", uid) == 2, "header: DailyMaxFor is not 2 while cold")
	assert(wi:Invoke("SetToday", uid, 5) == true, "header: SetToday 5 failed")
	wi:Invoke("Sent", uid)
	assert(wi:Invoke("Spawn", uid, WALKER) == true, "header: Spawn(" .. WALKER .. ") refused")
	assert(waitFor(function() local r = wi:Invoke("Pending", uid); return r ~= nil and r.arrived == true end, 15), "header: he did not arrive within 15 s")
	local arrive
	for _, e in ipairs(wi:Invoke("Sent", uid)) do if e.kind == "arrive" then arrive = e.payload end end
	assert(type(arrive) == "table", "header: no arrive payload in the walk-in hook's Sent")
	assert(arrive.today == 6 and arrive.max == 6, string.format("header: the arrive payload reads %s OF %s, want 6 OF 6 (never 6 OF 2)", tostring(arrive.today), tostring(arrive.max)))
	local r = wi:Invoke("Pending", uid)
	assert(wi:Invoke("Choose", uid, r.token, 0).ok == true, "header: walk away failed")
	table.insert(out, "6 cold, today 5, a visit arrives: payload " .. arrive.today .. " OF " .. arrive.max)
end

local ok, msg = pcall(run)
pcall(function()
	wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
	test:Invoke("ResetHints", uid); test:Invoke("SetRecent", uid, {}); advanceTour(); ph:Invoke("Quiet", uid, false)
end)
if not ok then pcall(teleport, LOUNGE); error(msg, 0) end
return "T78C PLAY OK\n" .. table.concat(out, "\n") .. string.format("\nelapsed %.1f s", os.clock() - T0)
