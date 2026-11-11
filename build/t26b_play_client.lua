-- Client, during play (after t26): SAMPLE IT copies the beat on air; unchanged it is refused, an unsampled copy is
-- refused, and changed 8+ pads it queues as a flip.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local char = player.Character; local root = char.HumanoidRootPart; local hum = char.Humanoid; local cam = workspace.CurrentCamera
local daw = player.PlayerGui:WaitForChild("OK_DAW"):WaitForChild("DAW"); local btn = player.PlayerGui.OK_DAW:WaitForChild("SampleButton")
local NP = RS.OK.NowPlaying
local Cfg = require(RS.OK.Modules.DAWConfig)
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local out = {}
if hum.Sit then hum.Sit = false; task.wait(0.4) end
local screen = workspace.OKStudio.ControlRoom.Screen_Main
local pos = Vector3.new(72.0, 3.5, -5.5)
root.CFrame = CFrame.lookAt(pos, Vector3.new(screen.Position.X, pos.Y, screen.Position.Z)); task.wait(1.0)
cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(-4, 3, 0), screen.Position); task.wait(1.5)
local prompt = screen:FindFirstChildWhichIsA("ProximityPrompt", true)
for i = 1, 4 do prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); task.wait(0.8); if daw.Visible then break end end
assert(daw.Visible, "beat maker did not open")
if daw.Request:GetAttribute("Overlay") ~= "none" then daw.Request:SetAttribute("Command", "close"); task.wait(0.2) end
assert(waitFor(function() return btn.Visible end, 3) and btn.AbsoluteSize.Y >= 44, "SAMPLE IT not shown near the speakers")
btn:SetAttribute("Command", "sample")
assert(waitFor(function() return daw:GetAttribute("LastSample") == "ok" end, 2), "sample failed")
local beat = NP:GetAttribute("Beat")
assert(daw:GetAttribute("Pattern") == Cfg.Upgrade(beat) and daw:GetAttribute("FlipOf") == "Maya Test" and daw:GetAttribute("FlipToken") == NP:GetAttribute("Token"), "sample did not load the beat on air")
table.insert(out, "SAMPLE IT (" .. btn.AbsoluteSize.Y .. " px) loads Maya Test's beat into the beat maker")
daw:SetAttribute("LastBroadcast", ""); daw:SetAttribute("Command", "monitors")
assert(waitFor(function() return daw:GetAttribute("LastBroadcast") == "flipcopy" end, 4), "unchanged flip not refused: " .. tostring(daw:GetAttribute("LastBroadcast")))
local copy = RS.OK.Remotes.DAW_Broadcast:InvokeServer(beat, 100, 0)
assert(not copy.ok and copy.reason == "copy", "unsampled copy not refused: " .. tostring(copy.reason))
table.insert(out, "unchanged flip refused ('" .. daw:GetAttribute("Status") .. "'); unsampled copy refused")
local p = beat
for i = 1, 8 do local idx = 64 + i; p = p:sub(1, idx - 1) .. (p:sub(idx, idx) == "0" and "m" or "0") .. p:sub(idx + 1) end
daw:SetAttribute("Pattern", p)
daw:SetAttribute("LastBroadcast", ""); daw:SetAttribute("Command", "monitors")
assert(waitFor(function() return daw:GetAttribute("LastBroadcast") == "ok" end, 4), "8-pad flip refused: " .. tostring(daw:GetAttribute("LastBroadcast")))
assert(daw:GetAttribute("QueuePos") == 1, "flip should wait behind Maya")
table.insert(out, "flip with 8 new 808 notes queued behind Maya")
return "T26B PLAY OK\n" .. table.concat(out, "\n")
