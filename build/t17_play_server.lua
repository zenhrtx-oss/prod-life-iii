-- Server, during play: reset the studio tour for the test player and remember their XP (Studio-only hook).
local p = game:GetService("Players"):GetPlayers()[1]; assert(p, "no player")
local hook = game:GetService("ServerScriptService").OK._StudioTestHook
assert(hook:Invoke("ResetTour", p.UserId) == true and hook:Invoke("ResetSessions", p.UserId) == true and hook:Invoke("ResetGear", p.UserId) == true, "reset failed")
local prof = hook:Invoke("GetProfile", p.UserId)
assert(type(prof.tour) == "table" and not prof.tour.done and next(prof.tour.got) == nil, "tour not reset")
p:SetAttribute("_T17XP", prof.xp); p:SetAttribute("_T17Cred", prof.cred or 0)
return "T17 OK: tour and sessions reset at " .. prof.xp .. " XP, $" .. (prof.cred or 0)
