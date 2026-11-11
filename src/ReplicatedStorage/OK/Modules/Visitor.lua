-- OK Studio walk-in visitor (server): a blocky NPC of anchored parts (BoothArtist's figure plus a signature piece)
-- with a pink name plate and a speech bubble (server-built BillboardGuis, so everyone sees them). He walks from the
-- corridor mouth along WalkInRules.Route to the target producer, faces them and arrives; says lines; walks back out the
-- way he came and destroys himself. No Humanoid, no pathfinding, never collides. Stateless: every number comes from
-- opts.walkins (Config.WalkIns: WalkSpeed, ArriveDistance, WalkTimeout, Waypoints, Spawn). Lives under
-- Workspace.OK_Visitors (outside OKStudio, never archivable).
-- SpawnSpot is the critter (the pigeon, design 4.3): the same Handle surface, but a small figure that appears on the
-- lounge coffee table's top face, arrives on the next Heartbeat and leaves by flying up for a second. No lights.
local RS, Players = game:GetService("ReplicatedStorage"), game:GetService("Players")
local RunService = game:GetService("RunService")
local WalkInRules = require(RS.OK.Modules.WalkInRules)
local Theme = require(RS.OK.Modules.UITheme)

local M = {}
local FLOOR_Y = 0          -- the floor top in every hub room (build/02_shell.lua)
local CHECK_EVERY = 0.5    -- seconds between re-aim checks (and re-facing once arrived)
local REAIM_MOVE = 3       -- studs the target must move before the route is re-aimed
local ARRIVE_SLACK = 0.5   -- he arrives within ArriveDistance + this
local STRIDE, SWING = 1.6, 0.6 -- leg/arm swing: radians of phase per stud walked, amplitude in radians
local DARK, SKIN, EYE = Color3.fromRGB(30, 30, 36), Color3.fromRGB(150, 110, 85), Color3.fromRGB(12, 12, 14)
local SUIT, WHITE = Color3.fromRGB(34, 34, 42), Color3.fromRGB(235, 235, 240)

-- a local placement: the figure faces -Z (the LookVector); angles in degrees
local function at(x, y, z, rx, ry, rz)
	return CFrame.new(x, y, z) * CFrame.Angles(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0))
end

