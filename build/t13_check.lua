-- Edit: DataService v3 unit checks with fake stores and a fake clock (no real DataStore, no real players).
-- Two DataService copies sharing one fake store stand in for two servers.
local RS, SSS = game:GetService("ReplicatedStorage"), game:GetService("ServerScriptService")
local function freshRequire(mod) local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name; local ok, r = pcall(require, c); c:Destroy(); if not ok then error(r) end; return r end
local Cfg = freshRequire(RS.OK.Config)
local function newDS()
  local DS = freshRequire(SSS.OK.Services.DataService)
  DS._SetConfigForTest(Cfg); DS._retryDelays = { 0, 0, 0 }; DS._lockWaits = { 0, 0, 0 }; DS._quiet = true
  return DS
end
local DS = newDS()
local out = {}
-- levels
for xp, lv in pairs({[0] = 1, [99] = 1, [100] = 2, [249] = 2, [250] = 3, [300] = 3, [3200] = 10, [99999] = 10}) do assert(DS.LevelFor(xp) == lv, "LevelFor(" .. xp .. ") ~= " .. lv) end
table.insert(out, "level ladder 0/100/250/.../3200")

-- 1) a store that always errors: 4 attempts, profile flagged, never written
local calls = 0
DS._SetStoreForTest({ UpdateAsync = function() calls += 1; error("throttled") end })
local p1 = { UserId = 101 }
local prof1 = DS.Load(p1)
assert(prof1._loadFailed == true and calls == 4, "failed load not flagged after 4 attempts (calls=" .. calls .. ")")
DS.AddXP(p1, 5, "Console")
local ok1, why1 = DS.Save(p1); assert(not ok1 and why1 == "loadFailed" and calls == 4, "a failed-load profile was written")
assert(DS._Autosave() == 0 and calls == 4, "autosave wrote a failed-load profile")
table.insert(out, "erroring store: 4 load attempts, profile flagged, no save attempts")

-- a fake store with UpdateAsync semantics (nil from the transform cancels)
local function fakeStore(data)
  local s = { calls = 0 }
  function s:UpdateAsync(k, fn) s.calls += 1; local new = fn(data[k]); if new ~= nil then data[k] = new end; return new end
  return s
end
local t, day = 1000000, 20261022
local function clock(ds) ds._now = function() return t end; ds._day = function() return day end end

-- 2) healthy store, old v1 profile: migrated to the current schema, lock claimed on load
local data = { u_202 = { xp = 300, visits = 4, v = 1 } }
local st = fakeStore(data); DS._SetStoreForTest(st); clock(DS)
local p2 = { UserId = 202 }
local prof2 = DS.Load(p2)
assert(prof2.level == 3 and prof2.v == DS.SchemaVersion and prof2.visits == 5 and prof2.xp == 300, "migration/visits wrong")
assert(prof2.cred == 0 and type(prof2.gear) == "table" and type(prof2.credits) == "table" and type(prof2.credLog) == "table", "schema v2 fields missing")
assert(data.u_202.lock and data.u_202.lock.id == DS.ServerId and prof2.lock == nil, "load did not claim the lock (or leaked it into the profile)")
table.insert(out, "v1 profile migrates to v" .. DS.SchemaVersion .. " (cred, gear, credits); load claims the session lock")

