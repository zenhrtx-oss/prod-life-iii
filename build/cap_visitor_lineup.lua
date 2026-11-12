-- Capture (Edit mode; Wave 3 Task 5d): every visitor's look B as the game builds it (Modules/VisitorLooks through
-- Modules/VisitorFigure, loaded fresh), for the user's lineup capture. Not a test; test.py never runs it. Remove it with
-- build/cap_visitor_lineup_remove.lua before any build, test or snapshot script runs (01_backup_scaffold moves stray
-- workspace children, room_test reads the hub's bounds from every Folder).
-- Everything goes in ONE Folder, workspace.OK_LookLineup (Archivable = false: never saved), in two closed rooms in empty
-- space west of the hub (X -926 .. -800, Y -4 .. 30, Z -40 .. 16; research/visitor_look_2026-11-05's lineup used the same
-- box and found it clear); it checks that box first and builds nothing if any other part is in it. Lighting is not
-- touched (03_lighting's night sky is why the rooms are closed). Re-running replaces the folder.
--   GROUP    three bleacher tiers, every person in Data/WalkIns order (10 a row), then the pigeon, the fallback (an id with
--            no recipe, here wearing the cowboy hat) and the hometown kid mid-stride (the limbs swing separately); names on
--            the tier fronts.
--   PROFILE  eight figures in pairs on a stage: each side-on (facing the camera's left) beside the same one front-on, for
--            the wedge noses (the vertical face against the head, the slope running down and forward to the tip at the
--            bottom), the rep's quiff (high at the front), the hats, cups and the headset.
-- Returns a one-line summary with the cameras (FieldOfView 70; set workspace.CurrentCamera.CFrame to one).
local RS = game:GetService("ReplicatedStorage")
local function freshRequire(mod)
	local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name
	local ok, res = pcall(require, c); c:Destroy(); if not ok then error(res) end; return res
end
local Looks = freshRequire(RS.OK.Modules.VisitorLooks)
local Figure = freshRequire(RS.OK.Modules.VisitorFigure)
local Content = freshRequire(RS.OK.Data.WalkIns)
local Config = freshRequire(RS.OK.Config)
local FOLDER, ORIGIN = "OK_LookLineup", Vector3.new(-900, 0, 0)
local V, CF, RGB = Vector3.new, CFrame.new, Color3.fromRGB
local WALL, FLOOR, BACK, TEXT = RGB(118, 114, 128), RGB(84, 80, 92), RGB(138, 134, 150), RGB(235, 235, 235)

local old = workspace:FindFirstChild(FOLDER)
while old do old:Destroy(); old = workspace:FindFirstChild(FOLDER) end
local lo, hi = ORIGIN + V(-26, -6, -40), ORIGIN + V(100, 32, 16)
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("BasePart") and not d:IsA("Terrain") then
		local p, r = d.Position, d.Size.Magnitude / 2
		if p.X + r > lo.X and p.X - r < hi.X and p.Y + r > lo.Y and p.Y - r < hi.Y and p.Z + r > lo.Z and p.Z - r < hi.Z then
			return "ABORT: a part is already inside the lineup box (" .. d:GetFullName() .. "); nothing built"
		end
	end
end
local root = Instance.new("Folder"); root.Name = FOLDER; root.Archivable = false

local function slab(parent, name, cframe, size, color)
	local p = Instance.new("Part")
	p.Name = name; p.Size = size; p.CFrame = cframe; p.Color = color; p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.Parent = parent
	return p
end
-- a closed room centred on local x = cx: inside x cx-hw..cx+hw, z z0..z1, y 0..h
local function room(name, cx, hw, z0, z1, h)
	local m = Instance.new("Model"); m.Name = name; m.Parent = root
	local w, d, zc, o = 2 * hw + 8, (z1 - z0) + 8, (z0 + z1) / 2, ORIGIN + V(cx, 0, 0)
	slab(m, "Floor", CF(o + V(0, -2, zc)), V(w, 4, d), FLOOR)
	slab(m, "Roof", CF(o + V(0, h + 2, zc)), V(w, 4, d), WALL)
	slab(m, "WallBack", CF(o + V(0, h / 2, z1 + 2)), V(w, h + 8, 4), BACK)
	slab(m, "WallFront", CF(o + V(0, h / 2, z0 - 2)), V(w, h + 8, 4), WALL)
	slab(m, "WallLeft", CF(o + V(-hw - 2, h / 2, zc)), V(4, h + 8, d), WALL)
	slab(m, "WallRight", CF(o + V(hw + 2, h / 2, zc)), V(4, h + 8, d), WALL)
	return m, o
end
local function text(part, face, lines) -- labels on a part's face (unlit)
	local g = Instance.new("SurfaceGui")
	g.Face = face; g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; g.PixelsPerStud = 50; g.LightInfluence = 0; g.Parent = part
	for _, l in ipairs(lines) do
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1; t.Font = Enum.Font.GothamBlack; t.TextScaled = true; t.TextWrapped = true
		t.TextColor3 = l.color or TEXT; t.Text = l.text; t.Position = UDim2.fromOffset(l.x * 50, l.y * 50); t.Size = UDim2.fromOffset(l.w * 50, l.h * 50)
		t.Parent = g
	end
end
local built = { figures = 0, parts = 0 }
-- a look standing at `at` (feet on it), facing `face` (a unit vector), at a swing
local function stand(parent, look, at, face, swing, name)
	local m = Instance.new("Model"); m.Name = name or look.id
	local list, _, primary = Figure.Build(look, m)
	Figure.Pose(list, CFrame.lookAt(at, at + face), swing or 0)
	m.PrimaryPart = primary
	m.Parent = parent
	built.figures += 1; built.parts += #list
	return m
end

local names = Content.Names(Config.WalkIns.Roster)
local function nameOf(id) return (string.gsub(names[id] or id, "{sponsor}", Content.SponsorName("energy", Config.WalkIns.Roster) or "A SPONSOR")) end
local cast = {}
for _, v in ipairs(Content.Visitors) do
	if Looks.IsPerson(v.id) then table.insert(cast, { look = Looks.For(v.id), label = nameOf(v.id) }) end
end
table.insert(cast, { look = Looks.Pigeon(), label = nameOf("pigeon") })
table.insert(cast, { look = Looks.Generic("cowboy_hat", { 255, 60, 160 }), label = "FALLBACK (NO RECIPE, A SIG)" })
table.insert(cast, { look = Looks.For("homekid"), label = "MID-STRIDE", swing = 0.45 })

-- GROUP: 10 a row on three tiers, facing the camera (-Z), turned a little
local PER, GAP = 10, 3.3
local TIERS = { { z = -6, top = 1.2 }, { z = 0, top = 5.7 }, { z = 6, top = 10.2 } }
local HALF = 18 -- the tiers' half width
local group, go = room("Group", 0, 19, -36, 12, 28)
for t = 1, 3 do
	local tier = TIERS[t]
	slab(group, "Tier" .. t, CF(go + V(0, tier.top / 2, tier.z)), V(2 * HALF, tier.top, 6), RGB(70 + 8 * t, 66 + 8 * t, 78 + 8 * t))
	-- the names on the tier's front face (a Front face's text runs from the part's +X end: x from the left is HALF - x)
	local front = slab(group, "Names" .. t, CF(go + V(0, tier.top - 0.6, tier.z - 3.05)), V(2 * HALF, 0.8, 0.1), RGB(24, 24, 30))
	local lines = {}
	for c = 1, PER do
		local e = cast[(t - 1) * PER + c]
		if e then
			local x = (c - (PER + 1) / 2) * GAP
			stand(group, e.look, go + V(x, tier.top, tier.z), Vector3.new(math.sin(math.rad(8)), 0, -math.cos(math.rad(8))), e.swing, e.look.id)
			table.insert(lines, { text = e.label, x = HALF - x - GAP / 2 + 0.1, y = 0.05, w = GAP - 0.2, h = 0.7, color = TEXT })
		end
	end
	text(front, Enum.NormalId.Front, lines)
end
for i = 3 * PER + 1, #cast do -- anything past three rows stands on the floor in front
	local e = cast[i]
	stand(group, e.look, go + V((i - 3 * PER - 0.5) * GAP, 0, -12), Vector3.new(0, 0, -1), e.swing, e.look.id)
end

-- PROFILE: eight pairs on a stage: side-on (facing +X: the camera's left, it looks along +Z) beside the same front-on
local PICK = { "navx", "rep", "mom", "blogger", "homekid", "llama", "booker", "rapper" }
local prof, po = room("Profile", 70, 22, -20, 8, 20)
local stage = slab(prof, "Stage", CF(po + V(0, 0.5, 0)), V(40, 1, 6), RGB(70, 66, 78))
local plines = {}
local pairX = {}
for i, id in ipairs(PICK) do
	local x = (i - (#PICK + 1) / 2) * 4.6
	pairX[id] = x
	local look = Looks.For(id)
	stand(prof, look, po + V(x + 1.1, 1, 0), Vector3.new(1, 0, 0), 0, id .. "_side")
	stand(prof, look, po + V(x - 1.1, 1, 0), Vector3.new(0, 0, -1), 0, id .. "_front")
	table.insert(plines, { text = nameOf(id), x = 20 - x - 2.2, y = 0.05, w = 4.4, h = 0.8, color = TEXT })
end
text(stage, Enum.NormalId.Front, plines)

root.Parent = workspace
local function cam(name, from, to)
	return string.format("%s CFrame.lookAt(Vector3.new(%g, %g, %g), Vector3.new(%g, %g, %g))", name, from.X, from.Y, from.Z, to.X, to.Y, to.Z)
end
local cams = {
	cam("whole", go + V(0, 16, -34), go + V(0, 9.5, 2)),
	cam("row1", go + V(0, 5.4, -20), go + V(0, 5.0, -6)),
	cam("row2", go + V(0, 9.9, -15), go + V(0, 9.5, 0)),
	cam("row3", go + V(0, 14.4, -10), go + V(0, 14.0, 6)),
	cam("profile_all", po + V(0, 5.0, -16), po + V(0, 4.2, 0)),
	cam("profile_navx", po + V(pairX.navx, 6.7, -4.5), po + V(pairX.navx, 6.5, 0)),
	cam("profile_rep", po + V(pairX.rep, 6.7, -4.5), po + V(pairX.rep, 6.5, 0)),
}
return string.format("OK_LookLineup built: %d figures, %d parts (%d people, the pigeon, the fallback, the kid mid-stride; %d side/front heads); cams FOV 70: %s",
	built.figures, built.parts, #cast - 3, 2 * #PICK, table.concat(cams, "; "))
