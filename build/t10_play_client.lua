-- Client, during play: beat maker v1. Desk seat + camera framing, instrument feel, sequencer, save, phone layout,
-- close restores everything. Ends with the beat maker OPEN and seated, for t10b (server kill) and t10c (respawn checks).
local Players, RS, CP, SoundService = game:GetService("Players"), game:GetService("ReplicatedStorage"), game:GetService("ContentProvider"), game:GetService("SoundService")
local PPS, GuiService, CAS = game:GetService("ProximityPromptService"), game:GetService("GuiService"), game:GetService("ContextActionService")
local player = Players.LocalPlayer; local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart"); local hum = char:WaitForChild("Humanoid"); local cam = workspace.CurrentCamera
local Cfg = require(RS.OK.Modules.DAWConfig); local SaveFn = RS.OK.Remotes.DAW_Save
local CR = workspace.OKStudio.ControlRoom
local out = {}
local function waitFor(fn, t) local t0 = os.clock(); while os.clock() - t0 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
-- 1) samples load and are audible
for _, tr in ipairs(Cfg.Tracks) do
  local s = RS.OK.Samples[tr.Name]:Clone(); s.Parent = SoundService
  CP:PreloadAsync({s}); waitFor(function() return s.IsLoaded end, 5)
  assert(s.IsLoaded and s.TimeLength > 0, tr.Name .. " did not load")
  local len = s.TimeLength
  s:Play(); local peak = 0; local t1 = os.clock(); while os.clock() - t1 < 0.25 do peak = math.max(peak, s.PlaybackLoudness); task.wait() end
  s:Destroy(); assert(peak > 0, tr.Name .. " played silent")
  table.insert(out, string.format("sample %-5s len=%.2fs peak=%.0f", tr.Name, len, peak))
end
-- 2) open at the studio PC: seated, camera on the console, prompts hidden
local screen = CR.Screen_Main; local prompt = screen:FindFirstChildWhichIsA("ProximityPrompt", true)
if hum.Sit then hum.Sit = false; task.wait(0.4) end
local pos = Vector3.new(72.0, 3.5, -5.5)
root.CFrame = CFrame.lookAt(pos, Vector3.new(screen.Position.X, pos.Y, screen.Position.Z)); task.wait(1.0)
cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(-4, 3, 0), screen.Position); task.wait(1.5)
local daw = player.PlayerGui:WaitForChild("OK_DAW", 5):WaitForChild("DAW")
for i = 1, 4 do prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); task.wait(0.8); if daw.Visible then break end end
assert(daw.Visible, "beat maker did not open from the studio PC")
assert(waitFor(function() return hum.SeatPart == CR.Chair_Seat end, 3), "not seated in Chair_Seat")
task.wait(0.6)
assert(cam.CameraType == Enum.CameraType.Scriptable, "camera not in the seated view")
assert(PPS.Enabled == false, "prompts still enabled while the window is open")
assert(next(CAS:GetBoundActionInfo("OK_DAW_PlayStop")) ~= nil and next(CAS:GetBoundActionInfo("OK_DAW_Close")) ~= nil, "play/close actions not bound")
local vp = cam.ViewportSize; local winTop = daw.AbsolutePosition.Y
for _, part in ipairs({CR.Meter_1_1, CR.Meter_8_6, CR.Screen_Main}) do
  local p3, onScreen = cam:WorldToViewportPoint(part.Position)
  assert(onScreen, part.Name .. " is off screen in the seated view")
  assert(p3.Y < winTop - 4, string.format("%s hidden behind the window (y=%.0f, window top=%.0f, vp=%.0f)", part.Name, p3.Y, winTop, vp.Y))
