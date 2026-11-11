-- Client, during play (after t19c): the player's turn: the window says so, the local preview is off, the room
-- listener plays it and the neon pulses on the kick; STOP ends it and frees the monitors.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local NP = RS.OK.NowPlaying
local daw = player.PlayerGui:WaitForChild("OK_DAW"):WaitForChild("DAW"); local dawGui = player.PlayerGui.OK_DAW
local studio = workspace.OKStudio
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
assert(NP:GetAttribute("Active") and NP:GetAttribute("OwnerId") == player.UserId, "t19c setup missing")
assert(waitFor(function() return daw:GetAttribute("QueuePos") == 0 and (daw:GetAttribute("Status") or ""):find("On the monitors") end, 3), "window did not switch to 'On the monitors': " .. tostring(daw:GetAttribute("Status")))
assert(daw:GetAttribute("Playing") == false, "local preview kept playing during the player's airing")
local p0 = studio:GetAttribute("NeonPulses") or 0
assert(waitFor(function() return (studio:GetAttribute("NeonPulses") or 0) > p0 + 2 and dawGui:GetAttribute("ListenerPlaying") == true end, 4), "neon did not pulse with the monitors' kick")
local out = { "player's turn: window shows it, preview off, room listener plays, neon pulses " .. ((studio:GetAttribute("NeonPulses") or 0) - p0) .. "x" }
RS.OK.Remotes.DAW_Stop:FireServer()
assert(waitFor(function() return NP:GetAttribute("Active") == false end, 3), "STOP did not end the player's airing")
assert(waitFor(function() return (daw:GetAttribute("Status") or ""):find("Done on the monitors") end, 2), "status after stop: " .. tostring(daw:GetAttribute("Status")))
table.insert(out, "STOP ends it; window says done")
daw:SetAttribute("Command", "close"); task.wait(0.4)
-- the control-room side-desk laptop opens the beat maker too, and its beat can go on the monitors
local char = player.Character; local root = char.HumanoidRootPart; local hum = char.Humanoid; local cam = workspace.CurrentCamera
local laptop = studio.ControlRoom.Station_Side.Screen
if hum.Sit then hum.Sit = false; task.wait(0.4) end
local pos = Vector3.new(53.0, 3.5, -6.2)
root.CFrame = CFrame.lookAt(pos, Vector3.new(laptop.Position.X, pos.Y, laptop.Position.Z)); task.wait(1.0)
cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(0, 2.5, 4), laptop.Position); task.wait(1.5)
local prompt = laptop:FindFirstChildWhichIsA("ProximityPrompt")
for i = 1, 4 do prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); task.wait(0.8); if daw.Visible then break end end
assert(daw.Visible and not hum.Sit, "side-desk laptop did not open the beat maker standing")
task.wait(3.2) -- gap after the last airing
daw:SetAttribute("LastBroadcast", ""); daw:SetAttribute("Command", "monitors")
assert(waitFor(function() return (daw:GetAttribute("LastBroadcast") or "") ~= "" end, 5) and daw:GetAttribute("LastBroadcast") == "ok" and NP:GetAttribute("OwnerId") == player.UserId, "monitors refused from the side desk: " .. tostring(daw:GetAttribute("LastBroadcast")))
RS.OK.Remotes.DAW_Stop:FireServer()
assert(waitFor(function() return NP:GetAttribute("Active") == false end, 3), "stop failed")
table.insert(out, "side-desk laptop opens the beat maker standing and puts a beat on the monitors")
daw:SetAttribute("Command", "close"); task.wait(0.4); cam.CameraType = Enum.CameraType.Custom
return "T19D PLAY OK\n" .. table.concat(out, "\n")
