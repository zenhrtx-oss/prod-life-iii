-- CLI spec for Modules/CareerSim (the pure day-by-day career simulation the pacing checks run).
-- Fixture deck and economy only; the real content is checked by pacing_spec. Run: sh tools/spec.sh career_sim
local Sim = require("../src/ReplicatedStorage/OK/Modules/CareerSim")
local R = require("../src/ReplicatedStorage/OK/Modules/WalkInRules")
local CR = require("../src/ReplicatedStorage/OK/Modules/CareerRules")
local E = require("./economy_fixture")

local fails = {}
local function eq(name, got, want)
	if got ~= want then table.insert(fails, string.format("%s: expected %s, got %s", name, tostring(want), tostring(got))) end
end
local function ok(name, cond) if not cond then table.insert(fails, name) end end

-- ready = Config.WalkIns.Odds.ready (economy_fixture.READY), for the two-sessions ready-choice cases; beatCenter and
-- beatPer are this spec's own literals (Wave 3's starting values), so a retune of Config can't move these cases
local ODDS = { auraPer = 20, auraCap = 15, followersPer = 1000, followersCap = 10, min = 10, max = 90, ready = E.READY,
	beatCenter = 3, beatPer = 4 }
local GATES = { studio_two = { needs = { placements = 1, aura = 300 }, cost = 5000 },
	plate_legend = { needs = { hits = 1, followers = 20000, aura = 1000 }, cost = 4000, level = 10 } }

local function merge(base, over)
	for k, v in pairs(over or {}) do base[k] = v end
	return base
end
local function economy(over)
	return merge({
		requests = {
			{ cred = 400, xp = 25, level = 1, needs = {} },
			{ cred = 300, xp = 20, level = 1, needs = { "Bass" } },
			{ cred = 300, xp = 20, level = 1, needs = { "Rolls" } },
			{ cred = 250, xp = 20, level = 1, needs = { "Rolls", "Swing" } },
			{ cred = 500, xp = 40, level = 3, needs = {} },
		},
		daily = { cred = 200, xp = 15, count = 3 },
		weekly = { cred = 800, xp = 50 },
		cypherWinCred = 500, cypherXP = 40, tourXP = 50,
		streakBonus = { [3] = 300, [7] = 600 },
		fireCred = 30, firePerDay = 4,
		levels = { 0, 100, 250, 450, 700, 1000, 1400, 1900, 2500, 3200 },
		activityXP = 30, beatSaveXP = 20,
		gear = { { id = "808", price = 0, level = 1, feature = "Bass" }, { id = "rollfx", price = 250, level = 1, feature = "Rolls" },
			{ id = "swing", price = 350, level = 1, feature = "Swing" } },
		feeds = { delivery = { [2] = { aura = 5, followers = 40 }, [3] = { aura = 10, followers = 120 } },
			plaque = { aura = 40, followers = 300 }, cypher = { aura = 25 }, fire = { followers = 10 } },
		XP_PHONE = E.XP_PHONE, -- Config.XP.Sources.Phone: the XP gate the sim applies to card XP
		WALKINS = { RecentMax = 3 }, -- Config.WalkIns.RecentMax: the recent beats the sim keeps (Wave 3)
	}, over)
end
local function outcome(t)
	return merge({ key = "k", headline = "H", text = "t", line = "l", tone = "neutral" }, t)
end
local function card(id, visitor, choices, extra)
	return merge({ id = id, visitor = visitor, tag = "TAG", line = "yo", choices = choices }, extra)
end

-- the two-card fixture deck: a placement card that plants a single, and a hype card
local DECK = {
	cards = {
		card("fx_place", "fxa", {
			{ text = "shot", odds = 50, good = outcome({ placements = 1, aura = 40, money = 200, plant = { id = "fx_single" } }), bad = outcome({ aura = -20 }) },
			{ text = "paid", cost = 300, sure = true, good = outcome({ money = 450, aura = 10 }) },
		}),
		card("fx_hype", "fxb", {
			{ text = "post", odds = 60, good = outcome({ followers = 500, money = 100 }), bad = outcome({ followers = -100, money = -50 }) },
			{ text = "chill", sure = true, good = outcome({ aura = 5 }) },
		}),
	},
	followups = {
		fx_single = { id = "fx_single", visitor = "fxa", tag = "TAG", line = "it dropped",
			resolve = { odds = 50, good = outcome({ hits = 1, money = 1000, followers = 2000 }), bad = outcome({ money = -100 }) } },
	},
	sponsors = {},
}

local function input(over)
	return merge({ days = 30, economy = economy(), deck = DECK, rules = R, careerRules = CR, odds = ODDS, followupAt = { 2, 4 },
		dropAt = { 1, 1 }, cooldown = 1, walkinsPerDay = 8, phonePerDay = 0, phoneSeed = 42, auraHeal = 0, rng = Sim.Lcg(42),
		policy = "random", gates = GATES }, over)
end

-- a WalkInRules stand-in that logs picks (with the opts they got and the counters they saw), plants, takes off the
-- queue, news reads, resolves (with their roll) and the money the first roll of each visit sees
local function spy()
	local log = { events = {}, firstMoney = {}, resolves = {} }
	local fresh = false
	local S = setmetatable({}, { __index = R })
	function S.Pick(state, deck, opts)
		local p = R.Pick(state, deck, opts)
		local item = p and (p.kind == "card" and p.card or p.followup)
		local c = opts.career
		table.insert(log.events, { ev = "pick", count = state.count, today = state.today, sponsored = opts.sponsored, aura = opts.aura,
			kind = p and p.kind, id = p and (p.kind == "card" and p.card.id or p.entry.id), visitor = item and item.visitor,
			source = opts.source, day = opts.day, week = opts.week, aired = opts.aired, cooldown = opts.cooldown,
			career = c and { visits = c.visits, money = c.money, aura = c.aura, followers = c.followers, placements = c.placements,
				hits = c.hits, sponsors = c.sponsors },
			phoneCount = state.phone and state.phone.count })
		fresh = p ~= nil
		return p
	end
	local function first(c)
		if fresh then table.insert(log.firstMoney, c.money); fresh = false end
	end
	function S.ResolveNews(f, c, odds, rng)
		first(c)
		table.insert(log.events, { ev = "news", id = f.id })
		return R.ResolveNews(f, c, odds, rng)
	end
	function S.Resolve(choice, c, odds, rng, tilt, beatQ)
		first(c)
		local money = c.money
		local res = R.Resolve(choice, c, odds, rng, tilt, beatQ)
		table.insert(log.resolves, { choice = choice, money = money, roll = res.roll, level = c.level, chance = res.chance,
			tilt = tilt, beatQ = beatQ })
		return res
	end
	function S.TakeQueued(state, entry)
		table.insert(log.events, { ev = "take", id = entry.id })
		return R.TakeQueued(state, entry)
	end
	function S.Plant(state, plant, at, rng, ctx)
		local e = R.Plant(state, plant, at, rng, ctx)
		if e then table.insert(log.events, { ev = "plant", id = e.id, at = e.at, ctx = ctx, count = state.count, range = plant.at }) end
		return e
	end
	return S, log
end

