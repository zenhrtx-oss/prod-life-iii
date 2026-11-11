-- Edit: flip rules (pure Judge): sampled flips need 8+ changed pads, can't flip your own beat or a beat that has left
-- the history, and an unsampled near-copy of someone's distinctive airing is refused (the default beat is not).
local RS = game:GetService("ReplicatedStorage")
local function freshRequire(mod) local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name; local ok, r = pcall(require, c); c:Destroy(); if not ok then error(r) end; return r end
local F = freshRequire(RS.OK.Systems.Flips)
local Cfg = freshRequire(RS.OK.Modules.DAWConfig)
F._SetConfigForTest(Cfg, freshRequire(RS.OK.Modules.BriefCheck))
local maya = "1001001001001000" .. "0000100100001000" .. "0010000000100000" .. "1111000011110000" .. string.rep("0", 16)
local function change(p, n) local s = p; for i = 1, n do local ch = s:sub(64 + i, 64 + i) == "0" and "m" or "0"; s = s:sub(1, 64 + i - 1) .. ch .. s:sub(64 + i + 1) end; return s end
local hist = { { token = 5, uid = 100, name = "Maya", pattern = maya }, { token = 6, uid = 300, name = "Def", pattern = Cfg.DefaultPattern } }
local a, why = F.Judge(hist, 200, change(maya, 3), 5); assert(a == nil and why == "flipcopy", "small flip allowed: " .. tostring(why))
local b = F.Judge(hist, 200, change(maya, 8), 5); assert(b and b.name == "Maya", "8-pad flip refused")
local c, w3 = F.Judge(hist, 100, change(maya, 8), 5); assert(c == nil and w3 == "own", "flipping your own beat allowed")
local d, w4 = F.Judge(hist, 200, change(maya, 8), 99); assert(d == nil and w4 == "gone", "unknown token allowed")
local e, w5 = F.Judge(hist, 200, change(maya, 2), nil); assert(e == nil and w5 == "copy", "unsampled copy allowed: " .. tostring(w5))
local f, w6 = F.Judge(hist, 200, Cfg.DefaultPattern, nil); assert(f == nil and w6 == nil, "the default beat counted as a copy")
local g, w7 = F.Judge(hist, 100, maya, nil); assert(g == nil and w7 == nil, "re-airing your own beat refused")
-- a forged token for beat X cannot launder a copy of producer Y's beat
local other = "0000100010001000" .. "1000100010001000" .. "0101000001010000" .. "0011001100110011" .. string.rep("0", 16)
local hist2 = { { token = 5, uid = 100, name = "Maya", pattern = maya }, { token = 7, uid = 400, name = "Ola", pattern = other } }
local h, w8 = F.Judge(hist2, 200, other, 5); assert(h == nil and w8 == "copy", "forged token laundered a copy: " .. tostring(w8))
-- without Roll FX, a sample loses its rolls: those lost rolls don't count as your 8 changes
local rolls = string.rep("0", 48) .. "2323232300000000" .. string.rep("0", 16)
local hist3 = { { token = 9, uid = 100, name = "Maya", pattern = rolls } }
local noRolls = function(f) return f ~= "Rolls" end
local i2, w9 = F.Judge(hist3, 200, F.Sampled(rolls, noRolls), 9, noRolls); assert(i2 == nil and w9 == "flipcopy", "a roll-stripped sample passed as a flip: " .. tostring(w9))
return "T26 OK: forged flip tokens can't launder copies; roll-stripped samples aren't changes; flips need 8+ changes and a live sample; own beat and unknown samples refused; unsampled copies of a distinctive airing refused; the default beat and your own beat are free"
