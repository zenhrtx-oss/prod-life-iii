-- Client, during play (after t41c): deliver the starter j1 for 3 stars through the real beat maker (the beat t20b
-- builds: DARK, snares on 5 and 13, claps on 2..12, 140 BPM), so Contracts.Delivered reaches the career for real.
-- Wave 3 Task 3 (fix round 1): first a refused delivery through the same button: that beat plus claps on 14 and 16 (a
-- different pattern, still 8+ pads from every preset, so it reaches the brief check) at 120 BPM, outside j1's 130..160:
-- LastDeliver "missing". t41e checks the recent beats hold only the passing one.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character; local root = char:WaitForChild("HumanoidRootPart"); local hum = char:WaitForChild("Humanoid"); local cam = workspace.CurrentCamera
local CR = workspace.OKStudio.ControlRoom
local daw = player.PlayerGui:WaitForChild("OK_DAW"):WaitForChild("DAW"); local req = daw:WaitForChild("Request")
local Cfg = require(RS.OK.Modules.DAWConfig)
daw:SetAttribute("CompactForced", nil); daw:SetAttribute("ViewportOverride", nil) -- never inherit phone mode left on by an earlier failed test
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function cmd(c) req:SetAttribute("Command", c); task.wait(0.15) end
if hum.Sit then hum.Sit = false; task.wait(0.4) end
local screen = CR.Screen_Main
local pos = Vector3.new(72.0, 3.5, -5.5)
root.CFrame = CFrame.lookAt(pos, Vector3.new(screen.Position.X, pos.Y, screen.Position.Z)); task.wait(1.0)
cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(-4, 3, 0), screen.Position); task.wait(1.5)
local prompt = screen:FindFirstChildWhichIsA("ProximityPrompt", true)
for _ = 1, 4 do prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); task.wait(0.8); if daw.Visible then break end end
assert(daw.Visible, "beat maker did not open")
assert(waitFor(function() return req:GetAttribute("Active") == "j1" and req:GetAttribute("Overlay") == "none" end, 3), "j1 not active (or an overlay opened): " .. tostring(req:GetAttribute("Active")) .. " " .. tostring(req:GetAttribute("Overlay")))
local function set(pat, track, step, ch) local i = (track - 1) * 16 + step; return pat:sub(1, i - 1) .. ch .. pat:sub(i + 1) end
local p = Cfg.Presets[1].pattern
p = set(p, 2, 5, "1"); p = set(p, 2, 13, "1")
for _, s in ipairs({ 2, 4, 6, 8, 10, 12 }) do p = set(p, 3, s, "1") end
-- the refused one first: another pattern at a tempo j1 doesn't take
local refused = set(set(p, 3, 14, "1"), 3, 16, "1")
daw:SetAttribute("Pattern", refused); daw:SetAttribute("BPM", 120)
task.wait(2.1); req:SetAttribute("LastDeliver", ""); cmd("deliver")
assert(waitFor(function() return req:GetAttribute("LastDeliver") == "missing" end, 12),
  "the 120 BPM delivery should be refused (missing): " .. tostring(req:GetAttribute("LastDeliver")) .. " " .. tostring(req:GetAttribute("Message")))
assert(req:GetAttribute("Active") == "j1", "the refused delivery cleared j1: " .. tostring(req:GetAttribute("Active")))
daw:SetAttribute("Pattern", p); daw:SetAttribute("BPM", 140)
assert(waitFor(function() return req:GetAttribute("Stars") == 3 end, 2), "the beat should be ready for 3 stars: " .. tostring(req:GetAttribute("Ticks")))
task.wait(2.1); req:SetAttribute("LastDeliver", ""); cmd("deliver")
assert(waitFor(function() return req:GetAttribute("LastDeliver") == "ok" and req:GetAttribute("Overlay") == "result" and req:GetAttribute("ResultStars") == 3 end, 12),
  "delivery failed: " .. tostring(req:GetAttribute("LastDeliver")) .. " " .. tostring(req:GetAttribute("Message")))
cmd("close"); daw:SetAttribute("Command", "stop")
daw:SetAttribute("Command", "close"); task.wait(0.4); cam.CameraType = Enum.CameraType.Custom
return "T41D PLAY OK: a 120 BPM delivery refused (missing), then j1 delivered for 3 stars through the beat maker (first time)"
