-- Server, during play (Wave 3 Task 5; design 4.3; Review Focus 5), before t79b: they remember you. The file's own
-- fresh() (unseated in the lounge, Quiet on, the phone's pops dropped, WalkIns Reset, Career Reset, Life Reset with the
-- career day set to 6, _StudioTestHook ResetHints, and SetRecent({}): no recent beat). The body runs held (WalkInsPaused
-- true) and drives visits through the hooks. "Eligible" is read two ways: the pure rule on live content
-- (WalkInRules.GateOk with the live Rel), and the scheduler's own path, a stored pick (Spawn(id) then Expire before he
-- arrives leaves prof.walkins.next) that the next Spawn() keeps only if Revalidate, Pick's eligibility with the live
-- opts (opts.rel included), still passes; else it re-picks. Before a stored-pick probe the visit count moves past the
-- artist cooldown and the caps are cleared, so only the relationship can close the card.
-- (0) WalkIns' Reset clears prof.walkins.rel.
-- (1) "Eat with her" on mom_food: Rel(uid).mom = { score 1, flags { fed = 6 } } and nothing else.
-- (2) two_sessions (a phone DM from bookings) through the phone hook (Pop, Open, Choose): the hometown pick writes +1 to
--     homekid, nothing to bookings; then the one-hit wonder sets homekid.passed.
-- (3) homekid_album: with no relationship its stored pick is re-picked; with SetRel { homekid = { score 2, flags {
--     blewup } } } (a misspelled flag) SetRel keeps no flag and it is still re-picked; with { score 2, flags { blew_up } }
--     the stored pick stands, he arrives, and the arrive payload carries beat = false (a card your beat decides; no beat
--     yet) and "something" in the line.
-- (4) mom at -2 and mom_quiet's "Walk her to the car": mom.quiet is set and mom_return queued. Every walk-in mom card
--     (mom_return is a follow-up, never gated) fails GateOk with quiet set and passes without it at a score its own
--     gate allows; mom_food's stored pick is re-picked. mom_return arrives: its news clears quiet; "call her back" is +2
--     (-2 -> 0); mom_food's stored pick then stands.
-- (5) rel.rep at 2 with `renewed`, then signing rep_energy ("Sign it"): rel.rep is gone and the deal is energy.
-- (6a) Fix round 1 (review F2): holding energy at Aura 0 with rel.rep there at score 0 (under 1, not missing): an arrival
--     plants sponsor_drop for energy and no sponsor_warning.
-- (6) Holding energy (floor 150) at Aura 0 with rel.rep 1: an arrival plants sponsor_warning for energy, not
--     sponsor_drop. The warning's arrival (news WARNING, planted) plants sponsor_drop for energy 2 or 3 visits on, and no
--     second warning; the deal stands.
-- (7) Bad data: SetRel with an unknown visitor, an unknown flag, a non-number flag day, a score of 99, a string score and a
--     junk entry keeps { navx = { score 3 }, homekid = { score 0 } } with no flags; SetRel("junk") keeps {}. With bad data
--     set, the scheduler's Spawn() and the phone's Pop() both still pick (no error).
-- Staging for t79b (inside the same pcall): fresh() again, rel navx 2, navx_tv spawned and left open (its payload has no
-- beat: no line under WALK AWAY). On any error everything is reset (hold true, WalkIns, the phone, Career, Life, hints and
-- recent beats, Quiet off) and the error rethrown.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local Config = require(RS.OK.Config)
local Rules = require(RS.OK.Modules.WalkInRules)
local Content = require(RS.OK.Data.WalkIns)
local W = Config.WalkIns
local LOUNGE = Vector3.new(24, 3, 0)
local DAY = 6 -- the career day the body runs on (Life SetDay): a relationship flag is stamped with it
local PAST_COOLDOWN = W.ArtistCooldown + 1 -- visits past the artist cooldown before a stored-pick probe
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
local function walkins() return test:Invoke("GetProfile", uid).walkins end
local function pending() return wi:Invoke("Pending", uid) end
local function arrived() local r = pending(); return r ~= nil and r.arrived == true end
local function queued(id)
	for _, q in ipairs(walkins().queue) do if q.id == id then return q end end
	return nil
