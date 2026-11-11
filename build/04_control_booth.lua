local L = require(game:GetService("ReplicatedStorage").OK.BuildLib)
local B = "04_control_booth"
L.clear(B)
local C = L.C
local CR = L.model(workspace.OKStudio, "ControlRoom")
local VB = L.model(workspace.OKStudio, "VocalBooth")
local BLACK = {Material = Enum.Material.SmoothPlastic, Color = C.black}
local METAL = {Material = Enum.Material.Metal, Color = C.steel}
local WOOD = {Material = Enum.Material.Wood, Color = C.walnut}
-- ===== CONTROL ROOM =====
-- desk: top at y=3, x 73..76, z -9..5
L.boxMM(CR, "Desk_Top", 72.6, 2.75, -9.2, 76.4, 3.0, 5.2, WOOD)
L.boxMM(CR, "Desk_CabL", 73, 0, -9.2, 76.4, 2.75, -7.6, BLACK)
L.boxMM(CR, "Desk_CabR", 73, 0, 3.6, 76.4, 2.75, 5.2, BLACK)
L.boxMM(CR, "Desk_Back", 76.0, 0, -7.6, 76.4, 2.75, 3.6, BLACK)
local strip = L.neon(CR, "Desk_LED", Vector3.new(72.65, 2.6, -2), Vector3.new(0.08, 0.08, 14.2), C.blue)
L.light(strip, "PointLight", C.blue, 0.7, 10)
-- console slab, tilted toward the producer (who faces +X)
local console = L.boxR(CR, "Console", Vector3.new(74.5, 3.35, -2), Vector3.new(2.6, 0.5, 10.4), 0, {Material = Enum.Material.Metal, Color = Color3.fromRGB(34, 34, 38)})
console.CFrame = CFrame.new(74.5, 3.35, -2) * CFrame.Angles(0, 0, math.rad(-9))
local cf = console.CFrame
-- 8 channel strips along z: knobs (3 rows), fader, meter column (6 segments)
for ch = 1, 8 do
  local z = -6.4 + (ch - 1) * 1.26
  for row = 1, 3 do
    local k = L.part("Knob", Vector3.new(0.28, 0.22, 0.28), cf * CFrame.new(-0.95 + (row - 1) * 0.45, 0.32, z), {Material = Enum.Material.SmoothPlastic, Color = (row == 2) and C.white or Color3.fromRGB(90, 90, 96)})
    k.Parent = CR
  end
  L.part("FaderSlot", Vector3.new(0.9, 0.02, 0.08), cf * CFrame.new(0.55, 0.26, z), BLACK).Parent = CR
  L.part("Fader", Vector3.new(0.24, 0.18, 0.34), cf * CFrame.new(0.55 - 0.4 + (ch % 5) * 0.16, 0.33, z), {Material = Enum.Material.SmoothPlastic, Color = C.white}).Parent = CR
  for seg = 1, 6 do
    local col = (seg <= 3) and C.led or (seg <= 5 and Color3.fromRGB(255, 200, 0) or C.red)
    local m = L.part("Meter_" .. ch .. "_" .. seg, Vector3.new(0.12, 0.06, 0.4), cf * CFrame.new(1.05 - (seg - 1) * 0.0, 0.28 + (seg - 1) * 0.0, z) * CFrame.new(-(seg - 1) * 0.0, 0, 0), {Material = Enum.Material.Neon, Color = col})
    -- stack the segments along the slab's local x toward the back
    m.CFrame = cf * CFrame.new(0.95 + (seg - 1) * 0.0 + 0.0, 0.28, z) * CFrame.new(0, 0, 0)
    m.CFrame = cf * CFrame.new(0.78 + (seg - 1) * 0.09, 0.28, z)
    m:SetAttribute("Seg", seg); m:SetAttribute("Channel", ch); m.Transparency = 0.7
    m.Parent = CR
  end
