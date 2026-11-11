-- Client, during play: the piano roll (KEYS view). Notes place/remove, chords cap at 3, the scale lock picks the rows,
-- a placed note auditions the voice repitched, notes play in time and hold for their length, CLEAR empties only the
-- lane you are in, a save keeps the keys lane, bad lanes and an unowned voice are refused, phone layout keeps 44 px.
local Players, RS, SoundService = game:GetService("Players"), game:GetService("ReplicatedStorage"), game:GetService("SoundService")
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart"); local hum = char:WaitForChild("Humanoid"); local cam = workspace.CurrentCamera
local daw = player.PlayerGui:WaitForChild("OK_DAW"):WaitForChild("DAW")
local Cfg = require(RS.OK.Modules.DAWConfig)
daw:SetAttribute("CompactForced", nil); daw:SetAttribute("ViewportOverride", nil)
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
daw:SetAttribute("Command", "stop"); task.wait(0.15)
-- KEYS view swaps the grid for the piano roll
assert(daw.HeaderRow:FindFirstChild("KeysBtn") and daw.HeaderRow.KeysBtn.Text == "KEYS", "KEYS button missing")
daw:SetAttribute("Command", "view:keys"); task.wait(0.25)
assert(daw:GetAttribute("View") == "keys" and daw.Roll.Visible and not daw.Grid.Visible and daw.HeaderRow.KeysBtn.Text == "DRUMS", "KEYS view did not open")
local function visibleKeys() local n = 0; for _, c in ipairs(daw.Roll.Rows:GetChildren()) do if c:IsA("TextButton") and c.Name:match("^Key") and c.Visible then n += 1 end end; return n end
assert(visibleKeys() == 11, "minor pentatonic should show 11 rows, got " .. visibleKeys())
-- placing a note auditions the voice, repitched
local box = Cfg.Voices[1]
daw:SetAttribute("Pattern", Cfg.DefaultPattern); daw:SetAttribute("BPM", 120); task.wait(0.1)
local heard = {}
local conn = SoundService.ChildAdded:Connect(function(c) if c:IsA("Sound") and Cfg.VoiceById(c.Name) then table.insert(heard, { id = c.Name, speed = c.PlaybackSpeed, sid = c.SoundId }) end end)
local h0 = daw:GetAttribute("Hits")
daw:SetAttribute("Command", "note:1:7:2"); task.wait(0.3)
conn:Disconnect()
local keys = Cfg.KeysSeg(daw:GetAttribute("Pattern"))
assert(keys:sub(1, 16) == Cfg.NoteChar(7) .. "-00000000000000", "note not placed: " .. keys:sub(1, 16))
assert(daw:GetAttribute("Hits") == h0 + 1 and #heard == 1 and heard[1].id == box.id and heard[1].sid == box.SoundId, "placing a note did not audition the voice")
assert(math.abs(heard[1].speed - 2 ^ ((7 + box.Tune) / 12)) < 0.001, "audition not repitched: " .. heard[1].speed)
table.insert(out, string.format("KEYS view: 11 rows (minor pent); a placed note auditions %s at speed %.3f", box.name, heard[1].speed))
-- chords: up to 3 notes on one step; unnote removes
daw:SetAttribute("Command", "note:1:0:1"); task.wait(0.1); daw:SetAttribute("Command", "note:1:3:1"); task.wait(0.1)
daw:SetAttribute("Status", ""); daw:SetAttribute("Command", "note:1:10:1"); task.wait(0.15)
assert(#Cfg.Notes(daw:GetAttribute("Pattern")) == 3 and daw:GetAttribute("Status"):find("3 notes max"), "4th note at a step was not refused")
daw:SetAttribute("Command", "unnote:1:0"); task.wait(0.15)
assert(#Cfg.Notes(daw:GetAttribute("Pattern")) == 2 and not Cfg.NoteAt(daw:GetAttribute("Pattern"), 1, 0), "unnote failed")
-- scale lock cycles; ALL NOTES shows 25 rows in a scrolling list; LEN cycles
daw:SetAttribute("Command", "scale"); task.wait(0.25); assert(daw:GetAttribute("Scale") == "majpent" and visibleKeys() == 12, "scale -> major pent (11 rows + the D# row that holds a note): " .. visibleKeys())
for i = 1, 3 do daw:SetAttribute("Command", "scale"); task.wait(0.25) end
assert(daw:GetAttribute("Scale") == "all" and visibleKeys() == 25 and daw.Roll.Rows.CanvasSize.Y.Offset > daw.Roll.Rows.AbsoluteSize.Y, "ALL NOTES should show 25 rows in a scrolling list")
daw:SetAttribute("Command", "scale"); task.wait(0.25); assert(daw:GetAttribute("Scale") == "minpent", "scale wraps")
daw:SetAttribute("Command", "len"); task.wait(0.15); assert(daw:GetAttribute("NoteLen") == 2 and daw.Roll.KeysBar.LenBtn.Text == "LEN 2", "LEN")
daw:SetAttribute("Command", "len"); task.wait(0.15); daw:SetAttribute("Command", "len"); task.wait(0.15); assert(daw:GetAttribute("NoteLen") == 1, "LEN wraps")
table.insert(out, "3-note chord cap, unnote, scale lock 11/11/15/15/25 rows (ALL NOTES scrolls), LEN cycles")
-- notes play in time: 4 two-step notes over a bar at 120 BPM, each held past 0.15 s and gone after its gate
local melody = Cfg.DefaultPattern
for i, s in ipairs({ 1, 5, 9, 13 }) do melody = Cfg.PlaceNote(melody, s, ({ 0, 3, 7, 10 })[i], 2) end
daw:SetAttribute("Pattern", melody); task.wait(0.1)
local clones, lifeOk, lifeMsg = {}, nil, nil
local c2 = SoundService.ChildAdded:Connect(function(c)
  if c:IsA("Sound") and c.Name == box.id then
    table.insert(clones, c)
    if #clones == 1 then
      task.delay(0.15, function() if c.Parent == nil then lifeMsg = "note ended before its length" end end)
      task.delay(0.7, function() lifeOk = c.Parent == nil; if not lifeOk then lifeMsg = "note still playing after its length" end end)
    end
  end
end)
local hits0 = daw:GetAttribute("Hits")
daw:SetAttribute("Command", "play"); task.wait(2.05); daw:SetAttribute("Command", "stop"); c2:Disconnect(); task.wait(0.3)
assert(#clones >= 4, "expected 4+ notes in a bar at 120 BPM, got " .. #clones)
assert(waitFor(function() return lifeOk ~= nil end, 1) and lifeOk and lifeMsg == nil, "note gate: " .. tostring(lifeMsg))
assert(daw:GetAttribute("Hits") - hits0 > #clones, "drums did not play alongside the keys")
table.insert(out, string.format("playback: %d notes in 2 s at 120 BPM with the drums, each held for its 2 steps then gone", #clones))
-- the velocity lane: accent the note on step 5; it plays louder than the others
daw:SetAttribute("Command", "accent:5"); task.wait(0.15)
assert(Cfg.NoteAt(daw:GetAttribute("Pattern"), 5, 3).accent and daw.Roll.Vel.Vel_5.Bar.Size.Y.Scale == 1 and daw.Roll.Vel.Vel_1.Bar.Size.Y.Scale == 0.5, "accent did not land on step 5")
local vols = {}
local c3 = SoundService.ChildAdded:Connect(function(c) if c:IsA("Sound") and c.Name == box.id then table.insert(vols, c.Volume) end end)
daw:SetAttribute("Command", "play"); task.wait(1.1); daw:SetAttribute("Command", "stop"); c3:Disconnect(); task.wait(0.3)
table.sort(vols); assert(#vols >= 2 and vols[#vols] > vols[1] * 1.2, string.format("the accented note should play louder (%.2f vs %.2f)", vols[#vols] or 0, vols[1] or 0))
daw:SetAttribute("Command", "accent:5"); task.wait(0.15); assert(daw:GetAttribute("Pattern") == melody, "accent off should restore the beat")
-- CHORD stamps a triad on an empty cell
daw:SetAttribute("Command", "chord"); task.wait(0.15); assert(daw:GetAttribute("Chord") == true, "CHORD on")
daw:SetAttribute("Command", "stamp:3:0"); task.wait(0.3)
local stamped = 0; for _, n in ipairs(Cfg.Notes(daw:GetAttribute("Pattern"))) do if n.step == 3 then stamped += 1 end end
assert(stamped == 3, "CHORD should place 3 notes, got " .. stamped)
daw:SetAttribute("Command", "chord"); task.wait(0.15); daw:SetAttribute("Pattern", melody); task.wait(0.1)
table.insert(out, "velocity lane: an accent plays louder; CHORD stamps a triad")
-- CLEAR empties only the lane you are in; UNDO restores
daw:SetAttribute("Command", "clear"); task.wait(0.15)
assert(Cfg.Drums(daw:GetAttribute("Pattern")) == Cfg.Drums(melody) and #Cfg.Notes(daw:GetAttribute("Pattern")) == 0, "CLEAR in the keys view should clear the keys only")
daw:SetAttribute("Command", "undo"); task.wait(0.15); assert(daw:GetAttribute("Pattern") == melody, "undo after a keys clear")
daw:SetAttribute("Command", "view:drums"); task.wait(0.25); assert(daw.Grid.Visible and not daw.Roll.Visible, "back to drums")
daw:SetAttribute("Command", "clear"); task.wait(0.15)
assert(Cfg.KeysSeg(daw:GetAttribute("Pattern")) == Cfg.KeysSeg(melody) and Cfg.Hits(Cfg.Drums(daw:GetAttribute("Pattern"))) == 0, "CLEAR in the drums view should keep the keys")
daw:SetAttribute("Command", "undo"); task.wait(0.15); assert(daw:GetAttribute("Pattern") == melody, "undo after a drums clear")
-- a save keeps the keys lane (default voice stored as none); bad lanes and an unowned voice are refused
daw:SetAttribute("Slot", 2); daw:SetAttribute("Pattern", melody); daw:SetAttribute("BPM", 120)
task.wait(3.2); daw:SetAttribute("LastSave", ""); daw:SetAttribute("Command", "save")
assert(waitFor(function() return daw:GetAttribute("LastSave") ~= "" end, 5) and daw:GetAttribute("LastSave") == "ok", "save with keys failed: " .. tostring(daw:GetAttribute("LastSave")))
local prof = RS.OK.Remotes.ProfileFunction:InvokeServer()
assert(prof.daw.slots.s2 and prof.daw.slots.s2.pattern == melody and prof.daw.slots.s2.voice == nil, "slot 2 did not keep the keys lane")
local r = RS.OK.Remotes.DAW_Save:InvokeServer(melody, 120, 0, 2, "studio", "pluck"); assert(r.ok == false and r.reason == "locked", "unowned voice accepted")
local r2 = RS.OK.Remotes.DAW_Save:InvokeServer(Cfg.Drums(melody) .. "-" .. string.rep("0", 47), 120, 0, 2); assert(r2.ok == false and r2.reason == "invalid", "bad keys lane accepted")
local r3 = RS.OK.Remotes.DAW_Save:InvokeServer(Cfg.Drums(melody) .. "m0-" .. string.rep("0", 45), 120, 0, 2); assert(r3.ok == false and r3.reason == "invalid", "stray tie accepted")
assert(daw:GetAttribute("Voices") == box.id, "voices owned: " .. tostring(daw:GetAttribute("Voices")))
daw:SetAttribute("Status", ""); daw:SetAttribute("Command", "voice"); task.wait(0.15)
assert(daw:GetAttribute("Voice") == box.id and daw:GetAttribute("Status"):find("gear rack"), "VOICE without gear should point to the rack")
table.insert(out, "CLEAR per lane with UNDO; save keeps the keys lane; bad lanes and an unowned voice refused; VOICE points to the rack")
-- phone layout in the KEYS view: every control and note cell at least 44 px, the scrolling rows inside the window
daw:SetAttribute("Command", "view:keys"); task.wait(0.25)
for _, size in ipairs({ Vector2.new(844, 390), Vector2.new(667, 375) }) do
  daw:SetAttribute("ViewportOverride", size); daw:SetAttribute("CompactForced", true); task.wait(0.3)
  local small, outside = {}, {}
  local rx0, ry0 = daw.AbsolutePosition.X, daw.AbsolutePosition.Y
  local rx1, ry1 = rx0 + daw.AbsoluteSize.X, ry0 + daw.AbsoluteSize.Y
  for _, b in ipairs(daw:GetDescendants()) do
    if b:IsA("GuiButton") and b.Visible and b.Name ~= "ModalCatcher" then
      local vis, scroller = true, nil
      local n = b.Parent
      while n and n ~= daw do if n:IsA("GuiObject") and not n.Visible then vis = false end; if n:IsA("ScrollingFrame") then scroller = n end; n = n.Parent end
      if vis then
        if not b.Name:match("^Label%d") and (b.AbsoluteSize.X < 44 or b.AbsoluteSize.Y < 44) then table.insert(small, string.format("%s %dx%d", b.Name, b.AbsoluteSize.X, b.AbsoluteSize.Y)) end
        local box2 = scroller or b
        local x0, y0 = box2.AbsolutePosition.X, box2.AbsolutePosition.Y
        if not (x0 >= rx0 - 1 and y0 >= ry0 - 1 and x0 + box2.AbsoluteSize.X <= rx1 + 1 and y0 + box2.AbsoluteSize.Y <= ry1 + 1) then table.insert(outside, box2.Name) end
      end
    end
  end
  assert(#small == 0, string.format("at %dx%d these are under 44 px: %s", size.X, size.Y, table.concat(small, ", ")))
  assert(#outside == 0, string.format("at %dx%d outside the window: %s", size.X, size.Y, table.concat(outside, ", ")))
  assert(daw.Roll.Visible and daw.Roll.Rows.AbsoluteSize.Y >= 44 and daw.Roll.Rows.CanvasSize.Y.Offset > daw.Roll.Rows.AbsoluteSize.Y, "rows should scroll on a phone")
  table.insert(out, string.format("phone layout %dx%d (keys): controls and note cells >= 44 px, rows scroll inside the window", size.X, size.Y))
end
daw:SetAttribute("CompactForced", nil); daw:SetAttribute("ViewportOverride", nil); daw:SetAttribute("Page", 1); daw:SetAttribute("Command", "view:drums"); task.wait(0.25)
daw:SetAttribute("Command", "close"); task.wait(0.4); cam.CameraType = Enum.CameraType.Custom
return "T30 PLAY OK\n" .. table.concat(out, "\n")
