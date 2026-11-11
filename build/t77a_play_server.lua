-- Server, during play (Wave 3 Task 3; design 4.1; Review Focus 1 and 2), before t77b: your beat feeds the cards. The
-- file's own fresh() (unseated in the lounge, Quiet on, WalkIns Reset, Career Reset, Life Reset with the career day set
-- to 5, _StudioTestHook ResetHints, and SetRecent({}): no recent beat). The body runs held (WalkInsPaused true) and
-- drives visits through the hooks. Every chance is computed here from the live rules (WalkInRules.Chance and BeatTilt on
-- Config.WalkIns.Odds) and the career Career Get returns, never typed in, so a retune of beatCenter or beatPer can't
-- break it.
-- (1) No beat: Recent is empty and BestBeat nil; navx_placement's arrive payload has beat = false (never nil, never a
--     raw token) and its line reads "something" (WalkInRules.Fill with no bpm). Its choice 1 (a beat choice) is forced
--     to roll U = the untilted chance (Chance with tilt 0), which is above the no-beat chance (tilt BeatTilt(0) < 0): it
--     lands bad, so the no-beat penalty is applied (a server that skipped it would land good, as (2) shows a roll equal
--     to the chance does).
-- (2) RecordDelivery(P1, 142, 3) then CreditFire(P1, 142) three times: Recent is one entry { P1, 142, stars 3, fires 3,
--     day 5 } and BestBeat has BeatQuality 4. navx_placement's payload has beat = { stars 3, fires 3, bpm 142 } and no
--     pattern, and its line reads "the one at 142". Choice 1 forced to roll R = the chance with the quality-4 tilt lands
--     good.
-- (2b) An unflagged choice stays untilted: the same quality-4 beat, choice 3 (no `beat`) forced to roll its untilted
--     chance + 1, which is at or under its chance if the tilt were wrongly applied: it lands bad.
-- (3) The same roll without the tilt: SetRecent to one 3-star beat with no FIRE (quality 3, BeatTilt(3)); R is above
--     that chance, so choice 1 lands bad: R succeeds only with the tilt.
-- (4) The beat on a waiting card is fresh (fix round 1): navx_placement arrives with no beat (payload beat false), the
--     card is deferred (the hook's SetDeferred, the WalkIn_Deferred path), a 3-star beat is recorded, and the card is
--     un-deferred: the walk-in hook's Sent holds a "beat" update for its token with { stars 3, fires 0, bpm 142 } and the
--     line "the one at 142", and choice 1 forced to roll U (the quality-3 chance, untilted) lands good: the roll uses the
--     refreshed snapshot (the stale one, no beat, would land bad).
-- (5) A beat aired without a delivery: the monitors air one of the player's own beats (never delivered) and a pretend
--     listener gives it FIRE (the monitor hook's FireAs, Reactions.Give, as t22c does): it joins Recent at stars 0,
--     fires 1, with the airing's bpm (Contracts.CreditFire from Reactions.Give).
-- (6) A 4th pattern drops the oldest: P1..P4 delivered leave P4, P3, P2; P3 again at 2 stars moves to the front and
--     keeps its 3 stars (the merge keeps the higher).
-- Staging for t77b (inside the same pcall): fresh() again, every hint unseen, navx_placement spawned with no beat and
-- deferred; then P1 at 3 stars with 3 FIRE and the card un-deferred, so its last "beat" update carries { 3, 3, 142 } and
-- the line "the one at 142". It is left open: t77b checks the client rebuilt the footer and his line from that update,
-- with the Aura line and the hint placement. On any error everything is reset (hold true, WalkIns, Career, Life, hints
-- and recent beats, Quiet off, the player's airing cancelled) and the error rethrown.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local mon = SOK:WaitForChild("_StudioMonitorHook", 5); assert(mon, "no _StudioMonitorHook")
local Config = require(RS.OK.Config)
local Rules = require(RS.OK.Modules.WalkInRules)
local Content = require(RS.OK.Data.WalkIns)
local NP = RS.OK.NowPlaying
local W = Config.WalkIns
local LOUNGE = Vector3.new(24, 3, 0)
local CARD = "navx_placement"
local CHOICE = Content.CardById[CARD].choices[1] -- the beat choice (walkins_data_spec pins it)
local DAY = 5 -- the career day the body runs on (Life SetDay): a recent beat is stamped with it
-- P1..P4 are only stored (RecordDelivery / CreditFire never send a pattern anywhere): 128 characters, one per letter.
-- AIR really airs on the monitors, so every client near the speakers plays it: it is the default beat, which t22c airs
-- cleanly (fresh() empties the list first, so t22c's FIRE on it doesn't carry over)
local function pat(ch) return string.rep("0", 120) .. string.rep(ch, 8) end
local P1, P2, P3, P4 = pat("1"), pat("2"), pat("3"), pat("4")
local AIR = require(RS.OK.Modules.DAWConfig).DefaultPattern
local out = {}
local T0 = os.clock()

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
local function pending() return wi:Invoke("Pending", uid) end
local function arrived() local r = pending(); return r ~= nil and r.arrived == true end
local function recent()
	local r = test:Invoke("Recent", uid)
	assert(type(r) == "table", "Recent(uid) returned " .. typeof(r) .. " (before the Task 3 sync of OK/Main it returns nil: the expected red)")
	return r
end
local function show(list)
	local parts = {}
	for _, e in ipairs(list) do
		table.insert(parts, string.format("%s %s* %sf bpm %s d%s", string.sub(tostring(e.pattern), -1), tostring(e.stars), tostring(e.fires),
			tostring(e.bpm), tostring(e.day)))
	end
	return "{" .. table.concat(parts, "; ") .. "}"
end
local function setRecent(list, label)
	local kept = test:Invoke("SetRecent", uid, list)
	assert(type(kept) == "table", label .. ": SetRecent returned " .. typeof(kept) .. " (before the Task 3 sync of OK/Main it returns nil: the expected red)")
	return kept
end
local function deliver(pattern, bpm, stars, label)
	assert(test:Invoke("RecordDelivery", uid, pattern, bpm, stars) == true, label .. ": RecordDelivery(" .. string.sub(pattern, -1) .. ", "
		.. bpm .. ", " .. stars .. ") did not return true")
end
local function fire(pattern, bpm, label)
	assert(test:Invoke("CreditFire", uid, pattern, bpm) == true, label .. ": CreditFire(" .. string.sub(pattern, -1) .. ") did not return true")
end
local function showBeat(b)
	if b == false then return "false" end
	if type(b) ~= "table" then return tostring(b) end
	return string.format("{ stars %s, fires %s, bpm %s%s }", tostring(b.stars), tostring(b.fires), tostring(b.bpm), b.pattern and ", pattern!" or "")
end
-- the newest "arrive" payload in the walk-in hook's Sent (the read drains it)
local function lastArrive()
	local got
	for _, e in ipairs(wi:Invoke("Sent", uid)) do if e.kind == "arrive" then got = e.payload end end
	return got
end
-- the newest "beat" update (fix round 1) for `token` in the walk-in hook's Sent (the read drains it)
local function lastBeatUpdate(token)
	local got
	for _, e in ipairs(wi:Invoke("Sent", uid)) do if e.kind == "beat" and type(e.payload) == "table" and e.payload.token == token then got = e.payload end end
	return got
end
-- the file's own fresh(): unseated and in the lounge, Quiet on, WalkIns, Career and Life reset (career day DAY), no
-- hint seen, no recent beat
local function fresh(label)
	local c = p.Character; local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum and hum.Sit then hum.Sit = false; task.wait(0.4) end
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, label .. ": Quiet(true) failed")
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	assert(life:Invoke("Reset", uid) == true, label .. ": Life Reset failed")
	assert(life:Invoke("SetDay", uid, DAY) == true, label .. ": Life SetDay(" .. DAY .. ") failed")
	assert(test:Invoke("ResetHints", uid) == true, label .. ": ResetHints failed")
	local kept = setRecent({}, label)
	assert(#kept == 0, label .. ": SetRecent({}) kept " .. show(kept))
end
-- the forced card walked in; returns the arrived record and its arrive payload's card. Every visit starts with no
-- relationship (Wave 3 Task 5: navx_placement's choices move LIL NAV X's score, which tilts his next roll; this file
-- tests the beat tilt alone). SetRel's return isn't read: before the Task 5 sync the hook has no SetRel (nil, no tilt)
local function spawnArrived(label)
	wi:Invoke("SetRel", uid, {})
	wi:Invoke("Sent", uid) -- drained: the arrive read below is this visit's
	assert(wi:Invoke("Spawn", uid, CARD) == true, label .. ": Spawn(" .. CARD .. ") refused")
	assert(waitFor(arrived, 15), label .. ": he did not arrive within 15 s")
	local a = lastArrive()
	assert(type(a) == "table" and type(a.card) == "table" and a.card.id == CARD, label .. ": no arrive payload for " .. CARD)
	return pending(), a.card
end
-- the beat choice's chance for the career now at beat quality q (WalkInRules.Chance with BeatTilt on live Config)
local function chanceAt(q) return Rules.Chance(CHOICE.odds or 50, career:Invoke("Get", uid), W.Odds, Rules.BeatTilt(q, W.Odds)) end
-- a choice's chance with no beat tilt at all (what a server that skipped the tilt would roll at)
local function untilted(choice) return Rules.Chance(choice.odds or 50, career:Invoke("Get", uid), W.Odds, 0) end
-- choice `index` (default 1) rolled at `roll` on the open card (the forced draw set right before Choose); returns the
-- result's key
local function rollChoice(label, r, roll, index)
	assert(wi:Invoke("SetRng", uid, { roll }) == true, label .. ": SetRng failed")
	local res = wi:Invoke("Choose", uid, r.token, index or 1)
	assert(res and res.ok == true and type(res.result) == "table", label .. ": Choose " .. tostring(index or 1) .. " refused: " .. tostring(res and res.reason))
	return res.result.key
end
local function filled(bpm) return Rules.Fill(Content.CardById[CARD].line, Content.Names(W.Roster), nil, bpm) end

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh("no beat")
	assert(CHOICE.beat == true, CARD .. " choice 1 is not a beat choice (Data/WalkIns: the expected red before the Task 3 sync)")

	-- 1. no beat: payload beat false, "something", and the roll at quality 4's chance lands bad
	assert(#recent() == 0 and test:Invoke("BestBeat", uid) == nil, "no beat: Recent " .. show(recent()) .. " / BestBeat not nil after SetRecent({})")
	local r1, c1 = spawnArrived("no beat")
	assert(c1.beat == false, "no beat: the payload's beat is " .. showBeat(c1.beat) .. ", want false (before the Task 3 sync of Systems/WalkIns: nil)")
	assert(c1.line == filled(nil) and string.find(c1.line, "something", 1, true) and not string.find(c1.line, "{", 1, true),
		"no beat: the line reads '" .. tostring(c1.line) .. "', want '" .. filled(nil) .. "'")
	assert(career:Invoke("Reset", uid) == true, "no beat: Career Reset failed")
	local R = chanceAt(4)
	local noBeat = chanceAt(0)
	assert(R > chanceAt(3) and chanceAt(3) > noBeat, string.format("no beat: the tilt should order the chances: q4 %s > q3 %s > q0 %s (beatCenter %s, beatPer %s)",
		tostring(R), tostring(chanceAt(3)), tostring(noBeat), tostring(W.Odds.beatCenter), tostring(W.Odds.beatPer)))
	local U = untilted(CHOICE)
	assert(U > noBeat, "no beat: the untilted chance " .. tostring(U) .. " is not above the no-beat chance " .. tostring(noBeat))
	local k1 = rollChoice("no beat", r1, U)
	assert(k1 == "passed", string.format("no beat: choice 1 rolled %s (the untilted chance) against %s (no beat) landed %s, want passed (bad): the no-beat penalty was not applied",
		tostring(U), tostring(noBeat), tostring(k1)))
	table.insert(out, string.format("1 no beat: Recent {}, payload beat false, line '%s'; roll %s (untilted) vs chance %s -> %s", c1.line, tostring(U), tostring(noBeat), k1))

	-- 2. a delivered 3-star beat with 3 FIRE: quality 4, the payload's beat, "the one at 142", the roll lands good
	deliver(P1, 142, 3, "beat")
	for _ = 1, 3 do fire(P1, 142, "beat") end
	local list = recent()
	assert(#list == 1 and list[1].pattern == P1 and list[1].bpm == 142 and list[1].stars == 3 and list[1].fires == 3 and list[1].day == DAY,
		"beat: Recent is " .. show(list) .. ", want one entry {1 3* 3f bpm 142 d" .. DAY .. "}")
	local best = test:Invoke("BestBeat", uid)
	assert(type(best) == "table" and best.pattern == P1 and Rules.BeatQuality(best) == 4, "beat: BestBeat " .. showBeat(best) .. " should be P1 at quality 4")
	local r2, c2 = spawnArrived("beat")
	local b2 = c2.beat
	assert(type(b2) == "table" and b2.stars == 3 and b2.fires == 3 and b2.bpm == 142 and b2.pattern == nil,
		"beat: the payload's beat is " .. showBeat(b2) .. ", want { stars 3, fires 3, bpm 142 } with no pattern")
	assert(c2.line == filled(142) and string.find(c2.line, "the one at 142", 1, true), "beat: the line reads '" .. tostring(c2.line) .. "', want '" .. filled(142) .. "'")
	assert(career:Invoke("Reset", uid) == true, "beat: Career Reset failed")
	R = chanceAt(4)
	local k2 = rollChoice("beat", r2, R)
	assert(k2 == "placement", string.format("beat: choice 1 rolled %s at its tilted chance %s landed %s, want placement (good)", tostring(R), tostring(R), tostring(k2)))
	table.insert(out, string.format("2 RecordDelivery(P1, 142, 3) + 3 CreditFire: Recent %s, BestBeat quality 4; payload beat %s, line '%s'; roll %s -> %s",
		show(list), showBeat(b2), c2.line, tostring(R), k2))

	-- 2b. an unflagged choice stays untilted (the same quality-4 beat): choice 3, its untilted chance + 1
	local PLAIN = Content.CardById[CARD].choices[3]
	assert(not PLAIN.beat and not PLAIN.sure and not PLAIN.rare, CARD .. " choice 3 should be a plain rolled choice (no beat, sure or rare)")
	local r2b = spawnArrived("unflagged")
	assert(career:Invoke("Reset", uid) == true, "unflagged: Career Reset failed")
	local plainChance = untilted(PLAIN)
	local wrong = Rules.Chance(PLAIN.odds or 50, career:Invoke("Get", uid), W.Odds, Rules.BeatTilt(4, W.Odds))
	local R2b = plainChance + 1
	assert(R2b <= wrong, string.format("unflagged: the roll %s should sit at or under the wrongly tilted chance %s", tostring(R2b), tostring(wrong)))
	local k2b = rollChoice("unflagged", r2b, R2b, 3)
	assert(k2b == PLAIN.bad.key, string.format("unflagged: choice 3 rolled %s against its chance %s landed %s, want %s (bad): the beat tilt reached a choice without `beat` (tilted it would be %s)",
		tostring(R2b), tostring(plainChance), tostring(k2b), tostring(PLAIN.bad.key), tostring(wrong)))
	table.insert(out, string.format("2b quality 4, choice 3 (no beat): roll %s vs chance %s (tilted would be %s) -> %s", tostring(R2b), tostring(plainChance), tostring(wrong), k2b))

	-- 3. the same roll without the tilt: a 3-star beat with no FIRE, quality 3
	local kept = setRecent({ { pattern = P1, bpm = 142, stars = 3, fires = 0, day = DAY } }, "no tilt")
	assert(#kept == 1 and Rules.BeatQuality(kept[1]) == 3, "no tilt: SetRecent kept " .. show(kept))
	local r3, c3 = spawnArrived("no tilt")
	assert(type(c3.beat) == "table" and c3.beat.stars == 3 and c3.beat.fires == 0, "no tilt: the payload's beat is " .. showBeat(c3.beat))
	assert(career:Invoke("Reset", uid) == true, "no tilt: Career Reset failed")
	local q3 = chanceAt(3)
	assert(R > q3, "no tilt: the roll " .. tostring(R) .. " is not above the quality-3 chance " .. tostring(q3))
	local k3 = rollChoice("no tilt", r3, R)
	assert(k3 == "passed", string.format("no tilt: choice 1 rolled %s against %s (quality 3) landed %s, want passed: %s succeeds only with the tilt", tostring(R), tostring(q3), tostring(k3), tostring(R)))
	table.insert(out, string.format("3 quality 3 (no tilt): roll %s vs chance %s -> %s; only the tilt makes %s good", tostring(R), tostring(q3), k3, tostring(R)))

	-- 4. the beat on a waiting card is fresh: no beat at arrival, deferred, a 3-star beat recorded, un-deferred
	setRecent({}, "waiting")
	local r4, c4 = spawnArrived("waiting")
	assert(c4.beat == false, "waiting: the payload's beat is " .. showBeat(c4.beat) .. ", want false")
	assert(wi:Invoke("SetDeferred", uid, r4.token, true) == true, "waiting: SetDeferred(true) refused")
	deliver(P1, 142, 3, "waiting")
	assert(wi:Invoke("SetDeferred", uid, r4.token, false) == true, "waiting: SetDeferred(false) refused")
	task.wait(0.1)
	local u4 = lastBeatUpdate(r4.token)
	assert(type(u4) == "table", "waiting: no \"beat\" update for the card in the hook's Sent (before the fix-round sync of Systems/WalkIns: none)")
	assert(type(u4.beat) == "table" and u4.beat.stars == 3 and u4.beat.fires == 0 and u4.beat.bpm == 142 and u4.beat.pattern == nil,
		"waiting: the update's beat is " .. showBeat(u4.beat) .. ", want { stars 3, fires 0, bpm 142 }")
	assert(u4.line == filled(142), "waiting: the update's line is '" .. tostring(u4.line) .. "', want '" .. filled(142) .. "'")
	assert(type(u4.choices) == "table" and #u4.choices == #Content.CardById[CARD].choices, "waiting: the update's choice texts are missing")
	assert(career:Invoke("Reset", uid) == true, "waiting: Career Reset failed")
	local fresh3, stale0 = chanceAt(3), chanceAt(0)
	assert(fresh3 > stale0, "waiting: the quality-3 chance " .. tostring(fresh3) .. " is not above the no-beat one " .. tostring(stale0))
	local k4 = rollChoice("waiting", r4, fresh3)
	assert(k4 == "placement", string.format("waiting: choice 1 rolled %s (the refreshed quality-3 chance) landed %s, want placement: the roll used the stale snapshot (chance %s)",
		tostring(fresh3), tostring(k4), tostring(stale0)))
	table.insert(out, string.format("4 no beat at arrival, deferred, 3-star beat recorded, un-deferred: update beat %s, line '%s'; roll %s -> %s",
		showBeat(u4.beat), u4.line, tostring(fresh3), k4))

	-- 5. a beat aired without a delivery, FIRE'd through Reactions.Give: stars 0, fires 1, the airing's bpm
	setRecent({}, "aired")
	mon:Invoke("Cancel", uid)
	assert(waitFor(function() local st = mon:Invoke("State"); return st.current == nil end, 25), "aired: the monitors are still busy after 25 s")
	local q = mon:Invoke("Enqueue", uid, p.DisplayName, AIR, 120)
	assert(q and q.ok, "aired: Enqueue refused: " .. tostring(q and q.reason))
	assert(waitFor(function() return NP:GetAttribute("Active") == true and NP:GetAttribute("OwnerId") == uid and NP:GetAttribute("Beat") == AIR end, 8),
		"aired: the player's beat did not go on air")
	mon:Invoke("FireAs", -7701)
	local airList = recent()
	mon:Invoke("Cancel", uid)
	assert(#airList == 1 and airList[1].pattern == AIR and airList[1].stars == 0 and airList[1].fires == 1 and airList[1].bpm == 120 and airList[1].day == DAY,
		"aired: Recent after one FIRE on an aired beat is " .. show(airList) .. ", want the default beat at 0 stars, 1 FIRE, bpm 120, day " .. DAY .. " (before the Task 3 sync of Systems/Reactions: {})")
	table.insert(out, "5 aired, never delivered, FIRE via the monitor hook: Recent " .. show(airList))

	-- 6. a 4th pattern drops the oldest; the same pattern again merges (stars the higher) and moves to the front
	setRecent({}, "fourth")
	deliver(P1, 142, 3, "fourth"); deliver(P2, 140, 2, "fourth"); deliver(P3, 150, 3, "fourth"); deliver(P4, 160, 2, "fourth")
	local four = recent()
	assert(#four == W.RecentMax and four[1].pattern == P4 and four[2].pattern == P3 and four[3].pattern == P2,
		"fourth: Recent after P1..P4 is " .. show(four) .. ", want P4, P3, P2 (RecentMax " .. tostring(W.RecentMax) .. ")")
	deliver(P3, 150, 2, "merge")
	local merged = recent()
	assert(#merged == W.RecentMax and merged[1].pattern == P3 and merged[1].stars == 3 and merged[2].pattern == P4 and merged[3].pattern == P2,
		"merge: Recent after P3 again at 2 stars is " .. show(merged) .. ", want P3 (3 stars), P4, P2")
	table.insert(out, "6 P1..P4 delivered: " .. show(four) .. "; P3 again at 2 stars: " .. show(merged))
end

-- staging for t77b (see the header). Returns its report line
local function stage()
	fresh("stage")
	local r, c = spawnArrived("stage")
	assert(c.beat == false, "stage: the payload's beat at arrival is " .. showBeat(c.beat) .. ", want false (no beat yet)")
	assert(type(c.hint) == "table" and c.hint.term == "placement", "stage: the staged card's hint is " .. tostring(c.hint and c.hint.term) .. ", want placement")
	assert(wi:Invoke("SetDeferred", uid, r.token, true) == true, "stage: SetDeferred(true) refused")
	deliver(P1, 142, 3, "stage")
	for _ = 1, 3 do fire(P1, 142, "stage") end
	assert(wi:Invoke("SetDeferred", uid, r.token, false) == true, "stage: SetDeferred(false) refused")
	task.wait(0.1)
	local u = lastBeatUpdate(r.token)
	assert(type(u) == "table" and type(u.beat) == "table" and u.beat.stars == 3 and u.beat.fires == 3 and u.beat.bpm == 142 and u.line == filled(142),
		"stage: the last \"beat\" update is " .. (u and (showBeat(u.beat) .. " '" .. tostring(u.line) .. "'") or "missing") .. ", want { 3, 3, 142 } and '" .. filled(142) .. "'")
	assert(pending() and pending().arrived, "stage: no arrived visit left for t77b")
	return "stage: " .. CARD .. " open for t77b, arrived with no beat, updated to " .. showBeat(u.beat) .. ", line '" .. u.line .. "', hint placement"
end

local ok, msg = pcall(run)
local staged
if ok then ok, staged = pcall(stage) end
if not ok then
	pcall(function()
		wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
		test:Invoke("ResetHints", uid); test:Invoke("SetRecent", uid, {}); ph:Invoke("Quiet", uid, false); mon:Invoke("Cancel", uid)
	end)
	pcall(teleport, LOUNGE)
	error(msg or staged, 0)
end
return "T77A PLAY OK\n" .. table.concat(out, "\n") .. "\n" .. staged .. string.format("\nelapsed %.1f s", os.clock() - T0)
