-- Server, during play (the Your Rooms plan, Task 5; Review Focus 1): walk-ins count down and walk in to your rooms, through
-- the Studio hooks (_StudioWalkInHook, _StudioRoomsHook). The body runs held (WalkInsPaused true, except one unpaused
-- countdown in (4)) and starts from the file's fresh(): unseated in the lounge, Quiet on, the phone, WalkIns, Career and
-- Life reset, no hint seen, the rooms hook's Reset (a slot claimed, the plot rebuilt), and the tour done (so a Poke after
-- the first counted visit isn't held by it). Distances are flat (x, z) unless they say y.
-- (1) WakeUp: the player in their bedroom (PlaceOf 1/bedroom). The room's Entrance, VisitorSpot and CritterSpot through
--     the hook's Anchor (the imported bedroom's Bedroom_Setup.Sockets, or the stand-in's).
-- (2) SetRemaining(0) and Poke in the bedroom: a visit starts there (presence counts in your own room). The visitor's first
--     pose (read as the Poke returns) is within 1 stud of the Entrance; he arrives within 15 s within 1 stud of the
--     VisitorSpot, facing the player (preflight F4: on a route he arrives only at its end, never by distance from the
--     player, who stands ~3.7 studs from the Entrance); the "arrive" payload with his token is sent.
-- (3) Exit("bedroom") (the real door handler) puts the player on the landing: the visit ends (Pending nil) and a "leave"
--     with the token is sent; he walks back out and is gone. On the landing (not a room for presence) DueWithin is false
--     with the timer at 0, a Poke starts nothing, and with Aura -20 on a clean heal gate the loop's heal step
--     (HealSteps(10): HEAL_SECONDS of them and more, past the hold, each with the real presence check) pays nothing.
-- (4) GoIn("bedroom"), WalkIns Reset; unpaused (the hold stays) with SetRemaining(2): the live 1 s loop counts down in the
--     bedroom and starts a visit within 5 s (loop -> tick -> schedule: nothing else pokes in that window).
-- (5) The pigeon card (Spawn weird_pigeon): the figure stands within 1 stud of the CritterSpot, feet within 0.3 studs of its
--     height, holds a walking slot and its card arrives within 2 s; Expire sends "leave", it flies off, the slot comes back.
-- (6) The heal in the bedroom, through the loop's own presence-gated heal step: still Aura -20 and no AuraHeal award yet,
--     HealSteps(10) pays Config.Career.Sources.AuraHeal's max (5), Aura -15 (the same steps paid nothing on the landing).
-- (7) Release mid-walk (Review Focus 1): WalkIns Reset; the hall streamed in first (RequestStreamAroundAsync on its
--     HallSpawn), so Release's own move of the owner doesn't wait on streaming and lands well inside his ~0.86 s walk;
--     Spawn navx_placement (a card, no news on arrival): not arrived, his figure on the Entrance -> VisitorSpot segment
--     and more than 1 stud short of the VisitorSpot; Release (preflight F5: the owner goes to HallSpawn and the plot
--     goes): the visit ends (Pending nil); the Sent log, read once, holds a "leave" and no "arrive" for his token (an
--     arrive means the owner moved too late: the walk wasn't cut mid-route); he is gone; money and every career stat are
--     as they were. Claim and WakeUp give the bedroom back.
-- (8) Another player's plot: in your own bedroom, SetRemaining(0) and DueWithin(60, ignorePause) is true (the control);
--     Fill(1) builds slot 2 for a fake owner, Enter(2, as a friend) and GoIn("bedroom") put the player in that plot's
--     bedroom (PlaceOf 2/bedroom): DueWithin is false and a Poke starts nothing (only your own rooms count); after a
--     Career Reset (a clean heal gate, checked) and Aura -20, HealSteps(10) pays nothing there.
-- On any error, and after success: unseated in the lounge, Unfill, the rooms Reset, the hold back to true, WalkIns, phone,
-- Career and Life reset, ResetHints, the tour done, Quiet off; then the test hook's ProfileRestore (its ProfileMark is
-- run()'s first step: money, XP and level, gear, the gate logs, the tour, the hints, the sessions) and the career hook's
-- Publish; then the error is rethrown. (D1-T7 final fix: fresh()'s tour done pays the real tour XP, +50, and t106a's
-- cleanup finished the tour again, +50 more: 100 XP, level 2 before t15, so t16 found level 3 after it. Now nothing is
-- left behind.)
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
local Config = require(RS.OK.Config)
local Tour = require(RS.OK.Systems.Tour)
local W = Config.WalkIns
local HEAL_MAX = Config.Career.Sources.AuraHeal.aura.max
local STATS = { "money", "aura", "followers", "placements", "hits", "sponsors" }
local LOUNGE = Vector3.new(24, 3, 0)
local RED = " (before the R-T5 sync of Systems/WalkIns and Modules/Visitor: the expected red)"
local HEAL_RED = " (before the R-T5 fix1 sync of Systems/WalkIns: no HealSteps hook, the expected red)"
local HEAL_STEPS = 10 -- the loop's heal pays on its HEAL_SECONDS-th (5th) present step; 10 leaves room
local out = {}
local T0 = os.clock()

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function root() local c = p.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = p.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function str(v) return typeof(v) == "Vector3" and string.format("(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z) or tostring(v) end
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
local function pending() return wi:Invoke("Pending", uid) end
local function placeNow()
	local pl = call("PlaceOf")
	return type(pl) == "table" and (tostring(pl.slot) .. "/" .. tostring(pl.kind)) or tostring(pl)
end
-- waits up to 3 s (a move settles) for PlaceOf to read `want` ("<slot>/<kind>", "hub" or "nil")
local function placeIs(want, label)
	waitFor(function() return placeNow() == want end, 3)
	local got = placeNow()
	assert(got == want, label .. ": PlaceOf is " .. got .. ", want " .. want)
end
local function anchor(name)
	local cf = call("Anchor", "bedroom", name)
	assert(typeof(cf) == "CFrame", "the bedroom has no " .. name .. " anchor (the hook's Anchor answered " .. tostring(cf) .. ")")
	return cf.Position
end
-- the player's one visitor figure under Workspace.OK_Visitors (`id`: its VisitorId), or nil
local function figure(id)
	local f = workspace:FindFirstChild("OK_Visitors")
	for _, m in ipairs(f and f:GetChildren() or {}) do
		if m:GetAttribute("Target") == uid and (id == nil or m:GetAttribute("VisitorId") == id) then return m end
	end
	return nil
end
local function sent(kind, token) -- the WalkIn sends of that kind (and token) since the hook's last Sent; drains the log
	local found
	for _, s in ipairs(wi:Invoke("Sent", uid) or {}) do
		if s.kind == kind and type(s.payload) == "table" and (token == nil or s.payload.token == token) then found = s.payload end
	end
	return found
end
-- every WalkIn send for `token` since the hook's last Sent, by kind ({ [kind] = payload }); drains the log, so read once
local function sentFor(token)
	local by = {}
	for _, s in ipairs(wi:Invoke("Sent", uid) or {}) do
		if type(s.payload) == "table" and s.payload.token == token then by[s.kind] = s.payload end
	end
	return by
end
local function advanceTour() for _, s in ipairs(Tour.Steps) do test:Invoke("TourAdvance", uid, s.id) end end
local function aura() return career:Invoke("Get", uid).aura end
local function setAura(n, label) assert(career:Invoke("Set", uid, { aura = n }) == true, label .. ": Set aura " .. n .. " failed") end
-- the reward gate's AuraHeal awards today (DataService's careerLog, as t61a reads it): 0 = a heal can still pay
local function healAwards()
	local log = test:Invoke("GetProfile", uid).career.careerLog
	return log and log.count and log.count["AuraHeal.aura"] or 0
end
-- the loop's presence-gated heal step, HEAL_STEPS times past the hold on a fresh session heal clock (the hook's
-- HealSteps), at Aura -20 on a clean gate (both checked first); returns what it paid and the Aura after
local function healHere(label)
	setAura(-20, label)
	assert(healAwards() == 0, label .. ": the AuraHeal gate already holds an award today, want none (so only presence can stop the heal)")
	local paid = wi:Invoke("HealSteps", uid, HEAL_STEPS)
	assert(type(paid) == "number", label .. ": the hook's HealSteps returned " .. tostring(paid) .. ", want a number" .. HEAL_RED)
	return paid, aura()
