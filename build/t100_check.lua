-- Edit: the Your Rooms plan, Task 2 (plots, the shared building, the wake-up and streaming). On the place after
-- build/19_rooms.lua and the sync of Modules/RoomRules, Data/RoomCatalog, Modules/RoomBuild, Systems/Rooms,
-- Services/InteractionService and OK/Config:
-- (1) the building: Workspace.OK_Rooms (Persistent) holds the Hall at Config.Rooms.Hall with exactly Config.Rooms.Slots
--     doors Door_01.., each with an EnterPrompt (off until a slot is claimed), an Attachment Front on the hall's floor
--     and a plate Plate_NN reading "STUDIO NN"; HallSpawn on the floor; the HubDoor with its HubPrompt; and the corridor's
--     RoomsDoor at (0.3, 4, 5), its face proud of OKStudio.Shell.Wall_Corr_W's inside face, with its RoomsPrompt and a
--     Front attachment in the corridor. 0 Lights under OK_Rooms, every part anchored, nothing tagged OK_Interactable
--     (Systems/Rooms hooks the prompts itself), no scripts.
-- (2) the remotes Room_Get and Room_Edit (RemoteFunction) and Room (RemoteEvent); ReplicatedStorage.OK.RoomPlaying holds
--     exactly the Folders Plot_01..Plot_12.
-- (3) streaming on with StreamingMinRadius 64, StreamingTargetRadius 1024, StreamOutBehavior LowMemory; the Persistent
--     top-level Models are exactly OKStudio, OK_Gates, OK_Passage_Interscope, OK_Passage_StudioTwo and OK_Rooms (the
--     controller's F10 ruling: other sessions' imports keep their mode); Env_bedroom_starter, when in Workspace, Atomic.
-- (4) Systems/Rooms and InteractionService.Adopt are in the place; the building's prompts and plates carry
--     Modules/RoomBuild's Copy (research/rooms/copy_2026-11-12.md §1).
-- (5) RoomBuild.StandIn for bedroom, home and real carries the asset contract by name: OK_Room and StandIn set, Atomic,
--     its pivot at the origin and its floor top at y 0, one RoomDoor part on the south wall with a (disabled) ExitPrompt,
--     exactly one Station (tagged, Kind "Station", a StationName, a prompt), Seat_Chair, a Spawn inside the room, inside
--     one of the kind's keep areas and facing into the room, every RoomBuild.ContractAnchors Attachment where
--     Config.Rooms puts it, at most 1 Light and no MeshPart.
-- (6) RoomBuild.Anchors adds exactly the missing anchors: a Model holding Entrance (somewhere else) and Plaque_2 gets the
--     other six, Entrance left where it was; a bare Model (no part) gets all eight on a Sockets part it makes; a second
--     run adds none.
-- (7) the hub's counts are unmoved (Modules/RoomScope, as t03 / t07 / 09_qa / 14_stations take them): lights <= 61,
--     12 tagged interactables, 2 Stations; no room over its one light.
-- (8) the literal copy of Config.Rooms below (spec/room_rules_spec.lua holds the same one: an Edit check can't read
--     spec/ from disk) equals the live Config.Rooms, field by field.
-- Nothing is parented into the place: the stand-ins and fixtures are built unparented and destroyed. Marker "T100 OK".
-- The expected red, before build/19_rooms.lua: (1) "Workspace.OK_Rooms missing".
local RS, CS = game:GetService("ReplicatedStorage"), game:GetService("CollectionService")
local function freshRequire(mod) -- edit-mode require caches modules across runs; load a clone so edits take effect
  local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name
  local ok, res = pcall(require, c); c:Destroy(); if not ok then error(res) end; return res
end
local TAG = "OK_Interactable"
local CAP = 61
local PERSISTENT = { OKStudio = true, OK_Gates = true, OK_Passage_Interscope = true, OK_Passage_StudioTwo = true, OK_Rooms = true }

