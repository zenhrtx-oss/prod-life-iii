-- OK Studio LifeRules (Wave 2, "the career remembers"): the rules behind the saved prof.life (schema v5) and every word
-- the player reads about it: fame tiers by Followers, the career clock and year, capped story and discography lists,
-- the firsts an event ticks, the auto title, ribbons, the one public read of year, tier and title, the story /
-- discography / firsts / DAY toast text, and the v4 -> v5 backfill. Pure: no Roblox globals and no require; Config.Life (and
-- Config.Ranks) come in as arguments, so Studio and the luau CLI (spec/life_rules_spec.lua) load the same file.
--
-- prof.life = { day = career day (1 on the first), last = the last UTC day counted (yyyymmdd), story = { entry },
--   disco = { { d, kind, v, key } }, firsts = { [firstId] = career day | 0 (0 = before the clock: backfilled) },
--   tier = the highest tier id ever reached, ribbons = { [ribbonId] = career day } }
-- A story entry is a named-field record of ids and small fields, never prose: { d = day, k = kind, v = visitor id
-- (placement, hit) or Data/Artists id (delivery, delivery3), s = sponsor id, key = card / follow-up / brief / tier id,
-- n = level, first = true when the same event ticked that kind's own first }. Names are filled at render (StoryText).
-- All copy below is Task 0's (research/wave2/copy_2026-10-30.md), on the user's approval list.
local M = {}

-- the Life event kinds (Systems/Life.Event). Wave 3 (design 4.2): cold and thaw, the cold spell's entry and exit
-- (Systems/Career.ColdCheck), every spell logged: no first, title or ribbon
M.KINDS = { "placement", "hit", "sponsor", "sponsor_drop", "delivery", "delivery3", "beat", "hall", "legend", "cypher_win",
	"level", "streak7", "tier", "cold", "thaw" }
-- the tiers that are firsts (FAMOUS and ICON are not: they still get a story line, a banner, a visit and a title)
M.TIER_FIRSTS = { BUZZING = "buzzing", KNOWN = "known" }
-- the room gate whose opening is the "hall" first (Config.Career.Gates)
M.HALL_GATE = "studio_two"
-- the level whose reaching is the "level5" first
M.LEVEL_FIRST = 5

local C = {}
M.Copy = C
-- story lines: "DAY {day} · " .. the sentence; StoryFirst replaces Story when the entry has first = true
C.Story = {
	placement = "You landed a placement with {artist}.",
	hit = "You got a HIT with {artist}.",
	sponsor = "You signed with {sponsor}.",
	sponsor_drop = "{sponsor} dropped you.",
	delivery = "You delivered a session for {artist}.",
	delivery3 = "You delivered a three-star session for {artist}.",
	beat = "You saved a beat.",
	hall = "THE HALL opened for you.",
	legend = "You bought the Legend nameplate.",
	cypher_win = "You won a cypher.",
	level = "You reached LEVEL {level}: {rank}.",
	streak7 = "You hit a 7-day streak on the dailies.",
	tier = "You hit {tier} at {followers} followers.",
	-- Wave 3 (research/wave3/copy_2026-11-05.md section 4, on the approval list): the cold spell, every streak
	cold = "Nobody was calling.",
	thaw = "You got people talking again.",
}
C.StoryFirst = {
	placement = "You landed your first placement, with {artist}.",
	hit = "You got your first HIT, with {artist}.",
	sponsor = "You signed your first sponsor: {sponsor}.",
	delivery = "You delivered your first session, for {artist}.",
	delivery3 = "You delivered your first three-star session, for {artist}.",
	beat = "You saved your first beat.",
	cypher_win = "You won your first cypher.",
}
C.StoryPrefix = "DAY {day} · "
C.StoryEmpty = "Nothing yet. Your story starts with your next session."
C.StoryFooter = "Story · Backspace / B to close"
C.Loading = "Loading..."
-- the career came back without its life: Story and Credits read this (a bug, so it never promises that opening again helps)
C.LifeFailed = "Your career history didn't load this time."
-- a name the render has no entry for (a roster change, a removed visitor) reads as this, never as an id (new copy, on
-- the approval list; a sentence that starts with one is capitalised)
C.Fallback = { artist = "an artist", sponsor = "a sponsor" }
-- the FIRSTS checklist: a label per Config.Life.Firsts id, and the row's state
C.FirstLabels = {
	beat = "FIRST BEAT SAVED",
	delivery = "FIRST DELIVERY",
	delivery3 = "FIRST 3-STAR DELIVERY",
	placement = "FIRST PLACEMENT",
	hit = "FIRST HIT",
	sponsor = "FIRST SPONSOR",
	hall = "THE HALL",
	cypher = "FIRST CYPHER WIN",
	level5 = "LEVEL 5",
	buzzing = "BUZZING",
	known = "KNOWN",
	streak7 = "7-DAY STREAK",
}
C.FirstsHeader = "FIRSTS"
C.StoryHeader = "STORY"
C.FirstDone = "DAY {day}"
C.FirstBefore = "BEFORE DAY 1"
C.FirstNot = "NOT YET"
-- the auto title's words, by Config.Life.Titles id (never a Config.Ranks word: the spec checks)
C.Titles = {
	icon = "ICON",
	famous = "FAMOUS",
	chart = "CHART MAKER",
	known = "WELL KNOWN",
	sponsored = "SPONSORED",
	cypher = "CYPHER CHAMP",
	record = "ON THE RECORD",
	buzzing = "BUZZING",
	regular = "SESSION REGULAR",
	new = "NEW IN TOWN",
}
-- ribbon labels, by Config.Life.Ribbons id
C.Ribbons = {
	streak7 = "7-DAY STREAK",
	placements10 = "10 PLACEMENTS",
	hit = "CHARTED",
	sponsor = "BRAND DEAL",
	icon = "ICON",
}
C.RibbonPrefix = "🎗 "
C.RibbonToast = "RIBBON: {label}"
-- the producer card's year
C.CardYear = "YEAR {year}"
C.DayToast = "DAY {day}"
C.DayToastYear = "DAY {day} · YEAR {year}"
-- the tier banner (the LEVEL UP banner's spot), by tier id
C.Banners = {
	BUZZING = "YOU'RE BUZZING\n1,000 followers · someone's coming by",
	KNOWN = "YOU'RE KNOWN\n5,000 followers · late-night tv is asking about you",
	FAMOUS = "YOU'RE FAMOUS\n20,000 followers · the gossip pages noticed",
	ICON = "YOU'RE AN ICON\n100,000 followers · a record label wants a meeting",
}
-- the cold spell's exit banner (Wave 3, copy doc section 5, on the approval list), sent through "LifeBanner" when a spell
-- ends (Systems/Life.Event "thaw"); none on entry (the cold_news NEWS card is that moment)
C.ThawBanner = "YOU'RE BACK\npeople are calling again"
-- the Career tab's milestone bars ({needs} is PanelUI's needs text)
C.Bars = {
	tier = "NEXT TIER: {tier} · {have} / {need} followers",
	tierTop = "ICON · the top tier",
	level = "NEXT LEVEL: {level} · {have} / {need} XP",
	levelTop = "LEVEL 10 · the top level",
	hall = "THE HALL · {needs}",
	hallOpen = "THE HALL · open",
}
C.DiscoHeader = "Your discography"
C.DiscoKinds = { placement = "PLACEMENT", hit = "HIT", trackone = "TRACK ONE" }
C.DiscoRow = "DAY {day} · {artist} · {kind}"

-- helpers ----------------------------------------------------------------------------------------------------------
-- whole number, truncated toward zero; anything that is not a finite number reads as 0
local function whole(n)
	n = tonumber(n) or 0
	if n ~= n or n == math.huge or n == -math.huge then return 0 end
	local i = n < 0 and -math.floor(-n) or math.floor(n)
	return i == 0 and 0 or i
end
local function num(x) local n = tonumber(x); if n == nil or n ~= n then return 0 end; return n end
local function str(x) return type(x) == "string" and x or nil end
local function tbl(x) return type(x) == "table" and x or nil end

-- thousands commas on a whole number: 5000 -> "5,000", -2500 -> "-2,500" (Format's commas is local; this module is pure)
function M.Commas(n)
	local i = whole(n)
	if i < 0 then return "-" .. M.Commas(-i) end
	local s, k = string.format("%.0f", i), 0
	repeat s, k = string.gsub(s, "^(%d+)(%d%d%d)", "%1,%2") until k == 0
	return s
end

-- fill each {key} from values (function replacement, so a "%" in a value stays as it is); unknown keys stay
function M.Fill(text, values)
	return (string.gsub(text, "{(%w+)}", function(k)
		local v = values and values[k]
		if v == nil then return nil end
		return tostring(v)
	end))
end

-- tiers ------------------------------------------------------------------------------------------------------------
-- the highest tier whose line Followers reach: id, index (1 = the lowest; junk and negatives read as 0 Followers)
function M.TierFor(followers, tiers)
	local f, best = num(followers), 1
	for i, t in ipairs(tiers) do
		if f >= t.followers then best = i end
	end
	return tiers[best].id, best
end

-- a tier id's index (1 when unknown or nil)
function M.TierIndex(id, tiers)
	for i, t in ipairs(tiers) do
		if t.id == id then return i end
	end
	return 1
end

-- every tier a move from index old to index new reaches, in order (A4: old + 1 .. new, never the lowest tier):
-- { { id, followers, index } } copies; empty when new <= old
function M.TiersCrossed(old, new, tiers)
	local out = {}
	for i = math.max(whole(old) + 1, 2), math.min(whole(new), #tiers) do
		table.insert(out, { id = tiers[i].id, followers = tiers[i].followers, index = i })
	end
	return out
end

-- the clock --------------------------------------------------------------------------------------------------------
-- the career year of a career day: days 1..perYear are year 1
function M.YearOf(day, perYear)
	local d = math.max(1, whole(day))
	return (d - 1) // math.max(1, whole(perYear)) + 1
end

-- one career day per UTC day played: advance life.day by 1 when `today` is later than life.last (a missed gap still
-- counts once; an earlier day, such as another server's clock, never counts; a today that isn't a number changes
-- nothing). Returns true when the day advanced.
function M.Step(life, today)
	local now = tonumber(today)
	if now == nil or now ~= now then return false end
	local last = tonumber(life.last)
	if last and now <= last then return false end
	life.day = math.max(0, whole(life.day)) + 1
	life.last = now
	return true
end

-- append entry, then drop the oldest until the list holds at most max (the list stays a dense array)
function M.Push(list, entry, max)
	table.insert(list, entry)
	while #list > max do table.remove(list, 1) end
	return list
end

-- titles and ribbons -----------------------------------------------------------------------------------------------
-- does a rule hold? tier = i: the tier index reached is at least i; first = id: that first is ticked (0 counts);
-- count = stat, n = k: counts[stat] >= k. Every key present must hold; a rule with none always holds.
local function holds(rule, firsts, tierIndex, counts)
	if type(rule) ~= "table" then return false end
	if rule.tier ~= nil and tierIndex < rule.tier then return false end
	if rule.first ~= nil and (firsts == nil or firsts[rule.first] == nil) then return false end
	if rule.count ~= nil and num(counts and counts[rule.count]) < num(rule.n) then return false end
	return true
end

-- the auto title: the first of `titles` (Config.Life.Titles) that holds; returns its word and id, or nil when none does
function M.TitleFor(firsts, tierIndex, titles)
	firsts, tierIndex = tbl(firsts), whole(tierIndex)
	for _, rule in ipairs(titles) do
		local word = C.Titles[rule.id]
		if word and holds(rule, firsts, tierIndex, nil) then return word, rule.id end
	end
	return nil
end

-- the ribbons `life` has newly earned: ids in `rules` order (Config.Life.Ribbons) whose rule holds and that
-- life.ribbons doesn't hold yet (an earned ribbon is kept for good). counts = prof.career; tiers = Config.Life.Tiers.
function M.RibbonsFor(life, counts, rules, tiers)
	life = tbl(life) or {}
	local have, firsts = tbl(life.ribbons) or {}, tbl(life.firsts) or {}
	local tierIndex = M.TierIndex(life.tier, tiers)
	local out = {}
	for _, r in ipairs(rules) do
		if have[r.id] == nil and holds(r.rule, firsts, tierIndex, tbl(counts)) then table.insert(out, r.id) end
	end
	return out
end

-- the toast for ribbons that just landed: "RIBBON: CHARTED", several joined by " · "; nil when none has a label
function M.RibbonToast(ids)
	local labels = {}
	for _, id in ipairs(tbl(ids) or {}) do
		if C.Ribbons[id] then table.insert(labels, C.Ribbons[id]) end
	end
	if #labels == 0 then return nil end
	return M.Fill(C.RibbonToast, { label = table.concat(labels, " · ") })
end

-- the one place a life's public face is computed (Systems/Life's attributes, Systems/Profiles' card, View, the Profile tab):
-- year, tier (id and index), title (word and id), ribbons = the held ids in cfg.Ribbons order. Reads a saved life or a View,
-- which keeps those keys; junk or no life reads as a new one. cfg = Config.Life.
function M.Public(life, cfg)
	life = tbl(life) or {}
	local tierIndex = M.TierIndex(life.tier, cfg.Tiers)
	local word, titleId = M.TitleFor(life.firsts, tierIndex, cfg.Titles)
	local have, ribbons = tbl(life.ribbons) or {}, {}
	for _, r in ipairs(cfg.Ribbons) do
		if have[r.id] ~= nil then table.insert(ribbons, r.id) end
	end
	return { year = M.YearOf(life.day, cfg.DaysPerYear), tier = cfg.Tiers[tierIndex].id, tierIndex = tierIndex, title = word,
		titleId = titleId, ribbons = ribbons }
end

-- events -----------------------------------------------------------------------------------------------------------
local KNOWN_KIND = {}
for _, k in ipairs(M.KINDS) do KNOWN_KIND[k] = true end
local SIMPLE_FIRST = { placement = "placement", hit = "hit", sponsor = "sponsor", delivery = "delivery", beat = "beat",
	hall = "hall", cypher_win = "cypher", streak7 = "streak7" }
-- kinds that only log a story line when they tick their own first (the 10-30 ruling: a busy day stays readable)
local ONLY_FIRST = { beat = true, cypher_win = true }

-- the first ids an event ticks (when not yet ticked), the kind's own first last
function M.FirstsFor(kind, fields)
	fields = tbl(fields) or {}
	if kind == "delivery3" then return { "delivery", "delivery3" } end
	if SIMPLE_FIRST[kind] then return { SIMPLE_FIRST[kind] } end
	if kind == "level" and num(fields.n) >= M.LEVEL_FIRST then return { "level5" } end
	if kind == "tier" and M.TIER_FIRSTS[fields.key] then return { M.TIER_FIRSTS[fields.key] } end
	return {}
end

-- record an event on `life` at its career day: tick its firsts, push a story entry, and for a placement or a hit a
-- discography entry (cfg = Config.Life: StoryMax, DiscoMax). fields: v, s, key (strings), n (number);
-- disco = "trackone" names a placement's discography kind; again = true marks a repeat delivery, daily = true a daily
-- request. beat, cypher_win and a repeat or daily delivery log a story line only when they tick their own first (a
-- first 3-star on a repeat brief, a first-ever delivery that is a daily): up to three dailies a day would otherwise
-- fill the 100 lines. Returns { ticked = { firstId }, story = entry?, disco = entry? }.
function M.Apply(life, kind, fields, cfg)
	fields = tbl(fields) or {}
	if type(life.firsts) ~= "table" then life.firsts = {} end
	if type(life.story) ~= "table" then life.story = {} end
	if type(life.disco) ~= "table" then life.disco = {} end
	local day = math.max(1, whole(life.day))
	local res = { ticked = {} }
	local ids = M.FirstsFor(kind, fields)
	local own, ownTicked = ids[#ids], false
	for _, id in ipairs(ids) do
		if life.firsts[id] == nil then
			life.firsts[id] = day
			table.insert(res.ticked, id)
			if id == own then ownTicked = true end
		end
	end
	if not KNOWN_KIND[kind] then return res end
	local quiet = ONLY_FIRST[kind] or ((kind == "delivery" or kind == "delivery3") and (fields.again == true or fields.daily == true))
	if ownTicked or not quiet then
		local n = tonumber(fields.n)
		local e = { d = day, k = kind, v = str(fields.v), s = str(fields.s), key = str(fields.key), n = n and whole(n) or nil,
			first = ownTicked or nil }
		M.Push(life.story, e, cfg.StoryMax)
		res.story = e
	end
	if kind == "placement" or kind == "hit" then
		local dk = kind
		if kind == "placement" and type(fields.disco) == "string" and C.DiscoKinds[fields.disco] then dk = fields.disco end
		local e = { d = day, kind = dk, v = str(fields.v), key = str(fields.key) }
		M.Push(life.disco, e, cfg.DiscoMax)
		res.disco = e
	end
	return res
end

-- text -------------------------------------------------------------------------------------------------------------
-- a display name from a names map, or the fallback (also for a name that still holds a {token}, like the rep's)
local function nameOr(map, id, fallback)
	local n = map and id ~= nil and map[id]
	if type(n) == "string" and #n > 0 and not string.find(n, "[{}]") then return n end
	return fallback
end
local function dayText(d) return tostring(math.max(0, whole(d))) end

-- a story line, "DAY 12 · You landed your first placement, with LIL NAV X.", from a story entry and
-- names = { visitors = { [visitorId] = name } (the roster in use), artists = { [Data/Artists id] = name },
--   sponsors = { [sponsorId] = name }, ranks = Config.Ranks, tiers = Config.Life.Tiers } (each part optional).
-- A missing visitor, artist or sponsor name reads as Copy.Fallback. Returns nil for a line it can't render cleanly
-- (an unknown kind, a level with no rank, an unknown tier): skip it; no line ever keeps a {token}.
function M.StoryText(entry, names)
	if type(entry) ~= "table" then return nil end
	local k = entry.k
	local tpl = (entry.first and C.StoryFirst[k]) or C.Story[k]
	if type(tpl) ~= "string" then return nil end
	names = tbl(names) or {}
	local vals = {}
	if k == "placement" or k == "hit" then
		vals.artist = nameOr(tbl(names.visitors), entry.v, C.Fallback.artist)
	elseif k == "delivery" or k == "delivery3" then
		vals.artist = nameOr(tbl(names.artists), entry.v, C.Fallback.artist)
	elseif k == "sponsor" or k == "sponsor_drop" then
		vals.sponsor = nameOr(tbl(names.sponsors), entry.s, C.Fallback.sponsor)
	elseif k == "level" then
		local n = tonumber(entry.n)
		local rank = n and tbl(names.ranks) and names.ranks[n]
		if type(rank) ~= "string" then return nil end
		vals.level, vals.rank = tostring(whole(n)), rank
	elseif k == "tier" then
		local t
		for _, x in ipairs(tbl(names.tiers) or {}) do
			if x.id == entry.key then t = x end
		end
		if not t then return nil end
		vals.tier, vals.followers = t.id, M.Commas(t.followers)
	end
	local sentence = string.gsub(M.Fill(tpl, vals), "^%l", string.upper)
	local line = M.Fill(C.StoryPrefix, { day = dayText(entry.d) }) .. sentence
	if string.find(line, "[{}]") then return nil end
	return line
end

-- a discography row, "DAY 9 · LIL NAV X · PLACEMENT" (names as in StoryText); nil for an unknown kind
function M.DiscoText(entry, names)
	if type(entry) ~= "table" then return nil end
	local kind = C.DiscoKinds[entry.kind]
	if not kind then return nil end
	names = tbl(names) or {}
	local line = M.Fill(C.DiscoRow, { day = dayText(entry.d), artist = nameOr(tbl(names.visitors), entry.v, C.Fallback.artist), kind = kind })
	if string.find(line, "[{}]") then return nil end
	return line
end

-- the ids a life's story and discography need display names for: { visitors = set, artists = set, sponsors = set }
-- (A8: Career.State sends the names for these, from the server's roster)
function M.NameIds(life)
	local out = { visitors = {}, artists = {}, sponsors = {} }
	life = tbl(life) or {}
	for _, e in ipairs(tbl(life.story) or {}) do
		if type(e) == "table" then
			if (e.k == "placement" or e.k == "hit") and str(e.v) then out.visitors[e.v] = true end
			if (e.k == "delivery" or e.k == "delivery3") and str(e.v) then out.artists[e.v] = true end
			if (e.k == "sponsor" or e.k == "sponsor_drop") and str(e.s) then out.sponsors[e.s] = true end
		end
	end
	for _, e in ipairs(tbl(life.disco) or {}) do
		if type(e) == "table" and str(e.v) then out.visitors[e.v] = true end
	end
	return out
end

-- one record's copy, or a list of them
local function copyRows(list)
	local out = {}
	for _, e in ipairs(tbl(list) or {}) do
		if type(e) == "table" then table.insert(out, table.clone(e)) end
	end
	return out
end

-- what the client gets of a life (Career.State's `life`, built from prof.life alone, so it works before Systems/Life
-- starts): day, year, tier (id and index), title (word and id), copies of the firsts, ribbons, story and discography,
-- and names = the display names of exactly the ids NameIds finds, from known = { visitors, artists, sponsors } maps. An
-- id with no known name, or a name still holding a {token}, is left out: StoryText reads it as Copy.Fallback. cfg =
-- Config.Life.
function M.View(life, cfg, known)
	life, known = tbl(life) or {}, tbl(known) or {}
	local day = math.max(1, whole(life.day))
	local pub = M.Public(life, cfg)
	local ids, names = M.NameIds(life), {}
	for part, set in pairs(ids) do
		local map, out = tbl(known[part]), {}
		for id in pairs(set) do
			local n = map and map[id]
			if type(n) == "string" and #n > 0 and not string.find(n, "[{}]") then out[id] = n end
		end
		names[part] = out
	end
	return { day = day, year = pub.year, tier = pub.tier, tierIndex = pub.tierIndex, title = pub.title, titleId = pub.titleId,
		firsts = table.clone(tbl(life.firsts) or {}), ribbons = table.clone(tbl(life.ribbons) or {}),
		story = copyRows(life.story), disco = copyRows(life.disco), names = names }
end

-- a FIRSTS row's state: "DAY 6", "BEFORE DAY 1" (0: backfilled) or "NOT YET"
function M.FirstText(firsts, id)
	local d = tbl(firsts) and firsts[id]
	if d == nil then return C.FirstNot end
	if whole(d) == 0 then return C.FirstBefore end
	return M.Fill(C.FirstDone, { day = dayText(d) })
end

-- the DAY toast on a new career day: "DAY 12", or "DAY 8 · YEAR 2" on the first day of a new career year
function M.DayToast(day, perYear)
	local d = math.max(1, whole(day))
	if d > 1 and (d - 1) % math.max(1, whole(perYear)) == 0 then
		return M.Fill(C.DayToastYear, { day = tostring(d), year = tostring(M.YearOf(d, perYear)) })
	end
	return M.Fill(C.DayToast, { day = tostring(d) })
end

-- one reader of the LifeDayToast attribute: read(day) returns the toast's text the first time it sees a value, and nil for
-- the same value again or no value. So a client that reads after the server set it still toasts, and only once.
function M.DayToastOnce(perYear)
	local seen
	return function(day)
		if type(day) ~= "number" or day == seen then return nil end
		seen = day
		return M.DayToast(day, perYear)
	end
end

-- the tier banner's text: its Copy.Banners line, or the headline alone when no walk-in will bring the visit it promises
-- (visits = false); nil for a tier with no banner
function M.BannerText(tierId, visits)
	local text = C.Banners[tierId]
	if not text or visits then return text end
	return string.match(text, "^[^\n]*")
end

-- backfill -----------------------------------------------------------------------------------------------------------
-- does a DAW save hold a beat? any save counted, any slot, or a v1 pattern
local function hasBeat(daw)
	if type(daw) ~= "table" then return false end
	if num(daw.saves) > 0 then return true end
	if type(daw.slots) == "table" and next(daw.slots) ~= nil then return true end
	return type(daw.pattern) == "string"
end

-- prof.life for a profile saved before v5: career day 1 from `today` (last = today, so today doesn't count again),
-- the current tier recorded silently, every first the profile shows marked 0 ("before the clock"), and an empty story,
-- discography and ribbons (Systems/Life awards ribbons). Junk or missing fields (career, credits, cypher, daw, daily)
-- read as nothing. Uses prof.level as stored.
function M.Backfill(prof, today, tiers)
	prof = tbl(prof) or {}
	local c = tbl(prof.career) or {}
	local tierId, tierIndex = M.TierFor(c.followers, tiers)
	local f = {}
	if num(c.placements) > 0 then f.placement = 0 end
	if num(c.hits) > 0 then f.hit = 0 end
	if num(c.sponsors) > 0 then f.sponsor = 0 end
	if tbl(c.gates) and c.gates[M.HALL_GATE] == true then f.hall = 0 end
	if num(prof.level) >= M.LEVEL_FIRST then f.level5 = 0 end
	for i = 2, tierIndex do
		local id = M.TIER_FIRSTS[tiers[i].id]
		if id then f[id] = 0 end
	end
	local credits = tbl(prof.credits)
	if credits and #credits > 0 then
		f.delivery = 0
		for _, cr in ipairs(credits) do
			if type(cr) == "table" and num(cr.s) >= 3 then f.delivery3 = 0 end
		end
	end
	if tbl(prof.cypher) and num(prof.cypher.wins) > 0 then f.cypher = 0 end
	if hasBeat(prof.daw) then f.beat = 0 end
	if tbl(prof.daily) and num(prof.daily.streak) >= 7 then f.streak7 = 0 end
	return { day = 1, last = today, story = {}, disco = {}, firsts = f, tier = tierId, ribbons = {} }
end

return M
