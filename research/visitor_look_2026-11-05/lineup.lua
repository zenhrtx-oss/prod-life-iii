-- Prod Life III, walk-in visitor look: an Edit-mode lineup to compare looks (proposal only; nothing in the game changes).
-- Run once through the Studio MCP execute tool; it is idempotent (an old OK_LookLineup is destroyed first) and returns a
-- one-line summary. Requires nothing from the project. Remove everything with lineup_remove.lua.
--
-- Everything lives in ONE Folder, workspace.OK_LookLineup (Archivable = false, so it never saves with the place), in
-- four closed rooms in empty space west of the hub (the rooms span world X -926 .. -704, Y -4 .. 32, Z -34 .. 16;
-- the clash check scans a slightly bigger box, X -928 .. -702, Y -6 .. 34, Z -40 .. 16). The hub is X 0..94,
-- the West Suite sits near X -4, Z -41, Studio Two near X 11, Z 60..100 and the room test far out at +X, so nothing
-- overlaps; the script also checks the box first and builds nothing if any other part is in it.
-- The rooms are closed (floor, walls, roof) on purpose: build/03_lighting.lua keeps ClockTime 0 and OutdoorAmbient
-- (8, 8, 12), so open sky here renders near-black; indoors gets Lighting.Ambient (78, 72, 88) like the hub. Lighting is
-- not touched. Studio here renders no local lights, so colours are picked to read under that flat ambient.
--   GROUP    the three rows on bleacher tiers, front to back: TODAY (today's blocky figure, copied from
--            Modules/Visitor.lua), A · VINYL TOY, B · LANKY SHAPES. The same five visitors in the same order in every
--            row: STIRRUP PEONY, YOUR MOTHER, A KID FROM YOUR OLD BLOCK, THE GOSSIP BLOGGER, A REP FROM NITE OWL ENERGY
--            (fiction names; the rep's sponsor is NITE OWL ENERGY). A sign at the left end of each row, a card mock at
--            the right end (the walk-in card's header with a ViewportFrame portrait instead of the brown square).
--   STAGE A  row A alone, close-up: name plate and speech bubble on STIRRUP PEONY (offset derived from the figure's
--            top, as notes.md proposes), names on the stage front, the row's card mock on the back wall.
--   STAGE B  the same for row B.
--   CARDS    the portraits: per direction, the five visitors as the card would frame them (big), each with a small
--            copy at about card scale. TODAY shows what the card shows today (a skin square on the visitor colour).
-- In every row the kid is posed mid-stride (swing 0.45 rad) to show the limbs are separate parts.
--
-- Cameras (Edit mode, set workspace.CurrentCamera.CFrame; computed for FieldOfView 70, framed to fit 1.43 to 1.78
-- aspect viewports). The script also returns them in its summary, computed from the same constants:
--   whole lineup  CFrame.lookAt(Vector3.new(-900, 18, -24),   Vector3.new(-900, 8.5, 1))
--   row A close   CFrame.lookAt(Vector3.new(-840, 4.9, -13.5), Vector3.new(-840, 4.3, 0))
--   row B close   CFrame.lookAt(Vector3.new(-780, 5.4, -14),   Vector3.new(-780, 4.8, 0))
--   portraits     CFrame.lookAt(Vector3.new(-720, 7.2, -4.5),  Vector3.new(-720, 7.2, 6))
-- ViewportFrames light themselves (their own Ambient and LightColor), so the portraits look brighter than the room;
-- the in-game card would look like the portraits, the room like the hub without its lamps.
--
-- Figure rules for A and B: anchored, CanCollide/CanQuery/CanTouch false, CastShadow false, SmoothPlastic or Neon,
-- Part/WedgePart only (Ball, Cylinder, Block, Wedge), no Light, Humanoid, Sound, mesh, decal or asset id; 8..16 parts
-- each (build/t42_play_server.lua's limit); limbs are separate parts posed by the same formula as Visitor's _pose,
-- generalised to { swing, hang = CFrame, rot = CFrame } (see notes.md).

local ORIGIN = Vector3.new(-900, 0, 0)
local FOLDER = "OK_LookLineup"
local MAX_PARTS = 16
local V, CF, RGB, rad = Vector3.new, CFrame.new, Color3.fromRGB, math.rad
local I = CFrame.identity
local ROTZ = CFrame.Angles(0, 0, math.pi / 2) -- a Cylinder runs along X; this stands it up (or lays a disc flat)
local ROTY = CFrame.Angles(0, math.pi / 2, 0) -- turns a Cylinder's axis to Z: a disc facing forward

-- a local placement: the figure faces -Z (its LookVector); angles in degrees (CFrame.Angles order, Z then Y then X)
local function at(x, y, z, rx, ry, rz)
	return CF(x, y, z) * CFrame.Angles(rad(rx or 0), rad(ry or 0), rad(rz or 0))
end

-- UITheme's values (Modules/UITheme), copied so this needs no require
local T = { bg = RGB(10, 10, 14), panel = RGB(18, 18, 24), line = RGB(40, 40, 52), text = RGB(235, 235, 235),
	muted = RGB(150, 150, 165), accent = RGB(255, 60, 160) }
local FONT, FONTB = Enum.Font.GothamBold, Enum.Font.GothamBlack

-- the five visitors (Data/WalkIns W.Visitors, fiction roster; sig/color are today's values)
local CAST = {
	{ id = "navx", name = "STIRRUP PEONY", style = "country trap", color = { 255, 110, 180 }, sig = "cowboy_hat",
	  tag = "COUNTRY TRAP · WANTS A PLACEMENT", line = "yo i need a beat for my next single. you got something for me?" },
	{ id = "mom", name = "YOUR MOTHER", style = "home cooking", color = { 255, 170, 120 }, sig = "apron" },
	{ id = "homekid", name = "A KID FROM YOUR OLD BLOCK", style = "up and coming", color = { 60, 180, 160 }, sig = "headphones" },
	{ id = "blogger", name = "THE GOSSIP BLOGGER", style = "music blog", color = { 255, 200, 0 }, sig = "none" },
	{ id = "rep", name = "A REP FROM NITE OWL ENERGY", style = "brand deals", color = { 40, 50, 80 }, sig = "suit" },
}

-- part entries: { n = name, s = size, cf = placement, c = colour, sh = "Ball" | "Cylinder" | "Wedge" | nil (block),
-- m = material?, sw = swing sign?, hang = CFrame?, rot = CFrame? }. A limb (sw set) is placed
-- base * cf * Angles(swing * sw, 0, 0) * hang * (rot or identity): cf is its pivot (hip, shoulder). Anything else is
-- base * cf, its rotation already in cf.
local function find(P, n) for i, e in ipairs(P) do if e.n == n then return e, i end end; return nil, nil end
local function drop(P, n) local _, i = find(P, n); if i then table.remove(P, i) end end
local function ball(n, d, pos, c, m) return { n = n, s = V(d, d, d), cf = CF(pos), c = c, sh = "Ball", m = m } end

-- TODAY: Modules/Visitor.lua's build() and the five SIGS it uses, copied as they are ----------------------------------
local DARK, SKIN, EYE = RGB(30, 30, 36), RGB(150, 110, 85), RGB(12, 12, 14)
local SUIT, WHITE = RGB(34, 34, 42), RGB(235, 235, 240)
local TODAY_SIGS = {
	cowboy_hat = function(c) local brown = RGB(92, 62, 38); return {
		{ "HatBrim", V(0.12, 2.3, 2.3), at(0, 5.3, 0, 0, 0, 90), brown, "Cylinder" },
		{ "HatCrown", V(1.1, 0.75, 1.1), at(0, 5.7, 0), brown },
		{ "HatBand", V(1.14, 0.15, 1.14), at(0, 5.42, 0), c },
	} end,
	apron = function(c) local cloth = RGB(240, 236, 226); return {
		{ "Bib", V(0.9, 1.0, 0.06), at(0, 3.65, -0.49), cloth },
		{ "Skirt", V(1.7, 1.3, 0.06), at(0, 2.45, -0.49), cloth },
		{ "Pocket", V(0.5, 0.35, 0.05), at(0, 2.55, -0.53), c },
	} end,
	headphones = function(c) return {
		{ "Band", V(1.5, 0.18, 0.3), at(0, 5.55, 0), DARK },
		{ "CupL", V(0.3, 0.6, 0.6), at(-0.68, 4.9, 0), c },
		{ "CupR", V(0.3, 0.6, 0.6), at(0.68, 4.9, 0), c },
	} end,
	suit = function(c) return {
		{ "Shirt", V(0.5, 1.2, 0.05), at(0, 3.6, -0.47), WHITE },
		{ "Tie", V(0.2, 1.0, 0.06), at(0, 3.5, -0.5), c },
	} end,
	none = function() return {} end,
}
local function lookToday(v)
	local color = RGB(v.color[1], v.color[2], v.color[3])
	local body = (v.sig == "suit") and SUIT or color
	local P = {
		{ n = "LegL", s = V(0.6, 2.2, 0.6), cf = CF(-0.35, 2.2, 0), c = DARK, sw = 1, hang = CF(0, -1.1, 0) },
		{ n = "LegR", s = V(0.6, 2.2, 0.6), cf = CF(0.35, 2.2, 0), c = DARK, sw = -1, hang = CF(0, -1.1, 0) },
		{ n = "Torso", s = V(1.6, 2.0, 0.9), cf = CF(0, 3.2, 0), c = body },
		{ n = "ArmL", s = V(0.5, 1.9, 0.5), cf = CF(-1.05, 4.1, 0), c = body, sw = -1, hang = CF(0, -0.95, 0) },
		{ n = "ArmR", s = V(0.5, 1.9, 0.5), cf = CF(1.05, 4.1, 0), c = body, sw = 1, hang = CF(0, -0.95, 0) },
		{ n = "Head", s = V(1.2, 1.2, 1.2), cf = CF(0, 4.85, 0), c = SKIN, sh = "Ball" },
		{ n = "EyeL", s = V(0.1, 0.2, 0.14), cf = CF(-0.22, 4.95, -0.57), c = EYE },
		{ n = "EyeR", s = V(0.1, 0.2, 0.14), cf = CF(0.22, 4.95, -0.57), c = EYE },
	}
	for _, s in ipairs(TODAY_SIGS[v.sig](color)) do table.insert(P, { n = s[1], s = s[2], cf = s[3], c = s[4], sh = s[5] }) end
	return { parts = P, head = "Head", primary = "Torso", plate = 2.4 }
end

-- A · VINYL TOY: big round head, capsule body (cylinder on a ball), stubby cylinder legs, ball hands --------------------
-- 12 body parts: LegL, LegR, Hips, Torso, ArmL, ArmR, HandL, HandR, Head, Hair, EyeL, EyeR; up to 4 signature parts
local A_ADULT = { legLen = 1.15, legD = 0.66, legX = 0.4, hipD = 1.6, torsoH = 1.45, torsoD = 1.6, headD = 2.2,
	armLen = 1.05, armD = 0.5, handD = 0.62, eyeD = 0.42, eyeX = 0.42, tilt = 9 }
local A_KID = { legLen = 0.75, legD = 0.58, legX = 0.34, hipD = 1.35, torsoH = 1.0, torsoD = 1.35, headD = 2.0,
	armLen = 0.8, armD = 0.42, handD = 0.52, eyeD = 0.4, eyeX = 0.38, tilt = 9 }
local A_EYE = RGB(20, 20, 26)
local function with(base, over) local t = table.clone(base); for k, v in pairs(over) do t[k] = v end; return t end

-- the body; col = { skin, hair, top, sleeve?, bottom, legs, hand? }; returns the part list and key heights
local function aBody(o, col)
	local P, K = {}, {}
	local hipY = o.legLen
	K.hipsY = hipY + o.hipD * 0.3
	K.torsoTop = K.hipsY + o.torsoH
	K.headY = K.torsoTop + o.headD * 0.42
	K.headR = o.headD / 2
	K.torsoR = o.torsoD / 2
	K.handDrop = o.armLen + o.handD * 0.13
	local sx, sy = o.torsoD / 2 + o.armD * 0.25, K.torsoTop - 0.22
	K.pivotL, K.pivotR = at(-sx, sy, 0, 0, 0, -o.tilt), at(sx, sy, 0, 0, 0, o.tilt)
	local function add(e) table.insert(P, e) end
	add { n = "LegL", s = V(o.legLen, o.legD, o.legD), cf = CF(-o.legX, hipY, 0), c = col.legs, sh = "Cylinder", sw = 1, hang = CF(0, -o.legLen / 2, 0), rot = ROTZ }
	add { n = "LegR", s = V(o.legLen, o.legD, o.legD), cf = CF(o.legX, hipY, 0), c = col.legs, sh = "Cylinder", sw = -1, hang = CF(0, -o.legLen / 2, 0), rot = ROTZ }
	add { n = "Hips", s = V(o.hipD, o.hipD, o.hipD), cf = CF(0, K.hipsY, 0), c = col.bottom, sh = "Ball" }
	add { n = "Torso", s = V(o.torsoH, o.torsoD, o.torsoD), cf = CF(0, K.hipsY + o.torsoH / 2, 0) * ROTZ, c = col.top, sh = "Cylinder" }
	add { n = "ArmL", s = V(o.armLen, o.armD, o.armD), cf = K.pivotL, c = col.sleeve or col.top, sh = "Cylinder", sw = -1, hang = CF(0, -o.armLen / 2, 0), rot = ROTZ }
	add { n = "ArmR", s = V(o.armLen, o.armD, o.armD), cf = K.pivotR, c = col.sleeve or col.top, sh = "Cylinder", sw = 1, hang = CF(0, -o.armLen / 2, 0), rot = ROTZ }
	add { n = "HandL", s = V(o.handD, o.handD, o.handD), cf = K.pivotL, c = col.hand or col.skin, sh = "Ball", sw = -1, hang = CF(0, -K.handDrop, 0) }
	add { n = "HandR", s = V(o.handD, o.handD, o.handD), cf = K.pivotR, c = col.hand or col.skin, sh = "Ball", sw = 1, hang = CF(0, -K.handDrop, 0) }
	add(ball("Head", o.headD, V(0, K.headY, 0), col.skin))
	add(ball("Hair", o.headD * 1.05, V(0, K.headY + o.headD * 0.077, o.headD * 0.068), col.hair))
	local r, ey = K.headR, -0.06
	local ez = -math.sqrt(r * r - o.eyeX * o.eyeX - ey * ey) + o.eyeD * 0.14
	add(ball("EyeL", o.eyeD, V(-o.eyeX, K.headY + ey, ez), A_EYE))
	add(ball("EyeR", o.eyeD, V(o.eyeX, K.headY + ey, ez), A_EYE))
	return P, K
end

-- an arm posed and held still (no swing): its part and its hand, and where the hand is
local function holdArm(P, side, pivot, o, K)
	local arm, hand = find(P, "Arm" .. side), find(P, "Hand" .. side)
	arm.cf, arm.sw, arm.hang, arm.rot = pivot * CF(0, -o.armLen / 2, 0) * ROTZ, nil, nil, nil
	hand.cf, hand.sw, hand.hang = pivot * CF(0, -K.handDrop, 0), nil, nil
	return hand.cf.Position
end

local A_LOOKS = {}
A_LOOKS.navx = function() -- STIRRUP PEONY: a peony bloom in the hair, a sunflower neckerchief, mint jacket, denim, tan boots
	local P, K = aBody(A_ADULT, { skin = RGB(232, 177, 130), hair = RGB(58, 38, 30), top = RGB(130, 214, 170),
		bottom = RGB(64, 98, 158), legs = RGB(176, 118, 66) })
	table.insert(P, { n = "Bandana", s = V(0.72, 0.72, 0.1), cf = at(0, K.torsoTop - 0.3, -K.torsoR - 0.03, 0, 0, 45), c = RGB(255, 196, 48) })
	local c = V(-0.72, K.headY + 0.78, -0.45)
	table.insert(P, ball("PetalA", 0.9, c + V(0.1, 0.12, 0.05), RGB(255, 105, 170)))
	table.insert(P, ball("PetalB", 0.8, c + V(-0.32, -0.2, 0.15), RGB(255, 150, 200)))
	table.insert(P, ball("Heart", 0.42, c + V(-0.06, 0, -0.4), RGB(196, 30, 110)))
	return P
end
A_LOOKS.mom = function() -- YOUR MOTHER: a big bun, cream apron, carries a covered dish in both hands (arms held)
	local o = with(A_ADULT, { torsoD = 1.75, hipD = 1.8, legLen = 1.05, torsoH = 1.4 })
	local P, K = aBody(o, { skin = RGB(156, 102, 68), hair = RGB(46, 32, 28), top = RGB(255, 150, 110),
		bottom = RGB(122, 62, 96), legs = RGB(70, 52, 52) })
	local sx, sy = o.torsoD / 2 + o.armD * 0.25, K.torsoTop - 0.22
	local hl = holdArm(P, "L", at(-sx, sy, 0, 70, 0, 15), o, K)
	local hr = holdArm(P, "R", at(sx, sy, 0, 70, 0, -15), o, K)
	local mid = (hl + hr) / 2 + V(0, -0.12, -0.32)
	table.insert(P, { n = "Apron", s = V(1.25, 1.6, 0.08), cf = CF(0, K.hipsY + 0.25, -o.torsoD / 2 - 0.1), c = RGB(245, 238, 220) })
	table.insert(P, ball("Bun", 1.0, V(0, K.headY + 1.1, 0.42), RGB(46, 32, 28)))
	table.insert(P, { n = "Dish", s = V(0.42, 1.35, 1.35), cf = CF(mid) * ROTZ, c = RGB(205, 55, 45), sh = "Cylinder" })
	table.insert(P, ball("Lid", 1.0, mid + V(0, 0.12, 0), RGB(205, 205, 215)))
	return P
end
A_LOOKS.homekid = function() -- A KID FROM YOUR OLD BLOCK: short, teal hoodie, orange cap, headphones round his neck, backpack
	local orange = RGB(255, 140, 40)
	local P, K = aBody(A_KID, { skin = RGB(198, 134, 90), hair = orange, top = RGB(60, 180, 160),
		bottom = RGB(52, 52, 62), legs = RGB(52, 52, 62) })
	table.insert(P, { n = "CapBill", s = V(1.05, 0.12, 0.8), cf = at(0, K.headY + 0.5, -0.98, -6, 0, 0), c = orange })
	local cup = RGB(40, 40, 48)
	table.insert(P, { n = "CupL", s = V(0.26, 0.62, 0.62), cf = CF(-0.5, K.torsoTop + 0.02, -0.55) * ROTY, c = cup, sh = "Cylinder" })
	table.insert(P, { n = "CupR", s = V(0.26, 0.62, 0.62), cf = CF(0.5, K.torsoTop + 0.02, -0.55) * ROTY, c = cup, sh = "Cylinder" })
	table.insert(P, { n = "Backpack", s = V(1.15, 1.1, 0.5), cf = CF(0, K.hipsY + 0.75, K.torsoR + 0.22), c = orange })
	return P
end
A_LOOKS.blogger = function() -- THE GOSSIP BLOGGER: purple bob, round shades, yellow dress, phone up (filming), REC light
	local o = A_ADULT
	local P, K = aBody(o, { skin = RGB(255, 214, 180), hair = RGB(120, 60, 180), top = RGB(255, 200, 0),
		bottom = RGB(255, 200, 0), legs = RGB(30, 30, 36) })
	local hair = find(P, "Hair")
	hair.s, hair.cf = V(2.4, 2.4, 2.4), CF(0, K.headY + 0.18, 0.22)
	drop(P, "EyeL"); drop(P, "EyeR")
	local lens = RGB(16, 16, 22)
	local lz = -math.sqrt(K.headR ^ 2 - 0.42 ^ 2 - 0.03 ^ 2) - 0.035
	table.insert(P, { n = "LensL", s = V(0.1, 0.72, 0.72), cf = CF(-0.42, K.headY + 0.03, lz) * ROTY, c = lens, sh = "Cylinder" })
	table.insert(P, { n = "LensR", s = V(0.1, 0.72, 0.72), cf = CF(0.42, K.headY + 0.03, lz) * ROTY, c = lens, sh = "Cylinder" })
	table.insert(P, { n = "Bridge", s = V(0.22, 0.08, 0.08), cf = CF(0, K.headY + 0.1, lz - 0.02), c = lens })
	local sx, sy = o.torsoD / 2 + o.armD * 0.25, K.torsoTop - 0.22
	local hand = holdArm(P, "R", at(sx, sy, 0, 120, 0, 40), o, K)
	local phone = CF(hand + V(0.02, 0.42, -0.12)) * CFrame.Angles(0, rad(-10), 0)
	table.insert(P, { n = "Phone", s = V(0.52, 0.88, 0.1), cf = phone, c = RGB(255, 70, 150) })
	table.insert(P, { n = "PhoneLight", s = V(0.13, 0.13, 0.04), cf = phone * CF(-0.14, 0.3, -0.07), c = RGB(255, 255, 255), m = Enum.Material.Neon })
	return P
end
A_LOOKS.rep = function() -- A REP FROM {sponsor}: light grey suit, white shirt, Neon sponsor tie, a swag bag that swings
	local o = A_ADULT
	local P, K = aBody(o, { skin = RGB(110, 70, 48), hair = RGB(22, 20, 22), top = RGB(176, 180, 190),
		bottom = RGB(150, 154, 166), legs = RGB(36, 36, 42) })
	local hair = find(P, "Hair")
	hair.s, hair.cf = V(2.28, 2.28, 2.28), CF(0.08, K.headY + 0.2, 0.18)
	table.insert(P, { n = "Shirt", s = V(0.62, 0.95, 0.06), cf = CF(0, K.torsoTop - 0.42, -K.torsoR - 0.02), c = WHITE })
	table.insert(P, { n = "Tie", s = V(0.2, 0.8, 0.07), cf = CF(0, K.torsoTop - 0.5, -K.torsoR - 0.06), c = RGB(180, 110, 255), m = Enum.Material.Neon })
	table.insert(P, { n = "Bag", s = V(0.35, 0.85, 0.9), cf = K.pivotL, c = RGB(120, 60, 210), sw = -1, hang = CF(0, -(K.handDrop + 0.5), 0) })
	return P
end

-- B · LANKY SHAPES: tall, thin and angular; small block heads, a wedge nose, long block limbs, big shoes ---------------
-- 13 body parts: LegL, LegR, ShoeL, ShoeR, Torso, Neck, Head, Hair, EyeL, EyeR, Nose, ArmL, ArmR; up to 3 signature parts
local B_ADULT = { legLen = 2.75, legW = 0.34, legX = 0.3, shoe = V(0.5, 0.32, 0.95), torsoW = 1.1, torsoH = 2.0,
	torsoD = 0.55, coat = 0, neckH = 0.38, neckD = 0.26, head = V(0.8, 0.95, 0.75), armLen = 2.25, armW = 0.26, tilt = 4 }
local B_KID = with(B_ADULT, { legLen = 1.55, legW = 0.36, shoe = V(0.58, 0.42, 1.0), torsoW = 1.32, torsoH = 1.55,
	torsoD = 0.66, neckH = 0.22, head = V(0.85, 0.95, 0.8), armLen = 1.5, armW = 0.3 })
local B_EYE = RGB(16, 16, 20)

local function bBody(o, col)
	local P, K = {}, {}
	local sole = o.shoe.Y
	local hipY = sole + o.legLen - 0.02
	K.torsoTop = hipY - 0.15 + o.torsoH
	K.torsoBottom = hipY - 0.15 - o.coat
	K.headY = K.torsoTop + o.neckH - 0.06 + o.head.Y / 2
	K.headTop = K.headY + o.head.Y / 2
	local sx, sy = o.torsoW / 2 + o.armW / 2 + 0.02, K.torsoTop - 0.15
	K.pivotL, K.pivotR = at(-sx, sy, 0, 0, 0, -o.tilt), at(sx, sy, 0, 0, 0, o.tilt)
	K.sx, K.sy = sx, sy
	local function add(e) table.insert(P, e) end
	add { n = "LegL", s = V(o.legW, o.legLen, o.legW), cf = CF(-o.legX, hipY, 0), c = col.legs, sw = 1, hang = CF(0, -o.legLen / 2, 0) }
	add { n = "LegR", s = V(o.legW, o.legLen, o.legW), cf = CF(o.legX, hipY, 0), c = col.legs, sw = -1, hang = CF(0, -o.legLen / 2, 0) }
	add { n = "ShoeL", s = o.shoe, cf = CF(-o.legX, hipY, 0), c = col.shoes, sw = 1, hang = CF(0, -(hipY - sole / 2), -0.18) }
	add { n = "ShoeR", s = o.shoe, cf = CF(o.legX, hipY, 0), c = col.shoes, sw = -1, hang = CF(0, -(hipY - sole / 2), -0.18) }
	add { n = "Torso", s = V(o.torsoW, K.torsoTop - K.torsoBottom, o.torsoD), cf = CF(0, (K.torsoTop + K.torsoBottom) / 2, 0), c = col.top }
	add { n = "Neck", s = V(o.neckH, o.neckD, o.neckD), cf = CF(0, K.torsoTop + o.neckH / 2 - 0.04, 0) * ROTZ, c = col.skin, sh = "Cylinder" }
	add { n = "Head", s = o.head, cf = CF(0, K.headY, 0), c = col.skin }
	add { n = "Hair", s = V(o.head.X + 0.06, 0.3, o.head.Z + 0.06), cf = CF(0, K.headTop + 0.12, 0.03), c = col.hair }
	local fz = -o.head.Z / 2
	add { n = "EyeL", s = V(0.1, 0.18, 0.05), cf = CF(-0.18, K.headY + 0.06, fz - 0.015), c = B_EYE }
	add { n = "EyeR", s = V(0.1, 0.18, 0.05), cf = CF(0.18, K.headY + 0.06, fz - 0.015), c = B_EYE }
	add { n = "Nose", s = V(0.12, 0.2, 0.15), cf = CF(0, K.headY - 0.1, fz - 0.075), c = col.nose or col.skin, sh = "Wedge" }
	add { n = "ArmL", s = V(o.armW, o.armLen, o.armW), cf = K.pivotL, c = col.sleeve or col.top, sw = -1, hang = CF(0, -o.armLen / 2, 0) }
	add { n = "ArmR", s = V(o.armW, o.armLen, o.armW), cf = K.pivotR, c = col.sleeve or col.top, sw = 1, hang = CF(0, -o.armLen / 2, 0) }
	return P, K
end
local function holdLong(P, side, pivot, o)
	local arm = find(P, "Arm" .. side)
	arm.cf, arm.sw, arm.hang = pivot * CF(0, -o.armLen / 2, 0), nil, nil
	return (pivot * CF(0, -o.armLen, 0)).Position
end

local B_LOOKS = {}
B_LOOKS.navx = function() -- STIRRUP PEONY: flat-top, long mint coat, the peony bloom, a sunflower neckerchief
	local o = with(B_ADULT, { coat = 0.9 })
	local P, K = bBody(o, { skin = RGB(232, 177, 130), hair = RGB(58, 38, 30), top = RGB(130, 214, 170),
		legs = RGB(64, 98, 158), shoes = RGB(176, 118, 66) })
	local hair = find(P, "Hair")
	hair.s, hair.cf = V(0.86, 0.55, 0.8), CF(0, K.headTop + 0.24, 0.03)
	table.insert(P, ball("Bloom", 0.78, V(-0.42, K.headTop + 0.28, -0.18), RGB(255, 105, 170)))
	table.insert(P, ball("Heart", 0.34, V(-0.42, K.headTop + 0.25, -0.52), RGB(196, 30, 110)))
	table.insert(P, { n = "Bandana", s = V(0.5, 0.5, 0.06), cf = at(0, K.torsoTop - 0.05, -o.torsoD / 2 - 0.03, 0, 0, 45), c = RGB(255, 196, 48) })
	return P
end
B_LOOKS.mom = function() -- YOUR MOTHER: a bun on top, long coral dress, cream apron, a food box held low in front
	local o = with(B_ADULT, { coat = 1.1, torsoW = 1.2 })
	local P, K = bBody(o, { skin = RGB(156, 102, 68), hair = RGB(46, 32, 28), top = RGB(255, 150, 110),
		legs = RGB(70, 52, 52), shoes = RGB(60, 40, 40) })
	find(P, "Hair").s = V(0.86, 0.28, 0.8)
	table.insert(P, ball("Bun", 0.62, V(0, K.headTop + 0.48, 0.08), RGB(46, 32, 28)))
	table.insert(P, { n = "Apron", s = V(0.85, 1.9, 0.05), cf = CF(0, K.torsoBottom + 1.05, -o.torsoD / 2 - 0.03), c = RGB(245, 238, 220) })
	local hl = holdLong(P, "L", at(-K.sx, K.sy, 0, 40, 0, 12), o)
	local hr = holdLong(P, "R", at(K.sx, K.sy, 0, 40, 0, -12), o)
	table.insert(P, { n = "FoodBox", s = V(1.0, 0.55, 0.75), cf = CF((hl + hr) / 2 + V(0, 0.2, -0.1)), c = RGB(120, 190, 230) })
	return P
end
B_LOOKS.homekid = function() -- A KID FROM YOUR OLD BLOCK: short, wide teal hoodie, white chunky shoes, orange headphones
	local P, K = bBody(B_KID, { skin = RGB(198, 134, 90), hair = RGB(26, 22, 24), top = RGB(60, 180, 160),
		legs = RGB(52, 52, 62), shoes = RGB(240, 240, 245) })
	local hair = find(P, "Hair")
	hair.s = V(0.9, 0.28, 0.85)
	local orange, hx = RGB(255, 140, 40), B_KID.head.X / 2 + 0.13
	table.insert(P, { n = "CupL", s = V(0.26, 1.1, 0.62), cf = CF(-hx, K.headY + 0.2, 0.02), c = orange })
	table.insert(P, { n = "CupR", s = V(0.26, 1.1, 0.62), cf = CF(hx, K.headY + 0.2, 0.02), c = orange })
	table.insert(P, { n = "Band", s = V(2 * hx + 0.26, 0.18, 0.28), cf = CF(0, K.headY + 0.84, 0.02), c = RGB(40, 40, 48) })
	return P
end
B_LOOKS.blogger = function() -- THE GOSSIP BLOGGER: long purple bob, shades, yellow jacket, pink skirt, phone held high
	local o = with(B_ADULT, { torsoW = 0.95 })
	local P, K = bBody(o, { skin = RGB(255, 214, 180), hair = RGB(120, 60, 180), top = RGB(255, 200, 0),
		legs = RGB(30, 30, 36), shoes = RGB(240, 240, 245) })
	local hair = find(P, "Hair")
	hair.s, hair.cf = V(0.96, 1.2, 0.72), CF(0, K.headY + 0.08, 0.2)
	for _, n in ipairs({ "EyeL", "EyeR" }) do
		local e = find(P, n)
		e.s = V(0.3, 0.2, 0.05); e.cf = CF((n == "EyeL" and -0.2 or 0.2), K.headY + 0.07, -o.head.Z / 2 - 0.015)
	end
	table.insert(P, { n = "Skirt", s = V(1.25, 0.85, 0.7), cf = CF(0, K.torsoBottom + 0.05, 0), c = RGB(255, 70, 150) })
	local hand = holdLong(P, "R", at(K.sx, K.sy, 0, 135, 0, 12), o)
	local phone = CF(hand + V(0, 0.3, -0.05)) * CFrame.Angles(0, rad(-10), 0)
	table.insert(P, { n = "Phone", s = V(0.42, 0.75, 0.08), cf = phone, c = RGB(255, 70, 150) })
	table.insert(P, { n = "PhoneLight", s = V(0.11, 0.11, 0.03), cf = phone * CF(-0.11, 0.26, -0.055), c = RGB(255, 255, 255), m = Enum.Material.Neon })
	return P
end
B_LOOKS.rep = function() -- A REP FROM {sponsor}: broad grey suit, a quiff, Neon sponsor tie, a swag bag that swings
	local o = with(B_ADULT, { torsoW = 1.38 })
	local P, K = bBody(o, { skin = RGB(110, 70, 48), hair = RGB(22, 20, 22), top = RGB(176, 180, 190),
		legs = RGB(150, 154, 166), shoes = RGB(30, 30, 34) })
	local hair = find(P, "Hair")
	hair.s, hair.cf, hair.sh = V(0.84, 0.42, 0.8), CF(0, K.headTop + 0.2, 0.02) * CFrame.Angles(0, math.pi, 0), "Wedge"
	table.insert(P, { n = "Shirt", s = V(0.42, 0.65, 0.05), cf = CF(0, K.torsoTop - 0.33, -o.torsoD / 2 - 0.02), c = WHITE })
	table.insert(P, { n = "Tie", s = V(0.14, 0.8, 0.06), cf = CF(0, K.torsoTop - 0.45, -o.torsoD / 2 - 0.05), c = RGB(180, 110, 255), m = Enum.Material.Neon })
	table.insert(P, { n = "Bag", s = V(0.32, 0.8, 0.85), cf = K.pivotL, c = RGB(120, 60, 210), sw = -1, hang = CF(0, -(o.armLen + 0.38), 0) })
	return P
end

-- the looks per row: { parts, head, primary, plate? } ----------------------------------------------------------------
local ROWS = {
	{ key = "TODAY", title = "TODAY", sub = "TODAY'S BLOCKS", look = function(v) return lookToday(v) end },
	{ key = "A", title = "A · VINYL TOY", sub = "VINYL TOY", look = function(v) return { parts = A_LOOKS[v.id](), head = "Head", primary = "Hips" } end },
	{ key = "B", title = "B · LANKY SHAPES", sub = "LANKY SHAPES", look = function(v) return { parts = B_LOOKS[v.id](), head = "Head", primary = "Torso" } end },
}

-- posing and building ------------------------------------------------------------------------------------------------
local function poseCF(e, base, swing)
	if e.sw then return base * e.cf * CFrame.Angles((swing or 0) * e.sw, 0, 0) * e.hang * (e.rot or I) end
	return base * e.cf
end
local function extentY(cf, s) -- half the height of the part's world box
	return (math.abs(cf.RightVector.Y) * s.X + math.abs(cf.UpVector.Y) * s.Y + math.abs(cf.LookVector.Y) * s.Z) / 2
end
-- head height, head radius and the figure's top, in the figure's own frame (feet at y 0)
local function lookInfo(look)
	local info = { top = 0, count = #look.parts }
	for _, e in ipairs(look.parts) do
		local cf = poseCF(e, I, 0)
		info.top = math.max(info.top, cf.Y + extentY(cf, e.s))
		if e.n == look.head then info.headY, info.headR = cf.Y, e.s.Y / 2 end
	end
	-- the name plate: today's StudsOffset is 2.4 (its centre 1.2 above the cowboy hat's crown); the same clearance
	-- above each figure's own top gives this offset from the head centre
	info.plate = look.plate or (math.floor((info.top - info.headY + 1.2) * 100 + 0.5) / 100)
	return info
end

local built = { parts = 0, figures = 0, viewports = 0 }
local function figure(parent, look, base, swing, name)
	local m = Instance.new("Model")
	m.Name = name
	local head, primary = nil, nil
	for _, e in ipairs(look.parts) do
		local p = Instance.new(e.sh == "Wedge" and "WedgePart" or "Part")
		p.Name = e.n; p.Size = e.s; p.Color = e.c
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
		p.Material = e.m or Enum.Material.SmoothPlastic
		if e.sh == "Ball" then p.Shape = Enum.PartType.Ball elseif e.sh == "Cylinder" then p.Shape = Enum.PartType.Cylinder end
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		p.CFrame = poseCF(e, base, swing)
		p.Parent = m
		built.parts += 1
		if e.n == look.head then head = p end
		if e.n == look.primary then primary = p end
	end
	m.PrimaryPart = primary
	m.Parent = parent
	built.figures += 1
	return m, head
end

-- the environment: closed rooms of plain parts (they block the sky, so CastShadow stays on) ---------------------------
local root
local function new(class, props, parent)
	local i = Instance.new(class)
	for k, v in pairs(props) do i[k] = v end
	i.Parent = parent
	return i
end
local function slab(parent, name, cf, size, color, mat)
	local p = new("Part", { Name = name, Size = size, CFrame = cf, Color = color, Material = mat or Enum.Material.SmoothPlastic,
		Anchored = true, TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth }, nil)
	p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.Parent = parent
	return p
end
local WALL, FLOOR, BACK = RGB(118, 114, 128), RGB(84, 80, 92), RGB(138, 134, 150)
-- a room centred on local x = cx: inside x cx-hw..cx+hw, z z0..z1, y 0..h; walls, floor and roof 4 studs thick
local function room(name, cx, hw, z0, z1, h)
	local m = new("Model", { Name = name }, root)
	local w, d = 2 * hw + 8, (z1 - z0) + 8
	local zc = (z0 + z1) / 2
	local o = ORIGIN + V(cx, 0, 0)
	slab(m, "Floor", CF(o + V(0, -2, zc)), V(w, 4, d), FLOOR)
	slab(m, "Roof", CF(o + V(0, h + 2, zc)), V(w, 4, d), WALL)
	slab(m, "WallBack", CF(o + V(0, h / 2, z1 + 2)), V(w, h + 8, 4), BACK)
	slab(m, "WallFront", CF(o + V(0, h / 2, z0 - 2)), V(w, h + 8, 4), WALL)
	slab(m, "WallLeft", CF(o + V(-hw - 2, h / 2, zc)), V(4, h + 8, d), WALL)
	slab(m, "WallRight", CF(o + V(hw + 2, h / 2, zc)), V(4, h + 8, d), WALL)
	return m, o
end

-- text on a part's front face (SurfaceGui, unlit). lines = { { text, heightScale, font, colour } }
local function sign(parent, name, cf, size, lines, bg)
	local p = slab(parent, name, cf, size, bg or RGB(24, 24, 30))
	p.CastShadow = false
	local g = new("SurfaceGui", { Name = "Sign", Face = Enum.NormalId.Front, SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = 50, LightInfluence = 0 }, p)
	local y = 0.06
	for i, l in ipairs(lines) do
		new("TextLabel", { Name = "Line" .. i, BackgroundTransparency = 1, Position = UDim2.fromScale(0.05, y), Size = UDim2.fromScale(0.9, l[2]),
			Font = l[3] or FONTB, Text = l[1], TextColor3 = l[4] or T.text, TextScaled = true, TextWrapped = true }, g)
		y += l[2]
	end
	return p
end

-- the card's portrait: a ViewportFrame with a head-and-shoulders copy of the figure (built fresh, not cloned)
local function portrait(parent, look, pos, px, corner)
	local vf = new("ViewportFrame", { Name = "Portrait", Position = pos, Size = UDim2.fromOffset(px, px), BackgroundColor3 = T.bg,
		BorderSizePixel = 0, Ambient = RGB(165, 165, 175), LightColor = RGB(255, 246, 236), LightDirection = V(-1, -1, -1) }, nil)
	new("UICorner", { CornerRadius = UDim.new(0, corner) }, vf)
	local info = lookInfo(look)
	figure(vf, look, CFrame.Angles(0, math.pi + rad(14), 0), 0, "Figure") -- faces +Z, toward the camera, a little turned
	local bottom = info.headY - info.headR * 1.7
	local top = info.top + 0.1
	local half = (top - bottom) / 2 * 1.2
	local cy = (top + bottom) / 2
	local cam = new("Camera", { Name = "PortraitCam", FieldOfView = 30 }, vf)
	local dist = half / math.tan(rad(15))
	cam.CFrame = CFrame.lookAt(V(0, cy + half * 0.08, dist), V(0, cy, 0))
	vf.CurrentCamera = cam
	vf.Parent = parent
	built.viewports += 1
	return vf
end
-- today's card portrait: a skin square on the visitor's colour (WalkInUI's Face and Shirt frames), scaled
local function flatPortrait(parent, v, pos, px, corner)
	local f = new("Frame", { Name = "Portrait", Position = pos, Size = UDim2.fromOffset(px, px), BackgroundColor3 = T.bg,
		BorderSizePixel = 0, ClipsDescendants = true }, parent)
	new("UICorner", { CornerRadius = UDim.new(0, corner) }, f)
	local k = px / 44
	new("Frame", { Name = "Face", Position = UDim2.fromOffset(11 * k, 8 * k), Size = UDim2.fromOffset(22 * k, 22 * k), BackgroundColor3 = SKIN, BorderSizePixel = 0 }, f)
	new("Frame", { Name = "Shirt", Position = UDim2.fromOffset(5 * k, 31 * k), Size = UDim2.fromOffset(34 * k, 16 * k),
		BackgroundColor3 = RGB(v.color[1], v.color[2], v.color[3]), BorderSizePixel = 0 }, f)
	return f
end

-- a card mock: the walk-in card's header and his line at 2x (WalkInUI: 500 px wide card, 44 px portrait at 14 px pad)
local function cardMock(parent, name, cf, width, row, v)
	local W, H = 1000, 280
	local p = slab(parent, name, cf, V(width, width * H / W, 0.2), T.panel)
	p.CastShadow = false
	local g = new("SurfaceGui", { Name = "Card", Face = Enum.NormalId.Front, SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = W / width, LightInfluence = 0 }, p)
	local card = new("Frame", { Name = "Card", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.panel, BorderSizePixel = 0 }, g)
	new("UICorner", { CornerRadius = UDim.new(0, 28) }, card)
	new("UIStroke", { Color = T.line, Thickness = 3 }, card)
	local pos = UDim2.fromOffset(28, 24)
	if row.key == "TODAY" then flatPortrait(card, v, pos, 88, 16) else portrait(card, row.look(v), pos, 88, 16) end
	new("TextLabel", { Name = "Name", BackgroundTransparency = 1, Position = UDim2.fromOffset(136, 26), Size = UDim2.fromOffset(600, 44),
		Font = FONTB, TextSize = 34, TextColor3 = T.accent, TextXAlignment = Enum.TextXAlignment.Left, Text = v.name }, card)
	new("TextLabel", { Name = "Tag", BackgroundTransparency = 1, Position = UDim2.fromOffset(136, 78), Size = UDim2.fromOffset(600, 26),
		Font = FONT, TextSize = 20, TextColor3 = T.muted, TextXAlignment = Enum.TextXAlignment.Left, Text = v.tag or string.upper(v.style) }, card)
	local chip = new("TextLabel", { Name = "Header", BackgroundColor3 = T.bg, BorderSizePixel = 0, Position = UDim2.fromOffset(W - 28 - 176, 46),
		Size = UDim2.fromOffset(176, 44), Font = FONTB, TextSize = 20, TextColor3 = T.muted, Text = "1 OF 8 TODAY" }, card)
	new("UICorner", { CornerRadius = UDim.new(0, 22) }, chip)
	new("TextLabel", { Name = "Line", BackgroundTransparency = 1, Position = UDim2.fromOffset(28, 128), Size = UDim2.fromOffset(W - 56, 76),
		Font = FONT, TextSize = 28, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
		Text = "\u{201C}" .. (v.line or "") .. "\u{201D}" }, card)
	new("TextLabel", { Name = "Which", BackgroundTransparency = 1, Position = UDim2.fromOffset(28, 222), Size = UDim2.fromOffset(W - 56, 34),
		Font = FONTB, TextSize = 22, TextColor3 = RGB(110, 110, 125), TextXAlignment = Enum.TextXAlignment.Left,
		Text = row.key == "TODAY" and "THE CARD TODAY: A SKIN SQUARE ON HIS COLOUR" or ("THE CARD WITH " .. row.title .. ": A VIEWPORT PORTRAIT") }, card)
	return p
end

-- the name plate and the speech bubble, as Visitor.lua's decorate() builds them (MaxDistance 80, LightInfluence 0)
local function decorate(model, head, v, offset, line)
	local plate = new("BillboardGui", { Name = "NamePlate", Size = UDim2.fromOffset(200, 46), StudsOffset = V(0, offset, 0),
		MaxDistance = 80, LightInfluence = 0, Adornee = head }, model)
	local bg = new("Frame", { Name = "Plate", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.accent, BackgroundTransparency = 0.1, BorderSizePixel = 0 }, plate)
	new("UICorner", {}, bg)
	new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }, bg)
	new("TextLabel", { Name = "NameText", BackgroundTransparency = 1, Font = FONTB, TextColor3 = T.text, TextScaled = true, Size = UDim2.fromScale(1, 0.62), Text = v.name }, bg)
	new("TextLabel", { Name = "StyleText", BackgroundTransparency = 1, Font = FONT, TextColor3 = T.text, TextScaled = true, TextTransparency = 0.15,
		Size = UDim2.fromScale(1, 0.38), Position = UDim2.fromScale(0, 0.62), Text = v.style }, bg)
	local bubble = new("BillboardGui", { Name = "Bubble", Size = UDim2.fromOffset(240, 64), StudsOffset = V(0, offset, 0),
		SizeOffset = Vector2.new(0, (46 / 2 + 6 + 64 / 2) / 64), MaxDistance = 80, LightInfluence = 0, Adornee = head, Enabled = line ~= nil }, model)
	local l = new("TextLabel", { Name = "Line", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0.15, BackgroundColor3 = T.panel, Font = FONT,
		TextColor3 = T.text, TextScaled = true, TextWrapped = true, Text = line or "" }, bubble)
	new("UICorner", {}, l)
	new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }, l)
end

-- layout constants (local to each room's centre; the cameras below are computed from these) -------------------------
-- the cameras look along +Z, so world +X is the screen's left: STIRRUP PEONY (first) stands at +9, on the left
local COLS = { 9, 4.5, 0, -4.5, -9 }
local ROOM = {
	GROUP = { cx = 0, hw = 22, z0 = -30, z1 = 12, h = 28 },
	A = { cx = 60, hw = 20, z0 = -22, z1 = 8, h = 22 },
	B = { cx = 120, hw = 20, z0 = -22, z1 = 8, h = 22 },
	CARDS = { cx = 180, hw = 12, z0 = -10, z1 = 6, h = 16 },
}
local TIERS = { { z = -6, top = 1 }, { z = 0, top = 6 }, { z = 6, top = 11 } } -- TODAY, A, B on the bleacher
local STRIDE = 0.45 -- the kid's pose (radians), mid-stride
local GROUP_YAW, STAGE_YAW = 8, 14
local function w(cx, x, y, z) return ORIGIN + V(cx + x, y, z) end
local CAMS = {
	{ "whole", w(ROOM.GROUP.cx, 0, 18, -24), w(ROOM.GROUP.cx, 0, 8.5, 1) },
	{ "A", w(ROOM.A.cx, 0, 4.9, -13.5), w(ROOM.A.cx, 0, 4.3, 0) },
	{ "B", w(ROOM.B.cx, 0, 5.4, -14), w(ROOM.B.cx, 0, 4.8, 0) },
	{ "portraits", w(ROOM.CARDS.cx, 0, 7.2, -4.5), w(ROOM.CARDS.cx, 0, 7.2, 6) },
}

-- 0. a fresh start, and nothing of anyone else's in the box -------------------------------------------------------
local old = workspace:FindFirstChild(FOLDER)
while old do old:Destroy(); old = workspace:FindFirstChild(FOLDER) end
local lo = ORIGIN + V(ROOM.GROUP.cx - ROOM.GROUP.hw - 6, -6, -40)
local hi = ORIGIN + V(ROOM.CARDS.cx + ROOM.CARDS.hw + 6, 34, 16)
local clash, clashName = 0, nil
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("BasePart") and not d:IsA("Terrain") then
		local p, r = d.Position, d.Size.Magnitude / 2
		if p.X + r > lo.X and p.X - r < hi.X and p.Y + r > lo.Y and p.Y - r < hi.Y and p.Z + r > lo.Z and p.Z - r < hi.Z then
			clash += 1; clashName = clashName or d:GetFullName()
		end
	end
end
if clash > 0 then
	return string.format("ABORT: %d part(s) already inside the lineup box %s..%s (e.g. %s); nothing built", clash, tostring(lo), tostring(hi), clashName)
end
root = new("Folder", { Name = FOLDER, Archivable = false }, nil)

-- 1. every look, checked before anything is placed ------------------------------------------------------------------
local LOOKS, INFO, counts, plates = {}, {}, {}, {}
for _, row in ipairs(ROWS) do
	LOOKS[row.key], INFO[row.key], counts[row.key], plates[row.key] = {}, {}, {}, {}
	for i, v in ipairs(CAST) do
		local look = row.look(v)
		local n = #look.parts
		assert(n >= 8 and n <= MAX_PARTS, row.key .. " " .. v.id .. ": " .. n .. " parts (want 8.." .. MAX_PARTS .. ")")
		for _, e in ipairs(look.parts) do
			assert(e.sh ~= "Ball" or (e.s.X == e.s.Y and e.s.Y == e.s.Z), row.key .. " " .. v.id .. " " .. e.n .. ": a Ball must be uniform")
			assert(e.sh ~= "Cylinder" or e.s.Y == e.s.Z, row.key .. " " .. v.id .. " " .. e.n .. ": a Cylinder needs Y == Z")
			assert(not e.sw or e.hang, row.key .. " " .. v.id .. " " .. e.n .. ": a limb needs a hang")
		end
		LOOKS[row.key][i], INFO[row.key][i] = look, lookInfo(look)
		counts[row.key][i] = n
		plates[row.key][i] = INFO[row.key][i].plate
	end
end

-- 2. GROUP: the three rows on bleacher tiers --------------------------------------------------------------------------
do
	local R = ROOM.GROUP
	local m, o = room("Group", R.cx, R.hw, R.z0, R.z1, R.h)
	for t, row in ipairs(ROWS) do
		local tier = TIERS[t]
		slab(m, "Tier_" .. row.key, CF(o + V(0, tier.top / 2, tier.z)), V(2 * R.hw - 2, tier.top, 6), t == 1 and RGB(70, 66, 78) or (t == 2 and RGB(78, 74, 86) or RGB(86, 82, 96)))
		local rowM = new("Model", { Name = "Row_" .. row.key }, m)
		for i, v in ipairs(CAST) do
			local base = CF(o + V(COLS[i], tier.top, tier.z)) * CFrame.Angles(0, rad(GROUP_YAW), 0)
			figure(rowM, LOOKS[row.key][i], base, v.id == "homekid" and STRIDE or 0, row.key .. "_" .. v.id)
		end
		local tilt = CFrame.Angles(rad(18), 0, 0)
		sign(rowM, "RowSign", CF(o + V(15, tier.top + 1.9, tier.z)) * tilt, V(5.4, 3.4, 0.3),
			{ { row.key == "TODAY" and "TODAY" or string.sub(row.title, 1, 1), 0.52, FONTB, row.key == "TODAY" and T.muted or T.accent },
				{ row.sub, 0.36, FONTB } })
		cardMock(rowM, "Card", CF(o + V(-15.3, tier.top + 1.0, tier.z)) * tilt, 6.6, row, CAST[1])
	end
	sign(m, "Title", CF(o + V(0, R.h - 4.6, R.z1 - 0.2)), V(30, 4.4, 0.2),
		{ { "WALK-IN VISITORS · LOOK OPTIONS", 0.5, FONTB }, { "PROPOSAL ONLY · NOTHING IN THE GAME CHANGED · SAME FIVE VISITORS IN EVERY ROW", 0.3, FONT, T.muted } })
end

-- 3. STAGE A and STAGE B: one row each, name plate and bubble on STIRRUP PEONY -----------------------------------------
for t = 2, 3 do
	local row = ROWS[t]
	local R = ROOM[row.key]
	local m, o = room("Stage_" .. row.key, R.cx, R.hw, R.z0, R.z1, R.h)
	local stage = slab(m, "Stage", CF(o + V(0, 0.6, 0)), V(2 * R.hw - 4, 1.2, 6), RGB(70, 66, 78))
	local g = new("SurfaceGui", { Name = "Names", Face = Enum.NormalId.Front, SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = 60, LightInfluence = 0 }, stage)
	local rowM = new("Model", { Name = "Row_" .. row.key }, m)
	for i, v in ipairs(CAST) do
		local base = CF(o + V(COLS[i], 1.2, 0)) * CFrame.Angles(0, rad(STAGE_YAW), 0)
		local fig, head = figure(rowM, LOOKS[row.key][i], base, v.id == "homekid" and STRIDE or 0, row.key .. "_" .. v.id)
		if i == 1 then decorate(fig, head, v, INFO[row.key][i].plate, v.line) end
		new("TextLabel", { Name = "Name_" .. v.id, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromOffset((R.hw - 2 - COLS[i]) * 60, 4), Size = UDim2.fromOffset(4.3 * 60, 64),
			Font = FONTB, TextColor3 = T.text, TextScaled = true, TextWrapped = true, Text = v.name }, g)
	end
	sign(m, "Title", CF(o + V(-8.5, 12.3, R.z1 - 0.2)), V(15, 2.6, 0.2),
		{ { row.title, 0.6, FONTB, T.accent }, { "16 PARTS OR FEWER A FIGURE · PEONY WEARS THE NAME PLATE AND BUBBLE", 0.28, FONT, T.muted } })
	cardMock(m, "Card", CF(o + V(-9.5, 8.9, R.z1 - 0.2)), 8, row, CAST[1])
end

-- 4. CARDS: per direction, the five as the card would frame them, big and at about card scale -------------------------
do
	local R = ROOM.CARDS
	local m, o = room("Cards", R.cx, R.hw, R.z0, R.z1, R.h)
	local PW = 1700 -- the panel canvas is 1700 x 420 px
	for t, row in ipairs(ROWS) do
		local cy = ({ 11.8, 7.2, 2.6 })[t]
		local part = slab(m, "Panel_" .. row.key, CF(o + V(0, cy, R.z1 - 0.2)), V(17, 4.2, 0.2), T.bg)
		part.CastShadow = false
		local g = new("SurfaceGui", { Name = "Panel", Face = Enum.NormalId.Front, SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
			PixelsPerStud = PW / 17, LightInfluence = 0 }, part)
		local bgF = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.bg, BorderSizePixel = 0 }, g)
		new("TextLabel", { Name = "Title", BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 40), Size = UDim2.fromOffset(180, 150),
			Font = FONTB, TextScaled = true, TextColor3 = row.key == "TODAY" and T.muted or T.accent, Text = row.key }, bgF)
		new("TextLabel", { Name = "Sub", BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 200), Size = UDim2.fromOffset(180, 170),
			Font = FONTB, TextScaled = true, TextWrapped = true, TextColor3 = T.text,
			Text = row.key == "TODAY" and "WHAT THE CARD SHOWS NOW" or (row.sub .. " IN THE CARD") }, bgF)
		for i, v in ipairs(CAST) do
			local tile = new("Frame", { Name = "Tile_" .. v.id, Position = UDim2.fromOffset(206 + (i - 1) * 298, 16), Size = UDim2.fromOffset(286, 388),
				BackgroundColor3 = T.panel, BorderSizePixel = 0 }, bgF)
			new("UICorner", { CornerRadius = UDim.new(0, 20) }, tile)
			local big, small = UDim2.fromOffset(23, 14), UDim2.fromOffset(212, 318)
			if row.key == "TODAY" then
				flatPortrait(tile, v, big, 240, 44); flatPortrait(tile, v, small, 52, 10)
			else
				portrait(tile, LOOKS[row.key][i], big, 240, 44); portrait(tile, LOOKS[row.key][i], small, 52, 10)
			end
			new("TextLabel", { Name = "Name", BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 262), Size = UDim2.fromOffset(262, 50),
				Font = FONTB, TextScaled = true, TextWrapped = true, TextColor3 = T.accent, Text = v.name }, tile)
			new("TextLabel", { Name = "Small", BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 324), Size = UDim2.fromOffset(190, 40),
				Font = FONT, TextScaled = true, TextColor3 = T.muted, Text = "about card size \u{2192}" }, tile)
		end
	end
end

root.Parent = workspace

-- 5. the summary: part counts per figure (in CAST order), plate offsets and the cameras --------------------------------
local function fmt(v3) return string.format("(%g, %g, %g)", math.floor(v3.X * 10 + 0.5) / 10, math.floor(v3.Y * 10 + 0.5) / 10, math.floor(v3.Z * 10 + 0.5) / 10) end
local camText = {}
for _, c in ipairs(CAMS) do table.insert(camText, c[1] .. " lookAt" .. fmt(c[2]) .. "->" .. fmt(c[3])) end
local function list(t) local s = {}; for _, x in ipairs(t) do table.insert(s, tostring(x)) end; return table.concat(s, "/") end
return string.format("OK_LookLineup built (%d figures, %d parts, %d viewports): parts TODAY %s, A %s, B %s (peony/mom/kid/blogger/rep); plate StudsOffset A %s, B %s (today 2.4); cams FOV70 %s",
	built.figures, built.parts, built.viewports, list(counts.TODAY), list(counts.A), list(counts.B), list(plates.A), list(plates.B), table.concat(camText, "; "))
