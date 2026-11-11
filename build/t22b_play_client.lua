-- Client, during play (after t22): FIRE is refused from the lounge (too far); near the speakers the button shows after
-- the first bar and sends once; the screens count it; your own nameplate shows the career year, level and rank. A16: the
-- longest line, YEAR 15 · LV 10 · STUDIO LEGEND · 🔥 1234, measured at 11 px (TextService), fits the plate's width, and the
-- plate's height stays 48 px.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local char = player.Character; local root = char.HumanoidRootPart; local hum = char.Humanoid
local NP = RS.OK.NowPlaying
local btn = player.PlayerGui:WaitForChild("OK_Fire"):WaitForChild("FireButton")
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local out = {}
if hum.Sit then hum.Sit = false; task.wait(0.4) end
root.CFrame = CFrame.new(20, 3.5, 0); task.wait(1.0)
local far = RS.OK.Remotes.Fire_Send:InvokeServer(NP:GetAttribute("Token"))
assert(not far.ok and (far.reason == "far" or far.reason == "early"), "FIRE from the lounge: " .. tostring(far.reason))
task.wait(2.2)
assert(not btn.Visible, "FIRE button shown from the lounge")
local far2 = RS.OK.Remotes.Fire_Send:InvokeServer(NP:GetAttribute("Token"))
assert(not far2.ok and far2.reason == "far", "FIRE from the lounge after the first bar: " .. tostring(far2.reason))
table.insert(out, "refused from the lounge (too far); no button there")
root.CFrame = CFrame.new(70, 3.5, -2); task.wait(0.8)
assert(waitFor(function() return btn.Visible end, 3), "FIRE button not shown near the speakers")
assert(btn.AbsoluteSize.Y >= 44, "FIRE button under 44 px")
btn:SetAttribute("LastFire", ""); btn:SetAttribute("Command", "fire")
assert(waitFor(function() return btn:GetAttribute("LastFire") ~= "" end, 3) and btn:GetAttribute("LastFire") == "ok", "FIRE not sent: " .. tostring(btn:GetAttribute("LastFire")))
assert(waitFor(function() return NP:GetAttribute("Fires") == 1 and workspace.OKStudio.ControlRoom.Screen_Side.Text.Label.Text:find("🔥 1") end, 3), "screens did not count the FIRE")
assert(waitFor(function() return btn.Text:find("SENT") end, 2), "button did not switch to SENT")
btn:SetAttribute("LastFire", ""); btn:SetAttribute("Command", "fire")
assert(waitFor(function() return btn:GetAttribute("LastFire") == "again" end, 2), "second FIRE on one airing not refused")
local again = RS.OK.Remotes.Fire_Send:InvokeServer(NP:GetAttribute("Token")); assert(not again.ok and again.reason == "again", "server allowed a second FIRE")
table.insert(out, "near the speakers: button after the first bar (" .. btn.AbsoluteSize.Y .. " px), FIRE sent once, screens show 🔥 1, a second is refused")
local plate = char.Head:FindFirstChild("OK_Nameplate")
assert(plate and plate.NameText.Text == player.DisplayName and plate.StatsText.Text:find("LV " .. player:GetAttribute("Level")), "nameplate missing or wrong")
assert(waitFor(function() return plate.StatsText.Text:find("^YEAR " .. tostring(player:GetAttribute("Year")) .. " · ") ~= nil end, 3), "nameplate has no year: " .. plate.StatsText.Text)
assert(plate.PlayerToHideFrom == player, "your own nameplate shows to you (PlayerToHideFrom " .. tostring(plate.PlayerToHideFrom) .. ")")
table.insert(out, "nameplate (hidden from you): " .. plate.NameText.Text .. " / " .. plate.StatsText.Text)
local WORST = "YEAR 15 · LV 10 · STUDIO LEGEND · 🔥 1234"
local need = game:GetService("TextService"):GetTextSize(WORST, 11, plate.StatsText.Font, Vector2.new(10000, 100))
assert(plate.Size == UDim2.fromOffset(plate.Size.X.Offset, 48), "the plate's height moved: " .. tostring(plate.Size))
assert(need.X <= plate.Size.X.Offset, string.format("the longest line needs %d px at 11 px, the plate is %d wide", need.X, plate.Size.X.Offset))
table.insert(out, string.format("longest line at 11 px: %d px, plate %dx%d", need.X, plate.Size.X.Offset, plate.Size.Y.Offset))
return "T22B PLAY OK\n" .. table.concat(out, "\n")
