-- Room test (THROWAWAY; first built 2026-11-04, rewritten 2026-11-13 for the Your Rooms plan's Task 15, spec §4.13): can a
-- phone carry 12 fully furnished player plots in one server, now with the real bedroom? Builds, all tagged OK_Build =
-- "room_test" and removed by build/room_test_remove.lua:
--   Workspace.RoomTest, a Folder (a Folder reaches every client at join whatever the place's model streaming behaviour; a
--     Model whose parts are all out of range may never be sent, and the client waits on it): Plot_01..Plot_12 (each Atomic,
--     so each streams on its own), each Modules/RoomBuild.Plot(k, nil, Config.Rooms, the bedroom template, { id = -(800 + k),
--     name = "STUDIO kk" },
--     { full = true, plaques = ROWS }) at the real slot origin RoomRules.PlotOrigin(k): every room unlocked, each at its
--     item limit from Data/RoomCatalog (RoomRules.FullHome), every plaque and poster spot filled, a closet's hangers and
--     tier-3 desk speakers, all built by Modules/RoomItems as a player's own plot is. Fake owners only: no real names.
--     Attributes: Parts on each plot (its BaseParts: the client's "all of it is here" check); Plots, PartsPerPlot, Kinds
--     (ladder order, comma separated) and Throwaway on the root.
--   ReplicatedStorage.RoomTest (Go, Report), ServerScriptService.RoomTest (moves players, hooks each plot's own door
--   prompts, prints the reports), StarterPlayerScripts.RoomTest (the ROOM TOUR, NEXT PLOT and HUB buttons, the
--   measurement and the results card).
-- While Workspace.RoomTest stands, Systems/Rooms claims no slot, builds no plot and moves nobody on join or respawn (its
-- throwaway-test seam): these 12 plots sit where the live ones would, and everyone starts at the hub spawn. So the test
-- stays in for the user's private publish and phone run, and comes out (room_test_remove.lua) before any test suite:
-- every rooms Play test needs a plot of its own.
-- The place's streaming (build/19_rooms.lua: on, min 64, target 1024, LowMemory, the hub's own build models Persistent)
-- is left exactly as it is, and no existing model's ModelStreamingMode changes (RoomBuild makes each new plot and room
-- Atomic, as the live plots are).
-- The plaques read the game's own lines (LifeRules.DiscoText, RoomBuild.Copy.WeeklyPlate) with its longest visitor names
-- (both rosters) and brief titles (Data/Artists), longest line first: the bedroom's wall shows the longest there is.
-- Kept out of src/ on purpose: tools/sync.py never sees it and tools/test.py never runs it. Idempotent.
-- Precondition: the user's bedroom import (ServerStorage or Workspace .Env_bedroom_starter, with its Bedroom_Setup).
local RS, SSS, SS = game:GetService("ReplicatedStorage"), game:GetService("ServerScriptService"), game:GetService("ServerStorage")
local CS = game:GetService("CollectionService")
local function freshRequire(mod) -- edit-mode require caches modules across runs; load a clone so edits take effect
	local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name
	local ok, res = pcall(require, c); c:Destroy(); if not ok then error(res) end; return res
end
local L = require(RS.OK.BuildLib)
local B = "room_test"
local Config = freshRequire(RS.OK.Config)
local Cfg = Config.Rooms
local RoomBuild = freshRequire(RS.OK.Modules.RoomBuild)
local RoomRules = freshRequire(RS.OK.Modules.RoomRules)
local RoomScope = freshRequire(RS.OK.Modules.RoomScope)
local LifeRules = freshRequire(RS.OK.Modules.LifeRules)
local Visitors = require(RS.OK.Data.WalkIns).Visitors -- data only
local Briefs = require(RS.OK.Data.Artists).Briefs -- data only
L.clear(B)
assert(workspace:FindFirstChild("RoomTest") == nil, "Workspace.RoomTest exists but isn't room_test's (no OK_Build tag): remove it by hand first")

