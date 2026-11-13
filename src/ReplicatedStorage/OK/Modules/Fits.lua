-- OK Studio Fits: the wearable gear (Config.Gear kind "fit") built from plain parts. Systems/Gear calls it on the
-- server (Publish and every respawn), so everyone sees the fit.
-- Fits.Apply(character, fitIds) takes off every OK_Fit_* model, then builds each listed fit, where a fit id is the gear
-- item's `fit` key ("cuban", "snapback", "shades"), as a Model "OK_Fit_<id>". Its parts are massless, never collide,
-- touch or answer raycasts, and are welded (WeldConstraint) to the torso (UpperTorso on R15, Torso on R6) or the Head.
-- An unknown id, or a character without that body part, is skipped. Shapes only: no meshes, images or decals.
local RS = game:GetService("ReplicatedStorage")
local Theme = require(RS.OK.Modules.UITheme)
local M = {}
M.PREFIX = "OK_Fit_"
local GOLD = Color3.fromRGB(235, 185, 60)
local LENS = Color3.fromRGB(14, 14, 18)
local FRAME = Color3.fromRGB(30, 30, 34)
-- each fit's own colour, by fit key (read only): the closet's hangers (Modules/RoomItems.Hangers, the Your Rooms plan,
-- Task 12) and the closet panel's swatches (Modules/PanelUI) show a fit in the colour it is built in
M.Colors = { cuban = GOLD, snapback = Theme.accent, shades = LENS }

-- one part of a fit at world CFrame `cf`, welded to `anchor`; `props` first, so a Shape is set before the Size
local function piece(model, anchor, name, size, cf, color, props)
	local p = Instance.new("Part")
	if props then for k, v in pairs(props) do p[k] = v end end
	p.Name = name; p.Size = size; p.CFrame = cf; p.Color = color
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = false; p.Massless = true; p.CastShadow = false
	p.CanCollide = false; p.CanTouch = false; p.CanQuery = false -- CanQuery only turns off once CanCollide is off
	local w = Instance.new("WeldConstraint"); w.Part0 = anchor; w.Part1 = p; w.Parent = p
	p.Parent = model
	return p
end
local function bodyPart(character, ...)
	for _, name in ipairs({ ... }) do
		local p = character:FindFirstChild(name)
		if p and p:IsA("BasePart") then return p end
	end
	return nil
end
-- the head's visible size: an R6 head is a 2 x 1 x 1 part drawn about 1.2 studs wide, an R15 head about 1.2 x 1.2 x 1.2
local function headScale(head) return math.min(head.Size.X, head.Size.Y * 1.2, head.Size.Z * 1.2) end

local BUILD = {}
-- a Cuban link chain: 10 gold links in a ring round the neck, tilted forward so the front lies on the chest
function BUILD.cuban(model, character)
	local torso = bodyPart(character, "UpperTorso", "Torso")
	if not torso then return false end
	local s = torso.Size
	local ring = torso.CFrame * CFrame.new(0, s.Y / 2 + 0.06, 0) * CFrame.Angles(math.rad(-20), 0, 0)
	local rx, rz = 0.7, s.Z / 2 + 0.12
	for i = 0, 9 do
		local a = i * math.pi / 5 -- 0 = the front (-Z), round through the right shoulder
		local x, z = rx * math.sin(a), -rz * math.cos(a)
		local yaw = math.atan2(-rz * math.sin(a), rx * math.cos(a)) -- each link along the ring
		piece(model, torso, "Link" .. (i + 1), Vector3.new(0.3, 0.12, 0.16), ring * CFrame.new(x, 0, z) * CFrame.Angles(0, yaw, 0), GOLD,
			{ Material = Enum.Material.Metal, Reflectance = 0.25 })
	end
	return true
end
-- a snapback in the theme's accent colour: a crown over the top of the head and a flat brim at the front
function BUILD.snapback(model, character)
	local head = bodyPart(character, "Head")
	if not head then return false end
	local k = headScale(head)
	piece(model, head, "Crown", Vector3.new(0.4 * k, 1.08 * k, 1.08 * k), head.CFrame * CFrame.new(0, 0.36 * k, 0.02 * k) * CFrame.Angles(0, 0, math.rad(90)),
		Theme.accent, { Shape = Enum.PartType.Cylinder, Material = Enum.Material.SmoothPlastic })
	piece(model, head, "Brim", Vector3.new(0.9 * k, 0.07, 0.5 * k), head.CFrame * CFrame.new(0, 0.2 * k, -0.68 * k), Theme.accent,
		{ Material = Enum.Material.SmoothPlastic })
	return true
end
-- shades: two dark lenses and a bridge across the front of the head
function BUILD.shades(model, character)
	local head = bodyPart(character, "Head")
	if not head then return false end
	local k = headScale(head)
	local z = -(0.5 * k + 0.03)
	piece(model, head, "LensL", Vector3.new(0.34 * k, 0.2 * k, 0.05), head.CFrame * CFrame.new(-0.2 * k, 0.08 * k, z), LENS,
		{ Material = Enum.Material.SmoothPlastic, Reflectance = 0.3 })
	piece(model, head, "LensR", Vector3.new(0.34 * k, 0.2 * k, 0.05), head.CFrame * CFrame.new(0.2 * k, 0.08 * k, z), LENS,
		{ Material = Enum.Material.SmoothPlastic, Reflectance = 0.3 })
	piece(model, head, "Bridge", Vector3.new(0.1 * k, 0.04 * k, 0.04), head.CFrame * CFrame.new(0, 0.12 * k, z), FRAME,
		{ Material = Enum.Material.SmoothPlastic })
	return true
end

-- takes every fit off `character`, then puts on `fitIds` (fit keys, in order); returns how many it built
function M.Apply(character, fitIds)
	if typeof(character) ~= "Instance" then return 0 end
	for _, c in ipairs(character:GetChildren()) do
		if c.Name:sub(1, #M.PREFIX) == M.PREFIX then c:Destroy() end
	end
	local built = 0
	for _, id in ipairs(type(fitIds) == "table" and fitIds or {}) do
		local build = BUILD[id]
		if build and not character:FindFirstChild(M.PREFIX .. id) then
			local model = Instance.new("Model")
			model.Name = M.PREFIX .. id
			if build(model, character) then model.Parent = character; built += 1 else model:Destroy() end
		end
	end
	return built
end

return M
