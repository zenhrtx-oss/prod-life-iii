-- Client, during play (after t41, career reset): the career remotes. Unlocking Studio Two with no placements is
-- refused for needs; a too-long or non-string id is invalid; Career_Get's Money matches the Cred attribute.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local R = RS.OK.Remotes
local out = {}
local r1 = R.Career_Unlock:InvokeServer("studio_two")
assert(type(r1) == "table" and not r1.ok and r1.reason == "needs", "studio_two with no placements should be refused for needs: " .. tostring(r1 and r1.reason))
local r2 = R.Career_Unlock:InvokeServer(string.rep("x", 40))
assert(not r2.ok and r2.reason == "invalid", "a 40-character id should be invalid: " .. tostring(r2.reason))
local r3 = R.Career_Unlock:InvokeServer(5)
assert(not r3.ok and r3.reason == "invalid", "a number id should be invalid: " .. tostring(r3.reason))
table.insert(out, "Career_Unlock: studio_two -> needs; 40-char id and a number -> invalid")
local st = R.Career_Get:InvokeServer()
assert(type(st) == "table" and st.stats and #st.gates == 4 and #st.gear == 7, "Career_Get shape wrong")
assert(st.stats.money == player:GetAttribute("Cred"), "Career_Get money " .. tostring(st.stats.money) .. " ~= Cred attribute " .. tostring(player:GetAttribute("Cred")))
table.insert(out, "Career_Get: 4 gates, 7 gear rows, money $" .. st.stats.money .. " = Cred attribute")
return "T41B PLAY OK\n" .. table.concat(out, "\n")
