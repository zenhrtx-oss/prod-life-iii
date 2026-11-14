-- OK Studio system: the career. Five stats besides Money live in prof.career (shape, clamps and the needs check in
-- Modules/CareerRules): Aura (may go negative), Followers, Placements, Hits, Sponsors, plus the current sponsor deal,
-- the sponsor-on-the-TV switch and the gates you own.
-- * Positive stats only through Career.Add(player, stat, n, source): DataService's reward gate keyed "<source>.<stat>"
--   against Config.Career.Sources (own log prof.career.careerLog, daily caps). An unknown source pays 0 and reports
--   [OK][ERR]. Losses go through Career.Take (no gate; only Systems/WalkIns calls it).
-- * Feeds: a first 2- or 3-star delivery (Contracts.Delivered; a daily or the Weekly Single counts once a day / week)
--   pays Config.Career.DeliveryFeed[stars]; FIRE (Reactions), flips (Flips), cypher wins (BeatBattles) and weekly
--   plaques (Dailies) call Career.Add inline.
-- * Gates (Config.Career.Gates): a "room" is bought once with Money when its needs are met (Studio Two); the "toggle"
--   is the sponsor-on-the-TV switch (free once its needs are met; flips prof.career.showSponsor). A gate's `after` (R-T16
--   fix, I7: real_studio's is home_studio, the decided ladder) must be owned first: Unlock answers "needs" until it is, and
--   State's gate row carries `after` and its check an `after = { id, name, ok }` row (check.ok false while it isn't met),
--   which the Career tab shows as one more needs chip with the gate's own name.
-- * Player attributes for the client: Aura, Followers, Placements, Hits, Sponsors, Sponsor (the deal's display name),
--   CareerGates ("studio_two,sponsor_tv": owned rooms, plus sponsor_tv while its needs are met and it is switched on).
-- * Life: Publish runs Systems/Life.Publish last (loud when Followers really rose, so only a real gain gets a tier banner),
--   and State carries `life`, built from prof.life through LifeRules.View with the display names of the ids it holds (nil
--   if that fails: the Career tab never depends on it). KnownNames(player) is that names table ({ visitors, artists,
--   sponsors }; it throws on a content failure), shared with Systems/Rooms' plaques (R-T11). A room bought through Unlock
--   reports "hall".
-- * The cold spell (Wave 3, design 4.2): prof.career.cold = { since = career day, reason = "aura" | "quiet", news } or nil
--   (warm), prof.career.rearm = true or nil (lazy sub-fields: schema v5 unchanged). Every rule is CareerRules.ColdStep on
--   Config.WalkIns.Cold, run by M.ColdCheck(player, event): "check" after every Aura move through Add / Take and at
--   Life.Tick's day step; "fire" from Reactions.Give (a FIRE to you) and "delivery3" from Contracts.RecordDelivery (a
--   3-star delivery of any brief), the only two ways out; "cypher" from BeatBattles (a cypher win), which never thaws.
--   The career day is prof.life.day; lastDay is prof.sessions.lastDay, read and written through Contracts (its one
--   writer): a check that finds none saves today for the next one and itself reads none, so it never goes cold (nobody is
--   cold on a first read, and days not played never count); set on every passed delivery, set to today on a thaw
--   (design: "on exit lastDay = exit day"; without it the next check would re-chill "quiet"), and set to today whenever
--   you are heard, a FIRE to you or a cypher win, warm or cold (CareerRules.LastDayStep after every step; Wave 3 final
--   review I1, ruling A of 2026-11-12: the quiet spell is for players nobody hears). Going cold logs the Life kind "cold",
--   ends a burst under way (WalkIns.ColdChanged) and queues the spell's one cold_news through Phone.SendSystem (it waits
--   for the player's ready profile, a character and the tour, and never queues a second while one waits). cold.news
--   turns true only when the card opens (Phone.open -> M.SystemShown); until then every check and the phone's 1 s loop
--   send it again whenever none waits, so a respawn, a
--   leave or an expiry that drops it never loses it (fix round 1, A). A thaw logs "thaw" (Systems/Life sends the exit
--   banner) and withdraws an unopened cold_news (Phone.Withdraw: never counted, B). While cold: WalkIns.DailyMaxFor is
--   Config.WalkIns.Cold.dailyMax and no burst starts; Phone.canSend is false. The player attribute Cold (bool) drives the
--   HUD's COLD chip. A hook Set of Aura runs no check (a silent seam, like its tier crossing).
-- * Remotes (build/17_career_remotes.lua): Career_Get -> Fetch (State, at most once per FetchCooldown a player unless the
--   career changed), Career_Unlock(id) -> Unlock behind a token bucket per player (a burst of 3, then one every 0.25 s,
--   as Gear_Equip; launch audit A6): an empty bucket answers "busy" at once, with no state built or sent (the panel fetches
--   its own). Unlock publishes and builds a new state only when a room was bought or the toggle flipped; a refusal changed
--   nothing and answers with Fetch's. Studio-only hook
--   ServerScriptService.OK._StudioCareerHook while running in Studio (Wave 3: Cold, SetCold, SetLastDay, ColdCheck).
local RS, Players = game:GetService("ReplicatedStorage"), game:GetService("Players")
local Config = require(RS.OK.Config)
local Rules = require(RS.OK.Modules.CareerRules)
local Format = require(RS.OK.Modules.Format)
local LifeRules = require(RS.OK.Modules.LifeRules)
local M = { Enabled = true, Version = 1 }
M.FetchCooldown = 0.25 -- seconds between built states on Career_Get, per player
M._quiet = false -- tests that provoke a reported error set this so the console stays clean
M._clock = os.clock -- edit tests move Fetch's clock
local changedEv = Instance.new("BindableEvent")
M.Changed = changedEv.Event -- (player, stat, gained, source); a Take fires a negative amount and no source
local ctx
local isStat = {}
for _, stat in ipairs(Rules.STATS) do isStat[stat] = true end
local built = {} -- Fetch: [userId] = { at = clock, state = the last built state }
local UNLOCK_EVERY, UNLOCK_BURST = 0.25, 3 -- Career_Unlock from a client: a burst of 3, then at most 4 a second (Gear_Equip's)
local unlockTokens = {} -- [player] = { n = calls left, at = os.clock() when n was counted }

-- edit-mode tests: a fake ctx ({ Data = DataService copy, Gear = Gear copy?, Life = Life copy? }) and a fresh Config; no Init needed
function M._SetCtxForTest(c) ctx = c end
function M._SetConfigForTest(cfg) Config = cfg end

local function report(msg) if not M._quiet then warn("[OK][ERR] " .. msg) end end
local function careerCfg() return Config.Career or {} end
-- Config.Career.Sources flattened to the reward gate's rules: { ["Delivery.followers"] = { max = 120, dailyMax = 15 }, ... }
local function sources()
	local flat = {}
	for source, stats in pairs(careerCfg().Sources or {}) do
		for stat, rule in pairs(stats) do flat[source .. "." .. stat] = rule end
	end
	return flat
end
local function gateById(id)
	for _, g in ipairs(careerCfg().Gates or {}) do if g.id == id then return g end end
	return nil
end
-- the Gear system: ctx.Gear in edit tests, the live module otherwise (required on use: Gear never requires Career)
local function gearSys() return (ctx and ctx.Gear) or require(RS.OK.Systems.Gear) end
-- the Life system, the same way (a no-op until its Init)
local function lifeSys() return (ctx and ctx.Life) or require(RS.OK.Systems.Life) end
-- the cold spell's partners, required on use (each requires Career at load; each is a no-op before its Init): Contracts
-- (prof.sessions.lastDay's one writer), Phone (SendSystem) and WalkIns (ColdChanged); ctx may stand in for them in tests
local function contractsSys() return (ctx and ctx.Contracts) or require(RS.OK.Systems.Contracts) end
local function phoneSys() return (ctx and ctx.Phone) or require(RS.OK.Systems.Phone) end
local function walkInsSys() return (ctx and ctx.WalkIns) or require(RS.OK.Systems.WalkIns) end
-- the player's profile with prof.career present and whole (DataService's migrate makes it; this repairs the inside)
local function profile(player)
	local prof = ctx.Data.GetProfile(player)
	local c = prof.career
	if type(c) ~= "table" then c = Rules.Defaults(); prof.career = c end
	for _, stat in ipairs(Rules.STATS) do c[stat] = tonumber(c[stat]) or 0 end
	if type(c.gates) ~= "table" then c.gates = {} end
	if type(c.careerLog) ~= "table" then c.careerLog = {} end
	return prof
end
-- the deal's display name in the current roster (Data/WalkIns); the raw id when the content can't name it
local function sponsorName(id)
	if id == nil then return nil end
	local ok, name = pcall(function()
		return require(RS.OK.Data.WalkIns).SponsorName(id, (Config.WalkIns or {}).Roster or "parody")
	end)
	if ok and type(name) == "string" and name ~= "" then return name end
	return tostring(id)
end
local function needsMet(check)
	for _, row in ipairs(check.rows) do if not row.ok then return false end end
	return true
end
-- the toggle is on while its needs are met and the player has it switched on
local function toggleOn(have, g) return have.showSponsor and needsMet(Rules.Check(have, g.needs)) end
-- is the gate a room gate's `after` names owned (R-T16 fix, I7)? True for a gate with none
local function afterMet(have, g) return type(g.after) ~= "string" or have.gates[g.after] == true end
-- a gate's check (CareerRules.Check) with its prerequisite folded in (R-T16 fix, I7): a gate whose `after` names another
-- gate gets check.after = { id, name, ok } (ok: that gate is owned), and check.ok is false while it isn't
local function gateCheck(have, g)
	local check = Rules.Check(have, g.needs, g.cost)
	if type(g.after) == "string" then
		local first = gateById(g.after)
		local okAfter = afterMet(have, g)
		check.after = { id = g.after, name = first and first.name or g.after, ok = okAfter }
		if not okAfter then check.ok = false end
	end
	return check
end

-- the Career a player has (Money, the five stats, sponsor, showSponsor, owned gates)
function M.Get(player) return Rules.Have(profile(player)) end

-- loud: this Publish follows a real Followers gain, so a tier it crosses is a moment (Systems/Life)
function M.Publish(player, loud)
	built[player.UserId] = nil -- the career moved: a fetch after this must see it, cooldown or not
	if typeof(player) ~= "Instance" or not player.Parent then return end
	local have = Rules.Have(profile(player))
	for _, stat in ipairs(Rules.STATS) do player:SetAttribute(stat:sub(1, 1):upper() .. stat:sub(2), have[stat]) end
	player:SetAttribute("Sponsor", sponsorName(have.sponsor))
	local list = {}
	for _, g in ipairs(careerCfg().Gates or {}) do
		if (g.kind == "room" and have.gates[g.id]) or (g.kind == "toggle" and toggleOn(have, g)) then table.insert(list, g.id) end
	end
	player:SetAttribute("CareerGates", table.concat(list, ","))
	player:SetAttribute("Cold", type(profile(player).career.cold) == "table") -- the HUD's COLD chip (Wave 3)
	local ok, err = pcall(function() lifeSys().Publish(player, loud) end) -- a Life bug never breaks a card
	if not ok then report("life publish: " .. tostring(err)) end
end

local function changed(player, loud)
	ctx.Data.MarkDirty(player)
	M.Publish(player, loud)
end

-- a gated award; returns the amount actually added (0 when refused)
function M.Add(player, stat, n, source)
	local prof = profile(player)
	local gained, why = 0, "unknown"
	if isStat[stat] and type(source) == "string" then
		gained, why = ctx.Data._gate(prof.career, "careerLog", sources(), {}, source .. "." .. stat, n)
	end
	if why == "unknown" then report("unknown career source " .. tostring(source) .. "." .. tostring(stat)) end
	if gained > 0 then
		prof.career[stat] = Rules.Clamp(stat, prof.career[stat] + gained)
		changedEv:Fire(player, stat, gained, source)
	end
	changed(player, gained > 0 and stat == "followers")
	if gained > 0 and stat == "aura" then M.ColdCheck(player, "check") end -- the cold spell: after every Aura move
	return gained
end

-- a loss, no gate: Aura may go negative, every other stat stops at 0; returns the amount actually removed
function M.Take(player, stat, n)
	if not isStat[stat] then report("unknown career stat " .. tostring(stat)); return 0 end
	n = math.floor(tonumber(n) or 0)
	if n ~= n or n <= 0 or n == math.huge then return 0 end
	local prof = profile(player)
	local before = prof.career[stat]
	prof.career[stat] = Rules.Clamp(stat, before - n)
	local taken = before - prof.career[stat]
	if taken > 0 then changedEv:Fire(player, stat, -taken) end
	changed(player)
	if taken > 0 and stat == "aura" then M.ColdCheck(player, "check") end -- the cold spell: after every Aura move
	return taken
end

-- the cold spell (see the header) ------------------------------------------------------------------------------------

local function coldCfg() return (Config.WalkIns or {}).Cold end
local function careerDay(prof)
	local life = prof.life
	local d = type(life) == "table" and tonumber(life.day) or nil
	return d and math.max(1, math.floor(d)) or 1
end
-- a copy of the spell, or nil
local function coldCopy(cold)
	if type(cold) ~= "table" then return nil end
	return { since = cold.since, reason = cold.reason, news = cold.news == true }
end
-- a call to a partner system that never fails the caller: its result, or nil (reported)
local function try(what, fn)
	local ok, res = pcall(fn)
	if not ok then report("cold " .. what .. ": " .. tostring(res)); return nil end
	return res
end

-- is the player cold? (WalkIns' DailyMaxFor and bursts, Phone's canSend)
function M.IsCold(player)
	if not ctx then return false end
	return type(profile(player).career.cold) == "table"
end

-- the spell's cold_news, shown once per spell: while cold and not yet shown (cold.news false), it is queued through
-- Phone.SendSystem (nil while the player isn't ready, has no character, the tour isn't done, or one already waits).
-- Returns true when it was queued now. Called by every ColdCheck and by the phone's 1 s loop, so a dropped card comes back
function M.SendColdNews(player)
	if not ctx then return false end
	local cold = profile(player).career.cold
	if type(cold) ~= "table" or cold.news == true then return false end
	return try("news", function() return phoneSys().SendSystem(player, "cold_news") end) ~= nil
end

-- Phone.open: a system card was shown (opened; a NEWS resolves there). cold_news shown marks the spell's news, so it never
-- comes again this spell
function M.SystemShown(player, id)
	if not ctx or id ~= "cold_news" then return false end
	local cold = profile(player).career.cold
	if type(cold) ~= "table" or cold.news == true then return false end
	cold.news = true
	ctx.Data.MarkDirty(player)
	return true
end

-- one step of the spell (CareerRules.ColdStep on Config.WalkIns.Cold): event "check" | "fire" | "delivery3" | "cypher"
-- (a cypher win, BeatBattles: it never thaws, it only moves lastDay). Returns a copy of the spell (nil = warm)
function M.ColdCheck(player, event)
	if not ctx then return nil end
	local cfg = coldCfg()
	if type(cfg) ~= "table" then return nil end
	local prof = profile(player)
	local c = prof.career
	local day = careerDay(prof)
	-- lastDay through Contracts (its one writer): nil when none is saved (or without Contracts), so ColdStep's check changes
	-- nothing: never cold on a first read (fix round 1, D)
	local last = try("lastDay", function() return contractsSys().LastDay(player) end)
	local before = type(c.cold) == "table" and c.cold or nil
	local cold, rearm, moved = Rules.ColdStep(before, c.rearm == true, c.aura, day, last, event, cfg)
	-- then lastDay (CareerRules.LastDayStep): today after a read that found none (for the next check), a thaw ("on exit
	-- lastDay = exit day") or being heard, a FIRE to you or a cypher win (final review I1, ruling A); else unchanged
	local nextLast = Rules.LastDayStep(last, day, event, moved and before ~= nil and cold == nil)
	if nextLast ~= last then try("lastDay write", function() return contractsSys().TouchLastDay(player, nextLast) end) end
	if moved then
		c.cold, c.rearm = cold, rearm == true or nil
		if before and not cold then -- a thaw (lastDay is today, above): the stale cold_news withdrawn, the story and banner
			try("thaw news", function() return phoneSys().Withdraw(player, "cold_news") end)
			try("thaw story", function() return lifeSys().Event(player, "thaw") end)
			print(string.format("[OK] %s: warm again on career day %d (%s)", tostring(player.Name), day, tostring(event)))
		elseif cold and not before then -- a spell starts: its story line
			try("cold story", function() return lifeSys().Event(player, "cold") end)
			print(string.format("[OK] %s: cold on career day %d (%s)", tostring(player.Name), day, tostring(cold.reason)))
		end
		-- in or out: WalkIns ends a burst under way on the way in (BUSY DAY never shows beside COLD)
		if (before == nil) ~= (cold == nil) then try("walk-ins", function() return walkInsSys().ColdChanged(player, cold ~= nil) end) end
		changed(player)
	end
	M.SendColdNews(player)
	return coldCopy(c.cold)
end

-- the current sponsor deal (an id from Data/WalkIns, or nil to drop it); the Sponsors count is never touched here
function M.SetSponsor(player, id)
	local prof = profile(player)
	prof.career.sponsor = type(id) == "string" and id or nil
	changed(player)
end

-- the display names for the ids a life holds, in this player's roster: { visitors, artists, sponsors } (LifeRules' `names`).
-- Only ids the content knows get a name; anything else reads as LifeRules' fallback, never as an id. Career.State's `life`
-- and Systems/Rooms' plaques (R-T11) both read it, so the two never name a visitor differently. Throws on a content failure:
-- a caller wraps it.
function M.KnownNames(player)
	local roster = lifeSys().Roster(player, (Config.WalkIns or {}).Roster or "parody")
	local known = { visitors = {}, artists = {}, sponsors = {} }
	local W = require(RS.OK.Data.WalkIns)
	known.visitors = W.Names(roster)
	for id in pairs(W.SponsorById) do known.sponsors[id] = W.SponsorName(id, roster) end
	for _, a in ipairs(require(RS.OK.Data.Artists).Artists) do known.artists[a.id] = a.name end
	return known
end

-- Career.State's `life`: the saved life for the client, with names for its ids in this player's roster (KnownNames)
local function lifeView(player, prof)
	local ok, view = pcall(function() return LifeRules.View(prof.life, Config.Life, M.KnownNames(player)) end)
	if not ok then report("life view: " .. tostring(view)); return nil end
	return view
end

-- the Career tab: stats, every gate with its check, every stat-gated gear item, and the life
function M.State(player)
	local prof = profile(player)
	local have = Rules.Have(prof)
	local gates = {}
	for _, g in ipairs(careerCfg().Gates or {}) do
		local owned = g.kind == "room" and have.gates[g.id] == true
		table.insert(gates, { id = g.id, kind = g.kind, name = g.name, desc = g.desc, needs = g.needs or {}, cost = g.cost or 0, after = g.after,
			owned = owned, on = owned or (g.kind == "toggle" and toggleOn(have, g)), check = gateCheck(have, g) })
	end
	local Gear = gearSys()
	local gear = {}
	for _, it in ipairs(Config.Gear or {}) do
		if it.needs then
			table.insert(gear, { id = it.id, name = it.name, kind = it.kind, needs = it.needs, price = it.price, level = it.level,
				owned = Gear.Owns(player, it.id), levelOk = (prof.level or 1) >= it.level, check = Rules.Check(have, it.needs, it.price) })
		end
	end
	return { stats = have, gates = gates, gear = gear, life = lifeView(player, prof) }
end

-- Career_Get: State, or the last built state when one was built under FetchCooldown ago (a panel can ask a lot, and a state
-- walks the whole career)
function M.Fetch(player)
	local now, last = M._clock(), built[player.UserId]
	if last and now - last.at < M.FetchCooldown then return last.state end
	local state = M.State(player)
	built[player.UserId] = { at = now, state = state }
	return state
end

-- returns { ok, reason = "invalid" | "owned" | "needs" | "money", state }: a new state after a buy or a flip, Fetch's (the
-- last built one under FetchCooldown) after a refusal, which changed nothing; "invalid" carries none
function M.Unlock(player, gateId)
	local g = type(gateId) == "string" and gateById(gateId) or nil
	if not g or (g.kind ~= "room" and g.kind ~= "toggle") then return { ok = false, reason = "invalid" } end
	local prof = profile(player)
	local have = Rules.Have(prof)
	local check = Rules.Check(have, g.needs, g.cost)
	local res
	if g.kind == "room" then
		if have.gates[g.id] then res = { ok = false, reason = "owned" }
		elseif not (needsMet(check) and afterMet(have, g)) then res = { ok = false, reason = "needs" } -- I7: the gate before it first, too
		elseif not check.money.ok or not ctx.Data.SpendCred(player, g.cost or 0) then res = { ok = false, reason = "money" }
		else
			prof.career.gates[g.id] = true
			print(string.format("[OK] %s unlocked %s for %s", tostring(player.Name), g.name, Format.Money(g.cost or 0)))
			if g.id == LifeRules.HALL_GATE then pcall(function() lifeSys().Event(player, "hall") end) end -- a Life failure never fails the unlock
			res = { ok = true, gate = g.id }
		end
	elseif not needsMet(check) then res = { ok = false, reason = "needs" }
	else
		prof.career.showSponsor = not have.showSponsor
		res = { ok = true, gate = g.id, on = prof.career.showSponsor }
	end
	if not res.ok then res.state = M.Fetch(player); return res end
	changed(player)
	res.state = M.State(player)
	return res
