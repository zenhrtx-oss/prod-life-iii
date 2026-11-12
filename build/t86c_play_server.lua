-- Server, during play (Wave 3 Task 5c-2; launch audit A7), after t86b: the cleanup. The profile's _loadFailed and
-- DataService.Persistent go back to what t86a found (kept on the player as _T86Was*; none kept, as when t86a failed
-- before setting them, means nothing to put back), and with them DataService.Saving (false in Studio Play, which has no
-- store); Quiet off, WalkIns reset, back in the lounge.
-- This file continues t86a/t86b, like t82c, so it has no fresh() of its own.
local Players, SSS = game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
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

local function run()
	local wasLF, wasP = p:GetAttribute("_T86WasLoadFailed"), p:GetAttribute("_T86WasPersistent")
	if wasP == nil then return "nothing to put back (t86a set no flags; its own result says why)" end
	local r = test:Invoke("SaveFlags", uid, { loadFailed = wasLF == true, persistent = wasP == true })
	assert(type(r) == "table" and r.was.loadFailed == true and r.was.persistent == true, "the flags t86b ran under were not t86a's")
	local now = test:Invoke("SaveFlags", uid, {})
	assert(now.was.loadFailed == (wasLF == true) and now.was.persistent == (wasP == true), "the flags did not go back")
	return string.format("_loadFailed back to %s, Persistent back to %s; Saving %s", tostring(wasLF), tostring(wasP), tostring(now.saving))
end

local ok, msg = pcall(run)
pcall(function()
	p:SetAttribute("_T86WasLoadFailed", nil); p:SetAttribute("_T86WasPersistent", nil)
	ph:Invoke("Quiet", uid, false)
	wi:Invoke("Reset", uid)
end)
pcall(teleport, LOUNGE)
if not ok then error(msg, 0) end
return "T86C PLAY OK: " .. msg .. "; Quiet off"
