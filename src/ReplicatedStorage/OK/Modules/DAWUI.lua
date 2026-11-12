-- OK Beat Maker window (v3: 808 row, hat rolls, swing, 3 slots, gear locks, kits, and the KEYS view: Modules/PianoRoll).
-- State lives in attributes on the root frame so other code (and tests) can drive it:
--   Pattern (string, track-major; cell values per DAWConfig), BPM, Swing, Slot (1..Cfg.Slots), Playing, Step (0 = idle),
--   Hits, Status, LastSave, Compact (bool), Page (1|2), UndoUntil (os.clock), Seated (bool), Level (number, sets the locks),
--   View (drums|keys), Scale, NoteLen, Chord (bool), Voice, Voices (owned, csv)
--   Command (string): play | stop | clear | undo | save | close | monitors | page1 | page2 | slot:N | swing | kit | paint:t:a:b | tap:t:s
--     | keys | view:keys | view:drums | note:step:semi[:len] | unnote:step:semi | scale | len | voice | chord | stamp:step:semi | accent:step
--   Set by the client (DAWClient): Touch (bool: a touch screen, so 44 px targets in any layout: launch audit A11) and
--   TopbarFree (Rect: the Roblox top bar's free area in this gui's space; nil without a bar). Published for RequestUI
--   (phones): HeaderRight, CloseLeft (the header row's right edge, or the band's limit, closeLeft − 6, once a button is
--   dropped, so the chip stays hidden; and the close button's left edge; both in the window).
-- Layout is a pure function of the viewport (and Compact, Touch and TopbarFree). Rows come from #Cfg.Tracks.
-- Phones (Compact): the top band keeps off the bar's own buttons (Modules/DAWLayout: launch audit A1, A3): the header row
-- [1–8][9–16] · [KIT][KEYS] starts right of them (an expanded unibar drops KIT, KEYS, then the page buttons); the slots
-- are a row of the transport column, over SAVE, and CLEAR shares a row with SWING to make room; the column's six rows
-- are placed by hand (its list layout is set aside).
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Roll = require(script.Parent:WaitForChild("PianoRoll"))
local DAWLayout = require(script.Parent:WaitForChild("DAWLayout"))

local M = {}

local MIN_TOUCH = 44
local CELL_INSET = 6 -- a pad is its row's height less this (3 px above and below)
local GRID_FOOT = 4 -- between the grid's bottom and the footer

-- rollModule (optional) replaces Modules/PianoRoll: edit-mode tests pass a fresh copy past the require cache
function M.Build(gui, Theme, Cfg, rollModule)
	local function new(class, props, parent)
		local i = Instance.new(class)
		for k, v in pairs(props) do i[k] = v end
		i.Parent = parent
		return i
	end
	local function corner(p, r) new("UICorner", { CornerRadius = UDim.new(0, r or 10) }, p) end

	local nT, nS = #Cfg.Tracks, Cfg.Steps
	local C = {}
	C.OnPlayChanged = function(_) end
	C.OnSave = function() end
	C.OnAudition = function(_, _) end
	C.OnMonitors = function() end
	C.OnHide = function() end
	C.OnSlot = function(_) end
	C.OnNote = function(_, _, _) end -- (semi, len, accent) audition a keys note

	local root = new("Frame", { Name = "DAW", BackgroundColor3 = Theme.panel, BorderSizePixel = 0, Visible = false, Active = true }, gui)
	corner(root, 14)
	-- a Modal button frees the mouse from first person / shift lock whenever the window is visible
	new("TextButton", { Name = "ModalCatcher", Modal = true, BackgroundTransparency = 1, Text = "", Size = UDim2.fromOffset(0, 0), Selectable = false }, root)
	new("UIStroke", { Color = Theme.line, Thickness = 1.5 }, root)
	for k, v in pairs({ Pattern = string.rep("0", Cfg.Length or nT * nS), BPM = Cfg.BPM.Default, Swing = 0, Slot = 1, Playing = false, Step = 0,
		Hits = 0, Status = "", LastSave = "", Command = "", Compact = false, Page = 1, UndoUntil = 0, Seated = false, Level = 1, Kit = "studio", Kits = "studio",
		View = "drums", Scale = Cfg.Keys.Scales[1].id, NoteLen = 1, Chord = false, Voice = Cfg.Voices[1].id, Voices = Cfg.Voices[1].id }) do
		root:SetAttribute(k, v)
	end

	-- features come from gear the player owns (root attribute Unlocked = "Bass,Rolls,Swing"); without it, the old level rule
	local function locked(feature)
		local u = root:GetAttribute("Unlocked")
		if u == nil then return (root:GetAttribute("Level") or 1) < (Cfg.Unlocks[feature] or 1) end
		return not string.find("," .. u .. ",", "," .. feature .. ",", 1, true)
	end
	local GEAR = { Bass = "the Sub Boom 808", Rolls = "Roll FX", Swing = "the Swing Unit" }
	local function lockedText(feature) return string.format("%s: get %s at the gear rack", feature == "Bass" and "808" or feature, GEAR[feature] or "gear") end
	local function trackLocked(t) local k = Cfg.Tracks[t].Kind; return k == "bass" and locked("Bass") end

	-- header
	local title = new("TextLabel", { Name = "Title", Text = "BEAT MAKER", Font = Theme.fontBlack, TextColor3 = Theme.accent,
		TextSize = 20, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left }, root)
	local status = new("TextLabel", { Name = "StatusText", Text = "", Font = Theme.font, TextColor3 = Theme.muted, TextSize = 14,
		BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd }, root)
	local hint = new("TextLabel", { Name = "Hint", Text = "", Font = Theme.font, TextColor3 = Theme.muted, TextSize = 12,
		BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left }, root)
	local close = new("TextButton", { Name = "Close", Text = "X", BackgroundColor3 = Theme.line, TextColor3 = Theme.text,
		Font = Theme.fontBlack, TextSize = 16, AutoButtonColor = true }, root)
	corner(close, 8)

	-- transport
	local transport = new("Frame", { Name = "Transport", BackgroundTransparency = 1 }, root)
	local list = new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, transport)
	local function btn(parent, name, text, order, color, size)
		local b = new("TextButton", { Name = name, Text = text, BackgroundColor3 = color or Theme.line, TextColor3 = Theme.text,
			Font = Theme.font, TextSize = size or 15, LayoutOrder = order, AutoButtonColor = true }, parent)
		corner(b, 8)
		return b
	end
	local function row(name, order, parent)
		local r = new("Frame", { Name = name, BackgroundTransparency = 1, LayoutOrder = order }, parent or transport)
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center }, r)
		return r
	end
	local play = btn(transport, "Play", "▶ PLAY", 1, Theme.accent)
	local bpmRow = row("BpmRow", 2)
	local bpmDown = btn(bpmRow, "BpmDown", "–", 1, nil, 16)
	local bpmLabel = new("TextLabel", { Name = "BPMText", Text = "", BackgroundTransparency = 1, TextColor3 = Theme.text,
		Font = Theme.mono, TextSize = 15, LayoutOrder = 2 }, bpmRow)
	local bpmUp = btn(bpmRow, "BpmUp", "+", 3, nil, 16)
	local monitors = btn(transport, "Monitors", "📢 ON MONITORS", 3, Color3.fromRGB(60, 40, 90))
	local clear = btn(transport, "Clear", "CLEAR", 4)
	local swing = btn(transport, "SwingBtn", "SWING 0%", 5)
	local spacer = new("Frame", { Name = "Spacer", BackgroundTransparency = 1, LayoutOrder = 7 }, transport)
	local save = btn(transport, "Save", "SAVE", 9, Theme.accent2)
	-- text that scales down when the phone layout narrows its button, never past its own size
	local function fitText(b) new("UITextSizeConstraint", { MaxTextSize = b.TextSize }, b) end
	fitText(swing)

	-- header row: pager (compact) + slots (compact: moved to the transport column by layout())
	local header = row("HeaderRow", 0, root)
	local pageBtns, slotBtns = {}, {}
	for p = 1, 2 do
		local b = btn(header, "Page" .. p, p == 1 and "1–8" or "9–16", p, nil, 14)
		new("Frame", { Name = "PlayheadDot", Size = UDim2.fromOffset(6, 6), Position = UDim2.new(1, -9, 0, 3),
			BackgroundColor3 = Theme.ledOn, BorderSizePixel = 0, Visible = false }, b)
		pageBtns[p] = b
	end
	local gap = new("Frame", { Name = "Gap", BackgroundTransparency = 1, Size = UDim2.fromOffset(6, 10), LayoutOrder = 5 }, header)
	for sIdx = 1, Cfg.Slots do slotBtns[sIdx] = btn(header, "Slot" .. sIdx, tostring(sIdx), 10 + sIdx, nil, 15) end
	local gap2 = new("Frame", { Name = "Gap2", BackgroundTransparency = 1, Size = UDim2.fromOffset(6, 10), LayoutOrder = 19 }, header)
	local kitBtn = btn(header, "KitBtn", "KIT: STUDIO", 20, Color3.fromRGB(40, 50, 70), 13)
	local keysBtn = btn(header, "KeysBtn", "KEYS", 21, Color3.fromRGB(32, 64, 32), 13)
	fitText(kitBtn); fitText(keysBtn)

	-- ruler + grid
	local ruler = new("Frame", { Name = "Ruler", BackgroundTransparency = 1 }, root)
	local rulerTicks = {}
	for s = 1, nS do
		local isBeat = (s - 1) % 4 == 0
		rulerTicks[s] = new("TextLabel", { Name = "Tick" .. s, Text = isBeat and tostring(math.floor((s - 1) / 4) + 1) or "·",
			Font = Theme.font, TextSize = isBeat and 13 or 12, TextColor3 = isBeat and Theme.text or Theme.muted, BackgroundTransparency = 1 }, ruler)
	end
	local rulerDot = new("Frame", { Name = "Dot", Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.accent, BorderSizePixel = 0, Visible = false }, ruler)
	corner(rulerDot, 4)

	local grid = new("Frame", { Name = "Grid", BackgroundColor3 = Theme.bg, BorderSizePixel = 0 }, root)
	corner(grid, 10)
	local labels, cells = {}, {}
	for t = 1, nT do
		local tr = Cfg.Tracks[t]
		labels[t] = new("TextButton", { Name = "Label" .. t, Text = string.upper(tr.Name), Font = Theme.font, TextSize = 13,
			TextColor3 = tr.Color, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false,
			TextWrapped = true }, grid)
		labels[t].MouseButton1Click:Connect(function() if not trackLocked(t) then C.OnAudition(t, nil) end end)
		cells[t] = {}
		for s = 1, nS do
			local c = new("TextButton", { Name = string.format("Cell_%d_%d", t, s), Text = "", AutoButtonColor = false,
				BorderSizePixel = 0, BackgroundColor3 = Theme.line, Selectable = true, Font = Theme.fontBlack, TextSize = 13,
				TextColor3 = Theme.bg }, grid)
			corner(c, 5)
			cells[t][s] = c
		end
	end

	-- the piano roll (KEYS view) takes the grid's place when View = "keys"
	local roll = (rollModule or Roll).Build(root, Theme, Cfg, function(semi, len, accent) C.OnNote(semi, len, accent) end)

	-- helpers
	local function idx(t, s) return (t - 1) * nS + s end
	local function valueAt(p, t, s) local i = idx(t, s); return p:sub(i, i) end
	local function setValue(p, t, s, ch)
		local i = idx(t, s)
		return p:sub(1, i - 1) .. ch .. p:sub(i + 1)
	end
	local function visibleRange()
		if root:GetAttribute("Compact") then
			local pg = root:GetAttribute("Page")
			return (pg - 1) * 8 + 1, (pg - 1) * 8 + 8
		end
		return 1, nS
	end
	local function cellText(t, ch)
		local k = Cfg.Tracks[t].Kind
		if ch == "0" then return "" end
		if k == "roll" then return ch == "1" and "" or ("×" .. ch) end
		if k == "bass" then local semi = Cfg.Semitones(ch); return semi == 0 and "0" or ((semi > 0 and "+" or "−") .. math.abs(semi)) end
		return ""
	end
	-- the value a tap moves a cell to, honouring the unlocks
	local function nextValue(t, ch)
		local k = Cfg.Tracks[t].Kind
		if k == "roll" then
			if locked("Rolls") then return ch == "0" and "1" or "0" end
			local order = { ["0"] = "1", ["1"] = "2", ["2"] = "3", ["3"] = "0" }
			return order[ch] or "0"
		elseif k == "bass" then
			if locked("Bass") then return nil end
			if ch == "0" then return Cfg.NoteChar(Cfg.BassCycle[1]) end
			local semi = Cfg.Semitones(ch)
			for i, v in ipairs(Cfg.BassCycle) do
				if v == semi then return Cfg.BassCycle[i + 1] and Cfg.NoteChar(Cfg.BassCycle[i + 1]) or "0" end
			end
			return "0"
		end
		return ch == "0" and "1" or "0"
	end
	local function onValue(t) return Cfg.Tracks[t].Kind == "bass" and Cfg.NoteChar(0) or "1" end

	-- layout -----------------------------------------------------------------
	local function layout()
		local guiSize = gui.AbsoluteSize
		local vp = root:GetAttribute("ViewportOverride")
			or ((guiSize.X > 0 and guiSize.Y > 0) and guiSize)
			or (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
		local compact = root:GetAttribute("Compact")
		local touch = root:GetAttribute("Touch") == true
		local big = compact or touch -- 44 px targets: phones, and any touch screen
		local pad = compact and 10 or 14
		local headerH = big and 52 or 40
		local footerH = 20
		local th = touch and MIN_TOUCH or 32 -- desktop: the transport row's buttons
		local deskGridY = headerH + (th + 2) + 22 -- desktop: the grid's top, under the header, the transport row and the ruler
		local W, H
		if compact then
			root.AnchorPoint = Vector2.new(0, 0)
			root.Position = UDim2.fromOffset(6, 6)
			W, H = vp.X - 12, vp.Y - 12
		else
			root.AnchorPoint = Vector2.new(0.5, 1)
			root.Position = UDim2.new(0.5, 0, 1, -10)
			W, H = math.min(vp.X - 24, 980), math.clamp(math.floor(vp.Y * 0.47), 280, 400)
			-- touch: tall enough for 44 px pads: the grid's top, a 44 px pad and its inset per row, the grid's foot and footer
			if touch then H = math.max(H, math.min(deskGridY + nT * (MIN_TOUCH + CELL_INSET) + GRID_FOOT + footerH, vp.Y - 20)) end
		end
		root.Size = UDim2.fromOffset(W, H)
		-- phones: the band the Roblox top bar leaves free (TopbarFree is in this gui's space; the window sits 6 px in)
		local band, coreRight, barBottom = nil, nil, 0
		if compact then
			local free, freeRight = root:GetAttribute("TopbarFree"), nil
			if typeof(free) == "Rect" and free.Max.Y - 6 > 4 then -- the bar reaches the header row (4 px down)
				barBottom = free.Max.Y - 6
				coreRight = free.Min.X - 6
				if free.Max.X > free.Min.X then freeRight = free.Max.X - 6 end
			end
			band = DAWLayout.Band(W, pad, coreRight, freeRight)
		end
		local closeSize = big and MIN_TOUCH or 32
		close.Size = UDim2.fromOffset(closeSize, closeSize)
		close.Position = compact and UDim2.fromOffset(band.closeLeft, 4) or UDim2.new(1, -(closeSize + pad - 4), 0, big and 4 or 6)
		hint.Position = UDim2.new(0, pad, 1, -18); hint.Size = UDim2.new(1, -2 * pad, 0, 16)
		hint.Visible = not compact

		local hb = big and MIN_TOUCH or 30
		-- phones: a button the band drops (a width of 0: an expanded unibar) is hidden, and the gap goes with KIT and KEYS
		for _, b in ipairs(pageBtns) do b.Visible = compact and band.pager > 0; b.Size = UDim2.fromOffset(compact and band.pager or 0, hb) end
		gap.Visible = not compact or (band.pager > 0 and (band.kit > 0 or band.keys > 0))
		gap2.Visible = not compact -- phones: the slots are in the transport column, so one gap is enough
		local slotW = touch and MIN_TOUCH or 34
		if not compact then for _, b in ipairs(slotBtns) do b.Size = UDim2.fromOffset(slotW, hb) end end
		local kitW = compact and band.kit or 104
		kitBtn.Visible = kitW > 0; kitBtn.Size = UDim2.fromOffset(kitW, hb); kitBtn.TextScaled = compact
		local keysW = compact and band.keys or 64
		keysBtn.Visible = keysW > 0; keysBtn.Size = UDim2.fromOffset(keysW, hb); keysBtn.TextScaled = compact
		local headerW = compact and band.width or (Cfg.Slots * (slotW + 6) + 12 + kitW + 6 + keysW)
		title.Visible = not compact
		title.Position = UDim2.fromOffset(pad, 6); title.Size = UDim2.fromOffset(200, 28)
		header.Position = UDim2.fromOffset(compact and band.x or (pad + 210), big and 4 or 5)
		header.Size = UDim2.fromOffset(headerW, hb)
		if compact then root:SetAttribute("HeaderRight", band.right); root:SetAttribute("CloseLeft", band.closeLeft) end
		if compact then
			status.Position = UDim2.fromOffset(pad, H - 20); status.Size = UDim2.fromOffset(W - 2 * pad, 18)
			status.TextXAlignment = Enum.TextXAlignment.Left
		else
			local statusX = pad + 210 + headerW + 10
			status.Position = UDim2.fromOffset(statusX, 6)
			status.Size = UDim2.fromOffset(math.max(40, W - statusX - closeSize - pad - 8), 28)
			status.TextXAlignment = Enum.TextXAlignment.Right
		end

		local gridX, gridY, gridW, gridH
		if compact then
			local colW = 150
			-- under the bar's buttons when the bar is taller than the header band (the usual 58 px bar ends where it starts)
			local top = (coreRight and coreRight > pad) and math.max(headerH, barBottom) or headerH
			transport.Position = UDim2.fromOffset(pad, top)
			local avail = H - top - footerH
			transport.Size = UDim2.fromOffset(colW, avail)
			local bh = math.clamp(math.floor((avail - 4 * 6) / 6), MIN_TOUCH, 56)
			-- six rows by hand, 4 px apart: PLAY; – BPM +; MONITORS; CLEAR | SWING; the slots 1 | 2 | 3; SAVE (still
			-- two rows under CLEAR)
			list.Parent = nil
			for _, b in ipairs(slotBtns) do b.Parent = transport end
			local y = 0
			for _, r in ipairs({ { play }, { bpmRow }, { monitors }, { clear, swing }, slotBtns, { save } }) do
				local w = math.floor((colW - (#r - 1) * 6) / #r)
				for i, b in ipairs(r) do b.Position = UDim2.fromOffset((i - 1) * (w + 6), y); b.Size = UDim2.fromOffset(w, bh) end
				y += bh + 4
			end
			bpmDown.Size = UDim2.fromOffset(MIN_TOUCH, bh); bpmUp.Size = UDim2.fromOffset(MIN_TOUCH, bh)
			bpmLabel.Size = UDim2.fromOffset(colW - 2 * MIN_TOUCH - 12, bh)
			spacer.Visible = false
			swing.TextScaled = true
			gridX = pad + colW + 10; gridY = headerH + 18; gridW = W - gridX - pad; gridH = H - gridY - footerH - GRID_FOOT
		else
			for _, b in ipairs(slotBtns) do b.Parent = header end
			list.Parent = transport
			list.FillDirection = Enum.FillDirection.Horizontal
			list.HorizontalAlignment = Enum.HorizontalAlignment.Left
			list.VerticalAlignment = Enum.VerticalAlignment.Center
			list.Padding = UDim.new(0, 8)
			spacer.Visible = true
			swing.TextScaled = false
			local bw = touch and MIN_TOUCH or 34 -- BPM – and +
			transport.Position = UDim2.fromOffset(pad, headerH)
			transport.Size = UDim2.fromOffset(W - 2 * pad, th + 2)
			play.Size = UDim2.fromOffset(96, th); bpmDown.Size = UDim2.fromOffset(bw, th); bpmUp.Size = UDim2.fromOffset(bw, th)
			bpmLabel.Size = UDim2.fromOffset(84, th); bpmRow.Size = UDim2.fromOffset(bw + 84 + bw + 12, th)
			monitors.Size = UDim2.fromOffset(150, th); clear.Size = UDim2.fromOffset(76, th); swing.Size = UDim2.fromOffset(110, th)
			save.Size = UDim2.fromOffset(76, th)
			local used = 96 + (bw + 84 + bw + 12) + 150 + 76 + 110 + 76 + 8 * 6
			spacer.Size = UDim2.fromOffset(math.max(8, (W - 2 * pad) - used), th)
			gridX = pad; gridY = deskGridY; gridW = W - 2 * pad; gridH = H - gridY - footerH - GRID_FOOT
		end

		grid.Position = UDim2.fromOffset(gridX, gridY); grid.Size = UDim2.fromOffset(gridW, gridH)
		local labelW = compact and 58 or 74
		local s0, s1 = visibleRange()
		local nVis = s1 - s0 + 1
		local cellW = (gridW - labelW - 6) / nVis
		local rowH = gridH / nT
		for t = 1, nT do
			labels[t].Position = UDim2.fromOffset(8, (t - 1) * rowH); labels[t].Size = UDim2.fromOffset(labelW - 8, rowH)
			for s = 1, nS do
				local c = cells[t][s]
				if s >= s0 and s <= s1 then
					c.Visible = true
					c.Position = UDim2.fromOffset(labelW + (s - s0) * cellW + 2, (t - 1) * rowH + CELL_INSET / 2)
					c.Size = UDim2.fromOffset(cellW - 4, rowH - CELL_INSET)
				else
					c.Visible = false
				end
			end
		end
		ruler.Position = UDim2.fromOffset(gridX, gridY - 18); ruler.Size = UDim2.fromOffset(gridW, 16)
		for s = 1, nS do
			local tk = rulerTicks[s]
			if s >= s0 and s <= s1 then
				tk.Visible = true
				tk.Position = UDim2.fromOffset(labelW + (s - s0) * cellW, 0); tk.Size = UDim2.fromOffset(cellW, 16)
			else
				tk.Visible = false
			end
		end
		C._cellW, C._labelW, C._s0, C._s1 = cellW, labelW, s0, s1
		local keysView = root:GetAttribute("View") == "keys"
		grid.Visible = not keysView
		roll.Layout(gridX, gridY, gridW, gridH, compact, s0, s1, labelW, cellW, touch)
		roll.SetVisible(keysView)
	end

	-- render -----------------------------------------------------------------
	local function render()
		local p, step = root:GetAttribute("Pattern"), root:GetAttribute("Step")
		for t = 1, nT do
			local isLocked = trackLocked(t)
			local tr = Cfg.Tracks[t]
			labels[t].Text = isLocked and (string.upper(tr.Name) .. "\nGEAR") or string.upper(tr.Name)
			labels[t].TextTransparency = isLocked and 0.5 or 0
			for s = 1, nS do
				local ch = valueAt(p, t, s)
				local on = ch ~= "0"
				local c = cells[t][s]
				local beatCol = ((s - 1) % 4 == 0) and Color3.fromRGB(56, 56, 72) or Theme.line
				local off = (s == step) and Color3.fromRGB(100, 100, 124) or beatCol
				c.BackgroundColor3 = on and tr.Color or off
				c.BackgroundTransparency = isLocked and 0.6 or 0
				c.Text = cellText(t, ch)
			end
		end
		local compact = root:GetAttribute("Compact")
		bpmLabel.Text = compact and tostring(root:GetAttribute("BPM")) or string.format("%d BPM", root:GetAttribute("BPM"))
		play.Text = root:GetAttribute("Playing") and "■ STOP" or "▶ PLAY"
		status.Text = root:GetAttribute("Status")
		local undoing = os.clock() < (root:GetAttribute("UndoUntil") or 0)
		clear.Text = undoing and "UNDO" or "CLEAR"
		swing.Text = locked("Swing") and "SWING · GEAR" or ("SWING " .. root:GetAttribute("Swing") .. "%")
		swing.TextTransparency = locked("Swing") and 0.5 or 0
		local pg = root:GetAttribute("Page")
		for i, b in ipairs(pageBtns) do b.BackgroundColor3 = (i == pg) and Theme.accent or Theme.line end
		local slot = root:GetAttribute("Slot")
		for i, b in ipairs(slotBtns) do b.BackgroundColor3 = (i == slot) and Theme.accent2 or Theme.line end
		local kit = Cfg.KitById and Cfg.KitById(root:GetAttribute("Kit") or "studio")
		kitBtn.Text = "KIT: " .. (kit and kit.name or "STUDIO")
		local keysView = root:GetAttribute("View") == "keys"
		keysBtn.Text = keysView and "DRUMS" or "KEYS"
		keysBtn.BackgroundColor3 = keysView and Cfg.Keys.Color:Lerp(Theme.bg, 0.5) or Color3.fromRGB(32, 64, 32)
		local s0, s1 = visibleRange()
		if step > 0 and step >= s0 and step <= s1 and C._cellW then
			rulerDot.Visible = true
			rulerDot.Position = UDim2.fromOffset(C._labelW + (step - s0 + 0.5) * C._cellW, 8)
		else
			rulerDot.Visible = false
		end
		for i, b in ipairs(pageBtns) do
			b.PlayheadDot.Visible = step > 0 and i ~= pg and math.floor((step - 1) / 8) + 1 == i
		end
		roll.Render()
	end

	-- hit flash on each step for cells that fire
	local lastFlashStep = 0
	local function flashStep(step)
		if step == 0 or step == lastFlashStep then return end
		lastFlashStep = step
		local p = root:GetAttribute("Pattern")
		for t = 1, nT do
			if valueAt(p, t, step) ~= "0" then
				local c = cells[t][step]
				c.BackgroundColor3 = Color3.new(1, 1, 1)
				TweenService:Create(c, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ BackgroundColor3 = Cfg.Tracks[t].Color }):Play()
			end
		end
		roll.Flash(step)
	end

	-- actions ----------------------------------------------------------------
	function C.SetValue(t, s, ch)
		if trackLocked(t) then
			root:SetAttribute("Status", lockedText("Bass"))
			return
		end
		local p = root:GetAttribute("Pattern")
		if valueAt(p, t, s) == ch then return end
		root:SetAttribute("Pattern", setValue(p, t, s, ch))
		if ch ~= "0" then C.OnAudition(t, ch) end
	end
	function C.Tap(t, s)
		local nv = nextValue(t, valueAt(root:GetAttribute("Pattern"), t, s))
		if nv == nil then
			root:SetAttribute("Status", lockedText("Bass"))
			return
		end
		C.SetValue(t, s, nv)
	end
	C.Toggle = C.Tap
	function C.Paint(t, fromStep, toStep, on)
		if on == nil then on = true end
		if trackLocked(t) then return end
		local ch = on and onValue(t) or "0"
		local a, b = math.min(fromStep, toStep), math.max(fromStep, toStep)
		local p = root:GetAttribute("Pattern")
		local changed = false
		for s = a, b do
			if valueAt(p, t, s) ~= ch then p = setValue(p, t, s, ch); changed = true end
		end
		root:SetAttribute("Pattern", p)
		if changed and on then C.OnAudition(t, ch) end
	end
	function C.SetBPM(n) root:SetAttribute("BPM", math.clamp(math.floor(n + 0.5), Cfg.BPM.Min, Cfg.BPM.Max)) end
	function C.CycleSwing()
		if locked("Swing") then
			root:SetAttribute("Status", lockedText("Swing"))
			return
		end
		local opts, cur = Cfg.Swing.Options, root:GetAttribute("Swing")
		local nextV = opts[1]
		for i, v in ipairs(opts) do if v == cur then nextV = opts[i + 1] or opts[1] end end
		root:SetAttribute("Swing", nextV)
	end
	function C.Play() root:SetAttribute("Playing", true) end
	function C.Stop() root:SetAttribute("Playing", false) end
	local undoPattern = nil
	-- CLEAR empties the lane you are looking at (drums or keys); UNDO brings the whole beat back
	function C.Clear()
		local p = root:GetAttribute("Pattern")
		undoPattern = p
		if root:GetAttribute("View") == "keys" then
			root:SetAttribute("Pattern", Cfg.Drums(p) .. string.rep("0", Cfg.Length - Cfg.KeysOffset))
		else
			root:SetAttribute("Pattern", string.rep("0", Cfg.KeysOffset) .. Cfg.KeysSeg(p))
		end
		root:SetAttribute("UndoUntil", os.clock() + 4)
		task.delay(4.05, function() if root.Parent then render() end end) -- the window may be gone by then
	end
	function C.Undo()
		if undoPattern and os.clock() < (root:GetAttribute("UndoUntil") or 0) then
			root:SetAttribute("Pattern", undoPattern)
			undoPattern = nil
			root:SetAttribute("UndoUntil", 0)
			return true
		end
		return false
	end
	function C.SetPage(pg) root:SetAttribute("Page", math.clamp(pg, 1, 2)) end
	-- KIT cycles through the kits you own (root attribute Kits = "studio,tape"); the client loads the sounds
	function C.CycleKit()
		local owned = {}
		for id in string.gmatch(root:GetAttribute("Kits") or "studio", "[^,]+") do table.insert(owned, id) end
		if #owned <= 1 then root:SetAttribute("Status", "More kits at the gear rack"); return end
		local cur, nextId = root:GetAttribute("Kit") or "studio", owned[1]
		for i, id in ipairs(owned) do if id == cur then nextId = owned[i % #owned + 1] end end
		root:SetAttribute("Kit", nextId)
		local k = Cfg.KitById(nextId)
		root:SetAttribute("Status", "Kit: " .. (k and k.name or nextId))
	end
	kitBtn.MouseButton1Click:Connect(function() C.CycleKit() end)
	function C.SetSlot(n)
		n = math.clamp(n, 1, Cfg.Slots)
		if n == root:GetAttribute("Slot") then return end
		C.Stop()
		root:SetAttribute("Slot", n)
		C.OnSlot(n)
	end
	-- load a beat into the window without opening/closing it
	function C.SetView(v)
		if v ~= "keys" then v = "drums" end
		if root:GetAttribute("View") == v then return end
		root:SetAttribute("View", v)
		if v == "keys" then root:SetAttribute("Status", "Keys: tap to add a note · tap it to remove · drag along the row to stretch") end
		local sel = GuiService.SelectedObject
		if sel and sel:IsDescendantOf(root) then task.defer(function() GuiService.SelectedObject = C.FirstCell() end) end -- gamepad: land in the new view
	end
	function C.ToggleView() C.SetView(root:GetAttribute("View") == "keys" and "drums" or "keys") end
	function C.Load(pattern, bpm, swingV)
		root:SetAttribute("Pattern", Cfg.Upgrade(pattern))
		C.SetBPM(bpm)
		root:SetAttribute("Swing", swingV or 0)
	end
	function C.Show(pattern, bpm, swingV, slot)
		C.Load(pattern, bpm, swingV)
		root:SetAttribute("Slot", slot or 1)
		root:SetAttribute("Status", "")
		root:SetAttribute("LastSave", "")
		root:SetAttribute("Page", 1)
		root.Visible = true
		layout()
		render()
	end
	function C.Hide()
		local wasOpen = root.Visible
		C.Stop()
		root.Visible = false
		if wasOpen then C.OnHide() end
	end
	function C.IsOpen() return root.Visible end
	function C.SetHint(text) hint.Text = text end
	function C.FirstCell() if root:GetAttribute("View") == "keys" then return roll.FirstCell() end; return cells[1][1] end
	function C.Layout() layout(); render() end
	C.Root = root
	C.Cells = cells
	C.Roll = roll

	-- drag-paint: press on a cell, slide along the row ------------------------
	local painting = nil -- {t = track, on = bool, last = step}
	local function stepAtX(x)
		if not C._cellW then return nil end
		local rel = x - grid.AbsolutePosition.X - C._labelW
		local s = C._s0 + math.floor(rel / C._cellW)
		if s < C._s0 or s > C._s1 then return nil end
		return s
	end
	for t = 1, nT do
		for s = 1, nS do
			local c = cells[t][s]
			c.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					local before = valueAt(root:GetAttribute("Pattern"), t, s)
					C.Tap(t, s)
					local after = valueAt(root:GetAttribute("Pattern"), t, s)
					-- dragging paints plain hits (or the root note) when the first tap turned the cell on
					painting = (before == "0" and after ~= "0") and { t = t, on = true, last = s } or
						((before ~= "0" and after == "0") and { t = t, on = false, last = s } or nil)
				end
			end)
			c.Activated:Connect(function(input)
				if input and (input.UserInputType == Enum.UserInputType.Gamepad1 or input.KeyCode == Enum.KeyCode.ButtonA
					or input.KeyCode == Enum.KeyCode.Return) then
					C.Tap(t, s)
				end
			end)
		end
	end
	UserInputService.InputChanged:Connect(function(input)
		if not painting then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local s = stepAtX(input.Position.X)
		if s and s ~= painting.last then
			C.Paint(painting.t, painting.last, s, painting.on)
			painting.last = s
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			painting = nil
		end
	end)

	-- buttons ------------------------------------------------------------------
	play.MouseButton1Click:Connect(function() if root:GetAttribute("Playing") then C.Stop() else C.Play() end end)
	bpmDown.MouseButton1Click:Connect(function() C.SetBPM(root:GetAttribute("BPM") - Cfg.BPM.Step) end)
	bpmUp.MouseButton1Click:Connect(function() C.SetBPM(root:GetAttribute("BPM") + Cfg.BPM.Step) end)
	clear.MouseButton1Click:Connect(function() if not C.Undo() then C.Clear() end end)
	swing.MouseButton1Click:Connect(C.CycleSwing)
	save.MouseButton1Click:Connect(function() C.OnSave() end)
	monitors.MouseButton1Click:Connect(function() C.OnMonitors() end)
	close.MouseButton1Click:Connect(C.Hide)
	keysBtn.MouseButton1Click:Connect(C.ToggleView)
	for p = 1, 2 do pageBtns[p].MouseButton1Click:Connect(function() C.SetPage(p) end) end
	for sIdx = 1, Cfg.Slots do slotBtns[sIdx].MouseButton1Click:Connect(function() C.SetSlot(sIdx) end) end

	root:GetAttributeChangedSignal("Playing"):Connect(function() C.OnPlayChanged(root:GetAttribute("Playing") == true) end)
	root:GetAttributeChangedSignal("Step"):Connect(function() flashStep(root:GetAttribute("Step")) end)
	root:GetAttributeChangedSignal("Command"):Connect(function()
		local cmd = root:GetAttribute("Command")
		if cmd == "" then return end
		root:SetAttribute("Command", "")
		if cmd == "play" then C.Play()
		elseif cmd == "stop" then C.Stop()
		elseif cmd == "clear" then C.Clear()
		elseif cmd == "undo" then C.Undo()
		elseif cmd == "save" then C.OnSave()
		elseif cmd == "close" then C.Hide()
		elseif cmd == "monitors" then C.OnMonitors()
		elseif cmd == "swing" then C.CycleSwing()
		elseif cmd == "kit" then C.CycleKit()
		elseif cmd == "page1" then C.SetPage(1)
		elseif cmd == "page2" then C.SetPage(2)
		elseif cmd == "keys" then C.ToggleView()
		elseif cmd == "view:keys" then C.SetView("keys")
		elseif cmd == "view:drums" then C.SetView("drums")
		elseif cmd == "scale" then roll.CycleScale()
		elseif cmd == "len" then roll.CycleLen()
		elseif cmd == "voice" then roll.CycleVoice()
		elseif cmd == "chord" then roll.ToggleChord()
		elseif cmd:sub(1, 6) == "stamp:" then
			local s, semi = cmd:match("^stamp:(%d+):(%-?%d+)$")
			if s then roll.Stamp(tonumber(s), tonumber(semi)) end
		elseif cmd:sub(1, 7) == "accent:" then
			local s = cmd:match("^accent:(%d+)$")
			if s then roll.ToggleAccent(tonumber(s)) end
		elseif cmd:sub(1, 5) == "note:" then
			local s, semi, len = cmd:match("^note:(%d+):(%-?%d+):?(%d*)$")
			if s then roll.Place(tonumber(s), tonumber(semi), tonumber(len)) end
		elseif cmd:sub(1, 7) == "unnote:" then
			local s, semi = cmd:match("^unnote:(%d+):(%-?%d+)$")
			if s then roll.Remove(tonumber(s), tonumber(semi)) end
		elseif cmd:sub(1, 5) == "slot:" then C.SetSlot(tonumber(cmd:sub(6)) or 1)
		elseif cmd:sub(1, 6) == "paint:" then
			local t, a, b = cmd:match("^paint:(%d+):(%d+):(%d+)$")
			if t then C.Paint(tonumber(t), tonumber(a), tonumber(b), true) end
		elseif cmd:sub(1, 4) == "tap:" then
			local t, s = cmd:match("^tap:(%d+):(%d+)$")
			if t then C.Tap(tonumber(t), tonumber(s)) end
		end
	end)
	for _, a in ipairs({ "Pattern", "BPM", "Swing", "Slot", "Playing", "Step", "Status", "UndoUntil", "Page", "Level", "Unlocked", "Kit", "NoteLen", "Chord", "Voice", "Voices" }) do
		root:GetAttributeChangedSignal(a):Connect(render)
	end
	for _, a in ipairs({ "Compact", "Touch", "TopbarFree", "Page", "ViewportOverride", "View", "Scale" }) do root:GetAttributeChangedSignal(a):Connect(function() layout(); render() end) end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() if root.Visible then layout(); render() end end)
	layout()
	render()
	return C
end

return M
