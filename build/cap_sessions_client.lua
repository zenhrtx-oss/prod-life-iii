-- Capture helper (client, play): MODE "open" opens the PC (requests show), "card" takes the starter on BOUNCE,
-- "result" makes it yours and delivers, "phone" switches to the phone layout with the card open, "close" restores.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer; local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart"); local hum = char:WaitForChild("Humanoid"); local cam = workspace.CurrentCamera
local daw = player.PlayerGui:WaitForChild("OK_DAW"):WaitForChild("DAW"); local req = daw:WaitForChild("Request")
local Cfg = require(RS.OK.Modules.DAWConfig)
local mode = MODE
if mode == "open" then
  if hum.Sit then hum.Sit = false; task.wait(0.4) end
  local screen = workspace.OKStudio.ControlRoom.Screen_Main
  local pos = Vector3.new(72.0, 3.5, -5.5)
  root.CFrame = CFrame.lookAt(pos, Vector3.new(screen.Position.X, pos.Y, screen.Position.Z)); task.wait(1.0)
  cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(-4, 3, 0), screen.Position); task.wait(1.5)
  local prompt = screen:FindFirstChildWhichIsA("ProximityPrompt", true)
  for i = 1, 4 do prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); task.wait(0.8); if daw.Visible then break end end
  task.wait(2.5)
  return "open overlay=" .. tostring(req:GetAttribute("Overlay"))
elseif mode == "card" then
  req:SetAttribute("Command", "take:j1"); task.wait(0.6); req:SetAttribute("Command", "preset:BOUNCE"); task.wait(0.6)
  local p = Cfg.Presets[2].pattern
  local function set(pat, track, step, ch) local i = (track - 1) * 16 + step; return pat:sub(1, i - 1) .. ch .. pat:sub(i + 1) end
  for _, s in ipairs({ 3, 7 }) do p = set(p, 2, s, "1") end
  daw:SetAttribute("Pattern", p); task.wait(0.8)
  return "card ticks=" .. tostring(req:GetAttribute("Ticks")) .. " changed=" .. tostring(req:GetAttribute("Changed"))
elseif mode == "result" then
  local p = daw:GetAttribute("Pattern")
  local function set(pat, track, step, ch) local i = (track - 1) * 16 + step; return pat:sub(1, i - 1) .. ch .. pat:sub(i + 1) end
  for _, s in ipairs({ 11, 15 }) do p = set(p, 2, s, "1") end
  for _, s in ipairs({ 2, 10 }) do p = set(p, 3, s, "1") end
  for _, s in ipairs({ 8, 16 }) do p = set(p, 4, s, "1") end
  daw:SetAttribute("Pattern", p); task.wait(0.5)
  req:SetAttribute("Command", "deliver"); task.wait(1.6)
  return "result cutaway=" .. tostring(req:GetAttribute("Cutaway")) .. " last=" .. tostring(req:GetAttribute("LastDeliver")) .. " stars=" .. tostring(req:GetAttribute("ResultStars"))
elseif mode == "after" then
  task.wait(4.5)
  return "after overlay=" .. tostring(req:GetAttribute("Overlay"))
elseif mode == "booth" then
  req:SetAttribute("Command", "close"); task.wait(0.3)
  daw.Visible = false
  local fig = cam:FindFirstChild("OK_BoothArtist")
  cam.CFrame = CFrame.lookAt(Vector3.new(76, 6, -2), Vector3.new(83.6, 3.5, -2)); task.wait(1.0)
  return "booth fig=" .. tostring(fig ~= nil)
elseif mode == "phone" then
  daw.Visible = true
  daw:SetAttribute("CompactForced", true); task.wait(0.6)
  req:SetAttribute("Command", "card"); task.wait(0.6)
  return "phone card=" .. tostring(req.Visible)
elseif mode == "close" then
  daw:SetAttribute("CompactForced", nil); daw:SetAttribute("Command", "close"); task.wait(0.5); cam.CameraType = Enum.CameraType.Custom; return "closed"
end
