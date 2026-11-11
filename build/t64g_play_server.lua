-- Server, during play (Wave 1b Task 5; Review Focus 1), before t64h: a death in the middle of the loss reaction. The
-- file's own fresh() (unseated in the lounge, Quiet on, WalkIns and Career reset), paused, and the card t64h needs
-- checked: rookie_block's choice 3 is a sure, free loss that moves only Aura (cold: -5 AURA, no money, no plant), and
-- the respawn is automatic (Players.CharacterAutoLoads; t64h waits RespawnTime + 4 s for the new character). Staging
-- for t64h, after the cleanup (its WalkIns Reset would send him home): rookie_block spawned; he walks to the player in
-- the lounge.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local Content = require(RS.OK.Data.WalkIns)
local LOUNGE = Vector3.new(24, 3, 0)
local CARD, PICK = "rookie_block", 3

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
	fresh("death")
	local card = Content.CardById[CARD]
	local c = card and card.source ~= "phone" and card.choices and card.choices[PICK]
	local o = c and c.good
	assert(c and c.sure and (c.cost or 0) == 0 and o and o.tone == "loss" and (o.aura or 0) < 0 and (o.money or 0) == 0 and not o.plant,
		CARD .. "'s choice " .. PICK .. " is not a sure, free walk-in loss of Aura with no money and no plant")
	assert(Players.CharacterAutoLoads, "Players.CharacterAutoLoads is off: t64h's death would leave no character")
	assert(wi:Invoke("Pending", uid) == nil, "a visit is still in flight after the WalkIns Reset")
	return string.format("T64G PLAY OK: paused, reset, player at (24, 3, 0); %s choice %d = %s (%+d AURA, sure loss); RespawnTime %s;"
		.. " %s spawned for t64h", CARD, PICK, o.key, o.aura, tostring(Players.RespawnTime), CARD)
end

local ok, msg = pcall(run)
pcall(function() wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); ph:Invoke("Quiet", uid, false) end)
pcall(teleport, LOUNGE)
if not ok then error(msg, 0) end
-- staging for t64h, after the cleanup: him, walking in
assert(wi:Invoke("Spawn", uid, CARD) == true, "tail: Spawn(" .. CARD .. ") refused (is the player in the hub?)")
local pend = wi:Invoke("Pending", uid)
assert(pend and pend.id == CARD, "tail: no visit walking in for " .. CARD .. " (" .. tostring(pend and pend.id) .. ")")
return msg
