-- Server, during play (after t28b): the lobby closes into the build; an off-brief entry and a copied entry are refused;
-- both pretend producers submit valid beats.
local SSS, RS = game:GetService("ServerScriptService"), game:GetService("ReplicatedStorage")
local cy = SSS.OK._StudioCypherHook; local CY = RS.OK.Cypher
local Cfg = require(RS.OK.Modules.DAWConfig); local Check = require(RS.OK.Modules.BriefCheck); local DR = require(RS.OK.Modules.DailyRequests)
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
-- builds a beat that meets every required ask of a (gear-free) request and is "yours" (8+ pads changed)
local function solve(brief, Cfg, Check, extraRefs)
  local p = string.rep("0", #Cfg.Tracks * Cfg.Steps)
  local idx = {}; for i, tr in ipairs(Cfg.Tracks) do idx[tr.Name] = i end
  local function get(track, step) local i = (idx[track] - 1) * 16 + step; return p:sub(i, i) end
  local function set(track, step, ch) local i = (idx[track] - 1) * 16 + step; p = p:sub(1, i - 1) .. ch .. p:sub(i + 1) end
  local function count(track) local n = 0; for s = 1, 16 do if get(track, s) ~= "0" then n += 1 end end; return n end
  local bpm, cap = 120, {}
  for _, a in ipairs(brief.asks) do if a.k == "max" then cap[a.track] = a.n end end
  for _, a in ipairs(brief.asks) do
    if a.k == "bpm" then bpm = math.ceil(a.min / 5) * 5
    elseif a.k == "on" then for _, s in ipairs(a.steps) do set(a.track, s, "1") end
    elseif a.k == "backbeat" then set("Snare", 5, "1"); set("Snare", 13, "1") end
  end
  for _, a in ipairs(brief.asks) do
    if a.k == "min" then for s = 1, 16 do if count(a.track) >= a.n then break end; if get(a.track, s) == "0" then set(a.track, s, "1") end end end
  end
  -- keys asks (piano roll): pad to the v3 length and place notes, so melody / melnotes / chord asks pass on the days
  -- a daily or weekly template asks for them (DAWConfig.Notes reads keys notes only from a full-length beat)
  local keys = false
  for _, a in ipairs(brief.asks) do if a.k == "melody" or a.k == "melnotes" or a.k == "chord" then keys = true end end
  if keys then
    p = p .. string.rep("0", Cfg.Length - #p)
    for i, semi in ipairs({ 0, 3, 5, 7, 10, 12 }) do p = Cfg.PlaceNote(p, 1 + (i - 1) * 2, semi, 1) or p end
    p = Cfg.PlaceNote(p, 1, 7, 1) or p -- a second note on step 1 makes a chord
  end
  local refs = Check.References(Cfg, extraRefs)
  -- top up until the beat is 8+ pads from every reference, never breaking a "max" ask
  for _, filler in ipairs({ "Hat", "Clap", "Snare", "Kick" }) do
    for s = 1, 16 do
      if Check.Changed(p, refs) >= Check.MinChanged then break end
      if get(filler, s) == "0" and (cap[filler] == nil or count(filler) < cap[filler]) then
        local before = Check.Changed(p, refs)
        set(filler, s, "1")
        if Check.Changed(p, refs) <= before or not Check.Check(Cfg, brief, p, bpm, 0).passed then set(filler, s, "0") end
      end
    end
  end
  return p, bpm
end

cy:Invoke("Skip")
assert(waitFor(function() return CY:GetAttribute("Phase") == "build" end, 3), "lobby did not move to build")
local t = DR.Templates[CY:GetAttribute("Template")]
local brief = { asks = t.asks, bonus = t.bonus }
-- someone else's airing can't be entered: a pretend producer airs a beat that fits the brief, Cy tries to enter it
local mon = SSS.OK._StudioMonitorHook
local aired, abpm = solve({ asks = t.asks, bonus = t.bonus }, Cfg, Check, {})
assert(mon:Invoke("Enqueue", -2899, "Air Test", aired, abpm).ok, "test airing failed")
local stolen = cy:Invoke("Submit", -2801, aired, abpm)
assert(not stolen.ok and stolen.reason == "copy", "an aired beat was accepted as a cypher entry: " .. tostring(stolen.reason))
mon:Invoke("Cancel", -2899)
local off = cy:Invoke("Submit", -2801, string.rep("0", 64) .. "m000000000000000", 120)
assert(not off.ok and (off.reason == "missing" or off.reason == "copy"), "off-brief entry accepted: " .. tostring(off.reason))
local p1, b1 = solve(brief, Cfg, Check, { aired })
local r1 = cy:Invoke("Submit", -2801, p1, b1); assert(r1.ok, "Cy's valid entry refused: " .. tostring(r1.reason))
local dup = cy:Invoke("Submit", -2802, p1, b1); assert(not dup.ok and dup.reason == "copy", "a copy of Cy's entry was accepted: " .. tostring(dup.reason))
-- Dee: the same asks, then the bonus too, and different filler
local full = { asks = table.clone(t.asks), bonus = t.bonus }; table.insert(full.asks, t.bonus)
local p2, b2 = solve(full, Cfg, Check, { p1, aired })
local r2 = cy:Invoke("Submit", -2802, p2, b2); assert(r2.ok, "Dee's valid entry refused: " .. tostring(r2.reason))
assert(CY:GetAttribute("Submitted") == 2 and CY:GetAttribute("Phase") == "build", "submission count")
local p = game:GetService("Players"):GetPlayers()[1]
p:SetAttribute("_T28Cy", p1); p:SetAttribute("_T28Dee", p2); p:SetAttribute("_T28Air", aired)
return "T28C OK: build open; off-brief and copied entries refused; Cy (" .. r1.stars .. " stars) and Dee (" .. r2.stars .. " stars) submitted"
