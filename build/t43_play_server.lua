-- Server, during play: the WalkIns system's choices through its Studio hook (_StudioWalkInHook), paused throughout.
-- A spawned navx_placement arrives and counts today; a choice before arrival, a second choice, a foreign token and bad
-- indexes are refused; choice 1 applies exactly its result chips (no XP) and floats a tag that goes after TagSeconds;
-- WALK AWAY changes nothing but counts; an unaffordable choice is refused and keeps the card; a paid choice charges the
-- cost and pays the outcome on their own; a loss at $0 takes nothing and shows only what it applied, with a blue "-"
-- tag; an expired card changes nothing and the visit stays counted. A sponsor drop queued while Aura was under the
-- floor is skipped once Aura is back at the floor (taken out of the queue, the deal kept), the stored pick included.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local test = SOK._StudioTestHook
local W = require(RS.OK.Config).WalkIns
local Theme = require(RS.OK.Modules.UITheme)
local Content = require(RS.OK.Data.WalkIns)
local CARD = Content.CardById.navx_placement
local LOUNGE = Vector3.new(24, 3, 0)
local STATS = { "aura", "followers", "placements", "hits", "sponsors" }
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
local function choose(token, index) return wi:Invoke("Choose", uid, token, index) end
local function queued(id)
	for _, q in ipairs(walkins().queue) do if q.id == id then return q end end
	return nil
end
-- a chip's exact amount: "+$600" -> 600, "-$400" -> -400, "+10 AURA" -> 10, "+500 FOLLOWERS" -> 500 (no K/M here)
local function amount(label)
	local sign, digits, rest = string.gsub(label, "[$,]", ""):match("^([+-]?)(%d+)(.*)$")
	assert(digits and not rest:match("^[%.KM]"), "chip is not an exact amount: " .. tostring(label))
	return (sign == "-" and -1 or 1) * tonumber(digits)
end
local function chipSums(chips)
	local sum = {}
	for _, c in ipairs(chips) do sum[c.kind] = (sum[c.kind] or 0) + amount(c.label) end
	return sum
end
-- spawn navx_placement and wait for him to arrive; returns the in-flight record
local function spawnArrived(label)
	assert(wi:Invoke("Spawn", uid, "navx_placement") == true, label .. ": Spawn(navx_placement) refused")
	assert(waitFor(arrived, 15), label .. ": he did not arrive within 15 s")
	return pending()
end
local function same(a, b, label)
	assert(a.money == b.money, label .. ": money changed " .. a.money .. " -> " .. b.money)
	for _, s in ipairs(STATS) do assert(a[s] == b[s], label .. ": " .. s .. " changed " .. a[s] .. " -> " .. b[s]) end
