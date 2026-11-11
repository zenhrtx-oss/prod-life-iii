-- Room test (THROWAWAY, 2026-11-04): can a phone carry 12 furnished player studios in one server? Roadmap phase 3's
-- first step, approved by the user 11-04 ("Build it"). Builds, all tagged OK_Build = "room_test" and removed by
-- build/room_test_remove.lua:
--   Workspace.RoomTest.Hallway (Atomic): 12 doors with name plates and neon words, entered by prompt, plus a way back.
--   Workspace.RoomTest.Rooms.Room_01..12 (Atomic, attribute Parts): suite-sized rooms (control room, booth, lounge),
--     TARGET parts each, no lights, built on a 4 x 3 grid 2,000 studs apart, well beyond the hub.
--   ReplicatedStorage.RoomTest (Go, Report), ServerScriptService.RoomTest (moves players, prints reports),
--   StarterPlayerScripts.RoomTest (the ROOM TOUR and HALLWAY buttons, the measurement and the results card).
-- Turns streaming on for the test; every top-level Model already in Workspace becomes Persistent, so the hub stays
-- whole on every client as it is with streaming off. The original settings are kept in ServerStorage.RoomTest_Orig.
-- Kept out of src/ on purpose: tools/sync.py never sees it. Idempotent.
local RS, SSS, SS = game:GetService("ReplicatedStorage"), game:GetService("ServerScriptService"), game:GetService("ServerStorage")
local Http = game:GetService("HttpService")
local L = require(RS.OK.BuildLib)
local B = "room_test"
local TARGET, N = 600, 12
local W, D, H = 64, 44, 14
L.clear(B)

-- 1. remember the original streaming settings once (a rebuild keeps the first record)
local tops = {}
for _, c in ipairs(workspace:GetChildren()) do if c:IsA("Model") and c.Name ~= "RoomTest" then table.insert(tops, c) end end
if not SS:FindFirstChild("RoomTest_Orig") then
	local modes = {}
	for _, m in ipairs(tops) do modes[m:GetFullName()] = m.ModelStreamingMode.Name end
	local v = Instance.new("StringValue"); v.Name = "RoomTest_Orig"
	v.Value = Http:JSONEncode({ enabled = workspace.StreamingEnabled, target = workspace.StreamingTargetRadius,
		min = workspace.StreamingMinRadius, out = workspace.StreamOutBehavior.Name, modes = modes })
	v.Parent = SS
end
workspace.StreamingEnabled = true
workspace.StreamingMinRadius = 64
workspace.StreamingTargetRadius = 1024
workspace.StreamOutBehavior = Enum.StreamOutBehavior.LowMemory -- rooms stay once loaded, unless the phone runs short
local persistent, folders = {}, {}
for _, m in ipairs(tops) do m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent; table.insert(persistent, m.Name) end
for _, c in ipairs(workspace:GetChildren()) do if c:IsA("Folder") and c.Name ~= "RoomTest" then table.insert(folders, c.Name) end end

-- 2. where the hub is
local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
local function grow(cf, size)
	local h = size / 2
	lo = Vector3.new(math.min(lo.X, cf.X - h.X), math.min(lo.Y, cf.Y - h.Y), math.min(lo.Z, cf.Z - h.Z))
	hi = Vector3.new(math.max(hi.X, cf.X + h.X), math.max(hi.Y, cf.Y + h.Y), math.max(hi.Z, cf.Z + h.Z))
end
for _, c in ipairs(workspace:GetChildren()) do
	if c:IsA("Model") and c.Name ~= "RoomTest" then local ok, cf, sz = pcall(c.GetBoundingBox, c); if ok then grow(cf, sz) end
	elseif c:IsA("BasePart") and not c:IsA("Terrain") then grow(c.CFrame, c.Size)
	elseif c:IsA("Folder") and c.Name ~= "RoomTest" then for _, d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") then grow(d.CFrame, d.Size) end end end
end
local spawnLoc = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
local floorY = spawnLoc and (spawnLoc.Position.Y + spawnLoc.Size.Y / 2) or lo.Y
local hubC = (lo + hi) / 2

local root = Instance.new("Folder"); root.Name = "RoomTest"; L.mark(root, B); root:SetAttribute("Throwaway", "build/room_test.lua")
local count = 0
local function P(parent, name, size, cf, color, mat, extra)
	local p = Instance.new("Part")
	p.Name = name; p.Size = size; p.CFrame = typeof(cf) == "CFrame" and cf or CFrame.new(cf)
	p.Anchored = true; p.CanTouch = false; p.Color = color; p.Material = mat or Enum.Material.SmoothPlastic
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if math.max(size.X, size.Y, size.Z) < 3 then p.CastShadow = false end
	if extra then for k, v in pairs(extra) do p[k] = v end end
	p.Parent = parent; count += 1
	return p
end
local function cyl(parent, name, len, dia, cf, color, mat) -- a cylinder whose axis is cf's X axis
	return P(parent, name, Vector3.new(len, dia, dia), cf, color, mat, { Shape = Enum.PartType.Cylinder })
end
local UP = CFrame.Angles(0, 0, math.rad(90)) -- turns a cylinder's axis upright
local FACE_Z = CFrame.Angles(0, math.rad(90), 0) -- turns a cylinder's axis along Z
local function text(part, face, words, color, size)
	local g = Instance.new("SurfaceGui"); g.Face = face; g.LightInfluence = 0
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; g.PixelsPerStud = 40; g.Parent = part
	local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.Size = size or UDim2.fromScale(1, 1)
	t.Position = UDim2.fromScale(0, 1 - (size and size.Y.Scale or 1)); t.Text = words; t.TextScaled = true
	t.TextColor3 = color; t.Font = Enum.Font.GothamBlack; t.Parent = g
	return g
end
local function prompt(part, action, object)
	local pp = Instance.new("ProximityPrompt"); pp.ActionText = action; pp.ObjectText = object
	pp.HoldDuration = 0; pp.MaxActivationDistance = 9; pp.RequiresLineOfSight = false; pp.Parent = part
	return pp
end

local C = L.C
local WORDS = { "COOK", "NO SLEEP", "ON AIR", "LOCKED IN", "LATE NIGHT", "ONE MORE TAKE" }
local NEON = { Color3.fromRGB(255, 60, 160), Color3.fromRGB(0, 200, 255), Color3.fromRGB(255, 170, 40),
	Color3.fromRGB(120, 255, 120), Color3.fromRGB(190, 110, 255), Color3.fromRGB(255, 70, 70) }
