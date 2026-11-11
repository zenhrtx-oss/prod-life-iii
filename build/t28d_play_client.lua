-- Client, during play (after t28c): the bar ticks the brief against the beat maker; SUBMIT sends it; with everyone in
-- the listen starts and the entries air anonymously; normal sends are refused while the cypher holds the monitors.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local bar = player.PlayerGui.OK_Cypher.Bar; local CY = RS.OK.Cypher; local NP = RS.OK.NowPlaying
local daw = player.PlayerGui.OK_DAW.DAW
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

assert(waitFor(function() return CY:GetAttribute("Phase") == "build" and bar.Visible and bar.Buttons.Submit.Visible end, 3), "SUBMIT not shown in the build (phase " .. tostring(CY:GetAttribute("Phase")) .. ")")
local t = DR.Templates[CY:GetAttribute("Template")]
local p, bpm = solve({ asks = t.asks, bonus = t.bonus }, Cfg, Check, { player:GetAttribute("_T28Cy"), player:GetAttribute("_T28Dee"), player:GetAttribute("_T28Air") })
-- phones: with the beat maker filling the screen, a 44 px SUBMIT · timer button stands in for the hidden bar
local mini = player.PlayerGui.OK_Cypher.MiniSubmit
daw.Visible = true; daw:SetAttribute("CompactForced", true); task.wait(0.6)
assert(waitFor(function() return mini.Visible and mini.Text:find("^SUBMIT") and not bar.Visible end, 2) and mini.AbsoluteSize.Y >= 44, "phone SUBMIT button missing")
daw:SetAttribute("CompactForced", nil); daw.Visible = false; task.wait(0.4)
daw:SetAttribute("Pattern", p); daw:SetAttribute("BPM", bpm); daw:SetAttribute("Swing", 0)
assert(waitFor(function() return select(2, bar.Info.Text:gsub("✓", "")) == #t.asks + 1 end, 2), "bar ticks (asks + make it yours) do not follow the beat maker: " .. bar.Info.Text)
bar:SetAttribute("LastAction", ""); bar:SetAttribute("Command", "submit")
assert(waitFor(function() return bar:GetAttribute("LastAction") == "ok" end, 3), "submit failed: " .. tostring(bar:GetAttribute("LastAction")))
assert(waitFor(function() return CY:GetAttribute("Phase") == "listen" and CY:GetAttribute("Mode") == "vote" end, 3), "listen did not start with everyone in")
assert(waitFor(function() return NP:GetAttribute("Active") and tostring(NP:GetAttribute("OwnerName")):find("^ENTRY ") end, 6), "entries are not airing anonymously")
assert(player:GetAttribute("CypherLetter") == nil and player.PlayerGui:GetAttribute("CypherLetter") ~= nil, "your letter is visible to others (on the Player)")
player.Character.HumanoidRootPart.CFrame = CFrame.new(72.0, 3.5, -5.5); task.wait(0.4)
local r = RS.OK.Remotes.DAW_Broadcast:InvokeServer(p, bpm, 0)
assert(not r.ok and r.reason == "cypher", "a normal send during the cypher should be refused as 'cypher': " .. tostring(r.reason))
local f = RS.OK.Remotes.Fire_Send:InvokeServer(NP:GetAttribute("Token")); assert(not f.ok, "FIRE on a cypher entry")
return "T28D PLAY OK: bar ticks match the beat maker; SUBMIT ok; listen started with all 3 in; '" .. NP:GetAttribute("OwnerName") .. "' on air anonymously; sends and FIRE held off"
