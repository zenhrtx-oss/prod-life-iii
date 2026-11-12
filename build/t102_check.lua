-- Edit: the Your Rooms plan, Task 3 (saving your rooms, spec 4.4; Review Focus 3). t70's / t75's seam: a fresh
-- DataService, a fake clock and fake players on a fake store that keeps JSON as a real DataStore does, plus Systems/Rooms'
-- own seams (_SetConfigForTest, _SetCtxForTest with { Data, Gear }, _State = the state() a plot's build reads). No Init runs.
-- prof.career.home = { v = 1, door, items = { [kind] = { entry, ... } } } is Rooms' alone to write (schema stays v5).
-- (a) a new player (no record) and a stored bare v5 profile load with 8 career keys and no home; Rooms' state defaults it to
-- { v = 1, door = "friends", items = {} }, saves it, and a second read keeps the same table. (b) a stored home with 2 good
-- bedroom items and 1 junk one survives HttpService JSON key for key; state() drops the junk and names it, writes the repair
-- back, a real save leaves it out of the stored JSON, and a reload brings back 2 items and drops nothing. (b2) every kind of
-- junk drops quietly (a string coordinate, out of bounds, overlapping, an unknown id, over the limit, a bad turn, a
-- non-table entry) and the good ones keep their order. (c) ruling R8: items under a room whose gate (career.gates.home_studio)
-- is missing stay in the save, reported as unbuilt "unowned" and never dropped; with the gate set they are buildable (nothing
-- unbuilt, nothing dropped, the same entries), and taking the gate away keeps them again. (c2) locked items (a first, a gear
-- item through the Gear system, a fame tier from prof.life) stay unbuilt until each unlock is held; a Gear that throws leaves its
-- item kept and unbuilt, never deleted. (d) ClientProfile keeps career.home and leaves prof.life and prof.hints out. (e) schema
-- 5, stored at 5. (f) a Career Reset (prof.career = CareerRules.Defaults()) makes the next state() default it again. (g) a junk
-- home (a string, a number, a bad door and items, an unknown kind) reads as the defaults, the junk named in `dropped`; a
-- throwaway profile (a player who left) gets the defaults and nothing is stored.
-- No long walk here (the largest list is 13 entries), so nothing waits. Marker "T102 OK".
-- The expected red, before the Task 3 sync of Systems/Rooms: "Systems/Rooms has no _SetCtxForTest / _State".
local RS, SSS = game:GetService("ReplicatedStorage"), game:GetService("ServerScriptService")
local Http = game:GetService("HttpService")
local function freshRequire(mod) local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name; local ok, r = pcall(require, c); c:Destroy(); if not ok then error(r) end; return r end
local Cfg = freshRequire(RS.OK.Config)
local CareerRules = freshRequire(RS.OK.Modules.CareerRules)
local RoomRules = require(RS.OK.Modules.RoomRules) -- the same cached modules Systems/Rooms requires
local Catalog = require(RS.OK.Data.RoomCatalog)
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
  path = path or "home"
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
local function dump(x)
  local ok, s = pcall(function() return Http:JSONEncode(x) end)
  return ok and s or tostring(x)
end
local function assertSame(got, want, what)
  local ok, at = same(got, want)
  assert(ok, what .. " differs at " .. tostring(at) .. ": want " .. dump(want) .. ", got " .. dump(got))
end
local function eq(what, got, want) assert(got == want, what .. ": want " .. tostring(want) .. ", got " .. tostring(got)) end
local function keys(t) local n = 0; for _ in pairs(t) do n += 1 end; return n end
-- "kind:index:id:reason" per entry of Repair's dropped / unbuilt lists (a field entry names its field in place of the kind)
local function names(list)
  local t = {}
  for _, e in ipairs(list) do
    table.insert(t, string.format("%s:%s:%s:%s", tostring(e.kind or e.field), tostring(e.index), tostring(e.id), tostring(e.reason)))
  end
  return table.concat(t, " ")
end

local t, day = 1000000, 20261112
local data = {}
local DS = freshRequire(SSS.OK.Services.DataService)
DS._SetConfigForTest(Cfg); DS._retryDelays = { 0, 0, 0 }; DS._lockWaits = { 0, 0, 0 }; DS._quiet = true
DS._now = function() return t end; DS._day = function() return day end
DS._SetStoreForTest(jsonStore(data))
local Gear = freshRequire(RS.OK.Systems.Gear)
Gear._SetConfigForTest(Cfg); Gear._SetCtxForTest({ Data = DS })
local Rooms = freshRequire(RS.OK.Systems.Rooms)
assert(type(Rooms._SetCtxForTest) == "function" and type(Rooms._SetConfigForTest) == "function" and type(Rooms._State) == "function",
  "Systems/Rooms has no _SetCtxForTest / _SetConfigForTest / _State (before the Task 3 sync of Systems/Rooms: the expected red)")
Rooms._SetConfigForTest(Cfg); Rooms._SetCtxForTest({ Data = DS, Gear = Gear })
local DEFAULT = { v = 1, door = "friends", items = {} }

local function seed(uid, prof) data["u_" .. uid] = Http:JSONEncode(prof) end
-- the 8 keys schema v4 made, plus whatever `extra` adds
local function career(extra)
  local c = { aura = 0, followers = 0, placements = 0, hits = 0, sponsors = 0, showSponsor = true, gates = {}, careerLog = {} }
  for k, v in pairs(extra or {}) do c[k] = v end
  return c
end
local function life() return { day = 4, last = day, story = {}, disco = {}, firsts = {}, tier = "LOCAL", ribbons = {} } end
-- fixtures, built fresh each time. Bedroom: the rug (2x2) and the plant (1x1) on the free floor at the west side; home: a
-- rug, a poster on slot 1 and the closet. The premise check below keeps them honest against the live Config.Rooms.
local function rug() return { id = "rug", x = -6, z = -7, r = 0 } end
local function plant() return { id = "plant", x = -4, z = -3, r = 0 } end
local function junk() return { id = "grand_piano", x = 0, z = 0, r = 0 } end
local function homeItems()
  return { { id = "rug", x = -4, z = -3, r = 0 }, { id = "poster", slot = 1, w = 2, c = 3, s = 1 }, { id = "closet", x = -4, z = 5, r = 0 } }
end
local function lockedItems() -- beanbag (a first), tape machine (gear), floor lamp (a fame tier)
  return { rug(), plant(), { id = "beanbag", x = -6, z = -5, r = 0 }, { id = "tape_machine", x = -6, z = -3, r = 0 },
    { id = "floor_lamp", x = -4, z = -2, r = 0 } }
end
do
  local all = RoomRules.Unlocked(Catalog, { gear = { kit_tape = true }, firsts = { delivery = 0 }, tier = 2, rooms = { "bedroom", "home" } }, Cfg.Life.Tiers)
  local home = { v = 1, door = "friends", items = { bedroom = lockedItems(), home = homeItems() } }
  local h, dropped, unbuilt = RoomRules.Repair(home, { "bedroom", "home" }, Cfg.Rooms, Catalog, all)
  assert(#dropped == 0 and #unbuilt == 0, "fixture premise: every fixture entry should fit the live Config.Rooms with everything owned and unlocked: dropped "
    .. names(dropped) .. ", unbuilt " .. names(unbuilt) .. " (Config.Rooms' grid or keep areas moved: re-pick the cells)")
  assert(#h.items.bedroom == 5 and #h.items.home == 3, "fixture premise: the repaired fixture lost entries")
end

-- e) the schema stays 5
eq("(e) SchemaVersion", DS.SchemaVersion, 5)
table.insert(out, "(e) SchemaVersion 5")

-- a) bare profiles: 8 career keys, no home; state defaults it
local pa = { UserId = 10201, Name = "T102a" }
local a = DS.Load(pa)
eq("(a) a new player's schema", a.v, 5)
eq("(a) career keys after a bare load", keys(a.career), 8)
assert(a.career.home == nil, "(a) DataService wrote career.home on load: Rooms must be its only writer, lazily")
local ha = Rooms._State(pa)
assertSame(ha, DEFAULT, "(a) the defaulted home")
assert(a.career.home == ha, "(a) state() should write the defaulted home into prof.career (so it is saved)")
eq("(a) career keys after state()", keys(a.career), 9)
assert(Rooms._State(pa) == ha, "(a) a second state() replaced a clean home table; it should keep it")
assert(DS.Save(pa), "(a) the profile with a home did not save")
assertSame(stored(data, "u_10201").career.home, DEFAULT, "(a) the stored home")
seed(10202, { v = 5, xp = 0, level = 1, career = career(), life = life() })
local pa2 = { UserId = 10202, Name = "T102a2" }
local a2 = DS.Load(pa2)
eq("(a) a stored bare v5 profile's career keys", keys(a2.career), 8)
assert(a2.career.home == nil, "(a) a stored v5 profile gained a home on load")
assertSame((Rooms._State(pa2)), DEFAULT, "(a) the stored bare profile's defaulted home")
table.insert(out, "(a) a new player and a stored bare v5 profile load with 8 career keys and no home; state() defaults it, saves it, keeps the table")

