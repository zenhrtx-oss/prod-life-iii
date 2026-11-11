local function freshRequire(mod) -- edit-mode require caches modules across runs; load a clone so edits take effect
  local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name
  local ok, res = pcall(require, c); c:Destroy(); if not ok then error(res) end; return res
end
local RS = game:GetService("ReplicatedStorage")
local OK = RS.OK
for _, n in ipairs({"DAWConfig", "DAWEngine", "DAWUI"}) do local ok, err = pcall(require, OK.Modules[n]); assert(ok, n .. " failed: " .. tostring(err)) end
-- require a fresh copy: the edit-mode module cache keeps whatever version an earlier check loaded
local fresh = OK.Systems.DAW:Clone(); fresh.Parent = OK.Systems.DAW.Parent; fresh.Name = "_DAW_check"
local ok, sys = pcall(require, fresh); fresh:Destroy()
local function freshReq(mod) local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name; local o, r = pcall(require, c); c:Destroy(); if not o then error(r) end; return r end
if ok and sys._SetConfigForTest then sys._SetConfigForTest(freshReq(OK.Modules.DAWConfig)) end
assert(ok, "Systems.DAW failed: " .. tostring(sys)); assert(sys.Enabled == true and sys.Init, "DAW system not enabled")
local Cfg = freshRequire(OK.Modules.DAWConfig)
assert(#Cfg.Tracks == 5 and Cfg.Steps == 16, "grid shape")
assert(#Cfg.DefaultPattern == Cfg.Length and Cfg.Length == 128 and not Cfg.DefaultPattern:find("[^01]"), "default pattern malformed")
assert(OK.Remotes:FindFirstChild("DAW_Save") and OK.Remotes.DAW_Save:IsA("RemoteFunction"), "DAW_Save remote missing")
assert(game.StarterPlayer.StarterPlayerScripts.OK:FindFirstChild("DAWClient"), "DAWClient missing")
for _, tr in ipairs(Cfg.Tracks) do local s = OK.Samples:FindFirstChild(tr.Name); assert(s and s.SoundId == tr.SoundId, "sample missing or stale: " .. tr.Name) end
-- validation unit checks
local V = sys.Validate
assert(V(Cfg.DefaultPattern, 142), "valid pattern rejected")
assert(not V("abc", 140), "short pattern accepted"); assert(not V(string.rep("2", 64), 140), "bad chars accepted")
assert(not V(Cfg.DefaultPattern, "fast"), "string bpm accepted"); assert(not V(Cfg.DefaultPattern, 0/0), "NaN bpm accepted")
local _, b = V(Cfg.DefaultPattern, 9999); assert(b == Cfg.BPM.Max, "bpm not clamped high"); local _, b2 = V(Cfg.DefaultPattern, 1); assert(b2 == Cfg.BPM.Min, "bpm not clamped low")
-- beat format v2: per-track alphabets, unlock gates, migration
local base = string.rep("0", 64)
local withBass = base .. "m000p00000000000"
local withRoll = string.rep("0", 48) .. "3000000000000000" .. string.rep("0", 16)
assert(V(withBass, 140, 0) and V(withRoll, 140, 0) and V(Cfg.DefaultPattern, 140, 25), "v2 values rejected without a level")
assert(select(2, V(withBass, 140, 0, 1)) == "locked" and V(withBass, 140, 0, 2), "808 gate wrong")
assert(select(2, V(withRoll, 140, 0, 2)) == "locked" and V(withRoll, 140, 0, 3), "roll gate wrong")
assert(select(2, V(Cfg.DefaultPattern, 140, 25, 3)) == "locked" and V(Cfg.DefaultPattern, 140, 25, 4), "swing gate wrong")
assert(not V(base .. "z000000000000000", 140, 0) and not V(string.rep("0", 48) .. "4" .. string.rep("0", 31), 140, 0), "bad v2 alphabet accepted")
assert(not V(Cfg.DefaultPattern, 140, 99) and not V(Cfg.DefaultPattern, 140, -1), "swing out of range accepted")
local mig = sys.Migrate({ pattern = string.rep("1", 64), bpm = 150, saves = 3 })
assert(mig.v == 2 and #mig.slots.s1.pattern == Cfg.Length and mig.slots.s1.bpm == 150 and mig.saves == 3 and sys.Migrate(mig) == mig, "v1 -> v2 migration wrong")
return "T10 OK: DAW modules load, " .. #Cfg.Tracks .. " samples, validation + unlock gates + v1->v2 migration"
