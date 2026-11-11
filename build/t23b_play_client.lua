-- Client, during play (after t23): today's 3 dailies are offered; one delivered pays once, starts a streak of 1, the pill
-- shows 1/3, and it is not offered again today.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local char = player.Character; local root = char.HumanoidRootPart; local hum = char.Humanoid; local cam = workspace.CurrentCamera
local daw = player.PlayerGui:WaitForChild("OK_DAW"):WaitForChild("DAW"); local req = daw:WaitForChild("Request")
local ui = player.PlayerGui.OK_UI
local Cfg = require(RS.OK.Modules.DAWConfig); local Check = require(RS.OK.Modules.BriefCheck); local DR = require(RS.OK.Modules.DailyRequests)
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function cmd(c) req:SetAttribute("Command", c); task.wait(0.15) end

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
if hum.Sit then hum.Sit = false; task.wait(0.4) end
local screen = workspace.OKStudio.ControlRoom.Screen_Main
local pos = Vector3.new(72.0, 3.5, -5.5)
root.CFrame = CFrame.lookAt(pos, Vector3.new(screen.Position.X, pos.Y, screen.Position.Z)); task.wait(1.0)
cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(-4, 3, 0), screen.Position); task.wait(1.5)
local prompt = screen:FindFirstChildWhichIsA("ProximityPrompt", true)
for i = 1, 4 do prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); task.wait(0.8); if daw.Visible then break end end
assert(daw.Visible, "beat maker did not open")
cmd("requests")
assert(waitFor(function() return req:GetAttribute("Overlay") == "picker" end, 3), "picker did not open")
local today = DR.Day(workspace:GetServerTimeNow())
local ids = {}
for id in string.gmatch(req:GetAttribute("Offers"), "[^,]+") do if id:sub(1, 1) == "d" then table.insert(ids, id) end end
assert(#ids == 3 and ids[1] == ("d" .. today .. "_1"), "today's 3 dailies not offered: " .. req:GetAttribute("Offers"))
assert(daw.Picker.List:FindFirstChild("Offer_" .. ids[1]), "daily not shown in the picker")
table.insert(out, "today's dailies offered: " .. table.concat(ids, ", "))
local brief = DR.Brief(ids[1])
cmd("take:" .. ids[1])
assert(waitFor(function() return req:GetAttribute("Active") == ids[1] and req:GetAttribute("Overlay") == "presets" end, 3), "taking the daily failed")
cmd("preset:KEEP")
local st = RS.OK.Remotes.Session_Get:InvokeServer()
local p, bpm = solve(brief, Cfg, Check, { st.last })
daw:SetAttribute("Pattern", p); daw:SetAttribute("BPM", bpm); daw:SetAttribute("Swing", 0)
assert(waitFor(function() return (req:GetAttribute("Stars") or 0) >= 2 end, 2), "solver beat not ready: ticks " .. tostring(req:GetAttribute("Ticks")) .. " changed " .. tostring(req:GetAttribute("Changed")))
task.wait(2.1); req:SetAttribute("LastDeliver", ""); cmd("deliver")
assert(waitFor(function() return req:GetAttribute("LastDeliver") == "ok" end, 5), "daily delivery failed: " .. tostring(req:GetAttribute("LastDeliver")) .. " " .. tostring(req:GetAttribute("Message")))
assert(waitFor(function() return ui:GetAttribute("DailyCount") == 1 and ui:GetAttribute("DailyStreak") == 1 end, 8), "daily pill not updated")
assert(waitFor(function() return ui.Daily.Text:find("1/3") and ui.Daily.Text:find("STREAK 1") end, 2), "pill text: " .. ui.Daily.Text)
table.insert(out, "daily '" .. brief.title .. "' delivered (" .. req:GetAttribute("ResultStars") .. " stars): pill '" .. ui.Daily.Text .. "'")
assert(waitFor(function() return req:GetAttribute("Overlay") == "result" end, 7), "result screen missing")
cmd("close")
local again = RS.OK.Remotes.Session_Pick:InvokeServer(ids[1])
assert(not again.ok and again.reason == "notoffered", "a finished daily was offered again today")
player:SetAttribute("_T23Stars", req:GetAttribute("ResultStars"))
local t0 = os.clock()
local forged = RS.OK.Remotes.Session_Pick:InvokeServer("d1663154086_1")
assert(not forged.ok and forged.reason == "notoffered" and os.clock() - t0 < 2, "forged daily id not refused quickly")
table.insert(out, "a forged daily id is refused at once (no generator call)")
table.insert(out, "the finished daily is not offered again today")
daw:SetAttribute("Command", "close"); task.wait(0.4); cam.CameraType = Enum.CameraType.Custom
return "T23B PLAY OK\n" .. table.concat(out, "\n")