-- signature pieces: { name, size, placement, colour, shape?, material? }; c = the visitor's colour. At most 4 each, so a
-- figure stays within 16 parts (8 body + 4). A suit also recolours the torso and arms (SUIT_BODY).
local SIGS = {
	cowboy_hat = function(c) local brown = Color3.fromRGB(92, 62, 38); return {
		{ "HatBrim", Vector3.new(0.12, 2.3, 2.3), at(0, 5.3, 0, 0, 0, 90), brown, Enum.PartType.Cylinder },
		{ "HatCrown", Vector3.new(1.1, 0.75, 1.1), at(0, 5.7, 0), brown },
		{ "HatBand", Vector3.new(1.14, 0.15, 1.14), at(0, 5.42, 0), c },
	} end,
	bat_ears = function(c) local black = Color3.fromRGB(24, 24, 30); return {
		{ "EarL", Vector3.new(0.4, 0.75, 0.12), at(-0.38, 5.55, 0, 0, 0, 20), black },
		{ "EarR", Vector3.new(0.4, 0.75, 0.12), at(0.38, 5.55, 0, 0, 0, -20), black },
		{ "EarInL", Vector3.new(0.22, 0.45, 0.13), at(-0.38, 5.52, -0.01, 0, 0, 20), c },
		{ "EarInR", Vector3.new(0.22, 0.45, 0.13), at(0.38, 5.52, -0.01, 0, 0, -20), c },
	} end,
	spiky_hair = function(c) return {
		{ "SpikeL", Vector3.new(0.35, 0.7, 0.35), at(-0.3, 5.45, 0, 0, 45, 25), c },
		{ "SpikeR", Vector3.new(0.35, 0.7, 0.35), at(0.3, 5.45, 0, 0, 45, -25), c },
		{ "SpikeF", Vector3.new(0.35, 0.7, 0.35), at(0, 5.5, -0.28, -25, 45, 0), c },
		{ "SpikeB", Vector3.new(0.35, 0.7, 0.35), at(0, 5.5, 0.28, 25, 45, 0), c },
	} end,
	blob_hat = function(c) return {
		{ "Blob", Vector3.new(1.6, 1.6, 1.6), at(0, 5.7, 0), c, Enum.PartType.Ball },
		{ "Pom", Vector3.new(0.45, 0.45, 0.45), at(0, 6.55, 0), WHITE, Enum.PartType.Ball },
	} end,
	helmet = function(c) return {
		{ "Shell", Vector3.new(1.4, 1.4, 1.4), at(0, 4.9, 0), c, Enum.PartType.Ball },
		{ "Visor", Vector3.new(1.0, 0.35, 0.12), at(0, 4.95, -0.66), Color3.fromRGB(16, 16, 22), nil, Enum.Material.Glass },
		{ "Fin", Vector3.new(0.15, 0.35, 1.0), at(0, 5.62, 0), c },
	} end,
	llama_ears = function(c) local fur = Color3.fromRGB(215, 190, 150); return {
		{ "EarL", Vector3.new(0.22, 0.75, 0.2), at(-0.35, 5.6, 0.05, 0, 0, 12), fur },
		{ "EarR", Vector3.new(0.22, 0.75, 0.2), at(0.35, 5.6, 0.05, 0, 0, -12), fur },
		{ "Snout", Vector3.new(0.55, 0.4, 0.4), at(0, 4.6, -0.6), fur },
	} end,
	sparkle_cape = function(c) local gold = Theme.gold; return {
		{ "Cape", Vector3.new(1.5, 2.6, 0.12), at(0, 3.0, 0.55), c },
		{ "SparkleA", Vector3.new(0.22, 0.22, 0.06), at(-0.4, 3.6, 0.63, 0, 0, 45), gold, nil, Enum.Material.Neon },
		{ "SparkleB", Vector3.new(0.22, 0.22, 0.06), at(0.35, 2.7, 0.63, 0, 0, 45), gold, nil, Enum.Material.Neon },
		{ "SparkleC", Vector3.new(0.22, 0.22, 0.06), at(-0.1, 2.0, 0.63, 0, 0, 45), gold, nil, Enum.Material.Neon },
	} end,
	owl_hood = function(c) return {
		{ "Hood", Vector3.new(1.45, 1.3, 0.6), at(0, 4.95, 0.35), c },
		{ "TuftL", Vector3.new(0.3, 0.45, 0.3), at(-0.5, 5.7, 0.25, 0, 0, 18), c },
		{ "TuftR", Vector3.new(0.3, 0.45, 0.3), at(0.5, 5.7, 0.25, 0, 0, -18), c },
	} end,
	green_roots = function() return {
		{ "Hair", Vector3.new(1.3, 1.7, 0.6), at(0, 4.5, 0.35), Color3.fromRGB(18, 18, 22) },
		{ "Roots", Vector3.new(1.3, 0.35, 1.3), at(0, 5.4, 0.05), Color3.fromRGB(110, 220, 90) },
	} end,
	suit = function(c) return {
		{ "Shirt", Vector3.new(0.5, 1.2, 0.05), at(0, 3.6, -0.47), WHITE },
		{ "Tie", Vector3.new(0.2, 1.0, 0.06), at(0, 3.5, -0.5), c },
	} end,
	cap = function(c) return {
		{ "CapCrown", Vector3.new(1.26, 0.45, 1.26), at(0, 5.3, 0), c },
		{ "CapBill", Vector3.new(1.0, 0.12, 0.75), at(0, 5.15, -0.85), c },
	} end,
	headphones = function(c) return {
		{ "Band", Vector3.new(1.5, 0.18, 0.3), at(0, 5.55, 0), DARK },
		{ "CupL", Vector3.new(0.3, 0.6, 0.6), at(-0.68, 4.9, 0), c },
		{ "CupR", Vector3.new(0.3, 0.6, 0.6), at(0.68, 4.9, 0), c },
	} end,
	-- Wave 1a (design 4.3): mom's apron, the talk show booker's headset, the youth coordinator's lanyard
	apron = function(c) local cloth = Color3.fromRGB(240, 236, 226); return {
		{ "Bib", Vector3.new(0.9, 1.0, 0.06), at(0, 3.65, -0.49), cloth },
		{ "Skirt", Vector3.new(1.7, 1.3, 0.06), at(0, 2.45, -0.49), cloth },
		{ "Pocket", Vector3.new(0.5, 0.35, 0.05), at(0, 2.55, -0.53), c },
	} end,
	headset = function(c) return {
		{ "Band", Vector3.new(1.5, 0.18, 0.3), at(0, 5.55, 0), DARK },
		{ "CupL", Vector3.new(0.3, 0.5, 0.5), at(-0.68, 4.9, 0), DARK },
		{ "CupR", Vector3.new(0.3, 0.5, 0.5), at(0.68, 4.9, 0), DARK },
		{ "Boom", Vector3.new(0.1, 0.1, 0.8), at(-0.42, 4.65, -0.35, 0, -35, 0), c },
	} end,
	lanyard = function(c) return {
		{ "CordL", Vector3.new(0.08, 1.2, 0.05), at(-0.28, 3.7, -0.48, 0, 0, 22), c },
		{ "CordR", Vector3.new(0.08, 1.2, 0.05), at(0.28, 3.7, -0.48, 0, 0, -22), c },
		{ "Badge", Vector3.new(0.55, 0.75, 0.05), at(0, 2.95, -0.49), WHITE },
		{ "Clip", Vector3.new(0.2, 0.15, 0.06), at(0, 3.37, -0.5), c },
	} end,
	none = function() return {} end,
}
local SUIT_BODY = { suit = SUIT }