end
-- two screens on stands, big faces along X; the producer looks from -X so text goes on the Left face
local function screen(name, z, yaw, text)
  local stand = L.boxMM(CR, name .. "_Stand", 75.5, 3.0, z - 0.2, 75.9, 4.2, z + 0.2, BLACK)
  local base = L.boxMM(CR, name .. "_Base", 75.0, 3.0, z - 1.0, 76.3, 3.1, z + 1.0, BLACK)
  local s = L.boxR(CR, name, Vector3.new(75.7, 5.9, z), Vector3.new(0.18, 3.4, 5.6), yaw, {Material = Enum.Material.Glass, Color = Color3.fromRGB(8, 10, 14)})
  local bez = L.boxR(CR, name .. "_Bezel", Vector3.new(75.85, 5.9, z), Vector3.new(0.12, 3.7, 5.9), yaw, BLACK)
  L.textFace(s, Enum.NormalId.Left, text, {TextColor3 = C.blue, PixelsPerStud = 36, BackgroundTransparency = 0.1, BackgroundColor3 = Color3.fromRGB(6, 8, 12), Font = Enum.Font.Code, Padding = 14, Brightness = 2})
  return s
end
local screenMain = screen("Screen_Main", -4.6, 10, "PROD LIFE III\n\nBEAT MAKER\nDRUMS · 808 · KEYS\n\nSTUDIO PC · MAKE A BEAT")
screen("Screen_Side", 0.9, -10, "MONITORS\n\nIDLE\n\nPLAY A BEAT\nON THE MONITORS")
screenMain:SetAttribute("InteractKind", "Computer")
-- MIDI keyboard on the desk's left end (z -9..-7.6 region is cabinet top; keyboard sits z -7.2..-2.4 near front edge? keep it at the right of the console)
local kbBody = L.boxMM(CR, "Midi_Body", 72.9, 3.0, 3.0, 74.6, 3.3, 5.0, BLACK)
for i = 0, 13 do
  L.boxMM(CR, "Midi_WhiteKey", 72.95 + i * 0.118, 3.3, 3.1, 72.95 + i * 0.118 + 0.1, 3.38, 4.9, {Material = Enum.Material.SmoothPlastic, Color = C.white})
end
for i = 0, 13 do
  if i % 7 ~= 2 and i % 7 ~= 6 then L.boxMM(CR, "Midi_BlackKey", 73.04 + i * 0.118, 3.38, 3.1, 73.04 + i * 0.118 + 0.05, 3.44, 4.2, BLACK) end
end
-- studio monitors on stands behind the desk corners, cones face -X
local function speaker(name, z)
  L.boxMM(CR, name .. "_Stand", 77.4, 0, z - 0.2, 77.8, 4.2, z + 0.2, METAL)
  L.boxMM(CR, name .. "_Foot", 77.0, 0, z - 0.8, 78.2, 0.2, z + 0.8, METAL)
  local box = L.boxMM(CR, name, 77.0, 4.2, z - 0.8, 78.6, 6.8, z + 0.8, {Material = Enum.Material.Wood, Color = Color3.fromRGB(26, 24, 24)})
  local woofer = L.part(name .. "_Cone", Vector3.new(0.15, 1.1, 1.1), CFrame.new(76.95, 5.0, z), {Shape = Enum.PartType.Cylinder, Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(48, 48, 52)})
  woofer.Parent = CR
  local tweeter = L.part(name .. "_Tweeter", Vector3.new(0.12, 0.4, 0.4), CFrame.new(76.95, 6.2, z), {Shape = Enum.PartType.Cylinder, Material = Enum.Material.Metal, Color = C.steel})
  tweeter.Parent = CR
  local led = L.neon(CR, name .. "_LED", Vector3.new(76.93, 4.5, z + 0.5), Vector3.new(0.06, 0.12, 0.12), C.blue); led:SetAttribute("SpeakerLED", true)
  return box
