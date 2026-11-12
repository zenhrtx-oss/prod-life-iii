-- OK Studio walk-in visitor figures (server and client; Wave 3 Task 5d): turns a Modules/VisitorLooks look into Roblox
-- parts. The server's walker (Modules/Visitor) builds and poses its figure with Build and Pose; the walk-in card
-- (WalkInUI) and a person's phone card (PhoneUI) show a head-and-shoulders copy built from the same recipe with
-- SetPortrait. Nothing here is saved or replicated by itself: the caller parents what it gets.
-- * Build(look, parent): one Part (a WedgePart for "Wedge") per look part, anchored, CanCollide / CanQuery / CanTouch
--   off, no shadow, SmoothPlastic or Neon, named as in the look. Returns the pose list ({ part, cf, swing, hang, flap }
--   with CFrames), the head part and the primary part.
-- * Pose(list, base, swing): places every part for a figure standing at `base` (feet at its origin, facing its
--   LookVector): a limb at base * cf * Angles(swing * swing sign, 0, 0) * hang, a wing at base * cf * Angles(0, 0,
--   swing * flap), anything else at base * cf (VisitorLooks.Pose, as CFrames).
-- * Portrait(look, frame, opts): a ViewportFrame (Name opts.name or "View", filling its parent) holding a Model "Figure"
--   (attribute VisitorId = look.id) posed and turned as `frame` (VisitorLooks.Frame(look)) says, and a Camera
--   "PortraitCam" set as its CurrentCamera with the frame's fov, from and at; lit like the lineup's portraits. opts =
--   { name?, bg = Color3?, corner = px? }. One call builds one copy.
-- * SetPortrait(holder, who, opts): the cards' one way to show a face. It destroys the holder's View (the copy built
--   before), then, when `who` = { id, sig?, color? } (a payload's visitor or sender) is given, builds the portrait of
--   VisitorLooks.Resolve(id, sig, color), the look his walker is built from, into the holder as "View" (opts.bg,
--   opts.corner). opts.person: only a person's look (VisitorLooks.IsPerson(id)); anyone else gets no face. A build error
--   warns "[OK][ERR]" and leaves the holder empty. Returns the View or nil. A card calls it when it opens (a new card
--   replaces the old copy) and with who = nil when it closes; never from a layout or a heartbeat.
-- Requires its sibling VisitorLooks by script.Parent, so an Edit check can load the pair fresh from one folder.
local Looks = require(script.Parent.VisitorLooks)
local F = {}
local AMBIENT, LIGHT, LIGHT_DIR = Color3.fromRGB(165, 165, 175), Color3.fromRGB(255, 246, 236), Vector3.new(-1, -1, -1)
local SHAPES = { Ball = Enum.PartType.Ball, Cylinder = Enum.PartType.Cylinder }

-- a VisitorLooks placement (CFrame.new's twelve components) as a CFrame
function F.CFrame(t) return CFrame.new(table.unpack(t)) end

function F.Build(look, parent)
	local list, head, primary = {}, nil, nil
	for _, e in ipairs(look.parts) do
		local p = Instance.new(e.sh == "Wedge" and "WedgePart" or "Part")
		p.Name = e.n
		p.Size = Vector3.new(e.s[1], e.s[2], e.s[3])
		p.Color = Color3.fromRGB(e.c[1], e.c[2], e.c[3])
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
		p.Material = e.m == "Neon" and Enum.Material.Neon or Enum.Material.SmoothPlastic
		if SHAPES[e.sh] then p.Shape = SHAPES[e.sh] end
		p.Parent = parent
		table.insert(list, { part = p, cf = F.CFrame(e.cf), swing = e.sw, hang = e.hang and F.CFrame(e.hang) or nil, flap = e.flap })
		if e.n == look.head then head = p end
		if e.n == look.primary then primary = p end
	end
	return list, head, primary
end

function F.Pose(list, base, swing)
	for _, e in ipairs(list) do
		if e.swing then
			e.part.CFrame = base * e.cf * CFrame.Angles(swing * e.swing, 0, 0) * e.hang
		elseif e.flap then
			e.part.CFrame = base * e.cf * CFrame.Angles(0, 0, swing * e.flap)
		else
			e.part.CFrame = base * e.cf
		end
	end
end

function F.Portrait(look, fr, opts)
	opts = opts or {}
	local vf = Instance.new("ViewportFrame")
	vf.Name = opts.name or "View"
	vf.Size = UDim2.fromScale(1, 1)
	vf.BackgroundColor3 = opts.bg or Color3.fromRGB(10, 10, 14)
	vf.BorderSizePixel = 0
	vf.Ambient, vf.LightColor, vf.LightDirection = AMBIENT, LIGHT, LIGHT_DIR
	if opts.corner then
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, opts.corner)
		c.Parent = vf
	end
	local model = Instance.new("Model")
	model.Name = "Figure"
	model:SetAttribute("VisitorId", look.id)
	local list = F.Build(look, model)
	F.Pose(list, F.CFrame(fr.base), 0)
	model.Parent = vf
	local cam = Instance.new("Camera")
	cam.Name = "PortraitCam"
	cam.FieldOfView = fr.fov
	cam.CFrame = CFrame.lookAt(Vector3.new(fr.from[1], fr.from[2], fr.from[3]), Vector3.new(fr.at[1], fr.at[2], fr.at[3]))
	cam.Parent = vf
	vf.CurrentCamera = cam
	return vf
end

function F.SetPortrait(holder, who, opts)
	opts = opts or {}
	for _, c in ipairs(holder:GetChildren()) do
		if c.Name == "View" and c:IsA("ViewportFrame") then c:Destroy() end
	end
	if type(who) ~= "table" then return nil end
	local id = type(who.id) == "string" and who.id or nil
	if opts.person and not Looks.IsPerson(id) then return nil end
	local ok, res = pcall(function()
		local look = Looks.Resolve(id, who.sig, who.color)
		return F.Portrait(look, Looks.Frame(look), { name = "View", bg = opts.bg, corner = opts.corner })
	end)
	if not ok then warn("[OK][ERR] VisitorFigure.SetPortrait: " .. tostring(res)); return nil end
	res.Parent = holder
	return res
end

return F
