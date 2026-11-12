-- CLI spec for Modules/WalkInRules (odds, resolve, money path, tags, scheduling, queue, pick, gates, source, the first
-- card, caps, seeding, exclude, Revalidate, CapKeys, MarkSent, the rush-hour gap and its room, rooms and routes,
-- presence (the hub or your own rooms), the cypher's hold).
-- Run: sh tools/spec.sh walkin_rules
local R = require("../src/ReplicatedStorage/OK/Modules/WalkInRules")
local Format = require("../src/ReplicatedStorage/OK/Modules/Format")
local E = require("./economy_fixture")

local fails = {}
local function eq(name, got, want)
	if got ~= want then table.insert(fails, string.format("%s: expected %s, got %s", name, tostring(want), tostring(got))) end
end
local function near(name, got, want)
	if type(got) ~= "number" or math.abs(got - want) > 1e-6 then
		table.insert(fails, string.format("%s: expected %s, got %s", name, tostring(want), tostring(got)))
	end
end

-- an rng that returns `values` in order and records each (lo, hi); running out is a failure
local function seq(values)
	local calls = {}
	local rng = function(lo, hi)
		table.insert(calls, { lo, hi })
		local v = values[#calls]
		if v == nil then error("rng called more often than expected") end
		return v
	end
	return rng, calls
end
local function noRng() error("rng must not be called") end

local ODDS = { auraPer = 20, auraCap = 15, followersPer = 1000, followersCap = 10, min = 10, max = 90 }
local function career(t)
	local c = { money = 0, aura = 0, followers = 0, placements = 0, hits = 0, sponsors = 0 }
	for k, v in pairs(t or {}) do c[k] = v end
	return c
end

-- Chance: aura and followers tilt the base, clamped to [min, max]
eq("Chance base", R.Chance(50, career(), ODDS), 50)
eq("Chance aura 400", R.Chance(50, career({ aura = 400 }), ODDS), 65)
eq("Chance aura -400", R.Chance(50, career({ aura = -400 }), ODDS), 35)
eq("Chance followers 25000", R.Chance(50, career({ followers = 25000 }), ODDS), 60)
eq("Chance base 85 + aura 400", R.Chance(85, career({ aura = 400 }), ODDS), 90)
eq("Chance base 5", R.Chance(5, career(), ODDS), 10)
eq("Chance aura 100 followers 3000", R.Chance(50, career({ aura = 100, followers = 3000 }), ODDS), 58)

-- Resolve
local GOOD = { key = "g", headline = "G", text = "", line = "", tone = "win", money = 400, aura = 40, placements = 1 }
local BAD = { key = "b", headline = "B", text = "", line = "", tone = "loss", money = -300, aura = -60 }
local RARE = { key = "r", headline = "R", text = "", line = "", tone = "win", money = 1500 }
local choice = { text = "go", odds = 50, good = GOOD, bad = BAD }

local rng, calls = seq({ 50 })
local r = R.Resolve(choice, career(), ODDS, rng)
eq("Resolve roll = chance ok", r.ok, true)
eq("Resolve roll = chance outcome", r.outcome, GOOD)
eq("Resolve roll = chance roll", r.roll, "good")
eq("Resolve chance", r.chance, 50)
eq("Resolve rng lo", calls[1] and calls[1][1], 1)
eq("Resolve rng hi", calls[1] and calls[1][2], 100)
r = R.Resolve(choice, career(), ODDS, (seq({ 51 })))
eq("Resolve roll > chance outcome", r.outcome, BAD)
eq("Resolve roll > chance roll", r.roll, "bad")
r = R.Resolve({ text = "x", odds = 50, good = GOOD }, career(), ODDS, (seq({ 99 })))
eq("Resolve missing bad -> good", r.outcome, GOOD)
r = R.Resolve({ text = "x", good = GOOD, bad = BAD }, career({ aura = 400 }), ODDS, (seq({ 65 })))
eq("Resolve default odds 50 tilted to 65", r.outcome, GOOD)
eq("Resolve tilted chance", r.chance, 65)

r = R.Resolve({ text = "x", sure = true, good = GOOD, bad = BAD }, career(), ODDS, noRng)
eq("Resolve sure ok", r.ok, true)
eq("Resolve sure outcome", r.outcome, GOOD)
eq("Resolve sure roll", r.roll, "sure")

local rareChoice = { text = "x", odds = 50, good = GOOD, bad = BAD, rare = RARE, rareOdds = 5 }
rng, calls = seq({ 5 })
r = R.Resolve(rareChoice, career(), ODDS, rng)
eq("Resolve rare outcome", r.outcome, RARE)
eq("Resolve rare roll", r.roll, "rare")
eq("Resolve rare single call", #calls, 1)
eq("Resolve rare rng hi", calls[1] and calls[1][2], 100)
rng, calls = seq({ 6, 1 })
r = R.Resolve(rareChoice, career(), ODDS, rng)
eq("Resolve rare miss -> good", r.outcome, GOOD)
eq("Resolve rare miss calls", #calls, 2)
r = R.Resolve({ text = "x", sure = true, good = GOOD, rare = RARE, rareOdds = 10 }, career(), ODDS, (seq({ 3 })))
eq("Resolve sure still rolls rare first", r.roll, "rare")

r = R.Resolve({ text = "x", cost = 400, sure = true, good = GOOD }, career({ money = 100 }), ODDS, noRng)
eq("Resolve afford ok", r.ok, false)
eq("Resolve afford reason", r.reason, "afford")
r = R.Resolve({ text = "x", cost = 400, sure = true, good = GOOD }, career({ money = 400 }), ODDS, noRng)
eq("Resolve exactly affordable", r.ok, true)

r = R.Resolve({ text = "x", cost = 300, sure = true, good = { key = "k", money = -200, aura = 5 } }, career({ money = 500 }), ODDS, noRng)
eq("deltas cost", r.deltas.cost, 300)
eq("deltas money raw", r.deltas.money, -200)
eq("deltas aura", r.deltas.aura, 5)
for _, s in ipairs({ "followers", "placements", "hits", "sponsors" }) do eq("deltas " .. s .. " zero", r.deltas[s], 0) end
r = R.Resolve({ text = "x", sure = true, good = { key = "k", aura = -900 } }, career({ aura = 0 }), ODDS, noRng)
eq("deltas unclamped", r.deltas.aura, -900)
eq("deltas free cost 0", r.deltas.cost, 0)
eq("deltas no money 0", r.deltas.money, 0)
eq("deltas xp 0 when the outcome has none", r.deltas.xp, 0)
r = R.Resolve({ text = "x", sure = true, good = { key = "k", aura = 5, xp = 40 } }, career(), ODDS, noRng)
eq("deltas xp from the outcome", r.deltas.xp, 40)

-- Readiness (two sessions): the average of level, placements, followers and Aura against their marks, each held to
-- 0..1; a missing stat counts as 0, a missing level as level 1, and Aura below 0 as 0. READY is Config.WalkIns.Odds.ready
-- from economy_fixture (build/t46_check.lua diffs it against the live value), so a retune can't leave this spec stale
local READY = E.READY
local function within(name, got, want, tol)
	if type(got) ~= "number" or math.abs(got - want) > tol then
		table.insert(fails, string.format("%s: expected %s +- %s, got %s", name, tostring(want), tostring(tol), tostring(got)))
	end
end
within("Readiness LV2 0 pl 3300 fol 63 aura", R.Readiness(career({ followers = 3300, aura = 63 }), 2, READY), 0.126, 0.001)
within("Readiness day 5 (LV6 3 pl 25000 fol 400 aura)",
	R.Readiness(career({ placements = 3, followers = 25000, aura = 400 }), 6, READY), 0.739, 0.001)
eq("Readiness past every mark is 1", R.Readiness(career({ placements = 12, followers = 90000, aura = 1500 }), 10, READY), 1)
eq("Readiness Aura -200 counts as 0", R.Readiness(career({ aura = -200 }), 7, READY), R.Readiness(career({ aura = 0 }), 7, READY))
near("Readiness Aura -200 alone", R.Readiness(career({ aura = -200 }), 7, READY), 0.25)
eq("Readiness nil level counts as level 1", R.Readiness(career({ followers = 3300 }), nil, READY),
	R.Readiness(career({ followers = 3300 }), 1, READY))
near("Readiness nil level value", R.Readiness(career(), nil, READY), (1 / 7) / 4)
near("Readiness missing stats count as 0", R.Readiness({}, 7, READY), 0.25)

-- ChoiceChance: a `ready` choice maps readiness onto odds.min..odds.max (rounded); any other choice is Chance's
local ODDS_READY = { auraPer = 20, auraCap = 15, followersPer = 1000, followersCap = 10, min = 10, max = 90, ready = READY }
local READY_GOOD = { key = "localhit", headline = "G", text = "", line = "", tone = "win", followers = 1500, xp = 0 }
local READY_BAD = { key = "blewup", headline = "B", text = "", line = "", tone = "loss", aura = -30 }
local readyChoice = { text = "x", ready = true, good = READY_GOOD, bad = READY_BAD }
local day5 = career({ level = 6, placements = 3, followers = 25000, aura = 400 })
eq("ChoiceChance ready at readiness 0", R.ChoiceChance(readyChoice, career({ level = 0 }), ODDS_READY), 10)
eq("ChoiceChance ready at readiness 1",
	R.ChoiceChance(readyChoice, career({ level = 10, placements = 12, followers = 90000, aura = 1500 }), ODDS_READY), 90)
eq("ChoiceChance ready at the day-5 career", R.ChoiceChance(readyChoice, day5, ODDS_READY), 69)
eq("ChoiceChance non-ready = Chance(odds)", R.ChoiceChance({ text = "x", odds = 70, good = GOOD, bad = BAD }, day5, ODDS_READY),
	R.Chance(70, day5, ODDS_READY))
local readyRan, readyErr = pcall(R.ChoiceChance, readyChoice, day5, ODDS)
eq("ChoiceChance ready without odds.ready errors", readyRan, false)
eq("ChoiceChance ready without odds.ready names Config.WalkIns.Odds.ready (got " .. tostring(readyErr) .. ")",
	string.find(tostring(readyErr), "Config.WalkIns.Odds.ready", 1, true) ~= nil, true)
eq("ChoiceChance non-ready default odds 50", R.ChoiceChance({ text = "x", good = GOOD, bad = BAD }, day5, ODDS),
	R.Chance(50, day5, ODDS))

-- Resolve with a `ready` choice: one rng draw as for any rolled choice (two when rare is set and misses), rolled
-- against ChoiceChance
local readyChance = R.ChoiceChance(readyChoice, day5, ODDS_READY)
rng, calls = seq({ readyChance })
r = R.Resolve(readyChoice, day5, ODDS_READY, rng)
eq("Resolve ready: one rng draw", #calls, 1)
eq("Resolve ready: rng hi", calls[1] and calls[1][2], 100)
eq("Resolve ready: roll = chance is good", r.outcome, READY_GOOD)
eq("Resolve ready: roll good", r.roll, "good")
eq("Resolve ready: chance is ChoiceChance", r.chance, 69)
eq("Resolve ready: deltas.xp 0 when the outcome's xp is 0", r.deltas.xp, 0)
rng, calls = seq({ readyChance + 1 })
r = R.Resolve(readyChoice, day5, ODDS_READY, rng)
eq("Resolve ready: one rng draw (bad)", #calls, 1)
eq("Resolve ready: roll = chance + 1 is bad", r.outcome, READY_BAD)
eq("Resolve ready: roll bad", r.roll, "bad")
eq("Resolve ready: deltas.xp 0 when absent", r.deltas.xp, 0)
local readyRare = { text = "x", ready = true, good = READY_GOOD, bad = READY_BAD, rare = RARE, rareOdds = 5 }
rng, calls = seq({ 6, readyChance })
r = R.Resolve(readyRare, day5, ODDS_READY, rng)
eq("Resolve ready + rare miss: two rng draws", #calls, 2)
eq("Resolve ready + rare miss: good", r.outcome, READY_GOOD)
rng, calls = seq({ 5 })
r = R.Resolve(readyRare, day5, ODDS_READY, rng)
eq("Resolve ready + rare hit: one rng draw", #calls, 1)
eq("Resolve ready + rare hit: rare", r.roll, "rare")
r = R.Resolve({ text = "x", ready = true, good = { key = "home", tone = "win", aura = 10, xp = 30 }, bad = READY_BAD },
	day5, ODDS_READY, (seq({ 1 })))
eq("Resolve ready: deltas.xp equals the outcome's xp", r.deltas.xp, 30)

-- RollChance (one chance rule): the chance Resolve rolls a choice at, in percent: 100 for a sure choice, else
-- ChoiceChance. Resolve's `chance` and the phone hook's ReadyChance both come from it; it never draws
local RC = R.RollChance
eq("RollChance is a function", type(RC), "function")
if type(RC) == "function" then
	eq("RollChance sure is 100", RC({ text = "x", sure = true, good = GOOD }, day5, ODDS_READY), 100)
	eq("RollChance sure ignores odds", RC({ text = "x", sure = true, odds = 30, good = GOOD, bad = BAD }, career({ aura = -400 }), ODDS), 100)
	eq("RollChance ready = ChoiceChance (day 5: 69)", RC(readyChoice, day5, ODDS_READY), 69)
	eq("RollChance plain odds 70 = Chance(70)", RC({ text = "x", odds = 70, good = GOOD, bad = BAD }, day5, ODDS_READY),
		R.Chance(70, day5, ODDS_READY))
	eq("RollChance default odds 50 = Chance(50)", RC({ text = "x", good = GOOD, bad = BAD }, career({ aura = 400 }), ODDS), 65)
	-- Resolve's chance is RollChance's, sure and ready alike, with the draws unchanged (sure: none; ready: one)
	r = R.Resolve({ text = "x", sure = true, good = GOOD, bad = BAD }, day5, ODDS_READY, noRng)
	eq("Resolve sure: chance = RollChance (100), no draw", r.chance, RC({ text = "x", sure = true, good = GOOD, bad = BAD }, day5, ODDS_READY))
	rng, calls = seq({ 1 })
	r = R.Resolve(readyChoice, day5, ODDS_READY, rng)
	eq("Resolve ready: chance = RollChance", r.chance, RC(readyChoice, day5, ODDS_READY))
	eq("Resolve ready via RollChance: still one draw", #calls, 1)
end

-- ResolveNews: the follow-up's own resolve, never a cost
local news = { id = "f", visitor = "v", tag = "", line = "", resolve = { odds = 50, good = GOOD, bad = BAD } }
r = R.ResolveNews(news, career(), ODDS, (seq({ 50 })))
eq("News ok", r.ok, true)
eq("News good", r.outcome, GOOD)
eq("News cost 0", r.deltas.cost, 0)
eq("News money", r.deltas.money, 400)
r = R.ResolveNews(news, career(), ODDS, (seq({ 51 })))
eq("News bad", r.outcome, BAD)
eq("News bad roll", r.roll, "bad")

-- ApplyMoney: cost first, then the outcome's money (a gain, or a loss that stops at $0)
local function money(name, b, c, m, wb, wg, wt)
	local nb, g, t = R.ApplyMoney(b, c, m)
	eq(name .. " balance", nb, wb)
	eq(name .. " gained", g, wg)
	eq(name .. " taken", t, wt)
end
money("loss clamps at zero", 120, 0, -300, 0, 0, 120)
money("paid win", 500, 400, 600, 700, 600, 0)
money("paid loss", 500, 400, -300, 0, 0, 100)
money("free loss", 500, 0, -300, 200, 0, 300)
money("nothing", 100, 0, 0, 100, 0, 0)

-- TagFor: the first non-zero applied amount by priority, with its tone
local function tag(name, applied, wantText, wantTone)
	local text, tone = R.TagFor(applied, Format)
	eq(name .. " text", text, wantText)
	eq(name .. " tone", tone, wantTone)
end
tag("placement win", { placements = 1, money = 400 }, "+1 PLACEMENT", "win")
tag("placement loss", { placements = -1 }, "-1 PLACEMENT", "loss")
tag("aura loss", { aura = -60 }, "-60 AURA", "loss")
tag("followers win", { followers = 1200 }, "+1.2K FOLLOWERS", "win")
tag("followers loss", { followers = -1200 }, "-1.2K FOLLOWERS", "loss")
tag("nothing", {}, nil, "neutral")
tag("hit first", { hits = 1, placements = 1, money = 1000 }, "+1 HIT", "win")
tag("sponsor", { sponsors = 1, aura = 20 }, "+1 SPONSOR", "win")
tag("sponsor loss", { sponsors = -1 }, "-1 SPONSOR", "loss")
tag("aura before followers", { aura = 40, followers = 500 }, "+40 AURA", "win")
tag("money last", { money = 400, aura = 0 }, "+$400", "win")
tag("money loss", { money = -120 }, "-$120", "loss")
tag("all zero", { money = 0, aura = 0, followers = 0, placements = 0, hits = 0, sponsors = 0 }, nil, "neutral")

-- TagFor with the outcome's tone: the first non-zero amount whose sign matches it (a loss counts a paid cost as money
-- lost), else the first non-zero; the tone returned is the one given
local function toned(name, applied, tone, wantText, wantTone)
	local text, got = R.TagFor(applied, Format, tone)
	eq(name .. " text", text, wantText)
	eq(name .. " tone", got, wantTone)
end
toned("win skips a loss amount", { cost = 0, followers = 1500, money = 100, aura = -5 }, "win", "+1.5K FOLLOWERS", "win")
toned("loss counts the cost", { cost = 300, followers = 300, money = 0 }, "loss", "-$300", "loss")
toned("loss cost plus money taken", { cost = 300, money = -100 }, "loss", "-$400", "loss")
toned("loss cost net of money", { cost = 400, money = 100 }, "loss", "-$300", "loss")
toned("loss stat before money", { cost = 400, aura = -10 }, "loss", "-10 AURA", "loss")
toned("loss plain money", { money = -150, followers = 200 }, "loss", "-$150", "loss")
toned("win ignores the cost", { cost = 300, money = 400 }, "win", "+$400", "win")
toned("win falls back to the first non-zero", { aura = -5 }, "win", "-5 AURA", "win")
toned("loss falls back to the first non-zero", { followers = 300 }, "loss", "+300 FOLLOWERS", "loss")
toned("neutral keeps the first non-zero", { aura = -5, followers = 100 }, "neutral", "-5 AURA", "neutral")
toned("nothing keeps the tone", {}, "loss", nil, "loss")
toned("nil tone is the two-argument call", { aura = -5, followers = 100 }, nil, "-5 AURA", "loss")

-- Rollover / CanSchedule: a new day resets today, the queue survives
local st = { day = 1, today = 8, count = 20, queue = { { id = "x", at = 22 } } }
eq("CanSchedule full day", R.CanSchedule(st, 1, 8), false)
eq("CanSchedule full day keeps today", st.today, 8)
R.Rollover(st, 2)
eq("rollover keeps queue: today", st.today, 0)
eq("rollover keeps queue: day", st.day, 2)
eq("rollover keeps queue: queue", #st.queue, 1)
eq("rollover keeps queue: count", st.count, 20)
eq("Rollover returns state", R.Rollover(st, 2), st)
local st2 = { day = 5, today = 8, count = 3, queue = {} }
eq("CanSchedule full 8/8", R.CanSchedule(st2, 5, 8), false)
eq("CanSchedule next day", R.CanSchedule(st2, 6, 8), true)
eq("CanSchedule next day resets", st2.today, 0)
st2.today = 7
eq("CanSchedule 7/8", R.CanSchedule(st2, 6, 8), true)

-- Plant: one queued entry per id, at = count + rng(at), ctx stored
local ps = { count = 10, queue = {} }
rng, calls = seq({ 3 })
local e = R.Plant(ps, { id = "single" }, { 2, 4 }, rng, { sponsor = "brand" })
eq("Plant entry", e ~= nil, true)
eq("Plant at", e and e.at, 13)
eq("Plant id", e and e.id, "single")
eq("Plant ctx", e and e.ctx and e.ctx.sponsor, "brand")
eq("Plant default range lo", calls[1] and calls[1][1], 2)
eq("Plant default range hi", calls[1] and calls[1][2], 4)
eq("Plant queued", ps.queue[1], e)
eq("Plant same id twice", R.Plant(ps, { id = "single" }, { 2, 4 }, noRng), nil)
eq("Plant same id queue", #ps.queue, 1)
rng, calls = seq({ 1 })
e = R.Plant(ps, { id = "drop", at = { 1, 1 } }, { 2, 4 }, rng)
eq("Plant own range", calls[1] and calls[1][1] == 1 and calls[1][2] == 1, true)
eq("Plant own at", e and e.at, 11)
eq("Plant no ctx", e and e.ctx, nil)

-- TakeQueued removes the entry
R.TakeQueued(ps, ps.queue[1])
eq("TakeQueued size", #ps.queue, 1)
eq("TakeQueued left the other", ps.queue[1].id, "drop")

-- Pick
local function card(id, visitor, extra)
	local c = { id = id, visitor = visitor, tag = "", line = "", choices = {} }
	for k, v in pairs(extra or {}) do c[k] = v end
	return c
end
local FU = { id = "fu", visitor = "va", tag = "", line = "", resolve = { odds = 50, good = GOOD, bad = BAD } }
local deck = { cards = { card("ca", "va"), card("cb", "vb") }, followups = { fu = FU }, sponsors = {} }
local function state(t)
	local s = { day = 1, today = 0, count = 0, queue = {}, seen = {}, last = {} }
	for k, v in pairs(t or {}) do s[k] = v end
	return s
end
local function unchanged(name, s, queueLen, seenCopy, lastCopy)
	eq(name .. " queue untouched", #s.queue, queueLen)
	for k, v in pairs(seenCopy) do eq(name .. " seen untouched " .. k, s.seen[k], v) end
	for k, v in pairs(lastCopy) do eq(name .. " last untouched " .. k, s.last[k], v) end
	local n = 0
	for _ in pairs(s.seen) do n += 1 end
	local m = 0
	for _ in pairs(seenCopy) do m += 1 end
	eq(name .. " seen size", n, m)
end

local s = state({ count = 5, queue = { { id = "fu", at = 6 } } })
local p = R.Pick(s, deck, { cooldown = 3, rng = noRng, sponsored = false })
eq("Pick due kind", p and p.kind, "followup")
eq("Pick due entry", p and p.entry, s.queue[1])
eq("Pick due followup", p and p.followup, FU)
unchanged("Pick due", s, 1, {}, {})

s = state({ count = 5, queue = { { id = "fu", at = 9 }, { id = "fu2", at = 6 }, { id = "fu", at = 4 } } })
local deck2 = { cards = deck.cards, followups = { fu = FU, fu2 = { id = "fu2", visitor = "vb", tag = "", line = "", resolve = FU.resolve } }, sponsors = {} }
p = R.Pick(s, deck2, { cooldown = 3, rng = noRng, sponsored = false })
eq("Pick lowest at first", p and p.entry, s.queue[3])

s = state({ count = 5, queue = { { id = "fu", at = 8 } } })
p = R.Pick(s, deck, { cooldown = 3, rng = (seq({ 1 })), sponsored = false })
eq("Pick not yet due -> card", p and p.kind, "card")
eq("Pick not yet due card", p and p.card and p.card.id, "ca")
unchanged("Pick card", s, 1, {}, {})
s.count += 2
p = R.Pick(s, deck, { cooldown = 3, rng = noRng, sponsored = false })
eq("Pick due after 2 visits", p and p.kind, "followup")

s = state({ count = 5, queue = { { id = "missing", at = 1 } } })
p = R.Pick(s, deck, { cooldown = 3, rng = (seq({ 1 })), sponsored = false })
eq("Pick skips unknown followup", p and p.kind, "card")

s = state({ count = 5, last = { va = 3 } })
rng, calls = seq({ 1 })
p = R.Pick(s, deck, { cooldown = 3, rng = rng, sponsored = false })
eq("Pick cooldown skips va", p and p.card and p.card.id, "cb")
eq("Pick cooldown single candidate rng hi", calls[1] and calls[1][2], 1)
unchanged("Pick cooldown", s, 0, {}, { va = 3 })
s.last.va = 2
p = R.Pick(s, deck, { cooldown = 3, rng = (seq({ 1 })), sponsored = false })
eq("Pick cooldown served", p and p.card and p.card.id, "ca")

-- rngs that always draw the lowest / highest value of the range asked for
local LOW = function(lo) return lo end
local HIGH = function(_, hi) return hi end

local deckMin = { cards = { card("late", "va", { minCount = 7 }), card("cb", "vb") }, followups = {}, sponsors = {} }
for _, n in ipairs({ 0, 3, 5 }) do
	for _, pickRng in ipairs({ LOW, HIGH }) do
		p = R.Pick(state({ count = n }), deckMin, { cooldown = 3, rng = pickRng, sponsored = false })
		eq("Pick minCount never at count " .. n, p and p.card and p.card.id, "cb")
	end
end
p = R.Pick(state({ count = 6, seen = { cb = 1 } }), deckMin, { cooldown = 3, rng = (seq({ 1 })), sponsored = false })
eq("Pick minCount reached", p and p.card and p.card.id, "late")

local deckWhen = { cards = { card("rep", "vr", { when = "unsponsored" }), card("boss", "vs", { when = "sponsored" }), card("any", "vx") }, followups = {}, sponsors = {} }
for _, pickRng in ipairs({ LOW, HIGH }) do
	p = R.Pick(state(), deckWhen, { cooldown = 3, rng = pickRng, sponsored = true })
	eq("Pick sponsored skips unsponsored card", p and p.card and p.card.id ~= "rep", true)
	p = R.Pick(state(), deckWhen, { cooldown = 3, rng = pickRng, sponsored = false })
	eq("Pick unsponsored skips sponsored card", p and p.card and p.card.id ~= "boss", true)
end
p = R.Pick(state({ seen = { any = 1 } }), deckWhen, { cooldown = 3, rng = LOW, sponsored = true })
eq("Pick sponsored card when sponsored", p and p.card and p.card.id, "boss")
p = R.Pick(state({ seen = { any = 1 } }), deckWhen, { cooldown = 3, rng = LOW, sponsored = false })
eq("Pick unsponsored card when unsponsored", p and p.card and p.card.id, "rep")

-- a sponsor's rep card only at or above that sponsor's Aura floor (ruling, Task 4b). The plain card has been seen
-- once, so the rep is the forced pick whenever it is eligible
local FLOORS = { x = 200, zero = 0, one = 1 }
local function floorDeck(sponsorId, when)
	return { cards = { card("rep", "vr", { sponsor = sponsorId, when = when }), card("any", "vx") }, followups = {}, sponsors = FLOORS }
end
local REP_FIRST = { any = 1 }
for _, pickRng in ipairs({ LOW, HIGH }) do
	p = R.Pick(state({ seen = REP_FIRST }), floorDeck("x", "unsponsored"), { cooldown = 3, rng = pickRng, sponsored = false, aura = 199 })
	eq("Pick rep under its floor (aura 199) -> plain card", p and p.card and p.card.id, "any")
	p = R.Pick(state({ seen = REP_FIRST }), floorDeck("x", "unsponsored"), { cooldown = 3, rng = pickRng, sponsored = false, aura = 200 })
	eq("Pick rep at its floor (aura 200)", p and p.card and p.card.id, "rep")
end
p = R.Pick(state({ seen = REP_FIRST }), floorDeck("nofloor"), { cooldown = 3, rng = LOW, sponsored = false, aura = 0 })
eq("Pick sponsor without a floor in the deck is eligible", p and p.card and p.card.id, "rep")
local deckPlain = { cards = { card("any", "vx") }, followups = {}, sponsors = FLOORS }
p = R.Pick(state(), deckPlain, { cooldown = 3, rng = LOW, sponsored = false, aura = -500 })
eq("Pick card without sponsor at aura -500", p and p.card and p.card.id, "any")
p = R.Pick(state(), deckPlain, { cooldown = 3, rng = LOW, sponsored = false })
eq("Pick card without sponsor at aura nil", p and p.card and p.card.id, "any")
p = R.Pick(state({ seen = REP_FIRST }), floorDeck("zero"), { cooldown = 3, rng = LOW, sponsored = false })
eq("Pick aura nil counts as 0: floor 0 eligible", p and p.card and p.card.id, "rep")
p = R.Pick(state({ seen = REP_FIRST }), floorDeck("one"), { cooldown = 3, rng = LOW, sponsored = false })
eq("Pick aura nil counts as 0: floor 1 not eligible", p and p.card and p.card.id, "any")

local deckSeen = { cards = { card("a", "v1"), card("b", "v2", { weight = 3 }), card("c", "v3") }, followups = {}, sponsors = {} }
local seenCopy = { a = 0, b = 2, c = 2 }
s = state({ seen = { a = 0, b = 2, c = 2 } })
for _, pickRng in ipairs({ LOW, HIGH }) do
	p = R.Pick(s, deckSeen, { cooldown = 3, rng = pickRng, sponsored = false })
	eq("Pick lowest-seen preference", p and p.card and p.card.id, "a")
end
unchanged("Pick seen", s, 0, seenCopy, {})
s = state({ seen = { a = 3, b = 2, c = 2 } })
rng, calls = seq({ 3 })
p = R.Pick(s, deckSeen, { cooldown = 3, rng = rng, sponsored = false })
eq("Pick weighted range", calls[1] and calls[1][1] == 1 and calls[1][2] == 4, true)
eq("Pick weighted 3 -> b", p and p.card and p.card.id, "b")
p = R.Pick(s, deckSeen, { cooldown = 3, rng = (seq({ 4 })), sponsored = false })
eq("Pick weighted 4 -> c", p and p.card and p.card.id, "c")
p = R.Pick(s, deckSeen, { cooldown = 3, rng = (seq({ 1 })), sponsored = false })
eq("Pick weighted 1 -> b", p and p.card and p.card.id, "b")

eq("Pick nothing eligible", R.Pick(state({ count = 2, last = { va = 2, vb = 1 } }), deck, { cooldown = 3, rng = noRng, sponsored = false }), nil)

-- Wave 1a: gates, source, the first card, caps, seeding, aired, exclude, Revalidate, CapKeys, MarkSent ---------------
-- each case runs in a pcall, so a missing rule fails that case and the others still run
local function case(name, fn)
	local ok, err = pcall(fn)
	if not ok then table.insert(fails, name .. ": " .. tostring(err)) end
end
local function copy(t)
	local c = {}
	for k, v in pairs(t or {}) do c[k] = v end
	return c
end
-- Pick plus the purity check on every call: queue, seen, last, caps, count and today untouched
local function pick(name, s, d, o)
	local seenCopy, lastCopy, capsRef, capsCopy = copy(s.seen), copy(s.last), s.caps, {}
	for g, c in pairs(s.caps or {}) do capsCopy[g] = { key = c.key, n = c.n } end
	local count, today, queueLen = s.count, s.today, #s.queue
	local got = R.Pick(s, d, o)
	unchanged(name, s, queueLen, seenCopy, lastCopy)
	eq(name .. " count untouched", s.count, count)
	eq(name .. " today untouched", s.today, today)
	eq(name .. " caps table untouched", s.caps, capsRef)
	local n, m = 0, 0
	for g, c in pairs(s.caps or {}) do
		n += 1
		eq(name .. " caps untouched " .. g, capsCopy[g] ~= nil and c.key == capsCopy[g].key and c.n == capsCopy[g].n, true)
	end
	for _ in pairs(capsCopy) do m += 1 end
	eq(name .. " caps size", n, m)
	return got
end
local function idOf(got) return got and (got.card and got.card.id or got.entry and got.entry.id) end
-- Pick opts: today's fields plus `extra`
local function opts(extra)
	local o = { cooldown = 3, rng = noRng, sponsored = false }
	for k, v in pairs(extra or {}) do o[k] = v end
	return o
end
-- an opts.career: CareerRules.Have-shaped plus visits
local function have(t, visits)
	local c = career(t)
	c.visits = visits
	return c
end
local MID = function(lo, hi) return (lo + hi) // 2 end
local DM = { source = "phone", app = "MESSAGES" }
local function dm(id, visitor) return card(id, visitor, DM) end

case("gate: needs followers 5000 excludes 4999 and includes 5000", function()
	local gated = card("gated", "v1", { needs = { followers = 5000 } })
	eq("GateOk followers 4999", R.GateOk(gated, career({ followers = 4999 }), 3), false)
	eq("GateOk followers 5000", R.GateOk(gated, career({ followers = 5000 }), 3), true)
	local rich = card("rich", "v3", { needs = { money = 200 } })
	eq("GateOk needs money 199", R.GateOk(rich, career({ money = 199 }), 3), false)
	eq("GateOk needs money 200", R.GateOk(rich, career({ money = 200 }), 3), true)
	local d = { cards = { gated, card("plain", "v2") }, followups = {}, sponsors = {} }
	for _, r in ipairs({ LOW, HIGH }) do
		local s = state({ count = 3, seen = { plain = 1 } })
		eq("gate Pick followers 4999 -> plain", idOf(pick("gate 4999", s, d, opts({ rng = r, career = have({ followers = 4999 }, 3) }))), "plain")
		eq("gate Pick followers 5000 -> gated", idOf(pick("gate 5000", s, d, opts({ rng = r, career = have({ followers = 5000 }, 3) }))), "gated")
		eq("gate Pick nil career -> plain", idOf(pick("gate nil career", s, d, opts({ rng = r }))), "plain")
	end
end)

case("gate: under visits 1 only at count 0", function()
	local rookie = card("rookie", "v1", { under = { visits = 1 } })
	eq("GateOk under visits 1 at 0", R.GateOk(rookie, career(), 0), true)
	eq("GateOk under visits 1 at 1", R.GateOk(rookie, career(), 1), false)
	local d = { cards = { rookie, card("plain", "v2") }, followups = {}, sponsors = {} }
	for _, r in ipairs({ LOW, HIGH }) do
		eq("under visits Pick count 0", idOf(pick("under visits 0", state({ count = 0, seen = { plain = 1 } }), d, opts({ rng = r, career = have({}, 0) }))), "rookie")
		eq("under visits Pick count 1", idOf(pick("under visits 1", state({ count = 1, seen = { plain = 1 } }), d, opts({ rng = r, career = have({}, 1) }))), "plain")
	end
end)

case("gate: unknown key is never eligible", function()
	local c = career({ luck = 5 })
	eq("GateOk needs unknown key", R.GateOk(card("odd", "v1", { needs = { luck = 1 } }), c, 3), false)
	eq("GateOk under unknown key", R.GateOk(card("odd", "v1", { under = { luck = 9 } }), c, 3), false)
	local d = { cards = { card("odd", "v1", { needs = { luck = 1 } }), card("plain", "v2") }, followups = {}, sponsors = {} }
	for _, r in ipairs({ LOW, HIGH }) do
		eq("unknown key never picked", idOf(pick("unknown key", state({ count = 3, seen = { plain = 1 } }), d, opts({ rng = r, career = have({ luck = 5 }, 3) }))), "plain")
	end
	-- nil career: only cards without needs/under
	eq("GateOk nil career, gated card", R.GateOk(card("g", "v1", { needs = { aura = 0 } }), nil, 0), false)
	eq("GateOk nil career, plain card", R.GateOk(card("p", "v1"), nil, 0), true)
end)

case("source: a phone card never comes back from a walk-in Pick, and a walk-in card never from a phone Pick", function()
	local d = { cards = { dm("dm", "v1"), card("walk", "v2"), card("walk2", "v3", { source = "walkin" }) }, followups = {}, sponsors = {} }
	for _, r in ipairs({ LOW, HIGH }) do
		local s = state({ count = 3, seen = { walk = 1, walk2 = 1 } })
		local got = idOf(pick("source nil", s, d, opts({ rng = r })))
		eq("walk-in Pick (source nil) never a phone card", got == "walk" or got == "walk2", true)
		got = idOf(pick("source walkin", s, d, opts({ rng = r, source = "walkin" })))
		eq("walk-in Pick (source walkin) never a phone card", got == "walk" or got == "walk2", true)
		eq("phone Pick -> the phone card", idOf(pick("source phone", state({ count = 3, seen = { dm = 5 } }), d, opts({ rng = r, source = "phone" }))), "dm")
	end
	local walkOnly = { cards = { card("walk", "v2") }, followups = {}, sponsors = {} }
	eq("phone Pick with no phone card", pick("source phone none", state(), walkOnly, opts({ source = "phone" })), nil)
end)

case("source: a due phone follow-up is skipped by a walk-in Pick and taken by a phone Pick", function()
	local CLIP = { id = "clip", visitor = "v1", source = "phone", tag = "", line = "", resolve = FU.resolve }
	local d = { cards = { card("walk", "v2"), dm("dm", "v1") }, followups = { clip = CLIP, fu = FU }, sponsors = {} }
	local s = state({ count = 5, queue = { { id = "clip", at = 4 } } })
	local got = pick("walk-in skips a phone follow-up", s, d, opts({ rng = (seq({ 1 })) }))
	eq("walk-in Pick skips the due phone follow-up", got and got.kind, "card")
	eq("walk-in Pick takes a walk-in card", idOf(got), "walk")
	got = pick("phone takes a phone follow-up", s, d, opts({ source = "phone" }))
	eq("phone Pick takes the due phone follow-up", got and got.kind, "followup")
	eq("phone Pick entry", got and got.entry, s.queue[1])
	eq("phone Pick followup", got and got.followup, CLIP)
	-- and the reverse: a due walk-in follow-up waits for a walk-in Pick
	s = state({ count = 5, queue = { { id = "fu", at = 4 } } })
	eq("phone Pick skips a due walk-in follow-up", idOf(pick("phone skips a walk-in follow-up", s, d, opts({ rng = (seq({ 1 })), source = "phone" }))), "dm")
	got = pick("walk-in takes a walk-in follow-up", s, d, opts())
	eq("walk-in Pick takes the due walk-in follow-up", got and got.kind == "followup" and got.followup, FU)
end)

-- the starter pool (Task 5b+): at visits 0 one eligible `first` card, drawn by weight in deck order with one
-- rng(1, total) draw, the same draw as the least-seen pool's; never once their gate (under visits 1) closes
case("first: visits 0 draws one eligible first card by weight with one rng draw; visits 1 never returns one", function()
	local s1 = card("s1", "vf1", { first = true, under = { visits = 1 } })
	local s2 = card("s2", "vf2", { first = true, under = { visits = 1 } })
	local s3 = card("s3", "vf3", { first = true, under = { visits = 1 }, weight = 2 })
	local d = { cards = { card("a", "v1"), s1, card("b", "v2"), s2, s3 }, followups = {}, sponsors = {} }
	-- weights 1 + 1 + 2 = 4: a draw of 1 is s1, 2 is s2, 3 and 4 are s3
	for v, want in pairs({ [1] = "s1", [2] = "s2", [3] = "s3", [4] = "s3" }) do
		local rng, calls = seq({ v })
		eq("first draw " .. v, idOf(pick("first draw " .. v, state({ count = 0 }), d, opts({ rng = rng, career = have({}, 0) }))), want)
		eq("first draw " .. v .. " is one draw over 1..4", #calls == 1 and calls[1][1] == 1 and calls[1][2] == 4, true)
	end
	for _, r in ipairs({ LOW, HIGH, MID }) do
		local got = idOf(pick("first count 1", state({ count = 1 }), d, opts({ rng = r, career = have({}, 1) })))
		eq("no first card at visits 1", got == "a" or got == "b", true)
	end
	-- it wins over the least-seen draw, and only when opts.career says visits 0
	local d2 = { cards = { card("a", "v1"), card("solo", "vf", { first = true }) }, followups = {}, sponsors = {} }
	local rng2, calls2 = seq({ 1 })
	eq("first beats the least-seen draw", idOf(pick("first beats least-seen", state({ count = 0, seen = { solo = 4 } }), d2, opts({ rng = rng2, career = have({}, 0) }))), "solo")
	eq("a lone first card is one draw over 1..1", #calls2 == 1 and calls2[1][1] == 1 and calls2[1][2] == 1, true)
	eq("first without opts.career is a normal draw", idOf(pick("first no career", state({ count = 0, seen = { solo = 4 } }), d2, opts({ rng = (seq({ 1 })) }))), "a")
	-- an ineligible first card (its gate) is never drawn; a phone Pick at visits 0 never sees one (walk-in cards)
	local gated = card("g", "vg", { first = true, needs = { followers = 1000 } })
	local d3 = { cards = { card("a", "v1"), gated, s1 }, followups = {}, sponsors = {} }
	for _, r in ipairs({ LOW, HIGH }) do
		eq("a gated first card is not drawn", idOf(pick("first gated", state({ count = 0 }), d3, opts({ rng = r, career = have({}, 0) }))), "s1")
	end
	local d4 = { cards = { s1, dm("dm", "v5") }, followups = {}, sponsors = {} }
	eq("a phone Pick at visits 0 draws its phone card", idOf(pick("first phone", state({ count = 0 }), d4, opts({ rng = (seq({ 1 })), source = "phone", career = have({}, 0) }))), "dm")
	-- the pool is taken only when its total weight is above 0 (review Minor 6): starters all at weight 0 fall through to
	-- the least-seen pool, where a weight-0 card is never drawn either, instead of leaving no pick at all
	local z1 = card("z1", "vz1", { first = true, under = { visits = 1 }, weight = 0 })
	local z2 = card("z2", "vz2", { first = true, under = { visits = 1 }, weight = 0 })
	local d5 = { cards = { z1, card("a", "v1"), z2 }, followups = {}, sponsors = {} }
	local rng5, calls5 = seq({ 1 })
	eq("weight-0 starters fall through to the least-seen pool", idOf(pick("first weight 0", state({ count = 0 }), d5, opts({ rng = rng5, career = have({}, 0) }))), "a")
	eq("the least-seen draw is one over 1..1 (the weight-0 starters add nothing)", #calls5 == 1 and calls5[1][1] == 1 and calls5[1][2] == 1, true)
	-- `solo` has no gate, so only the visits == 0 condition keeps it from being forced at visits 1
	for _, r in ipairs({ LOW, HIGH, MID }) do
		eq("first card without a gate at visits 1 is a normal draw", idOf(pick("first visits 1", state({ count = 1, seen = { solo = 4 } }), d2, opts({ rng = r, career = have({}, 1) }))), "a")
	end
end)

case("cap: mom group max 2 per week refuses the third in week 0 and allows it in week 1", function()
	local MOM = { group = "mom", per = "week", max = 2 }
	local momA, momB = card("mom_a", "mom", { cap = MOM }), card("mom_b", "mom", { cap = MOM })
	eq("CapOk no counts yet", R.CapOk(momA, {}, 3, 0), true)
	eq("CapOk nil caps", R.CapOk(momA, nil, 3, 0), true)
	local s = state({ count = 3, caps = {}, seen = { plain = 9 } })
	R.CountCap(s, momA, 1, 0)
	eq("CapOk after one this week", R.CapOk(momB, s.caps, 3, 0), true)
	R.CountCap(s, momB, 2, 0)
	eq("CapOk third in week 0 refused (counted per group)", R.CapOk(momA, s.caps, 6, 0), false)
	eq("CapOk third in week 1 allowed", R.CapOk(momA, s.caps, 7, 1), true)
	eq("CapOk an uncapped card ignores caps", R.CapOk(card("plain", "v2"), s.caps, 6, 0), true)
	eq("CapOk a capped card with no keys", R.CapOk(momA, {}, nil, nil), false)
	local d = { cards = { momA, card("plain", "v2") }, followups = {}, sponsors = {} }
	for _, r in ipairs({ LOW, HIGH }) do
		eq("cap Pick week 0 -> plain", idOf(pick("cap week 0", s, d, opts({ rng = r, day = 6, week = 0 }))), "plain")
		eq("cap Pick week 1 -> mom", idOf(pick("cap week 1", s, d, opts({ rng = r, day = 7, week = 1 }))), "mom_a")
	end
end)

case("cap: CountCap resets n when the key changes", function()
	local weekly = card("w", "v1", { cap = { group = "mom", per = "week", max = 2 } })
	local daily = card("d", "v2", { cap = { group = "weird", per = "day", max = 1 } })
	local s = state({ count = 4, today = 2, caps = {}, seen = { x = 1 }, last = { v1 = 2 }, queue = { { id = "fu", at = 9 } } })
	R.CountCap(s, weekly, 0, 0)
	R.CountCap(s, weekly, 6, 0)
	eq("CountCap week 0 key", s.caps.mom and s.caps.mom.key, 0)
	eq("CountCap week 0 n", s.caps.mom and s.caps.mom.n, 2)
	R.CountCap(s, weekly, 7, 1)
	eq("CountCap new week key", s.caps.mom and s.caps.mom.key, 1)
	eq("CountCap new week n reset, then counted", s.caps.mom and s.caps.mom.n, 1)
	R.CountCap(s, daily, 10, 1)
	R.CountCap(s, daily, 11, 1)
	eq("CountCap new day key", s.caps.weird and s.caps.weird.key, 11)
	eq("CountCap new day n", s.caps.weird and s.caps.weird.n, 1)
	eq("CountCap daily: the second that day refused", R.CapOk(daily, s.caps, 11, 1), false)
	eq("CountCap daily: the next day allowed", R.CapOk(daily, s.caps, 12, 1), true)
	R.CountCap(s, card("plain", "v3"), 11, 1)
	local n = 0
	for _ in pairs(s.caps) do n += 1 end
	eq("CountCap an uncapped card adds no group", n, 2)
	eq("CountCap leaves count", s.count, 4)
	eq("CountCap leaves today", s.today, 2)
	eq("CountCap leaves seen", s.seen.x, 1)
	eq("CountCap leaves last", s.last.v1, 2)
	eq("CountCap leaves queue", #s.queue, 1)
	local fresh = state()
	R.CountCap(fresh, weekly, 0, 0)
	eq("CountCap with no caps table yet", fresh.caps and fresh.caps.mom and fresh.caps.mom.n, 1)
end)

case("seed: newly eligible joins evenly", function()
	local d = { cards = { card("a", "v1"), card("b", "v2"), card("c", "v3"), card("d", "v4", { needs = { followers = 5000 } }),
		dm("e", "v5") }, followups = {}, sponsors = {} }
	-- e is a phone card at seen 0: not in the walk-in pool, so it never sets the floor
	local base = { a = 3, b = 3, c = 4, e = 0 }
	local closed, open = opts({ career = have({ followers = 4999 }, 9) }), opts({ career = have({ followers = 5000 }, 9) })
	local s = state({ count = 9, seen = copy(base) })
	eq("Seed before the gate opens", R.Seed(s, d, closed), 0)
	eq("Seed leaves a card that isn't eligible yet", s.seen.d, nil)
	eq("Seed when the gate opens", R.Seed(s, d, open), 1)
	eq("Seed d = the lowest eligible seen", s.seen.d, 3)
	for k, v in pairs(base) do eq("Seed leaves " .. k, s.seen[k], v) end
	eq("Seed again changes nothing", R.Seed(s, d, open), 0)
	-- six arrivals: seeded, d is drawn at most twice; unseeded (nil = 0), it wins the first three back to back
	local function arrivals(seeded, r)
		local st = state({ count = 9, seen = copy(base) })
		if seeded then R.Seed(st, d, open) end
		local got, ds = {}, 0
		for i = 1, 6 do
			local id = idOf(pick("seed arrival " .. i, st, d, opts({ rng = r, career = open.career })))
			got[i] = tostring(id)
			if id then st.seen[id] = (st.seen[id] or 0) + 1 end
			if id == "d" then ds += 1 end
		end
		return ds, table.concat(got, ",", 1, 3)
	end
	for _, r in ipairs({ LOW, HIGH, MID }) do
		local ds = arrivals(true, r)
		eq("seeded: d drawn at most twice in 6", ds <= 2, true)
		local _, firstThree = arrivals(false, r)
		eq("unseeded control: d wins the first three", firstThree, "d,d,d")
	end
end)

case("seed: no eligible seen yet → 0", function()
	local d = { cards = { card("a", "v1"), card("b", "v2"), card("g", "v3", { needs = { followers = 5000 } }), dm("dm", "v4") },
		followups = {}, sponsors = {} }
	local s = state({ count = 0, seen = { dm = 7 } })
	eq("Seed with nothing seen", R.Seed(s, d, opts({ career = have({}, 0) })), 2)
	eq("Seed a = 0", s.seen.a, 0)
	eq("Seed b = 0", s.seen.b, 0)
	eq("Seed leaves the gated card", s.seen.g, nil)
	eq("Seed leaves the phone card", s.seen.dm, 7)
	-- a phone Seed seeds the phone pool only
	local s2 = state({ count = 0 })
	eq("Seed phone pool", R.Seed(s2, d, opts({ source = "phone", career = have({}, 0) })), 1)
	eq("Seed phone pool dm = 0", s2.seen.dm, 0)
	eq("Seed phone pool leaves walk-in cards", s2.seen.a, nil)
end)

-- Pick's least-seen pool under `o`: the eligible cards (Revalidate, Pick's own eligibility) at the lowest seen, as their
-- sorted ids joined by ","
local function leastPool(s, d, o)
	local fewest, pool = math.huge, {}
	for _, c in ipairs(d.cards) do
		if R.Revalidate(s, d, o, c) then
			local n = s.seen[c.id] or 0
			if n < fewest then fewest, pool = n, {} end
			if n == fewest then table.insert(pool, c.id) end
		end
	end
	table.sort(pool)
	return table.concat(pool, ",")
end

case("seed: a card back from a closed gate joins the rotation's least-seen level, never alone below it", function()
	-- the uncapped rotation sits at 5-6; x (gated on its visitor's score) last came at seen 1, then its gate closed while
	-- the rest moved on. Left at 1 when it reopens, it is the only least-seen card and comes on every visit the cooldown
	-- allows until it catches up (Task 5 review F4)
	local d = { cards = { card("a", "v1"), card("b", "v2"), card("c", "v3"), card("d", "v4"), card("e", "v5"),
		card("x", "vx", { needs = { rel = 1 } }) }, followups = {}, sponsors = {} }
	local base = { a = 5, b = 6, c = 5, d = 6, e = 6, x = 1 }
	local closed = opts({ rel = { vx = { score = 0, flags = {} } } })
	local open = opts({ rel = { vx = { score = 1, flags = {} } } })
	local s = state({ count = 60, seen = copy(base) })
	eq("reopen: Seed while x is closed", R.Seed(s, d, closed), 0)
	eq("reopen: x keeps its seen while closed", s.seen.x, 1)
	eq("reopen: control: as it stands, x alone is the least seen", leastPool(s, d, open), "x")
	eq("reopen: Seed when x reopens changes one card", R.Seed(s, d, open), 1)
	eq("reopen: x joins at the rotation's least-seen level", s.seen.x, 5)
	eq("reopen: x is least seen with a and c, not alone", leastPool(s, d, open), "a,c,x")
	for k, v in pairs(base) do
		if k ~= "x" then eq("reopen: Seed leaves " .. k, s.seen[k], v) end
	end
	eq("reopen: Seed again changes nothing", R.Seed(s, d, open), 0)
	-- the three draws that clear the least-seen level take x once, whatever the rng; not levelled, x takes all three
	local function draws(levelled, r)
		local st = state({ count = 60, seen = copy(base) })
		if levelled then R.Seed(st, d, open) end
		local got, xs = {}, 0
		for i = 1, 3 do
			local id = idOf(pick("reopen draw " .. i, st, d, opts({ rng = r, rel = open.rel })))
			table.insert(got, tostring(id))
			if id then st.seen[id] = (st.seen[id] or 0) + 1 end
			if id == "x" then xs += 1 end
		end
		return xs, table.concat(got, ",")
	end
	for _, r in ipairs({ LOW, HIGH, MID }) do
		local xs = draws(true, r)
		eq("reopen: levelled, x drawn once in the 3 draws that clear its level", xs, 1)
		local _, all = draws(false, r)
		eq("reopen: control: not levelled, x wins all three", all, "x,x,x")
	end
end)

case("seed: a card first opening late joins the uncapped rotation's level, not the 0-1 of capped cards", function()
	-- the uncapped rotation sits at 5-6. big1 and big2 share a weekly cap (max 1) that keeps them behind on purpose; this
	-- week's slot is open, so both are eligible, at 0 and 1. y opens late (followers 5000). At the lowest eligible seen
	-- (big1's 0) it would be the only least-seen card once a big card came and the cap shut (Task 5 review F4)
	local BIG = { group = "big", per = "week", max = 1 }
	local d = { cards = { card("a", "v1"), card("b", "v2"), card("c", "v3"), card("d", "v4"),
		card("big1", "vb1", { cap = BIG }), card("big2", "vb2", { cap = BIG }),
		card("y", "vy", { needs = { followers = 5000 } }) }, followups = {}, sponsors = {} }
	local base = { a = 5, b = 6, c = 5, d = 6, big1 = 0, big2 = 1 }
	local function at(followers) return opts({ career = have({ followers = followers }, 60), day = 70, week = 10 }) end
	local s = state({ count = 60, seen = copy(base), caps = {} })
	eq("late: Seed before y opens", R.Seed(s, d, at(4999)), 0)
	eq("late: Seed when y opens changes one card", R.Seed(s, d, at(5000)), 1)
	eq("late: y joins at the uncapped rotation's least-seen level", s.seen.y, 5)
	eq("late: a capped card keeps its seen (big1)", s.seen.big1, 0)
	eq("late: a capped card keeps its seen (big2)", s.seen.big2, 1)
	-- this week's big card comes (big1, the least seen while the cap is open), and the cap shuts
	eq("late: big1 is the least seen while the big cap is open", leastPool(s, d, at(5000)), "big1")
	s.seen.big1 += 1
	R.CountCap(s, d.cards[5], 70, 10)
	eq("late: with the big cap shut, y is least seen with a and c, not alone", leastPool(s, d, at(5000)), "a,c,y")
	-- control: at the capped cards' 0, y would be alone at the least-seen level once the cap shut
	local low = state({ count = 60, seen = copy(base), caps = { big = { key = 10, n = 1 } } })
	low.seen.y = 0
	eq("late: control: at big1's 0, y is alone", leastPool(low, d, at(5000)), "y")
end)

case("seed: a rotation one apart, a card ahead of it and a capped card behind it stay; 2 under the median joins", function()
	-- uncapped seen 4, 4, 5, 5 and 7 (median 5): 4 is 1 under it, so the rotation's least-seen level is 4; the card at 7 is
	-- ahead and lifts nobody; the capped m sits at 1, rationed by its cap, and keeps it
	local MOM = { group = "mom", per = "week", max = 2 }
	local d = { cards = { card("a", "v1"), card("b", "v2"), card("c", "v3"), card("d", "v4"), card("e", "v5"),
		card("m", "vm", { cap = MOM }) }, followups = {}, sponsors = {} }
	local o = opts({ day = 70, week = 10 })
	local base = { a = 4, b = 5, c = 5, d = 7, e = 4, m = 1 }
	local s = state({ count = 60, seen = copy(base), caps = {} })
	eq("level: Seed changes nothing", R.Seed(s, d, o), 0)
	for k, v in pairs(base) do eq("level: Seed leaves " .. k, s.seen[k], v) end
	-- e at 3, 2 under the median: it joins the least-seen level, 4
	local behind = copy(base)
	behind.e = 3
	local s2 = state({ count = 60, seen = behind, caps = {} })
	eq("level: 2 under the median: Seed changes one card", R.Seed(s2, d, o), 1)
	eq("level: 2 under the median: e joins at 4", s2.seen.e, 4)
	eq("level: 2 under the median: a stays at 4", s2.seen.a, 4)
	eq("level: 2 under the median: m stays at 1", s2.seen.m, 1)
end)

case("aired: needs opts.aired", function()
	local d = { cards = { card("onair", "v1", { aired = true }), card("plain", "v2") }, followups = {}, sponsors = {} }
	for _, r in ipairs({ LOW, HIGH }) do
		local s = state({ count = 3, seen = { plain = 1 } })
		eq("aired nil -> plain", idOf(pick("aired nil", s, d, opts({ rng = r }))), "plain")
		eq("aired false -> plain", idOf(pick("aired false", s, d, opts({ rng = r, aired = false }))), "plain")
		eq("aired true -> onair", idOf(pick("aired true", s, d, opts({ rng = r, aired = true }))), "onair")
	end
end)

case("phone: an artist who just walked in can't DM for cooldown walk-ins", function()
	-- va walked in at count 5 (last = 5); the existing cooldown check holds the phone Pick too
	local d = { cards = { dm("dm_va", "va"), dm("dm_vb", "vb"), card("walk", "vc") }, followups = {}, sponsors = {} }
	for _, r in ipairs({ LOW, HIGH }) do
		for _, n in ipairs({ 5, 6, 7 }) do
			local s = state({ count = n, last = { va = 5 }, seen = { dm_vb = 1 } })
			eq("phone cooldown at count " .. n, idOf(pick("phone cooldown " .. n, s, d, opts({ rng = r, source = "phone" }))), "dm_vb")
		end
		local s = state({ count = 8, last = { va = 5 }, seen = { dm_vb = 1 } })
		eq("phone cooldown served at count 8", idOf(pick("phone cooldown 8", s, d, opts({ rng = r, source = "phone" }))), "dm_va")
	end
end)

case("stored pick re-validated", function()
	local rookie = card("rookie", "v1", { under = { money = 200 } })
	local d = { cards = { rookie, card("plain", "v2") }, followups = {}, sponsors = {} }
	local s = state({ count = 3 })
	eq("Revalidate money 199", R.Revalidate(s, d, opts({ career = have({ money = 199 }, 3) }), rookie), true)
	eq("Revalidate money 200", R.Revalidate(s, d, opts({ career = have({ money = 200 }, 3) }), rookie), false)
	eq("Revalidate ignores exclude", R.Revalidate(s, d, opts({ career = have({}, 3), exclude = { rookie = true } }), rookie), true)
	unchanged("Revalidate", s, 0, {}, {})
	-- the full eligibility: source, caps, aired, when and minCount too
	local function rv(c, extra)
		return R.Revalidate(state({ count = 3, caps = { g = { key = 0, n = 1 } } }), d, opts(extra), c)
	end
	eq("Revalidate source mismatch", rv(dm("dm", "v3")), false)
	eq("Revalidate cap reached", rv(card("capped", "v3", { cap = { group = "g", per = "week", max = 1 } }), { day = 0, week = 0 }), false)
	eq("Revalidate cap in a new week", rv(card("capped", "v3", { cap = { group = "g", per = "week", max = 1 } }), { day = 7, week = 1 }), true)
	eq("Revalidate aired", rv(card("onair", "v3", { aired = true }), { aired = false }), false)
	eq("Revalidate when", rv(card("boss", "v3", { when = "sponsored" })), false)
	eq("Revalidate minCount", rv(card("late", "v3", { minCount = 9 })), false)
	eq("Revalidate a plain card", rv(card("plain", "v2")), true)
end)

case("stored pick re-validated: cooldown", function()
	local stored = card("x_card", "vx")
	local d = { cards = { stored }, followups = {}, sponsors = {} }
	eq("Revalidate artist within cooldown", R.Revalidate(state({ count = 4, last = { vx = 3 } }), d, opts(), stored), false)
	eq("Revalidate artist cooldown served", R.Revalidate(state({ count = 4, last = { vx = 1 } }), d, opts(), stored), true)
	eq("Revalidate artist never seen", R.Revalidate(state({ count = 4 }), d, opts(), stored), true)
end)

case("stored pick re-validated: nil card (a follow-up pick) → true", function()
	eq("Revalidate nil card", R.Revalidate(state({ count = 4 }), deck, opts(), nil), true)
end)

case("capKeys: CapKeys(86399) == 0, 0 and CapKeys(7 * 86400) == 7, 1", function()
	local day, week = R.CapKeys(86399)
	eq("CapKeys(86399) day", day, 0)
	eq("CapKeys(86399) week", week, 0)
	day, week = R.CapKeys(7 * 86400)
	eq("CapKeys(7 days) day", day, 7)
	eq("CapKeys(7 days) week", week, 1)
	day, week = R.CapKeys(7 * 86400 - 1)
	eq("CapKeys(7 days - 1 s) day", day, 6)
	eq("CapKeys(7 days - 1 s) week", week, 0)
end)

case("exclude: an excluded card is left out of the least-seen pool, so the next tier is drawn when it was the only one left", function()
	local d = { cards = { card("a", "v1"), card("b", "v2"), card("c", "v3") }, followups = {}, sponsors = {} }
	local s = state({ count = 3, seen = { a = 0, b = 1, c = 1 } })
	for _, r in ipairs({ LOW, HIGH }) do
		eq("no exclude -> a", idOf(pick("exclude none", s, d, opts({ rng = r }))), "a")
	end
	local rng2, calls2 = seq({ 2 })
	eq("exclude a -> the next tier", idOf(pick("exclude a", s, d, opts({ rng = rng2, exclude = { a = true } }))), "c")
	eq("exclude a draws over b and c", calls2[1] and calls2[1][1] == 1 and calls2[1][2] == 2, true)
	eq("exclude all -> nil", pick("exclude all", s, d, opts({ exclude = { a = true, b = true, c = true } })), nil)
	-- the first card and Seed honour it too
	local fd = { cards = { card("solo", "vf", { first = true }), card("z", "v9") }, followups = {}, sponsors = {} }
	eq("exclude the first card -> a normal draw", idOf(pick("exclude first", state({ count = 0 }), fd, opts({ rng = (seq({ 1 })), career = have({}, 0), exclude = { solo = true } }))), "z")
	local ss = state({ count = 3, seen = { a = 2 } })
	eq("Seed skips an excluded card", R.Seed(ss, d, opts({ exclude = { b = true } })), 1)
	eq("Seed leaves the excluded card", ss.seen.b, nil)
	eq("Seed c joins at 2", ss.seen.c, 2)
end)

case("exclude: an excluded due follow-up is skipped and the next due one, or a card, is taken", function()
	local P1 = { id = "p1", visitor = "v1", source = "phone", tag = "", line = "", resolve = FU.resolve }
	local P2 = { id = "p2", visitor = "v2", source = "phone", tag = "", line = "", resolve = FU.resolve }
	local d = { cards = { dm("dm", "v3") }, followups = { p1 = P1, p2 = P2 }, sponsors = {} }
	local s = state({ count = 5, queue = { { id = "p1", at = 4 }, { id = "p2", at = 5 } } })
	eq("no exclude -> the lowest at", idOf(pick("exclude fu none", s, d, opts({ source = "phone" }))), "p1")
	local got = pick("exclude p1", s, d, opts({ source = "phone", exclude = { p1 = true } }))
	eq("exclude p1 -> the next due one", got and got.kind == "followup" and got.entry, s.queue[2])
	got = pick("exclude both", s, d, opts({ rng = (seq({ 1 })), source = "phone", exclude = { p1 = true, p2 = true } }))
	eq("exclude both -> a card", got and got.kind == "card" and got.card.id, "dm")
end)

case("exclude: absent → identical rng draw count", function()
	-- a regression guard (it passes on the old code too): today's opts, an empty exclude and one naming an unknown id
	-- all make the same single rng(1, 4) draw and pick the same card
	for i, ex in ipairs({ false, {}, { nobody = true } }) do
		local s = state({ seen = { a = 3, b = 2, c = 2 } })
		local rng3, calls3 = seq({ 3 })
		local got = pick("exclude absent " .. i, s, deckSeen, opts({ rng = rng3, exclude = ex or nil }))
		eq("exclude absent " .. i .. " draw count", #calls3, 1)
		eq("exclude absent " .. i .. " draw range", calls3[1] and calls3[1][1] == 1 and calls3[1][2] == 4, true)
		eq("exclude absent " .. i .. " card", idOf(got), "b")
	end
end)

local VISITORS = { vx = { id = "vx", kind = "artist" }, vy = { id = "vy", kind = "artist" },
	studio = { id = "studio", kind = "sender" }, rep = { id = "rep", kind = "rep" } }

case("markSent: after MarkSent(dm from artist X), a walk-in Pick never returns an X card until opts.cooldown more arrivals, and Revalidate rejects a stored X pick", function()
	local xWalk, xDm = card("x_walk", "vx"), dm("x_dm", "vx")
	local d = { cards = { xWalk, card("y_walk", "vy"), xDm }, followups = {}, sponsors = {}, visitors = VISITORS }
	local s = state({ count = 5, today = 2, seen = { y_walk = 1 }, caps = {}, queue = { { id = "fu", at = 99 } } })
	for _, r in ipairs({ LOW, HIGH }) do
		eq("before MarkSent X walks in", idOf(pick("markSent before", s, d, opts({ rng = r }))), "x_walk")
	end
	eq("before MarkSent a stored X pick is valid", R.Revalidate(s, d, opts(), xWalk), true)
	R.MarkSent(s, xDm, d)
	eq("MarkSent sets last to count", s.last.vx, 5)
	eq("MarkSent leaves count", s.count, 5)
	eq("MarkSent leaves today", s.today, 2)
	eq("MarkSent leaves queue", #s.queue, 1)
	eq("MarkSent leaves caps", next(s.caps), nil)
	unchanged("MarkSent", s, 1, { y_walk = 1 }, { vx = 5 })
	for _, n in ipairs({ 5, 6, 7 }) do
		s.count = n
		for _, r in ipairs({ LOW, HIGH }) do
			eq("no X walk-in at count " .. n, idOf(pick("markSent cooldown " .. n, s, d, opts({ rng = r }))), "y_walk")
		end
		eq("Revalidate rejects a stored X pick at count " .. n, R.Revalidate(s, d, opts(), xWalk), false)
		eq("no X DM at count " .. n, pick("markSent phone " .. n, s, d, opts({ source = "phone" })), nil)
	end
	s.count = 8
	for _, r in ipairs({ LOW, HIGH }) do
		eq("X walks in after the cooldown", idOf(pick("markSent served", s, d, opts({ rng = r }))), "x_walk")
	end
	eq("a stored X pick is valid after the cooldown", R.Revalidate(s, d, opts(), xWalk), true)
end)

case("markSent: a phone-only sender (kind \"sender\") leaves last unchanged", function()
	local d = { cards = {}, followups = {}, sponsors = {}, visitors = VISITORS }
	local s = state({ count = 5 })
	R.MarkSent(s, card("studio_dm", "studio", { source = "phone", app = "STUDIO" }), d)
	eq("a sender leaves last", s.last.studio, nil)
	R.MarkSent(s, dm("rep_dm", "rep"), d)
	eq("a role visitor leaves last", s.last.rep, nil)
	R.MarkSent(s, dm("ghost_dm", "nobody"), d)
	eq("an unknown visitor leaves last", s.last.nobody, nil)
	R.MarkSent(s, dm("x_dm", "vx"), { cards = {}, followups = {}, sponsors = {} })
	eq("a deck without visitors leaves last", s.last.vx, nil)
	eq("nothing set", next(s.last), nil)
	-- a phone follow-up from an artist counts like a card
	R.MarkSent(s, { id = "clip", visitor = "vy", source = "phone", tag = "", line = "", resolve = FU.resolve }, d)
	eq("an artist's follow-up sets last", s.last.vy, 5)
end)

case("markSent: an existing outcome cooldown (last > count) is never shortened", function()
	local d = { cards = {}, followups = {}, sponsors = {}, visitors = VISITORS }
	local s = state({ count = 5, last = { vx = 9, vy = 2 } })
	R.MarkSent(s, dm("x_dm", "vx"), d)
	eq("a last ahead of count is kept", s.last.vx, 9)
	R.MarkSent(s, dm("y_dm", "vy"), d)
	eq("an older last moves up to count", s.last.vy, 5)
end)

-- Wave 1b: RushGap (rush hour, design 4.5) ---------------------------------------------------------------------------
-- draw follows rng(lo, hi) (`seq` scripts it and records each range); roll() -> a number in [0, 1). A burst's short
-- gaps plus its quiet gap add up to the normal gaps they replace. A rush handed back in is frozen, so writes throw
local RUSH = { Chance = 0.15, Size = { 2, 3 }, Short = { 10, 20 } }
local GAP = { 240, 360 }
-- a roll that returns `values` in order; running out is a failure. The second result reads how many rolls were taken
local function rolls(values)
	local n = 0
	return function()
		n += 1
		if values[n] == nil then error("roll called more often than expected") end
		return values[n]
	end, function() return n end
end
local function noRoll() error("roll must not be called") end
local function ranges(name, drawn, want)
	eq(name .. " draws", #drawn, #want)
	for i, w in ipairs(want) do
		eq(name .. " draw " .. i .. " range", drawn[i] and drawn[i][1] == w[1] and drawn[i][2] == w[2], true)
	end
end

case("rushGap: no rush and a roll at or above Chance draw one normal gap and start nothing", function()
	local draw, drawn = seq({ 300 })
	local roll, rolled = rolls({ 0.5 })
	local g, rush = R.RushGap(nil, RUSH, GAP, draw, roll, true)
	eq("RushGap no start: gap", g, 300)
	eq("RushGap no start: no rush", rush, nil)
	eq("RushGap no start: one roll", rolled(), 1)
	ranges("RushGap no start:", drawn, { GAP })
end)

case("rushGap: allowStart false starts no burst, even on a winning roll", function()
	local draw, drawn = seq({ 280 })
	local roll, rolled = rolls({ 0.1 })
	local g, rush = R.RushGap(nil, RUSH, GAP, draw, roll, false)
	eq("RushGap allowStart false: gap", g, 280)
	eq("RushGap allowStart false: no rush", rush, nil)
	eq("RushGap allowStart false: roll never called", rolled(), 0)
	ranges("RushGap allowStart false:", drawn, { GAP })
end)

-- RushRoom (Task H): a burst starts only when today's visits leave room for its smallest size before DailyMax; a
-- stored day that isn't today counts 0 (the rollover would reset it), so there is room
case("rushRoom: today 7 of 8 on the same day leaves no room for a burst of 2", function()
	eq("RushRoom 7/8 same day", R.RushRoom(7, 8, RUSH.Size, true), false)
end)
case("rushRoom: today 6 of 8 on the same day fits a burst of 2", function()
	eq("RushRoom 6/8 same day", R.RushRoom(6, 8, RUSH.Size, true), true)
end)
case("rushRoom: today 7 on a new day has room (it rolls over to 0)", function()
	eq("RushRoom 7/8 new day", R.RushRoom(7, 8, RUSH.Size, false), true)
end)
case("rushRoom: today 8 of 8 on the same day has no room", function()
	eq("RushRoom 8/8 same day", R.RushRoom(8, 8, RUSH.Size, true), false)
end)

case("rushGap: a burst of 3 short gaps, then a quiet gap that carries what they saved", function()
	-- draws in order: Size 3; each burst call a normal gap then a short gap; the quiet call one normal gap
	local draw, drawn = seq({ 3, 300, 12, 250, 15, 360, 20, 330 })
	local roll, rolled = rolls({ 0.1 })
	local g1, r1 = R.RushGap(nil, RUSH, GAP, draw, roll, true)
	eq("RushGap start: short gap", g1, 12)
	eq("RushGap start: left", r1 and r1.left, 2)
	eq("RushGap start: saved = g - s", r1 and r1.saved, 300 - 12)
	table.freeze(r1)
	-- a running burst never rolls
	local g2, r2 = R.RushGap(r1, RUSH, GAP, draw, noRoll, true)
	eq("RushGap 2nd: short gap", g2, 15)
	eq("RushGap 2nd: left", r2 and r2.left, 1)
	eq("RushGap 2nd: saved", r2 and r2.saved, 288 + 235)
	eq("RushGap 2nd: a new table", r2 ~= r1, true)
	eq("RushGap 2nd: caller's rush unchanged", r1.left == 2 and r1.saved == 288, true)
	table.freeze(r2)
	-- allowStart false (a no-pick re-arm) only stops a new burst: this one carries on
	local g3, r3 = R.RushGap(r2, RUSH, GAP, draw, noRoll, false)
	eq("RushGap 3rd: short gap", g3, 20)
	eq("RushGap 3rd: left", r3 and r3.left, 0)
	eq("RushGap 3rd: saved", r3 and r3.saved, 523 + 340)
	eq("RushGap 3rd: a new table", r3 ~= r2, true)
	eq("RushGap 3rd: caller's rush unchanged", r2.left == 1 and r2.saved == 523, true)
	table.freeze(r3)
	local g4, r4 = R.RushGap(r3, RUSH, GAP, draw, noRoll, true)
	eq("RushGap quiet: normal gap + saved", g4, 330 + 863)
	eq("RushGap quiet: the rush ends", r4, nil)
	eq("RushGap quiet: caller's rush unchanged", r3.left == 0 and r3.saved == 863, true)
	-- over the cycle the four gaps add up to the four normal draws
	eq("RushGap cycle sum", g1 + g2 + g3 + g4, 300 + 250 + 360 + 330)
	eq("RushGap cycle: one roll", rolled(), 1)
	ranges("RushGap cycle:", drawn, { RUSH.Size, GAP, RUSH.Short, GAP, RUSH.Short, GAP, RUSH.Short, GAP })
end)

-- Admit: FIFO up to max walking
local a, b, c, d4 = {}, {}, {}, {}
local adm, rest = R.Admit(2, { a, b, c }, 3)
eq("Admit 2/3 admitted", #adm == 1 and adm[1] == a, true)
eq("Admit 2/3 rest", #rest == 2 and rest[1] == b and rest[2] == c, true)
adm, rest = R.Admit(0, { a, b, c, d4 }, 3)
eq("Admit 0/3 admitted", #adm == 3 and adm[1] == a and adm[2] == b and adm[3] == c, true)
eq("Admit 0/3 rest", #rest == 1 and rest[1] == d4, true)
adm, rest = R.Admit(3, { a }, 3)
eq("Admit full", #adm == 0 and #rest == 1, true)

-- Fill: names first, then {sponsor}
local names = { navx = "LIL NAV X", rep = "a suit from {sponsor}" }
eq("Fill name", R.Fill("{name:navx} wants a placement", names), "LIL NAV X wants a placement")
eq("Fill rep name holds sponsor", R.Fill("{name:rep}", names, "NYKE"), "a suit from NYKE")
eq("Fill both", R.Fill("{name:navx} x {sponsor}", names, "RED BULB"), "LIL NAV X x RED BULB")
eq("Fill plain", R.Fill("no tokens", names), "no tokens")
eq("Fill percent safe", R.Fill("{name:p}", { p = "100%" }), "100%")
eq("Fill unknown left", R.Fill("{name:nobody}", names), "{name:nobody}")

-- RoomOf / InHub
eq("RoomOf 11.9", R.RoomOf(11.9), "Corridor")
eq("RoomOf 12", R.RoomOf(12), "Lounge")
eq("RoomOf 44", R.RoomOf(44), "Control")
eq("RoomOf 80", R.RoomOf(80), "Booth")
eq("InHub lounge", R.InHub(50, 3, 0), true)
eq("InHub passage", R.InHub(50, 3, 30), false)
eq("InHub high", R.InHub(50, 25, 0), false)
eq("InHub west", R.InHub(-1, 3, 0), false)
eq("InHub edge", R.InHub(94, 3, -12), true)
-- the corridor (x < 12) only between its walls (z 0..10): the Interscope passage (z < 0) and the Studio Two passage
-- (z > 10) open off it
eq("InHub corridor", R.InHub(6, 3, 5), true)
eq("InHub Interscope passage", R.InHub(6, 3, -8), false)
eq("InHub Studio Two passage", R.InHub(6, 3, 15), false)
eq("InHub corridor south wall", R.InHub(6, 3, 0), true)
eq("InHub corridor north wall", R.InHub(6, 3, 10), true)
eq("InHub corridor just south", R.InHub(11.9, 3, -0.5), false)
eq("InHub lounge south", R.InHub(30, 3, -10), true)
eq("InHub lounge corner", R.InHub(12, 3, -12), true)
eq("InHub corridor high", R.InHub(6, 25, 5), false)

-- Present (the Your Rooms plan, Task 5): where a position counts for walk-ins. The hub first (InHub: "hub", no index),
-- else the first of your rooms' boxes ({ x0, z0, x1, z1 }, world x and z, edges inside; Rooms.BoxesFor) that holds it
-- with 0 <= y < 20 ("room", its index), else nil. Two rooms side by side, as RoomRules.Box gives slot 1's bedroom and home
local BOXES = { { 6003.82, -2015.415, 6016.18, -2000.585 }, { 6028, -2020.6, 6052, -2000.6 } }
local function present(x, y, z, boxes)
	local where, i = R.Present(x, y, z, boxes)
	return tostring(where) .. "/" .. tostring(i)
end
eq("Present hub, no boxes", present(30, 3, 0, {}), "hub/nil")
eq("Present hub corridor", present(6, 3, 5, BOXES), "hub/nil")
eq("Present room 1", present(6010, 3, -2008, BOXES), "room/1")
eq("Present room 2", present(6040, 3, -2010, BOXES), "room/2")
eq("Present room 2 edge", present(6028, 3, -2020.6, BOXES), "room/2")
eq("Present room 2 far edge", present(6052, 3, -2000.6, BOXES), "room/2")
eq("Present room floor y 0", present(6040, 0, -2010, BOXES), "room/2")
eq("Present room y 19.9", present(6040, 19.9, -2010, BOXES), "room/2")
eq("Present room y 20", present(6040, 20, -2010, BOXES), "nil/nil")
eq("Present room high y 25", present(6040, 25, -2010, BOXES), "nil/nil")
eq("Present under the floor", present(6040, -0.1, -2010, BOXES), "nil/nil")
eq("Present outside both", present(6100, 3, -2010, BOXES), "nil/nil")
eq("Present between the rooms", present(6020, 3, -2010, BOXES), "nil/nil")
eq("Present just south of room 2 (its wall)", present(6040, 3, -2000.5, BOXES), "nil/nil")
eq("Present on the landing (plot-local z 0..8)", present(6040, 3, -1996, BOXES), "nil/nil")
eq("Present Studio Two passage", present(6, 3, 15, BOXES), "nil/nil")
eq("Present nil boxes", present(6040, 3, -2010, nil), "nil/nil")
eq("Present nil boxes in the hub", present(50, 3, 0, nil), "hub/nil")
-- the hub wins over a box that overlaps it; the hub's own height rule (y 25) is not rescued by the box
local OVER = { { 0, -20, 100, 20 } }
eq("Present hub over a box", present(30, 3, 0, OVER), "hub/nil")
eq("Present box around the hub, off the hub", present(98, 3, 0, OVER), "room/1")
eq("Present hub high inside a box", present(30, 25, 0, OVER), "nil/nil")
-- the first box that holds the point wins
eq("Present first box wins", present(10, 3, 18, { { 0, 15, 20, 30 }, { 0, 0, 50, 50 } }), "room/1")

-- CypherHolds (launch audit A2/A4 "for scale"): walk-ins and phone pops wait for everyone while the room listens to the
-- entries or votes; in a lobby, the build and the reveal only for that round's entrants (CypherIn equal to the cypher's
-- Round; one left from an earlier round is stale and holds nothing); idle, no phase (no RS.OK.Cypher yet) and junk hold
-- no one. Every phase against an entrant, an outsider (no CypherIn) and a stale entrant
local ROUND = 12
local WHO = { { "entrant", ROUND }, { "outsider", nil }, { "stale", ROUND - 1 } }
local HOLDS = { -- phase -> entrant, outsider, stale
	{ "listen", true, true, true }, { "vote", true, true, true },
	{ "lobby", true, false, false }, { "build", true, false, false }, { "reveal", true, false, false },
	{ "idle", false, false, false }, { nil, false, false, false }, { 7, false, false, false }, { "party", false, false, false },
}
for _, row in ipairs(HOLDS) do
	for i, who in ipairs(WHO) do
		eq("CypherHolds " .. tostring(row[1]) .. " " .. who[1], R.CypherHolds(row[1], who[2], ROUND), row[i + 1])
	end
end
-- no Round, or an entrant value that isn't a round number, holds no one outside listen and vote
eq("CypherHolds lobby no round", R.CypherHolds("lobby", ROUND, nil), false)
eq("CypherHolds lobby nothing", R.CypherHolds("lobby", nil, nil), false)
eq("CypherHolds lobby string in", R.CypherHolds("lobby", "12", ROUND), false)
eq("CypherHolds build true in", R.CypherHolds("build", true, true), false)
eq("CypherHolds vote no round", R.CypherHolds("vote", nil, nil), true)

-- Route: the room's chain plus an arrival point short of the target
local W = { Corridor = { { 1.5, 5 }, { 9, 5 } }, Lounge = { { 1.5, 5 }, { 9, 5 }, { 16, 5 } },
	Control = { { 1.5, 5 }, { 9, 5 }, { 16, 5 }, { 40, 0 }, { 47, 0 } },
	Booth = { { 1.5, 5 }, { 9, 5 }, { 16, 5 }, { 40, 0 }, { 47, 0 }, { 77, 6 }, { 83, 6 } } }
local route = R.Route(60, 0, W, 4)
eq("Route control length", #route, 6)
for i, w in ipairs(W.Control) do
	near("Route control x" .. i, route[i] and route[i][1], w[1])
	near("Route control z" .. i, route[i] and route[i][2], w[2])
end
near("Route arrival x", route[6] and route[6][1], 56)
near("Route arrival z", route[6] and route[6][2], 0)
eq("Route copies points", route[1] ~= W.Control[1], true)
route = R.Route(24, 11, W, 4)
eq("Route lounge length", #route, 4)
near("Route lounge arrival x", route[4] and route[4][1], 20.8)
near("Route lounge arrival z", route[4] and route[4][2], 8.6)
route = R.Route(17, 5, W, 4)
eq("Route already in range: no arrival point", #route, 3)

-- AfterFirst (F4): a system plant before any walk-in moves one later on both ends, so it can never be the first walk-in
local plantAt = { 1, 2 }
local shifted = R.AfterFirst({ count = 0 }, plantAt)
eq("AfterFirst at count 0: low", shifted[1], 2)
eq("AfterFirst at count 0: high", shifted[2], 3)
eq("AfterFirst leaves the caller's table", plantAt[1], 1)
eq("AfterFirst after a walk-in: the same range", R.AfterFirst({ count = 1 }, plantAt), plantAt)
local firstState = { count = 0, queue = {} }
local firstPlant = R.Plant(firstState, { id = "tier_x", at = R.AfterFirst(firstState, { 1, 2 }) }, { 1, 2 }, function(lo) return lo end)
eq("a plant shifted at count 0 is not due at the first pick", firstPlant.at, 2)
eq("a plant shifted at count 0 can't be picked first", firstPlant.at > firstState.count + 1, true)

-- Wave 3 "Stakes": the beat, the relationship, the hints and the tilted odds
local ODDS3 = { auraPer = 20, auraCap = 15, followersPer = 1000, followersCap = 10, min = 10, max = 90,
	beatCenter = 3, beatPer = 4, relPer = 4 }
local ODDS3B = { beatCenter = 3, beatPer = 5, relPer = 2 }

-- BeatQuality: stars, +1 once the room has fired it 3 times, held to 0..4
eq("BeatQuality nil", R.BeatQuality(nil), 0)
eq("BeatQuality 0/0", R.BeatQuality({ stars = 0, fires = 0 }), 0)
eq("BeatQuality 2/2", R.BeatQuality({ stars = 2, fires = 2 }), 2)
eq("BeatQuality 3/3", R.BeatQuality({ stars = 3, fires = 3 }), 4)
eq("BeatQuality 3/40", R.BeatQuality({ stars = 3, fires = 40 }), 4)

eq("BeatQuality 0/3", R.BeatQuality({ stars = 0, fires = 3 }), 1)
eq("BeatQuality 1/6", R.BeatQuality({ stars = 1, fires = 6 }), 2)

-- BestBeat: highest quality, ties to the first (newest)
local b1, b2, b3 = { pattern = "a", stars = 2, fires = 0 }, { pattern = "b", stars = 3, fires = 0 }, { pattern = "c", stars = 3, fires = 1 }
eq("BestBeat highest", R.BestBeat({ b1, b2 }), b2)
eq("BestBeat tie to first", R.BestBeat({ b1, b2, b3 }), b2)
eq("BestBeat empty", R.BestBeat({}), nil)
local f0, f3 = { pattern = "p", stars = 2, fires = 0 }, { pattern = "q", stars = 2, fires = 3 }
eq("BestBeat fires lift", R.BestBeat({ f0, f3 }), f3)

-- RecentPush: merge by pattern, stars max, front, cap
local rec = R.RecentPush({}, { pattern = "A", bpm = 90, stars = 1, fires = 0, day = 1 }, 3)
rec = R.RecentPush(rec, { pattern = "B", bpm = 100, stars = 1, fires = 0, day = 2 }, 3)
eq("RecentPush new at front", rec[1].pattern, "B")
rec = R.RecentPush(rec, { pattern = "A", bpm = 90, stars = 2, fires = 0, day = 3 }, 3)
rec = R.RecentPush(rec, { pattern = "A", bpm = 90, stars = 3, fires = 0, day = 4 }, 3)
eq("RecentPush merged count", #rec, 2)
eq("RecentPush merged front", rec[1].pattern, "A")
eq("RecentPush merged stars", rec[1].stars, 3)
rec = R.RecentPush(rec, { pattern = "A", bpm = 90, stars = 1, fires = 0, day = 5 }, 3)
eq("RecentPush keeps higher stars", rec[1].stars, 3)
rec = R.RecentPush(rec, { pattern = "C", bpm = 80, stars = 1, fires = 0, day = 6 }, 3)
rec = R.RecentPush(rec, { pattern = "D", bpm = 80, stars = 1, fires = 0, day = 7 }, 3)
eq("RecentPush capped", #rec, 3)
eq("RecentPush drops the last", rec[3].pattern, "A")

-- RecentPush keeps the fires a known beat has
local rk = {}
for _ = 1, 3 do rk = R.RecentFire(rk, "X", 120, 1, 3) end
rk = R.RecentPush(rk, { pattern = "X", bpm = 120, stars = 2, fires = 0, day = 2 }, 3)
eq("RecentPush keeps fires: one entry", #rk, 1)
eq("RecentPush keeps fires: stars", rk[1].stars, 2)
eq("RecentPush keeps fires: fires", rk[1].fires, 3)

-- RecentFire: find or create, fires += 1, position kept
local rf = R.RecentFire({}, "X", 142, 5, 3)
eq("RecentFire creates at front", rf[1].pattern, "X")
eq("RecentFire creates stars 0", rf[1].stars, 0)
eq("RecentFire creates fires 1", rf[1].fires, 1)
eq("RecentFire creates bpm", rf[1].bpm, 142)
rf = R.RecentPush(rf, { pattern = "Y", bpm = 90, stars = 1, fires = 0, day = 6 }, 3)
rf = R.RecentFire(rf, "X", 142, 7, 3)
rf = R.RecentFire(rf, "X", 142, 7, 3)
eq("RecentFire known fires", rf[2].fires, 3)
eq("RecentFire known position", rf[2].pattern, "X")
eq("RecentFire known count", #rf, 2)

-- RecentFire on a full list (Wave 3 final review I2, ruling B): the new beat goes to the front and is always kept; the
-- lowest-quality older entry makes room, a tie to the oldest (the last). With equal qualities that is the last one
local full = { { pattern = "A", stars = 1, fires = 0 }, { pattern = "B", stars = 1, fires = 0 }, { pattern = "C", stars = 1, fires = 0 } }
local fz = R.RecentFire(full, "Z", 100, 9, 3)
eq("RecentFire full: front", fz[1].pattern, "Z")
eq("RecentFire full: fires", fz[1].fires, 1)
eq("RecentFire full: count", #fz, 3)
eq("RecentFire full, all equal: the oldest (C) goes", fz[3].pattern, "B")
eq("RecentFire full, all equal: A kept", fz[2].pattern, "A")
local function pats(list) local t = {} for i, e in ipairs(list) do t[i] = e.pattern end return table.concat(t, ",") end
-- the ruling's case: [3* A, 2* B, 2* C] + a FIRE on Z gives [Z, A, B]; the best quality is still A's
local best = { { pattern = "A", stars = 3, fires = 0 }, { pattern = "B", stars = 2, fires = 0 }, { pattern = "C", stars = 2, fires = 0 } }
local bz = R.RecentFire(best, "Z", 100, 9, 3)
eq("RecentFire full [3A,2B,2C] + Z", pats(bz), "Z,A,B")
eq("RecentFire full [3A,2B,2C] + Z: best is A", R.BestBeat(bz).pattern, "A")
eq("RecentFire full [3A,2B,2C] + Z: best quality 3", R.BeatQuality(R.BestBeat(bz)), 3)
-- the best beat oldest: [2* A, 2* B, 3* C] + Z drops B (the oldest of the two 2-stars), never C
local old = { { pattern = "A", stars = 2, fires = 0 }, { pattern = "B", stars = 2, fires = 0 }, { pattern = "C", stars = 3, fires = 0 } }
eq("RecentFire full, best oldest: [2A,2B,3C] + Z keeps C", pats(R.RecentFire(old, "Z", 100, 9, 3)), "Z,A,C")
-- the lowest not last: [1* A, 3* B, 2* C] + Z drops A
local low = { { pattern = "A", stars = 1, fires = 0 }, { pattern = "B", stars = 3, fires = 0 }, { pattern = "C", stars = 2, fires = 0 } }
eq("RecentFire full, lowest first: [1A,3B,2C] + Z drops A", pats(R.RecentFire(low, "Z", 100, 9, 3)), "Z,B,C")
-- quality counts FIRE: [2* A 3 fires (q3), 2* B, 3* C] + Z drops B
local fq = { { pattern = "A", stars = 2, fires = 3 }, { pattern = "B", stars = 2, fires = 0 }, { pattern = "C", stars = 3, fires = 0 } }
eq("RecentFire full, quality counts FIRE: [2A+3f,2B,3C] + Z drops B", pats(R.RecentFire(fq, "Z", 100, 9, 3)), "Z,A,C")
-- the review's evening: [3* A, 2* B, 2* C], then three aired-only beats D, E, F one FIRE each: A stays, its quality 3
local eve = { { pattern = "A", stars = 3, fires = 0 }, { pattern = "B", stars = 2, fires = 0 }, { pattern = "C", stars = 2, fires = 0 } }
for _, x in ipairs({ "D", "E", "F" }) do eve = R.RecentFire(eve, x, 100, 9, 3) end
eq("RecentFire three aired-only beats: [F, A, B]", pats(eve), "F,A,B")
eq("RecentFire three aired-only beats: best quality stays 3", R.BeatQuality(R.BestBeat(eve)), 3)
-- an aired-only beat joins even when it is the lowest; a list over max (bad data) comes back at max; max 1 keeps the new
eq("RecentFire the new one stays at q0", R.RecentFire(best, "Z", 100, 9, 3)[1].stars, 0)
local over = { { pattern = "A", stars = 3 }, { pattern = "B", stars = 1 }, { pattern = "C", stars = 2 }, { pattern = "D", stars = 0 } }
eq("RecentFire over max: lowest go first", pats(R.RecentFire(over, "Z", 100, 9, 3)), "Z,A,C")
eq("RecentFire max 1 keeps only the new", pats(R.RecentFire({ { pattern = "A", stars = 3 } }, "Z", 100, 9, 1)), "Z")
eq("RecentFire doesn't mutate its input", pats(best), "A,B,C")
local kd = { { pattern = "K", bpm = 90, stars = 3, fires = 0, day = 1 } }
for _ = 1, 3 do kd = R.RecentFire(kd, "K", 90, 2, 3) end
eq("RecentFire keeps stars", kd[1].stars, 3)
eq("RecentFire known fires 3", kd[1].fires, 3)

-- tilts
eq("BeatTilt q0", R.BeatTilt(0, ODDS3), -12)
eq("BeatTilt q2", R.BeatTilt(2, ODDS3), -4)
eq("BeatTilt q3", R.BeatTilt(3, ODDS3), 0)
eq("BeatTilt q4", R.BeatTilt(4, ODDS3), 4)
eq("RelTilt -3", R.RelTilt(-3, ODDS3), -12)
eq("RelTilt 3", R.RelTilt(3, ODDS3), 12)

eq("BeatTilt beatPer 5 q0", R.BeatTilt(0, ODDS3B), -15)
eq("BeatTilt beatPer 5 q4", R.BeatTilt(4, ODDS3B), 5)
eq("RelTilt relPer 2", R.RelTilt(3, ODDS3B), 6)

-- Chance / Resolve with a tilt
eq("Chance tilt after the caps", R.Chance(85, career({ aura = 400 }), ODDS3, -12), 88)
eq("Chance tilt 15", R.Chance(50, career(), ODDS3, 15), 65)
eq("Chance tilt clamps max", R.Chance(50, career(), ODDS3, 100), 90)
eq("Chance tilt clamps min", R.Chance(50, career(), ODDS3, -100), 10)
eq("ChoiceChance tilt", R.ChoiceChance({ odds = 50 }, career(), ODDS3, 15), 65)
eq("RollChance tilt", R.RollChance({ odds = 50 }, career(), ODDS3, -15), 35)
eq("RollChance sure ignores tilt", R.RollChance({ sure = true, good = GOOD }, career(), ODDS3, -15), 100)
local tr = R.Resolve(choice, career(), ODDS3, function() return 64 end, 15)
eq("Resolve tilted good", tr.roll, "good")
eq("Resolve tilted chance", tr.chance, 65)
eq("Resolve untilted bad", R.Resolve(choice, career(), ODDS3, function() return 64 end).roll, "bad")
local readyC = { text = "r", ready = true, good = GOOD, bad = BAD }
local ODDS3R = { auraPer = 20, auraCap = 15, followersPer = 1000, followersCap = 10, min = 10, max = 90, ready = E.READY }
local readyBase = R.ChoiceChance(readyC, career(), ODDS3R)
eq("ready choice tilted", R.ChoiceChance(readyC, career(), ODDS3R, 7), readyBase + 7)
eq("ready choice tilt clamps", R.ChoiceChance(readyC, career(), ODDS3R, 100), 90)

-- beatMin: no roll, no tilt
local bm = { text = "b", beatMin = 3, good = GOOD, bad = BAD }
local bmr = R.Resolve(bm, career(), ODDS3, noRng, 50, 3)
eq("beatMin met good", bmr.outcome, GOOD)
eq("beatMin met roll", bmr.roll, "sure")
eq("beatMin met chance", bmr.chance, 100)
local bml = R.Resolve(bm, career(), ODDS3, noRng, 50, 2)
eq("beatMin short bad", bml.outcome, BAD)
eq("beatMin short roll", bml.roll, "bad")
eq("beatMin short chance", bml.chance, 0)
eq("beatMin nil beatQ bad", R.Resolve(bm, career(), ODDS3, noRng).outcome, BAD)
eq("beatMin RollChance met", R.RollChance(bm, career(), ODDS3, 0, 4), 100)
eq("beatMin ChoiceChance short", R.ChoiceChance(bm, career(), ODDS3, 0, 1), 0)

-- RelWrite: rel is the map { [visitorId] = { score, flags } }; it is changed in place and returned
local rel = nil
for _ = 1, 5 do rel = R.RelWrite(rel, { score = 1 }, "mom", 4) end
eq("RelWrite clamps +3", rel.mom.score, 3)
eq("RelWrite clamps -3", R.RelWrite(rel, { score = -10 }, "mom", 4).mom.score, -3)
local rw = R.RelWrite({}, { who = "navx", flag = "tv" }, "mom", 9)
eq("RelWrite who flag", rw.navx.flags.tv, 9)
eq("RelWrite who leaves own", rw.mom, nil)
eq("RelWrite flag on own", R.RelWrite({}, { flag = "quiet" }, "mom", 6).mom.flags.quiet, 6)
local rw2 = R.RelWrite(rw, { who = "navx", clear = "tv" }, "mom", 9)
eq("RelWrite clear", rw2.navx.flags.tv, nil)
local rw3 = R.RelWrite({ mom = { score = 2, flags = { x = 1 } } }, {}, "mom", 3)
eq("RelWrite empty keeps score", rw3.mom.score, 2)
eq("RelWrite empty keeps flag", rw3.mom.flags.x, 1)
local rw4 = R.RelWrite({}, { who = "navx" }, "mom", 3)
eq("RelWrite who only no-op", rw4.navx, nil)
eq("RelWrite nil rel + empty", next(R.RelWrite(nil, {}, "mom", 3)), nil)

-- GateOk: relationship gates
local relMap = { homekid = { score = 2, flags = { blew_up = 4 } }, mom = { score = -2, flags = {} } }
local gk = { visitor = "homekid", needs = { flags = { "homekid.blew_up" } } }
eq("GateOk flag with", R.GateOk(gk, career(), 0, relMap), true)
eq("GateOk flag without", R.GateOk(gk, career(), 0, { homekid = { score = 0, flags = {} } }), false)
eq("GateOk flag unknown visitor", R.GateOk(gk, career(), 0, {}), false)
eq("GateOk flag nil rel", R.GateOk(gk, career(), 0, nil), false)
local gu = { visitor = "homekid", under = { flags = { "homekid.blew_up" } } }
eq("GateOk under flag with", R.GateOk(gu, career(), 0, relMap), false)
eq("GateOk under flag without", R.GateOk(gu, career(), 0, { homekid = { score = 0, flags = {} } }), true)
eq("GateOk under flag no entry", R.GateOk(gu, career(), 0, {}), true)
eq("GateOk under flag nil rel", R.GateOk(gu, career(), 0, nil), false)
eq("GateOk needs rel met", R.GateOk({ visitor = "homekid", needs = { rel = 2 } }, career(), 0, relMap), true)
eq("GateOk needs rel short", R.GateOk({ visitor = "mom", needs = { rel = 1 } }, career(), 0, relMap), false)
eq("GateOk under rel met", R.GateOk({ visitor = "mom", under = { rel = -1 } }, career(), 0, relMap), true)
eq("GateOk under rel short", R.GateOk({ visitor = "homekid", under = { rel = 2 } }, career(), 0, relMap), false)
eq("GateOk rel unknown visitor", R.GateOk({ visitor = "ghost", needs = { rel = 0 } }, career(), 0, relMap), false)
eq("GateOk rel nil", R.GateOk({ visitor = "homekid", needs = { rel = 0 } }, career(), 0, nil), false)
eq("GateOk no rel gates, rel nil", R.GateOk({ visitor = "homekid", needs = { aura = 0 } }, career(), 0, nil), true)
-- Pick / Seed / Revalidate pass opts.rel through
local rdeck = { cards = { { id = "g", visitor = "homekid", needs = { flags = { "homekid.blew_up" } } } }, followups = {}, sponsors = {} }
local function rstate() return { count = 0, queue = {}, seen = {}, last = {}, caps = {} } end
local ropts = function(rl) return { cooldown = 3, career = career({ visits = 0 }), rel = rl, rng = function() return 1 end } end
eq("Pick rel passes", R.Pick(rstate(), rdeck, ropts(relMap)) ~= nil, true)
eq("Pick rel missing", R.Pick(rstate(), rdeck, ropts(nil)), nil)
local rs = rstate()
eq("Seed rel passes", R.Seed(rs, rdeck, ropts(relMap)), 1)
eq("Seed rel missing", R.Seed(rstate(), rdeck, ropts(nil)), 0)
eq("Revalidate rel passes", R.Revalidate(rstate(), rdeck, ropts(relMap), rdeck.cards[1]), true)
eq("Revalidate rel missing", R.Revalidate(rstate(), rdeck, ropts(nil), rdeck.cards[1]), false)

-- system cards are never picked or seeded
local sysDeck = { cards = { { id = "s", visitor = "x", system = true } }, followups = {}, sponsors = {} }
local ss = rstate()
eq("Pick system only", R.Pick(ss, sysDeck, ropts(nil)), nil)
eq("Seed system only", R.Seed(ss, sysDeck, ropts(nil)), 0)
eq("Seed system left unseen", ss.seen.s, nil)
local mixDeck = { cards = { { id = "s", visitor = "x", system = true }, { id = "n", visitor = "y" } }, followups = {}, sponsors = {} }
local sawSystem = false
for i = 1, 40 do
	local o = ropts(nil)
	o.rng = function(lo, hi) return (i % hi) + 1 end
	local pk = R.Pick(rstate(), mixDeck, o)
	if pk == nil or pk.card.system then sawSystem = true end
end
eq("Pick mixed never system", sawSystem, false)

local gm = { visitor = "homekid", needs = { flags = { "homekid.blew_up" }, followers = 5000 } }
local blew = { homekid = { score = 0, flags = { blew_up = 1 } } }
eq("GateOk flags + stat short", R.GateOk(gm, career({ followers = 0 }), 0, blew), false)
eq("GateOk flags + stat met", R.GateOk(gm, career({ followers = 5000 }), 0, blew), true)
eq("GateOk two flags, one set", R.GateOk({ visitor = "homekid", needs = { flags = { "homekid.blew_up", "homekid.passed" } } }, career(), 0, blew), false)
eq("GateOk under rel unknown visitor", R.GateOk({ visitor = "ghost", under = { rel = 1 } }, career(), 0, relMap), false)

-- beatMin beats sure
local bs = { text = "s", beatMin = 3, sure = true, good = GOOD, bad = BAD }
eq("beatMin+sure short RollChance", R.RollChance(bs, career(), ODDS3, 0, 1), 0)
eq("beatMin+sure short Resolve", R.Resolve(bs, career(), ODDS3, noRng, 0, 1).outcome, BAD)
eq("beatMin+sure met", R.Resolve(bs, career(), ODDS3, noRng, 0, 3).outcome, GOOD)
local br = { text = "r", beatMin = 3, rare = RARE, rareOdds = 100, good = GOOD, bad = BAD }
eq("beatMin+rare never rolls", R.Resolve(br, career(), ODDS3, noRng, 0, 3).outcome, GOOD)

-- Fill: {beat}
eq("Fill beat bpm", R.Fill("you got {beat}?", nil, nil, 142), "you got the one at 142?")
eq("Fill beat nil", R.Fill("you got {beat}?", nil, nil, nil), "you got something?")
eq("Fill beat with name", R.Fill("{name:a} {beat}", { a = "Al" }, nil, 90), "Al the one at 90")

-- HintFor: whole words, case-insensitive, first unseen in hints order
local HINTS = { { term = "aura", text = "Your Aura tilts it" }, { term = "placement", text = "a placement" } }
local texts = { "Your Aura tilts it", "a placement" }
eq("HintFor aura first", (R.HintFor(texts, {}, HINTS) or {}).term, "aura")
eq("HintFor skips seen", (R.HintFor(texts, { aura = 1 }, HINTS) or {}).term, "placement")
eq("HintFor all seen", R.HintFor(texts, { aura = 1, placement = 1 }, HINTS), nil)
eq("HintFor whole word auras", R.HintFor({ "auras" }, {}, HINTS), nil)
eq("HintFor whole word plaurall", R.HintFor({ "plaurall" }, {}, HINTS), nil)
eq("HintFor case", (R.HintFor({ "AURA!" }, {}, HINTS) or {}).term, "aura")
eq("HintFor text", (R.HintFor({ "aura" }, {}, HINTS) or {}).text, "Your Aura tilts it")
eq("HintFor Laura", R.HintFor({ "Laura" }, {}, HINTS), nil)
eq("HintFor hints order beats texts order", (R.HintFor({ "a placement", "Your Aura" }, {}, HINTS) or {}).term, "aura")
eq("HintFor nil seen", (R.HintFor({ "aura" }, nil, HINTS) or {}).term, "aura")
-- the skip list (Wave 3 final review M2, ruling D): a card's `nohint` terms (and Systems/Phone's held ones) are passed over
-- as if seen, never the next term's chance; nil or empty skips nothing
eq("HintFor skip passes over a term", (R.HintFor(texts, {}, HINTS, { "aura" }) or {}).term, "placement")
eq("HintFor skip every term", R.HintFor(texts, {}, HINTS, { "aura", "placement" }), nil)
eq("HintFor skip with seen", R.HintFor(texts, { placement = 1 }, HINTS, { "aura" }), nil)
eq("HintFor skip nil", (R.HintFor(texts, {}, HINTS, nil) or {}).term, "aura")
eq("HintFor skip empty", (R.HintFor(texts, {}, HINTS, {}) or {}).term, "aura")
eq("HintFor skip a set", (R.HintFor(texts, {}, HINTS, { aura = true }) or {}).term, "placement")
eq("HintFor skip is exact (case as in Config)", (R.HintFor(texts, {}, HINTS, { "Aura" }) or {}).term, "aura")

if #fails > 0 then error(#fails .. " walk-in rules case(s) failed: " .. table.concat(fails, "; ")) end
print("SPEC OK: walkin rules")