-- b) 2 good items and 1 junk one through JSON, a repair, a real save and a reload
local function seedB() return { v = 1, door = "open", items = { bedroom = { rug(), junk(), plant() } } } end
assertSame(Http:JSONDecode(Http:JSONEncode(seedB())), seedB(), "(b) the seed through HttpService JSON")
seed(10203, { v = 5, xp = 0, level = 1, career = career({ home = seedB() }), life = life() })
local pb = { UserId = 10203, Name = "T102b" }
local b = DS.Load(pb)
assertSame(b.career.home, seedB(), "(b) the stored home after load, before any state()")
local hb, droppedB, unbuiltB = Rooms._State(pb)
eq("(b) dropped", names(droppedB), "bedroom:2:grand_piano:unknown")
eq("(b) unbuilt", names(unbuiltB), "")
assertSame(hb, { v = 1, door = "open", items = { bedroom = { rug(), plant() } } }, "(b) the repaired home")
assert(b.career.home == hb, "(b) the repair was not written back into prof.career")
assert(DS.Save(pb), "(b) the repaired profile did not save")
local sb = stored(data, "u_10203")
assertSame(sb.career.home, hb, "(b) the stored home after the repair")
assert(not string.find(data["u_10203"], "grand_piano", 1, true), "(b) the dropped junk is still in the stored JSON")
DS._Forget(pb)
local b2 = DS.Load(pb)
assertSame(b2.career.home, hb, "(b) the reloaded home, before any state(): the junk must not return")
local _, droppedB2 = Rooms._State(pb)
eq("(b) dropped after the reload", names(droppedB2), "")
table.insert(out, "(b) 2 good + 1 junk survives JSON; the junk is dropped and named, written back, saved without it, and gone after a reload")

