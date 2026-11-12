-- CLI pacing check (design §4.8): the real walk-in deck (Data/WalkIns.Deck) run through CareerSim against the economy
-- fixture, 60 days a seed, for six players: random choices, greedy (most expected money, counting what planted
-- follow-ups and rare outcomes pay), the career chaser (any choice that gives a placement or plants a follow-up, else
-- random), random with every dollar spent before each visit, and two random players pinned on the two-sessions card
-- (input.prefer): "homer" always takes the hometown kid (choice 1) and "climber" always the one-hit wonder (choice 2).
-- Up to 6 phone pops a day run on their own rng stream (phoneSeed = the seed); once the deck has a phone card, the
-- random player must open some (> 0 a day) and gain at most +15 net phone Aura a day. Each day starts by healing Aura
-- in the red up to 5 toward 0 (auraHeal, Config.Career.Sources.AuraHeal's max).
-- The fame tiers come from the fixture's LIFE (Config.Life): a tier's first crossing plants its visit (A13), and each seed
-- set prints the random player's median and p90 day per tier. The money guardrails see mainly ICON's visit: steadyShare
-- starts on day 8, and the three lower tiers cross in the first week.
-- Every guardrail runs on two seed sets with the same asserts: CareerSim.Seeds (20) and the recorded 200-seed set
-- SEEDS_200. The money floor (the user's call, 2026-10-29) is checked on the 200 seeds only: the random median steady
-- share >= BASELINE_SHARE_200 - 0.005, BASELINE_SHARE_200 being today's deck before the two-sessions card
-- (research/two_sessions/baseline_2026-10-29.md). build/t46_check.lua runs the 20-seed assertions in Studio, without
-- the floor (200 seeds would outrun Studio's call limit).
-- Your beat (Wave 3, design 4.1): the sim rolls the deck's `beat` choices with the beat tilt (CareerSim's recent beats);
-- every random run must roll some, and each seed set prints each policy's mean tilt a roll (the tuning aims it near 0).
-- The cold spell (Wave 3, design 4.2; the sim runs CareerRules.ColdStep on the fixture's WALKINS.Cold): random, greedy,
-- the career chaser and spend-down never go cold in days 1-7 on either seed set (design anti-goal: a regular player cold
-- in their first career week), and the `neglect` persona (delivers on day 1, then nothing until resumeDay 6, no FIRE) is
-- cold on day 4 and 5 on every seed (it goes cold on day 4 at the latest: "quiet", or earlier by Aura) and thaws on its
-- day-6 3-star delivery, with nothing ending the spell before it, and is warm at the end of day 6.
-- They remember you (Wave 3, design 4.3; CareerSim keeps the relationships through the same pure rules): the 18 arc
-- entries are in the deck (ARCS). Each seed set prints, for the random player, how many runs each one reached and its
-- median first day among them, homer's runs to homekid_album (two hometown picks and a tape that blew up), and the mean
-- relationship tilt a rolled choice took (walk-in or phone). On the 200 seeds every arc entry is reached by some random
-- or homer run (no gate the deck can't open), except sponsor_warning: it stands in for a sponsor_drop, which itself comes
-- on only a few runs (a player holding a deal rarely falls under its floor; printed beside it), so career_sim_spec and
-- t79a prove it instead. The old mom cards, gated only on her silence, still come on most random runs.
-- Run: sh tools/spec.sh pacing
local Sim = require("../src/ReplicatedStorage/OK/Modules/CareerSim")
local R = require("../src/ReplicatedStorage/OK/Modules/WalkInRules")
local CR = require("../src/ReplicatedStorage/OK/Modules/CareerRules")
local W = require("../src/ReplicatedStorage/OK/Data/WalkIns")
local E = require("./economy_fixture")

local fails = {}
local function ok(name, cond) if not cond then table.insert(fails, name) end end

-- ready = Config.WalkIns.Odds.ready (the fixture's READY): the sim passes ODDS to Resolve and ChoiceChance. beatCenter,
-- beatPer and relPer are Config.WalkIns.Odds' too: the same numbers live in Config, economy_fixture's WALKINS.Odds,
-- build/t46_check.lua (FIXTURE.WALKINS.Odds and PACING.odds) and here, and t46 pins live Config against them
local ODDS = { auraPer = 20, auraCap = 15, followersPer = 1000, followersCap = 10, min = 10, max = 90,
	beatCenter = 3, beatPer = 3, relPer = 4, ready = E.READY }
-- the 18 arc entries (copy doc section 2: 15 walk-in cards, 3 follow-ups), and the mom cards that were already here
local ARCS = { "rival_collab", "rival_war", "rival_truce", "mom_aunt", "mom_quiet", "mom_return", "homekid_show",
	"homekid_album", "homekid_forgot", "navx_tour", "navx_tv", "navx_replaced", "sponsor_duty", "sponsor_renew",
	"sponsor_warning", "blogger_exclusive", "blogger_expose", "blogger_expose_bounce" }
local OLD_MOM = { "mom_food", "mom_placement", "mom_busy" }
local RARE = { sponsor_warning = true } -- reached only through a rare sponsor_drop (see the header): not asserted
local CONTEXT = { "sponsor_drop" } -- printed beside the arcs, never asserted
for _, id in ipairs(ARCS) do assert(W.CardById[id] or W.FollowupById[id], "pacing: arc entry " .. id .. " is not in the deck") end
for _, k in ipairs({ "beatCenter", "beatPer", "relPer" }) do
	assert(ODDS[k] == E.WALKINS.Odds[k], string.format("pacing ODDS.%s is %s, economy_fixture WALKINS.Odds.%s is %s: keep the four copies equal",
		k, tostring(ODDS[k]), k, tostring(E.WALKINS.Odds[k])))
end
local GATES = {
	studio_two = { needs = { placements = 1, aura = 300 }, cost = 5000 },
	plate_legend = { needs = { hits = 1, followers = 20000, aura = 1000 }, cost = 4000, level = 10 },
}
-- the recorded 200-seed set, and the random median steady share today's deck (before two_sessions) makes on it:
-- Task 0's measurement (research/two_sessions/baseline_2026-10-29.md, 0.346158), pinned. The floor is 0.005 under it
local SEEDS_200 = {}
for i = 0, 199 do SEEDS_200[i + 1] = 100000 + 7919 * i end
local BASELINE_SHARE_200 = 0.3462
local FLOOR_200 = BASELINE_SHARE_200 - 0.005
-- the two-sessions card's choices: 1 = the hometown kid, 2 = the one-hit wonder
local HOMER = { two_sessions = 1 }
local CLIMBER = { two_sessions = 2 }
-- the pins mean "the kid" and "the one-hit wonder" only while choice 1 is the sure one and choice 2 the ready one: a
-- reorder fails here (the pin-fired asserts below can't see one)
local TWO = W.CardById.two_sessions
assert(TWO and TWO.choices[1].sure == true and TWO.choices[2].ready == true,
	"two_sessions: choice 1 must be sure (the hometown kid) and choice 2 ready (the one-hit wonder) for HOMER and CLIMBER")

local DAYS = 60
local function run(seed, policy, spendDown, prefer, persona, resumeDay)
	return Sim.Run({ days = DAYS, economy = E, deck = W.Deck, rules = R, careerRules = CR, odds = ODDS, followupAt = { 2, 4 },
		dropAt = { 1, 1 }, cooldown = 3, walkinsPerDay = 8, phonePerDay = 6, phoneSeed = seed, auraHeal = 5, rng = Sim.Lcg(seed),
		policy = policy, spendDown = spendDown, prefer = prefer, gates = GATES, tiers = E.LIFE.Tiers, tierVisits = E.LIFE.TierVisits,
		persona = persona, resumeDay = resumeDay })
end
-- the cold spell's checks need the fixture's Cold (Config.WalkIns.Cold): without it the sim models no cold at all
assert(type(E.WALKINS.Cold) == "table" and E.WALKINS.Cold.quietDays == 3, "economy_fixture WALKINS.Cold missing: the cold checks would pass vacuously")
local NEGLECT_RESUME = 6
-- the phone checks apply once the deck has a phone card
local hasPhone = false
for _, card in ipairs(W.Deck.cards) do if card.source == "phone" then hasPhone = true end end

-- Order statistics over the seeds, fixed before tuning (t46 copies these verbatim). A nil day (never unlocked) counts as
-- +infinity. Values are sorted ascending; n = #values (20 or 200 seeds).
--   median = mean of the two middle values when n is even (the 10th and 11th of 20, the 100th and 101st of 200), the
--            middle one when odd; an infinite middle value makes the median infinite
--   percentile k = nearest rank: the value at position ceil(k / 100 * n) (p10 = 2nd of 20 / 20th of 200, p90 = 18th of
--            20 / 180th of 200)
local function sorted(values)
	local s = {}
	for i, v in ipairs(values) do s[i] = v end
	table.sort(s)
	return s
end
local function median(values)
	local s, n = sorted(values), #values
	if n % 2 == 1 then return s[(n + 1) // 2] end
	return (s[n // 2] + s[n // 2 + 1]) / 2
end
local function percentile(values, k)
	local s = sorted(values)
	return s[math.max(1, math.ceil(k / 100 * #s))]
end
local function dayOrInf(d) return d or math.huge end
local function fmt(x) return x == math.huge and "never" or string.format("%g", x) end

-- every guardrail on one seed set, each failure named with `tag`; returns the summary line, the random median share and
-- the tier-day line.
-- random: THE HALL (Studio Two) median day 4..6, p10 >= 3, p90 <= 7; Legend nil or >= day 15 on every seed; steady
-- share <= 0.50 on every seed and median <= 0.50 (the floor is the 200-seed check below). Phone: pops a day > 0 and
-- net phone Aura a day <= +15 (design 4.8 / Global "Phone Aura budget"), each the mean over seeds. greedy, the career
-- chaser, spend-down, homer and climber: steady share <= 0.50 on every seed. homer: Legend nil or >= day 15 on every
-- seed. climber: THE HALL median day 4..6 and p90 <= 7, and net phone Aura a day <= +15 (the mean over seeds). homer and climber: the pin fired (Run's pinned > 0) on every
-- seed, so a renamed id or an unaffordable choice can't make them silently equal random (a reorder still fires the
-- pin; the sure/ready assert next to HOMER and CLIMBER catches that)
local function check(seeds, tag)
	local function name(s) return "[" .. tag .. "] " .. s end
	local function ceiling(label, seed, res)
		ok(name(string.format("%s seed %d: steady share %.3f <= 0.50", label, seed, res.steadyShare)), res.steadyShare <= 0.50)
	end
	-- the cold spell: never in days 1-7 for a regular player; colds[label] = the runs cold at any point in the 60 days
	local colds = {}
	local function warmWeek(label, seed, res)
		ok(name(string.format("%s seed %d: never cold in days 1-7 (first cold day %s)", label, seed, tostring(res.firstCold))),
			res.firstCold == nil or res.firstCold > 7)
		colds[label] = (colds[label] or 0) + (res.firstCold and 1 or 0)
	end

	local twoDays, shares, legendMin, popsPerDay, auraPerDay = {}, {}, math.huge, 0, 0
	local tierDays = {}
	-- Wave 3 (design 4.1): the beat tilt is on. tilts[policy] = { rolls, sum } over the seeds: the beat choices each
	-- policy rolled and the tilt they rolled with (printed as the mean tilt a roll; the tuning aims it near 0)
	local tilts = {}
	local function addTilt(policy, res)
		local t = tilts[policy] or { rolls = 0, sum = 0 }
		tilts[policy] = t
		t.rolls += res.beatRolls or 0
		t.sum += res.beatTilt or 0
	end
	local function meanTilt(policy)
		local t = tilts[policy]
		return (t and t.rolls > 0) and t.sum / t.rolls or 0
	end
	-- the arcs (Wave 3): arcRuns[id] = random runs that reached it, arcDays[id] = their first days; the rel tilt's rolls
	local arcRuns, arcDays, relRolls, relSum = {}, {}, 0, 0
	local function addArcs(res, list)
		for _, id in ipairs(list) do
			local d = res.firstSeen and res.firstSeen[id]
			if d then
				arcRuns[id] = (arcRuns[id] or 0) + 1
				arcDays[id] = arcDays[id] or {}
				table.insert(arcDays[id], d)
			end
		end
	end
	for _, seed in ipairs(seeds) do
		local res = run(seed, "random")
		addTilt("random", res)
		addArcs(res, ARCS)
		addArcs(res, OLD_MOM)
		addArcs(res, CONTEXT)
		relRolls += res.relRolls or 0
		relSum += res.relTilt or 0
		ok(name(string.format("random seed %d: the beat choices rolled with the beat tilt (beatRolls %s > 0)", seed, tostring(res.beatRolls))),
			(res.beatRolls or 0) > 0)
		for _, t in ipairs(E.LIFE.Tiers) do
			if t.id ~= "LOCAL" then
				tierDays[t.id] = tierDays[t.id] or {}
				table.insert(tierDays[t.id], dayOrInf(res.tierDays[t.id]))
			end
		end
		table.insert(twoDays, dayOrInf(res.studioTwoDay))
		table.insert(shares, res.steadyShare)
		legendMin = math.min(legendMin, dayOrInf(res.legendDay))
		popsPerDay += res.phonePops / DAYS / #seeds
		auraPerDay += res.phoneAura / DAYS / #seeds
		ok(name(string.format("random seed %d: legend day %s >= 15", seed, fmt(dayOrInf(res.legendDay)))), res.legendDay == nil or res.legendDay >= 15)
		ceiling("random", seed, res)
		warmWeek("random", seed, res)
	end
	local twoMedian, twoP10, twoP90 = median(twoDays), percentile(twoDays, 10), percentile(twoDays, 90)
	ok(name("random: Studio Two median day " .. fmt(twoMedian) .. " in 4..6"), twoMedian >= 4 and twoMedian <= 6)
	ok(name("random: Studio Two 10th percentile day " .. fmt(twoP10) .. " >= 3"), twoP10 >= 3)
	ok(name("random: Studio Two 90th percentile day " .. fmt(twoP90) .. " <= 7"), twoP90 <= 7)
	local shareMedian = median(shares)
	ok(name(string.format("random: steady share median %.3f <= 0.50", shareMedian)), shareMedian <= 0.50)
	if hasPhone then
		ok(name(string.format("random: phone pops per day %.2f > 0", popsPerDay)), popsPerDay > 0)
		ok(name(string.format("random: phone Aura per day %.2f <= 15", auraPerDay)), auraPerDay <= 15)
	end

	-- greedy (always the most expected money, follow-ups and rare outcomes included), the career chaser (every
	-- placement and every planted thread it can afford, else random) and spend-down (random, broke at every visit, so
	-- only free choices): still at most half the money
	local greedyMax, chaserMax, spendMax = 0, 0, 0
	for _, seed in ipairs(seeds) do
		local res = run(seed, "greedy")
		addTilt("greedy", res)
		greedyMax = math.max(greedyMax, res.steadyShare)
		ceiling("greedy", seed, res)
		warmWeek("greedy", seed, res)
	end
	for _, seed in ipairs(seeds) do
		local res = run(seed, "chaser")
		addTilt("chaser", res)
		chaserMax = math.max(chaserMax, res.steadyShare)
		ceiling("chaser", seed, res)
		warmWeek("chaser", seed, res)
	end
	for _, seed in ipairs(seeds) do
		local res = run(seed, "random", true)
		addTilt("spend-down", res)
		spendMax = math.max(spendMax, res.steadyShare)
		ceiling("spend-down", seed, res)
		warmWeek("spend-down", seed, res)
	end

	-- homer (random, always the hometown kid): Legend never before day 15, and at most half the money
	local homerLegend, homerMax, homerPinned, homerAlbum = math.huge, 0, 0, 0
	for _, seed in ipairs(seeds) do
		local res = run(seed, "random", nil, HOMER)
		addTilt("homer", res)
		if res.firstSeen and res.firstSeen.homekid_album then homerAlbum += 1 end
		homerPinned += res.pinned
		ok(name(string.format("homer seed %d: the pin fired (pinned %d > 0)", seed, res.pinned)), res.pinned > 0)
		homerLegend = math.min(homerLegend, dayOrInf(res.legendDay))
		homerMax = math.max(homerMax, res.steadyShare)
		ok(name(string.format("homer seed %d: legend day %s >= 15", seed, fmt(dayOrInf(res.legendDay)))), res.legendDay == nil or res.legendDay >= 15)
		ceiling("homer", seed, res)
	end

	-- climber (random, always the one-hit wonder): THE HALL on time, and at most half the money
	local climbDays, climberMax, climberPinned, climberAura = {}, 0, 0, 0
	for _, seed in ipairs(seeds) do
		local res = run(seed, "random", nil, CLIMBER)
		addTilt("climber", res)
		climberPinned += res.pinned
		climberAura += res.phoneAura / DAYS / #seeds
		ok(name(string.format("climber seed %d: the pin fired (pinned %d > 0)", seed, res.pinned)), res.pinned > 0)
		table.insert(climbDays, dayOrInf(res.studioTwoDay))
		climberMax = math.max(climberMax, res.steadyShare)
		ceiling("climber", seed, res)
	end
	-- neglect (random choices; delivers on day 1, then nothing until day NEGLECT_RESUME; no FIRE): cold on days 4 and 5,
	-- cold by day 4 at the latest, nothing ends the spell before day 6, and the day-6 3-star delivery thaws it
	local neglectQuiet4, neglectEarly, neglectRechill = 0, 0, 0
	for _, seed in ipairs(seeds) do
		local res = run(seed, "random", nil, nil, "neglect", NEGLECT_RESUME)
		local function nm(s) return name(string.format("neglect seed %d: %s", seed, s)) end
		ok(nm("cold at the end of day 4"), res.coldDays[4] == true)
		ok(nm("cold at the end of day 5"), res.coldDays[5] == true)
		ok(nm(string.format("cold by day 4 at the latest (first cold day %s)", tostring(res.firstCold))), res.firstCold ~= nil and res.firstCold <= 4)
		local thaw, early
		for _, e in ipairs(res.coldLog) do
			if e.kind == "thaw" and not thaw then thaw = e end
		end
		if thaw and thaw.day < NEGLECT_RESUME then early = thaw end
		ok(nm("nothing ends the spell before day " .. NEGLECT_RESUME .. (early and (" (a " .. tostring(early.event) .. " thaw on day " .. early.day .. ")") or "")), early == nil)
		ok(nm("the first thaw is the day-" .. NEGLECT_RESUME .. " 3-star delivery (got " .. (thaw and (tostring(thaw.event) .. " on day " .. thaw.day) or "none") .. ")"),
			thaw ~= nil and thaw.day == NEGLECT_RESUME and thaw.event == "delivery3")
		local first = res.coldLog[1]
		if first and first.day == 4 and first.reason == "quiet" then neglectQuiet4 += 1 end
		if res.firstCold and res.firstCold < 4 then neglectEarly += 1 end
		-- warm after its day-6 3-star delivery: not cold again by the end of that day (fix round 1, F10)
		ok(nm("warm at the end of day " .. NEGLECT_RESUME), not res.coldDays[NEGLECT_RESUME])
		if res.coldDays[NEGLECT_RESUME] then neglectRechill += 1 end
	end

	local climbMedian, climbP90 = median(climbDays), percentile(climbDays, 90)
	ok(name("climber: Studio Two median day " .. fmt(climbMedian) .. " in 4..6"), climbMedian >= 4 and climbMedian <= 6)
	ok(name("climber: Studio Two 90th percentile day " .. fmt(climbP90) .. " <= 7"), climbP90 <= 7)
	-- the one-hit wonder every time is the most Aura the card gives: the phone Aura budget holds for him too
	ok(name(string.format("climber: phone Aura per day %.2f <= 15", climberAura)), climberAura <= 15)

	local line = string.format("pacing%s: Studio Two median day %s (p10 %s, p90 %s); random share median %.3f; greedy max %.3f; chaser max %.3f; "
		.. "spend-down max %.3f; legend earliest day %s; phone pops/day %.2f; phone aura/day %.2f; homer legend earliest day %s (max %.3f); "
		.. "climber Studio Two median day %s (p90 %s, max %.3f, phone aura/day %.2f); pinned picks/run homer %.2f, climber %.2f; "
		.. "beat tilt/roll (center %g, per %g) random %.2f, greedy %.2f, chaser %.2f, spend-down %.2f, homer %.2f, climber %.2f; beat rolls/run random %.2f",
		tag == "20 seeds" and "" or " " .. tag, fmt(twoMedian), fmt(twoP10), fmt(twoP90), shareMedian, greedyMax, chaserMax, spendMax,
		fmt(legendMin), popsPerDay, auraPerDay, fmt(homerLegend), homerMax, fmt(climbMedian), fmt(climbP90), climberMax, climberAura,
		homerPinned / #seeds, climberPinned / #seeds, ODDS.beatCenter, ODDS.beatPer, meanTilt("random"), meanTilt("greedy"),
		meanTilt("chaser"), meanTilt("spend-down"), meanTilt("homer"), meanTilt("climber"), (tilts.random and tilts.random.rolls or 0) / #seeds)
	-- the random player's tier days: every tier reached inside the 60 days, so a sim that lost its tier input fails here
	local tierParts = {}
	for _, t in ipairs(E.LIFE.Tiers) do
		local days = tierDays[t.id]
		if days then
			ok(name("random: " .. t.id .. " median day " .. fmt(median(days)) .. " reached"), median(days) < math.huge)
			table.insert(tierParts, string.format("%s %s (p90 %s)", t.id, fmt(median(days)), fmt(percentile(days, 90))))
		end
	end
	line = line .. string.format("; cold in 60 days (runs) random %d, greedy %d, chaser %d, spend-down %d; neglect: quiet on day 4 %d/%d, cold earlier by Aura %d, cold again at the end of day %d %d",
		colds.random or 0, colds.greedy or 0, colds.chaser or 0, colds["spend-down"] or 0, neglectQuiet4, #seeds, neglectEarly, NEGLECT_RESUME, neglectRechill)
	-- the arcs: random runs reaching each entry (median first day), homer's album runs, the rel tilt a rolled choice took
	local arcParts = {}
	for _, list in ipairs({ ARCS, OLD_MOM, CONTEXT }) do
		for _, id in ipairs(list) do
			local n = arcRuns[id] or 0
			table.insert(arcParts, string.format("%s %d/%d%s", id, n, #seeds, n > 0 and (" d" .. fmt(median(arcDays[id]))) or ""))
		end
	end
	local arcLine = string.format("arcs %s, random runs reaching each (median first day): %s; homer runs to homekid_album %d/%d; rel tilt/roll (per %g) random %.2f over %.1f rolls/run",
		tag, table.concat(arcParts, ", "), homerAlbum, #seeds, ODDS.relPer, relRolls > 0 and relSum / relRolls or 0, relRolls / #seeds)
	if tag == "200 seeds" then
		for _, id in ipairs(ARCS) do
			if not RARE[id] then
				ok(name(string.format("arc %s is reached by some random or homer run (random %d)", id, arcRuns[id] or 0)),
					(arcRuns[id] or 0) > 0 or (id == "homekid_album" and homerAlbum > 0))
			end
		end
		for _, id in ipairs(OLD_MOM) do
			ok(name(string.format("old mom card %s still comes on most random runs (%d of %d)", id, arcRuns[id] or 0, #seeds)), (arcRuns[id] or 0) > #seeds / 2)
		end
		ok(name(string.format("random: the relationships tilt some rolls (%.1f a run)", relRolls / #seeds)), relRolls > 0)
	end
	return line, shareMedian, string.format("tier days %s, random: %s", tag, table.concat(tierParts, ", ")), arcLine
end

local line20, _, tiers20, arcs20 = check(Sim.Seeds, "20 seeds")
local line200, share200, tiers200, arcs200 = check(SEEDS_200, "200 seeds")
-- the money floor (200 seeds only): no worse than today's deck, within 0.005
ok(string.format("[200 seeds] random: steady share median %.4f >= floor %.4f (BASELINE_SHARE_200 %.4f - 0.005)", share200, FLOOR_200,
	BASELINE_SHARE_200), share200 >= FLOOR_200)

print(line20)
print(tiers20)
print(arcs20)
print(string.format("%s; random share median %.4f vs floor %.4f", line200, share200, FLOOR_200))
print(tiers200)
print(arcs200)
if #fails > 0 then error(#fails .. " pacing case(s) failed: " .. table.concat(fails, "; ")) end
print("SPEC OK: pacing")
