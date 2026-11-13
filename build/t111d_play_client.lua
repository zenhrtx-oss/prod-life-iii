-- Client, during play (the Your Rooms plan, Task 12; preflight F3: the bedroom's side), after t111c's tail: request j1
-- active (the sessions reset), the player at the bedroom's stand spot (room-local (2, 0, -3)). Every step waits for its
-- state, with a timeout (the locked-screen ruling).
-- (1) Room_bedroom (Workspace.OK_Plots.Plot_<PlotSlot>) with its laptop is on this client (awaited at most 5 s); the beat
--     maker and the panel are closed first.
-- (2) With the camera Custom, the laptop's prompt opens the beat maker; the OpenDAW payload's room is "bedroom" and its
--     booth is false (Systems/Rooms.Booth: a room with no booth). The card's Active is j1.
-- (3) BOUNCE loaded and made yours with t124b's 8 pads (3 stars on j1); with a Cutaway watcher started before the press,
--     Command "deliver": LastDeliver "ok"; Overlay "result" within 1 s; then for 2 s Cutaway never turns true, OK_DAW
--     stays on, the camera stays Custom and no new OK_BoothArtist appears under the camera.
-- On any error, and after success: the beat maker closed, the camera given back (Custom), the listeners disconnected; on
-- an error the character goes to the lounge; then the error is rethrown. t111e puts the profile back.
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
local DAWCfg = require(RS.OK.Modules.DAWConfig)
local Remotes = RS.OK.Remotes
local LOUNGE = Vector3.new(24, 3, 0)
local BED_STAND = Vector3.new(2, 0, -3) -- room-local (t111c's)
local RED = " (before the R-T12 sync of Systems/Rooms, Systems/DAW and OK/DAWClient: the expected red)"
local BOUNCE
for _, pr in ipairs(DAWCfg.Presets) do if pr.name == "BOUNCE" then BOUNCE = pr end end
local out = {}
local events = {}
local conns = {}
table.insert(conns, Remotes.InteractionEvent.OnClientEvent:Connect(function(kind, payload) table.insert(events, { kind = kind, payload = payload, t = os.clock() }) end))

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function str(v) return string.format("(%.2f, %.2f, %.2f)", v.X, v.Y, v.Z) end
local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function eventSince(kind, since)
	for i = #events, 1, -1 do
		local e = events[i]
		if e.kind == kind and e.t >= since then return e end
	end
	return nil
end
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

local function run()
	assert(BOUNCE, "DAWConfig.Presets has no BOUNCE")
	-- 1. the bedroom and its laptop on this client
	local slot = player:GetAttribute("PlotSlot")
	assert(waitFor(function() slot = player:GetAttribute("PlotSlot"); return type(slot) == "number" and slot > 0 end, 3), "PlotSlot is " .. tostring(slot) .. ", want the player's slot")
	local plots = workspace:WaitForChild("OK_Plots", 5); assert(plots, "Workspace.OK_Plots is not on this client")
	local name = string.format("Plot_%02d", slot)
	local bed, station
	assert(waitFor(function()
		local pm = plots:FindFirstChild(name)
		bed = pm and pm:FindFirstChild("Room_bedroom")
		if not bed then return false end
		station = nil
		for _, d in ipairs(bed:GetDescendants()) do if d:IsA("BasePart") and d:GetAttribute("Kind") == "Station" then station = d end end
		return station ~= nil
	end, 5), name .. ".Room_bedroom with its laptop is not on this client 5 s in")
	closeAll()
	local sp = station:FindFirstChildWhichIsA("ProximityPrompt")
	assert(sp and sp.Enabled, "the bedroom's laptop has no enabled prompt")
	local stand = (bed:GetPivot() * CFrame.new(BED_STAND)).Position + Vector3.new(0, 3, 0)
	if flat(root.Position - stand) > 1.5 then
		if hum.Sit then hum.Sit = false; task.wait(0.4) end
		root.CFrame = CFrame.lookAt(stand, Vector3.new(station.Position.X, stand.Y, station.Position.Z))
	end
	assert(waitFor(function() return (root.Position - station.Position).Magnitude < sp.MaxActivationDistance - 1 end, 2), string.format("the player is %.1f studs from the bedroom laptop, past its prompt's reach",
		(root.Position - station.Position).Magnitude))
	table.insert(out, string.format("1 %s.Room_bedroom on this client; the player at its stand spot %s", name, str(root.Position)))

	-- 2. the bedroom laptop: booth false
	cam.CameraType = Enum.CameraType.Custom
	task.wait(0.8)
	local t2 = os.clock()
	assert(press(sp, function() return daw.Visible end, 1.5), "the beat maker did not open from the bedroom laptop's prompt")
	local od = eventSince("OpenDAW", t2)
	local dp = od and type(od.payload) == "table" and od.payload or {}
	assert(dp.room == "bedroom", "the OpenDAW payload's room is " .. tostring(dp.room) .. ", want bedroom")
	assert(dp.booth == false, "the OpenDAW payload's booth is " .. tostring(dp.booth) .. ", want false (the bedroom has no booth)" .. RED)
	assert(waitFor(function() return req:GetAttribute("Active") == "j1" end, 5), "the Request card's Active is " .. tostring(req:GetAttribute("Active")) .. ", want j1 (t111c's tail)")
	table.insert(out, "2 the bedroom laptop opens the beat maker: payload room bedroom, booth false; Active j1")

	-- 3. delivered: the result at once, no cutaway
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
	local cutSeen = false
	table.insert(conns, req:GetAttributeChangedSignal("Cutaway"):Connect(function() if req:GetAttribute("Cutaway") == true then cutSeen = true end end))
	local boothBefore = cam:FindFirstChild("OK_BoothArtist")
	task.wait(2.1) -- Contracts' DeliverCooldown since t111b's delivery
	req:SetAttribute("LastDeliver", "")
	cmd("deliver")
	assert(waitFor(function() return (req:GetAttribute("LastDeliver") or "") ~= "" end, 8), "deliver got no answer within 8 s (LastDeliver empty)")
	assert(req:GetAttribute("LastDeliver") == "ok", "deliver answered '" .. tostring(req:GetAttribute("LastDeliver")) .. "' (" .. tostring(req:GetAttribute("Message")) .. "), want ok")
	assert(waitFor(function() return req:GetAttribute("Overlay") == "result" end, 1), "Overlay is '" .. tostring(req:GetAttribute("Overlay")) .. "', Cutaway "
		.. tostring(req:GetAttribute("Cutaway")) .. " right after the delivery; want the result at once")
	local cut = waitFor(function() return cutSeen or req:GetAttribute("Cutaway") == true or not dawGui.Enabled or cam.CameraType ~= Enum.CameraType.Custom end, 2)
	assert(not cut, "a listen-back cutaway ran at the bedroom laptop (Cutaway seen " .. tostring(cutSeen) .. ", OK_DAW enabled " .. tostring(dawGui.Enabled)
		.. ", camera " .. tostring(cam.CameraType) .. "), want none")
	local fig = cam:FindFirstChild("OK_BoothArtist")
	assert(fig == nil or fig == boothBefore, "the booth artist " .. (fig and tostring(fig:GetAttribute("Artist")) or "") .. " appeared under the camera, want none in the bedroom")
	table.insert(out, string.format("3 bedroom delivery ok (%s stars): the result at once; for 2 s no Cutaway, OK_DAW on, the camera Custom, no booth artist", tostring(req:GetAttribute("ResultStars"))))
	closeAll()
	return "T111D PLAY OK\n" .. table.concat(out, "\n")
end

local ok, msg = pcall(run)
for _, c in ipairs(conns) do c:Disconnect() end
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
