-- Client, during play (after t28e): VOTE from the bar (your own letter is not offered); vote for the favourite.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local bar = player.PlayerGui.OK_Cypher.Bar
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local root = player.Character.HumanoidRootPart; root.CFrame = CFrame.new(70, 3.5, -2); task.wait(0.5)
local mine, fav = player.PlayerGui:GetAttribute("CypherLetter"), player:GetAttribute("_T28Fav")
assert(waitFor(function() return bar.Buttons["Vote" .. fav].Visible end, 3), "vote button for the favourite missing")
assert(not bar.Buttons["Vote" .. mine].Visible, "your own entry is offered for voting")
assert(bar.Buttons["Vote" .. fav].AbsoluteSize.Y >= 44, "vote button under 44 px")
local own = RS.OK.Remotes.Cypher_Vote:InvokeServer(mine); assert(not own.ok and own.reason == "own", "server allowed a self-vote")
bar:SetAttribute("LastAction", ""); bar:SetAttribute("Command", "vote:" .. fav)
assert(waitFor(function() return bar:GetAttribute("LastAction") == "ok" end, 3), "vote failed: " .. tostring(bar:GetAttribute("LastAction")))
assert(waitFor(function() return bar.Info.Text:find("You voted") end, 2), "bar did not confirm the vote")
return "T28F PLAY OK: own letter " .. mine .. " not offered (server refuses it too); voted " .. fav
