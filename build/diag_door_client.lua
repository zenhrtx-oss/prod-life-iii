local Players, PPS, CS = game:GetService("Players"), game:GetService("ProximityPromptService"), game:GetService("CollectionService")
local player = Players.LocalPlayer; local char = player.Character or player.CharacterAdded:Wait(); local root = char:WaitForChild("HumanoidRootPart")
local studio = workspace:WaitForChild("OKStudio"); local door = studio.Shell.SlidingDoor
local shown = {}
local c1 = PPS.PromptShown:Connect(function(p) shown[p.Parent.Name] = (shown[p.Parent.Name] or 0) + 1 end)
root.CFrame = CFrame.new(40.5, 3.5, 0); task.wait(2.0)
local out = {string.format("root=(%.1f,%.1f,%.1f) door=(%.1f,%.1f,%.1f) dist=%.1f", root.Position.X, root.Position.Y, root.Position.Z, door.Position.X, door.Position.Y, door.Position.Z, (root.Position - door.Position).Magnitude)}
for _, inst in ipairs(CS:GetTagged("OK_Interactable")) do
  local p = inst:FindFirstChildOfClass("ProximityPrompt")
  table.insert(out, string.format("  %-12s dist=%5.1f enabled=%s max=%d shownEvents=%d", inst.Name, (root.Position - inst.Position).Magnitude, tostring(p and p.Enabled), p and p.MaxActivationDistance or -1, shown[inst.Name] or 0))
end
local p = door:FindFirstChildOfClass("ProximityPrompt")
local fired = false; local c2 = p.Triggered:Connect(function() fired = true end)
local c3 = PPS.PromptTriggered:Connect(function(pp) if pp == p then fired = true end end)
p:InputHoldBegin(); task.wait(0.05); p:InputHoldEnd(); task.wait(1.0)
table.insert(out, "door client-side Triggered fired=" .. tostring(fired) .. " Open=" .. tostring(door:GetAttribute("Open")))
-- try the console the same way for comparison from here (far away: should NOT fire)
local console = studio.ControlRoom.Console; local cp = console:FindFirstChildOfClass("ProximityPrompt"); local cfired = false
local c4 = cp.Triggered:Connect(function() cfired = true end); cp:InputHoldBegin(); task.wait(0.05); cp:InputHoldEnd(); task.wait(0.8)
table.insert(out, "console from afar fired=" .. tostring(cfired))
c1:Disconnect(); c2:Disconnect(); c3:Disconnect(); c4:Disconnect()
return table.concat(out, "\n")
