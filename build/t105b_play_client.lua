-- Client, during play (the Your Rooms plan, Task 6; preflight F3: the owner's side), after t105a's tail: the player woke
-- up in their bedroom and request j1 is active. Every step waits for its state, with a timeout. "The stand spot" is
-- room-local (2, 0, -3), t101b's: clear floor beside the chair, in reach of the laptop's prompt and the rack's.
-- (1) The bedroom (Workspace.OK_Plots.Plot_<PlotSlot>.Room_bedroom) with its laptop (Kind "Station") and its RackSpot is on
--     this client (awaited at most 5 s), owned by this player (OwnerId); the rack's prompt is on, reads "Open gear rack" /
--     "Your laptop" (copy §3.2, §3.3) and uses F / ButtonY.
-- (2) Anything t105a's handler runs left open (the beat maker, the panel) is closed first, and checked closed.
-- (3) At the stand spot, pressing the laptop's prompt (InputHoldBegin / End, as t19b and t101b) opens the beat maker, and
--     the OpenDAW payload's room reads "bedroom" (DAW.OpenFor: the room's RoomKind). The beat maker is closed again.
-- (4) A delivery at your own laptop counts like the studio PC: Session_Deliver (DAWConfig.DefaultPattern, 140, 0) with j1
--     active answers "copy" (the station check passed; the default beat is a reference, so nothing is delivered), never
--     "away". Nothing is put ON MONITORS from here (a room play would join the studio's queue until Task 7).
-- (5) OK_UI forced (ForceViewport) to 667x375, 771x390 and 844x390 minus this gui's insets. At each, pressing the rack's
--     prompt opens the panel on the Gear tab (Gear_ rows in Content; the OpenPanel payload has tab Gear and the RackSpot as
--     its source): the panel fits the box; Close and the Gear tab button are 44 px or more and inside the panel; Content is
--     inside the panel and every Gear_ row's Action button is 44 px or more and inside Content's width (the list scrolls).
--     The two tap targets: from this test's camera, scaled to the phone's height, the rack's prompt sits at least a default
--     prompt's height (72 px) off the laptop's (RoomBuild.RACK_UI_GAP through UIOffset, whichever way UIOffset.Y points),
--     and both stay inside the phone's height.
-- On any error, and after success: the force off, the panel and the beat maker closed, the camera given back, the character
-- moved to the lounge; then the error is rethrown.
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
local tabs = panel:WaitForChild("Tabs", 5); assert(tabs, "no Tabs")
local dawGui = pg:WaitForChild("OK_DAW", 10)
local daw = dawGui and dawGui:WaitForChild("DAW", 10)
assert(daw, "no beat maker gui (PlayerGui.OK_DAW.DAW)")
local Config = require(RS.OK.Config)
local DAWCfg = require(RS.OK.Modules.DAWConfig)
local Remotes = RS.OK.Remotes
local LOUNGE = Vector3.new(24, 3, 0)
local PROMPT_H = 72 -- a default ProximityPrompt is 72 px tall
local RED = " (before the R-T6 sync of Modules/RoomBuild and the rest: the expected red)"
local out = {}
local events = {} -- every InteractionEvent this client got: { kind, payload, t }
local conn = Remotes.InteractionEvent.OnClientEvent:Connect(function(kind, payload) table.insert(events, { kind = kind, payload = payload, t = os.clock() }) end)

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function str(v) return string.format("(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z) end
local function inside(g, box)
	local a, b = g.AbsolutePosition, box.AbsolutePosition
	return a.X >= b.X - 0.5 and a.Y >= b.Y - 0.5 and a.X + g.AbsoluteSize.X <= b.X + box.AbsoluteSize.X + 0.5 and a.Y + g.AbsoluteSize.Y <= b.Y + box.AbsoluteSize.Y + 0.5
end
-- the newest event of `kind` that came at or after `since`
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
	return rows
end
local function closeAll()
	if daw.Visible then daw:SetAttribute("Command", "close") end
	assert(waitFor(function() return not daw.Visible end, 3), "the beat maker would not close (its Command 'close')")
	panel.Visible = false
end
-- presses `pp` (InputHoldBegin / End) up to 4 times until done() holds, `each` seconds a try
local function press(pp, done, each)
	for _ = 1, 4 do
		pp:InputHoldBegin(); task.wait(0.05); pp:InputHoldEnd()
		if waitFor(done, each or 1.5) then return true end
	end
	return false
end

local function run()
	-- 1. the bedroom, its laptop and its RackSpot on this client
	local slot = player:GetAttribute("PlotSlot")
	assert(waitFor(function() slot = player:GetAttribute("PlotSlot"); return type(slot) == "number" and slot > 0 end, 3),
		"PlotSlot is " .. tostring(slot) .. ", want the player's slot (t105a's tail wakes the player up in their bedroom)")
	local plots = workspace:WaitForChild("OK_Plots", 5)
	assert(plots, "Workspace.OK_Plots is not on this client")
	local name = string.format("Plot_%02d", slot)
	local bedroom, station, rack
	local got = waitFor(function()
		local pm = plots:FindFirstChild(name)
		bedroom = pm and pm:FindFirstChild("Room_bedroom")
		if not bedroom then return false end
		station = nil
		for _, d in ipairs(bedroom:GetDescendants()) do
			if d:IsA("BasePart") and d:GetAttribute("Kind") == "Station" then station = d; break end
		end
		rack = bedroom:FindFirstChild("RackSpot")
		return station ~= nil and rack ~= nil
	end, 5)
	assert(got, name .. ".Room_bedroom with its laptop and RackSpot is not on this client 5 s into the test (station " .. tostring(station)
		.. ", RackSpot " .. tostring(rack) .. ")" .. RED)
	assert(bedroom:GetAttribute("OwnerId") == player.UserId, "the bedroom's OwnerId is " .. tostring(bedroom:GetAttribute("OwnerId")) .. ", want this player's " .. player.UserId)
	local sp = station:FindFirstChildWhichIsA("ProximityPrompt")
	assert(sp and sp.Enabled, "the bedroom's laptop has no enabled prompt")
	local rp = rack:FindFirstChildWhichIsA("ProximityPrompt")
	assert(rp and rp.Enabled, "the RackSpot has no enabled prompt")
	assert(rp.ActionText == "Open gear rack" and rp.ObjectText == "Your laptop", "the rack's prompt reads '" .. rp.ActionText .. "' / '" .. rp.ObjectText
		.. "', want 'Open gear rack' / 'Your laptop'")
	assert(rp.KeyboardKeyCode == Enum.KeyCode.F and rp.GamepadKeyCode == Enum.KeyCode.ButtonY, "the rack's prompt keys are " .. tostring(rp.KeyboardKeyCode)
		.. " / " .. tostring(rp.GamepadKeyCode) .. ", want F / ButtonY")
	table.insert(out, string.format("1 %s.Room_bedroom on this client, yours; the rack's prompt 'Open gear rack' / 'Your laptop' on F / ButtonY", name))

	-- 2. what t105a's handlers opened is closed first
	closeAll()
	assert(not daw.Visible and not panel.Visible, "the beat maker or the panel is still open before the first press")
	table.insert(out, "2 the beat maker and the panel closed before pressing")

	-- 3. your laptop opens the beat maker, and the payload names the room
	if hum.Sit then hum.Sit = false; task.wait(0.4) end
	local stand = (bedroom:GetPivot() * CFrame.new(2, 0, -3)).Position + Vector3.new(0, 3, 0)
	for _, it in ipairs({ { station, sp, "the laptop" }, { rack, rp, "the RackSpot" } }) do
		local dd = (stand - it[1].Position).Magnitude
		assert(dd < it[2].MaxActivationDistance - 1, string.format("the stand spot %s is %.1f studs from %s, past its prompt's reach %.1f", str(stand), dd, it[3], it[2].MaxActivationDistance))
	end
	local rd = (stand - rack.Position).Magnitude
	assert(rd < Config.Interaction.PanelCloseDistance - 1, string.format("the stand spot is %.1f studs from the RackSpot: the panel closes past %d", rd, Config.Interaction.PanelCloseDistance))
	root.CFrame = CFrame.lookAt(stand, Vector3.new(station.Position.X, stand.Y, station.Position.Z)); task.wait(1.0)
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.lookAt(stand + Vector3.new(0, 2.5, 0) + (stand - station.Position) * Vector3.new(1, 0, 1) * 0.3, station.Position)
	task.wait(1.0)
	local t3 = os.clock()
	assert(press(sp, function() return daw.Visible end, 1.2), "the beat maker did not open from your own laptop's prompt")
	local od = eventSince("OpenDAW", t3)
	local room = od and type(od.payload) == "table" and od.payload.room
	assert(room == "bedroom", "the OpenDAW payload's room is " .. tostring(room) .. ", want bedroom (DAW.OpenFor: the room's RoomKind)" .. RED)
	closeAll()
	task.wait(0.5) -- the prompts come back (DAWClient turns ProximityPromptService off while the beat maker is open)
	table.insert(out, "3 your laptop's prompt opens the beat maker; OpenDAW room = bedroom")

	-- 4. a delivery at your own laptop gets past the station check
	local del = Remotes.Session_Deliver:InvokeServer(DAWCfg.DefaultPattern, 140, 0)
	local reason = type(del) == "table" and del.reason or tostring(del)
	assert(reason ~= "away", "Session_Deliver at your own laptop answered away: StationOf should count a room's laptop for its owner" .. RED)
	assert(type(del) == "table" and del.ok ~= true and reason == "copy", "Session_Deliver (DefaultPattern, j1 active) at your own laptop answered "
		.. tostring(del and del.ok) .. " / " .. tostring(reason) .. ", want false / copy (past the station check, refused as the default beat)")
	table.insert(out, "4 Session_Deliver at your own laptop: copy (past the station check), not away")

	-- 5. the rack opens the Gear tab, at three phone sizes (the camera on the laptop again: the beat maker may have moved it)
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.lookAt(stand + Vector3.new(0, 2.5, 0) + (stand - station.Position) * Vector3.new(1, 0, 1) * 0.3, station.Position)
	task.wait(0.3)
	local inset = cam.ViewportSize - ui.AbsoluteSize
	inset = Vector2.new(math.max(0, inset.X), math.max(0, inset.Y))
	for _, screen in ipairs({ Vector2.new(667, 375), Vector2.new(771, 390), Vector2.new(844, 390) }) do
		local vp = screen - inset
		local where = vp.X .. "x" .. vp.Y .. " (" .. screen.X .. "x" .. screen.Y .. " less " .. inset.X .. "x" .. inset.Y .. ")"
		ui:SetAttribute("ForceViewport", vp)
		panel.Visible = false
		task.wait(1.1) -- the rack's cooldown (Config.Cooldowns.GearRack) since the last press
		local t5 = os.clock()
		assert(press(rp, function() return panel.Visible and #gearRows() > 0 end, 1.5), where .. ": pressing the rack's prompt did not open the panel on the Gear tab")
		local op = eventSince("OpenPanel", t5)
		local pay = op and type(op.payload) == "table" and op.payload or {}
		assert(pay.tab == "Gear" and type(pay.source) == "string" and pay.source:sub(-9) == ".RackSpot", where .. ": the OpenPanel payload is tab "
			.. tostring(pay.tab) .. ", source " .. tostring(pay.source) .. "; want Gear from the RackSpot")
		task.wait(0.2) -- one layout pass
		local size = panel.AbsoluteSize
		assert(size.X <= vp.X + 0.5 and size.Y <= vp.Y + 0.5, where .. ": the panel is " .. size.X .. "x" .. size.Y .. ", past the box")
		local close = panel:FindFirstChild("Close")
		assert(close and close.Visible and close.AbsoluteSize.X >= 44 and close.AbsoluteSize.Y >= 44 and inside(close, panel), where .. ": Close is missing, under 44 px or outside the panel")
		local gearTab = tabs:FindFirstChild("Gear")
		assert(gearTab and gearTab.AbsoluteSize.Y >= 44 and inside(gearTab, panel), where .. ": the Gear tab button is missing, under 44 px or outside the panel")
		local content = panel.Content
		assert(inside(content, panel), where .. ": Content sticks out of the panel")
		local rows = gearRows()
		for _, row in ipairs(rows) do
			local b = row:FindFirstChild("Action")
			assert(b and b.AbsoluteSize.X >= 44 and b.AbsoluteSize.Y >= 44, where .. ": " .. row.Name .. "'s button is missing or under 44 px")
			local x0, c0 = b.AbsolutePosition.X, content.AbsolutePosition.X
			assert(x0 >= c0 - 0.5 and x0 + b.AbsoluteSize.X <= c0 + content.AbsoluteSize.X + 0.5, where .. ": " .. row.Name .. "'s button sticks out of Content's width")
		end
		-- the two tap targets, from this camera, scaled to the phone's height
		local a = cam:WorldToViewportPoint(station.Position)
		local r = cam:WorldToViewportPoint(rack.Position)
		local scale = screen.Y / cam.ViewportSize.Y
		local dy = (r.Y - a.Y) * scale
		local off = rp.UIOffset.Y
		local sep = math.min(math.abs(dy + off), math.abs(dy - off))
		assert(sep >= PROMPT_H, string.format("%s: the rack's prompt sits %.0f px off the laptop's, want %d or more (UIOffset %s)", where, sep, PROMPT_H, tostring(rp.UIOffset)))
		local ay = screen.Y / 2 + (a.Y - cam.ViewportSize.Y / 2) * scale
		local reachY = math.abs(dy) + math.abs(off) + PROMPT_H / 2
		assert(ay - reachY >= 0 and ay + reachY <= screen.Y, string.format("%s: the laptop's prompt at y %.0f with the rack's %.0f px off leaves the %d px screen", where, ay, math.abs(off), screen.Y))
		table.insert(out, string.format("5 %s: the rack opens the Gear tab (%d rows, buttons 44 px+, inside); panel %dx%d; the two prompts %.0f px apart",
			where, #rows, size.X, size.Y, sep))
		panel.Visible = false
		ui:SetAttribute("ForceViewport", nil)
	end
	cam.CameraType = Enum.CameraType.Custom

	root.CFrame = CFrame.new(LOUNGE)
	return "T105B PLAY OK\n" .. table.concat(out, "\n")
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
