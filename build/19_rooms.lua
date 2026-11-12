-- 19: your rooms' shared building (the Your Rooms plan, Task 2). STRUCTURE, idempotent (OK_Build = "19_rooms"); run in
-- Edit after 18_gates, before Play. It runs before OK/Config and Modules/RoomBuild are synced, so its numbers and words
-- are literal copies (build/t100_check.lua holds them to the live Config.Rooms and RoomBuild.Copy). It makes:
-- * the remotes RemoteFunction Room_Get and Room_Edit and RemoteEvent Room (ReplicatedStorage.OK.Remotes), and the folder
--   ReplicatedStorage.OK.RoomPlaying with one Folder Plot_01..Plot_12 per slot (NowPlaying's attribute names plus Tier and
--   Room), for the room plays of Task 7;
-- * Workspace.OK_Rooms (Persistent): the Hall at Config.Rooms.Hall (3000, 0, 0), 16 x 104 x 14, floor top y 0: 12 doors
--   (6 a side) Door_01..Door_12, each with an untagged EnterPrompt (off until a slot is claimed), an Attachment Front
--   (where you arrive in front of it, facing into the hall), a name plate Plate_NN ("STUDIO 07"), a neon strip, posts, a
--   header and a mat; HallSpawn (south end, facing north), the HubDoor with an untagged HubPrompt (back to the studio)
--   and the lobby sign. Then the corridor's RoomsDoor at (0.3, 4, 5) on the inside face of OKStudio.Shell.Wall_Corr_W
--   (4 x 8), with an untagged RoomsPrompt (reach 6), a sign above it and an Attachment Front (where you arrive from the
--   hall). Every part is
--   anchored; no lights, no scripts, no tags (Systems/Rooms hooks the prompts itself); each door carries a DoorSFX sound
--   with Config.SFX.Door's id. RoomsDoor lives in OK_Rooms, not OKStudio, because 02_shell rebuilds OKStudio.
-- * streaming on: workspace.StreamingEnabled, StreamingMinRadius 64, StreamingTargetRadius 1024, StreamOutBehavior
--   LowMemory. ModelStreamingMode = Persistent on the hub's own build models only (preflight F10, the controller's
--   ruling): OKStudio, OK_Gates, OK_Passage_Interscope, OK_Passage_StudioTwo and OK_Rooms (and its Hall). Other
--   sessions' imports (Env_studio_two, Env_interscope_la, ~50-65 studs from the hub) keep their own mode, and
--   Env_bedroom_starter stays Atomic: it is Systems/Rooms' template.
-- Streaming is a place setting: the user's save keeps it. Rerun this after 18_gates or ok_assets'
-- connect_studio_two.py / the Interscope passage script: they rebuild OK_Gates and OK_Passage_* as Default-mode Models,
-- which drops Persistent (t100 goes red when that happens).
local function freshRequire(mod)
  local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name
  local ok, res = pcall(require, c); c:Destroy(); if not ok then error(res) end; return res
