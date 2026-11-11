-- OK Studio system: the career remembers (Wave 2). Owns prof.life (schema v5, shape and copy in Modules/LifeRules): the
-- career clock, the story, the discography, the firsts, the highest tier reached and the ribbons. Nothing here pays.
-- * The clock: Life.Tick(player) counts one career day per UTC day played, on join and from a 15 s loop for players online
--   across midnight (the loop skips while WalkInsPaused is present in Studio, the test hold). A new day sets the player
--   attribute LifeDayToast = day, which the client reads once its UI is built, so a join's toast can't beat the client's
--   listener. A profile from a newer schema never steps (it's never saved) and never toasts.
-- * Life.Event(player, kind, fields): other systems report what happened (LifeRules.KINDS); it never errors at the caller.
--   Every site reports through a lazy lookup, so nothing that happened ever depends on Life. "tier" is refused: tiers move
--   only through Publish.
-- * Life.Publish(player, loud): run by Career.Publish. It records any tier the Followers reached, with its story line and
--   first; only loud (Career.Add's own Publish, a real gain) also sends "LifeBanner" and plants the tier's visit
--   (Config.Life.TierVisits through WalkIns.PlantSystem; the k-th tier of one move at {k, k + 1} walk-ins). With walk-ins
--   switched off there's no visit and the banner is its headline alone (the visit stays lost: a tier crosses once). A crossing
--   through a hook Set, a join or a backfill is silent. Career.Add passes loud straight through rather than Life listening
--   to Career.Changed: under deferred signals that listener runs after Add's Publish, which would already have recorded
--   the crossing silently.
--   The tier is a high-water mark, so a fall and a re-rise never repeat any of this.
-- * A ribbon that lands sends the "Toast" notify (Copy.RibbonToast, no sound).
-- * The cold spell (Wave 3, design 4.2; Systems/Career owns it): a new career day runs Career.ColdCheck(player, "check")
--   (the quiet rule counts career days, so days not played never count); Career reports the spell's entry and exit as
--   the kinds "cold" and "thaw", every spell logged, and a "thaw" also sends "LifeBanner" with Copy.ThawBanner (the exit
--   banner; none on entry).
-- * Player attributes: Year, Tier (the highest reached), Title (LifeRules.Public), LifeDayToast.
-- * Every entry point is a no-op until Init (or _SetCtxForTest), so Career can call Life from edit tests and at any
--   point in the start order. Career.State doesn't call Life for its data: it reads prof.life through LifeRules.View.
-- * Studio-only hook ServerScriptService.OK._StudioLifeHook while running: hook:Invoke(cmd, userId, a, b) with Reset,
--   State, SetDay(day, last), AdvanceDay, Event(kind, fields), Sent, SetRoster(roster), SetTier(id: the high-water mark put
--   back, so a test can stage a crossing still to come).
local RS, Players = game:GetService("ReplicatedStorage"), game:GetService("Players")
local RunService = game:GetService("RunService")
local Config = require(RS.OK.Config)
local Rules = require(RS.OK.Modules.LifeRules)
local M = { Enabled = true, Version = 1 }
M._quiet = false -- tests that provoke a reported error set this so the console stays clean
local ctx
local sentLog      -- with the Studio hook or a test ctx: [userId] = { { kind, payload } } sent since the last read
local rosters = {} -- Studio hook SetRoster: [userId] = the roster that player's Career.State names come from
local isKind = {}
for _, k in ipairs(Rules.KINDS) do isKind[k] = true end

-- edit-mode tests: a fake ctx ({ Data = DataService copy }) and a fresh Config and LifeRules (Edit caches a plain require
-- across syncs); no Init needed
function M._SetCtxForTest(c) ctx = c; sentLog = sentLog or {} end
function M._SetConfigForTest(cfg, rules) Config = cfg; Rules = rules or Rules end

local function report(msg)
	M._lastReport = msg -- what edit tests read, _quiet or not
	if not M._quiet then warn("[OK][ERR] " .. msg) end
end
local function isPlayer(p) return typeof(p) == "Instance" and p:IsA("Player") end
-- the test hold, as WalkIns reads it: Studio with the WalkInsPaused attribute present, true or false
local function held() return RunService:IsStudio() and RS.OK:GetAttribute("WalkInsPaused") ~= nil end

local function logSent(player, kind, payload)
	if not sentLog then return end
	local log = sentLog[player.UserId] or {}
	sentLog[player.UserId] = log
	table.insert(log, { kind = kind, payload = payload })
end

local function send(player, kind, payload)
	logSent(player, kind, payload)
	if isPlayer(player) then
		pcall(function() RS.OK.Remotes.InteractionEvent:FireClient(player, kind, payload) end)
	end
end

-- the player's life with its inside whole (DataService's migrate makes the table); nil for a throwaway profile
local function lifeOf(player)
	local prof = ctx.Data.GetProfile(player)
	if prof._detached then return nil, prof end
	local life = prof.life
	if type(life) ~= "table" then life = Rules.Backfill(prof, ctx.Data._day(), Config.Life.Tiers); prof.life = life end
	for _, part in ipairs({ "story", "disco", "firsts", "ribbons" }) do
		if type(life[part]) ~= "table" then life[part] = {} end
	end
	if type(life.day) ~= "number" then life.day = 1 end
	-- an unknown tier would read as the lowest and replay every crossing: it becomes the current tier, silently
	local tiers = Config.Life.Tiers
	if tiers[Rules.TierIndex(life.tier, tiers)].id ~= life.tier then
		local career = type(prof.career) == "table" and prof.career or {}
		life.tier = (Rules.TierFor(career.followers, tiers))
	end
	return life, prof
end

local function setAttrs(player, life)
	if not isPlayer(player) then return end
	local pub = Rules.Public(life, Config.Life)
	player:SetAttribute("Year", pub.year)
	player:SetAttribute("Tier", pub.tier)
	player:SetAttribute("Title", pub.title)
end

-- the WalkIns system: ctx.WalkIns in edit tests, the live module otherwise (required on use, a no-op before its Init)
local function walkInsSys() return ctx.WalkIns or require(RS.OK.Systems.WalkIns) end
local function walkInsOn() return (Config.WalkIns or {}).Enabled ~= false end
-- the tier's visit, due in k or k + 1 walk-ins (k = its place in this move, A4); a plant that fails never stops the
-- crossing. Quiet with walk-ins switched off, and refused for being queued or seen already is fine; any other refusal (an
-- unknown id, WalkIns not started) is reported
local function plantVisit(player, tierId, k)
	local id = Config.Life.TierVisits[tierId]
	if not id or not walkInsOn() then return end
	local ok, entry, why = pcall(function() return walkInsSys().PlantSystem(player, id, { k, k + 1 }) end)
	if not ok then report("tier visit " .. id .. ": " .. tostring(entry))
	elseif entry == nil and why ~= "queued" then report("tier visit " .. id .. " was not planted") end
end

-- stamps any ribbon now earned at today's career day and toasts it; returns how many
local function awardRibbons(player, prof, life)
	local earned = Rules.RibbonsFor(life, prof.career, Config.Life.Ribbons, Config.Life.Tiers)
	for _, id in ipairs(earned) do life.ribbons[id] = life.day end
	local text = Rules.RibbonToast(earned)
	if text then send(player, "Toast", { text = text }) end
	return #earned
end

-- moves the high-water mark up to the Followers' tier, handling every tier passed, in order (A4); returns how many
local function crossTiers(player, prof, life, loud)
	local lc = Config.Life
	local career = type(prof.career) == "table" and prof.career or {}
	local _, now = Rules.TierFor(career.followers, lc.Tiers)
	local crossed = Rules.TiersCrossed(Rules.TierIndex(life.tier, lc.Tiers), now, lc.Tiers)
	for k, t in ipairs(crossed) do
		Rules.Apply(life, "tier", { key = t.id }, lc)
		life.tier = t.id
		if loud then
			send(player, "LifeBanner", { text = Rules.BannerText(t.id, walkInsOn()), tier = t.id })
			plantVisit(player, t.id, k)
		end
	end
	return #crossed
end

function M.Publish(player, loud)
	if not ctx then return end
	local life, prof = lifeOf(player)
	if not life then return end
	local crossed = crossTiers(player, prof, life, loud == true)
	local ribbons = awardRibbons(player, prof, life)
	if crossed + ribbons > 0 then ctx.Data.MarkDirty(player) end
	setAttrs(player, life)
end

-- what happened, recorded (LifeRules.Apply): returns { ticked, story?, disco? }, or nil when nothing could be recorded
function M.Event(player, kind, fields)
	if not ctx then return nil end
	if not isKind[kind] then report("unknown life event " .. tostring(kind)); return nil end
	if kind == "tier" then report("life event tier refused: tiers move only through Publish"); return nil end
	local ok, res = pcall(function()
		local life, prof = lifeOf(player)
		if not life then return nil end
		local r = Rules.Apply(life, kind, fields, Config.Life)
		awardRibbons(player, prof, life)
		ctx.Data.MarkDirty(player)
		setAttrs(player, life)
		-- the cold spell's exit banner, through the tier banners' path (the client's queue holds it behind a card)
		if kind == "thaw" and Rules.Copy.ThawBanner then send(player, "LifeBanner", { text = Rules.Copy.ThawBanner }) end
		return r
	end)
	if not ok then report("life event " .. tostring(kind) .. ": " .. tostring(res)); return nil end
	return res
end

-- the clock: one career day when today is later than the last day counted; returns true when it advanced. The DAY toast
-- is state, not a notify (see the header)
function M.Tick(player)
	if not ctx then return false end
	local life, prof = lifeOf(player)
	if not life or prof._newerSchema or not Rules.Step(life, ctx.Data._day()) then return false end
	ctx.Data.MarkDirty(player)
	setAttrs(player, life)
	logSent(player, "LifeDayToast", { day = life.day })
	if isPlayer(player) then player:SetAttribute("LifeDayToast", life.day) end
	print(string.format("[OK] %s: career day %d", tostring(player.Name), life.day))
	-- the cold spell's day step (Wave 3): a failure there never stops the day
	local ok, err = pcall(function() (ctx.Career or require(RS.OK.Systems.Career)).ColdCheck(player, "check") end)
	if not ok then report("cold check: " .. tostring(err)) end
	return true
end

-- the saved life as hooks read it: LifeRules.View plus the last day counted (Career.State sends the client its own)
function M.State(player)
	if not ctx then return nil end
	local life = lifeOf(player)
	if not life then return nil end
	local view = Rules.View(life, Config.Life, nil)
	view.last = life.last
	return view
end

-- the roster Career.State's names come from: a hook's SetRoster for this player, or `default`
function M.Roster(player, default) return rosters[player.UserId] or default end

function M._Sent(uid)
	local log = sentLog and sentLog[uid] or {}
	if sentLog then sentLog[uid] = nil end
	return log
end

-- Studio-only test seam ---------------------------------------------------------------------------------------------
-- a blank life at today's day 1. The tier starts from the current Followers, so a Reset leaves no crossing pending.
local function reset(p)
	local prof = ctx.Data.GetProfile(p)
	local career = type(prof.career) == "table" and prof.career or {}
	prof.life = { day = 1, last = ctx.Data._day(), story = {}, disco = {}, firsts = {}, ribbons = {},
		tier = (Rules.TierFor(career.followers, Config.Life.Tiers)) }
	rosters[p.UserId] = nil
	if sentLog then sentLog[p.UserId] = nil end
	ctx.Data.MarkDirty(p)
	setAttrs(p, prof.life)
	p:SetAttribute("LifeDayToast", nil)
	return true
end

local function makeHook()
	local SOK = game:GetService("ServerScriptService"):FindFirstChild("OK")
	if not SOK then return end
	local hook = SOK:FindFirstChild("_StudioLifeHook") or Instance.new("BindableFunction")
	hook.Name = "_StudioLifeHook"; hook.Parent = SOK
	sentLog = sentLog or {}
	hook.OnInvoke = function(cmd, userId, a, b)
		local p = Players:GetPlayerByUserId(userId)
		if not p then return nil end
		if cmd == "Reset" then return reset(p) end
		if cmd == "State" then return M.State(p) end
		if cmd == "SetDay" then -- day and, when given, the last day counted (yyyymmdd)
			local life = lifeOf(p)
			life.day = tonumber(a) or life.day
			life.last = tonumber(b) or life.last
			ctx.Data.MarkDirty(p)
			setAttrs(p, life)
			return true
		end
		if cmd == "AdvanceDay" then -- the next day through the real Tick, whatever the clock says
			lifeOf(p).last = 0
			return M.Tick(p)
		end
		if cmd == "Event" then return M.Event(p, a, b) end
		if cmd == "SetTier" then -- no story, no first, no attribute: the next Publish finds the crossing
			lifeOf(p).tier = a
			ctx.Data.MarkDirty(p)
			return true
		end
		if cmd == "Sent" then return M._Sent(p.UserId) end
		if cmd == "SetRoster" then -- "parody" or "fiction"; anything else goes back to Config's. Reset clears it too.
			rosters[p.UserId] = (a == "parody" or a == "fiction") and a or nil
			return true
		end
		return nil
	end
end

function M.Init(c)
	ctx = c
	c.Data.LeveledUp:Connect(function(player, level) M.Event(player, "level", { n = level }) end)
	local function onJoin(p) task.spawn(function()
		ctx.Data.GetProfile(p)
		M.Tick(p)
		M.Publish(p)
	end) end
	Players.PlayerAdded:Connect(onJoin)
	Players.PlayerRemoving:Connect(function(p)
		rosters[p.UserId] = nil
		if sentLog then sentLog[p.UserId] = nil end
	end)
	for _, p in ipairs(Players:GetPlayers()) do onJoin(p) end
	-- a new UTC day for everyone online (Dailies' pattern)
	task.spawn(function()
		local last = ctx.Data._day()
		while true do
			task.wait(15)
			local today = ctx.Data._day()
			if today ~= last and not held() then
				last = today
				for _, p in ipairs(Players:GetPlayers()) do task.spawn(M.Tick, p) end
			end
		end
	end)
	if RunService:IsStudio() and RunService:IsRunning() then makeHook() end
end

return M
