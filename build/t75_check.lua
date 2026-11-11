-- Edit: Wave 3 Task 2, the explainers' save (design 4.5; Review Focus 4). t70's seam: a fresh DataService, a fake clock
-- and fake players, on a fake store that keeps JSON as a real DataStore does; no Init runs.
-- (a) the schema stays 5. (b) prof.hints, the one new top-level table, comes from DataService.migrate's repair line: a
-- v5 profile without hints, a v5 profile whose hints is junk, and a v4 profile each load with hints = {} (an empty
-- table); a stored v5 hints is left alone. (c) a v5 profile with hints = { aura = 3 } survives HttpService JSON key for
-- key, and a real save and reload (with a term added after the load, so the save carries the change). (d)
-- ClientProfile has no hints (the original keeps them; life stays out as before).
local RS, SSS = game:GetService("ReplicatedStorage"), game:GetService("ServerScriptService")
local Http = game:GetService("HttpService")
local function freshRequire(mod) local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name; local ok, r = pcall(require, c); c:Destroy(); if not ok then error(r) end; return r end
local Cfg = freshRequire(RS.OK.Config)
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
  path = path or "hints"
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
local function empty(t) return type(t) == "table" and next(t) == nil end

local t, day = 1000000, 20261105
local data = {}
local DS = freshRequire(SSS.OK.Services.DataService)
DS._SetConfigForTest(Cfg); DS._retryDelays = { 0, 0, 0 }; DS._lockWaits = { 0, 0, 0 }; DS._quiet = true
DS._now = function() return t end; DS._day = function() return day end
DS._SetStoreForTest(jsonStore(data))
local function seed(uid, prof) data["u_" .. uid] = Http:JSONEncode(prof) end

-- a) the schema stays 5 (prof.hints needs no bump)
assert(DS.SchemaVersion == 5, "SchemaVersion should stay 5, is " .. tostring(DS.SchemaVersion))
table.insert(out, "(a) SchemaVersion 5")

-- b) the repair line
seed(7501, { v = 5, xp = 0, level = 1, career = { aura = 0, followers = 0, gates = {} },
  life = { day = 4, last = 20261101, story = {}, disco = {}, firsts = {}, tier = "LOCAL", ribbons = {} } })
local b1 = DS.Load({ UserId = 7501, Name = "T75b1" })
assert(b1.v == 5, "a v5 profile should load at v5, is v" .. tostring(b1.v))
assert(empty(b1.hints), "a v5 profile without hints should get hints = {} (got " .. typeof(b1.hints) .. ")"
  .. " (before the Task 2 sync of Services/DataService: the expected red)")
assert(b1.life.day == 4, "the repair touched the life")
seed(7502, { v = 5, hints = "junk", career = { aura = 0, followers = 0, gates = {} } })
local b2 = DS.Load({ UserId = 7502, Name = "T75b2" })
assert(empty(b2.hints), "a v5 profile whose hints is not a table should get hints = {}")
seed(7503, { v = 4, xp = 0, career = { aura = 0, followers = 0, gates = {} }, walkins = { day = 0, today = 0, count = 0, queue = {}, seen = {}, last = {} } })
local b3 = DS.Load({ UserId = 7503, Name = "T75b3" })
assert(b3.v == 5 and type(b3.life) == "table" and empty(b3.hints), "a v4 profile should reach v5 with a life and hints = {}")
seed(7504, { v = 5, hints = { placement = 2, fire = 0 }, career = { aura = 0, followers = 0, gates = {} } })
local b4 = DS.Load({ UserId = 7504, Name = "T75b4" })
assertSame(b4.hints, { placement = 2, fire = 0 }, "a stored v5 hints after load")
table.insert(out, "(b) no hints, junk hints and a v4 profile load with hints = {}; a stored hints is left alone")

-- c) through JSON and a real save and reload
local pc = { UserId = 7510, Name = "T75c" }
seed(7510, { v = 5, xp = 0, level = 1, cred = 0, hints = { aura = 3 }, career = { aura = 0, followers = 0, gates = {} } })
local c = DS.Load(pc)
assertSame(c.hints, { aura = 3 }, "hints after load")
assertSame(Http:JSONDecode(Http:JSONEncode({ aura = 3 })), { aura = 3 }, "{ aura = 3 } through JSONEncode/JSONDecode")
c.hints.followers = 4
DS.MarkDirty(pc)
assert(DS.Save(pc), "the profile with hints did not save")
local s = stored(data, "u_7510")
assert(s.v == 5, "the stored profile should be v5, is v" .. tostring(s.v))
assertSame(s.hints, { aura = 3, followers = 4 }, "the stored hints")
for k, v in pairs(s.hints) do assert(type(k) == "string" and type(v) == "number", "a stored hints entry is not term = day: " .. tostring(k)) end
DS._Forget(pc)
local c2 = DS.Load(pc)
assertSame(c2.hints, { aura = 3, followers = 4 }, "the hints after save and reload")
table.insert(out, "(c) hints = { aura = 3 } survives JSON; a term added after load is stored and reloads key for key")

-- d) ClientProfile has no hints
local cp = DS.ClientProfile(c2)
assert(cp.hints == nil, "ClientProfile carries hints (before the Task 2 sync: the expected red)")
assert(cp.life == nil, "ClientProfile carries the life")
assert(cp.xp == c2.xp and cp.career == c2.career, "ClientProfile dropped more than hints and life")
assertSame(c2.hints, { aura = 3, followers = 4 }, "the original's hints after ClientProfile")
table.insert(out, "(d) ClientProfile drops hints (and life); the original keeps them")

DS._SetStoreForTest(nil)
return "T75 OK: " .. table.concat(out, "; ")
