-- Server, during play (the Day One plan, Task 4: Day One on screen), stage for t123d. Through the Studio hooks, held
-- (WalkInsPaused true). First the DayOne Reset (ruling B1: t123a's chain, whose card 1 t123b looked around on, would
-- come back), then the file's fresh(): unseated in the lounge, Quiet on, the phone, WalkIns, Career and Life reset, no
-- hint seen, the rooms hook's Reset (a slot claimed, the plot rebuilt), the DayOne Reset, ResetTour and ResetSessions.
-- t123a's ProfileMark and tour note stand: t123e puts the profile and the tour back.
-- Then WakeUp, and the player at the bedroom's stand spot (room-local (2, 0, -3), t106a's), where the DAW's StationOf
-- names the bedroom's laptop (the beat maker closes past DAWConfig.CloseDistance, 14 studs). There:
-- (1) the rooms hook's RunStation (InteractionService._RunHandler "Station" on the bedroom's laptop) acts: the beat
--     maker opens at the bedroom laptop, and the tour's open step is got (DAW.Opened; polled, a frame late);
-- (2) the steps take and deliver advanced (TourAdvance; no chain runs, so Day One does nothing), and a beat recorded
--     (RecordDelivery: DAWConfig.DefaultPattern at 140 BPM, 2 stars), so Contracts.Recent[1] is card 2's beat;
-- (3) the DayOne hook's Show("speakers"): card 2 sent now (staged), with now = true (shown over the beat maker), its
--     line and two choices; the hook's Open names it, the chain's beat is the recorded one, DayOneBusy true, Next
--     "speakers". It is left open over the open beat maker for t123d.
-- On any error: unseated in the lounge (the beat maker closes there), then the DayOne Reset; the error is rethrown.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local d1 = SOK:WaitForChild("_StudioDayOneHook", 5); assert(d1, "no _StudioDayOneHook (is Systems/DayOne synced and started?)")
local rooms = SOK:WaitForChild("_StudioRoomsHook", 5); assert(rooms, "no _StudioRoomsHook (is Systems/Rooms synced and started?)")
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local D = require(RS.OK.Data.DayOne)
local DAWCfg = require(RS.OK.Modules.DAWConfig)
local LOUNGE = Vector3.new(24, 3, 0)
local BPM = 140
local T0 = os.clock()
local out = {}

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function root() local c = p.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = p.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function name(inst) return typeof(inst) == "Instance" and inst:GetFullName() or tostring(inst) end
local function teleport(pos) -- checked, and tried once more if the client's position won
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
local function unseat()
	local h = hum()
	if h and (h.Sit or h.SeatPart) then h.Sit = false; task.wait(0.4) end
end
local function call(cmd, a, b, c) return d1:Invoke(cmd, uid, a, b, c) end
local function tourNow()
	local pr = test:Invoke("GetProfile", uid)
	local t = type(pr) == "table" and type(pr.tour) == "table" and pr.tour or {}
	return { done = t.done == true, got = type(t.got) == "table" and t.got or {} }
end
local function gotList(t)
	local ids = {}
	for _, id in ipairs({ "open", "take", "deliver", "monitors", "gear" }) do if t.got[id] then table.insert(ids, id) end end
	return (#ids > 0 and table.concat(ids, ",") or "none") .. (t.done and " (done)" or "")
end
local function placeNow()
	local pl = rooms:Invoke("PlaceOf", uid)
	return type(pl) == "table" and (tostring(pl.slot) .. "/" .. tostring(pl.kind)) or tostring(pl)
end
local function kinds(list)
	local t = {}
	for _, e in ipairs(list) do table.insert(t, tostring(e.kind) .. (e.id and (":" .. tostring(e.id)) or "")) end
	return #t > 0 and table.concat(t, ", ") or "nothing"
end

local function fresh()
	unseat()
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, "fresh: Quiet(true) failed")
	assert(ph:Invoke("Reset", uid) == true, "fresh: phone Reset failed")
	assert(wi:Invoke("Reset", uid) == true, "fresh: WalkIns Reset failed")
	assert(career:Invoke("Reset", uid) == true, "fresh: Career Reset failed")
	assert(life:Invoke("Reset", uid) == true, "fresh: Life Reset failed")
	assert(test:Invoke("ResetHints", uid) == true, "fresh: ResetHints failed")
	assert(rooms:Invoke("Reset", uid) == true, "fresh: the rooms hook's Reset failed (no slot, or the plot did not build)")
	assert(call("Reset") == true, "fresh: the DayOne hook's Reset answered something else than true")
	assert(test:Invoke("ResetTour", uid) == true, "fresh: ResetTour failed")
	assert(test:Invoke("ResetSessions", uid) == true, "fresh: ResetSessions failed")
end

