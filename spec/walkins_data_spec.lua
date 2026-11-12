-- CLI spec for Data/WalkIns (the walk-in content: visitors, sponsors, cards, follow-ups, both rosters).
-- Checks shapes, ids, the plant graph, the money/stat rules, the test-facing ids Tasks 6/7 use, both rosters' names,
-- and the safety lists (real names, blocklist). Wave 1a's content validator (Task 0) adds odds 10..90, the phone fields
-- (source, app, news) and phone outcomes, needs/under gates, caps, mom and first never cost, wait and note lines, and a
-- web-check note on every new visitor. Run: sh tools/spec.sh walkins_data
local W = require("../src/ReplicatedStorage/OK/Data/WalkIns")
local R = require("../src/ReplicatedStorage/OK/Modules/WalkInRules")
local F = require("../src/ReplicatedStorage/OK/Modules/Format")
local E = require("./economy_fixture")

local fails = {}
local function ok(name, cond) if not cond then table.insert(fails, name) end end
local function eq(name, got, want)
	if got ~= want then table.insert(fails, string.format("%s: expected %s, got %s", name, tostring(want), tostring(got))) end
end

local function isInt(n) return type(n) == "number" and n == math.floor(n) end
local function isStr(s) return type(s) == "string" and #s > 0 end
local function intIn(n, lo, hi) return isInt(n) and n >= lo and n <= hi end
-- text with every {token} removed (so case checks ignore {name:navx} and {sponsor})
local function bare(s) return (string.gsub(s, "{[^}]*}", "")) end

-- apron, headset and lanyard are Wave 1a's new looks (Task 5 adds them to Visitor.SIGS); Task 0 owns these two lists
local SIGS = { cowboy_hat = true, bat_ears = true, spiky_hair = true, blob_hat = true, helmet = true, llama_ears = true,
	sparkle_cape = true, owl_hood = true, green_roots = true, suit = true, cap = true, headphones = true, none = true,
	apron = true, headset = true, lanyard = true }
local KINDS = { artist = true, rep = true, blogger = true, fan = true, rival = true, manager = true,
	mom = true, booker = true, coordinator = true, weird = true, critter = true, ["local"] = true, sender = true }
-- the 14 visitors before Wave 1; every visitor added since carries `check`, its note in the names web-check file
local ORIGINALS = { "navx", "dojabat", "icespike", "charti", "scoot", "llama", "drift", "drizzle", "eyelash",
	"rep", "blogger", "fan", "rival", "manager" }
