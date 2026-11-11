-- Server, during play (two sessions Task 4; Review Focus 1, 4, 5), before t66b: the hometown kid through the phone
-- hook, paused, Quiet on for the whole body (as t65a: the hook's Open and Choose ignore Quiet, and every check reads the
-- hook's return or GetProfile, so no pop or result reaches the live client). The file's own fresh() (unseated in the
-- lounge, Quiet on, WalkIns Reset, Career Reset, then _StudioTestHook ResetXPCount(uid, "Phone"): the XP gate's
-- per-day count, which Career Reset leaves alone). XP is prof.xp through GetProfile.
-- (1) Pop, Open, Choose 1 on two_sessions: XP +40, chips exactly ["+40 XP", "+100 FOLLOWERS"] in that order, planted
-- true, payback_homekid queued once. (2) a second pick the same day: XP +40 (dailyMax 3), planted nil, still one
-- payback_homekid queued, and the note is the generic one that promises no visit. (3) a third pick pays 40; the fourth pays 0 (dailyMax used) and
-- its chips have no xp chip, the followers chip still there. (4) DISMISS on a fifth pop changes nothing (stats, XP,
-- queue). (5) WalkIns AdvanceVisits until payback_homekid is due, the walk-in SetRng {1} (its news rolls good), Spawn()
-- with no id: the scheduler's pick is payback_homekid; on arrival blewup pays $400, +1 placement, +800 followers.
-- Tail for t66b, after the cleanup: ResetXPCount(uid, "Phone"), every Config.Hints term marked seen (ResetHints with the
-- list, Wave 3: so the DM carries no hint line), Quiet off, then two_sessions popped and opened (the DM left open for the
-- client's choice).
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local Content = require(RS.OK.Data.WalkIns)
local LOUNGE = Vector3.new(24, 3, 0)
local CARD, KID = "two_sessions", "payback_homekid"
local out = {}

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
local function profile() return test:Invoke("GetProfile", uid) end
local function xp() return profile().xp end
local function stats() return career:Invoke("Get", uid) end
local function walkins() return profile().walkins end
local function queuedCount(id)
	local n, entry = 0, nil
	for _, q in ipairs(walkins().queue) do if q.id == id then n += 1; entry = q end end
	return n, entry
end
local function pending() return wi:Invoke("Pending", uid) end
local function arrived() local r = pending(); return r ~= nil and r.arrived == true end
local function hasChip(chips, label)
	for _, c in ipairs(chips or {}) do if c.label == label then return true end end
	return false
end
local function xpChip(chips)
	for _, c in ipairs(chips or {}) do if c.kind == "xp" then return c end end
	return nil
end
local function labels(chips)
	local l = {}
	for _, c in ipairs(chips or {}) do table.insert(l, tostring(c.label)) end
	return "[" .. table.concat(l, ", ") .. "]"
end
local function resetXP(label)
	assert(test:Invoke("ResetXPCount", uid, "Phone") == true, label .. ": _StudioTestHook ResetXPCount(uid, \"Phone\") did not return true"
		.. " (before the Task 4 sync of OK/Main it returns nil: the expected red)")
end
-- the file's own fresh(): unseated and in the lounge, Quiet on, WalkIns and Career reset, the Phone XP count cleared
local function fresh(label)
	local c = p.Character; local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum and hum.Sit then hum.Sit = false; task.wait(0.4) end
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, label .. ": Quiet(true) failed")
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	resetXP(label)
	assert(#ph:Invoke("Pending", uid) == 0 and p:GetAttribute("PhoneBusy") == nil, label .. ": pops or PhoneBusy left after the WalkIns Reset")
end
-- Pop and Open two_sessions; returns the token
local function popOpen(label)
	local t = ph:Invoke("Pop", uid, CARD)
	assert(type(t) == "string", label .. ": Pop(" .. CARD .. ") sent nothing")
	assert(ph:Invoke("Open", uid, t) == true and p:GetAttribute("PhoneBusy") == true, label .. ": the DM did not open (PhoneBusy not set)")
	return t
end
-- a pick of the hometown kid: Pop, Open, Choose 1; returns the result and the XP it moved
local function pickKid(label)
	local x0 = xp()
	local t = popOpen(label)
	local r = ph:Invoke("Choose", uid, t, 1)
	assert(r and r.ok == true and r.result, label .. ": Choose 1 refused: " .. tostring(r and r.reason))
	assert(r.result.key == "home" and r.result.source == "phone", label .. ": choice 1 should land home, landed " .. tostring(r.result.key))
	assert(#ph:Invoke("Pending", uid) == 0 and p:GetAttribute("PhoneBusy") == nil, label .. ": the DM is still pending or PhoneBusy after the choice")
	return r.result, xp() - x0
end

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh("hometown")
	local card = Content.CardById[CARD]
	local good = card and card.choices[1].good
	assert(good and card.choices[1].sure and good.xp == 40 and good.followers == 100 and type(good.plant) == "table" and good.plant.id == KID,
		CARD .. "'s choice 1 is not a sure outcome paying xp 40 and +100 followers that plants " .. KID)
	assert(queuedCount(KID) == 0, "hometown: " .. KID .. " queued after the WalkIns Reset")

	-- 1: the first pick pays 40 XP, shows it, and plants the kid's comeback
	local r1, dx1 = pickKid("pick 1")
	assert(dx1 == 40, "pick 1: XP should rise by 40, rose by " .. dx1)
	assert(labels(r1.chips) == "[+40 XP, +100 FOLLOWERS]", "pick 1: want exactly the chips [+40 XP, +100 FOLLOWERS] in that order, got " .. labels(r1.chips))
	local x = xpChip(r1.chips)
	assert(x and x.label == "+40 XP", "pick 1: the xp chip should be kind xp, label +40 XP")
	assert(r1.planted == true, "pick 1: planted should be true, is " .. tostring(r1.planted))
	local n1, entry = queuedCount(KID)
	assert(n1 == 1 and entry, "pick 1: " .. KID .. " should be queued once, is " .. n1)
	table.insert(out, string.format("pick 1: XP +%d, chips %s, planted, %s queued at %d", dx1, labels(r1.chips), KID, entry.at))

	-- 2: a second kid while the first is on his way: XP paid, nothing booked, no Plant, a note that promises no visit
	local r2, dx2 = pickKid("pick 2")
	assert(dx2 == 40 and hasChip(r2.chips, "+40 XP"), "pick 2: want XP +40 and a +40 XP chip (dailyMax 3), got " .. dx2 .. " and " .. labels(r2.chips))
	assert(r2.planted == nil, "pick 2: planted should be nil with " .. KID .. " already queued, is " .. tostring(r2.planted))
	local n2, entry2 = queuedCount(KID)
	assert(n2 == 1 and entry2.at == entry.at, "pick 2: want still one " .. KID .. " at " .. entry.at .. ", got " .. n2)
	assert(r2.note == good.note, "pick 2: the note should be the generic '" .. tostring(good.note) .. "', is '" .. tostring(r2.note) .. "'")
	table.insert(out, "pick 2: XP +40, planted nil, still one " .. KID .. ", note '" .. tostring(r2.note) .. "'")

	-- 3: the third pick uses up dailyMax 3; the fourth pays 0 and shows no xp chip (Review Focus 1)
	local r3, dx3 = pickKid("pick 3")
	assert(dx3 == 40 and hasChip(r3.chips, "+40 XP"), "pick 3: want XP +40 and a +40 XP chip, got " .. dx3 .. " and " .. labels(r3.chips))
	local r4, dx4 = pickKid("pick 4")
	assert(dx4 == 0, "pick 4: dailyMax 3 is used up, XP should not move, moved " .. dx4)
	assert(xpChip(r4.chips) == nil, "pick 4: XP paid 0, so no xp chip; got " .. labels(r4.chips))
	assert(hasChip(r4.chips, "+100 FOLLOWERS"), "pick 4: the followers chip should still be there, got " .. labels(r4.chips))
	local count = (profile().xpLog.count or {}).Phone
	assert(count == 3, "pick 4: the gate's Phone count should be 3, is " .. tostring(count))
	table.insert(out, "pick 3: XP +40; pick 4: XP +0, chips " .. labels(r4.chips) .. " (no xp chip), Phone count 3")

	-- 4: DISMISS changes nothing
	local s0, x0, q0 = stats(), xp(), queuedCount(KID)
	local t5 = popOpen("dismiss")
	local r5 = ph:Invoke("Choose", uid, t5, 0)
	assert(r5 and r5.ok == true and r5.result == nil, "dismiss: choice 0 refused: " .. tostring(r5 and r5.reason))
	local s1 = stats()
	for _, k in ipairs({ "money", "aura", "followers", "placements", "hits", "sponsors" }) do
		assert(s1[k] == s0[k], "dismiss: " .. k .. " moved " .. tostring(s0[k]) .. " -> " .. tostring(s1[k]))
	end
	assert(xp() == x0 and queuedCount(KID) == q0, "dismiss: XP or the queue moved")
	assert(#ph:Invoke("Pending", uid) == 0 and p:GetAttribute("PhoneBusy") == nil, "dismiss: the DM is still pending or PhoneBusy")
	table.insert(out, "dismiss: no stat, XP or queue change")

	-- 5: the kid comes back as a walk-in once he is due; his news rolls good (blewup)
	local _, due = queuedCount(KID)
	local count0 = walkins().count
	local steps = due.at - 1 - count0 -- due at the next arrival once at <= count + 1
	if steps > 0 then assert(wi:Invoke("AdvanceVisits", uid, steps) == true, "comeback: AdvanceVisits failed") end
	local blew = Content.FollowupById[KID].resolve.good
	assert(blew.key == "blewup" and blew.money == 400 and blew.placements == 1 and blew.followers == 800, KID .. "'s good news is not blewup ($400, +1 placement, +800 followers)")
	local before = stats()
	local credCount = ((profile().credLog or {}).count or {}).WalkIn or 0
	assert(wi:Invoke("SetRng", uid, { 1 }) == true, "comeback: SetRng failed")
	assert(wi:Invoke("Spawn", uid) == true, "comeback: Spawn() refused (is the player in the hub?)")
	local r = pending()
	assert(r and r.id == KID, "comeback: the scheduler's pick at visit count " .. (count0 + math.max(steps, 0)) .. " should be " .. KID .. " (due at " .. due.at .. "), is " .. tostring(r and r.id))
	assert(waitFor(arrived, 15), "comeback: the kid did not arrive within 15 s")
	r = pending()
	assert(r.news == "blewup", "comeback: want the news blewup, got " .. tostring(r.news))
	local after = stats()
	assert(after.money - before.money == 400, string.format("comeback: money should rise by $400, rose by %d (credLog WalkIn count before: %d of %d)",
		after.money - before.money, credCount, require(RS.OK.Config).Cred.Sources.WalkIn.dailyMax))
	assert(after.placements - before.placements == 1 and after.followers - before.followers == 800,
		string.format("comeback: want +1 placement and +800 followers, got %+d and %+d", after.placements - before.placements, after.followers - before.followers))
	assert(queuedCount(KID) == 0, "comeback: " .. KID .. " is still queued after he arrived")
	assert(wi:Invoke("Choose", uid, r.token, 0).ok == true, "comeback: walk away failed")
	table.insert(out, string.format("comeback: AdvanceVisits %d, Spawn() -> %s, news blewup: +$400, +1 placement, +800 followers", math.max(steps, 0), KID))

	return "T66A PLAY OK\n" .. table.concat(out, "\n")
end

local ok, msg = pcall(run)
pcall(function() wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); ph:Invoke("Quiet", uid, false) end)
pcall(teleport, LOUNGE)
if not ok then error(msg, 0) end
-- staging for t66b, after the cleanup (its WalkIns Reset ran the phone's reset: no pop, no SetRng list): the Phone XP
-- count cleared so the client's choice pays, Quiet off, then two_sessions popped and opened, the DM left open
resetXP("tail")
-- every explainer seen, so two_sessions ("the one-hit wonder") pops without a hint line and t66b measures the layout it
-- was written for (the hinted layout is t76b's)
local terms = {}
for _, h in ipairs(require(RS.OK.Config).Hints) do table.insert(terms, h.term) end
assert(test:Invoke("ResetHints", uid, terms) == true, "tail: ResetHints with every term did not return true (before the Wave 3 Task 2 sync of OK/Main: nil)")
assert(ph:Invoke("Quiet", uid, false) == true, "tail: Quiet(false) failed")
local tail = ph:Invoke("Pop", uid, CARD)
assert(type(tail) == "string", "tail: Pop(" .. CARD .. ") sent nothing")
assert(ph:Invoke("Open", uid, tail) == true and p:GetAttribute("PhoneBusy") == true, "tail: the DM did not open")
return msg
