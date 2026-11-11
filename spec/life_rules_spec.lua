-- CLI spec for Modules/LifeRules (Wave 2, "the career remembers"): fame tiers, the career clock and year, capped list
-- pushes, the auto title, ribbons, the story and discography text in both rosters, the event bookkeeping (firsts, story
-- and discography entries) and the v4 -> v5 backfill. Config values come from spec/economy_fixture.lua's LIFE (a literal
-- copy of Config.Life that build/t46_check.lua diffs against the live Config) and RANKS (Config.Ranks).
-- Run: sh tools/spec.sh life_rules
local L = require("../src/ReplicatedStorage/OK/Modules/LifeRules")
local W = require("../src/ReplicatedStorage/OK/Data/WalkIns")
local E = require("./economy_fixture")
local LIFE, RANKS = E.LIFE, E.RANKS
local TIERS = LIFE.Tiers

local fails = {}
local function ok(name, cond) if not cond then table.insert(fails, name) end end
local function eq(name, got, want)
	if got ~= want then table.insert(fails, string.format("%s: expected %s, got %s", name, tostring(want), tostring(got))) end
end
local function plain(s, sub) return string.find(s, sub, 1, true) ~= nil end
-- s with the first plain occurrence of sub cut out (a display name is text, never a pattern)
local function cut(s, sub)
	local a, b = string.find(s, sub, 1, true)
	if not a then return s end
	return string.sub(s, 1, a - 1) .. string.sub(s, b + 1)
end

-- Data/Artists (session artists) needs Roblox globals (Color3), so its names are a literal copy here
local ARTISTS = { juno = "JUNO VALE", tavi = "TAVI GLASS", rue = "RUE LANTERN", vesper = "SAINT VESPER", nyx = "NYX ARCADE",
	indigo = "INDIGO RAIL" }
local function sponsorNames(roster)
	local t = {}
	for _, s in ipairs(W.Sponsors) do t[s.id] = W.SponsorName(s.id, roster) end
	return t
end
local function namesFor(roster)
	return { visitors = W.Names(roster), artists = ARTISTS, sponsors = sponsorNames(roster), ranks = RANKS, tiers = TIERS }
end

-- Commas: thousands commas, whole numbers
eq("Commas 0", L.Commas(0), "0")
eq("Commas 999", L.Commas(999), "999")
eq("Commas 1000", L.Commas(1000), "1,000")
eq("Commas 5000", L.Commas(5000), "5,000")
eq("Commas 100000", L.Commas(100000), "100,000")
eq("Commas 1234567", L.Commas(1234567), "1,234,567")
eq("Commas -2500", L.Commas(-2500), "-2,500")
eq("Commas junk", L.Commas("x"), "0")

-- TierFor: the highest tier whose line the Followers reach
local function tier(n) local id, i = L.TierFor(n, TIERS); return id .. "/" .. tostring(i) end
eq("TierFor 0", tier(0), "LOCAL/1")
eq("TierFor 999", tier(999), "LOCAL/1")
eq("TierFor 1000", tier(1000), "BUZZING/2")
eq("TierFor 4999", tier(4999), "BUZZING/2")
eq("TierFor 5000", tier(5000), "KNOWN/3")
eq("TierFor 19999", tier(19999), "KNOWN/3")
eq("TierFor 20000", tier(20000), "FAMOUS/4")
eq("TierFor 99999", tier(99999), "FAMOUS/4")
eq("TierFor 100000", tier(100000), "ICON/5")
eq("TierFor 5000000", tier(5000000), "ICON/5")
eq("TierFor -50", tier(-50), "LOCAL/1")
eq("TierFor nil", tier(nil), "LOCAL/1")
eq("TierFor junk", tier("lots"), "LOCAL/1")
eq("TierIndex KNOWN", L.TierIndex("KNOWN", TIERS), 3)
eq("TierIndex unknown", L.TierIndex("MEGA", TIERS), 1)
eq("TierIndex nil", L.TierIndex(nil, TIERS), 1)

-- TiersCrossed (A4): every tier above the old index up to the new one, in order
local function crossed(a, b)
	local ids = {}
	for _, t in ipairs(L.TiersCrossed(a, b, TIERS)) do table.insert(ids, t.id .. "@" .. t.index .. ":" .. t.followers) end
	return table.concat(ids, ",")
end
local _, i900 = L.TierFor(900, TIERS)
local _, i6000 = L.TierFor(6000, TIERS)
eq("TiersCrossed 900 -> 6,000 (A4)", crossed(i900, i6000), "BUZZING@2:1000,KNOWN@3:5000")
eq("TiersCrossed 1 -> 2", crossed(1, 2), "BUZZING@2:1000")
eq("TiersCrossed 1 -> 5", crossed(1, 5), "BUZZING@2:1000,KNOWN@3:5000,FAMOUS@4:20000,ICON@5:100000")
eq("TiersCrossed same", crossed(3, 3), "")
eq("TiersCrossed fall", crossed(4, 2), "")
eq("TiersCrossed past the top", crossed(4, 9), "ICON@5:100000")
eq("TiersCrossed never the lowest tier", crossed(0, 2), "BUZZING@2:1000")
local tc = L.TiersCrossed(1, 2, TIERS)
tc[1].id = "CHANGED"
eq("TiersCrossed returns copies", TIERS[2].id, "BUZZING")

-- YearOf: 7 career days a year
eq("YearOf 1", L.YearOf(1, LIFE.DaysPerYear), 1)
eq("YearOf 7", L.YearOf(7, LIFE.DaysPerYear), 1)
eq("YearOf 8", L.YearOf(8, LIFE.DaysPerYear), 2)
eq("YearOf 14", L.YearOf(14, LIFE.DaysPerYear), 2)
eq("YearOf 15", L.YearOf(15, LIFE.DaysPerYear), 3)
eq("YearOf 0", L.YearOf(0, LIFE.DaysPerYear), 1)
eq("YearOf nil", L.YearOf(nil, LIFE.DaysPerYear), 1)

