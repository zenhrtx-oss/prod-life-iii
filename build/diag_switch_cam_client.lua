local Players, PPS = game:GetService("Players"), game:GetService("ProximityPromptService")
local player = Players.LocalPlayer; local char = player.Character or player.CharacterAdded:Wait(); local root = char:WaitForChild("HumanoidRootPart"); local hum = char:WaitForChild("Humanoid")
local studio = workspace:WaitForChild("OKStudio"); local sw = studio.ControlRoom.LightSwitch; local p = sw:FindFirstChildOfClass("ProximityPrompt")
local cam = workspace.CurrentCamera
local log = {}
PPS.PromptShown:Connect(function(pr) table.insert(log, "shown " .. pr.Parent.Name) end)
PPS.PromptHidden:Connect(function(pr) table.insert(log, "hidden " .. pr.Parent.Name) end)
local pos = Vector3.new(47.5, 3.5, -4.1)
root.CFrame = CFrame.lookAt(pos, Vector3.new(sw.Position.X, pos.Y, sw.Position.Z)); task.wait(1.0)
cam.CameraType = Enum.CameraType.Scriptable
cam.CFrame = CFrame.lookAt(root.Position + Vector3.new(5, 3, 0), sw.Position); task.wait(1.5)
local before = studio:GetAttribute("LightPreset")
p:InputHoldBegin(); task.wait(0.05); p:InputHoldEnd(); task.wait(0.8)
table.insert(log, "with camera aimed: preset " .. tostring(before) .. " -> " .. tostring(studio:GetAttribute("LightPreset")))
cam.CameraType = Enum.CameraType.Custom
return table.concat(log, "\n")
