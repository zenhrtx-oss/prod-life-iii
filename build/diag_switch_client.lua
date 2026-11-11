local Players, PPS = game:GetService("Players"), game:GetService("ProximityPromptService")
local player = Players.LocalPlayer; local char = player.Character or player.CharacterAdded:Wait(); local root = char:WaitForChild("HumanoidRootPart"); local hum = char:WaitForChild("Humanoid")
local studio = workspace:WaitForChild("OKStudio"); local sw = studio.ControlRoom.LightSwitch; local p = sw:FindFirstChildOfClass("ProximityPrompt")
local log = {}
PPS.PromptShown:Connect(function(pr) table.insert(log, "shown " .. pr.Parent.Name) end)
PPS.PromptHidden:Connect(function(pr) table.insert(log, "hidden " .. pr.Parent.Name) end)
for _, spot in ipairs({Vector3.new(47.5, 3.5, -4.1), Vector3.new(46.2, 3.5, -4.1), Vector3.new(46.5, 3.5, -2.5)}) do
  if hum.Sit then hum.Sit = false; task.wait(0.4) end
  root.CFrame = CFrame.new(spot); task.wait(2.0)
  table.insert(log, string.format("spot (%.1f,%.1f,%.1f): root=(%.1f,%.1f,%.1f) dist=%.1f state=%s promptEnabled=%s key=%s", spot.X, spot.Y, spot.Z, root.Position.X, root.Position.Y, root.Position.Z, (root.Position - sw.Position).Magnitude, tostring(hum:GetState()), tostring(p.Enabled), tostring(p.KeyboardKeyCode)))
  local before = studio:GetAttribute("LightPreset")
  p:InputHoldBegin(); task.wait(0.05); p:InputHoldEnd(); task.wait(0.8)
  table.insert(log, "  preset " .. tostring(before) .. " -> " .. tostring(studio:GetAttribute("LightPreset")))
end
return table.concat(log, "\n")
