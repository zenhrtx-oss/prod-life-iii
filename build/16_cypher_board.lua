-- 16: the cypher board at the lounge entrance (OK_Interactable Kind = "Cypher"; Systems/BeatBattles handles joining).
-- Parts + SurfaceGui text, no images, no lights. Prompt key F (the bar laptop's E prompt is nearby). Idempotent (OK_Build).
local function freshRequire(mod)
  local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name
  local ok, res = pcall(require, c); c:Destroy(); if not ok then error(res) end; return res
end
local RS = game:GetService("ReplicatedStorage")
local L = require(RS.OK.BuildLib)
local Config = freshRequire(RS.OK.Config); local Defs = freshRequire(RS.OK.Modules.Interactions)
local B = "16_cypher_board"
L.clear(B)
local m = Instance.new("Model"); m.Name = "CypherBoard"; m.Parent = workspace.OKStudio.Lounge; L.mark(m, B)
local dark = Color3.fromRGB(16, 16, 20)
L.box(m, "Base", Vector3.new(14.6, 0.1, -4.0), Vector3.new(1.6, 0.2, 1.6), { Color = dark, Material = Enum.Material.Metal })
L.box(m, "Pole", Vector3.new(14.6, 2.0, -4.0), Vector3.new(0.3, 3.8, 0.3), { Color = dark, Material = Enum.Material.Metal })
local sign = L.box(m, "Sign", Vector3.new(14.7, 4.9, -4.0), Vector3.new(0.15, 2.0, 3.4), { Color = Color3.fromRGB(10, 10, 16), Material = Enum.Material.SmoothPlastic })
L.textFace(sign, Enum.NormalId.Right, "CYPHER\n<font size=\"14\">JOIN · BUILD · VOTE</font>", { RichText = true, TextColor3 = L.C.pink, BackgroundTransparency = 1, Padding = 6, PixelsPerStud = 60 })
L.neon(m, "Underline", Vector3.new(14.8, 3.85, -4.0), Vector3.new(0.06, 0.06, 3.2), L.C.pink)
local a = Instance.new("Attachment"); a.Name = "PromptAnchor"; a.Parent = sign; a.WorldPosition = Vector3.new(15.4, 3.6, -4.0)
local p = Instance.new("ProximityPrompt")
p.ActionText = Defs.Cypher.Action; p.ObjectText = Defs.Cypher.Object
p.MaxActivationDistance = Config.Interaction.MaxDistance; p.HoldDuration = Config.Interaction.HoldSeconds
p.RequiresLineOfSight = false; p.KeyboardKeyCode = Enum.KeyCode.F; p.GamepadKeyCode = Enum.KeyCode.ButtonY
p.Parent = a
L.tag(sign, "Cypher", Defs.Cypher.Object)
L.markAll(m, B); L.mark(a, B); L.mark(p, B)
return "16 cypher board ok, parts=" .. L.count(workspace.OKStudio)
