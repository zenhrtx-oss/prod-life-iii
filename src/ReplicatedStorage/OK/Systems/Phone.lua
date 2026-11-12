-- OK Studio system: the phone. DMs and NEWS (Data/WalkIns cards with source = "phone", and phone follow-ups) pop on
-- the player's phone anywhere in the game, on a per-player timer that runs only in eligible time (design 4.1): the
-- tour done, no cypher round holding the player (WalkInRules.CypherHolds: one that listens or votes holds everyone; a
-- lobby, the build and the reveal hold only that round's entrants), no walk-in in flight or due within
-- Config.Phone.WalkInDueSeconds, no opened DM awaiting
-- its choice (the PhoneBusy player attribute, which also holds the walk-in scheduler), and the send gate: fewer than
-- MaxWaiting un-opened pops, and today's opened pops plus the un-opened ones under DailyMax (a waiting pop holds its
-- day slot until it opens or is dropped). The first pop FirstDelay after the later of joining and finishing the tour,
-- then Gap between pops.
-- * A pop is picked and sent at once (Seed, then WalkInRules.Pick with source "phone" and every pending id excluded,
--   so two waiting pops never share a card or a follow-up; MarkSent starts an artist sender's cooldown across both
--   sources). It counts when it OPENS (Phone_Open): the phone's own counters prof.walkins.phone (never the walk-in
--   count), seen and the group cap. A DM then holds PhoneBusy until Phone_Choose(token, index) resolves it (0 =
--   dismiss; the same Resolve and hidden odds as walk-ins, on the career with level = prof.level, so a `ready` choice
--   reads the server's level); a NEWS applies its sure outcome at open and sends its result. A phone follow-up pops as NEWS and must still be queued at its first open (TakeQueued), else it is
--   dropped quietly.
-- * Money path: a choice's cost through DataService.SpendCred; the outcome's money is never applied (pops never pay,
--   design 4.8); Aura and Followers through Career.Add "Phone" / Career.Take, no other stat. An outcome's xp (two
--   sessions) through DataService.AddXP "Phone" (Config.XP.Sources.Phone: max 60, dailyMax 3); the result's xp chip
--   shows what the gate paid, none for 0.
-- * An un-opened pop expires after ExpireSeconds, an opened DM after OpenExpireSeconds (as a dismiss: it stays
--   counted); a respawn and the Reset hooks (this system's, and WalkIns' through WalkIns.OnReset) drop every pending
--   pop. Each drop sends ("expire", { token }), so the client never keeps a card the server lost. Leaving clears
--   silently.
-- * Explainers (Wave 3 design 4.5, through WalkIns.Hint, which marks each one seen): a pop's card carries hint =
--   { term, text } for the first unseen term in its line and choice texts as sent (a pop shows no tag), and a result
--   one for its headline and text, except a NEWS whose pop already carried one (a NEWS is one card: its result
--   replaces the message at once, and PhoneUI keeps showing the pop's hint under it).
-- * The cold spell (Wave 3, design 4.2; the state is Systems/Career's): while Career.IsCold, canSend is false, so no pop
--   comes and the timer stands still. The spell's one NEWS card, cold_news (a `system` card the normal pick never draws),
--   comes through M.SendSystem(player, id): once the player's profile is ready, they have a character (so the first
--   spawn's drop has run) and the tour is done, it sends that system card at once, past canSend (the waiting cap and the
--   day's cap) and whatever was seen before, unless one with that id already waits; it opens and counts like any pop
--   (the day's phone total, seen), and its open tells Career it was shown (Career.SystemShown: cold.news). Until then
--   Career sends it again from every ColdCheck, and this loop asks Career each second (Career.SendColdNews), so a card
--   dropped by a respawn, a leave or the expiry comes back, and a spell that started before the tour gets its card once
--   the tour ends. M.Withdraw(player, id) takes an unopened one back (a thaw), uncounted, with its "expire".
-- * They remember you (Wave 3, design 4.3): an outcome's `rel` (a DM's choice or any NEWS: a NEWS card's one choice, a
--   phone follow-up's news) goes through WalkIns.WriteRel, the relationships' one writer (two_sessions writes to the
--   hometown kid); the pick passes prof.walkins.rel as opts.rel. A rolled choice on a phone card tilts by the card's
--   visitor's score as a walk-in's does (fix round 1, the controller's 11-06 ruling: a DM from mom is mom's card), through
--   the one rule WalkIns.RelTiltFor: a sure choice (every NEWS card's) never does, nor a sender nobody has a relationship
--   with (score 0), nor a follow-up's news (ResolveNews takes no tilt).
-- * Telemetry (Systems/Funnel, source "phone"): PhoneOpen (detail = the app), PhoneExpire (detail waited | opened |
--   taken), CardChoice ("<index>:<outcome key>"; a count, value 1), CardReady after a `ready` choice's CardChoice
--   (detail = the outcome key, value = the readiness x 100, rounded), CardWalkAway, CardNews (the outcome key).
-- * Remotes: Phone (server -> client: "pop", "result", "expire"), Phone_Open, Phone_Choose. The scheduler honours
--   ReplicatedStorage.OK's WalkInsPaused attribute like Systems/WalkIns (the expiry sweep runs while paused). The
--   Studio-only hook ServerScriptService.OK._StudioPhoneHook drives it in tests (its Sent lists { kind, token, hint } per
--   send since the last call); its Quiet(uid, on) keeps "pop" and
--   "result" from reaching that client and drops its Phone_Open / Phone_Choose, so server tests never open a live card,
--   and its ReadyChance(uid, cardId, index) returns the chance Choose would roll that choice at now (WalkInRules.
--   RollChance at prof.level, with the relationship tilt); CanSend(uid) reads the send gate (Wave 3: false while cold).
local RS, Players = game:GetService("ReplicatedStorage"), game:GetService("Players")
local RunService, Http = game:GetService("RunService"), game:GetService("HttpService")
local Config = require(RS.OK.Config)
local Rules = require(RS.OK.Modules.WalkInRules)
local CareerRules = require(RS.OK.Modules.CareerRules)
local Content = require(RS.OK.Data.WalkIns)
local Career = require(RS.OK.Systems.Career)
local Tour = require(RS.OK.Systems.Tour)
local WalkIns = require(RS.OK.Systems.WalkIns)

local P, W = Config.Phone, Config.WalkIns
-- the phone lives in the walk-in state (WalkIns.State), so it runs only while walk-ins do
local M = { Enabled = P.Enabled ~= false and W.Enabled ~= false, Version = 1 }
local STUDIO = RunService:IsStudio()
local SOURCE = "Phone" -- the Career.Add source (Config.Career.Sources.Phone: Aura and Followers only)

local ctx, phoneEv
local ready = {}     -- [userId] = true once the profile has loaded
local remaining = {} -- [userId] = eligible seconds until the next pop; nil = not armed yet (FirstDelay when it is)
local pending = {}   -- [userId] = { { token, id, kind = "dm" | "news", item, entry?, fill, sentAt, openedAt?, opened } }
local forced = {}    -- [userId] = SetRng values still to hand out (Studio hook)
local quiet = {}     -- [userId] = true: Studio test isolation (see the header); Reset never clears it, leaving does
local sentLog = {}   -- Studio only: [userId] = { { kind, token } } since the hook's last Sent
local timeRng, drawRng = Random.new(), Random.new() -- FirstDelay/Gap, and the draws SetRng does not cover

local function report(msg) warn("[OK][ERR] phone: " .. tostring(msg)) end
-- telemetry (Systems/Funnel, required lazily like WalkIns does; a failure never touches the pop); value nil = Funnel's 1
local function track(p, name, id, detail, value)
	pcall(function() require(RS.OK.Systems.Funnel).Event(p, name, value, { source = "phone", card = id, detail = detail }) end)
end
local function paused() return STUDIO and RS.OK:GetAttribute("WalkInsPaused") == true end
local function utcDay() return ctx.Data._day() end
-- the career a choice resolves against: Career.Get (a fresh copy) with level = prof.level, read on the server (the
-- Level attribute is never trusted). Choose and the hook's ReadyChance both use it, so the hook can't drift from the roll
local function careerOf(p)
	local have = Career.Get(p)
	have.level = ctx.Data.GetProfile(p).level
	return have
end
local function between(range) return timeRng:NextInteger(range[1], range[2]) end
-- does a cypher round hold p's phone (WalkInRules.CypherHolds on its Phase and Round and p's CypherIn)? RS.OK.Cypher is
-- made by BeatBattles' Init, and no folder (or no phase) holds nothing
local function cypherHolds(p)
	local cy = RS.OK:FindFirstChild("Cypher")
	return Rules.CypherHolds(cy and cy:GetAttribute("Phase"), p:GetAttribute("CypherIn"), cy and cy:GetAttribute("Round"))
end
-- one player's Pick / Resolve / ResolveNews / Plant draws: SetRng values first (held to [lo, hi]), then random. The
-- phone's own list and Random, never WalkIns' (its tests force walk-in draws)
local function rngFor(uid)
	return function(lo, hi)
		if hi <= lo then return lo end
		local list = forced[uid]
		if list and #list > 0 then return math.clamp(math.floor(tonumber(table.remove(list, 1)) or lo), lo, hi) end
		return drawRng:NextInteger(lo, hi)
	end
end
-- every send: recorded for the hook's Sent (Studio), then the remote; "pop" and "result" stay on the server while
-- Quiet is on for p, "expire" always goes out
local function send(p, kind, payload)
	if p.Parent ~= Players then return end
	local uid = p.UserId
	if STUDIO then
		local log = sentLog[uid] or {}
		sentLog[uid] = log
		table.insert(log, { kind = kind, token = payload.token, hint = payload.hint or (type(payload.card) == "table" and payload.card.hint) or nil })
	end
	if quiet[uid] and kind ~= "expire" then return end
	local ok, err = pcall(function() phoneEv:FireClient(p, kind, payload) end)
	if not ok then report("send " .. kind .. ": " .. tostring(err)) end
end

-- pending pops -------------------------------------------------------------------------------------------------------

local function find(uid, token)
	for _, e in ipairs(pending[uid] or {}) do
		if e.token == token then return e end
	end
	return nil
end
local function remove(uid, e)
	local list = pending[uid] or {}
	for i, x in ipairs(list) do
		if x == e then table.remove(list, i); return end
	end
end
local function unopened(uid)
	local n = 0
	for _, e in ipairs(pending[uid] or {}) do if not e.opened then n += 1 end end
	return n
end
-- PhoneBusy: set while an opened DM awaits its choice, cleared otherwise (walk-ins hold while it is set)
local function setBusy(p)
	local busy = false
	for _, e in ipairs(pending[p.UserId] or {}) do
		if e.opened and e.kind == "dm" then busy = true; break end
	end
	p:SetAttribute("PhoneBusy", busy or nil)
end

-- payloads ----------------------------------------------------------------------------------------------------------

-- the PhoneResult (WalkIns' ResultPayload plus source); planted = true when apply queued a follow-up (not a chip)
local function resultOf(e, outcome, applied, planted)
	local fill = e.fill
	return { token = e.token, key = outcome.key, headline = fill(outcome.headline), text = fill(outcome.text), tone = outcome.tone,
		chips = WalkIns.Chips(applied), note = fill(outcome.note), source = "phone", planted = planted or nil }
end
-- PopPayload (Shared shapes): a phone follow-up shows as NEWS with no choices; today after the day rollover
local function popOf(st, e)
	local item, fill = e.item, e.fill
	local v = Content.VisitorById[item.visitor]
	local choices = {}
	if not e.entry then
		for i, c in ipairs(item.choices or {}) do choices[i] = { text = fill(c.text), cost = (c.cost or 0) > 0 and c.cost or nil } end
	end
	Rules.Rollover(st.phone, utcDay())
	return { token = e.token, card = { id = e.id, app = e.entry and "NEWS" or item.app, line = fill(item.line), choices = choices,
		news = e.kind == "news", sender = { name = fill(WalkIns.Names[item.visitor] or item.visitor), color = v and v.color } },
		today = st.phone.today, max = P.DailyMax }
end

-- applying ----------------------------------------------------------------------------------------------------------

-- apply a Resolve / ResolveNews result after its cost was paid: Aura and Followers through the Phone source (losses
-- through Career.Take), XP through DataService.AddXP "Phone" (applied.xp = what the gate paid: 0 when it refused or
-- the outcome has none), the relationship write (WalkIns.WriteRel, Wave 3), a planted follow-up, a cooldown. The
-- outcome's money, placements, hits, sponsors and a sponsor deal are never applied here (the content validator keeps them off phone outcomes; live content carrying one is
-- reported). Returns the amounts actually applied, and whether the plant queued a follow-up (Plant returned an entry)
local function apply(p, res, item, cost)
	local d, o = res.deltas, res.outcome
	local st = WalkIns.State(p)
	local applied = { cost = cost, money = 0, xp = 0 }
	if d.money ~= 0 then report("outcome " .. tostring(o.key) .. " carries money (not applied)") end
	for _, stat in ipairs(CareerRules.STATS) do
		local n = d[stat] or 0
		if stat ~= "aura" and stat ~= "followers" then
			if n ~= 0 then report("outcome " .. tostring(o.key) .. " carries " .. stat .. " (not applied)") end
			applied[stat] = 0
		elseif n > 0 then applied[stat] = Career.Add(p, stat, n, SOURCE)
		elseif n < 0 then applied[stat] = -Career.Take(p, stat, -n)
		else applied[stat] = 0 end
	end
	if (d.xp or 0) > 0 then applied.xp = ctx.Data.AddXP(p, d.xp, "Phone") end
	if o.sponsor ~= nil then report("outcome " .. tostring(o.key) .. " carries a sponsor (not applied)") end
	if type(o.rel) == "table" then WalkIns.WriteRel(p, o.rel, item.visitor) end
	local planted = type(o.plant) == "table" and Rules.Plant(st, o.plant, W.FollowupAt, rngFor(p.UserId), { sponsor = item.sponsor }) ~= nil
	if type(o.cooldown) == "number" then st.last[item.visitor] = (st.last[item.visitor] or st.count) + o.cooldown end
	ctx.Data.MarkDirty(p)
	return applied, planted
end

-- the result for an entry already taken out of pending: apply, ("result", PhoneResult), log `event` (with `value`, nil
-- for Funnel's default). On an error nothing stays open: the client gets its expire and the error is reported. Returns
-- the result, or nil
local function deliver(p, e, res, cost, event, detail, value)
	local ok, result = pcall(function()
		local applied, planted = apply(p, res, e.item, cost)
		local r = resultOf(e, res.outcome, applied, planted)
		if not (e.kind == "news" and e.hint) then r.hint = WalkIns.Hint(p, WalkIns.ResultTexts(r)) end -- one per NEWS card
		return r
	end)
	if not ok then
		report("deliver " .. e.id .. ": " .. tostring(result))
		send(p, "expire", { token = e.token })
		return nil
	end
	send(p, "result", result)
	track(p, event, e.id, detail, value)
	return result
end

-- opening and choosing ----------------------------------------------------------------------------------------------

-- Phone_Open(token): the card is on screen. An unknown token gets ("expire") and nothing else. The first open counts
-- the pop (the phone counters after the day rollover, seen, the group cap) once a follow-up's queue entry is taken
-- (nil = already taken: dropped quietly, nothing counted or applied); a DM then waits for its choice under PhoneBusy,
-- a NEWS applies now. A second open of the same token does nothing, and a DM's open while another DM is open
-- (PhoneBusy) does nothing either: one open DM at a time, as WalkIns' one card at a time. It stays waiting, uncounted,
-- and opens once the first resolves or expires (or drops as waited at ExpireSeconds)
local function open(p, token)
	local uid = p.UserId
	local e = find(uid, token)
	if not e then send(p, "expire", { token = token }); return end
	if e.opened then return end
	if e.kind == "dm" and p:GetAttribute("PhoneBusy") == true then return end
	local st = WalkIns.State(p)
	if e.entry and not Rules.TakeQueued(st, e.entry) then
		remove(uid, e)
		send(p, "expire", { token = token })
		track(p, "PhoneExpire", e.id, "taken")
		return
	end
	Rules.Rollover(st.phone, utcDay())
	e.opened, e.openedAt = true, os.clock()
	st.phone.today += 1
	st.phone.count += 1
	st.seen[e.id] = (st.seen[e.id] or 0) + 1
	local day, week = Rules.CapKeys(ctx.Data._now())
	Rules.CountCap(st, e.item, day, week)
	ctx.Data.MarkDirty(p)
	track(p, "PhoneOpen", e.id, e.entry and "NEWS" or e.item.app)
	if e.item.system then -- a system card was shown (cold_news: the spell's news, Wave 3); never fails the open
		local okS, errS = pcall(Career.SystemShown, p, e.id)
		if not okS then report("system shown: " .. tostring(errS)) end
	end
	if e.kind == "dm" then setBusy(p); return end
	local have, rng = Career.Get(p), rngFor(uid)
	local res = e.entry and Rules.ResolveNews(e.item, have, W.Odds, rng) or Rules.Resolve(e.item.choices[1], have, W.Odds, rng)
	remove(uid, e)
	deliver(p, e, res, 0, "CardNews", res.outcome.key)
end

-- Phone_Choose: choice `index` (1..#choices; 0 = dismiss) on the opened DM `token`, applied exactly once. Returns
-- { ok = true, result = PhoneResult } ({ ok = true } for a dismiss) or { ok = false, reason = stale|invalid|afford }:
-- stale = the token is gone (the client drops the card), invalid = a NEWS, a DM not yet opened or a bad index (it keeps it)
function M.Choose(player, token, index)
	local uid = player.UserId
	local e = type(token) == "string" and find(uid, token) or nil
	if not e then return { ok = false, reason = "stale" } end
	if e.kind ~= "dm" or not e.opened then return { ok = false, reason = "invalid" } end
	local choices = e.item.choices or {}
	if type(index) ~= "number" or index ~= math.floor(index) or index < 0 or index > #choices then return { ok = false, reason = "invalid" } end
	if index == 0 then
		remove(uid, e)
		setBusy(player)
		track(player, "CardWalkAway", e.id)
		return { ok = true }
	end
	local choice = choices[index]
	local have = careerOf(player)
	-- a rolled choice tilts by the card's visitor's score, as a walk-in's does (fix round 1; WalkIns.RelTiltFor)
	local res = Rules.Resolve(choice, have, W.Odds, rngFor(uid), WalkIns.RelTiltFor(player, e.item, choice))
	local cost = res.ok and res.deltas.cost or 0
	if not res.ok or (cost > 0 and not ctx.Data.SpendCred(player, cost)) then return { ok = false, reason = "afford" } end
	remove(uid, e) -- before anything is applied: the same token again is stale, and PhoneBusy never outlives the card
	setBusy(player)
	local result = deliver(player, e, res, cost, "CardChoice", index .. ":" .. tostring(res.outcome.key))
	if not result then return { ok = false, reason = "stale" } end
	-- CardChoice stays a count; a ready choice also logs how ready the career was (0..100), from the snapshot the roll used
	if choice.ready then
		track(player, "CardReady", e.id, tostring(res.outcome.key), math.floor(Rules.Readiness(have, have.level, W.Odds.ready) * 100 + 0.5))
	end
	return { ok = true, result = result }
end

-- expiry and drops --------------------------------------------------------------------------------------------------

-- one player's expiry sweep: an un-opened pop older than ExpireSeconds, or an opened DM unanswered for
-- OpenExpireSeconds (a dismiss: it stays counted), is dropped with its expire and PhoneExpire. Returns how many
local function sweep(p, now)
	local uid = p.UserId
	local list = pending[uid]
	if not list then return 0 end
	local dropped = 0
	for i = #list, 1, -1 do
		local e = list[i]
		local why = (not e.opened and now - e.sentAt >= P.ExpireSeconds and "waited")
			or (e.opened and e.kind == "dm" and now - e.openedAt >= P.OpenExpireSeconds and "opened") or nil
		if why then
			table.remove(list, i)
			send(p, "expire", { token = e.token })
			track(p, "PhoneExpire", e.id, why)
			dropped += 1
		end
	end
	if dropped > 0 then setBusy(p) end
	return dropped
end

-- every pending pop goes (a respawn, the Reset hooks): an expire each; nothing counted, nothing logged
local function dropAll(p)
	local uid = p.UserId
	for _, e in ipairs(pending[uid] or {}) do send(p, "expire", { token = e.token }) end
	pending[uid] = nil
	p:SetAttribute("PhoneBusy", nil)
end
-- the Reset hooks (this system's, and WalkIns' through OnReset): the pops, PhoneBusy, the timer (FirstDelay applies
-- again) and the SetRng list. Never Quiet
local function reset(p)
	dropAll(p)
	remaining[p.UserId], forced[p.UserId] = nil, nil
end

-- picking and sending -----------------------------------------------------------------------------------------------

-- the Pick opts (Shared shapes; WalkIns and CareerSim pass the same): the artist cooldown (so an artist who just
-- walked in can't DM), this player's draws, the sponsor floor, the life gates against the career with visits = the
-- walk-in count, the cap keys, whether a beat aired this session, every pending pop's id excluded, and the relationships
-- (Wave 3: prof.walkins.rel, the `flags` and `rel` gates; state() has defaulted it)
local function pickOpts(p, st)
	local uid = p.UserId
	local have = Career.Get(p)
	local career = table.clone(have)
	career.visits = st.count
	local day, week = Rules.CapKeys(ctx.Data._now())
	local exclude = {}
	for _, e in ipairs(pending[uid] or {}) do exclude[e.id] = true end
	return { cooldown = W.ArtistCooldown, rng = rngFor(uid), sponsored = have.sponsor ~= nil, aura = have.aura,
		source = "phone", career = career, day = day, week = week, aired = WalkIns.Aired(p), exclude = exclude, rel = st.rel }, have
end
-- { kind, id, item, entry? } for a WalkInRules.Pick result; nil for nil
local function pickFrom(res)
	if not res then return nil end
	if res.kind == "card" then return { kind = "card", id = res.card.id, item = res.card } end
	return { kind = "followup", id = res.entry.id, item = res.followup, entry = res.entry }
end
-- send the pick now: the pending entry, ("pop", PopPayload), then the sender's cooldown (MarkSent). Returns the token
local function sendPop(p, st, pick, have)
	local uid = p.UserId
	local item = pick.item
	local entryCtx = pick.entry and type(pick.entry.ctx) == "table" and pick.entry.ctx or {}
	local e = { token = Http:GenerateGUID(false), id = pick.id, kind = (pick.entry or item.news) and "news" or "dm", item = item,
		entry = pick.entry, fill = WalkIns.Filler(item.sponsor or entryCtx.sponsor or have.sponsor), sentAt = os.clock(), opened = false }
	local list = pending[uid] or {}
	pending[uid] = list
	table.insert(list, e)
	local payload = popOf(st, e)
	payload.card.hint = WalkIns.Hint(p, WalkIns.CardTexts(payload.card)) -- its line and choices (a pop shows no tag)
	e.hint = payload.card.hint
	send(p, "pop", payload)
	Rules.MarkSent(st, item, Content.Deck)
	ctx.Data.MarkDirty(p)
	return e.token
end
-- the scheduler's send: Seed, Pick, send; the timer restarts with Gap either way. Returns the token, or nil
local function schedule(p)
	local st = WalkIns.State(p)
	local opts, have = pickOpts(p, st)
	Rules.Seed(st, Content.Deck, opts)
	local pick = pickFrom(Rules.Pick(st, Content.Deck, opts))
	ctx.Data.MarkDirty(p)
	remaining[p.UserId] = between(P.Gap)
	return pick and sendPop(p, st, pick, have) or nil
end

-- scheduling --------------------------------------------------------------------------------------------------------

-- the send gate (Shared shapes "Phone rules"): un-opened pops under MaxWaiting, and after the day rollover, today's
-- opened pops plus the un-opened ones under DailyMax (a waiting pop holds its slot until it opens or is dropped)
local function canSend(p)
	if Career.IsCold(p) then return false end -- the cold spell: no pops (Wave 3)
	local n = unopened(p.UserId)
	if n >= P.MaxWaiting then return false end
	local st = WalkIns.State(p)
	local day = st.phone.day
	Rules.Rollover(st.phone, utcDay())
	if st.phone.day ~= day then ctx.Data.MarkDirty(p) end
	return st.phone.today + n < P.DailyMax
end
-- eligible time (design 4.1): the timer runs only while every one of these holds
local function eligible(p, ignorePause)
	if not Tour.State(p).done or cypherHolds(p) then return false end
	if WalkIns.Busy(p) or WalkIns.DueWithin(p, P.WalkInDueSeconds, ignorePause) then return false end
	if p:GetAttribute("PhoneBusy") == true then return false end
	return canSend(p)
end
-- a system card (Data/WalkIns `system = true`, a phone NEWS card the normal pick never draws: cold_news) sent to p now:
-- past canSend and the seen check, never before the player's profile is ready, a character exists (the first spawn's
-- CharacterAdded drops every pending pop) and the tour is done, and never while one with that id already waits. It is an
-- ordinary pending pop from here (opened, counted on the day's phone total and applied like any NEWS; its open calls
-- Career.SystemShown). Returns its token, or nil (before Init, an id that isn't a phone system card, not ready, no
-- character, the tour not done, one already waiting, a player not here)
function M.SendSystem(p, id)
	if not ctx or typeof(p) ~= "Instance" or p.Parent ~= Players then return nil end
	local card = type(id) == "string" and Content.CardById[id] or nil
	if not (card and card.system == true and card.source == "phone") then report("SendSystem: " .. tostring(id) .. " is not a phone system card"); return nil end
	if not ready[p.UserId] or not p.Character or not Tour.State(p).done then return nil end
	for _, e in ipairs(pending[p.UserId] or {}) do
		if e.id == id then return nil end -- never two waiting
	end
	local st = WalkIns.State(p)
	return sendPop(p, st, { kind = "card", id = id, item = card }, Career.Get(p))
end

-- every unopened pop of card `id` taken back (a thaw withdraws a stale cold_news): its "expire" goes out, nothing is
-- counted (a pop counts when it opens) or logged. Returns how many
function M.Withdraw(p, id)
	if not ctx or typeof(p) ~= "Instance" then return 0 end
	local list = pending[p.UserId]
	if not list then return 0 end
	local n = 0
	for i = #list, 1, -1 do
		local e = list[i]
		if e.id == id and not e.opened then
			table.remove(list, i)
			send(p, "expire", { token = e.token })
			n += 1
		end
	end
	if n > 0 then setBusy(p) end
	return n
end

-- s eligible seconds for p: the checks, then the timer (armed with FirstDelay the first time: the later of joining
-- and the tour's end is the first eligible tick) runs down by s, and a pop is sent at 0. Returns the token sent, or nil
local function tick(p, s, ignorePause)
	local uid = p.UserId
	if not ready[uid] or not eligible(p, ignorePause) then return nil end
	if remaining[uid] == nil then remaining[uid] = between(P.FirstDelay) end
	remaining[uid] = math.max(0, remaining[uid] - s)
	if remaining[uid] > 0 then return nil end
	return schedule(p)
end

local function loop()
	while true do
		task.wait(1)
		local now = os.clock()
		for _, p in ipairs(Players:GetPlayers()) do
			local ok, err = pcall(sweep, p, now)
			if not ok then report(err) end
		end
		if not paused() then
			for _, p in ipairs(Players:GetPlayers()) do
				local ok, err = pcall(tick, p, 1, nil)
				if not ok then report(err) end
				-- a cold spell's cold_news not sent yet (it waited for the tour): Career sends it once (Wave 3)
				if ready[p.UserId] then
					local okC, errC = pcall(Career.SendColdNews, p)
					if not okC then report("cold news: " .. tostring(errC)) end
				end
			end
		end
	end
end

local function onJoin(p)
	p.CharacterAdded:Connect(function() dropAll(p) end) -- a respawn drops the pops, as it sends a walk-in out
	task.spawn(function()
		ctx.Data.GetProfile(p)
		if p.Parent == Players then ready[p.UserId] = true end
	end)
end
local function onLeave(p)
	local uid = p.UserId
	pending[uid], ready[uid], remaining[uid], forced[uid], quiet[uid], sentLog[uid] = nil, nil, nil, nil, nil, nil
	p:SetAttribute("PhoneBusy", nil)
end

-- Studio-only test seam ---------------------------------------------------------------------------------------------

-- the hook's Pop: sends now, past the timer, the eligibility checks and DailyMax, but never MaxWaiting. No id = Seed
-- and Pick with the pending ids excluded; id = that phone card, or that phone follow-up while it is queued (nil
-- otherwise), exclude ignored. Returns the token, or nil
local function popNow(p, id)
	if unopened(p.UserId) >= P.MaxWaiting then return nil end
	local st = WalkIns.State(p)
	local opts, have = pickOpts(p, st)
	local pick
	if id == nil then
		Rules.Seed(st, Content.Deck, opts)
		pick = pickFrom(Rules.Pick(st, Content.Deck, opts))
	else
		local card, f = Content.CardById[id], Content.FollowupById[id]
		if card and card.source == "phone" then
			pick = { kind = "card", id = id, item = card }
		elseif f and f.source == "phone" then
			for _, q in ipairs(st.queue) do
				if q.id == id then pick = { kind = "followup", id = id, item = f, entry = q }; break end
			end
		end
	end
	if not pick then return nil end
	return sendPop(p, st, pick, have)
end

local function makeHook()
	local SOK = game:GetService("ServerScriptService"):FindFirstChild("OK")
	if not SOK then return end
	local hook = SOK:FindFirstChild("_StudioPhoneHook") or Instance.new("BindableFunction")
	hook.Name = "_StudioPhoneHook"; hook.Parent = SOK
	hook.OnInvoke = function(cmd, userId, a, b)
		local p = Players:GetPlayerByUserId(userId)
		if not p then return nil end
		local uid = p.UserId
		if cmd == "Quiet" then quiet[uid] = a == true or nil; return true end
		if cmd == "Reset" then reset(p); return true end
		if cmd == "Pop" then return popNow(p, a) end
		if cmd == "Tick" then return tick(p, tonumber(a) or 0, true) end -- the checks, then the timer, under the suite's pause
		if cmd == "Pending" then
			local out = {}
			for i, e in ipairs(pending[uid] or {}) do out[i] = { token = e.token, id = e.id, kind = e.kind, opened = e.opened } end
			return out
		end
		if cmd == "Open" then open(p, a); return true end
		if cmd == "Choose" then return M.Choose(p, a, b) end
		if cmd == "ReadyChance" then -- Resolve's chance for card `a`'s choice `b` now (RollChance, careerOf: prof.level, and the
			-- relationship tilt Choose adds); nil if none
			local card = Content.CardById[a]
			local choice = card and card.choices and card.choices[tonumber(b) or 0]
			if not choice then return nil end
			return Rules.RollChance(choice, careerOf(p), W.Odds, WalkIns.RelTiltFor(p, card, choice))
		end
		if cmd == "Age" then -- every pop was sent (and opened) `a` seconds earlier; the expiry sweep runs now
			local s = tonumber(a) or 0
			for _, e in ipairs(pending[uid] or {}) do
				e.sentAt -= s
				if e.openedAt then e.openedAt -= s end
			end
			return sweep(p, os.clock())
		end
		if cmd == "SetRemaining" then remaining[uid] = tonumber(a); return true end
		if cmd == "GetRemaining" then return remaining[uid] end
		if cmd == "SetToday" then local st = WalkIns.State(p); st.phone.today = tonumber(a) or 0; st.phone.day = utcDay(); ctx.Data.MarkDirty(p); return true end
		if cmd == "SetDay" then local st = WalkIns.State(p); st.phone.day = tonumber(a) or 0; ctx.Data.MarkDirty(p); return true end
		if cmd == "State" then local ph = WalkIns.State(p).phone; return { day = ph.day, today = ph.today, count = ph.count } end
		if cmd == "Busy" then return p:GetAttribute("PhoneBusy") == true end
		if cmd == "SetRng" then forced[uid] = type(a) == "table" and table.clone(a) or nil; return true end
		if cmd == "Sent" then local log = sentLog[uid] or {}; sentLog[uid] = nil; return log end
		if cmd == "CanSend" then return canSend(p) end -- the send gate now (Wave 3: false while cold)
		return nil
	end
end

function M.Init(c)
	ctx = c
	local R = RS.OK.Remotes
	phoneEv = R.Phone
	R.Phone_Open.OnServerEvent:Connect(function(player, token)
		if quiet[player.UserId] or type(token) ~= "string" then return end
		local ok, err = pcall(open, player, token)
		if not ok then report("open: " .. tostring(err)) end
	end)
	R.Phone_Choose.OnServerInvoke = function(player, token, index)
		if quiet[player.UserId] then return { ok = false, reason = "stale" } end
		return M.Choose(player, token, index)
	end
	WalkIns.OnReset(reset)
	Players.PlayerAdded:Connect(onJoin)
	Players.PlayerRemoving:Connect(onLeave)
	for _, p in ipairs(Players:GetPlayers()) do onJoin(p) end
	task.spawn(loop)
	if STUDIO and RunService:IsRunning() then makeHook() end
end

return M
