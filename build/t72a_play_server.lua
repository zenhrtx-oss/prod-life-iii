-- Server, during play (Wave 2 Task 4; Review Focus 4; first of t72a..e, one staged career run through): stages a life for
-- t72b, paused, Quiet on (t72e puts everything back; a failure here cleans up at once). The file's own fresh() (unseated in
-- the lounge, Quiet on, WalkIns, Career, then Life Reset). The roster is set to parody through the hook, whatever Config says.
-- A hook Set to 6,000 Followers records BUZZING and KNOWN silently on day 1. Day 3: a placement (navx). Day 9: a placement
-- (homekid, TRACK ONE), a hit (navx: ribbon CHARTED) and a sponsor (energy: ribbon BRAND DEAL), through _StudioLifeHook
-- Event: t71a has their real walk-in paths. A level entry at n = 99 has no rank, so StoryText can't render it: t72b's rows
-- skip it. Career: 1 placement, 150 Aura, $2,500, so THE HALL's bar reads part way. Asserted here: the Year, Tier and Title
-- attributes, the stored entries by id, and one ribbon toast per ribbon.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local LOUNGE = Vector3.new(24, 3, 0)
local T0 = os.clock()

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
local function fresh(label)
	local c = p.Character; local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum and hum.Sit then hum.Sit = false; task.wait(0.4) end
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, label .. ": Quiet(true) failed")
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	assert(life:Invoke("Reset", uid) == true, label .. ": Life Reset failed")
end
local function day(n) assert(life:Invoke("SetDay", uid, n) == true, "SetDay " .. n .. " failed") end
local function event(kind, fields)
	local r = life:Invoke("Event", uid, kind, fields)
	assert(r and r.story, kind .. ": the hook Event logged nothing")
	return r
end

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh("stage")
	assert(test:Invoke("ResetSessions", uid) == true, "ResetSessions failed")
	assert(life:Invoke("SetRoster", uid, "parody") == true, "SetRoster failed")
	assert(career:Invoke("Set", uid, { followers = 6000, placements = 1, aura = 150, money = 2500, sponsor = false }) == true, "Career Set failed")
	assert(#life:Invoke("Sent", uid) == 0, "a hook Set sent a banner")
	day(3)
	event("placement", { v = "navx", key = "navx_placement" })
	day(9)
	event("placement", { v = "homekid", key = "payback_homekid", disco = "trackone" })
	event("hit", { v = "navx", key = "navx_single" })
	event("sponsor", { s = "energy" })
	event("level", { n = 99 })
	local st = life:Invoke("State", uid)
	assert(#st.story == 7, "the story should hold 7 entries, holds " .. #st.story)
	assert(#st.disco == 3 and st.disco[2].kind == "trackone" and st.disco[2].v == "homekid", "the discography is wrong")
	assert(st.firsts.placement == 3 and st.firsts.hit == 9 and st.firsts.sponsor == 9 and st.firsts.buzzing == 1 and st.firsts.known == 1, "the firsts are wrong")
	assert(st.ribbons.hit == 9 and st.ribbons.sponsor == 9, "the ribbons are wrong")
	local toasts = {}
	for _, e in ipairs(life:Invoke("Sent", uid)) do if e.kind == "Toast" then table.insert(toasts, e.payload.text) end end
	assert(table.concat(toasts, "|") == "RIBBON: CHARTED|RIBBON: BRAND DEAL", "the ribbon toasts: " .. table.concat(toasts, "|"))
	assert(p:GetAttribute("Year") == 2 and p:GetAttribute("Tier") == "KNOWN" and p:GetAttribute("Title") == "CHART MAKER",
		string.format("attributes: Year %s, Tier %s, Title %s", tostring(p:GetAttribute("Year")), tostring(p:GetAttribute("Tier")), tostring(p:GetAttribute("Title"))))
	return string.format("T72A PLAY OK: day 9, year 2, KNOWN, CHART MAKER; 7 story entries (one unrenderable), 3 discography rows, ribbons hit and sponsor; elapsed %.1f s", os.clock() - T0)
end

local ok, msg = pcall(run)
if not ok then
	pcall(function() wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid); ph:Invoke("Quiet", uid, false) end)
	error(msg, 0)
end
return msg
