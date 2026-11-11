-- Client, during play (after t17 reset): the Studio Sessions tour. Opening the PC counts and shows the requests;
-- taking the starter counts; an untouched preset is refused and does not count; a beat made yours delivers for 3 stars
-- (artist in the booth, result screen); ON MONITORS finishes the tour. Card and outline follow the server.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character; local root = char:WaitForChild("HumanoidRootPart"); local hum = char:WaitForChild("Humanoid"); local cam = workspace.CurrentCamera
local studio = workspace.OKStudio; local CR = studio.ControlRoom
local ui = player.PlayerGui:WaitForChild("OK_UI"); local card = ui:WaitForChild("Tour"); local hl = ui:WaitForChild("OK_TourHighlight")
local daw = player.PlayerGui:WaitForChild("OK_DAW"):WaitForChild("DAW"); local req = daw:WaitForChild("Request")
local Cfg = require(RS.OK.Modules.DAWConfig)
local out = {}
do local d = player.PlayerGui:WaitForChild("OK_DAW"):WaitForChild("DAW"); d:SetAttribute("CompactForced", nil); d:SetAttribute("ViewportOverride", nil) end -- never inherit phone mode left on by an earlier failed test
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local toasts = {}
local tconn = RS.OK.Remotes.InteractionEvent.OnClientEvent:Connect(function(kind, payload) if kind == "Toast" then table.insert(toasts, payload.text or "") end end)
local function cmd(c) req:SetAttribute("Command", c); task.wait(0.15) end

