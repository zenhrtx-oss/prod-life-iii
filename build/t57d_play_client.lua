-- Client, during play (after t57c: scam_label waits behind the open beat maker, scam_curator expired behind it): before
-- closing, Pending is 1 (2 would mean the client ignored the expire), Open false, Deferred true, the icon's count reads
-- 1 and the icon shakes (its Body's UIScale leaves 1 within 14 s: a pop that waits shakes it every 12 s). Closing
-- the beat maker (Command close) opens the card within 2 s with Card scam_label, and at no 0.1 s sample is Card
-- scam_curator. Reopening the beat maker at the studio PC with that card open hides the card (OK_DAW draws under
-- OK_Phone) while Open, Token and Card keep it (its slot stays taken), and closing the beat maker brings it back;
-- dismiss leaves Pending 0 and nothing open.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui", 10)
local gui = pg:WaitForChild("OK_Phone", 10); assert(gui, "no OK_Phone gui")
local daw = pg.OK_DAW.DAW
local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); local cam = workspace.CurrentCamera
local A, B = "scam_curator", "scam_label"
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
gui:SetAttribute("ForceViewport", nil); daw:SetAttribute("CompactForced", nil)
assert(daw.Visible, "the beat maker should still be open from t57b")
local card, icon = gui:FindFirstChild("Card", true), gui:FindFirstChild("Icon", true)
local badge, scale = icon and icon:FindFirstChild("Count", true), icon and icon:FindFirstChild("Shake", true)
assert(card and icon and badge and scale and scale:IsA("UIScale"), "Card, Icon, its Count badge or its Shake UIScale missing")
task.wait(0.5) -- one deferral check

-- 1. before closing: one pop waits, nothing open, the icon counts it and shakes
assert(gui:GetAttribute("Pending") == 1, "Pending " .. tostring(gui:GetAttribute("Pending")) .. " (want 1: 2 means the expire for " .. A .. " was ignored)")
assert(gui:GetAttribute("Open") == false and not card.Visible, "a phone card is open over the beat maker")
assert(gui:GetAttribute("Deferred") == true, "Deferred " .. tostring(gui:GetAttribute("Deferred")) .. " with a pop waiting behind the beat maker")
assert(icon.Visible and badge.Visible and badge.Text == "1", "the icon's count reads '" .. tostring(badge.Text) .. "' (visible " .. tostring(badge.Visible) .. "), want 1")
local peak = 1
assert(waitFor(function() peak = math.max(peak, scale.Scale); return scale.Scale > 1.02 end, 14), string.format("the icon did not shake within 14 s (UIScale peak %.2f)", peak))
local out = { string.format("behind the beat maker: Pending 1, Open false, Deferred true, count 1, icon shook (scale %.2f)", peak) }

-- 2. close the beat maker: only B opens
daw:SetAttribute("Command", "close")
assert(waitFor(function() return not daw.Visible end, 3), "beat maker did not close")
if hum and hum.Sit then hum.Sit = false end
cam.CameraType = Enum.CameraType.Custom
local t1, opened = os.clock(), false
while os.clock() - t1 < 2 do
	local c = gui:GetAttribute("Card")
	assert(c ~= A, "the expired " .. A .. " opened on the client")
	if c == B and gui:GetAttribute("Open") == true then opened = true; break end
	task.wait(0.1)
end
assert(opened, "the waiting " .. B .. " did not open within 2 s of closing the beat maker (Open " .. tostring(gui:GetAttribute("Open")) .. ", Card '" .. tostring(gui:GetAttribute("Card")) .. "')")
assert(card.Visible and gui:GetAttribute("Deferred") == false and not badge.Visible, "card hidden, still Deferred, or the count still shown after opening")
table.insert(out, string.format("beat maker closed: %s opened in %.1f s, %s never showed", B, os.clock() - t1, A))

