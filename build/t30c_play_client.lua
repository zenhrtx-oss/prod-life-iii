-- Client, during play (after t30b): VOICE cycles to PLUCK, the preview plays it repitched, a save keeps the voice and
-- reopening the slot brings it back, an unowned voice (CHIME) is refused, and the monitors play the producer's voice.
local Players, RS, SoundService = game:GetService("Players"), game:GetService("ReplicatedStorage"), game:GetService("SoundService")
local player = Players.LocalPlayer
local char = player.Character; local root = char.HumanoidRootPart; local hum = char.Humanoid; local cam = workspace.CurrentCamera
local daw = player.PlayerGui:WaitForChild("OK_DAW"):WaitForChild("DAW")
local Cfg = require(RS.OK.Modules.DAWConfig); local NP = RS.OK.NowPlaying
local pluck = Cfg.VoiceById("pluck")
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local out = {}
if hum.Sit then hum.Sit = false; task.wait(0.4) end
local screen = workspace.OKStudio.ControlRoom.Screen_Main
local pos = Vector3.new(72.0, 3.5, -5.5)
local function open()
  root.CFrame = CFrame.lookAt(pos, Vector3.new(screen.Position.X, pos.Y, screen.Position.Z)); task.wait(1.0)
  cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(-4, 3, 0), screen.Position); task.wait(1.5)
  local prompt = screen:FindFirstChildWhichIsA("ProximityPrompt", true)
  for i = 1, 4 do prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); task.wait(0.8); if daw.Visible then break end end
  assert(daw.Visible, "beat maker did not open")
  if daw.Request:GetAttribute("Overlay") ~= "none" then daw.Request:SetAttribute("Command", "close"); task.wait(0.2) end
end
open()
assert(waitFor(function() return daw:GetAttribute("Voices") == "box,pluck" end, 3), "owned voices: " .. tostring(daw:GetAttribute("Voices")))
daw:SetAttribute("Command", "view:keys"); task.wait(0.25)
daw:SetAttribute("Voice", "box"); task.wait(0.1)
local heard
local conn = SoundService.ChildAdded:Connect(function(c) if c:IsA("Sound") and c.Name == "pluck" then heard = { sid = c.SoundId, speed = c.PlaybackSpeed } end end)
daw:SetAttribute("Command", "voice"); task.wait(0.3)
assert(daw:GetAttribute("Voice") == "pluck" and daw.Roll.KeysBar.VoiceBtn.Text == "VOICE: PLUCK", "VOICE did not switch to PLUCK")
daw:SetAttribute("Pattern", Cfg.DefaultPattern); task.wait(0.1); heard = nil
daw:SetAttribute("Command", "note:1:3:1"); task.wait(0.3); conn:Disconnect()
assert(heard and heard.sid == pluck.SoundId and math.abs(heard.speed - 2 ^ ((3 + pluck.Tune) / 12)) < 0.001, "the preview did not play the PLUCK voice repitched")
table.insert(out, string.format("VOICE: PLUCK (%d px); the preview plays the pluck at speed %.3f", daw.Roll.KeysBar.VoiceBtn.AbsoluteSize.Y, heard.speed))
local melody = daw:GetAttribute("Pattern")
daw:SetAttribute("Slot", 3)
task.wait(3.2); daw:SetAttribute("LastSave", ""); daw:SetAttribute("Command", "save")
assert(waitFor(function() return daw:GetAttribute("LastSave") == "ok" end, 4), "save with PLUCK failed: " .. tostring(daw:GetAttribute("LastSave")))
local prof = RS.OK.Remotes.ProfileFunction:InvokeServer()
assert(prof.daw.slots.s3 and prof.daw.slots.s3.voice == "pluck" and prof.daw.slots.s3.pattern == melody, "slot 3 did not keep the voice")
local bad = RS.OK.Remotes.DAW_Save:InvokeServer(melody, 140, 0, 3, "studio", "chime"); assert(not bad.ok and bad.reason == "locked", "unowned voice accepted")
-- the slot's voice comes back when the beat maker reopens
daw:SetAttribute("Command", "close"); task.wait(0.5); daw:SetAttribute("Voice", "box")
if hum.Sit then hum.Sit = false; task.wait(0.4) end
open()
assert(daw:GetAttribute("Slot") == 3 and daw:GetAttribute("Voice") == "pluck", "reopening slot 3 did not bring back PLUCK: " .. tostring(daw:GetAttribute("Voice")))
table.insert(out, "save keeps the voice and reopening the slot brings it back; an unowned voice (CHIME) is refused")
-- the monitors: listeners hear the producer's voice from the speakers
local t0 = os.clock(); while NP:GetAttribute("Active") and os.clock() - t0 < 25 do task.wait(0.2) end
task.wait(3.2)
local fromSpeakers
local cr = workspace.OKStudio.ControlRoom
local function watch(sp) return sp.ChildAdded:Connect(function(c) if c:IsA("Sound") and c.Name == "pluck" then fromSpeakers = { sid = c.SoundId, speed = c.PlaybackSpeed } end end) end
local c1, c2 = watch(cr.Speaker_L), watch(cr.Speaker_R)
daw:SetAttribute("LastBroadcast", ""); daw:SetAttribute("Command", "monitors")
assert(waitFor(function() return daw:GetAttribute("LastBroadcast") == "ok" end, 4), "broadcast failed: " .. tostring(daw:GetAttribute("LastBroadcast")))
assert(waitFor(function() return NP:GetAttribute("Voice") == "pluck" and fromSpeakers ~= nil end, 4), "listeners did not hear the PLUCK voice")
assert(#NP:GetAttribute("Beat") == 128 and fromSpeakers.sid == pluck.SoundId and math.abs(fromSpeakers.speed - 2 ^ ((3 + pluck.Tune) / 12)) < 0.001, "the room's note is not the producer's note")
c1:Disconnect(); c2:Disconnect()
table.insert(out, "on the monitors the room hears the pluck note from the speakers, repitched like the producer's")
RS.OK.Remotes.DAW_Stop:FireServer()
daw:SetAttribute("Command", "view:drums"); task.wait(0.2)
daw:SetAttribute("Command", "close"); task.wait(0.4); cam.CameraType = Enum.CameraType.Custom
return "T30C PLAY OK\n" .. table.concat(out, "\n")
