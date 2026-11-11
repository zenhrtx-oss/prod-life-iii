-- Client, during play (after t29): opening the studio PC logs "Used something" and "Opened a beat maker"; opening again
-- logs nothing more.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local char = player.Character; local root = char.HumanoidRootPart; local hum = char.Humanoid; local cam = workspace.CurrentCamera
local daw = player.PlayerGui.OK_DAW.DAW
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
if daw.Visible then daw:SetAttribute("Command", "close"); task.wait(0.4) end
if hum.Sit then hum.Sit = false; task.wait(0.4) end
local screen = workspace.OKStudio.ControlRoom.Screen_Main
local pos = Vector3.new(72.0, 3.5, -5.5)
for round = 1, 2 do
  root.CFrame = CFrame.lookAt(pos, Vector3.new(screen.Position.X, pos.Y, screen.Position.Z)); task.wait(1.0)
  cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(-4, 3, 0), screen.Position); task.wait(1.5)
  local prompt = screen:FindFirstChildWhichIsA("ProximityPrompt", true)
  for i = 1, 4 do prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); task.wait(0.8); if daw.Visible then break end end
  assert(daw.Visible, "beat maker did not open")
  daw:SetAttribute("Command", "close"); task.wait(1.2)
  if hum.Sit then hum.Sit = false; task.wait(0.4) end
end
cam.CameraType = Enum.CameraType.Custom
assert(waitFor(function() return (player:GetAttribute("FunnelStep") or 0) >= 3 end, 3), "funnel did not reach 'Opened a beat maker'")
return "T29B PLAY OK: opened the PC twice; funnel at step " .. player:GetAttribute("FunnelStep")
