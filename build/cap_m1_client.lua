local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer; local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart"); local hum = char:WaitForChild("Humanoid"); local cam = workspace.CurrentCamera
local CR = workspace.OKStudio.ControlRoom; local screen = CR.Screen_Main; local prompt = screen:FindFirstChildWhichIsA("ProximityPrompt", true)
local daw = player.PlayerGui:WaitForChild("OK_DAW"):WaitForChild("DAW")
local mode = MODE
if mode == "open" then
  if hum.Sit then hum.Sit = false; task.wait(0.4) end
  local pos = Vector3.new(72.0, 3.5, -5.5)
  root.CFrame = CFrame.lookAt(pos, Vector3.new(screen.Position.X, pos.Y, screen.Position.Z)); task.wait(1.0)
  cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(-4, 3, 0), screen.Position); task.wait(1.5)
  for i = 1, 4 do prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); task.wait(0.8); if daw.Visible then break end end
  daw:SetAttribute("Pattern", require(RS.OK.Modules.DAWConfig).DefaultPattern); daw:SetAttribute("BPM", 142); daw:SetAttribute("Command", "play"); task.wait(1.2)
  return "open playing=" .. tostring(daw:GetAttribute("Playing"))
elseif mode == "compact" then
  daw:SetAttribute("CompactForced", true); task.wait(0.4); return "compact"
elseif mode == "close" then
  daw:SetAttribute("CompactForced", nil); daw:SetAttribute("Command", "close"); task.wait(0.5); return "closed"
elseif mode == "doorway" then
  if hum.Sit then hum.Sit = false; task.wait(0.3) end
  root.CFrame = CFrame.new(30, 3.5, 4); task.wait(0.5)
  cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(Vector3.new(26, 6.5, 3), Vector3.new(60, 4, -1)); task.wait(0.8)
  return "doorway"
else
  cam.CameraType = Enum.CameraType.Custom; return "reset"
end
