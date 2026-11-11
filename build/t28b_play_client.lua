-- Client, during play (after t28): JOIN from the cypher bar.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local bar = player.PlayerGui:WaitForChild("OK_Cypher"):WaitForChild("Bar")
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local d = player.PlayerGui.OK_DAW.DAW; if d.Visible then d:SetAttribute("Command", "close"); task.wait(0.4) end
assert(waitFor(function() return bar.Visible and bar.Buttons.Join.Visible end, 3), "cypher bar / JOIN not shown in the lobby")
assert(bar.Buttons.Join.AbsoluteSize.Y >= 44, "JOIN under 44 px")
bar:SetAttribute("LastAction", ""); bar:SetAttribute("Command", "join")
assert(waitFor(function() return bar:GetAttribute("LastAction") == "ok" and player:GetAttribute("CypherIn") == RS.OK.Cypher:GetAttribute("Round") end, 3), "join failed: " .. tostring(bar:GetAttribute("LastAction")))
assert(waitFor(function() return RS.OK.Cypher:GetAttribute("Entrants") == 3 and not bar.Buttons.Join.Visible end, 2), "entrant count / JOIN still shown")
return "T28B PLAY OK: joined from the bar (" .. bar.Buttons.Join.AbsoluteSize.Y .. " px JOIN); 3 producers in the lobby"
