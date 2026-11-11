-- Server, during play (after t19): make the finished starter the active request again (a repeat) and note XP/Cred.
local p = game:GetService("Players"):GetPlayers()[1]; assert(p, "no player")
local hook = game:GetService("ServerScriptService").OK._StudioTestHook
local prof = hook:Invoke("GetProfile", p.UserId)
assert(prof.sessions and prof.sessions.done and prof.sessions.done.j1, "starter should be done after t17b")
assert(hook:Invoke("SetActiveRequest", p.UserId, "j1"), "could not set the active request")
p:SetAttribute("_T20XP", prof.xp); p:SetAttribute("_T20Cred", prof.cred or 0); p:SetAttribute("_T20Credits", #prof.credits)
return "T20 PLAY OK: j1 active again as a repeat"
