local cam = workspace.CurrentCamera
local mode = MODE
if mode == "lounge" then
  workspace:SetAttribute("_CamBackup", cam.CFrame); workspace:SetAttribute("_FocusBackup", cam.Focus)
  cam.CFrame = CFrame.lookAt(Vector3.new(13.5, 6.5, 4.5), Vector3.new(40, 3, -4)); cam.Focus = CFrame.new(28, 2, 0)
  return "focus lounge"
elseif mode == "control" then
  cam.CFrame = CFrame.lookAt(Vector3.new(48, 7, 9), Vector3.new(78, 3.5, -3)); cam.Focus = CFrame.new(62, 2, 0)
  return "focus control"
else
  local c, f = workspace:GetAttribute("_CamBackup"), workspace:GetAttribute("_FocusBackup")
  if c then cam.CFrame = c end; if f then cam.Focus = f end
  workspace:SetAttribute("_CamBackup", nil); workspace:SetAttribute("_FocusBackup", nil)
  return "restored"
end
