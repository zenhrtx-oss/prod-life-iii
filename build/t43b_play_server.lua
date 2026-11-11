-- Server, during play: the WalkIns scheduler through its Studio hook. Paused throughout except the presence case (Poke
-- ignores the pause). Each blocking condition sits next to a positive control that differs from it by that one
-- condition: the unfinished tour, a cypher round and the daily cap each stop a Poke; unpaused in the lounge the live 1 s
-- loop runs the presence timer down and spawns, while outside the hub (Studio Two) the timer does not run. Then a
-- planted follow-up comes back with its news (+1 HIT), a new UTC day resets today and keeps the queue, and an Aura
-- under the sponsor's floor queues the drop, which clears the deal on the next visit.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local test, cy = SOK._StudioTestHook, SOK._StudioCypherHook
local W = require(RS.OK.Config).WalkIns
local Tour = require(RS.OK.Systems.Tour)
local Content = require(RS.OK.Data.WalkIns)
local LOUNGE, STUDIO_TWO = Vector3.new(24, 3, 0), Vector3.new(11.2, 3, 60)
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
local function tag() local c = p.Character; local h = c and c:FindFirstChild("Head"); return h and h:FindFirstChild("OK_WalkInTag") end
local function visitorHere()
	local f = workspace:FindFirstChild("OK_Visitors")
	for _, m in ipairs(f and f:GetChildren() or {}) do if m:GetAttribute("Target") == uid then return true end end
	return false
end
local function phase() return RS.OK.Cypher:GetAttribute("Phase") end
local function queued(id)
	for _, q in ipairs(walkins().queue) do if q.id == id then return q end end
	return nil
end
local function advanceTour() for _, s in ipairs(Tour.Steps) do test:Invoke("TourAdvance", uid, s.id) end end
-- WalkIns state back to defaults, the tour done
local function fresh(label)
	assert(wi:Invoke("Reset", uid) == true, label .. ": Reset failed")
	advanceTour()
end
-- the positive control: from a fresh state a Poke spawns a visitor; then fresh again, idle and under the cap
local function control(label)
	fresh(label)
	assert(wi:Invoke("Poke", uid) == true, label .. ": positive control: Poke did not spawn")
	assert(waitFor(visitorHere, 2), label .. ": positive control: no visitor within 2 s")
	fresh(label)
	assert(pending() == nil, label .. ": still pending after Reset")
	assert(walkins().today < W.DailyMax, label .. ": today is at the cap after Reset")
end
local function blocked(label)
	assert(wi:Invoke("Poke", uid) == false, label .. ": Poke spawned")
	assert(pending() == nil, label .. ": a record was made")
	assert(wi:Invoke("GetRemaining", uid) == 1e6, label .. ": a refused Poke did not restore the presence timer")
	task.wait(0.5)
	assert(not visitorHere(), label .. ": a visitor appeared")
end
local function spawnArrived(label, id)
	assert(wi:Invoke("Spawn", uid, id) == true, label .. ": Spawn(" .. tostring(id) .. ") refused")
	assert(waitFor(arrived, 15), label .. ": he did not arrive within 15 s")
	return pending()
