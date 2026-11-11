-- OK Studio WalkInRules: every walk-in rule as a pure function. The odds tilt, readiness and a choice's chance, rolling
-- a choice or a follow-up's news, the money path, the overhead tag, the daily cap, the rush-hour gap and its room, the
-- follow-up queue, picking the next visitor or phone pop (source, life gates, group caps, the first card, seen seeding,
-- re-checking a stored pick, the artist cooldown at send), the walking queue, name filling, the hub rooms and a
-- visitor's route.
-- Pure: no Roblox globals and no other modules. Config values, the rng (`rng(lo, hi)` -> whole number) and Format come in
-- as arguments, so Studio and the luau CLI (spec/walkin_rules_spec.lua) run the same rules.
local M = {}

-- the good outcome's chance in percent: base tilted by Aura (+1 per auraPer, within +-auraCap) and Followers
-- (+1 per followersPer, up to followersCap), plus `tilt` (default 0: the beat's and the relationship's), then held to
-- [odds.min, odds.max]
function M.Chance(base, career, odds, tilt)
	local aura = math.clamp(math.floor((career.aura or 0) / odds.auraPer), -odds.auraCap, odds.auraCap)
	local followers = math.min(math.floor((career.followers or 0) / odds.followersPer), odds.followersCap)
	return math.clamp(base + aura + followers + (tilt or 0), odds.min, odds.max)
end

-- how ready a career is for a big room, 0..1 (two sessions): the average of level, placements, followers and Aura,
-- each against its mark in `cfg` (Config.WalkIns.Odds.ready) and held to 1. A missing stat counts as 0, Aura below 0
-- as 0, and a missing level as level 1. `level` comes in separately: the server reads prof.level, the sim sim.level
function M.Readiness(career, level, cfg)
	local function part(have, mark) return math.min(math.max(have or 0, 0) / mark, 1) end
	return (part(level or 1, cfg.level) + part(career.placements, cfg.placements) + part(career.followers, cfg.followers)
		+ part(career.aura, cfg.aura)) / 4
end

