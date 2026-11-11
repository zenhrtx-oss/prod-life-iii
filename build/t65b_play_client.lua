-- Client, during play (Wave 1b Task 5; Review Focus 6), after t65a's tail: dm_navx popped and opened by itself, then
-- news_spedup and mishap_monitor popped, with Quiet off and the phone's next draw forced to 100. Sounds are read from
-- OK_UI's SoundLog / Sounds / LastSound (CardFeel). (1) The DM is open and the NEWS and the mishap wait behind it
-- (Pending 3): the log's newest four entries are the DM's PhoneBuzz and CardOpen, then the other two pops' PhoneBuzz
-- (t65a pops them only once the DM has opened). (2) Standing still, choice 2 rolls bad: the inline result shows a
-- "-N AURA" chip, then exactly one new sound, "Loss" (the reply and the "result" message carry the same result: one
-- Loss), and LastReaction is "sit" on R15 ("skip:r6" on R6) with hum.Sit true within 0.5 s and released within 3 s.
-- (3) RS.OK.Cypher's Phase set to "lobby" here (a local change) holds the NEWS once the DM closes (OK): it waits
-- (Deferred) and the icon re-shakes, with Sounds unchanged: no buzz on a re-shake. (4) MuteMonitors set true here, then
-- Phase back: the NEWS opens, its result (spedup) shows and OK closes it with Sounds unchanged (the mishap opens by
-- itself after it, its riser muted too). (5) Since t65a's pops the log holds exactly three PhoneBuzz. (6, Task H)
-- MuteMonitors back off, the mishap open: choice 3 (borrowed: neutral, no money, plants mishap_owe) ends the SoundLog
-- with Plant within 1.5 s of its result.
-- Everything this file changed is set back (Phase, MuteMonitors, no card left open, standing).
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character; local hum = char:WaitForChild("Humanoid", 5)
local pg = player:WaitForChild("PlayerGui", 10)
local phone = pg:WaitForChild("OK_Phone", 10); assert(phone, "no OK_Phone gui (PhoneUI.Build did not run?)")
local ui = pg:WaitForChild("OK_UI", 10); assert(ui, "no OK_UI")
local daw = pg:WaitForChild("OK_DAW", 10):WaitForChild("DAW", 10); assert(daw, "no beat maker gui")
local cy = RS.OK:WaitForChild("Cypher", 5); assert(cy, "no RS.OK.Cypher")
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function soundLog() local o = {}; for k in string.gmatch(ui:GetAttribute("SoundLog") or "", "[^,]+") do table.insert(o, k) end; return o end
local function sounds() return tonumber(ui:GetAttribute("Sounds")) or 0 end
local function newest(n) local l = soundLog(); local o = {}; for i = math.max(1, #l - n + 1), #l do table.insert(o, l[i]) end; return o end
local AIRBORNE = { [Enum.HumanoidStateType.Jumping] = true, [Enum.HumanoidStateType.Freefall] = true, [Enum.HumanoidStateType.GettingUp] = true }
local function standing() return hum.FloorMaterial ~= Enum.Material.Air and not AIRBORNE[hum:GetState()] and not hum.Sit end
local DM, NEWS, MISHAP = "dm_navx", "news_spedup", "mishap_monitor"
local R15 = hum.RigType == Enum.HumanoidRigType.R15
-- never inherit a forced size or an open beat maker from an earlier failed run
phone:SetAttribute("ForceViewport", nil); ui:SetAttribute("ForceViewport", nil)
local dawClosed = -math.huge
if daw.Visible then daw:SetAttribute("Command", "close"); dawClosed = os.clock(); task.wait(0.4) end
if hum.Sit then hum.Sit = false; task.wait(0.4) end
local was = { mute = player:GetAttribute("MuteMonitors"), phase = cy:GetAttribute("Phase") }
local out = {}

local function run()
	assert(was.mute ~= true, "MuteMonitors is on at the start: t65a's pops could not log their buzz")
	-- 1. the DM opened by itself; the three pops buzzed once each and the DM's open rose once
	assert(waitFor(function() return phone:GetAttribute("Open") == true end, 10), "the DM did not open by itself within 10 s (Pending "
		.. tostring(phone:GetAttribute("Pending")) .. ", Deferred " .. tostring(phone:GetAttribute("Deferred")) .. ")")
	assert(waitFor(function() return phone:GetAttribute("Pending") == 3 end, 2) and phone:GetAttribute("Card") == DM, "open card '"
		.. tostring(phone:GetAttribute("Card")) .. "', Pending " .. tostring(phone:GetAttribute("Pending")) .. ": want t65a's " .. DM
		.. " with its NEWS and the mishap held (3)")
	local tail = table.concat(newest(4), ",")
	assert(tail == "PhoneBuzz,CardOpen,PhoneBuzz,PhoneBuzz", "after t65a's pops and the DM's open the log ends '" .. tail
		.. "', want the DM's PhoneBuzz and CardOpen, then two PhoneBuzz (SoundLog '" .. tostring(ui:GetAttribute("SoundLog")) .. "')")
	local base = sounds() - 4 -- the count before t65a's pops
	table.insert(out, "three pops and the DM's open: the log ends " .. tail)

	-- 2. choice 2 rolls bad (SetRng 100): the -N AURA chip, one Loss, the sit
	assert(waitFor(function() return os.clock() - dawClosed > 1.3 and standing() end, 4), "not standing still on the floor before the choice (Floor "
		.. tostring(hum.FloorMaterial) .. ", State " .. tostring(hum:GetState()) .. ", Sit " .. tostring(hum.Sit) .. ")")
	local s0 = sounds()
	ui:SetAttribute("LastReaction", "")
	phone:SetAttribute("ResultKey", ""); phone:SetAttribute("LastChoose", "")
	phone:SetAttribute("Command", "choose:2")
	assert(waitFor(function() return phone:GetAttribute("ResultKey") == "toomany" end, 6), "choice 2 with the draw forced to 100: ResultKey '"
		.. tostring(phone:GetAttribute("ResultKey")) .. "', LastChoose '" .. tostring(phone:GetAttribute("LastChoose")) .. "', want toomany")
	cy:SetAttribute("Phase", "lobby") -- holds the NEWS once the DM closes (step 3), even if its result closes by itself
	local chips = phone:FindFirstChild("Card", true):FindFirstChild("Chips", true)
	local chip
	for _, c in ipairs(chips and chips:GetChildren() or {}) do
		if c:IsA("TextLabel") and string.match(c.Text, "^%-%d+ AURA$") then chip = c.Text end
	end
	assert(chip, "the inline result shows no '-N AURA' chip")
	assert(waitFor(function() return ui:GetAttribute("LastSound") == "Loss" and sounds() == s0 + 1 end, 1), "within 1 s of the result: LastSound '"
		.. tostring(ui:GetAttribute("LastSound")) .. "', " .. (sounds() - s0) .. " new sounds, want one Loss")
	local want = R15 and "sit" or "skip:r6"
	assert(waitFor(function() return ui:GetAttribute("LastReaction") == want end, 0.5), "LastReaction '" .. tostring(ui:GetAttribute("LastReaction"))
		.. "', want '" .. want .. "' (" .. tostring(hum.RigType) .. ")")
	if R15 then
		assert(waitFor(function() return hum.Sit end, 0.5), "the loss did not sit the avatar within 0.5 s")
		assert(waitFor(function() return not hum.Sit end, 3), "the avatar still sits 3 s after the loss")
	end
	assert(sounds() == s0 + 1 and newest(1)[1] == "Loss", "after the loss the log ends '" .. table.concat(newest(3), ",") .. "' with "
		.. (sounds() - s0) .. " new sounds, want one Loss (no Money, no Plant, one Loss for the reply and the message)")
	table.insert(out, string.format("choice 2: toomany, chip '%s', then one Loss; LastReaction '%s'%s", chip, want, R15 and ", sat and stood up within 3 s" or ""))

	-- 3. the NEWS waits behind the cypher lobby: the icon re-shakes, no buzz
	phone:SetAttribute("Command", "ok")
	assert(waitFor(function() return phone:GetAttribute("Open") == false end, 2), "OK did not close the DM's result")
	assert(waitFor(function() return phone:GetAttribute("Deferred") == true end, 1), "the NEWS is not held (Deferred " .. tostring(phone:GetAttribute("Deferred"))
		.. ", Pending " .. tostring(phone:GetAttribute("Pending")) .. ") with the cypher in its lobby")
	local scale = phone:FindFirstChild("Shake", true)
	assert(scale and scale:IsA("UIScale"), "no Shake UIScale on the phone icon")
	local s1, peak = sounds(), 1
	assert(waitFor(function() peak = math.max(peak, scale.Scale); return scale.Scale > 1.02 end, 14), string.format("the icon did not re-shake within 14 s (UIScale peak %.2f)", peak))
	task.wait(0.3)
	assert(sounds() == s1, "the re-shake played a sound: the log ends '" .. table.concat(newest(sounds() - s1), ",") .. "'")
	table.insert(out, string.format("the NEWS held by the cypher lobby: the icon re-shook (scale %.2f), no sound", peak))

	-- 4. muted: the NEWS opens, shows its result and closes, all silent
	player:SetAttribute("MuteMonitors", true)
	local s2 = sounds()
	phone:SetAttribute("ResultKey", "")
	cy:SetAttribute("Phase", was.phase)
	assert(waitFor(function() return phone:GetAttribute("Open") == true and phone:GetAttribute("Card") == NEWS end, 2), "the NEWS did not open with the cypher idle (Open "
		.. tostring(phone:GetAttribute("Open")) .. ", Card '" .. tostring(phone:GetAttribute("Card")) .. "')")
	assert(waitFor(function() return phone:GetAttribute("ResultKey") == "spedup" end, 3), "the NEWS result did not show (ResultKey '" .. tostring(phone:GetAttribute("ResultKey")) .. "')")
	phone:SetAttribute("Command", "ok")
	-- the mishap may open by itself right after (Open true again), so the check is that the NEWS is no longer on screen
	assert(waitFor(function() return phone:GetAttribute("Card") ~= NEWS end, 2), "OK did not close the NEWS")
	task.wait(0.6) -- Money and Plant would land 0.25 / 0.5 s after the result
	assert(sounds() == s2, "with MuteMonitors on the NEWS (and the mishap's open) played " .. (sounds() - s2) .. " sounds: '"
		.. table.concat(newest(sounds() - s2), ",") .. "'")
	player:SetAttribute("MuteMonitors", was.mute)
	table.insert(out, "muted: the NEWS opened, showed spedup and closed with Sounds unchanged")

	-- 5. since t65a's pops: exactly three PhoneBuzz
	local k = sounds() - base
	local since = newest(k)
	assert(#since == k, "the log holds " .. #since .. " entries, fewer than the " .. k .. " since t65a's pops")
	local buzz = 0
	for _, key in ipairs(since) do if key == "PhoneBuzz" then buzz += 1 end end
	assert(buzz == 3, "since t65a's pops the log holds " .. buzz .. " PhoneBuzz, want 3: '" .. table.concat(since, ",") .. "'")
	table.insert(out, "since t65a's pops: " .. table.concat(since, ",") .. " (three PhoneBuzz)")

	-- 6. (Task H) a phone choice that plants a follow-up: the mishap's choice 3 ends the log with Plant
	assert(waitFor(function() return phone:GetAttribute("Open") == true and phone:GetAttribute("Card") == MISHAP end, 3), "the mishap did not open"
		.. " after the NEWS (Open " .. tostring(phone:GetAttribute("Open")) .. ", Card '" .. tostring(phone:GetAttribute("Card")) .. "', Pending "
		.. tostring(phone:GetAttribute("Pending")) .. ")")
	local s3 = sounds()
	phone:SetAttribute("ResultKey", ""); phone:SetAttribute("LastChoose", "")
	phone:SetAttribute("Command", "choose:3")
	assert(waitFor(function() return phone:GetAttribute("ResultKey") == "borrowed" end, 6), "the mishap's choice 3: ResultKey '"
		.. tostring(phone:GetAttribute("ResultKey")) .. "', LastChoose '" .. tostring(phone:GetAttribute("LastChoose")) .. "', want borrowed")
	assert(waitFor(function() return sounds() > s3 and newest(1)[1] == "Plant" end, 1.5), "within 1.5 s of the planting result the log ends '"
		.. table.concat(newest(3), ",") .. "' (" .. (sounds() - s3) .. " new sounds), want Plant last")
	table.insert(out, "the mishap's choice 3 (borrowed, plants mishap_owe): new sounds " .. table.concat(newest(sounds() - s3), ",") .. ", the log ends with Plant")
	phone:SetAttribute("Command", "ok")
	assert(waitFor(function() return phone:GetAttribute("Open") == false end, 2), "OK did not close the mishap's result")
end

local ok, err = pcall(run)
cy:SetAttribute("Phase", was.phase)
player:SetAttribute("MuteMonitors", was.mute)
if phone:GetAttribute("Open") == true then phone:SetAttribute("Command", "ok") end
waitFor(function() return not hum.Sit end, 3)
if hum.Sit then hum.Sit = false end
if not ok then error(err, 0) end
return "T65B PLAY OK\n" .. table.concat(out, "\n")
