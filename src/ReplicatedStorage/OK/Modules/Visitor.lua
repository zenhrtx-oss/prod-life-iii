-- OK Studio walk-in visitor (server): an NPC of anchored parts with a pink name plate and a speech bubble (server-built
-- BillboardGuis, so everyone sees them). His figure is look B, "Lanky shapes" (Wave 3 Task 5d): his own recipe in
-- Modules/VisitorLooks (an id without one gets the fallback figure in his colour, wearing his sig), built and posed by
-- Modules/VisitorFigure, at most 16 parts, PrimaryPart Torso; the plate and the bubble sit VisitorLooks.Info's `plate`
-- over his Head (1.2 above his figure's top). He walks from the corridor mouth along WalkInRules.Route to the target
-- producer, faces them and arrives; says lines; walks back out the way he came and destroys himself. In your own room
-- (the Your Rooms plan, Task 5) he walks opts.route instead: in at its first point (the room's Entrance), along it to
-- its last (VisitorSpot), where he arrives facing you; he leaves back along it. opts.present says whether the target
-- still counts as there (your room); without it, the hub rooms (WalkInRules.InHub). While he walks,
-- his position moves every Heartbeat but his figure is posed only about VisitorLooks.POSE_HZ times a second (launch
-- audit A14: every pose is a CFrame write per part, replicated to every client); he is posed at once when he spawns,
-- arrives (or snaps in) and turns to face the player. No Humanoid, no pathfinding, never collides. Stateless: every
-- number comes from opts.walkins (Config.WalkIns: WalkSpeed, ArriveDistance, WalkTimeout, Waypoints, Spawn). Lives
-- under Workspace.OK_Visitors (outside OKStudio, never archivable).
-- SpawnSpot is the critter (the pigeon, design 4.3, VisitorLooks.Pigeon): the same Handle surface, but a small figure
-- that appears on the lounge coffee table's top face (in your room: at opts.at, its CritterSpot), arrives on the next
-- Heartbeat and leaves by flying up for a second. No lights.
local RS, Players = game:GetService("ReplicatedStorage"), game:GetService("Players")
local RunService = game:GetService("RunService")
local WalkInRules = require(RS.OK.Modules.WalkInRules)
local Theme = require(RS.OK.Modules.UITheme)
local Looks = require(RS.OK.Modules.VisitorLooks)
local Figure = require(RS.OK.Modules.VisitorFigure)

local M = {}
local FLOOR_Y = 0          -- the floor top in every hub room (build/02_shell.lua) and every room of yours (Config.Rooms)
local CHECK_EVERY = 0.5    -- seconds between re-aim checks (and re-facing once arrived)
local REAIM_MOVE = 3       -- studs the target must move before the route is re-aimed
local ARRIVE_SLACK = 0.5   -- he arrives within ArriveDistance + this
local STRIDE, SWING = 1.6, 0.6 -- leg/arm swing: radians of phase per stud walked, amplitude in radians

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

-- a position from a Vector3 or a CFrame (a room anchor)
local function posOf(v) return typeof(v) == "CFrame" and v.Position or v end

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

-- the name plate (Nameplate's billboard, on a pink plate) and the hidden speech bubble (lifted by its own size so it
-- sits just above the plate), both `offset` studs over `head` (VisitorLooks.Info's plate); returns bubble, bubble label
local function decorate(model, head, def, offset)
	local plate = Instance.new("BillboardGui")
	plate.Name = "NamePlate"; plate.Size = UDim2.fromOffset(200, 46); plate.StudsOffset = Vector3.new(0, offset, 0)
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
	bubble.Name = "Bubble"; bubble.Size = UDim2.fromOffset(240, 64); bubble.StudsOffset = Vector3.new(0, offset, 0)
	bubble.SizeOffset = Vector2.new(0, (46 / 2 + 6 + 64 / 2) / 64)
	bubble.MaxDistance = 80; bubble.LightInfluence = 0; bubble.Adornee = head; bubble.Enabled = false; bubble.Parent = model
	local line = label("Line", bubble, Theme.font, Theme.text)
	line.Size = UDim2.fromScale(1, 1); line.BackgroundTransparency = 0.15; line.BackgroundColor3 = Theme.panel
	line.TextWrapped = true
	Instance.new("UICorner").Parent = line
	padding(line, 8, 4)
	return bubble, line
end

-- the walker's figure (his look, VisitorLooks.Resolve: his recipe, else the fallback in his colour wearing his sig),
-- name plate and hidden bubble; returns model, pose list, bubble, bubble label
local function build(def, target)
	local look = Looks.Resolve(def.id, def.sig, def.color)
	local model = newModel(def, target)
	local parts, head, primary = Figure.Build(look, model)
	model.PrimaryPart = primary
	local bubble, line = decorate(model, head, def, Looks.Info(look).plate)
	return model, parts, bubble, line
end

-- def = { id, name, style, color = {r, g, b}, sig } (a Data/WalkIns visitor with its display name filled in);
-- target = the Player he walks to; opts = { walkins = Config.WalkIns, onArrive = fn?, onGone = fn?, route = { point }?,
-- present = fn(pos)? }.
-- * route (your room; points are Vector3s or CFrames, only x and z are used: Systems/WalkIns passes the room's Entrance
--   and VisitorSpot): he starts at route[1] and walks the rest in order. He is never re-aimed at the target and never
--   arrives by distance (preflight F4): he arrives at the last point, then faces the target; WalkTimeout snaps him
--   there. Leave walks the route back and he vanishes at route[1]. Without a route: the hub's (Handle:_aim).
-- * present(pos) -> truthy while the target's root position still counts for the visit (your room); without it, the hub
--   rooms (WalkInRules.InHub). Not present: he leaves.
function M.Spawn(def, target, opts)
	-- id feeds the VisitorId attribute and name the Visitor attribute; SetAttribute(k, nil) would drop either silently
	assert(type(def) == "table" and type(def.id) == "string" and type(def.name) == "string", "Visitor.Spawn needs def.id and def.name")
	assert(opts and opts.walkins, "Visitor.Spawn needs opts.walkins (Config.WalkIns)")
	local w = opts.walkins
	local route
	if opts.route ~= nil then
		assert(type(opts.route) == "table" and #opts.route >= 1, "Visitor.Spawn: opts.route needs at least one point")
		route = {}
		for i, pt in ipairs(opts.route) do
			local pos = posOf(pt)
			route[i] = { pos.X, pos.Z }
		end
	end
	local home = route and route[1] or w.Spawn -- where he comes in, and where Leave takes him
	local model, parts, bubble, line = build(def, target)
	local now = os.clock()
	local self = setmetatable({
		Model = model, Arrived = false,
		_w = w, _target = target, _onArrive = opts.onArrive, _onGone = opts.onGone, _present = opts.present,
		_route = route, _home = home,
		_state = "walking",   -- walking -> arrived -> leaving -> gone (leaving and gone can come from any state)
		_parts = parts, _bubble = bubble, _line = line,
		_x = home[1], _z = home[2], _lx = 1, _lz = 0, _phase = 0, _poseClock = 0, -- _poseClock: A14's (VisitorLooks.PoseStep)
		_path = {},           -- points still to walk: { x, z, chain = reached adds it to the trail, back = reached pops it }
		_trail = {},          -- the route waypoints walked so far, in order (he leaves back along them)
		_since = now, _checkedAt = now, _aimX = nil, _aimZ = nil,
	}, Handle)
	if route then
		for i = 2, #route do table.insert(self._path, { x = route[i][1], z = route[i][2], chain = true }) end
		if route[2] then self:_face(route[2][1], route[2][2]) end -- facing his first step
	else
		local root = self:_targetRoot()
		if root then self:_aim(root.Position.X, root.Position.Z) end
	end
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
	Figure.Pose(self._parts, CFrame.lookAt(here, here + Vector3.new(self._lx, 0, self._lz)), swing)
end

-- a walking frame: the stride's phase moves on every frame, the figure is posed only when the pose clock says (A14)
function Handle:_stride(dt)
	self._phase += dt * self._w.WalkSpeed * STRIDE
	local due
	due, self._poseClock = Looks.PoseStep(self._poseClock, dt)
	if due then self:_pose(math.sin(self._phase) * SWING) end
end

function Handle:_arrive(tx, tz)
	self._state, self._path = "arrived", {}
	self:_face(tx, tz)
	self:_pose(0)
	self.Arrived = true
	if self._onArrive then task.spawn(self._onArrive) end
end

-- does the target's root position still count for this visit? opts.present when it was given, else the hub rooms
function Handle:_here(pos)
	if self._present then return self._present(pos) and true or false end
	return WalkInRules.InHub(pos.X, pos.Y, pos.Z)
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
	if not pos or not self:_here(pos) then self:Leave(); return end
	local now = os.clock()
	local check = now - self._checkedAt >= CHECK_EVERY
	if check then self._checkedAt = now end
	if self._state == "arrived" then
		if check then self:_face(pos.X, pos.Z); self:_pose(0) end
		return
	end
	if self._route then -- your room (preflight F4): its points in order, never re-aimed at or closed toward the target
		self:_walk(now - self._since >= w.WalkTimeout and math.huge or dt * w.WalkSpeed) -- too long: snap to its end
		if not self._path[1] then self:_arrive(pos.X, pos.Z) else self:_stride(dt) end
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

-- turn round and walk back out the way he came (the hub's corridor mouth, or your room's route back to its first point),
-- then destroy himself (within WalkTimeout). No-op once leaving or gone
function Handle:Leave()
	if self._state == "leaving" or self._state == "gone" then return end
	self._state, self._since = "leaving", os.clock()
	local path = {}
	for i = #self._trail, 1, -1 do table.insert(path, { x = self._trail[i][1], z = self._trail[i][2], back = true }) end
	table.insert(path, { x = self._home[1], z = self._home[2] })
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

-- the pigeon (VisitorLooks.Pigeon: 11 parts, feet at y 0, facing -Z like the walker; its wings flap in Leave)
local function buildSpot(def, target)
	local look = Looks.Pigeon()
	local model = newModel(def, target)
	local parts, head, primary = Figure.Build(look, model)
	model.PrimaryPart = primary
	local bubble, line = decorate(model, head, def, Looks.Info(look).plate)
	return model, parts, bubble, line
end

local Spot = setmetatable({}, { __index = Handle }) -- Say, Destroy, _targetRoot, _here and _face come from the walker
Spot.__index = Spot

-- a critter's figure: def and opts as Spawn (opts.walkins and opts.route are not used). It sits on the lounge coffee
-- table (the lowest free table slot), or with opts.at (a CFrame or Vector3: your room's CritterSpot) with its feet there,
-- with no table and no table slot (preflight m13). Arrived and onArrive come on the next Heartbeat, never inside this
-- call; it leaves on its own when the target no longer counts as there (opts.present, else the hub rooms)
function M.SpawnSpot(def, target, opts)
	assert(type(def) == "table" and type(def.id) == "string" and type(def.name) == "string", "Visitor.SpawnSpot needs def.id and def.name")
	opts = opts or {}
	local at = opts.at ~= nil and posOf(opts.at) or nil
	local top
	if not at then top = coffeeTable() end -- before anything is built
	local model, parts, bubble, line = buildSpot(def, target)
	local n, x, y, z
	if at then
		x, y, z = at.X, at.Y, at.Z
	else
		n = 0
		while taken[n] do n += 1 end -- the lowest free slot
		taken[n] = true
		local offset = math.ceil(n / 2) * SPOT_GAP * ((n % 2 == 1) and 1 or -1) -- 0, +1.5, -1.5, +3, ...
		x, y, z = top.Position.X + offset, top.Position.Y + top.Size.Y / 2, top.Position.Z
	end
	local now = os.clock()
	local self = setmetatable({
		Model = model, Arrived = false,
		_target = target, _onArrive = opts.onArrive, _onGone = opts.onGone, _present = opts.present,
		_state = "spot",      -- spot -> arrived -> leaving -> gone
		_parts = parts, _bubble = bubble, _line = line, _slot = n, -- _slot: nil away from the table
		_x = x, _y = y, _z = z, _lx = 1, _lz = 0,
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
	Figure.Pose(self._parts, CFrame.lookAt(here, here + Vector3.new(self._lx, 0, self._lz)), flap)
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
	if not pos or not self:_here(pos) then self:Leave(); return end
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
	if self._state ~= "gone" and self._slot ~= nil then taken[self._slot] = nil end -- its table slot is free for the next one
	Handle._gone(self, external)
end

return M
