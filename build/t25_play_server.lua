-- Server, during play (after t24c): a clean Weekly Single state; note XP and Cred.
local p = game:GetService("Players"):GetPlayers()[1]
local hook = game:GetService("ServerScriptService").OK._StudioTestHook
assert(hook:Invoke("ResetWeekly", p.UserId), "reset failed")
local prof = hook:Invoke("GetProfile", p.UserId)
p:SetAttribute("_T25XP", prof.xp); p:SetAttribute("_T25Cred", prof.cred or 0)
return "T25 PLAY OK: weekly reset"
