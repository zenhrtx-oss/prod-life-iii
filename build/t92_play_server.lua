-- Server, during play (Wave 3 final fix round, 2026-11-12; final review M1, M2, M3 under rulings C, D and E): an
-- explainer is spent only on a card the player sees, it lands on the right word, and a beatMin card names its bar. The
-- file's own fresh() (unseated in the lounge, Quiet on, the phone's pops dropped, WalkIns Reset, Career Reset, Life Reset
-- with the career day set to DAY = 5, _StudioTestHook ResetHints, SetRecent({}), the tour done and one walk-in counted).
-- The body runs held (WalkInsPaused true) and drives visits through the hooks; a card expires through the walk-in hook's
-- Age (past ExpireSeconds) and the next 1 s upkeep, the real "expired" end.
-- (1) Deferred the whole time: navx_placement arrives (its hint placement, marked at the career day), the hook's
--     SetDeferred(true) (the WalkIn_Deferred path; seen false: it never showed), then it expires: placement is unseen
--     again, so a later card teaches it.
-- (2) Shown, then hidden: SetDeferred(true, seen true) (the client had it on screen first), expired: placement stays.
-- (3) Hidden, then shown: SetDeferred(true), SetDeferred(false) (it opened), SetDeferred(true), expired: it stays.
-- (4) Never deferred (on screen the whole time), expired: it stays (the control).
-- (5) A waiting pop holds its term: with placement and followers seen, two_sessions pops with hit and stays unopened
--     (hit still unseen); navx_single walks in with its news forced to HIT (Followers 6,000 first: the +3,000 crosses no
--     tier), whose headline alone would teach hit: the card's hint is HintFor with hit held, never hit. Opening the pop
--     then marks hit at the career day.
-- (6) nohint: with every term unseen, rival_beat's hint is cypher (its line names the cypher), never the verb in "my
--     beats hit harder" (its nohint).
-- (7) The bar: rival_war's arrive payload carries beatMin 3 and beat false (no beat yet), and CardFeel.BeatLine reads it
--     as "Needs a 3★ best beat. Yours: none yet."; a 2-star best beat "... Yours: ★★☆." and a 3-star "... Yours: ★★★.".
-- On any error everything is reset (hold true, WalkIns, the phone, Career, Life, hints and recent beats, Quiet off) and
-- the error rethrown.
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
local CardFeel = require(RS.OK.Modules.CardFeel)
local Tour = require(RS.OK.Systems.Tour)
local HINTS, W = Config.Hints, Config.WalkIns
local LOUNGE = Vector3.new(24, 3, 0)
local CARD, NEWS, DM = "navx_placement", "navx_single", "two_sessions"
local DAY = 5 -- the career day the body runs on (Life SetDay): never the fallback 1
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
local function pending() return wi:Invoke("Pending", uid) end
local function arrived() local r = pending(); return r ~= nil and r.arrived == true end
local function hints()
	local h = test:Invoke("Hints", uid)
	assert(type(h) == "table", "Hints(uid) returned " .. typeof(h))
	return h
end
local function termOf(h) return type(h) == "table" and h.term or nil end
local function show(h) return type(h) == "table" and (tostring(h.term) .. " '" .. tostring(h.text) .. "'") or "none" end
local function add(list, s) if type(s) == "string" and s ~= "" then table.insert(list, s) end end
local function cardTexts(card)
	local t = {}
	add(t, card.tag); add(t, card.line)
	for _, c in ipairs(card.choices or {}) do add(t, c.text) end
	return t
end
local function resultTexts(r) local t = {}; add(t, r.headline); add(t, r.text); return t end
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
local function set(s, label) assert(career:Invoke("Set", uid, s) == true, label .. ": Career Set failed") end
-- `id` walked in (Spawn(id)); returns the arrived record and its arrive payload's card
local function spawnArrived(id, label)
	wi:Invoke("Sent", uid) -- drained: the arrive read below is this visit's
	assert(wi:Invoke("Spawn", uid, id) == true, label .. ": Spawn(" .. id .. ") refused")
	assert(waitFor(arrived, 15), label .. ": " .. id .. " did not arrive within 15 s")
	local a = lastArrive()
	assert(type(a) == "table" and type(a.card) == "table" and a.card.id == id, label .. ": no arrive payload for " .. id)
	return pending(), a.card
