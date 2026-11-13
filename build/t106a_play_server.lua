-- Server, during play (the Your Rooms plan, Task 7: your room's speakers), through the Studio hooks. The body runs held
-- (WalkInsPaused true) from the file's fresh(): unseated in the lounge, Quiet on, the phone, WalkIns, Career and Life
-- reset, no hint seen, the rooms hook's Reset (a slot claimed, the plot rebuilt). The rooms hook's Play(pattern, bpm) and
-- Stop run DAW_Broadcast's and DAW_Stop's own handlers for the player (DAW._Broadcast, DAW._Stop: the remote's path, its
-- room branch and its BroadcastTried rule); Counts reads how many times Rooms.Played and DAW.BroadcastTried fired for the
-- player since the last read (read until the expected totals arrive, at most 2 s, then once more after 0.3 s: deferred
-- signals can run a handler a frame late). "The stand spot" is room-local (2, 0, -3), in reach of the bedroom's laptop.
-- First the player's gear and tour are noted (speaker gear dropped if a failed run left some), the tour is reset and
-- the monitors are free (nothing on air or in line; at most 25 s).
-- (1) In the bedroom with no speaker gear, Play(DefaultPattern, 120) at the stand spot answers ok, room, tier 1,
--     position 0; RoomPlaying.Plot_<k> is Active with Tier 1, Room "bedroom", the player's OwnerId and OwnerName, the
--     beat, 120 BPM, swing 0, the studio kit, the first voice, StartAt ~0.5 s ahead, Loops and EndsAt from
--     MonitorService.LoopsFor; Played fired once and BroadcastTried never; the tour's "monitors" step is done; NowPlaying's
--     Token, Active and QueueCount are as they were; a FIRE for the play's Token is refused "noair" (the rooms hook's
--     Fire: the live Reactions.Send, which reads only NowPlaying); no speaker models stand in the bedroom.
-- (2) At once, a second play answers "cooldown" (room) and changes nothing; Config.Rooms.PlayCooldown later (preflight
--     m14) it replaces the first: a new Token, Played once more.
-- (3) It ends itself: past the first play's EndsAt the second is still on (the first's end only ends its own Token),
--     and at its own EndsAt it ends (Active false, same Token).
-- (4) Stop (DAW_Stop's handler) clears a third play at once.
-- (5) GrantGear("spk_monitors"): RoomSpeaker_L and _R (RoomItems.Speakers, tier 2) stand on the bedroom's
--     Desk_Speaker_L / _R anchors (pivot within 0.05 studs, facing the anchor's way): plain anchored Parts that never
--     collide, touch or answer a raycast, no MeshPart, no light (the bedroom keeps at most 1); the hook's SpeakerTier
--     answers 2 and the next play is Tier 2. GrantGear("spk_studio"): the same two models, now tier 3 (still exactly
--     two), and the next play is Tier 3.
-- (6) At the studio PC (StationOf: the PC's screen, no room) a play goes on the monitors as before: ok, no room flag,
--     position 0; NowPlaying airs it (the player's OwnerId, the beat); BroadcastTried fired once and Played never; the
--     room's folder is untouched. Stop takes it off the air.
-- On any error, and after success: any play of the player's stopped, unseated in the lounge, the gear put back as it
-- was (ResetGear, then GrantGear the noted ids), the rooms Reset, everything else reset, the tour's noted steps done
-- again (a finished tour finished again, as t104a's cleanup), hold on, Quiet off, then the test hook's ProfileRestore
-- (its ProfileMark is run()'s first step: money, XP and level, gear, the gate logs, the tour, the hints, the sessions; the
-- D1-T7 final fix: finishing the noted tour again paid the real tour XP, +50, which with t104a's put t16 a level ahead)
-- and the career hook's Publish; the error is rethrown.
-- Tail for t106b and t106c, after the cleanup and only on success: the noted gear ids in the player attribute _T106Gear
-- (t106c puts them back), WakeUp (the player in their bedroom), and GrantGear("spk_monitors"), so t106b finds tier 2
-- speakers in the bedroom (awaited here, at most 5 s).
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local rooms = SOK:WaitForChild("_StudioRoomsHook", 5); assert(rooms, "no _StudioRoomsHook (is Systems/Rooms synced and started?)")
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local mon = SOK:WaitForChild("_StudioMonitorHook", 5); assert(mon, "no _StudioMonitorHook (is Main running in Studio?)")
local Config = require(RS.OK.Config)
local DAWCfg = require(RS.OK.Modules.DAWConfig)
local Mon = require(SSS.OK.Services.MonitorService) -- LoopsFor only (pure)
local Tour = require(RS.OK.Systems.Tour) -- its Steps only
local NP = RS.OK.NowPlaying
local LOUNGE = Vector3.new(24, 3, 0)
local PC_SPOT = Vector3.new(72.0, 3.5, -5.5) -- in front of the studio PC (t17b, t21d, t105a)
local PAT = DAWCfg.DefaultPattern -- a reference beat: never a "copy" of anyone's airing
local BPM = 120
local COOLDOWN = Config.Rooms.PlayCooldown
local RED = " (before the R-T7 sync of Systems/Rooms, Systems/DAW and the rest: the expected red)"
local out = {}
local T0 = os.clock()
local gearBefore, tourBefore -- noted first thing in run(); the cleanup puts them back

local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function root() local c = p.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = p.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function name(inst) return typeof(inst) == "Instance" and inst:GetFullName() or tostring(inst) end
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function teleport(pos) -- the test's own move; checked, and tried once more if the client's position won
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
local function call(cmd, a, b) return rooms:Invoke(cmd, uid, a, b) end
local function plotModel(k) local f = workspace:FindFirstChild("OK_Plots"); return f and f:FindFirstChild(string.format("Plot_%02d", k)) end
local function says(r)
	if type(r) ~= "table" then return tostring(r) end
	return string.format("ok %s, room %s, tier %s, position %s, reason %s", tostring(r.ok), tostring(r.room), tostring(r.tier), tostring(r.position), tostring(r.reason))
end
-- the hook's Counts: Played and BroadcastTried fires for the player since the last read
local function counts(label)
	local c = call("Counts")
	assert(type(c) == "table", label .. ": the rooms hook's Counts answered " .. tostring(c) .. ", want { played, tried }" .. RED)
	return c.played, c.tried
end
-- the Counts summed until they reach the expected totals (under deferred signals an event's handlers can run a frame
-- after the call that fired it), then one more read after a short settle, so a late extra fire counts too
local function countsAre(label, wantPlayed, wantTried)
	local played, tried = 0, 0
	waitFor(function()
		local p1, t1 = counts(label)
		played += p1; tried += t1
		return played >= wantPlayed and tried >= wantTried
	end, 2)
	task.wait(0.3)
	local p2, t2 = counts(label)
	return played + p2, tried + t2
end
local function ownedGear()
	local prof = test:Invoke("GetProfile", uid)
	local ids = {}
	local g = type(prof) == "table" and type(prof.gear) == "table" and prof.gear or {}
	for id, on in pairs(g) do if on == true then table.insert(ids, id) end end
	table.sort(ids)
	return ids
end
local function setGear(ids)
	assert(test:Invoke("ResetGear", uid) == true, "ResetGear failed")
	if #ids > 0 then assert(test:Invoke("GrantGear", uid, table.concat(ids, ",")) == true, "GrantGear(" .. table.concat(ids, ",") .. ") failed") end
end
local function tourNow()
	local prof = test:Invoke("GetProfile", uid)
	local t = type(prof) == "table" and type(prof.tour) == "table" and prof.tour or {}
	return { done = t.done == true, got = type(t.got) == "table" and t.got or {} }
end
-- the tour as it was noted: its steps done again (a finished tour finished again, as t104a's cleanup does)
local function restoreTour(before)
	for _, s in ipairs(Tour.Steps) do
		if before.done or before.got[s.id] then test:Invoke("TourAdvance", uid, s.id) end
	end
end
local function npSnap() return { token = NP:GetAttribute("Token"), active = NP:GetAttribute("Active") == true, queue = NP:GetAttribute("QueueCount") or 0 } end
local function free() return NP:GetAttribute("Active") ~= true and (NP:GetAttribute("QueueCount") or 0) == 0 and NP:GetAttribute("Reserved") ~= true end
-- the bedroom's speaker models: RoomSpeaker_L, RoomSpeaker_R and how many children carry either name
local function speakers(bed)
	local n = 0
	for _, c in ipairs(bed:GetChildren()) do if c.Name == "RoomSpeaker_L" or c.Name == "RoomSpeaker_R" then n += 1 end end
	return bed:FindFirstChild("RoomSpeaker_L"), bed:FindFirstChild("RoomSpeaker_R"), n
end
local function lights(inst) local n = 0; for _, d in ipairs(inst:GetDescendants()) do if d:IsA("Light") then n += 1 end end; return n end
-- RoomSpeaker_L / _R at `tier` on their anchors (waited for: the Gear attribute's change refits them)
local function checkSpeakers(bed, tier, label)
	local got = waitFor(function()
		local L, R, n = speakers(bed)
		return L ~= nil and R ~= nil and n == 2 and L:GetAttribute("Tier") == tier and R:GetAttribute("Tier") == tier
	end, 5)
	local L, R, n = speakers(bed)
	assert(got, string.format("%s: the bedroom holds %d speaker models (RoomSpeaker_L tier %s, _R tier %s), want exactly RoomSpeaker_L and _R at tier %d",
		label, n, tostring(L and L:GetAttribute("Tier")), tostring(R and R:GetAttribute("Tier")), tier) .. RED)
	for side, m in pairs({ L = L, R = R }) do
		local what = label .. ": RoomSpeaker_" .. side
		assert(m:IsA("Model") and m:GetAttribute("RoomItem") == "speaker", what .. " is a " .. m.ClassName .. " with RoomItem " .. tostring(m:GetAttribute("RoomItem")) .. ", want a Model, speaker")
		local cab = m.PrimaryPart
		assert(cab and cab.Name == "Cabinet" and cab:IsA("BasePart"), what .. "'s PrimaryPart is " .. name(cab) .. ", want its Cabinet part")
		local a = bed:FindFirstChild("Desk_Speaker_" .. side, true)
		assert(a and a:IsA("Attachment"), "the bedroom has no Desk_Speaker_" .. side .. " Attachment")
		local pv = m:GetPivot()
		local d = (pv.Position - a.WorldPosition).Magnitude
		assert(d <= 0.05, string.format("%s stands %.3f studs off Desk_Speaker_%s, want on it (0.05)", what, d, side))
		local dot = pv.LookVector:Dot(a.WorldCFrame.LookVector)
		assert(dot >= 0.99, string.format("%s faces %s, Desk_Speaker_%s faces %s (dot %.3f), want the same way", what, tostring(pv.LookVector), side, tostring(a.WorldCFrame.LookVector), dot))
		for _, x in ipairs(m:GetDescendants()) do
			assert(not x:IsA("Light"), what .. " holds a light: " .. x:GetFullName())
			assert(not x:IsA("MeshPart"), what .. " holds a MeshPart: " .. x:GetFullName())
			if x:IsA("BasePart") then
				assert(x.Anchored and not x.CanCollide and not x.CanTouch and not x.CanQuery, x:GetFullName() .. ": Anchored " .. tostring(x.Anchored)
					.. ", CanCollide " .. tostring(x.CanCollide) .. ", CanTouch " .. tostring(x.CanTouch) .. ", CanQuery " .. tostring(x.CanQuery) .. "; want anchored and none of the rest")
			end
		end
	end
	assert(lights(bed) <= 1, "the bedroom holds " .. lights(bed) .. " lights with its speakers, want 1 at most")
	return L, R
end
-- a room play's answer and its folder
local function checkPlay(f, res, tier, label, tokBefore)
	assert(type(res) == "table", label .. ": the rooms hook's Play answered " .. tostring(res) .. ", want DAW._Broadcast's table" .. RED)
	assert(res.ok == true and res.room == true and res.tier == tier and res.position == 0, label .. ": Play answered " .. says(res)
		.. "; want ok true, room true, tier " .. tier .. ", position 0" .. RED)
	local tok = f:GetAttribute("Token")
	assert(f:GetAttribute("Active") == true and type(tok) == "number" and tok > tokBefore, label .. ": " .. f:GetFullName() .. " Active " .. tostring(f:GetAttribute("Active"))
		.. ", Token " .. tostring(tok) .. " (was " .. tostring(tokBefore) .. "); want Active and a new Token")
	assert(f:GetAttribute("Tier") == tier and f:GetAttribute("Room") == "bedroom" and f:GetAttribute("OwnerId") == uid, label .. ": the folder reads Tier "
		.. tostring(f:GetAttribute("Tier")) .. ", Room " .. tostring(f:GetAttribute("Room")) .. ", OwnerId " .. tostring(f:GetAttribute("OwnerId"))
		.. "; want " .. tier .. ", bedroom, " .. uid)
	return tok
end
-- the file's own fresh(): unseated in the lounge, Quiet on, the phone, WalkIns, Career and Life reset, no hint seen,
-- the rooms hook's Reset (slot claimed, plot rebuilt)
local function fresh(label)
	unseat()
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, label .. ": Quiet(true) failed")
	assert(ph:Invoke("Reset", uid) == true, label .. ": phone Reset failed")
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	assert(life:Invoke("Reset", uid) == true, label .. ": Life Reset failed")
	assert(test:Invoke("ResetHints", uid) == true, label .. ": ResetHints failed")
	assert(call("Reset") == true, label .. ": the rooms hook's Reset failed (no slot, or the plot did not build)")
end

local function run()
	local mk = test:Invoke("ProfileMark", uid) -- first, before anything changes (the cleanup's ProfileRestore)
	assert(mk == true, "the test hook's ProfileMark answered " .. tostring(mk) .. ", want true (sync ServerScriptService/OK/Main: D1-T3 fix 1)")
	gearBefore, tourBefore = ownedGear(), tourNow()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh("speakers")
	local kept = {}
	for _, id in ipairs(gearBefore) do if id:sub(1, 4) ~= "spk_" then table.insert(kept, id) end end
	if #kept ~= #gearBefore then setGear(kept) end -- a failed run left speaker gear: tier 1 first
	assert(test:Invoke("ResetTour", uid) == true, "ResetTour failed")
	assert(waitFor(free, 25), "the monitors are not free after 25 s (Active " .. tostring(NP:GetAttribute("Active")) .. ", QueueCount "
		.. tostring(NP:GetAttribute("QueueCount")) .. ", Reserved " .. tostring(NP:GetAttribute("Reserved")) .. ")")
	countsAre("start", 0, 0) -- drained

	-- 1. tier 1: the laptop's own speakers
	assert(call("WakeUp") == true, "WakeUp returned false")
	local info = call("Plot")
	local k = type(info) == "table" and info.slot
	assert(k, "the hook's Plot answered " .. tostring(info) .. ", want the player's slot")
	local bed = plotModel(k) and plotModel(k):FindFirstChild("Room_bedroom")
	assert(bed, string.format("Workspace.OK_Plots.Plot_%02d has no Room_bedroom", k))
	local f = RS.OK:FindFirstChild("RoomPlaying") and RS.OK.RoomPlaying:FindFirstChild(string.format("Plot_%02d", k))
	assert(f, string.format("ReplicatedStorage.OK.RoomPlaying.Plot_%02d missing (build/19_rooms.lua)", k))
	local st = call("Station")
	assert(typeof(st) == "Instance" and st:IsDescendantOf(bed), "the hook's Station is " .. name(st) .. ", want the bedroom's laptop")
	teleport((bed:GetPivot() * CFrame.new(2, 0, -3)).Position + Vector3.new(0, 3, 0))
	local so = call("StationOf")
	assert(type(so) == "table" and so.inst == st and so.room == bed, "at the stand spot StationOf is " .. name(so and so.inst) .. " / " .. name(so and so.room)
		.. ", want the bedroom's laptop / the bedroom")
	local L0, R0, n0 = speakers(bed)
	assert(n0 == 0 and L0 == nil and R0 == nil, "with no speaker gear the bedroom holds " .. n0 .. " speaker models, want none")
	local np0 = npSnap()
	local tok0 = f:GetAttribute("Token") or 0
	local loops, dur = Mon.LoopsFor(BPM, DAWCfg.Steps, Config.Monitors)
	local tPlay1 = os.clock()
	local res1 = call("Play", PAT, BPM)
	local now = workspace:GetServerTimeNow()
	local cd = call("Play", PAT, BPM) -- at once, well inside the cooldown (checked in 2)
	local tok1 = checkPlay(f, res1, 1, "1 tier 1", tok0)
	local startAt, endsAt = f:GetAttribute("StartAt"), f:GetAttribute("EndsAt")
	assert(f:GetAttribute("Beat") == PAT and f:GetAttribute("BPM") == BPM and f:GetAttribute("Swing") == 0 and f:GetAttribute("Kit") == "studio"
		and f:GetAttribute("Voice") == DAWCfg.Voices[1].id and f:GetAttribute("OwnerName") == p.DisplayName,
		string.format("1: the folder's play reads BPM %s, Swing %s, Kit %s, Voice %s, OwnerName %s, the beat %s; want %d, 0, studio, %s, %s, the default beat",
			tostring(f:GetAttribute("BPM")), tostring(f:GetAttribute("Swing")), tostring(f:GetAttribute("Kit")), tostring(f:GetAttribute("Voice")),
			tostring(f:GetAttribute("OwnerName")), f:GetAttribute("Beat") == PAT and "the same" or "different", BPM, DAWCfg.Voices[1].id, p.DisplayName))
	assert(f:GetAttribute("Loops") == loops and type(startAt) == "number" and type(endsAt) == "number" and math.abs(endsAt - startAt - dur) < 1e-3,
		string.format("1: Loops %s, EndsAt - StartAt %s; want MonitorService.LoopsFor's %d bars, %.2f s", tostring(f:GetAttribute("Loops")),
			tostring(type(endsAt) == "number" and type(startAt) == "number" and (endsAt - startAt) or nil), loops, dur))
	assert(startAt - now >= 0.2 and startAt - now <= 0.6, string.format("1: StartAt is %.2f s from now, want about 0.5 ahead", startAt - now))
	local played, tried = countsAre("1", 1, 0)
	assert(played == 1 and tried == 0, string.format("1: a play and a refused one fired Played %d times and BroadcastTried %d, want 1 and 0", played, tried))
	assert(waitFor(function() return tourNow().got.monitors == true end, 2), "1: the tour's monitors step is not done after a room play (Systems/Tour: Rooms.Played)")
	local np1 = npSnap()
	assert(np1.token == np0.token and np1.active == np0.active and np1.queue == np0.queue, string.format("1: NowPlaying moved: Token %s -> %s, Active %s -> %s, QueueCount %s -> %s",
		tostring(np0.token), tostring(np1.token), tostring(np0.active), tostring(np1.active), tostring(np0.queue), tostring(np1.queue)))
	local fire = call("Fire", tok1)
	assert(type(fire) == "table" and fire.ok == false and fire.reason == "noair", "1: a FIRE for the room play's Token answered " .. says(fire) .. ", want refused: noair (nothing airs)")
	table.insert(out, string.format("1 Plot_%02d tier 1: Token %d, Room bedroom, %d bars %.1f s, StartAt +%.2f s; Played 1, BroadcastTried 0; tour monitors done; NowPlaying untouched; FIRE noair; no speaker models",
		k, tok1, loops, dur, startAt - now))

	-- 2. the cooldown (the play made at once in 1), then a play replaces the one under way
	assert(type(cd) == "table" and cd.ok == false and cd.room == true and cd.reason == "cooldown", "2: a play at once answered " .. says(cd) .. ", want cooldown (room)")
	assert(f:GetAttribute("Token") == tok1, "2: a refused play moved the Token to " .. tostring(f:GetAttribute("Token")))
	local left = COOLDOWN + 0.1 - (os.clock() - tPlay1)
	if left > 0 then task.wait(left) end
	local tok2 = checkPlay(f, call("Play", PAT, BPM), 1, "2 replace", tok1)
	local ends2 = f:GetAttribute("EndsAt")
	played, tried = countsAre("2", 1, 0)
	assert(played == 1 and tried == 0, string.format("2: Played fired %d times and BroadcastTried %d, want 1 and 0", played, tried))
	table.insert(out, string.format("2 at once: cooldown, nothing moved; %.1f s later Token %d replaces %d", COOLDOWN + 0.1, tok2, tok1))

	-- 3. it ends itself, and only its own Token
	assert(waitFor(function() return workspace:GetServerTimeNow() >= endsAt + 0.4 end, dur + 3), "3: the server clock did not pass the first play's EndsAt")
	assert(f:GetAttribute("Active") == true and f:GetAttribute("Token") == tok2, "3: past the first play's EndsAt the folder reads Active "
		.. tostring(f:GetAttribute("Active")) .. ", Token " .. tostring(f:GetAttribute("Token")) .. "; want the second play still on (" .. tok2 .. ")")
	local endedAt
	assert(waitFor(function()
		if f:GetAttribute("Active") ~= true then endedAt = endedAt or workspace:GetServerTimeNow(); return true end
		return false
	end, ends2 - workspace:GetServerTimeNow() + 3), "3: the second play did not end by its EndsAt + 3 s")
	assert(f:GetAttribute("Token") == tok2 and endedAt >= ends2 - 0.05, string.format("3: it ended %.2f s before its EndsAt (Token %s, want %d)",
		ends2 - endedAt, tostring(f:GetAttribute("Token")), tok2))
	table.insert(out, string.format("3 past the first play's end the second plays on; it ends itself %.2f s after its EndsAt", endedAt - ends2))

	-- 4. Stop clears a play
	local tPlay3 = os.clock()
	local tok3 = checkPlay(f, call("Play", PAT, BPM), 1, "4 play", tok2)
	assert(call("Stop") == true, "4: the rooms hook's Stop failed" .. RED)
	assert(waitFor(function() return f:GetAttribute("Active") ~= true end, 2), "4: Stop left the play on")
	assert(f:GetAttribute("Token") == tok3, "4: Stop moved the Token to " .. tostring(f:GetAttribute("Token")))
	played, tried = countsAre("4", 1, 0) -- the third play's, drained
	assert(played == 1 and tried == 0, string.format("4: a play and its Stop fired Played %d times and BroadcastTried %d, want 1 and 0", played, tried))
	table.insert(out, string.format("4 Stop (DAW_Stop's handler) ended Token %d at once", tok3))

	-- 5. speaker gear: tier 2, then tier 3
	assert(test:Invoke("GrantGear", uid, "spk_monitors") == true, "5: GrantGear(spk_monitors) failed")
	local L2 = checkSpeakers(bed, 2, "5 spk_monitors")
	assert(call("SpeakerTier") == 2, "5: the hook's SpeakerTier answered " .. tostring(call("SpeakerTier")) .. " with spk_monitors, want 2")
	local wait4 = COOLDOWN + 0.1 - (os.clock() - tPlay3)
	if wait4 > 0 then task.wait(wait4) end
	local tPlay4 = os.clock()
	local tok4 = checkPlay(f, call("Play", PAT, BPM), 2, "5 tier 2", tok3)
	assert(call("Stop") == true and waitFor(function() return f:GetAttribute("Active") ~= true end, 2), "5: Stop left the tier 2 play on")
	assert(test:Invoke("GrantGear", uid, "spk_studio") == true, "5: GrantGear(spk_studio) failed")
	local L3 = checkSpeakers(bed, 3, "5 spk_studio")
	assert(L3 ~= L2, "5: the tier 3 RoomSpeaker_L is the tier 2 model, want a new one")
	assert(call("SpeakerTier") == 3, "5: the hook's SpeakerTier answered " .. tostring(call("SpeakerTier")) .. " with spk_studio, want 3")
	local wait5 = COOLDOWN + 0.1 - (os.clock() - tPlay4)
	if wait5 > 0 then task.wait(wait5) end
	local tok5 = checkPlay(f, call("Play", PAT, BPM), 3, "5 tier 3", tok4)
	assert(call("Stop") == true and waitFor(function() return f:GetAttribute("Active") ~= true end, 2), "5: Stop left the tier 3 play on")
	played, tried = countsAre("5", 2, 0)
	assert(played == 2 and tried == 0, string.format("5: two room plays fired Played %d times and BroadcastTried %d, want 2 and 0", played, tried))
	local np5 = npSnap()
	assert(np5.token == np0.token and np5.active == np0.active, "5: room plays moved NowPlaying's Token " .. tostring(np0.token) .. " -> " .. tostring(np5.token))
	table.insert(out, string.format("5 spk_monitors: 2 tier 2 models on Desk_Speaker_L/R (plain parts, no light), play Tier 2 (Token %d); spk_studio: 2 tier 3 models, play Tier 3 (Token %d); NowPlaying untouched",
		tok4, tok5))

	-- 6. the studio PC: on the monitors, as before
	teleport(PC_SPOT)
	local pc = call("StationOf")
	local screen = workspace.OKStudio.ControlRoom:FindFirstChild("Screen_Main")
	assert(type(pc) == "table" and pc.inst == screen and pc.room == nil, "6: at the studio PC StationOf is " .. name(pc and pc.inst) .. " / " .. name(pc and pc.room)
		.. ", want the PC's screen and no room")
	mon:Invoke("ClearFlipCheck", uid)
	assert(waitFor(free, 25), "6: the monitors are not free after 25 s")
	countsAre("6 start", 0, 0) -- drained
	local hub = call("Play", PAT, BPM)
	assert(type(hub) == "table" and hub.ok == true and hub.room == nil and hub.position == 0, "6: a play at the studio PC answered " .. says(hub)
		.. ", want ok true, no room flag, position 0 (on the monitors)")
	assert(NP:GetAttribute("Active") == true and NP:GetAttribute("OwnerId") == uid and NP:GetAttribute("Beat") == PAT, "6: NowPlaying reads Active "
		.. tostring(NP:GetAttribute("Active")) .. ", OwnerId " .. tostring(NP:GetAttribute("OwnerId")) .. "; want the player's beat on air")
	played, tried = countsAre("6", 0, 1)
	assert(played == 0 and tried == 1, string.format("6: the monitors play fired Played %d times and BroadcastTried %d, want 0 and 1", played, tried))
	assert(f:GetAttribute("Active") ~= true and f:GetAttribute("Token") == tok5, "6: the monitors play touched the room's folder (Active "
		.. tostring(f:GetAttribute("Active")) .. ", Token " .. tostring(f:GetAttribute("Token")) .. ")")
	assert(call("Stop") == true and waitFor(function() return NP:GetAttribute("Active") ~= true end, 3), "6: Stop left the player's beat on the monitors")
	table.insert(out, "6 at the studio PC: on the monitors (position 0, NowPlaying airs it), BroadcastTried 1, Played 0, the room's folder untouched; Stop took it off")

	return "T106A PLAY OK\n" .. table.concat(out, "\n") .. string.format("\nelapsed %.1f s", os.clock() - T0)
end

local ok, msg = pcall(run)
pcall(function() rooms:Invoke("Stop", uid) end) -- any play of the player's, in a room or on the monitors
pcall(unseat)
pcall(teleport, LOUNGE) -- first, so the rebuild below never happens under the player
pcall(function() if gearBefore then setGear(gearBefore) end end)
pcall(function() rooms:Invoke("Reset", uid) end)
pcall(function()
	wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
	test:Invoke("ResetHints", uid)
	if tourBefore then restoreTour(tourBefore) end
	ph:Invoke("Quiet", uid, false)
end)
-- the profile as ProfileMark noted it (finishing the noted tour again paid its XP: taken back here)
local restored
pcall(function() restored = test:Invoke("ProfileRestore", uid) end)
pcall(function() career:Invoke("Publish", uid) end) -- Career_Get's cached Money dropped, the career attributes sent again
if not ok then error(msg, 0) end
assert(restored == true, "cleanup: the test hook's ProfileRestore answered " .. tostring(restored) .. ", want true")
-- tail for t106b and t106c, after the cleanup: the noted gear for t106c, the player in their bedroom with tier 2 speakers
p:SetAttribute("_T106Gear", table.concat(gearBefore, ","))
assert(rooms:Invoke("WakeUp", uid) == true, "tail: WakeUp returned false")
assert(test:Invoke("GrantGear", uid, "spk_monitors") == true, "tail: GrantGear(spk_monitors) failed")
local info = rooms:Invoke("Plot", uid)
local k = type(info) == "table" and info.slot
assert(k and waitFor(function()
	local bed = plotModel(k) and plotModel(k):FindFirstChild("Room_bedroom")
	local L = bed and bed:FindFirstChild("RoomSpeaker_L")
	return L ~= nil and L:GetAttribute("Tier") == 2
end, 5), "tail: the bedroom has no tier 2 speakers 5 s after GrantGear(spk_monitors)")
return msg
