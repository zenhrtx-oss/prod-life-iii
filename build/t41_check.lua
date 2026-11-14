-- Edit: the career system (walk-ins Task 3) with a fake store, a fake clock and fake players; no Init runs.
-- (a) a stored v3 profile loads at v5 with career and walkins defaults and its Money untouched, and those two shapes
-- are exactly v4's: v5 only adds prof.life, beside them (Wave 2; t70 has the life itself); (b) walkins survive
-- load, save and reload unchanged, and a broken career/walkins is replaced; (c) DataService.TakeCred clamps at the
-- balance; (d) Career.Add passes the career gate (caps, separate log, unknown sources pay 0), Career.Take clamps,
-- SetSponsor leaves the count alone; (e) Unlock studio_two: needs, money, ok, owned; the sponsor TV toggle never
-- spends; a refusal publishes nothing and answers with Fetch's last built state (launch audit A6); a bought room reports
-- "hall" to Life once, and only THE HALL's gate does; (f) Gear: needs refuse a buy after the level check, fits equip by slot,
-- plate_legend stays last, buying it reports "legend" through ctx.Life, and a failing Life never fails either;
-- Career.State's life is nil, the Career tab whole, when Life or its view fails; (g) producer cards carry the five stats
-- and the life's year, tier, title and ribbons, and never Money; (e2) R-T16 fix, I7, the ladder's order: Config's
-- real_studio row carries after = "home_studio"; with real_studio's needs met and its price in hand, Unlock answers "needs"
-- and spends nothing while home_studio isn't owned, and Career.State's real_studio row carries `after` and a check whose
-- `after` row (home_studio's name, not ok) keeps check.ok false (the Career tab's chip); with home_studio owned it unlocks.
local RS, SSS = game:GetService("ReplicatedStorage"), game:GetService("ServerScriptService")
local function freshRequire(mod) local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name; local ok, r = pcall(require, c); c:Destroy(); if not ok then error(r) end; return r end
local Cfg = freshRequire(RS.OK.Config)
local Rules = freshRequire(RS.OK.Modules.CareerRules)
local out = {}
local function fakeStore(data)
  local s = { calls = 0 }
  function s:UpdateAsync(k, fn) s.calls += 1; local new = fn(data[k]); if new ~= nil then data[k] = new end; return new end
  return s
end
local t, day = 1000000, 20261023
local data = {}
local DS = freshRequire(SSS.OK.Services.DataService)
DS._SetConfigForTest(Cfg); DS._retryDelays = { 0, 0, 0 }; DS._lockWaits = { 0, 0, 0 }; DS._quiet = true
DS._now = function() return t end; DS._day = function() return day end
DS._SetStoreForTest(fakeStore(data))
-- a stand-in Life for the edit-mode ctx (Career and Gear find it as ctx.Life), logging the events it is told
local lifeEvents = {}
local Life = { Publish = function() end, Roster = function(_, default) return default end }
function Life.Event(_, kind) table.insert(lifeEvents, kind) end
local Gear = freshRequire(RS.OK.Systems.Gear)
Gear._SetConfigForTest(Cfg); Gear._SetCtxForTest({ Data = DS, Life = Life })
local Career = freshRequire(RS.OK.Systems.Career)
Career._SetConfigForTest(Cfg); Career._SetCtxForTest({ Data = DS, Gear = Gear, Life = Life }); Career._quiet = true
local P = freshRequire(RS.OK.Systems.Profiles)
P._SetConfigForTest(Cfg, freshRequire(RS.OK.Modules.LifeRules))
local function keys(tbl) local n = 0; for _ in pairs(tbl) do n += 1 end; return n end

-- config sanity: every career source names a real stat; the three fits sit just before plate_legend
for src, stats in pairs(Cfg.Career.Sources) do
  for stat in pairs(stats) do assert(table.find(Rules.STATS, stat), "career source " .. src .. " pays an unknown stat " .. tostring(stat)) end
