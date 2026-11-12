-- OK Studio walk-in card (client). Its own ScreenGui, OK_WalkIn (DisplayOrder 8, ResetOnSpawn false, CoreUISafeInsets:
-- the same space as OK_UI and OK_Cypher). Listens to the WalkIn remote itself:
-- * "arrive": the choice card (portrait, name, style tag, "1 OF 8 TODAY", his line, a news strip on a follow-up, the
--   choices with their cost, WALK AWAY). A choice you can't afford is greyed "· can't afford" and re-checked whenever
--   your money changes. The card waits behind a 44 px "<NAME> IS WAITING · OPEN" chip while the beat maker is open or
--   the listen-back cutaway runs (both also hide an open card), or while a cypher round holds you (WalkInRules.CypherHolds:
--   one that listens or votes holds everyone; a lobby, the build and the reveal only that round's entrants) or a phone card
--   (OK_Phone's Open) shows (those only keep a card from opening, never hide one you're reading; a chip tap while the
--   phone card shows does nothing, so you never see two cards, and the card then opens by itself once the phone card
--   closes, deferred by the beat maker and armed like any other), and opens by itself once all of that clears; tapping
--   the chip opens it anyway over the beat maker or a cypher. Every flip of the deferral tells the server
--   (WalkIn_Deferred(token, deferred)), so his bubble can say he is waiting. The chip is centred, 8 px under the lowest
--   of the HUD, the career pills, the daily / tour pill, the phone icon and the cypher bar, and narrow enough (vp.X -
--   320) to stay clear of the FIRE button's column; while a phone card shows (its column is up to 316 px wide on
--   phones, and OK_Phone draws over this gui) the chip shifts, then if it must narrows, to end 8 px left of the card.
--   Over the phone (compact) beat maker it would sit on the pads, so it hides there: the card still opens when the beat
--   maker closes.
--   A card that opens by itself focuses its header for a gamepad and ignores taps / clicks on its buttons for
--   ARM_SECONDS, so a press meant for the game (A is Jump) never picks a choice nobody read; a card opened from the
--   chip selects Choice 1 at once.
-- * "result": a result card at the bottom centre (headline, text, the applied amounts as chips, note, OK); it hides
--   after 8 s. The same result also comes back from WalkIn_Choose: shown once per token. "leave": the visit is over;
--   a follow-up's news (applied on arrival) whose card never showed is shown then on a result card instead, and a
--   visitor who gave up (the payload's note: he waited the whole limit) leaves a note card through the same frame
--   ("<NAME> LEFT", how long he waited, his parting line; neutral tone, token "note:<token>"). Both queue until
--   nothing defers them and no other result card shows, so a stat change never goes unexplained.
-- A choice sends only WalkIn_Choose(token, index) (0 = walk away); the server rolls and applies everything.
-- Explainers (Wave 3 design 4.5): a card or result whose payload carries hint = { term, text } shows it as its last
-- footer line, Card.Hint / Result.Hint (a Mark "i" and the muted Label), full width under WALK AWAY's row (the Aura
-- line beside it) or under OK; a line added between the Aura line and the hint goes above it. On a card whose body
-- would no longer fit above it, the hint moves into the scroll instead (Card.Scroll.Hint), after the last choice, so a
-- hint never pushes a choice under the fold (fix round 1). Without a hint the line is hidden at zero size: the card
-- and the result card are exactly as before.
-- Your beat (Wave 3 design 4.1): a card whose payload carries `beat` (a choice on it goes by your best beat) shows
-- CardFeel.BeatLine as its second footer line, Card.BeatLine: full width under WALK AWAY's row (the Aura line beside it),
-- above the hint. It is a fixed row, so the body's room leaves space for it first: on a short screen his line drops and
-- then the body scrolls exactly as before, and the hint's footer-or-scroll rule sees the row. No `beat`, no row: it is
-- hidden at zero size. A "beat" message (fix round 1: your best beat changed while the card waits or shows) replaces the
-- open visit's beat, his line and the choice texts in place and lays the card out again; no riser (attribute
-- BeatUpdates counts them).
-- Feel (CardFeel, shared with PhoneUI): the footer reads your Aura band and follows an Aura change unless a refusal
-- note shows; the riser when a card first shows (not when the beat maker hides and re-shows it); a result's sounds and
-- your avatar's reaction from showResult, and for a follow-up's news when its card first shows. CardFeel gets dawUp:
-- the beat maker or the cutaway is up, or went down within the last second (restore() may just have stood you up).
-- Layout: every element sits by offset inside Root, a top-left box the size of the gui, or of the gui's ForceViewport
-- attribute (a Vector2) when a test sets one, so phone sizes can be checked inside (0, 0)-vp on any screen.
-- Attributes on the gui (tests): Open (card shown), Deferred, Token, Card (card id), Choices (count), ResultKey,
-- ResultTone, LastChoose ("ok" or the refusal); Command = "choose:<n>" | "walkaway" | "open" | "ok".
local Players, RS, RunService = game:GetService("Players"), game:GetService("ReplicatedStorage"), game:GetService("RunService")
local TextService, GuiService, UIS = game:GetService("TextService"), game:GetService("GuiService"), game:GetService("UserInputService")
local Format = require(RS.OK.Modules.Format)
local CardFeel = require(RS.OK.Modules.CardFeel)
local Rules = require(RS.OK.Modules.WalkInRules)
local M = {}
local MIN = 44                 -- touch target
local PAD = 14                 -- card side padding; top padding and gaps tighten on short screens (layout)
local PORTRAIT = 44
-- vertical spacing: top / bottom padding, row gap, gap between choices, the card's margin to the screen edge, the header
-- row (portrait, name, tag) and where name and tag sit in it, and the news strip's padding and inner gap. Phones in
-- landscape (under 420 px tall) get TIGHT: with it a follow-up's news strip and three choices fit the safe area of a
-- 667x375 phone under a 58 px top bar (667x317) without scrolling once his line (also in his overhead bubble) is
-- dropped, which happens only when the card doesn't fit; only what still doesn't fit scrolls (t47b checks this at
-- 844x390 and 667x375 less the real insets).
local ROOMY = { top = 12, gap = 8, cgap = 6, margin = 8, head = PORTRAIT, nameY = 2, tagY = 26, newsPad = 8, newsGap = 4 }
local TIGHT = { top = 6, gap = 6, cgap = 4, margin = 4, head = 36, nameY = 0, tagY = 22, newsPad = 6, newsGap = 2 }
local ARM_SECONDS = 0.6        -- a card that opened by itself ignores button presses this long
local COST_W = 104             -- the cost column of a paid choice ("$400" / "· can't afford")
local WALK_W = 124
local RESULT_W, RESULT_H, RESULT_SECONDS = 340, 180, 8
local HINT_ICON, HINT_GAP = 14, 4 -- the hint line's "i" (a 14 px dot) and its gap under the row above it
local SKIN = Color3.fromRGB(150, 110, 85)
local CHOICE_BG = Color3.fromRGB(26, 26, 34)
local REASONS = { afford = "Not enough money for that one yet", invalid = "That choice isn't on the card",
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
	local gui = Instance.new("ScreenGui")
	gui.Name = "OK_WalkIn"; gui.ResetOnSpawn = false; gui.DisplayOrder = 8
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	for k, v in pairs({ Open = false, Deferred = false, Token = "", Card = "", Choices = 0, ResultKey = "", ResultTone = "",
		LastChoose = "", Command = "" }) do gui:SetAttribute(k, v) end
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
	local LEFT, RIGHT = Enum.TextXAlignment.Left, Enum.TextXAlignment.Right
	-- the hint line: a row with a small "i" (Mark: never "Icon", which OK_Phone's recursive lookups mean) and the muted
	-- text, hidden until a hint is placed in it
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
	-- the row in `parent` at (x, y), `width` wide and h tall; h = 0 hides it at zero size (it takes no space)
	local function placeHint(hr, text, parent, x, y, width, h)
		if hr.row.Parent ~= parent then hr.row.Parent = parent end
		hr.row.Visible = h > 0
		hr.label.Text = h > 0 and text or ""
		hr.row.Position = UDim2.fromOffset(x, y); hr.row.Size = UDim2.fromOffset(h > 0 and width or 0, h)
		hr.label.Size = UDim2.fromOffset(h > 0 and math.max(40, width - HINT_ICON - 6) or 0, h)
	end
	-- the height the beat line takes at `width` (0 for none)
	local function beatHeight(text, width)
		if not text then return 0 end
		return math.ceil(measure(text, 11, Theme.font, width).Y) + 2
	end

	local root = new("Frame", { Name = "Root", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 0) }, gui)

	-- the choice card ---------------------------------------------------------------------------------------------------
	local card = new("Frame", { Name = "Card", BackgroundColor3 = Theme.panel, BorderSizePixel = 0, Visible = false, Active = true }, root)
	corner(card, 14)
	local cardStroke = new("UIStroke", { Color = Theme.line, Thickness = 1.5 }, card)
	local portrait = new("Frame", { Name = "Portrait", Size = UDim2.fromOffset(PORTRAIT, PORTRAIT),
		BackgroundColor3 = Theme.bg, BorderSizePixel = 0, ClipsDescendants = true }, card)
	corner(portrait, 8)
	local portraitScale = new("UIScale", { Scale = 1 }, portrait) -- shrinks the portrait with the header row on short screens
	new("Frame", { Name = "Face", Position = UDim2.fromOffset(11, 8), Size = UDim2.fromOffset(22, 22), BackgroundColor3 = SKIN, BorderSizePixel = 0 }, portrait)
	local shirt = new("Frame", { Name = "Shirt", Position = UDim2.fromOffset(5, 31), Size = UDim2.fromOffset(34, 16), BackgroundColor3 = Theme.accent2, BorderSizePixel = 0 }, portrait)
	local nameL = new("TextLabel", { Name = "Name", BackgroundTransparency = 1, Font = Theme.fontBlack, TextSize = 17, TextColor3 = Theme.accent,
		TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Text = "" }, card)
	local tagL = new("TextLabel", { Name = "Tag", BackgroundTransparency = 1, Font = Theme.font, TextSize = 10, TextColor3 = Theme.muted,
		TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Text = "" }, card)
	-- selectable so a gamepad can rest on it (it commits nothing) when the card opens by itself
	local header = new("TextLabel", { Name = "Header", BackgroundColor3 = Theme.bg, BorderSizePixel = 0, Font = Theme.fontBlack, TextSize = 10,
		TextColor3 = Theme.muted, Text = "", Selectable = true }, card)
	corner(header, 11)
	-- the middle scrolls only when a phone can't fit his line, the news and the choices
	local scroll = new("ScrollingFrame", { Name = "Scroll", BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.muted, ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.new() }, card)
	local lineL = new("TextLabel", { Name = "Line", BackgroundTransparency = 1, Font = Theme.font, TextSize = 14, TextColor3 = Theme.text,
		TextWrapped = true, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, Text = "" }, scroll)
	local news = new("Frame", { Name = "News", BackgroundColor3 = Theme.bg, BorderSizePixel = 0, Visible = false }, scroll)
	corner(news, 9)
	local newsHead = new("TextLabel", { Name = "Headline", BackgroundTransparency = 1, Font = Theme.fontBlack, TextSize = 18,
		TextColor3 = Theme.gold, TextXAlignment = LEFT, Text = "" }, news)
	local newsChips = new("Frame", { Name = "Chips", BackgroundTransparency = 1 }, news)
	local newsText = new("TextLabel", { Name = "Text", BackgroundTransparency = 1, Font = Theme.font, TextSize = 12, TextColor3 = Theme.muted,
		TextWrapped = true, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, Text = "" }, news)
	-- a card that opened by itself takes no button press before this os.clock(): the press was meant for the game.
	-- Only the buttons check it; the Command attribute (what they send, and the tests' seam) acts at once.
	local armedUntil = 0
	local function armed() return os.clock() >= armedUntil end
	local parts = {}
	for i = 1, 4 do
		local b = new("TextButton", { Name = "Choice" .. i, BackgroundColor3 = CHOICE_BG, BorderSizePixel = 0, AutoButtonColor = true, Text = "",
			Visible = false, Selectable = true }, scroll)
		corner(b, 9)
		new("UIStroke", { Color = Theme.line, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
		local label = new("TextLabel", { Name = "Label", BackgroundTransparency = 1, Font = Theme.font, TextSize = 13, TextColor3 = Theme.text,
			TextWrapped = true, TextXAlignment = LEFT, Text = "" }, b)
		local cost = new("TextLabel", { Name = "Cost", BackgroundTransparency = 1, Font = Theme.fontBlack, TextSize = 12, TextColor3 = Theme.ledOn,
			TextWrapped = true, TextXAlignment = RIGHT, Text = "" }, b)
		b.MouseButton1Click:Connect(function() if armed() then gui:SetAttribute("Command", "choose:" .. i) end end)
		parts[i] = { btn = b, label = label, cost = cost }
	end
	local footer = new("TextLabel", { Name = "Footer", BackgroundTransparency = 1, Font = Theme.font, TextSize = 11, TextColor3 = Theme.muted,
		TextWrapped = true, TextXAlignment = LEFT, Text = CardFeel.Footer() }, card)
	local walkAway = new("TextButton", { Name = "WalkAway", BackgroundColor3 = Theme.line, BorderSizePixel = 0, Font = Theme.fontBlack, TextSize = 13,
		TextColor3 = Theme.text, Text = "WALK AWAY", AutoButtonColor = true, Selectable = true }, card)
	corner(walkAway, 9)
	-- your beat's line: the second footer line, under WALK AWAY's row (layout() places it; hidden at zero size without one)
	local beatL = new("TextLabel", { Name = "BeatLine", BackgroundTransparency = 1, Font = Theme.font, TextSize = 11, TextColor3 = Theme.muted,
		TextWrapped = true, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, Text = "", Visible = false }, card)
	local cardHint = hintRow(card) -- the card's last footer line, or the scroll's last item (layout() moves it)

	-- the result card ---------------------------------------------------------------------------------------------------
	local result = new("Frame", { Name = "Result", AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(RESULT_W, RESULT_H),
		BackgroundColor3 = Theme.panel, BorderSizePixel = 0, Visible = false, Active = true }, root)
	corner(result, 14)
	local resultStroke = new("UIStroke", { Color = Theme.gold, Thickness = 1.5 }, result)
	local resHead = new("TextLabel", { Name = "Headline", Position = UDim2.fromOffset(14, 10), BackgroundTransparency = 1, Font = Theme.fontBlack,
		TextSize = 22, TextColor3 = Theme.gold, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Text = "" }, result)
	local resText = new("TextLabel", { Name = "Text", Position = UDim2.fromOffset(14, 38), BackgroundTransparency = 1, Font = Theme.font,
		TextSize = 12, TextColor3 = Theme.text, TextWrapped = true, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, Text = "" }, result)
	local resChips = new("Frame", { Name = "Chips", Position = UDim2.fromOffset(14, 72), BackgroundTransparency = 1, ClipsDescendants = true }, result)
	local resNote = new("TextLabel", { Name = "Note", Position = UDim2.fromOffset(14, 126), BackgroundTransparency = 1, Font = Theme.font,
		TextSize = 10, TextColor3 = Theme.muted, TextWrapped = true, TextXAlignment = LEFT, Text = "" }, result)
	local okBtn = new("TextButton", { Name = "Ok", Size = UDim2.fromOffset(72, MIN), BackgroundColor3 = Theme.line, BorderSizePixel = 0,
		Font = Theme.fontBlack, TextSize = 13, TextColor3 = Theme.text, Text = "OK", AutoButtonColor = true, Selectable = true }, result)
	corner(okBtn, 9)
	local resultHint = hintRow(result) -- under OK, only when the result carries one (the card grows up: it is anchored at its bottom)

	-- the Waiting chip ---------------------------------------------------------------------------------------------------
	local chip = new("TextButton", { Name = "Waiting", BackgroundColor3 = Theme.accent, BorderSizePixel = 0, Font = Theme.fontBlack, TextSize = 13,
		TextColor3 = Theme.bg, Text = "", Visible = false, AutoButtonColor = true, Selectable = true, TextScaled = true }, root)
	corner(chip, MIN // 2)
	new("UITextSizeConstraint", { MaxTextSize = 13, MinTextSize = 9 }, chip)
	new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, chip)

	-- helpers -----------------------------------------------------------------------------------------------------------
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
	local function cred() return tonumber(player:GetAttribute("Cred")) or 0 end
	local function costOf(c) return math.max(0, math.floor(tonumber(c.cost) or 0)) end

	local cur = nil        -- the visit on screen: { token, card, today, max, seen = the card has been open }
	local forced = false   -- the chip was tapped: show the card even while deferred
	local busy = false     -- a WalkIn_Choose call is out
	local shown = {}       -- the open / deferred / chip state last applied
	local queued = {}      -- result payloads waiting for the result card: a follow-up's news whose card never showed, a note
	local lastResult, lastResultToken, resultSerial, noteUntil, chipW = nil, nil, 0, 0, 160
	local resHint = nil    -- the hint text of the result on the result card (hintOf), or nil
	local function choices() return (cur and type(cur.card.choices) == "table") and cur.card.choices or {} end

	-- costs and the "can't afford" grey; runs again whenever the Cred attribute (your money) changes
	local function paintChoices()
		local list = choices()
		for i, part in ipairs(parts) do
			local c = list[i]
			part.btn.Visible = type(c) == "table"
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
		walkAway.Text = #list == 0 and "OK" or "WALK AWAY" -- a news-only follow-up has nothing to choose
	end

	-- positions everything from the viewport (real, or ForceViewport). layoutBody lays out the scrolling middle (his line
	-- when withLine, the news strip, the choices) at `width` with spacing m and returns its height
	local function layoutBody(width, m, withLine)
		local gap, cgap = m.gap, m.cgap
		local y = 0
		local lineH = (withLine and lineL.Text ~= "") and (math.ceil(measure(lineL.Text, 14, Theme.font, width).Y) + 4) or 0
		lineL.Visible = lineH > 0
		lineL.Position = UDim2.fromOffset(0, 0); lineL.Size = UDim2.fromOffset(width, lineH)
		if lineH > 0 then y = lineH + gap end
		local nw = cur and type(cur.card.news) == "table" and cur.card.news or nil
		news.Visible = nw ~= nil
		if nw then
			local np, ng = m.newsPad, m.newsGap
			local headW = math.ceil(measure(newsHead.Text, 18, Theme.fontBlack, 1000).X)
			newsHead.Position = UDim2.fromOffset(10, np); newsHead.Size = UDim2.fromOffset(headW, 22)
			local chipsX = 10 + headW + (headW > 0 and 10 or 0)
			local chipsW = math.max(60, width - 10 - chipsX)
			local chipsH = flow(newsChips, nw.chips, chipsW, 22, 11, Theme.panel)
			newsChips.Position = UDim2.fromOffset(chipsX, np); newsChips.Size = UDim2.fromOffset(chipsW, math.max(22, chipsH))
			local ty = np + math.max(22, chipsH) + ng
			local th = newsText.Text ~= "" and (math.ceil(measure(newsText.Text, 12, Theme.font, width - 20).Y) + 2) or 0
			newsText.Visible = th > 0
			newsText.Position = UDim2.fromOffset(10, ty); newsText.Size = UDim2.fromOffset(width - 20, th)
			local nh = (th > 0 and ty + th or ty - ng) + np
			news.Position = UDim2.fromOffset(0, y); news.Size = UDim2.fromOffset(width, nh)
			y += nh + gap
		end
		local list, n = choices(), 0
		for i, part in ipairs(parts) do
			local b = part.btn
			b.Position = UDim2.fromOffset(0, y + (i - 1) * (MIN + cgap)); b.Size = UDim2.fromOffset(width, MIN)
			local costW = (list[i] and costOf(list[i]) > 0) and COST_W or 0
			local lw = width - 24 - (costW > 0 and costW + 8 or 0)
			part.label.Position = UDim2.fromOffset(12, 0); part.label.Size = UDim2.fromOffset(lw, MIN)
			-- two lines of 13 px fit 44 px; a longer text drops to 11 px (texts run to ~51 characters)
			part.label.TextSize = measure(part.label.Text, 13, Theme.font, lw).Y <= MIN - 8 and 13 or 11
			part.cost.Visible = costW > 0
			part.cost.Position = UDim2.fromOffset(width - 12 - costW, 0); part.cost.Size = UDim2.fromOffset(costW, MIN)
			if b.Visible then n += 1 end
		end
		if n > 0 then return y + n * MIN + (n - 1) * cgap end
		return math.max(0, y - gap)
	end
	local function layout()
		local vp = viewport()
		root.Size = UDim2.fromOffset(vp.X, vp.Y)
		-- card: header row, the scrolling middle, then the footer row with WALK AWAY (spacing: ROOMY / TIGHT above)
		local tight = vp.Y < 420
		local m = tight and TIGHT or ROOMY
		local top, gap, head = m.top, m.gap, m.head
		local W = math.max(220, math.min(500, vp.X - 32))
		local inner = W - 2 * PAD
		portrait.Position = UDim2.fromOffset(PAD, top); portraitScale.Scale = head / PORTRAIT
		local headerW = math.ceil(measure(header.Text, 10, Theme.fontBlack, 1000).X) + 20
		header.Position = UDim2.fromOffset(W - PAD - headerW, top + math.floor((head - 22) / 2)); header.Size = UDim2.fromOffset(headerW, 22)
		local textX = PAD + head + 10
		local textW = math.max(40, W - PAD - headerW - 8 - textX)
		nameL.Position = UDim2.fromOffset(textX, top + m.nameY); nameL.Size = UDim2.fromOffset(textW, 22)
		tagL.Position = UDim2.fromOffset(textX, top + m.tagY); tagL.Size = UDim2.fromOffset(textW, 14)
		local fixed = top + head + gap + gap + MIN + top
		-- your beat's line: a fixed row under WALK AWAY's, taken out of the body's room first (none: 0)
		local beatText = cur and cur.beatText or nil
		local beatH = beatHeight(beatText, inner)
		local beatBelow = beatH > 0 and (HINT_GAP + beatH) or 0
		local room = math.max(MIN, (vp.Y - 2 * m.margin) - fixed - beatBelow)
		local withLine = true
		local contentH = layoutBody(inner, m, withLine)
		if contentH > room and tight then withLine = false; contentH = layoutBody(inner, m, withLine) end -- his bubble says it too
		local width = inner
		if contentH > room then width = inner - 8; contentH = layoutBody(width, m, withLine) end -- the scroll bar gets its own lane
		-- the hint, laid out after the body (which is exactly as with no hint): the card's last footer line, under WALK
		-- AWAY's row, while the whole body still fits above it; else the last item in the scroll, after the last choice,
		-- so a hint never pushes a choice under the fold (it may scroll out of view itself). Scrolling only for the hint,
		-- the bar gets its lane when narrowing moves nothing, else it draws over the edge
		local cardHintText = cur and hintOf(cur.card) or nil
		local footH = hintHeight(cardHintText, inner)
		local inFooter = footH > 0 and contentH + HINT_GAP + footH <= room
		local below = inFooter and (HINT_GAP + footH) or 0
		local bodyH = contentH
		local scrollHintH = (footH > 0 and not inFooter) and hintHeight(cardHintText, width) or 0
		if scrollHintH > 0 then
			contentH = bodyH + gap + scrollHintH
			if contentH > room and width == inner then
				if layoutBody(inner - 8, m, withLine) == bodyH then
					width = inner - 8
					scrollHintH = hintHeight(cardHintText, width)
					contentH = bodyH + gap + scrollHintH
				else
					layoutBody(inner, m, withLine)
				end
			end
		end
		local scrollH = math.min(contentH, room - below)
		scroll.Position = UDim2.fromOffset(PAD, top + head + gap); scroll.Size = UDim2.fromOffset(inner, math.max(1, scrollH))
		scroll.CanvasSize = UDim2.fromOffset(0, contentH)
		local fy = top + head + gap + scrollH + gap
		walkAway.Position = UDim2.fromOffset(W - PAD - WALK_W, fy); walkAway.Size = UDim2.fromOffset(WALK_W, MIN)
		footer.Position = UDim2.fromOffset(PAD, fy); footer.Size = UDim2.fromOffset(math.max(40, inner - WALK_W - 10), MIN)
		beatL.Visible = beatH > 0
		beatL.Text = beatH > 0 and beatText or ""
		beatL.TextColor3 = (cur and cur.beatGood) and Theme.gold or Theme.muted
		beatL.Position = UDim2.fromOffset(PAD, fy + MIN + HINT_GAP); beatL.Size = UDim2.fromOffset(beatH > 0 and inner or 0, beatH)
		if inFooter then placeHint(cardHint, cardHintText, card, PAD, fy + MIN + beatBelow + HINT_GAP, inner, footH)
		else placeHint(cardHint, cardHintText, scroll, 0, bodyH + gap, width, scrollHintH) end
		local H = fy + MIN + beatBelow + below + top
		card.Size = UDim2.fromOffset(W, H)
		card.Position = UDim2.fromOffset(math.floor((vp.X - W) / 2), math.max(m.margin, math.floor((vp.Y - H) / 2)))
		-- result: bottom centre, 14 px up; RESULT_H tall, plus its hint line under OK when it has one
		local rw = math.min(RESULT_W, vp.X - 32)
		local rh = hintHeight(resHint, rw - 28)
		result.Size = UDim2.fromOffset(rw, RESULT_H + (rh > 0 and rh + HINT_GAP or 0))
		result.Position = UDim2.fromOffset(math.floor(vp.X / 2), vp.Y - 14)
		resHead.Size = UDim2.fromOffset(rw - 28, 26)
		resText.Size = UDim2.fromOffset(rw - 28, 30)
		resChips.Size = UDim2.fromOffset(rw - 28, 50)
		resNote.Size = UDim2.fromOffset(rw - 28 - 72 - 8, MIN)
		okBtn.Position = UDim2.fromOffset(rw - 14 - 72, RESULT_H - 10 - MIN)
		placeHint(resultHint, resHint, result, 14, RESULT_H - 10 + HINT_GAP, rw - 28, rh)
		if result.Visible and lastResult then flow(resChips, lastResult.chips, rw - 28, 22, 11, Theme.bg) end
	end

	-- the chip: centred, 8 px under the lowest visible HUD piece / career pills / daily or tour pill / cypher bar / phone
	-- icon, and clear of a phone card on screen: shifted left, then narrowed only if it must, to end 8 px left of the
	-- card (both guis use CoreUISafeInsets; the card's rect is read in this gui's space)
	local function placeChip()
		local vp = viewport()
		local base, lowest = gui.AbsolutePosition.Y, 0
		local function take(g)
			if g and g:IsA("GuiObject") and g.Visible then lowest = math.max(lowest, g.AbsolutePosition.Y + g.AbsoluteSize.Y - base) end
		end
		local ui = pg:FindFirstChild("OK_UI")
		if ui then for _, n in ipairs({ "HUD", "Career", "Daily", "Tour" }) do take(ui:FindFirstChild(n)) end end
		local cy = pg:FindFirstChild("OK_Cypher")
		take(cy and cy:FindFirstChild("Bar"))
		local ph = pg:FindFirstChild("OK_Phone")
		take(ph and ph:FindFirstChild("Icon", true))
		local w = math.max(MIN, math.min(chipW, math.max(160, vp.X - 320))) -- a centred chip this narrow clears FIRE (vp.X - 152)
		local x = math.floor((vp.X - w) / 2)
		local pc = ph and ph:GetAttribute("Open") == true and ph:FindFirstChild("Card", true) or nil
		if pc and pc:IsA("GuiObject") and pc.Visible and pc.AbsoluteSize.X > 0 then
			local left = pc.AbsolutePosition.X - gui.AbsolutePosition.X - 8 -- where the chip must end: 8 px left of the card
			w = math.max(MIN, math.min(w, left - 8))
			x = math.max(8, math.min(x, left - w))
		end
		chip.Size = UDim2.fromOffset(w, MIN)
		chip.Position = UDim2.fromOffset(x, math.floor(lowest + 8))
	end

	-- deferral, each looked up afresh. dawOrCutaway: the beat maker is open or the listen-back cutaway runs (these hide
	-- even an open card); its second value says the beat maker is the phone (compact) one that fills the screen, the
	-- same test as FireButton's dawCoversScreen; each check also records when it last went from true to false (dawUp).
	-- cypherBusy: a cypher round holds you (WalkInRules.CypherHolds on its Phase and Round and your CypherIn, the server's
	-- rule; this only keeps a card from opening)
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
		return Rules.CypherHolds(cy and cy:GetAttribute("Phase"), player:GetAttribute("CypherIn"), cy and cy:GetAttribute("Round"))
	end
	local function phoneOpen() -- a phone card (PhoneUI) is on screen: one card at a time
		local ph = pg:FindFirstChild("OK_Phone")
		return ph ~= nil and ph:GetAttribute("Open") == true
	end
	local function releaseSelection()
		local s = GuiService.SelectedObject
		if s and s:IsDescendantOf(card) then GuiService.SelectedObject = nil end
	end
	-- the server learns of every flip of the arrived card's deferral (his bubble says he is waiting meanwhile)
	local function tellDeferred(token, deferred)
		local ok, err = pcall(function() RS.OK.Remotes.WalkIn_Deferred:FireServer(token, deferred) end)
		if not ok then warn("[OK][ERR] WalkInUI: WalkIn_Deferred: " .. tostring(err)) end
	end
	-- applies open / deferred / the chip; only touches visibility when that state changes. The beat maker and the cutaway
	-- defer unless the chip was tapped; a cypher and a phone card only keep a card from opening (a chip tap while the
	-- phone card shows is not taken: the card opens by itself once the phone card closes, deferred and armed as usual)
	local function refresh(force)
		local daw, compactDaw = dawOrCutaway()
		local deferred = cur ~= nil and ((not forced and (daw or (cypherBusy() and not shown.open))) or (phoneOpen() and not shown.open))
		local open = cur ~= nil and not deferred
		local chipOn = deferred and not compactDaw -- over the phone beat maker the chip would sit on its pads
		if not force and open == shown.open and deferred == shown.deferred and chipOn == shown.chip then return end
		if cur and deferred ~= shown.deferred then tellDeferred(cur.token, deferred) end
		local wasOpen = shown.open
		shown.open, shown.deferred, shown.chip = open, deferred, chipOn
		card.Visible = open; chip.Visible = chipOn
		gui:SetAttribute("Open", open); gui:SetAttribute("Deferred", deferred)
		local first = open and cur ~= nil and not cur.seen -- the card shows for the first time
		if open and cur then cur.seen = true end
		if open and not wasOpen then
			-- opened by itself: rest a gamepad on the header (it commits nothing) and ignore presses for a moment; opened
			-- from the chip: the player asked, so Choice 1 is ready
			if not forced then armedUntil = os.clock() + ARM_SECONDS end
			if UIS:GetLastInputType().Name:find("Gamepad") then
				GuiService.SelectedObject = not forced and header or (parts[1].btn.Visible and parts[1].btn or walkAway)
			end
		elseif wasOpen and not open then
			releaseSelection()
		end
		if first then -- the riser, then a follow-up's news (applied on arrival) counts as a result
			CardFeel.Opened(cur.token)
			local nw = cur.card.news
			if type(nw) == "table" and tostring(nw.headline or "") ~= "" then CardFeel.Result(nw, dawUp()) end
		end
	end
	local function resetFooter() noteUntil = 0; footer.Text = CardFeel.Footer(); footer.TextColor3 = Theme.muted end
	local function note(text) footer.Text = text; footer.TextColor3 = Theme.accent; noteUntil = os.clock() + 4 end

	local function endVisit(token)
		if not cur or (token ~= nil and cur.token ~= token) then return end
		cur, forced = nil, false
		gui:SetAttribute("Token", ""); gui:SetAttribute("Card", ""); gui:SetAttribute("Choices", 0)
		resetFooter()
		refresh(true)
	end
	local function hideResult()
		resultSerial += 1
		result.Visible = false
		if GuiService.SelectedObject == okBtn then GuiService.SelectedObject = nil end
	end
	local function showResult(r)
		if type(r) ~= "table" then return end
		if r.token ~= nil and r.token == lastResultToken then return end -- the Choose reply and the "result" message carry the same one
		lastResult, lastResultToken = r, r.token
		local tone = r.tone
		resHead.Text = tostring(r.headline or ""); resHead.TextColor3 = toneColor(tone)
		resultStroke.Color = toneColor(tone)
		resText.Text = tostring(r.text or "")
		resNote.Text = tostring(r.note or "")
		okBtn.Text = tone == "win" and "NICE" or "OK"
		okBtn.BackgroundColor3 = tone == "win" and Theme.gold or Theme.line
		okBtn.TextColor3 = tone == "win" and Theme.bg or Theme.text
		resHint = hintOf(r)
		layout() -- the result card's height and its hint line (the choice card is laid out too: unchanged while hidden)
		flow(resChips, r.chips, resChips.Size.X.Offset, 22, 11, Theme.bg)
		gui:SetAttribute("ResultKey", tostring(r.key or "")); gui:SetAttribute("ResultTone", tostring(tone or ""))
		result.Visible = true
		if UIS:GetLastInputType().Name:find("Gamepad") then GuiService.SelectedObject = okBtn end
		resultSerial += 1
		local my = resultSerial
		task.delay(RESULT_SECONDS, function() if resultSerial == my then hideResult() end end)
		CardFeel.Result(r, dawUp())
	end

	local function arrive(p)
		if type(p) ~= "table" or type(p.card) ~= "table" then return end
		local c = p.card
		-- beatText: the second footer line for the payload's beat (nil: none); beatGood: a best beat to show
		cur = { token = p.token, card = c, today = p.today, max = p.max, beatText = CardFeel.BeatLine(c.beat), beatGood = type(c.beat) == "table" }
		forced = false
		local v = type(c.visitor) == "table" and c.visitor or {}
		nameL.Text = tostring(v.name or "?")
		tagL.Text = tostring(c.tag or v.style or "")
		header.Text = string.format("%d OF %d TODAY", tonumber(p.today) or 0, tonumber(p.max) or 0)
		shirt.BackgroundColor3 = colorOf(v.color, Theme.accent2)
		lineL.Text = (type(c.line) == "string" and c.line ~= "") and ("“" .. c.line .. "”") or ""
		local nw = type(c.news) == "table" and c.news or nil
		newsHead.Text = nw and tostring(nw.headline or "") or ""
		newsHead.TextColor3 = toneColor(nw and nw.tone)
		newsText.Text = nw and tostring(nw.text or "") or ""
		cardStroke.Color = nw and toneColor(nw.tone) or Theme.line
		paintChoices()
		chip.Text = string.upper(nameL.Text) .. " IS WAITING · OPEN"
		chipW = math.ceil(measure(chip.Text, 13, Theme.fontBlack, 1000).X) + 36
		gui:SetAttribute("Token", tostring(p.token or "")); gui:SetAttribute("Card", tostring(c.id or "")); gui:SetAttribute("Choices", #choices())
		resetFooter()
		scroll.CanvasPosition = Vector2.new(0, 0)
		layout(); placeChip()
		refresh(true)
	end

	-- "beat" (fix round 1): your best beat changed while his card waits or shows. The open visit's beat, line and choice
	-- texts are replaced in place and the card laid out again (same token: no riser, no re-arm, the hint stays)
	local function beatUpdate(p)
		if not cur or type(p) ~= "table" or p.token ~= cur.token then return end
		local c = cur.card
		c.beat = p.beat
		if type(p.line) == "string" then c.line = p.line end
		if type(p.choices) == "table" and type(c.choices) == "table" then
			for i, ch in ipairs(c.choices) do
				if type(ch) == "table" and type(p.choices[i]) == "string" then ch.text = p.choices[i] end
			end
		end
		cur.beatText, cur.beatGood = CardFeel.BeatLine(c.beat), type(c.beat) == "table"
		lineL.Text = (type(c.line) == "string" and c.line ~= "") and ("“" .. c.line .. "”") or ""
		paintChoices()
		gui:SetAttribute("BeatUpdates", (tonumber(gui:GetAttribute("BeatUpdates")) or 0) + 1)
		layout(); placeChip()
	end

	local function choose(index)
		if not cur or busy then return end
		if index > 0 then
			local c = choices()[index]
			if type(c) ~= "table" then gui:SetAttribute("LastChoose", "invalid"); return end
			if costOf(c) > cred() then gui:SetAttribute("LastChoose", "afford"); note(REASONS.afford); return end
		end
		local token = cur.token
		busy = true
		local ok, res = pcall(function() return RS.OK.Remotes.WalkIn_Choose:InvokeServer(token, index) end)
		busy = false
		local r = (ok and type(res) == "table") and res or { ok = false, reason = "error" }
		gui:SetAttribute("LastChoose", r.ok and "ok" or tostring(r.reason))
		if r.ok or r.reason == "stale" then -- stale: the visit is over on the server (expired, or he left)
			endVisit(token)
			if r.ok then showResult(r.result) end
		else
			note(REASONS[r.reason] or REASONS.error)
		end
	end

	-- input and test commands ----------------------------------------------------------------------------------------------
	walkAway.MouseButton1Click:Connect(function() if armed() then gui:SetAttribute("Command", "walkaway") end end)
	chip.MouseButton1Click:Connect(function() gui:SetAttribute("Command", "open") end)
	okBtn.MouseButton1Click:Connect(function() gui:SetAttribute("Command", "ok") end)
	gui:GetAttributeChangedSignal("Command"):Connect(function()
		local c = gui:GetAttribute("Command")
		if type(c) ~= "string" or c == "" then return end
		gui:SetAttribute("Command", "")
		if c == "walkaway" then choose(0)
		elseif c == "open" then -- a tap the phone card holds is not latched: it would open the card later, over the beat maker and un-armed
			if cur and not phoneOpen() then forced = true; refresh(true) end
		elseif c == "ok" then hideResult()
		else
			local n = tonumber(string.match(c, "^choose:(%d)$"))
			if n then choose(n) end
		end
	end)

	local ev = RS.OK.Remotes:FindFirstChild("WalkIn")
	if ev then
		ev.OnClientEvent:Connect(function(kind, payload)
			if kind == "arrive" then arrive(payload)
			elseif kind == "beat" then beatUpdate(payload)
			elseif kind == "result" and type(payload) == "table" then endVisit(payload.token); showResult(payload)
			elseif kind == "leave" and type(payload) == "table" then
				-- he left before his card ever showed (deferred until it expired, you left the hub or respawned): his news was
				-- applied on arrival, so it still gets told
				local nw = cur and cur.token == payload.token and not cur.seen and cur.card.news
				if type(nw) == "table" and tostring(nw.headline or "") ~= "" then table.insert(queued, nw) end
				-- he gave up waiting (the card stood for the whole limit): his note, through the result card
				local n = payload.note
				if type(n) == "table" then
					local line = tostring(n.line or "")
					table.insert(queued, { token = "note:" .. tostring(payload.token), key = "note", tone = "neutral", chips = {},
						headline = string.upper(tostring(n.name or "?")) .. " LEFT", text = "waited " .. tostring(n.waited or "a while"),
						note = line ~= "" and ("“" .. line .. "”") or "" })
				end
				endVisit(payload.token)
			end
		end)
	else
		warn("[OK][ERR] WalkInUI: ReplicatedStorage.OK.Remotes.WalkIn is missing (run build/17_career_remotes.lua)")
	end
	player:GetAttributeChangedSignal("Cred"):Connect(function() if cur then paintChoices() end end)
	-- the footer follows your Aura band, unless a refusal note shows (it comes back with the band line when it ends)
	player:GetAttributeChangedSignal("Aura"):Connect(function() if noteUntil == 0 or os.clock() > noteUntil then resetFooter() end end)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() layout(); placeChip() end)
	gui:GetAttributeChangedSignal("ForceViewport"):Connect(function() layout(); placeChip() end)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt; if acc < 0.2 then return end; acc = 0
		dawOrCutaway() -- keeps the beat maker's close time current with no card on screen (dawUp)
		placeChip()
		if cur then refresh(false) end
		-- not over a result card already showing (a newer visit's) or a phone card: his news or note waits until that hides
		if #queued > 0 and not shown.open and not result.Visible and not dawOrCutaway() and not cypherBusy() and not phoneOpen() then
			showResult(table.remove(queued, 1))
		end
		if noteUntil > 0 and os.clock() > noteUntil then resetFooter() end
	end)
	layout(); refresh(true)
	return { Gui = gui, Card = card, Result = result, Waiting = chip }
end

return M
