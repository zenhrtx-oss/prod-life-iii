-- Client, during play (after t45c: 1 placement, Aura 380, $5,000). The Career tab offers "UNLOCK $5,000" for Studio
-- Two; the unlock seam (what the button calls) buys it: the row re-renders OWNED, CareerGates holds studio_two and
-- Money is $0.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local ui = player:WaitForChild("PlayerGui", 10):WaitForChild("OK_UI", 10); assert(ui, "no OK_UI")
local panel = ui:WaitForChild("Panel", 5); assert(panel, "no panel")
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function command(c, t)
  ui:SetAttribute("PanelCommand", c)
  assert(waitFor(function() return ui:GetAttribute("PanelCommand") == "" end, t or 6), "PanelCommand '" .. c .. "' was not taken (Studio seam missing?)")
end
local function action() local r = panel.Content:FindFirstChild("Gate_studio_two"); return r and r:FindFirstChild("Action") end
ui:SetAttribute("PanelCommand", "")
local out = {}
command("os"); command("tab:Career")
assert(waitFor(function() local a = action(); return a and a.Text == "UNLOCK $5,000" end, 3),
  "Studio Two should offer UNLOCK $5,000, reads '" .. tostring(action() and action().Text) .. "'")
assert(action().AbsoluteSize.Y >= 44, "UNLOCK under 44 px")
table.insert(out, "Career tab: Studio Two reads UNLOCK $5,000")
ui:SetAttribute("LastUnlock", "")
command("unlock:studio_two", 8)
assert(waitFor(function() local a = action(); return a and a.Text == "OWNED" end, 3),
  "Studio Two row did not re-render OWNED: '" .. tostring(action() and action().Text) .. "' (LastUnlock " .. tostring(ui:GetAttribute("LastUnlock")) .. ")")
assert(waitFor(function() return string.find(player:GetAttribute("CareerGates") or "", "studio_two", 1, true) ~= nil and player:GetAttribute("Cred") == 0 end, 3),
  "after the unlock: CareerGates '" .. tostring(player:GetAttribute("CareerGates")) .. "', Money " .. tostring(player:GetAttribute("Cred")))
table.insert(out, "unlock: row OWNED, CareerGates '" .. player:GetAttribute("CareerGates") .. "', Money $0")
panel.Visible = false
return "T45D PLAY OK\n" .. table.concat(out, "\n")
