-- OK Studio system: walk-ins. Artists, sponsor reps, fans and rivals (Data/WalkIns) walk into the hub rooms as an NPC
-- (Modules/Visitor), offer a choice card, roll a hidden outcome (Modules/WalkInRules) and move Money and the career
-- stats (Systems/Career); some outcomes plant a follow-up that comes back a few visits later.
-- * Presence timer: per player, `remaining` seconds, from Config.WalkIns.FirstDelay on first entering the hub (FirstEver
--   instead while prof.walkins.count is 0: the very first visit, Wave 3 design 4.4) and from Gap after each visit ends
--   (or a visitor leaves without arriving; FirstEver again, with no burst, while count is still 0). A 1 s loop counts
--   it down only while the player is in the hub rooms (WalkInRules.InHub). At 0 a visit starts once the tour is done
--   or skipped (not needed while count is 0, so a new player's first card comes without the tour), the cypher is
--   idle, no visit is in flight for the player and today's count (UTC day) is under DailyMax. Server-wide at most
--   MaxWalking visitors are out at once (from spawn until gone); the rest wait, first come, first walk.
-- * Rush hour (Wave 1b): every re-arm after FirstDelay draws through nextGap (WalkInRules.RushGap on Config.WalkIns.Rush),
--   so now and then a burst of 2-3 visits comes Short seconds apart and the quiet gap after it adds back what they saved.
--   A burst starts only while today leaves room for its smallest size before DailyMax (WalkInRules.RushRoom), so
--   BUSY DAY never covers one visitor and then nobody until UTC midnight, and only once the tour is done (Wave 3: an
--   unfinished tour also ends one, and a first-ever visit that never arrived starts none). The player attribute
--   BusyDay is true from the re-arm that starts a burst until the one that arms its quiet gap; reaching DailyMax, the
--   hook's Reset and leaving end a burst (its saved seconds dropped). The burst lives in server memory only.
-- * The daily Aura heal (Wave 1b): after 5 s in the hub each UTC day (once a session), Aura in the red moves up to
--   Config.Career.Sources.AuraHeal's max toward 0 through Career.Add "AuraHeal", whose gate (dailyMax 1) holds it to
--   once a UTC day across sessions; a heal that pays sends the toast "the internet forgot. +N AURA".
-- * The pick is stored in prof.walkins.next until he arrives, so a respawn or a trip out of the hub never rerolls it.
--   A queued sponsor_drop that no longer applies (the deal it was planted for is gone or changed, or Aura is back at
--   that sponsor's floor) is taken out of the queue when it would be picked, stored pick included, and never applied.
-- * Arrival counts the visit (today, count, last, seen), rolls and applies a follow-up's news, queues sponsor_drop when
--   Aura is under the sponsor's floor, and sends the card. WalkIn_Choose(token, index) applies one choice exactly once
--   (0 = WALK AWAY). Unanswered for ExpireSeconds (ExpireBusySeconds while another visit waits for a walking slot), or
--   when the target leaves the hub or the server or respawns, he walks out with no stat change; a visit that arrived
--   stays counted.
-- * Money path: a choice's cost through DataService.SpendCred; then the outcome's money on its own (AddCred "WalkIn"
--   or TakeCred); stats through Career.Add "WalkIn" / Career.Take. No XP from walk-ins; phone items may pay XP through
--   Config.XP.Sources.Phone. Chips and the overhead tag show what was actually applied. A choice resolves against the
--   career with level = prof.level (a `ready` choice reads it, WalkInRules.ChoiceChance).
-- * Life (Systems/Life, a lazy lookup that never touches the visit): apply reports a placement (with the outcome's
--   `disco`, the discography kind it names), a signed deal and a dropped one (by sponsor id); onArrive reports a HIT's news.
--   Life plants a fame tier's visit through M.PlantSystem at the crossing, which also runs for a crossing away from a visit.
-- * Explainers (Wave 3 design 4.5): the "arrive" card carries hint = { term, text } (Config.Hints) for the first term the
--   player hasn't seen in its tag, line and choice texts as sent (WalkInRules.HintFor, whole word), else in its news
--   strip's headline and text (a follow-up's news, applied on arrival); one per card. A choice's result carries one for
--   its headline and text. Sending a hint marks it seen, prof.hints[term] = the career day (prof.life.day), so it never
--   comes again. M.Hint, M.CardTexts and M.ResultTexts serve Systems/Phone's pops and results the same way.
-- * Your beat (Wave 3 design 4.1): on arrival the visit takes one snapshot of your best recent beat (Contracts.BestBeat:
--   what you delivered or played on the monitors). It fills {beat} in his line, bubble and card ("the one at <bpm>", or
--   "something" with none: WalkInRules.Fill), rides on the "arrive" card as beat = { stars, fires, bpm } (false with
--   none; only on a card with a `beat` or `beatMin` choice, so the footer shows what decides it; never the pattern), and
--   decides the choice: a `beat` choice rolls with WalkInRules.BeatTilt of the snapshot's BeatQuality, and every Resolve
--   gets that quality as beatQ (a `beatMin` choice goes by it). The snapshot is taken again (fix round 1) whenever the
--   recent beats change while his card waits or shows (Contracts.RecentChanged: a delivery at the beat maker while the
--   card waits behind it, a FIRE) and when a deferred card reopens (WalkIn_Deferred false): a new best beat refills
--   {beat} and goes to the client as "beat" { token, beat, line, choices } on the WalkIn remote, which rebuilds the
--   footer line and the texts in place (no riser); the roll uses the same snapshot. Systems/Phone's pops fill with no
--   beat (Filler's bpm nil: "something").
-- * The cold spell (Wave 3, design 4.2; the state is Systems/Career's): while Career.IsCold, today's cap is
--   Config.WalkIns.Cold.dailyMax instead of DailyMax (M.DailyMaxFor: the scheduler, DueWithin, the burst's room and the
--   arrive payload's `max`, which is never under today's count, all read it) and no burst starts; one under way ends at
--   the next re-arm, and at once when the spell starts (M.ColdChanged, called by Career.ColdCheck), so BUSY DAY never
--   shows beside the HUD's COLD chip.
-- * They remember you (Wave 3, design 4.3): prof.walkins.rel = { [visitorId] = { score = -3..3, flags = { [flag] = career
--   day } } }, defaulted and repaired in state() (only visitors and flags the content knows: Data/WalkIns' RelFlags; whole
--   scores held to -3..3). This system is its one writer: M.WriteRel (WalkInRules.RelWrite on the career day,
--   prof.life.day) applies an outcome's `rel` here and for Systems/Phone (a DM's choice and every NEWS), for rel.who or
--   the item's own visitor; any signing resets rel.rep (a new deal is a new relationship). The pick passes it as opts.rel
--   (the needs/under `flags` and `rel` gates); a rolled choice on a walk-in card or follow-up tilts by
--   WalkInRules.RelTilt of its visitor's score (Config.WalkIns.Odds.relPer), added to the beat tilt (Phone's choices
--   never tilt by it). Under the sponsor's floor with rel.rep's score 1 or more, arrival plants sponsor_warning (at
--   DropAt) instead of sponsor_drop, and neither while one of them waits; the warning's arrival plants sponsor_drop
--   WARNING_DROP_AT walk-ins on, which drops you only if Aura is still under the floor then (dropStale covers both).
--   WalkIns' Reset clears it.
-- * Telemetry (Systems/Funnel, source "walkin"): CardChoice (detail "<index>:<outcome key>"), CardWalkAway, and
--   CardNews (detail = the outcome key) when a follow-up's news is applied on arrival.
-- * Wave 1a: the pick passes the life gates (opts.career with visits = the walk-in count), the group caps (keys from
--   WalkInRules.CapKeys, counted at arrival) and whether a beat aired this session; Seed runs before every Pick so a
--   newly eligible card joins the rotation evenly; a stored pick is re-checked (Revalidate) and re-picked when its gate
--   closed or its artist DMed since. The first HIT plants mom_plaque. prof.walkins also holds the phone's counters
--   (`phone`) and the cap counts (`caps`), defaulted in state(); Systems/Phone reads them through the exports below
--   (State, Filler, Chips, Names, Busy, DueWithin, Aired, OnReset) and WalkIns never requires Phone. The scheduler
--   holds while the player attribute PhoneBusy is set (an opened DM awaits its choice).
-- * Visits that behave like people (design 4.4): a card that stands open for the whole expiry closes with a note on its
--   "leave" payload ({ name, waited, line }: who, how long he waited, a W.NoteLines parting line; the visit counted at
--   arrival; telemetry CardExpire and CardNote). No other way a visit ends leaves one. While the client reports the card
--   deferred (WalkIn_Deferred, the beat maker or a cutaway hides it), his bubble says a W.WaitLines line every
--   Config.WalkIns.WaitLineSeconds, the first that long after the deferral began. A visitor of kind critter (the pigeon)
--   is a Visitor.SpawnSpot figure on the lounge coffee table instead of a walker; it holds a MaxWalking slot like any
--   visitor, its card opens wherever the player is in the hub, and it flies off after the result.
-- * Remotes: WalkIn (server -> client: "arrive", "result", "leave", "beat"), WalkIn_Choose, WalkIn_Deferred (client -> server:
--   token, deferred). In Studio the scheduler is paused while ReplicatedStorage.OK's WalkInsPaused attribute is true
--   (tools/test.py sets it around Play), and while that attribute is there at all (true or false: the test hold) no burst
--   starts and the loop never heals; the Studio-only hook ServerScriptService.OK._StudioWalkInHook exists while
--   running (its Age(userId, s) moves the open card's clocks s seconds back, so a test can reach an expiry or the next
--   waiting line without waiting it out; its Sent(userId) returns every WalkIn send since the last call; Rush(userId, k)
--   makes the next re-arm start a burst of k, Rush(userId, 0) ends one, Rush(userId) reads { left, saved, busy }; and
--   Heal(userId) runs the heal now past the hold and the session memory, never past the gate, and returns what it paid;
--   DailyMaxFor(userId) returns today's cap, Wave 3; Rel(userId) returns a copy of prof.walkins.rel, and SetRel(userId,
--   rel) replaces it with a copy of `rel` (not a table: none) through state()'s repair, never reporting, and returns what
--   it kept).
local RS, Players = game:GetService("ReplicatedStorage"), game:GetService("Players")
local RunService, Http = game:GetService("RunService"), game:GetService("HttpService")
local Config = require(RS.OK.Config)
local Rules = require(RS.OK.Modules.WalkInRules)
local CareerRules = require(RS.OK.Modules.CareerRules)
local Format = require(RS.OK.Modules.Format)
local Theme = require(RS.OK.Modules.UITheme)
local Visitor = require(RS.OK.Modules.Visitor)
local Content = require(RS.OK.Data.WalkIns)
local Career = require(RS.OK.Systems.Career)
local Tour = require(RS.OK.Systems.Tour)
local Contracts = require(RS.OK.Systems.Contracts) -- your beat (Tour already requires it: no cycle)

