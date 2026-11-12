-- OK Studio DataService (v3): profiles you can trust.
-- * Session lock: every stored profile carries lock = { id = server id, at = time }. Load claims it through UpdateAsync.
--   A fresh lock held by another server (for example the server a player just left, still saving) is waited out
--   (Config.Data.LockWaits, about 30 s: longer than a slow leave save, launch audit A8), then taken over; a lock older
--   than Config.Data.LockStaleSeconds is taken at once.
--   A server whose lock was taken stops writing that profile (_lockLost), so an old server can never roll progress back.
--   Leaving releases the lock. Autosave refreshes the lock every Config.Data.LockHeartbeatSeconds even without changes.
--   Each load also writes a writer token (a GUID per load) that every save keeps, the leave save included. A save is
--   refused (lockLost) when the stored lock is foreign, the stored writer isn't this load's, or the stored v is newer
--   than ours: a save held in the store's queue while another server took the profile over and let it go can't roll
--   that server's progress back. A stored profile with no writer (saved before the token existed) is accepted once.
-- * Load retries errors (1, 2, 4 s). If every attempt errors the profile is flagged _loadFailed: it is never written,
--   and the player is told this session won't save.
-- * Saves go through UpdateAsync with a schema version (v) and updatedAt; fields starting with "_" are never stored.
--   A save stores a deep copy made when it starts, so a stored profile is one moment. Every change marks the player dirty
--   through touch(), which bumps their generation; a save clears dirty only if the generation didn't move while the
--   store held it, so a change made during that wait goes out with the next autosave.
--   A stored profile newer than M.SchemaVersion (saved by a newer build; old servers stay up after a publish) is
--   flagged _newerSchema: it loads and plays, but this server never writes it, and no save ever lowers a stored v.
-- * Rewards: AddXP(player, n, source) and AddCred(player, n, source) pass one gate (Config.XP / Config.Cred): known
--   sources only, per-source cooldowns, daily limits and shared daily caps. An unknown source pays 0 and reports
--   "[OK][ERR]", which fails the test suite. GrantXP / GrantCred are for trusted one-off grants (tour reward, tests).
--   TakeCred(player, n) is a loss (walk-ins): no gate, takes at most the balance, so Money never goes below 0.
-- * Schema v4 adds prof.career (Systems/Career) and prof.walkins (Systems/WalkIns). Schema v5 adds prof.life (Systems/Life,
--   Modules/LifeRules): the career clock, story, discography, firsts, highest tier and ribbons. It can grow to about 30 KB,
--   so a client gets the profile through M.ClientProfile, without it; Career.State serves the life.
-- * Wave 3 (still v5) adds prof.hints = { [term] = career day }: the explainers already shown (Systems/WalkIns marks one
--   when a card or result carries it). migrate's repair line makes it a table; ClientProfile leaves it out.
-- * M.LeveledUp fires (player, level, before, source) on the server when XP raises a player's level.
-- * M.Saving(prof): this session writes the profile (a store, and none of _loadFailed, _lockLost, _newerSchema). The beat
--   maker's save answers it, so the player is never told "Saved" when nothing will be (launch audit A7).
-- * Shutdown (BindToClose -> M._Shutdown): closing stops the autosave and every save that is not a release, releases
--   every cached profile at once (the store runs one key's requests in call order, so a release issued behind a save in
--   flight lands after it) and waits once, for everything in flight, under one deadline (launch audit A9). A player
--   leaving meanwhile gets no second release.
-- * With no DataStore (Studio, unpublished place) M.Persistent = false and nothing is written. The real-save trial
--   (tools/real_save_on.lua: the Edit attribute ReplicatedStorage.OK.RealSaveTrial names a trial store) makes a Studio
--   session save to that store; a live server ignores the attribute, and tools/guard.lua refuses tests while it is set.
local DSS = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local Config = require(RS.OK.Config)
local LifeRules = require(RS.OK.Modules.LifeRules)