end

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	assert(career:Invoke("Set", uid, { sponsor = false }) == true, "could not clear the sponsor deal")
	teleport(LOUNGE)
	local money0 = stats().money

	-- tour blocks (past the first-ever visit: at count 0 the tour gate is skipped, Wave 3 design 4.4, t76a)
	control("tour blocks")
	assert(wi:Invoke("AdvanceVisits", uid, 1) == true, "tour blocks: AdvanceVisits failed")
	assert(test:Invoke("ResetTour", uid) == true, "tour blocks: ResetTour failed")
	blocked("tour blocks")
	advanceTour()
	table.insert(out, "tour blocks: control spawned; count 1, unfinished tour -> Poke false")

	-- cypher blocks
	control("cypher blocks")
	assert(phase() == "idle", "cypher blocks: the cypher is not idle before the case")
	local j = cy:Invoke("Join", -4301, "WalkIn Test")
	assert(j and j.ok and phase() ~= "idle", "cypher blocks: the fake producer did not open a lobby")
	blocked("cypher blocks")
	for _ = 1, 25 do
		if phase() == "idle" then break end
		cy:Invoke("Skip")
		task.wait(0.4)
	end
	assert(phase() == "idle", "cypher blocks: the cypher did not get back to idle")
	table.insert(out, "cypher blocks: control spawned; phase lobby -> Poke false; back to idle")

	-- daily cap
	control("daily cap")
	assert(wi:Invoke("SetToday", uid, W.DailyMax) == true, "daily cap: SetToday failed")
	blocked("daily cap")
	assert(wi:Invoke("SetToday", uid, 0) == true, "daily cap: SetToday(0) failed")
	table.insert(out, "daily cap: control spawned; today " .. W.DailyMax .. " -> Poke false")

	-- presence: unpaused in the lounge the live 1 s loop counts the timer down and spawns (nothing else calls Poke or
	-- Spawn in that window, so a record can only come from loop -> tick -> schedule); then the same unpaused loop in
	-- Studio Two, one condition changed (where he stands), leaves the timer alone for 5 s
	control("presence")
	assert(wi:Invoke("SetRemaining", uid, 2) == true and wi:Invoke("Pause", uid, false) == true, "presence: could not set the timer / unpause")
	local t0 = os.clock()
	local looped = waitFor(function() return pending() ~= nil or visitorHere() end, 4)
	local took = os.clock() - t0
	wi:Invoke("SetRemaining", uid, 1e6)
	wi:Invoke("Pause", uid, true)
	assert(looped, "presence: unpaused in the lounge with 2 s left, the live loop spawned nothing within 4 s")
	fresh("presence")
	assert(waitFor(function() return pending() == nil and not visitorHere() end, 1), "presence: a visit was left after Reset")
	teleport(STUDIO_TWO)
	assert(wi:Invoke("Pause", uid, false) == true and wi:Invoke("SetRemaining", uid, 3) == true, "presence: could not unpause / set the timer")
	task.wait(5)
	local left = wi:Invoke("GetRemaining", uid)
	local spawned = pending() ~= nil or visitorHere()
	wi:Invoke("SetRemaining", uid, 1e6)
	wi:Invoke("Pause", uid, true)
	teleport(LOUNGE)
	assert(not spawned, "presence: a visitor was scheduled while the player was in Studio Two")
	assert(type(left) == "number" and left >= 2.5 and left <= 3, "presence: the timer ran in Studio Two (3 -> " .. tostring(left) .. ")")
	table.insert(out, string.format("presence: lounge unpaused, the live loop spawned %.1f s after SetRemaining(2); ", took)
		.. "5 s in Studio Two unpaused, nothing spawned, timer still " .. tostring(left))

	-- follow-up: navx_placement choice 1 plants navx_single, which comes back with its news
	fresh("follow-up")
	-- under the BUZZING line whatever ran before: a real Add across it would plant tier_buzzing, due before navx_single
	assert(career:Invoke("Set", uid, { followers = 0 }) == true, "follow-up: Set followers 0 failed")
	assert(wi:Invoke("SetRng", uid, { 1 }) == true, "follow-up: SetRng failed")
	local r1 = spawnArrived("follow-up", "navx_placement")
	local c1 = wi:Invoke("Choose", uid, r1.token, 1)
	assert(c1 and c1.ok and c1.result.key == "placement", "follow-up: choice 1 should land PLACEMENT")
	assert(queued("navx_single"), "follow-up: navx_single was not planted")
	assert(wi:Invoke("AdvanceVisits", uid, 4) == true, "follow-up: AdvanceVisits failed")
	assert(wi:Invoke("SetRng", uid, { 1 }) == true, "follow-up: SetRng failed")
	local hits0 = stats().hits
	local r2 = spawnArrived("follow-up", nil)
	assert(r2.id == "navx_single", "follow-up: the due follow-up did not come first, got " .. tostring(r2.id))
	assert(r2.news == "hit", "follow-up: he did not arrive with the HIT news, got " .. tostring(r2.news))
	local t = tag()
	assert(t and t.Label.Text == "+1 HIT", "follow-up: the tag should read +1 HIT, got " .. tostring(t and t.Label.Text))
	assert(stats().hits == hits0 + 1, "follow-up: hits did not go up by 1")
	assert(not queued("navx_single"), "follow-up: navx_single is still queued after it came")
	assert(wi:Invoke("Choose", uid, r2.token, 0).ok == true, "follow-up: walk away failed")
	table.insert(out, "follow-up: navx_single planted, came back first with news 'hit', tag +1 HIT, hits +1")

	-- rollover: plant again, a full day yesterday; the next check is a new day with the queue kept
	assert(wi:Invoke("SetRng", uid, { 1 }) == true, "rollover: SetRng failed")
	local r3 = spawnArrived("rollover", "navx_placement")
	assert(wi:Invoke("Choose", uid, r3.token, 1).ok == true and queued("navx_single"), "rollover: navx_single was not planted again")
	local today = tonumber(os.date("!%Y%m%d"))
	local yesterday = tonumber(os.date("!%Y%m%d", os.time() - 86400))
	assert(wi:Invoke("SetToday", uid, W.DailyMax) == true and wi:Invoke("SetDay", uid, yesterday) == true, "rollover: SetToday/SetDay failed")
	local poked = wi:Invoke("Poke", uid)
	local st = walkins() -- read at once: the visitor he started has not arrived yet
	assert(poked == true, "rollover: a new day did not let the Poke spawn")
	assert(st.today == 0 and st.day == today, "rollover: today " .. tostring(st.today) .. " day " .. tostring(st.day) .. " after the new day")
	assert(queued("navx_single"), "rollover: the queued follow-up did not survive the day change")
	table.insert(out, "rollover: yesterday at the cap -> Poke spawns, today 0, day " .. today .. ", navx_single still queued")

	-- sponsor drop
	fresh("sponsor drop")
	local sid = Content.Sponsors[1].id
	assert(career:Invoke("Set", uid, { sponsor = sid, sponsors = 1, aura = 0 }) == true, "sponsor drop: Set failed")
	local r4 = spawnArrived("sponsor drop", nil)
	local count = walkins().count
	local drop = queued("sponsor_drop")
	assert(drop and drop.at == count + 1 and drop.ctx and drop.ctx.sponsor == sid, "sponsor drop: sponsor_drop not queued at count + 1 for " .. sid)
	assert(wi:Invoke("Choose", uid, r4.token, 0).ok == true, "sponsor drop: walk away failed")
	local r5 = spawnArrived("sponsor drop", nil)
	assert(r5.id == "sponsor_drop", "sponsor drop: the drop did not come next, got " .. tostring(r5.id))
	assert(p:GetAttribute("Sponsor") == nil and p:GetAttribute("Sponsors") == 0, "sponsor drop: Sponsor " .. tostring(p:GetAttribute("Sponsor")) .. ", Sponsors " .. tostring(p:GetAttribute("Sponsors")))
	assert(wi:Invoke("Choose", uid, r5.token, 0).ok == true, "sponsor drop: walk away failed")
	table.insert(out, "sponsor drop: aura 0 under " .. sid .. "'s floor -> sponsor_drop at count + 1; next visit cleared Sponsor, Sponsors 0")

	career:Invoke("Set", uid, { money = money0, sponsor = false })
	return "T43B PLAY OK\n" .. table.concat(out, "\n")
end

local ok, msg = pcall(run)
pcall(function()
	wi:Invoke("SetRemaining", uid, 1e6); wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid)
	for _ = 1, 25 do if phase() == "idle" then break end; cy:Invoke("Skip"); task.wait(0.4) end
end)
pcall(teleport, LOUNGE)
if not ok then error(msg, 0) end
return msg
