-- OK Studio RoomItems (the Your Rooms plan, Task 7; Task 9 adds Build): the things that stand in your rooms, built from
-- plain Parts. No uploads, no MeshParts (the bedroom asset already spends 55 of a room's 56), no lights, no tags, no
-- scripts. Every model comes back unparented with its pivot at the origin, on the surface it stands on (a floor or a
-- desk top) at its footprint's centre, its front facing -Z: a caller PivotTo's it onto an anchor (an Attachment's
-- WorldCFrame, whose LookVector is the way the item faces).
-- * Build(id, catalog) -> Model?: a placed item (Data/RoomCatalog) from its recipe, one Part per recipe part (a WedgePart
--   for "Wedge"), named as the recipe names it, SmoothPlastic or Neon. Every part is anchored and never collides or
--   touches, but it does answer a raycast (CanQuery true: a tap in decorate mode selects it); a part whose longest side
--   is under SMALL studs casts no shadow. The model is named for the id and carries the attribute ItemId; its pivot is
--   the origin (WorldPivot at 0, 0, 0, no PrimaryPart). nil for an id the catalog doesn't know. No lights, no scripts.
-- * Speakers(tier) -> Model?: one desk speaker for a Config.Rooms.Speakers tier; nil for tier 1 (the laptop's own
--   speakers) and for an unknown tier. Tier 2 (spk_monitors, "Desk monitors") is a small black cabinet with a woofer and
--   a tweeter; tier 3 (spk_studio, "Studio monitors") is bigger, with a metal ring round the woofer and a blue power
--   LED (Neon material, not a light). Its PrimaryPart "Cabinet" is where a room play's sounds come from
--   (StarterPlayerScripts/OK/RoomClient). Every part is anchored, never collides, touches or answers a raycast, and casts
--   no shadow. The model carries Tier = tier and RoomItem = "speaker" (Systems/Rooms replaces only what it made).
-- Sizes are studs at the hub's scale (about 0.25 m a stud: tier 2 about 18 x 26 x 21 cm, tier 3 about 24 x 38 x 26 cm),
-- so a pair sits on the bedroom desk's Desk_Speaker_L / _R anchors either side of the laptop.
local M = {}

local SPEAKERS = {
	[2] = { w = 0.7, h = 1.05, d = 0.85, woofer = 0.5, wooferY = 0.36, tweeter = 0.2, tweeterY = 0.82,
		body = Color3.fromRGB(22, 22, 24), cone = Color3.fromRGB(40, 40, 44) },
	[3] = { w = 0.95, h = 1.5, d = 1.05, woofer = 0.72, wooferY = 0.5, tweeter = 0.26, tweeterY = 1.14,
		body = Color3.fromRGB(16, 16, 18), cone = Color3.fromRGB(205, 160, 40), ring = Color3.fromRGB(185, 185, 192),
		led = Color3.fromRGB(80, 170, 255), ledY = 1.38 },
}
M.SpeakerSpecs = SPEAKERS -- read only: the sizes, for a caller's checks

local AXIS_Z = CFrame.Angles(0, math.pi / 2, 0) -- a Cylinder's axis is its X: turned onto Z, its round face looks along -Z

local function part(model, name, size, cf, color, props, class)
	local p = Instance.new(class or "Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	if props then for k, v in pairs(props) do p[k] = v end end
	p.Parent = model
	return p
end
-- a disc on the cabinet's front face (z = -d/2), `t` thick, standing `out` proud of it
local function disc(model, name, dia, y, s, t, out, color, props)
	local z = -s.d / 2 - t / 2 + out
	local p = part(model, name, Vector3.new(t, dia, dia), CFrame.new(0, y, z) * AXIS_Z, color, props)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local SHAPES = { Ball = Enum.PartType.Ball, Cylinder = Enum.PartType.Cylinder }
M.SMALL = 1.5 -- studs: a part whose longest side is under this casts no shadow

function M.Build(id, catalog)
	local item = type(catalog) == "table" and type(catalog.ById) == "table" and catalog.ById[id] or nil
	if type(item) ~= "table" or type(item.parts) ~= "table" then return nil end
	local m = Instance.new("Model")
	m.Name = tostring(item.id)
	m:SetAttribute("ItemId", item.id)
	for _, e in ipairs(item.parts) do
		local size = Vector3.new(e.s[1], e.s[2], e.s[3])
		local p = part(m, e.n, size, CFrame.new(table.unpack(e.cf)), Color3.fromRGB(e.c[1], e.c[2], e.c[3]), {
			Material = e.m == "Neon" and Enum.Material.Neon or Enum.Material.SmoothPlastic,
			CanQuery = true,
			CastShadow = math.max(size.X, size.Y, size.Z) >= M.SMALL,
		}, e.sh == "Wedge" and "WedgePart" or "Part")
		if SHAPES[e.sh] then p.Shape = SHAPES[e.sh] end
	end
	m.WorldPivot = CFrame.new()
	return m
end

function M.Speakers(tier)
	local s = SPEAKERS[tier]
	if not s then return nil end
	local m = Instance.new("Model")
	m.Name = "Speaker"
	m:SetAttribute("Tier", tier)
	m:SetAttribute("RoomItem", "speaker")
	local cab = part(m, "Cabinet", Vector3.new(s.w, s.h, s.d), CFrame.new(0, s.h / 2, 0), s.body)
	cab.PivotOffset = CFrame.new(0, -s.h / 2, 0) -- the model's pivot: the cabinet's bottom centre, at the origin
	-- the ring sits just behind the woofer's face (its face 0.008 proud of the cabinet, the woofer's 0.015)
	if s.ring then disc(m, "Ring", s.woofer + 0.1, s.wooferY, s, 0.04, 0.032, s.ring, { Material = Enum.Material.Metal }) end
	disc(m, "Woofer", s.woofer, s.wooferY, s, 0.05, 0.035, s.cone)
	disc(m, "Tweeter", s.tweeter, s.tweeterY, s, 0.05, 0.035, s.cone)
	if s.led then
		part(m, "LED", Vector3.new(0.06, 0.06, 0.02), CFrame.new(s.w / 2 - 0.14, s.ledY, -s.d / 2 - 0.005), s.led,
			{ Material = Enum.Material.Neon })
	end
	m.PrimaryPart = cab
	return m
end

return M
