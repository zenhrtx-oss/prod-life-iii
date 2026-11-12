-- OK Studio RoomCatalog (the Your Rooms plan, Task 1): the launch items a player places in their rooms, as data. Pure:
-- no Roblox globals and no require, so the server's room builder, the client's decorate mode and the luau CLI
-- (spec/room_rules_spec.lua) read the same recipes; Modules/RoomRules does the rules.
--
-- An item = { id, name (the edit bar's label: research/rooms/copy_2026-11-12.md §6.2), kind = "floor" | "wall",
--   size = { w, d } (a floor item's footprint in 1-stud cells, before its turn) or { width, height } (a wall item's
--   face, in studs), rooms = { kind, ... } (nil = any room), max = n (nil = no cap but the room's limit),
--   unlock = { gear = <Config.Gear id> } | { first = <Config.Life.Firsts id> } | { tier = <Config.Life.Tiers id> } |
--   { room = <room kind> } | nil (always open), parts = { Part } }.
-- Unlocks (preflight F11, spec §4.6 "furniture you place from day one"): the rug and the plant from day one; the other
--   decor by a first, a fame tier or a room you own; the gear-linked items by their gear; the closet, the poster, the
--   couch and the mic stand have no unlock but go only in the home and real studios (`rooms`). These picks are first
--   guesses for the user's approval.
-- A Part has VisitorLooks' shape: { n = name, s = { x, y, z }, cf = Tf, c = { r, g, b } (0-255), sh = "Ball" |
--   "Cylinder" | "Wedge" | nil (a block), m = "Neon" | nil (SmoothPlastic) }, at most 12 an item (Config.Rooms
--   .ItemParts), at most one Neon, and no Light anywhere (a room holds one light, its own bulb). A Tf is CFrame.new's
--   twelve components as a flat array (VisitorLooks' order). A Cylinder's axis is its x; a Ball is uniform.
-- A floor item's parts sit around its origin: the centre of its footprint on the floor (y 0 = the floor top), its
--   front facing -Z, its parts inside its cells. A wall item's origin is the centre of its face on the wall surface,
--   the room toward -Z: its parts sit at z 0 .. -0.1 and the poster's design (Task 13) goes on its Face part's -Z side.
local C = {}

-- the one transform helper (preflight R4): CFrame.new(x, y, z) * CFrame.Angles(rx, ry, rz), angles in degrees, as a Tf
local function Tf(x, y, z, rx, ry, rz)
	local ax, ay, az = math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0)
	local cx, sx, cy, sy, cz, sz = math.cos(ax), math.sin(ax), math.cos(ay), math.sin(ay), math.cos(az), math.sin(az)
	return { x, y, z,
		cy * cz, -cy * sz, sy,
		cx * sz + sx * sy * cz, cx * cz - sx * sy * sz, -sx * cy,
		sx * sz - cx * sy * cz, sx * cz + cx * sy * sz, cx * cy }
end
local UP = 90 -- a Cylinder turned 90 degrees about Z stands upright (its axis along y)

-- colours
local WOOD, DARK_WOOD, LIGHT_WOOD = { 150, 105, 70 }, { 92, 64, 46 }, { 196, 160, 116 }
local BLACK, CHARCOAL, METAL, WHITE = { 28, 28, 32 }, { 58, 58, 64 }, { 160, 162, 170 }, { 236, 236, 232 }
local LEAF, LEAF_DARK = { 72, 150, 78 }, { 46, 112, 58 }

C.Items = {
	-- decor -----------------------------------------------------------------------------------------------------------
	{ id = "rug", name = "Rug", kind = "floor", size = { 2, 2 }, parts = {
		{ n = "Rug", s = { 1.9, 0.06, 1.9 }, cf = Tf(0, 0.03, 0), c = { 168, 58, 70 } },
		{ n = "Band", s = { 1.4, 0.07, 1.4 }, cf = Tf(0, 0.035, 0), c = { 236, 196, 120 } },
		{ n = "Middle", s = { 0.9, 0.08, 0.9 }, cf = Tf(0, 0.04, 0), c = { 168, 58, 70 } },
	} },
	{ id = "plant", name = "Plant", kind = "floor", size = { 1, 1 }, parts = {
		{ n = "Pot", s = { 0.8, 0.8, 0.8 }, cf = Tf(0, 0.4, 0, 0, 0, UP), c = { 190, 96, 60 }, sh = "Cylinder" },
		{ n = "Soil", s = { 0.06, 0.68, 0.68 }, cf = Tf(0, 0.8, 0, 0, 0, UP), c = { 58, 40, 30 }, sh = "Cylinder" },
		{ n = "Stem", s = { 0.12, 1.1, 0.12 }, cf = Tf(0, 1.35, 0), c = LEAF_DARK },
		{ n = "Crown", s = { 0.9, 0.9, 0.9 }, cf = Tf(0, 2.0, 0), c = LEAF, sh = "Ball" },
		{ n = "LeafL", s = { 0.6, 0.6, 0.6 }, cf = Tf(-0.15, 1.6, 0.1), c = LEAF_DARK, sh = "Ball" },
		{ n = "LeafR", s = { 0.6, 0.6, 0.6 }, cf = Tf(0.15, 1.7, -0.1), c = LEAF_DARK, sh = "Ball" },
	} },
	{ id = "beanbag", name = "Beanbag", kind = "floor", size = { 2, 2 }, unlock = { first = "delivery" }, parts = {
		{ n = "Base", s = { 1.8, 0.7, 1.8 }, cf = Tf(0, 0.35, 0), c = { 222, 120, 44 } },
		{ n = "Seat", s = { 1.6, 1.6, 1.6 }, cf = Tf(0, 0.9, 0), c = { 222, 120, 44 }, sh = "Ball" },
		{ n = "Back", s = { 1.2, 1.2, 1.2 }, cf = Tf(0, 1.4, 0.3), c = { 204, 106, 36 }, sh = "Ball" },
	} },
	{ id = "record_crate", name = "Record crate", kind = "floor", size = { 1, 1 }, unlock = { first = "placement" }, parts = {
		{ n = "Floor", s = { 0.9, 0.08, 0.9 }, cf = Tf(0, 0.04, 0), c = LIGHT_WOOD },
		{ n = "Front", s = { 0.9, 0.7, 0.08 }, cf = Tf(0, 0.43, -0.41), c = LIGHT_WOOD },
		{ n = "Back", s = { 0.9, 0.7, 0.08 }, cf = Tf(0, 0.43, 0.41), c = LIGHT_WOOD },
		{ n = "Left", s = { 0.08, 0.7, 0.74 }, cf = Tf(-0.41, 0.43, 0), c = LIGHT_WOOD },
		{ n = "Right", s = { 0.08, 0.7, 0.74 }, cf = Tf(0.41, 0.43, 0), c = LIGHT_WOOD },
		{ n = "Sleeve1", s = { 0.7, 0.72, 0.04 }, cf = Tf(0, 0.46, -0.24), c = { 40, 40, 44 } },
		{ n = "Sleeve2", s = { 0.7, 0.72, 0.04 }, cf = Tf(0, 0.46, -0.12), c = { 220, 70, 60 } },
		{ n = "Sleeve3", s = { 0.7, 0.72, 0.04 }, cf = Tf(0, 0.46, 0), c = { 240, 200, 70 } },
		{ n = "Sleeve4", s = { 0.7, 0.72, 0.04 }, cf = Tf(0, 0.46, 0.12), c = { 70, 120, 220 } },
		{ n = "Sleeve5", s = { 0.7, 0.72, 0.04 }, cf = Tf(0, 0.46, 0.24), c = WHITE },
	} },
	{ id = "low_shelf", name = "Low shelf", kind = "floor", size = { 2, 1 }, unlock = { first = "delivery3" }, parts = {
		{ n = "SideL", s = { 0.1, 1.5, 0.9 }, cf = Tf(-0.9, 0.75, 0), c = WOOD },
		{ n = "SideR", s = { 0.1, 1.5, 0.9 }, cf = Tf(0.9, 0.75, 0), c = WOOD },
		{ n = "Back", s = { 1.7, 1.5, 0.06 }, cf = Tf(0, 0.75, 0.42), c = DARK_WOOD },
		{ n = "Bottom", s = { 1.7, 0.1, 0.84 }, cf = Tf(0, 0.05, -0.03), c = WOOD },
		{ n = "Middle", s = { 1.7, 0.08, 0.84 }, cf = Tf(0, 0.75, -0.03), c = WOOD },
		{ n = "Top", s = { 1.9, 0.1, 0.9 }, cf = Tf(0, 1.5, 0), c = WOOD },
		{ n = "BooksA", s = { 0.6, 0.5, 0.6 }, cf = Tf(-0.45, 1.04, 0), c = { 70, 120, 200 } },
		{ n = "BooksB", s = { 0.5, 0.55, 0.6 }, cf = Tf(0.45, 0.375, 0), c = { 200, 80, 70 } },
		{ n = "Speaker", s = { 0.4, 0.55, 0.4 }, cf = Tf(0.55, 1.825, 0), c = BLACK },
	} },
	{ id = "floor_lamp", name = "Floor lamp", kind = "floor", size = { 1, 1 }, unlock = { tier = "BUZZING" }, parts = {
		{ n = "Base", s = { 0.1, 0.8, 0.8 }, cf = Tf(0, 0.05, 0, 0, 0, UP), c = CHARCOAL, sh = "Cylinder" },
		{ n = "Pole", s = { 4.9, 0.12, 0.12 }, cf = Tf(0, 2.55, 0, 0, 0, UP), c = METAL, sh = "Cylinder" },
		{ n = "Shade", s = { 0.9, 0.9, 0.9 }, cf = Tf(0, 5.4, 0, 0, 0, UP), c = { 255, 222, 168 }, sh = "Cylinder", m = "Neon" },
		{ n = "Cap", s = { 0.08, 0.6, 0.6 }, cf = Tf(0, 5.89, 0, 0, 0, UP), c = CHARCOAL, sh = "Cylinder" },
	} },
	{ id = "keyboard_stand", name = "Keyboard stand", kind = "floor", size = { 3, 1 }, unlock = { room = "home" }, parts = {
		{ n = "FootL", s = { 0.16, 0.1, 0.9 }, cf = Tf(-1.1, 0.05, 0), c = CHARCOAL },
		{ n = "PostL", s = { 0.12, 2.5, 0.12 }, cf = Tf(-1.1, 1.35, 0), c = CHARCOAL },
		{ n = "FootR", s = { 0.16, 0.1, 0.9 }, cf = Tf(1.1, 0.05, 0), c = CHARCOAL },
		{ n = "PostR", s = { 0.12, 2.5, 0.12 }, cf = Tf(1.1, 1.35, 0), c = CHARCOAL },
		{ n = "Bar", s = { 2.3, 0.1, 0.12 }, cf = Tf(0, 2.55, 0), c = CHARCOAL },
		{ n = "Body", s = { 2.9, 0.24, 0.8 }, cf = Tf(0, 2.72, 0), c = BLACK },
		{ n = "Keys", s = { 2.6, 0.06, 0.42 }, cf = Tf(0, 2.87, -0.14), c = WHITE },
		{ n = "Panel", s = { 2.6, 0.05, 0.22 }, cf = Tf(0, 2.865, 0.24), c = CHARCOAL },
	} },
	-- gear-linked: they show once you own the gear ------------------------------------------------------------------
	{ id = "tape_machine", name = "Tape machine", kind = "floor", size = { 2, 1 }, unlock = { gear = "kit_tape" }, parts = {
		{ n = "Cabinet", s = { 1.8, 2.2, 0.9 }, cf = Tf(0, 1.1, 0), c = DARK_WOOD },
		{ n = "Deck", s = { 1.7, 1.5, 0.35 }, cf = Tf(0, 2.95, 0.2), c = METAL },
		{ n = "ReelL", s = { 0.06, 0.62, 0.62 }, cf = Tf(-0.42, 3.3, -0.005, 0, 90, 0), c = { 200, 202, 210 }, sh = "Cylinder" },
		{ n = "ReelR", s = { 0.06, 0.62, 0.62 }, cf = Tf(0.42, 3.3, -0.005, 0, 90, 0), c = { 200, 202, 210 }, sh = "Cylinder" },
		{ n = "HubL", s = { 0.08, 0.16, 0.16 }, cf = Tf(-0.42, 3.3, -0.05, 0, 90, 0), c = BLACK, sh = "Cylinder" },
		{ n = "HubR", s = { 0.08, 0.16, 0.16 }, cf = Tf(0.42, 3.3, -0.05, 0, 90, 0), c = BLACK, sh = "Cylinder" },
		{ n = "Tape", s = { 0.84, 0.04, 0.03 }, cf = Tf(0, 2.98, 0.0), c = { 70, 46, 36 } },
		{ n = "Meter", s = { 0.5, 0.22, 0.04 }, cf = Tf(0, 2.55, 0.005), c = { 236, 186, 90 } },
		{ n = "Knobs", s = { 1.2, 0.08, 0.06 }, cf = Tf(0, 2.32, 0.0), c = BLACK },
	} },
	{ id = "drum_machine", name = "Drum machine", kind = "floor", size = { 2, 1 }, unlock = { gear = "kit_iron" }, parts = {
		{ n = "Top", s = { 1.8, 0.12, 0.9 }, cf = Tf(0, 2.4, 0), c = WOOD },
		{ n = "Leg1", s = { 0.1, 2.34, 0.1 }, cf = Tf(-0.8, 1.17, -0.35), c = CHARCOAL },
		{ n = "Leg2", s = { 0.1, 2.34, 0.1 }, cf = Tf(0.8, 1.17, -0.35), c = CHARCOAL },
		{ n = "Leg3", s = { 0.1, 2.34, 0.1 }, cf = Tf(-0.8, 1.17, 0.35), c = CHARCOAL },
		{ n = "Leg4", s = { 0.1, 2.34, 0.1 }, cf = Tf(0.8, 1.17, 0.35), c = CHARCOAL },
		{ n = "Machine", s = { 1.3, 0.25, 0.7 }, cf = Tf(0, 2.585, 0), c = { 70, 72, 80 } },
		{ n = "Pads", s = { 0.7, 0.05, 0.5 }, cf = Tf(-0.22, 2.735, 0.02), c = { 240, 140, 60 } },
		{ n = "Screen", s = { 0.36, 0.03, 0.16 }, cf = Tf(0.4, 2.725, -0.15), c = { 120, 230, 200 }, m = "Neon" },
		{ n = "Knobs", s = { 0.36, 0.05, 0.2 }, cf = Tf(0.4, 2.735, 0.12), c = BLACK },
	} },
	{ id = "pluck_synth", name = "Pluck synth", kind = "floor", size = { 2, 1 }, unlock = { gear = "voice_pluck" }, parts = {
		{ n = "FootL", s = { 0.16, 0.1, 0.9 }, cf = Tf(-0.7, 0.05, 0), c = CHARCOAL },
		{ n = "PostL", s = { 0.12, 2.55, 0.12 }, cf = Tf(-0.7, 1.375, 0), c = CHARCOAL },
		{ n = "FootR", s = { 0.16, 0.1, 0.9 }, cf = Tf(0.7, 0.05, 0), c = CHARCOAL },
		{ n = "PostR", s = { 0.12, 2.55, 0.12 }, cf = Tf(0.7, 1.375, 0), c = CHARCOAL },
		{ n = "Bar", s = { 1.5, 0.1, 0.12 }, cf = Tf(0, 2.6, 0), c = CHARCOAL },
		{ n = "Body", s = { 1.9, 0.28, 0.8 }, cf = Tf(0, 2.79, 0), c = { 214, 214, 208 } },
		{ n = "Keys", s = { 1.35, 0.06, 0.42 }, cf = Tf(0.22, 2.96, -0.14), c = WHITE },
		{ n = "Controls", s = { 0.36, 0.05, 0.5 }, cf = Tf(-0.7, 2.955, -0.05), c = CHARCOAL },
		{ n = "Stripe", s = { 1.9, 0.05, 0.1 }, cf = Tf(0, 2.955, 0.32), c = { 60, 190, 200 } },
	} },
	{ id = "chime_bells", name = "Chime bells", kind = "floor", size = { 2, 1 }, unlock = { gear = "voice_chime" }, parts = {
		{ n = "FootL", s = { 0.16, 0.1, 0.9 }, cf = Tf(-0.85, 0.05, 0), c = DARK_WOOD },
		{ n = "PostL", s = { 0.12, 4.0, 0.12 }, cf = Tf(-0.85, 2.1, 0), c = DARK_WOOD },
		{ n = "FootR", s = { 0.16, 0.1, 0.9 }, cf = Tf(0.85, 0.05, 0), c = DARK_WOOD },
		{ n = "PostR", s = { 0.12, 4.0, 0.12 }, cf = Tf(0.85, 2.1, 0), c = DARK_WOOD },
		{ n = "Bar", s = { 1.82, 0.12, 0.12 }, cf = Tf(0, 4.04, 0), c = DARK_WOOD },
		{ n = "Tube1", s = { 1.6, 0.12, 0.12 }, cf = Tf(-0.6, 3.18, 0, 0, 0, UP), c = { 222, 192, 96 }, sh = "Cylinder" },
		{ n = "Tube2", s = { 1.45, 0.12, 0.12 }, cf = Tf(-0.36, 3.255, 0, 0, 0, UP), c = { 222, 192, 96 }, sh = "Cylinder" },
		{ n = "Tube3", s = { 1.3, 0.12, 0.12 }, cf = Tf(-0.12, 3.33, 0, 0, 0, UP), c = { 222, 192, 96 }, sh = "Cylinder" },
		{ n = "Tube4", s = { 1.15, 0.12, 0.12 }, cf = Tf(0.12, 3.405, 0, 0, 0, UP), c = { 222, 192, 96 }, sh = "Cylinder" },
		{ n = "Tube5", s = { 1.0, 0.12, 0.12 }, cf = Tf(0.36, 3.48, 0, 0, 0, UP), c = { 222, 192, 96 }, sh = "Cylinder" },
		{ n = "Tube6", s = { 0.85, 0.12, 0.12 }, cf = Tf(0.6, 3.555, 0, 0, 0, UP), c = { 222, 192, 96 }, sh = "Cylinder" },
	} },
	-- home and real studios only ------------------------------------------------------------------------------------
	{ id = "closet", name = "Closet", kind = "floor", size = { 3, 2 }, rooms = { "home", "real" }, max = 1, parts = {
		{ n = "Plinth", s = { 2.7, 0.25, 1.7 }, cf = Tf(0, 0.125, 0), c = DARK_WOOD },
		{ n = "Body", s = { 2.8, 6.3, 1.8 }, cf = Tf(0, 3.4, 0), c = WOOD },
		{ n = "Top", s = { 2.95, 0.15, 1.9 }, cf = Tf(0, 6.625, 0), c = DARK_WOOD },
		{ n = "DoorL", s = { 1.36, 6.0, 0.06 }, cf = Tf(-0.69, 3.4, -0.92), c = LIGHT_WOOD },
		{ n = "DoorR", s = { 1.36, 6.0, 0.06 }, cf = Tf(0.69, 3.4, -0.92), c = LIGHT_WOOD },
		{ n = "HandleL", s = { 0.08, 0.6, 0.06 }, cf = Tf(-0.12, 3.4, -0.97), c = METAL },
		{ n = "HandleR", s = { 0.08, 0.6, 0.06 }, cf = Tf(0.12, 3.4, -0.97), c = METAL },
	} },
	{ id = "poster", name = "Poster", kind = "wall", size = { 3, 4 }, rooms = { "home", "real" }, parts = {
		{ n = "Frame", s = { 3.0, 4.0, 0.05 }, cf = Tf(0, 0, -0.025), c = BLACK },
		{ n = "Face", s = { 2.8, 3.8, 0.04 }, cf = Tf(0, 0, -0.07), c = WHITE },
	} },
	{ id = "couch", name = "Couch", kind = "floor", size = { 5, 2 }, rooms = { "home", "real" }, parts = {
		{ n = "FootL", s = { 0.3, 0.3, 1.6 }, cf = Tf(-2.2, 0.15, 0), c = DARK_WOOD },
		{ n = "FootR", s = { 0.3, 0.3, 1.6 }, cf = Tf(2.2, 0.15, 0), c = DARK_WOOD },
		{ n = "Base", s = { 4.8, 0.8, 1.8 }, cf = Tf(0, 0.7, 0), c = { 70, 84, 120 } },
		{ n = "Back", s = { 4.8, 1.6, 0.45 }, cf = Tf(0, 1.9, 0.675), c = { 70, 84, 120 } },
		{ n = "ArmL", s = { 0.5, 0.8, 1.8 }, cf = Tf(-2.15, 1.5, 0), c = { 62, 74, 108 } },
		{ n = "ArmR", s = { 0.5, 0.8, 1.8 }, cf = Tf(2.15, 1.5, 0), c = { 62, 74, 108 } },
		{ n = "SeatL", s = { 1.85, 0.3, 1.3 }, cf = Tf(-0.95, 1.25, -0.2), c = { 84, 100, 140 } },
		{ n = "SeatR", s = { 1.85, 0.3, 1.3 }, cf = Tf(0.95, 1.25, -0.2), c = { 84, 100, 140 } },
		{ n = "Pillow", s = { 0.9, 0.8, 0.25 }, cf = Tf(-1.4, 1.8, 0.3), c = { 236, 186, 90 } },
	} },
	{ id = "mic_stand", name = "Mic stand", kind = "floor", size = { 1, 1 }, rooms = { "home", "real" }, parts = {
		{ n = "Base", s = { 0.08, 0.9, 0.9 }, cf = Tf(0, 0.04, 0, 0, 0, UP), c = CHARCOAL, sh = "Cylinder" },
		{ n = "Pole", s = { 4.5, 0.1, 0.1 }, cf = Tf(0, 2.33, 0, 0, 0, UP), c = METAL, sh = "Cylinder" },
		{ n = "Clip", s = { 0.16, 0.18, 0.16 }, cf = Tf(0, 4.66, 0), c = BLACK },
		{ n = "Mic", s = { 0.4, 0.2, 0.2 }, cf = Tf(0, 4.8, -0.05, 0, 90, 0), c = CHARCOAL, sh = "Cylinder" },
		{ n = "Grille", s = { 0.3, 0.3, 0.3 }, cf = Tf(0, 4.8, -0.3), c = METAL, sh = "Ball" },
	} },
}

C.ById = {}
for _, item in ipairs(C.Items) do C.ById[item.id] = item end

return C
