-- CLI spec for Modules/DAWLayout: the phone (compact) beat maker's top band, launch audit A1 + A3 (Wave 3 Task 5c-1),
-- and which screens get the phone layout. Run: sh tools/spec.sh daw_layout
-- Every phone width from 568 to 1400 px (the window is the screen less 6 px a side, padding 10) with the Roblox top
-- bar's own buttons ending anywhere from x 0 to the screen's width: nothing of ours starts left of them (+6), every
-- shown button stays 44 px or more, the header row never passes 6 px short of the close button, the REQUESTS chip
-- sits at max(W - 190, header right + 6) and 6 px clear of the header and the close button when it shows, and it
-- hides (width never under 0) where it can't have 44 px. The band gives way in one order as the bar widens, and
-- nothing comes back: the chip narrows to 96, KIT and KEYS shrink, the chip narrows to 44 and hides, then KIT, KEYS
-- and the page buttons drop out. The widths where each step happens are pinned per phone size.
local L = require("../src/ReplicatedStorage/OK/Modules/DAWLayout")

local fails = {}
local function check(ok, msg, where) if not ok then table.insert(fails, msg .. (where and (": " .. where()) or "")) end end
local PAD = 10 -- the compact window's side padding (DAWUI)

-- the band and the chip for a window W wide, the bar's left buttons ending at core (nil: none), its free area ending
-- at free (nil: past the window)
local function band(W, core, free)
	local b = L.Band(W, PAD, core, free)
	local cx, cw = L.Chip(b.right, b.closeLeft)
	return b, cx, cw
end
local function show(W, core, b, cx, cw)
	return string.format("W %d core %s: header %d..%d (pager %s KIT %d KEYS %d, right %d), chip %d+%d, close %d", W, tostring(core), b.x,
		b.x + b.width, tostring(b.pager), b.kit, b.keys, b.right, cx, cw, b.closeLeft)
end

-- 0. the contract: Band reports the page buttons' width (0: dropped), and the phone layout's rule is here
do
	local b = L.Band(655, PAD, 168)
	assert(type(b.pager) == "number" and type(L.WantsCompact) == "function" and type(L.COMPACT_UNDER) == "number",
		"DAWLayout lacks the band's page buttons (Band().pager), WantsCompact or COMPACT_UNDER")
end

-- 1. the header row's width: two 48 px page buttons, a 6 px gap, KIT, KEYS, 6 px apart; a 0 leaves a button out (the
-- gap goes with KIT and KEYS)
for _, c in ipairs({ { 80, 64, nil, 270 }, { 56, 52, nil, 234 }, { 0, 52, nil, 172 }, { 0, 0, nil, 102 }, { 0, 0, 0, 0 } }) do
	check(L.HeaderWidth(c[1], c[2], c[3]) == c[4], string.format("HeaderWidth(%d, %d, %s) is %d, want %d", c[1], c[2], tostring(c[3]),
		L.HeaderWidth(c[1], c[2], c[3]), c[4]))
end
check(L.MIN == 44 and L.PAGER >= 44 and L.KIT_MIN >= 44 and L.KEYS_MIN >= 44 and L.CHIP_MIN >= 44, "a width under 44 px")
-- no top bar (or one that ends left of the padding): the row starts at the padding; the chip at home, 124 wide; the
-- close button where it always was (W - 50)
for _, core in ipairs({ false, 0, 4 }) do
	local b, cx, cw = band(655, core or nil) -- 667x375
	check(b.x == PAD and b.pager == 48 and b.kit == 80 and b.keys == 64 and b.right == 280 and b.closeLeft == 605 and cx == 465 and cw == 124,
		"667 with no bar", function() return show(655, core, b, cx, cw) end)
end

