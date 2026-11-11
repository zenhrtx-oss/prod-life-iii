-- 18: the Studio Two door (walk-ins). STRUCTURE, idempotent (OK_Build = "18_gates"); run in Edit before Play, after
-- ok_assets/scripts/connect_studio_two.py has cut the doorway, and after 16. InteractionService attaches the door's
-- sound at Init, so a door built during Play would stay silent until the next Play.
-- Workspace.OK_Gates.StudioTwoDoor: a glass part filling the 4 x 7.5 doorway in the corridor's north wall (x 4-8), with
-- a prompt (E / ButtonX) and the OK_Interactable tag, Kind = "StudioTwoDoor" (Systems/Unlocks answers it). It lives
-- outside OKStudio and OK_Passage_StudioTwo because 02_shell and connect_studio_two.py rebuild those. The door opens per
-- player on the client (StarterPlayerScripts/OK/GatesClient); the server's door always collides. No lights, no images.
local function freshRequire(mod)
  local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name
  local ok, res = pcall(require, c); c:Destroy(); if not ok then error(res) end; return res
end
local RS = game:GetService("ReplicatedStorage")
local L = require(RS.OK.BuildLib)
local Config = freshRequire(RS.OK.Config)
-- the prompt copy (Modules/Interactions); literal until the module that names StudioTwoDoor is synced
local def = freshRequire(RS.OK.Modules.Interactions).StudioTwoDoor or { Action = "Enter", Object = "The Hall" }
local B = "18_gates"
assert(workspace:FindFirstChild("OK_Passage_StudioTwo"), "Workspace.OK_Passage_StudioTwo missing: run ok_assets/scripts/connect_studio_two.py first")
local shell = workspace.OKStudio.Shell
local cut = shell:FindFirstChild("Wall_Corr_N_Top") or shell:FindFirstChild("Wall_Corr_N_L") or shell:FindFirstChild("Wall_Corr_N_R")
if not cut then
  if shell:FindFirstChild("Wall_Corr_N") then error("doorway not cut: run ok_assets/scripts/connect_studio_two.py") end
  error("OKStudio.Shell has no Wall_Corr_N pieces: rebuild the shell (02) and run ok_assets/scripts/connect_studio_two.py")
end
local z = cut.Position.Z
L.clear(B)
local gates = Instance.new("Model"); gates.Name = "OK_Gates"
local door = L.box(gates, "StudioTwoDoor", Vector3.new(6, 3.75, z), Vector3.new(4, 7.5, 0.4),
  { Material = Enum.Material.Glass, Transparency = 0.4, Color = Color3.fromRGB(40, 40, 52), CanCollide = true })
local p = Instance.new("ProximityPrompt")
p.ActionText = def.Action; p.ObjectText = def.Object
p.MaxActivationDistance = Config.Interaction.MaxDistance; p.HoldDuration = Config.Interaction.HoldSeconds
p.RequiresLineOfSight = false; p.KeyboardKeyCode = Enum.KeyCode.E; p.GamepadKeyCode = Enum.KeyCode.ButtonX
p.Parent = door
L.tag(door, "StudioTwoDoor", def.Object)
L.mark(gates, B); L.markAll(gates, B)
gates.Parent = workspace
return string.format("18 gates ok: OK_Gates.StudioTwoDoor at (6, 3.75, %.2f) in the doorway cut (%s)", z, cut.Name)
