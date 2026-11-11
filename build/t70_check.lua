-- Edit: Wave 2's save and Systems/Life (t41's seam: a fresh DataService, a fake clock and fake players; no Init runs),
-- on a fake store that keeps JSON, as a real DataStore does, so a value it would reject or reshape fails here.
-- (a) schema 5; a v4 profile loads as v5, its life equal to LifeRules.Backfill plus its ribbons dated day 1; the step
-- runs after the career repair and the level; a stored v5 life is left alone and a junk one replaced. (b) a v5 profile
-- with 3 story entries, 2 discography entries, firsts and ribbons survives JSON key for key, and through a real save and
-- reload. (c) the clock through _day: Life is a no-op before its ctx; a second join the same day counts nothing, the next
-- day +1 with one LifeDayToast logged, a three-day gap +1, an earlier day nothing; ClientMain reads the attribute at UI
-- build (pinned from its source). (d) tiers: a Publish-only crossing records every tier silently, a
-- loud one banners and plants its visit once each (one move across two tiers at {1, 2} then {2, 3}, through a stand-in
-- ctx.WalkIns; a plant that fails stops nothing, a plant refused for being queued is quiet, any other refusal is
-- reported), walk-ins off means no plant, no report and a headline-only banner, an unknown tier id repairs to the current
-- tier silently, a fall and re-rise repeats nothing, ribbons follow the career, and Life.Event refuses a "tier" (tiers move
-- only through Publish). The cypher win's report has no cheap real path (the other sites are t72's), so its one line is
-- pinned from the source: a typo inside its pcall would otherwise pass. (e) Career.State's life
-- names only ids the content knows, in the current roster; Fetch keeps the last built state for 0.25 s, unless the career
-- moved. (f) ClientProfile leaves the life out; LeveledUp fires on a level rise only. (g) a v6 profile is never overwritten,
-- and its clock never steps.
local RS, SSS = game:GetService("ReplicatedStorage"), game:GetService("ServerScriptService")
local Http = game:GetService("HttpService")
local function freshRequire(mod) local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name; local ok, r = pcall(require, c); c:Destroy(); if not ok then error(r) end; return r end
local Cfg = freshRequire(RS.OK.Config)
local Rules = freshRequire(RS.OK.Modules.LifeRules)
local out = {}

-- UpdateAsync semantics, with the value held as JSON: what comes back is what a store would give
local function jsonStore(data)
  local s = { calls = 0 }
  function s:UpdateAsync(k, fn)
    s.calls += 1
    local old = data[k] ~= nil and Http:JSONDecode(data[k]) or nil
    local new = fn(old)
    if new ~= nil then data[k] = Http:JSONEncode(new) end
    return new
  end
  return s
end
local function stored(data, k) return Http:JSONDecode(data[k]) end
-- key for key, both ways; returns true, or false and the first path that differs
local function same(a, b, path)
  path = path or "life"
  if type(a) ~= type(b) then return false, path end
  if type(a) ~= "table" then return a == b, path end
  for k, v in pairs(a) do
    local ok, at = same(v, b[k], path .. "." .. tostring(k))
    if not ok then return false, at end
  end
  for k in pairs(b) do
    if a[k] == nil then return false, path .. "." .. tostring(k) end
  end
  return true, path
end
local function assertSame(a, b, what)
  local ok, at = same(a, b)
  assert(ok, what .. " differs at " .. tostring(at))
end
local function deepCopy(x)
  if type(x) ~= "table" then return x end
  local c = {}
  for k, v in pairs(x) do c[k] = deepCopy(v) end
  return c
end
local function dense(list)
  local n = 0
  for k in pairs(list) do
    if type(k) ~= "number" then return false end
    n += 1
  end
  return n == #list
end

local t, day = 1000000, 20261030
local data = {}
local DS = freshRequire(SSS.OK.Services.DataService)
DS._SetConfigForTest(Cfg); DS._retryDelays = { 0, 0, 0 }; DS._lockWaits = { 0, 0, 0 }; DS._quiet = true
DS._now = function() return t end; DS._day = function() return day end
DS._SetStoreForTest(jsonStore(data))
local Gear = freshRequire(RS.OK.Systems.Gear)
Gear._SetConfigForTest(Cfg); Gear._SetCtxForTest({ Data = DS })
local Life = freshRequire(RS.OK.Systems.Life)
Life._SetConfigForTest(Cfg, Rules); Life._quiet = true
local TIERS = Cfg.Life.Tiers
local function seed(uid, prof) data["u_" .. uid] = Http:JSONEncode(prof) end
local function sentKinds(uid)
  local kinds = {}
  for _, e in ipairs(Life._Sent(uid)) do table.insert(kinds, e.kind) end
  return table.concat(kinds, ",")
