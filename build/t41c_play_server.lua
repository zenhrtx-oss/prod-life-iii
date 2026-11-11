-- Server, during play (after t41b): set up a real first delivery for the career feed. Career reset, sessions reset so
-- the starter j1 counts as a first delivery, j1 active; note Followers / Aura for t41e. Wave 3 Task 3 (fix round 1): the
-- recent beats emptied too (SetRecent({}), checked empty), so t41e can see exactly what t41d's real deliveries recorded.
local p = game:GetService("Players"):GetPlayers()[1]; assert(p, "no player")
local SOK = game:GetService("ServerScriptService").OK
local hook, test = SOK._StudioCareerHook, SOK._StudioTestHook
assert(hook:Invoke("Reset", p.UserId) == true, "career reset failed")
assert(test:Invoke("ResetSessions", p.UserId) == true, "sessions reset failed")
assert(test:Invoke("SetActiveRequest", p.UserId, "j1") == true, "could not make j1 active")
local kept = test:Invoke("SetRecent", p.UserId, {})
assert(type(kept) == "table" and #kept == 0, "SetRecent({}) did not empty the recent beats (before the Task 3 sync of OK/Main it returns nil)")
local recent = test:Invoke("Recent", p.UserId)
assert(type(recent) == "table" and #recent == 0, "the recent beats are not empty after SetRecent({})")
p:SetAttribute("_T41F", p:GetAttribute("Followers") or 0); p:SetAttribute("_T41A", p:GetAttribute("Aura") or 0)
return "T41C PLAY OK: career, sessions and recent beats reset, j1 active as a first delivery (followers " .. p:GetAttribute("_T41F") .. ", aura " .. p:GetAttribute("_T41A") .. ")"
