local cam = workspace.CurrentCamera
local mode = MODE
if mode == "booth" then
  workspace:SetAttribute("_CamBackup", cam.CFrame); workspace:SetAttribute("_FocusBackup", cam.Focus)
  cam.CFrame = CFrame.lookAt(Vector3.new(81.5, 6, 6.5), Vector3.new(90, 3.5, -3)); cam.Focus = CFrame.new(87, 2, 0)
elseif mode == "corridor" then
  cam.CFrame = CFrame.lookAt(Vector3.new(1.5, 5.5, 3), Vector3.new(14, 4, 6)); cam.Focus = CFrame.new(6, 2, 5)
else
  local c, f = workspace:GetAttribute("_CamBackup"), workspace:GetAttribute("_FocusBackup")
  if c then cam.CFrame = c end; if f then cam.Focus = f end
  workspace:SetAttribute("_CamBackup", nil); workspace:SetAttribute("_FocusBackup", nil)
end
return mode
