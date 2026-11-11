-- Client, during play: the HUD shows level, XP bar, a +XP float and the LEVEL UP banner after t15 grants XP.
local player = game:GetService("Players").LocalPlayer
local gui = player.PlayerGui:WaitForChild("OK_UI"); local hud = gui:WaitForChild("HUD")
local expect = player:GetAttribute("_ExpectLevel")
local t0 = os.clock(); while os.clock() - t0 < 4 and gui:GetAttribute("LastLevelUp") ~= expect do task.wait(0.1) end
assert(hud.Visible, "HUD hidden")
assert(player:GetAttribute("Level") == expect, "Level attribute " .. tostring(player:GetAttribute("Level")) .. " ~= " .. tostring(expect))
assert(hud.Level.Text == "LV " .. tostring(expect), "badge shows " .. hud.Level.Text)
assert(hud.OS.AbsoluteSize.Y >= 44 and hud.OS.AbsoluteSize.X >= 44 and hud.Mute.AbsoluteSize.Y >= 44 and hud.Mute.AbsoluteSize.X >= 44, "HUD buttons under 44 px")
assert(gui:GetAttribute("LastLevelUp") == expect, "no LEVEL UP banner for level " .. tostring(expect))
assert((gui:GetAttribute("Floats") or 0) >= 1, "no +XP float")
assert(hud.XPBar.Fill.Size.X.Scale >= 0 and hud.XPText.Text:find("XP"), "XP bar text missing")
return "T15B PLAY OK: HUD shows " .. hud.Level.Text .. " (" .. hud.XPText.Text .. "), +XP float, LEVEL " .. tostring(expect) .. " banner"
