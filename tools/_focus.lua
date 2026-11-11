local cam = workspace.CurrentCamera
local mode = MODE
if mode == "save" then
  workspace:SetAttribute("_CamBackup", cam.CFrame); workspace:SetAttribute("_FocusBackup", cam.Focus)
  cam.CFrame = CFrame.lookAt(Vector3.new(-60, 40, -39.99), Vector3.new(-60, 0, -40)); cam.Focus = CFrame.new(-60, 0, -40)
  return "focused on the test"
else
  local c, f = workspace:GetAttribute("_CamBackup"), workspace:GetAttribute("_FocusBackup")
  if c then cam.CFrame = c end; if f then cam.Focus = f end
  workspace:SetAttribute("_CamBackup", nil); workspace:SetAttribute("_FocusBackup", nil)
  return "camera restored"
end
