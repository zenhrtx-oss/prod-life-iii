-- Server, during play (Wave 1b Task 3; Review Focus 2): rush hour through the WalkIns hook, paused, Quiet on. A cycle
-- is Spawn (navx_placement, a walker) then Expire before he arrives, which re-arms the presence timer at once through
-- endVisit (an expired visit never counts toward today). The hook's Rush(uid, k) makes the next re-arm start a burst
-- of k whatever the hold.
-- (1) Rush(3): the first re-arm is a short gap (Config.WalkIns.Rush.Short, 10..20) and sets BusyDay; (2) two more short
-- gaps keep it, then the quiet gap (Gap plus the seconds the shorts saved) clears BusyDay and the rush; (3) E2: a timer
-- at 0 behind an open DM during a burst re-arms short, not with a full Gap; (4) E2 residual: a timer under the short
-- minimum behind an open DM is floored at Short[1] and the burst goes on (both unpaused for 2 s, re-paused on every
-- exit); (5) the cap reached mid-burst ends it with a plain Gap (its saved seconds dropped); (6) a WalkIns Reset ends it,
-- and so does Rush(uid, 0). Tail for t60b, after the cleanup: a burst running (BusyDay true) and scam_curator popped
-- with Quiet off, a held pop opening between burst cards (t61a's fresh() clears both).
-- Wave 3: every case runs past the first-ever visit (AdvanceVisits 1 after each WalkIns Reset) with the tour done, since
-- at count 0 an aborted visit re-arms from FirstEver with no burst, and an unfinished tour starts or keeps none (t76a).
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local Tour = require(RS.OK.Systems.Tour)
local W = require(RS.OK.Config).WalkIns
local R = W.Rush; assert(R and R.Short, "Config.WalkIns.Rush missing")
local LOUNGE = Vector3.new(24, 3, 0)
local DM, WALKER = "scam_curator", "navx_placement"
local out = {}

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
local function busyDay() return p:GetAttribute("BusyDay") end
local function left() return wi:Invoke("GetRemaining", uid) end
local function rush() return wi:Invoke("Rush", uid) end
local function short(s) return type(s) == "number" and s >= R.Short[1] and s <= R.Short[2] end
-- past the first-ever visit (count 1) with the tour done: where a burst can run (Wave 3)
local function pastFirst(label)
	for _, s in ipairs(Tour.Steps) do test:Invoke("TourAdvance", uid, s.id) end
	assert(wi:Invoke("AdvanceVisits", uid, 1) == true, label .. ": AdvanceVisits failed")
end
-- the file's own fresh(): unseated and in the lounge, Quiet on, WalkIns and Career reset, past the first-ever visit;
-- then the case's checks start from no rush, BusyDay false and the timer far off
local function fresh(label)
	local c = p.Character; local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum and hum.Sit then hum.Sit = false; task.wait(0.4) end
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, label .. ": Quiet(true) failed")
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	assert(busyDay() == false and rush() == nil and left() == 1e6, label .. ": after Reset want BusyDay false, no rush, timer 1e6; got "
		.. tostring(busyDay()) .. ", " .. tostring(rush() ~= nil) .. ", " .. tostring(left()))
	pastFirst(label)
