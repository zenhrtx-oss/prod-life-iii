local L = require(game:GetService("ReplicatedStorage").OK.BuildLib)
local B = "03_lighting"
L.clear(B)
local Lighting = game:GetService("Lighting")
local C = L.C
Lighting.ClockTime = 0; Lighting.Brightness = 1; Lighting.GlobalShadows = true
Lighting.Ambient = Color3.fromRGB(78, 72, 88); Lighting.OutdoorAmbient = Color3.fromRGB(8, 8, 12)
Lighting.EnvironmentDiffuseScale = 0.25; Lighting.EnvironmentSpecularScale = 0.35
Lighting.FogColor = Color3.fromRGB(4, 4, 6); Lighting.FogStart = 120; Lighting.FogEnd = 200
Lighting.ExposureCompensation = 0.15; Lighting.ShadowSoftness = 0.3
for _, e in ipairs(Lighting:GetChildren()) do if e:IsA("SunRaysEffect") or e:IsA("Atmosphere") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then e:Destroy() end end
local cc = Instance.new("ColorCorrectionEffect"); cc.Contrast = 0.12; cc.Saturation = 0.05; cc.TintColor = Color3.fromRGB(255, 242, 228); cc.Parent = Lighting; L.mark(cc, B)
local bloom = Instance.new("BloomEffect"); bloom.Intensity = 0.35; bloom.Size = 24; bloom.Threshold = 0.95; bloom.Parent = Lighting; L.mark(bloom, B)
local LM = L.model(workspace.OKStudio, "Lighting")
-- helpers
local function pendant(name, x, z, y, color, bright, range)
  local cord = L.boxMM(LM, name .. "_Cord", x - 0.1, y + 1.2, z - 0.1, x + 0.1, 12, z + 0.1, {Color = C.black})
  local shade = L.box(LM, name .. "_Shade", Vector3.new(x, y + 0.6, z), Vector3.new(2.2, 1.2, 2.2), {Material = Enum.Material.Metal, Color = C.black})
  local bulb = L.neon(LM, name .. "_Bulb", Vector3.new(x, y, z), Vector3.new(1.2, 0.3, 1.2), color)
  L.light(bulb, "PointLight", color, bright or 1.2, range or 18)
  return bulb
end
local function recessed(name, x, z, ceilY, color, bright, range, angle)
  local can = L.box(LM, name .. "_Can", Vector3.new(x, ceilY - 0.15, z), Vector3.new(1.6, 0.3, 1.6), {Material = Enum.Material.Metal, Color = C.black})
  local lens = L.neon(LM, name .. "_Lens", Vector3.new(x, ceilY - 0.32, z), Vector3.new(1.2, 0.08, 1.2), color)
  L.light(lens, "PointLight", color, bright or 1.5, range or 20)
  return lens
end
local function strip(name, center, size, color, bright, range)
  local s = L.neon(LM, name, center, size, color)
  L.light(s, "PointLight", color, bright or 0.6, range or 14)
  return s
end
-- corridor: blue ceiling strip
strip("Strip_Corridor", Vector3.new(6, 9.8, 5), Vector3.new(11, 0.15, 0.4), C.blue, 1.3, 16)
local sconce = L.neon(LM, "Sconce_Corridor_Bulb", Vector3.new(6, 7.2, 9.1), Vector3.new(1.6, 0.3, 0.3), C.warm)
L.light(sconce, "PointLight", C.warm, 2.2, 18)
local up = L.neon(LM, "Uplight_Corridor_Bulb", Vector3.new(1.2, 0.3, 8.6), Vector3.new(0.6, 0.3, 0.6), C.warm)
L.light(up, "PointLight", C.warm, 1.6, 14)
local bsc = L.neon(LM, "Sconce_Booth_Bulb", Vector3.new(93.2, 7.4, 0), Vector3.new(0.3, 0.3, 1.6), C.warm)
L.light(bsc, "PointLight", C.warm, 0.9, 14)
-- lounge: two warm pendants over seating, one over the bar, blue strip along the south wall top
pendant("Pendant_Lounge_1", 24, 2, 8.5, C.warm, 1.4, 22)
pendant("Pendant_Lounge_2", 32, -5, 8.5, C.warm, 1.4, 22)
pendant("Pendant_Bar", 20, -9, 8.5, C.warm, 1.0, 14)
strip("Strip_Lounge_S", Vector3.new(28, 11.7, -11.3), Vector3.new(30, 0.15, 0.4), C.blue, 0.5, 18)
-- control room: two warm recessed spots over the console, one over the couch, pink strip over the booth window, blue strip under the ceiling north edge
recessed("Spot_Console_1", 72, -5, 12, C.warm, 2.6, 28, 85)
recessed("Spot_Console_2", 72, 2, 12, C.warm, 2.6, 28, 85)
recessed("Spot_Couch", 50, 7.5, 12, C.warm, 2.2, 26, 85)
strip("Strip_Ctrl_N", Vector3.new(62, 11.7, 11.3), Vector3.new(34, 0.15, 0.4), C.blue, 0.5, 18)
-- booth: one warm recessed light
recessed("Spot_Booth", 87, 0, 10, C.warm, 1.3, 16, 80)
L.markAll(LM, B)
local n = 0
for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("Light") then n += 1 end end
return string.format("lighting fixtures parts=%d lights=%d", L.count(LM), n)
