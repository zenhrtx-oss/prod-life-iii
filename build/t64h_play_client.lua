-- Client, during play (Wave 1b Task 5; Review Focus 1), after t64g's tail: rookie_block walking in to the lounge. A
-- death in the middle of the loss reaction leaves nothing behind. Standing still, choice 3 (a sure loss: cold) gives
-- LastReaction "sit"; once hum.Sit is true, hum:ChangeState(Dead) kills the character here on the client (Task 0's P4).
-- The reaction's 2 s release then finds a dead humanoid and does nothing. The new character arrives within
-- RespawnTime + 4 s and stands within 3 s of arriving: not Sit, no SeatPart, not Seated or Dead, on the floor. It still
-- doesn't sit 1 s later. From the choice to the end, the client's console shows no error: no MessageError, no
-- [OK][ERR] and no "Infinite yield", by tools/test.py's own rule and BENIGN list. The test avatar must be R15 (P1), since
-- an R6 avatar never sits. Everything this file changed is set back: the result card hidden, the new character standing.
local Players, LogService = game:GetService("Players"), game:GetService("LogService")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character; local hum = char:WaitForChild("Humanoid", 5); local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui", 10)
local wg = pg:WaitForChild("OK_WalkIn", 10); assert(wg, "no OK_WalkIn gui (WalkInUI.Build did not run?)")
local ui = pg:WaitForChild("OK_UI", 10); assert(ui, "no OK_UI")
local daw = pg:WaitForChild("OK_DAW", 10):WaitForChild("DAW", 10); assert(daw, "no beat maker gui")
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local AIRBORNE = { [Enum.HumanoidStateType.Jumping] = true, [Enum.HumanoidStateType.Freefall] = true, [Enum.HumanoidStateType.GettingUp] = true }
local function standing(h) return h.FloorMaterial ~= Enum.Material.Air and not AIRBORNE[h:GetState()] and not h.Sit and h.SeatPart == nil end
local CARD, PICK, KEY = "rookie_block", 3, "cold"
-- tools/test.py's console rule (and its BENIGN list), applied to what this client logs during the case
local BENIGN = { "not authorized to access Asset", "failed due to: User is not authorized" }
local function bad(msg, kind)
	local hit = kind == Enum.MessageType.MessageError or (string.find(msg, "rror", 1, true) and not string.find(msg, "[OK]", 1, true))
		or string.find(msg, "[OK][ERR]", 1, true) or string.find(msg, "nfinite yield", 1, true) or string.find(msg, "Stack Begin", 1, true)
	if not hit then return false end
	for _, b in ipairs(BENIGN) do if string.find(msg, b, 1, true) then return false end end
	return true
end
-- never inherit a forced size or an open beat maker from an earlier failed run
wg:SetAttribute("ForceViewport", nil); ui:SetAttribute("ForceViewport", nil)
local dawClosed = -math.huge
if daw.Visible then daw:SetAttribute("Command", "close"); dawClosed = os.clock(); task.wait(0.4) end
if hum.Sit then hum.Sit = false; task.wait(0.4) end
cam.CameraType = Enum.CameraType.Custom
local errs, conn = {}, nil
local out = {}

local function run()
	assert(hum.RigType == Enum.HumanoidRigType.R15, "the test avatar is " .. tostring(hum.RigType) .. ": this case needs R15 (an R6 avatar never sits, P1)")
	-- 1. the card opens by itself; standing still, choice 3: the sit
	assert(waitFor(function() return wg:GetAttribute("Open") == true end, 15), "the card did not open within 15 s (Token '"
		.. tostring(wg:GetAttribute("Token")) .. "', Deferred " .. tostring(wg:GetAttribute("Deferred")) .. ")")
	assert(wg:GetAttribute("Card") == CARD, "the open card is '" .. tostring(wg:GetAttribute("Card")) .. "', not t64g's " .. CARD)
	assert(waitFor(function() return os.clock() - dawClosed > 1.3 and standing(hum) end, 4), "not standing still on the floor before the choice (Floor "
		.. tostring(hum.FloorMaterial) .. ", State " .. tostring(hum:GetState()) .. ", Sit " .. tostring(hum.Sit) .. ")")
	conn = LogService.MessageOut:Connect(function(msg, kind) if bad(msg, kind) then table.insert(errs, msg) end end)
	ui:SetAttribute("LastReaction", "")
	wg:SetAttribute("ResultKey", ""); wg:SetAttribute("LastChoose", "")
	wg:SetAttribute("Command", "choose:" .. PICK)
	assert(waitFor(function() return wg:GetAttribute("ResultKey") == KEY end, 6), "choice " .. PICK .. " (sure): ResultKey '"
		.. tostring(wg:GetAttribute("ResultKey")) .. "', LastChoose '" .. tostring(wg:GetAttribute("LastChoose")) .. "', want " .. KEY)
	assert(waitFor(function() return ui:GetAttribute("LastReaction") == "sit" end, 0.5), "LastReaction '" .. tostring(ui:GetAttribute("LastReaction")) .. "', want 'sit'")
	assert(waitFor(function() return hum.Sit end, 0.5), "the loss did not sit the avatar within 0.5 s")

	-- 2. die while sitting (P4: the client kills its own character)
	local tDie = os.clock()
	hum:ChangeState(Enum.HumanoidStateType.Dead)
	assert(waitFor(function() return hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead end, 1),
		"ChangeState(Dead) did not kill the character within 1 s (Health " .. tostring(hum.Health) .. ", State " .. tostring(hum:GetState()) .. ")")
	table.insert(out, "choice " .. PICK .. ": " .. KEY .. ", LastReaction 'sit', hum.Sit true; then ChangeState(Dead) killed the character")

	-- 3. the new character arrives and stands; nothing of the reaction follows it
	local limit = (tonumber(Players.RespawnTime) or 5) + 4
	assert(waitFor(function() local c = player.Character; return c ~= nil and c ~= char end, limit), "no new character within " .. limit .. " s of the death")
	local arrivedAt = os.clock() - tDie
	local c2 = player.Character
	local h2 = c2:WaitForChild("Humanoid", 5); assert(h2, "the new character has no Humanoid")
	local tNew = os.clock()
	local function stands()
		local s = h2:GetState()
		return h2.Health > 0 and standing(h2) and s ~= Enum.HumanoidStateType.Seated and s ~= Enum.HumanoidStateType.Dead
	end
	assert(waitFor(stands, 3), "the new character does not stand within 3 s of arriving (Sit "
		.. tostring(h2.Sit) .. ", SeatPart " .. tostring(h2.SeatPart) .. ", State " .. tostring(h2:GetState()) .. ", Floor " .. tostring(h2.FloorMaterial) .. ")")
	local stoodAfter = os.clock() - tNew
	local t2 = os.clock()
	while os.clock() - t2 < 1 do
		assert(not h2.Sit and h2.SeatPart == nil, "the new character sat down " .. string.format("%.1f", os.clock() - tNew) .. " s after arriving")
		task.wait(0.1)
	end
	conn:Disconnect(); conn = nil
	assert(#errs == 0, #errs .. " console error(s) from the choice on: " .. table.concat(errs, " | "))
	table.insert(out, string.format("the new character arrived %.1f s after the death and stood %.1f s later; it didn't sit through the next 1 s; no console error",
		arrivedAt, stoodAfter))
end

local ok, err = pcall(run)
if conn then conn:Disconnect() end
if wg:GetAttribute("Open") == true then wg:SetAttribute("Command", "walkaway"); task.wait(0.3) end
wg:SetAttribute("Command", "ok") -- hide the result card
cam.CameraType = Enum.CameraType.Custom
-- the next server file reads p.Character: never leave before a live, unseated character stands
waitFor(function()
	local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	return h ~= nil and h.Health > 0 and not h.Sit
end, (tonumber(Players.RespawnTime) or 5) + 4)
do -- stand the character that is live now (hum is the one that died); never write to a corpse
	local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if h and h.Health > 0 and h:GetState() ~= Enum.HumanoidStateType.Dead and h.Sit then h.Sit = false end
end
if not ok then error(err, 0) end
return "T64H PLAY OK\n" .. table.concat(out, "\n")
