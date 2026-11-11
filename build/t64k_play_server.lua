-- Server, during play (Wave 1b Task 5; Review Focus 1), before t64l: a result that lands just after the beat maker
-- closes. The file's own fresh() (unseated in the lounge, Quiet on, WalkIns and Career reset), paused, and the cards
-- t64l needs checked: navx_single, a walk-in follow-up with choices whose news rolls at odds under 100 with a loss that
-- plants nothing and pays no money (flop: -15 AURA, +200 FOLLOWERS); dm_dojabat, a phone DM. Staging for t64l, after
-- the cleanup (its WalkIns Reset would clear the SetRng list, send him home and drop the pop), in t57e's order: Quiet
-- off, dm_dojabat popped (the client opens it at once), the next walk-in draw forced to 100 (his news rolls bad: flop),
-- then navx_single spawned. He reaches the lounge in about 3 s, applies his news on arrival and waits behind the open
-- DM, so his card can't show before t64l has opened the beat maker over it (a visitor spawned for the studio PC would
-- race the client's prompt).
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local Content = require(RS.OK.Data.WalkIns)
local LOUNGE = Vector3.new(24, 3, 0)
local FOLLOW, DM = "navx_single", "dm_dojabat"

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
	fresh("after the beat maker")
	local f, dm = Content.FollowupById[FOLLOW], Content.CardById[DM]
	local r = f and f.source ~= "phone" and f.resolve
	local bad = r and r.bad
	assert(r and (r.odds or 0) < 100 and bad and bad.tone == "loss" and tostring(bad.headline or "") ~= "" and not bad.plant
		and (bad.money or 0) <= 0 and #(f.choices or {}) > 0,
		FOLLOW .. " is not a walk-in follow-up with choices whose news can roll a loss that plants nothing and pays no money")
	assert(dm and dm.source == "phone" and not dm.news, DM .. " is not a phone DM")
	assert(wi:Invoke("Pending", uid) == nil and #ph:Invoke("Pending", uid) == 0 and p:GetAttribute("PhoneBusy") == nil,
		"a visit, a pop or PhoneBusy is left after the WalkIns Reset")
	return string.format("T64K PLAY OK: paused, reset, player at (24, 3, 0); %s's bad news = %s (%s, %+d AURA, no plant); %s a phone DM;"
		.. " staged Quiet off, %s popped, SetRng {100}, %s spawned for t64l", FOLLOW, bad.key, bad.headline, bad.aura or 0, DM, DM, FOLLOW)
end

local ok, msg = pcall(run)
pcall(function() wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); ph:Invoke("Quiet", uid, false) end)
pcall(teleport, LOUNGE)
if not ok then error(msg, 0) end
-- staging for t64l, after the cleanup: the DM first (it opens at once and holds his card), then the bad roll, then him
assert(ph:Invoke("Quiet", uid, false) == true, "tail: Quiet(false) failed")
assert(type(ph:Invoke("Pop", uid, DM)) == "string", "tail: Pop(" .. DM .. ") sent nothing")
assert(wi:Invoke("SetRng", uid, { 100 }) == true, "tail: SetRng failed")
assert(wi:Invoke("Spawn", uid, FOLLOW) == true, "tail: Spawn(" .. FOLLOW .. ") refused (is the player in the hub?)")
local pend = wi:Invoke("Pending", uid)
assert(pend and pend.id == FOLLOW and not pend.arrived, "tail: no visit walking in for " .. FOLLOW .. " (" .. tostring(pend and pend.id) .. ")")
return msg