end
speaker("Speaker_L", -9.0); speaker("Speaker_R", 3.4)
-- racks on the south wall
local function rack(name, x)
  L.boxMM(CR, name .. "_Frame", x - 1.1, 0, -11.4, x + 1.1, 8.2, -9.2, {Material = Enum.Material.Metal, Color = Color3.fromRGB(20, 20, 22)})
  for u = 1, 8 do
    local y0 = 0.4 + (u - 1) * 0.95
    L.boxMM(CR, name .. "_Unit", x - 1.0, y0, -9.25, x + 1.0, y0 + 0.8, -9.1, {Material = Enum.Material.Metal, Color = (u % 3 == 0) and Color3.fromRGB(60, 60, 66) or Color3.fromRGB(38, 38, 42)})
    L.neon(CR, name .. "_LED", Vector3.new(x - 0.7, y0 + 0.4, -9.08), Vector3.new(0.1, 0.1, 0.04), (u % 2 == 0) and C.led or C.blue)
    L.neon(CR, name .. "_LED2", Vector3.new(x + 0.7, y0 + 0.4, -9.08), Vector3.new(0.1, 0.1, 0.04), (u % 4 == 0) and C.red or C.led)
  end
end
rack("Rack_A", 60); rack("Rack_B", 63)
-- producer chair (faces +X)
L.boxMM(CR, "Chair_Base", 70.8, 0, -3.0, 72.8, 0.2, -1.0, METAL)
L.boxMM(CR, "Chair_Post", 71.7, 0.2, -2.1, 71.9, 1.4, -1.9, METAL)
L.seat(CR, "Chair_Seat", Vector3.new(71.8, 1.6, -2), Vector3.new(2.2, 0.4, 2.2), -90, {Material = Enum.Material.Fabric, Color = C.leather})
L.boxMM(CR, "Chair_Back", 70.7, 1.8, -3.1, 71.0, 4.4, -0.9, {Material = Enum.Material.Fabric, Color = C.leather})
-- couch at the back (x 47..49.6), faces +X; three seats
L.boxMM(CR, "Couch_Base", 47.0, 0, 3.6, 49.8, 1.2, 11.4, {Material = Enum.Material.Fabric, Color = C.leather})
for i, z in ipairs({5.3, 7.5, 9.7}) do L.seat(CR, "Couch_Seat_" .. i, Vector3.new(48.5, 1.5, z), Vector3.new(2.4, 0.5, 2.7), -90) end
L.boxMM(CR, "Couch_Back", 46.6, 1.2, 3.6, 47.2, 3.6, 11.4, {Material = Enum.Material.Fabric, Color = C.leather})
L.boxMM(CR, "Couch_ArmL", 46.6, 1.2, 3.0, 49.8, 2.4, 3.6, {Material = Enum.Material.Fabric, Color = C.leather})
L.boxMM(CR, "Couch_ArmR", 46.6, 1.2, 11.4, 49.8, 2.4, 11.9, {Material = Enum.Material.Fabric, Color = C.leather})
L.boxMM(CR, "Rug", 46.0, 0, 2.2, 56, 0.06, 11.9, {Material = Enum.Material.Fabric, Color = Color3.fromRGB(70, 28, 34)})
-- side table + lamp
L.boxMM(CR, "Side_Table", 47.2, 0, -6.9, 49.6, 1.8, -4.5, WOOD)
L.boxMM(CR, "Lamp_Base", 48.1, 1.8, -6.0, 48.7, 2.2, -5.4, METAL)
L.boxMM(CR, "Lamp_Post", 48.3, 2.2, -5.8, 48.5, 3.4, -5.6, METAL)
local shade = L.box(CR, "Lamp_Shade", Vector3.new(48.4, 3.8, -5.7), Vector3.new(1.4, 1.0, 1.4), {Material = Enum.Material.Fabric, Color = Color3.fromRGB(120, 90, 60)})
local bulb = L.neon(CR, "Lamp_Bulb", Vector3.new(48.4, 3.5, -5.7), Vector3.new(0.5, 0.4, 0.5), C.warm)
L.light(bulb, "PointLight", C.warm, 1.0, 12)
-- acoustic panels on north and south walls, y 3..8
for i = 0, 5 do
  local x = 47 + i * 5.4
  L.boxMM(CR, "Panel_N", x, 3, 11.3, x + 3.2, 8, 11.6, {Material = Enum.Material.Fabric, Color = C.maroon})
  if x < 57 or x > 66 then L.boxMM(CR, "Panel_S", x, 3, -11.6, x + 3.2, 8, -11.3, {Material = Enum.Material.Fabric, Color = C.maroon}) end
