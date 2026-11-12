-- Edit: the walk-in economy check (walk-ins Task 9). Studio's twin of spec/pacing_spec.lua, on the live modules.
-- (a) build the economy CareerSim runs on from the live sources spec/economy_fixture.lua names, and assert it equals the
--     literal copy of that fixture below (every field except firePerDay, a sim assumption), so the CLI pacing check and
--     the live game can't drift; LIFE (Config.Life) and RANKS (Config.Ranks) ride along for spec/life_rules_spec.lua;
--     the sim inputs pacing_spec types as literals (odds, follow-up and drop delays, artist
--     cooldown, walk-ins a day, phone pops a day = Config.Phone.DailyMax, the daily Aura heal = the AuraHeal source's
--     aura.max, the Studio Two and Legend gates, the fame tiers and their visits) must equal the live Config values too, and
--     Config.Career.Sources.Phone must register Aura and Followers only, at the maxes spec/walkins_data_spec.lua's
--     PHONE_CAPS holds (60 and 2,000); spec/rush_spec.lua's literals (Rush, Gap, FirstDelay, DailyMax) must equal
--     Config.WalkIns's (RUSH_SPEC);
-- (b) run CareerSim (Lcg, Seeds) on the live deck and Config.WalkIns values under pacing_spec's four original policies
--     and its 20-seed assertions: random: Studio Two median day 4..6, p10 >= 3, p90 <= 7, Legend nil or >= day 15, steady
--     share <= 0.50 on every seed and median <= 0.50, and once the deck has a phone card, phone pops a day > 0 and net phone Aura
--     a day <= 15 (means over the seeds); greedy (most expected money, planted follow-ups and rare outcomes included),
--     the career chaser and spend-down: steady share <= 0.50 on every seed. Every run carries the fame tiers (a tier's
--     first crossing plants its visit), and the random player's median day per tier must be reached.
--     The money floor is pacing_spec's alone (its 200 recorded seeds would outrun Studio's call limit), so the 20-seed
--     median share is printed, not floored;
-- (c) t21's basics on day 1 still hold: its day-1 step on the live catalog leaves Roll FX and Swing Unit owned.
local RS = game:GetService("ReplicatedStorage")
local function freshRequire(mod) local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name; local ok, r = pcall(require, c); c:Destroy(); if not ok then error(r) end; return r end
local Cfg = freshRequire(RS.OK.Config)
local A = freshRequire(RS.OK.Data.Artists)
local W = freshRequire(RS.OK.Data.WalkIns)
local Check = freshRequire(RS.OK.Modules.BriefCheck)
local Sim = freshRequire(RS.OK.Modules.CareerSim)
local R = freshRequire(RS.OK.Modules.WalkInRules)
local CR = freshRequire(RS.OK.Modules.CareerRules)
local Tour = freshRequire(RS.OK.Systems.Tour)