-- 1. fresh tour: step 1 of 4 points at the studio PC
assert(waitFor(function() return ui:GetAttribute("TourVisible") == true and ui:GetAttribute("TourCount") == 0 end, 5), "card not shown after reset")
assert(ui:GetAttribute("TourStep") == "open" and card.Head.Text:find("1/5") and hl.Adornee == CR.Screen_Main, "step 1 wrong: " .. tostring(ui:GetAttribute("TourStep")) .. " " .. card.Head.Text)
-- 2. open the PC: counts, and the requests open by themselves for a first-timer
if daw.Visible then daw:SetAttribute("Command", "close"); task.wait(0.4) end
if hum.Sit then hum.Sit = false; task.wait(0.4) end
local screen = CR.Screen_Main
local pos = Vector3.new(72.0, 3.5, -5.5)
root.CFrame = CFrame.lookAt(pos, Vector3.new(screen.Position.X, pos.Y, screen.Position.Z)); task.wait(1.0)
cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(-4, 3, 0), screen.Position); task.wait(1.5)
local prompt = screen:FindFirstChildWhichIsA("ProximityPrompt", true)
for i = 1, 4 do prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); task.wait(0.8); if daw.Visible then break end end
assert(daw.Visible, "beat maker did not open")
assert(waitFor(function() return ui:GetAttribute("TourCount") == 1 and ui:GetAttribute("TourStep") == "take" end, 3), "opening the PC did not count")
assert(waitFor(function() return req:GetAttribute("Overlay") == "picker" end, 3), "requests did not open for a first-timer")
local offers = req:GetAttribute("Offers")
local regular = 0; for id in string.gmatch(offers, "[^,]+") do if not id:match("^[dw]%d") then regular += 1 end end
assert(offers:sub(1, 2) == "j1" and regular == 3, "offers should start with the starter and hold 3 regular requests (dailies and the weekly follow): " .. offers)
assert(req.Visible and req.AbsoluteSize.X > 300, "request card not shown on desktop")
table.insert(out, "opening the PC counts (1/5); the requests open by themselves: " .. offers)
-- 3. take the starter: counts; the preset chooser follows
cmd("take:j1")
assert(waitFor(function() return req:GetAttribute("Active") == "j1" and req:GetAttribute("Overlay") == "presets" end, 3), "taking j1 failed")
assert(waitFor(function() return ui:GetAttribute("TourCount") == 2 and ui:GetAttribute("TourStep") == "deliver" end, 3), "taking the request did not count")
cmd("preset:BOUNCE")
local bounce = Cfg.Presets[2]
assert(waitFor(function() return daw:GetAttribute("Pattern") == bounce.pattern and daw:GetAttribute("BPM") == bounce.bpm and req:GetAttribute("Overlay") == "none" end, 2), "preset not loaded")
assert(waitFor(function() return req:GetAttribute("Ticks") == "111" and req:GetAttribute("Changed") == 0 and req:GetAttribute("Stars") == 0 end, 2), "ticks wrong on the preset: " .. tostring(req:GetAttribute("Ticks")) .. " changed " .. tostring(req:GetAttribute("Changed")))
table.insert(out, "starter taken (2/5); BOUNCE loaded: all asks green but 0 pads changed")
-- 4. an untouched preset is refused and does not count
task.wait(2.1)
cmd("deliver")
assert(waitFor(function() return req:GetAttribute("LastDeliver") == "copy" end, 4), "untouched preset was not refused: " .. tostring(req:GetAttribute("LastDeliver")))
assert((req:GetAttribute("Message") or ""):find("Make it yours") and ui:GetAttribute("TourCount") == 2, "copy refusal message or tour wrong")
table.insert(out, "untouched preset refused ('" .. req:GetAttribute("Message") .. "'), tour unchanged")
-- 5. make it yours (8 pads: extra snares, claps, hats) and deliver for 3 stars
local p = bounce.pattern
local function set(pat, track, step, ch) local i = (track - 1) * 16 + step; return pat:sub(1, i - 1) .. ch .. pat:sub(i + 1) end
for _, s in ipairs({ 3, 7, 11, 15 }) do p = set(p, 2, s, "1") end
for _, s in ipairs({ 2, 10 }) do p = set(p, 3, s, "1") end
for _, s in ipairs({ 8, 16 }) do p = set(p, 4, s, "1") end
daw:SetAttribute("Pattern", p)
assert(waitFor(function() return req:GetAttribute("Changed") >= 8 and req:GetAttribute("Stars") == 3 end, 2), "ticks did not reach 3 stars: changed " .. tostring(req:GetAttribute("Changed")))
task.wait(2.1)
req:SetAttribute("LastDeliver", "")
cmd("deliver")
assert(waitFor(function() return req:GetAttribute("LastDeliver") ~= "" end, 5) and req:GetAttribute("LastDeliver") == "ok", "delivery failed: " .. tostring(req:GetAttribute("LastDeliver")) .. " " .. tostring(req:GetAttribute("Message")))
local artistFig = cam:FindFirstChild("OK_BoothArtist")
assert(artistFig and artistFig:GetAttribute("Artist") == "JUNO VALE", "artist not in the booth")
assert(req:GetAttribute("Cutaway") == true and daw.Parent.Enabled == false and daw:GetAttribute("Playing") == true, "no cutaway listen-back")
local camX = cam.CFrame.Position.X
assert(camX > 80 and camX < 83, "camera not inside the booth: x=" .. camX)
assert(waitFor(function() return req:GetAttribute("Overlay") == "result" and req:GetAttribute("ResultStars") == 3 end, 7), "result screen missing after the cutaway")
assert(daw.Parent.Enabled == true and req:GetAttribute("Cutaway") == false, "window not back after the cutaway")
assert(waitFor(function() return ui:GetAttribute("TourCount") == 3 and ui:GetAttribute("TourStep") == "monitors" end, 3), "delivery did not count")
table.insert(out, "made it yours (8 pads) and delivered for 3 stars: camera cuts to JUNO VALE in the booth for the listen-back, then the result screen; tour 3/5")
cmd("close")
-- 6. ON MONITORS counts
task.wait(2.5)
daw:SetAttribute("Command", "stop"); task.wait(0.2)
daw:SetAttribute("LastBroadcast", ""); daw:SetAttribute("Command", "monitors")
assert(waitFor(function() return (daw:GetAttribute("LastBroadcast") or "") ~= "" end, 5), "no broadcast answer")
local answer = daw:GetAttribute("LastBroadcast")
assert(answer == "ok" or answer == "inline" or answer == "full", "monitors refused: " .. tostring(answer))
assert(waitFor(function() return ui:GetAttribute("TourCount") == 4 and ui:GetAttribute("TourStep") == "gear" end, 3), "monitors did not count")
assert(hl.Adornee == workspace.OKStudio.ControlRoom.GearRack.Panel, "outline should move to the gear rack")
table.insert(out, "monitors (" .. answer .. ") counts (4/5); outline moves to the gear rack")
RS.OK.Remotes.DAW_Stop:FireServer()
daw:SetAttribute("Command", "close"); task.wait(0.4)
-- 7. the gear rack: its prompt opens the Gear tab; buying Roll FX with the starter's money finishes the tour
local rack = workspace.OKStudio.ControlRoom.GearRack.Panel
if hum.Sit then hum.Sit = false; task.wait(0.4) end
local rpos = Vector3.new(61.5, 3.5, -5.5)
root.CFrame = CFrame.lookAt(rpos, Vector3.new(61.5, 3.5, -9.2)); task.wait(1.0)
cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(rpos + Vector3.new(0, 3, 4), Vector3.new(61.5, 5, -9.2)); task.wait(1.5)
local rp = rack:FindFirstChildWhichIsA("ProximityPrompt", true)
local panel = ui:WaitForChild("Panel")
for i = 1, 4 do rp:InputHoldBegin(); task.wait(0.05); rp:InputHoldEnd(); task.wait(0.8); if panel.Visible then break end end
assert(panel.Visible and panel.Content:FindFirstChild("Gear_rollfx"), "gear rack did not open the Gear tab")
local buyBtn = panel.Content.Gear_rollfx.Action
assert(buyBtn:GetAttribute("Action") == "buy" and buyBtn.Text == "BUY $250" and buyBtn.AbsoluteSize.Y >= 44, "Roll FX should be buyable for $250: " .. buyBtn.Text)
ui:SetAttribute("LastGear", "")
local res = RS.OK.Remotes.Gear_Buy:InvokeServer("rollfx") -- what the BUY button sends
assert(res.ok, "buying Roll FX failed: " .. tostring(res.reason))
assert(waitFor(function() return ui:GetAttribute("TourVisible") == false end, 3), "card did not hide after the last step")
assert(not card.Visible and not hl.Enabled and hl.Adornee == nil, "highlight left on after the tour")
assert(waitFor(function() for _, t in ipairs(toasts) do if t:find("tour complete") then return true end end; return false end, 2), "no completion toast")
assert(waitFor(function() return (player:GetAttribute("Unlocked") or ""):find("Rolls") ~= nil and (studio:GetAttribute("RackLit") or 0) >= 1 end, 3), "Roll FX not unlocked or rack LED not lit")
table.insert(out, "gear rack prompt opens the Gear tab; Roll FX bought for $250 finishes the tour (5/5): rolls unlocked, rack LED lit")
tconn:Disconnect()
panel.Visible = false; cam.CameraType = Enum.CameraType.Custom
return "T17B PLAY OK\n" .. table.concat(out, "\n")