-- b2) every kind of junk drops quietly, the good entries keep their order
local function junkList()
  return {
    rug(),                                           -- 1 kept
    { id = "plant", x = "3", z = 1, r = 0 },         -- 2 malformed: a string coordinate
    { id = "plant", x = 40, z = 40, r = 0 },         -- 3 bounds
    { id = "plant", x = -6, z = -7, r = 0 },         -- 4 overlap with the rug
    junk(),                                          -- 5 unknown
    plant(),                                         -- 6 kept
    { id = "plant", x = -6, z = -5, r = 0 },         -- 7 kept
    { id = "plant", x = -5, z = -5, r = 0 },         -- 8 kept
    { id = "plant", x = -6, z = -4, r = 0 },         -- 9 kept
    { id = "plant", x = -5, z = -4, r = 0 },         -- 10 kept: the bedroom's sixth
    { id = "plant", x = -4, z = -4, r = 0 },         -- 11 limit (6)
    { id = "plant", x = -4, z = -2, r = 7 },         -- 12 rot
    "junk string",                                   -- 13 malformed: not a table
  }
end
seed(10204, { v = 5, xp = 0, level = 1, career = career({ home = { v = 1, door = "friends", items = { bedroom = junkList() } } }), life = life() })
local pb2 = { UserId = 10204, Name = "T102b2" }
local bb = DS.Load(pb2)
assertSame(bb.career.home, { v = 1, door = "friends", items = { bedroom = junkList() } }, "(b2) the junk list through JSON")
local hbb, droppedBB, unbuiltBB = Rooms._State(pb2)
eq("(b2) dropped", names(droppedBB), "bedroom:2:plant:malformed bedroom:3:plant:bounds bedroom:4:plant:overlap bedroom:5:grand_piano:unknown"
  .. " bedroom:11:plant:limit bedroom:12:plant:rot bedroom:13:nil:malformed")