local function folder()
	local f = workspace:FindFirstChild("OK_Visitors")
	if not f then
		f = Instance.new("Folder")
		f.Name = "OK_Visitors"; f.Archivable = false
		f.Parent = workspace
	end
	return f
end

local function flatDist(x1, z1, x2, z2)
	local dx, dz = x2 - x1, z2 - z1
	return math.sqrt(dx * dx + dz * dz)
end

-- the point `ad` studs short of (tx, tz) on the straight line from (x, z); (x, z) itself when already that close
local function stopToward(x, z, tx, tz, ad)
	local d = flatDist(x, z, tx, tz)
	if d <= ad then return { x = x, z = z } end
	local k = (d - ad) / d
	return { x = x + (tx - x) * k, z = z + (tz - z) * k }
end

local function label(name, parent, font, color)
	local l = Instance.new("TextLabel")
	l.Name = name; l.BackgroundTransparency = 1; l.Font = font; l.TextColor3 = color; l.TextScaled = true
	l.Text = ""; l.Parent = parent
	return l
end

local function padding(parent, x, y)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, x); p.PaddingRight = UDim.new(0, x); p.PaddingTop = UDim.new(0, y); p.PaddingBottom = UDim.new(0, y)
	p.Parent = parent
end

local Handle = {}
Handle.__index = Handle

-- the empty model: Visitor_<id>, never archivable, with the attributes the tests and WalkIns read
local function newModel(def, target)
	local model = Instance.new("Model")
	model.Name = "Visitor_" .. def.id
	model.Archivable = false
	model:SetAttribute("Visitor", def.name)
	model:SetAttribute("VisitorId", def.id)
	model:SetAttribute("Target", target.UserId)
	return model
end

