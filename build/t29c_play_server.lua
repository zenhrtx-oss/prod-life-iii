-- Server, during play (after t29b): steps 2 and 3 were each logged exactly once, despite two opens.
local p = game:GetService("Players"):GetPlayers()[1]
local hook = game:GetService("ServerScriptService").OK._StudioTestHook
local log = hook:Invoke("FunnelLog", p.UserId)
local prof = hook:Invoke("GetProfile", p.UserId)
local d2, d3 = (log[2] or 0) - p:GetAttribute("_T29L2"), (log[3] or 0) - p:GetAttribute("_T29L3")
assert(d2 == 1 and d3 == 1 and prof.funnel["2"] and prof.funnel["3"], "since the reset, steps 2/3 logged " .. d2 .. "/" .. d3 .. " times")
return "T29C OK: 'Used something' and 'Opened a beat maker' logged once each (two opens); remembered in the profile"