end

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	assert(wi:Invoke("Reset", uid) == true, "Reset failed")
	assert(career:Invoke("Set", uid, { sponsor = false }) == true, "could not clear the sponsor deal") -- no sponsor-floor plant
	teleport(LOUNGE)
	local money0 = stats().money

	-- arrive (and an early token on the way in)
	assert(wi:Invoke("SetRng", uid, { 1 }) == true, "SetRng failed")
	assert(wi:Invoke("Spawn", uid, "navx_placement") == true, "arrive: Spawn(navx_placement) refused")
	local r0 = pending()
	assert(r0 and r0.id == "navx_placement" and r0.arrived == false and type(r0.token) == "string", "arrive: no unarrived record for navx_placement")
	local early = choose(r0.token, 1)
	assert(early and early.ok == false and early.reason == "stale", "early token: a choice before arrival was not refused stale: " .. tostring(early and early.reason))
	table.insert(out, "early token: refused stale before arrival")
	assert(waitFor(arrived, 15), "arrive: did not arrive within 15 s")
	assert(walkins().today == 1, "arrive: today should be 1 after the arrival, got " .. tostring(walkins().today))
	table.insert(out, "arrive: navx_placement arrived, today 1")

	-- resolve: choice 1 with the roll forced good
	local tok = pending().token
	local before, xp0 = stats(), p:GetAttribute("XP")
	local res = choose(tok, 1)
	assert(res and res.ok == true and res.result and res.result.key == "placement", "resolve: choice 1 should land PLACEMENT, got " .. tostring(res and (res.reason or (res.result and res.result.key))))
	assert(res.result.token == tok and res.result.tone == "win", "resolve: result token/tone wrong")
	local after, sums = stats(), chipSums(res.result.chips)
	assert(after.placements == before.placements + 1, "resolve: placements did not go up by 1")
	for _, k in ipairs({ "money", "followers", "aura" }) do
		assert(after[k] - before[k] == (sums[k] or 0), string.format("resolve: %s moved %d but the chips say %d", k, after[k] - before[k], sums[k] or 0))
	end
	assert(p:GetAttribute("XP") == xp0, "resolve: walk-ins paid XP")
	assert(pending() == nil, "resolve: the record is still there after the choice")
	local t1 = tag()
	assert(t1 and t1:IsA("BillboardGui") and t1.Label.Text:sub(1, 1) == "+", "resolve: no '+' OK_WalkInTag over the player's head")
	assert(t1.Label.TextColor3 == Theme.gold, "resolve: a win tag is not gold")
	local tagText = t1.Label.Text -- read now: destroying the tag after TagSeconds destroys its Label too
	task.wait(W.TagSeconds + 1)
	assert(t1.Parent == nil and tag() == nil, "resolve: the tag is still up after TagSeconds + 1")
	table.insert(out, string.format("resolve: PLACEMENT, money %+d followers %+d aura %+d = chips, no XP, tag '%s' gone after %ds",
		after.money - before.money, after.followers - before.followers, after.aura - before.aura, tagText, W.TagSeconds + 1))

	-- double choose
	local again = choose(tok, 1)
	assert(again and again.ok == false and again.reason == "stale", "double choose: the same token was not refused stale")
	same(after, stats(), "double choose")
	table.insert(out, "double choose: stale, nothing applied twice")

	-- bad index, foreign token, walk away (one visit)
	local count0 = walkins().count
	local r1 = spawnArrived("bad index")
	for _, bad in ipairs({ 5, -1, "1", 1.5 }) do
		local b = choose(r1.token, bad)
		assert(b and b.ok == false and b.reason == "invalid", "bad index: " .. tostring(bad) .. " was not refused invalid: " .. tostring(b and b.reason))
		local still = pending()
		assert(still and still.token == r1.token, "bad index: " .. tostring(bad) .. " cleared the record")
	end
	table.insert(out, "bad index: 5, -1, \"1\", 1.5 refused invalid, card still pending")
	local foreign = choose("not-" .. r1.token, 1)
	assert(foreign and foreign.ok == false and foreign.reason == "stale", "foreign token: not refused stale")
	assert(pending() and pending().token == r1.token, "foreign token: cleared the record")
	table.insert(out, "foreign token: stale")
	local s0 = stats()
	local away = choose(r1.token, 0)
	assert(away and away.ok == true, "walk away: choice 0 refused: " .. tostring(away and away.reason))
	same(s0, stats(), "walk away")
	assert(walkins().count == count0 + 1, "walk away: the visit should count once, count " .. count0 .. " -> " .. walkins().count)
	assert(pending() == nil, "walk away: the record is still there")
	table.insert(out, "walk away: no stat change, count +1")

	-- unaffordable
	local r2 = spawnArrived("unaffordable")
	assert(career:Invoke("Set", uid, { money = 0 }) == true and p:GetAttribute("Cred") == 0, "unaffordable: could not set money to 0")
	local s2 = stats()
	local poor = choose(r2.token, 2)
	assert(poor and poor.ok == false and poor.reason == "afford", "unaffordable: choice 2 at $0 was not refused afford: " .. tostring(poor and poor.reason))
	same(s2, stats(), "unaffordable")
	assert(pending() and pending().token == r2.token and pending().arrived, "unaffordable: the card is not still pending")
	table.insert(out, "unaffordable: choice 2 at $0 refused afford, card still pending")
	assert(choose(r2.token, 0).ok == true, "unaffordable: walk away to clear failed")

	-- paid choice: the cost is charged, the outcome's money comes on its own
	local paid = CARD.choices[2]
	local cost, gain = paid.cost, paid.good.money
	assert(cost and cost > 0 and gain and gain > 0, "paid choice: navx_placement choice 2 should cost and pay money")
	local r3 = spawnArrived("paid choice")
	assert(career:Invoke("Set", uid, { money = 2000 }) == true and p:GetAttribute("Cred") == 2000, "paid choice: could not set money to 2000")
	assert(wi:Invoke("SetRng", uid, { 1 }) == true, "paid choice: SetRng failed")
	local pr = choose(r3.token, 2)
	assert(pr and pr.ok == true and pr.result.key == paid.good.key, "paid choice: choice 2 should land " .. paid.good.key .. ", got " .. tostring(pr and (pr.reason or pr.result.key)))
	local cred = p:GetAttribute("Cred")
	assert(cred == 2000 - cost + gain, string.format("paid choice: Cred %d, want 2000 - %d + %d = %d", cred, cost, gain, 2000 - cost + gain))
	local hasCost = false
	for _, c in ipairs(pr.result.chips) do if c.kind == "money" and c.label == "-$" .. cost then hasCost = true end end
	assert(hasCost, "paid choice: no -$" .. cost .. " chip")
	assert((chipSums(pr.result.chips).money or 0) == cred - 2000, "paid choice: the money chips don't sum to the balance change")
	table.insert(out, string.format("paid choice: $2,000 - $%d + $%d = $%d; chips -$%d and +$%d", cost, gain, cred, cost, gain))

	-- loss at $0 (and the loss tag)
	local r4 = spawnArrived("loss at $0")
	assert(career:Invoke("Set", uid, { money = 0 }) == true, "loss at $0: could not set money to 0")
	assert(wi:Invoke("SetRng", uid, { 100 }) == true, "loss at $0: SetRng failed")
	local s4 = stats()
	local lr = choose(r4.token, 3)
	local bad = CARD.choices[3].bad
	assert(lr and lr.ok == true and lr.result.key == bad.key and lr.result.tone == "loss", "loss at $0: choice 3 should land " .. bad.key .. ", got " .. tostring(lr and (lr.reason or lr.result.key)))
	local a4 = stats()
	assert(a4.aura == s4.aura + bad.aura, "loss at $0: aura should fall by " .. -bad.aura)
	assert(a4.money == 0 and p:GetAttribute("Cred") == 0, "loss at $0: Money went below or above 0")
	local kinds = {}
	for _, c in ipairs(lr.result.chips) do table.insert(kinds, c.kind) end
	assert(#kinds == 1 and kinds[1] == "aura", "loss at $0: chips should show only the aura applied, got " .. table.concat(kinds, ","))
	table.insert(out, "loss at $0: aura " .. bad.aura .. ", Money stays $0, chips: " .. lr.result.chips[1].label)
	local lt = tag()
	assert(lt and lt.Label.Text:sub(1, 1) == "-" and lt.Label.TextColor3 == Theme.accent2, "loss tag: want a '-' tag in Theme.accent2, got " .. tostring(lt and lt.Label.Text))
	table.insert(out, "loss tag: '" .. lt.Label.Text .. "' in accent2")

	-- expire
	local c5 = walkins().count
	local r5 = spawnArrived("expire")
	local s5 = stats()
	assert(walkins().count == c5 + 1, "expire: the arrival did not count")
	assert(wi:Invoke("Expire", uid) == true, "expire: Expire refused")
	assert(pending() == nil, "expire: the record is still there")
	same(s5, stats(), "expire")
	assert(walkins().count == c5 + 1, "expire: the visit should stay counted")
	assert(choose(r5.token, 1).reason == "stale", "expire: the expired token was not stale")
	table.insert(out, "expire: record gone, no stat change, visit counted, token stale")

	-- recovered aura: the drop planted at Aura 0 comes next (control) and is kept as the stored pick when he walks out
	-- before arriving; with Aura back at the sponsor's floor the next spawn skips it and the deal stays
	local sp, s6 = Content.Sponsors[1], stats()
	assert(wi:Invoke("Reset", uid) == true, "recovered drop: Reset failed") -- empties the queue (choice 1 planted navx_single)
	assert(career:Invoke("Set", uid, { sponsor = sp.id, sponsors = 1, aura = 0 }) == true, "recovered drop: Set failed")
	local r6 = spawnArrived("recovered drop")
	assert(queued("sponsor_drop"), "recovered drop: Aura 0 under " .. sp.id .. "'s floor did not queue sponsor_drop")
	assert(choose(r6.token, 0).ok == true, "recovered drop: walk away failed")
	assert(wi:Invoke("Spawn", uid) == true and pending() and pending().id == "sponsor_drop", "recovered drop: control: the drop was not the next pick at Aura 0")
	assert(wi:Invoke("Expire", uid) == true and walkins().next and walkins().next.id == "sponsor_drop", "recovered drop: the drop is not the stored pick after he walked out")
	assert(career:Invoke("Set", uid, { aura = sp.floor }) == true, "recovered drop: Set aura failed")
	assert(wi:Invoke("Spawn", uid) == true, "recovered drop: Spawn() refused at the floor")
	local r7 = pending()
	assert(r7 and r7.id ~= "sponsor_drop" and not queued("sponsor_drop"), "recovered drop: Aura at the floor still brought the drop (" .. tostring(r7 and r7.id) .. ")")
	assert(walkins().next and walkins().next.id == r7.id, "recovered drop: the new pick was not stored")
	assert(waitFor(arrived, 15), "recovered drop: he did not arrive within 15 s")
	assert(p:GetAttribute("Sponsors") == 1 and p:GetAttribute("Sponsor") ~= nil and not queued("sponsor_drop"), "recovered drop: the deal was dropped or the drop queued again")
	assert(choose(r7.token, 0).ok == true, "recovered drop: walk away failed")
	assert(career:Invoke("Set", uid, { sponsor = false, sponsors = s6.sponsors, aura = s6.aura }) == true, "recovered drop: restore failed")
	table.insert(out, "recovered drop: queued at Aura 0, stored as the next pick; at Aura " .. sp.floor .. " (" .. sp.id .. "'s floor) skipped for " .. r7.id .. ", deal kept")

	career:Invoke("Set", uid, { money = money0 })
	return "T43 PLAY OK\n" .. table.concat(out, "\n")
end

local ok, msg = pcall(run)
pcall(function() wi:Invoke("Reset", uid); wi:Invoke("Pause", uid, true) end)
pcall(teleport, LOUNGE)
if not ok then error(msg, 0) end
return msg
