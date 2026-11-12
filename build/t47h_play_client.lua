-- Client, during play (after t47g: cypher idle, beat maker closed): the card, open by itself since t47f's cypher lobby,
-- is open with everything clear (or opens within 5 s if it was still held); WALK AWAY closes it.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui", 10)
local gui = pg:WaitForChild("OK_WalkIn", 10); assert(gui, "no OK_WalkIn gui")
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local chip, card = gui:FindFirstChild("Waiting", true), gui:FindFirstChild("Card", true)
assert(waitFor(function() return gui:GetAttribute("Open") == true and gui:GetAttribute("Deferred") == false end, 5),
  "the card did not open within 5 s of all clear (Open " .. tostring(gui:GetAttribute("Open")) .. ", Deferred " .. tostring(gui:GetAttribute("Deferred")) .. ")")
assert(card.Visible and not chip.Visible, "card hidden or chip still shown after opening")
assert(gui:GetAttribute("Card") == "navx_placement", "card id " .. tostring(gui:GetAttribute("Card")))
gui:SetAttribute("LastChoose", "")
gui:SetAttribute("Command", "walkaway")
assert(waitFor(function() return gui:GetAttribute("Open") == false and gui:GetAttribute("LastChoose") == "ok" end, 5),
  "WALK AWAY did not close the card (Open " .. tostring(gui:GetAttribute("Open")) .. ", LastChoose " .. tostring(gui:GetAttribute("LastChoose")) .. ")")
assert(not card.Visible and not chip.Visible and (gui:GetAttribute("Token") or "") == "", "card, chip or token left behind after walking away")
gui:SetAttribute("Command", "ok") -- dismiss a result card, if walking away showed one
return "T47H PLAY OK: open with all clear; WALK AWAY closed it"
