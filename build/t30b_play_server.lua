-- Server, during play (after t30): the player owns the PLUCK voice, not CHIME.
local p = game:GetService("Players"):GetPlayers()[1]
local hook = game:GetService("ServerScriptService").OK._StudioTestHook
assert(hook:Invoke("GrantGear", p.UserId, "voice_pluck"), "grant failed")
local prof = hook:Invoke("GetProfile", p.UserId)
assert(prof.gear.voice_pluck and not prof.gear.voice_chime, "gear state wrong")
return "T30B PLAY OK: PLUCK voice granted"
