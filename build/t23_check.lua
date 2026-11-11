-- Edit: daily requests are the same on every server for a date, need no gear, and the streak rules hold.
local RS = game:GetService("ReplicatedStorage")
local function freshRequire(mod) local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name; local ok, r = pcall(require, c); c:Destroy(); if not ok then error(r) end; return r end
local A, B = freshRequire(RS.OK.Modules.DailyRequests), freshRequire(RS.OK.Modules.DailyRequests) -- two "servers"
local Check = freshRequire(RS.OK.Modules.BriefCheck)
local Dl = freshRequire(RS.OK.Systems.Dailies)
local out = {}
local day = 20261022
local a, b = A.ForDay(day), B.ForDay(day)
assert(#a == 3 and #b == 3, "three dailies a day")
local seenT = {}
for i = 1, 3 do
  assert(a[i].id == b[i].id and a[i].template == b[i].template and a[i].title == b[i].title and a[i].artist == b[i].artist, "servers disagree on daily " .. i)
  assert(not seenT[a[i].template], "a template repeats within the day"); seenT[a[i].template] = true
  assert(next(Check.Requires(a[i])) == nil, "a daily needs gear: " .. a[i].id)
  assert(A.Brief(a[i].id) == a[i] and a[i].id == string.format("d%d_%d", day, i), "id round trip")
end
local differs = false
for k = 1, 7 do local o = A.ForDay(day + k); if o[1].template ~= a[1].template or o[2].template ~= a[2].template then differs = true end end
assert(differs, "dailies never change")
assert(A.Brief("d2026_9") == nil and A.Brief("x") == nil and A.Brief(5) == nil and A.Brief("d20261022_4") == nil, "bad ids accepted")
local t0 = os.clock()
assert(A.Brief("d1663154086_1") == nil and A.Brief("d3810637733_1") == nil, "forged seed-0 ids reach the generator")
assert(os.clock() - t0 < 0.5, "forged id took too long")
table.insert(out, "two servers pick the same 3 for a date (" .. a[1].title .. ", " .. a[2].title .. ", " .. a[3].title .. "); no gear needed; they change by day")
assert(A.PrevDay(20261101) == 20261031 and A.PrevDay(20270101) == 20261231 and A.PrevDay(20260301) == 20260228, "PrevDay across month/year ends")
assert(Dl.NextStreak(nil, 0, day) == 1, "first delivery should start a streak of 1")
assert(Dl.NextStreak(day, 1, day) == 1, "a second delivery the same day keeps the streak")
assert(Dl.NextStreak(day, 1, 20261023) == 2, "the next day grows the streak")
assert(Dl.NextStreak(20261023, 2, 20261025) == 1, "a missed day resets the streak")
assert(Dl.NextStreak(20261031, 5, 20261101) == 6, "streak across a month end")
table.insert(out, "streak: starts at 1, same day keeps, next day grows, a missed day resets, month ends handled")
return "T23 OK: " .. table.concat(out, "; ")