-- 1. the bedroom template: as Systems/Rooms' Init finds it (cloned here, never moved)
local template = SS:FindFirstChild(Cfg.Template) or workspace:FindFirstChild(Cfg.Template)
assert(template and template:IsA("Model"), "no bedroom template (ServerStorage or Workspace ." .. Cfg.Template .. "): the user's import is Task 15's precondition")
assert(template:FindFirstChild("Bedroom_Setup"), Cfg.Template .. " has no Bedroom_Setup: the bedroom pipeline's setup hasn't run on it")

-- 2. the plaques: the game's own lines with its longest names and titles, the longest line first
local function len(s) return utf8.len(s) or #s end
local names = {}
for _, v in ipairs(Visitors) do
	for _, roster in ipairs({ "parody", "fiction" }) do
		local n = type(v.names) == "table" and v.names[roster] or nil
		if type(n) == "string" and n ~= "" and not string.find(n, "[{}]") then table.insert(names, { id = v.id, name = n }) end
	end
end
table.sort(names, function(a, b) if len(a.name) ~= len(b.name) then return len(a.name) > len(b.name) end return a.name < b.name end)
local titles = {}
for _, br in ipairs(Briefs) do if type(br.title) == "string" and br.title ~= "" then table.insert(titles, br.title) end end
table.sort(titles, function(a, b) if len(a) ~= len(b) then return len(a) > len(b) end return a < b end)
local kinds = RoomBuild.KindOrder(Cfg)
local slotsN = 0
for _, kind in ipairs(kinds) do slotsN += Cfg.Kinds[kind].plaques or 0 end
local ORDER = { "placement", "trackone", "hit", "weekly" }
local rows, ni, ti = {}, 0, 0
for i = 1, slotsN do
	local kind = ORDER[(i - 1) % #ORDER + 1]
	local text
	if kind == "weekly" and #titles > 0 then
		ti += 1
		local t = titles[(ti - 1) % #titles + 1]
		text = (string.gsub(RoomBuild.Copy.WeeklyPlate, "{title}", function() return string.upper(t) end))
	elseif #names > 0 then
		if kind == "weekly" then kind = "hit" end
		ni += 1
		local v = names[(ni - 1) % #names + 1]
		text = LifeRules.DiscoText({ d = 366 - i, kind = kind, v = v.id }, { visitors = { [v.id] = v.name } })
	end
	if type(text) == "string" and text ~= "" then table.insert(rows, { kind = kind, text = text, i = i }) end
end
table.sort(rows, function(a, b) if len(a.text) ~= len(b.text) then return len(a.text) > len(b.text) end return a.i < b.i end)
assert(#rows >= slotsN, "only " .. #rows .. " plaque lines for " .. slotsN .. " spots")

-- 3. the 12 plots, at the real slot origins
local root = Instance.new("Folder") -- not a Model: see the header
root.Name = "RoomTest"
L.mark(root, B)
root:SetAttribute("Throwaway", "build/room_test.lua")
root:SetAttribute("Kinds", table.concat(kinds, ","))
local parts, lightsPer, tagged = {}, 0, 0
for k = 1, Cfg.Slots do
	local plot = RoomBuild.Plot(k, nil, Cfg, template, { id = -(800 + k), name = string.format("STUDIO %02d", k) }, { full = true, plaques = rows })
	assert(plot:GetAttribute("FullPlot") == true, "RoomBuild.Plot has no full-plot path: sync Modules/RoomBuild and Modules/RoomRules first")
	local n, lights = 0, 0
	for _, d in ipairs(plot:GetDescendants()) do
		if d:IsA("BasePart") then
			n += 1
			-- a clone keeps its template's OK_Hooked mark, and InteractionService's hook() skips a marked part: clear it, as Adopt does
			if d:GetAttribute("OK_Hooked") ~= nil then d:SetAttribute("OK_Hooked", nil) end
			if k == 1 and CS:HasTag(d, L.TAG) then tagged += 1 end
		end
		if d:IsA("Light") then lights += 1 end
	end
	plot:SetAttribute("Parts", n)
	plot.Parent = root
	parts[k] = n
	if k == 1 then lightsPer = lights end
	task.wait()
end
root:SetAttribute("Plots", Cfg.Slots)
root:SetAttribute("PartsPerPlot", parts[1])
root.Parent = workspace

-- 4. the remotes and the two scripts
local net = Instance.new("Folder"); net.Name = "RoomTest"; L.mark(net, B)
local go = Instance.new("RemoteFunction"); go.Name = "Go"; go.Parent = net
local rep = Instance.new("RemoteEvent"); rep.Name = "Report"; rep.Parent = net
net.Parent = RS

local server = Instance.new("Script"); server.Name = "RoomTest"; L.mark(server, B)
server.Source = [==[
-- THROWAWAY room test (build/room_test.lua): moves players between the hub and the 12 full plots, hooks each plot's own
-- door prompts (Systems/Rooms holds while Workspace.RoomTest stands, so nothing else hooks them), and prints each tour's
-- results to the server log as [ROOMTEST]. Every target is a CFrame on a floor; a mover lands 3 studs above it.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local root = workspace:WaitForChild("RoomTest")
local net = RS:WaitForChild("RoomTest")
local busy = {}
local function plot(k) return root:FindFirstChild(string.format("Plot_%02d", k)) end
local function onFloor(part)
	local p = part.Position
	return CFrame.new(p.X, p.Y - part.Size.Y / 2, p.Z) * part.CFrame.Rotation
end
local function roomSpawn(k, kind)
	local pl = plot(k)
	local room = pl and pl:FindFirstChild("Room_" .. tostring(kind))
	local s = room and room:FindFirstChild("Spawn", true)
	return (s and s:IsA("BasePart")) and onFloor(s) or nil
end
local function marker(part, name)
	local a = part and part:FindFirstChild(name)
	return (a and a:IsA("Attachment")) and a.WorldCFrame or nil
end
local function hub()
	local sp = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	return sp and (sp.CFrame * CFrame.new(0, sp.Size.Y / 2, 0)) or nil
end
local function target(kind, k, roomKind)
	if kind == "room" then return roomSpawn(k, roomKind or "bedroom") end
	if kind == "hub" then return hub() end
	return nil
end
local function stream(player, cf) pcall(function() player:RequestStreamAroundAsync(cf.Position, 10) end) end
net.Go.OnServerInvoke = function(player, kind, k, roomKind)
	if type(kind) ~= "string" or (roomKind ~= nil and type(roomKind) ~= "string") then return nil end
	local cf = target(kind, math.floor(tonumber(k) or 0), roomKind)
	if cf then stream(player, cf) end
	return cf
end
net.Report.OnServerEvent:Connect(function(player, s)
	if type(s) == "string" then print("[ROOMTEST] " .. player.Name .. " " .. s:sub(1, 3800)) end
end)
-- a door press: stream, unseat, move
local function move(player, cf)
	if not cf or busy[player] then return end
	busy[player] = true
	local ch = player.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if ch and hum and hum.Health > 0 then
		stream(player, cf)
		if hum.SeatPart then
			hum.Sit = false
			local w = hum.SeatPart:FindFirstChild("SeatWeld")
			if w then w:Destroy() end
			task.wait(0.3)
		end
		ch:PivotTo(cf + Vector3.new(0, 3, 0))
	end
	busy[player] = nil
end
local function hook(pp, where)
	if pp and pp:IsA("ProximityPrompt") then
		pp.Triggered:Connect(function(player) task.spawn(move, player, where()) end)
	end
end
for k = 1, root:GetAttribute("Plots") or 12 do
	local pl = plot(k)
	local landing = pl and pl:FindFirstChild("Landing")
	if landing then
		local front = landing:FindFirstChild("FrontDoor")
		hook(front and front:FindFirstChild("LeavePrompt"), hub)
		for _, door in ipairs(landing:GetChildren()) do
			local kind = door:GetAttribute("RoomKind")
			if kind then hook(door:FindFirstChild("RoomPrompt"), function() return roomSpawn(k, kind) end) end
		end
		for _, room in ipairs(pl:GetChildren()) do
			local kind = room:GetAttribute("RoomKind")
			if kind and room ~= landing then
				for _, d in ipairs(room:GetDescendants()) do
					if d:IsA("ProximityPrompt") and d.Name == "ExitPrompt" then
						hook(d, function() return marker(landing:FindFirstChild("Door_" .. kind), "Out") end)
					end
				end
			end
		end
	end
end
Players.PlayerRemoving:Connect(function(p) busy[p] = nil end)
]==]
server.Parent = SSS

local client = Instance.new("LocalScript"); client.Name = "RoomTest"; L.mark(client, B)
client.Source = [==[
-- THROWAWAY room test (build/room_test.lua). ROOM TOUR: for each of the 12 plots, ask the server to stream it, wait until
-- the whole plot is on this device (its Parts attribute), then in each of its rooms (bedroom, home, real) stand on the
-- room's Spawn and spin the camera at the room's middle for a few seconds, recording frames per second, the worst half
-- second, the slowest frame, memory, and the scene's triangles and draw calls where this device lets a script read them.
-- Then, with everything loaded, plot 1 again and the hub. The results card is for a screenshot; the same numbers go to
-- the server log. NEXT PLOT walks you to the next plot's bedroom (the plots' doors work); HUB brings you back.
local Players, RS, Run = game:GetService("Players"), game:GetService("ReplicatedStorage"), game:GetService("RunService")
local Stats, UIS, Http = game:GetService("Stats"), game:GetService("UserInputService"), game:GetService("HttpService")
local player = Players.LocalPlayer
local net = RS:WaitForChild("RoomTest")
local root = workspace:WaitForChild("RoomTest")
local N = root:GetAttribute("Plots") or 12
local KINDS = string.split(root:GetAttribute("Kinds") or "bedroom", ",")
local started = os.clock()

local gui = Instance.new("ScreenGui"); gui.Name = "RoomTestUI"; gui.ResetOnSpawn = false; gui.DisplayOrder = 50
gui.Parent = player:WaitForChild("PlayerGui")
local function button(text, y)
	local b = Instance.new("TextButton"); b.Size = UDim2.fromOffset(132, 44); b.Position = UDim2.new(0, 8, 0.3, y)
	b.BackgroundColor3 = Color3.fromRGB(20, 20, 24); b.BackgroundTransparency = 0.15; b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBlack; b.TextSize = 15; b.Text = text; b.Parent = gui
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	return b
end
local tourB, nextB, hubB = button("ROOM TOUR", 0), button("NEXT PLOT", 52), button("HUB", 104)
local function setButtons(on) tourB.Active = on; nextB.Active = on; hubB.Active = on end
local status = Instance.new("TextLabel"); status.Size = UDim2.new(0.6, 0, 0, 28); status.Position = UDim2.new(0.2, 0, 0, 6)
status.BackgroundTransparency = 0.3; status.BackgroundColor3 = Color3.new(0, 0, 0); status.TextColor3 = Color3.new(1, 1, 1)
status.Font = Enum.Font.GothamBold; status.TextSize = 15; status.Text = ""; status.Visible = false; status.Parent = gui
local card = Instance.new("Frame"); card.Name = "Frame"; card.Size = UDim2.fromScale(0.9, 0.9); card.Position = UDim2.fromScale(0.05, 0.05)
card.BackgroundColor3 = Color3.fromRGB(10, 10, 12); card.BackgroundTransparency = 0.05; card.Visible = false; card.Parent = gui
local scroll = Instance.new("ScrollingFrame"); scroll.Size = UDim2.new(1, -16, 1, -16); scroll.Position = UDim2.fromOffset(8, 8)
scroll.BackgroundTransparency = 1; scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.CanvasSize = UDim2.new()
scroll.ScrollBarThickness = 6; scroll.Parent = card
local body = Instance.new("TextLabel"); body.Size = UDim2.new(1, -10, 0, 0); body.AutomaticSize = Enum.AutomaticSize.Y
body.BackgroundTransparency = 1; body.TextColor3 = Color3.new(1, 1, 1); body.Font = Enum.Font.Code; body.TextSize = 12
body.LineHeight = 1.05; body.TextXAlignment = Enum.TextXAlignment.Left; body.TextYAlignment = Enum.TextYAlignment.Top
body.TextWrapped = true; body.Text = ""; body.Parent = scroll
local close = Instance.new("TextButton"); close.Size = UDim2.fromOffset(44, 44); close.Position = UDim2.new(1, -52, 0, 8)
close.Text = "X"; close.Font = Enum.Font.GothamBlack; close.TextSize = 18; close.TextColor3 = Color3.new(1, 1, 1)
close.BackgroundColor3 = Color3.fromRGB(60, 20, 20); close.Parent = card
close.Activated:Connect(function() card.Visible = false end)

local function plotOf(k) return root:FindFirstChild(string.format("Plot_%02d", k)) end
local function full(m)
	local want = m and m:GetAttribute("Parts"); if not want then return false end
	local n = 0; for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then n += 1 end end
	return n >= want
end
local function loadedPlots() local n = 0; for k = 1, N do if full(plotOf(k)) then n += 1 end end; return n end
local function stat(f) local ok, v = pcall(f); return (ok and type(v) == "number") and v or -1 end
local function mem() return math.floor(stat(function() return Stats:GetTotalMemoryUsageMb() end)) end
local function gfx() return math.floor(stat(function() return Stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.GraphicsParts) end)) end
-- the scene's triangles and draw calls this frame, -1 where a script can't read them on this device
local function scene()
	return math.floor(stat(function() return Stats.SceneTriangleCount end)), math.floor(stat(function() return Stats.SceneDrawcallCount end))
end
local function center(k, kind)
	local pl = plotOf(k)
	local room = pl and pl:FindFirstChild("Room_" .. kind)
	return room and (room:GetPivot().Position + Vector3.new(0, 5, 0)) or nil
end

local function measure(secs, at)
	local cam, dts, t = workspace.CurrentCamera, {}, 0
	local conn = Run.RenderStepped:Connect(function(dt)
		table.insert(dts, dt); t += dt
		if at then local a = (t / secs) * math.pi * 2; cam.CFrame = CFrame.lookAt(at, at + Vector3.new(math.cos(a), -0.15, math.sin(a))) end
	end)
	local tris, draws = -1, -1
	local t0 = os.clock()
	while os.clock() - t0 < secs do
		task.wait()
		local a, b = scene(); tris = math.max(tris, a); draws = math.max(draws, b)
	end
	conn:Disconnect()
	local total, maxdt = 0, 0; for _, d in ipairs(dts) do total += d; maxdt = math.max(maxdt, d) end
	local avg = total > 0 and #dts / total or 0
	local low, win, wn = math.huge, 0, 0
	for _, d in ipairs(dts) do win += d; wn += 1; if win >= 0.5 then low = math.min(low, wn / win); win, wn = 0, 0 end end
	if low == math.huge then low = avg end
	return { fps = math.floor(avg + 0.5), low = math.floor(low + 0.5), worstMs = math.floor(maxdt * 1000 + 0.5), mem = mem(), gfx = gfx(),
		tris = tris, draws = draws }
end

-- ask the server for a target (it streams it in), wait for `model` to be whole when given, then move there
local function go(kind, k, roomKind, model)
	local t0 = os.clock()
	local cf = net.Go:InvokeServer(kind, k, roomKind)
	if typeof(cf) ~= "CFrame" then error("no target for " .. kind .. " " .. tostring(k) .. " " .. tostring(roomKind)) end
	local took = 0
	if model then
		local deadline, ok = os.clock() + 20, false
		while os.clock() < deadline do if full(model()) then ok = true; break end; task.wait(0.05) end
		if not ok then return nil end -- never move into a plot that isn't here: the player would fall
		took = os.clock() - t0
	end
	local ch = player.Character; local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not ch or not hum or hum.Health <= 0 then error("no character") end
	if hum.SeatPart then hum.Sit = false; task.wait(0.3) end
	ch:PivotTo(cf + Vector3.new(0, 3, 0))
	return took
end

local running = false
local function line(tag, r, extra)
	return ("%-9s %s%2d fps (low %2d, worst %3d ms) · %4d MB"):format(tag, extra or "", r.fps, r.low, r.worstMs, r.mem)
end
local function tour(fast)
	if running then return nil end
	running = true; setButtons(false); card.Visible = false; status.Visible = true
	local secs, settle = fast and 0.5 or 3, fast and 0.2 or 0.7
	local cam = workspace.CurrentCamera
	local res = { at = DateTime.now():FormatUniversalTime("YYYY-MM-DD HH:mm", "en-us") .. " UTC", joinedS = math.floor(os.clock() - started),
		kinds = KINDS, plots = {}, again = {} }
	res.device = { w = math.floor(cam.ViewportSize.X), h = math.floor(cam.ViewportSize.Y), touch = UIS.TouchEnabled,
		quality = tostring(stat(function() return UserSettings():GetService("UserGameSettings").SavedQualityLevel.Value end)) }
	local ok, err = pcall(function()
		status.Text = "Hub"; res.hub = measure(secs, nil) -- the normal camera, where the player stands
		cam.CameraType = Enum.CameraType.Scriptable
		for k = 1, N do
			status.Text = ("Plot %d / %d"):format(k, N)
			local took = go("room", k, KINDS[1], function() return plotOf(k) end)
			local e = { k = k, load = took and math.floor(took * 100 + 0.5) / 100 or -1, rooms = {} }
			if took then
				local fps, low, worst, tris, draws = math.huge, math.huge, 0, -1, -1
				for i, kind in ipairs(KINDS) do
					status.Text = ("Plot %d / %d · %s"):format(k, N, kind)
					if i > 1 then go("room", k, kind, nil) end
					task.wait(settle)
					local at = center(k, kind)
					if at then
						local r = measure(secs, at)
						e.rooms[kind] = r
						fps, low, worst = math.min(fps, r.fps), math.min(low, r.low), math.max(worst, r.worstMs)
						if r.tris > tris then tris, draws, e.busiest = r.tris, r.draws, kind end
					end
				end
				e.fps, e.low, e.worstMs, e.tris, e.draws = fps == math.huge and 0 or fps, low == math.huge and 0 or low, worst, tris, draws
				e.mem = mem()
			end
			res.plots[k] = e
		end
		res.loaded = loadedPlots()
		status.Text = "Everything loaded: plot 1 again"
		if go("room", 1, KINDS[1], function() return plotOf(1) end) then task.wait(settle); res.again.plot1 = measure(secs, center(1, KINDS[1])) end
		status.Text = "Hub"
		go("hub", 0, nil, nil); task.wait(settle)
		cam.CameraType = Enum.CameraType.Custom
		res.again.hub = measure(secs, nil)
		res.loadedEnd = loadedPlots(); res.instances = stat(function() return Stats.InstanceCount end)
	end)
	cam.CameraType = Enum.CameraType.Custom
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if hum then cam.CameraSubject = hum end
	if not ok then res.error = tostring(err) end
	-- the card
	local Lines, bad = {}, {}
	local most = nil
	table.insert(Lines, ("ROOM TEST · %s · screen %dx%d · touch %s · quality %s"):format(res.at, res.device.w, res.device.h, tostring(res.device.touch), res.device.quality))
	table.insert(Lines, "each room: frames a second / the worst half second")
	if res.hub then table.insert(Lines, line("HUB", res.hub, "        ")) end
	for k = 1, N do
		local e = res.plots[k]
		if not e then break end
		if e.load < 0 then
			table.insert(Lines, ("PLOT %02d  did not load in 20 s"):format(k)); table.insert(bad, k)
		else
			local parts = {}
			for _, kind in ipairs(KINDS) do
				local r = e.rooms[kind]
				table.insert(parts, r and ("%s %d/%d"):format(kind, r.fps, r.low) or (kind .. " ?"))
			end
			table.insert(Lines, ("PLOT %02d %4.2fs · %s · worst %d ms · %d MB"):format(k, e.load, table.concat(parts, " · "), e.worstMs or 0, e.mem or -1))
			if (e.fps or 0) < 30 or (e.low or 0) < 20 or e.load > 2 then table.insert(bad, k) end
			if (e.tris or -1) >= 0 and (not most or e.tris > most.tris) then most = { k = k, tris = e.tris, draws = e.draws, kind = e.busiest } end
		end
	end
	table.insert(Lines, ("EVERYTHING LOADED: %s of %d plots on this device"):format(tostring(res.loaded or "?"), N))
	if res.again.plot1 then table.insert(Lines, line("PLOT 01", res.again.plot1, "again   ")) end
	if res.again.hub then table.insert(Lines, line("HUB", res.again.hub, "again   ")) end
	table.insert(Lines, ("graphics parts %s MB · instances %s · plots still loaded %s"):format(tostring(res.again.hub and res.again.hub.gfx or "?"),
		tostring(res.instances or "?"), tostring(res.loadedEnd or "?")))
	table.insert(Lines, most and ("most on screen: %d triangles, %d draw calls (plot %02d, %s)"):format(most.tris, most.draws, most.k, tostring(most.kind))
		or "triangles on screen: not readable by a script on this device")
	if res.error then table.insert(Lines, "STOPPED: " .. res.error) end
	table.insert(Lines, (#bad == 0 and not res.error) and "RESULT: PASS (every plot 30+ fps, low 20+, loaded within 2 s)"
		or ("RESULT: CHECK plots " .. table.concat(bad, ", ") .. " (under 30 fps, low under 20, or over 2 s to load)"))
	table.insert(Lines, "Screenshot this card and send it over.")
	body.Text = table.concat(Lines, "\n"); card.Visible = true
	status.Visible = false; running = false; setButtons(true)
	local json = Http:JSONEncode(res)
	gui:SetAttribute("LastResult", json)
	net.Report:FireServer(json)
	return json
end
tourB.Activated:Connect(function() task.spawn(tour, false) end)
local visit = 0
nextB.Activated:Connect(function()
	if running then return end
	visit = visit % N + 1
	local k = visit
	task.spawn(function() pcall(go, "room", k, KINDS[1], function() return plotOf(k) end) end)
end)
hubB.Activated:Connect(function()
	if running then return end
	task.spawn(function() pcall(go, "hub", 0, nil, nil) end)
end)
local run = Instance.new("BindableFunction"); run.Name = "Run"; run.OnInvoke = function(fast) return tour(fast == true) end; run.Parent = gui
]==]
client.Parent = game:GetService("StarterPlayer").StarterPlayerScripts

-- 5. the print: 12 plots, the parts in each (equal: the plots are identical) and in all; the hub unmoved
local same, total = true, 0
for _, n in ipairs(parts) do total += n; if n ~= parts[1] then same = false end end
task.wait()
local hubLights, _, over = RoomScope.Lights(workspace)
task.wait()
local inWs, stations = {}, {}
for _, t in ipairs(CS:GetTagged(L.TAG)) do
	if t:IsDescendantOf(workspace) then
		table.insert(inWs, t)
		if t:GetAttribute("Kind") == "Station" then table.insert(stations, t) end
	end
end
local x1, _, z1 = RoomRules.PlotOrigin(1, Cfg)
local xN, _, zN = RoomRules.PlotOrigin(Cfg.Slots, Cfg)
return ("ROOM TEST BUILT: %d plots x %d parts each (%s), %d parts in all; each plot %s, every room full (things %s), plaques and posters on every spot, tier-%d speakers, %d lights (one bulb a room), %d tagged parts inside its rooms; the longest plaque line \"%s\"; plots at the slot origins (%d, %d)..(%d, %d) from %s; hub %d lights (cap 61), %d interactables, %d stations%s; streaming as the place has it: %s, min %d, target %d, %s; Systems/Rooms holds its slots while Workspace.RoomTest stands")
	:format(Cfg.Slots, parts[1], same and "all equal" or "UNEQUAL", total, table.concat(kinds, " + "),
		(function() local t = {}; for _, kind in ipairs(kinds) do table.insert(t, kind .. " " .. Cfg.Kinds[kind].limit) end; return table.concat(t, ", ") end)(),
		RoomBuild.FULL_TIER, lightsPer, tagged, rows[1] and rows[1].text or "?", x1, z1, xN, zN, template:GetFullName(),
		hubLights, #RoomScope.Split(inWs), #RoomScope.Split(stations), over and ("; OVER: " .. over) or "",
		tostring(workspace.StreamingEnabled), workspace.StreamingMinRadius, workspace.StreamingTargetRadius, tostring(workspace.StreamOutBehavior))
