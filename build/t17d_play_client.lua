-- Client, during play (after t17c reset): SKIP hides the card and the outline.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local ui = player.PlayerGui:WaitForChild("OK_UI"); local card = ui:WaitForChild("Tour"); local hl = ui:WaitForChild("OK_TourHighlight")
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
assert(waitFor(function() return ui:GetAttribute("TourVisible") == true and ui:GetAttribute("TourCount") == 0 end, 5), "card not back after reset")
assert(card.Skip:IsA("TextButton") and card.Skip.Visible and card.Skip.AbsoluteSize.Y >= 44, "skip button missing or under 44 px")
RS.OK.Remotes.Tour_Skip:FireServer() -- what the SKIP button sends
assert(waitFor(function() return ui:GetAttribute("TourVisible") == false end, 3), "skip did not hide the card")
assert(not card.Visible and not hl.Enabled, "outline left on after skip")
return "T17D PLAY OK: skip hides the card and the outline"