end
local function startRush(label, k) assert(wi:Invoke("Rush", uid, k) == true, label .. ": the hook's Rush(" .. k .. ") failed") end
-- one cycle: Spawn a walker (navx_placement walks in from the door, so he can't arrive and count before the Expire),
-- then Expire (endVisit re-arms at once); returns the timer
local function cycle(label)
	assert(wi:Invoke("Spawn", uid, WALKER) == true, label .. ": Spawn(" .. WALKER .. ") refused (is the player in the hub?)")
	assert(wi:Invoke("Expire", uid) == true, label .. ": Expire found no visit")
	return left()
end
-- a burst card's re-arm: a short gap, BusyDay set, `n` short gaps still to come
local function shortCycle(label, n)
	local s = cycle(label)
	local r = rush()
	assert(short(s), label .. ": want a short gap in " .. R.Short[1] .. ".." .. R.Short[2] .. ", got " .. tostring(s))
	assert(busyDay() == true, label .. ": BusyDay is " .. tostring(busyDay()) .. " during the burst")
	assert(r and r.left == n and r.busy == true, label .. ": Rush() should read left " .. n .. ", busy true; got "
		.. tostring(r and r.left) .. ", " .. tostring(r and r.busy))
	return s, r
end
local function pop() local t = ph:Invoke("Pop", uid, DM); assert(type(t) == "string", "Pop(" .. DM .. ") sent nothing"); return t end
-- unpaused for `s` seconds (the live loop ticks), then the timer; re-paused on every exit
local function unpaused(label, s)
	local ok, res = pcall(function()
		assert(wi:Invoke("Pause", uid, false) == true, label .. ": unpause failed")
		task.wait(s)
		return { left = left(), busy = busyDay(), pending = wi:Invoke("Pending", uid) }
	end)
	assert(wi:Invoke("Pause", uid, true) == true, label .. ": re-pause failed")
	if not ok then error(res, 0) end
	return res
end
-- an open DM (PhoneBusy) between burst cards
local function openDM(label)
	assert(ph:Invoke("Open", uid, pop()) == true and p:GetAttribute("PhoneBusy") == true, label .. ": the DM did not open (PhoneBusy not set)")
end

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")

	-- 1, 2: a burst of 3 short gaps, then the quiet gap adds back what they saved
	fresh("burst")
	startRush("burst", 3)
	local s1 = shortCycle("burst 1", 2)
	local s2 = shortCycle("burst 2", 1)
	local s3, r3 = shortCycle("burst 3", 0)
	local q = cycle("quiet")
	assert(type(q) == "number" and q >= W.Gap[1], "quiet: want the quiet gap >= " .. W.Gap[1] .. ", got " .. tostring(q))
	assert(q - r3.saved >= W.Gap[1] and q - r3.saved <= W.Gap[2], string.format("quiet: %s minus the %d s saved should be a Gap draw in %d..%d",
		tostring(q), r3.saved, W.Gap[1], W.Gap[2]))
	assert(busyDay() == false and rush() == nil, "quiet: BusyDay " .. tostring(busyDay()) .. " / rush left after the quiet gap")
	table.insert(out, string.format("burst: Rush(3) -> short gaps %d, %d, %d with BusyDay; quiet gap %d (Gap + %d saved), BusyDay off", s1, s2, s3, q, r3.saved))

	-- 3: E2, a run-out timer behind an open DM during a burst re-arms short
	fresh("E2")
	startRush("E2", 2)
	shortCycle("E2", 1)
	assert(wi:Invoke("SetRemaining", uid, 0) == true, "E2: SetRemaining(0) failed")
	openDM("E2")
	local e2 = unpaused("E2", 2)
	assert(e2.pending == nil, "E2: a walk-in was scheduled behind the open DM")
	assert(short(e2.left), "E2: the run-out timer behind the DM should re-arm short (" .. R.Short[1] .. ".." .. R.Short[2] .. "), not with a full Gap; got " .. tostring(e2.left))
	assert(e2.busy == true, "E2: BusyDay is " .. tostring(e2.busy) .. " after the short re-arm")
	table.insert(out, "E2: timer 0 behind an open DM mid-burst -> re-armed short (" .. tostring(e2.left) .. " s), BusyDay kept")

	-- 4: E2 residual, a timer under the short minimum behind an open DM is floored at Short[1]
	fresh("E2 residual")
	startRush("E2 residual", 2)
	shortCycle("E2 residual", 1)
	assert(wi:Invoke("SetRemaining", uid, 3) == true, "E2 residual: SetRemaining(3) failed")
	openDM("E2 residual")
	local e3 = unpaused("E2 residual", 2)
	assert(e3.pending == nil, "E2 residual: a walk-in was scheduled behind the open DM")
	assert(e3.left == R.Short[1], "E2 residual: 3 s left behind the DM should be floored at " .. R.Short[1] .. ", got " .. tostring(e3.left))
	assert(e3.busy == true and rush() ~= nil, "E2 residual: the burst ended behind the DM")
	table.insert(out, "E2 residual: 3 s behind an open DM mid-burst -> floored at " .. tostring(e3.left) .. " s, burst kept")

	-- 5: the cap reached mid-burst ends it; the re-arm is a plain Gap, its saved seconds dropped
	fresh("cap")
	startRush("cap", 3)
	shortCycle("cap", 2)
	assert(wi:Invoke("SetToday", uid, W.DailyMax) == true, "cap: SetToday(" .. W.DailyMax .. ") failed")
	local c = cycle("cap") -- Spawn ignores the cap
	assert(busyDay() == false and rush() == nil, "cap: the burst outlived the cap (BusyDay " .. tostring(busyDay()) .. ")")
	assert(type(c) == "number" and c >= W.Gap[1] and c <= W.Gap[2], "cap: want a plain Gap " .. W.Gap[1] .. ".." .. W.Gap[2] .. " (saved dropped), got " .. tostring(c))
	table.insert(out, "cap: today " .. W.DailyMax .. " mid-burst -> BusyDay off, no rush, plain Gap " .. tostring(c))

	-- 6: a WalkIns Reset ends a burst; so does the hook's Rush(uid, 0)
	fresh("reset")
	startRush("reset", 2)
	shortCycle("reset", 1)
	assert(wi:Invoke("Reset", uid) == true, "reset: Reset failed")
	assert(busyDay() == false and rush() == nil and left() == 1e6, "reset: after Reset want BusyDay false, no rush, timer 1e6")
	pastFirst("Rush(0)")
	startRush("Rush(0)", 2)
	shortCycle("Rush(0)", 1)
	assert(wi:Invoke("Rush", uid, 0) == true, "Rush(0): the hook failed")
	assert(busyDay() == false and rush() == nil, "Rush(0): BusyDay " .. tostring(busyDay()) .. " / rush left")
	table.insert(out, "reset: WalkIns Reset mid-burst -> BusyDay off, no rush, timer 1e6; Rush(0) clears too")

	return "T60A PLAY OK\n" .. table.concat(out, "\n")
end

local ok, msg = pcall(run)
pcall(function()
	wi:Invoke("SetRemaining", uid, 1e6); wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); ph:Invoke("Quiet", uid, false)
end)
pcall(teleport, LOUNGE)
if not ok then error(msg, 0) end
-- staging for t60b, after the cleanup (its Reset would end the burst and drop the pop): a burst under way, then a held
-- DM popping between its cards with Quiet off, so the client opens it
pastFirst("tail") -- the cleanup's Reset put count back to 0
startRush("tail", 2)
shortCycle("tail", 1)
assert(ph:Invoke("Quiet", uid, false) == true, "tail: Quiet(false) failed")
pop()
return msg
