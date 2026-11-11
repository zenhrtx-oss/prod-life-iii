local Players, PPS = game:GetService("Players"), game:GetService("ProximityPromptService")
local player = Players.LocalPlayer; local char = player.Character or player.CharacterAdded:Wait(); local root = char:WaitForChild("HumanoidRootPart"); local hum = char:WaitForChild("Humanoid")
local studio = workspace:WaitForChild("OKStudio")
local log = {}
PPS.PromptShown:Connect(function(p) table.insert(log, "shown " .. p.Parent.Name) end)
PPS.PromptHidden:Connect(function(p) table.insert(log, "hidden " .. p.Parent.Name) end)
local function standAt(x, y, z) root.CFrame = CFrame.new(x, y, z); task.wait(2.0) end
local function trigger(inst) local p = inst:FindFirstChildOfClass("ProximityPrompt"); p:InputHoldBegin(); task.wait(0.05); p:InputHoldEnd(); task.wait(0.7) end
standAt(69.5, 3.5, -2); trigger(studio.ControlRoom.Console)
table.insert(log, string.format("after console: root=(%.1f,%.1f,%.1f) state=%s", root.Position.X, root.Position.Y, root.Position.Z, tostring(hum:GetState())))
standAt(88.5, 3.5, -2); trigger(studio.VocalBooth.Mic)
table.insert(log, string.format("after mic: root=(%.1f,%.1f,%.1f) state=%s", root.Position.X, root.Position.Y, root.Position.Z, tostring(hum:GetState())))
standAt(40.5, 3.5, 0)
table.insert(log, string.format("at door: root=(%.1f,%.1f,%.1f) state=%s health=%.0f", root.Position.X, root.Position.Y, root.Position.Z, tostring(hum:GetState()), hum.Health))
local door = studio.Shell.SlidingDoor
trigger(door)
table.insert(log, "door Open=" .. tostring(door:GetAttribute("Open")))
return table.concat(log, "\n")
