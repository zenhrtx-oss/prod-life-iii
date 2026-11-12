-- OK Studio CareerSim: a day-by-day simulation of one producer's career (beats + walk-ins + phone pops), used by the
-- pacing checks (spec/pacing_spec.lua in the CLI, build/t46_check.lua in Studio) to tune walk-in and phone content
-- against the economy targets.
-- Pure: no Roblox globals and no other modules. The rules (WalkInRules, CareerRules), the content deck, the economy
-- numbers and the rng all come in through Run's input. Phone pops draw from their own stream (Lcg(phoneSeed + 100003)),
-- so a deck without phone cards draws exactly what a phoneless run draws.
-- Your beat (Wave 3, design 4.1): sim.recent holds the recent beats as Contracts keeps prof.sessions.recent, through the
-- same pure functions (WalkInRules.RecentPush / RecentFire, economy.WALKINS.RecentMax): every paying delivery is a new
-- beat (a real one must differ from the last by 8 pads) with its stars, and the day's FIRE credits the newest (an aired
-- beat at 0 stars when nothing was delivered yet). A choice marked `beat` rolls with BeatTilt(BeatQuality(BestBeat)) on
-- input.odds, a `beatMin` one by that quality (Resolve's beatQ); greedy values every choice through RollChance. No beat
-- draws from any rng, so the draws are those of a run without beats.
-- The cold spell (Wave 3, design 4.2), while economy.WALKINS.Cold is given (Config.WalkIns.Cold): the same
-- CareerRules.ColdStep Systems/Career runs, at the same moments: "check" at the day step (the day's first step, as
-- Life.Tick's) and after every Aura move, "delivery3" on a 3-star delivery and "fire" on each FIRE. lastDay is the day
-- of the last delivery, defaulted to the day of the first check (Contracts' prof.sessions.lastDay), which itself reads
-- none (never cold on a first read); a thaw sets it to that day. While cold, at most Cold.dailyMax walk-ins a day and no phone pop; the one cold_news a spell opens at once and
-- counts on the day's phone total. The `neglect` persona (input.persona = "neglect") delivers on day 1, then nothing until
-- input.resumeDay (nil = never), and gets no FIRE. No cold step draws from any rng.
-- They remember you (Wave 3, design 4.3): sim.rel is prof.walkins.rel ({ [visitorId] = { score, flags } }) through the
-- same pure rules Systems/WalkIns runs. An outcome's `rel` is WalkInRules.RelWrite for rel.who or the item's visitor on
-- the sim day, walk-in and phone alike; Pick and Seed get opts.rel; a rolled choice, a walk-in's or (fix round 1) a phone
-- pop's, tilts by RelTilt of its card's visitor's score on input.odds, on top of the beat tilt; any signing resets
-- rel.rep; under the sponsor's floor with rel.rep's score 1 or more the system plants sponsor_warning (at dropAt) instead
-- of sponsor_drop, never while either one waits, and the warning's arrival plants the drop at WARNING_DROP_AT. No rel
-- step draws an rng value the server's wouldn't (a plant draws its `at` as the server's does).
local M = {}

local REQUESTS_PER_DAY = 3   -- first-time session requests a day while they last
local STEADY_FROM = 8        -- steadyShare counts days 8..days (after the first week)
local DROP = "sponsor_drop"  -- the generic follow-up planted when Aura falls below the sponsor's floor
local PLAQUE = "mom_plaque"  -- the follow-up planted when the first HIT lands (mom comes to see the plaque)
local WARNING = "sponsor_warning" -- the rep's warning, planted instead of the drop while rel.rep's score is 1+ (Wave 3)
local WARNING_DROP_AT = { 2, 3 } -- the drop the warning's arrival plants, in walk-ins (Systems/WalkIns: the same literal)
local PHONE_STREAM = 100003  -- the phone stream's seed offset from phoneSeed
local SIM_BPM = 142          -- the bpm the sim's beats carry (DAWConfig.BPM.Default): only {beat}'s text would read it

-- a deterministic integer rng (Park-Miller): rng(lo, hi) -> whole number in [lo, hi]
function M.Lcg(seed)
	local s = math.floor(seed) % 2147483647
	if s <= 0 then s += 2147483646 end
	return function(lo, hi)
		s = s * 48271 % 2147483647
		if hi <= lo then return lo end
		return lo + s % (hi - lo + 1)
	end
end

-- the fixed seeds the pacing checks run
M.Seeds = { 1, 7, 42, 99, 123, 256, 777, 1001, 2024, 3141, 4242, 5150, 6007, 7919, 8191, 9001, 12345, 22222, 31337, 65537 }

-- "rounded as Contracts does"
local function round(x) return math.floor(x + 0.5) end

local function newSim(input)
	local CR = input.careerRules
	local sim = {
		input = input, rules = input.rules, careerRules = CR, economy = input.economy, deck = input.deck, rng = input.rng,
		phoneRng = input.phonePerDay > 0 and M.Lcg(input.phoneSeed + PHONE_STREAM) or nil,
		career = CR.Have({ cred = 0, career = CR.Defaults() }),
		-- phone = opened pops (today on the sim day, count lifetime); caps = { [group] = { key, n } } (Shared shapes)
		walkins = { day = 0, today = 0, count = 0, queue = {}, seen = {}, last = {},
			phone = { day = 0, today = 0, count = 0 }, caps = {} },
		xp = 0, level = 1, cardXP = 0, xpAwards = 0, pinned = 0, owned = {}, done = {}, requestThree = true, dailyThree = true,
		dayGained = 0, walkGained = 0, steadyAll = 0, steadyWalk = 0, shares = {}, phoneAura = 0,
		studioTwoDay = nil, legendDay = nil, today = 0, tierIndex = 1, tierDays = {},
		-- your beat: the recent beats newest first, the beats made so far (their pattern names), and the `beat` choices
		-- rolled with the sum of the tilt they rolled at
		recent = {}, beats = 0, beatRolls = 0, beatTilt = 0,
		-- the cold spell: the state (CareerRules.ColdStep's cold and rearm), the last delivery's day, the days that ended
		-- cold, every entry and exit { day, kind = "cold" | "thaw", reason?, event? } and the first day it went cold
		cold = nil, rearm = false, lastDay = nil, coldDays = {}, coldLog = {}, firstCold = nil,
		-- they remember you: the relationships (prof.walkins.rel's shape), the day each card or follow-up first came (a
		-- walk-in or an opened pop), and the rolls a relationship tilted with the sum of that tilt
		rel = {}, firstSeen = {}, relRolls = 0, relTilt = 0,
	}
	for _, g in ipairs(sim.economy.gear) do
		if g.price == 0 then sim.owned[g.id] = true end
	end
	return sim
end

-- shared helpers ------------------------------------------------------------------------------------------------------

local function earn(sim, n)
	sim.career.money += n
	sim.dayGained += n
end

-- Followers reached past the highest tier so far (input.tiers = Config.Life.Tiers, lowest first): each new tier records its
-- day in tierDays and, when the deck has its visit (input.tierVisits = Config.Life.TierVisits), plants it, as Systems/Life
-- does at the crossing: the k-th tier of one move at {k, k + 1}, one later on both ends before any walk-in (AfterFirst). The
-- tier is a high-water mark, so a fall and a re-rise plant nothing. No draw at all without a visit to plant
local function crossTiers(sim)
	local tiers = sim.input.tiers
	if not tiers then return end
	local k = 0
	while tiers[sim.tierIndex + 1] and sim.career.followers >= tiers[sim.tierIndex + 1].followers do
		sim.tierIndex += 1
		k += 1
		local id = tiers[sim.tierIndex].id
		sim.tierDays[id] = sim.today
		local visit = (sim.input.tierVisits or {})[id]
		if visit and sim.deck.followups[visit] then
			sim.rules.Plant(sim.walkins, { id = visit, at = sim.rules.AfterFirst(sim.walkins, { k, k + 1 }) }, sim.input.followupAt, sim.rng)
		end
	end
end

-- the cold spell's config (economy.WALKINS.Cold), or nil: no cold model at all
local function coldCfg(sim)
	local wi = sim.economy.WALKINS
	return wi and wi.Cold or nil
end

-- one CareerRules.ColdStep, as Systems/Career.ColdCheck runs it: a step that finds no lastDay saves today for the next
-- one and itself passes none (ColdStep's "lastDay nil changes nothing": never cold on a first read, fix round 1 D); a
-- thaw sets it to today; an entry logs, and its cold_news opens at once on today's phone count (Phone.SendSystem; the
-- sim's tour is done from day 1)
local function coldStep(sim, event)
	local cfg = coldCfg(sim)
	if not cfg then return end
	local last = sim.lastDay
	if last == nil then sim.lastDay = sim.today end
	local before = sim.cold
	local cold, rearm, changed = sim.careerRules.ColdStep(sim.cold, sim.rearm, sim.career.aura, sim.today, last, event, cfg)
	if not changed then return end
	sim.cold, sim.rearm = cold, rearm == true
	if before and not cold then
		sim.lastDay = sim.today
		table.insert(sim.coldLog, { day = sim.today, kind = "thaw", event = event })
	elseif cold and not before then
		table.insert(sim.coldLog, { day = sim.today, kind = "cold", reason = cold.reason })
		if sim.firstCold == nil then sim.firstCold = sim.today end
		local ph = sim.walkins.phone
		sim.rules.Rollover(ph, sim.today)
		ph.today += 1
		ph.count += 1
		cold.news = true
	end
end

local function addStat(sim, stat, n)
	local was = sim.career[stat] or 0
	sim.career[stat] = sim.careerRules.Clamp(stat, was + (n or 0))
	if stat == "followers" then crossTiers(sim) end
	if stat == "aura" and sim.career.aura ~= was then coldStep(sim, "check") end -- after any Aura move (Career.Add / Take)
end

-- a feed table ({ aura = n, followers = n }) from the beat loop
local function feed(sim, f)
	for stat, n in pairs(f or {}) do addStat(sim, stat, n) end
end

local function refreshLevel(sim)
	for i, threshold in ipairs(sim.economy.levels) do
		if sim.xp >= threshold then sim.level = i end
	end
end

-- the career a roll sees: a copy of sim.career with level = sim.level (the server reads prof.level), so a `ready`
-- choice's ChoiceChance has the level. sim.career itself never carries level
local function rollCareer(sim)
	local career = table.clone(sim.career)
	career.level = sim.level
	return career
end

-- the best recent beat's quality (WalkInRules.BeatQuality of BestBeat; 0 with none), and the chance tilt a choice rolls
-- with: BeatTilt on input.odds for a `beat` choice, 0 for any other (Systems/WalkIns.Choose passes the same)
local function beatQ(sim) return sim.rules.BeatQuality(sim.rules.BestBeat(sim.recent)) end
local function tiltFor(sim, choice)
	if not choice.beat then return 0 end
	return sim.rules.BeatTilt(beatQ(sim), sim.input.odds)
end
-- the relationship tilt a choice rolls with (Wave 3, design 4.3; Systems/WalkIns.RelTiltFor, which a walk-in's and a phone
-- pop's choice both roll with): RelTilt of `visitor`'s score (the card's own visitor) on input.odds for a rolled choice; 0
-- for a sure or beatMin choice (neither rolls), a score of 0 (a visitor with no relationship, so a deck without
-- relationships never reads odds.relPer) and no visitor
local function relTiltFor(sim, visitor, choice)
	if visitor == nil or choice.sure or choice.beatMin then return 0 end
	local e = sim.rel[visitor]
	local score = e and e.score or 0
	if score == 0 then return 0 end
	return sim.rules.RelTilt(score, sim.input.odds)
end

-- 3, 2, 3, ... on the named alternation
local function nextStars(sim, key)
	local three = sim[key]
	sim[key] = not three
	return three and 3 or 2
end

-- the recent beats kept: Config.WalkIns.RecentMax, through the economy (economy_fixture.WALKINS; t46 builds it from live
-- Config)
local function recentMax(sim)
	local wi = sim.economy.WALKINS
	local max = wi and wi.RecentMax
	assert(type(max) == "number", "CareerSim: your beat needs economy.WALKINS.RecentMax (Config.WalkIns.RecentMax)")
	return max
end

-- a new beat delivered at `stars` goes to the front of sim.recent (Contracts.RecordDelivery's RecentPush), and like
-- RecordDelivery it is the last delivery's day (lastDay) and a 3-star one thaws ("delivery3")
local function pushBeat(sim, stars)
	sim.beats += 1
	sim.recent = sim.rules.RecentPush(sim.recent, { pattern = "sim" .. sim.beats, bpm = SIM_BPM, stars = stars, fires = 0, day = sim.today },
		recentMax(sim))
	if coldCfg(sim) then
		sim.lastDay = sim.today
		if stars >= 3 then coldStep(sim, "delivery3") end
	end
end

-- one paying delivery: cred and XP (x1.5 at 3 stars); the beat joins sim.recent (the server records it before the
-- delivery feed: Contracts.Deliver's RecordDelivery, then Delivered), then the delivery feed for its stars
local function deliver(sim, cred, xp, stars)
	local mult = stars >= 3 and 1.5 or 1
	earn(sim, round(cred * mult))
	sim.xp += round(xp * mult)
	pushBeat(sim, stars)
	feed(sim, sim.economy.feeds.delivery[stars])
end

local function ownsFeature(sim, feature)
	for _, g in ipairs(sim.economy.gear) do
		if g.feature == feature and sim.owned[g.id] then return true end
	end
	return false
end

local function canTake(sim, request)
	if sim.level < request.level then return false end
	for _, feature in ipairs(request.needs or {}) do
		if not ownsFeature(sim, feature) then return false end
	end
	return true
end

-- day loop steps ------------------------------------------------------------------------------------------------------

-- the daily Aura heal (Config.Career.Sources.AuraHeal), the day's first step: Aura in the red moves at most
-- input.auraHeal toward 0, never past it, by the same CareerRules.HealAmount the server pays through. No draw, and
-- outside pop(), so phoneAura never counts it
local function healAura(sim)
	local n = sim.careerRules.HealAmount(sim.career.aura, sim.input.auraHeal)
	if n > 0 then addStat(sim, "aura", n) end
end

local function gainActivityXP(sim, day)
	local e = sim.economy
	sim.xp += e.activityXP + e.beatSaveXP + (day == 1 and e.tourXP or 0)
	refreshLevel(sim)
end

local function deliverRequests(sim)
	local n = 0
	for i, request in ipairs(sim.economy.requests) do
		if n >= REQUESTS_PER_DAY then return end
		if not sim.done[i] and canTake(sim, request) then
			sim.done[i] = true
			n += 1
			deliver(sim, request.cred, request.xp, nextStars(sim, "requestThree"))
		end
	end
end

-- the dailies, plus the streak bonus on the day the streak reaches 3 or 7 (it rides on a daily delivery)
local function deliverDailies(sim, day)
	local d = sim.economy.daily
	for _ = 1, d.count do deliver(sim, d.cred, d.xp, nextStars(sim, "dailyThree")) end
	local bonus = sim.economy.streakBonus[day]
	if d.count > 0 and bonus then earn(sim, bonus) end
end

-- the weekly single on days 7, 14, ...: always 3 stars, so it also earns the plaque
local function deliverWeekly(sim, day)
	if day % 7 ~= 0 then return end
	local w = sim.economy.weekly
	deliver(sim, w.cred, w.xp, 3)
	feed(sim, sim.economy.feeds.plaque)
end

local function winCypher(sim, day)
	if day % 2 ~= 0 then return end
	earn(sim, sim.economy.cypherWinCred)
	sim.xp += sim.economy.cypherXP
	feed(sim, sim.economy.feeds.cypher)
end

-- the day's FIRE, each on the newest beat, the one on the monitors (Reactions.Give -> Contracts.CreditFire's RecentFire).
-- With no beat delivered yet the aired beat is new to the list, at 0 stars
local function receiveFire(sim)
	if sim.input.persona == "neglect" then return end -- the neglect persona gets no FIRE
	for _ = 1, sim.economy.firePerDay do
		earn(sim, sim.economy.fireCred)
		feed(sim, sim.economy.feeds.fire)
		local newest = sim.recent[1]
		sim.recent = sim.rules.RecentFire(sim.recent, newest and newest.pattern or "sim_aired", newest and newest.bpm or SIM_BPM, sim.today,
			recentMax(sim))
		coldStep(sim, "fire") -- a FIRE to the producer (Reactions.Give)
	end
end

-- buy the cheapest unowned gear you can afford at your level, until nothing fits
local function buyGear(sim)
	refreshLevel(sim)
	while true do
		local best
		for _, g in ipairs(sim.economy.gear) do
			if not sim.owned[g.id] and sim.level >= g.level and sim.career.money >= g.price and (not best or g.price < best.price) then
				best = g
			end
		end
		if not best then return end
		sim.owned[best.id] = true
		sim.career.money -= best.price
	end
end

-- per visit steps (mirrors the WalkIns server system) -----------------------------------------------------------------

-- card XP through the XP gate (DataService's gate for source "Phone", economy.XP_PHONE = Config.XP.Sources.Phone):
-- trimmed to max; once dailyMax awards were paid this sim day it pays 0; an award of 0 is neither paid nor counted.
-- Returns what it paid
local function gateXP(sim, n)
	if n <= 0 then return 0 end
	local rule = sim.economy.XP_PHONE
	assert(type(rule) == "table", "CareerSim: card XP needs economy.XP_PHONE (Config.XP.Sources.Phone)")
	local gained = math.max(0, math.floor(math.min(n, rule.max or n)))
	if rule.dailyMax and sim.xpAwards >= rule.dailyMax then return 0 end
	if gained <= 0 then return 0 end
	sim.xpAwards += 1
	return gained
end

-- apply a Resolve/ResolveNews result for `item` (the card or follow-up it came from). A phone pop (`phone`) never pays:
-- its outcome money is not applied (design 4.8), so money moves only through the choice's cost and nothing reaches the
-- walk-in share. Card XP (deltas.xp, phone outcomes only per the validator) passes the XP gate (gateXP); what it paid
-- adds to sim.xp and cardXP, and the level is refreshed at once, so the rest of the day sees it (the server's AddXP
-- levels up on the spot). The first HIT (hits 0 -> more) plants mom_plaque at {1, 2} when the deck has it (Plant
-- refuses a second while one is queued)
local function apply(sim, res, item, phone)
	local d, o, st = res.deltas, res.outcome, sim.walkins
	local money, gained = sim.rules.ApplyMoney(sim.career.money, d.cost, if phone then 0 else d.money)
	sim.career.money = money
	sim.walkGained += gained
	sim.dayGained += gained
	local hadHit = sim.career.hits > 0
	for _, stat in ipairs(sim.careerRules.STATS) do addStat(sim, stat, d[stat]) end
	local paid = gateXP(sim, d.xp or 0)
	sim.xp += paid
	sim.cardXP += paid
	refreshLevel(sim)
	if o.sponsor == "drop" then
		sim.career.sponsor = nil
	elseif o.sponsor then
		sim.career.sponsor = o.sponsor
		sim.rel.rep = nil -- a new deal is a new relationship (design 4.3): the rep's score and flags start over
	end
	if type(o.rel) == "table" then sim.rules.RelWrite(sim.rel, o.rel, item.visitor, sim.today) end
	if o.plant then sim.rules.Plant(st, o.plant, sim.input.followupAt, sim.rng, { sponsor = item.sponsor }) end
	if not hadHit and sim.career.hits > 0 and sim.deck.followups[PLAQUE] then
		sim.rules.Plant(st, { id = PLAQUE, at = { 1, 2 } }, sim.input.followupAt, sim.rng)
	end
	if o.cooldown then st.last[item.visitor] = (st.last[item.visitor] or st.count) + o.cooldown end
end

-- he arrives: the visit counts, and a capped card counts against its group for the sim day and week; returns the card
-- or follow-up
local function arrive(sim, pick, day)
	local st = sim.walkins
	local item = pick.kind == "card" and pick.card or pick.followup
	local id = pick.kind == "card" and pick.card.id or pick.entry.id
	st.count += 1
	st.today += 1
	st.last[item.visitor] = st.count
	st.seen[id] = (st.seen[id] or 0) + 1
	sim.firstSeen[id] = sim.firstSeen[id] or day
	sim.rules.CountCap(st, item, day, day // 7)
	return item
end

-- a queued sponsor drop (or the rep's warning, Wave 3) that no longer applies: the deal it was planted for has ended (or
-- is unknown), or Aura is back at or above that sponsor's floor (the server's dropStale re-checks the same in nextPick
-- and onArrive)
local function staleDrop(sim, entry)
	if entry.id ~= DROP and entry.id ~= WARNING then return false end
	local planted = entry.ctx and entry.ctx.sponsor
	if planted ~= sim.career.sponsor then return true end
	local floor = planted and sim.deck.sponsors[planted]
	return floor == nil or sim.career.aura >= floor
end

-- a follow-up resolves the old thread first; a stale sponsor drop (or warning) rolls its news but applies nothing. The
-- rep's warning, applied, plants the drop WARNING_DROP_AT walk-ins on for the deal it warned about
local function readNews(sim, pick)
	sim.rules.TakeQueued(sim.walkins, pick.entry)
	local res = sim.rules.ResolveNews(pick.followup, rollCareer(sim), sim.input.odds, sim.rng)
	if staleDrop(sim, pick.entry) then return end
	apply(sim, res, pick.followup)
	if pick.entry.id == WARNING and sim.deck.followups[DROP] then
		local ctx = pick.entry.ctx
		sim.rules.Plant(sim.walkins, { id = DROP, at = WARNING_DROP_AT }, sim.input.followupAt, sim.rng, { sponsor = ctx and ctx.sponsor })
	end
end

local function queued(sim, id)
	for _, q in ipairs(sim.walkins.queue) do if q.id == id then return true end end
	return false
end
-- Aura under the current sponsor's floor queues the drop; with rel.rep's score 1 or more, the rep's warning instead (Wave
-- 3), and neither while one of them waits (the warning's drop is already on its way)
local function checkSponsorFloor(sim)
	local sponsor = sim.career.sponsor
	local floor = sponsor and sim.deck.sponsors[sponsor]
	if not (floor and sim.career.aura < floor) or queued(sim, DROP) or queued(sim, WARNING) then return end
	local rep = sim.rel.rep
	local warn = rep ~= nil and (rep.score or 0) >= 1 and sim.deck.followups[WARNING] ~= nil
	sim.rules.Plant(sim.walkins, { id = warn and WARNING or DROP }, sim.input.dropAt, sim.rng, { sponsor = sponsor })
end

-- the expected money of a choice for the greedy player, everything it leads to included: the rare outcome (rolled
-- first, at rareOdds %), else good at p = the good chance (RollChance, the one rule Resolve rolls at: a beatMin choice by
-- the best beat first, a sure choice certain, otherwise ChoiceChance with the beat tilt, so a `ready` choice is valued at
-- its readiness, and the relationship tilt of `visitor`'s score, the card's own visitor) and bad otherwise,
-- minus the cost. `career` is the roll's career copy (rollCareer: level included), made once per choice and passed down.
-- An outcome is worth its money plus, when it plants a follow-up, that follow-up's news at its own chance and the best
-- of its choices affordable now (none = walking away, $0), recursively. PLANT_DEPTH bounds the recursion (the content's
-- plant graph is acyclic and at most 2 deep, walkins_data_spec; a fixture deck might not be)
local PLANT_DEPTH = 4
local expectedMoney

local function affordableChoices(sim, item)
	local affordable = {}
	for _, c in ipairs(item.choices or {}) do
		if (c.cost or 0) <= sim.career.money then table.insert(affordable, c) end
	end
	return affordable
end

local function outcomeMoney(sim, o, career, depth)
	local value = o.money or 0
	local f = o.plant and depth < PLANT_DEPTH and sim.deck.followups[o.plant.id]
	if not f then return value end
	local r = f.resolve
	local p = sim.rules.Chance(r.odds, career, sim.input.odds) / 100
	value += p * outcomeMoney(sim, r.good, career, depth + 1) + (1 - p) * outcomeMoney(sim, r.bad, career, depth + 1)
	local best
	for _, c in ipairs(affordableChoices(sim, f)) do
		local v = expectedMoney(sim, c, career, depth + 1, f.visitor)
		if not best or v > best then best = v end
	end
	return value + (best or 0)
end

function expectedMoney(sim, choice, career, depth, visitor)
	depth = depth or 0
	local tilt = tiltFor(sim, choice) + relTiltFor(sim, visitor, choice)
	local p = sim.rules.RollChance(choice, career, sim.input.odds, tilt, beatQ(sim)) / 100
	local value = p * outcomeMoney(sim, choice.good, career, depth) + (1 - p) * outcomeMoney(sim, choice.bad or choice.good, career, depth)
	if choice.rare then
		local q = (choice.rareOdds or 0) / 100
		value = q * outcomeMoney(sim, choice.rare, career, depth) + (1 - q) * value
	end
	return value - (choice.cost or 0)
end

-- the career chaser's thread: a choice whose good outcome gives a placement or plants a follow-up
local function careerThread(choice)
	return (choice.good.placements or 0) > 0 or choice.good.plant ~= nil
end

-- the choice the policy takes among the affordable ones; nil = walk away (none affordable, or news only).
-- random: uniform; greedy: the most expected money (first on ties); chaser: the first career thread, else random.
-- input.prefer = { [cardId] = choiceIndex } pins the random policy (not greedy or chaser) to that choice of that card,
-- with no draw, whenever it is affordable, and counts the pick in sim.pinned; otherwise the random policy draws as usual.
-- Greedy values a walk-in's and a phone pop's choices alike, with the item's visitor's relationship tilt
local function chooseByPolicy(sim, item)
	local affordable = affordableChoices(sim, item)
	if #affordable == 0 then return nil end
	local policy = sim.input.policy
	if policy == "greedy" then
		local career = rollCareer(sim)
		local best, bestValue
		for _, c in ipairs(affordable) do
			local value = expectedMoney(sim, c, career, 0, item.visitor)
			if not best or value > bestValue then best, bestValue = c, value end
		end
		return best
	end
	if policy == "chaser" then
		for _, c in ipairs(affordable) do
			if careerThread(c) then return c end
		end
	else
		local index = sim.input.prefer and sim.input.prefer[item.id]
		local pinned = index and item.choices and item.choices[index]
		if pinned and (pinned.cost or 0) <= sim.career.money then
			sim.pinned += 1
			return pinned
		end
	end
	return affordable[sim.rng(1, #affordable)]
end

-- a choice rolls with its beat tilt plus its card's relationship tilt (a walk-in's or a phone pop's, fix round 1 D), and
-- the best beat's quality (Resolve's tilt and beatQ); a `beat` choice's roll is counted with its beat tilt (beatRolls,
-- beatTilt), a roll the relationship tilted with that tilt (relRolls, relTilt). `phone`: the outcome's money is not paid
local function resolveChoice(sim, item, choice, phone)
	local beat = tiltFor(sim, choice)
	local rel = relTiltFor(sim, item.visitor, choice)
	local res = sim.rules.Resolve(choice, rollCareer(sim), sim.input.odds, sim.rng, beat + rel, beatQ(sim))
	if not res.ok then return end
	if choice.beat then
		sim.beatRolls += 1
		sim.beatTilt += beat
	end
	if rel ~= 0 then
		sim.relRolls += 1
		sim.relTilt += rel
	end
	apply(sim, res, item, phone)
end

-- the next visit (source "walkin") or phone pop (source "phone") on sim.rng (the phone stream during a pop): the Pick
-- opts the server passes too (Shared shapes), so the life gates, the caps, aired and the first card hold in the sim.
-- career is a copy of the career with visits = the walk-in count; day and week are the sim day and day // 7; a day with
-- FIRE has aired a beat (receiveFire runs before any visit or pop); rel = sim.rel (the relationship gates). Seed first, so
-- a newly eligible card, or one back from a closed gate, joins the least-seen rotation instead of winning the next draws
-- back to back
local function pickNext(sim, source, day)
	local career = table.clone(sim.career)
	career.visits = sim.walkins.count
	local opts = { cooldown = sim.input.cooldown, rng = sim.rng, sponsored = sim.career.sponsor ~= nil, aura = sim.career.aura,
		source = source, career = career, day = day, week = day // 7, aired = sim.economy.firePerDay > 0, rel = sim.rel }
	sim.rules.Seed(sim.walkins, sim.deck, opts)
	return sim.rules.Pick(sim.walkins, sim.deck, opts)
end

local function visit(sim, day)
	if sim.input.spendDown then sim.career.money = 0 end
	local pick = pickNext(sim, "walkin", day)
	-- a stale sponsor drop leaves the queue unvisited and the visit picks again (nextPick on the server)
	if pick and pick.kind == "followup" and staleDrop(sim, pick.entry) then
		sim.rules.TakeQueued(sim.walkins, pick.entry)
		pick = pickNext(sim, "walkin", day)
	end
	if not pick then return end
	local item = arrive(sim, pick, day)
	if pick.kind == "followup" then readNews(sim, pick) end
	checkSponsorFloor(sim)
	local choice = chooseByPolicy(sim, item)
	if choice then resolveChoice(sim, item, choice) end
end

-- the walk-in cap now: walkinsPerDay, or Cold.dailyMax (never more) while cold (WalkIns.DailyMaxFor)
local function dailyMax(sim)
	local cfg = coldCfg(sim)
	if sim.cold and cfg then return math.min(cfg.dailyMax, sim.input.walkinsPerDay) end
	return sim.input.walkinsPerDay
end

local function runVisits(sim, day)
	for _ = 1, sim.input.walkinsPerDay do
		if not sim.rules.CanSchedule(sim.walkins, day, dailyMax(sim)) then return end
		visit(sim, day)
	end
end

-- per pop steps (mirrors Systems/Phone: send, then the first open, then the choice; Shared shapes "Phone rules") ------

-- the pop opens: counted on the phone's counters (never walkins.count or today), plus seen and the group cap
local function openPop(sim, pick, item, day)
	local st = sim.walkins
	st.phone.today += 1
	st.phone.count += 1
	local id = pick.kind == "card" and pick.card.id or pick.entry.id
	st.seen[id] = (st.seen[id] or 0) + 1
	sim.firstSeen[id] = sim.firstSeen[id] or day
	sim.rules.CountCap(st, item, day, day // 7)
end

-- one pop on sim.rng; false when nothing is eligible. The send marks an artist sender's cooldown (MarkSent). A due phone
-- follow-up (it wins over cards) comes off the queue first: nil means already taken, so the pop is dropped with nothing
-- counted or applied; otherwise its news is rolled and applied. A NEWS card resolves its one sure choice, with no policy
-- draw; a DM takes the policy's choice. No sponsor-floor check (the server checks it only when a walk-in arrives). The
-- Aura the pop applied, after the clamp, adds to phoneAura
local function pop(sim, day)
	local st = sim.walkins
	local pick = pickNext(sim, "phone", day)
	if not pick then return false end
	local item = pick.kind == "card" and pick.card or pick.followup
	sim.rules.MarkSent(st, item, sim.deck)
	if pick.kind == "followup" and not sim.rules.TakeQueued(st, pick.entry) then return true end
	openPop(sim, pick, item, day)
	local aura = sim.career.aura
	if pick.kind == "followup" then
		apply(sim, sim.rules.ResolveNews(item, rollCareer(sim), sim.input.odds, sim.rng), item, true)
	elseif item.news then
		resolveChoice(sim, item, item.choices[1], true)
	else
		local choice = chooseByPolicy(sim, item)
		if choice then resolveChoice(sim, item, choice, true) end
	end
	sim.phoneAura += sim.career.aura - aura
	return true
end

-- after the day's visits, up to phonePerDay pops while the send gate holds (nothing waits unopened in the sim, so it is
-- CanSchedule on walkins.phone). Each whole pop draws from the phone stream: sim.rng is swapped for it and put back
local function runPhone(sim, day)
	local max = sim.input.phonePerDay
	for _ = 1, max do
		if sim.cold then return end -- no pop while cold (Phone.canSend)
		if not sim.rules.CanSchedule(sim.walkins.phone, day, max) then return end
		local main = sim.rng
		sim.rng = sim.phoneRng
		local more = pop(sim, day)
		sim.rng = main
		if not more then return end
	end
end

-- end of the day ------------------------------------------------------------------------------------------------------

-- spend a gate's cost the first day its check passes (and its level, when it has one); true when it unlocked
local function tryUnlock(sim, gate)
	if not gate or sim.level < (gate.level or 1) then return false end
	if not sim.careerRules.Check(sim.career, gate.needs, gate.cost).ok then return false end
	sim.career.money -= gate.cost or 0
	return true
end

local function unlockGates(sim, day)
	local gates = sim.input.gates or {}
	if not sim.studioTwoDay and tryUnlock(sim, gates.studio_two) then sim.studioTwoDay = day end
	if not sim.legendDay and tryUnlock(sim, gates.plate_legend) then sim.legendDay = day end
end

-- the walk-in share of the day's gained money (positive amounts only)
local function recordShares(sim, day)
	sim.shares[day] = sim.dayGained > 0 and sim.walkGained / sim.dayGained or 0
	if day >= STEADY_FROM then
		sim.steadyAll += sim.dayGained
		sim.steadyWalk += sim.walkGained
	end
end

-- does the player deliver today? everyone does, except the neglect persona after day 1 and before input.resumeDay
local function delivers(sim, day)
	if sim.input.persona ~= "neglect" or day == 1 then return true end
	return sim.input.resumeDay ~= nil and day >= sim.input.resumeDay
end

local function runDay(sim, day)
	sim.today = day
	sim.dayGained, sim.walkGained = 0, 0
	sim.xpAwards = 0 -- the XP gate's count starts again each sim day (the server's UTC day)
	coldStep(sim, "check") -- the career day's step (Life.Tick)
	healAura(sim)
	gainActivityXP(sim, day)
	if delivers(sim, day) then
		deliverRequests(sim)
		deliverDailies(sim, day)
		deliverWeekly(sim, day)
	end
	winCypher(sim, day)
	receiveFire(sim)
	buyGear(sim)
	runVisits(sim, day)
	runPhone(sim, day)
	unlockGates(sim, day)
	recordShares(sim, day)
	if sim.cold then sim.coldDays[day] = true end
end

-- run `input.days` days; day numbers are nil when the gate never unlocks. input.phonePerDay is required (0 = no phone),
-- and input.phoneSeed with it whenever it is above 0. input.auraHeal is required (0 = no heal). input.prefer (optional,
-- { [cardId] = choiceIndex }) pins the random policy's choice on those cards. input.tiers and input.tierVisits (optional,
-- crossTiers) track the fame tiers. phonePops = pops opened; phoneAura = the
-- net Aura they applied; cardXP = the card XP the XP gate paid (deltas.xp, trimmed and counted); pinned = the picks input.prefer made (0 when the
-- pin never applied: a missing card or choice, or one never affordable); tierDays = { [tierId] = the day it was first
-- reached }, LOCAL never in it, empty without input.tiers. Your beat: recent = the recent beats at the end (newest first,
-- { pattern, bpm, stars, fires, day }), beatRolls = the `beat` choices rolled, beatTilt = the sum of their tilt.
-- economy.WALKINS.RecentMax is required once a beat is delivered or fired. The cold spell (economy.WALKINS.Cold): coldDays =
-- { [day] = true } for each day that ended cold, coldLog = every entry and exit in order ({ day, kind = "cold", reason } |
-- { day, kind = "thaw", event }), firstCold = the first day it went cold (nil: never). They remember you: rel = the
-- relationships at the end ({ [visitorId] = { score, flags = { [flag] = day } } }), firstSeen = { [cardOrFollowupId] =
-- the first day it came (a walk-in or an opened pop) }, relRolls = the rolls a relationship tilted, relTilt = their sum.
-- input.odds.relPer is required once a choice rolls with a non-zero score
function M.Run(input)
	assert(type(input.phonePerDay) == "number", "CareerSim.Run: input.phonePerDay must be a number (0 = no phone pops)")
	assert(input.phonePerDay <= 0 or type(input.phoneSeed) == "number",
		"CareerSim.Run: input.phoneSeed must be a number when phonePerDay > 0")
	assert(type(input.auraHeal) == "number", "CareerSim.Run: input.auraHeal must be a number (0 = no heal)")
	local sim = newSim(input)
	for day = 1, input.days do runDay(sim, day) end
	return {
		studioTwoDay = sim.studioTwoDay, legendDay = sim.legendDay, shares = sim.shares,
		steadyShare = sim.steadyAll > 0 and sim.steadyWalk / sim.steadyAll or 0,
		placements = sim.career.placements, hits = sim.career.hits,
		phonePops = sim.walkins.phone.count, phoneAura = sim.phoneAura, cardXP = sim.cardXP, pinned = sim.pinned,
		tierDays = sim.tierDays, recent = sim.recent, beatRolls = sim.beatRolls, beatTilt = sim.beatTilt,
		coldDays = sim.coldDays, coldLog = sim.coldLog, firstCold = sim.firstCold,
		rel = sim.rel, firstSeen = sim.firstSeen, relRolls = sim.relRolls, relTilt = sim.relTilt,
	}
end

return M