-- 3) XP gate
assert(DS.AddXP(p2, 5, "Console") == 5, "first console XP refused")
for i = 1, 9 do t += 1; assert(DS.AddXP(p2, 5, "Console") == 0, "console XP paid inside its cooldown") end
t += 600; assert(DS.AddXP(p2, 5, "Console") == 5, "console XP refused after the cooldown")
assert(DS.AddXP(p2, 10, "Mic") == 10, "first mic XP refused"); t += 60; assert(DS.AddXP(p2, 10, "Mic") == 0, "mic XP paid inside 2 min")
local cap = Cfg.XP.GroupDailyCap.Activity
assert(cap == 30, "Activity cap should be 30, is " .. tostring(cap))
local paid = 20
for i = 1, 20 do t += 700; paid += DS.AddXP(p2, 10, "Mic") end
assert(paid == cap, "Console+Mic daily cap should stop at " .. cap .. ", paid " .. paid)
local saves = 0; for i = 1, 8 do t += 61; saves += (DS.AddXP(p2, 10, "BeatSave") > 0) and 1 or 0 end
assert(saves == 5, "beat-save XP should pay 5 times a day, paid " .. saves)
day += 1; t += 700; assert(DS.AddXP(p2, 10, "Mic") == 10, "daily cap did not reset on a new day")
-- unknown sources pay nothing; nil is not a back door; a rule without a cooldown does not crash
local xpBefore = prof2.xp
assert(DS.AddXP(p2, 500, "Consol") == 0 and DS.AddXP(p2, 500, nil) == 0 and prof2.xp == xpBefore, "an unknown XP source paid")
Cfg.XP.Sources._NoCooldown = { xp = 1 }
assert(DS.AddXP(p2, 1, "_NoCooldown") == 1 and DS.AddXP(p2, 1, "_NoCooldown") == 1, "a rule without a cooldown failed")
Cfg.XP.Sources._NoCooldown = nil
assert(DS.GrantXP(p2, 50, "Tour") == 50 and DS.GrantXP(p2, -5, "x") == 0 and DS.GrantXP(p2, 0/0, "x") == 0, "GrantXP wrong")
table.insert(out, "XP gate: cooldowns, Console+Mic capped at 30/day, 5 paying beat saves/day, daily reset; misspelled or nil source pays 0; no-cooldown rule ok; GrantXP rejects bad amounts")

-- 4) Cred: own log and gate, spend
Cfg.Cred.Sources._Test = { max = 10, cooldown = 5, dailyMax = 2 }
assert(DS.AddCred(p2, 25, "_Test") == 10, "Cred max not applied")
assert(DS.AddCred(p2, 5, "_Test") == 0, "Cred paid inside its cooldown")
t += 6; assert(DS.AddCred(p2, 5, "_Test") == 5, "Cred refused after its cooldown")
t += 6; assert(DS.AddCred(p2, 5, "_Test") == 0, "Cred dailyMax not applied")
assert(DS.AddCred(p2, 5, "Nope") == 0, "unknown Cred source paid")
assert(prof2.cred == 15 and prof2.credLog.count._Test == 2 and (prof2.xpLog.count._Test == nil), "Cred log wrong or shared with XP")
assert(DS.SpendCred(p2, 16) == false and prof2.cred == 15, "overspend allowed")
assert(DS.SpendCred(p2, -3) == false and DS.SpendCred(p2, 0/0) == false and prof2.cred == 15, "bad spend allowed")
assert(DS.SpendCred(p2, 15) == true and prof2.cred == 0, "spend failed")
Cfg.Cred.Sources._Test = nil
table.insert(out, "Cred: own log, max/cooldown/dailyMax, unknown source 0, no overspend or negative spend")

-- 5) save: UpdateAsync with the current schema version, lock kept, private fields stripped; autosave writes changed profiles + heartbeat
prof2._scratch = true
local c0 = st.calls
assert(DS.Save(p2) and st.calls == c0 + 1, "save did not go through UpdateAsync")
local stored = data.u_202
assert(stored.v == DS.SchemaVersion and stored.updatedAt == t and stored._scratch == nil and stored.xp == prof2.xp and stored.lock.id == DS.ServerId and stored.lock.at == t, "stored profile wrong")
assert(DS._Autosave() == 0, "autosave wrote an unchanged profile")
DS.AddXP(p2, 10, "BeatSave"); t += 1; assert(DS._Autosave() == 1, "autosave did not write a changed profile")
t += 60; assert(DS._Autosave() == 0, "autosave rewrote an unchanged profile before the heartbeat")
t += Cfg.Data.LockHeartbeatSeconds; assert(DS._Autosave() == 1 and data.u_202.lock.at == t, "lock heartbeat did not refresh an unchanged profile")
assert(DS.Save(p2, true) and data.u_202.lock == nil, "release did not clear the lock")
table.insert(out, "save: v=" .. DS.SchemaVersion .. ", updatedAt, lock kept, private fields stripped; autosave writes changes and refreshes the lock; leaving releases it")

