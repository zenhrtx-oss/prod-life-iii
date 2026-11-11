-- Edit: Wave 1b's server data (Task 3). (a) the daily Aura heal through the career reward gate, with t41's seam (a
-- fake store, a fake clock, a fake player; no Init runs): Config.Career.Sources.AuraHeal is { aura = { max = 5,
-- dailyMax = 1 } }; on day 1 at aura -3, Career.Add(p, "aura", CareerRules.HealAmount(-3, 5), "AuraHeal") pays 3 and
-- leaves aura 0 (never above); back at -3 the same Add pays 0, aura stays -3 and the gate's reason is "daily"; on day 2
-- at -12 it pays 5, leaving -7. (b) Config.SFX holds the 11 interaction sounds and exactly the 6 UI keys
-- research/wave1b_sounds_2026-10-28.md verified, each with its verified rbxassetid id and volume (literal copies of
-- the note's "Verified picks" table; never an alternate).
local RS, SSS = game:GetService("ReplicatedStorage"), game:GetService("ServerScriptService")
local function freshRequire(mod) local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name; local ok, r = pcall(require, c); c:Destroy(); if not ok then error(r) end; return r end
local Cfg = freshRequire(RS.OK.Config)
local Rules = freshRequire(RS.OK.Modules.CareerRules)
local out = {}
local function fakeStore(data)
  local s = { calls = 0 }
  function s:UpdateAsync(k, fn) s.calls += 1; local new = fn(data[k]); if new ~= nil then data[k] = new end; return new end
  return s
end
local t, day = 1000000, 20261029
local data = {}
local DS = freshRequire(SSS.OK.Services.DataService)
DS._SetConfigForTest(Cfg); DS._retryDelays = { 0, 0, 0 }; DS._lockWaits = { 0, 0, 0 }; DS._quiet = true
DS._now = function() return t end; DS._day = function() return day end
DS._SetStoreForTest(fakeStore(data))
local Career = freshRequire(RS.OK.Systems.Career)
Career._SetConfigForTest(Cfg); Career._SetCtxForTest({ Data = DS }); Career._quiet = true

-- a) the heal through the gate
local src = Cfg.Career.Sources.AuraHeal
assert(src and src.aura and src.aura.max == 5 and src.aura.dailyMax == 1, "Config.Career.Sources.AuraHeal.aura should be { max = 5, dailyMax = 1 }")
local n = 0; for _ in pairs(src) do n += 1 end; for _ in pairs(src.aura) do n += 1 end
assert(n == 3, "Config.Career.Sources.AuraHeal should register aura only, with max and dailyMax only")
local p = { UserId = 6001, Name = "T60" }
local prof = DS.Load(p)
local function heal() return Career.Add(p, "aura", Rules.HealAmount(prof.career.aura, src.aura.max), "AuraHeal") end
local function count() return (prof.career.careerLog.count or {})["AuraHeal.aura"] end
prof.career.aura = -3
local h1 = heal()
assert(h1 == 3 and prof.career.aura == 0, string.format("day 1 at aura -3: the heal should pay 3 and leave 0, paid %s, aura %s", tostring(h1), tostring(prof.career.aura)))
assert(count() == 1, "day 1: the gate should count AuraHeal.aura once, counted " .. tostring(count()))
prof.career.aura = -3
local h2 = heal()
assert(h2 == 0 and prof.career.aura == -3, string.format("day 1 again at -3: the second heal should pay 0 and leave -3, paid %s, aura %s", tostring(h2), tostring(prof.career.aura)))
local _, why = DS._gate(prof.career, "careerLog", { ["AuraHeal.aura"] = src.aura }, {}, "AuraHeal.aura", 3) -- a refusal writes nothing
assert(why == "daily" and count() == 1, "day 1 again: the gate should refuse 'daily' with the count kept at 1, got " .. tostring(why) .. ", count " .. tostring(count()))
day += 1
prof.career.aura = -12
local h3 = heal()
assert(h3 == 5 and prof.career.aura == -7, string.format("day 2 at aura -12: the heal should pay 5 and leave -7, paid %s, aura %s", tostring(h3), tostring(prof.career.aura)))
assert(count() == 1, "day 2: the new day's count should be 1, got " .. tostring(count()))
table.insert(out, "(a) AuraHeal {max 5, dailyMax 1}: day 1 -3 -> +3 (0); again at -3 -> 0, 'daily'; day 2 -12 -> +5 (-7)")

-- b) Config.SFX: the 11 interaction sounds and the sound note's 6 verified UI picks, nothing else
local INTERACTION = { "LightSwitch", "Door", "Console", "Mic", "TV", "Computer", "Station", "GearRack", "Cypher", "CreditsWall", "StudioTwoDoor" }
local UI = {
  CardOpen  = { id = "rbxassetid://9125805579", volume = 0.3 },
  Win       = { id = "rbxassetid://9126071452", volume = 0.3 },
  Loss      = { id = "rbxassetid://9120885415", volume = 0.45 },
  Money     = { id = "rbxassetid://9113848780", volume = 0.4 },
  Plant     = { id = "rbxassetid://9120131970", volume = 0.35 },
  PhoneBuzz = { id = "rbxassetid://9119715399", volume = 0.4 },
}
local known = {}
for _, k in ipairs(INTERACTION) do known[k] = true; assert(Cfg.SFX[k], "Config.SFX." .. k .. " (interaction sound) missing") end
for k, want in pairs(UI) do
  known[k] = true
  local def = Cfg.SFX[k]
  assert(def and def.id == want.id and def.volume == want.volume, string.format("Config.SFX.%s should be the note's verified pick %s at %s, got %s at %s",
    k, want.id, tostring(want.volume), tostring(def and def.id), tostring(def and def.volume)))
end
for k, def in pairs(Cfg.SFX) do
  assert(known[k], "Config.SFX." .. tostring(k) .. " is neither an interaction sound nor a verified UI key")
  assert(type(def.id) == "string" and def.id:match("^rbxassetid://%d+$"), "Config.SFX." .. k .. " id is not an rbxassetid: " .. tostring(def.id))
end
table.insert(out, "(b) Config.SFX: 11 interaction sounds + CardOpen, Win, Loss, Money, Plant, PhoneBuzz at the note's verified ids")

DS._SetStoreForTest(nil)
-- (c) walkthrough 11-05: the lamps alone left the studio black when they didn't draw; each preset keeps a base light
-- of at least 60 per channel, and LightingService applies the current preset when it starts
for _, name in ipairs({ "Warm", "Neon" }) do
	local c = Cfg.LightPresets[name].Ambient
	assert(c.R * 255 >= 60 and c.G * 255 >= 45 and c.B * 255 >= 60, name .. " preset's base light is too dark: " .. tostring(c))
end
local ls = game:GetService("ServerScriptService").OK.Services.LightingService.Source
assert(ls:find("function M.Init%(%)[^\n]*M.Apply%(M.Current%)"), "LightingService.Init does not apply the current preset")
table.insert(out, "(c) base light: Warm and Neon presets 60+ per channel; Init applies the current preset")
return "T60 OK: " .. table.concat(out, "; ")