-- a literal copy of spec/economy_fixture.lua (keep the two identical)
local FIXTURE = {
  requests = {
    { cred = 400, xp = 25, level = 1, needs = {} },                   -- j1 Late Bus Home (juno)
    { cred = 250, xp = 20, level = 1, needs = {} },                   -- j2 Glow Stick
    { cred = 250, xp = 20, level = 1, needs = {} },                   -- j3 Corner Store Run
    { cred = 300, xp = 20, level = 1, needs = { "Bass" } },           -- j4 Summer Static (min 808)
    { cred = 300, xp = 20, level = 1, needs = { "Rolls" } },          -- j5 Arcade Lights (rolls)
    { cred = 250, xp = 20, level = 1, needs = {} },                   -- t1 Cold Engine (tavi)
    { cred = 250, xp = 20, level = 1, needs = {} },                   -- t2 Red Light Wait
    { cred = 300, xp = 25, level = 1, needs = { "Bass" } },           -- t3 Gravel (min 808)
    { cred = 300, xp = 25, level = 1, needs = { "Rolls" } },          -- t4 Back Pocket (rolls)
    { cred = 350, xp = 25, level = 3, needs = {} },                   -- r1 Slow Rain Radio (rue)
    { cred = 350, xp = 25, level = 3, needs = { "Bass" } },           -- r2 Porch Light (notes)
    { cred = 350, xp = 25, level = 3, needs = { "Swing" } },          -- r3 Blue Hour Call (swing)
    { cred = 450, xp = 30, level = 5, needs = { "Bass" } },           -- v1 Iron Chapel (vesper; notes)
    { cred = 450, xp = 30, level = 5, needs = { "Rolls", "Swing" } }, -- v2 Midnight Ledger (swing, rolls)
    { cred = 450, xp = 30, level = 5, needs = { "Bass", "Swing" } },  -- v3 Velvet Alarm (swing, min 808)
    { cred = 550, xp = 35, level = 7, needs = { "Rolls" } },          -- n1 Pixel Heart (nyx; rolls)
    { cred = 550, xp = 35, level = 7, needs = { "Swing" } },          -- n2 Respawn (swing)
    { cred = 550, xp = 35, level = 7, needs = { "Bass" } },           -- n3 Low Poly (notes)
    { cred = 650, xp = 40, level = 9, needs = { "Rolls" } },          -- i1 Northbound (indigo; rolls)
    { cred = 650, xp = 40, level = 9, needs = { "Bass" } },           -- i2 Platform Nine (notes)
    { cred = 650, xp = 40, level = 9, needs = { "Rolls", "Swing" } }, -- i3 Last Train (swing, rolls)
  },
  daily = { cred = 200, xp = 15, count = 3 },
  weekly = { cred = 800, xp = 50 },
  cypherWinCred = 500,
  cypherXP = 40,
  tourXP = 50,
  streakBonus = { [3] = 300, [7] = 600 },
  fireCred = 30,
  firePerDay = 4,
  levels = { 0, 100, 250, 450, 700, 1000, 1400, 1900, 2500, 3200 },
  activityXP = 30,
  beatSaveXP = 20,
  gear = {
    { id = "808", price = 0, level = 1, feature = "Bass" },
    { id = "rollfx", price = 250, level = 1, feature = "Rolls" },
    { id = "swing", price = 350, level = 1, feature = "Swing" },
  },
  feeds = {
    delivery = {
      [2] = { aura = 5, followers = 40 },
      [3] = { aura = 10, followers = 120 },
    },
    plaque = { aura = 40, followers = 300 },
    cypher = { aura = 25 },
    fire = { followers = 10 },
  },
  XP_PHONE = { max = 60, dailyMax = 3 },
  READY = { level = 7, placements = 5, followers = 30000, aura = 600 },
  WALKINS = {
    Odds = { beatCenter = 3, beatPer = 3, relPer = 4 },
    FirstEver = { 15, 20 },
    Cold = { aura = -50, quietDays = 3, rearmAura = -25, dailyMax = 2 },
    RecentMax = 3,
  },
  LIFE = {
    Tiers = { { id = "LOCAL", followers = 0 }, { id = "BUZZING", followers = 1000 }, { id = "KNOWN", followers = 5000 },
      { id = "FAMOUS", followers = 20000 }, { id = "ICON", followers = 100000 } },
    DaysPerYear = 7, StoryMax = 100, DiscoMax = 200,
    Firsts = { "beat", "delivery", "delivery3", "placement", "hit", "sponsor", "hall", "cypher", "level5", "buzzing", "known", "streak7" },
    Titles = {
      { tier = 5, id = "icon" },
      { tier = 4, id = "famous" },
      { first = "hit", id = "chart" },
      { tier = 3, id = "known" },
      { first = "sponsor", id = "sponsored" },
      { first = "cypher", id = "cypher" },
      { first = "placement", id = "record" },
      { tier = 2, id = "buzzing" },
      { first = "delivery", id = "regular" },
      { id = "new" },
    },
    Ribbons = {
      { id = "streak7", rule = { first = "streak7" } },
      { id = "placements10", rule = { count = "placements", n = 10 } },
      { id = "hit", rule = { first = "hit" } },
      { id = "sponsor", rule = { first = "sponsor" } },
      { id = "icon", rule = { tier = 5 } },
    },
    TierVisits = { BUZZING = "tier_buzzing", KNOWN = "tier_known", FAMOUS = "tier_famous", ICON = "tier_icon" },
  },
  RANKS = { "INTERN", "RUNNER", "ASSISTANT", "ENGINEER", "BEATMAKER", "PRODUCER", "HITMAKER", "HEAD PRODUCER", "EXEC PRODUCER", "STUDIO LEGEND" },
}
-- pacing_spec's sim-input literals (ODDS, GATES and its Run arguments; phoneSeed is per seed, not Config)
local PACING = {
  odds = { auraPer = 20, auraCap = 15, followersPer = 1000, followersCap = 10, min = 10, max = 90,
    beatCenter = 3, beatPer = 3, relPer = 4,
    ready = { level = 7, placements = 5, followers = 30000, aura = 600 } },
  followupAt = { 2, 4 }, dropAt = { 1, 1 }, cooldown = 3, walkinsPerDay = 8, phonePerDay = 6, auraHeal = 5,
  gates = {
    studio_two = { needs = { placements = 1, aura = 300 }, cost = 5000 },
    plate_legend = { needs = { hits = 1, followers = 20000, aura = 1000 }, cost = 4000, level = 10 },
  },
  tiers = { { id = "LOCAL", followers = 0 }, { id = "BUZZING", followers = 1000 }, { id = "KNOWN", followers = 5000 },
    { id = "FAMOUS", followers = 20000 }, { id = "ICON", followers = 100000 } },
  tierVisits = { BUZZING = "tier_buzzing", KNOWN = "tier_known", FAMOUS = "tier_famous", ICON = "tier_icon" },
}
-- a literal copy of spec/walkins_data_spec.lua's PHONE_CAPS: the most one phone outcome may add, per stat
local PHONE_CAPS = { aura = 60, followers = 2000 }
-- a literal copy of spec/rush_spec.lua's Config.WalkIns values (RUSH, GAP, FIRST, DAILY): the rush-hour pace check
local RUSH_SPEC = { Rush = { Chance = 0.15, Size = { 2, 3 }, Short = { 10, 20 } }, Gap = { 240, 360 }, FirstDelay = { 60, 120 }, DailyMax = 8 }

