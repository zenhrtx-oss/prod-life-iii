-- Server, during play (Wave 3 Task 4; design 4.2; Review Focus 3), before t78b: the cold spell. The file's own fresh()
-- (unseated in the lounge, Quiet on, WalkIns Reset, Career Reset (warm, no lastDay), Life Reset with the career day set to
-- DAY = 6, _StudioTestHook ResetHints, SetRecent({}), the tour done and one walk-in counted, so bursts and the phone's
-- system send are allowed). The body runs held (WalkInsPaused true) and drives everything through the hooks; the cold
-- state is read through _StudioCareerHook Cold (Systems/Career owns it), the player attribute Cold, and Life's State.
-- (1) A burst under way (the hook's Rush(2) and one Spawn + Expire: BusyDay true), then SetLastDay(DAY - 3) and
--     ColdCheck("check"): cold, reason "quiet", since DAY; Cold true; the burst is over (BusyDay false, Rush nil); no
--     LifeBanner on entry; the story ends with "cold".
-- (2) While cold: DailyMaxFor 2 (Config.WalkIns.Cold.dailyMax), and the scheduler goes by it (a Poke at today 2 is
--     refused, at today 1 it starts a visit); a forced burst is ended at its first re-arm (no burst while cold); the
--     phone's CanSend is false; cold_news was queued once through SendSystem (one pop, a NEWS; cold.news still false: it
--     turns true only when shown, fix round 1 A), a second ColdCheck doesn't queue a second; opened, it counts on today's
--     phone total, its result carries the FIRE hint, cold.news is true, and a later check queues nothing.
-- (3) The way out, a FIRE: the player's own beat airs (the monitor hook's Enqueue) and a pretend listener's FIRE goes
--     through Reactions.Give (FireAs, as t22c and t77a do): CreditFire put it on that beat (Recent: fires 1), and the
--     spell is over: warm, Cold false, lastDay = DAY, a "thaw" story line and exactly one LifeBanner with
--     LifeRules.Copy.ThawBanner. Then ColdCheck("check") the same day stays warm (the lastDay ruling: a stale lastDay
--     would re-chill "quiet"), CanSend is true again and DailyMaxFor is back to DailyMax.
-- (4) Aura: SetCold(nil) and Aura 0, then a real Take of 60 (Aura -60): cold "aura", and this new spell's own cold_news
--     is queued (news false). A 3-star RecordDelivery (the real Contracts path) thaws it with rearm true (a second
--     ThawBanner) and withdraws the unopened cold_news (gone from Pending, its "expire" sent, today's phone count
--     unchanged: fix round 1 B). Aura -60 stays warm on a check, and a real Take to -70 too; a real Add back to -20 clears
--     rearm; a real Take to -60 goes cold "aura" again.
-- (5) No lastDay (fix round 1 D): SetCold(nil), Aura -60, SetLastDay(nil): the first ColdCheck("check") is warm and lastDay
--     becomes DAY (never cold on a first read); the next check goes cold "aura".
-- (6) The day step: lastDay DAY - 2 and Life AdvanceDay (the real Tick) to DAY + 1: cold "quiet" since DAY + 1.
-- Staging for t78b (inside the same pcall): fresh() again, then SetLastDay(DAY - 3) and ColdCheck("check"): the player is
-- cold (attribute Cold true, BusyDay false) and Quiet stays on, so no card reaches the client; the two ThawBanners of (3)
-- and (4) went to the client during the body. t78b checks the COLD chip and BannerLog. On any error everything is reset
-- (hold true, WalkIns, Career (warm), Life, hints, recent beats, Quiet off, the airing cancelled) and the error rethrown.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local mon = SOK:WaitForChild("_StudioMonitorHook", 5); assert(mon, "no _StudioMonitorHook")
local Config = require(RS.OK.Config)
local LifeRules = require(RS.OK.Modules.LifeRules)
local Tour = require(RS.OK.Systems.Tour)
local NP = RS.OK.NowPlaying
local W = Config.WalkIns
local COLD = W.Cold; assert(type(COLD) == "table" and COLD.dailyMax == 2 and COLD.quietDays == 3, "Config.WalkIns.Cold is not { dailyMax = 2, quietDays = 3, ... }")
local THAW = LifeRules.Copy.ThawBanner
local LOUNGE = Vector3.new(24, 3, 0)
local WALKER = "navx_placement" -- walks in from the door, so a Spawn + Expire ends before he can arrive
local DAY = 6 -- the career day the body runs on (Life SetDay)
local AIR = require(RS.OK.Modules.DAWConfig).DefaultPattern -- the beat the monitors air (t22c and t77a air it cleanly)
local P1 = string.rep("0", 120) .. string.rep("1", 8) -- a delivered beat, only stored
local out = {}
local T0 = os.clock()

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
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
-- the cold state through the career hook: { cold = { since, reason, news } | nil, rearm, lastDay }
local function cold()
	local c = career:Invoke("Cold", uid)
	assert(type(c) == "table", "Cold(uid) returned " .. typeof(c) .. " (before the Task 4 sync of Systems/Career it returns nil: the expected red)")
	return c