end

-- may this player's client unlock now? A token bucket: UNLOCK_BURST calls, then one more every UNLOCK_EVERY s
local function unlockAllowed(player)
	local now = os.clock()
	local b = unlockTokens[player]
	if not b then b = { n = UNLOCK_BURST, at = now }; unlockTokens[player] = b end
	b.n, b.at = math.min(UNLOCK_BURST, b.n + (now - b.at) / UNLOCK_EVERY), now
	if b.n < 1 then return false end
	b.n -= 1
	return true
end

-- Contracts.Delivered: a first 2- or 3-star delivery feeds Followers and Aura; returns what it added
local function onDelivered(player, _brief, stars, first)
	if not first or type(stars) ~= "number" or stars < 2 then return 0, 0 end
	local feed = (careerCfg().DeliveryFeed or {})[stars >= 3 and 3 or 2]
	if not feed then return 0, 0 end
	return M.Add(player, "followers", feed.followers or 0, "Delivery"), M.Add(player, "aura", feed.aura or 0, "Delivery")
end

-- Studio-only test seam (Studio + running): hook:Invoke(cmd, userId, ...). Add(stat, n, source) is the real gated award;
-- ResetCredCount(source) clears today's Money gate count for that source (Career Reset leaves prof.credLog alone)
local function makeHook()
	local SOK = game:GetService("ServerScriptService"):FindFirstChild("OK")
	if not SOK then return end
	local hook = SOK:FindFirstChild("_StudioCareerHook") or Instance.new("BindableFunction")
	hook.Name = "_StudioCareerHook"; hook.Parent = SOK
	hook.OnInvoke = function(cmd, userId, a, b, c)
		local p = Players:GetPlayerByUserId(userId)
		if not p then return nil end
		if cmd == "Get" then return M.Get(p) end
		if cmd == "Add" then return M.Add(p, a, b, c) end
		if cmd == "ResetCredCount" then
			local log = ctx.Data.GetProfile(p).credLog
			if type(log) == "table" and type(log.count) == "table" then log.count[a] = nil end
			return true
		end
		if cmd == "State" then return M.State(p) end
		if cmd == "Publish" then M.Publish(p); return true end
		if cmd == "Take" then return M.Take(p, a, b) end
		if cmd == "Unlock" then return M.Unlock(p, a) end
		if cmd == "Equip" then return gearSys().Equip(p, a) end
		if cmd == "FeedDelivered" then local f, au = onDelivered(p, nil, a, b); return { followers = f, aura = au } end
		-- Reset: a fresh career, warm, and no lastDay (through Contracts), so the next check defaults it to that day's career day
		if cmd == "Reset" then
			local prof = profile(p); prof.career = Rules.Defaults()
			try("reset lastDay", function() return contractsSys().TouchLastDay(p, nil) end)
			changed(p); return true
		end
		-- the cold spell (Wave 3): Cold = { cold = a copy or nil, rearm = bool, lastDay }; SetCold(cold, rearm) puts a spell (a
		-- table; nil = warm) and rearm as given, silently (no story, no news, no ColdChanged; the attribute follows); SetLastDay(day)
		-- through Contracts (nil clears it); ColdCheck(event) is the real step and returns the spell's copy (nil = warm)
		if cmd == "Cold" then
			local cr = profile(p).career
			return { cold = coldCopy(cr.cold), rearm = cr.rearm == true, lastDay = try("hook lastDay", function() return contractsSys().LastDay(p) end) }
		end
		if cmd == "SetCold" then
			local cr = profile(p).career
			cr.cold = type(a) == "table" and { since = tonumber(a.since) or 1, reason = a.reason == "quiet" and "quiet" or "aura", news = a.news == true } or nil
			cr.rearm = b == true or nil
			changed(p); return true
		end
		if cmd == "SetLastDay" then return try("hook SetLastDay", function() return contractsSys().TouchLastDay(p, a) end) == true end
		if cmd == "ColdCheck" then return M.ColdCheck(p, a) end
		if cmd == "Set" then
			-- stats = { money?, aura?, followers?, placements?, hits?, sponsors?, sponsor? (false clears the deal), showSponsor? }
			local stats = type(a) == "table" and a or {}
			local prof = profile(p)
			for _, stat in ipairs(Rules.STATS) do
				if type(stats[stat]) == "number" then prof.career[stat] = Rules.Clamp(stat, stats[stat]) end
			end
			if stats.sponsor == false then prof.career.sponsor = nil elseif type(stats.sponsor) == "string" then prof.career.sponsor = stats.sponsor end
			if type(stats.showSponsor) == "boolean" then prof.career.showSponsor = stats.showSponsor end
			if type(stats.money) == "number" then -- through DataService so the Cred attribute follows
				local d = math.max(0, math.floor(stats.money)) - (prof.cred or 0)
				if d > 0 then ctx.Data.GrantCred(p, d, "Test") elseif d < 0 then ctx.Data.TakeCred(p, -d) end
			end
			changed(p)
			return true
		end
		return nil
	end
