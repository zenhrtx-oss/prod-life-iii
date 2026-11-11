-- Server, during Play (Studio only; see DEMO_RUNSHEET.md): preps the one player in the session for the live demo.
-- Gives money, Aura and one placement so THE HALL door opens, and after the first passed delivery lifts followers to
-- 1,000 so the YOU'RE BUZZING banner and the superfan visit happen during the tour. Uses the Studio test hooks, which a
-- live server never has. Run: python3 -I tools/mcp_call.py --luaus tools/demo_prep.lua
local Players, SSS = game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]
if not p then return "DEMO PREP: no player in the session yet (press Play and spawn first)" end
local test = SSS.OK:FindFirstChild("_StudioTestHook")
local career = SSS.OK:FindFirstChild("_StudioCareerHook")
if not (test and career) then return "DEMO PREP: hooks missing (is this a Studio Play session?)" end
local uid = p.UserId
test:Invoke("GrantCred", uid, 6000)
career:Invoke("Add", uid, "aura", 300, "WalkIn") -- a known career source with room for these amounts (an unknown source pays 0)
career:Invoke("Add", uid, "placements", 1, "WalkIn") -- a known career source with room for these amounts (an unknown source pays 0)
career:Invoke("Publish", uid)
-- followers to 1,000 after the first passed delivery (Contracts.Delivered fires once per pass; this listens once)
local Contracts = require(game:GetService("ReplicatedStorage").OK.Systems.Contracts)
local conn
conn = Contracts.Delivered:Connect(function(who)
	if who ~= p then return end
	conn:Disconnect()
	task.wait(1.5) -- let the delivery's own floats land first
	local have = p:GetAttribute("Followers") or 0
	if have < 1000 then career:Invoke("Add", uid, "followers", 1000 - have, "WalkIn"); career:Invoke("Publish", uid) end
end)
return ("DEMO PREP OK for %s: +$6,000, +300 Aura, +1 placement; followers go to 1,000 after the first delivery"):format(p.Name)