local M = {}
M.Persistent = false
M.SchemaVersion = 5
M.ServerId = Http:GenerateGUID(false)
M._now = function() return os.time() end
M._day = function() return tonumber(os.date("!%Y%m%d", M._now())) end
M._retryDelays = { 1, 2, 4 }
M._lockWaits = nil -- tests override; defaults to Config.Data.LockWaits
M._quiet = false   -- tests that provoke a reported error set this so the console stays clean
local leveledEv = Instance.new("BindableEvent")
M.LeveledUp = leveledEv.Event -- (player, level, before, source); server side, only when the level rose

local store = nil
local cache, dirty, loading, owners, gen = {}, {}, {}, {}, {}
local writerOf = setmetatable({}, { __mode = "k" }) -- profile -> its load's writer token (kept out of the profile)
local DEFAULT = { level = 1, xp = 0, visits = 0 }

local function dataCfg() return Config.Data or {} end
local function report(msg) if not M._quiet then warn("[OK][ERR] " .. msg) end end
local function key(p) return "u_" .. tostring(p.UserId) end
-- every change marks the player dirty here and bumps their generation (Save clears dirty only if it didn't move)
local function touch(p) dirty[p.UserId] = p; gen[p.UserId] = (gen[p.UserId] or 0) + 1 end
local function notify(p, kind, payload)
	if typeof(p) == "Instance" and p:IsA("Player") then
		pcall(function() RS.OK.Remotes.InteractionEvent:FireClient(p, kind, payload) end)
	end
end
local function setAttrs(p, prof)
	if typeof(p) == "Instance" and p:IsA("Player") then
		p:SetAttribute("Level", prof.level)
		p:SetAttribute("XP", prof.xp)
		p:SetAttribute("NextLevelXP", Config.Levels[prof.level + 1] or prof.xp)
		p:SetAttribute("LevelXP", Config.Levels[prof.level] or 0)
		p:SetAttribute("Cred", prof.cred or 0)
		local c = type(prof.career) == "table" and prof.career or {}
		for _, stat in ipairs({ "Aura", "Followers", "Placements", "Hits", "Sponsors" }) do
			p:SetAttribute(stat, tonumber(c[string.lower(stat)]) or 0)
		end
	end
end

function M.LevelFor(xp)
	local lv = 1
	for i, threshold in ipairs(Config.Levels) do
		if xp >= threshold then lv = i end
	end
	return lv
end

-- schema v4 shapes, written out here so DataService needs no system module (Modules/CareerRules.Defaults matches)
local function newCareer()
	return { aura = 0, followers = 0, placements = 0, hits = 0, sponsors = 0, sponsor = nil, showSponsor = true, gates = {}, careerLog = {} }
end
local function newWalkins() return { day = 0, today = 0, count = 0, queue = {}, seen = {}, last = {} } end
-- schema v5: a career life from what the profile already shows (day 1 today, the tier and firsts it has reached, no
-- banner), plus the ribbons those earn, dated day 1
local function newLife(prof)
	local lc = Config.Life
	local life = LifeRules.Backfill(prof, M._day(), lc.Tiers)
	for _, id in ipairs(LifeRules.RibbonsFor(life, prof.career, lc.Ribbons, lc.Tiers)) do life.ribbons[id] = life.day end
	return life
end

-- schema migrations run on every load; bump M.SchemaVersion and add a step when the stored shape changes
function M.migrate(prof)
	prof.v = prof.v or 0
	if prof.v < 1 then
		prof.xpLog = prof.xpLog or {}
		prof.v = 1
	end
	if prof.v < 2 then -- Studio Sessions: Cred, gear, credits list, Cred reward log
		prof.cred = tonumber(prof.cred) or 0
		prof.gear = type(prof.gear) == "table" and prof.gear or {}
		prof.credits = type(prof.credits) == "table" and prof.credits or {}
		prof.credLog = type(prof.credLog) == "table" and prof.credLog or {}
		prof.v = 2
	end
	if prof.v < 3 then prof.cred = (tonumber(prof.cred) or 0) * 10; prof.v = 3 end -- Money x10: amounts read like money ("$")
	if prof.v < 4 then prof.career = newCareer(); prof.walkins = newWalkins(); prof.v = 4 end -- walk-ins: career stats + schedule
	-- a career or walkins that is not a table (hand-edited or corrupt store) is replaced whole; their fields are left alone
	if type(prof.career) ~= "table" then prof.career = newCareer() end
	if type(prof.walkins) ~= "table" then prof.walkins = newWalkins() end
	prof.xp = tonumber(prof.xp) or 0
	prof.cred = math.max(0, math.floor(tonumber(prof.cred) or 0))
	prof.level = M.LevelFor(prof.xp)
	-- after the repairs and the level above: the backfill reads a whole career and a current level
	if prof.v < 5 then prof.life = newLife(prof); prof.v = 5 end -- the career remembers
	if type(prof.life) ~= "table" then prof.life = newLife(prof) end -- a life that is not a table: same repair as above
	if type(prof.hints) ~= "table" then prof.hints = {} end -- Wave 3, no bump: the explainers seen, { [term] = career day }
	return prof
end

local function copy(v)
	if type(v) ~= "table" then return v end
	local out = {}
	for k, x in pairs(v) do out[k] = copy(x) end
	return out
end
-- the stored profile: a deep copy (one moment, whatever changes while the store holds the save), "_" fields left out
local function clean(prof)
	local out = {}
	for k, v in pairs(prof) do
		if not (type(k) == "string" and k:sub(1, 1) == "_") then out[k] = copy(v) end
	end
	return out
end

-- the profile a client is sent: a shallow copy without prof.life (Career.State serves that, once, in the background) and
-- prof.hints (server bookkeeping: a hint reaches the client on the card that carries it)
function M.ClientProfile(prof)
	local out = table.clone(prof)
	out.life = nil
	out.hints = nil
	return out
end

local function foreignLock(lock) return type(lock) == "table" and lock.id ~= M.ServerId end
local function freshForeignLock(lock, now)
	return foreignLock(lock) and type(lock.at) == "number" and now - lock.at < (dataCfg().LockStaleSeconds or 600)
end

local inflight = 0    -- loads, saves and release saves in progress (shutdown waits for them)
local closing = false -- set by M._Shutdown: a load that finishes now releases at once
-- has this player left the server? (tests mark fake players with _left = true)
local function left(p)
	if typeof(p) == "Instance" then return p.Parent == nil end
	return type(p) == "table" and p._left == true
end
-- a throwaway profile that is never cached or saved: for players who already left, or a load that never finished
local function detached()
	local prof = M.migrate({ level = 1, xp = 0, visits = 0, xpLog = {} })
	prof._loadFailed = true
	prof._detached = true
	return prof
end
local function forget(uid) cache[uid] = nil; dirty[uid] = nil; owners[uid] = nil; gen[uid] = nil end

-- leave / shutdown save: releases the lock, retrying transient errors
local function releaseSave(p)
	local prof = cache[p.UserId]
	if not prof then return false, "noprofile" end
	inflight += 1
	local ok, err = M.Save(p, true)
	local i = 0
	while not ok and err ~= "lockLost" and err ~= "loadFailed" and err ~= "newerSchema" and err ~= "noprofile" and err ~= "nostore" and i < #M._retryDelays do
		i += 1
		task.wait(M._retryDelays[i])
		ok, err = M.Save(p, true)
	end
	if ok and dirty[p.UserId] then ok, err = M.Save(p, true) end -- a change made while the leave save waited: once more
	if not ok and err ~= "nostore" and err ~= "loadFailed" and err ~= "newerSchema" and err ~= "lockLost" then
		warn("[OK] release save failed for " .. tostring(p.UserId) .. ": " .. tostring(err))
	end
	inflight -= 1
	return ok, err
end
M._ReleaseSave = releaseSave

-- the store round trip of a load; returns nil when the player left before the lock was claimed
local function loadUncached(p)
	local uid = p.UserId
	local prof = table.clone(DEFAULT)
	prof.xpLog = {}
	if store then
		local waits = M._lockWaits or dataCfg().LockWaits or { 1, 2, 3, 6, 8, 10 }
		local errors, lockTries = 0, 0
		local loaded, data, tookOver = false, nil, false
		local writer = Http:GenerateGUID(false)
		while true do
			if left(p) then return nil end -- never claim (or take over) a lock for someone who has gone
			local force = lockTries >= #waits
			local blocked, seen, took = false, nil, false
			local ok = pcall(function()
				store:UpdateAsync(key(p), function(old)
					local now = M._now()
					if type(old) == "table" and freshForeignLock(old.lock, now) and not force then
						blocked = true
						return nil -- cancel: another server still holds this profile
					end
					blocked = false
					seen = type(old) == "table" and old or {}
					took = foreignLock(seen.lock)
					seen.lock = { id = M.ServerId, at = now }
					seen.writer = writer
					return seen
				end)
			end)
			if ok and not blocked then loaded, data, tookOver = true, seen, took; break end
			if ok then
				lockTries += 1
				if lockTries <= #waits then task.wait(waits[lockTries]) end
			else
				errors += 1
				if errors > #M._retryDelays then break end
				task.wait(M._retryDelays[errors])
			end
		end
		if not loaded then
			prof._loadFailed = true
			notify(p, "Toast", { text = "Progress couldn't load. This session won't save." })
			warn("[OK] profile load failed for " .. tostring(uid) .. "; this session will not be saved")
		elseif type(data) == "table" then
			for k, v in pairs(data) do if k ~= "lock" and k ~= "writer" then prof[k] = v end end
			prof._lockAt = M._now()
			writerOf[prof] = writer
			prof._tookOver = tookOver or nil
			if (tonumber(prof.v) or 0) > M.SchemaVersion then -- this build can't migrate it, and must not write it back
				prof._newerSchema = true
				notify(p, "Toast", { text = "This server runs an older version, so this session won't save. Rejoin to keep saving." })
				warn("[OK] profile " .. tostring(uid) .. " is v" .. tostring(prof.v) .. ", newer than this server's v" .. M.SchemaVersion .. "; this session will not be saved")
			end
		end
	end
	M.migrate(prof)
	prof.visits = (tonumber(prof.visits) or 0) + 1
	return prof
end

-- single flight: one load per player at a time; everyone else waits for that same load
function M.Load(p)
	local uid = p.UserId
	local cached = cache[uid]
	if cached and cached._releasing then -- rejoined while the leave save is still running: wait for it
		local t0 = os.clock()
		while cache[uid] == cached and os.clock() - t0 < 30 do task.wait(0.05) end
		cached = cache[uid]
	end
	if cached then return cached end
	local pending = loading[uid]
	if pending then
		local t0 = os.clock()
		while not pending.done and os.clock() - t0 < 60 do task.wait(0.05) end
		return pending.done and pending.prof or detached()
	end
	pending = { done = false }
	loading[uid] = pending
	inflight += 1
	owners[uid] = p
	local ok, prof = pcall(loadUncached, p)
	if not ok then report("profile load crashed for " .. tostring(uid) .. ": " .. tostring(prof)); prof = nil end
	if prof == nil then
		prof = detached()
		owners[uid] = nil
	else
		cache[uid] = prof
		touch(p)
		setAttrs(p, prof)
		if closing or left(p) then -- left while loading, or the server is shutting down: save and release now
			releaseSave(p)
			forget(uid)
		end
	end
	pending.prof, pending.done = prof, true
	if loading[uid] == pending then loading[uid] = nil end
	inflight -= 1
	return prof
end

function M.GetProfile(p)
	local uid = p.UserId
	local c = cache[uid]
	if c and (not c._releasing or left(p)) then return c end -- a departing player's profile is still readable
	if loading[uid] or c then return M.Load(p) end           -- wait for the load (or the rejoin release) in flight
	if left(p) then return detached() end                    -- never load or lock for someone who has gone
	return M.Load(p)
end

function M.MarkDirty(p) touch(p) end

-- does this session write prof? A store, and not a profile whose load failed, whose lock another server took, or that a
-- newer build wrote (Save refuses all three)
function M.Saving(prof)
	return M.Persistent == true and type(prof) == "table" and not (prof._loadFailed or prof._lockLost or prof._newerSchema)
end

-- release = true on leave / shutdown: the stored lock is cleared so the next server loads at once.
-- Once a release has started, ordinary saves (autosave, heartbeat) leave the profile alone.
function M.Save(p, release)
	local prof = cache[p.UserId]
	if not prof then return false, "noprofile" end
	if prof._loadFailed then return false, "loadFailed" end
	if prof._newerSchema then return false, "newerSchema" end
	if prof._lockLost then return false, "lockLost" end
	if not store then return false, "nostore" end
	if release then prof._releasing = true
	elseif prof._releasing then return false, "releasing"
	elseif closing then return false, "closing" end -- shutting down: only the releases write now
	inflight += 1
	local uid = p.UserId
	local g0 = gen[uid]
	local now = M._now()
	prof.updatedAt = now
	prof.v = math.max(tonumber(prof.v) or 0, M.SchemaVersion) -- never lowers a stored version
	local lost = false
	local ok, err = pcall(function()
		-- the copy is inside the pcall: a value it can't take fails this save, never the autosave loop or a leave
		local data = clean(prof)
		data.writer = writerOf[prof]
		if not release then data.lock = { id = M.ServerId, at = now } end
		store:UpdateAsync(key(p), function(old)
			if type(old) == "table" and (foreignLock(old.lock) or (old.writer ~= nil and old.writer ~= data.writer)
				or (tonumber(old.v) or 0) > (tonumber(data.v) or 0)) then
				lost = true
				return nil -- another server took this profile over or wrote it since our load; never overwrite its progress
			end
			lost = false
			return data
		end)
	end)
	inflight -= 1
	-- a save that lands after its profile was forgotten (the player left and came back) leaves the new session alone
	local current = cache[uid] == prof
	if ok and lost then
		prof._lockLost = true
		if current then
			dirty[uid] = nil
			notify(p, "Toast", { text = "Your progress opened in another server, so this one stopped saving." })
			warn("[OK] profile " .. tostring(uid) .. " is now owned by another server; this server stopped saving it")
		end
		return false, "lockLost"
	end
	if ok then
		if current and gen[uid] == g0 then dirty[uid] = nil end -- a change during the store's wait stays dirty
		prof._lockAt = now
	else
		warn("[OK] save failed for " .. tostring(p.UserId) .. ": " .. tostring(err))
	end
	return ok, err
end

-- shutdown: no more autosaves or ordinary saves; every cached profile not already releasing is released at once (a
-- release behind a save in flight on the same key lands after it), then one wait, capped by deadline, for everything in
-- flight: those releases, the ones leaving players started, and loads (one that finishes now releases itself)
function M._Shutdown(deadline)
	closing = true
	deadline = deadline or 25
	local t0 = os.clock()
	local list = {}
	for uid, prof in pairs(cache) do
		if not prof._releasing then table.insert(list, uid) end
	end
	for _, uid in ipairs(list) do
		local p = owners[uid] or dirty[uid]
		if p then task.spawn(function() releaseSave(p); forget(uid) end) end
	end
	while inflight > 0 and os.clock() - t0 < deadline do task.wait(0.05) end
	return inflight == 0
end

-- a player leaving: their profile is released and forgotten, unless the shutdown is releasing it already (a second
-- release would only queue another write to the same key behind it)
local function onLeave(p)
	local prof = cache[p.UserId]
	if not prof then return end -- still loading: the load releases itself when it sees the player has gone
	if closing and prof._releasing then return end
	releaseSave(p)
	if cache[p.UserId] == prof then forget(p.UserId) end
end
M._OnLeave = onLeave -- tests: a leave with no Players event

-- writes changed profiles, and refreshes the lock of unchanged ones once it is LockHeartbeatSeconds old; none once the
-- server is closing (the shutdown's releases write everything)
function M._Autosave()
	if closing then return 0 end
	local now = M._now()
	local hb = dataCfg().LockHeartbeatSeconds or 180
	local list = {}
	for uid, prof in pairs(cache) do
		local p = dirty[uid] or owners[uid]
		if p and (dirty[uid] or (prof._lockAt and now - prof._lockAt >= hb)) then table.insert(list, p) end
	end
	local n = 0
	for _, p in ipairs(list) do
		if M.Save(p) then n += 1 end
	end
	return n
end

-- reward gate ----------------------------------------------------------------------
-- rules[source] = { xp | amount = fixed award, or max = cap on a variable award; cooldown = s; dailyMax = awards a
-- day; group = name of a shared daily cap in caps }. Returns the amount allowed (0 when refused) and why.
local function gate(prof, logKey, rules, caps, source, n)
	local rule = source ~= nil and rules[source] or nil
	if not rule then return 0, "unknown" end
	n = tonumber(n) or 0
	if n ~= n or n == math.huge then n = 0 end
	local now, day = M._now(), M._day()
	local log = prof[logKey]
	if type(log) ~= "table" then log = {}; prof[logKey] = log end
	if log.day ~= day then log.day = day; log.count = {}; log.group = {} end
	log.count = log.count or {}; log.group = log.group or {}; log.last = log.last or {}
	local gained = rule.xp or rule.amount or math.min(n, rule.max or n)
	gained = math.max(0, math.floor(gained))
	local cd = rule.cooldown or 0
	if cd > 0 and log.last[source] and now - log.last[source] < cd then return 0, "cooldown" end
	if rule.dailyMax and (log.count[source] or 0) >= rule.dailyMax then return 0, "daily" end
	if rule.group and caps[rule.group] then
		gained = math.min(gained, math.max(0, caps[rule.group] - (log.group[rule.group] or 0)))
	end
	if gained <= 0 then return 0, "cap" end
	log.last[source] = now
	log.count[source] = (log.count[source] or 0) + 1
	if rule.group then log.group[rule.group] = (log.group[rule.group] or 0) + gained end
	return gained
end
M._gate = gate

local function applyXP(p, prof, gained, source)
	local before = prof.level
	prof.xp += gained
	prof.level = M.LevelFor(prof.xp)
	touch(p)
	setAttrs(p, prof)
	notify(p, "Progress", { gained = gained, xp = prof.xp, level = prof.level, levelUp = prof.level > before, source = source })
	if prof.level > before then leveledEv:Fire(p, prof.level, before, source) end
	return gained, prof
end
local function applyCred(p, prof, gained, source)
	prof.cred = (prof.cred or 0) + gained
	touch(p)
	setAttrs(p, prof)
	notify(p, "Cred", { gained = gained, cred = prof.cred, source = source })
	return gained, prof
end

-- returns gained (number, 0 when refused), profile, reason
function M.AddXP(p, n, source)
	local prof = M.GetProfile(p)
	local gained, why = gate(prof, "xpLog", Config.XP.Sources, Config.XP.GroupDailyCap or {}, source, n)
	if why == "unknown" then report("unknown XP source " .. tostring(source)) end
	if gained <= 0 then return 0, prof, why end
	return applyXP(p, prof, gained, source)
end
function M.AddCred(p, n, source)
	local prof = M.GetProfile(p)
	local cc = Config.Cred or {}
	local gained, why = gate(prof, "credLog", cc.Sources or {}, cc.GroupDailyCap or {}, source, n)
	if why == "unknown" then report("unknown Cred source " .. tostring(source)) end
	if gained <= 0 then return 0, prof, why end
	return applyCred(p, prof, gained, source)
end
-- trusted one-off grants (the tour reward, Studio tests); never wire these to anything a client can trigger at will
function M.GrantXP(p, n, reason)
	local prof = M.GetProfile(p)
	n = math.floor(tonumber(n) or 0)
	if n <= 0 or n ~= n or n == math.huge then return 0, prof end
	return applyXP(p, prof, n, reason)
end
function M.GrantCred(p, n, reason)
	local prof = M.GetProfile(p)
	n = math.floor(tonumber(n) or 0)
	if n <= 0 or n ~= n or n == math.huge then return 0, prof end
	return applyCred(p, prof, n, reason)
end
function M.SpendCred(p, n)
	local prof = M.GetProfile(p)
	n = math.floor(tonumber(n) or -1)
	if n < 0 or n ~= n or n == math.huge or (prof.cred or 0) < n then return false, prof end
	prof.cred -= n
	touch(p)
	setAttrs(p, prof)
	notify(p, "Cred", { gained = -n, cred = prof.cred })
	return true, prof
end
-- a loss (walk-ins): no gate; takes floor(n) but never more than the balance; returns the amount taken (0 for n <= 0)
function M.TakeCred(p, n)
	local prof = M.GetProfile(p)
	n = math.floor(tonumber(n) or 0)
	if n ~= n or n <= 0 then return 0, prof end
	local taken = math.min(n, prof.cred or 0)
	if taken <= 0 then return 0, prof end
	prof.cred -= taken
	touch(p)
	setAttrs(p, prof)
	notify(p, "Cred", { gained = -taken, cred = prof.cred })
	return taken, prof
end

-- tests ------------------------------------------------------------------------------
function M._SetStoreForTest(fake)
	store = fake
	M.Persistent = fake ~= nil
	cache, dirty, loading, owners, gen = {}, {}, {}, {}, {}
	inflight, closing = 0, false
end
function M._Forget(p) forget(p.UserId) end
function M._Inflight() return inflight end
function M._SetConfigForTest(cfg) Config = cfg end

function M.Init()
	local studio = game:GetService("RunService"):IsStudio()
	local trial = studio and RS.OK:GetAttribute("RealSaveTrial") or nil -- tools/real_save_on.lua; Studio only
	trial = type(trial) == "string" and trial ~= "" and trial or nil
	if game.PlaceId ~= 0 and (not studio or (Config.Data and Config.Data.UseStoreInStudio) or trial) then
		local ok, s = pcall(function() return DSS:GetDataStore(trial or Config.DataStoreName) end)
		store = ok and s or nil
	end
	if trial then print("[OK] real-save trial: profiles save to the DataStore " .. trial .. (store and "" or " (not reachable)")) end
	if studio and not store and not trial then print("[OK] Studio session: profiles are not saved (Config.Data.UseStoreInStudio = false)") end
	M.Persistent = store ~= nil
	Players.PlayerAdded:Connect(function(p) task.spawn(M.Load, p) end)
	Players.PlayerRemoving:Connect(onLeave)

	for _, p in ipairs(Players:GetPlayers()) do task.spawn(M.Load, p) end
	task.spawn(function()
		while true do
			task.wait(Config.AutosaveSeconds or 120)
			M._Autosave()
		end
	end)
	game:BindToClose(function() M._Shutdown(25) end)
end

return M