end
assert(Cfg.Cred.Sources.WalkIn and Cfg.Cred.Sources.WalkIn.max == 2000 and Cfg.Cred.Sources.WalkIn.dailyMax == 16, "Money source WalkIn missing")
assert(Cfg.WalkIns and Cfg.WalkIns.Roster == "parody" and Cfg.WalkIns.DailyMax == 8, "Config.WalkIns missing")
local n = #Cfg.Gear
assert(Cfg.Gear[n].id == "plate_legend", "plate_legend must stay last, last is " .. tostring(Cfg.Gear[n].id))
assert(Cfg.Gear[n - 3].id == "fit_cuban" and Cfg.Gear[n - 2].id == "fit_snapback" and Cfg.Gear[n - 1].id == "fit_shades", "the three fits must sit just before plate_legend")
for i = n - 3, n - 1 do local it = Cfg.Gear[i]; assert(it.kind == "fit" and it.slot and it.fit and it.needs and it.price > 0, "fit shape: " .. it.id) end
table.insert(out, "config: career sources pay known stats; WalkIn Money source; cuban/snapback/shades before plate_legend (last)")

-- a) a stored v3 profile loads at v5: career and walkins defaults, Money not multiplied again
data.u_4101 = { v = 3, cred = 700, xp = 0 }
local pa = { UserId = 4101, Name = "T41a" }
local a = DS.Load(pa)
assert(DS.SchemaVersion == 5 and a.v == DS.SchemaVersion, "schema should be v5, profile at v" .. tostring(a.v))
local c = a.career
assert(type(c) == "table" and c.aura == 0 and c.followers == 0 and c.placements == 0 and c.hits == 0 and c.sponsors == 0, "career stats not zero")
assert(c.sponsor == nil and c.showSponsor == true and type(c.gates) == "table" and next(c.gates) == nil and type(c.careerLog) == "table", "career defaults wrong")
local w = a.walkins
assert(type(w) == "table" and w.day == 0 and w.today == 0 and w.count == 0, "walkins counters wrong")
assert(type(w.queue) == "table" and #w.queue == 0 and type(w.seen) == "table" and type(w.last) == "table", "walkins tables missing")
-- v5 adds one top-level table and leaves these two exactly as v4 made them: 8 career keys (sponsor is nil), 6 walkins keys
assert(keys(c) == 8 and keys(w) == 6 and c.life == nil and w.life == nil, "the career or walkins shape changed: " .. keys(c) .. " career keys, " .. keys(w) .. " walkins keys")
assert(type(a.life) == "table", "a migrated profile has no prof.life")
assert(a.cred == 700, "a v3 balance must not be multiplied again: " .. tostring(a.cred))
assert(DS.Save(pa) and data.u_4101.v == 5 and type(data.u_4101.career) == "table" and type(data.u_4101.walkins) == "table" and type(data.u_4101.life) == "table", "migrated profile not stored at v5")
table.insert(out, "(a) v3 profile ($700) loads at v" .. DS.SchemaVersion .. " with career and walkins defaults, still $700")

-- b) walkins survive load, save and reload unchanged; a missing or broken career/walkins is replaced whole
data.u_4102 = { v = 4, walkins = { day = 20261023, today = 3, count = 9, queue = { { id = "navx_single", at = 11 } } } }
local pb = { UserId = 4102, Name = "T41b" }
local function sameWalkins(x)
  return type(x) == "table" and keys(x) == 4 and x.day == 20261023 and x.today == 3 and x.count == 9
    and type(x.queue) == "table" and #x.queue == 1 and keys(x.queue[1]) == 2 and x.queue[1].id == "navx_single" and x.queue[1].at == 11
