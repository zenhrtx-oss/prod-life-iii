-- Server, during play (after t45b): Studio Two becomes affordable and open to you: 1 placement and exactly $5,000.
local p = game:GetService("Players"):GetPlayers()[1]; assert(p, "no player")
local hook = game:GetService("ServerScriptService").OK:WaitForChild("_StudioCareerHook", 5)
assert(hook, "no _StudioCareerHook (did Career.Init run?)")
assert(hook:Invoke("Set", p.UserId, { placements = 1, money = 5000 }) == true, "career Set failed")
assert(p:GetAttribute("Placements") == 1 and p:GetAttribute("Cred") == 5000,
  "Placements " .. tostring(p:GetAttribute("Placements")) .. ", Money " .. tostring(p:GetAttribute("Cred")))
return "T45C PLAY OK: 1 placement, $5,000 (Aura 380 from t45a)"