-- the first path where a and b differ (both ways), or nil when they are equal
local function diff(a, b, path)
  if type(a) ~= "table" or type(b) ~= "table" then
    if a == b then return nil end
    return string.format("%s: live %s, expected %s", path, tostring(a), tostring(b))
  end
  for k, v in pairs(a) do local d = diff(v, b[k], path .. "." .. tostring(k)); if d then return d end end
  for k, v in pairs(b) do if a[k] == nil then return diff(nil, v, path .. "." .. tostring(k)) end end
  return nil
end
local function copy(t) local c = {}; for k, v in pairs(t) do c[k] = type(v) == "table" and copy(v) or v end; return c end
-- { stat = amount } of a Config.Career.Sources entry
local function amounts(source) local t = {}; for stat, rule in pairs(source) do t[stat] = rule.amount end; return t end

-- a) the economy from its live sources
local requests = {}
for _, b in ipairs(A.Briefs) do
  local needs = {}
  for need in pairs(Check.Requires(b)) do table.insert(needs, need) end
  table.sort(needs)
  table.insert(requests, { cred = b.reward.cred, xp = b.reward.xp, level = A.ArtistById[b.artist].level, needs = needs })
end
local gear = {}
for _, it in ipairs(Cfg.Gear) do
  if it.feature then table.insert(gear, { id = it.id, price = it.price, level = it.level, feature = it.feature }) end
