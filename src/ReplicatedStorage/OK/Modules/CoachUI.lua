-- OK Studio coach marks (the Day One plan, Task 5): a short label with a small arrow beside the live beat-maker control
-- the tour's step needs next, for the take, deliver and monitors steps only (Data/DayOne's Marks, copy §6; the DAY ONE
-- pill covers open and gear). Its own ScreenGui, OK_Coach (DisplayOrder 6, ResetOnSpawn false, CoreUISafeInsets): above
-- the beat maker (OK_DAW, 5), under the walk-in and Day One card (OK_WalkIn, 8). Driven only by the server's "Tour"
-- events (ClientMain passes every payload to Set: { done, step, ... }); it never decides progress.
-- * The controls are found by name under PlayerGui.OK_DAW every 0.2 s (Modules/DAWUI is Aku's design area and stays
--   untouched; RequestUI's card, chip and picker sit in the same window), the first one on screen:
--   take: the starter's TAKE button in the picker (Take_<id>, DayOneRules.Starter on Data/Artists' briefs: j1; fix 1,
--     review minor 3: the copy says "Tap the request to take it", and that is the button that takes it), else the
--     card's REQUESTS button (Requests), else the phone chip (RequestChip);
--   deliver: DELIVER (Deliver) while the Request card shows, else RequestChip;
--   monitors: DAWUI's Monitors button ("📢 ON MONITORS" at the hub, "🔊 ON SPEAKERS" in a room; the mark names neither).
-- * It shows only while the beat maker is open (OK_DAW enabled and its DAW frame shown), the Request card's Overlay is
--   "none", no listen-back cutaway runs (Request.Cutaway), no walk-in or Day One card is open (OK_WalkIn's Open) and the
--   control is on screen (it and every GuiObject above it shown, its rect not empty once clipped to any scrolling or
--   clipping frame above it). One exception to the Overlay rule (the controller's ruling): the take step's TAKE button
--   lives in the picker, so there the picker ("picker") counts as none. The deliver mark also hides while the Request
--   card shows a message (its Message attribute: "Delivering…", "Make it yours: change N more pads", "Not yet: …"), so
--   the specific reason is never under it (fix 1, review Important 1).
-- * Where the mark goes (fix 1, review Important 1): it never covers a control. The spots are tried in order: above,
--   below, left and right of the control (8 px off it), then the four corners diagonal from it; the first one that fits
--   the screen and misses every blocker wins, and with none the mark hides rather than cover something. The blockers:
--   every GuiButton on screen in OK_DAW (each rect clipped like the control's), the control itself, the Request card's
--   message line (Msg) and the beat maker's status line (StatusText), both feedback a player reads, and the DAY ONE pill
--   (OK_UI.Tour) while it shows. A spot wholly inside the open picker only has to miss the picker's own buttons (what is
--   under the picker can't be seen). "Fits the screen" is this gui's area less 4 px, and, while a test forces the beat
--   maker's size (its ViewportOverride attribute), that forced box at OK_DAW's corner too. The pill and the arrow's tip
--   (a 10 px square turned 45°, half under the pill, on the side facing the control) both count. Rects are compared in
--   absolute space, so OK_DAW's DeviceSafeInsets and this gui's CoreUISafeInsets need no conversion.
-- * Labels only: Active = false, nothing selectable, no button.
-- Attributes on OK_Coach (tests): CoachStep (the step whose mark applies: take, deliver or monitors; "" for none: a done
-- tour, no payload yet, or a step with no mark), CoachAnchor (the Name of the control the mark points at while it shows,
-- else "") and CoachVisible.
local Players, RS, RunService = game:GetService("Players"), game:GetService("ReplicatedStorage"), game:GetService("RunService")
local TextService = game:GetService("TextService")
local M = {}
local PERIOD = 0.2 -- how often the controls are looked up and the mark placed
local H = 30       -- the pill's height
local PADX = 12    -- the pill's side padding
local ARROW = 10   -- the arrow: a square this size turned 45°, half of it under the pill
local TIP = 7      -- half the turned square's span: how far its tip box reaches each way from its centre
local GAP = 8      -- between the pill and the control (the arrow's tip sits in it)
local EDGE = 4     -- the pill's least margin to the screen's edges
local TEXT = 13    -- the line's text size

local function rectOf(g) local p, s = g.AbsolutePosition, g.AbsoluteSize; return { x0 = p.X, y0 = p.Y, x1 = p.X + s.X, y1 = p.Y + s.Y } end
local function hits(a, b) return a.x0 < b.x1 and b.x0 < a.x1 and a.y0 < b.y1 and b.y0 < a.y1 end
local function inside(a, b) return a.x0 >= b.x0 and a.y0 >= b.y0 and a.x1 <= b.x1 and a.y1 <= b.y1 end

function M.Build(Theme)
	local player = Players.LocalPlayer
	local D = require(RS.OK.Data.DayOne)
	local Rules = require(RS.OK.Modules.DayOneRules)
	local Artists = require(RS.OK.Data.Artists)
	local MARKS = type(D.Marks) == "table" and D.Marks or {}
	local starter = Rules.Starter(Artists.Briefs)
	local TAKE = starter and ("Take_" .. starter.id) or nil -- RequestUI's TAKE button on the starter's picker row
	local pg = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "OK_Coach"; gui.ResetOnSpawn = false; gui.DisplayOrder = 6; gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	for k, v in pairs({ CoachStep = "", CoachAnchor = "", CoachVisible = false }) do gui:SetAttribute(k, v) end
	local mark = Instance.new("TextLabel")
	mark.Name = "Mark"; mark.Active = false; mark.Selectable = false; mark.Visible = false; mark.ZIndex = 2
	mark.BackgroundColor3 = Theme.accent; mark.BorderSizePixel = 0; mark.TextColor3 = Theme.text
	mark.Font = Theme.fontBlack; mark.TextSize = TEXT; mark.Text = ""; mark.Size = UDim2.fromOffset(120, H)
	do
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, math.floor(H / 2)); c.Parent = mark
		local tc = Instance.new("UITextSizeConstraint"); tc.MaxTextSize = TEXT; tc.Parent = mark
	end
	mark.Parent = gui
	local arrow = Instance.new("Frame")
	arrow.Name = "Arrow"; arrow.Active = false; arrow.Selectable = false; arrow.Visible = false; arrow.ZIndex = 1
	arrow.BackgroundColor3 = Theme.accent; arrow.BorderSizePixel = 0; arrow.Rotation = 45
	arrow.AnchorPoint = Vector2.new(0.5, 0.5); arrow.Size = UDim2.fromOffset(ARROW, ARROW)
	arrow.Parent = gui
	gui.Parent = pg

	local function setAttr(k, v) if gui:GetAttribute(k) ~= v then gui:SetAttribute(k, v) end end
	local step = "" -- the step whose mark applies ("" for none)
	local textW = 0 -- the mark's text width at TEXT
	local warned = false
	local function report(err)
		if not warned then warned = true; warn("[OK][ERR] CoachUI: " .. tostring(err)) end
	end
	local function hide()
		mark.Visible = false; arrow.Visible = false
		setAttr("CoachAnchor", ""); setAttr("CoachVisible", false)
	end
	-- on screen in ScreenGui sg: sg enabled, x and every GuiObject above it shown; its absolute rect clipped to every
	-- scrolling or clipping frame above it, or nil when that leaves nothing
	local function onScreen(x, sg)
		if not (x and sg and sg.Enabled and x:IsA("GuiObject")) then return nil end
		local r = rectOf(x)
		local n = x
		while n and n ~= sg do
			if n:IsA("GuiObject") then
				if not n.Visible then return nil end
				if n ~= x and (n:IsA("ScrollingFrame") or n.ClipsDescendants) then
					local q = rectOf(n)
					r = { x0 = math.max(r.x0, q.x0), y0 = math.max(r.y0, q.y0), x1 = math.min(r.x1, q.x1), y1 = math.min(r.y1, q.y1) }
				end
			end
			n = n.Parent
		end
		if n ~= sg or r.x1 - r.x0 < 1 or r.y1 - r.y0 < 1 then return nil end
		return r
	end
	-- the step's candidate controls by name, in order (the first one on screen is the anchor)
	local function names(card, dg)
		if step == "take" then
			if TAKE then return { TAKE, "Requests", "RequestChip" } end
			return { "Requests", "RequestChip" } -- no single starter brief: no picker row to point at
		end
		if step == "deliver" then return (card and onScreen(card, dg)) and { "Deliver" } or { "RequestChip" } end
		if step == "monitors" then return { "Monitors" } end
		return {}
	end
	-- the screen the pill must stay inside (absolute): this gui less EDGE, and the beat maker's forced box when a test
	-- forces its size (ViewportOverride, at OK_DAW's corner, as DAWUI lays the window out in it)
	local function screenBox(dg, root)
		local o, s = gui.AbsolutePosition, gui.AbsoluteSize
		local b = { x0 = o.X + EDGE, y0 = o.Y + EDGE, x1 = o.X + s.X - EDGE, y1 = o.Y + s.Y - EDGE }
		local vp = root:GetAttribute("ViewportOverride")
		if typeof(vp) == "Vector2" then
			local d = dg.AbsolutePosition
			b = { x0 = math.max(b.x0, d.X + EDGE), y0 = math.max(b.y0, d.Y + EDGE), x1 = math.min(b.x1, d.X + vp.X - EDGE), y1 = math.min(b.y1, d.Y + vp.Y - EDGE) }
		end
		return b
	end
	-- the spots for a w x H pill around the control's rect r, in the order they're tried; each { pill, tip, tipBox }, all
	-- absolute; a spot that doesn't fit the screen box b is left out (above and below may slide sideways to fit, left and
	-- right up or down; the corners can't)
	local function spots(r, w, b)
		local list = {}
		local cx, cy = (r.x0 + r.x1) / 2, (r.y0 + r.y1) / 2
		local inset = math.min(H, w) / 2
		local function add(x0, y0, edge) -- edge: the pill's side facing the control, where the arrow sits
			x0, y0 = math.floor(x0 + 0.5), math.floor(y0 + 0.5)
			local pill = { x0 = x0, y0 = y0, x1 = x0 + w, y1 = y0 + H }
			if not inside(pill, b) then return end
			local tx, ty
			if edge == "bottom" or edge == "top" then
				tx, ty = math.clamp(cx, x0 + inset, x0 + w - inset), edge == "bottom" and pill.y1 or pill.y0
			else
				tx, ty = edge == "right" and pill.x1 or pill.x0, y0 + H / 2
			end
			table.insert(list, { pill = pill, tip = Vector2.new(tx, ty), tipBox = { x0 = tx - TIP, y0 = ty - TIP, x1 = tx + TIP, y1 = ty + TIP } })
		end
		local function slideX(x) return math.clamp(x, b.x0, math.max(b.x0, b.x1 - w)) end
		local function slideY(y) return math.clamp(y, b.y0, math.max(b.y0, b.y1 - H)) end
		add(slideX(cx - w / 2), r.y0 - GAP - H, "bottom") -- above
		add(slideX(cx - w / 2), r.y1 + GAP, "top") -- below
		add(r.x0 - GAP - w, slideY(cy - H / 2), "right") -- left
		add(r.x1 + GAP, slideY(cy - H / 2), "left") -- right
		add(r.x1 + GAP, r.y0 - GAP - H, "bottom") -- the corners: above right, above left, below right, below left
		add(r.x0 - GAP - w, r.y0 - GAP - H, "bottom")
		add(r.x1 + GAP, r.y1 + GAP, "top")
		add(r.x0 - GAP - w, r.y1 + GAP, "top")
		return list
	end
	-- the first spot that misses every blocker (see the header), or nil
	local function firstClear(list, r, dg, root, card)
		if #list == 0 then return nil end
		local u = { x0 = math.huge, y0 = math.huge, x1 = -math.huge, y1 = -math.huge } -- every spot's extent: a cheap first test
		for _, c in ipairs(list) do
			for _, q in ipairs({ c.pill, c.tipBox }) do
				u = { x0 = math.min(u.x0, q.x0), y0 = math.min(u.y0, q.y0), x1 = math.max(u.x1, q.x1), y1 = math.max(u.y1, q.y1) }
			end
		end
		-- the open picker: a spot wholly inside it shows only the picker's own controls, which still count
		local picker = root:FindFirstChild("Picker")
		local cover = (card and card:GetAttribute("Overlay") == "picker" and picker) and onScreen(picker, dg) or nil
		local function block(br, ownPicker)
			if not hits(u, br) then return end
			for _, c in ipairs(list) do
				if not c.blocked and (hits(c.pill, br) or hits(c.tipBox, br))
					and not (cover and not ownPicker and inside(c.pill, cover) and inside(c.tipBox, cover)) then
					c.blocked = true
				end
			end
		end
		block(r, true) -- the control itself
		for _, d in ipairs(dg:GetDescendants()) do
			if d:IsA("GuiButton") and hits(u, rectOf(d)) then
				local vr = onScreen(d, dg)
				if vr then block(vr, picker ~= nil and d:IsDescendantOf(picker)) end
			end
		end
		for _, lbl in ipairs({ card and card:FindFirstChild("Msg") or false, root:FindFirstChild("StatusText", true) or false }) do
			local vr = lbl and onScreen(lbl, dg)
			if vr then block(vr, false) end
		end
		local ui = pg:FindFirstChild("OK_UI")
		local tourPill = ui and ui:IsA("ScreenGui") and ui:FindFirstChild("Tour")
		local tr = tourPill and onScreen(tourPill, ui)
		if tr then block(tr, false) end
		for _, c in ipairs(list) do if not c.blocked then return c end end
		return nil
	end
	local function tick()
		if step == "" then hide(); return end
		local dg = pg:FindFirstChild("OK_DAW")
		local root = dg and dg:FindFirstChild("DAW")
		-- the beat maker open; the cutaway turns its gui off (and sets the card's Cutaway)
		if not (dg and dg:IsA("ScreenGui") and dg.Enabled and root and root:IsA("GuiObject") and root.Visible) then hide(); return end
		local card = root:FindFirstChild("Request")
		if card and card:GetAttribute("Cutaway") == true then hide(); return end
		local wi = pg:FindFirstChild("OK_WalkIn")
		if wi and wi:GetAttribute("Open") == true then hide(); return end -- a walk-in or Day One card is open
		-- a delivery's message (its reason) wins over "press DELIVER"
		if step == "deliver" and card and tostring(card:GetAttribute("Message") or "") ~= "" then hide(); return end
		local anchor, r
		for _, n in ipairs(names(card, dg)) do
			local x = root:FindFirstChild(n, true)
			r = x and onScreen(x, dg)
			if r then anchor = x; break end
		end
		if not anchor then hide(); return end
		local overlay = card and card:GetAttribute("Overlay") or "none"
		if not (overlay == "none" or (step == "take" and overlay == "picker" and anchor.Name == TAKE)) then hide(); return end
		local b = screenBox(dg, root)
		local w = math.min(textW + 2 * PADX, b.x1 - b.x0)
		if w < H or b.y1 - b.y0 < H then hide(); return end
		local c = firstClear(spots(r, w, b), r, dg, root, card)
		if not c then hide(); return end -- every spot covers a control: no mark rather than a covered one
		local o = gui.AbsolutePosition
		mark.TextScaled = w < textW + 2 * PADX -- a very narrow screen: the line shrinks rather than spill (capped at TEXT)
		mark.Size = UDim2.fromOffset(w, H)
		mark.Position = UDim2.fromOffset(c.pill.x0 - o.X, c.pill.y0 - o.Y)
		arrow.Position = UDim2.fromOffset(math.floor(c.tip.X - o.X + 0.5), math.floor(c.tip.Y - o.Y + 0.5))
		mark.Visible = true; arrow.Visible = true
		setAttr("CoachAnchor", anchor.Name); setAttr("CoachVisible", true)
	end
	local function run()
		local ok, err = pcall(tick)
		if not ok then hide(); report(err) end
	end

	local C = { Gui = gui, Mark = mark }
	-- every Tour payload: the step's mark when it has one and the tour isn't done, else none (guarded: a failure here never
	-- reaches ClientMain's Tour handler; fix 1, review minor 1)
	function C.Set(s)
		local ok, err = pcall(function()
			local st = (type(s) == "table" and s.done ~= true and type(s.step) == "string") and s.step or ""
			if type(MARKS[st]) ~= "string" or MARKS[st] == "" then st = "" end
			if st ~= "" and mark.Text ~= MARKS[st] then
				mark.Text = MARKS[st]
				textW = math.ceil(TextService:GetTextSize(MARKS[st], TEXT, Theme.fontBlack, Vector2.new(10000, H)).X)
			end
			step = st
			setAttr("CoachStep", st)
		end)
		if not ok then report(err) end
		run()
	end
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt; if acc < PERIOD then return end; acc = 0
		run()
	end)
	return C
end

return M
