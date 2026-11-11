-- Edit: Studio Sessions data and grader. Artist/brief data is consistent, the starter works at level 1, presets are
-- legal at level 1, 20 fixture beats grade as expected, and an untouched preset is never "yours".
local RS = game:GetService("ReplicatedStorage")
local function freshRequire(mod) local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name; local ok, r = pcall(require, c); c:Destroy(); if not ok then error(r) end; return r end
local Cfg = freshRequire(RS.OK.Modules.DAWConfig)
local A = freshRequire(RS.OK.Data.Artists)
local Check = freshRequire(RS.OK.Modules.BriefCheck)
local DAW = freshRequire(RS.OK.Systems.DAW); DAW._SetConfigForTest(Cfg)
local out = {}
-- data integrity
local ids, starters, L1 = {}, 0, 0
local KINDS = { bpm = true, on = true, backbeat = true, min = true, max = true, notes = true, rolls = true, swing = true, melody = true, melnotes = true, chord = true }
for _, a in ipairs(A.Artists) do assert(a.quotes[2] and a.quotes[3] and a.name == a.name:upper() and a.level >= 1, "artist data: " .. a.id) end
for _, b in ipairs(A.Briefs) do
  assert(not ids[b.id], "duplicate brief id " .. b.id); ids[b.id] = true
  local a = A.ArtistById[b.artist]; assert(a, "unknown artist on " .. b.id)
  assert(#b.asks >= 2 and #b.asks <= 3 and b.reward.xp > 0 and b.reward.cred > 0, "brief shape: " .. b.id)
  for _, ask in ipairs(b.asks) do assert(KINDS[ask.k] and Check.Text(ask) ~= "?", "ask kind on " .. b.id) end
  if b.bonus then assert(KINDS[b.bonus.k], "bonus kind on " .. b.id) end
  if b.starter then starters += 1; assert(next(Check.Requires(b)) == nil and a.level == 1, "starter needs an unlock") end
  if a.level == 1 and next(Check.Requires(b)) == nil then L1 += 1 end
end
assert(#A.Briefs >= 21 and #A.Artists == 6 and starters == 1 and L1 >= 5, string.format("catalog: %d briefs, %d starters, %d at level 1", #A.Briefs, starters, L1))
table.insert(out, string.format("%d artists, %d requests, 1 starter, %d doable at level 1", #A.Artists, #A.Briefs, L1))
-- presets: legal at level 1, distinct, never the default beat
for _, p in ipairs(Cfg.Presets) do
  local ok, why = DAW.Validate(p.pattern, p.bpm, 0, 1)
  assert(ok, "preset " .. p.name .. " not legal at level 1: " .. tostring(why))
  assert(Check.Changed(p.pattern, Check.References(Cfg)) == 0, "preset not in the reference list")
  assert(Check.Changed(p.pattern, { Cfg.DefaultPattern }) >= Check.MinChanged, "preset too close to the default beat")
end
table.insert(out, #Cfg.Presets .. " presets legal at level 1; an untouched preset counts 0 pads changed")
-- fixture beats: build from rows
local function beat(k, s, c, h, b) return (k or string.rep("0", 16)) .. (s or string.rep("0", 16)) .. (c or string.rep("0", 16)) .. (h or string.rep("0", 16)) .. (b or string.rep("0", 16)) end
local Z = string.rep("0", 16)
local K1, BB, H8, H16 = "1000000000000000", "0000100000001000", "1010101010101010", "1111111111111111"
local function stars(id, p, bpm, sw) return Check.Check(Cfg, A.BriefById[id], p, bpm, sw or 0).stars end
local cases = {
  { "j1", beat(K1, BB, Z, H8), 140, 0, 3 },            -- every ask + 8 hats
  { "j1", beat(K1, BB, Z, "1000100010001000"), 140, 0, 2 }, -- asks met, 4 hats: no bonus
  { "j1", beat(K1, BB, Z, H8), 170, 0, 0 },            -- BPM out of range
  { "j1", beat(Z, BB, Z, H8), 140, 0, 0 },             -- no kick on the 1
  { "j1", beat(K1, Z, BB, H8), 140, 0, 3 },            -- clap can carry the backbeat
  { "j1", beat(K1, "0000100000000000", Z, H8), 140, 0, 0 }, -- only beat 2
  { "j2", beat(K1, Z, "0000100000001000", "0010001000100010"), 160, 0, 2 },  -- asks met, no keys: the bonus (4+ notes) is missed
  { "j2", (function() local p = Cfg.Upgrade(beat(K1, Z, "0000100000001000", "0010001000100010")); for i, s in ipairs({ 1, 5, 9, 13 }) do p = Cfg.PlaceNote(p, s, ({ 0, 3, 7, 3 })[i], 1) end; return p end)(), 160, 0, 3 }, -- 4 notes on the keys: bonus
  { "j2", beat(Z, Z, "0000100000001000", "0010001000100010"), 160, 0, 2 },
  { "j2", beat(K1, Z, "0000100000000000", "0010001000100010"), 160, 0, 0 }, -- one clap
  { "t1", beat("1000000000100000", "0000000010000000", Z, H8), 145, 0, 3 },
  { "t1", beat("1000100010100000", "0000000010000000", Z, H8), 145, 0, 0 }, -- 4 kicks
  { "t2", beat(Z, Z, Z, "1111111111110000"), 140, 0, 2 },
  { "t2", beat(K1, Z, "0000100000000000", H16), 140, 0, 0 },  -- a clap
  { "j4", beat(K1, Z, Z, Z, "m000m000p000m000"), 150, 0, 2 },
  { "j4", beat(K1, Z, Z, Z, "m000r000p000m000"), 150, 0, 3 },  -- 3 different notes
  { "j4", beat(K1, Z, Z, Z, "m000m000m000"  .. "0000"), 150, 0, 0 }, -- 3 notes only
  { "j5", beat(Z, BB, Z, "2030100010001000"), 150, 0, 2 },
  { "t4", beat("1000000000000000", Z, Z, "3030200000000000", "m000p000r0000000"), 150, 0, 3 },
  { "r3", beat(Z, BB, Z, Z), 80, 25, 2 },
  { "r3", beat(Z, BB, Z, Z), 80, 0, 0 },               -- no swing
}
for i, c in ipairs(cases) do
  local got = stars(c[1], c[2], c[3], c[4])
  assert(got == c[5], string.format("fixture %d (%s): expected %d stars, got %d", i, c[1], c[5], got))
end
table.insert(out, #cases .. " fixture beats grade as expected (2 stars asks, 3 with the bonus, 0 on any missing ask)")
-- needs
assert(Check.Requires(A.BriefById.j4).Bass and Check.Requires(A.BriefById.j5).Rolls and Check.Requires(A.BriefById.r3).Swing and next(Check.Requires(A.BriefById.j1)) == nil, "Requires wrong")
-- "make it yours"
local bounce = Cfg.Presets[2].pattern
local refs = Check.References(Cfg)
local tweak = bounce:sub(1, 48) .. "1111111111111111" .. bounce:sub(65)
local _, zeros = bounce:sub(49, 64):gsub("0", "")
assert(Check.Changed(tweak, refs) == zeros and zeros > 0 and Check.Changed(beat(K1, BB, Z, H16), refs) >= 1, "Changed miscounts")
table.insert(out, "Requires and Changed correct")
return "T20 OK: " .. table.concat(out, "; ")