eq("(b2) unbuilt", names(unbuiltBB), "")
local list = junkList()
assertSame(hbb.items.bedroom, { list[1], list[6], list[7], list[8], list[9], list[10] }, "(b2) the kept entries, in their order")
table.insert(out, "(b2) a string coordinate, out of bounds, overlap, an unknown id, over the limit, a bad turn and a non-table entry all drop (named); the six good ones stay")

-- c) ruling R8: items under a room whose gate is missing stay, unbuilt; the gate makes them buildable
local function seedC() return { v = 1, door = "friends", items = { bedroom = { rug() }, home = homeItems() } } end
seed(10205, { v = 5, xp = 0, level = 1, career = career({ home = seedC() }), life = life() })
local pc = { UserId = 10205, Name = "T102c" }
local c = DS.Load(pc)
local hc, droppedC, unbuiltC, ownedC = Rooms._State(pc)
eq("(c) the kinds owned without the gate", table.concat(ownedC, ","), "bedroom")
eq("(c) dropped (R8: kept, not dropped)", names(droppedC), "")
eq("(c) unbuilt", names(unbuiltC), "home:1:rug:unowned home:2:poster:unowned home:3:closet:unowned")
assertSame(hc, seedC(), "(c) the home with its unowned room's items kept")
assert(c.career.home == hc and #c.career.home.items.home == 3, "(c) the unowned room's items are not in prof.career.home")
assert(DS.Save(pc), "(c) the profile did not save")
DS._Forget(pc)
local c2 = DS.Load(pc)
assertSame(c2.career.home, seedC(), "(c) after a save and reload (a poster entry through JSON)")
c2.career.gates.home_studio = true -- Career.Unlock is the real writer; this is its effect
local hc2, droppedC2, unbuiltC2, ownedC2 = Rooms._State(pc)
eq("(c) the kinds owned with the gate", table.concat(ownedC2, ","), "bedroom,home")
eq("(c) dropped with the gate", names(droppedC2), "")
eq("(c) unbuilt with the gate", names(unbuiltC2), "")
assertSame(hc2, seedC(), "(c) the same entries, now buildable")
c2.career.gates.home_studio = nil
local _, droppedC3, unbuiltC3 = Rooms._State(pc)
eq("(c) dropped after the gate goes", names(droppedC3), "")
eq("(c) unbuilt after the gate goes", names(unbuiltC3), "home:1:rug:unowned home:2:poster:unowned home:3:closet:unowned")
assertSame(c2.career.home, seedC(), "(c) the home after the gate went (kept, not wiped)")
table.insert(out, "(c) R8: home items without career.gates.home_studio stay in the save as unbuilt 'unowned' (never dropped), buildable once it is set, kept again when it goes")

-- c2) locked items stay unbuilt until each unlock is held; a Gear that throws deletes nothing
local function seedC2() return { v = 1, door = "friends", items = { bedroom = lockedItems() } } end
seed(10206, { v = 5, xp = 0, level = 1, career = career({ home = seedC2() }), life = life() })
local pl = { UserId = 10206, Name = "T102c2" }
local l = DS.Load(pl)
local hl, droppedL, unbuiltL = Rooms._State(pl)
eq("(c2) dropped", names(droppedL), "")
eq("(c2) unbuilt with nothing unlocked", names(unbuiltL), "bedroom:3:beanbag:locked bedroom:4:tape_machine:locked bedroom:5:floor_lamp:locked")
assertSame(hl, seedC2(), "(c2) the locked items stay in the home")
l.life.firsts.delivery = 0 -- a backfilled first counts
eq("(c2) unbuilt after the first", names(select(3, Rooms._State(pl))), "bedroom:4:tape_machine:locked bedroom:5:floor_lamp:locked")
l.gear = l.gear or {}
l.gear.kit_tape = true
eq("(c2) unbuilt after the gear", names(select(3, Rooms._State(pl))), "bedroom:5:floor_lamp:locked")
l.life.tier = "BUZZING"
local hl2, droppedL2, unbuiltL2 = Rooms._State(pl)
eq("(c2) unbuilt after the fame tier", names(unbuiltL2), "")
eq("(c2) dropped after the fame tier", names(droppedL2), "")
assertSame(hl2, seedC2(), "(c2) every item buildable and kept")
-- a Gear that throws (not started yet on an early join): the gear item is kept and unbuilt, never dropped
Rooms._SetCtxForTest({ Data = DS, Gear = { Owns = function() error("gear not started") end } })
local hl3, droppedL3, unbuiltL3 = Rooms._State(pl)
eq("(c2) dropped with a Gear that throws", names(droppedL3), "")
eq("(c2) unbuilt with a Gear that throws", names(unbuiltL3), "bedroom:4:tape_machine:locked")
assertSame(hl3, seedC2(), "(c2) the home with a Gear that throws")
Rooms._SetCtxForTest({ Data = DS, Gear = Gear })
eq("(c2) unbuilt once Gear answers again", names(select(3, Rooms._State(pl))), "")
table.insert(out, "(c2) locked items (a first, gear, a fame tier) stay in the save, unbuilt until held; a Gear that throws keeps its item, unbuilt")

