-- Server, during play (Wave 1b Task 3; Review Focus 4): the daily Aura heal through the WalkIns hook's Heal, paused,
-- Quiet on. Heal runs the heal attempt now and returns what it paid: it ignores the test hold and the heal's session
-- memory, never the reward gate (Config.Career.Sources.AuraHeal: max 5, dailyMax 1). Counts are the gate's
-- careerLog.count["AuraHeal.aura"]. (1) aura -3 heals 3 to 0, never above; count 1. (2) back at -3, a second heal the
-- same UTC day pays 0 through the gate: aura stays -3, count stays 1 (the cross-session case, since Heal skips the
-- session memory). (3) on a fresh career log, aura 40 heals nothing and counts nothing. Tail for t61b, after the
-- cleanup: Career Reset (a fresh log), aura -12, 0.5 s for the client to take it, then Heal pays 5 with the toast
-- "the internet forgot. +5 AURA".
local Players, SSS = game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local LOUNGE = Vector3.new(24, 3, 0)
local KEY = "AuraHeal.aura"
local out = {}

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
local function aura() return career:Invoke("Get", uid).aura end
local function setAura(n, label) assert(career:Invoke("Set", uid, { aura = n }) == true, label .. ": Set aura " .. n .. " failed") end
-- the reward gate's count of awards through "<source>.<stat>" today (DataService._gate's careerLog)
local function awards(key)
	local log = test:Invoke("GetProfile", uid).career.careerLog
	return log and log.count and log.count[key] or 0
end
local function heal(label)
	local n = wi:Invoke("Heal", uid)
	assert(type(n) == "number", label .. ": the hook's Heal returned " .. tostring(n))
	return n
end
-- the file's own fresh(): unseated and in the lounge, Quiet on, WalkIns and Career reset (Career Reset clears careerLog)
local function fresh(label)
	local c = p.Character; local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum and hum.Sit then hum.Sit = false; task.wait(0.4) end
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, label .. ": Quiet(true) failed")
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	assert(awards(KEY) == 0, label .. ": an AuraHeal award is left after Career Reset")
end

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh("heal")

	-- 1: aura -3 heals to 0, never above
	setAura(-3, "-3")
	local h1 = heal("-3")
	assert(h1 == 3 and aura() == 0, "-3: want Heal 3 and aura 0, got " .. h1 .. " and " .. aura())
	assert(awards(KEY) == 1, "-3: want one " .. KEY .. " award, got " .. awards(KEY))
	table.insert(out, "aura -3: Heal 3, aura 0, one " .. KEY .. " award")

	-- 2: a second heal the same UTC day pays 0 through the gate (Heal skips the session memory: a new session's try)
	setAura(-3, "again")
	local h2 = heal("again")
	assert(h2 == 0 and aura() == -3, "again: want Heal 0 and aura -3 (the gate's daily refusal), got " .. h2 .. " and " .. aura())
	assert(awards(KEY) == 1, "again: the count moved to " .. awards(KEY))
	table.insert(out, "again at -3 the same day: Heal 0, aura -3, count still 1")

	-- 3: Aura 0 and above heals nothing, on a log where the gate would still pay
	assert(career:Invoke("Reset", uid) == true and awards(KEY) == 0, "aura 40: Career Reset failed")
	setAura(40, "aura 40")
	local h3 = heal("aura 40")
	assert(h3 == 0 and aura() == 40 and awards(KEY) == 0, "aura 40: want Heal 0, aura 40, no award; got " .. h3 .. ", " .. aura() .. ", " .. awards(KEY))
	table.insert(out, "aura 40 on a fresh log: Heal 0, nothing counted")

	return "T61A PLAY OK\n" .. table.concat(out, "\n")
end

local ok, msg = pcall(run)
pcall(function() wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Quiet", uid, false) end)
pcall(teleport, LOUNGE)
if not ok then error(msg, 0) end
-- staging for t61b, after the cleanup: a fresh career log at aura -12, a pause so the client's Aura listener takes -12
-- as its last value, then the heal of 5 sends its toast and drives the float now
assert(career:Invoke("Reset", uid) == true, "tail: Career Reset failed")
setAura(-12, "tail")
task.wait(0.5)
local h = heal("tail")
assert(h == 5 and aura() == -7, "tail: want Heal 5 from -12 (aura -7), got " .. h .. " and " .. aura())
return msg
