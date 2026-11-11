-- Edit: FIRE rules (pure Judge) and nameplate text.
local RS = game:GetService("ReplicatedStorage")
local function freshRequire(mod) local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name; local ok, r = pcall(require, c); c:Destroy(); if not ok then error(r) end; return r end
local R = freshRequire(RS.OK.Systems.Reactions)
local NPm = freshRequire(RS.OK.Modules.Nameplate)
local Cfg = freshRequire(RS.OK.Config)
local base = { active = true, token = 7, ownerId = 100, startAt = 0, barLen = 2, now = 5, fired = {}, pairCount = 0 }
local function judge(over, a)
  local s = table.clone(base); for k, v in pairs(over or {}) do s[k] = v end
  local args = { listenerId = 200, token = 7, dist = 10 }; for k, v in pairs(a or {}) do args[k] = v end
  return R.Judge(s, args)
end
local cases = {
  { {}, {}, true },
  { { active = false }, {}, "noair" }, { {}, { token = 6 }, "stale" }, { {}, { listenerId = 100 }, "self" },
  { { now = 1.5 }, {}, "early" }, { { fired = { [200] = true } }, {}, "again" }, { {}, { dist = Cfg.Fire.Range + 1 }, "far" },
  { { pairCount = Cfg.Fire.PairDaily }, {}, "pair" }, { { pairCount = Cfg.Fire.PairDaily - 1 }, {}, true },
}
for i, c in ipairs(cases) do
  local ok, why = judge(c[1], c[2])
  if c[3] == true then assert(ok, "case " .. i .. " should pass, got " .. tostring(why))
  else assert(not ok and why == c[3], string.format("case %d: expected %s, got %s", i, c[3], tostring(why))) end
end
assert(NPm.Text(4, "ENGINEER", nil, 2) == "YEAR 2 · LV 4 · ENGINEER" and NPm.Text(4, "ENGINEER", 0, 2) == "YEAR 2 · LV 4 · ENGINEER", "nameplate text with a year: " .. NPm.Text(4, "ENGINEER", nil, 2))
assert(NPm.Text(4, "ENGINEER", 37, 2) == "YEAR 2 · LV 4 · ENGINEER · 🔥 37", "nameplate text with a year and FIRE: " .. NPm.Text(4, "ENGINEER", 37, 2))
assert(NPm.Text(4, "ENGINEER", 37) == "LV 4 · ENGINEER · 🔥 37", "nameplate text before the year is known: " .. NPm.Text(4, "ENGINEER", 37))
assert(Cfg.XP.Sources.FireTap and Cfg.Cred.Sources.Fire and Cfg.Cred.Sources.Fire.dailyMax, "FIRE rewards not configured with caps")
return "T22 OK: FIRE refused when nothing airs, stale, own beat, first bar, again, too far, pair cap; passes otherwise; nameplate 'YEAR 2 · LV 4 · ENGINEER · 🔥 37'"
