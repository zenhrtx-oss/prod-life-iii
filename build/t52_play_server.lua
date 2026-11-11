-- Server, during play: what a pop does and doesn't apply, through the phone's Studio hook (Quiet on). An un-opened
-- pop that waited ExpireSeconds expires with nothing counted or applied; a NEWS applies at its open, once, with one
-- CardNews; a DM's choice pays no money and moves Aura through the Phone source with one CardChoice; a dismiss logs
-- CardWalkAway only; a stale or foreign token is refused (and an unknown Open gets its expire); an opened DM left
-- OpenExpireSeconds closes as a dismiss and frees the walk-in scheduler; a planted phone follow-up pops once (the
-- pending pop's id is excluded from the next pick) and applies once (a second forced token finds its queue entry
-- taken and drops quietly). Wave E: a second DM's open is refused (un-opened, uncounted) while one DM is open and
-- goes through once it closes; a walk-in timer that ran out behind an open DM is re-armed with Gap, not fired, when
-- the DM closes (unpaused for a few seconds, like t43b's presence case); seven sure Aura choices in one day all pay
-- (Config.Career.Sources.Phone dailyMax = Config.Phone.DailyMax + 1).
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local test = SOK._StudioTestHook
local Config = require(RS.OK.Config)
local P, W = Config.Phone, Config.WalkIns
local Tour = require(RS.OK.Systems.Tour)
local Content = require(RS.OK.Data.WalkIns)
local LOUNGE = Vector3.new(24, 3, 0)
local STATS = { "money", "aura", "followers", "placements", "hits", "sponsors" }
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
local function walkins() return test:Invoke("GetProfile", uid).walkins end
local function stats() return career:Invoke("Get", uid) end
local function pops() return ph:Invoke("Pending", uid) end
local function pendingPop(token)
	for _, e in ipairs(pops()) do if e.token == token then return e end end
	return nil
end
local function state() return ph:Invoke("State", uid) end
local function busy() return p:GetAttribute("PhoneBusy") end
local function queued(id)
	for _, q in ipairs(walkins().queue) do if q.id == id then return q end end
	return nil
end
-- the reward gate's count of awards through "<source>.<stat>" today (DataService._gate's careerLog)
local function awards(key)
	local log = test:Invoke("GetProfile", uid).career.careerLog
	return log and log.count and log.count[key] or 0
end
local function same(a, b, label)
	for _, s in ipairs(STATS) do assert(a[s] == b[s], label .. ": " .. s .. " changed " .. tostring(a[s]) .. " -> " .. tostring(b[s])) end
end
local function advanceTour() for _, s in ipairs(Tour.Steps) do test:Invoke("TourAdvance", uid, s.id) end end
local function fresh(label)
	assert(wi:Invoke("Reset", uid) == true, label .. ": Reset failed")
	advanceTour()
	assert(ph:Invoke("Reset", uid) == true, label .. ": phone Reset failed")
	assert(ph:Invoke("SetToday", uid, 0) == true, label .. ": SetToday failed")
	assert(test:Invoke("ResetFunnelEvents", uid) == true, label .. ": ResetFunnelEvents failed")
	ph:Invoke("Sent", uid) -- read and clear
end
-- the player's phone telemetry entries named `name` (and, when given, with that detail)
local function events(name, detail)
	local n = 0
	for _, e in ipairs(test:Invoke("FunnelEvents", uid)) do
		local f = e.fields or {}
		if e.name == name and f.source == "phone" and (detail == nil or f.detail == detail) then n += 1 end
	end
	return n
end
local function has(sent, kind, token)
	for _, s in ipairs(sent) do if s.kind == kind and s.token == token then return true end end
	return false
