-- OK Studio system: Studio Sessions. Fictional artists (Data/Artists) send session requests; the player builds a beat
-- in the beat maker while the asks tick green (Modules/BriefCheck on the client), then DELIVERs it here for the real
-- grade: required asks = 2 stars, plus the bonus = 3 stars. A request pays XP and Cred the first time only; a repeat
-- still earns the credit line. The beat must be "yours": BriefCheck.MinChanged+ pads different from the default beat,
-- every preset, your last delivery and someone else's beat on the monitors.
-- prof.sessions = { active = briefId|nil, done = { [briefId] = best stars }, last = pattern, deliveries = n,
--                   recent = { { pattern, bpm, stars = 0..3, fires = n, day = careerDay }, ... }, lastDay = careerDay? }
-- prof.credits  = { { t = title, a = artist, s = stars, d = yyyymmdd }, ... } (newest last, capped)
-- Your beat (Wave 3, design 4.1): prof.sessions.recent, newest first, at most Config.WalkIns.RecentMax, is what you
-- delivered or played on the monitors (deliver never saves, so save slots don't track it). Every passed delivery (first
-- or repeat, any brief, dailies and the weekly too) records its beat through RecordDelivery (WalkInRules.RecentPush: the
-- same pattern merges, its stars the higher, and moves to the front); a FIRE to the producer (Reactions.Give, only while
-- the producer is online) adds one to the aired beat through CreditFire (WalkInRules.RecentFire: a beat aired without a
-- delivery joins at 0 stars, and when the list is full the lowest-quality older beat makes room, ties to the oldest, so a
-- FIRE never pushes out a better delivered beat: final review I2). `day` is the career day (prof.life.day). This module
-- is the only writer of prof.sessions;
-- BestBeat, Recent and SetRecent serve Systems/WalkIns and the Studio hooks, and every write fires RecentChanged(player),
-- so a walk-in card already on screen or waiting re-takes its beat (Systems/WalkIns, fix round 1).
-- The cold spell (Wave 3, design 4.2): prof.sessions.lastDay is the career day of the last passed delivery of any brief,
-- written by RecordDelivery on every pass (Deliver calls it; the Studio hook too), and a 3-star one runs
-- Career.ColdCheck(player, "delivery3"), one of the spell's two ways out. Systems/Career reads it through LastDay and,
-- being the spell's owner, sets it through TouchLastDay (CareerRules.LastDayStep): today on the first check that finds
-- none (that check itself reads none, so it can't go cold), today on a thaw, and today when the player is heard: a FIRE
-- to them or a cypher win (final review I1, ruling A of 2026-11-12).
-- It is left nil until then (never defaulted in state(), so no other read fixes the day early).
local RS, Players = game:GetService("ReplicatedStorage"), game:GetService("Players")
local Config = require(RS.OK.Config)
local Rules = require(RS.OK.Modules.WalkInRules)
local Artists = require(RS.OK.Data.Artists)
local Check = require(RS.OK.Modules.BriefCheck)
local Cfg = require(RS.OK.Modules.DAWConfig)
local DAW = require(RS.OK.Systems.DAW)
local DR = require(RS.OK.Modules.DailyRequests)
local Briefs = DR.Index(Artists) -- regular requests and today's dailies
local function dailies() return require(RS.OK.Systems.Dailies) end
local M = { Enabled = true, Version = 1 }
M.OfferCount = 3
M.CreditsCap = 50
M.DeliverCooldown = 2
local pickedEv, deliveredEv = Instance.new("BindableEvent"), Instance.new("BindableEvent")
local recentEv = Instance.new("BindableEvent")
M.Picked = pickedEv.Event       -- (player, brief)
M.Delivered = deliveredEv.Event -- (player, brief, stars, firstTime)
M.RecentChanged = recentEv.Event -- (player): prof.sessions.recent was written (RecordDelivery, CreditFire, SetRecent)
local ctx
local lastDeliver = {}

local function recentMax() return tonumber((Config.WalkIns or {}).RecentMax) or 3 end
-- one recent beat as stored, or nil when it isn't one: a pattern string, a bpm number; stars 0..3, fires and day whole
local function beatOf(e)
	if type(e) ~= "table" or type(e.pattern) ~= "string" or e.pattern == "" or type(e.bpm) ~= "number" then return nil end
	return { pattern = e.pattern, bpm = e.bpm, stars = math.clamp(math.floor(tonumber(e.stars) or 0), 0, 3),
		fires = math.max(0, math.floor(tonumber(e.fires) or 0)), day = math.floor(tonumber(e.day) or 0) }
end

-- prof.sessions, defaulted on every touch (schema v5 unchanged: sub-fields are filled in here). `recent` is rebuilt as a
-- plain array of whole beats, at most RecentMax, so a hand-edited or corrupt store can't break a card
local function state(prof)
	local s = prof.sessions
	if type(s) ~= "table" then s = {}; prof.sessions = s end
	if type(s.done) ~= "table" then s.done = {} end
	s.deliveries = tonumber(s.deliveries) or 0
	local recent = {}
	for _, e in ipairs(type(s.recent) == "table" and s.recent or {}) do
		local b = beatOf(e)
		if b and #recent < recentMax() then table.insert(recent, b) end
	end
	s.recent = recent
	if type(prof.credits) ~= "table" then prof.credits = {} end
	return s
end

-- the career day a recent beat is stamped with (prof.life.day; 1 without a life, as WalkIns' hints do)
local function careerDay(prof)
	local life = prof.life
	return type(life) == "table" and tonumber(life.day) or 1
end

-- the cold spell's lastDay (see the header): a whole career day, or nil
function M.LastDay(player)
	if not ctx then return nil end
	local d = tonumber(state(ctx.Data.GetProfile(player)).lastDay)
	if d == nil or d ~= d or d == math.huge or d == -math.huge then return nil end
	return math.floor(d)
end
-- lastDay set to `day` (a whole career day; nil clears it). Systems/Career's calls (ColdCheck's LastDayStep, its hooks)
-- and RecordDelivery's. Returns true when written, false before Init or for a day that isn't a finite number
function M.TouchLastDay(player, day)
	if not ctx then return false end
	local n = day ~= nil and tonumber(day) or nil
	if day ~= nil and (n == nil or n ~= n or n == math.huge or n == -math.huge) then return false end
	state(ctx.Data.GetProfile(player)).lastDay = n and math.floor(n) or nil
	ctx.Data.MarkDirty(player)
	return true
end

-- a request is offered only when its artist is unlocked and the player has every tool its required asks need
-- a daily taken on an earlier UTC day can no longer be delivered (it would eat today's daily allowance)
local function staleDaily(s)
	local b = s.active and Briefs[s.active]
	if b and b.weekly then return s.active ~= "w" .. dailies().ThisWeek() end -- last week's single expired too
	return b ~= nil and b.daily == true and not tostring(s.active):find("^d" .. dailies().Today() .. "_")
end

function M.Feasible(player, brief)
	local a = Artists.ArtistById[brief.artist]
	local level = ctx.Data.GetProfile(player).level or 1
	if not a or level < (a.level or 1) then return false end
	for need in pairs(Check.Requires(brief)) do
		if not DAW.Unlocked(player, need) then return false end
	end
	return true
end

-- up to OfferCount requests: unfinished ones first (taking artists in turn, the starter first), then repeats
function M.Offers(player)
	local s = state(ctx.Data.GetProfile(player))
	local byArtist, order = {}, {}
	for _, a in ipairs(Artists.Artists) do byArtist[a.id] = {}; table.insert(order, a.id) end
	for _, b in ipairs(Artists.Briefs) do if byArtist[b.artist] then table.insert(byArtist[b.artist], b) end end
	local out, seen = {}, {}
	local function take(wantDone)
		local progress = true
		while #out < M.OfferCount and progress do
			progress = false
			for _, aid in ipairs(order) do
				for _, b in ipairs(byArtist[aid]) do
					if not seen[b.id] and ((s.done[b.id] ~= nil) == wantDone) and M.Feasible(player, b) then
						seen[b.id] = true
						table.insert(out, { id = b.id, again = wantDone or nil })
						progress = true
						break
					end
				end
				if #out >= M.OfferCount then break end
			end
		end
	end
	-- the starter request leads until it is done
	for _, b in ipairs(Artists.Briefs) do
		if b.starter and not s.done[b.id] and M.Feasible(player, b) then seen[b.id] = true; table.insert(out, { id = b.id }) end
	end
	take(false)
	take(true)
	for _, o in ipairs(dailies().Offers(player)) do table.insert(out, o) end -- today's daily requests follow
	local wk = dailies().WeeklyOffer(player)                                  -- then this week's single
	if wk then table.insert(out, wk) end
	return out
end

function M.State(player)
	local s = state(ctx.Data.GetProfile(player))
	if staleDaily(s) then s.active = nil; ctx.Data.MarkDirty(player) end
	local done = {}
	for k, v in pairs(s.done) do done[k] = v end
	-- last = your own last delivery, so the client's "make it yours" tick matches the server's check
	return { offers = M.Offers(player), active = s.active, done = done, deliveries = s.deliveries, last = s.last }
end

function M.Pick(player, id)
	if type(id) ~= "string" or #id > 24 then return { ok = false, reason = "invalid" } end
	-- compare with the server-built offers FIRST: client text never reaches the brief lookup (or the daily generator)
	local offered = false
	for _, o in ipairs(M.Offers(player)) do if o.id == id then offered = true; break end end
	if not offered then return { ok = false, reason = "notoffered" } end
	local brief = Briefs[id]
	if not brief then return { ok = false, reason = "invalid" } end
	local prof = ctx.Data.GetProfile(player)
	state(prof).active = id
	ctx.Data.MarkDirty(player)
	pickedEv:Fire(player, brief)
	return { ok = true, state = M.State(player) }
end

-- your beat ---------------------------------------------------------------------------------------------------------

-- a passed delivery's beat into prof.sessions.recent (RecentPush with the career day), the career day as lastDay, and a
-- 3-star one's Career.ColdCheck "delivery3" (the cold spell's way out; a failure there is reported and never undoes the
-- record); false for a call that isn't one (before Init, or a pattern / bpm / stars of the wrong type)
function M.RecordDelivery(player, pattern, bpm, stars)
	if not ctx or type(pattern) ~= "string" or pattern == "" or type(bpm) ~= "number" or type(stars) ~= "number" then return false end
	local prof = ctx.Data.GetProfile(player)
	local s = state(prof)
	local day = careerDay(prof)
	local st = math.clamp(math.floor(stars), 0, 3)
	s.recent = Rules.RecentPush(s.recent, { pattern = pattern, bpm = bpm, stars = st, fires = 0, day = day }, recentMax())
	s.lastDay = math.floor(day)
	ctx.Data.MarkDirty(player)
	recentEv:Fire(player)
	if st >= 3 then
		local ok, err = pcall(function() require(RS.OK.Systems.Career).ColdCheck(player, "delivery3") end)
		if not ok then warn("[OK][ERR] cold delivery3: " .. tostring(err)) end
	end
	return true
end

-- one FIRE on the aired beat `pattern` (RecentFire: a beat not in the list joins at 0 stars, at the front, and a full list
-- drops its lowest-quality older beat, ties to the oldest); false for a
-- call that isn't one. Reactions.Give calls it for an online producer only
function M.CreditFire(player, pattern, bpm)
	if not ctx or type(pattern) ~= "string" or pattern == "" then return false end
	local prof = ctx.Data.GetProfile(player)
	local s = state(prof)
	s.recent = Rules.RecentFire(s.recent, pattern, tonumber(bpm) or Cfg.BPM.Default, careerDay(prof), recentMax())
	ctx.Data.MarkDirty(player)
	recentEv:Fire(player)
	return true
end

-- the best recent beat (WalkInRules.BestBeat: the highest BeatQuality, ties to the newest) as a copy, or nil
function M.BestBeat(player)
	if not ctx then return nil end
	local best = Rules.BestBeat(state(ctx.Data.GetProfile(player)).recent)
	return best and beatOf(best) or nil
end

-- the recent beats as copies, newest first (Studio hook Recent)
function M.Recent(player)
	if not ctx then return {} end
	local out = {}
	for i, e in ipairs(state(ctx.Data.GetProfile(player)).recent) do out[i] = beatOf(e) end
	return out
end

-- the recent beats replaced by `list` (Studio hook SetRecent): its whole beats in order, at most RecentMax; anything
-- else in it is dropped. Returns the list kept (copies)
function M.SetRecent(player, list)
	if not ctx then return nil end
	local prof = ctx.Data.GetProfile(player)
	state(prof).recent = type(list) == "table" and list or {}
	ctx.Data.MarkDirty(player)
	recentEv:Fire(player)
	return M.Recent(player)
end

function M.Deliver(player, pattern, bpm, swing)
	local now = os.clock()
	if lastDeliver[player] and now - lastDeliver[player] < M.DeliverCooldown then return { ok = false, reason = "cooldown" } end
	lastDeliver[player] = now
	local prof = ctx.Data.GetProfile(player)
	local s = state(prof)
	if staleDaily(s) then
		s.active = nil
		ctx.Data.MarkDirty(player)
		return { ok = false, reason = "expired", state = M.State(player) }
	end
	local brief = s.active and Briefs[s.active]
	if not brief then return { ok = false, reason = "noactive" } end
	local p, b, sw = DAW.Validate(pattern, bpm, swing, DAW.UnlockFn(player))
	if not p then return { ok = false, reason = b } end
	if not DAW.AtStation(player) then return { ok = false, reason = "away" } end
	local extra = { s.last }
	local NP = RS.OK.NowPlaying
	if NP:GetAttribute("Active") and NP:GetAttribute("OwnerId") ~= player.UserId then table.insert(extra, NP:GetAttribute("Beat")) end
	local changed = Check.Changed(p, Check.References(Cfg, extra))
	if changed < Check.MinChanged then return { ok = false, reason = "copy", changed = changed } end
	local res = Check.Check(Cfg, brief, p, b, sw)
	if not res.passed then
		local missing = {}
		for _, a in ipairs(res.asks) do if not a.ok then table.insert(missing, a.text) end end
		return { ok = false, reason = "missing", missing = missing }
	end
	local stars = res.stars
	local first, xp, cred, plaque = false, 0, 0, false
	if brief.weekly then
		first, xp, cred, plaque = dailies().RecordWeekly(player, brief, stars)
	elseif brief.daily then
		first, xp, cred = dailies().Record(player, brief, stars)
	else
		first = s.done[brief.id] == nil
		if first then
			local mult = stars >= 3 and 1.5 or 1
			xp = ctx.Data.AddXP(player, math.floor(brief.reward.xp * mult + 0.5), "Delivery")
			cred = ctx.Data.AddCred(player, math.floor(brief.reward.cred * mult + 0.5), "Delivery")
		end
		s.done[brief.id] = math.max(s.done[brief.id] or 0, stars)
	end
	s.active = nil
	s.last = p
	s.deliveries += 1
	M.RecordDelivery(player, p, b, stars) -- your beat: this delivery joins the recent beats (Wave 3)
	local artist = Artists.ArtistById[brief.artist]
	table.insert(prof.credits, { t = brief.title, a = artist.name, s = stars, d = tonumber(os.date("!%Y%m%d")) })
	while #prof.credits > M.CreditsCap do table.remove(prof.credits, 1) end
	ctx.Data.MarkDirty(player)
	print(string.format("[OK] %s delivered %s for %s: %d stars, +%d XP, +$%d%s", player.Name, brief.title, artist.name, stars, xp, cred, first and "" or " (repeat)"))
	-- a repeat or a daily logs no line unless it ticks its own first (LifeRules.Apply)
	pcall(function() require(RS.OK.Systems.Life).Event(player, stars >= 3 and "delivery3" or "delivery",
		{ v = brief.artist, key = brief.id, again = not first or nil, daily = brief.daily or nil }) end)
	deliveredEv:Fire(player, brief, stars, first)
	return { ok = true, stars = stars, xp = xp, cred = cred, again = not first, brief = brief.id, plaque = plaque,
		credit = string.format("%s · %s · prod. %s", brief.title, artist.name, player.DisplayName),
		reaction = artist.quotes[stars] or "", state = M.State(player) }
end

function M.Init(c)
	ctx = c
	local R = RS.OK.Remotes
	R.Session_Get.OnServerInvoke = function(player) return M.State(player) end
	R.Session_Pick.OnServerInvoke = function(player, id) return M.Pick(player, id) end
	R.Session_Deliver.OnServerInvoke = function(player, pattern, bpm, swing) return M.Deliver(player, pattern, bpm, swing) end
	Players.PlayerRemoving:Connect(function(p) lastDeliver[p] = nil end)
end

return M
