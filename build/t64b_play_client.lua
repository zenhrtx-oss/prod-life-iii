-- Client, during play (Wave 1b Task 5; Review Focus 1 and 6), after t64a's tail: money $300, the player at the studio
-- PC spot, the next walk-in draw forced to 1 and scoot_session walking in. Sounds and the reaction are read from OK_UI's
-- SoundLog / Sounds / LastSound / LastReaction (CardFeel). (1) The card opens by itself: exactly one new sound,
-- "CardOpen" (the count is taken before it opens, so an earlier file's riser can't pass for it). (2) The beat maker
-- opens over the card at the studio PC (t57b's prompt) and closes again: the card hides and comes back with no new sound
-- (the riser is once per card, not per show). (3) 1.5 s after the close, standing still on the floor, choice 3 rolls
-- good (paid). (4) LastReaction is "cheer" on R15 ("skip:r6" on R6) and, within 0.5 s, the Animator plays the Animate
-- script's cheer: a track named CheerAnim or animation 507770677 (read first, while the emote plays; track counts are
-- no signal: the idle track stops when the cheer starts). (5) The result shows a "+$" money chip, and within 1 s of it
-- the log ends Win,Money,Plant with exactly three new sounds (the reply and the "result" message carry one result).
-- Everything this file changed is set back (the beat maker closed, the camera Custom, the result card hidden).
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character; local root = char:WaitForChild("HumanoidRootPart", 5); local hum = char:WaitForChild("Humanoid", 5); local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui", 10)
local wg = pg:WaitForChild("OK_WalkIn", 10); assert(wg, "no OK_WalkIn gui (WalkInUI.Build did not run?)")
local ui = pg:WaitForChild("OK_UI", 10); assert(ui, "no OK_UI")
local daw = pg:WaitForChild("OK_DAW", 10):WaitForChild("DAW", 10); assert(daw, "no beat maker gui")
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function soundLog() local o = {}; for k in string.gmatch(ui:GetAttribute("SoundLog") or "", "[^,]+") do table.insert(o, k) end; return o end
local function sounds() return tonumber(ui:GetAttribute("Sounds")) or 0 end
local function newest(n) local l = soundLog(); local o = {}; for i = math.max(1, #l - n + 1), #l do table.insert(o, l[i]) end; return o end
local AIRBORNE = { [Enum.HumanoidStateType.Jumping] = true, [Enum.HumanoidStateType.Freefall] = true, [Enum.HumanoidStateType.GettingUp] = true }
local function standing() -- still, on the floor, no seat: the Animate script plays an emote only while Standing
	return hum.FloorMaterial ~= Enum.Material.Air and not AIRBORNE[hum:GetState()] and not hum.Sit and hum.SeatPart == nil
		and hum.MoveDirection.Magnitude < 0.01
end
local CARD, PICK, KEY = "scoot_session", 3, "paid"
local R15 = hum.RigType == Enum.HumanoidRigType.R15
local card, res = wg:FindFirstChild("Card", true), wg:FindFirstChild("Result", true)
assert(card and res, "the walk-in Card or Result frame is missing")
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
	local at = os.clock()
	if hum.Sit then hum.Sit = false end
	cam.CameraType = Enum.CameraType.Custom
	return at
end
local function cheerTrack()
	local animator = hum:FindFirstChildOfClass("Animator")
	for _, t in ipairs(animator and animator:GetPlayingAnimationTracks() or {}) do
		local id = t.Animation and t.Animation.AnimationId or ""
		if t.Name == "CheerAnim" or string.find(id, "507770677", 1, true) then return t.Name .. " " .. id end
	end
	return nil
end
local function tracks()
	local animator = hum:FindFirstChildOfClass("Animator")
	local o = {}
	for _, t in ipairs(animator and animator:GetPlayingAnimationTracks() or {}) do table.insert(o, t.Name .. "=" .. (t.Animation and t.Animation.AnimationId or "?")) end
	return table.concat(o, ", ")
end

local function run()
	-- 1. the card opens by itself: one riser
	assert(wg:GetAttribute("Open") ~= true, "the walk-in card was already open when this file started (Card '" .. tostring(wg:GetAttribute("Card"))
		.. "'): its riser can't be told from an earlier file's")
	local s0 = sounds()
	assert(waitFor(function() return wg:GetAttribute("Open") == true end, 15), "the card did not open within 15 s (Token '"
		.. tostring(wg:GetAttribute("Token")) .. "', Deferred " .. tostring(wg:GetAttribute("Deferred")) .. ")")
	assert(wg:GetAttribute("Card") == CARD, "the open card is '" .. tostring(wg:GetAttribute("Card")) .. "', not t64a's " .. CARD)
	assert(waitFor(function() return sounds() == s0 + 1 end, 0.5) and ui:GetAttribute("LastSound") == "CardOpen", "the card's open: LastSound '"
		.. tostring(ui:GetAttribute("LastSound")) .. "', " .. (sounds() - s0) .. " new sounds, want one CardOpen (SoundLog '" .. tostring(ui:GetAttribute("SoundLog")) .. "')")
	table.insert(out, CARD .. " opened by itself: one CardOpen")

	-- 2. the beat maker over the card, then closed: the card hides and comes back, no second riser
	local s1 = sounds()
	openBeatMaker("over the card")
	assert(waitFor(function() return not card.Visible and wg:GetAttribute("Open") == false end, 1), "the card did not hide behind the beat maker (Open "
		.. tostring(wg:GetAttribute("Open")) .. ")")
	local closedAt = closeBeatMaker()
	assert(waitFor(function() return wg:GetAttribute("Open") == true and card.Visible end, 2), "the card did not come back within 2 s of closing the beat maker (Open "
		.. tostring(wg:GetAttribute("Open")) .. ", Deferred " .. tostring(wg:GetAttribute("Deferred")) .. ")")
	task.wait(0.3)
	assert(sounds() == s1, "the card's re-show played " .. (sounds() - s1) .. " sounds: '" .. table.concat(newest(sounds() - s1), ",") .. "'")
	table.insert(out, "the beat maker hid the card and closed: the card came back with Sounds unchanged")

	-- 3. 1.5 s after the close, standing still: choice 3 rolls good (SetRng 1)
	assert(waitFor(function() return os.clock() - closedAt >= 1.5 and standing() end, 5), "not standing still on the floor 1.5 s after the close (Floor "
		.. tostring(hum.FloorMaterial) .. ", State " .. tostring(hum:GetState()) .. ", Sit " .. tostring(hum.Sit) .. ", SeatPart " .. tostring(hum.SeatPart) .. ")")
	assert(waitFor(function() return (tonumber(player:GetAttribute("Cred")) or 0) >= 300 end, 2), "Cred is " .. tostring(player:GetAttribute("Cred"))
		.. ": t64a staged $300 for choice 3's cost")
	local s2 = sounds()
	ui:SetAttribute("LastReaction", "")
	wg:SetAttribute("ResultKey", ""); wg:SetAttribute("LastChoose", "")
	wg:SetAttribute("Command", "choose:" .. PICK)
	assert(waitFor(function() return wg:GetAttribute("ResultKey") == KEY end, 6), "choice " .. PICK .. " with the roll forced to 1: ResultKey '"
		.. tostring(wg:GetAttribute("ResultKey")) .. "', LastChoose '" .. tostring(wg:GetAttribute("LastChoose")) .. "', want " .. KEY)
	local tRes = os.clock()

	-- 4. the reaction, read first (the emote is short): the Animate script's cheer on R15
	local want = R15 and "cheer" or "skip:r6"
	assert(waitFor(function() return ui:GetAttribute("LastReaction") == want end, 0.5), "LastReaction '" .. tostring(ui:GetAttribute("LastReaction"))
		.. "', want '" .. want .. "' (" .. tostring(hum.RigType) .. ")")
	local track
	if R15 then
		assert(waitFor(function() track = cheerTrack(); return track ~= nil end, 0.5), "no CheerAnim (507770677) track within 0.5 s; playing: " .. tracks())
	end

	-- 5. the "+$" chip, and within 1 s of the result Win, then Money, then Plant
	local chips, money = res:FindFirstChild("Chips"), nil
	for _, c in ipairs(chips and chips:GetChildren() or {}) do
		if c:IsA("TextLabel") and string.match(c.Text, "^%+%$") then money = c.Text end
	end
	assert(res.Visible and money, "the result card shows no '+$' money chip")
	assert(waitFor(function() return table.concat(newest(3), ",") == "Win,Money,Plant" and sounds() == s2 + 3 end, math.max(0, 1 - (os.clock() - tRes))),
		"within 1 s of the result the log ends '" .. table.concat(newest(3), ",") .. "' with " .. (sounds() - s2) .. " new sounds, want exactly Win,Money,Plant")
	task.wait(0.3)
	assert(sounds() == s2 + 3, "later " .. (sounds() - s2) .. " new sounds, want 3: '" .. table.concat(newest(sounds() - s2), ",") .. "'")
	table.insert(out, string.format("choice %d: %s, chip '%s', then Win,Money,Plant; LastReaction '%s'%s", PICK, KEY, money, want,
		track and (", playing " .. track) or ""))
end

local ok, err = pcall(run)
if daw.Visible then daw:SetAttribute("Command", "close"); task.wait(0.4) end
if hum.Sit then hum.Sit = false end
cam.CameraType = Enum.CameraType.Custom
if wg:GetAttribute("Open") == true then wg:SetAttribute("Command", "walkaway"); task.wait(0.3) end
wg:SetAttribute("Command", "ok") -- hide the result card
if not ok then error(err, 0) end
return "T64B PLAY OK\n" .. table.concat(out, "\n")
