-- Client, during play (Wave 1b Task 5; Review Focus 1 and 6), after t64c's tail: rookie_block walking in to the lounge.
-- Sounds and the reaction are read from OK_UI (CardFeel). The card opens by itself; standing still on the floor, choice
-- 3 (a sure loss: cold, -5 AURA) gives exactly one new sound, "Loss" (no Money, no Plant; the reply and the "result"
-- message carry one result), LastReaction "sit" on R15 ("skip:r6" on R6), and on R15 hum.Sit turns true within 0.5 s
-- and false within 3 s (the reaction sits you where you stand for 2 s and stands you back up). Everything this file
-- changed is set back (standing, the result card hidden).
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character; local hum = char:WaitForChild("Humanoid", 5); local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui", 10)
local wg = pg:WaitForChild("OK_WalkIn", 10); assert(wg, "no OK_WalkIn gui (WalkInUI.Build did not run?)")
local ui = pg:WaitForChild("OK_UI", 10); assert(ui, "no OK_UI")
local daw = pg:WaitForChild("OK_DAW", 10):WaitForChild("DAW", 10); assert(daw, "no beat maker gui")
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function soundLog() local o = {}; for k in string.gmatch(ui:GetAttribute("SoundLog") or "", "[^,]+") do table.insert(o, k) end; return o end
local function sounds() return tonumber(ui:GetAttribute("Sounds")) or 0 end
local function newest(n) local l = soundLog(); local o = {}; for i = math.max(1, #l - n + 1), #l do table.insert(o, l[i]) end; return o end
local AIRBORNE = { [Enum.HumanoidStateType.Jumping] = true, [Enum.HumanoidStateType.Freefall] = true, [Enum.HumanoidStateType.GettingUp] = true }
local function standing() return hum.FloorMaterial ~= Enum.Material.Air and not AIRBORNE[hum:GetState()] and not hum.Sit and hum.SeatPart == nil end
local CARD, PICK, KEY = "rookie_block", 3, "cold"
local R15 = hum.RigType == Enum.HumanoidRigType.R15
-- never inherit a forced size or an open beat maker from an earlier failed run
wg:SetAttribute("ForceViewport", nil); ui:SetAttribute("ForceViewport", nil)
local dawClosed = -math.huge
if daw.Visible then daw:SetAttribute("Command", "close"); dawClosed = os.clock(); task.wait(0.4) end
if hum.Sit then hum.Sit = false; task.wait(0.4) end
cam.CameraType = Enum.CameraType.Custom
local out = {}

local function run()
	-- 1. the card opens by itself
	assert(waitFor(function() return wg:GetAttribute("Open") == true end, 15), "the card did not open within 15 s (Token '"
		.. tostring(wg:GetAttribute("Token")) .. "', Deferred " .. tostring(wg:GetAttribute("Deferred")) .. ")")
	assert(wg:GetAttribute("Card") == CARD, "the open card is '" .. tostring(wg:GetAttribute("Card")) .. "', not t64c's " .. CARD)

	-- 2. standing still (and clear of any beat maker this file closed), choice 3: one Loss, then the sit
	assert(waitFor(function() return os.clock() - dawClosed > 1.3 and standing() end, 4), "not standing still on the floor before the choice (Floor "
		.. tostring(hum.FloorMaterial) .. ", State " .. tostring(hum:GetState()) .. ", Sit " .. tostring(hum.Sit) .. ")")
	local s0 = sounds()
	ui:SetAttribute("LastReaction", "")
	wg:SetAttribute("ResultKey", ""); wg:SetAttribute("LastChoose", "")
	wg:SetAttribute("Command", "choose:" .. PICK)
	assert(waitFor(function() return wg:GetAttribute("ResultKey") == KEY end, 6), "choice " .. PICK .. " (sure): ResultKey '"
		.. tostring(wg:GetAttribute("ResultKey")) .. "', LastChoose '" .. tostring(wg:GetAttribute("LastChoose")) .. "', want " .. KEY)
	assert(waitFor(function() return ui:GetAttribute("LastSound") == "Loss" and sounds() == s0 + 1 end, 1), "within 1 s of the result: LastSound '"
		.. tostring(ui:GetAttribute("LastSound")) .. "', " .. (sounds() - s0) .. " new sounds, want one Loss")
	local want = R15 and "sit" or "skip:r6"
	assert(waitFor(function() return ui:GetAttribute("LastReaction") == want end, 0.5), "LastReaction '" .. tostring(ui:GetAttribute("LastReaction"))
		.. "', want '" .. want .. "' (" .. tostring(hum.RigType) .. ")")
	local satAfter, stoodAfter
	if R15 then
		local tRes = os.clock()
		assert(waitFor(function() return hum.Sit end, 0.5), "the loss did not sit the avatar within 0.5 s")
		satAfter = os.clock() - tRes
		assert(waitFor(function() return not hum.Sit end, 3), "the avatar still sits 3 s after the loss (SeatPart " .. tostring(hum.SeatPart) .. ")")
		stoodAfter = os.clock() - tRes
	end
	assert(sounds() == s0 + 1 and newest(1)[1] == "Loss", "after the loss the log ends '" .. table.concat(newest(3), ",") .. "' with "
		.. (sounds() - s0) .. " new sounds, want one Loss (no Money, no Plant)")
	table.insert(out, string.format("choice %d: %s, one Loss; LastReaction '%s'%s", PICK, KEY, want,
		R15 and string.format(", sat %.2f s and stood up %.1f s after the result", satAfter, stoodAfter) or ""))
end

local ok, err = pcall(run)
if wg:GetAttribute("Open") == true then wg:SetAttribute("Command", "walkaway"); task.wait(0.3) end
wg:SetAttribute("Command", "ok") -- hide the result card
waitFor(function() return not hum.Sit end, 3)
if hum.Sit then hum.Sit = false end
if not ok then error(err, 0) end
return "T64D PLAY OK\n" .. table.concat(out, "\n")