end
local function pop(id) local t = ph:Invoke("Pop", uid, id); assert(type(t) == "string", "Pop(" .. tostring(id) .. ") sent nothing"); return t end
local function open(t) assert(ph:Invoke("Open", uid, t) == true, "Open failed"); return t end

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	assert(ph:Invoke("Quiet", uid, true) == true, "Quiet(true) failed")
	assert(career:Invoke("Set", uid, { sponsor = false }) == true, "could not clear the sponsor deal")
	-- a fresh reward log, so the Phone source's dailyMax never binds on this file's awards (money is not career state)
	assert(career:Invoke("Reset", uid) == true, "career Reset failed")
	teleport(LOUNGE)
	local NEWS = Content.CardById.news_spedup
	assert(NEWS and NEWS.news and NEWS.source == "phone" and not NEWS.needs, "news_spedup is not an ungated phone NEWS card")
	local NEWS_GOOD = NEWS.choices[1].good

	-- waited: an un-opened pop older than ExpireSeconds goes with nothing counted or applied
	fresh("waited")
	local s0, st0 = stats(), state()
	local t0 = pop("news_spedup")
	assert(ph:Invoke("Age", uid, P.ExpireSeconds + 1) == 1 and #pops() == 0, "waited: Age(" .. (P.ExpireSeconds + 1) .. ") did not expire the pop")
	same(s0, stats(), "waited")
	assert(state().today == st0.today and state().count == st0.count, "waited: an expired pop counted")
	assert(events("PhoneExpire", "waited") == 1 and events("PhoneOpen") == 0, "waited: want one PhoneExpire 'waited' and no PhoneOpen")
	assert(has(ph:Invoke("Sent", uid), "expire", t0), "waited: no expire was sent")
	table.insert(out, "waited: expired un-opened, no stats, not counted, PhoneExpire waited, expire sent")

	-- news: applies at its open, once; a second open of the token does nothing
	fresh("news")
	local s1, st1 = stats(), state()
	local t1 = pop("news_spedup")
	same(s1, stats(), "news: at send")
	open(t1)
	local s2 = stats()
	assert(s2.followers - s1.followers == (NEWS_GOOD.followers or 0) and s2.aura - s1.aura == (NEWS_GOOD.aura or 0),
		string.format("news: want followers %+d aura %+d, got %+d %+d", NEWS_GOOD.followers or 0, NEWS_GOOD.aura or 0, s2.followers - s1.followers, s2.aura - s1.aura))
	assert(#pops() == 0 and busy() == nil, "news: the NEWS is still pending or PhoneBusy after its open")
	local st2 = state()
	assert(st2.today == st1.today + 1 and st2.count == st1.count + 1, "news: the open did not count once")
	assert(has(ph:Invoke("Sent", uid), "result", t1), "news: no result was sent")
	ph:Invoke("Open", uid, t1)
	same(s2, stats(), "news: second open")
	assert(state().today == st2.today, "news: the second open counted")
	assert(events("CardNews", NEWS_GOOD.key) == 1 and events("PhoneOpen") == 1, "news: want one CardNews '" .. NEWS_GOOD.key .. "' and one PhoneOpen, got " .. events("CardNews") .. " / " .. events("PhoneOpen"))
	table.insert(out, string.format("news: applied at open (followers %+d), once; second open nothing; one CardNews", s2.followers - s1.followers))

	-- choose: a sure, free, aura-paying choice pays no money and awards through the Phone source
	fresh("choose")
	local DM = Content.CardById.scam_curator
	local idx, ch = 3, DM.choices[3]
	assert(ch.sure and not ch.rare and (ch.cost or 0) == 0 and (ch.good.aura or 0) > 0 and (ch.good.money or 0) == 0, "choose: scam_curator choice 3 is not a sure, free, Aura-paying choice")
	local s3, a3 = stats(), awards("Phone.aura")
	local t3 = open(pop("scam_curator"))
	local r3 = ph:Invoke("Choose", uid, t3, idx)
	assert(r3 and r3.ok == true and r3.result and r3.result.key == ch.good.key and r3.result.source == "phone", "choose: choice " .. idx .. " should land " .. ch.good.key .. ", got " .. tostring(r3 and (r3.reason or (r3.result and r3.result.key))))
	local s4 = stats()
	assert(s4.money == s3.money and p:GetAttribute("Cred") == s3.money, "choose: money moved " .. s3.money .. " -> " .. s4.money)
	assert(s4.aura == s3.aura + ch.good.aura, "choose: aura should rise by " .. ch.good.aura .. ", got " .. (s4.aura - s3.aura))
	assert(awards("Phone.aura") == a3 + 1, "choose: no Phone.aura award in the career log")
	local auraChip = false
	for _, c in ipairs(r3.result.chips) do if c.kind == "aura" and c.label:sub(1, 1) == "+" then auraChip = true end end
	assert(auraChip, "choose: no +AURA chip in the result")
	assert(events("CardChoice") == 1 and events("CardWalkAway") == 0, "choose: want one CardChoice and no CardWalkAway")
	assert(#pops() == 0 and busy() == nil, "choose: the DM is still pending or PhoneBusy after the choice")
	table.insert(out, string.format("choose: %s choice %d -> %s, money kept, aura %+d via Phone.aura, one CardChoice", DM.id, idx, ch.good.key, ch.good.aura))

	-- dismiss: no stats, one CardWalkAway, no CardChoice
	fresh("dismiss")
	local t5 = open(pop("scam_curator"))
	local s5 = stats()
	local r5 = ph:Invoke("Choose", uid, t5, 0)
	assert(r5 and r5.ok == true and r5.result == nil, "dismiss: choice 0 refused: " .. tostring(r5 and r5.reason))
	same(s5, stats(), "dismiss")
	assert(events("CardWalkAway") == 1 and events("CardChoice") == 0, "dismiss: want one CardWalkAway and no CardChoice")
	assert(#pops() == 0 and busy() == nil, "dismiss: the DM is still pending or PhoneBusy after the dismiss")
	table.insert(out, "dismiss: no stats, one CardWalkAway")

	-- stale: a foreign token is refused stale; an unknown Open gets its expire; an un-opened DM's choice is invalid
	fresh("stale")
	local r6 = ph:Invoke("Choose", uid, "not-a-token", 1)
	assert(r6 and r6.ok == false and r6.reason == "stale", "stale: a foreign token was not refused stale: " .. tostring(r6 and r6.reason))
	ph:Invoke("Open", uid, "not-a-token")
	assert(has(ph:Invoke("Sent", uid), "expire", "not-a-token"), "stale: an unknown Open did not send its expire")
	local t6 = pop("scam_curator")
	local r6b = ph:Invoke("Choose", uid, t6, 1)
	assert(r6b and r6b.ok == false and r6b.reason == "invalid" and #pops() == 1, "stale: a choice on an un-opened DM should be invalid and keep it, got " .. tostring(r6b and r6b.reason))
	table.insert(out, "stale: foreign Choose stale; unknown Open -> expire; un-opened DM Choose invalid")

	-- opened: an opened DM left OpenExpireSeconds closes as a dismiss, stays counted, frees the walk-in scheduler
	fresh("opened")
	local t7 = open(pop("scam_curator"))
	local s7, st7 = stats(), state()
	assert(busy() == true, "opened: PhoneBusy not set")
	assert(ph:Invoke("Age", uid, P.OpenExpireSeconds + 1) == 1, "opened: Age(" .. (P.OpenExpireSeconds + 1) .. ") did not close the open DM")
	assert(busy() == nil and ph:Invoke("Busy", uid) == false and #pops() == 0, "opened: PhoneBusy or the DM is still there")
	same(s7, stats(), "opened")
	assert(state().today == st7.today and state().count == st7.count, "opened: the counts moved after the open")
	assert(events("PhoneExpire", "opened") == 1, "opened: want one PhoneExpire 'opened', got " .. events("PhoneExpire"))
	assert(has(ph:Invoke("Sent", uid), "expire", t7), "opened: no expire was sent")
	assert(wi:Invoke("Poke", uid) == true, "opened: Poke did not schedule a walk-in after the DM closed")
	table.insert(out, "opened: DM closed after OpenExpireSeconds, no stats, still counted, PhoneExpire opened, Poke true")

	-- one pop: a due phone follow-up pops once; the next pick excludes it
	fresh("one pop")
	assert(wi:Invoke("Plant", uid, "clip_context") == true, "one pop: Plant failed")
	local t8 = pop(nil)
	local t8b = ph:Invoke("Pop", uid)
	local n = 0
	for _, e in ipairs(pops()) do if e.id == "clip_context" then n += 1 end end
	assert(n == 1, "one pop: clip_context should be pending exactly once, got " .. n)
	assert(pops()[1].token == t8 and pops()[1].id == "clip_context" and pops()[1].kind == "news", "one pop: the due follow-up did not pop first as NEWS")
	table.insert(out, "one pop: clip_context popped once; the second Pop brought " .. tostring(t8b and pops()[2] and pops()[2].id or "nothing"))

	-- applies once: two forced tokens for one follow-up; the first open applies, the second finds the queue entry taken
	fresh("applies once")
	assert(wi:Invoke("Plant", uid, "clip_context") == true, "applies once: Plant failed")
	assert(ph:Invoke("SetRng", uid, { 1 }) == true, "applies once: SetRng failed")
	local F = Content.FollowupById.clip_context
	local good = F.resolve.good
	local ta, tb = pop("clip_context"), pop("clip_context")
	assert(ta ~= tb and #pops() == 2, "applies once: two tokens expected")
	local s9, a9, f9 = stats(), awards("Phone.aura"), awards("Phone.followers")
	open(ta)
	local s10 = stats()
	assert(s10.aura - s9.aura == good.aura and s10.followers - s9.followers == good.followers,
		string.format("applies once: want aura %+d followers %+d, got %+d %+d", good.aura, good.followers, s10.aura - s9.aura, s10.followers - s9.followers))
	assert(awards("Phone.aura") == a9 + 1 and awards("Phone.followers") == f9 + 1, "applies once: want one Phone award per positive stat")
	assert(not queued("clip_context"), "applies once: clip_context is still queued after its open")
	local st10 = state()
	assert(st10.today == 1 and events("CardNews", good.key) == 1, "applies once: the first open should count once with one CardNews")
	open(tb)
	same(s10, stats(), "applies once: second token")
	assert(awards("Phone.aura") == a9 + 1 and awards("Phone.followers") == f9 + 1, "applies once: the second token awarded again")
	assert(state().today == st10.today and state().count == st10.count, "applies once: the second token counted")
	assert(busy() == nil and #pops() == 0, "applies once: PhoneBusy or a pop left after the second token")
	assert(events("PhoneExpire", "taken") == 1 and events("CardNews") == 1, "applies once: want one PhoneExpire 'taken' and still one CardNews")
	assert(has(ph:Invoke("Sent", uid), "expire", tb), "applies once: no expire for the second token")
	table.insert(out, string.format("applies once: clip_context good (aura %+d, followers %+d) once; the second token -> expire, PhoneExpire taken", good.aura, good.followers))

	-- one open DM at a time: a second waiting DM's open is refused while the first is open (it stays un-opened and
	-- uncounted, PhoneBusy unchanged), then opens once the first expires; PhoneBusy never outlives the opened one
	fresh("one open DM")
	local DM2 = Content.CardById.dm_drift
	assert(DM2 and DM2.source == "phone" and not DM2.news, "one open DM: dm_drift is not a phone DM")
	local t11, t12 = pop("scam_curator"), pop("dm_drift")
	open(t11)
	assert(busy() == true and state().today == 1, "one open DM: the first open did not count / set PhoneBusy")
	ph:Invoke("Open", uid, t12)
	local e12 = pendingPop(t12)
	assert(e12 and e12.opened == false and e12.kind == "dm", "one open DM: the second DM opened (or went) behind the first")
	assert(state().today == 1 and events("PhoneOpen") == 1, "one open DM: the refused open counted (today " .. state().today .. ", PhoneOpen " .. events("PhoneOpen") .. ")")
	assert(busy() == true and ph:Invoke("Busy", uid) == true, "one open DM: the refused open moved PhoneBusy")
	assert(ph:Invoke("Age", uid, P.OpenExpireSeconds + 1) == 1, "one open DM: Age(" .. (P.OpenExpireSeconds + 1) .. ") should drop the open DM only")
	assert(events("PhoneExpire", "opened") == 1 and events("PhoneExpire") == 1, "one open DM: want one PhoneExpire 'opened', got " .. events("PhoneExpire"))
	assert(busy() == nil and ph:Invoke("Busy", uid) == false, "one open DM: PhoneBusy stayed after the open DM closed")
	e12 = pendingPop(t12)
	assert(#pops() == 1 and e12 and e12.opened == false, "one open DM: the second DM is gone or opened after the first closed")
	open(t12)
	assert(state().today == 2 and busy() == true and events("PhoneOpen") == 2, "one open DM: the second DM did not open once the first closed")
	assert(ph:Invoke("Choose", uid, t12, 0).ok == true and busy() == nil and #pops() == 0, "one open DM: the dismiss did not clear the second DM")
	table.insert(out, "one open DM: second DM refused while the first is open (today 1, un-opened, busy kept); opened after the first expired (today 2)")

	-- DM holds a run-out timer: a walk-in timer already at 0 (it ran out behind a cypher or the cap) is re-armed with
	-- Gap while a DM is open, so the DM's close never fires a visitor at once. The live loop runs unpaused for a few
	-- seconds, as in t43b's presence case; re-paused on every exit
	fresh("timer hold")
	assert(wi:Invoke("SetRemaining", uid, 0) == true, "timer hold: SetRemaining(0) failed")
	local t13 = open(pop("scam_curator"))
	assert(busy() == true, "timer hold: PhoneBusy not set")
	local okHold, leftHold = pcall(function()
		assert(wi:Invoke("Pause", uid, false) == true, "timer hold: unpause failed")
		task.wait(2)
		local left = wi:Invoke("GetRemaining", uid)
		assert(wi:Invoke("Pending", uid) == nil, "timer hold: a walk-in was scheduled behind the open DM")
		assert(type(left) == "number" and left >= 1, "timer hold: the run-out timer was not re-armed behind the open DM (" .. tostring(left) .. ")")
		assert(ph:Invoke("Choose", uid, t13, 0).ok == true and busy() == nil, "timer hold: the dismiss failed")
		task.wait(3)
		left = wi:Invoke("GetRemaining", uid)
		assert(wi:Invoke("Pending", uid) == nil, "timer hold: a walk-in fired the moment the DM closed")
		assert(type(left) == "number" and left >= W.Gap[1] - 6, "timer hold: " .. tostring(left) .. " s left 3 s after the DM closed, want >= " .. (W.Gap[1] - 6))
		return left
	end)
	wi:Invoke("SetRemaining", uid, 1e6)
	assert(wi:Invoke("Pause", uid, true) == true, "timer hold: re-pause failed")
	if not okHold then error(leftHold, 0) end
	table.insert(out, string.format("timer hold: timer 0 behind an open DM re-armed; %s s left 3 s after the dismiss, no visitor", tostring(leftHold)))

	-- seven awards in a day: Config.Career.Sources.Phone.aura.dailyMax = Config.Phone.DailyMax + 1 (a DM opened before
	-- UTC midnight and answered after it is counted on the old day but awarded on the new), so DailyMax + 1 sure Aura
	-- choices in one day all pay (the count follows a DailyMax retune; t46 pins the + 1). The hook's Pop skips DailyMax
	-- (today reaches DailyMax + 1); each pop resolves before the next (MaxWaiting)
	fresh("seven awards")
	assert(career:Invoke("Reset", uid) == true, "seven awards: career Reset failed")
	local N = P.DailyMax + 1
	local aura14 = stats().aura
	for i = 1, N do
		local t = open(pop("scam_curator"))
		local r = ph:Invoke("Choose", uid, t, idx)
		assert(r and r.ok == true and r.result and r.result.key == ch.good.key, "seven awards: choice " .. i .. " of " .. N .. " refused: " .. tostring(r and (r.reason or (r.result and r.result.key))))
	end
	local gained14 = stats().aura - aura14
	assert(gained14 == N * ch.good.aura, "seven awards: want aura +" .. N * ch.good.aura .. " over " .. N .. " pops (Config.Phone.DailyMax + 1), got +" .. gained14
		.. " (Config.Career.Sources.Phone.aura.dailyMax " .. tostring(Config.Career.Sources.Phone.aura.dailyMax) .. ")")
	assert(awards("Phone.aura") == N and state().today == N, "seven awards: want " .. N .. " Phone.aura awards and today " .. N .. ", got " .. awards("Phone.aura") .. " / " .. state().today)
	assert(events("CardChoice") == N, "seven awards: want " .. N .. " CardChoice, got " .. events("CardChoice"))
	table.insert(out, string.format("seven awards: %d x %s choice %d -> aura +%d, %d Phone.aura awards, %d CardChoice", N, DM.id, idx, gained14, N, N))

	return "T52 PLAY OK\n" .. table.concat(out, "\n")
end

local ok, msg = pcall(run)
pcall(function() wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); ph:Invoke("Quiet", uid, false); wi:Invoke("Pause", uid, true) end)
pcall(teleport, LOUNGE)
if not ok then error(msg, 0) end
return msg
