-- OK Studio system: Day One (the Day One plan, Task 2). The opening chain of choice cards in your own bedroom: JUNO
-- VALE's beat request (card 1) a moment after you wake up; Task 3 adds "play it on your speakers?" (card 2) and "spend
-- it?" (card 3), then the first visitor at your door. The rules are Modules/DayOneRules (pure), every word Data/DayOne,
-- the numbers Config.DayOne; the saved state is prof.tour.d1 (DayOneRules.Repair: { v = 1, haggle, paid, private }),
-- which Tour.Reset wipes with the tour. Rooms.lua is never touched: Systems/Rooms and Systems/WalkIns are required lazily.
-- * The chain is per-player server memory, never saved: { started, card = { token, id, at, payload }?, pending = { id,
--   at, beat? }?, returnAt?, returned, room?, beat?, done, tour } (tour = the prof.tour table it started on: Tour.Reset
--   replaces that table, so a chain whose table is gone is dropped). Times are os.clock() seconds.
-- * The join path (the first character only; a respawn never restarts it): under the test hold (Studio with
--   ReplicatedStorage.OK's WalkInsPaused attribute present, true or false: Systems/WalkIns' held()) nothing starts, so the
--   existing play tests never see a card; a done or skipped tour starts nothing. Else the chain starts now and waits until
--   Rooms.PlaceOf names your own bedroom (at most Config.DayOne.WakeWait s; at once with no slot), then queues the card
--   DayOneRules.Next names FirstCard s later (Task 2 sends "dayone"; Task 3 adds "speakers" and "spend").
-- * Sending: a queued card goes out only while no walk-in is in flight (WalkIns.Busy) and no phone DM is open
--   (PhoneBusy); else it waits and the 1 s loop retries. At send time a card the saved tour no longer names
--   (DayOneRules.Stale, ruling B1) is dropped unsent. A new card closes any open one first ("leave").
-- * The 1 s loop runs every started chain, the test hold or not: DayOneRules.Due (expire, then send, then card 1's one
--   return: the sender sets returned = true and clears returnAt in the same step, F1), then the player attribute
--   DayOneBusy = DayOneRules.Holds (true while a card is open or queued, or for HoldMax s from the chain's start), which
--   holds Systems/WalkIns' countdown and scheduler. A finished chain is skipped (F4).
-- * Card 1's choices (DayOne_Choose(token, index); 0 is SKIP; an index past the card's choices is "invalid", a token that
--   isn't the open card's "stale", and the card stays as it was; an open card the saved tour no longer names, say card 1
--   after the request was taken at the laptop's picker, is closed and the choice refused as "stale", with nothing applied:
--   fix round 1, B1 for the open card; a staged card, the hook's Show, is exempt):
--   make: Contracts.Pick(starter) (a refusal ignored: the beat maker's picker opens instead), then DAW.OpenFor(p, it, nil,
--     { presets = true }) at your bedroom's laptop (Rooms.Station) within DAWConfig.CloseDistance (14, 3D from your root:
--     DAWClient closes the beat maker past it), else at the spot DAW.StationOf names within 14 too (seated in the studio
--     PC's chair: its screen, with that chair, as the PC's own handler opens it); else the toast `far` inside your own
--     plot or `farHub` elsewhere.
--   haggle: the roll (the hook's SetRoll, else a Random) through DayOneRules.Haggle at HaggleOdds, written to d1.haggle
--     (once: a later haggle keeps it), the toast haggleGood or haggleBad, then as make.
--   look: the card closes; returnAt = now + LookAround unless card 1 has already come back. Expiry (CardSeconds): as look.
--   SKIP: the chain ends at once, then Tour.Skip.
-- * Tour.Changed (player, what, at): only a running chain reacts (F3), and only to an event fired after it started (a
--   deferred handler can run after the next chain began). "done" or "skip" with the tour done ends the chain: the open
--   card leaves, the queued card and returnAt go, done = true, DayOneBusy false, then WalkIns.ArmFirst(p, a draw from
--   VisitAfter) brings the first visitor (F4). "reset" (the tour's table replaced) drops the chain. "take" clears returnAt
--   (B1), and any step closes an open card the tour no longer names (fix round 1; the staged card exempt): DayOneBusy then
--   follows Holds' time rule. WalkIns' hook Reset drops the chain too (WalkIns.OnReset, F6: the chain, DayOneBusy and the
--   forced roll; prof.tour.d1 and the Sent log are the DayOne Reset's). Leaving the server clears the memory.
-- * Remotes (build/20_day_one.lua): DayOne (server -> client: "arrive" with DayOneRules.Card's payload plus its token,
--   "leave" with { token }); DayOne_Choose(token, index) -> { ok = true } | { ok = false, reason = "stale" | "invalid" };
--   DayOne_Get() -> the open card's payload or nil.
-- * Studio-only hook ServerScriptService.OK._StudioDayOneHook (Studio and running), hook:Invoke(cmd, userId, a, b):
--   Joined (the real join path: "held", "done", "gone" or "waiting"); Start (a chain now, past the hold, its card queued and sent
--   if nothing blocks it; returns Next's id, nil and no chain on a finished tour); Show(id) (a chain if none runs, then
--   that card sent now, unchecked and marked staged); Open ({ token, id } or nil); Choose(index) (M.Choose on the open token);
--   ChooseToken(token, index); Get (M.Get, as DayOne_Get answers); State ({ d1, next, busy, running, done, card, pending,
--   returned, returnAt, started, now }); Sent (this system's actions since the last read: { kind = "arrive" | "leave" |
--   "toast" | "opendaw", id?, token?, text?, why?, payload? }); Opened (DAW.Opened fires for the player since the last
--   read: a test's require gets its own module copies, so it can't connect the live event); SetRoll(r) (the next
--   haggle's roll); Age(s) (every chain clock s seconds back); Tick (one loop step now); Reset (any open card closed,
--   the memory and DayOneBusy cleared, prof.tour.d1 = nil, the Sent log emptied); Pick(id?) (Contracts.Pick, the
--   Session_Pick remote's own handler, on brief `id`, or with none on the first offered brief by another artist than the
--   starter's: { ok, reason, id }, the real way a player takes a request at the laptop's picker).
local RS, Players = game:GetService("ReplicatedStorage"), game:GetService("Players")
local RunService, Http = game:GetService("RunService"), game:GetService("HttpService")
local Config = require(RS.OK.Config)
local Rules = require(RS.OK.Modules.DayOneRules)
local D = require(RS.OK.Data.DayOne)
local Artists = require(RS.OK.Data.Artists)
local Format = require(RS.OK.Modules.Format)
local DAWCfg = require(RS.OK.Modules.DAWConfig)
local Tour = require(RS.OK.Systems.Tour)
local Contracts = require(RS.OK.Systems.Contracts)
local DAW = require(RS.OK.Systems.DAW)

-- Config.DayOne, read again in Init (an Edit check's fresh clone may get an older cached Config without it: no index here)
local C = Config.DayOne
local M = { Enabled = not (type(C) == "table" and C.Enabled == false), Version = 1 }
local CARDS = { dayone = true } -- the cards the join path and Start queue (Task 3 adds speakers and spend)
local GOAL = "spk_monitors" -- card 3's next goal (Data/DayOne {goal})

local ctx, dayOneEv
local chains = {}  -- [userId] = the chain (see the header)
local joined = {}  -- [player] = true once their first character came (the join path ran, or was held)
local rolls = {}   -- [userId] = the next haggle's roll (the hook's SetRoll)
local opened = {}  -- Studio: [userId] = DAW.Opened fires since the hook's last Opened
local sentLog      -- while the Studio hook exists: [userId] = { action } since the hook's last Sent
local rng = Random.new()

local function report(msg) warn("[OK][ERR] day one: " .. tostring(msg)) end
-- the test hold, as Systems/WalkIns' held(): Studio only, so a stray attribute in a published place never holds anyone
local function held() return RunService:IsStudio() and RS.OK:GetAttribute("WalkInsPaused") ~= nil end

-- Systems/Rooms and Systems/WalkIns, required lazily on first use (never at load); nil when they can't be
local lazyMods = {}
local function lazy(name)
	local m = lazyMods[name]
	if m == nil then
		local ok, res = pcall(function() return require(RS.OK.Systems[name]) end)
		m = ok and res or false
		lazyMods[name] = m
		if not ok then report(name .. ": " .. tostring(res)) end
	end
	return m or nil
end
local function rooms() return lazy("Rooms") end
local function walkIns() return lazy("WalkIns") end

local function log(p, entry)
	if not sentLog then return end
	local l = sentLog[p.UserId] or {}
	sentLog[p.UserId] = l
	table.insert(l, entry)
end
local function fire(p, kind, payload)
	if p.Parent ~= Players then return end
	local ok, err = pcall(function() dayOneEv:FireClient(p, kind, payload) end)
	if not ok then report("send " .. kind .. ": " .. tostring(err)) end
end
local function toast(p, text)
	if p.Parent == Players then
		local ok, err = pcall(function() RS.OK.Remotes.InteractionEvent:FireClient(p, "Toast", { text = text }) end)
		if not ok then report("toast: " .. tostring(err)) end
	end
	log(p, { kind = "toast", text = text })
end
local function fill(text, vars) return (Rules.Fill(text, vars)) end

-- the saved tour and d1 ---------------------------------------------------------------------------------------------

-- prof.tour as Systems/Tour keeps it (made here only for a profile with none, as Tour's own state() would)
local function tourOf(p)
	local prof = ctx.Data.GetProfile(p)
	local t = prof.tour
	if type(t) ~= "table" then t = { got = {} }; prof.tour = t end
	if type(t.got) ~= "table" then t.got = {} end
	return t
end
-- prof.tour.d1 through DayOneRules.Repair, written back: the table to read and write
local function state(p)
	local t = tourOf(p)
	local d1 = Rules.Repair(t.d1)
	t.d1 = d1
	return d1
end
local function finished(t) return t.done == true or t.skipped == true end

-- a Color3 as { r, g, b } 0-255 (VisitorFigure's generic figure takes that; ruling m5)
local function rgb(c)
	if typeof(c) ~= "Color3" then return nil end
	return { math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5) }
end
local function gearRow(id)
	for _, g in ipairs(Config.Gear) do if g.id == id then return g end end
	return nil
end
-- every token Data/DayOne uses (its header's table), plus artistId and color for card 1's face (DayOneRules.Card)
local function vars(p)
	local prof = ctx.Data.GetProfile(p)
	local starter = Rules.Starter(Artists.Briefs)
	local artist = starter and Artists.ArtistById[starter.artist]
	local pay = starter and type(starter.reward) == "table" and tonumber(starter.reward.cred) or 0
	local money = tonumber(prof.cred) or 0
	local v = {
		artist = artist and artist.name or nil, artistId = artist and artist.id or nil, color = artist and rgb(artist.color) or nil,
		pay = Format.Money(pay), ask = Format.Money(pay + C.HaggleBonus), money = Format.Money(money),
		xp = C.PrivateXP, reward = Tour.RewardXP,
	}
	local tool = Rules.Tool(Config.Gear, prof.gear, money, prof.level)
	if tool then v.tool = tool.name; v.toolprice = Format.Money(tool.price) end
	local goal = gearRow(GOAL)
	if goal then
		v.goal, v.goalprice = goal.name, Format.Money(goal.price)
		v.goalfollowers = type(goal.needs) == "table" and goal.needs.followers or nil
	end
	return v
end

-- the chain ----------------------------------------------------------------------------------------------------------

local function alive(p, chain) return p.Parent == Players and chains[p.UserId] == chain and not chain.done end
-- p's open card and its chain, or nil (no chain, a finished one, or no card)
local function openCard(p)
	local chain = chains[p.UserId]
	local card = chain and not chain.done and chain.card or nil
	return card, chain
end
-- an open card the saved tour no longer names (DayOneRules.Stale; ruling B1 for the open card, fix round 1); a staged
-- card (the hook's Show) never is
local function staleCard(p, card) return card ~= nil and not card.staged and Rules.Stale(tourOf(p), card.id) end
-- DayOneBusy from DayOneRules.Holds, for the player's running chain only
local function busy(p, chain)
	if not alive(p, chain) then return end
	p:SetAttribute("DayOneBusy", Rules.Holds(chain, os.clock(), C) == true)
end
-- the open card closed on the client ("leave"); false when none was open
local function close(p, chain, why)
	local card = chain.card
	if not card then return false end
	chain.card = nil
	fire(p, "leave", { token = card.token })
	log(p, { kind = "leave", id = card.id, token = card.token, why = why })
	return true
end
-- card `id` sent now (any open card closed first): DayOneRules.Card's payload with a new token; the payload, or nil for
-- an id Data/DayOne doesn't have
local function send(p, chain, id)
	local payload = Rules.Card(id, D, vars(p))
	if not payload then report("no card " .. tostring(id)); return nil end
	close(p, chain, "next")
	local token = "day1:" .. Http:GenerateGUID(false)
	payload.token = token
	chain.card = { token = token, id = id, at = os.clock(), payload = payload }
	fire(p, "arrive", payload)
	log(p, { kind = "arrive", id = id, token = token, payload = payload })
	return payload
end
-- a walk-in in flight or a phone DM open: a queued Day One card waits (one card at a time)
local function blocked(p)
	if p:GetAttribute("PhoneBusy") == true then return true end
	local W = walkIns()
	return W ~= nil and W.Busy(p) == true
end
-- the queued card out now, unless something blocks it (it stays queued); one the saved tour no longer names is dropped
-- (ruling B1). True when a card went out
local function sendPending(p, chain)
	local pend = chain.pending
	if not pend or blocked(p) then return false end
	chain.pending = nil
	if Rules.Stale(tourOf(p), pend.id) then return false end
	if pend.beat then chain.beat = pend.beat end
	return send(p, chain, pend.id) ~= nil
end
-- card 1 comes back (Due's "return"): spent in this step, sent or not (returned = true, returnAt cleared: F1); blocked,
-- it waits as the queued card; stale (the request was taken meanwhile), it is dropped
local function sendReturn(p, chain)
	chain.returned = true
	chain.returnAt = nil
	if Rules.Stale(tourOf(p), "dayone") then return false end
	chain.pending = { id = "dayone", at = os.clock() }
	return sendPending(p, chain)
end
-- the chain's end (SKIP, or the tour done): the open card leaves, nothing queued or returning, DayOneBusy false, then the
-- first-ever visit is armed VisitAfter seconds out (WalkIns.ArmFirst: only while no walk-in has come yet). Once only
local function finish(p, chain)
	if chain.done then return false end
	close(p, chain, "end")
	chain.done = true
	chain.pending, chain.returnAt = nil, nil
	if p.Parent == Players then p:SetAttribute("DayOneBusy", false) end
	local W = walkIns()
	if W and W.ArmFirst then
		local ok, err = pcall(W.ArmFirst, p, rng:NextInteger(C.VisitAfter[1], C.VisitAfter[2]))
		if not ok then report("arm the first visit: " .. tostring(err)) end
	end
	return true
end
-- the memory gone (Reset, a replaced tour): any open card closed, DayOneBusy cleared (nil: no chain)
local function drop(p)
	local uid = p.UserId
	local chain = chains[uid]
	chains[uid] = nil
	if chain then close(p, chain, "reset") end
	if p.Parent == Players then p:SetAttribute("DayOneBusy", nil) end
end
-- a new chain for p, started now on the current tour (an old chain's open card closed first)
local function newChain(p)
	local old = chains[p.UserId]
	if old then close(p, old, "replaced") end
	local chain = { started = os.clock(), returned = false, done = false, tour = tourOf(p) }
	chains[p.UserId] = chain
	return chain
end

-- card 1 -------------------------------------------------------------------------------------------------------------

-- the beat-making spot to open at: your bedroom's laptop, else the spot DAW.StationOf names, each only within
-- DAWConfig.CloseDistance of your root (DAWClient hides the beat maker past it, so a farther open would shut at once)
local function nearSpot(p)
	local c = p.Character
	local root = c and c:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local reach = DAWCfg.CloseDistance
	local R = rooms()
	local laptop = R and R.Station(p) or nil
	if laptop and (root.Position - laptop.Position).Magnitude <= reach then return laptop, "room" end
	local spot = DAW.StationOf(p)
	if spot and (root.Position - spot.Position).Magnitude <= reach then return spot, "station" end
	return nil
end
-- standing in your own plot (a room or its landing): the `far` toast points at your laptop, else `farHub` at the PC
local function inOwnPlot(p)
	local R = rooms()
	if not R then return false end
	local place = R.PlaceOf(p)
	return type(place) == "table" and place.slot ~= nil and place.slot == R.PlotOf(p)
end
-- "Make it now": the starter request taken, then the beat maker on its preset chooser where you stand, else a toast
local function make(p)
	local starter = Rules.Starter(Artists.Briefs)
	if starter then
		local ok, err = pcall(Contracts.Pick, p, starter.id) -- a refusal is ignored: the beat maker's picker opens instead
		if not ok then report("pick " .. tostring(starter.id) .. ": " .. tostring(err)) end
	end
	local spot, where = nearSpot(p)
	if spot then
		local inst, seat = spot, nil
		if spot.Name == "Chair_Seat" and spot:IsA("Seat") then -- seated at the studio PC: its screen and chair, as the PC's handler
			local screen = spot.Parent and spot.Parent:FindFirstChild("Screen_Main")
			if screen then inst, seat = screen, spot end
		end
		DAW.OpenFor(p, inst, seat, { presets = true })
		log(p, { kind = "opendaw", id = where, text = inst:GetFullName() })
	else
		toast(p, fill(inOwnPlot(p) and D.Toasts.far or D.Toasts.farHub, vars(p)))
	end
end
-- "Haggle": one roll for the whole Day One (d1.haggle kept once written), its toast, then as make
local function haggle(p)
	local d1 = state(p)
	if d1.haggle == nil then
		local roll = rolls[p.UserId]
		rolls[p.UserId] = nil
		if type(roll) ~= "number" then roll = rng:NextNumber() end
		d1.haggle = Rules.Haggle(roll, C.HaggleOdds)
		ctx.Data.MarkDirty(p)
	end
	toast(p, fill(d1.haggle == "good" and D.Toasts.haggleGood or D.Toasts.haggleBad, vars(p)))
	make(p)
end
-- "Look around first" (and card 1's expiry): it comes back LookAround seconds later, once (DayOneRules.Due decides)
local function look(chain)
	if not chain.returned then chain.returnAt = os.clock() + C.LookAround end
end

-- each card's choices by key, and what its expiry does (Task 3 adds speakers and spend)
local CHOOSE = {
	dayone = function(p, chain, key)
		if key == "make" then make(p)
		elseif key == "haggle" then haggle(p)
		elseif key == "look" then look(chain) end
	end,
}
local EXPIRE = {
	dayone = function(_, chain) look(chain) end,
}
local function expire(p, chain)
	local card = chain.card
	if not card then return end
	close(p, chain, "expire")
	local fn = EXPIRE[card.id]
	if fn then fn(p, chain) end
end

-- the loop's step for one player's chain: a chain whose tour was replaced is dropped; then Due's one action; then
-- DayOneBusy. A missing or finished chain does nothing (F4)
local function step(p)
	local chain = chains[p.UserId]
	if not chain or chain.done then return end
	if chain.tour ~= tourOf(p) then drop(p); return end
	local due = Rules.Due(chain, os.clock(), C)
	if due == "expire" then expire(p, chain)
	elseif due == "send" then sendPending(p, chain)
	elseif due == "return" then sendReturn(p, chain) end
	busy(p, chain)
end

-- Tour.Changed: a running chain only (F3), an event fired after it started only
local function onChanged(p, what, at)
	if typeof(p) ~= "Instance" or not p:IsA("Player") then return end
	local chain = chains[p.UserId]
	if not chain or chain.done then return end
	if type(at) == "number" and at < chain.started then return end
	local t = tourOf(p)
	if chain.tour ~= t then drop(p); return end -- "reset": the tour it ran on is gone
	if what == "done" or what == "skip" then
		if finished(t) then finish(p, chain) end
		return
	end
	if what == "take" and t.got.take then chain.returnAt = nil end -- the request is taken: card 1 never comes back (B1)
	-- a step the open card waited on is done another way (card 1 after a pick at the laptop): it leaves (fix round 1)
	local card = chain.card
	if card and staleCard(p, card) then close(p, chain, "taken") end
	busy(p, chain)
end

-- the join path and the hook's starts ------------------------------------------------------------------------------

-- in your own plot's bedroom
local function inBedroom(p, R)
	local place = R.PlaceOf(p)
	return type(place) == "table" and place.kind == "bedroom" and place.slot == R.PlotOf(p)
end
-- the wake-up: until you stand in your bedroom (at most WakeWait; at once with no slot), then the card Next names
-- queued FirstCard seconds out (and a step then, so it doesn't wait for the loop)
local function wake(p, chain)
	local R = rooms()
	local t0 = os.clock()
	if R and R.PlotOf(p) then
		while alive(p, chain) and os.clock() - t0 < C.WakeWait and not inBedroom(p, R) do task.wait(0.25) end
	end
	if not alive(p, chain) then return end
	local n = Rules.Next(tourOf(p))
	if not (n and CARDS[n]) or chain.card or chain.pending then return end
	chain.pending = { id = n, at = os.clock() + C.FirstCard }
	task.delay(C.FirstCard + 0.05, function()
		if not alive(p, chain) then return end
		local ok, err = pcall(step, p)
		if not ok then report("first card: " .. tostring(err)) end
	end)
end
-- the join path: "held" under the test hold, "done" for a finished tour (no chain), "gone" for a player who left while
-- the profile loaded, else the chain starts and waits for the wake-up ("waiting")
local function join(p)
	if held() then return "held" end
	local t = tourOf(p) -- waits for the profile's load
	if p.Parent ~= Players then return "gone" end -- left meanwhile (onLeave already cleared the memory)
	if finished(t) then return "done" end
	local chain = newChain(p)
	busy(p, chain)
	task.spawn(function()
		local ok, err = pcall(wake, p, chain)
		if not ok then report("wake: " .. tostring(err)) end
	end)
	return "waiting"
end
-- a chain now, past the hold, with the card Next names queued and sent unless something blocks it; Next's id. A finished
-- tour starts nothing (nil; ruling m6)
local function start(p)
	local t = tourOf(p)
	if finished(t) then return nil end
	local chain = newChain(p)
	local n = Rules.Next(t)
	if n and CARDS[n] then
		chain.pending = { id = n, at = os.clock() }
		sendPending(p, chain)
	end
	busy(p, chain)
	return n
end
-- staging: card `id` sent now, unchecked (a chain started first if none runs, or replacing a finished one); "speakers"
-- takes its beat from the chain, else the newest recent beat. The id, or nil for an unknown one
local function show(p, id)
	if type(id) ~= "string" or type(D.Cards[id]) ~= "table" then return nil end
	local chain = chains[p.UserId]
	if not chain or chain.done then chain = newChain(p) end
	if id == "speakers" and not chain.beat then
		local r = Contracts.Recent(p)[1]
		if r then chain.beat = { pattern = r.pattern, bpm = r.bpm, swing = 0 } end
	end
	local payload = send(p, chain, id)
	if payload then chain.card.staged = true end -- B1's Show exemption: never closed or refused as stale
	busy(p, chain)
	return payload and id or nil
end

-- WalkIns' hook Reset (OnReset, F6): the chain, DayOneBusy and the forced roll; the saved d1 and the Sent log stay (review
-- minor 2: a test that resets walk-ins mid-case keeps its haggle)
local function dropForWalkIns(p)
	drop(p)
	rolls[p.UserId] = nil
end
local function reset(p)
	drop(p)
	local uid = p.UserId
	rolls[uid], opened[uid] = nil, nil
	local prof = ctx.Data.GetProfile(p)
	if type(prof.tour) == "table" and prof.tour.d1 ~= nil then prof.tour.d1 = nil; ctx.Data.MarkDirty(p) end
	if sentLog then sentLog[uid] = nil end
	return true
end

-- API ----------------------------------------------------------------------------------------------------------------

-- a choice on the open card: index 0 is SKIP, 1.. the card's choices in order. { ok = true }, or { ok = false, reason =
-- "stale" } (no card open, another token, or an open card the tour no longer names: that card leaves, nothing is applied)
-- or "invalid" (an index the card hasn't; the card stays open)
function M.Choose(p, token, index)
	if not ctx then return { ok = false, reason = "stale" } end
	local card, chain = openCard(p)
	if not card or type(token) ~= "string" or token ~= card.token then return { ok = false, reason = "stale" } end
	if staleCard(p, card) then -- the request was taken another way a moment ago (the take handler runs a frame late)
		close(p, chain, "taken")
		busy(p, chain)
		return { ok = false, reason = "stale" }
	end
	local def = D.Cards[card.id]
	local n = type(def) == "table" and type(def.choices) == "table" and #def.choices or 0
	if type(index) ~= "number" or index ~= math.floor(index) or index < 0 or index > n then return { ok = false, reason = "invalid" } end
	if index == 0 then -- SKIP: the chain ends here, inline, so Tour's deferred "skip" finds it done (one ArmFirst)
		finish(p, chain)
		Tour.Skip(p)
		return { ok = true }
	end
	local fn = CHOOSE[card.id]
	if not fn then return { ok = false, reason = "invalid" } end
	local key = def.choices[index].key
	close(p, chain, key)
	local ok, err = pcall(fn, p, chain, key)
	if not ok then report("choose " .. tostring(card.id) .. " " .. tostring(key) .. ": " .. tostring(err)) end
	busy(p, chain)
	return { ok = true }
end
-- the open card's payload (as "arrive" sent it), or nil
function M.Get(p)
	local card = openCard(p)
	return card and card.payload or nil
end
-- a Day One chain runs for p (started and not ended)
function M.Running(p)
	local chain = chains[p.UserId]
	return chain ~= nil and not chain.done
end

-- the Studio hook ----------------------------------------------------------------------------------------------------

local function snapshot(p)
	local chain = chains[p.UserId]
	local t = tourOf(p)
	local card = chain and chain.card
	local pend = chain and chain.pending
	return {
		d1 = t.d1 ~= nil and Rules.Repair(t.d1) or nil, next = Rules.Next(t), busy = p:GetAttribute("DayOneBusy"),
		running = chain ~= nil and not chain.done, done = chain ~= nil and chain.done or nil,
		card = card and { token = card.token, id = card.id, at = card.at } or nil,
		pending = pend and { id = pend.id, at = pend.at } or nil,
		returned = chain and chain.returned or nil, returnAt = chain and chain.returnAt or nil,
		started = chain and chain.started or nil, now = os.clock(),
	}
end
local function age(p, s)
	local chain = chains[p.UserId]
	if not chain or type(s) ~= "number" then return false end
	chain.started -= s
	if chain.card then chain.card.at -= s end
	if chain.pending then chain.pending.at -= s end
	if chain.returnAt then chain.returnAt -= s end
	return true
end
local function makeHook()
	local SOK = game:GetService("ServerScriptService"):FindFirstChild("OK")
	if not SOK then return end
	local hook = SOK:FindFirstChild("_StudioDayOneHook") or Instance.new("BindableFunction")
	hook.Name = "_StudioDayOneHook"; hook.Parent = SOK
	sentLog = sentLog or {}
	DAW.Opened:Connect(function(q)
		if typeof(q) == "Instance" then opened[q.UserId] = (opened[q.UserId] or 0) + 1 end
	end)
	hook.OnInvoke = function(cmd, userId, a, b)
		local p = Players:GetPlayerByUserId(userId)
		if not p then return nil end
		local uid = p.UserId
		if cmd == "Joined" then return join(p) end
		if cmd == "Start" then return start(p) end
		if cmd == "Show" then return show(p, a) end
		if cmd == "Open" then
			local card = openCard(p)
			return card and { token = card.token, id = card.id } or nil
		end
		if cmd == "Choose" then
			local card = openCard(p)
			return M.Choose(p, card and card.token or nil, a)
		end
		if cmd == "Pick" then -- the laptop picker's path (Session_Pick's handler); no id: another artist's offered brief
			local id = a
			if id == nil then
				local starter = Rules.Starter(Artists.Briefs)
				for _, o in ipairs(Contracts.Offers(p)) do
					local brief = Artists.BriefById[o.id]
					if brief and not (starter and brief.artist == starter.artist) then id = o.id; break end
				end
			end
			local res = Contracts.Pick(p, id)
			return { ok = type(res) == "table" and res.ok == true, reason = type(res) == "table" and res.reason or nil, id = id }
		end
		if cmd == "ChooseToken" then return M.Choose(p, a, b) end
		if cmd == "Get" then return M.Get(p) end
		if cmd == "State" then return snapshot(p) end
		if cmd == "Sent" then local l = sentLog[uid] or {}; sentLog[uid] = nil; return l end
		if cmd == "Opened" then local n = opened[uid] or 0; opened[uid] = nil; return n end
		if cmd == "SetRoll" then rolls[uid] = tonumber(a); return true end
		if cmd == "Age" then return age(p, a) end
		if cmd == "Tick" then step(p); return true end
		if cmd == "Reset" then return reset(p) end
		return nil
	end
end

-- start ----------------------------------------------------------------------------------------------------------------

local function onJoin(p)
	if joined[p] ~= nil then return end
	joined[p] = false
	local function first()
		if joined[p] then return end
		joined[p] = true
		task.spawn(function()
			local ok, err = pcall(join, p)
			if not ok then report("join: " .. tostring(err)) end
		end)
	end
	local conn
	conn = p.CharacterAdded:Connect(function()
		conn:Disconnect()
		first()
	end)
	if p.Character then conn:Disconnect(); first() end
end
local function onLeave(p)
	local uid = p.UserId
	joined[p] = nil
	chains[uid], rolls[uid], opened[uid] = nil, nil, nil
	if sentLog then sentLog[uid] = nil end
end
local function loop()
	while true do
		task.wait(1)
		for _, p in ipairs(Players:GetPlayers()) do
			if chains[p.UserId] then
				local ok, err = pcall(step, p)
				if not ok then report(err) end
			end
		end
	end
end

function M.Init(c)
	ctx = c
	C = Config.DayOne
	assert(type(C) == "table", "Config.DayOne missing (sync OK/Config)")
	local R = RS.OK.Remotes
	dayOneEv = R.DayOne
	R.DayOne_Choose.OnServerInvoke = function(player, token, index) return M.Choose(player, token, index) end
	R.DayOne_Get.OnServerInvoke = function(player) return M.Get(player) end
	Tour.Changed:Connect(function(p, what, at)
		local ok, err = pcall(onChanged, p, what, at)
		if not ok then report("tour changed: " .. tostring(err)) end
	end)
	local W = walkIns()
	if W and W.OnReset then W.OnReset(dropForWalkIns) end -- WalkIns' hook Reset drops a Day One chain too (F6)
	Players.PlayerAdded:Connect(onJoin)
	Players.PlayerRemoving:Connect(onLeave)
	for _, p in ipairs(Players:GetPlayers()) do onJoin(p) end
	task.spawn(loop)
	if RunService:IsStudio() and RunService:IsRunning() then makeHook() end
end

return M
