-- Studio Sessions: fictional artists and their session requests ("briefs").
-- NAMES, TITLES AND QUOTES APPROVED by the user on 2026-10-22 (with the ranks and gear names in Config). Invented for
-- the game; checked that day against web searches for real artists with the same name (none found).
-- No real artists, no OK branding. Briefs never use player-typed text.
--
-- Ask kinds (graded by Modules/BriefCheck):
--   { k = "bpm", min, max }            tempo inside the range
--   { k = "on", track, steps = {..} }  a hit on each of these steps of a track ("Kick on the 1")
--   { k = "backbeat" }                 snare or clap on steps 5 and 13 (beats 2 and 4)
--   { k = "min", track, n }            at least n hits on a track
--   { k = "max", track, n }            at most n hits on a track (n = 0: none)
--   { k = "notes", n }                 the 808 uses at least n different notes          (needs Bass)
--   { k = "rolls", n }                 at least n hat rolls (x2 or x3 pads)              (needs Rolls)
--   { k = "swing", n }                 swing at least n %                                (needs Swing)
--   { k = "melody", n }                at least n notes on the keys (piano roll; no gear needed)
--   { k = "melnotes", n }              the keys use at least n different notes
--   { k = "chord" }                    two or more keys notes start on the same step
-- An ask on the 808 track ("min"/"on" with track "808") also needs Bass.
local A = {}

A.Artists = {
	{ id = "juno",   name = "JUNO VALE",    style = "bouncy melodic rap", level = 1, color = Color3.fromRGB(255, 150, 60),
	  quotes = { [2] = "Okay, okay, I can write to this.", [3] = "This one's going straight on the tape!" } },
	{ id = "tavi",   name = "TAVI GLASS",   style = "hard trap",          level = 1, color = Color3.fromRGB(0, 200, 255),
	  quotes = { [2] = "Solid. Run it back.", [3] = "That knock is crazy. Send it over." } },
	{ id = "rue",    name = "RUE LANTERN",  style = "slow late-night R&B", level = 3, color = Color3.fromRGB(255, 90, 140),
	  quotes = { [2] = "Mm, that sits nice.", [3] = "This is the one I hear in my head." } },
	{ id = "vesper", name = "SAINT VESPER", style = "dark swung trap",    level = 5, color = Color3.fromRGB(170, 90, 255),
	  quotes = { [2] = "Dark enough. I'll take it.", [3] = "Haunting. Exactly the mood." } },
	{ id = "nyx",    name = "NYX ARCADE",   style = "glitchy hyperpop",   level = 7, color = Color3.fromRGB(120, 255, 200),
	  quotes = { [2] = "Cute! Let's glitch it up.", [3] = "This is literally a final boss theme." } },
	{ id = "indigo", name = "INDIGO RAIL",  style = "moody drill",        level = 9, color = Color3.fromRGB(80, 110, 255),
	  quotes = { [2] = "Cold. Good.", [3] = "That's the one. Lock it in." } },
}

local KICK1 = { k = "on", track = "Kick", steps = { 1 } }
local SNARE3 = { k = "on", track = "Snare", steps = { 9 } }
local OFFHATS = { k = "on", track = "Hat", steps = { 3, 7, 11, 15 } }

