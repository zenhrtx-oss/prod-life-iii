-- Server, during play (after t17d): a skipped tour is done, marked skipped, and paid nothing; later steps pay nothing.
local p = game:GetService("Players"):GetPlayers()[1]; assert(p, "no player")
local hook = game:GetService("ServerScriptService").OK._StudioTestHook
local Tour = require(game:GetService("ReplicatedStorage").OK.Systems.Tour)
local prof = hook:Invoke("GetProfile", p.UserId)
assert(prof.tour.done == true and prof.tour.skipped == true, "skip not recorded")
assert(prof.xp == p:GetAttribute("_T17XP"), "skip paid XP")
assert(hook:Invoke("TourAdvance", p.UserId, "open") == false, "a skipped tour still advanced")
return "T17E OK: skipped tour recorded, no XP, no further steps"
