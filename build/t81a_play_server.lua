-- Server, during play (Wave 3 Task 5b+, the starter pool; the user's call of 2026-11-06): the very first walk-in is drawn
-- at random from the starter pool, the `first` cards of Data/WalkIns. The file's own fresh() (unseated in the lounge,
-- Quiet on, WalkIns, Career and Life Reset, ResetHints).
-- (1) The real first-ever timer: ResetTour (the tour not done: the first-ever visit skips it), SetRemaining(nil) and the
--     hold set to false for this file only (present, so no burst and no heal, as t76a's stage): a visit is pending within
--     25 s of the reset and it is a starter; he arrives, the arrive payload's card is the same id, and the visit counts.
-- (2) The sweep at count 0: for k = 1..N (N = the starters' total weight), WalkIns Reset, SetRng({ k }), Spawn() (the
--     scheduler's own pick: Seed, then one draw over the starters), then Expire before he arrives. Every pick is a
--     starter, and with every weight 1 the sweep reaches each of them exactly once (distinct == the starter count).
--     Before the Task 5b+ sync the pool is gentle_first alone: the expected red.
-- (3) At count 1 (AdvanceVisits 1), Spawn() with the draw forced low, high and in the middle never picks a starter.
-- Cleanup either way: the hold back to true, WalkIns, Career and Life Reset, ResetHints, the tour done, Quiet off.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local Content = require(RS.OK.Data.WalkIns)
local Tour = require(RS.OK.Systems.Tour)
local W = require(RS.OK.Config).WalkIns
local LOUNGE = Vector3.new(24, 3, 0)
local out = {}
local T0 = os.clock()

-- the starter pool as the live content has it: `first` cards in deck order, and their total weight (the draw's range)
local STARTERS, TOTAL = {}, 0
for _, c in ipairs(Content.Cards) do
	if c.first then table.insert(STARTERS, c.id); TOTAL += c.weight or 1 end
end
local function isStarter(id) local c = Content.CardById[id]; return c ~= nil and c.first == true end

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function root() local c = p.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function teleport(pos) -- server-side; checked, and tried once more if the client's position won
	for _ = 1, 2 do
		local c = p.Character or p.CharacterAdded:Wait()
		c:WaitForChild("HumanoidRootPart", 5)
		c:PivotTo(CFrame.new(pos))
		task.wait(0.3)
		local r = root()
		if r and flat(r.Position - pos) < 2 then return r end
	end
	error("teleport to " .. tostring(pos) .. " did not take")
end
local function walkins() return test:Invoke("GetProfile", uid).walkins end
local function pending() return wi:Invoke("Pending", uid) end
local function arrived() local r = pending(); return r ~= nil and r.arrived == true end
local function left() return wi:Invoke("GetRemaining", uid) end
local function within(x, range, slack) return type(x) == "number" and x >= range[1] - (slack or 0) and x <= range[2] end
local function advanceTour() for _, s in ipairs(Tour.Steps) do test:Invoke("TourAdvance", uid, s.id) end end
local function tourDone() local t = test:Invoke("GetProfile", uid).tour; return type(t) == "table" and t.done == true end
-- the newest "arrive" payload in the walk-in hook's Sent (the read drains it)
local function lastArrive()
	local got
	for _, e in ipairs(wi:Invoke("Sent", uid)) do if e.kind == "arrive" then got = e.payload end end
	return got
end
-- the file's own fresh(): unseated and in the lounge, Quiet on, WalkIns, Career and Life reset, no hint seen
local function fresh(label)
	local c = p.Character; local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum and hum.Sit then hum.Sit = false; task.wait(0.4) end
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, label .. ": Quiet(true) failed")
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	assert(life:Invoke("Reset", uid) == true, label .. ": Life Reset failed")
	assert(test:Invoke("ResetHints", uid) == true, label .. ": ResetHints failed")
end
-- `fn` with the hold false (the loop ticks: bursts and the heal stay held), then the hold back; returns fn()'s value
local function unheld(label, fn)
	local ok, res = pcall(function()
		assert(wi:Invoke("Pause", uid, false) == true, label .. ": Pause(false) failed")
		return fn()
	end)
	assert(wi:Invoke("Pause", uid, true) == true, label .. ": Pause(true) failed")
	if not ok then error(res, 0) end
	return res
end
-- the scheduler's own pick (Spawn with no id) with the next draw forced to `k`, sent out before he arrives; returns its id
local function forcedPick(label, k)
	assert(wi:Invoke("SetRng", uid, { k }) == true, label .. ": SetRng failed")
	assert(wi:Invoke("Spawn", uid) == true, label .. ": Spawn() refused (is the player in the hub?)")
	local r = pending()
	assert(r and type(r.id) == "string" and r.arrived ~= true, label .. ": no visit pending after Spawn()")
	assert(wi:Invoke("Expire", uid) == true, label .. ": Expire found no visit")
	return r.id
end

local function run()
	assert(#STARTERS >= 2, "the content has " .. #STARTERS .. " `first` card(s) (" .. table.concat(STARTERS, ", ")
		.. "): no pool to draw from (before the Task 5b+ sync only gentle_first: the expected red)")
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")

	-- 1. the real first-ever timer brings a starter
	fresh("first-ever")
	local t0 = os.clock()
	assert(test:Invoke("ResetTour", uid) == true and not tourDone(), "first-ever: ResetTour failed")
	assert(walkins().count == 0, "first-ever: count is " .. tostring(walkins().count) .. " after WalkIns Reset, want 0")
	wi:Invoke("Sent", uid)
	assert(wi:Invoke("SetRemaining", uid, nil) == true, "first-ever: SetRemaining(nil) failed") -- a fresh join's timer
	local armed, scheduled, due
	unheld("first-ever", function()
		assert(waitFor(function() armed = left(); return type(armed) == "number" end, 2.5), "first-ever: the loop did not arm the timer within 2.5 s in the lounge")
		assert(within(armed, W.FirstEver, 3), "first-ever: the first timer armed at " .. tostring(armed) .. ", want FirstEver "
			.. W.FirstEver[1] .. ".." .. W.FirstEver[2])
		scheduled = waitFor(function() return pending() ~= nil end, 25 - (os.clock() - t0))
		due = os.clock() - t0
	end) -- the hold back: the visit in flight walks on
	assert(scheduled, string.format("first-ever: no visit pending %.1f s after the reset", due))
	local r1 = pending()
	assert(isStarter(r1.id), "first-ever: the first-ever visit is " .. tostring(r1.id) .. ", want a starter (" .. table.concat(STARTERS, ", ") .. ")")
	assert(waitFor(arrived, math.max(1, 35 - (os.clock() - t0))), string.format("first-ever: he did not arrive within 35 s of the reset (%.1f s)", os.clock() - t0))
	local a1 = lastArrive()
	assert(type(a1) == "table" and type(a1.card) == "table" and a1.card.id == r1.id, "first-ever: no arrive payload for " .. r1.id)
	assert(walkins().count == 1, "first-ever: count is " .. tostring(walkins().count) .. " after the arrival, want 1")
	assert(wi:Invoke("Choose", uid, pending().token, 0).ok == true, "first-ever: walk away failed")
	table.insert(out, string.format("1 the first-ever timer (armed %d s, FirstEver %d..%d, tour not done): %s pending %.1f s after the reset, arrived, count 1",
		armed, W.FirstEver[1], W.FirstEver[2], r1.id, due))

	-- 2. the forced sweep at count 0: every draw is a starter, and the draws reach more than one
	local seen, distinct, picks = {}, 0, {}
	for k = 1, TOTAL do
		fresh("sweep " .. k)
		local id = forcedPick("sweep " .. k, k)
		assert(isStarter(id), "sweep " .. k .. ": the pick at count 0 is " .. id .. ", want a starter")
		assert(walkins().count == 0, "sweep " .. k .. ": a visit that never arrived counted")
		if not seen[id] then seen[id] = true; distinct += 1 end
		table.insert(picks, k .. "->" .. id)
	end
	-- every starter's weight is 1 (the data spec forbids `weight` on one), so draw k is the k-th starter in deck order and
	-- the sweep reaches each exactly once; a forced value used up by some other draw before Pick would repeat a card
	-- (review Minor 7)
	assert(TOTAL == #STARTERS, "sweep: the starters weigh " .. TOTAL .. " in all, want " .. #STARTERS .. " (every weight 1)")
	assert(distinct == #STARTERS, "sweep: " .. TOTAL .. " forced draws at count 0 reached " .. distinct .. " of the " .. #STARTERS
		.. " starters: " .. table.concat(picks, ", "))
	table.insert(out, string.format("2 forced draws 1..%d at count 0: %d different starters (%s)", TOTAL, distinct, table.concat(picks, ", ")))

	-- 3. past the first visit no starter ever comes. Each draw on a fresh state: Expire keeps the stored pick, which the
	-- next Spawn() would reuse without drawing
	local late = {}
	for _, k in ipairs({ 1, math.max(1, TOTAL // 2), 1e6 }) do
		fresh("count 1 draw " .. k)
		assert(wi:Invoke("AdvanceVisits", uid, 1) == true and walkins().count == 1, "count 1: AdvanceVisits failed")
		assert(walkins().next == nil, "count 1: a stored pick survived the Reset")
		local id = forcedPick("count 1 draw " .. k, k)
		assert(not isStarter(id), "count 1: the draw forced to " .. k .. " picked the starter " .. id)
		table.insert(late, id)
	end
	table.insert(out, "3 count 1, draws forced low, middle and high: " .. table.concat(late, ", ") .. " (no starter)")
end

local ok, msg = pcall(run)
pcall(function()
	wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
	test:Invoke("ResetHints", uid); advanceTour(); ph:Invoke("Quiet", uid, false)
end)
pcall(teleport, LOUNGE)
if not ok then error(msg, 0) end
return "T81A PLAY OK\n" .. table.concat(out, "\n") .. string.format("\nelapsed %.1f s", os.clock() - T0)