end
local function leave(r, label) assert(wi:Invoke("Choose", uid, r.token, 0).ok == true, label .. ": walk away failed") end
-- the open card ages past ExpireSeconds; the next 1 s upkeep ends it as "expired"
local function expire(label)
	assert(wi:Invoke("Age", uid, W.ExpireSeconds + 1) == true, label .. ": Age refused (no arrived card)")
	assert(waitFor(function() return pending() == nil end, 4), label .. ": the card did not expire within 4 s of Age")
end
local function deferred(r, on, seen, label)
	assert(wi:Invoke("SetDeferred", uid, r.token, on, seen) == true, label .. ": SetDeferred(" .. tostring(on) .. ", " .. tostring(seen) .. ") refused")
end
-- the file's own fresh(): unseated and in the lounge, Quiet on, no pops, WalkIns, Career and Life reset (career day DAY),
-- no hint seen, no recent beat, the tour done, one walk-in counted
local function fresh(label)
	local c = p.Character; local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum and hum.Sit then hum.Sit = false; task.wait(0.4) end
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, label .. ": Quiet(true) failed")
	assert(ph:Invoke("Reset", uid) == true, label .. ": phone Reset failed")
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	assert(life:Invoke("Reset", uid) == true, label .. ": Life Reset failed")
	assert(life:Invoke("SetDay", uid, DAY) == true, label .. ": Life SetDay(" .. DAY .. ") failed")
	assert(test:Invoke("ResetHints", uid) == true, label .. ": ResetHints failed")
	assert(type(test:Invoke("SetRecent", uid, {})) == "table", label .. ": SetRecent({}) failed")
	for _, s in ipairs(Tour.Steps) do test:Invoke("TourAdvance", uid, s.id) end
	assert(wi:Invoke("AdvanceVisits", uid, 1) == true, label .. ": AdvanceVisits failed")
