-- Server, during play (the Day One plan, Task 2: card 1, the test hold and the walk-in hold), through the Studio hooks.
-- The body runs held (WalkInsPaused true: the join path starts no chain; Review Focus 1), except case 13's at most 3 s,
-- from the file's fresh(): unseated in the lounge, Quiet on, the phone, WalkIns, Career and Life reset, no hint seen, the
-- rooms hook's Reset (a slot claimed, the plot rebuilt), the DayOne hook's Reset, ResetTour and ResetSessions. The tour
-- is noted first; the cleanup puts it back. _StudioDayOneHook (Systems/DayOne): Joined, Start, Open, Choose(index),
-- ChooseToken(token, index), Get, State, Sent (DayOne's actions since the last read), Opened (DAW.Opened fires for the
-- player since the last read: a test's require gets its own module copies and can't connect the live event), SetRoll,
-- Age(s), Tick, Reset. Under deferred signals a handler runs a frame after the call that fired its event (Picked ->
-- the tour's take, Opened -> open, Tour.Changed -> DayOne), so every read after such a call polls (2 s, as t106a), and
-- between() settles before and after its resets.
-- Every case starts with between() (case 4 goes on from case 3's open card): the DayOne Reset, ResetTour, ResetSessions
-- and WalkIns Reset (count 0, no visit, the timer at 1e6), then WakeUp (the player at the bedroom's Spawn, PlaceOf
-- <slot>/bedroom); then no chain, DayOneBusy nil, a fresh tour, and Sent read empty.
-- (1) Joined under the hold answers "held"; 2 s later Sent is empty, DayOneBusy nil, no chain.
-- (2) Every step advanced (TourAdvance x5, no chain: ruling F3): the walk-in timer stays 1e6 and DayOneBusy nil; Start
--     answers nil, sends nothing and starts no chain.
-- (3) Start answers "dayone" and sends it at once; Get returns that payload: source "dayone", header DAY ONE, walk SKIP,
--     card day1_dayone with three choices, the line carrying "$400" (JUNO's j1 pay), choice 2 "$450", no "{" in any text,
--     visitor.id "juno" in her Data/Artists colour as { r, g, b }; DayOneBusy true; WalkIns SetRemaining(0) + Poke
--     answers false (no visit).
-- (4) Choose(1) on that card at the bedroom's Spawn (the laptop within DAWConfig.CloseDistance, checked): Sent holds
--     "leave" and "opendaw" (at the room laptop); DAW.Opened fired once; Contracts' active request is j1; the tour's open
--     and take steps are got.
-- (5) Start; SetRoll(0.1); Choose(2): d1.haggle "good", the toast haggleGood ("she said yes. $450 when it's done."), j1
--     active. between(); Start; SetRoll(0.9); Choose(2): "bad" and haggleBad. Money is unchanged by both.
-- (6) Start; Choose(3): the card closes, no request taken, returnAt set LookAround ahead. Age(LookAround), Tick: card 1
--     again, returned true. Choose(3), Age(LookAround), Tick: no third card.
-- (6b) Ruling B1: Start; Choose(3) (returnAt set); TourAdvance take (the request taken another way): returnAt cleared
--      (Changed "take", polled), Next nil; Age(LookAround), Tick: nothing sent, no card.
-- (6c) Fix round 1, a stale open card refused: Start; TourAdvance take (written at once; its Changed handler runs a frame
--      late); at once ChooseToken(card 1, 2) (Haggle) answers "stale": card 1 leaves, d1.haggle stays nil, nothing is
--      taken (active nil), no toast and no beat maker.
-- (6d) Fix round 1, the real pick path: Start; the DayOne hook's Pick (Contracts.Pick, Session_Pick's own handler) on
--      the first offered brief by another artist than JUNO: ok, that brief active, the tour's take got; card 1 leaves
--      within 2 s (the same "leave" as an expiry's, its token); ChooseToken on it, 1 and 2, answer "stale"; the active
--      brief is still the picked one, d1.haggle nil, no returnAt; DayOneBusy stays true until Age(HoldMax) + Tick, then
--      false, and nothing more is sent.
-- (7) Teleported to the landing's front door (PlaceOf <slot>/landing; the laptop more than 14 studs away and no beat-
--     making spot in reach, checked); Start; Choose(1): j1 active, no "opendaw", the toast far.
-- (8) Start; Choose(0) (SKIP): the tour done and skipped, XP unchanged, DayOneBusy false, the chain ended, the walk-in
--     timer within Config.DayOne.VisitAfter.
-- (9) Start; ChooseToken("day1:stale", 1) answers { ok = false, reason = "stale" }; Choose(7) "invalid"; the card stays
--     open (same token, no "leave").
-- (10) WalkIns Spawn (a visit in flight); Start: nothing sent, card 1 queued (pending), DayOneBusy true. The visit
--      Expire'd; Tick: "dayone" sent.
-- (11) Start; Choose(3); Age(HoldMax); Tick: no return (ruling F1), DayOneBusy false; SetRemaining(0) + Poke starts a
--      visit.
-- (12) The wanderer: Start; Choose(3); Age(LookAround); Tick: card 1 returns. Age(HoldMax - LookAround); Tick: the
--      returned card leaves, DayOneBusy false, the tour not done; SetRemaining(0) + Poke starts a visit.
-- (13) The real auto-start: the hold lifted (WalkInsPaused nil) for at most 3 s; Joined answers "waiting" and "dayone"
--      is sent within 3 s (the player in their bedroom: FirstCard later); the hold back at once (the cleanup too).
-- On any error, and after success: the hold on, the DayOne Reset, unseated in the lounge (the beat maker closes there),
-- the rooms Reset, WalkIns, phone, Career and Life reset, no hint seen, ResetSessions, ResetTour and the noted steps done
-- again, Quiet off, then a final DayOne Reset (ruling F6) and DayOneBusy nil; the error is rethrown after.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local RED = " (before the D1-T2 sync of Systems/DayOne, Systems/Tour, Systems/WalkIns and the rest: the expected red)"
local RED1 = " (before the D1-T2 fix1 sync of Systems/DayOne: the expected red)"
local d1 = SOK:WaitForChild("_StudioDayOneHook", 5); assert(d1, "no _StudioDayOneHook (is Systems/DayOne synced and started?)" .. RED)
local rooms = SOK:WaitForChild("_StudioRoomsHook", 5); assert(rooms, "no _StudioRoomsHook (is Systems/Rooms synced and started?)")
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local Config = require(RS.OK.Config)
local C = Config.DayOne
assert(type(C) == "table", "Config.DayOne missing" .. RED)
local D = require(RS.OK.Data.DayOne)
local Rules = require(RS.OK.Modules.DayOneRules)
local Format = require(RS.OK.Modules.Format)
local Artists = require(RS.OK.Data.Artists)
local DAWCfg = require(RS.OK.Modules.DAWConfig)
local Tour = require(RS.OK.Systems.Tour) -- its Steps only
local LOUNGE = Vector3.new(24, 3, 0)
local REACH = DAWCfg.CloseDistance
local STARTER = Rules.Starter(Artists.Briefs)
local JUNO = Artists.ArtistById[STARTER.artist]
local PAY = STARTER.reward.cred
local VARS = { artist = JUNO.name, pay = Format.Money(PAY), ask = Format.Money(PAY + C.HaggleBonus) }
local out = {}
local T0 = os.clock()
local tourBefore -- noted first thing in run(); the cleanup puts it back
local k, bed, laptop -- the player's slot, bedroom and bedroom laptop (run())

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
local function call(cmd, a, b) return d1:Invoke(cmd, uid, a, b) end
local function state(label)
	local s = call("State")
	assert(type(s) == "table", label .. ": the DayOne hook's State answered " .. tostring(s) .. ", want a table" .. RED)
	return s
end
local function busy() return p:GetAttribute("DayOneBusy") end
-- the DayOne actions since the last read (drains the log)
local function sent(label)
	local l = call("Sent")
	assert(type(l) == "table", label .. ": the DayOne hook's Sent answered " .. tostring(l) .. ", want a list" .. RED)
	return l
end
local function find(list, kind, id)
	for _, e in ipairs(list) do if e.kind == kind and (id == nil or e.id == id) then return e end end
	return nil
end
local function kinds(list)
	local t = {}
	for _, e in ipairs(list) do table.insert(t, tostring(e.kind) .. (e.id and (":" .. tostring(e.id)) or "") .. (e.text and (" '" .. tostring(e.text) .. "'") or "")) end
	return #t > 0 and table.concat(t, ", ") or "nothing"
end
local function prof() return test:Invoke("GetProfile", uid) end
local function tourNow()
	local pr = prof()
	local t = type(pr) == "table" and type(pr.tour) == "table" and pr.tour or {}
	return { done = t.done == true, skipped = t.skipped == true, got = type(t.got) == "table" and t.got or {} }
end
local function gotList(t)
	local ids = {}
	for _, s in ipairs(Tour.Steps) do if t.got[s.id] then table.insert(ids, s.id) end end
	return (#ids > 0 and table.concat(ids, ",") or "none") .. (t.done and " (done)" or "") .. (t.skipped and " (skipped)" or "")
end
local function money() return tonumber(prof().cred) or 0 end
local function xp() return tonumber(prof().xp) or 0 end
local function active() local s = prof().sessions; return type(s) == "table" and s.active or nil end
-- the tour as it was noted: its steps done again (a finished tour finished again, as t104a's cleanup does)
local function restoreTour(before)
	for _, s in ipairs(Tour.Steps) do
		if before.done or before.got[s.id] then test:Invoke("TourAdvance", uid, s.id) end
	end
end
local function placeNow()
	local pl = rooms:Invoke("PlaceOf", uid)
	return type(pl) == "table" and (tostring(pl.slot) .. "/" .. tostring(pl.kind)) or tostring(pl)
end
local function placeIs(want, label)
	waitFor(function() return placeNow() == want end, 3)
	local got = placeNow()
	assert(got == want, label .. ": PlaceOf is " .. got .. ", want " .. want)
end
local function dist(part) local r = root(); return r and (r.Position - part.Position).Magnitude or math.huge end
-- the take step got (Picked's handler runs a frame late), so no Advance lands in the next case's fresh tour
local function takeGot(label)
	assert(waitFor(function() return tourNow().got.take == true end, 2), label .. ": the tour's take step isn't got 2 s after the pick (got: " .. gotList(tourNow()) .. ")")
end
-- every string in a payload, for the "no {" check
local function strings(v, acc, path)
	if type(v) == "string" then table.insert(acc, { path = path, s = v })
	elseif type(v) == "table" then for key, x in pairs(v) do strings(x, acc, path .. "." .. tostring(key)) end end
	return acc
end
local function rgb(c) return { math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5) } end

-- the file's own fresh(): unseated in the lounge, Quiet on, the phone, WalkIns, Career and Life reset, no hint seen,
-- the rooms hook's Reset (slot claimed, plot rebuilt), the DayOne Reset, ResetTour and ResetSessions
local function fresh(label)
	unseat()
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, label .. ": Quiet(true) failed")
	assert(ph:Invoke("Reset", uid) == true, label .. ": phone Reset failed")
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	assert(life:Invoke("Reset", uid) == true, label .. ": Life Reset failed")
	assert(test:Invoke("ResetHints", uid) == true, label .. ": ResetHints failed")
	assert(rooms:Invoke("Reset", uid) == true, label .. ": the rooms hook's Reset failed (no slot, or the plot did not build)")
	assert(call("Reset") == true, label .. ": the DayOne hook's Reset answered something else than true" .. RED)
	assert(test:Invoke("ResetTour", uid) == true, label .. ": ResetTour failed")
	assert(test:Invoke("ResetSessions", uid) == true, label .. ": ResetSessions failed")
end
-- before every case: settled, everything Day One touches reset, the player at the bedroom's Spawn, and all of it checked
local function between(label)
	task.wait(0.3) -- the last case's late handlers (Picked, Opened, Tour.Changed) run before the resets
	assert(call("Reset") == true, label .. ": the DayOne Reset failed")
	assert(test:Invoke("ResetTour", uid) == true, label .. ": ResetTour failed")
	assert(test:Invoke("ResetSessions", uid) == true, label .. ": ResetSessions failed")
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed")
	unseat()
	assert(rooms:Invoke("WakeUp", uid) == true, label .. ": WakeUp returned false")
	task.wait(0.3) -- the resets' own late handlers (Tour.Changed "reset") run
	placeIs(k .. "/bedroom", label .. " WakeUp")
	local s = state(label)
	assert(not s.running and s.card == nil and s.pending == nil, label .. ": after the resets a chain runs (card "
		.. tostring(s.card and s.card.id) .. ", pending " .. tostring(s.pending and s.pending.id) .. "), want none")
	assert(busy() == nil, label .. ": DayOneBusy is " .. tostring(busy()) .. " after the resets, want nil")
	local t = tourNow()
	assert(not t.done and next(t.got) == nil, label .. ": the tour after ResetTour has " .. gotList(t) .. ", want nothing got")
	local l = sent(label)
	assert(#l == 0, label .. ": Sent after the resets holds " .. kinds(l) .. ", want nothing")
	assert(wi:Invoke("Pending", uid) == nil, label .. ": a walk-in is in flight after WalkIns Reset")
	assert(wi:Invoke("GetRemaining", uid) == 1e6, label .. ": the walk-in timer is " .. tostring(wi:Invoke("GetRemaining", uid)) .. " after WalkIns Reset, want 1e6")
end

local function run()
	tourBefore = tourNow()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh("start")
	local info = rooms:Invoke("Plot", uid)
	k = type(info) == "table" and info.slot
	assert(k, "the rooms hook's Plot answered " .. tostring(info) .. ", want the player's slot")
	local plotModel = workspace.OK_Plots:FindFirstChild(string.format("Plot_%02d", k))
	bed = plotModel and plotModel:FindFirstChild("Room_bedroom")
	assert(bed, string.format("Workspace.OK_Plots.Plot_%02d has no Room_bedroom", k))
	laptop = rooms:Invoke("Station", uid)
	assert(typeof(laptop) == "Instance" and laptop:IsDescendantOf(bed), "the rooms hook's Station is " .. tostring(laptop) .. ", want the bedroom's laptop")
	assert(VARS.pay == "$400" and VARS.ask == "$450", "JUNO's pay fills " .. VARS.pay .. " and the ask " .. VARS.ask .. ", want $400 and $450 (Data/Artists j1, Config.DayOne.HaggleBonus)")

	-- 1. the join path under the hold
	between("1")
	local j = call("Joined")
	assert(j == "held", "1: Joined under the hold answered " .. tostring(j) .. ", want held" .. RED)
	task.wait(2)
	local l1 = sent("1")
	assert(#l1 == 0, "1: 2 s after a held join Sent holds " .. kinds(l1) .. ", want nothing")
	assert(busy() == nil, "1: DayOneBusy is " .. tostring(busy()) .. " after a held join, want nil")
	assert(not state("1").running, "1: a chain runs after a held join")
	table.insert(out, "1 Joined under the hold: held; 2 s later nothing sent, DayOneBusy nil, no chain")

	-- 2. a finished tour (no chain: F3) and Start on it
	between("2")
	for _, s in ipairs(Tour.Steps) do test:Invoke("TourAdvance", uid, s.id) end
	task.wait(0.3) -- Tour.Changed's handlers run
	assert(tourNow().done, "2: TourAdvance x5 left the tour " .. gotList(tourNow()) .. ", want done")
	local rem2 = wi:Invoke("GetRemaining", uid)
	assert(rem2 == 1e6, "2: after TourAdvance x5 with no chain the walk-in timer is " .. tostring(rem2) .. ", want 1e6 untouched (F3: no ArmFirst)")
	assert(busy() == nil, "2: DayOneBusy is " .. tostring(busy()) .. " after TourAdvance x5 with no chain, want nil")
	local s2 = call("Start")
	assert(s2 == nil, "2: Start on a finished tour answered " .. tostring(s2) .. ", want nil")
	task.wait(0.3)
	local l2 = sent("2")
	assert(#l2 == 0, "2: Start on a finished tour sent " .. kinds(l2) .. ", want nothing")
	assert(not state("2").running and busy() == nil, "2: Start on a finished tour left a chain (DayOneBusy " .. tostring(busy()) .. "), want none (m6)")
	table.insert(out, "2 TourAdvance x5 with no chain: timer 1e6, DayOneBusy nil; Start: nil, nothing sent, no chain")

	-- 3. Start: card 1 at once
	between("3")
	local n3 = call("Start")
	assert(n3 == "dayone", "3: Start answered " .. tostring(n3) .. ", want dayone")
	local l3 = sent("3")
	local arr = find(l3, "arrive", "dayone")
	assert(arr and type(arr.token) == "string", "3: Start sent " .. kinds(l3) .. ", want arrive:dayone with a token")
	local pay = call("Get")
	assert(type(pay) == "table" and pay.token == arr.token, "3: Get answered " .. tostring(type(pay) == "table" and pay.token or pay) .. ", want the sent card's token " .. arr.token)
	local open3 = call("Open")
	assert(type(open3) == "table" and open3.token == arr.token and open3.id == "dayone", "3: Open answered " .. tostring(open3 and open3.id) .. ", want the dayone card")
	assert(pay.source == "dayone", "3: the payload's source is " .. tostring(pay.source) .. ", want dayone")
	assert(pay.header == D.Header and pay.header == "DAY ONE", "3: the payload's header is " .. tostring(pay.header) .. ", want DAY ONE")
	assert(pay.walk == D.Skip and pay.walk == "SKIP", "3: the payload's walk is " .. tostring(pay.walk) .. ", want SKIP")
	local card = pay.card
	assert(type(card) == "table" and card.id == "day1_dayone", "3: the payload's card id is " .. tostring(card and card.id) .. ", want day1_dayone")
	assert(type(card.choices) == "table" and #card.choices == 3, "3: the card has " .. tostring(type(card.choices) == "table" and #card.choices) .. " choices, want 3")
	assert(type(card.line) == "string" and card.line:find("$400", 1, true), "3: the card's line is '" .. tostring(card.line) .. "', want it to carry $400")
	assert(card.line == Rules.Fill(D.Cards.dayone.line, VARS), "3: the card's line is '" .. card.line .. "', want '" .. Rules.Fill(D.Cards.dayone.line, VARS) .. "'")
	assert(tostring(card.choices[2].text):find("$450", 1, true), "3: choice 2 reads '" .. tostring(card.choices[2].text) .. "', want it to carry $450")
	for _, e in ipairs(strings(pay, {}, "payload")) do
		assert(not e.s:find("{", 1, true), "3: " .. e.path .. " still holds a '{': " .. e.s)
	end
	local v = card.visitor
	assert(type(v) == "table" and v.id == "juno" and v.name == JUNO.name, "3: the visitor is " .. tostring(v and v.id) .. " / " .. tostring(v and v.name) .. ", want juno / " .. JUNO.name)
	local want = rgb(JUNO.color)
	assert(type(v.color) == "table" and v.color[1] == want[1] and v.color[2] == want[2] and v.color[3] == want[3], "3: the visitor's colour is "
		.. (type(v.color) == "table" and table.concat(v.color, ",") or tostring(v.color)) .. ", want JUNO's " .. table.concat(want, ","))
	assert(busy() == true, "3: DayOneBusy is " .. tostring(busy()) .. " with card 1 open, want true")
	assert(wi:Invoke("SetRemaining", uid, 0) == true, "3: SetRemaining(0) failed")
	local poke3 = wi:Invoke("Poke", uid)
	assert(poke3 == false and wi:Invoke("Pending", uid) == nil, "3: with card 1 open a Poke answered " .. tostring(poke3) .. ", want false and no visit (WalkIns' schedule refuses while DayOneBusy)")
	table.insert(out, string.format("3 Start: dayone sent and Get returns it (DAY ONE, SKIP, 3 choices, %s / %s, juno %s, no '{'); DayOneBusy true; Poke refused",
		VARS.pay, VARS.ask, table.concat(want, ",")))

	-- 4. "Make it now" at the bedroom's Spawn (case 3's card)
	local d4 = dist(laptop)
	assert(d4 <= REACH, string.format("4: at the bedroom's Spawn the laptop is %.1f studs away, want at most %d (the precondition)", d4, REACH))
	call("Opened") -- drained
	local c4 = call("Choose", 1)
	assert(type(c4) == "table" and c4.ok == true, "4: Choose(1) answered " .. tostring(c4 and c4.reason) .. ", want ok")
	local l4 = sent("4")
	assert(find(l4, "leave", "dayone") and find(l4, "opendaw"), "4: Choose(1) at the Spawn sent " .. kinds(l4) .. ", want leave:dayone and opendaw")
	assert(find(l4, "opendaw").id == "room", "4: the beat maker opened at " .. tostring(find(l4, "opendaw").text) .. ", want the bedroom's laptop")
	local opens = 0
	waitFor(function() opens += call("Opened"); return opens >= 1 end, 2)
	task.wait(0.3)
	opens += call("Opened")
	assert(opens == 1, "4: DAW.Opened fired " .. opens .. " times, want once")
	assert(active() == "j1", "4: Contracts' active request is " .. tostring(active()) .. ", want j1")
	assert(waitFor(function() local t = tourNow(); return t.got.open == true and t.got.take == true end, 2), "4: the tour has " .. gotList(tourNow()) .. ", want open and take got")
	assert(call("Get") == nil and state("4").card == nil, "4: a card is still open after Choose(1)")
	table.insert(out, string.format("4 Choose(1) %.1f studs from the laptop: leave + opendaw (room), DAW.Opened once, j1 active, open and take got", d4))

	-- 5. the haggle, good then bad
	between("5 good")
	local m5 = money()
	assert(call("Start") == "dayone", "5 good: Start didn't answer dayone")
	assert(call("SetRoll", 0.1) == true, "5 good: SetRoll failed")
	local c5 = call("Choose", 2)
	assert(type(c5) == "table" and c5.ok == true, "5 good: Choose(2) answered " .. tostring(c5 and c5.reason) .. ", want ok")
	local l5 = sent("5 good")
	local t5 = find(l5, "toast")
	local good = Rules.Fill(D.Toasts.haggleGood, VARS)
	assert(t5 and t5.text == good, "5 good: the toast reads " .. tostring(t5 and t5.text) .. ", want '" .. good .. "'")
	assert(find(l5, "opendaw"), "5 good: the haggle didn't go on as make (sent " .. kinds(l5) .. ", want an opendaw)")
	local h5 = state("5 good").d1
	assert(type(h5) == "table" and h5.haggle == "good", "5 good: d1.haggle is " .. tostring(h5 and h5.haggle) .. ", want good")
	assert(active() == "j1", "5 good: the active request is " .. tostring(active()) .. ", want j1")
	takeGot("5 good")
	between("5 bad")
	assert(call("Start") == "dayone", "5 bad: Start didn't answer dayone")
	assert(call("SetRoll", 0.9) == true, "5 bad: SetRoll failed")
	local c5b = call("Choose", 2)
	assert(type(c5b) == "table" and c5b.ok == true, "5 bad: Choose(2) answered " .. tostring(c5b and c5b.reason) .. ", want ok")
	local l5b = sent("5 bad")
	local t5b = find(l5b, "toast")
	local bad = Rules.Fill(D.Toasts.haggleBad, VARS)
	assert(t5b and t5b.text == bad, "5 bad: the toast reads " .. tostring(t5b and t5b.text) .. ", want '" .. bad .. "'")
	local h5b = state("5 bad").d1
	assert(type(h5b) == "table" and h5b.haggle == "bad", "5 bad: d1.haggle is " .. tostring(h5b and h5b.haggle) .. ", want bad")
	assert(active() == "j1", "5 bad: the active request is " .. tostring(active()) .. ", want j1")
	takeGot("5 bad")
	assert(money() == m5, "5: money moved from " .. m5 .. " to " .. money() .. " over two haggles, want unchanged (the +$50 comes on the delivery)")
	table.insert(out, "5 haggle: roll 0.1 good ('" .. good .. "'), roll 0.9 bad ('" .. bad .. "'), j1 active both times, money unchanged")

	-- 6. "Look around first", the one return, no third card
	between("6")
	assert(call("Start") == "dayone", "6: Start didn't answer dayone")
	sent("6")
	assert(call("Choose", 3).ok == true, "6: Choose(3) failed")
	local l6 = sent("6")
	assert(find(l6, "leave", "dayone") and not find(l6, "opendaw") and not find(l6, "toast"), "6: Look around sent " .. kinds(l6) .. ", want only leave:dayone")
	local s6 = state("6")
	assert(s6.card == nil and type(s6.returnAt) == "number" and math.abs(s6.returnAt - s6.now - C.LookAround) < 1,
		"6: after Look around the card is " .. tostring(s6.card and s6.card.id) .. " and returnAt is " .. tostring(s6.returnAt and (s6.returnAt - s6.now))
		.. " s ahead, want no card and " .. C.LookAround)
	task.wait(0.3)
	assert(active() == nil and not tourNow().got.take, "6: Look around took a request (active " .. tostring(active()) .. ", tour " .. gotList(tourNow()) .. ")")
	assert(call("Age", C.LookAround) == true and call("Tick") == true, "6: Age or Tick failed")
	local l6b = sent("6 return")
	local back6 = find(l6b, "arrive", "dayone")
	local s6b = state("6 return")
	assert(back6 and s6b.returned == true and s6b.card and s6b.card.token == back6.token and s6b.returnAt == nil,
		"6: LookAround later the loop sent " .. kinds(l6b) .. " (returned " .. tostring(s6b.returned) .. ", returnAt " .. tostring(s6b.returnAt) .. "), want card 1 back, returned, no returnAt")
	assert(call("Choose", 3).ok == true, "6: Choose(3) on the returned card failed")
	assert(state("6 again").returnAt == nil, "6: Look around on the returned card set a returnAt, want none (it comes back once)")
	assert(call("Age", C.LookAround) == true and call("Tick") == true, "6: Age or Tick failed")
	local l6c = sent("6 again")
	assert(not find(l6c, "arrive"), "6: a third card 1 came: " .. kinds(l6c))
	assert(state("6 again").card == nil, "6: a card is open after the second Look around")
	table.insert(out, "6 Look around: closed, nothing taken, returnAt +" .. C.LookAround .. " s; aged, it returns once (returned true); again: no third card")

	-- 6b. ruling B1: the request taken another way while card 1 is away: it never comes back
	between("6b")
	assert(call("Start") == "dayone", "6b: Start didn't answer dayone")
	assert(call("Choose", 3).ok == true, "6b: Choose(3) failed")
	sent("6b")
	assert(type(state("6b").returnAt) == "number", "6b: no returnAt after Look around")
	assert(test:Invoke("TourAdvance", uid, "take") == true, "6b: TourAdvance(take) failed")
	assert(waitFor(function() return state("6b").returnAt == nil end, 2), "6b: returnAt is still " .. tostring(state("6b").returnAt)
		.. " 2 s after the take step, want cleared (B1: Changed take)")
	local n6b = state("6b").next
	assert(n6b == nil, "6b: with take got Next is " .. tostring(n6b) .. ", want nil (deliver missing)")
	assert(call("Age", C.LookAround) == true and call("Tick") == true, "6b: Age or Tick failed")
	local l6d = sent("6b")
	assert(not find(l6d, "arrive"), "6b: card 1 came back after the request was taken: " .. kinds(l6d))
	assert(state("6b").card == nil, "6b: a card is open after the take")
	table.insert(out, "6b B1: Look around, then take: returnAt cleared, LookAround later nothing sent")

	-- 6c. fix round 1: a choice on card 1 after the request was taken is refused (the take handler may not have run yet)
	between("6c")
	assert(call("Start") == "dayone", "6c: Start didn't answer dayone")
	local open6c = call("Open")
	assert(type(open6c) == "table" and open6c.id == "dayone", "6c: card 1 isn't open after Start")
	sent("6c")
	assert(test:Invoke("TourAdvance", uid, "take") == true, "6c: TourAdvance(take) failed")
	local r6c = call("ChooseToken", open6c.token, 2) -- at once
	assert(type(r6c) == "table" and r6c.ok == false and r6c.reason == "stale", "6c: Haggle on card 1 after the request was taken answered ok "
		.. tostring(r6c and r6c.ok) .. ", reason " .. tostring(r6c and r6c.reason) .. "; want refused: stale" .. RED1)
	task.wait(0.3)
	local s6c = state("6c")
	assert(s6c.d1 == nil or s6c.d1.haggle == nil, "6c: d1.haggle is " .. tostring(s6c.d1 and s6c.d1.haggle) .. " after a refused Haggle, want nil")
	assert(active() == nil, "6c: the refused Haggle took " .. tostring(active()) .. ", want no request (the take came from TourAdvance)")
	assert(call("Open") == nil and s6c.card == nil, "6c: card 1 is still open after the take")
	local l6g = sent("6c")
	assert(find(l6g, "leave", "dayone") and not find(l6g, "toast") and not find(l6g, "opendaw"), "6c: sent " .. kinds(l6g)
		.. ", want only leave:dayone")
	table.insert(out, "6c a Haggle right after the take: stale; card 1 left, d1.haggle nil, nothing taken")

	-- 6d. fix round 1: another artist's request taken at the laptop's picker while card 1 is open
	between("6d")
	assert(call("Start") == "dayone", "6d: Start didn't answer dayone")
	local open6d = call("Open")
	assert(type(open6d) == "table" and open6d.id == "dayone", "6d: card 1 isn't open after Start")
	sent("6d")
	local pk = call("Pick")
	assert(type(pk) == "table" and pk.ok == true and type(pk.id) == "string", "6d: the DayOne hook's Pick answered ok "
		.. tostring(type(pk) == "table" and pk.ok or pk) .. ", reason " .. tostring(type(pk) == "table" and pk.reason) .. ", id "
		.. tostring(type(pk) == "table" and pk.id) .. "; want ok and a brief" .. RED1)
	local pb = Artists.BriefById[pk.id]
	assert(pb and pb.artist ~= STARTER.artist, "6d: the hook picked " .. pk.id .. " by " .. tostring(pb and pb.artist) .. ", want another artist than " .. STARTER.artist)
	assert(active() == pk.id, "6d: the active request is " .. tostring(active()) .. " after the pick, want " .. pk.id)
	takeGot("6d")
	assert(waitFor(function() return call("Open") == nil end, 2), "6d: card 1 is still open 2 s after " .. pk.id .. " was taken, want it closed" .. RED1)
	local l6e = sent("6d")
	local left6d = find(l6e, "leave", "dayone")
	assert(left6d and left6d.token == open6d.token, "6d: after the pick the loop sent " .. kinds(l6e) .. ", want card 1's leave")
	assert(not find(l6e, "toast") and not find(l6e, "opendaw") and not find(l6e, "arrive"), "6d: after the pick sent " .. kinds(l6e) .. ", want only the leave")
	for _, i in ipairs({ 1, 2 }) do
		local r = call("ChooseToken", open6d.token, i)
		assert(type(r) == "table" and r.ok == false and r.reason == "stale", "6d: ChooseToken(card 1, " .. i .. ") after the pick answered ok "
			.. tostring(r and r.ok) .. ", reason " .. tostring(r and r.reason) .. "; want stale")
	end
	task.wait(0.3)
	assert(active() == pk.id, "6d: the active request became " .. tostring(active()) .. ", want " .. pk.id .. " kept (no j1 over it)")
	local s6d = state("6d")
	assert(s6d.d1 == nil or s6d.d1.haggle == nil, "6d: d1.haggle is " .. tostring(s6d.d1 and s6d.d1.haggle) .. ", want nil")
	assert(s6d.returnAt == nil and s6d.card == nil and s6d.pending == nil, "6d: after the pick the chain holds card " .. tostring(s6d.card and s6d.card.id)
		.. ", pending " .. tostring(s6d.pending and s6d.pending.id) .. ", returnAt " .. tostring(s6d.returnAt) .. "; want none of them")
	assert(busy() == true, "6d: DayOneBusy is " .. tostring(busy()) .. " right after the pick, want true until HoldMax from the chain's start")
	assert(call("Age", C.HoldMax) == true and call("Tick") == true, "6d: Age or Tick failed")
	assert(busy() == false, "6d: DayOneBusy is " .. tostring(busy()) .. " HoldMax after the chain's start, want false")
	local l6f = sent("6d")
	assert(#l6f == 0, "6d: HoldMax later the loop sent " .. kinds(l6f) .. ", want nothing")
	table.insert(out, "6d " .. pk.id .. " (" .. pb.artist .. ") taken at the picker: card 1 left, choices on it stale, " .. pk.id
		.. " kept, d1.haggle nil, DayOneBusy false at HoldMax")

	-- 7. "Make it now" from the landing: far
	between("7")
	local front = plotModel:FindFirstChild("Landing") and plotModel.Landing:FindFirstChild("FrontDoor")
	local inside = front and front:FindFirstChild("Inside")
	assert(inside and inside:IsA("Attachment"), string.format("Plot_%02d's Landing.FrontDoor has no Inside attachment", k))
	unseat()
	teleport(inside.WorldPosition + Vector3.new(0, 3, 0))
	placeIs(k .. "/landing", "7")
	local d7 = dist(laptop)
	assert(d7 > REACH, string.format("7: on the landing the laptop is %.1f studs away, want more than %d (the precondition)", d7, REACH))
	local so7 = rooms:Invoke("StationOf", uid)
	assert(type(so7) == "table" and so7.inst == nil, "7: on the landing DAW.StationOf names " .. tostring(so7 and so7.inst) .. ", want no beat-making spot")
	assert(call("Start") == "dayone", "7: Start didn't answer dayone")
	sent("7")
	call("Opened") -- drained
	assert(call("Choose", 1).ok == true, "7: Choose(1) failed")
	local l7 = sent("7")
	local t7 = find(l7, "toast")
	assert(t7 and t7.text == D.Toasts.far, "7: the toast reads " .. tostring(t7 and t7.text) .. ", want '" .. D.Toasts.far .. "' (sent " .. kinds(l7) .. ")")
	assert(not find(l7, "opendaw"), "7: the beat maker opened from the landing (sent " .. kinds(l7) .. ")")
	assert(active() == "j1", "7: the active request is " .. tostring(active()) .. ", want j1")
	takeGot("7")
	task.wait(0.3)
	assert(call("Opened") == 0, "7: DAW.Opened fired from the landing, want never")
	table.insert(out, string.format("7 Choose(1) on the landing (%.1f studs from the laptop): j1 active, no opendaw, the toast '%s'", d7, D.Toasts.far))

	-- 8. SKIP
	between("8")
	local x8 = xp()
	assert(call("Start") == "dayone", "8: Start didn't answer dayone")
	sent("8")
	assert(call("Choose", 0).ok == true, "8: Choose(0) failed")
	local t8 = tourNow()
	assert(t8.done and t8.skipped, "8: after SKIP the tour is " .. gotList(t8) .. ", want done and skipped")
	task.wait(0.3)
	assert(xp() == x8, "8: XP moved from " .. x8 .. " to " .. xp() .. " on SKIP, want unchanged")
	assert(busy() == false, "8: DayOneBusy is " .. tostring(busy()) .. " after SKIP, want false")
	local s8 = state("8")
	assert(not s8.running and s8.done == true, "8: after SKIP the chain still runs, want it ended")
	local rem8 = wi:Invoke("GetRemaining", uid)
	assert(type(rem8) == "number" and rem8 >= C.VisitAfter[1] and rem8 <= C.VisitAfter[2], "8: the walk-in timer is " .. tostring(rem8)
		.. " after SKIP, want " .. C.VisitAfter[1] .. ".." .. C.VisitAfter[2] .. " (WalkIns.ArmFirst)")
	local l8 = sent("8")
	assert(find(l8, "leave", "dayone"), "8: SKIP sent " .. kinds(l8) .. ", want leave:dayone")
	table.insert(out, "8 SKIP: tour done and skipped, XP unchanged, DayOneBusy false, the first visit armed in " .. rem8 .. " s")

	-- 9. a stale token and an invalid index
	between("9")
	assert(call("Start") == "dayone", "9: Start didn't answer dayone")
	sent("9")
	local open9 = call("Open")
	local r9 = call("ChooseToken", "day1:stale", 1)
	assert(type(r9) == "table" and r9.ok == false and r9.reason == "stale", "9: ChooseToken(day1:stale) answered " .. tostring(r9 and r9.reason) .. ", want stale")
	local r9b = call("Choose", 7)
	assert(type(r9b) == "table" and r9b.ok == false and r9b.reason == "invalid", "9: Choose(7) answered " .. tostring(r9b and r9b.reason) .. ", want invalid")
	local open9b = call("Open")
	assert(type(open9b) == "table" and open9b.token == open9.token, "9: card 1 isn't open with the same token after the refusals")
	local l9 = sent("9")
	assert(#l9 == 0, "9: the refusals sent " .. kinds(l9) .. ", want nothing")
	assert(active() == nil, "9: a refused choice took " .. tostring(active()))
	table.insert(out, "9 ChooseToken(day1:stale): stale; Choose(7): invalid; card 1 still open")

	-- 10. a walk-in in flight holds card 1
	between("10")
	assert(wi:Invoke("Spawn", uid) == true, "10: WalkIns Spawn refused (the player in the bedroom, nothing in flight)")
	assert(wi:Invoke("Pending", uid) ~= nil, "10: no walk-in in flight after Spawn")
	assert(call("Start") == "dayone", "10: Start didn't answer dayone")
	local l10 = sent("10")
	assert(not find(l10, "arrive"), "10: with a visit in flight Start sent " .. kinds(l10) .. ", want nothing")
	local s10 = state("10")
	assert(s10.card == nil and s10.pending and s10.pending.id == "dayone", "10: card " .. tostring(s10.card and s10.card.id) .. ", pending "
		.. tostring(s10.pending and s10.pending.id) .. "; want no card and dayone queued")
	assert(busy() == true, "10: DayOneBusy is " .. tostring(busy()) .. " with card 1 queued, want true")
	assert(wi:Invoke("Expire", uid) == true, "10: Expire failed")
	assert(wi:Invoke("Pending", uid) == nil, "10: the visit is still in flight after Expire")
	assert(call("Tick") == true, "10: Tick failed")
	local l10b = sent("10")
	assert(find(l10b, "arrive", "dayone"), "10: once the visit ended a Tick sent " .. kinds(l10b) .. ", want arrive:dayone")
	assert(state("10").pending == nil, "10: card 1 is still queued after it was sent")
	table.insert(out, "10 a visit in flight: Start queues card 1 and sends nothing; the visit expired, a Tick sends it")

	-- 11. HoldMax with no return
	between("11")
	assert(call("Start") == "dayone", "11: Start didn't answer dayone")
	assert(call("Choose", 3).ok == true, "11: Choose(3) failed")
	sent("11")
	assert(call("Age", C.HoldMax) == true and call("Tick") == true, "11: Age or Tick failed")
	local l11 = sent("11")
	assert(not find(l11, "arrive"), "11: past HoldMax card 1 came back: " .. kinds(l11) .. " (F1: no return once HoldMax has passed)")
	assert(busy() == false, "11: DayOneBusy is " .. tostring(busy()) .. " past HoldMax with no card, want false")
	assert(wi:Invoke("SetRemaining", uid, 0) == true, "11: SetRemaining(0) failed")
	local poke11 = wi:Invoke("Poke", uid)
	assert(poke11 == true and wi:Invoke("Pending", uid) ~= nil, "11: past HoldMax a Poke answered " .. tostring(poke11) .. ", want a visit")
	table.insert(out, "11 Look around, HoldMax later: no return, DayOneBusy false, a Poke starts a visit")

	-- 12. the wanderer: the returned card closes at HoldMax
	between("12")
	assert(call("Start") == "dayone", "12: Start didn't answer dayone")
	assert(call("Choose", 3).ok == true, "12: Choose(3) failed")
	sent("12")
	assert(call("Age", C.LookAround) == true and call("Tick") == true, "12: Age or Tick failed")
	local l12 = sent("12")
	local back12 = find(l12, "arrive", "dayone")
	assert(back12 and state("12").returned == true, "12: LookAround later the loop sent " .. kinds(l12) .. ", want card 1 back")
	assert(call("Age", C.HoldMax - C.LookAround) == true and call("Tick") == true, "12: Age or Tick failed")
	local l12b = sent("12")
	local gone = find(l12b, "leave", "dayone")
	assert(gone and gone.token == back12.token, "12: at HoldMax the loop sent " .. kinds(l12b) .. ", want the returned card's leave")
	assert(busy() == false, "12: DayOneBusy is " .. tostring(busy()) .. " at HoldMax, want false")
	assert(not tourNow().done, "12: the tour is done after the wanderer's card closed, want not")
	assert(wi:Invoke("SetRemaining", uid, 0) == true, "12: SetRemaining(0) failed")
	local poke12 = wi:Invoke("Poke", uid)
	assert(poke12 == true and wi:Invoke("Pending", uid) ~= nil, "12: at HoldMax a Poke answered " .. tostring(poke12) .. ", want a visit")
	table.insert(out, "12 the wanderer: card 1 returns, closes at HoldMax, DayOneBusy false, tour not done, a Poke starts a visit")

	-- 13. the real auto-start, the hold lifted for at most 3 s
	between("13")
	local got13, j13
	local ok13, err13 = pcall(function()
		RS.OK:SetAttribute("WalkInsPaused", nil)
		local t13 = os.clock()
		j13 = call("Joined")
		waitFor(function()
			for _, e in ipairs(sent("13")) do if e.kind == "arrive" and e.id == "dayone" then got13 = os.clock() - t13 end end
			return got13 ~= nil
		end, 3)
	end)
	RS.OK:SetAttribute("WalkInsPaused", true)
	if not ok13 then error(err13, 0) end
	assert(j13 == "waiting", "13: Joined without the hold answered " .. tostring(j13) .. ", want waiting")
	assert(got13, "13: without the hold no dayone was sent within 3 s of Joined")
	table.insert(out, string.format("13 without the hold: Joined waiting, dayone sent %.1f s later; the hold back on", got13))

	return "T121A PLAY OK\n" .. table.concat(out, "\n") .. string.format("\nelapsed %.1f s", os.clock() - T0)
end

local ok, msg = pcall(run)
pcall(function() RS.OK:SetAttribute("WalkInsPaused", true) end)
pcall(function() d1:Invoke("Reset", uid) end) -- first: no chain sees the tour restored
pcall(unseat)
pcall(teleport, LOUNGE) -- the beat maker closes past 14 studs; first, so the rebuild below never happens under the player
pcall(function() rooms:Invoke("Reset", uid) end)
pcall(function()
	wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
	test:Invoke("ResetHints", uid); test:Invoke("ResetSessions", uid); test:Invoke("ResetTour", uid)
	if tourBefore then restoreTour(tourBefore) end
	ph:Invoke("Quiet", uid, false)
end)
task.wait(0.3) -- the restore's late handlers run (no chain: nothing)
pcall(function() d1:Invoke("Reset", uid) end) -- last (F6)
local busyLeft = p:GetAttribute("DayOneBusy")
if not ok then error(msg, 0) end
assert(busyLeft == nil, "cleanup: DayOneBusy is " .. tostring(busyLeft) .. " after the final DayOne Reset, want nil")
return msg
