-- Server, during play (the Your Rooms plan, Task 12): the tail of t111a-d. It puts back what they staged and what the two
-- real deliveries (t111b's at home, t111d's in the bedroom) paid, so the files after it (t11_play_client, t12, then t17b,
-- which counts on a fresh session's money, level and gear) find the player in the lounge with the profile and the tour as
-- t111a found them. One Play session runs the whole sorted list, so this runs even when an earlier t111 file failed.
-- The put-back, every step tried whatever failed before it: the hold on; any room play stopped; unseated and moved to the
-- lounge (24, 3, 0), where the beat maker and any panel close; WalkIns, the phone, Career (its gates: home goes) and Life
-- reset, no hint seen, ResetSessions (no active request); the rooms hook's Reset (the home back to its defaults: the
-- closet goes; the plot rebuilt with the bedroom only); ResetTour, then the steps t111a noted in _T111Tour done again (or
-- the tour skipped again), so the client's pill shows the restored tour; Quiet off; then the test hook's ProfileRestore
-- (t111a's ProfileMark: money, XP and level, gear and what is worn, the gate logs, the tour, the hints, the sessions and
-- credits) and the career hook's Publish. Then _T111Tour is cleared. After all of that: t111a's note was there,
-- ProfileRestore answered true, InPlot 0 and the player within 2 studs of the lounge, the plot's rooms read "bedroom", and
-- the tour reads as noted. The first failure is rethrown. Marker "T111E PLAY OK".
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local rooms = SOK:WaitForChild("_StudioRoomsHook", 5); assert(rooms, "no _StudioRoomsHook (is Systems/Rooms synced and started?)")
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local Tour = require(RS.OK.Systems.Tour) -- its Steps only
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
local function tourNow()
	local prof = test:Invoke("GetProfile", uid)
	local t = type(prof) == "table" and type(prof.tour) == "table" and prof.tour or {}
	return { done = t.done == true, skipped = t.skipped == true, got = type(t.got) == "table" and t.got or {} }
end
local function tourNote(t)
	local ids = {}
	for _, s in ipairs(Tour.Steps) do if t.got[s.id] then table.insert(ids, s.id) end end
	return table.concat(ids, ",") .. "|" .. (t.done and "done" or "") .. "|" .. (t.skipped and "skipped" or "")
end
local function parseTour(note)
	if type(note) ~= "string" then return nil end
	local ids, done, skipped = string.match(note, "^([^|]*)|([^|]*)|([^|]*)$")
	if not ids then return nil end
	local got = {}
	for id in string.gmatch(ids, "[^,]+") do got[id] = true end
	return { got = got, done = done == "done", skipped = skipped == "skipped" }
end

local note = p:GetAttribute("_T111Tour")
local before = parseTour(note)
local steps = {}
local function try(label, fn)
	local good, err = pcall(fn)
	if not good then table.insert(steps, label .. ": " .. tostring(err)) end
end
try("hold", function() wi:Invoke("Pause", uid, true) end)
try("stop", function() rooms:Invoke("Stop", uid) end) -- a room play (none is fine)
try("unseat", unseat)
try("lounge", function() teleport(LOUNGE) end) -- first, so the rebuild below never happens under the player
try("resets", function()
	wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
	test:Invoke("ResetHints", uid); test:Invoke("ResetSessions", uid)
end)
try("rooms Reset", function() assert(rooms:Invoke("Reset", uid) == true, "the rooms hook's Reset failed") end)
try("tour", function()
	test:Invoke("ResetTour", uid)
	if before then
		if before.skipped then test:Invoke("TourSkip", uid)
		else
			for _, s in ipairs(Tour.Steps) do
				if before.done or before.got[s.id] then test:Invoke("TourAdvance", uid, s.id) end
			end
		end
	end
end)
try("Quiet off", function() ph:Invoke("Quiet", uid, false) end)
local restored
try("ProfileRestore", function() restored = test:Invoke("ProfileRestore", uid) end)
try("Publish", function() career:Invoke("Publish", uid) end) -- Career_Get's cached Money dropped, the career attributes sent again
p:SetAttribute("_T111Tour", nil)
local inPlot
try("InPlot", function() inPlot = rooms:Invoke("InPlot", uid) end)

-- the put-back's checks
assert(before ~= nil, "no _T111Tour note on the player (t111a writes it with its ProfileMark: did t111a fail and put everything back itself?); "
	.. "the lounge and the resets are done" .. (#steps > 0 and (" (and hit: " .. table.concat(steps, "; ") .. ")") or ""))
assert(#steps == 0, "the put-back hit " .. #steps .. " error(s): " .. table.concat(steps, "; "))
assert(restored == true, "the test hook's ProfileRestore answered " .. tostring(restored) .. ", want true (t111a's ProfileMark)")
assert(inPlot == 0 and p:GetAttribute("InPlot") == 0, "InPlot is " .. tostring(p:GetAttribute("InPlot")) .. " (the hook read " .. tostring(inPlot) .. ") in the lounge, want 0")
local r = root()
assert(r and flat(r.Position - LOUNGE) < 2, "the player is at " .. tostring(r and r.Position) .. ", want the lounge " .. tostring(LOUNGE))
local info = rooms:Invoke("Plot", uid)
local kinds = type(info) == "table" and table.concat(info.rooms, ",") or tostring(info)
assert(kinds == "bedroom", "the plot's rooms read '" .. kinds .. "' after the put-back, want bedroom (Career Reset: home goes)")
local after = tourNote(tourNow())
assert(after == note, "the tour is '" .. after .. "' after the put-back, want '" .. tostring(note) .. "' as t111a noted it")
return string.format("T111E PLAY OK (%.1f s)\nput back: the player in the lounge (InPlot 0), the plot bedroom only, the tour '%s' and the profile as t111a found them",
	os.clock() - T0, note)
