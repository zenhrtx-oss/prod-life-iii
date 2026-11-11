-- Server, during play (after t21b): give the player enough money and level for the Ice neon.
local p = game:GetService("Players"):GetPlayers()[1]
local hook = game:GetService("ServerScriptService").OK._StudioTestHook
local prof = hook:Invoke("GetProfile", p.UserId)
if prof.level < 3 then hook:Invoke("AddXP", p.UserId, 250 - prof.xp, nil) end
hook:Invoke("GrantCred", p.UserId, 1000)
return "T21C OK: +$1000"
