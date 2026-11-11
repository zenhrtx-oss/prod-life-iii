-- Server, during play (Wave 1b Task 5; Review Focus 5), before t63b: the footer by Aura band. The file's own fresh()
-- (unseated in the lounge, Quiet on, WalkIns and Career reset: Aura 0), paused, and the card t63b needs checked:
-- scam_curator, a phone DM whose first choice "Pay the fee." costs $200. Staging for t63b, after the cleanup (its
-- WalkIns Reset would drop the pop): money 0 (Career Set { money = 0 }, so the fee is refused on the client with the
-- can't-afford note), Quiet off, then scam_curator popped, so the client opens it by itself. Money stays 0 after this
-- file: a later file that needs money sets its own.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local Content = require(RS.OK.Data.WalkIns)
local LOUNGE = Vector3.new(24, 3, 0)
local DM, FEE = "scam_curator", 200

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
	fresh("footer")
	local card = Content.CardById[DM]
	local pay = card and card.choices and card.choices[1]
	assert(card and card.source == "phone" and not card.news and pay and pay.text == "Pay the fee." and pay.cost == FEE,
		DM .. " is not a phone DM whose first choice 'Pay the fee.' costs $" .. FEE)
	assert(career:Invoke("Get", uid).aura == 0, "Aura is " .. tostring(career:Invoke("Get", uid).aura) .. " after Career Reset, want 0")
	return "T63A PLAY OK: paused, reset (Aura 0), player at (24, 3, 0); " .. DM .. "'s 'Pay the fee.' costs $" .. FEE
		.. "; staged money 0, Quiet off, " .. DM .. " popped for t63b"
end

local ok, msg = pcall(run)
pcall(function() wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); ph:Invoke("Quiet", uid, false) end)
pcall(teleport, LOUNGE)
if not ok then error(msg, 0) end
-- staging for t63b, after the cleanup: no money (the fee is refused with the can't-afford note), then the DM popped
-- with Quiet off
assert(career:Invoke("Set", uid, { money = 0 }) == true, "tail: Career Set money 0 failed")
assert(p:GetAttribute("Cred") == 0, "tail: Cred is " .. tostring(p:GetAttribute("Cred")) .. " after Set money 0")
assert(ph:Invoke("Quiet", uid, false) == true, "tail: Quiet(false) failed")
assert(type(ph:Invoke("Pop", uid, DM)) == "string", "tail: Pop(" .. DM .. ") sent nothing")
return msg
