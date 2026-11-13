-- Server, during play (the Your Rooms plan, Task 13): the tail of t112a-b. It puts back what they staged (home bought, the
-- player in it, posters hung and taken down), so the files after it find the player in the lounge with the profile as t112a
-- found it. One Play session runs the whole sorted list, so this runs even when an earlier t112 file failed.
-- The put-back, every step tried whatever failed before it: the hold on; unseated and moved to the lounge (24, 3, 0);
-- WalkIns, the phone, Career (its gates: home goes) and Life reset, no hint seen; the rooms hook's Reset (the home back to its
-- defaults; the plot rebuilt with the bedroom only); Quiet off; then the test hook's ProfileRestore (t112a's ProfileMark)
-- and the career hook's Publish. Then _T112Mark is cleared. After all of that: t112a's mark was there, ProfileRestore
-- answered true, InPlot 0 and the player within 2 studs of the lounge, and the plot's rooms read "bedroom". The first
-- failure is rethrown. Marker "T112C PLAY OK".
local Players, SSS = game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local rooms = SOK:WaitForChild("_StudioRoomsHook", 5); assert(rooms, "no _StudioRoomsHook (is Systems/Rooms synced and started?)")
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local LOUNGE = Vector3.new(24, 3, 0)
local T0 = os.clock()

local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function root() local c = p.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = p.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function teleport(pos) -- the test's own move; checked, and tried once more if the client's position won
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
local function unseat()
	local h = hum()
	if h and (h.Sit or h.SeatPart) then h.Sit = false; task.wait(0.4) end
end

local marked = p:GetAttribute("_T112Mark") == true
local steps = {}
local function try(label, fn)
	local good, err = pcall(fn)
	if not good then table.insert(steps, label .. ": " .. tostring(err)) end
end
try("hold", function() wi:Invoke("Pause", uid, true) end)
try("unseat", unseat)
try("lounge", function() teleport(LOUNGE) end) -- first, so the rebuild below never happens under the player
try("resets", function()
	wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
	test:Invoke("ResetHints", uid)
end)
try("rooms Reset", function() assert(rooms:Invoke("Reset", uid) == true, "the rooms hook's Reset failed") end)
try("Quiet off", function() ph:Invoke("Quiet", uid, false) end)
local restored
try("ProfileRestore", function() restored = test:Invoke("ProfileRestore", uid) end)
try("Publish", function() career:Invoke("Publish", uid) end) -- Career_Get's cached Money dropped, the career attributes sent again
p:SetAttribute("_T112Mark", nil)
local inPlot
try("InPlot", function() inPlot = rooms:Invoke("InPlot", uid) end)

-- the put-back's checks
assert(marked, "no _T112Mark on the player (t112a sets it with its ProfileMark: did t112a fail and put everything back itself?); "
	.. "the lounge and the resets are done" .. (#steps > 0 and (" (and hit: " .. table.concat(steps, "; ") .. ")") or ""))
assert(#steps == 0, "the put-back hit " .. #steps .. " error(s): " .. table.concat(steps, "; "))
assert(restored == true, "the test hook's ProfileRestore answered " .. tostring(restored) .. ", want true (t112a's ProfileMark)")
assert(inPlot == 0 and p:GetAttribute("InPlot") == 0, "InPlot is " .. tostring(p:GetAttribute("InPlot")) .. " (the hook read " .. tostring(inPlot) .. ") in the lounge, want 0")
local r = root()
assert(r and flat(r.Position - LOUNGE) < 2, "the player is at " .. tostring(r and r.Position) .. ", want the lounge " .. tostring(LOUNGE))
local info = rooms:Invoke("Plot", uid)
local kinds = type(info) == "table" and table.concat(info.rooms, ",") or tostring(info)
assert(kinds == "bedroom", "the plot's rooms read '" .. kinds .. "' after the put-back, want bedroom (Career Reset: home goes)")
return string.format("T112C PLAY OK (%.1f s)\nput back: the player in the lounge (InPlot 0), the plot bedroom only, the profile as t112a found it", os.clock() - T0)
