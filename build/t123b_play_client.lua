-- Client, during play (the Day One plan, Task 4: Day One on screen), after t123a left card 1 (JUNO VALE's request) open
-- with the tour reset and the player in their bedroom. The file's own fresh(): no forced size on OK_WalkIn or the beat
-- maker, the beat maker closed (card 1 isn't shown over it), the camera given back.
-- (1) The card opens by itself through Systems/DayOne's own remote: OK_WalkIn Open and not Deferred, Card day1_dayone,
--     the header reads Data/DayOne's Header (DAY ONE), the bottom button its Skip (SKIP), 3 choices; the portrait holds
--     a face (visitor.id juno). The DAY ONE pill's frame (OK_UI.Tour) is hidden under the card while TourVisible stays
--     true (a step to show; preflight m15).
-- (2) Forced (ForceViewport on OK_WalkIn) to 667x375, 771x390 and 844x390 less this gui's real insets (as t47b: OK_WalkIn
--     is CoreUISafeInsets): every GuiButton on screen in OK_WalkIn (itself and its ancestors visible; its rect clipped to
--     the card's Scroll) shows 44 px or more both ways, inside (0, 0)-vp, and overlaps no other; at least the 3 choices and
--     SKIP are among them; the line is shown and carries JUNO's pay (a Day One card keeps its line on a short phone); the
--     pill's frame stays hidden.
-- (3) Command "choose:3" (Look around first): LastChoose "ok" and the card closes. The pill comes back: TourVisible
--     true, its Head reads "DAY ONE" and "1/5", its Step is Data/DayOne's room line for open ({artist} filled), TourStep
--     open, and the outline is on the bedroom's laptop (OK_Plots.Plot_<PlotSlot>.Room_bedroom's Kind "Station" part
--     tagged OK_Interactable, as RoomBuild.StationOf names it): TourTarget its full name, the Highlight on it, and
--     TourPulse true.
-- On any error, and after success: the forced sizes off, the camera given back; then the error is rethrown. Card 1's
-- chain (look around: it would come back in 30 s) is t123c's to reset.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local CS = game:GetService("CollectionService")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui", 10)
local wg = pg:WaitForChild("OK_WalkIn", 10); assert(wg, "no OK_WalkIn gui (WalkInUI.Build did not run?)")
local ui = pg:WaitForChild("OK_UI", 10); assert(ui, "no OK_UI")
local tour = ui:WaitForChild("Tour", 5); assert(tour, "no OK_UI.Tour (TourUI.Build did not run?)")
local hl = ui:WaitForChild("OK_TourHighlight", 5); assert(hl, "no OK_UI.OK_TourHighlight")
local dawGui = pg:WaitForChild("OK_DAW", 10)
local daw = dawGui and dawGui:WaitForChild("DAW", 10); assert(daw, "no beat maker gui (PlayerGui.OK_DAW.DAW)")
local D = require(RS.OK.Data.DayOne)
local Rules = require(RS.OK.Modules.DayOneRules)
local Artists = require(RS.OK.Data.Artists)
local Format = require(RS.OK.Modules.Format)
local RED = " (before the D1-T4 sync of Modules/WalkInUI, Modules/TourUI and Systems/Tour: the expected red)"
local SCREENS = { Vector2.new(667, 375), Vector2.new(771, 390), Vector2.new(844, 390) }
local STARTER = Rules.Starter(Artists.Briefs)
local JUNO = STARTER and Artists.ArtistById[STARTER.artist]
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

local function fresh()
	wg:SetAttribute("ForceViewport", nil)
	daw:SetAttribute("CompactForced", nil); daw:SetAttribute("ViewportOverride", nil)
	if daw.Visible then daw:SetAttribute("Command", "close"); waitFor(function() return not daw.Visible end, 3) end
	cam.CameraType = Enum.CameraType.Custom
end

local function run()
	assert(STARTER and JUNO, "Data/Artists has no single starter brief with an artist")
	fresh()
	-- 1. card 1 opens by itself
	assert(waitFor(function() return wg:GetAttribute("Open") == true and wg:GetAttribute("Card") == "day1_dayone" end, 10),
		"no Day One card opened within 10 s: Card '" .. tostring(wg:GetAttribute("Card")) .. "', Open " .. tostring(wg:GetAttribute("Open"))
		.. ", Deferred " .. tostring(wg:GetAttribute("Deferred")) .. "; want day1_dayone open (t123a's Start sent it)" .. RED)
	assert(wg:GetAttribute("Deferred") == false, "card 1 is Deferred " .. tostring(wg:GetAttribute("Deferred")) .. " with the beat maker closed, want false")
	local c = card()
	assert(c and c.Visible, "Card frame missing or hidden while Open")
	local header, walk = c:FindFirstChild("Header"), c:FindFirstChild("WalkAway")
	assert(header and header.Text == D.Header, "the header reads '" .. tostring(header and header.Text) .. "', want '" .. D.Header .. "' (the payload's header)")
	assert(walk and walk.Text == D.Skip, "the bottom button reads '" .. tostring(walk and walk.Text) .. "', want '" .. D.Skip .. "' (the payload's walk)")
	assert(wg:GetAttribute("Choices") == 3, "Choices is " .. tostring(wg:GetAttribute("Choices")) .. ", want 3")
	local portrait = c:FindFirstChild("Portrait")
	assert(portrait and portrait:FindFirstChild("View"), "card 1's portrait holds no View (visitor.id juno: a generic figure in her colour)")
	assert(waitFor(function() return ui:GetAttribute("TourVisible") == true end, 3), "TourVisible is " .. tostring(ui:GetAttribute("TourVisible"))
		.. " with the tour reset, want true (a step to show)")
	assert(not tour.Visible, "the DAY ONE pill's frame (OK_UI.Tour) shows under the open card, want it hidden")
	table.insert(out, string.format("1 card 1 open: %s, %s / %s, 3 choices, a face; the pill hidden under it (TourVisible true)", wg:GetAttribute("Card"), header.Text, walk.Text))
	task.wait(0.3) -- the labels were filled while the card was hidden: let it render once so the rects are current

	-- 2. three phone sizes
	local pay = Format.Money(STARTER.reward.cred)
	local d = cam.ViewportSize - wg.AbsoluteSize
	local inset = Vector2.new(math.max(0, d.X), math.max(0, d.Y))
	for _, screen in ipairs(SCREENS) do
		local vp = screen - inset
		wg:SetAttribute("ForceViewport", vp)
		task.wait(0.4)
		local where = string.format("%dx%d (%dx%d less %dx%d)", vp.X, vp.Y, screen.X, screen.Y, inset.X, inset.Y)
		assert(wg:GetAttribute("Open") == true and wg:GetAttribute("Deferred") == false and wg:GetAttribute("Card") == "day1_dayone",
			where .. ": card 1 is not open (Open " .. tostring(wg:GetAttribute("Open")) .. ", Deferred " .. tostring(wg:GetAttribute("Deferred")) .. ")")
		local n = buttons(where, vp, 4)
		local line = c:FindFirstChild("Line", true)
		assert(line and line.Visible and line.Text:find(pay, 1, true), where .. ": the line is " .. (line and (line.Visible and ("'" .. line.Text .. "'") or "hidden") or "missing")
			.. ", want it shown with JUNO's pay " .. pay .. " (a Day One card keeps its line on a short phone)")
		assert(not tour.Visible, where .. ": the DAY ONE pill's frame shows under the open card")
		table.insert(out, string.format("2 %s: %d buttons >= 44 px, inside, none overlapping; the line kept (%s); card %s", where, n, pay, fmt(rel(c))))
	end
	wg:SetAttribute("ForceViewport", nil)
	task.wait(0.3)

	-- 3. Look around first: the card closes and the pill comes back on the bedroom's laptop
	wg:SetAttribute("LastChoose", "")
	wg:SetAttribute("Command", "choose:3")
	assert(waitFor(function() return wg:GetAttribute("LastChoose") ~= "" end, 5), "choose:3 got no answer within 5 s (LastChoose empty)")
	assert(wg:GetAttribute("LastChoose") == "ok", "choose:3 answered '" .. tostring(wg:GetAttribute("LastChoose")) .. "', want ok (DayOne_Choose)")
	assert(waitFor(function() return wg:GetAttribute("Open") == false end, 3), "card 1 is still open after choose:3")
	assert(waitFor(function() return ui:GetAttribute("TourVisible") == true and tour.Visible end, 3), "the pill did not come back after the card closed (TourVisible "
		.. tostring(ui:GetAttribute("TourVisible")) .. ", frame " .. tostring(tour.Visible) .. ")")
	local headText = tour.Head.Text
	assert(headText:find(D.Header, 1, true) and headText:find("1/5", 1, true), "the pill's Head reads '" .. headText .. "', want '" .. D.Header .. "' and '1/5'" .. RED)
	assert(ui:GetAttribute("TourStep") == "open", "TourStep is '" .. tostring(ui:GetAttribute("TourStep")) .. "', want open")
	local roomLine = Rules.Fill(D.Steps.open.room, { artist = JUNO.name })
	assert(tour.Step.Text == roomLine, "the pill's Step reads '" .. tour.Step.Text .. "', want the room line '" .. roomLine .. "' (in your own plot)" .. RED)
	local slot = player:GetAttribute("PlotSlot")
	assert(type(slot) == "number" and slot > 0 and player:GetAttribute("InPlot") == slot, "PlotSlot " .. tostring(slot) .. ", InPlot "
		.. tostring(player:GetAttribute("InPlot")) .. ": not in your own plot (t123a's WakeUp)")
	local station
	assert(waitFor(function()
		local plots = workspace:FindFirstChild("OK_Plots")
		local pm = plots and plots:FindFirstChild(string.format("Plot_%02d", slot))
		local bedroom = pm and pm:FindFirstChild("Room_bedroom")
		station = nil
		for _, x in ipairs(bedroom and bedroom:GetDescendants() or {}) do
			if x:IsA("BasePart") and x:GetAttribute("Kind") == "Station" and CS:HasTag(x, "OK_Interactable") then station = x; break end
		end
		return station ~= nil
	end, 5), string.format("Plot_%02d.Room_bedroom has no Kind 'Station' part tagged OK_Interactable on this client", slot))
	assert(waitFor(function() return ui:GetAttribute("TourTarget") == station:GetFullName() end, 3), "TourTarget is '" .. tostring(ui:GetAttribute("TourTarget"))
		.. "', want the bedroom's laptop '" .. station:GetFullName() .. "'" .. RED)
	assert(hl.Adornee == station and hl.Enabled, "the outline is on " .. tostring(hl.Adornee) .. " (Enabled " .. tostring(hl.Enabled) .. "), want the bedroom's laptop")
	assert(ui:GetAttribute("TourPulse") == true, "TourPulse is " .. tostring(ui:GetAttribute("TourPulse")) .. " on the open step in your plot, want true")
	table.insert(out, string.format("3 choose:3 ok, the card closed; the pill: '%s', '%s', the outline pulsing on %s", headText, tour.Step.Text, station:GetFullName()))
	return table.concat(out, "\n")
end

local ok, msg = pcall(run)
pcall(function() wg:SetAttribute("ForceViewport", nil) end)
pcall(function() daw:SetAttribute("CompactForced", nil); daw:SetAttribute("ViewportOverride", nil) end)
pcall(function() cam.CameraType = Enum.CameraType.Custom end)
if not ok then error(msg, 0) end
return string.format("T123B PLAY OK (%.1f s)\n", os.clock() - T0) .. msg