-- 6) two servers: B waits on A's fresh lock, takes over, and A can no longer write
local data2 = { u_404 = { xp = 120, v = 2, cred = 7, gear = {}, credits = {}, credLog = {} } }
local shared = fakeStore(data2)
local A, Bs = newDS(), newDS()
A._SetStoreForTest(shared); Bs._SetStoreForTest(shared); clock(A); clock(Bs)
assert(A.ServerId ~= Bs.ServerId, "server ids collide")
local pA = { UserId = 404 }
local profA = A.Load(pA)
assert(data2.u_404.lock.id == A.ServerId, "A did not lock")
A.AddXP(pA, 10, "Mic") -- A's progress after load
local c1 = shared.calls
local pB = { UserId = 404 }
local profB = Bs.Load(pB)
assert(shared.calls - c1 == 4 and profB._tookOver == true and data2.u_404.lock.id == Bs.ServerId, "B did not wait 3 times then take over (calls=" .. (shared.calls - c1) .. ")")
Bs.GrantXP(pB, 40, "Test"); t += 1; assert(Bs.Save(pB), "B could not save")
local xpB = data2.u_404.xp
local okA, whyA = A.Save(pA)
assert(not okA and whyA == "lockLost" and profA._lockLost and data2.u_404.xp == xpB and data2.u_404.lock.id == Bs.ServerId, "A overwrote B after losing the lock")
assert(A._Autosave() == 0 and A.Save(pA, true) == false and data2.u_404.lock.id == Bs.ServerId, "A kept writing or released B's lock")
table.insert(out, "two servers: B waits out A's fresh lock then takes over; A's saves, autosave and release are all refused")

-- 7) a stale lock is taken at once; a released profile loads at once
data2.u_505 = { xp = 10, v = 2, lock = { id = "ghost-server", at = t - Cfg.Data.LockStaleSeconds - 1 } }
local c2 = shared.calls
local p5 = { UserId = 505 }; local prof5 = A.Load(p5)
assert(shared.calls - c2 == 1 and prof5._tookOver == true and data2.u_505.lock.id == A.ServerId, "stale lock not taken at once")
data2.u_606 = { xp = 10, v = 2 }
local c3 = shared.calls; local p6 = { UserId = 606 }; local prof6 = A.Load(p6)
assert(shared.calls - c3 == 1 and not prof6._tookOver, "an unlocked profile did not load at once")
table.insert(out, "stale lock taken at once; unlocked profile loads in one call")

-- 9) review fixes: single-flight loads, no ghost takeovers, retried release, release beats autosave, shutdown waits
local function slowStore(data, delay, failFirst)
  local st = { calls = 0, fails = failFirst or 0 }
  function st:UpdateAsync(k, fn)
    st.calls += 1
    task.wait(delay)
    if st.fails > 0 then st.fails -= 1; error("throttled") end
    local new = fn(data[k]); if new ~= nil then data[k] = new end; return new
  end
  return st
end
do
  local S1 = newDS(); local d9 = {}; local st9 = slowStore(d9, 0.15); S1._SetStoreForTest(st9); clock(S1)
  local fp = { UserId = 901 }
  local r1, r2
  task.spawn(function() r1 = S1.GetProfile(fp) end)
  task.spawn(function() r2 = S1.GetProfile(fp) end)
  local t1 = os.clock(); while (not r1 or not r2) and os.clock() - t1 < 3 do task.wait(0.05) end
  assert(r1 and r1 == r2 and st9.calls == 1, "two loads ran for one player (calls=" .. st9.calls .. ")")
  -- a player who leaves while waiting on another server's lock never takes it over
  d9.u_902 = { xp = 5, v = 2, lock = { id = "other-server", at = t } }
  S1._lockWaits = { 0.1, 0.1, 0.1 }
  local gp = { UserId = 902 }; local rg
  task.spawn(function() rg = S1.Load(gp) end)
  task.wait(0.2); gp._left = true
  local t2 = os.clock(); while not rg and os.clock() - t2 < 3 do task.wait(0.05) end
  assert(rg and rg._detached and d9.u_902.lock.id == "other-server", "a departed player's load took the lock over")
  assert(S1.GetProfile({ UserId = 903, _left = true })._detached and d9.u_903 == nil, "loaded a profile for a player who had left")
  -- release save retries transient errors
  local d10 = {}; local st10 = slowStore(d10, 0, 0); S1._SetStoreForTest(st10); clock(S1); S1._retryDelays = { 0, 0, 0 }
  local rp = { UserId = 904 }; S1.Load(rp); S1.GrantXP(rp, 30, "Test")
  st10.fails = 2
  local okR = S1._ReleaseSave(rp)
  assert(okR and d10.u_904.lock == nil and d10.u_904.xp == 30, "release save did not retry to success")
  -- once a release starts, autosave leaves the profile alone (no re-lock)
  local d11 = {}; local st11 = slowStore(d11, 0.2); S1._SetStoreForTest(st11); clock(S1)
  local ap = { UserId = 905 }; S1.Load(ap); S1.GrantXP(ap, 10, "Test")
  local c11 = st11.calls
  task.spawn(function() S1._ReleaseSave(ap) end)
  task.wait(0.05)
  assert(S1._Autosave() == 0, "autosave wrote a profile that is being released")
  local t3 = os.clock(); while S1._Inflight() > 0 and os.clock() - t3 < 3 do task.wait(0.05) end
  assert(st11.calls == c11 + 1 and d11.u_905.lock == nil, "release was followed by a re-lock")
  -- shutdown waits for a load in flight and releases every cached profile
  local S2 = newDS(); local d12 = {}; local st12 = slowStore(d12, 0.15); S2._SetStoreForTest(st12); clock(S2)
  local q1, q2 = { UserId = 906 }, { UserId = 907 }
  S2.Load(q1); S2.GrantXP(q1, 7, "Test")
  task.spawn(function() S2.Load(q2) end)
  task.wait(0.05)
  assert(S2._Shutdown(5), "shutdown timed out")
  assert(d12.u_906 and d12.u_906.lock == nil and d12.u_906.xp == 7 and d12.u_907 and d12.u_907.lock == nil, "shutdown left a profile locked or unsaved")
  S1._SetStoreForTest(nil); S2._SetStoreForTest(nil)
