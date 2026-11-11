-- Client, during play (after t27): KIT cycles to TAPE, the preview plays TAPE sounds, a save keeps the kit, the server
-- refuses an unowned kit, and the monitors play the producer's kit for listeners.
local Players, RS, SoundService = game:GetService("Players"), game:GetService("ReplicatedStorage"), game:GetService("SoundService")
local player = Players.LocalPlayer
local char = player.Character; local root = char.HumanoidRootPart; local hum = char.Humanoid; local cam = workspace.CurrentCamera
local daw = player.PlayerGui:WaitForChild("OK_DAW"):WaitForChild("DAW")
local Cfg = require(RS.OK.Modules.DAWConfig); local NP = RS.OK.NowPlaying
local tape = Cfg.KitById("tape")
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
assert(waitFor(function() return daw:GetAttribute("Kits") == "studio,tape" end, 3), "owned kits: " .. tostring(daw:GetAttribute("Kits")))
daw:SetAttribute("Kit", "studio"); task.wait(0.1)
daw:SetAttribute("Command", "kit")
assert(waitFor(function() return daw:GetAttribute("Kit") == "tape" end, 2) and daw.HeaderRow.KitBtn.Text == "KIT: TAPE", "KIT did not switch to TAPE")
local heard
local conn = SoundService.ChildAdded:Connect(function(c) if c:IsA("Sound") and c.Name == "Kick" then heard = c.SoundId end end)
daw:SetAttribute("Command", "clear"); task.wait(0.1)
daw:SetAttribute("Command", "tap:1:1"); task.wait(0.3)
conn:Disconnect()
assert(heard == tape.sounds.Kick.id, "preview did not use the TAPE kick: " .. tostring(heard))
table.insert(out, "KIT: TAPE (" .. daw.HeaderRow.KitBtn.AbsoluteSize.Y .. " px); the preview plays the TAPE kick")
local beat = "1000100010001000" .. "0000100000001000" .. string.rep("0", 16) .. "1010101010101010" .. string.rep("0", 16)
daw:SetAttribute("Pattern", beat); daw:SetAttribute("Swing", 0); daw:SetAttribute("Slot", 3)
task.wait(3.2); daw:SetAttribute("LastSave", ""); daw:SetAttribute("Command", "save")
assert(waitFor(function() return daw:GetAttribute("LastSave") == "ok" end, 4), "save with TAPE failed: " .. tostring(daw:GetAttribute("LastSave")))
local prof = RS.OK.Remotes.ProfileFunction:InvokeServer()
assert(prof.daw.slots.s3 and prof.daw.slots.s3.kit == "tape", "slot 3 did not keep the kit")
task.wait(3.2)
local bad = RS.OK.Remotes.DAW_Save:InvokeServer(beat, 140, 0, 3, "iron"); assert(not bad.ok and bad.reason == "locked", "unowned kit accepted")
-- the slot's kit comes back when the beat maker reopens
daw:SetAttribute("Command", "close"); task.wait(0.5); daw:SetAttribute("Kit", "studio")
if hum.Sit then hum.Sit = false; task.wait(0.4) end
root.CFrame = CFrame.lookAt(pos, Vector3.new(screen.Position.X, pos.Y, screen.Position.Z)); task.wait(1.0)
cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(-4, 3, 0), screen.Position); task.wait(1.5)
for i = 1, 4 do prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); task.wait(0.8); if daw.Visible then break end end
assert(daw.Visible and daw:GetAttribute("Slot") == 3 and daw:GetAttribute("Kit") == "tape", "reopening slot 3 did not bring back the TAPE kit: " .. tostring(daw:GetAttribute("Kit")))
if daw.Request:GetAttribute("Overlay") ~= "none" then daw.Request:SetAttribute("Command", "close"); task.wait(0.2) end
table.insert(out, "save keeps the kit and reopening the slot brings it back; an unowned kit (IRON) is refused")
local t0 = os.clock(); while NP:GetAttribute("Active") and os.clock() - t0 < 25 do task.wait(0.2) end
task.wait(3.2)
local underSpeakers = {}
local cr = workspace.OKStudio.ControlRoom
local c1 = cr.Speaker_L.ChildAdded:Connect(function(c) if c:IsA("Sound") then underSpeakers[c.SoundId] = true end end)
local c2 = cr.Speaker_R.ChildAdded:Connect(function(c) if c:IsA("Sound") then underSpeakers[c.SoundId] = true end end)
daw:SetAttribute("LastBroadcast", ""); daw:SetAttribute("Command", "monitors")
assert(waitFor(function() return daw:GetAttribute("LastBroadcast") == "ok" end, 4), "broadcast failed: " .. tostring(daw:GetAttribute("LastBroadcast")))
assert(waitFor(function() return NP:GetAttribute("Kit") == "tape" and underSpeakers[tape.sounds.Kick.id] end, 4), "listeners did not hear the TAPE kit")
c1:Disconnect(); c2:Disconnect()
table.insert(out, "on the monitors the room hears the TAPE kick from the speakers")
RS.OK.Remotes.DAW_Stop:FireServer()
daw:SetAttribute("Command", "close"); task.wait(0.4); cam.CameraType = Enum.CameraType.Custom
return "T27B PLAY OK\n" .. table.concat(out, "\n")