end
local S = Cfg.Career.Sources
local economy = {
  requests = requests,
  daily = { cred = Cfg.Daily.Cred, xp = Cfg.Daily.XP, count = Cfg.Daily.Count },
  weekly = { cred = Cfg.Weekly.Cred, xp = Cfg.Weekly.XP },
  cypherWinCred = Cfg.Cypher.Reward.WinCred,
  cypherXP = Cfg.Cypher.Reward.EnterXP + Cfg.Cypher.Reward.WinXP,
  tourXP = Tour.RewardXP,
  streakBonus = copy(Cfg.Daily.StreakBonus),
  fireCred = Cfg.Cred.Sources.Fire.amount,
  levels = copy(Cfg.Levels),
  activityXP = Cfg.XP.GroupDailyCap.Activity,
  beatSaveXP = 2 * Cfg.XP.Sources.BeatSave.xp,
  gear = gear,
  feeds = { delivery = copy(Cfg.Career.DeliveryFeed), plaque = amounts(S.Plaque), cypher = amounts(S.Cypher), fire = amounts(S.Fire) },
  XP_PHONE = copy(Cfg.XP.Sources.Phone),
  READY = copy(Cfg.WalkIns.Odds.ready),
  WALKINS = {
    Odds = { beatCenter = Cfg.WalkIns.Odds.beatCenter, beatPer = Cfg.WalkIns.Odds.beatPer, relPer = Cfg.WalkIns.Odds.relPer },
    FirstEver = copy(Cfg.WalkIns.FirstEver),
    Cold = copy(Cfg.WalkIns.Cold),
    RecentMax = Cfg.WalkIns.RecentMax,
  },
  LIFE = copy(Cfg.Life),
  RANKS = copy(Cfg.Ranks),
}
local expected = copy(FIXTURE)
expected.firePerDay = nil
local drift = diff(economy, expected, "economy")
assert(not drift, "live economy differs from spec/economy_fixture.lua at " .. tostring(drift))
economy.firePerDay = FIXTURE.firePerDay

local WI = Cfg.WalkIns
local studioTwo, legend
for _, g in ipairs(Cfg.Career.Gates) do if g.id == "studio_two" then studioTwo = g end end
for _, it in ipairs(Cfg.Gear) do if it.id == "plate_legend" then legend = it end end
assert(studioTwo and legend, "Config.Career.Gates studio_two or Config.Gear plate_legend missing")
assert(Cfg.Phone, "Config.Phone missing")
assert(S.AuraHeal and S.AuraHeal.aura, "Config.Career.Sources.AuraHeal.aura missing")
local input = {
  odds = WI.Odds, followupAt = WI.FollowupAt, dropAt = WI.DropAt, cooldown = WI.ArtistCooldown, walkinsPerDay = WI.DailyMax,
  phonePerDay = Cfg.Phone.DailyMax, auraHeal = S.AuraHeal.aura.max,
  gates = {
    studio_two = { needs = studioTwo.needs, cost = studioTwo.cost },
    plate_legend = { needs = legend.needs, cost = legend.price, level = legend.level },
  },
  tiers = Cfg.Life.Tiers, tierVisits = Cfg.Life.TierVisits,
}
local inputDrift = diff(input, PACING, "input")
assert(not inputDrift, "live sim inputs differ from spec/pacing_spec.lua at " .. tostring(inputDrift))
local rushDrift = diff({ Rush = WI.Rush, Gap = WI.Gap, FirstDelay = WI.FirstDelay, DailyMax = WI.DailyMax }, RUSH_SPEC, "Config.WalkIns")
assert(not rushDrift, "live walk-in pace differs from spec/rush_spec.lua's literals at " .. tostring(rushDrift))
-- the Phone career source: Aura max 60 and Followers max 2,000, no other stat, equal to PHONE_CAPS (a Config retune
-- fails here until spec/walkins_data_spec.lua's PHONE_CAPS is updated with it), and each dailyMax = Config.Phone.DailyMax
-- + 1 (E3: a DM opened before UTC midnight is counted on the old day but awarded on the new; a DailyMax retune that
-- leaves these behind would refuse the day's last award while its result card promises it)
local phoneSource = S.Phone
assert(phoneSource, "Config.Career.Sources.Phone missing")
for stat, rule in pairs(phoneSource) do
  assert(PHONE_CAPS[stat], "Config.Career.Sources.Phone registers " .. tostring(stat) .. " (Aura and Followers only)")
  assert(rule.max == PHONE_CAPS[stat], string.format("Config.Career.Sources.Phone.%s.max is %s, PHONE_CAPS says %d", stat,
    tostring(rule.max), PHONE_CAPS[stat]))
  assert(rule.dailyMax == Cfg.Phone.DailyMax + 1, string.format("Config.Career.Sources.Phone.%s.dailyMax is %s, want Config.Phone.DailyMax + 1 = %d (E3: a DM opened before UTC midnight is counted on the old day but awarded on the new)",
    stat, tostring(rule.dailyMax), Cfg.Phone.DailyMax + 1))
end
for stat in pairs(PHONE_CAPS) do assert(phoneSource[stat], "Config.Career.Sources.Phone." .. stat .. " missing") end

-- b) pacing_spec's four original policies and their 20-seed assertions (the floor is pacing_spec's, on 200 seeds), on
--    the live deck and Config.WalkIns
local fails = {}
local function ok(name, cond) if not cond then table.insert(fails, name) end end
local DAYS = 60
local function run(seed, policy, spendDown)
  local res = Sim.Run({ days = DAYS, economy = economy, deck = W.Deck, rules = R, careerRules = CR, odds = input.odds,
    followupAt = input.followupAt, dropAt = input.dropAt, cooldown = input.cooldown, walkinsPerDay = input.walkinsPerDay,
    phonePerDay = input.phonePerDay, phoneSeed = seed, auraHeal = input.auraHeal, rng = Sim.Lcg(seed), policy = policy,
    spendDown = spendDown, gates = input.gates, tiers = input.tiers, tierVisits = input.tierVisits })
  -- yield after each of the 80 runs: a call that never yields freezes Studio's main thread, and past about a
  -- minute the MCP connection drops ("Target is not reachable", 11-11 after the place reopened)
  task.wait()
  return res
