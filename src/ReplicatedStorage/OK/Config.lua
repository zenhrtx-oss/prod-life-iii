-- OK Studio Config (v1). Extend, do not replace: other modules read these keys.
local Config = {}
Config.Version = 1
Config.Colors = { warm = Color3.fromRGB(255,190,120), blue = Color3.fromRGB(0,170,255), pink = Color3.fromRGB(255,60,160), red = Color3.fromRGB(255,40,40), white = Color3.fromRGB(235,235,235) }
Config.LightPresets = {
  -- Ambient is the base light under the lamps, bright enough to read the rooms if the lamps don't draw (t60)
  Warm = { Ambient = Color3.fromRGB(78,72,88), Pendant = Color3.fromRGB(255,190,120), Strip = Color3.fromRGB(0,170,255), Exposure = 0.15 },
  Neon = { Ambient = Color3.fromRGB(66,54,92), Pendant = Color3.fromRGB(120,80,255), Strip = Color3.fromRGB(255,60,160), Exposure = 0.05 },
}
Config.Interaction = { MaxDistance = 8, HoldSeconds = 0, RecSeconds = 8, PanelCloseDistance = 12 }
Config.DataStoreName = "OKStudio_v1"
-- session lock (DataService v3): wait LockWaits seconds for another server to release a profile, then take it over;
-- a lock older than LockStaleSeconds is taken at once; autosave refreshes the lock every LockHeartbeatSeconds.
-- LockWaits sums to 30 s, longer than a slow leave save (launch audit A8); with the load's error retries (1 + 2 + 4 s)
-- it stays well under the 60 s other callers wait on that load
Config.Data = { LockStaleSeconds = 600, LockHeartbeatSeconds = 180, LockWaits = { 1, 2, 3, 6, 8, 10 },
  -- Studio play tests run as the creator's own account: keep them away from the live store unless turned on here
  UseStoreInStudio = false }
