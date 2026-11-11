-- Edit: gear catalog sanity and a pacing simulation of the Studio Sessions economy (no live state).
local RS = game:GetService("ReplicatedStorage")
local function freshRequire(mod) local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name; local ok, r = pcall(require, c); c:Destroy(); if not ok then error(r) end; return r end
local Cfg = freshRequire(RS.OK.Config)
local A = freshRequire(RS.OK.Data.Artists)
local Check = freshRequire(RS.OK.Modules.BriefCheck)
local out = {}
-- catalog
local ids, feats, firstBuys = {}, {}, 0
for _, it in ipairs(Cfg.Gear) do
  assert(not ids[it.id], "duplicate gear " .. it.id); ids[it.id] = it
  assert(it.price >= 0 and it.level >= 1 and it.level <= #Cfg.Levels and it.name and it.desc and it.kind, "gear shape: " .. it.id)
  if it.feature then feats[it.feature] = it end
  if (it.kind == "neon" or it.kind == "plate") then assert(typeof(it.color) == "Color3", "look without colour: " .. it.id) end
end
assert(feats.Bass and feats.Bass.price == 0 and feats.Rolls and feats.Swing, "tools must cover Bass (free), Rolls and Swing")
local starter; for _, b in ipairs(A.Briefs) do if b.starter then starter = b end end
local starterCred = math.floor(starter.reward.cred * 1.5 + 0.5)
assert(feats.Rolls.price + feats.Swing.price <= starterCred, "the starter (3 stars) should pay for Roll FX + Swing Unit")
assert(#Cfg.Ranks == #Cfg.Levels, "one rank per level")
table.insert(out, string.format("%d gear items; 808 free; Roll FX + Swing Unit = %d Cred <= starter %d", #Cfg.Gear, feats.Rolls.price + feats.Swing.price, starterCred))
-- pacing: 3 first-time deliveries a day (stars alternate 3/2), activity 30 XP/day, 2 paying beat saves/day,
-- tour 50 XP on day 1; buy the cheapest unowned gear you can each evening
local function levelFor(xp) local lv = 1; for i, th in ipairs(Cfg.Levels) do if xp >= th then lv = i end end; return lv end
local xp, cred, owned, done = 0, 0, {}, {}
for _, it in ipairs(Cfg.Gear) do if it.price == 0 then owned[it.id] = true end end
local function has(feature) for _, it in ipairs(Cfg.Gear) do if it.feature == feature and owned[it.id] then return true end end; return false end
local top = Cfg.Gear[#Cfg.Gear]
local basicsDay, topDay, starsFlip = nil, nil, true
local daily = Cfg.Daily -- step 6: daily requests (nil until they ship)
for day = 1, 60 do
  local level = levelFor(xp)
  local n = 0
  for _, b in ipairs(A.Briefs) do
    if n >= 3 then break end
    local a = A.ArtistById[b.artist]
    local ok = not done[b.id] and level >= a.level
    for need in pairs(Check.Requires(b)) do if not has(need) then ok = false end end
    if ok then
      done[b.id] = true; n += 1
      local mult = starsFlip and 1.5 or 1; starsFlip = not starsFlip
      xp += math.min(math.floor(b.reward.xp * mult + 0.5), Cfg.XP.Sources.Delivery.max)
      cred += math.min(math.floor(b.reward.cred * mult + 0.5), Cfg.Cred.Sources.Delivery.max)
    end
  end
  if daily then xp += daily.XP * daily.Count; cred += daily.Cred * daily.Count end
  xp += Cfg.XP.GroupDailyCap.Activity + 2 * Cfg.XP.Sources.BeatSave.xp + (day == 1 and 50 or 0)
  level = levelFor(xp)
  local bought = true
  while bought do
    bought = false
    local best
    for _, it in ipairs(Cfg.Gear) do
      if not owned[it.id] and level >= it.level and cred >= it.price and (not best or it.price < best.price) then best = it end
    end
    if best then owned[best.id] = true; cred -= best.price; bought = true end
  end
  if not basicsDay and owned.rollfx and owned.swing then basicsDay = day end
  if not topDay and owned[top.id] then topDay = day end
end
assert(basicsDay == 1, "basics (Roll FX + Swing Unit) should be owned on day 1, got day " .. tostring(basicsDay))
assert(topDay == nil or topDay >= 15, "top-tier gear reached on day " .. tostring(topDay) .. " (should be week 3 or later)")
table.insert(out, string.format("pacing at 3 deliveries/day: basics on day %d, %s on day %s, level %d after 60 days", basicsDay, top.name, tostring(topDay or "never (needs daily Cred)"), levelFor(xp)))
return "T21 OK: " .. table.concat(out, "; ")