-- a choice's good chance in percent: a `ready` choice maps Readiness(career, career.level, odds.ready) onto
-- odds.min..odds.max (rounded, plus `tilt`, then held there); any other choice is Chance(choice.odds or 50, ..., tilt).
-- A `beatMin` choice has no roll: 100 when `beatQ` (the best beat's BeatQuality, default 0) reaches it, else 0, and the
-- tilt doesn't apply
function M.ChoiceChance(choice, career, odds, tilt, beatQ)
	if choice.beatMin then return (beatQ or 0) >= choice.beatMin and 100 or 0 end
	if choice.ready then
		assert(odds.ready, "ChoiceChance: a ready choice needs odds.ready (Config.WalkIns.Odds.ready)")
		local r = M.Readiness(career, career.level, odds.ready)
		return math.clamp(math.floor(odds.min + (odds.max - odds.min) * r + 0.5) + (tilt or 0), odds.min, odds.max)
	end
	return M.Chance(choice.odds or 50, career, odds, tilt)
end

-- the chance Resolve rolls `choice` at, in percent (one chance rule): 100 for a sure choice (a beatMin choice goes by its beat first), else ChoiceChance. Resolve
-- and the phone hook's ReadyChance both read it; it never draws
function M.RollChance(choice, career, odds, tilt, beatQ)
	if choice.beatMin then return M.ChoiceChance(choice, career, odds, tilt, beatQ) end
	if choice.sure then return 100 end
	return M.ChoiceChance(choice, career, odds, tilt, beatQ)
end

-- what an outcome would do, raw and unclamped: the choice's cost and the outcome's money stay separate (Money path);
-- xp is the content's number (the caller pays it through the XP gate and shows what was paid)
local function deltasOf(outcome, cost)
	return { cost = cost, money = outcome.money or 0, aura = outcome.aura or 0, followers = outcome.followers or 0,
		placements = outcome.placements or 0, hits = outcome.hits or 0, sponsors = outcome.sponsors or 0,
		xp = outcome.xp or 0 }
end

-- roll a Choice for `career`. Refused before any roll when the cost is out of reach. A rare outcome is the first roll;
-- a sure choice is good without rolling; otherwise one roll of 1..100 at or under RollChance is good, else bad
-- (a choice with no bad outcome stays good). A `ready` choice rolls like any other, so the draws never change. `tilt`
-- (default 0) moves the chance before its clamp; a `beatMin` choice never rolls: good ("sure") when `beatQ` reaches it,
-- else bad ("bad")
function M.Resolve(choice, career, odds, rng, tilt, beatQ)
	local cost = choice.cost or 0
	if (career.money or 0) < cost then return { ok = false, reason = "afford" } end
	local chance = M.RollChance(choice, career, odds, tilt, beatQ)
	local outcome, roll
	if choice.beatMin then
		if chance == 100 then
			outcome, roll = choice.good, "sure"
		else
			outcome, roll = choice.bad or choice.good, "bad"
		end
	elseif choice.rare and rng(1, 100) <= (choice.rareOdds or 0) then
		outcome, roll = choice.rare, "rare"
	elseif choice.sure then
		outcome, roll = choice.good, "sure"
	elseif rng(1, 100) <= chance then
		outcome, roll = choice.good, "good"
	else
		outcome, roll = choice.bad or choice.good, "bad"
	end
	return { ok = true, outcome = outcome, roll = roll, chance = chance, deltas = deltasOf(outcome, cost) }
end

-- roll a Followup's news (its `resolve`): the same result shape as Resolve, never a cost
function M.ResolveNews(followup, career, odds, rng)
	local r = followup.resolve
	return M.Resolve({ odds = r.odds, good = r.good, bad = r.bad }, career, odds, rng)
end

-- the live money path on a plain balance: pay `cost` (the caller has checked it is affordable), then add a positive
-- `money` or take a negative one, never below 0. returns newBalance, gained, taken
function M.ApplyMoney(balance, cost, money)
	local b = balance - (cost or 0)
	money = money or 0
	if money > 0 then return b + money, money, 0 end
	if money < 0 then
		local taken = math.min(-money, b)
		return b - taken, 0, taken
	end
	return b, 0, 0
end

local function sign(n) return n > 0 and "+" or "-" end

-- the overhead tag for what was actually applied (`applied` = the amounts and the `cost` paid), in priority order.
-- Given the outcome's tone "win" or "loss": the first non-zero amount whose sign matches it, where a loss counts a paid
-- cost as money lost (money - cost), so the tag never contradicts the headline; when none matches, or for any other
-- tone, the first non-zero amount. The tone returned is the one given, else the amount's sign ("neutral" when none)
local TAGS = {
	{ "hits", function(n) return sign(n) .. math.abs(n) .. " HIT" end },
	{ "placements", function(n) return sign(n) .. math.abs(n) .. " PLACEMENT" end },
	{ "sponsors", function(n) return sign(n) .. math.abs(n) .. " SPONSOR" end },
	{ "aura", function(n, Format) return Format.Signed(n) .. " AURA" end },
	{ "followers", function(n, Format) return sign(n) .. Format.Count(math.abs(n)) .. " FOLLOWERS" end },
	{ "money", function(n, Format) return Format.SignedMoney(n) end },
}
function M.TagFor(applied, Format, tone)
	local want = (tone == "win" and 1) or (tone == "loss" and -1) or nil
	if want then
		for _, t in ipairs(TAGS) do
			local n = applied[t[1]] or 0
			if t[1] == "money" and want < 0 then n -= applied.cost or 0 end
			if n * want > 0 then return t[2](n, Format), tone end
		end
	end
	for _, t in ipairs(TAGS) do
		local n = applied[t[1]] or 0
		if n ~= 0 then return t[2](n, Format), tone or (n > 0 and "win" or "loss") end
	end
	return nil, tone or "neutral"
end

-- a new UTC day (yyyymmdd) resets today's count; the queue, seen and last carry over
function M.Rollover(state, today)
	if state.day ~= today then
		state.day = today
		state.today = 0
	end
	return state
end

-- may another visit start today? (rolls the day over first)
function M.CanSchedule(state, today, max)
	M.Rollover(state, today)
	return (state.today or 0) < max
end

-- rush hour (design 4.5): the presence seconds until the next visit and the rush to keep (Rush = { left, saved }, or
-- nil). With no rush, a roll() under cfg.Chance (only when allowStart) starts a burst of draw(cfg.Size) short gaps;
-- otherwise it is one normal draw(gap). In a burst (left > 0) each gap is a short draw(cfg.Short) in place of a normal
-- draw(gap), the difference saved; once left is 0 the quiet gap is a normal draw plus everything saved, so a finished
-- burst's gaps add up to the normal gaps they replace. A running burst never rolls. Never changes the rush passed in
function M.RushGap(rush, cfg, gap, draw, roll, allowStart)
	if rush == nil then
		if not (allowStart and roll() < cfg.Chance) then return draw(gap[1], gap[2]), nil end
		rush = { left = draw(cfg.Size[1], cfg.Size[2]), saved = 0 }
	end
	if rush.left > 0 then
		local g = draw(gap[1], gap[2])
		local s = draw(cfg.Short[1], cfg.Short[2])
		return s, { left = rush.left - 1, saved = rush.saved + g - s }
	end
	return draw(gap[1], gap[2]) + rush.saved, nil
end

-- may a burst start now? Only with room for its smallest size (size[1]) before the daily cap, so BUSY DAY never
-- covers one visitor and then nobody until UTC midnight. A stored day that isn't today (sameDay false) has room: the
-- rollover resets today's count
function M.RushRoom(today, dailyMax, size, sameDay)
	return not sameDay or dailyMax - today >= size[1]
end

-- queue the follow-up `plant` ({ id, at? }) for visit count + rng(at); nil when that id is already queued
function M.Plant(state, plant, defaultAt, rng, ctx)
	for _, q in ipairs(state.queue) do
		if q.id == plant.id then return nil end
	end
	local at = plant.at or defaultAt
	local entry = { id = plant.id, at = state.count + rng(at[1], at[2]), ctx = ctx }
	table.insert(state.queue, entry)
	return entry
end

-- a system plant's `at` for this state (a tier visit): before any walk-in (count 0) both ends move one later, so it can never
-- be the first walk-in, which is the gentle first card's. Any other time, the same range. Never changes the table given
function M.AfterFirst(state, at)
	if state.count == 0 then return { at[1] + 1, at[2] + 1 } end
	return at
end

-- the career value a gate key reads (GateKey): the five stats and money from `career`, visits from the argument;
-- nil for any other key
local CAREER_GATES = { aura = true, followers = true, placements = true, hits = true, sponsors = true, money = true }
local function gateValue(key, career, visits)
	if key == "visits" then return visits end
	if CAREER_GATES[key] then return career[key] end
	return nil
end

-- a "who.flag" gate id as (who, flag); the first dot splits them
local function splitFlag(id)
	local who, flag = string.match(id, "^([^.]+)%.(.+)$")
	return who, flag
end

-- do the card's relationship gates hold? `rel` = prof.walkins.rel ({ [visitorId] = { score, flags } }). needs.flags /
-- under.flags list "who.flag" ids (a flag set for that visitor / not set), needs.rel / under.rel are the card's own
-- visitor's score (>= n / < n). A needs flag or a rel score of a visitor not in `rel` fails; an under flag of one passes
-- (it can't be set)
local function relOk(card, rel, key, wantSet)
	for _, id in ipairs(card[key].flags or {}) do
		local who, flag = splitFlag(id)
		local e = who and rel[who]
		local isSet = e ~= nil and e.flags ~= nil and e.flags[flag] ~= nil
		if isSet ~= wantSet then return false end
	end
	return true
end
local function relScore(card, rel)
	local e = rel[card.visitor]
	return e and (e.score or 0)
end

-- is the card open to this career? Every `needs` value met (have >= n) and every `under` value not reached
-- (have < n). A key outside GateKey, or one whose value is missing, is never eligible, and a nil career passes only
-- cards with no needs/under. The relationship gates (needs/under `flags` and `rel`) read `rel`; with `rel` nil a card
-- with any of them is ineligible
function M.GateOk(card, career, visits, rel)
	local needs, under = card.needs, card.under
	if (needs and (needs.flags or needs.rel)) or (under and (under.flags or under.rel)) then
		if rel == nil then return false end
		if needs then
			if needs.flags and not relOk(card, rel, "needs", true) then return false end
			if needs.rel then
				local have = relScore(card, rel)
				if have == nil or have < needs.rel then return false end
			end
		end
		if under then
			if under.flags and not relOk(card, rel, "under", false) then return false end
			if under.rel then
				local have = relScore(card, rel)
				if have == nil or have >= under.rel then return false end
			end
		end
	end
	for k, n in pairs(needs or {}) do
		if k ~= "flags" and k ~= "rel" then
			local have = career and gateValue(k, career, visits)
			if have == nil or have < n then return false end
		end
	end
	for k, n in pairs(under or {}) do
		if k ~= "flags" and k ~= "rel" then
			local have = career and gateValue(k, career, visits)
			if have == nil or have >= n then return false end
		end
	end
	return true
end

-- a cap's key: the day or the week number (CapKeys), by cap.per
local function capKey(cap, day, week)
	if cap.per == "week" then return week end
	return day
end

-- is the card's group under its cap (Card.cap = { group, per, max }) for this day or week? `caps` = state.caps
-- ({ [group] = { key, n } }); a count kept under another key is from an earlier day or week and doesn't count. An
-- uncapped card always passes; a capped one fails when its key wasn't given
function M.CapOk(card, caps, day, week)
	local cap = card.cap
	if not cap then return true end
	local key = capKey(cap, day, week)
	if key == nil then return false end
	local c = caps and caps[cap.group]
	return not (c and c.key == key and c.n >= cap.max)
end

-- count one delivery of a capped card against its group: a new day or week key starts n again from 0. Mutating; it
-- touches only state.caps (created when missing). An uncapped card changes nothing
function M.CountCap(state, card, day, week)
	local cap = card.cap
	if not cap then return end
	local key = capKey(cap, day, week)
	state.caps = state.caps or {}
	local c = state.caps[cap.group]
	if not c or c.key ~= key then
		c = { key = key, n = 0 }
		state.caps[cap.group] = c
	end
	c.n += 1
end

-- the cap keys for a time in seconds (Data._now() on the server): whole UTC days since the epoch, and that day // 7.
-- Never yyyymmdd, which is the walk-in day counter's (Rollover)
function M.CapKeys(nowSeconds)
	local day = math.floor(nowSeconds / 86400)
	return day, day // 7
end

-- the queued entry that is due next visit (lowest `at` first). Skipped: ids the deck doesn't know, a follow-up of the
-- other source (Followup.source, default "walkin", against opts.source) and ids in opts.exclude
local function dueEntry(state, deck, opts)
	local want, exclude = opts.source or "walkin", opts.exclude
	local best
	for _, q in ipairs(state.queue) do
		local f = deck.followups[q.id]
		if q.at <= state.count + 1 and f and (f.source or "walkin") == want and not (exclude and exclude[q.id])
			and (not best or q.at < best.at) then
			best = q
		end
	end
	return best
end

-- may the card come next? minCount, the artist cooldown, the sponsor floor, the source (Card.source, default
-- "walkin", against opts.source), the needs/under gates against opts.career, the group cap for opts.day/opts.week,
-- aired, opts.exclude (unless `ignoreExclude`), then `when`. A `system` card is never eligible: only a dedicated
-- server path sends one. opts.rel (prof.walkins.rel) feeds the relationship gates
local function cardEligible(card, state, deck, opts, ignoreExclude)
	if card.system then return false end
	if (card.minCount or 0) > state.count + 1 then return false end
	local last = state.last[card.visitor]
	if last ~= nil and state.count - last < opts.cooldown then return false end
	local floor = card.sponsor and deck.sponsors[card.sponsor]
	if floor and (opts.aura or 0) < floor then return false end
	if (card.source or "walkin") ~= (opts.source or "walkin") then return false end
	local career = opts.career
	if not M.GateOk(card, career, career and career.visits, opts.rel) then return false end
	if not M.CapOk(card, state.caps, opts.day, opts.week) then return false end
	if card.aired and not opts.aired then return false end
	if not ignoreExclude and opts.exclude and opts.exclude[card.id] then return false end
	if card.when == "unsponsored" then return not opts.sponsored end
	if card.when == "sponsored" then return opts.sponsored end
	return true
end

-- no burst when a gate opens (design 4.2): every card eligible under `opts` whose seen is still nil joins at the
-- lowest seen among the eligible cards that have one (0 when none has), so it joins the least-seen rotation evenly.
-- Mutating: the caller runs it before Pick. Returns how many cards it changed
function M.Seed(state, deck, opts)
	local low, fresh = nil, {}
	for _, card in ipairs(deck.cards) do
		if cardEligible(card, state, deck, opts) then
			local seen = state.seen[card.id]
			if seen == nil then
				table.insert(fresh, card)
			elseif low == nil or seen < low then
				low = seen
			end
		end
	end
	for _, card in ipairs(fresh) do state.seen[card.id] = low or 0 end
	return #fresh
end

-- the next visit, or the next phone pop with opts.source = "phone": a due follow-up of that source wins; then, when
-- opts.career says visits 0, the first eligible card marked `first` (no rng draw); else an eligible card among the
-- least seen, by weight (whole numbers, default 1) with one rng(1, total) draw. A sponsor's card needs opts.aura
-- (nil = 0) at or above that sponsor's floor in deck.sponsors; the other filters are cardEligible's. Pure: reads
-- state, never changes it
function M.Pick(state, deck, opts)
	local entry = dueEntry(state, deck, opts)
	if entry then return { kind = "followup", entry = entry, followup = deck.followups[entry.id] } end
	local firstVisit = opts.career ~= nil and opts.career.visits == 0
	local pool, fewest = {}, math.huge
	for _, card in ipairs(deck.cards) do
		if cardEligible(card, state, deck, opts) then
			if firstVisit and card.first then return { kind = "card", card = card } end
			local seen = state.seen[card.id] or 0
			if seen < fewest then pool, fewest = {}, seen end
			if seen == fewest then table.insert(pool, card) end
		end
	end
	local total = 0
	for _, card in ipairs(pool) do total += card.weight or 1 end
	if total <= 0 then return nil end
	local r = opts.rng(1, total)
	for _, card in ipairs(pool) do
		r -= card.weight or 1
		if r <= 0 then return { kind = "card", card = card } end
	end
	return nil
end

-- may a stored pick still be delivered? `card` is the stored pick's Card (nil for a follow-up pick: true). True when
-- it passes Pick's eligibility under the same opts (minCount, the cooldown, the floor, `when`, source, gates, caps,
-- aired); opts.exclude is ignored. Pure
function M.Revalidate(state, deck, opts, card)
	if card == nil then return true end
	return cardEligible(card, state, deck, opts, true)
end

-- a phone pop was sent: when its sender is an artist (deck.visitors), that artist's cooldown runs from now across
-- both sources (last = count, never moved back, so a cooldown already ahead of count stands). Any other sender, and a
-- deck without visitors, change nothing. Mutating; it touches only state.last
function M.MarkSent(state, item, deck)
	local v = deck.visitors and deck.visitors[item.visitor]
	if not (v and v.kind == "artist") then return end
	state.last[item.visitor] = math.max(state.last[item.visitor] or state.count, state.count)
end

-- remove a queued entry (ids are unique in the queue: Plant refuses a second)
function M.TakeQueued(state, entry)
	for i, q in ipairs(state.queue) do
		if q == entry or q.id == entry.id then
			table.remove(state.queue, i)
			return q
		end
	end
	return nil
end

-- first come, first walk: admit `max - walking` from the front of `waiting`; returns admitted, rest
function M.Admit(walking, waiting, max)
	local room = max - walking
	local admitted, rest = {}, {}
	for i, v in ipairs(waiting) do
		table.insert(i <= room and admitted or rest, v)
	end
	return admitted, rest
end

-- fill every {name:<visitorId>} from `names`, then {sponsor} with `sponsorName` and {beat} with "the one at <bpm>" (or
-- "something" when `beatBpm` is nil); unknown tokens stay as they are
function M.Fill(text, names, sponsorName, beatBpm)
	local out = string.gsub(text, "{name:([^}]+)}", function(id) return names and names[id] end)
	if sponsorName then out = string.gsub(out, "{sponsor}", function() return sponsorName end) end
	out = string.gsub(out, "{beat}", function() return beatBpm and ("the one at " .. beatBpm) or "something" end)
	return out
end

-- the first term in `hints` ({ { term, text } }, in order) that `seen` ({ [term] = n }) hasn't and some text in `texts`
-- says as a whole word (case-insensitive: "auras" and "plaurall" are not "aura"); nil when none
function M.HintFor(texts, seen, hints)
	for _, h in ipairs(hints) do
		if not (seen and seen[h.term]) then
			local pat = "%f[%w]" .. string.gsub(string.lower(h.term), "%W", "%%%0") .. "%f[%W]"
			for _, t in ipairs(texts) do
				if string.find(string.lower(t), pat) then return h end
			end
		end
	end
	return nil
end

-- how good a beat is as a walk-in's proof, 0..4 (nil = 0): its stars, +1 once the room has fired it 3 times
function M.BeatQuality(entry)
	if not entry then return 0 end
	return math.min((entry.stars or 0) + ((entry.fires or 0) >= 3 and 1 or 0), 4)
end

-- the recent beat with the highest quality; a tie goes to the first (the newest); nil for none
function M.BestBeat(recent)
	local best, bestQ
	for _, e in ipairs(recent) do
		local q = M.BeatQuality(e)
		if bestQ == nil or q > bestQ then best, bestQ = e, q end
	end
	return best
end

-- the recent list (newest first) after delivering `entry`: the same pattern merges (stars the higher of the two, fires
-- the larger) and moves to the front, a new one goes to the front, and only `max` stay. Returns a new list
function M.RecentPush(recent, entry, max)
	local merged = { pattern = entry.pattern, bpm = entry.bpm, stars = entry.stars or 0, fires = entry.fires or 0, day = entry.day }
	local out = { merged }
	for _, e in ipairs(recent) do
		if e.pattern == entry.pattern then
			merged.stars = math.max(merged.stars, e.stars or 0)
			merged.fires = math.max(merged.fires, e.fires or 0)
		elseif #out < max then
			table.insert(out, e)
		end
	end
	return out
end

-- the recent list after one FIRE on `pattern`: a known one gains a fire where it stands; an unknown one is created at the
-- front with stars 0 first. Returns a new list
function M.RecentFire(recent, pattern, bpm, day, max)
	local out, found = {}, false
	for _, e in ipairs(recent) do
		if e.pattern == pattern then
			found = true
			table.insert(out, { pattern = e.pattern, bpm = e.bpm, stars = e.stars, fires = (e.fires or 0) + 1, day = e.day })
		else
			table.insert(out, e)
		end
	end
	if not found then
		table.insert(out, 1, { pattern = pattern, bpm = bpm, stars = 0, fires = 1, day = day })
		while #out > max do table.remove(out) end
	end
	return out
end

-- the chance tilt in points of a beat quality `q` against odds.beatCenter, and of a relationship score
function M.BeatTilt(q, odds) return (q - odds.beatCenter) * odds.beatPer end
function M.RelTilt(score, odds) return score * odds.relPer end

-- apply an outcome's `rel` write ({ who?, score?, flag?, clear? }) to `rel` ({ [visitorId] = { score, flags } }, nil =
-- none), for `who` or else `ownVisitor`: score is added (held to -3..3), flag is set to `day`, clear removes a flag. A
-- write with none of score, flag or clear changes nothing. Mutates and returns `rel`
function M.RelWrite(rel, write, ownVisitor, day)
	rel = rel or {}
	if write.score == nil and write.flag == nil and write.clear == nil then return rel end
	local id = write.who or ownVisitor
	local e = rel[id]
	if not e then
		e = { score = 0, flags = {} }
		rel[id] = e
	end
	e.flags = e.flags or {}
	if write.score then e.score = math.clamp((e.score or 0) + write.score, -3, 3) end
	if write.flag then e.flags[write.flag] = day end
	if write.clear then e.flags[write.clear] = nil end
	return rel