end
-- neon sign over the booth window (control room side); the part keeps its old name, OK_Sign, for the checks
local sign = L.boxMM(CR, "OK_Sign", 79.3, 8.6, -5.2, 79.6, 11.2, 1.2, BLACK)
L.textFace(sign, Enum.NormalId.Left, "PROD LIFE III", {TextColor3 = C.pink, PixelsPerStud = 60, Brightness = 3})
local signGlow = L.neon(CR, "OK_Sign_Glow", Vector3.new(79.25, 8.55, -2), Vector3.new(0.1, 0.1, 6.4), C.pink)
L.light(signGlow, "PointLight", C.pink, 0.9, 7)
-- plaques on the mid wall (control room side faces +X, so text on Right face)
local function plaque(name, z, text)
  local p = L.boxMM(CR, name, 44.6, 4.5, z - 1.4, 44.8, 7.0, z + 1.4, {Material = Enum.Material.Wood, Color = Color3.fromRGB(20, 16, 14)})
  L.textFace(p, Enum.NormalId.Right, text, {TextColor3 = Color3.fromRGB(220, 190, 120), PixelsPerStud = 40, Padding = 6, Brightness = 1.2})
end
plaque("Plaque_A", -9.5, "HOUSE STUDIO\nCONTROL ROOM A")
plaque("Plaque_B", -6.0, "PROD LIFE III\nHOUSE STUDIO")
-- light switch by the door (mid wall, control-room side)
local sw = L.boxMM(CR, "LightSwitch", 44.6, 4.2, -4.4, 44.8, 5.0, -3.8, {Material = Enum.Material.SmoothPlastic, Color = C.white})
sw:SetAttribute("InteractKind", "LightSwitch")
-- ===== VOCAL BOOTH (x 80..94, z -8..8) =====
-- foam grid on N, S and E walls (2x2 tiles, alternating)
for i = 0, 6 do for r = 0, 3 do
  local x0 = 80.5 + i * 2; local y0 = 1 + r * 2
  local col = ((i + r) % 2 == 0) and Color3.fromRGB(26, 26, 30) or C.maroon
  L.boxMM(VB, "Foam_N", x0, y0, 7.4, x0 + 1.9, y0 + 1.9, 7.6, {Material = Enum.Material.Fabric, Color = col})
  L.boxMM(VB, "Foam_S", x0, y0, -7.6, x0 + 1.9, y0 + 1.9, -7.4, {Material = Enum.Material.Fabric, Color = col})
end end
for j = 0, 7 do for r = 0, 3 do
  local z0 = -7.9 + j * 2; local y0 = 1 + r * 2
  local col = ((j + r) % 2 == 0) and C.maroon or Color3.fromRGB(26, 26, 30)
  L.boxMM(VB, "Foam_E", 93.4, y0, z0, 93.6, y0 + 1.9, z0 + 1.9, {Material = Enum.Material.Fabric, Color = col})