end
table.insert(out, string.format("seated in Chair_Seat; meters and Screen_Main above the window (top=%.0f of %.0f)", winTop, vp.Y))
-- 3) instrument feel: audition, clear + undo, paint, layout order
daw:SetAttribute("Pattern", Cfg.DefaultPattern); task.wait(0.1)
daw:SetAttribute("Command", "clear"); task.wait(0.1)
assert(daw:GetAttribute("Pattern") == string.rep("0", #Cfg.DefaultPattern), "clear failed")
daw:SetAttribute("Command", "undo"); task.wait(0.1)
assert(daw:GetAttribute("Pattern") == Cfg.DefaultPattern, "undo did not restore the exact pattern")
daw:SetAttribute("Command", "clear"); task.wait(0.1)
local h0 = daw:GetAttribute("Hits"); daw:SetAttribute("Command", "paint:2:5:5"); task.wait(0.15)
assert(daw:GetAttribute("Hits") == h0 + 1, "turning a pad on did not play it")
daw:SetAttribute("Command", "paint:4:1:8"); task.wait(0.1)
assert(daw:GetAttribute("Pattern"):sub(49, 56) == "11111111", "paint did not fill hat steps 1-8")
local tr = daw.Transport
assert(math.abs(tr.Save.LayoutOrder - tr.Clear.LayoutOrder) > 1, "SAVE sits next to CLEAR")
table.insert(out, "audition +1 hit, clear/undo exact, paint 1-8, SAVE away from CLEAR")
-- 4) sequencer
local pat = Cfg.Upgrade("1" .. string.rep("0", 15) .. "1" .. string.rep("0", 15) .. "1" .. string.rep("0", 15) .. string.rep("10", 8) .. string.rep("0", 16))
daw:SetAttribute("Pattern", pat); daw:SetAttribute("BPM", 160)
local hits0 = daw:GetAttribute("Hits"); daw:SetAttribute("Command", "play"); task.wait(2.0)
assert(daw:GetAttribute("Playing") == true and player:GetAttribute("DAWPlaying") == true, "not playing")
local hits = daw:GetAttribute("Hits") - hits0; assert(hits >= 10, "too few hits: " .. hits)
daw:SetAttribute("Command", "stop"); task.wait(0.2)
assert(daw:GetAttribute("Step") == 0 and player:GetAttribute("DAWPlaying") == false, "stop did not reset")
table.insert(out, string.format("sequencer: %d hits in 2 s at 160 BPM", hits))
-- 5) meters follow the kick
local kickOnly = Cfg.Upgrade("1000100010001000" .. string.rep("0", 64))
daw:SetAttribute("Pattern", kickOnly); daw:SetAttribute("BPM", 120)
local onKick, offKick = {}, {}
local conn = daw:GetAttributeChangedSignal("Step"):Connect(function()
  local st = daw:GetAttribute("Step"); if st == 0 then return end
  task.delay(0.04, function() local lv = CR.Console:GetAttribute("MeterLevel") or 0; if (st - 1) % 4 == 0 then table.insert(onKick, lv) else table.insert(offKick, lv) end end)
end)
daw:SetAttribute("Command", "play"); task.wait(4.2); daw:SetAttribute("Command", "stop"); conn:Disconnect(); task.wait(0.1)
local function avg(t) local s = 0; for _, v in ipairs(t) do s += v end; return #t > 0 and s / #t or 0 end
assert(#onKick >= 4 and avg(onKick) > avg(offKick) + 1, string.format("meters not on the beat (kick avg %.1f vs %.1f)", avg(onKick), avg(offKick)))
table.insert(out, string.format("meters: kick steps avg %.1f vs other steps %.1f", avg(onKick), avg(offKick)))
-- 6) save (session wording while unpublished), read back, rate limit, bad input
daw:SetAttribute("Pattern", pat); daw:SetAttribute("BPM", 160); daw:SetAttribute("LastSave", "")
daw:SetAttribute("Command", "save"); waitFor(function() return daw:GetAttribute("LastSave") ~= "" end, 5)
assert(daw:GetAttribute("LastSave") == "ok", "save failed: " .. tostring(daw:GetAttribute("LastSave")))
if game.PlaceId == 0 then assert(daw:GetAttribute("Status"):find("session"), "unpublished save should say it lasts for this session: " .. daw:GetAttribute("Status")) end
local firstStatus = daw:GetAttribute("Status")
local prof = RS.OK.Remotes.ProfileFunction:InvokeServer(); local sl = prof.daw and prof.daw.slots and prof.daw.slots["s" .. daw:GetAttribute("Slot")]
assert(sl and sl.pattern == pat and sl.bpm == 160, "saved beat not in the active slot")
daw:SetAttribute("LastSave", ""); daw:SetAttribute("Command", "save"); waitFor(function() return daw:GetAttribute("LastSave") ~= "" end, 5)
assert(daw:GetAttribute("LastSave") == "cooldown", "second save not rate-limited")
for _, case in ipairs({{"abc", 140}, {string.rep("2", 64), 140}, {nil, 140}, {pat, "fast"}, {{}, 140}}) do
  local r = SaveFn:InvokeServer(case[1], case[2]); assert(type(r) == "table" and r.ok == false and r.reason == "invalid", "malformed payload accepted")