local function sharesOk(name, res, days)
	eq(name .. " shares length", #res.shares, days)
	for d = 1, days do
		local s = res.shares[d]
		ok(name .. " share day " .. d .. " in [0,1]", type(s) == "number" and s >= 0 and s <= 1)
	end
	ok(name .. " steadyShare in [0,1]", type(res.steadyShare) == "number" and res.steadyShare >= 0 and res.steadyShare <= 1)
end

-- Lcg and Seeds
local r1, r2 = Sim.Lcg(5), Sim.Lcg(5)
for i = 1, 50 do
	local a, b = r1(1, 100), r2(1, 100)
	eq("Lcg same seed draw " .. i, a, b)
	ok("Lcg draw in range", a >= 1 and a <= 100 and a == math.floor(a))
end
eq("Lcg single value range", Sim.Lcg(9)(3, 3), 3)
eq("Seeds count", #Sim.Seeds, 20)
local seenSeed = {}
for _, s in ipairs(Sim.Seeds) do
	ok("Seed distinct " .. tostring(s), not seenSeed[s]); seenSeed[s] = true
end

-- base run: shares in [0,1], Studio Two within 30 days, gate days nil (not false) when never reached
local base = Sim.Run(input())
sharesOk("base", base, 30)
ok("base studioTwoDay within 30 days (got " .. tostring(base.studioTwoDay) .. ")", type(base.studioTwoDay) == "number" and base.studioTwoDay <= 30)
ok("base legendDay nil or a day", base.legendDay == nil or type(base.legendDay) == "number")
ok("base placements >= 1", type(base.placements) == "number" and base.placements >= 1)
ok("base hits is a number", type(base.hits) == "number")
ok("base walk-ins earned something", base.steadyShare > 0)

-- the same seed gives the same run
local x, y = Sim.Run(input({ rng = Sim.Lcg(7) })), Sim.Run(input({ rng = Sim.Lcg(7) }))
for _, k in ipairs({ "studioTwoDay", "legendDay", "steadyShare", "placements", "hits" }) do eq("same seed " .. k, x[k], y[k]) end
for d = 1, 30 do eq("same seed share day " .. d, x.shares[d], y.shares[d]) end

-- a request that needs Bass is delivered on day 1: the 808 is free. Gate cost = that 3-star pay, nothing else pays on day 1.
local function bassRun(price)
	return Sim.Run(input({ days = 3, walkinsPerDay = 0, deck = { cards = {}, followups = {}, sponsors = {} },
		economy = economy({ requests = { { cred = 400, xp = 25, level = 1, needs = { "Bass" } } }, daily = { cred = 200, xp = 15, count = 0 },
			firePerDay = 0, gear = { { id = "808", price = price, level = 1, feature = "Bass" } } }),
		gates = { studio_two = { needs = {}, cost = 600 } } }))
end
local bass = bassRun(0)
eq("Bass request delivered on day 1 (808 free)", bass.studioTwoDay, 1)
sharesOk("no-gain day 3 still has a share", bass, 3)
ok("control: a priced 808 delays the Bass request", bassRun(100).studioTwoDay ~= 1)

-- spendDown: the first roll of every visit sees $0; without it, money is there (control)
local S, log = spy()
local spent = Sim.Run(input({ rules = S, spendDown = true }))
sharesOk("spendDown", spent, 30)
ok("spendDown observed visits", #log.firstMoney > 20)
for i, m in ipairs(log.firstMoney) do eq("spendDown money before visit " .. i, m, 0) end
S, log = spy()
Sim.Run(input({ rules = S }))
local any = false
for _, m in ipairs(log.firstMoney) do if m > 0 then any = true end end
ok("control: without spendDown a visit sees money", any)

-- greedy: the higher expected money choice, listed second and never tied on cost-blind money
local A = { text = "A", cost = 300, odds = 50, good = outcome({ money = 600 }), bad = outcome({ money = 0 }) }
local B = { text = "B", odds = 50, good = outcome({ money = 300 }), bad = outcome({ money = 150 }) }
local greedyDeck = { cards = { card("fx_two", "fxg", { A, B }) }, followups = {}, sponsors = {} }
S, log = spy()
Sim.Run(input({ rules = S, deck = greedyDeck, cooldown = 0, policy = "greedy", days = 10 }))
ok("greedy resolved visits", #log.resolves > 20)
local affordableA = false
for i, rv in ipairs(log.resolves) do
	eq("greedy pick " .. i, rv.choice.text, "B")
	if rv.money >= A.cost then affordableA = true end
end
ok("greedy had A affordable", affordableA)
S, log = spy()
Sim.Run(input({ rules = S, deck = greedyDeck, cooldown = 0, policy = "random", days = 10 }))
local pickedA = false
for _, rv in ipairs(log.resolves) do if rv.choice.text == "A" then pickedA = true end end
ok("control: random picks A sometimes", pickedA)

-- greedy counts the money a choice leads to, not only its own: the rare outcome (rolled first) and, for an outcome that
-- plants a follow-up, that follow-up's news and its best affordable choice. One-card decks, cooldown 0, 10 days.
local function oneCard(choices, followups)
	return { cards = { card("fx_one", "fxo", choices) }, followups = followups or {}, sponsors = {} }
end
-- how often `policy` resolved choice a and choice b
local function picks(deck, a, b, policy)
	local s, l = spy()
	Sim.Run(input({ rules = s, deck = deck, cooldown = 0, policy = policy or "greedy", days = 10 }))
	local na, nb = 0, 0
	for _, rv in ipairs(l.resolves) do
		if rv.choice == a then na += 1 elseif rv.choice == b then nb += 1 end
	end
	return na, nb
end
local cash = { text = "cash", sure = true, good = outcome({ money = 100 }) }
-- the planted news: 50 % (tilted up by the beats' Aura) of `money`; worth at most 0.75 * 0.75 * 100 < $100 at $100
local function bigNews(money)
	return { fx_big = { id = "fx_big", visitor = "fxo", tag = "TAG", line = "news",
		resolve = { odds = 50, good = outcome({ money = money }), bad = outcome({}) } } }
end
local thread = { text = "thread", odds = 50, good = outcome({ plant = { id = "fx_big" } }), bad = outcome({}) }
local na, nb = picks(oneCard({ thread, cash }, bigNews(1000)), thread, cash)
ok(string.format("greedy values a planted follow-up's news (thread %d, cash %d)", na, nb), na > 0 and nb == 0)
na, nb = picks(oneCard({ thread, cash }, bigNews(100)), thread, cash)
ok(string.format("control: greedy takes the cash over small news (thread %d, cash %d)", na, nb), na == 0 and nb > 0)
-- the planted follow-up's best affordable choice: a sure $1,000 when it costs nothing, out of reach at a $1,000,000 cost
local function dealNews(cost)
	return { fx_deal = { id = "fx_deal", visitor = "fxo", tag = "TAG", line = "deal",
		resolve = { odds = 50, good = outcome({}), bad = outcome({}) },
		choices = { { text = "take", cost = cost, sure = true, good = outcome({ money = 1000 }) },
			{ text = "skip", sure = true, good = outcome({}) } } } }
end
local opener = { text = "opener", sure = true, good = outcome({ plant = { id = "fx_deal" } }) }
local cash300 = { text = "cash300", sure = true, good = outcome({ money = 300 }) }
na, nb = picks(oneCard({ opener, cash300 }, dealNews(nil)), opener, cash300)
ok(string.format("greedy values a planted follow-up's best choice (opener %d, cash300 %d)", na, nb), na > 0 and nb == 0)
na, nb = picks(oneCard({ opener, cash300 }, dealNews(1000000)), opener, cash300)
ok(string.format("control: an unaffordable follow-up choice is worth nothing (opener %d, cash300 %d)", na, nb), na == 0 and nb > 0)
-- the rare outcome: 10 % of $2,000 beats a sure $100; 2 % does not
local function longshot(rareOdds)
	return { text = "longshot", odds = 50, good = outcome({}), bad = outcome({}), rare = outcome({ money = 2000 }), rareOdds = rareOdds }
end
local rare10, rare2 = longshot(10), longshot(2)
na, nb = picks(oneCard({ rare10, cash }), rare10, cash)
ok(string.format("greedy values the rare outcome (longshot %d, cash %d)", na, nb), na > 0 and nb == 0)
na, nb = picks(oneCard({ rare2, cash }), rare2, cash)
ok(string.format("control: a 2%% rare loses to the sure cash (longshot %d, cash %d)", na, nb), na == 0 and nb > 0)

-- the career chaser: the first affordable choice whose good outcome gives a placement or plants a follow-up, else random
local place = { text = "place", odds = 50, good = outcome({ placements = 1 }), bad = outcome({}) }
na, nb = picks(oneCard({ cash, place }), place, cash, "chaser")
ok(string.format("chaser takes the placement (place %d, cash %d)", na, nb), na > 0 and nb == 0)
na, nb = picks(oneCard({ cash, thread }, bigNews(0)), thread, cash, "chaser")
ok(string.format("chaser takes the planted thread even when it pays nothing (thread %d, cash %d)", na, nb), na > 0 and nb == 0)
local chill = { text = "chill", sure = true, good = outcome({ aura = 5 }) }
local paidPlace = { text = "paid place", cost = 1000000, sure = true, good = outcome({ placements = 1 }) }
local s5, l5 = spy()
Sim.Run(input({ rules = s5, deck = oneCard({ cash, chill, paidPlace }), cooldown = 0, policy = "chaser", days = 10 }))
local chaserSeen = {}
for _, rv in ipairs(l5.resolves) do chaserSeen[rv.choice.text] = (chaserSeen[rv.choice.text] or 0) + 1 end
ok("chaser never takes an unaffordable placement", chaserSeen["paid place"] == nil)
ok("chaser picks at random without a career choice (cash and chill both taken)", (chaserSeen.cash or 0) > 0 and (chaserSeen.chill or 0) > 0)

-- a planted follow-up arrives at the first visit it is due
S, log = spy()
Sim.Run(input({ rules = S }))
local matched = 0
for i, e in ipairs(log.events) do
	if e.ev == "plant" and e.id == "fx_single" then
		for j = i + 1, #log.events do
			local p = log.events[j]
			if p.ev == "pick" and p.kind == "followup" and p.id == "fx_single" then
				eq("follow-up arrives when due", p.count + 1, e.at)
				matched += 1
				break
			elseif p.ev == "pick" and p.kind then
				ok("follow-up not due before " .. e.at .. " (count " .. p.count .. ")", p.count + 1 < e.at)
			end
		end
	end
end
ok("follow-ups planted and arrived", matched >= 1)

-- the sponsor fixture: fx_brand's rep (Aura floor `floor`, signing adds `signed` to the outcome), a plain card and the
-- drop. The fixture's beats give 40 Aura on day 1 before the first visit and the plain card +1 a visit (46 at most)
local function sponsorDeck(floor, signed)
	return {
		cards = {
			card("fx_rep", "fxr", {
				{ text = "sign", sure = true, good = outcome(merge({ sponsor = "fx_brand", sponsors = 1 }, signed)) },
				{ text = "pass", sure = true, good = outcome({}) },
			}, { sponsor = "fx_brand", when = "unsponsored" }),
			card("fx_any", "fxb", {
				{ text = "hm", sure = true, good = outcome({ aura = 1 }) },
				{ text = "eh", sure = true, good = outcome({}) },
			}),
		},
		followups = {
			sponsor_drop = { id = "sponsor_drop", visitor = "fxr", tag = "TAG", line = "we're done",
				resolve = { odds = 50, good = outcome({ sponsor = "drop", sponsors = -1 }), bad = outcome({ sponsor = "drop", sponsors = -1 }) } },
		},
		sponsors = { fx_brand = floor },
	}
end

-- a rep card only at or above its sponsor's Aura floor (ruling, Task 4b): the sim passes the current Aura to Pick
local function dayOne(floor)
	local s1, log1 = spy()
	Sim.Run(input({ rules = s1, deck = sponsorDeck(floor, { money = 300 }), cooldown = 0, policy = "greedy", days = 1 }))
	local signed = false
	for _, rv in ipairs(log1.resolves) do if rv.choice.good.sponsor then signed = true end end
	return signed, log1
end
ok("no sponsor signed on day 1 under a floor (200) above day 1's Aura", not dayOne(200))
local signedLow, logLow = dayOne(20)
ok("control: a floor (20) under day 1's Aura signs on day 1", signedLow)
for i, e in ipairs(logLow.events) do
	if e.ev == "pick" then
		ok("pick " .. i .. " gets the current Aura (got " .. tostring(e.aura) .. ")", type(e.aura) == "number" and e.aura >= 40)
		if e.id == "fx_rep" then ok("pick " .. i .. " serves the rep at or above its floor", type(e.aura) == "number" and e.aura >= 20) end
	end
end

-- a sponsor signed then dropped clears the current sponsor (signing knocks Aura far under the floor, so the next
-- visit plants the drop)
S, log = spy()
local sp = Sim.Run(input({ rules = S, deck = sponsorDeck(20, { aura = -1000 }), cooldown = 0, policy = "greedy", days = 3 }))
sharesOk("sponsor", sp, 3)
local signedSeen, plantedDrop, dropIndex = false, false, nil
for i, e in ipairs(log.events) do
	if e.ev == "pick" and e.sponsored then signedSeen = true end
	if e.ev == "plant" and e.id == "sponsor_drop" then plantedDrop = e.ctx and e.ctx.sponsor == "fx_brand" end
	if e.ev == "pick" and e.kind == "followup" and e.id == "sponsor_drop" and not dropIndex then dropIndex = i end
end
ok("sponsor signed (a pick saw sponsored)", signedSeen)
ok("sponsor_drop planted with ctx.sponsor", plantedDrop)
ok("sponsor_drop arrived", dropIndex ~= nil)
local after
for j = (dropIndex or #log.events) + 1, #log.events do
	if log.events[j].ev == "pick" then after = log.events[j]; break end
end
eq("sponsor cleared after the drop", after and after.sponsored, false)

-- a drop whose Aura has recovered by its visit is skipped (the server re-checks in nextPick and onArrive): visit 1 is
-- the rep (fx_boost waits for minCount 2), whose signing knocks Aura to about -960, under the floor (20); visit 2 is
-- fx_boost, which plants the drop on arrival and then adds `boost` Aura; visit 3 is the drop's visit
local function recoveryRun(boost)
	local deck = sponsorDeck(20, { aura = -1000 })
	deck.cards[2] = card("fx_boost", "fxb", {
		{ text = "boost", sure = true, good = outcome({ aura = boost }) },
		{ text = "eh", sure = true, good = outcome({}) },
	}, { minCount = 2 })
	local s, l = spy()
	Sim.Run(input({ rules = s, deck = deck, cooldown = 0, policy = "greedy", days = 1 }))
	local planted, dueAt, picked = false, nil, {}
	for _, e in ipairs(l.events) do
		if e.ev == "plant" and e.id == "sponsor_drop" then planted = e.ctx and e.ctx.sponsor == "fx_brand"; dueAt = e.at end
		if e.ev == "pick" then table.insert(picked, e) end
	end
	return planted, dueAt, picked
end
local plantedR, dueR, pickedR = recoveryRun(2000)
ok("recovery: the drop was planted for fx_brand", plantedR)
eq("recovery: the drop is due on visit 3", dueR, 3)
local dropPicks, visitThree = 0, nil
for _, e in ipairs(pickedR) do
	if e.id == "sponsor_drop" then dropPicks += 1 end
	if e.count == 2 then visitThree = e end -- the last pick before visit 3 is the one that visit used
end
eq("recovery: Pick offered the drop once", dropPicks, 1)
eq("recovery: visit 3 is a card instead of the drop", visitThree and visitThree.kind, "card")
for _, e in ipairs(pickedR) do
	if e.count >= 2 then eq("recovery: still sponsored at count " .. e.count, e.sponsored, true) end
end
-- control: no recovery (boost 0), so visit 3 is the drop and the deal ends
local _, dueC, pickedC = recoveryRun(0)
eq("control: the drop is due on visit 3", dueC, 3)
local visitThreeC, afterC
for _, e in ipairs(pickedC) do
	if e.count == 2 then visitThreeC = e end
	if e.count == 3 and not afterC then afterC = e end
end
eq("control: visit 3 is the drop", visitThreeC and visitThreeC.id, "sponsor_drop")
eq("control: the deal ends at the drop", afterC and afterC.sponsored, false)

-- Wave 1a: the phone and the new rules (Shared shapes "Phone rules") -----------------------------------------------------

local function deckOf(cards, followups, visitors)
	return { cards = cards, followups = followups or {}, sponsors = {}, visitors = visitors }
end
-- a walk-in card with two free sure choices that change nothing
local function plain(id, visitor, extra)
	return card(id, visitor, { { text = "a", sure = true, good = outcome({}) }, { text = "b", sure = true, good = outcome({}) } }, extra)
end
local function phoneCard(id, visitor, choices, extra)
	return card(id, visitor, choices, merge({ source = "phone", app = "MESSAGES" }, extra))
end
-- a phone NEWS card: its one sure choice
local function newsCard(id, visitor, good)
	return card(id, visitor, { { text = "read", sure = true, good = good } }, { source = "phone", app = "NEWS", news = true })
end
-- a phone follow-up whose news is `good` or `bad` at 50 %
local function phoneFollowup(id, visitor, good, bad)
	return { id = id, visitor = visitor, source = "phone", tag = "TAG", line = "news", resolve = { odds = 50, good = good, bad = bad or good } }
end
local function isNum(x) return type(x) == "number" end
-- the day a walk-in pick at `count` falls on, with 8 visits a day (its cap week is that day // 7, Shared shapes)
local function walkDay(count) return count // 8 + 1 end

-- Run requires phonePerDay, and phoneSeed whenever phonePerDay > 0 (no silent default)
local function without(key, over)
	local inp = input(over)
	inp[key] = nil
	return inp
end
local ranNoPerDay, errNoPerDay = pcall(Sim.Run, without("phonePerDay"))
ok("Run errors without phonePerDay (got " .. tostring(errNoPerDay) .. ")",
	not ranNoPerDay and string.find(tostring(errNoPerDay), "phonePerDay", 1, true) ~= nil)
local ranNoSeed, errNoSeed = pcall(Sim.Run, without("phoneSeed", { phonePerDay = 6 }))
ok("Run errors without phoneSeed when phonePerDay > 0 (got " .. tostring(errNoSeed) .. ")",
	not ranNoSeed and string.find(tostring(errNoSeed), "phoneSeed", 1, true) ~= nil)
ok("control: phoneSeed may be absent when phonePerDay is 0", (pcall(Sim.Run, without("phoneSeed", { days = 2 }))))

-- phone pops never add to walkGained: a DM with a paid choice whose outcomes carry money (content never does; the sim
-- must not count it either way). Control: the same card as a walk-in does add to the share
local function moneyDM(source)
	return card("fx_dm", "fxp", {
		{ text = "pay", cost = 100, sure = true, good = outcome({ money = 500, aura = 1 }) },
		{ text = "free", sure = true, good = outcome({ money = 300 }) },
	}, source == "phone" and { source = "phone", app = "MESSAGES" } or nil)
end
local phoneOnly = Sim.Run(input({ deck = deckOf({ moneyDM("phone") }), walkinsPerDay = 0, phonePerDay = 6, cooldown = 0, days = 10 }))
ok("money DM: pops opened (got " .. tostring(phoneOnly.phonePops) .. ")", isNum(phoneOnly.phonePops) and phoneOnly.phonePops > 0)
for d = 1, 10 do eq("phone pops never add to walkGained: share day " .. d, phoneOnly.shares[d], 0) end
eq("phone pops never add to walkGained: steadyShare", phoneOnly.steadyShare, 0)
ok("control: the same card as a walk-in adds to the share",
	Sim.Run(input({ deck = deckOf({ moneyDM("walkin") }), walkinsPerDay = 6, cooldown = 0, days = 10 })).steadyShare > 0)

-- phone outcome money is never applied: on day 1 with no walk-ins, each pop's money is the last one's minus the cost it
-- paid, never plus its outcome's money
local S6, log6 = spy()
local moneyRun = Sim.Run(input({ rules = S6, deck = deckOf({ moneyDM("phone") }), walkinsPerDay = 0, phonePerDay = 6, cooldown = 0, days = 1 }))
eq("money DM: six pops on day 1", moneyRun.phonePops, 6)
eq("money DM: six resolves on day 1", #log6.resolves, 6)
local paidOnce, moneyBad = false, nil
for i = 1, #log6.resolves - 1 do
	local r, nextMoney = log6.resolves[i], log6.resolves[i + 1].money
	if (r.choice.cost or 0) > 0 then paidOnce = true end
	if nextMoney ~= r.money - (r.choice.cost or 0) and not moneyBad then
		moneyBad = string.format("pop %d: $%d, then $%d after %s", i, r.money, nextMoney, r.choice.text)
	end
end
ok("phone outcome money is never applied, only the cost moves money (" .. tostring(moneyBad) .. ")", moneyBad == nil)
ok("money DM: the paid choice was taken", paidOnce)

-- phone pops don't advance walkins.count or today: two walk-in cards, a DM and a NEWS card, 8 visits and 6 pops a day
local countDeck = deckOf({ plain("fx_w1", "fxa"), plain("fx_w2", "fxb"),
	phoneCard("fx_dm", "fxp", { { text = "ok", sure = true, good = outcome({}) } }), newsCard("fx_news", "fxn", outcome({})) })
local S7, log7 = spy()
local countRun = Sim.Run(input({ rules = S7, deck = countDeck, walkinsPerDay = 8, phonePerDay = 6, cooldown = 1, days = 3 }))
eq("count run: phonePops", countRun.phonePops, 18)
local walkPicks, phonePicks, countBad = 0, 0, nil
for _, e in ipairs(log7.events) do
	if e.ev == "pick" and e.source == "phone" then
		phonePicks += 1
		local want = 8 * ((phonePicks - 1) // 6 + 1)
		if (e.count ~= want or e.today ~= 8 or e.phoneCount ~= phonePicks - 1) and not countBad then
			countBad = string.format("phone pick %d: count %s (want %d), today %s (want 8), phone.count %s (want %d)", phonePicks,
				tostring(e.count), want, tostring(e.today), tostring(e.phoneCount), phonePicks - 1)
		end
	elseif e.ev == "pick" then
		walkPicks += 1
		if e.count ~= walkPicks - 1 and not countBad then
			countBad = string.format("walk-in pick %d: count %s (want %d)", walkPicks, tostring(e.count), walkPicks - 1)
		end
	end
end
eq("count run: walk-in picks", walkPicks, 24)
eq("count run: phone picks", phonePicks, 18)
ok("phone pops don't advance walkins.count or today (" .. tostring(countBad) .. ")", countBad == nil)

-- pickNext passes career (with visits = the walk-in count), day, week (day // 7), source, aired (FIRE that day) and the
-- cooldown, for both sources. 15 days crosses weeks 0, 1 and 2. Control: no FIRE a day, nothing aired
local S8, log8 = spy()
Sim.Run(input({ rules = S8, deck = countDeck, walkinsPerDay = 8, phonePerDay = 6, cooldown = 1, days = 15 }))
local sources, weeks, optsBad = {}, {}, nil
for i, e in ipairs(log8.events) do
	if e.ev == "pick" then
		local c, why = e.career, nil
		local wantDay = e.source == "phone" and e.count // 8 or walkDay(e.count)
		if not c then
			why = "no career"
		elseif c.visits ~= e.count or c.aura ~= e.aura then
			why = string.format("career.visits %s / aura %s (want %d / %s)", tostring(c.visits), tostring(c.aura), e.count, tostring(e.aura))
		elseif not (isNum(c.money) and isNum(c.followers) and isNum(c.placements) and isNum(c.hits) and isNum(c.sponsors)) then
			why = "career stats missing"
		elseif e.source ~= "walkin" and e.source ~= "phone" then
			why = "source " .. tostring(e.source)
		elseif e.day ~= wantDay or not isNum(e.day) or e.week ~= e.day // 7 then
			why = string.format("day %s / week %s (want day %d)", tostring(e.day), tostring(e.week), wantDay)
		elseif e.aired ~= true then
			why = "aired " .. tostring(e.aired)
		elseif e.cooldown ~= 1 then
			why = "cooldown " .. tostring(e.cooldown)
		end
		if why and not optsBad then optsBad = "pick " .. i .. ": " .. why end
		sources[tostring(e.source)] = true
		if isNum(e.week) then weeks[e.week] = true end
	end
end
ok("pickNext passes career, visits, day, week, source, aired, cooldown (" .. tostring(optsBad) .. ")", optsBad == nil)
ok("pickNext: both sources picked", sources.walkin and sources.phone)
ok("pickNext: weeks 0, 1 and 2 seen", weeks[0] and weeks[1] and weeks[2])
S8, log8 = spy()
Sim.Run(input({ rules = S8, deck = countDeck, economy = economy({ firePerDay = 0 }), walkinsPerDay = 8, phonePerDay = 6, days = 2 }))
local airedNone = true
for _, e in ipairs(log8.events) do if e.ev == "pick" and e.aired ~= false then airedNone = false end end
ok("control: no FIRE a day passes aired = false", airedNone)

-- phoneAura is the net Aura phone pops applied: a NEWS card (+20) and a DM whose only choice is sure (-10), two pops on
-- one day (least-seen draws each once); the beats' Aura that day doesn't count
local auraDeck = deckOf({ newsCard("fx_news", "fxn", outcome({ aura = 20 })),
	phoneCard("fx_dm", "fxd", { { text = "ok", sure = true, good = outcome({ aura = -10 }) } }) })
local auraRun = Sim.Run(input({ deck = auraDeck, walkinsPerDay = 0, phonePerDay = 2, days = 1 }))
eq("phoneAura run: two pops", auraRun.phonePops, 2)
eq("phoneAura is the net Aura phone pops applied (+20 - 10)", auraRun.phoneAura, 10)

-- the first card arrives on visit 1 of day 1, on every seed (the only `first` card: its draw has one way to land), and
-- never again (under visits 1)
local firstDeck = deckOf({ plain("fx_a", "fxa"), plain("fx_b", "fxb"), plain("fx_first", "fxf", { first = true, under = { visits = 1 } }) })
for _, seed in ipairs({ 1, 7, 42, 99, 123 }) do
	local s, l = spy()
	Sim.Run(input({ rules = s, deck = firstDeck, rng = Sim.Lcg(seed), days = 2 }))
	local firstPick, again = nil, 0
	for _, e in ipairs(l.events) do
		if e.ev == "pick" then
			firstPick = firstPick or e
			if e.id == "fx_first" and e ~= firstPick then again += 1 end
		end
	end
	ok("seed " .. seed .. ": first card arrives on visit 1 of day 1 (got " .. tostring(firstPick and firstPick.id) .. ")",
		firstPick ~= nil and firstPick.count == 0 and firstPick.id == "fx_first")
	eq("seed " .. seed .. ": the first card comes once", again, 0)
end
-- the starter pool (Task 5b+): with two `first` cards the first visit draws one of them on the sim's rng, each comes
-- first on some of 40 seeds, and neither comes again in the run (under visits 1)
local poolDeck = deckOf({ plain("fx_a", "fxa"), plain("fx_b", "fxb"), plain("fx_s1", "fxs1", { first = true, under = { visits = 1 } }),
	plain("fx_s2", "fxs2", { first = true, under = { visits = 1 } }) })
local firstDrawn = {}
for seed = 1, 40 do
	local s, l = spy()
	Sim.Run(input({ rules = s, deck = poolDeck, rng = Sim.Lcg(seed), days = 2 }))
	local firstPick, again = nil, 0
	for _, e in ipairs(l.events) do
		if e.ev == "pick" then
			if not firstPick then firstPick = e
			elseif e.id == "fx_s1" or e.id == "fx_s2" then again += 1 end
		end
	end
	ok("pool seed " .. seed .. ": the first visit is a starter (got " .. tostring(firstPick and firstPick.id) .. ")",
		firstPick ~= nil and firstPick.count == 0 and (firstPick.id == "fx_s1" or firstPick.id == "fx_s2"))
	eq("pool seed " .. seed .. ": no starter after the first visit", again, 0)
	if firstPick then firstDrawn[firstPick.id] = true end
end
ok("pool: each starter comes first on some seed", firstDrawn.fx_s1 == true and firstDrawn.fx_s2 == true)

-- mom's cap holds over 14 days: at most 2 a sim week (day // 7, from the visit count), and she does come. Control:
-- uncapped, she comes more than twice in some week
local function momWeeks(cap)
	local s, l = spy()
	Sim.Run(input({ rules = s, deck = deckOf({ plain("fx_a", "fxa"), plain("fx_b", "fxb"), plain("fx_mom", "fxm", cap and { cap = cap }) }),
		days = 14 }))
	local perWeek, total = {}, 0
	for _, e in ipairs(l.events) do
		if e.ev == "pick" and e.id == "fx_mom" then
			local w = walkDay(e.count) // 7
			perWeek[w] = (perWeek[w] or 0) + 1
			total += 1
		end
	end
	return perWeek, total
end
local momPer, momTotal = momWeeks({ group = "mom", per = "week", max = 2 })
ok("mom cap: she comes (" .. momTotal .. " visits)", momTotal > 0)
for w = 0, 2 do ok("mom cap holds over 14 days: week " .. w .. " has " .. tostring(momPer[w]) .. " <= 2", (momPer[w] or 0) <= 2) end
local momOver = false
for _, n in pairs((momWeeks(nil))) do if n > 2 then momOver = true end end
ok("control: uncapped mom comes more than twice a week", momOver)

-- a seeded new card doesn't arrive twice in a row: fx_late opens at visit 11 (needs visits 10) when the other three are
-- at seen 3 or 4; Seed joins it at 3, so it comes exactly once in visits 11..13. Control: without Seed it is the only
-- seen-0 card and wins visits 11 and 12
local function lateRun(seed, noSeed)
	local s, l = spy()
	if noSeed then s.Seed = function() return 0 end end
	Sim.Run(input({ rules = s, rng = Sim.Lcg(seed), cooldown = 0, days = 2,
		deck = deckOf({ plain("fx_a", "fxa"), plain("fx_b", "fxb"), plain("fx_c", "fxc"), plain("fx_late", "fxl", { needs = { visits = 10 } }) }) }))
	local at = {}
	for _, e in ipairs(l.events) do if e.ev == "pick" then at[e.count] = e.id end end
	return at
end
for _, seed in ipairs({ 1, 7, 42, 99, 123 }) do
	local at, early, window = lateRun(seed), false, 0
	for c = 0, 9 do if at[c] == "fx_late" then early = true end end
	for c = 10, 12 do if at[c] == "fx_late" then window += 1 end end
	ok("seed " .. seed .. ": the gated card waits for visit 11", not early)
	eq("seed " .. seed .. ": seeded new card doesn't arrive twice in a row (visits 11..13)", window, 1)
	local raw = lateRun(seed, true)
	ok("seed " .. seed .. " control: without Seed it wins visits 11 and 12", raw[10] == "fx_late" and raw[11] == "fx_late")
end

-- NEWS resolves its one sure choice, with no policy draw: a NEWS card given a second, richer choice still resolves the
-- first, sure, under random and greedy
local newsTwo = card("fx_news", "fxn", {
	{ text = "read", sure = true, good = outcome({ aura = 1 }) },
	{ text = "cash", sure = true, good = outcome({ money = 1000 }) },
}, { source = "phone", app = "NEWS", news = true })
for _, policy in ipairs({ "random", "greedy" }) do
	local s, l = spy()
	local res = Sim.Run(input({ rules = s, deck = deckOf({ newsTwo }), walkinsPerDay = 0, phonePerDay = 6, cooldown = 0, days = 3, policy = policy }))
	eq(policy .. ": NEWS pops", res.phonePops, 18)
	eq(policy .. ": NEWS resolves", #l.resolves, 18)
	local bad
	for i, r in ipairs(l.resolves) do
		if (r.choice ~= newsTwo.choices[1] or r.roll ~= "sure") and not bad then bad = i .. ": " .. r.choice.text .. " " .. tostring(r.roll) end
	end
	ok(policy .. ": NEWS resolves sure, with no policy draw (" .. tostring(bad) .. ")", bad == nil)
end

-- phone draws never touch the main stream: a phone-only deck (a DM with a random-policy pick, a rolled choice that plants
-- a phone follow-up, and a NEWS card), no walk-ins, input.rng counting its calls. Control: walk-ins do draw from it
local function counting(seed)
	local inner, n = Sim.Lcg(seed), 0
	return function(lo, hi) n += 1; return inner(lo, hi) end, function() return n end
end
local clipThen = { aura = 5, plant = { id = "fx_clip", at = { 0, 0 } } }
local streamDeck = deckOf({
	phoneCard("fx_dm", "fxd", {
		{ text = "risk", odds = 50, good = outcome(clipThen), bad = outcome({ aura = -5, plant = { id = "fx_clip", at = { 0, 0 } } }) },
		{ text = "pass", sure = true, good = outcome({}) },
	}),
	newsCard("fx_news", "fxn", outcome({ aura = 2 })),
}, { fx_clip = phoneFollowup("fx_clip", "fxd", outcome({ followers = 100 }), outcome({})) })
local mainRng, mainCalls = counting(42)
local S9, log9 = spy()
local streamRun = Sim.Run(input({ rules = S9, deck = streamDeck, rng = mainRng, walkinsPerDay = 0, phonePerDay = 6, cooldown = 0, days = 5 }))
ok("stream run: pops opened (got " .. tostring(streamRun.phonePops) .. ")", isNum(streamRun.phonePops) and streamRun.phonePops > 0)
eq("phone draws never touch the main stream (input.rng calls)", mainCalls(), 0)
local rolled, passed, clipRead = false, false, false
for _, r in ipairs(log9.resolves) do
	if r.roll == "good" or r.roll == "bad" then rolled = true end
	if r.choice.text == "pass" then passed = true end
end
for _, e in ipairs(log9.events) do if e.ev == "news" and e.id == "fx_clip" then clipRead = true end end
ok("stream run: the policy took both choices, one rolled", rolled and passed)
ok("stream run: the planted phone follow-up was read", clipRead)
local walkRng, walkCalls = counting(42)
Sim.Run(input({ rng = walkRng, days = 2 }))
ok("control: walk-ins draw from input.rng", walkCalls() > 0)

-- an artist's DM blocks his walk-in for cooldown visits (MarkSent at the send): no walk-in pick of fxa within 3 visits
-- of his DM. Control: the same sender as a fan (not an artist) does walk in inside that window. Five walk-in cards, so
-- fxa's place in the rotation moves each day (8 visits) and his DM is eligible on some days
local function artistRun(kind)
	local s, l = spy()
	Sim.Run(input({ rules = s, cooldown = 3, walkinsPerDay = 8, phonePerDay = 6, days = 20,
		deck = deckOf({ plain("fx_a", "fxa"), plain("fx_b", "fxb"), plain("fx_c", "fxc"), plain("fx_d", "fxd"), plain("fx_e", "fxe"),
			phoneCard("fx_dm", "fxa", { { text = "ok", sure = true, good = outcome({}) } }) }, nil,
			{ fxa = { id = "fxa", kind = kind }, fxb = { id = "fxb", kind = "fan" }, fxc = { id = "fxc", kind = "fan" },
				fxd = { id = "fxd", kind = "fan" }, fxe = { id = "fxe", kind = "fan" } }) }))
	local dmAt, dms, inside = nil, 0, 0
	for _, e in ipairs(l.events) do
		if e.ev == "pick" and e.id == "fx_dm" then
			dmAt, dms = e.count, dms + 1
		elseif e.ev == "pick" and e.source ~= "phone" and e.visitor == "fxa" and dmAt and e.count - dmAt < 3 then
			inside += 1
		end
	end
	return dms, inside
end
local artistDms, artistInside = artistRun("artist")
ok("artist DMs sent (" .. artistDms .. ")", artistDms > 0)
eq("an artist DM blocks his walk-in for cooldown visits", artistInside, 0)
local fanDms, fanInside = artistRun("fan")
ok("control: a fan's DM doesn't block his walk-in (" .. fanDms .. " DMs, " .. fanInside .. " walk-ins inside)", fanDms > 0 and fanInside > 0)

-- a phone follow-up applies once: every DM plants fx_clip (due at once) and every clip is taken off the queue before its
-- news is read, once per plant. A pick whose TakeQueued returns nil (already taken) applies and counts nothing
local onceDeck = deckOf({ phoneCard("fx_dm", "fxd", { { text = "ok", sure = true, good = outcome({ plant = { id = "fx_clip", at = { 0, 0 } } }) } }) },
	{ fx_clip = phoneFollowup("fx_clip", "fxd", outcome({ aura = 7 })) })
local S10, log10 = spy()
local onceRun = Sim.Run(input({ rules = S10, deck = onceDeck, walkinsPerDay = 0, phonePerDay = 6, cooldown = 0, days = 2 }))
local clipPlants, clipReads, takenFirst = 0, 0, true
for i, e in ipairs(log10.events) do
	if e.ev == "plant" and e.id == "fx_clip" then clipPlants += 1 end
	if e.ev == "news" and e.id == "fx_clip" then
		clipReads += 1
		local prev = log10.events[i - 1]
		if not (prev and prev.ev == "take" and prev.id == "fx_clip") then takenFirst = false end
	end
end
eq("follow-up run: six clips planted", clipPlants, 6)
eq("a phone follow-up applies once: one read per plant", clipReads, clipPlants)
ok("a phone follow-up applies once: TakeQueued comes first", takenFirst)
eq("follow-up run: pops = 6 DMs + 6 clips", onceRun.phonePops, 12)
eq("follow-up run: phoneAura = 7 a clip", onceRun.phoneAura, 7 * clipReads)
local S11, log11 = spy()
S11.TakeQueued = function(_, entry)
	table.insert(log11.events, { ev = "take", id = entry.id })
	return nil
end
local droppedRun = Sim.Run(input({ rules = S11, deck = onceDeck, walkinsPerDay = 0, phonePerDay = 6, cooldown = 0, days = 2 }))
local droppedTakes, droppedReads = 0, 0
for _, e in ipairs(log11.events) do
	if e.ev == "take" then droppedTakes += 1 end
	if e.ev == "news" then droppedReads += 1 end
end
ok("dropped run: TakeQueued was asked (" .. droppedTakes .. ")", droppedTakes > 0)
eq("a pick whose TakeQueued returns nil applies nothing: no news", droppedReads, 0)
eq("a pick whose TakeQueued returns nil applies nothing: phoneAura", droppedRun.phoneAura, 0)
eq("a pick whose TakeQueued returns nil counts nothing: only the DM opened", droppedRun.phonePops, 1)

-- system plant: the first HIT plants mom_plaque once per run, at {1, 2}, on the visit the HIT lands, when the deck has
-- that follow-up; later HITs (after she has come) plant nothing. Control: a deck without it plants nothing
local function plaqueRun(withPlaque)
	local s, l = spy()
	local res = Sim.Run(input({ rules = s, days = 5, deck = deckOf({
		card("fx_hit", "fxh", { { text = "drop", sure = true, good = outcome({ hits = 1 }) }, { text = "drop too", sure = true, good = outcome({ hits = 1 }) } }),
		plain("fx_other", "fxo"),
	}, withPlaque and { mom_plaque = { id = "mom_plaque", visitor = "fxm", tag = "TAG", line = "so proud",
		resolve = { odds = 50, good = outcome({ aura = 1 }), bad = outcome({}) } } } or nil) }))
	return res, l
end
local plaqueRes, plaqueLog = plaqueRun(true)
local plaquePlants, firstHitVisit, plaqueEv, plaqueVisit, hitsAfter = 0, nil, nil, nil, 0
for _, e in ipairs(plaqueLog.events) do
	if e.ev == "pick" and e.id == "fx_hit" then
		firstHitVisit = firstHitVisit or e.count + 1
		if plaqueVisit then hitsAfter += 1 end
	end
	if e.ev == "plant" and e.id == "mom_plaque" then plaquePlants += 1; plaqueEv = plaqueEv or e end
	if e.ev == "pick" and e.id == "mom_plaque" then plaqueVisit = plaqueVisit or e.count + 1 end
end
eq("system plant: the first HIT plants mom_plaque once per run", plaquePlants, 1)
eq("system plant: on the first HIT's visit", plaqueEv and plaqueEv.count, firstHitVisit)
ok("system plant: at {1, 2}", plaqueEv ~= nil and plaqueEv.range ~= nil and plaqueEv.range[1] == 1 and plaqueEv.range[2] == 2)
ok("system plant: mom_plaque came, then more HITs (" .. hitsAfter .. ")", plaqueVisit ~= nil and hitsAfter > 0)
ok("system plant: hits >= 2", plaqueRes.hits >= 2)
local _, noPlaqueLog = plaqueRun(false)
local strayPlant = false
for _, e in ipairs(noPlaqueLog.events) do if e.ev == "plant" and e.id == "mom_plaque" then strayPlant = true end end
ok("control: no mom_plaque in the deck, no plant", not strayPlant)

-- Wave 1b: the daily Aura heal (Config.Career.Sources.AuraHeal) -------------------------------------------------------

-- Run requires auraHeal (0 = no heal), like phonePerDay
local ranNoHeal, errNoHeal = pcall(Sim.Run, without("auraHeal"))
ok("Run errors without auraHeal (got " .. tostring(errNoHeal) .. ")",
	not ranNoHeal and string.find(tostring(errNoHeal), "auraHeal", 1, true) ~= nil)

-- heal: a day starts by moving negative aura at most auraHeal toward 0. The career starts at `start` Aura (a CareerRules
-- stand-in's Defaults), the beats feed no Aura unless `feeds` says so, and one plain visit a day changes nothing, so
-- each day's one pick sees the Aura that day's first step left. Returns { [day] = that Aura }
local NO_FEEDS = { delivery = { [2] = {}, [3] = {} }, plaque = {}, cypher = {}, fire = {} }
local function healRun(start, heal, days, feeds)
	local startAt = setmetatable({ Defaults = function()
		local d = CR.Defaults()
		d.aura = start
		return d
	end }, { __index = CR })
	local s, l = spy()
	Sim.Run(input({ rules = s, careerRules = startAt, auraHeal = heal, days = days, walkinsPerDay = 1, cooldown = 0,
		economy = economy({ feeds = feeds or NO_FEEDS }), deck = deckOf({ plain("fx_a", "fxa"), plain("fx_b", "fxb") }) }))
	local auraOn = {}
	for _, e in ipairs(l.events) do if e.ev == "pick" then auraOn[e.day] = e.aura end end
	return auraOn
end
local HEAL = "heal: a day starts by moving negative aura at most auraHeal toward 0"
eq(HEAL .. ": -3 to 0", healRun(-3, 5, 1)[1], 0)
local healed = healRun(-12, 5, 3)
eq(HEAL .. ": -12 to -7 on day 1", healed[1], -7)
eq(HEAL .. ": then -2 on day 2", healed[2], -2)
eq(HEAL .. ": then 0 on day 3, never above", healed[3], 0)
eq(HEAL .. ": 40 unchanged", healRun(40, 5, 1)[1], 40)
eq("control: auraHeal 0 leaves -3", healRun(-3, 0, 1)[1], -3)
-- before the day's beats: from -12, day 1 heals to -7; day 2 heals to -2 and then its cypher win adds 25 (23). A heal
-- after the beats would find 18 and heal nothing
eq(HEAL .. ": first, before the day's beats (day 2: -7, -2, then the cypher's +25)",
	healRun(-12, 5, 2, merge(table.clone(NO_FEEDS), { cypher = { aura = 25 } }))[2], 23)

-- Two sessions: card XP, the level in the career Resolve sees, input.prefer, greedy on a ready choice ----------------

-- an economy whose beats pay no XP (no requests, dailies, activity, beat saves, tour or cypher XP), so card XP is the
-- only XP; levels as given
local function noXP(levels, over)
	return economy(merge({ requests = {}, daily = { cred = 200, xp = 15, count = 0 }, activityXP = 0, beatSaveXP = 0, tourXP = 0,
		cypherXP = 0, levels = levels }, over))
end
-- card XP raises sim.xp by the outcome's xp and the level at once, within the same day: a DM whose one sure choice pays
-- 40 XP, three pops on day 1 and no walk-ins. Levels 0 / 40 / 80 / 81: each pop's Resolve sees the level the pops
-- before it reached (1, 2, 3), and 81 is out of reach, so each pop added exactly 40. cardXP sums it (120). Control: a
-- deck without xp stays at level 1 and cardXP 0
local xpDM = phoneCard("fx_xp", "fxx", { { text = "take", sure = true, good = outcome({ xp = 40 }) } })
local SX, logX = spy()
local xpRun = Sim.Run(input({ rules = SX, deck = deckOf({ xpDM }), economy = noXP({ 0, 40, 80, 81 }), walkinsPerDay = 0, phonePerDay = 3,
	cooldown = 0, days = 1 }))
eq("card XP: three pops", xpRun.phonePops, 3)
eq("card XP: three resolves", #logX.resolves, 3)
for i, want in ipairs({ 1, 2, 3 }) do
	eq("card XP raises the level at once, within the same day: pop " .. i .. " resolves at level", logX.resolves[i] and logX.resolves[i].level, want)
end
eq("cardXP sums the card XP paid", xpRun.cardXP, 120)
local noXpDM = phoneCard("fx_xp", "fxx", { { text = "take", sure = true, good = outcome({}) } })
local SX0, logX0 = spy()
local noXpRun = Sim.Run(input({ rules = SX0, deck = deckOf({ noXpDM }), economy = noXP({ 0, 40, 80, 81 }), walkinsPerDay = 0,
	phonePerDay = 3, cooldown = 0, days = 1 }))
eq("control: no card XP, cardXP 0", noXpRun.cardXP, 0)
eq("control: no card XP, the third pop still resolves at level 1", logX0.resolves[3] and logX0.resolves[3].level, 1)

-- the sim applies the XP gate (economy.XP_PHONE, DataService's gate for source "Phone"): each card XP award is trimmed to
-- max (60), and a sim day pays at most dailyMax (3) awards; a 4th pays 0. An award trimmed to 0 isn't counted. A DM whose
-- one sure choice pays xp 70, levels out of reach: one pop pays 60; four pops on day 1 pay 60, 60, 60, 0 (180); the
-- count starts again on day 2 (360 over two days)
local xp70DM = phoneCard("fx_xp70", "fxx", { { text = "take", sure = true, good = outcome({ xp = 70 }) } })
local HIGH = { 0, 1e9, 1e9, 1e9, 1e9, 1e9, 1e9, 1e9, 1e9, 1e9 }
local function gateRun(perDay, days)
	return Sim.Run(input({ deck = deckOf({ xp70DM }), economy = noXP(HIGH), walkinsPerDay = 0, phonePerDay = perDay, cooldown = 0,
		days = days }))
end
local g1 = gateRun(1, 1)
eq("XP gate: one pop", g1.phonePops, 1)
eq("XP gate: an xp 70 award pays max 60", g1.cardXP, 60)
local g4 = gateRun(4, 1)
eq("XP gate: four pops on day 1", g4.phonePops, 4)
eq("XP gate: four xp 70 awards on one day pay 60 + 60 + 60 + 0 (dailyMax 3)", g4.cardXP, 180)
local g8 = gateRun(4, 2)
eq("XP gate: eight pops over two days", g8.phonePops, 8)
eq("XP gate: the daily count starts again on day 2 (2 x 180)", g8.cardXP, 360)

-- every Resolve sees the sim's level in its career copy: on the base run (the beats' XP) the levels Resolve sees are
-- whole numbers 1..10, never falling, and pass level 1
local SL, logL = spy()
Sim.Run(input({ rules = SL }))
local lastLevel, levelBad, rose = 0, nil, false
for i, rv in ipairs(logL.resolves) do
	if not (isNum(rv.level) and rv.level >= 1 and rv.level <= 10 and rv.level >= lastLevel) and not levelBad then
		levelBad = "resolve " .. i .. ": level " .. tostring(rv.level) .. " after " .. lastLevel
	end
	if isNum(rv.level) then
		if rv.level > 1 then rose = true end
		lastLevel = rv.level
	end
end
ok("every Resolve's career carries level = sim.level (" .. tostring(levelBad) .. ")", levelBad == nil and #logL.resolves > 0)
ok("the level Resolve sees rises past 1 over 30 days", rose)

-- input.prefer = { [cardId] = choiceIndex }: the random policy always takes that choice on that card, and still draws
-- on the others. Card `two` (three free sure choices) and card `other` (two); 10 days. Control: without prefer, the
-- random policy takes choice 1 on `two` sometimes. Run's `pinned` counts the picks the pin made: every t2 resolve
-- under prefer, 0 without it, and 0 when the pinned index doesn't exist (the silent fallback the pacing spec guards)
local twoCard = card("two", "fxt", { { text = "t1", sure = true, good = outcome({}) }, { text = "t2", sure = true, good = outcome({}) },
	{ text = "t3", sure = true, good = outcome({}) } })
local otherCard = card("other", "fxo", { { text = "o1", sure = true, good = outcome({}) }, { text = "o2", sure = true, good = outcome({}) } })
local function preferRun(prefer)
	local s, l = spy()
	local res = Sim.Run(input({ rules = s, deck = deckOf({ twoCard, otherCard }), cooldown = 0, days = 10, policy = "random",
		prefer = prefer }))
	local on = { t1 = 0, t2 = 0, t3 = 0, o1 = 0, o2 = 0 }
	for _, rv in ipairs(l.resolves) do on[rv.choice.text] += 1 end
	return on, res, l
end
local pref, prefRes = preferRun({ two = 2 })
ok(string.format("prefer { two = 2 }: the random policy picks choice 2 on card two (t1 %d, t2 %d, t3 %d)", pref.t1, pref.t2, pref.t3),
	pref.t2 > 0 and pref.t1 == 0 and pref.t3 == 0)
ok(string.format("prefer { two = 2 }: the other card is still random (o1 %d, o2 %d)", pref.o1, pref.o2), pref.o1 > 0 and pref.o2 > 0)
eq("prefer { two = 2 }: Run's pinned counts every pinned pick (the t2 resolves)", prefRes.pinned, pref.t2)
local unpref, unprefRes, unprefLog = preferRun(nil)
ok(string.format("control: without prefer the random policy takes t1 and t3 too (t1 %d, t3 %d)", unpref.t1, unpref.t3),
	unpref.t1 > 0 and unpref.t3 > 0)
eq("control: without prefer, pinned is 0", unprefRes.pinned, 0)
local _, missRes = preferRun({ two = 9 })
eq("prefer { two = 9 } (no choice 9): the pin falls back and pinned is 0", missRes.pinned, 0)

-- prefer naming no card in the deck is inert: the same resolves (choice and roll, in order), the same shares and the
-- same result as no prefer, and pinned 0
local _, ghostRes, ghostLog = preferRun({ nosuchcard = 1 })
eq("prefer { nosuchcard = 1 }: as many resolves as no prefer", #ghostLog.resolves, #unprefLog.resolves)
local sameLog = #ghostLog.resolves == #unprefLog.resolves and #unprefLog.resolves > 0
for i, rv in ipairs(unprefLog.resolves) do
	local g = ghostLog.resolves[i]
	if not (g and g.choice == rv.choice and g.roll == rv.roll and g.money == rv.money) then sameLog = false end
end
ok("prefer { nosuchcard = 1 }: the resolve log equals no prefer's, choice and roll in order", sameLog)
local sameShares = #ghostRes.shares == #unprefRes.shares
for d, v in ipairs(unprefRes.shares) do if ghostRes.shares[d] ~= v then sameShares = false end end
ok("prefer { nosuchcard = 1 }: the daily shares equal no prefer's", sameShares)
for _, k in ipairs({ "steadyShare", "studioTwoDay", "legendDay", "placements", "hits", "phonePops", "phoneAura", "cardXP", "pinned" }) do
	eq("prefer { nosuchcard = 1 }: result." .. k .. " equals no prefer's", ghostRes[k], unprefRes[k])
end
eq("prefer { nosuchcard = 1 }: pinned is 0", ghostRes.pinned, 0)

-- greedy's expectedMoney on a ready choice uses ChoiceChance: the career starts past every readiness mark (a
-- CareerRules stand-in's Defaults: 12 placements, 90,000 followers, 1,500 Aura) and every level threshold is 0 (level
-- 10), so readiness is 1 and the chance 90 %: a free ready choice worth $1,000 / $0 is worth $900, above a sure $850.
-- The old path (Chance(odds or 50), at most 75 % here) and a career copy without the level (nil counts as level 1,
-- 73 %) both value it under $850. Control: every level threshold out of reach (level 1) gives 73 %, so the cash
local function careerAt(stats)
	return setmetatable({ Defaults = function() return merge(CR.Defaults(), stats) end }, { __index = CR })
end
local readyBig = { text = "ready", ready = true, good = outcome({ money = 1000 }), bad = outcome({}) }
local cash850 = { text = "cash850", sure = true, good = outcome({ money = 850 }) }
local PAST = { placements = 12, followers = 90000, aura = 1500 }
local function readyPicks(levels, stats)
	local s, l = spy()
	Sim.Run(input({ rules = s, careerRules = careerAt(stats), auraHeal = 0, cooldown = 0, days = 3, policy = "greedy",
		economy = economy({ levels = levels, feeds = NO_FEEDS }), deck = oneCard({ readyBig, cash850 }) }))
	local nr, nc, chance = 0, 0, nil
	for _, rv in ipairs(l.resolves) do
		if rv.choice == readyBig then nr += 1; chance = chance or rv.chance elseif rv.choice == cash850 then nc += 1 end
	end
	return nr, nc, chance
end
local ZERO_LEVELS = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
local nr, nc, rc = readyPicks(ZERO_LEVELS, PAST)
ok(string.format("greedy values a ready choice at ChoiceChance (readiness 1, 90 %%): ready %d, cash %d", nr, nc), nr > 0 and nc == 0)
eq("greedy ready choice: Resolve's chance is 90", rc, 90)
nr, nc = readyPicks({ 0, 1e9, 1e9, 1e9, 1e9, 1e9, 1e9, 1e9, 1e9, 1e9 }, PAST)
ok(string.format("control: at level 1 the ready choice is 73 %%, under the cash (ready %d, cash %d)", nr, nc), nr == 0 and nc > 0)

-- Wave 2: the fame tiers (Config.Life.Tiers in input.tiers, the visits in input.tierVisits) ------------------------------

local TIERS, VISITS = E.LIFE.Tiers, E.LIFE.TierVisits
local function tierInput(over) return input(merge({ tiers = TIERS, tierVisits = VISITS }, over)) end
-- an economy that moves no Followers by itself: only the cards (and `over`) do
local function quietEconomy(over)
	return economy(merge({ requests = {}, daily = { cred = 0, xp = 0, count = 0 }, weekly = { cred = 0, xp = 0 }, streakBonus = {},
		cypherWinCred = 0, cypherXP = 0, firePerDay = 0,
		feeds = { delivery = { [2] = {}, [3] = {} }, plaque = {}, cypher = {}, fire = {} } }, over))
end
local function tierFollowups()
	local f = {}
	for _, id in pairs(VISITS) do
		f[id] = { id = id, visitor = "fxv_" .. id, tag = "TAG", line = "hey", resolve = { odds = 50, good = outcome({}), bad = outcome({}) } }
	end
	return f
end
-- a card with one sure choice moving Followers by n, while `needs` and `under` hold
local function moveCard(id, n, needs, under)
	return card(id, "fx_" .. id, { { text = "go", sure = true, good = outcome({ followers = n }) } }, { needs = needs, under = under })
end
local function eventsOf(l, ev, id)
	local found = {}
	for _, e in ipairs(l.events) do if e.ev == ev and e.id == id then table.insert(found, e) end end
	return found
end

-- one visit a day: 0 -> 900 on day 1, 900 -> 1,100 on day 2, then back to 900 and over the line again and again
local RISE = deckOf({ moveCard("fx_to900", 900, nil, { followers = 900 }), moveCard("fx_over", 200, { followers = 900 }, { followers = 1000 }),
	moveCard("fx_fall", -200, { followers = 1000 }) }, tierFollowups())
local riseSpy, riseLog = spy()
local rise = Sim.Run(tierInput({ rules = riseSpy, days = 12, walkinsPerDay = 1, economy = quietEconomy(), deck = RISE }))
local risePlants = eventsOf(riseLog, "plant", "tier_buzzing")
eq("a rise across 1,000 plants tier_buzzing once", #risePlants, 1)
ok("tier_buzzing at {1, 2}", risePlants[1] ~= nil and risePlants[1].range[1] == 1 and risePlants[1].range[2] == 2)
ok("tier_buzzing was planted on the crossing's visit", risePlants[1] ~= nil and risePlants[1].count == 2)
eq("tierDays.BUZZING is the crossing's day", rise.tierDays.BUZZING, 2)
eq("tierDays.KNOWN: not reached", rise.tierDays.KNOWN, nil)
eq("tierDays never holds LOCAL", rise.tierDays.LOCAL, nil)
ok("the visit came", #eventsOf(riseLog, "pick", "tier_buzzing") == 1)
ok(string.format("the Followers fell (%d falls) and rose again (%d rises) after the visit", #eventsOf(riseLog, "pick", "fx_fall"),
	#eventsOf(riseLog, "pick", "fx_over")), #eventsOf(riseLog, "pick", "fx_fall") >= 2 and #eventsOf(riseLog, "pick", "fx_over") >= 3)
for _, id in ipairs({ "tier_known", "tier_famous", "tier_icon" }) do eq(id .. " not planted", #eventsOf(riseLog, "plant", id), 0) end

-- A4: one move across two lines handles both, in order, one visit after the other
local JUMP = deckOf({ moveCard("fx_to900", 900, nil, { followers = 900 }), moveCard("fx_jump", 5100, { followers = 900 }, { followers = 1000 }),
	plain("fx_after", "fx_after", { needs = { followers = 1000 } }) }, tierFollowups())
local jumpSpy, jumpLog = spy()
local jump = Sim.Run(tierInput({ rules = jumpSpy, days = 8, walkinsPerDay = 1, economy = quietEconomy(), deck = JUMP }))
local b, k = eventsOf(jumpLog, "plant", "tier_buzzing")[1], eventsOf(jumpLog, "plant", "tier_known")[1]
ok("900 -> 6,000 plants tier_buzzing and tier_known", b ~= nil and k ~= nil)
if b and k then
	ok("tier_buzzing at {1, 2}", b.range[1] == 1 and b.range[2] == 2)
	ok("tier_known at {2, 3}", k.range[1] == 2 and k.range[2] == 3)
	eq("both on the crossing's visit", k.count, b.count)
	ok("BUZZING's visit is due first", b.at < k.at)
end
eq("tierDays.BUZZING on the jump", jump.tierDays.BUZZING, 2)
eq("tierDays.KNOWN on the jump", jump.tierDays.KNOWN, 2)
eq("tierDays.FAMOUS on the jump", jump.tierDays.FAMOUS, nil)
eq("each tier once on the jump", #eventsOf(jumpLog, "plant", "tier_buzzing") + #eventsOf(jumpLog, "plant", "tier_known"), 2)
local firstVisit, secondVisit
for _, e in ipairs(jumpLog.events) do
	if e.ev == "pick" and (e.id == "tier_buzzing" or e.id == "tier_known") then
		if not firstVisit then firstVisit = e.id elseif not secondVisit then secondVisit = e.id end
	end
end
eq("the BUZZING visit comes first", firstVisit, "tier_buzzing")
eq("then the KNOWN visit", secondVisit, "tier_known")

-- a crossing away from any card counts too: Followers fed by the beat loop (addStat), planted on the day's visit count
local feedSpy, feedLog = spy()
local fed = Sim.Run(tierInput({ rules = feedSpy, days = 4, walkinsPerDay = 1, deck = deckOf({ plain("fx_p", "fx_p") }, tierFollowups()),
	economy = quietEconomy({ firePerDay = 1, feeds = { delivery = { [2] = {}, [3] = {} }, plaque = {}, cypher = {}, fire = { followers = 400 } } }) }))
eq("a fed crossing: tierDays.BUZZING", fed.tierDays.BUZZING, 3)
eq("a fed crossing plants the visit", #eventsOf(feedLog, "plant", "tier_buzzing"), 1)

-- a phone pop's Followers cross a line too
local popRes = Sim.Run(tierInput({ days = 2, walkinsPerDay = 1, phonePerDay = 1, economy = quietEconomy(),
	deck = deckOf({ plain("fx_p", "fx_p"), newsCard("fx_news", "fx_feed", outcome({ followers = 1500 })) }, tierFollowups()) }))
eq("a pop's crossing: tierDays.BUZZING", popRes.tierDays.BUZZING, 1)

-- no tier visit in the deck: the days still count and nothing draws, so the run is the run without tiers
local plainRun, tierRun = Sim.Run(input()), Sim.Run(tierInput())
ok("a deck without the visits still counts days", tierRun.tierDays.BUZZING ~= nil)
eq("a deck without the visits draws nothing more: share", tierRun.steadyShare, plainRun.steadyShare)
eq("a deck without the visits draws nothing more: placements", tierRun.placements, plainRun.placements)
eq("a deck without the visits draws nothing more: hits", tierRun.hits, plainRun.hits)
eq("a deck without the visits draws nothing more: studioTwoDay", tierRun.studioTwoDay, plainRun.studioTwoDay)
eq("a deck without the visits draws nothing more: legendDay", tierRun.legendDay, plainRun.legendDay)
eq("a deck without the visits draws nothing more: phoneAura", tierRun.phoneAura, plainRun.phoneAura)
eq("a deck without the visits draws nothing more: cardXP", tierRun.cardXP, plainRun.cardXP)
-- no tiers input: no days, no plants, even with the visits in the deck
local offSpy, offLog = spy()
local off = Sim.Run(input({ rules = offSpy, days = 6, walkinsPerDay = 1, economy = quietEconomy(), deck = RISE }))
eq("no tiers input: no tier days", next(off.tierDays), nil)
eq("no tiers input: no plant", #eventsOf(offLog, "plant", "tier_buzzing"), 0)

-- F4: a tier crossed before the first walk-in (FIRE runs before any visit) can't take the first slot: the visit is planted
-- one later on both ends, the first pick is the gentle card, and the visit comes after it
local gentleSpy, gentleLog = spy()
local gentleRun = Sim.Run(tierInput({ rules = gentleSpy, days = 1, walkinsPerDay = 3,
	deck = deckOf({ plain("fx_p", "fx_p"), plain("fx_first", "fxf", { first = true, under = { visits = 1 } }) }, tierFollowups()),
	economy = quietEconomy({ firePerDay = 1, feeds = { delivery = { [2] = {}, [3] = {} }, plaque = {}, cypher = {}, fire = { followers = 1500 } } }) }))
eq("count 0: BUZZING on day 1", gentleRun.tierDays.BUZZING, 1)
local gentlePlants = eventsOf(gentleLog, "plant", "tier_buzzing")
eq("count 0: one plant", #gentlePlants, 1)
ok("count 0: planted before any visit", gentlePlants[1] ~= nil and gentlePlants[1].count == 0)
ok("count 0: at {2, 3}", gentlePlants[1] ~= nil and gentlePlants[1].range[1] == 2 and gentlePlants[1].range[2] == 3)
local firstPick, visitPick
for _, e in ipairs(gentleLog.events) do
	if e.ev == "pick" then
		firstPick = firstPick or e
		if e.id == "tier_buzzing" and not visitPick then visitPick = e end
	end
end
eq("count 0: the first pick is the gentle card", firstPick and firstPick.id, "fx_first")
ok("count 0: the visit still comes, after the first walk-in", visitPick ~= nil and visitPick.count >= 1)

-- Wave 3: your beat (design 4.1) ------------------------------------------------------------------------------------------
-- The sim keeps recent beats as Contracts does (WalkInRules.RecentPush / RecentFire, economy.WALKINS.RecentMax): every
-- delivery is a new beat with its stars, newest first; the day's FIRE (it runs after the day's deliveries) credits the
-- newest, or, with no beat yet, a beat that aired without a delivery (stars 0). A `beat` choice rolls with
-- BeatTilt(BeatQuality(BestBeat(recent))), a `beatMin` one by that quality (Resolve's beatQ), and greedy values both
-- through RollChance.

-- an economy whose only deliveries are `dailies` dailies a day (3, 2, 3, ... stars across the days), with `fire` FIRE a
-- day and no feeds (Aura and Followers stay 0, so a chance is its base plus the beat tilt)
local function beatEconomy(dailies, fire, over)
	return economy(merge({ requests = {}, daily = { cred = 200, xp = 15, count = dailies }, firePerDay = fire, feeds = NO_FEEDS }, over))
end
local function beatRun(days, dailies, fire, over)
	return Sim.Run(input(merge({ days = days, walkinsPerDay = 0, economy = beatEconomy(dailies, fire), deck = deckOf({}) }, over)))
end
local function shape(recent)
	local parts = {}
	for _, e in ipairs(recent or {}) do table.insert(parts, string.format("%s*/%sf/d%s", tostring(e.stars), tostring(e.fires), tostring(e.day))) end
	return table.concat(parts, " ")
end
-- a sim day's deliveries push recent beats with the sim's stars; its FIRE credits the newest
local r1 = beatRun(1, 2, 3)
eq("recent: two dailies on day 1, FIRE x3 on the newest", shape(r1.recent), "2*/3f/d1 3*/0f/d1")
ok("recent: each delivery is its own beat (distinct patterns, a bpm)", r1.recent and #r1.recent == 2 and r1.recent[1].pattern ~= r1.recent[2].pattern
	and type(r1.recent[1].pattern) == "string" and type(r1.recent[1].bpm) == "number")
eq("recent: four dailies keep the newest three (RecentMax 3), no FIRE", shape(beatRun(1, 4, 0).recent), "2*/0f/d1 3*/0f/d1 2*/0f/d1")
eq("recent: each day's FIRE goes to that day's newest", shape(beatRun(2, 1, 1).recent), "2*/1f/d2 3*/1f/d1")
eq("recent: FIRE with no delivery credits an aired beat at 0 stars", shape(beatRun(1, 0, 2).recent), "0*/2f/d1")
eq("recent: no deliveries and no FIRE, none", shape(beatRun(1, 0, 0).recent), "")
local weekly = beatRun(7, 0, 0).recent
eq("recent: the weekly single (day 7, 3 stars) is a beat too", shape(weekly), "3*/0f/d7")

-- a beat choice rolls with BeatTilt of the best beat's quality; any other choice with no tilt. One free beat choice and
-- one plain one, random, 16 visits over 2 days. One 3-star daily a day with 3 FIRE: the best stays day 1's 3 stars with
-- 3 FIRE, quality 4, tilt +4, chance 54. No beat at all: quality 0, tilt -12, chance 38. The plain choice: 50
local flagC = { text = "flag", odds = 50, beat = true, good = outcome({ placements = 1 }), bad = outcome({}) }
local plainC = { text = "plain", odds = 50, good = outcome({}), bad = outcome({}) }
local function tiltLog(dailies, fire)
	local s, l = spy()
	local res = Sim.Run(input({ rules = s, days = 2, cooldown = 0, economy = beatEconomy(dailies, fire), deck = oneCard({ flagC, plainC }) }))
	return l, res
end
for _, case in ipairs({ { label = "best beat quality 4", dailies = 1, fire = 3, q = 4, tilt = 4, chance = 54 },
	{ label = "no beat", dailies = 0, fire = 0, q = 0, tilt = -12, chance = 38 } }) do
	local l, res = tiltLog(case.dailies, case.fire)
	local nf, np = 0, 0
	for _, rv in ipairs(l.resolves) do
		if rv.choice == flagC then
			nf += 1
			eq("beat tilt (" .. case.label .. "): the beat choice's tilt", rv.tilt, case.tilt)
			eq("beat tilt (" .. case.label .. "): the beat choice's beatQ", rv.beatQ, case.q)
			eq("beat tilt (" .. case.label .. "): the beat choice's chance", rv.chance, case.chance)
		elseif rv.choice == plainC then
			np += 1
			ok("beat tilt (" .. case.label .. "): the plain choice has no tilt", (rv.tilt or 0) == 0)
			eq("beat tilt (" .. case.label .. "): the plain choice's chance", rv.chance, 50)
		end
	end
	ok(string.format("beat tilt (%s): both choices rolled (beat %d, plain %d)", case.label, nf, np), nf > 0 and np > 0)
	eq("beat tilt (" .. case.label .. "): Run's beatRolls counts the beat choice's rolls", res.beatRolls, nf)
	eq("beat tilt (" .. case.label .. "): Run's beatTilt sums their tilt", res.beatTilt, nf * case.tilt)
end

-- greedy values a beat choice at its tilted chance (RollChance): a free beat choice worth $1,000 / $0 against a sure $450.
-- At quality 4 it is worth $540 and wins; with no beat $380, so the cash. Without the tilt it would be $500 both times
local flagBig = { text = "flagBig", odds = 50, beat = true, good = outcome({ placements = 1, money = 1000 }), bad = outcome({}) }
local cash450 = { text = "cash450", sure = true, good = outcome({ money = 450 }) }
local function greedyBeat(dailies, fire, a, b)
	local s, l = spy()
	Sim.Run(input({ rules = s, days = 1, cooldown = 0, policy = "greedy", economy = beatEconomy(dailies, fire), deck = oneCard({ a, b }) }))
	local na, nb = 0, 0
	for _, rv in ipairs(l.resolves) do if rv.choice == a then na += 1 elseif rv.choice == b then nb += 1 end end
	return na, nb
end
local na, nb = greedyBeat(1, 3, flagBig, cash450)
ok(string.format("greedy: a beat choice at quality 4 (54 %%) beats a sure $450 (beat %d, cash %d)", na, nb), na > 0 and nb == 0)
na, nb = greedyBeat(0, 0, flagBig, cash450)
ok(string.format("greedy: with no beat (38 %%) the sure $450 wins (beat %d, cash %d)", na, nb), na == 0 and nb > 0)

-- a beatMin choice goes by its beat before anything else (CareerSim once let `sure` win): one marked sure as well, worth
-- $1,000 when good, against a sure $850. With no beat it is worth $0 to greedy (the cash), and random's rolls of it are
-- all bad (Resolve got beatQ 0); at quality 4 greedy takes it
local beatMinC = { text = "beatMin", beatMin = 3, sure = true, good = outcome({ money = 1000 }), bad = outcome({}) }
local cash850b = { text = "cash850", sure = true, good = outcome({ money = 850 }) }
na, nb = greedyBeat(0, 0, beatMinC, cash850b)
ok(string.format("greedy: a beatMin choice with no beat is worth $0, so the cash (beatMin %d, cash %d)", na, nb), na == 0 and nb > 0)
na, nb = greedyBeat(1, 3, beatMinC, cash850b)
ok(string.format("greedy: a beatMin choice at quality 4 is worth $1,000 (beatMin %d, cash %d)", na, nb), na > 0 and nb == 0)
do
	local s, l = spy()
	Sim.Run(input({ rules = s, days = 1, cooldown = 0, economy = beatEconomy(0, 0), deck = oneCard({ beatMinC, cash850b }) }))
	local n, allBad = 0, true
	for _, rv in ipairs(l.resolves) do
		if rv.choice == beatMinC then
			n += 1
			if rv.roll ~= "bad" or rv.beatQ ~= 0 then allBad = false end
		end
	end
	ok(string.format("random: a beatMin choice with no beat rolls bad with beatQ 0 every time (%d rolls)", n), n > 0 and allBad)
end

-- Wave 3: the cold spell (design 4.2) ------------------------------------------------------------------------------------
-- With economy.WALKINS.Cold the sim runs CareerRules.ColdStep as Systems/Career does: "check" at the day's first step and
-- after every Aura move, "delivery3" on a 3-star delivery, "fire" on each FIRE. lastDay = the last delivery's day,
-- defaulted on the first check; a thaw sets it to the thaw's day. While cold: at most Cold.dailyMax walk-ins a day and no
-- phone pop, the spell's one cold_news counted on the day's phone total. Without Cold, no cold at all (the economies above).
local COLD = { aura = -50, quietDays = 3, rearmAura = -25, dailyMax = 2 }
local function coldEconomy(dailies, fire)
	return beatEconomy(dailies, fire, { WALKINS = { RecentMax = 3, Cold = COLD } })
end
local function coldLog(res)
	local parts = {}
	for _, e in ipairs(res.coldLog or {}) do table.insert(parts, string.format("%s %d %s", e.kind, e.day, tostring(e.reason or e.event))) end
	return table.concat(parts, ", ")
end
local function coldDays(res, days)
	local parts = {}
	for d = 1, days do if (res.coldDays or {})[d] then table.insert(parts, tostring(d)) end end
	return table.concat(parts, ",")
end
-- walk-in arrivals a day, from a spy's picks (a pick that found a card is a visit)
local function visitsByDay(l)
	local by = {}
	for _, e in ipairs(l.events) do
		if e.ev == "pick" and e.source == "walkin" and e.kind ~= nil then by[e.day] = (by[e.day] or 0) + 1 end
	end
	return by
end

-- the neglect persona, no resume: 3 dailies on day 1, then nothing. Quiet on day 4 (4 - 1 = 3), cold to the end; 8 walk-ins
-- a day before, 2 a day after; 2 phone pops a day before, none after, the cold_news counted once
do
	local s, l = spy()
	local deck = deckOf({ plain("fx_walk", "fxw"), newsCard("fx_news", "fxn", outcome({})) })
	local res = Sim.Run(input({ rules = s, days = 8, cooldown = 0, walkinsPerDay = 8, phonePerDay = 2, persona = "neglect",
		economy = coldEconomy(3, 0), deck = deck }))
	eq("cold: neglect goes cold on day 4, quiet, and stays", coldLog(res), "cold 4 quiet")
	eq("cold: neglect's cold days", coldDays(res, 8), "4,5,6,7,8")
	eq("cold: firstCold", res.firstCold, 4)
	local by = visitsByDay(l)
	eq("cold: 8 walk-ins on day 3 (warm)", by[3], 8)
	eq("cold: 2 walk-ins on day 4 (Cold.dailyMax)", by[4], 2)
	eq("cold: 2 walk-ins on day 8", by[8], 2)
	eq("cold: phone pops 2 a day for 3 days, then only the cold_news", res.phonePops, 2 * 3 + 1)
end
-- the same with resumeDay 6: day 6's dailies run 2, 3, 2 stars (day 1 used 3, 2, 3): the 3-star thaws it; 8 walk-ins on
-- day 6 (deliveries come before visits) and the phone back
do
	local s, l = spy()
	local deck = deckOf({ plain("fx_walk", "fxw"), newsCard("fx_news", "fxn", outcome({})) })
	local res = Sim.Run(input({ rules = s, days = 8, cooldown = 0, walkinsPerDay = 8, phonePerDay = 2, persona = "neglect", resumeDay = 6,
		economy = coldEconomy(3, 0), deck = deck }))
	eq("cold: neglect resumes and thaws on its day-6 3-star delivery", coldLog(res), "cold 4 quiet, thaw 6 delivery3")
	eq("cold: neglect's cold days with a resume", coldDays(res, 8), "4,5")
	eq("cold: 8 walk-ins on day 6, thawed", visitsByDay(l)[6], 8)
	eq("cold: the phone back from day 6", res.phonePops, 2 * 3 + 1 + 2 * 3)
end
-- neglect gets no FIRE (an economy with FIRE: its recent beats hold no FIRE)
do
	local res = Sim.Run(input({ days = 2, walkinsPerDay = 0, persona = "neglect", economy = coldEconomy(1, 3), deck = deckOf({}) }))
	eq("cold: neglect gets no FIRE", shape(res.recent), "3*/0f/d1")
end
-- Aura and FIRE: one sure -60 Aura card, no deliveries (lastDay defaults to day 1 at its first check), 1 FIRE a day (before
-- the visits). Day 1: the first visit goes cold "aura", so 2 visits. Day 2: the FIRE thaws (rearm, lastDay 2) and the
-- visits' -60s can't re-chill it while Aura stays under rearmAura. Day 5: the day step finds 5 - 2 = 3, cold "quiet", and
-- that day's FIRE (after the day step) thaws it again
do
	local s, l = spy()
	local deck = oneCard({ { text = "ouch", sure = true, good = outcome({ aura = -60 }) } })
	local res = Sim.Run(input({ rules = s, days = 6, cooldown = 0, walkinsPerDay = 8, economy = coldEconomy(0, 1), deck = deck }))
	eq("cold: aura, fire, quiet, fire", coldLog(res), "cold 1 aura, thaw 2 fire, cold 5 quiet, thaw 5 fire")
	local by = visitsByDay(l)
	eq("cold: day 1, cold after the first visit: 2 walk-ins", by[1], 2)
	eq("cold: day 2, thawed by the FIRE: 8 walk-ins", by[2], 8)
end
-- Task 4 fix round 1. F: a 2-star delivery while cold doesn't end the spell; only the 3-star one does. One daily a day:
-- day 1's is 3 stars, the neglect persona resumes on day 6 with a 2-star one (no thaw) and day 7's 3-star thaws it
do
	local res = Sim.Run(input({ days = 8, walkinsPerDay = 0, persona = "neglect", resumeDay = 6, economy = coldEconomy(1, 0), deck = deckOf({}) }))
	eq("cold: a 2-star delivery while cold doesn't thaw; the next 3-star does", coldLog(res), "cold 4 quiet, thaw 7 delivery3")
	eq("cold: cold days through the 2-star day", coldDays(res, 8), "4,5,6")
end
-- F: every delivery is the last delivery's day, so a player delivering every day never goes quiet (one daily a day, no
-- FIRE, 10 days: 3, 2, 3, ... stars)
do
	local res = Sim.Run(input({ days = 10, walkinsPerDay = 0, economy = coldEconomy(1, 0), deck = deckOf({}) }))
	eq("cold: a daily every day keeps lastDay moving: never cold", coldLog(res), "")
end
-- D: never cold on a first read. Starting at Aura -60 with nothing moving it (no deliveries, FIRE, feeds, walk-ins or
-- heal): day 1's check finds no lastDay, saves day 1 and stays warm; day 2's check goes cold "aura"
do
	local startAt = setmetatable({ Defaults = function()
		local d = CR.Defaults()
		d.aura = -60
		return d
	end }, { __index = CR })
	local res = Sim.Run(input({ days = 3, walkinsPerDay = 0, careerRules = startAt, economy = coldEconomy(0, 0), deck = deckOf({}) }))
	eq("cold: the first read (no lastDay) never goes cold; the next check does", coldLog(res), "cold 2 aura")
end
-- C: a quiet spell that ends deep in the red re-arms (CareerRules.ColdStep, ruling C). Neglect with one daily a day (day 1
-- 3 stars; resumeDay 6: day 6 2 stars, day 7 3) and a cypher win every even day that costs 30 Aura: day 2 -30 (warm), day
-- 4 goes cold "quiet" and its cypher takes it to -60, day 6 -90; day 7's 3-star thaws it with rearm, so day 8's check at
-- -90 (and its cypher, -120) never re-chills it as "aura"
do
	local feeds = merge(table.clone(NO_FEEDS), { cypher = { aura = -30 } })
	local res = Sim.Run(input({ days = 9, walkinsPerDay = 0, persona = "neglect", resumeDay = 6, deck = deckOf({}),
		economy = beatEconomy(1, 0, { WALKINS = { RecentMax = 3, Cold = COLD }, feeds = feeds }) }))
	eq("cold: a quiet spell thawed at -90 re-arms: no 'aura' relapse", coldLog(res), "cold 4 quiet, thaw 7 delivery3")
	eq("cold: cold days of the deep quiet spell", coldDays(res, 9), "4,5,6")
end

-- no Cold in the economy: no cold model (the same run never goes cold)
do
	local deck = oneCard({ { text = "ouch", sure = true, good = outcome({ aura = -60 }) } })
	local res = Sim.Run(input({ days = 6, cooldown = 0, walkinsPerDay = 8, economy = beatEconomy(0, 1), deck = deck }))
	eq("cold: no Cold config, no cold", coldLog(res), "")
	eq("cold: no Cold config, firstCold nil", res.firstCold, nil)
end

-- Wave 3: they remember you (design 4.3) -----------------------------------------------------------------------------
-- The sim keeps sim.rel as Systems/WalkIns keeps prof.walkins.rel, through the same pure rules: an outcome's `rel` is
-- WalkInRules.RelWrite (for rel.who or the item's visitor, on the sim day), walk-in or phone; Pick and Seed get
-- opts.rel, so GateOk reads the flags and scores; a rolled choice, a walk-in's or (fix round 1) a phone pop's, tilts by
-- RelTilt of its card's visitor's score on input.odds, added to the beat tilt; any signing resets rel.rep; under the
-- sponsor's floor with rel.rep's score 1+ the system plants sponsor_warning (at dropAt) instead of sponsor_drop, never
-- while either is queued, and the warning's arrival plants the drop at {2,3}. Run returns rel, firstSeen ({ [id] = the
-- day it first came, walk-in or pop }), relRolls (rolls with a rel tilt) and relTilt (their sum). relPer is a literal
-- here (5, not the beat's 4), so a retune of Config can't move these cases; the economies above have no relPer and no
-- rel content
local REL_ODDS = merge(table.clone(ODDS), { relPer = 5 })
local function relOut(o) return outcome(merge({ tone = "neutral" }, o)) end
local function relShow(e)
	if e == nil then return "nil" end
	local fl = {}
	for f, d in pairs(e.flags or {}) do table.insert(fl, f .. "@" .. tostring(d)) end
	table.sort(fl)
	return string.format("score %s, flags %s", tostring(e.score), table.concat(fl, " "))
end
-- a spy that records whether every Pick and Seed got opts.rel as a table
local function relSpy()
	local log = { calls = 0, missing = 0, resolves = {}, plants = {} }
	local S = setmetatable({}, { __index = R })
	local function check(opts) log.calls += 1; if type(opts.rel) ~= "table" then log.missing += 1 end end
	function S.Pick(st, d, o) check(o); return R.Pick(st, d, o) end
	function S.Seed(st, d, o) check(o); return R.Seed(st, d, o) end
	function S.Resolve(choice, c, odds, rng, tilt, beatQ)
		local res = R.Resolve(choice, c, odds, rng, tilt, beatQ)
		table.insert(log.resolves, { choice = choice, tilt = tilt, chance = res.chance })
		return res
	end
	function S.Plant(state, plant, at, rng, ctx)
		local e = R.Plant(state, plant, at, rng, ctx)
		if e then table.insert(log.plants, { id = e.id, at = e.at, count = state.count, sponsor = ctx and ctx.sponsor }) end
		return e
	end
	return S, log
end
local function relRun(over)
	return Sim.Run(input(merge({ odds = REL_ODDS, days = 1, cooldown = 0, economy = beatEconomy(0, 0) }, over)))
end

-- every write applies and the score holds at 3; the flag is stamped with the sim day of its last write
do
	local deck = oneCard({ { text = "meet", sure = true, good = relOut({ rel = { score = 1, flag = "met" } }) } })
	local res = relRun({ days = 2, walkinsPerDay = 4, deck = deck })
	eq("rel: 8 writes of +1 hold at 3, the flag on day 2", relShow(res.rel and res.rel.fxo), "score 3, flags met@2")
end
-- rel.who writes another visitor's memory; a clear removes a flag
do
	local deck = oneCard({ { text = "tell", sure = true, good = relOut({ rel = { who = "fxk", flag = "told", score = -1 } }) } })
	local res = relRun({ walkinsPerDay = 1, deck = deck })
	eq("rel: who = fxk writes to fxk", relShow(res.rel and res.rel.fxk), "score -1, flags told@1")
	eq("rel: and not to the card's own visitor", relShow(res.rel and res.rel.fxo), "nil")
end
-- the gates read sim.rel (opts.rel on every Pick and Seed): fx_gate needs fxb's `met`, which only fx_meet sets, so it never
-- comes before fx_meet; firstSeen records both days
do
	local s, l = relSpy()
	local deck = deckOf({
		card("fx_gate", "fxa", { { text = "a", sure = true, good = relOut({}) }, { text = "b", sure = true, good = relOut({}) } },
			{ needs = { flags = { "fxb.met" } } }),
		card("fx_meet", "fxb", { { text = "a", sure = true, good = relOut({ rel = { flag = "met" } }) } }),
	})
	local res = relRun({ rules = s, days = 4, walkinsPerDay = 1, deck = deck })
	eq("rel gate: fx_meet first comes on day 1", res.firstSeen and res.firstSeen.fx_meet, 1)
	ok("rel gate: fx_gate comes once fxb.met is set, never before (firstSeen " .. tostring(res.firstSeen and res.firstSeen.fx_gate) .. ")",
		res.firstSeen ~= nil and type(res.firstSeen.fx_gate) == "number" and res.firstSeen.fx_gate > 1)
	ok(string.format("rel gate: every Pick and Seed got opts.rel as a table (%d calls, %d without)", l.calls, l.missing), l.calls > 0 and l.missing == 0)
end
-- a rolled walk-in choice tilts by score * relPer: +1 each roll on fxo's own card, so 0, 5, 10, 15, then held at 15. A beat
-- choice adds its beat tilt (no beat: (0 - 3) * 4 = -12); beatRolls / beatTilt stay the beat's alone
do
	local function tilts(choice, n)
		local s, l = relSpy()
		local res = relRun({ rules = s, walkinsPerDay = n, deck = oneCard({ choice }) })
		local t, c = {}, {}
		for _, rv in ipairs(l.resolves) do table.insert(t, tostring(rv.tilt)); table.insert(c, tostring(rv.chance)) end
		return table.concat(t, ","), table.concat(c, ","), res
	end
	local roll = { text = "roll", odds = 50, good = relOut({ rel = { score = 1 } }), bad = relOut({ rel = { score = 1 } }) }
	local t, c, res = tilts(roll, 5)
	eq("rel tilt: a rolled choice's tilt as the score climbs", t, "0,5,10,15,15")
	eq("rel tilt: its chance", c, "50,55,60,65,65")
	eq("rel tilt: relRolls counts the rolls with a rel tilt", res.relRolls, 4)
	eq("rel tilt: relTilt sums them", res.relTilt, 45)
	local beatRoll = { text = "beat", odds = 50, beat = true, good = relOut({ placements = 1, rel = { score = 1 } }), bad = relOut({ rel = { score = 1 } }) }
	t, c, res = tilts(beatRoll, 3)
	eq("rel tilt: a beat choice adds its beat tilt", t, "-12,-7,-2")
	eq("rel tilt: beatTilt is the beat's alone", res.beatTilt, -36)
	eq("rel tilt: relTilt the rel's alone", res.relTilt, 15)
	local sure = { text = "sure", sure = true, good = relOut({ rel = { score = 1 } }) }
	_, _, res = tilts(sure, 3)
	eq("rel tilt: a sure choice never counts as a rel roll", res.relRolls, 0)
end
-- a phone pop's rolled choice tilts by its card's visitor's score too, as a walk-in's does (fix round 1, D; the
-- controller's 11-06 ruling: a DM from fxo is fxo's card): 0, 5, 10, 15 as each pop's +1 lands. The tilt reads the card's
-- own visitor: once fxo's walk-ins have put it at 3, fxo's DM rolls at +15 and fxq's (no relationship) untilted
do
	local function rolls(l, choice)
		local t, c = {}, {}
		for _, rv in ipairs(l.resolves) do
			if choice == nil or rv.choice == choice then
				table.insert(t, tostring(rv.tilt))
				table.insert(c, tostring(rv.chance))
			end
		end
		return table.concat(t, ","), table.concat(c, ",")
	end
	local s, l = relSpy()
	local deck = deckOf({ phoneCard("fx_dm", "fxo", {
		{ text = "roll", odds = 50, good = relOut({ rel = { score = 1 } }), bad = relOut({ rel = { score = 1 } }) },
		{ text = "roll2", odds = 50, good = relOut({ rel = { score = 1 } }), bad = relOut({ rel = { score = 1 } }) } }) })
	local res = relRun({ rules = s, walkinsPerDay = 0, phonePerDay = 4, deck = deck })
	local t, c = rolls(l)
	eq("rel: a phone pop's rolled choice tilts as the score climbs", t, "0,5,10,15")
	eq("rel: its chance", c, "50,55,60,65")
	eq("rel: relRolls counts the phone rolls with a rel tilt", res.relRolls, 3)
	eq("rel: relTilt sums them", res.relTilt, 30)
	eq("rel: phone pops still write", relShow(res.rel and res.rel.fxo), "score 3, flags ")
	-- whose score: four walk-ins put fxo at 3, then one DM each from fxo and fxq
	local fromO = { text = "o", odds = 50, good = relOut({}), bad = relOut({}) }
	local fromQ = { text = "q", odds = 50, good = relOut({}), bad = relOut({}) }
	s, l = relSpy()
	res = relRun({ rules = s, walkinsPerDay = 4, phonePerDay = 2, deck = deckOf({
		card("fx_walk", "fxo", { { text = "up", sure = true, good = relOut({ rel = { score = 1 } }) } }),
		phoneCard("fx_dmo", "fxo", { fromO }), phoneCard("fx_dmq", "fxq", { fromQ }) }) })
	eq("rel: fxo at 3 before the pops", relShow(res.rel and res.rel.fxo), "score 3, flags ")
	eq("rel: fxo's DM rolls at fxo's +15", (rolls(l, fromO)), "15")
	eq("rel: fxq's DM (no relationship) rolls untilted", (rolls(l, fromQ)), "0")
end
-- any signing resets rel.rep (score and flags): the rep's +2 and flag on the first visit, a signing on the second
do
	local function repRun(signs)
		local signOut = signs and relOut({ tone = "win", sponsor = "s1", sponsors = 1 }) or relOut({})
		local deck = deckOf({
			card("fx_duty", "rep", { { text = "a", sure = true, good = relOut({ rel = { score = 2, flag = "renewed" } }) } }, { under = { visits = 1 } }),
			card("fx_sign", "rep", { { text = "a", sure = true, good = signOut } }, { needs = { visits = 1 } }),
		})
		return relRun({ walkinsPerDay = 2, deck = deck })
	end
	eq("rel: a signing resets rel.rep", relShow((repRun(true).rel or {}).rep), "nil")
	eq("rel: control: no signing keeps it", relShow((repRun(false).rel or {}).rep), "score 2, flags renewed@1")
end
-- the rep's warning: you hold s1 (floor 100) at Aura 200. Visit 1 (fx_duty, the ad filmed) is rep +1; visit 2 (fx_crash)
-- takes Aura to 0, and with `sayNo` it is also rep -1 (the ad, then a "no": rel.rep is { score 0 }, there but under 1);
-- from visit 3 (fx_after) every arrival is under the floor. At rep 1: sponsor_warning is planted at visit 3 (dropAt
-- {1,1}), comes at visit 4 and plants sponsor_drop at {2,3}; nothing else is planted while either waits, and the drop
-- drops you. At rep 0 (fix round 1, F2: the threshold at exactly 0, not rel.rep missing): the drop at visit 3, no warning
do
	local startAt = setmetatable({ Defaults = function()
		local d = CR.Defaults()
		d.aura, d.sponsor, d.sponsors = 200, "s1", 1
		return d
	end }, { __index = CR })
	local function warnRun(sayNo)
		local s, l = relSpy()
		local crashOut = relOut(merge({ tone = "loss", aura = -200 }, sayNo and { rel = { who = "rep", score = -1 } } or nil))
		local deck = {
			cards = {
				card("fx_duty", "rep", { { text = "a", sure = true, good = relOut({ rel = { score = 1 } }) } }, { under = { visits = 1 } }),
				card("fx_crash", "fxa", { { text = "a", sure = true, good = crashOut } }, { needs = { visits = 1 }, under = { visits = 2 } }),
				card("fx_after", "fxb", { { text = "a", sure = true, good = relOut({}) } }, { needs = { visits = 2 } }),
			},
			followups = {
				sponsor_warning = { id = "sponsor_warning", visitor = "rep", tag = "T", line = "fix it", resolve = { odds = 50, good = relOut({}), bad = relOut({}) } },
				sponsor_drop = { id = "sponsor_drop", visitor = "rep", tag = "T", line = "bye",
					resolve = { odds = 50, good = relOut({ sponsor = "drop", sponsors = -1 }), bad = relOut({ sponsor = "drop", sponsors = -1 }) } },
			},
			sponsors = { s1 = 100 },
		}
		local res = relRun({ rules = s, careerRules = startAt, walkinsPerDay = 8, deck = deck })
		local parts = {}
		for _, e in ipairs(l.plants) do table.insert(parts, string.format("%s@%d+%d(%s)", e.id, e.count, e.at - e.count, tostring(e.sponsor))) end
		return table.concat(parts, " "), res
	end
	local plants, res = warnRun(false)
	eq("warning: rel.rep at 1", relShow((res.rel or {}).rep), "score 1, flags ")
	ok("warning: score 1 plants sponsor_warning at visit 3 for s1, then its arrival the drop 2 or 3 on (" .. plants .. ")",
		plants == "sponsor_warning@3+1(s1) sponsor_drop@4+2(s1)" or plants == "sponsor_warning@3+1(s1) sponsor_drop@4+3(s1)")
	eq("warning: and the drop dropped you", res.firstSeen and type(res.firstSeen.sponsor_drop), "number")
	plants, res = warnRun(true)
	eq("warning: control: rel.rep is there at score 0 (not missing)", relShow((res.rel or {}).rep), "score 0, flags ")
	eq("warning: control: score 0 plants the drop, no warning", plants, "sponsor_drop@3+1(s1)")
end

if #fails > 0 then error(#fails .. " career sim case(s) failed: " .. table.concat(fails, "; ")) end
print("SPEC OK: career sim")