-- d) ClientProfile keeps career.home; life and hints stay out
local cp = DS.ClientProfile(b2)
assert(cp.career == b2.career and (same(cp.career.home, hb)), "(d) ClientProfile lost career.home or changed career")
assert(cp.life == nil, "(d) ClientProfile carries the life")
assert(cp.hints == nil, "(d) ClientProfile carries the hints")
assert(type(b2.life) == "table" and type(b2.hints) == "table", "(d) the original lost its life or hints")
table.insert(out, "(d) ClientProfile keeps career.home; prof.life and prof.hints stay out, the original keeps them")

-- f) a Career Reset replaces prof.career: the next state() defaults the home again
assert(#b2.career.home.items.bedroom == 2, "(f) premise: the profile should hold 2 bedroom items before the reset")
b2.career = CareerRules.Defaults() -- what _StudioCareerHook's Reset does
assert(b2.career.home == nil, "(f) CareerRules.Defaults() carries a home")
local hf = Rooms._State(pb)
assertSame(hf, DEFAULT, "(f) the home after a Career Reset")
assert(b2.career.home == hf, "(f) the defaulted home was not written back")
table.insert(out, "(f) after a Career Reset (prof.career = Defaults()) the next state() defaults the home again")

-- g) a junk home reads as the defaults; a throwaway profile gets them and stores nothing
local junkHomes = {
  { "a string", "junk", "home:nil:nil:malformed" },
  { "a number", 42, "home:nil:nil:malformed" },
  { "a bad door and items", { v = 1, door = "wide", items = "x" }, "door:nil:nil:malformed items:nil:nil:malformed" },
  { "an unknown kind", { v = 1, door = "locked", items = { attic = { rug() } } }, "attic:nil:nil:kind" },
}
local pg = { UserId = 10207, Name = "T102g" }
local g = DS.Load(pg)
for _, case in ipairs(junkHomes) do
  g.career.home = case[2]
  local hg, droppedG = Rooms._State(pg)
  local want = case[1] == "an unknown kind" and { v = 1, door = "locked", items = {} } or DEFAULT
  assertSame(hg, want, "(g) " .. case[1] .. " read as")
  eq("(g) dropped for " .. case[1], names(droppedG), case[3])
  assert(g.career.home == hg, "(g) the repaired home for " .. case[1] .. " was not written back")
end
local gone = { UserId = 10208, Name = "T102gone", _left = true }
local hgone, droppedGone = Rooms._State(gone)
assertSame(hgone, DEFAULT, "(g) a throwaway profile's home")
eq("(g) a throwaway profile drops nothing", #droppedGone, 0)
assert(data["u_10208"] == nil, "(g) a throwaway profile left a stored record")
table.insert(out, "(g) a junk home (a string, a number, a bad door and items, an unknown kind) reads as the defaults, the junk named; a throwaway profile stores nothing")

DS._SetStoreForTest(nil)
return "T102 OK: " .. table.concat(out, "; ")
