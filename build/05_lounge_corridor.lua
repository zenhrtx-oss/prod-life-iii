local function freshRequire(mod) -- edit-mode require caches modules across runs; load a clone so edits take effect
  local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name
  local ok, res = pcall(require, c); c:Destroy(); if not ok then error(res) end; return res
end
local L = require(game:GetService("ReplicatedStorage").OK.BuildLib)
local B = "05_lounge_corridor"
L.clear(B)
local C = L.C
local RS = game:GetService("ReplicatedStorage")
local LO = L.model(workspace.OKStudio, "Lounge")
local CO = L.model(workspace.OKStudio, "Corridor")
local BLACK = {Material = Enum.Material.SmoothPlastic, Color = C.black}
local METAL = {Material = Enum.Material.Metal, Color = C.steel}
local WOOD = {Material = Enum.Material.Wood, Color = C.walnut}
local LEATHER = {Material = Enum.Material.Fabric, Color = Color3.fromRGB(34, 26, 24)}
-- the credits wall shows the house studio's artists (../src/ReplicatedStorage/OK/Data/Artists.lua, tools/sync.py);
-- pressing it opens the player's own credits in the panel (Prod Life III, 2026-10-26: OK's credits were removed)
local roster = freshRequire(RS.OK.Data.Artists).Artists
-- ===== LOUNGE (x 12..44, z -12..12) =====
-- L-shaped sofa facing the TV wall (south): long run along z 6..9.5 (faces -Z), short leg along x 34.5..38 (faces -X)
L.boxMM(LO, "Sofa_Base_Long", 24, 0, 6, 38, 1.2, 9.6, LEATHER)
L.boxMM(LO, "Sofa_Back_Long", 24, 1.2, 9.6, 38.6, 3.4, 10.3, LEATHER)
L.boxMM(LO, "Sofa_Base_Short", 34.6, 0, -1.5, 38, 1.2, 6, LEATHER)
L.boxMM(LO, "Sofa_Back_Short", 38, 1.2, -1.5, 38.6, 3.4, 10.3, LEATHER)
L.boxMM(LO, "Sofa_ArmW", 23.3, 1.2, 6, 24, 2.3, 10.3, LEATHER)
L.boxMM(LO, "Sofa_ArmS", 34.6, 1.2, -2.2, 38.6, 2.3, -1.5, LEATHER)
for i, x in ipairs({25.8, 28.6, 31.4}) do L.seat(LO, "Sofa_Seat_" .. i, Vector3.new(x, 1.5, 7.7), Vector3.new(2.6, 0.5, 3.0), 0, LEATHER) end
for i, z in ipairs({0.3, 3.3}) do L.seat(LO, "Sofa_Seat_S" .. i, Vector3.new(36.3, 1.5, z), Vector3.new(2.6, 0.5, 3.0), 90, LEATHER) end
L.boxMM(LO, "Rug", 20, 0, -6, 40, 0.06, 10, {Material = Enum.Material.Fabric, Color = Color3.fromRGB(52, 30, 36)})
L.boxMM(LO, "Coffee_Top", 26.5, 1.3, 1.0, 32.5, 1.5, 4.2, WOOD)
L.boxMM(LO, "Coffee_LegA", 27, 0, 1.4, 27.4, 1.3, 3.8, METAL); L.boxMM(LO, "Coffee_LegB", 31.6, 0, 1.4, 32, 1.3, 3.8, METAL)
-- TV wall on the south wall (room side faces +Z => Back face)
local tv = L.boxMM(LO, "TV_Screen", 24, 3, -11.45, 36, 9.4, -11.25, {Material = Enum.Material.Glass, Color = Color3.fromRGB(6, 8, 12)})
L.boxMM(LO, "TV_Bezel", 23.7, 2.7, -11.5, 36.3, 9.7, -11.4, BLACK)
L.textFace(tv, Enum.NormalId.Back, "PROD LIFE III\n\nHOUSE STUDIO · LOUNGE\n[ CHANGE SCREEN ]", {TextColor3 = C.pink, PixelsPerStud = 30, Brightness = 2.2, Padding = 12, Name = "ScreenText"})
tv:SetAttribute("InteractKind", "TV"); tv:SetAttribute("ScreenIndex", 1)
local tvGlow = L.neon(LO, "TV_Glow", Vector3.new(30, 2.6, -11.2), Vector3.new(12.4, 0.08, 0.1), C.pink); L.light(tvGlow, "PointLight", C.pink, 0.5, 10)
-- credits wall on the north brick wall (room side faces -Z => Front face): a header and one row of plaques, one per
-- house artist in that artist's colour; pressing the header opens your own credits
local header = L.boxMM(LO, "CreditsWall", 20, 9.2, 11.25, 36, 10.9, 11.45, BLACK)
L.textFace(header, Enum.NormalId.Front, "HOUSE STUDIO · WHO WE MAKE BEATS FOR", {TextColor3 = Color3.fromRGB(220, 190, 120), PixelsPerStud = 40, Brightness = 1.6})
header:SetAttribute("InteractKind", "CreditsWall")
for i, a in ipairs(roster) do
  local width = 2.45; local gap = 0.25
  local total = #roster * width + (#roster - 1) * gap
  local x0 = 28 - total / 2 + (i - 1) * (width + gap)
  local y0 = 6.6
  local p = L.boxMM(LO, "Plaque_" .. i, x0, y0, 11.3, x0 + width, y0 + 2.2, 11.45, {Material = Enum.Material.Wood, Color = Color3.fromRGB(22, 18, 16)})
  L.textFace(p, Enum.NormalId.Front, a.name .. "\n" .. string.upper(a.style), {TextColor3 = a.color or Color3.fromRGB(225, 200, 140), PixelsPerStud = 60, Padding = 5, Brightness = 1.4, Font = Enum.Font.GothamBold})
  p:SetAttribute("ArtistId", a.id)
