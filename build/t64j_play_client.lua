-- Client, during play (Wave 1b Task 5; Review Focus 1), after t64i's tail: rookie_block walking in to the lounge. A
-- loss at the lounge-bar laptop, which opens the beat maker with no chair. (1) The laptop opens by its Station prompt
-- (t19b's pattern): the beat maker is up and you don't sit. (2) He arrives and his card waits behind the beat maker;
-- the chip's tap (Command "open") opens it over the beat maker. (3) Choice 3 (a sure loss: cold) plays one Loss, and
-- within 1 s LastReaction is "skip:daw" (no seat holds you; the beat maker is up). 0.5 s later, and on through 2.5 s
-- after the result (past the reaction's 2 s release), hum.Sit is still false and the beat maker still open. (4) The
-- beat maker closes. Everything this file changed is set back (the beat maker closed, the camera Custom, the result
-- card hidden).
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
local laptop = workspace.OKStudio.Lounge.Station_Bar.Screen
-- never inherit a forced size or an open beat maker from an earlier failed run
wg:SetAttribute("ForceViewport", nil); ui:SetAttribute("ForceViewport", nil)
daw:SetAttribute("CompactForced", nil); daw:SetAttribute("ViewportOverride", nil)
if daw.Visible then daw:SetAttribute("Command", "close"); task.wait(0.4) end
if hum.Sit then hum.Sit = false; task.wait(0.4) end
cam.CameraType = Enum.CameraType.Custom
local out = {}

local function run()
	-- 1. the lounge-bar laptop by its Station prompt (t19b): the beat maker, no chair
	local pos = Vector3.new(18.0, 3.5, -4.8)
	root.CFrame = CFrame.lookAt(pos, Vector3.new(laptop.Position.X, pos.Y, laptop.Position.Z)); task.wait(1.0)
	cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(0, 2.5, 4), laptop.Position); task.wait(1.5)
	local prompt = laptop:FindFirstChildWhichIsA("ProximityPrompt"); assert(prompt, "the lounge-bar laptop has no prompt")
	for _ = 1, 4 do prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); task.wait(0.8); if daw.Visible then break end end
	assert(daw.Visible, "beat maker did not open from the lounge-bar laptop")
	assert(not hum.Sit and hum.SeatPart == nil, "the laptop seated the player (Sit " .. tostring(hum.Sit) .. ", SeatPart " .. tostring(hum.SeatPart) .. ")")
	table.insert(out, "lounge-bar laptop: the beat maker is open, no chair")

	-- 2. he arrives; his card waits behind the beat maker; the chip's tap opens it over the beat maker
	assert(waitFor(function() return (wg:GetAttribute("Token") or "") ~= "" end, 15), "no visitor arrived within 15 s")
	task.wait(0.5) -- one deferral check
	assert(wg:GetAttribute("Card") == CARD, "the waiting card is '" .. tostring(wg:GetAttribute("Card")) .. "', not t64i's " .. CARD)
	assert(wg:GetAttribute("Deferred") == true and wg:GetAttribute("Open") == false and not card.Visible, "the card is not waiting behind the beat maker (Deferred "
		.. tostring(wg:GetAttribute("Deferred")) .. ", Open " .. tostring(wg:GetAttribute("Open")) .. ")")
	wg:SetAttribute("Command", "open")
	assert(waitFor(function() return wg:GetAttribute("Open") == true and card.Visible end, 1), "the chip's tap did not open the card over the beat maker")
	assert(daw.Visible, "opening the card closed the beat maker")
	table.insert(out, CARD .. " arrived and waited behind the beat maker; Command open showed it over the beat maker")

	-- 3. choice 3: one Loss, skip:daw; you never sit and the beat maker stays open
	local s0 = sounds()
	ui:SetAttribute("LastReaction", "")
	wg:SetAttribute("ResultKey", ""); wg:SetAttribute("LastChoose", "")
	wg:SetAttribute("Command", "choose:" .. PICK)
	assert(waitFor(function() return wg:GetAttribute("ResultKey") == KEY end, 6), "choice " .. PICK .. " (sure): ResultKey '"
		.. tostring(wg:GetAttribute("ResultKey")) .. "', LastChoose '" .. tostring(wg:GetAttribute("LastChoose")) .. "', want " .. KEY)
	local tRes = os.clock()
	assert(waitFor(function() return ui:GetAttribute("LastReaction") == "skip:daw" end, 1), "LastReaction '" .. tostring(ui:GetAttribute("LastReaction"))
		.. "' within 1 s of the result, want 'skip:daw'")
	local tReact = os.clock()
	assert(waitFor(function() return ui:GetAttribute("LastSound") == "Loss" and sounds() == s0 + 1 end, 1), "within 1 s of the result: LastSound '"
		.. tostring(ui:GetAttribute("LastSound")) .. "', " .. (sounds() - s0) .. " new sounds, want one Loss")
	task.wait(math.max(0, 0.5 - (os.clock() - tReact)))
	assert(not hum.Sit and daw.Visible, "0.5 s after skip:daw: Sit " .. tostring(hum.Sit) .. ", the beat maker " .. (daw.Visible and "open" or "closed"))
	while os.clock() - tRes < 2.5 do
		assert(not hum.Sit and hum.SeatPart == nil, string.format("%.1f s after the loss you sit (SeatPart %s)", os.clock() - tRes, tostring(hum.SeatPart)))
		assert(daw.Visible, string.format("the beat maker closed %.1f s after the loss", os.clock() - tRes))
		task.wait(0.1)
	end
	table.insert(out, "choice " .. PICK .. ": " .. KEY .. ", one Loss; LastReaction 'skip:daw'; through 2.5 s no sit and the beat maker stayed open")

	-- 4. close it
	daw:SetAttribute("Command", "close")
	assert(waitFor(function() return not daw.Visible end, 3), "beat maker did not close")
	cam.CameraType = Enum.CameraType.Custom
	table.insert(out, "beat maker closed")
end

local ok, err = pcall(run)
if daw.Visible then daw:SetAttribute("Command", "close"); task.wait(0.4) end
if hum.Sit then hum.Sit = false end
cam.CameraType = Enum.CameraType.Custom
if wg:GetAttribute("Open") == true then wg:SetAttribute("Command", "walkaway"); task.wait(0.3) end
wg:SetAttribute("Command", "ok") -- hide the result card (t64l's DM must open by itself)
if not ok then error(err, 0) end
return "T64J PLAY OK\n" .. table.concat(out, "\n")
