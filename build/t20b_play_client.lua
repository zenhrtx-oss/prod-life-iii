-- Client, during play (after t20): a beat missing an ask is refused with the ask named; a different beat delivers
-- the repeat (credit, no pay); unknown requests are refused; the phone layout has a 44 px chip and card buttons.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character; local root = char:WaitForChild("HumanoidRootPart"); local hum = char:WaitForChild("Humanoid"); local cam = workspace.CurrentCamera
local CR = workspace.OKStudio.ControlRoom
local daw = player.PlayerGui:WaitForChild("OK_DAW"):WaitForChild("DAW"); local req = daw:WaitForChild("Request")
local Cfg = require(RS.OK.Modules.DAWConfig)
do local d = player.PlayerGui:WaitForChild("OK_DAW"):WaitForChild("DAW"); d:SetAttribute("CompactForced", nil); d:SetAttribute("ViewportOverride", nil) end -- never inherit phone mode left on by an earlier failed test
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function cmd(c) req:SetAttribute("Command", c); task.wait(0.15) end
local out = {}
if hum.Sit then hum.Sit = false; task.wait(0.4) end
local screen = CR.Screen_Main
local pos = Vector3.new(72.0, 3.5, -5.5)
root.CFrame = CFrame.lookAt(pos, Vector3.new(screen.Position.X, pos.Y, screen.Position.Z)); task.wait(1.0)
cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(-4, 3, 0), screen.Position); task.wait(1.5)
local prompt = screen:FindFirstChildWhichIsA("ProximityPrompt", true)
for i = 1, 4 do prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); task.wait(0.8); if daw.Visible then break end end
assert(daw.Visible, "beat maker did not open")
assert(waitFor(function() return req:GetAttribute("Active") == "j1" and req:GetAttribute("Overlay") == "none" end, 3), "repeat request not active (or picker opened for a returning player)")
-- a different beat from DARK: backbeat added, claps added, but no kick on the 1
local dark = Cfg.Presets[1]
local function set(pat, track, step, ch) local i = (track - 1) * 16 + step; return pat:sub(1, i - 1) .. ch .. pat:sub(i + 1) end
local p = dark.pattern
p = set(p, 2, 5, "1"); p = set(p, 2, 13, "1")
for _, s in ipairs({ 2, 4, 6, 8, 10, 12 }) do p = set(p, 3, s, "1") end
local noKick = set(p, 1, 1, "0")
daw:SetAttribute("Pattern", noKick); daw:SetAttribute("BPM", 140)
assert(waitFor(function() return req:GetAttribute("Ticks") == "101" end, 2), "ticks should show the missing kick: " .. tostring(req:GetAttribute("Ticks")))
task.wait(2.1); req:SetAttribute("LastDeliver", ""); cmd("deliver")
assert(waitFor(function() return req:GetAttribute("LastDeliver") == "missing" end, 4), "missing ask not refused: " .. tostring(req:GetAttribute("LastDeliver")))
assert((req:GetAttribute("Message") or ""):find("Kick on the 1"), "refusal does not name the ask: " .. tostring(req:GetAttribute("Message")))
table.insert(out, "missing ask refused and named: " .. req:GetAttribute("Message"))
-- the full beat delivers as a repeat
daw:SetAttribute("Pattern", p)
assert(waitFor(function() return req:GetAttribute("Stars") == 3 end, 2), "fixed beat should be ready for 3 stars")
task.wait(2.1); req:SetAttribute("LastDeliver", ""); cmd("deliver")
assert(waitFor(function() return req:GetAttribute("LastDeliver") == "ok" and req:GetAttribute("Overlay") == "result" end, 9), "repeat delivery failed: " .. tostring(req:GetAttribute("LastDeliver")))
local resultText = ""
for _, d in ipairs(daw.Result:GetDescendants()) do if d:IsA("TextLabel") then resultText ..= d.Text .. " | " end end
assert(resultText:find("no pay"), "result should say a repeat pays nothing: " .. resultText)
table.insert(out, "repeat delivered: result says credit only, no pay")
cmd("close"); daw:SetAttribute("Command", "stop")
-- unknown request refused
cmd("take:zz")
assert(waitFor(function() return (req:GetAttribute("Message") or ""):find("Couldn't take") end, 3), "unknown request accepted")
table.insert(out, "unknown request refused")
-- phone layout: chip in the header, card behind it, 44 px buttons
daw:SetAttribute("CompactForced", true); daw:SetAttribute("ViewportOverride", Vector2.new(844, 390)); task.wait(0.5)
daw:SetAttribute("Command", "page1"); task.wait(0.3)
local chip = daw.RequestChip
assert(chip.Visible and chip.AbsoluteSize.Y >= 44 and not req.Visible, "phone: chip missing or card shown")
cmd("card")
assert(req.Visible and req:GetAttribute("CardOpen") == true, "phone: chip did not open the card")
for _, b in ipairs({ req.Buttons.Requests, req.Buttons.Back }) do assert(b.Visible and b.AbsoluteSize.Y >= 44, "phone button under 44 px: " .. b.Name) end
cmd("card")
assert(not req.Visible, "phone: card did not close")
daw:SetAttribute("ViewportOverride", Vector2.new(640, 360)); task.wait(0.5)
local kb, ch = daw.HeaderRow.KitBtn, daw.RequestChip
assert(kb.AbsolutePosition.X + kb.AbsoluteSize.X <= ch.AbsolutePosition.X, "KIT runs under the REQUEST chip at 640 px")
table.insert(out, "phone: 44 px chip opens and closes the card; card buttons 44 px")
daw:SetAttribute("CompactForced", nil); daw:SetAttribute("ViewportOverride", nil)
daw:SetAttribute("Command", "close"); task.wait(0.4); cam.CameraType = Enum.CameraType.Custom
return "T20B PLAY OK\n" .. table.concat(out, "\n")
