-- Edit: save safety (plans/2026-11-03-save-safety.md; the Wave 2 save review's findings 3 and 5), on a fresh DataService,
-- a fake clock and fake players, through a fake store that keeps JSON as a real DataStore does (the profile and the
-- "store" never share a table) and can run the game on during its wait (s.wait, called before the transform).
-- (a) a grant made during a save's wait keeps the profile dirty, and the next autosave writes it. (b) a save is one
-- moment: a nested change and a Money change during the wait are both missing from that save, then both in the next.
-- (c) server S's queued save after T took the profile over, played and released is refused (lockLost) and T's progress
-- stays. (d) a stored v newer than ours refuses the save. (e) leaving releases only the lock and keeps the writer; a
-- reload on the same server writes a new one and saves. (f) a stored document with no writer saves and then carries
-- ours. (g) the writer never reaches the profile or ClientProfile. (h) a transform the store runs twice (as it does when the
-- key moved under it) decides on its last run: saved when nothing moved, refused when another writer came in between.
-- (i) a change made while the leave save waits is written by one more release. (j) an old session's save landing after
-- a leave and reload is refused without touching the new session (still dirty, not lockLost).
local RS, SSS = game:GetService("ReplicatedStorage"), game:GetService("ServerScriptService")
local Http = game:GetService("HttpService")
local function freshRequire(mod) local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name; local ok, r = pcall(require, c); c:Destroy(); if not ok then error(r) end; return r end
local Cfg = freshRequire(RS.OK.Config)
local function newDS()
  local DS = freshRequire(SSS.OK.Services.DataService)
  DS._SetConfigForTest(Cfg); DS._retryDelays = { 0, 0, 0 }; DS._lockWaits = { 0, 0, 0 }; DS._quiet = true
  return DS
end
local out = {}

-- UpdateAsync semantics, with the value held as JSON; s.wait (once) runs before the transform, as the game does while
-- a real store holds the request; s.retry (once) runs the transform, discards it, runs s.retry and runs it again
local function jsonStore(data)
  local s = { calls = 0 }
  function s:UpdateAsync(k, fn)
    s.calls += 1
    local w = s.wait; s.wait = nil
    if w then w() end
    local r = s.retry; s.retry = nil
    if r then fn(data[k] ~= nil and Http:JSONDecode(data[k]) or nil); r() end
    local old = data[k] ~= nil and Http:JSONDecode(data[k]) or nil
    local new = fn(old)
    if new ~= nil then data[k] = Http:JSONEncode(new) end
    return new
  end
  return s
end
local function stored(data, k) return Http:JSONDecode(data[k]) end
local function put(data, k, doc) data[k] = Http:JSONEncode(doc) end
local t, day = 2000000, 20261103
local function clock(ds) ds._now = function() return t end; ds._day = function() return day end end

-- a) a grant during the wait stays dirty
local d1 = {}
local s1 = jsonStore(d1)
local S = newDS(); S._SetStoreForTest(s1); clock(S)
local pa = { UserId = 7401 }
local pra = S.Load(pa)
assert(pra and not pra._loadFailed and not pra._detached, "the profile did not load")
assert(S.Save(pa), "the first save failed")
local cred0 = stored(d1, "u_7401").cred
s1.wait = function() S.GrantCred(pa, 100, "Test") end
t += 1
assert(S.Save(pa), "the save with a grant during its wait failed")
assert(stored(d1, "u_7401").cred == cred0, "the save took Money from after it started: " .. tostring(stored(d1, "u_7401").cred))
local n = S._Autosave()
assert(n == 1 and stored(d1, "u_7401").cred == cred0 + 100, "the grant made during the save's wait was never written (autosave wrote "
  .. n .. ", stored Money " .. tostring(stored(d1, "u_7401").cred) .. ", want " .. (cred0 + 100) .. ")")
table.insert(out, "(a) a grant during a save's wait stays dirty; the next autosave writes it")

-- b) one moment per save
local count0, cred1 = pra.walkins.count, pra.cred
s1.wait = function() pra.walkins.count = count0 + 5; S.GrantCred(pa, 50, "Test") end
t += 1
assert(S.Save(pa), "the save with changes during its wait failed")
local b = stored(d1, "u_7401")
assert(b.walkins.count == count0 and b.cred == cred1, "the stored document mixes moments: walk-ins count " .. tostring(b.walkins.count)
  .. " (want " .. count0 .. ", from before the wait), Money " .. tostring(b.cred) .. " (want " .. cred1 .. ")")
