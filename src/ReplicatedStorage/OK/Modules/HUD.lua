-- OK Studio HUD: level badge + XP bar, money chip ("$12.4K"), OS button (opens the profile), mute-monitors toggle,
-- the career pills (Frame "Career" at x 350: "+380 AURA", "9.4K FOLLOWERS"), floats under them, the BUSY DAY chip, the
-- COLD chip in its slot, and the banner queue (LEVEL UP, the fame tiers and the cold spell's exit). Reads the replicated
-- player attributes Level, XP, LevelXP, NextLevelXP, Cred (the money balance), Aura, Followers, Placements, Hits,
-- Sponsors, BusyDay and Cold, and RS.OK.Cypher's Phase. The pills sit side by side (x 350-620) only when the pair ends
-- 8 px left of the FIRE button's column (vp.X - 152), i.e. from 780 px wide: FIRE's top (y 60 in OK_Fire, which has other insets) can be level with the
-- pills on screen, so they must clear its column, not its top. Else (a notched 844x390 phone gives OK_UI 700-771 px)
-- they stack and end at x 500, left of FIRE from 652 px up. The viewport is OK_UI's ForceViewport attribute (tests) or
-- its size.
-- * Floats (C.Float(text, stat)): every move of a career stat floats under its pill in the stat's colour (Theme.stat);
--   Placements, Hits and Sponsors have no pill and float in the Aura pill's column, as do +XP and +$ (stat nil, in
--   Theme.ledOn). A stat's first value (join) is its baseline and a move of 0 floats nothing. Each column x is a chain
--   of 6 slots, 22 px apart, from the pills' bottom + 30 (y 66 side by side, 96 stacked): the 24 px under the pills
--   stay free for the BUSY DAY chip, and a float rises 6 px at most, so it never reaches the chip's row. A chain
--   starts at slot 0 when none of its floats shows, else at the slot after its last; when all six still show, the
--   oldest goes at once, so no two live floats share a slot. While the cypher bar (OK_Cypher.Bar) drops under the
--   pills (phones, and side-by-side widths below about 932 px) and shows over a column's first row, that chain starts
--   RISE px under the bar, so a float never rises back into it. A float shows 1.3 s. It
--   is 140 wide, except where the other column starts to its right less than 144 px away (side by side, the Aura
--   column: Followers' is 120 px over): there it ends 4 px short of that column (116 wide), so it never runs into that
--   column's floats. Text is 16; only a narrowed float's scales down to fit (never cut). A 140-wide float never
--   scales, as before Task 6.
-- * The pill pop: a change of Aura or Followers pops its pill: the pill's child Frame "Pop" (a stroke in the stat's
--   colour, no fill) scales 1.0 -> 1.08 -> 1.0 with a UIScale while the stroke fades in and out. The pill's own rect
--   never changes, so nothing that reads Career moves.
-- * The LEVEL UP banner (TextLabel "LevelUp", 420x64, top-centre at y 70, 3.5 s) lives in its own ScreenGui,
--   PlayerGui.OK_LevelUp (two sessions, 2026-10-30): DisplayOrder 10, over OK_UI's floats and over the walk-in (8) and
--   phone (9) cards, so a level-up from a card is never hidden; ResetOnSpawn false; IgnoreGuiInset, ScreenInsets and
--   ZIndexBehavior copied from OK_UI, so the banner sits where it did inside OK_UI. LastLevelUp stays on OK_UI. A long
--   text scales down to fit the box (at most TextSize 22).
-- * The banner queue: C.Banner(text) (a fame tier) and C.LevelUp(level, unlockText) share that one banner, one at a time,
--   in order, 3.5 s each, and never replace each other: the second waits. A C.Banner is held while a walk-in card, its
--   result card or a phone card shows, and comes when it closes; a LEVEL UP is never held, so it can pass a held banner.
-- * The BUSY DAY chip (Career.Busy, a 92x20 gold label 4 px under the pills) shows while the server's BusyDay is true
--   and the cypher is idle; Career then grows by 24 px, so every gui that places itself against Career makes room.
-- * The COLD chip (Wave 3, design 4.2: Career.Cold, the same 92x20 label in Theme.muted, "COLD", in BUSY DAY's slot)
--   shows while the server's Cold is true and the cypher is idle, and Career grows the same 24 px. The two never show
--   together: the server starts no burst while you're cold, and here BUSY DAY also hides while Cold is true. Nothing to
--   tap; nothing on the nameplate.
-- Attributes on OK_UI (tests): Floats (count), LastFloat (text), FloatLog (the last 12 floats, "stat|text|x|y" joined by
-- ";": stat empty for +XP / +$, x and y the float's start offset in OK_UI), Pops (count), LastPop (the stat), BannerLog
-- (the last 6 banners' texts as they showed, joined by "|"), LastLevelUp (set when a LEVEL banner shows). Each float label
-- carries the attributes Stat (nil for +XP / +$) and Slot.
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Format = require(RS.OK.Modules.Format)

local M = {}

-- the career stats that float: attribute, stat key, and the unit for the pill-less ones (singular for 1, else plural)
local STATS = {
	{ attr = "Aura", stat = "aura" },
	{ attr = "Followers", stat = "followers" },
	{ attr = "Placements", stat = "placements", one = "PLACEMENT", many = "PLACEMENTS" },
	{ attr = "Hits", stat = "hits", one = "HIT", many = "HITS" },
	{ attr = "Sponsors", stat = "sponsors", one = "SPONSOR", many = "SPONSORS" },
}
local SLOTS, SLOT_H, FLOAT_W = 6, 22, 140 -- a float chain: 6 slots of 22 px, each float 140 wide (or narrower: floatW)
local FLOAT_CLEAR = 4 -- a float narrowed by the next column ends this far left of it
local FLOAT_TEXT = 16 -- a float's text size; a narrowed float's longer text scales down from it
local FLOAT_GAP = 30 -- a chain starts this far under the pills: the chip's row (4 + 20) stays free
local RISE = 6       -- how far a float rises: it stops at the chip row's bottom
local FLOAT_LIFE = 1.3
local BUSY_GAP, BUSY_W, BUSY_H = 4, 92, 20
local LOG_MAX = 12
local POP_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true) -- up, then back
local BANNER_LIFE, BANNER_CHECK, BANNER_LOG = 3.5, 0.2, 6 -- a banner's seconds, how often a held one looks, the log's length

-- "-50 AURA", "+1.5K FOLLOWERS" (the result chip's formula), "+1 PLACEMENT", "+2 HITS"
local function floatText(s, d)
	if s.stat == "aura" then return Format.Signed(d) .. " AURA" end
	if s.stat == "followers" then return (d > 0 and "+" or "-") .. Format.Count(math.abs(d)) .. " FOLLOWERS" end
	return Format.Signed(d) .. " " .. (math.abs(d) == 1 and s.one or s.many)
end

function M.Build(gui, Theme, opts)
	opts = opts or {}
	local player = Players.LocalPlayer
	local function new(class, props, parent)
		local i = Instance.new(class)
		for k, v in pairs(props) do i[k] = v end
		i.Parent = parent
		return i
	end
	local function corner(p, r) new("UICorner", { CornerRadius = UDim.new(0, r or 10) }, p) end

	local chip = new("Frame", { Name = "HUD", Position = UDim2.fromOffset(12, 10), Size = UDim2.fromOffset(330, 48),
		BackgroundColor3 = Theme.panel, BackgroundTransparency = 0.1, BorderSizePixel = 0 }, gui)
	corner(chip, 12)
	new("UIStroke", { Color = Theme.line, Thickness = 1 }, chip)
	local badge = new("TextLabel", { Name = "Level", Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(46, 36),
		BackgroundColor3 = Theme.accent, Text = "LV 1", TextColor3 = Theme.bg, Font = Theme.fontBlack, TextSize = 14 }, chip)
	corner(badge, 8)
	local barBack = new("Frame", { Name = "XPBar", Position = UDim2.fromOffset(60, 26), Size = UDim2.fromOffset(96, 8),
		BackgroundColor3 = Theme.line, BorderSizePixel = 0 }, chip)
	corner(barBack, 4)
	local barFill = new("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = Theme.accent2, BorderSizePixel = 0 }, barBack)
	corner(barFill, 4)
	local xpText = new("TextLabel", { Name = "XPText", Position = UDim2.fromOffset(60, 6), Size = UDim2.fromOffset(98, 18),
		BackgroundTransparency = 1, Text = "0 XP", TextColor3 = Theme.muted, Font = Theme.font, TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left }, chip)
	local money = new("TextLabel", { Name = "Money", Position = UDim2.fromOffset(162, 6), Size = UDim2.fromOffset(64, 36),
		BackgroundColor3 = Theme.bg, Text = Format.CompactMoney(0), TextColor3 = Theme.ledOn, Font = Theme.fontBlack, TextSize = 14 }, chip)
	corner(money, 8)
	local osBtn = new("TextButton", { Name = "OS", Position = UDim2.fromOffset(230, 2), Size = UDim2.fromOffset(44, 44), -- 44 px touch target
		BackgroundColor3 = Theme.line, Text = "OS", TextColor3 = Theme.text, Font = Theme.fontBlack, TextSize = 11 }, chip)
	corner(osBtn, 8)
	local mute = new("TextButton", { Name = "Mute", Position = UDim2.fromOffset(278, 2), Size = UDim2.fromOffset(44, 44),
		BackgroundColor3 = Theme.line, Text = "🔊", TextColor3 = Theme.text, Font = Theme.font, TextSize = 14 }, chip)
	corner(mute, 8)

	-- career pills, right of the HUD (Frame "Career" spans both pills and the BUSY DAY chip while it shows: other bars
	-- place themselves against it)
	local career = new("Frame", { Name = "Career", Position = UDim2.fromOffset(350, 10), Size = UDim2.fromOffset(270, 26),
		BackgroundTransparency = 1 }, gui)
	local function pill(name, w, color)
		local l = new("TextLabel", { Name = name, Size = UDim2.fromOffset(w, 26), BackgroundColor3 = Theme.panel, BackgroundTransparency = 0.1,
			BorderSizePixel = 0, TextColor3 = color, Font = Theme.fontBlack, TextSize = 12, Text = "" }, career)
		corner(l, 13)
		return l
	end
	local auraPill = pill("Aura", 112, Theme.aura)
	local followersPill = pill("Followers", 150, Theme.accent2)
	-- the pop ring: a full-size child centred on the pill, so its UIScale grows it about the pill's centre
	local function ring(p, color)
		local r = new("Frame", { Name = "Pop", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0 }, p)
		corner(r, 13)
		return { stroke = new("UIStroke", { Color = color, Thickness = 2, Transparency = 1 }, r), scale = new("UIScale", { Scale = 1 }, r), tweens = {} }
	end
	local rings = { aura = ring(auraPill, Theme.stat.aura), followers = ring(followersPill, Theme.stat.followers) }
	local busyChip = new("TextLabel", { Name = "Busy", Size = UDim2.fromOffset(BUSY_W, BUSY_H), BackgroundColor3 = Theme.gold,
		BorderSizePixel = 0, TextColor3 = Theme.bg, Font = Theme.fontBlack, TextSize = 10, Text = "BUSY DAY", Visible = false }, career)
	corner(busyChip, 5)
	-- the cold spell's chip: BUSY DAY's component and slot, grey (copy: on the approval list with the cold spell)
	local coldChip = new("TextLabel", { Name = "Cold", Size = UDim2.fromOffset(BUSY_W, BUSY_H), BackgroundColor3 = Theme.muted,
		BorderSizePixel = 0, TextColor3 = Theme.bg, Font = Theme.fontBlack, TextSize = 10, Text = "COLD", Visible = false }, career)
	corner(coldChip, 5)
	local pillsH = 26  -- the pills' height in Career: 26 side by side, 56 stacked (layoutCareer)
	local cypher = nil -- RS.OK.Cypher, once it has replicated
	local function cypherIdle()
		local phase = cypher and cypher:GetAttribute("Phase")
		return phase == nil or phase == "idle"
	end
	local function coldShown() return player:GetAttribute("Cold") == true and cypherIdle() end
	local function busyShown() return player:GetAttribute("BusyDay") == true and player:GetAttribute("Cold") ~= true and cypherIdle() end
	local function layoutCareer()
		local vp = gui:GetAttribute("ForceViewport")
		if typeof(vp) ~= "Vector2" then vp = gui.AbsoluteSize end
		auraPill.Position = UDim2.fromOffset(0, 0)
		local w
		if vp.X - 152 >= 120 + 150 + 350 + 8 then -- side by side: the pair clears FIRE's column in OK_UI's x space
			followersPill.Position = UDim2.fromOffset(120, 0); w, pillsH = 270, 26
		else -- stacked (y 10 and 40): ends at x 500, left of FIRE from 652 px up
			followersPill.Position = UDim2.fromOffset(0, 30); w, pillsH = 150, 56
		end
		local busy, cold = busyShown(), coldShown()
		busyChip.Position = UDim2.fromOffset(0, pillsH + BUSY_GAP)
		busyChip.Visible = busy
		coldChip.Position = busyChip.Position
		coldChip.Visible = cold
		career.Size = UDim2.fromOffset(w, pillsH + ((busy or cold) and BUSY_GAP + BUSY_H or 0))
	end

	-- the banner's own ScreenGui, OK_LevelUp (DisplayOrder 10): over OK_UI's floats, which can share its rows on
	-- 1024-1600 px desktops, and over the walk-in (8) and phone (9) cards. It takes OK_UI's insets, so the banner's rect
	-- is as it was in OK_UI; an OK_LevelUp left by an earlier build is reused (its old banner goes)
	local pgui = gui.Parent or player:FindFirstChildOfClass("PlayerGui")
	local lvGui = pgui and pgui:FindFirstChild("OK_LevelUp")
	if not (lvGui and lvGui:IsA("ScreenGui")) then lvGui = Instance.new("ScreenGui") end
	lvGui.Name = "OK_LevelUp"; lvGui.DisplayOrder = 10; lvGui.ResetOnSpawn = false
	lvGui.IgnoreGuiInset = gui.IgnoreGuiInset; lvGui.ScreenInsets = gui.ScreenInsets; lvGui.ZIndexBehavior = gui.ZIndexBehavior
	do local old = lvGui:FindFirstChild("LevelUp"); if old then old:Destroy() end end
	lvGui.Parent = pgui
	local banner = new("TextLabel", { Name = "LevelUp", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 70),
		Size = UDim2.fromOffset(420, 64), BackgroundColor3 = Theme.panel, TextColor3 = Theme.accent, Font = Theme.fontBlack,
		TextSize = 22, Text = "", Visible = false, TextWrapped = true, TextScaled = true }, lvGui)
	corner(banner, 14)
	new("UIStroke", { Color = Theme.accent, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, banner) -- the box, not the letters
	new("UITextSizeConstraint", { MaxTextSize = 22 }, banner)

	local C = {}
	C.Chip = chip
	C.Career = career
	function C.Refresh()
		local lv = player:GetAttribute("Level") or 1
		local xp = player:GetAttribute("XP") or 0
		local lo = player:GetAttribute("LevelXP") or 0
		local hi = player:GetAttribute("NextLevelXP") or xp
		badge.Text = "LV " .. lv
		money.Text = Format.CompactMoney(player:GetAttribute("Cred") or 0)
		if hi > lo then
			barFill.Size = UDim2.fromScale(math.clamp((xp - lo) / (hi - lo), 0, 1), 1)
			xpText.Text = string.format("%d / %d XP", xp, hi)
		else
			barFill.Size = UDim2.fromScale(1, 1)
			xpText.Text = string.format("%d XP · max level", xp)
		end
		auraPill.Text = Format.Signed(player:GetAttribute("Aura") or 0) .. " AURA"
		followersPill.Text = Format.Count(player:GetAttribute("Followers") or 0) .. " FOLLOWERS"
	end
	local chains = {} -- [column x] = { last = slot, floats = { [slot] = label } }
	local floatLog = {}
	-- the slot for a new float in column x: 0 when none of the chain's floats shows, else the one after its last; a
	-- float still showing there (the oldest: all six show) goes now
	local function takeSlot(x)
		local chain = chains[x]
		if not chain then chain = { last = -1, floats = {} }; chains[x] = chain end
		local live = false
		for s = 0, SLOTS - 1 do
			local f = chain.floats[s]
			if f and f.Parent then live = true; break end
		end
		local slot = live and (chain.last + 1) % SLOTS or 0
		local old = chain.floats[slot]
		if old and old.Parent then old:Destroy() end
		chain.last = slot
		return chain, slot
	end
	-- a float's width in column x: FLOAT_W, or the distance to the other column less FLOAT_CLEAR when that column starts
	-- to its right less than FLOAT_W + FLOAT_CLEAR away (side by side, the Aura column: 116); stacked, both are one
	local function floatW(x)
		local w = FLOAT_W
		for _, p in ipairs({ auraPill, followersPill }) do
			local d = career.Position.X.Offset + p.Position.X.Offset - x
			if d > 0 and d < FLOAT_W + FLOAT_CLEAR then w = math.min(w, d - FLOAT_CLEAR) end
		end
		return w
	end
	-- the cypher bar's rect in this gui's space while it shows (OK_Cypher uses CoreUISafeInsets too), else nil
	local function cypherBar()
		local cy = gui.Parent and gui.Parent:FindFirstChild("OK_Cypher")
		local b = cy and cy:FindFirstChild("Bar")
		if not (b and b:IsA("GuiObject") and b.Visible and b.AbsoluteSize.X > 0) then return nil end
		local p = b.AbsolutePosition - gui.AbsolutePosition
		return { x0 = p.X, y0 = p.Y, x1 = p.X + b.AbsoluteSize.X, y1 = p.Y + b.AbsoluteSize.Y }
	end
	-- a float under the pill of `stat` (Followers' column for "followers", else Aura's), in its colour (+XP / +$:
	-- stat nil, Theme.ledOn), its text FLOAT_TEXT; a narrowed float's (floatW < FLOAT_W) text scales down when it
	-- doesn't fit, and a 140-wide float's never scales (a longer text runs past it, as before). The cypher bar drops
	-- under the pills (y 74) on a gui above this one on phones and on side-by-side widths below about 932 px (CypherUI
	-- keeps it beside the pills only when 240 px fit there): while it shows over the column's x span and the chain's
	-- first row, the chain starts RISE px under it, so the float's rise ends at the bar's bottom, never inside it
	function C.Float(text, stat)
		gui:SetAttribute("Floats", (gui:GetAttribute("Floats") or 0) + 1)
		local p = stat == "followers" and followersPill or auraPill
		local x = career.Position.X.Offset + p.Position.X.Offset
		local chain, slot = takeSlot(x)
		local top = career.Position.Y.Offset + pillsH + FLOAT_GAP -- the chain's y0 (slot 0)
		local y0 = top + slot * SLOT_H
		local w = floatW(x)
		local bar = cypherBar()
		if bar and bar.x0 < x + w and bar.x1 > x and bar.y0 < top + SLOT_H and bar.y1 > top then
			y0 = math.max(y0, math.ceil(bar.y1) + RISE + slot * SLOT_H)
		end
		local f = new("TextLabel", { Name = "Float", Position = UDim2.fromOffset(x, y0), Size = UDim2.fromOffset(w, SLOT_H),
			BackgroundTransparency = 1, Text = text, TextColor3 = (stat and Theme.stat[stat]) or Theme.ledOn, Font = Theme.fontBlack,
			TextSize = FLOAT_TEXT, TextXAlignment = Enum.TextXAlignment.Left }, nil)
		if w < FLOAT_W then -- narrowed: scales down to fit, capped at FLOAT_TEXT; a 140-wide float is as it was
			f.TextScaled = true
			new("UITextSizeConstraint", { MaxTextSize = FLOAT_TEXT }, f)
		end
		f:SetAttribute("Stat", stat)
		f:SetAttribute("Slot", slot)
		f.Parent = gui
		chain.floats[slot] = f
		table.insert(floatLog, string.format("%s|%s|%d|%d", stat or "", text, x, y0))
		if #floatLog > LOG_MAX then table.remove(floatLog, 1) end
		gui:SetAttribute("LastFloat", text)
		gui:SetAttribute("FloatLog", table.concat(floatLog, ";"))
		TweenService:Create(f, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = UDim2.fromOffset(x, y0 - RISE), TextTransparency = 1 }):Play()
		task.delay(FLOAT_LIFE, function() f:Destroy() end)
	end
	-- the pill of `stat` pops (Aura and Followers have pills; the other stats have none to pop)
	local function pop(stat)
		local r = rings[stat]
		if not r then return end
		for _, t in ipairs(r.tweens) do t:Cancel() end
		r.scale.Scale = 1; r.stroke.Transparency = 1
		r.tweens = { TweenService:Create(r.scale, POP_INFO, { Scale = 1.08 }), TweenService:Create(r.stroke, POP_INFO, { Transparency = 0 }) }
		for _, t in ipairs(r.tweens) do t:Play() end
		gui:SetAttribute("Pops", (gui:GetAttribute("Pops") or 0) + 1)
		gui:SetAttribute("LastPop", stat)
	end
	-- the banner queue: { text, level = n (LEVEL UP), hold = true (C.Banner) }, oldest first
	local bannerQueue, bannerLog, bannerRunning = {}, {}, false
	local function showing(guiName, frame) -- WalkInUI and PhoneUI build after this, so found when asked
		local g = gui.Parent and gui.Parent:FindFirstChild(guiName)
		local root = g and g:FindFirstChild("Root")
		local f = root and root:FindFirstChild(frame)
		return f ~= nil and f.Visible
	end
	local function cardUp() return showing("OK_WalkIn", "Card") or showing("OK_WalkIn", "Result") or showing("OK_Phone", "Card") end
	-- the oldest banner free to show, out of the queue
	local function nextBanner()
		for i, b in ipairs(bannerQueue) do
			if not (b.hold and cardUp()) then return table.remove(bannerQueue, i) end
		end
		return nil
	end
	local function showBanner(b)
		banner.Text = b.text
		banner.Visible = true
		table.insert(bannerLog, b.text)
		if #bannerLog > BANNER_LOG then table.remove(bannerLog, 1) end
		gui:SetAttribute("BannerLog", table.concat(bannerLog, "|"))
		if b.level then gui:SetAttribute("LastLevelUp", b.level) end
	end
	local function runBanners()
		if bannerRunning then return end
		bannerRunning = true
		task.spawn(function() -- the first banner shows in this frame, before the spawn's first wait
			while #bannerQueue > 0 do
				local b = nextBanner()
				if b then
					showBanner(b)
					task.wait(BANNER_LIFE)
					banner.Visible = false
				else
					task.wait(BANNER_CHECK)
				end
			end
			bannerRunning = false
		end)
	end
	function C.Banner(text)
		if type(text) ~= "string" or text == "" then return end
		table.insert(bannerQueue, { text = text, hold = true })
		runBanners()
	end
	function C.LevelUp(level, unlockText)
		table.insert(bannerQueue, { text = "LEVEL " .. level .. (unlockText and ("\n" .. unlockText) or ""), level = level })
		runBanners()
	end
	function C.SetMuted(m)
		player:SetAttribute("MuteMonitors", m)
		mute.Text = m and "🔇" or "🔊"
	end
	osBtn.MouseButton1Click:Connect(function() if opts.onOS then opts.onOS() end end)
	mute.MouseButton1Click:Connect(function() C.SetMuted(not player:GetAttribute("MuteMonitors")) end)
	for _, a in ipairs({ "Level", "XP", "LevelXP", "NextLevelXP", "Cred", "Aura", "Followers" }) do
		player:GetAttributeChangedSignal(a):Connect(C.Refresh)
	end
	-- each stat keeps its last value: the first number seen (now, or the first after nil) is the baseline
	for _, s in ipairs(STATS) do
		local last = player:GetAttribute(s.attr)
		if type(last) ~= "number" then last = nil end
		player:GetAttributeChangedSignal(s.attr):Connect(function()
			local v = player:GetAttribute(s.attr)
			if type(v) ~= "number" then last = nil; return end
			if last == nil then last = v; return end
			local d = v - last
			last = v
			if d == 0 then return end
			C.Float(floatText(s, d), s.stat)
			pop(s.stat)
		end)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutCareer)
	gui:GetAttributeChangedSignal("ForceViewport"):Connect(layoutCareer)
	player:GetAttributeChangedSignal("BusyDay"):Connect(layoutCareer)
	player:GetAttributeChangedSignal("Cold"):Connect(layoutCareer)
	-- the cypher's folder may replicate after the HUD is built: watch for it without yielding
	local function watchCypher(f)
		if cypher then return end
		cypher = f
		f:GetAttributeChangedSignal("Phase"):Connect(layoutCareer)
		layoutCareer()
	end
	local found = RS.OK:FindFirstChild("Cypher")
	if found then watchCypher(found)
	else
		local conn
		conn = RS.OK.ChildAdded:Connect(function(c)
			if c.Name == "Cypher" then conn:Disconnect(); watchCypher(c) end
		end)
	end
	layoutCareer()
	C.SetMuted(false)
	C.Refresh()
	return C
end

return M