local ROLES = { "rep", "blogger", "fan", "rival", "manager" } -- one of each among the originals
-- the names web-check files a `check` may point into: Wave 1a's, and the fiction pass's (Task 5b: the starter pool's people)
local CHECK_PATTERNS = { "^research/wave1_names_2026%-10%-27%.md#.+", "^research/fiction_pass_2026%-11%-06%.md#.+" }
local function checkNote(s)
	if type(s) ~= "string" then return false end
	for _, pat in ipairs(CHECK_PATTERNS) do if string.find(s, pat) then return true end end
	return false
end
local GATE_KEYS = { aura = true, followers = true, placements = true, hits = true, sponsors = true, money = true, visits = true }
local SOURCES = { walkin = true, phone = true }
local APPS = { MESSAGES = true, NEWS = true, STUDIO = true }
local CAP_PER = { day = true, week = true }
-- the most one phone outcome may add: Config.Career.Sources.Phone's per-award maxes (aura.max, followers.max), the
-- only stats the Phone source registers. The spec can't load Config; t46_check asserts the live values equal these
local PHONE_CAPS = { aura = 60, followers = 2000 }
local TONES = { win = true, loss = true, neutral = true }
local APPROVED = { "LIL NAV X", "DOJA BAT", "ICE SPIKE", "PLAYDOH CHARTI", "TRAVIS SCOOT", "KENDRICK LLAMA", "TAYLOR DRIFT",
	"DRIZZLE", "BILLIE EYELASH" }
local REAL = { "lil nas x", "doja cat", "ice spice", "playboi carti", "travis scott", "kendrick lamar", "taylor swift", "drake",
	"billie eilish", "red bull", "nike", "beats by dre", "spotify", "rolex", "prime hydration", "playboy" }
-- titles the country-trap visitor's theme invites: the parodied artist's own songs ("Rodeo" is also the album of the
-- artist TRAVIS SCOOT parodies). Checked as substrings over the whole module and both rosters' names, like REAL.
local TITLES = { "rodeo", "old town road" }
local BLOCK = { "weed", "drug", "drugs", "pill", "pills", "lean", "perc", "xan", "coke", "alcohol", "beer", "vodka", "liquor",
	"drunk", "gun", "glock", "shoot", "kill", "sex", "nude", "casino", "bet", "gamble", "onlyfans" }
local ROSTERS = { "parody", "fiction" }
local OUTCOME_KEYS = { "good", "bad", "rare" }
-- every key an Outcome or a Choice may carry (two sessions, Task 1): any other key fails, so a typo or a field nothing
-- applies (xp before its plumbing, say) can't pass silently. `tag` is listed so its own must-be-absent rule reports it
local OUTCOME_FIELDS = { key = true, headline = true, text = true, line = true, tone = true, money = true, aura = true,
	followers = true, placements = true, hits = true, sponsors = true, sponsor = true, note = true, cooldown = true,
	plant = true, tag = true, xp = true, disco = true, rel = true }
-- Wave 3 (design 4.3, copy doc 9.1 #3): an outcome's relationship write `rel = { who?, score?, flag?, clear? }`
-- (WalkInRules.RelWrite): who = a visitor (default: the card's own), score a whole step within -3..3 (never 0), flag /
-- clear a flag name. A write with none of score, flag or clear does nothing, so the validator refuses one
local REL_FIELDS = { who = true, score = true, flag = true, clear = true }
local FLAG_PATTERN = "^[%w_]+$"
-- Wave 3 (design 4.1): `beat = true` (the best beat tilts the roll) and `beatMin` (no roll: good when the best beat's
-- quality reaches it, copy doc 9.1 #9) are choice fields too
local CHOICE_FIELDS = { text = true, cost = true, sure = true, odds = true, good = true, bad = true, rare = true,
	rareOdds = true, ready = true, beat = true, beatMin = true }
-- the choices `beat = true` flags today (design 4.1, counted from the data: the walk-in card choices whose good outcome
-- pays a placement), "card:choice"; Task 5's two new placement cards join this list
local BEAT_CHOICES = { "navx_placement:1", "dojabat_pitch:1", "icespike_pitch:1", "charti_pitch:1", "scoot_pitch:1",
	"llama_pitch:1", "drift_pitch:1", "drizzle_pitch:1", "eyelash_pitch:1", "rival_beat:3", "rival_collab:1", "homekid_album:1" }
local BEAT_TOKEN = "{beat}"
-- the cards only a server path sends (`system = true`, Wave 3): the cold spell's one NEWS card, Phone.SendSystem's
local SYSTEM_CARDS = { cold_news = true }
-- how many times `token` appears in s (plain text)
local function count(s, token)
	local n, at = 0, 1
	while type(s) == "string" do
		local i = string.find(s, token, at, true)
		if not i then break end
		n += 1
		at = i + #token
	end
	return n
end
-- the most XP one phone outcome may pay: Config.XP.Sources.Phone.max, read from economy_fixture.XP_PHONE (the spec
-- can't load Config; build/t46_check.lua diffs the fixture against the live value)
local PHONE_XP_MAX = E.XP_PHONE.max

-- module shape and indexes -------------------------------------------------------------------------------------------
for _, k in ipairs({ "Visitors", "Sponsors", "Cards", "Followups", "VisitorById", "CardById", "FollowupById", "SponsorById", "Deck" }) do
	ok("W." .. k .. " is a table", type(W[k]) == "table")
end
ok("W.Names is a function", type(W.Names) == "function")
ok("W.SponsorName is a function", type(W.SponsorName) == "function")

local function indexed(list, byId, what)
	local seen, n = {}, 0
	for i, item in ipairs(list) do
		ok(what .. " " .. i .. " has an id", isStr(item.id))
		ok(what .. " id unique: " .. tostring(item.id), not seen[item.id])
		seen[item.id] = true
		eq(what .. "ById[" .. tostring(item.id) .. "]", byId[item.id], item)
	end
	for _ in pairs(byId) do n += 1 end
	eq(what .. "ById size", n, #list)
end
indexed(W.Visitors, W.VisitorById, "Visitor")
indexed(W.Sponsors, W.SponsorById, "Sponsor")
indexed(W.Cards, W.CardById, "Card")
indexed(W.Followups, W.FollowupById, "Followup")
eq("Deck.cards is Cards", W.Deck.cards, W.Cards)
eq("Deck.followups is FollowupById", W.Deck.followups, W.FollowupById)
eq("Deck.visitors is VisitorById", W.Deck.visitors, W.VisitorById)
local nDeckSponsors = 0
for _ in pairs(W.Deck.sponsors) do nDeckSponsors += 1 end
eq("Deck.sponsors size", nDeckSponsors, #W.Sponsors)
for _, s in ipairs(W.Sponsors) do eq("Deck.sponsors[" .. s.id .. "] is its floor", W.Deck.sponsors[s.id], s.floor) end

-- visitors -----------------------------------------------------------------------------------------------------------
ok("at least 14 visitors", #W.Visitors >= 14)
local isOriginal = {}
for _, id in ipairs(ORIGINALS) do
	isOriginal[id] = true
	ok("original visitor " .. id .. " present", W.VisitorById[id] ~= nil)
end
local kindCount, originalKinds = {}, {}
for _, v in ipairs(W.Visitors) do
	ok("visitor " .. v.id .. " kind", KINDS[v.kind] == true)
	kindCount[v.kind] = (kindCount[v.kind] or 0) + 1
	if isOriginal[v.id] then originalKinds[v.kind] = (originalKinds[v.kind] or 0) + 1 end
	ok("visitor " .. v.id .. " names", type(v.names) == "table" and isStr(v.names.parody) and isStr(v.names.fiction))
	ok("visitor " .. v.id .. " style", isStr(v.style))
	ok("visitor " .. v.id .. " sig in the Shared-shapes list", SIGS[v.sig] == true)
	ok("visitor " .. v.id .. " color is 3 integers 0..255", type(v.color) == "table" and #v.color == 3
		and intIn(v.color[1], 0, 255) and intIn(v.color[2], 0, 255) and intIn(v.color[3], 0, 255))
	if v.kind == "sender" then eq("visitor " .. v.id .. " (sender, no figure) sig", v.sig, "none") end
	if not isOriginal[v.id] then
		ok("visitor " .. v.id .. " (new) check is research/wave1_names_2026-10-27.md#<anchor> or research/fiction_pass_2026-11-06.md#<anchor>",
			checkNote(v.check))
	end
end
eq("9 artists", kindCount.artist, 9)
for _, k in ipairs(ROLES) do eq("one " .. k .. " among the originals", originalKinds[k], 1) end
ok("visitor navx exists", W.VisitorById.navx ~= nil and W.VisitorById.navx.kind == "artist")
ok("visitor rep exists", W.VisitorById.rep ~= nil and W.VisitorById.rep.kind == "rep")

-- sponsors -----------------------------------------------------------------------------------------------------------
eq("6 sponsors", #W.Sponsors, 6)
for _, s in ipairs(W.Sponsors) do
	ok("sponsor " .. s.id .. " names", type(s.names) == "table" and isStr(s.names.parody) and isStr(s.names.fiction))
	ok("sponsor " .. s.id .. " kind", isStr(s.kind))
	ok("sponsor " .. s.id .. " floor 100..400", intIn(s.floor, 100, 400))
	eq("SponsorName parody " .. s.id, W.SponsorName(s.id, "parody"), s.names.parody)
	eq("SponsorName fiction " .. s.id, W.SponsorName(s.id, "fiction"), s.names.fiction)
end

-- names: both rosters cover every visitor, the approved nine, rosters don't share a name ---------------------------------
for _, roster in ipairs(ROSTERS) do
	local names = W.Names(roster)
	local n, seen = 0, {}
	for _ in pairs(names) do n += 1 end
	eq("Names(" .. roster .. ") covers every visitor", n, #W.Visitors)
	for _, v in ipairs(W.Visitors) do
		ok("Names(" .. roster .. ")." .. v.id, isStr(names[v.id]))
		local key = string.lower(names[v.id] or "")
		ok("Names(" .. roster .. ") unique: " .. key, not seen[key])
		seen[key] = true
	end
	ok("rep's " .. roster .. " name uses {sponsor}", string.find(names.rep or "", "{sponsor}", 1, true) ~= nil)
end
do
	local parody, want, got = W.Names("parody"), {}, {}
	for _, name in ipairs(APPROVED) do want[name] = true end
	for _, v in ipairs(W.Visitors) do
		if v.kind == "artist" then
			ok("parody artist name approved: " .. tostring(parody[v.id]), want[parody[v.id]] == true)
			got[parody[v.id]] = true
		end
	end
	for _, name in ipairs(APPROVED) do ok("approved name used: " .. name, got[name] == true) end
end
local parodyNames, fictionNames, allNames = {}, {}, {}
for _, v in ipairs(W.Visitors) do
	table.insert(parodyNames, v.names.parody)
	table.insert(fictionNames, v.names.fiction)
end
for _, s in ipairs(W.Sponsors) do
	table.insert(parodyNames, s.names.parody)
	table.insert(fictionNames, s.names.fiction)
end
for _, f in ipairs(fictionNames) do
	for _, p in ipairs(parodyNames) do ok("fiction name equals a parody name: " .. f, string.lower(f) ~= string.lower(p)) end
end
for _, name in ipairs(parodyNames) do table.insert(allNames, name) end
for _, name in ipairs(fictionNames) do table.insert(allNames, name) end

-- every Outcome / Choice ---------------------------------------------------------------------------------------------
-- `xpOk`: the outcome is a phone card's, the only place xp may go until walk-ins wire it (ruling "XP only on phone
-- items"); checkPhoneOutcome holds it to 0..PHONE_XP_MAX
local function checkOutcome(where, o, xpOk)
	if type(o) ~= "table" then ok(where .. " is an Outcome", false); return end
	for k in pairs(o) do ok(where .. " unknown outcome key " .. tostring(k), OUTCOME_FIELDS[k] == true) end
	for _, k in ipairs({ "key", "headline", "text", "line" }) do ok(where .. "." .. k, isStr(o[k])) end
	ok(where .. ".tone", TONES[o.tone] == true)
	ok(where .. " xp only on phone items (a phone card's outcome)", o.xp == nil or xpOk == true)
	for _, k in ipairs({ "money", "aura", "followers", "placements", "hits", "sponsors", "xp" }) do
		ok(where .. "." .. k .. " whole", o[k] == nil or isInt(o[k]))
	end
	ok(where .. " money <= 2000", (o.money or 0) <= 2000)
	ok(where .. " money >= -300", (o.money or 0) >= -300)
	ok(where .. " aura within 500", math.abs(o.aura or 0) <= 500)
	ok(where .. " followers within 20000", math.abs(o.followers or 0) <= 20000)
	for _, k in ipairs({ "placements", "hits", "sponsors" }) do ok(where .. " " .. k .. " within 1", math.abs(o[k] or 0) <= 1) end
	ok(where .. ".note", o.note == nil or isStr(o.note))
	ok(where .. ".cooldown", o.cooldown == nil or intIn(o.cooldown, 1, 50))
	ok(where .. ".tag absent (tags come from TagFor)", o.tag == nil)
	if o.plant ~= nil then
		ok(where .. ".plant resolves", type(o.plant) == "table" and W.FollowupById[o.plant.id] ~= nil)
		local at = type(o.plant) == "table" and o.plant.at
		ok(where .. ".plant.at", not at or (isInt(at[1]) and isInt(at[2]) and at[1] >= 1 and at[1] <= at[2]))
		ok(where .. " plants not sponsor_drop", type(o.plant) ~= "table" or o.plant.id ~= "sponsor_drop")
	end
	ok(where .. " headline is caps", o.headline == nil or bare(o.headline) == string.upper(bare(o.headline)))
	ok(where .. " line is lowercase", o.line == nil or bare(o.line) == string.lower(bare(o.line)))
	if o.rel ~= nil then
		local r = o.rel
		ok(where .. ".rel is a table", type(r) == "table")
		if type(r) == "table" then
			for k in pairs(r) do ok(where .. ".rel unknown key " .. tostring(k), REL_FIELDS[k] == true) end
			ok(where .. ".rel.who is a visitor", r.who == nil or (type(r.who) == "string" and W.VisitorById[r.who] ~= nil))
			ok(where .. ".rel.score whole -3..3, not 0", r.score == nil or (intIn(r.score, -3, 3) and r.score ~= 0))
			for _, f in ipairs({ "flag", "clear" }) do
				ok(where .. ".rel." .. f .. " is a flag name", r[f] == nil or (type(r[f]) == "string" and string.match(r[f], FLAG_PATTERN) ~= nil))
			end
			ok(where .. ".rel writes something (score, flag or clear; who alone is a no-op)", r.score ~= nil or r.flag ~= nil or r.clear ~= nil)
		end
	end
end

local function eachOutcome(choice, fn)
	for _, k in ipairs(OUTCOME_KEYS) do
		if choice[k] ~= nil then fn(choice[k], k) end
	end
end

-- a phone NEWS card (`news`) has its one choice, checked below (design 4.1: NEWS has no choice, its effects apply on
-- arrival); every other card and follow-up has 2..4. A sponsor quiz (`quiz`) skips only the sure-payout quote (see
-- the quiz check in the card loop)
local function checkChoices(where, choices, news, quiz, xpOk)
	if news then
		ok(where .. " (news) has exactly one choice", type(choices) == "table" and #choices == 1)
	else
		ok(where .. " has 2..4 choices", type(choices) == "table" and #choices >= 2 and #choices <= 4)
	end
	local free = false
	for i, c in ipairs(choices or {}) do
		local cw = where .. " choice " .. i
		for k in pairs(c) do ok(cw .. " unknown choice key " .. tostring(k), CHOICE_FIELDS[k] == true) end
		ok(cw .. ".text", isStr(c.text))
		ok(cw .. ".cost 1..1500", c.cost == nil or intIn(c.cost, 1, 1500))
		ok(cw .. ".sure", c.sure == nil or type(c.sure) == "boolean")
		ok(cw .. ".odds 1..100", c.odds == nil or intIn(c.odds, 1, 100))
		ok(cw .. ".odds 10..90 (design 6 content validator)", c.odds == nil or intIn(c.odds, 10, 90))
		ok(cw .. " has good", type(c.good) == "table")
		ok(cw .. " not sure has bad", c.sure or type(c.bad) == "table")
		ok(cw .. " rare and rareOdds together", (c.rare == nil) == (c.rareOdds == nil))
		ok(cw .. ".rareOdds 1..100", c.rareOdds == nil or intIn(c.rareOdds, 1, 100))
		-- a `ready` choice (two sessions): its chance is readiness's (WalkInRules.ChoiceChance), so no odds, never sure,
		-- no rare, and it rolls between a good and a bad outcome
		ok(cw .. ".ready is true or absent", c.ready == nil or c.ready == true)
		if c.ready ~= nil then
			ok(cw .. " (ready) has no odds", c.odds == nil)
			ok(cw .. " (ready) is not sure", c.sure == nil)
			ok(cw .. " (ready) has no rare", c.rare == nil and c.rareOdds == nil)
			ok(cw .. " (ready) has good and bad", type(c.good) == "table" and type(c.bad) == "table")
		end
		-- Wave 3 (design 4.1): a `beat` choice rolls with the best beat's tilt, so it is a rolled choice (never sure, never
		-- decided by beatMin). A `beatMin` choice never rolls: good when the best beat's quality (0..4) reaches it, else bad
		-- (copy doc 9.1 #9), so no odds, sure, ready or rare, and both outcomes
		ok(cw .. ".beat is true or absent", c.beat == nil or c.beat == true)
		if c.beat ~= nil then
			ok(cw .. " (beat) is not sure", c.sure == nil)
			ok(cw .. " (beat) has no beatMin", c.beatMin == nil)
		end
		ok(cw .. ".beatMin whole 1..4", c.beatMin == nil or intIn(c.beatMin, 1, 4))
		if c.beatMin ~= nil then
			ok(cw .. " (beatMin) has no odds", c.odds == nil)
			ok(cw .. " (beatMin) is not sure", c.sure == nil)
			ok(cw .. " (beatMin) is not ready", c.ready == nil)
			ok(cw .. " (beatMin) has no rare", c.rare == nil and c.rareOdds == nil)
			ok(cw .. " (beatMin) has good and bad", type(c.good) == "table" and type(c.bad) == "table")
		end
		if c.cost == nil then free = true end
		-- money shows on the button when a choice pays a fixed amount (design 4.2): a sure payout is quoted in
		-- Format.Money style, and every "$N" in the text is that choice's good.money or its cost, so a retune
		-- (Task 9) can't leave the copy saying one number and the outcome paying another
		local payout = type(c.good) == "table" and c.good.money or 0
		if c.sure and payout > 0 and not quiz then
			ok(cw .. " sure payout quoted as " .. F.Money(payout),
				isStr(c.text) and string.find(c.text, F.Money(payout), 1, true) ~= nil)
		end
		for amount in string.gmatch(type(c.text) == "string" and c.text or "", "%$([%d,]+)") do
			local n = tonumber((string.gsub(amount, ",", "")))
			ok(cw .. " text '$" .. amount .. "' is its good.money or cost", n ~= nil and (n == payout or n == c.cost))
		end
		eachOutcome(c, function(o, k)
			checkOutcome(cw .. "." .. k, o, xpOk)
			if c.cost == nil then ok(cw .. "." .. k .. " free-choice money >= -300", (o.money or 0) >= -300) end
		end)
	end
	ok(where .. " has a choice without a cost", free)
end

-- a phone item (source = "phone": every phone card, every phone follow-up) moves Aura and Followers only (design 4.8,
-- Shared shapes "Outcomes"): money only through a choice's cost, no placement, hit or sponsor (the Phone career source
-- registers none, so Career.Add would pay 0 and log [OK][ERR]), and a gain within the Phone source's maxes. Losses keep
-- checkOutcome's bands (they go through Career.Take)
local function checkPhoneOutcome(where, o)
	ok(where .. " money 0 (phone money moves only through a choice cost)", (o.money or 0) == 0)
	for _, k in ipairs({ "placements", "hits", "sponsors" }) do ok(where .. " " .. k .. " 0 (Aura and Followers only)", (o[k] or 0) == 0) end
	ok(where .. " no sponsor (no signing, no drop)", o.sponsor == nil)
	for _, k in ipairs({ "aura", "followers" }) do
		ok(where .. " " .. k .. " <= Phone.max " .. PHONE_CAPS[k], (o[k] or 0) <= PHONE_CAPS[k])
	end
	ok(where .. " xp >= 0", (o.xp or 0) >= 0)
	ok(where .. " xp <= " .. PHONE_XP_MAX .. " (Config.XP.Sources.Phone.max)", (o.xp or 0) <= PHONE_XP_MAX)
end
local function checkPhoneChoices(where, choices)
	for i, c in ipairs(choices or {}) do
		eachOutcome(c, function(o, k) checkPhoneOutcome(where .. " choice " .. i .. "." .. k, o) end)
	end
end

-- mom and the starter pool (`first` cards; Task 5b+) can't cost you money (design 2, 4.3): no choice has a cost, and no
-- outcome takes money or reads as a loss
local function checkGentle(where, choices, resolve)
	local function outcome(ow, o)
		ok(ow .. " money >= 0", (o.money or 0) >= 0)
		ok(ow .. " tone is not loss", o.tone ~= "loss")
	end
	for i, c in ipairs(choices or {}) do
		ok(where .. " choice " .. i .. " has no cost", c.cost == nil)
		eachOutcome(c, function(o, k) outcome(where .. " choice " .. i .. "." .. k, o) end)
	end
	if type(resolve) == "table" then
		for _, k in ipairs({ "good", "bad" }) do outcome(where .. ".resolve." .. k, resolve[k] or {}) end
	end
end

-- needs / under: GateKey = number; an unknown key fails, so a typo can't quietly make a card unreachable. Wave 3
-- (design 4.3, copy doc 9.1 #4): `flags`, a non-empty list of "who.flag" ids (who a visitor; set / not set, and some
-- outcome must set it: relFails below), and `rel`, the card's own visitor's score, whole -2..3 (needs: >= n, under:
-- < n, so under = { rel = -1 } is "-2 or lower"; -3 and 4 would make a card that can never or always pass)
local function checkGates(where, gates, field)
	if gates == nil then return end
	ok(where .. "." .. field .. " is a table", type(gates) == "table")
	if type(gates) ~= "table" then return end
	for k, n in pairs(gates) do
		local gw = where .. "." .. field .. "." .. tostring(k)
		if k == "flags" then
			ok(gw .. " is a non-empty list", type(n) == "table" and #n > 0)
			for i, id in ipairs(type(n) == "table" and n or {}) do
				local who, flag = nil, nil
				if type(id) == "string" then who, flag = string.match(id, "^([%w_]+)%.([%w_]+)$") end
				ok(gw .. "[" .. i .. "] '" .. tostring(id) .. "' is who.flag with who a visitor", who ~= nil and flag ~= nil and W.VisitorById[who] ~= nil)
			end
		elseif k == "rel" then
			ok(gw .. " whole -2..3", intIn(n, -2, 3))
		else
			ok(where .. "." .. field .. " key " .. tostring(k) .. " is a GateKey", GATE_KEYS[k] == true)
			ok(gw .. " whole >= 0", isInt(n) and n >= 0)
		end
	end
end

-- cards --------------------------------------------------------------------------------------------------------------
-- checkCard: every rule for one card (shape, fields, gates, cap, choices and their outcomes), appending to `fails`. It
-- runs over the live deck below and over the scratch cards that prove the validator's rules
local repCards = {}
local function checkCard(card)
	local where = "card " .. card.id
	local v = W.VisitorById[card.visitor]
	ok(where .. " visitor resolves", v ~= nil)
	ok(where .. ".tag", isStr(card.tag) and bare(card.tag) == string.upper(bare(card.tag)))
	ok(where .. ".line", isStr(card.line) and bare(card.line) == string.lower(bare(card.line)))
	ok(where .. ".weight whole >= 1", card.weight == nil or (isInt(card.weight) and card.weight >= 1))
	ok(where .. ".minCount whole >= 0", card.minCount == nil or (isInt(card.minCount) and card.minCount >= 0))
	ok(where .. ".when", card.when == nil or card.when == "unsponsored" or card.when == "sponsored")
	ok(where .. ".sponsor resolves", card.sponsor == nil or W.SponsorById[card.sponsor] ~= nil)
	if v and v.kind == "rep" then
		-- a rep card is a deal on offer (its sponsor, while you hold none) or, Wave 3 (design 4.3, copy doc 9.1 #5), the rep
		-- of the deal you hold (`when = "sponsored"`, no sponsor of its own: {sponsor} is Career's)
		ok(where .. " (rep) offers its sponsor while unsponsored, or is the held deal's rep (sponsored, no sponsor)",
			(card.sponsor ~= nil and card.when == "unsponsored") or (card.sponsor == nil and card.when == "sponsored"))
		if card.sponsor then repCards[card.sponsor] = true end
	end
	-- Wave 1a fields (Shared shapes): source, app (phone only, required there), news, needs/under, cap, first
	ok(where .. ".source walkin|phone", card.source == nil or SOURCES[card.source] == true)
	local phone = card.source == "phone"
	if phone then
		ok(where .. " (phone) app MESSAGES|NEWS|STUDIO", APPS[card.app] == true)
	else
		ok(where .. " app only on phone cards", card.app == nil)
	end
	ok(where .. ".news is true or absent", card.news == nil or card.news == true)
	-- Wave 3 (design 4.2, copy doc 9.1 #10): a `system` card is never drawn (WalkInRules.Seed / Pick skip it); only a
	-- server path sends it (Phone.SendSystem), so it is a phone NEWS card, and exactly the ids SYSTEM_CARDS lists
	ok(where .. ".system is true or absent", card.system == nil or card.system == true)
	if card.system then
		ok(where .. " (system) is a phone NEWS card", phone and card.news == true and card.app == "NEWS")
		ok(where .. " (system) is one SYSTEM_CARDS lists", SYSTEM_CARDS[card.id] == true)
	end
	if card.news then
		ok(where .. " (news) is a phone card with app NEWS", phone and card.app == "NEWS")
		local c = type(card.choices) == "table" and card.choices[1] or {}
		ok(where .. " (news) choice is sure", c.sure == true)
		ok(where .. " (news) choice has no cost", c.cost == nil)
		ok(where .. " (news) choice has no rare", c.rare == nil)
	end
	checkGates(where, card.needs, "needs")
	checkGates(where, card.under, "under")
	if card.cap ~= nil then
		local cap = card.cap
		ok(where .. ".cap is a table", type(cap) == "table")
		if type(cap) == "table" then
			ok(where .. ".cap.group is a string", isStr(cap.group))
			ok(where .. ".cap.per day|week", CAP_PER[cap.per] == true)
			ok(where .. ".cap.max whole >= 1", isInt(cap.max) and cap.max >= 1)
		end
	end
	if phone then checkPhoneChoices(where .. " (phone)", card.choices) end
	if v and v.kind == "mom" then checkGentle(where .. " (mom)", card.choices) end
	if card.first then checkGentle(where .. " (first)", card.choices) end
	-- the sponsor quiz (design 8.3): quoting the bonus on the right answer would give it away, so quiz_* cards skip the
	-- sure-payout quote; instead no answer types an amount and the card's line quotes the one right answer's bonus
	local quiz = string.find(card.id, "^quiz_") ~= nil
	checkChoices(where, card.choices, card.news, quiz, phone)
	-- Wave 3 (design 4.1): your beat. Only a walk-in card's choice carries `beat` or `beatMin` (a phone card never does),
	-- and on a walk-in card a choice carries `beat` exactly when its good outcome pays a placement. Each beat or beatMin
	-- choice has {beat} in the card's line or its own text, and the card says it exactly once (no render says "something"
	-- twice); a card with no such choice, every tag, every other choice text and every outcome never says it (Fill fills it
	-- from the best beat, so it only reads on the card it decides)
	local flagged, beats = {}, count(card.line, BEAT_TOKEN)
	for i, c in ipairs(card.choices or {}) do
		local cw = where .. " choice " .. i
		local pays = type(c.good) == "table" and (c.good.placements or 0) > 0
		if phone then
			ok(cw .. " (phone) has no beat or beatMin", c.beat == nil and c.beatMin == nil)
		else
			ok(cw .. " beat exactly when its good pays a placement", (c.beat == true) == pays)
		end
		if c.beat or c.beatMin then
			table.insert(flagged, c)
			beats += count(c.text, BEAT_TOKEN)
			ok(cw .. " (beat) has {beat} in the card's line or its own text", count(card.line, BEAT_TOKEN) + count(c.text, BEAT_TOKEN) > 0)
		else
			ok(cw .. " text has no {beat} (not a beat or beatMin choice)", count(c.text, BEAT_TOKEN) == 0)
		end
		eachOutcome(c, function(o, k)
			for _, f in ipairs({ "headline", "text", "line", "note" }) do
				ok(cw .. "." .. k .. "." .. f .. " has no {beat}", count(o[f], BEAT_TOKEN) == 0)
			end
		end)
	end
	if #flagged > 0 then
		ok(where .. " (beat) says {beat} exactly once", beats == 1)
	else
		ok(where .. " has no {beat} (no beat or beatMin choice)", beats == 0)
	end
	ok(where .. " tag has no {beat}", count(card.tag, BEAT_TOKEN) == 0)
	if quiz then
		local rights, typed = {}, false
		for _, c in ipairs(card.choices or {}) do
			if type(c.good) == "table" and c.good.sponsor ~= nil then table.insert(rights, c) end
			if type(c.text) == "string" and string.find(c.text, "$", 1, true) then typed = true end
		end
		local money = #rights == 1 and F.Money(rights[1].good.money or 0) or "?"
		ok(where .. " (quiz) has one right answer, no answer types an amount, and its line quotes the bonus " .. money,
			#rights == 1 and not typed and isStr(card.line) and string.find(card.line, money, 1, true) ~= nil)
	end
	for i, c in ipairs(card.choices or {}) do
		eachOutcome(c, function(o, k)
			local ow = where .. " choice " .. i .. "." .. k
			ok(ow .. " hits only in follow-ups", (o.hits or 0) == 0)
			ok(ow .. " placements in cards are 0 or +1", (o.placements or 0) == 0 or o.placements == 1)
			ok(ow .. " no sponsor drop in cards", o.sponsor ~= "drop")
			if o.sponsor ~= nil then
				ok(ow .. " signs only on unsponsored cards", card.when == "unsponsored")
				eq(ow .. " signs the card's sponsor", o.sponsor, card.sponsor)
				eq(ow .. " signing adds one sponsor", o.sponsors, 1)
			end
			if (o.sponsors or 0) == 1 then ok(ow .. " +1 sponsor names the sponsor", o.sponsor ~= nil and o.sponsor ~= "drop") end
			ok(ow .. " no sponsor loss on cards", (o.sponsors or 0) >= 0)
		end)
	end
end
for _, card in ipairs(W.Cards) do checkCard(card) end
for _, s in ipairs(W.Sponsors) do ok("sponsor " .. s.id .. " has a rep card", repCards[s.id] == true) end

-- scratch cards (two sessions, Task 1): each runs through checkCard; its new failures must include the named message
-- (none at all for a valid card), then `fails` is truncated back so a scratch card never fails the live deck
local function scratch(name, card, want)
	local n = #fails
	checkCard(card)
	local got = {}
	for i = n + 1, #fails do table.insert(got, fails[i]) end
	for i = #fails, n + 1, -1 do fails[i] = nil end
	if want == nil then
		ok("scratch " .. name .. " passes, got: " .. table.concat(got, " | "), #got == 0)
		return
	end
	local hit = false
	for _, f in ipairs(got) do if string.find(f, want, 1, true) then hit = true end end
	ok("scratch " .. name .. " fails '" .. want .. "', got: " .. table.concat(got, " | "), hit)
end
local function sOutcome(key, tone, extra)
	local o = { key = key, headline = "HEADLINE", text = "text.", line = "a line.", tone = tone }
	for k, v in pairs(extra or {}) do o[k] = v end
	return o
end
-- a valid two-choice phone DM: a sure choice and a `ready` one (no odds, sure or rare; good and bad)
local function readyDM(c1extra, c2extra)
	local c1 = { text = "take the first", sure = true, good = sOutcome("home", "win", { aura = 20, xp = 40 }) }
	local c2 = { text = "take the second", ready = true, good = sOutcome("localhit", "win", { followers = 1500, xp = 10 }),
		bad = sOutcome("blewup", "loss", { aura = -30 }) }
	for k, v in pairs(c1extra or {}) do c1[k] = v end
	for k, v in pairs(c2extra or {}) do c2[k] = v end
	return { id = "scratch_dm", visitor = "unknown", source = "phone", app = "MESSAGES", tag = "SCRATCH · TODAY ONLY",
		line = "a scratch line.", choices = { c1, c2 } }
end
local function walkinCard(goodExtra)
	return { id = "scratch_walkin", visitor = "navx", tag = "SCRATCH", line = "a scratch line.", choices = {
		{ text = "one", odds = 50, good = sOutcome("g", "win", goodExtra or { aura = 10 }), bad = sOutcome("b", "loss", { aura = -10 }) },
		{ text = "two", sure = true, good = sOutcome("s", "win", { aura = 5 }) },
	} }
end
scratch("valid walk-in card", walkinCard(), nil)
scratch("xp on a walk-in outcome", walkinCard({ aura = 10, xp = 5 }), "xp only on phone items")
scratch("valid ready DM", readyDM(), nil)
scratch("xp 61 on a phone outcome", readyDM({ good = sOutcome("home", "win", { aura = 20, xp = 61 }) }), "xp <= 60")
scratch("xp -1 on a phone outcome", readyDM({ good = sOutcome("home", "win", { aura = 20, xp = -1 }) }), "xp >= 0")
scratch("xp 2.5 on a phone outcome", readyDM({ good = sOutcome("home", "win", { aura = 20, xp = 2.5 }) }), ".xp whole")
scratch("unknown outcome key", readyDM({ good = sOutcome("home", "win", { aura = 20, xpp = 5 }) }), "unknown outcome key xpp")
scratch("unknown choice key", readyDM({ odd = 40 }), "unknown choice key odd")
scratch("ready choice with odds", readyDM(nil, { odds = 50 }), "(ready) has no odds")
scratch("ready choice with sure", readyDM(nil, { sure = true }), "(ready) is not sure")
scratch("ready choice with rare", readyDM(nil, { rare = sOutcome("r", "win", { aura = 5 }), rareOdds = 5 }), "(ready) has no rare")
do
	local noBad = readyDM()
	noBad.choices[2].bad = nil
	scratch("ready choice without bad", noBad, "(ready) has good and bad")
end
scratch("ready not true", readyDM(nil, { ready = 1 }), ".ready is true or absent")

-- Wave 3 (design 4.1): a valid walk-in card with a beat choice (choice 1 pays a placement and carries beat; the line says
-- {beat}), and one decided by beatMin (choice 1's own text says {beat}; its good pays no placement). `edit` changes the
-- built card before the check (nil values can't ride in an extras table)
local function beatCard(edit)
	local card = { id = "scratch_beat", visitor = "navx", tag = "SCRATCH", line = "play me {beat}.", choices = {
		{ text = "one", odds = 50, beat = true, good = sOutcome("g", "win", { placements = 1, aura = 10 }), bad = sOutcome("b", "loss", { aura = -10 }) },
		{ text = "two", sure = true, good = sOutcome("s", "win", { aura = 5 }) },
	} }
	if edit then edit(card) end
	return card
end
local function beatMinCard(edit)
	local card = { id = "scratch_beatmin", visitor = "rival", tag = "SCRATCH", line = "a scratch line.", choices = {
		{ text = "answer it with {beat}.", beatMin = 3, good = sOutcome("won", "win", { aura = 20 }), bad = sOutcome("lost", "loss", { aura = -30 }) },
		{ text = "two", sure = true, good = sOutcome("s", "win", { aura = 5 }) },
	} }
	if edit then edit(card) end
	return card
end
scratch("valid beat card", beatCard(), nil)
scratch("valid beatMin card", beatMinCard(), nil)
scratch("beat on a sure choice", beatCard(function(c) c.choices[1].sure = true; c.choices[1].odds = nil end), "(beat) is not sure")
scratch("beat not true", beatCard(function(c) c.choices[1].beat = 1 end), ".beat is true or absent")
scratch("a placement choice without beat", beatCard(function(c) c.choices[1].beat = nil end), "beat exactly when its good pays a placement")
scratch("beat on a choice that pays no placement", beatCard(function(c) c.choices[1].good.placements = nil end), "beat exactly when its good pays a placement")
scratch("a beat card without {beat}", beatCard(function(c) c.line = "play me something." end), "(beat) has {beat} in the card's line or its own text")
scratch("{beat} twice", beatCard(function(c) c.choices[1].text = "send {beat}." end), "(beat) says {beat} exactly once")
scratch("{beat} on another choice's text", beatCard(function(c) c.choices[2].text = "keep {beat}." end), "text has no {beat} (not a beat or beatMin choice)")
scratch("{beat} in an outcome", beatCard(function(c) c.choices[1].good.text = "{beat} landed." end), "good.text has no {beat}")
scratch("{beat} in the tag", beatCard(function(c) c.tag = "SCRATCH {beat}" end), "tag has no {beat}")
scratch("{beat} on a card with no beat choice", beatCard(function(c) c.choices[1].beat = nil; c.choices[1].good.placements = nil end), "has no {beat} (no beat or beatMin choice)")
scratch("beat on a phone card", readyDM(nil, { beat = true }), "(phone) has no beat or beatMin")
scratch("beat with beatMin", beatCard(function(c) c.choices[1].beatMin = 3 end), "(beat) has no beatMin")
scratch("beatMin with odds", beatMinCard(function(c) c.choices[1].odds = 50 end), "(beatMin) has no odds")
scratch("beatMin 5", beatMinCard(function(c) c.choices[1].beatMin = 5 end), ".beatMin whole 1..4")
scratch("beatMin 2.5", beatMinCard(function(c) c.choices[1].beatMin = 2.5 end), ".beatMin whole 1..4")
scratch("beatMin sure", beatMinCard(function(c) c.choices[1].sure = true end), "(beatMin) is not sure")
scratch("beatMin ready", beatMinCard(function(c) c.choices[1].ready = true end), "(beatMin) is not ready")
scratch("beatMin with rare", beatMinCard(function(c) c.choices[1].rare = sOutcome("r", "win", { aura = 5 }); c.choices[1].rareOdds = 5 end), "(beatMin) has no rare")
scratch("beatMin without bad", beatMinCard(function(c) c.choices[1].bad = nil end), "(beatMin) has good and bad")

-- the beat choices today are exactly design 4.1's ten (BEAT_CHOICES), in deck order
do
	local got = {}
	for _, card in ipairs(W.Cards) do
		for i, c in ipairs(card.choices or {}) do if c.beat then table.insert(got, card.id .. ":" .. i) end end
	end
	eq("the beat = true choices (design 4.1's ten)", table.concat(got, ","), table.concat(BEAT_CHOICES, ","))
end

-- follow-ups ---------------------------------------------------------------------------------------------------------
for _, f in ipairs(W.Followups) do
	local where = "followup " .. f.id
	local v = W.VisitorById[f.visitor]
	ok(where .. " visitor resolves", v ~= nil)
	ok(where .. ".tag", isStr(f.tag) and bare(f.tag) == string.upper(bare(f.tag)))
	ok(where .. ".line", isStr(f.line) and bare(f.line) == string.lower(bare(f.line)))
	local r = f.resolve
	ok(where .. ".resolve", type(r) == "table" and intIn(r.odds, 1, 100))
	ok(where .. ".resolve.odds 10..90", type(r) == "table" and intIn(r.odds, 10, 90))
	if type(r) == "table" then
		for _, k in ipairs({ "good", "bad" }) do
			checkOutcome(where .. ".resolve." .. k, r[k])
			ok(where .. ".resolve." .. k .. " news money >= -300", ((r[k] or {}).money or 0) >= -300)
		end
	end
	if f.choices ~= nil then checkChoices(where, f.choices) end
	-- Wave 3 (design 4.1): follow-ups are untouched by the beat: no beat or beatMin choice, and no {beat} anywhere
	local fTexts = { f.tag, f.line }
	for _, k in ipairs({ "good", "bad" }) do
		local o = type(r) == "table" and r[k] or {}
		for _, fld in ipairs({ "headline", "text", "line", "note" }) do table.insert(fTexts, o[fld] or "") end
	end
	for i, c in ipairs(f.choices or {}) do
		ok(where .. " choice " .. i .. " has no beat or beatMin (follow-ups are untouched)", c.beat == nil and c.beatMin == nil)
		table.insert(fTexts, c.text or "")
		eachOutcome(c, function(o)
			for _, fld in ipairs({ "headline", "text", "line", "note" }) do table.insert(fTexts, o[fld] or "") end
		end)
	end
	for _, s in ipairs(fTexts) do ok(where .. " has no {beat}: " .. tostring(s), count(s, BEAT_TOKEN) == 0) end
	-- a phone follow-up pops as NEWS (its pop's app is always "NEWS", so it has no app of its own)
	ok(where .. ".source walkin|phone", f.source == nil or SOURCES[f.source] == true)
	ok(where .. " has no app", f.app == nil)
	if f.source == "phone" then
		if type(r) == "table" then
			for _, k in ipairs({ "good", "bad" }) do checkPhoneOutcome(where .. " (phone).resolve." .. k, r[k] or {}) end
		end
		checkPhoneChoices(where .. " (phone)", f.choices)
	end
	if v and v.kind == "mom" then checkGentle(where .. " (mom)", f.choices, r) end
	-- day-one payback (design 4.3: "+1 Placement, Aura, Followers"): a payback_* follow-up's news may give the
	-- placement, its choices may not. They are walk-in follow-ups; checkPhoneOutcome keeps every phone item at 0
	local payback = string.find(f.id, "^payback_") ~= nil
	local function rules(o, ow, news)
		if f.id ~= "sponsor_drop" then
			ok(ow .. " carries no sponsor", o.sponsor == nil)
			ok(ow .. " sponsors 0", (o.sponsors or 0) == 0)
		end
		ok(ow .. " hits are 0 or +1", (o.hits or 0) == 0 or o.hits == 1)
		-- a Hit pays royalties of $1,000..$2,000 (design 4.8, plan Task 4 money rules); pacing tunes the odds, not this
		if (o.hits or 0) > 0 then
			ok(ow .. " Hit royalty $" .. tostring(o.money or 0) .. " in 1000..2000", (o.money or 0) >= 1000 and (o.money or 0) <= 2000)
		end
		local p = o.placements or 0
		ok(ow .. " placements in follow-ups are 0, -1 (rival only) or +1 (payback news only)",
			p == 0 or (p == -1 and v ~= nil and v.kind == "rival") or (p == 1 and news == true and payback))
	end
	if type(r) == "table" then
		rules(r.good or {}, where .. ".resolve.good", true)
		rules(r.bad or {}, where .. ".resolve.bad", true)
	end
	for i, c in ipairs(f.choices or {}) do
		eachOutcome(c, function(o, k) rules(o, where .. " choice " .. i .. "." .. k) end)
	end
end

-- the overhead tag never contradicts the headline: every win or loss outcome, applied in full (with its choice's cost;
-- news has none), gets a TagFor tag in its own tone whose sign matches that tone, so TagFor's fallback never fires
local function checkTag(where, o, cost)
	if o.tone ~= "win" and o.tone ~= "loss" then return end
	local applied = { cost = cost or 0 }
	for _, k in ipairs({ "money", "aura", "followers", "placements", "hits", "sponsors" }) do applied[k] = o[k] or 0 end
	local text, tone = R.TagFor(applied, F, o.tone)
	ok(string.format("%s (%s) tag %s in tone %s", where, tostring(o.tone), tostring(text), tostring(tone)),
		tone == o.tone and text ~= nil and string.sub(text, 1, 1) == (o.tone == "win" and "+" or "-"))
end
local function checkChoiceTags(where, choices)
	for i, c in ipairs(choices or {}) do
		eachOutcome(c, function(o, k) checkTag(where .. " choice " .. i .. "." .. k, o, c.cost) end)
	end
end
for _, card in ipairs(W.Cards) do checkChoiceTags("card " .. card.id, card.choices) end
for _, f in ipairs(W.Followups) do
	for _, k in ipairs({ "good", "bad" }) do checkTag("followup " .. f.id .. ".resolve." .. k, f.resolve[k], 0) end
	checkChoiceTags("followup " .. f.id, f.choices)
end

-- sponsor_drop: generic, news only, never planted by an outcome
do
	local d = W.FollowupById.sponsor_drop
	ok("sponsor_drop exists", d ~= nil)
	if d then
		ok("sponsor_drop line uses {sponsor}", string.find(d.line, "{sponsor}", 1, true) ~= nil)
		for _, k in ipairs({ "good", "bad" }) do
			local o = d.resolve[k]
			ok("sponsor_drop " .. k .. " text uses {sponsor}", string.find(o.text, "{sponsor}", 1, true) ~= nil)
			eq("sponsor_drop " .. k .. ".sponsor", o.sponsor, "drop")
			eq("sponsor_drop " .. k .. ".sponsors", o.sponsors, -1)
			ok("sponsor_drop " .. k .. ".aura <= 0", (o.aura or 0) <= 0)
		end
	end
end

-- the plant graph: who plants what; every follow-up but the system-planted ones reachable from a card; no cycles;
-- depth <= 2. Planted by the system, never by content: sponsor_drop (Aura under the sponsor's floor) and mom_plaque
-- (design 4.3: mom "turns up the day after your first HIT"; Systems/WalkIns and CareerSim plant it when the first HIT
-- lands), and the four tier visits (Wave 2: Systems/Life and CareerSim plant one at each fame tier's first crossing)
local SYSTEM_PLANTED = { sponsor_drop = true, mom_plaque = true, tier_buzzing = true, tier_known = true, tier_famous = true,
	tier_icon = true, sponsor_warning = true } -- Wave 3: the rep's warning, planted instead of sponsor_drop (copy doc 9.1 #7)
local plantsOf = {} -- [nodeKey] = { followupId, ... }; nodeKey = "card:<id>" or "f:<id>"
local plantedBy = {} -- [followupId] = { nodeKey, ... }
local function addPlants(node, choices, resolve)
	plantsOf[node] = plantsOf[node] or {}
	local function add(o)
		if type(o.plant) == "table" and o.plant.id then
			table.insert(plantsOf[node], o.plant.id)
			plantedBy[o.plant.id] = plantedBy[o.plant.id] or {}
			table.insert(plantedBy[o.plant.id], node)
		end
	end
	if resolve then add(resolve.good or {}); add(resolve.bad or {}) end
	for _, c in ipairs(choices or {}) do eachOutcome(c, function(o) add(o) end) end
end
for _, card in ipairs(W.Cards) do addPlants("card:" .. card.id, card.choices) end
for _, f in ipairs(W.Followups) do addPlants("f:" .. f.id, f.choices, f.resolve) end

local depthOf = {}
local function walk(id, depth, stack)
	if stack[id] then ok("plant graph has no cycle through " .. id, false); return end
	ok("follow-up " .. id .. " depth < 3", depth < 3)
	if depth >= 3 then return end
	depthOf[id] = math.max(depthOf[id] or 0, depth)
	stack[id] = true
	for _, child in ipairs(plantsOf["f:" .. id] or {}) do walk(child, depth + 1, stack) end
	stack[id] = nil
end
for _, card in ipairs(W.Cards) do
	for _, child in ipairs(plantsOf["card:" .. card.id] or {}) do walk(child, 1, {}) end
end
for _, f in ipairs(W.Followups) do walk(f.id, 1, {}) end -- cycles among follow-ups no card reaches
for _, f in ipairs(W.Followups) do
	if SYSTEM_PLANTED[f.id] then
		ok(f.id .. " is planted by no outcome", plantedBy[f.id] == nil)
	else
		ok("follow-up " .. f.id .. " is planted by some outcome", plantedBy[f.id] ~= nil)
	end
end
-- reachable from a card (depth recorded by the walk from cards only)
depthOf = {}
for _, card in ipairs(W.Cards) do
	for _, child in ipairs(plantsOf["card:" .. card.id] or {}) do walk(child, 1, {}) end
end
for _, f in ipairs(W.Followups) do
	if not SYSTEM_PLANTED[f.id] then ok("follow-up " .. f.id .. " is reachable from a card", depthOf[f.id] ~= nil) end
end

-- a follow-up knows a sponsor only when the system plants it with the deal you hold (sponsor_drop and, Wave 3,
-- sponsor_warning: ctx.sponsor) or every planter is a card with a sponsor (ctx.sponsor)
local SPONSOR_PLANTED = { sponsor_drop = true, sponsor_warning = true }
local function followupKnowsSponsor(f)
	if SPONSOR_PLANTED[f.id] then return true end
	for _, node in ipairs(plantedBy[f.id] or {}) do
		local cardId = string.match(node, "^card:(.+)$")
		if not cardId or not W.CardById[cardId].sponsor then return false end
	end
	return plantedBy[f.id] ~= nil
end

-- test-facing ids (Tasks 6/7) ----------------------------------------------------------------------------------------
do
	local c = W.CardById.navx_placement
	ok("card navx_placement exists", c ~= nil)
	if c then
		eq("navx_placement visitor", c.visitor, "navx")
		ok("navx_placement has no when", c.when == nil)
		ok("navx_placement has no minCount", c.minCount == nil)
		ok("navx_placement has 3+ choices", #c.choices >= 3)
		local c1, c2, c3 = c.choices[1], c.choices[2], c.choices[3]
		ok("navx c1 no cost", c1.cost == nil)
		ok("navx c1 no rare", c1.rare == nil)
		ok("navx c1 not sure", not c1.sure)
		ok("navx c1 odds <= 90", (c1.odds or 50) <= 90)
		eq("navx c1 good.key", c1.good.key, "placement")
		eq("navx c1 good.placements", c1.good.placements, 1)
		local plant = c1.good.plant
		ok("navx c1 good.plant is exactly { id = navx_single }", type(plant) == "table" and plant.id == "navx_single"
			and plant.at == nil and next(plant, next(plant)) == nil)
		ok("navx c2 cost 200..1500", c2.cost ~= nil and c2.cost >= 200 and c2.cost <= 1500)
		ok("navx c2 good.money > 0", (c2.good.money or 0) > 0)
		ok("navx c2 no rare (SetRng({1}) lands good)", c2.rare == nil)
		ok("navx c3 no cost", c3.cost == nil)
		ok("navx c3 no rare", c3.rare == nil)
		ok("navx c3 not sure", not c3.sure)
		ok("navx c3 bad exists", type(c3.bad) == "table")
		if c3.bad then
			eq("navx c3 bad.tone", c3.bad.tone, "loss")
			ok("navx c3 bad.aura < 0", (c3.bad.aura or 0) < 0)
			ok("navx c3 bad.money < 0", (c3.bad.money or 0) < 0)
		end
	end
	local s = W.FollowupById.navx_single
	ok("follow-up navx_single exists", s ~= nil)
	if s then
		ok("navx_single has 2..4 choices", type(s.choices) == "table" and #s.choices >= 2 and #s.choices <= 4)
		eq("navx_single resolve.good.hits", s.resolve.good.hits, 1)
	end
end

-- gate pools (design 6 "a 180-follower and a 21K-follower profile draw from different pools", 8.2): on the live deck,
-- the walk-in cards whose needs/under pass (R.GateOk) at 180 followers hold the rookie cards and none of the famous-only
-- ones; at 21,000 followers, the reverse
do
	local ROOKIE = { "rookie_block", "rookie_corner", "rookie_open" }
	local FAMOUS = { "famous_stadium", "famous_doc", "famous_label", "manager_offer" }
	for _, id in ipairs(ROOKIE) do ok("gate pools: card " .. id .. " exists", W.CardById[id] ~= nil) end
	for _, id in ipairs(FAMOUS) do ok("gate pools: card " .. id .. " exists", W.CardById[id] ~= nil) end
	local function pool(followers)
		local career = { aura = 0, followers = followers, placements = 0, hits = 0, sponsors = 0, money = 0 }
		local passing = {}
		for _, card in ipairs(W.Deck.cards) do
			if (card.source or "walkin") == "walkin" and R.GateOk(card, career, 10) then passing[card.id] = true end
		end
		return passing
	end
	local rookie, famous = pool(180), pool(21000)
	for _, id in ipairs(ROOKIE) do
		ok("gate pools: 180 followers draw " .. id, rookie[id] == true)
		ok("gate pools: 21K followers never draw " .. id, famous[id] == nil)
	end
	for _, id in ipairs(FAMOUS) do
		ok("gate pools: 180 followers never draw " .. id, rookie[id] == nil)
		ok("gate pools: 21K followers draw " .. id, famous[id] == true)
	end
end

-- the two-sessions card's gates (two sessions, Task 3; Review Focus 5), on the live deck through WalkInRules.Pick:
-- each pick is Seed + Pick on a fresh state with opts like CareerSim.pickNext's (cooldown, rng, sponsored, aura,
-- source "phone", career with visits, day, week = day // 7, aired), 500 seeded picks a run. Only the opts named in a
-- run differ from the base run. visits 9 never draws it and visits 10 can; two CountCap calls on two days of one week
-- close it (CapOk and Pick) for that week, one call doesn't, and the next week opens it again
do
	local TWO = W.CardById.two_sessions
	ok("card two_sessions exists", TWO ~= nil)
	-- a deterministic rng (CareerSim.Lcg's Park-Miller, inlined: this spec loads no sim)
	local function lcg(seed)
		local s = seed % 2147483647
		if s <= 0 then s += 2147483646 end
		return function(lo, hi)
			s = s * 48271 % 2147483647
			if hi <= lo then return lo end
			return lo + s % (hi - lo + 1)
		end
	end
	-- state.count stays 12 in every run (phone cards read no count), so the visits 9 and 10 runs differ only in visits
	local function freshState(caps)
		return { day = 0, today = 0, count = 12, queue = {}, seen = {}, last = {},
			phone = { day = 0, today = 0, count = 0 }, caps = caps or {} }
	end
	local function copyCaps(caps)
		local c = {}
		for g, v in pairs(caps) do c[g] = { key = v.key, n = v.n } end
		return c
	end
	-- how many of 500 seeded picks are two_sessions, and how many picks returned anything
	local function picks(visits, day, caps)
		local hits, any = 0, 0
		for seed = 1, 500 do
			local state = freshState(caps and copyCaps(caps))
			local career = { aura = 0, followers = 0, placements = 0, hits = 0, sponsors = 0, money = 0, visits = visits }
			local opts = { cooldown = 3, rng = lcg(seed), sponsored = false, aura = 0, source = "phone", career = career,
				day = day, week = day // 7, aired = true }
			R.Seed(state, W.Deck, opts)
			local p = R.Pick(state, W.Deck, opts)
			if p then any += 1 end
			if p and p.kind == "card" and p.card.id == "two_sessions" then hits += 1 end
		end
		return hits, any
	end
	local DAY = 15 -- week 2 (days 14..20)
	local h9, any9 = picks(9, DAY)
	local h10, any10 = picks(10, DAY)
	eq("two_sessions gate: 500 phone picks at visits 9 all return a card", any9, 500)
	eq("two_sessions gate: never at visits 9 (500 picks)", h9, 0)
	ok(string.format("two_sessions gate: drawn at visits 10 (%d of 500 picks)", h10), h10 > 0 and any10 == 500)
	if TWO then
		-- the final review's values (2026-10-30): the 61-character line (two lines on a phone card; the 146-character one
		-- pushed choice 2 below the fold), and the one-hit wonder's win at +20 Aura and 10 XP (the climber's phone Aura
		-- budget, with margin for later phone cards)
		eq("two_sessions line (32 characters, one line at 771)", TWO.line, "two sessions, one day. pick one.")
		eq("two_sessions line length", #TWO.line, 32)
		local wentoff = TWO.choices[2] and TWO.choices[2].good
		eq("two_sessions wentoff aura", wentoff and wentoff.aura, 20)
		eq("two_sessions wentoff xp", wentoff and wentoff.xp, 10)
		eq("two_sessions needs visits 10", TWO.needs and TWO.needs.visits, 10)
		local state = { caps = {} }
		R.CountCap(state, TWO, DAY, DAY // 7)
		ok("two_sessions cap: one delivery this week still allows it", R.CapOk(TWO, state.caps, DAY + 1, (DAY + 1) // 7))
		R.CountCap(state, TWO, DAY + 1, (DAY + 1) // 7)
		ok("two_sessions cap: two deliveries on two days of one week refuse it that week",
			not R.CapOk(TWO, state.caps, DAY + 5, (DAY + 5) // 7))
		local hCapped = picks(10, DAY + 5, state.caps)
		eq("two_sessions cap: Pick never draws it after two deliveries this week (500 picks)", hCapped, 0)
		local NEXT = DAY + 6 -- day 21, week 3
		ok("two_sessions cap: the next week allows it again", R.CapOk(TWO, state.caps, NEXT, NEXT // 7))
		local hNext = picks(10, NEXT, state.caps)
		ok(string.format("two_sessions cap: Pick draws it again the next week (%d of 500 picks)", hNext), hNext > 0)
	end
end

-- every player-facing text: Fill leaves no token, no display name typed in, fiction fill has no parody name ------------
local texts = {} -- { where, text, sponsorKnown }
local function addText(where, text, known) if text ~= nil then table.insert(texts, { where, text, known }) end end
local function addOutcomeTexts(where, o, known)
	for _, k in ipairs({ "headline", "text", "line", "note" }) do addText(where .. "." .. k, o[k], known) end
end
local function addChoiceTexts(where, choices, known)
	for i, c in ipairs(choices or {}) do
		addText(where .. " choice " .. i .. ".text", c.text, known)
		eachOutcome(c, function(o, k) addOutcomeTexts(where .. " choice " .. i .. "." .. k, o, known) end)
	end
end
-- a card knows a sponsor when it has one, or (Wave 3, copy doc 9.1 #6) when it comes only while you hold a deal
-- (`when = "sponsored"`: Systems/WalkIns fills {sponsor} from Career's sponsor)
local function cardKnowsSponsor(card) return card.sponsor ~= nil or card.when == "sponsored" end
for _, card in ipairs(W.Cards) do
	local known = cardKnowsSponsor(card)
	addText("card " .. card.id .. ".tag", card.tag, known)
	addText("card " .. card.id .. ".line", card.line, known)
	addChoiceTexts("card " .. card.id, card.choices, known)
end
for _, f in ipairs(W.Followups) do
	local known = followupKnowsSponsor(f)
	addText("followup " .. f.id .. ".tag", f.tag, known)
	addText("followup " .. f.id .. ".line", f.line, known)
	addOutcomeTexts("followup " .. f.id .. ".resolve.good", f.resolve.good, known)
	addOutcomeTexts("followup " .. f.id .. ".resolve.bad", f.resolve.bad, known)
	addChoiceTexts("followup " .. f.id, f.choices, known)
end
-- a waiting visitor's lines and the note card's parting lines (Task 5): non-empty, lowercase, and checked below like
-- card text with no sponsor known (only {name:<id>} fills), so no token is left and no display name is typed in
for _, list in ipairs({ "WaitLines", "NoteLines" }) do
	for i, line in ipairs(W[list] or {}) do
		local where = "W." .. list .. "[" .. i .. "]"
		ok(where .. " is a non-empty string", isStr(line))
		if isStr(line) then
			ok(where .. " is lowercase", bare(line) == string.lower(bare(line)))
			addText(where, line, false)
		end
	end
end
-- the visitor shown on each card / follow-up needs a sponsor name exactly when its display name uses {sponsor};
-- these entries carry their roster (4th field) and are filled only with that roster's names
for _, card in ipairs(W.Cards) do
	local v = W.VisitorById[card.visitor]
	if v then
		for _, roster in ipairs(ROSTERS) do
			table.insert(texts, { "card " .. card.id .. " visitor " .. roster .. " name", v.names[roster], cardKnowsSponsor(card), roster })
		end
	end
end
for _, f in ipairs(W.Followups) do
	local v = W.VisitorById[f.visitor]
	if v then
		for _, roster in ipairs(ROSTERS) do
			table.insert(texts, { "followup " .. f.id .. " visitor " .. roster .. " name", v.names[roster], followupKnowsSponsor(f), roster })
		end
	end
end
ok("texts collected", #texts > 100)
for _, roster in ipairs(ROSTERS) do
	local names = W.Names(roster)
	for _, v in ipairs(W.Visitors) do
		local filled = R.Fill(names[v.id] or "", names, W.SponsorName(W.Sponsors[1].id, roster))
		ok(roster .. " visitor name fills: " .. filled, string.find(filled, "[{}]") == nil)
	end
end

local lowerParody = {}
for _, name in ipairs(parodyNames) do table.insert(lowerParody, string.lower(name)) end
for _, roster in ipairs(ROSTERS) do
	local names = W.Names(roster)
	for _, s in ipairs(W.Sponsors) do
		local sponsorName = W.SponsorName(s.id, roster)
		for _, t in ipairs(texts) do
			if t[4] and t[4] ~= roster then continue end
			local filled = R.Fill(t[2], names, t[3] and sponsorName or nil)
			ok(roster .. " Fill leaves no token: " .. t[1] .. " -> " .. filled,
				string.find(filled, "{", 1, true) == nil and string.find(filled, "}", 1, true) == nil)
			-- with a best beat too (Wave 3: {beat} -> "the one at <bpm>"; without one it reads "something")
			local withBeat = R.Fill(t[2], names, t[3] and sponsorName or nil, 142)
			ok(roster .. " Fill with a beat leaves no token: " .. t[1] .. " -> " .. withBeat,
				string.find(withBeat, "{", 1, true) == nil and string.find(withBeat, "}", 1, true) == nil)
			if roster == "fiction" then
				local low = string.lower(filled)
				for _, p in ipairs(lowerParody) do
					ok("fiction fill has no parody name " .. p .. ": " .. t[1], string.find(low, p, 1, true) == nil)
				end
			end
		end
	end
end
-- Wave 3 (design 4.1, copy doc 1): each beat or beatMin choice's {beat} reads both ways, in the card's line or that
-- choice's text: "the one at 142" with a best beat at 142, "something" with none, and the no-beat render says
-- "something" exactly once
do
	local names = W.Names("parody")
	for _, card in ipairs(W.Cards) do
		for i, c in ipairs(card.choices or {}) do
			if c.beat or c.beatMin then
				local src = count(card.line, BEAT_TOKEN) > 0 and card.line or c.text
				local with, without = R.Fill(src, names, nil, 142), R.Fill(src, names, nil, nil)
				local where = card.id .. " choice " .. i
				ok(where .. " with a beat reads 'the one at 142': " .. with, string.find(with, "the one at 142", 1, true) ~= nil)
				ok(where .. " with no beat reads 'something' once: " .. without, count(without, "something") == 1)
			end
		end
	end
end

-- content text never types a display name (names arrive through {name:<id>} and {sponsor}, so tokens are stripped
-- first: {name:drizzle} is fine, a typed "drizzle" is not); visitor names excluded
for _, t in ipairs(texts) do
	if not t[4] then
		local low = string.lower(bare(t[2]))
		for _, name in ipairs(allNames) do
			ok("display name " .. name .. " typed in " .. t[1], string.find(low, string.lower(name), 1, true) == nil)
		end
	end
end

-- safety: no real name anywhere in the module's strings; no blocklisted whole word -------------------------------------
local strings = {}
local function collect(x, seen)
	if type(x) == "string" then
		table.insert(strings, x)
	elseif type(x) == "table" and not seen[x] then
		seen[x] = true
		for k, v in pairs(x) do collect(k, seen); collect(v, seen) end
	end
end
collect(W, {})
for _, roster in ipairs(ROSTERS) do
	for _, name in pairs(W.Names(roster)) do table.insert(strings, name) end
	for _, s in ipairs(W.Sponsors) do table.insert(strings, W.SponsorName(s.id, roster)) end
end
local whole = string.lower(table.concat(strings, "\n"))
for _, real in ipairs(REAL) do ok("real name in content: " .. real, string.find(whole, real, 1, true) == nil) end
for _, title in ipairs(TITLES) do ok("real title in content: " .. title, string.find(whole, title, 1, true) == nil) end
for _, word in ipairs(BLOCK) do
	local at = string.find(whole, "%f[%w]" .. word .. "%f[%W]")
	ok("blocklisted word '" .. word .. "' near: " .. (at and string.sub(whole, math.max(1, at - 40), at + 40) or ""), at == nil)
end

-- Wave 2: the four tier visits (research/wave2/copy_2026-10-30.md section 1, pinned literally). One per Config.Life.TierVisits
-- entry (economy_fixture.LIFE), resolve only, and neither outcome loses. They pay through the walk-in path: Money, Followers
-- and, on ICON alone (A5: the others land before THE HALL's 300-Aura need), Aura. Never a Placement, a hit, a sponsor or XP
-- (Global: nothing that pays a Placement is gated)
local TIER_VISITS = {
	{ tier = "BUZZING", id = "tier_buzzing", visitor = "fan", good = { key = "shirts", money = 300, followers = 1000 },
		bad = { key = "stickers", money = 150, followers = 500 } },
	{ tier = "KNOWN", id = "tier_known", visitor = "booker", good = { key = "houseband", money = 400, followers = 1500 },
		bad = { key = "bumper", money = 200, followers = 500 } },
	{ tier = "FAMOUS", id = "tier_famous", visitor = "blogger", good = { key = "cover", money = 500, followers = 2000 },
		bad = { key = "sidebar", money = 250, followers = 1000 } },
	{ tier = "ICON", id = "tier_icon", visitor = "labelboss", good = { key = "imprint", money = 600, aura = 40, followers = 2000 },
		bad = { key = "handshake", money = 300, aura = 20, followers = 1000 } },
}
eq("every tier with a visit is listed here", #TIER_VISITS, (function() local n = 0; for _ in pairs(E.LIFE.TierVisits) do n += 1 end; return n end)())
for _, want in ipairs(TIER_VISITS) do
	local f = W.FollowupById[want.id]
	eq("Config.Life.TierVisits." .. want.tier, E.LIFE.TierVisits[want.tier], want.id)
	ok(want.id .. " exists", f ~= nil)
	if f then
		ok(want.id .. " is system-planted", SYSTEM_PLANTED[want.id] == true)
		eq(want.id .. " visitor", f.visitor, want.visitor)
		ok(want.id .. "'s visitor exists", W.VisitorById[f.visitor] ~= nil)
		ok(want.id .. " is a walk-in", f.source == nil or f.source == "walkin")
		ok(want.id .. " is resolve only", f.choices == nil)
		eq(want.id .. " odds", f.resolve.odds, 60)
		for _, side in ipairs({ "good", "bad" }) do
			local o, pay = f.resolve[side], want[side]
			local where = want.id .. " " .. side
			eq(where .. " key", o.key, pay.key)
			eq(where .. " tone", o.tone, side == "good" and "win" or "neutral")
			eq(where .. " money", o.money, pay.money)
			eq(where .. " followers", o.followers, pay.followers)
			eq(where .. " aura", o.aura, pay.aura)
			for _, field in ipairs({ "placements", "xp", "hits", "sponsors", "sponsor", "plant", "cooldown", "disco" }) do
				eq(where .. " has no " .. field, o[field], nil)
			end
		end
	end
end
-- the ICON visitor (web-checked: the check note) reads as a label in both rosters and has a figure
local boss = W.VisitorById.labelboss
ok("labelboss exists", boss ~= nil)
if boss then
	eq("labelboss kind", boss.kind, "manager")
	eq("labelboss sig", boss.sig, "suit")
	eq("labelboss parody name", boss.names.parody, "THE LABEL BOSS")
	eq("labelboss fiction name", boss.names.fiction, "A LABEL CHAIRMAN")
	eq("labelboss check", boss.check, "research/wave1_names_2026-10-27.md#labelboss")
end

-- Wave 2: the discography kind an outcome names (Systems/WalkIns passes it to Life). TRACK ONE is the kid's first tape
-- and every payback's trackone outcome (the 10-30 ruling: they show as TRACK ONE on the result card, so on the
-- discography too), and only a placement has a discography row to name
local named = {}
local function discoOf(where, o)
	if o.disco == nil then return end
	named[where] = true
	eq(where .. " disco", o.disco, "trackone")
	ok(where .. " disco needs a placement", (o.placements or 0) > 0)
end
for _, f in ipairs(W.Followups) do
	for _, side in ipairs(OUTCOME_KEYS) do
		if f.resolve[side] then discoOf(f.id .. "." .. side, f.resolve[side]) end
	end
end
for _, card in ipairs(W.Cards) do
	for i, choice in ipairs(card.choices) do
		for _, side in ipairs(OUTCOME_KEYS) do
			if choice[side] then discoOf(card.id .. " choice " .. i .. "." .. side, choice[side]) end
		end
	end
end
local namedList = {}
for where in pairs(named) do table.insert(namedList, where) end
table.sort(namedList)
-- Wave 3 (design 4.3, copy doc 9.1 #8): the hometown kid's album opens with your beat, TRACK ONE too
eq("only the first tape, the paybacks' trackone and the kid's album name a discography kind", table.concat(namedList, ","),
	"homekid_album choice 1.good,payback_charti.good,payback_dojabat.good,payback_drizzle.good,payback_eyelash.good,payback_homekid.good,payback_icespike.good,payback_llama.good,payback_scoot.good")
for _, f in ipairs(W.Followups) do
	local good = f.resolve and f.resolve.good
	if good and good.key == "trackone" then eq(f.id .. " is a TRACK ONE row", good.disco, "trackone") end
end

-- Wave 3 (design 4.2, copy doc 3): cold_news, the cold spell's one NEWS card, as the copy doc wrote it. A system card
-- (never drawn; Phone.SendSystem sends it), from the feed, one sure choice with no deltas, tone neutral
local coldNews = W.CardById.cold_news
ok("cold_news exists", coldNews ~= nil)
if coldNews then
	eq("cold_news system", coldNews.system, true)
	eq("cold_news visitor", coldNews.visitor, "feed")
	eq("cold_news source", coldNews.source, "phone")
	eq("cold_news app", coldNews.app, "NEWS")
	eq("cold_news news", coldNews.news, true)
	eq("cold_news tag", coldNews.tag, "STUDIO · QUIET")
	eq("cold_news line", coldNews.line, "your phone hasn't buzzed in days. make something people hear.")
	local c = coldNews.choices[1]
	eq("cold_news one choice", #coldNews.choices, 1)
	eq("cold_news choice text", c.text, "Got it.")
	eq("cold_news choice sure", c.sure, true)
	local g = c.good
	eq("cold_news key", g.key, "cold")
	eq("cold_news headline", g.headline, "YOU WENT COLD")
	eq("cold_news tone", g.tone, "neutral")
	eq("cold_news text", g.text, "Nobody's calling. Deliver a three-star beat or get a FIRE on the monitors to bring them back.")
	eq("cold_news reply", g.line, "three stars or a fire. that's the way back")
	for _, k in ipairs({ "money", "aura", "followers", "placements", "hits", "sponsors", "xp", "plant", "cooldown", "sponsor" }) do
		eq("cold_news has no " .. k, g[k], nil)
	end
	-- never drawn: 300 seeded phone picks on a state where every gate is open never return it
	local st = { day = 0, today = 0, count = 30, queue = {}, seen = {}, last = {}, phone = { day = 0, today = 0, count = 0 }, caps = {} }
	local rng = (function()
		local s = 12345
		return function(lo, hi) s = s * 48271 % 2147483647; if hi <= lo then return lo end; return lo + s % (hi - lo + 1) end
	end)()
	local drawn = false
	for _ = 1, 300 do
		local pk = R.Pick(st, W.Deck, { cooldown = 0, rng = rng, sponsored = false, aura = 1000, source = "phone",
			career = { money = 99999, aura = 1000, followers = 50000, placements = 9, hits = 9, sponsors = 9, visits = 30 }, day = 1, week = 0,
			aired = true })
		if pk and pk.kind == "card" and pk.card.id == "cold_news" then drawn = true end
	end
	ok("cold_news is never drawn by the phone's Pick", not drawn)
end
scratch("system on a walk-in card", (function() local c = walkinCard(); c.system = true; return c end)(), "(system) is a phone NEWS card")
scratch("system on a card SYSTEM_CARDS doesn't list", (function()
	local c = { id = "scratch_sys", visitor = "feed", source = "phone", app = "NEWS", news = true, system = true, tag = "SCRATCH",
		line = "a scratch line.", choices = { { text = "ok", sure = true, good = sOutcome("s", "neutral", {}) } } }
	return c
end)(), "(system) is one SYSTEM_CARDS lists")
scratch("system not true", (function() local c = readyDM(); c.system = 1; return c end)(), ".system is true or absent")

-- Wave 3: they remember you (design 4.3, copy doc 2 and 7) ---------------------------------------------------------------
-- A stable rendering of a value (tables by sorted key), for the literal pins below
local function show(x)
	if type(x) ~= "table" then return tostring(x) end
	local keys = {}
	for k in pairs(x) do table.insert(keys, k) end
	table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
	local parts = {}
	for _, k in ipairs(keys) do table.insert(parts, tostring(k) .. "=" .. show(x[k])) end
	return "{" .. table.concat(parts, ",") .. "}"
end
-- fn(item, where, outcome) for every outcome of `cards` (their choices) and `followups` (resolve, then choices)
local function eachItemOutcome(cards, followups, fn)
	for _, card in ipairs(cards) do
		for i, c in ipairs(card.choices or {}) do
			eachOutcome(c, function(o, k) fn(card, "card " .. card.id .. " choice " .. i .. "." .. k, o) end)
		end
	end
	for _, f in ipairs(followups) do
		for _, k in ipairs({ "good", "bad" }) do
			local o = type(f.resolve) == "table" and f.resolve[k] or nil
			if o then fn(f, "followup " .. f.id .. ".resolve." .. k, o) end
		end
		for i, c in ipairs(f.choices or {}) do
			eachOutcome(c, function(o, k) fn(f, "followup " .. f.id .. " choice " .. i .. "." .. k, o) end)
		end
	end
end
-- the deck-wide relationship rules over `cards` and `followups`; returns the failures and the set flags
-- { ["who.flag"] = true } (who = rel.who, else the item's visitor):
-- * every needs.flags / under.flags id names a flag some outcome sets (an unset one would make the card dead or the
--   guard meaningless: a misspelled once flag never blocks), and so does every rel.clear;
-- * no dead score gate: a card with needs.rel > 0 has some outcome that raises its visitor's score, one with
--   under.rel <= 0 some outcome that lowers it
local function relFails(cards, followups)
	local set, up, down, out = {}, {}, {}, {}
	eachItemOutcome(cards, followups, function(item, _, o)
		local r = type(o) == "table" and o.rel or nil
		if type(r) ~= "table" then return end
		local who = r.who or item.visitor
		if type(r.flag) == "string" then set[who .. "." .. r.flag] = true end
		if type(r.score) == "number" and r.score > 0 then up[who] = true end
		if type(r.score) == "number" and r.score < 0 then down[who] = true end
	end)
	for _, card in ipairs(cards) do
		for _, field in ipairs({ "needs", "under" }) do
			local g = type(card[field]) == "table" and card[field] or {}
			for _, id in ipairs(type(g.flags) == "table" and g.flags or {}) do
				if not set[id] then table.insert(out, "card " .. card.id .. "." .. field .. ".flags '" .. tostring(id) .. "' is a flag no outcome sets") end
			end
		end
		local needs, under = type(card.needs) == "table" and card.needs or {}, type(card.under) == "table" and card.under or {}
		if type(needs.rel) == "number" and needs.rel > 0 and not up[card.visitor] then
			table.insert(out, "card " .. card.id .. " needs.rel " .. needs.rel .. ": no outcome raises " .. tostring(card.visitor) .. "'s score")
		end
		if type(under.rel) == "number" and under.rel <= 0 and not down[card.visitor] then
			table.insert(out, "card " .. card.id .. " under.rel " .. under.rel .. ": no outcome lowers " .. tostring(card.visitor) .. "'s score")
		end
	end
	eachItemOutcome(cards, followups, function(item, where, o)
		local r = type(o) == "table" and o.rel or nil
		if type(r) == "table" and type(r.clear) == "string" and not set[(r.who or item.visitor) .. "." .. r.clear] then
			table.insert(out, where .. ".rel.clear '" .. r.clear .. "' is a flag no outcome sets")
		end
	end)
	return out, set
end
local relGot, relSet = relFails(W.Cards, W.Followups)
for _, f in ipairs(relGot) do ok(f, false) end
-- Data/WalkIns indexes the same set (W.RelFlags = { [visitorId] = { [flag] = true } }: Systems/WalkIns keeps only these)
do
	local idx = {}
	for who, flags in pairs(type(W.RelFlags) == "table" and W.RelFlags or {}) do
		for flag in pairs(flags) do idx[who .. "." .. flag] = true end
	end
	eq("W.RelFlags indexes every flag an outcome sets", show(idx), show(relSet))
end
-- the deck-wide rules over the live deck plus one scratch card: its failures must include `want` (none when nil)
local function relScratch(name, card, want)
	local cards = table.clone(W.Cards)
	table.insert(cards, card)
	local got = relFails(cards, W.Followups)
	if want == nil then
		ok("rel scratch " .. name .. " passes, got: " .. table.concat(got, " | "), #got == 0)
		return
	end
	local hit = false
	for _, f in ipairs(got) do if string.find(f, want, 1, true) then hit = true end end
	ok("rel scratch " .. name .. " fails '" .. want .. "', got: " .. table.concat(got, " | "), hit)
end
local function relCard(needs, under, rel)
	return { id = "scratch_rel", visitor = "navx", tag = "SCRATCH", line = "a scratch line.", needs = needs, under = under, choices = {
		{ text = "one", sure = true, good = sOutcome("g", "win", { aura = 5, rel = rel }) },
		{ text = "two", sure = true, good = sOutcome("s", "win", { aura = 5 }) },
	} }
end
relScratch("a card gated on a set flag", relCard({ flags = { "navx.album_hit" } }), nil)
relScratch("a gate on a flag no outcome sets", relCard({ flags = { "navx.nobody_sets_this" } }), "'navx.nobody_sets_this' is a flag no outcome sets")
relScratch("a misspelled once guard", relCard(nil, { flags = { "navx.telly" } }), "'navx.telly' is a flag no outcome sets")
relScratch("a clear of a flag no outcome sets", relCard(nil, nil, { clear = "nothing_here" }), "rel.clear 'nothing_here' is a flag no outcome sets")
relScratch("needs.rel on a visitor nothing raises", (function() local c = relCard({ rel = 1 }); c.visitor = "pigeon"; return c end)(), "no outcome raises pigeon's score")
relScratch("under.rel on a visitor nothing lowers", (function() local c = relCard(nil, { rel = 0 }); c.visitor = "pigeon"; return c end)(), "no outcome lowers pigeon's score")
scratch("a valid rel card", relCard({ rel = 2, flags = { "navx.album_hit" } }, { rel = 3 }, { score = 1, flag = "tv" }), nil)
scratch("under.rel -5", relCard(nil, { rel = -5 }), ".under.rel whole -2..3")
scratch("needs.rel 4", relCard({ rel = 4 }), ".needs.rel whole -2..3")
scratch("a gate flag without a dot", relCard({ flags = { "album_hit" } }), "is who.flag with who a visitor")
scratch("a gate flag of a visitor that doesn't exist", relCard({ flags = { "nobody.flag" } }), "is who.flag with who a visitor")
scratch("an empty gate flag list", relCard({ flags = {} }), ".needs.flags is a non-empty list")
scratch("rel.who not a visitor", relCard(nil, nil, { who = "nobody", score = 1 }), ".rel.who is a visitor")
scratch("rel with only who", relCard(nil, nil, { who = "mom" }), ".rel writes something")
scratch("rel score 0", relCard(nil, nil, { score = 0 }), ".rel.score whole -3..3, not 0")
scratch("rel score 4", relCard(nil, nil, { score = 4 }), ".rel.score whole -3..3, not 0")
scratch("rel flag not a name", relCard(nil, nil, { flag = "two words" }), ".rel.flag is a flag name")
scratch("rel unknown key", relCard(nil, nil, { score = 1, flags = "tv" }), ".rel unknown key flags")
scratch("a sponsored rep card with a sponsor of its own", (function()
	local c = relCard(); c.visitor = "rep"; c.when = "sponsored"; c.sponsor = "energy"; return c
end)(), "(rep) offers its sponsor while unsponsored, or is the held deal's rep")

-- the 18 arc entries, as copy doc 7.1 maps the design's gates (15 walk-in cards, 3 walk-in follow-ups)
local ARC = {
	{ id = "rival_collab", visitor = "rival", needs = { rel = 1, flags = { "rival.respect" } } },
	{ id = "rival_war", visitor = "rival", needs = { flags = { "rival.posted" } } },
	{ id = "mom_aunt", visitor = "mom", needs = { rel = 2 }, under = { flags = { "mom.quiet", "mom.aunt" } } },
	{ id = "mom_quiet", visitor = "mom", under = { rel = -1, flags = { "mom.quiet" } } },
	{ id = "homekid_show", visitor = "homekid", needs = { flags = { "homekid.blew_up" } }, under = { flags = { "homekid.show" } } },
	{ id = "homekid_album", visitor = "homekid", needs = { rel = 2, flags = { "homekid.blew_up" } } },
	{ id = "homekid_forgot", visitor = "homekid", needs = { followers = 5000, flags = { "homekid.passed" } }, under = { flags = { "homekid.blew_up" } } },
	{ id = "navx_tour", visitor = "navx", needs = { flags = { "navx.album_hit" } }, under = { flags = { "navx.toured" } } },
	{ id = "navx_tv", visitor = "navx", needs = { rel = 2 }, under = { flags = { "navx.tv" } } },
	{ id = "navx_replaced", visitor = "navx", needs = { placements = 2 }, under = { rel = 0, flags = { "navx.replaced" } } },
	{ id = "sponsor_duty", visitor = "rep", when = "sponsored" },
	{ id = "sponsor_renew", visitor = "rep", when = "sponsored", needs = { rel = 2 }, under = { flags = { "rep.renewed" } } },
	{ id = "blogger_exclusive", visitor = "blogger", needs = { rel = 1 } },
	{ id = "blogger_expose", visitor = "blogger", under = { rel = 0, aura = 300, flags = { "blogger.exposed" } } },
	{ id = "blogger_expose_bounce", visitor = "blogger", needs = { aura = 300 }, under = { rel = 0, flags = { "blogger.exposed" } } },
}
local ARC_FOLLOWUPS = { { id = "rival_truce", visitor = "rival" }, { id = "mom_return", visitor = "mom" }, { id = "sponsor_warning", visitor = "rep" } }
local isArc = {}
for _, a in ipairs(ARC) do
	isArc[a.id] = true
	local c = W.CardById[a.id]
	ok("arc card " .. a.id .. " exists", c ~= nil)
	if c then
		eq(a.id .. " visitor", c.visitor, a.visitor)
		ok(a.id .. " is a walk-in card", c.source == nil)
		eq(a.id .. " when", c.when, a.when)
		eq(a.id .. " needs", show(c.needs), show(a.needs))
		eq(a.id .. " under", show(c.under), show(a.under))
		ok(a.id .. " has no sponsor of its own", c.sponsor == nil)
	end
end
for _, a in ipairs(ARC_FOLLOWUPS) do
	isArc[a.id] = true
	local f = W.FollowupById[a.id]
	ok("arc follow-up " .. a.id .. " exists", f ~= nil)
	if f then
		eq(a.id .. " visitor", f.visitor, a.visitor)
		ok(a.id .. " is a walk-in follow-up", f.source == nil)
		ok(a.id .. " has choices", type(f.choices) == "table" and #f.choices == 2)
	end
end
-- the mom arc's two cards share the mom group's cap; every walk-in mom card but mom_return (a follow-up: no gates) stays
-- away while she is quiet (plan Task 5)
for _, id in ipairs({ "mom_aunt", "mom_quiet" }) do
	eq(id .. " cap", show(W.CardById[id] and W.CardById[id].cap), show({ group = "mom", per = "week", max = 2 }))
end
for _, card in ipairs(W.Cards) do
	if card.visitor == "mom" then
		local quiet = false
		for _, id in ipairs(type(card.under) == "table" and type(card.under.flags) == "table" and card.under.flags or {}) do
			if id == "mom.quiet" then quiet = true end
		end
		ok("mom card " .. card.id .. " has under.flags mom.quiet", quiet)
	end
end
-- the two new placement cards (copy doc 2.1, 2.3): choice 1 a `beat` choice, {beat} in the line (BEAT_CHOICES pins the
-- flag; this the token's place); rival_war's answer goes by your best beat (beatMin 3, ruling), {beat} in its text
for _, id in ipairs({ "rival_collab", "homekid_album" }) do
	local c = W.CardById[id]
	ok(id .. " choice 1 is a beat choice and its line says {beat}", c ~= nil and c.choices[1].beat == true and count(c.line, BEAT_TOKEN) == 1)
end
do
	local war = W.CardById.rival_war
	local a = war and war.choices[1]
	ok("rival_war choice 1 is beatMin 3 with {beat} in its text", a ~= nil and a.beatMin == 3 and count(a.text, BEAT_TOKEN) == 1)
end
-- the once guards (ruling): every outcome of each card sets the card's own flag, which its under.flags names
local ONCE = { mom_aunt = "aunt", homekid_show = "show", navx_tour = "toured", navx_tv = "tv", navx_replaced = "replaced",
	sponsor_renew = "renewed", blogger_expose = "exposed", blogger_expose_bounce = "exposed" }
for id, flag in pairs(ONCE) do
	local c = W.CardById[id]
	for i, ch in ipairs(c and c.choices or {}) do
		eachOutcome(ch, function(o, k) eq(id .. " choice " .. i .. "." .. k .. " sets its once flag", o.rel and o.rel.flag, flag) end)
	end
end
-- the clears and plants the rulings name: every rival_war outcome clears posted and plants the truce at {3,5}; both
-- mom_quiet outcomes set quiet and plant mom_return at {6,9}; the truce's, mom_return's and mom_plaque's news clear
-- posted / quiet; every homekid_forgot outcome clears passed; calling her back is +2
do
	local function each(item, fn)
		for i, ch in ipairs(item and item.choices or {}) do eachOutcome(ch, function(o, k) fn(o, item.id .. " choice " .. i .. "." .. k) end) end
	end
	local function news(item, fn)
		for _, k in ipairs({ "good", "bad" }) do fn(item and item.resolve and item.resolve[k] or {}, (item and item.id or "?") .. ".resolve." .. k) end
	end
	each(W.CardById.rival_war, function(o, w)
		eq(w .. " clears posted", o.rel and o.rel.clear, "posted")
		eq(w .. " plants rival_truce at {3,5}", show(o.plant), show({ id = "rival_truce", at = { 3, 5 } }))
	end)
	each(W.CardById.mom_quiet, function(o, w)
		eq(w .. " sets quiet", o.rel and o.rel.flag, "quiet")
		eq(w .. " plants mom_return at {6,9}", show(o.plant), show({ id = "mom_return", at = { 6, 9 } }))
	end)
	news(W.FollowupById.rival_truce, function(o, w) eq(w .. " clears posted", o.rel and o.rel.clear, "posted") end)
	news(W.FollowupById.mom_return, function(o, w) eq(w .. " clears quiet", o.rel and o.rel.clear, "quiet") end)
	news(W.FollowupById.mom_plaque, function(o, w) eq(w .. " clears mom's quiet", show(o.rel), show({ who = "mom", clear = "quiet" })) end)
	each(W.CardById.homekid_forgot, function(o, w) eq(w .. " clears passed", o.rel and o.rel.clear, "passed") end)
	local back = W.FollowupById.mom_return and W.FollowupById.mom_return.choices[1]
	eq("mom_return calling her back is +2 (ruling)", back and back.good.rel and back.good.rel.score, 2)
end
-- the trigger writes on the cards that were already here (design 4.3's table; Task 5's calls on ghost_out and rumour, on
-- the approval list; the mom_plaque ruling): exactly these, outcome by outcome. A write named on a choice is on every
-- outcome of that choice, one named on an outcome on that outcome only
local TRIGGERS = {
	["card rival_beat choice 1.good"] = { score = -1, flag = "posted" }, ["card rival_beat choice 1.bad"] = { score = -1, flag = "posted" },
	["card rival_beat choice 2.good"] = { score = 1, flag = "respect" },
	["card rival_beat choice 3.good"] = { score = 1 }, ["card rival_beat choice 3.bad"] = { score = 1 },
	["followup rival_steal.resolve.good"] = { score = -1 },
	["card mom_food choice 1.good"] = { score = 1, flag = "fed" }, ["card mom_food choice 3.good"] = { score = -1 },
	["card mom_busy choice 2.good"] = { score = 1 }, ["card mom_busy choice 3.good"] = { score = -1 },
	["card two_sessions choice 1.good"] = { who = "homekid", score = 1 },
	["card two_sessions choice 2.good"] = { who = "homekid", flag = "passed" }, ["card two_sessions choice 2.bad"] = { who = "homekid", flag = "passed" },
	["followup payback_homekid.resolve.good"] = { flag = "blew_up" },
	["card navx_placement choice 1.good"] = { score = 1 }, ["card navx_placement choice 1.bad"] = { score = 1 },
	["card navx_placement choice 3.good"] = { score = -1 }, ["card navx_placement choice 3.bad"] = { score = -1 },
	["followup navx_album.resolve.good"] = { flag = "album_hit" },
	["card blogger_interview choice 1.good"] = { score = 1 }, ["card blogger_interview choice 1.bad"] = { score = 1 },
	["card blogger_interview choice 2.good"] = { score = -1 },
	["followup ghost_out.resolve.good"] = { score = 1 }, ["followup ghost_out.resolve.bad"] = { score = -1 },
	["followup rumour choice 1.good"] = { score = 1 }, ["followup rumour choice 2.good"] = { score = -1 },
	["followup rumour choice 3.good"] = { score = 1 }, ["followup rumour choice 3.bad"] = { score = 1 },
	["followup mom_plaque.resolve.good"] = { who = "mom", clear = "quiet" }, ["followup mom_plaque.resolve.bad"] = { who = "mom", clear = "quiet" },
}
do
	local got = {}
	eachItemOutcome(W.Cards, W.Followups, function(item, where, o)
		if o.rel ~= nil and not isArc[item.id] then got[where] = show(o.rel) end
	end)
	for where, want in pairs(TRIGGERS) do eq(where .. " rel", got[where], show(want)) end
	for where, s in pairs(got) do ok(where .. " has a rel write " .. s .. " the trigger table doesn't list", TRIGGERS[where] ~= nil) end
end
-- sponsor_warning (copy doc 2.5): the rep of the deal you hold ({sponsor} from the plant's ctx), its news the warning
-- itself (both sides the same, nothing moved, as sponsor_drop's), two sure choices; the system plants it (SYSTEM_PLANTED)
do
	local f = W.FollowupById.sponsor_warning
	if f then
		for _, k in ipairs({ "good", "bad" }) do
			local o = f.resolve[k]
			ok("sponsor_warning " .. k .. " text uses {sponsor}", string.find(o.text, "{sponsor}", 1, true) ~= nil)
			eq("sponsor_warning " .. k .. " tone", o.tone, "neutral")
			for _, d in ipairs({ "money", "aura", "followers", "placements", "hits", "sponsors", "sponsor", "plant", "rel" }) do
				eq("sponsor_warning " .. k .. " has no " .. d, o[d], nil)
			end
		end
		eq("sponsor_warning sides are the same", show(f.resolve.good), show(f.resolve.bad))
		for i, c in ipairs(f.choices) do ok("sponsor_warning choice " .. i .. " is sure", c.sure == true) end
	end
end

-- the starter pool (Task 5b+, the user's call of 2026-11-06): the very first walk-in is one of these `first` cards, drawn
-- at random (WalkInRules.Pick at visits 0). Each suits a producer with nothing yet and is open to a brand-new career:
-- a walk-in card gated by exactly under = { visits = 1 } (it never comes back once the first visit is in) and nothing else
-- (no needs, cap, when, sponsor, aired, weight or minCount), no cost and no loss (checkGentle above), and no plant,
-- relationship write, placement, hit, sponsor or beat. The superfan stays out of the first slot (gentle_first is retired;
-- tier_buzzing still brings the fan): no first card is the fan's
local STARTERS = { "starter_rapper", "starter_cousin", "starter_neighbor", "starter_kid", "starter_host", "starter_landlord" }
do
	local got = {}
	for _, card in ipairs(W.Cards) do if card.first then table.insert(got, card.id) end end
	eq("the `first` cards are the starter pool, in deck order", table.concat(got, ","), table.concat(STARTERS, ","))
	ok("gentle_first is retired", W.CardById.gentle_first == nil)
	local freshCareer = { aura = 0, followers = 0, placements = 0, hits = 0, sponsors = 0, money = 0 }
	for _, id in ipairs(STARTERS) do
		local c = W.CardById[id]
		local where = "starter " .. id
		ok(where .. " exists", c ~= nil)
		if c then
			eq(where .. " first", c.first, true)
			eq(where .. " under is exactly { visits = 1 }", show(c.under), show({ visits = 1 }))
			for _, f in ipairs({ "needs", "cap", "when", "sponsor", "aired", "weight", "minCount", "system", "source" }) do
				eq(where .. " has no " .. f, c[f], nil)
			end
			ok(where .. " is not the superfan's", c.visitor ~= "fan")
			ok(where .. " is open to a new career at visits 0", R.GateOk(c, freshCareer, 0, {}))
			ok(where .. " is closed at visits 1", not R.GateOk(c, freshCareer, 1, {}))
			for i, ch in ipairs(c.choices or {}) do
				ok(where .. " choice " .. i .. " has no beat or beatMin", ch.beat == nil and ch.beatMin == nil)
				eachOutcome(ch, function(o, k)
					local ow = where .. " choice " .. i .. "." .. k
					for _, f in ipairs({ "plant", "rel", "placements", "hits", "sponsors", "sponsor", "cooldown", "disco" }) do
						eq(ow .. " has no " .. f, o[f], nil)
					end
					-- the first-visit Aura cushion (the controller's ruling of 2026-11-11, research/fiction_pass_2026-11-06.md
					-- section 8): every starter outcome pays at least +5 Aura, as the retired gentle_first's wins did, so a new
					-- player's day 1 keeps the margin the "never cold in days 1-7" pacing check relies on
					ok(ow .. " pays at least +5 Aura (the 11-11 cushion)", (o.aura or 0) >= 5)
				end)
			end
		end
	end
	-- the draw on the live deck: Seed + Pick on a fresh state at visits 0 always gives a starter and, over 600 seeded
	-- draws, every one of them; at visits 1, never one (500 draws). The sim's Park-Miller step, inlined as above
	local function lcg(seed)
		local s = seed % 2147483647
		if s <= 0 then s += 2147483646 end
		return function(lo, hi)
			s = s * 48271 % 2147483647
			if hi <= lo then return lo end
			return lo + s % (hi - lo + 1)
		end
	end
	local isStarter, drawn = {}, {}
	for _, id in ipairs(STARTERS) do isStarter[id] = true end
	local function draw(visits, seed)
		local state = { day = 0, today = 0, count = visits, queue = {}, seen = {}, last = {}, caps = {} }
		local career = table.clone(freshCareer)
		career.visits = visits
		local opts = { cooldown = 3, rng = lcg(seed), sponsored = false, aura = 0, source = "walkin", career = career, day = 3,
			week = 0, aired = false, rel = {} }
		R.Seed(state, W.Deck, opts)
		local p = R.Pick(state, W.Deck, opts)
		return p and p.kind == "card" and p.card.id or nil
	end
	local others, nonStarter = 0, nil
	for seed = 1, 600 do
		local id = draw(0, seed)
		if id and isStarter[id] then drawn[id] = (drawn[id] or 0) + 1 else others += 1; nonStarter = nonStarter or tostring(id) end
	end
	eq("visits 0: 600 draws are all starters (first other: " .. tostring(nonStarter) .. ")", others, 0)
	for _, id in ipairs(STARTERS) do ok(string.format("visits 0: %s drawn (%d of 600)", id, drawn[id] or 0), (drawn[id] or 0) > 0) end
	local late = 0
	for seed = 1, 500 do if isStarter[draw(1, seed) or ""] then late += 1 end end
	eq("visits 1: no starter in 500 draws", late, 0)
end

if #fails > 0 then error(#fails .. " walkins data case(s) failed: " .. table.concat(fails, "; ")) end
print("SPEC OK: walkins data")