end
local function visitorOf(id) local item = Content.CardById[id] or Content.FollowupById[id]; return item and item.visitor end
-- a relationship map as text: "who score [flag@day ...]" sorted, "{}" for none
local function show(rel)
	if type(rel) ~= "table" then return tostring(rel) end
	local ids = {}
	for id in pairs(rel) do table.insert(ids, id) end
	table.sort(ids)
	local parts = {}
	for _, id in ipairs(ids) do
		local e, fl = rel[id], {}
		for f, d in pairs(type(e) == "table" and type(e.flags) == "table" and e.flags or {}) do table.insert(fl, f .. "@" .. tostring(d)) end
		table.sort(fl)
		table.insert(parts, string.format("%s %s [%s]", id, tostring(type(e) == "table" and e.score), table.concat(fl, " ")))
	end
	return "{" .. table.concat(parts, "; ") .. "}"
end
local function rel()
	local r = wi:Invoke("Rel", uid)
	assert(type(r) == "table", "Rel(uid) returned " .. typeof(r) .. " (before the Task 5 sync of Systems/WalkIns it returns nil: the expected red)")
	return r
end
local function setRel(r, label)
	local kept = wi:Invoke("SetRel", uid, r)
	assert(type(kept) == "table", label .. ": SetRel returned " .. typeof(kept) .. " (before the Task 5 sync of Systems/WalkIns it returns nil: the expected red)")
	return kept
end
local function set(s, label) assert(career:Invoke("Set", uid, s) == true, label .. ": Career Set failed") end
-- the newest "arrive" payload in the walk-in hook's Sent (the read drains it)
local function lastArrive()
	local got
	for _, e in ipairs(wi:Invoke("Sent", uid)) do if e.kind == "arrive" then got = e.payload end end
	return got
end
-- the file's own fresh(): unseated and in the lounge, Quiet on, no pops, WalkIns, Career and Life reset (career day DAY),
-- no hint seen, no recent beat
local function fresh(label)
	local c = p.Character; local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum and hum.Sit then hum.Sit = false; task.wait(0.4) end
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, label .. ": Quiet(true) failed")
	assert(ph:Invoke("Reset", uid) == true, label .. ": phone Reset failed")
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	assert(life:Invoke("Reset", uid) == true, label .. ": Life Reset failed")
	assert(life:Invoke("SetDay", uid, DAY) == true, label .. ": Life SetDay(" .. DAY .. ") failed")
	assert(test:Invoke("ResetHints", uid) == true, label .. ": ResetHints failed")
	assert(type(test:Invoke("SetRecent", uid, {})) == "table", label .. ": SetRecent({}) failed")
end
-- `id` walked in (Spawn(id): a card, or a queued follow-up); returns the arrived record and its arrive payload's card
local function spawnArrived(id, label)
	wi:Invoke("Sent", uid) -- drained: the arrive read below is this visit's
	assert(wi:Invoke("Spawn", uid, id) == true, label .. ": Spawn(" .. id .. ") refused")
	assert(waitFor(arrived, 15), label .. ": " .. id .. " did not arrive within 15 s")
	local a = lastArrive()
	assert(type(a) == "table" and type(a.card) == "table" and a.card.id == id, label .. ": no arrive payload for " .. id)
	return pending(), a.card
end
local function choose(r, index, label)
	local res = wi:Invoke("Choose", uid, r.token, index)
	assert(res and res.ok == true, label .. ": Choose " .. index .. " refused: " .. tostring(res and res.reason))
	return res.result
