-- Client, during play (Wave 3 Task 5c-1; launch audit A1, A3, A11; fix round 1), after t82a's fresh() (unseated in the
-- lounge, Quiet on, WalkIns, Career and Life reset, no hints). The file's own fresh(): unseated, the beat maker closed,
-- no forced size or touch. The beat maker is opened at the studio PC and measured on screen, in the drums view and the
-- KEYS view, at:
--   phones (CompactForced, ViewportOverride): 640x360, 667x375, 771x390 (an 844x390 less a 73 px notch), 844x390;
--   touch screens (TouchForced, ViewportOverride; the layout picked by the height rule, DAWLayout.COMPACT_UNDER 700):
--   1024x600 must come up compact (a phone), 1024x768 desktop.
-- At each, for every GuiButton on screen in OK_DAW (itself and its ancestors visible, its rect clipped to the KEYS view's
-- scrolling rows and the roll; one scrolled out of sight is not on screen; ModalCatcher, the 0 px modal helper, aside):
-- (1) it is 44 px or more both ways; (2) no two overlap; (3) none touches the Roblox top bar's own buttons: the bar's
-- occupied ends, left of GuiService.TopbarInset.Min.X and right of its Max.X, down to its Max.Y, in screen space (laid out
-- in a ScreenGui with no insets, as the docs place a frame in the free area); (4) every one under the window but the
-- desktop request card's (docked above the window by design) sits inside it; (5) at least as many are on screen as the
-- layout shows (each case's min, worked out below), the forced size reached the window (phones and compact: W = vp.X -
-- 12, H = vp.Y - 12; desktop: W = min(vp.X - 24, 980)), and the view really switched before it is measured. On compact
-- windows (6) the header row's last button ends at least 6 px left of the REQUESTS chip (A3), and the chip sits at
-- max(W - 190, header right + 6) in the window. On the touch screens the window took Touch from the seam; in every KEYS
-- view the rows scroll. At 1024x600 (7) every visible piece of the request UI sits inside the screen: the chip, the card
-- it opens and the requests picker. Every problem is collected and reported together; the seams, the view, the card and
-- the window are set back either way.
local Players, GuiService = game:GetService("Players"), game:GetService("GuiService")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character
local hrp = char:WaitForChild("HumanoidRootPart"); local hum = char:WaitForChild("Humanoid"); local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui")
local gui = pg:WaitForChild("OK_DAW", 10); assert(gui, "no OK_DAW gui")
local daw = gui:WaitForChild("DAW", 10); assert(daw, "no beat maker window")
local req = daw:WaitForChild("Request", 10); assert(req, "no request card (RequestUI.Build did not run?)")
local T0 = os.clock()
local SEAMS = { "CompactForced", "ViewportOverride", "TouchForced" }
-- min: the fewest GuiButtons each view shows at that size
--   compact drums 61: 5 tracks x 8 pads + 5 track labels + the column's 10 (PLAY, BPM - and +, MONITORS, CLEAR, SWING,
--     the slots 1-3, SAVE) + the header's 4 (1-8, 9-16, KIT, KEYS) + the chip + close
--   compact keys: those 16 (column, header, chip, close) + the KEYS bar's 4 + 8 velocity bars + 9 per piano row (its
--     key and 8 note cells) for each whole 48 px row the rows' box holds: 3 at 360-390 px tall (148-178 px), 8 at
--     1024x600 (388 px): 55 and 100
--   desktop drums 99: 5 x 16 pads + 5 labels + the transport row's 7 + the header's 5 (the slots, KIT, KEYS) + close +
--     the docked request card's REQUESTS (DELIVER shows only with a request taken)
--   desktop keys 85: those 14 (all but pads and labels) + the KEYS bar's 4 + 16 velocity bars + 17 per row (key and 16
--     cells) for 3 rows (144 px)
-- forced: CompactForced true (phones); touch screens leave it unset, so the height rule picks their layout
local CASES = {
	{ name = "640x360", vp = Vector2.new(640, 360), forced = true, compact = true, min = { drums = 61, keys = 55 } },
	{ name = "667x375", vp = Vector2.new(667, 375), forced = true, compact = true, min = { drums = 61, keys = 55 } },
	{ name = "771x390", vp = Vector2.new(771, 390), forced = true, compact = true, min = { drums = 61, keys = 55 } },
	{ name = "844x390", vp = Vector2.new(844, 390), forced = true, compact = true, min = { drums = 61, keys = 55 } },
	{ name = "1024x600 touch", vp = Vector2.new(1024, 600), touch = true, compact = true, requestUI = true, min = { drums = 61, keys = 100 } },
	{ name = "1024x768 touch", vp = Vector2.new(1024, 768), touch = true, compact = false, min = { drums = 99, keys = 85 } },
}
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function rectOf(g) local p, s = g.AbsolutePosition, g.AbsoluteSize; return { x0 = p.X, y0 = p.Y, x1 = p.X + s.X, y1 = p.Y + s.Y } end
local function clip(a, b) return { x0 = math.max(a.x0, b.x0), y0 = math.max(a.y0, b.y0), x1 = math.min(a.x1, b.x1), y1 = math.min(a.y1, b.y1) } end
local function empty(r) return r.x1 - r.x0 < 1 or r.y1 - r.y0 < 1 end
local function overlaps(a, b) return a.x0 < b.x1 - 1 and b.x0 < a.x1 - 1 and a.y0 < b.y1 - 1 and b.y0 < a.y1 - 1 end
local function inside(a, b) return a.x0 >= b.x0 - 1 and a.y0 >= b.y0 - 1 and a.x1 <= b.x1 + 1 and a.y1 <= b.y1 + 1 end
local function fmt(r) return string.format("(%d,%d)-(%d,%d)", r.x0, r.y0, r.x1, r.y1) end
local function nameOf(b) return (b.Parent and b.Parent ~= daw and b.Parent ~= gui) and (b.Parent.Name .. "." .. b.Name) or b.Name end
local function some(list) -- the first few, then a count
	local shown = {}
	for i = 1, math.min(#list, 5) do shown[i] = list[i] end
	return table.concat(shown, ", ") .. (#list > 5 and string.format(" and %d more", #list - 5) or "")
end
local out, problems = {}, {}
local probe = nil -- a ScreenGui with no insets: the screen's own space, the one GuiService.TopbarInset is in

-- the file's own fresh(): unseated, the beat maker closed, no forced size or touch
local function fresh()
	if hum.Sit then hum.Sit = false; task.wait(0.4) end
	for _, a in ipairs(SEAMS) do daw:SetAttribute(a, nil) end
	if daw.Visible then daw:SetAttribute("Command", "close"); task.wait(0.4) end
	cam.CameraType = Enum.CameraType.Custom
end

-- the bar's occupied ends as rects on screen: left of the free area and right of it, down to the bar's bottom
local function barRects()
	local r = GuiService.TopbarInset
	assert(r.Max.Y > 0 and r.Min.X > 0, "GuiService.TopbarInset is " .. tostring(r) .. ": no Roblox top bar to measure the beat maker against")
	if not probe then
		probe = Instance.new("ScreenGui")
		probe.Name = "T82_Screen"; probe.ResetOnSpawn = false; probe.IgnoreGuiInset = true; probe.ScreenInsets = Enum.ScreenInsets.None
		probe.Parent = pg
	end
	probe:ClearAllChildren()
	local left = Instance.new("Frame"); left.Name = "BarLeft"; left.BackgroundTransparency = 1
	left.Size = UDim2.fromOffset(r.Min.X, r.Max.Y); left.Parent = probe
	local right = Instance.new("Frame"); right.Name = "BarRight"; right.BackgroundTransparency = 1
	right.Position = UDim2.fromOffset(r.Max.X, 0); right.Size = UDim2.new(1, -r.Max.X, 0, r.Max.Y); right.Parent = probe
	task.wait(0.1)
	local rects = { left = rectOf(left) }
	if right.AbsoluteSize.X >= 1 then rects.right = rectOf(right) end
	return rects, r
end

-- every GuiButton on screen in OK_DAW: itself and every ancestor visible, its rect clipped to each clipping ancestor
local function onScreen()
	local list = {}
	for _, b in ipairs(gui:GetDescendants()) do
		if b:IsA("GuiButton") and b.Visible and b.Name ~= "ModalCatcher" then
			local r, vis, n = rectOf(b), true, b.Parent
			while n and n ~= gui do
				if n:IsA("GuiObject") then
					if not n.Visible then vis = false; break end
					if n.ClipsDescendants then r = clip(r, rectOf(n)) end
				end
				n = n.Parent
			end
			if vis and not empty(r) then table.insert(list, { b = b, r = r }) end
		end
	end
	return list
end

-- no requests overlay (the open's sessions fetch can show the picker late, for a player with no delivery yet) and no
-- phone request card over the grid
local function noOverlay()
	return waitFor(function()
		if req:GetAttribute("Overlay") ~= "none" then req:SetAttribute("Command", "close") end
		if req:GetAttribute("CardOpen") == true then req:SetAttribute("Command", "card") end
		return req:GetAttribute("Overlay") == "none" and req:GetAttribute("CardOpen") ~= true
	end, 4)
end

-- every visible GuiObject of `top` (itself included) on screen, clipped to each clipping ancestor up to the gui, that is
-- not inside `screen` (1 px slack); returns the misfits and how many were looked at
local function outsideOf(top, screen)
	local bad, n = {}, 0
	local items = top:GetDescendants()
	table.insert(items, 1, top)
	for _, g in ipairs(items) do
		if g:IsA("GuiObject") and g.Visible then
			local r, vis, a = rectOf(g), true, g.Parent
			while a and a ~= gui do
				if a:IsA("GuiObject") then
					if not a.Visible then vis = false; break end
					if a.ClipsDescendants then r = clip(r, rectOf(a)) end
				end
				a = a.Parent
			end
			if vis and not empty(r) then
				n += 1
				if not inside(r, screen) then table.insert(bad, nameOf(g) .. " " .. fmt(r)) end
			end
		end
	end
	return bad, n
end

-- (7) the request UI inside the screen (the forced size, from the gui's corner): the chip, the card it opens, the picker
local function requestInside(where, vp, found)
	local o = gui.AbsolutePosition
	local screenR = { x0 = o.X, y0 = o.Y, x1 = o.X + vp.X, y1 = o.Y + vp.Y }
	local chip = daw:FindFirstChild("RequestChip")
	local bad, looked = {}, 0
	local function take(list, n) for _, b in ipairs(list) do table.insert(bad, b) end; looked += n end
	if chip and chip.Visible then take(outsideOf(chip, screenR)) else table.insert(found, "request UI: the chip is hidden") end
	req:SetAttribute("Command", "card")
	if waitFor(function() return req:GetAttribute("CardOpen") == true and req.Visible end, 2) then take(outsideOf(req, screenR))
	else table.insert(found, "request UI: the chip's card did not open") end
	req:SetAttribute("Command", "card")
	req:SetAttribute("Command", "requests") -- fetches the offers, then shows the picker
	local picker = daw:FindFirstChild("Picker")
	if picker and waitFor(function() return req:GetAttribute("Overlay") == "picker" and picker.Visible end, 5) then task.wait(0.2); take(outsideOf(picker, screenR))
	else table.insert(found, "request UI: the requests picker did not open") end
	req:SetAttribute("Command", "close")
	if not noOverlay() then table.insert(found, "request UI: the card or the picker would not close") end
	if #bad > 0 then table.insert(found, "request UI outside the screen " .. fmt(screenR) .. ": " .. some(bad)) end
	return string.format("; request UI (chip, card, picker: %d pieces) inside the screen %s", looked, fmt(screenR))
end

-- one size, one view: every check, the problems collected under `where`
local function measure(where, case, view)
	local found = {}
	-- the view really switched (else the KEYS case would measure the drums again)
	if not waitFor(function() return daw:GetAttribute("View") == view and daw.Roll.Visible == (view == "keys") and daw.Grid.Visible == (view ~= "keys") end, 2) then
		table.insert(found, string.format("the view did not switch to %s (View %s, roll shown %s)", view, tostring(daw:GetAttribute("View")), tostring(daw.Roll.Visible)))
	end
	assert(noOverlay(), where .. ": the request overlay or card would not close")
	task.wait(0.4) -- DAWUI and RequestUI lay out at once; the rects settle on the next frames
	local list = onScreen()
	local bar, inset = barRects()
	local win = rectOf(daw)
	local small, under, outside, hits = {}, {}, {}, {}
	for _, e in ipairs(list) do
		local s = e.b.AbsoluteSize
		if s.X < 44 or s.Y < 44 then table.insert(small, string.format("%s %dx%d", nameOf(e.b), s.X, s.Y)) end
		for side, br in pairs(bar) do
			if overlaps(e.r, br) then table.insert(under, string.format("%s %s (bar %s %s)", nameOf(e.b), fmt(e.r), side, fmt(br))) end
		end
		if e.b:IsDescendantOf(daw) and not e.b:IsDescendantOf(req) and not inside(e.r, win) then
			table.insert(outside, nameOf(e.b) .. " " .. fmt(e.r))
		end
	end
	for i = 1, #list do
		for j = i + 1, #list do
			local a, b = list[i], list[j]
			if overlaps(a.r, b.r) and not a.b:IsAncestorOf(b.b) and not b.b:IsAncestorOf(a.b) then
				table.insert(hits, nameOf(a.b) .. " " .. fmt(a.r) .. " x " .. nameOf(b.b) .. " " .. fmt(b.r))
			end
		end
	end
	if #under > 0 then table.insert(found, "under the Roblox top bar: " .. some(under)) end
	if #hits > 0 then table.insert(found, "overlapping: " .. some(hits)) end
	if #small > 0 then table.insert(found, "under 44 px: " .. some(small)) end
	if #outside > 0 then table.insert(found, "outside the window " .. fmt(win) .. ": " .. some(outside)) end
	if #list < case.min[view] then table.insert(found, string.format("only %d buttons on screen, want at least %d", #list, case.min[view])) end
	-- the forced size reached the window (the relations DAWUI's layout uses)
	local W, H = win.x1 - win.x0, win.y1 - win.y0
	local compactNow = daw:GetAttribute("Compact") == true
	if compactNow then
		if math.abs(W - (case.vp.X - 12)) > 1 or math.abs(H - (case.vp.Y - 12)) > 1 then
			table.insert(found, string.format("the window is %dx%d, want %dx%d (the forced size less 6 px a side)", W, H, case.vp.X - 12, case.vp.Y - 12))
		end
	elseif math.abs(W - math.min(case.vp.X - 24, 980)) > 1 then
		table.insert(found, string.format("the window is %d wide, want min(%d - 24, 980) = %d", W, case.vp.X, math.min(case.vp.X - 24, 980)))
	end
	if compactNow ~= case.compact then
		table.insert(found, string.format("the window came up %s, want %s (%s)", compactNow and "compact" or "desktop", case.compact and "compact" or "desktop",
			case.forced and "CompactForced" or "a touch screen picked by its height"))
	end
	if case.touch and daw:GetAttribute("Touch") ~= true then table.insert(found, "TouchForced did not reach the window's Touch (seam missing?)") end
	if view == "keys" then
		local rows = daw.Roll.Rows
		if not (rows.CanvasSize.Y.Offset > rows.AbsoluteSize.Y and rows.AbsoluteSize.Y >= 44) then
			table.insert(found, string.format("the KEYS rows do not scroll (canvas %d in %d px)", rows.CanvasSize.Y.Offset, rows.AbsoluteSize.Y))
		end
	end
	local note = ""
	if case.compact and compactNow then
		-- A3: the header row ends 6 px or more left of the chip; the chip at max(W - 190, header right + 6) in the window
		local right = -math.huge
		for _, c in ipairs(daw.HeaderRow:GetChildren()) do
			if c:IsA("GuiButton") and c.Visible then right = math.max(right, c.AbsolutePosition.X + c.AbsoluteSize.X) end
		end
		local chip, close = daw:FindFirstChild("RequestChip"), daw:FindFirstChild("Close")
		if not (chip and chip.Visible and close and close.Visible) then
			table.insert(found, "the REQUESTS chip or the close button is hidden")
		else
			local cx = chip.AbsolutePosition.X - win.x0
			local hr = right - win.x0
			if hr > cx - 6 + 0.5 then table.insert(found, string.format("A3: the header row ends at x %d, less than 6 px left of the chip at %d", hr, cx)) end
			-- the chip's home is W - 190, 140 px left of the close button at W - 50 (it moves left with the close button
			-- only when the bar has buttons on the right too)
			local home = (close.AbsolutePosition.X - win.x0) - 140
			local want = math.max(home, hr + 6)
			if math.abs(cx - want) > 1 then table.insert(found, string.format("the chip sits at x %d, want max(W - 190, header right + 6) = %d (W %d, home %d)", cx, want, W, home)) end
			note = string.format("; header ends %d, chip %d..%d (%d wide), close at %d", hr, cx, cx + chip.AbsoluteSize.X, chip.AbsoluteSize.X, home + 140)
		end
		if case.requestUI and view == "drums" then note ..= requestInside(where, case.vp, found) end
	end
	if #found > 0 then
		table.insert(problems, where .. ": " .. table.concat(found, "; "))
	else
		table.insert(out, string.format("%s: %s %dx%d, %d buttons on screen (min %d), all >= 44 px, none overlapping, none under the top bar (free from x %d, bar %d tall), inside the window %s%s",
			where, compactNow and "compact" or "desktop", W, H, #list, case.min[view], inset.Min.X, inset.Max.Y, fmt(win), note))
	end
end

local function run()
	fresh()
	-- open at the studio PC (as t30)
	local screen = workspace.OKStudio.ControlRoom.Screen_Main
	local pos = Vector3.new(72.0, 3.5, -5.5)
	hrp.CFrame = CFrame.lookAt(pos, Vector3.new(screen.Position.X, pos.Y, screen.Position.Z)); task.wait(1.0)
	cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(-4, 3, 0), screen.Position); task.wait(1.5)
	local prompt = screen:FindFirstChildWhichIsA("ProximityPrompt", true)
	for _ = 1, 4 do prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); task.wait(0.8); if daw.Visible then break end end
	assert(daw.Visible, "the beat maker did not open at the studio PC")
	daw:SetAttribute("Command", "stop")
	task.wait(1.0) -- the open's sessions fetch (a player with no delivery yet gets the picker from it)
	for _, case in ipairs(CASES) do
		daw:SetAttribute("TouchForced", case.touch)
		daw:SetAttribute("CompactForced", case.forced)
		daw:SetAttribute("ViewportOverride", case.vp)
		daw:SetAttribute("Page", 1)
		for _, view in ipairs({ "drums", "keys" }) do
			daw:SetAttribute("Command", "view:" .. view)
			measure(case.name .. " " .. view, case, view)
		end
	end
	assert(#problems == 0, #problems .. " layout problem(s):\n" .. table.concat(problems, "\n"))
end

local ok, err = pcall(run)
if req:GetAttribute("Overlay") ~= "none" then req:SetAttribute("Command", "close") end
if req:GetAttribute("CardOpen") == true then req:SetAttribute("Command", "card") end
for _, a in ipairs(SEAMS) do daw:SetAttribute(a, nil) end
daw:SetAttribute("Page", 1)
if daw.Visible then daw:SetAttribute("Command", "view:drums"); task.wait(0.2); daw:SetAttribute("Command", "close"); task.wait(0.4) end
cam.CameraType = Enum.CameraType.Custom
if probe then probe:Destroy() end
if not ok then error(err, 0) end
return "T82B PLAY OK\n" .. table.concat(out, "\n") .. string.format("\nelapsed %.1f s", os.clock() - T0)
