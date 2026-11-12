-- Server, during play (the Your Rooms plan, Task 7), after t106b: puts back what t106a's tail staged for t106b. Any play
-- of the player's is stopped (the rooms hook's Stop: DAW_Stop's own handler), the player stands in the lounge, and their
-- gear goes back to what it was before t106a: ResetGear, then GrantGear the ids t106a noted in the player attribute
-- _T106Gear (cleared after). Then the gear is checked back, and the bedroom's speakers follow it (none, unless the noted
-- gear held speaker gear). With no _T106Gear (t106a failed before its tail) nothing is touched and the file fails.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local rooms = SOK:WaitForChild("_StudioRoomsHook", 5); assert(rooms, "no _StudioRoomsHook (is Systems/Rooms synced and started?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local Config = require(RS.OK.Config)
local RoomRules = require(RS.OK.Modules.RoomRules)
local LOUNGE = Vector3.new(24, 3, 0)

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local noted = p:GetAttribute("_T106Gear")
assert(type(noted) == "string", "no _T106Gear on the player: t106a's tail did not run (did t106a fail?), so there is nothing to put back")

pcall(function() rooms:Invoke("Stop", uid) end)
local c = p.Character
local h = c and c:FindFirstChildOfClass("Humanoid")
if h and (h.Sit or h.SeatPart) then h.Sit = false; task.wait(0.4) end
if c then c:PivotTo(CFrame.new(LOUNGE)); task.wait(0.3) end

local want = {}
for id in string.gmatch(noted, "[^,]+") do table.insert(want, id) end
table.sort(want)
assert(test:Invoke("ResetGear", uid) == true, "ResetGear failed")
if #want > 0 then assert(test:Invoke("GrantGear", uid, table.concat(want, ",")) == true, "GrantGear(" .. noted .. ") failed") end
p:SetAttribute("_T106Gear", nil)

local prof = test:Invoke("GetProfile", uid)
local have = {}
for id, on in pairs(type(prof) == "table" and type(prof.gear) == "table" and prof.gear or {}) do if on == true then table.insert(have, id) end end
table.sort(have)
assert(table.concat(have, ",") == table.concat(want, ","), "the gear is " .. table.concat(have, ",") .. " after the put-back, want " .. table.concat(want, ","))
-- the bedroom's speakers follow the gear put back
local tier = RoomRules.SpeakerTier(want, Config.Rooms.Speakers)
local info = rooms:Invoke("Plot", uid)
local k = type(info) == "table" and info.slot
local plots = workspace:FindFirstChild("OK_Plots")
local bed = k and plots and plots:FindFirstChild(string.format("Plot_%02d", k)) and plots[string.format("Plot_%02d", k)]:FindFirstChild("Room_bedroom")
if bed then
	assert(waitFor(function()
		local L = bed:FindFirstChild("RoomSpeaker_L")
		if tier < 2 then return L == nil end
		return L ~= nil and L:GetAttribute("Tier") == tier
	end, 5), "the bedroom's RoomSpeaker_L is " .. tostring(bed:FindFirstChild("RoomSpeaker_L") and bed.RoomSpeaker_L:GetAttribute("Tier")) .. " after the put-back, want tier " .. tier
		.. (tier < 2 and " (none)" or ""))
end
return "T106C PLAY OK: gear put back (" .. (#want > 0 and table.concat(want, ",") or "none") .. "), speaker tier " .. tier .. ", the player in the lounge"
