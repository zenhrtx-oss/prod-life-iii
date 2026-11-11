-- Client, during play: ON MONITORS. Airs at once when idle, server-timed listener on the speakers, screens, refusals,
-- one place in line per producer, airing length 12-20 s, and the monitors free again afterwards.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character; local root = char:WaitForChild("HumanoidRootPart"); local hum = char:WaitForChild("Humanoid"); local cam = workspace.CurrentCamera
local Cfg = require(RS.OK.Modules.DAWConfig); local NP = RS.OK.NowPlaying; local BroadcastFn = RS.OK.Remotes.DAW_Broadcast
local CR = workspace.OKStudio.ControlRoom; local gui = player.PlayerGui:WaitForChild("OK_DAW"); local daw = gui.DAW
local out = {}
do local d = player.PlayerGui:WaitForChild("OK_DAW"):WaitForChild("DAW"); d:SetAttribute("CompactForced", nil); d:SetAttribute("ViewportOverride", nil) end -- never inherit phone mode left on by an earlier failed test
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
-- open the beat maker at the PC
local screen = CR.Screen_Main; local prompt = screen:FindFirstChildWhichIsA("ProximityPrompt", true)
if hum.Sit then hum.Sit = false; task.wait(0.4) end
local pos = Vector3.new(72.0, 3.5, -5.5)
root.CFrame = CFrame.lookAt(pos, Vector3.new(screen.Position.X, pos.Y, screen.Position.Z)); task.wait(1.0)
cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(-4, 3, 0), screen.Position); task.wait(1.5)
for i = 1, 4 do prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); task.wait(0.8); if daw.Visible then break end end
assert(daw.Visible, "beat maker did not open")
local pat = Cfg.DefaultPattern
daw:SetAttribute("Pattern", pat); daw:SetAttribute("BPM", 150); daw:SetAttribute("Command", "play"); task.wait(0.3)
daw:SetAttribute("LastBroadcast", ""); daw:SetAttribute("Command", "monitors")
assert(waitFor(function() return (daw:GetAttribute("LastBroadcast") or "") ~= "" end, 5) and daw:GetAttribute("LastBroadcast") == "ok", "broadcast refused: " .. tostring(daw:GetAttribute("LastBroadcast")))
assert(NP:GetAttribute("Active") == true and NP:GetAttribute("OwnerId") == player.UserId and NP:GetAttribute("Beat") == pat and NP:GetAttribute("BPM") == 150, "NowPlaying attributes wrong")
assert(daw:GetAttribute("Playing") == false and player:GetAttribute("DAWPlaying") == false, "author's local preview kept playing during the broadcast")
table.insert(out, "broadcast accepted; NowPlaying set; author's local preview stopped")
-- listener: hits rise, clones play from the speakers, step follows server time
local underSpeakers, meterMax, stepErr, fromMonitors = 0, 0, 0, false
local samples, offBy2 = 0, 0 -- a single client frame stall (first sounds loading) can lag one sample; real drift lags most
local interval = 60 / 150 / 4
local t1 = os.clock()
while os.clock() - t1 < 2.5 do
  for _, sp in ipairs({CR.Speaker_L, CR.Speaker_R}) do for _, c in ipairs(sp:GetChildren()) do if c:IsA("Sound") then underSpeakers += 1 end end end
  meterMax = math.max(meterMax, CR.Console:GetAttribute("MeterLevel") or 0)
  if CR.Console:GetAttribute("BeatSource") == "monitors" then fromMonitors = true end
  local st = gui:GetAttribute("ListenerStep")
  if st then
    local k = math.floor((workspace:GetServerTimeNow() - NP:GetAttribute("StartAt")) / interval) % 16 + 1
    local d = math.abs(k - st); d = math.min(d, 16 - d); stepErr = math.max(stepErr, d)
    samples += 1; if d > 1 then offBy2 += 1 end
  end
  task.wait(0.03)
end
assert(gui:GetAttribute("ListenerPlaying") == true and (gui:GetAttribute("ListenerHits") or 0) > 0, "listener engine not playing")
assert(underSpeakers > 0, "no sample clones under Speaker_L/R")
assert(samples >= 20 and offBy2 <= math.floor(samples * 0.05) and stepErr <= 4, string.format("listener drifted from server time: %d of %d samples off by 2+, max %d", offBy2, samples, stepErr))
assert(meterMax > 0 and fromMonitors, "meters were not driven by the monitors' beat")
local side = CR.Screen_Side.Text.Label.Text; local tv = workspace.OKStudio.Lounge.TV_Screen.ScreenText.Label.Text
assert(side:find("NOW PLAYING") and tv:find("NOW PLAYING"), "screens do not show NOW PLAYING")
table.insert(out, string.format("listener: %d hits, clones on the speakers, step within %d of server time, meters peak %d, both screens NOW PLAYING", gui:GetAttribute("ListenerHits"), stepErr, meterMax))
-- refusals while busy, and bad input
local busy = BroadcastFn:InvokeServer(pat, 150); assert(busy.ok == false and busy.reason == "inline" and busy.position == 0, "second broadcast by the same producer not refused as already on air")
local airLen = NP:GetAttribute("EndsAt") - NP:GetAttribute("StartAt")
assert(airLen >= 12 - 1e-6 and airLen <= 20 + 1e-6, "airing length " .. airLen .. "s outside 12-20 s")
for _, case in ipairs({{"abc", 140}, {string.rep("2", 64), 140}, {nil, 140}, {pat, "fast"}, {{}, 140}}) do
  local r = BroadcastFn:InvokeServer(case[1], case[2]); assert(r.ok == false and r.reason == "invalid", "malformed broadcast accepted")
end
table.insert(out, string.format("airs %.1f s; a second send while on air is refused as 'inline'; 5 malformed payloads refused", airLen))
-- end of the airing: screens go back, the monitors are free again
assert(waitFor(function() return NP:GetAttribute("Active") == false end, 25), "broadcast never ended")
task.wait(0.3)
side = CR.Screen_Side.Text.Label.Text; tv = workspace.OKStudio.Lounge.TV_Screen.ScreenText.Label.Text
assert(side:find("IDLE") and not tv:find("NOW PLAYING"), "screens not restored after the broadcast")
assert(gui:GetAttribute("ListenerPlaying") == false, "listener still playing after the end")
task.wait(3.2) -- the gap between airings
local again = BroadcastFn:InvokeServer(pat, 150); assert(again.ok == true and again.position == 0, "monitors not free after the airing: " .. tostring(again.reason))
RS.OK.Remotes.DAW_Stop:FireServer()
assert(waitFor(function() return NP:GetAttribute("Active") == false end, 3), "stop did not end the airing")
local empty = BroadcastFn:InvokeServer(string.rep("0", 64), 150); assert(empty.ok == false and (empty.reason == "empty"), "empty beat accepted")
table.insert(out, "after the end: screens restored, listener stopped; the monitors take a new beat after the gap; STOP ends it; empty beat refused")
daw:SetAttribute("Command", "close"); task.wait(0.5)
assert(PPS.Enabled == true, "prompts not restored after closing")
return "T12 PLAY OK\n" .. table.concat(out, "\n")