-- one anchored, non-colliding, shadowless part of the figure
local function newPart(model, name, size, col, shape, material)
	local p = Instance.new("Part")
	p.Name = name; p.Size = size; p.Color = col
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then p.Shape = shape end
	p.Parent = model
	return p
end

-- the name plate (Nameplate's billboard, on a pink plate) and the hidden speech bubble (lifted by its own size so it
-- sits just above the plate), both over `head`; returns bubble, bubble label
local function decorate(model, head, def)
	local plate = Instance.new("BillboardGui")
	plate.Name = "NamePlate"; plate.Size = UDim2.fromOffset(200, 46); plate.StudsOffset = Vector3.new(0, 2.4, 0)
	plate.MaxDistance = 80; plate.LightInfluence = 0; plate.Adornee = head; plate.Parent = model
	local bg = Instance.new("Frame")
	bg.Name = "Plate"; bg.Size = UDim2.fromScale(1, 1); bg.BackgroundColor3 = Theme.accent; bg.BackgroundTransparency = 0.1
	bg.BorderSizePixel = 0; bg.Parent = plate
	Instance.new("UICorner").Parent = bg
	padding(bg, 8, 3)
	local name = label("NameText", bg, Theme.fontBlack, Theme.text)
	name.Size = UDim2.fromScale(1, 0.62); name.Text = def.name
	local style = label("StyleText", bg, Theme.font, Theme.text)
	style.Size = UDim2.fromScale(1, 0.38); style.Position = UDim2.fromScale(0, 0.62); style.TextTransparency = 0.15
	style.Text = def.style or ""

	local bubble = Instance.new("BillboardGui")
	bubble.Name = "Bubble"; bubble.Size = UDim2.fromOffset(240, 64); bubble.StudsOffset = Vector3.new(0, 2.4, 0)
	bubble.SizeOffset = Vector2.new(0, (46 / 2 + 6 + 64 / 2) / 64)
	bubble.MaxDistance = 80; bubble.LightInfluence = 0; bubble.Adornee = head; bubble.Enabled = false; bubble.Parent = model
	local line = label("Line", bubble, Theme.font, Theme.text)
	line.Size = UDim2.fromScale(1, 1); line.BackgroundTransparency = 0.15; line.BackgroundColor3 = Theme.panel
	line.TextWrapped = true
	Instance.new("UICorner").Parent = line
	padding(line, 8, 4)
	return bubble, line
end

-- the walker's figure, name plate and hidden bubble; returns model, posed part list, bubble, bubble label
local function build(def, target)
	local color = def.color and Color3.fromRGB(def.color[1], def.color[2], def.color[3]) or Theme.accent2
	local model = newModel(def, target)
	local parts = {}
	local function add(name, size, cf, col, shape, material, limb)
		local p = newPart(model, name, size, col, shape, material)
		table.insert(parts, { part = p, cf = cf, swing = limb and limb.swing, hang = limb and CFrame.new(0, -limb.len / 2, 0) })
		return p
	end
	local body = SUIT_BODY[def.sig] or color
	-- BoothArtist's proportions, turned to face -Z; limbs hang from hip/shoulder pivots so they can swing
	add("LegL", Vector3.new(0.6, 2.2, 0.6), CFrame.new(-0.35, 2.2, 0), DARK, nil, nil, { swing = 1, len = 2.2 })
	add("LegR", Vector3.new(0.6, 2.2, 0.6), CFrame.new(0.35, 2.2, 0), DARK, nil, nil, { swing = -1, len = 2.2 })
	local torso = add("Torso", Vector3.new(1.6, 2.0, 0.9), CFrame.new(0, 3.2, 0), body)
	add("ArmL", Vector3.new(0.5, 1.9, 0.5), CFrame.new(-1.05, 4.1, 0), body, nil, nil, { swing = -1, len = 1.9 })
	add("ArmR", Vector3.new(0.5, 1.9, 0.5), CFrame.new(1.05, 4.1, 0), body, nil, nil, { swing = 1, len = 1.9 })
	local head = add("Head", Vector3.new(1.2, 1.2, 1.2), CFrame.new(0, 4.85, 0), SKIN, Enum.PartType.Ball)
	add("EyeL", Vector3.new(0.1, 0.2, 0.14), CFrame.new(-0.22, 4.95, -0.57), EYE)
	add("EyeR", Vector3.new(0.1, 0.2, 0.14), CFrame.new(0.22, 4.95, -0.57), EYE)
	for _, s in ipairs((SIGS[def.sig] or SIGS.none)(color)) do add(s[1], s[2], s[3], s[4], s[5], s[6]) end
	model.PrimaryPart = torso
	local bubble, line = decorate(model, head, def)
	return model, parts, bubble, line
