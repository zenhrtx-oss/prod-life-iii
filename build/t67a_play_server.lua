-- Server, during play (two sessions Task 4; Review Focus 2, 3), before t67b: the one-hit wonder (two_sessions choice 2,
-- `ready`) through the phone hook, paused, Quiet on for the whole body. The file's own fresh() (unseated in the lounge,
-- Quiet on, WalkIns Reset, Career Reset, ResetXPCount(uid, "Phone")), then Career Set { placements 0, followers 0,
-- aura 0 }. The phone hook's ReadyChance(uid, card, index) is the chance Choose would roll now; it reads prof.level on
-- the server, never the Level attribute.
-- (1) c1 = ReadyChance(two_sessions, 2) is in 10..90 and equals WalkInRules.ChoiceChance for the stats read through the
-- Career hook with level = prof.level (GetProfile). (2) SetRng c1 + 1 (held to 100), Pop, Open, Choose 2: notready,
-- Aura -30, XP unchanged, no xp chip. (3) the Level attribute set to 10 and then to 1 on the server: ReadyChance stays c1
-- both times (one of the two always differs from prof.level's part); the attribute restored. (4) Career Set
-- { placements 12, followers 90000, aura 1500 }: c2 = ReadyChance > c1; ResetFunnelEvents, SetRng c2 (a roll at the
-- chance is good), Choose 2 on a new pop: wentoff, Aura +20, XP +10, chips exactly ["+10 XP", "+20 AURA"];
-- FunnelEvents holds exactly one CardChoice (detail "2:wentoff", value 1: a count) and, right after it, exactly one
-- CardReady (detail "wentoff", value = floor(Readiness(stats, level, Odds.ready) * 100 + 0.5) from the stats and level
-- read just before the choice). The gates (visits 10, the weekly cap) are proven in the CLI (Task 3), not here.
-- Tail for t67b, after the cleanup: Career Set { placements 0, followers 0, aura 0 }, Quiet off, the phone's next draw
-- forced to 100 (a sure miss), then two_sessions popped and opened (the DM left open for the client's choice).
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local Rules = require(RS.OK.Modules.WalkInRules)
local Content = require(RS.OK.Data.WalkIns)
local ODDS = require(RS.OK.Config).WalkIns.Odds
local LOUNGE = Vector3.new(24, 3, 0)
local CARD = "two_sessions"
local ZERO = { placements = 0, followers = 0, aura = 0 }
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
local function profile() return test:Invoke("GetProfile", uid) end
local function xp() return profile().xp end
local function stats() return career:Invoke("Get", uid) end
local function set(s, label) assert(career:Invoke("Set", uid, s) == true, label .. ": Career Set failed") end
local function chance(label)
	local c = ph:Invoke("ReadyChance", uid, CARD, 2)
	assert(type(c) == "number", label .. ": the phone hook's ReadyChance returned " .. tostring(c) .. " (before the Task 4 sync of Systems/Phone it returns nil: the expected red)")
	return c
end
-- what the server should roll at: ChoiceChance on the Career stats with level = prof.level, both read through the hooks
local function expected(choice)
	local have, level = stats(), profile().level
	have.level = level
	return Rules.ChoiceChance(choice, have, ODDS), have, level
end
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
-- the file's own fresh(): unseated and in the lounge, Quiet on, WalkIns and Career reset, the Phone XP count cleared
local function fresh(label)
	local c = p.Character; local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum and hum.Sit then hum.Sit = false; task.wait(0.4) end
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, label .. ": Quiet(true) failed")
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	assert(test:Invoke("ResetXPCount", uid, "Phone") == true, label .. ": _StudioTestHook ResetXPCount(uid, \"Phone\") did not return true"
		.. " (before the Task 4 sync of OK/Main it returns nil: the expected red)")
	assert(#ph:Invoke("Pending", uid) == 0 and p:GetAttribute("PhoneBusy") == nil, label .. ": pops or PhoneBusy left after the WalkIns Reset")
end
-- Pop, Open, Choose 2 on two_sessions with the phone's next draw forced to `roll`; returns the result
local function pickWonder(label, roll)
	assert(ph:Invoke("SetRng", uid, { roll }) == true, label .. ": SetRng failed")
	local t = ph:Invoke("Pop", uid, CARD)
	assert(type(t) == "string", label .. ": Pop(" .. CARD .. ") sent nothing")
	assert(ph:Invoke("Open", uid, t) == true and p:GetAttribute("PhoneBusy") == true, label .. ": the DM did not open (PhoneBusy not set)")
	return t
end
local function choose(label, t)
	local r = ph:Invoke("Choose", uid, t, 2)
	assert(r and r.ok == true and r.result, label .. ": Choose 2 refused: " .. tostring(r and r.reason))
	assert(#ph:Invoke("Pending", uid) == 0 and p:GetAttribute("PhoneBusy") == nil, label .. ": the DM is still pending or PhoneBusy after the choice")
	return r.result
end

local levelAttr -- the Level attribute before step 3, restored in the body and again in the cleanup
local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh("one-hit wonder")
	set(ZERO, "zero")
	local choice = Content.CardById[CARD] and Content.CardById[CARD].choices[2]
	assert(choice and choice.ready == true and choice.good.key == "wentoff" and choice.bad.key == "notready", CARD .. "'s choice 2 is not the ready wentoff / notready choice")

	-- 1: the hook's chance is the server's: ChoiceChance at prof.level
	local c1 = chance("c1")
	local want1, _, level1 = expected(choice)
	assert(c1 >= ODDS.min and c1 <= ODDS.max, "c1: " .. c1 .. " is outside " .. ODDS.min .. ".." .. ODDS.max)
	assert(c1 == want1, string.format("c1: ReadyChance %d, want ChoiceChance %d at prof.level %d with no placements, followers or Aura", c1, want1, level1))
	table.insert(out, string.format("c1: ReadyChance %d = ChoiceChance at prof.level %d, stats 0", c1, level1))

	-- 2: a roll just over the chance misses: notready, Aura -30, no XP
	local a0, x0 = stats().aura, xp()
	local miss = math.min(c1 + 1, 100)
	local r2 = choose("miss", pickWonder("miss", miss))
	assert(r2.key == "notready", "miss: a roll of " .. miss .. " over chance " .. c1 .. " should land notready, landed " .. tostring(r2.key))
	assert(stats().aura - a0 == -30, "miss: Aura should fall by 30, moved " .. (stats().aura - a0))
	assert(xp() == x0, "miss: XP moved " .. x0 .. " -> " .. xp())
	assert(xpChip(r2.chips) == nil and hasChip(r2.chips, "-30 AURA"), "miss: want the chip -30 AURA and no xp chip, got " .. labels(r2.chips))
	table.insert(out, string.format("miss: SetRng %d -> notready, Aura -30, XP unchanged, chips %s", miss, labels(r2.chips)))

	-- 3: the Level attribute is not the server's level: 10 and 1 both leave ReadyChance at c1
	levelAttr = p:GetAttribute("Level")
	for _, lv in ipairs({ 10, 1 }) do
		p:SetAttribute("Level", lv)
		local c = chance("Level " .. lv)
		assert(c == c1, string.format("Level %d: the Level attribute moved ReadyChance %d -> %d (it must read prof.level %d)", lv, c1, c, level1))
	end
	p:SetAttribute("Level", levelAttr)
	assert(p:GetAttribute("Level") == levelAttr, "the Level attribute was not restored")
	table.insert(out, "Level attribute 10, then 1: ReadyChance stays " .. c1 .. "; restored to " .. tostring(levelAttr))

	-- 4: a ready career has a higher chance; a roll at the chance lands wentoff, pays XP 10, counts one CardChoice and
	-- logs the readiness as its own CardReady
	set({ placements = 12, followers = 90000, aura = 1500 }, "ready")
	local c2 = chance("c2")
	local want2, have2, level2 = expected(choice)
	assert(c2 == want2 and c2 > c1, string.format("c2: ReadyChance %d should equal ChoiceChance %d and beat c1 %d", c2, want2, c1))
	local value = math.floor(Rules.Readiness(have2, level2, ODDS.ready) * 100 + 0.5)
	local t4 = pickWonder("hit", c2)
	assert(test:Invoke("ResetFunnelEvents", uid) == true, "hit: ResetFunnelEvents failed")
	local a4, x4 = stats().aura, xp()
	local r4 = choose("hit", t4)
	assert(r4.key == "wentoff", "hit: a roll of " .. c2 .. " at chance " .. c2 .. " should land wentoff, landed " .. tostring(r4.key))
	assert(stats().aura - a4 == 20, "hit: Aura should rise by 20, moved " .. (stats().aura - a4))
	assert(xp() - x4 == 10, "hit: XP should rise by 10, rose by " .. (xp() - x4))
	assert(labels(r4.chips) == "[+10 XP, +20 AURA]", "hit: want exactly the chips [+10 XP, +20 AURA] in that order, got " .. labels(r4.chips))
	local events = test:Invoke("FunnelEvents", uid)
	local choices, readies, at = {}, {}, {}
	for i, e in ipairs(events) do
		if e.name == "CardChoice" then table.insert(choices, e); at.choice = i end
		if e.name == "CardReady" then table.insert(readies, e); at.ready = i end
	end
	assert(#choices == 1, "hit: want exactly one CardChoice event, got " .. #choices)
	local ev = choices[1]
	assert(ev.fields and ev.fields.source == "phone" and ev.fields.card == CARD and ev.fields.detail == "2:wentoff",
		"hit: the CardChoice fields should be phone / " .. CARD .. " / 2:wentoff, are " .. tostring(ev.fields and ev.fields.detail))
	assert(ev.value == 1, "hit: the CardChoice value should be 1 (a count; the readiness is CardReady's), is " .. tostring(ev.value))
	assert(#readies == 1, "hit: want exactly one CardReady event, got " .. #readies .. " (before the Task H sync of Systems/Phone: none, the expected red)")
	local rv = readies[1]
	assert(rv.fields and rv.fields.source == "phone" and rv.fields.card == CARD and rv.fields.detail == "wentoff",
		"hit: the CardReady fields should be phone / " .. CARD .. " / wentoff, are " .. tostring(rv.fields and rv.fields.source) .. " / "
		.. tostring(rv.fields and rv.fields.card) .. " / " .. tostring(rv.fields and rv.fields.detail))
	assert(rv.value == value, string.format("hit: the CardReady value should be the readiness x 100 (%d), is %s", value, tostring(rv.value)))
	assert(at.ready == at.choice + 1, string.format("hit: CardReady should come right after CardChoice (events %s and %s)",
		tostring(at.choice), tostring(at.ready)))
	table.insert(out, string.format("hit: c2 %d > c1 %d; SetRng %d -> wentoff, Aura +20, XP +10, chips %s; CardChoice value 1, then CardReady value %d",
		c2, c1, c2, labels(r4.chips), value))

	return "T67A PLAY OK\n" .. table.concat(out, "\n")
end

local ok, msg = pcall(run)
pcall(function()
	if levelAttr ~= nil then p:SetAttribute("Level", levelAttr) end
	wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); ph:Invoke("Quiet", uid, false)
end)
pcall(teleport, LOUNGE)
if not ok then error(msg, 0) end
-- staging for t67b, after the cleanup (its WalkIns Reset ran the phone's reset: no pop, no SetRng list): an unready
-- career, Quiet off, the phone's next draw 100 (choice 2's roll misses at any chance), then two_sessions popped and
-- opened, the DM left open
set(ZERO, "tail")
assert(ph:Invoke("Quiet", uid, false) == true, "tail: Quiet(false) failed")
assert(ph:Invoke("SetRng", uid, { 100 }) == true, "tail: SetRng failed")
local tail = ph:Invoke("Pop", uid, CARD)
assert(type(tail) == "string", "tail: Pop(" .. CARD .. ") sent nothing")
assert(ph:Invoke("Open", uid, tail) == true and p:GetAttribute("PhoneBusy") == true, "tail: the DM did not open")
return msg
