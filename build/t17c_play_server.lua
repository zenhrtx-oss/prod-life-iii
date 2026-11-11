-- Server, during play (after t17b): the tour is done with all four steps and paid exactly once; a repeat step pays nothing.
-- Then reset it again for the skip test.
local p = game:GetService("Players"):GetPlayers()[1]; assert(p, "no player")
local hook = game:GetService("ServerScriptService").OK._StudioTestHook
local Tour = require(game:GetService("ReplicatedStorage").OK.Systems.Tour)
local prof = hook:Invoke("GetProfile", p.UserId)
local t = prof.tour
assert(t.done == true and not t.skipped, "tour not done")
for _, s in ipairs(Tour.Steps) do assert(t.got[s.id], "step missing: " .. s.id) end
local gained = prof.xp - (p:GetAttribute("_T17XP") or 0)
assert(gained >= Tour.RewardXP + 38, "tour reward + delivery XP not paid: +" .. gained)
local credGain = (prof.cred or 0) - (p:GetAttribute("_T17Cred") or 0)
assert(credGain == 350, "starter pays $600 ($400 x1.5 for 3 stars), minus $250 for Roll FX = $350, got " .. credGain)
assert(prof.gear.rollfx == true, "Roll FX not recorded in the profile")
local last = prof.credits[#prof.credits]
assert(last and last.t == "Late Bus Home" and last.a == "JUNO VALE" and last.s == 3 and prof.sessions.done.j1 == 3 and prof.sessions.active == nil, "credit or session record wrong")
local xp1 = prof.xp
local again = hook:Invoke("TourAdvance", p.UserId, "open")
assert(again == false and hook:Invoke("GetProfile", p.UserId).xp == xp1, "a finished tour paid again")
hook:Invoke("ResetTour", p.UserId)
p:SetAttribute("_T17XP", hook:Invoke("GetProfile", p.UserId).xp)
return "T17C OK: tour done, all " .. #Tour.Steps .. " steps, +" .. gained .. " XP (tour " .. Tour.RewardXP .. " + delivery), money +$600 -$250 (Roll FX), credit 'Late Bus Home · JUNO VALE' (3 stars); no second payment; reset for skip"
