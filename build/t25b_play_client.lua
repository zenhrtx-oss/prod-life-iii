-- Client, during play (after t25): this week's single is offered; 3 stars pays and earns a plaque, shown on your card;
-- Card_Get returns only public fields; your own "View card" prompt is hidden for you.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
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

local out = {}
local root = player.Character.HumanoidRootPart
if player.Character.Humanoid.Sit then player.Character.Humanoid.Sit = false; task.wait(0.4) end
root.CFrame = CFrame.new(72.0, 3.5, -5.5); task.wait(0.6)
local wid = "w" .. DR.Week(workspace:GetServerTimeNow())
local st = RS.OK.Remotes.Session_Get:InvokeServer()
local offered = false; for _, o in ipairs(st.offers) do if o.id == wid then offered = true end end
assert(offered, "this week's single not offered")
local pick = RS.OK.Remotes.Session_Pick:InvokeServer(wid); assert(pick.ok, "could not take the weekly: " .. tostring(pick.reason))
-- solve the asks AND the bonus for 3 stars
local brief = DR.Brief(wid)
local full = { asks = table.clone(brief.asks), bonus = brief.bonus }
table.insert(full.asks, brief.bonus)
local p, bpm = solve(full, Cfg, Check, { st.last })
assert(Check.Check(Cfg, brief, p, bpm, 0).stars == 3, "solver could not reach 3 stars on " .. wid)
task.wait(2.1)
local r = RS.OK.Remotes.Session_Deliver:InvokeServer(p, bpm, 0)
assert(r.ok and r.stars == 3 and r.plaque == true, "weekly delivery: " .. tostring(r.reason) .. " stars " .. tostring(r.stars) .. " plaque " .. tostring(r.plaque))
assert(waitFor(function() return player:GetAttribute("Plaques") == 1 end, 3), "plaque attribute not set")
table.insert(out, "Weekly Single '" .. brief.title .. "' delivered for 3 stars: +" .. r.xp .. " XP, +$" .. r.cred .. ", plaque earned")
local st2 = RS.OK.Remotes.Session_Get:InvokeServer()
for _, o in ipairs(st2.offers) do assert(o.id ~= wid, "the weekly is offered again the same week") end
local c = RS.OK.Remotes.Card_Get:InvokeServer(player.UserId)
assert(c.ok and c.card.plaqueCount == 1 and c.card.plaques[1].t == brief.title and c.card.name == player.DisplayName, "card does not show the plaque")
for _, k in ipairs({ "xp", "cred", "gear", "xpLog", "daw", "sessions", "lock", "credLog" }) do assert(c.card[k] == nil, "card leaks " .. k) end
local bad = RS.OK.Remotes.Card_Get:InvokeServer("abc"); assert(not bad.ok, "card for a bad id")
table.insert(out, "Card_Get: plaque on the card, no private fields; bad ids refused")
local pr = root:FindFirstChild("OK_CardPrompt")
assert(pr and pr.Enabled == false and pr.KeyboardKeyCode == Enum.KeyCode.G, "own card prompt missing or shown")
table.insert(out, "own 'View card' prompt exists (G) and is hidden for you")
return "T25B PLAY OK\n" .. table.concat(out, "\n")
