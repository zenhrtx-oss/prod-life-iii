-- Edit check (Wave 3 Task 5d): the visitors' look B as Roblox builds it, from Modules/VisitorLooks (the recipes, pure)
-- through Modules/VisitorFigure (the parts). Both modules load fresh, as clones in one temporary folder (VisitorFigure
-- requires its sibling VisitorLooks), so a sync takes effect without a restart.
-- (1) VisitorLooks' maths is Roblox's: Math.Angles against CFrame.Angles and Math.Mul against CFrame multiplication over a
--     spread of angles (every recipe placement is built from these two), within 1e-5.
-- (2) Every look: each person (VisitorLooks.Ids(), every id the content sends in person: the spec checks that), the pigeon
--     and the fallback (Generic). VisitorFigure.Build makes one part per recipe part: 13-16 for a person, at most 12 for the
--     pigeon (t42's limits), named as the recipe, a WedgePart exactly for a "Wedge", the recipe's Shape, Size, Color and
--     Material (SmoothPlastic or Neon), anchored, CanCollide / CanQuery / CanTouch off, no shadow; the head and primary
--     parts are the look's. Posed by VisitorFigure.Pose at a turned base and at swings 0, 0.45 and -0.6, every part sits
--     where base * VisitorLooks.Pose puts it (position 1e-3, rotation 1e-4).
-- (3) Every portrait (VisitorFigure.Portrait with VisitorLooks.Frame): a ViewportFrame "View" whose CurrentCamera is its
--     own child Camera at the frame's fov, from and at, holding a Model "Figure" (VisitorId = the look's id) with the
--     look's part count; one copy per call.
-- (4) SetPortrait, the cards' helper (fix round 1): an id with no recipe and a sig gets the look its walker gets
--     (VisitorLooks.Resolve: the same part names, the sig's pieces); a second call replaces the copy (one View); a
--     phone-only sender with { person = true } gets no face; who = nil clears it.
-- Builds nothing in the workspace (every model is parented to nil or to its ViewportFrame), yields after each look, and
-- destroys everything at the end, also on an error. Red before the sync: the modules are not in the place.
local RS = game:GetService("ReplicatedStorage")
local Mods = RS.OK.Modules
assert(Mods:FindFirstChild("VisitorLooks") and Mods:FindFirstChild("VisitorFigure"),
	"Modules.VisitorLooks / Modules.VisitorFigure are not in the place: look B (Task 5d) is not synced")
-- edit-mode require caches modules across runs: load clones, side by side in one folder (VisitorFigure requires its
-- sibling VisitorLooks), so edits take effect; the folder goes as soon as both are loaded
local fresh = Instance.new("Folder"); fresh.Name = "_t89_fresh"; fresh.Parent = RS.OK
local loaded, Looks, Figure = pcall(function()
	local l, f = Mods.VisitorLooks:Clone(), Mods.VisitorFigure:Clone()
	l.Parent, f.Parent = fresh, fresh
	return require(l), require(f)
end)
fresh:Destroy()
if not loaded then error(Looks, 0) end
local M = Looks.Math
local made = {} -- everything this check built, destroyed at the end

local function cf(t) return CFrame.new(table.unpack(t)) end
local function near(a, b, eps) return math.abs(a - b) <= eps end
local function sameCF(a, b, pe, re)
	local ac, bc = { a:GetComponents() }, { b:GetComponents() }
	for i = 1, 12 do if not near(ac[i], bc[i], i <= 3 and pe or re) then return false, i, ac[i], bc[i] end end
	return true
end

local function run()
	-- 1. the maths
	local worst, n1 = 0, 0
	for _, rx in ipairs({ -2.1, -0.6, 0, 0.45, 1.3, 2.9 }) do
		for _, ry in ipairs({ -1.7, 0, 0.35, math.pi / 2, 3.0 }) do
			for _, rz in ipairs({ -0.8, 0, 0.2, 1.57 }) do
				local mine, theirs = cf(M.Angles(rx, ry, rz)), CFrame.Angles(rx, ry, rz)
				local ok, i, a, b = sameCF(mine, theirs, 1e-5, 1e-5)
				if not ok then error(string.format("Math.Angles(%g, %g, %g) differs from CFrame.Angles at component %d: %.6f vs %.6f", rx, ry, rz, i, a, b), 0) end
				local p = M.At(0.3, -1.2, 2.5, math.deg(rz), math.deg(rx), math.deg(ry))
				local mul = cf(M.Mul(M.Mul(p, M.Angles(rx, ry, rz)), M.New(-0.4, 0.9, 0.1)))
				local rb = cf(p) * CFrame.Angles(rx, ry, rz) * CFrame.new(-0.4, 0.9, 0.1)
				ok, i, a, b = sameCF(mul, rb, 1e-5, 1e-5)
				if not ok then error(string.format("Math.Mul differs from CFrame multiplication at component %d: %.6f vs %.6f", i, a, b), 0) end
				n1 += 2
				worst = math.max(worst, (mine.Position - theirs.Position).Magnitude)
			end
		end
	end

	-- 2. every look, built and posed
	local looks = {}
	for _, id in ipairs(Looks.Ids()) do table.insert(looks, Looks.For(id)) end
	table.insert(looks, Looks.Pigeon())
	table.insert(looks, Looks.Generic("cowboy_hat", { 255, 60, 160 }))
	local BASE = CFrame.new(10, 0, -5) * CFrame.Angles(0, 0.7, 0)
	local counts, wedges = {}, 0
	for _, look in ipairs(looks) do
		local id = look.id
		local model = Instance.new("Model")
		table.insert(made, model)
		local list, head, primary = Figure.Build(look, model)
		local n = #model:GetChildren()
		if look.kind == "critter" then assert(n >= 1 and n <= 12, id .. ": " .. n .. " parts (the critter's limit is 12)")
		else assert(n >= 13 and n <= 16, id .. ": " .. n .. " parts (want 13..16)") end
		assert(#list == #look.parts and n == #look.parts, id .. ": built " .. n .. " parts for a recipe of " .. #look.parts)
		assert(head and head.Name == look.head and primary and primary.Name == look.primary, id .. ": head / primary not the look's " .. look.head .. " / " .. look.primary)
		for i, e in ipairs(look.parts) do
			local part = list[i].part
			assert(part.Name == e.n and part.Parent == model, id .. ": part " .. i .. " is " .. part.Name .. ", want " .. e.n)
			assert(part:IsA(e.sh == "Wedge" and "WedgePart" or "Part") and (e.sh == "Wedge") == part:IsA("WedgePart"), id .. " " .. e.n .. ": class " .. part.ClassName)
			if e.sh == "Wedge" then wedges += 1 end
			if part:IsA("Part") then
				local want = e.sh == "Ball" and Enum.PartType.Ball or (e.sh == "Cylinder" and Enum.PartType.Cylinder or Enum.PartType.Block)
				assert(part.Shape == want, id .. " " .. e.n .. ": shape " .. part.Shape.Name .. ", want " .. want.Name)
			end
			assert((part.Size - Vector3.new(e.s[1], e.s[2], e.s[3])).Magnitude < 1e-4, id .. " " .. e.n .. ": size " .. tostring(part.Size))
			assert(part.Color == Color3.fromRGB(e.c[1], e.c[2], e.c[3]), id .. " " .. e.n .. ": colour " .. tostring(part.Color))
			assert(part.Material == (e.m == "Neon" and Enum.Material.Neon or Enum.Material.SmoothPlastic), id .. " " .. e.n .. ": material " .. part.Material.Name)
			assert(part.Anchored and not part.CanCollide and not part.CanQuery and not part.CanTouch and not part.CastShadow,
				id .. " " .. e.n .. ": not anchored / colliding / queried / touched / casting a shadow")
		end
		for _, swing in ipairs({ 0, 0.45, -0.6 }) do
			Figure.Pose(list, BASE, swing)
			for i, e in ipairs(look.parts) do
				local ok, k, a, b = sameCF(list[i].part.CFrame, BASE * cf(Looks.Pose(e, swing)), 1e-3, 1e-4)
				if not ok then error(string.format("%s %s at swing %g: posed component %d is %.5f, the recipe says %.5f", id, e.n, swing, k, a, b), 0) end
			end
		end
		table.insert(counts, id .. " " .. n)
		task.wait()
	end

	-- 3. every portrait
	local views = 0
	for _, look in ipairs(looks) do
		local fr = Looks.Frame(look)
		local vf = Figure.Portrait(look, fr, { name = "View", corner = 8 })
		table.insert(made, vf)
		assert(vf:IsA("ViewportFrame") and vf.Name == "View", look.id .. ": the portrait is not a ViewportFrame named View")
		local cam = vf.CurrentCamera
		assert(cam and cam:IsA("Camera") and cam.Parent == vf, look.id .. ": the portrait's CurrentCamera is not its own child Camera")
		assert(near(cam.FieldOfView, fr.fov, 1e-3), look.id .. ": the camera's fov " .. cam.FieldOfView .. ", want " .. fr.fov)
		local want = CFrame.lookAt(Vector3.new(table.unpack(fr.from)), Vector3.new(table.unpack(fr.at)))
		assert(sameCF(cam.CFrame, want, 1e-3, 1e-4), look.id .. ": the camera is not at the frame's from / at")
		local fig = vf:FindFirstChild("Figure")
		assert(fig and fig:IsA("Model") and fig:GetAttribute("VisitorId") == look.id, look.id .. ": no Figure model with VisitorId " .. look.id)
		assert(#fig:GetChildren() == #look.parts, look.id .. ": the portrait's figure has " .. #fig:GetChildren() .. " parts, the look " .. #look.parts)
		local n = 0
		for _, d in ipairs(vf:GetChildren()) do if d:IsA("ViewportFrame") or d:IsA("Model") then n += 1 end end
		assert(n == 1, look.id .. ": the portrait holds " .. n .. " figures (one copy per call)")
		views += 1
		task.wait()
	end
	-- 4. the cards' helper
	local holder = Instance.new("Frame")
	table.insert(made, holder)
	local color = { 255, 60, 160 }
	local v1 = Figure.SetPortrait(holder, { id = "t89_nobody", sig = "cowboy_hat", color = color })
	local walker = Looks.Resolve("t89_nobody", "cowboy_hat", color)
	assert(v1 and v1.Parent == holder and v1.Name == "View", "SetPortrait built no View in its holder")
	local names = {}
	for _, d in ipairs(v1.Figure:GetChildren()) do names[d.Name] = true end
	for _, e in ipairs(walker.parts) do assert(names[e.n], "SetPortrait's figure for a recipe-less id has no " .. e.n .. " (its walker's look has)") end
	assert(#v1.Figure:GetChildren() == #walker.parts and names.HatBrim, "SetPortrait's figure is not the walker's (the fallback wearing its sig)")
	local v2 = Figure.SetPortrait(holder, { id = "navx", sig = "cowboy_hat", color = color })
	local n = 0
	for _, d in ipairs(holder:GetChildren()) do if d:IsA("ViewportFrame") then n += 1 end end
	assert(v2 and n == 1 and v1.Parent == nil and v2.Figure:GetAttribute("VisitorId") == "navx", "a second SetPortrait did not replace the first copy (" .. n .. " Views)")
	assert(Figure.SetPortrait(holder, { id = "feed" }, { person = true }) == nil and holder:FindFirstChild("View") == nil, "a phone-only sender got a face (or the old copy stayed)")
	Figure.SetPortrait(holder, { id = "navx" }, { person = true })
	assert(holder:FindFirstChild("View") and Figure.SetPortrait(holder, nil) == nil and holder:FindFirstChild("View") == nil, "SetPortrait(holder, nil) did not clear the face")
	return string.format("T89 OK: maths = Roblox's (%d checks, worst %.1e); %d looks built and posed at 3 swings to the recipe (%s; %d wedge noses); %d portraits with their own camera; SetPortrait: a recipe-less id wears its walker's look, one copy, no face for a sender, cleared by nil",
		n1, worst, #looks, table.concat(counts, ", "), wedges, views)
end

local ok, res = pcall(run)
for _, x in ipairs(made) do pcall(function() x:Destroy() end) end
if not ok then error(res, 0) end
return res
