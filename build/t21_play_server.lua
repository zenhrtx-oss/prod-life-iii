-- Server, during play (after t20c): note the player's gear state for the gear tests.
local p = game:GetService("Players"):GetPlayers()[1]
local hook = game:GetService("ServerScriptService").OK._StudioTestHook
local prof = hook:Invoke("GetProfile", p.UserId)
assert(prof.gear and prof.gear.rollfx and not prof.gear.swing, "expected Roll FX (bought in t17b) and no Swing Unit")
assert((prof.cred or 0) < 900, "need less than $900 for the 'not enough money' check, have " .. tostring(prof.cred))
return "T21 PLAY OK: Roll FX owned, Swing not, $" .. prof.cred .. ", level " .. prof.level