-- a literal copy of Config.Rooms (src/ReplicatedStorage/OK/Config.lua); spec/room_rules_spec.lua holds the same
local FIXTURE = {
  Slots = 12, PlotOrigin = { 6000, 0, -2000 }, PlotCols = 4, PlotSpacing = 2000,
  Hall = { 3000, 0, 0 }, -- the shared building's hall origin (build/19_rooms.lua builds it there; preflight m3: fixed)
  Template = "Env_bedroom_starter", PlayCooldown = 1, Edit = { burst = 5, every = 0.2 }, ItemParts = 12,
  Landing = { length = 110, width = 8 }, -- plot-local x 0..110, z 0..8; its front door at x 0
  DoorModes = { "open", "friends", "locked" }, DoorDefault = "friends",
  Kinds = { -- ladder order
    bedroom = { order = 1, at = { 10, -8 }, size = { 12.36, 14.83 }, limit = 6, plaques = 3, posters = 0, booth = false,
      grid = { { -1, -0.5, 2, 2 }, { 3, 0.5, 5.8, 3 }, { -6, -7, -3, -1 } },
      keep = { { 0.6, 1.8, 2.6, 3.8 },                                            -- Spawn (its 2 x 2 plate)
        { 1.0, -1.5, 2.9, 1.0 }, { 1.7, 1.0, 3.7, 3.0 }, { 2.4, 3.0, 4.7, 6.2 },  -- Entrance -> VisitorSpot, 1.2 wide
        { -1.2, -0.5, 0.7, 1.5 } },                                               -- CritterSpot (the pigeon, turned)
      anchors = { Entrance = { 4.0849, 0, 5.5897, 0, -1 }, VisitorSpot = { 1.6014, 0, -0.7986, -0.5764, -0.8172 },
        CritterSpot = { -0.2027, 0, 0.6081, 0.6332, 0.774 },
        Plaque_1 = { 6.1784, 5.3919, -4.3986, -1, 0 }, Plaque_2 = { 6.1784, 5.3919, -2.2014, -1, 0 },
        Plaque_3 = { 6.1784, 5.3919, 0, -1, 0 },
        Desk_Speaker_L = { -2.2297, 3, -6.8059, 0, 1 }, Desk_Speaker_R = { 1.0135, 3, -6.8059, 0, 1 } } },
    -- home and real: Task 2's code-built stand-ins (Modules/RoomBuild): door on the south wall's east end, desk on the north
    -- wall, booth in the north-west corner; first guesses until the user's imports land (their free floor goes here then)
    home = { order = 2, gate = "home_studio", at = { 40, -10.6 }, size = { 24, 20 }, limit = 16, plaques = 6, posters = 4, booth = true,
      grid = { { -5, -4, 5, 9 }, { 5, -9, 11, 4 }, { -11, -2, -5, 9 } },
      keep = { { 5, 5.5, 7, 7.5 },                                                -- Spawn (its 2 x 2 plate)
        { 5.4, 3.8, 8.6, 9.1 }, { 3.4, -0.2, 6.6, 5.1 }, { 1.4, -4.2, 4.6, 1.0 },  -- Entrance -> VisitorSpot
        { -2.5, 1, -0.5, 3 },                                                      -- CritterSpot
        { 6, 8.4, 10, 10 } },                                                      -- just inside the door
      anchors = { Entrance = { 8, 0, 8.5, 0, -1 }, VisitorSpot = { 2, 0, -3.6, -0.5764, -0.8172 },
        CritterSpot = { -1.5, 0, 2, 0.6332, 0.774 },
        Desk_Speaker_L = { -1.6, 3, -9.3, 0, 1 }, Desk_Speaker_R = { 1.6, 3, -9.3, 0, 1 },
        Plaque_1 = { 12, 5.4, -7.5, -1, 0 }, Plaque_2 = { 12, 5.4, -5, -1, 0 }, Plaque_3 = { 12, 5.4, -2.5, -1, 0 },
        Plaque_4 = { 12, 5.4, 0, -1, 0 }, Plaque_5 = { 12, 5.4, 2.5, -1, 0 }, Plaque_6 = { 12, 5.4, 5, -1, 0 },
        Poster_1 = { -12, 5.5, -6, 1, 0 }, Poster_2 = { -12, 5.5, -2, 1, 0 }, Poster_3 = { -12, 5.5, 2, 1, 0 },
        Poster_4 = { -12, 5.5, 6, 1, 0 },
        BoothSpot = { -8.5, 0, -6.5, 0, 1 }, BoothCam = { -8.5, 5, -1.5, 0, -1 } } },
    real = { order = 3, gate = "real_studio", at = { 85, -14.6 }, size = { 36, 28 }, limit = 24, plaques = 10, posters = 6, booth = true,
      grid = { { -8, -7, 8, 12 }, { 8, -12, 17, 8 }, { -17, -4, -8, 13 } },
      keep = { { 11, 9, 13, 11 },                                                 -- Spawn (its 2 x 2 plate)
        { 9.4, 5.2, 14.6, 13.1 }, { 5.4, -1.5, 10.6, 6.4 }, { 1.4, -8.2, 6.6, -0.3 }, -- Entrance -> VisitorSpot
        { -3, 2, -1, 4 },                                                           -- CritterSpot
        { 12, 12.4, 16, 14 } },                                                     -- just inside the door
      anchors = { Entrance = { 14, 0, 12.5, 0, -1 }, VisitorSpot = { 2, 0, -7.6, -0.5764, -0.8172 },
        CritterSpot = { -2, 0, 3, 0.6332, 0.774 },
        Desk_Speaker_L = { -2.1, 3, -13.4, 0, 1 }, Desk_Speaker_R = { 2.1, 3, -13.4, 0, 1 },
        Plaque_1 = { 18, 5.4, -11.25, -1, 0 }, Plaque_2 = { 18, 5.4, -8.75, -1, 0 }, Plaque_3 = { 18, 5.4, -6.25, -1, 0 },
        Plaque_4 = { 18, 5.4, -3.75, -1, 0 }, Plaque_5 = { 18, 5.4, -1.25, -1, 0 }, Plaque_6 = { 18, 5.4, 1.25, -1, 0 },
        Plaque_7 = { 18, 5.4, 3.75, -1, 0 }, Plaque_8 = { 18, 5.4, 6.25, -1, 0 }, Plaque_9 = { 18, 5.4, 8.75, -1, 0 },
        Plaque_10 = { 18, 5.4, 11.25, -1, 0 },
        Poster_1 = { -18, 5.5, -10, 1, 0 }, Poster_2 = { -18, 5.5, -6, 1, 0 }, Poster_3 = { -18, 5.5, -2, 1, 0 },
        Poster_4 = { -18, 5.5, 2, 1, 0 }, Poster_5 = { -18, 5.5, 6, 1, 0 }, Poster_6 = { -18, 5.5, 10, 1, 0 },
        BoothSpot = { -13.5, 0, -10, 0, 1 }, BoothCam = { -13.5, 5, -4, 0, -1 } } },
  },
  Speakers = {
    { gear = nil,            rolloff = { 2, 8 },   volume = 0.5, eq = { -20, -4, 0 } },
    { gear = "spk_monitors", rolloff = { 6, 24 },  volume = 1.0, eq = { -6, 0, 0 } },
    { gear = "spk_studio",   rolloff = { 10, 45 }, volume = 1.4, eq = { 0, 0, 2 } },
  },
  PosterWords = { "LOUD", "GRIND", "DREAM", "BASS", "VIBES", "FIRE", "GOLD", "NIGHT", "FOCUS", "HUSTLE", "RISE", "SOON" },
  PosterColors = {
    { 235, 64, 52 }, { 255, 150, 40 }, { 255, 214, 60 }, { 0, 200, 120 },
    { 60, 130, 255 }, { 150, 90, 240 }, { 230, 45, 145 }, { 28, 28, 34 },
  },
  PosterStyles = 3,
  PosterColorNames = { "RED", "ORANGE", "YELLOW", "GREEN", "BLUE", "PURPLE", "PINK", "BLACK" },
  PosterStyleNames = { "BOLD", "FRAMED", "STACKED" },
  PosterColorInk = {
    { 245, 245, 245 }, { 24, 24, 28 }, { 24, 24, 28 }, { 24, 24, 28 },
    { 245, 245, 245 }, { 245, 245, 245 }, { 245, 245, 245 }, { 245, 245, 245 },
  },
}

