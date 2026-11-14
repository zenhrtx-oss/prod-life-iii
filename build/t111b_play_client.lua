-- Client, during play (the Your Rooms plan, Task 12; preflight F3: the home studio's side), after t111a's tail: home
-- owned, a closet placed in it, fit_cuban and fit_shades owned (none worn), the player at the home stand spot (room-local
-- (3, 0, -6.6), t111a's) and request j1 active. Every step waits for its state, with a timeout (the locked-screen ruling).
-- (1) Room_home (Workspace.OK_Plots.Plot_<PlotSlot>) is on this client (awaited at most 5 s) with its laptop, its
--     BoothSpot and BoothCam Attachments, and in its Items the closet with two hangers and its enabled ClosetPrompt.
-- (2) Anything t111a left open (the beat maker, the panel) is closed first.
-- (3) 2.6 studs in front of the closet (its front: the model's LookVector; out of reach of the laptop's and the door's E
--     prompts), pressing the ClosetPrompt (InputHoldBegin / End, as t105b) opens the panel: the OpenPanel payload has tab
--     Gear, closet true and the closet's Body as its source; Content's ClosetHeader reads "YOUR CLOSET" (copy 8.3) and its
--     rows are exactly Gear_<id> for the fits this player owns (Config.Gear kind "fit" in the Gear attribute: fit_cuban,
--     fit_shades), each with an Action button "EQUIP" (Fits empty); the footer reads "Closet · Backspace / B to close"
--     (copy 8.5); there is no money line and no other Gear_ row.
--     R-T16 fix, M1: the press is a double press, two InputHoldBegin / End pairs with nothing yielding between them (well
--     inside 0.1 s), and the closet opens ONCE: one OpenPanel { closet } reaches this client. The count is read after (4)'s
--     first EQUIP reply is back: the server answers in order, so a second OpenPanel would have come before that reply.
--     The expected red, before the sync of Systems/Rooms: 2 OpenPanels.
-- (4) EQUIP toggles Fits: fit_cuban's button pressed (its Command "press", the path a click takes): OK_UI's LastGear "ok",
--     Fits holds fit_cuban and the re-rendered row reads "EQUIPPED", still in closet mode (the same two rows); pressed
--     again: Fits no longer holds it and the row reads "EQUIP".
-- (5) OK_UI forced (ForceViewport) to 667x375, 771x390 and 844x390 minus this gui's insets: the panel fits the box; Close
--     is 44 px or more and inside the panel; Content is inside the panel; every closet row's Action button is 44 px or
--     more and inside Content's width.
-- (5b) The empty closet (copy 8.4; the R-T12 review's M1): OK_UI's PanelCommand "closet:empty" (ClientMain's Studio seam: the
--     Gear tab with a closet payload and no fit owned, as Gear.State sends it for a player with none) opens the closet panel
--     with ClosetHeader "YOUR CLOSET" (8.3), ClosetEmpty reading "Nothing in here yet. Buy a fit at the gear rack and it
--     hangs here." (8.4), no Gear_ row, no money line, and the footer 8.5. Closed again.
-- (6) A delivery from the home studio: back at the home stand spot (within reach of the laptop, checked), with the camera
--     Custom, the laptop's prompt opens the beat maker; the OpenDAW payload's room is "home" and its booth { spot, cam }
--     is this client's BoothSpot / BoothCam (within 0.05 stud). The card's Active is j1; BOUNCE loaded (Command
--     "preset:BOUNCE") and made yours with t124b's 8 pads (3 stars on j1); Command "deliver": LastDeliver "ok", Cutaway
--     true within 3 s, the camera Scriptable at BoothCam's position (within 0.1) and OK_DAW off; OK_BoothArtist under the
--     camera, InRoom true, its Torso within 0.6 stud (flat) of BoothSpot and facing the camera's side. Then (within 8 s)
--     Cutaway false, the camera back to Custom, OK_DAW on and the result screen (Overlay "result").
-- On any error, and after success: the force off, the panel and the beat maker closed, the camera given back (Custom),
-- the listener disconnected; on an error the character goes to the lounge; then the error is rethrown. Fits are put back
-- by t111e's ProfileRestore either way.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character
local root = char and char:WaitForChild("HumanoidRootPart", 5)
local hum = char and char:WaitForChild("Humanoid", 5)
assert(root and hum, "no live character")
local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui", 10)
local ui = pg and pg:WaitForChild("OK_UI", 10); assert(ui, "no OK_UI")
local panel = ui:WaitForChild("Panel", 5); assert(panel, "no Panel")
local dawGui = pg:WaitForChild("OK_DAW", 10)
local daw = dawGui and dawGui:WaitForChild("DAW", 10); assert(daw, "no beat maker gui (PlayerGui.OK_DAW.DAW)")
local req = daw:WaitForChild("Request", 5); assert(req, "no Request card in the beat maker (RequestUI)")
local Config = require(RS.OK.Config)
local DAWCfg = require(RS.OK.Modules.DAWConfig)
local Remotes = RS.OK.Remotes
local LOUNGE = Vector3.new(24, 3, 0)
local HOME_STAND = Vector3.new(3, 0, -6.6) -- room-local (t111a's)
local HEADER, FOOTER = "YOUR CLOSET", "Closet · Backspace / B to close" -- copy 8.3, 8.5
local EMPTY = "Nothing in here yet. Buy a fit at the gear rack and it hangs here." -- copy 8.4
local RED = " (before the R-T12 sync of Modules/PanelUI, Modules/BoothArtist, Systems/Rooms, Systems/DAW and OK/DAWClient, and the R-T12/13 review fixes' sync of OK/ClientMain (the PanelCommand 'closet:empty'): the expected red)"
local BOUNCE
for _, pr in ipairs(DAWCfg.Presets) do if pr.name == "BOUNCE" then BOUNCE = pr end end
local out = {}
local events = {} -- every InteractionEvent this client got: { kind, payload, t }
local conn = Remotes.InteractionEvent.OnClientEvent:Connect(function(kind, payload) table.insert(events, { kind = kind, payload = payload, t = os.clock() }) end)

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function str(v) return string.format("(%.2f, %.2f, %.2f)", v.X, v.Y, v.Z) end
local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function inside(g, box)
	local a, b = g.AbsolutePosition, box.AbsolutePosition
	return a.X >= b.X - 0.5 and a.Y >= b.Y - 0.5 and a.X + g.AbsoluteSize.X <= b.X + box.AbsoluteSize.X + 0.5 and a.Y + g.AbsoluteSize.Y <= b.Y + box.AbsoluteSize.Y + 0.5
end
local function eventSince(kind, since)
	for i = #events, 1, -1 do
		local e = events[i]
		if e.kind == kind and e.t >= since then return e end
	end
	return nil
end
local function gearRows()
	local rows = {}
	for _, c in ipairs(panel.Content:GetChildren()) do if c.Name:sub(1, 5) == "Gear_" then table.insert(rows, c) end end
	table.sort(rows, function(a, b) return a.Name < b.Name end)
	return rows
end
local function rowNames() local n = {}; for _, r in ipairs(gearRows()) do table.insert(n, r.Name) end; return table.concat(n, ",") end
local function actionOf(id)
	local row = panel.Content:FindFirstChild("Gear_" .. id)
	local b = row and row:FindFirstChild("Action")
	return (b and b:IsA("TextButton")) and b or nil
end
local function has(list, id) return string.find("," .. (list or "") .. ",", "," .. id .. ",", 1, true) ~= nil end
local function closeAll()
	if daw.Visible then daw:SetAttribute("Command", "close") end
	assert(waitFor(function() return not daw.Visible end, 3), "the beat maker would not close (its Command 'close')")
	panel.Visible = false
end
local function press(pp, done, each)
	for _ = 1, 4 do
		pp:InputHoldBegin(); task.wait(0.05); pp:InputHoldEnd()
		if waitFor(done, each or 1.5) then return true end
	end
	return false
end
local function cmd(c) req:SetAttribute("Command", c); task.wait(0.15) end
local function standAt(pos, lookAt)
	if hum.Sit then hum.Sit = false; task.wait(0.4) end
	root.CFrame = CFrame.lookAt(pos, Vector3.new(lookAt.X, pos.Y, lookAt.Z))
	assert(waitFor(function() return flat(root.Position - pos) < 1.5 end, 2), "the character did not stay at " .. str(pos) .. " (at " .. str(root.Position) .. ")")
end

local function run()
	assert(BOUNCE, "DAWConfig.Presets has no BOUNCE")
	-- 1. the home studio and its closet on this client
	local slot = player:GetAttribute("PlotSlot")
	assert(waitFor(function() slot = player:GetAttribute("PlotSlot"); return type(slot) == "number" and slot > 0 end, 3), "PlotSlot is " .. tostring(slot) .. ", want the player's slot")
	local plots = workspace:WaitForChild("OK_Plots", 5); assert(plots, "Workspace.OK_Plots is not on this client")
	local name = string.format("Plot_%02d", slot)
	local home, station, closet, cp, spotA, camA
	local got = waitFor(function()
		local pm = plots:FindFirstChild(name)
		home = pm and pm:FindFirstChild("Room_home")
		if not home then return false end
		station, closet = nil, nil
		for _, d in ipairs(home:GetDescendants()) do
			if d:IsA("BasePart") and d:GetAttribute("Kind") == "Station" then station = d end
		end
		local items = home:FindFirstChild("Items")
		for _, m in ipairs(items and items:GetChildren() or {}) do if m:IsA("Model") and m:GetAttribute("ItemId") == "closet" then closet = m end end
		local body = closet and closet:FindFirstChild("Body")
		cp = body and body:FindFirstChild("ClosetPrompt")
		local hf = closet and closet:FindFirstChild("Hangers")
		spotA, camA = home:FindFirstChild("BoothSpot", true), home:FindFirstChild("BoothCam", true)
		return station ~= nil and cp ~= nil and hf ~= nil and #hf:GetChildren() == 2 and spotA ~= nil and camA ~= nil
	end, 5)
	assert(got, name .. ".Room_home with its laptop, BoothSpot / BoothCam and a closet with 2 hangers and its ClosetPrompt is not on this client 5 s in (station "
		.. tostring(station) .. ", closet " .. tostring(closet) .. ", prompt " .. tostring(cp) .. ")" .. RED)
	assert(cp:IsA("ProximityPrompt") and cp.Enabled, "the ClosetPrompt is off")
	assert(home:GetAttribute("OwnerId") == player.UserId, "Room_home's OwnerId is " .. tostring(home:GetAttribute("OwnerId")) .. ", want this player's")
	local fits = {}
	for _, it in ipairs(Config.Gear) do if it.kind == "fit" and has(player:GetAttribute("Gear"), it.id) then table.insert(fits, "Gear_" .. it.id) end end
	table.sort(fits)
	assert(table.concat(fits, ",") == "Gear_fit_cuban,Gear_fit_shades", "the fits owned (the Gear attribute) are " .. table.concat(fits, ",") .. ", want fit_cuban and fit_shades (t111a's tail)")
	assert((player:GetAttribute("Fits") or "") == "", "Fits is '" .. tostring(player:GetAttribute("Fits")) .. "' at the start, want none worn")
	table.insert(out, string.format("1 %s.Room_home on this client: its laptop, BoothSpot, BoothCam and the closet (2 hangers, ClosetPrompt on)", name))

	-- 2. what t111a's handlers opened is closed first
	closeAll()
	table.insert(out, "2 the beat maker and the panel closed")

	-- 3. the closet opens the closet panel
	local cpv = closet:GetPivot()
	local front = Vector3.new(cpv.LookVector.X, 0, cpv.LookVector.Z).Unit
	local cstand = cpv.Position + front * 2.6 + Vector3.new(0, 3, 0)
	local body = closet.Body
	assert((cstand - body.Position).Magnitude < cp.MaxActivationDistance - 1, string.format("the closet's stand spot is %.1f studs from its Body, past the prompt's reach", (cstand - body.Position).Magnitude))
	assert((cstand - station.Position).Magnitude > 9, string.format("the closet's stand spot is %.1f studs from the laptop: its E prompt would be in reach too", (cstand - station.Position).Magnitude))
	standAt(cstand, body.Position)
	cam.CameraType = Enum.CameraType.Custom
	task.wait(0.5)
	-- R-T16 fix, M1: a double press (nothing yields between the two), retried whole until an OpenPanel { closet } comes back
	local function closetOpens(since)
		local n = 0
		for _, e in ipairs(events) do
			if e.kind == "OpenPanel" and e.t >= since and type(e.payload) == "table" and e.payload.closet == true then n += 1 end
		end
		return n
	end
	local t3 = os.clock()
	local gap, sent = math.huge, false
	for _ = 1, 4 do
		local a = os.clock()
		cp:InputHoldBegin(); cp:InputHoldEnd()
		cp:InputHoldBegin(); cp:InputHoldEnd()
		gap = os.clock() - a
		if waitFor(function() return closetOpens(a) >= 1 end, 3) then sent = true; break end
	end
	assert(sent, "the ClosetPrompt's double press brought no OpenPanel { closet }" .. RED)
	assert(gap < 0.1, string.format("premise: the double press took %.3f s, want both presses inside 0.1 s", gap))
	assert(waitFor(function() return panel.Visible and panel.Content:FindFirstChild("ClosetHeader") ~= nil end, 3), "pressing the ClosetPrompt did not open the closet panel (visible "
		.. tostring(panel.Visible) .. ", rows " .. rowNames() .. ")" .. RED)
	local op = eventSince("OpenPanel", t3)
	local pay = op and type(op.payload) == "table" and op.payload or {}
	assert(pay.tab == "Gear" and pay.closet == true and pay.source == body:GetFullName(), "the OpenPanel payload is tab " .. tostring(pay.tab) .. ", closet "
		.. tostring(pay.closet) .. ", source " .. tostring(pay.source) .. "; want Gear, true, " .. body:GetFullName())
	local head = panel.Content.ClosetHeader
	assert(head:IsA("TextLabel") and head.Text == HEADER, "the closet header reads '" .. tostring(head.Text) .. "', want '" .. HEADER .. "'")
	assert(rowNames() == table.concat(fits, ","), "the closet lists " .. rowNames() .. ", want exactly the owned fits " .. table.concat(fits, ","))
	for _, id in ipairs({ "fit_cuban", "fit_shades" }) do
		local b = actionOf(id)
		assert(b and b.Text == "EQUIP" and b:GetAttribute("Action") == "equip", "Gear_" .. id .. "'s button is " .. tostring(b and b.Text) .. ", want EQUIP")
	end
	local footer = panel:FindFirstChild("Footer")
	assert(footer and footer.Text == FOOTER, "the footer reads '" .. tostring(footer and footer.Text) .. "', want '" .. FOOTER .. "'")
	for _, c in ipairs(panel.Content:GetChildren()) do
		if c:IsA("TextLabel") then assert(not string.find(c.Text, "You have", 1, true), "the closet shows the rack's money line: " .. c.Text) end
	end
	table.insert(out, "3 the ClosetPrompt opens the closet: OpenPanel { Gear, closet, the Body }; 'YOUR CLOSET'; rows " .. rowNames() .. ", each EQUIP; footer '" .. FOOTER .. "'")

	-- 4. EQUIP toggles Fits (the button's press, as a click sets it)
	for round, want in ipairs({ true, false }) do
		ui:SetAttribute("LastGear", "")
		local b = actionOf("fit_cuban")
		assert(b, "round " .. round .. ": no Gear_fit_cuban button")
		b:SetAttribute("Command", "press")
		assert(waitFor(function() return ui:GetAttribute("LastGear") == "ok" end, 4), "round " .. round .. ": EQUIP got LastGear '" .. tostring(ui:GetAttribute("LastGear")) .. "', want ok" .. RED)
		assert(waitFor(function() return has(player:GetAttribute("Fits"), "fit_cuban") == want end, 3), "round " .. round .. ": Fits is '" .. tostring(player:GetAttribute("Fits"))
			.. "', want fit_cuban " .. (want and "in it" or "out of it"))
		local text = want and "EQUIPPED" or "EQUIP"
		assert(waitFor(function() local nb = actionOf("fit_cuban"); return nb ~= nil and nb.Text == text end, 3), "round " .. round .. ": the row reads '"
			.. tostring(actionOf("fit_cuban") and actionOf("fit_cuban").Text) .. "', want " .. text)
		assert(panel.Content:FindFirstChild("ClosetHeader") and rowNames() == table.concat(fits, ","), "round " .. round .. ": after the equip the panel lists " .. rowNames() .. ", want the closet's two rows")
		if round == 1 then -- R-T16 fix, M1: the equip's reply is back, so every OpenPanel the double press caused has come
			local n = closetOpens(t3)
			assert(n == 1, "3: the ClosetPrompt's two presses " .. string.format("%.3f", gap) .. " s apart opened the closet " .. n .. " times (OpenPanel { closet }), want once: the per-prompt debounce (0.25 s; before the R-T16 fix sync of Systems/Rooms: 2, the expected red)")
		end
		task.wait(0.3) -- the equip bucket (Systems/Gear) refills a token
	end
	table.insert(out, "4 EQUIP on fit_cuban: Fits holds it and the row reads EQUIPPED; again: off, EQUIP; still the closet's two rows; the double press (" .. string.format("%.3f", gap) .. " s apart) opened the closet once")

	-- 5. the phone sizes
	local inset = cam.ViewportSize - ui.AbsoluteSize
	inset = Vector2.new(math.max(0, inset.X), math.max(0, inset.Y))
	for _, screen in ipairs({ Vector2.new(667, 375), Vector2.new(771, 390), Vector2.new(844, 390) }) do
		local vp = screen - inset
		local where = vp.X .. "x" .. vp.Y .. " (" .. screen.X .. "x" .. screen.Y .. " less " .. inset.X .. "x" .. inset.Y .. ")"
		ui:SetAttribute("ForceViewport", vp)
		waitFor(function() return panel.AbsoluteSize.X <= vp.X + 0.5 and panel.AbsoluteSize.Y <= vp.Y + 0.5 end, 2)
		task.wait(0.2) -- one layout pass
		local size = panel.AbsoluteSize
		assert(size.X <= vp.X + 0.5 and size.Y <= vp.Y + 0.5, where .. ": the panel is " .. size.X .. "x" .. size.Y .. ", past the box")
		local close = panel:FindFirstChild("Close")
		assert(close and close.Visible and close.AbsoluteSize.X >= 44 and close.AbsoluteSize.Y >= 44 and inside(close, panel), where .. ": Close is missing, under 44 px or outside the panel")
		local content = panel.Content
		assert(inside(content, panel), where .. ": Content sticks out of the panel")
		local rows = gearRows()
		assert(#rows == 2, where .. ": the closet lists " .. #rows .. " rows, want 2")
		for _, row in ipairs(rows) do
			local b = row:FindFirstChild("Action")
			assert(b and b.AbsoluteSize.X >= 44 and b.AbsoluteSize.Y >= 44, where .. ": " .. row.Name .. "'s button is missing or under 44 px")
			local x0, c0 = b.AbsolutePosition.X, content.AbsolutePosition.X
			assert(x0 >= c0 - 0.5 and x0 + b.AbsoluteSize.X <= c0 + content.AbsoluteSize.X + 0.5, where .. ": " .. row.Name .. "'s button sticks out of Content's width")
		end
		table.insert(out, string.format("5 %s: panel %dx%d; Close and both EQUIP buttons 44 px+, inside", where, size.X, size.Y))
	end
	ui:SetAttribute("ForceViewport", nil)
	panel.Visible = false

	-- 5b. the empty closet (copy 8.4), through ClientMain's Studio seam
	ui:SetAttribute("PanelCommand", "closet:empty")
	assert(waitFor(function() return ui:GetAttribute("PanelCommand") == "" end, 6), "5b: the PanelCommand 'closet:empty' was not acknowledged within 6 s")
	assert(waitFor(function() return panel.Visible and panel.Content:FindFirstChild("ClosetHeader") ~= nil end, 2), "5b: 'closet:empty' did not open the closet panel (visible "
		.. tostring(panel.Visible) .. ", rows " .. rowNames() .. ")" .. RED)
	assert(panel.Content.ClosetHeader.Text == HEADER, "5b: the empty closet's header reads '" .. panel.Content.ClosetHeader.Text .. "', want '" .. HEADER .. "'")
	local empty = panel.Content:FindFirstChild("ClosetEmpty")
	assert(empty and empty:IsA("TextLabel") and empty.Text == EMPTY, "5b: the empty closet's line reads '" .. tostring(empty and empty.Text) .. "', want '" .. EMPTY .. "' (copy 8.4)")
	assert(rowNames() == "", "5b: the empty closet lists " .. rowNames() .. ", want no Gear_ row")
	for _, c in ipairs(panel.Content:GetChildren()) do
		if c:IsA("TextLabel") then assert(not string.find(c.Text, "You have", 1, true), "5b: the empty closet shows the rack's money line: " .. c.Text) end
	end
	local footer5 = panel:FindFirstChild("Footer")
	assert(footer5 and footer5.Text == FOOTER, "5b: the empty closet's footer reads '" .. tostring(footer5 and footer5.Text) .. "', want '" .. FOOTER .. "'")
	panel.Visible = false
	table.insert(out, "5b the empty closet (PanelCommand closet:empty): 'YOUR CLOSET', ClosetEmpty '" .. EMPTY .. "', no Gear_ row, no money line, footer 8.5")

	-- 6. a delivery from the home studio: the listen-back at home's booth
	local stand = (home:GetPivot() * CFrame.new(HOME_STAND)).Position + Vector3.new(0, 3, 0)
	local sp = station:FindFirstChildWhichIsA("ProximityPrompt")
	assert(sp and sp.Enabled, "the home laptop has no enabled prompt")
	local dd = (stand - station.Position).Magnitude
	assert(dd < sp.MaxActivationDistance - 1 and dd <= DAWCfg.CloseDistance, string.format("the home stand spot is %.1f studs from the laptop, past its prompt's reach or the beat maker's CloseDistance", dd))
	standAt(stand, station.Position)
	cam.CameraType = Enum.CameraType.Custom
	task.wait(0.8)
	local t6 = os.clock()
	assert(press(sp, function() return daw.Visible end, 1.5), "the beat maker did not open from the home laptop's prompt")
	local od = eventSince("OpenDAW", t6)
	local dp = od and type(od.payload) == "table" and od.payload or {}
	local bt = dp.booth
	assert(dp.room == "home", "the OpenDAW payload's room is " .. tostring(dp.room) .. ", want home")
	assert(type(bt) == "table" and typeof(bt.spot) == "CFrame" and typeof(bt.cam) == "CFrame", "the OpenDAW payload's booth is " .. tostring(bt) .. ", want { spot, cam }" .. RED)
	assert((bt.spot.Position - spotA.WorldPosition).Magnitude < 0.05 and (bt.cam.Position - camA.WorldPosition).Magnitude < 0.05, "the payload's booth "
		.. str(bt.spot.Position) .. " / " .. str(bt.cam.Position) .. " is not this client's BoothSpot " .. str(spotA.WorldPosition) .. " / BoothCam " .. str(camA.WorldPosition))
	assert(waitFor(function() return req:GetAttribute("Active") == "j1" end, 5), "the Request card's Active is " .. tostring(req:GetAttribute("Active")) .. ", want j1 (t111a's tail)")
	cmd("preset:BOUNCE")
	assert(waitFor(function() return daw:GetAttribute("Pattern") == BOUNCE.pattern and daw:GetAttribute("BPM") == BOUNCE.bpm end, 3), "preset:BOUNCE did not load BOUNCE")
	local pat = BOUNCE.pattern
	local function set(s, track, step, ch) local i = (track - 1) * DAWCfg.Steps + step; return s:sub(1, i - 1) .. ch .. s:sub(i + 1) end
	for _, s in ipairs({ 3, 7, 11, 15 }) do pat = set(pat, 2, s, "1") end
	for _, s in ipairs({ 2, 10 }) do pat = set(pat, 3, s, "1") end
	for _, s in ipairs({ 8, 16 }) do pat = set(pat, 4, s, "1") end
	daw:SetAttribute("Pattern", pat)
	assert(waitFor(function() return (req:GetAttribute("Changed") or 0) >= 8 and req:GetAttribute("Stars") == 3 end, 3), "the ticks didn't reach 3 stars: changed "
		.. tostring(req:GetAttribute("Changed")) .. ", stars " .. tostring(req:GetAttribute("Stars")))
	local camType = cam.CameraType
	assert(camType == Enum.CameraType.Custom, "the camera is " .. tostring(camType) .. " before the delivery, want Custom (a laptop, unseated)")
	task.wait(2.1) -- Contracts' DeliverCooldown since any earlier delivery
	req:SetAttribute("LastDeliver", "")
	cmd("deliver")
	assert(waitFor(function() return (req:GetAttribute("LastDeliver") or "") ~= "" end, 8), "deliver got no answer within 8 s (LastDeliver empty)")
	assert(req:GetAttribute("LastDeliver") == "ok", "deliver answered '" .. tostring(req:GetAttribute("LastDeliver")) .. "' (" .. tostring(req:GetAttribute("Message")) .. "), want ok")
	assert(waitFor(function() return req:GetAttribute("Cutaway") == true end, 3), "no cutaway after the home delivery (Overlay '" .. tostring(req:GetAttribute("Overlay")) .. "')" .. RED)
	local fig = cam:FindFirstChild("OK_BoothArtist")
	assert(fig and fig:GetAttribute("InRoom") == true, "no OK_BoothArtist (InRoom) under the camera during the home cutaway" .. RED)
	local torso = fig:FindFirstChild("Torso")
	assert(torso, "the booth artist has no Torso")
	local off = flat(torso.Position - spotA.WorldPosition)
	assert(off <= 0.6, string.format("the booth artist stands %.2f studs (flat) from home's BoothSpot %s, want on it", off, str(spotA.WorldPosition)))
	local toCam = Vector3.new(camA.WorldPosition.X - torso.Position.X, 0, camA.WorldPosition.Z - torso.Position.Z).Unit
	assert(torso.CFrame.LookVector:Dot(toCam) > 0.7, "the booth artist faces " .. str(torso.CFrame.LookVector) .. ", want towards BoothCam")
	assert(cam.CameraType == Enum.CameraType.Scriptable and (cam.CFrame.Position - camA.WorldPosition).Magnitude < 0.1, "the cutaway's camera is " .. tostring(cam.CameraType)
		.. " at " .. str(cam.CFrame.Position) .. ", want Scriptable at BoothCam " .. str(camA.WorldPosition))
	assert(dawGui.Enabled == false, "OK_DAW stays on during the cutaway")
	table.insert(out, string.format("6 home delivery: payload room home, booth = this client's BoothSpot / BoothCam; ok; the cutaway: the artist %.2f studs from BoothSpot facing the camera, the camera at BoothCam", off))
	assert(waitFor(function()
		return req:GetAttribute("Cutaway") == false and cam.CameraType == camType and dawGui.Enabled and req:GetAttribute("Overlay") == "result"
	end, 8), "after the cutaway: Cutaway " .. tostring(req:GetAttribute("Cutaway")) .. ", camera " .. tostring(cam.CameraType) .. ", OK_DAW " .. tostring(dawGui.Enabled)
		.. ", Overlay " .. tostring(req:GetAttribute("Overlay")) .. "; want false, Custom, on, result")
	table.insert(out, "6 the camera came back (Custom), OK_DAW on, the result screen shown (" .. tostring(req:GetAttribute("ResultStars")) .. " stars)")
	closeAll()
	return "T111B PLAY OK\n" .. table.concat(out, "\n")
end

local ok, msg = pcall(run)
conn:Disconnect()
pcall(function() ui:SetAttribute("ForceViewport", nil) end)
pcall(function() panel.Visible = false end)
pcall(function() if daw.Visible then daw:SetAttribute("Command", "close") end end)
pcall(function() cam.CameraType = Enum.CameraType.Custom end)
if not ok then
	pcall(function()
		local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if h and h.Sit then h.Sit = false; task.wait(0.4) end
		if r then r.CFrame = CFrame.new(LOUNGE) end
	end)
	error(msg, 0)
end
return msg
