-- Edit: MonitorService queue with a fake clock and scheduler and a temporary NowPlaying folder (no live state touched).
local RS, SSS = game:GetService("ReplicatedStorage"), game:GetService("ServerScriptService")
local function freshRequire(mod) local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name; local ok, r = pcall(require, c); c:Destroy(); if not ok then error(r) end; return r end
local Cfg = freshRequire(RS.OK.Config)
local Mon = freshRequire(SSS.OK.Services.MonitorService)
local mc = Cfg.Monitors
local out = {}
-- airing length: whole bars inside 12-20 s at every tempo
for _, bpm in ipairs({ 60, 75, 142, 150, 200 }) do
  local loops, dur = Mon.LoopsFor(bpm, 16, mc)
  assert(dur >= mc.MinSeconds - 1e-6 and dur <= mc.MaxSeconds + 1e-6 and loops == math.floor(loops), string.format("%d BPM airs %.1fs (%d bars)", bpm, dur, loops))
end
table.insert(out, "airings last 12-20 s in whole bars at 60-200 BPM")
-- fake time
local now, jobs = 0, {}
local function delay(s, fn) table.insert(jobs, { at = now + s, fn = fn }) end
local function advance(to)
  while true do
    table.sort(jobs, function(a, b) return a.at < b.at end)
    local j = jobs[1]
    if not j or j.at > to then break end
    table.remove(jobs, 1); now = j.at; j.fn()
  end
  now = to
end
local np = Instance.new("Folder"); np.Name = "_T19NowPlaying"; np.Parent = game:GetService("ServerStorage")
local changes = 0
local m = Mon.new({ np = np, mcfg = mc, now = function() return now end, delay = delay, onChange = function() changes += 1 end })
local aired, ended = {}, {}
m.Aired:Connect(function(e) table.insert(aired, e.name) end)
m.Ended:Connect(function(e, stopped) table.insert(ended, e.name .. (stopped and "!" or "")) end)
local pat = string.rep("1000", 4) .. string.rep("0", 64)
local A, Bo, C, Dd, E = { UserId = -1, DisplayName = "Ana" }, { UserId = -2, DisplayName = "Bo" }, { UserId = -3, DisplayName = "Cy" }, { UserId = -4, DisplayName = "Di" }, { UserId = -5, DisplayName = "Ed" }
local function check()
  local r1 = m:Enqueue(A, pat, 150, 0)
  assert(r1.ok and r1.position == 0 and np:GetAttribute("Active") == true and np:GetAttribute("OwnerName") == "Ana", "first beat should air at once")
  local r2 = m:Enqueue(Bo, pat, 60, 0); local r3 = m:Enqueue(C, pat, 200, 0)
  assert(r2.ok and r2.position == 1 and r3.ok and r3.position == 2 and r3.wait > r2.wait and r2.wait > 0, "queue positions/waits wrong")
  assert(np:GetAttribute("UpNext") == "Bo · Cy" and np:GetAttribute("QueueIds") == "-2,-3" and np:GetAttribute("QueueCount") == 3, "UpNext/QueueIds wrong: " .. tostring(np:GetAttribute("UpNext")))
  local dup = m:Enqueue(A, pat, 150, 0); local dup2 = m:Enqueue(Bo, pat, 150, 0)
  assert(not dup.ok and dup.reason == "inline" and dup.position == 0 and not dup2.ok and dup2.reason == "inline" and dup2.position == 1, "duplicates not refused")
  -- InLine (launch audit A12, asked by Systems/DAW before its flip check): Enqueue's own "inline" answer, nil off the line
  local inA, inC = m:InLine(-1), m:InLine(-3)
  assert(inA and inA.reason == "inline" and inA.position == 0 and inA.wait == 0 and inC and inC.position == 2 and inC.wait == r3.wait
    and m:InLine(-4) == nil, "InLine should answer Enqueue's 'inline' (Ana on air, Cy #2 with Cy's wait) and nil for a producer not in line")
  assert(m:Enqueue(Dd, pat, 150, 0).ok and not m:Enqueue(E, pat, 150, 0).ok and m:Enqueue(E, pat, 150, 0).reason == "full", "5th producer should find the line full")
  assert(m:Cancel(-4) == "removed" and np:GetAttribute("QueueIds") == "-2,-3", "cancel from the line failed")
  -- Ana's airing ends, 3 s of silence, then Bo
  local endsA = np:GetAttribute("EndsAt")
  advance(endsA + 0.2)
  task.wait() -- BindableEvent handlers are deferred
  assert(np:GetAttribute("Active") == false and ended[1] == "Ana", "Ana's airing did not end on time")
  advance(endsA + 0.2 + mc.GapSeconds - 0.5)
  assert(np:GetAttribute("Active") == false, "next beat started inside the gap")
  advance(endsA + 0.2 + mc.GapSeconds + 0.1)
  assert(np:GetAttribute("Active") == true and np:GetAttribute("OwnerName") == "Bo" and np:GetAttribute("UpNext") == "Cy", "Bo did not air after the gap")
  local loops, dur = Mon.LoopsFor(60, 16, mc)
  assert(np:GetAttribute("Loops") == loops and math.abs(np:GetAttribute("EndsAt") - np:GetAttribute("StartAt") - dur) < 1e-6, "Bo's airing length wrong")
  -- the owner stops it early: Cy follows after the gap
  assert(m:Cancel(-2) == "stopped" and np:GetAttribute("Active") == false, "stop did not end Bo's airing")
  task.wait()
  assert(ended[2] == "Bo!", "stop not reported as stopped: " .. tostring(ended[2]))
  advance(now + mc.GapSeconds + 0.1)
  assert(np:GetAttribute("OwnerName") == "Cy" and np:GetAttribute("Active") == true, "Cy did not air after Bo stopped")
  advance(np:GetAttribute("EndsAt") + mc.GapSeconds + 1)
  assert(np:GetAttribute("Active") == false and np:GetAttribute("QueueCount") == 0 and np:GetAttribute("UpNext") == "", "queue not empty at the end")
  task.wait()
  assert(table.concat(aired, ",") == "Ana,Bo,Cy", "airing order wrong: " .. table.concat(aired, ","))
  -- an empty queue after the gap airs a new beat at once; tokens always move on
  local tok = np:GetAttribute("Token")
  assert(m:Enqueue(Dd, pat, 150, 0).position == 0 and np:GetAttribute("Token") > tok, "idle monitors did not air at once")
  m:Cancel(-4)
  -- switched off
  mc.Enabled = false
  local off = m:Enqueue(E, pat, 150, 0); mc.Enabled = true
  assert(not off.ok and off.reason == "off", "disabled monitors accepted a beat")
  assert(changes > 0, "screens never told")
end
local ok, err = pcall(check)
np:Destroy()
if not ok then error(err) end
table.insert(out, "queue: airs at once when idle; positions and waits; one place each (InLine gives the same answer); full at 4; cancel; order Ana, Bo, Cy with 3 s gaps; stop early; off switch")
return "T19 OK: " .. table.concat(out, "; ")
