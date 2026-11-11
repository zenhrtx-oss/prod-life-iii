-- Server, during play (after t28f): the reveal names Dee Test with 2 votes; entrants get their entry XP; the monitors
-- are free again; then the cypher goes idle.
local SSS, RS = game:GetService("ServerScriptService"), game:GetService("ReplicatedStorage")
local cy = SSS.OK._StudioCypherHook; local CY = RS.OK.Cypher
local hook = SSS.OK._StudioTestHook
local p = game:GetService("Players"):GetPlayers()[1]
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
cy:Invoke("Skip")
assert(waitFor(function() return CY:GetAttribute("Phase") == "reveal" end, 3), "no reveal")
assert(CY:GetAttribute("Winner") == "Dee Test" and CY:GetAttribute("Result"):find("2 votes"), "wrong winner: " .. tostring(CY:GetAttribute("Result")))
assert(CY:GetAttribute("Reveal"):find("Dee Test") and CY:GetAttribute("Reveal"):find(p.DisplayName), "reveal does not name the entries")
local prof = hook:Invoke("GetProfile", p.UserId)
assert(prof.cypher and prof.cypher.entered >= 1, "entry not recorded")
assert(RS.OK.NowPlaying:GetAttribute("Reserved") == false, "monitors still reserved")
cy:Invoke("Skip")
assert(waitFor(function() return CY:GetAttribute("Phase") == "idle" and p:GetAttribute("CypherIn") == nil end, 3), "cypher did not return to idle")
-- your own cypher beat is still yours: the history records the real producer, so airing it later is not a "copy"
local hist = SSS.OK._StudioMonitorHook:Invoke("History")
local mine
for _, h in ipairs(hist) do if h.uid == p.UserId then mine = h end end
assert(mine, "the player's cypher entry is not in the history under their real id")
local _, why = require(RS.OK.Systems.Flips).Judge(hist, p.UserId, mine.pattern, nil)
assert(why == nil, "your own cypher entry counts as someone else's beat: " .. tostring(why))
return "T28G OK: " .. CY:GetAttribute("Result") .. "; entry recorded; monitors free; back to idle; your entry stays yours in the history"
