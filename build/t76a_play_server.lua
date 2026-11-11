-- Server, during play (Wave 3 Task 2 and its fix round 1; design 4.4 and 4.5; Review Focus 4), before t76b: the first
-- card in 20 s and the explainers. The file's own fresh() (unseated in the lounge, Quiet on, WalkIns Reset, Career Reset,
-- Life Reset, then _StudioTestHook ResetHints). The body runs held (WalkInsPaused true) and drives visits through the
-- hooks, with the career day set to 4 (Life SetDay), so a hint's day can't be the fallback 1:
-- (0) ResetTour; WalkIns Reset leaves count 0. (1) A count-0 visit that ends before he arrives (a burst forced with the
-- hook's Rush(2), then Spawn and Expire): the re-arm is a FirstEver draw, BusyDay stays false and no burst is left;
-- count stays 0. (2) The pick at count 0 (Spawn with no id) is gentle_first, and its arrive payload carries no hint: none
-- of the eight Config.Hints terms is in its tag, line or choices (checked against WalkInRules.HintFor on the payload's
-- own texts), so Hints stays empty. (3) At count 1, SetRemaining(nil) and the hold set to false: the loop arms the timer
-- from FirstDelay, not FirstEver. (4) The tour still not done: with a burst forced again, walking away re-arms a plain Gap,
-- BusyDay false, no burst (none starts or runs before the tour). (5) navx_placement (forced): its hint is the first
-- unseen term in its tag, line and choices (placement), and Hints holds placement = 4, nothing else. (6) Its choice 3
-- forced good (CLOUT; Followers set to 1,200 first by a silent Set, so the +1,500 crosses no tier): the result's hint
-- comes from its headline and text, followers = 4. (7) navx_placement again: no second hint; Hints unchanged. (8) The phone:
-- two_sessions popped (Quiet on): the pop's hint, read from the phone hook's Sent, is hit ("the one-hit wonder"). (9) Each
-- term once, every value 4. (10) The news strip: with hit unseen again (ResetHints with placement and followers), Followers
-- set to 6,000 (the HIT's +3,000 crosses no tier) and the news forced good, navx_single's card has no term in its tag,
-- line or choices, so its hint is hit from the news headline (HIT), still one per card.
-- Staging for t76b (the real timer, inside the same pcall): fresh() again, ResetTour (the tour not done), Followers set to
-- 1,200 (tier_known's news crosses no tier), tier_known planted due now, then SetRemaining(nil) (a fresh join's state)
-- and the hold set to false for this file only (present, so no burst and no heal; the phone stays ineligible with the
-- tour not done): the loop arms the first-ever timer from FirstEver, a visit is pending within 25 s of the reset with
-- the tour still not done, then the hold goes back to true and the visit walks on. tier_known arrives (arrival - reset
-- <= 35 s, server time) with the hint followers (its line: "five thousand followers"). A second later Quiet goes off and
-- two_sessions pops with hit still unseen (its hint hit): the hinted DM players get at visit 10, which the client holds
-- behind the walk-in card.
-- Why a planted follow-up: gentle_first, the real first pick, has no term at all, so the hint line can't be checked on
-- it; a due follow-up beats the first card in WalkInRules.Pick, so it rides the same first-ever timer and tour bypass.
-- The player attributes _T76Reset and _T76Arrived (server time) carry the clock to t76b. On success the staged card,
-- the pop and the unfinished tour are left for t76b (it walks away, dismisses and skips the tour); on any error
-- everything is reset (hold true, the tour done, Quiet off) and the error rethrown.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local Config = require(RS.OK.Config)
local Rules = require(RS.OK.Modules.WalkInRules)
local Tour = require(RS.OK.Systems.Tour)
local HINTS, W = Config.Hints, Config.WalkIns
local LOUNGE = Vector3.new(24, 3, 0)
local FIRST, CARD, NEWS, DM, STAGE = "gentle_first", "navx_placement", "navx_single", "two_sessions", "tier_known"
local DAY = 4 -- the career day the body runs on (Life SetDay): never the fallback 1
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
local function profile() return test:Invoke("GetProfile", uid) end
local function walkins() return profile().walkins end
local function tourDone() local t = profile().tour; return type(t) == "table" and t.done == true end
local function pending() return wi:Invoke("Pending", uid) end
local function arrived() local r = pending(); return r ~= nil and r.arrived == true end
local function left() return wi:Invoke("GetRemaining", uid) end
local function busyDay() return p:GetAttribute("BusyDay") == true end
local function careerDay() return life:Invoke("State", uid).day end
local function within(x, range, slack) return type(x) == "number" and x >= range[1] - (slack or 0) and x <= range[2] end
local function hints()
	local h = test:Invoke("Hints", uid)
	assert(type(h) == "table", "Hints(uid) returned " .. typeof(h) .. " (before the Task 2 sync of OK/Main it returns nil: the expected red)")
	return h
end
local function keys(t) local k = {}; for x in pairs(t) do table.insert(k, tostring(x)) end; table.sort(k); return table.concat(k, ",") end
local function hintText(term) for _, h in ipairs(HINTS) do if h.term == term then return h.text end end; return nil end
local function termOf(h) return type(h) == "table" and h.term or nil end
local function show(h) return type(h) == "table" and (tostring(h.term) .. " '" .. tostring(h.text) .. "'") or "none" end
local function add(list, s) if type(s) == "string" and s ~= "" then table.insert(list, s) end end
-- what a card shows that a hint may explain, as sent: the tag, the line and every choice's text
local function cardTexts(card)
	local t = {}
	add(t, card.tag); add(t, card.line)
	for _, c in ipairs(card.choices or {}) do add(t, c.text) end
	return t
end
local function resultTexts(r) local t = {}; add(t, r.headline); add(t, r.text); return t end
-- `got` against WalkInRules.HintFor on `texts` (then `fallback`, when given), `seen` = Hints read before the send
local function expectHint(label, got, texts, seen, fallback)
	local want = Rules.HintFor(texts, seen, HINTS)
	if not want and fallback then want = Rules.HintFor(fallback, seen, HINTS) end
	assert(termOf(got) == termOf(want), label .. ": the hint is " .. show(got) .. "; HintFor on its texts gives " .. show(want)
		.. " (before the Task 2 sync of Systems/WalkIns and Systems/Phone no payload has one: the expected red)")
	if want then assert(got.text == want.text, label .. ": the hint text is '" .. tostring(got.text) .. "', want '" .. want.text .. "'") end
	return want
end
-- an arrive payload's card: its tag, line and choices first, else its news strip (fix round 1)
local function expectArrive(label, a, seen)
	local news = type(a.card.news) == "table" and resultTexts(a.card.news) or nil
	return expectHint(label, a.card.hint, cardTexts(a.card), seen, news)
end
-- the newest "arrive" payload in the walk-in hook's Sent (the read drains it)
local function lastArrive()
	local got
	for _, e in ipairs(wi:Invoke("Sent", uid)) do if e.kind == "arrive" then got = e.payload end end
	return got
end
-- the phone hook's Sent entry for the pop `token` (the read drains it)
local function popSent(token)
	for _, e in ipairs(ph:Invoke("Sent", uid)) do if e.kind == "pop" and e.token == token then return e end end
	return nil
end
local function advanceTour() for _, s in ipairs(Tour.Steps) do test:Invoke("TourAdvance", uid, s.id) end end
local function set(s, label) assert(career:Invoke("Set", uid, s) == true, label .. ": Career Set failed") end
-- the file's own fresh(): unseated and in the lounge, Quiet on, WalkIns, Career and Life reset, no hint seen
local function fresh(label)
	local c = p.Character; local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum and hum.Sit then hum.Sit = false; task.wait(0.4) end
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, label .. ": Quiet(true) failed")
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	assert(life:Invoke("Reset", uid) == true, label .. ": Life Reset failed")
	assert(test:Invoke("ResetHints", uid) == true, label .. ": ResetHints did not return true (before the Task 2 sync of OK/Main it returns nil: the expected red)")
end
-- a forced card (id) or the scheduler's own pick (nil), walked in; returns the arrived record and its arrive payload
local function spawnArrived(label, id)
	wi:Invoke("Sent", uid) -- drained: the arrive read below is this visit's
	assert(wi:Invoke("Spawn", uid, id) == true, label .. ": Spawn(" .. tostring(id) .. ") refused")
	assert(waitFor(arrived, 15), label .. ": he did not arrive within 15 s")
	local a = lastArrive()
	assert(type(a) == "table" and type(a.card) == "table", label .. ": no arrive payload in the hook's Sent")
	return pending(), a
end
local function leave(label, r) assert(wi:Invoke("Choose", uid, r.token, 0).ok == true, label .. ": walk away failed") end
-- `s` seconds with the hold false (the loop ticks: bursts and the heal stay held), then the hold back; returns fn()'s value
local function unheld(label, fn)
	local ok, res = pcall(function()
		assert(wi:Invoke("Pause", uid, false) == true, label .. ": Pause(false) failed")
		return fn()
	end)
	assert(wi:Invoke("Pause", uid, true) == true, label .. ": Pause(true) failed")
	if not ok then error(res, 0) end
	return res
end

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh("first pick")
	assert(test:Invoke("ResetTour", uid) == true, "first pick: ResetTour failed")
	assert(not tourDone(), "first pick: the tour is done after ResetTour")
	assert(walkins().count == 0, "first pick: count is " .. tostring(walkins().count) .. " after WalkIns Reset, want 0")
	assert(next(hints()) == nil, "first pick: Hints holds " .. keys(hints()) .. " after ResetHints")
	assert(life:Invoke("SetDay", uid, DAY) == true and careerDay() == DAY, "first pick: Life SetDay(" .. DAY .. ") did not take")

	-- 1. a count-0 visit that ends before he arrives: FirstEver again, no burst (fix round 1, B)
	assert(wi:Invoke("Rush", uid, 2) == true, "abort: the hook's Rush(2) failed")
	assert(wi:Invoke("Spawn", uid, nil) == true, "abort: Spawn() refused")
	local r0 = pending()
	assert(r0 and r0.id == FIRST and r0.arrived ~= true, "abort: want " .. FIRST .. " pending and not yet arrived, got " .. tostring(r0 and r0.id))
	assert(wi:Invoke("Expire", uid) == true, "abort: Expire found no visit")
	local a0 = left()
	assert(within(a0, W.FirstEver), "abort: the re-arm after a count-0 visit ended early is " .. tostring(a0) .. ", want FirstEver "
		.. W.FirstEver[1] .. ".." .. W.FirstEver[2] .. " (before the fix-round sync: a Gap or a burst's short gap)")
	assert(not busyDay() and wi:Invoke("Rush", uid) == nil, "abort: a burst survived the count-0 re-arm (BusyDay " .. tostring(busyDay()) .. ")")
	assert(walkins().count == 0, "abort: a visit that never arrived counted")
	table.insert(out, "1 count-0 visit ended before arrival (burst forced): re-armed " .. a0 .. " s (FirstEver), BusyDay false, no burst, count 0")

	-- 2. the first pick at count 0: gentle_first, no term, no hint
	local r1, a1 = spawnArrived("first pick", nil)
	assert(r1.id == FIRST and a1.card.id == FIRST, "first pick: the pick at count 0 is " .. tostring(r1.id) .. ", want " .. FIRST)
	expectArrive("first pick", a1, {})
	assert(a1.card.hint == nil, "first pick: " .. FIRST .. " carries the hint " .. show(a1.card.hint))
	assert(next(hints()) == nil, "first pick: a card with no term marked " .. keys(hints()) .. " seen")
	assert(walkins().count == 1, "first pick: count is " .. tostring(walkins().count) .. " after the arrival")
	table.insert(out, "2 first pick at count 0 (tour not done): " .. FIRST .. "; no hint (none of the 8 terms in its tag, line or choices)")

	-- 3. past the first visit the first arm is FirstDelay's
	assert(wi:Invoke("SetRemaining", uid, nil) == true, "FirstDelay: SetRemaining(nil) failed")
	local a3
	unheld("FirstDelay", function()
		assert(waitFor(function() a3 = left(); return type(a3) == "number" end, 2.5), "FirstDelay: the loop did not arm the timer within 2.5 s")
	end)
	assert(within(a3, W.FirstDelay, 3), "FirstDelay: at count 1 the first arm is " .. tostring(a3) .. ", want FirstDelay " .. W.FirstDelay[1]
		.. ".." .. W.FirstDelay[2] .. " (FirstEver is " .. W.FirstEver[1] .. ".." .. W.FirstEver[2] .. ")")
	assert(wi:Invoke("SetRemaining", uid, 1e6) == true, "FirstDelay: SetRemaining(1e6) failed")
	table.insert(out, "3 count 1: the first arm is " .. a3 .. " s (FirstDelay), not FirstEver")

	-- 4. no burst before the tour (fix round 1, C): a forced one ends at the re-arm
	assert(wi:Invoke("Rush", uid, 2) == true, "no burst: the hook's Rush(2) failed")
	leave("no burst", r1)
	local a4 = left()
	assert(not busyDay() and wi:Invoke("Rush", uid) == nil, "no burst: a burst ran with the tour not done (BusyDay " .. tostring(busyDay()) .. ")")
	assert(within(a4, W.Gap), "no burst: the re-arm is " .. tostring(a4) .. ", want a plain Gap " .. W.Gap[1] .. ".." .. W.Gap[2])
	table.insert(out, "4 tour not done, burst forced, walk away: plain Gap " .. a4 .. " s, BusyDay false, no burst")

	-- 5. a card with a term: the first unseen one, marked with the career day
	set({ followers = 1200 }, "term") -- silent: the CLOUT below crosses no tier
	local seen5 = hints()
	local r5, a5 = spawnArrived("term", CARD)
	expectArrive("term", a5, seen5)
	assert(termOf(a5.card.hint) == "placement" and a5.card.hint.text == hintText("placement"), "term: " .. CARD .. "'s hint is "
		.. show(a5.card.hint) .. ", want placement")
	local h5 = hints()
	assert(h5.placement == DAY, "term: Hints.placement is " .. tostring(h5.placement) .. ", want the career day " .. DAY)
	assert(keys(h5) == "placement", "term: Hints holds " .. keys(h5) .. ", want placement only")
	table.insert(out, "5 " .. CARD .. ": hint " .. show(a5.card.hint) .. "; Hints placement = day " .. DAY)

	-- 6. the result's hint, from its headline and text
	assert(wi:Invoke("SetRng", uid, { 1 }) == true, "result: SetRng failed")
	local res = wi:Invoke("Choose", uid, r5.token, 3)
	assert(res and res.ok == true and type(res.result) == "table", "result: Choose 3 refused: " .. tostring(res and res.reason))
	assert(res.result.key == "clout", "result: choice 3 forced good should land clout, landed " .. tostring(res.result.key))
	expectHint("result", res.result.hint, resultTexts(res.result), h5)
	assert(termOf(res.result.hint) == "followers", "result: the CLOUT result's hint is " .. show(res.result.hint) .. ", want followers")
	local h6 = hints()
	assert(h6.followers == DAY and keys(h6) == "followers,placement", "result: Hints holds " .. keys(h6) .. " (followers "
		.. tostring(h6.followers) .. "), want followers,placement at day " .. DAY)
	table.insert(out, "6 choice 3 (clout): result hint " .. show(res.result.hint) .. " from its headline and text")

	-- 7. the same term again: none (navx_placement has no other term)
	local seen7 = hints()
	local r7, a7 = spawnArrived("again", CARD)
	expectArrive("again", a7, seen7)
	assert(a7.card.hint == nil, "again: " .. CARD .. " a second time carries " .. show(a7.card.hint) .. ", want none")
	assert(keys(hints()) == keys(seen7), "again: Hints moved from " .. keys(seen7) .. " to " .. keys(hints()))
	leave("again", r7)
	table.insert(out, "7 " .. CARD .. " again: no hint (placement seen, no other term); Hints unchanged")

	-- 8. the phone pop: two_sessions' "one-hit wonder"
	ph:Invoke("Sent", uid)
	local seen8 = hints()
	local tok = ph:Invoke("Pop", uid, DM)
	assert(type(tok) == "string", "phone: Pop(" .. DM .. ") sent nothing")
	local pop = popSent(tok)
	assert(pop, "phone: the pop is not in the phone hook's Sent")
	assert(termOf(pop.hint) == "hit" and pop.hint.text == hintText("hit"), "phone: " .. DM .. "'s pop hint is " .. show(pop.hint)
		.. ", want hit (before the Task 2 sync of Systems/Phone: the expected red)")
	assert(hints().hit == DAY and seen8.hit == nil, "phone: Hints.hit is " .. tostring(hints().hit) .. ", want day " .. DAY)
	table.insert(out, "8 phone pop " .. DM .. ": hint " .. show(pop.hint))

	-- 9. once each, the career day each
	local h9 = hints()
	assert(keys(h9) == "followers,hit,placement", "never twice: Hints holds " .. keys(h9))
	for term, d in pairs(h9) do assert(d == DAY, "never twice: Hints." .. term .. " is " .. tostring(d) .. ", want " .. DAY) end
	table.insert(out, "9 Hints: followers, hit, placement, each once at day " .. DAY)

	-- 10. the news strip carries the hint when the tag, line and choices carry none (fix round 1, D)
	assert(test:Invoke("ResetHints", uid, { "placement", "followers" }) == true, "news: ResetHints with a list failed")
	assert(hints().hit == nil and hints().placement == 0, "news: ResetHints with a list should mark only those (day 0), hit unseen")
	set({ followers = 6000 }, "news") -- silent: the HIT's +3,000 crosses no tier
	assert(wi:Invoke("SetRng", uid, { 1 }) == true, "news: SetRng failed") -- the news rolls good: HIT
	local seen10 = hints()
	local r10, a10 = spawnArrived("news", NEWS)
	assert(r10.news == "hit" and type(a10.card.news) == "table", "news: " .. NEWS .. " arrived with the news " .. tostring(r10.news) .. ", want hit")
	assert(Rules.HintFor(cardTexts(a10.card), seen10, HINTS) == nil, "news: " .. NEWS .. "'s tag, line or choices now carry a term: pick another card")
	expectArrive("news", a10, seen10)
	assert(termOf(a10.card.hint) == "hit", "news: " .. NEWS .. "'s card hint is " .. show(a10.card.hint)
		.. ", want hit from the HIT headline (before the fix-round sync: none)")
	assert(hints().hit == DAY, "news: Hints.hit is " .. tostring(hints().hit) .. ", want " .. DAY)
	leave("news", r10)
	table.insert(out, "10 " .. NEWS .. " with HIT news: no term in tag/line/choices, hint " .. show(a10.card.hint) .. " from the news strip")
end

-- staging for t76b: the real first-ever timer (see the header). Returns its report line
local function stage()
	fresh("stage")
	local resetAt, t0 = workspace:GetServerTimeNow(), os.clock()
	assert(test:Invoke("ResetTour", uid) == true, "stage: ResetTour failed")
	set({ followers = 1200 }, "stage") -- silent: tier_known's news crosses no tier
	assert(not tourDone() and walkins().count == 0 and next(hints()) == nil, "stage: not a fresh start (tour, count or Hints)")
	assert(wi:Invoke("Plant", uid, STAGE) == true, "stage: Plant(" .. STAGE .. ") refused")
	wi:Invoke("Sent", uid)
	assert(wi:Invoke("SetRemaining", uid, nil) == true, "stage: SetRemaining(nil) failed") -- a fresh join's timer: not armed yet
	local armed, scheduled, due
	unheld("stage", function()
		assert(waitFor(function() armed = left(); return type(armed) == "number" end, 2.5), "stage: the loop did not arm the timer within 2.5 s in the lounge")
		assert(within(armed, W.FirstEver, 3), string.format("stage: the first timer armed at %s s, want FirstEver %d..%d (FirstDelay is %d..%d;"
			.. " before the Task 2 sync of Systems/WalkIns: the expected red)", tostring(armed), W.FirstEver[1], W.FirstEver[2], W.FirstDelay[1], W.FirstDelay[2]))
		scheduled = waitFor(function() return pending() ~= nil end, 25 - (os.clock() - t0))
		due = os.clock() - t0
	end) -- the hold back: the visit in flight walks on
	assert(scheduled, string.format("stage: no visit pending %.1f s after the reset (the tour not done blocks it before the Task 2 sync)", due))
	local r = pending()
	assert(r.id == STAGE, "stage: the first-ever visit is " .. tostring(r.id) .. ", want the planted " .. STAGE)
	assert(not tourDone(), "stage: the tour is done: the visit should have started without it")
	assert(waitFor(arrived, math.max(1, 35 - (os.clock() - t0))), string.format("stage: he did not arrive within 35 s of the reset (%.1f s)", os.clock() - t0))
	local arrivedAt = workspace:GetServerTimeNow()
	assert(arrivedAt - resetAt <= 35, string.format("stage: arrived %.1f s after the reset, want 35 or less", arrivedAt - resetAt))
	local a = lastArrive()
	assert(type(a) == "table" and type(a.card) == "table" and a.card.id == STAGE, "stage: no arrive payload for " .. STAGE)
	expectArrive("stage", a, {})
	assert(termOf(a.card.hint) == "followers", "stage: " .. STAGE .. "'s hint is " .. show(a.card.hint) .. ", want followers")
	assert(hints().followers == careerDay() and hints().hit == nil, "stage: Hints should hold followers at the career day and no hit")
	-- the hinted DM for t76b's fold check, held on the client while the walk-in card shows (a second for the card to open
	-- there first; t76b handles either order, since a beat maker left open by an earlier file holds both)
	task.wait(1)
	assert(ph:Invoke("Quiet", uid, false) == true, "stage: Quiet(false) failed")
	ph:Invoke("Sent", uid)
	local tok = ph:Invoke("Pop", uid, DM)
	assert(type(tok) == "string", "stage: Pop(" .. DM .. ") sent nothing")
	local pop = popSent(tok)
	assert(pop and termOf(pop.hint) == "hit", "stage: " .. DM .. "'s pop hint is " .. show(pop and pop.hint) .. ", want hit")
	p:SetAttribute("_T76Reset", resetAt); p:SetAttribute("_T76Arrived", arrivedAt)
	return string.format("stage: first-ever timer armed at %d s (FirstEver %d..%d), %s pending %.1f s and arrived %.1f s after the reset with"
		.. " the tour not done, hint followers; %s popped (hint hit) for t76b", armed, W.FirstEver[1], W.FirstEver[2], STAGE, due,
		arrivedAt - resetAt, DM)
end

local ok, msg = pcall(run)
local staged
if ok then ok, staged = pcall(stage) end
if not ok then
	pcall(function()
		wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
		test:Invoke("ResetHints", uid); advanceTour(); ph:Invoke("Quiet", uid, false)
		p:SetAttribute("_T76Reset", nil); p:SetAttribute("_T76Arrived", nil)
	end)
	pcall(teleport, LOUNGE)
	error(msg or staged, 0)
end
return "T76A PLAY OK\n" .. table.concat(out, "\n") .. "\n" .. staged .. string.format("\nelapsed %.1f s", os.clock() - T0)
