-- Client, during play (after t58c: the DM the client had opened expired on the server, an expire sent): within 2 s
-- the card is gone: Open false, Pending 0, Token cleared, the Card frame hidden.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui", 10)
local gui = pg:WaitForChild("OK_Phone", 10); assert(gui, "no OK_Phone gui")
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local card = gui:FindFirstChild("Card", true); assert(card, "no Card frame")
assert(waitFor(function() return gui:GetAttribute("Open") == false and gui:GetAttribute("Pending") == 0 and (gui:GetAttribute("Token") or "") == "" end, 2),
	"the expired DM is still on the client (Open " .. tostring(gui:GetAttribute("Open")) .. ", Pending " .. tostring(gui:GetAttribute("Pending"))
	.. ", Token '" .. tostring(gui:GetAttribute("Token")) .. "')")
assert(not card.Visible and (gui:GetAttribute("Card") or "") == "", "the Card frame or the Card id is left after the expire")
return "T58D PLAY OK: the opened DM's expire closed the card (Open false, Pending 0, Token cleared)"