end
-- the phone checks apply once the deck has a phone card
local hasPhone = false
for _, card in ipairs(W.Deck.cards) do if card.source == "phone" then hasPhone = true end end
-- order statistics copied verbatim from pacing_spec: nil day = +infinity; median of 20 = mean of the 10th and 11th;
-- percentile k = nearest rank ceil(k / 100 * n)
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

local twoDays, shares, legendMin, popsPerDay, auraPerDay = {}, {}, math.huge, 0, 0
local tierDays = {}
for _, seed in ipairs(Sim.Seeds) do
  local res = run(seed, "random")
  for _, t in ipairs(input.tiers) do
    if t.id ~= "LOCAL" then
      tierDays[t.id] = tierDays[t.id] or {}
      table.insert(tierDays[t.id], dayOrInf(res.tierDays[t.id]))
    end
  end
  table.insert(twoDays, dayOrInf(res.studioTwoDay))
  table.insert(shares, res.steadyShare)
  legendMin = math.min(legendMin, dayOrInf(res.legendDay))
  popsPerDay += res.phonePops / DAYS / #Sim.Seeds
  auraPerDay += res.phoneAura / DAYS / #Sim.Seeds
  ok(string.format("random seed %d: legend day %s >= 15", seed, fmt(dayOrInf(res.legendDay))), res.legendDay == nil or res.legendDay >= 15)
  ok(string.format("random seed %d: steady share %.3f <= 0.50", seed, res.steadyShare), res.steadyShare <= 0.50)
