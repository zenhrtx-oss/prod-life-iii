-- Server, during play: the walk-in scheduler's Wave 1a rules through its Studio hook (paused; Spawn and the stored
-- pick). A fresh profile's first walk-in is gentle_first; mom's weekly cap holds on the cap keys (an old week's count
-- doesn't bind, this week's does, and the walk-in day counter never touches it); a stored pick whose gate closed is
-- re-picked, with the still-open gate as the control (Review Focus 3); the first HIT system-plants mom_plaque once;
-- a capped card counts at arrival, not at the pick; an artist's DM holds his walk-ins (MarkSent) and re-picks a
-- stored pick of his (Revalidate's cooldown). Last, a fame tier crossed before any walk-in (a real Add at count 0): its
-- visit is planted one later on both ends, the first walk-in is still gentle_first, and tier_buzzing comes after.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK._StudioTestHook
local Rules = require(RS.OK.Modules.WalkInRules)
local Tour = require(RS.OK.Systems.Tour)
local Content = require(RS.OK.Data.WalkIns)
local LOUNGE = Vector3.new(24, 3, 0)
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
local function walkins() return test:Invoke("GetProfile", uid).walkins end
local function stats() return career:Invoke("Get", uid) end
local function pending() return wi:Invoke("Pending", uid) end
local function arrived() local r = pending(); return r ~= nil and r.arrived == true end
local function visitorOf(id) local item = Content.CardById[id] or Content.FollowupById[id]; return item and item.visitor end
local function queued(id)
	for _, q in ipairs(walkins().queue) do if q.id == id then return q end end
	return nil
end
local function advanceTour() for _, s in ipairs(Tour.Steps) do test:Invoke("TourAdvance", uid, s.id) end end
local function fresh(label)
	assert(wi:Invoke("Reset", uid) == true, label .. ": Reset failed")
	advanceTour()
	assert(ph:Invoke("Reset", uid) == true, label .. ": phone Reset failed")
	assert(ph:Invoke("SetToday", uid, 0) == true, label .. ": SetToday failed")
	assert(test:Invoke("ResetFunnelEvents", uid) == true, label .. ": ResetFunnelEvents failed")
end
-- the scheduler's own pick (Spawn with no id); returns the record
local function spawnDefault(label)
	assert(wi:Invoke("Spawn", uid) == true, label .. ": Spawn() refused")
	local r = pending()
	assert(r and type(r.id) == "string", label .. ": no record after Spawn()")
	return r
end
-- an explicit pick stored, then sent out before he arrives: the stored pick stays in prof.walkins.next
local function storeOnly(label, id)
	assert(wi:Invoke("Spawn", uid, id) == true, label .. ": Spawn(" .. id .. ") refused")
	assert(wi:Invoke("Expire", uid) == true, label .. ": Expire refused")
	local n = walkins().next
	assert(n and n.id == id, label .. ": " .. id .. " is not the stored pick after he walked out (" .. tostring(n and n.id) .. ")")
end

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	assert(ph:Invoke("Quiet", uid, true) == true, "Quiet(true) failed")
	assert(career:Invoke("Set", uid, { sponsor = false }) == true, "could not clear the sponsor deal")
	teleport(LOUNGE)
	local day, week = Rules.CapKeys(os.time())

	-- gentle first: a fresh profile's first walk-in is the superfan
	fresh("gentle first")
	local r0 = spawnDefault("gentle first")
	assert(r0.id == "gentle_first" and walkins().next.id == "gentle_first", "gentle first: the first pick was " .. r0.id)
	table.insert(out, "gentle first: Spawn() after Reset -> gentle_first")

	-- mom cap: the weekly group cap on the cap keys; a stored mom pick is reused under an old week's count and
	-- re-picked under this week's, and SetToday (the walk-in day counter) leaves the cap alone
	-- an ungated weekly mom card: no needs, and no under but her silence (Wave 3: every mom card has under.flags
	-- mom.quiet, which a fresh profile never has)
	local function quietOnly(under)
		if under == nil then return true end
		for k in pairs(under) do if k ~= "flags" then return false end end
		return type(under.flags) == "table" and #under.flags == 1 and under.flags[1] == "mom.quiet"
	end
	local momId, cap
	for _, c in ipairs(Content.Cards) do
		if c.cap and c.cap.group == "mom" and not c.needs and quietOnly(c.under) then momId, cap = c.id, c.cap; break end
	end
	assert(momId and cap.per == "week", "mom cap: no ungated weekly mom card in the deck")
	fresh("mom cap")
	assert(wi:Invoke("AdvanceVisits", uid, 1) == true, "mom cap: AdvanceVisits failed")
	storeOnly("mom cap", momId)
	assert(wi:Invoke("SetCaps", uid, { mom = { key = week - 1, n = cap.max } }) == true, "mom cap: SetCaps failed")
	local r1 = spawnDefault("mom cap control")
	assert(r1.id == momId, "mom cap control: last week's count blocked her (" .. r1.id .. ")")
	assert(wi:Invoke("Expire", uid) == true, "mom cap control: Expire refused")
	assert(wi:Invoke("SetCaps", uid, { mom = { key = week, n = cap.max } }) == true and wi:Invoke("SetToday", uid, 0) == true, "mom cap: SetCaps/SetToday failed")
	local r2 = spawnDefault("mom cap")
	assert(visitorOf(r2.id) ~= "mom", "mom cap: she came with this week's count at " .. cap.max .. " (" .. r2.id .. ")")
	local caps = wi:Invoke("Caps", uid)
	assert(caps.mom and caps.mom.key == week and caps.mom.n == cap.max, "mom cap: SetToday touched the cap (" .. tostring(caps.mom and caps.mom.n) .. ")")
	table.insert(out, "mom cap: stored " .. momId .. " reused at week " .. (week - 1) .. " n " .. cap.max .. "; re-picked (" .. r2.id .. ") at week " .. week .. "; SetToday left the cap")

	-- gate closed: a stored rookie pick is reused while the gate is open (999 followers) and re-picked once it closed
	local fol0 = stats().followers
	local function stageRookie(label)
		fresh(label)
		assert(wi:Invoke("AdvanceVisits", uid, 1) == true, label .. ": AdvanceVisits failed")
		assert(career:Invoke("Set", uid, { followers = 0 }) == true, label .. ": Set followers 0 failed")
		storeOnly(label, "rookie_block")
	end
	stageRookie("gate control")
	assert(career:Invoke("Set", uid, { followers = 999 }) == true, "gate control: Set followers 999 failed")
	local r3 = spawnDefault("gate control")
	assert(r3.id == "rookie_block", "gate control: at 999 followers the stored rookie pick was not reused (" .. r3.id .. ")")
	stageRookie("gate closed")
	assert(career:Invoke("Set", uid, { followers = 1000 }) == true, "gate closed: Set followers 1000 failed")
	local r4 = spawnDefault("gate closed")
	assert(not string.find(r4.id, "^rookie_"), "gate closed: at 1,000 followers a rookie card still came (" .. r4.id .. ")")
	assert(walkins().next.id == r4.id, "gate closed: the re-pick was not stored")
	assert(career:Invoke("Set", uid, { followers = fol0 }) == true, "gate closed: restore failed")
	table.insert(out, "gate closed: rookie_block reused at 999 followers, re-picked (" .. r4.id .. ") at 1,000")

	-- first hit: navx_single's HIT news plants mom_plaque at {1, 2} once; a second HIT plants nothing more
	fresh("first hit")
	assert(career:Invoke("Set", uid, { hits = 0 }) == true, "first hit: Set hits 0 failed")
	local function hitVisit(label)
		assert(wi:Invoke("SetRng", uid, { 1 }) == true, label .. ": SetRng failed")
		assert(wi:Invoke("Spawn", uid, "navx_single") == true, label .. ": Spawn(navx_single) refused")
		assert(waitFor(arrived, 15), label .. ": he did not arrive within 15 s")
		local r = pending()
		assert(r.news == "hit", label .. ": no HIT news (" .. tostring(r.news) .. ")")
		assert(wi:Invoke("Choose", uid, r.token, 0).ok == true, label .. ": walk away failed")
	end
	hitVisit("first hit")
	assert(stats().hits == 1, "first hit: hits should be 1, got " .. stats().hits)
	local q, count = queued("mom_plaque"), walkins().count
	assert(q and q.at >= count + 1 and q.at <= count + 2, "first hit: mom_plaque not planted at {1, 2} (at " .. tostring(q and q.at) .. ", count " .. count .. ")")
	hitVisit("second hit")
	assert(stats().hits == 2, "second hit: hits should be 2, got " .. stats().hits)
	local n = 0
	for _, e in ipairs(walkins().queue) do if e.id == "mom_plaque" then n += 1 end end
	assert(n == 1 and queued("mom_plaque").at == q.at, "second hit: mom_plaque planted again (" .. n .. " queued)")
	table.insert(out, "first hit: mom_plaque planted at count " .. count .. " + " .. (q.at - count) .. "; the second HIT planted nothing")

	-- cap at arrival: a stored weird_jar pick counts its group when he arrives, not when it was picked
	fresh("cap at arrival")
	assert(wi:Invoke("AdvanceVisits", uid, 1) == true, "cap at arrival: AdvanceVisits failed")
	storeOnly("cap at arrival", "weird_jar")
	assert(wi:Invoke("Caps", uid).weird == nil, "cap at arrival: the cap counted at the pick")
	local r5 = spawnDefault("cap at arrival")
	assert(r5.id == "weird_jar", "cap at arrival: the stored pick was not reused (" .. r5.id .. ")")
	assert(waitFor(arrived, 15), "cap at arrival: he did not arrive within 15 s")
	local c5 = wi:Invoke("Caps", uid)
	assert(c5.weird and c5.weird.n == 1 and c5.weird.key == day, "cap at arrival: want weird { key " .. day .. ", n 1 }, got " .. tostring(c5.weird and (c5.weird.key .. "/" .. c5.weird.n)))
	assert(wi:Invoke("Choose", uid, pending().token, 0).ok == true, "cap at arrival: walk away failed")
	local r6 = spawnDefault("cap at arrival")
	assert(not string.find(r6.id, "^weird_"), "cap at arrival: a weird card came again today (" .. r6.id .. ")")
	table.insert(out, "cap at arrival: weird_jar stored uncounted, counted at arrival (day " .. day .. "), then no weird_* card")

	-- dm cooldown: an artist's DM marks his cooldown at the send, so he doesn't walk in; a stored pick of his is re-picked
	fresh("dm cooldown")
	assert(wi:Invoke("AdvanceVisits", uid, 1) == true, "dm cooldown: AdvanceVisits failed")
	assert(type(ph:Invoke("Pop", uid, "dm_navx")) == "string", "dm cooldown: Pop(dm_navx) sent nothing")
	local w = walkins()
	assert(w.last.navx == w.count, "dm cooldown: last.navx " .. tostring(w.last.navx) .. " should equal count " .. w.count)
	local r7 = spawnDefault("dm cooldown")
	assert(visitorOf(r7.id) ~= "navx", "dm cooldown: a navx card walked in after his DM (" .. r7.id .. ")")
	fresh("stored navx")
	assert(wi:Invoke("AdvanceVisits", uid, 1) == true, "stored navx: AdvanceVisits failed")
	storeOnly("stored navx", "navx_placement")
	assert(type(ph:Invoke("Pop", uid, "dm_navx")) == "string", "stored navx: Pop(dm_navx) sent nothing")
	local r8 = spawnDefault("stored navx")
	assert(visitorOf(r8.id) ~= "navx" and walkins().next.id == r8.id, "stored navx: the stored navx pick came after his DM (" .. r8.id .. ")")
	table.insert(out, "dm cooldown: dm_navx -> last.navx = count, Spawn() -> " .. r7.id .. "; stored navx_placement re-picked -> " .. r8.id)

	-- gentle first, safe: a tier crossed at count 0 can't take the first slot; the Life Reset comes after Career's
	fresh("tier at count 0")
	assert(career:Invoke("Reset", uid) == true and life:Invoke("Reset", uid) == true, "tier at count 0: a Reset failed")
	assert(career:Invoke("Set", uid, { followers = 900 }) == true, "tier at count 0: Set followers 900 failed")
	assert(wi:Invoke("SetRng", uid, { 1 }) == true, "tier at count 0: SetRng failed") -- the draw clamps to its range's low end: 2 of {2, 3}, or 1 unshifted
	assert(career:Invoke("Add", uid, "followers", 200, "WalkIn") == 200, "tier at count 0: Career Add did not pay 200")
	local qt = queued("tier_buzzing")
	assert(walkins().count == 0 and qt and qt.at == 2, "tier at count 0: want tier_buzzing at 2 (the low end, one later), count " .. walkins().count .. ", at " .. tostring(qt and qt.at))
	local r9 = spawnDefault("tier at count 0")
	assert(r9.id == "gentle_first", "tier at count 0: the first walk-in is " .. r9.id .. ", want gentle_first")
	assert(waitFor(arrived, 15), "tier at count 0: the superfan did not arrive within 15 s")
	assert(wi:Invoke("Choose", uid, pending().token, 0).ok == true, "tier at count 0: walk away failed")
	assert(walkins().count == 1, "tier at count 0: the count after the first walk-in is " .. walkins().count)
	local r10 = spawnDefault("tier after")
	assert(r10.id == "tier_buzzing", "tier at count 0: the walk-in after the first is " .. r10.id .. ", want tier_buzzing")
	table.insert(out, "tier at count 0: tier_buzzing planted at 2, first walk-in gentle_first, then tier_buzzing")

	return "T53 PLAY OK\n" .. table.concat(out, "\n")
end

local ok, msg = pcall(run)
pcall(function() wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid); ph:Invoke("Quiet", uid, false); wi:Invoke("Pause", uid, true) end)
pcall(teleport, LOUNGE)
if not ok then error(msg, 0) end
return msg