end end
-- mic stand facing the window (singer stands at x~88 looking -X)
L.boxMM(VB, "Mic_Base", 86.2, 0, -2.8, 87.8, 0.15, -1.2, METAL)
L.boxMM(VB, "Mic_Pole", 86.92, 0.15, -2.08, 87.08, 4.6, -1.92, METAL)
L.boxMM(VB, "Mic_Boom", 85.4, 4.55, -2.06, 87.1, 4.67, -1.94, METAL)
local mic = L.part("Mic", Vector3.new(1.3, 0.55, 0.55), CFrame.new(85.9, 4.2, -2) * CFrame.Angles(0, 0, math.rad(70)), {Shape = Enum.PartType.Cylinder, Material = Enum.Material.Metal, Color = Color3.fromRGB(200, 200, 205)})
mic.Parent = VB; mic:SetAttribute("InteractKind", "Mic")
L.part("Mic_Grille", Vector3.new(0.6, 0.5, 0.5), CFrame.new(85.7, 4.75, -2) * CFrame.Angles(0, 0, math.rad(70)), {Shape = Enum.PartType.Cylinder, Material = Enum.Material.DiamondPlate, Color = Color3.fromRGB(60, 60, 64)}).Parent = VB
L.part("Pop_Filter", Vector3.new(0.08, 1.5, 1.5), CFrame.new(85.0, 4.6, -2), {Shape = Enum.PartType.Cylinder, Material = Enum.Material.Fabric, Color = C.black, Transparency = 0.25}).Parent = VB
L.boxMM(VB, "Pop_Arm", 85.0, 3.8, -2.06, 86.95, 3.92, -1.94, METAL)
-- music stand and headphones hook
L.boxMM(VB, "MusicStand_Pole", 88.9, 0, -5.1, 89.1, 3.6, -4.9, METAL)
L.boxR(VB, "MusicStand_Plate", Vector3.new(89.0, 4.0, -5.0), Vector3.new(0.1, 1.6, 2.0), 0, BLACK).CFrame = CFrame.new(89.0, 4.0, -5.0) * CFrame.Angles(0, 0, math.rad(-20))
L.boxMM(VB, "Hook", 93.1, 5.5, 4.0, 93.4, 5.7, 4.3, METAL)
L.part("Headphones", Vector3.new(0.3, 1.4, 1.4), CFrame.new(93.05, 4.9, 4.15), {Shape = Enum.PartType.Cylinder, Material = Enum.Material.SmoothPlastic, Color = C.black}).Parent = VB
-- booth lamp (warm, turns red during a take) and REC sign over the window, booth side
local lampBase = L.boxMM(VB, "BoothLamp_Base", 92.3, 0, -6.6, 93.1, 0.3, -5.8, METAL)
L.boxMM(VB, "BoothLamp_Post", 92.6, 0.3, -6.3, 92.8, 5.6, -6.1, METAL)
local blamp = L.neon(VB, "BoothLamp", Vector3.new(92.7, 5.9, -6.2), Vector3.new(0.7, 0.7, 0.7), C.warm)
L.light(blamp, "PointLight", C.warm, 1.0, 14)
local rec = L.boxMM(VB, "REC_Backing", 80.5, 8.6, -3.6, 80.8, 9.8, -0.4, BLACK)
L.textFace(rec, Enum.NormalId.Right, "● REC", {TextColor3 = Color3.fromRGB(120, 20, 20), PixelsPerStud = 50, Brightness = 2, Name = "RecText"})
local recNeon = L.neon(VB, "REC_Sign", Vector3.new(80.85, 8.55, -2), Vector3.new(0.1, 0.1, 3.2), Color3.fromRGB(80, 10, 10))
local recLight = L.light(recNeon, "PointLight", C.red, 1.2, 10); recLight.Enabled = false
recNeon:SetAttribute("On", false)
-- floor rug in booth
L.boxMM(VB, "Booth_Rug", 83, 0, -5, 92, 0.06, 3, {Material = Enum.Material.Fabric, Color = Color3.fromRGB(44, 24, 30)})
L.markAll(CR, B); L.markAll(VB, B)
local lights = 0; for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("Light") then lights += 1 end end
return string.format("control parts=%d booth parts=%d total=%d lights=%d", L.count(CR), L.count(VB), L.count(workspace.OKStudio), lights)
