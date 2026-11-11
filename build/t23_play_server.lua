-- Server, during play (after t22d): a clean daily state; note XP and Cred.
local p = game:GetService("Players"):GetPlayers()[1]
local hook = game:GetService("ServerScriptService").OK._StudioTestHook
assert(hook:Invoke("ResetDaily", p.UserId, 0, nil), "reset failed")
local prof = hook:Invoke("GetProfile", p.UserId)
p:SetAttribute("_T23XP", prof.xp); p:SetAttribute("_T23Cred", prof.cred or 0)
return "T23 PLAY OK: daily state reset"
