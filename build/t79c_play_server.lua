-- Server, during play (Wave 3 Task 5, fix round 1; design 4.3): the relationship tilt on a rolled choice, forced to the
-- roll's boundary, on a walk-in card (B, review F1) and on a phone DM (D, the controller's 11-06 ruling: a DM from LIL NAV
-- X is his card). The file's own fresh() (unseated in the lounge, Quiet on, the phone's pops dropped, WalkIns Reset,
-- Career Reset, Life Reset, _StudioTestHook ResetHints, and SetRecent({}): no recent beat). The body runs held
-- (WalkInsPaused true). Every chance is computed here from the live rules and Config (WalkInRules.RollChance with
-- WalkInRules.RelTilt on Config.WalkIns.Odds) on the career Career Get returns right after a Career Reset, never typed
-- in; each roll is forced through its own system's SetRng list (the walk-in hook's for a walk-in, the phone hook's for a
-- DM). For each of LIL NAV X's scores +2, -2 and 0 (SetRel right before each roll; at 0 the entry is there), a roll at T
-- (the chance with RelTilt of that score) lands good and a roll at T + 1 lands bad. At +2, T is over the untilted chance
-- U, so it lands good only with the tilt (a server that drops it, flips its sign or reads another visitor's score lands
-- it bad); at -2, T + 1 is at or under U, so it lands bad only with the tilt; at 0, T is U.
-- (B) navx_placement's choice 3 ("Post that he's in your studio. Clout first.": rolled, no beat, no rare, no cost, so the
--     relationship's is its only tilt), each roll on a fresh arrival (this card's own outcomes move his score). The
--     walk-in tilt is already live: B passes before and after the fix round's sync.
-- (D) dm_navx's choice 2 ("Send three and let him pick.": rolled, no rare, no cost), each roll on a fresh pop (Pop, Open,
--     Choose through the phone hook). Before the fix round's sync of Systems/Phone a phone choice rolls untilted, so at +2
--     the roll at T lands bad: the expected red.
-- Everything is reset after the body (hold true, WalkIns, the phone, Career, Life, hints and recent beats, Quiet off), and
-- an error is rethrown.
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
local CARD, CARD_CHOICE = "navx_placement", 3
local DM, DM_CHOICE = "dm_navx", 2
local SCORES = { 2, -2, 0 }
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
-- LIL NAV X's relationship set to `score` (the entry there, no flags); checked through what SetRel kept
local function setScore(score, label)
	local kept = wi:Invoke("SetRel", uid, { navx = { score = score } })
	assert(type(kept) == "table" and type(kept.navx) == "table" and kept.navx.score == score,
		label .. ": SetRel({ navx " .. score .. " }) kept " .. (type(kept) == "table" and tostring(kept.navx and kept.navx.score) or typeof(kept)))
end
-- the file's own fresh(): unseated and in the lounge, Quiet on, no pops, WalkIns, Career and Life reset, no hint seen, no
-- recent beat
local function fresh(label)
	local c = p.Character; local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum and hum.Sit then hum.Sit = false; task.wait(0.4) end
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, label .. ": Quiet(true) failed")
	assert(ph:Invoke("Reset", uid) == true, label .. ": phone Reset failed")
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	assert(life:Invoke("Reset", uid) == true, label .. ": Life Reset failed")
	assert(test:Invoke("ResetHints", uid) == true, label .. ": ResetHints failed")
	assert(type(test:Invoke("SetRecent", uid, {})) == "table", label .. ": SetRecent({}) failed")
end
-- the chance a roll of `choice` lands good at now, with the relationship tilt of `score` (T) and with none (U), on the
-- career Career Get returns (the caller has just reset it)
local function chances(choice, score)
	local have = career:Invoke("Get", uid)
	return Rules.RollChance(choice, have, W.Odds, Rules.RelTilt(score, W.Odds)), Rules.RollChance(choice, have, W.Odds, 0)
end
-- T and U where the two rolls tell the tilt apart: over U at a positive score, T + 1 at or under U at a negative one, T = U
-- at 0
local function boundary(T, U, score, label)
	if score > 0 then
		assert(T > U, string.format("%s: the tilted chance %s is not over the untilted %s (relPer %s)", label, tostring(T), tostring(U), tostring(W.Odds.relPer)))
	elseif score < 0 then
		assert(T + 1 <= U, string.format("%s: the tilted chance %s + 1 is over the untilted %s (relPer %s)", label, tostring(T), tostring(U), tostring(W.Odds.relPer)))
	else
		assert(T == U, string.format("%s: at score 0 the chance %s is not the untilted %s", label, tostring(T), tostring(U)))
	end