end
local b1 = DS.Load(pb)
assert(sameWalkins(b1.walkins), "walkins changed on load")
assert(type(b1.career) == "table" and b1.career.aura == 0 and b1.career.showSponsor == true, "a v4 profile without career was not repaired")
assert(DS.Save(pb) and sameWalkins(data.u_4102.walkins), "walkins changed on save")
DS._Forget(pb)
local b2 = DS.Load(pb)
assert(sameWalkins(b2.walkins) and b2.v == 5, "walkins changed on reload")
data.u_4103 = { v = 4, career = "junk", walkins = 7 }
local b3 = DS.Load({ UserId = 4103, Name = "T41b3" })
assert(type(b3.career) == "table" and b3.career.showSponsor == true and type(b3.career.gates) == "table", "a broken career was not replaced")
assert(type(b3.walkins) == "table" and b3.walkins.count == 0 and type(b3.walkins.queue) == "table", "broken walkins were not replaced")
table.insert(out, "(b) walkins {day, today 3, count 9, queue navx_single@11} round-trip unchanged; broken career/walkins replaced")

-- c) TakeCred: takes what you have, never below $0; bad amounts take nothing; floors
data.u_4104 = { v = 4, cred = 120 }
local pc = { UserId = 4104, Name = "T41c" }
local cp = DS.Load(pc)
assert(DS.TakeCred(pc, 300) == 120 and cp.cred == 0, "TakeCred(300) on $120 should take 120 and leave $0, left " .. tostring(cp.cred))
assert(DS.TakeCred(pc, -5) == 0 and DS.TakeCred(pc, 0 / 0) == 0 and DS.TakeCred(pc, 10) == 0 and cp.cred == 0, "TakeCred took a bad amount or went below $0")
DS.GrantCred(pc, 50, "Test")
assert(DS.TakeCred(pc, 20.9) == 20 and cp.cred == 30, "TakeCred should floor the amount")
table.insert(out, "(c) TakeCred: $300 from $120 takes 120 (balance $0); -5, NaN and anything at $0 take 0; 20.9 takes 20")

-- d) Career.Add through the gate; Career.Take; SetSponsor
local pd = { UserId = 4105, Name = "T41d" }
local dp = DS.Load(pd)
assert(Career.Add(pd, "followers", 999, "Delivery") == 120 and dp.career.followers == 120, "Delivery followers should cap at 120")
local paid = 120
for _ = 2, 15 do paid += Career.Add(pd, "followers", 120, "Delivery") end
assert(paid == 15 * 120, "15 Delivery followers awards should pay, paid " .. paid)
assert(Career.Add(pd, "followers", 120, "Delivery") == 0 and dp.career.followers == 1800, "the 16th Delivery followers award that day paid")
assert(Career.Add(pd, "aura", 5, "Delivery") == 5 and dp.career.aura == 5, "Delivery aura has its own count")
assert(Career.Add(pd, "aura", 5, "Nope") == 0 and Career.Add(pd, "money", 5, "WalkIn") == 0 and Career.Add(pd, "aura", 5, nil) == 0 and dp.career.aura == 5, "an unknown source or stat paid")
assert(Career.Add(pd, "followers", 1, "Fire") == Cfg.Career.Sources.Fire.followers.amount, "a fixed-amount source should pay its amount")
local log = dp.career.careerLog
assert(log.count["Delivery.followers"] == 15 and log.count["Delivery.aura"] == 1 and dp.careerLog == nil, "career log not in prof.career.careerLog")
assert(type(dp.credLog) ~= "table" or (dp.credLog.count or {})["Delivery.followers"] == nil, "career awards leaked into the Money log")
day += 1
assert(Career.Add(pd, "followers", 120, "Delivery") == 120, "the daily cap did not reset on a new day")
dp.career.aura = 100
assert(Career.Take(pd, "aura", 400) == 400 and dp.career.aura == -300, "Take aura 400 from 100 should leave -300, got " .. tostring(dp.career.aura))
dp.career.followers = 10
assert(Career.Take(pd, "followers", 50) == 10 and dp.career.followers == 0, "Take followers 50 from 10 should take 10 and stop at 0")
assert(Career.Take(pd, "followers", -5) == 0 and Career.Take(pd, "nope", 5) == 0 and Career.Take(pd, "aura", 0 / 0) == 0 and dp.career.aura == -300, "Take accepted a bad amount or stat")
Career.SetSponsor(pd, "t41_brand")
assert(dp.career.sponsor == "t41_brand" and dp.career.sponsors == 0, "SetSponsor must set the deal and leave the count alone")
local got = Career.Get(pd)
assert(got.sponsor == "t41_brand" and got.aura == -300 and got.money == (dp.cred or 0) and got.showSponsor == true, "Get wrong")
Career.SetSponsor(pd, nil)
assert(dp.career.sponsor == nil, "SetSponsor(nil) did not clear the deal")
table.insert(out, "(d) Add: Delivery followers capped at 120, 16th award 0, own log; unknown source/stat 0; Take: aura 100-400 = -300, followers 10-50 = 0 (took 10); SetSponsor keeps the count")

