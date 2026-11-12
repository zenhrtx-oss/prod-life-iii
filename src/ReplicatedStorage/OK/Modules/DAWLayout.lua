-- OK Beat Maker: the phone (compact) window's top band as arithmetic (launch audit A1 + A3, Wave 3 Task 5c-1), and
-- which screens get the phone layout. Pure: no Roblox globals and no require, so it loads in Studio (Modules/DAWUI lays
-- the band out, Modules/RequestUI places its chip, DAWClient picks the layout) and in the luau CLI
-- (spec/daw_layout_spec.lua).
--
-- The band is the window's top row, x measured from the window's left edge. On a phone the Roblox top bar's own
-- buttons (the menu button and the unibar) cover the band's left end and take every tap there, so nothing of ours sits
-- under them: the header row [1–8][9–16] · [KIT][KEYS] starts 6 px right of them. The REQUESTS chip sits at
-- max(W − 190, header right + 6): its home is W − 190, 140 px left of the close button (44 px, at the right end, 6 px
-- in), unless the header reaches it; it stops 6 px short of the close button. As the bar widens the band gives way in
-- one order: the chip narrows to 96 (its text scales down), KIT to 56, KEYS to 52, the chip down to 44; under that the
-- chip hides (its width never goes under 0; MiniSubmit, which covers it, hides too). Only an expanded unibar (while its
-- menu is open) goes further: then KIT, KEYS and the page buttons drop out in that order, so the header never passes
-- 6 px short of the close button. The spec pins the bar widths where each step happens. If the bar also has buttons on
-- the right, the close button (and the chip's home with it) moves left of them.
local M = {}
M.MIN = 44 -- the smallest touch target
M.GAP = 6 -- between the band's buttons, and from the bar's
M.PAGER = 48 -- each page button (1–8, 9–16)
M.KIT, M.KIT_MIN = 80, 56
M.KEYS, M.KEYS_MIN = 64, 52
M.CHIP, M.CHIP_SHRUNK, M.CHIP_MIN = 124, 96, 64 -- the chip: full width; narrowed to before KIT or KEYS shrink; the band's comfortable limit
M.CHIP_HOME = 140 -- the chip's home: this far left of the close button (W − 190)
-- touch screens shorter than this get the phone layout: a desktop window with 44 px pads (394 px) and the request card
-- docked above it (about 290 px) need about 684 (1024x600 tablets are phones here)
M.COMPACT_UNDER = 700

-- the phone layout: a touch screen under COMPACT_UNDER tall; never a mouse-only screen
function M.WantsCompact(touch, height)
	return touch == true and height < M.COMPACT_UNDER
end

-- the header row's width: [1–8][9–16][a 6 px gap][KIT][KEYS], 6 px apart; a width of 0 leaves that button out (pager 0:
-- both page buttons), and the gap goes with KIT and KEYS
function M.HeaderWidth(kit, keys, pager)
	pager = pager or M.PAGER
	local w, n = 0, 0
	if pager > 0 then w += 2 * pager; n += 2 end
	if pager > 0 and (kit > 0 or keys > 0) then w += M.GAP; n += 1 end
	if kit > 0 then w += kit; n += 1 end
	if keys > 0 then w += keys; n += 1 end
	return n > 0 and w + (n - 1) * M.GAP or 0
end

-- the chip's left edge and width: at max(home, header right + 6), CHIP wide, never within 6 px of the close button and
-- never under 0 wide; under MIN it hides (RequestUI)
function M.Chip(headerRight, closeLeft)
	local x = math.max(closeLeft - M.CHIP_HOME, headerRight + M.GAP)
	return x, math.max(0, math.min(M.CHIP, closeLeft - M.GAP - x))
end

-- the band for a window W wide with side padding pad. coreRight: the right edge of the top bar's buttons on the left,
-- in the window's space (nil: they don't reach the band); freeRight: where the bar's free area ends on the right (nil:
-- past the window). Returns { x, pager, kit, keys, width, right, closeLeft }: the header row's left edge, the page
-- buttons', KIT's and KEYS' widths (0: dropped), the row's width, its right edge as the chip sees it, and the close
-- button's left edge.
function M.Band(W, pad, coreRight, freeRight)
	local closeRight = W - M.GAP
	if freeRight then closeRight = math.min(closeRight, freeRight - M.GAP) end
	local closeLeft = closeRight - M.MIN
	local limit = closeLeft - M.GAP -- nothing of the header passes this
	local x = math.min(coreRight and math.max(pad, coreRight + M.GAP) or pad, limit)
	-- the chip's width if it sits right after the header, 6 px from it and from the close button
	local chipRoom = limit - (x + M.HeaderWidth(M.KIT, M.KEYS) + M.GAP)
	local short = math.max(0, M.CHIP_SHRUNK - chipRoom)
	local kitCut = math.min(short, M.KIT - M.KIT_MIN)
	local keysCut = math.min(short - kitCut, M.KEYS - M.KEYS_MIN)
	local pager, kit, keys = M.PAGER, M.KIT - kitCut, M.KEYS - keysCut
	-- a header that would pass the limit loses KIT, then KEYS, then the page buttons (the chip has hidden by then)
	if x + M.HeaderWidth(kit, keys, pager) > limit then kit = 0 end
	if x + M.HeaderWidth(kit, keys, pager) > limit then keys = 0 end
	if x + M.HeaderWidth(kit, keys, pager) > limit then pager = 0 end
	local width = M.HeaderWidth(kit, keys, pager)
	-- with a button dropped the band is all the header's: its right edge for the chip is the limit, so the chip stays hidden
	local full = pager > 0 and kit > 0 and keys > 0
	return { x = x, pager = pager, kit = kit, keys = keys, width = width, right = full and (x + width) or limit, closeLeft = closeLeft }
end

return M
