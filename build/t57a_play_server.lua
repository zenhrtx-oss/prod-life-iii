-- Server, during play (the phone on the client, before t57b): Quiet off for this chain (the earlier phone files leave
-- it on, so the live PhoneUI never saw their pops), the scheduler paused, the player's walk-ins reset (the WalkIns
-- Reset runs the phone's reset through OnReset before it returns: no pop, no PhoneBusy, no timer carries over), the
-- player in the lounge at (24, 3, 0); then two pops through the phone hook, in this order: a DM (dm_navx: three
-- choices, the first sure and free) and a NEWS (news_spedup). t57b opens them on the client.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local Content = require(RS.OK.Data.WalkIns)
local LOUNGE = Vector3.new(24, 3, 0)

local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function root() local c = p.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function teleport(pos) -- server-side; checked, and tried once more if the client's position won
	for _ = 1, 2 do
		local c = p.Character or p.CharacterAdded:Wait()
		c:WaitForChild("HumanoidRootPart", 5)
		local hum = c:FindFirstChildOfClass("Humanoid")
		if hum and hum.Sit then hum.Sit = false; task.wait(0.4) end
		c:PivotTo(CFrame.new(pos))
		task.wait(0.3)
		local r = root()
		if r and flat(r.Position - pos) < 2 then return r end
	end
	error("teleport to " .. tostring(pos) .. " did not take")
end

assert(ph:Invoke("Quiet", uid, false) == true, "Quiet(false) failed")
assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
assert(wi:Invoke("Reset", uid) == true, "Reset failed")
assert(wi:Invoke("Pending", uid) == nil, "a visit is still in flight after Reset")
assert(#ph:Invoke("Pending", uid) == 0 and ph:Invoke("Busy", uid) == false and p:GetAttribute("PhoneBusy") == nil,
	"pops or PhoneBusy left right after the WalkIns Reset (the OnReset seam)")
teleport(LOUNGE)
local dm, news = Content.CardById.dm_navx, Content.CardById.news_spedup
assert(dm and dm.source == "phone" and not dm.news and #dm.choices == 3 and dm.choices[1].sure and (dm.choices[1].cost or 0) == 0,
	"dm_navx is not a phone DM with a sure, free first choice")
assert(news and news.source == "phone" and news.news == true, "news_spedup is not a phone NEWS card")
ph:Invoke("Sent", uid) -- read and clear
local a = ph:Invoke("Pop", uid, "dm_navx"); assert(type(a) == "string", "Pop(dm_navx) did not send")
local b = ph:Invoke("Pop", uid, "news_spedup"); assert(type(b) == "string", "Pop(news_spedup) did not send")
local pend = ph:Invoke("Pending", uid)
assert(#pend == 2 and pend[1].id == "dm_navx" and pend[2].id == "news_spedup" and not pend[1].opened and not pend[2].opened,
	"pending after the two Pops: " .. #pend .. " (" .. tostring(pend[1] and pend[1].id) .. ", " .. tostring(pend[2] and pend[2].id) .. ")")
local sent, pops = ph:Invoke("Sent", uid), 0
for _, s in ipairs(sent) do if s.kind == "pop" then pops += 1 end end
assert(pops == 2, "two pops should have gone to the client (Quiet off): " .. pops .. " of " .. #sent .. " sends")
return "T57A PLAY OK: Quiet off, paused, reset, player at (24, 3, 0); dm_navx then news_spedup sent to the client"
