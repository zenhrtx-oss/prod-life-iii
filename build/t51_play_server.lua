-- Server, during play: the phone scheduler through its Studio hook, under the suite's pause (Tick moves the phone's
-- timer; the live loop never runs). Quiet keeps the pops off the client. Step 1 is the positive control for the
-- blockers in 2-4, each one condition away from it: a walk-in in flight, the unfinished tour and a walk-in due within
-- WalkInDueSeconds each stop a 200 s Tick (longer than the longest FirstDelay). Then MaxWaiting holds at 2; the day
-- caps at DailyMax with a waiting pop holding its slot and an expired one giving it back; a pop sent before UTC
-- midnight opens on the new day (the rollover at open); an opened DM blocks both the phone and the walk-in scheduler
-- until it is dismissed; the first pop comes inside FirstDelay; a cypher lobby blocks and idle lets it through.
-- Every step starts clean (fresh): WalkIns Reset (it ends any walk-in, parks its timer and resets the phone through
-- OnReset), the tour done, the phone at today 0.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local test, cy = SOK._StudioTestHook, SOK._StudioCypherHook
local Config = require(RS.OK.Config)
local P = Config.Phone
local Tour = require(RS.OK.Systems.Tour)
local LOUNGE = Vector3.new(24, 3, 0)
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
local function pops() return ph:Invoke("Pending", uid) end
local function npops() return #pops() end
local function state() return ph:Invoke("State", uid) end
local function phase() return RS.OK.Cypher:GetAttribute("Phase") end
local function advanceTour() for _, s in ipairs(Tour.Steps) do test:Invoke("TourAdvance", uid, s.id) end end
-- the clean start: WalkIns Reset (no walk-in, its timer at 1e6, the phone reset through OnReset), the tour done, the
-- phone reset at today 0, telemetry cleared
local function fresh(label)
	assert(wi:Invoke("Reset", uid) == true, label .. ": Reset failed")
	advanceTour()
	assert(ph:Invoke("Reset", uid) == true, label .. ": phone Reset failed")
	assert(ph:Invoke("SetToday", uid, 0) == true, label .. ": SetToday failed")
	assert(test:Invoke("ResetFunnelEvents", uid) == true, label .. ": ResetFunnelEvents failed")
	assert(npops() == 0 and p:GetAttribute("PhoneBusy") == nil, label .. ": a pop or PhoneBusy carried into the step")