end
table.insert(out, "review fixes: one load per player; a departed player never takes a lock; release retries; autosave skips a releasing profile; shutdown waits and releases all")

-- 8) new player (nothing stored) counts as a successful load
local p3 = { UserId = 303 }; local prof3 = DS.Load(p3)
assert(not prof3._loadFailed and prof3.level == 1 and prof3.visits == 1 and prof3.v == DS.SchemaVersion and data.u_303.lock.id == DS.ServerId, "new player load wrong")

-- 10) schema v3 (Money x10): a stored v2 balance is multiplied by 10 once; saving and loading again keeps it
do
  local d13 = { u_707 = { v = 2, cred = 70, xp = 0 } }
  local S3 = newDS(); S3._SetStoreForTest(fakeStore(d13)); clock(S3)
  local mp = { UserId = 707 }
  local m1 = S3.Load(mp)
  assert(m1.cred == 700, "v2 balance 70 should load as 700, got " .. tostring(m1.cred))
  assert(S3.Save(mp), "migrated profile did not save")
  S3._Forget(mp)
  local m2 = S3.Load(mp)
  assert(m2.cred == 700 and d13.u_707.v == S3.SchemaVersion, "second load multiplied again or kept the old version: cred " .. tostring(m2.cred) .. ", v " .. tostring(d13.u_707.v))
  S3._SetStoreForTest(nil)
end
table.insert(out, "v2 balance 70 migrates to 700 once; save + reload keeps 700 at v" .. DS.SchemaVersion)

-- 11) schema v4 (career): a stored v3 profile gains career and walkins tables
do
  local d14 = { u_808 = { v = 3 } }
  local S4 = newDS(); S4._SetStoreForTest(fakeStore(d14)); clock(S4)
  local c4 = S4.Load({ UserId = 808 })
  assert(c4.v == S4.SchemaVersion and type(c4.career) == "table" and c4.career.aura == 0 and type(c4.career.gates) == "table", "v3 profile did not gain a career table")
  assert(type(c4.walkins) == "table" and c4.walkins.count == 0 and type(c4.walkins.queue) == "table", "v3 profile did not gain a walkins table")
  S4._SetStoreForTest(nil)
end
table.insert(out, "v3 profile gains career and walkins tables at v" .. DS.SchemaVersion)