end
local twoMedian, twoP10, twoP90 = median(twoDays), percentile(twoDays, 10), percentile(twoDays, 90)
ok("random: Studio Two median day " .. fmt(twoMedian) .. " in 4..6", twoMedian >= 4 and twoMedian <= 6)
ok("random: Studio Two 10th percentile day " .. fmt(twoP10) .. " >= 3", twoP10 >= 3)
ok("random: Studio Two 90th percentile day " .. fmt(twoP90) .. " <= 7", twoP90 <= 7)
local shareMedian = median(shares)
ok(string.format("random: steady share median %.3f <= 0.50", shareMedian), shareMedian <= 0.50)
local tierParts = {}
for _, t in ipairs(input.tiers) do
  local days = tierDays[t.id]
  if days then
    ok("random: " .. t.id .. " median day " .. fmt(median(days)) .. " reached", median(days) < math.huge)
    table.insert(tierParts, t.id .. " " .. fmt(median(days)))
  end
end
if hasPhone then
  ok(string.format("random: phone pops per day %.2f > 0", popsPerDay), popsPerDay > 0)
  ok(string.format("random: phone Aura per day %.2f <= 15", auraPerDay), auraPerDay <= 15)
end
for _, seed in ipairs(Sim.Seeds) do
  local res = run(seed, "greedy")
  ok(string.format("greedy seed %d: steady share %.3f <= 0.50", seed, res.steadyShare), res.steadyShare <= 0.50)
end
for _, seed in ipairs(Sim.Seeds) do
  local res = run(seed, "chaser")
  ok(string.format("chaser seed %d: steady share %.3f <= 0.50", seed, res.steadyShare), res.steadyShare <= 0.50)
end
for _, seed in ipairs(Sim.Seeds) do
  local res = run(seed, "random", true)
  ok(string.format("spend-down seed %d: steady share %.3f <= 0.50", seed, res.steadyShare), res.steadyShare <= 0.50)
end
if #fails > 0 then error(#fails .. " pacing case(s) failed: " .. table.concat(fails, "; ")) end

-- c) t21's day-1 step on the live catalog: 3 first-time deliveries (stars 3/2/3, capped), the dailies, activity +
-- 2 beat saves + the tour's XP, then the cheapest gear you can afford at your level, until nothing fits
local function levelFor(xp) local lv = 1; for i, th in ipairs(Cfg.Levels) do if xp >= th then lv = i end end; return lv end
local owned = {}
for _, it in ipairs(Cfg.Gear) do if it.price == 0 then owned[it.id] = true end end
local function has(feature) for _, it in ipairs(Cfg.Gear) do if it.feature == feature and owned[it.id] then return true end end; return false end
local xp, cred, n, three = 0, 0, 0, true
local level = levelFor(xp)
for _, b in ipairs(A.Briefs) do
  if n >= 3 then break end
  local can = level >= A.ArtistById[b.artist].level
  for need in pairs(Check.Requires(b)) do if not has(need) then can = false end end
  if can then
    n += 1
    local mult = three and 1.5 or 1; three = not three
    xp += math.min(math.floor(b.reward.xp * mult + 0.5), Cfg.XP.Sources.Delivery.max)
    cred += math.min(math.floor(b.reward.cred * mult + 0.5), Cfg.Cred.Sources.Delivery.max)
  end
end
xp += Cfg.Daily.XP * Cfg.Daily.Count + Cfg.XP.GroupDailyCap.Activity + 2 * Cfg.XP.Sources.BeatSave.xp + Tour.RewardXP
cred += Cfg.Daily.Cred * Cfg.Daily.Count
level = levelFor(xp)
local earned = cred
while true do
  local best
  for _, it in ipairs(Cfg.Gear) do
    if not owned[it.id] and level >= it.level and cred >= it.price and (not best or it.price < best.price) then best = it end
  end
  if not best then break end
  owned[best.id] = true; cred -= best.price
end
assert(owned.rollfx and owned.swing, string.format("basics (Roll FX + Swing Unit) should be owned on day 1 (t21): $%d earned, rollfx %s, swing %s",
  earned, tostring(owned.rollfx == true), tostring(owned.swing == true)))

return string.format("T46 OK: Studio Two median day %s, legend min day %s, steady share median %.1f%%, phone pops/day %.2f, phone aura/day %.2f, tier days %s",
  fmt(twoMedian), fmt(legendMin), shareMedian * 100, popsPerDay, auraPerDay, table.concat(tierParts, ", "))
