-- Server, during play (after t41d): the real 3-star first delivery fed the career through Contracts.Delivered:
-- +120 Followers and +10 Aura (Config.Career.DeliveryFeed[3]). Resets the career afterwards.
-- Wave 3 Task 3 (fix round 1): the real delivery reached the recent beats (Contracts.Deliver -> RecordDelivery): from
-- t41c's empty list there is exactly one entry, the passing beat (its pattern = prof.sessions.last and = t41d's beat,
-- rebuilt here the same way), bpm 140, 3 stars, no FIRE, stamped with the career day; t41d's refused 120 BPM delivery
-- (another pattern) added nothing.
local RS = game:GetService("ReplicatedStorage")
local p = game:GetService("Players"):GetPlayers()[1]; assert(p, "no player")
local SOK = game:GetService("ServerScriptService").OK
local hook, test, lifeHook = SOK._StudioCareerHook, SOK._StudioTestHook, SOK:FindFirstChild("_StudioLifeHook")
local Cfg = require(RS.OK.Modules.DAWConfig)
local f0, a0 = p:GetAttribute("_T41F"), p:GetAttribute("_T41A")
assert(type(f0) == "number" and type(a0) == "number", "t41c did not note the starting stats")
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
assert(waitFor(function() return p:GetAttribute("Followers") == f0 + 120 and p:GetAttribute("Aura") == a0 + 10 end, 3),
  string.format("delivery feed missing: followers %s (want %d), aura %s (want %d)", tostring(p:GetAttribute("Followers")), f0 + 120, tostring(p:GetAttribute("Aura")), a0 + 10))
p:SetAttribute("_T41F", nil); p:SetAttribute("_T41A", nil)
-- the recent beats: the passing delivery only
local function set(pat, track, step, ch) local i = (track - 1) * 16 + step; return pat:sub(1, i - 1) .. ch .. pat:sub(i + 1) end
local passed = Cfg.Presets[1].pattern
passed = set(passed, 2, 5, "1"); passed = set(passed, 2, 13, "1")
for _, s in ipairs({ 2, 4, 6, 8, 10, 12 }) do passed = set(passed, 3, s, "1") end
local refused = set(set(passed, 3, 14, "1"), 3, 16, "1")
local recent = test:Invoke("Recent", p.UserId)
assert(type(recent) == "table", "Recent(uid) returned " .. typeof(recent) .. " (before the Task 3 sync of OK/Main it returns nil)")
local function show(list)
  local parts = {}
  for _, e in ipairs(list) do
    table.insert(parts, string.format("{%s, bpm %s, %s*, %sf, d%s}", e.pattern == passed and "passed" or (e.pattern == refused and "REFUSED" or "other"),
      tostring(e.bpm), tostring(e.stars), tostring(e.fires), tostring(e.day)))
  end
  return table.concat(parts, " ")
end
local last = test:Invoke("GetProfile", p.UserId).sessions.last
assert(#recent == 1, "the recent beats after one refused and one passing delivery: " .. show(recent) .. ", want exactly the passing one")
local e = recent[1]
assert(e.pattern == passed and e.pattern == last, "the recent beat is not the delivered one: " .. show(recent) .. " (sessions.last matches: " .. tostring(e.pattern == last) .. ")")
assert(e.bpm == 140 and e.stars == 3 and e.fires == 0, "the recent beat is " .. show(recent) .. ", want bpm 140, 3 stars, no FIRE")
local day = lifeHook and lifeHook:Invoke("State", p.UserId)
day = type(day) == "table" and day.day or nil
assert(day == nil or e.day == day, "the recent beat's day is " .. tostring(e.day) .. ", the career day " .. tostring(day))
assert(hook:Invoke("Reset", p.UserId) == true, "career reset failed")
return "T41E PLAY OK: the real 3-star first delivery fed +120 followers and +10 aura; recent beats " .. show(recent) .. " (the refused 120 BPM one added nothing)"