end

function M.Init(c)
	ctx = c
	local R = RS.OK.Remotes
	R.Career_Get.OnServerInvoke = function(player) return M.Fetch(player) end
	R.Career_Unlock.OnServerInvoke = function(player, id)
		if not unlockAllowed(player) then return { ok = false, reason = "busy" } end -- no state: a spam call costs nothing more
		if type(id) ~= "string" or #id > 24 then return { ok = false, reason = "invalid" } end
		return M.Unlock(player, id)
	end
	require(RS.OK.Systems.Contracts).Delivered:Connect(function(...)
		local ok, err = pcall(onDelivered, ...)
		if not ok then warn("[OK][ERR] career feed: " .. tostring(err)) end
	end)
	local function onJoin(p) task.spawn(function() ctx.Data.GetProfile(p); M.Publish(p) end) end
	Players.PlayerAdded:Connect(onJoin)
	Players.PlayerRemoving:Connect(function(p) built[p.UserId] = nil; unlockTokens[p] = nil end)
	gearSys().Bought:Connect(function(p) built[p.UserId] = nil end) -- a buy runs no Career.Publish, and the next fetch must show it
	for _, p in ipairs(Players:GetPlayers()) do onJoin(p) end
	local Run = game:GetService("RunService")
	if Run:IsStudio() and Run:IsRunning() then makeHook() end
end

return M