end
-- neon sign above the sliding door, lounge side (faces -X => Left face)
local sign = L.boxMM(LO, "Neon_Sign", 43.3, 8.8, -5.5, 43.6, 11.4, 5.5, BLACK)
L.textFace(sign, Enum.NormalId.Left, "PROD LIFE III", {TextColor3 = C.pink, PixelsPerStud = 50, Brightness = 3})
local sg = L.neon(LO, "Neon_Sign_Glow", Vector3.new(43.25, 8.75, 0), Vector3.new(0.1, 0.1, 11), C.pink); L.light(sg, "PointLight", C.pink, 1.0, 14)
-- bar along the south wall, west side; stools face -Z toward the bar
L.boxMM(LO, "Bar_Counter", 14, 0, -11, 22, 3.2, -8, WOOD)
L.boxMM(LO, "Bar_Top", 13.8, 3.2, -11.2, 22.2, 3.45, -7.6, {Material = Enum.Material.Marble, Color = Color3.fromRGB(28, 28, 32)})
local barLED = L.neon(LO, "Bar_LED", Vector3.new(18, 3.0, -7.65), Vector3.new(8.2, 0.08, 0.08), C.blue); L.light(barLED, "PointLight", C.blue, 0.5, 8)
L.boxMM(LO, "Bar_Shelf", 14, 5, -11.4, 22, 5.3, -10.4, WOOD)
L.boxMM(LO, "Bar_Shelf2", 14, 7.2, -11.4, 22, 7.5, -10.4, WOOD)
for i = 0, 5 do
  local x = 14.8 + i * 1.2
  local cols = {Color3.fromRGB(40, 90, 60), Color3.fromRGB(120, 40, 30), Color3.fromRGB(200, 160, 60), Color3.fromRGB(60, 60, 120)}
  L.boxMM(LO, "Bottle", x, 5.3, -11.1, x + 0.5, 6.6, -10.6, {Material = Enum.Material.Glass, Color = cols[(i % 4) + 1], Transparency = 0.3})