-- Roblox's licensed partner library accounts (MarketplaceService:GetProductInfo(id).Creator.CreatorTargetId).
-- Every SoundId in the experience must belong to one of these; build/t13_publish_ready.lua checks it.
Config.LicensedCreators = { [7462718749] = "APMOfficial", [7462895450] = "ProSoundEffects" }
-- sounds, all from the licensed library accounts above (ProSoundEffects; build/t14_check.lua checks each id's creator).
-- The interaction sounds play from their part so everyone nearby hears them; the UI keys (Wave 1b: CardOpen to
-- PhoneBuzz) play locally on the client (SoundService:PlayLocalSound), never from a world part.
Config.SFX = {
  LightSwitch = { id = "rbxassetid://9116284750", volume = 0.7 },  -- Light Switch Wall Plastic Flip On Off 2
  Door        = { id = "rbxassetid://9119203830", volume = 0.6 },  -- Sliding Glass Door 1
  Console     = { id = "rbxassetid://9119717523", volume = 0.6 },  -- Switch Click On Or Off Toggle Button 2
  Mic         = { id = "rbxassetid://9117060349", volume = 0.5 },  -- Nasa Transmission Beep 2
  TV          = { id = "rbxassetid://9119717529", volume = 0.5 },  -- Switch Click On Or Off Toggle Button 1
  Computer    = { id = "rbxassetid://9113880475", volume = 0.5 },  -- Computer Keyboard Beep 3
  Station     = { id = "rbxassetid://9113880475", volume = 0.4 },  -- Computer Keyboard Beep 3 (studio laptops)
  GearRack    = { id = "rbxassetid://9119717523", volume = 0.5 },  -- Switch Click On Or Off Toggle Button 2 (gear rack)
  Cypher      = { id = "rbxassetid://9119717529", volume = 0.5 },  -- Switch Click On Or Off Toggle Button 1 (cypher board)
  CreditsWall = { id = "rbxassetid://9119717529", volume = 0.35 }, -- Switch Click On Or Off Toggle Button 1
  StudioTwoDoor = { id = "rbxassetid://9119203830", volume = 0.6 }, -- Sliding Glass Door 1 (the Studio Two door)
  -- UI sounds: Task 0's verified picks (research/wave1b_sounds_2026-10-28.md), pending the user's listen
  CardOpen  = { id = "rbxassetid://9125805579", volume = 0.3 },  -- Rising Whoosh Hissing Build Up Ascending Swo (a card opens)
  Win       = { id = "rbxassetid://9126071452", volume = 0.3 },  -- Synth Sparkle Tone High Pitch Bell Tone Burs (a win)
  Loss      = { id = "rbxassetid://9120885415", volume = 0.45 }, -- Wood Hit Giant Wood Beam Dull Thuds Knocks 5 (a loss)
  Money     = { id = "rbxassetid://9113848780", volume = 0.4 },  -- Coins Drop Wood Table Hits Brass Gear 1 (money lands; a coin-clink stand-in)
  Plant     = { id = "rbxassetid://9120131970", volume = 0.35 }, -- Tone Clusters Classic Synth Switch Tones 18 (a follow-up planted)
  PhoneBuzz = { id = "rbxassetid://9119715399", volume = 0.4 },  -- Switch Blurt Single Short Synth Buzzes 6 (a phone pop; a synth-buzz stand-in)
}
-- XP: every award goes through DataService.AddXP(player, n, source); an unknown source pays 0 and reports [OK][ERR]. Cooldowns in seconds; dailyMax counts awards per UTC day;
-- group shares a daily XP cap (GroupDailyCap). Level thresholds are fixed now so levels never shift once real profiles exist.
Config.XP = {
  Console = 5, Take = 10, -- toast copy
  Sources = {
    Console  = { xp = 5,  cooldown = 600, group = "Activity" },
    Mic      = { xp = 10, cooldown = 120, group = "Activity" },
    BeatSave = { xp = 10, cooldown = 60,  dailyMax = 5 }, -- only when the beat changed by 4+ cells and has 4+ hits
    Delivery = { max = 60, dailyMax = 15 },               -- session requests (Systems/Contracts), first time per request only; >= top reward x1.5
    FireTap  = { xp = 2, dailyMax = 15 },                 -- tapping FIRE on someone else's beat (Systems/Reactions)
    Daily    = { max = 30, dailyMax = 3 },                -- daily requests (Systems/Dailies)
    Weekly   = { max = 75, dailyMax = 1 },                -- the Weekly Single (once a week in practice)
    Cypher   = { max = 40, dailyMax = 10 },               -- entering / winning a cypher round
    CypherVote = { xp = 3, dailyMax = 10 },               -- voting in a cypher
    Phone    = { max = 60, dailyMax = 3 },                -- a phone card's outcome xp (Systems/Phone; spec/economy_fixture.lua XP_PHONE)
  },
  GroupDailyCap = { Activity = 30 }, -- console + mic together, per UTC day
}
-- Cred (Studio Sessions currency; players see it as money, "$"): DataService.AddCred(player, n, source) passes the same
-- gate; sources land with each system. Every Money amount is x10 since profile schema v3 (DataService migrates stored balances).
Config.Cred = {
  Sources = {
    Delivery = { max = 980, dailyMax = 15 }, -- session requests, first time per request only; >= top reward x1.5
    Fire     = { amount = 30, dailyMax = 10 }, -- each FIRE your beat gets on the monitors ($300 a day at most)
    Daily    = { max = 300, dailyMax = 3 },   -- daily requests
    Streak   = { max = 600, dailyMax = 1 },   -- daily streak bonus (3 and 7 days)
    Weekly   = { max = 1200, dailyMax = 1 },  -- the Weekly Single
    Flip     = { amount = 50, dailyMax = 6 }, -- another producer airs a flip of your beat
    Cypher   = { max = 600, dailyMax = 4 },   -- winning a cypher round
    WalkIn   = { max = 2000, dailyMax = 16 }, -- walk-in outcomes (Systems/WalkIns); losses go through DataService.TakeCred
  },
  GroupDailyCap = {},
}
Config.Levels = { 0, 100, 250, 450, 700, 1000, 1400, 1900, 2500, 3200 }
-- banner text shown on reaching a level
Config.Unlocks = {
  [3] = "RUE LANTERN sends requests · new gear on the rack", [4] = "Rank up: ENGINEER",
  [5] = "SAINT VESPER sends requests · Gold nameplate on the rack", [6] = "Rank up: PRODUCER",
  [7] = "NYX ARCADE sends requests · Gold on-air neon on the rack", [8] = "Rank up: HEAD PRODUCER",
  [9] = "INDIGO RAIL sends requests", [10] = "STUDIO LEGEND · Legend nameplate on the rack",
}
-- daily requests (Systems/Dailies): Count a UTC day, each pays XP/Cred once (x1.5 for 3 stars); streak bonuses in Cred
Config.Daily = { Count = 3, XP = 15, Cred = 200, StreakBonus = { [3] = 300, [7] = 600 } }
-- the Weekly Single: one harder request a UTC week; pays once (x1.5 for 3 stars); 3 stars adds a plaque to your card
Config.Weekly = { XP = 50, Cred = 800 }
-- cypher rounds (Systems/BeatBattles): seconds per phase, entrants, voting range, rewards. CancelCooldown: seconds,
-- server-wide, with no new lobby after one ends with too few entrants (launch audit A4)
Config.Cypher = { LobbySeconds = 20, BuildSeconds = 120, VoteSeconds = 20, RevealSeconds = 10, MinEntrants = 2, MaxEntrants = 6, VoteRange = 45,
  CancelCooldown = 60, Reward = { EnterXP = 10, WinXP = 30, WinCred = 500, VoteXP = 3 } }
-- FIRE reactions (Systems/Reactions): listeners within Range studs of a speaker; PairDaily FIRE per listener->producer a day
Config.Fire = { Range = 45, PairDaily = 3 }
-- ranks sit over the levels (index = level)
Config.Ranks = { "INTERN", "RUNNER", "ASSISTANT", "ENGINEER", "BEATMAKER", "PRODUCER", "HITMAKER", "HEAD PRODUCER", "EXEC PRODUCER", "STUDIO LEGEND" }
-- the gear rack (Systems/Gear): Cred buys tools (beat-maker features) and looks. price 0 = everyone owns it.
-- feature = the beat-maker feature a tool unlocks ("Bass", "Rolls", "Swing"); level = rack tier it appears at.
-- kind "voice" = a keys instrument for the piano roll (DAWConfig.Voices[i].gear); the music box is free.
-- kind "fit" = something you wear (slot = where it sits; one fit per slot). needs = career stats you must have before
-- BUY ({ [stat] = n }, Modules/CareerRules.Check). plate_legend stays LAST (t21, t27 and t30 treat it as the top tier).
-- kind "speakers" = your room's desk speakers (tier = its Config.Rooms.Speakers index; Systems/Rooms builds them and
-- plays a room play through them). Not a look: nothing to equip.
Config.Gear = {
  { id = "808",        name = "Sub Boom 808",      kind = "tool",  feature = "Bass",  price = 0,   level = 1, desc = "The 808 row in the beat maker" },
  { id = "rollfx",     name = "Roll FX",           kind = "tool",  feature = "Rolls", price = 250, level = 1, desc = "Hat rolls: tap a hat pad twice or three times" },
  { id = "swing",      name = "Swing Unit",        kind = "tool",  feature = "Swing", price = 350, level = 1, desc = "Swing at 25% and 50%" },
  { id = "neon_ice",   name = "On-air neon: Ice",  kind = "neon",  color = Color3.fromRGB(90, 210, 255),  price = 900, level = 3, desc = "The room's neon flashes ice blue while your beat airs" },
  { id = "kit_tape",   name = "TAPE kit",          kind = "kit",   kit = "tape", price = 1200, level = 3, desc = "Warmer kick, snare, clap and shaker (pick it with KIT in the beat maker)" },
  { id = "voice_pluck", name = "Pluck voice",      kind = "voice", voice = "pluck", price = 600, level = 2, desc = "A plucked string for the keys (pick it with VOICE in the piano roll)" },
  { id = "voice_chime", name = "Chime voice",      kind = "voice", voice = "chime", price = 1100, level = 4, desc = "A bright metal chime for the keys" },
  { id = "plate_gold", name = "Gold nameplate",    kind = "plate", color = Color3.fromRGB(255, 205, 80),  price = 1500, level = 5, desc = "Your nameplate turns gold" },
  { id = "kit_iron",   name = "IRON kit",          kind = "kit",   kit = "iron", price = 2000, level = 6, needs = { placements = 1 }, desc = "Distorted kick, rim snare, slap clap and metal shaker" },
  { id = "neon_gold",  name = "On-air neon: Gold", kind = "neon",  color = Color3.fromRGB(255, 190, 40),  price = 2200, level = 7, desc = "The room's neon flashes gold while your beat airs" },
  -- Task 7 (the Your Rooms plan): your room's speakers, tier 2 and 3 of Config.Rooms.Speakers (tier 1 is the laptop's own).
  -- They go before fit_cuban (t41_check keeps the fits just before plate_legend); neither has a feature, so neither
  -- enters the pacing sim's gear (spec/economy_fixture.lua). Copy: research/rooms/copy_2026-11-12.md §4
  { id = "spk_monitors", name = "Desk monitors", kind = "speakers", tier = 2, price = 500, level = 2, needs = { followers = 200 }, desc = "Real speakers for your desk. They fill your room" },
  { id = "spk_studio", name = "Studio monitors", kind = "speakers", tier = 3, price = 3000, level = 5, needs = { placements = 2, followers = 5000 }, desc = "Big, bright speakers. They fill the whole studio" },
  { id = "fit_cuban",   name = "Cuban link",       kind = "fit",   slot = "neck", fit = "cuban", price = 3500, level = 1, needs = { placements = 2, followers = 5000 }, desc = "A gold chain, built from parts" },
  { id = "fit_snapback", name = "Sponsor snapback", kind = "fit",   slot = "head", fit = "snapback", price = 1500, level = 1, needs = { sponsors = 1 }, desc = "A cap with a flat brim" },
  { id = "fit_shades",   name = "Shades",           kind = "fit",   slot = "face", fit = "shades", price = 2000, level = 1, needs = { aura = 500 }, desc = "Dark shades" },
  { id = "plate_legend", name = "Legend nameplate", kind = "plate", color = Color3.fromRGB(190, 110, 255), price = 4000, level = 10, needs = { hits = 1, followers = 20000, aura = 1000 }, desc = "A purple Legend nameplate" },
}
-- career (Systems/Career): stats besides Money. Career.Add(player, stat, n, source) passes the reward gate keyed
-- "<source>.<stat>" in Sources (amount = fixed award, max = cap on a variable award, dailyMax = awards a UTC day);
-- an unknown source pays 0 and reports [OK][ERR]. DeliveryFeed[stars] is what a first 2- or 3-star delivery pays.
-- Gates: kind "room" is unlocked once with Money (cost) when needs are met; kind "toggle" is the sponsor-on-the-TV
-- switch (free; flips showSponsor once its needs are met). A room gate with a `room` field is a rung of your own ladder
-- (Config.Rooms.Kinds.<room>.gate is its id): owning it adds that room to your plot (Systems/Rooms rebuilds it on the
-- CareerGates change). The ladder gates come first, so the Career tab lists them before THE HALL, which has none. Names and
-- descs: research/rooms/copy_2026-11-12.md section 2 (draft lines, on the approval list). The prices are first guesses.
Config.Career = {
  DeliveryFeed = { [2] = { followers = 40, aura = 5 }, [3] = { followers = 120, aura = 10 } },
  Sources = {
    Delivery = { followers = { max = 120, dailyMax = 15 }, aura = { max = 10, dailyMax = 15 } },
    Fire     = { followers = { amount = 10, dailyMax = 30 } },
    Flip     = { followers = { amount = 25, dailyMax = 6 } },
    Cypher   = { aura = { amount = 25, dailyMax = 4 } },
    Plaque   = { aura = { amount = 40, dailyMax = 1 }, followers = { amount = 300, dailyMax = 1 } },
    WalkIn   = { aura = { max = 500, dailyMax = 16 }, followers = { max = 20000, dailyMax = 16 }, placements = { max = 1, dailyMax = 8 },
      hits = { max = 1, dailyMax = 8 }, sponsors = { max = 1, dailyMax = 8 } },
    -- phone pops (Systems/Phone) move Aura and Followers only; these maxes equal PHONE_CAPS in spec/walkins_data_spec.lua
    -- (build/t46_check.lua asserts it). Pops never pay Money: there is no Config.Cred.Sources.Phone
    -- Config.Phone.DailyMax + 1: a DM opened before UTC midnight and answered after it is counted on the old day but awarded on the new
    Phone    = { aura = { max = 60, dailyMax = 7 }, followers = { max = 2000, dailyMax = 7 } },
    -- the daily Aura heal (Systems/WalkIns): Aura in the red moves up to max toward 0 (CareerRules.HealAmount, never
    -- past it), once a UTC day by the gate's own count (dailyMax)
    AuraHeal = { aura = { max = 5, dailyMax = 1 } },
  },
  Gates = {
    { id = "home_studio", kind = "room", room = "home", name = "HOME STUDIO", desc = "More space, a closet, posters and a booth", needs = { placements = 1, followers = 1000 }, cost = 1500 },
    { id = "real_studio", kind = "room", room = "real", name = "REAL STUDIO", desc = "The biggest room, with space for it all", needs = { placements = 3, followers = 20000 }, cost = 8000 },
    { id = "studio_two", kind = "room", name = "THE HALL", desc = "The door in the passage opens for you", needs = { placements = 1, aura = 300 }, cost = 5000 },
    { id = "sponsor_tv", kind = "toggle", name = "SPONSOR ON THE TV", desc = "Your sponsor's name on the lounge TV while you're in the room", needs = { sponsors = 1 }, cost = 0 },
  },
}
-- walk-ins (Systems/WalkIns): Roster "parody" | "fiction" picks the visitor and sponsor names; times in seconds.
-- FirstDelay / Gap = presence time before the first / next visit; FollowupAt / DropAt = visits until a planted
-- follow-up / a sponsor drop arrives; Odds shift a choice's chance by Aura and Followers (Modules/WalkInRules.Chance).
-- An unanswered card closes after ExpireSeconds, or after ExpireBusySeconds while another visit waits for one of the
-- MaxWalking slots (so open cards at the beat maker or of AFK players can't hold every slot for 5 minutes).
-- While the beat maker hides his card, the visitor says one of his waiting lines every WaitLineSeconds.
-- Waypoints are {x, z} chains per room the visitor walks from Spawn. Tuned in Studio 2026-10-23 with a path-overlap
-- probe: through the lounge he keeps to the z = -4 lane (south of the L-sofa and coffee table, north of the bar
-- stools) and enters the control room at z -3..0; to the booth he crosses the control room on the z = 7 lane, north
-- of the console, desk and MIDI keyboard, and enters by the booth door (x 80, z 4..8).
Config.WalkIns = {
  -- Enabled = false also leaves Studio Two locked, and kit_iron, fit_cuban, fit_snapback and plate_legend unbuyable, for
  -- players who don't already have the stats they need: only walk-ins pay Placements, Hits and Sponsors. It also stops
  -- the daily Aura heal (Career.Sources.AuraHeal), which runs in the walk-in loop, so an Aura saved below 0 climbs only
  -- through the other feeds. To change the names, switch Roster instead.
  Enabled = true, Roster = "parody", DailyMax = 8, FirstDelay = { 60, 120 }, Gap = { 240, 360 }, ExpireSeconds = 300,
  ExpireBusySeconds = 90, WaitLineSeconds = 45, MaxWalking = 3, ArtistCooldown = 3, FollowupAt = { 2, 4 }, DropAt = { 1, 1 },
  -- Odds.ready: a `ready` choice's marks (WalkInRules.Readiness averages level, placements, followers and Aura against
  -- them; ChoiceChance maps that onto min..max). spec/economy_fixture.lua READY holds a literal copy
  Odds = { auraPer = 20, auraCap = 15, followersPer = 1000, followersCap = 10, min = 10, max = 90,
    ready = { level = 7, placements = 5, followers = 30000, aura = 600 },
    -- Wave 3: a card's good chance moves (best beat's BeatQuality - beatCenter) * beatPer and (relationship score) *
    -- relPer points (WalkInRules.BeatTilt, RelTilt). Task 3 tuned beatPer to 3 (no beat -9, 2 stars -3, 3 stars 0, 3 stars
    -- with 3+ FIRE +3; the sim's players average +1.6). Task 5 kept relPer at 4 (a rolled walk-in choice, -12..+12 by its
    -- card's visitor's score; 3 put greedy over the 0.50 money ceiling on one of 200 seeds, 4 and 5 hold every guardrail,
    -- 4 with the most room). The same numbers live in spec/economy_fixture.lua WALKINS.Odds,
    -- build/t46_check.lua (FIXTURE.WALKINS.Odds and PACING.odds) and spec/pacing_spec.lua ODDS: keep the four equal
    beatCenter = 3, beatPer = 3, relPer = 4 },
  -- Wave 3 "Stakes": FirstEver = the presence seconds of the very first walk-in timer, used instead of FirstDelay while
  -- prof.walkins.count == 0, and that one visit skips the tour gate (Systems/WalkIns tick and schedule, design 4.4);
  -- Cold = the cold spell (CareerRules.ColdStep through Systems/Career.ColdCheck: Aura below `aura`, or `quietDays` career
  -- days since the last passed delivery, goes cold; Aura back at `rearmAura` re-arms; dailyMax = the walk-in cap while cold,
  -- Systems/WalkIns.DailyMaxFor); RecentMax = beats kept in prof.sessions.recent. spec/economy_fixture.lua WALKINS and
  -- build/t46_check.lua FIXTURE.WALKINS hold literal copies: keep the three equal.
  FirstEver = { 15, 20 }, Cold = { aura = -50, quietDays = 3, rearmAura = -25, dailyMax = 2 }, RecentMax = 3,
  -- rush hour (WalkInRules.RushGap): a re-arm starts a burst of Size cards with Chance; each burst re-arm is Short
  -- presence seconds after the card closes, and the quiet re-arm after the burst adds back what the shorts saved, so
  -- the pace over time stays Gap's. Reaching DailyMax ends a burst, and one starts only with room for Size[1] visits
  -- before DailyMax (WalkInRules.RushRoom). Bursts never start under the Studio test hold
  -- (ReplicatedStorage.OK's WalkInsPaused attribute present, true or false); the hook's Rush forces one.
  -- spec/rush_spec.lua and build/t46_check.lua's RUSH_SPEC hold literal copies of Rush, Gap, FirstDelay and DailyMax.
  Rush = { Chance = 0.15, Size = { 2, 3 }, Short = { 10, 20 } },
  ArriveDistance = 4, WalkSpeed = 8, WalkTimeout = 40, TagSeconds = 3, Spawn = { 1.5, 5 },
  Waypoints = {
    Corridor = { { 1.5, 5 }, { 9, 5 } },
    Lounge   = { { 1.5, 5 }, { 9, 5 }, { 16, 5 } },
    Control  = { { 1.5, 5 }, { 9, 5 }, { 16, 5 }, { 20, -4 }, { 40, -3 }, { 46, 0 } },
    Booth    = { { 1.5, 5 }, { 9, 5 }, { 16, 5 }, { 20, -4 }, { 40, -3 }, { 46, 0 }, { 52, 0 }, { 68, 7 }, { 78, 7 }, { 83, 6 } },
  },
}
-- Config.Hints (Task 1): one line each, at most 70 bytes (the "·" is 2 bytes, so each is at most 69 characters);
-- HintFor attaches the first unseen term in this order
Config.Hints = {
  { term = "aura", text = "AURA · your reputation. It tilts the odds and can go negative." },
  { term = "followers", text = "FOLLOWERS · your audience. They set your fame tier." },
  { term = "placement", text = "PLACEMENT · your beat on an artist's record." },
  { term = "hit", text = "HIT · a placement that charts. Rare, and it pays." },
  { term = "sponsor", text = "SPONSOR · a brand deal. Keep your Aura over their bar." },
  { term = "flip", text = "FLIP · someone's beat, 8 or more pads changed, aired again." },
  { term = "cypher", text = "CYPHER · two or more producers, one brief. Two duel; 3 or more vote." },
  { term = "fire", text = "FIRE · the room liked your beat. Money and followers." },
}
-- the phone (Systems/Phone): DMs and NEWS pop on it, at most DailyMax opened a UTC day (a waiting pop holds its slot),
-- MaxWaiting un-opened at once. Times in seconds: the first pop FirstDelay after join or the tour's end (the later),
-- then Gap between pops; a pop left un-opened closes after ExpireSeconds, an opened DM left unanswered after
-- OpenExpireSeconds (as a dismiss), an opened NEWS by itself after NewsCloseSeconds; no pop while a walk-in is due
-- within WalkInDueSeconds. Layout "phone" draws the phone card; "walkin" draws it centred at the walk-in card's width.
-- DailyMax is CareerSim's phonePerDay (build/t46_check.lua pins it; Config.Career.Sources.Phone dailyMax = DailyMax + 1).
-- Enabled = false also hides the phone icon and skips planting the follow-ups only the phone delivers (clip_context
-- from the booker's bad outcomes, giveback_letter from the give-back; mishap_owe is planted by a phone card, so it is
-- never planted while the phone is off), so nothing is queued that no source could deliver. The booker's and the
-- give-back's walk-in cards still show their notes, though no follow-up comes. The pacing sim (t46,
-- spec/pacing_spec.lua) still assumes DailyMax pops a day. Untested off: the suite runs with it on.
Config.Phone = { Enabled = true, DailyMax = 6, FirstDelay = { 90, 150 }, Gap = { 120, 180 }, MaxWaiting = 2,
  ExpireSeconds = 600, OpenExpireSeconds = 300, NewsCloseSeconds = 8, WalkInDueSeconds = 60, Layout = "phone" }
