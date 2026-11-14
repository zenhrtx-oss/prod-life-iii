-- Server, during play (the Your Rooms plan, R-T16 fix, I1: decorate mode yields to the beat maker and to cards; preflight
-- F3: the server's half), after t109b. A tail that stages t109d and nothing else, through the Studio hooks:
-- * the player wakes up in their bedroom (the rooms hook's WakeUp: t109b's cleanup left them in the lounge);
-- * OnDecorate("RunStation", "bedroom") is armed (Systems/Rooms' one-shot test seam): the next time this player's decorate
--   push goes out (t109d presses the bedroom's DecoratePrompt), the server runs the bedroom laptop's real handler
--   (InteractionService._RunHandler "Station": Systems/Stations -> DAW.OpenFor -> OpenDAW, the path a laptop press and Day
--   One's "Make it now" take) at this client's second Room_Get after the push: the first is decorate mode's own fetch,
--   the second t109d's knock, sent once it reads Editing. So the beat maker opens while decorate mode is on, with no timing
--   guess and no fixed sleep.
-- The body runs held (WalkInsPaused true, as the suite leaves it). Marker "T109C PLAY OK".
-- The expected red, before the R-T16 fix sync of Systems/Rooms: "tail: OnDecorate(RunStation, bedroom) was not armed (the
-- hook answered nil)".
local Players, SSS = game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local rooms = SSS.OK:WaitForChild("_StudioRoomsHook", 5); assert(rooms, "no _StudioRoomsHook (is Systems/Rooms synced and started?)")
local function call(cmd, a, b) return rooms:Invoke(cmd, uid, a, b) end

local hm = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
if hm and (hm.Sit or hm.SeatPart) then hm.Sit = false; task.wait(0.4) end
assert(call("WakeUp") == true, "tail: WakeUp returned false (no slot, or no plot)")
local pl = call("PlaceOf")
local t0 = os.clock()
while not (type(pl) == "table" and pl.kind == "bedroom") and os.clock() - t0 < 4 do task.wait(0.1); pl = call("PlaceOf") end
assert(type(pl) == "table" and pl.kind == "bedroom", "tail: after WakeUp PlaceOf reads " .. (type(pl) == "table" and (tostring(pl.slot) .. "/" .. tostring(pl.kind)) or tostring(pl)) .. ", want the bedroom")
local st = call("Station", "bedroom")
assert(typeof(st) == "Instance", "tail: the bedroom has no Station (the hook's Station answered " .. tostring(st) .. ")")
local armed = call("OnDecorate", "RunStation", "bedroom")
assert(armed == true, "tail: OnDecorate(RunStation, bedroom) was not armed (the hook answered " .. tostring(armed) .. "; before the R-T16 fix sync of Systems/Rooms: the expected red)")
return string.format("T109C PLAY OK\nwoken in Plot_%02d's bedroom; OnDecorate(RunStation, bedroom) armed: the laptop's beat maker opens at t109d's knock (its second Room_Get after its decorate press)", pl.slot)
