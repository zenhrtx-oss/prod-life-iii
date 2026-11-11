local Lighting, TS = game:GetService("Lighting"), game:GetService("TweenService")
local Config = require(game:GetService("ReplicatedStorage").OK.Config)
local M = {}; M.Current = "Warm"
local function tween(inst, props, t) TS:Create(inst, TweenInfo.new(t or 1), props):Play() end
local function isStrip(n) return n:match("^Strip_") or n == "Desk_LED" or n == "Bar_LED" end
local function isPendant(n) return (n:match("_Bulb$") or n:match("_Lens$")) and n ~= "BoothLamp" end
function M.Apply(name)
  local p = Config.LightPresets[name]; if not p then return false end
  M.Current = name
  tween(Lighting, {Ambient = p.Ambient, ExposureCompensation = p.Exposure}, 1)
  for _, d in ipairs(workspace.OKStudio:GetDescendants()) do
    if d:IsA("BasePart") and d.Material == Enum.Material.Neon then
      if isPendant(d.Name) then tween(d, {Color = p.Pendant}, 1) elseif isStrip(d.Name) then tween(d, {Color = p.Strip}, 1) end
      local l = d:FindFirstChildWhichIsA("Light")
      if l then if isPendant(d.Name) then tween(l, {Color = p.Pendant}, 1) elseif isStrip(d.Name) then tween(l, {Color = p.Strip}, 1) end end
    end
  end
  workspace.OKStudio:SetAttribute("LightPreset", name)
  return true
end
function M.Toggle() M.Apply(M.Current == "Warm" and "Neon" or "Warm"); return M.Current end
function M.Init() M.Apply(M.Current) end -- the preset's base light, not whatever the place was saved with
return M