end
-- the scheduler's own verdict on `id`: stored as the pick (Spawn(id), then Expire before he arrives), then Spawn() keeps it
-- if Revalidate passes with the live opts, else re-picks; that visit is expired too. Past the cooldown, caps cleared.
-- Returns the id the scheduler sent
local function probe(id, label)
	assert(wi:Invoke("AdvanceVisits", uid, PAST_COOLDOWN) == true, label .. ": AdvanceVisits failed")
	assert(wi:Invoke("SetCaps", uid, {}) == true, label .. ": SetCaps({}) failed")
	assert(wi:Invoke("Spawn", uid, id) == true, label .. ": Spawn(" .. id .. ") refused")
	assert(wi:Invoke("Expire", uid) == true, label .. ": Expire found no visit")
	local n = walkins().next
	assert(n and n.id == id, label .. ": " .. id .. " is not the stored pick after he walked out (" .. tostring(n and n.id) .. ")")
	assert(wi:Invoke("Spawn", uid) == true, label .. ": Spawn() refused")
	local r = pending()
	assert(r and type(r.id) == "string", label .. ": no visit after Spawn()")
	assert(wi:Invoke("Expire", uid) == true, label .. ": Expire found no visit")
	return r.id
end
-- the pure rule on live content: GateOk(card, the career now with visits = count, `relMap`)
local function gate(id, relMap)
	local c = career:Invoke("Get", uid)
	return Rules.GateOk(Content.CardById[id], c, walkins().count, relMap)
