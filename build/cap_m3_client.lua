local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer; local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart"); local hum = char:WaitForChild("Humanoid"); local cam = workspace.CurrentCamera
local CR = workspace.OKStudio.ControlRoom; local screen = CR.Screen_Main; local prompt = screen:FindFirstChildWhichIsA("ProximityPrompt", true)
local daw = player.PlayerGui:WaitForChild("OK_DAW"):WaitForChild("DAW")
local mode = MODE
if mode == "open" then
  local t0 = os.clock(); while (player:GetAttribute("Level") or 1) < 4 and os.clock() - t0 < 4 do task.wait(0.1) end
  if hum.Sit then hum.Sit = false; task.wait(0.4) end
  local pos = Vector3.new(72.0, 3.5, -5.5)
  root.CFrame = CFrame.lookAt(pos, Vector3.new(screen.Position.X, pos.Y, screen.Position.Z)); task.wait(1.0)
  cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(-4, 3, 0), screen.Position); task.wait(1.5)
  for i = 1, 4 do prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); task.wait(0.8); if daw.Visible then break end end
  daw:SetAttribute("Pattern", "1000001000100000" .. "0000100000001000" .. "0000000000001000" .. "1030102010301020" .. "m00000p000m000k0")
  daw:SetAttribute("BPM", 140); daw:SetAttribute("Swing", 25); task.wait(0.2)
  daw:SetAttribute("Command", "play"); task.wait(1.6)
  return "open level=" .. tostring(daw:GetAttribute("Level"))
elseif mode == "compact" then daw:SetAttribute("CompactForced", true); task.wait(0.5); return "compact"
elseif mode == "close" then daw:SetAttribute("CompactForced", nil); daw:SetAttribute("Command", "close"); task.wait(0.6); cam.CameraType = Enum.CameraType.Custom; return "closed"
end
