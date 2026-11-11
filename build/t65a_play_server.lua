-- Server, during play (Wave 1b Task 5; Review Focus 6), before t65b: phone sounds and the phone's avatar reaction. The
-- file's own fresh() (unseated in the lounge, Quiet on, WalkIns and Career reset), paused, and the three cards checked:
-- dm_navx's choice 2 ("Send three and let him pick.") rolls at odds 50 with no rare, and its bad outcome is a loss of
-- Aura (toomany, -5 AURA, nothing planted); news_spedup is a NEWS with one sure win; (Task H) mishap_monitor's choice 3
-- ("Borrow one from the rival.") is a sure, free, neutral outcome with no money that plants a follow-up (borrowed,
-- mishap_owe), so its result plays only Plant. Staging for t65b, after the cleanup (the WalkIns Reset runs the phone's
-- reset, which drops pops and clears the SetRng list): Quiet off, the phone's next draw forced to 100 (choice 2 rolls
-- bad), then dm_navx popped; once the client has opened it by itself (the phone holds MaxWaiting = 2 un-opened pops),
-- news_spedup and mishap_monitor popped in that order. The client buzzes three times, opens the DM and holds the
-- other two behind it.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local Content = require(RS.OK.Data.WalkIns)
local LOUNGE = Vector3.new(24, 3, 0)
local DM, NEWS, MISHAP = "dm_navx", "news_spedup", "mishap_monitor"

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
	fresh("phone sounds")
	local dm, news = Content.CardById[DM], Content.CardById[NEWS]
	local c2 = dm and dm.source == "phone" and not dm.news and dm.choices and dm.choices[2]
	assert(c2 and not c2.sure and not c2.rare and (c2.cost or 0) == 0 and c2.bad and c2.bad.tone == "loss" and (c2.bad.aura or 0) < 0
		and not c2.bad.plant, DM .. "'s choice 2 is not a free rolled choice whose bad outcome is an Aura loss with no plant")
	assert(news and news.source == "phone" and news.news == true and news.choices[1].sure and news.choices[1].good.tone == "win",
		NEWS .. " is not a phone NEWS with one sure win")
	local mishap = Content.CardById[MISHAP]
	local c3 = mishap and mishap.source == "phone" and not mishap.news and mishap.choices and mishap.choices[3]
	local o3 = c3 and c3.good
	assert(c3 and c3.sure and (c3.cost or 0) == 0 and o3 and o3.tone == "neutral" and (o3.money or 0) == 0 and type(o3.plant) == "table",
		MISHAP .. "'s choice 3 is not a sure, free, neutral phone outcome with no money that plants a follow-up")
	assert(#ph:Invoke("Pending", uid) == 0 and p:GetAttribute("PhoneBusy") == nil, "pops or PhoneBusy left after the WalkIns Reset")
	return string.format("T65A PLAY OK: paused, reset, player at (24, 3, 0); %s choice 2 bad = %s (%+d AURA, loss), %s a sure win;"
		.. " %s choice 3 = %s (neutral, plants %s); staged Quiet off, SetRng {100}, %s popped and opened, then %s and %s popped for t65b",
		DM, c2.bad.key, c2.bad.aura, NEWS, MISHAP, o3.key, tostring(o3.plant.id), DM, NEWS, MISHAP)
end

local ok, msg = pcall(run)
pcall(function() wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); ph:Invoke("Quiet", uid, false) end)
pcall(teleport, LOUNGE)
if not ok then error(msg, 0) end
-- staging for t65b, after the cleanup: the next phone draw is 100 (choice 2's roll: bad), then the DM; once the client
-- has opened it (MaxWaiting = 2 un-opened pops: a third would be refused), the NEWS and the mishap
assert(ph:Invoke("Quiet", uid, false) == true, "tail: Quiet(false) failed")
assert(ph:Invoke("SetRng", uid, { 100 }) == true, "tail: SetRng failed")
assert(type(ph:Invoke("Pop", uid, DM)) == "string", "tail: Pop(" .. DM .. ") sent nothing")
local function dmOpened()
	for _, e in ipairs(ph:Invoke("Pending", uid) or {}) do if e.id == DM then return e.opened == true end end
	return false
end
local t1 = os.clock()
while not dmOpened() and os.clock() - t1 < 10 do task.wait(0.1) end
assert(dmOpened(), "tail: the client did not open " .. DM .. " by itself within 10 s (the mishap needs its waiting slot)")
assert(type(ph:Invoke("Pop", uid, NEWS)) == "string", "tail: Pop(" .. NEWS .. ") sent nothing")
assert(type(ph:Invoke("Pop", uid, MISHAP)) == "string", "tail: Pop(" .. MISHAP .. ") sent nothing (MaxWaiting?)")
return msg
