-- Client, during play (after t57e popped dm_dojabat and spawned navx_placement back to back): one card at a time.
-- The DM opened by itself (nothing blocked it); LIL NAV X arrives within 15 s and waits (OK_WalkIn Deferred, Open
-- false, the IS WAITING chip) because the phone card is open. The chip keeps clear of the open phone card: its right
-- edge is 8 px left of the card at the real viewport and with OK_Phone, OK_UI and OK_WalkIn forced to 667x375 minus
-- the real insets (WalkInUI.placeChip shifts it left of the card's column). At no 0.1 s sample through the whole case
-- are OK_Phone.Open and OK_WalkIn.Open both true. A chip tap (Command open) while the phone card shows does nothing
-- (Open stays false, Deferred true: the tap is not latched). The beat maker opens at the studio PC (the DM hides
-- behind it) and dismiss closes the DM behind it: the walk-in card stays deferred behind the beat maker (a latched tap
-- would open it over the beat maker, un-armed); closing the beat maker opens it by itself within 2 s. walkaway closes
-- it; nothing is open. Then the beat maker opens again at the studio PC and stays open for t58a.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local char = player.Character; local root = char:WaitForChild("HumanoidRootPart", 5); local hum = char:WaitForChild("Humanoid", 5); local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui", 10)
local gui = pg:WaitForChild("OK_Phone", 10); assert(gui, "no OK_Phone gui")
local wg = pg:WaitForChild("OK_WalkIn", 10); assert(wg, "no OK_WalkIn gui")
local ui = pg:WaitForChild("OK_UI", 10)
local daw = pg.OK_DAW.DAW
local both, samples = 0, 0 -- 0.1 s samples where both cards were open
local function sample()
	samples += 1
	if gui:GetAttribute("Open") == true and wg:GetAttribute("Open") == true then both += 1 end
end
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do sample(); if fn() then return true end; task.wait(0.1) end; sample(); return fn() end
gui:SetAttribute("ForceViewport", nil); wg:SetAttribute("ForceViewport", nil); ui:SetAttribute("ForceViewport", nil); daw:SetAttribute("CompactForced", nil)
assert(not daw.Visible, "the beat maker is open: t57d should have closed it")
assert((RS.OK.Cypher:GetAttribute("Phase") or "idle") == "idle", "cypher phase " .. tostring(RS.OK.Cypher:GetAttribute("Phase")) .. ": this case needs it idle")
local pcard, wcard, chip = gui:FindFirstChild("Card", true), wg:FindFirstChild("Card", true), wg:FindFirstChild("Waiting", true)
local out = {}
-- the beat maker, opened at the studio PC the way t57b opens it
local screen = workspace.OKStudio.ControlRoom.Screen_Main
local function openBeatMaker(where)
	if hum.Sit then hum.Sit = false; task.wait(0.4) end
	local pos = Vector3.new(72.0, 3.5, -5.5)
	root.CFrame = CFrame.lookAt(pos, Vector3.new(screen.Position.X, pos.Y, screen.Position.Z)); task.wait(1.0)
	cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(-4, 3, 0), screen.Position); task.wait(1.5)
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

-- 1. the DM is open; the walk-in arrives and waits behind it
assert(waitFor(function() return gui:GetAttribute("Open") == true and gui:GetAttribute("Card") == "dm_dojabat" end, 5),
	"the DM did not open (Open " .. tostring(gui:GetAttribute("Open")) .. ", Card '" .. tostring(gui:GetAttribute("Card")) .. "')")
-- he walks ~75 studs to the studio PC (about 9.4 s at WalkSpeed 8); arrival waits are capped at 15 s
assert(waitFor(function() return (wg:GetAttribute("Token") or "") ~= "" end, 15), "no visitor arrived within 15 s")
task.wait(0.5); sample() -- one deferral check
assert(wg:GetAttribute("Deferred") == true and wg:GetAttribute("Open") == false and wcard and not wcard.Visible,
	"the walk-in card did not wait behind the phone card (Deferred " .. tostring(wg:GetAttribute("Deferred")) .. ", Open " .. tostring(wg:GetAttribute("Open")) .. ")")
assert(chip and chip.Visible and chip.Text:find("IS WAITING", 1, true), "the IS WAITING chip is not shown (reads '" .. tostring(chip and chip.Text) .. "')")
assert(gui:GetAttribute("Open") == true and pcard.Visible, "the phone card went while the walk-in waited")
-- the chip stays clear of the open phone card (OK_Phone draws over OK_WalkIn): its right edge 8 px left of the card, at
-- the real viewport and at a 667x375 phone's safe area (the three guis forced to the same box, as t57b forces OK_Phone
-- and OK_UI; the chip and the card are both laid out in it)
local function chipClear(where)
	local cr, pl = chip.AbsolutePosition.X + chip.AbsoluteSize.X, pcard.AbsolutePosition.X
	assert(chip.Visible and chip.AbsoluteSize.Y >= 44, where .. ": the chip is hidden or under 44 px")
	assert(cr <= pl - 8, string.format("%s: the chip's right edge %d is under the phone card from %d (want 8 px clear)", where, cr, pl))
	return cr, pl