end
local function show(c)
	local s = c.cold
	return string.format("{ %s, rearm %s, lastDay %s }", s and string.format("cold %s since %s news %s", tostring(s.reason), tostring(s.since), tostring(s.news)) or "warm",
		tostring(c.rearm), tostring(c.lastDay))
end
local function check(event, label)
	career:Invoke("ColdCheck", uid, event)
	return cold()
end
local function setLastDay(d, label) assert(career:Invoke("SetLastDay", uid, d) == true, label .. ": SetLastDay(" .. tostring(d) .. ") failed") end
local function set(s, label) assert(career:Invoke("Set", uid, s) == true, label .. ": Career Set failed") end
local function aura() return career:Invoke("Get", uid).aura end
local function busyDay() return p:GetAttribute("BusyDay") end
local function rush() return wi:Invoke("Rush", uid) end
local function dailyMax()
	local m = wi:Invoke("DailyMaxFor", uid)
	assert(type(m) == "number", "DailyMaxFor(uid) returned " .. typeof(m) .. " (before the Task 4 sync of Systems/WalkIns it returns nil: the expected red)")
	return m
end
local function canSend()
	local c = ph:Invoke("CanSend", uid)
	assert(type(c) == "boolean", "CanSend(uid) returned " .. typeof(c) .. " (before the Task 4 sync of Systems/Phone it returns nil: the expected red)")
	return c