end

-- the hub room at x (the floor plan runs west to east along x)
function M.RoomOf(x)
	if x < 12 then return "Corridor" end
	if x < 44 then return "Lounge" end
	if x < 80 then return "Control" end
	return "Booth"
end

-- inside the hub rooms (not the Studio Two or Interscope passages, the stairs or the roof): the corridor between its
-- walls (x 0..12, z 0..10; OK_Passage_Interscope opens off it at x 2..10, z < 0 and OK_Passage_StudioTwo at z > 10),
-- then the lounge, control room and booth (x 12..94, z -12..12)
function M.InHub(x, y, z)
	if y >= 20 then return false end
	if x >= 0 and x < 12 then return z >= 0 and z <= 10 end
	return x >= 12 and x <= 94 and z >= -12 and z <= 12
end

-- the walk to a target: the waypoint chain of the target's room (each { x, z }), then a stop `arriveDistance` studs
-- short of the target on the last leg. No stop is added when the last waypoint is already that close
function M.Route(targetX, targetZ, waypoints, arriveDistance)
	local route = {}
	for i, p in ipairs(waypoints[M.RoomOf(targetX)] or {}) do route[i] = { p[1], p[2] } end
	local last = route[#route]
	if last then
		local dx, dz = targetX - last[1], targetZ - last[2]
		local d = math.sqrt(dx * dx + dz * dz)
		if d > arriveDistance then
			local k = (d - arriveDistance) / d
			table.insert(route, { last[1] + dx * k, last[2] + dz * k })
		end
	end
	return route
end

return M
