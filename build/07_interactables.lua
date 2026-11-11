local function freshRequire(mod) -- edit-mode require caches modules across runs; load a clone so edits take effect
  local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name
  local ok, res = pcall(require, c); c:Destroy(); if not ok then error(res) end; return res
end
local L = require(game:GetService("ReplicatedStorage").OK.BuildLib)
local RS = game:GetService("ReplicatedStorage")
local Config = freshRequire(RS.OK.Config); local Defs = freshRequire(RS.OK.Modules.Interactions)
local B = "07_interactables"
L.clear(B)
local studio = workspace.OKStudio
local hosts = {
  {studio.ControlRoom:FindFirstChild("Screen_Main"), "Computer"},
  {studio.ControlRoom:FindFirstChild("Console"), "Console"},
  {studio.VocalBooth:FindFirstChild("Mic"), "Mic"},
  {studio.ControlRoom:FindFirstChild("LightSwitch"), "LightSwitch"},
  {studio.Shell:FindFirstChild("SlidingDoor"), "Door"},
  {studio.Lounge:FindFirstChild("CreditsWall"), "CreditsWall"},
  {studio.Lounge:FindFirstChild("TV_Screen"), "TV"},
}
local n = 0
for _, h in ipairs(hosts) do
  local inst, kind = h[1], h[2]
  assert(inst, "host missing for " .. kind)
  for _, c in ipairs(inst:GetChildren()) do if c:IsA("ProximityPrompt") then c:Destroy() end end
  local p = Instance.new("ProximityPrompt")
  p.ActionText = Defs[kind].Action; p.ObjectText = Defs[kind].Object
  p.MaxActivationDistance = Config.Interaction.MaxDistance; p.HoldDuration = Config.Interaction.HoldSeconds
  p.RequiresLineOfSight = false; p.Style = Enum.ProximityPromptStyle.Default
  -- neighbours share space (console/computer, door/switch): give them different keys so both can show
  p.KeyboardKeyCode = (kind == "Computer" or kind == "LightSwitch") and Enum.KeyCode.F or Enum.KeyCode.E
  p.GamepadKeyCode = (kind == "Computer" or kind == "LightSwitch") and Enum.KeyCode.ButtonY or Enum.KeyCode.ButtonX
  if kind == "Door" then p.ActionText = inst:GetAttribute("Open") and "Close" or "Open" end
  -- the switch sits on the control-room side of a 1-stud wall: never offer it through the wall
  if kind == "LightSwitch" then p.RequiresLineOfSight = true end
  if kind == "CreditsWall" then
    local a = inst:FindFirstChild("PromptAnchor") or Instance.new("Attachment")
    a.Name = "PromptAnchor"; a.Parent = inst; a.WorldPosition = Vector3.new(21.5, 4.6, 11.0); L.mark(a, B)
    p.Parent = a
  else
    p.Parent = inst
  end
  L.mark(p, B)
  L.tag(inst, kind, Defs[kind].Object)
  inst:SetAttribute("OK_Hooked", nil)
  n += 1
end
return "interactables=" .. n