-- the career remembers (Wave 2; Systems/Life, Modules/LifeRules): the saved prof.life (schema v5). Every word players
-- read lives in Modules/LifeRules (Copy), which t40 scans; here are only ids, numbers and rules.
-- Tiers = fame tiers by Followers, lowest first (LifeRules.TierFor); a tier is reached once, ever (the saved high-water
-- tier), and each tier above LOCAL plants its one-time visit, TierVisits[id] (a Data/WalkIns follow-up), at the first
-- crossing through Career.Add. DaysPerYear career days make a career year; StoryMax / DiscoMax cap the story and the
-- discography (oldest dropped first). Firsts = the FIRSTS checklist ids, in row order. Titles = the auto title's rules
-- in order, the first that holds wins (tier = i: the highest tier index reached is at least i; first = id: that first
-- is ticked, a backfilled 0 included; neither: always holds); Ribbons = { id, rule } in display order (rule keys as in
-- Titles, plus count = career stat, n = at least). spec/economy_fixture.lua LIFE holds a literal copy (t46 pins it).
Config.Life = {
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
}
Config.AutosaveSeconds = 120
-- studio monitors queue (Services/MonitorService): QueueSize places including the beat on air, one per producer;
-- each airing is whole bars lasting MinSeconds..MaxSeconds (closest to TargetSeconds), GapSeconds of silence between.
-- Enabled = false switches the monitors off (the "music beds" question is the user's call).
Config.Monitors = { Enabled = true, QueueSize = 4, MinSeconds = 12, MaxSeconds = 20, TargetSeconds = 16, GapSeconds = 3, LeadSeconds = 0.5 }
-- your rooms (Systems/Rooms, Modules/RoomRules, Data/RoomCatalog): each player claims one of Slots plots, far from the
-- hub (Modules/RoomRules.PlotOrigin), with a landing and a ladder of rooms, one Kinds row each (`gate` = the
-- Config.Career.Gates id that owns it; none = always owned). Room-local coordinates have their origin on the floor at
-- the room's centre, north -Z. at = the room's centre in plot-local studs; size = its interior (x, z); limit = the items
-- it holds (posters count); plaques / posters = its wall spots. grid = its free floor as { x0, z0, x1, z1 } areas: a
-- 1-stud cell (cx, cz) covers [cx, cx+1) x [cz, cz+1) and must lie wholly inside one area. keep = areas no item may
-- touch (the spawn, the Entrance -> VisitorSpot walkway, the pigeon's spot). anchors = { x, y, z, nx, nz } (a position
-- and a horizontal facing) for the code-built stand-in only: an imported room brings its own (the bedroom's are its
-- Sockets, copied from ok_assets' bedroom_setup.lua). The bedroom's grid and keep are first guesses that Task 10's
-- capture tunes; home and real get grid, keep and anchors in Task 2. Speakers: tier 1 = the laptop's own speakers (no
-- gear); eq = { low, mid, high } dB on an EqualizerSoundEffect. Posters: research/rooms/copy_2026-11-12.md §9's words,
-- colors (RGB), styles and their names; PosterColorInk = the word's ink on each color. spec/room_rules_spec.lua holds a
-- literal copy (Task 2's t100 check pins it to this table): keep the two equal.
Config.Rooms = {
  Slots = 12, PlotOrigin = { 6000, 0, -2000 }, PlotCols = 4, PlotSpacing = 2000,
  Hall = { 3000, 0, 0 }, -- the shared building's hall origin (build/19_rooms.lua builds it there; preflight m3: fixed)
  Template = "Env_bedroom_starter", PlayCooldown = 1, Edit = { burst = 5, every = 0.2 }, ItemParts = 12,
  Landing = { length = 110, width = 8 }, -- plot-local x 0..110, z 0..8; its front door at x 0
  DoorModes = { "open", "friends", "locked" }, DoorDefault = "friends",
  Kinds = { -- ladder order
    bedroom = { order = 1, at = { 10, -8 }, size = { 12.36, 14.83 }, limit = 6, plaques = 3, posters = 0, booth = false,
      grid = { { -1, -0.5, 2, 2 }, { 3, 0.5, 5.8, 3 }, { -6, -7, -3, -1 } },
      keep = { { 0.6, 1.8, 2.6, 3.8 },                                            -- Spawn (its 2 x 2 plate)
        { 1.0, -1.5, 2.9, 1.0 }, { 1.7, 1.0, 3.7, 3.0 }, { 2.4, 3.0, 4.7, 6.2 },  -- Entrance -> VisitorSpot, 1.2 wide
        { -1.2, -0.5, 0.7, 1.5 } },                                               -- CritterSpot (the pigeon, turned)
      anchors = { Entrance = { 4.0849, 0, 5.5897, 0, -1 }, VisitorSpot = { 1.6014, 0, -0.7986, -0.5764, -0.8172 },
        CritterSpot = { -0.2027, 0, 0.6081, 0.6332, 0.774 },
        Plaque_1 = { 6.1784, 5.3919, -4.3986, -1, 0 }, Plaque_2 = { 6.1784, 5.3919, -2.2014, -1, 0 },
        Plaque_3 = { 6.1784, 5.3919, 0, -1, 0 },
        Desk_Speaker_L = { -2.2297, 3, -6.8059, 0, 1 }, Desk_Speaker_R = { 1.0135, 3, -6.8059, 0, 1 } } },
    -- home and real: Task 2's code-built stand-ins (Modules/RoomBuild): door on the south wall's east end, desk on the north
    -- wall, booth in the north-west corner; first guesses until the user's imports land (their free floor goes here then)
    home = { order = 2, gate = "home_studio", at = { 40, -10.6 }, size = { 24, 20 }, limit = 16, plaques = 6, posters = 4, booth = true,
      grid = { { -5, -4, 5, 9 }, { 5, -9, 11, 4 }, { -11, -2, -5, 9 } },
      keep = { { 5, 5.5, 7, 7.5 },                                                -- Spawn (its 2 x 2 plate)
        { 5.4, 3.8, 8.6, 9.1 }, { 3.4, -0.2, 6.6, 5.1 }, { 1.4, -4.2, 4.6, 1.0 },  -- Entrance -> VisitorSpot
        { -2.5, 1, -0.5, 3 },                                                      -- CritterSpot
        { 6, 8.4, 10, 10 } },                                                      -- just inside the door
      anchors = { Entrance = { 8, 0, 8.5, 0, -1 }, VisitorSpot = { 2, 0, -3.6, -0.5764, -0.8172 },
        CritterSpot = { -1.5, 0, 2, 0.6332, 0.774 },
        Desk_Speaker_L = { -1.6, 3, -9.3, 0, 1 }, Desk_Speaker_R = { 1.6, 3, -9.3, 0, 1 },
        Plaque_1 = { 11.9, 5.4, -7.5, -1, 0 }, Plaque_2 = { 11.9, 5.4, -5, -1, 0 }, Plaque_3 = { 11.9, 5.4, -2.5, -1, 0 },
        Plaque_4 = { 11.9, 5.4, 0, -1, 0 }, Plaque_5 = { 11.9, 5.4, 2.5, -1, 0 }, Plaque_6 = { 11.9, 5.4, 5, -1, 0 },
        Poster_1 = { -11.9, 5.5, -6, 1, 0 }, Poster_2 = { -11.9, 5.5, -2, 1, 0 }, Poster_3 = { -11.9, 5.5, 2, 1, 0 },
        Poster_4 = { -11.9, 5.5, 6, 1, 0 },
        BoothSpot = { -8.5, 0, -6.5, 0, 1 }, BoothCam = { -8.5, 5, -1.5, 0, -1 } } },
    real = { order = 3, gate = "real_studio", at = { 85, -14.6 }, size = { 36, 28 }, limit = 24, plaques = 10, posters = 6, booth = true,
      grid = { { -8, -7, 8, 12 }, { 8, -12, 17, 8 }, { -17, -4, -8, 13 } },
      keep = { { 11, 9, 13, 11 },                                                 -- Spawn (its 2 x 2 plate)
        { 9.4, 5.2, 14.6, 13.1 }, { 5.4, -1.5, 10.6, 6.4 }, { 1.4, -8.2, 6.6, -0.3 }, -- Entrance -> VisitorSpot
        { -3, 2, -1, 4 },                                                           -- CritterSpot
        { 12, 12.4, 16, 14 } },                                                     -- just inside the door
      anchors = { Entrance = { 14, 0, 12.5, 0, -1 }, VisitorSpot = { 2, 0, -7.6, -0.5764, -0.8172 },
        CritterSpot = { -2, 0, 3, 0.6332, 0.774 },
        Desk_Speaker_L = { -2.1, 3, -13.4, 0, 1 }, Desk_Speaker_R = { 2.1, 3, -13.4, 0, 1 },
        Plaque_1 = { 17.9, 5.4, -11.25, -1, 0 }, Plaque_2 = { 17.9, 5.4, -8.75, -1, 0 }, Plaque_3 = { 17.9, 5.4, -6.25, -1, 0 },
        Plaque_4 = { 17.9, 5.4, -3.75, -1, 0 }, Plaque_5 = { 17.9, 5.4, -1.25, -1, 0 }, Plaque_6 = { 17.9, 5.4, 1.25, -1, 0 },
        Plaque_7 = { 17.9, 5.4, 3.75, -1, 0 }, Plaque_8 = { 17.9, 5.4, 6.25, -1, 0 }, Plaque_9 = { 17.9, 5.4, 8.75, -1, 0 },
        Plaque_10 = { 17.9, 5.4, 11.25, -1, 0 },
        Poster_1 = { -17.9, 5.5, -10, 1, 0 }, Poster_2 = { -17.9, 5.5, -6, 1, 0 }, Poster_3 = { -17.9, 5.5, -2, 1, 0 },
        Poster_4 = { -17.9, 5.5, 2, 1, 0 }, Poster_5 = { -17.9, 5.5, 6, 1, 0 }, Poster_6 = { -17.9, 5.5, 10, 1, 0 },
        BoothSpot = { -13.5, 0, -10, 0, 1 }, BoothCam = { -13.5, 5, -4, 0, -1 } } },
  },
  Speakers = {
    { gear = nil,            rolloff = { 2, 8 },   volume = 0.5, eq = { -20, -4, 0 } },
    { gear = "spk_monitors", rolloff = { 6, 24 },  volume = 1.0, eq = { -6, 0, 0 } },
    { gear = "spk_studio",   rolloff = { 10, 45 }, volume = 1.4, eq = { 0, 0, 2 } },
  },
  PosterWords = { "LOUD", "GRIND", "DREAM", "BASS", "VIBES", "FIRE", "GOLD", "NIGHT", "FOCUS", "HUSTLE", "RISE", "SOON" },
  PosterColors = {
    { 235, 64, 52 }, { 255, 150, 40 }, { 255, 214, 60 }, { 0, 200, 120 },
    { 60, 130, 255 }, { 150, 90, 240 }, { 230, 45, 145 }, { 28, 28, 34 },
  },
  PosterStyles = 3,
  PosterColorNames = { "RED", "ORANGE", "YELLOW", "GREEN", "BLUE", "PURPLE", "PINK", "BLACK" },
  PosterStyleNames = { "BOLD", "FRAMED", "STACKED" },
  PosterColorInk = {
    { 245, 245, 245 }, { 24, 24, 28 }, { 24, 24, 28 }, { 24, 24, 28 },
    { 245, 245, 245 }, { 245, 245, 245 }, { 245, 245, 245 }, { 245, 245, 245 },
  },
}
-- Day One (Systems/DayOne, Modules/DayOneRules, Data/DayOne): the opening chain of cards in your bedroom. Times in
-- seconds. Enabled = false: no chain starts, and the tour is the passive tracker. A chain starts once you wake up in your
-- bedroom (or after WakeWait), and card 1 follows FirstCard later. LookAround = card 1's "look around first" brings it
-- back that much later, once, if at least ReturnMin seconds are then left before HoldMax (a later look never brings it
-- back); HoldMax = the first-ever walk-in waits at most this long after the chain starts unless a card is open or
-- queued, and a returned card 1 closes then (with Config.WalkIns.FirstEver's 20, a first visit by ~90 s);
-- HoldTakenMax = while the request is taken and not yet delivered (your first beat) the first-ever walk-in waits until
-- this long after the chain starts (final fix, review Important 1: he never walks in mid-beat; an abandoned beat still
-- meets him, FirstEver later); CardSeconds = an unanswered card closes. AfterDeliver = card 2 after the first delivery at your laptop; AfterSpeakers =
-- card 3 after card 2; VisitAfter = the first visitor's range once the chain ends. HaggleOdds = card 1's haggle wins this
-- percent of the time and pays HaggleBonus (money) once, on the starter's first delivery; PrivateXP = "keep it private"
-- pays this XP once. spec/day_one_spec.lua holds a literal copy (Task 2's t120 check pins it to this table): keep the two equal.
Config.DayOne = { Enabled = true, FirstCard = 1, WakeWait = 20, LookAround = 30, ReturnMin = 15, HoldMax = 70, HoldTakenMax = 240,
  CardSeconds = 180, AfterDeliver = 3, AfterSpeakers = 4, VisitAfter = { 5, 7 }, HaggleOdds = 50, HaggleBonus = 50, PrivateXP = 10 }
-- per-player cooldown between uses of one interactable (s), and server-wide cooldowns for shared state
Config.Cooldowns = { Console = 2, Door = 1, TV = 1, LightSwitch = 3, Mic = 1, Computer = 1, CreditsWall = 0.5, Station = 1, GearRack = 1, Cypher = 1, StudioTwoDoor = 1 }
Config.GlobalCooldowns = { Door = 3, LightSwitch = 3 }
-- content: the user decides; true keeps every confirmed credit title as released
Config.Content = { ShowExplicitTitles = true }
return Config
