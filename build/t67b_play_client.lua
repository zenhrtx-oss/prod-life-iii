-- Client, during play (two sessions Task 5; Review Focus 1), after t67a's tail: Career set to zero placements,
-- followers and Aura, Quiet off, the phone's next draw forced to 100 (choice 2's roll misses at any chance), then
-- two_sessions popped and opened on the server, the DM left open. Sounds are read from OK_UI's SoundLog / Sounds /
-- LastSound and the reaction from LastReaction (CardFeel). (1) The DM is open here (waited up to 20 s, as in t66b),
-- Card two_sessions, Pending 1. (2) Standing still, choice 2 (the one-hit wonder, `ready`) misses: ResultKey notready;
-- the inline result's Headline (OK_Phone.Root.Card.Scroll.Result.Headline, by its path) reads "YOU WEREN'T READY"; its
-- chips are exactly "-30 AURA", in the cold colour (Theme.accent2), with no chip ending " XP" (XP paid 0); exactly one
-- new sound, Loss; LastReaction is "sit" on R15 ("skip:r6" on R6), hum.Sit true within 0.5 s and released within 3 s.
-- OK closes the result. Everything this file changed is set back (no card left open, standing).
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character; local hum = char:WaitForChild("Humanoid", 5)
local pg = player:WaitForChild("PlayerGui", 10)
local phone = pg:WaitForChild("OK_Phone", 10); assert(phone, "no OK_Phone gui (PhoneUI.Build did not run?)")
local ui = pg:WaitForChild("OK_UI", 10); assert(ui, "no OK_UI")
local daw = pg:WaitForChild("OK_DAW", 10):WaitForChild("DAW", 10); assert(daw, "no beat maker gui")
local Theme = require(RS.OK.Modules.UITheme)
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function soundLog() local o = {}; for k in string.gmatch(ui:GetAttribute("SoundLog") or "", "[^,]+") do table.insert(o, k) end; return o end
local function sounds() return tonumber(ui:GetAttribute("Sounds")) or 0 end
local function newest(n) local l = soundLog(); local o = {}; for i = math.max(1, #l - n + 1), #l do table.insert(o, l[i]) end; return o end
local AIRBORNE = { [Enum.HumanoidStateType.Jumping] = true, [Enum.HumanoidStateType.Freefall] = true, [Enum.HumanoidStateType.GettingUp] = true }
local function standing() return hum.FloorMaterial ~= Enum.Material.Air and not AIRBORNE[hum:GetState()] and not hum.Sit end
local CARD, HEADLINE = "two_sessions", "YOU WEREN'T READY"
local R15 = hum.RigType == Enum.HumanoidRigType.R15
-- never inherit a forced size or an open beat maker from an earlier failed run
ui:SetAttribute("ForceViewport", nil); phone:SetAttribute("ForceViewport", nil)
local dawClosed = -math.huge
if daw.Visible then daw:SetAttribute("Command", "close"); dawClosed = os.clock(); task.wait(0.4) end
if hum.Sit then hum.Sit = false; task.wait(0.4) end
local was = { mute = player:GetAttribute("MuteMonitors") }
local out = {}

local function run()
	assert(was.mute ~= true, "MuteMonitors is on at the start: the result's sound would not log")
	-- 1. the DM is open
	assert(waitFor(function() return phone:GetAttribute("Open") == true and phone:GetAttribute("Card") == CARD end, 20), "the DM did not open"
		.. " within 20 s (Open " .. tostring(phone:GetAttribute("Open")) .. ", Card '" .. tostring(phone:GetAttribute("Card")) .. "', Pending "
		.. tostring(phone:GetAttribute("Pending")) .. ", Deferred " .. tostring(phone:GetAttribute("Deferred")) .. ")")
	assert(phone:GetAttribute("Pending") == 1, "Pending is " .. tostring(phone:GetAttribute("Pending")) .. ", want 1 (only t67a's tail pop)")
	assert(phone:GetAttribute("Choices") == 2, "Choices is " .. tostring(phone:GetAttribute("Choices")) .. ", want 2")
	table.insert(out, "the DM opened (" .. CARD .. ", Pending 1)")

	-- 2. choice 2 misses (SetRng 100): the headline, the cold -30 AURA chip and no XP chip, one Loss, the sit
	assert(waitFor(function() return os.clock() - dawClosed > 1.3 and standing() end, 4), "not standing still on the floor before the choice (Floor "
		.. tostring(hum.FloorMaterial) .. ", State " .. tostring(hum:GetState()) .. ", Sit " .. tostring(hum.Sit) .. ")")
	local s0 = sounds()
	ui:SetAttribute("LastReaction", "")
	phone:SetAttribute("ResultKey", ""); phone:SetAttribute("LastChoose", "")
	phone:SetAttribute("Command", "choose:2")
	assert(waitFor(function() return phone:GetAttribute("ResultKey") == "notready" end, 6), "choice 2 with the draw forced to 100: ResultKey '"
		.. tostring(phone:GetAttribute("ResultKey")) .. "', LastChoose '" .. tostring(phone:GetAttribute("LastChoose")) .. "', want notready")
	assert(phone:GetAttribute("ResultTone") == "loss", "ResultTone is '" .. tostring(phone:GetAttribute("ResultTone")) .. "', want loss")
	local res = phone.Root.Card.Scroll.Result
	assert(res.Headline.Text == HEADLINE, "the inline result's headline reads '" .. res.Headline.Text .. "', want '" .. HEADLINE .. "'")
	local list, aura = {}, nil
	for i = 1, 8 do
		local c = res.Chips:FindFirstChild("Chip" .. i)
		if c then
			table.insert(list, c.Text)
			assert(not string.match(c.Text, " XP$"), "the result shows an XP chip '" .. c.Text .. "' for a miss that paid no XP")
			if c.Text == "-30 AURA" then aura = c end
		end
	end
	assert(aura and #list == 1, "the inline result's chips are [" .. table.concat(list, ", ") .. "], want [-30 AURA]")
	assert(aura.TextColor3 == Theme.accent2, "the -30 AURA chip is " .. tostring(aura.TextColor3) .. ", want the cold Theme.accent2 " .. tostring(Theme.accent2))
	table.insert(out, "choice 2: notready, headline '" .. res.Headline.Text .. "', chips [" .. table.concat(list, ", ") .. "] in Theme.accent2, no XP chip")
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
		.. (sounds() - s0) .. " new sounds, want one Loss (no Money, no Plant)")
	table.insert(out, string.format("one Loss; LastReaction '%s'%s", want, R15 and ", sat and stood up within 3 s" or ""))

	phone:SetAttribute("Command", "ok")
	assert(waitFor(function() return phone:GetAttribute("Open") == false end, 2), "OK did not close the result")
end

local ok, err = pcall(run)
player:SetAttribute("MuteMonitors", was.mute)
if phone:GetAttribute("Open") == true then phone:SetAttribute("Command", "ok") end
waitFor(function() return not hum.Sit end, 3)
if hum.Sit then hum.Sit = false end
if not ok then error(err, 0) end
return "T67B PLAY OK\n" .. table.concat(out, "\n")
