-- Client, during play (after t58g respawned the player with a DM open and one waiting, an expire each; the last file
-- of the suite): within 2 s nothing is open and nothing is held (Open false, Pending 0, no Token), and no phone card
-- opens in the next 5 s.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui", 10)
local gui = pg:WaitForChild("OK_Phone", 10); assert(gui, "no OK_Phone gui (ResetOnSpawn should keep it across the respawn)")
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local card = gui:FindFirstChild("Card", true); assert(card, "no Card frame")
assert(waitFor(function() return gui:GetAttribute("Open") == false and gui:GetAttribute("Pending") == 0 end, 2),
	"the respawn's expires did not clear the client (Open " .. tostring(gui:GetAttribute("Open")) .. ", Pending " .. tostring(gui:GetAttribute("Pending")) .. ")")
assert(not card.Visible and (gui:GetAttribute("Token") or "") == "", "the Card frame or a Token is left after the respawn")
local t0 = os.clock()
while os.clock() - t0 < 5 do
	assert(gui:GetAttribute("Open") == false and not card.Visible, "a phone card opened " .. string.format("%.1f", os.clock() - t0) .. " s after the respawn (Card '" .. tostring(gui:GetAttribute("Card")) .. "')")
	task.wait(0.1)
end
assert(gui:GetAttribute("Pending") == 0, "a pop is held after the respawn")
return "T58H PLAY OK: the respawn closed the card and cleared the count; nothing opened in the next 5 s"
