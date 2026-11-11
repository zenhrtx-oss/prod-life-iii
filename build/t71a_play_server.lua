-- Server, during play (Wave 2 Task 3; Review Focus 2), before t71b: tier visits and the career's events through the real
-- walk-in path, paused, Quiet on for the whole body. The file's own fresh() (unseated in the lounge, Quiet on, WalkIns
-- Reset, Career Reset, then the Life Reset, which must come after Career's: it takes the tier from the Followers).
-- (1) Career Set { followers = 900 }, then navx_placement's paid choice (a forced card, its good outcome +300 Followers)
-- crosses BUZZING through the walk-in apply path: the Tier attribute, a `tier` story entry, firsts.buzzing, tier_buzzing
-- queued at {1, 2} and exactly one LifeBanner in the hook's Sent. A Followers Add that crosses nothing sends none.
-- (2) navx_placement's first choice: the discography's newest entry is a placement with the visitor id and
-- the card id, firsts.placement is the career day. (3) A10, the visit before the fall: AdvanceVisits until it is due, a
-- Spawn() with no id picks tier_buzzing, and it pays the good news of research/wave2/copy_2026-10-30.md section 1: $300 and
-- +1,000 Followers, no Aura, Placement or XP. (4) the fall and re-rise after the visit: Set 800, a real Add of 300: no new
-- queue entry, no new tier story entry, no banner (the visit already left the queue, so only the high-water mark can
-- hold this). With the mark put back (SetTier), a real crossing banners again, and PlantSystem refuses the visit already
-- seen, reported as nothing. (5) a hook Set across KNOWN is silent (A3): the tier, its story line and its first, no banner, no plant.
-- Then a real Aura Add with a crossing pending (SetTier puts the mark back under the Followers): recorded, never loud.
-- (6) A4: back under BUZZING (the Life Reset takes the tier down with the Followers), one real Add to 6,000: BUZZING then
-- KNOWN, two banners in order, visits at {1, 2} and {2, 3} (the walk-in rng forced to each range's top). (7) the HIT's news (navx_single), a signed deal, its drop
-- and the kid's first tape: each one's story and discography entry, stored by id; blewup's row is TRACK ONE.
-- Tail for t71b, after the cleanup: Quiet off, _StudioLifeHook Event "hall" (a story entry). The banners this file sent
-- are still coming on the client: t71b waits for them, then t71c stages the tier banner and the LEVEL UP.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local LifeRules = require(RS.OK.Modules.LifeRules)
local Content = require(RS.OK.Data.WalkIns)
local LOUNGE = Vector3.new(24, 3, 0)
local CARD, VISIT, KID = "navx_placement", "tier_buzzing", "payback_homekid"
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
local function profile() return test:Invoke("GetProfile", uid) end
local function walkins() return profile().walkins end
local function stats() return career:Invoke("Get", uid) end
local function state() return life:Invoke("State", uid) end
local function set(s, label) assert(career:Invoke("Set", uid, s) == true, label .. ": Career Set failed") end
local function pending() return wi:Invoke("Pending", uid) end
local function arrived() local r = pending(); return r ~= nil and r.arrived == true end
local function queued(id)
	for _, q in ipairs(walkins().queue) do if q.id == id then return q end end
	return nil
end
local function queueIds()
	local ids = {}
	for _, q in ipairs(walkins().queue) do table.insert(ids, q.id) end
	table.sort(ids)
	return table.concat(ids, ",")
end
-- the LifeBanners sent since the last read, as a comma list of their tiers
local function banners()
	local tiers = {}
	for _, e in ipairs(life:Invoke("Sent", uid)) do
		if e.kind == "LifeBanner" then
			assert(e.payload.text == LifeRules.Copy.Banners[e.payload.tier], "banner text for " .. tostring(e.payload.tier) .. ": " .. tostring(e.payload.text))
			table.insert(tiers, e.payload.tier)
		end
	end
	return table.concat(tiers, ",")
end
local function newest(list) return list[#list] end
local function tierLines(st)
	local ids = {}
	for _, e in ipairs(st.story) do if e.k == "tier" then table.insert(ids, e.key) end end
	return table.concat(ids, ",")
end
local function fresh(label)
	local c = p.Character; local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum and hum.Sit then hum.Sit = false; task.wait(0.4) end
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, label .. ": Quiet(true) failed")
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	assert(life:Invoke("Reset", uid) == true, label .. ": Life Reset failed")
end
-- an explicit card or follow-up (id) or the scheduler's own pick (nil), walked in; returns the arrived record
local function spawnArrived(label, id, rng)
	assert(wi:Invoke("SetRng", uid, rng or { 1 }) == true, label .. ": SetRng failed")
	assert(wi:Invoke("Spawn", uid, id) == true, label .. ": Spawn(" .. tostring(id) .. ") refused")
	assert(waitFor(arrived, 15), label .. ": he did not arrive within 15 s")
	return pending()
end
-- that card's choice, its roll forced good
local function choose(label, r, index)
	assert(wi:Invoke("SetRng", uid, { 1 }) == true, label .. ": SetRng failed")
	local res = wi:Invoke("Choose", uid, r.token, index)
	assert(res and res.ok == true, label .. ": Choose " .. index .. " refused: " .. tostring(res and res.reason))
	return res.result
end
local function leave(label, r) assert(wi:Invoke("Choose", uid, r.token, 0).ok == true, label .. ": walk away failed") end

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh("crossing")

	-- 1: a real gain through a forced card crosses BUZZING: one banner, one planted visit
	set({ followers = 900, money = 2000, sponsor = false }, "crossing")
	assert(banners() == "", "crossing: a Set under the line sent a banner")
	assert(p:GetAttribute("Tier") == "LOCAL", "crossing: Tier at 900 followers should be LOCAL, is " .. tostring(p:GetAttribute("Tier")))
	local c1 = spawnArrived("crossing", CARD)
	local r1 = choose("crossing", c1, 2)
	assert(r1.key == "paid", "crossing: choice 2 forced good should land paid, landed " .. tostring(r1.key))
	assert(stats().followers == 1200, "crossing: 900 + 300 should be 1,200 followers, is " .. stats().followers)
	assert(p:GetAttribute("Tier") == "BUZZING", "crossing: the Tier attribute is " .. tostring(p:GetAttribute("Tier")))
	local s1 = state()
	local e1 = newest(s1.story)
	assert(e1.k == "tier" and e1.key == "BUZZING", "crossing: the newest story entry is " .. tostring(e1.k) .. " " .. tostring(e1.key))
	assert(s1.firsts.buzzing == s1.day, "crossing: firsts.buzzing " .. tostring(s1.firsts.buzzing) .. ", career day " .. s1.day)
	local visit, count = queued(VISIT), walkins().count
	assert(visit, "crossing: " .. VISIT .. " was not queued (before the Task 3 sync of Systems/Life and Systems/WalkIns: the expected red)")
	assert(visit.at >= count + 1 and visit.at <= count + 2, "crossing: " .. VISIT .. " at " .. visit.at .. ", want count " .. count .. " + 1..2")
	local sent = banners()
	assert(sent == "BUZZING", "crossing: want exactly one BUZZING banner, Sent has '" .. sent .. "'")
	table.insert(out, string.format("1 crossing: 900 + 300 through %s: Tier BUZZING, story tier, %s at count + %d, one banner", CARD, VISIT, visit.at - count))

	-- a Followers Add that crosses nothing is not a moment
	assert(career:Invoke("Add", uid, "followers", 10, "WalkIn") == 10, "small add: Career Add did not pay 10")
	assert(banners() == "", "small add: a gain that crosses nothing sent a banner")
	table.insert(out, "1 quiet: a Followers Add under the next line sends no banner")

	-- 2: a placement through a forced card
	local c2 = spawnArrived("placement", CARD)
	local r2 = choose("placement", c2, 1)
	assert(r2.key == "placement" and queued("navx_single"), "placement: choice 1 should land placement and plant navx_single, landed " .. tostring(r2.key))
	local s2 = state()
	local d2 = newest(s2.disco)
	assert(d2 and d2.kind == "placement" and d2.v == "navx" and d2.key == CARD, "placement: the newest discography entry is " .. tostring(d2 and d2.kind) .. " " .. tostring(d2 and d2.v))
	assert(s2.firsts.placement == s2.day, "placement: firsts.placement " .. tostring(s2.firsts.placement) .. ", career day " .. s2.day)
	local e2 = newest(s2.story)
	assert(e2.k == "placement" and e2.v == "navx" and e2.first == true, "placement: the newest story entry is " .. tostring(e2.k))
	table.insert(out, "2 placement: discography placement, navx, " .. CARD .. "; firsts.placement = career day " .. s2.day)

	-- 3: the visit comes before the fall (A10), through the scheduler's own pick
	local steps = queued(VISIT).at - 1 - walkins().count -- due at the next arrival once at <= count + 1
	if steps > 0 then assert(wi:Invoke("AdvanceVisits", uid, steps) == true, "visit: AdvanceVisits failed") end
	assert(career:Invoke("ResetCredCount", uid, "WalkIn") == true, "visit: ResetCredCount failed") -- so the run's earlier cards can't use up the Money gate
	local good = Content.FollowupById[VISIT].resolve.good
	assert(good.key == "shirts" and good.money == 300 and good.followers == 1000 and good.aura == nil and good.placements == nil and good.xp == nil,
		VISIT .. "'s good news is not shirts ($300, +1,000 followers, nothing else)")
	local before, xp0 = stats(), profile().xp
	local rv = spawnArrived("visit", nil)
	assert(rv.id == VISIT, "visit: the scheduler's pick should be " .. VISIT .. ", is " .. tostring(rv.id))
	assert(rv.news == "shirts", "visit: want the news shirts, got " .. tostring(rv.news))
	local after = stats()
	assert(after.money - before.money == 300 and after.followers - before.followers == 1000, string.format("visit: want +$300 and +1,000 followers, got %+d and %+d",
		after.money - before.money, after.followers - before.followers))
	assert(after.aura == before.aura and after.placements == before.placements and profile().xp == xp0, "visit: it paid more than Money and Followers")
	assert(queued(VISIT) == nil, "visit: " .. VISIT .. " is still queued after it came")
	leave("visit", rv)
	table.insert(out, "3 visit: " .. VISIT .. " came (the scheduler's pick), shirts: +$300, +1,000 followers, nothing else")

	-- 4: the fall and re-rise (A10): the visit is gone, so only the high-water mark stops a second one
	set({ followers = 800 }, "fall")
	assert(banners() == "", "fall: a fall sent a banner")
	local queue4, lines4 = queueIds(), tierLines(state())
	assert(career:Invoke("Add", uid, "followers", 300, "WalkIn") == 300, "re-rise: Career Add did not pay 300")
	assert(stats().followers == 1100, "re-rise: followers " .. stats().followers)
	assert(queueIds() == queue4, "re-rise: the queue moved: " .. queue4 .. " -> " .. queueIds())
	assert(queued(VISIT) == nil, "re-rise: " .. VISIT .. " was planted again")
	assert(tierLines(state()) == lines4, "re-rise: a new tier story entry: " .. tierLines(state()))
	assert(banners() == "", "re-rise: a second banner")
	table.insert(out, "4 fall and re-rise: Set 800, real Add 300: no queue entry, no tier line, no banner")
	assert(life:Invoke("SetTier", uid, "LOCAL") == true, "seen: SetTier failed")
	set({ followers = 800 }, "seen")
	assert(career:Invoke("Add", uid, "followers", 300, "WalkIn") == 300, "seen: Career Add did not pay 300")
	assert(banners() == "BUZZING", "seen: with the mark put back the crossing should banner")
	assert(queued(VISIT) == nil, "seen: PlantSystem planted a visit already seen: " .. queueIds())
	table.insert(out, "4 seen: a real crossing with the mark put back: PlantSystem refuses the visit already seen")

	-- 5: a hook Set across a line is silent (A3): recorded, never a moment
	set({ followers = 6000 }, "silent")
	assert(p:GetAttribute("Tier") == "KNOWN", "silent: the Tier attribute is " .. tostring(p:GetAttribute("Tier")))
	local s5 = state()
	assert(newest(s5.story).k == "tier" and newest(s5.story).key == "KNOWN" and s5.firsts.known == s5.day, "silent: KNOWN was not recorded")
	assert(banners() == "", "silent: a Set sent a banner")
	assert(queued("tier_known") == nil, "silent: a Set planted tier_known")
	table.insert(out, "5 silent: a hook Set to 6,000 records KNOWN, no banner, no plant")

	-- an Aura Add is a real Add, but no Followers rose: with a crossing pending it records silently
	assert(life:Invoke("SetTier", uid, "BUZZING") == true, "aura add: SetTier failed")
	assert(career:Invoke("Add", uid, "aura", 5, "WalkIn") == 5, "aura add: Career Add did not pay 5")
	assert(state().tier == "KNOWN", "aura add: the pending crossing was not recorded, tier " .. tostring(state().tier))
	assert(banners() == "", "aura add: an Aura Add sent a banner")
	assert(queued("tier_known") == nil, "aura add: an Aura Add planted tier_known")
	table.insert(out, "5 aura: a real Aura Add with KNOWN pending records it, no banner, no plant")

	-- 6: one real Add across two lines handles both, in order (A4)
	assert(wi:Invoke("Reset", uid) == true, "two tiers: WalkIns Reset failed")
	assert(wi:Invoke("AdvanceVisits", uid, 1) == true, "two tiers: AdvanceVisits failed") -- past count 0, where every plant moves one later (t53)
	set({ followers = 900 }, "two tiers")
	assert(life:Invoke("Reset", uid) == true, "two tiers: Life Reset failed") -- the tier follows the Followers back down
	assert(banners() == "" and p:GetAttribute("Tier") == "LOCAL", "two tiers: not back to LOCAL")
	assert(wi:Invoke("SetRng", uid, { 2, 3 }) == true, "two tiers: SetRng failed") -- each visit's draw at the top of its range
	assert(career:Invoke("Add", uid, "followers", 5100, "WalkIn") == 5100, "two tiers: Career Add did not pay 5,100")
	local two = banners()
	assert(two == "BUZZING,KNOWN", "two tiers: banners '" .. two .. "', want BUZZING,KNOWN")
	assert(tierLines(state()) == "BUZZING,KNOWN", "two tiers: story " .. tierLines(state()))
	local q6, n6, count6 = queued(VISIT), queued("tier_known"), walkins().count
	assert(q6 and n6, "two tiers: both visits should be queued, queue: " .. queueIds())
	assert(q6.at == count6 + 2 and n6.at == count6 + 3, string.format("two tiers: want the top of {1, 2} and of {2, 3}, at %d and %d, count %d", q6.at, n6.at, count6))
	table.insert(out, string.format("6 two tiers: 900 + 5,100: banners BUZZING,KNOWN; visits at count + %d and + %d", q6.at - count6, n6.at - count6))

	-- 7: the rest of the walk-in events, stored by id
	fresh("events")
	set({ sponsor = false }, "events")
	local hitDay = state().day
	local rh = spawnArrived("hit", "navx_single")
	assert(rh.news == "hit", "hit: no HIT news (" .. tostring(rh.news) .. ")")
	local sh = state()
	local eh, dh = newest(sh.story), newest(sh.disco)
	-- +3,000 followers crosses BUZZING in the same apply; the news is logged after it
	assert(eh.k == "hit" and eh.v == "navx" and eh.key == "navx_single" and eh.first == true, "hit: the newest story entry is " .. tostring(eh.k))
	assert(dh.kind == "hit" and dh.v == "navx" and sh.firsts.hit == hitDay, "hit: the newest discography entry is " .. tostring(dh.kind))
	leave("hit", rh)
	wi:Invoke("Reset", uid)
	local rs = spawnArrived("sponsor", "rep_energy")
	assert(choose("sponsor", rs, 1).key == "signed", "sponsor: choice 1 should sign")
	local es = newest(state().story)
	assert(es.k == "sponsor" and es.s == "energy" and es.first == true, "sponsor: the newest story entry is " .. tostring(es.k) .. " " .. tostring(es.s))
	wi:Invoke("Reset", uid)
	set({ aura = 0 }, "drop") -- under the deal's floor: the next arrival queues sponsor_drop for this deal
	local ra = spawnArrived("drop stage", CARD)
	assert(queued("sponsor_drop"), "drop stage: sponsor_drop was not queued at Aura 0")
	leave("drop stage", ra)
	local rd = spawnArrived("drop", nil)
	assert(rd.id == "sponsor_drop", "drop: the pick is " .. tostring(rd.id))
	assert(stats().sponsor == nil, "drop: the deal is still on")
	local ed = newest(state().story)
	assert(ed.k == "sponsor_drop" and ed.s == "energy", "drop: the newest story entry is " .. tostring(ed.k) .. " " .. tostring(ed.s))
	leave("drop", rd)
	wi:Invoke("Reset", uid)
	local rk = spawnArrived("first tape", KID)
	assert(rk.news == "blewup", "first tape: want the news blewup, got " .. tostring(rk.news))
	local dk = newest(state().disco)
	assert(dk.kind == "trackone" and dk.v == "homekid" and dk.key == KID, "first tape: the newest discography entry is " .. tostring(dk.kind))
	leave("first tape", rk)
	table.insert(out, "7 events: hit (story + disco, navx), sponsor and sponsor_drop (s = energy), blewup (disco TRACK ONE)")

	return "T71A PLAY OK\n" .. table.concat(out, "\n")
end

local ok, msg = pcall(run)
pcall(function() wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid); ph:Invoke("Quiet", uid, false) end)
pcall(teleport, LOUNGE)
if not ok then error(msg, 0) end
-- staging for t71b, after the cleanup: a story entry the client's tab can show
local hall = life:Invoke("Event", uid, "hall")
assert(hall and hall.story and hall.story.k == "hall", "tail: the hall event logged nothing")
return msg .. string.format("\ntail: hook Event hall, a story entry; elapsed %.1f s", os.clock() - T0)