-- 2. every phone width, every bar width up to the screen's
local first = {} -- [vp width] = { under64, hides, kit, keys, pager }: the first bar width where each step has happened
for vpX = 568, 1400 do
	local W = vpX - 12
	local f = {}
	first[vpX] = f
	for core = 0, vpX do
		local b, cx, cw = band(W, core)
		local function where() return show(W, core, b, cx, cw) end
		local limit = b.closeLeft - L.GAP -- nothing of the header passes this
		local full = b.pager > 0 and b.kit > 0 and b.keys > 0
		local shown = cw >= L.MIN
		check(b.pager == 0 or b.pager == L.PAGER, "the page buttons' width", where)
		check(b.kit == 0 or (b.kit >= L.KIT_MIN and b.kit <= L.KIT), "KIT out of range", where)
		check(b.keys == 0 or (b.keys >= L.KEYS_MIN and b.keys <= L.KEYS), "KEYS out of range", where)
		check((b.keys > 0 or b.kit == 0) and (b.pager > 0 or b.keys == 0), "dropped out of order (KIT, then KEYS, then the page buttons)", where)
		check(b.width == L.HeaderWidth(b.kit, b.keys, b.pager), "the header's width", where)
		check(b.x + b.width <= limit and b.right <= limit, "the header passes 6 px short of the close button", where)
		check(b.width == 0 or (b.x >= core + L.GAP and b.x >= PAD), "A1: a header button under the bar's buttons", where)
		check(b.right == (full and (b.x + b.width) or limit), "the header's right edge for the chip", where)
		check(cw >= 0 and cw <= L.CHIP, "the chip's width out of 0.." .. L.CHIP, where)
		check(cx == math.max(W - 190, b.right + L.GAP), "the chip is not at max(W - 190, header right + 6)", where)
		check(full or not shown, "the chip shows with a header button dropped", where)
		if shown then
			check(b.right + L.GAP <= cx, "A3: the header ends less than 6 px left of the chip", where)
			check(cx + cw + L.GAP <= b.closeLeft, "the chip runs within 6 px of the close button", where)
		end
		check(b.closeLeft == W - 50 and b.closeLeft + L.MIN == W - L.GAP, "the close button moved", where)
		-- KIT and KEYS shrink only once the chip is down to CHIP_SHRUNK, KIT first
		if b.kit > 0 and b.kit < L.KIT and b.keys == L.KEYS then check(cw == L.CHIP_SHRUNK, "KIT shrank while the chip had room", where) end
		if b.keys > 0 and b.keys < L.KEYS then check(b.kit == 0 or b.kit == L.KIT_MIN, "KEYS shrank before KIT", where) end
		-- each step, once it has happened, stays (a wider bar never brings anything back)
		local steps = { under64 = cw < L.CHIP_MIN, hides = not shown, kit = b.kit == 0, keys = b.keys == 0, pager = b.pager == 0 }
		for name, now in pairs(steps) do
			if now then f[name] = f[name] or core
			else check(f[name] == nil, "came back after its step (" .. name .. " from bar " .. tostring(f[name]) .. ")", where) end
		end
	end
end
-- the widths where each step happens (the bar's buttons end at x core in the window, 6 px in from the screen's edge);
-- a typical bar (menu button and unibar, chat on) ends near 150-210, with voice chat near 220; only an expanded unibar
-- (while its menu is open) reaches the chip's hiding point
local pinned = {
	[640] = { under64 = 263, hides = 283, kit = 333, keys = 395, pager = 465 },
	[667] = { under64 = 290, hides = 310, kit = 360, keys = 422, pager = 492 },
	[771] = { under64 = 394, hides = 414, kit = 464, keys = 526, pager = 596 },
	[844] = { under64 = 467, hides = 487, kit = 537, keys = 599, pager = 669 },
}
for vpX, want in pairs(pinned) do
	for name, at in pairs(want) do
		check(first[vpX][name] == at, string.format("at %d px the %s step comes at bar %s, want %d", vpX, name, tostring(first[vpX][name]), at))
	end
end
for vpX = 569, 1400 do
	for _, name in ipairs({ "under64", "hides", "kit", "keys", "pager" }) do
		check(first[vpX][name] ~= nil and first[vpX][name] >= first[vpX - 1][name], "a wider phone takes a step at a narrower bar: " .. name .. " at " .. vpX)
	end
