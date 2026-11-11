-- Edit: the Weekly Single is the same on every server and needs no gear; a producer card holds only public fields.
local RS = game:GetService("ReplicatedStorage")
local function freshRequire(mod) local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name; local ok, r = pcall(require, c); c:Destroy(); if not ok then error(r) end; return r end
local A, B = freshRequire(RS.OK.Modules.DailyRequests), freshRequire(RS.OK.Modules.DailyRequests)
local Check = freshRequire(RS.OK.Modules.BriefCheck)
local P = freshRequire(RS.OK.Systems.Profiles)
P._SetConfigForTest(freshRequire(RS.OK.Config), freshRequire(RS.OK.Modules.LifeRules)) -- Edit caches a plain require across syncs
local out = {}
local wk = A.Week(os.time())
local w1, w2 = A.ForWeek(wk), B.ForWeek(wk)
assert(w1.id == "w" .. wk and w1.id == w2.id and w1.title == w2.title and w1.template == w2.template and w1.weekly, "servers disagree on the weekly")
assert(next(Check.Requires(w1)) == nil and #w1.asks == 3 and w1.bonus, "weekly shape / needs gear")
for k = 0, 5 do assert(next(Check.Requires(A.ForWeek(wk + k))) == nil, "a weekly needs gear") end
assert(A.Brief("w" .. wk) == w1 and A.Brief("w123") == nil and A.Brief("w99999") == nil and A.Brief("w1663154086") == nil, "weekly id parsing")
assert(A.ForWeek(wk + 1).id ~= w1.id, "weeks do not change")
table.insert(out, "weekly " .. w1.id .. " '" .. w1.title .. "' same on two servers, no gear, strict ids")
local prof = { level = 4, xp = 999, cred = 77, fireTotal = 5, flipsReceived = 2, xpLog = { secret = 1 }, gear = { rollfx = true }, daw = { slots = {} },
  sessions = { deliveries = 9, last = "x" }, credits = { { t = "A", a = "B", s = 3 }, { t = "C", a = "D", s = 2 }, { t = "E", a = "F", s = 2 }, { t = "G", a = "H", s = 3 } },
  plaques = { { w = 1, t = "P1", a = "X" } }, lock = { id = "srv" } }
local card = P.CardFrom(prof, "Maya", 123, 4)
local expected = { "name", "level", "rank", "fires", "flips", "deliveries", "streak", "credits", "recent", "plaques", "plaqueCount", "userId", "aura", "followers", "placements", "hits", "sponsors",
  "year", "tier", "title", "ribbons" }
local allowed = {}; for _, k in ipairs(P.PUBLIC) do allowed[k] = true end
for _, k in ipairs(expected) do assert(allowed[k], "PUBLIC lacks " .. k) end
assert(#P.PUBLIC == #expected, "PUBLIC has fields beyond the expected list: " .. table.concat(P.PUBLIC, ","))
for k in pairs(card) do assert(allowed[k], "card leaks field " .. tostring(k)) end
assert(card.level == 4 and card.rank == "ENGINEER" and card.fires == 5 and card.flips == 2 and card.credits == 4 and #card.recent == 3 and card.recent[1].t == "G" and card.plaqueCount == 1 and card.streak == 4 and card.deliveries == 9, "card values wrong")
assert(card.xp == nil and card.cred == nil and card.xpLog == nil and card.gear == nil and card.sessions == nil, "private fields on the card")
assert(card.aura == 0 and card.followers == 0 and card.placements == 0 and card.hits == 0 and card.sponsors == 0, "a profile without career should show zero stats")
assert(#expected == 21, "PUBLIC should hold 21 fields")
assert(card.year == 1 and card.tier == "LOCAL" and card.title == "NEW IN TOWN" and type(card.ribbons) == "table" and #card.ribbons == 0, "a profile without a life should read as new")
local lived = P.CardFrom({ level = 2, life = { day = 15, tier = "KNOWN", firsts = { hit = 3, placement = 2 }, ribbons = { sponsor = 4, hit = 3 },
  story = { { d = 1, k = "beat" } }, disco = { { d = 1, kind = "hit", v = "navx" } } } }, "Maya", 123, 0)
assert(lived.year == 3 and lived.tier == "KNOWN" and lived.title == "CHART MAKER", "card life fields: year " .. tostring(lived.year) .. ", tier " .. tostring(lived.tier) .. ", title " .. tostring(lived.title))
assert(table.concat(lived.ribbons, ",") == "hit,sponsor", "ribbons should be ids in Config order: " .. table.concat(lived.ribbons, ","))
assert(lived.story == nil and lived.disco == nil and lived.life == nil, "a card leaks the story")
table.insert(out, "card: only the " .. #expected .. " public fields (no xp, Money, gear, logs, beats, story); career stats 0 without a career; latest 3 credits, newest first; year 3, KNOWN, CHART MAKER, ribbons hit,sponsor")
return "T25 OK: " .. table.concat(out, "; ")