end

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh("hidden")
	-- 1-4. navx_placement teaches placement; whether an expiry keeps it marked depends on whether the card ever showed
	local function placementAfter(label, how)
		assert(test:Invoke("ResetHints", uid) == true, label .. ": ResetHints failed")
		local r, c = spawnArrived(CARD, label)
		assert(termOf(c.hint) == "placement", label .. ": " .. CARD .. "'s hint is " .. show(c.hint) .. ", want placement")
		assert(hints().placement == DAY, label .. ": Hints.placement is " .. tostring(hints().placement) .. " at arrival, want " .. DAY)
		how(r)
		expire(label)
		return hints().placement
	end
	local h1 = placementAfter("hidden", function(r) deferred(r, true, false, "hidden") end)
	assert(h1 == nil, "hidden: a card deferred from its arrival that expired left Hints.placement " .. tostring(h1)
		.. ", want unseen (before the final fix round's sync of Systems/WalkIns: " .. DAY .. ", the expected red)")
	local h2 = placementAfter("seen first", function(r) deferred(r, true, true, "seen first") end)
	assert(h2 == DAY, "seen first: a card shown, then deferred, then expired left Hints.placement " .. tostring(h2) .. ", want " .. DAY)
	local h3 = placementAfter("reopened", function(r)
		deferred(r, true, false, "reopened"); deferred(r, false, false, "reopened"); deferred(r, true, false, "reopened")
	end)
	assert(h3 == DAY, "reopened: a card deferred, shown, deferred again and expired left Hints.placement " .. tostring(h3) .. ", want " .. DAY)
	local h4 = placementAfter("on screen", function() end)
	assert(h4 == DAY, "on screen: a card never deferred that expired left Hints.placement " .. tostring(h4) .. ", want " .. DAY)
	table.insert(out, string.format("1-4 %s expired: deferred from arrival -> placement %s; seen then deferred -> %s; deferred, shown, deferred -> %s; never deferred -> %s",
		CARD, tostring(h1), tostring(h2), tostring(h3), tostring(h4)))

	-- 5. a waiting pop holds its term: two_sessions (hit) unopened, then navx_single's HIT news can't teach hit
	fresh("held")
	assert(test:Invoke("ResetHints", uid, { "placement", "followers" }) == true, "held: ResetHints with a list failed")
	ph:Invoke("Sent", uid)
	local tok = ph:Invoke("Pop", uid, DM)
	assert(type(tok) == "string", "held: Pop(" .. DM .. ") sent nothing")
	local pop = popSent(tok)
	assert(pop and termOf(pop.hint) == "hit", "held: " .. DM .. "'s pop hint is " .. show(pop and pop.hint) .. ", want hit")
	assert(hints().hit == nil, "held: Hints.hit is " .. tostring(hints().hit) .. " with the pop only sent, want unseen"
		.. " (before the final fix round's sync of Systems/Phone and Systems/WalkIns: " .. DAY .. ", the expected red)")
	set({ followers = 6000 }, "held") -- silent: the HIT's +3,000 crosses no tier
	assert(wi:Invoke("SetRng", uid, { 1 }) == true, "held: SetRng failed") -- the news rolls good: HIT
	local seen5 = hints()
	local r5, c5 = spawnArrived(NEWS, "held")
	assert(type(c5.news) == "table" and c5.news.headline == "HIT", "held: " .. NEWS .. " arrived with the news " .. tostring(c5.news and c5.news.headline) .. ", want HIT")
	local unheld = Rules.HintFor(cardTexts(c5), seen5, HINTS) or Rules.HintFor(resultTexts(c5.news), seen5, HINTS)
	assert(termOf(unheld) == "hit", "held: without the hold " .. NEWS .. "'s hint would be " .. show(unheld) .. ", not hit: pick another card")
	local want5 = Rules.HintFor(cardTexts(c5), seen5, HINTS, { "hit" }) or Rules.HintFor(resultTexts(c5.news), seen5, HINTS, { "hit" })
	assert(termOf(c5.hint) ~= "hit" and termOf(c5.hint) == termOf(want5), "held: " .. NEWS .. "'s hint is " .. show(c5.hint)
		.. " while the pop holds hit, want " .. show(want5) .. " (HintFor with hit held)")
	leave(r5, "held")
	assert(ph:Invoke("Open", uid, tok) == true, "held: Open failed")
	assert(hints().hit == DAY, "held: Hints.hit is " .. tostring(hints().hit) .. " once the pop opened, want " .. DAY)
	local d5 = ph:Invoke("Choose", uid, tok, 0)
	assert(type(d5) == "table" and d5.ok == true, "held: dismissing the opened DM failed")
	table.insert(out, "5 " .. DM .. " popped (hit) and waiting: " .. NEWS .. " (HIT news) hint " .. show(c5.hint) .. "; the pop opened: Hints.hit " .. DAY)

	-- 6. nohint: rival_beat teaches cypher, never the verb hit
	fresh("nohint")
	local r6, c6 = spawnArrived("rival_beat", "nohint")
	assert(termOf(c6.hint) == "cypher", "nohint: rival_beat's hint is " .. show(c6.hint) .. ", want cypher"
		.. " (before the final fix round's sync of Data/WalkIns and Systems/WalkIns: hit, the expected red)")
	assert(hints().hit == nil, "nohint: rival_beat marked hit")
	leave(r6, "nohint")
	table.insert(out, "6 rival_beat (nohint hit): hint " .. show(c6.hint))

	-- 7. the bar: rival_war's payload carries beatMin, and the beat line names it
	fresh("bar")
	local r7, c7 = spawnArrived("rival_war", "bar")
	assert(c7.beatMin == 3, "bar: rival_war's arrive payload carries beatMin " .. tostring(c7.beatMin)
		.. ", want 3 (before the final fix round's sync of Systems/WalkIns: nil, the expected red)")
	assert(c7.beat == false, "bar: rival_war's payload beat is " .. tostring(c7.beat) .. ", want false (no beat yet)")
	local none = CardFeel.BeatLine(c7.beat, c7.beatMin)
	local below = CardFeel.BeatLine({ stars = 2, fires = 0, bpm = 142 }, c7.beatMin)
	local at = CardFeel.BeatLine({ stars = 3, fires = 0, bpm = 142 }, c7.beatMin)
	assert(none == "Needs a 3★ best beat. Yours: none yet.", "bar: no beat reads '" .. tostring(none) .. "'")
	assert(below == "Needs a 3★ best beat. Yours: ★★☆.", "bar: a 2-star beat reads '" .. tostring(below) .. "'")
	assert(at == "Needs a 3★ best beat. Yours: ★★★.", "bar: a 3-star beat reads '" .. tostring(at) .. "'")
	leave(r7, "bar")
	table.insert(out, string.format("7 rival_war: beatMin %d, beat false; '%s' / '%s' / '%s'", c7.beatMin, none, below, at))
end

local ok, msg = pcall(run)
pcall(function()
	wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
	test:Invoke("ResetHints", uid); test:Invoke("SetRecent", uid, {}); ph:Invoke("Quiet", uid, false)
end)
pcall(teleport, LOUNGE)
if not ok then error(msg, 0) end
return "T92 PLAY OK\n" .. table.concat(out, "\n") .. string.format("\nelapsed %.1f s", os.clock() - T0)