end

-- def = { id, name, style, color = {r, g, b}, sig } (a Data/WalkIns visitor with its display name filled in);
-- target = the Player he walks to; opts = { walkins = Config.WalkIns, onArrive = fn?, onGone = fn? }
function M.Spawn(def, target, opts)
	-- id feeds the VisitorId attribute and name the Visitor attribute; SetAttribute(k, nil) would drop either silently
	assert(type(def) == "table" and type(def.id) == "string" and type(def.name) == "string", "Visitor.Spawn needs def.id and def.name")
	assert(opts and opts.walkins, "Visitor.Spawn needs opts.walkins (Config.WalkIns)")
	local w = opts.walkins
	local model, parts, bubble, line = build(def, target)
	local now = os.clock()
	local self = setmetatable({
		Model = model, Arrived = false,
		_w = w, _target = target, _onArrive = opts.onArrive, _onGone = opts.onGone,
		_state = "walking",   -- walking -> arrived -> leaving -> gone (leaving and gone can come from any state)
		_parts = parts, _bubble = bubble, _line = line,
		_x = w.Spawn[1], _z = w.Spawn[2], _lx = 1, _lz = 0, _phase = 0,
		_path = {},           -- points still to walk: { x, z, chain = reached adds it to the trail, back = reached pops it }
		_trail = {},          -- the route waypoints walked so far, in order (he leaves back along them)
		_since = now, _checkedAt = now, _aimX = nil, _aimZ = nil,
	}, Handle)
	local root = self:_targetRoot()
	if root then self:_aim(root.Position.X, root.Position.Z) end
	self:_pose(0)
	model.Parent = folder()
	self._destroying = model.Destroying:Connect(function() self:_gone(true) end) -- removed from outside: still onGone once
	self._conn = RunService.Heartbeat:Connect(function(dt) self:_tick(dt) end)
	return self
end

function Handle:_targetRoot()
	local t = self._target
	if t.Parent ~= Players then return nil end
	local c = t.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

-- plan the walk to (tx, tz): Route's waypoint chain for that room (straight from Spawn when the waypoints lack the room,
-- where Route gives {}), then its stop. Waypoints already walked that the new chain shares are kept; any others are
-- walked back over first, so a re-aim never cuts a corner the chain goes around.
function Handle:_aim(tx, tz)
	local w = self._w
	local room = WalkInRules.RoomOf(tx)
	local chain = w.Waypoints[room]
	if not chain or #chain == 0 then chain = { w.Spawn } end
	local route = WalkInRules.Route(tx, tz, { [room] = chain }, w.ArriveDistance)
	local trail, j = self._trail, 0
	while j < #trail and j < #chain and trail[j + 1][1] == route[j + 1][1] and trail[j + 1][2] == route[j + 1][2] do j += 1 end
	local path = {}
	for i = #trail, j + 1, -1 do table.insert(path, { x = trail[i][1], z = trail[i][2], back = true }) end
	for i = j + 1, #route do table.insert(path, { x = route[i][1], z = route[i][2], chain = i <= #chain }) end
	self._path, self._aimX, self._aimZ = path, tx, tz
end

