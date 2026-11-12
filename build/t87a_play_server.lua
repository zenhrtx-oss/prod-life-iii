-- Server, during play (Wave 3 Task 5c-2; launch audit A13): a nameplate lets go of its player when its character is
-- removed. A stand-in character (a Model with a Head and a Humanoid, anchored and hidden high over the hub) gets a plate
-- for the player through Modules/Nameplate.Attach, as Systems/Reactions does on every spawn.
-- (1) In the world, its plate follows the player's Year.
-- (2) Removed the way a respawn or a leave removes a character under legacy removal (parented to nil, never destroyed),
--     its plate no longer follows the player's attributes, while the live character's own plate still does.
-- The file's own fresh(): unseated in the lounge, Quiet on, WalkIns paused and reset (nothing else moves the player's
-- attributes meanwhile), then the player's Year kept. Everything this file made is destroyed, the Year put back and Quiet
-- turned off, error or not.
-- fresh() deviates from the standard one on purpose: no Career, Life or Hints reset. The check reads only the plates and
-- the Year it sets, and a Life reset would itself rewrite the Year it reads.
local Players, RS, SSS = game:GetService("Players"), game:GetService("ReplicatedStorage"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local wi = SSS.OK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SSS.OK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local Nameplate = require(RS.OK.Modules.Nameplate)
local LOUNGE = Vector3.new(24, 3, 0)
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
	assert(wi:Invoke("Pause", uid, true) == true and wi:Invoke("Reset", uid) == true, label .. ": WalkIns Pause / Reset failed")
end
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function livePlate()
	local c = p.Character; local h = c and c:FindFirstChild("Head")
	return h and h:FindFirstChild("OK_Nameplate")
end
local was, kept = nil, false -- the player's Year before this file, and whether it was read
local dummy
local out = {}

local function run()
	fresh("t87a")
	was, kept = p:GetAttribute("Year"), true
	local live = livePlate()
	assert(live and live:FindFirstChild("StatsText"), "the player's character has no OK_Nameplate (Systems/Reactions)")
	dummy = Instance.new("Model"); dummy.Name = "T87_PlateStandIn"
	local head = Instance.new("Part")
	head.Name = "Head"; head.Size = Vector3.new(1, 1, 1); head.Anchored = true; head.CanCollide = false; head.CanQuery = false; head.CanTouch = false
	head.Transparency = 1; head.CFrame = CFrame.new(0, 300, 0); head.Parent = dummy
	Instance.new("Humanoid").Parent = dummy
	dummy.Parent = workspace
	local bb = Nameplate.Attach(dummy, p, function() return "T87" end)
	local stats = bb and bb:FindFirstChild("StatsText")
	assert(stats, "Nameplate.Attach built no plate on the stand-in")

	-- 1. in the world it follows the player
	p:SetAttribute("Year", 87)
	assert(waitFor(function() return string.find(stats.Text, "YEAR 87", 1, true) ~= nil end, 2), "the stand-in's plate did not follow the Year: '" .. stats.Text .. "'")
	table.insert(out, "1 in the world: '" .. stats.Text .. "'")

	-- 2. removed (parented to nil, not destroyed): it lets go; the live plate still follows
	dummy.Parent = nil
	task.wait(0.2) -- deferred signals: the removal is seen before the next change
	p:SetAttribute("Year", 88)
	assert(waitFor(function() return string.find(live.StatsText.Text, "YEAR 88", 1, true) ~= nil end, 2), "the live plate did not follow the Year: '" .. live.StatsText.Text .. "'")
	task.wait(0.2)
	assert(not string.find(stats.Text, "YEAR 88", 1, true), "the removed character's plate still follows the player's attributes: '" .. stats.Text .. "'")
	table.insert(out, "2 removed: its plate kept '" .. stats.Text .. "' while the live plate moved to '" .. live.StatsText.Text .. "'")
end

local ok, err = pcall(run)
if kept then p:SetAttribute("Year", was) end
if dummy then dummy:Destroy() end
pcall(function() ph:Invoke("Quiet", uid, false) end)
if not ok then error(err, 0) end
return "T87A PLAY OK\n" .. table.concat(out, "\n")
