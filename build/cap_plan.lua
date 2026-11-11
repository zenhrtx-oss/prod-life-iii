local CS = game:GetService("CollectionService")
local S = workspace.OKStudio.Shell
local mode = ...
for _, p in ipairs(S:GetChildren()) do
  if p.Name:match("^Ceiling_") then
    if mode == "hide" then p:SetAttribute("T0", p.Transparency); p.Transparency = 1 else p.Transparency = p:GetAttribute("T0") or 0 end
  end
end
return "ceilings " .. tostring(mode)
