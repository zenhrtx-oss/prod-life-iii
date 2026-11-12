-- CLI spec for Modules/VisitorLooks (Wave 3 Task 5d: the visitors' look B, "Lanky shapes", and the card portrait).
-- Run: sh tools/spec.sh visitor_looks
-- (1) Every visitor the content can send in person (Data/WalkIns' W.Visitors, kind neither "sender" nor "critter") has
--     its own recipe, and no recipe names anyone else; the phone-only senders have none (no figure, no portrait); the
--     pigeon is the critter (11 parts, today's plate 2.4). Every person wears at least one signature piece, and a visitor
--     with a signature in the data (`sig`) wears that piece.
-- (2) Each person is a B figure: the 13 body parts by name, at most 16 in all, names unique, a block Head (primary
--     Torso, unrotated) with a Wedge Nose, legs and shoes that swing in opposite pairs, arms that swing in opposite
--     pairs or hold still, anything else that swings hangs from a limb's own pivot; Balls uniform, Cylinders round,
--     SmoothPlastic or Neon, colours 0-255; feet on the floor, adults 6.6-7.3 studs tall (the brief's ~6.6-7; the lineup's
--     four verbatim recipes keep their own, pinned by their plates: the rep stands 6.58) and the kids 4.6-5.4; no part
--     floating off the body, at rest or mid-stride (swings of 0.6 either way).
-- (3) The name plate: 1.2 above the figure's top (notes.md), the lineup's numbers kept for its four verbatim recipes.
-- (4) The card portrait: the head fully in frame and at least 45% of its height, the shoulders in view.
-- (5) The fallback (an id with no recipe: tests, decoys): a B body in its colour wearing its sig when the sig is known.
-- (6) Each call builds fresh tables; the maths is CFrame.Angles' order (Rx * Ry * Rz; t89 checks it against Roblox).
-- (7) The pose clock (A14): about 18 Hz at any frame rate, and a hitch never fires a burst.
local L = require("../src/ReplicatedStorage/OK/Modules/VisitorLooks")
local W = require("../src/ReplicatedStorage/OK/Data/WalkIns")
local M = L.Math

local fails = {}
local function ok(name, cond) if not cond then table.insert(fails, name) end end
local function near(a, b, eps) return math.abs(a - b) <= (eps or 1e-9) end

local BODY = { "LegL", "LegR", "ShoeL", "ShoeR", "Torso", "Neck", "Head", "Hair", "EyeL", "EyeR", "Nose", "ArmL", "ArmR" }
local KIDS = { homekid = true, nextkid = true, blockkid = true }
-- the lineup's B recipes kept verbatim (research/visitor_look_2026-11-05/notes.md: parts and StudsOffset)
local LINEUP = { mom = 2.47, homekid = 2.13, blogger = 2.49, rep = 2.09 }
local TOL = 0.05 -- studs: parts closer than this touch

local function partsByName(look)
	local t = {}
	for _, e in ipairs(look.parts) do t[e.n] = e end
	return t
end
local function isRot(t, want) -- rotation part of a Tf against want (identity when nil)
	want = want or { 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1 }
	for i = 4, 12 do if not near(t[i], want[i], 1e-9) then return false end end
	return true
end
local function same(a, b) -- two Tfs equal
	for i = 1, 12 do if not near(a[i], b[i], 1e-9) then return false end end
	return true
end
local function box(e, swing) -- world-aligned box of a posed part: centre and half extents
	local t = L.Pose(e, swing or 0)
	return { t[1], t[2], t[3] }, { M.Half(t, e.s, 1), M.Half(t, e.s, 2), M.Half(t, e.s, 3) }
end
local function touch(a, b, swing)
	local ca, ha = box(a, swing); local cb, hb = box(b, swing)
	for i = 1, 3 do if math.abs(ca[i] - cb[i]) > ha[i] + hb[i] + TOL then return false end end
	return true
end
-- every part reachable from the root part through touching parts, posed at a swing
local function floating(look, root, swing)
	local seen, queue, n = { [root] = true }, { root }, 0
	while #queue > 0 do
		local cur = table.remove(queue)
		for _, e in ipairs(look.parts) do
			if not seen[e] and touch(cur, e, swing) then seen[e] = true; table.insert(queue, e) end
		end
	end
	local out = {}
	for _, e in ipairs(look.parts) do if not seen[e] then n += 1; table.insert(out, e.n) end end
	return n, table.concat(out, ", ")
end

-- (1) who has a figure ----------------------------------------------------------------------------------------------
local persons, kinds = {}, {}
for _, v in ipairs(W.Visitors) do
	kinds[v.id] = v.kind
	if v.kind ~= "sender" and v.kind ~= "critter" then table.insert(persons, v) end
end
-- at least the 28 of 11-11 (9 artists, rep, blogger, fan, rival, manager, mom, booker, coordinator, nextkid, jarman,
-- stranger, blockkid, labelboss, homekid and the 5 starters); a person added later needs a recipe (checked per id below)
ok("fewer than the 28 people of 11-11 in the content: " .. #persons, #persons >= 28)
for _, v in ipairs(persons) do
	local look = L.For(v.id)
	ok(v.id .. ": has no recipe (every person who walks in needs a B figure)", look ~= nil and look.kind == "person")
	ok(v.id .. ": IsPerson is false", L.IsPerson(v.id) == true)
	if look and v.sig ~= "none" then
		local wears = false
		for _, p in ipairs(look.pieces) do if p == v.sig then wears = true end end
		ok(v.id .. ": does not wear its signature '" .. v.sig .. "' (pieces: " .. table.concat(look.pieces, ", ") .. ")", wears)
	end
	if look then ok(v.id .. ": wears no signature piece (the brief: one or two)", #look.pieces >= 1) end
end
local ids = L.Ids()
ok("Ids() lists " .. #ids .. " recipes, want " .. #persons, #ids == #persons)
for i, id in ipairs(ids) do
	ok("recipe '" .. id .. "' is not a person in Data/WalkIns (kind " .. tostring(kinds[id]) .. ")", kinds[id] ~= nil and kinds[id] ~= "sender" and kinds[id] ~= "critter")
	if i > 1 then ok("Ids() is not sorted at " .. id, ids[i - 1] < id) end
end
for _, v in ipairs(W.Visitors) do
	if v.kind == "sender" then
		ok(v.id .. ": a phone-only sender has a figure", L.For(v.id) == nil and L.IsPerson(v.id) == false)
	end
end
local pigeon = L.For("pigeon")
ok("the pigeon is not the critter look", pigeon ~= nil and pigeon.kind == "critter" and L.IsPerson("pigeon") == false)
if pigeon then
	ok("the pigeon is not today's 11 parts", #pigeon.parts == 11)
	ok("the pigeon's plate is not today's 2.4", L.Info(pigeon).plate == 2.4)
	ok("the pigeon's head / primary are not Head / Body", pigeon.head == "Head" and pigeon.primary == "Body")
	local pn = partsByName(pigeon)
	ok("the pigeon's wings don't flap in opposite pairs", pn.WingL and pn.WingL.flap == 1 and pn.WingR and pn.WingR.flap == -1)
	for _, flap in ipairs({ 0, 0.9, -0.9 }) do
		local n, list = floating(pigeon, pn.Body, flap)
		ok(string.format("the pigeon has parts floating off its body at a flap of %g: %s", flap, list), n == 0)
	end
	ok("L.Pigeon() is not the pigeon's look", #L.Pigeon().parts == 11)
end
ok("For(nil) / For('nobody') should be nil", L.For(nil) == nil and L.For("nobody") == nil)

-- (2) each person is a B figure ----------------------------------------------------------------------------------------
local function checkFigure(id, look, kid, lineup)
	local names, count = {}, 0
	for _, e in ipairs(look.parts) do
		count += 1
		ok(id .. ": two parts named " .. e.n, not names[e.n])
		names[e.n] = e
		ok(id .. " " .. e.n .. ": size not 3 positive numbers", #e.s == 3 and e.s[1] > 0 and e.s[2] > 0 and e.s[3] > 0)
		ok(id .. " " .. e.n .. ": placement not 12 numbers", type(e.cf) == "table" and #e.cf == 12)
		ok(id .. " " .. e.n .. ": colour not 3 integers 0-255", #e.c == 3 and (function()
			for i = 1, 3 do if type(e.c[i]) ~= "number" or e.c[i] ~= math.floor(e.c[i]) or e.c[i] < 0 or e.c[i] > 255 then return false end end
			return true end)())
		ok(id .. " " .. e.n .. ": shape " .. tostring(e.sh), e.sh == nil or e.sh == "Ball" or e.sh == "Cylinder" or e.sh == "Wedge")
		ok(id .. " " .. e.n .. ": material " .. tostring(e.m) .. " (SmoothPlastic or Neon only)", e.m == nil or e.m == "Neon")
		ok(id .. " " .. e.n .. ": a Ball must be uniform", e.sh ~= "Ball" or (e.s[1] == e.s[2] and e.s[2] == e.s[3]))
		ok(id .. " " .. e.n .. ": a Cylinder needs Y == Z", e.sh ~= "Cylinder" or e.s[2] == e.s[3])
		ok(id .. " " .. e.n .. ": a swing without a hang (or a hang without a swing)", (e.sw == nil) == (e.hang == nil))
		ok(id .. " " .. e.n .. ": a person has no flapping wing", e.flap == nil)
	end
	ok(id .. ": " .. count .. " parts (want 13..16)", count >= 13 and count <= L.MAX_PARTS)
	for _, n in ipairs(BODY) do ok(id .. ": no body part " .. n, names[n] ~= nil) end
	ok(id .. ": head / primary are not Head / Torso", look.head == "Head" and look.primary == "Torso")
	local head, torso, nose = names.Head, names.Torso, names.Nose
	if head then ok(id .. ": the Head is not a block", head.sh == nil) end
	if nose then ok(id .. ": the Nose is not a Wedge", nose.sh == "Wedge") end
	if torso then ok(id .. ": the Torso (the PrimaryPart) is rotated: the facing check reads its LookVector", isRot(torso.cf) and torso.sw == nil) end
	-- the walk swing: legs and shoes always swing, in opposite pairs; arms swing in opposite pairs or hold still
	for _, pair in ipairs({ { "LegL", 1 }, { "LegR", -1 }, { "ShoeL", 1 }, { "ShoeR", -1 } }) do
		local e = names[pair[1]]
		if e then ok(id .. ": " .. pair[1] .. " does not swing " .. pair[2], e.sw == pair[2]) end
	end
	if names.ArmL then ok(id .. ": ArmL swings " .. tostring(names.ArmL.sw) .. " (want -1, or held)", names.ArmL.sw == -1 or names.ArmL.sw == nil) end
	if names.ArmR then ok(id .. ": ArmR swings " .. tostring(names.ArmR.sw) .. " (want 1, or held)", names.ArmR.sw == 1 or names.ArmR.sw == nil) end
	for _, e in ipairs(look.parts) do
		if e.sw and not (e.n == "LegL" or e.n == "LegR" or e.n == "ArmL" or e.n == "ArmR") then
			local limb = false
			for _, n in ipairs({ "LegL", "LegR", "ArmL", "ArmR" }) do
				local l = names[n]
				if l and l.sw == e.sw and same(l.cf, e.cf) then limb = true end
			end
			ok(id .. " " .. e.n .. ": swings but does not hang from a limb's pivot with its sign", limb)
		end
	end
	-- swinging moves only the limbs, the right way: a leg with sw 1 goes forward (-Z) at a positive swing
	if names.LegL and names.LegR and names.Head then
		local l, r, h0, h1 = L.Pose(names.LegL, 0.5), L.Pose(names.LegR, 0.5), L.Pose(names.Head, 0), L.Pose(names.Head, 0.5)
		ok(id .. ": a positive swing should send LegL forward and LegR back", l[3] < -0.1 and r[3] > 0.1)
		ok(id .. ": the swing moved the Head", same(h0, h1))
	end
	-- heights: feet on the floor, the figure's top in its band
	local info = L.Info(look)
	ok(id .. string.format(": the feet are at %.3f, not on the floor", info.bottom), math.abs(info.bottom) <= 0.01)
	if kid then ok(id .. string.format(": a kid %.2f studs tall (want 4.6-5.4)", info.top), info.top >= 4.6 and info.top <= 5.4)
	elseif lineup then ok(id .. string.format(": the lineup's recipe %.2f studs tall (want 6.4-7.3)", info.top), info.top >= 6.4 and info.top <= 7.3)
	else ok(id .. string.format(": an adult %.2f studs tall (want 6.6-7.3)", info.top), info.top >= 6.6 and info.top <= 7.3) end
	-- (3) the name plate: centred 1.2 above the figure's top, measured from the head
	local raw = info.top - info.headY + L.PLATE_CLEARANCE
	ok(id .. string.format(": plate %.2f is not round(top - headY + 1.2) = %.3f", info.plate, raw), near(info.plate, math.floor(raw * 100 + 0.5) / 100, 1e-9))
	ok(id .. string.format(": plate %.2f outside 1.7-2.8", info.plate), info.plate >= 1.7 and info.plate <= 2.8)
	-- nothing floats off the body (boxes touching within 0.05), at rest and mid-stride (the walk swings 0.6 either way)
	if torso then
		for _, swing in ipairs({ 0, 0.6, -0.6 }) do
			local n, list = floating(look, torso, swing)
			ok(string.format("%s: parts floating off the body at swing %g: %s", id, swing, list), n == 0)
		end
	end
	return info
end

local infos = {}
for _, v in ipairs(persons) do
	local look = L.For(v.id)
	if look then infos[v.id] = checkFigure(v.id, look, KIDS[v.id], LINEUP[v.id] ~= nil) end
end
-- (3) the lineup's numbers, for the four recipes kept verbatim (navx changed: the cowboy hat stays, 11-11)
for id, plate in pairs(LINEUP) do
	local look = L.For(id)
	ok(id .. ": the lineup's recipe has 16 parts, got " .. (look and #look.parts or 0), look ~= nil and #look.parts == 16)
	local info = infos[id]
	ok(id .. string.format(": plate %s, the lineup's is %.2f", info and string.format("%.2f", info.plate) or "?", plate), info ~= nil and math.abs(info.plate - plate) <= 0.0101)
end
local navx = L.For("navx")
ok("navx: 16 parts with the cowboy hat (the bloom, heart and bandana gone)", navx ~= nil and #navx.parts == 16 and partsByName(navx).HatBrim ~= nil and partsByName(navx).Bloom == nil)

-- (4) the card portrait ------------------------------------------------------------------------------------------------
local function sub(a, b) return { a[1] - b[1], a[2] - b[2], a[3] - b[3] } end
local function dot(a, b) return a[1] * b[1] + a[2] * b[2] + a[3] * b[3] end
local function cross(a, b) return { a[2] * b[3] - a[3] * b[2], a[3] * b[1] - a[1] * b[3], a[1] * b[2] - a[2] * b[1] } end
local function unit(a) local m = math.sqrt(dot(a, a)); return { a[1] / m, a[2] / m, a[3] / m } end
-- the head's eight corners in the portrait's view (CFrame.lookAt's basis, a square frame): normalised -1..1 extents
local function headView(look, fr)
	local fwd = unit(sub(fr.at, fr.from))
	local right = unit(cross(fwd, { 0, 1, 0 }))
	local up = cross(right, fwd)
	local t = math.tan(math.rad(fr.fov / 2))
	local head = partsByName(look)[look.head]
	local hc = M.Mul(fr.base, L.Pose(head, 0))
	local x0, x1, y0, y1 = math.huge, -math.huge, math.huge, -math.huge
	for _, sx in ipairs({ -1, 1 }) do for _, sy in ipairs({ -1, 1 }) do for _, sz in ipairs({ -1, 1 }) do
		local c = M.Mul(hc, M.New(sx * head.s[1] / 2, sy * head.s[2] / 2, sz * head.s[3] / 2))
		local d = sub({ c[1], c[2], c[3] }, fr.from)
		local z = dot(d, fwd)
		local x, y = dot(d, right) / (z * t), dot(d, up) / (z * t)
		x0, x1, y0, y1 = math.min(x0, x), math.max(x1, x), math.min(y0, y), math.max(y1, y)
	end end end
	return x0, x1, y0, y1
end
local function checkFrame(id, look, shoulders)
	local fr = L.Frame(look)
	ok(id .. ": the portrait frame has no fov / base / from / at", type(fr.fov) == "number" and #fr.base == 12 and #fr.from == 3 and #fr.at == 3)
	local x0, x1, y0, y1 = headView(look, fr)
	ok(id .. string.format(": the head leaves the portrait (x %.2f..%.2f, y %.2f..%.2f)", x0, x1, y0, y1), x0 >= -1 and x1 <= 1 and y0 >= -1 and y1 <= 1)
	ok(id .. string.format(": the head is %.0f%% of the portrait's height (want at least 45%%: a face at 36 px)", (y1 - y0) / 2 * 100), (y1 - y0) / 2 >= 0.45)
	if shoulders then
		local torso = partsByName(look).Torso
		local t = L.Pose(torso, 0)
		local torsoTop = t[2] + M.Half(t, torso.s, 2)
		ok(id .. string.format(": the frame's bottom %.2f is not under the torso's top %.2f (head and shoulders)", fr.bottom, torsoTop), fr.bottom <= torsoTop - 0.05)
	end
end
for _, v in ipairs(persons) do
	local look = L.For(v.id)
	if look then checkFrame(v.id, look, true) end
end
if pigeon then checkFrame("pigeon", pigeon, false) end

-- (5) the fallback: a B body in its colour, wearing its sig when that sig is a known piece ---------------------------
local sigs = { none = true, nonsense = true }
for _, v in ipairs(W.Visitors) do sigs[v.sig] = true end
local PINK = { 255, 60, 160 }
for sig in pairs(sigs) do
	local g = L.Generic(sig, PINK)
	ok("Generic(" .. sig .. "): not a generic look", g ~= nil and g.kind == "generic")
	if g then
		checkFigure("Generic(" .. sig .. ")", g, false)
		checkFrame("Generic(" .. sig .. ")", g, true)
		local wears = false
		for _, p in ipairs(g.pieces) do if p == sig then wears = true end end
		if sig == "none" or sig == "nonsense" then ok("Generic(" .. sig .. ") wears a piece", #g.pieces == 0)
		else ok("Generic(" .. sig .. ") does not wear its sig", wears) end
	end
end
local g0 = L.Generic(nil, nil)
ok("Generic(nil, nil) is not a plain B body", g0 ~= nil and #g0.parts == 13 and #g0.pieces == 0)
local gt = partsByName(L.Generic("none", PINK)).Torso
ok("Generic's torso is not the visitor's colour", gt and gt.c[1] == 255 and gt.c[2] == 60 and gt.c[3] == 160)
local r1, r2 = L.Resolve("mom", "cowboy_hat", PINK), L.Resolve("t42_x", "cap", PINK)
ok("Resolve(a known id) is not that id's recipe", r1.kind == "person" and #r1.parts == #L.For("mom").parts and partsByName(r1).FoodBox ~= nil)
ok("Resolve(an unknown id, cap) is not the generic with a cap", r2.kind == "generic" and partsByName(r2).CapBill ~= nil)
ok("Resolve('pigeon') is not the critter", L.Resolve("pigeon", "none", PINK).kind == "critter")
ok("Resolve(a sender) should be the generic (a sender never walks in, but Spawn must not fail)", L.Resolve("feed", "none", PINK).kind == "generic")

-- (6) fresh tables, and the maths ----------------------------------------------------------------------------------------
local a, b = L.For("mom"), L.For("mom")
ok("For returns the same table twice", a ~= b and a.parts ~= b.parts and a.parts[1] ~= b.parts[1])
a.parts[1].s[1] = 99; a.parts[1].cf[1] = 99; a.parts[1].c[1] = 99
local c = L.For("mom")
ok("mutating one look changed the next one", b.parts[1].s[1] ~= 99 and c.parts[1].s[1] ~= 99 and c.parts[1].cf[1] ~= 99 and c.parts[1].c[1] ~= 99)
local shared = false
for _, e in ipairs(c.parts) do for _, f in ipairs(c.parts) do if e ~= f and (e.cf == f.cf or e.s == f.s or e.c == f.c or (e.hang and e.hang == f.hang)) then shared = true end end end
ok("two parts of one look share a table", not shared)

ok("Angles(0, 0, 0) is not the identity", isRot(M.Angles(0, 0, 0)))
local id3 = M.Mul(M.New(1, 2, 3), M.New(4, 5, 6))
ok("New(1,2,3) * New(4,5,6) is not New(5,7,9)", same(id3, M.New(5, 7, 9)))
local ry = M.Angles(0, math.pi / 2, 0)
ok("Angles(0, 90deg, 0) does not turn the look vector (0,0,-1) to (-1,0,0) (CFrame's convention)", near(-ry[6], -1, 1e-9) and near(-ry[9], 0, 1e-9) and near(-ry[12], 0, 1e-9))
local ax, by, cz = 0.3, -1.1, 2.2
ok("Angles(x, y, z) is not Angles(x,0,0) * Angles(0,y,0) * Angles(0,0,z) (CFrame.Angles' XYZ order)",
	same(M.Angles(ax, by, cz), M.Mul(M.Mul(M.Angles(ax, 0, 0), M.Angles(0, by, 0)), M.Angles(0, 0, cz))))
local rr = M.Angles(0.7, -0.4, 1.9)
local orth = true
for i = 0, 2 do for j = 0, 2 do
	local s = 0
	for k = 0, 2 do s += rr[4 + i * 3 + k] * rr[4 + j * 3 + k] end
	if not near(s, i == j and 1 or 0, 1e-9) then orth = false end
end end
ok("Angles is not orthonormal", orth)
local at = M.At(1, 2, 3, 0, 90, 0)
ok("At(1, 2, 3, 0, 90, 0) is not a translation then Angles(0, 90deg, 0)", same(at, M.Mul(M.New(1, 2, 3), M.Angles(0, math.rad(90), 0))))

-- (7) the pose clock (A14) -----------------------------------------------------------------------------------------------
local function rate(fps, seconds)
	local acc, n = 0, 0
	for _ = 1, math.floor(fps * seconds + 0.5) do
		local pose
		pose, acc = L.PoseStep(acc, 1 / fps)
		if pose then n += 1 end
	end
	return n / seconds
end
ok("L.POSE_HZ is not between 15 and 20", L.POSE_HZ >= 15 and L.POSE_HZ <= 20)
for _, fps in ipairs({ 60, 144, 240 }) do
	local hz = rate(fps, 10)
	ok(string.format("at %d fps the figure is posed %.1f times a second (want %d +-1)", fps, hz, L.POSE_HZ), math.abs(hz - L.POSE_HZ) <= 1)
end
local hz30 = rate(30, 10)
ok(string.format("at 30 fps the figure is posed %.1f times a second (want 15-20)", hz30), hz30 >= 15 and hz30 <= 20)
local hz12 = rate(12, 10)
ok(string.format("at 12 fps (slower than the clock) every frame poses: %.1f", hz12), near(hz12, 12, 1e-9))
local p1, acc1 = L.PoseStep(0, 0.5)   -- a half-second hitch: one pose, no backlog
local p2 = L.PoseStep(acc1, 1 / 60)
ok("a 0.5 s hitch should pose once and not again on the next 60 fps frame", p1 == true and p2 == false and acc1 >= 0 and acc1 < 1 / L.POSE_HZ)

if #fails > 0 then error(#fails .. " failure(s):\n  " .. table.concat(fails, "\n  "), 0) end
print(string.format("SPEC OK visitor_looks: %d people with their own B recipe (%d-%d parts), the pigeon, %d senders without; plates %.2f-%.2f; portraits frame the head at 45%%+; fallback for %d sigs; pose clock %d Hz",
	#persons, (function() local lo = math.huge; for _, v in ipairs(persons) do lo = math.min(lo, #L.For(v.id).parts) end; return lo end)(),
	(function() local hi = 0; for _, v in ipairs(persons) do hi = math.max(hi, #L.For(v.id).parts) end; return hi end)(),
	(function() local n = 0; for _, v in ipairs(W.Visitors) do if v.kind == "sender" then n += 1 end end; return n end)(),
	(function() local lo = math.huge; for _, i in pairs(infos) do lo = math.min(lo, i.plate) end; return lo end)(),
	(function() local hi = 0; for _, i in pairs(infos) do hi = math.max(hi, i.plate) end; return hi end)(),
	(function() local n = 0; for _ in pairs(sigs) do n += 1 end; return n end)(), L.POSE_HZ))