local WALLS = { Color3.fromRGB(34, 32, 36), Color3.fromRGB(46, 30, 28), Color3.fromRGB(26, 34, 44), Color3.fromRGB(40, 40, 34) }

-- 3. one suite-sized room: control room (x 0-40), booth (x 40-64, z 28-44), lounge (x 40-64, z 0-28); door at z 0
local function buildRoom(k, O)
	local m = Instance.new("Model"); m.Name = ("Room_%02d"):format(k); m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local start = count
	local neon, wall = NEON[(k - 1) % #NEON + 1], WALLS[(k - 1) % #WALLS + 1]
	local function at(x, y, z) return O + Vector3.new(x, y, z) end
	local function cfAt(x, y, z, rot) return CFrame.new(at(x, y, z)) * (rot or CFrame.identity) end
	local function facing(x, y, z, nx, nz) local p = at(x, y, z); return CFrame.lookAt(p, p + Vector3.new(nx, 0, nz)) end
	local seed = Random.new(k * 7919)
	-- shell (15) and the spawn mark
	P(m, "Floor", Vector3.new(W, 1, D), cfAt(W / 2, -0.5, D / 2), C.wood, Enum.Material.WoodPlanks)
	P(m, "Ceiling", Vector3.new(W, 1, D), cfAt(W / 2, H + 0.5, D / 2), C.concrete, Enum.Material.Concrete)
	P(m, "WallN", Vector3.new(W, H, 1), cfAt(W / 2, H / 2, D + 0.5), wall, Enum.Material.Plaster)
	P(m, "WallS1", Vector3.new(4, H, 1), cfAt(2, H / 2, -0.5), wall, Enum.Material.Plaster)
	P(m, "WallS2", Vector3.new(54, H, 1), cfAt(37, H / 2, -0.5), wall, Enum.Material.Plaster)
	P(m, "WallSHead", Vector3.new(6, H - 8, 1), cfAt(7, (8 + H) / 2, -0.5), wall, Enum.Material.Plaster)
	P(m, "WallW", Vector3.new(1, H, D), cfAt(-0.5, H / 2, D / 2), wall, Enum.Material.Plaster)
	P(m, "WallE", Vector3.new(1, H, D), cfAt(W + 0.5, H / 2, D / 2), wall, Enum.Material.Plaster)
	P(m, "BoothLow", Vector3.new(1, 3, 16), cfAt(40, 1.5, 36), wall, Enum.Material.Plaster)
	P(m, "BoothGlass", Vector3.new(0.4, 5, 16), cfAt(40, 5.5, 36), C.glass, Enum.Material.Glass, { Transparency = 0.6 })
	P(m, "BoothHigh", Vector3.new(1, H - 8, 16), cfAt(40, (8 + H) / 2, 36), wall, Enum.Material.Plaster)
	P(m, "BoothS1", Vector3.new(4, H, 1), cfAt(42, H / 2, 28), wall, Enum.Material.Plaster)
	P(m, "BoothS2", Vector3.new(16, H, 1), cfAt(56, H / 2, 28), wall, Enum.Material.Plaster)
	P(m, "BoothSHead", Vector3.new(4, H - 8, 1), cfAt(46, (8 + H) / 2, 28), wall, Enum.Material.Plaster)
	local exit = P(m, "ExitDoor", Vector3.new(6, 8, 0.4), cfAt(7, 4, -0.3), C.walnut, Enum.Material.Wood)
	prompt(exit, "Back to hallway", "STUDIO " .. ("%02d"):format(k)).Name = "ExitPrompt"
	P(m, "Spawn", Vector3.new(2, 1, 2), cfAt(7, 0.5, 4), C.black, nil, { Transparency = 1, CanCollide = false, CanQuery = false })
	-- rugs (8)
	for _, r in ipairs({ { 20, 28, 24, 16 }, { 52, 13, 16, 14 }, { 52, 36, 10, 10 }, { 7, 2.5, 6, 3 } }) do
		P(m, "RugEdge", Vector3.new(r[3] + 1, 0.15, r[4] + 1), cfAt(r[1], 0.075, r[2]), C.black, Enum.Material.Fabric)
		P(m, "Rug", Vector3.new(r[3], 0.2, r[4]), cfAt(r[1], 0.1, r[2]), C.maroon, Enum.Material.Fabric)
	end
	-- acoustic panels (70)
	for r = 0, 2 do for c = 0, 7 do P(m, "PanelN", Vector3.new(4, 3, 0.5), cfAt(4 + c * 4.5, 3 + r * 3.6, D - 0.25), C.charcoal, Enum.Material.Fabric) end end
	for r = 0, 2 do for c = 0, 5 do P(m, "PanelW", Vector3.new(0.5, 3, 4), cfAt(0.25, 3 + r * 3.6, 6 + c * 5.5), C.charcoal, Enum.Material.Fabric) end end
	for r = 0, 2 do for c = 0, 3 do P(m, "PanelB", Vector3.new(4, 3, 0.5), cfAt(44 + c * 4.8, 3 + r * 3.6, D - 0.25), C.charcoal, Enum.Material.Fabric) end end
	for r = 0, 2 do for c = 0, 1 do P(m, "PanelBE", Vector3.new(0.5, 3, 4), cfAt(W - 0.25, 3 + r * 3.6, 32 + c * 5), C.charcoal, Enum.Material.Fabric) end end
	for _, z in ipairs({ D - 1.5, 1.5 }) do for i = 0, 2 do P(m, "BassTrap", Vector3.new(2, 4, 2), cfAt(1.5, 2.1 + i * 4.2, z), C.concreteLight, Enum.Material.Fabric) end end
	for i = 0, 3 do P(m, "Cloud", Vector3.new(8, 0.5, 6), cfAt(8 + i * 8.5, H - 1, 24), C.concreteLight, Enum.Material.Fabric) end
	-- the desk: cabinets, console, 24 faders, 48 knobs, meters, a 25-key controller (136)
	P(m, "DeskTop", Vector3.new(16, 0.6, 8), cfAt(20, 3, 34), C.walnut, Enum.Material.Wood)
	P(m, "DeskCabL", Vector3.new(3, 2.7, 7.6), cfAt(13.5, 1.35, 34), C.charcoal)
	P(m, "DeskCabR", Vector3.new(3, 2.7, 7.6), cfAt(26.5, 1.35, 34), C.charcoal)
	P(m, "DeskModesty", Vector3.new(10, 2, 0.3), cfAt(20, 1.6, 37.6), C.charcoal)
	P(m, "Console", Vector3.new(12, 0.4, 3.4), cfAt(20, 3.5, 35.5), C.steel, Enum.Material.Metal)
	for i = 0, 23 do
		P(m, "FaderSlot", Vector3.new(0.15, 0.08, 1.2), cfAt(14.6 + i * 0.47, 3.74, 35), C.black)
		P(m, "FaderCap", Vector3.new(0.35, 0.25, 0.3), cfAt(14.6 + i * 0.47, 3.85, 34.6 + seed:NextNumber() * 0.8), C.white)
	end
	for r = 0, 2 do for i = 0, 15 do
		local tone = ({ C.red, C.blue, C.white })[r + 1]
		cyl(m, "Knob", 0.3, 0.35, cfAt(14.8 + i * 0.68, 3.85, 36 + r * 0.45, UP), tone)
	end end
	P(m, "MeterBridge", Vector3.new(12, 1, 0.5), cfAt(20, 4.2, 37.6), C.black)
	for i = 0, 7 do P(m, "Meter", Vector3.new(0.9, 0.6, 0.1), cfAt(14.9 + i * 1.45, 4.25, 37.33), i < 6 and C.led or C.warm, Enum.Material.Neon) end
	P(m, "KeysBase", Vector3.new(7, 0.3, 1.6), cfAt(20, 3.45, 31.4), C.black)
	for i = 0, 14 do P(m, "KeyW", Vector3.new(0.42, 0.12, 1.2), cfAt(16.85 + i * 0.45, 3.66, 31.3), C.white) end
	for _, i in ipairs({ 0, 1, 3, 4, 5, 7, 8, 10, 11, 12 }) do P(m, "KeyB", Vector3.new(0.25, 0.14, 0.7), cfAt(17.08 + i * 0.45, 3.72, 31.6), C.black) end
	-- screens (12): three on the desk, the middle one with a label
	for i, x in ipairs({ 14.5, 20, 25.5 }) do
		local yaw = CFrame.Angles(0, math.rad(({ 20, 0, -20 })[i]), 0)
		P(m, "ScreenBezel", Vector3.new(5.2, 3.2, 0.3), cfAt(x, 6.2, 37.1, yaw), C.black)
		local s = P(m, "Screen", Vector3.new(4.8, 2.8, 0.05), cfAt(x, 6.2, 36.93, yaw), Color3.fromRGB(20, 30, 60))
		if i == 2 then text(s, Enum.NormalId.Front, "BEAT 07 · 140 BPM", neon) end
		P(m, "ScreenPole", Vector3.new(0.3, 1.2, 0.3), cfAt(x, 4.2, 37.3), C.steel, Enum.Material.Metal)
		P(m, "ScreenFoot", Vector3.new(1.6, 0.15, 1), cfAt(x, 3.38, 37.3), C.steel, Enum.Material.Metal)
	end
	-- speakers (18)
	for _, x in ipairs({ 12.5, 27.5 }) do
		P(m, "Nearfield", Vector3.new(1.6, 2.6, 1.6), cfAt(x, 4.6, 36.5), C.black)
		cyl(m, "Woofer", 0.1, 1.2, cfAt(x, 4.2, 35.68, FACE_Z), C.steel, Enum.Material.Metal)
		cyl(m, "Tweeter", 0.1, 0.5, cfAt(x, 5.3, 35.68, FACE_Z), C.steel, Enum.Material.Metal)
	end
	for _, x in ipairs({ 6, 34 }) do
		P(m, "MainStand", Vector3.new(3, 3.5, 2.6), cfAt(x, 1.75, 41), C.charcoal)
		P(m, "Main", Vector3.new(4, 6, 3), cfAt(x, 6.5, 41), C.black)
		cyl(m, "MainWoofer", 0.15, 3, cfAt(x, 5.5, 39.45, FACE_Z), C.steel, Enum.Material.Metal)
		cyl(m, "MainTweeter", 0.15, 1, cfAt(x, 8.3, 39.45, FACE_Z), C.steel, Enum.Material.Metal)
		P(m, "MainPort", Vector3.new(1.6, 0.3, 0.1), cfAt(x, 4, 39.45), C.black)
	end
	P(m, "Sub", Vector3.new(3, 2.5, 3), cfAt(20, 1.25, 33), C.black)
	cyl(m, "SubWoofer", 0.1, 2, cfAt(20, 1.25, 31.45, FACE_Z), C.steel, Enum.Material.Metal)
	-- gear rack (34)
	P(m, "RackL", Vector3.new(0.3, 6, 2), cfAt(3.2, 3, 30), C.black); P(m, "RackR", Vector3.new(0.3, 6, 2), cfAt(6.8, 3, 30), C.black)
	P(m, "RackTop", Vector3.new(3.9, 0.3, 2), cfAt(5, 6.15, 30), C.black); P(m, "RackBase", Vector3.new(3.9, 0.3, 2), cfAt(5, 0.15, 30), C.black)
	for u = 0, 9 do
		local y = 0.65 + u * 0.55
		P(m, "RackUnit", Vector3.new(3.3, 0.48, 0.15), cfAt(5, y, 29), u % 2 == 0 and C.steel or C.charcoal, Enum.Material.Metal)
		cyl(m, "RackKnob", 0.12, 0.3, cfAt(4, y, 28.88, FACE_Z), C.white)
		P(m, "RackLed", Vector3.new(0.15, 0.15, 0.05), cfAt(6.2, y, 28.9), u % 3 == 0 and C.red or C.led, Enum.Material.Neon)
	end
	-- the chair (10)
	for i = 0, 4 do P(m, "ChairLeg", Vector3.new(0.3, 0.2, 1.4), cfAt(20, 0.3, 28, CFrame.Angles(0, math.rad(i * 72), 0) * CFrame.new(0, 0, 0.6)), C.black) end
	P(m, "ChairLift", Vector3.new(0.4, 1.4, 0.4), cfAt(20, 1, 28), C.steel, Enum.Material.Metal)
	P(m, "ChairSeat", Vector3.new(2.4, 0.5, 2.4), cfAt(20, 2, 28), C.leather, Enum.Material.Fabric)
	P(m, "ChairBack", Vector3.new(2.4, 3, 0.4), cfAt(20, 3.6, 26.9), C.leather, Enum.Material.Fabric)
	P(m, "ChairArmL", Vector3.new(0.3, 0.3, 1.8), cfAt(18.9, 2.7, 28), C.black); P(m, "ChairArmR", Vector3.new(0.3, 0.3, 1.8), cfAt(21.1, 2.7, 28), C.black)
	-- the booth (13)
	cyl(m, "MicBase", 0.2, 1.4, cfAt(52, 0.1, 37, UP), C.black)
	P(m, "MicPole", Vector3.new(0.15, 5, 0.15), cfAt(52, 2.7, 37), C.steel, Enum.Material.Metal)
	P(m, "MicBoom", Vector3.new(2.5, 0.12, 0.12), cfAt(53, 5.2, 37), C.steel, Enum.Material.Metal)
	P(m, "Mic", Vector3.new(0.5, 1, 0.5), cfAt(54.1, 4.9, 37), C.steel, Enum.Material.Metal)
	cyl(m, "PopFilter", 0.05, 0.9, cfAt(54.1, 4.9, 36.4, FACE_Z), C.black)
	P(m, "PhonesHook", Vector3.new(0.6, 0.2, 0.2), cfAt(W - 0.6, 6, 41), C.steel, Enum.Material.Metal)
	P(m, "Phones", Vector3.new(0.3, 1, 0.9), cfAt(W - 0.9, 5.5, 41), C.black)
	P(m, "StoolSeat", Vector3.new(1.6, 0.3, 1.6), cfAt(52, 2.6, 33), C.leather, Enum.Material.Fabric)
	for i = 0, 2 do P(m, "StoolLeg", Vector3.new(0.2, 2.4, 0.2), cfAt(52, 1.2, 33, CFrame.Angles(0, math.rad(i * 120), 0) * CFrame.new(0, 0, 0.6)), C.steel, Enum.Material.Metal) end
	P(m, "LyricStand", Vector3.new(0.12, 3.6, 0.12), cfAt(50, 1.8, 39), C.black)
	P(m, "LyricTray", Vector3.new(1.6, 1.1, 0.1), cfAt(50, 3.8, 38.9), C.black)
	-- the lounge: two couches, a table, an armchair, the TV, two shelves of records (141)
	P(m, "Couch1", Vector3.new(4, 1.4, 12), cfAt(61, 0.7, 14), C.leather, Enum.Material.Fabric)
	P(m, "Couch1Back", Vector3.new(1.2, 2.4, 12), cfAt(62.9, 2.6, 14), C.leather, Enum.Material.Fabric)
	for _, z in ipairs({ 7.5, 20.5 }) do P(m, "Couch1Arm", Vector3.new(4, 2, 1), cfAt(61, 1.6, z), C.leather, Enum.Material.Fabric) end
	for _, z in ipairs({ 10, 14, 18 }) do P(m, "Couch1Cushion", Vector3.new(3, 0.6, 3.8), cfAt(60.6, 1.7, z), C.maroon, Enum.Material.Fabric) end
	P(m, "Couch2", Vector3.new(12, 1.4, 4), cfAt(50, 0.7, 3.5), C.leather, Enum.Material.Fabric)
	P(m, "Couch2Back", Vector3.new(12, 2.4, 1.2), cfAt(50, 2.6, 1.5), C.leather, Enum.Material.Fabric)
	for _, x in ipairs({ 43.5, 56.5 }) do P(m, "Couch2Arm", Vector3.new(1, 2, 4), cfAt(x, 1.6, 3.5), C.leather, Enum.Material.Fabric) end
	for _, x in ipairs({ 46, 50, 54 }) do P(m, "Couch2Cushion", Vector3.new(3.8, 0.6, 3), cfAt(x, 1.7, 3.9), C.maroon, Enum.Material.Fabric) end
	P(m, "TableTop", Vector3.new(6, 0.3, 4), cfAt(52, 1.5, 13), C.walnut, Enum.Material.Wood)
	for _, d in ipairs({ { -2.6, -1.6 }, { 2.6, -1.6 }, { -2.6, 1.6 }, { 2.6, 1.6 } }) do P(m, "TableLeg", Vector3.new(0.3, 1.35, 0.3), cfAt(52 + d[1], 0.68, 13 + d[2]), C.black) end
	P(m, "Armchair", Vector3.new(3.2, 1.4, 3.2), cfAt(45, 0.7, 18), C.leather, Enum.Material.Fabric)
	P(m, "ArmchairBack", Vector3.new(3.2, 2.4, 0.8), cfAt(45, 2.6, 19.2), C.leather, Enum.Material.Fabric)
	for _, x in ipairs({ 43.6, 46.4 }) do P(m, "ArmchairArm", Vector3.new(0.6, 1.8, 3.2), cfAt(x, 1.6, 18), C.leather, Enum.Material.Fabric) end
	P(m, "ArmchairCushion", Vector3.new(2.4, 0.5, 2.4), cfAt(45, 1.6, 17.8), C.maroon, Enum.Material.Fabric)
	P(m, "TV", Vector3.new(7, 4, 0.3), cfAt(54, 6, 27.3), C.black)
	local tv = P(m, "TVScreen", Vector3.new(6.6, 3.6, 0.05), cfAt(54, 6, 27.13), Color3.fromRGB(16, 22, 40))
	text(tv, Enum.NormalId.Front, "CHARTS · #1", neon)
	P(m, "TVConsole", Vector3.new(8, 1.5, 1.6), cfAt(54, 0.75, 26.6), C.walnut, Enum.Material.Wood)
	for _, x in ipairs({ 52, 56 }) do P(m, "TVDoor", Vector3.new(3.8, 1.2, 0.05), cfAt(x, 0.75, 25.78), C.wood, Enum.Material.Wood) end
	for _, bx in ipairs({ 18, 30 }) do
		P(m, "ShelfSideL", Vector3.new(0.3, 7, 1.6), cfAt(bx - 3, 3.5, 1), C.walnut, Enum.Material.Wood)
		P(m, "ShelfSideR", Vector3.new(0.3, 7, 1.6), cfAt(bx + 3, 3.5, 1), C.walnut, Enum.Material.Wood)
		P(m, "ShelfTop", Vector3.new(6.3, 0.3, 1.6), cfAt(bx, 7, 1), C.walnut, Enum.Material.Wood)
		P(m, "ShelfBack", Vector3.new(6, 7, 0.2), cfAt(bx, 3.5, 0.3), C.walnut, Enum.Material.Wood)
		for s = 0, 3 do
			local y = 0.8 + s * 1.6
			P(m, "Shelf", Vector3.new(5.7, 0.2, 1.4), cfAt(bx, y, 1), C.walnut, Enum.Material.Wood)
			for i = 0, 11 do
				local tone = Color3.fromHSV(seed:NextNumber(), 0.5, 0.35 + seed:NextNumber() * 0.4)
				P(m, "Record", Vector3.new(0.08, 1.2, 1.2), cfAt(bx - 2.5 + i * 0.44, y + 0.7, 1.05), tone)
			end
		end
	end
	-- plants (48)
	for _, p in ipairs({ { 38.5, 1.5 }, { 62.5, 1.5 }, { 42, 26.5 }, { 1.8, 22 }, { 62.5, 29.8 }, { 38.5, 42.5 } }) do
		local x, z = p[1], p[2]
		cyl(m, "Pot", 1.6, 1.6, cfAt(x, 0.8, z, UP), C.concreteLight, Enum.Material.Concrete)
		cyl(m, "Soil", 0.1, 1.4, cfAt(x, 1.6, z, UP), C.brick)
		P(m, "Stem", Vector3.new(0.25, 2.5, 0.25), cfAt(x, 2.8, z), Color3.fromRGB(60, 90, 40))
		for i = 0, 4 do
			P(m, "Leaf", Vector3.new(1.6, 0.15, 0.7), cfAt(x, 2.6 + i * 0.2, z, CFrame.Angles(0, math.rad(i * 72), math.rad(20)) * CFrame.new(0.7, 0, 0)), Color3.fromRGB(50, 120, 50), Enum.Material.Fabric)
		end
	end
	-- the career on the walls: 12 plaques above couch 1 (24)
	for r = 0, 1 do for c = 0, 5 do
		local f = P(m, "Plaque", Vector3.new(0.25, 2.6, 2), cfAt(W - 0.15, 6.5 + r * 3.2, 3.5 + c * 3.8), C.black)
		text(f, Enum.NormalId.Left, (r == 0 and "GOLD" or "PLATINUM") .. " · TRACK " .. (r * 6 + c + 1), C.white, UDim2.fromScale(1, 0.25))
		cyl(m, "Disc", 0.08, 1.4, cfAt(W - 0.32, 6.75 + r * 3.2, 3.5 + c * 3.8), r == 0 and Color3.fromRGB(212, 175, 55) or Color3.fromRGB(220, 220, 230), Enum.Material.Metal)
	end end
	-- neon signs (15) and ceiling strips (8)
	local function sign(cf, word)
		local b = P(m, "SignBack", Vector3.new(6, 2, 0.2), cf, C.black)
		text(b, Enum.NormalId.Front, word, neon)
		for _, e in ipairs({ { 0, 1, 6, 0.12 }, { 0, -1, 6, 0.12 }, { -3, 0, 0.12, 2 }, { 3, 0, 0.12, 2 } }) do
			P(m, "SignTube", Vector3.new(e[3], e[4], 0.12), cf * CFrame.new(e[1], e[2], -0.15), neon, Enum.Material.Neon)
		end
	end
	sign(facing(24, 10.5, 0.3, 0, 1), WORDS[(k - 1) % #WORDS + 1])
	sign(facing(50, 9, 0.3, 0, 1), WORDS[k % #WORDS + 1])
	sign(facing(W - 0.3, 11, 36, -1, 0), "ON AIR")
	for _, s in ipairs({ { 20, 0.6, 38, 0.2 }, { 20, D - 0.6, 38, 0.2 }, { 0.6, D / 2, 0.2, 42 }, { 39.4, 14, 0.2, 26 },
		{ 52, 0.6, 22, 0.2 }, { 52, 27.4, 22, 0.2 }, { W - 0.6, 14, 0.2, 26 }, { 52, D - 0.6, 22, 0.2 } }) do
		P(m, "Strip", Vector3.new(s[3], 0.2, s[4]), cfAt(s[1], H - 0.3, s[2]), neon, Enum.Material.Neon)
	end
	-- floor lamps without lights (9) and a mini fridge (3)
	for _, p in ipairs({ { 44, 25 }, { 62, 5 }, { 2.5, 28 } }) do
		P(m, "LampBase", Vector3.new(1.2, 0.2, 1.2), cfAt(p[1], 0.1, p[2]), C.black)
		P(m, "LampPole", Vector3.new(0.2, 5, 0.2), cfAt(p[1], 2.7, p[2]), C.steel, Enum.Material.Metal)
		P(m, "LampShade", Vector3.new(1.6, 1.2, 1.6), cfAt(p[1], 5.6, p[2]), C.warm, Enum.Material.Fabric)
	end
	P(m, "Fridge", Vector3.new(2, 3, 2), cfAt(41.5, 1.5, 1.5), C.white)
	P(m, "FridgeHandle", Vector3.new(0.1, 1.2, 0.2), cfAt(42.2, 1.8, 2.55), C.steel, Enum.Material.Metal)
	P(m, "FridgeTop", Vector3.new(1.2, 0.6, 0.8), cfAt(41.5, 3.3, 1.5), C.red)
	-- clutter up to TARGET: cups, books, crates and cans on the desk, the table, the shelves and the floor
	local spots = { { 13, 3.3, 31, 4, 1.5 }, { 27, 3.3, 31, 4, 1.5 }, { 52, 1.65, 13, 5, 3 }, { 18, 7.15, 1, 5, 1 },
		{ 30, 7.15, 1, 5, 1 }, { 30, 0, 18, 12, 6 }, { 58, 0, 24, 6, 2 }, { 48, 0, 40, 8, 3 } }
	local kinds = { { "Cup", Vector3.new(0.4, 0.5, 0.4) }, { "Book", Vector3.new(0.8, 0.15, 0.6) }, { "Crate", Vector3.new(1.6, 1.2, 1.6) },
		{ "Can", Vector3.new(0.3, 0.5, 0.3) }, { "Box", Vector3.new(1, 0.8, 1) } }
	local i = 0
	while count - start < TARGET do
		local s, kd = spots[i % #spots + 1], kinds[seed:NextInteger(1, #kinds)]
		if s[2] > 0 and kd[1] == "Crate" then kd = kinds[2] end -- crates only on the floor
		local x, z = s[1] + (seed:NextNumber() - 0.5) * s[4], s[3] + (seed:NextNumber() - 0.5) * s[5]
		P(m, kd[1], kd[2], cfAt(x, s[2] + kd[2].Y / 2, z, CFrame.Angles(0, seed:NextNumber() * 6.28, 0)), Color3.fromHSV(seed:NextNumber(), 0.4, 0.7), Enum.Material.Plastic)
		i += 1
	end
	m:SetAttribute("Parts", count - start)
	m:SetAttribute("Center", at(20, 6, 22))
	m.WorldPivot = CFrame.new(at(W / 2, 0, D / 2))
	return m
end

-- 4. the hallway: 6 doors a side, a way back to the hub at the south end
local hallO = Vector3.new(hi.X + 40, floorY, hubC.Z - 52)
local hall = Instance.new("Model"); hall.Name = "Hallway"; hall.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
local hs = count
do
	local HL, HW = 104, 16
	local function at(x, y, z) return hallO + Vector3.new(x, y, z) end
	P(hall, "Floor", Vector3.new(HW, 1, HL), CFrame.new(at(HW / 2, -0.5, HL / 2)), C.concrete, Enum.Material.Concrete)
	P(hall, "Ceiling", Vector3.new(HW, 1, HL), CFrame.new(at(HW / 2, H + 0.5, HL / 2)), C.concrete, Enum.Material.Concrete)
	P(hall, "WallW", Vector3.new(1, H, HL), CFrame.new(at(-0.5, H / 2, HL / 2)), C.concreteLight, Enum.Material.Plaster)
	P(hall, "WallE", Vector3.new(1, H, HL), CFrame.new(at(HW + 0.5, H / 2, HL / 2)), C.concreteLight, Enum.Material.Plaster)
	P(hall, "WallN", Vector3.new(HW, H, 1), CFrame.new(at(HW / 2, H / 2, HL + 0.5)), C.concreteLight, Enum.Material.Plaster)
	P(hall, "WallS", Vector3.new(HW, H, 1), CFrame.new(at(HW / 2, H / 2, -0.5)), C.concreteLight, Enum.Material.Plaster)
	P(hall, "Strip", Vector3.new(0.4, 0.2, HL - 4), CFrame.new(at(HW / 2, H - 0.3, HL / 2)), C.white, Enum.Material.Neon)
	local back = P(hall, "HubDoor", Vector3.new(6, 8, 0.4), CFrame.lookAt(at(HW / 2, 4, 0.3), at(HW / 2, 4, 2)), C.walnut, Enum.Material.Wood)
	text(back, Enum.NormalId.Front, "HUB", C.white, UDim2.fromScale(1, 0.15))
	prompt(back, "Back to the hub", "HALLWAY").Name = "HubPrompt"
	P(hall, "HallSpawn", Vector3.new(2, 1, 2), CFrame.lookAt(at(HW / 2, 0.5, 4), at(HW / 2, 0.5, 8)), C.black, nil, { Transparency = 1, CanCollide = false, CanQuery = false })
	for k = 1, N do
		local west = k <= 6
		local z = 10 + ((k - 1) % 6) * 16
		local x = west and 0.3 or HW - 0.3
		local p = at(x, 4.5, z)
		local cf = CFrame.lookAt(p, p + Vector3.new(west and 1 or -1, 0, 0))
		local neon = NEON[(k - 1) % #NEON + 1]
		local door = P(hall, ("Door_%02d"):format(k), Vector3.new(6, 9, 0.4), cf, C.walnut, Enum.Material.Wood)
		prompt(door, "Enter", "STUDIO " .. ("%02d"):format(k)).Name = "EnterPrompt"
		P(hall, "PostL", Vector3.new(0.5, 9.5, 0.6), cf * CFrame.new(-3.25, 0.25, 0), C.black)
		P(hall, "PostR", Vector3.new(0.5, 9.5, 0.6), cf * CFrame.new(3.25, 0.25, 0), C.black)
		P(hall, "Header", Vector3.new(7, 0.5, 0.6), cf * CFrame.new(0, 4.75, 0), C.black)
		local plate = P(hall, "NamePlate", Vector3.new(5, 1.2, 0.2), cf * CFrame.new(0, 5.8, -0.1), C.black)
		text(plate, Enum.NormalId.Front, "STUDIO " .. ("%02d"):format(k), C.white)
		local sg = P(hall, "NeonWord", Vector3.new(4, 1, 0.15), cf * CFrame.new(0, 7.4, -0.1), neon, Enum.Material.Neon)
		text(sg, Enum.NormalId.Front, WORDS[(k - 1) % #WORDS + 1], C.black)
		P(hall, "Mat", Vector3.new(4, 0.15, 2), CFrame.new(at(west and 2 or HW - 2, 0.075, z)), C.maroon, Enum.Material.Fabric)
	end
end
hall:SetAttribute("Parts", count - hs)
hall.Parent = root

-- 5. the rooms, 4 x 3, 2,000 studs apart (beyond the 1,024-stud streaming radius), starting 4,000 studs past the hub
local rooms = Instance.new("Folder"); rooms.Name = "Rooms"; rooms.Parent = root
local roomParts = {}
for k = 1, N do
	local col, row = (k - 1) % 4, math.floor((k - 1) / 4)
	local m = buildRoom(k, Vector3.new(hi.X + 4000 + col * 2000, floorY, hubC.Z + (row - 1) * 2000))
	m.Parent = rooms; table.insert(roomParts, m:GetAttribute("Parts"))
end
root.Parent = workspace

-- 6. the remotes and the two scripts
local net = Instance.new("Folder"); net.Name = "RoomTest"; L.mark(net, B)
local go = Instance.new("RemoteFunction"); go.Name = "Go"; go.Parent = net
local rep = Instance.new("RemoteEvent"); rep.Name = "Report"; rep.Parent = net
net.Parent = RS

local server = Instance.new("Script"); server.Name = "RoomTest"; L.mark(server, B)
server.Source = [==[
-- THROWAWAY room test (build/room_test.lua): moves players between the hub, the hallway and the 12 rooms, and prints
-- each tour's results to the server log as [ROOMTEST].
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local root = workspace:WaitForChild("RoomTest")
local rooms, hall = root:WaitForChild("Rooms"), root:WaitForChild("Hallway")
local net = RS:WaitForChild("RoomTest")
local function target(kind, k)
	if kind == "room" then
		local r = rooms:FindFirstChild(("Room_%02d"):format(k)); local s = r and r:FindFirstChild("Spawn")
		if s then return s.CFrame * CFrame.new(0, 3, 0) * CFrame.Angles(0, math.pi, 0) end
	elseif kind == "hall" then
		local d = hall:FindFirstChild(("Door_%02d"):format(k))
		if d then local p = (d.CFrame * CFrame.new(0, -1.5, -5)).Position; return CFrame.lookAt(p, p + d.CFrame.LookVector) end
	elseif kind == "hallspawn" then
		local s = hall:FindFirstChild("HallSpawn"); if s then return s.CFrame * CFrame.new(0, 3, 0) end
	elseif kind == "hub" then
		local sp = workspace:FindFirstChildWhichIsA("SpawnLocation", true); if sp then return sp.CFrame * CFrame.new(0, 4, 0) end
	end
	return nil
end
local function stream(player, cf) pcall(function() player:RequestStreamAroundAsync(cf.Position, 10) end) end
net.Go.OnServerInvoke = function(player, kind, k)
	if type(kind) ~= "string" then return nil end
	local cf = target(kind, math.floor(tonumber(k) or 0))
	if cf then stream(player, cf) end
	return cf
end
net.Report.OnServerEvent:Connect(function(player, s)
	if type(s) == "string" then print("[ROOMTEST] " .. player.Name .. " " .. s:sub(1, 3800)) end
end)
local function hook(pp, kind, k)
	pp.Triggered:Connect(function(player)
		local cf = target(kind, k); if not cf then return end
		stream(player, cf)
		local ch = player.Character; if ch then ch:PivotTo(cf) end
	end)
end
for k = 1, 12 do
	local d = hall:FindFirstChild(("Door_%02d"):format(k)); if d then hook(d.EnterPrompt, "room", k) end
	local r = rooms:FindFirstChild(("Room_%02d"):format(k)); if r then hook(r.ExitDoor.ExitPrompt, "hall", k) end
end
hook(hall.HubDoor.HubPrompt, "hub", 0)
]==]
server.Parent = SSS

local client = Instance.new("LocalScript"); client.Name = "RoomTest"; L.mark(client, B)
client.Source = [==[
-- THROWAWAY room test (build/room_test.lua). ROOM TOUR: for each of the 12 rooms, ask the server to stream it, wait
-- until the whole room is on this device (its Parts attribute), move there, spin the camera for a few seconds and
-- record frames per second, the worst half second, the slowest frame and memory. Then, with every room loaded, room 1
-- again, the hallway and the hub. The results card is for a screenshot; the same numbers go to the server log.
local Players, RS, Run = game:GetService("Players"), game:GetService("ReplicatedStorage"), game:GetService("RunService")
local Stats, UIS, Http = game:GetService("Stats"), game:GetService("UserInputService"), game:GetService("HttpService")
local player = Players.LocalPlayer
local net = RS:WaitForChild("RoomTest")
local root = workspace:WaitForChild("RoomTest")
local roomsF = root:WaitForChild("Rooms")
local N, started = 12, os.clock()

local gui = Instance.new("ScreenGui"); gui.Name = "RoomTestUI"; gui.ResetOnSpawn = false; gui.DisplayOrder = 50
gui.Parent = player:WaitForChild("PlayerGui")
local function button(text, y)
	local b = Instance.new("TextButton"); b.Size = UDim2.fromOffset(132, 44); b.Position = UDim2.new(0, 8, 0.3, y)
	b.BackgroundColor3 = Color3.fromRGB(20, 20, 24); b.BackgroundTransparency = 0.15; b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBlack; b.TextSize = 15; b.Text = text; b.Parent = gui
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	return b
end
local tourB, hallB = button("ROOM TOUR", 0), button("HALLWAY", 52)
local status = Instance.new("TextLabel"); status.Size = UDim2.new(0.6, 0, 0, 28); status.Position = UDim2.new(0.2, 0, 0, 6)
status.BackgroundTransparency = 0.3; status.BackgroundColor3 = Color3.new(0, 0, 0); status.TextColor3 = Color3.new(1, 1, 1)
status.Font = Enum.Font.GothamBold; status.TextSize = 15; status.Text = ""; status.Visible = false; status.Parent = gui
local card = Instance.new("Frame"); card.Size = UDim2.new(0.9, 0, 0.9, 0); card.Position = UDim2.new(0.05, 0, 0.05, 0)
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

local function full(m)
	local want = m and m:GetAttribute("Parts"); if not want then return false end
	local n = 0; for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then n += 1 end end
	return n >= want
end
local function room(k) return roomsF:FindFirstChild(("Room_%02d"):format(k)) end
local function loadedRooms() local n = 0; for k = 1, N do if full(room(k)) then n += 1 end end; return n end
local function stat(f) local ok, v = pcall(f); return ok and v or -1 end
local function mem() return math.floor(stat(function() return Stats:GetTotalMemoryUsageMb() end)) end
local function gfx() return math.floor(stat(function() return Stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.GraphicsParts) end)) end

local function measure(secs, center)
	local cam, dts, t = workspace.CurrentCamera, {}, 0
	local conn = Run.RenderStepped:Connect(function(dt)
		table.insert(dts, dt); t += dt
		if center then local a = (t / secs) * math.pi * 2; cam.CFrame = CFrame.lookAt(center, center + Vector3.new(math.cos(a), -0.15, math.sin(a))) end
	end)
	local t0 = os.clock(); while os.clock() - t0 < secs do task.wait() end
	conn:Disconnect()
	local total, maxdt = 0, 0; for _, d in ipairs(dts) do total += d; maxdt = math.max(maxdt, d) end
	local avg = total > 0 and #dts / total or 0
	local low, win, wn = math.huge, 0, 0
	for _, d in ipairs(dts) do win += d; wn += 1; if win >= 0.5 then low = math.min(low, wn / win); win, wn = 0, 0 end end
	if low == math.huge then low = avg end
	return { fps = math.floor(avg + 0.5), low = math.floor(low + 0.5), worstMs = math.floor(maxdt * 1000 + 0.5), mem = mem(), gfx = gfx() }
end

local function go(kind, k, model)
	local t0 = os.clock()
	local cf = net.Go:InvokeServer(kind, k)
	if typeof(cf) ~= "CFrame" then error("no target for " .. kind .. " " .. tostring(k)) end
	local took = 0
	if model then
		local deadline, ok = os.clock() + 20, false
		while os.clock() < deadline do if full(model()) then ok = true; break end; task.wait(0.05) end
		if not ok then return nil end -- never move into a room that isn't here: the player would fall
		took = os.clock() - t0
	end
	local ch = player.Character; local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not ch or not hum or hum.Health <= 0 then error("no character") end
	ch:PivotTo(cf)
	return took
end

local running = false
local function line(tag, r, extra)
	return ("%-9s %s%2d fps (low %2d, worst %3d ms) · %4d MB"):format(tag, extra or "", r.fps, r.low, r.worstMs, r.mem)
end
local function tour(fast)
	if running then return nil end
	running = true; tourB.Active = false; hallB.Active = false; card.Visible = false; status.Visible = true
	local secs, settle = fast and 0.6 or 4, fast and 0.2 or 1
	local cam = workspace.CurrentCamera
	local res = { at = DateTime.now():FormatUniversalTime("YYYY-MM-DD HH:mm", "en-us") .. " UTC", joinedS = math.floor(os.clock() - started), rooms = {}, again = {} }
	res.device = { w = math.floor(cam.ViewportSize.X), h = math.floor(cam.ViewportSize.Y), touch = UIS.TouchEnabled,
		quality = tostring(stat(function() return UserSettings():GetService("UserGameSettings").SavedQualityLevel end)) }
	local ok, err = pcall(function()
		status.Text = "Hub"; res.hub = measure(secs, nil) -- the normal camera, where the player stands
		cam.CameraType = Enum.CameraType.Scriptable
		for k = 1, N do
			status.Text = ("Room %d / %d"):format(k, N)
			local took = go("room", k, function() return room(k) end)
			local e = { k = k, load = took and math.floor(took * 100 + 0.5) / 100 or -1 }
			if took then task.wait(settle); for a, b in pairs(measure(secs, room(k):GetAttribute("Center"))) do e[a] = b end end
			res.rooms[k] = e
		end
		res.loaded = loadedRooms()
		status.Text = "Everything loaded: room 1 again"
		if go("room", 1, function() return room(1) end) then task.wait(settle); res.again.room1 = measure(secs, room(1):GetAttribute("Center")) end
		status.Text = "Hallway"
		if go("hallspawn", 0, function() return root:FindFirstChild("Hallway") end) then
			task.wait(settle); local h = root.Hallway.HallSpawn.Position; res.again.hall = measure(secs, h + Vector3.new(0, 5, 40))
		end
		status.Text = "Hub"
		go("hub", 0, nil); task.wait(settle)
		cam.CameraType = Enum.CameraType.Custom
		res.again.hub = measure(secs, nil)
		res.loadedEnd = loadedRooms(); res.instances = stat(function() return Stats.InstanceCount end)
	end)
	cam.CameraType = Enum.CameraType.Custom
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if hum then cam.CameraSubject = hum end
	if not ok then res.error = tostring(err) end
	-- the card
	local L, bad = {}, {}
	table.insert(L, ("ROOM TEST · %s · screen %dx%d · touch %s · quality %s"):format(res.at, res.device.w, res.device.h, tostring(res.device.touch), res.device.quality))
	if res.hub then table.insert(L, line("HUB", res.hub, "           ")) end
	for k = 1, N do
		local e = res.rooms[k]
		if not e then break end
		if e.load < 0 then table.insert(L, ("ROOM %02d   did not load in 20 s"):format(k)); table.insert(bad, k)
		else
			table.insert(L, line(("ROOM %02d"):format(k), e, ("load %4.2fs "):format(e.load)))
			if e.fps < 30 or e.low < 20 or e.load > 2 then table.insert(bad, k) end
		end
	end
	table.insert(L, ("EVERYTHING LOADED: %s of 12 rooms on this device"):format(tostring(res.loaded or "?")))
	if res.again.room1 then table.insert(L, line("ROOM 01", res.again.room1, "again      ")) end
	if res.again.hall then table.insert(L, line("HALLWAY", res.again.hall, "           ")) end
	if res.again.hub then table.insert(L, line("HUB", res.again.hub, "again      ")) end
	table.insert(L, ("graphics parts %s MB · instances %s · rooms still loaded %s"):format(tostring(res.hub and res.again.hub and res.again.hub.gfx or "?"), tostring(res.instances or "?"), tostring(res.loadedEnd or "?")))
	if res.error then table.insert(L, "STOPPED: " .. res.error) end
	table.insert(L, (#bad == 0 and not res.error) and "RESULT: PASS (every room 30+ fps, low 20+, loaded within 2 s)"
		or ("RESULT: CHECK rooms " .. table.concat(bad, ", ") .. " (under 30 fps, low under 20, or over 2 s to load)"))
	table.insert(L, "Screenshot this card and send it over.")
	body.Text = table.concat(L, "\n"); card.Visible = true
	status.Visible = false; running = false; tourB.Active = true; hallB.Active = true
	local json = Http:JSONEncode(res)
	gui:SetAttribute("LastResult", json)
	net.Report:FireServer(json)
	return json
end
tourB.Activated:Connect(function() task.spawn(tour, false) end)
hallB.Activated:Connect(function()
	if running then return end
	task.spawn(function() pcall(go, "hallspawn", 0, function() return root:FindFirstChild("Hallway") end) end)
end)
local run = Instance.new("BindableFunction"); run.Name = "Run"; run.OnInvoke = function(fast) return tour(fast == true) end; run.Parent = gui
]==]
client.Parent = game:GetService("StarterPlayer").StarterPlayerScripts

local same = true; for _, n in ipairs(roomParts) do if n ~= TARGET then same = false end end
return ("ROOM TEST BUILT: %d rooms x %s parts (%s), hallway %d parts, %d new lights; hub %s..%s, rooms from x=%d; streaming=%s, Persistent: %s; top-level folders (stream by distance): %s")
	:format(N, tostring(roomParts[1]), same and "all equal" or "UNEQUAL", hall:GetAttribute("Parts"), 0,
		tostring(Vector3.new(math.floor(lo.X), math.floor(lo.Y), math.floor(lo.Z))), tostring(Vector3.new(math.floor(hi.X), math.floor(hi.Y), math.floor(hi.Z))),
		math.floor(hi.X + 4000), tostring(workspace.StreamingEnabled), table.concat(persistent, ", "), #folders > 0 and table.concat(folders, ", ") or "none")
