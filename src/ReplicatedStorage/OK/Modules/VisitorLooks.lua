-- OK Studio walk-in visitors' looks: look B, "Lanky shapes" (the user's pick, 2026-11-05; Wave 3 Task 5d). Every
-- visitor's figure is a recipe here, as data: tall and thin (adults about 6.6-7 studs, the kids about 4.9), a small block
-- head with bar eyes and a wedge nose, long block limbs, big shoes, one bold colour and one or two signature pieces. The
-- parody cast keeps its signature pieces (the user, 11-11), so each visitor wears its Data/WalkIns `sig`; the five
-- starter locals wear only theirs. Pure: no Roblox globals and no require, so the server's walker (Modules/Visitor), the
-- client's card portraits (both through Modules/VisitorFigure) and the luau CLI (spec/visitor_looks_spec.lua) read the
-- same recipes. Source: research/visitor_look_2026-11-05 (lineup.lua's B body and its mom, homekid, blogger and rep
-- recipes, kept verbatim; notes.md's plate rule).
--
-- A look = { id, kind = "person" | "critter" | "generic", head = "Head", primary = "Torso" (the critter's "Body"),
--   plate = n? (a fixed name plate offset: the critter keeps today's 2.4), pieces = { piece names }, parts = { Part } }.
-- A Part = { n = name, s = { x, y, z }, cf = Tf, c = { r, g, b } (0-255), sh = "Ball" | "Cylinder" | "Wedge" | nil (a
--   block), m = "Neon" | nil (SmoothPlastic), sw = 1 | -1 (a limb, with hang = Tf), flap = 1 | -1 (a wing) }.
-- A Tf is a placement as a flat array of CFrame.new's twelve components, in order: { x, y, z, R00, R01, R02, R10, R11,
--   R12, R20, R21, R22 } (VisitorFigure makes CFrame.new(table.unpack(tf))). Every look faces -Z, feet at y 0.
-- Pose: a limb sits at base * cf * Angles(swing * sw, 0, 0) * hang (cf is its pivot, hip or shoulder; hang drops it from
--   there), a wing at base * cf * Angles(0, 0, swing * flap), anything else at base * cf. Legs and shoes swing in
--   opposite pairs (LegL / ShoeL 1, LegR / ShoeR -1), arms against them (ArmL -1, ArmR 1) unless a recipe holds one
--   still; a piece that swings (the rep's bag) shares a limb's pivot and sign.
-- The name plate (and the bubble over it) sits PLATE_CLEARANCE above the figure's top, measured from the head's centre
--   (notes.md: today's 2.4 is the same clearance over the cowboy hat). The card portrait (Frame) looks at the head and
--   shoulders, tight enough that the small square head reads as a face at the card's 36-44 px.
-- Every call builds fresh tables (no two parts share one), so a caller may keep or change what it gets.
local L = {}
L.MAX_PARTS = 16           -- build/t42_play_server.lua's limit for a walker
L.PLATE_CLEARANCE = 1.2    -- studs from the figure's top to the name plate's centre
L.POSE_HZ = 18             -- A14: while he walks the server poses him this often, not every Heartbeat

-- maths: CFrame's, on flat arrays -------------------------------------------------------------------------------------
local Math = {}
L.Math = Math
-- a translation (no rotation)
function Math.New(x, y, z) return { x or 0, y or 0, z or 0, 1, 0, 0, 0, 1, 0, 0, 0, 1 } end
-- CFrame.Angles(rx, ry, rz) (radians): Rx * Ry * Rz, the Z rotation applied first
function Math.Angles(rx, ry, rz)
	local cx, sx, cy, sy, cz, sz = math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
	return { 0, 0, 0,
		cy * cz, -cy * sz, sy,
		cx * sz + sx * sy * cz, cx * cz - sx * sy * sz, -sx * cy,
		sx * sz - cx * sy * cz, sx * cz + cx * sy * sz, cx * cy }
end
-- a * b, as CFrame multiplication
function Math.Mul(a, b)
	local ax, ay, az, a00, a01, a02, a10, a11, a12, a20, a21, a22 = table.unpack(a)
	local bx, by, bz, b00, b01, b02, b10, b11, b12, b20, b21, b22 = table.unpack(b)
	return {
		ax + a00 * bx + a01 * by + a02 * bz, ay + a10 * bx + a11 * by + a12 * bz, az + a20 * bx + a21 * by + a22 * bz,
		a00 * b00 + a01 * b10 + a02 * b20, a00 * b01 + a01 * b11 + a02 * b21, a00 * b02 + a01 * b12 + a02 * b22,
		a10 * b00 + a11 * b10 + a12 * b20, a10 * b01 + a11 * b11 + a12 * b21, a10 * b02 + a11 * b12 + a12 * b22,
		a20 * b00 + a21 * b10 + a22 * b20, a20 * b01 + a21 * b11 + a22 * b21, a20 * b02 + a21 * b12 + a22 * b22 }
end
-- New(x, y, z) * Angles in degrees (rx, ry, rz)
function Math.At(x, y, z, rx, ry, rz)
	local t = Math.Angles(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0))
	t[1], t[2], t[3] = x, y, z
	return t
end
-- half the world extent, along axis a (1 x, 2 y, 3 z), of a box of size s placed at t
function Math.Half(t, s, a)
	local i = 3 * a
	return (math.abs(t[i + 1]) * s[1] + math.abs(t[i + 2]) * s[2] + math.abs(t[i + 3]) * s[3]) / 2
end
local New, At, Mul = Math.New, Math.At, Math.Mul

-- the figure ----------------------------------------------------------------------------------------------------------
-- the body's proportions (lineup.lua's B_ADULT and B_KID); a recipe's `shape` overrides any of them
local ADULT = { legLen = 2.75, legW = 0.34, legX = 0.3, shoe = { 0.5, 0.32, 0.95 }, torsoW = 1.1, torsoH = 2.0, torsoD = 0.55,
	coat = 0, neckH = 0.38, neckD = 0.26, head = { 0.8, 0.95, 0.75 }, armLen = 2.25, armW = 0.26, tilt = 4 }
local KID = { legLen = 1.55, legW = 0.36, legX = 0.3, shoe = { 0.58, 0.42, 1.0 }, torsoW = 1.32, torsoH = 1.55, torsoD = 0.66,
	coat = 0, neckH = 0.22, neckD = 0.26, head = { 0.85, 0.95, 0.8 }, armLen = 1.5, armW = 0.3, tilt = 4 }
local EYE = { 16, 16, 20 }

local function rgb(c) return { c[1], c[2], c[3] } end
local function add(fig, e) -- every table copied: no two parts (or looks) share one
	e.s, e.cf, e.c = table.clone(e.s), table.clone(e.cf), rgb(e.c)
	if e.hang then e.hang = table.clone(e.hang) end
	table.insert(fig.P, e)
	return e
end
local function find(fig, n) for _, e in ipairs(fig.P) do if e.n == n then return e end end; return nil end

-- the 13 body parts: LegL, LegR, ShoeL, ShoeR, Torso (down over the hips by `coat`), Neck, Head, Hair, EyeL, EyeR,
-- Nose (a wedge), ArmL, ArmR (no hands: the arm is the hand). K = the landmarks pieces are placed from
local function body(fig)
	local o, col, K = fig.o, fig.col, fig.K
	local sole = o.shoe[2]
	local hipY = sole + o.legLen - 0.02
	K.torsoTop = hipY - 0.15 + o.torsoH
	K.torsoBottom = hipY - 0.15 - o.coat
	K.headY = K.torsoTop + o.neckH - 0.06 + o.head[2] / 2
	K.headTop = K.headY + o.head[2] / 2
	K.headFront, K.torsoFront, K.torsoBack = -o.head[3] / 2, -o.torsoD / 2, o.torsoD / 2
	K.sx, K.sy = o.torsoW / 2 + o.armW / 2 + 0.02, K.torsoTop - 0.15
	K.pivotL, K.pivotR = At(-K.sx, K.sy, 0, 0, 0, -o.tilt), At(K.sx, K.sy, 0, 0, 0, o.tilt)
	add(fig, { n = "LegL", s = { o.legW, o.legLen, o.legW }, cf = New(-o.legX, hipY, 0), c = col.legs, sw = 1, hang = New(0, -o.legLen / 2, 0) })
	add(fig, { n = "LegR", s = { o.legW, o.legLen, o.legW }, cf = New(o.legX, hipY, 0), c = col.legs, sw = -1, hang = New(0, -o.legLen / 2, 0) })
	add(fig, { n = "ShoeL", s = o.shoe, cf = New(-o.legX, hipY, 0), c = col.shoes, sw = 1, hang = New(0, -(hipY - sole / 2), -0.18) })
	add(fig, { n = "ShoeR", s = o.shoe, cf = New(o.legX, hipY, 0), c = col.shoes, sw = -1, hang = New(0, -(hipY - sole / 2), -0.18) })
	add(fig, { n = "Torso", s = { o.torsoW, K.torsoTop - K.torsoBottom, o.torsoD }, cf = New(0, (K.torsoTop + K.torsoBottom) / 2, 0), c = col.top })
	add(fig, { n = "Neck", s = { o.neckH, o.neckD, o.neckD }, cf = At(0, K.torsoTop + o.neckH / 2 - 0.04, 0, 0, 0, 90), c = col.skin, sh = "Cylinder" })
	add(fig, { n = "Head", s = o.head, cf = New(0, K.headY, 0), c = col.skin })
	add(fig, { n = "Hair", s = { o.head[1] + 0.06, 0.3, o.head[3] + 0.06 }, cf = New(0, K.headTop + 0.12, 0.03), c = col.hair })
	add(fig, { n = "EyeL", s = { 0.1, 0.18, 0.05 }, cf = New(-0.18, K.headY + 0.06, K.headFront - 0.015), c = EYE })
	add(fig, { n = "EyeR", s = { 0.1, 0.18, 0.05 }, cf = New(0.18, K.headY + 0.06, K.headFront - 0.015), c = EYE })
	add(fig, { n = "Nose", s = { 0.12, 0.2, 0.15 }, cf = New(0, K.headY - 0.1, K.headFront - 0.075), c = col.nose or col.skin, sh = "Wedge" })
	add(fig, { n = "ArmL", s = { o.armW, o.armLen, o.armW }, cf = K.pivotL, c = col.sleeve or col.top, sw = -1, hang = New(0, -o.armLen / 2, 0) })
	add(fig, { n = "ArmR", s = { o.armW, o.armLen, o.armW }, cf = K.pivotR, c = col.sleeve or col.top, sw = 1, hang = New(0, -o.armLen / 2, 0) })
end

-- hair styles: a size (or `fit`: the head's width and depth plus fit, `h` tall), its height from a landmark, its z
local HAIR = {
	crop = { fit = 0.06, h = 0.3, from = "headTop", y = 0.12, z = 0.03 },           -- the body's own short hair
	under = { fit = 0.06, h = 0.3, from = "headTop", y = -0.13, z = 0.06 },         -- under a hat or a cap: the sides and back
	hidden = { s = { 0.6, 0.3, 0.5 }, from = "headY", y = 0, z = 0 },               -- inside a hood or a helmet
	flat = { s = { 0.86, 0.55, 0.8 }, from = "headTop", y = 0.24, z = 0.03 },       -- a flat-top (lineup: the peony)
	low = { s = { 0.86, 0.28, 0.8 }, from = "headTop", y = 0.12, z = 0.03 },        -- under a bun (lineup: mom)
	kid = { s = { 0.9, 0.28, 0.85 }, from = "headTop", y = 0.12, z = 0.03 },        -- lineup: the hometown kid
	bob = { s = { 0.96, 1.2, 0.72 }, from = "headY", y = 0.08, z = 0.2 },           -- a long bob (lineup: the blogger)
	long = { s = { 0.96, 1.6, 0.7 }, from = "headY", y = 0.14, z = 0.21 },          -- high on top, down to the shoulders
	puff = { s = { 1.04, 0.55, 0.96 }, from = "headTop", y = 0.16, z = 0.08 },      -- big hair
	high = { fit = 0.1, h = 0.55, from = "headTop", y = 0.2, z = 0.04 },            -- a high top
	quiff = { s = { 0.84, 0.42, 0.8 }, from = "headTop", y = 0.2, z = 0.02, ry = 180, sh = "Wedge" }, -- high at the front (lineup: the rep)
	swept = { s = { 0.86, 0.5, 0.82 }, from = "headTop", y = 0.22, z = 0.02, ry = 180, sh = "Wedge" }, -- a taller quiff
}
local function hair(fig, style)
	local h = assert(HAIR[style], "unknown hair style " .. tostring(style))
	local e, o = find(fig, "Hair"), fig.o
	e.s = h.s and table.clone(h.s) or { o.head[1] + h.fit, h.h, o.head[3] + h.fit }
	e.cf = At(0, fig.K[h.from] + h.y, h.z, 0, h.ry or 0, 0)
	e.sh = h.sh
end
-- the Hair part's top, and its front (z)
local function hairTop(fig)
	local e = find(fig, "Hair")
	return e.cf[2] + e.s[2] / 2, e.cf[3] - e.s[3] / 2
end

-- an arm held still at the shoulder (angles in degrees): it no longer swings; fig.hand[side] = where its end is
local function holdArm(fig, side, a)
	local K, o = fig.K, fig.o
	local arm = find(fig, "Arm" .. side)
	local pivot = At((side == "L" and -1 or 1) * K.sx, K.sy, 0, a[1], a[2], a[3])
	arm.cf, arm.sw, arm.hang = Mul(pivot, New(0, -o.armLen / 2, 0)), nil, nil
	local hand = Mul(pivot, New(0, -o.armLen, 0))
	fig.hand[side] = { hand[1], hand[2], hand[3] }
end
local function between(fig) -- the midpoint of both held hands
	local l, r = assert(fig.hand.L, "needs both arms held"), assert(fig.hand.R, "needs both arms held")
	return (l[1] + r[1]) / 2, (l[2] + r[2]) / 2, (l[3] + r[3]) / 2
end

-- signature pieces: piece(fig, p) adds its parts (at most 3 with the 13-part body) or changes body parts; p = the
-- recipe's entry { name, c = its colour, ...options }. Today's sig names (Data/WalkIns) are pieces of the same name.
local DARK, WHITE = { 30, 30, 36 }, { 240, 240, 245 }
local PIECES = {}
-- LIL NAV X's western hat: a wide brim, a crown, a band in his colour; his hair shows under it
function PIECES.cowboy_hat(fig, p)
	local K, brown = fig.K, p.hat or { 92, 62, 38 }
	hair(fig, "under")
	add(fig, { n = "HatBrim", s = { 0.08, 1.45, 1.45 }, cf = At(0, K.headTop - 0.02, 0, 0, 0, 90), c = brown, sh = "Cylinder" })
	add(fig, { n = "HatCrown", s = { 0.84, 0.5, 0.8 }, cf = New(0, K.headTop + 0.27, 0.02), c = brown })
	add(fig, { n = "HatBand", s = { 0.88, 0.1, 0.84 }, cf = New(0, K.headTop + 0.08, 0.02), c = p.c })
end
-- DOJA BAT's ears: two tall black ears leaning out from the top of the head
function PIECES.bat_ears(fig, p)
	local K, o, c = fig.K, fig.o, p.ears or { 24, 24, 30 }
	local x = o.head[1] / 2 - 0.12
	add(fig, { n = "EarL", s = { 0.26, 0.55, 0.1 }, cf = At(-x, K.headTop + 0.2, 0.06, 0, 0, 18), c = c })
	add(fig, { n = "EarR", s = { 0.26, 0.55, 0.1 }, cf = At(x, K.headTop + 0.2, 0.06, 0, 0, -18), c = c })
end
-- ICE SPIKE's hair: big hair in her colour and three spikes of it
function PIECES.spiky_hair(fig, p)
	local K = fig.K
	hair(fig, "puff")
	find(fig, "Hair").c = rgb(p.c)
	add(fig, { n = "SpikeL", s = { 0.3, 0.5, 0.3 }, cf = At(-0.3, K.headTop + 0.42, 0.12, 0, 45, 30), c = p.c })
	add(fig, { n = "SpikeR", s = { 0.3, 0.5, 0.3 }, cf = At(0.3, K.headTop + 0.42, 0.12, 0, 45, -30), c = p.c })
	add(fig, { n = "SpikeT", s = { 0.32, 0.55, 0.32 }, cf = At(0, K.headTop + 0.55, 0.16, -20, 45, 0), c = p.c })
end
-- PLAYDOH CHARTI's hat: a big round hat in his colour and a white pom-pom
function PIECES.blob_hat(fig, p)
	local K = fig.K
	hair(fig, "under")
	add(fig, { n = "Blob", s = { 1.2, 1.2, 1.2 }, cf = New(0, K.headTop + 0.1, 0.04), c = p.c, sh = "Ball" })
	add(fig, { n = "Pom", s = { 0.3, 0.3, 0.3 }, cf = New(0, K.headTop + 0.78, 0.04), c = { 245, 245, 245 }, sh = "Ball" })
end
-- TRAVIS SCOOT's helmet: a round space helmet over the whole head, a dark visor across it and a fin on top
function PIECES.helmet(fig, p)
	local K = fig.K
	hair(fig, "hidden")
	add(fig, { n = "Shell", s = { 1.5, 1.5, 1.5 }, cf = New(0, K.headY, 0), c = p.c, sh = "Ball" })
	add(fig, { n = "Visor", s = { 0.9, 0.4, 0.1 }, cf = New(0, K.headY + 0.05, -0.72), c = p.visor or { 22, 26, 36 } })
	add(fig, { n = "Fin", s = { 0.12, 0.4, 0.9 }, cf = New(0, K.headY + 0.75, 0.05), c = p.fin or p.c })
end
-- KENDRICK LLAMA's ears and snout: two tall furry ears and a snout over the nose
function PIECES.llama_ears(fig, p)
	local K, o, fur = fig.K, fig.o, p.fur or { 215, 190, 150 }
	local x = o.head[1] / 2 - 0.1
	add(fig, { n = "EarL", s = { 0.18, 0.6, 0.16 }, cf = At(-x, K.headTop + 0.22, 0.08, 0, 0, 12), c = fur })
	add(fig, { n = "EarR", s = { 0.18, 0.6, 0.16 }, cf = At(x, K.headTop + 0.22, 0.08, 0, 0, -12), c = fur })
	add(fig, { n = "Snout", s = { 0.5, 0.34, 0.3 }, cf = New(0, K.headY - 0.17, K.headFront - 0.13), c = fur })
end
-- TAYLOR DRIFT's cape: a long cape in her colour, two Neon sparkles on the front
function PIECES.sparkle_cape(fig, p)
	local K, o, gold = fig.K, fig.o, p.sparkle or { 255, 215, 90 }
	add(fig, { n = "Cape", s = { o.torsoW + 0.1, 3.0, 0.08 }, cf = New(0, K.torsoTop - 1.45, K.torsoBack + 0.05), c = p.c })
	add(fig, { n = "SparkleA", s = { 0.2, 0.2, 0.05 }, cf = At(-0.22, K.torsoTop - 0.55, K.torsoFront - 0.03, 0, 0, 45), c = gold, m = "Neon" })
	add(fig, { n = "SparkleB", s = { 0.16, 0.16, 0.05 }, cf = At(0.2, K.torsoTop - 1.2, K.torsoFront - 0.03, 0, 0, 45), c = gold, m = "Neon" })
end
-- DRIZZLE's owl hood: a hood round the head (the face shows), two owl tufts on it
function PIECES.owl_hood(fig, p)
	local K, o = fig.K, fig.o
	hair(fig, "hidden")
	local hy, hh = K.headY + 0.08, o.head[2] + 0.1
	add(fig, { n = "Hood", s = { o.head[1] + 0.16, hh, o.head[3] + 0.1 }, cf = New(0, hy, 0.1), c = p.c })
	local x = o.head[1] / 2 - 0.04
	add(fig, { n = "TuftL", s = { 0.22, 0.34, 0.2 }, cf = At(-x, hy + hh / 2 + 0.14, 0.12, 0, 0, 18), c = p.c })
	add(fig, { n = "TuftR", s = { 0.22, 0.34, 0.2 }, cf = At(x, hy + hh / 2 + 0.14, 0.12, 0, 0, -18), c = p.c })
end
-- BILLIE EYELASH's hair: long and dark, a fringe, its roots bright on top
function PIECES.green_roots(fig, p)
	local K, o = fig.K, fig.o
	hair(fig, "long")
	local e = find(fig, "Hair")
	local top = e.cf[2] + e.s[2] / 2
	add(fig, { n = "Roots", s = { e.s[1] - 0.04, 0.18, e.s[3] + 0.02 }, cf = New(0, top + 0.05, e.cf[3]), c = p.c })
	add(fig, { n = "Fringe", s = { o.head[1] + 0.04, 0.2, 0.12 }, cf = New(0, K.headTop - 0.08, K.headFront + 0.02), c = fig.col.hair })
end
-- a suit: a white shirt front and a tie (Neon when p.neon); the jacket is the recipe's top
function PIECES.suit(fig, p)
	local K = fig.K
	add(fig, { n = "Shirt", s = { 0.42, 0.65, 0.05 }, cf = New(0, K.torsoTop - 0.33, K.torsoFront - 0.02), c = p.shirt or { 235, 235, 240 } })
	add(fig, { n = "Tie", s = { 0.14, 0.8, 0.06 }, cf = New(0, K.torsoTop - 0.45, K.torsoFront - 0.05), c = p.tie or p.c, m = p.neon and "Neon" or nil })
end
-- a cap in its colour, the bill forward (p.back: turned round); over the head with the hair showing at the sides, or
-- perched on top of big hair (p.over: that hair style)
function PIECES.cap(fig, p)
	local K, o = fig.K, fig.o
	if p.over then
		hair(fig, p.over)
		local top, front = hairTop(fig)
		local e = find(fig, "Hair")
		add(fig, { n = "CapCrown", s = { o.head[1] + 0.08, 0.3, o.head[3] + 0.08 }, cf = New(0, top + 0.03, e.cf[3]), c = p.c })
		add(fig, { n = "CapBill", s = { o.head[1] - 0.06, 0.07, 0.5 }, cf = New(0, top - 0.09, front - 0.2), c = p.bill or p.c })
		return
	end
	hair(fig, "under")
	add(fig, { n = "CapCrown", s = { o.head[1] + 0.08, 0.3, o.head[3] + 0.08 }, cf = New(0, K.headTop + 0.1, 0), c = p.c })
	local z = o.head[3] / 2 + 0.22
	add(fig, { n = "CapBill", s = { o.head[1] - 0.06, 0.07, 0.5 }, cf = New(0, K.headTop - 0.02, p.back and z or -z), c = p.bill or p.c })
end
-- headphones: tall cups over the ears in its colour and a band over the head (lineup: the hometown kid's), or round
-- the neck (p.neck)
function PIECES.headphones(fig, p)
	local K, o, band = fig.K, fig.o, p.band or { 40, 40, 48 }
	if p.neck then
		add(fig, { n = "CupL", s = { 0.24, 0.42, 0.42 }, cf = New(-0.27, K.torsoTop + 0.1, -0.12), c = p.c })
		add(fig, { n = "CupR", s = { 0.24, 0.42, 0.42 }, cf = New(0.27, K.torsoTop + 0.1, -0.12), c = p.c })
		add(fig, { n = "Band", s = { 0.78, 0.12, 0.16 }, cf = New(0, K.torsoTop + 0.06, 0.16), c = band })
		return
	end
	local hx = o.head[1] / 2 + 0.13
	add(fig, { n = "CupL", s = { 0.26, 1.1, 0.62 }, cf = New(-hx, K.headY + 0.2, 0.02), c = p.c })
	add(fig, { n = "CupR", s = { 0.26, 1.1, 0.62 }, cf = New(hx, K.headY + 0.2, 0.02), c = p.c })
	add(fig, { n = "Band", s = { 2 * hx + 0.26, 0.18, 0.28 }, cf = New(0, K.headY + 0.84, 0.02), c = band })
end
-- mom's apron: a long cream apron down the front (lineup)
function PIECES.apron(fig, p)
	local K = fig.K
	add(fig, { n = "Apron", s = { 0.85, 1.9, 0.05 }, cf = New(0, K.torsoBottom + 1.05, K.torsoFront - 0.03), c = p.cloth or { 245, 238, 220 } })
end
-- a headset: a light band over the hair (dark gear vanished against dark hair), one tall cup and a mic boom in its
-- colour reaching to the mouth
function PIECES.headset(fig, p)
	local K, o, set = fig.K, fig.o, p.set or { 215, 215, 222 }
	local hx = o.head[1] / 2 + 0.07
	local band = hairTop(fig) + 0.04 -- on top of the hair
	local cup0 = K.headY - 0.17
	add(fig, { n = "Band", s = { 2 * hx + 0.14, 0.08, 0.16 }, cf = New(0, band, 0.02), c = set })
	add(fig, { n = "Cup", s = { 0.14, band - 0.04 - cup0, 0.4 }, cf = New(-hx, (band - 0.04 + cup0) / 2, 0.02), c = set })
	add(fig, { n = "Boom", s = { 0.07, 0.07, 0.55 }, cf = At(-hx + 0.16, K.headY - 0.15, -0.2, 0, -35, 0), c = p.c })
end
-- a lanyard: two cords in its colour from the collar down to a white badge
function PIECES.lanyard(fig, p)
	local K = fig.K
	local z = K.torsoFront - 0.025
	add(fig, { n = "CordL", s = { 0.06, 0.85, 0.04 }, cf = At(-0.15, K.torsoTop - 0.4, z, 0, 0, 15), c = p.c })
	add(fig, { n = "CordR", s = { 0.06, 0.85, 0.04 }, cf = At(0.15, K.torsoTop - 0.4, z, 0, 0, -15), c = p.c })
	add(fig, { n = "Badge", s = { 0.34, 0.46, 0.04 }, cf = New(0, K.torsoTop - 1.0, z - 0.005), c = p.badge or { 240, 240, 245 } })
end
-- lineup pieces: mom's bun and her food box (both arms held), the blogger's shades, skirt and raised phone (her right
-- arm held), the rep's swag bag (it swings with his left arm)
function PIECES.bun(fig, p)
	add(fig, { n = "Bun", s = { 0.62, 0.62, 0.62 }, cf = New(0, fig.K.headTop + 0.48, 0.08), c = p.c or fig.col.hair, sh = "Ball" })
end
function PIECES.food_box(fig, p)
	local x, y, z = between(fig)
	add(fig, { n = "FoodBox", s = { 1.0, 0.55, 0.75 }, cf = New(x, y + 0.2, z - 0.1), c = p.c })
end
function PIECES.shades(fig, p)
	local K = fig.K
	for _, n in ipairs({ "EyeL", "EyeR" }) do
		local e = find(fig, n)
		e.s, e.cf = { 0.3, 0.2, 0.05 }, New(n == "EyeL" and -0.2 or 0.2, K.headY + 0.07, K.headFront - 0.015)
		if p.c then e.c = rgb(p.c) end
	end
end
function PIECES.skirt(fig, p)
	add(fig, { n = "Skirt", s = { 1.25, 0.85, 0.7 }, cf = New(0, fig.K.torsoBottom + 0.05, 0), c = p.c })
end
function PIECES.phone_up(fig, p)
	local h = assert(fig.hand.R, "phone_up needs the right arm held")
	local phone = Mul(New(h[1], h[2] + 0.3, h[3] - 0.05), Math.Angles(0, math.rad(-10), 0))
	add(fig, { n = "Phone", s = { 0.42, 0.75, 0.08 }, cf = phone, c = p.c })
	add(fig, { n = "PhoneLight", s = { 0.11, 0.11, 0.03 }, cf = Mul(phone, New(-0.11, 0.26, -0.055)), c = { 255, 255, 255 }, m = "Neon" })
end
function PIECES.bag(fig, p)
	local K, o = fig.K, fig.o
	add(fig, { n = "Bag", s = { 0.32, 0.8, 0.85 }, cf = K.pivotL, c = p.c, sw = -1, hang = New(0, -(o.armLen + 0.38), 0) })
end
-- new pieces: the superfan's foam hand (both arms held up), the confident kid's medallion, the aura salesman's
-- glowing jar (both arms held) and beanie, the sleepy neighbour's sleep mask, the faraway visitor's backpack and scarf
function PIECES.foam_finger(fig, p)
	local h = assert(fig.hand.R, "foam_finger needs the right arm held")
	add(fig, { n = "FoamFinger", s = { 0.46, 0.62, 0.2 }, cf = New(h[1], h[2] + 0.22, h[3]), c = p.c })
end
function PIECES.medallion(fig, p)
	local K = fig.K
	add(fig, { n = "Medallion", s = { 0.3, 0.3, 0.05 }, cf = At(0, K.torsoTop - 0.45, K.torsoFront - 0.03, 0, 0, 45), c = p.c })
end
function PIECES.jar(fig, p)
	local x, y, z = between(fig)
	add(fig, { n = "Jar", s = { 0.44, 0.56, 0.44 }, cf = New(x, y + 0.28, z - 0.06), c = p.c, m = "Neon" })
	add(fig, { n = "Lid", s = { 0.5, 0.1, 0.5 }, cf = New(x, y + 0.61, z - 0.06), c = p.lid or { 60, 60, 70 } })
end
function PIECES.beanie(fig, p)
	local K, o = fig.K, fig.o
	hair(fig, "under")
	add(fig, { n = "Beanie", s = { o.head[1] + 0.1, 0.55, o.head[3] + 0.1 }, cf = New(0, K.headTop + 0.18, 0.02), c = p.c })
end
function PIECES.sleep_mask(fig, p)
	local K, o = fig.K, fig.o
	add(fig, { n = "MaskBand", s = { o.head[1] + 0.04, 0.16, o.head[3] + 0.04 }, cf = New(0, K.headY + 0.3, 0), c = p.band or { 60, 70, 120 } })
	add(fig, { n = "Mask", s = { 0.6, 0.24, 0.06 }, cf = New(0, K.headY + 0.3, K.headFront - 0.04), c = p.c })
end
function PIECES.backpack(fig, p)
	local K, o = fig.K, fig.o
	add(fig, { n = "Backpack", s = { o.torsoW - 0.1, 1.3, 0.5 }, cf = New(0, K.torsoTop - 0.8, K.torsoBack + 0.24), c = p.c })
end
function PIECES.scarf(fig, p)
	local K = fig.K
	add(fig, { n = "Scarf", s = { 0.56, 0.24, 0.5 }, cf = New(0, K.torsoTop + 0.08, 0), c = p.c })
	add(fig, { n = "ScarfEnd", s = { 0.18, 0.7, 0.06 }, cf = New(0.14, K.torsoTop - 0.3, K.torsoFront - 0.04), c = p.c })
end

-- the recipes ---------------------------------------------------------------------------------------------------------
-- { kid = true?, shape = { proportions }?, col = { skin, hair, top, legs, shoes, sleeve?, nose? }, hair = style?,
--   hold = { L = { rx, ry, rz }?, R = ... }? (arms held still, degrees at the shoulder), pieces = { { name, ... } } }.
-- Skin tones are spread across the cast on purpose and not matched to the real people behind the parody names.
local SKIN = { a = { 255, 214, 180 }, b = { 232, 177, 130 }, c = { 198, 134, 90 }, d = { 156, 102, 68 }, e = { 110, 70, 48 } }
local BLACK, DENIM = { 22, 20, 22 }, { 64, 98, 158 }
local RECIPES = {
	-- the nine artists: each keeps today's signature piece (the parody cast, the user's 11-11 call)
	navx = { shape = { coat = 0.9 }, col = { skin = SKIN.b, hair = { 58, 38, 30 }, top = { 255, 110, 180 }, legs = DENIM, shoes = { 176, 118, 66 } },
		pieces = { { "cowboy_hat", c = { 255, 110, 180 } } } }, -- lineup's coat, denim and boots; the hat, not the bloom
	dojabat = { shape = { coat = 0.35, torsoW = 1.0 }, col = { skin = SKIN.c, hair = BLACK, top = { 190, 90, 255 }, legs = DARK, shoes = { 190, 90, 255 } },
		hair = "bob", pieces = { { "bat_ears" } } },
	icespike = { shape = { torsoW = 1.2 }, col = { skin = SKIN.d, hair = { 255, 140, 50 }, top = { 238, 234, 226 }, legs = { 120, 150, 200 }, shoes = WHITE },
		pieces = { { "spiky_hair", c = { 255, 140, 50 } } } },
	charti = { col = { skin = SKIN.e, hair = BLACK, top = { 70, 70, 82 }, legs = DARK, shoes = { 200, 30, 70 } },
		pieces = { { "blob_hat", c = { 200, 30, 70 } } } },
	scoot = { col = { skin = SKIN.a, hair = BLACK, top = { 225, 215, 195 }, legs = { 120, 85, 50 }, shoes = { 60, 45, 35 } },
		pieces = { { "helmet", c = { 150, 105, 60 }, fin = { 100, 70, 40 } } } },
	llama = { col = { skin = SKIN.d, hair = BLACK, top = { 205, 165, 110 }, legs = { 70, 60, 50 }, shoes = WHITE },
		pieces = { { "llama_ears", fur = { 245, 238, 225 } } } },
	drift = { shape = { coat = 0.6 }, col = { skin = SKIN.c, hair = { 240, 215, 140 }, top = { 220, 90, 140 }, legs = { 235, 235, 245 }, shoes = { 235, 235, 245 } },
		hair = "long", pieces = { { "sparkle_cape", c = { 255, 210, 110 } } } },
	drizzle = { col = { skin = SKIN.e, hair = BLACK, top = { 110, 120, 165 }, legs = DARK, shoes = WHITE },
		pieces = { { "owl_hood", c = { 110, 120, 165 } } } },
	eyelash = { shape = { torsoW = 1.32, coat = 0.5 }, col = { skin = SKIN.a, hair = BLACK, top = { 120, 255, 120 }, legs = DARK, shoes = WHITE },
		pieces = { { "green_roots", c = { 120, 255, 120 } } } },
	-- the roles: the rep (lineup), the blogger (lineup), the superfan, the rival, the manager
	rep = { shape = { torsoW = 1.38 }, col = { skin = SKIN.e, hair = BLACK, top = { 176, 180, 190 }, legs = { 150, 154, 166 }, shoes = { 30, 30, 34 } },
		hair = "quiff", pieces = { { "suit", tie = { 180, 110, 255 }, neon = true }, { "bag", c = { 120, 60, 210 } } } },
	blogger = { shape = { torsoW = 0.95 }, col = { skin = SKIN.a, hair = { 120, 60, 180 }, top = { 255, 200, 0 }, legs = DARK, shoes = WHITE },
		hair = "bob", hold = { R = { 135, 0, 12 } }, pieces = { { "shades" }, { "skirt", c = { 255, 70, 150 } }, { "phone_up", c = { 255, 70, 150 } } } },
	fan = { col = { skin = SKIN.b, hair = { 90, 60, 40 }, top = WHITE, legs = DENIM, shoes = { 0, 200, 255 } },
		hold = { L = { 150, 0, -25 }, R = { 150, 0, 25 } }, -- cheering: both arms up in a V, a foam hand on the right
		pieces = { { "cap", c = { 0, 200, 255 } }, { "foam_finger", c = { 0, 200, 255 } } } },
	rival = { col = { skin = SKIN.e, hair = BLACK, top = { 58, 58, 66 }, legs = DARK, shoes = { 255, 60, 60 } },
		pieces = { { "headphones", c = { 255, 60, 60 } } } },
	manager = { shape = { torsoW = 1.3 }, col = { skin = SKIN.c, hair = BLACK, top = { 125, 100, 190 }, legs = { 125, 100, 190 }, shoes = DARK },
		hair = "swept", pieces = { { "suit", tie = { 230, 190, 80 } }, { "shades" } } },
	-- Wave 1a's people: mom (lineup), the booker, the coordinator, the confident kid, the aura salesman, the faraway visitor
	mom = { shape = { coat = 1.1, torsoW = 1.2 }, col = { skin = SKIN.d, hair = { 46, 32, 28 }, top = { 255, 150, 110 }, legs = { 70, 52, 52 }, shoes = { 60, 40, 40 } },
		hair = "low", hold = { L = { 40, 0, 12 }, R = { 40, 0, -12 } },
		pieces = { { "bun", c = { 46, 32, 28 } }, { "apron", cloth = { 245, 238, 220 } }, { "food_box", c = { 120, 190, 230 } } } },
	booker = { col = { skin = SKIN.d, hair = { 90, 60, 40 }, top = { 60, 120, 200 }, legs = { 60, 62, 70 }, shoes = DARK },
		hair = "high", pieces = { { "headset", c = { 60, 120, 200 } } } },
	coordinator = { col = { skin = SKIN.a, hair = { 120, 80, 50 }, top = { 80, 190, 140 }, legs = { 190, 170, 130 }, shoes = WHITE },
		hair = "puff", pieces = { { "lanyard", c = { 40, 40, 48 } } } },
	nextkid = { kid = true, col = { skin = SKIN.b, hair = { 40, 30, 25 }, top = { 60, 90, 200 }, legs = WHITE, shoes = { 220, 50, 50 } },
		pieces = { { "cap", c = { 255, 220, 60 }, back = true }, { "medallion", c = { 255, 205, 60 } } } },
	jarman = { shape = { coat = 1.0 }, col = { skin = SKIN.e, hair = BLACK, top = { 190, 160, 110 }, legs = { 60, 55, 50 }, shoes = { 40, 30, 25 } },
		hold = { L = { 60, 0, 16 }, R = { 60, 0, -16 } }, pieces = { { "shades" }, { "jar", c = { 180, 120, 255 } }, { "beanie", c = { 70, 50, 90 } } } },
	stranger = { col = { skin = SKIN.c, hair = { 60, 40, 30 }, top = { 80, 110, 90 }, legs = { 170, 150, 110 }, shoes = { 90, 60, 40 } },
		hair = "high", pieces = { { "backpack", c = { 200, 140, 90 } }, { "scarf", c = { 200, 60, 50 } } } },
	-- the locals: the kid from the block, the label boss (ICON tier), the hometown kid (lineup)
	blockkid = { kid = true, col = { skin = SKIN.d, hair = BLACK, top = { 255, 120, 60 }, legs = DENIM, shoes = WHITE },
		pieces = { { "cap", c = WHITE } } },
	labelboss = { shape = { torsoW = 1.32 }, col = { skin = SKIN.a, hair = { 205, 205, 210 }, top = { 62, 62, 74 }, legs = { 62, 62, 74 }, shoes = DARK },
		hair = "swept", pieces = { { "suit", tie = { 215, 180, 90 } } } },
	homekid = { kid = true, col = { skin = SKIN.c, hair = { 26, 22, 24 }, top = { 60, 180, 160 }, legs = { 52, 52, 62 }, shoes = WHITE },
		hair = "kid", pieces = { { "headphones", c = { 255, 140, 40 } } } },
	-- the starter pool (11-11)
	rapper = { shape = { torsoW = 1.24, coat = 0.3 }, col = { skin = SKIN.b, hair = BLACK, top = { 230, 90, 70 }, legs = DARK, shoes = WHITE },
		hair = "high", pieces = { { "headphones", c = { 240, 240, 245 }, neck = true } } },
	cousin = { col = { skin = SKIN.e, hair = { 40, 30, 25 }, top = { 250, 140, 200 }, legs = { 150, 150, 160 }, shoes = WHITE },
		pieces = { { "cap", c = { 40, 40, 48 }, over = "puff" } } }, -- the cap perched on big hair
	neighbor = { shape = { coat = 1.2 }, col = { skin = SKIN.c, hair = { 90, 70, 55 }, top = { 120, 150, 190 }, legs = { 170, 180, 200 }, shoes = { 230, 225, 215 } },
		hair = "flat", pieces = { { "sleep_mask", c = { 200, 170, 230 } } } }, -- a bathrobe, slippers, a sleep mask pushed up
	host = { col = { skin = SKIN.d, hair = BLACK, top = { 255, 200, 40 }, legs = DARK, shoes = WHITE },
		hair = "flat", pieces = { { "headset", c = { 255, 200, 40 } } } },
	landlord = { shape = { coat = 0.5 }, col = { skin = SKIN.b, hair = { 170, 170, 175 }, top = { 150, 115, 80 }, legs = { 70, 70, 80 }, shoes = { 40, 30, 25 } },
		hair = "puff", pieces = { { "lanyard", c = { 230, 200, 80 } } } },
}

local function build(id, kind, r)
	local o = table.clone(r.kid and KID or ADULT)
	for k, v in pairs(r.shape or {}) do o[k] = v end
	local fig = { P = {}, K = {}, o = o, col = r.col, hand = {} }
	body(fig)
	if r.hair then hair(fig, r.hair) end
	for _, side in ipairs({ "L", "R" }) do
		if r.hold and r.hold[side] then holdArm(fig, side, r.hold[side]) end
	end
	local names = {}
	for _, p in ipairs(r.pieces or {}) do
		assert(PIECES[p[1]], "unknown piece " .. tostring(p[1]))(fig, p)
		table.insert(names, p[1])
	end
	return { id = id, kind = kind, head = "Head", primary = "Torso", pieces = names, parts = fig.P }
end

-- the critter (the pigeon, design 4.3): unchanged from Wave 1a, 11 parts, feet at y 0 facing -Z; its wings flap in Leave
local PIGEON = { body = { 125, 130, 140 }, dark = { 85, 90, 100 }, neck = { 80, 140, 120 }, beak = { 225, 180, 90 },
	foot = { 225, 115, 105 }, eye = { 12, 12, 14 } }
local function pigeon()
	local P, fig = PIGEON, { P = {} }
	add(fig, { n = "Body", s = { 0.7, 0.6, 1.1 }, cf = At(0, 0.6, 0.05), c = P.body })
	add(fig, { n = "Head", s = { 0.45, 0.45, 0.45 }, cf = At(0, 1.05, -0.5), c = P.body, sh = "Ball" })
	add(fig, { n = "Neck", s = { 0.4, 0.2, 0.4 }, cf = At(0, 0.85, -0.4), c = P.neck })
	add(fig, { n = "Beak", s = { 0.12, 0.1, 0.25 }, cf = At(0, 1.02, -0.8), c = P.beak })
	add(fig, { n = "EyeL", s = { 0.08, 0.08, 0.08 }, cf = At(-0.16, 1.1, -0.62), c = P.eye })
	add(fig, { n = "EyeR", s = { 0.08, 0.08, 0.08 }, cf = At(0.16, 1.1, -0.62), c = P.eye })
	add(fig, { n = "WingL", s = { 0.12, 0.35, 0.8 }, cf = At(-0.4, 0.65, 0.1), c = P.dark, flap = 1 })
	add(fig, { n = "WingR", s = { 0.12, 0.35, 0.8 }, cf = At(0.4, 0.65, 0.1), c = P.dark, flap = -1 })
	add(fig, { n = "Tail", s = { 0.4, 0.08, 0.5 }, cf = At(0, 0.62, 0.75, 15), c = P.dark })
	add(fig, { n = "LegL", s = { 0.08, 0.3, 0.08 }, cf = At(-0.15, 0.15, 0.05), c = P.foot })
	add(fig, { n = "LegR", s = { 0.08, 0.3, 0.08 }, cf = At(0.15, 0.15, 0.05), c = P.foot })
	-- its portrait shows more of it under the small head, with a little room over it
	return { id = "pigeon", kind = "critter", head = "Head", primary = "Body", plate = 2.4, frame = { below = 1.55, room = 0.2 },
		pieces = {}, parts = fig.P }
end

-- the API -------------------------------------------------------------------------------------------------------------
-- the look of a visitor id: its recipe ("person"), the pigeon ("critter"), or nil (no figure: a phone-only sender, or
-- an id nobody wrote a recipe for)
function L.For(id)
	if id == "pigeon" then return pigeon() end
	local r = id ~= nil and RECIPES[id] or nil
	return r and build(id, "person", r) or nil
end
function L.Pigeon() return pigeon() end
function L.IsPerson(id) return id ~= nil and RECIPES[id] ~= nil end
-- every id with a person recipe, sorted
function L.Ids()
	local ids = {}
	for id in pairs(RECIPES) do table.insert(ids, id) end
	table.sort(ids)
	return ids
end
-- the fallback for an id with no look (tests, a visitor added without a recipe): a B body in `color` ({ r, g, b }, or a
-- pink) with a high top, wearing `sig` when that is one of the data's signature pieces (a cap perched on the hair); a
-- suit dresses it in grey
local SIGS = { cowboy_hat = true, bat_ears = true, spiky_hair = true, blob_hat = true, helmet = true, llama_ears = true,
	sparkle_cape = true, owl_hood = true, green_roots = true, suit = true, cap = true, headphones = true, apron = true,
	headset = true, lanyard = true }
function L.Generic(sig, color)
	local c = (type(color) == "table" and tonumber(color[1])) and { color[1], color[2] or 0, color[3] or 0 } or { 255, 60, 160 }
	local worn = SIGS[sig] and sig or nil
	local top = worn == "suit" and { 176, 180, 190 } or c
	return build("generic", "generic", { col = { skin = SKIN.c, hair = { 40, 32, 28 }, top = top, legs = { 40, 40, 48 }, shoes = DARK },
		hair = "high", pieces = worn and { { worn, c = c, over = "high" } } or nil })
end
-- what Visitor.Spawn and the walk-in card build for a visitor: its look, else the fallback. Never nil
function L.Resolve(id, sig, color) return L.For(id) or L.Generic(sig, color) end

-- a part's placement in the figure's own frame (base = identity) at a swing (radians; a wing's flap)
function L.Pose(e, swing)
	if e.sw then return Mul(Mul(e.cf, Math.Angles((swing or 0) * e.sw, 0, 0)), e.hang) end
	if e.flap then return Mul(e.cf, Math.Angles(0, 0, (swing or 0) * e.flap)) end
	return table.clone(e.cf)
end
-- at rest: the figure's top and bottom, the head's height and size, the name plate's StudsOffset (rounded to 0.01)
function L.Info(look)
	local top, bottom, headY, headH = -math.huge, math.huge, 0, 1
	for _, e in ipairs(look.parts) do
		local t = L.Pose(e, 0)
		local h = Math.Half(t, e.s, 2)
		top, bottom = math.max(top, t[2] + h), math.min(bottom, t[2] - h)
		if e.n == look.head then headY, headH = t[2], e.s[2] end
	end
	local plate = look.plate or math.floor((top - headY + L.PLATE_CLEARANCE) * 100 + 0.5) / 100
	return { count = #look.parts, top = top, bottom = bottom, headY = headY, headH = headH, plate = plate }
end

-- the card portrait: the figure turned to face the camera (base: a half turn and `yaw` degrees, so the wedge nose shows
-- side-on), the camera level with the head and shoulders. The frame runs from `below` head-heights under the head's
-- centre (the shoulders) up to the figure's top, at least `room` and at most `above` head-heights over the head (a
-- raised phone or a tall hat is cut). A look's `frame` overrides any of these. fov in degrees, square; from / at in the
-- portrait's own space
L.PORTRAIT = { fov = 30, yaw = 14, below = 1.0, room = 0.1, above = 0.6, margin = 0.05, tilt = 0.08 }
function L.Frame(look)
	local F = table.clone(L.PORTRAIT)
	for k, v in pairs(look.frame or {}) do F[k] = v end
	local info = L.Info(look)
	local hh, headTop = info.headH, info.headY + info.headH / 2
	local top = math.clamp(info.top, headTop + F.room * hh, headTop + F.above * hh)
	local bottom = info.headY - F.below * hh
	local half = (top - bottom) / 2 * (1 + F.margin)
	local cy = (top + bottom) / 2
	local base = Math.Angles(0, math.pi + math.rad(F.yaw), 0)
	local head
	for _, e in ipairs(look.parts) do if e.n == look.head then head = Mul(base, L.Pose(e, 0)) end end
	local hx, hz = head and head[1] or 0, head and head[3] or 0
	local dist = half / math.tan(math.rad(F.fov / 2))
	return { fov = F.fov, base = base, from = { hx, cy + half * F.tilt, hz + dist }, at = { hx, cy, hz }, top = top, bottom = bottom }
end

-- A14: called with each walking frame's dt; returns whether to pose the figure now and the clock's new value. The
-- remainder carries (so 60 fps gives POSE_HZ, not every 4th frame's 15), and a hitch poses once, never a burst
function L.PoseStep(acc, dt)
	local every = 1 / L.POSE_HZ
	acc += dt
	if acc < every then return false, acc end
	return true, (acc - every) % every
end

return L