local out = {}
local function near(a, b, eps) return math.abs(a - b) <= (eps or 1e-3) end
local function v3(t) return Vector3.new(t[1], t[2], t[3]) end
local function str(v) return typeof(v) == "Vector3" and string.format("(%.2f, %.2f, %.2f)", v.X, v.Y, v.Z) or tostring(v) end

-- (1) the building -----------------------------------------------------------------------------------------------------
local rooms = workspace:FindFirstChild("OK_Rooms")
assert(rooms and rooms:IsA("Model"), "Workspace.OK_Rooms missing: run build/19_rooms.lua in Edit")
local hall = rooms:FindFirstChild("Hall")
assert(hall and hall:IsA("Model"), "OK_Rooms.Hall missing (got " .. tostring(hall and hall.ClassName) .. ")")
local origin = v3(FIXTURE.Hall)
assert(hall:GetAttribute("Origin") == origin, "the hall's Origin is " .. str(hall:GetAttribute("Origin")) .. ", want Config.Rooms.Hall " .. str(origin))
local floor = hall:FindFirstChild("Floor")
assert(floor and floor:IsA("BasePart"), "the hall has no Floor part")
assert(near(floor.Position.Y + floor.Size.Y / 2, origin.Y), "the hall's floor top is at y " .. (floor.Position.Y + floor.Size.Y / 2) .. ", want " .. origin.Y)
local function onHallFloor(p, label)
  local lp = floor.CFrame:PointToObjectSpace(p)
  assert(math.abs(lp.X) <= floor.Size.X / 2 and math.abs(lp.Z) <= floor.Size.Z / 2, label .. " at " .. str(p) .. " is off the hall's floor")
  assert(near(p.Y, origin.Y, 0.2), label .. " is at y " .. p.Y .. ", want the floor (" .. origin.Y .. ")")
