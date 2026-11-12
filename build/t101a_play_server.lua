-- Server, during play (the Your Rooms plan, Task 2; Review Focus 1, 2 and 5): plots, the building's doors, the wake-up
-- and the respawn rule, through the Studio hook ServerScriptService.OK._StudioRoomsHook (a server test can't press a
-- prompt; every untagged Rooms prompt has a hook command that runs its real handler). The body runs held (WalkInsPaused
-- true: no join wake-up or respawn move of its own) and starts from the file's fresh(): unseated in the lounge, Quiet on,
-- the phone, WalkIns, Career and Life reset, no hint seen, and the rooms hook's Reset (a slot claimed, the plot rebuilt).
-- Positions are flat (x, z) distances from the root to the target: a pivot puts the root 3 studs over the floor.
-- (1) Plot: slot 1 at RoomRules.PlotOrigin(1) with rooms { "bedroom" }; Workspace.OK_Plots.Plot_01 holds a Landing
--     (OK_Room "landing") and Room_bedroom with OwnerId, OwnerName, RoomKind and Plot set; PlotSlot reads 1. The way in
--     and out is there and on: the bedroom door's ExitPrompt (the clone's, switched on by RoomBuild.Plot), the landing's
--     LeavePrompt and its bedroom RoomPrompt (none on a kind you don't own), hall door 1's EnterPrompt ("{player}'s
--     door"); a free slot's (door 2) is off. t101b presses them for real.
-- (2) WakeUp: within 3 studs of the bedroom's Spawn; InPlot 1; PlaceOf { slot 1, bedroom }.
-- (3) the bedroom's Station: its SFX is Config.SFX.Station's (InteractionService.Adopt), OK_Hooked is set (the added-tag
--     signal hooked the clone), and the hook's RunStation (InteractionService._RunHandler("Station")) acts: the beat
--     maker opens.
-- (4) the walk: Exit("bedroom") -> the landing outside the bedroom's door (its Door_bedroom.Out), PlaceOf landing;
--     Leave -> in front of hall door 1 (Door_01.Front), InPlot 0; HubDoor -> the corridor (RoomsDoor.Front, in the hub);
--     RoomsDoor -> HallSpawn; Enter(1) -> just inside the landing's front door (FrontDoor.Inside), InPlot 1;
--     GoIn("bedroom") -> the bedroom's Spawn.
-- (5) seated in the bedroom's Seat_Chair, Exit("bedroom") unseats first and moves to the landing.
-- (6) Respawn on the landing (inside your plot) -> "room", back at the bedroom's Spawn; Respawn in the lounge -> "hub",
--     at the hub's SpawnLocation, InPlot 0.
-- (7) the owner leaves with a guest in: Guest(1) (a stand-in Model in the bedroom) and the player in the bedroom, then
--     Release -> the guest and the player (preflight F5: owner included) at HallSpawn, Plot nil, PlotSlot 0, Plot_01
--     gone; Claim -> slot 1 again, rebuilt (a new Plot_01, OwnerId the player's).
-- (8) a full building: in the lounge, Release, Fill(12) fills all 12, then Claim answers nil and sends nothing; the
--     game's wake-up with no slot (the hook's WakeUp, past the hold) returns false and sends "the building is full. stay
--     in the studio." (copy 1.18), the player stays in the hub, PlotSlot 0; Unfill frees 12, Claim -> 1.
-- On any error: unseated in the lounge, Unfill, rooms Reset, and everything else reset (hold on, Quiet off); the error is
-- rethrown after. Tail for t101b, after the cleanup and only on success: WakeUp (the player in their bedroom, the plot
-- streamed in), then OnOpen("Exit", "bedroom"): the next time this player's beat maker opens at a laptop in a plot, the
-- server runs the bedroom's exit 2 s later (t101b opens it by pressing the laptop's prompt, then checks the window
-- closed after the server's move).
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
local Config = require(RS.OK.Config)
local RoomRules = require(RS.OK.Modules.RoomRules)
local WalkInRules = require(RS.OK.Modules.WalkInRules)
local RoomBuild = require(RS.OK.Modules.RoomBuild)
local Copy = RoomBuild.Copy
local Cfg = Config.Rooms
local LOUNGE = Vector3.new(24, 3, 0)
local out = {}
local T0 = os.clock()

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function root() local c = p.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = p.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function str(v) return typeof(v) == "Vector3" and string.format("(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z) or tostring(v) end
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
local function call(cmd, a, b) return rooms:Invoke(cmd, uid, a, b) end
local function plotModel(k) local f = workspace:FindFirstChild("OK_Plots"); return f and f:FindFirstChild(string.format("Plot_%02d", k)) end
local function bedroomOf(k) local m = plotModel(k); return m and m:FindFirstChild("Room_bedroom") end
local function spawnOf(k) local b = bedroomOf(k); local s = b and b:FindFirstChild("Spawn", true); return s end
local function landingOf(k) local m = plotModel(k); return m and m:FindFirstChild("Landing") end
local function hall() local r = workspace:FindFirstChild("OK_Rooms"); return r and r:FindFirstChild("Hall") end
local function attachment(parent, name)
	local a = parent and parent:FindFirstChild(name)
	assert(a and a:IsA("Attachment"), "no Attachment " .. name .. " under " .. tostring(parent and parent:GetFullName()))
	return a.WorldPosition
end
-- waits until the root stands within `tol` studs (flat) of `pos`
local function arrive(pos, label, tol)
	tol = tol or 3
	local ok = waitFor(function() local r = root(); return r ~= nil and flat(r.Position - pos) < tol end, 3)
	local r = root()
	assert(ok, label .. ": want the player within " .. tol .. " studs of " .. str(pos) .. ", got " .. (r and str(r.Position) or "no character")
		.. (r and string.format(" (%.1f away)", flat(r.Position - pos)) or ""))
end
local function inPlot(want, label)
	local v = call("InPlot")
	assert(v == want, label .. ": InPlot reads " .. tostring(v) .. ", want " .. want)
	assert(p:GetAttribute("InPlot") == want, label .. ": the InPlot attribute is " .. tostring(p:GetAttribute("InPlot")) .. ", want " .. want)
end
local function placeIs(want, label)
	local pl = call("PlaceOf")
	local got = type(pl) == "table" and (tostring(pl.slot) .. "/" .. tostring(pl.kind)) or tostring(pl)
	assert(got == want, label .. ": PlaceOf is " .. got .. ", want " .. want)
end
-- the file's own fresh(): unseated in the lounge, Quiet on, the phone, WalkIns, Career and Life reset, no hint seen,
-- the rooms hook's Reset (slot claimed, plot rebuilt)
local function fresh(label)
	unseat()
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, label .. ": Quiet(true) failed")
	assert(ph:Invoke("Reset", uid) == true, label .. ": phone Reset failed")
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	assert(life:Invoke("Reset", uid) == true, label .. ": Life Reset failed")
	assert(test:Invoke("ResetHints", uid) == true, label .. ": ResetHints failed")
	assert(call("Reset") == true, label .. ": the rooms hook's Reset failed (no slot, or the plot did not build)")
end

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh("plot")

	-- 1. the plot
	local info = call("Plot")
	assert(type(info) == "table", "Plot returned " .. tostring(info) .. ", want { slot, origin, rooms }")
	assert(info.slot == 1, "Plot: slot " .. tostring(info.slot) .. ", want 1 (the only player claims the lowest slot)")
	local ox, oy, oz = RoomRules.PlotOrigin(1, Cfg)
	local o = info.origin
	assert(o and o[1] == ox and o[2] == oy and o[3] == oz, string.format("Plot: origin %s, want (%d, %d, %d)",
		o and string.format("(%s, %s, %s)", tostring(o[1]), tostring(o[2]), tostring(o[3])) or "nil", ox, oy, oz))
	assert(type(info.rooms) == "table" and #info.rooms == 1 and info.rooms[1] == "bedroom",
		"Plot: rooms " .. (type(info.rooms) == "table" and table.concat(info.rooms, ",") or tostring(info.rooms)) .. ", want bedroom")
	local plot = plotModel(1)
	assert(plot, "Workspace.OK_Plots.Plot_01 missing")
	local landing = landingOf(1)
	assert(landing and landing:GetAttribute("OK_Room") == "landing", "Plot_01 has no Landing with OK_Room 'landing'")
	local bed = bedroomOf(1)
	assert(bed, "Plot_01 has no Room_bedroom")
	assert(bed:GetAttribute("OwnerId") == uid and bed:GetAttribute("OwnerName") == p.DisplayName, string.format(
		"Room_bedroom: OwnerId %s / OwnerName %s, want %d / %s", tostring(bed:GetAttribute("OwnerId")), tostring(bed:GetAttribute("OwnerName")), uid, p.DisplayName))
	assert(bed:GetAttribute("RoomKind") == "bedroom" and bed:GetAttribute("Plot") == 1, "Room_bedroom: RoomKind / Plot are "
		.. tostring(bed:GetAttribute("RoomKind")) .. " / " .. tostring(bed:GetAttribute("Plot")) .. ", want bedroom / 1")
	assert(p:GetAttribute("PlotSlot") == 1, "PlotSlot is " .. tostring(p:GetAttribute("PlotSlot")) .. ", want 1")
	-- the way in and out: every door's prompt is there and on (t101b presses them for real)
	local function promptOn(parent, name, label)
		local pp = parent and parent:FindFirstChild(name)
		assert(pp and pp:IsA("ProximityPrompt"), label .. ": no " .. name .. " under " .. tostring(parent and parent:GetFullName()))
		assert(pp.Enabled == true, label .. ": " .. pp:GetFullName() .. " is off")
		return pp
	end
	local bedDoor = RoomBuild.DoorOf(bed)
	assert(bedDoor, "Room_bedroom has no RoomDoor part")
	promptOn(bedDoor, "ExitPrompt", "the bedroom's door (RoomBuild.Plot turns the clone's ExitPrompt on)")
	promptOn(landing:FindFirstChild("FrontDoor"), "LeavePrompt", "the landing's front door")
	promptOn(landing:FindFirstChild("Door_bedroom"), "RoomPrompt", "the landing's bedroom door")
	for kind in pairs(Cfg.Kinds) do
		if kind ~= "bedroom" then
			local d = landing:FindFirstChild("Door_" .. kind)
			assert(d and d:FindFirstChild("RoomPrompt") == nil, "the landing's " .. kind .. " door (not owned) should have no RoomPrompt")
		end
	end
	local hl = hall()
	assert(hl, "Workspace.OK_Rooms.Hall missing")
	local enter1 = promptOn(hl:FindFirstChild("Door_01"), "EnterPrompt", "hall door 1 (claimed)")
	assert(enter1.ObjectText == (string.gsub(Copy.EnterObject, "{player}", function() return p.DisplayName end)), "hall door 1's EnterPrompt reads '" .. enter1.ObjectText .. "'")
	local enter2 = hl:FindFirstChild("Door_02") and hl.Door_02:FindFirstChild("EnterPrompt")
	assert(enter2 and enter2.Enabled == false, "hall door 2 (a free slot) has its EnterPrompt on")
	table.insert(out, string.format("1 Plot: slot 1 at (%d, %d, %d), rooms bedroom (%s); Landing + Room_bedroom owned by %d; ExitPrompt, LeavePrompt, RoomPrompt and door 1's EnterPrompt on, door 2's off",
		ox, oy, oz, bed:GetAttribute("StandIn") and "stand-in" or "the bedroom template", uid))

	-- 2. the wake-up
	assert(call("WakeUp") == true, "WakeUp returned false")
	local sp = spawnOf(1)
	assert(sp, "the bedroom has no Spawn")
	arrive(sp.Position, "WakeUp")
	inPlot(1, "WakeUp")
	placeIs("1/bedroom", "WakeUp")
	table.insert(out, "2 WakeUp: at the bedroom's Spawn, InPlot 1, PlaceOf 1/bedroom")

	-- 3. the bedroom's laptop
	local st = call("Station")
	assert(typeof(st) == "Instance" and st:IsDescendantOf(bed), "the hook's Station is " .. tostring(st) .. ", want the bedroom's Station")
	local sfx = st:FindFirstChild("SFX")
	assert(sfx and sfx:IsA("Sound") and sfx.SoundId == Config.SFX.Station.id, "the bedroom's Station has no Station SFX (InteractionService.Adopt): "
		.. tostring(sfx and sfx.SoundId))
	assert(st:GetAttribute("OK_Hooked") == true, "the bedroom's Station is not hooked (OK_Hooked " .. tostring(st:GetAttribute("OK_Hooked")) .. ")")
	task.wait(0.5)
	local res = call("RunStation")
	assert(type(res) == "table" and res.acted == true, "RunStation (_RunHandler Station) did not act: " .. tostring(res and res.acted) .. " / " .. tostring(res and res.toast))
	table.insert(out, "3 the bedroom's Station: Station SFX, hooked, and its handler opens the beat maker")
	task.wait(1)

	-- 4. the walk: bedroom -> landing -> hall -> studio -> hall -> your door -> landing -> bedroom
	assert(call("Exit", "bedroom") == true, "Exit(bedroom) returned false")
	local out1 = attachment(landing:FindFirstChild("Door_bedroom"), "Out")
	arrive(out1, "Exit(bedroom)")
	local r = root()
	assert(r.Position.X >= ox and r.Position.X <= ox + Cfg.Landing.length and r.Position.Z >= oz and r.Position.Z <= oz + Cfg.Landing.width,
		"Exit(bedroom): " .. str(r.Position) .. " is off the landing")
	inPlot(1, "Exit(bedroom)")
	placeIs("1/landing", "Exit(bedroom)")
	assert(call("Leave") == true, "Leave returned false")
	local h = hall()
	assert(h, "Workspace.OK_Rooms.Hall missing")
	arrive(attachment(h:FindFirstChild("Door_01"), "Front"), "Leave (hall door 1)")
	inPlot(0, "Leave")
	assert(call("HubDoor") == true, "HubDoor returned false")
	local rd = workspace.OK_Rooms:FindFirstChild("RoomsDoor")
	arrive(attachment(rd, "Front"), "HubDoor (the corridor)")
	r = root()
	assert(WalkInRules.InHub(r.Position.X, r.Position.Y, r.Position.Z), "HubDoor: " .. str(r.Position) .. " is not in the hub")
	placeIs("hub", "HubDoor")
	assert(call("RoomsDoor") == true, "RoomsDoor returned false")
	arrive(h:FindFirstChild("HallSpawn").Position, "RoomsDoor (HallSpawn)")
	inPlot(0, "RoomsDoor")
	assert(call("Enter", 1) == true, "Enter(1) by the owner returned false")
	arrive(attachment(landing:FindFirstChild("FrontDoor"), "Inside"), "Enter(1)")
	inPlot(1, "Enter(1)")
	assert(call("GoIn", "bedroom") == true, "GoIn(bedroom) returned false")
	arrive(sp.Position, "GoIn(bedroom)")
	table.insert(out, "4 doors: Exit -> landing, Leave -> hall door 1, HubDoor -> corridor (hub), RoomsDoor -> HallSpawn, Enter(1) -> landing, GoIn -> bedroom")

	-- 5. seated, a door press unseats first
	local seat = bed:FindFirstChild("Seat_Chair", true)
	assert(seat and seat:IsA("Seat"), "the bedroom has no Seat_Chair")
	seat:Sit(hum())
	assert(waitFor(function() return hum() and hum().SeatPart == seat end, 3), "the player did not sit in the bedroom's Seat_Chair")
	assert(call("Exit", "bedroom") == true, "seated: Exit(bedroom) returned false")
	assert(waitFor(function() return hum() and hum().SeatPart == nil end, 3), "seated: still in the chair after the door press")
	arrive(out1, "seated: Exit(bedroom)")
	table.insert(out, "5 seated in Seat_Chair: the door press unseats, then moves to the landing")

	-- 6. the respawn rule
	local where = call("Respawn")
	assert(where == "room", "Respawn on the landing (inside your plot) returned " .. tostring(where) .. ", want room")
	arrive(sp.Position, "Respawn in the plot")
	inPlot(1, "Respawn in the plot")
	unseat()
	teleport(LOUNGE)
	where = call("Respawn")
	assert(where == "hub", "Respawn in the lounge returned " .. tostring(where) .. ", want hub")
	local hubSpawn = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	assert(hubSpawn, "no SpawnLocation")
	arrive(hubSpawn.Position, "Respawn in the hub", 5)
	inPlot(0, "Respawn in the hub")
	table.insert(out, "6 Respawn: in the plot -> the bedroom's Spawn; in the hub -> the hub's spawn")

	-- 7. the owner leaves with a guest in
	assert(call("WakeUp") == true, "release: WakeUp returned false")
	arrive(sp.Position, "release: WakeUp")
	local g = call("Guest", 1)
	assert(typeof(g) == "Instance" and g.PrimaryPart, "Guest(1) returned " .. tostring(g))
	local hs = h:FindFirstChild("HallSpawn").Position
	local ok7, err7 = pcall(function()
		assert(flat(g.PrimaryPart.Position - hs) > 100, "the guest did not start in the plot")
		call("Sent") -- drained
		assert(call("Release") == true, "Release returned false")
		assert(flat(g.PrimaryPart.Position - hs) < 3, "Release: the guest is at " .. str(g.PrimaryPart.Position) .. ", want HallSpawn " .. str(hs))
		arrive(hs, "Release (preflight F5: the owner too)", 4)
		assert(call("Plot") == nil, "Release: Plot still answers a slot")
		assert(p:GetAttribute("PlotSlot") == 0, "Release: PlotSlot is " .. tostring(p:GetAttribute("PlotSlot")) .. ", want 0")
		assert(plotModel(1) == nil, "Release: Plot_01 is still in Workspace.OK_Plots")
	end)
	g:Destroy()
	if not ok7 then error(err7, 0) end
	assert(call("Claim") == 1, "Claim after Release: want slot 1 again")
	info = call("Plot")
	assert(info and info.slot == 1 and plotModel(1) and bedroomOf(1) and bedroomOf(1):GetAttribute("OwnerId") == uid, "Claim: slot 1 was not rebuilt for the player")
	table.insert(out, "7 Release with a guest and the owner in the bedroom: both at HallSpawn, slot freed, Plot_01 gone; Claim -> slot 1, rebuilt")

	-- 8. a full building
	teleport(LOUNGE)
	assert(call("Release") == true, "full: Release returned false")
	local filled = call("Fill", Cfg.Slots)
	assert(filled == Cfg.Slots, "Fill(" .. Cfg.Slots .. ") filled " .. tostring(filled))
	call("Sent") -- drained
	local okClaim, k = pcall(call, "Claim")
	assert(okClaim, "full: Claim errored: " .. tostring(k))
	assert(k == nil, "full: Claim answered " .. tostring(k) .. ", want nil (every slot taken)")
	local early = call("Sent")
	assert(type(early) == "table" and #early == 0, "full: the hook's Claim sent '" .. (type(early) == "table" and table.concat(early, " | ") or tostring(early))
		.. "' itself; only the game's wake-up may send the full toast (before R-T2 fix1's sync of Systems/Rooms: the hook's toast, the expected red)")
	-- the game's own path: the join wake-up with no slot (the hook's WakeUp runs it past the hold, without its 2 s wait)
	local okWake, woke = pcall(call, "WakeUp")
	assert(okWake, "full: WakeUp errored: " .. tostring(woke))
	assert(woke == false, "full: WakeUp with no slot returned " .. tostring(woke) .. ", want false")
	local sent = call("Sent")
	assert(type(sent) == "table" and table.find(sent, Copy.Full), "full: the wake-up sent no '" .. Copy.Full .. "' toast; got " .. (type(sent) == "table" and table.concat(sent, " | ") or tostring(sent)))
	r = root()
	assert(WalkInRules.InHub(r.Position.X, r.Position.Y, r.Position.Z), "full: the player left the hub: " .. str(r.Position))
	assert(p:GetAttribute("PlotSlot") == 0 and call("Plot") == nil, "full: the player has a slot")
	local freed = call("Unfill")
	assert(freed == Cfg.Slots, "Unfill freed " .. tostring(freed) .. ", want " .. Cfg.Slots)
	assert(call("Claim") == 1, "Claim after Unfill: want slot 1")
	table.insert(out, "8 full: Fill(12), Claim -> nil (no toast of its own); the wake-up with no slot -> false, '" .. Copy.Full .. "', still in the hub; Unfill, Claim -> 1")

	return "T101A PLAY OK\n" .. table.concat(out, "\n") .. string.format("\nelapsed %.1f s", os.clock() - T0)
end

local ok, msg = pcall(run)
pcall(unseat)
pcall(teleport, LOUNGE) -- first, so the rebuild below never happens under the player
pcall(function() rooms:Invoke("Unfill", uid) end)
pcall(function() rooms:Invoke("Reset", uid) end)
pcall(function()
	wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
	test:Invoke("ResetHints", uid); ph:Invoke("Quiet", uid, false)
end)
if not ok then error(msg, 0) end
-- staging for t101b, after the cleanup: the player wakes up in their bedroom (the plot streamed in), and the next time
-- their beat maker opens at a laptop in a plot, the server runs the bedroom's exit 2 s later
assert(rooms:Invoke("WakeUp", uid) == true, "tail: WakeUp returned false")
assert(rooms:Invoke("OnOpen", uid, "Exit", "bedroom") == true, "tail: OnOpen(Exit, bedroom) was not armed")
return msg
