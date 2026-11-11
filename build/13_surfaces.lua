-- 13: surface and value pass (+0 lights, built-in materials only, no image uploads). Run after 02-05.
-- Lit ceilings with beams, cooler walls against warm floors, leather seating, carpet, foam with depth.
local L = require(game:GetService("ReplicatedStorage").OK.BuildLib)
local B = "13_surfaces"
L.clear(B)
local S = workspace.OKStudio
local C = L.C
local changed = 0
local function set(part, props) for k, v in pairs(props) do part[k] = v end; changed += 1 end

-- ceilings: a dark charcoal that still reads under the lamps, plus beams so the ceiling has structure
for _, p in ipairs(S.Shell:GetChildren()) do
	if p:IsA("BasePart") and p.Name:match("^Ceiling_") then
		set(p, { Color = Color3.fromRGB(38, 38, 44), Material = Enum.Material.Concrete })
	end
end
local beams = L.model(S.Shell, "Beams")
local function beamsFor(x0, x1, z0, z1, y, every)
	local x = x0 + every / 2
	while x < x1 do
		L.boxMM(beams, "Beam", x - 0.35, y - 0.6, z0 + 0.5, x + 0.35, y, z1 - 0.5, { Color = Color3.fromRGB(26, 24, 24), Material = Enum.Material.Wood })
		x += every
	end
end
beamsFor(12, 44, -12, 12, 12, 6.4)   -- lounge
beamsFor(44, 80, -12, 12, 12, 7.2)   -- control room
beamsFor(0, 12, 0, 10, 10, 4)        -- corridor
-- walls: cooler and a touch lighter so they separate from the warm floors
for _, p in ipairs(S.Shell:GetChildren()) do
	if p:IsA("BasePart") and p.Name:match("^Wall_") and p.Material == Enum.Material.Concrete then
		set(p, { Color = Color3.fromRGB(36, 38, 46) })
	end
end
-- floors: carpet where people sit and record
if S.Shell:FindFirstChild("Floor_Control") then set(S.Shell.Floor_Control, { Material = Enum.Material.Carpet, Color = Color3.fromRGB(44, 40, 44) }) end
if S.Shell:FindFirstChild("Floor_Booth") then set(S.Shell.Floor_Booth, { Material = Enum.Material.Carpet, Color = Color3.fromRGB(40, 34, 40) }) end
-- seating: leather
local leather = Color3.fromRGB(46, 30, 26)
for _, room in ipairs({ S.Lounge, S.ControlRoom }) do
	for _, p in ipairs(room:GetDescendants()) do
		if p:IsA("BasePart") and (p.Name:match("^Sofa_") or p.Name:match("^Couch_") or p.Name:match("^Chair_Seat") or p.Name:match("^Chair_Back") or p.Name:match("^Stool_%d")) then
			set(p, { Material = Enum.Material.Leather, Color = leather })
		end
	end
end
-- foam: alternate tile depth so the grid reads as relief, not a flat checkerboard
local i = 0
for _, p in ipairs(S.VocalBooth:GetChildren()) do
	if p:IsA("BasePart") and p.Name:match("^Foam_") then
		i += 1
		local deep = (i % 2 == 0)
		local axis = p.Name == "Foam_E" and "X" or "Z"
		local size = p.Size
		local depth = deep and 0.55 or 0.25
		if axis == "X" then
			local face = p.Position.X + size.X / 2 -- wall-side face stays put
			p.Size = Vector3.new(depth, size.Y, size.Z); p.Position = Vector3.new(face - depth / 2, p.Position.Y, p.Position.Z)
		else
			local sign = p.Position.Z > 0 and 1 or -1
			local face = p.Position.Z + sign * size.Z / 2
			p.Size = Vector3.new(size.X, size.Y, depth); p.Position = Vector3.new(p.Position.X, p.Position.Y, face - sign * depth / 2)
		end
		p.Material = Enum.Material.Fabric
		changed += 1
	end
end
L.markAll(beams, B)
return string.format("surfaces: %d parts restyled, %d beams, studio parts=%d", changed, #beams:GetChildren(), L.count(S))
