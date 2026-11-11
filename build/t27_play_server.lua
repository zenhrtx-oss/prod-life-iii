-- Server, during play (after t26d): the player owns the TAPE kit, not IRON.
local p = game:GetService("Players"):GetPlayers()[1]
local hook = game:GetService("ServerScriptService").OK._StudioTestHook
assert(hook:Invoke("GrantGear", p.UserId, "kit_tape"), "grant failed")
local prof = hook:Invoke("GetProfile", p.UserId)
assert(prof.gear.kit_tape and not prof.gear.kit_iron, "gear state wrong")
return "T27 PLAY OK: TAPE kit granted"