-- move up to `dist` studs along the path, turning to face where he walks
function Handle:_walk(dist)
	local path, trail = self._path, self._trail
	while dist > 0 and path[1] do
		local p = path[1]
		local dx, dz = p.x - self._x, p.z - self._z
		local d = math.sqrt(dx * dx + dz * dz)
		if d > 1e-3 then self._lx, self._lz = dx / d, dz / d end
		if d <= dist then
			self._x, self._z, dist = p.x, p.z, dist - d
			table.remove(path, 1)
			if p.back then table.remove(trail) elseif p.chain then table.insert(trail, { p.x, p.z }) end
		else
			self._x += dx / d * dist; self._z += dz / d * dist
			dist = 0
		end
	end
end

function Handle:_face(tx, tz)
	local dx, dz = tx - self._x, tz - self._z
	local d = math.sqrt(dx * dx + dz * dz)
	if d > 1e-3 then self._lx, self._lz = dx / d, dz / d end
end

-- place every part for the current position and heading; `swing` (radians) swings legs and arms in opposite pairs
function Handle:_pose(swing)
	local here = Vector3.new(self._x, FLOOR_Y, self._z)
	local base = CFrame.lookAt(here, here + Vector3.new(self._lx, 0, self._lz))
	for _, e in ipairs(self._parts) do
		if e.swing then
			e.part.CFrame = base * e.cf * CFrame.Angles(swing * e.swing, 0, 0) * e.hang
		else
			e.part.CFrame = base * e.cf
		end
	end
end

function Handle:_stride(dt)
	self._phase += dt * self._w.WalkSpeed * STRIDE
	self:_pose(math.sin(self._phase) * SWING)
end

function Handle:_arrive(tx, tz)
	self._state, self._path = "arrived", {}
	self:_face(tx, tz)
	self:_pose(0)
	self.Arrived = true
	if self._onArrive then task.spawn(self._onArrive) end
end

function Handle:_tick(dt)
	local w = self._w
	if self._state == "leaving" then
		self:_walk(dt * w.WalkSpeed)
		if not self._path[1] or os.clock() - self._since >= w.WalkTimeout then self:Destroy() else self:_stride(dt) end
		return
	end
	local root = self:_targetRoot()
	local pos = root and root.Position
	if not pos or not WalkInRules.InHub(pos.X, pos.Y, pos.Z) then self:Leave(); return end
	local now = os.clock()
	local check = now - self._checkedAt >= CHECK_EVERY
	if check then self._checkedAt = now end
	if self._state == "arrived" then
		if check then self:_face(pos.X, pos.Z); self:_pose(0) end
		return
	end
	if check and (not self._aimX or flatDist(self._aimX, self._aimZ, pos.X, pos.Z) > REAIM_MOVE) then self:_aim(pos.X, pos.Z) end
	self:_walk(dt * w.WalkSpeed)
	if flatDist(self._x, self._z, pos.X, pos.Z) <= w.ArriveDistance + ARRIVE_SLACK then self:_arrive(pos.X, pos.Z); return end
	-- at the end of the path but the target drifted (less than the re-aim distance): close the gap in a straight line
	if not self._path[1] then self._path = { stopToward(self._x, self._z, pos.X, pos.Z, w.ArriveDistance) } end
	if now - self._since >= w.WalkTimeout then -- too long: snap to the arrival point
		self:_walk(math.huge)
		self:_arrive(pos.X, pos.Z)
		return
	end
	self:_stride(dt)
end

-- show `text` in his bubble (nil or "" hides it)
function Handle:Say(text)
	if self._state == "gone" then return end
	local has = text ~= nil and text ~= ""
	self._line.Text = has and tostring(text) or ""
	self._bubble.Enabled = has
end

-- turn round and walk back out the way he came, then destroy himself (within WalkTimeout). No-op once leaving or gone
function Handle:Leave()
	if self._state == "leaving" or self._state == "gone" then return end
	self._state, self._since = "leaving", os.clock()
	local path = {}
	for i = #self._trail, 1, -1 do table.insert(path, { x = self._trail[i][1], z = self._trail[i][2], back = true }) end
	table.insert(path, { x = self._w.Spawn[1], z = self._w.Spawn[2] })
	self._path = path