end
for i, x in ipairs({15.5, 18, 20.5}) do
  L.boxMM(LO, "Stool_Post", x - 0.15, 0, -6.95, x + 0.15, 1.8, -6.65, METAL)
  L.boxMM(LO, "Stool_Foot", x - 0.8, 0, -7.6, x + 0.8, 0.15, -6.0, METAL)
  L.seat(LO, "Stool_" .. i, Vector3.new(x, 2.0, -6.8), Vector3.new(1.6, 0.4, 1.6), 0, LEATHER)
end
-- record crates by the sofa's east end
for i, cz in ipairs({10.6, 8.2}) do
  L.boxMM(LO, "Crate", 40.2, 0, cz - 1.0, 42.8, 1.6, cz + 1.0, WOOD)
  for k = 0, 5 do L.boxMM(LO, "Record", 40.5 + k * 0.36, 0.3, cz - 0.9, 40.5 + k * 0.36 + 0.12, 1.9, cz + 0.9, {Material = Enum.Material.SmoothPlastic, Color = (k % 2 == 0) and Color3.fromRGB(200, 200, 205) or Color3.fromRGB(90, 40, 60)}) end
end
-- plants (pot + crossed leaf slabs)
local function plant(name, x, z)
  L.boxMM(LO, name .. "_Pot", x - 0.9, 0, z - 0.9, x + 0.9, 1.6, z + 0.9, {Material = Enum.Material.Slate, Color = Color3.fromRGB(40, 40, 44)})
  for k = 0, 2 do
    local leaf = L.boxR(LO, name .. "_Leaf", Vector3.new(x, 3.2, z), Vector3.new(0.2, 3.2, 2.6), k * 60, {Material = Enum.Material.Grass, Color = Color3.fromRGB(40, 90, 50)})
  end
end
plant("Plant_A", 13.8, 10.6); plant("Plant_B", 42.6, -10.6)
-- typography posters on the south wall east part (faces +Z => Back)
local function poster(name, x0, x1, text, color)
  local p = L.boxMM(LO, name, x0, 5.0, -11.45, x1, 10.4, -11.3, {Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(14, 14, 16)})
  L.textFace(p, Enum.NormalId.Back, text, {TextColor3 = color, PixelsPerStud = 40, Padding = 10, Brightness = 1.5})
end
poster("Poster_A", 36.6, 39.9, "PROD\nLIFE\nIII", C.pink)
poster("Poster_B", 40.1, 43.4, "MAKE\nBEATS\nGET\nPLACED", C.blue)
-- ===== CORRIDOR (x 0..12, z 0..10) =====
local es = L.boxMM(CO, "Entry_Sign", 2, 5.5, 9.3, 10, 8.5, 9.45, BLACK)
L.textFace(es, Enum.NormalId.Front, "PROD LIFE III\nHOUSE STUDIO", {TextColor3 = C.white, PixelsPerStud = 40, Brightness = 1.6})
for i = 0, 2 do
  L.neon(CO, "Floor_Arrow", Vector3.new(3 + i * 3, 0.03, 5), Vector3.new(1.4, 0.04, 0.25), C.blue, 0)
  L.neon(CO, "Floor_Arrow_Tip", Vector3.new(3.9 + i * 3, 0.03, 5), Vector3.new(0.6, 0.04, 0.25), C.blue, 35)
  L.neon(CO, "Floor_Arrow_Tip2", Vector3.new(3.9 + i * 3, 0.03, 5), Vector3.new(0.6, 0.04, 0.25), C.blue, -35)
end
L.boxMM(CO, "Entry_Bench", 1.2, 0, 0.8, 5.2, 1.4, 2.4, WOOD)
L.markAll(LO, B); L.markAll(CO, B)
local lights = 0; for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("Light") then lights += 1 end end
return string.format("lounge parts=%d corridor parts=%d total=%d lights=%d plaques=%d", L.count(LO), L.count(CO), L.count(workspace.OKStudio), lights, #roster)
