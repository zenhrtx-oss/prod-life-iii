-- Client, during play (after t23e): at a studio laptop (no chair), closing the beat maker during the delivery
-- cutaway gives the camera and the window back.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local char = player.Character; local root = char.HumanoidRootPart; local hum = char.Humanoid; local cam = workspace.CurrentCamera
local daw = player.PlayerGui:WaitForChild("OK_DAW"):WaitForChild("DAW"); local req = daw:WaitForChild("Request")
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

if daw.Visible then daw:SetAttribute("Command", "close"); task.wait(0.4) end
cam.CameraType = Enum.CameraType.Custom
if hum.Sit then hum.Sit = false; task.wait(0.4) end
local laptop = workspace.OKStudio.ControlRoom.Station_Side.Screen
local pos = Vector3.new(53.0, 3.5, -6.2)
root.CFrame = CFrame.lookAt(pos, Vector3.new(laptop.Position.X, pos.Y, laptop.Position.Z)); task.wait(1.0)
local prompt = laptop:FindFirstChildWhichIsA("ProximityPrompt")
cam.CameraType = Enum.CameraType.Custom; task.wait(0.5)
for i = 1, 4 do prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); task.wait(0.8); if daw.Visible then break end end
assert(daw.Visible and not hum.Sit and cam.CameraType == Enum.CameraType.Custom, "laptop did not open the beat maker unseated with the normal camera")
local id = "d" .. DR.Day(workspace:GetServerTimeNow()) .. "_3"
cmd("take:" .. id)
assert(waitFor(function() return req:GetAttribute("Active") == id end, 3), "could not take " .. id)
cmd("preset:KEEP")
local st = RS.OK.Remotes.Session_Get:InvokeServer()
local p, bpm = solve(DR.Brief(id), Cfg, Check, { st.last })
daw:SetAttribute("Pattern", p); daw:SetAttribute("BPM", bpm); daw:SetAttribute("Swing", 0)
task.wait(2.1); req:SetAttribute("LastDeliver", ""); cmd("deliver")
assert(waitFor(function() return req:GetAttribute("Cutaway") == true end, 5), "no cutaway: " .. tostring(req:GetAttribute("LastDeliver")))
assert(cam.CameraType == Enum.CameraType.Scriptable and daw.Parent.Enabled == false, "cutaway did not take the camera")
daw:SetAttribute("Command", "close")
assert(waitFor(function() return cam.CameraType == Enum.CameraType.Custom and daw.Parent.Enabled == true and req:GetAttribute("Cutaway") == false end, 2), "camera or window stuck after closing mid-cutaway")
task.wait(5)
assert(cam.CameraType == Enum.CameraType.Custom, "the old cutaway timer took the camera back")
return "T24 PLAY OK: closing the beat maker mid-cutaway at a laptop gives back the normal camera and the window (and the timer does not undo it)"
