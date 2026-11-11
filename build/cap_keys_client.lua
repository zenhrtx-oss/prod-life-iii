-- Capture helper (client, play): MODE "open" opens the beat maker in the KEYS view with a melody; "all" switches the
-- scale lock to ALL NOTES; "phone" forces the phone layout; "close" restores everything.
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
  task.wait(1.5)
  if req:GetAttribute("Overlay") ~= "none" then req:SetAttribute("Command", "close"); task.wait(0.3) end
  daw:SetAttribute("Command", "stop"); task.wait(0.2)
  daw:SetAttribute("CompactForced", nil); daw:SetAttribute("ViewportOverride", nil)
  local p = Cfg.Presets[1].pattern
  p = p:sub(1, 64) .. "m000m000p000j000" .. p:sub(81) -- an 808 line shows as ghost notes
  for _, n in ipairs({ { 1, 0, 2, true }, { 3, 3, 1 }, { 5, 7, 4 }, { 9, 10, 2, true }, { 11, 7, 1 }, { 13, 12, 2 }, { 15, 3, 2 }, { 5, 0, 4 }, { 13, 5, 2 } }) do
    p = Cfg.PlaceNote(p, n[1], n[2], n[3], n[4]) or p
  end
  daw:SetAttribute("Pattern", p); daw:SetAttribute("BPM", 142)
  daw:SetAttribute("Command", "view:keys"); task.wait(0.4)
  daw:SetAttribute("Command", "play"); task.wait(0.9)
  return "open view=" .. tostring(daw:GetAttribute("View")) .. " notes=" .. #Cfg.Notes(daw:GetAttribute("Pattern"))
elseif mode == "all" then
  while daw:GetAttribute("Scale") ~= "all" do daw:SetAttribute("Command", "scale"); task.wait(0.25) end
  task.wait(0.4)
  return "scale=" .. tostring(daw:GetAttribute("Scale"))
elseif mode == "phone" then
  while daw:GetAttribute("Scale") ~= "minpent" do daw:SetAttribute("Command", "scale"); task.wait(0.25) end
  daw:SetAttribute("CompactForced", true); task.wait(0.8)
  return "phone compact=" .. tostring(daw:GetAttribute("Compact"))
elseif mode == "close" then
  daw:SetAttribute("Command", "stop"); daw:SetAttribute("CompactForced", nil); daw:SetAttribute("Command", "view:drums"); task.wait(0.2)
  daw:SetAttribute("Command", "close"); task.wait(0.5); cam.CameraType = Enum.CameraType.Custom; return "closed"
end
