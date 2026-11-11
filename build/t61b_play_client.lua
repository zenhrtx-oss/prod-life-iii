-- Client, during play (Wave 1b Task 4; Review Focus 4), after t61a's tail: a fresh career log at Aura -12, then the
-- heal of 5 (to -7). The toast names the amount healed: OK_UI.Toast (PanelUI's, through the InteractionEvent "Toast"
-- path) reads "the internet forgot. +5 AURA". The HUD's Aura listener floated the same change: LastFloat is "+5 AURA" and
-- the newest aura entry in FloatLog is aura|+5 AURA, in the Aura pill's column.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui", 10)
local ui = pg:WaitForChild("OK_UI", 10); assert(ui, "no OK_UI")
local toast = ui:WaitForChild("Toast", 5); assert(toast, "no Toast label in OK_UI (PanelUI)")
local career = ui:WaitForChild("Career", 5); local aura = career and career:FindFirstChild("Aura")
assert(aura, "no Career.Aura pill")
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local TOAST, FLOAT = "the internet forgot. +5 AURA", "+5 AURA"

assert(waitFor(function() return player:GetAttribute("Aura") == -7 end, 3), "Aura is " .. tostring(player:GetAttribute("Aura")) .. " (t61a heals -12 by 5 to -7)")
assert(waitFor(function() return toast.Text == TOAST end, 3), "the toast reads '" .. toast.Text .. "', want '" .. TOAST .. "'")
assert(waitFor(function() return ui:GetAttribute("LastFloat") == FLOAT end, 3), "LastFloat is '" .. tostring(ui:GetAttribute("LastFloat")) .. "', want '" .. FLOAT .. "'")
local newest
for item in string.gmatch(ui:GetAttribute("FloatLog") or "", "[^;]+") do
	if item:sub(1, 5) == "aura|" then newest = item end
end
local x = newest and tonumber(string.match(newest, "^aura|%+5 AURA|(%-?%d+)|%-?%d+$"))
assert(x, "the newest aura entry in FloatLog is '" .. tostring(newest) .. "', want aura|+5 AURA|x|y")
local auraX = aura.AbsolutePosition.X - ui.AbsolutePosition.X
assert(x == auraX, "the heal's float is at x " .. x .. ", want the Aura pill's column " .. auraX)
return "T61B PLAY OK\ntoast '" .. toast.Text .. "'; LastFloat '" .. FLOAT .. "'; newest aura entry " .. newest .. "; Aura " .. tostring(player:GetAttribute("Aura"))