-- 11b) schema v5 (the career remembers): a stored v4 profile gains prof.life from the backfill, once. The step runs after
-- the career repair and after the level is recomputed, so it reads the level xp 800 earns, not the stale stored 1
do
  local d16 = { u_818 = { v = 4, xp = 800, level = 1, career = { followers = 6000, placements = 2, hits = 1, gates = { studio_two = true } }, walkins = {} } }
  local S6 = newDS(); S6._SetStoreForTest(fakeStore(d16)); clock(S6)
  local lp = { UserId = 818 }
  local l1 = S6.Load(lp)
  local life = l1.life
  assert(l1.v == 5 and S6.SchemaVersion == 5 and l1.level == 5, "v4 profile should load at v5, level 5: v " .. tostring(l1.v) .. ", level " .. tostring(l1.level))
  assert(type(life) == "table" and life.day == 1 and life.last == day and life.tier == "KNOWN", "the v4 backfill is wrong (day, last or tier)")
  assert(life.firsts.placement == 0 and life.firsts.hit == 0 and life.firsts.hall == 0 and life.firsts.buzzing == 0 and life.firsts.known == 0 and life.firsts.level5 == 0, "the v4 backfill missed a first")
  assert(#life.story == 0 and #life.disco == 0 and life.ribbons.hit == 1, "the v4 backfill should start with no lines, and the hit ribbon dated day 1")
  -- the step runs once: a later load keeps what the career has done since
  life.day = 7; life.firsts.sponsor = 6
  assert(S6.Save(lp), "the migrated profile did not save")
  S6._Forget(lp)
  local today = day
  day += 3
  local l2 = S6.Load(lp)
  day = today
  assert(l2.life.day == 7 and l2.life.last == today and l2.life.firsts.sponsor == 6 and l2.life.firsts.hit == 0, "a second load backfilled again (day " .. tostring(l2.life.day) .. ")")
  -- a career that is junk is repaired before the backfill reads it; a life that is junk is replaced whole
  d16.u_819 = { v = 4, career = "junk" }
  local l3 = S6.Load({ UserId = 819 })
  assert(type(l3.life) == "table" and l3.life.tier == "LOCAL" and next(l3.life.firsts) == nil and l3.life.last == day, "v4 with a junk career: bad life")
  d16.u_820 = { v = 5, life = 7, career = { followers = 1200, gates = {} } }
  local l4 = S6.Load({ UserId = 820 })
  assert(type(l4.life) == "table" and l4.life.day == 1 and l4.life.tier == "BUZZING" and l4.life.last == day, "a junk life was not repaired")
  S6._SetStoreForTest(nil)
end
table.insert(out, "v4 profile gains prof.life at v" .. DS.SchemaVersion .. " after the career repair and the level; once only; junk career and junk life repaired")

-- 12) a stored profile newer than this build (saved after a schema bump; this server is older): it loads, but neither
-- Save, autosave nor the leave save writes it, so its version is never lowered and no migration step runs on it twice
do
  local newer = DS.SchemaVersion + 1
  local d15 = { u_909 = { v = newer, cred = 10 } }
  local st15 = fakeStore(d15)
  local S5 = newDS(); S5._SetStoreForTest(st15); clock(S5)
  local np = { UserId = 909 }
  local n1 = S5.Load(np)
  assert(n1._newerSchema == true and n1.v == newer and n1.cred == 10, "a v" .. newer .. " profile should load flagged _newerSchema with v and cred untouched (cred " .. tostring(n1.cred) .. ", v " .. tostring(n1.v) .. ")")
  local c15 = st15.calls
  local okN, whyN = S5.Save(np)
  assert(not okN and whyN == "newerSchema" and st15.calls == c15, "Save wrote a newer-schema profile (" .. tostring(whyN) .. ")")
  S5.MarkDirty(np)
  assert(S5._Autosave() == 0 and st15.calls == c15, "autosave wrote a newer-schema profile")
  local okR, whyR = S5._ReleaseSave(np)
  assert(not okR and whyR == "newerSchema" and st15.calls == c15, "the leave save wrote a newer-schema profile (" .. tostring(whyR) .. ")")
  assert(d15.u_909.v == newer and d15.u_909.cred == 10, "the stored newer profile changed: v " .. tostring(d15.u_909.v) .. ", cred " .. tostring(d15.u_909.cred))
  -- and Save never lowers a stored version, flag or not
  S5._Forget(np)
  local n2 = S5.Load(np)
  n2._newerSchema = nil
  assert(S5.Save(np) and d15.u_909.v == newer, "Save lowered v" .. newer .. " to v" .. tostring(d15.u_909.v))
  S5._SetStoreForTest(nil)
end
table.insert(out, "a v" .. (DS.SchemaVersion + 1) .. " profile loads flagged; Save, autosave and the leave save refuse it (newerSchema); Save never lowers v")
DS._SetStoreForTest(nil); A._SetStoreForTest(nil); Bs._SetStoreForTest(nil)
return "T13 OK: " .. table.concat(out, "; ")
