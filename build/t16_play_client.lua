-- Client, during play (no gear bought yet): the free 808 works and is pitched per note; hat rolls and swing stay locked
-- (window and server) until Roll FX / the Swing Unit are bought at the gear rack.
local Players, RS, SoundService = game:GetService("Players"), game:GetService("ReplicatedStorage"), game:GetService("SoundService")
local player = Players.LocalPlayer; local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart"); local hum = char:WaitForChild("Humanoid"); local cam = workspace.CurrentCamera
local Cfg = require(RS.OK.Modules.DAWConfig); local SaveFn = RS.OK.Remotes.DAW_Save
local CR = workspace.OKStudio.ControlRoom; local daw = player.PlayerGui:WaitForChild("OK_DAW"):WaitForChild("DAW")
local out = {}
assert((player:GetAttribute("Level") or 1) == 2, "expected level 2 after t15, got " .. tostring(player:GetAttribute("Level")))
local screen = CR.Screen_Main; local prompt = screen:FindFirstChildWhichIsA("ProximityPrompt", true)
if hum.Sit then hum.Sit = false; task.wait(0.4) end
local pos = Vector3.new(72.0, 3.5, -5.5)
root.CFrame = CFrame.lookAt(pos, Vector3.new(screen.Position.X, pos.Y, screen.Position.Z)); task.wait(1.0)
cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(-4, 3, 0), screen.Position); task.wait(1.5)
for i = 1, 4 do prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); task.wait(0.8); if daw.Visible then break end end
assert(daw.Visible, "beat maker did not open")
local u = daw:GetAttribute("Unlocked") or ""
assert(u:find("Bass") and not u:find("Rolls") and not u:find("Swing"), "window unlocks should be the free 808 only: " .. u)
daw:SetAttribute("Command", "clear"); task.wait(0.1)
-- 808: tap cycles root -> +3, each played at its pitch
local speeds = {}
local conn = SoundService.ChildAdded:Connect(function(c) if c:IsA("Sound") and c.Name == "808" then table.insert(speeds, c.PlaybackSpeed) end end)
daw:SetAttribute("Command", "tap:5:1"); task.wait(0.15); daw:SetAttribute("Command", "tap:5:1"); task.wait(0.15)
conn:Disconnect()
local cell = daw:GetAttribute("Pattern"):sub(65, 65)
assert(cell == Cfg.NoteChar(3), "808 cell should be +3 after two taps, got '" .. cell .. "'")
assert(#speeds == 2 and math.abs(speeds[1] - 1) < 0.01 and math.abs(speeds[2] - 2 ^ (3 / 12)) < 0.01, "808 not pitched per note: " .. table.concat(speeds, ","))
assert(daw.Grid.Cell_5_1.Text == "+3", "808 pad label should read +3")
table.insert(out, string.format("808: root then +3, played at speed %.3f then %.3f, pad reads +3", speeds[1], speeds[2]))
-- rolls locked without Roll FX: two taps go on then off
daw:SetAttribute("Command", "tap:4:1"); task.wait(0.1); daw:SetAttribute("Command", "tap:4:1"); task.wait(0.1)
assert(daw:GetAttribute("Pattern"):sub(49, 49) == "0", "hat roll should be locked without Roll FX")
daw:SetAttribute("Command", "swing"); task.wait(0.1)
assert(daw:GetAttribute("Swing") == 0 and daw:GetAttribute("Status"):find("gear rack"), "swing should point to the gear rack: " .. tostring(daw:GetAttribute("Status")))
local roll = string.rep("0", 48) .. "3000000000000000" .. string.rep("0", 16)
task.wait(3.2); local r = SaveFn:InvokeServer(roll, 140, 0, 1)
assert(r.ok == false and r.reason == "locked", "server accepted a hat roll without Roll FX")
table.insert(out, "hat rolls and swing locked without gear, in the window and on the server; swing points to the gear rack")
daw:SetAttribute("Command", "close"); task.wait(0.4)
return "T16 PLAY OK\n" .. table.concat(out, "\n")