end

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")

	-- 0. Reset clears rel
	fresh("reset")
	local kept0 = setRel({ mom = { score = 2 } }, "reset")
	assert(kept0.mom and kept0.mom.score == 2, "reset: SetRel({ mom 2 }) kept " .. show(kept0))
	assert(wi:Invoke("Reset", uid) == true, "reset: WalkIns Reset failed")
	assert(next(rel()) == nil, "reset: Rel after WalkIns Reset is " .. show(rel()) .. ", want {}")
	table.insert(out, "0 SetRel({ mom 2 }) then WalkIns Reset: Rel {}")

	-- 1. mom_food, "Eat with her"
	fresh("fed")
	local r1 = spawnArrived("mom_food", "fed")
	local res1 = choose(r1, 1, "fed")
	assert(res1.key == "fed", "fed: choice 1 landed " .. tostring(res1.key) .. ", want fed")
	local rel1 = rel()
	assert(show(rel1) == "{mom 1 [fed@" .. DAY .. "]}", "fed: Rel is " .. show(rel1) .. ", want {mom 1 [fed@" .. DAY .. "]}")
	table.insert(out, "1 mom_food 'Eat with her': Rel " .. show(rel1))

	-- 2. two_sessions writes to the kid, not to bookings
	fresh("two sessions")
	local function phoneChoose(index, label)
		local token = ph:Invoke("Pop", uid, "two_sessions")
		assert(type(token) == "string", label .. ": Pop(two_sessions) sent nothing")
		assert(ph:Invoke("Open", uid, token) == true, label .. ": Open failed")
		local res = ph:Invoke("Choose", uid, token, index)
		assert(res and res.ok == true and type(res.result) == "table", label .. ": phone Choose " .. index .. " refused: " .. tostring(res and res.reason))
		return res.result.key
	end
	local k2 = phoneChoose(1, "hometown")
	assert(k2 == "home", "hometown: choice 1 landed " .. tostring(k2))
	local rel2 = rel()
	assert(show(rel2) == "{homekid 1 []}", "hometown: Rel is " .. show(rel2) .. ", want {homekid 1 []} (homekid, never bookings)")
	local k2b = phoneChoose(2, "one-hit wonder")
	local rel2b = rel()
	assert(show(rel2b) == "{homekid 1 [passed@" .. DAY .. "]}", "one-hit wonder (" .. tostring(k2b) .. "): Rel is " .. show(rel2b) .. ", want {homekid 1 [passed@" .. DAY .. "]}")
	table.insert(out, "2 two_sessions (phone) hometown: Rel " .. show(rel2) .. "; one-hit wonder (" .. tostring(k2b) .. "): " .. show(rel2b))

	-- 3. homekid_album opens on blew_up and a score of 2
	fresh("album")
	local none = probe("homekid_album", "album, no relationship")
	assert(none ~= "homekid_album", "album: with no relationship the stored homekid_album was kept (Revalidate ignored the gates)")
	local typo = setRel({ homekid = { score = 2, flags = { blewup = DAY } } }, "album, misspelled flag")
	assert(show(typo) == "{homekid 2 []}", "album: SetRel with the misspelled flag kept " .. show(typo) .. ", want {homekid 2 []}")
	assert(not gate("homekid_album", rel()), "album: GateOk passes homekid_album with no blew_up")
	local miss = probe("homekid_album", "album, misspelled flag")
	assert(miss ~= "homekid_album", "album: with only a misspelled flag the stored homekid_album was kept")
	local good = setRel({ homekid = { score = 2, flags = { blew_up = DAY } } }, "album")
	assert(show(good) == "{homekid 2 [blew_up@" .. DAY .. "]}", "album: SetRel kept " .. show(good))
	assert(gate("homekid_album", rel()), "album: GateOk fails homekid_album with blew_up and score 2")
	assert(wi:Invoke("AdvanceVisits", uid, PAST_COOLDOWN) == true and wi:Invoke("SetCaps", uid, {}) == true, "album: AdvanceVisits / SetCaps failed")
	assert(wi:Invoke("Spawn", uid, "homekid_album") == true and wi:Invoke("Expire", uid) == true, "album: storing the pick failed")
	wi:Invoke("Sent", uid)
	assert(wi:Invoke("Spawn", uid) == true, "album: Spawn() refused")
	local r3 = pending()
	assert(r3 and r3.id == "homekid_album", "album: with blew_up and score 2 the stored homekid_album was re-picked (" .. tostring(r3 and r3.id) .. ")")
	assert(waitFor(arrived, 15), "album: homekid_album did not arrive within 15 s")
	local a3 = lastArrive()
	local c3 = a3 and a3.card
	assert(c3 and c3.id == "homekid_album", "album: no arrive payload for homekid_album")
	assert(c3.beat == false, "album: the payload's beat is " .. tostring(c3.beat) .. ", want false (a beat card, no beat yet)")
	assert(string.find(c3.line, "something", 1, true) and not string.find(c3.line, "{", 1, true), "album: the line reads '" .. tostring(c3.line) .. "'")
	choose(pending(), 0, "album")
	table.insert(out, string.format("3 homekid_album: no rel -> re-picked %s; misspelled flag -> re-picked %s; blew_up + 2 -> kept, arrived, beat false, line '%s'",
		none, miss, c3.line))

	-- 4. mom stops coming, and comes back
	fresh("quiet")
	setRel({ mom = { score = -2 } }, "quiet")
	local r4 = spawnArrived("mom_quiet", "quiet")
	local res4 = choose(r4, 1, "quiet")
	assert(res4.key == "walked", "quiet: choice 1 landed " .. tostring(res4.key))
	local rel4 = rel()
	assert(show(rel4) == "{mom -2 [quiet@" .. DAY .. "]}", "quiet: Rel is " .. show(rel4) .. ", want {mom -2 [quiet@" .. DAY .. "]}")
	local ret = queued("mom_return")
	local count4 = walkins().count
	assert(ret and ret.at - count4 >= 6 and ret.at - count4 <= 9, "quiet: mom_return is not queued 6-9 visits on (" .. tostring(ret and ret.at) .. " at count " .. count4 .. ")")
	local moms = {}
	for _, c in ipairs(Content.Cards) do
		if c.visitor == "mom" and (c.source or "walkin") == "walkin" then
			-- a score her own gate allows: needs.rel, else under.rel - 1, else 0
			local s = (c.needs and c.needs.rel) or (c.under and c.under.rel and c.under.rel - 1) or 0
			local quiet = { mom = { score = s, flags = { quiet = DAY } } }
			local open = { mom = { score = s, flags = {} } }
			assert(not gate(c.id, quiet), "quiet: " .. c.id .. " passes GateOk while mom is quiet (score " .. s .. ")")
			assert(gate(c.id, open), "quiet: control: " .. c.id .. " fails GateOk at score " .. s .. " without quiet")
			table.insert(moms, c.id)
		end
	end
	assert(#moms >= 5, "quiet: only " .. #moms .. " walk-in mom cards found")
	local q4 = probe("mom_food", "quiet")
	assert(visitorOf(q4) ~= "mom", "quiet: the scheduler sent mom (" .. q4 .. ") while she is quiet")
	local _, c4b = spawnArrived("mom_return", "return")
	assert(type(c4b.news) == "table" and (c4b.news.key == "food" or c4b.news.key == "nofood"), "return: mom_return's news is " .. tostring(c4b.news and c4b.news.key))
	local rel4b = rel()
	assert(rel4b.mom and rel4b.mom.flags.quiet == nil, "return: quiet is still set after mom_return's news: " .. show(rel4b))
	local res4b = choose(pending(), 1, "return")
	assert(res4b.key == "sunday", "return: choice 1 landed " .. tostring(res4b.key))
	local rel4c = rel()
	assert(show(rel4c) == "{mom 0 []}", "return: Rel after 'call her back' is " .. show(rel4c) .. ", want {mom 0 []} (-2 + 2)")
	local back = probe("mom_food", "back")
	assert(back == "mom_food", "back: the stored mom_food was re-picked (" .. back .. ") after quiet cleared")
	table.insert(out, string.format("4 mom_quiet: Rel %s, mom_return at +%d; GateOk false while quiet (true without) for %s; probe sent %s; mom_return news %s -> %s, call back -> %s; probe kept mom_food",
		show(rel4), ret.at - count4, table.concat(moms, ", "), q4, c4b.news.key, show(rel4b), show(rel4c)))

	-- 5. a new deal resets the rep
	fresh("signing")
	set({ sponsor = false, aura = 200 }, "signing")
	local kept5 = setRel({ rep = { score = 2, flags = { renewed = DAY } } }, "signing")
	assert(show(kept5) == "{rep 2 [renewed@" .. DAY .. "]}", "signing: SetRel kept " .. show(kept5))
	local r5 = spawnArrived("rep_energy", "signing")
	local res5 = choose(r5, 1, "signing")
	assert(res5.key == "signed", "signing: choice 1 landed " .. tostring(res5.key))
	local rel5 = rel()
	assert(rel5.rep == nil, "signing: rel.rep after signing rep_energy is " .. show(rel5) .. ", want gone")
	assert(career:Invoke("Get", uid).sponsor == "energy", "signing: the deal is " .. tostring(career:Invoke("Get", uid).sponsor))
	table.insert(out, "5 rep 2 [renewed] then rep_energy signed: Rel " .. show(rel5) .. ", sponsor energy")

	-- 6a. rel.rep at exactly 0 (there, under 1): the drop, not the warning (fix round 1, review F2)
	local floor = Content.SponsorById.energy.floor
	fresh("no warning")
	set({ sponsor = "energy", aura = 0 }, "no warning")
	assert(career:Invoke("Get", uid).aura < floor, "no warning: Aura is not under energy's floor " .. floor)
	local kept6a = setRel({ rep = { score = 0 } }, "no warning")
	assert(show(kept6a) == "{rep 0 []}", "no warning: SetRel kept " .. show(kept6a) .. ", want {rep 0 []} (rel.rep there at score 0)")
	local r6a = spawnArrived("fan_meet", "no warning")
	local d6a = queued("sponsor_drop")
	assert(d6a and type(d6a.ctx) == "table" and d6a.ctx.sponsor == "energy", "no warning: no sponsor_drop queued for energy after an arrival under the floor at rel.rep 0")
	assert(queued("sponsor_warning") == nil, "no warning: sponsor_warning was queued with rel.rep at 0 (the warning needs 1 or more)")
	choose(r6a, 0, "no warning")
	table.insert(out, "6a energy at Aura 0, rep 0 (there, under 1): an arrival queued sponsor_drop (energy), no warning")

	-- 6. the rep's warning instead of the drop, and the drop after it
	fresh("warning")
	set({ sponsor = "energy", aura = 0 }, "warning")
	assert(career:Invoke("Get", uid).aura < floor, "warning: Aura is not under energy's floor " .. floor)
	setRel({ rep = { score = 1 } }, "warning")
	local r6 = spawnArrived("fan_meet", "warning")
	local w = queued("sponsor_warning")
	assert(w and type(w.ctx) == "table" and w.ctx.sponsor == "energy", "warning: no sponsor_warning queued for energy after an arrival under the floor")
	assert(queued("sponsor_drop") == nil, "warning: sponsor_drop was queued with rel.rep at 1")
	choose(r6, 0, "warning")
	local _, c6 = spawnArrived("sponsor_warning", "warned")
	assert(type(c6.news) == "table" and c6.news.headline == "WARNING" and c6.news.planted == true, "warned: the warning's news is "
		.. tostring(c6.news and c6.news.headline) .. " (planted " .. tostring(c6.news and c6.news.planted) .. "), want WARNING, planted")
	local d = queued("sponsor_drop")
	local count6 = walkins().count
	assert(d and type(d.ctx) == "table" and d.ctx.sponsor == "energy" and d.at - count6 >= 2 and d.at - count6 <= 3,
		"warned: sponsor_drop is not queued for energy 2-3 visits on (" .. tostring(d and d.at) .. " at count " .. count6 .. ")")
	assert(queued("sponsor_warning") == nil, "warned: a second sponsor_warning was queued")
	assert(career:Invoke("Get", uid).sponsor == "energy", "warned: the warning dropped the deal")
	choose(pending(), 0, "warned")
	table.insert(out, string.format("6 energy at Aura 0, rep 1: an arrival queued sponsor_warning (energy), no drop; its arrival (WARNING, planted) queued sponsor_drop (energy) at +%d, no second warning; deal kept",
		d.at - count6))

	-- 7. bad data never crashes or unlocks
	fresh("bad data")
	local bad = setRel({ navx = { score = 99, flags = { telly = 1, tv = "x" } }, nobody = { score = 1 }, mom = "junk",
		homekid = { score = "two", flags = 5 } }, "bad data")
	assert(show(bad) == "{homekid 0 []; navx 3 []}", "bad data: SetRel kept " .. show(bad) .. ", want {homekid 0 []; navx 3 []}")
	local junk = setRel("junk", "bad data")
	assert(next(junk) == nil, "bad data: SetRel('junk') kept " .. show(junk))
	setRel({ navx = { score = 1, flags = { telly = DAY } }, nobody = { score = 3, flags = { x = 1 } } }, "bad data")
	assert(show(rel()) == "{navx 1 []}", "bad data: Rel is " .. show(rel()))
	assert(wi:Invoke("Spawn", uid) == true and pending() ~= nil, "bad data: the scheduler's Spawn() refused")
	assert(wi:Invoke("Expire", uid) == true, "bad data: Expire found no visit")
	local token = ph:Invoke("Pop", uid)
	assert(type(token) == "string", "bad data: the phone's Pop() picked nothing")
	assert(ph:Invoke("Reset", uid) == true, "bad data: phone Reset failed")
	table.insert(out, "7 SetRel(junk entries) kept " .. show(bad) .. "; SetRel('junk') kept {}; Spawn() and Pop() still pick")
end

-- staging for t79b (see the header). Returns its report line
local function stage()
	fresh("stage")
	setRel({ navx = { score = 2 } }, "stage")
	local _, c = spawnArrived("navx_tv", "stage")
	assert(c.beat == nil, "stage: navx_tv's payload has a beat (" .. tostring(c.beat) .. "), want none: no beat line")
	assert(type(c.choices) == "table" and #c.choices == 2, "stage: navx_tv has " .. tostring(c.choices and #c.choices) .. " choices, want 2")
	assert(pending() and pending().arrived, "stage: no arrived visit left for t79b")
	return "stage: navx_tv open for t79b (rel navx 2), 2 choices, no beat line, hint " .. tostring(c.hint and c.hint.term)
end

local ok, msg = pcall(run)
local staged
if ok then ok, staged = pcall(stage) end
if not ok then
	pcall(function()
		wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
		test:Invoke("ResetHints", uid); test:Invoke("SetRecent", uid, {}); ph:Invoke("Quiet", uid, false)
	end)
	pcall(teleport, LOUNGE)
	error(msg or staged, 0)
end
return "T79A PLAY OK\n" .. table.concat(out, "\n") .. "\n" .. staged .. string.format("\nelapsed %.1f s", os.clock() - T0)
