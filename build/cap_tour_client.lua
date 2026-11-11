-- Capture helper (client, play): MODE "wall" frames the credits wall with the tour card; "daw" opens the beat maker.
local Players = game:GetService("Players")
local player = Players.LocalPlayer; local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart"); local hum = char:WaitForChild("Humanoid"); local cam = workspace.CurrentCamera
local S = workspace.OKStudio; local ui = player.PlayerGui:WaitForChild("OK_UI")
local mode = MODE
if hum.Sit then hum.Sit = false; task.wait(0.4) end
if mode == "wall" then
  local wall = S.Lounge.CreditsWall
  local pos = Vector3.new(24, 3.5, 2)
  root.CFrame = CFrame.lookAt(pos, Vector3.new(wall.Position.X, pos.Y, wall.Position.Z)); task.wait(0.8)
  cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(4, 4, -6), wall.Position); cam.Focus = CFrame.new(wall.Position)
  task.wait(1.5)
  return "wall visible=" .. tostring(ui.Tour.Visible) .. " adornee=" .. tostring(ui.OK_TourHighlight.Adornee)
elseif mode == "daw" then
  local CR = S.ControlRoom; local screen = CR.Screen_Main; local prompt = screen:FindFirstChildWhichIsA("ProximityPrompt", true)
  local daw = player.PlayerGui:WaitForChild("OK_DAW"):WaitForChild("DAW")
  local pos = Vector3.new(72.0, 3.5, -5.5)
  root.CFrame = CFrame.lookAt(pos, Vector3.new(screen.Position.X, pos.Y, screen.Position.Z)); task.wait(1.0)
  cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(-4, 3, 0), screen.Position); task.wait(1.5)
  for i = 1, 4 do prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); task.wait(0.8); if daw.Visible then break end end
  task.wait(1.2)
  return "daw open=" .. tostring(daw.Visible) .. " card=" .. tostring(ui.Tour.Visible)
elseif mode == "close" then
  local daw = player.PlayerGui.OK_DAW.DAW; daw:SetAttribute("Command", "close"); task.wait(0.5); cam.CameraType = Enum.CameraType.Custom; return "closed"
end
