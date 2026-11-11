-- The economy CareerSim runs against in spec/pacing_spec.lua: a literal copy of the live x10 numbers.
-- Pure (no Roblox globals, no require). Each field names its live source; build/t46_check.lua rebuilds this table from
-- those sources in Studio and asserts it equals a copy of these literals (every field except firePerDay), so the CLI
-- pacing check and the live game can't drift.
return {
	-- Data/Artists.lua A.Briefs, in order: reward.cred (already x10), reward.xp, the artist's level (A.ArtistById[artist].level),
	-- needs = sorted keys of Modules/BriefCheck.Requires(brief) (unlocks the required asks need; the bonus is optional)
	requests = {
		{ cred = 400, xp = 25, level = 1, needs = {} },                   -- j1 Late Bus Home (juno)
		{ cred = 250, xp = 20, level = 1, needs = {} },                   -- j2 Glow Stick
		{ cred = 250, xp = 20, level = 1, needs = {} },                   -- j3 Corner Store Run
		{ cred = 300, xp = 20, level = 1, needs = { "Bass" } },           -- j4 Summer Static (min 808)
		{ cred = 300, xp = 20, level = 1, needs = { "Rolls" } },          -- j5 Arcade Lights (rolls)
		{ cred = 250, xp = 20, level = 1, needs = {} },                   -- t1 Cold Engine (tavi)
		{ cred = 250, xp = 20, level = 1, needs = {} },                   -- t2 Red Light Wait
		{ cred = 300, xp = 25, level = 1, needs = { "Bass" } },           -- t3 Gravel (min 808)
		{ cred = 300, xp = 25, level = 1, needs = { "Rolls" } },          -- t4 Back Pocket (rolls)
		{ cred = 350, xp = 25, level = 3, needs = {} },                   -- r1 Slow Rain Radio (rue)
		{ cred = 350, xp = 25, level = 3, needs = { "Bass" } },           -- r2 Porch Light (notes)
		{ cred = 350, xp = 25, level = 3, needs = { "Swing" } },          -- r3 Blue Hour Call (swing)
		{ cred = 450, xp = 30, level = 5, needs = { "Bass" } },           -- v1 Iron Chapel (vesper; notes)
		{ cred = 450, xp = 30, level = 5, needs = { "Rolls", "Swing" } }, -- v2 Midnight Ledger (swing, rolls)
		{ cred = 450, xp = 30, level = 5, needs = { "Bass", "Swing" } },  -- v3 Velvet Alarm (swing, min 808)
		{ cred = 550, xp = 35, level = 7, needs = { "Rolls" } },          -- n1 Pixel Heart (nyx; rolls)
		{ cred = 550, xp = 35, level = 7, needs = { "Swing" } },          -- n2 Respawn (swing)
		{ cred = 550, xp = 35, level = 7, needs = { "Bass" } },           -- n3 Low Poly (notes)
		{ cred = 650, xp = 40, level = 9, needs = { "Rolls" } },          -- i1 Northbound (indigo; rolls)
		{ cred = 650, xp = 40, level = 9, needs = { "Bass" } },           -- i2 Platform Nine (notes)
		{ cred = 650, xp = 40, level = 9, needs = { "Rolls", "Swing" } }, -- i3 Last Train (swing, rolls)
	},
	daily = { cred = 200, xp = 15, count = 3 },  -- Config.Daily.Cred, Config.Daily.XP, Config.Daily.Count
	weekly = { cred = 800, xp = 50 },            -- Config.Weekly.Cred, Config.Weekly.XP
	cypherWinCred = 500,                         -- Config.Cypher.Reward.WinCred
	cypherXP = 40,                               -- Config.Cypher.Reward.EnterXP + Config.Cypher.Reward.WinXP
	tourXP = 50,                                 -- Systems/Tour.RewardXP
	streakBonus = { [3] = 300, [7] = 600 },      -- Config.Daily.StreakBonus
	fireCred = 30,                               -- Config.Cred.Sources.Fire.amount
	firePerDay = 4,                              -- sim assumption (FIRE received a day), not a live value; t46 skips it
	levels = { 0, 100, 250, 450, 700, 1000, 1400, 1900, 2500, 3200 }, -- Config.Levels
	activityXP = 30,                             -- Config.XP.GroupDailyCap.Activity
	beatSaveXP = 20,                             -- 2 x Config.XP.Sources.BeatSave.xp
	-- Config.Gear rows that have a `feature` (id, price, level, feature)
	gear = {
		{ id = "808", price = 0, level = 1, feature = "Bass" },
		{ id = "rollfx", price = 250, level = 1, feature = "Rolls" },
		{ id = "swing", price = 350, level = 1, feature = "Swing" },
	},
	feeds = {
		delivery = {
			[2] = { aura = 5, followers = 40 },    -- Config.Career.DeliveryFeed[2]
			[3] = { aura = 10, followers = 120 },  -- Config.Career.DeliveryFeed[3]
		},
		plaque = { aura = 40, followers = 300 },   -- Config.Career.Sources.Plaque.aura.amount, .followers.amount
		cypher = { aura = 25 },                    -- Config.Career.Sources.Cypher.aura.amount
		fire = { followers = 10 },                 -- Config.Career.Sources.Fire.followers.amount
	},
	XP_PHONE = { max = 60, dailyMax = 3 },       -- Config.XP.Sources.Phone (a phone card's outcome xp)
	READY = { level = 7, placements = 5, followers = 30000, aura = 600 }, -- Config.WalkIns.Odds.ready
	-- Config.WalkIns, Wave 3 "Stakes" additions (t46 pins each against live Config)
	WALKINS = {
		Odds = { beatCenter = 3, beatPer = 3, relPer = 4 }, -- Config.WalkIns.Odds.beatCenter, .beatPer, .relPer
		FirstEver = { 15, 20 },                             -- Config.WalkIns.FirstEver
		Cold = { aura = -50, quietDays = 3, rearmAura = -25, dailyMax = 2 }, -- Config.WalkIns.Cold
		RecentMax = 3,                                      -- Config.WalkIns.RecentMax
	},
	-- Config.Life (Wave 2: spec/life_rules_spec.lua reads it), a literal copy of the whole table
	LIFE = {
		Tiers = { { id = "LOCAL", followers = 0 }, { id = "BUZZING", followers = 1000 }, { id = "KNOWN", followers = 5000 },
			{ id = "FAMOUS", followers = 20000 }, { id = "ICON", followers = 100000 } },
		DaysPerYear = 7, StoryMax = 100, DiscoMax = 200,
		Firsts = { "beat", "delivery", "delivery3", "placement", "hit", "sponsor", "hall", "cypher", "level5", "buzzing", "known", "streak7" },
		Titles = {
			{ tier = 5, id = "icon" },
			{ tier = 4, id = "famous" },
			{ first = "hit", id = "chart" },
			{ tier = 3, id = "known" },
			{ first = "sponsor", id = "sponsored" },
			{ first = "cypher", id = "cypher" },
			{ first = "placement", id = "record" },
			{ tier = 2, id = "buzzing" },
			{ first = "delivery", id = "regular" },
			{ id = "new" },
		},
		Ribbons = {
			{ id = "streak7", rule = { first = "streak7" } },
			{ id = "placements10", rule = { count = "placements", n = 10 } },
			{ id = "hit", rule = { first = "hit" } },
			{ id = "sponsor", rule = { first = "sponsor" } },
			{ id = "icon", rule = { tier = 5 } },
		},
		TierVisits = { BUZZING = "tier_buzzing", KNOWN = "tier_known", FAMOUS = "tier_famous", ICON = "tier_icon" },
	},
	-- Config.Ranks (spec/life_rules_spec.lua: no title or ribbon is a rank word)
	RANKS = { "INTERN", "RUNNER", "ASSISTANT", "ENGINEER", "BEATMAKER", "PRODUCER", "HITMAKER", "HEAD PRODUCER", "EXEC PRODUCER", "STUDIO LEGEND" },
}