end
table.insert(out, "save ok ('" .. firstStatus .. "'), rate limit, 5 malformed payloads rejected")
-- 7) phone layout: every pad and control at least 44 px at two common phone sizes
for _, size in ipairs({Vector2.new(844, 390), Vector2.new(667, 375)}) do
  daw:SetAttribute("ViewportOverride", size); daw:SetAttribute("CompactForced", true); task.wait(0.25)
  local small = {}
  for _, d in ipairs(daw:GetDescendants()) do
    if d:IsA("GuiButton") and d.Visible and d:IsDescendantOf(daw) then
      local vis = true; local n = d.Parent; while n and n ~= daw do if n:IsA("GuiObject") and not n.Visible then vis = false end; n = n.Parent end
      if vis and d.Name ~= "ModalCatcher" and not d.Name:match("^Label%d") and (d.AbsoluteSize.X < 44 or d.AbsoluteSize.Y < 44) then table.insert(small, string.format("%s %dx%d", d.Name, d.AbsoluteSize.X, d.AbsoluteSize.Y)) end
    end
  end
  assert(#small == 0, string.format("at %dx%d these are under 44 px: %s", size.X, size.Y, table.concat(small, ", ")))
  local rx0, ry0 = daw.AbsolutePosition.X, daw.AbsolutePosition.Y
  local rx1, ry1 = rx0 + daw.AbsoluteSize.X, ry0 + daw.AbsoluteSize.Y
  for _, d in ipairs(daw:GetDescendants()) do
    if d:IsA("GuiButton") and d.Visible and d.Name ~= "ModalCatcher" then
      local vis = true; local scroller = nil; local n = d.Parent
      while n and n ~= daw do if n:IsA("GuiObject") and not n.Visible then vis = false end; if n:IsA("ScrollingFrame") then scroller = n end; n = n.Parent end
      if vis then
        -- a button in a scrolling list is reachable by scrolling: the list itself must fit the window
        local box = scroller or d
        local x0, y0 = box.AbsolutePosition.X, box.AbsolutePosition.Y
        local d = box
        assert(x0 >= rx0 - 1 and y0 >= ry0 - 1 and x0 + d.AbsoluteSize.X <= rx1 + 1 and y0 + d.AbsoluteSize.Y <= ry1 + 1, d.Name .. " sits outside the window at " .. size.X .. "x" .. size.Y)
      end
    end
  end
  local tr2 = daw.Transport
  assert(tr2.Save.AbsolutePosition.Y - (tr2.Clear.AbsolutePosition.Y + tr2.Clear.AbsoluteSize.Y) >= 40, "SAVE too close to CLEAR on a phone")
  local bottom = daw.AbsolutePosition.Y + daw.AbsoluteSize.Y
  for _, d in ipairs(daw.Transport:GetDescendants()) do if d:IsA("GuiButton") and d.Visible then assert(d.AbsolutePosition.Y + d.AbsoluteSize.Y <= bottom + 1, d.Name .. " falls off the bottom of the window at " .. size.X .. "x" .. size.Y) end end
  table.insert(out, string.format("phone layout %dx%d: all controls and pads >= 44 px", size.X, size.Y))
end
daw:SetAttribute("CompactForced", nil); daw:SetAttribute("ViewportOverride", nil); daw:SetAttribute("Page", 1); task.wait(0.2)
-- 8) close restores everything (and keeps the unsaved beat)
local draftPat = Cfg.Upgrade("1000000000000000" .. "0000000010000000" .. string.rep("0", 32) .. string.rep("1", 16))
daw:SetAttribute("Pattern", draftPat)
daw:SetAttribute("Command", "play"); task.wait(0.3); daw:SetAttribute("Command", "close"); task.wait(0.6)
assert(not daw.Visible and daw:GetAttribute("Playing") == false, "close did not hide/stop")
assert(cam.CameraType == Enum.CameraType.Custom and PPS.Enabled == true and GuiService.TouchControlsEnabled == true, "close did not restore camera/prompts/touch controls")
assert(waitFor(function() return hum.SeatPart == nil end, 2), "still seated after close")
assert(next(CAS:GetBoundActionInfo("OK_DAW_PlayStop")) == nil, "play action still bound after close")
table.insert(out, "close: window hidden, playback stopped, camera/prompts/touch restored, stood up, actions unbound")
-- 9) reopen and leave it open + playing for the respawn test (t10b kills on the server, t10c checks)
cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(root.Position + Vector3.new(-4, 3, 0), screen.Position); task.wait(1.0)
for i = 1, 4 do prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); task.wait(0.8); if daw.Visible then break end end
assert(daw.Visible, "could not reopen")
assert(daw:GetAttribute("Pattern") == draftPat and daw:GetAttribute("Status"):find("Unsaved"), "the unsaved beat was not kept across close/reopen")
daw:SetAttribute("Command", "play"); task.wait(0.3)
table.insert(out, "reopened with the unsaved beat kept, playing (for the respawn test)")
return "T10 PLAY OK\n" .. table.concat(out, "\n")