A.Briefs = {
	-- JUNO VALE (level 1)
	{ id = "j1", artist = "juno", title = "Late Bus Home", starter = true, reward = { xp = 25, cred = 400 },
	  asks = { { k = "bpm", min = 130, max = 160 }, KICK1, { k = "backbeat" } }, bonus = { k = "min", track = "Hat", n = 8 } },
	{ id = "j2", artist = "juno", title = "Glow Stick", reward = { xp = 20, cred = 250 },
	  asks = { { k = "bpm", min = 150, max = 170 }, OFFHATS, { k = "min", track = "Clap", n = 2 } }, bonus = { k = "melody", n = 4 } },
	{ id = "j3", artist = "juno", title = "Corner Store Run", reward = { xp = 20, cred = 250 },
	  asks = { { k = "bpm", min = 90, max = 110 }, { k = "min", track = "Kick", n = 5 }, { k = "backbeat" } }, bonus = { k = "min", track = "Hat", n = 12 } },
	{ id = "j4", artist = "juno", title = "Summer Static", reward = { xp = 20, cred = 300 },
	  asks = { { k = "bpm", min = 140, max = 160 }, { k = "min", track = "808", n = 4 }, KICK1 }, bonus = { k = "notes", n = 3 } },
	{ id = "j5", artist = "juno", title = "Arcade Lights", reward = { xp = 20, cred = 300 },
	  asks = { { k = "bpm", min = 140, max = 160 }, { k = "rolls", n = 2 }, { k = "backbeat" } }, bonus = { k = "min", track = "Hat", n = 8 } },
	-- TAVI GLASS (level 1)
	{ id = "t1", artist = "tavi", title = "Cold Engine", reward = { xp = 20, cred = 250 },
	  asks = { { k = "bpm", min = 140, max = 150 }, { k = "max", track = "Kick", n = 3 }, SNARE3 }, bonus = { k = "min", track = "Hat", n = 8 } },
	{ id = "t2", artist = "tavi", title = "Red Light Wait", reward = { xp = 20, cred = 250 },
	  asks = { { k = "bpm", min = 135, max = 150 }, { k = "max", track = "Clap", n = 0 }, { k = "min", track = "Hat", n = 12 } }, bonus = KICK1 },
	{ id = "t3", artist = "tavi", title = "Gravel", reward = { xp = 25, cred = 300 },
	  asks = { { k = "bpm", min = 140, max = 150 }, { k = "min", track = "808", n = 4 }, SNARE3 }, bonus = { k = "rolls", n = 2 } },
	{ id = "t4", artist = "tavi", title = "Back Pocket", reward = { xp = 25, cred = 300 },
	  asks = { { k = "bpm", min = 140, max = 160 }, { k = "rolls", n = 3 }, { k = "max", track = "Kick", n = 3 } }, bonus = { k = "notes", n = 3 } },
	-- RUE LANTERN (level 3)
	{ id = "r1", artist = "rue", title = "Slow Rain Radio", reward = { xp = 25, cred = 350 },
	  asks = { { k = "bpm", min = 70, max = 90 }, { k = "backbeat" }, { k = "max", track = "Kick", n = 4 } }, bonus = { k = "swing", n = 25 } },
	{ id = "r2", artist = "rue", title = "Porch Light", reward = { xp = 25, cred = 350 },
	  asks = { { k = "bpm", min = 70, max = 90 }, { k = "notes", n = 3 }, { k = "max", track = "Clap", n = 0 } }, bonus = { k = "melnotes", n = 3 } },
	{ id = "r3", artist = "rue", title = "Blue Hour Call", reward = { xp = 25, cred = 350 },
	  asks = { { k = "bpm", min = 75, max = 95 }, { k = "swing", n = 25 }, { k = "backbeat" } }, bonus = { k = "min", track = "808", n = 4 } },
	-- SAINT VESPER (level 5)
	{ id = "v1", artist = "vesper", title = "Iron Chapel", reward = { xp = 30, cred = 450 },
	  asks = { { k = "bpm", min = 130, max = 145 }, { k = "notes", n = 4 }, SNARE3 }, bonus = { k = "rolls", n = 3 } },
	{ id = "v2", artist = "vesper", title = "Midnight Ledger", reward = { xp = 30, cred = 450 },
	  asks = { { k = "bpm", min = 140, max = 160 }, { k = "swing", n = 25 }, { k = "rolls", n = 2 } }, bonus = KICK1 },
	{ id = "v3", artist = "vesper", title = "Velvet Alarm", reward = { xp = 30, cred = 450 },
	  asks = { { k = "bpm", min = 60, max = 80 }, { k = "swing", n = 50 }, { k = "min", track = "808", n = 6 } }, bonus = { k = "max", track = "Clap", n = 0 } },
	-- NYX ARCADE (level 7)
	{ id = "n1", artist = "nyx", title = "Pixel Heart", reward = { xp = 35, cred = 550 },
	  asks = { { k = "bpm", min = 160, max = 180 }, { k = "rolls", n = 3 }, { k = "min", track = "Clap", n = 4 } }, bonus = { k = "notes", n = 4 } },
	{ id = "n2", artist = "nyx", title = "Respawn", reward = { xp = 35, cred = 550 },
	  asks = { { k = "bpm", min = 150, max = 170 }, { k = "min", track = "Kick", n = 6 }, { k = "swing", n = 25 } }, bonus = OFFHATS },
	{ id = "n3", artist = "nyx", title = "Low Poly", reward = { xp = 35, cred = 550 },
	  asks = { { k = "bpm", min = 140, max = 160 }, { k = "notes", n = 4 }, { k = "max", track = "Clap", n = 0 } }, bonus = { k = "rolls", n = 3 } },
	-- INDIGO RAIL (level 9)
	{ id = "i1", artist = "indigo", title = "Northbound", reward = { xp = 40, cred = 650 },
	  asks = { { k = "bpm", min = 138, max = 146 }, SNARE3, { k = "rolls", n = 2 } }, bonus = { k = "min", track = "808", n = 6 } },
	{ id = "i2", artist = "indigo", title = "Platform Nine", reward = { xp = 40, cred = 650 },
	  asks = { { k = "bpm", min = 140, max = 145 }, { k = "notes", n = 5 }, { k = "max", track = "Kick", n = 3 } }, bonus = { k = "swing", n = 25 } },
	{ id = "i3", artist = "indigo", title = "Last Train", reward = { xp = 40, cred = 650 },
	  asks = { { k = "bpm", min = 60, max = 75 }, { k = "swing", n = 50 }, { k = "rolls", n = 3 } }, bonus = { k = "backbeat" } },
}

A.ArtistById, A.BriefById = {}, {}
for _, a in ipairs(A.Artists) do A.ArtistById[a.id] = a end
for _, b in ipairs(A.Briefs) do A.BriefById[b.id] = b end
return A
