-- Client, during play: the credits wall opens the panel on your own credits, it auto-closes on distance, and reopens.
local Players = game:GetService("Players")
local player = Players.LocalPlayer; local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart"); local hum = char:WaitForChild("Humanoid"); local cam = workspace.CurrentCamera
local gui = player.PlayerGui:WaitForChild("OK_UI"); local panel = gui:WaitForChild("Panel")
local wall = workspace.OKStudio.Lounge.CreditsWall
local p = wall:FindFirstChildWhichIsA("ProximityPrompt", true); assert(p, "credits prompt missing")
local apos = p.Parent:IsA("Attachment") and p.Parent.WorldPosition or p.Parent.Position
local function standAt(pos)
  if hum.Sit then hum.Sit = false; task.wait(0.4) end
  root.CFrame = CFrame.lookAt(pos, Vector3.new(apos.X, pos.Y, apos.Z)); task.wait(1.0)
  local back = (pos - apos) * Vector3.new(1, 0, 1); back = back.Magnitude > 0.1 and back.Unit * 4 or Vector3.new(-4, 0, 0)
  cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + back + Vector3.new(0, 3, 0), apos); task.wait(1.5)
end
local function trigger() p:InputHoldBegin(); task.wait(0.05); p:InputHoldEnd(); task.wait(0.8) end
standAt(Vector3.new(21.5, 3.5, 8.0)); trigger()
assert(panel.Visible, "panel did not open from the credits wall")
assert(panel.Header.Text == "PROD LIFE III", "panel header reads '" .. panel.Header.Text .. "'")
local labels, mine = 0, false
for _, c in ipairs(panel.Content:GetChildren()) do
  if c:IsA("TextLabel") then labels += 1; if c.Text:find("Your credits", 1, true) then mine = true end end
end
assert(mine and labels >= 2, "credits tab should open on your credits (" .. labels .. " lines)")
root.CFrame = CFrame.new(root.Position + Vector3.new(0, 0, -22)); task.wait(0.8)
assert(not panel.Visible, "panel did not auto-close on distance")
standAt(Vector3.new(21.5, 3.5, 8.0)); trigger()
assert(panel.Visible, "panel did not reopen")
panel.Visible = false; cam.CameraType = Enum.CameraType.Custom
return "T08 PLAY OK: credits wall opens the panel with " .. labels .. " lines, closes on distance, reopens"
