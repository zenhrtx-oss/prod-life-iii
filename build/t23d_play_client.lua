-- Client, during play (after t23c): another daily today makes the streak 3 and pays the streak bonus.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local daw = player.PlayerGui:WaitForChild("OK_DAW"):WaitForChild("DAW")
local ui = player.PlayerGui.OK_UI
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

local char = player.Character; local root = char.HumanoidRootPart
if char.Humanoid.Sit then char.Humanoid.Sit = false; task.wait(0.4) end
root.CFrame = CFrame.new(72.0, 3.5, -5.5); task.wait(0.8)
local today = DR.Day(workspace:GetServerTimeNow())
local id = "d" .. today .. "_2"
local pick = RS.OK.Remotes.Session_Pick:InvokeServer(id)
assert(pick.ok, "could not take the second daily: " .. tostring(pick.reason))
local st = RS.OK.Remotes.Session_Get:InvokeServer()
local p, bpm = solve(DR.Brief(id), Cfg, Check, { st.last })
task.wait(2.1)
local toasts = {}
local tconn = RS.OK.Remotes.InteractionEvent.OnClientEvent:Connect(function(k, pl) if k == "Toast" then table.insert(toasts, pl.text or "") end end)
local r = RS.OK.Remotes.Session_Deliver:InvokeServer(p, bpm, 0)
assert(r.ok, "second daily failed: " .. tostring(r.reason) .. " " .. table.concat(r.missing or {}, ","))
assert(waitFor(function() return ui:GetAttribute("DailyStreak") == 3 and ui:GetAttribute("DailyCount") == 1 end, 3), "streak not 3")
assert(waitFor(function() for _, t in ipairs(toasts) do if t:find("3%-day streak") then return true end end; return false end, 3), "no streak bonus toast")
tconn:Disconnect()
player:SetAttribute("_T23Stars2", r.stars)
return "T23D PLAY OK: second daily on a 2-day streak makes it 3; bonus toast shown; pill '" .. ui.Daily.Text .. "'"
