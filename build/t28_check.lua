-- Edit: cypher rules: head-to-head by stars (equal = draw), votes decide 3+ (ties: stars, then the earlier submit),
-- briefs need no gear, FIRE is refused on cypher entries.
local RS = game:GetService("ReplicatedStorage")
local function freshRequire(mod) local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name; local ok, r = pcall(require, c); c:Destroy(); if not ok then error(r) end; return r end
local BB = freshRequire(RS.OK.Systems.BeatBattles)
local Check = freshRequire(RS.OK.Modules.BriefCheck)
local R = freshRequire(RS.OK.Systems.Reactions)
local A = { name = "A", stars = 3, votes = 0, at = 1 }; local Bq = { name = "B", stars = 2, votes = 0, at = 2 }
assert(BB.Decide({ A, Bq }, "h2h") == A, "h2h: more stars should win")
assert(BB.Decide({ { name = "A", stars = 2, votes = 0, at = 1 }, { name = "B", stars = 2, votes = 0, at = 2 } }, "h2h") == nil, "h2h: equal stars should draw")
local x, y, z = { name = "X", stars = 2, votes = 1, at = 1 }, { name = "Y", stars = 3, votes = 2, at = 2 }, { name = "Z", stars = 3, votes = 2, at = 3 }
assert(BB.Decide({ x, y, z }, "vote") == y, "vote: most votes, then stars, then earlier submit")
local p, q = { name = "P", stars = 2, votes = 2, at = 1 }, { name = "Q", stars = 3, votes = 2, at = 2 }
assert(BB.Decide({ p, q }, "vote") == q, "vote tie should go to stars")
for r = 1, 12 do assert(next(Check.Requires(BB.BriefFor(r))) == nil, "a cypher brief needs gear") end
local ok, why = R.Judge({ active = true, cypher = true, token = 1, ownerId = -1, startAt = 0, barLen = 1, now = 9, fired = {}, pairCount = 0 }, { listenerId = 5, token = 1, dist = 1 })
assert(not ok and why == "cypher", "FIRE allowed on a cypher entry")
return "T28 OK: head-to-head by stars (equal = draw); votes decide 3+ (ties: stars, then earlier); briefs need no gear; no FIRE on cypher entries"