end

-- a) v4 -> v5
assert(DS.SchemaVersion == 5, "SchemaVersion should be 5, is " .. tostring(DS.SchemaVersion))
seed(7001, { v = 4, xp = 1100, level = 1, cred = 900,
  career = { aura = 400, followers = 25000, placements = 3, hits = 1, sponsors = 1, gates = { studio_two = true }, careerLog = {} },
  walkins = { day = 0, today = 0, count = 0, queue = {}, seen = {}, last = {} },
  credits = { { t = "Gravel", a = "TAVI GLASS", s = 3, d = 20261021 } },
  cypher = { entered = 3, wins = 1 }, daw = { v = 2, slots = { s1 = { pattern = "x" } }, saves = 4 }, daily = { day = 20261029, streak = 7, done = {} } })
local pa = { UserId = 7001, Name = "T70a" }
local a = DS.Load(pa)
assert(a.v == 5 and a.level == 6, "v4 should load at v5 and level 6 (xp 1100): v " .. tostring(a.v) .. ", level " .. tostring(a.level))
local want = Rules.Backfill(a, day, TIERS)
for _, id in ipairs(Rules.RibbonsFor(want, a.career, Cfg.Life.Ribbons, TIERS)) do want.ribbons[id] = want.day end
assertSame(a.life, want, "the migrated life vs Backfill + ribbons")
assert(a.life.day == 1 and a.life.last == day and a.life.tier == "FAMOUS", "the backfill day, last or tier is wrong")
assert(a.life.firsts.level5 == 0, "the backfill ran before the level was recomputed (a stale level 1 was stored)")
assert(a.life.ribbons.hit == 1 and a.life.ribbons.sponsor == 1 and a.life.ribbons.streak7 == 1, "an old profile's ribbons should be dated day 1")
assert(a.life.ribbons.icon == nil and a.life.ribbons.placements10 == nil, "the backfill awarded a ribbon it hasn't earned")
seed(7002, { v = 4, career = "junk" })
local aj = DS.Load({ UserId = 7002, Name = "T70a2" })
assert(type(aj.career) == "table" and aj.life.tier == "LOCAL" and next(aj.life.firsts) == nil and aj.life.last == day, "v4 with a junk career: bad life")
seed(7003, { v = 3 })
local av3 = DS.Load({ UserId = 7003, Name = "T70a3" })
assert(av3.v == 5 and type(av3.life) == "table" and av3.life.day == 1, "a v3 profile should reach v5 with a life")
seed(7004, { v = 5, life = { day = 9, last = 20261020, story = {}, disco = {}, firsts = { hit = 3 }, tier = "KNOWN", ribbons = {} },
  career = { followers = 0, gates = {} } })
local av5 = DS.Load({ UserId = 7004, Name = "T70a4" })
assert(av5.life.day == 9 and av5.life.last == 20261020 and av5.life.tier == "KNOWN" and av5.life.firsts.hit == 3, "a stored v5 life was touched on load")
seed(7005, { v = 5, life = "junk", career = { followers = 1200, gates = {} } })
local alj = DS.Load({ UserId = 7005, Name = "T70a5" })
assert(type(alj.life) == "table" and alj.life.tier == "BUZZING" and alj.life.day == 1, "a junk life was not replaced")
table.insert(out, "(a) v5; v4 -> Backfill + day-1 ribbons, after the career repair and level; a stored life untouched, a junk one replaced")