end
local slots = FIXTURE.Slots
for k = 1, slots do
  local num = string.format("%02d", k)
  local door = hall:FindFirstChild("Door_" .. num)
  assert(door and door:IsA("BasePart"), "the hall has no Door_" .. num)
  local pp = door:FindFirstChild("EnterPrompt")
  assert(pp and pp:IsA("ProximityPrompt"), "Door_" .. num .. " has no EnterPrompt")
  assert(pp.Enabled == false, "Door_" .. num .. "'s EnterPrompt is on in Edit, want off until a slot is claimed")
  assert(door:GetAttribute("Slot") == k, "Door_" .. num .. "'s Slot attribute is " .. tostring(door:GetAttribute("Slot")) .. ", want " .. k)
  local front = door:FindFirstChild("Front")
  assert(front and front:IsA("Attachment"), "Door_" .. num .. " has no Front attachment")
  onHallFloor(front.WorldPosition, "Door_" .. num .. ".Front")
  assert(front.WorldCFrame.LookVector:Dot(door.CFrame.LookVector) > 0.99, "Door_" .. num .. ".Front should face into the hall, as the door does")
  local plate = hall:FindFirstChild("Plate_" .. num)
  local gui = plate and plate:FindFirstChild("Text")
  local label = gui and gui:FindFirstChild("Label")
  assert(label and label.Text == "STUDIO " .. num, "Plate_" .. num .. " reads '" .. tostring(label and label.Text) .. "', want 'STUDIO " .. num .. "'")
end
assert(hall:FindFirstChild(string.format("Door_%02d", slots + 1)) == nil, "the hall has a door past Config.Rooms.Slots (" .. slots .. ")")
local spawn = hall:FindFirstChild("HallSpawn")
assert(spawn and spawn:IsA("BasePart"), "the hall has no HallSpawn")
onHallFloor(spawn.Position - Vector3.new(0, spawn.Size.Y / 2, 0), "HallSpawn")
local hub = hall:FindFirstChild("HubDoor")
local hubPrompt = hub and hub:FindFirstChild("HubPrompt")
assert(hubPrompt and hubPrompt:IsA("ProximityPrompt"), "the hall's HubDoor (or its HubPrompt) is missing")
local shell = workspace:FindFirstChild("OKStudio") and workspace.OKStudio:FindFirstChild("Shell")
local corrW = shell and shell:FindFirstChild("Wall_Corr_W")
assert(corrW, "OKStudio.Shell.Wall_Corr_W missing")
local face = corrW.Position.X + corrW.Size.X / 2
local rd = rooms:FindFirstChild("RoomsDoor")
assert(rd and rd:IsA("BasePart"), "OK_Rooms.RoomsDoor missing")
assert((rd.Position - Vector3.new(0.3, 4, 5)).Magnitude < 0.01, "RoomsDoor is at " .. str(rd.Position) .. ", want (0.30, 4.00, 5.00)")
assert(rd.Position.X + rd.Size.X / 2 > face + 0.05, string.format("RoomsDoor's face (x %.2f) is not proud of Wall_Corr_W's inside face (x %.2f)", rd.Position.X + rd.Size.X / 2, face))
local roomsPrompt = rd:FindFirstChild("RoomsPrompt")
assert(roomsPrompt and roomsPrompt:IsA("ProximityPrompt"), "RoomsDoor has no RoomsPrompt")
local rdFront = rd:FindFirstChild("Front")
assert(rdFront and rdFront:IsA("Attachment"), "RoomsDoor has no Front attachment")
local fp = rdFront.WorldPosition
assert(fp.X > face and fp.X < 12 and fp.Z > 0 and fp.Z < 10 and near(fp.Y, 0, 0.2), "RoomsDoor.Front at " .. str(fp) .. " is not on the corridor's floor (x 0..12, z 0..10)")
local nParts, lights, tagged = 0, 0, 0
for _, d in ipairs(rooms:GetDescendants()) do
  if d:IsA("BasePart") then
    nParts += 1
    assert(d.Anchored, "unanchored part under OK_Rooms: " .. d:GetFullName())
    if CS:HasTag(d, TAG) then tagged += 1 end
  end
  if d:IsA("Light") then lights += 1 end
  assert(not d:IsA("LuaSourceContainer"), "a script under OK_Rooms: " .. d:GetFullName())
