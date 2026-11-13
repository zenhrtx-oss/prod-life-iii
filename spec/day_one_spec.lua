-- CLI spec for Modules/DayOneRules and Data/DayOne (the Day One plan, Task 1): which card comes next from the saved
-- tour (Next, over every `got` combination), the stale-card check at send time (Stale, ruling B1), the card a delivery
-- queues (Delivered, ruling B3), the starter brief, the haggle and its one-time bonus, the walk-in hold (Holds; the final
-- fix: a taken, undelivered request holds it until HoldTakenMax), the
-- loop's clock (Due: expire, send, return; ruling F1: no return once HoldMax has passed; fix 1: card 1 returns only
-- with ReturnMin seconds left before HoldMax), the tool card 3 names (Tool, ruling F2: price-0 rows are everyone's and
-- never offered; fix 1: rows with needs are skipped), the fills, the card payload, the saved d1's repair, the
-- words' shapes and lengths (research/day_one/copy_2026-11-12.md) and Config.DayOne's own checks.
-- Run: sh tools/spec.sh day_one
local R = require("../src/ReplicatedStorage/OK/Modules/DayOneRules")
local D = require("../src/ReplicatedStorage/OK/Data/DayOne")
local Format = require("../src/ReplicatedStorage/OK/Modules/Format")
local E = require("./economy_fixture")

-- a literal copy of Config.DayOne (src/ReplicatedStorage/OK/Config.lua); Task 2's t120 check pins it to live Config
local DAYONE = { Enabled = true, FirstCard = 1, WakeWait = 20, LookAround = 30, ReturnMin = 15, HoldMax = 70, HoldTakenMax = 240,
	CardSeconds = 180, AfterDeliver = 3, AfterSpeakers = 4, VisitAfter = { 5, 7 }, HaggleOdds = 50, HaggleBonus = 50, PrivateXP = 10 }
-- Data/Artists needs Roblox globals (Color3), so its briefs are a literal copy of { id, artist, starter } (preflight m3;
-- t120 checks the real list), and JUNO's pay (j1's reward.cred) and colour (her Color3 as 0-255) are literals too
local BRIEFS = {
	{ id = "j1", artist = "juno", starter = true }, { id = "j2", artist = "juno" }, { id = "j3", artist = "juno" },
	{ id = "j4", artist = "juno" }, { id = "j5", artist = "juno" }, { id = "t1", artist = "tavi" }, { id = "t2", artist = "tavi" },
	{ id = "t3", artist = "tavi" }, { id = "t4", artist = "tavi" }, { id = "r1", artist = "rue" }, { id = "r2", artist = "rue" },
	{ id = "r3", artist = "rue" }, { id = "v1", artist = "vesper" }, { id = "v2", artist = "vesper" }, { id = "v3", artist = "vesper" },
	{ id = "n1", artist = "nyx" }, { id = "n2", artist = "nyx" }, { id = "n3", artist = "nyx" }, { id = "i1", artist = "indigo" },
	{ id = "i2", artist = "indigo" }, { id = "i3", artist = "indigo" },
}
local J1_PAY = 400
local JUNO = { name = "JUNO VALE", color = { 255, 150, 60 } }
-- a literal copy of the live Config.Gear rows, in order (their Color3 and desc fields left out: Tool never reads them)
local GEAR = {
	{ id = "808", name = "Sub Boom 808", kind = "tool", feature = "Bass", price = 0, level = 1 },
	{ id = "rollfx", name = "Roll FX", kind = "tool", feature = "Rolls", price = 250, level = 1 },
	{ id = "swing", name = "Swing Unit", kind = "tool", feature = "Swing", price = 350, level = 1 },
	{ id = "neon_ice", name = "On-air neon: Ice", kind = "neon", price = 900, level = 3 },
	{ id = "kit_tape", name = "TAPE kit", kind = "kit", kit = "tape", price = 1200, level = 3 },
	{ id = "voice_pluck", name = "Pluck voice", kind = "voice", voice = "pluck", price = 600, level = 2 },
	{ id = "voice_chime", name = "Chime voice", kind = "voice", voice = "chime", price = 1100, level = 4 },
	{ id = "plate_gold", name = "Gold nameplate", kind = "plate", price = 1500, level = 5 },
	{ id = "kit_iron", name = "IRON kit", kind = "kit", kit = "iron", price = 2000, level = 6, needs = { placements = 1 } },
	{ id = "neon_gold", name = "On-air neon: Gold", kind = "neon", price = 2200, level = 7 },
	{ id = "spk_monitors", name = "Desk monitors", kind = "speakers", tier = 2, price = 500, level = 2, needs = { followers = 200 } },
	{ id = "spk_studio", name = "Studio monitors", kind = "speakers", tier = 3, price = 3000, level = 5, needs = { placements = 2, followers = 5000 } },
	{ id = "fit_cuban", name = "Cuban link", kind = "fit", slot = "neck", fit = "cuban", price = 3500, level = 1, needs = { placements = 2, followers = 5000 } },
	{ id = "fit_snapback", name = "Sponsor snapback", kind = "fit", slot = "head", fit = "snapback", price = 1500, level = 1, needs = { sponsors = 1 } },
	{ id = "fit_shades", name = "Shades", kind = "fit", slot = "face", fit = "shades", price = 2000, level = 1, needs = { aura = 500 } },
	{ id = "plate_legend", name = "Legend nameplate", kind = "plate", price = 4000, level = 10, needs = { hits = 1, followers = 20000, aura = 1000 } },
}
local GEAR_BY = {}
for _, g in ipairs(GEAR) do GEAR_BY[g.id] = g end
-- Systems/Tour's five steps, in order, and their texts today (the hub lines keep these words, JUNO VALE through {artist})
local STEPS = { "open", "take", "deliver", "monitors", "gear" }
local TOUR_TEXT = {
	open = "Open the studio PC or a studio laptop",
	take = "Take the starter request from JUNO VALE",
	deliver = "Make every ask tick green, then press DELIVER",
	monitors = "Press ON MONITORS so the room hears it",
	gear = "Spend your money at the gear rack",
}
local REWARD_XP = 50 -- Systems/Tour.RewardXP (economy_fixture's tourXP, t46-pinned)
-- the 12 tokens of the copy doc's token table
local TOKENS = { "artist", "pay", "ask", "money", "tool", "toolprice", "goal", "goalprice", "goalfollowers", "xp", "reward", "reason" }

local fails = {}
local function eq(name, got, want)
	if got ~= want then table.insert(fails, string.format("%s: expected %s, got %s", name, tostring(want), tostring(got))) end
end
local function ok(name, cond) if not cond then table.insert(fails, name) end end
local function plain(s, sub) return type(s) == "string" and string.find(s, sub, 1, true) ~= nil end
local function len(s) return utf8.len(s) or #s end -- characters, not bytes: "·" is 2 bytes
local function tour(ids, extra)
	local t = { got = {} }
	for _, id in ipairs(ids) do t.got[id] = true end
	for k, v in pairs(extra or {}) do t[k] = v end
	return t
end

-- the real fills, as Systems/DayOne builds them: JUNO's pay from j1 ($400), the ask = pay + HaggleBonus, a fresh
-- profile's $625 after its first delivery, the tool Tool picks, the Desk monitors as the goal, PrivateXP, the tour's XP
-- and the longest refusal code. artistId and color are not tokens: Card puts them on a face card's visitor
local monitors = GEAR_BY.spk_monitors
local VARS = {
	artist = JUNO.name, artistId = "juno", color = JUNO.color,
	pay = Format.Money(J1_PAY), ask = Format.Money(J1_PAY + DAYONE.HaggleBonus), money = Format.Money(625),
	tool = GEAR_BY.rollfx.name, toolprice = Format.Money(GEAR_BY.rollfx.price),
	goal = monitors.name, goalprice = Format.Money(monitors.price), goalfollowers = monitors.needs.followers,
	xp = DAYONE.PrivateXP, reward = REWARD_XP, reason = "cooldown",
}
local NOTOOL = table.clone(VARS)
NOTOOL.tool, NOTOOL.toolprice = nil, nil
-- the longest fill of every token (copy doc §0 and preflight m1): the starter's name; "$1,050" for the ask (so "$1,000"
-- for the pay); a 5-digit balance; the longest priced tool; 3-digit XP; the longest PlayLocal refusal code
local LONGEST = {
	artist = "JUNO VALE", pay = "$1,000", ask = "$1,050", money = "$12,345", tool = "Swing Unit", toolprice = "$350",
	goal = "Desk monitors", goalprice = "$500", goalfollowers = "200", xp = "100", reward = "100", reason = "cooldown",
}