end
local function stats()
	local have = career:Invoke("Get", uid)
	local t = {}
	for _, k in ipairs(STATS) do t[k] = have[k] end
	t.sponsor = tostring(have.sponsor)
	return t
end
-- the file's own fresh(): unseated in the lounge, Quiet on, the phone, WalkIns, Career and Life reset, no hint seen, the
-- rooms hook's Reset (slot claimed, plot rebuilt), the tour done
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
	advanceTour()
end

local function run()
	local mk = test:Invoke("ProfileMark", uid) -- first, before anything changes (the cleanup's ProfileRestore)
	assert(mk == true, "the test hook's ProfileMark answered " .. tostring(mk) .. ", want true (sync ServerScriptService/OK/Main: D1-T3 fix 1)")
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh("rooms walk-ins")

	-- 1. into the bedroom; its anchors
	assert(call("WakeUp") == true, "WakeUp returned false")
	placeIs("1/bedroom", "WakeUp")
	local ENT, SPOT, CRIT = anchor("Entrance"), anchor("VisitorSpot"), anchor("CritterSpot")
	local r0 = root()
	table.insert(out, string.format("1 WakeUp: 1/bedroom at %s; Entrance %s, VisitorSpot %s (%.1f apart), CritterSpot %s; the player %.1f from the Entrance",
		str(r0.Position), str(ENT), str(SPOT), flat(SPOT - ENT), str(CRIT), flat(r0.Position - ENT)))

	-- 2. the timer at 0 and a Poke in the bedroom: he walks in from the Entrance to the VisitorSpot
	assert(figure() == nil and pending() == nil, "Poke: a visit or a visitor is left over from fresh()")
	local walking = wi:Invoke("Walking")
	assert(walking < W.MaxWalking, "Poke: " .. tostring(walking) .. " visitors already walking (MaxWalking " .. W.MaxWalking .. "): his walk would wait")
	wi:Invoke("Sent", uid) -- drained
	assert(wi:Invoke("SetRemaining", uid, 0) == true, "SetRemaining(0) failed")
	local poked = wi:Invoke("Poke", uid)
	local m = figure()
	local first = m and m:GetPivot().Position -- his first pose, read before anything waits
	assert(poked == true, "Poke in your bedroom returned " .. tostring(poked) .. ", want true (presence counts in your own room)" .. RED)
	local r = pending()
	assert(r and r.arrived == false, "Poke: want a visit in flight, not yet arrived; got " .. (r and ("arrived " .. tostring(r.arrived)) or "none"))
	assert(m, "Poke: no visitor figure for the player under Workspace.OK_Visitors")
	assert(flat(first - ENT) <= 1, string.format("first pose: want within 1 stud of the Entrance %s, got %s (%.2f away)", str(ENT), str(first), flat(first - ENT)))
	local t0 = os.clock()
	assert(waitFor(function() local q = pending(); return q ~= nil and q.arrived == true end, 15), "the visitor did not arrive within 15 s in the bedroom")
	local took = os.clock() - t0
	local cf = m:GetPivot()
	assert(flat(cf.Position - SPOT) <= 1, string.format("arrival: want within 1 stud of the VisitorSpot %s, got %s (%.2f away; %.2f from the Entrance)",
		str(SPOT), str(cf.Position), flat(cf.Position - SPOT), flat(cf.Position - ENT)))
	local to = root().Position - cf.Position
	local face = (cf.LookVector.X * to.X + cf.LookVector.Z * to.Z) / (flat(cf.LookVector) * flat(to))
	assert(face > 0.9, string.format("arrival: want him facing the player (> 0.9), got %.2f", face))
	local arrive = sent("arrive", r.token)
	assert(arrive and type(arrive.card) == "table" and arrive.card.id == r.id, "arrival: no 'arrive' payload with his token (card " .. tostring(r.id) .. ") was sent")
	table.insert(out, string.format("2 Poke in the bedroom: %s, first pose %.2f from the Entrance; arrived in %.1f s, %.2f from the VisitorSpot, facing %.2f; arrive sent",
		r.id, flat(first - ENT), took, flat(cf.Position - SPOT), face))

	-- 3. out to the landing: the visit ends, a leave is sent, he walks out; the landing doesn't count
	assert(call("Exit", "bedroom") == true, "Exit(bedroom) returned false")
	placeIs("1/landing", "Exit(bedroom)")
	assert(waitFor(function() return pending() == nil end, 4), "landing: the visit did not end within 4 s of the player stepping out to the landing" .. RED)
	assert(sent("leave", r.token), "landing: no 'leave' with his token was sent")
	assert(waitFor(function() return m.Parent == nil end, 5), "landing: the visitor is still there 5 s after the visit ended")
	assert(wi:Invoke("SetRemaining", uid, 0) == true, "landing: SetRemaining(0) failed")
	local due = wi:Invoke("DueWithin", uid, 60, true)
	assert(due == false, "landing: DueWithin(60) with the timer at 0 is " .. tostring(due) .. ", want false (the landing is not a room)"
		.. (due == nil and " (nil: the hook has no DueWithin, before the R-T5 sync of Systems/WalkIns)" or ""))
	assert(wi:Invoke("Poke", uid) == false and pending() == nil, "landing: a Poke started a visit on the landing")
	local lpaid, laura = healHere("landing heal")
	assert(lpaid == 0 and laura == -20, string.format("landing heal: the loop's heal step paid %d (Aura %d), want 0 and Aura -20 (the landing is not a room)", lpaid, laura))
	table.insert(out, "3 Exit -> landing: visit ended, leave sent, visitor gone; on the landing DueWithin false, Poke false, the heal step pays 0 at Aura -20")

	-- 4. the live loop counts down in the bedroom
	assert(call("GoIn", "bedroom") == true, "GoIn(bedroom) returned false")
	placeIs("1/bedroom", "GoIn(bedroom)")
	assert(wi:Invoke("Reset", uid) == true, "countdown: WalkIns Reset failed")
	assert(wi:Invoke("SetRemaining", uid, 2) == true and wi:Invoke("Pause", uid, false) == true, "countdown: could not set the timer / unpause")
	t0 = os.clock()
	local looped = waitFor(function() return pending() ~= nil end, 5)
	took = os.clock() - t0
	wi:Invoke("SetRemaining", uid, 1e6)
	wi:Invoke("Pause", uid, true)
	assert(looped, "countdown: unpaused in your bedroom with 2 s left, the live loop started no visit within 5 s" .. RED)
	assert(wi:Invoke("Reset", uid) == true, "countdown: WalkIns Reset failed")
	assert(waitFor(function() return figure() == nil end, 2), "countdown: a visitor is left after Reset")
	table.insert(out, string.format("4 the live loop in the bedroom (unpaused, held): a visit %.1f s after SetRemaining(2)", took))

	-- 5. the pigeon sits at the CritterSpot
	local walking0 = wi:Invoke("Walking")
	wi:Invoke("Sent", uid) -- drained
	assert(wi:Invoke("Spawn", uid, "weird_pigeon") == true, "pigeon: Spawn(weird_pigeon) refused in the bedroom")
	assert(waitFor(function() local q = pending(); return q ~= nil and q.arrived == true end, 2), "pigeon: its card did not arrive within 2 s")
	local pr = pending()
	local pg = figure("pigeon")
	assert(pg, "pigeon: no pigeon figure under Workspace.OK_Visitors")
	local at = pg:GetPivot().Position
	local lo = math.huge
	for _, d in ipairs(pg:GetDescendants()) do if d:IsA("BasePart") then lo = math.min(lo, d.Position.Y - d.Size.Y / 2) end end
	assert(flat(at - CRIT) <= 1, string.format("pigeon: want within 1 stud of the CritterSpot %s, got %s (%.2f away)", str(CRIT), str(at), flat(at - CRIT)))
	assert(math.abs(lo - CRIT.Y) <= 0.3, string.format("pigeon: want its feet at the CritterSpot's y %.2f, got %.2f", CRIT.Y, lo))
	assert(wi:Invoke("Walking") == walking0 + 1, "pigeon: it does not hold a walking slot (Walking " .. tostring(wi:Invoke("Walking")) .. ", was " .. walking0 .. ")")
	local parrive = sent("arrive", pr.token)
	assert(parrive and parrive.card.id == "weird_pigeon", "pigeon: no 'arrive' for weird_pigeon was sent")
	assert(wi:Invoke("Expire", uid) == true, "pigeon: Expire refused")
	assert(sent("leave", pr.token), "pigeon: no 'leave' after Expire")
	assert(waitFor(function() return pg.Parent == nil end, 3), "pigeon: still there 3 s after the visit ended (it flies off in 1 s)")
	assert(waitFor(function() return wi:Invoke("Walking") == walking0 end, 1), "pigeon: the walking slot was not given back")
	table.insert(out, string.format("5 pigeon: %.2f from the CritterSpot, feet at y %.2f (spot %.2f), a walking slot held; card arrived; Expire -> leave, flown off, slot back",
		flat(at - CRIT), lo, CRIT.Y))

	-- 6. the heal pays in the bedroom
	placeIs("1/bedroom", "heal")
	local paid, haura = healHere("heal in the bedroom")
	assert(paid == HEAL_MAX and haura == -20 + HEAL_MAX, string.format("heal in the bedroom: the loop's heal step paid %d (Aura %d), want %d and Aura %d (presence counts in your own room)",
		paid, haura, HEAL_MAX, -20 + HEAL_MAX))
	table.insert(out, string.format("6 heal in the bedroom (the loop's presence-gated step, %d steps): Aura -20 -> %d (+%d)", HEAL_STEPS, haura, paid))

	-- 7. the owner's plot goes mid-walk (Review Focus 1): the visit ends with no stat change
	assert(wi:Invoke("Reset", uid) == true, "release: WalkIns Reset failed")
	-- the hall streamed in first: Release's own move (RequestStreamAroundAsync, then PivotTo) then needn't wait on it
	local rmodel = workspace:FindFirstChild("OK_Rooms")
	local hallM = rmodel and rmodel:FindFirstChild("Hall")
	local hs = hallM and hallM:FindFirstChild("HallSpawn")
	assert(hs, "release: no Workspace.OK_Rooms.Hall.HallSpawn")
	local streamed = pcall(function() p:RequestStreamAroundAsync(hs.Position, 10) end)
	wi:Invoke("Sent", uid) -- drained
	local before = stats()
	assert(wi:Invoke("Spawn", uid, "navx_placement") == true, "release: Spawn(navx_placement) refused in the bedroom")
	local rr = pending()
	local vm = figure()
	assert(rr and rr.arrived == false and vm, "release: want navx_placement walking in, not arrived; got " .. (rr and ("arrived " .. tostring(rr.arrived)) or "no visit"))
	local at7 = vm:GetPivot().Position
	local seg = flat(SPOT - ENT)
	local off = flat(at7 - ENT) + flat(at7 - SPOT) - seg
	assert(off <= 0.5 and flat(at7 - SPOT) > 1, string.format("release: want his figure on the Entrance -> VisitorSpot segment and more than 1 stud short of the VisitorSpot, got %s (%.2f from it, %.2f off the segment)",
		str(at7), flat(at7 - SPOT), off))
	local t7 = os.clock()
	assert(call("Release") == true, "release: Release returned false")
	local took7 = os.clock() - t7
	assert(waitFor(function() return pending() == nil end, 3), "release: the visit did not end within 3 s of the plot going")
	local by = sentFor(rr.token) -- read once: every send for his token since the drain
	assert(by.arrive == nil, string.format("release: an 'arrive' went out for his token, want none: he reached the VisitorSpot before Release moved the owner (Release took %.2f s, the walk is %.2f s; hall pre-streamed: %s), so the walk wasn't cut mid-route",
		took7, seg / W.WalkSpeed, tostring(streamed)))
	assert(by.leave, "release: no 'leave' with his token was sent")
	assert(waitFor(function() return vm.Parent == nil end, 5), "release: the visitor is still there 5 s after the plot went")
	local after = stats()
	for _, k in ipairs(STATS) do
		assert(after[k] == before[k], string.format("release: %s moved from %s to %s (want no stat change)", k, tostring(before[k]), tostring(after[k])))
	end
	assert(after.sponsor == before.sponsor, "release: the sponsor moved from " .. before.sponsor .. " to " .. after.sponsor)
	assert(call("Plot") == nil, "release: the player still has a plot")
	assert(call("Claim") == 1, "release: Claim did not give slot 1 back")
	assert(call("WakeUp") == true, "release: WakeUp after Claim returned false")
	placeIs("1/bedroom", "release: WakeUp after Claim")
	table.insert(out, string.format("7 Release mid-walk (hall pre-streamed: %s): %.2f short of the VisitorSpot at the call, Release took %.2f s (walk %.2f s); leave sent, no arrive, visitor gone, money and stats unchanged; Claim + WakeUp -> 1/bedroom",
		tostring(streamed), flat(at7 - SPOT), took7, seg / W.WalkSpeed))

	-- 8. only your own rooms count: the control in yours, then another player's bedroom
	assert(wi:Invoke("Reset", uid) == true, "other plot: WalkIns Reset failed")
	assert(wi:Invoke("SetRemaining", uid, 0) == true, "other plot: SetRemaining(0) failed")
	due = wi:Invoke("DueWithin", uid, 60, true)
	assert(due == true, "your bedroom (the control): DueWithin(60) with the timer at 0 is " .. tostring(due) .. ", want true" .. RED)
	assert(call("Fill", 1) == 1, "other plot: Fill(1) did not build a plot for a fake owner")
	assert(call("Enter", 2, true) == true, "other plot: Enter(2, as a friend) returned false")
	assert(call("GoIn", "bedroom") == true, "other plot: GoIn(bedroom) in plot 2 returned false")
	placeIs("2/bedroom", "other plot")
	due = wi:Invoke("DueWithin", uid, 60, true)
	assert(due == false, "another player's bedroom: DueWithin(60) with the timer at 0 is " .. tostring(due) .. ", want false (only your own rooms count)")
	assert(wi:Invoke("Poke", uid) == false and pending() == nil, "another player's bedroom: a Poke started a visit")
	assert(wi:Invoke("GetRemaining", uid) == 0, "another player's bedroom: the refused Poke did not keep the timer at 0")
	assert(career:Invoke("Reset", uid) == true, "another player's bedroom: Career Reset (a clean heal gate) failed")
	local opaid, oaura = healHere("another player's bedroom heal")
	assert(opaid == 0 and oaura == -20, string.format("another player's bedroom: the loop's heal step paid %d (Aura %d), want 0 and Aura -20 (only your own rooms count)", opaid, oaura))
	table.insert(out, "8 own bedroom: DueWithin true; slot 2's bedroom (a fake owner's): DueWithin false, Poke false, the heal step pays 0 at Aura -20 on a clean gate")

	return "T104A PLAY OK\n" .. table.concat(out, "\n") .. string.format("\nelapsed %.1f s", os.clock() - T0)
end

local ok, msg = pcall(run)
pcall(unseat)
pcall(teleport, LOUNGE) -- first, so no release or rebuild below happens under the player
pcall(function() rooms:Invoke("Unfill", uid) end)
pcall(function() rooms:Invoke("Reset", uid) end)
pcall(function()
	wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
	test:Invoke("ResetHints", uid); advanceTour(); ph:Invoke("Quiet", uid, false)
end)
-- the profile as ProfileMark noted it (the tour's XP from fresh() and the cleanup's advanceTour taken back)
local restored
pcall(function() restored = test:Invoke("ProfileRestore", uid) end)
pcall(function() career:Invoke("Publish", uid) end) -- Career_Get's cached Money dropped, the career attributes sent again
if not ok then error(msg, 0) end
assert(restored == true, "cleanup: the test hook's ProfileRestore answered " .. tostring(restored) .. ", want true")
return msg
