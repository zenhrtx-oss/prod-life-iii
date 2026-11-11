-- Server, during play (Wave 2 Task 4; A2; after t71b, so nothing is showing or held on the client): the queue's order
-- through the real path. A real Followers Add crosses BUZZING (a LifeBanner), and straight after it a LEVEL UP from
-- _StudioTestHook AddXP with a nil source, as t15 does, and the newest story entry is that level. _T71Level = the level
-- t71d expects, 0 at the top level, where no LEVEL UP can come. The career is put back; the banners are already on their way.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi, ph = SOK:WaitForChild("_StudioWalkInHook", 5), SOK:WaitForChild("_StudioPhoneHook", 5)
local career, life, test = SOK:WaitForChild("_StudioCareerHook", 5), SOK:WaitForChild("_StudioLifeHook", 5), SOK:WaitForChild("_StudioTestHook", 5)
assert(wi and ph and career and life and test, "a Studio hook is missing")
local Cfg = require(RS.OK.Config)

local function run()
	assert(ph:Invoke("Quiet", uid, true) == true, "Quiet(true) failed")
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	assert(wi:Invoke("Reset", uid) == true and career:Invoke("Reset", uid) == true, "a Reset failed")
	assert(life:Invoke("Reset", uid) == true, "Life Reset failed") -- after Career's: it takes the tier from the Followers
	assert(career:Invoke("Set", uid, { followers = 900 }) == true, "Career Set failed")
	local before = test:Invoke("GetProfile", uid)
	local nextXP = Cfg.Levels[before.level + 1]
	assert(career:Invoke("Add", uid, "followers", 200, "WalkIn") == 200, "Career Add did not pay 200")
	local expect = 0
	if nextXP then
		local gained = test:Invoke("AddXP", uid, nextXP - before.xp, nil)
		local after = test:Invoke("GetProfile", uid)
		assert(gained == nextXP - before.xp and after.level == before.level + 1, "the level did not go up")
		expect = after.level
		local entry -- LeveledUp reaches Life through a BindableEvent, deferred
		local t1 = os.clock()
		repeat
			local story = life:Invoke("State", uid).story
			entry = story[#story]
			if not (entry and entry.k == "level") then task.wait(0.05) end
		until (entry and entry.k == "level") or os.clock() - t1 > 2
		assert(entry and entry.k == "level" and entry.n == expect, "the newest story entry after the real AddXP is " .. tostring(entry and entry.k))
	end
	p:SetAttribute("_T71Level", expect)
	return "T71C PLAY OK: a real crossing, then " .. (expect > 0 and ("LEVEL " .. expect .. " from AddXP") or "no level (the top level)")
end

local ok, msg = pcall(run)
pcall(function() wi:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid); ph:Invoke("Quiet", uid, false) end)
if not ok then error(msg, 0) end
return msg
