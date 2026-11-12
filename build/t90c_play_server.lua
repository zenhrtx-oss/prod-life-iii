-- Server, during play (Wave 3 Task 5d), after t90b and before t90d: two phone pops for the portrait check on the phone
-- card. The file's own fresh() (unseated in the lounge, Quiet on, the phone's pops dropped, WalkIns, Career and Life
-- reset, ResetHints, SetRecent({})), the scheduler held; then Quiet off (the client must see these two, as in the t57
-- chain) and two pops through the phone hook, in this order: LIL NAV X's DM dm_navx (a person: his face on the card) and
-- news_spedup (from NEWS PING, a phone-only sender: no face). Quiet stays off for t90d; the next file's fresh() turns it
-- back on. On an error everything is reset, Quiet back on, and the error rethrown.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local Content = require(RS.OK.Data.WalkIns)
local LOUNGE = Vector3.new(24, 3, 0)

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
-- the file's own fresh(): unseated and in the lounge, Quiet on, no pops, WalkIns, Career and Life reset, hints and recent beats cleared
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

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh("stage")
	local dm, news = Content.CardById.dm_navx, Content.CardById.news_spedup
	assert(dm and dm.source == "phone" and dm.visitor == "navx", "dm_navx is not LIL NAV X's phone DM")
	assert(news and news.source == "phone" and news.visitor == "feed" and Content.VisitorById.feed.kind == "sender", "news_spedup is not a NEWS from the sender feed")
	assert(ph:Invoke("Quiet", uid, false) == true, "Quiet(false) failed")
	ph:Invoke("Sent", uid) -- read and clear
	assert(type(ph:Invoke("Pop", uid, "dm_navx")) == "string", "Pop(dm_navx) did not send")
	assert(type(ph:Invoke("Pop", uid, "news_spedup")) == "string", "Pop(news_spedup) did not send")
	local pend = ph:Invoke("Pending", uid)
	assert(#pend == 2, "pending after the two Pops: " .. #pend)
	local pops = 0
	for _, e in ipairs(ph:Invoke("Sent", uid)) do if e.kind == "pop" then pops += 1 end end
	assert(pops == 2, "two pops should have gone to the client (Quiet off): " .. pops)
end

local ok, err = pcall(run)
if not ok then
	pcall(function()
		wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
		test:Invoke("ResetHints", uid); test:Invoke("SetRecent", uid, {}); ph:Invoke("Quiet", uid, true)
	end)
	pcall(teleport, LOUNGE)
	error(err, 0)
end
return "T90C PLAY OK: fresh, Quiet off; dm_navx (LIL NAV X) then news_spedup (NEWS PING) sent to the client for t90d"
