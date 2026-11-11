-- Client, during play (level 4): hat rolls fire three hits in one step, swing delays the even steps, slots keep separate beats.
local Players, RS, SoundService = game:GetService("Players"), game:GetService("ReplicatedStorage"), game:GetService("SoundService")
local player = Players.LocalPlayer; local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart"); local hum = char:WaitForChild("Humanoid"); local cam = workspace.CurrentCamera
local Cfg = require(RS.OK.Modules.DAWConfig)
local CR = workspace.OKStudio.ControlRoom; local daw = player.PlayerGui.OK_DAW.DAW
local out = {}
local t0 = os.clock(); while (player:GetAttribute("Level") or 1) < 4 and os.clock() - t0 < 4 do task.wait(0.1) end
assert(player:GetAttribute("Level") == 4, "not level 4")
local screen = CR.Screen_Main; local prompt = screen:FindFirstChildWhichIsA("ProximityPrompt", true)
if hum.Sit then hum.Sit = false; task.wait(0.4) end
local pos = Vector3.new(72.0, 3.5, -5.5)
root.CFrame = CFrame.lookAt(pos, Vector3.new(screen.Position.X, pos.Y, screen.Position.Z)); task.wait(1.0)
cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(-4, 3, 0), screen.Position); task.wait(1.5)
for i = 1, 4 do prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); task.wait(0.8); if daw.Visible then break end end
assert(daw.Visible and daw:GetAttribute("Level") == 4, "beat maker not open at level 4")
-- hat roll: three taps -> "3", which fires three hats in one step
daw:SetAttribute("Command", "clear"); task.wait(0.1)
for i = 1, 3 do daw:SetAttribute("Command", "tap:4:1"); task.wait(0.12) end
assert(daw:GetAttribute("Pattern"):sub(49, 49) == "3" and daw.Grid.Cell_4_1.Text == "×3", "hat roll did not reach x3")
local hats, times = 0, {}
local conn = SoundService.ChildAdded:Connect(function(c) if c:IsA("Sound") and c.Name == "Hat" then hats += 1; table.insert(times, os.clock()) end end)
daw:SetAttribute("BPM", 60); daw:SetAttribute("Command", "play"); task.wait(0.4); daw:SetAttribute("Command", "stop"); conn:Disconnect()
task.wait(0.2) -- attribute signals are deferred: let "stop" land before the next command
assert(hats == 3 and times[3] - times[1] > 0.1, "roll should fire 3 hats spread across the step, got " .. hats)
table.insert(out, string.format("hat roll x3: 3 hats over %.2f s of a 0.25 s step", times[3] - times[1]))
-- swing 50%: the kick on step 2 lands later than the step tick
local function kickDelay(swingValue)
  daw:SetAttribute("Pattern", "0100000000000000" .. string.rep("0", 64)); daw:SetAttribute("BPM", 60)
  while daw:GetAttribute("Swing") ~= swingValue do daw:SetAttribute("Command", "swing"); task.wait(0.05) end
  local stepAt, kickAt
  local c1 = daw:GetAttributeChangedSignal("Step"):Connect(function() if daw:GetAttribute("Step") == 2 and not stepAt then stepAt = os.clock() end end)
  local c2 = SoundService.ChildAdded:Connect(function(c) if c:IsA("Sound") and c.Name == "Kick" and not kickAt then kickAt = os.clock() end end)
  daw:SetAttribute("Command", "play"); task.wait(0.7); daw:SetAttribute("Command", "stop"); c1:Disconnect(); c2:Disconnect()
  task.wait(0.2)
  return (kickAt and stepAt) and (kickAt - stepAt) or -1
end
local d0, d50 = kickDelay(0), kickDelay(50)
assert(d0 > -0.5 and math.abs(d0) < 0.03 and d50 > 0.04, string.format("swing delay wrong: 0%%=%.3f s, 50%%=%.3f s", d0, d50))
table.insert(out, string.format("swing: kick on step 2 lands %.3f s late at 50%% (vs %.3f s at 0%%)", d50, d0))
-- slots: save slot 2, switch to slot 1 and back
local beat2 = Cfg.Upgrade("1000000010000000" .. "0000100000001000" .. string.rep("0", 16) .. "2020202020202020" .. "m000000p00000000")
daw:SetAttribute("Command", "slot:2"); task.wait(0.1)
daw:SetAttribute("Pattern", beat2); daw:SetAttribute("BPM", 150); daw:SetAttribute("Swing", 50)
task.wait(3.2); daw:SetAttribute("LastSave", ""); daw:SetAttribute("Command", "save")
local t1 = os.clock(); while daw:GetAttribute("LastSave") == "" and os.clock() - t1 < 5 do task.wait(0.1) end
assert(daw:GetAttribute("LastSave") == "ok", "slot 2 save failed: " .. tostring(daw:GetAttribute("LastSave")))
daw:SetAttribute("Command", "slot:1"); task.wait(0.15)
assert(daw:GetAttribute("Pattern") ~= beat2, "slot 1 shows slot 2's beat")
daw:SetAttribute("Command", "slot:2"); task.wait(0.15)
assert(daw:GetAttribute("Pattern") == beat2 and daw:GetAttribute("BPM") == 150 and daw:GetAttribute("Swing") == 50, "slot 2 did not come back")
local prof = RS.OK.Remotes.ProfileFunction:InvokeServer()
assert(prof.daw.v == 2 and prof.daw.slots.s2 and prof.daw.slots.s2.pattern == beat2 and prof.daw.slots.s2.swing == 50, "slot 2 not in the profile")
table.insert(out, "slots: slot 2 saved with 808, double hats and swing 50; slot 1 separate; switching back restores it")
daw:SetAttribute("Command", "close"); task.wait(0.4); cam.CameraType = Enum.CameraType.Custom
return "T16C PLAY OK\n" .. table.concat(out, "\n")
