local L = require(game:GetService("ReplicatedStorage").OK.BuildLib)
local B = "02_shell"
L.clear(B)
local studio = workspace.OKStudio
local S = L.model(studio, "Shell")
local C = L.C
local T = 1 -- wall thickness
-- floors (top at y=0)
L.boxMM(S, "Floor_Corridor", 0, -1, 0, 12, 0, 10, {Material = Enum.Material.Concrete, Color = C.concreteLight})
L.boxMM(S, "Floor_Lounge", 12, -1, -12, 44, 0, 12, {Material = Enum.Material.WoodPlanks, Color = C.walnut})
L.boxMM(S, "Floor_Control", 44, -1, -12, 80, 0, 12, {Material = Enum.Material.Fabric, Color = Color3.fromRGB(40, 40, 44)})
L.boxMM(S, "Floor_Booth", 80, -1, -8, 94, 0, 8, {Material = Enum.Material.Fabric, Color = C.charcoal})
-- ceilings
L.boxMM(S, "Ceiling_Corridor", 0, 10, 0, 12, 11, 10, {Color = C.black, Material = Enum.Material.Concrete})
L.boxMM(S, "Ceiling_Lounge", 12, 12, -12, 44, 13, 12, {Color = C.black, Material = Enum.Material.Concrete})
L.boxMM(S, "Ceiling_Control", 44, 12, -12, 80, 13, 12, {Color = C.black, Material = Enum.Material.Concrete})
L.boxMM(S, "Ceiling_Booth", 80, 10, -8, 94, 11, 8, {Color = C.black, Material = Enum.Material.Concrete})
local W = {Material = Enum.Material.Concrete, Color = C.concrete}
-- corridor walls
L.wall(S, "Wall_Corr_W", 0, 0, 0, 10, 0, 10, T, W)
L.wall(S, "Wall_Corr_N", 0, 10, 12, 10, 0, 10, T, W)
L.wall(S, "Wall_Corr_S", 0, 0, 12, 0, 0, 10, T, W)
-- lounge west wall x=12 with door z 3..7 (h 8)
L.wall(S, "Wall_Lounge_W1", 12, -12, 12, 3, 0, 12, T, W)
L.wall(S, "Wall_Lounge_W2", 12, 7, 12, 12, 0, 12, T, W)
L.wall(S, "Wall_Lounge_W_Header", 12, 3, 12, 7, 8, 4, T, W)
L.wall(S, "Wall_Lounge_N", 12, 12, 44, 12, 0, 12, T, {Material = Enum.Material.Brick, Color = C.brick})
L.wall(S, "Wall_Lounge_S", 12, -12, 44, -12, 0, 12, T, W)
-- lounge/control shared wall x=44 with door z -3..3 (h 8)
L.wall(S, "Wall_Mid_1", 44, -12, 44, -3, 0, 12, T, W)
L.wall(S, "Wall_Mid_2", 44, 3, 44, 12, 0, 12, T, W)
L.wall(S, "Wall_Mid_Header", 44, -3, 44, 3, 8, 4, T, W)
-- control room walls
L.wall(S, "Wall_Ctrl_N", 44, 12, 80, 12, 0, 12, T, W)
L.wall(S, "Wall_Ctrl_S", 44, -12, 80, -12, 0, 12, T, W)
-- control/booth wall x=80: window z -7..3 y 3..8, door z 4..8 (h 8)
L.wall(S, "Wall_Booth_W1", 80, -12, 80, -7, 0, 12, T, W)
L.wall(S, "Wall_Booth_Sill", 80, -7, 80, 3, 0, 3, T, W)
L.wall(S, "Wall_Booth_WinHeader", 80, -7, 80, 3, 8, 4, T, W)
L.wall(S, "Wall_Booth_Post", 80, 3, 80, 4, 0, 12, T, W)
L.wall(S, "Wall_Booth_DoorHeader", 80, 4, 80, 8, 8, 4, T, W)
L.wall(S, "Wall_Booth_W2", 80, 8, 80, 12, 0, 12, T, W)
local g = L.boxMM(S, "BoothGlass", 80 - 0.2, 3, -7, 80 + 0.2, 8, 3, {Material = Enum.Material.Glass, Color = C.glass, Transparency = 0.35, Reflectance = 0.1})
-- booth walls
L.wall(S, "Wall_Booth_N", 80, 8, 94, 8, 0, 10, T, W)
L.wall(S, "Wall_Booth_S", 80, -8, 94, -8, 0, 10, T, W)
L.wall(S, "Wall_Booth_E", 94, -8, 94, 8, 0, 10, T, W)
-- door frames (dark steel) around the three openings
local F = {Material = Enum.Material.Metal, Color = C.steel}
local function frame(name, x, z0, z1, h)
  L.boxMM(S, name .. "_L", x - 0.6, 0, z0 - 0.3, x + 0.6, h + 0.3, z0, F)
  L.boxMM(S, name .. "_R", x - 0.6, 0, z1, x + 0.6, h + 0.3, z1 + 0.3, F)
  L.boxMM(S, name .. "_T", x - 0.6, h, z0 - 0.3, x + 0.6, h + 0.3, z1 + 0.3, F)
end
frame("Frame_Entry", 12, 3, 7, 8)
frame("Frame_Mid", 44, -3, 3, 8)
frame("Frame_Booth", 80, 4, 8, 8)
-- sliding door panel (interactable in Task 7), flush on the lounge side of the mid wall
local door = L.boxMM(S, "SlidingDoor", 43.0, 0.05, -3, 43.5, 8, 3, {Material = Enum.Material.Metal, Color = Color3.fromRGB(22, 22, 26)})
door:SetAttribute("Open", false); door:SetAttribute("ClosedZ", 0); door:SetAttribute("OpenZ", 6.3)
L.textFace(door, Enum.NormalId.Left, "CONTROL ROOM", {TextColor3 = C.blue, PixelsPerStud = 40})
L.textFace(door, Enum.NormalId.Right, "LOUNGE", {TextColor3 = C.pink, PixelsPerStud = 40})
-- booth window frame
L.boxMM(S, "WinFrame_T", 79.5, 8, -7.3, 80.5, 8.3, 3.3, F); L.boxMM(S, "WinFrame_B", 79.5, 2.7, -7.3, 80.5, 3, 3.3, F)
-- spawn pad inside the corridor, facing +X
local sp = workspace:FindFirstChild("SpawnLocation")
if not sp then sp = Instance.new("SpawnLocation"); sp.Parent = workspace end
sp.Size = Vector3.new(6, 1, 6); sp.CFrame = CFrame.lookAt(Vector3.new(6, 0.5, 5), Vector3.new(16, 0.5, 5)); sp.Anchored = true
sp.Material = Enum.Material.SmoothPlastic; sp.Color = C.black; sp.Transparency = 1; sp.CanCollide = false
for _, d in ipairs(sp:GetChildren()) do if d:IsA("Decal") then d:Destroy() end end
local bp = workspace:FindFirstChild("Baseplate"); if bp then bp:Destroy() end
L.markAll(S, B)
return string.format("shell parts=%d", L.count(S))
