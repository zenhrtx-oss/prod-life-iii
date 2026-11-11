local mode = MODE
local n = 0
for _, l in ipairs(workspace.OKStudio:GetDescendants()) do
  if l:IsA("SpotLight") or l:IsA("SurfaceLight") then
    if mode == "boost" then l:SetAttribute("_B0", l.Brightness); l.Brightness = l.Brightness * 4 else l.Brightness = l:GetAttribute("_B0") or l.Brightness; l:SetAttribute("_B0", nil) end
    n += 1
  end
end
return mode .. " " .. n