end
local function plainRolled(choice, where)
	assert(type(choice) == "table" and not choice.beat and not choice.beatMin and not choice.sure and not choice.ready and not choice.rare
		and (choice.cost or 0) == 0, where .. " should be a free plain rolled choice (no beat, beatMin, sure, ready, rare or cost)")
	return choice
end

-- B: navx_placement walked in, Career Reset, choice CARD_CHOICE rolled at T + offset through the walk-in hook. Returns the
-- result's key, T and U
local function walkRoll(choice, score, offset, label)
	setScore(score, label)
	wi:Invoke("Sent", uid) -- drained
	assert(wi:Invoke("Spawn", uid, CARD) == true, label .. ": Spawn(" .. CARD .. ") refused")
	assert(waitFor(arrived, 15), label .. ": " .. CARD .. " did not arrive within 15 s")
	local r = pending()
	assert(r and r.id == CARD, label .. ": the open card is " .. tostring(r and r.id))
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	local T, U = chances(choice, score)
	boundary(T, U, score, label)
	assert(wi:Invoke("SetRng", uid, { T + offset }) == true, label .. ": SetRng failed")
	local res = wi:Invoke("Choose", uid, r.token, CARD_CHOICE)
	assert(res and res.ok == true and type(res.result) == "table", label .. ": Choose " .. CARD_CHOICE .. " refused: " .. tostring(res and res.reason))
	return res.result.key, T, U
end
-- D: dm_navx popped and opened, Career Reset, choice DM_CHOICE rolled at T + offset through the phone hook. Returns the
-- result's key, T and U
local function phoneRoll(choice, score, offset, label)
	setScore(score, label)
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	local token = ph:Invoke("Pop", uid, DM)
	assert(type(token) == "string", label .. ": Pop(" .. DM .. ") sent nothing")
	assert(ph:Invoke("Open", uid, token) == true, label .. ": Open failed")
	local T, U = chances(choice, score)
	boundary(T, U, score, label)
	assert(ph:Invoke("SetRng", uid, { T + offset }) == true, label .. ": phone SetRng failed")
	local res = ph:Invoke("Choose", uid, token, DM_CHOICE)
	assert(res and res.ok == true and type(res.result) == "table", label .. ": phone Choose " .. DM_CHOICE .. " refused: " .. tostring(res and res.reason))
	return res.result.key, T, U
end
-- both rolls at each score: T lands good, T + 1 lands bad
local function boundaries(name, choice, roll)
	for _, score in ipairs(SCORES) do
		local label = string.format("%s, navx at %+d", name, score)
		local kT, T, U = roll(choice, score, 0, label .. ", roll T")
		assert(kT == choice.good.key, string.format("%s: the roll at T = %s (untilted %s) landed %s, want %s (good)%s", label, tostring(T), tostring(U),
			tostring(kT), tostring(choice.good.key), score > 0 and ": the relationship tilt was not added" or ""))
		local kT1 = roll(choice, score, 1, label .. ", roll T + 1")
		assert(kT1 == choice.bad.key, string.format("%s: the roll at T + 1 = %s (untilted %s) landed %s, want %s (bad)%s", label, tostring(T + 1), tostring(U),
			tostring(kT1), tostring(choice.bad.key), score < 0 and ": the relationship tilt was not taken off" or ""))
		table.insert(out, string.format("%s: untilted %s, tilted %s; roll %s -> %s, roll %s -> %s", label, tostring(U), tostring(T), tostring(T), kT,
			tostring(T + 1), kT1))
	end
end

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	local walkChoice = plainRolled(Content.CardById[CARD].choices[CARD_CHOICE], CARD .. " choice " .. CARD_CHOICE)
	local dmChoice = plainRolled(Content.CardById[DM].choices[DM_CHOICE], DM .. " choice " .. DM_CHOICE)
	fresh("walk-in")
	boundaries("B walk-in " .. CARD .. " choice " .. CARD_CHOICE, walkChoice, walkRoll)
	fresh("phone")
	boundaries("D phone " .. DM .. " choice " .. DM_CHOICE, dmChoice, phoneRoll)
end

local ok, msg = pcall(run)
pcall(function()
	wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
	test:Invoke("ResetHints", uid); test:Invoke("SetRecent", uid, {}); ph:Invoke("Quiet", uid, false)
end)
if not ok then pcall(teleport, LOUNGE); error(msg, 0) end
return "T79C PLAY OK\n" .. table.concat(out, "\n") .. string.format("\nelapsed %.1f s", os.clock() - T0)