end
assert(lights == 0, "OK_Rooms holds " .. lights .. " lights, want 0 (the hall and its doors add none)")
assert(tagged == 0, tagged .. " parts under OK_Rooms are tagged " .. TAG .. ": the building's prompts are untagged")
table.insert(out, string.format("building: hall at %s, %d doors (EnterPrompt off, Front, STUDIO plates), HallSpawn, HubDoor; RoomsDoor at (0.3, 4, 5); %d parts, 0 lights, none tagged",
  str(origin), slots, nParts))
task.wait()

-- (2) remotes and the room-play folders --------------------------------------------------------------------------------
local Remotes = RS.OK.Remotes
for name, class in pairs({ Room_Get = "RemoteFunction", Room_Edit = "RemoteFunction", Room = "RemoteEvent" }) do
  local r = Remotes:FindFirstChild(name)
  assert(r and r.ClassName == class, "Remotes." .. name .. " is " .. tostring(r and r.ClassName) .. ", want a " .. class)
end
local playing = RS.OK:FindFirstChild("RoomPlaying")
assert(playing, "ReplicatedStorage.OK.RoomPlaying missing")
assert(#playing:GetChildren() == slots, "RoomPlaying holds " .. #playing:GetChildren() .. " children, want " .. slots)
for k = 1, slots do
  local f = playing:FindFirstChild(string.format("Plot_%02d", k))
  assert(f and f:IsA("Folder"), string.format("RoomPlaying.Plot_%02d missing", k))
  assert(f:GetAttribute("Active") == false and f:GetAttribute("Tier") ~= nil and f:GetAttribute("Room") ~= nil,
    string.format("RoomPlaying.Plot_%02d lacks NowPlaying's Active (false), Tier or Room", k))
end
table.insert(out, "remotes Room_Get, Room_Edit, Room; RoomPlaying Plot_01.." .. string.format("%02d", slots))

-- (3) streaming --------------------------------------------------------------------------------------------------------
assert(workspace.StreamingEnabled == true, "streaming is off")
assert(workspace.StreamingMinRadius == 64, "StreamingMinRadius is " .. workspace.StreamingMinRadius .. ", want 64")
assert(workspace.StreamingTargetRadius == 1024, "StreamingTargetRadius is " .. workspace.StreamingTargetRadius .. ", want 1024")
assert(workspace.StreamOutBehavior == Enum.StreamOutBehavior.LowMemory, "StreamOutBehavior is " .. tostring(workspace.StreamOutBehavior) .. ", want LowMemory")
local persistent, others = {}, {}
for _, c in ipairs(workspace:GetChildren()) do
  if c:IsA("Model") then
    local isP = c.ModelStreamingMode == Enum.ModelStreamingMode.Persistent
    if PERSISTENT[c.Name] then
      assert(isP, c.Name .. " is " .. c.ModelStreamingMode.Name .. ", want Persistent (the hub's own build models)")
      persistent[c.Name] = true
    else
      assert(not isP, c.Name .. " is Persistent: only the hub's own build models are (preflight F10; another session's import keeps its mode)")
      table.insert(others, c.Name .. "=" .. c.ModelStreamingMode.Name)
    end
  end
end
for name in pairs(PERSISTENT) do assert(persistent[name], "Workspace." .. name .. " missing (it should be Persistent)") end
local tmpl = workspace:FindFirstChild(FIXTURE.Template)
if tmpl then
  assert(tmpl.ModelStreamingMode == Enum.ModelStreamingMode.Atomic, FIXTURE.Template .. " is " .. tmpl.ModelStreamingMode.Name .. ", want Atomic (the template stays as imported)")
end
table.sort(others)
table.insert(out, "streaming on (64, 1024, LowMemory); Persistent: OKStudio, OK_Gates, OK_Passage_Interscope, OK_Passage_StudioTwo, OK_Rooms; others: "
  .. (#others > 0 and table.concat(others, ", ") or "none"))

-- (4) the synced code and the building's words -------------------------------------------------------------------------
local Config = freshRequire(RS.OK.Config)
local live = Config.Rooms
assert(type(live) == "table", "the place's Config has no Rooms: sync OK/Config")
assert(RS.OK.Systems:FindFirstChild("Rooms"), "ReplicatedStorage.OK.Systems.Rooms missing: sync Systems/Rooms")
local svc = game:GetService("ServerScriptService").OK.Services:FindFirstChild("InteractionService")
local okSrc, src = pcall(function() return svc.Source end)
local adoptCheck = "skipped (InteractionService.Source unreadable here)"
if okSrc and type(src) == "string" then
  assert(src:find("function M.Adopt", 1, true), "InteractionService has no M.Adopt: sync Services/InteractionService")
  adoptCheck = "present"
end
local RoomBuild = freshRequire(RS.OK.Modules.RoomBuild)
local Copy = RoomBuild.Copy
assert(roomsPrompt.ActionText == Copy.BuildingAction and roomsPrompt.ObjectText == Copy.BuildingObject,
  "RoomsPrompt reads '" .. roomsPrompt.ActionText .. "' / '" .. roomsPrompt.ObjectText .. "', want copy 1.2 / 1.3")
assert(hubPrompt.ActionText == Copy.HubAction and hubPrompt.ObjectText == Copy.HubObject,
  "HubPrompt reads '" .. hubPrompt.ActionText .. "' / '" .. hubPrompt.ObjectText .. "', want copy 1.6 / 1.7")
local function signText(part)
  local g = part and part:FindFirstChildWhichIsA("SurfaceGui")
  local l = g and g:FindFirstChildWhichIsA("TextLabel")
  return l and l.Text
end
assert(signText(rooms:FindFirstChild("RoomsSign")) == Copy.BuildingSign, "RoomsSign reads '" .. tostring(signText(rooms:FindFirstChild("RoomsSign"))) .. "', want copy 1.1")
assert(signText(hall:FindFirstChild("LobbySign")) == Copy.LobbySign, "LobbySign reads '" .. tostring(signText(hall:FindFirstChild("LobbySign"))) .. "', want copy 1.4")
assert(signText(hall:FindFirstChild("HubSign")) == Copy.HubSign, "HubSign reads '" .. tostring(signText(hall:FindFirstChild("HubSign"))) .. "', want copy 1.5")
table.insert(out, "Systems/Rooms in the place; InteractionService.Adopt " .. adoptCheck .. "; the building's words are RoomBuild.Copy's")

-- (5) the stand-ins ----------------------------------------------------------------------------------------------------
local function inside(kc, x, z, pad)
  pad = pad or 0
  return math.abs(x) <= kc.size[1] / 2 - pad and math.abs(z) <= kc.size[2] / 2 - pad
end
local function inKeep(kc, x, z)
  for _, a in ipairs(kc.keep or {}) do
    if x >= a[1] and x <= a[3] and z >= a[2] and z <= a[4] then return true end
  end
  return false
end
for _, kind in ipairs({ "bedroom", "home", "real" }) do
  local kc = live.Kinds[kind]
  assert(kc, "Config.Rooms.Kinds has no " .. kind)
  local m = RoomBuild.StandIn(kind, kc)
  local ok, err = pcall(function()
    assert(m:IsA("Model"), kind .. ": StandIn returned a " .. m.ClassName)
    assert(m:GetAttribute("OK_Room") ~= nil and m:GetAttribute("StandIn") == true, kind .. ": OK_Room / StandIn not set")
    assert(m.ModelStreamingMode == Enum.ModelStreamingMode.Atomic, kind .. ": ModelStreamingMode is " .. m.ModelStreamingMode.Name .. ", want Atomic")
    local piv = m:GetPivot()
    assert(piv.Position.Magnitude < 1e-3 and piv.LookVector:Dot(Vector3.new(0, 0, -1)) > 0.999, kind .. ": pivot " .. str(piv.Position) .. ", want the origin facing -Z")
    local fl = m:FindFirstChild("Floor")
    assert(fl and near(fl.Position.Y + fl.Size.Y / 2, 0), kind .. ": the floor's top is not at y 0")
    local doors, stations, lightsN, meshes = {}, {}, 0, 0
    for _, d in ipairs(m:GetDescendants()) do
      if d:IsA("BasePart") and d:GetAttribute("RoomDoor") == true then table.insert(doors, d) end
      if d:IsA("BasePart") and CS:HasTag(d, TAG) and d:GetAttribute("Kind") == "Station" then table.insert(stations, d) end
      if d:IsA("Light") then lightsN += 1 end
      if d:IsA("MeshPart") then meshes += 1 end
    end
    assert(#doors == 1, kind .. ": " .. #doors .. " RoomDoor parts, want 1")
    local exit = doors[1]:FindFirstChild("ExitPrompt")
    assert(exit and exit:IsA("ProximityPrompt") and exit.Enabled == false, kind .. ": the door's ExitPrompt is missing or on (a plot's copy turns it on)")
    assert(doors[1].Position.Z > kc.size[2] / 2 - 0.5, kind .. ": the door is at z " .. doors[1].Position.Z .. ", want the south wall (z " .. kc.size[2] / 2 .. ")")
    assert(#stations == 1, kind .. ": " .. #stations .. " Stations, want 1")
    local st = stations[1]
    assert((st:GetAttribute("StationName") or "") ~= "" and st:FindFirstChildWhichIsA("ProximityPrompt"), kind .. ": the Station lacks a StationName or a prompt")
    local seat = m:FindFirstChild("Seat_Chair", true)
    assert(seat and seat:IsA("Seat"), kind .. ": no Seat_Chair")
    local sp = m:FindFirstChild("Spawn", true)
    assert(sp and sp:IsA("BasePart"), kind .. ": no Spawn part")
    local s = sp.Position
    assert(inside(kc, s.X, s.Z, 1), kind .. ": the Spawn at " .. str(s) .. " is not inside the room")
    assert(inKeep(kc, s.X, s.Z), kind .. ": the Spawn at " .. str(s) .. " is in none of the kind's keep areas (an item could stand on it)")
    local ahead = s + sp.CFrame.LookVector * 3
    assert(inside(kc, ahead.X, ahead.Z, 0.5), kind .. ": the Spawn faces out of the room")
    for _, name in ipairs(RoomBuild.ContractAnchors(kc)) do
      local a = m:FindFirstChild(name, true)
      assert(a and a:IsA("Attachment"), kind .. ": no " .. name .. " Attachment")
      local want = RoomBuild.AnchorCFrame(kc.anchors[name])
      assert((a.WorldPosition - want.Position).Magnitude < 1e-3, kind .. ": " .. name .. " is at " .. str(a.WorldPosition) .. ", want " .. str(want.Position))
    end
    assert(lightsN <= 1, kind .. ": " .. lightsN .. " lights, want at most 1")
    assert(meshes <= 56, kind .. ": " .. meshes .. " MeshParts, over 56")
    table.insert(out, string.format("stand-in %s: contract items, %d anchors, %d light, Spawn %s in a keep area", kind, #RoomBuild.ContractAnchors(kc), lightsN, str(s)))
  end)
  m:Destroy()
  if not ok then error(err, 0) end
end

-- (6) Anchors ----------------------------------------------------------------------------------------------------------
local bed = live.Kinds.bedroom
local names = {}
for name in pairs(bed.anchors) do table.insert(names, name) end
table.sort(names)
local m1 = Instance.new("Model")
local m2 = Instance.new("Model")
local ok6, err6 = pcall(function()
  m1.WorldPivot = CFrame.new()
  local holder = Instance.new("Part"); holder.Name = "Sockets"; holder.Anchored = true; holder.CFrame = CFrame.new(); holder.Parent = m1
  local keepCF = CFrame.new(1, 2, 3)
  local e = Instance.new("Attachment"); e.Name = "Entrance"; e.Parent = holder; e.WorldCFrame = keepCF
  local p2 = Instance.new("Attachment"); p2.Name = "Plaque_2"; p2.Parent = holder
  local added = RoomBuild.Anchors(m1, bed)
  local want = {}
  for _, n in ipairs(names) do if n ~= "Entrance" and n ~= "Plaque_2" then table.insert(want, n) end end
  assert(table.concat(added, ",") == table.concat(want, ","), "Anchors added " .. table.concat(added, ",") .. ", want " .. table.concat(want, ","))
  assert((e.WorldPosition - keepCF.Position).Magnitude < 1e-4, "Anchors moved the Entrance it already had")
  local n = 0
  for _, d in ipairs(m1:GetDescendants()) do if d:IsA("Attachment") then n += 1 end end
  assert(n == #names, "the model holds " .. n .. " attachments after Anchors, want " .. #names)
  for _, name in ipairs(want) do
    local a = holder:FindFirstChild(name)
    assert(a and (a.WorldPosition - RoomBuild.AnchorCFrame(bed.anchors[name]).Position).Magnitude < 1e-3, name .. " is not where Config.Rooms puts it")
  end
  local added2 = RoomBuild.Anchors(m2, bed)
  assert(#added2 == #names, "a bare Model got " .. #added2 .. " anchors, want " .. #names)
  local sockets = m2:FindFirstChild("Sockets")
  assert(sockets and sockets:IsA("BasePart"), "Anchors made no Sockets part on a bare Model")
  assert(#RoomBuild.Anchors(m2, bed) == 0, "a second Anchors run added more")
end)
m1:Destroy(); m2:Destroy()
if not ok6 then error(err6, 0) end
table.insert(out, "Anchors: adds exactly the " .. (#names - 2) .. " missing of " .. #names .. ", keeps what is there; a bare Model gets all " .. #names .. "; a rerun adds none")

-- (7) the hub's counts ---------------------------------------------------------------------------------------------------
local RoomScope = freshRequire(RS.OK.Modules.RoomScope)
task.wait()
local hubLights, _, over = RoomScope.Lights(workspace) -- one walk, as t03 / 09_qa take it
task.wait()
local inWs = {}
for _, t in ipairs(CS:GetTagged(TAG)) do if t:IsDescendantOf(workspace) then table.insert(inWs, t) end end
local hubTagged = RoomScope.Split(inWs)
local stationsAll = {}
for _, t in ipairs(inWs) do if t:GetAttribute("Kind") == "Station" then table.insert(stationsAll, t) end end
local hubStations = RoomScope.Split(stationsAll)
assert(hubLights <= CAP, "the hub holds " .. hubLights .. " lights, over its " .. CAP)
assert(over == nil, over)
assert(#hubTagged == 12, "the hub holds " .. #hubTagged .. " tagged interactables, want 12")
assert(#hubStations == 2, "the hub holds " .. #hubStations .. " Stations, want 2")
table.insert(out, string.format("hub: %d lights (cap %d), %d interactables, %d stations", hubLights, CAP, #hubTagged, #hubStations))

-- (8) the literal copy equals live Config.Rooms ------------------------------------------------------------------------
local function same(a, b, path)
  if type(a) ~= type(b) then return path .. ": the copy has a " .. type(a) .. ", live Config a " .. type(b) end
  if type(a) ~= "table" then
    if a ~= b then return path .. ": the copy has " .. tostring(a) .. ", live Config " .. tostring(b) end
    return nil
  end
  for k, v in pairs(a) do
    local d = same(v, b[k], path .. "." .. tostring(k))
    if d then return d end
  end
  for k in pairs(b) do
    if a[k] == nil then return path .. "." .. tostring(k) .. ": in live Config, missing from the copy" end
  end
  return nil
end
local diff = same(FIXTURE, live, "Config.Rooms")
assert(diff == nil, "the literal Config.Rooms (t100 and spec/room_rules_spec.lua) differs from live Config: " .. tostring(diff))
table.insert(out, "the literal Config.Rooms equals live Config")

return "T100 OK\n" .. table.concat(out, "\n")
