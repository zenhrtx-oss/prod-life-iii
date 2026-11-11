-- Server, during play (Wave 3 Task 3; design 4.1; Review Focus 1), after t77b: the card without a beat, for t77d. It
-- stands alone (fix round 1): its own fresh() (unseated in the lounge, Quiet on, WalkIns Reset, Career Reset, Life
-- Reset, _StudioTestHook ResetHints) and its own beat, so `--play t77c` runs by itself. (1) With a 3-star beat seeded
-- here (SetRecent), scoot_session, a card no choice of which goes by your beat: its arrive payload has no beat at all
-- (nil); walked away. (2) SetRecent({}): no recent beat, BestBeat nil. (3) navx_placement spawned: its payload has beat =
-- false and its line reads "something"; left open for t77d. Quiet goes back off at the end. On any error everything is
-- reset (hold true, WalkIns, Career, Life, hints and recent beats, Quiet off, back in the lounge) and the error rethrown.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook")
local Config = require(RS.OK.Config)
local Rules = require(RS.OK.Modules.WalkInRules)
local Content = require(RS.OK.Data.WalkIns)
local W = Config.WalkIns
local LOUNGE = Vector3.new(24, 3, 0)
local CARD, PLAIN = "navx_placement", "scoot_session"
local BEAT = string.rep("0", 120) .. string.rep("7", 8) -- only stored, never aired
local out = {}

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function teleport(pos) -- server-side; checked, and tried once more if the client's position won
	for _ = 1, 2 do
		local c = p.Character or p.CharacterAdded:Wait()
		c:WaitForChild("HumanoidRootPart", 5)
		c:PivotTo(CFrame.new(pos))
		task.wait(0.3)
		local r = c:FindFirstChild("HumanoidRootPart")
		if r and flat(r.Position - pos) < 2 then return r end
	end
	error("teleport to " .. tostring(pos) .. " did not take")
end
local function pending() return wi:Invoke("Pending", uid) end
local function arrived() local r = pending(); return r ~= nil and r.arrived == true end
local function lastArrive()
	local got
	for _, e in ipairs(wi:Invoke("Sent", uid)) do if e.kind == "arrive" then got = e.payload end end
	return got
end
local function spawnArrived(label, id)
	wi:Invoke("Sent", uid)
	assert(wi:Invoke("Spawn", uid, id) == true, label .. ": Spawn(" .. id .. ") refused (a visit still in flight?)")
	assert(waitFor(arrived, 15), label .. ": he did not arrive within 15 s")
	local a = lastArrive()
	assert(type(a) == "table" and type(a.card) == "table" and a.card.id == id, label .. ": no arrive payload for " .. id)
	return pending(), a.card
end
-- the file's own fresh(): unseated and in the lounge, Quiet on, WalkIns, Career and Life reset, no hint seen
local function fresh(label)
	local c = p.Character; local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum and hum.Sit then hum.Sit = false; task.wait(0.4) end
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, label .. ": Quiet(true) failed")
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	assert(life:Invoke("Reset", uid) == true, label .. ": Life Reset failed")
	assert(test:Invoke("ResetHints", uid) == true, label .. ": ResetHints failed")
end

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh("plain")
	-- 1. a card your beat decides nothing on: no beat in its payload, even with a beat in the list (seeded here)
	for _, ch in ipairs(Content.CardById[PLAIN].choices) do assert(not (ch.beat or ch.beatMin), PLAIN .. " has a beat choice: pick another plain card") end
	local seeded = test:Invoke("SetRecent", uid, { { pattern = BEAT, bpm = 150, stars = 3, fires = 0, day = 1 } })
	assert(type(seeded) == "table" and #seeded == 1 and seeded[1].stars == 3, "plain: SetRecent did not keep the seeded 3-star beat (before the Task 3 sync of OK/Main it returns nil)")
	local r1, c1 = spawnArrived("plain", PLAIN)
	assert(c1.beat == nil, "plain: " .. PLAIN .. "'s payload carries beat " .. tostring(c1.beat) .. ", want none")
	assert(wi:Invoke("Choose", uid, r1.token, 0).ok == true, "plain: walk away failed")
	table.insert(out, "1 " .. PLAIN .. " (no beat choice): payload beat nil with a 3-star beat in Recent")
	-- 2. no beat
	local kept = test:Invoke("SetRecent", uid, {})
	assert(type(kept) == "table" and #kept == 0 and test:Invoke("BestBeat", uid) == nil, "no beat: SetRecent({}) left a beat")
	-- 3. navx_placement with no beat, left open for t77d
	local r3, c3 = spawnArrived("no beat", CARD)
	assert(c3.beat == false, "no beat: the payload's beat is " .. tostring(c3.beat) .. ", want false")
	local want = Rules.Fill(Content.CardById[CARD].line, Content.Names(W.Roster), nil, nil)
	assert(c3.line == want and string.find(c3.line, "something", 1, true), "no beat: the line reads '" .. tostring(c3.line) .. "', want '" .. want .. "'")
	assert(r3 and r3.arrived, "no beat: no arrived visit left for t77d")
	table.insert(out, "3 " .. CARD .. " with no beat: payload beat false, line '" .. c3.line .. "', open for t77d")
	assert(ph:Invoke("Quiet", uid, false) == true, "Quiet(false) failed")
end

local ok, err = pcall(run)
if not ok then
	pcall(function()
		wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
		test:Invoke("ResetHints", uid); test:Invoke("SetRecent", uid, {}); ph:Invoke("Quiet", uid, false)
	end)
	pcall(teleport, LOUNGE)
	error(err, 0)
end
return "T77C PLAY OK\n" .. table.concat(out, "\n")
