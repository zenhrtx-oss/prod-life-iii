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
-- * Plaque(entry, text) -> Model?: one wall plaque for a RoomRules.Plaques row ({ kind = "hit" | "placement" | "trackone" |
--   "weekly", entry = the source row }; only .kind is read): a coloured Frame (hits gold, placements and track ones silver,
--   weekly singles blue) with a dark Board set into its front, and a SurfaceGui "Face" on the Board's Front face holding a
--   TextLabel "Label" with `text`: two parts and one gui, no lights, meshes, scripts or tags. Its pivot is the centre of the
--   Frame's back face and the front looks along -Z, so a caller PivotTo's it onto a Plaque_<n> Attachment's WorldCFrame (a
--   wall anchor: the plate then hangs flush on the wall facing into the room). Every part is anchored, never collides,
--   touches, answers a raycast or casts a shadow (a flat plate on a wall would only darken the wall behind it, and decorate
--   mode must not catch it). The model is named "Plaque" and carries RoomItem = "plaque" and PlaqueKind = the kind (Systems/
--   Rooms replaces only what it made). nil for a kind it doesn't know or text that is not a non-empty string. The Frame is
--   PLAQUE_W x PLAQUE_H (1.8 x 1.1 studs), under the 2.2 studs between the bedroom's anchors.
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

-- plaques: the frame's colour and the ink the text is set in, per RoomRules.Plaques kind (a track one reads as a placement)
local PLAQUES = {
	hit = { frame = Color3.fromRGB(212, 168, 48), ink = Color3.fromRGB(255, 226, 130) },
	placement = { frame = Color3.fromRGB(192, 194, 202), ink = Color3.fromRGB(238, 239, 244) },
	trackone = { frame = Color3.fromRGB(192, 194, 202), ink = Color3.fromRGB(238, 239, 244) },
	weekly = { frame = Color3.fromRGB(62, 120, 214), ink = Color3.fromRGB(176, 210, 255) },
}
M.PlaqueSpecs = PLAQUES -- read only: the colours, for a caller's checks
M.PLAQUE_W, M.PLAQUE_H = 1.8, 1.1 -- studs, the frame's face
local PLAQUE_FRAME, PLAQUE_BOARD = 0.08, 0.04 -- thickness of the frame and of the board set into its front
local PLAQUE_INSET = 0.06 -- the frame's rim round the board

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

function M.Plaque(entry, text)
	local spec = type(entry) == "table" and PLAQUES[entry.kind] or nil
	if not spec or type(text) ~= "string" or text == "" then return nil end
	local w, h = M.PLAQUE_W, M.PLAQUE_H
	local m = Instance.new("Model")
	m.Name = "Plaque"
	m:SetAttribute("RoomItem", "plaque")
	m:SetAttribute("PlaqueKind", entry.kind)
	part(m, "Frame", Vector3.new(w, h, PLAQUE_FRAME), CFrame.new(0, 0, -PLAQUE_FRAME / 2), spec.frame, { Material = Enum.Material.Metal })
	local board = part(m, "Board", Vector3.new(w - 2 * PLAQUE_INSET, h - 2 * PLAQUE_INSET, PLAQUE_BOARD),
		CFrame.new(0, 0, -PLAQUE_FRAME - PLAQUE_BOARD / 2), Color3.fromRGB(24, 24, 30))
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Face"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 100
	gui.LightInfluence = 0 -- the text reads the same in a dim room
	gui.Brightness = 1.5
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = spec.ink
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 8), UDim.new(0, 8), UDim.new(0, 6), UDim.new(0, 6)
	pad.Parent = label
	local cap = Instance.new("UITextSizeConstraint") -- a short line stays a plate's size, not a poster's
	cap.MaxTextSize = 26
	cap.MinTextSize = 8
	cap.Parent = label
	label.Parent = gui
	gui.Parent = board
	m.WorldPivot = CFrame.new()
	return m
end

return M