local W = Config.WalkIns
local M = { Enabled = W.Enabled ~= false, Version = 1 }
local DROP = "sponsor_drop" -- the follow-up this system plants when Aura falls under the sponsor's floor
local PLAQUE = "mom_plaque" -- the follow-up this system plants when the first HIT lands (mom comes to see the plaque)
local WARNING = "sponsor_warning" -- planted instead of DROP while rel.rep's score is 1 or more (Wave 3, design 4.3)
local WARNING_DROP_AT = { 2, 3 } -- the drop the warning's arrival plants, in walk-ins (CareerSim: the same literal)
local TAG_COLORS = { win = Theme.gold, loss = Theme.accent2, neutral = Theme.muted }
local HEAL_SECONDS = 5 -- in-hub seconds into a session's UTC day before the heal tries (the client's handlers are up by then)
local NAMES = Content.Names(W.Roster)
local ARTISTS = {} -- decoys (test hook) walk in as artists: a rep's name needs a sponsor
for _, v in ipairs(Content.Visitors) do if v.kind == "artist" then table.insert(ARTISTS, v) end end

local ctx, walkInEv
local ready = {}     -- [userId] = true once the profile has loaded
local remaining = {} -- [userId] = presence seconds until the next visit; nil before the first hub entry
local pending = {}   -- [userId] = the in-flight visit { token, kind, id, handle, arrived, arrivedAt, player, item, entry, fill, def }
local forced = {}    -- [userId] = SetRng values still to hand out (Studio hook)
local live = {}      -- [handle] = target userId: every visitor out, walking, standing or leaving (decoys too)
local liveCount = 0
local waiting = {}   -- first come, first walk: { uid, rec?, start }
local aired = {}     -- [userId] = true once a beat of theirs aired this session (ctx.Monitors.Aired; Pick opts.aired)
local onReset = {}   -- functions the hook Reset calls with the player (Phone's reset registers through M.OnReset)
local sentLog        -- while the Studio hook exists: [userId] = { { kind, payload } } sent since the hook's last Sent
local rush = {}       -- [userId] = the burst under way { left, saved } (WalkInRules.RushGap); nil between bursts
local heals = {}      -- [userId] = { day, seconds, done }: this session's heal clock for the UTC day
local timeRng, drawRng = Random.new(), Random.new() -- FirstDelay/Gap/Rush, and the draws SetRng does not cover

local function report(msg) warn("[OK][ERR] walk-ins: " .. tostring(msg)) end
-- choice telemetry (Systems/Funnel, required lazily like its other callers; a failure never touches the visit)
local function track(p, name, id, detail)
	pcall(function() require(RS.OK.Systems.Funnel).Event(p, name, nil, { source = "walkin", card = id, detail = detail }) end)
end
-- what happened, for the career's memory (Systems/Life, required lazily; a failure never touches the visit)
local function life(p, kind, fields) pcall(function() require(RS.OK.Systems.Life).Event(p, kind, fields) end) end
local function paused() return RunService:IsStudio() and RS.OK:GetAttribute("WalkInsPaused") == true end
-- the test hold: Studio with the WalkInsPaused attribute present, true or false (tools/test.py sets it for the whole
-- suite; t43b and t52 only flip it to false): no burst starts and the loop never heals
local function held() return RunService:IsStudio() and RS.OK:GetAttribute("WalkInsPaused") ~= nil end
local function utcDay() return ctx.Data._day() end
local function between(range) return timeRng:NextInteger(range[1], range[2]) end
local function inHub(p)
	if p.Parent ~= Players then return false end
	local c = p.Character
	local root = c and c:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	local pos = root.Position
	return Rules.InHub(pos.X, pos.Y, pos.Z)
end
-- RS.OK.Cypher is made by BeatBattles' Init; no folder (or no phase) reads as idle
local function cypherIdle()
	local cy = RS.OK:FindFirstChild("Cypher")
	local phase = cy and cy:GetAttribute("Phase")
	return phase == nil or phase == "idle"
end
local function send(p, kind, payload)
	if p.Parent ~= Players then return end
	if sentLog then
		local log = sentLog[p.UserId] or {}
		sentLog[p.UserId] = log
		table.insert(log, { kind = kind, payload = payload })
	end
	local ok, err = pcall(function() walkInEv:FireClient(p, kind, payload) end)
	if not ok then report("send " .. kind .. ": " .. tostring(err)) end
end

-- one player's Pick / Resolve / ResolveNews / Plant draws: SetRng values first (held to [lo, hi]), then random.
-- A draw with one possible result takes no SetRng value.
local function rngFor(uid)
	return function(lo, hi)
		if hi <= lo then return lo end
		local list = forced[uid]
		if list and #list > 0 then return math.clamp(math.floor(tonumber(table.remove(list, 1)) or lo), lo, hi) end
		return drawRng:NextInteger(lo, hi)
	end
end

local function newState(day) return { day = day or 0, today = 0, count = 0, queue = {}, seen = {}, last = {} } end
-- prof.walkins.rel repaired (Wave 3): an entry of a visitor the content doesn't know, or that isn't a table, goes; a score
-- is a whole number held to -3..3 (anything else 0); flags keep only names some outcome sets for that visitor
-- (Content.RelFlags), each stamped with a number (its career day). Never reports: a bad save or the hook's SetRel is
-- repaired quietly, and nothing it drops could have opened or closed a card
local function repairRel(st)
	if type(st.rel) ~= "table" then st.rel = {} end
	for id, e in pairs(st.rel) do
		if type(id) ~= "string" or not Content.VisitorById[id] or type(e) ~= "table" then
			st.rel[id] = nil
		else
			local n = tonumber(e.score)
			e.score = (n ~= nil and n == n) and math.clamp(math.floor(n), -3, 3) or 0
			if type(e.flags) ~= "table" then e.flags = {} end
			local known = Content.RelFlags[id] or {}
			for f, d in pairs(e.flags) do
				if type(f) ~= "string" or not known[f] or type(d) ~= "number" then e.flags[f] = nil end
			end
		end
	end
end
-- prof.walkins, repaired on every touch: numbers are numbers, queue/seen/last are tables, queued ids the deck doesn't
-- know are dropped (Pick skips them but would keep them forever), a `next` that names nothing is forgotten, and the
-- phone counters (`phone`: opened pops this UTC day and ever), the cap counts (`caps`) and the relationships (`rel`, Wave
-- 3: repairRel) default when missing (schema v5 unchanged: this is the one place they are filled in)
local function state(p)
	local prof = ctx.Data.GetProfile(p)
	local st = prof.walkins
	if type(st) ~= "table" then st = newState(); prof.walkins = st end
	st.day, st.today, st.count = tonumber(st.day) or 0, tonumber(st.today) or 0, tonumber(st.count) or 0
	for _, k in ipairs({ "queue", "seen", "last", "caps" }) do if type(st[k]) ~= "table" then st[k] = {} end end
	for group, c in pairs(st.caps) do
		if type(c) ~= "table" or type(c.key) ~= "number" or type(c.n) ~= "number" then st.caps[group] = nil end
	end
	local ph = st.phone
	if type(ph) ~= "table" then ph = {}; st.phone = ph end
	ph.day, ph.today, ph.count = tonumber(ph.day) or 0, tonumber(ph.today) or 0, tonumber(ph.count) or 0
	for i = #st.queue, 1, -1 do
		local q = st.queue[i]
		if type(q) ~= "table" or type(q.at) ~= "number" or not Content.FollowupById[q.id] then table.remove(st.queue, i) end
	end
	local n = st.next
	local known = type(n) == "table" and ((n.kind == "card" and Content.CardById[n.id]) or (n.kind == "followup" and Content.FollowupById[n.id]))
	if not known then st.next = nil end
	repairRel(st)
	return st
end

-- they remember you (Wave 3) -----------------------------------------------------------------------------------------

-- the career day a relationship flag is stamped with (prof.life.day; 1 without a life), as the hints are
local function careerDay(p)
	local life = ctx.Data.GetProfile(p).life
	return type(life) == "table" and tonumber(life.day) or 1
end
-- the one writer of prof.walkins.rel: an outcome's `rel` ({ who?, score?, flag?, clear? }) through WalkInRules.RelWrite for
-- rel.who or `ownVisitor` (the card's), on the career day. Systems/Phone calls it for its DMs and NEWS. False for no write
function M.WriteRel(p, write, ownVisitor)
	if type(write) ~= "table" then return false end
	local st = state(p)
	Rules.RelWrite(st.rel, write, ownVisitor, careerDay(p))
	repairRel(st) -- a who the content doesn't know never stays
	ctx.Data.MarkDirty(p)
	return true
end
-- a visitor's relationship score now (0 with none)
local function relScore(p, visitor)
	local e = state(p).rel[visitor]
	return e and e.score or 0
end
-- a copy of prof.walkins.rel (the hooks' Rel and SetRel)
local function relCopy(rel)
	local out = {}
	for id, e in pairs(rel) do out[id] = { score = e.score, flags = table.clone(e.flags) } end
	return out
end

-- text filling ------------------------------------------------------------------------------------------------------

-- {name:<id>} from the roster, then {sponsor} with the deal this visit is about (named now, before any drop clears it),
-- then {beat} with "the one at <beatBpm>" ("something" when beatBpm is nil: Systems/Phone never passes one)
local function filler(sponsorId, beatBpm)
	local sponsor = sponsorId and Content.SponsorName(sponsorId, W.Roster) or nil
	return function(text) return text and Rules.Fill(text, NAMES, sponsor, beatBpm) or nil end
end

-- your beat -----------------------------------------------------------------------------------------------------------

-- the player's best recent beat (Contracts.BestBeat, a copy) or false; never fails the visit (an error reports, false)
local function bestBeat(p)
	local ok, res = pcall(Contracts.BestBeat, p)
	if not ok then report("best beat: " .. tostring(res)); return false end
	return res or false
end
-- does your beat decide a choice of this card or follow-up (a `beat` or a `beatMin` choice)?
local function beatDecides(item)
	for _, c in ipairs(type(item.choices) == "table" and item.choices or {}) do
		if type(c) == "table" and (c.beat or c.beatMin) then return true end
	end
	return false
end
-- what the card's payload carries as `beat`: { stars, fires, bpm } of the snapshot or false, only on a card your beat
-- decides (never the pattern); nil on any other card
local function beatPayload(rec)
	if not beatDecides(rec.item) then return nil end
	return rec.beat and { stars = rec.beat.stars, fires = rec.beat.fires, bpm = rec.beat.bpm } or false
end
-- the visit's snapshot quality (WalkInRules.BeatQuality; 0 with no beat) and a choice's chance tilt: BeatTilt for a
-- `beat` choice, plus (Wave 3, design 4.3) RelTilt of the card's visitor's score for a rolled choice (a sure or beatMin
-- choice never rolls), read when it is chosen
local function beatQOf(rec) return Rules.BeatQuality(rec.beat or nil) end
local function tiltOf(rec, choice)
	local tilt = choice.beat and Rules.BeatTilt(beatQOf(rec), W.Odds) or 0
	if not choice.sure and not choice.beatMin then
		local score = relScore(rec.player, rec.item.visitor)
		if score ~= 0 then tilt += Rules.RelTilt(score, W.Odds) end
	end
	return tilt
end

-- explainers ---------------------------------------------------------------------------------------------------------

local function addText(list, s) if type(s) == "string" and s ~= "" then table.insert(list, s) end end
-- what a card payload shows that a hint may explain: its tag, its line and every choice's text, as sent
local function cardTexts(card)
	local list = {}
	addText(list, card.tag); addText(list, card.line)
	for _, c in ipairs(type(card.choices) == "table" and card.choices or {}) do addText(list, type(c) == "table" and c.text or nil) end
	return list
end
-- what a result payload shows that a hint may explain: its headline and text
local function resultTexts(r)
	local list = {}
	addText(list, r.headline); addText(list, r.text)
	return list
end
-- the hint for `texts` (WalkInRules.HintFor on Config.Hints: the first term in that order the player hasn't seen), marked
-- seen at once with the career day (prof.life.day; 1 without a life), so the payload that carries it is its only one.
-- Returns a copy { term, text }, or nil. Never fails the payload: an error is reported and gives nil
local function hint(p, texts)
	local ok, res = pcall(function()
		local list = Config.Hints
		if type(list) ~= "table" or #texts == 0 then return nil end
		local prof = ctx.Data.GetProfile(p)
		if type(prof.hints) ~= "table" then prof.hints = {} end
		local h = Rules.HintFor(texts, prof.hints, list)
		if not h then return nil end
		local life = prof.life
		prof.hints[h.term] = type(life) == "table" and tonumber(life.day) or 1
		ctx.Data.MarkDirty(p)
		return { term = h.term, text = h.text }
	end)
	if not ok then report("hint: " .. tostring(res)); return nil end
	return res
end
M.Hint, M.CardTexts, M.ResultTexts = hint, cardTexts, resultTexts

local function sign(n) return n > 0 and "+" or "-" end
local CHIPS = {
	{ "aura", function(n) return Format.Signed(n) .. " AURA" end },
	{ "followers", function(n) return sign(n) .. Format.Count(math.abs(n)) .. " FOLLOWERS" end },
	{ "placements", function(n) return sign(n) .. math.abs(n) .. " PLACEMENT" end },
	{ "hits", function(n) return sign(n) .. math.abs(n) .. " HIT" end },
	{ "sponsors", function(n) return sign(n) .. math.abs(n) .. " SPONSOR" end },
}
-- the result chips for what was applied: the cost, the outcome's money, the XP paid (applied.xp, set by Systems/Phone
-- only: missing = 0), then each stat; nothing for a zero
local function chipsFor(applied)
	local chips = {}
	if applied.cost > 0 then table.insert(chips, { label = "-" .. Format.Money(applied.cost), kind = "money" }) end
	if applied.money ~= 0 then table.insert(chips, { label = Format.SignedMoney(applied.money), kind = "money" }) end
	if (applied.xp or 0) > 0 then table.insert(chips, { label = "+" .. applied.xp .. " XP", kind = "xp" }) end
	for _, c in ipairs(CHIPS) do
		local n = applied[c[1]]
		if n ~= 0 then table.insert(chips, { label = c[2](n), kind = c[1] }) end
	end
	return chips
end
-- the ResultPayload; planted = true when apply queued a follow-up for this outcome (not a chip)
local function resultOf(rec, outcome, applied, planted)
	local fill = rec.fill
	return { token = rec.token, key = outcome.key, headline = fill(outcome.headline), text = fill(outcome.text), tone = outcome.tone,
		chips = chipsFor(applied), note = fill(outcome.note), planted = planted or nil }
end
-- what Systems/Phone reuses (it requires WalkIns; WalkIns never requires Phone). State needs ctx: player and loop
-- paths only, never Init
M.State, M.Filler, M.Chips, M.Names = state, filler, chipsFor, NAMES
local function cardOf(rec, news)
	local item, fill = rec.item, rec.fill
	local choices = {}
	for i, c in ipairs(item.choices or {}) do choices[i] = { text = fill(c.text), cost = (c.cost or 0) > 0 and c.cost or nil } end
	return { id = rec.id, visitor = { name = rec.def.name, style = rec.def.style, color = rec.def.color }, tag = fill(item.tag),
		line = fill(item.line), choices = choices, news = news, beat = beatPayload(rec) }
end

-- the visit's best beat taken again (fix round 1; see the header): only for an arrived card your beat decides, and only
-- when the best beat differs from the snapshot (pattern, stars, FIRE, bpm). Then rec.beat and rec.fill are replaced and
-- the client gets "beat" { token, beat, line, choices = { text, ... } }. Returns whether it sent one
local function sameBeat(a, b)
	if not a or not b then return (not a) == (not b) end
	return a.pattern == b.pattern and a.stars == b.stars and a.fires == b.fires and a.bpm == b.bpm
end
local function refreshBeat(rec)
	if not rec.arrived or not beatDecides(rec.item) then return false end
	local p = rec.player
	local now = bestBeat(p)
	if sameBeat(now, rec.beat) then return false end
	rec.beat = now
	rec.fill = filler(rec.sponsorId, now and now.bpm or nil)
	local item, fill = rec.item, rec.fill
	local texts = {}
	for i, c in ipairs(item.choices or {}) do texts[i] = fill(c.text) end
	send(p, "beat", { token = rec.token, beat = beatPayload(rec), line = fill(item.line), choices = texts })
	return true
end
local function refreshSafe(rec)
	local ok, err = pcall(refreshBeat, rec)
	if not ok then report("beat refresh: " .. tostring(err)) end
end

-- applying ----------------------------------------------------------------------------------------------------------

-- the overhead tag for what was applied, over the target's head for TagSeconds (no tag when nothing was applied),
-- picked and coloured by the outcome's tone so it agrees with the headline
local function showTag(p, applied, tone)
	local text, tagTone = Rules.TagFor(applied, Format, tone)
	local head = p.Character and p.Character:FindFirstChild("Head")
	if not text or not head then return end
	local old = head:FindFirstChild("OK_WalkInTag")
	if old then old:Destroy() end
	local bb = Instance.new("BillboardGui")
	-- stacked above the player's name plate (Nameplate: 48 px tall at StudsOffset (0, 2.4, 0)) in pixels, the way
	-- Visitor's bubble sits above his plate: pixel heights don't scale with distance, a studs gap would overlap far away
	bb.Name = "OK_WalkInTag"; bb.Size = UDim2.fromOffset(240, 40); bb.StudsOffset = Vector3.new(0, 2.4, 0)
	bb.SizeOffset = Vector2.new(0, (48 / 2 + 6 + 40 / 2) / 40)
	bb.MaxDistance = 80; bb.LightInfluence = 0; bb.Adornee = head
	local label = Instance.new("TextLabel")
	label.Name = "Label"; label.Size = UDim2.fromScale(1, 1); label.BackgroundTransparency = 1
	label.Font = Theme.fontBlack; label.TextScaled = true; label.TextStrokeTransparency = 0.35
	label.TextColor3 = TAG_COLORS[tone or tagTone] or Theme.muted; label.Text = text; label.Parent = bb
	bb.Parent = head
	task.delay(W.TagSeconds, function() if bb.Parent then bb:Destroy() end end)
end

-- apply a Resolve / ResolveNews result after its cost was paid (the Money path): the outcome's money on its own, the
-- stats, the sponsor deal (a signing resets rel.rep), the relationship write (M.WriteRel), a planted follow-up, a
-- cooldown. The first HIT (hits 0 -> more) plants mom_plaque at {1, 2} after the outcome's own plant, as CareerSim does
-- (Plant refuses a second while one is queued). A follow-up only the phone delivers (source "phone": clip_context,
-- giveback_letter) is not planted while Config.Phone is off: queued, nothing could ever pop it and Plant would refuse the
-- thread for good. Rng order: a Followers Add below that
-- crosses a tier plants its visit (Life -> PlantSystem) from inside Career.Add, so the visit draws before this outcome's
-- plant and the plaque's; CareerSim's addStat draws in the same order, and a test's SetRng list must too. Returns the
-- amounts actually applied, and whether either plant queued a follow-up (Plant returned an entry)
local function apply(p, res, item, cost)
	local d, o = res.deltas, res.outcome
	local st = state(p)
	local applied = { cost = cost, money = 0 }
	local before = Career.Get(p) -- the hits and the deal as they stood: a drop names the sponsor it ended
	local hadHit = before.hits > 0
	if d.money > 0 then applied.money = ctx.Data.AddCred(p, d.money, "WalkIn")
	elseif d.money < 0 then applied.money = -ctx.Data.TakeCred(p, -d.money) end
	for _, stat in ipairs(CareerRules.STATS) do
		local n = d[stat] or 0
		if n > 0 then applied[stat] = Career.Add(p, stat, n, "WalkIn")
		elseif n < 0 then applied[stat] = -Career.Take(p, stat, -n)
		else applied[stat] = 0 end
	end
	if o.sponsor == "drop" then Career.SetSponsor(p, nil); life(p, "sponsor_drop", { s = before.sponsor })
	elseif type(o.sponsor) == "string" then
		Career.SetSponsor(p, o.sponsor); life(p, "sponsor", { s = o.sponsor })
		st.rel.rep = nil -- a new deal is a new relationship (design 4.3): the rep's score and flags start over
	end
	if type(o.rel) == "table" then M.WriteRel(p, o.rel, item.visitor) end
	if applied.placements > 0 then life(p, "placement", { v = item.visitor, key = item.id, disco = o.disco }) end
	local planted = false
	if type(o.plant) == "table" then
		local f = Content.FollowupById[o.plant.id]
		local phoneOff = Config.Phone ~= nil and Config.Phone.Enabled == false
		if not (f and f.source == "phone" and phoneOff) then
			planted = Rules.Plant(st, o.plant, W.FollowupAt, rngFor(p.UserId), { sponsor = item.sponsor }) ~= nil
		end
	end
	if not hadHit and applied.hits > 0 and Rules.Plant(st, { id = PLAQUE, at = { 1, 2 } }, W.FollowupAt, rngFor(p.UserId)) then planted = true end
	if type(o.cooldown) == "number" then st.last[item.visitor] = (st.last[item.visitor] or st.count) + o.cooldown end
	ctx.Data.MarkDirty(p)
	return applied, planted
end

-- visits ------------------------------------------------------------------------------------------------------------

-- { kind, id, item, entry } for a card or follow-up id; a follow-up comes with its queue entry, or (only when `make`)
-- a new entry due now that is not in the queue
local function pickOf(st, kind, id, make)
	if kind == "card" then
		local card = Content.CardById[id]
		return card and { kind = "card", id = id, item = card } or nil
	end
	local f = Content.FollowupById[id]
	if not f then return nil end
	for _, q in ipairs(st.queue) do
		if q.id == id then return { kind = "followup", id = id, item = f, entry = q } end
	end
	return make and { kind = "followup", id = id, item = f, entry = { id = id, at = st.count + 1 } } or nil
end

-- a sponsor_drop (or, Wave 3, sponsor_warning) pick that no longer applies for `have` (Career.Get): the deal it was planted
-- for is gone or another one, or Aura is back at that sponsor's floor (the drop is planted on one arrival and comes on a
-- later one)
local function dropStale(have, pick)
	if pick.kind ~= "followup" or (pick.id ~= DROP and pick.id ~= WARNING) then return false end
	local planted = type(pick.entry.ctx) == "table" and pick.entry.ctx.sponsor or nil
	local deal = planted and Content.SponsorById[planted]
	return planted ~= have.sponsor or not deal or have.aura >= deal.floor
end

-- a WalkInRules.Pick result as a pick ({ kind, id, item, entry }); nil for nil
local function pickFrom(res)
	if not res then return nil end
	if res.kind == "card" then return { kind = "card", id = res.card.id, item = res.card } end
	return { kind = "followup", id = res.entry.id, item = res.followup, entry = res.entry }
end

-- the Pick opts (Shared shapes; Phone and CareerSim pass the same): the artist cooldown, this player's draws, the
-- sponsor floor, the life gates against the career with visits = the walk-in count, the cap keys (whole UTC days
-- since the epoch and that day // 7, never the yyyymmdd day counter), whether a beat of theirs aired this session and the
-- relationships (Wave 3: opts.rel, the `flags` and `rel` gates)
local function pickOpts(p, st, have)
	local career = table.clone(have)
	career.visits = st.count
	local day, week = Rules.CapKeys(ctx.Data._now())
	return { cooldown = W.ArtistCooldown, rng = rngFor(p.UserId), sponsored = have.sponsor ~= nil, aura = have.aura,
		source = "walkin", career = career, day = day, week = week, aired = aired[p.UserId] == true, rel = st.rel }
end

-- the next visit: the stored pick while it still applies (dropStale; Revalidate re-picks a card whose gate or cap
-- closed, or whose artist DMed, since it was stored), else Seed then WalkInRules.Pick, stored as prof.walkins.next
-- before he spawns; nil if none. A stale sponsor_drop (dropStale) leaves the queue and the next pick is taken instead
local function nextPick(p, st)
	local have = Career.Get(p)
	local opts = pickOpts(p, st, have)
	local n = st.next
	local pick = n and pickOf(st, n.kind, n.id, false)
	local stale = pick ~= nil and dropStale(have, pick)
	if pick and not stale and Rules.Revalidate(st, Content.Deck, opts, pick.kind == "card" and pick.item or nil) then return pick end
	Rules.Seed(st, Content.Deck, opts)
	if not stale then pick = pickFrom(Rules.Pick(st, Content.Deck, opts)) end
	while pick and dropStale(have, pick) do -- each pass takes one entry out of the queue, so this ends
		Rules.TakeQueued(st, pick.entry)
		pick = pickFrom(Rules.Pick(st, Content.Deck, opts))
	end
	st.next = pick and { kind = pick.kind, id = pick.id } or nil
	ctx.Data.MarkDirty(p)
	return pick
end

-- the in-flight record for a pick (blocks the scheduler and the hook's Spawn for the player until it ends)
local function newRecord(p, pick)
	local item = pick.item
	local entryCtx = pick.entry and type(pick.entry.ctx) == "table" and pick.entry.ctx or {}
	local sponsorId = item.sponsor or entryCtx.sponsor or Career.Get(p).sponsor
	local fill = filler(sponsorId) -- refilled with your best beat's bpm on arrival (onArrive)
	local v = Content.VisitorById[item.visitor]
	local rec = { token = Http:GenerateGUID(false), kind = pick.kind, id = pick.id, handle = nil, arrived = false, arrivedAt = nil,
		player = p, item = item, entry = pick.entry, fill = fill, sponsorId = sponsorId, beat = false,
		def = { id = v.id, name = fill(NAMES[v.id] or v.id), style = v.style, color = v.color, sig = v.sig } }
	pending[p.UserId] = rec
	return rec
end

-- no burst for p: its saved seconds dropped, BusyDay off
local function endRush(p)
	rush[p.UserId] = nil
	p:SetAttribute("BusyDay", false)
end

-- the cold spell (Systems/Career owns it): a read that never fails the scheduler (an error reads as warm, reported)
local function cold(p)
	local ok, res = pcall(Career.IsCold, p)
	if not ok then report("cold: " .. tostring(res)); return false end
	return res == true
end
-- today's walk-in cap for p: DailyMax, or Config.WalkIns.Cold.dailyMax (never more) while the player is cold
function M.DailyMaxFor(p)
	local c = W.Cold
	if type(c) == "table" and type(c.dailyMax) == "number" and cold(p) then return math.min(W.DailyMax, c.dailyMax) end
	return W.DailyMax
end
-- Career.ColdCheck: the spell started (true) or ended (false). Starting ends a burst under way at once
function M.ColdChanged(p, isCold)
	if isCold and typeof(p) == "Instance" then endRush(p) end
	return true
end

-- the presence seconds a re-arm sets (every re-arm but FirstDelay): WalkInRules.RushGap on timeRng. A burst starts only
-- when allowStart (the no-pick re-arm passes false, so the chip never promises visitors the deck can't send), the
-- test hold is off and today leaves room for the smallest burst before DailyMax (WalkInRules.RushRoom); one under way
-- (the hook's Rush too) goes on. Today at DailyMax (a stored day that isn't today counts 0, as the rollover would make
-- it) ends the burst and re-arms with a plain Gap. While the tour isn't done (only the first-ever visit comes before
-- it), no burst starts and one under way ends: BUSY DAY never shows while no visitor can come. The same while the player
-- is cold (Wave 3: the cap is Cold.dailyMax, DailyMaxFor). BusyDay is set while a burst runs
local function nextGap(p, allowStart)
	local uid = p.UserId
	local st = state(p)
	local sameDay = st.day == utcDay()
	local max = M.DailyMaxFor(p)
	if sameDay and st.today >= max then
		endRush(p)
		return between(W.Gap)
	end
	local toured = Tour.State(p).done
	local chilled = cold(p)
	if not toured or chilled then endRush(p) end
	local seconds, r = Rules.RushGap(rush[uid], W.Rush, W.Gap, function(lo, hi) return timeRng:NextInteger(lo, hi) end,
		function() return timeRng:NextNumber() end,
		allowStart and toured and not chilled and not held() and Rules.RushRoom(st.today, max, W.Rush.Size, sameDay))
	rush[uid] = r
	p:SetAttribute("BusyDay", r ~= nil)
	return seconds
end

-- the visit ends with no choice; reason = expired | left_hub | respawn | left_server | error | gone | hook. He walks
-- out (the pigeon flies off), the client closes the card, nothing is applied. Only `expired` (the card stood open for
-- the whole limit) puts a note on the "leave" payload, { name, waited = Format.Duration(seconds), line }, and logs
-- CardExpire and CardNote; the visit counted at arrival (design 4.4). No-op unless rec is still the player's in-flight visit
local function endVisit(rec, reason)
	local uid = rec.player.UserId
	if pending[uid] ~= rec then return end
	pending[uid] = nil
	for i, job in ipairs(waiting) do
		if job.rec == rec then table.remove(waiting, i); break end
	end
	if rec.handle then rec.handle:Leave() end
	local payload = { token = rec.token }
	if reason == "expired" then
		local lines = Content.NoteLines
		local waited = math.floor(os.clock() - rec.arrivedAt)
		local line = #lines > 0 and rec.fill(lines[timeRng:NextInteger(1, #lines)]) or ""
		payload.note = { name = rec.def.name, waited = Format.Duration(waited), line = line }
		track(rec.player, "CardExpire", rec.id, tostring(waited))
		track(rec.player, "CardNote", rec.id, line)
	end
	send(rec.player, "leave", payload)
	-- leaving the server re-arms nothing: onLeave clears the timer and the burst, and the leaving player's profile is
	-- never read (DataService may be releasing it). A first-ever visit that ended before he arrived (count still 0)
	-- re-arms from FirstEver with no burst, so a new player keeps the fast first card
	if reason ~= "left_server" then
		if state(rec.player).count == 0 then
			endRush(rec.player)
			remaining[uid] = between(W.FirstEver or W.FirstDelay)
		else
			remaining[uid] = nextGap(rec.player, true)
		end
	end
end

local pump
-- put a visitor on the floor for p (a critter on the lounge coffee table, `spot`); he holds a walking slot until he is
-- gone. nil when he can't be built
local function spawnVisitor(def, p, onArrive, onGone, spot)
	local handle
	local ok, err = pcall(function()
		handle = (spot and Visitor.SpawnSpot or Visitor.Spawn)(def, p, { walkins = W,
			onArrive = function() onArrive(handle) end,
			onGone = function()
				if live[handle] then live[handle] = nil; liveCount -= 1 end
				if onGone then onGone() end
				pump()
			end })
	end)
	if not ok then report("visitor " .. tostring(def.id) .. ": " .. tostring(err)); return nil end
	live[handle] = p.UserId
	liveCount += 1
	return handle
end

-- is `id` in the follow-up queue?
local function queuedId(st, id)
	for _, q in ipairs(st.queue) do if q.id == id then return true end end
	return false
end
-- he arrived: the visit counts; a follow-up's news is rolled and applied (sponsor_drop and sponsor_warning only while they
-- still apply, see dropStale, else the news is empty; the warning then plants the drop); then the sponsor floor check
-- (the drop or the warning, never while one waits) and the card. `arrived` is set last
local function onArrive(rec)
	local p, uid = rec.player, rec.player.UserId
	if pending[uid] ~= rec then rec.handle:Leave(); return end
	local ok, err = pcall(function()
		-- your beat: one snapshot for the whole visit, his line, bubble and card, the payload's beat and the roll
		rec.beat = bestBeat(p)
		rec.fill = filler(rec.sponsorId, rec.beat and rec.beat.bpm or nil)
		local st = state(p)
		Rules.Rollover(st, utcDay())
		st.today += 1
		st.count += 1
		st.last[rec.item.visitor] = st.count
		st.seen[rec.id] = (st.seen[rec.id] or 0) + 1
		local day, week = Rules.CapKeys(ctx.Data._now())
		Rules.CountCap(st, rec.item, day, week) -- a capped card counts against its group here, not at the pick
		st.next = nil
		local line, news = rec.item.line, nil
		if rec.kind == "followup" then
			Rules.TakeQueued(st, rec.entry)
			local res = Rules.ResolveNews(rec.item, Career.Get(p), W.Odds, rngFor(uid))
			if dropStale(Career.Get(p), rec) then
				news = { token = rec.token, key = "none", headline = "", text = "", tone = "neutral", chips = {} }
			else
				local applied, planted = apply(p, res, rec.item, 0)
				if applied.hits > 0 then life(p, "hit", { v = rec.item.visitor, key = rec.id }) end
				if rec.id == WARNING then -- the rep's warning (Wave 3): they check again WARNING_DROP_AT walk-ins on
					local entryCtx = type(rec.entry.ctx) == "table" and rec.entry.ctx or {}
					local sponsor = entryCtx.sponsor or Career.Get(p).sponsor
					if Rules.Plant(st, { id = DROP, at = WARNING_DROP_AT }, W.FollowupAt, rngFor(uid), { sponsor = sponsor }) then planted = true end
				end
				news = resultOf(rec, res.outcome, applied, planted)
				line = res.outcome.line or line
				showTag(p, applied, res.outcome.tone)
				track(p, "CardNews", rec.id, res.outcome.key)
			end
		end
		rec.handle:Say(rec.fill(line))
		local have = Career.Get(p)
		local deal = have.sponsor and Content.SponsorById[have.sponsor]
		if deal and have.aura < deal.floor and not queuedId(st, DROP) and not queuedId(st, WARNING) then
			-- under the floor: the drop, or the rep's warning while rel.rep's score is 1 or more (Wave 3)
			local rep = st.rel.rep
			local id = (rep ~= nil and (rep.score or 0) >= 1 and Content.FollowupById[WARNING]) and WARNING or DROP
			Rules.Plant(st, { id = id }, W.DropAt, rngFor(uid), { sponsor = have.sponsor })
		end
		ctx.Data.MarkDirty(p)
		local card = cardOf(rec, news)
		-- one per card: the tag, line and choices first; else the news strip's headline and text (a follow-up's result)
		card.hint = hint(p, cardTexts(card)) or (news and hint(p, resultTexts(news))) or nil
		-- the header's "N OF M TODAY": never under N (fix round 1, E). A visit scheduled before the player went cold (a phone
		-- DM's loss while he walked in, or this follow-up's own news above) still arrives, and the cold cap reads as reached
		send(p, "arrive", { token = rec.token, card = card, today = st.today, max = math.max(M.DailyMaxFor(p), st.today) })
		rec.news = news and news.key
		rec.arrived, rec.arrivedAt = true, os.clock()
	end)
	if not ok then report("arrival: " .. tostring(err)); endVisit(rec, "error") end
end

-- the record's visitor walks in now (MaxWalking already allowed for; a critter appears on the lounge coffee table
-- instead); false when the visit could not start
local function walkIn(rec)
	local p = rec.player
	if pending[p.UserId] ~= rec then return false end
	if not inHub(p) then endVisit(rec, "left_hub"); return false end
	local v = Content.VisitorById[rec.item.visitor]
	local handle = spawnVisitor(rec.def, p, function() onArrive(rec) end, function() endVisit(rec, "gone") end, v and v.kind == "critter")
	if not handle then endVisit(rec, "error"); return false end
	rec.handle = handle
	return true