assert(S._Autosave() == 1, "the changes made during the wait were not dirty")
b = stored(d1, "u_7401")
assert(b.walkins.count == count0 + 5 and b.cred == cred1 + 50, "the next autosave missed the changes: count " .. tostring(b.walkins.count)
  .. ", Money " .. tostring(b.cred))
table.insert(out, "(b) a save is one moment: a nested change and Money during the wait are both in the next save, not this one")

-- c) a stale server never overwrites a newer save
local d2 = {}
local s2 = jsonStore(d2)
local Sv, Tv = newDS(), newDS()
Sv._SetStoreForTest(s2); Tv._SetStoreForTest(s2); clock(Sv); clock(Tv)
local pc = { UserId = 7403 }
local ps = Sv.Load(pc)
Sv.GrantCred(pc, 100, "Test"); t += 1
assert(Sv.Save(pc), "S could not save")
local pt = Tv.Load(pc) -- S's lock is fresh: T waits out its LockWaits, then takes over
assert(pt._tookOver == true and stored(d2, "u_7403").lock.id == Tv.ServerId, "T did not take the profile over")
Tv.GrantCred(pc, 900, "Test"); t += 1
assert(Tv._ReleaseSave(pc), "T's leave save failed")
local released = stored(d2, "u_7403")
assert(released.lock == nil and released.cred == ps.cred + 900, "T's release: lock " .. tostring(released.lock) .. ", Money " .. tostring(released.cred))
Sv.GrantCred(pc, 5, "Test"); t += 1
local okS, whyS = Sv.Save(pc) -- S's save, held in the store's queue until now
local after = stored(d2, "u_7403")
assert(not okS and whyS == "lockLost" and ps._lockLost == true, "S's stale save was not refused (" .. tostring(okS) .. ", " .. tostring(whyS) .. ")")
assert(after.cred == released.cred, "S rolled T's progress back: Money " .. tostring(after.cred) .. ", T left " .. released.cred)
assert(Sv._Autosave() == 0 and not Sv._ReleaseSave(pc) and stored(d2, "u_7403").cred == released.cred, "S kept writing after it lost the profile")
-- c2) the same through a leave save that reaches the transform (S has not seen the takeover yet)
local pc2 = { UserId = 7407 }
local ps2 = Sv.Load(pc2); t += 1
Tv.Load(pc2); Tv.GrantCred(pc2, 300, "Test"); t += 1
assert(Tv._ReleaseSave(pc2), "T's second leave save failed")
local t2 = stored(d2, "u_7407").cred
local okL, whyL = Sv._ReleaseSave(pc2)
assert(not okL and whyL == "lockLost" and ps2._lockLost == true and stored(d2, "u_7407").cred == t2, "S's stale leave save went through ("
  .. tostring(okL) .. ", " .. tostring(whyL) .. ", Money " .. tostring(stored(d2, "u_7407").cred) .. ", T left " .. t2 .. ")")
table.insert(out, "(c) T takes over, plays and releases; S's queued save and S's leave save are both refused (lockLost) and T's Money stays")

-- d) a newer stored version refuses the save
local pd = { UserId = 7404 }
Sv.Load(pd)
local raw = stored(d2, "u_7404"); raw.v = Sv.SchemaVersion + 1; put(d2, "u_7404", raw)
t += 1
local okD, whyD = Sv.Save(pd)
assert(not okD and whyD == "lockLost" and stored(d2, "u_7404").v == Sv.SchemaVersion + 1, "a save lowered a stored v" .. (Sv.SchemaVersion + 1)
  .. " (" .. tostring(okD) .. ", " .. tostring(whyD) .. ", stored v " .. tostring(stored(d2, "u_7404").v) .. ")")
table.insert(out, "(d) a stored v" .. (Sv.SchemaVersion + 1) .. " written after our load refuses the save")

