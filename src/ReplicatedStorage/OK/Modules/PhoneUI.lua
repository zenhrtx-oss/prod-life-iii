-- OK Studio phone (client, design 4.1). Its own ScreenGui, OK_Phone (DisplayOrder 9, ResetOnSpawn false,
-- CoreUISafeInsets: the same space as OK_UI, OK_WalkIn and OK_Cypher). Listens to the Phone remote itself.
-- * The icon (44 px): beside the career pills (left = OK_UI.Career's right + 8, top = its top - 4; mockup boards 1 and
--   3), or at the top right (right -16, top 8) only when beside them it would enter FIRE's column (Career's right + 8 +
--   44 + 8 > vp.X - 152, the clearance the pills keep, HUD.lua), with vp = OK_UI's ForceViewport or size. The spot is
--   published as the gui attribute IconSpot = "pills" | "corner", so the cypher bar (CypherUI) starts after it and
--   WalkInUI's Waiting chip sits under it; it depends on Career and the viewport only and stays put while the icon is
--   hidden (behind the phone-sized beat maker, and under an open walk-in card, which reaches the top on phones). A red
--   count of the pops waiting; a shake (a UIScale tween on its body) when a pop arrives that can't open, then every
--   SHAKE_EVERY while one waits. Tapping it opens the first waiting pop.
-- * "pop": the card on the right (right -16, top 58: under the icon in both spots, or 8 px under the career pills
--   when they stack (phones, under 780 px: they end at y 66 and reach the card's column); min(300, vp.X * 0.42) wide,
--   at least 240): the app label and the sender's name in the visitor's colour, the message and the choices in a middle
--   that scrolls on phones, the footer with DISMISS. While the cypher bar shows beside the pills (y 10, from 932 px
--   wide) and reaches the card's column, the card sits 8 px under the bar instead, as FIRE does, so it never covers
--   the bar's text; a bar under the pills (phones, y 74) starts at the card's top and shares its rows (documented
--   in t57b, like FIRE and SAMPLE IT). One card at a time, in arrival order: a pop opens by itself only
--   while the beat maker is closed, no listen-back cutaway runs, the cypher is idle and no walk-in card or result card
--   shows (WalkInUI defers to this gui's Open the same way, so the player never sees two cards); otherwise it waits
--   (Deferred). A card that opened by itself fires Phone_Open(token) (the server counts the pop then), focuses its
--   header for a gamepad and ignores button presses for ARM_SECONDS, as the walk-in card does; one opened from the
--   icon is armed at once. A card the heartbeat moves (its top changed: the cypher bar, the pills or the BUSY DAY chip)
--   ignores presses for ARM_SECONDS again, an icon-opened one too, so a tap already on its way never lands on the
--   choice that moved under it. The next waiting pop opens only after the card on screen closes (the server refuses a
--   second DM's open while one is open). The card on screen hides behind the beat maker and the listen-back cutaway
--   (OK_DAW draws under this gui, and on a phone the card would sit on the compact beat maker's pads) unless the icon
--   opened it, as the walk-in card does for a tapped chip. Hidden, it keeps Open, Token and Card (its slot stays taken,
--   so no walk-in card opens meanwhile or races it when the beat maker closes), its arm and auto-close timers run on,
--   the server's open-expiry still ends an unanswered DM, and it comes back armed afresh when the beat maker closes, or
--   at once when the icon is tapped.
-- * A choice sends Phone_Choose(token, index) (0 = dismiss); the server rolls and applies. The result shows inline in
--   the same card (headline, text, chips, note; OK / NICE), and the card closes on OK or after RESULT_SECONDS, as the
--   walk-in result card hides. A NEWS (no choices) gets its result right after its open and closes by itself after
--   Config.Phone.NewsCloseSeconds.
-- * ("expire", { token }): the token is gone on the server, opened or not (expired, a follow-up already taken, a
--   respawn, a Reset): it leaves the list and, when it is the card on screen (armed or not, a NEWS still waiting for its
--   result, or hidden), the card closes with its arm and auto-close timers cancelled. It is never shown or opened
--   again; a token this gui doesn't hold is ignored. A Phone_Choose reply { ok = false, reason = "stale" } closes and
--   drops the card the same way; "invalid" (the server hasn't opened it yet) keeps it.
-- * Config.Phone.Layout = "walkin" draws the card centred at the walk-in card's width instead.
-- * Explainers (Wave 3 design 4.5): a pop whose card carries hint = { term, text } shows it as the last item of the
--   scrolling middle, Card.Scroll.Hint (a Mark "i" and the muted Label), after the last choice (the controller's ruling,
--   fix round 1: a hint may scroll out of view itself but never pushes a choice under the fold). Once the result shows,
--   its own hint takes the line, or the pop's stays (Systems/Phone sends a NEWS result none when the pop had one).
--   Without a hint the line is hidden at zero size and the card is exactly as before.
-- * Feel (CardFeel, shared with WalkInUI): the footer reads your Aura band and follows an Aura change unless a refusal
--   note shows (the card re-lays out); the buzz when a pop arrives (never on a re-shake); the riser when a card opens
--   (open(), once per card); the inline result's sounds and your avatar's reaction. CardFeel gets dawUp: the beat
--   maker or the cutaway is up, or went down within the last second.
-- Layout: every element sits by offset inside Root, a top-left box the size of the gui, or of the gui's ForceViewport
-- attribute (a Vector2) when a test sets one.
-- Attributes on the gui (tests): Open, Deferred (a pop waits and can't open), Pending (the tokens held, open or
-- waiting), Token, Card (card id), Choices (count), ResultKey, ResultTone, LastChoose ("ok" or the refusal), IconSpot,
-- Armed (the buttons take presses: the arm is over); Command = "choose:<n>" | "dismiss" | "open" | "ok" (it skips the
-- arm).
local Players, RS, RunService = game:GetService("Players"), game:GetService("ReplicatedStorage"), game:GetService("RunService")
local TextService, GuiService, UIS = game:GetService("TextService"), game:GetService("GuiService"), game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Config = require(RS.OK.Config)
local Format = require(RS.OK.Modules.Format)
local CardFeel = require(RS.OK.Modules.CardFeel)
local M = {}
local MIN = 44                 -- touch target
local ICON = 44
local PAD = 12                 -- card padding
local TOP, RIGHT, MARGIN = 58, 16, 8 -- the card's top, its distance from the right edge, its bottom margin
local GAP, CGAP = 8, 6         -- row gap, gap between choices
local HEAD = 44                -- the header row: the app label over the sender's name
local ARM_SECONDS = 0.6        -- a card that opened by itself ignores button presses this long
local COST_W = 88              -- the cost column of a paid choice ("$400" / "· can't afford")
local DISMISS_W = 104
local HINT_ICON = 14 -- the hint line's "i" (a 14 px dot); the line sits GAP under the last choice
local RESULT_SECONDS = 8       -- a DM's inline result closes by itself after this (WalkInUI's result card: the same)
local SHAKE_EVERY = 12         -- while a pop waits, the icon shakes again this often
local RED = Color3.fromRGB(235, 55, 55)
local CHOICE_BG = Color3.fromRGB(26, 26, 34)
local REASONS = { afford = "Not enough money for that one yet", invalid = "Not yet · try that again in a moment",
	error = "Couldn't reach the studio · try again" }

-- a visitor colour as sent: a Color3, or a { r, g, b } array (0..255) straight from the content
local function colorOf(c, fallback)
	if typeof(c) == "Color3" then return c end
	if type(c) == "table" and tonumber(c[1]) then return Color3.fromRGB(tonumber(c[1]), tonumber(c[2]) or 0, tonumber(c[3]) or 0) end
	return fallback
end

function M.Build(Theme)
	local player = Players.LocalPlayer
	local pg = player:WaitForChild("PlayerGui", 10)
	local P = Config.Phone or {}
	-- the phone off (Systems/Phone's own switch: Config.Phone or Config.WalkIns Enabled = false): no gui at all, so no
	-- dead icon; without OK_Phone CypherUI reads IconSpot as "pills" and WalkInUI sees no phone card
	if P.Enabled == false or (Config.WalkIns and Config.WalkIns.Enabled == false) then return nil end
	local gui = Instance.new("ScreenGui")
	gui.Name = "OK_Phone"; gui.ResetOnSpawn = false; gui.DisplayOrder = 9
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	for k, v in pairs({ Open = false, Deferred = false, Pending = 0, Token = "", Card = "", Choices = 0, ResultKey = "", ResultTone = "",
		LastChoose = "", Command = "", IconSpot = "pills", Armed = true }) do gui:SetAttribute(k, v) end
	gui.Parent = pg
	local function new(class, props, parent)
		local i = Instance.new(class)
		for k, v in pairs(props) do i[k] = v end
		i.Parent = parent
		return i
	end
	local function corner(p, r) new("UICorner", { CornerRadius = UDim.new(0, r or 10) }, p) end
	local function measure(text, size, font, width)
		local ok, v = pcall(function() return TextService:GetTextSize(text, size, font, Vector2.new(width, 10000)) end)
		return ok and v or Vector2.new(width, size + 4)
	end
	local LEFT, RIGHT_ALIGN = Enum.TextXAlignment.Left, Enum.TextXAlignment.Right
	-- the hint line (WalkInUI's): a small "i" (Mark: never "Icon", the name the phone icon's recursive lookups use) and the
	-- muted text, hidden until a hint is placed in it
	local function hintRow(parent)
		local row = new("Frame", { Name = "Hint", BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false }, parent)
		local mark = new("TextLabel", { Name = "Mark", Size = UDim2.fromOffset(HINT_ICON, HINT_ICON), BackgroundColor3 = Theme.line, BorderSizePixel = 0,
			Font = Theme.fontBlack, TextSize = 10, TextColor3 = Theme.muted, Text = "i" }, row)
		corner(mark, HINT_ICON // 2)
		local label = new("TextLabel", { Name = "Label", Position = UDim2.fromOffset(HINT_ICON + 6, 0), BackgroundTransparency = 1, Font = Theme.font,
			TextSize = 11, TextColor3 = Theme.muted, TextWrapped = true, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, Text = "" }, row)
		return { row = row, label = label }
	end
	-- the hint text a payload carries ({ term, text }), or nil
	local function hintOf(x)
		local h = type(x) == "table" and x.hint or nil
		return (type(h) == "table" and type(h.text) == "string" and h.text ~= "") and h.text or nil
	end
	-- the height a hint line takes at `width` (0 for no hint: it adds nothing to the layout)
	local function hintHeight(text, width)
		if not text then return 0 end
		return math.max(HINT_ICON, math.ceil(measure(text, 11, Theme.font, math.max(40, width - HINT_ICON - 6)).Y) + 2)
	end
	-- the row at (x, y) in its parent, `width` wide and h tall; h = 0 hides it at zero size (it takes no space)
	local function placeHint(hr, text, x, y, width, h)
		hr.row.Visible = h > 0
		hr.label.Text = h > 0 and text or ""
		hr.row.Position = UDim2.fromOffset(x, y); hr.row.Size = UDim2.fromOffset(h > 0 and width or 0, h)
		hr.label.Size = UDim2.fromOffset(h > 0 and math.max(40, width - HINT_ICON - 6) or 0, h)
	end

	local root = new("Frame", { Name = "Root", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 0) }, gui)

	-- the icon -----------------------------------------------------------------------------------------------------------
	local icon = new("TextButton", { Name = "Icon", Size = UDim2.fromOffset(ICON, ICON), BackgroundColor3 = Theme.panel, BorderSizePixel = 0,
		Text = "", AutoButtonColor = true, Selectable = true }, root)
	corner(icon, 12)
	new("UIStroke", { Color = Theme.line, Thickness = 1 }, icon)
	local body = new("Frame", { Name = "Body", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, icon) -- what the shake scales
	local shake = new("UIScale", { Name = "Shake", Scale = 1 }, body)
	new("TextLabel", { Name = "Glyph", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Theme.font, TextSize = 22,
		TextColor3 = Theme.text, Text = "📱" }, body)
	local badge = new("TextLabel", { Name = "Count", Position = UDim2.fromOffset(24, 0), Size = UDim2.fromOffset(20, 20), BackgroundColor3 = RED,
		BorderSizePixel = 0, Font = Theme.fontBlack, TextSize = 11, TextColor3 = Color3.new(1, 1, 1), Text = "", Visible = false, ZIndex = 2 }, body)
	corner(badge, 10)
	local shakeTween = TweenService:Create(shake, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 2, true), { Scale = 1.2 })

	-- the card -----------------------------------------------------------------------------------------------------------
	local card = new("Frame", { Name = "Card", BackgroundColor3 = Theme.panel, BorderSizePixel = 0, Visible = false, Active = true }, root)
	corner(card, 14)
	local cardStroke = new("UIStroke", { Color = Theme.line, Thickness = 1.5 }, card)
	-- the app label: selectable so a gamepad can rest on it (it commits nothing) when the card opens by itself
	local header = new("TextLabel", { Name = "Header", BackgroundColor3 = Theme.bg, BorderSizePixel = 0, Font = Theme.fontBlack, TextSize = 10,
		TextColor3 = Theme.muted, Text = "", Selectable = true }, card)
	corner(header, 11)
	local senderL = new("TextLabel", { Name = "Sender", BackgroundTransparency = 1, Font = Theme.fontBlack, TextSize = 15, TextColor3 = Theme.accent,
		TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Text = "" }, card)
	-- the middle scrolls when a phone can't fit the message and the choices
	local scroll = new("ScrollingFrame", { Name = "Scroll", BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.muted, ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.new() }, card)
	local lineL = new("TextLabel", { Name = "Line", BackgroundTransparency = 1, Font = Theme.font, TextSize = 14, TextColor3 = Theme.text,
		TextWrapped = true, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, Text = "" }, scroll)
	-- a card that opened by itself takes no button press before this os.clock(): the press was meant for the game.
	-- Only the buttons check it; the Command attribute (what they send, and the tests' seam) acts at once, so the gui's
	-- Armed attribute shows the arm: set with it (arm) and on every heartbeat (syncArmed)
	local armedUntil = 0
	local function armed() return os.clock() >= armedUntil end
	local function syncArmed() local a = armed(); if gui:GetAttribute("Armed") ~= a then gui:SetAttribute("Armed", a) end end
	local function arm(untilClock) armedUntil = untilClock; syncArmed() end
	local parts = {}
	for i = 1, 4 do
		local b = new("TextButton", { Name = "Choice" .. i, BackgroundColor3 = CHOICE_BG, BorderSizePixel = 0, AutoButtonColor = true, Text = "",
			Visible = false, Selectable = true }, scroll)
		corner(b, 9)
		new("UIStroke", { Color = Theme.line, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
		local label = new("TextLabel", { Name = "Label", BackgroundTransparency = 1, Font = Theme.font, TextSize = 13, TextColor3 = Theme.text,
			TextWrapped = true, TextXAlignment = LEFT, Text = "" }, b)
		local cost = new("TextLabel", { Name = "Cost", BackgroundTransparency = 1, Font = Theme.fontBlack, TextSize = 12, TextColor3 = Theme.ledOn,
			TextWrapped = true, TextXAlignment = RIGHT_ALIGN, Text = "" }, b)
		b.MouseButton1Click:Connect(function() if armed() then gui:SetAttribute("Command", "choose:" .. i) end end)
		parts[i] = { btn = b, label = label, cost = cost }
	end
	-- the inline result (in the scrolling middle, in place of the message and the choices)
	local res = new("Frame", { Name = "Result", BackgroundTransparency = 1, Visible = false }, scroll)
	local resHead = new("TextLabel", { Name = "Headline", BackgroundTransparency = 1, Font = Theme.fontBlack, TextSize = 18, TextColor3 = Theme.gold,
		TextWrapped = true, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, Text = "" }, res)
	local resText = new("TextLabel", { Name = "Text", BackgroundTransparency = 1, Font = Theme.font, TextSize = 12, TextColor3 = Theme.text,
		TextWrapped = true, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, Text = "" }, res)
	local resChips = new("Frame", { Name = "Chips", BackgroundTransparency = 1, ClipsDescendants = true }, res)
	local resNote = new("TextLabel", { Name = "Note", BackgroundTransparency = 1, Font = Theme.font, TextSize = 10, TextColor3 = Theme.muted,
		TextWrapped = true, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, Text = "" }, res)
	local footer = new("TextLabel", { Name = "Footer", BackgroundTransparency = 1, Font = Theme.font, TextSize = 11, TextColor3 = Theme.muted,
		TextWrapped = true, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, Text = CardFeel.Footer() }, card)
	local dismiss = new("TextButton", { Name = "Dismiss", BackgroundColor3 = Theme.line, BorderSizePixel = 0, Font = Theme.fontBlack, TextSize = 13,
		TextColor3 = Theme.text, Text = "DISMISS", AutoButtonColor = true, Selectable = true }, card)
	corner(dismiss, 9)
	local cardHint = hintRow(scroll) -- the last item in the scrolling middle, after the choices or the inline result

	-- helpers ------------------------------------------------------------------------------------------------------------
	local function toneColor(tone)
		if tone == "win" then return Theme.gold elseif tone == "loss" then return Theme.accent2 end
		return Theme.muted
	end
	local function chipColor(c)
		if tostring(c.label or ""):sub(1, 1) == "-" then return Theme.accent2 end -- a loss reads cold, whatever it is
		return Theme.stat[c.kind] or Theme.gold -- the stat's colour (UITheme.stat); an unknown kind reads gold
	end
	-- lays chips ({ label, kind }) out left to right inside holder, wrapping at maxW; returns the height used (0 if none)
	local function flow(holder, chips, maxW, h, size, bg)
		for _, ch in ipairs(holder:GetChildren()) do if ch:IsA("GuiObject") then ch:Destroy() end end
		local x, y, any = 0, 0, false
		for i, c in ipairs(type(chips) == "table" and chips or {}) do
			if type(c) == "table" then
				local text = tostring(c.label or "")
				local w = math.min(maxW, math.ceil(measure(text, size, Theme.fontBlack, 1000).X) + 16)
				if x > 0 and x + w > maxW then x = 0; y += h + 6 end
				local l = new("TextLabel", { Name = "Chip" .. i, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = bg,
					BorderSizePixel = 0, Font = Theme.fontBlack, TextSize = size, TextColor3 = chipColor(c), Text = text,
					TextTruncate = Enum.TextTruncate.AtEnd }, holder)
				corner(l, 6)
				x += w + 6; any = true
			end
		end
		return any and (y + h) or 0
	end
	local function viewport()
		local f = gui:GetAttribute("ForceViewport")
		if typeof(f) == "Vector2" and f.X > 0 and f.Y > 0 then return f end
		local s = gui.AbsoluteSize
		if s.X > 0 and s.Y > 0 then return s end
		local cam = workspace.CurrentCamera
		return cam and cam.ViewportSize or Vector2.new(1280, 720)
	end
	-- the HUD's viewport (its ForceViewport, else its size): the icon's spot follows the pills, which follow it
	local function uiViewport()
		local ui = pg:FindFirstChild("OK_UI")
		local f = ui and ui:GetAttribute("ForceViewport")
		if typeof(f) == "Vector2" and f.X > 0 and f.Y > 0 then return f end
		if ui and ui.AbsoluteSize.X > 0 and ui.AbsoluteSize.Y > 0 then return ui.AbsoluteSize end
		return viewport()
	end
	local function cred() return tonumber(player:GetAttribute("Cred")) or 0 end
	local function costOf(c) return math.max(0, math.floor(tonumber(c.cost) or 0)) end
	-- the card's width at a viewport: the walk-in card's (centred layout) or min(300, 42 %), at least 240
	local function cardW(vp)
		if P.Layout == "walkin" then return math.max(220, math.min(500, vp.X - 32)) end
		return math.max(240, math.min(300, math.floor(vp.X * 0.42)))
	end
	-- the card's top: TOP (under the icon), raised to MARGIN under the career pills when they reach the card's column
	-- (stacked on phones, HUD.layoutCareer, they end at y 66; side by side they end at 36, so TOP stays), or MARGIN under
	-- the cypher bar while it shows beside the pills (it starts above that base) and reaches the card's column, the way
	-- FIRE sits under it (FireButton), so the card never covers its text. A bar under the pills (phones, y 74) starts
	-- at the base and is left alone: under it the card would not fit a phone's box, so it shares the card's rows
	-- (documented in t57b, like FIRE and SAMPLE IT). All three guis use CoreUISafeInsets; the rects are read in this
	-- gui's space, as placeIcon reads Career's
	local function cardTop(vp, W)
		if P.Layout == "walkin" then return TOP end
		local base = TOP
		local ui = pg:FindFirstChild("OK_UI")
		local career = ui and ui:FindFirstChild("Career")
		if career and career:IsA("GuiObject") and career.AbsoluteSize.X > 0 then
			local r = career.AbsolutePosition - gui.AbsolutePosition
			if r.X + career.AbsoluteSize.X > vp.X - RIGHT - W then base = math.max(TOP, math.floor(r.Y + career.AbsoluteSize.Y + MARGIN)) end
		end
		local cy = pg:FindFirstChild("OK_Cypher")
		local b = cy and cy:FindFirstChild("Bar")
		if b and b:IsA("GuiObject") and b.Visible and b.AbsoluteSize.X > 0 then
			local p = b.AbsolutePosition - gui.AbsolutePosition
			local x1, y1 = p.X + b.AbsoluteSize.X, p.Y + b.AbsoluteSize.Y
			if p.Y < base and p.X < vp.X - RIGHT and x1 > vp.X - RIGHT - W then return math.max(base, math.floor(y1 + MARGIN)) end
		end
		return base
	end
	local cardY = TOP -- the top the last layout used; the heartbeat re-lays the card out when the bar changes it

	local held = {}        -- the pops this client holds, in arrival order: { token, card }
	local cur = nil        -- the card on screen: { token, card, news, result? }; its token stays in held until the server drops it
	local forced = false   -- the card on screen was asked for (the icon): armed at once, and never hidden
	local hidden = false   -- the card on screen is behind the beat maker or the cutaway (its slot stays taken: Open stays true)
	local busy = false     -- a Phone_Choose call is out
	local closeSerial = 0  -- bumps cancel the pending auto-close
	local deferred, spot, lastShake, noteUntil = false, "pills", -math.huge, 0
	local function indexOf(token)
		for i, e in ipairs(held) do if e.token == token then return i end end
		return nil
	end
	local function waiting() return #held - ((cur and indexOf(cur.token)) and 1 or 0) end
	local function choices() return (cur and not cur.news and type(cur.card.choices) == "table") and cur.card.choices or {} end
	local function setPending()
		local n = waiting()
		gui:SetAttribute("Pending", #held)
		badge.Text = tostring(n); badge.Visible = n > 0
	end
	local function doShake() lastShake = os.clock(); shakeTween:Play() end

	-- costs and the "can't afford" grey; runs again whenever the Cred attribute (your money) changes
	local function paintChoices()
		local list = choices()
		for i, part in ipairs(parts) do
			local c = list[i]
			part.btn.Visible = type(c) == "table" and not (cur and cur.result)
			if type(c) == "table" then
				local cost = costOf(c)
				local broke = cost > cred()
				part.label.Text = tostring(c.text or "")
				part.cost.Text = cost > 0 and (Format.Money(cost) .. (broke and "\n· can't afford" or "")) or ""
				part.btn.BackgroundColor3 = broke and Theme.bg or CHOICE_BG
				part.btn.AutoButtonColor = not broke
				part.label.TextColor3 = broke and Theme.muted or Theme.text
				part.cost.TextColor3 = broke and Theme.muted or Theme.ledOn
			end
		end
	end

	-- lays out the scrolling middle at `width` (the message and the choices, or the inline result) and returns its height
	local function layoutBody(width)
		local y = 0
		local showing = cur ~= nil and cur.result ~= nil
		local lineH = (not showing and lineL.Text ~= "") and (math.ceil(measure(lineL.Text, 14, Theme.font, width).Y) + 4) or 0
		lineL.Visible = lineH > 0
		lineL.Position = UDim2.fromOffset(0, 0); lineL.Size = UDim2.fromOffset(width, lineH)
		if lineH > 0 then y = lineH + GAP end
		res.Visible = showing
		if showing then
			for _, part in ipairs(parts) do part.btn.Visible = false end
			local hh = math.ceil(measure(resHead.Text, 18, Theme.fontBlack, width).Y) + 2
			resHead.Position = UDim2.fromOffset(0, 0); resHead.Size = UDim2.fromOffset(width, hh)
			local ty = hh + 4
			local th = resText.Text ~= "" and (math.ceil(measure(resText.Text, 12, Theme.font, width).Y) + 2) or 0
			resText.Visible = th > 0
			resText.Position = UDim2.fromOffset(0, ty); resText.Size = UDim2.fromOffset(width, math.max(1, th))
			local cy = ty + (th > 0 and th + 6 or 0)
			local ch = flow(resChips, cur.result.chips, width, 22, 11, Theme.bg)
			resChips.Position = UDim2.fromOffset(0, cy); resChips.Size = UDim2.fromOffset(width, math.max(1, ch))
			local ny = cy + (ch > 0 and ch + 6 or 0)
			local nh = resNote.Text ~= "" and (math.ceil(measure(resNote.Text, 10, Theme.font, width).Y) + 2) or 0
			resNote.Visible = nh > 0
			resNote.Position = UDim2.fromOffset(0, ny); resNote.Size = UDim2.fromOffset(width, math.max(1, nh))
			local rh = ny + nh
			res.Position = UDim2.fromOffset(0, y); res.Size = UDim2.fromOffset(width, rh)
			return y + rh
		end
		local list, n = choices(), 0
		for i, part in ipairs(parts) do
			local b = part.btn
			b.Position = UDim2.fromOffset(0, y + (i - 1) * (MIN + CGAP)); b.Size = UDim2.fromOffset(width, MIN)
			local costW = (list[i] and costOf(list[i]) > 0) and COST_W or 0
			local lw = width - 24 - (costW > 0 and costW + 8 or 0)
			part.label.Position = UDim2.fromOffset(12, 0); part.label.Size = UDim2.fromOffset(lw, MIN)
			-- two lines of 13 px fit 44 px; a longer text drops to 11 px
			part.label.TextSize = measure(part.label.Text, 13, Theme.font, lw).Y <= MIN - 8 and 13 or 11
			part.cost.Visible = costW > 0
			part.cost.Position = UDim2.fromOffset(width - 12 - costW, 0); part.cost.Size = UDim2.fromOffset(costW, MIN)
			if b.Visible then n += 1 end
		end
		if n > 0 then return y + n * MIN + (n - 1) * CGAP end
		return math.max(0, y - GAP)
	end
	-- positions the card from the viewport (real, or ForceViewport): the header row, the scrolling middle, the footer
	-- row with DISMISS. Layout "phone": on the right under the icon (or under the cypher bar beside the pills, cardTop);
	-- "walkin": centred at the walk-in card's width
	local function layout()
		local vp = viewport()
		root.Size = UDim2.fromOffset(vp.X, vp.Y)
		local walkin = P.Layout == "walkin"
		local W = cardW(vp)
		local top0 = cardTop(vp, W)
		local inner = W - 2 * PAD
		local top = PAD
		local headerW = math.min(inner, math.ceil(measure(header.Text, 10, Theme.fontBlack, 1000).X) + 20)
		header.Position = UDim2.fromOffset(PAD, top); header.Size = UDim2.fromOffset(headerW, 22)
		senderL.Position = UDim2.fromOffset(PAD, top + 24); senderL.Size = UDim2.fromOffset(inner, 20)
		-- the footer line sits beside DISMISS when it fits 44 px there (wide cards), else above it
		local fw = inner - DISMISS_W - 8
		local beside = math.ceil(measure(footer.Text, 11, Theme.font, fw).Y) <= MIN
		local fh = beside and MIN or math.ceil(measure(footer.Text, 11, Theme.font, inner).Y)
		local rowH = beside and MIN or (fh + 6 + MIN)
		local fixed = top + HEAD + GAP + GAP + rowH + top
		local room = math.max(MIN, (walkin and (vp.Y - 16) or (vp.Y - top0 - MARGIN)) - fixed)
		local width = inner
		local contentH = layoutBody(width)
		if contentH > room then width = inner - 8; contentH = layoutBody(width) end -- the scroll bar gets its own lane
		-- the hint (the result's, else the pop's): always the last item in the scroll, after the last choice or the inline
		-- result, so it can only push itself under the fold, never a choice. The body above is laid out as with no hint;
		-- when only the hint makes it scroll, the bar gets its lane if narrowing moves nothing, else it draws over the edge
		local hintText = cur and (hintOf(cur.result) or hintOf(cur.card)) or nil
		local bodyH = contentH
		local hintH = hintHeight(hintText, width)
		if hintH > 0 then
			contentH = bodyH + GAP + hintH
			if contentH > room and width == inner then
				if layoutBody(inner - 8) == bodyH then
					width = inner - 8
					hintH = hintHeight(hintText, width)
					contentH = bodyH + GAP + hintH
				else
					layoutBody(inner)
				end
			end
		end
		placeHint(cardHint, hintText, 0, bodyH + GAP, width, hintH)
		local scrollH = math.min(contentH, room)
		scroll.Position = UDim2.fromOffset(PAD, top + HEAD + GAP); scroll.Size = UDim2.fromOffset(inner, math.max(1, scrollH))
		scroll.CanvasSize = UDim2.fromOffset(0, contentH)
		local fy = top + HEAD + GAP + scrollH + GAP
		footer.Position = UDim2.fromOffset(PAD, fy); footer.Size = UDim2.fromOffset(beside and fw or inner, fh)
		dismiss.Position = UDim2.fromOffset(W - PAD - DISMISS_W, beside and fy or (fy + fh + 6)); dismiss.Size = UDim2.fromOffset(DISMISS_W, MIN)
		local H = fy + rowH + top
		card.Size = UDim2.fromOffset(W, H)
		if walkin then card.Position = UDim2.fromOffset(math.floor((vp.X - W) / 2), math.max(8, math.floor((vp.Y - H) / 2)))
		else card.Position = UDim2.fromOffset(vp.X - RIGHT - W, top0) end
		cardY = top0
	end
	-- the icon's spot: beside the pills (Career's rect read in this gui's space; both guis use CoreUISafeInsets), else the
	-- top right when beside them it would enter FIRE's column (the test the pills make in HUD.layoutCareer)
	local function placeIcon()
		local vp = uiViewport()
		local ui = pg:FindFirstChild("OK_UI")
		local career = ui and ui:FindFirstChild("Career")
		local s, x, y = "corner", vp.X - RIGHT - ICON, 8
		if career and career:IsA("GuiObject") and career.AbsoluteSize.X > 0 then
			local rel = career.AbsolutePosition - gui.AbsolutePosition
			local right = rel.X + career.AbsoluteSize.X
			if right + 8 + ICON + 8 <= vp.X - 152 then s, x, y = "pills", right + 8, rel.Y - 4 end
		end
		icon.Position = UDim2.fromOffset(math.floor(x), math.floor(y))
		if s ~= spot then spot = s; gui:SetAttribute("IconSpot", s) end
	end

	-- deferral, each looked up afresh (WalkInUI's lookups). dawOrCutaway: the beat maker is open or the listen-back
	-- cutaway runs; its second value says the beat maker is the phone (compact) one that fills the screen; each check
	-- also records when it last went from true to false (dawUp; the heartbeat checks every 0.2 s). cypherBusy: a
	-- cypher round isn't idle. walkInBusy: a walk-in card or the walk-in result card (a result or the note) shows
	local reqCard = nil
	local dawWasUp, dawDownAt = false, -math.huge
	local function dawOrCutaway()
		local dg = pg:FindFirstChild("OK_DAW")
		local d = dg and dg:FindFirstChild("DAW")
		local up, compact = false, false
		if d and d:IsA("GuiObject") and d.Visible then
			up, compact = true, d:GetAttribute("Compact") == true
		else
			if d and not (reqCard and reqCard:IsDescendantOf(d)) then reqCard = d:FindFirstChild("Request", true) end
			up = reqCard ~= nil and reqCard:GetAttribute("Cutaway") == true
		end
		if dawWasUp and not up then dawDownAt = os.clock() end
		dawWasUp = up
		return up, compact
	end
	-- for CardFeel.Result: the beat maker or the cutaway is up, or went down within the last second
	local function dawUp() return (dawOrCutaway()) or os.clock() - dawDownAt <= 1 end
	local function cypherBusy()
		local cy = RS.OK:FindFirstChild("Cypher")
		local phase = cy and cy:GetAttribute("Phase")
		return phase ~= nil and phase ~= "idle"
	end
	local function walkInOpen()
		local wg = pg:FindFirstChild("OK_WalkIn")
		return wg ~= nil and wg:GetAttribute("Open") == true
	end
	local function walkInBusy()
		if walkInOpen() then return true end
		local wg = pg:FindFirstChild("OK_WalkIn")
		local r = wg and wg:FindFirstChild("Result", true)
		return r ~= nil and r:IsA("GuiObject") and r.Visible
	end
	local function blocked() return dawOrCutaway() or cypherBusy() or walkInBusy() end
	local function refreshDeferred()
		local d = cur == nil and #held > 0 and blocked()
		if d ~= deferred then deferred = d; gui:SetAttribute("Deferred", d) end
	end
	local function releaseSelection()
		local s = GuiService.SelectedObject
		if s and s:IsDescendantOf(card) then GuiService.SelectedObject = nil end
	end
	local function resetFooter() noteUntil = 0; footer.Text = CardFeel.Footer(); footer.TextColor3 = Theme.muted end
	local function note(text) footer.Text = text; footer.TextColor3 = Theme.accent; noteUntil = os.clock() + 4; layout() end

	-- the card for held entry e goes on screen; byHand = from the icon (armed at once, Choice 1 ready for a gamepad)
	local function open(e, byHand)
		cur = { token = e.token, card = e.card, news = e.card.news == true }
		forced = byHand == true
		local c = e.card
		local s = type(c.sender) == "table" and c.sender or {}
		header.Text = tostring(c.app or "MESSAGES")
		senderL.Text = tostring(s.name or "?"); senderL.TextColor3 = colorOf(s.color, Theme.accent)
		lineL.Text = (type(c.line) == "string" and c.line ~= "") and ("“" .. c.line .. "”") or ""
		cardStroke.Color = Theme.line
		dismiss.Text = cur.news and "OK" or "DISMISS"; dismiss.BackgroundColor3 = Theme.line; dismiss.TextColor3 = Theme.text
		paintChoices()
		gui:SetAttribute("Token", tostring(e.token)); gui:SetAttribute("Card", tostring(c.id or "")); gui:SetAttribute("Choices", #choices())
		gui:SetAttribute("ResultKey", ""); gui:SetAttribute("ResultTone", "")
		resetFooter()
		scroll.CanvasPosition = Vector2.new(0, 0)
		layout()
		hidden = false
		card.Visible = true
		gui:SetAttribute("Open", true)
		-- opened by itself: rest a gamepad on the header (it commits nothing) and ignore presses for a moment; opened
		-- from the icon: the player asked, so Choice 1 is ready
		arm(forced and 0 or (os.clock() + ARM_SECONDS))
		if UIS:GetLastInputType().Name:find("Gamepad") then
			GuiService.SelectedObject = not forced and header or (parts[1].btn.Visible and parts[1].btn or dismiss)
		end
		setPending(); refreshDeferred()
		CardFeel.Opened(e.token)
		local ok, err = pcall(function() RS.OK.Remotes.Phone_Open:FireServer(e.token) end)
		if not ok then warn("[OK][ERR] PhoneUI: Phone_Open: " .. tostring(err)) end
	end
	local function drop(token)
		local i = indexOf(token)
		if i then table.remove(held, i) end
		setPending()
	end
	-- the card on screen goes, its arm and auto-close cancelled; the next waiting pop may open on the next check
	local function close()
		if not cur then return end
		cur, forced, hidden = nil, false, false
		closeSerial += 1
		arm(0)
		card.Visible = false
		releaseSelection()
		gui:SetAttribute("Open", false); gui:SetAttribute("Token", ""); gui:SetAttribute("Card", ""); gui:SetAttribute("Choices", 0)
		resetFooter()
		setPending(); refreshDeferred()
	end
	-- the card on screen hides behind the beat maker and the cutaway unless the icon opened it (WalkInUI's forced chip),
	-- and only its drawing changes: cur, Open, Token and Card stay, so the slot stays taken and nothing opens over it.
	-- Hidden, a gamepad leaves it; back on screen it rests on the header (or OK) and presses are ignored for ARM_SECONDS
	-- again (the press that closed the beat maker was meant for the game), unless the player asked for it from the icon
	local function showCard()
		local h = cur ~= nil and not forced and dawOrCutaway() == true
		if h == hidden then return end
		hidden = h
		card.Visible = cur ~= nil and not h
		if h then
			releaseSelection()
		elseif cur then
			arm(forced and 0 or (os.clock() + ARM_SECONDS))
			if UIS:GetLastInputType().Name:find("Gamepad") then
				GuiService.SelectedObject = (cur.result or forced) and (parts[1].btn.Visible and parts[1].btn or dismiss) or header
			end
		end
	end
	-- the result shows inline in the card on screen, once per card (a DM's comes both as the Phone_Choose reply and as
	-- the "result" message); the card closes by itself later unless OK comes first
	local function showResult(r)
		if not cur or cur.result or type(r) ~= "table" then return end
		cur.result = r
		local tone = r.tone
		resHead.Text = tostring(r.headline or ""); resHead.TextColor3 = toneColor(tone)
		cardStroke.Color = toneColor(tone)
		resText.Text = tostring(r.text or "")
		resNote.Text = tostring(r.note or "")
		dismiss.Text = tone == "win" and "NICE" or "OK"
		dismiss.BackgroundColor3 = tone == "win" and Theme.gold or Theme.line
		dismiss.TextColor3 = tone == "win" and Theme.bg or Theme.text
		gui:SetAttribute("ResultKey", tostring(r.key or "")); gui:SetAttribute("ResultTone", tostring(tone or "")); gui:SetAttribute("Choices", 0)
		scroll.CanvasPosition = Vector2.new(0, 0)
		layout()
		if UIS:GetLastInputType().Name:find("Gamepad") then GuiService.SelectedObject = dismiss end
		closeSerial += 1
		local my = closeSerial
		local after = cur.news and (tonumber(P.NewsCloseSeconds) or RESULT_SECONDS) or RESULT_SECONDS
		task.delay(after, function() if closeSerial == my then close() end end)
		CardFeel.Result(r, dawUp())
	end

	local function choose(index)
		if not cur or busy or cur.result then return end
		-- a NEWS has nothing to choose: the server never takes a Choose on one (opened, it is already gone: "stale" would
		-- close the card the moment its result drew). Its result, or an expire, always comes; OK after the result closes it
		if cur.news then return end
		if index > 0 then
			local c = choices()[index]
			if type(c) ~= "table" then gui:SetAttribute("LastChoose", "invalid"); return end
			if costOf(c) > cred() then gui:SetAttribute("LastChoose", "afford"); note(REASONS.afford); return end
		end
		local token = cur.token
		busy = true
		local ok, r0 = pcall(function() return RS.OK.Remotes.Phone_Choose:InvokeServer(token, index) end)
		busy = false
		local r = (ok and type(r0) == "table") and r0 or { ok = false, reason = "error" }
		gui:SetAttribute("LastChoose", r.ok and "ok" or tostring(r.reason))
		if not cur or cur.token ~= token then return end -- the card went (an expire) while the call was out
		if r.ok then
			drop(token) -- applied: the token is gone on the server
			if index == 0 or type(r.result) ~= "table" then close() else showResult(r.result) end
		elseif r.reason == "stale" then -- the token is gone on the server: as an expire
			drop(token); close()
		else
			note(REASONS[r.reason] or REASONS.error) -- invalid (not opened on the server yet), afford, error: the card stays
		end
	end

	-- input and test commands ----------------------------------------------------------------------------------------------
	dismiss.MouseButton1Click:Connect(function() if armed() then gui:SetAttribute("Command", (cur and cur.result) and "ok" or "dismiss") end end)
	icon.MouseButton1Click:Connect(function() gui:SetAttribute("Command", "open") end)
	gui:GetAttributeChangedSignal("Command"):Connect(function()
		local c = gui:GetAttribute("Command")
		if type(c) ~= "string" or c == "" then return end
		gui:SetAttribute("Command", "")
		if c == "dismiss" then choose(0)
		elseif c == "ok" then if cur and cur.result then close() elseif cur then choose(0) end
		elseif c == "open" then
			if cur then if hidden then forced = true; showCard() end -- the icon brings back the card hidden behind the beat maker
			elseif #held > 0 and not walkInBusy() then open(held[1], true) end
		else
			local n = tonumber(string.match(c, "^choose:(%d)$"))
			if n then choose(n) end
		end
	end)

	local R = RS.OK.Remotes
	local ev = R:FindFirstChild("Phone")
	if ev and R:FindFirstChild("Phone_Open") and R:FindFirstChild("Phone_Choose") then
		ev.OnClientEvent:Connect(function(kind, payload)
			if type(payload) ~= "table" then return end
			local token = payload.token
			if kind == "pop" then
				if type(token) ~= "string" or type(payload.card) ~= "table" or indexOf(token) then return end
				table.insert(held, { token = token, card = payload.card })
				CardFeel.Pop(token)
				setPending()
				if not cur and not blocked() then open(held[1], false) end
				if waiting() > 0 then doShake() end
				refreshDeferred()
			elseif kind == "result" then
				drop(token) -- its result is out: the server no longer holds it
				if cur and cur.token == token then showResult(payload) end
			elseif kind == "expire" then
				if not indexOf(token) and not (cur and cur.token == token) then return end -- not ours (a Quiet test's, an old one)
				drop(token)
				if cur and cur.token == token then close() end
				refreshDeferred()
			end
		end)
	else
		warn("[OK][ERR] PhoneUI: ReplicatedStorage.OK.Remotes.Phone / Phone_Open / Phone_Choose missing (run build/17_career_remotes.lua)")
	end
	player:GetAttributeChangedSignal("Cred"):Connect(function() if cur then paintChoices(); layout() end end)
	-- the footer follows your Aura band, unless a refusal note shows (it comes back with the band line when it ends)
	player:GetAttributeChangedSignal("Aura"):Connect(function()
		if noteUntil == 0 or os.clock() > noteUntil then resetFooter(); layout() end
	end)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() layout(); placeIcon() end)
	gui:GetAttributeChangedSignal("ForceViewport"):Connect(function() layout(); placeIcon() end)
	do local ui = pg:FindFirstChild("OK_UI"); if ui then ui:GetAttributeChangedSignal("ForceViewport"):Connect(placeIcon) end end
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		syncArmed() -- every frame, so Armed turns true the frame the arm ends
		acc += dt; if acc < 0.2 then return end; acc = 0
		placeIcon()
		local _, compactDaw = dawOrCutaway()
		icon.Visible = not compactDaw and not walkInOpen()
		if not cur and #held > 0 and not blocked() then open(held[1], false) end
		showCard()
		-- the cypher bar came, went or grew beside the pills, the pills stacked or unstacked, or the BUSY DAY chip came or
		-- went: the card on screen moves under them, or back up to TOP, and re-arms (a forced card too), so a finger
		-- already on its way never lands on the choice that moved under it
		if cur and not hidden then
			local vp = viewport()
			if cardTop(vp, cardW(vp)) ~= cardY then layout(); arm(math.max(armedUntil, os.clock() + ARM_SECONDS)) end
		end
		refreshDeferred()
		if deferred and os.clock() - lastShake >= SHAKE_EVERY then doShake() end
		if noteUntil > 0 and os.clock() > noteUntil then resetFooter(); layout() end
	end)
	layout(); placeIcon(); setPending()
	return { Gui = gui, Icon = icon, Card = card }
end

return M