-- Next: the card the saved tour names ------------------------------------------------------------------------------
eq("Next {}", R.Next(tour({})), "dayone")
eq("Next { open }", R.Next(tour({ "open" })), "dayone")
eq("Next { take }", R.Next(tour({ "take" })), nil)
eq("Next { open, take }", R.Next(tour({ "open", "take" })), nil)
eq("Next { take, deliver }", R.Next(tour({ "take", "deliver" })), "speakers")
eq("Next { take, deliver, monitors }", R.Next(tour({ "take", "deliver", "monitors" })), "spend")
eq("Next { take, monitors } (still making the beat)", R.Next(tour({ "take", "monitors" })), nil)
eq("Next { take, deliver, gear }", R.Next(tour({ "take", "deliver", "gear" })), "speakers")
eq("Next all five, done unset (defensive)", R.Next(tour(STEPS)), "spend")
eq("Next all five, done", R.Next(tour(STEPS, { done = true })), nil)
eq("Next nothing got, done", R.Next(tour({}, { done = true })), nil)
eq("Next skipped", R.Next(tour({ "take", "deliver" }, { skipped = true })), nil)
eq("Next done and skipped", R.Next(tour({}, { done = true, skipped = true })), nil)
eq("Next nil tour", R.Next(nil), "dayone")
eq("Next junk tour", R.Next("x"), "dayone")
eq("Next junk got", R.Next({ got = 5 }), "dayone")
eq("Next no got", R.Next({}), "dayone")
-- every got combination (Review Focus 2): "open" is never read, and done always wins
for mask = 0, 31 do
	local ids = {}
	for i, id in ipairs(STEPS) do if (mask // 2 ^ (i - 1)) % 2 == 1 then table.insert(ids, id) end end
	local g = tour(ids).got
	local want -- the rule, written out: the first missing of take, deliver, monitors, gear (none missing: "spend")
	if not g.take then want = "dayone"
	elseif not g.deliver then want = nil
	elseif not g.monitors then want = "speakers"
	else want = "spend" end
	local name = "Next {" .. table.concat(ids, ",") .. "}"
	eq(name, R.Next(tour(ids)), want)
	local flipped = {}
	for _, id in ipairs(ids) do if id ~= "open" then table.insert(flipped, id) end end
	if not g.open then table.insert(flipped, "open") end
	eq(name .. ": open is never read", R.Next(tour(flipped)), want)
	eq(name .. ", done", R.Next(tour(ids, { done = true })), nil)
end

-- Stale (ruling B1): at send time, a queued or returned card whose id is no longer Next's is dropped
eq("Stale: card 1 returns after the request was taken from the laptop", R.Stale(tour({ "open", "take" }), "dayone"), true)
eq("Stale: card 1 returns, nothing taken", R.Stale(tour({ "open" }), "dayone"), false)
eq("Stale: a queued speakers card after monitors got", R.Stale(tour({ "take", "deliver", "monitors" }), "speakers"), true)
eq("Stale: a queued speakers card, monitors still missing", R.Stale(tour({ "take", "deliver" }), "speakers"), false)
eq("Stale: a queued spend card", R.Stale(tour({ "take", "deliver", "monitors" }), "spend"), false)
eq("Stale: anything once the tour is done", R.Stale(tour(STEPS, { done = true }), "spend"), true)
eq("Stale: anything once skipped", R.Stale(tour({}, { done = true, skipped = true }), "dayone"), true)

-- Delivered (ruling B3): after Tour has written "deliver", the card the delivery queues is whatever Next names;
-- "speakers" only from your own room's laptop, "spend" from anywhere
eq("Delivered { take, deliver } at your laptop", R.Delivered(tour({ "open", "take", "deliver" }), true), "speakers")
eq("Delivered { take, deliver } at the hub (no card 2)", R.Delivered(tour({ "open", "take", "deliver" }), false), nil)
eq("Delivered: an old { take, monitors } save reaches spend (hub)", R.Delivered(tour({ "take", "monitors", "deliver" }), false), "spend")
eq("Delivered: an old { take, monitors } save reaches spend (laptop)", R.Delivered(tour({ "take", "monitors", "deliver" }), true), "spend")
eq("Delivered { take, deliver, gear } at your laptop", R.Delivered(tour({ "take", "deliver", "gear" }), true), "speakers")
eq("Delivered: the delivery finished the tour", R.Delivered(tour(STEPS, { done = true }), true), nil)
eq("Delivered: skipped", R.Delivered(tour({ "take", "deliver" }, { done = true, skipped = true }), true), nil)
eq("Delivered: deliver not written yet", R.Delivered(tour({ "take" }), true), nil)
eq("Delivered: a junk own flag is not your laptop", R.Delivered(tour({ "take", "deliver" }), "yes"), nil)
-- B3's real path, step by step on one saved tour (D1-T3): ON MONITORS pressed before any delivery leaves { open, take,
-- monitors }. While you make the beat the tour names no card (Next nil: the chain only holds the first visit for
-- HoldMax), and a Delivered read before Tour writes "deliver" queues nothing; Systems/DayOne writes "deliver" first,
-- and then the delivery queues card 3 from anywhere. Card 2 is stale on that save, and card 3 ends the tour
local old = tour({ "open", "take", "monitors" })
eq("B3 path: before the delivery Next names no card", R.Next(old), nil)
eq("B3 path: Delivered before deliver is written queues nothing", R.Delivered(old, true), nil)
old.got.deliver = true -- Tour.Advance(p, "deliver"), as Systems/DayOne's Delivered listener runs it first
eq("B3 path: after the delivery Next is spend", R.Next(old), "spend")
eq("B3 path: the delivery queues spend at the hub", R.Delivered(old, false), "spend")
eq("B3 path: the delivery queues spend at your laptop", R.Delivered(old, true), "spend")
eq("B3 path: card 2 is stale on that save", R.Stale(old, "speakers"), true)
for _, id in ipairs(STEPS) do old.got[id] = true end
old.done = true -- Tour.Finish (card 3's rack or save)
eq("B3 path: card 3's end finishes the tour (no card after)", R.Next(old), nil)

-- Starter: the one brief marked starter ----------------------------------------------------------------------------
local st = R.Starter(BRIEFS)
eq("Starter id", st and st.id, "j1")
eq("Starter artist", st and st.artist, "juno")
local two = { { id = "a", starter = true }, { id = "b" }, { id = "c", starter = true } }
eq("Starter: two starters", R.Starter(two), nil)
eq("Starter: none", R.Starter({ { id = "a" }, { id = "b", starter = "yes" } }), nil)
eq("Starter: empty", R.Starter({}), nil)
eq("Starter: junk", R.Starter("x"), nil)
eq("Starter: nil", R.Starter(nil), nil)

-- Haggle: good when roll * 100 < odds ------------------------------------------------------------------------------
eq("Haggle 0.49 at 50", R.Haggle(0.49, 50), "good")
eq("Haggle 0.5 at 50", R.Haggle(0.5, 50), "bad")
eq("Haggle 0 at 50", R.Haggle(0, 50), "good")
eq("Haggle 0.99 at 50", R.Haggle(0.99, 50), "bad")
eq("Haggle 0 at 0", R.Haggle(0, 0), "bad")
eq("Haggle 0.5 at 0", R.Haggle(0.5, 0), "bad")
eq("Haggle 0.999 at 0", R.Haggle(0.999, 0), "bad")
eq("Haggle 0.99 at 100", R.Haggle(0.99, 100), "good")
eq("Haggle junk roll", R.Haggle(nil, 50), "bad")
eq("Haggle junk odds", R.Haggle(0.1, nil), "bad")

-- Bonus: HaggleBonus once, for a good haggle, unpaid, on the starter's first delivery --------------------------------
local B = DAYONE.HaggleBonus
local good = { v = 1, haggle = "good", paid = false, private = false }
eq("Bonus good, unpaid, j1, first", R.Bonus(good, "j1", "j1", true, B), 50)
eq("Bonus paid", R.Bonus({ v = 1, haggle = "good", paid = true, private = false }, "j1", "j1", true, B), 0)
eq("Bonus bad", R.Bonus({ v = 1, haggle = "bad", paid = false, private = false }, "j1", "j1", true, B), 0)
eq("Bonus nil haggle", R.Bonus({ v = 1, paid = false, private = false }, "j1", "j1", true, B), 0)
eq("Bonus j2", R.Bonus(good, "j2", "j1", true, B), 0)
eq("Bonus first false", R.Bonus(good, "j1", "j1", false, B), 0)
eq("Bonus no d1", R.Bonus(nil, "j1", "j1", true, B), 0)
eq("Bonus no starter", R.Bonus(good, "j1", nil, true, B), 0)
eq("Bonus no brief", R.Bonus(good, nil, nil, true, B), 0)
eq("Bonus junk amount", R.Bonus(good, "j1", "j1", true, "x"), 0)
eq("Bonus a repaired junk d1", R.Bonus(R.Repair({ haggle = "maybe", paid = "yes" }), "j1", "j1", true, B), 0)

-- Holds: the first-ever walk-in waits while Day One holds (cfg HoldMax 70) -----------------------------------------
eq("Holds started 0, now 69", R.Holds({ started = 0 }, 69, DAYONE), true)
eq("Holds started 0, now 70", R.Holds({ started = 0 }, 70, DAYONE), false)
eq("Holds a card open at now 500", R.Holds({ started = 0, card = { token = "day1:1", id = "dayone", at = 400 } }, 500, DAYONE), true)
eq("Holds a pending card at now 500", R.Holds({ started = 0, pending = { id = "speakers", at = 600 } }, 500, DAYONE), true)
eq("Holds done", R.Holds({ started = 0, done = true, card = { token = "day1:1", id = "dayone", at = 0 } }, 10, DAYONE), false)
eq("Holds nil chain", R.Holds(nil, 10, DAYONE), false)
eq("Holds a look-around's return past HoldMax (F1)", R.Holds({ started = 0, returnAt = 90 }, 90, DAYONE), false)
-- final fix (review Important 1, ruling a): the request taken and not yet delivered (you're making your first beat) holds
-- the first visitor until started + HoldTakenMax (240), so he never walks in mid-beat, and an abandoned beat still meets
-- him by then; the tour (4th argument) decides it, whichever brief was taken
local function tourGot(...) local g = {}; for _, id in ipairs({ ... }) do g[id] = true end; return { got = g } end
local making = tourGot("open", "take")
eq("Holds taken, not delivered, at 69", R.Holds({ started = 0 }, 69, DAYONE, making), true)
eq("Holds taken, not delivered, at 70 (past HoldMax: still making the beat)", R.Holds({ started = 0 }, 70, DAYONE, making), true)
eq("Holds taken, not delivered, at 239", R.Holds({ started = 0 }, 239, DAYONE, making), true)
eq("Holds taken, not delivered, at 240 (HoldTakenMax: released)", R.Holds({ started = 0 }, 240, DAYONE, making), false)
eq("Holds taken, not delivered, much later", R.Holds({ started = 0 }, 1000, DAYONE, making), false)
eq("Holds taken, not delivered, from a later start", R.Holds({ started = 100 }, 339, DAYONE, making), true)
eq("Holds taken, not delivered, from a later start, at +240", R.Holds({ started = 100 }, 340, DAYONE, making), false)
eq("Holds taken without open (take alone)", R.Holds({ started = 0 }, 200, DAYONE, tourGot("take")), true)
-- delivered: the old rule (HoldMax, or a card open or queued)
local delivered = tourGot("open", "take", "deliver")
eq("Holds delivered at 69", R.Holds({ started = 0 }, 69, DAYONE, delivered), true)
eq("Holds delivered at 70", R.Holds({ started = 0 }, 70, DAYONE, delivered), false)
eq("Holds delivered at 200", R.Holds({ started = 0 }, 200, DAYONE, delivered), false)
eq("Holds delivered, card 2 queued at 200", R.Holds({ started = 0, pending = { id = "speakers", at = 203 } }, 200, DAYONE, delivered), true)
eq("Holds an old save's deliver without take at 100", R.Holds({ started = 0 }, 100, DAYONE, tourGot("deliver")), false)
-- never taken: the old 70 s rule (the wanderer's first visit by ~90 s)
eq("Holds never taken at 69", R.Holds({ started = 0 }, 69, DAYONE, tourGot("open")), true)
eq("Holds never taken at 70", R.Holds({ started = 0 }, 70, DAYONE, tourGot("open")), false)
eq("Holds never taken, nothing got, at 70", R.Holds({ started = 0 }, 70, DAYONE, tourGot()), false)
-- a finished tour never extends it (the chain ends with it anyway)
eq("Holds taken on a done tour at 100", R.Holds({ started = 0 }, 100, DAYONE, { got = { take = true }, done = true }), false)
eq("Holds taken on a skipped tour at 100", R.Holds({ started = 0 }, 100, DAYONE, { got = { take = true }, done = true, skipped = true }), false)
eq("Holds taken, a done chain", R.Holds({ started = 0, done = true }, 100, DAYONE, making), false)
-- no tour, or a junk one: the old rule
eq("Holds no tour at 100", R.Holds({ started = 0 }, 100, DAYONE, nil), false)
eq("Holds a junk tour at 100", R.Holds({ started = 0 }, 100, DAYONE, "junk"), false)
eq("Holds a junk got at 100", R.Holds({ started = 0 }, 100, DAYONE, { got = "take" }), false)
eq("Holds no tour at 69", R.Holds({ started = 0 }, 69, DAYONE, nil), true)

-- Due: expire, then send, then return; nothing is sent over an open card ---------------------------------------------
local function card(id, at) return { token = "day1:t", id = id, at = at } end
eq("Due a card 180 s old", R.Due({ started = 0, card = card("speakers", 1000) }, 1180, DAYONE), "expire")
eq("Due a card 179 s old", R.Due({ started = 0, card = card("speakers", 1000) }, 1179, DAYONE), nil)
eq("Due card 1, 180 s old", R.Due({ started = 0, card = card("dayone", 1) }, 181, DAYONE), "expire")
eq("Due the returned card 1 at started + 70", R.Due({ started = 0, returned = true, card = card("dayone", 60) }, 70, DAYONE), "expire")
eq("Due the returned card 1 at started + 69", R.Due({ started = 0, returned = true, card = card("dayone", 60) }, 69, DAYONE), nil)
eq("Due the first card 1 at started + 70", R.Due({ started = 0, card = card("dayone", 1) }, 70, DAYONE), nil)
eq("Due the first card 1 at started + 70, returned false", R.Due({ started = 0, returned = false, card = card("dayone", 1) }, 70, DAYONE), nil)
eq("Due a returned chain's speakers card at started + 70", R.Due({ started = 0, returned = true, card = card("speakers", 65) }, 70, DAYONE), nil)
eq("Due pending at now", R.Due({ started = 0, pending = { id = "speakers", at = 100 } }, 100, DAYONE), "send")
eq("Due pending before now", R.Due({ started = 0, pending = { id = "speakers", at = 90 } }, 100, DAYONE), "send")
eq("Due pending after now", R.Due({ started = 0, pending = { id = "speakers", at = 101 } }, 100, DAYONE), nil)
eq("Due returnAt at now", R.Due({ started = 0, returnAt = 40 }, 40, DAYONE), "return")
eq("Due returnAt before now", R.Due({ started = 0, returnAt = 40 }, 45, DAYONE), "return")
eq("Due returnAt after now", R.Due({ started = 0, returnAt = 40 }, 39, DAYONE), nil)
eq("Due returned", R.Due({ started = 0, returnAt = 40, returned = true }, 45, DAYONE), nil)
-- fix 1 (controller ruling): card 1 comes back LookAround after "look around first", and only when at least ReturnMin
-- seconds are left before HoldMax (started + HoldMax - returnAt >= ReturnMin); otherwise it never comes back
local function look(at) return { started = 0, returnAt = at + DAYONE.LookAround } end
-- look at +5: back at +35, open until the HoldMax expiry at +70
eq("Due look at +5: not back at +34", R.Due(look(5), 34, DAYONE), nil)
eq("Due look at +5: back at +35", R.Due(look(5), 35, DAYONE), "return")
local back5 = { started = 0, returnAt = 35, returned = true, card = card("dayone", 35) } -- the sender set returned
eq("Due look at +5: the returned card stays open at +69", R.Due(back5, 69, DAYONE), nil)
eq("Due look at +5: the returned card expires at +70", R.Due(back5, 70, DAYONE), "expire")
eq("Holds look at +5: held while the returned card is open", R.Holds(back5, 69, DAYONE), true)
-- look at +25: back at +55, exactly ReturnMin (15 s) left, so it returns
eq("Due look at +25: back at +55 (15 s left)", R.Due(look(25), 55, DAYONE), "return")
eq("Due look at +25: a tick late, still back", R.Due(look(25), 55.6, DAYONE), "return")
-- look at +26: back would be at +56 with 14 s left, so it never comes back
for _, now in ipairs({ 56, 60, 69, 70, 120 }) do eq("Due look at +26: no return at +" .. now, R.Due(look(26), now, DAYONE), nil) end
eq("Holds look at +26: held until HoldMax", R.Holds(look(26), 69, DAYONE), true)
eq("Holds look at +26: released at HoldMax", R.Holds(look(26), 70, DAYONE), false)
-- a returned card is never sent twice (the sender sets returned = true as it sends the return)
eq("Due a sent return, card open", R.Due({ started = 0, returnAt = 35, returned = true, card = card("dayone", 35) }, 40, DAYONE), nil)
eq("Due a sent return, card closed again", R.Due({ started = 0, returnAt = 35, returned = true }, 50, DAYONE), nil)
eq("Due a sent return, card closed, much later", R.Due({ started = 0, returnAt = 35, returned = true }, 500, DAYONE), nil)
-- ruling F1: no return once HoldMax has passed since the chain started (a send held up past it is dropped)
eq("Due an eligible return at started + 69 (F1)", R.Due(look(25), 69, DAYONE), "return")
eq("Due an eligible return at started + 70 (F1)", R.Due(look(25), 70, DAYONE), nil)
-- the slow reader: card 1 lands late (WakeWait 20 + FirstCard 1), they look around at 30, so returnAt is 60 (10 s left)
local slow = look(30)
eq("Due slow reader at returnAt (no return)", R.Due(slow, 60, DAYONE), nil)
eq("Due slow reader much later (no return)", R.Due(slow, 500, DAYONE), nil)
eq("Holds slow reader at returnAt (held until HoldMax)", R.Holds(slow, 60, DAYONE), true)
eq("Holds slow reader past HoldMax (F1)", R.Holds(slow, 90, DAYONE), false)
-- priority
local all = { started = 0, card = card("dayone", 0), pending = { id = "speakers", at = 10 }, returnAt = 20 }
eq("Due expire beats send and return", R.Due(all, 180, DAYONE), "expire")
eq("Due send beats return", R.Due({ started = 0, pending = { id = "speakers", at = 10 }, returnAt = 20 }, 30, DAYONE), "send")
-- a due card isn't held back by an open one (the server closes the open card first; Stale drops a card Next no longer
-- names): card 2 left open after ON SPEAKERS mustn't hold card 3 for CardSeconds
eq("Due send over an open card (the server replaces it)", R.Due({ started = 0, card = card("speakers", 25), pending = { id = "spend", at = 10 } }, 30, DAYONE), "send")
eq("Due return over an open card (Stale drops it if card 1 isn't Next)", R.Due({ started = 0, card = card("speakers", 25), returnAt = 20 }, 30, DAYONE), "return")
eq("Due done", R.Due({ started = 0, done = true, card = card("dayone", 0), pending = { id = "spend", at = 0 } }, 500, DAYONE), nil)
eq("Due nil chain", R.Due(nil, 500, DAYONE), nil)
eq("Due nothing", R.Due({ started = 0 }, 500, DAYONE), nil)

-- Tool: the cheapest unowned priced row with a feature you can afford at your level ---------------------------------
local function toolId(...) local row = R.Tool(...) return row and row.id end
eq("Tool money 600, level 1, nothing owned", toolId(GEAR, {}, 600, 1), "rollfx")
eq("Tool a fresh profile's $625 (F2: never the $0 808)", toolId(GEAR, {}, 625, 1), "rollfx")
eq("Tool Roll FX owned", toolId(GEAR, { rollfx = true }, 600, 1), "swing")
eq("Tool Roll FX owned (a list)", toolId(GEAR, { "rollfx" }, 600, 1), "swing")
eq("Tool money 200", toolId(GEAR, {}, 200, 1), nil)
eq("Tool money 0 (the 808 is everyone's)", toolId(GEAR, {}, 0, 1), nil)
eq("Tool both owned, rich, level 10", toolId(GEAR, { rollfx = true, swing = true }, 99999, 10), nil)
eq("Tool level 2: no row without a feature (spk_monitors, voice_pluck)", toolId(GEAR, { rollfx = true, swing = true }, 600, 2), nil)
eq("Tool nil owned", toolId(GEAR, nil, 600, 1), "rollfx")
eq("Tool junk gear", toolId(nil, {}, 600, 1), nil)
-- preflight m4: a synthetic level-2 feature row, cheaper than Roll FX, beside the live copy
local LEVELLED = {}
for _, g in ipairs(GEAR) do table.insert(LEVELLED, g) end
table.insert(LEVELLED, { id = "test_l2", name = "Level Two Tool", kind = "tool", feature = "Test", price = 100, level = 2 })
eq("Tool level 1 never offers a level-2 row", toolId(LEVELLED, {}, 600, 1), "rollfx")
eq("Tool level 2 offers it", toolId(LEVELLED, {}, 600, 2), "test_l2")
-- fix 1 (review Minor 2): a feature row with needs is skipped, so card 3 never names a tool Gear.Buy would refuse
local NEEDY = {}
for _, g in ipairs(GEAR) do table.insert(NEEDY, g) end
table.insert(NEEDY, { id = "test_needs", name = "Needy Tool", kind = "tool", feature = "Test", price = 100, level = 1, needs = { followers = 200 } })
eq("Tool skips a feature row with needs", toolId(NEEDY, {}, 600, 1), "rollfx")
eq("Tool skips it at any level", toolId(NEEDY, { rollfx = true, swing = true }, 600, 10), nil)
for _, money in ipairs({ 0, 100, 250, 350, 600, 625, 5000 }) do
	local row = R.Tool(GEAR, {}, money, 1)
	ok("Tool money " .. money .. ": a priced feature row", row == nil or (type(row.feature) == "string" and row.price > 0 and row.level <= 1))
end

-- Fill ------------------------------------------------------------------------------------------------------------
local everyToken = {}
for _, k in ipairs(TOKENS) do table.insert(everyToken, "{" .. k .. "}") end
local filled, left = R.Fill(table.concat(everyToken, " "), VARS)
eq("Fill every token: left", left, false)
ok("Fill every token: no { left (" .. tostring(filled) .. ")", not plain(filled, "{"))
ok("Fill every token: the pay", plain(filled, "$400"))
ok("Fill every token: the ask", plain(filled, "$450"))
local unk, unkLeft = R.Fill("hi {nope} {pay}", VARS)
eq("Fill unknown token text", unk, "hi {nope} $400")
eq("Fill unknown token: left", unkLeft, true)
local nm, nmLeft = R.Fill("hi {name:x}", VARS)
eq("Fill {name:x} passes through", nm, "hi {name:x}")
eq("Fill {name:x} is not a Day One token", nmLeft, false)
eq("Fill a % in a value stays", (R.Fill("{v}", { v = "50% off" })), "50% off")
eq("Fill a number", (R.Fill("+{xp} XP", { xp = 10 })), "+10 XP")
eq("Fill a value that looks like a token", select(2, R.Fill("{a}", { a = "{b}" })), false)
local nilText, nilLeft = R.Fill(nil, VARS)
eq("Fill nil text", nilText, "")
eq("Fill nil text: left", nilLeft, false)
local noVars, noVarsLeft = R.Fill("{pay}", nil)
eq("Fill nil vars", noVars, "{pay}")
eq("Fill nil vars: left", noVarsLeft, true)

-- Card: the payload Systems/DayOne sends ----------------------------------------------------------------------------
local function texts(p) -- every text a player reads on the card
	local t = { p.header, p.walk, p.card.visitor.name, p.card.visitor.style, p.card.tag, p.card.line }
	for _, c in ipairs(p.card.choices) do table.insert(t, c.text) end
	return t
end
local cardIds = {}
for id in pairs(D.Cards) do table.insert(cardIds, id) end
table.sort(cardIds)
eq("Card ids", table.concat(cardIds, ","), "dayone,speakers,spend")
for _, id in ipairs(cardIds) do
	for _, v in ipairs({ { "full vars", VARS }, { "no tool", NOTOOL } }) do
		local p = R.Card(id, D, v[2])
		ok("Card " .. id .. " (" .. v[1] .. "): built", type(p) == "table" and type(p.card) == "table")
		if type(p) == "table" and type(p.card) == "table" then
			for i, s in ipairs(texts(p)) do
				ok("Card " .. id .. " (" .. v[1] .. ") text " .. i .. " is a string", type(s) == "string")
				ok("Card " .. id .. " (" .. v[1] .. ") text " .. i .. " has no { (" .. tostring(s) .. ")", not plain(s, "{"))
			end
			eq("Card " .. id .. ": source", p.source, "dayone")
			eq("Card " .. id .. ": token (the server sets it)", p.token, nil)
			eq("Card " .. id .. ": card id", p.card.id, "day1_" .. id)
			eq("Card " .. id .. ": header", p.header, D.Header)
			eq("Card " .. id .. ": walk", p.walk, D.Skip)
		end
	end
end
local c1, c2, c3 = R.Card("dayone", D, VARS), R.Card("speakers", D, VARS), R.Card("spend", D, VARS)
local c3none = R.Card("spend", D, NOTOOL)
eq("Card dayone: 3 choices", #c1.card.choices, 3)
eq("Card dayone: visitor id", c1.card.visitor.id, "juno")
eq("Card dayone: now is false", c1.now, false)
eq("Card dayone: name", c1.card.visitor.name, "JUNO VALE")
eq("Card dayone: colour", type(c1.card.visitor.color) == "table" and table.concat(c1.card.visitor.color, ","), "255,150,60")
ok("Card dayone: the line names the pay ($400)", plain(c1.card.line, "$400"))
ok("Card dayone: choice 2 names the ask ($450)", plain(c1.card.choices[2].text, "$450"))
eq("Card dayone: tag", c1.card.tag, D.Cards.dayone.tag)
eq("Card speakers: 2 choices", #c2.card.choices, 2)
eq("Card speakers: no visitor id", c2.card.visitor.id, nil)
eq("Card speakers: no colour", c2.card.visitor.color, nil)
eq("Card speakers: now is true", c2.now, true)
eq("Card spend: 2 choices", #c3.card.choices, 2)
eq("Card spend: no visitor id", c3.card.visitor.id, nil)
eq("Card spend: now is true (D1-T4 fix 1: over the beat maker too)", c3.now, true)
eq("Card spend with a tool: lines.tool", c3.card.line, (R.Fill(D.Cards.spend.lines.tool, VARS)))
ok("Card spend with a tool: names Roll FX and the Desk monitors", plain(c3.card.line, "Roll FX") and plain(c3.card.line, "Desk monitors"))
eq("Card spend without a tool: lines.none", c3none.card.line, (R.Fill(D.Cards.spend.lines.none, NOTOOL)))
ok("Card spend without a tool: names the Desk monitors", plain(c3none.card.line, "Desk monitors"))
eq("Card choices carry only their text", c1.card.choices[1].key, nil)
eq("Card unknown id", R.Card("nope", D, VARS), nil)
eq("Card junk data", R.Card("dayone", nil, VARS), nil)

-- Repair: the saved prof.tour.d1 ------------------------------------------------------------------------------------
local function d1str(d)
	if type(d) ~= "table" then return tostring(d) end
	local keys = {}
	for k in pairs(d) do table.insert(keys, tostring(k)) end
	table.sort(keys)
	local parts = {}
	for _, k in ipairs(keys) do table.insert(parts, k .. "=" .. tostring(d[k])) end
	return table.concat(parts, ",")
end
local CLEAN = "paid=false,private=false,v=1"
eq("Repair junk string", d1str(R.Repair("x")), CLEAN)
eq("Repair junk fields", d1str(R.Repair({ haggle = "maybe", paid = "yes" })), CLEAN)
eq("Repair nil", d1str(R.Repair(nil)), CLEAN)
eq("Repair a good one", d1str(R.Repair({ v = 1, haggle = "good", paid = true, private = true })), "haggle=good,paid=true,private=true,v=1")
eq("Repair a bad haggle", d1str(R.Repair({ v = 1, haggle = "bad", paid = false, private = false })), "haggle=bad,paid=false,private=false,v=1")
eq("Repair drops unknown keys", d1str(R.Repair({ v = 1, haggle = "good", paid = false, private = false, extra = 5, [1] = 2 })),
	"haggle=good,paid=false,private=false,v=1")

-- Data/DayOne: the words' shapes (copy doc §1-§6) ------------------------------------------------------------------
eq("Data Header", D.Header, "DAY ONE")
eq("Data Skip", D.Skip, "SKIP")
local function keysOf(t)
	local k = {}
	for key in pairs(t or {}) do table.insert(k, tostring(key)) end
	table.sort(k)
	return table.concat(k, ",")
end
local function choiceKeys(c)
	local k = {}
	for _, ch in ipairs(c.choices or {}) do table.insert(k, tostring(ch.key)) end
	return table.concat(k, ",")
end
eq("Data dayone choices", choiceKeys(D.Cards.dayone), "make,haggle,look")
eq("Data dayone face", D.Cards.dayone.face, true)
eq("Data speakers choices", choiceKeys(D.Cards.speakers), "speakers,private")
eq("Data speakers face", D.Cards.speakers.face, false)
eq("Data speakers now", D.Cards.speakers.now, true)
eq("Data spend choices", choiceKeys(D.Cards.spend), "rack,save")
eq("Data spend face", D.Cards.spend.face, false)
eq("Data spend now", D.Cards.spend.now, true)
eq("Data spend lines", keysOf(D.Cards.spend.lines), "none,tool")
ok("Data spend lines.none never names the tool", not plain(D.Cards.spend.lines.none, "{tool"))
eq("Data Toasts", keysOf(D.Toasts), "done,far,farHub,haggleBad,haggleGood,private,rackFar,speakers,speakersRefused")
eq("Data Marks keys", keysOf(D.Marks), "deliver,monitors,take")
eq("Data Steps keys", keysOf(D.Steps), "deliver,gear,monitors,open,take")
local isStep = {}
for _, id in ipairs(STEPS) do isStep[id] = true end
for id, s in pairs(D.Steps) do
	ok("Data Steps." .. tostring(id) .. " is one of Tour's five", isStep[id] == true)
	ok("Data Steps." .. tostring(id) .. ".hub is set", type(s) == "table" and type(s.hub) == "string" and s.hub ~= "")
	ok("Data Steps." .. tostring(id) .. ".room is set", type(s) == "table" and type(s.room) == "string" and s.room ~= "")
end
-- the hub lines keep Tour's words today (copy §5): filled with the artist, each equals its old text
for _, id in ipairs(STEPS) do
	eq("Data Steps." .. id .. ".hub keeps Tour's words", (R.Fill(D.Steps[id] and D.Steps[id].hub, { artist = JUNO.name })), TOUR_TEXT[id])
end

-- every string a player reads, with its kind and budget (copy doc, "Case and length by kind")
local rows = {}
local function row(where, kind, text, max) table.insert(rows, { where = where, kind = kind, text = text, max = max }) end
row("Header", "label", D.Header, 10)
row("Skip", "label", D.Skip, 14)
for _, id in ipairs(cardIds) do
	local c = D.Cards[id]
	local bubble = id == "spend" and 105 or 80
	row(id .. ".name", "name", c.name, 16)
	row(id .. ".tag", "tag", c.tag, 40)
	if c.line then row(id .. ".line", "bubble", c.line, bubble) end
	for k, l in pairs(c.lines or {}) do row(id .. ".lines." .. k, "bubble", l, bubble) end
	for i, ch in ipairs(c.choices) do row(id .. ".choice" .. i, "choice", ch.text, 48) end
end
for k, t in pairs(D.Toasts) do row("Toasts." .. k, "toast", t, 42) end
for k, s in pairs(D.Steps) do row("Steps." .. k .. ".hub", "step", s.hub, 48); row("Steps." .. k .. ".room", "step", s.room, 48) end
for k, t in pairs(D.Marks) do row("Marks." .. k, "mark", t, 32) end
local isToken = {}
for _, k in ipairs(TOKENS) do isToken[k] = true end
local used = {}
for _, r in ipairs(rows) do
	ok(r.where .. ": a string", type(r.text) == "string" and r.text ~= "")
	if type(r.text) == "string" then
		local long, leftover = R.Fill(r.text, LONGEST)
		eq(r.where .. ": no token left after the longest fill", leftover, false)
		ok(string.format("%s: %d characters after the longest fill (max %d): %s", r.where, len(long), r.max, long), len(long) <= r.max)
		for k in string.gmatch(r.text, "{([^}]*)}") do
			ok(r.where .. ": {" .. k .. "} is in the token table", isToken[k] == true)
			used[k] = true
		end
		ok(r.where .. ": JUNO only through {artist}", not plain(string.lower(r.text), "juno"))
		ok(r.where .. ": a money token carries its own $", not plain(r.text, "${"))
		ok(r.where .. ": never says Cred", not plain(string.lower(r.text), "cred"))
		if r.kind == "mark" then ok(r.where .. ": a mark has no token", not plain(r.text, "{")) end
	end
end
for _, k in ipairs(TOKENS) do ok("token {" .. k .. "} is used", used[k] == true) end

-- Config.DayOne -----------------------------------------------------------------------------------------------------
local firstEver = E.WALKINS.FirstEver -- Config.WalkIns.FirstEver (t46-pinned), { 15, 20 }
eq("Config FirstEver's literal", firstEver[2], 20)
ok("Config HoldMax + FirstEver[2] <= 90 (a wanderer's first visit by ~90 s)", DAYONE.HoldMax + firstEver[2] <= 90)
ok("Config VisitAfter[2] <= 8", DAYONE.VisitAfter[2] <= 8)
ok("Config VisitAfter is a range", DAYONE.VisitAfter[1] >= 0 and DAYONE.VisitAfter[1] <= DAYONE.VisitAfter[2])
eq("Config HaggleBonus", DAYONE.HaggleBonus, 50)
eq("Config the ask is $450", Format.Money(J1_PAY + DAYONE.HaggleBonus), "$450")
ok("Config HaggleOdds is a percentage", DAYONE.HaggleOdds >= 0 and DAYONE.HaggleOdds <= 100)
ok("Config CardSeconds > HoldMax (an open card holds past HoldMax)", DAYONE.CardSeconds > DAYONE.HoldMax)
-- final fix (ruling a): the first beat holds the first visitor longer than HoldMax, and an abandoned one still meets him by
-- HoldTakenMax + FirstEver[2] (about 4 min 20 s)
eq("Config HoldTakenMax", DAYONE.HoldTakenMax, 240)
ok("Config HoldTakenMax > HoldMax", DAYONE.HoldTakenMax > DAYONE.HoldMax)
ok("Config HoldTakenMax + FirstEver[2] <= 260", DAYONE.HoldTakenMax + firstEver[2] <= 260)
-- fix 1: the return fits before the first visitor. Card 1 lands at FirstCard (or WakeWait + FirstCard on the late path);
-- a look pressed at once there still returns with ReturnMin seconds left
eq("Config LookAround", DAYONE.LookAround, 30)
eq("Config ReturnMin", DAYONE.ReturnMin, 15)
ok("Config a quick look returns (FirstCard + LookAround + ReturnMin <= HoldMax)", DAYONE.FirstCard + DAYONE.LookAround + DAYONE.ReturnMin <= DAYONE.HoldMax)
ok("Config a quick look on the late card 1 returns (WakeWait + FirstCard + LookAround + ReturnMin <= HoldMax)",
	DAYONE.WakeWait + DAYONE.FirstCard + DAYONE.LookAround + DAYONE.ReturnMin <= DAYONE.HoldMax)

if #fails > 0 then error(#fails .. " day one case(s) failed: " .. table.concat(fails, "; ")) end
print(string.format("SPEC OK: day one (%d word rows; card 1 pays %s, asks %s; card 3 offers %s)", #rows, VARS.pay, VARS.ask,
	tostring(toolId(GEAR, {}, 625, 1))))