end

-- WalkIn_Deferred (the client hides the arrived card behind the beat maker or a cutaway) and the hook's SetDeferred:
-- only the player's arrived record with that token changes, anything else is ignored (false). While deferred, upkeep
-- says a waiting line every WaitLineSeconds, the first one that long after the deferral began
local function setDeferred(p, token, deferred)
	local rec = pending[p.UserId]
	if not rec or not rec.arrived or type(token) ~= "string" or token ~= rec.token then return false end
	if deferred then
		if not rec.deferred then rec.deferred, rec.deferredAt, rec.lineAt = true, os.clock(), os.clock() end
	else
		rec.deferred, rec.deferredAt, rec.lineAt = nil, nil, nil
		refreshSafe(rec) -- the card shows now: with your best beat as it is now (fix round 1)
	end
	return true
end

-- admit waiting visits, first come first, while fewer than MaxWalking visitors are out
function pump()
	while #waiting > 0 do
		local admitted, rest = Rules.Admit(liveCount, waiting, W.MaxWalking)
		if #admitted == 0 then return end
		waiting = rest
		for _, job in ipairs(admitted) do job.start() end
	end
end

-- choosing ----------------------------------------------------------------------------------------------------------

-- WalkIn_Choose: choice `index` (1..#choices; 0 = WALK AWAY) on the arrived card `token`, applied exactly once.
-- Returns { ok = true, result = ResultPayload } ({ ok = true } for WALK AWAY) or { ok = false, reason = stale|invalid|afford }
function M.Choose(player, token, index)
	local uid = player.UserId
	local rec = pending[uid]
	if not rec or type(token) ~= "string" or token ~= rec.token or not rec.arrived then return { ok = false, reason = "stale" } end
	local choices = rec.item.choices or {}
	if type(index) ~= "number" or index ~= math.floor(index) or index < 0 or index > #choices then return { ok = false, reason = "invalid" } end
	pending[uid] = nil -- cleared before anything is applied: the same token again is stale
	local handle = rec.handle
	if index == 0 then
		handle:Leave()
		send(player, "leave", { token = token })
		remaining[uid] = nextGap(player, true)
		track(player, "CardWalkAway", rec.id)
		return { ok = true }
	end
	local have = Career.Get(player) -- a fresh copy; level from the profile, never the Level attribute
	have.level = ctx.Data.GetProfile(player).level
	-- your beat: a beat choice tilts by the arrival snapshot's quality, which a beatMin choice goes by (CareerSim rolls the same)
	local choice = choices[index]
	local res = Rules.Resolve(choice, have, W.Odds, rngFor(uid), tiltOf(rec, choice), beatQOf(rec))
	local cost = res.ok and res.deltas.cost or 0
	if not res.ok or (cost > 0 and not ctx.Data.SpendCred(player, cost)) then
		pending[uid] = rec -- refused before anything applied: the card stays open
		return { ok = false, reason = "afford" }
	end
	local applied, planted, result
	local ok, err = pcall(function()
		applied, planted = apply(player, res, rec.item, cost)
		result = resultOf(rec, res.outcome, applied, planted)
		result.hint = hint(player, resultTexts(result))
		handle:Say(rec.fill(res.outcome.line))
		showTag(player, applied, res.outcome.tone)
	end)
	if not ok then -- nothing stays behind: he leaves, the card closes, the timer runs again
		report("choose " .. rec.id .. ": " .. tostring(err))
		handle:Leave()
		send(player, "leave", { token = token })
		remaining[uid] = nextGap(player, true)
		return { ok = false, reason = "stale" }
	end
	send(player, "result", result)
	track(player, "CardChoice", rec.id, index .. ":" .. tostring(res.outcome.key))
	task.delay(2, function() handle:Leave() end)
	remaining[uid] = nextGap(player, true)
	return { ok = true, result = result }
end

-- scheduling --------------------------------------------------------------------------------------------------------

-- the tour gate: done or skipped, or no walk-in yet (count 0: the first-ever visit comes without it, design 4.4)
local function tourOk(p, st) return st.count == 0 or Tour.State(p).done end

-- one scheduler check for p with the presence timer run out; true when it started a visit (queued for a walking slot).
-- Refused while a phone DM is open (PhoneBusy, set by Systems/Phone): one card at a time
local function schedule(p)
	local uid = p.UserId
	if pending[uid] or p:GetAttribute("PhoneBusy") == true or not inHub(p) or not cypherIdle() then return false end
	local st = state(p)
	if not tourOk(p, st) then return false end
	local day = st.day
	local can = Rules.CanSchedule(st, utcDay(), M.DailyMaxFor(p)) -- rolls a new UTC day over first; Cold.dailyMax while cold
	if st.day ~= day then ctx.Data.MarkDirty(p) end
	if not can then return false end
	local pick = nextPick(p, st)
	if not pick then remaining[uid] = nextGap(p, false); return false end
	local rec = newRecord(p, pick)
	table.insert(waiting, { uid = uid, rec = rec, start = function() walkIn(rec) end })
	pump()
	return true
end

-- the heal attempt now: Aura in the red moves up to AuraHeal's max toward 0 (CareerRules.HealAmount) through the
-- reward gate (Career.Add "AuraHeal", dailyMax 1 a UTC day); a heal that pays toasts the amount. Returns what it paid
local function healNow(p)
	local n = CareerRules.HealAmount(Career.Get(p).aura, Config.Career.Sources.AuraHeal.aura.max)
	if n <= 0 then return 0 end
	local paid = Career.Add(p, "aura", n, "AuraHeal")
	if paid > 0 then -- the toast can't fail the heal: it was paid (send()'s rule)
		local ok, err = pcall(function() RS.OK.Remotes.InteractionEvent:FireClient(p, "Toast", { text = "the internet forgot. +" .. paid .. " AURA" }) end)
		if not ok then report("heal toast: " .. tostring(err)) end
	end
	return paid
