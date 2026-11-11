-- Server, during play (walk-ins Task 7, before t45b): a known career for the HUD pills and the Career tab. Reset the
-- career (t44 leaves Studio Two owned), then Aura 380 and Followers 9,400 with no placements, so Studio Two is LOCKED.
local p = game:GetService("Players"):GetPlayers()[1]; assert(p, "no player")
local hook = game:GetService("ServerScriptService").OK:WaitForChild("_StudioCareerHook", 5)
assert(hook, "no _StudioCareerHook (did Career.Init run?)")
assert(hook:Invoke("Reset", p.UserId) == true, "career reset failed")
assert(hook:Invoke("Set", p.UserId, { aura = 380, followers = 9400 }) == true, "career Set failed")
assert(p:GetAttribute("Aura") == 380 and p:GetAttribute("Followers") == 9400 and p:GetAttribute("Placements") == 0,
  "career attributes not published: Aura " .. tostring(p:GetAttribute("Aura")) .. ", Followers " .. tostring(p:GetAttribute("Followers"))
  .. ", Placements " .. tostring(p:GetAttribute("Placements")))
return "T45A PLAY OK: career reset; Aura 380, Followers 9,400, no placements"
