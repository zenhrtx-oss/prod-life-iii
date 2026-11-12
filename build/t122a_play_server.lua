-- Server, during play (the Day One plan, Task 3: cards 2 and 3, the haggle's bonus and the first visitor), through the
-- Studio hooks. The body runs held (WalkInsPaused true: the join path starts no chain) from the file's fresh(): unseated
-- in the lounge, Quiet on, the phone, WalkIns, Career and Life reset, no hint seen, no gear (ResetGear: Tier 1 speakers,
-- and Roll FX is card 3's tool), the rooms hook's Reset (a slot claimed, the plot rebuilt), the DayOne hook's Reset,
-- ResetTour, ResetSessions, and today's Delivery counts cleared (ResetXPCount and the career hook's ResetCredCount). The
-- tour and the gear are noted first; the cleanup puts them back. Before anything else the test hook's ProfileMark notes
-- the profile's money, XP and level, gear (owned, equipped), today's XP and money gate logs, the tour, the hints and the
-- sessions; the cleanup's last step, ProfileRestore, puts them back exactly (D1-T3 fix 1: this file pays real deliveries
-- and tour rewards, and t17 -> t21 after it count on a fresh session's money, level and gear), on success or failure.
-- _StudioDayOneHook (Systems/DayOne): Start, Show(id), Open, Choose(index), State, Sent (DayOne's actions since the last
-- read), SetRoll, Age(s), Tick, Reset, and Deliver(pattern, bpm, swing) (Contracts.Deliver, Session_Deliver's own
-- handler: a test's require gets its own module copies, so it can't call the live one). Under deferred signals a handler
-- runs a frame after the call that fired its event (Delivered -> Day One, Picked -> the take step, Played -> monitors,
-- Tour.Changed -> Day One), so every read after such a call polls (2 s, as t106a), and money is read once it settles.
-- Money and XP come from the replies, never fixed totals (the suite's other deliveries spend Delivery's daily caps).
-- The beats: j1Beat() is DAWConfig.DefaultPattern (all 128 characters, the keys lane kept) with, in DAWConfig.Tracks
-- order and 16 steps, Kick on 1, Snare on 5 and 13, no Clap, and 8 Hats on the off-beats; j1BeatB() adds 4 hats, 4
-- claps and 2 kicks (10 pads: 4 more hats alone would be 4, under BriefCheck.MinChanged, and refused as a copy of the
-- last delivery). Both pass j1 for 3 stars at 140 BPM and differ from every reference beat by MinChanged or more.
-- "At the laptop" is room-local (2, 0, -3), t106a's stand spot. Every delivery waits out Contracts.DeliverCooldown.
-- Every case starts with between() (2, 3 and 4 go on from case 1's chain): the DayOne Reset, ResetTour, ResetSessions,
-- WalkIns Reset, WakeUp, then at the laptop; no chain, DayOneBusy nil, a fresh tour, Sent empty, no walk-in, timer 1e6.
-- (1) Start; SetRoll(0.1); Choose(2) (the haggle, good: j1 taken). Deliver j1Beat(): ok, 3 stars; money + reply's cred
--     + HaggleBonus, d1.paid; "speakers" queued AfterDeliver out; Age(AfterDeliver), Tick: card 2 sent with now = true
--     (its line, two choices), the chain's beat j1Beat() at 140.
-- (2) SetActiveRequest("j1"); deliver j1BeatB(), a repeat (again): money + the reply's cred exactly (no second bonus);
--     card 2 still open with the same token, nothing queued, the chain's beat still j1Beat() (ruling m9).
-- (3) Choose(1) (On my speakers): RoomPlaying.Plot_<k> Active with a new Token, Beat == j1Beat(), BPM 140, Room
--     "bedroom", Tier 1, the studio kit; NowPlaying unchanged; Sent: card 2's leave, "play" ok, the toast `speakers`; the
--     monitors step got; "spend" queued; Age(AfterSpeakers), Tick: card 3 sent, its line holding your money, Roll FX and
--     the Desk monitors.
-- (4) Choose(1) (Hit the gear rack) at the laptop (the RackSpot within PanelCloseDistance, checked): Sent "opengear" at
--     the RackSpot and no toast; the tour done, not skipped; XP + Tour.RewardXP once; DayOneBusy false, the chain ended;
--     the walk-in timer within VisitAfter (WalkIns.ArmFirst); in the bedroom a Poke starts a visit whose Data/WalkIns card
--     has first = true. (The done toast is Tour's, not in DayOne's Sent: t124b reads it on the client; preflight m11.)
-- (5) Start; Choose(1) (make: j1 taken, the beat maker at the laptop); deliver j1Beat() (money + cred, no bonus: no
--     haggle); Tick to card 2; Choose(2) (Keep it private): XP + PrivateXP, d1.private, its toast, no play, monitors got;
--     Tick to card 3; Choose(2) (Save it): the tour done, XP + RewardXP, no "opengear", no toast. Show("speakers") again
--     and Choose(2): XP + 0 (d1.private already set), and that staged chain ends (the tour is done: DayOneBusy false).
-- (6) Expiry: TourAdvance take and deliver; RecordDelivery(j1Beat(), 140, 3); Show("speakers") (the chain's beat: Recent
--     [1]); Age(CardSeconds), Tick: it leaves, resolved as private (XP + PrivateXP, monitors got, no play) and "spend" is
--     queued; Show("spend") drops that queued one; Age(CardSeconds), Tick: it leaves, resolved as save (the tour done).
-- (7) No chain (no Start): SetActiveRequest("j1"); deliver: Sent empty, no chain, money + the reply's cred (no bonus),
--     prof.tour.d1 still unwritten. This is t17b's and t41d's case.
-- (8) Resume: TourAdvance open, take and deliver; RecordDelivery(j1Beat(), 140, 3); Start answers "speakers" and sends
--     it at once (now = true), the chain's beat Recent[1]. (8b) The same with no recent beat: Start advances monitors and
--     answers "spend", sent at once.
-- (10, run before 9, which releases the plot) Ruling B3's real path: an old save that pressed ON MONITORS before any
--     delivery (TourAdvance open, take, monitors): Start answers nil (you're making the beat: no card) and the chain runs;
--     SetActiveRequest("j1"); deliver at the studio PC (not your laptop): "spend" queued AfterDeliver out; Age, Tick:
--     card 3; Choose(2): the tour done.
-- (11, run before 9) The haggle, then SKIP, then the first delivery (the review's minor 1): Start; SetRoll(0.1);
--     Choose(2) (good, j1 taken); the pill's SKIP (the test hook's TourSkip: Tour.Skip, the Tour_Skip remote's handler):
--     the tour done and skipped, the chain ended; deliver j1Beat(): money + the reply's cred + HaggleBonus, d1.paid, nothing
--     sent. Once: ResetSessions (the tour and d1 kept), j1 again a first delivery: money + the reply's cred only.
-- (9) A hub delivery, then no plot: Start; Choose(1) far from every beat-making spot (the entry corridor, CORRIDOR: the
--     lounge spot (24, 3, 0) is ~10 studs from the lounge bar's laptop, inside DAWConfig.CloseDistance, so Make it now
--     would open there; checked): the toast farHub, j1 taken; deliver at the studio PC (t106a's PC_SPOT): no card 2
--     (nothing queued, Next still "speakers"); the rooms hook's Play at the bedroom laptop
--     (ON SPEAKERS: Played -> monitors) queues "spend"; Age, Tick: card 3; the rooms hook's Release (moved to the hall,
--     no Station); Choose(1): the toast rackFar, no "opengear", the tour done.
-- On any error, and after success: the hold on, the DayOne Reset, any room play stopped, unseated in the lounge, the
-- rooms hook's Claim (case 9 released the slot), the gear put back, the rooms Reset, WalkIns, phone, Career and Life
-- reset, no hint seen, ResetSessions, ResetTour and the noted steps done again, Quiet off, then a final DayOne Reset
-- (ruling F6), then ProfileRestore and the career hook's Publish (its Money read fresh); the error is rethrown after. On
-- success it then checks DayOneBusy nil and the money, XP, level, owned and equipped gear and tour as noted. The marker
-- line carries the elapsed seconds, the cleanup included (the budget is 90).
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local RED = " (before the D1-T3 sync of Systems/DayOne, Systems/Contracts, Systems/Gear and Systems/Tour: the expected red)"
local d1 = SOK:WaitForChild("_StudioDayOneHook", 5); assert(d1, "no _StudioDayOneHook (is Systems/DayOne synced and started?)")
local rooms = SOK:WaitForChild("_StudioRoomsHook", 5); assert(rooms, "no _StudioRoomsHook (is Systems/Rooms synced and started?)")
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local Config = require(RS.OK.Config)
local C = Config.DayOne
assert(type(C) == "table", "Config.DayOne missing")
local D = require(RS.OK.Data.DayOne)
local Rules = require(RS.OK.Modules.DayOneRules)
local Format = require(RS.OK.Modules.Format)
local Artists = require(RS.OK.Data.Artists)
local DAWCfg = require(RS.OK.Modules.DAWConfig)
local Check = require(RS.OK.Modules.BriefCheck)
local Content = require(RS.OK.Data.WalkIns)
local Tour = require(RS.OK.Systems.Tour) -- its Steps and RewardXP only
local Contracts = require(RS.OK.Systems.Contracts) -- its DeliverCooldown only
local NP = RS.OK.NowPlaying
local LOUNGE = Vector3.new(24, 3, 0)
local PC_SPOT = Vector3.new(72.0, 3.5, -5.5) -- in front of the studio PC (t17b, t21d, t105a, t106a)
-- the entry corridor (hub; its floor arrows' walkway, 05_lounge_corridor): ~18 studs from the lounge bar's laptop
-- (14_stations: 18, 3.4, -8.4), the nearest beat-making spot; the lounge spot is ~10 from it
local CORRIDOR = Vector3.new(7, 3, 5)
local BPM = 140
local STARTER = Rules.Starter(Artists.Briefs)
local J1 = STARTER and Artists.BriefById[STARTER.id]
local function gearRow(id) for _, g in ipairs(Config.Gear) do if g.id == id then return g end end; return nil end
local GOAL = gearRow("spk_monitors")
local TOOL = gearRow("rollfx")
local out = {}
local T0 = os.clock()
local tourBefore, gearBefore -- noted first thing in run(); the cleanup puts them back
local k -- the player's slot (run())
local released = false -- case 9 released the slot: the cleanup claims one again
local lastDeliver = -math.huge -- os.clock() of this file's last Deliver call (Contracts.DeliverCooldown)

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function root() local c = p.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = p.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function name(inst) return typeof(inst) == "Instance" and inst:GetFullName() or tostring(inst) end
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
local function call(cmd, a, b, c) return d1:Invoke(cmd, uid, a, b, c) end
local function state(label)
	local s = call("State")
	assert(type(s) == "table", label .. ": the DayOne hook's State answered " .. tostring(s) .. ", want a table")
	return s
end
local function busy() return p:GetAttribute("DayOneBusy") end
-- the DayOne actions since the last read (drains the log)
local function sent(label)
	local l = call("Sent")
	assert(type(l) == "table", label .. ": the DayOne hook's Sent answered " .. tostring(l) .. ", want a list")
	return l
end
local function find(list, kind, id)
	for _, e in ipairs(list) do if e.kind == kind and (id == nil or e.id == id) then return e end end
	return nil
end
local function kinds(list)
	local t = {}
	for _, e in ipairs(list) do
		table.insert(t, tostring(e.kind) .. (e.id and (":" .. tostring(e.id)) or "") .. (e.why and ("(" .. tostring(e.why) .. ")") or "")
			.. (e.text and (" '" .. tostring(e.text) .. "'") or ""))
	end
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
local function ownedGear()
	local pr = prof()
	local ids = {}
	local g = type(pr) == "table" and type(pr.gear) == "table" and pr.gear or {}
	for id, on in pairs(g) do if on == true then table.insert(ids, id) end end
	table.sort(ids)
	return ids
end
local function setGear(ids)
	assert(test:Invoke("ResetGear", uid) == true, "ResetGear failed")
	if #ids > 0 then assert(test:Invoke("GrantGear", uid, table.concat(ids, ",")) == true, "GrantGear(" .. table.concat(ids, ",") .. ") failed") end
end
-- the tour as it was noted: its steps done again (a finished tour finished again, as t104a's cleanup does)
local function restoreTour(before)
	for _, s in ipairs(Tour.Steps) do
		if before.done or before.got[s.id] then test:Invoke("TourAdvance", uid, s.id) end
	end
end
local function advance(label, ids)
	for _, id in ipairs(ids) do assert(test:Invoke("TourAdvance", uid, id) == true, label .. ": TourAdvance(" .. id .. ") failed") end
	task.wait(0.3) -- Tour.Changed's handlers run (no chain yet, or the chain's: nothing to read here)
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
local function bedroom(label)
	local plot = workspace:FindFirstChild("OK_Plots") and workspace.OK_Plots:FindFirstChild(string.format("Plot_%02d", k))
	local bed = plot and plot:FindFirstChild("Room_bedroom")
	assert(bed, label .. string.format(": Workspace.OK_Plots.Plot_%02d has no Room_bedroom", k))
	return bed
end
-- at the laptop: the stand spot, room-local (2, 0, -3), where DAW.StationOf names your bedroom's laptop and its room
local function atLaptop(label)
	unseat()
	local bed = bedroom(label)
	teleport((bed:GetPivot() * CFrame.new(2, 0, -3)).Position + Vector3.new(0, 3, 0))
	local so = rooms:Invoke("StationOf", uid)
	assert(type(so) == "table" and so.room == bed, label .. ": at the stand spot StationOf names " .. name(so and so.inst) .. " / "
		.. name(so and so.room) .. ", want the bedroom's laptop / the bedroom")
	return bed
end
-- the take step got (Picked's handler runs a frame late)
local function takeGot(label)
	assert(waitFor(function() return tourNow().got.take == true end, 2), label .. ": the tour's take step isn't got 2 s after the pick (got: " .. gotList(tourNow()) .. ")")
end
-- money once it settles (the bonus is paid by Day One's Delivered handler, a frame late): exactly `want`
local function moneyIs(want, label)
	waitFor(function() return money() == want end, 2)
	task.wait(0.3)
	local got = money()
	assert(got == want, string.format("%s: money is %s, want %s (%+d off)", label, Format.Money(got), Format.Money(want), got - want))
end
local function xpIs(want, label)
	waitFor(function() return xp() == want end, 2)
	task.wait(0.3)
	local got = xp()
	assert(got == want, string.format("%s: XP is %d, want %d (%+d off)", label, got, want, got - want))
end
-- card `id` queued (or already out: the 1 s loop can send it first), polled for 2 s
local function queued(label, id)
	local s
	local ok = waitFor(function()
		s = state(label)
		return (s.pending and s.pending.id == id) or (s.card and s.card.id == id)
	end, 2)
	assert(ok, label .. ": no " .. id .. " card queued 2 s later (card " .. tostring(s and s.card and s.card.id) .. ", pending "
		.. tostring(s and s.pending and s.pending.id) .. ", tour " .. gotList(tourNow()) .. ")")
	return s
end
-- Age(s), Tick, then the arrive of card `id` in Sent (sent by that Tick or already by the loop); the list and the arrive
local function tickTo(label, s, id)
	assert(call("Age", s) == true and call("Tick") == true, label .. ": Age or Tick failed")
	local l = sent(label)
	local arr = find(l, "arrive", id)
	assert(arr and type(arr.payload) == "table" and type(arr.payload.card) == "table", label .. ": Age(" .. s .. ") and a Tick sent "
		.. kinds(l) .. ", want arrive:" .. id)
	assert(arr.payload.card.id == "day1_" .. id, label .. ": the card's id is " .. tostring(arr.payload.card.id) .. ", want day1_" .. id)
	return l, arr
end
local function choose(label, index)
	local r = call("Choose", index)
	assert(type(r) == "table" and r.ok == true, label .. ": Choose(" .. index .. ") answered ok " .. tostring(type(r) == "table" and r.ok or r)
		.. ", reason " .. tostring(type(r) == "table" and r.reason) .. "; want ok")
end
-- Contracts.Deliver through the DayOne hook, after the delivery cooldown; the reply, which must be a pass
local function deliver(label, pattern)
	local left = Contracts.DeliverCooldown + 0.15 - (os.clock() - lastDeliver)
	if left > 0 then task.wait(left) end
	local res = call("Deliver", pattern, BPM, 0)
	lastDeliver = os.clock()
	assert(type(res) == "table", label .. ": the DayOne hook's Deliver answered " .. tostring(res) .. ", want Contracts.Deliver's reply" .. RED)
	assert(res.ok == true, label .. ": the delivery was refused: " .. tostring(res.reason) .. (res.changed and (" (" .. tostring(res.changed) .. " pads changed)") or "")
		.. "; want ok")
	assert(type(res.cred) == "number", label .. ": the delivery's reply has cred " .. tostring(res.cred) .. ", want a number")
	return res
end
local function npSnap() return { token = NP:GetAttribute("Token"), active = NP:GetAttribute("Active") == true, queue = NP:GetAttribute("QueueCount") or 0 } end
local function chainEnded(label)
	assert(waitFor(function() return busy() == false end, 2), label .. ": DayOneBusy is " .. tostring(busy()) .. " after the chain's end, want false")
	local s = state(label)
	assert(not s.running and s.done == true, label .. ": the chain still runs (card " .. tostring(s.card and s.card.id) .. ", pending "
		.. tostring(s.pending and s.pending.id) .. "), want it ended")
end

-- the beats ------------------------------------------------------------------------------------------------------------
local STEPS = DAWCfg.Steps
local function row(hits) local t = table.create(STEPS, "0"); for _, s in ipairs(hits) do t[s] = "1" end; return table.concat(t) end
-- DAWConfig.DefaultPattern with the named tracks' rows replaced (DAWConfig.Tracks order, STEPS each; the rest kept)
local function withRows(rows)
	local pat = DAWCfg.DefaultPattern
	for i, tr in ipairs(DAWCfg.Tracks) do
		local r = rows[tr.Name]
		if r then
			local a = (i - 1) * STEPS
			pat = pat:sub(1, a) .. r .. pat:sub(a + STEPS + 1)
		end
	end
	return pat
end
local function j1Beat()
	return withRows({ Kick = row({ 1 }), Snare = row({ 5, 13 }), Clap = row({}), Hat = row({ 2, 4, 6, 8, 10, 12, 14, 16 }) })
end
local function j1BeatB()
	return withRows({ Kick = row({ 1, 9, 11 }), Snare = row({ 5, 13 }), Clap = row({ 3, 7, 11, 15 }), Hat = row({ 1, 2, 4, 5, 6, 8, 9, 10, 12, 13, 14, 16 }) })
end
local function checkBeat(label, pat, extra)
	assert(#pat == #DAWCfg.DefaultPattern, label .. " is " .. #pat .. " characters, want " .. #DAWCfg.DefaultPattern)
	local res = Check.Check(DAWCfg, J1, pat, BPM, 0)
	assert(res.passed and res.stars == 3, label .. ": BriefCheck on j1 at " .. BPM .. " BPM: passed " .. tostring(res.passed) .. ", " .. tostring(res.stars) .. " stars; want 3")
	local ch = Check.Changed(pat, Check.References(DAWCfg, extra))
	assert(ch >= Check.MinChanged, label .. ": " .. ch .. " pads from the nearest reference beat, want at least " .. Check.MinChanged)
	return ch
end

-- the file's own fresh(): unseated in the lounge, Quiet on, the phone, WalkIns, Career and Life reset, no hint seen, no
-- gear, the rooms hook's Reset (slot claimed, plot rebuilt), the DayOne Reset, ResetTour, ResetSessions, and today's
-- Delivery counts (XP and money) cleared
local function fresh(label)
	unseat()
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, label .. ": Quiet(true) failed")
	assert(ph:Invoke("Reset", uid) == true, label .. ": phone Reset failed")
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	assert(life:Invoke("Reset", uid) == true, label .. ": Life Reset failed")
	assert(test:Invoke("ResetHints", uid) == true, label .. ": ResetHints failed")
	setGear({})
	assert(rooms:Invoke("Reset", uid) == true, label .. ": the rooms hook's Reset failed (no slot, or the plot did not build)")
	assert(call("Reset") == true, label .. ": the DayOne hook's Reset answered something else than true")
	assert(test:Invoke("ResetTour", uid) == true, label .. ": ResetTour failed")
	assert(test:Invoke("ResetSessions", uid) == true, label .. ": ResetSessions failed")
	assert(test:Invoke("ResetXPCount", uid, "Delivery") == true, label .. ": ResetXPCount(Delivery) failed")
	assert(career:Invoke("ResetCredCount", uid, "Delivery") == true, label .. ": the career hook's ResetCredCount(Delivery) failed")
end
-- before every case: settled, everything Day One touches reset, the player in the bedroom at the laptop, all checked
local function between(label)
	task.wait(0.3) -- the last case's late handlers (Delivered, Picked, Played, Tour.Changed) run before the resets
	assert(call("Reset") == true, label .. ": the DayOne Reset failed")
	assert(test:Invoke("ResetTour", uid) == true, label .. ": ResetTour failed")
	assert(test:Invoke("ResetSessions", uid) == true, label .. ": ResetSessions failed")
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed")
	unseat()
	assert(rooms:Invoke("WakeUp", uid) == true, label .. ": WakeUp returned false")
	task.wait(0.3) -- the resets' own late handlers (Tour.Changed "reset") run
	placeIs(k .. "/bedroom", label .. " WakeUp")
	atLaptop(label)
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

local profBefore -- the profile as ProfileMark noted it (a copy, for the cleanup's checks)
local function run()
	profBefore = prof()
	local mk = test:Invoke("ProfileMark", uid)
	assert(mk == true, "the test hook's ProfileMark answered " .. tostring(mk) .. ", want true (sync ServerScriptService/OK/Main: D1-T3 fix 1)")
	tourBefore, gearBefore = tourNow(), ownedGear()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	assert(J1 and J1.id == "j1", "the starter brief is " .. tostring(J1 and J1.id) .. ", want j1")
	assert(GOAL and TOOL, "Config.Gear has no spk_monitors or rollfx row")
	local A, B = j1Beat(), j1BeatB()
	local chA = checkBeat("j1Beat()", A, {})
	local chB = checkBeat("j1BeatB()", B, {})
	local chAB = checkBeat("j1BeatB() against j1Beat() as the last delivery", B, { A })
	table.insert(out, string.format("beats: j1Beat() and j1BeatB() pass j1 for 3 stars at %d BPM; %d and %d pads from the references, B %d from A (MinChanged %d)",
		BPM, chA, chB, chAB, Check.MinChanged))
	fresh("start")
	local info = rooms:Invoke("Plot", uid)
	k = type(info) == "table" and info.slot
	assert(k, "the rooms hook's Plot answered " .. tostring(info) .. ", want the player's slot")
	local f = RS.OK:FindFirstChild("RoomPlaying") and RS.OK.RoomPlaying:FindFirstChild(string.format("Plot_%02d", k))
	assert(f, string.format("ReplicatedStorage.OK.RoomPlaying.Plot_%02d missing (build/19_rooms.lua)", k))

	-- 1. the haggle, a delivery at your laptop: the bonus once, then card 2
	between("1")
	local m1 = money()
	assert(call("Start") == "dayone", "1: Start didn't answer dayone")
	sent("1")
	assert(call("SetRoll", 0.1) == true, "1: SetRoll failed")
	choose("1 haggle", 2)
	takeGot("1")
	assert(active() == "j1", "1: the active request is " .. tostring(active()) .. " after the haggle, want j1")
	local h1 = state("1").d1
	assert(type(h1) == "table" and h1.haggle == "good" and h1.paid ~= true, "1: d1 is haggle " .. tostring(h1 and h1.haggle) .. ", paid "
		.. tostring(h1 and h1.paid) .. " before the delivery; want good and unpaid")
	sent("1") -- the haggle's toast and opendaw (t121a case 5)
	local r1 = deliver("1", A)
	assert(r1.stars == 3 and r1.again ~= true and r1.brief == "j1", "1: the delivery answered " .. tostring(r1.stars) .. " stars, again "
		.. tostring(r1.again) .. ", brief " .. tostring(r1.brief) .. "; want 3, a first delivery of j1")
	local s1 = queued("1", "speakers")
	if s1.pending then
		assert(math.abs(s1.pending.at - s1.now - C.AfterDeliver) < 1, string.format("1: card 2 is queued %.2f s out, want about %d (AfterDeliver)",
			s1.pending.at - s1.now, C.AfterDeliver))
	end
	moneyIs(m1 + r1.cred + C.HaggleBonus, "1 (the delivery's cred " .. r1.cred .. " + the haggle's " .. C.HaggleBonus .. ")" .. RED)
	local d1a = state("1").d1
	assert(type(d1a) == "table" and d1a.paid == true, "1: d1.paid is " .. tostring(d1a and d1a.paid) .. " after the bonus, want true")
	assert(tourNow().got.deliver == true, "1: the tour's deliver step isn't got after the delivery (" .. gotList(tourNow()) .. ")")
	local _, arr1 = tickTo("1 card 2", C.AfterDeliver, "speakers")
	local c2 = arr1.payload.card
	assert(arr1.payload.now == true, "1: card 2's payload has now " .. tostring(arr1.payload.now) .. ", want true (shown over the beat maker)")
	assert(c2.line == D.Cards.speakers.line and type(c2.choices) == "table" and #c2.choices == 2, "1: card 2 reads '" .. tostring(c2.line)
		.. "' with " .. tostring(type(c2.choices) == "table" and #c2.choices) .. " choices, want '" .. D.Cards.speakers.line .. "' and 2")
	local s1b = state("1")
	assert(s1b.card and s1b.card.id == "speakers" and s1b.card.token == arr1.token, "1: the open card is " .. tostring(s1b.card and s1b.card.id) .. ", want card 2")
	assert(s1b.beat and s1b.beat.pattern == A and s1b.beat.bpm == BPM, "1: the chain's beat is " .. (s1b.beat and ((s1b.beat.pattern == A and "j1Beat()" or "another")
		.. " at " .. tostring(s1b.beat.bpm)) or "none") .. ", want j1Beat() at " .. BPM)
	table.insert(out, string.format("1 haggle good; j1Beat() delivered for 3 stars: +%s (cred %d + bonus %d), d1.paid; card 2 queued, sent with now = true",
		Format.Money(money() - m1), r1.cred, C.HaggleBonus))

	-- 2. a repeat delivery while card 2 is up: no second bonus, card 2 kept with its beat (no between())
	local m2 = money()
	assert(test:Invoke("SetActiveRequest", uid, "j1") == true, "2: SetActiveRequest(j1) failed")
	local r2 = deliver("2", B)
	assert(r2.again == true, "2: the second j1 delivery answered again " .. tostring(r2.again) .. ", want a repeat")
	moneyIs(m2 + r2.cred, "2 (a repeat's cred " .. r2.cred .. ", no second bonus)")
	local l2 = sent("2")
	assert(not find(l2, "arrive") and not find(l2, "leave"), "2: the repeat delivery sent " .. kinds(l2) .. ", want nothing")
	local s2 = state("2")
	assert(s2.card and s2.card.id == "speakers" and s2.card.token == arr1.token and s2.pending == nil, "2: after the repeat the card is "
		.. tostring(s2.card and s2.card.id) .. " (same token " .. tostring(s2.card and s2.card.token == arr1.token) .. "), pending "
		.. tostring(s2.pending and s2.pending.id) .. "; want card 2 kept and nothing queued (m9)")
	assert(s2.beat and s2.beat.pattern == A, "2: the chain's beat became " .. (s2.beat and (s2.beat.pattern == B and "j1BeatB()" or "another") or "none") .. ", want j1Beat() kept")
	table.insert(out, string.format("2 j1BeatB() delivered again (repeat): +%s, no second bonus; card 2 kept, its beat j1Beat()", Format.Money(r2.cred)))

	-- 3. On my speakers: the room play, then card 3 (no between())
	local tok0 = f:GetAttribute("Token") or 0
	local np0 = npSnap()
	choose("3 speakers", 1)
	local tok3 = f:GetAttribute("Token")
	assert(f:GetAttribute("Active") == true and type(tok3) == "number" and tok3 > tok0, "3: " .. f:GetFullName() .. " Active " .. tostring(f:GetAttribute("Active"))
		.. ", Token " .. tostring(tok3) .. " (was " .. tostring(tok0) .. "); want a new play on")
	assert(f:GetAttribute("Beat") == A and f:GetAttribute("BPM") == BPM and f:GetAttribute("Room") == "bedroom" and f:GetAttribute("Tier") == 1
		and f:GetAttribute("Kit") == "studio" and f:GetAttribute("OwnerId") == uid, string.format("3: the room play reads %s at %s BPM, Room %s, Tier %s, Kit %s, OwnerId %s; want j1Beat() at %d, bedroom, 1, studio, %d",
		f:GetAttribute("Beat") == A and "j1Beat()" or (f:GetAttribute("Beat") == B and "j1BeatB()" or "another beat"), tostring(f:GetAttribute("BPM")),
		tostring(f:GetAttribute("Room")), tostring(f:GetAttribute("Tier")), tostring(f:GetAttribute("Kit")), tostring(f:GetAttribute("OwnerId")), BPM, uid))
	local np3 = npSnap()
	assert(np3.token == np0.token and np3.active == np0.active and np3.queue == np0.queue, string.format("3: NowPlaying moved: Token %s -> %s, Active %s -> %s, QueueCount %s -> %s",
		tostring(np0.token), tostring(np3.token), tostring(np0.active), tostring(np3.active), tostring(np0.queue), tostring(np3.queue)))
	local l3 = sent("3")
	local play3, toast3 = find(l3, "play"), find(l3, "toast")
	assert(find(l3, "leave", "speakers") and play3 and play3.ok == true, "3: On my speakers sent " .. kinds(l3) .. ", want card 2's leave and an ok play")
	assert(toast3 and toast3.text == D.Toasts.speakers, "3: the toast reads " .. tostring(toast3 and toast3.text) .. ", want '" .. D.Toasts.speakers .. "'")
	assert(waitFor(function() return tourNow().got.monitors == true end, 2), "3: the tour's monitors step isn't got after the room play (" .. gotList(tourNow()) .. ")")
	queued("3", "spend")
	local _, arr3 = tickTo("3 card 3", C.AfterSpeakers, "spend")
	local line3 = tostring(arr3.payload.card.line)
	local cash = Format.Money(money())
	assert(line3:find(cash, 1, true) and line3:find(TOOL.name, 1, true) and line3:find(GOAL.name, 1, true), "3: card 3 reads '" .. line3
		.. "', want your money " .. cash .. ", " .. TOOL.name .. " and " .. GOAL.name)
	assert(not line3:find("{", 1, true), "3: card 3's line keeps a token: " .. line3)
	table.insert(out, string.format("3 On my speakers: Plot_%02d Token %d, j1Beat() at %d, bedroom, Tier 1; NowPlaying untouched; play + toast; monitors got; card 3 '%s'",
		k, tok3, BPM, line3))

	-- 4. Hit the gear rack at the laptop: the Gear tab, the tour done, the first visitor (no between())
	local bed4 = bedroom("4")
	local rack = bed4:FindFirstChild("RackSpot")
	assert(rack and rack:IsA("BasePart"), "4: Room_bedroom has no RackSpot part")
	local dr = dist(rack)
	assert(dr <= Config.Interaction.PanelCloseDistance, string.format("4: at the laptop the RackSpot is %.1f studs away, want at most %d (the precondition)",
		dr, Config.Interaction.PanelCloseDistance))
	local x4 = xp()
	choose("4 rack", 1)
	local l4 = sent("4")
	local og = find(l4, "opengear")
	assert(og and og.text == rack:GetFullName(), "4: Hit the gear rack sent " .. kinds(l4) .. ", want opengear at " .. rack:GetFullName() .. RED)
	assert(find(l4, "leave", "spend") and not find(l4, "toast"), "4: Hit the gear rack sent " .. kinds(l4) .. ", want card 3's leave and no toast")
	local t4 = tourNow()
	assert(t4.done and not t4.skipped, "4: after the rack the tour is " .. gotList(t4) .. ", want done, not skipped")
	xpIs(x4 + Tour.RewardXP, "4 (the tour's +" .. Tour.RewardXP .. " once)")
	chainEnded("4")
	local rem4 = wi:Invoke("GetRemaining", uid)
	assert(type(rem4) == "number" and rem4 >= C.VisitAfter[1] and rem4 <= C.VisitAfter[2], "4: the walk-in timer is " .. tostring(rem4)
		.. " after card 3, want " .. C.VisitAfter[1] .. ".." .. C.VisitAfter[2] .. " (WalkIns.ArmFirst)")
	placeIs(k .. "/bedroom", "4 before the Poke")
	local poke4 = wi:Invoke("Poke", uid)
	assert(poke4 == true, "4: a Poke in the bedroom after Day One answered " .. tostring(poke4) .. ", want a visit")
	local v4 = wi:Invoke("Pending", uid)
	local card4 = v4 and Content.CardById[v4.id]
	assert(card4 and card4.first == true, "4: the first visit is " .. tostring(v4 and v4.id) .. ", want a Data/WalkIns card with first = true")
	table.insert(out, string.format("4 Hit the gear rack (%.1f studs from the RackSpot): opengear, tour done, +%d XP once, DayOneBusy false, timer %s, Poke -> %s (first) in %s",
		dr, Tour.RewardXP, tostring(rem4), v4.id, placeNow()))

	-- 5. make, deliver, Keep it private, Save it; then a second private pays nothing
	between("5")
	local m5 = money()
	assert(call("Start") == "dayone", "5: Start didn't answer dayone")
	choose("5 make", 1)
	takeGot("5")
	sent("5")
	local r5 = deliver("5", A)
	queued("5", "speakers")
	moneyIs(m5 + r5.cred, "5 (the delivery's cred " .. r5.cred .. ", no haggle: no bonus)")
	tickTo("5 card 2", C.AfterDeliver, "speakers")
	local x5 = xp()
	choose("5 private", 2)
	xpIs(x5 + C.PrivateXP, "5 private (+" .. C.PrivateXP .. ")")
	local l5 = sent("5 private")
	local toast5 = find(l5, "toast")
	local privateText = Rules.Fill(D.Toasts.private, { xp = C.PrivateXP })
	assert(toast5 and toast5.text == privateText and not find(l5, "play"), "5: Keep it private sent " .. kinds(l5) .. ", want the toast '" .. privateText .. "' and no play")
	local d5 = state("5").d1
	assert(type(d5) == "table" and d5.private == true, "5: d1.private is " .. tostring(d5 and d5.private) .. ", want true")
	assert(tourNow().got.monitors == true, "5: the monitors step isn't got after Keep it private (" .. gotList(tourNow()) .. ")")
	queued("5", "spend")
	tickTo("5 card 3", C.AfterSpeakers, "spend")
	local x5b = xp()
	choose("5 save", 2)
	local l5b = sent("5 save")
	assert(find(l5b, "leave", "spend") and not find(l5b, "opengear") and not find(l5b, "toast"), "5: Save it sent " .. kinds(l5b) .. ", want card 3's leave only")
	local t5 = tourNow()
	assert(t5.done and not t5.skipped, "5: after Save it the tour is " .. gotList(t5) .. ", want done")
	xpIs(x5b + Tour.RewardXP, "5 save (the tour's +" .. Tour.RewardXP .. ")")
	chainEnded("5")
	local x5c = xp()
	assert(call("Show", "speakers") == "speakers", "5: Show(speakers) didn't answer speakers")
	choose("5 private again", 2)
	xpIs(x5c, "5 private again (d1.private already set: +0)")
	chainEnded("5 private again (a staged card 2 on a done tour: the chain ends, DayOneBusy false)")
	table.insert(out, string.format("5 make + deliver (+%s, no bonus); private +%d XP once; save: tour done +%d XP, no opengear; private again +0",
		Format.Money(r5.cred), C.PrivateXP, Tour.RewardXP))

	-- 6. expiry: card 2 as private, card 3 as save
	between("6")
	advance("6", { "take", "deliver" })
	assert(test:Invoke("RecordDelivery", uid, A, BPM, 3) == true, "6: RecordDelivery failed")
	local x6 = xp()
	assert(call("Show", "speakers") == "speakers", "6: Show(speakers) didn't answer speakers")
	local l6 = sent("6")
	assert(find(l6, "arrive", "speakers"), "6: Show(speakers) sent " .. kinds(l6) .. ", want arrive:speakers")
	local s6 = state("6")
	assert(s6.beat and s6.beat.pattern == A and s6.beat.bpm == BPM, "6: the staged card 2's beat isn't Recent[1] (j1Beat() at " .. BPM .. ")")
	assert(call("Age", C.CardSeconds) == true and call("Tick") == true, "6: Age or Tick failed")
	local l6b = sent("6 expire speakers")
	assert(find(l6b, "leave", "speakers") and find(l6b, "toast") and not find(l6b, "play"), "6: card 2's expiry sent " .. kinds(l6b) .. ", want its leave and the private toast, no play")
	xpIs(x6 + C.PrivateXP, "6 expiry as private")
	assert(tourNow().got.monitors == true, "6: the monitors step isn't got after card 2's expiry (" .. gotList(tourNow()) .. ")")
	local s6b = queued("6", "spend")
	assert(s6b.pending and s6b.pending.id == "spend", "6: card 3 isn't queued after card 2's expiry")
	assert(call("Show", "spend") == "spend", "6: Show(spend) didn't answer spend")
	local s6c = state("6")
	assert(s6c.pending == nil and s6c.card and s6c.card.id == "spend", "6: after Show(spend) pending is " .. tostring(s6c.pending and s6c.pending.id)
		.. ", want the queued spend dropped (it is out)")
	sent("6")
	assert(call("Age", C.CardSeconds) == true and call("Tick") == true, "6: Age or Tick failed")
	local l6c = sent("6 expire spend")
	assert(find(l6c, "leave", "spend") and not find(l6c, "opengear") and not find(l6c, "arrive"), "6: card 3's expiry sent " .. kinds(l6c) .. ", want its leave only")
	local t6 = tourNow()
	assert(t6.done and not t6.skipped, "6: after card 3's expiry the tour is " .. gotList(t6) .. ", want done (as save)")
	chainEnded("6")
	table.insert(out, "6 expiry: card 2 as private (+" .. C.PrivateXP .. " XP, monitors got, card 3 queued); Show(spend) drops the queued one; card 3 as save (tour done)")

	-- 7. a delivery with no chain: nothing sent, no bonus, d1 unwritten
	between("7")
	local m7 = money()
	assert(test:Invoke("SetActiveRequest", uid, "j1") == true, "7: SetActiveRequest(j1) failed")
	local r7 = deliver("7", A)
	moneyIs(m7 + r7.cred, "7 (no chain: the delivery's cred " .. r7.cred .. " only)")
	local l7 = sent("7")
	assert(#l7 == 0, "7: a delivery with no chain sent " .. kinds(l7) .. ", want nothing")
	local s7 = state("7")
	assert(not s7.running and s7.pending == nil and s7.card == nil and busy() == nil, "7: a delivery with no chain left a chain (pending "
		.. tostring(s7.pending and s7.pending.id) .. ", DayOneBusy " .. tostring(busy()) .. "), want none")
	assert(s7.d1 == nil, "7: a delivery with no haggle wrote prof.tour.d1, want it left unwritten")
	table.insert(out, "7 no chain: j1 delivered, nothing sent, no chain, +" .. Format.Money(r7.cred) .. " (no bonus), d1 unwritten")

	-- 8. resume on card 2 with the newest recent beat; 8b with none: monitors, then card 3
	between("8")
	advance("8", { "open", "take", "deliver" })
	assert(test:Invoke("RecordDelivery", uid, A, BPM, 3) == true, "8: RecordDelivery failed")
	local n8 = call("Start")
	assert(n8 == "speakers", "8: Start on { open, take, deliver } answered " .. tostring(n8) .. ", want speakers" .. RED)
	local l8 = sent("8")
	local arr8 = find(l8, "arrive", "speakers")
	assert(arr8 and arr8.payload and arr8.payload.now == true, "8: Start sent " .. kinds(l8) .. ", want card 2 at once with now = true")
	local s8 = state("8")
	assert(s8.beat and s8.beat.pattern == A and s8.beat.bpm == BPM, "8: the resumed card 2's beat isn't Recent[1] (j1Beat() at " .. BPM .. ")")
	assert(busy() == true, "8: DayOneBusy is " .. tostring(busy()) .. " with card 2 open, want true")
	between("8b")
	advance("8b", { "open", "take", "deliver" })
	local n8b = call("Start")
	assert(n8b == "spend", "8b: Start with no recent beat answered " .. tostring(n8b) .. ", want spend (monitors advanced)")
	local l8b = sent("8b")
	assert(find(l8b, "arrive", "spend") and not find(l8b, "arrive", "speakers"), "8b: Start sent " .. kinds(l8b) .. ", want card 3 at once and no card 2")
	assert(tourNow().got.monitors == true, "8b: the monitors step isn't got (" .. gotList(tourNow()) .. ")")
	task.wait(0.3) -- the deferred monitors event queues nothing more (card 3 is open)
	local s8b = state("8b")
	assert(s8b.pending == nil and s8b.card and s8b.card.id == "spend", "8b: after the monitors event pending is " .. tostring(s8b.pending and s8b.pending.id) .. ", want none")
	table.insert(out, "8 resume { open, take, deliver }: Start -> speakers at once, beat Recent[1]; 8b with no recent beat: monitors advanced, Start -> spend at once")

	-- 10 (before 9, which releases the plot). B3's real path: ON MONITORS before any delivery
	between("10")
	advance("10", { "open", "take", "monitors" })
	local n10 = call("Start")
	assert(n10 == nil, "10: Start on { open, take, monitors } answered " .. tostring(n10) .. ", want nil (making the beat: no card)")
	local s10 = state("10")
	assert(s10.running and s10.card == nil and s10.pending == nil and s10.next == nil, "10: before the delivery the chain runs "
		.. tostring(s10.running) .. " with card " .. tostring(s10.card and s10.card.id) .. ", pending " .. tostring(s10.pending and s10.pending.id) .. ", next "
		.. tostring(s10.next) .. "; want a running chain and no card")
	assert(#sent("10") == 0, "10: Start sent something before the delivery")
	assert(test:Invoke("SetActiveRequest", uid, "j1") == true, "10: SetActiveRequest(j1) failed")
	unseat()
	teleport(PC_SPOT)
	deliver("10", A)
	local q10 = queued("10", "spend")
	if q10.pending then
		assert(math.abs(q10.pending.at - q10.now - C.AfterDeliver) < 1, string.format("10: card 3 is queued %.2f s out, want about %d (AfterDeliver)",
			q10.pending.at - q10.now, C.AfterDeliver))
	end
	tickTo("10 card 3", C.AfterDeliver, "spend")
	choose("10 save", 2)
	local t10 = tourNow()
	assert(t10.done and not t10.skipped, "10: after Save it the tour is " .. gotList(t10) .. ", want done")
	chainEnded("10")
	table.insert(out, "10 B3: { open, take, monitors } -> Start nil (no card), a delivery at the studio PC queues spend, sent, Save it: tour done")

	-- 11 (before 9). The haggle, then the pill's SKIP, then the first delivery: +$50 once
	between("11")
	assert(call("Start") == "dayone", "11: Start didn't answer dayone")
	assert(call("SetRoll", 0.1) == true, "11: SetRoll failed")
	choose("11 haggle", 2)
	takeGot("11")
	local h11 = state("11").d1
	assert(type(h11) == "table" and h11.haggle == "good", "11: d1.haggle is " .. tostring(h11 and h11.haggle) .. ", want good")
	assert(test:Invoke("TourSkip", uid) == true, "11: the test hook's TourSkip failed (sync ServerScriptService/OK/Main)")
	local t11 = tourNow()
	assert(t11.done and t11.skipped, "11: after SKIP the tour is " .. gotList(t11) .. ", want done and skipped")
	chainEnded("11 SKIP")
	sent("11")
	local m11 = money()
	local r11 = deliver("11", A)
	assert(r11.stars == 3 and r11.again ~= true and r11.brief == "j1", "11: the delivery after SKIP answered " .. tostring(r11.stars) .. " stars, again "
		.. tostring(r11.again) .. ", brief " .. tostring(r11.brief) .. "; want 3, a first delivery of j1")
	moneyIs(m11 + r11.cred + C.HaggleBonus, "11 (after SKIP: the delivery's cred " .. r11.cred .. " + the haggle's " .. C.HaggleBonus .. ")")
	local d11 = state("11").d1
	assert(type(d11) == "table" and d11.paid == true, "11: d1.paid is " .. tostring(d11 and d11.paid) .. " after the bonus, want true")
	local l11 = sent("11")
	assert(#l11 == 0, "11: a delivery after SKIP sent " .. kinds(l11) .. ", want nothing (the chain is over)")
	assert(test:Invoke("ResetSessions", uid) == true, "11: ResetSessions failed")
	assert(test:Invoke("SetActiveRequest", uid, "j1") == true, "11: SetActiveRequest(j1) failed")
	local m11b = money()
	local r11b = deliver("11 again", A)
	assert(r11b.again ~= true, "11: after ResetSessions j1 answered again " .. tostring(r11b.again) .. ", want a first delivery again")
	moneyIs(m11b + r11b.cred, "11 again (d1.paid: the delivery's cred " .. r11b.cred .. " only, no second bonus)")
	table.insert(out, string.format("11 haggle good, SKIP (tour done + skipped), then j1: +%s (cred %d + bonus %d), d1.paid; j1 first again: +%s, no second bonus",
		Format.Money(r11.cred + C.HaggleBonus), r11.cred, C.HaggleBonus, Format.Money(r11b.cred)))

	-- 9. a hub delivery (no card 2), ON SPEAKERS at the laptop, then no plot: rackFar
	between("9")
	unseat()
	teleport(CORRIDOR)
	placeIs("hub", "9 corridor")
	local so9 = rooms:Invoke("StationOf", uid)
	local near9 = type(so9) == "table" and so9.inst or nil
	assert(near9 == nil or dist(near9) > DAWCfg.CloseDistance, string.format("9: in the corridor %s is %.1f studs away, want none within %d (the precondition)",
		name(near9), near9 and dist(near9) or 0, DAWCfg.CloseDistance))
	assert(call("Start") == "dayone", "9: Start didn't answer dayone")
	sent("9")
	choose("9 make", 1)
	local l9 = sent("9")
	local toast9 = find(l9, "toast")
	assert(toast9 and toast9.text == D.Toasts.farHub and not find(l9, "opendaw"), "9: Make it now in the corridor sent " .. kinds(l9) .. ", want the toast '" .. D.Toasts.farHub .. "'")
	takeGot("9")
	assert(active() == "j1", "9: the active request is " .. tostring(active()) .. ", want j1")
	teleport(PC_SPOT)
	deliver("9", A)
	assert(waitFor(function() return tourNow().got.deliver == true end, 2), "9: the deliver step isn't got after the hub delivery")
	task.wait(0.5) -- Day One's Delivered handler has run
	local s9 = state("9")
	assert(s9.pending == nil and s9.card == nil and s9.next == "speakers", "9: after a hub delivery pending is " .. tostring(s9.pending and s9.pending.id)
		.. ", card " .. tostring(s9.card and s9.card.id) .. ", next " .. tostring(s9.next) .. "; want no card 2 (the pill's ON MONITORS step)")
	local l9b = sent("9")
	assert(not find(l9b, "arrive"), "9: a hub delivery sent " .. kinds(l9b) .. ", want no card")
	atLaptop("9")
	local play9 = rooms:Invoke("Play", uid, A, BPM)
	assert(type(play9) == "table" and play9.ok == true and play9.room == true, "9: the rooms hook's Play at the laptop answered ok "
		.. tostring(type(play9) == "table" and play9.ok or play9) .. ", room " .. tostring(type(play9) == "table" and play9.room) .. ", reason "
		.. tostring(type(play9) == "table" and play9.reason) .. "; want a room play")
	queued("9", "spend")
	assert(tourNow().got.monitors == true, "9: the monitors step isn't got after the room play (" .. gotList(tourNow()) .. ")")
	tickTo("9 card 3", C.AfterSpeakers, "spend")
	pcall(function() rooms:Invoke("Stop", uid) end)
	released = true -- set first: the cleanup claims a slot again even if Release throws midway
	assert(rooms:Invoke("Release", uid) == true, "9: the rooms hook's Release failed")
	assert(rooms:Invoke("Station", uid) == nil, "9: after Release the rooms hook's Station is " .. name(rooms:Invoke("Station", uid)) .. ", want none")
	choose("9 rack", 1)
	local l9c = sent("9 rack")
	local toast9c = find(l9c, "toast")
	assert(toast9c and toast9c.text == D.Toasts.rackFar and not find(l9c, "opengear"), "9: Hit the gear rack with no plot sent " .. kinds(l9c)
		.. ", want the toast '" .. D.Toasts.rackFar .. "' and no opengear")
	local t9 = tourNow()
	assert(t9.done and not t9.skipped, "9: after the rack the tour is " .. gotList(t9) .. ", want done")
	chainEnded("9")
	table.insert(out, "9 corridor: farHub; hub delivery: no card 2; Play at the laptop: card 3; released: rackFar, tour done")

	return table.concat(out, "\n") .. string.format("\nthe cases took %.1f s", os.clock() - T0)
end

local ok, msg = pcall(run)
pcall(function() RS.OK:SetAttribute("WalkInsPaused", true) end)
pcall(function() d1:Invoke("Reset", uid) end) -- first: no chain sees the tour restored
pcall(function() rooms:Invoke("Stop", uid) end) -- any room play of the player's
pcall(unseat)
pcall(teleport, LOUNGE) -- the beat maker and the Gear tab close out here; first, so no rebuild happens under the player
pcall(function() if released then rooms:Invoke("Claim", uid) end end)
pcall(function() if gearBefore then setGear(gearBefore) end end)
pcall(function() rooms:Invoke("Reset", uid) end)
pcall(function()
	wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
	test:Invoke("ResetHints", uid); test:Invoke("ResetSessions", uid); test:Invoke("ResetTour", uid)
	if tourBefore then restoreTour(tourBefore) end
	ph:Invoke("Quiet", uid, false)
end)
task.wait(0.3) -- the restore's late handlers run (no chain: nothing)
pcall(function() d1:Invoke("Reset", uid) end) -- the last Day One step (F6)
-- the profile as ProfileMark noted it: money, XP and level, gear, gate logs, tour, hints, sessions (D1-T3 fix 1)
local restored
pcall(function() restored = test:Invoke("ProfileRestore", uid) end)
pcall(function() career:Invoke("Publish", uid) end) -- Career_Get's cached Money dropped, the career attributes sent again
local busyLeft = p:GetAttribute("DayOneBusy")
if not ok then error(msg, 0) end
assert(busyLeft == nil, "cleanup: DayOneBusy is " .. tostring(busyLeft) .. " after the final DayOne Reset, want nil")
assert(restored == true, "cleanup: the test hook's ProfileRestore answered " .. tostring(restored) .. ", want true")
-- a flat table ({ [key] = number | string | bool }) as sorted "key=value" text, for the checks below
local function flatText(t)
	local l = {}
	for key, v in pairs(type(t) == "table" and t or {}) do if type(v) ~= "table" then table.insert(l, tostring(key) .. "=" .. tostring(v)) end end
	table.sort(l)
	return table.concat(l, ",")
end
local after = prof()
local function tourText(t)
	t = type(t) == "table" and t or {}
	return flatText(t.got) .. (t.done and " done" or "") .. (t.skipped and " skipped" or "")
end
local checks = {
	{ "money", tonumber(after.cred) or 0, tonumber(profBefore.cred) or 0 },
	{ "XP", tonumber(after.xp) or 0, tonumber(profBefore.xp) or 0 },
	{ "level", after.level, profBefore.level },
	{ "the Cred attribute", p:GetAttribute("Cred"), tonumber(profBefore.cred) or 0 },
	{ "the Level attribute", p:GetAttribute("Level"), profBefore.level },
	{ "the XP attribute", p:GetAttribute("XP"), tonumber(profBefore.xp) or 0 },
	{ "the gear owned", flatText(after.gear), flatText(profBefore.gear) },
	{ "the gear equipped", flatText(after.equip), flatText(profBefore.equip) },
	{ "the tour", tourText(after.tour), tourText(profBefore.tour) },
}
for _, c in ipairs(checks) do
	assert(c[2] == c[3], "cleanup: " .. c[1] .. " is " .. tostring(c[2]) .. " after ProfileRestore, want " .. tostring(c[3]) .. " as noted")
end
return string.format("T122A PLAY OK (elapsed %.1f s, the cleanup included)\n", os.clock() - T0) .. msg
	.. string.format("\ncleanup: money %s, XP %d, level %d, gear and tour as noted", Format.Money(tonumber(after.cred) or 0), tonumber(after.xp) or 0, after.level or 0)