end
local function tick(s) return ph:Invoke("Tick", uid, s) end

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	assert(ph:Invoke("Quiet", uid, true) == true, "Quiet(true) failed")
	assert(career:Invoke("Set", uid, { sponsor = false }) == true, "could not clear the sponsor deal")
	teleport(LOUNGE)

	-- 1 control: the timer at 2 s, a 3 s Tick sends one pop
	fresh("step 1")
	assert(ph:Invoke("SetRemaining", uid, 2) == true, "step 1: SetRemaining failed")
	local t1 = tick(3)
	assert(npops() == 1, "step 1: SetRemaining(2) then Tick(3) sent " .. npops() .. " pops, want 1")
	assert(type(t1) == "string" and pops()[1].token == t1, "step 1: Tick did not return the pop's token")
	table.insert(out, "1 control: SetRemaining(2), Tick(3) -> one pop (" .. pops()[1].id .. ")")

	-- 2 a walk-in in flight blocks
	fresh("step 2")
	assert(wi:Invoke("Spawn", uid) == true, "step 2: Spawn refused")
	tick(200)
	assert(npops() == 0, "step 2: a pop was sent while a walk-in was in flight")
	table.insert(out, "2 walk-in in flight: Tick(200) -> none")

	-- 3 the unfinished tour blocks
	fresh("step 3")
	assert(test:Invoke("ResetTour", uid) == true, "step 3: ResetTour failed")
	tick(200)
	assert(npops() == 0, "step 3: a pop was sent with the tour unfinished")
	advanceTour()
	table.insert(out, "3 tour unfinished: Tick(200) -> none")

	-- 4 a walk-in due within WalkInDueSeconds blocks (in the lounge, tour done, cypher idle, today under the cap)
	fresh("step 4")
	assert(wi:Invoke("SetRemaining", uid, 30) == true, "step 4: SetRemaining failed")
	tick(200)
	assert(npops() == 0, "step 4: a pop was sent with a walk-in due in 30 s (WalkInDueSeconds " .. P.WalkInDueSeconds .. ")")
	table.insert(out, "4 walk-in due in 30 s: Tick(200) -> none")

	-- 5 MaxWaiting: two pops wait, a third never comes
	fresh("step 5")
	tick(200); tick(200)
	assert(npops() == 2, "step 5: two Ticks sent " .. npops() .. " pops, want 2")
	tick(200)
	assert(npops() == 2, "step 5: a third pop was sent with " .. P.MaxWaiting .. " waiting")
	local a, b = pops()[1], pops()[2]
	assert(a.id ~= b.id, "step 5: the two waiting pops carry the same card " .. a.id)
	table.insert(out, "5 MaxWaiting: two Ticks -> 2 pops (" .. a.id .. ", " .. b.id .. "), a third -> none")

	-- 6 the day cap: a waiting pop holds its slot, an expired one gives it back, an opened one counts (every send by Tick)
	fresh("step 6")
	assert(ph:Invoke("SetToday", uid, 5) == true, "step 6: SetToday(5) failed")
	tick(200)
	assert(npops() == 1, "step 6.1: at today 5 a Tick sent " .. npops() .. " pops, want 1")
	tick(200)
	assert(npops() == 1, "step 6.2: a second pop was sent with 5 opened and 1 waiting (DailyMax " .. P.DailyMax .. ")")
	assert(ph:Invoke("Age", uid, P.ExpireSeconds + 1) == 1 and npops() == 0, "step 6.3: Age(" .. (P.ExpireSeconds + 1) .. ") did not expire the waiting pop")
	tick(200)
	local bl = pops()
	assert(#bl == 1, "step 6.4: after the expiry the slot was not given back (" .. #bl .. " pops)")
	assert(ph:Invoke("Open", uid, bl[1].token) == true, "step 6.5: Open failed")
	if bl[1].kind == "dm" then assert(ph:Invoke("Choose", uid, bl[1].token, 0).ok == true, "step 6.5: dismiss failed") end
	assert(state().today == 6, "step 6.5: today should be 6 after the open, got " .. tostring(state().today))
	assert(p:GetAttribute("PhoneBusy") == nil, "step 6.5: PhoneBusy still set")
	tick(200)
	assert(npops() == 0, "step 6.6: a pop was sent at today " .. P.DailyMax)
	table.insert(out, "6 day cap: today 5 -> one pop; waiting holds the slot; expired gives it back; opened -> today 6 -> none")

	-- 7 midnight: a pop sent on one UTC day opens on the next; the rollover at open counts it on the new day
	fresh("step 7")
	assert(ph:Invoke("SetToday", uid, 3) == true, "step 7: SetToday(3) failed")
	local day0 = state().day
	local t7 = ph:Invoke("Pop", uid)
	assert(type(t7) == "string", "step 7: Pop sent nothing")
	local yesterday = tonumber(os.date("!%Y%m%d", os.time() - 86400))
	assert(ph:Invoke("SetDay", uid, yesterday) == true, "step 7: SetDay failed")
	assert(ph:Invoke("Open", uid, t7) == true, "step 7: Open failed")
	local s7 = state()
	assert(s7.today == 1 and s7.day == day0, string.format("step 7: want today 1 on day %s after the open, got today %s day %s",
		tostring(day0), tostring(s7.today), tostring(s7.day)))
	table.insert(out, "7 midnight: today 3 yesterday, a pop opened today -> today 1, day " .. tostring(day0))

	-- 8 an opened DM blocks the phone and the walk-in scheduler; the dismiss frees both (control)
	fresh("step 8")
	local t8 = ph:Invoke("Pop", uid, "scam_curator")
	assert(type(t8) == "string", "step 8: Pop(scam_curator) sent nothing")
	assert(ph:Invoke("Open", uid, t8) == true, "step 8: Open failed")
	assert(p:GetAttribute("PhoneBusy") == true and ph:Invoke("Busy", uid) == true, "step 8: the opened DM did not set PhoneBusy")
	assert(wi:Invoke("Poke", uid) == false, "step 8: a walk-in was scheduled behind an open DM")
	tick(200)
	assert(npops() == 1, "step 8: a pop was sent behind an open DM")
	assert(ph:Invoke("Choose", uid, t8, 0).ok == true, "step 8: the dismiss failed")
	assert(p:GetAttribute("PhoneBusy") == nil and npops() == 0, "step 8: the dismiss did not clear PhoneBusy / the DM")
	tick(200)
	assert(npops() == 1, "step 8 control: after the dismiss a Tick sent " .. npops() .. " pops, want 1")
	assert(wi:Invoke("Poke", uid) == true, "step 8 control: Poke did not schedule a walk-in after the dismiss")
	table.insert(out, "8 open DM: PhoneBusy, Poke false, Tick -> none; dismissed: Tick -> one pop, Poke true")

	-- 9 the first pop comes inside FirstDelay (design 6: 90-150 s)
	fresh("step 9")
	local lo, hi = P.FirstDelay[1], P.FirstDelay[2]
	tick(lo - 1)
	assert(npops() == 0, "step 9: a pop came " .. (lo - 1) .. " s in (FirstDelay " .. lo .. ".." .. hi .. ")")
	tick(hi - lo + 1)
	assert(npops() == 1, "step 9: no pop by " .. hi .. " s")
	table.insert(out, string.format("9 first pop: Tick(%d) -> none, Tick(%d) -> one pop", lo - 1, hi - lo + 1))

	-- 10 a cypher lobby blocks; idle again lets the pop through (control)
	fresh("step 10")
	assert(phase() == "idle", "step 10: the cypher is not idle before the case")
	local j = cy:Invoke("Join", -4302, "Phone Test")
	assert(j and j.ok and phase() ~= "idle", "step 10: the fake producer did not open a lobby")
	tick(200)
	assert(npops() == 0, "step 10: a pop was sent during a cypher lobby")
	for _ = 1, 25 do
		if phase() == "idle" then break end
		cy:Invoke("Skip")
		task.wait(0.4)
	end
	assert(phase() == "idle", "step 10: the cypher did not get back to idle")
	tick(200)
	assert(npops() == 1, "step 10 control: no pop once the cypher was idle")
	table.insert(out, "10 cypher: lobby -> Tick(200) none; idle -> one pop")

	return "T51 PLAY OK\n" .. table.concat(out, "\n")
end

local ok, msg = pcall(run)
pcall(function()
	wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); ph:Invoke("Quiet", uid, false)
	wi:Invoke("Pause", uid, true)
	for _ = 1, 25 do if phase() == "idle" then break end; cy:Invoke("Skip"); task.wait(0.4) end
end)
pcall(teleport, LOUNGE)
if not ok then error(msg, 0) end
return msg