-- e) leave and come back to the same server
local pe = { UserId = 7405 }
Sv.Load(pe)
local w1 = stored(d2, "u_7405").writer
assert(type(w1) == "string" and #w1 > 0, "the load wrote no writer: " .. tostring(w1))
assert(Sv._ReleaseSave(pe), "the leave save failed"); Sv._Forget(pe)
local left = stored(d2, "u_7405")
assert(left.lock == nil and left.writer == w1, "a release should clear only the lock: lock " .. tostring(left.lock) .. ", writer " .. tostring(left.writer))
local pre2 = Sv.Load(pe)
local w2 = stored(d2, "u_7405").writer
assert(type(w2) == "string" and w2 ~= w1, "the reload kept the old writer")
Sv.GrantCred(pe, 10, "Test"); t += 1
assert(Sv.Save(pe) and stored(d2, "u_7405").cred == pre2.cred and stored(d2, "u_7405").visits == 2, "the reloaded profile did not save")
table.insert(out, "(e) a release keeps the writer; a reload on the same server writes a new one and saves")

-- f) a document with no writer saves, then carries ours
local pf = { UserId = 7406 }
local prf = Sv.Load(pf)
local wf = stored(d2, "u_7406").writer
assert(type(wf) == "string", "the load wrote no writer")
raw = stored(d2, "u_7406"); raw.writer = nil; put(d2, "u_7406", raw)
Sv.GrantCred(pf, 10, "Test"); t += 1
assert(Sv.Save(pf), "a stored document with no writer refused the save")
assert(stored(d2, "u_7406").writer == wf and stored(d2, "u_7406").cred == prf.cred, "the save did not write our writer back")
table.insert(out, "(f) a stored document with no writer saves and then carries ours")

-- g) the writer stays server side
for k in pairs(prf) do assert(k ~= "writer" and k ~= "_writer" and k ~= "lock", "the profile carries " .. k) end
local cp = Sv.ClientProfile(prf)
assert(cp.writer == nil and cp._writer == nil, "ClientProfile carries the writer")
table.insert(out, "(g) the writer is in the store only, never in the profile or ClientProfile")

-- h) a transform run twice
local ph = { UserId = 7408 }
local prh = Sv.Load(ph)
Sv.GrantCred(ph, 20, "Test"); t += 1
s2.retry = function() end
assert(Sv.Save(ph) and stored(d2, "u_7408").cred == prh.cred, "a save whose transform ran twice did not store")
raw = nil
s2.retry = function() raw = stored(d2, "u_7408"); raw.writer = "another-load"; put(d2, "u_7408", raw) end
Sv.GrantCred(ph, 20, "Test"); t += 1
local okH, whyH = Sv.Save(ph)
assert(not okH and whyH == "lockLost" and stored(d2, "u_7408").writer == "another-load", "the second run of the transform did not see the new writer ("
  .. tostring(okH) .. ", " .. tostring(whyH) .. ")")
table.insert(out, "(h) a transform run twice saves when nothing moved and refuses when another writer came in between")

-- i) a change during the leave save
local pi = { UserId = 7409 }
local pri = Sv.Load(pi); t += 1
s2.wait = function() Sv.GrantCred(pi, 70, "Test") end
assert(Sv._ReleaseSave(pi), "the leave save failed")
assert(stored(d2, "u_7409").cred == pri.cred and stored(d2, "u_7409").lock == nil, "the Money granted during the leave save was lost: stored "
  .. tostring(stored(d2, "u_7409").cred) .. ", want " .. pri.cred)
Sv._Forget(pi)
table.insert(out, "(i) a change while the leave save waits goes out with one more release")

-- j) an old session's save that lands after a leave and reload
local pj = { UserId = 7410 }
Sv.Load(pj); t += 1
local newer
s2.wait = function() Sv._Forget(pj); newer = Sv.Load(pj); Sv.GrantCred(pj, 40, "Test") end
local okJ = Sv.Save(pj) -- the old session's save, finished by the store after the reload
assert(not okJ and newer and not newer._lockLost, "the old session's save marked the new one lockLost, or went through")
assert(Sv._Autosave() == 1 and stored(d2, "u_7410").cred == newer.cred, "the old session's late save cleared the new session's dirty flag")
table.insert(out, "(j) an old session's late save is refused and leaves the new session dirty and saving")

S._SetStoreForTest(nil); Sv._SetStoreForTest(nil); Tv._SetStoreForTest(nil)
return "T74 OK: " .. table.concat(out, "; ")
