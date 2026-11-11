-- CLI rush-hour check (design 4.5, and 6 "Rush hour and pace"): WalkInRules.RushGap run on the walk-in presence timer
-- over 1,000 simulated days, with and without rush, on the same seeds. A day is FirstDelay, then a visit each time the
-- timer runs out and a gap after it; the day stops at the daily cap (no gap after the last visit) or once the timer
-- passes its presence budget, and a rush still running then is dropped with its saved seconds (the cap and leaving
-- clear it in WalkIns). Every day starts with no rush, and a burst starts only with room for its smallest size before
-- the cap (WalkInRules.RushRoom, nextGap's gate).
-- Asserts: where the cap binds (3,600 presence seconds a day) no day goes over the cap and visits per day are the same
-- with and without rush; every burst that finishes has 2 or 3 short gaps, its short gaps plus its quiet gap equal the
-- k + 1 normal gaps it replaced, and every short gap is in Short; at least 50 bursts finish. At 1,800 presence seconds
-- it prints the visit lift and the gap-mean change, no assert (ruling "Rush pulls visits forward").
-- The literals are copies of Config.WalkIns (Config can't load in the CLI); build/t46_check.lua's RUSH_SPEC pins them.
-- Run: sh tools/spec.sh rush
local Sim = require("../src/ReplicatedStorage/OK/Modules/CareerSim")
local R = require("../src/ReplicatedStorage/OK/Modules/WalkInRules")

local fails = {}
local function ok(name, cond) if not cond then table.insert(fails, name) end end

local RUSH = { Chance = 0.15, Size = { 2, 3 }, Short = { 10, 20 } }
local GAP = { 240, 360 }
local FIRST = { 60, 120 }
local DAILY = 8

local DAYS = 1000
local SEED = 2026          -- draw's seed
local ROLL_STREAM = 100003 -- roll's seed is SEED + this (CareerSim's phone-stream offset), so the two streams differ

local function sum(list)
	local s = 0
	for _, v in ipairs(list) do s += v end
	return s
end

-- DAYS days at `budget` presence seconds a day, with RushGap (rushOn) or today's plain normal gap. Returns visits
-- (total, per day, max in a day), the gaps drawn (count, total, mean) and the bursts: every short gap drawn (shorts),
-- how many started, and the finished ones as { shorts = {...}, normals = {...}, quiet = n }
local function run(budget, rushOn)
	local base, lcg2 = Sim.Lcg(SEED), Sim.Lcg(SEED + ROLL_STREAM)
	local function roll() return lcg2(1, 10000) / 10000 end
	local normals = {} -- the normal draws (GAP's range) made since the last gap began
	local function draw(lo, hi)
		local v = base(lo, hi)
		if lo == GAP[1] and hi == GAP[2] then table.insert(normals, v) end
		return v
	end
	local res = { visits = 0, maxVisits = 0, gaps = 0, gapTotal = 0, shorts = {}, started = 0, finished = {} }
	for _ = 1, DAYS do
		local t, visits, rush, burst = draw(FIRST[1], FIRST[2]), 0, nil, nil
		while t <= budget do
			visits += 1
			if visits >= DAILY then break end
			table.clear(normals)
			local g
			if rushOn then
				local before = rush
				-- nextGap's gate: a burst starts only with room for its smallest size before the cap (visits is today's
				-- count here, and every simulated day is the same UTC day)
				g, rush = R.RushGap(rush, RUSH, GAP, draw, roll, R.RushRoom(visits, DAILY, RUSH.Size, true))
				if before == nil and rush ~= nil then
					burst = { shorts = {}, normals = {} }
					res.started += 1
				end
				if burst then
					for _, v in ipairs(normals) do table.insert(burst.normals, v) end
					if rush ~= nil then
						table.insert(burst.shorts, g)
						table.insert(res.shorts, g)
					else
						burst.quiet = g
						table.insert(res.finished, burst)
						burst = nil
					end
				end
			else
				g = draw(GAP[1], GAP[2])
			end
			res.gaps += 1
			res.gapTotal += g
			t += g
		end
		res.visits += visits
		res.maxVisits = math.max(res.maxVisits, visits)
	end
	res.perDay = res.visits / DAYS
	res.gapMean = res.gapTotal / res.gaps
	return res
end

-- the burst invariants, on every burst a rush run saw
local function checkBursts(name, res)
	for i, b in ipairs(res.finished) do
		local k = #b.shorts
		ok(string.format("%s burst %d: %d short gaps, want 2 or 3", name, i, k), k == 2 or k == 3)
		ok(string.format("%s burst %d: %d normal draws, want k + 1 = %d", name, i, #b.normals, k + 1), #b.normals == k + 1)
		ok(string.format("%s burst %d: short gaps %d + quiet %d ~= normal draws %d", name, i, sum(b.shorts), b.quiet,
			sum(b.normals)), sum(b.shorts) + b.quiet == sum(b.normals))
	end
	for i, s in ipairs(res.shorts) do
		ok(string.format("%s short gap %d: %s outside %d..%d", name, i, tostring(s), RUSH.Short[1], RUSH.Short[2]),
			s >= RUSH.Short[1] and s <= RUSH.Short[2])
	end
end

-- where the cap binds: the same visits with and without rush, never over the cap
local capOff, capOn = run(3600, false), run(3600, true)
ok(string.format("3600 s without rush: max %d visits in a day <= %d", capOff.maxVisits, DAILY), capOff.maxVisits <= DAILY)
ok(string.format("3600 s with rush: max %d visits in a day <= %d", capOn.maxVisits, DAILY), capOn.maxVisits <= DAILY)
ok(string.format("3600 s: visits per day %.3f with rush == %.3f without", capOn.perDay, capOff.perDay),
	capOn.perDay == capOff.perDay)
checkBursts("3600 s", capOn)
ok(string.format("3600 s: %d bursts finished, want >= 50", #capOn.finished), #capOn.finished >= 50)

-- a shorter session: rush pulls visits forward (printed, no assert)
local shortOff, shortOn = run(1800, false), run(1800, true)
checkBursts("1800 s", shortOn)

local twos, threes = 0, 0
for _, b in ipairs(capOn.finished) do
	if #b.shorts == 2 then twos += 1 elseif #b.shorts == 3 then threes += 1 end
end
print(string.format("rush: %d days. 3600 s: visits/day %.2f without, %.2f with (max %d); bursts %d started, %d finished "
	.. "(%d of 2, %d of 3); gap mean %.1f -> %.1f s. 1800 s: visits/day %.2f -> %.2f (%+.1f%%); gap mean %.1f -> %.1f s "
	.. "(%+.1f%%); bursts %d started, %d finished",
	DAYS, capOff.perDay, capOn.perDay, capOn.maxVisits, capOn.started, #capOn.finished, twos, threes, capOff.gapMean,
	capOn.gapMean, shortOff.perDay, shortOn.perDay, (shortOn.perDay / shortOff.perDay - 1) * 100, shortOff.gapMean,
	shortOn.gapMean, (shortOn.gapMean / shortOff.gapMean - 1) * 100, shortOn.started, #shortOn.finished))
if #fails > 0 then error(#fails .. " rush case(s) failed: " .. table.concat(fails, "; ")) end
print("SPEC OK: rush")