-- b) v5 through JSON, key for key
local plants = {} -- what the stand-in WalkIns was asked to plant: "<id>@<lo>-<hi>"
local plantError
local plantRefuse -- nil: a planted entry; "queued", "other": PlantSystem refuses, for being queued or anything else
local plantWalkIns = { PlantSystem = function(_, id, at)
  table.insert(plants, id .. "@" .. at[1] .. "-" .. at[2])
  if plantError then error(plantError) end
  if plantRefuse == "queued" then return nil, "queued" end
  if plantRefuse then return nil end
  return { id = id }
end }
Life._SetCtxForTest({ Data = DS, WalkIns = plantWalkIns })
local pb = { UserId = 7010, Name = "T70b" }
local b = DS.Load(pb)
Life.Event(pb, "placement", { v = "navx", key = "c1" })
Life.Event(pb, "hit", { v = "drift", key = "f1" })
Life.Event(pb, "sponsor", { s = "watches" })
assert(#b.life.story == 3 and #b.life.disco == 2, "stage: 3 story and 2 discography entries, got " .. #b.life.story .. " and " .. #b.life.disco)
assert(b.life.firsts.placement == 1 and b.life.firsts.hit == 1 and b.life.firsts.sponsor == 1, "stage: firsts not ticked at day 1")
assert(b.life.ribbons.hit == 1 and b.life.ribbons.sponsor == 1, "stage: the hit and sponsor ribbons were not awarded")
local ribbonToasts = {}
for _, e in ipairs(Life._Sent(7010)) do
  assert(e.kind == "Toast", "stage: a life event sent " .. tostring(e.kind))
  table.insert(ribbonToasts, e.payload.text)
end
assert(table.concat(ribbonToasts, "|") == "RIBBON: CHARTED|RIBBON: BRAND DEAL", "each ribbon should toast as it lands, toasts: " .. table.concat(ribbonToasts, "|"))
Life.Event(pb, "hit", { v = "drift", key = "f2" })
assert(#b.life.story == 4 and #Life._Sent(7010) == 0, "a ribbon already held toasted again")
table.remove(b.life.story); table.remove(b.life.disco)
assert(dense(b.life.story) and dense(b.life.disco), "the story and discography must stay dense arrays")
for k in pairs(b.life) do assert(type(k) == "string", "a life key is not a string") end
assert(b.life.story[1][1] == nil and b.life.story[1].k == "placement", "story entries are named-field records")
local jsonLife = Http:JSONEncode(b.life)
assertSame(Http:JSONDecode(jsonLife), b.life, "a v5 life through JSONEncode/JSONDecode")
local before = deepCopy(b.life)
assert(DS.Save(pb), "the v5 profile did not save")
assertSame(stored(data, "u_7010").life, before, "the stored life")
DS._Forget(pb)
local b2 = DS.Load(pb)
assertSame(b2.life, before, "the life after save and reload")
assert(b2.v == 5, "a reloaded profile should stay v5")
assert(#jsonLife < 2000, "3 story and 2 discography entries should stay small, are " .. #jsonLife .. " bytes")
table.insert(out, "(b) 3 story, 2 disco, firsts, ribbons: JSON and a stored save + reload equal the original key for key (" .. #jsonLife .. " bytes)")

-- c) the clock: nothing before a ctx; through _day after
local Cold = freshRequire(RS.OK.Systems.Life)
Cold._SetConfigForTest(Cfg, Rules); Cold._quiet = true
local pc = { UserId = 7020, Name = "T70c" }
local c = DS.Load(pc)
local snapshot = deepCopy(c.life)
assert(Cold.Tick(pc) == false and Cold.Event(pc, "hit", { v = "navx" }) == nil and Cold.Publish(pc) == nil and Cold.State(pc) == nil, "Life before Init should do nothing")
day += 1
assert(Cold.Tick(pc) == false, "Life before Init should not step the clock")
day -= 1
assertSame(c.life, snapshot, "the life after calls before Init")
assert(Cold.Roster(pc, "fiction") == "fiction", "Roster before Init should give the default")
assert(Life.Tick(pc) == false and c.life.day == 1, "the same UTC day (a second join) should count nothing")
assert(sentKinds(7020) == "", "no day, no LifeDayToast")
day = 20261031
assert(Life.Tick(pc) == true and c.life.day == 2 and c.life.last == 20261031, "the next UTC day should be +1 (midnight, online)")
local dayLog = Life._Sent(7020)
assert(#dayLog == 1 and dayLog[1].kind == "LifeDayToast" and dayLog[1].payload.day == 2, "a new day should log LifeDayToast { day = 2 }")
assert(Life.Tick(pc) == false and c.life.day == 2, "the same day again should count nothing")
day = 20261103
assert(Life.Tick(pc) == true and c.life.day == 3 and c.life.last == 20261103, "a three-day gap should count once")
day = 20261102
assert(Life.Tick(pc) == false and c.life.day == 3 and c.life.last == 20261103, "an earlier day (another server's clock) should count nothing")
day = 20261030
Life._Sent(7020)
assert(game:GetService("StarterPlayer").StarterPlayerScripts.OK.ClientMain.Source:find("\nreadDay()\n", 1, true), "ClientMain no longer reads LifeDayToast at UI build")
table.insert(out, "(c) before Init: no-ops; same day 0, next day +1 with LifeDayToast, three-day gap +1, an earlier day 0; ClientMain reads at UI build")

-- d) tiers: the high-water mark
local pd = { UserId = 7030, Name = "T70d" }
local d = DS.Load(pd)
local function tierLines()
  local ids = {}
  for _, e in ipairs(d.life.story) do if e.k == "tier" then table.insert(ids, e.key) end end
  return table.concat(ids, ",")
end
d.career.followers = 900
Life.Publish(pd)
assert(d.life.tier == "LOCAL" and tierLines() == "", "900 Followers is still LOCAL")
d.career.followers = 6000
Life.Publish(pd)
assert(d.life.tier == "KNOWN" and tierLines() == "BUZZING,KNOWN", "a Publish-only move to 6,000 should record both tiers in order, has " .. tierLines())
assert(d.life.firsts.buzzing == 1 and d.life.firsts.known == 1, "a silent crossing still ticks its firsts")
assert(sentKinds(7030) == "", "a Publish-only crossing must be silent (A3)")
assert(#plants == 0, "a Publish-only crossing must plant nothing (A3), planted " .. table.concat(plants, ","))
d.career.followers = 25000
Life.Publish(pd, true)
assert(d.life.tier == "FAMOUS" and tierLines() == "BUZZING,KNOWN,FAMOUS", "a loud crossing should record FAMOUS")
local loud = Life._Sent(7030)
assert(#loud == 1 and loud[1].kind == "LifeBanner" and loud[1].payload.tier == "FAMOUS" and loud[1].payload.text == Rules.Copy.Banners.FAMOUS, "a loud crossing should send one FAMOUS banner")
d.career.followers = 900
Life.Publish(pd, true)
d.career.followers = 25000
Life.Publish(pd, true)
assert(d.life.tier == "FAMOUS" and tierLines() == "BUZZING,KNOWN,FAMOUS" and sentKinds(7030) == "", "a fall and re-rise repeated a tier")
assert(table.concat(plants, ",") == "tier_famous@1-2", "a loud crossing plants its visit once, a re-rise nothing, planted " .. table.concat(plants, ","))
d.career.followers = 120000
d.career.placements = 10
Life.Publish(pd)
assert(d.life.ribbons.icon == 1 and d.life.ribbons.placements10 == 1, "Publish should award the ICON and 10 placements ribbons")
local p2 = { UserId = 7031, Name = "T70d2" }
local d2 = DS.Load(p2)
d2.career.followers = 6000
Life.Publish(p2, true)
local two = Life._Sent(7031)
assert(#two == 2 and two[1].payload.tier == "BUZZING" and two[2].payload.tier == "KNOWN", "one loud move across two tiers should banner both, in order (A4)")
assert(table.concat(plants, ",") == "tier_famous@1-2,tier_buzzing@1-2,tier_known@2-3", "one loud move should plant both visits, one after the other (A4), planted " .. table.concat(plants, ","))
-- a plant that fails stops nothing: the next tier is still handled, and the banners still go
local p3 = { UserId = 7032, Name = "T70d3" }
local d3 = DS.Load(p3)
d3.career.followers = 6000
plantError = "t70: the plant failed"
Life.Publish(p3, true)
plantError = nil
assert(d3.life.tier == "KNOWN" and #Life._Sent(7032) == 2 and #plants == 5, "a failed plant must not stop the crossing")
-- a refused plant: already queued is fine, anything else is reported
local function refused(uid, how)
  local pr = { UserId = uid, Name = "T70r" .. uid }
  local dr = DS.Load(pr)
  dr.career.followers = 1500
  plantRefuse, Life._lastReport = how, nil
  Life.Publish(pr, true)
  plantRefuse = nil
  assert(dr.life.tier == "BUZZING", "a refused plant must not stop the crossing")
  return Life._lastReport
end
assert(refused(7033, "queued") == nil, "a visit already queued should not report, got " .. tostring(Life._lastReport))
assert(tostring(refused(7034, "other")):find("tier_buzzing", 1, true), "a plant refused for any other reason should report")
Life._lastReport = nil
-- walk-ins switched off: the crossing stands, with no plant and no report, and the banner promises no visit
local pOff = { UserId = 7035, Name = "T70d5" }
local dOff = DS.Load(pOff)
dOff.career.followers = 1500
local plantedOff = #plants
Cfg.WalkIns.Enabled = false
Life.Publish(pOff, true)
Cfg.WalkIns.Enabled = true
local offLog = Life._Sent(7035)
assert(dOff.life.tier == "BUZZING" and #plants == plantedOff and Life._lastReport == nil, "walk-ins off: want the tier recorded, no plant, no report; report " .. tostring(Life._lastReport))
assert(#offLog == 1 and offLog[1].kind == "LifeBanner" and offLog[1].payload.text == "YOU'RE BUZZING", "walk-ins off: the banner should be its headline alone, is '" .. tostring(offLog[1] and offLog[1].payload.text) .. "'")
-- an unknown tier id can't replay the crossings: it becomes the current tier, with no line, banner or plant
local pUnk = { UserId = 7036, Name = "T70d6" }
local dUnk = DS.Load(pUnk)
dUnk.career.followers = 6000
dUnk.life.tier = "T70_GONE"
Life.Publish(pUnk, true)
assert(dUnk.life.tier == "KNOWN" and #dUnk.life.story == 0 and #plants == plantedOff and sentKinds(7036) == "", "an unknown tier should repair to KNOWN silently, is " .. tostring(dUnk.life.tier))
-- tiers move only through Publish: a "tier" event is refused, whatever its fields
local storyBefore = #d.life.story
local tierBefore = d.life.tier
assert(Life.Event(pd, "tier", { key = "BUZZING" }) == nil and #d.life.story == storyBefore and d.life.tier == tierBefore, "Life.Event should refuse a tier")
d.life.day = 4
assert(Life.Event(pd, "party", {}) == nil, "an unknown event kind should record nothing")
local lv = Life.Event(pd, "level", { n = 5 })
assert(lv and lv.story and lv.story.n == 5 and d.life.firsts.level5 == 4, "a level event should log and tick level5 at the career day")
assert(RS.OK.Systems.BeatBattles.Source:find('require(RS.OK.Systems.Life).Event(o, "cypher_win")', 1, true), "BeatBattles no longer reports cypher_win to Systems/Life")
table.insert(out, "(d) a loud crossing plants its visit once; one move at {1, 2} then {2, 3}; a failed plant stops nothing; a queued visit is quiet, another refusal reported; walk-ins off: headline, no plant, no report; an unknown tier repairs silently; Event refuses a tier; BeatBattles' cypher_win line in place")
table.insert(out, "(d) Publish-only 900 -> 6,000 records BUZZING and KNOWN silently; a loud crossing banners once; fall + re-rise repeats nothing; one loud move banners both; ribbons at the career day")

-- e) Career.State's life: names for ids the content knows, in the current roster
local W = freshRequire(RS.OK.Data.WalkIns)
local Career = freshRequire(RS.OK.Systems.Career)
Career._SetConfigForTest(Cfg); Career._SetCtxForTest({ Data = DS, Gear = Gear, Life = Life }); Career._quiet = true
local pe = { UserId = 7040, Name = "T70e" }
local e = DS.Load(pe)
Life.Event(pe, "placement", { v = "navx", key = "c1" })
Life.Event(pe, "hit", { v = "t70_nobody" })
Life.Event(pe, "sponsor", { s = "watches" })
Life.Event(pe, "sponsor", { s = "t41_brand" })
Life.Event(pe, "delivery", { v = "juno", key = "j1" })
Life.Event(pe, "delivery", { v = "t70_nobody", key = "j2" })
Life.Event(pe, "hit", { v = "rep" })
local function lifeState(roster)
  Cfg.WalkIns.Roster = roster
  return Career.State(pe).life
end
local parody = lifeState("parody")
assert(parody.day == 1 and parody.year == 1 and parody.tier == "LOCAL" and parody.title == "CHART MAKER" and #parody.story == 7 and #parody.disco == 3, "Career.State's life is wrong")
assert(parody.names.visitors.navx == W.Names("parody").navx and parody.names.sponsors.watches == W.SponsorName("watches", "parody") and parody.names.artists.juno == "JUNO VALE", "Career.State's names are wrong")
assert(parody.names.visitors.t70_nobody == nil and parody.names.sponsors.t41_brand == nil and parody.names.artists.t70_nobody == nil, "an id the content doesn't know got a name")
assert(parody.names.visitors.rep == nil, "the rep's name still holds {sponsor}: it must not be sent")
local fiction = lifeState("fiction")
assert(fiction.names.visitors.navx == W.Names("fiction").navx and fiction.names.visitors.navx ~= parody.names.visitors.navx, "the names should follow the roster")
Cfg.WalkIns.Roster = "parody"
local coldCareer = freshRequire(RS.OK.Systems.Career) -- no ctx.Life: the live module, before its Init, as in t41
coldCareer._SetConfigForTest(Cfg); coldCareer._SetCtxForTest({ Data = DS, Gear = Gear }); coldCareer._quiet = true
assert(coldCareer.State(pe).life.names.visitors.navx == parody.names.visitors.navx, "Career.State should build its life without Life running")
local clock = 100
Career._clock = function() return clock end
local f1 = Career.Fetch(pe)
clock += 0.2
assert(Career.Fetch(pe) == f1, "a Fetch inside the 0.25 s cooldown should return the last built state")
clock += 0.06
local f2 = Career.Fetch(pe)
assert(f2 ~= f1, "a Fetch after the cooldown should build a new state")
clock += 0.01
Career.Publish(pe)
assert(Career.Fetch(pe) ~= f2, "a Publish should drop the last built state, cooldown or not")
table.insert(out, "(e) Career.State.life: names follow the roster; unknown ids and the rep's template stay out; Fetch: 0.25 s, dropped by a Publish")

-- f) ClientProfile and LeveledUp
local cp = DS.ClientProfile(e)
assert(cp.life == nil and cp.career == e.career and cp.xp == e.xp and type(e.life) == "table", "ClientProfile should be the profile without life, the original untouched")
local levels = {}
DS.LeveledUp:Connect(function(p, level, was, source) table.insert(levels, { uid = p.UserId, level = level, was = was, source = source }) end)
DS.GrantXP(pe, 50, "Test")
task.wait(0.1)
assert(#levels == 0, "LeveledUp fired without a level-up")
DS.GrantXP(pe, 60, "Test") -- 110 XP: level 2
local t0 = os.clock()
while #levels == 0 and os.clock() - t0 < 2 do task.wait(0.05) end
assert(#levels == 1 and levels[1].uid == 7040 and levels[1].level == 2 and levels[1].was == 1 and levels[1].source == "Test", "LeveledUp should fire once on the level-up, fired " .. #levels)
table.insert(out, "(f) ClientProfile drops only life; LeveledUp fires (player, 2, 1, source) on the rise, not before")

-- g) a v6 profile is never overwritten
seed(7050, { v = 6, cred = 10, life = { day = 99 } })
local pg = { UserId = 7050, Name = "T70g" }
local g = DS.Load(pg)
local rawLocked = data.u_7050 -- the load's lock claim is the one write it may make
assert(g._newerSchema == true and g.v == 6 and g.life.day == 99, "a v6 profile should load flagged, with its life untouched")
local okS, whyS = DS.Save(pg)
assert(not okS and whyS == "newerSchema" and data.u_7050 == rawLocked, "Save wrote a v6 profile (" .. tostring(whyS) .. ")")
DS.MarkDirty(pg)
DS._Autosave() -- saves the other test profiles, never this one
assert(data.u_7050 == rawLocked, "autosave wrote a v6 profile")
local okR, whyR = DS._ReleaseSave(pg)
assert(not okR and whyR == "newerSchema" and data.u_7050 == rawLocked, "the leave save wrote a v6 profile (" .. tostring(whyR) .. ")")
local lastBefore = g.life.last
day += 1
assert(Life.Tick(pg) == false and g.life.day == 99 and g.life.last == lastBefore and sentKinds(7050) == "", "a v6 profile's clock stepped or toasted")
day -= 1
local kept = stored(data, "u_7050")
assert(kept.v == 6 and kept.cred == 10 and kept.life.day == 99, "the stored v6 profile changed")
table.insert(out, "(g) a v6 profile loads flagged; Save, autosave and the leave save refuse it; its clock never steps")

Cfg.WalkIns.Roster = "parody"
DS._SetStoreForTest(nil)
return "T70 OK: " .. table.concat(out, "; ")
