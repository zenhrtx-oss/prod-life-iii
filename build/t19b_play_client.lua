-- Client, during play (after t19): the lounge-bar laptop opens the beat maker without the chair; ON MONITORS from it
-- joins the line behind the two pretend producers (#2 waiting), and the window shows the place.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character; local root = char:WaitForChild("HumanoidRootPart"); local hum = char:WaitForChild("Humanoid"); local cam = workspace.CurrentCamera
local NP = RS.OK.NowPlaying
local daw = player.PlayerGui:WaitForChild("OK_DAW"):WaitForChild("DAW")
do local d = player.PlayerGui:WaitForChild("OK_DAW"):WaitForChild("DAW"); d:SetAttribute("CompactForced", nil); d:SetAttribute("ViewportOverride", nil) end -- never inherit phone mode left on by an earlier failed test
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local laptop = workspace.OKStudio.Lounge.Station_Bar.Screen
local side = workspace.OKStudio.ControlRoom.Station_Side.Screen
assert(laptop:FindFirstChildWhichIsA("ProximityPrompt") and side:FindFirstChildWhichIsA("ProximityPrompt"), "laptop prompts missing")
if hum.Sit then hum.Sit = false; task.wait(0.4) end
local pos = Vector3.new(18.0, 3.5, -4.8)
root.CFrame = CFrame.lookAt(pos, Vector3.new(laptop.Position.X, pos.Y, laptop.Position.Z)); task.wait(1.0)
cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(0, 2.5, 4), laptop.Position); task.wait(1.5)
local prompt = laptop:FindFirstChildWhichIsA("ProximityPrompt")
for i = 1, 4 do prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); task.wait(0.8); if daw.Visible then break end end
assert(daw.Visible, "beat maker did not open from the lounge-bar laptop")
assert(not hum.Sit, "the laptop should not seat the player")
local out = { "lounge-bar laptop opens the beat maker, no chair" }
-- save from the laptop
task.wait(3.2)
daw:SetAttribute("Pattern", RS.OK.Modules.DAWConfig and require(RS.OK.Modules.DAWConfig).DefaultPattern); daw:SetAttribute("Swing", 0); daw:SetAttribute("LastSave", "")
daw:SetAttribute("Command", "save")
assert(waitFor(function() return (daw:GetAttribute("LastSave") or "") ~= "" end, 5) and daw:GetAttribute("LastSave") == "ok", "save from the laptop failed: " .. tostring(daw:GetAttribute("LastSave")))
table.insert(out, "saves from the laptop")
-- join the line
assert(NP:GetAttribute("Active") and NP:GetAttribute("OwnerName") == "Ava Test", "t19 setup missing")
daw:SetAttribute("LastBroadcast", ""); daw:SetAttribute("Command", "monitors")
assert(waitFor(function() return (daw:GetAttribute("LastBroadcast") or "") ~= "" end, 5) and daw:GetAttribute("LastBroadcast") == "ok", "monitors refused from the laptop: " .. tostring(daw:GetAttribute("LastBroadcast")))
assert(daw:GetAttribute("QueuePos") == 2 and (daw:GetAttribute("Status") or ""):find("#2 in line"), "window should show #2 in line: " .. tostring(daw:GetAttribute("Status")))
assert(waitFor(function() return (NP:GetAttribute("UpNext") or ""):find(player.DisplayName, 1, true) ~= nil end, 3), "UpNext does not name the player")
table.insert(out, "ON MONITORS from the laptop joins the line behind Bo (#2); window and UP NEXT show it")
return "T19B PLAY OK\n" .. table.concat(out, "\n")