end
-- the loop's heal (in the hub, the hold off): one try once HEAL_SECONDS in-hub seconds of this session's UTC day have
-- passed, so a player still here after UTC midnight gets the new day's
local function heal(p)
	local uid, day = p.UserId, utcDay()
	local h = heals[uid]
	if not h or h.day ~= day then h = { day = day, seconds = 0 }; heals[uid] = h end
	if h.done then return end
	h.seconds += 1
	if h.seconds < HEAL_SECONDS then return end
	h.done = true
	healNow(p)
end

-- the 1 s loop's step for one player: the heal clock; the first arm on entering the hub (FirstEver while no walk-in has
-- come yet, count 0; else FirstDelay); presence counts only in the hub, only between visits, and not behind an open
-- phone DM (PhoneBusy), so a walk-in never fires the moment a DM closes: a timer that already ran out behind it is
-- re-armed (nextGap), and during a burst one under the short minimum is raised to it
local function tick(p)
	local uid = p.UserId
	if not ready[uid] then return end
	local here = inHub(p)
	if here and not held() then heal(p) end
	if remaining[uid] == nil then
		if here then remaining[uid] = between((state(p).count == 0 and W.FirstEver) or W.FirstDelay) end
		return
	end
	if not here or pending[uid] then return end
	if p:GetAttribute("PhoneBusy") == true then
		-- a run-out timer (behind a cypher or the cap) is re-armed so a DM close can't fire it; during a burst the timer is
		-- floored at the short minimum, so a DM opened between burst cards still leaves a short gap after its choice
		if remaining[uid] <= 0 then remaining[uid] = nextGap(p, true)
		elseif rush[uid] then remaining[uid] = math.max(remaining[uid], W.Rush.Short[1]) end
		return
	end
	remaining[uid] = math.max(0, remaining[uid] - 1)
	if remaining[uid] <= 0 then schedule(p) end
