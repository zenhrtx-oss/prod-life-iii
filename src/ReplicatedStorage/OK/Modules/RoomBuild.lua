-- OK Studio RoomBuild (the Your Rooms plan, Task 2): builds a player's plot from parts. No uploads, no lights except a
-- stand-in room's one warm bulb, and nothing here parents into Workspace: Systems/Rooms takes the unparented Model,
-- runs InteractionService.Adopt on it, then parents it once, straight into Workspace.OK_Plots.
-- * StandIn(kind, kindCfg): a code-built room shell that honours the asset contract (plans/2026-11-12-your-rooms.md,
--   "The asset contract"): a Model with OK_Room and StandIn set, Atomic, its pivot on the floor at the room's centre
--   (north -Z, floor top y 0); a door part (RoomDoor = true) on the south wall with a disabled ExitPrompt; one Station
--   (OK_Interactable, Kind "Station", StationName); a Seat_Chair; a Spawn part facing into the room; every contract
--   Attachment (ContractAnchors) from kindCfg.anchors on a Sockets part; one PointLight (0.25, range 14).
-- * Landing(cfg, owned, kinds): the plot's landing, plot-local x 0..Landing.length, z 0..Landing.width, floor top y 0,
--   OK_Room = "landing", 0 lights. Its FrontDoor (west wall) has an untagged LeavePrompt and an Attachment Inside (where
--   you arrive from the building's hall). On the north wall, for each kind in `kinds` (default: every kind, ladder order),
--   a door part Door_<kind> at DoorX: an owned kind's has an untagged RoomPrompt, a sign with its name and an Attachment
--   Out (where you arrive when you leave that room); one you don't own has the locked sign and no prompt.
-- * Anchors(room, kindCfg): adds each Attachment named in kindCfg.anchors that the room lacks (an imported asset brings
--   its own; Config fills only the gaps), on the room's Sockets part (made at the room's pivot when there is none).
--   Returns the names it added, sorted.
-- * Plot(k, owned, cfg, template, owner): Model Plot_<kk> (Atomic) with the Landing at RoomRules.PlotOrigin(k) and each
--   owned kind at origin + its `at`: a clone of template (a Model for the bedroom, or { [kind] = Model }), else its
--   stand-in; each room named Room_<kind> with RoomKind, Plot and (given owner = { id, name }) OwnerId and OwnerName set,
--   its missing anchors added, its ExitPrompt enabled and its RackSpot added. Unparented.
-- * RackSpot(room) (Task 6): an invisible part RackSpot, a child of the room Model, M.RACK_SIDE studs room-local east of
--   the room's Station (StationOf), tagged OK_Interactable with Kind = "GearRack" (Systems/Gear's handler opens the Gear
--   tab), with a RackPrompt in the house style on F / ButtonY (copy §3.2, §3.3), so it shows beside the laptop's E prompt.
--   Its UIOffset stacks it M.RACK_UI_GAP px off the laptop's prompt (a default prompt is 72 px tall), so on a phone the two
--   tap targets don't overlap (t105b checks it from its camera). It sits inside the room, so the hub's 12 tagged
--   interactables stay 12 (RoomScope), and InteractionService's owner rule makes it the room owner's only. A room with no
--   Station gets none.
-- Copy: research/rooms/copy_2026-11-12.md §1, §2, §3 and §10 (draft lines on the user's approval list), in M.Copy.
local RS = game:GetService("ReplicatedStorage")
local CS = game:GetService("CollectionService")
local Config = require(RS.OK.Config)
local Rules = require(RS.OK.Modules.RoomRules)
local L = require(RS.OK.BuildLib)

local M = {}

M.Copy = {
	-- §1 the building
	BuildingSign = "THE BUILDING\nYOUR DOOR IS INSIDE", -- 1.1 (the corridor's RoomsDoor; build/19_rooms.lua)
	BuildingAction = "Go inside", BuildingObject = "The building", -- 1.2, 1.3
	LobbySign = "THE BUILDING\nFIND YOUR NAME ON A DOOR", -- 1.4
	HubSign = "BACK TO THE STUDIO", HubAction = "Go back", HubObject = "The studio", -- 1.5 - 1.7
	PlateEmpty = "STUDIO {slot}", -- 1.8
	PlateOwned = "{player}\nSTUDIO {slot} · {MODE}", -- 1.9
	EnterAction = "Enter", EnterObject = "{player}'s door", -- 1.10, 1.11
	OwnAction = "Go to your room", OwnObject = "Your door", -- 1.12, 1.13: per viewer, so a client line (not built yet)
	LeaveAction = "Leave", LeaveObject = "Front door", -- 1.14, 1.15
	Locked = "{player}'s door is locked", -- 1.16
	FriendsOnly = "{player}'s door is friends only", -- 1.17
	Full = "the building is full. stay in the studio.", -- 1.18
	OwnerLeft = "{player} left the server", -- 1.19
	-- §2 the rooms
	Names = { bedroom = "BEDROOM", home = "HOME STUDIO", real = "REAL STUDIO" }, -- 2.1 - 2.3
	GoIn = "Go in", -- 2.4
	Objects = { bedroom = "Bedroom", home = "Home studio", real = "Real studio" }, -- 2.5 - 2.7
	LockedSign = { home = "HOME STUDIO · LOCKED", real = "REAL STUDIO · LOCKED" }, -- 2.8, 2.9
	LockedHint = "SEE THE CAREER TAB", -- 2.10 (optional: the user may drop it)
	-- §3 your laptop is yours: the owner toast (InteractionService.Guard; the whole name, the toast label wraps) and the
	-- rack prompt beside the laptop
	OwnerOnly = "{player}'s laptop. only they can use it.", -- 3.1
	RackAction = "Open gear rack", RackObject = "Your laptop", -- 3.2, 3.3
	-- §10 the door modes' labels (the plate's {MODE}; Task 14 cycles the mode, the default shows until then)
	Modes = { open = "OPEN", friends = "FRIENDS ONLY", locked = "LOCKED" },
	-- a stand-in's own prompts, as the bedroom asset's (bedroom_setup.lua: "Make a beat" / "Your laptop", "Leave" /
	-- "YOUR ROOM"; copy §3.3 names the laptop "Your laptop")
	LaptopObject = "Your laptop", ExitObject = "YOUR ROOM",
	StationNames = { bedroom = "YOUR ROOM", home = "HOME STUDIO", real = "REAL STUDIO" },
}

M.LANDING_HEIGHT = 10
M.RACK_SIDE = 0.6    -- studs, room-local +x of the Station: beside the laptop, within the same reach
M.RACK_UI_GAP = 88   -- px the rack's prompt is stacked off the laptop's (its UIOffset.Y): the default prompt's 72 px plus a gap
local DOOR_W, DOOR_H = 4, 8 -- a landing door frame's opening

function M.PlotName(k) return string.format("Plot_%02d", k) end
function M.RoomName(kind) return "Room_" .. tostring(kind) end

-- every kind in Config.Rooms.Kinds, ladder order
function M.KindOrder(cfg)
	local list = {}
	for kind in pairs(cfg.Kinds) do table.insert(list, kind) end
	table.sort(list, function(a, b) return (cfg.Kinds[a].order or 0) < (cfg.Kinds[b].order or 0) end)
	return list
end

-- the room-local CFrame of a Config anchor { x, y, z, nx, nz }: LookVector = its horizontal facing
function M.AnchorCFrame(a)
	local p = Vector3.new(a[1], a[2], a[3])
	local nx, nz = a[4] or 0, a[5] or 0
	if math.abs(nx) + math.abs(nz) < 1e-6 then return CFrame.new(p) end
	return CFrame.lookAt(p, p + Vector3.new(nx, 0, nz))
end

-- the Attachments the asset contract names for a kind, in a fixed order
function M.ContractAnchors(kindCfg)
	local list = { "Entrance", "VisitorSpot", "CritterSpot", "Desk_Speaker_L", "Desk_Speaker_R" }
	for i = 1, kindCfg.plaques or 0 do table.insert(list, "Plaque_" .. i) end
	for i = 1, kindCfg.posters or 0 do table.insert(list, "Poster_" .. i) end
	if kindCfg.booth then table.insert(list, "BoothSpot"); table.insert(list, "BoothCam") end
	return list
end

-- plot-local x of a kind's door: its `at` x plus its Entrance anchor's x (the bedroom's is the asset's own)
function M.DoorX(cfg, kind)
	local kc = cfg.Kinds[kind]
	local e = kc.anchors and kc.anchors.Entrance
	return kc.at[1] + (e and e[1] or 0)
end

-- a room's parts the contract names
function M.DoorOf(room)
	for _, d in ipairs(room:GetDescendants()) do
		if d:IsA("BasePart") and d:GetAttribute("RoomDoor") == true then return d end
	end
	return nil
end
function M.SpawnOf(room)
	local s = room:FindFirstChild("Spawn", true)
	return (s and s:IsA("BasePart")) and s or nil
end
function M.StationOf(room)
	for _, d in ipairs(room:GetDescendants()) do
		if d:IsA("BasePart") and d:GetAttribute("Kind") == "Station" and CS:HasTag(d, L.TAG) then return d end
	end
	return nil
end

-- a prompt in the house style (E / ButtonX, instant, no line of sight): untagged, so Systems/Rooms hooks it itself
local function prompt(part, name, action, object)
	local pp = Instance.new("ProximityPrompt")
	pp.Name = name; pp.ActionText = action; pp.ObjectText = object
	pp.MaxActivationDistance = Config.Interaction.MaxDistance; pp.HoldDuration = 0; pp.RequiresLineOfSight = false
	pp.KeyboardKeyCode = Enum.KeyCode.E; pp.GamepadKeyCode = Enum.KeyCode.ButtonX
	pp.Parent = part
	return pp
end
M.Prompt = prompt

-- the room door's sound: Config.SFX.Door's id (Config.SFX stays 17 keys), played by Systems/Rooms on a door press
function M.DoorSound(part)
	local def = Config.SFX and Config.SFX.Door
	if not def or part:FindFirstChild("DoorSFX") then return end
	local s = Instance.new("Sound")
	s.Name = "DoorSFX"; s.SoundId = def.id; s.Volume = def.volume or 0.6
	s.RollOffMode = Enum.RollOffMode.InverseTapered; s.RollOffMinDistance = 6; s.RollOffMaxDistance = 40
	s.Parent = part
end

-- an Attachment on `part` at a CFrame in the frame the part was built in
local function marker(part, name, cf)
	local a = Instance.new("Attachment")
	a.Name = name
	a.Parent = part -- parent first: an Attachment without a part treats WorldCFrame as its local CFrame
	a.WorldCFrame = cf
	return a
end

local function sign(parent, name, x0, y0, z0, x1, y1, z1, face, text)
	local s = L.boxMM(parent, name, x0, y0, z0, x1, y1, z1, { Color = L.C.black, CanCollide = false, CastShadow = false })
	L.textFace(s, face, text, { PixelsPerStud = 40, Padding = 4 })
	return s
end

-- Anchors ------------------------------------------------------------------------------------------------------------
function M.Anchors(room, kindCfg)
	local added = {}
	local anchors = kindCfg and kindCfg.anchors
	if type(anchors) ~= "table" then return added end
	local names = {}
	for name in pairs(anchors) do table.insert(names, name) end
	table.sort(names)
	local pivot = room:GetPivot()
	local holder
	for _, name in ipairs(names) do
		local have = room:FindFirstChild(name, true)
		if not (have and have:IsA("Attachment")) then
			if not holder then
				local h = room:FindFirstChild("Sockets", true)
				holder = (h and h:IsA("BasePart")) and h or nil
				if not holder then
					holder = L.part("Sockets", Vector3.new(0.2, 0.2, 0.2), pivot, { Transparency = 1, CanCollide = false,
						CanTouch = false, CanQuery = false, CastShadow = false })
					holder.Parent = room
				end
			end
			marker(holder, name, pivot * M.AnchorCFrame(anchors[name]))
			table.insert(added, name)
		end
	end
	return added
end

-- the rack spot (Task 6) ------------------------------------------------------------------------------------------------
function M.RackSpot(room)
	local have = room:FindFirstChild("RackSpot")
	if have then return have end
	local st = M.StationOf(room)
	if not st then return nil end
	local pivot = room:GetPivot()
	local rel = pivot:PointToObjectSpace(st.Position)
	-- queryable, as the bedroom asset leaves its laptop screen (bedroom_setup.lua) for its prompt; tiny and invisible
	local spot = L.part("RackSpot", Vector3.new(0.4, 0.4, 0.4), pivot * CFrame.new(rel.X + M.RACK_SIDE, rel.Y, rel.Z),
		{ Transparency = 1, CanCollide = false, CanTouch = false, CanQuery = true, CastShadow = false })
	L.tag(spot, "GearRack", M.Copy.RackObject)
	local pp = prompt(spot, "RackPrompt", M.Copy.RackAction, M.Copy.RackObject)
	pp.KeyboardKeyCode = Enum.KeyCode.F; pp.GamepadKeyCode = Enum.KeyCode.ButtonY
	pp.UIOffset = Vector2.new(0, -M.RACK_UI_GAP)
	spot.Parent = room
	return spot
end

-- stand-ins ----------------------------------------------------------------------------------------------------------
-- per kind: shell height, the door's opening, the desk { x, z, w, d } (top at y 3), the laptop screen { x, y, z }, the
-- chair's Seat { x, y, z, nx, nz }, the Spawn { x, z, nx, nz }. The bedroom's numbers are the asset's own
-- (bedroom_setup.lua, roblox_assemble.lua's Proxy_Desk); home's and real's match Config.Rooms' grid, keep and anchors.
local SHELL = {
	bedroom = { height = 9.89, door = 3.3, doorH = 8.24, desk = { -0.6081, -6.0762, 4.0541, 2.4324 },
		screen = { -0.1072, 3.7369, -7.0703 }, seat = { -0.4054, 1.7319, -3.6438, -0.2079, -0.9781 },
		spawn = { 1.6216, 2.8378, -0.6814, -0.7319 } },
	home = { height = 12, door = 4, doorH = 8, desk = { 0, -8.8, 4, 2.4 }, screen = { 0, 3.65, -9.3 },
		seat = { 0, 1.7, -6.4, 0, -1 }, spawn = { 6, 6.5, -0.6814, -0.7319 } },
	real = { height = 14, door = 4, doorH = 8, desk = { 0, -12.8, 5, 2.4 }, screen = { 0, 3.65, -13.3 },
		seat = { 0, 1.7, -10.4, 0, -1 }, spawn = { 12, 10, -0.6814, -0.7319 } },
}
-- a kind with no row above gets a shell worked out from its size and Entrance
local function shellFor(kind, kc)
	if SHELL[kind] then return SHELL[kind] end
	local W, D = kc.size[1], kc.size[2]
	local e = kc.anchors and kc.anchors.Entrance or { W / 2 - 4, 0, D / 2 - 1.5 }
	return { height = 12, door = 4, doorH = 8, desk = { 0, -D / 2 + 1.2, 4, 2.4 }, screen = { 0, 3.65, -D / 2 + 0.7 },
		seat = { 0, 1.7, -D / 2 + 3.6, 0, -1 }, spawn = { e[1] - 2, D / 2 - 3.5, -0.6814, -0.7319 } }
end

function M.StandIn(kind, kindCfg)
	local kc = kindCfg or Config.Rooms.Kinds[kind]
	assert(type(kc) == "table", "RoomBuild.StandIn: no Config.Rooms.Kinds row for " .. tostring(kind))
	local sh = shellFor(kind, kc)
	local W, D, H = kc.size[1], kc.size[2], sh.height
	local hw, hd = W / 2, D / 2
	local e = kc.anchors and kc.anchors.Entrance
	local ex = e and e[1] or (hw - 4)
	local dw, dh = sh.door, sh.doorH
	local C = L.C
	local wallP = { Material = Enum.Material.Plaster, Color = Color3.fromRGB(190, 178, 154) }
	local m = Instance.new("Model")
	m.Name = "StandIn_" .. tostring(kind)
	-- shell: walls 0.5 thick outside the interior, the south wall's opening at the Entrance's x
	L.boxMM(m, "Floor", -hw - 0.5, -1, -hd - 0.5, hw + 0.5, 0, hd + 0.5, { Material = Enum.Material.Carpet, Color = Color3.fromRGB(132, 122, 106) })
	L.boxMM(m, "Ceiling", -hw - 0.5, H, -hd - 0.5, hw + 0.5, H + 0.5, hd + 0.5, { Material = Enum.Material.Plaster, Color = Color3.fromRGB(196, 188, 166) })
	L.boxMM(m, "WallN", -hw - 0.5, 0, -hd - 0.5, hw + 0.5, H, -hd, wallP)
	L.boxMM(m, "WallE", hw, 0, -hd, hw + 0.5, H, hd, wallP)
	L.boxMM(m, "WallW", -hw - 0.5, 0, -hd, -hw, H, hd, wallP)
	L.boxMM(m, "WallS_L", -hw - 0.5, 0, hd, ex - dw / 2, H, hd + 0.5, wallP)
	L.boxMM(m, "WallS_R", ex + dw / 2, 0, hd, hw + 0.5, H, hd + 0.5, wallP)
	L.boxMM(m, "WallS_Head", ex - dw / 2, dh, hd, ex + dw / 2, H, hd + 0.5, wallP)
	-- the door (the contract's RoomDoor + ExitPrompt; Systems/Rooms enables the prompt on a plot's copy)
	local door = L.boxMM(m, "Door", ex - dw / 2, 0, hd + 0.1, ex + dw / 2, dh, hd + 0.4, { Material = Enum.Material.Wood, Color = Color3.fromRGB(132, 100, 70) })
	door:SetAttribute("RoomDoor", true)
	prompt(door, "ExitPrompt", M.Copy.LeaveAction, M.Copy.ExitObject).Enabled = false
	M.DoorSound(door)
	-- the desk, the laptop (the Station) and the chair
	local dk = sh.desk
	L.boxMM(m, "Desk", dk[1] - dk[3] / 2, 0, dk[2] - dk[4] / 2, dk[1] + dk[3] / 2, 3, dk[2] + dk[4] / 2, { Material = Enum.Material.Wood, Color = C.walnut })
	local sc = sh.screen
	local sp = Vector3.new(sc[1], sc[2], sc[3])
	L.boxMM(m, "Laptop_Base", sc[1] - 0.95, 3, sc[3] - 0.1, sc[1] + 0.95, 3.08, sc[3] + 1.2, { Color = C.steel, Material = Enum.Material.Metal, CanCollide = false })
	local screen = L.part("Screen", Vector3.new(1.9, 1.1, 0.08), CFrame.lookAt(sp, sp + Vector3.zAxis), { Color = Color3.fromRGB(14, 16, 26), CanCollide = false })
	screen.Parent = m
	L.tag(screen, "Station", M.Copy.LaptopObject, { StationName = M.Copy.StationNames[kind] or string.upper(tostring(kind)) })
	local okDefs, defs = pcall(require, RS.OK.Modules.Interactions)
	local action = okDefs and type(defs) == "table" and defs.Station and defs.Station.Action or "Make a beat"
	prompt(screen, "StationPrompt", action, M.Copy.LaptopObject)
	local st = sh.seat
	local seatPos = Vector3.new(st[1], st[2], st[3])
	local seat = Instance.new("Seat")
	seat.Name = "Seat_Chair"; seat.Anchored = true; seat.Size = Vector3.new(1.8, 0.25, 1.7)
	seat.CFrame = CFrame.lookAt(seatPos, seatPos + Vector3.new(st[4], 0, st[5]))
	seat.Material = Enum.Material.Fabric; seat.Color = Color3.fromRGB(44, 44, 50)
	seat.TopSurface = Enum.SurfaceType.Smooth; seat.BottomSurface = Enum.SurfaceType.Smooth
	seat.Parent = m
	L.boxMM(m, "Chair_Base", st[1] - 0.15, 0, st[3] - 0.15, st[1] + 0.15, st[2] - 0.12, st[3] + 0.15, { Color = C.steel, CanCollide = false })
	-- the Spawn: where you stand when you come in by the door, facing into the room
	local s = sh.spawn
	local s0 = Vector3.new(s[1], 0.05, s[2])
	local spawn = L.part("Spawn", Vector3.new(2, 0.1, 2), CFrame.lookAt(s0, s0 + Vector3.new(s[3], 0, s[4])),
		{ Transparency = 1, CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false })
	spawn:SetAttribute("Kind", "RoomSpawn")
	spawn.Parent = m
	-- the booth corner (home, real): a mat and a mic stand at BoothSpot
	local bs = kc.booth and kc.anchors and kc.anchors.BoothSpot
	if bs then
		L.boxMM(m, "Booth_Mat", bs[1] - 2.5, 0, bs[3] - 3, bs[1] + 2.5, 0.05, bs[3] + 3, { Material = Enum.Material.Fabric, Color = C.charcoal, CanCollide = false })
		L.boxMM(m, "Booth_MicStand", bs[1] - 0.08, 0, bs[3] + 0.9, bs[1] + 0.08, 5.2, bs[3] + 1.06, { Color = C.steel, Material = Enum.Material.Metal, CanCollide = false })
		L.boxMM(m, "Booth_Mic", bs[1] - 0.2, 5.2, bs[3] + 0.7, bs[1] + 0.2, 5.8, bs[3] + 1.1, { Color = C.black, CanCollide = false })
	end
	-- the one warm bulb (the user's call 2026-11-11: one light per room, as the bedroom asset's)
	local bulb = L.boxMM(m, "Bulb", -0.25, H - 0.6, -0.25, 0.25, H, 0.25, { Material = Enum.Material.Neon, Color = Color3.fromRGB(214, 172, 112), CanCollide = false, CastShadow = false })
	local light = Instance.new("PointLight")
	light.Brightness = 0.25; light.Range = 14; light.Color = Color3.fromRGB(255, 214, 170); light.Shadows = false
	light.Parent = bulb
	m:SetAttribute("OK_Room", tostring(kind))
	m:SetAttribute("StandIn", true)
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	m.WorldPivot = CFrame.new()
	M.Anchors(m, kc)
	return m
end

-- the landing --------------------------------------------------------------------------------------------------------
function M.Landing(cfg, owned, kinds)
	local len, wid, H = cfg.Landing.length, cfg.Landing.width, M.LANDING_HEIGHT
	local own = {}
	for _, kind in ipairs(owned or {}) do own[kind] = true end
	local C = L.C
	local wallP = { Material = Enum.Material.Plaster, Color = Color3.fromRGB(70, 66, 62) }
	local dark = { Color = C.black }
	local m = Instance.new("Model")
	m.Name = "Landing"
	L.boxMM(m, "Floor", -0.5, -1, -0.2, len + 0.5, 0, wid + 0.5, { Material = Enum.Material.WoodPlanks, Color = C.wood })
	L.boxMM(m, "Ceiling", -0.5, H, -0.2, len + 0.5, H + 0.5, wid + 0.5, { Material = Enum.Material.Concrete, Color = C.concrete })
	L.boxMM(m, "WallN", 0, 0, -0.2, len, H, 0, wallP)
	L.boxMM(m, "WallS", -0.5, 0, wid, len + 0.5, H, wid + 0.5, wallP)
	L.boxMM(m, "WallW", -0.5, 0, -0.2, 0, H, wid, wallP)
	L.boxMM(m, "WallE", len, 0, -0.2, len + 0.5, H, wid, wallP)
	L.neon(m, "CeilingStrip", Vector3.new(len / 2, H - 0.1, wid / 2), Vector3.new(len - 4, 0.15, 0.3), Color3.fromRGB(255, 214, 170))
	-- the front door: out to the building's hall
	local front = L.boxMM(m, "FrontDoor", 0, 0, wid / 2 - DOOR_W / 2, 0.3, DOOR_H, wid / 2 + DOOR_W / 2, { Material = Enum.Material.Wood, Color = C.walnut })
	prompt(front, "LeavePrompt", M.Copy.LeaveAction, M.Copy.LeaveObject)
	M.DoorSound(front)
	marker(front, "Inside", CFrame.lookAt(Vector3.new(3.5, 0, wid / 2), Vector3.new(4.5, 0, wid / 2)))
	-- a door frame per kind on the north wall
	for _, kind in ipairs(kinds or M.KindOrder(cfg)) do
		if cfg.Kinds[kind] then
			local x = M.DoorX(cfg, kind)
			local mine = own[kind] == true
			L.boxMM(m, "Post_L_" .. kind, x - DOOR_W / 2 - 0.4, 0, 0, x - DOOR_W / 2, DOOR_H + 0.4, 0.5, dark)
			L.boxMM(m, "Post_R_" .. kind, x + DOOR_W / 2, 0, 0, x + DOOR_W / 2 + 0.4, DOOR_H + 0.4, 0.5, dark)
			L.boxMM(m, "Header_" .. kind, x - DOOR_W / 2, DOOR_H, 0, x + DOOR_W / 2, DOOR_H + 0.4, 0.5, dark)
			local door = L.boxMM(m, "Door_" .. kind, x - DOOR_W / 2, 0, 0, x + DOOR_W / 2, DOOR_H, 0.3,
				{ Material = Enum.Material.Wood, Color = mine and C.walnut or Color3.fromRGB(40, 36, 34) })
			door:SetAttribute("RoomKind", kind)
			local words
			if mine then
				words = M.Copy.Names[kind] or string.upper(kind)
				prompt(door, "RoomPrompt", M.Copy.GoIn, M.Copy.Objects[kind] or kind)
				M.DoorSound(door)
				marker(door, "Out", CFrame.lookAt(Vector3.new(x, 0, 3.5), Vector3.new(x - 1, 0, 3.5)))
			else
				words = (M.Copy.LockedSign[kind] or (string.upper(kind) .. " · LOCKED")) .. "\n" .. M.Copy.LockedHint
			end
			sign(m, "Sign_" .. kind, x - 3.5, DOOR_H + 0.5, 0, x + 3.5, H - 0.3, 0.2, Enum.NormalId.Back, words)
		end
	end
	m:SetAttribute("OK_Room", "landing")
	m.WorldPivot = CFrame.new()
	return m
end

-- the plot -----------------------------------------------------------------------------------------------------------
local function templateFor(template, kind)
	if typeof(template) == "Instance" then return kind == "bedroom" and template or nil end
	if type(template) == "table" then return template[kind] end
	return nil
end

function M.Plot(k, owned, cfg, template, owner)
	local ox, oy, oz = Rules.PlotOrigin(k, cfg)
	local O = CFrame.new(ox, oy, oz)
	local plot = Instance.new("Model")
	plot.Name = M.PlotName(k)
	plot.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	plot:SetAttribute("Plot", k)
	if owner then plot:SetAttribute("OwnerId", owner.id); plot:SetAttribute("OwnerName", owner.name) end
	local landing = M.Landing(cfg, owned)
	landing:PivotTo(O)
	landing.Parent = plot
	for _, kind in ipairs(owned or {}) do
		local kc = cfg.Kinds[kind]
		if kc then
			local src = templateFor(template, kind)
			local room = src and src:Clone() or M.StandIn(kind, kc)
			room.Name = M.RoomName(kind)
			room:PivotTo(O * CFrame.new(kc.at[1], 0, kc.at[2]))
			room.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
			M.Anchors(room, kc)
			room:SetAttribute("RoomKind", kind)
			room:SetAttribute("Plot", k)
			if owner then room:SetAttribute("OwnerId", owner.id); room:SetAttribute("OwnerName", owner.name) end
			local door = M.DoorOf(room)
			local exit = door and door:FindFirstChild("ExitPrompt")
			if exit and exit:IsA("ProximityPrompt") then exit.Enabled = true end
			if door then M.DoorSound(door) end
			M.RackSpot(room) -- before the plot is parented: InteractionService.Adopt hooks it with the Station
			room.Parent = plot
		end
	end
	plot.WorldPivot = O
	return plot
end

return M
