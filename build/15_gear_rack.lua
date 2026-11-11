-- 15: the gear rack sign over the control-room racks. The sign (GearRack.Panel) is an OK_Interactable with
-- Kind = "GearRack" (Systems/Gear opens the Gear tab); its prompt sits on an anchor at standing height in front of the
-- racks. The racks' existing LEDs show each player's own gear (ClientMain). No images, no lights. Idempotent (OK_Build).
local function freshRequire(mod)
  local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name
  local ok, res = pcall(require, c); c:Destroy(); if not ok then error(res) end; return res
end
local RS = game:GetService("ReplicatedStorage")
local L = require(RS.OK.BuildLib)
local Config = freshRequire(RS.OK.Config); local Defs = freshRequire(RS.OK.Modules.Interactions)
local B = "15_gear_rack"
L.clear(B)
local CR = workspace.OKStudio.ControlRoom
local m = Instance.new("Model"); m.Name = "GearRack"; m.Parent = CR; L.mark(m, B)
-- racks: Rack_A at x 60, Rack_B at x 63, fronts at z -9.2, 8.2 tall
local sign = L.box(m, "Panel", Vector3.new(61.5, 8.75, -9.15), Vector3.new(5.6, 0.9, 0.12), { Color = Color3.fromRGB(10, 10, 14), Material = Enum.Material.SmoothPlastic })
L.textFace(sign, Enum.NormalId.Back, "GEAR RACK · SPEND YOUR MONEY", { TextColor3 = L.C.blue, BackgroundTransparency = 1, Padding = 4, PixelsPerStud = 60 })
L.neon(m, "Underline", Vector3.new(61.5, 8.25, -9.12), Vector3.new(5.4, 0.06, 0.06), L.C.blue)
local a = Instance.new("Attachment"); a.Name = "PromptAnchor"; a.Parent = sign; a.WorldPosition = Vector3.new(61.5, 4.4, -8.6)
local p = Instance.new("ProximityPrompt")
p.ActionText = Defs.GearRack.Action; p.ObjectText = Defs.GearRack.Object
p.MaxActivationDistance = Config.Interaction.MaxDistance; p.HoldDuration = Config.Interaction.HoldSeconds
p.RequiresLineOfSight = false; p.KeyboardKeyCode = Enum.KeyCode.E; p.GamepadKeyCode = Enum.KeyCode.ButtonX
p.Parent = a
L.tag(sign, "GearRack", Defs.GearRack.Object)
L.markAll(m, B); L.mark(a, B); L.mark(p, B)
return "15 gear rack ok: sign + prompt at the racks, parts=" .. L.count(workspace.OKStudio)