-- e) Unlock studio_two (room) and sponsor_tv (toggle)
local pe = { UserId = 4106, Name = "T41e" }
local ep = DS.Load(pe)
ep.career.aura = 300; ep.cred = 5000
local clock0, held = Career._clock, os.clock()
Career._clock = function() return held end -- Fetch's 0.25 s window, held still
local cached = Career.Fetch(pe)
local r1 = Career.Unlock(pe, "studio_two")
assert(not r1.ok and r1.reason == "needs" and ep.cred == 5000, "studio_two at 0 placements should be 'needs', got " .. tostring(r1.reason))
-- a refusal changed nothing: no Publish (it would drop Fetch's state) and the answer is the state Fetch last built
local refetched = Career.Fetch(pe)
Career._clock = clock0
assert(r1.state == cached and refetched == cached, "a refused unlock should answer with Fetch's last built state and publish nothing (its state "
  .. (r1.state == cached and "is" or "is not") .. " Fetch's, and Fetch " .. (refetched == cached and "kept" or "lost") .. " it)")
ep.career.placements = 1; ep.cred = 4999
local r2 = Career.Unlock(pe, "studio_two")
assert(not r2.ok and r2.reason == "money" and ep.cred == 4999, "studio_two at $4,999 should be 'money', got " .. tostring(r2.reason))
ep.cred = 5000
local r3 = Career.Unlock(pe, "studio_two")
assert(r3.ok and ep.cred == 0 and ep.career.gates.studio_two == true, "studio_two at $5,000 did not unlock or did not spend")
local row
for _, g in ipairs(r3.state.gates) do if g.id == "studio_two" then row = g end end
assert(row and row.owned == true and row.on == true and row.kind == "room" and row.cost == 5000 and row.check and #row.check.rows == 2, "state row for studio_two wrong")
local r4 = Career.Unlock(pe, "studio_two")
assert(not r4.ok and r4.reason == "owned" and ep.cred == 0, "a second unlock should be 'owned' and spend nothing")
assert(Career.Unlock(pe, "nope").reason == "invalid" and Career.Unlock(pe, 5).reason == "invalid", "an unknown gate was not 'invalid'")
local r5 = Career.Unlock(pe, "sponsor_tv")
assert(not r5.ok and r5.reason == "needs", "sponsor_tv without a sponsor should be 'needs'")
ep.career.sponsors = 1; ep.cred = 100
local r6 = Career.Unlock(pe, "sponsor_tv")
assert(r6.ok and ep.career.showSponsor == false and ep.cred == 100, "sponsor_tv toggle did not switch off, or it spent")
local r7 = Career.Unlock(pe, "sponsor_tv")
assert(r7.ok and ep.career.showSponsor == true and ep.cred == 100, "sponsor_tv toggle did not switch back on")
assert(table.concat(lifeEvents, ",") == "hall", "one bought room should report one hall, the refused, owned and toggle calls none, got " .. table.concat(lifeEvents, ","))
-- a room that isn't THE HALL opens with no hall event
table.insert(Cfg.Career.Gates, { id = "t41_room", kind = "room", name = "T41 ROOM", desc = "", needs = {}, cost = 0 })
assert(Career.Unlock(pe, "t41_room").ok == true, "the test room did not unlock")
table.remove(Cfg.Career.Gates)
assert(table.concat(lifeEvents, ",") == "hall", "another room reported hall: " .. table.concat(lifeEvents, ","))
local st = Career.State(pe)
assert(#st.gates == 4 and st.stats.money == 100 and st.stats.placements == 1 and st.stats.gates.studio_two == true, "Career.State stats/gates wrong")
assert(type(st.life) == "table" and st.life.day == 1 and st.stats.life == nil, "Career.State should carry life beside the stats")
local ids = {}
for _, g in ipairs(st.gear) do
  table.insert(ids, g.id)
  assert(g.needs and g.check and g.check.money and type(g.owned) == "boolean" and type(g.levelOk) == "boolean" and g.price and g.level and g.name and g.kind, "gear row shape: " .. g.id)
end
assert(table.concat(ids, ",") == "kit_iron,spk_monitors,spk_studio,fit_cuban,fit_snapback,fit_shades,plate_legend", "Career.State gear rows: " .. table.concat(ids, ","))
-- rows by id (preflight F1: the room speakers, Task 7, sit between kit_iron and fit_cuban)
local gearRow = {}
for _, g in ipairs(st.gear) do gearRow[g.id] = g end
assert(gearRow.kit_iron.levelOk == false and gearRow.fit_cuban.levelOk == true and gearRow.fit_cuban.check.ok == false, "gear row levelOk/check wrong (kit_iron is level 6; fit_cuban needs 2 placements)")
-- the speaker rows equal spec/room_rules_spec.lua's literal (SPEAKER_GEAR), and carry no feature (so the pacing sim's
-- gear, spec/economy_fixture.lua, can't hold them)
local SPEAKER_GEAR = {
  spk_monitors = { tier = 2, price = 500, level = 2, needs = { followers = 200 } },
  spk_studio = { tier = 3, price = 3000, level = 5, needs = { placements = 2, followers = 5000 } },
}
for id, want in pairs(SPEAKER_GEAR) do
  local it
  for _, g in ipairs(Cfg.Gear) do if g.id == id then it = g end end
  assert(it and it.kind == "speakers" and it.feature == nil and it.tier == want.tier and it.price == want.price and it.level == want.level,
    "Config.Gear " .. id .. ": kind " .. tostring(it and it.kind) .. ", feature " .. tostring(it and it.feature) .. ", tier " .. tostring(it and it.tier)
    .. ", price " .. tostring(it and it.price) .. ", level " .. tostring(it and it.level) .. "; want speakers, no feature, the spec's literal")
  local nk = 0
  for stat, need in pairs(it.needs or {}) do nk += 1; assert(want.needs[stat] == need, "Config.Gear " .. id .. " needs " .. stat .. " = " .. tostring(need) .. ", the spec's literal says " .. tostring(want.needs[stat])) end
  for _ in pairs(want.needs) do nk -= 1 end
  assert(nk == 0, "Config.Gear " .. id .. "'s needs and the spec's literal name different stats")
  assert(Cfg.Rooms.Speakers[want.tier].gear == id, "Config.Rooms.Speakers[" .. want.tier .. "].gear is " .. tostring(Cfg.Rooms.Speakers[want.tier].gear) .. ", want " .. id)
end
-- a failing Life leaves the tab whole, with no life; the same for a view that can't be built
local realRoster = Life.Roster
Life.Roster = function() error("t41: Life is down") end
local broke = Career.State(pe)
assert(broke.life == nil and #broke.gates == 4 and #broke.gear == 7 and broke.stats.money == 100, "a failing Life should give a nil life and a whole State")
Life.Roster = realRoster
local realCfgLife = Cfg.Life
Cfg.Life = nil
local noView = Career.State(pe)
Cfg.Life = realCfgLife
assert(noView.life == nil and #noView.gates == 4, "a view that fails should give a nil life and a whole State")
assert(type(Career.State(pe).life) == "table", "the life should come back when Life does")
table.insert(out, "(e) a failing Life or view: Career.State has no life, the tab whole")
table.insert(out, "(e) studio_two: needs (0 placements; answered with Fetch's state, nothing published), money ($4,999), ok at $5,000 leaving $0, then owned; sponsor_tv needs a sponsor, toggles, never spends; State: 4 gates (home studio, real studio, THE HALL, sponsor_tv), 7 gear rows (the speaker rows pinned to the spec)")

-- e2) R-T16 fix, I7: the ladder's order, real_studio only after home_studio
local realG, homeG
for _, g in ipairs(Cfg.Career.Gates) do
  if g.id == "real_studio" then realG = g elseif g.id == "home_studio" then homeG = g end
end
assert(realG and homeG and realG.after == "home_studio", "Config.Career.Gates real_studio.after is " .. tostring(realG and realG.after)
  .. ", want home_studio (before the R-T16 fix sync of OK/Config and Systems/Career: the expected red)")
local pr = { UserId = 4108, Name = "T41r" }
local rp = DS.Load(pr)
for stat, need in pairs(realG.needs) do rp.career[stat] = need end
rp.cred = realG.cost
local rr1 = Career.Unlock(pr, "real_studio")
assert(not rr1.ok and rr1.reason == "needs" and rp.cred == realG.cost and not rp.career.gates.real_studio,
  "real_studio with its needs met and $" .. realG.cost .. " but no home_studio: ok " .. tostring(rr1.ok) .. ", reason " .. tostring(rr1.reason)
  .. ", money left $" .. tostring(rp.cred) .. "; want 'needs' and nothing spent")
local realRow
for _, g in ipairs(Career.State(pr).gates) do if g.id == "real_studio" then realRow = g end end
local ca = realRow and realRow.check and realRow.check.after
assert(realRow and realRow.after == "home_studio" and realRow.check.ok == false and type(ca) == "table" and ca.id == "home_studio" and ca.ok == false
  and ca.name == homeG.name, "Career.State's real_studio row before home_studio: after " .. tostring(realRow and realRow.after) .. ", check.ok "
  .. tostring(realRow and realRow.check.ok) .. ", check.after " .. tostring(ca and (tostring(ca.id) .. "/" .. tostring(ca.name) .. "/" .. tostring(ca.ok)))
  .. "; want home_studio, false, home_studio/" .. homeG.name .. "/false")
rp.career.gates.home_studio = true -- Career.Unlock is the real writer; its effect
local rr2 = Career.Unlock(pr, "real_studio")
assert(rr2.ok and rp.cred == 0 and rp.career.gates.real_studio == true, "real_studio with home_studio owned did not unlock (" .. tostring(rr2.reason) .. ") or did not spend")
local realRow2
for _, g in ipairs(rr2.state.gates) do if g.id == "real_studio" then realRow2 = g end end
assert(realRow2 and realRow2.owned == true and realRow2.check.after and realRow2.check.after.ok == true, "the real_studio row after the buy is not owned, or its after row isn't met")
table.insert(out, "(e2) real_studio after home_studio: 'needs' with its needs and $" .. realG.cost .. " but no home studio (nothing spent; State: after home_studio, check.after '"
  .. homeG.name .. "' not ok, check.ok false); with home_studio owned it unlocks")

-- f) Gear: needs refuse after the level check; fits equip by slot
local pf = { UserId = 4107, Name = "T41f" }
local fp = DS.Load(pf)
fp.level = 10; fp.cred = 4000
lifeEvents = {}
local g1 = Gear.Buy(pf, "plate_legend")
assert(not g1.ok and g1.reason == "needs" and fp.cred == 4000 and not (fp.gear or {}).plate_legend, "plate_legend without a hit should be 'needs', got " .. tostring(g1.reason))
fp.level = 1
assert(Gear.Buy(pf, "plate_legend").reason == "level", "the level check must come before needs")
fp.level = 10
fp.career.hits = 1; fp.career.followers = 20000; fp.career.aura = 1000
local g2 = Gear.Buy(pf, "plate_legend")
assert(g2.ok and fp.cred == 0 and fp.gear.plate_legend == true, "plate_legend with its needs met did not sell")
assert(table.concat(lifeEvents, ",") == "legend", "only the sale should report legend, through ctx.Life, got " .. table.concat(lifeEvents, ","))
fp.cred = 900
assert(Gear.Buy(pf, "neon_ice").ok == true and #lifeEvents == 1, "any other item should report nothing")
fp.gear.plate_legend = nil; fp.cred = 4000
local realEvent = Life.Event
Life.Event = function() error("t41: Life is down") end
local g3 = Gear.Buy(pf, "plate_legend")
Life.Event = realEvent
assert(g3.ok and fp.gear.plate_legend == true, "a failing Life must not fail the sale")
fp.gear.fit_cuban = true
local e1 = Gear.Equip(pf, "fit_cuban")
local function item(state, id) for _, it in ipairs(state.items) do if it.id == id then return it end end; return nil end
local cub = e1.ok and item(e1.state, "fit_cuban")
assert(cub and cub.equipped == true and fp.equip.neck == "fit_cuban" and cub.needs and cub.meets == false, "fit_cuban did not equip on the neck slot")
assert(item(e1.state, "808").meets == true and item(e1.state, "808").needs == nil, "an item without needs should always meet them")
local e2 = Gear.Equip(pf, "fit_cuban")
assert(e2.ok and fp.equip.neck == nil and item(e2.state, "fit_cuban").equipped == false, "a second Equip did not take the fit off")
assert(Gear.Equip(pf, "fit_shades").reason == "notowned" and Gear.Equip(pf, "rollfx").reason == "invalid", "Equip accepted an unowned fit or a tool")
table.insert(out, "(f) Gear: plate_legend at level 10 with $4,000 and no hit -> needs (level first), sells once met; fit_cuban equips on neck and toggles off")

-- g) producer cards: the five stats, never Money
local card = P.CardFrom({ level = 2, cred = 900, career = { aura = -40, followers = 1200, placements = 2, hits = 1, sponsors = 1, sponsor = "x" } }, "Maya", 7, 0)
assert(card.aura == -40 and card.followers == 1200 and card.placements == 2 and card.hits == 1 and card.sponsors == 1, "card stats wrong")
assert(card.cred == nil and card.money == nil and card.sponsor == nil, "card leaks Money or the sponsor id")
assert(card.year == 1 and card.tier == "LOCAL" and type(card.title) == "string" and type(card.ribbons) == "table", "card life fields missing")
local allowed = {}
for _, k in ipairs(P.PUBLIC) do allowed[k] = true end
for k in pairs(card) do assert(allowed[k], "card leaks field " .. tostring(k)) end
for _, stat in ipairs(Rules.STATS) do assert(allowed[stat], "PUBLIC lacks " .. stat) end
local bare = P.CardFrom({ level = 1 }, "Ola", 8, 0)
assert(bare.aura == 0 and bare.followers == 0 and bare.placements == 0 and bare.hits == 0 and bare.sponsors == 0, "a profile without career should show zeros")
table.insert(out, "(g) cards carry aura/followers/placements/hits/sponsors (zeros without career), no Money")

DS._SetStoreForTest(nil)
return "T41 OK: " .. table.concat(out, "; ")