end
local RS = game:GetService("ReplicatedStorage")
local L = require(RS.OK.BuildLib)
local B = "19_rooms"
local Config = freshRequire(RS.OK.Config)
-- literal until OK/Config is synced (t100 holds them equal)
local SLOTS, HALL = 12, Vector3.new(3000, 0, 0)
local DOOR_SFX = (Config.SFX and Config.SFX.Door) or { id = "rbxassetid://9119203830", volume = 0.6 }
local REACH = (Config.Interaction and Config.Interaction.MaxDistance) or 8
-- research/rooms/copy_2026-11-12.md §1 (Modules/RoomBuild's Copy holds the same lines)
local COPY = {
  BuildingSign = "THE BUILDING\nYOUR DOOR IS INSIDE", BuildingAction = "Go inside", BuildingObject = "The building",
  LobbySign = "THE BUILDING\nFIND YOUR NAME ON A DOOR",
  HubSign = "BACK TO THE STUDIO", HubAction = "Go back", HubObject = "The studio",
  PlateEmpty = "STUDIO %02d",
}
local PERSISTENT = { "OKStudio", "OK_Gates", "OK_Passage_Interscope", "OK_Passage_StudioTwo" }
local NEON = { Color3.fromRGB(255, 60, 160), Color3.fromRGB(0, 200, 255), Color3.fromRGB(255, 170, 40),
  Color3.fromRGB(120, 255, 120), Color3.fromRGB(190, 110, 255), Color3.fromRGB(255, 70, 70) }

local shell = workspace:FindFirstChild("OKStudio") and workspace.OKStudio:FindFirstChild("Shell")
local corrW = shell and shell:FindFirstChild("Wall_Corr_W")
assert(corrW and corrW:IsA("BasePart"), "OKStudio.Shell.Wall_Corr_W missing: rebuild the shell (02) first")

-- 1. remotes and the room-play folders ------------------------------------------------------------------------------
local Remotes = RS.OK.Remotes
local function ensure(parent, class, name)
  local i = parent:FindFirstChild(name)
  if not i or i.ClassName ~= class then if i then i:Destroy() end; i = Instance.new(class); i.Name = name; i.Parent = parent end
  return i
end
ensure(Remotes, "RemoteFunction", "Room_Get"); ensure(Remotes, "RemoteFunction", "Room_Edit"); ensure(Remotes, "RemoteEvent", "Room")
local playing = ensure(RS.OK, "Folder", "RoomPlaying")
for _, c in ipairs(playing:GetChildren()) do if not c.Name:match("^Plot_%d%d$") or tonumber(c.Name:sub(6)) > SLOTS then c:Destroy() end end
local NP_ATTRS = { Active = false, Beat = "", BPM = 0, Swing = 0, OwnerId = 0, OwnerName = "", StartAt = 0, Loops = 0, EndsAt = 0,
  Kit = "studio", Voice = "", Token = 0, Tier = 1, Room = "" }
for k = 1, SLOTS do
  local f = ensure(playing, "Folder", string.format("Plot_%02d", k))
  for a, v in pairs(NP_ATTRS) do if f:GetAttribute(a) == nil then f:SetAttribute(a, v) end end
end

-- 2. the hall and the corridor's door -------------------------------------------------------------------------------
L.clear(B)
local C = L.C
local rooms = Instance.new("Model"); rooms.Name = "OK_Rooms"
local hall = Instance.new("Model"); hall.Name = "Hall"; hall.Parent = rooms
hall:SetAttribute("Origin", HALL)
local function prompt(part, name, action, object, reach)
  local pp = Instance.new("ProximityPrompt")
  pp.Name = name; pp.ActionText = action; pp.ObjectText = object
  pp.MaxActivationDistance = reach or REACH; pp.HoldDuration = 0; pp.RequiresLineOfSight = false
  pp.KeyboardKeyCode = Enum.KeyCode.E; pp.GamepadKeyCode = Enum.KeyCode.ButtonX
  pp.Parent = part
  return pp
end
local function doorSound(part)
  local s = Instance.new("Sound")
  s.Name = "DoorSFX"; s.SoundId = DOOR_SFX.id; s.Volume = DOOR_SFX.volume or 0.6
  s.RollOffMode = Enum.RollOffMode.InverseTapered; s.RollOffMinDistance = 6; s.RollOffMaxDistance = 40
  s.Parent = part
end
local function marker(part, name, cf)
  local a = Instance.new("Attachment"); a.Name = name
  a.Parent = part -- parent first: an Attachment without a part treats WorldCFrame as its local CFrame
  a.WorldCFrame = cf
  return a
end
local function P(parent, name, size, cf, props)
  local p = L.part(name, size, cf, props); p.Parent = parent; return p
end
local HW, HL, H = 16, 104, 14
local function at(x, y, z) return HALL + Vector3.new(x, y, z) end
local wallP = { Material = Enum.Material.Plaster, Color = C.concreteLight }
P(hall, "Floor", Vector3.new(HW + 2, 1, HL + 2), CFrame.new(at(HW / 2, -0.5, HL / 2)), { Material = Enum.Material.Concrete, Color = C.concrete })
P(hall, "Ceiling", Vector3.new(HW + 2, 1, HL + 2), CFrame.new(at(HW / 2, H + 0.5, HL / 2)), { Material = Enum.Material.Concrete, Color = C.concrete })
P(hall, "WallW", Vector3.new(1, H, HL), CFrame.new(at(-0.5, H / 2, HL / 2)), wallP)
P(hall, "WallE", Vector3.new(1, H, HL), CFrame.new(at(HW + 0.5, H / 2, HL / 2)), wallP)
P(hall, "WallN", Vector3.new(HW + 2, H, 1), CFrame.new(at(HW / 2, H / 2, HL + 0.5)), wallP)
P(hall, "WallS", Vector3.new(HW + 2, H, 1), CFrame.new(at(HW / 2, H / 2, -0.5)), wallP)
P(hall, "CeilingStrip", Vector3.new(0.4, 0.2, HL - 4), CFrame.new(at(HW / 2, H - 0.3, HL / 2)), { Material = Enum.Material.Neon, Color = C.white, CanCollide = false })
local lobby = P(hall, "LobbySign", Vector3.new(12, 2.4, 0.3), CFrame.new(at(HW / 2, 11, 7)), { Color = C.black, CanCollide = false })
L.textFace(lobby, Enum.NormalId.Front, COPY.LobbySign, { PixelsPerStud = 40, Padding = 6 })
local hub = P(hall, "HubDoor", Vector3.new(6, 8, 0.4), CFrame.new(at(HW / 2, 4, 0.2)), { Material = Enum.Material.Wood, Color = C.walnut })
prompt(hub, "HubPrompt", COPY.HubAction, COPY.HubObject)
doorSound(hub)
local hubSign = P(hall, "HubSign", Vector3.new(7, 1.4, 0.2), CFrame.new(at(HW / 2, 9, 0.1)), { Color = C.black, CanCollide = false })
L.textFace(hubSign, Enum.NormalId.Back, COPY.HubSign, { PixelsPerStud = 40, Padding = 4 })
local s0 = at(HW / 2, 0.05, 4)
P(hall, "HallSpawn", Vector3.new(2, 0.1, 2), CFrame.lookAt(s0, s0 + Vector3.zAxis),
  { Transparency = 1, CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false })
for k = 1, SLOTS do
  local west = k <= SLOTS / 2
  local z = 10 + ((k - 1) % (SLOTS / 2)) * 16
  local p = at(west and 0.3 or HW - 0.3, 4.5, z)
  local cf = CFrame.lookAt(p, p + Vector3.new(west and 1 or -1, 0, 0)) -- LookVector (Front) into the hall
  local num = string.format("%02d", k)
  local door = P(hall, "Door_" .. num, Vector3.new(6, 9, 0.4), cf, { Material = Enum.Material.Wood, Color = C.walnut })
  door:SetAttribute("Slot", k)
  prompt(door, "EnterPrompt", "Enter", string.format(COPY.PlateEmpty, k)).Enabled = false
  doorSound(door)
  marker(door, "Front", cf * CFrame.new(0, -4.5, -5))
  P(hall, "PostL_" .. num, Vector3.new(0.5, 9.5, 0.6), cf * CFrame.new(-3.25, 0.25, 0), { Color = C.black })
  P(hall, "PostR_" .. num, Vector3.new(0.5, 9.5, 0.6), cf * CFrame.new(3.25, 0.25, 0), { Color = C.black })
  P(hall, "Header_" .. num, Vector3.new(7, 0.5, 0.6), cf * CFrame.new(0, 4.75, 0), { Color = C.black })
  local plate = P(hall, "Plate_" .. num, Vector3.new(5.6, 1.8, 0.2), cf * CFrame.new(0, 5.9, -0.15), { Color = C.black, CanCollide = false })
  L.textFace(plate, Enum.NormalId.Front, string.format(COPY.PlateEmpty, k), { PixelsPerStud = 40, Padding = 4 })
  P(hall, "Neon_" .. num, Vector3.new(4, 0.3, 0.15), cf * CFrame.new(0, 7.2, -0.15), { Material = Enum.Material.Neon, Color = NEON[(k - 1) % #NEON + 1], CanCollide = false })
  P(hall, "Mat_" .. num, Vector3.new(4, 0.1, 2), CFrame.new(at(west and 2 or HW - 2, 0.05, z)), { Material = Enum.Material.Fabric, Color = C.maroon, CanCollide = false })
end
-- the corridor's door at (0.3, 4, 5), on Wall_Corr_W's inside face: the wall spans x -0.5..0.5, so the slab is 0.8 thick
-- (x -0.1..0.7) and its face stands 0.2 proud of the wall's (a 0.4 slab there would sit flush with it and flicker)
local face = corrW.Position.X + corrW.Size.X / 2
local RD_X, RD_T = 0.3, 0.8
assert(RD_X + RD_T / 2 > face + 0.05 and RD_X - RD_T / 2 < face, string.format("RoomsDoor at x %.2f (%.2f thick) misses Wall_Corr_W's inside face at x %.2f", RD_X, RD_T, face))
local rd = P(rooms, "RoomsDoor", Vector3.new(RD_T, 8, 4), CFrame.new(RD_X, 4, 5), { Material = Enum.Material.Wood, Color = C.walnut })
prompt(rd, "RoomsPrompt", COPY.BuildingAction, COPY.BuildingObject, 6) -- 6: the spawn pad's prompts stay the nearer ones
doorSound(rd)
marker(rd, "Front", CFrame.lookAt(Vector3.new(face + 3, 0, 5), Vector3.new(face + 4, 0, 5)))
local rs = P(rooms, "RoomsSign", Vector3.new(0.2, 1.4, 4.6), CFrame.new(face + 0.15, 8.9, 5), { Color = C.black, CanCollide = false })
L.textFace(rs, Enum.NormalId.Right, COPY.BuildingSign, { PixelsPerStud = 40, Padding = 4 })
rooms.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
hall.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
L.mark(rooms, B); L.markAll(rooms, B)
for _, d in ipairs(rooms:GetDescendants()) do if d:IsA("Attachment") or d:IsA("Sound") then L.mark(d, B) end end
rooms.Parent = workspace

-- 3. streaming -------------------------------------------------------------------------------------------------------
workspace.StreamingEnabled = true
workspace.StreamingMinRadius = 64
workspace.StreamingTargetRadius = 1024
workspace.StreamOutBehavior = Enum.StreamOutBehavior.LowMemory
local set, missing = {}, {}
for _, name in ipairs(PERSISTENT) do
  local m = workspace:FindFirstChild(name)
  if m and m:IsA("Model") then m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent; table.insert(set, name)
  else table.insert(missing, name) end
end
table.insert(set, "OK_Rooms")
local others = {}
for _, c in ipairs(workspace:GetChildren()) do
  if c:IsA("Model") and not table.find(set, c.Name) then table.insert(others, c.Name .. "=" .. c.ModelStreamingMode.Name) end
end
table.sort(others)

local parts, lights = 0, 0
for _, d in ipairs(rooms:GetDescendants()) do
  if d:IsA("BasePart") then parts += 1 end
  if d:IsA("Light") then lights += 1 end
end
return string.format("19 rooms ok: hall at (%d, %d, %d) with %d doors, RoomsDoor at (%.2f, 4, 5); %d parts, %d lights; streaming on (min 64, target 1024, LowMemory); Persistent: %s%s; others kept: %s; remotes Room_Get, Room_Edit, Room; RoomPlaying x%d",
  HALL.X, HALL.Y, HALL.Z, SLOTS, RD_X, parts, lights, table.concat(set, ", "),
  #missing > 0 and (" (MISSING: " .. table.concat(missing, ", ") .. ")") or "", #others > 0 and table.concat(others, ", ") or "none", SLOTS)
