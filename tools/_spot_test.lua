local mode = MODE
local f = workspace:FindFirstChild("_SpotTest")
if mode == "clean" then if f then f:Destroy() end; return "cleaned" end
if f then f:Destroy() end
f = Instance.new("Model"); f.Name = "_SpotTest"; f.Parent = workspace
local function part(name, size, pos, color, mat)
  local p = Instance.new("Part"); p.Name = name; p.Size = size; p.Position = pos; p.Anchored = true; p.Color = color; p.Material = mat or Enum.Material.SmoothPlastic; p.Parent = f; return p
end
part("Floor", Vector3.new(80, 1, 80), Vector3.new(1000, -0.5, 0), Color3.fromRGB(60, 60, 60))
local lamp = part("Lamp", Vector3.new(1, 0.2, 1), Vector3.new(1000, 10, 0), Color3.new(1, 1, 1), Enum.Material.Neon)
local s = Instance.new("SpotLight"); s.Face = Enum.NormalId.Bottom; s.Angle = 60; s.Brightness = 10; s.Range = 40; s.Color = Color3.new(1, 1, 1); s.Shadows = false; s.Parent = lamp
-- markers: green = edge if Angle is the full cone (r = 10*tan 30 = 5.77); red = edge if Angle is the half-angle (r = 10*tan 60 = 17.3)
for _, x in ipairs({-5.77, 5.77}) do part("Full", Vector3.new(0.3, 0.1, 6), Vector3.new(1000 + x, 0.05, 0), Color3.fromRGB(0, 255, 0), Enum.Material.Neon) end
for _, x in ipairs({-17.3, 17.3}) do part("Half", Vector3.new(0.3, 0.1, 6), Vector3.new(1000 + x, 0.05, 0), Color3.fromRGB(255, 0, 0), Enum.Material.Neon) end
return "built"
