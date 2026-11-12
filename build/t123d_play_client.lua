-- Client, during play (the Day One plan, Task 4: Day One on screen; fix 1: card 3 is a `now` card too, and the Gear tab
-- opens on top), after t123c opened the beat maker at the bedroom laptop and left card 2 ("play it on your speakers?",
-- now = true) open over it. The file's own fresh(): no forced size on OK_WalkIn or the beat maker (it stays open: t123c
-- opened it for this file), the camera given back.
-- (1) The beat maker (OK_DAW.DAW) is open, and card 2 is shown over it: OK_WalkIn Open and not Deferred, Card
--     day1_speakers, DAY ONE / SKIP, 2 choices, no face (the Portrait square hidden, no View: its visitor has no id).
-- (2) At 667x375, 771x390 and 844x390 (preflight F8: the beat maker forced compact through its own CompactForced and
--     ViewportOverride at the phone's size; OK_WalkIn through ForceViewport at that size less its real insets, as t47b):
--     the beat maker is open and Compact, card 2 is still open and not deferred over it, the Waiting chip is hidden, and
--     every GuiButton on screen in OK_WalkIn shows 44 px or more (its rect clipped to the Scroll), inside (0, 0)-vp and
--     overlapping no other (at least the 2 choices and SKIP); the line is shown.
-- (3) Command "choose:2" (Keep it private): LastChoose "ok", the card closes. The server's real loop then sends card 3
--     ("spend it?", now = true since fix 1) within Config.DayOne.AfterSpeakers + 3 s: Card day1_spend, shown over the
--     still-open beat maker (Open, not Deferred), DAY ONE / SKIP, 2 choices, no face.
-- (4) The same three phone sizes, the beat maker compact under it: card 3 open and not deferred, no chip, its buttons
--     44 px, inside and apart, and its line kept (its tool and goal live there).
-- (5) With the beat maker still open (compact, 844x390), Command "choose:1" (Hit the gear rack.; the player stands at
--     t123c's stand spot, in reach of the RackSpot): LastChoose "ok", the card closes, the beat maker closes (a Gear
--     OpenPanel closes it: DAWClient, fix 1), and the Gear tab opens on top: OK_UI.Panel shown with Gear_ rows, and
--     nothing on screen in OK_DAW or OK_WalkIn (both draw over OK_UI) overlaps it. The tour is done: TourVisible false,
--     the pill's frame and the outline off, TourTarget "" and TourPulse false.
-- On any error, and after success: the forced sizes off, the panel hidden, the beat maker closed, the camera given back;
-- then the error is rethrown. Any card still open is left for t123e's DayOne Reset (SKIP would skip the tour).
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui", 10)
local wg = pg:WaitForChild("OK_WalkIn", 10); assert(wg, "no OK_WalkIn gui (WalkInUI.Build did not run?)")
local ui = pg:WaitForChild("OK_UI", 10); assert(ui, "no OK_UI")
local tour = ui:WaitForChild("Tour", 5); assert(tour, "no OK_UI.Tour (TourUI.Build did not run?)")
local hl = ui:WaitForChild("OK_TourHighlight", 5); assert(hl, "no OK_UI.OK_TourHighlight")
local panel = ui:WaitForChild("Panel", 5); assert(panel, "no OK_UI.Panel")
local dawGui = pg:WaitForChild("OK_DAW", 10)
local daw = dawGui and dawGui:WaitForChild("DAW", 10); assert(daw, "no beat maker gui (PlayerGui.OK_DAW.DAW)")
local Config = require(RS.OK.Config)
local D = require(RS.OK.Data.DayOne)
local RED = " (before the D1-T4 sync of Modules/WalkInUI, Modules/TourUI and Systems/Tour: the expected red)"
local SCREENS = { Vector2.new(667, 375), Vector2.new(771, 390), Vector2.new(844, 390) }
local SEAMS = { "CompactForced", "ViewportOverride" }
local T0 = os.clock()
local out = {}

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
-- rects in the walk-in gui's own space: (0, 0) is its top-left, so a forced viewport's box is (0, 0)-vp
local function rel(g) local p, s = g.AbsolutePosition - wg.AbsolutePosition, g.AbsoluteSize; return { x0 = p.X, y0 = p.Y, x1 = p.X + s.X, y1 = p.Y + s.Y } end
local function clip(a, b) return { x0 = math.max(a.x0, b.x0), y0 = math.max(a.y0, b.y0), x1 = math.min(a.x1, b.x1), y1 = math.min(a.y1, b.y1) } end
local function empty(r) return r.x1 - r.x0 < 1 or r.y1 - r.y0 < 1 end
local function overlaps(a, b) return a.x0 < b.x1 - 1 and b.x0 < a.x1 - 1 and a.y0 < b.y1 - 1 and b.y0 < a.y1 - 1 end
local function fmt(r) return string.format("(%d,%d)-(%d,%d)", r.x0, r.y0, r.x1, r.y1) end
-- on screen: the object and every GuiObject above it up to the gui are Visible
local function onScreen(g)
	local x = g
	while x and x ~= wg do
		if x:IsA("GuiObject") and not x.Visible then return false end
		x = x.Parent
	end
	return x == wg and wg.Enabled
end
-- on screen in gui `g`: the object and every GuiObject above it up to g are Visible
local function shownIn(x, g)
	while x and x ~= g do
		if x:IsA("GuiObject") and not x.Visible then return false end
		x = x.Parent
	end
	return x == g
end
-- its rect, clipped to every ScrollingFrame or clipping frame above it (a choice scrolled out of sight is empty)
local function shownRect(g)
	local r = rel(g)
	local x = g.Parent
	while x and x ~= wg do
		if x:IsA("ScrollingFrame") or (x:IsA("GuiObject") and x.ClipsDescendants) then r = clip(r, rel(x)) end
		x = x.Parent
	end
	return r
end
local function card() return wg:FindFirstChild("Card", true) end

-- every GuiButton on screen in OK_WalkIn: 44 px or more, inside (0, 0)-vp, none overlapping; at least `want` of them
local function buttons(where, vp, want)
	local list = {}
	for _, d in ipairs(wg:GetDescendants()) do
		if d:IsA("GuiButton") and onScreen(d) then
			local r = shownRect(d)
			if not empty(r) then table.insert(list, { b = d, r = r }) end
		end
	end
	assert(#list >= want, string.format("%s: %d buttons on screen in OK_WalkIn, want at least %d (the choices and %s)", where, #list, want, D.Skip))
	for _, e in ipairs(list) do
		-- the size on screen: its rect clipped to the Scroll, so a choice mostly under the fold fails (fix 1, minor 4)
		local w, h = e.r.x1 - e.r.x0, e.r.y1 - e.r.y0
		assert(w >= 43.5 and h >= 43.5, string.format("%s: %s shows %dx%d px on screen (%dx%d in all), want 44 or more both ways", where, e.b.Name, w, h,
			e.b.AbsoluteSize.X, e.b.AbsoluteSize.Y))
		assert(e.r.x0 >= -1 and e.r.y0 >= -1 and e.r.x1 <= vp.X + 1 and e.r.y1 <= vp.Y + 1, string.format("%s: %s %s is outside (0,0)-(%d,%d)", where, e.b.Name, fmt(e.r), vp.X, vp.Y))
	end
	for i = 1, #list do
		for j = i + 1, #list do
			local a, b = list[i], list[j]
			if not a.b:IsAncestorOf(b.b) and not b.b:IsAncestorOf(a.b) then
				assert(not overlaps(a.r, b.r), string.format("%s: %s %s overlaps %s %s", where, a.b.Name, fmt(a.r), b.b.Name, fmt(b.r)))
			end
		end
	end
	return #list
end
-- the open Day One card `id`'s header row, bottom button, choice count and (no) face
local function looks(label, id, n)
	local c = card()
	assert(c and c.Visible, label .. ": Card frame missing or hidden while Open")
	assert(wg:GetAttribute("Card") == id, label .. ": Card is '" .. tostring(wg:GetAttribute("Card")) .. "', want " .. id)
	local header, walk = c:FindFirstChild("Header"), c:FindFirstChild("WalkAway")
	assert(header and header.Text == D.Header, label .. ": the header reads '" .. tostring(header and header.Text) .. "', want '" .. D.Header .. "'")
	assert(walk and walk.Text == D.Skip, label .. ": the bottom button reads '" .. tostring(walk and walk.Text) .. "', want '" .. D.Skip .. "'")
	assert(wg:GetAttribute("Choices") == n, label .. ": Choices is " .. tostring(wg:GetAttribute("Choices")) .. ", want " .. n)
	local portrait = c:FindFirstChild("Portrait")
	assert(portrait and portrait:FindFirstChild("View") == nil and not portrait.Visible, label .. ": the portrait square is "
		.. (portrait and ((portrait.Visible and "shown" or "hidden") .. (portrait:FindFirstChild("View") and " with a View" or "")) or "missing")
		.. ", want it hidden with no View (the visitor has no id; fix 1, minor 9)")
	return c
end
local function lineShown(where, c)
	local line = c:FindFirstChild("Line", true)
	assert(line and line.Visible and line.Text ~= "", where .. ": the line is " .. (line and (line.Visible and "empty" or "hidden") or "missing")
		.. ", want it shown (a Day One card keeps its line on a short phone)")
	return line
end
local function choose(label, n)
	wg:SetAttribute("LastChoose", "")
	wg:SetAttribute("Command", "choose:" .. n)
	assert(waitFor(function() return wg:GetAttribute("LastChoose") ~= "" end, 5), label .. ": choose:" .. n .. " got no answer within 5 s (LastChoose empty)")
	assert(wg:GetAttribute("LastChoose") == "ok", label .. ": choose:" .. n .. " answered '" .. tostring(wg:GetAttribute("LastChoose")) .. "', want ok (DayOne_Choose)")
	assert(waitFor(function() return wg:GetAttribute("Open") == false end, 3), label .. ": the card is still open after choose:" .. n)
end
local function unforce()
	wg:SetAttribute("ForceViewport", nil)
	for _, a in ipairs(SEAMS) do daw:SetAttribute(a, nil) end
end

local function run()
	unforce()
	cam.CameraType = Enum.CameraType.Custom
	-- 1. card 2 over the open beat maker
	assert(waitFor(function() return daw.Visible end, 8), "the beat maker isn't open (t123c's RunStation opens it at the bedroom laptop)")
	assert(waitFor(function() return wg:GetAttribute("Open") == true and wg:GetAttribute("Card") == "day1_speakers" end, 10),
		"no Day One card opened over the beat maker within 10 s: Card '" .. tostring(wg:GetAttribute("Card")) .. "', Open " .. tostring(wg:GetAttribute("Open"))
		.. ", Deferred " .. tostring(wg:GetAttribute("Deferred")) .. "; want day1_speakers open (now = true)" .. RED)
	assert(wg:GetAttribute("Deferred") == false, "card 2 is Deferred " .. tostring(wg:GetAttribute("Deferred")) .. " over the beat maker, want false (now = true)" .. RED)
	local c = looks("1 card 2", "day1_speakers", 2)
	table.insert(out, "1 the beat maker open; card 2 shown over it: day1_speakers, " .. D.Header .. " / " .. D.Skip .. ", 2 choices, no face")
	task.wait(0.3)

	-- 2. three phone sizes, the beat maker compact under the card
	local d = cam.ViewportSize - wg.AbsoluteSize
	local inset = Vector2.new(math.max(0, d.X), math.max(0, d.Y))
	local function overCompact(label, id)
		for _, screen in ipairs(SCREENS) do
			daw:SetAttribute("CompactForced", true)
			daw:SetAttribute("ViewportOverride", screen)
			local vp = screen - inset
			wg:SetAttribute("ForceViewport", vp)
			local where = string.format("%s %dx%d (OK_WalkIn %dx%d)", label, screen.X, screen.Y, vp.X, vp.Y)
			assert(waitFor(function() return daw:GetAttribute("Compact") == true end, 3), where .. ": the beat maker's Compact is " .. tostring(daw:GetAttribute("Compact"))
				.. " with CompactForced and ViewportOverride set, want true")
			task.wait(0.5) -- WalkInUI re-checks the deferral every 0.2 s
			assert(daw.Visible, where .. ": the beat maker closed")
			assert(wg:GetAttribute("Open") == true and wg:GetAttribute("Deferred") == false and wg:GetAttribute("Card") == id,
				where .. ": " .. id .. " isn't shown over the compact beat maker (Open " .. tostring(wg:GetAttribute("Open")) .. ", Deferred "
				.. tostring(wg:GetAttribute("Deferred")) .. ", Card " .. tostring(wg:GetAttribute("Card")) .. ")" .. RED)
			local chip = wg:FindFirstChild("Waiting", true)
			assert(chip and not chip.Visible, where .. ": the Waiting chip shows over the compact beat maker")
			local n = buttons(where, vp, 3)
			local line = lineShown(where, c)
			table.insert(out, string.format("%s: the beat maker compact; the card open over it, no chip; %d buttons >= 44 px, inside, none overlapping; card %s%s",
				where, n, fmt(rel(c)), id == "day1_spend" and ("; the line kept: " .. line.Text) or ""))
		end
	end
	overCompact("2 card 2", "day1_speakers")
	unforce()
	task.wait(0.4)

	-- 3. Keep it private; card 3 from the server's loop, shown over the still-open beat maker (now = true, fix 1)
	choose("3 card 2", 2)
	local wait3 = (Config.DayOne and Config.DayOne.AfterSpeakers or 4) + 3
	assert(waitFor(function() return wg:GetAttribute("Card") == "day1_spend" end, wait3), "card 3 (day1_spend) didn't arrive within " .. wait3
		.. " s of card 2's choice: Card '" .. tostring(wg:GetAttribute("Card")) .. "'")
	assert(daw.Visible, "the beat maker closed before card 3 came")
	assert(waitFor(function() return wg:GetAttribute("Open") == true end, 2) and wg:GetAttribute("Deferred") == false,
		"card 3 is Open " .. tostring(wg:GetAttribute("Open")) .. ", Deferred " .. tostring(wg:GetAttribute("Deferred"))
		.. " over the open beat maker, want shown (now = true since D1-T4 fix 1: sync Data/DayOne)")
	c = looks("3 card 3", "day1_spend", 2)
	table.insert(out, "3 card 3 (day1_spend) shown over the open beat maker: " .. D.Header .. " / " .. D.Skip .. ", 2 choices, no face")
	task.wait(0.3)

	-- 4. card 3 at the three phone sizes over the compact beat maker (the loop leaves it compact at 844x390)
	overCompact("4 card 3", "day1_spend")
	wg:SetAttribute("ForceViewport", nil)
	task.wait(0.3)

	-- 5. Hit the gear rack over the open beat maker: it closes, and the Gear tab opens on top; the tour is done
	assert(daw.Visible and daw:GetAttribute("Compact") == true, "5: the compact beat maker isn't open before the rack choice")
	choose("5 card 3", 1)
	assert(waitFor(function() return not daw.Visible end, 3), "5: the beat maker is still open after Hit the gear rack. (a Gear OpenPanel closes it: DAWClient, D1-T4 fix 1)")
	local function gearRows()
		local n = 0
		for _, x in ipairs(panel.Content:GetChildren()) do if x.Name:sub(1, 5) == "Gear_" then n += 1 end end
		return n
	end
	assert(waitFor(function() return panel.Visible and gearRows() > 0 end, 3), "5: the Gear tab didn't open (Panel visible " .. tostring(panel.Visible) .. ", "
		.. gearRows() .. " Gear_ rows): the RackSpot out of PanelCloseDistance from t123c's stand spot gives the toast rackFar instead")
	task.wait(0.3)
	local pr = { x0 = panel.AbsolutePosition.X, y0 = panel.AbsolutePosition.Y, x1 = panel.AbsolutePosition.X + panel.AbsoluteSize.X, y1 = panel.AbsolutePosition.Y + panel.AbsoluteSize.Y }
	local over = {}
	for _, gname in ipairs({ "OK_DAW", "OK_WalkIn" }) do
		local g = pg:FindFirstChild(gname)
		if g and g.Enabled then
			for _, x in ipairs(g:GetDescendants()) do
				if x:IsA("GuiObject") and x.BackgroundTransparency < 1 and shownIn(x, g) then
					local ap, as = x.AbsolutePosition, x.AbsoluteSize
					local r = { x0 = ap.X, y0 = ap.Y, x1 = ap.X + as.X, y1 = ap.Y + as.Y }
					if not empty(r) and overlaps(r, pr) then table.insert(over, gname .. "." .. x.Name .. " " .. fmt(r)) end
				end
			end
		end
	end
	assert(#over == 0, "5: the Gear tab " .. fmt(pr) .. " is covered by " .. table.concat(over, ", ", 1, math.min(#over, 5)) .. (#over > 5 and " …" or ""))
	assert(wg:GetAttribute("Open") == false, "5: the walk-in card is open over the Gear tab")
	table.insert(out, string.format("5 Hit the gear rack.: ok; the beat maker closed; the Gear tab open on top (%d Gear_ rows, panel %s, nothing of OK_DAW or OK_WalkIn over it)",
		gearRows(), fmt(pr)))
	assert(waitFor(function() return ui:GetAttribute("TourVisible") == false end, 4), "TourVisible is " .. tostring(ui:GetAttribute("TourVisible"))
		.. " after card 3's rack, want false (the tour done)")
	assert(not tour.Visible and not hl.Enabled and hl.Adornee == nil, "the pill (" .. tostring(tour.Visible) .. ") or the outline (" .. tostring(hl.Enabled)
		.. ") is left on after the tour")
	assert(ui:GetAttribute("TourTarget") == "" and ui:GetAttribute("TourPulse") == false, "TourTarget '" .. tostring(ui:GetAttribute("TourTarget"))
		.. "', TourPulse " .. tostring(ui:GetAttribute("TourPulse")) .. " after the tour, want '' and false")
	table.insert(out, "5 the tour done: the pill and the outline off")
	return table.concat(out, "\n")
end

local ok, msg = pcall(run)
pcall(unforce)
pcall(function() panel.Visible = false end)
pcall(function() if daw.Visible then daw:SetAttribute("Command", "close") end end)
pcall(function() cam.CameraType = Enum.CameraType.Custom end)
if not ok then error(msg, 0) end
return string.format("T123D PLAY OK (%.1f s)\n", os.clock() - T0) .. msg
