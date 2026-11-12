-- CLI spec for Modules/RoomRules and Data/RoomCatalog (the Your Rooms plan, Task 1): plot origins and claims, owned
-- rooms, the room boxes, item cells, Fits, Repair (ruling R8: drop the malformed, unknown, out-of-bounds, overlapping
-- and over-limit; keep locked items and items in rooms you don't own, unbuilt), the save's size, unlocks, plaques,
-- speaker tiers, door access and modes, poster designs, Config.Rooms' own checks and the launch catalog's recipes.
-- Run: sh tools/spec.sh room_rules
local R = require("../src/ReplicatedStorage/OK/Modules/RoomRules")
local CAT = require("../src/ReplicatedStorage/OK/Data/RoomCatalog")
local L = require("../src/ReplicatedStorage/OK/Modules/VisitorLooks")

-- a literal copy of Config.Rooms (src/ReplicatedStorage/OK/Config.lua); Task 2's t100 check pins it to live Config
local ROOMS = {
  Slots = 12, PlotOrigin = { 6000, 0, -2000 }, PlotCols = 4, PlotSpacing = 2000,
  Hall = { 3000, 0, 0 }, -- the shared building's hall origin (build/19_rooms.lua builds it there; preflight m3: fixed)
  Template = "Env_bedroom_starter", PlayCooldown = 1, Edit = { burst = 5, every = 0.2 }, ItemParts = 12,
  Landing = { length = 110, width = 8 }, -- plot-local x 0..110, z 0..8; its front door at x 0
  DoorModes = { "open", "friends", "locked" }, DoorDefault = "friends",
  Kinds = { -- ladder order
    bedroom = { order = 1, at = { 10, -8 }, size = { 12.36, 14.83 }, limit = 6, plaques = 3, posters = 0, booth = false,
      grid = { { -1, -0.5, 2, 2 }, { 3, 0.5, 5.8, 3 }, { -6, -7, -3, -1 } },
      keep = { { 0.6, 1.8, 2.6, 3.8 },                                            -- Spawn (its 2 x 2 plate)
        { 1.0, -1.5, 2.9, 1.0 }, { 1.7, 1.0, 3.7, 3.0 }, { 2.4, 3.0, 4.7, 6.2 },  -- Entrance -> VisitorSpot, 1.2 wide
        { -1.2, -0.5, 0.7, 1.5 } },                                               -- CritterSpot (the pigeon, turned)
      anchors = { Entrance = { 4.0849, 0, 5.5897, 0, -1 }, VisitorSpot = { 1.6014, 0, -0.7986, -0.5764, -0.8172 },
        CritterSpot = { -0.2027, 0, 0.6081, 0.6332, 0.774 },
        Plaque_1 = { 6.1784, 5.3919, -4.3986, -1, 0 }, Plaque_2 = { 6.1784, 5.3919, -2.2014, -1, 0 },
        Plaque_3 = { 6.1784, 5.3919, 0, -1, 0 },
        Desk_Speaker_L = { -2.2297, 3, -6.8059, 0, 1 }, Desk_Speaker_R = { 1.0135, 3, -6.8059, 0, 1 } } },
    -- home and real: Task 2's code-built stand-ins (Modules/RoomBuild): door on the south wall's east end, desk on the north
    -- wall, booth in the north-west corner; first guesses until the user's imports land (their free floor goes here then)
    home = { order = 2, gate = "home_studio", at = { 40, -10.6 }, size = { 24, 20 }, limit = 16, plaques = 6, posters = 4, booth = true,
      grid = { { -5, -4, 5, 9 }, { 5, -9, 11, 4 }, { -11, -2, -5, 9 } },
      keep = { { 5, 5.5, 7, 7.5 },                                                -- Spawn (its 2 x 2 plate)
        { 5.4, 3.8, 8.6, 9.1 }, { 3.4, -0.2, 6.6, 5.1 }, { 1.4, -4.2, 4.6, 1.0 },  -- Entrance -> VisitorSpot
        { -2.5, 1, -0.5, 3 },                                                      -- CritterSpot
        { 6, 8.4, 10, 10 } },                                                      -- just inside the door
      anchors = { Entrance = { 8, 0, 8.5, 0, -1 }, VisitorSpot = { 2, 0, -3.6, -0.5764, -0.8172 },
        CritterSpot = { -1.5, 0, 2, 0.6332, 0.774 },
        Desk_Speaker_L = { -1.6, 3, -9.3, 0, 1 }, Desk_Speaker_R = { 1.6, 3, -9.3, 0, 1 },
        Plaque_1 = { 11.9, 5.4, -7.5, -1, 0 }, Plaque_2 = { 11.9, 5.4, -5, -1, 0 }, Plaque_3 = { 11.9, 5.4, -2.5, -1, 0 },
        Plaque_4 = { 11.9, 5.4, 0, -1, 0 }, Plaque_5 = { 11.9, 5.4, 2.5, -1, 0 }, Plaque_6 = { 11.9, 5.4, 5, -1, 0 },
        Poster_1 = { -11.9, 5.5, -6, 1, 0 }, Poster_2 = { -11.9, 5.5, -2, 1, 0 }, Poster_3 = { -11.9, 5.5, 2, 1, 0 },
        Poster_4 = { -11.9, 5.5, 6, 1, 0 },
        BoothSpot = { -8.5, 0, -6.5, 0, 1 }, BoothCam = { -8.5, 5, -1.5, 0, -1 } } },
    real = { order = 3, gate = "real_studio", at = { 85, -14.6 }, size = { 36, 28 }, limit = 24, plaques = 10, posters = 6, booth = true,
      grid = { { -8, -7, 8, 12 }, { 8, -12, 17, 8 }, { -17, -4, -8, 13 } },
      keep = { { 11, 9, 13, 11 },                                                 -- Spawn (its 2 x 2 plate)
        { 9.4, 5.2, 14.6, 13.1 }, { 5.4, -1.5, 10.6, 6.4 }, { 1.4, -8.2, 6.6, -0.3 }, -- Entrance -> VisitorSpot
        { -3, 2, -1, 4 },                                                           -- CritterSpot
        { 12, 12.4, 16, 14 } },                                                     -- just inside the door
      anchors = { Entrance = { 14, 0, 12.5, 0, -1 }, VisitorSpot = { 2, 0, -7.6, -0.5764, -0.8172 },
        CritterSpot = { -2, 0, 3, 0.6332, 0.774 },
        Desk_Speaker_L = { -2.1, 3, -13.4, 0, 1 }, Desk_Speaker_R = { 2.1, 3, -13.4, 0, 1 },
        Plaque_1 = { 17.9, 5.4, -11.25, -1, 0 }, Plaque_2 = { 17.9, 5.4, -8.75, -1, 0 }, Plaque_3 = { 17.9, 5.4, -6.25, -1, 0 },
        Plaque_4 = { 17.9, 5.4, -3.75, -1, 0 }, Plaque_5 = { 17.9, 5.4, -1.25, -1, 0 }, Plaque_6 = { 17.9, 5.4, 1.25, -1, 0 },
        Plaque_7 = { 17.9, 5.4, 3.75, -1, 0 }, Plaque_8 = { 17.9, 5.4, 6.25, -1, 0 }, Plaque_9 = { 17.9, 5.4, 8.75, -1, 0 },
        Plaque_10 = { 17.9, 5.4, 11.25, -1, 0 },
        Poster_1 = { -17.9, 5.5, -10, 1, 0 }, Poster_2 = { -17.9, 5.5, -6, 1, 0 }, Poster_3 = { -17.9, 5.5, -2, 1, 0 },
        Poster_4 = { -17.9, 5.5, 2, 1, 0 }, Poster_5 = { -17.9, 5.5, 6, 1, 0 }, Poster_6 = { -17.9, 5.5, 10, 1, 0 },
        BoothSpot = { -13.5, 0, -10, 0, 1 }, BoothCam = { -13.5, 5, -4, 0, -1 } } },
  },
  Speakers = {
    { gear = nil,            rolloff = { 2, 8 },   volume = 0.5, eq = { -20, -4, 0 } },
    { gear = "spk_monitors", rolloff = { 6, 24 },  volume = 1.0, eq = { -6, 0, 0 } },
    { gear = "spk_studio",   rolloff = { 10, 45 }, volume = 1.4, eq = { 0, 0, 2 } },
  },
  PosterWords = { "LOUD", "GRIND", "DREAM", "BASS", "VIBES", "FIRE", "GOLD", "NIGHT", "FOCUS", "HUSTLE", "RISE", "SOON" },
  PosterColors = {
    { 235, 64, 52 }, { 255, 150, 40 }, { 255, 214, 60 }, { 0, 200, 120 },
    { 60, 130, 255 }, { 150, 90, 240 }, { 230, 45, 145 }, { 28, 28, 34 },
  },
  PosterStyles = 3,
  PosterColorNames = { "RED", "ORANGE", "YELLOW", "GREEN", "BLUE", "PURPLE", "PINK", "BLACK" },
  PosterStyleNames = { "BOLD", "FRAMED", "STACKED" },
  PosterColorInk = {
    { 245, 245, 245 }, { 24, 24, 28 }, { 24, 24, 28 }, { 24, 24, 28 },
    { 245, 245, 245 }, { 245, 245, 245 }, { 245, 245, 245 }, { 245, 245, 245 },
  },
}
-- literal copies of the live ids the catalog's unlocks may name: Config.Gear's ids (Task 7 adds spk_monitors and
-- spk_studio), Config.Life.Firsts and Config.Life.Tiers
local GEAR_IDS = { "808", "rollfx", "swing", "neon_ice", "kit_tape", "voice_pluck", "voice_chime", "plate_gold", "kit_iron",
	"neon_gold", "fit_cuban", "fit_snapback", "fit_shades", "plate_legend" }
local FIRSTS = { "beat", "delivery", "delivery3", "placement", "hit", "sponsor", "hall", "cypher", "level5", "buzzing", "known", "streak7" }
local TIERS = { { id = "LOCAL", followers = 0 }, { id = "BUZZING", followers = 1000 }, { id = "KNOWN", followers = 5000 },
	{ id = "FAMOUS", followers = 20000 }, { id = "ICON", followers = 100000 } }

local fails = {}
local function eq(name, got, want)
	if got ~= want then table.insert(fails, string.format("%s: expected %s, got %s", name, tostring(want), tostring(got))) end
end
local function ok(name, cond) if not cond then table.insert(fails, name) end end
local function near(a, b, eps) return type(a) == "number" and math.abs(a - b) <= (eps or 1e-9) end
local function setOf(list) local s = {} for _, v in ipairs(list) do s[v] = true end return s end
local function idList(list, field) -- "a,b,c" of a list's field (or the values themselves)
	local t = {}
	for _, e in ipairs(list or {}) do
		local v = e
		if field then v = e[field] end
		table.insert(t, tostring(v))
	end
	return table.concat(t, ",")
end

-- a strict JSON encoder, as strict as HttpService:JSONEncode about what it can't encode: a table is either a dense
-- array or an object with string keys (never both: mixed tables and sparse arrays error), numbers are finite
local function json(v)
	local t = type(v)
	if t == "string" then return '"' .. string.gsub(v, '[%c"\\]', function(c) return string.format("\\u%04x", string.byte(c)) end) .. '"' end
	if t == "boolean" then return tostring(v) end
	if t == "number" then
		if v ~= v or v == math.huge or v == -math.huge then error("json: NaN or inf") end
		if v % 1 == 0 then return string.format("%d", v) end
		return tostring(v)
	end
	if t ~= "table" then error("json: can't encode a " .. t) end
	local count, n = 0, #v
	for _ in pairs(v) do count += 1 end
	if n > 0 then
		if count ~= n then error("json: a mixed or sparse table") end
		local parts = {}
		for i = 1, n do parts[i] = json(v[i]) end
		return "[" .. table.concat(parts, ",") .. "]"
	end
	if count == 0 then return "[]" end
	local keys = {}
	for k in pairs(v) do
		if type(k) ~= "string" then error("json: a mixed or sparse table (key " .. tostring(k) .. ")") end
		table.insert(keys, k)
	end
	table.sort(keys)
	local parts = {}
	for _, k in ipairs(keys) do table.insert(parts, json(k) .. ":" .. json(v[k])) end
	return "{" .. table.concat(parts, ",") .. "}"
end
local function encodes(name, v)
	local good, res = pcall(json, v)
	ok(name .. ": JSON-encodes (" .. tostring(res) .. ")", good)
	return good and res or ""
end

local BED, HOME, REAL = ROOMS.Kinds.bedroom, ROOMS.Kinds.home, ROOMS.Kinds.real
local ALL = {} -- every catalog item unlocked
for _, it in ipairs(CAT.Items) do ALL[it.id] = true end
local NONE = R.Unlocked(CAT, {}, TIERS) -- only the items with no unlock rule
-- Fits' reason ("ok" when it fits); kcfg overrides the kind's Config row
local function why(items, e, kind, unl, ignore, kcfg)
	local fit, reason = R.Fits(items, e, kcfg or ROOMS.Kinds[kind], CAT, unl or ALL, kind, ignore, ROOMS)
	if fit then
		if reason ~= nil then return "ok with a reason " .. tostring(reason) end
		return "ok"
	end
	return tostring(reason)
end
local function F(id, x, z, r) return { id = id, x = x, z = z, r = r or 0 } end
local function P(slot, w, c, s) return { id = "poster", slot = slot, w = w or 1, c = c or 1, s = s or 1 } end
local function copy(t) -- deep copy
	if type(t) ~= "table" then return t end
	local o = {}
	for k, v in pairs(t) do o[k] = copy(v) end
	return o
end
-- the home row with a whole-floor grid and no keep areas (Task 2 wrote the stand-in's real ones, checked below), for
-- cases that need a home floor item to fit anywhere
local HOME_GRID = copy(HOME)
HOME_GRID.grid = { { -12, -10, 12, 10 } }
HOME_GRID.keep = nil
local ROOMS_GRID = copy(ROOMS)
ROOMS_GRID.Kinds.home.grid = { { -12, -10, 12, 10 } }
ROOMS_GRID.Kinds.home.keep = nil

-- PlotOrigin ---------------------------------------------------------------------------------------------------------
local function origin(k) local x, y, z = R.PlotOrigin(k, ROOMS) return string.format("%g,%g,%g", x, y, z) end
eq("PlotOrigin 1", origin(1), "6000,0,-2000")
eq("PlotOrigin 4", origin(4), "12000,0,-2000")
eq("PlotOrigin 5", origin(5), "6000,0,0")
eq("PlotOrigin 12", origin(12), "12000,0,2000")
local minGap = math.huge
for a = 1, ROOMS.Slots do
	for b = a + 1, ROOMS.Slots do
		local ax, _, az = R.PlotOrigin(a, ROOMS)
		local bx, _, bz = R.PlotOrigin(b, ROOMS)
		minGap = math.min(minGap, math.sqrt((ax - bx) ^ 2 + (az - bz) ^ 2))
	end
end
ok("PlotOrigin: any two slots are at least 2000 apart (closest " .. minGap .. ")", minGap >= 2000)

-- Claim: the lowest free slot (slots[k] = a user id or nil; a freed slot leaves a hole) ------------------------------
eq("Claim empty", R.Claim({}, 12), 1)
eq("Claim 1..3 taken", R.Claim({ 101, 102, 103 }, 12), 4)
eq("Claim slot 2 freed", R.Claim({ 101, nil, 103 }, 12), 2)
local full = {}
for k = 1, 12 do full[k] = 100 + k end
eq("Claim all 12 taken", R.Claim(full, 12), nil)
local holes = { [1] = 101, [3] = 103, [12] = 112 }
eq("Claim with holes", R.Claim(holes, 12), 2)
holes[2] = 102
eq("Claim with holes, 2 taken", R.Claim(holes, 12), 4)
eq("Claim nil slots", R.Claim(nil, 12), 1)

-- Owned: ladder order, the bedroom always ----------------------------------------------------------------------------
eq("Owned {}", idList(R.Owned({}, ROOMS.Kinds)), "bedroom")
eq("Owned nil", idList(R.Owned(nil, ROOMS.Kinds)), "bedroom")
eq("Owned home", idList(R.Owned({ home_studio = true }, ROOMS.Kinds)), "bedroom,home")
eq("Owned real without home", idList(R.Owned({ real_studio = true }, ROOMS.Kinds)), "bedroom,real")
eq("Owned both", idList(R.Owned({ real_studio = true, home_studio = true }, ROOMS.Kinds)), "bedroom,home,real")
eq("Owned studio_two changes nothing", idList(R.Owned({ studio_two = true }, ROOMS.Kinds)), "bedroom")
eq("Owned false gate", idList(R.Owned({ home_studio = false }, ROOMS.Kinds)), "bedroom")

-- Box: the room's interior in world studs (the plot's origin + at, +- size / 2) --------------------------------------
local b = R.Box("bedroom", ROOMS, 1)
ok("Box bedroom slot 1", b and near(b[1], 6010 - 6.18) and near(b[2], -2008 - 7.415) and near(b[3], 6010 + 6.18) and near(b[4], -2008 + 7.415))
b = R.Box("real", ROOMS, 12)
ok("Box real slot 12", b and near(b[1], 12085 - 18) and near(b[2], 2000 - 14.6 - 14) and near(b[3], 12085 + 18) and near(b[4], 2000 - 14.6 + 14))
eq("Box unknown kind", R.Box("attic", ROOMS, 1), nil)
-- every room sits north of the landing (plot-local z 0..8) and inside the plot's spacing
for kind, k in pairs(ROOMS.Kinds) do
	local bx = R.Box(kind, ROOMS, 1)
	ok("Box " .. kind .. ": north of the landing", bx and bx[4] <= -2000 + 0)
	ok("Box " .. kind .. ": within the landing's length", bx and bx[1] >= 6000 and bx[3] <= 6000 + ROOMS.Landing.length)
	ok("Box " .. kind .. ": size", bx and near(bx[3] - bx[1], k.size[1]) and near(bx[4] - bx[2], k.size[2]))
end
-- no two rooms of one plot overlap
local kinds = { "bedroom", "home", "real" }
for i = 1, #kinds do
	for j = i + 1, #kinds do
		local p, q = R.Box(kinds[i], ROOMS, 1), R.Box(kinds[j], ROOMS, 1)
		ok("Box " .. kinds[i] .. " and " .. kinds[j] .. " don't overlap", p[3] <= q[1] or q[3] <= p[1] or p[4] <= q[2] or q[4] <= p[2])
	end
end

-- Cells: (x, z) is the footprint's lowest cell; an odd r swaps w and d ---------------------------------------------
local function cellKey(cells)
	local t = {}
	for _, c in ipairs(cells) do table.insert(t, c[1] .. ":" .. c[2]) end
	table.sort(t)
	return table.concat(t, " ")
end
local SHELF = CAT.ById.low_shelf
eq("low_shelf is 2 x 1", SHELF and SHELF.size[1] .. "x" .. SHELF.size[2], "2x1")
eq("Cells 2x1 r0", cellKey(R.Cells(SHELF, F("low_shelf", -6, -7, 0))), "-5:-7 -6:-7")
eq("Cells 2x1 r1 (swapped)", cellKey(R.Cells(SHELF, F("low_shelf", -6, -7, 1))), "-6:-6 -6:-7")
eq("Cells 2x1 r2", cellKey(R.Cells(SHELF, F("low_shelf", -6, -7, 2))), "-5:-7 -6:-7")
eq("Cells 2x1 r3 (swapped)", cellKey(R.Cells(SHELF, F("low_shelf", -6, -7, 3))), "-6:-6 -6:-7")
eq("Cells rug 2x2", cellKey(R.Cells(CAT.ById.rug, F("rug", 0, 0, 0))), "0:0 0:1 1:0 1:1")
eq("Cells a wall item has none", #R.Cells(CAT.ById.poster, P(1)), 0)
eq("Cells junk coordinates", #R.Cells(SHELF, { id = "low_shelf", x = "1", z = 0, r = 0 }), 0)
-- Centre: the footprint's centre (where a builder puts the item's origin before its r quarter turns)
local cx, cz = R.Centre(SHELF, F("low_shelf", -6, -7, 1))
ok("Centre 2x1 r1", near(cx, -5.5) and near(cz, -6))
cx, cz = R.Centre(SHELF, F("low_shelf", -6, -7, 0))
ok("Centre 2x1 r0", near(cx, -5) and near(cz, -6.5))

-- Fits ---------------------------------------------------------------------------------------------------------------
eq("rug is 2 x 2", CAT.ById.rug and CAT.ById.rug.size[1] .. "x" .. CAT.ById.rug.size[2], "2x2")
eq("plant is 1 x 1", CAT.ById.plant and CAT.ById.plant.size[1] .. "x" .. CAT.ById.plant.size[2], "1x1")
-- inside a grid area (area 3, the north-west corner, and area 2's free cells): ok
eq("Fits rug in area 3", why({}, F("rug", -6, -7), "bedroom"), "ok")
eq("Fits plant in area 2", why({}, F("plant", 4, 1), "bedroom"), "ok")
eq("Fits plant in area 2, south cell", why({}, F("plant", 4, 2), "bedroom"), "ok")
-- grid area 1 lies under the pigeon's spot and the walkway (preflight m5): with the first-guess grid every one of its
-- cells touches a keep area, so an item there is "bounds" until Task 10's capture moves the area
for _, c in ipairs({ { -1, 0 }, { 0, 0 }, { 1, 0 }, { -1, 1 }, { 0, 1 }, { 1, 1 } }) do
	eq("Fits plant on area 1's cell " .. c[1] .. "," .. c[2] .. " (keep)", why({}, F("plant", c[1], c[2]), "bedroom"), "bounds")
end
eq("Fits plant on CritterSpot's cell", why({}, F("plant", -1, 0), "bedroom"), "bounds")
eq("Fits plant on the walkway (area 2's west column)", why({}, F("plant", 3, 1), "bedroom"), "bounds")
-- one cell outside every area
eq("Fits rug one column out of area 3", why({}, F("rug", -4, -7), "bedroom"), "bounds")
eq("Fits rug one row out of area 3", why({}, F("rug", -6, -2), "bedroom"), "bounds")
eq("Fits plant far away", why({}, F("plant", 40, 40), "bedroom"), "bounds")
eq("Fits plant at a fractional x", why({}, F("plant", -5.5, -7), "bedroom"), "bounds")
eq("Fits plant at a string x", why({}, { id = "plant", x = "-5", z = -7, r = 0 }, "bedroom"), "bounds")
-- on another item's cell
local placed = { F("rug", -6, -7) }
eq("Fits plant on the rug", why(placed, F("plant", -5, -6), "bedroom"), "overlap")
eq("Fits plant beside the rug", why(placed, F("plant", -4, -6), "bedroom"), "ok")
eq("Fits a 2nd rug half over the first", why(placed, F("rug", -5, -6), "bedroom"), "overlap")
-- the 7th bedroom item
local six = { F("rug", -6, -7), F("plant", -4, -7), F("plant", -4, -6), F("plant", -4, -5), F("plant", 4, 1), F("plant", 4, 2) }
for i, e in ipairs(six) do eq("Fits the six, one by one: " .. i, why({ table.unpack(six, 1, i - 1) }, e, "bedroom"), "ok") end
eq("Fits the 7th bedroom item", why(six, F("plant", -6, -4), "bedroom"), "limit")
eq("Fits the 6th item moved (ignoreIndex)", why(six, F("plant", -6, -4), "bedroom", ALL, 6), "ok")
eq("Fits the 6th item moved onto its own cell", why(six, F("plant", 4, 2), "bedroom", ALL, 6), "ok")
eq("Fits the 6th item moved onto the rug", why(six, F("plant", -5, -7), "bedroom", ALL, 6), "overlap")
-- rotations: whole quarter turns 0..3 only
eq("Fits r = 4", why({}, F("plant", -5, -5, 4), "bedroom"), "rot")
eq("Fits r = 1.5", why({}, F("plant", -5, -5, 1.5), "bedroom"), "rot")
eq("Fits r = -1", why({}, F("plant", -5, -5, -1), "bedroom"), "rot")
eq("Fits r = '1'", why({}, { id = "plant", x = -5, z = -5, r = "1" }, "bedroom"), "rot")
eq("Fits r = 3", why({}, F("plant", -5, -5, 3), "bedroom"), "ok")
eq("Fits r missing (0)", why({}, { id = "plant", x = -5, z = -5 }, "bedroom"), "ok")
-- a rotated 2 x 1 item occupies swapped cells: across area 3's 3 columns at r 0 it fits, turned it runs down a column
eq("Fits shelf r0 at the west edge", why({}, F("low_shelf", -5, -7, 0), "bedroom"), "ok")
eq("Fits shelf r0 one column too far east", why({}, F("low_shelf", -4, -7, 0), "bedroom"), "bounds")
eq("Fits shelf r1 in the east column", why({}, F("low_shelf", -4, -7, 1), "bedroom"), "ok")
eq("Fits shelf r1 down into the last row", why({}, F("low_shelf", -4, -2, 1), "bedroom"), "bounds")
eq("Fits plant on a turned shelf's 2nd cell", why({ F("low_shelf", -4, -7, 1) }, F("plant", -4, -6), "bedroom"), "overlap")
eq("Fits plant beside a turned shelf", why({ F("low_shelf", -4, -7, 1) }, F("plant", -5, -7), "bedroom"), "ok")
-- unknown ids and junk entries
eq("Fits an unknown id", why({}, F("lava_lamp", -5, -5), "bedroom"), "unknown")
eq("Fits no id", why({}, { x = -5, z = -5, r = 0 }, "bedroom"), "unknown")
eq("Fits a junk entry", why({}, "plant", "bedroom"), "unknown")
-- locked: a gear-linked item without its gear
local noTape = R.Unlocked(CAT, { gear = {} }, TIERS)
local withTape = R.Unlocked(CAT, { gear = { kit_tape = true } }, TIERS)
eq("Fits tape_machine without kit_tape", why({}, F("tape_machine", -6, -7), "bedroom", noTape), "locked")
eq("Fits tape_machine with kit_tape", why({}, F("tape_machine", -6, -7), "bedroom", withTape), "ok")
eq("Fits tape_machine with an empty unlocked set", why({}, F("tape_machine", -6, -7), "bedroom", {}), "locked")
-- an item with no unlock rule fits whatever the unlocked set says (a partial or stubbed set never refuses the rug)
eq("Fits rug with an empty unlocked set", R.Fits({}, F("rug", -6, -7), BED, CAT, {}, "bedroom", nil, ROOMS), true)
eq("Fits rug with a nil unlocked set", R.Fits({}, F("rug", -6, -7), BED, CAT, nil, "bedroom", nil, ROOMS), true)
-- an existing entry that is locked (kept unbuilt by Repair) or unknown takes no cell and doesn't count
eq("Fits plant on a locked tape machine's cell", why({ F("tape_machine", -6, -7) }, F("plant", -6, -7), "bedroom", noTape), "ok")
eq("Fits plant on an unlocked tape machine's cell", why({ F("tape_machine", -6, -7) }, F("plant", -6, -7), "bedroom", withTape), "overlap")
local fivePlus = { table.unpack(six, 1, 5) }
table.insert(fivePlus, 2, F("tape_machine", -6, -5))
table.insert(fivePlus, F("lava_lamp", -6, -4))
eq("Fits locked and unknown entries don't count toward the limit", why(fivePlus, F("plant", -6, -3), "bedroom", noTape), "ok")
eq("Fits ... but an unlocked one does", why(fivePlus, F("plant", -6, -3), "bedroom", withTape), "limit")
-- room: a kind the item isn't allowed in
eq("Fits closet in the bedroom", why({}, F("closet", -6, -7), "bedroom"), "room")
eq("Fits couch in the bedroom", why({}, F("couch", -6, -7), "bedroom"), "room")
eq("Fits poster in the bedroom", why({}, P(1), "bedroom"), "room")
eq("Fits plant in an unknown kind", R.Fits({}, F("plant", 0, 0), nil, CAT, ALL, "attic", nil, ROOMS), false)
eq("Fits plant in an unknown kind: reason", select(2, R.Fits({}, F("plant", 0, 0), nil, CAT, ALL, "attic", nil, ROOMS)), "room")
-- max: one closet a room
eq("Fits closet in home", why({}, F("closet", 0, 0), "home", ALL, nil, HOME_GRID), "ok")
eq("Fits a 2nd closet in home", why({ F("closet", 0, 0) }, F("closet", 5, 5), "home"), "max")
eq("Fits a 2nd closet in home (with a grid)", why({ F("closet", 0, 0) }, F("closet", 5, 5), "home", ALL, nil, HOME_GRID), "max")
eq("Fits home's only closet moved", why({ F("closet", 0, 0) }, F("closet", 5, 5), "home", ALL, 1, HOME_GRID), "ok")
eq("Fits a closet in real while home has one", why({}, F("closet", 0, 0), "real", ALL, nil, (function() local k = copy(REAL); k.grid = { { -18, -14, 18, 14 } }; return k end)()), "ok")
-- a room row with no grid has no floor to stand on (Task 2 wrote home's real grid, so the case takes a copy without one)
local HOME_BARE = copy(HOME)
HOME_BARE.grid = nil
eq("Fits couch in home with no grid", why({}, F("couch", 0, 0), "home", ALL, nil, HOME_BARE), "bounds")
-- with home's own grid (Task 2's stand-in floor) the same couch stands in the middle of the room
eq("Fits couch in home's own grid", why({}, F("couch", -4, 4), "home"), "ok")
eq("Fits couch on home's desk (off the grid)", why({}, F("couch", -2, -9), "home"), "bounds")
-- posters: wall spots 1..posters, one poster a spot, designs in range; they count toward the limit
eq("Fits poster slot 1 in home", why({}, P(1), "home"), "ok")
eq("Fits poster slot 4 in home", why({}, P(4), "home"), "ok")
eq("Fits poster slot 5 in home (posters 4)", why({}, P(5), "home"), "slot")
eq("Fits poster slot 0", why({}, P(0), "home"), "slot")
eq("Fits poster slot 1.5", why({}, P(1.5), "home"), "slot")
eq("Fits poster slot 6 in real", why({}, P(6), "real"), "ok")
eq("Fits poster slot 7 in real", why({}, P(7), "real"), "slot")
eq("Fits poster on a taken slot", why({ P(2) }, P(2, 3, 3, 3), "home"), "slot")
eq("Fits poster redesigned in its own slot", why({ P(2) }, P(2, 3, 3, 3), "home", ALL, 1), "ok")
eq("Fits poster moved to a free slot", why({ P(2) }, P(3), "home", ALL, 1), "ok")
eq("Fits poster word 13", why({}, P(1, 13, 1, 1), "home"), "design")
eq("Fits poster word 12", why({}, P(1, 12, 1, 1), "home"), "ok")
eq("Fits poster color 9", why({}, P(1, 1, 9, 1), "home"), "design")
eq("Fits poster color 8", why({}, P(1, 1, 8, 1), "home"), "ok")
eq("Fits poster style 4", why({}, P(1, 1, 1, 4), "home"), "design")
eq("Fits poster style 0", why({}, P(1, 1, 1, 0), "home"), "design")
eq("Fits poster word 1.5", why({}, P(1, 1.5, 1, 1), "home"), "design")
eq("Fits poster with no Config.Rooms (fails closed)", select(2, R.Fits({}, P(1), HOME, CAT, ALL, "home", nil, nil)), "design")
local fifteen = {}
for i = 1, 15 do table.insert(fifteen, F("plant", -12 + i, -9)) end
eq("Fits 15 home items + a poster is the 16th", why(fifteen, P(1), "home", ALL, nil, HOME_GRID), "ok")
table.insert(fifteen, P(1))
eq("Fits a 2nd poster as the 17th home item", why(fifteen, P(2), "home", ALL, nil, HOME_GRID), "limit")
eq("Fits a plant as the 17th home item (posters count)", why(fifteen, F("plant", 0, 5), "home", ALL, nil, HOME_GRID), "limit")
-- a wall item on the floor list and a floor item on the wall don't collide: a poster takes no floor cell
eq("Fits plant with posters hung", why({ P(1), P(2) }, F("plant", 0, 0), "home", ALL, nil, HOME_GRID), "ok")
-- every catalog item allowed in the bedroom (gear items included) fits somewhere in an empty bedroom
for _, it in ipairs(CAT.Items) do
	local allowed = it.rooms == nil or table.find(it.rooms, "bedroom") ~= nil
	if allowed then
		local found = false
		for r = 0, 3 do
			for x = -8, 8 do
				for z = -8, 8 do
					if not found and R.Fits({}, F(it.id, x, z, r), BED, CAT, ALL, "bedroom", nil, ROOMS) then found = true end
				end
			end
		end
		ok("Fits " .. it.id .. ": has a spot in an empty bedroom", found)
	end
end
-- keep: the walkway from Entrance to VisitorSpot is covered 0.5 either side of the line, and the spawn and the pigeon
local function inKeep(x, z)
	for _, a in ipairs(BED.keep) do
		if x >= a[1] and x <= a[3] and z >= a[2] and z <= a[4] then return true end
	end
	return false
end
local en, vs, cs = BED.anchors.Entrance, BED.anchors.VisitorSpot, BED.anchors.CritterSpot
local dx, dz = en[1] - vs[1], en[3] - vs[3]
local len = math.sqrt(dx * dx + dz * dz)
local px, pz = dz / len, -dx / len
for i = 0, 40 do
	for _, off in ipairs({ -0.5, 0, 0.5 }) do
		local x, z = vs[1] + dx * i / 40 + px * off, vs[3] + dz * i / 40 + pz * off
		ok(string.format("keep covers the walkway at %.2f, %.2f", x, z), inKeep(x, z))
	end
end
ok("keep covers CritterSpot", inKeep(cs[1], cs[3]))
ok("keep covers the spawn (1.62, 2.84)", inKeep(1.6216, 2.8378))

-- Repair (R8) --------------------------------------------------------------------------------------------------------
local function entryKey(e)
	if type(e) ~= "table" then return tostring(e) end
	if e.id == "poster" then return string.format("poster@%s:%s/%s/%s", tostring(e.slot), tostring(e.w), tostring(e.c), tostring(e.s)) end
	return string.format("%s@%s,%s,%s", tostring(e.id), tostring(e.x), tostring(e.z), tostring(e.r))
end
local function listKey(list)
	local t = {}
	for _, e in ipairs(list or {}) do table.insert(t, entryKey(e)) end
	return table.concat(t, " ")
end
local function reasons(list, kind) -- "index:reason" of the records for one kind (or the home-level ones when kind is false)
	local t = {}
	for _, d in ipairs(list or {}) do
		if (kind == false and d.kind == nil) or (kind ~= false and d.kind == kind) then
			table.insert(t, tostring(d.index or d.field) .. ":" .. tostring(d.reason))
		end
	end
	return table.concat(t, " ")
end
-- junk at the top: defaults, and the junk named
local h, dropped, unbuilt = R.Repair({ items = "x", door = "wide" }, { "bedroom" }, ROOMS, CAT, NONE)
eq("Repair junk: v", h.v, 1)
eq("Repair junk: door", h.door, "friends")
eq("Repair junk: items", type(h.items) == "table" and next(h.items) == nil, true)
eq("Repair junk: dropped", reasons(dropped, false), "door:malformed items:malformed")
eq("Repair junk: unbuilt", #unbuilt, 0)
h, dropped = R.Repair(nil, { "bedroom" }, ROOMS, CAT, NONE)
eq("Repair nil: defaults", json(h), '{"door":"friends","items":[],"v":1}')
eq("Repair nil: nothing dropped", #dropped, 0)
h, dropped = R.Repair("junk", { "bedroom" }, ROOMS, CAT, NONE)
eq("Repair a string: defaults", json(h), '{"door":"friends","items":[],"v":1}')
eq("Repair a string: named", reasons(dropped, false), "home:malformed")
h = R.Repair({ v = 7, door = "locked", items = {} }, { "bedroom" }, ROOMS, CAT, NONE)
eq("Repair keeps a good door", h.door, "locked")
eq("Repair sets v 1", h.v, 1)
-- the mixed list: home not owned, kit_tape not owned
local MIXED = { v = 1, door = "open", items = {
	bedroom = {
		F("rug", -6, -7),                                  -- 1 good: kept
		{ id = "plant", x = "4", z = 1, r = 0 },           -- 2 a string coordinate: dropped
		F("lava_lamp", 4, 1),                              -- 3 an unknown id: dropped
		F("tape_machine", -6, -5),                         -- 4 locked (no kit_tape): kept, unbuilt
		F("plant", -5, -7),                                -- 5 on the rug: dropped (overlap)
		F("plant", 0, 0),                                  -- 6 on the pigeon's spot: dropped (bounds)
		F("plant", -6, -5),                                -- 7 on the locked tape machine's cell: kept (it takes none)
		"x",                                               -- 8 junk: dropped
		F("plant", -4, -7),                                -- 9 kept
		F("closet", -4, -5),                               -- 10 a kind it isn't allowed in: dropped
		F("plant", -4, -6),                                -- 11 kept
		F("plant", -5, -4, 4),                             -- 12 a bad turn: dropped
		F("plant", -4, -5),                                -- 13 kept
		F("plant", 4, 1),                                  -- 14 kept: the 6th built
		F("plant", 4, 2),                                  -- 15 the 7th: dropped (limit)
		F("plant", -6, -4),                                -- 16 the 8th: dropped (limit)
		F("rug", 3.5, -7),                                 -- 17 a fractional coordinate: dropped
		{ id = 5, x = 0, z = 0, r = 0 },                   -- 18 a number id: dropped
	},
	-- home isn't owned: its entries are kept unbuilt with no geometry checks (a bad slot waits until home is owned);
	-- only the malformed, the unknown and a bad design go
	home = { F("couch", 0, 0), P(1, 2, 3, 1), F("lava_lamp", 1, 1), P(9, 1, 1, 1), P(1, 13, 1, 1) },
	attic = { F("rug", 0, 0) },
} }
local mixedBefore = json(MIXED)
h, dropped, unbuilt = R.Repair(MIXED, { "bedroom" }, ROOMS, CAT, NONE)
eq("Repair mixed: bedroom kept in order", listKey(h.items.bedroom),
	"rug@-6,-7,0 tape_machine@-6,-5,0 plant@-6,-5,0 plant@-4,-7,0 plant@-4,-6,0 plant@-4,-5,0 plant@4,1,0")
eq("Repair mixed: bedroom dropped", reasons(dropped, "bedroom"),
	"2:malformed 3:unknown 5:overlap 6:bounds 8:malformed 10:room 12:rot 15:limit 16:limit 17:malformed 18:malformed")
eq("Repair mixed: home kept unbuilt (not owned)", listKey(h.items.home), "couch@0,0,0 poster@1:2/3/1 poster@9:1/1/1")
eq("Repair mixed: home dropped (unknown, a bad design)", reasons(dropped, "home"), "3:unknown 5:design")
eq("Repair mixed: an unknown kind dropped", reasons(dropped, "attic"), "items:kind")
eq("Repair mixed: unbuilt", reasons(unbuilt, "bedroom") .. " | " .. reasons(unbuilt, "home"), "2:locked | 1:unowned 2:unowned 3:unowned")
eq("Repair mixed: unbuilt names ids", idList(unbuilt, "id"), "tape_machine,couch,poster,poster")
eq("Repair mixed: dropped names ids", idList(dropped, "id"),
	"plant,lava_lamp,plant,plant,nil,closet,plant,plant,plant,rug,5,lava_lamp,poster,nil")
eq("Repair mixed: the input is untouched", json(MIXED), mixedBefore)
ok("Repair mixed: returns fresh tables", h.items.bedroom[1] ~= MIXED.items.bedroom[1])
eq("Repair mixed: the door kept", h.door, "open")
encodes("Repair mixed: the result", h)
-- every kept entry carries named fields only
for _, e in ipairs(h.items.bedroom) do
	local n = 0
	for k in pairs(e) do
		n += 1
		ok("Repair: a floor entry holds only id, x, z, r (" .. tostring(k) .. ")", k == "id" or k == "x" or k == "z" or k == "r")
	end
	eq("Repair: a floor entry's field count", n, 4)
end
-- repaired again: nothing more to drop, the same home
local h2, d2, u2 = R.Repair(h, { "bedroom" }, ROOMS, CAT, NONE)
eq("Repair is idempotent", json(h2), json(h))
eq("Repair again drops nothing", #d2, 0)
eq("Repair again: the same unbuilt", reasons(u2, "bedroom") .. " | " .. reasons(u2, "home"), "2:locked | 1:unowned 2:unowned 3:unowned")
-- with kit_tape owned the tape machine is built again: the earlier entry wins and the later plant on its cell is dropped
local unlTape = R.Unlocked(CAT, { gear = { kit_tape = true } }, TIERS)
local h3, d3, u3 = R.Repair(h, { "bedroom" }, ROOMS, CAT, unlTape)
eq("Repair with kit_tape: bedroom", listKey(h3.items.bedroom),
	"rug@-6,-7,0 tape_machine@-6,-5,0 plant@-4,-7,0 plant@-4,-6,0 plant@-4,-5,0 plant@4,1,0")
eq("Repair with kit_tape: the plant on its cell dropped", reasons(d3, "bedroom"), "3:overlap")
eq("Repair with kit_tape: nothing locked", reasons(u3, "bedroom"), "")
-- a locked item ahead of six good ones: all six built
local h4, d4, u4 = R.Repair({ items = { bedroom = { F("tape_machine", -6, -5), table.unpack(six) } } }, { "bedroom" }, ROOMS, CAT, NONE)
eq("Repair: a locked item ahead of six good ones keeps all seven", #h4.items.bedroom, 7)
eq("Repair: ... dropping none", #d4, 0)
eq("Repair: ... one unbuilt", reasons(u4, "bedroom"), "1:locked")
-- home owned (with a grid): built; a 2nd closet and a 2nd poster on one slot dropped
local h5, d5, u5 = R.Repair({ items = { home = { F("couch", -5, 0), F("closet", 3, 3), F("closet", 6, 6), P(1, 2, 3, 1), P(1, 4, 4, 2) } } },
	{ "bedroom", "home" }, ROOMS_GRID, CAT, NONE)
eq("Repair home owned: kept", listKey(h5.items.home), "couch@-5,0,0 closet@3,3,0 poster@1:2/3/1")
eq("Repair home owned: dropped", reasons(d5, "home"), "3:max 5:slot")
eq("Repair home owned: unbuilt", #u5, 0)
-- owned as a set works too
local h6 = R.Repair({ items = { home = { P(1) } } }, { bedroom = true, home = true }, ROOMS_GRID, CAT, NONE)
eq("Repair owned as a set", listKey(h6.items.home), "poster@1:1/1/1")
-- the non-array part of a kind's list is junk
local odd = { F("rug", -6, -7) }
odd.extra = F("plant", 4, 1)
local h7, d7 = R.Repair({ items = { bedroom = odd } }, { "bedroom" }, ROOMS, CAT, NONE)
eq("Repair: a list's array part kept", listKey(h7.items.bedroom), "rug@-6,-7,0")
eq("Repair: a list's extra key dropped", reasons(d7, "bedroom"), "extra:malformed")
local h8, d8 = R.Repair({ items = { bedroom = "rugs" } }, { "bedroom" }, ROOMS, CAT, NONE)
eq("Repair: a kind's list that isn't a table", reasons(d8, "bedroom"), "items:malformed")
eq("Repair: ... leaves the kind out", h8.items.bedroom, nil)

-- the save's size: every room filled to its limit, posters at their max, the longest id and the widest numbers -----
local longest = ""
for _, it in ipairs(CAT.Items) do if it.kind == "floor" and #it.id > #longest then longest = it.id end end
local maxHome = { v = 1, door = "friends", items = {} }
for kind, k in pairs(ROOMS.Kinds) do
	local list = {}
	for i = 1, k.posters do table.insert(list, { id = "poster", slot = i, w = #ROOMS.PosterWords, c = #ROOMS.PosterColors, s = ROOMS.PosterStyles }) end
	while #list < k.limit do table.insert(list, { id = longest, x = -18, z = -14, r = 3 }) end
	maxHome.items[kind] = list
end
local maxJson = encodes("the maximal home", maxHome)
ok("the maximal home JSON-encodes under 4,096 bytes (" .. #maxJson .. ")", #maxJson > 0 and #maxJson < 4096)
eq("the maximal home holds 46 items", #maxHome.items.bedroom + #maxHome.items.home + #maxHome.items.real, 46)
-- and the strict encoder does refuse what HttpService can't encode
-- selene: allow(mixed_table)
ok("json refuses a mixed table", not pcall(json, { "rug", x = 1 }))
ok("json refuses a sparse array", not pcall(json, { [1] = 1, [3] = 3 }))

-- Unlocked -----------------------------------------------------------------------------------------------------------
eq("Unlocked: kit_tape opens tape_machine", R.Unlocked(CAT, { gear = { kit_tape = true } }, TIERS).tape_machine, true)
eq("Unlocked: no gear, no tape_machine", R.Unlocked(CAT, { gear = {} }, TIERS).tape_machine, nil)
eq("Unlocked: gear as a list", R.Unlocked(CAT, { gear = { "kit_iron" } }, TIERS).drum_machine, true)
eq("Unlocked: the rug and the plant from day one", NONE.rug == true and NONE.plant == true, true)
eq("Unlocked: nil have", R.Unlocked(CAT, nil, TIERS).rug, true)
-- a first, a tier and a room rule each open only when held (a test catalog, so the cases don't hang on the launch picks)
local TEST = { Items = {
	{ id = "a_first", unlock = { first = "placement" } },
	{ id = "a_tier", unlock = { tier = "KNOWN" } },
	{ id = "a_room", unlock = { room = "home" } },
	{ id = "a_gear", unlock = { gear = "kit_iron" } },
	{ id = "an_odd_rule", unlock = { wish = true } },
	{ id = "free" },
} }
local u = R.Unlocked(TEST, {}, TIERS)
eq("Unlocked test: nothing held", idList((function() local t = {} for id in pairs(u) do table.insert(t, id) end table.sort(t) return t end)()), "free")
eq("Unlocked first held", R.Unlocked(TEST, { firsts = { placement = 12 } }, TIERS).a_first, true)
eq("Unlocked first backfilled (0) counts", R.Unlocked(TEST, { firsts = { placement = 0 } }, TIERS).a_first, true)
eq("Unlocked another first", R.Unlocked(TEST, { firsts = { hit = 3 } }, TIERS).a_first, nil)
eq("Unlocked tier KNOWN at index 3", R.Unlocked(TEST, { tier = 3 }, TIERS).a_tier, true)
eq("Unlocked tier KNOWN at index 5", R.Unlocked(TEST, { tier = 5 }, TIERS).a_tier, true)
eq("Unlocked tier KNOWN at index 2", R.Unlocked(TEST, { tier = 2 }, TIERS).a_tier, nil)
eq("Unlocked tier without the tier list (fails closed)", R.Unlocked(TEST, { tier = 5 }, nil).a_tier, nil)
eq("Unlocked room held (set)", R.Unlocked(TEST, { rooms = { home = true } }, TIERS).a_room, true)
eq("Unlocked room held (Owned's list)", R.Unlocked(TEST, { rooms = { "bedroom", "home" } }, TIERS).a_room, true)
eq("Unlocked room not held", R.Unlocked(TEST, { rooms = { "bedroom" } }, TIERS).a_room, nil)
eq("Unlocked an unknown rule stays locked", R.Unlocked(TEST, { gear = { kit_iron = true }, firsts = { placement = 1 }, tier = 5 }, TIERS).an_odd_rule, nil)

-- Plaques: hits newest first, then placements and track ones newest first, then weekly singles newest first --------
local DISCO = {
	{ d = 1, kind = "placement", v = "p1" }, { d = 2, kind = "hit", v = "h1" }, { d = 3, kind = "trackone", v = "t1" },
	{ d = 4, kind = "placement", v = "p2" }, { d = 5, kind = "hit", v = "h2" }, { d = 6, kind = "placement", v = "p3" },
}
local WEEKLY = { { w = 1, t = "Gold Tape", a = "x" }, { w = 2, t = "Main Stage", a = "y" } }
local function plaqueKey(list)
	local t = {}
	for _, p in ipairs(list) do table.insert(t, p.kind .. ":" .. tostring(p.entry.v or p.entry.t)) end
	return table.concat(t, " ")
end
eq("Plaques n 3", plaqueKey(R.Plaques(DISCO, WEEKLY, 3)), "hit:h2 hit:h1 placement:p3")
eq("Plaques n 10", plaqueKey(R.Plaques(DISCO, WEEKLY, 10)), "hit:h2 hit:h1 placement:p3 placement:p2 trackone:t1 placement:p1 weekly:Main Stage weekly:Gold Tape")
eq("Plaques n 1", plaqueKey(R.Plaques(DISCO, WEEKLY, 1)), "hit:h2")
eq("Plaques nil inputs", #R.Plaques(nil, nil, 3), 0)
eq("Plaques n 0", #R.Plaques(DISCO, WEEKLY, 0), 0)
eq("Plaques n nil", #R.Plaques(DISCO, WEEKLY, nil), 0)
eq("Plaques weekly only", plaqueKey(R.Plaques(nil, WEEKLY, 3)), "weekly:Main Stage weekly:Gold Tape")
ok("Plaques return the source rows", R.Plaques(DISCO, WEEKLY, 1)[1].entry == DISCO[5])
eq("Plaques skip junk rows and unknown kinds", plaqueKey(R.Plaques({ "x", { d = 1, kind = "delivery", v = "d" }, { d = 2, kind = "hit", v = "h" } }, { 5 }, 5)), "hit:h")

-- SpeakerTier --------------------------------------------------------------------------------------------------------
eq("SpeakerTier {}", R.SpeakerTier({}, ROOMS.Speakers), 1)
eq("SpeakerTier nil", R.SpeakerTier(nil, ROOMS.Speakers), 1)
eq("SpeakerTier monitors", R.SpeakerTier({ spk_monitors = true }, ROOMS.Speakers), 2)
eq("SpeakerTier studio", R.SpeakerTier({ spk_studio = true }, ROOMS.Speakers), 3)
eq("SpeakerTier both", R.SpeakerTier({ spk_monitors = true, spk_studio = true }, ROOMS.Speakers), 3)
-- each tier reaches further and plays louder than the one under it (preflight R6)
for i = 2, #ROOMS.Speakers do
	local lo, hi = ROOMS.Speakers[i - 1], ROOMS.Speakers[i]
	ok("Speakers tier " .. i .. ": rolloff max strictly larger", hi.rolloff[2] > lo.rolloff[2])
	ok("Speakers tier " .. i .. ": rolloff min not smaller", hi.rolloff[1] >= lo.rolloff[1])
	ok("Speakers tier " .. i .. ": louder", hi.volume > lo.volume)
end
eq("Speakers tier 1 needs no gear", ROOMS.Speakers[1].gear, nil)

-- CanEnter: the owner always; open admits anyone; friends admits friends; locked admits only the owner -------------
local ENTER = {
	{ "open", true, true, true }, { "open", true, false, true }, { "open", false, true, true }, { "open", false, false, true },
	{ "friends", true, true, true }, { "friends", true, false, true }, { "friends", false, true, true }, { "friends", false, false, false },
	{ "locked", true, true, true }, { "locked", true, false, true }, { "locked", false, true, false }, { "locked", false, false, false },
	{ "wide", false, true, true }, { "wide", false, false, false }, { "wide", true, false, true }, -- junk reads as friends
	{ "friends", false, nil, false }, -- a friend check that errored or timed out: not a friend
}
for _, row in ipairs(ENTER) do
	eq(string.format("CanEnter %s owner=%s friend=%s", row[1], tostring(row[2]), tostring(row[3])), R.CanEnter(row[1], row[2], row[3]), row[4])
end

-- NextDoorMode -------------------------------------------------------------------------------------------------------
eq("NextDoorMode open", R.NextDoorMode("open", ROOMS.DoorModes), "friends")
eq("NextDoorMode friends", R.NextDoorMode("friends", ROOMS.DoorModes), "locked")
eq("NextDoorMode locked", R.NextDoorMode("locked", ROOMS.DoorModes), "open")
eq("NextDoorMode junk", R.NextDoorMode("wide", ROOMS.DoorModes), "friends")
eq("NextDoorMode nil", R.NextDoorMode(nil, ROOMS.DoorModes), "friends")
eq("RoomRules' door fallback is Config's default", R.DOOR_FALLBACK, ROOMS.DoorDefault)

-- PosterOk -----------------------------------------------------------------------------------------------------------
eq("PosterOk 1/1/1", R.PosterOk({ w = 1, c = 1, s = 1 }, ROOMS), true)
eq("PosterOk 12/8/3", R.PosterOk({ w = 12, c = 8, s = 3 }, ROOMS), true)
eq("PosterOk w 0", R.PosterOk({ w = 0, c = 1, s = 1 }, ROOMS), false)
eq("PosterOk w 13", R.PosterOk({ w = 13, c = 1, s = 1 }, ROOMS), false)
eq("PosterOk c 9", R.PosterOk({ w = 1, c = 9, s = 1 }, ROOMS), false)
eq("PosterOk s 4", R.PosterOk({ w = 1, c = 1, s = 4 }, ROOMS), false)
eq("PosterOk w 2.5", R.PosterOk({ w = 2.5, c = 1, s = 1 }, ROOMS), false)
eq("PosterOk w '2'", R.PosterOk({ w = "2", c = 1, s = 1 }, ROOMS), false)
eq("PosterOk w nan", R.PosterOk({ w = 0 / 0, c = 1, s = 1 }, ROOMS), false)
eq("PosterOk missing s", R.PosterOk({ w = 1, c = 1 }, ROOMS), false)
eq("PosterOk nil design", R.PosterOk(nil, ROOMS), false)
eq("PosterOk nil cfg", R.PosterOk({ w = 1, c = 1, s = 1 }, nil), false)

-- Config.Rooms' own checks -------------------------------------------------------------------------------------------
eq("PosterWords: 12", #ROOMS.PosterWords, 12)
eq("PosterColors: 8", #ROOMS.PosterColors, 8)
eq("PosterColorNames: one a color", #ROOMS.PosterColorNames, #ROOMS.PosterColors)
eq("PosterColorInk: one a color", #ROOMS.PosterColorInk, #ROOMS.PosterColors)
eq("PosterStyleNames: one a style", #ROOMS.PosterStyleNames, ROOMS.PosterStyles)
for _, w in ipairs(ROOMS.PosterWords) do ok("PosterWords: " .. w .. " is short CAPS", string.match(w, "^%u+$") ~= nil and #w <= 6) end
-- the ink reads on its color: at least 3 : 1 (WCAG, large text), as the copy says
local function lum(c)
	local function ch(v) v = v / 255; return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4 end
	return 0.2126 * ch(c[1]) + 0.7152 * ch(c[2]) + 0.0722 * ch(c[3])
end
for i, c in ipairs(ROOMS.PosterColors) do
	local a, b2 = lum(c), lum(ROOMS.PosterColorInk[i])
	local ratio = (math.max(a, b2) + 0.05) / (math.min(a, b2) + 0.05)
	ok(string.format("PosterColorInk %s: contrast %.2f >= 3", ROOMS.PosterColorNames[i], ratio), ratio >= 3)
end
-- the bedroom's anchors: inside the room, unit facings, and every one the asset contract names
for _, name in ipairs({ "Entrance", "VisitorSpot", "CritterSpot", "Desk_Speaker_L", "Desk_Speaker_R", "Plaque_1", "Plaque_2", "Plaque_3" }) do
	local a = BED.anchors[name]
	ok("bedroom anchor " .. name .. " present", a ~= nil)
	if a then
		ok("bedroom anchor " .. name .. " inside the room", math.abs(a[1]) <= BED.size[1] / 2 + 1e-6 and math.abs(a[3]) <= BED.size[2] / 2 + 1e-6)
		ok("bedroom anchor " .. name .. " faces a unit direction", near(math.sqrt(a[4] ^ 2 + a[5] ^ 2), 1, 0.01))
	end
end
eq("bedroom plaques = its Plaque anchors", BED.plaques, 3)
for kind, k in pairs(ROOMS.Kinds) do
	for _, area in ipairs(k.grid or {}) do
		ok(kind .. " grid area inside the room", area[1] >= -k.size[1] / 2 and area[3] <= k.size[1] / 2 and area[2] >= -k.size[2] / 2 and area[4] <= k.size[2] / 2)
	end
end
-- the shared building's hall origin (Task 2, preflight m3): a fixed point, 1,000 studs west of the bedroom template's
-- x 4000 and 3,000 from the hub, past the hub's 1,024-stud streaming radius
eq("Hall: x, y, z", type(ROOMS.Hall) == "table" and string.format("%g,%g,%g", ROOMS.Hall[1], ROOMS.Hall[2], ROOMS.Hall[3]) or "none", "3000,0,0")
-- every kind (Task 2 wrote home's and real's for their stand-ins): a grid and keep areas, and the asset contract's
-- anchors, each inside the room with a unit facing; Plaque_1..plaques, Poster_1..posters, and BoothSpot / BoothCam when
-- the room has a booth; nothing past those counts. The keep areas cover the walkway from Entrance to VisitorSpot (0.5
-- either side of the line), CritterSpot and the stand-in's Spawn plate (RoomBuild's stand-in spawn: a literal here; the
-- bedroom's is the asset's own)
local SPAWNS = { bedroom = { 1.6216, 2.8378 }, home = { 6, 6.5 }, real = { 12, 10 } }
for _, kind in ipairs({ "bedroom", "home", "real" }) do
	local k = ROOMS.Kinds[kind]
	local a = k.anchors or {}
	ok(kind .. ": a grid", type(k.grid) == "table" and #k.grid > 0)
	ok(kind .. ": keep areas", type(k.keep) == "table" and #k.keep > 0)
	local want = { "Entrance", "VisitorSpot", "CritterSpot", "Desk_Speaker_L", "Desk_Speaker_R" }
	for i = 1, k.plaques do table.insert(want, "Plaque_" .. i) end
	for i = 1, k.posters do table.insert(want, "Poster_" .. i) end
	if k.booth then table.insert(want, "BoothSpot"); table.insert(want, "BoothCam") end
	local wantSet = setOf(want)
	for _, name in ipairs(want) do
		local v = a[name]
		ok(kind .. " anchor " .. name .. " present", v ~= nil)
		if v then
			ok(kind .. " anchor " .. name .. " inside the room", math.abs(v[1]) <= k.size[1] / 2 + 1e-6 and math.abs(v[3]) <= k.size[2] / 2 + 1e-6)
			ok(kind .. " anchor " .. name .. " faces a unit direction", near(math.sqrt(v[4] ^ 2 + v[5] ^ 2), 1, 0.01))
		end
	end
	for name in pairs(a) do ok(kind .. " anchor " .. name .. " is one the contract names", wantSet[name] == true) end
	local function covered(x, z)
		for _, area in ipairs(k.keep or {}) do
			if x >= area[1] and x <= area[3] and z >= area[2] and z <= area[4] then return true end
		end
		return false
	end
	local e, v, c = a.Entrance, a.VisitorSpot, a.CritterSpot
	if e and v and c then
		local ddx, ddz = e[1] - v[1], e[3] - v[3]
		local dl = math.sqrt(ddx * ddx + ddz * ddz)
		local qx, qz = ddz / dl, -ddx / dl
		local miss = 0
		for i = 0, 40 do
			for _, off in ipairs({ -0.5, 0, 0.5 }) do
				if not covered(v[1] + ddx * i / 40 + qx * off, v[3] + ddz * i / 40 + qz * off) then miss += 1 end
			end
		end
		eq(kind .. ": keep covers the Entrance -> VisitorSpot walkway (points missed)", miss, 0)
		ok(kind .. ": keep covers CritterSpot", covered(c[1], c[3]))
	end
	local sp = SPAWNS[kind]
	ok(kind .. ": keep covers the stand-in's spawn", covered(sp[1], sp[2]))
	-- every catalog item allowed in this kind of room has a spot in an empty one
	for _, it in ipairs(CAT.Items) do
		if it.kind == "floor" and (it.rooms == nil or table.find(it.rooms, kind) ~= nil) then
			local found = false
			for r = 0, 1 do
				for x = -math.ceil(k.size[1] / 2), math.ceil(k.size[1] / 2) do
					for z = -math.ceil(k.size[2] / 2), math.ceil(k.size[2] / 2) do
						if not found and R.Fits({}, F(it.id, x, z, r), k, CAT, ALL, kind, nil, ROOMS) then found = true end
					end
				end
			end
			ok("Fits " .. it.id .. ": has a spot in an empty " .. kind, found)
		end
	end
end

-- the launch catalog -------------------------------------------------------------------------------------------------
local WANT = { "rug", "plant", "beanbag", "record_crate", "low_shelf", "floor_lamp", "keyboard_stand", "tape_machine",
	"drum_machine", "pluck_synth", "chime_bells", "closet", "poster", "couch", "mic_stand" }
eq("catalog: the launch items, in order", idList(CAT.Items, "id"), table.concat(WANT, ","))
local GEAR_FOR = { tape_machine = "kit_tape", drum_machine = "kit_iron", pluck_synth = "voice_pluck", chime_bells = "voice_chime" }
local HOME_ONLY = { closet = true, poster = true, couch = true, mic_stand = true }
local gearSet, firstSet, roomSet, tierSet = setOf(GEAR_IDS), setOf(FIRSTS), {}, {}
for kind in pairs(ROOMS.Kinds) do roomSet[kind] = true end
for _, t in ipairs(TIERS) do tierSet[t.id] = true end
local seen, kindsUsed = {}, {}
local PART_KEYS = { n = true, s = true, cf = true, c = true, sh = true, m = true }
for _, it in ipairs(CAT.Items) do
	local id = tostring(it.id)
	ok("catalog " .. id .. ": unique id", not seen[id])
	seen[id] = true
	eq("catalog " .. id .. ": ById", CAT.ById[id], it)
	ok("catalog " .. id .. ": a name of at most 16 characters", type(it.name) == "string" and #it.name > 0 and #it.name <= 16)
	ok("catalog " .. id .. ": kind floor or wall", it.kind == "floor" or it.kind == "wall")
	ok("catalog " .. id .. ": whole-cell size", type(it.size) == "table" and it.size[1] >= 1 and it.size[2] >= 1 and it.size[1] % 1 == 0 and it.size[2] % 1 == 0)
	-- unlock rules (preflight F11): the rug and the plant from day one, gear items by their gear, decor by a first, a tier or a room
	local rule = it.unlock
	if id == "rug" or id == "plant" or HOME_ONLY[id] then
		eq("catalog " .. id .. ": no unlock rule", rule, nil)
	elseif GEAR_FOR[id] then
		eq("catalog " .. id .. ": unlocks by its gear", rule and rule.gear, GEAR_FOR[id])
	else
		ok("catalog " .. id .. ": a decor unlock (first, tier or room)", type(rule) == "table" and (rule.first ~= nil or rule.tier ~= nil or rule.room ~= nil))
	end
	if type(rule) == "table" then
		local n = 0
		for key, v in pairs(rule) do
			n += 1
			kindsUsed[key] = true
			if key == "gear" then ok("catalog " .. id .. ": gear " .. tostring(v) .. " is a Config.Gear id", gearSet[v] == true)
			elseif key == "first" then ok("catalog " .. id .. ": first " .. tostring(v) .. " is a Config.Life first", firstSet[v] == true)
			elseif key == "tier" then ok("catalog " .. id .. ": tier " .. tostring(v) .. " is a Config.Life tier", tierSet[v] == true)
			elseif key == "room" then ok("catalog " .. id .. ": room " .. tostring(v) .. " is a room kind", roomSet[v] == true)
			else ok("catalog " .. id .. ": unknown unlock key " .. tostring(key), false) end
		end
		eq("catalog " .. id .. ": one unlock rule", n, 1)
	end
	if HOME_ONLY[id] then
		eq("catalog " .. id .. ": home and real only", it.rooms and table.concat(it.rooms, ","), "home,real")
	else
		eq("catalog " .. id .. ": any room", it.rooms, nil)
	end
	for _, rk in ipairs(it.rooms or {}) do ok("catalog " .. id .. ": room " .. tostring(rk) .. " is a kind", roomSet[rk] == true) end
	-- parts: 1..12, names unique, VisitorLooks' shape, at most one Neon, no Light
	local parts = it.parts or {}
	ok("catalog " .. id .. ": 1.." .. ROOMS.ItemParts .. " parts (" .. #parts .. ")", #parts >= 1 and #parts <= ROOMS.ItemParts)
	local names, neon = {}, 0
	local lo, hi = { math.huge, math.huge, math.huge }, { -math.huge, -math.huge, -math.huge }
	for _, e in ipairs(parts) do
		local pn = tostring(e.n)
		ok("catalog " .. id .. "." .. pn .. ": unique name", type(e.n) == "string" and not names[e.n])
		names[pn] = true
		for key in pairs(e) do ok("catalog " .. id .. "." .. pn .. ": field " .. tostring(key) .. " (no Light, no extras)", PART_KEYS[key] == true) end
		ok("catalog " .. id .. "." .. pn .. ": material Neon or plain", e.m == nil or e.m == "Neon")
		if e.m == "Neon" then neon += 1 end
		ok("catalog " .. id .. "." .. pn .. ": shape", e.sh == nil or e.sh == "Ball" or e.sh == "Cylinder" or e.sh == "Wedge")
		ok("catalog " .. id .. "." .. pn .. ": size", type(e.s) == "table" and e.s[1] > 0 and e.s[2] > 0 and e.s[3] > 0)
		if e.sh == "Ball" then ok("catalog " .. id .. "." .. pn .. ": a Ball is uniform", e.s[1] == e.s[2] and e.s[2] == e.s[3]) end
		if e.sh == "Cylinder" then ok("catalog " .. id .. "." .. pn .. ": a Cylinder is round", e.s[2] == e.s[3]) end
		ok("catalog " .. id .. "." .. pn .. ": colour 0-255", type(e.c) == "table" and #e.c == 3 and e.c[1] >= 0 and e.c[1] <= 255 and e.c[2] >= 0 and e.c[2] <= 255 and e.c[3] >= 0 and e.c[3] <= 255)
		ok("catalog " .. id .. "." .. pn .. ": a 12-number placement", type(e.cf) == "table" and #e.cf == 12)
		if type(e.cf) == "table" and #e.cf == 12 and type(e.s) == "table" then
			-- the rotation is orthonormal (a real CFrame)
			local m = e.cf
			local rows = { { m[4], m[5], m[6] }, { m[7], m[8], m[9] }, { m[10], m[11], m[12] } }
			for i = 1, 3 do
				for j = 1, 3 do
					local dot = rows[i][1] * rows[j][1] + rows[i][2] * rows[j][2] + rows[i][3] * rows[j][3]
					ok("catalog " .. id .. "." .. pn .. ": orthonormal", near(dot, i == j and 1 or 0, 1e-6))
				end
			end
			for a = 1, 3 do
				local half = L.Math.Half(m, e.s, a)
				lo[a] = math.min(lo[a], m[a] - half)
				hi[a] = math.max(hi[a], m[a] + half)
			end
		end
	end
	ok("catalog " .. id .. ": at most one Neon part (" .. neon .. ")", neon <= 1)
	-- the footprint: a floor item stands on the floor at its footprint's centre, its x and z extents its size (within
	-- 0.5); a wall item hangs from the wall at z 0 into the room (-z), its x and y extents its size (width, height)
	if it.kind == "floor" then
		ok(string.format("catalog %s: x extent %.2f matches width %d", id, hi[1] - lo[1], it.size[1]), math.abs((hi[1] - lo[1]) - it.size[1]) <= 0.5)
		ok(string.format("catalog %s: z extent %.2f matches depth %d", id, hi[3] - lo[3], it.size[2]), math.abs((hi[3] - lo[3]) - it.size[2]) <= 0.5)
		ok(string.format("catalog %s: inside its cells (x %.2f..%.2f, z %.2f..%.2f)", id, lo[1], hi[1], lo[3], hi[3]),
			lo[1] >= -it.size[1] / 2 - 0.05 and hi[1] <= it.size[1] / 2 + 0.05 and lo[3] >= -it.size[2] / 2 - 0.05 and hi[3] <= it.size[2] / 2 + 0.05)
		ok(string.format("catalog %s: on the floor (bottom %.3f)", id, lo[2]), math.abs(lo[2]) <= 0.01)
	else
		ok(string.format("catalog %s: x extent %.2f matches width %d", id, hi[1] - lo[1], it.size[1]), math.abs((hi[1] - lo[1]) - it.size[1]) <= 0.5)
		ok(string.format("catalog %s: y extent %.2f matches height %d", id, hi[2] - lo[2], it.size[2]), math.abs((hi[2] - lo[2]) - it.size[2]) <= 0.5)
		ok(string.format("catalog %s: on the wall (z %.2f..%.2f)", id, lo[3], hi[3]), hi[3] <= 0.01 and lo[3] >= -0.5)
	end
end
-- the decor unlocks use all three kinds of rule (preflight F11)
ok("catalog: a decor item unlocks by a first", kindsUsed.first == true)
ok("catalog: a decor item unlocks by a tier", kindsUsed.tier == true)
ok("catalog: a decor item unlocks by a room", kindsUsed.room == true)
eq("catalog: the closet's max", CAT.ById.closet and CAT.ById.closet.max, 1)
eq("catalog: the poster hangs", CAT.ById.poster and CAT.ById.poster.kind, "wall")
local neonLamp = 0
for _, e in ipairs(CAT.ById.floor_lamp and CAT.ById.floor_lamp.parts or {}) do if e.m == "Neon" then neonLamp += 1 end end
eq("catalog: the floor lamp's shade is Neon", neonLamp, 1)

if #fails > 0 then error(#fails .. " room rules case(s) failed: " .. table.concat(fails, "; ")) end
print("SPEC OK: room rules (the maximal home " .. #maxJson .. " bytes)")
