-- Client, during play (the Your Rooms plan, R-T16 fix, I1: decorate mode yields to the beat maker and to cards; preflight
-- F3: the client's half), after t109c's tail: the player woke up in their bedroom, and the server opens the bedroom laptop's
-- beat maker at this client's second Room_Get after its next decorate push (the rooms hook's OnDecorate). Every step waits
-- for its state (an attribute, a property, a server answer) with a timeout, never for a fixed time or a frame count.
-- The stand spot: 3 studs into the room from the Entrance, toward the laptop (the walkway: its keep area holds no item),
-- within the DecoratePrompt's reach of the door and within DAWConfig.CloseDistance of the laptop (both checked: the beat
-- maker hides past that distance from its source).
-- (1) The beat maker over decorate mode. The DecoratePrompt pressed (InputHoldBegin / End, as t109b) -> Editing. The knock
--     (Room_Get, called by this file once it reads Editing) -> the server's RunStation opens the beat maker (PlayerGui.OK_DAW.DAW
--     Visible) -> decorate mode ends: LeftBy "daw", Editing false, the bar hidden, the camera Custom, the controls back
--     (ControlsOn), and the prompts stay OFF while the beat maker is up (ProximityPromptService.Enabled false: DAWClient owns
--     them; before the fix decorate mode's leave put its saved "on" back under the open window). Closed through the beat
--     maker's own close (its Command "close": DAWUI's Hide, what the Backspace / ButtonB action runs) -> the window hidden and
--     the prompts back ON (DAWClient's restore).
-- (2) A card over decorate mode. In again by the prompt (Editing); PlayerGui.OK_WalkIn's Open set true (the attribute WalkInUI
--     sets when a walk-in or Day One card opens) -> decorate mode ends: LeftBy "card", Editing false, the prompts back on (PPS
--     true: decorate mode's saved state), the controls back and the camera Custom. Open put back.
-- (3) No decorate mode under a card. OK_Room's Refused cleared, OK_WalkIn's Open true, the DecoratePrompt pressed -> Refused
--     "card" and Editing still false (RoomClient's enter refuses, as it does under the beat maker). Open put back.
-- On any error, and after success: OK_WalkIn's Open put back, the beat maker closed, decorate mode left (DONE), the camera
-- Custom, the character moved to the lounge; then the error is rethrown.
-- The expected reds, before the R-T16 fix sync of OK/RoomClient (and of Systems/Rooms for t109c's arm): (1) "1: the beat maker
-- opened over decorate mode and decorate mode stayed on (Editing true, LeftBy ...)"; with the old leave(), had it left, the
-- prompts would read on under the window; (2) "2: a card opening (OK_WalkIn's Open) did not end decorate mode (Editing true,
-- LeftBy ...)"; (3) "3: a decorate press under an open card was not refused (Refused '', Editing true)".
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character
local root = char and char:WaitForChild("HumanoidRootPart", 5)
local hum = char and char:WaitForChild("Humanoid", 5)
assert(root and hum, "no live character")
local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui", 10)
local gui = pg and pg:WaitForChild("OK_Room", 10)
assert(gui, "no PlayerGui.OK_Room (RoomUI.Build did not run)")
local bar = gui:WaitForChild("Root", 5) and gui.Root:WaitForChild("Bar", 5)
assert(bar, "OK_Room has no Root.Bar")
local dawGui = pg:WaitForChild("OK_DAW", 10)
local daw = dawGui and dawGui:WaitForChild("DAW", 10)
assert(daw, "no beat maker gui (PlayerGui.OK_DAW.DAW)")
local card = pg:WaitForChild("OK_WalkIn", 10)
assert(card, "no PlayerGui.OK_WalkIn (WalkInUI did not build)")
local DAWCfg = require(RS.OK.Modules.DAWConfig)
local RoomGet = RS.OK.Remotes:WaitForChild("Room_Get", 5)
assert(RoomGet, "no Remotes.Room_Get")
local LOUNGE = Vector3.new(24, 3, 0)
local RED = " (before the R-T16 fix sync of OK/RoomClient: the expected red)"
local out = {}
local openBefore = card:GetAttribute("Open")

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function str(v) return string.format("(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z) end
local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function attr(name) return gui:GetAttribute(name) end
local function rootNow() return player.Character and player.Character:FindFirstChild("HumanoidRootPart") end
local function where() return "Editing " .. tostring(attr("Editing")) .. ", LeftBy " .. tostring(attr("LeftBy")) .. ", Refused " .. tostring(attr("Refused"))
	.. ", the beat maker " .. (daw.Visible and "open" or "closed") .. ", prompts " .. (PPS.Enabled and "on" or "off") .. ", ControlsOn " .. tostring(attr("ControlsOn")) end

local bedroom, door, decor, station, stand
local function find()
	local slot
	assert(waitFor(function() slot = player:GetAttribute("PlotSlot"); return type(slot) == "number" and slot > 0 end, 3), "PlotSlot is " .. tostring(slot) .. " (t109c's tail wakes the player up in their bedroom)")
	local plots = workspace:WaitForChild("OK_Plots", 5)
	assert(plots, "Workspace.OK_Plots is not on this client")
	local name = string.format("Plot_%02d", slot)
	assert(waitFor(function()
		local pm = plots:FindFirstChild(name)
		bedroom = pm and pm:FindFirstChild("Room_bedroom")
		if not bedroom then return false end
		door, station = nil, nil
		for _, d in ipairs(bedroom:GetDescendants()) do
			if d:IsA("BasePart") and d:GetAttribute("RoomDoor") == true then door = d end
			if d:IsA("BasePart") and d:GetAttribute("Kind") == "Station" then station = d end
		end
		decor = door and door:FindFirstChild("DecoratePrompt")
		return decor ~= nil and station ~= nil
	end, 5), name .. ".Room_bedroom (with its door's DecoratePrompt and its laptop) is not on this client")
	local entrance
	for _, d in ipairs(bedroom:GetDescendants()) do if d:IsA("Attachment") and d.Name == "Entrance" then entrance = d; break end end
	assert(entrance, "the bedroom has no Entrance attachment")
	-- 3 studs in from the Entrance, toward the laptop
	local e = entrance.WorldPosition
	local toward = Vector3.new(station.Position.X - e.X, 0, station.Position.Z - e.Z)
	stand = e + toward.Unit * 3 + Vector3.new(0, 3, 0)
	local dDoor, dLaptop = (stand - door.Position).Magnitude, (stand - station.Position).Magnitude
	assert(dDoor < decor.MaxActivationDistance - 0.5, string.format("premise: the stand spot %s is %.1f studs from the door, past the DecoratePrompt's reach %.1f", str(stand), dDoor, decor.MaxActivationDistance))
	assert(dLaptop < DAWCfg.CloseDistance - 1, string.format("premise: the stand spot %s is %.1f studs from the laptop: the beat maker hides past %.1f", str(stand), dLaptop, DAWCfg.CloseDistance))
	return name, dDoor, dLaptop
end
-- stand at the spot facing the door, the camera Scriptable and aimed at it (as t109b), then press the DecoratePrompt until
-- `done` holds (each press waits for it at most 5 s, so a slow client's first press is never pressed again while its decorate
-- mode is still fetching, which would spend t109c's knock early; the server ignores a press within 0.25 s of the last: M1)
local function press(label, done, keepCamera)
	local r = rootNow()
	r.CFrame = CFrame.lookAt(stand, Vector3.new(door.Position.X, stand.Y, door.Position.Z))
	assert(waitFor(function() local rr = rootNow(); return rr ~= nil and flat(rr.Position - stand) < 1 end, 3), label .. ": the character did not stay at the stand spot")
	if not keepCamera then
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = CFrame.lookAt(stand + Vector3.new(0, 2, 0) - (door.Position - stand) * Vector3.new(1, 0, 1) * 0.4, door.Position)
	end
	assert(waitFor(function() return decor.Enabled and PPS.Enabled end, 3), label .. ": the DecoratePrompt (or every prompt) is off before the press: " .. where())
	for _ = 1, 4 do
		decor:InputHoldBegin(); task.wait(0.05); decor:InputHoldEnd()
		if waitFor(done, 5) then return true end
	end
	return false
end

local function run()
	assert(not daw.Visible and attr("Editing") ~= true, "premise: the beat maker is open or decorate mode is on at the start: " .. where())
	local name, dDoor, dLaptop = find()

	-- 1. the beat maker over decorate mode
	assert(press("1", function() return attr("Editing") == true end), "1: pressing the DecoratePrompt did not put the client in decorate mode: " .. where())
	assert(PPS.Enabled == false, "1: decorate mode is on with the prompts on")
	local okKnock, knock = pcall(function() return RoomGet:InvokeServer() end) -- the knock: t109c's armed RunStation runs at this call
	assert(okKnock and type(knock) == "table", "1: the knock (Room_Get) failed: " .. tostring(knock))
	assert(waitFor(function() return daw.Visible end, 8), "1: the beat maker did not open after the knock (t109c's OnDecorate arm: before the R-T16 fix sync of Systems/Rooms it is never armed): " .. where())
	assert(waitFor(function() return attr("Editing") == false and attr("LeftBy") == "daw" end, 4),
		"1: the beat maker opened over decorate mode and decorate mode stayed on: " .. where() .. RED)
	assert(daw.Visible, "1: the beat maker closed by itself (the stand spot is " .. string.format("%.1f", dLaptop) .. " studs from its laptop)")
	assert(PPS.Enabled == false, "1: decorate mode left for the beat maker and turned the prompts back on under its open window: " .. where() .. RED)
	assert(not bar.Visible, "1: the edit bar still shows under the beat maker")
	assert(waitFor(function() return cam.CameraType == Enum.CameraType.Custom end, 3), "1: the camera is " .. tostring(cam.CameraType) .. " after decorate mode left for the beat maker, want Custom")
	assert(waitFor(function() return attr("ControlsOn") == true end, 3), "1: the controls are not back (ControlsOn " .. tostring(attr("ControlsOn")) .. ")")
	daw:SetAttribute("Command", "close") -- DAWUI's Hide: what the Backspace / ButtonB action (OK_DAW_Close) runs
	assert(waitFor(function() return not daw.Visible end, 4), "1: the beat maker did not close on its own close (its Command 'close')")
	assert(waitFor(function() return PPS.Enabled == true end, 3), "1: the prompts are still off after the beat maker closed: " .. where())
	table.insert(out, string.format("1 %s's bedroom, %.1f studs from the door and %.1f from the laptop: decorate mode on; the knock opened the beat maker (RunStation) -> LeftBy daw, Editing off, the bar hidden, the camera Custom, the controls back, the prompts OFF under the window; its close -> the prompts on",
		name, dDoor, dLaptop))

	-- 2. a card over decorate mode
	assert(press("2", function() return attr("Editing") == true end), "2: pressing the DecoratePrompt did not put the client in decorate mode again: " .. where())
	card:SetAttribute("Open", true) -- the attribute WalkInUI sets when a walk-in or Day One card opens
	assert(waitFor(function() return attr("Editing") == false and attr("LeftBy") == "card" end, 4), "2: a card opening (OK_WalkIn's Open) did not end decorate mode: " .. where() .. RED)
	assert(waitFor(function() return PPS.Enabled == true end, 3), "2: the prompts are not back after decorate mode left for the card: " .. where())
	assert(waitFor(function() return cam.CameraType == Enum.CameraType.Custom and attr("ControlsOn") == true end, 3), "2: after the card the camera is " .. tostring(cam.CameraType)
		.. " and ControlsOn " .. tostring(attr("ControlsOn")) .. ", want Custom and true")
	assert(not bar.Visible, "2: the edit bar still shows under the card")
	card:SetAttribute("Open", openBefore == true)
	table.insert(out, "2 a card (OK_WalkIn's Open) over decorate mode: LeftBy card, Editing off, the prompts, the controls and the camera back, the bar hidden")

	-- 3. no decorate mode under a card
	gui:SetAttribute("Refused", "")
	card:SetAttribute("Open", true)
	-- keepCamera: case 3 never enters decorate mode, so nothing would put a Scriptable camera back as decorate mode's
	-- leave() does; a camera this test made Scriptable and only set back to Custom left the client showing no prompt at all
	-- afterwards (11-13: t111b/d's laptop presses then sent nothing; bisected to this press; a test artifact, since
	-- decorate mode's own camera cycle, cases 1 and 2, leaves the prompts working)
	local refused = press("3", function() return attr("Refused") == "card" or attr("Editing") == true end, true)
	card:SetAttribute("Open", openBefore == true)
	assert(refused and attr("Refused") == "card" and attr("Editing") ~= true, "3: a decorate press under an open card was not refused: " .. where() .. RED)
	table.insert(out, "3 a decorate press under an open card: refused (Refused card), Editing stays off")

	return "T109D PLAY OK\n" .. table.concat(out, "\n")
end

local ok, msg = pcall(run)
pcall(function() card:SetAttribute("Open", openBefore == true) end)
pcall(function() if daw.Visible then daw:SetAttribute("Command", "close"); waitFor(function() return not daw.Visible end, 3) end end)
pcall(function()
	if gui:GetAttribute("Editing") == true then
		gui:SetAttribute("Command", "done")
		waitFor(function() return gui:GetAttribute("Editing") == false end, 3)
	end
end)
-- the camera back as decorate mode's leave() puts it: Custom AND its subject the humanoid. Case 3 never enters decorate
-- mode, so only this restores the Scriptable camera press() set; with CameraType alone the client's prompts stopped
-- showing (no PromptShown, so InputHoldBegin on a laptop sent nothing) until something reset the camera properly:
-- t111b/d failed after this file (found 11-13 by bisecting t109d's cases; masked in the full suite by t10_play/t10b/t10c)
pcall(function()
	cam.CameraType = Enum.CameraType.Custom
	local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if h then cam.CameraSubject = h end
end)
pcall(function()
	local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if h and h.Sit then h.Sit = false; task.wait(0.4) end
	if r then r.CFrame = CFrame.new(LOUNGE) end
end)
if not ok then error(msg, 0) end
return msg
