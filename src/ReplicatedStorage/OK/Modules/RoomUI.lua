-- OK Studio RoomUI (the Your Rooms plan, Task 10): decorate mode's edit bar, phone first. Client only (Build makes a
-- ScreenGui); its top level touches nothing, so requiring it anywhere is harmless. StarterPlayerScripts/OK/RoomClient
-- runs decorate mode (the camera, the controls, the ghost, the remotes) and paints this bar.
-- * Its own ScreenGui, PlayerGui.OK_Room (DisplayOrder 7, ResetOnSpawn false, CoreUISafeInsets: the same space as OK_UI).
--   Root is a top-left box the size of the gui, or of the gui's ForceViewport attribute (a Vector2) when a test sets
--   one, so phone sizes can be checked inside (0, 0)-vp on any screen. The bar (Root.Bar) sits at the bottom centre,
--   EDGE px off the box's sides and bottom; it shows only while decorating.
-- * In the bar: a head row (Mode, the "DECORATING" tag, then Hint: copy 6.13-6.15, or the sentence a refusal shows, copy
--   6.31-6.44) and the buttons, each MIN (44) px tall and at least 44 wide:
--   - nothing picked: Prev (◀), Item (a label: the shown item's name, then "{used} / {limit}"), Next (▶), Add (ADD), Done;
--   - an item picked (a new one, or one already placed): Item (its name and the count), Rotate (⟳ ROTATE), Place
--     (✓ PLACE), Remove (🗑 REMOVE: a placed one only), Cancel (✕ CANCEL), Done.
--   One row when the box is TWO_ROWS_BELOW (667) px wide or more and everything fits; otherwise two rows: the item group
--   and Done above, the actions below. A row that still doesn't fit narrows the Item label, then the buttons' padding,
--   then their text, and last splits what is left evenly (never under 44 px a button).
-- * The poster designer (Task 13), the bar's other face while a wall spot is picked (Paint's mode "poster"): the head row's
--   Mode reads "POSTER" (copy 9.24); three rows of ◀ / value / ▶ (WordPrev, Word, WordNext; ColorPrev, Color, ColorNext;
--   StylePrev, Style, StyleNext: each value a Frame holding its Caption, WORD / COLOR / STYLE (9.25-9.27), and its Value,
--   the word itself or §9's colour or style name), then HANG (9.28), 🗑 REMOVE (a poster already hung only), ✕ CANCEL and
--   DONE. Every control is MIN px tall and at least MIN wide; a value is as wide as the widest name it can show (from
--   Build's Config.Rooms), so the layout never jumps as you browse. A selector group (◀ value ▶) never splits. One row when
--   the box is TWO_ROWS_BELOW px wide or more and everything fits; otherwise the selector groups, packed as many to a row as
--   fit, then the actions (or both run on together when that takes fewer rows: two rows, not three, at 640 px); a row that
--   still doesn't fit narrows the padding, then the text, then splits evenly.
-- * A button sets the gui's Command attribute to its command ("prev", "next", "add", "rotate", "place", "remove",
--   "cancel", "done"; the designer's "word:-1", "word:+1", "color:-1", "color:+1", "style:-1", "style:+1", "hang"), the same
--   seam the tests use; RoomClient runs it and clears it.
-- * Attributes RoomUI writes on the gui: Rows and Layout ("<w>x<h>" of the box last laid out). RoomClient
--   writes the rest (Editing, Kind, Item, Selected, Ghost, GhostOk, Poster, LastEdit).
-- Copy: research/rooms/copy_2026-11-12.md §6 and §9 (draft lines on the user's approval list), in M.Copy. 6.1 / 6.2 (the
-- Decorate prompt) are Systems/Rooms' own; listed here for the record.
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")

local M = {}

M.Copy = {
	Action = "Decorate", Object = "Your room", -- 6.1, 6.2 (Systems/Rooms' DecoratePrompt)
	Mode = "DECORATING", -- 6.3
	Prev = "◀", Next = "▶", -- 6.4, 6.5
	Count = "{used} / {limit}", -- 6.6, after the item's name
	Add = "ADD", Rotate = "⟳ ROTATE", Place = "✓ PLACE", Remove = "🗑 REMOVE", Cancel = "✕ CANCEL", Done = "DONE", -- 6.7 - 6.12
	HintPick = "Pick a thing, then tap ADD.", -- 6.13
	HintNew = "Tap the floor to move it, then PLACE.", -- 6.14
	HintItem = "Move it, turn it or take it away.", -- 6.15
	Refusals = { -- 6.31 - 6.43: RoomRules.Fits' reasons, then the server's
		unknown = "That one isn't available.", locked = "You haven't unlocked that yet.",
		room = "That only goes in a bigger room.", bounds = "Keep it on the open floor.",
		overlap = "Something's already there.", limit = "This room is full. Remove one first.",
		max = "You've got enough of those.", rot = "That turn didn't work. Try again.",
		slot = "That wall spot is taken.", design = "That poster isn't available.",
		busy = "Slow down. One thing at a time.", away = "You can only decorate in your own room.",
		owner = "Only the owner can decorate here.",
	},
	Other = "Couldn't do that. Try again.", -- 6.44: any other reason ("invalid", "error", a failed call)
	Poster = "POSTER", -- 9.24: the designer's title (the head row's Mode)
	Word = "WORD", Color = "COLOR", Style = "STYLE", -- 9.25 - 9.27: the designer's rows (COLOR: the game's copy is American)
	Hang = "HANG", -- 9.28: hang it (a new poster, or a redesign)
	HintWall = "Tap an empty wall spot to hang a poster.", -- 9.29: after 6.13 while nothing is picked, in a room with a free spot
	HintDesign = "Pick a word, a color and a style.", -- 9.30: the designer's hint
}

-- the sentence a refusal reason shows
function M.Sentence(reason) return M.Copy.Refusals[reason] or M.Copy.Other end
-- the Item label: the name, then the count
function M.ItemText(name, used, limit)
	local count = string.gsub(M.Copy.Count, "{(%w+)}", { used = tostring(used or 0), limit = tostring(limit or 0) })
	return (name and name ~= "") and (name .. "  " .. count) or count
end

M.MIN = 44             -- a touch target, both ways
M.GAP = 6              -- between buttons, and between rows
M.PAD = 8              -- inside the bar
M.EDGE = 8             -- the bar to the box's sides and bottom
M.HEAD = 18            -- the head row (Mode, Hint)
M.TWO_ROWS_BELOW = 667 -- px: a narrower box always gets two rows
local TEXT, TEXT_SMALL, PAD_X, PAD_X_SMALL = 15, 13, 24, 12
local ITEM_MIN, ITEM_MAX = 96, 200
local VALUE_MIN, VALUE_MAX = 72, 132 -- px: a designer value box (the widest name it shows, + VALUE_PAD)
local VALUE_PAD = 16

-- rooms (optional) = Config.Rooms: the poster words, colour names and style names the designer's value boxes are sized for
function M.Build(Theme, rooms)
	local player = Players.LocalPlayer
	local pg = player:WaitForChild("PlayerGui", 10)
	local old = pg:FindFirstChild("OK_Room")
	if old then old:Destroy() end
	local gui = Instance.new("ScreenGui")
	gui.Name = "OK_Room"; gui.ResetOnSpawn = false; gui.DisplayOrder = 7
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	for k, v in pairs({ Editing = false, Kind = "", Item = "", Selected = "", Ghost = "", GhostOk = false, LastEdit = "",
		Poster = "", Command = "", Rows = 0, Layout = "" }) do gui:SetAttribute(k, v) end
	gui.Parent = pg
	local function new(class, props, parent)
		local i = Instance.new(class)
		for k, v in pairs(props) do i[k] = v end
		i.Parent = parent
		return i
	end
	local function corner(p, r) new("UICorner", { CornerRadius = UDim.new(0, r or 10) }, p) end
	local function measure(text, size, font)
		local ok, v = pcall(function() return TextService:GetTextSize(text, size, font, Vector2.new(2000, 200)) end)
		return ok and v.X or (#text * size * 0.6)
	end

	local root = new("Frame", { Name = "Root", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, gui)
	local bar = new("Frame", { Name = "Bar", BackgroundColor3 = Theme.panel, BackgroundTransparency = 0.06, BorderSizePixel = 0,
		Visible = false }, root)
	corner(bar, 12)
	new("UIStroke", { Color = Theme.line, Thickness = 1 }, bar)
	local mode = new("TextLabel", { Name = "Mode", BackgroundTransparency = 1, Font = Theme.fontBlack, TextSize = 12,
		TextColor3 = Theme.accent, Text = M.Copy.Mode, TextXAlignment = Enum.TextXAlignment.Left }, bar)
	local hint = new("TextLabel", { Name = "Hint", BackgroundTransparency = 1, Font = Theme.font, TextSize = 13,
		TextColor3 = Theme.text, Text = "", TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, bar)
	local function button(name, text, cmd)
		local b = new("TextButton", { Name = name, BackgroundColor3 = Theme.bg, BorderSizePixel = 0, AutoButtonColor = true,
			Font = Theme.fontBlack, TextSize = TEXT, TextColor3 = Theme.text, Text = text, Visible = false,
			TextTruncate = Enum.TextTruncate.AtEnd }, bar)
		corner(b, 10)
		new("UIStroke", { Color = Theme.line, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
		b.Activated:Connect(function() gui:SetAttribute("Command", cmd) end)
		return b
	end
	local B = {
		prev = button("Prev", M.Copy.Prev, "prev"),
		next = button("Next", M.Copy.Next, "next"),
		add = button("Add", M.Copy.Add, "add"),
		rotate = button("Rotate", M.Copy.Rotate, "rotate"),
		place = button("Place", M.Copy.Place, "place"),
		remove = button("Remove", M.Copy.Remove, "remove"),
		cancel = button("Cancel", M.Copy.Cancel, "cancel"),
		done = button("Done", M.Copy.Done, "done"),
	}
	local item = new("TextLabel", { Name = "Item", BackgroundTransparency = 1, Font = Theme.font, TextSize = TEXT,
		TextColor3 = Theme.text, Text = "", Visible = false, TextTruncate = Enum.TextTruncate.AtEnd }, bar)
	-- the poster designer (Task 13)
	local D = {
		wordPrev = button("WordPrev", M.Copy.Prev, "word:-1"), wordNext = button("WordNext", M.Copy.Next, "word:+1"),
		colorPrev = button("ColorPrev", M.Copy.Prev, "color:-1"), colorNext = button("ColorNext", M.Copy.Next, "color:+1"),
		stylePrev = button("StylePrev", M.Copy.Prev, "style:-1"), styleNext = button("StyleNext", M.Copy.Next, "style:+1"),
		hang = button("Hang", M.Copy.Hang, "hang"),
	}
	local function valueBox(name, caption)
		local f = new("Frame", { Name = name, BackgroundColor3 = Theme.bg, BackgroundTransparency = 0.3, BorderSizePixel = 0, Visible = false }, bar)
		corner(f, 10)
		new("TextLabel", { Name = "Caption", BackgroundTransparency = 1, Font = Theme.font, TextSize = 10, TextColor3 = Theme.muted,
			Text = caption, Position = UDim2.fromOffset(4, 3), Size = UDim2.new(1, -8, 0, 12) }, f)
		new("TextLabel", { Name = "Value", BackgroundTransparency = 1, Font = Theme.fontBlack, TextSize = TEXT, TextColor3 = Theme.text,
			Text = "", Position = UDim2.fromOffset(4, 15), Size = UDim2.new(1, -8, 1, -18), TextTruncate = Enum.TextTruncate.AtEnd }, f)
		return f
	end
	local V = { word = valueBox("Word", M.Copy.Word), color = valueBox("Color", M.Copy.Color), style = valueBox("Style", M.Copy.Style) }
	local ARROWS = { [B.prev] = true, [B.next] = true, [D.wordPrev] = true, [D.wordNext] = true, [D.colorPrev] = true,
		[D.colorNext] = true, [D.stylePrev] = true, [D.styleNext] = true }
	local VALUES = { [V.word] = true, [V.color] = true, [V.style] = true }
	-- every control the bar lays out, in one list (a control no row holds is hidden)
	local ALL = { B.prev, item, B.next, B.add, B.rotate, B.place, B.remove, B.cancel, B.done,
		D.wordPrev, V.word, D.wordNext, D.colorPrev, V.color, D.colorNext, D.stylePrev, V.style, D.styleNext, D.hang }

	local function viewport()
		local f = gui:GetAttribute("ForceViewport")
		if typeof(f) == "Vector2" and f.X > 0 and f.Y > 0 then return f end
		local s = gui.AbsoluteSize
		if s.X > 0 and s.Y > 0 then return s end
		local cam = workspace.CurrentCamera
		return cam and cam.ViewportSize or Vector2.new(1280, 720)
	end

	-- what the bar shows (Paint's view)
	local cur = { mode = "none", name = "", used = 0, limit = 0, canAdd = false, canBrowse = false, ok = true, hint = "" }
	local barTop = 0 -- the bar's top inside the box, as last laid out

	-- the value boxes' width: the widest name each can show (Config.Rooms' lists), at a size
	local function valueWidth(size)
		local widest = 0
		local lists = type(rooms) == "table" and { rooms.PosterWords, rooms.PosterColorNames, rooms.PosterStyleNames } or {}
		for _, list in ipairs(lists) do
			for _, name in ipairs(type(list) == "table" and list or {}) do widest = math.max(widest, measure(tostring(name), size, Theme.fontBlack)) end
		end
		if widest == 0 then widest = measure("HUSTLE", size, Theme.fontBlack) end
		return math.clamp(math.ceil(widest) + VALUE_PAD, VALUE_MIN, VALUE_MAX)
	end
	-- a control's natural width at a text size and side padding
	local function natural(g, size, pad)
		if ARROWS[g] then return M.MIN end
		if VALUES[g] then return valueWidth(size) end
		if g == item then return math.clamp(math.ceil(measure(item.Text, size, item.Font)) + 8, ITEM_MIN, ITEM_MAX) end
		return math.max(M.MIN, math.ceil(measure(g.Text, size, g.Font)) + pad)
	end
	local function span(row, widths)
		local s = 0
		for i, g in ipairs(row) do s += widths[g] + (i > 1 and M.GAP or 0) end
		return s
	end
	local function concat(...)
		local out = {}
		for _, list in ipairs({ ... }) do for _, g in ipairs(list) do table.insert(out, g) end end
		return out
	end

	-- the item bar's rows (nothing picked, a new item, a placed one)
	local function barRows(vp, avail, widths, textSize)
		local picked = cur.mode ~= "none"
		B.prev.Visible = not picked and cur.canBrowse
		B.next.Visible = not picked and cur.canBrowse
		B.add.Visible = not picked and cur.canAdd
		B.rotate.Visible, B.place.Visible, B.cancel.Visible = picked, picked, picked
		B.remove.Visible = cur.mode == "item"
		B.done.Visible = true
		item.Visible = true
		item.Text = M.ItemText(cur.name, cur.used, cur.limit)
		B.place.BackgroundColor3 = cur.ok and Color3.fromRGB(0, 120, 72) or Theme.bg
		B.place.TextColor3 = cur.ok and Theme.text or Theme.muted
		-- the groups, in order
		local itemGroup = {}
		for _, g in ipairs({ B.prev, item, B.next }) do if g.Visible then table.insert(itemGroup, g) end end
		local acts = {}
		for _, g in ipairs({ B.add, B.rotate, B.place, B.remove, B.cancel }) do if g.Visible then table.insert(acts, g) end end
		-- natural widths at full size
		for _, g in ipairs({ B.prev, item, B.next, B.add, B.rotate, B.place, B.remove, B.cancel, B.done }) do
			widths[g] = natural(g, TEXT, PAD_X)
			textSize[g] = TEXT
		end
		local one = concat(itemGroup, acts, { B.done })
		local rows
		if vp.X >= M.TWO_ROWS_BELOW and span(one, widths) <= avail then rows = { one }
		else rows = { concat(itemGroup, { B.done }), acts } end
		if #rows == 2 and #rows[2] == 0 then table.remove(rows, 2) end
		-- a row that still doesn't fit: the Item label narrows, then the padding, then the text, then an even split
		for _, row in ipairs(rows) do
			if span(row, widths) > avail and table.find(row, item) then
				widths[item] = math.max(ITEM_MIN - 16, widths[item] - (span(row, widths) - avail))
			end
			if span(row, widths) > avail then
				for _, g in ipairs(row) do if g ~= item then widths[g] = natural(g, TEXT, PAD_X_SMALL) end end
			end
			if span(row, widths) > avail then
				for _, g in ipairs(row) do
					widths[g] = g == item and math.min(widths[g], natural(g, TEXT_SMALL, 0)) or natural(g, TEXT_SMALL, PAD_X_SMALL)
					textSize[g] = TEXT_SMALL
				end
			end
			if span(row, widths) > avail then
				local even = math.max(M.MIN, math.floor((avail - (#row - 1) * M.GAP) / #row))
				for _, g in ipairs(row) do widths[g] = even end
			end
		end
		return rows
	end

	-- the poster designer's rows (Task 13): the selector groups (never split), then the actions
	local function designerRows(vp, avail, widths, textSize)
		for _, g in ipairs({ B.prev, item, B.next, B.add, B.rotate, B.place }) do g.Visible = false end
		for _, g in ipairs({ D.wordPrev, V.word, D.wordNext, D.colorPrev, V.color, D.colorNext, D.stylePrev, V.style, D.styleNext, D.hang, B.cancel, B.done }) do
			g.Visible = true
		end
		B.remove.Visible = cur.hung == true
		V.word.Value.Text = tostring(cur.word or "")
		V.color.Value.Text = tostring(cur.color or "")
		V.style.Value.Text = tostring(cur.style or "")
		D.hang.BackgroundColor3 = cur.ok and Color3.fromRGB(0, 120, 72) or Theme.bg
		D.hang.TextColor3 = cur.ok and Theme.text or Theme.muted
		local groups = { { D.wordPrev, V.word, D.wordNext }, { D.colorPrev, V.color, D.colorNext }, { D.stylePrev, V.style, D.styleNext } }
		local acts = {}
		for _, g in ipairs({ D.hang, B.remove, B.cancel, B.done }) do if g.Visible then table.insert(acts, { g }) end end
		for _, g in ipairs(ALL) do
			widths[g] = natural(g, TEXT, PAD_X)
			textSize[g] = TEXT
		end
		-- units (a group, or one action) packed into rows as many as fit
		local function pack(units)
			local rows, row, w = {}, nil, 0
			for _, u in ipairs(units) do
				local uw = span(u, widths)
				if row and w + M.GAP + uw <= avail then
					for _, g in ipairs(u) do table.insert(row, g) end
					w += M.GAP + uw
				else
					row = {}
					table.insert(rows, row)
					for _, g in ipairs(u) do table.insert(row, g) end
					w = uw
				end
			end
			return rows
		end
		-- one row when it all fits at TWO_ROWS_BELOW or wider; else the selectors' rows then the actions' rows, unless running
		-- them on together takes fewer rows (a box a little under 667 px: two rows, not three)
		local rows = pack(concat(groups, acts))
		if not (vp.X >= M.TWO_ROWS_BELOW and #rows == 1) then
			local split = concat(pack(groups), pack(acts))
			if #split <= #rows then rows = split end
		end
		-- a row that still doesn't fit (a box narrower than any phone): the padding, then the text, then an even split
		for _, row in ipairs(rows) do
			if span(row, widths) > avail then
				for _, g in ipairs(row) do widths[g] = natural(g, TEXT, PAD_X_SMALL) end
			end
			if span(row, widths) > avail then
				for _, g in ipairs(row) do widths[g] = natural(g, TEXT_SMALL, PAD_X_SMALL); textSize[g] = TEXT_SMALL end
			end
			if span(row, widths) > avail then
				local even = math.max(M.MIN, math.floor((avail - (#row - 1) * M.GAP) / #row))
				for _, g in ipairs(row) do widths[g] = even end
			end
		end
		return rows
	end

	local function layout()
		local vp = viewport()
		root.Size = UDim2.fromOffset(vp.X, vp.Y)
		local designing = cur.mode == "poster"
		mode.Text = designing and M.Copy.Poster or M.Copy.Mode
		hint.Text = cur.hint or ""
		local avail = math.max(M.MIN, vp.X - 2 * M.EDGE - 2 * M.PAD)
		local widths, textSize = {}, {}
		local rows = designing and designerRows(vp, avail, widths, textSize) or barRows(vp, avail, widths, textSize)
		-- the bar: as wide as its widest row or its head row, inside the box
		local headW = math.ceil(measure(mode.Text, 12, mode.Font)) + 10 + math.ceil(measure(hint.Text, 13, hint.Font))
		local inner = math.max(headW, 0)
		for _, row in ipairs(rows) do inner = math.max(inner, span(row, widths)) end
		inner = math.min(inner, avail)
		local barW = inner + 2 * M.PAD
		local barH = M.PAD + M.HEAD + M.GAP + #rows * M.MIN + (#rows - 1) * M.GAP + M.PAD
		bar.Size = UDim2.fromOffset(barW, barH)
		bar.Position = UDim2.fromOffset(math.floor((vp.X - barW) / 2), vp.Y - barH - M.EDGE)
		barTop = vp.Y - barH - M.EDGE
		local modeW = math.ceil(measure(mode.Text, 12, mode.Font))
		mode.Position = UDim2.fromOffset(M.PAD, M.PAD); mode.Size = UDim2.fromOffset(modeW, M.HEAD)
		hint.Position = UDim2.fromOffset(M.PAD + modeW + 10, M.PAD)
		hint.Size = UDim2.fromOffset(math.max(0, inner - modeW - 10), M.HEAD)
		-- every row centred in the bar, its controls left to right
		local shown = {}
		local y = M.PAD + M.HEAD + M.GAP
		for _, row in ipairs(rows) do
			local x = M.PAD + math.floor((inner - math.min(span(row, widths), inner)) / 2)
			for _, g in ipairs(row) do
				g.Position = UDim2.fromOffset(x, y)
				g.Size = UDim2.fromOffset(widths[g], M.MIN)
				if VALUES[g] then g.Value.TextSize = textSize[g] else g.TextSize = textSize[g] end
				x += widths[g] + M.GAP
				shown[g] = true
			end
			y += M.MIN + M.GAP
		end
		for _, g in ipairs(ALL) do
			if not shown[g] then g.Visible = false end
		end
		gui:SetAttribute("Rows", #rows)
		gui:SetAttribute("Layout", string.format("%dx%d", math.floor(vp.X + 0.5), math.floor(vp.Y + 0.5)))
	end

	local ui = { gui = gui, bar = bar, buttons = B, item = item, hint = hint, designer = D, values = V }
	-- view = { mode = "none" | "new" | "item" | "poster", name, used, limit, canAdd, canBrowse, ok (the ghost or the poster
	-- fits), hint; for "poster" (Task 13): word, color, style (the names the value boxes show) and hung (a poster already on
	-- the spot: REMOVE shows) }
	function ui.Paint(view)
		for k, v in pairs(view) do cur[k] = v end
		layout()
	end
	function ui.Show(on)
		bar.Visible = on == true
		if on then layout() end
	end
	function ui.Shown() return bar.Visible end
	-- px from the bottom of the real screen that the bar covers (its height, its gap and whatever lies under the gui):
	-- RoomClient keeps the room's floor above it
	function ui.Reserved()
		local cam = workspace.CurrentCamera
		local screenH = cam and cam.ViewportSize.Y or 0
		local inset = game:GetService("GuiService"):GetGuiInset()
		local top = inset.Y + gui.AbsolutePosition.Y + barTop -- the bar's top in the camera's viewport
		return math.max(bar.Size.Y.Offset + M.EDGE, screenH - top)
	end
	gui:GetAttributeChangedSignal("ForceViewport"):Connect(layout)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	layout()
	return ui
end

return M