end

function Handle:_gone(external)
	if self._state == "gone" then return end
	self._state = "gone"
	self._conn:Disconnect()
	self._destroying:Disconnect()
	if not external then self.Model:Destroy() end
	if self._onGone then task.spawn(self._onGone) end
end

-- remove him now; idempotent, onGone exactly once (also when the model is destroyed from outside)
function Handle:Destroy()
	self:_gone(false)
end

-- the spot figure (the pigeon) ----------------------------------------------------------------------------------------

local FLY_SECONDS, FLY_SPEED, FLAP = 1, 5, 0.9 -- Leave: this long straight up at this speed, wings swinging this far
local SPOT_GAP = 1.5                            -- studs between live spot figures along the table
local PIGEON = { body = Color3.fromRGB(125, 130, 140), dark = Color3.fromRGB(85, 90, 100), neck = Color3.fromRGB(80, 140, 120),
	beak = Color3.fromRGB(225, 180, 90), foot = Color3.fromRGB(225, 115, 105) }
-- { name, size, placement, colour, shape?, material?, flap? }: 11 parts, feet at y 0, facing -Z like the walker; a
-- flap of 1 or -1 swings that wing about its own axis during the flight
local function pigeonParts()
	local P = PIGEON
	return {
		{ "Body", Vector3.new(0.7, 0.6, 1.1), at(0, 0.6, 0.05), P.body },
		{ "Head", Vector3.new(0.45, 0.45, 0.45), at(0, 1.05, -0.5), P.body, Enum.PartType.Ball },
		{ "Neck", Vector3.new(0.4, 0.2, 0.4), at(0, 0.85, -0.4), P.neck },
		{ "Beak", Vector3.new(0.12, 0.1, 0.25), at(0, 1.02, -0.8), P.beak },
		{ "EyeL", Vector3.new(0.08, 0.08, 0.08), at(-0.16, 1.1, -0.62), EYE },
		{ "EyeR", Vector3.new(0.08, 0.08, 0.08), at(0.16, 1.1, -0.62), EYE },
		{ "WingL", Vector3.new(0.12, 0.35, 0.8), at(-0.4, 0.65, 0.1), P.dark, nil, nil, 1 },
		{ "WingR", Vector3.new(0.12, 0.35, 0.8), at(0.4, 0.65, 0.1), P.dark, nil, nil, -1 },
		{ "Tail", Vector3.new(0.4, 0.08, 0.5), at(0, 0.62, 0.75, 15), P.dark },
		{ "LegL", Vector3.new(0.08, 0.3, 0.08), at(-0.15, 0.15, 0.05), P.foot },
		{ "LegR", Vector3.new(0.08, 0.3, 0.08), at(0.15, 0.15, 0.05), P.foot },
	}
end
local taken = {} -- [slot] = true while a spot figure stands in it: slot n sits ceil(n / 2) * SPOT_GAP along the table,
                 -- alternating sides (0, +1.5, -1.5, +3, ...); a new one takes the lowest free slot, so one that left
                 -- never leaves the next on top of one still standing (a live count would)

-- the lounge coffee table's top, read live (build/05_lounge_corridor.lua makes it; its top face is where the figure stands)
local function coffeeTable()
	local ok = workspace:FindFirstChild("OKStudio")
	local lounge = ok and ok:FindFirstChild("Lounge")
	local top = lounge and lounge:FindFirstChild("Coffee_Top")
	assert(top and top:IsA("BasePart"), "Visitor.SpawnSpot needs workspace.OKStudio.Lounge.Coffee_Top")
	return top
end

