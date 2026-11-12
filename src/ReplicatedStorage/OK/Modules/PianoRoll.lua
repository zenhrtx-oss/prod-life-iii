-- OK Beat Maker piano roll: the KEYS view of the beat maker window (beat format v3's keys lane), modelled on FL Studio's
-- piano roll. A piano keyboard runs down the left (click a key to hear it); rows are shaded by the scale lock; beat lines
-- and a playhead line cross the grid; notes are green bars with their name and a grab handle on their last cell; the 808
-- line shows through as ghost notes; a velocity lane underneath holds one bar per note (normal / accent); CHORD stamps
-- a triad built from the scale. Editing: tap an empty cell to place a note (LEN steps), drag a note's body to move it
-- (pitch too with a mouse), drag its last cell to stretch it, tap a note or right-click it to remove it. On a phone a
-- vertical swipe scrolls the rows and changes nothing. Up to Keys.Voices notes sound together; a row outside the scale
-- lock stays visible while it holds a note.
-- State lives in attributes on the beat maker root (DAWUI): Pattern, Scale, NoteLen, Chord, Voice, Voices (owned), Step.
-- The gesture (BeginAt / MoveTo / End) is exposed so tests can drive it without real input.
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local M = {}
local MIN_TOUCH = 44
local SCROLL_PX = 12
local BLACK = { [1] = true, [3] = true, [6] = true, [8] = true, [10] = true }

-- root: the beat maker's root frame; onNote(semi, len, accent) auditions a note
function M.Build(root, Theme, Cfg, onNote)
	local K, nS = Cfg.Keys, Cfg.Steps
	local function new(class, props, parent)
		local i = Instance.new(class)
		for k, v in pairs(props) do i[k] = v end
		i.Parent = parent
		return i
	end
	local function corner(p, r) new("UICorner", { CornerRadius = UDim.new(0, r or 8) }, p) end
	local R = {}
	local function status(t) root:SetAttribute("Status", t) end
	local NOTE, ACCENT = K.Color, K.AccentColor or K.Color
	local TAIL, ACCENT_TAIL = NOTE:Lerp(Theme.bg, 0.4), ACCENT:Lerp(Theme.bg, 0.4)
	local INK = Color3.fromRGB(12, 36, 14) -- note names on the green bars
	local bassIdx, bassColor = nil, Color3.fromRGB(170, 90, 255)
	for i, tr in ipairs(Cfg.Tracks) do if tr.Kind == "bass" then bassIdx, bassColor = i, tr.Color end end
	local GHOST = bassColor:Lerp(Theme.bg, 0.55)
	R.NoteColor, R.AccentColor, R.GhostColor = NOTE, ACCENT, GHOST

	local roll = new("Frame", { Name = "Roll", BackgroundColor3 = Theme.bg, BorderSizePixel = 0, Visible = false, ClipsDescendants = true }, root)
	corner(roll, 10)
	-- toolbar: VOICE (instrument), SCALE (scale lock), LEN (length of a placed note), CHORD (stamp a triad)
	local bar = new("Frame", { Name = "KeysBar", BackgroundTransparency = 1 }, roll)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center }, bar)
	local function btn(name, text, order, color)
		local b = new("TextButton", { Name = name, Text = text, BackgroundColor3 = color or Theme.line, TextColor3 = Theme.text,
			Font = Theme.font, TextSize = 13, LayoutOrder = order, AutoButtonColor = true }, bar)
		corner(b, 8)
		return b
	end
	local voiceBtn = btn("VoiceBtn", "VOICE", 1, Color3.fromRGB(32, 64, 32))
	local scaleBtn = btn("ScaleBtn", "SCALE", 2)
	local lenBtn = btn("LenBtn", "LEN 1", 3)
	local chordBtn = btn("ChordBtn", "CHORD", 4)
	local info = new("TextLabel", { Name = "Info", Text = "", Font = Theme.font, TextSize = 12, TextColor3 = Theme.muted, BackgroundTransparency = 1,
		LayoutOrder = 5, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, bar)

	-- rows: one per semitone in range, shown or hidden by the scale lock, inside a vertical scroller
	local rows = new("ScrollingFrame", { Name = "Rows", BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6,
		ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.new(), ElasticBehavior = Enum.ElasticBehavior.Never,
		ScrollBarImageColor3 = Theme.muted, Selectable = false }, roll)
	local beatLines = {}
	for i = 1, 4 do beatLines[i] = new("Frame", { Name = "Beat" .. i, BackgroundColor3 = Color3.fromRGB(74, 74, 92), BorderSizePixel = 0, ZIndex = 1, Visible = false }, rows) end
	local playhead = new("Frame", { Name = "Playhead", BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 4, Visible = false }, rows)
	local keys = {} -- semi -> { key, cells }
	for semi = K.Range, -K.Range, -1 do
		local black = BLACK[semi % 12]
		local key = new("TextButton", { Name = "Key" .. semi, Text = Cfg.NoteName(semi), Font = Theme.font, TextSize = 11,
			TextColor3 = black and Theme.muted or Color3.fromRGB(40, 40, 50), BackgroundColor3 = black and Color3.fromRGB(26, 26, 32) or Color3.fromRGB(228, 228, 236),
			BorderSizePixel = 0, AutoButtonColor = true, TextXAlignment = Enum.TextXAlignment.Right, Selectable = false, Visible = false, ZIndex = 2 }, rows)
		new("UIPadding", { PaddingRight = UDim.new(0, 5) }, key)
		corner(key, 3)
		key.MouseButton1Click:Connect(function() onNote(semi, root:GetAttribute("NoteLen") or 1, false) end)
		local cells = {}
		for s = 1, nS do
			local c = new("TextButton", { Name = string.format("Note_%d_%d", semi, s), Text = "", AutoButtonColor = false, BorderSizePixel = 0,
				BackgroundColor3 = Theme.line, Selectable = true, Visible = false, Font = Theme.font, TextSize = 11, TextColor3 = INK,
				TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2 }, rows)
			new("UIPadding", { PaddingLeft = UDim.new(0, 4) }, c)
			corner(c, 3)
			new("Frame", { Name = "Handle", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 6, 1, 0),
				BackgroundColor3 = INK, BackgroundTransparency = 0.45, BorderSizePixel = 0, Visible = false, ZIndex = 3 }, c)
			cells[s] = c
		end
		keys[semi] = { key = key, cells = cells, black = black }
	end
	-- velocity lane: one bar per step where a note starts; tap or drag across it to set accents
	local lane = new("Frame", { Name = "Vel", BackgroundColor3 = Color3.fromRGB(14, 14, 19), BorderSizePixel = 0 }, roll)
	corner(lane, 6)
	local laneLabel = new("TextLabel", { Name = "Label", Text = "VEL", Font = Theme.font, TextSize = 11, TextColor3 = Theme.muted,
		BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left }, lane)
	local velBars = {}
	for s = 1, nS do
		local b = new("TextButton", { Name = "Vel_" .. s, Text = "", BackgroundColor3 = Theme.line, BackgroundTransparency = 0.6, AutoButtonColor = false,
			BorderSizePixel = 0, Selectable = false, Visible = false }, lane)
		corner(b, 3)
		new("Frame", { Name = "Bar", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0.5, 0),
			BackgroundColor3 = NOTE, BorderSizePixel = 0, Visible = false }, b)
		velBars[s] = b
	end

	-- layout: the roll takes the drum grid's rectangle; the columns line up with the ruler (same labelW / cellW) ----------
	-- touch (a touch screen, any layout: launch audit A11) gets the phone's 44 px bar, lane and rows, the rows scrolling
	local L = { rows = {}, shown = {}, inScale = {}, rowH = 0, cellW = 0, labelW = 0, s0 = 1, s1 = nS, scale = nil, args = nil }
	function R.Layout(x, y, w, h, compact, s0, s1, labelW, cellW, touch)
		L.args = { x, y, w, h, compact, s0, s1, labelW, cellW, touch }
		roll.Position = UDim2.fromOffset(x, y); roll.Size = UDim2.fromOffset(w, h)
		local big = compact or touch == true
		local barH = big and MIN_TOUCH or 26
		bar.Position = UDim2.fromOffset(6, 3); bar.Size = UDim2.fromOffset(w - 12, barH)
		local bw, lw, cw = 140, compact and 56 or 60, compact and 64 or 68
		voiceBtn.Size = UDim2.fromOffset(bw, barH); scaleBtn.Size = UDim2.fromOffset(bw, barH)
		lenBtn.Size = UDim2.fromOffset(lw, barH); chordBtn.Size = UDim2.fromOffset(cw, barH)
		local room = w - 12 - 2 * bw - lw - cw - 24
		info.Visible = room >= 60
		info.Size = UDim2.fromOffset(math.max(20, room), barH)
		local laneH = big and MIN_TOUCH or 30
		local top = barH + 8
		local avail = math.max(MIN_TOUCH, h - top - laneH - 10)
		rows.Position = UDim2.fromOffset(0, top); rows.Size = UDim2.fromOffset(w, avail)
		lane.Position = UDim2.fromOffset(4, top + avail + 4); lane.Size = UDim2.fromOffset(w - 8, laneH)
		laneLabel.Position = UDim2.fromOffset(4, 0); laneLabel.Size = UDim2.fromOffset(labelW - 8, laneH)
		local scale = root:GetAttribute("Scale")
		local sc = Cfg.ScaleById(scale) or K.Scales[1]
		local inScale = {}
		for _, s in ipairs(sc.steps) do inScale[s] = true end
		L.inScale = inScale
		local list = Cfg.ScaleRows(scale)
		-- rows outside the scale that hold a note stay visible, so a note can always be seen and removed
		local have, extra = {}, false
		for _, semi in ipairs(list) do have[semi] = true end
		for _, n in ipairs(Cfg.Notes(root:GetAttribute("Pattern"))) do
			if not have[n.semi] then have[n.semi] = true; extra = true end
		end
		if extra then
			list = {}
			for semi = K.Range, -K.Range, -1 do if have[semi] then table.insert(list, semi) end end
		end
		L.shown = have
		local rowH = big and (MIN_TOUCH + 4) or math.clamp(math.floor(avail / #list), 18, 34) -- touch cells stay 44 px tall
		local canvasH = #list * rowH
		rows.CanvasSize = UDim2.fromOffset(0, canvasH)
		local shownAt = {}
		for i, semi in ipairs(list) do shownAt[semi] = i end
		for semi = K.Range, -K.Range, -1 do
			local k = keys[semi]
			local i = shownAt[semi]
			if i then
				local ry = (i - 1) * rowH
				k.key.Visible = true
				k.key.Position = UDim2.fromOffset(4, ry + 1)
				k.key.Size = UDim2.fromOffset((k.black and not big) and math.floor((labelW - 8) * 0.68) or (labelW - 8), rowH - 2) -- touch: every key stays a 44 px target
				k.key.TextSize = rowH >= 24 and 12 or 10
				for s = 1, nS do
					local c = k.cells[s]
					if s >= s0 and s <= s1 then
						c.Visible = true
						c.Position = UDim2.fromOffset(labelW + (s - s0) * cellW + 2, ry + 2)
						c.Size = UDim2.fromOffset(cellW - 4, rowH - 4)
						c.TextSize = rowH >= 30 and 12 or 10
					else
						c.Visible = false
					end
				end
			else
				k.key.Visible = false
				for s = 1, nS do k.cells[s].Visible = false end
			end
		end
		for i, s in ipairs({ 1, 5, 9, 13 }) do
			local line = beatLines[i]
			line.Visible = s > s0 and s <= s1
			line.Position = UDim2.fromOffset(labelW + (s - s0) * cellW, 0); line.Size = UDim2.fromOffset(2, canvasH)
		end
		playhead.Size = UDim2.fromOffset(2, canvasH)
		for s = 1, nS do
			local b = velBars[s]
			b.Position = UDim2.fromOffset(labelW - 4 + (s - s0) * cellW + 2, 0); b.Size = UDim2.fromOffset(cellW - 4, laneH)
		end
		L.rows, L.rowH, L.cellW, L.labelW, L.s0, L.s1 = list, rowH, cellW, labelW, s0, s1
		-- when the rows do not fit, start (and restart after a scale change) with the root row in view
		if canvasH > avail and L.scale ~= scale then
			local rootRow = 1
			for j, semi in ipairs(list) do if semi == 0 then rootRow = j end end
			rows.CanvasPosition = Vector2.new(0, math.clamp((rootRow - 0.5) * rowH - avail / 2, 0, canvasH - avail))
		end
		L.scale = scale
	end
	function R.Relayout() if L.args then R.Layout(table.unpack(L.args)) end end

	-- render -----------------------------------------------------------------------------------------------------------
	local function rowBase(semi, s)
		local onBeat = (s - 1) % 4 == 0
		local pc = semi % 12
		if not L.inScale[pc] then return onBeat and Color3.fromRGB(30, 30, 38) or Color3.fromRGB(23, 23, 29) end -- outside the scale
		if pc == 0 then return onBeat and Color3.fromRGB(62, 60, 44) or Color3.fromRGB(52, 50, 38) end          -- the root rows
		if BLACK[pc] then return onBeat and Color3.fromRGB(46, 46, 58) or Color3.fromRGB(36, 36, 46) end         -- black keys
		return onBeat and Color3.fromRGB(58, 58, 72) or Color3.fromRGB(46, 46, 58)                                 -- white keys
	end
	function R.Render()
		if not roll.Visible then return end
		local p, step = root:GetAttribute("Pattern"), root:GetAttribute("Step")
		local notes = Cfg.Notes(p)
		for _, n in ipairs(notes) do if not L.shown[n.semi] then R.Relayout(); break end end -- a note landed on a hidden row
		local cover = {} -- [semi][step] = { note, head, last }
		local starts = {} -- [step] = { any = true, accent = bool }
		for _, n in ipairs(notes) do
			cover[n.semi] = cover[n.semi] or {}
			for s = n.step, n.step + n.len - 1 do cover[n.semi][s] = { note = n, head = s == n.step, last = s == n.step + n.len - 1 } end
			local st = starts[n.step] or { any = true, accent = false }
			st.accent = st.accent or n.accent
			starts[n.step] = st
		end
		local bass = (bassIdx and #p >= Cfg.KeysOffset) and p:sub((bassIdx - 1) * nS + 1, bassIdx * nS) or ""
		local showName = L.rowH >= 22
		for _, semi in ipairs(L.rows) do
			local cells, cv = keys[semi].cells, cover[semi]
			for s = L.s0, L.s1 do
				local c, item = cells[s], cv and cv[s]
				if item then
					local acc = item.note.accent
					c.BackgroundColor3 = item.head and (acc and ACCENT or NOTE) or (acc and ACCENT_TAIL or TAIL)
					c.Text = (item.head and showName) and Cfg.NoteName(semi) or ""
					c.Handle.Visible = item.last
				else
					local g = bass:sub(s, s)
					c.BackgroundColor3 = (g ~= "" and g ~= "0" and Cfg.Semitones(g) == semi) and GHOST or rowBase(semi, s)
					c.Text = ""
					c.Handle.Visible = false
				end
			end
		end
		if step > 0 and step >= L.s0 and step <= L.s1 then
			playhead.Visible = true
			playhead.Position = UDim2.fromOffset(L.labelW + (step - L.s0) * L.cellW, 0)
		else
			playhead.Visible = false
		end
		for s = 1, nS do
			local b = velBars[s]
			local st = starts[s]
			b.Visible = s >= L.s0 and s <= L.s1
			b.Bar.Visible = st ~= nil
			if st then
				b.Bar.Size = UDim2.new(1, 0, st.accent and 1 or 0.5, 0)
				b.Bar.BackgroundColor3 = st.accent and ACCENT or NOTE
			end
		end
		local v = Cfg.VoiceById(root:GetAttribute("Voice") or "")
		voiceBtn.Text = "VOICE: " .. (v and v.name or "?")
		local sc = Cfg.ScaleById(root:GetAttribute("Scale") or "")
		scaleBtn.Text = "SCALE: " .. (sc and sc.name or "?")
		lenBtn.Text = "LEN " .. tostring(root:GetAttribute("NoteLen") or 1)
		local chord = root:GetAttribute("Chord") == true
		chordBtn.Text = chord and "CHORD ON" or "CHORD"
		chordBtn.BackgroundColor3 = chord and NOTE:Lerp(Theme.bg, 0.5) or Theme.line
		info.Text = string.format("%d notes · tap to add, drag to move, drag the end to stretch, tap a note to remove", #notes)
	end
	local lastFlash = 0
	function R.Flash(step)
		if not roll.Visible or step == 0 or step == lastFlash then return end
		lastFlash = step
		if step < L.s0 or step > L.s1 then return end
		for _, n in ipairs(Cfg.Notes(root:GetAttribute("Pattern"))) do
			local k = n.step == step and keys[n.semi]
			if k and k.cells[step].Visible then
				local c = k.cells[step]
				c.BackgroundColor3 = Color3.new(1, 1, 1)
				TweenService:Create(c, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = n.accent and ACCENT or NOTE }):Play()
			end
		end
	end

	-- actions ----------------------------------------------------------------------------------------------------------
	function R.Place(step, semi, len, accent)
		local np, nn = Cfg.PlaceNote(root:GetAttribute("Pattern"), step, semi, len or root:GetAttribute("NoteLen") or 1, accent)
		if not np then
			status(nn == "full" and string.format("%d notes max at once", K.Voices) or nn == "taken" and "That note is already there" or "Out of range")
			return nil
		end
		root:SetAttribute("Pattern", np)
		onNote(semi, nn.len, nn.accent)
		return nn
	end
	function R.Remove(step, semi)
		local p = root:GetAttribute("Pattern")
		local n = Cfg.NoteAt(p, step, semi)
		if not n then return false end
		root:SetAttribute("Pattern", Cfg.RemoveNote(p, n))
		return true
	end
	function R.Toggle(step, semi) if not R.Remove(step, semi) then R.Place(step, semi) end end
	-- CHORD: a triad from the scale on the tapped row (fewer notes when voices are taken)
	function R.Stamp(step, semi)
		local p, placed = root:GetAttribute("Pattern"), {}
		for _, sm in ipairs(Cfg.ChordNotes(root:GetAttribute("Scale"), semi)) do
			local np, nn = Cfg.PlaceNote(p, step, sm, root:GetAttribute("NoteLen") or 1)
			if np then p = np; table.insert(placed, nn) end
		end
		if #placed == 0 then status("No room for a chord there"); return 0 end
		root:SetAttribute("Pattern", p)
		for _, nn in ipairs(placed) do onNote(nn.semi, nn.len, false) end
		status(string.format("Chord: %d notes on %s", #placed, Cfg.NoteName(semi)))
		return #placed
	end
	function R.ToggleChord()
		local on = not (root:GetAttribute("Chord") == true)
		root:SetAttribute("Chord", on)
		status(on and "CHORD: a tap places a triad from the scale" or "Single notes")
	end
	-- the velocity lane: accents for the notes starting on a step
	function R.SetAccent(step, on)
		local p = root:GetAttribute("Pattern")
		local changed = false
		for _, n in ipairs(Cfg.Notes(p)) do
			if n.step == step and n.accent ~= on then p = Cfg.SetAccent(p, n, on); changed = true end
		end
		if changed then root:SetAttribute("Pattern", p) end
		return changed
	end
	function R.ToggleAccent(step)
		local on = false
		for _, n in ipairs(Cfg.Notes(root:GetAttribute("Pattern"))) do if n.step == step and not n.accent then on = true end end
		R.SetAccent(step, on)
		return on
	end
	function R.CycleScale()
		local cur, nextS = root:GetAttribute("Scale"), K.Scales[1]
		for i, s in ipairs(K.Scales) do if s.id == cur then nextS = K.Scales[i + 1] or K.Scales[1] end end
		root:SetAttribute("Scale", nextS.id)
		status("Scale: " .. nextS.name .. (nextS.id == "all" and " · in-scale rows are lighter" or " · every row is in key"))
	end
	function R.CycleLen()
		local cur, nextL = root:GetAttribute("NoteLen") or 1, K.Lens[1]
		for i, l in ipairs(K.Lens) do if l == cur then nextL = K.Lens[i + 1] or K.Lens[1] end end
		root:SetAttribute("NoteLen", nextL)
	end
	-- VOICE cycles through the instruments you own (root attribute Voices = "box,pluck"); the client loads the sounds
	function R.CycleVoice()
		local owned = {}
		for id in string.gmatch(root:GetAttribute("Voices") or "", "[^,]+") do table.insert(owned, id) end
		if #owned <= 1 then status("More voices at the gear rack"); return end
		local cur, nextId = root:GetAttribute("Voice"), owned[1]
		for i, id in ipairs(owned) do if id == cur then nextId = owned[i % #owned + 1] end end
		root:SetAttribute("Voice", nextId)
		local v = Cfg.VoiceById(nextId)
		status("Voice: " .. (v and v.name or nextId))
		task.defer(function() onNote(0, 1, false) end) -- after the client has switched the sample
	end

	-- the gesture: a press on an empty cell places a note (or stamps a chord) and a drag along the row stretches it; a
	-- press on a note's last cell (the right half of a one-step note) grabs it to stretch, anywhere else to move; a
	-- press that never moved on an existing note removes it (a tap). On a phone a vertical swipe scrolls the rows: it
	-- must neither leave the note it placed behind nor remove the one it started on.
	local grab = nil
	local function stepAtX(x)
		if L.cellW == 0 then return nil end
		local s = L.s0 + math.floor((x - rows.AbsolutePosition.X - L.labelW) / L.cellW)
		if s < L.s0 or s > L.s1 then return nil end
		return s
	end
	local function rowAtY(y)
		if L.rowH == 0 then return nil end
		return L.rows[math.floor((y - rows.AbsolutePosition.Y + rows.CanvasPosition.Y) / L.rowH) + 1]
	end
	function R.StepX(s) return rows.AbsolutePosition.X + L.labelW + (s - L.s0 + 0.5) * L.cellW end -- screen x of a step (tests)
	function R.RowY(semi) -- screen y of a row (tests)
		for i, sm in ipairs(L.rows) do if sm == semi then return rows.AbsolutePosition.Y - rows.CanvasPosition.Y + (i - 0.5) * L.rowH end end
		return nil
	end
	-- mode (optional): "move" | "resize" | nil (from the press position); touch: a finger, which scrolls vertically
	function R.BeginAt(step, semi, pos, mode, touch)
		local n = Cfg.NoteAt(root:GetAttribute("Pattern"), step, semi)
		if not n then
			if root:GetAttribute("Chord") == true then R.Stamp(step, semi); return false end
			n = R.Place(step, semi)
			if not n then return false end
			grab = { note = n, existed = false, mode = "place", moved = false, scrolled = false, startStep = step, startPos = pos,
				canvasY = rows.CanvasPosition.Y, touch = touch == true, offset = 0 }
			return true
		end
		if not mode then
			if n.len == 1 then
				mode = (pos and L.cellW > 0 and (pos.X - (R.StepX(step) - L.cellW / 2)) > L.cellW * 0.5) and "resize" or "move"
			else
				mode = (step == n.step + n.len - 1) and "resize" or "move"
			end
		end
		grab = { note = n, existed = true, mode = mode, moved = false, scrolled = false, startStep = step, startPos = pos,
			canvasY = rows.CanvasPosition.Y, touch = touch == true, offset = step - n.step }
		return true
	end
	function R.DragTo(step)
		if not grab or grab.scrolled or not step then return end
		if step == grab.startStep and not grab.moved then return end
		grab.moved = true
		local len = math.max(1, step - grab.note.step + 1)
		if len ~= grab.note.len then
			local np, nn = Cfg.ResizeNote(root:GetAttribute("Pattern"), grab.note, len)
			root:SetAttribute("Pattern", np)
			grab.note = nn
		end
	end
	-- the pointer is at a screen position: a finger moving up or down before anything else is a scroll; along the row a
	-- stretch or a move; a mouse moving to another row moves the note's pitch
	function R.MoveTo(pos)
		if not grab or grab.scrolled then return end
		if grab.touch and not grab.moved and grab.startPos and (math.abs(pos.Y - grab.startPos.Y) > SCROLL_PX or rows.CanvasPosition.Y ~= grab.canvasY) then
			grab.scrolled = true
			return
		end
		local s = stepAtX(pos.X)
		if grab.mode ~= "move" then R.DragTo(s); return end
		if not s then return end
		local n = grab.note
		local head = math.clamp(s - grab.offset, 1, nS - n.len + 1)
		local semi = grab.touch and n.semi or (rowAtY(pos.Y) or n.semi)
		if head == n.step and semi == n.semi then return end
		grab.moved = true
		local np, nn = Cfg.MoveNote(root:GetAttribute("Pattern"), n, head, semi)
		if nn ~= n then
			root:SetAttribute("Pattern", np)
			grab.note = nn
			if semi ~= n.semi then onNote(semi, 1, nn.accent) end
		end
	end
	function R.End()
		if not grab then return end
		if grab.scrolled then
			if not grab.existed then root:SetAttribute("Pattern", Cfg.RemoveNote(root:GetAttribute("Pattern"), grab.note)) end -- a swipe is not a tap
		elseif grab.existed and not grab.moved then
			root:SetAttribute("Pattern", Cfg.RemoveNote(root:GetAttribute("Pattern"), grab.note))
		end
		grab = nil
	end
	for semi, k in pairs(keys) do
		for s, c in ipairs(k.cells) do
			c.InputBegan:Connect(function(input)
				local t = input.UserInputType
				if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
					R.BeginAt(s, semi, input.Position, nil, t == Enum.UserInputType.Touch)
				elseif t == Enum.UserInputType.MouseButton2 then
					R.Remove(s, semi)
				end
			end)
			c.Activated:Connect(function(input)
				if input and (input.UserInputType == Enum.UserInputType.Gamepad1 or input.KeyCode == Enum.KeyCode.ButtonA
					or input.KeyCode == Enum.KeyCode.Return) then
					R.Toggle(s, semi)
				end
			end)
		end
	end
	-- the velocity lane: press toggles the step's accent, dragging paints the same state across steps
	local velPaint = nil
	for s, b in ipairs(velBars) do
		b.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				velPaint = { on = R.ToggleAccent(s), last = s }
			end
		end)
	end
	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if grab then R.MoveTo(input.Position) end
		if velPaint then
			local s = stepAtX(input.Position.X)
			if s and s ~= velPaint.last then velPaint.last = s; R.SetAccent(s, velPaint.on) end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then R.End(); velPaint = nil end
	end)
	voiceBtn.MouseButton1Click:Connect(R.CycleVoice)
	scaleBtn.MouseButton1Click:Connect(R.CycleScale)
	lenBtn.MouseButton1Click:Connect(R.CycleLen)
	chordBtn.MouseButton1Click:Connect(R.ToggleChord)

	function R.SetVisible(on)
		roll.Visible = on
		if on then R.Render() end
	end
	function R.FirstCell() return keys[0].cells[L.s0] end
	R.Frame = roll
	return R
end

return M