end
local real = gui.AbsoluteSize
local cr0, pl0 = chipClear("real " .. real.X .. "x" .. real.Y)
local inset = cam.ViewportSize - gui.AbsoluteSize
inset = Vector2.new(math.max(0, inset.X), math.max(0, inset.Y))
local vp = Vector2.new(667, 375) - inset
local where = vp.X .. "x" .. vp.Y .. " (667x375 less " .. inset.X .. "x" .. inset.Y .. ")"
gui:SetAttribute("ForceViewport", vp); ui:SetAttribute("ForceViewport", vp); wg:SetAttribute("ForceViewport", vp)
task.wait(0.5) -- two chip checks (WalkInUI places it every 0.2 s)
local okForced, errForced = pcall(chipClear, where)
gui:SetAttribute("ForceViewport", nil); ui:SetAttribute("ForceViewport", nil); wg:SetAttribute("ForceViewport", nil)
if not okForced then error(errForced, 0) end
task.wait(0.3)
table.insert(out, string.format("dm_dojabat open; navx_placement arrived and waits: chip '%s', right edge %d left of the card at %d (real), clear at %s", chip.Text, cr0, pl0, where))

-- 2. a chip tap while the phone card shows does nothing: Open stays false, Deferred true (and the tap is not latched:
--    step 3 shows the card waiting behind the beat maker once the phone card closes)
wg:SetAttribute("Command", "open")
task.wait(0.5); sample()
assert(wg:GetAttribute("Open") == false and wg:GetAttribute("Deferred") == true and not wcard.Visible,
	"a chip tap opened the walk-in card over the phone card (Open " .. tostring(wg:GetAttribute("Open")) .. ", Deferred " .. tostring(wg:GetAttribute("Deferred")) .. ")")
assert(gui:GetAttribute("Open") == true and pcard.Visible, "the phone card went on the chip tap")
table.insert(out, "chip tap while the phone card shows: Open false, Deferred true")

-- 3. the beat maker opens with the DM on screen (it hides behind it); dismiss closes the DM behind the beat maker: the
--    walk-in card stays deferred behind the beat maker (a tap latched in step 2 would open it over the beat maker, un-armed)
openBeatMaker("with the DM open")
assert(waitFor(function() return not pcard.Visible end, 1) and gui:GetAttribute("Open") == true, "the DM did not hide behind the beat maker, or lost its slot")
gui:SetAttribute("LastChoose", "")
gui:SetAttribute("Command", "dismiss")
assert(waitFor(function() return gui:GetAttribute("Open") == false and gui:GetAttribute("LastChoose") == "ok" end, 5),
	"dismiss did not close the DM (Open " .. tostring(gui:GetAttribute("Open")) .. ", LastChoose " .. tostring(gui:GetAttribute("LastChoose")) .. ")")
task.wait(0.5); sample() -- two deferral checks
assert(wg:GetAttribute("Open") == false and wg:GetAttribute("Deferred") == true and not wcard.Visible,
	"the walk-in card opened over the beat maker once the DM closed (Open " .. tostring(wg:GetAttribute("Open")) .. ", Deferred " .. tostring(wg:GetAttribute("Deferred")) .. "): the chip tap the phone card held was latched")
assert(gui:GetAttribute("Open") == false and gui:GetAttribute("Pending") == 0, "the phone card came back, or holds a pop")
table.insert(out, "dismiss behind the beat maker: the walk-in card stays deferred (Open false, Deferred true)")

-- 4. close the beat maker: the walk-in card opens by itself within 2 s
closeBeatMaker()
local t1 = os.clock()
assert(waitFor(function() return wg:GetAttribute("Open") == true and wg:GetAttribute("Deferred") == false end, 2),
	"the walk-in card did not open within 2 s of the beat maker closing (Open " .. tostring(wg:GetAttribute("Open")) .. ", Deferred " .. tostring(wg:GetAttribute("Deferred")) .. ")")
assert(wg:GetAttribute("Card") == "navx_placement" and wcard.Visible and not chip.Visible, "walk-in card id '" .. tostring(wg:GetAttribute("Card")) .. "', hidden, or the chip still shown")
assert(gui:GetAttribute("Open") == false and gui:GetAttribute("Pending") == 0, "the phone card came back, or holds a pop")
table.insert(out, string.format("beat maker closed: the walk-in card opened by itself %.1f s later", os.clock() - t1))

-- 5. walk away: nothing open
wg:SetAttribute("LastChoose", "")
wg:SetAttribute("Command", "walkaway")
assert(waitFor(function() return wg:GetAttribute("Open") == false and wg:GetAttribute("LastChoose") == "ok" end, 5),
	"WALK AWAY did not close the card (Open " .. tostring(wg:GetAttribute("Open")) .. ", LastChoose " .. tostring(wg:GetAttribute("LastChoose")) .. ")")
wg:SetAttribute("Command", "ok") -- dismiss a result card, if walking away showed one
task.wait(0.3); sample()
assert(not wcard.Visible and not chip.Visible and not pcard.Visible and (wg:GetAttribute("Token") or "") == "", "a card, the chip or a token is left")
assert(both == 0, both .. " of " .. samples .. " samples saw both cards open")
table.insert(out, "walk away: nothing open; " .. samples .. " samples, never both cards")

-- 6. open the beat maker and leave it open (t58a spawns a walk-in behind it)
openBeatMaker("for t58a")
table.insert(out, "beat maker open for t58a")
return "T57F PLAY OK\n" .. table.concat(out, "\n")
