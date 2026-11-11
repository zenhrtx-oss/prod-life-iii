-- Client, during play (Wave 1b Task 5; Review Focus 1), after t64e's tail: the player at the studio PC spot and
-- rookie_block walking in. (1) The client sits at the studio PC (t57b's prompt), which opens the beat maker and seats
-- you in Chair_Seat. (2) He arrives and his card waits behind the beat maker (Deferred, Open false); the chip's tap
-- (Command "open") opens it over the beat maker. (3) Choice 3 (a sure loss: cold) plays one Loss, and LastReaction is
-- "skip:seated": a seat holds you, which wins over skip:daw (the beat maker is up) and skip:r6. Through 2.5 s after the
-- result (past the reaction's 2 s release) the beat maker stays open, hum.SeatPart is still the chair and you still
-- sit. (4) The beat maker closes and you stand up, as t57d does. Everything this file changed is set back (the beat
-- maker closed, standing, the camera Custom, the result card hidden).
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character; local root = char:WaitForChild("HumanoidRootPart", 5); local hum = char:WaitForChild("Humanoid", 5); local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui", 10)
local wg = pg:WaitForChild("OK_WalkIn", 10); assert(wg, "no OK_WalkIn gui (WalkInUI.Build did not run?)")
local ui = pg:WaitForChild("OK_UI", 10); assert(ui, "no OK_UI")
local daw = pg:WaitForChild("OK_DAW", 10):WaitForChild("DAW", 10); assert(daw, "no beat maker gui")
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function sounds() return tonumber(ui:GetAttribute("Sounds")) or 0 end
local CARD, PICK, KEY = "rookie_block", 3, "cold"
local card = wg:FindFirstChild("Card", true); assert(card, "the walk-in Card frame is missing")
local chair = workspace.OKStudio.ControlRoom:FindFirstChild("Chair_Seat"); assert(chair, "no Chair_Seat in the control room")
-- never inherit a forced size or an open beat maker from an earlier failed run
wg:SetAttribute("ForceViewport", nil); ui:SetAttribute("ForceViewport", nil)
daw:SetAttribute("CompactForced", nil); daw:SetAttribute("ViewportOverride", nil)
if daw.Visible then daw:SetAttribute("Command", "close"); task.wait(0.4) end
if hum.Sit then hum.Sit = false; task.wait(0.4) end
cam.CameraType = Enum.CameraType.Custom
local out = {}

-- the beat maker at the studio PC, opened the way t57b opens it, and closed the way t57d closes it
local screen = workspace.OKStudio.ControlRoom.Screen_Main
local PC = Vector3.new(72.0, 3.5, -5.5)
local function openBeatMaker(where)
	if hum.Sit then hum.Sit = false; task.wait(0.4) end
	root.CFrame = CFrame.lookAt(PC, Vector3.new(screen.Position.X, PC.Y, screen.Position.Z)); task.wait(1.0)
	cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(PC + Vector3.new(-4, 3, 0), screen.Position); task.wait(1.5)
	local prompt = screen:FindFirstChildWhichIsA("ProximityPrompt", true)
	for _ = 1, 4 do prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); task.wait(0.8); if daw.Visible then break end end
	assert(daw.Visible, "beat maker did not open " .. where)
end
local function closeBeatMaker()
	daw:SetAttribute("Command", "close")
	assert(waitFor(function() return not daw.Visible end, 3), "beat maker did not close")
	if hum.Sit then hum.Sit = false end
	cam.CameraType = Enum.CameraType.Custom
end

local function run()
	-- 1. sit at the studio PC: the beat maker opens and the chair holds you
	openBeatMaker("at the studio PC")
	assert(waitFor(function() return hum.SeatPart == chair end, 2), "the studio PC did not seat you in Chair_Seat (SeatPart "
		.. tostring(hum.SeatPart) .. ", Sit " .. tostring(hum.Sit) .. ")")
	table.insert(out, "seated at the studio PC: the beat maker is open, SeatPart Chair_Seat")

	-- 2. he arrives; his card waits behind the beat maker; the chip's tap opens it over the beat maker
	assert(waitFor(function() return (wg:GetAttribute("Token") or "") ~= "" end, 20), "no visitor arrived within 20 s")
	task.wait(0.5) -- one deferral check
	assert(wg:GetAttribute("Card") == CARD, "the waiting card is '" .. tostring(wg:GetAttribute("Card")) .. "', not t64e's " .. CARD)
	assert(wg:GetAttribute("Deferred") == true and wg:GetAttribute("Open") == false and not card.Visible, "the card is not waiting behind the beat maker (Deferred "
		.. tostring(wg:GetAttribute("Deferred")) .. ", Open " .. tostring(wg:GetAttribute("Open")) .. ")")
	wg:SetAttribute("Command", "open")
	assert(waitFor(function() return wg:GetAttribute("Open") == true and card.Visible end, 1), "the chip's tap did not open the card over the beat maker")
	assert(daw.Visible and hum.SeatPart == chair, "opening the card closed the beat maker or stood you up")
	table.insert(out, CARD .. " arrived and waited behind the beat maker; Command open showed it over the beat maker")

	-- 3. choice 3: one Loss, skip:seated; nothing moves through the reaction's 2 s
	local s0 = sounds()
	ui:SetAttribute("LastReaction", "")
	wg:SetAttribute("ResultKey", ""); wg:SetAttribute("LastChoose", "")
	wg:SetAttribute("Command", "choose:" .. PICK)
	assert(waitFor(function() return wg:GetAttribute("ResultKey") == KEY end, 6), "choice " .. PICK .. " (sure): ResultKey '"
		.. tostring(wg:GetAttribute("ResultKey")) .. "', LastChoose '" .. tostring(wg:GetAttribute("LastChoose")) .. "', want " .. KEY)
	local tRes = os.clock()
	assert(waitFor(function() return ui:GetAttribute("LastReaction") == "skip:seated" end, 1), "LastReaction '" .. tostring(ui:GetAttribute("LastReaction"))
		.. "' within 1 s of the result, want 'skip:seated' (it wins over skip:daw and skip:r6)")
	assert(waitFor(function() return ui:GetAttribute("LastSound") == "Loss" and sounds() == s0 + 1 end, 1), "within 1 s of the result: LastSound '"
		.. tostring(ui:GetAttribute("LastSound")) .. "', " .. (sounds() - s0) .. " new sounds, want one Loss")
	while os.clock() - tRes < 2.5 do
		assert(daw.Visible, string.format("the beat maker closed %.1f s after the loss", os.clock() - tRes))
		assert(hum.SeatPart == chair and hum.Sit, string.format("%.1f s after the loss you no longer sit in the chair (SeatPart %s, Sit %s)",
			os.clock() - tRes, tostring(hum.SeatPart), tostring(hum.Sit)))
		task.wait(0.1)
	end
	table.insert(out, "choice " .. PICK .. ": " .. KEY .. ", one Loss; LastReaction 'skip:seated'; for 2.5 s the beat maker stayed open and SeatPart stayed Chair_Seat")

	-- 4. close the beat maker and stand up
	closeBeatMaker()
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
return "T64F PLAY OK\n" .. table.concat(out, "\n")
