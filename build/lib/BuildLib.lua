-- OK Studio BuildLib: shared helpers for the re-runnable build scripts.
local CollectionService = game:GetService("CollectionService")
local L = {}
L.BUILD_ATTR = "OK_Build"
L.TAG = "OK_Interactable"
L.C = {
  concrete = Color3.fromRGB(30, 30, 32), concreteLight = Color3.fromRGB(44, 44, 48),
  walnut = Color3.fromRGB(58, 38, 26), charcoal = Color3.fromRGB(28, 28, 30),
  brick = Color3.fromRGB(74, 36, 30), maroon = Color3.fromRGB(60, 20, 28),
  warm = Color3.fromRGB(255, 190, 120), blue = Color3.fromRGB(0, 170, 255), pink = Color3.fromRGB(255, 60, 160),
  red = Color3.fromRGB(255, 40, 40), steel = Color3.fromRGB(70, 72, 78), black = Color3.fromRGB(12, 12, 14),
  white = Color3.fromRGB(235, 235, 235), leather = Color3.fromRGB(38, 30, 28), wood = Color3.fromRGB(92, 64, 40),
  glass = Color3.fromRGB(180, 210, 230), led = Color3.fromRGB(0, 255, 140),
}
function L.mark(inst, build) inst:SetAttribute(L.BUILD_ATTR, build) return inst end
function L.clear(build)
  local n = 0
  for _, root in ipairs({workspace, game:GetService("Lighting"), game:GetService("ReplicatedStorage"), game:GetService("ServerScriptService"), game:GetService("StarterGui"), game:GetService("StarterPlayer"), game:GetService("ServerStorage")}) do
    for _, d in ipairs(root:GetDescendants()) do
      if d.Parent and d:GetAttribute(L.BUILD_ATTR) == build then d:Destroy(); n += 1 end
    end
  end
  return n
end
function L.model(parent, name)
  local m = parent:FindFirstChild(name)
  if not m then m = Instance.new("Model"); m.Name = name; m.Parent = parent end
  return m
end
function L.folder(parent, name)
  local f = parent:FindFirstChild(name)
  if not f then f = Instance.new("Folder"); f.Name = name; f.Parent = parent end
  return f
end
function L.part(name, size, cf, props)
  local p = Instance.new("Part")
  p.Name = name; p.Size = size; p.CFrame = cf; p.Anchored = true
  p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
  p.Material = Enum.Material.SmoothPlastic; p.Color = L.C.concrete
  if props then for k, v in pairs(props) do p[k] = v end end
  return p
end
-- axis-aligned box from min corner to max corner
function L.boxMM(parent, name, x0, y0, z0, x1, y1, z1, props)
  local size = Vector3.new(x1 - x0, y1 - y0, z1 - z0)
  local p = L.part(name, size, CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), props)
  p.Parent = parent; return p
end
-- box by center and size
function L.box(parent, name, center, size, props)
  local p = L.part(name, size, CFrame.new(center), props); p.Parent = parent; return p
end
-- box by center, size and yaw (degrees)
function L.boxR(parent, name, center, size, yawDeg, props)
  local p = L.part(name, size, CFrame.new(center) * CFrame.Angles(0, math.rad(yawDeg), 0), props); p.Parent = parent; return p
end
-- wall from (x0,z0) to (x1,z1) (axis aligned), thickness t, from y0 up h
function L.wall(parent, name, x0, z0, x1, z1, y0, h, t, props)
  if x0 == x1 then return L.boxMM(parent, name, x0 - t / 2, y0, math.min(z0, z1), x1 + t / 2, y0 + h, math.max(z0, z1), props) end
  return L.boxMM(parent, name, math.min(x0, x1), y0, z0 - t / 2, math.max(x0, x1), y0 + h, z1 + t / 2, props)
end
function L.textFace(part, face, text, props)
  props = props or {}
  local gui = Instance.new("SurfaceGui"); gui.Name = props.Name or "Text"; gui.Face = face
  gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud = props.PixelsPerStud or 50
  gui.LightInfluence = props.LightInfluence or 0; gui.Brightness = props.Brightness or 1.5
  local lbl = Instance.new("TextLabel"); lbl.Name = "Label"
  lbl.Size = UDim2.fromScale(1, 1); lbl.BackgroundTransparency = props.BackgroundTransparency or 1
  lbl.BackgroundColor3 = props.BackgroundColor3 or L.C.black
  lbl.Text = text; lbl.TextColor3 = props.TextColor3 or L.C.white
  lbl.Font = props.Font or Enum.Font.GothamBlack; lbl.TextScaled = props.TextScaled ~= false
  lbl.TextWrapped = true; lbl.RichText = props.RichText or false
  lbl.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center
  lbl.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center
  if props.Padding then local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, props.Padding); pad.PaddingRight = UDim.new(0, props.Padding); pad.PaddingTop = UDim.new(0, props.Padding); pad.PaddingBottom = UDim.new(0, props.Padding); pad.Parent = lbl end
  if props.MaxTextSize then lbl.TextScaled = false; lbl.TextSize = props.MaxTextSize end
  lbl.Parent = gui; gui.Parent = part
  return gui
end
function L.light(part, kind, color, brightness, range, extra)
  local l = Instance.new(kind or "PointLight")
  l.Color = color or L.C.warm; l.Brightness = brightness or 1; l.Range = range or 16; l.Shadows = true
  if extra then for k, v in pairs(extra) do l[k] = v end end
  l.Parent = part; return l
end
function L.neon(parent, name, center, size, color, yawDeg)
  local p = L.part(name, size, CFrame.new(center) * CFrame.Angles(0, math.rad(yawDeg or 0), 0), {Material = Enum.Material.Neon, Color = color, CanCollide = false})
  p.Parent = parent; return p
end
function L.seat(parent, name, center, size, yawDeg, props)
  local s = Instance.new("Seat"); s.Name = name; s.Size = size
  s.CFrame = CFrame.new(center) * CFrame.Angles(0, math.rad(yawDeg or 0), 0); s.Anchored = true
  s.TopSurface = Enum.SurfaceType.Smooth; s.BottomSurface = Enum.SurfaceType.Smooth
  s.Material = Enum.Material.Fabric; s.Color = L.C.leather
  if props then for k, v in pairs(props) do s[k] = v end end
  s.Parent = parent; return s
end
function L.tag(inst, kind, title, extra)
  CollectionService:AddTag(inst, L.TAG); inst:SetAttribute("Kind", kind); inst:SetAttribute("Title", title)
  if extra then for k, v in pairs(extra) do inst:SetAttribute(k, v) end end
  return inst
end
function L.count(root, class)
  local n = 0
  for _, d in ipairs(root:GetDescendants()) do if d:IsA(class or "BasePart") then n += 1 end end
  return n
end
function L.markAll(root, build)
  for _, d in ipairs(root:GetDescendants()) do if d:IsA("BasePart") or d:IsA("Light") or d:IsA("SurfaceGui") or d:IsA("Model") or d:IsA("Folder") or d:IsA("ProximityPrompt") then L.mark(d, build) end end
  -- the container model itself is never marked, so clear() never deletes a room container
end
return L