-- 3. the card on screen hides behind the beat maker and keeps its slot: reopen the beat maker at the studio PC (as
--    t57b opens it) with B open; within 1 s the Card frame is hidden while Open stays true and Token / Card keep B
--    (no walk-in card may open meanwhile), the count never shows for it; close the beat maker: the card is back within
--    1 s, still B, Open true, nothing else opened
local tokenB = gui:GetAttribute("Token")
assert(type(tokenB) == "string" and tokenB ~= "", "no Token with " .. B .. " open")
local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); assert(root, "no HumanoidRootPart")
local screen = workspace.OKStudio.ControlRoom.Screen_Main
local pos = Vector3.new(72.0, 3.5, -5.5)
root.CFrame = CFrame.lookAt(pos, Vector3.new(screen.Position.X, pos.Y, screen.Position.Z)); task.wait(1.0)
cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(-4, 3, 0), screen.Position); task.wait(1.5)
local prompt = screen:FindFirstChildWhichIsA("ProximityPrompt", true)
for _ = 1, 4 do prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); task.wait(0.8); if daw.Visible then break end end
assert(daw.Visible, "beat maker did not reopen with " .. B .. " on screen")
assert(waitFor(function() return not card.Visible end, 1), "the open card is still drawn over the beat maker")
assert(gui:GetAttribute("Open") == true and gui:GetAttribute("Card") == B and gui:GetAttribute("Token") == tokenB and gui:GetAttribute("Pending") == 1,
	"hidden behind the beat maker the card lost its slot (Open " .. tostring(gui:GetAttribute("Open")) .. ", Card '" .. tostring(gui:GetAttribute("Card"))
	.. "', Token '" .. tostring(gui:GetAttribute("Token")) .. "', Pending " .. tostring(gui:GetAttribute("Pending")) .. ")")
assert(not badge.Visible, "the icon counts the hidden card (reads '" .. tostring(badge.Text) .. "')")
task.wait(0.5) -- two deferral checks: it stays hidden
assert(not card.Visible and gui:GetAttribute("Open") == true and gui:GetAttribute("Token") == tokenB, "the hidden card came back over the beat maker, or went")
daw:SetAttribute("Command", "close")
assert(waitFor(function() return not daw.Visible end, 3), "beat maker did not close the second time")
if hum and hum.Sit then hum.Sit = false end
cam.CameraType = Enum.CameraType.Custom
assert(waitFor(function() return card.Visible end, 1), "the hidden card did not come back within 1 s of closing the beat maker")
assert(gui:GetAttribute("Open") == true and gui:GetAttribute("Card") == B and gui:GetAttribute("Token") == tokenB and gui:GetAttribute("Pending") == 1
	and gui:GetAttribute("Deferred") == false and not badge.Visible,
	"back from the beat maker: Open " .. tostring(gui:GetAttribute("Open")) .. ", Card '" .. tostring(gui:GetAttribute("Card")) .. "', Token '"
	.. tostring(gui:GetAttribute("Token")) .. "', Pending " .. tostring(gui:GetAttribute("Pending")) .. ", Deferred " .. tostring(gui:GetAttribute("Deferred")))
table.insert(out, "beat maker reopened over the card: hidden with Open true and its token kept; back on close")

-- 4. dismiss
gui:SetAttribute("LastChoose", "")
gui:SetAttribute("Command", "dismiss")
assert(waitFor(function() return gui:GetAttribute("Open") == false and gui:GetAttribute("LastChoose") == "ok" end, 5),
	"dismiss did not close the card (Open " .. tostring(gui:GetAttribute("Open")) .. ", LastChoose " .. tostring(gui:GetAttribute("LastChoose")) .. ")")
assert(gui:GetAttribute("Pending") == 0 and (gui:GetAttribute("Token") or "") == "" and not card.Visible, "Pending " .. tostring(gui:GetAttribute("Pending")) .. " or a token / card left after dismiss")
table.insert(out, "dismiss: Pending 0, nothing open")
return "T57D PLAY OK\n" .. table.concat(out, "\n")