end
-- the pending cold_news pops (the phone hook's Pending: { token, id, kind, opened })
local function coldPops()
	local list = {}
	for _, e in ipairs(ph:Invoke("Pending", uid)) do if e.id == "cold_news" then table.insert(list, e) end end
	return list
end
local function popsSent() -- "pop" sends since the last read (the read drains it)
	local n = 0
	for _, e in ipairs(ph:Invoke("Sent", uid)) do if e.kind == "pop" then n += 1 end end
	return n
end
-- the LifeBanner texts Life sent since the last read (the read drains it)
local function banners()
	local list = {}
	for _, e in ipairs(life:Invoke("Sent", uid)) do if e.kind == "LifeBanner" then table.insert(list, tostring(e.payload and e.payload.text)) end end
	return list
end
local function lastStory()
	local st = life:Invoke("State", uid)
	local e = st and st.story and st.story[#st.story]
	return e and e.k, e and e.d
end
local function cycle(label) -- a walker Spawned then Expired before he arrives: endVisit re-arms at once (nextGap)
	assert(wi:Invoke("Spawn", uid, WALKER) == true, label .. ": Spawn(" .. WALKER .. ") refused (is the player in the hub?)")
	assert(wi:Invoke("Expire", uid) == true, label .. ": Expire found no visit")
end
local function poke(today, label) -- one scheduler check at `today` visits; a visit it starts is ended at once
	assert(wi:Invoke("SetToday", uid, today) == true, label .. ": SetToday failed")
	local started = wi:Invoke("Poke", uid)
	if started then assert(wi:Invoke("Expire", uid) == true, label .. ": the Poke's visit could not be expired") end
	return started
end
-- the file's own fresh(): unseated in the lounge, Quiet on, WalkIns, Career and Life reset (career day DAY), no hint
-- seen, no recent beat, the tour done and one walk-in counted (past the first-ever visit)
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
	for _, s in ipairs(Tour.Steps) do test:Invoke("TourAdvance", uid, s.id) end
	local tour = test:Invoke("GetProfile", uid).tour
	assert(type(tour) == "table" and tour.done == true, label .. ": the tour is not done after TourAdvance")
	assert(wi:Invoke("AdvanceVisits", uid, 1) == true, label .. ": AdvanceVisits failed")
	ph:Invoke("Sent", uid); life:Invoke("Sent", uid) -- drained: every read below is this file's
	local c0 = cold()
	assert(c0.cold == nil and c0.rearm == false and c0.lastDay == nil and p:GetAttribute("Cold") ~= true,
		label .. ": after the resets want warm, no rearm, no lastDay; got " .. show(c0) .. ", Cold " .. tostring(p:GetAttribute("Cold")))
end

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh("quiet")

	-- 1. a burst under way, then a quiet streak: cold "quiet", the burst over, no banner, the story's "cold"
	assert(wi:Invoke("Rush", uid, 2) == true, "quiet: the hook's Rush(2) failed")
	cycle("quiet burst")
	assert(busyDay() == true and rush() ~= nil, "quiet: the forced burst is not under way (BusyDay " .. tostring(busyDay()) .. ")")
	setLastDay(DAY - 3, "quiet")
	local c1 = check("check", "quiet")
	assert(c1.cold and c1.cold.reason == "quiet" and c1.cold.since == DAY, "quiet: SetLastDay(DAY - 3) then ColdCheck: want cold quiet since " .. DAY .. ", got " .. show(c1))
	assert(p:GetAttribute("Cold") == true, "quiet: the Cold attribute is " .. tostring(p:GetAttribute("Cold")))
	assert(busyDay() == false and rush() == nil, "quiet: the burst under way did not end when the spell started (BusyDay " .. tostring(busyDay()) .. ")")
	local b1 = banners()
	assert(#b1 == 0, "quiet: going cold sent a LifeBanner: " .. table.concat(b1, " | "))
	local k1, d1 = lastStory()
	assert(k1 == "cold" and d1 == DAY, "quiet: the story ends with " .. tostring(k1) .. " on day " .. tostring(d1) .. ", want cold on day " .. DAY)
	table.insert(out, "1 burst under way, SetLastDay(" .. (DAY - 3) .. ") + ColdCheck: " .. show(c1) .. "; Cold true; BusyDay false, no burst; no banner; story ends 'cold'")

	-- 2. while cold: the walk-in cap, no burst, no pop, cold_news once
	local m2 = dailyMax()
	assert(m2 == COLD.dailyMax, "cold: DailyMaxFor is " .. tostring(m2) .. ", want " .. COLD.dailyMax)
	assert(poke(2, "cold today 2") == false, "cold: a Poke at today 2 started a visit (the cap should be " .. COLD.dailyMax .. ")")
	assert(poke(1, "cold today 1") == true, "cold: a Poke at today 1 was refused (control: under the cold cap)")
	assert(wi:Invoke("SetToday", uid, 0) == true, "cold: SetToday 0 failed")
	assert(wi:Invoke("Rush", uid, 2) == true, "cold: the hook's Rush(2) failed")
	cycle("cold burst")
	assert(busyDay() == false and rush() == nil, "cold: a forced burst went on while cold (BusyDay " .. tostring(busyDay()) .. ")")
	assert(canSend() == false, "cold: the phone's CanSend is true while cold")
	local pops = coldPops()
	assert(#pops == 1 and pops[1].kind == "news" and pops[1].opened == false, "cold: want one un-opened cold_news NEWS pending, got " .. #pops)
	assert(popsSent() == 1, "cold: the phone sent other than one pop since fresh()")
	assert(c1.cold.news == false, "cold: cold.news is " .. tostring(c1.cold.news) .. " while the card only waits (it turns true when shown)")
	local c2 = check("check", "cold again")
	assert(c2.cold and c2.cold.reason == "quiet" and c2.cold.news == false, "cold again: a second ColdCheck changed the spell: " .. show(c2))
	assert(#coldPops() == 1 and popsSent() == 0, "cold again: a second ColdCheck queued a second cold_news")
	local before = ph:Invoke("State", uid).today
	assert(ph:Invoke("Open", uid, pops[1].token) == true, "cold: Open(cold_news) failed")
	local opened = ph:Invoke("State", uid).today
	local resultHint
	for _, e in ipairs(ph:Invoke("Sent", uid)) do if e.kind == "result" and e.token == pops[1].token then resultHint = e.hint end end
	assert(opened == before + 1 and #coldPops() == 0, "cold: opening cold_news should count on today's phone total (" .. tostring(before) .. " -> " .. tostring(opened) .. ") and leave none pending")
	assert(type(resultHint) == "table" and resultHint.term == "fire", "cold: cold_news's result hint is " .. tostring(resultHint and resultHint.term) .. ", want fire")
	local c2b = check("check", "shown")
	assert(c2b.cold and c2b.cold.news == true, "shown: cold.news is " .. tostring(c2b.cold and c2b.cold.news) .. " after the card opened")
	assert(#coldPops() == 0 and popsSent() == 0, "shown: a check after the card was shown queued it again")
	table.insert(out, string.format("2 cold: DailyMaxFor %d (Poke refused at today 2, started at 1); a forced burst ended at its re-arm; CanSend false; cold_news once (a second check sent none); opened: phone today %d -> %d, result hint fire",
		m2, before, opened))

	-- 3. a FIRE on the player's own beat ends it: warm, lastDay DAY, a thaw line, one exit banner; the same day's check stays warm
	mon:Invoke("Cancel", uid)
	assert(waitFor(function() local st = mon:Invoke("State"); return st.current == nil end, 25), "fire: the monitors are still busy after 25 s")
	local q = mon:Invoke("Enqueue", uid, p.DisplayName, AIR, 120)
	assert(q and q.ok, "fire: Enqueue refused: " .. tostring(q and q.reason))
	assert(waitFor(function() return NP:GetAttribute("Active") == true and NP:GetAttribute("OwnerId") == uid and NP:GetAttribute("Beat") == AIR end, 8),
		"fire: the player's beat did not go on air")
	mon:Invoke("FireAs", -7801)
	local recent = test:Invoke("Recent", uid)
	mon:Invoke("Cancel", uid)
	assert(type(recent) == "table" and recent[1] and recent[1].pattern == AIR and recent[1].fires == 1, "fire: CreditFire did not put the FIRE on the player's aired beat")
	local c3 = cold()
	assert(c3.cold == nil and c3.rearm == false and c3.lastDay == DAY, "fire: a FIRE on the player's beat should thaw a quiet spell with no rearm and lastDay " .. DAY .. "; got " .. show(c3))
	assert(p:GetAttribute("Cold") == false, "fire: the Cold attribute is " .. tostring(p:GetAttribute("Cold")) .. " after the thaw")
	local k3 = lastStory()
	assert(k3 == "thaw", "fire: the story ends with " .. tostring(k3) .. ", want thaw")
	local b3 = banners()
	assert(#b3 == 1 and b3[1] == THAW, "fire: want exactly one LifeBanner '" .. THAW .. "', got " .. #b3 .. ": " .. table.concat(b3, " | "))
	local c3b = check("check", "fire, same day")
	assert(c3b.cold == nil, "fire: ColdCheck the same day after a quiet thaw re-chilled it: " .. show(c3b) .. " (the lastDay ruling)")
	assert(canSend() == true, "fire: CanSend is false once warm (control)")
	assert(dailyMax() == W.DailyMax, "fire: DailyMaxFor is " .. tostring(dailyMax()) .. " once warm, want " .. W.DailyMax)
	assert(poke(2, "warm today 2") == true, "fire: a Poke at today 2 was refused once warm (control)")
	assert(wi:Invoke("SetToday", uid, 0) == true, "fire: SetToday 0 failed")
	table.insert(out, "3 FIRE on the aired beat (Recent fires 1): " .. show(c3) .. ", Cold false, story 'thaw', one banner; same-day check warm; CanSend true, DailyMaxFor " .. W.DailyMax .. ", Poke at today 2 starts")

	-- 4. Aura: cold "aura" on a real Take, its own cold_news; a 3-star RecordDelivery thaws with rearm; rearm holds under -25
	assert(career:Invoke("SetCold", uid, nil, false) == true, "aura: SetCold(nil) failed")
	set({ aura = 0 }, "aura")
	ph:Invoke("Sent", uid); banners()
	assert(career:Invoke("Take", uid, "aura", 60) == 60 and aura() == -60, "aura: Take 60 did not leave Aura -60")
	local c4 = cold()
	assert(c4.cold and c4.cold.reason == "aura" and c4.cold.since == DAY and c4.cold.news == false, "aura: Aura -60 after a real Take: want cold aura with its news queued, not shown, got " .. show(c4))
	assert(popsSent() == 1 and #coldPops() == 1, "aura: the new spell's cold_news was not queued (once per spell)")
	local stale = coldPops()[1].token
	local phoneToday = ph:Invoke("State", uid).today
	assert(test:Invoke("RecordDelivery", uid, P1, 142, 3) == true, "aura: RecordDelivery(P1, 142, 3) failed")
	local c5 = cold()
	assert(c5.cold == nil and c5.rearm == true and c5.lastDay == DAY, "aura: a 3-star RecordDelivery should thaw with rearm and lastDay " .. DAY .. ", got " .. show(c5))
	local b5 = banners()
	assert(#b5 == 1 and b5[1] == THAW, "aura: the thaw sent " .. #b5 .. " banners: " .. table.concat(b5, " | "))
	local expired = false
	for _, e in ipairs(ph:Invoke("Sent", uid)) do if e.kind == "expire" and e.token == stale then expired = true end end
	assert(#coldPops() == 0 and expired, "aura: the thaw left the unopened cold_news pending (or sent no expire for it)")
	assert(ph:Invoke("State", uid).today == phoneToday, "aura: the withdrawn cold_news counted on today's phone total")
	local c6 = check("check", "rearm -60")
	assert(c6.cold == nil and c6.rearm == true, "aura: Aura -60 with rearm should stay warm on a check, got " .. show(c6))
	assert(career:Invoke("Take", uid, "aura", 10) == 10, "aura: Take 10 failed")
	local c7 = cold()
	assert(c7.cold == nil and c7.rearm == true and aura() == -70, "aura: a real Take to -70 with rearm should stay warm, got " .. show(c7))
	assert(career:Invoke("Add", uid, "aura", 50, "WalkIn") == 50 and aura() == -20, "aura: Add 50 WalkIn did not reach -20")
	local c8 = cold()
	assert(c8.cold == nil and c8.rearm == false, "aura: Aura -20 seen (>= rearmAura " .. COLD.rearmAura .. ") should clear rearm, got " .. show(c8))
	assert(career:Invoke("Take", uid, "aura", 40) == 40 and aura() == -60, "aura: Take 40 did not reach -60")
	local c9 = cold()
	assert(c9.cold and c9.cold.reason == "aura", "aura: re-armed, Aura -60 should go cold again, got " .. show(c9))
	table.insert(out, "4 Take to -60: " .. show(c4) .. " (its own cold_news queued); 3-star RecordDelivery: " .. show(c5) .. " (one banner; the unopened cold_news withdrawn, uncounted); -60 and -70 stay warm (rearm); Add to -20 clears rearm; Take to -60: " .. show(c9))

	-- 5. no lastDay, Aura -60: the first read is warm and saves lastDay; the next check goes cold "aura"
	assert(career:Invoke("SetCold", uid, nil, false) == true, "no lastDay: SetCold(nil) failed")
	set({ aura = -60 }, "no lastDay")
	setLastDay(nil, "no lastDay")
	assert(cold().lastDay == nil, "no lastDay: SetLastDay(nil) left " .. tostring(cold().lastDay))
	local c10 = check("check", "no lastDay")
	assert(c10.cold == nil and c10.lastDay == DAY, "no lastDay: the first ColdCheck at Aura -60 should be warm and save lastDay " .. DAY .. ", got " .. show(c10))
	local c10b = check("check", "no lastDay, next")
	assert(c10b.cold and c10b.cold.reason == "aura", "no lastDay: the check after the first read should go cold aura at -60, got " .. show(c10b))
	assert(career:Invoke("SetCold", uid, nil, false) == true, "no lastDay: SetCold(nil) failed")
	set({ aura = 0 }, "no lastDay")
	table.insert(out, "5 lastDay nil at Aura -60: first ColdCheck " .. show(c10) .. "; the next " .. show(c10b))

	-- 6. the day step: Life.Tick runs the check (lastDay DAY - 2, AdvanceDay to DAY + 1: 3 days)
	setLastDay(DAY - 2, "tick")
	assert(life:Invoke("AdvanceDay", uid) == true, "tick: AdvanceDay did not advance")
	local c11 = cold()
	assert(c11.cold and c11.cold.reason == "quiet" and c11.cold.since == DAY + 1, "tick: the day step to " .. (DAY + 1) .. " with lastDay " .. (DAY - 2) .. " should go cold quiet, got " .. show(c11))
	table.insert(out, "6 lastDay " .. (DAY - 2) .. ", Life AdvanceDay to " .. (DAY + 1) .. " (the real Tick): " .. show(c11))
end

-- staging for t78b (see the header). Returns its report line
local function stage()
	fresh("stage")
	setLastDay(DAY - 3, "stage")
	local c = check("check", "stage")
	assert(c.cold and c.cold.reason == "quiet" and p:GetAttribute("Cold") == true and busyDay() == false, "stage: want the player cold (attribute Cold) with no burst, got " .. show(c))
	return "stage: cold " .. show(c) .. " for t78b (Cold true, BusyDay false, Quiet on)"
end

local ok, msg = pcall(run)
local staged
if ok then ok, staged = pcall(stage) end
if not ok then
	pcall(function()
		wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
		test:Invoke("ResetHints", uid); test:Invoke("SetRecent", uid, {}); ph:Invoke("Quiet", uid, false); mon:Invoke("Cancel", uid)
	end)
	pcall(teleport, LOUNGE)
	error(msg or staged, 0)
end
return "T78A PLAY OK\n" .. table.concat(out, "\n") .. "\n" .. staged .. string.format("\nelapsed %.1f s", os.clock() - T0)
