-- Server, during play (Wave 2 Task 4; after t72b): the roster moves to fiction through _StudioLifeHook SetRoster (A8).
-- Ruling 8: THE HALL through the real Career Unlock (the hall event, reported only for that gate); cypher_win through
-- _StudioLifeHook Event, because a real win takes a whole round with the player on top (t70 pins the site's one line).
-- Staged for t72d: 100,000 Followers, so the tier bar is at the top; the daily streak at 6, last played yesterday; j1 active
-- again, for a repeat at 3 stars; career day 14, then AdvanceDay through the real Tick: day 15, a new year, LifeDayToast set.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local DR = require(RS.OK.Modules.DailyRequests)

assert(life:Invoke("SetRoster", uid, "fiction") == true, "SetRoster fiction failed")
assert(career:Invoke("Set", uid, { aura = 300, money = 5000, followers = 100000 }) == true, "Career Set failed")
local u = career:Invoke("Unlock", uid, "studio_two")
assert(u and u.ok == true, "Unlock studio_two: " .. tostring(u and u.reason))
local st = life:Invoke("State", uid)
assert(st.firsts.hall == 9, "the real Unlock did not report hall: firsts.hall " .. tostring(st.firsts.hall))
local halls = 0
for _, e in ipairs(st.story) do if e.k == "hall" then halls += 1 end end
assert(halls == 1, "want one hall line, have " .. halls)
local cw = life:Invoke("Event", uid, "cypher_win")
assert(cw and cw.story and cw.story.first == true, "the hook's cypher_win logged nothing")
assert(test:Invoke("ResetDaily", uid, 6, DR.PrevDay(DR.Day(os.time()))) == true, "ResetDaily failed")
assert(test:Invoke("SetActiveRequest", uid, "j1") == true, "SetActiveRequest failed")
task.wait(0.5) -- the ICON ribbon toast lands first, so the DAY toast t72d reads is the last one
assert(life:Invoke("SetDay", uid, 14) == true, "SetDay failed")
assert(life:Invoke("AdvanceDay", uid) == true, "AdvanceDay did not advance")
assert(p:GetAttribute("Year") == 3, "day 15 should be year 3, Year is " .. tostring(p:GetAttribute("Year")))
assert(p:GetAttribute("LifeDayToast") == 15, "LifeDayToast is " .. tostring(p:GetAttribute("LifeDayToast")))
return "T72C PLAY OK: roster fiction; 100,000 followers; THE HALL through the real Unlock; cypher_win through the hook; streak 6; j1 active; career day 15"
