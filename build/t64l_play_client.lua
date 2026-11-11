-- Client, during play (Wave 1b Task 5; Review Focus 1), after t64k's tail: dm_dojabat popped with Quiet off, the next
-- walk-in draw forced to 100 and navx_single walking in to the lounge. A result that shows itself right after the beat
-- maker closes. (1) The DM opens by itself; he arrives (his news, FLOP, applied on arrival) and his card waits behind
-- it (Deferred, never shown). (2) The client sits at the studio PC (t57b's prompt): the beat maker opens, the DM hides
-- behind it, and DISMISS closes the DM there; his card still waits, now behind the beat maker (t57f's sequence). (3)
-- The beat maker closes; his card opens by itself within 2 s, its first show: the log gains exactly CardOpen then Loss
-- (the news counts as a result), LastReaction is "skip:daw" or "skip:seated" (the beat maker went down under a second
-- ago, and restore() may not have let go of the chair yet), and hum.Sit stays false for 1 s after the card opens: you
-- never sit on the floor beside the chair. The log, LastReaction and Sit are read before anything here touches Sit.
-- (4) WALK AWAY closes the card (no result). Everything this file changed is set back (the beat maker closed, the DM
-- gone, standing, the camera Custom, no card open).
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character; local root = char:WaitForChild("HumanoidRootPart", 5); local hum = char:WaitForChild("Humanoid", 5); local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui", 10)
local wg = pg:WaitForChild("OK_WalkIn", 10); assert(wg, "no OK_WalkIn gui (WalkInUI.Build did not run?)")
local phone = pg:WaitForChild("OK_Phone", 10); assert(phone, "no OK_Phone gui (PhoneUI.Build did not run?)")
local ui = pg:WaitForChild("OK_UI", 10); assert(ui, "no OK_UI")
local daw = pg:WaitForChild("OK_DAW", 10):WaitForChild("DAW", 10); assert(daw, "no beat maker gui")
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function soundLog() local o = {}; for k in string.gmatch(ui:GetAttribute("SoundLog") or "", "[^,]+") do table.insert(o, k) end; return o end
local function sounds() return tonumber(ui:GetAttribute("Sounds")) or 0 end
local function newest(n) local l = soundLog(); local o = {}; for i = math.max(1, #l - n + 1), #l do table.insert(o, l[i]) end; return o end
local FOLLOW, DM, NEWS = "navx_single", "dm_dojabat", "FLOP"
local card, pcard = wg:FindFirstChild("Card", true), phone:FindFirstChild("Card", true)
assert(card and pcard, "the walk-in or the phone Card frame is missing")
-- never inherit a forced size or an open beat maker from an earlier failed run
wg:SetAttribute("ForceViewport", nil); ui:SetAttribute("ForceViewport", nil); phone:SetAttribute("ForceViewport", nil)
daw:SetAttribute("CompactForced", nil); daw:SetAttribute("ViewportOverride", nil)
if daw.Visible then daw:SetAttribute("Command", "close"); task.wait(0.4) end
if hum.Sit then hum.Sit = false; task.wait(0.4) end
cam.CameraType = Enum.CameraType.Custom
local out = {}

-- the beat maker at the studio PC, opened the way t57b opens it
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

local function run()
	-- 1. the DM opens by itself; he arrives and his card waits behind it, never shown
	assert(waitFor(function() return phone:GetAttribute("Open") == true end, 10), "the DM did not open by itself within 10 s (Pending "
		.. tostring(phone:GetAttribute("Pending")) .. ", Deferred " .. tostring(phone:GetAttribute("Deferred")) .. ")")
	assert(phone:GetAttribute("Card") == DM, "the open phone card is '" .. tostring(phone:GetAttribute("Card")) .. "', not t64k's " .. DM)
	assert(waitFor(function() return (wg:GetAttribute("Token") or "") ~= "" end, 15), "no visitor arrived within 15 s")
	task.wait(0.5) -- one deferral check
	assert(wg:GetAttribute("Card") == FOLLOW, "the waiting card is '" .. tostring(wg:GetAttribute("Card")) .. "', not t64k's " .. FOLLOW)
	assert(wg:GetAttribute("Deferred") == true and wg:GetAttribute("Open") == false and not card.Visible, "his card did not wait behind the DM (Deferred "
		.. tostring(wg:GetAttribute("Deferred")) .. ", Open " .. tostring(wg:GetAttribute("Open")) .. "): it may already have shown")
	table.insert(out, DM .. " open; " .. FOLLOW .. " arrived and waits behind it")

	-- 2. the beat maker at the studio PC; the DM hides behind it and is dismissed there; his card still waits
	openBeatMaker("with the DM open")
	assert(waitFor(function() return not pcard.Visible end, 1) and phone:GetAttribute("Open") == true, "the DM did not hide behind the beat maker, or lost its slot")
	phone:SetAttribute("LastChoose", "")
	phone:SetAttribute("Command", "dismiss")
	assert(waitFor(function() return phone:GetAttribute("Open") == false and phone:GetAttribute("LastChoose") == "ok" end, 5),
		"dismiss did not close the DM (Open " .. tostring(phone:GetAttribute("Open")) .. ", LastChoose " .. tostring(phone:GetAttribute("LastChoose")) .. ")")
	task.wait(0.5) -- two deferral checks
	assert(wg:GetAttribute("Open") == false and wg:GetAttribute("Deferred") == true and not card.Visible, "his card opened over the beat maker once the DM closed (Open "
		.. tostring(wg:GetAttribute("Open")) .. ", Deferred " .. tostring(wg:GetAttribute("Deferred")) .. ")")
	local seat = hum.SeatPart
	table.insert(out, "beat maker open at the studio PC (SeatPart " .. tostring(seat) .. "); the DM dismissed behind it; his card still waits")

	-- 3. close the beat maker (nothing here touches Sit): his card opens by itself, CardOpen then Loss, a skip, no sit
	local s0 = sounds()
	ui:SetAttribute("LastReaction", "")
	daw:SetAttribute("Command", "close")
	assert(waitFor(function() return not daw.Visible end, 3), "beat maker did not close")
	local tClose = os.clock()
	assert(waitFor(function() return wg:GetAttribute("Open") == true and card.Visible end, 2), "his card did not open by itself within 2 s of the close (Open "
		.. tostring(wg:GetAttribute("Open")) .. ", Deferred " .. tostring(wg:GetAttribute("Deferred")) .. ")")
	local tOpen = os.clock()
	local sitAtOpen, seatAtOpen = hum.Sit, hum.SeatPart
	assert(wg:GetAttribute("Card") == FOLLOW, "the card that opened is '" .. tostring(wg:GetAttribute("Card")) .. "'")
	local news = card:FindFirstChild("News", true)
	local head = news and news:FindFirstChild("Headline")
	assert(news and news.Visible and head and head.Text == NEWS, "his news strip reads '" .. tostring(head and head.Text) .. "', want " .. NEWS .. " (t64k forced the roll to 100)")
	assert(not sitAtOpen, "you sit as the card opens (SeatPart " .. tostring(seatAtOpen) .. ")")
	assert(waitFor(function() return sounds() == s0 + 2 end, 1) and table.concat(newest(2), ",") == "CardOpen,Loss", "within 1 s of the open the log ends '"
		.. table.concat(newest(3), ",") .. "' with " .. (sounds() - s0) .. " new sounds, want exactly CardOpen,Loss (the news is a result)")
	local reaction
	assert(waitFor(function() reaction = ui:GetAttribute("LastReaction"); return reaction == "skip:daw" or reaction == "skip:seated" end, 1),
		"LastReaction '" .. tostring(ui:GetAttribute("LastReaction")) .. "' within 1 s of the open, want 'skip:daw' or 'skip:seated'")
	while os.clock() - tOpen < 1 do
		assert(not hum.Sit, string.format("%.2f s after the card opened you sit (SeatPart %s)", os.clock() - tOpen, tostring(hum.SeatPart)))
		task.wait(0.05)
	end
	table.insert(out, string.format("closed: his card opened by itself %.1f s later; CardOpen,Loss; LastReaction '%s'; hum.Sit false through 1 s", tOpen - tClose, reaction))

	-- 4. walk away: no result
	wg:SetAttribute("LastChoose", "")
	wg:SetAttribute("Command", "walkaway")
	assert(waitFor(function() return wg:GetAttribute("Open") == false and wg:GetAttribute("LastChoose") == "ok" end, 5),
		"WALK AWAY did not close the card (Open " .. tostring(wg:GetAttribute("Open")) .. ", LastChoose " .. tostring(wg:GetAttribute("LastChoose")) .. ")")
	table.insert(out, "walked away")
end

local ok, err = pcall(run)
if daw.Visible then daw:SetAttribute("Command", "close"); task.wait(0.4) end
if hum.Sit then hum.Sit = false end
cam.CameraType = Enum.CameraType.Custom
if phone:GetAttribute("Open") == true then phone:SetAttribute("Command", "dismiss"); task.wait(0.3) end
if wg:GetAttribute("Open") == true then wg:SetAttribute("Command", "walkaway"); task.wait(0.3) end
wg:SetAttribute("Command", "ok") -- hide a result card, if one showed
waitFor(function() return not hum.Sit end, 3)
if not ok then error(err, 0) end
return "T64L PLAY OK\n" .. table.concat(out, "\n")
