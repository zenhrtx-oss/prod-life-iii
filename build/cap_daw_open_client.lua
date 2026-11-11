-- Client, during play: open the beat maker with the default pattern and leave it playing for a screenshot.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer; local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart"); local hum = char:WaitForChild("Humanoid"); local cam = workspace.CurrentCamera
local screen = workspace.OKStudio.ControlRoom.Screen_Main; local prompt = screen:FindFirstChildWhichIsA("ProximityPrompt", true)
if hum.Sit then hum.Sit = false; task.wait(0.4) end
local pos = Vector3.new(72.0, 3.5, -5.5)
root.CFrame = CFrame.lookAt(pos, Vector3.new(screen.Position.X, pos.Y, screen.Position.Z)); task.wait(1.0)
cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(-4, 3, 0), screen.Position); task.wait(1.5)
local daw = player.PlayerGui:WaitForChild("OK_DAW"):WaitForChild("DAW")
for i = 1, 4 do prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); task.wait(0.8); if daw.Visible then break end end
daw:SetAttribute("Pattern", require(RS.OK.Modules.DAWConfig).DefaultPattern); daw:SetAttribute("Command", "play")
task.wait(0.6)
return "open=" .. tostring(daw.Visible) .. " playing=" .. tostring(daw:GetAttribute("Playing")) .. " step=" .. tostring(daw:GetAttribute("Step"))
