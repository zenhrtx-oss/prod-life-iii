-- Server, during play (after t20b): the repeat paid no XP or Cred but added a credit; nothing is active now.
local p = game:GetService("Players"):GetPlayers()[1]
local hook = game:GetService("ServerScriptService").OK._StudioTestHook
local prof = hook:Invoke("GetProfile", p.UserId)
assert(prof.xp == p:GetAttribute("_T20XP") and (prof.cred or 0) == p:GetAttribute("_T20Cred"), "a repeat paid XP or Cred")
assert(#prof.credits == p:GetAttribute("_T20Credits") + 1 and prof.credits[#prof.credits].t == "Late Bus Home", "repeat credit not added")
assert(prof.sessions.active == nil and prof.sessions.deliveries >= 2, "session state wrong after the repeat")
return "T20C OK: repeat paid nothing, added a credit, cleared the active request"
