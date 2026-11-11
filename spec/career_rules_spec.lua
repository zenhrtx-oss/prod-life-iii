-- CLI spec for Modules/CareerRules (career stat clamps, defaults, the Career view of a profile, gate checks, the Aura
-- heal amount).
-- Run: sh tools/spec.sh career_rules
local CR = require("../src/ReplicatedStorage/OK/Modules/CareerRules")

local fails = {}
local function eq(name, got, want)
	if got ~= want then table.insert(fails, string.format("%s: expected %s, got %s", name, tostring(want), tostring(got))) end
end

-- STATS order is the row order of Check and the stat order everywhere else
eq("STATS size", #CR.STATS, 5)
for i, s in ipairs({ "aura", "followers", "placements", "hits", "sponsors" }) do eq("STATS[" .. i .. "]", CR.STATS[i], s) end

-- Clamp: floor; aura may go negative, every other stat stops at 0
eq("Clamp aura -12.7", CR.Clamp("aura", -12.7), -13)
eq("Clamp aura 12.7", CR.Clamp("aura", 12.7), 12)
eq("Clamp followers -5", CR.Clamp("followers", -5), 0)
eq("Clamp followers 1200.9", CR.Clamp("followers", 1200.9), 1200)
eq("Clamp placements -1", CR.Clamp("placements", -1), 0)
eq("Clamp hits 2", CR.Clamp("hits", 2), 2)
eq("Clamp sponsors -0.5", CR.Clamp("sponsors", -0.5), 0)

-- Defaults: the prof.career shape, a fresh table (and fresh gates/log) every call
local d1, d2 = CR.Defaults(), CR.Defaults()
for _, s in ipairs(CR.STATS) do eq("Defaults." .. s, d1[s], 0) end
eq("Defaults.sponsor", d1.sponsor, nil)
eq("Defaults.showSponsor", d1.showSponsor, true)
eq("Defaults.gates is a table", type(d1.gates), "table")
eq("Defaults.careerLog is a table", type(d1.careerLog), "table")
eq("Defaults fresh table", d1 ~= d2, true)
eq("Defaults fresh gates", d1.gates ~= d2.gates, true)
eq("Defaults fresh careerLog", d1.careerLog ~= d2.careerLog, true)

-- Have: money from prof.cred, stats from prof.career; a missing career reads as zeros
local h = CR.Have({ cred = 50 })
eq("Have money", h.money, 50)
for _, s in ipairs(CR.STATS) do eq("Have zero " .. s, h[s], 0) end
eq("Have no-career sponsor", h.sponsor, nil)
eq("Have no-career showSponsor", h.showSponsor, true)
eq("Have no-career gates", type(h.gates) == "table" and next(h.gates) == nil, true)
eq("Have no cred", CR.Have({}).money, 0)

local gates = { studio_two = true }
local prof = { cred = 700, career = { aura = -40, followers = 1200, placements = 2, hits = 1, sponsors = 1, sponsor = "brand",
	showSponsor = false, gates = gates, careerLog = {} } }
local h2 = CR.Have(prof)
eq("Have money 700", h2.money, 700)
eq("Have aura", h2.aura, -40)
eq("Have followers", h2.followers, 1200)
eq("Have placements", h2.placements, 2)
eq("Have hits", h2.hits, 1)
eq("Have sponsors", h2.sponsors, 1)
eq("Have sponsor", h2.sponsor, "brand")
eq("Have showSponsor false", h2.showSponsor, false)
eq("Have gates copied", h2.gates ~= gates and h2.gates.studio_two == true, true)
eq("Have partial career", CR.Have({ career = { aura = 5 } }).followers, 0)
eq("Have showSponsor nil -> true", CR.Have({ career = { aura = 5 } }).showSponsor, true)

-- Check: rows in STATS order for the stats in needs, money as its own row
local c = CR.Check({ money = 4999, placements = 1, aura = 300 }, { placements = 1, aura = 300 }, 5000)
eq("Check short money ok", c.ok, false)
eq("Check money.ok", c.money.ok, false)
eq("Check money.need", c.money.need, 5000)
eq("Check money.have", c.money.have, 4999)
eq("Check rows", #c.rows, 2)
eq("Check row1 stat", c.rows[1] and c.rows[1].stat, "aura")
eq("Check row1 need", c.rows[1] and c.rows[1].need, 300)
eq("Check row1 have", c.rows[1] and c.rows[1].have, 300)
eq("Check row1 ok", c.rows[1] and c.rows[1].ok, true)
eq("Check row2 stat", c.rows[2] and c.rows[2].stat, "placements")
eq("Check row2 ok", c.rows[2] and c.rows[2].ok, true)
local c2 = CR.Check({ money = 5000, placements = 1, aura = 300 }, { placements = 1, aura = 300 }, 5000)
eq("Check enough money ok", c2.ok, true)
eq("Check enough money.ok", c2.money.ok, true)
local c3 = CR.Check({ money = 9000, placements = 0, aura = 300 }, { placements = 1, aura = 300 }, 5000)
eq("Check short stat ok", c3.ok, false)
eq("Check short stat row", c3.rows[2] and c3.rows[2].ok, false)
eq("Check short stat money.ok", c3.money.ok, true)
local c4 = CR.Check({ money = 0 })
eq("Check no needs ok", c4.ok, true)
eq("Check no needs rows", #c4.rows, 0)
eq("Check no cost need", c4.money.need, 0)
eq("Check missing stat reads 0", CR.Check({ money = 0 }, { hits = 1 }).rows[1].have, 0)

-- HealAmount: negative Aura heals toward 0 by at most max, never above 0; zero and positive Aura never change
eq("HealAmount -3", CR.HealAmount(-3, 5), 3)
eq("HealAmount -5", CR.HealAmount(-5, 5), 5)
eq("HealAmount -12", CR.HealAmount(-12, 5), 5)
eq("HealAmount 0", CR.HealAmount(0, 5), 0)
eq("HealAmount 40", CR.HealAmount(40, 5), 0)

-- ColdStep (Wave 3): the career goes cold on a deep Aura or a quiet spell, and thaws on a fire or a third delivery
local CFG = { aura = -50, quietDays = 3, rearmAura = -25 }
local function cold(c, rearm, aura, day, last, event)
	local c2, r2, ch = CR.ColdStep(c, rearm, aura, day, last, event, CFG)
	return c2, r2, ch
end
local c, r, ch = cold(nil, false, -100, 10, nil, "check")
eq("ColdStep lastDay nil warm", c, nil)
eq("ColdStep lastDay nil unchanged", ch, false)
c, r, ch = cold(nil, false, -51, 10, 10, "check")
eq("ColdStep aura cold", c and c.reason, "aura")
eq("ColdStep aura since", c and c.since, 10)
eq("ColdStep aura news", c and c.news, false)
eq("ColdStep aura changed", ch, true)
c, r, ch = cold(nil, true, -51, 10, 10, "check")
eq("ColdStep rearm blocks aura", c, nil)
eq("ColdStep rearm blocks changed", ch, false)
c, r, ch = cold(nil, false, 0, 13, 10, "check")
eq("ColdStep quiet 3 days", c and c.reason, "quiet")
c, r, ch = cold(nil, false, 0, 12, 10, "check")
eq("ColdStep quiet 2 days warm", c, nil)
local held = { since = 5, reason = "aura", news = true }
c, r, ch = cold(held, false, 100, 20, 20, "check")
eq("ColdStep check keeps cold", c, held)
eq("ColdStep check keeps unchanged", ch, false)
c, r, ch = cold(held, false, 100, 20, 20, "fire")
eq("ColdStep fire thaws", c, nil)
eq("ColdStep fire changed", ch, true)
eq("ColdStep aura thaw sets rearm", r, true)
c, r = cold({ since = 5, reason = "quiet" }, false, 100, 20, 20, "delivery3")
eq("ColdStep delivery3 thaws", c, nil)
eq("ColdStep quiet thaw no rearm", r, false)
c, r, ch = cold(nil, true, -20, 20, 20, "check")
eq("ColdStep clears rearm", r, false)
eq("ColdStep clears rearm changed", ch, true)
c, r, ch = cold(nil, true, -30, 20, 20, "check")
eq("ColdStep keeps rearm above bar", r, true)
c, r, ch = cold(nil, false, 0, 20, 20, "fire")
eq("ColdStep fire while warm", ch, false)
local keep = { since = 1, reason = "quiet" }
CR.ColdStep(keep, false, 0, 5, 5, "fire", CFG)
eq("ColdStep thaw doesn't mutate: since", keep.since, 1)
eq("ColdStep thaw doesn't mutate: reason", keep.reason, "quiet")

-- boundaries and the event rules
c = cold(nil, false, -50, 10, 10, "check")
eq("ColdStep aura -50 warm", c, nil)
c = cold(nil, false, -51, 10, 10, "check")
eq("ColdStep aura -51 cold", c and c.reason, "aura")
c, r, ch = cold(nil, true, -25, 10, 10, "check")
eq("ColdStep rearm clears at -25: rearm", r, false)
eq("ColdStep rearm clears at -25: changed", ch, true)
c = cold(nil, false, 0, 13, 10, "check")
eq("ColdStep quiet since", c and c.since, 13)
c, r = cold({ since = 5, reason = "quiet" }, true, 0, 20, 20, "fire")
eq("ColdStep quiet thaw keeps rearm", r, true)
for _, ev in ipairs({ "delivery", "Check", "FIRE" }) do
	c, r, ch = cold(held, false, 100, 20, 20, ev)
	eq("ColdStep event " .. ev .. " unchanged", c, held)
	eq("ColdStep event " .. ev .. " changed", ch, false)
end
c, r, ch = CR.ColdStep(held, false, 100, 20, 20, nil, CFG)
eq("ColdStep nil event unchanged", c, held)
eq("ColdStep nil event changed", ch, false)
c, r, ch = cold(held, false, -999, 20, 20, "bogus")
eq("ColdStep bogus event no entry check", ch, false)
c, r, ch = cold(held, false, 100, 20, nil, "fire")
eq("ColdStep fire with lastDay nil thaws", c, nil)
eq("ColdStep fire with lastDay nil changed", ch, true)
c, r, ch = cold(held, false, -999, 20, nil, "check")
eq("ColdStep check with lastDay nil on cold", c, held)
eq("ColdStep check with lastDay nil on cold changed", ch, false)
c, r, ch = cold(held, true, -20, 20, 20, "check")
eq("ColdStep cold check clears rearm: stays cold", c, held)
eq("ColdStep cold check clears rearm: rearm", r, false)
eq("ColdStep cold check clears rearm: changed", ch, true)
-- the lastDay contract: the caller moves lastDay on a thaw
local q = cold(nil, false, 0, 13, 10, "check")
eq("ColdStep contract: quiet", q and q.reason, "quiet")
local th = cold(q, false, 0, 14, 10, "fire")
eq("ColdStep contract: thawed", th, nil)
local again = cold(th, false, 0, 14, 10, "check")
eq("ColdStep contract: stale lastDay re-chills", again and again.reason, "quiet")
eq("ColdStep contract: lastDay moved stays warm", (cold(th, false, 0, 14, 14, "check")), nil)
-- Task 4 fix round 1 (ruling C): any thaw re-arms while Aura is under cfg.aura at that moment, so a quiet spell that ends
-- deep in the red can't re-chill "aura" on the very next check (the exit is "earn it back", not a relapse); Aura back at
-- rearmAura clears it as before
local deep = { since = 5, reason = "quiet", news = true }
c, r, ch = cold(deep, false, -60, 20, 20, "fire")
eq("ColdStep quiet fire thaw at -60: warm", c, nil)
eq("ColdStep quiet fire thaw at -60: rearm", r, true)
eq("ColdStep quiet fire thaw at -60: changed", ch, true)
c, r, ch = cold(nil, r, -60, 20, 20, "check")
eq("ColdStep after the -60 thaw, a check at -60 stays warm", c, nil)
eq("ColdStep after the -60 thaw, rearm holds", r, true)
c, r, ch = cold(nil, r, -20, 20, 20, "check")
eq("ColdStep after the -60 thaw, -20 clears rearm", r, false)
eq("ColdStep after the -60 thaw, -20 changed", ch, true)
c, r = cold(deep, false, -60, 20, 20, "delivery3")
eq("ColdStep quiet delivery3 thaw at -60: rearm", r, true)
c, r = cold(deep, false, -50, 20, 20, "fire")
eq("ColdStep quiet thaw at -50 (not under the bar): no rearm", r, false)
c, r = cold(deep, false, -51, 20, 20, "fire")
eq("ColdStep quiet thaw at -51: rearm", r, true)
c, r = cold({ since = 5, reason = "aura" }, false, 10, 20, 20, "fire")
eq("ColdStep aura thaw at +10 still re-arms", r, true)

if #fails > 0 then error(#fails .. " career rules case(s) failed: " .. table.concat(fails, "; ")) end
print("SPEC OK: career rules")
