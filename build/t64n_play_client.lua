-- Client, during play (Wave 1b Task H; Review Focus 1), after t64m's tail: the player standing at the studio PC spot and
-- rookie_block walking in. The studio PC used from the loss reaction's floor sit opens the beat maker as a laptop's
-- (the chair can't take a humanoid already sitting on the floor: DAW.OpenFor's seated is the chair's Occupant), so the
-- reaction's release never closes it. (1) Standing at the studio PC, facing Screen_Main with the camera on it (t64f's
-- prompt pattern), the beat maker closed. (2) His card opens by itself. (3) Standing still on the floor, choice 3 (a
-- sure loss: cold) gives LastReaction "sit": hum.Sit true with no SeatPart; 0.3 s more lets that Sit reach the server.
-- (4) Within 1 s of the result the PC prompt is triggered (InputHoldBegin/End, retried every 0.25 s up to 1 s), and
-- the beat maker opens while you still sit on the floor (SeatPart nil: the chair didn't take you). (5) Through 2.5 s
-- after the result (past the reaction's 2 s release) the beat maker stays open; at 2.5 s LastReaction is still "sit",
-- hum.Sit is false (the release stood you up) and the beat maker is in laptop mode (OK_DAW.DAW's Seated false). (6) The
-- beat maker closes and you stand, as t64f does. The test avatar must be R15 (Task 0's P1): R6 never sits. Everything
-- this file changed is set back (the beat maker closed, standing, the camera Custom, the result card hidden).
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character; local root = char:WaitForChild("HumanoidRootPart", 5); local hum = char:WaitForChild("Humanoid", 5); local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui", 10)
local wg = pg:WaitForChild("OK_WalkIn", 10); assert(wg, "no OK_WalkIn gui (WalkInUI.Build did not run?)")
local ui = pg:WaitForChild("OK_UI", 10); assert(ui, "no OK_UI")
local daw = pg:WaitForChild("OK_DAW", 10):WaitForChild("DAW", 10); assert(daw, "no beat maker gui")
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local AIRBORNE = { [Enum.HumanoidStateType.Jumping] = true, [Enum.HumanoidStateType.Freefall] = true, [Enum.HumanoidStateType.GettingUp] = true }
local function standing() return hum.FloorMaterial ~= Enum.Material.Air and not AIRBORNE[hum:GetState()] and not hum.Sit and hum.SeatPart == nil end
local CARD, PICK, KEY = "rookie_block", 3, "cold"
local R15 = hum.RigType == Enum.HumanoidRigType.R15
local chair = workspace.OKStudio.ControlRoom:FindFirstChild("Chair_Seat"); assert(chair, "no Chair_Seat in the control room")
local screen = workspace.OKStudio.ControlRoom.Screen_Main
local prompt = screen:FindFirstChildWhichIsA("ProximityPrompt", true); assert(prompt, "no ProximityPrompt on Screen_Main")
local PC = Vector3.new(72.0, 3.5, -5.5)
-- never inherit a forced size or an open beat maker from an earlier failed run
wg:SetAttribute("ForceViewport", nil); ui:SetAttribute("ForceViewport", nil)
daw:SetAttribute("CompactForced", nil); daw:SetAttribute("ViewportOverride", nil)
local dawClosed = -math.huge
if daw.Visible then daw:SetAttribute("Command", "close"); dawClosed = os.clock(); task.wait(0.4) end
if hum.Sit then hum.Sit = false; task.wait(0.4) end
cam.CameraType = Enum.CameraType.Custom
local out = {}

local function run()
	assert(R15, "the test avatar is " .. tostring(hum.RigType) .. ": only R15 sits on a loss (Task 0's P1), and this case needs the sit")
	-- 1. standing at the studio PC, facing Screen_Main, the camera on it (t64f's prompt pattern), the beat maker closed
	root.CFrame = CFrame.lookAt(PC, Vector3.new(screen.Position.X, PC.Y, screen.Position.Z)); task.wait(1.0)
	cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(PC + Vector3.new(-4, 3, 0), screen.Position); task.wait(1.5)

	-- 2. his card opens by itself
	assert(waitFor(function() return wg:GetAttribute("Open") == true end, 20), "the card did not open within 20 s (Token '"
		.. tostring(wg:GetAttribute("Token")) .. "', Deferred " .. tostring(wg:GetAttribute("Deferred")) .. ")")
	assert(wg:GetAttribute("Card") == CARD, "the open card is '" .. tostring(wg:GetAttribute("Card")) .. "', not t64m's " .. CARD)
	assert(not daw.Visible, "the beat maker is open before the choice")
	table.insert(out, CARD .. " arrived at the studio PC and his card opened by itself")

	-- 3. standing still on the floor (and clear of any beat maker this file closed), choice 3: the floor sit
	assert(waitFor(function() return os.clock() - dawClosed > 1.3 and standing() end, 4), "not standing still on the floor before the choice (Floor "
		.. tostring(hum.FloorMaterial) .. ", State " .. tostring(hum:GetState()) .. ", Sit " .. tostring(hum.Sit) .. ")")
	ui:SetAttribute("LastReaction", "")
	wg:SetAttribute("ResultKey", ""); wg:SetAttribute("LastChoose", "")
	wg:SetAttribute("Command", "choose:" .. PICK)
	assert(waitFor(function() return wg:GetAttribute("ResultKey") == KEY end, 6), "choice " .. PICK .. " (sure): ResultKey '"
		.. tostring(wg:GetAttribute("ResultKey")) .. "', LastChoose '" .. tostring(wg:GetAttribute("LastChoose")) .. "', want " .. KEY)
	local tRes = os.clock()
	assert(waitFor(function() return ui:GetAttribute("LastReaction") == "sit" and hum.Sit and hum.SeatPart == nil end, 0.5), "within 0.5 s of the loss:"
		.. " LastReaction '" .. tostring(ui:GetAttribute("LastReaction")) .. "', Sit " .. tostring(hum.Sit) .. ", SeatPart " .. tostring(hum.SeatPart)
		.. " (want 'sit' on the floor)")
	task.wait(0.3) -- the seatless Sit reaches the server before its seat:Sit runs (Task 0's P3: it seats in 0.06 s)

	-- 4. within 1 s of the result, still on the floor: the PC prompt opens the beat maker
	local tPrompt, tries = os.clock() - tRes, 0
	repeat
		prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); tries += 1
		waitFor(function() return daw.Visible end, 0.2)
	until daw.Visible or os.clock() - tRes >= 1.0
	assert(waitFor(function() return daw.Visible end, math.max(0.1, 1.8 - (os.clock() - tRes))), string.format("the PC prompt (%d tries from %.2f s"
		.. " after the loss) did not open the beat maker by %.1f s, while you sat on the floor", tries, tPrompt, os.clock() - tRes))
	local openedAt = os.clock() - tRes
	assert(hum.SeatPart == nil, string.format("the beat maker opened %.2f s after the loss with SeatPart %s: the chair took you, so the floor sit"
		.. " hadn't reached the server and this case tests nothing", openedAt, tostring(hum.SeatPart)))
	table.insert(out, string.format("the PC prompt (%d tries from %.2f s after the loss) opened the beat maker %.2f s after it, Sit %s, SeatPart nil",
		tries, tPrompt, openedAt, tostring(hum.Sit)))

	-- 5. past the reaction's 2 s release: the beat maker stays open, the release stood you up, laptop mode
	while os.clock() - tRes < 2.5 do
		assert(daw.Visible, string.format("the beat maker closed %.1f s after the loss (opened at %.2f s, Seated %s, Sit %s)", os.clock() - tRes,
			openedAt, tostring(daw:GetAttribute("Seated")), tostring(hum.Sit)))
		task.wait(0.1)
	end
	assert(ui:GetAttribute("LastReaction") == "sit", "LastReaction '" .. tostring(ui:GetAttribute("LastReaction")) .. "' 2.5 s after the loss, want 'sit'")
	assert(not hum.Sit, "you still sit 2.5 s after the loss (SeatPart " .. tostring(hum.SeatPart) .. ", Seated " .. tostring(daw:GetAttribute("Seated")) .. ")")
	assert(daw:GetAttribute("Seated") ~= true, "the beat maker is in seated mode (Seated true) with no chair holding you: DAW said seated")
	table.insert(out, string.format("at 2.5 s the beat maker is still open in laptop mode (Seated %s), LastReaction 'sit', Sit false",
		tostring(daw:GetAttribute("Seated"))))

	-- 6. close the beat maker and stand up
	daw:SetAttribute("Command", "close")
	assert(waitFor(function() return not daw.Visible end, 3), "beat maker did not close")
	if hum.Sit then hum.Sit = false end
	cam.CameraType = Enum.CameraType.Custom
	table.insert(out, "beat maker closed, standing")
end

local ok, err = pcall(run)
if daw.Visible then daw:SetAttribute("Command", "close"); task.wait(0.4) end
if hum.Sit then hum.Sit = false end
cam.CameraType = Enum.CameraType.Custom
if wg:GetAttribute("Open") == true then wg:SetAttribute("Command", "walkaway"); task.wait(0.3) end
wg:SetAttribute("Command", "ok") -- hide the result card
waitFor(function() return not hum.Sit end, 3)
if not ok then error(err, 0) end
return "T64N PLAY OK\n" .. table.concat(out, "\n")