local function run()
	-- t123a's chain first (B1): its card 1 would come back LookAround after t123b's Look around
	assert(call("Reset") == true, "the DayOne hook's Reset answered something else than true")
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh()
	local info = rooms:Invoke("Plot", uid)
	local k = type(info) == "table" and info.slot
	assert(k, "the rooms hook's Plot answered " .. tostring(info) .. ", want the player's slot")
	unseat()
	assert(rooms:Invoke("WakeUp", uid) == true, "WakeUp returned false")
	task.wait(0.3) -- the resets' late handlers (Tour.Changed "reset": no chain) run
	local want = k .. "/bedroom"
	waitFor(function() return placeNow() == want end, 3)
	assert(placeNow() == want, "after WakeUp PlaceOf is " .. placeNow() .. ", want " .. want)
	-- the stand spot, in reach of the laptop
	local plots = workspace:FindFirstChild("OK_Plots")
	local bed = plots and plots:FindFirstChild(string.format("Plot_%02d", k)) and plots[string.format("Plot_%02d", k)]:FindFirstChild("Room_bedroom")
	assert(bed, string.format("Workspace.OK_Plots.Plot_%02d has no Room_bedroom", k))
	teleport((bed:GetPivot() * CFrame.new(2, 0, -3)).Position + Vector3.new(0, 3, 0))
	local so = rooms:Invoke("StationOf", uid)
	assert(type(so) == "table" and so.room == bed, "at the stand spot StationOf names " .. name(so and so.inst) .. " / " .. name(so and so.room)
		.. ", want the bedroom's laptop / the bedroom")
	local s0 = call("State")
	assert(type(s0) == "table" and not s0.running and s0.card == nil, "after the DayOne Reset a chain runs (card " .. tostring(type(s0) == "table" and s0.card and s0.card.id) .. "), want none")
	call("Sent") -- drained
	table.insert(out, string.format("DayOne Reset (t123a's chain gone); fresh; at Plot_%02d's bedroom laptop", k))

	-- 1. the beat maker at the bedroom laptop
	local res = rooms:Invoke("RunStation", uid)
	assert(type(res) == "table" and res.acted == true, "RunStation (_RunHandler Station) did not act: " .. tostring(type(res) == "table" and res.acted) .. " / "
		.. tostring(type(res) == "table" and res.toast))
	assert(waitFor(function() return tourNow().got.open == true end, 2), "the tour's open step isn't got 2 s after RunStation (" .. gotList(tourNow()) .. ")")
	-- 2. take and deliver, and a beat recorded
	for _, id in ipairs({ "take", "deliver" }) do assert(test:Invoke("TourAdvance", uid, id) == true, "TourAdvance(" .. id .. ") failed") end
	local pattern = DAWCfg.DefaultPattern
	assert(test:Invoke("RecordDelivery", uid, pattern, BPM, 2) == true, "RecordDelivery failed")
	task.wait(0.3) -- Tour.Changed's handlers run (no chain: nothing)
	local t = tourNow()
	assert(t.got.open and t.got.take and t.got.deliver and not t.got.monitors and not t.done, "the tour is " .. gotList(t) .. ", want open,take,deliver")
	local s1 = call("State")
	assert(type(s1) == "table" and s1.next == "speakers" and not s1.running, "before Show: Next is " .. tostring(type(s1) == "table" and s1.next)
		.. ", running " .. tostring(type(s1) == "table" and s1.running) .. "; want speakers and no chain")
	table.insert(out, "1-2 RunStation opened the beat maker (open got); take and deliver advanced; a beat recorded (" .. BPM .. " BPM)")

	-- 3. card 2, staged over the open beat maker
	assert(call("Show", "speakers") == "speakers", "Show(speakers) didn't answer speakers")
	local open = call("Open")
	assert(type(open) == "table" and open.id == "speakers", "the hook's Open answers " .. tostring(type(open) == "table" and open.id or open) .. " after Show, want speakers")
	local l = call("Sent")
	local arr
	for _, e in ipairs(type(l) == "table" and l or {}) do if e.kind == "arrive" and e.id == "speakers" then arr = e end end
	assert(arr and type(arr.payload) == "table" and type(arr.payload.card) == "table", "Show sent " .. kinds(type(l) == "table" and l or {}) .. ", want arrive:speakers")
	local pl = arr.payload
	assert(pl.now == true and pl.source == "dayone" and pl.card.id == "day1_speakers", "card 2's payload has now " .. tostring(pl.now) .. ", source "
		.. tostring(pl.source) .. ", id " .. tostring(pl.card.id) .. "; want true, dayone, day1_speakers")
	assert(pl.card.line == D.Cards.speakers.line and type(pl.card.choices) == "table" and #pl.card.choices == 2, "card 2 reads '" .. tostring(pl.card.line)
		.. "' with " .. tostring(type(pl.card.choices) == "table" and #pl.card.choices) .. " choices, want '" .. D.Cards.speakers.line .. "' and 2")
	assert(type(pl.card.visitor) == "table" and pl.card.visitor.id == nil, "card 2's visitor has id " .. tostring(type(pl.card.visitor) == "table" and pl.card.visitor.id) .. ", want none (no face)")
	local s2 = call("State")
	assert(type(s2) == "table" and s2.beat and s2.beat.pattern == pattern and s2.beat.bpm == BPM, "the chain's beat is " .. tostring(type(s2) == "table" and s2.beat
		and (tostring(s2.beat.bpm) .. " BPM") or "none") .. ", want the recorded one at " .. BPM)
	assert(waitFor(function() return p:GetAttribute("DayOneBusy") == true end, 2), "DayOneBusy is " .. tostring(p:GetAttribute("DayOneBusy")) .. " with card 2 open, want true")
	table.insert(out, "3 Show(speakers): card 2 (now = true, 2 choices, no face) open over the beat maker, the chain's beat the recorded one; left for t123d")
	return table.concat(out, "\n")
end

local ok, msg = pcall(run)
if not ok then
	pcall(unseat)
	pcall(teleport, LOUNGE) -- the beat maker closes out here
	pcall(function() rooms:Invoke("InPlot", uid) end)
	pcall(function() d1:Invoke("Reset", uid) end) -- the last step (ruling F6)
	error(msg, 0)
end
return string.format("T123C PLAY OK (%.1f s)\n", os.clock() - T0) .. msg
