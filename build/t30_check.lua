-- Edit: beat format v3, the keys lane (piano roll). Config helpers (place / stack to 3 / clamp / resize / remove / notes),
-- lane validation and old-beat upgrades on the server, grader asks for melodies, voices on the rack and in Samples.Voices,
-- the monitors carry the voice, SAMPLE IT keeps the keys, and the KEYS view builds, lays out and takes the gesture.
local RS = game:GetService("ReplicatedStorage")
local OK = RS.OK
local function freshRequire(mod) local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name; local ok, r = pcall(require, c); c:Destroy(); if not ok then error(r) end; return r end
local Cfg = freshRequire(OK.Modules.DAWConfig)
local Config = freshRequire(OK.Config)
local Check = freshRequire(OK.Modules.BriefCheck)
local DR = freshRequire(OK.Modules.DailyRequests)
local DAW = freshRequire(OK.Systems.DAW); DAW._SetConfigForTest(Cfg, Check)
local F = freshRequire(OK.Systems.Flips); F._SetConfigForTest(Cfg, Check)
local out = {}
-- shape and upgrades
assert(Cfg.Version == 3 and Cfg.Length == 128 and Cfg.KeysOffset == 80 and Cfg.Keys.Voices == 3 and #Cfg.DefaultPattern == 128, "v3 shape")
for _, p in ipairs(Cfg.Presets) do assert(#p.pattern == 128, "preset length " .. p.name) end
assert(Cfg.Upgrade(string.rep("1", 64)) == string.rep("1", 64) .. string.rep("0", 64) and #Cfg.Upgrade(string.rep("0", 80)) == 128 and Cfg.Upgrade(Cfg.DefaultPattern) == Cfg.DefaultPattern, "Upgrade")
assert(#Cfg.ScaleRows("minpent") == 11 and #Cfg.ScaleRows("major") == 15 and #Cfg.ScaleRows("all") == 25 and Cfg.ScaleRows("all")[1] == 12 and Cfg.ScaleRows("minpent")[11] == -12, "scale rows")
assert(Cfg.NoteName(0) == "C5" and Cfg.NoteName(-12) == "C4" and Cfg.NoteName(3) == "D#5" and Cfg.NoteName(-1) == "B4" and Cfg.NoteName(12) == "C6", "note names")
-- accents are uppercase letters of the same pitch
assert(Cfg.NoteChar(0, true) == "M" and Cfg.NoteChar(3) == "p" and Cfg.Semitones("M") == 0 and Cfg.Semitones("P") == 3 and Cfg.Accent("M") and not Cfg.Accent("m"), "accent letters")
-- the chord stamp: 1-3-5 by scale degree (pentatonics borrow the parent 7-note scale), a major triad off-scale, clipped to the lane
local function same(a, b) if #a ~= #b then return false end; for i = 1, #a do if a[i] ~= b[i] then return false end end; return true end
assert(same(Cfg.ChordNotes("minpent", 0), { 0, 3, 7 }) and same(Cfg.ChordNotes("minpent", 3), { 3, 7, 10 }) and same(Cfg.ChordNotes("minpent", -5), { -5, -2, 2 }), "minor triads by degree")
assert(same(Cfg.ChordNotes("majpent", 0), { 0, 4, 7 }) and same(Cfg.ChordNotes("major", 2), { 2, 5, 9 }) and same(Cfg.ChordNotes("all", 0), { 0, 4, 7 }) and same(Cfg.ChordNotes("minpent", 1), { 1, 5, 8 }), "major / diatonic / off-scale triads")
assert(same(Cfg.ChordNotes("minpent", 10), { 10 }) and same(Cfg.ChordNotes("minpent", 7), { 7, 10 }), "chord notes above the lane are dropped")
table.insert(out, "v3: 128 chars, 2-octave lane, 5 scales")
-- notes
local Z = string.rep("0", 128)
local p1, n1 = Cfg.PlaceNote(Z, 1, 0, 4); assert(p1 and n1.voice == 1 and n1.len == 4 and Cfg.KeysSeg(p1):sub(1, 16) == "m---000000000000", "place a 4-step note")
local p2, n2 = Cfg.PlaceNote(p1, 2, 7, 1); assert(p2 and n2.voice == 2, "a note under a held note takes the next voice")
local p3, n3 = Cfg.PlaceNote(p2, 2, 3, 2); assert(p3 and n3.voice == 3, "third voice")
local p4, why = Cfg.PlaceNote(p3, 2, 10, 1); assert(p4 == nil and why == "full", "a 4th note at one step was accepted")
local _, whyR = Cfg.PlaceNote(p3, 1, 13, 1); assert(whyR == "range", "out-of-range note accepted")
local _, whyS = Cfg.PlaceNote(p3, 17, 0, 1); assert(whyS == "range", "step 17 accepted")
local p5, n5 = Cfg.PlaceNote(Z, 15, -5, 4); assert(p5 and n5.len == 2, "length not clamped at the bar end")
local notes = Cfg.Notes(p3); assert(#notes == 3 and notes[1].step == 1 and notes[2].semi == 3 and notes[3].semi == 7, "Notes order")
assert(Cfg.NoteAt(p3, 3, 0) and Cfg.NoteAt(p3, 3, 0).step == 1 and not Cfg.NoteAt(p3, 5, 0) and not Cfg.NoteAt(p3, 3, 7), "NoteAt")
local p6, n6 = Cfg.ResizeNote(p3, n1, 8); assert(n6.len == 8 and Cfg.KeysSeg(p6):sub(1, 16) == "m-------00000000", "resize longer")
local p7, n7 = Cfg.ResizeNote(p6, n6, 1); assert(n7.len == 1 and Cfg.KeysSeg(p7):sub(1, 16) == "m000000000000000", "resize to 1")
local pA = Cfg.PlaceNote(Z, 1, 0, 1); local pB = Cfg.PlaceNote(pA, 4, 5, 1)
local _, nC = Cfg.ResizeNote(pB, Cfg.NoteAt(pB, 1, 0), 8); assert(nC.len == 3, "a resize ran into the note on step 4: " .. nC.len)
-- one voice per pitch at a time: placing on a sounding note is "taken"; a note or a stretch stops before the next note of its pitch
local _, whyT = Cfg.PlaceNote(p1, 2, 0, 1); assert(whyT == "taken", "the same pitch under a held note was accepted: " .. tostring(whyT))
local pX = Cfg.PlaceNote(Z, 5, 0, 1); local pY, nY = Cfg.PlaceNote(pX, 1, 0, 8); assert(pY and nY.voice == 2 and nY.len == 4, "a note ran into the next note of its pitch in another voice")
local _, nR = Cfg.ResizeNote(pY, nY, 8); assert(nR.len == 4, "a stretch ran into the next note of its pitch in another voice: " .. nR.len)
local twice = "m" .. string.rep("0", 15) .. "m" .. string.rep("0", 15) .. string.rep("0", 16)
local under = "m---" .. string.rep("0", 12) .. "0m" .. string.rep("0", 14) .. string.rep("0", 16)
assert(not Cfg.KeysValid(twice) and not Cfg.KeysValid(under) and Cfg.KeysValid("m" .. string.rep("0", 15) .. "p" .. string.rep("0", 15) .. string.rep("0", 16)), "the same pitch in two voices at once was accepted")
local twiceAcc = "M" .. string.rep("0", 15) .. "m" .. string.rep("0", 15) .. string.rep("0", 16)
assert(not Cfg.KeysValid(twiceAcc) and Cfg.KeysValid("M---" .. string.rep("0", 12) .. string.rep("0", 32)) and not Cfg.KeysValid("Z" .. string.rep("0", 47)), "accent validation")
assert(DAW.Validate(Cfg.Drums(Z) .. "M---" .. string.rep("0", 12) .. string.rep("0", 32), 140, 0) and not DAW.Validate(Cfg.Drums(Z) .. twiceAcc, 140, 0), "the server must take accents and refuse an accented duplicate")
assert(not DAW.Validate(Cfg.Drums(Z) .. twice, 140, 0) and not DAW.Validate(Cfg.Drums(Z) .. under, 140, 0), "the server accepted the same pitch in two voices")
assert(Cfg.RemoveNote(p1, n1) == Z and #Cfg.Notes(Z) == 0 and #Cfg.Notes(string.rep("0", 80)) == 0, "remove / empty")
-- accents round-trip through place / resize / notes; SetAccent flips the head letter only
local pAcc, nAcc = Cfg.PlaceNote(Z, 3, 7, 2, true); assert(nAcc.accent and Cfg.KeysSeg(pAcc):sub(3, 4) == "T-" and Cfg.Notes(pAcc)[1].accent, "accented place")
local pAcc2, nAcc2 = Cfg.ResizeNote(pAcc, nAcc, 4); assert(nAcc2.accent and Cfg.KeysSeg(pAcc2):sub(3, 6) == "T---", "resize keeps the accent")
local pAcc3, nAcc3 = Cfg.SetAccent(pAcc2, nAcc2, false); assert(not nAcc3.accent and Cfg.KeysSeg(pAcc3):sub(3, 6) == "t---" and Cfg.Hits(pAcc3) == 1, "SetAccent off")
-- MoveNote keeps length and accent, and stays put when the target has no room
local pM, nM = Cfg.MoveNote(pAcc2, nAcc2, 9, -3); assert(nM.step == 9 and nM.semi == -3 and nM.len == 4 and nM.accent and Cfg.KeysSeg(pM):sub(9, 12) == "J---" and Cfg.KeysSeg(pM):sub(3, 6) == "0000", "MoveNote")
local blockP = Cfg.PlaceNote(pM, 14, -3, 1); assert(blockP, "blocker placed")
local pM2, nM2 = Cfg.MoveNote(blockP, Cfg.NoteAt(blockP, 9, -3), 11, -3); assert(pM2 == blockP and nM2.step == 9, "a move that would shrink the note must not happen")
local pM4, nM4 = Cfg.MoveNote(blockP, Cfg.NoteAt(blockP, 9, -3), 10, -3); assert(nM4.step == 10 and nM4.len == 4 and Cfg.NoteAt(pM4, 14, -3), "a move that fits before the next note of its pitch happens")
local pM3, nM3 = Cfg.MoveNote(blockP, Cfg.NoteAt(blockP, 9, -3), 15, -3); assert(pM3 == blockP and nM3.step == 9, "a move past the bar end must not happen")
assert(Cfg.Hits(p1) == 1 and Cfg.Hits(p3) == 3 and Cfg.Hits(Cfg.DefaultPattern) == select(2, Cfg.DefaultPattern:gsub("1", "")), "Hits counts notes, not ties")
assert(Cfg.KeysValid(Cfg.KeysSeg(p6)) and Cfg.KeysValid(string.rep("0", 48)), "legal lanes refused")
for _, bad in ipairs({ "-" .. string.rep("0", 47), "m0-" .. string.rep("0", 45), "z" .. string.rep("0", 47), string.rep("0", 47), string.rep("0", 49) }) do assert(not Cfg.KeysValid(bad), "bad lane accepted: " .. bad:sub(1, 4)) end
table.insert(out, "notes place/stack to 3/clamp/resize/remove; lane validation")
-- server validation: v3 accepted, v1/v2 upgraded, bad lanes refused; the first voice is free
assert(DAW.Validate(p3, 140, 0), "v3 beat refused")
local up = DAW.Validate(string.rep("0", 64) .. "m000000000000000", 140, 0); assert(up and #up == 128 and up:sub(65, 65) == "m", "v2 beat not upgraded")
assert(#DAW.Validate(string.rep("1", 64), 140, 0) == 128, "v1 beat not upgraded")
assert(not DAW.Validate(Cfg.Drums(Z) .. "-" .. string.rep("0", 47), 140, 0) and not DAW.Validate(Z .. "0", 140, 0) and not DAW.Validate(Cfg.Drums(Z) .. "m0-" .. string.rep("0", 45), 140, 0), "bad keys lane accepted")
assert(DAW.VoiceFor({}, nil) == Cfg.Voices[1].id and DAW.VoiceFor({}, Cfg.Voices[1].id) == Cfg.Voices[1].id and DAW.VoiceFor({}, 5) == nil and DAW.VoiceFor({}, "nope") == nil, "VoiceFor")
-- grader asks
local f = Cfg.DefaultPattern
f = Cfg.PlaceNote(f, 1, 0, 2); f = Cfg.PlaceNote(f, 5, 3, 1); f = Cfg.PlaceNote(f, 9, 7, 1); f = Cfg.PlaceNote(f, 9, 0, 1)
local function ask(a, p) return Check.Ask(Cfg, a, p, 140, 0) end
assert(ask({ k = "melody", n = 4 }, f) and not ask({ k = "melody", n = 5 }, f) and ask({ k = "melnotes", n = 3 }, f) and not ask({ k = "melnotes", n = 4 }, f) and ask({ k = "chord" }, f), "keys asks wrong")
assert(not ask({ k = "melody", n = 1 }, Cfg.DefaultPattern) and not ask({ k = "chord" }, Cfg.DefaultPattern) and not ask({ k = "melody", n = 1 }, string.rep("0", 80)), "keys asks on beats without notes")
local held = Cfg.PlaceNote(Cfg.PlaceNote(Cfg.DefaultPattern, 1, 0, 4), 2, 7, 1); assert(ask({ k = "chord" }, held), "a note starting under a held note is a chord")
assert(not ask({ k = "chord" }, Cfg.PlaceNote(Cfg.PlaceNote(Cfg.DefaultPattern, 1, 0, 1), 2, 7, 1)), "two notes that never overlap are not a chord")
for _, a in ipairs({ { k = "melody", n = 4 }, { k = "melnotes", n = 3 }, { k = "chord" } }) do assert(Check.Text(a) ~= "?" and Check.Needs(a) == nil, "keys ask text/needs") end
local A = freshRequire(OK.Data.Artists)
assert(A.BriefById.j2.bonus.k == "melody" and A.BriefById.r2.bonus.k == "melnotes", "briefs with keys bonuses")
assert(#DR.Templates == 9 and DR.Templates[9].asks[3].k == "melody" and #DR.WeeklyTemplates == 7 and DR.WeeklyTemplates[7].bonus.k == "chord" and #DR.ForDay(20261022) == 3, "daily/weekly keys templates")
-- templates added later are gated by date: days and weeks already generated keep their asks
assert(DR.TemplateCount(20261022) == 8 and DR.TemplateCount(20261023) == 9 and DR.WeeklyCount(2964) == 6 and DR.WeeklyCount(2965) == 7, "template date gates")
for _, b in ipairs(DR.ForDay(20261022)) do assert(b.template <= 8, "a pre-gate day got the keys template") end
assert(DR.ForWeek(2964).template <= 6 and DR.ForWeek(2970).template == 2970 % 7 + 1, "weekly gate")
-- older, shorter beats still count as references: a v2 airing vs its v3 upgrade differs by 0 pads, and by its notes only
-- a held note is one pad: ties never count, so stretching a sampled note cannot make it "yours"
assert(Check.Diff(Cfg.Drums(f), f) == #Cfg.Notes(f) and Check.Diff(f, Cfg.Drums(f)) == 4 and Check.Diff(string.rep("0", 64), Z) == 0, "Diff across formats")
local stretched = Cfg.ResizeNote(f, Cfg.NoteAt(f, 1, 0), 9); assert(Check.Diff(f, stretched) == 0, "a stretch counted as changed pads: " .. Check.Diff(f, stretched))
local allAcc = f; for _, n in ipairs(Cfg.Notes(f)) do allAcc = Cfg.SetAccent(allAcc, n, true) end
assert(Check.Diff(f, allAcc) == 0 and Check.Changed(allAcc, { f }) == 0, "accents counted as changed pads (one velocity-lane swipe would make a copy 'yours')")
assert(Check.Changed(Cfg.Drums(Cfg.DefaultPattern), { Cfg.DefaultPattern }) == 0 and DAW.CellsDiffer(Cfg.Drums(Cfg.DefaultPattern), Cfg.DefaultPattern) == 0, "a v2 copy of the default beat must count as unchanged")
local maya = "1001001001001000" .. "0000100100001000" .. "0010000000100000" .. "1111000011110000" .. string.rep("0", 16) -- a distinctive 80-char airing (test hook / old server)
local hist = { { token = 1, uid = 100, name = "Maya", pattern = maya } }
local _, whyCopy = F.Judge(hist, 200, Cfg.Upgrade(maya), nil); assert(whyCopy == "copy", "a v3 copy of a v2 airing slipped past the copy check: " .. tostring(whyCopy))
assert(F.Judge(hist, 200, Cfg.Upgrade(Cfg.Drums(Cfg.DefaultPattern)), nil) == nil and select(2, F.Judge(hist, 200, Cfg.Upgrade(Cfg.Drums(Cfg.DefaultPattern)), nil)) == nil, "the default beat is never a copy")
-- SAMPLE IT keeps the keys lane even without gear
assert(Cfg.KeysSeg(F.Sampled(f, function() return false end)) == Cfg.KeysSeg(f) and #F.Sampled(f, function() return false end) == 128, "SAMPLE IT lost the keys lane")
table.insert(out, "server upgrades v1/v2 beats and refuses bad lanes; melody/melnotes/chord asks grade; samples keep keys")
-- voices: rack items, sample folder, licensed source noted
local gear = {}; for _, it in ipairs(Config.Gear) do gear[it.id] = it end
local vf = OK.Samples:FindFirstChild("Voices"); assert(vf, "Samples.Voices missing (run build/10_daw.lua)")
for i, v in ipairs(Cfg.Voices) do
  if i == 1 then assert(v.gear == nil, "the first voice must be free") else local g = gear[v.gear]; assert(g and g.kind == "voice" and g.voice == v.id and g.price > 0, "voice " .. v.id .. " has no rack item") end
  local s = vf:FindFirstChild(v.id); assert(s and s:IsA("Sound") and s.SoundId == v.SoundId, "voice sample " .. v.id .. " missing or stale")
  assert(type(v.Tune) == "number" and v.Source:find("Roblox licensed"), "voice " .. v.id .. " tune/source")
end
assert(Config.Gear[#Config.Gear].id == "plate_legend", "the top-tier item must stay last")
-- the monitors carry the voice (pure service with an injected clock)
local MS = freshRequire(game:GetService("ServerScriptService").OK.Services.MonitorService)
local np = Instance.new("Folder"); local t = 0
local svc = MS.new({ np = np, now = function() return t end, delay = function() end })
local r = svc:Enqueue({ UserId = 1, DisplayName = "A" }, f, 140, 0, nil, "studio", "pluck")
assert(r.ok and r.position == 0 and np:GetAttribute("Voice") == "pluck" and np:GetAttribute("Beat") == f, "voice not on NowPlaying")
svc:Cancel(1); t = 10
svc:EnqueueSystem({ UserId = -5, DisplayName = "ENTRY A" }, f, 140, 0, "studio", 1, 9, "Real", "chime")
assert(np:GetAttribute("Voice") == "chime" and np:GetAttribute("System") == true, "cypher entry voice not on NowPlaying")
table.insert(out, #Cfg.Voices .. " voices: first free, others on the rack, samples in Samples.Voices; NowPlaying.Voice set")
-- the KEYS view: builds, swaps the grid, scale lock rows, gesture, per-lane CLEAR
local Theme = freshRequire(OK.Modules.UITheme)
local UI = freshRequire(OK.Modules.DAWUI)
local gui = Instance.new("ScreenGui")
local ui = UI.Build(gui, Theme, Cfg, freshRequire(OK.Modules.PianoRoll))
local d = ui.Root
assert(d:GetAttribute("View") == "drums" and #d:GetAttribute("Pattern") == 128 and d:FindFirstChild("Roll") and d.HeaderRow:FindFirstChild("KeysBtn") and d.Roll.KeysBar:FindFirstChild("VoiceBtn") and d.Roll.KeysBar:FindFirstChild("ChordBtn") and d.Roll:FindFirstChild("Vel") and d.Roll.Rows:FindFirstChild("Playhead"), "piano roll not built")
local function visibleKeys() local n = 0; for _, c in ipairs(d.Roll.Rows:GetChildren()) do if c:IsA("TextButton") and c.Name:match("^Key") and c.Visible then n += 1 end end; return n end
ui.SetView("keys"); ui.Layout()
assert(d.Roll.Visible and not d.Grid.Visible and visibleKeys() == 11, "KEYS view: rows " .. visibleKeys())
d:SetAttribute("Scale", "all"); ui.Layout(); assert(visibleKeys() == 25 and d.Roll.Rows.CanvasSize.Y.Offset >= 25 * 18, "ALL NOTES rows")
d:SetAttribute("Scale", "minpent"); ui.Layout()
d:SetAttribute("Pattern", Cfg.DefaultPattern)
assert(ui.Roll.BeginAt(1, 0), "press on an empty cell should place a note"); ui.Roll.DragTo(1); ui.Roll.DragTo(6); ui.Roll.End()
local n = Cfg.NoteAt(d:GetAttribute("Pattern"), 1, 0); assert(n and n.len == 6, "drag did not stretch the note to 6 steps")
ui.Roll.BeginAt(3, 0); ui.Roll.End(); assert(not Cfg.NoteAt(d:GetAttribute("Pattern"), 1, 0), "a tap on a note (its tail) should remove it")
ui.Roll.BeginAt(2, 7); ui.Roll.DragTo(2); ui.Roll.End(); assert(Cfg.NoteAt(d:GetAttribute("Pattern"), 2, 7).len == 1, "a press-release on an empty cell keeps the new note")
-- a vertical swipe (phone scrolling) neither leaves a note behind nor removes the note it started on; a drag along the row still stretches
local before = d:GetAttribute("Pattern")
assert(ui.Roll.BeginAt(6, 0, Vector2.new(ui.Roll.StepX(6), 100), nil, true), "press for the swipe"); ui.Roll.MoveTo(Vector2.new(ui.Roll.StepX(6), 130)); ui.Roll.End()
assert(d:GetAttribute("Pattern") == before, "a scroll swipe left a note behind")
ui.Roll.BeginAt(2, 7, Vector2.new(ui.Roll.StepX(2), 100), nil, true); ui.Roll.MoveTo(Vector2.new(ui.Roll.StepX(2), 140)); ui.Roll.End()
assert(Cfg.NoteAt(d:GetAttribute("Pattern"), 2, 7), "a scroll swipe removed the note it started on")
-- FL-style editing: the last cell stretches, the body moves (a finger moves in time only, a mouse in pitch too)
ui.Roll.BeginAt(2, 7, Vector2.new(ui.Roll.StepX(2), 100), "resize"); ui.Roll.MoveTo(Vector2.new(ui.Roll.StepX(5), 104)); ui.Roll.End()
assert(Cfg.NoteAt(d:GetAttribute("Pattern"), 2, 7).len == 4, "a drag from the end should stretch to 4 steps")
ui.Roll.BeginAt(3, 7, Vector2.new(ui.Roll.StepX(3), 100), nil, true); ui.Roll.MoveTo(Vector2.new(ui.Roll.StepX(5), 102)); ui.Roll.End()
local moved = Cfg.NoteAt(d:GetAttribute("Pattern"), 4, 7); assert(moved and moved.step == 4 and moved.len == 4 and not Cfg.NoteAt(d:GetAttribute("Pattern"), 2, 7), "a finger drag on the body should move the note 2 steps right, keeping its length")
ui.Roll.BeginAt(5, 7, Vector2.new(ui.Roll.StepX(5), ui.Roll.RowY(7))); ui.Roll.MoveTo(Vector2.new(ui.Roll.StepX(3), ui.Roll.RowY(3))); ui.Roll.End()
local moved2 = Cfg.NoteAt(d:GetAttribute("Pattern"), 2, 3); assert(moved2 and moved2.step == 2 and moved2.len == 4 and not Cfg.NoteAt(d:GetAttribute("Pattern"), 4, 7), "a mouse drag should move the note to step 2 on D#5")
ui.Roll.BeginAt(2, 3, Vector2.new(ui.Roll.StepX(2), ui.Roll.RowY(3))); ui.Roll.MoveTo(Vector2.new(ui.Roll.StepX(1), ui.Roll.RowY(7))); ui.Roll.End()
assert(Cfg.NoteAt(d:GetAttribute("Pattern"), 1, 7) and Cfg.NoteAt(d:GetAttribute("Pattern"), 1, 7).len == 4, "move back up to G5 on step 1")
ui.Roll.BeginAt(4, 7, Vector2.new(ui.Roll.StepX(4), 100), "resize"); ui.Roll.MoveTo(Vector2.new(ui.Roll.StepX(2), 100)); ui.Roll.End()
ui.Roll.BeginAt(1, 7, Vector2.new(ui.Roll.StepX(1), 100)); ui.Roll.MoveTo(Vector2.new(ui.Roll.StepX(2), 100)); ui.Roll.End()
local back = Cfg.NoteAt(d:GetAttribute("Pattern"), 2, 7); assert(back and back.step == 2 and back.len == 2 and not Cfg.NoteAt(d:GetAttribute("Pattern"), 1, 7), "shrink to 2 then move to step 2")
ui.Roll.BeginAt(3, 7, Vector2.new(ui.Roll.StepX(3), 100), "resize"); ui.Roll.MoveTo(Vector2.new(ui.Roll.StepX(2), 100)); ui.Roll.End()
assert(Cfg.NoteAt(d:GetAttribute("Pattern"), 2, 7).len == 1, "shrink back to one step")
-- the velocity lane: a press toggles the accents of the notes starting on that step; accents play louder
assert(ui.Roll.ToggleAccent(2) == true, "accent on"); ui.Layout()
assert(Cfg.NoteAt(d:GetAttribute("Pattern"), 2, 7).accent and d.Roll.Vel.Vel_2.Bar.Size.Y.Scale == 1 and d.Roll.Vel.Vel_2.Bar.BackgroundColor3 == ui.Roll.AccentColor, "accent on: bar")
assert(ui.Roll.ToggleAccent(2) == false, "accent off"); ui.Layout()
assert(not Cfg.NoteAt(d:GetAttribute("Pattern"), 2, 7).accent and d.Roll.Vel.Vel_2.Bar.Size.Y.Scale == 0.5, "accent off: bar")
-- CHORD: a press on an empty cell stamps a triad from the scale
ui.Roll.ToggleChord(); ui.Layout(); assert(d:GetAttribute("Chord") == true and d.Roll.KeysBar.ChordBtn.Text == "CHORD ON", "chord mode")
assert(ui.Roll.BeginAt(9, 0, Vector2.new(ui.Roll.StepX(9), 100)) == false, "a chord stamp holds no grab"); ui.Roll.End()
local chordNotes = {}; for _, n in ipairs(Cfg.Notes(d:GetAttribute("Pattern"))) do if n.step == 9 then table.insert(chordNotes, n.semi) end end
assert(same(chordNotes, { 0, 3, 7 }), "CHORD should stamp C minor on step 9: " .. table.concat(chordNotes, ","))
ui.Roll.ToggleChord(); assert(d:GetAttribute("Chord") == false, "chord mode off")
for _, sm in ipairs({ 0, 3, 7 }) do ui.Roll.Remove(9, sm) end
-- ghost notes: the 808's notes show through on their row when the cell is empty
local withBass = d:GetAttribute("Pattern"); withBass = withBass:sub(1, 64) .. "m000p00000000000" .. withBass:sub(81)
d:SetAttribute("Pattern", withBass); ui.Layout()
assert(d.Roll.Rows["Note_0_1"].BackgroundColor3 == ui.Roll.GhostColor and d.Roll.Rows["Note_3_5"].BackgroundColor3 == ui.Roll.GhostColor and d.Roll.Rows["Note_0_2"].BackgroundColor3 ~= ui.Roll.GhostColor, "808 ghost notes")
d:SetAttribute("Pattern", withBass:sub(1, 64) .. string.rep("0", 16) .. withBass:sub(81)); ui.Layout()
d:SetAttribute("Status", ""); assert(ui.Roll.Place(2, 7) == nil and d:GetAttribute("Status"):find("already there"), "placing on a sounding note should say it is taken")
-- a note outside the scale lock keeps its row on screen until it is removed
d:SetAttribute("Scale", "all"); ui.Layout(); assert(ui.Roll.Place(8, 2, 1), "place a D")
d:SetAttribute("Scale", "minpent"); ui.Layout(); assert(visibleKeys() == 12, "a row holding a note must stay visible: " .. visibleKeys())
ui.Roll.Remove(8, 2); ui.Layout(); assert(visibleKeys() == 11, "the extra row should go once its note is gone")
ui.Roll.Toggle(2, 0); ui.Roll.Toggle(2, 3); assert(#Cfg.Notes(d:GetAttribute("Pattern")) == 3, "toggle places")
d:SetAttribute("Status", ""); assert(ui.Roll.Place(2, 10) == nil and d:GetAttribute("Status"):find("3 notes max"), "4th note at a step not refused in the UI")
ui.Roll.CycleLen(); assert(d:GetAttribute("NoteLen") == 2, "LEN"); ui.Roll.CycleLen(); ui.Roll.CycleLen(); assert(d:GetAttribute("NoteLen") == 1, "LEN wraps")
d:SetAttribute("Status", ""); ui.Roll.CycleVoice(); assert(d:GetAttribute("Voice") == Cfg.Voices[1].id and d:GetAttribute("Status"):find("gear rack"), "VOICE with one voice")
d:SetAttribute("Voices", "box,pluck"); ui.Roll.CycleVoice(); assert(d:GetAttribute("Voice") == "pluck", "VOICE cycle")
local withNotes = d:GetAttribute("Pattern")
ui.Clear(); assert(Cfg.Drums(d:GetAttribute("Pattern")) == Cfg.Drums(withNotes) and #Cfg.Notes(d:GetAttribute("Pattern")) == 0, "CLEAR in KEYS should clear only the keys")
assert(ui.Undo() and d:GetAttribute("Pattern") == withNotes, "UNDO after a keys clear")
ui.SetView("drums"); ui.Layout(); assert(d.Grid.Visible and not d.Roll.Visible, "back to drums")
ui.Clear(); assert(Cfg.KeysSeg(d:GetAttribute("Pattern")) == Cfg.KeysSeg(withNotes) and Cfg.Hits(Cfg.Drums(d:GetAttribute("Pattern"))) == 0, "CLEAR in DRUMS should keep the keys")
ui.Load(string.rep("0", 80), 120, 0); assert(#d:GetAttribute("Pattern") == 128, "Load should upgrade old beats")
gui:Destroy()
table.insert(out, "KEYS view: 11/25 rows by scale, FL editing (stretch from the end, move the body, tap removes, swipes scroll), accents + velocity lane, chord stamp, 808 ghosts, 3-note cap, LEN/VOICE cycle, per-lane CLEAR")
return "T30 OK: " .. table.concat(out, "; ")
