-- Client, during play (after t58e: a WalkIns Reset dropped the open DM and the waiting one, an expire each): within
-- 2 s nothing is open and nothing is held: Open false, Pending 0, no Token, the icon's count hidden.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui", 10)
local gui = pg:WaitForChild("OK_Phone", 10); assert(gui, "no OK_Phone gui")
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local card, badge = gui:FindFirstChild("Card", true), gui:FindFirstChild("Count", true)
assert(card and badge, "no Card frame or Count badge")
assert(waitFor(function() return gui:GetAttribute("Open") == false and gui:GetAttribute("Pending") == 0 end, 2),
	"the Reset's expires did not clear the client (Open " .. tostring(gui:GetAttribute("Open")) .. ", Pending " .. tostring(gui:GetAttribute("Pending")) .. ")")
assert(not card.Visible and (gui:GetAttribute("Token") or "") == "" and not badge.Visible, "the Card frame, a Token or the count is left after the Reset")
return "T58F PLAY OK: the WalkIns Reset closed the card and cleared the count (Open false, Pending 0)"
