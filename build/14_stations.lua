-- 14: studio laptops ("Room for three"): one on the lounge bar, one on a new side desk in the control room.
-- Each laptop screen is an OK_Interactable with Kind = "Station" (Systems/Stations opens the beat maker from it).
-- Built from parts with a SurfaceGui screen: no images, no lights. Run after 02-07 and 13; idempotent (OK_Build).
local function freshRequire(mod)
  local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name
  local ok, res = pcall(require, c); c:Destroy(); if not ok then error(res) end; return res
end
local RS = game:GetService("ReplicatedStorage")
local L = require(RS.OK.BuildLib)
local Config = freshRequire(RS.OK.Config); local Defs = freshRequire(RS.OK.Modules.Interactions)
local RoomScope = freshRequire(RS.OK.Modules.RoomScope) -- required first, so a missing module stops the script before it rebuilds anything
local B = "14_stations"
L.clear(B)
local S = workspace.OKStudio
local C = L.C
local dark = Color3.fromRGB(22, 22, 26)

-- a laptop whose base sits on a surface at height y, centred at (x, z), screen facing +Z (towards the player)
local function laptop(parent, name, x, y, z, stationName)
  local m = Instance.new("Model"); m.Name = name; m.Parent = parent; L.mark(m, B)
  L.box(m, "Base", Vector3.new(x, y + 0.05, z), Vector3.new(2.0, 0.1, 1.3), { Color = dark, Material = Enum.Material.Metal })
  L.box(m, "Keys", Vector3.new(x, y + 0.105, z + 0.1), Vector3.new(1.7, 0.01, 0.7), { Color = Color3.fromRGB(40, 40, 46), Material = Enum.Material.SmoothPlastic })
  local hinge = CFrame.new(x, y + 0.1, z - 0.62) * CFrame.Angles(math.rad(-15), 0, 0)
  local screen = L.part("Screen", Vector3.new(2.0, 1.3, 0.08), hinge * CFrame.new(0, 0.65, 0), { Color = Color3.fromRGB(10, 12, 20), Material = Enum.Material.SmoothPlastic })
  screen.Parent = m
  L.textFace(screen, Enum.NormalId.Back, "BEAT MAKER · " .. stationName .. "\n<font size=\"14\">MAKE BEATS</font>",
    { RichText = true, TextColor3 = C.blue, BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(8, 10, 22), Padding = 6, PixelsPerStud = 60 })
  local p = Instance.new("ProximityPrompt")
  p.ActionText = Defs.Station.Action; p.ObjectText = Defs.Station.Object
  p.MaxActivationDistance = Config.Interaction.MaxDistance; p.HoldDuration = Config.Interaction.HoldSeconds
  p.RequiresLineOfSight = false; p.KeyboardKeyCode = Enum.KeyCode.E; p.GamepadKeyCode = Enum.KeyCode.ButtonX
  p.Parent = screen
  L.tag(screen, "Station", Defs.Station.Object, { StationName = stationName })
  L.markAll(m, B)
  return m, screen
end

-- 1) lounge bar: the bar top is at y 3.4, front edge z -7.6; the laptop sits near the front, facing the room
laptop(S.Lounge, "Station_Bar", 18.0, 3.4, -8.4, "LOUNGE BAR")

-- 2) control room side desk on the north wall, between the couch and the racks
local desk = Instance.new("Model"); desk.Name = "SideDesk"; desk.Parent = S.ControlRoom; L.mark(desk, B)
L.boxMM(desk, "Top", 50.5, 2.8, -11.4, 55.5, 3.0, -9.0, { Color = C.walnut, Material = Enum.Material.Wood })
L.boxMM(desk, "LegL", 50.6, 0.0, -11.3, 50.9, 2.8, -9.2, { Color = dark, Material = Enum.Material.Metal })
L.boxMM(desk, "LegR", 55.1, 0.0, -11.3, 55.4, 2.8, -9.2, { Color = dark, Material = Enum.Material.Metal })
L.markAll(desk, B)
laptop(S.ControlRoom, "Station_Side", 53.0, 3.0, -9.8, "SIDE DESK")

local stations = {}
for _, t in ipairs(game:GetService("CollectionService"):GetTagged("OK_Interactable")) do if t:GetAttribute("Kind") == "Station" and t:IsDescendantOf(workspace) then table.insert(stations, t) end end
local n = #RoomScope.Split(stations) -- the hub's own laptops: a room's laptop is not counted
assert(n == 2, "expected 2 studio laptops, found " .. n)
return "14 stations ok: 2 laptops (lounge bar, control-room side desk), parts=" .. L.count(S)
