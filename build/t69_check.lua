-- Edit: two sessions, same day (Task 4): the Config and content the server reads. (a) Config.XP.Sources.Phone is exactly
-- { max = 60, dailyMax = 3 } and Config.WalkIns.Odds.ready exactly READY (literal copies, as t46 keeps), with Odds.min 10
-- and Odds.max 90 its range. (b) the card two_sessions: a phone DM (MESSAGES, not news) from the sender bookings, gated
-- needs = { visits = 10 } only, capped sessions / week / 2; choice 1 sure, its good outcome xp 40 and planting
-- payback_homekid at {10, 16}; choice 2 ready (no odds, sure or rare; a good and a bad outcome). The phone is its only
-- way in (source "phone": with Config.Phone off it never shows). (c) the follow-up payback_homekid exists, a walk-in
-- (no source or "walkin") from the visitor homekid (kind local); bookings is a sender with no figure. (d) the XP gate
-- with t13's seam (a fake store, a fake clock, a fake player; no Init runs): AddXP(p, 40, "Phone") pays 40 three times
-- on a day and the fourth pays 0 with the reason "daily" (Review Focus 1: the chip shows that 0 as no chip); on the
-- next day an award of 61 is trimmed to 60.
local RS, SSS = game:GetService("ReplicatedStorage"), game:GetService("ServerScriptService")
local function freshRequire(mod) local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name; local ok, r = pcall(require, c); c:Destroy(); if not ok then error(r) end; return r end
local Cfg = freshRequire(RS.OK.Config)
local W = freshRequire(RS.OK.Data.WalkIns)
local out = {}
local XP_PHONE = { max = 60, dailyMax = 3 }
local READY = { level = 7, placements = 5, followers = 30000, aura = 600 }
local function same(got, want)
  if type(got) ~= "table" then return false end
  for k, v in pairs(want) do if got[k] ~= v then return false end end
  for k in pairs(got) do if want[k] == nil then return false end end
  return true
end
local function show(t)
  if type(t) ~= "table" then return tostring(t) end
  local keys = {}
  for k in pairs(t) do table.insert(keys, k) end
  table.sort(keys)
  local parts = {}
  for _, k in ipairs(keys) do table.insert(parts, k .. " = " .. tostring(t[k])) end
  return "{ " .. table.concat(parts, ", ") .. " }"
end

-- a) Config
assert(same(Cfg.XP.Sources.Phone, XP_PHONE), "Config.XP.Sources.Phone should be { max = 60, dailyMax = 3 }, is " .. show(Cfg.XP.Sources.Phone))
local O = Cfg.WalkIns.Odds
assert(same(O.ready, READY), "Config.WalkIns.Odds.ready should be " .. show(READY) .. ", is " .. show(O.ready))
assert(O.min == 10 and O.max == 90, "Config.WalkIns.Odds min/max should be 10/90 (a ready choice's range), are " .. tostring(O.min) .. "/" .. tostring(O.max))
table.insert(out, "(a) XP.Sources.Phone {max 60, dailyMax 3}; Odds.ready {level 7, placements 5, followers 30000, aura 600}, range 10..90")

-- b) the card
local card = W.CardById.two_sessions
assert(card, "no card two_sessions in Data/WalkIns")
assert(card.source == "phone" and card.app == "MESSAGES" and not card.news and card.visitor == "bookings",
  "two_sessions should be a phone DM (MESSAGES, not news) from bookings; is source " .. tostring(card.source) .. ", app " .. tostring(card.app)
  .. ", news " .. tostring(card.news) .. ", visitor " .. tostring(card.visitor))
