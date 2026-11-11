-- Server, during play (after t28d): skip through the three airings to the vote; Dee is the planted favourite.
local SSS, RS = game:GetService("ServerScriptService"), game:GetService("ReplicatedStorage")
local cy = SSS.OK._StudioCypherHook; local CY = RS.OK.Cypher
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
for i = 1, 3 do
  assert(waitFor(function() return RS.OK.NowPlaying:GetAttribute("Active") end, 6), "entry " .. i .. " did not air")
  cy:Invoke("Skip")
  task.wait(0.3)
end
assert(waitFor(function() return CY:GetAttribute("Phase") == "vote" end, 8), "vote did not open after the last entry")
local st = cy:Invoke("State")
local dee, cyl
for l, n in pairs(st.names) do if n == "Dee Test" then dee = l elseif n == "Cy Test" then cyl = l end end
assert(dee and cyl, "letters not assigned")
local own = cy:Invoke("Vote", -2802, dee); assert(not own.ok and own.reason == "own", "self-vote allowed")
assert(cy:Invoke("Vote", -2801, dee).ok and cy:Invoke("Vote", -2802, cyl).ok, "pretend votes failed")
assert(not cy:Invoke("Vote", -2801, cyl).ok, "voted twice")
game:GetService("Players"):GetPlayers()[1]:SetAttribute("_T28Fav", dee)
return "T28E OK: three entries aired; vote open; self-vote and double vote refused; Cy -> " .. dee .. " (Dee), Dee -> " .. cyl
