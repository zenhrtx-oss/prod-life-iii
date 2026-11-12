-- Client, during play (the Your Rooms plan, Task 2; Review Focus 5), after t101a's tail: the player woke up in their
-- bedroom, and the server will run the bedroom's exit 2 s after this player's beat maker next opens at a laptop in a
-- plot (the rooms hook's OnOpen). Every step waits for its state, with a timeout:
-- (1) streaming: the plot's bedroom (Workspace.OK_Plots.Plot_<PlotSlot>.Room_bedroom, with its Spawn and Station) is on
--     this client (it streamed in with the tail's wake-up, RequestStreamAroundAsync; awaited at most 3 s from this
--     file's start: presence, not a load time), and InPlot reads the slot.
-- (2) the laptop: standing beside the chair (room-local (2, 0, -3)), pressing the Station's prompt (InputHoldBegin / End,
--     as t19b) opens the beat maker: the clone's Station is hooked like the hub's (InteractionService.Adopt).
-- (3) the server's door move: within 6 s the window is gone (DAWClient's CloseDistance: the landing is ~19 studs from the
--     laptop), the player stands on the plot's landing, and InPlot still reads the slot.
-- (4) the way in and out through the real prompts (InputHoldBegin / End, as t19b and t44), each move awaited, each press
--     made where that prompt is the nearest on its key: the landing's bedroom RoomPrompt -> the bedroom's Spawn; the
--     bedroom door's ExitPrompt -> the landing outside it (Out); the landing's LeavePrompt -> in front of the player's hall
--     door (Front), InPlot 0; that door's EnterPrompt -> just inside the landing's front door (Inside), InPlot the slot;
--     LeavePrompt again; the hall's HubPrompt -> the corridor (RoomsDoor.Front: in the hub, InPlot 0); the corridor's
--     RoomsPrompt -> HallSpawn; HubPrompt again -> the corridor. Then the character goes to the lounge.
-- On any error the camera is given back and the character is moved to the lounge before the rethrow.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character
local root = char and char:WaitForChild("HumanoidRootPart", 5)
local hum = char and char:WaitForChild("Humanoid", 5)
assert(root and hum, "no live character")
local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui", 10)
local dawGui = pg and pg:WaitForChild("OK_DAW", 10)
local daw = dawGui and dawGui:WaitForChild("DAW", 10)
assert(daw, "no beat maker gui (PlayerGui.OK_DAW.DAW)")
local Config = require(RS.OK.Config)
local RoomRules = require(RS.OK.Modules.RoomRules)
local WalkInRules = require(RS.OK.Modules.WalkInRules)
local LOUNGE = Vector3.new(24, 3, 0)
local out = {}
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function str(v) return string.format("(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z) end

local function run()
	-- 1. the plot has streamed in, and InPlot reads the slot
	local slot = player:GetAttribute("PlotSlot")
	assert(waitFor(function() slot = player:GetAttribute("PlotSlot"); return type(slot) == "number" and slot > 0 end, 3),
		"PlotSlot is " .. tostring(slot) .. ", want the player's slot (t101a's tail wakes the player up in slot 1)")
	local plots = workspace:WaitForChild("OK_Plots", 5)
	assert(plots, "Workspace.OK_Plots is not on this client")
	local name = string.format("Plot_%02d", slot)
	local bedroom, station, spawn
	local s0 = os.clock()
	local got = waitFor(function()
		local pm = plots:FindFirstChild(name)
		bedroom = pm and pm:FindFirstChild("Room_bedroom")
		if not bedroom then return false end
		spawn = bedroom:FindFirstChild("Spawn", true)
		station = nil
		for _, d in ipairs(bedroom:GetDescendants()) do
			if d:IsA("BasePart") and d:GetAttribute("Kind") == "Station" then station = d; break end
		end
		return spawn ~= nil and station ~= nil
	end, 3)
	assert(got, name .. ".Room_bedroom (with its Spawn and Station) is not on this client 3 s into the test (t101a's tail woke the player up in it)")
	local streamed = os.clock() - s0
	assert(waitFor(function() return player:GetAttribute("InPlot") == slot end, 3),
		"InPlot reads " .. tostring(player:GetAttribute("InPlot")) .. " in the bedroom, want " .. slot)
	table.insert(out, string.format("1 %s.Room_bedroom on this client (present %.2f s into the test), InPlot %d", name, streamed, slot))

	-- 2. the bedroom's laptop opens the beat maker
	assert(not daw.Visible, "the beat maker is already open before the laptop's prompt is pressed")
	local prompt = station:FindFirstChildWhichIsA("ProximityPrompt")
	assert(prompt and prompt.Enabled, "the bedroom's Station has no enabled prompt")
	-- room-local (2, 0, -3): clear floor beside the chair and in front of the desk, in the asset and the stand-in alike
	local stand = (bedroom:GetPivot() * CFrame.new(2, 0, -3)).Position
	if hum.Sit then hum.Sit = false; task.wait(0.4) end
	local pos = stand + Vector3.new(0, 3, 0)
	assert((pos - station.Position).Magnitude < prompt.MaxActivationDistance - 1, string.format(
		"the stand spot %s is %.1f studs from the laptop, past its prompt's reach %.1f", str(pos), (pos - station.Position).Magnitude, prompt.MaxActivationDistance))
	root.CFrame = CFrame.lookAt(pos, Vector3.new(station.Position.X, pos.Y, station.Position.Z)); task.wait(1.0)
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.lookAt(pos + Vector3.new(0, 2.5, 0) + (pos - station.Position) * Vector3.new(1, 0, 1) * 0.3, station.Position)
	task.wait(1.0)
	local opened = false
	for _ = 1, 4 do
		prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd()
		if waitFor(function() return daw.Visible end, 1.2) then opened = true; break end
	end
	cam.CameraType = Enum.CameraType.Custom
	assert(opened, "the beat maker did not open from the bedroom laptop's prompt (the clone's Station should be hooked by InteractionService.Adopt)")
	local at = os.clock()
	table.insert(out, "2 the bedroom laptop's prompt opens the beat maker")

	-- 3. the server's door move closes it
	local closed = waitFor(function() return not daw.Visible end, 6)
	local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	assert(closed, "the beat maker is still open 6 s after it opened at the bedroom laptop: the server's door move (t101a's tail)"
		.. " should have put the player on the landing and closed it (DAWClient CloseDistance); the player is at " .. (r and str(r.Position) or "?"))
	local ox, _, oz = RoomRules.PlotOrigin(slot, Config.Rooms)
	local onLanding = waitFor(function()
		r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		return r ~= nil and r.Position.X >= ox and r.Position.X <= ox + Config.Rooms.Landing.length
			and r.Position.Z >= oz and r.Position.Z <= oz + Config.Rooms.Landing.width
	end, 3)
	assert(onLanding, "after the door move the player is at " .. (r and str(r.Position) or "?") .. ", want the landing (x " .. ox .. ".." .. (ox + Config.Rooms.Landing.length) .. ", z " .. oz .. ".." .. (oz + Config.Rooms.Landing.width) .. ")")
	assert(waitFor(function() return player:GetAttribute("InPlot") == slot end, 3), "on the landing InPlot reads " .. tostring(player:GetAttribute("InPlot")) .. ", want " .. slot)
	table.insert(out, string.format("3 the server's door move: the window closed %.1f s after it opened; on the landing at %s, InPlot %d", os.clock() - at, str(r.Position), slot))

	-- 4. the way in and out through the real prompts
	task.wait(1) -- the server's move has settled (it checks its pivot once, 0.25 s after)
	local plot = plots:FindFirstChild(name)
	local landing = plot and plot:FindFirstChild("Landing")
	assert(landing, name .. ".Landing is not on this client")
	local roomsM = workspace:FindFirstChild("OK_Rooms")
	local hallM = roomsM and roomsM:FindFirstChild("Hall")
	local rd = roomsM and roomsM:FindFirstChild("RoomsDoor")
	assert(hallM and rd, "Workspace.OK_Rooms (Hall, RoomsDoor) is not on this client")
	local bedDoor
	for _, d in ipairs(bedroom:GetDescendants()) do if d:IsA("BasePart") and d:GetAttribute("RoomDoor") == true then bedDoor = d; break end end
	assert(bedDoor, "the bedroom has no RoomDoor part on this client")
	local hallDoor = hallM:FindFirstChild(string.format("Door_%02d", slot))
	local function rootNow() return player.Character and player.Character:FindFirstChild("HumanoidRootPart") end
	local function flat(a, b) return math.sqrt((a.X - b.X) ^ 2 + (a.Z - b.Z) ^ 2) end
	local function marker(parent, mname)
		local a = parent and parent:FindFirstChild(mname)
		assert(a and a:IsA("Attachment"), "no " .. mname .. " under " .. tostring(parent and parent:GetFullName()))
		return a.WorldPosition
	end
	-- this client moves its own character (it owns it) to a floor point, facing `toward`
	local function goTo(floorPos, toward)
		local rr = rootNow()
		local p0 = floorPos + Vector3.new(0, 3, 0)
		rr.CFrame = CFrame.lookAt(p0, Vector3.new(toward.X, p0.Y, toward.Z))
		task.wait(0.6)
	end
	-- press `part`'s prompt `pname` (up to 4 tries) until the player stands within 3 studs (flat) of `dest`
	local function press(part, pname, dest, label)
		local pp = part and part:FindFirstChild(pname)
		assert(pp and pp:IsA("ProximityPrompt") and pp.Enabled, label .. ": " .. pname .. " missing or off on " .. tostring(part and part:GetFullName()))
		local rr = rootNow()
		local d = rr and (rr.Position - part.Position).Magnitude or math.huge
		assert(d < pp.MaxActivationDistance, string.format("%s: standing %.1f studs from %s, past its prompt's reach %.1f", label, d, part.Name, pp.MaxActivationDistance))
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = CFrame.lookAt(rr.Position + Vector3.new(0, 2, 0), part.Position)
		local moved = false
		for _ = 1, 4 do
			pp:InputHoldBegin(); task.wait(0.05); pp:InputHoldEnd()
			if waitFor(function() local q = rootNow(); return q ~= nil and flat(q.Position, dest) < 3 end, 2.5) then moved = true; break end
		end
		cam.CameraType = Enum.CameraType.Custom
		local q = rootNow()
		assert(moved, label .. ": pressing " .. pname .. " did not move the player to " .. str(dest) .. "; at " .. (q and str(q.Position) or "?"))
		task.wait(0.6) -- the server's move settles (its pivot check; one move at a time)
	end
	local landingDoor = landing:FindFirstChild("Door_bedroom")
	local frontDoor = landing:FindFirstChild("FrontDoor")
	local outPos, insidePos = marker(landingDoor, "Out"), marker(frontDoor, "Inside")
	local hallFront, hallSpawn, corridorPos = marker(hallDoor, "Front"), hallM:FindFirstChild("HallSpawn").Position, marker(rd, "Front")
	goTo(outPos, landingDoor.Position)
	press(landingDoor, "RoomPrompt", spawn.Position, "the landing's bedroom door")
	goTo(spawn.Position, bedDoor.Position)
	press(bedDoor, "ExitPrompt", outPos, "the bedroom's door")
	goTo(insidePos, frontDoor.Position)
	press(frontDoor, "LeavePrompt", hallFront, "the landing's front door")
	assert(waitFor(function() return player:GetAttribute("InPlot") == 0 end, 3), "in the hall InPlot reads " .. tostring(player:GetAttribute("InPlot")) .. ", want 0")
	press(hallDoor, "EnterPrompt", insidePos, "the player's hall door")
	assert(waitFor(function() return player:GetAttribute("InPlot") == slot end, 3), "back on the landing InPlot reads " .. tostring(player:GetAttribute("InPlot")) .. ", want " .. slot)
	press(frontDoor, "LeavePrompt", hallFront, "the landing's front door, again")
	local hub = hallM:FindFirstChild("HubDoor")
	goTo(hallSpawn - Vector3.new(0, hallSpawn.Y, 0), hub.Position)
	press(hub, "HubPrompt", corridorPos, "the hall's HubDoor")
	local rr = rootNow()
	assert(WalkInRules.InHub(rr.Position.X, rr.Position.Y, rr.Position.Z), "the HubDoor left the player outside the hub: " .. str(rr.Position))
	assert(waitFor(function() return player:GetAttribute("InPlot") == 0 end, 3), "in the corridor InPlot reads " .. tostring(player:GetAttribute("InPlot")) .. ", want 0")
	goTo(corridorPos, rd.Position)
	press(rd, "RoomsPrompt", hallSpawn, "the corridor's RoomsDoor")
	goTo(hallSpawn - Vector3.new(0, hallSpawn.Y, 0), hub.Position)
	press(hub, "HubPrompt", corridorPos, "the hall's HubDoor, again")
	table.insert(out, "4 real prompts: RoomPrompt -> bedroom, ExitPrompt -> landing, LeavePrompt -> hall door " .. slot
		.. " (InPlot 0), EnterPrompt -> landing (InPlot " .. slot .. "), LeavePrompt, HubPrompt -> corridor (hub, InPlot 0), RoomsPrompt -> HallSpawn, HubPrompt -> corridor")
	rootNow().CFrame = CFrame.new(LOUNGE)
	assert(waitFor(function() return player:GetAttribute("InPlot") == 0 end, 3), "in the lounge InPlot reads " .. tostring(player:GetAttribute("InPlot")) .. ", want 0")
	return "T101B PLAY OK\n" .. table.concat(out, "\n")
end

local ok, msg = pcall(run)
pcall(function() cam.CameraType = Enum.CameraType.Custom end)
if not ok then
	pcall(function()
		local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if h and h.Sit then h.Sit = false; task.wait(0.4) end
		if r then r.CFrame = CFrame.new(LOUNGE) end
	end)
	error(msg, 0)
end
return msg
