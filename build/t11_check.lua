-- Edit: first-look fixes and sounds (the 11 interaction sounds, and Wave 1b's 6 UI sounds from research/wave1b_sounds_2026-10-28.md).
local RS = game:GetService("ReplicatedStorage")
local function freshRequire(mod) local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name; local ok, r = pcall(require, c); c:Destroy(); if not ok then error(r) end; return r end
local Config = freshRequire(RS.OK.Config)
local S = workspace.OKStudio
local function box(p) local h = p.Size / 2; return p.Position - h, p.Position + h end
local function overlap(a, b) local a0, a1 = box(a); local b0, b1 = box(b); return a0.X < b1.X and a1.X > b0.X and a0.Y < b1.Y and a1.Y > b0.Y and a0.Z < b1.Z and a1.Z > b0.Z end
local LO = S.Lounge
local others = {LO.TV_Bezel, S.Shell.Wall_Mid_1, S.Lighting.Strip_Lounge_S}
for _, d in ipairs(LO:GetChildren()) do if d.Name == "Plant_B_Leaf" then table.insert(others, d) end end
for _, n in ipairs({"Poster_A", "Poster_B"}) do
  for _, o in ipairs(others) do assert(not overlap(LO[n], o), n .. " overlaps " .. o.Name) end
end
assert(not overlap(LO.Poster_A, LO.Poster_B), "posters overlap each other")
local plaque = S.ControlRoom.Plaque_B.Text.Label.Text; assert(plaque == "PROD LIFE III\nHOUSE STUDIO", "Plaque_B text: " .. plaque)
local main = S.ControlRoom.Screen_Main.Text.Label.Text; assert(not main:find("wegonebeok_001") and main:find("MAKE A BEAT") and not main:find("%[ F %]"), "Screen_Main copy wrong")
for kind, def in pairs(Config.SFX) do assert(type(def.id) == "string" and def.id:match("^rbxassetid://%d+$"), "bad SFX id for " .. kind) end
local n = 0; for _ in pairs(Config.SFX) do n += 1 end
assert(n == 17, "expected 17 sounds: 11 interaction sounds (7 + laptops + gear rack + cypher board + Studio Two door) and 6 UI sounds (CardOpen, Win, Loss, Money, Plant, PhoneBuzz), got " .. n)
return "T11 OK: posters clear of TV, wall, strip, plant and each other; plaque and PC screen copy fixed; 17 sounds configured (11 interaction, 6 UI)"
