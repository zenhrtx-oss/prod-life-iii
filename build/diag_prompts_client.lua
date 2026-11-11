local Players, PPS, CS = game:GetService("Players"), game:GetService("ProximityPromptService"), game:GetService("CollectionService")
local player = Players.LocalPlayer; local char = player.Character or player.CharacterAdded:Wait(); local root = char:WaitForChild("HumanoidRootPart"); local hum = char:WaitForChild("Humanoid")
local cam = workspace.CurrentCamera
local out = {"PPS.Enabled=" .. tostring(PPS.Enabled) .. " camType=" .. tostring(cam.CameraType) .. " sit=" .. tostring(hum.Sit) .. " health=" .. hum.Health}
local console = workspace.OKStudio.ControlRoom.Console
local p = console:FindFirstChildWhichIsA("ProximityPrompt", true)
table.insert(out, "console prompt: " .. tostring(p and p:GetFullName()) .. " enabled=" .. tostring(p and p.Enabled) .. " maxDist=" .. tostring(p and p.MaxActivationDistance))
local shown = {}
local c1 = PPS.PromptShown:Connect(function(pr) table.insert(shown, pr.Parent.Name) end)
root.CFrame = CFrame.lookAt(Vector3.new(72.3, 3.5, 1.2), Vector3.new(console.Position.X, 3.5, console.Position.Z)); task.wait(1.0)
cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(Vector3.new(72.3, 3.5, 1.2) + Vector3.new(-4, 3, 0), console.Position); task.wait(1.5)
table.insert(out, string.format("root=(%.1f,%.1f,%.1f) dist=%.1f shown=%s", root.Position.X, root.Position.Y, root.Position.Z, (root.Position - console.Position).Magnitude, table.concat(shown, ",")))
local fired = false; local c2 = p.Triggered:Connect(function() fired = true end)
p:InputHoldBegin(); task.wait(0.05); p:InputHoldEnd(); task.wait(1.0)
table.insert(out, "client Triggered=" .. tostring(fired) .. " Powered=" .. tostring(console:GetAttribute("Powered")))
local dg = player.PlayerGui:FindFirstChild("OK_DAW"); table.insert(out, "OK_DAW gui=" .. tostring(dg ~= nil) .. " OK_UI=" .. tostring(player.PlayerGui:FindFirstChild("OK_UI") ~= nil))
c1:Disconnect(); c2:Disconnect(); cam.CameraType = Enum.CameraType.Custom
return table.concat(out, "\n")