local function buildSpot(def, target)
	local model = newModel(def, target)
	local parts, head = {}, nil
	for _, s in ipairs(pigeonParts()) do
		local p = newPart(model, s[1], s[2], s[4], s[5], s[6])
		table.insert(parts, { part = p, cf = s[3], flap = s[7] })
		if s[1] == "Head" then head = p elseif s[1] == "Body" then model.PrimaryPart = p end
	end
	local bubble, line = decorate(model, head, def)
	return model, parts, bubble, line
end

local Spot = setmetatable({}, { __index = Handle }) -- Say, Destroy, _targetRoot and _face come from the walker
Spot.__index = Spot

-- a critter's figure on the lounge coffee table: def and opts as Spawn (opts.walkins is not needed). Arrived and
-- onArrive come on the next Heartbeat, never inside this call; it leaves on its own when the target leaves the hub
function M.SpawnSpot(def, target, opts)
	assert(type(def) == "table" and type(def.id) == "string" and type(def.name) == "string", "Visitor.SpawnSpot needs def.id and def.name")
	opts = opts or {}
	local top = coffeeTable()
	local model, parts, bubble, line = buildSpot(def, target)
	local n = 0
	while taken[n] do n += 1 end -- the lowest free slot
	taken[n] = true
	local offset = math.ceil(n / 2) * SPOT_GAP * ((n % 2 == 1) and 1 or -1) -- 0, +1.5, -1.5, +3, ...
	local now = os.clock()
	local self = setmetatable({
		Model = model, Arrived = false,
		_target = target, _onArrive = opts.onArrive, _onGone = opts.onGone,
		_state = "spot",      -- spot -> arrived -> leaving -> gone
		_parts = parts, _bubble = bubble, _line = line, _slot = n,
		_x = top.Position.X + offset, _y = top.Position.Y + top.Size.Y / 2, _z = top.Position.Z, _lx = 1, _lz = 0,
		_since = now, _checkedAt = now,
	}, Spot)
	local root = self:_targetRoot()
	if root then self:_face(root.Position.X, root.Position.Z) end
	self:_pose(0)
	model.Parent = folder()
	self._destroying = model.Destroying:Connect(function() self:_gone(true) end)
	self._conn = RunService.Heartbeat:Connect(function(dt) self:_tick(dt) end)
	return self
end

-- place every part at the figure's position and heading; `flap` (radians) swings the wings
function Spot:_pose(flap)
	local here = Vector3.new(self._x, self._y, self._z)
	local base = CFrame.lookAt(here, here + Vector3.new(self._lx, 0, self._lz))
	for _, e in ipairs(self._parts) do
		if e.flap then
			e.part.CFrame = base * e.cf * CFrame.Angles(0, 0, flap * e.flap)
		else
			e.part.CFrame = base * e.cf
		end
	end
end

function Spot:_tick(dt)
	local now = os.clock()
	if self._state == "leaving" then
		self._y += dt * FLY_SPEED
		self:_pose(math.sin((now - self._since) * 40) * FLAP)
		if now - self._since >= FLY_SECONDS then self:Destroy() end
		return
	end
	local root = self:_targetRoot()
	local pos = root and root.Position
	if not pos or not WalkInRules.InHub(pos.X, pos.Y, pos.Z) then self:Leave(); return end
	if not self.Arrived then -- the first Heartbeat after SpawnSpot
		self._state = "arrived"
		self.Arrived = true
		if self._onArrive then task.spawn(self._onArrive) end
	end
	if now - self._checkedAt >= CHECK_EVERY then
		self._checkedAt = now
		self:_face(pos.X, pos.Z)
		self:_pose(0)
	end
end

-- fly straight up for FLY_SECONDS, then destroy itself. No-op once leaving or gone
function Spot:Leave()
	if self._state == "leaving" or self._state == "gone" then return end
	self._state, self._since = "leaving", os.clock()
end

function Spot:_gone(external)
	if self._state ~= "gone" then taken[self._slot] = nil end -- its slot is free for the next one
	Handle._gone(self, external)
end

return M