end

-- what Systems/Life plants -----------------------------------------------------------------------------------------

-- a follow-up the system plants, not an outcome: Systems/Life's tier visit, due in at = { lo, hi } walk-ins, drawn like every
-- plant (rngFor), and at the moment of the crossing: inside an outcome's apply that is before the outcome's own plant (see
-- apply's rng order). Before any walk-in both ends move one later (Rules.AfterFirst), so it can never take the first
-- slot. Returns the queue entry; nil, "queued" for one already queued or already seen (once ever); nil for an unknown id
-- or before Init
function M.PlantSystem(p, id, at)
	if not ctx or not Content.FollowupById[id] then return nil end
	local st = state(p)
	if (st.seen[id] or 0) > 0 then return nil, "queued" end
	local entry = Rules.Plant(st, { id = id, at = Rules.AfterFirst(st, at) }, W.FollowupAt, rngFor(p.UserId))
	if not entry then return nil, "queued" end
	ctx.Data.MarkDirty(p)
	return entry
end

-- what Systems/Phone asks before a pop ----------------------------------------------------------------------------

-- a visit is in flight for p (waiting for a walking slot, walking, or his card open). Safe before Init
function M.Busy(p) return pending[p.UserId] ~= nil end

-- is a walk-in due within s seconds? The presence timer is set and at or under s, and every scheduler check would pass
-- now: in the hub, the tour gate (tourOk: done, or count 0), the cypher idle, today under DailyMaxFor (a new UTC day rolls
-- over first). The timer alone is never read as "due": a capped player's sits at 0 for the day. The pause blocks it
-- unless ignorePause (the Phone hook's Tick runs under the suite's pause)
function M.DueWithin(p, s, ignorePause)
	if not ignorePause and paused() then return false end
	local left = remaining[p.UserId]
	if left == nil or left > s then return false end
	if not inHub(p) or not cypherIdle() then return false end
	local st = state(p)
	if not tourOk(p, st) then return false end
	local day = st.day
	local can = Rules.CanSchedule(st, utcDay(), M.DailyMaxFor(p))
	if st.day ~= day then ctx.Data.MarkDirty(p) end
	return can
end

-- a beat of theirs aired on the monitors this session (Pick opts.aired)
function M.Aired(p) return aired[p.UserId] == true end

-- fn(player) runs inside the hook Reset, before it returns (module-level, so Init order doesn't matter)
function M.OnReset(fn) table.insert(onReset, fn) end

-- an in-flight visit ends when it expires or its target is no longer in the hub (or the server). While another visit
-- waits for a walking slot, a standing visitor gives his up after ExpireBusySeconds (a card left open at the beat maker
-- or by an AFK player must not hold one of the MaxWalking slots for the whole ExpireSeconds). A deferred card's
-- visitor says the next W.WaitLines line (cycling) once WaitLineSeconds have passed since the last one (or the deferral)
local function upkeep(rec, now)
	local limit = (#waiting > 0) and (W.ExpireBusySeconds or 90) or W.ExpireSeconds
	if rec.arrived and now - rec.arrivedAt >= limit then endVisit(rec, "expired"); return end
	if not inHub(rec.player) then endVisit(rec, "left_hub"); return end
	local lines = Content.WaitLines
	if rec.deferred and #lines > 0 and now - rec.lineAt >= W.WaitLineSeconds then
		rec.lineAt = now
		rec.lineIndex = (rec.lineIndex or 0) % #lines + 1
		rec.handle:Say(rec.fill(lines[rec.lineIndex]))
	end
end

local function loop()
	while true do
		task.wait(1)
		local now, recs = os.clock(), {}
		for _, rec in pairs(pending) do table.insert(recs, rec) end
		for _, rec in ipairs(recs) do
			local ok, err = pcall(upkeep, rec, now)
			if not ok then report(err) end
		end
		if not paused() then
			for _, p in ipairs(Players:GetPlayers()) do
				local ok, err = pcall(tick, p)
				if not ok then report(err) end
			end
		end
	end
end

local function dropWaiting(uid)
	local keep = {}
	for _, job in ipairs(waiting) do if job.uid ~= uid then table.insert(keep, job) end end
	waiting = keep
end

local function onJoin(p)
	p.CharacterAdded:Connect(function()
		local rec = pending[p.UserId]
		if rec then endVisit(rec, "respawn") end -- a respawn sends him out
	end)
	task.spawn(function()
		ctx.Data.GetProfile(p)
		if p.Parent == Players then ready[p.UserId] = true end
	end)
end
local function onLeave(p)
	local uid = p.UserId
	local rec = pending[uid]
	if rec then endVisit(rec, "left_server") end
	dropWaiting(uid)
	endRush(p)
	ready[uid], remaining[uid], forced[uid], aired[uid], heals[uid] = nil, nil, nil, nil, nil
	if sentLog then sentLog[uid] = nil end
end

-- Studio-only test seam ---------------------------------------------------------------------------------------------

-- the hook's Spawn: skips pause, presence, tour, cypher, DailyMax and MaxWalking; still the hub and one per player.
-- id = a card or follow-up id (stored as the pick), nil = the scheduler's own pick
local function spawnNow(p, id)
	if pending[p.UserId] or not inHub(p) then return false end
	local st = state(p)
	local pick
	if id == nil then
		pick = nextPick(p, st)
	else
		pick = pickOf(st, Content.CardById[id] and "card" or "followup", id, true)
		if pick then st.next = { kind = pick.kind, id = pick.id }; ctx.Data.MarkDirty(p) end
	end
	if not pick then return false end
	return walkIn(newRecord(p, pick))
end

-- n decoys (no card: they walk to p and leave on arrival) through the walking limit
local function spawnExtra(p, n)
	if not inHub(p) then return 0 end
	for i = 1, n do
		local v = ARTISTS[(i - 1) % #ARTISTS + 1]
		local def = { id = v.id, name = NAMES[v.id] or v.id, style = v.style, color = v.color, sig = v.sig }
		table.insert(waiting, { uid = p.UserId, start = function()
			if inHub(p) then spawnVisitor(def, p, function(h) h:Leave() end) end
		end })
	end
	pump()
	return n
end

-- state back to defaults (day = today; phone and caps go with it), no visit in flight, none of p's visitors out or
-- waiting, timer far off, no burst (BusyDay off); then the OnReset list (Phone's pops, PhoneBusy and timer), inline, so
-- nothing carries into the next test
local function reset(p)
	local uid = p.UserId
	local rec = pending[uid]
	pending[uid] = nil
	dropWaiting(uid) -- before the destroys below, whose onGone admits the next in line
	local mine = {}
	for h, target in pairs(live) do if target == uid then table.insert(mine, h) end end
	for _, h in ipairs(mine) do h:Destroy() end
	if rec then send(p, "leave", { token = rec.token }) end
	ctx.Data.GetProfile(p).walkins = newState(utcDay())
	ctx.Data.MarkDirty(p)
	forced[uid] = nil
	remaining[uid] = 1e6
	endRush(p)
	for _, fn in ipairs(onReset) do
		local ok, err = pcall(fn, p)
		if not ok then warn("[OK][ERR] reset hook: " .. tostring(err)) end
	end
	return true
end

local function makeHook()
	local SOK = game:GetService("ServerScriptService"):FindFirstChild("OK")
	if not SOK then return end
	local hook = SOK:FindFirstChild("_StudioWalkInHook") or Instance.new("BindableFunction")
	hook.Name = "_StudioWalkInHook"; hook.Parent = SOK
	sentLog = sentLog or {}
	hook.OnInvoke = function(cmd, userId, a, b)
		if cmd == "Pause" then RS.OK:SetAttribute("WalkInsPaused", a == true); return true end
		if cmd == "Walking" then return liveCount end
		if cmd == "Waiting" then return #waiting end
		local p = Players:GetPlayerByUserId(userId)
		if not p then return nil end
		local uid = p.UserId
		if cmd == "Spawn" then return spawnNow(p, a) end
		if cmd == "SpawnExtra" then return spawnExtra(p, math.clamp(math.floor(tonumber(a) or 0), 0, 20)) end
		if cmd == "Poke" then -- one scheduler check with the timer at 0, paused or not
			local before = remaining[uid]
			remaining[uid] = 0
			local spawned = schedule(p)
			if not spawned then remaining[uid] = before end
			return spawned
		end
		if cmd == "SetRemaining" then remaining[uid] = tonumber(a); return true end
		if cmd == "GetRemaining" then return remaining[uid] end
		if cmd == "Rush" then -- k (Rush.Size) = the next re-arm starts a burst of k, whatever the hold (never while cold or
			-- before the tour: nextGap ends it); 0 = no burst;
			-- no k = { left, saved, busy } of the burst under way, or nil
			if a == nil then
				local r = rush[uid]
				return r and { left = r.left, saved = r.saved, busy = p:GetAttribute("BusyDay") == true } or nil
			end
			local k = tonumber(a)
			if k == 0 then endRush(p); return true end
			if not k or k ~= math.floor(k) or k < W.Rush.Size[1] or k > W.Rush.Size[2] then return false end
			rush[uid] = { left = k, saved = 0 }
			return true
		end
		if cmd == "Heal" then return healNow(p) end -- past the hold and the session memory, never the gate
		if cmd == "DailyMaxFor" then return M.DailyMaxFor(p) end -- today's cap (Wave 3: Cold.dailyMax while cold)
		if cmd == "Rel" then return relCopy(state(p).rel) end -- the relationships (Wave 3), a copy
		if cmd == "SetRel" then -- replaced by a copy of `a` (not a table: none), repaired by state() with no report; returns what it kept
			local st, rel = state(p), {}
			for id, e in pairs(type(a) == "table" and a or {}) do
				if type(e) == "table" then rel[id] = { score = e.score, flags = type(e.flags) == "table" and table.clone(e.flags) or e.flags } end
			end
			st.rel = rel
			ctx.Data.MarkDirty(p)
			return relCopy(state(p).rel)
		end
		if cmd == "Reset" then return reset(p) end
		if cmd == "SetToday" then local st = state(p); st.today = tonumber(a) or 0; st.day = utcDay(); ctx.Data.MarkDirty(p); return true end
		if cmd == "SetDay" then local st = state(p); st.day = tonumber(a) or 0; ctx.Data.MarkDirty(p); return true end
		if cmd == "AdvanceVisits" then local st = state(p); st.count += tonumber(a) or 0; ctx.Data.MarkDirty(p); return true end
		if cmd == "Choose" then return M.Choose(p, a, b) end
		if cmd == "Pending" then -- news = the key of the news he arrived with
			local r = pending[uid]
			return r and { token = r.token, id = r.id, arrived = r.arrived, news = r.news } or nil
		end
		if cmd == "Expire" then local r = pending[uid]; if not r then return false end; endVisit(r, "hook"); return true end
		if cmd == "Age" then -- every clock on the open card moves `a` seconds back: the arrival, the deferral's start and
			-- its last waiting line (the next 1 s upkeep applies the expiry rules and the next line)
			local r = pending[uid]
			if not r or not r.arrived or type(a) ~= "number" then return false end
			r.arrivedAt -= a
			if r.deferredAt then r.deferredAt -= a end
			if r.lineAt then r.lineAt -= a end
			return true
		end
		if cmd == "SetDeferred" then return setDeferred(p, a, b == true) end -- the WalkIn_Deferred path
		if cmd == "Sent" then local log = sentLog[uid] or {}; sentLog[uid] = nil; return log end
		if cmd == "SetRng" then forced[uid] = type(a) == "table" and table.clone(a) or nil; return true end
		if cmd == "Plant" then -- that follow-up is due now (at = count + 0); false for an unknown id or one already queued
			if not Content.FollowupById[a] then return false end
			local st = state(p)
			local entry = Rules.Plant(st, { id = a, at = { 0, 0 } }, W.FollowupAt, rngFor(uid))
			ctx.Data.MarkDirty(p)
			return entry ~= nil
		end
		if cmd == "SetCaps" then -- { [group] = { key, n } }
			local st, caps = state(p), {}
			for group, c in pairs(type(a) == "table" and a or {}) do caps[group] = { key = c.key, n = c.n } end
			st.caps = caps
			ctx.Data.MarkDirty(p)
			return true
		end
		if cmd == "Caps" then
			local caps = {}
			for group, c in pairs(state(p).caps) do caps[group] = { key = c.key, n = c.n } end
			return caps
		end
		return nil
	end
end

function M.Init(c)
	ctx = c
	local R = RS.OK.Remotes
	walkInEv = R.WalkIn
	R.WalkIn_Choose.OnServerInvoke = function(player, token, index) return M.Choose(player, token, index) end
	R.WalkIn_Deferred.OnServerEvent:Connect(function(player, token, deferred) setDeferred(player, token, deferred == true) end)
	-- your beat changed (a delivery, a FIRE): an arrived card waiting or on screen re-takes its snapshot (fix round 1)
	Contracts.RecentChanged:Connect(function(p)
		local rec = typeof(p) == "Instance" and pending[p.UserId] or nil
		if rec then refreshSafe(rec) end
	end)
	if c.Monitors then -- a beat aired this session; a cypher entry airs anonymously but counts for its real producer
		c.Monitors.Aired:Connect(function(entry)
			local uid = entry.realUid or entry.uid
			if uid then aired[uid] = true end
		end)
	end
	Players.PlayerAdded:Connect(onJoin)
	Players.PlayerRemoving:Connect(onLeave)
	for _, p in ipairs(Players:GetPlayers()) do onJoin(p) end
	task.spawn(loop)
	if RunService:IsStudio() and RunService:IsRunning() then makeHook() end
end

return M