assert(same(card.needs, { visits = 10 }), "two_sessions needs should be { visits = 10 } only, is " .. show(card.needs))
assert(same(card.cap, { group = "sessions", per = "week", max = 2 }), "two_sessions cap should be sessions / week / 2, is " .. show(card.cap))
assert(card.under == nil, "two_sessions should have no under gate")
local c1, c2 = card.choices and card.choices[1], card.choices and card.choices[2]
assert(type(card.choices) == "table" and #card.choices == 2 and c1 and c2, "two_sessions should have two choices")
assert(c1.sure == true and not c1.rare and (c1.cost or 0) == 0 and c1.good and c1.good.xp == 40,
  "two_sessions choice 1 should be a free sure choice whose outcome pays xp 40 (xp " .. tostring(c1.good and c1.good.xp) .. ")")
local plant = c1.good.plant
assert(type(plant) == "table" and plant.id == "payback_homekid" and type(plant.at) == "table" and plant.at[1] == 10 and plant.at[2] == 16,
  "two_sessions choice 1 should plant payback_homekid at {10, 16}, plants " .. show(plant) .. " at " .. show(plant and plant.at))
assert(c2.ready == true and c2.odds == nil and not c2.sure and not c2.rare and c2.good and c2.bad and (c2.cost or 0) == 0,
  "two_sessions choice 2 should be a free ready choice (no odds, sure or rare) with a good and a bad outcome")
assert(c2.good.key == "wentoff" and c2.bad.key == "notready", "two_sessions choice 2's outcomes should be wentoff / notready, are "
  .. tostring(c2.good.key) .. " / " .. tostring(c2.bad.key))
table.insert(out, "(b) two_sessions: phone DM from bookings, needs visits 10, cap sessions/week/2; 1 sure (xp 40, plants payback_homekid {10, 16}); 2 ready (wentoff / notready)")

-- c) the follow-up and the two new names
local f = W.FollowupById.payback_homekid
assert(f, "no follow-up payback_homekid in Data/WalkIns")
assert(f.visitor == "homekid" and (f.source == nil or f.source == "walkin") and type(f.resolve) == "table",
  "payback_homekid should be a walk-in follow-up from homekid, is visitor " .. tostring(f.visitor) .. ", source " .. tostring(f.source))
local kid, desk = W.VisitorById.homekid, W.VisitorById.bookings
assert(kid and kid.kind == "local", "the visitor homekid should be kind local, is " .. tostring(kid and kid.kind))
assert(desk and desk.kind == "sender" and desk.sig == "none", "bookings should be a sender with sig none")
table.insert(out, "(c) payback_homekid: a walk-in follow-up from homekid (local); bookings a sender, sig none")

-- d) the XP gate, through a fresh DataService on a fake store
local function fakeStore(data)
  local s = { calls = 0 }
  function s:UpdateAsync(k, fn) s.calls += 1; local new = fn(data[k]); if new ~= nil then data[k] = new end; return new end
  return s
end
local t, day = 1000000, 20261030
local DS = freshRequire(SSS.OK.Services.DataService)
DS._SetConfigForTest(Cfg); DS._retryDelays = { 0, 0, 0 }; DS._lockWaits = { 0, 0, 0 }; DS._quiet = true
DS._now = function() return t end; DS._day = function() return day end
DS._SetStoreForTest(fakeStore({}))
local p = { UserId = 6901, Name = "T69" }
local prof = DS.Load(p)
local xp0 = prof.xp
for i = 1, 3 do
  t += 1
  local paid = DS.AddXP(p, 40, "Phone")
  assert(paid == 40, "Phone XP award " .. i .. " of 3 should pay 40, paid " .. tostring(paid))
end
t += 1
local paid4, _, why4 = DS.AddXP(p, 40, "Phone")
assert(paid4 == 0 and why4 == "daily", "the 4th Phone XP award in a day should pay 0 ('daily'), paid " .. tostring(paid4) .. " (" .. tostring(why4) .. ")")
assert(prof.xp == xp0 + 120, "after 3 paid awards xp should be " .. (xp0 + 120) .. ", is " .. tostring(prof.xp))
day += 1; t += 86400
local paid5 = DS.AddXP(p, 61, "Phone")
assert(paid5 == 60, "a 61 Phone XP award should be trimmed to max 60, paid " .. tostring(paid5))
DS._SetStoreForTest(nil)
table.insert(out, "(d) AddXP Phone: 40 x3 paid, the 4th 0 'daily'; next day 61 -> 60")

return "T69 OK: " .. table.concat(out, "; ")
