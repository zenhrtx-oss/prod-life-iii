-- Server, during play (after t28g): forget the player's logged steps, then log step 1 twice: it logs once.
local p = game:GetService("Players"):GetPlayers()[1]
local hook = game:GetService("ServerScriptService").OK._StudioTestHook
assert(hook:Invoke("ResetFunnel", p.UserId), "reset failed")
local log0 = hook:Invoke("FunnelLog", p.UserId)
local before = log0[1] or 0
p:SetAttribute("_T29L2", log0[2] or 0); p:SetAttribute("_T29L3", log0[3] or 0)
assert(hook:Invoke("FunnelStep", p.UserId, 1) == true and hook:Invoke("FunnelStep", p.UserId, 1) == false, "step 1 logged twice")
assert((hook:Invoke("FunnelLog", p.UserId)[1] or 0) == before + 1, "log count wrong")
return "T29 PLAY OK: a step logs once, a repeat is ignored"
