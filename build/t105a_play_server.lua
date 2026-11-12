-- Server, during play (the Your Rooms plan, Task 6: your station is yours, and the gear rack opens from your laptop),
-- through the Studio hook ServerScriptService.OK._StudioRoomsHook. The body runs held (WalkInsPaused true) from the file's
-- fresh(): unseated in the lounge, Quiet on, the phone, WalkIns, Career and Life reset, no hint seen, the rooms hook's Reset
-- (a slot claimed, the plot rebuilt). The bedroom's laptop is the hook's Station; "the stand spot" is room-local (2, 0, -3),
-- clear floor beside the chair in front of the desk (t101b's), in reach of the laptop.
-- (1) WakeUp puts the player in their bedroom. Room_bedroom holds a RackSpot (RoomBuild.RackSpot): a BasePart, invisible
--     and not colliding, inside the room Model (RoomScope.RoomOf is the bedroom), within 1.5 studs of the laptop, tagged
--     OK_Interactable with Kind "GearRack", hooked (OK_Hooked) with Config.SFX.GearRack's sound (InteractionService.Adopt),
--     and one enabled prompt "Open gear rack" / "Your laptop" (copy §3.2, §3.3) on F / ButtonY, its UIOffset.Y at least
--     80 px off the laptop prompt's (the stacked tap targets, RoomBuild.RACK_UI_GAP).
-- (2) The owner at the stand spot: the hook's StationOf (DAW.StationOf) answers { the laptop, the bedroom }; the hook's
--     MayUse answers true on the laptop, the RackSpot and the studio PC's screen; RunStation (_RunHandler "Station") acts
--     and sends no toast; Run("GearRack", RackSpot) (_RunHandler "GearRack": Systems/Gear's handler, which sends OpenPanel
--     with tab Gear straight on the remote, so only "acts" is visible here; t105b presses the real prompt) acts.
-- (3) Another owner, staged by setting the bedroom's OwnerId to -10501 and OwnerName to "Test Owner 7" (preflight m19: no
--     hook command for it; put back in the cleanup): still at the stand spot, MayUse answers false, "Test Owner 7" on the
--     laptop and on the RackSpot; StationOf answers no spot and no room while the laptop is within DAWConfig.CloseDistance
--     + 4; RunStation is refused by Systems/Stations' own guard with the owner toast "Test Owner 7's laptop. only they can
--     use it." (copy §3.1, the whole name). Then no OwnerId at all (preflight m18): MayUse answers false with no name, and
--     StationOf answers no spot.
-- (4) Still staged: the studio PC counts for anyone: at (72, 3.5, -5.5) StationOf answers the PC's screen and no room.
-- (5) The hub's counts (RoomScope.Split over every tagged part in Workspace, as t07): 12 interactables and 2 Stations; the
--     bedroom's entry holds its laptop and its RackSpot.
-- The deliver and ON MONITORS answers go through the real remotes from the client (a server script can't call a remote's
-- server side): "away" in t105d (someone else's laptop), not "away" in t105b (your own).
-- On any error, and after success: the staged owner put back, unseated in the lounge, the rooms Reset, everything else
-- reset (hold on, Quiet off); the error is rethrown. Tail for t105b, after the cleanup and only on success: WakeUp (the
-- player in their bedroom, the plot streamed in) and request j1 active (SetActiveRequest), for t105b's delivery at the
-- player's own laptop.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local CS = game:GetService("CollectionService")
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
local RoomScope = require(RS.OK.Modules.RoomScope)
local DAWCfg = require(RS.OK.Modules.DAWConfig)
local LOUNGE = Vector3.new(24, 3, 0)
local PC_SPOT = Vector3.new(72.0, 3.5, -5.5) -- in front of the studio PC (t17b, t21d)
local OTHER_ID, OTHER_NAME = -10501, "Test Owner 7" -- a 12-character name, not the player's
local TOAST = "Test Owner 7's laptop. only they can use it." -- copy §3.1 with OTHER_NAME, whole
local RED = " (before the R-T6 sync of Modules/RoomBuild, Services/InteractionService, Systems/DAW, Systems/Stations and Systems/Rooms: the expected red)"
local out = {}
local T0 = os.clock()
local staged -- { room, id, name } while another owner is staged on the bedroom

local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function root() local c = p.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = p.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function name(inst) return typeof(inst) == "Instance" and inst:GetFullName() or tostring(inst) end
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
-- the owner rule as the hook answers it: ok, ownerName?
local function mayUse(inst) return rooms:Invoke("MayUse", uid, inst) end
-- the hook's StationOf as "<spot> / <room>"
local function stationOf()
	local r = call("StationOf")
	assert(type(r) == "table", "the hook's StationOf answered " .. tostring(r) .. ", want { inst, room }" .. RED)
	return r, name(r.inst) .. " / " .. name(r.room)
end
local function restore()
	local s = staged
	staged = nil
	if s and s.room.Parent then s.room:SetAttribute("OwnerId", s.id); s.room:SetAttribute("OwnerName", s.name) end
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
	fresh("rack")

	-- 1. the RackSpot beside the bedroom's laptop
	assert(call("WakeUp") == true, "WakeUp returned false")
	local info = call("Plot")
	local k = type(info) == "table" and info.slot
	assert(k, "the hook's Plot answered " .. tostring(info) .. ", want the player's slot")
	local bed = plotModel(k) and plotModel(k):FindFirstChild("Room_bedroom")
	assert(bed, string.format("Workspace.OK_Plots.Plot_%02d has no Room_bedroom", k))
	local st = call("Station")
	assert(typeof(st) == "Instance" and st:IsDescendantOf(bed), "the hook's Station is " .. tostring(st) .. ", want the bedroom's laptop")
	local rack = bed:FindFirstChild("RackSpot")
	assert(rack and rack:IsA("BasePart"), "Room_bedroom has no RackSpot part" .. RED)
	assert(RoomScope.RoomOf(rack) == bed, "the RackSpot's room is " .. name(RoomScope.RoomOf(rack)) .. ", want " .. bed:GetFullName())
	assert(rack.Transparency == 1 and rack.CanCollide == false, string.format("the RackSpot should be invisible and not collide: Transparency %s, CanCollide %s",
		tostring(rack.Transparency), tostring(rack.CanCollide)))
	local gap = (rack.Position - st.Position).Magnitude
	assert(gap <= 1.5, string.format("the RackSpot is %.2f studs from the laptop, want beside it (1.5 at most)", gap))
	assert(CS:HasTag(rack, "OK_Interactable") and rack:GetAttribute("Kind") == "GearRack", "the RackSpot: tagged " .. tostring(CS:HasTag(rack, "OK_Interactable"))
		.. ", Kind " .. tostring(rack:GetAttribute("Kind")) .. "; want OK_Interactable and GearRack")
	assert(rack:GetAttribute("OK_Hooked") == true, "the RackSpot is not hooked (OK_Hooked " .. tostring(rack:GetAttribute("OK_Hooked")) .. ")")
	local sfx = rack:FindFirstChild("SFX")
	assert(sfx and sfx:IsA("Sound") and sfx.SoundId == Config.SFX.GearRack.id, "the RackSpot's SFX is " .. tostring(sfx and sfx.SoundId)
		.. ", want Config.SFX.GearRack's " .. Config.SFX.GearRack.id .. " (InteractionService.Adopt)")
	local prompts = {}
	for _, d in ipairs(rack:GetDescendants()) do if d:IsA("ProximityPrompt") then table.insert(prompts, d) end end
	assert(#prompts == 1, "the RackSpot holds " .. #prompts .. " prompts, want 1")
	local rp = prompts[1]
	assert(rp.Enabled, "the RackSpot's prompt is off")
	assert(rp.ActionText == "Open gear rack" and rp.ObjectText == "Your laptop", "the RackSpot's prompt reads '" .. rp.ActionText .. "' / '" .. rp.ObjectText
		.. "', want 'Open gear rack' / 'Your laptop' (copy §3.2, §3.3)")
	assert(rp.KeyboardKeyCode == Enum.KeyCode.F and rp.GamepadKeyCode == Enum.KeyCode.ButtonY, "the RackSpot's prompt keys are " .. tostring(rp.KeyboardKeyCode)
		.. " / " .. tostring(rp.GamepadKeyCode) .. ", want F / ButtonY")
	assert(math.abs(rp.UIOffset.Y) >= 80, "the RackSpot's prompt UIOffset is " .. tostring(rp.UIOffset) .. ", want it stacked 80 px or more off the laptop's (72 px a prompt)")
	table.insert(out, string.format("1 RackSpot in Plot_%02d.Room_bedroom, %.2f studs from the laptop: invisible, tagged GearRack, hooked, GearRack SFX; prompt 'Open gear rack' / 'Your laptop' on F / ButtonY, UIOffset %s",
		k, gap, tostring(rp.UIOffset)))

	-- 2. the owner at their laptop
	local stand = (bed:GetPivot() * CFrame.new(2, 0, -3)).Position + Vector3.new(0, 3, 0)
	teleport(stand)
	local reach = DAWCfg.CloseDistance + 4
	local d = (root().Position - st.Position).Magnitude
	assert(d <= reach, string.format("the stand spot is %.1f studs from the laptop, past StationOf's reach %d", d, reach))
	local mine, mineText = stationOf()
	assert(mine.inst == st and mine.room == bed, "the owner at their laptop: StationOf is " .. mineText .. ", want " .. st:GetFullName() .. " / " .. bed:GetFullName())
	local okSt, nameSt = mayUse(st)
	assert(okSt == true and nameSt == nil, "the owner: MayUse on the laptop answered " .. tostring(okSt) .. ", " .. tostring(nameSt) .. "; want true" .. RED)
	local okRk = mayUse(rack)
	assert(okRk == true, "the owner: MayUse on the RackSpot answered " .. tostring(okRk) .. ", want true")
	local pcScreen = workspace.OKStudio.ControlRoom:FindFirstChild("Screen_Main")
	assert(pcScreen, "no OKStudio.ControlRoom.Screen_Main")
	assert(mayUse(pcScreen) == true, "MayUse on the studio PC's screen should answer true (the hub's parts are everyone's)")
	local res = call("RunStation")
	assert(type(res) == "table" and res.acted == true and res.toast == nil, "the owner: RunStation should act with no toast, got "
		.. tostring(res and res.acted) .. " / " .. tostring(res and res.toast))
	local rres = call("Run", "GearRack", rack)
	assert(type(rres) == "table" and rres.acted == true, "the owner: Run(GearRack, RackSpot) should act (Systems/Gear's handler), got " .. tostring(rres and rres.acted) .. RED)
	table.insert(out, "2 the owner at the stand spot: StationOf " .. mineText .. "; MayUse true on the laptop, the RackSpot and the PC; RunStation and Run(GearRack) act")

	-- 3. another owner (preflight m19: the attribute set directly), then none (m18)
	staged = { room = bed, id = bed:GetAttribute("OwnerId"), name = bed:GetAttribute("OwnerName") }
	assert(staged.id == uid, "the bedroom's OwnerId is " .. tostring(staged.id) .. " before the staging, want " .. uid)
	bed:SetAttribute("OwnerId", OTHER_ID); bed:SetAttribute("OwnerName", OTHER_NAME)
	local okS, nS = mayUse(st)
	assert(okS == false and nS == OTHER_NAME, "another owner: MayUse on the laptop answered " .. tostring(okS) .. ", " .. tostring(nS) .. "; want false, " .. OTHER_NAME)
	local okR, nR = mayUse(rack)
	assert(okR == false and nR == OTHER_NAME, "another owner: MayUse on the RackSpot answered " .. tostring(okR) .. ", " .. tostring(nR) .. "; want false, " .. OTHER_NAME)
	d = (root().Position - st.Position).Magnitude
	assert(d <= reach, string.format("another owner: the player is %.1f studs from the laptop, want within %d", d, reach))
	local theirs, theirsText = stationOf()
	assert(theirs.inst == nil and theirs.room == nil, "another owner: StationOf is " .. theirsText .. " within reach of their laptop, want nil / nil")
	local res2 = call("RunStation")
	assert(type(res2) == "table" and res2.acted == false and res2.toast == TOAST, "another owner: RunStation should be refused by Systems/Stations' guard with '"
		.. TOAST .. "', got " .. tostring(res2 and res2.acted) .. " / " .. tostring(res2 and res2.toast))
	bed:SetAttribute("OwnerId", nil)
	local okN, nN = mayUse(st)
	assert(okN == false and nN == nil, "no owner (m18): MayUse on the laptop answered " .. tostring(okN) .. ", " .. tostring(nN) .. "; want false, no name")
	local none, noneText = stationOf()
	assert(none.inst == nil, "no owner (m18): StationOf is " .. noneText .. ", want nil")
	bed:SetAttribute("OwnerId", OTHER_ID)
	table.insert(out, string.format("3 OwnerId %d, OwnerName %s: MayUse false + the name on the laptop and the RackSpot; StationOf nil %.1f studs from the laptop; RunStation refused, '%s'; no OwnerId: MayUse false, no name, StationOf nil",
		OTHER_ID, OTHER_NAME, d, TOAST))

	-- 4. the studio PC counts for anyone
	teleport(PC_SPOT)
	local pc, pcText = stationOf()
	assert(pc.inst == pcScreen and pc.room == nil, "at the studio PC: StationOf is " .. pcText .. ", want " .. pcScreen:GetFullName() .. " / nil")
	table.insert(out, "4 still staged, at the studio PC: StationOf " .. pcText)

	-- 5. the hub's counts
	local inWs = {}
	for _, t in ipairs(CS:GetTagged("OK_Interactable")) do if t:IsDescendantOf(workspace) then table.insert(inWs, t) end end
	local hub, roomList = RoomScope.Split(inWs)
	local hubStations = 0
	for _, t in ipairs(hub) do if t:GetAttribute("Kind") == "Station" then hubStations += 1 end end
	assert(#hub == 12, "the hub holds " .. #hub .. " tagged interactables, want 12 (the RackSpot is inside the room)")
	assert(hubStations == 2, "the hub holds " .. hubStations .. " Stations, want 2")
	local entry
	for _, e in ipairs(roomList) do if e.room == bed then entry = e end end
	assert(entry and table.find(entry.items, rack) and table.find(entry.items, st), "RoomScope.Split should put the laptop and the RackSpot in the bedroom's entry")
	table.insert(out, string.format("5 hub: %d tagged interactables, %d Stations; the bedroom's entry holds its laptop and RackSpot (%d tagged)", #hub, hubStations, #entry.items))
	restore()

	return "T105A PLAY OK\n" .. table.concat(out, "\n") .. string.format("\nelapsed %.1f s", os.clock() - T0)
end

local ok, msg = pcall(run)
pcall(restore)
pcall(unseat)
pcall(teleport, LOUNGE) -- first, so the rebuild below never happens under the player
pcall(function() rooms:Invoke("Reset", uid) end)
pcall(function()
	wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
	test:Invoke("ResetHints", uid); ph:Invoke("Quiet", uid, false)
end)
if not ok then error(msg, 0) end
-- staging for t105b, after the cleanup: the player wakes up in their bedroom (the plot streamed in), with request j1
-- active so t105b's delivery at the player's own laptop gets past the request check to the station check
assert(rooms:Invoke("WakeUp", uid) == true, "tail: WakeUp returned false")
assert(test:Invoke("SetActiveRequest", uid, "j1") == true, "tail: SetActiveRequest(j1) failed")
return msg