-- Step: one career day per UTC day played; missed days never count; an earlier day (another server's clock) never counts
local life = { day = 1, last = 20261030 }
eq("Step same day", L.Step(life, 20261030), false)
eq("Step same day keeps day", life.day, 1)
eq("Step next day", L.Step(life, 20261031), true)
eq("Step next day +1", life.day, 2)
eq("Step next day sets last", life.last, 20261031)
eq("Step twice on the same day", L.Step(life, 20261031), false)
eq("Step twice keeps day", life.day, 2)
eq("Step three-day gap", L.Step(life, 20261103), true)
eq("Step three-day gap +1 only", life.day, 3)
eq("Step gap sets last", life.last, 20261103)
eq("Step earlier day", L.Step(life, 20261102), false)
eq("Step earlier day keeps day", life.day, 3)
eq("Step earlier day keeps last", life.last, 20261103)
local blank = {}
eq("Step blank life", L.Step(blank, 20261030), true)
eq("Step blank life day 1", blank.day, 1)
eq("Step blank life last", blank.last, 20261030)
local junk = { day = "x", last = "y" }
eq("Step junk life", L.Step(junk, 20261030), true)
eq("Step junk life day 1", junk.day, 1)
-- a today that isn't a number never steps and never touches the life; a numeric string counts as its number
for _, bad in ipairs({ "x", {}, true, 0 / 0 }) do
	local g = { day = 3, last = 20261030 }
	eq("Step bad today " .. type(bad), L.Step(g, bad), false)
	eq("Step bad today keeps day " .. type(bad), g.day, 3)
	eq("Step bad today keeps last " .. type(bad), g.last, 20261030)
end
local g0 = { day = 3, last = 20261030 }
eq("Step nil today", L.Step(g0, nil), false)
eq("Step nil today keeps day", g0.day, 3)
eq("Step nil today keeps last", g0.last, 20261030)
local gs = { day = 3, last = 20261030 }
eq("Step numeric-string today", L.Step(gs, "20261031"), true)
eq("Step numeric-string today +1", gs.day, 4)
eq("Step numeric-string today stores a number", gs.last, 20261031)

-- Push: append, drop the oldest past max, stay dense
local list = {}
for i = 1, 3 do L.Push(list, { n = i }, 3) end
eq("Push under max", #list, 3)
L.Push(list, { n = 4 }, 3)
eq("Push 4th keeps 3", #list, 3)
eq("Push drops the first", list[1].n, 2)
eq("Push newest last", list[3].n, 4)
local dense = 0
for _ in pairs(list) do dense += 1 end
eq("Push dense", dense, #list)
local big = {}
for i = 1, 105 do L.Push(big, { n = i }, LIFE.StoryMax) end
eq("Push story cap", #big, 100)
eq("Push story cap oldest", big[1].n, 6)
local disco = {}
for i = 1, 230 do L.Push(disco, { n = i }, LIFE.DiscoMax) end
eq("Push disco cap", #disco, 200)
eq("Push disco cap oldest", disco[1].n, 31)
local over = { { n = 1 }, { n = 2 }, { n = 3 }, { n = 4 }, { n = 5 } }
L.Push(over, { n = 6 }, 3)
eq("Push trims a list already over max", #over, 3)
eq("Push trims to the newest", over[1].n, 4)

-- TitleFor: the first rule that holds wins; never a rank word
local T = LIFE.Titles
local function title(firsts, ti) return (L.TitleFor(firsts, ti, T)) end
eq("TitleFor fresh", title({}, 1), "NEW IN TOWN")
eq("TitleFor nil firsts", title(nil, 1), "NEW IN TOWN")
eq("TitleFor delivery", title({ delivery = 3 }, 1), "SESSION REGULAR")
eq("TitleFor buzzing", title({ delivery = 3 }, 2), "BUZZING")
eq("TitleFor placement", title({ placement = 4 }, 2), "ON THE RECORD")
eq("TitleFor cypher", title({ placement = 4, cypher = 5 }, 2), "CYPHER CHAMP")
eq("TitleFor sponsor", title({ placement = 4, cypher = 5, sponsor = 6 }, 2), "SPONSORED")
eq("TitleFor known", title({ sponsor = 6 }, 3), "WELL KNOWN")
eq("TitleFor hit", title({ hit = 7 }, 3), "CHART MAKER")
eq("TitleFor backfilled hit (0)", title({ hit = 0 }, 1), "CHART MAKER")
eq("TitleFor famous", title({ hit = 7 }, 4), "FAMOUS")
eq("TitleFor icon", title({}, 5), "ICON")
local _, tid = L.TitleFor({ hit = 7 }, 3, T)
eq("TitleFor id", tid, "chart")
-- without the catch-all (Task 0: drop NEW IN TOWN to show no title) there is no title before any first or tier
local noCatch = {}
for i = 1, #T - 1 do noCatch[i] = T[i] end
eq("TitleFor nil before any first", L.TitleFor({}, 1, noCatch), nil)
eq("TitleFor nil firsts, no catch-all", L.TitleFor(nil, 1, noCatch), nil)
eq("TitleFor first only, no catch-all", L.TitleFor({ delivery = 2 }, 1, noCatch), "SESSION REGULAR")
-- every title word: none is a rank, contains a rank, or is one with spaces removed (A15)
local function squash(s) return (string.gsub(string.upper(s), "%s", "")) end
local function isRank(word)
	local w = squash(word)
	for _, r in ipairs(RANKS) do
		if plain(w, squash(r)) then return true end
	end
	return false
end
local words = 0
for _, rule in ipairs(T) do
	local w = L.Copy.Titles[rule.id]
	ok("title word for " .. tostring(rule.id), type(w) == "string" and #w > 0)
	if type(w) == "string" then
		words += 1
		ok(string.format("title %s is not a rank", w), not isRank(w))
	end
end
eq("TitleFor words", words, 10)
-- the rank check itself trips on its controls
ok("rank check control HIT MAKER", isRank("HIT MAKER"))
ok("rank check control STAR PRODUCER", isRank("STAR PRODUCER"))
ok("rank check control CHART MAKER", not isRank("CHART MAKER"))

-- RibbonsFor: newly earned ribbon ids in rule order; an earned ribbon never comes back
local R = LIFE.Ribbons
local function ribbons(lf, counts) return table.concat(L.RibbonsFor(lf, counts, R, TIERS), ",") end
eq("RibbonsFor none", ribbons({ firsts = {}, tier = "LOCAL", ribbons = {} }, { placements = 0 }), "")
eq("RibbonsFor 9 placements", ribbons({ firsts = {}, tier = "LOCAL", ribbons = {} }, { placements = 9 }), "")
eq("RibbonsFor 10 placements", ribbons({ firsts = {}, tier = "LOCAL", ribbons = {} }, { placements = 10 }), "placements10")
eq("RibbonsFor streak7", ribbons({ firsts = { streak7 = 4 }, tier = "LOCAL", ribbons = {} }, {}), "streak7")
eq("RibbonsFor backfilled streak7 (0)", ribbons({ firsts = { streak7 = 0 }, tier = "LOCAL", ribbons = {} }, {}), "streak7")
eq("RibbonsFor hit", ribbons({ firsts = { hit = 2 }, tier = "LOCAL", ribbons = {} }, {}), "hit")
eq("RibbonsFor sponsor", ribbons({ firsts = { sponsor = 2 }, tier = "LOCAL", ribbons = {} }, {}), "sponsor")
eq("RibbonsFor FAMOUS is no ICON", ribbons({ firsts = {}, tier = "FAMOUS", ribbons = {} }, {}), "")
eq("RibbonsFor ICON", ribbons({ firsts = {}, tier = "ICON", ribbons = {} }, {}), "icon")
eq("RibbonsFor all, in rule order", ribbons({ firsts = { streak7 = 1, hit = 2, sponsor = 3 }, tier = "ICON", ribbons = {} },
	{ placements = 12 }), "streak7,placements10,hit,sponsor,icon")
eq("RibbonsFor earned stays out", ribbons({ firsts = { hit = 2, sponsor = 3 }, tier = "LOCAL", ribbons = { hit = 2 } }, {}), "sponsor")
eq("RibbonsFor nil counts and tables", ribbons({}, nil), "")
local labels = 0
for _, rb in ipairs(R) do
	local lbl = L.Copy.Ribbons[rb.id]
	ok("ribbon label for " .. tostring(rb.id), type(lbl) == "string" and #lbl > 0)
	if type(lbl) == "string" then
		labels += 1
		ok(string.format("ribbon %s is not a rank", lbl), not isRank(lbl))
	end
end
eq("RibbonsFor labels", labels, 5)

-- FirstsFor: the firsts an event ticks
local function firstsOf(kind, fields) return table.concat(L.FirstsFor(kind, fields), ",") end
eq("FirstsFor placement", firstsOf("placement", {}), "placement")
eq("FirstsFor hit", firstsOf("hit", {}), "hit")
eq("FirstsFor sponsor", firstsOf("sponsor", {}), "sponsor")
eq("FirstsFor sponsor_drop", firstsOf("sponsor_drop", {}), "")
eq("FirstsFor delivery", firstsOf("delivery", {}), "delivery")
eq("FirstsFor delivery3", firstsOf("delivery3", {}), "delivery,delivery3")
eq("FirstsFor beat", firstsOf("beat", {}), "beat")
eq("FirstsFor hall", firstsOf("hall", {}), "hall")
eq("FirstsFor legend", firstsOf("legend", {}), "")
eq("FirstsFor cypher_win", firstsOf("cypher_win", {}), "cypher")
eq("FirstsFor level 4", firstsOf("level", { n = 4 }), "")
eq("FirstsFor level 5", firstsOf("level", { n = 5 }), "level5")
eq("FirstsFor level 8", firstsOf("level", { n = 8 }), "level5")
eq("FirstsFor streak7", firstsOf("streak7", {}), "streak7")
eq("FirstsFor tier BUZZING", firstsOf("tier", { key = "BUZZING" }), "buzzing")
eq("FirstsFor tier KNOWN", firstsOf("tier", { key = "KNOWN" }), "known")
eq("FirstsFor tier FAMOUS", firstsOf("tier", { key = "FAMOUS" }), "")
eq("FirstsFor tier ICON", firstsOf("tier", { key = "ICON" }), "")
eq("FirstsFor unknown", firstsOf("party", {}), "")
-- Wave 3 (design 4.2): the cold spell's two kinds tick no first (no firsts, titles or ribbons)
eq("FirstsFor cold", firstsOf("cold", {}), "")
eq("FirstsFor thaw", firstsOf("thaw", {}), "")
-- every first an event can tick is in Config.Life.Firsts, and every Config first has a label
local inList = {}
for _, id in ipairs(LIFE.Firsts) do
	inList[id] = true
	ok("first label for " .. id, type(L.Copy.FirstLabels[id]) == "string")
end
eq("Firsts count", #LIFE.Firsts, 12)
for _, k in ipairs(L.KINDS) do
	for _, id in ipairs(L.FirstsFor(k, { n = 10, key = "KNOWN" })) do ok("first " .. id .. " from " .. k .. " is listed", inList[id]) end
	for _, id in ipairs(L.FirstsFor(k, { key = "BUZZING" })) do ok("first " .. id .. " from " .. k .. " is listed", inList[id]) end
end
eq("KINDS count", #L.KINDS, 15)
ok("KINDS has cold (Wave 3)", table.find(L.KINDS, "cold") ~= nil)
ok("KINDS has thaw (Wave 3)", table.find(L.KINDS, "thaw") ~= nil)

-- Apply: ticks firsts, pushes a named-field story entry (first = true when the kind's own first ticked), and a
-- discography entry for placements and hits; beat and cypher_win log only as firsts; a repeat or daily delivery
-- (fields.again, fields.daily) logs only when it ticks its own first
local lf = { day = 4, last = 20261030, story = {}, disco = {}, firsts = {}, tier = "LOCAL", ribbons = {} }
local res = L.Apply(lf, "placement", { v = "navx", key = "c_navx_1" }, LIFE)
eq("Apply placement ticks", table.concat(res.ticked, ","), "placement")
eq("Apply placement first day", lf.firsts.placement, 4)
eq("Apply placement story", #lf.story, 1)
local st = lf.story[1]
eq("Apply story d", st.d, 4)
eq("Apply story k", st.k, "placement")
eq("Apply story v", st.v, "navx")
eq("Apply story key", st.key, "c_navx_1")
eq("Apply story first", st.first, true)
eq("Apply story has no positional fields", st[1], nil)
eq("Apply placement disco", #lf.disco, 1)
eq("Apply disco d", lf.disco[1].d, 4)
eq("Apply disco kind", lf.disco[1].kind, "placement")
eq("Apply disco v", lf.disco[1].v, "navx")
eq("Apply disco key", lf.disco[1].key, "c_navx_1")
res = L.Apply(lf, "placement", { v = "homekid", key = "payback_homekid", disco = "trackone" }, LIFE)
eq("Apply second placement ticks nothing", #res.ticked, 0)
eq("Apply second placement first kept", lf.firsts.placement, 4)
eq("Apply second placement not first", lf.story[2].first, nil)
eq("Apply TRACK ONE disco kind", lf.disco[2].kind, "trackone")
eq("Apply TRACK ONE story kind", lf.story[2].k, "placement")
res = L.Apply(lf, "placement", { v = "navx", disco = "bogus" }, LIFE)
eq("Apply unknown disco kind falls back", lf.disco[3].kind, "placement")
res = L.Apply(lf, "hit", { v = "drift", key = "hit_drift" }, LIFE)
eq("Apply hit disco", lf.disco[4].kind, "hit")
eq("Apply hit first", lf.story[4].first, true)
lf.day = 5
res = L.Apply(lf, "beat", {}, LIFE)
eq("Apply first beat logs", res.story ~= nil, true)
eq("Apply first beat entry first", res.story and res.story.first, true)
res = L.Apply(lf, "beat", {}, LIFE)
eq("Apply second beat no story", res.story, nil)
res = L.Apply(lf, "cypher_win", {}, LIFE)
eq("Apply first cypher win logs", res.story and res.story.k, "cypher_win")
eq("Apply first cypher win first", lf.firsts.cypher, 5)
res = L.Apply(lf, "cypher_win", {}, LIFE)
eq("Apply second cypher win no story", res.story, nil)
local before = #lf.story
res = L.Apply(lf, "delivery3", { v = "juno", key = "j1" }, LIFE)
eq("Apply delivery3 ticks both", table.concat(res.ticked, ","), "delivery,delivery3")
eq("Apply delivery3 first", res.story and res.story.first, true)
eq("Apply delivery3 no disco", res.disco, nil)
res = L.Apply(lf, "delivery", { v = "tavi", key = "t1", again = true }, LIFE)
eq("Apply repeat delivery no story", res.story, nil)
res = L.Apply(lf, "delivery", { v = "tavi", key = "t2" }, LIFE)
eq("Apply new brief delivery logs", res.story and res.story.k, "delivery")
eq("Apply delivery after delivery3 not first", res.story and res.story.first, nil)
eq("Apply story grew by 2", #lf.story, before + 2)
-- the 10-30 ruling: dailies log no line, and a delivery that ticks its own first always does
local df = { day = 2, last = 20261030, story = {}, disco = {}, firsts = {}, tier = "LOCAL", ribbons = {} }
res = L.Apply(df, "delivery", { v = "juno", key = "d20261030_1", daily = true }, LIFE)
eq("Apply first-ever delivery that is a daily logs", res.story and res.story.k, "delivery")
eq("Apply first-ever daily is first", res.story and res.story.first, true)
eq("Apply first-ever daily ticks", table.concat(res.ticked, ","), "delivery")
res = L.Apply(df, "delivery", { v = "juno", key = "d20261030_2", daily = true }, LIFE)
eq("Apply second daily no story", res.story, nil)
res = L.Apply(df, "delivery", { v = "juno", key = "j1", again = true }, LIFE)
eq("Apply repeat brief at 2 stars no story", res.story, nil)
res = L.Apply(df, "delivery3", { v = "juno", key = "j1", again = true }, LIFE)
eq("Apply first 3-star on a repeat brief logs", res.story and res.story.k, "delivery3")
eq("Apply first 3-star on a repeat brief is first", res.story and res.story.first, true)
eq("Apply first 3-star on a repeat brief ticks", table.concat(res.ticked, ","), "delivery3")
res = L.Apply(df, "delivery3", { v = "juno", key = "j1", again = true }, LIFE)
eq("Apply second 3-star repeat no story", res.story, nil)
res = L.Apply(df, "delivery3", { v = "juno", key = "d20261030_3", daily = true }, LIFE)
eq("Apply 3-star daily after the first no story", res.story, nil)
eq("Apply dailies story count", #df.story, 2)
-- a first 3-star that is a daily logs too
local df3 = { day = 2, last = 20261030, story = {}, disco = {}, firsts = { delivery = 1 }, tier = "LOCAL", ribbons = {} }
res = L.Apply(df3, "delivery3", { v = "tavi", key = "d20261030_1", daily = true }, LIFE)
eq("Apply first 3-star daily logs", res.story and res.story.first, true)
eq("Apply a new weekly (neither again nor daily) still logs", L.Apply(df3, "delivery", { v = "tavi", key = "w2965" }, LIFE).story ~= nil, true)
res = L.Apply(lf, "level", { n = 5 }, LIFE)
eq("Apply level n", res.story and res.story.n, 5)
eq("Apply level5 first", lf.firsts.level5, 5)
res = L.Apply(lf, "tier", { key = "BUZZING" }, LIFE)
eq("Apply tier key", res.story and res.story.key, "BUZZING")
eq("Apply tier first", lf.firsts.buzzing, 5)
res = L.Apply(lf, "sponsor", { s = "energy" }, LIFE)
eq("Apply sponsor s", res.story and res.story.s, "energy")
res = L.Apply(lf, "sponsor_drop", { s = "energy" }, LIFE)
eq("Apply sponsor_drop logs", res.story and res.story.k, "sponsor_drop")
eq("Apply sponsor_drop ticks nothing", #res.ticked, 0)
res = L.Apply(lf, "party", {}, LIFE)
eq("Apply unknown kind no story", res.story, nil)
-- Apply honours the caps and builds missing tables
local capped = { day = 1 }
for i = 1, 105 do L.Apply(capped, "hall", {}, LIFE) end
eq("Apply story capped", #capped.story, LIFE.StoryMax)
for i = 1, 205 do L.Apply(capped, "hit", { v = "navx" }, LIFE) end
eq("Apply disco capped", #capped.disco, LIFE.DiscoMax)
-- Wave 3 (design 4.2): every cold spell and every thaw logs its line, the second as well as the first (no first-only
-- rule), with no first, no discography entry and no id fields
local cl = { day = 4, last = 20261105, story = {}, disco = {}, firsts = {}, tier = "LOCAL", ribbons = {} }
for i, k in ipairs({ "cold", "thaw", "cold", "thaw" }) do
	cl.day = 3 + i
	res = L.Apply(cl, k, {}, LIFE)
	eq("Apply " .. k .. " #" .. i .. " logs", res.story and res.story.k, k)
	eq("Apply " .. k .. " #" .. i .. " day", res.story and res.story.d, 3 + i)
	eq("Apply " .. k .. " #" .. i .. " is never a first", res.story and res.story.first, nil)
	eq("Apply " .. k .. " #" .. i .. " ticks nothing", #res.ticked, 0)
	eq("Apply " .. k .. " #" .. i .. " no disco", res.disco, nil)
end
eq("Apply cold/thaw: every streak logged", #cl.story, 4)
eq("Apply cold/thaw: no firsts", next(cl.firsts), nil)
eq("Apply cold/thaw: no disco", #cl.disco, 0)
local cl1 = cl.story[1] or {}
eq("Apply cold: no id fields", cl1.v == nil and cl1.s == nil and cl1.key == nil, true)

-- StoryText: every kind, both rosters, plain and first lines; display names come from the names table; no line
-- keeps a {token} or types a raw visitor id
local SAMPLES = {
	{ d = 12, k = "placement", v = "navx", key = "c1" },
	{ d = 12, k = "hit", v = "drift", key = "f1" },
	{ d = 12, k = "sponsor", s = "watches" },
	{ d = 12, k = "sponsor_drop", s = "watches" },
	{ d = 12, k = "delivery", v = "juno", key = "j1" },
	{ d = 12, k = "delivery3", v = "rue", key = "r1" },
	{ d = 12, k = "beat" },
	{ d = 12, k = "hall" },
	{ d = 12, k = "legend" },
	{ d = 12, k = "cypher_win" },
	{ d = 12, k = "level", n = 7 },
	{ d = 12, k = "streak7" },
	{ d = 12, k = "tier", key = "KNOWN" },
	{ d = 12, k = "cold" },
	{ d = 12, k = "thaw" },
}
local kindsSeen = {}
for _, roster in ipairs({ "parody", "fiction" }) do
	local names = namesFor(roster)
	for _, base in ipairs(SAMPLES) do
		for _, first in ipairs({ false, true }) do
			local e = table.clone(base)
			e.first = first or nil
			local line = L.StoryText(e, names)
			kindsSeen[e.k] = true
			local tag = string.format("%s %s%s", roster, e.k, first and " first" or "")
			ok("StoryText " .. tag .. " renders", type(line) == "string")
			if type(line) == "string" then
				ok("StoryText " .. tag .. " starts DAY 12 · (" .. line .. ")", string.sub(line, 1, #"DAY 12 · ") == "DAY 12 · ")
				ok("StoryText " .. tag .. " has no { (" .. line .. ")", not plain(line, "{") and not plain(line, "}"))
				if e.k == "placement" or e.k == "hit" then
					local nm = names.visitors[e.v]
					ok("StoryText " .. tag .. " names " .. nm .. " (" .. line .. ")", plain(line, nm))
					ok("StoryText " .. tag .. " types no raw id (" .. line .. ")", not plain(cut(line, nm), e.v))
				elseif e.k == "sponsor" or e.k == "sponsor_drop" then
					ok("StoryText " .. tag .. " names the sponsor (" .. line .. ")", plain(line, names.sponsors[e.s]))
					ok("StoryText " .. tag .. " types no sponsor id (" .. line .. ")", not plain(line, e.s))
				elseif e.k == "delivery" or e.k == "delivery3" then
					ok("StoryText " .. tag .. " names the artist (" .. line .. ")", plain(line, ARTISTS[e.v]))
					ok("StoryText " .. tag .. " types no raw id (" .. line .. ")", not plain(cut(line, ARTISTS[e.v]), e.v))
				end
			end
		end
	end
end
for _, k in ipairs(L.KINDS) do ok("StoryText sample for kind " .. k, kindsSeen[k]) end
-- the A8 sweep: every visitor id in both rosters, placement and hit, plain and first, and every discography kind. A name
-- still holding a {token} (the rep) reads as the fallback. Past the name, the line equals the template with no name: the
-- id can't hide anywhere, and an id that happens to sit inside a template word doesn't trip it.
local swept, sweptNames = 0, 0
for _, roster in ipairs({ "parody", "fiction" }) do
	local names = namesFor(roster)
	for id, name in pairs(names.visitors) do
		local shown = plain(name, "{") and L.Copy.Fallback.artist or name
		for _, k in ipairs({ "placement", "hit" }) do
			for _, first in ipairs({ false, true }) do
				local line = L.StoryText({ d = 7, k = k, v = id, first = first or nil }, names)
				local tag = string.format("sweep %s %s %s%s", roster, id, k, first and " first" or "")
				swept += 1
				ok(tag .. " renders", type(line) == "string")
				if type(line) == "string" then
					ok(tag .. " has no braces (" .. line .. ")", not plain(line, "{") and not plain(line, "}"))
					ok(tag .. " shows the name (" .. line .. ")", plain(line, shown))
					local tpl = first and L.Copy.StoryFirst[k] or L.Copy.Story[k]
					eq(tag .. " line", cut(line, shown), "DAY 7 · " .. cut(tpl, "{artist}"))
				end
			end
		end
		for key, label in pairs(L.Copy.DiscoKinds) do
			local line = L.DiscoText({ d = 7, kind = key, v = id }, names)
			local tag = string.format("sweep %s %s disco %s", roster, id, key)
			swept += 1
			ok(tag .. " renders", type(line) == "string")
			if type(line) == "string" then
				ok(tag .. " has no braces (" .. line .. ")", not plain(line, "{") and not plain(line, "}"))
				eq(tag .. " line", line, "DAY 7 · " .. shown .. " · " .. label)
			end
		end
		sweptNames += 1
	end
end
ok("sweep covers both rosters", sweptNames >= 2 * 20)
ok("sweep covers the rep", namesFor("parody").visitors.rep ~= nil)
eq("sweep size", swept, sweptNames * (4 + 3))
local P = namesFor("parody")
eq("StoryText placement", L.StoryText({ d = 3, k = "placement", v = "navx" }, P), "DAY 3 · You landed a placement with LIL NAV X.")
eq("StoryText first placement", L.StoryText({ d = 3, k = "placement", v = "navx", first = true }, P),
	"DAY 3 · You landed your first placement, with LIL NAV X.")
eq("StoryText fiction placement", L.StoryText({ d = 12, k = "placement", v = "homekid" }, namesFor("fiction")),
	"DAY 12 · You landed a placement with A KID FROM YOUR OLD BLOCK.")
eq("StoryText sponsor_drop", L.StoryText({ d = 12, k = "sponsor_drop", s = "watches" }, P), "DAY 12 · ROWLECKS dropped you.")
eq("StoryText level", L.StoryText({ d = 12, k = "level", n = 7 }, P), "DAY 12 · You reached LEVEL 7: HITMAKER.")
eq("StoryText tier", L.StoryText({ d = 12, k = "tier", key = "KNOWN" }, P), "DAY 12 · You hit KNOWN at 5,000 followers.")
eq("StoryText tier ICON", L.StoryText({ d = 30, k = "tier", key = "ICON" }, P), "DAY 30 · You hit ICON at 100,000 followers.")
eq("StoryText hall (no first variant)", L.StoryText({ d = 5, k = "hall", first = true }, P), "DAY 5 · THE HALL opened for you.")
eq("StoryText delivery3 first", L.StoryText({ d = 2, k = "delivery3", v = "juno", first = true }, P),
	"DAY 2 · You delivered your first three-star session, for JUNO VALE.")
-- a name it doesn't have (or one that still holds a {token}, like the rep's) reads as a fallback, never an id or a {
local miss = L.StoryText({ d = 4, k = "placement", v = "ghost" }, P)
eq("StoryText missing visitor", miss, "DAY 4 · You landed a placement with " .. L.Copy.Fallback.artist .. ".")
local rep = L.StoryText({ d = 4, k = "placement", v = "rep" }, P)
ok("StoryText rep name has no { (" .. tostring(rep) .. ")", type(rep) == "string" and not plain(rep, "{"))
eq("StoryText missing sponsor", L.StoryText({ d = 4, k = "sponsor", s = "ghost" }, P),
	"DAY 4 · You signed with " .. L.Copy.Fallback.sponsor .. ".")
eq("StoryText missing artist", L.StoryText({ d = 4, k = "delivery", v = "ghost" }, P),
	"DAY 4 · You delivered a session for " .. L.Copy.Fallback.artist .. ".")
eq("StoryText no names table", L.StoryText({ d = 4, k = "placement", v = "navx" }, nil),
	"DAY 4 · You landed a placement with " .. L.Copy.Fallback.artist .. ".")
-- a name holding a "%" is used as it is
local pct = { visitors = { navx = "100% REAL" } }
eq("StoryText % in a name", L.StoryText({ d = 1, k = "hit", v = "navx" }, pct), "DAY 1 · You got a HIT with 100% REAL.")
-- lines it can't render cleanly are skipped (nil), never shown half-filled
eq("StoryText unknown kind", L.StoryText({ d = 1, k = "party" }, P), nil)
eq("StoryText level without n", L.StoryText({ d = 1, k = "level" }, P), nil)
eq("StoryText level without its rank", L.StoryText({ d = 1, k = "level", n = 11 }, P), nil)
eq("StoryText tier unknown", L.StoryText({ d = 1, k = "tier", key = "MEGA" }, P), nil)
eq("StoryText not a table", L.StoryText(nil, P), nil)
-- Wave 3 (design 4.2; copy doc 4): the cold spell's two lines, the same with or without names, and no first variant
eq("StoryText cold", L.StoryText({ d = 4, k = "cold" }, P), "DAY 4 · Nobody was calling.")
eq("StoryText thaw", L.StoryText({ d = 6, k = "thaw" }, P), "DAY 6 · You got people talking again.")
eq("StoryText cold without names", L.StoryText({ d = 4, k = "cold" }, nil), "DAY 4 · Nobody was calling.")
eq("StoryText thaw first reads the same", L.StoryText({ d = 6, k = "thaw", first = true }, P), "DAY 6 · You got people talking again.")
eq("StoryFirst has no cold", L.Copy.StoryFirst.cold, nil)
eq("StoryFirst has no thaw", L.Copy.StoryFirst.thaw, nil)

-- NameIds: the ids a life's story and discography need names for (A8: Career.State sends these names)
local ids = L.NameIds({ story = { { d = 1, k = "placement", v = "navx" }, { d = 1, k = "delivery", v = "juno" },
	{ d = 1, k = "sponsor", s = "energy" }, { d = 2, k = "hit", v = "navx" } }, disco = { { d = 1, kind = "trackone", v = "homekid" } } })
local function keys(t) local out = {}; for k in pairs(t) do table.insert(out, k) end; table.sort(out); return table.concat(out, ",") end
eq("NameIds visitors", keys(ids.visitors), "homekid,navx")
eq("NameIds artists", keys(ids.artists), "juno")
eq("NameIds sponsors", keys(ids.sponsors), "energy")
eq("NameIds empty life", keys(L.NameIds(nil).visitors), "")

-- View (A1, A8): what Career.State sends: copies of the life, the year and title, and the display names of exactly the ids
-- it holds, taken from the known maps. An id with no known name, or one still holding a {token}, stays out of names.
local vLife = { day = 9, last = 20261030, tier = "KNOWN", firsts = { placement = 2, hit = 6 }, ribbons = { hit = 6 },
	story = { { d = 2, k = "placement", v = "navx", first = true }, { d = 3, k = "placement", v = "ghost" }, { d = 4, k = "sponsor", s = "watches" },
		{ d = 4, k = "sponsor", s = "ghost" }, { d = 5, k = "delivery", v = "juno" }, { d = 5, k = "delivery", v = "ghost" }, { d = 6, k = "hit", v = "rep" } },
	disco = { { d = 2, kind = "placement", v = "homekid" } } }
local namesByRoster = {}
for _, roster in ipairs({ "parody", "fiction" }) do
	local known = { visitors = W.Names(roster), artists = ARTISTS, sponsors = sponsorNames(roster) }
	local v = L.View(vLife, LIFE, known)
	local tag = "View " .. roster
	eq(tag .. " day", v.day, 9)
	eq(tag .. " year", v.year, 2)
	eq(tag .. " tier", v.tier, "KNOWN")
	eq(tag .. " tierIndex", v.tierIndex, 3)
	eq(tag .. " title", v.title, "CHART MAKER")
	eq(tag .. " titleId", v.titleId, "chart")
	eq(tag .. " keeps last private", v.last, nil)
	eq(tag .. " story", #v.story, 7)
	eq(tag .. " disco", #v.disco, 1)
	eq(tag .. " firsts", v.firsts.hit, 6)
	eq(tag .. " ribbons", v.ribbons.hit, 6)
	eq(tag .. " names navx", v.names.visitors.navx, known.visitors.navx)
	eq(tag .. " names homekid", v.names.visitors.homekid, known.visitors.homekid)
	eq(tag .. " no name for an unknown visitor", v.names.visitors.ghost, nil)
	eq(tag .. " no name for the rep's template", v.names.visitors.rep, nil)
	eq(tag .. " sponsor name", v.names.sponsors.watches, known.sponsors.watches)
	eq(tag .. " no name for an unknown sponsor", v.names.sponsors.ghost, nil)
	eq(tag .. " artist name", v.names.artists.juno, "JUNO VALE")
	eq(tag .. " no name for an unknown artist", v.names.artists.ghost, nil)
	eq(tag .. " only the ids it holds", v.names.visitors.drift, nil)
	-- the client renders from exactly what View sends, plus Config's ranks and tiers
	local render = { visitors = v.names.visitors, artists = v.names.artists, sponsors = v.names.sponsors, ranks = RANKS, tiers = TIERS }
	for i, e in ipairs(v.story) do
		local line = L.StoryText(e, render)
		ok(tag .. " story " .. i .. " renders clean", type(line) == "string" and not plain(line, "{") and not plain(line, "}"))
	end
	eq(tag .. " unknown visitor falls back", L.StoryText(v.story[2], render), "DAY 3 · You landed a placement with " .. L.Copy.Fallback.artist .. ".")
	eq(tag .. " unknown sponsor falls back", L.StoryText(v.story[4], render), "DAY 4 · You signed with " .. L.Copy.Fallback.sponsor .. ".")
	namesByRoster[roster] = v.names.visitors.navx
	-- copies: changing what View returned never touches the saved life
	v.story[1].v = "changed"; v.disco[1].v = "changed"; v.firsts.hit = 99; v.ribbons.hit = 99; table.insert(v.story, {})
	eq(tag .. " story entries are copies", vLife.story[1].v, "navx")
	eq(tag .. " disco entries are copies", vLife.disco[1].v, "homekid")
	eq(tag .. " firsts is a copy", vLife.firsts.hit, 6)
	eq(tag .. " ribbons is a copy", vLife.ribbons.hit, 6)
	eq(tag .. " story list is a copy", #vLife.story, 7)
end
ok("View names follow the roster", namesByRoster.parody ~= namesByRoster.fiction)
local blankView = L.View(nil, LIFE, nil)
eq("View nil day", blankView.day, 1)
eq("View nil year", blankView.year, 1)
eq("View nil tier", blankView.tier, "LOCAL")
eq("View nil title", blankView.title, "NEW IN TOWN")
eq("View nil story", #blankView.story, 0)
eq("View nil disco", #blankView.disco, 0)
eq("View nil firsts", next(blankView.firsts), nil)
eq("View nil names", next(blankView.names.visitors), nil)
local junkView = L.View({ day = "x", tier = "MEGA", story = "junk", disco = 7, firsts = "junk", ribbons = true }, LIFE, {})
eq("View junk day", junkView.day, 1)
eq("View junk tier", junkView.tier, "LOCAL")
eq("View junk story", #junkView.story, 0)

-- DiscoText: "DAY n · <visitor> · <kind>"
eq("DiscoText placement", L.DiscoText({ d = 9, kind = "placement", v = "navx" }, P), "DAY 9 · LIL NAV X · PLACEMENT")
eq("DiscoText trackone", L.DiscoText({ d = 9, kind = "trackone", v = "homekid" }, P), "DAY 9 · A KID FROM BACK HOME · TRACK ONE")
eq("DiscoText hit fiction", L.DiscoText({ d = 9, kind = "hit", v = "navx" }, namesFor("fiction")), "DAY 9 · STIRRUP PEONY · HIT")
eq("DiscoText unknown kind", L.DiscoText({ d = 9, kind = "remix", v = "navx" }, P), nil)

-- FirstText, DayToast, Banner
eq("FirstText day", L.FirstText({ hit = 6 }, "hit"), "DAY 6")
eq("FirstText before the clock", L.FirstText({ hit = 0 }, "hit"), "BEFORE DAY 1")
eq("FirstText not yet", L.FirstText({}, "hit"), "NOT YET")
eq("FirstText nil firsts", L.FirstText(nil, "hit"), "NOT YET")
eq("DayToast 1", L.DayToast(1, LIFE.DaysPerYear), "DAY 1")
eq("DayToast 7", L.DayToast(7, LIFE.DaysPerYear), "DAY 7")
eq("DayToast 8", L.DayToast(8, LIFE.DaysPerYear), "DAY 8 · YEAR 2")
eq("DayToast 9", L.DayToast(9, LIFE.DaysPerYear), "DAY 9")
eq("DayToast 15", L.DayToast(15, LIFE.DaysPerYear), "DAY 15 · YEAR 3")
for i = 2, #TIERS do ok("Banner for " .. TIERS[i].id, type(L.Copy.Banners[TIERS[i].id]) == "string") end
eq("Banner LOCAL none", L.Copy.Banners.LOCAL, nil)
for i = 2, #TIERS do ok("TierVisits " .. TIERS[i].id, type(LIFE.TierVisits[TIERS[i].id]) == "string") end

-- Backfill (A11, A12): day 1 from today, the tier recorded silently, every first it can derive at 0, empty lists
local v4 = { v = 4, level = 6, xp = 1100, cred = 9000,
	career = { aura = 400, followers = 25000, placements = 3, hits = 1, sponsors = 1, gates = { studio_two = true }, careerLog = {} },
	credits = { { t = "Late Bus Home", a = "JUNO VALE", s = 2, d = 20261020 }, { t = "Gravel", a = "TAVI GLASS", s = 3, d = 20261021 } },
	cypher = { entered = 3, wins = 1 }, daw = { v = 2, slots = { s1 = { pattern = "x" } }, active = 1, saves = 4 },
	daily = { day = 20261029, streak = 7, done = {} } }
local b = L.Backfill(v4, 20261030, TIERS)
eq("Backfill day", b.day, 1)
eq("Backfill last == today", b.last, 20261030)
eq("Backfill tier", b.tier, "FAMOUS")
for _, id in ipairs({ "placement", "hit", "hall", "sponsor", "buzzing", "known", "level5", "delivery", "delivery3", "cypher",
	"beat", "streak7" }) do
	eq("Backfill firsts." .. id, b.firsts[id], 0)
end
eq("Backfill no famous first", b.firsts.famous, nil)
eq("Backfill story empty", #b.story, 0)
eq("Backfill disco empty", #b.disco, 0)
eq("Backfill ribbons empty", next(b.ribbons), nil)
-- the brief's case: placements 3, hits 1, followers 25,000, THE HALL; nothing else
local brief = L.Backfill({ v = 4, level = 1, career = { followers = 25000, placements = 3, hits = 1, gates = { studio_two = true } } },
	20261030, TIERS)
eq("Backfill brief tier", brief.tier, "FAMOUS")
eq("Backfill brief placement", brief.firsts.placement, 0)
eq("Backfill brief hit", brief.firsts.hit, 0)
eq("Backfill brief hall", brief.firsts.hall, 0)
for _, id in ipairs({ "sponsor", "level5", "delivery", "delivery3", "cypher", "beat", "streak7" }) do
	eq("Backfill brief no " .. id, brief.firsts[id], nil)
end
-- edges
local function count(t) local n = 0; for _ in pairs(t) do n += 1 end; return n end
local fresh = L.Backfill({ v = 4, level = 1, xp = 0, career = { aura = 0, followers = 0, placements = 0, hits = 0, sponsors = 0,
	gates = {}, careerLog = {} }, credits = {} }, 20261030, TIERS)
eq("Backfill fresh day", fresh.day, 1)
eq("Backfill fresh tier", fresh.tier, "LOCAL")
eq("Backfill fresh no firsts", count(fresh.firsts), 0)
eq("Backfill fresh last", fresh.last, 20261030)
eq("Backfill fresh story", #fresh.story, 0)
local noCareer = L.Backfill({ v = 4 }, 20261030, TIERS)
eq("Backfill career nil tier", noCareer.tier, "LOCAL")
eq("Backfill career nil firsts", count(noCareer.firsts), 0)
local junkProf = L.Backfill({ v = 4, level = "x", career = "junk", credits = "junk", cypher = 7, daw = "junk", daily = true },
	20261030, TIERS)
eq("Backfill career junk tier", junkProf.tier, "LOCAL")
eq("Backfill career junk firsts", count(junkProf.firsts), 0)
local oddGates = L.Backfill({ career = { followers = "lots", placements = "3", gates = "open" } }, 20261030, TIERS)
eq("Backfill junk followers tier", oddGates.tier, "LOCAL")
eq("Backfill junk gates no hall", oddGates.firsts.hall, nil)
eq("Backfill numeric-string placements", oddGates.firsts.placement, 0)
local edge = L.Backfill({ level = 4, career = { followers = 999, gates = { studio_two = false } }, credits = { { s = 2 } },
	cypher = { wins = 0 }, daw = { v = 2, slots = {}, saves = 0 }, daily = { streak = 6 } }, 20261030, TIERS)
eq("Backfill 999 followers LOCAL", edge.tier, "LOCAL")
eq("Backfill no buzzing at 999", edge.firsts.buzzing, nil)
eq("Backfill level 4 no level5", edge.firsts.level5, nil)
eq("Backfill gate false no hall", edge.firsts.hall, nil)
eq("Backfill credits 2 stars: delivery", edge.firsts.delivery, 0)
eq("Backfill credits 2 stars: no delivery3", edge.firsts.delivery3, nil)
eq("Backfill 0 cypher wins", edge.firsts.cypher, nil)
eq("Backfill empty daw", edge.firsts.beat, nil)
eq("Backfill streak 6", edge.firsts.streak7, nil)
local v1daw = L.Backfill({ daw = { pattern = "1000100010001000" } }, 20261030, TIERS)
eq("Backfill v1 daw pattern is a save", v1daw.firsts.beat, 0)
local savesOnly = L.Backfill({ daw = { v = 2, slots = {}, saves = 2 } }, 20261030, TIERS)
eq("Backfill daw saves count", savesOnly.firsts.beat, 0)
-- keys stay strings and the lists stay arrays: the saved shape a DataStore keeps exactly
for k in pairs(b) do ok("Backfill key " .. tostring(k) .. " is a string", type(k) == "string") end
for k in pairs(b.firsts) do ok("Backfill firsts key " .. tostring(k) .. " is a string", type(k) == "string") end

-- Public: the one place year, tier, title and the ribbon ids are computed (the final review, F1)
local pub = L.Public({ day = 9, tier = "KNOWN", firsts = { hit = 9 }, ribbons = { sponsor = 9, hit = 9, t70_gone = 3 } }, LIFE)
eq("Public year", pub.year, 2)
eq("Public tier", pub.tier, "KNOWN")
eq("Public tierIndex", pub.tierIndex, 3)
eq("Public title", pub.title, "CHART MAKER")
eq("Public titleId", pub.titleId, "chart")
eq("Public ribbons in Config order, unknown ids out", table.concat(pub.ribbons, ","), "hit,sponsor")
local pubNil = L.Public(nil, LIFE)
eq("Public no life: year", pubNil.year, 1)
eq("Public no life: tier", pubNil.tier, "LOCAL")
eq("Public no life: title", pubNil.title, "NEW IN TOWN")
eq("Public no life: ribbons", #pubNil.ribbons, 0)
local pubJunk = L.Public({ day = "x", tier = "GOD", firsts = "no", ribbons = 5 }, LIFE)
eq("Public junk: year", pubJunk.year, 1)
eq("Public junk: tier", pubJunk.tier, "LOCAL")
eq("Public junk: ribbons", #pubJunk.ribbons, 0)
-- View's year, tier and title are Public's; its ribbons stay the saved map, so Public reads a view as it reads a life
local pubLife = { day = 15, tier = "ICON", firsts = { hit = 2 }, ribbons = { icon = 15, hit = 2 } }
local pubView = L.View(pubLife, LIFE, nil)
local fromView = L.Public(pubView, LIFE)
local fromLife = L.Public(pubLife, LIFE)
for _, k in ipairs({ "year", "tier", "tierIndex", "title", "titleId" }) do
	eq("View " .. k .. " is Public's", pubView[k], fromLife[k])
	eq("Public over a View " .. k, fromView[k], fromLife[k])
end
eq("Public over a View: ribbons", table.concat(fromView.ribbons, ","), table.concat(fromLife.ribbons, ","))
eq("View keeps the ribbons map", pubView.ribbons.icon, 15)

-- the ribbon toast: the labels of what just landed; nil for nothing to show (F1)
eq("RibbonToast one", L.RibbonToast({ "hit" }), "RIBBON: CHARTED")
eq("RibbonToast two", L.RibbonToast({ "hit", "sponsor" }), "RIBBON: CHARTED · BRAND DEAL")
eq("RibbonToast none", L.RibbonToast({}), nil)
eq("RibbonToast unknown id", L.RibbonToast({ "t70_gone" }), nil)

-- the tier banner: with no walk-ins to bring the visit, the headline alone (F5)
for i = 2, #TIERS do
	local id = TIERS[i].id
	eq("BannerText " .. id .. " with visits", L.BannerText(id, true), L.Copy.Banners[id])
	local head = L.BannerText(id, false)
	eq("BannerText " .. id .. " without visits is the headline", head, string.match(L.Copy.Banners[id], "^[^\n]+"))
	ok("BannerText " .. id .. " without visits is one line", head ~= nil and not plain(head, "\n") and not plain(head, "coming by"))
end
eq("BannerText BUZZING headline", L.BannerText("BUZZING", false), "YOU'RE BUZZING")
eq("BannerText unknown tier", L.BannerText("t70_gone", true), nil)
-- the cold spell's exit banner (Wave 3 design 4.2, copy doc 5): a CAPS headline over a lowercase line, as the tier banners
eq("ThawBanner", L.Copy.ThawBanner, "YOU'RE BACK\npeople are calling again")

-- the DAY toast read: once a value, whenever it's read; nothing for a missing attribute (F3)
local once = L.DayToastOnce(LIFE.DaysPerYear)
eq("DayToastOnce no attribute yet", once(nil), nil)
eq("DayToastOnce first read", once(15), "DAY 15 · YEAR 3")
eq("DayToastOnce same value", once(15), nil)
eq("DayToastOnce next day", once(16), "DAY 16")
eq("DayToastOnce a second reader starts clean", L.DayToastOnce(LIFE.DaysPerYear)(16), "DAY 16")

-- copy moved or changed by the final review (F9, F12, F14)
eq("no TabLabel", L.Copy.TabLabel, nil)
eq("StoryFooter", L.Copy.StoryFooter, "Story · Backspace / B to close")
eq("RibbonPrefix", L.Copy.RibbonPrefix, "🎗 ")
eq("Legend line", L.Copy.Story.legend, "You bought the Legend nameplate.")
eq("Legend StoryText", L.StoryText({ d = 20, k = "legend" }, {}), "DAY 20 · You bought the Legend nameplate.")
ok("LifeFailed is a line", type(L.Copy.LifeFailed) == "string" and #L.Copy.LifeFailed > 0)
ok("LifeFailed promises no retry", type(L.Copy.LifeFailed) == "string" and not plain(string.lower(L.Copy.LifeFailed), "again"))

if #fails > 0 then error(#fails .. " life rules case(s) failed: " .. table.concat(fails, "; ")) end
print("SPEC OK: life rules")
