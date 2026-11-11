-- OK Beat Maker config (beat format v3). Swap a sound by editing one SoundId here, then run build/10_daw.lua.
-- Every SoundId must come from Roblox's licensed partner library (Config.LicensedCreators); t14 checks it.
--
-- A beat is one string of Length characters: the drum tracks (#Tracks * Steps, track-major) followed by the keys lane
-- (Keys.Voices rows of Steps cells, the piano roll), plus bpm and swing.
-- Drum cell values by track kind:
--   "hit"  : "0" off, "1" hit
--   "roll" : "0" off, "1" hit, "2" two hits in the step, "3" three hits (a roll)      -- rolls unlock at Unlocks.Rolls
--   "bass" : "0" off, or a note letter: "m" = root, each letter is one semitone ("p" = +3, "j" = -3)  -- unlocks at Unlocks.Bass
-- Keys cells (v3): "0" rest, a note letter ("m" = the root, "a" = -12 .. "y" = +12 semitones; UPPERCASE = an accent,
--   played louder), or "-" holding the note before it (a note is a letter followed by its ties, inside one voice row).
--   Up to Keys.Voices notes sound at once
--   (chords); one voice per pitch at a time (the same note never sounds twice at once). The keys lane needs no gear;
--   instruments beyond the first (Voices[i].gear) are sold at the rack.
local C = {}
C.Version = 3
C.Steps = 16
C.Slots = 3
C.BPM = { Default = 142, Min = 60, Max = 200, Step = 5 }
C.Swing = { Options = { 0, 25, 50 }, Max = 60 }
C.CloseDistance = 14
C.SaveCooldown = 3
C.XPPerSave = 10
C.Tracks = {
	{ Name = "Kick",  Kind = "hit",  SoundId = "rbxassetid://9043367885", Volume = 0.9,  Gate = 0.9,  Color = Color3.fromRGB(255, 60, 160), Source = "APM PERCUSSIVE NOISE 14-Electronic Kick (APMOfficial, Roblox licensed)" },
	{ Name = "Snare", Kind = "hit",  SoundId = "rbxassetid://1837831619", Volume = 0.55, Gate = 0.6,  Color = Color3.fromRGB(0, 170, 255),  Source = "APM SNARE-Distorted Snare 02 (APMOfficial, Roblox licensed)" },
	{ Name = "Clap",  Kind = "hit",  SoundId = "rbxassetid://9114762817", Volume = 0.7,  Gate = 0.5,  Color = Color3.fromRGB(225, 200, 140), Source = "Hand Clap Single Hits 7 (ProSoundEffects, Roblox licensed)" },
	{ Name = "Hat",   Kind = "roll", SoundId = "rbxassetid://9116847963", Volume = 0.5,  Gate = 0.12, Color = Color3.fromRGB(0, 255, 140),  Source = "Metal Spice Shaker 1 (ProSoundEffects, Roblox licensed), cut to 0.12 s" },
	{ Name = "808",   Kind = "bass", SoundId = "rbxassetid://1837830050", Volume = 0.8,  Gate = 0.7,  Color = Color3.fromRGB(170, 90, 255), Source = "APM BOOM-Sub Boom 01 (APMOfficial, Roblox licensed), pitched per note" },
}
-- notes a tap cycles through on the 808 row (semitones from the root), shown on the pad
C.BassCycle = { 0, 3, 5, 7, -2 }
C.Unlocks = { Bass = 2, Rolls = 3, Swing = 4 }

-- the keys lane (piano roll) ---------------------------------------------------------------------------------------
C.Keys = {
	Voices = 3,          -- notes that can sound at once
	Range = 12,          -- semitones either side of the root: two octaves
	Lens = { 1, 2, 4 },  -- note lengths (steps) the LEN button cycles through
	Release = 0.08,      -- seconds of fade when a note ends (no clicks)
	Accent = 1.35,       -- volume multiplier of an accented note (uppercase letter; the velocity lane)
	Color = Color3.fromRGB(122, 214, 108),        -- note bars (FL Studio's green)
	AccentColor = Color3.fromRGB(184, 248, 160),  -- accented note bars
	-- the chord stamp builds 1-3-5 triads by scale degree; pentatonic scales borrow their parent 7-note scale
	ChordParent = { minpent = "minor", majpent = "major" },
	NoteNames = { "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" },
	RootOctave = 5,      -- the root ("m") is shown as C5, so the lane reads C4..C6
	-- scale lock: rows of the piano roll (semitones in the octave). The first is the default.
	Scales = {
		{ id = "minpent", name = "MINOR PENT", steps = { 0, 3, 5, 7, 10 } },
		{ id = "majpent", name = "MAJOR PENT", steps = { 0, 2, 4, 7, 9 } },
		{ id = "minor",   name = "MINOR",      steps = { 0, 2, 3, 5, 7, 8, 10 } },
		{ id = "major",   name = "MAJOR",      steps = { 0, 2, 4, 5, 7, 9, 11 } },
		{ id = "all",     name = "ALL NOTES",  steps = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 } },
	},
}
C.KeysOffset = #C.Tracks * C.Steps                  -- 80: where the keys lane starts
C.Length = C.KeysOffset + C.Keys.Voices * C.Steps   -- 128
local KEYS0 = string.rep("0", C.Length - C.KeysOffset)
-- instruments for the keys lane. One licensed single note each, repitched by PlaybackSpeed (2^(semitones/12)).
-- Tune = semitones (fractions allowed) that move the recording's own pitch onto the root. Measured in Studio with
-- AudioAnalyzer on 2026-10-22: the 808's body sits at 38.1 Hz (D#1 - 36 cents), so the keys root is D#6 - 36 cents, the
-- same pitch class, and the lane reads C4..C6 relative to it. The first voice is free; the others are gear
-- (Config.Gear kind "voice"). Samples live in ReplicatedStorage.OK.Samples.Voices.
C.Voices = {
	{ id = "box",   name = "MUSIC BOX", SoundId = "rbxassetid://9117043141", Volume = 1.6, Tune = 3.6,  Source = "Music Box Swan Lake Single Notes 11 (ProSoundEffects, Roblox licensed), recorded B5" },
	{ id = "pluck", name = "PLUCK",     SoundId = "rbxassetid://9126163252", Volume = 1.4, Tune = 3.6,  gear = "voice_pluck", Source = "Violin String Pluck Single Notes (ProSoundEffects, Roblox licensed), recorded B5" },
	{ id = "chime", name = "CHIME",     SoundId = "rbxassetid://9113133643", Volume = 1.0, Tune = -4.4, gear = "voice_chime", Source = "Anvil Hits Ringing Metal Clinks Blacksmith 8 (ProSoundEffects, Roblox licensed), recorded G6" },
}
function C.VoiceById(id) for _, v in ipairs(C.Voices) do if v.id == id then return v end end; return nil end
function C.ScaleById(id) for _, s in ipairs(C.Keys.Scales) do if s.id == id then return s end end; return nil end
-- piano-roll rows for a scale: semitones from +Range down to -Range that sit in the scale (highest first)
function C.ScaleRows(scaleId)
	local sc = C.ScaleById(scaleId) or C.Keys.Scales[1]
	local inScale = {}
	for _, s in ipairs(sc.steps) do inScale[s] = true end
	local rows = {}
	for semi = C.Keys.Range, -C.Keys.Range, -1 do if inScale[semi % 12] then table.insert(rows, semi) end end
	return rows
end
function C.NoteName(semi) return C.Keys.NoteNames[semi % 12 + 1] .. (C.Keys.RootOctave + math.floor(semi / 12)) end
-- the chord stamp: semitones of a triad built on `semi` from the scale's degrees (a major triad when the row is outside
-- the scale), kept inside the lane's range
function C.ChordNotes(scaleId, semi)
	local sc = C.ScaleById(scaleId) or C.Keys.Scales[1]
	local parent = C.ScaleById(C.Keys.ChordParent[sc.id] or sc.id)
	local steps = (parent and #parent.steps == 7) and parent.steps or nil
	local pc, deg = semi % 12, nil
	if steps then for i, s in ipairs(steps) do if s == pc then deg = i end end end
	local out = { semi }
	if deg then
		for _, up in ipairs({ 2, 4 }) do
			local j = deg + up
			table.insert(out, semi - pc + steps[(j - 1) % 7 + 1] + 12 * math.floor((j - 1) / 7))
		end
	else
		table.insert(out, semi + 4); table.insert(out, semi + 7)
	end
	local kept = {}
	for _, s in ipairs(out) do if math.abs(s) <= C.Keys.Range then table.insert(kept, s) end end
	return kept
end
function C.KeyIdx(voice, step) return C.KeysOffset + (voice - 1) * C.Steps + step end
function C.Drums(p) return p:sub(1, C.KeysOffset) end
function C.KeysSeg(p) return p:sub(C.KeysOffset + 1) end
-- a legal keys lane: Voices rows, each "0" / note letters / ties, a tie only after a note or another tie, and no two
-- rows sounding the same pitch on one step (a crafted lane could otherwise stack one note three times as loud)
function C.KeysValid(seg)
	if type(seg) ~= "string" or #seg ~= C.Keys.Voices * C.Steps then return false end
	local rows = {}
	for v = 1, C.Keys.Voices do
		local row = seg:sub((v - 1) * C.Steps + 1, v * C.Steps)
		if not row:match("^[0a-yA-Y%-]+$") or row:sub(1, 1) == "-" or row:find("0%-") then return false end
		rows[v] = row
	end
	local sounding = {}
	for s = 1, C.Steps do
		local seen = {}
		for v = 1, C.Keys.Voices do
			local ch = rows[v]:sub(s, s)
			if ch == "0" then sounding[v] = nil elseif ch ~= "-" then sounding[v] = ch:lower() end -- an accent is the same pitch
			local cur = sounding[v]
			if cur then
				if seen[cur] then return false end
				seen[cur] = true
			end
		end
	end
	return true
end
-- every note in a beat: { step, semi, len, voice, accent }, by step then pitch (none for a beat without a keys lane)
function C.Notes(p)
	local out = {}
	if type(p) ~= "string" or #p < C.Length then return out end
	for v = 1, C.Keys.Voices do
		local s = 1
		while s <= C.Steps do
			local i = C.KeyIdx(v, s)
			local ch = p:sub(i, i)
			if ch ~= "0" and ch ~= "-" then
				local len = 1
				while s + len <= C.Steps and p:sub(C.KeyIdx(v, s + len), C.KeyIdx(v, s + len)) == "-" do len += 1 end
				table.insert(out, { step = s, semi = C.Semitones(ch), len = len, voice = v, accent = C.Accent(ch) })
				s += len
			else
				s += 1
			end
		end
	end
	table.sort(out, function(a, b) if a.step ~= b.step then return a.step < b.step end; return a.semi < b.semi end)
	return out
end
-- the note sounding at (step, semi), or nil
function C.NoteAt(p, step, semi)
	for _, n in ipairs(C.Notes(p)) do
		if n.semi == semi and step >= n.step and step < n.step + n.len then return n end
	end
	return nil
end
local function setCells(p, voice, step, text)
	local i = C.KeyIdx(voice, step)
	return p:sub(1, i - 1) .. text .. p:sub(i + #text)
end
-- free cells from `step` on in a voice row (0 when that cell is taken)
function C.FreeRun(p, voice, step)
	local n = 0
	for s = step, C.Steps do
		local i = C.KeyIdx(voice, s)
		if p:sub(i, i) == "0" then n += 1 else break end
	end
	return n
end
-- steps a note at (step, semi) may last before it runs into the next note of the same pitch (in any voice)
local function samePitchRoom(p, step, semi)
	local limit = C.Steps + 1
	for _, n in ipairs(C.Notes(p)) do
		if n.semi == semi and n.step > step and n.step < limit then limit = n.step end
	end
	return limit - step
end
-- place a note (len shrinks to the room left in the freest voice and before the next note of that pitch):
-- newPattern, note  or  nil, "full" (Keys.Voices notes there already) | "taken" (that pitch already sounds there) | "range"
function C.PlaceNote(p, step, semi, len, accent)
	if type(p) ~= "string" or #p ~= C.Length or step < 1 or step > C.Steps or math.abs(semi) > C.Keys.Range then return nil, "range" end
	if C.NoteAt(p, step, semi) then return nil, "taken" end
	len = math.clamp(math.floor(len or 1), 1, C.Steps - step + 1)
	local best, bestRun = nil, 0
	for v = 1, C.Keys.Voices do
		local run = C.FreeRun(p, v, step)
		if run > bestRun then best, bestRun = v, run end
	end
	if not best then return nil, "full" end
	len = math.min(len, bestRun, samePitchRoom(p, step, semi))
	local note = { step = step, semi = semi, len = len, voice = best, accent = accent == true }
	return setCells(p, best, step, C.NoteChar(semi, accent) .. string.rep("-", len - 1)), note
end
function C.RemoveNote(p, note) return setCells(p, note.voice, note.step, string.rep("0", note.len)) end
-- a note's new length (1 .. the room left in its row and before the next note of that pitch): newPattern, note
function C.ResizeNote(p, note, len)
	local cleared = C.RemoveNote(p, note)
	len = math.clamp(math.floor(len), 1, math.min(C.FreeRun(cleared, note.voice, note.step), samePitchRoom(cleared, note.step, note.semi)))
	local nn = { step = note.step, semi = note.semi, len = len, voice = note.voice, accent = note.accent }
	return setCells(cleared, note.voice, note.step, C.NoteChar(note.semi, note.accent) .. string.rep("-", len - 1)), nn
end
-- move a note to another step / pitch, keeping its length and accent; if it does not fit there it stays: newPattern, note
function C.MoveNote(p, note, step, semi)
	if step == note.step and semi == note.semi then return p, note end
	local np, nn = C.PlaceNote(C.RemoveNote(p, note), step, semi, note.len, note.accent)
	if not np or nn.len < note.len then return p, note end
	return np, nn
end
-- accent on or off (the velocity lane): newPattern, note
function C.SetAccent(p, note, on)
	local nn = { step = note.step, semi = note.semi, len = note.len, voice = note.voice, accent = on == true }
	return setCells(p, note.voice, note.step, C.NoteChar(note.semi, on)), nn
end
-- hits in a beat: drum hits plus notes (a tie is not a hit)
function C.Hits(p) return select(2, p:gsub("[^0%-]", "")) end

-- track-major: Kick, Snare, Clap, Hat, 808, then the empty keys lane
C.DefaultPattern = "1000001000100000" .. "0000100000001000" .. "0000000000001000" .. "1010101010101010" .. "0000000000000000" .. KEYS0

-- drum kits (gear): a kit swaps the Kick/Snare/Clap/Hat sounds; the 808 is shared. "studio" = the Tracks' own sounds.
-- Every sound comes from Roblox's licensed partner library (t14 checks). Samples live in ReplicatedStorage.OK.Samples.Kits.
C.Kits = {
	{ id = "studio", name = "STUDIO" },
	{ id = "tape", name = "TAPE", gear = "kit_tape", sounds = {
		Kick  = { id = "rbxassetid://9043367506", volume = 0.9 },  -- APM PERCUSSIVE NOISE 07-Kick 04
		Snare = { id = "rbxassetid://1837831620", volume = 0.55 }, -- APM SNARE-Distorted Snare 01
		Clap  = { id = "rbxassetid://9114763105", volume = 0.7 },  -- PSE Hand Clap Single Hits 13
		Hat   = { id = "rbxassetid://9119034326", volume = 0.5 },  -- PSE Shaker Pod South American Instrument 3
	} },
	{ id = "iron", name = "IRON", gear = "kit_iron", sounds = {
		Kick  = { id = "rbxassetid://9043367738", volume = 0.85 }, -- APM PERCUSSIVE NOISE 12-Distorted FX Kick
		Snare = { id = "rbxassetid://9043367891", volume = 0.7 },  -- APM PERCUSSIVE NOISE 15-Stick 01 (rim)
		Clap  = { id = "rbxassetid://9114771792", volume = 0.6 },  -- PSE Hand Slap Claps 3
		Hat   = { id = "rbxassetid://9116848191", volume = 0.5 },  -- PSE Metal Spice Shaker 3
	} },
}
function C.KitById(id) for _, k in ipairs(C.Kits) do if k.id == id then return k end end; return nil end

-- starting points for session requests (level-1 sounds only: no 808, no rolls, no swing). A delivery must change at
-- least BriefCheck.MinChanged pads from each of these, so an untouched preset never counts.
C.Presets = {
	{ name = "DARK",   bpm = 142, pattern = "1000000010100000" .. "0000000010000000" .. "0000000000000000" .. "1011101110111011" .. "0000000000000000" .. KEYS0 },
	{ name = "BOUNCE", bpm = 160, pattern = "1000000110000010" .. "0000100000001000" .. "0000100000001000" .. "1111111011111110" .. "0000000000000000" .. KEYS0 },
	{ name = "SLOW",   bpm = 75,  pattern = "1000000100100100" .. "0000100000001000" .. "0000000000000000" .. "1000100010001000" .. "0000000000000000" .. KEYS0 },
}

function C.NoteChar(semitones, accent)
	local ch = string.char(string.byte("m") + semitones)
	return accent and string.upper(ch) or ch
end
function C.Semitones(ch) return string.byte(string.lower(ch)) - string.byte("m") end
function C.Accent(ch) return ch:match("%u") ~= nil end
-- v1 beats were 4 tracks (64 chars): add an empty 808 row; v2 beats (80 chars): add an empty keys lane
function C.Upgrade(pattern)
	if type(pattern) == "string" and #pattern == 64 then pattern = pattern .. string.rep("0", 16) end
	if type(pattern) == "string" and #pattern == C.KeysOffset then pattern = pattern .. KEYS0 end
	return pattern
end
-- seated view at the studio PC
C.SeatCamera = { Offset = Vector3.new(-3.8, 7.9, 0), LookOffset = Vector3.new(5.2, -2.4, 0) }
-- playing a beat on the studio monitors for the whole room
-- room playback through the speakers; queue, airing length and gaps live in Config.Monitors (Services/MonitorService)
C.Broadcast = { Rolloff = { 10, 70 }, VolumeScale = 1.4 }
return C
