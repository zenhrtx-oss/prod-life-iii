-- Server, during play (Wave 1b Task 5; Review Focus 6), before t64b: a walk-in win with every sound. The file's own
-- fresh() (unseated in the lounge, Quiet on, WalkIns and Career reset), paused, and the card t64b needs checked:
-- scoot_session's choice 3 ("Rent extra synths and build all five.") costs $300 and rolls at odds 30 with no rare, and
-- its good outcome is a win that pays money and plants a follow-up (paid: +$500, +600 FOLLOWERS, scoot_refund). Staging
-- for t64b, after the cleanup (its WalkIns Reset clears the SetRng list and sends a visitor home): money $300 (the cost,
-- so the client lets the choice through), the player at the studio PC spot (72, 3.5, -5.5), the next walk-in draw
-- forced to 1 (choice 3 rolls good: the plant's own draw is random), then scoot_session spawned. He walks the control
-- room route (about 9 s), so t64b starts before his card opens and can count its riser.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local Content = require(RS.OK.Data.WalkIns)
local LOUNGE, PC = Vector3.new(24, 3, 0), Vector3.new(72, 3.5, -5.5)
local CARD, PICK, COST = "scoot_session", 3, 300

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
-- the file's own fresh(): unseated and in the lounge, Quiet on, WalkIns and Career reset
local function fresh(label)
	local c = p.Character; local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum and hum.Sit then hum.Sit = false; task.wait(0.4) end
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, label .. ": Quiet(true) failed")
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
end

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh("win")
	local card = Content.CardById[CARD]
	local c = card and card.source ~= "phone" and card.choices and card.choices[PICK]
	local good = c and c.good
	assert(c and not c.sure and not c.rare and c.cost == COST and (c.odds or 0) < 100 and good and good.tone == "win"
		and (good.money or 0) > 0 and type(good.plant) == "table" and Content.FollowupById[good.plant.id] ~= nil,
		CARD .. "'s choice " .. PICK .. " is not a $" .. COST .. " rolled walk-in choice whose good outcome is a win that pays money and plants a follow-up")
	assert(wi:Invoke("Pending", uid) == nil, "a visit is still in flight after the WalkIns Reset")
	return string.format("T64A PLAY OK: paused, reset, player at (24, 3, 0); %s choice %d good = %s (+$%d, plants %s, win); staged money $%d,"
		.. " the player at the studio PC, SetRng {1}, %s spawned for t64b", CARD, PICK, good.key, good.money, good.plant.id, COST, CARD)
end

local ok, msg = pcall(run)
pcall(function() wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); ph:Invoke("Quiet", uid, false) end)
pcall(teleport, LOUNGE)
if not ok then error(msg, 0) end
-- staging for t64b, after the cleanup: the cost in hand, the player at the studio PC, the roll forced good, then him
assert(career:Invoke("Set", uid, { money = COST }) == true, "tail: Career Set money " .. COST .. " failed")
assert(p:GetAttribute("Cred") == COST, "tail: Cred is " .. tostring(p:GetAttribute("Cred")) .. " after Set money " .. COST)
teleport(PC)
assert(wi:Invoke("SetRng", uid, { 1 }) == true, "tail: SetRng failed")
assert(wi:Invoke("Spawn", uid, CARD) == true, "tail: Spawn(" .. CARD .. ") refused (is the player in the hub?)")
local pend = wi:Invoke("Pending", uid)
assert(pend and pend.id == CARD and not pend.arrived, "tail: no visit walking in for " .. CARD .. " (" .. tostring(pend and pend.id) .. ")")
return msg