end

-- 3. a typical bar at the brief's sizes: KIT and KEYS keep their size; at 640 the chip gives 2 px
for _, case in ipairs({ { 640, 168, 122 }, { 667, 168, 124 }, { 771, 168, 124 }, { 844, 168, 124 }, { 640, 144, 124 } }) do
	local W = case[1] - 12
	local b, cx, cw = band(W, case[2])
	check(b.kit == L.KIT and b.keys == L.KEYS and cw == case[3], string.format("%d with the bar at %d: want KIT 80, KEYS 64, chip %d", case[1], case[2], case[3]),
		function() return show(W, case[2], b, cx, cw) end)
end
-- voice chat at 640 (the bar ends near 214): the chip at 96, KIT gives 20; Studio's own bar (208, 2026-11-11): KIT 66
for _, case in ipairs({ { 214, 60 }, { 208, 66 } }) do
	local b, cx, cw = band(628, case[1])
	check(cw == L.CHIP_SHRUNK and b.kit == case[2] and b.keys == L.KEYS, string.format("640 with the bar at %d: want chip 96, KIT %d, KEYS 64", case[1], case[2]),
		function() return show(628, case[1], b, cx, cw) end)
end
-- a bar past the close button (an expanded unibar on a narrow screen): nothing of the header, no chip
do
	local b, cx, cw = band(628, 640)
	check(b.width == 0 and b.pager == 0 and b.kit == 0 and b.keys == 0 and cw == 0 and b.right == b.closeLeft - L.GAP, "640 with the bar at 640: want an empty band",
		function() return show(628, 640, b, cx, cw) end)
end

-- 4. a bar with buttons on the right too (its free area ends inside the window): the close button and the chip move
-- left with it, 6 px clear, the chip's home 140 px left of the close button (W - 190 when nothing is on the right)
do
	local b, cx, cw = band(655, 168, 600)
	check(b.closeLeft == 600 - L.GAP - L.MIN and cx + cw + L.GAP <= b.closeLeft and cw == L.CHIP_SHRUNK and b.kit == 78,
		"a bar ending at 600: want close at 550, chip 96 flush after the header, KIT 78", function() return show(655, 168, b, cx, cw) end)
	local b3, cx3, cw3 = band(655, nil, 600)
	check(cx3 == b3.closeLeft - 140 and cw3 == L.CHIP, "a bar ending at 600, nothing on the left: the chip should sit 140 px left of the close button",
		function() return show(655, nil, b3, cx3, cw3) end)
	local b2 = band(655, 168, 2000)
	check(b2.closeLeft == 605, "a free area past the window moved the close button: " .. b2.closeLeft)
end

-- 5. which screens get the phone layout: a touch screen under 700 px tall (1024x600 tablets included: a desktop
-- window with 44 px pads is 394 px tall, and the request card needs about 290 px above it); never a mouse-only screen
check(L.COMPACT_UNDER == 700, "the phone layout's height edge is " .. tostring(L.COMPACT_UNDER) .. ", want 700")
for _, c in ipairs({ { true, 360, true }, { true, 390, true }, { true, 600, true }, { true, 699, true }, { true, 700, false }, { true, 768, false },
	{ false, 360, false }, { false, 600, false } }) do
	check(L.WantsCompact(c[1], c[2]) == c[3], string.format("WantsCompact(touch %s, %d px tall) should be %s", tostring(c[1]), c[2], tostring(c[3])))
end

if #fails > 0 then
	local shown = {}
	for i = 1, math.min(#fails, 8) do shown[i] = fails[i] end
	error(#fails .. " failure(s): " .. table.concat(shown, " | "))
end
local p = first[640]
print(string.format("SPEC OK daw_layout: widths 568-1400 x bars 0 to the screen's width; at 640 the chip is under 64 from bar %d, hides from %d, KIT drops from %d, KEYS %d, the page buttons %d; touch screens under %d px tall are phones",
	p.under64, p.hides, p.kit, p.keys, p.pager, L.COMPACT_UNDER))
