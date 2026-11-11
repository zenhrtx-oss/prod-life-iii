-- Run with datamodel_type Client during a play session. Teleports the local character, fires prompts, asserts server state.
local Players = game:GetService("Players"); local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer; local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")
local studio = workspace:WaitForChild("OKStudio")
local function goto(inst, offset) root.CFrame = CFrame.new(inst.Position + (offset or Vector3.new(-4, 2, 0))); task.wait(2.0) end
local hum = char:WaitForChild("Humanoid")
local cam = workspace.CurrentCamera
local function standAt(x, y, z, target)
  if hum.Sit then hum.Sit = false; task.wait(0.4) end
  local pos = Vector3.new(x, y, z)
  if target then root.CFrame = CFrame.lookAt(pos, Vector3.new(target.Position.X, pos.Y, target.Position.Z)) else root.CFrame = CFrame.new(pos) end
  task.wait(1.0)
  if target then
    cam.CameraType = Enum.CameraType.Scriptable
    local back = (pos - target.Position); back = Vector3.new(back.X, 0, back.Z).Unit * 5
    cam.CFrame = CFrame.lookAt(pos + back + Vector3.new(0, 3, 0), target.Position)
  end
  task.wait(1.5)
end
local function trigger(inst) local p = inst:FindFirstChildWhichIsA("ProximityPrompt", true); p:InputHoldBegin(); task.wait(0.05); p:InputHoldEnd() end
local function until_(inst, check, tries) for i = 1, (tries or 4) do trigger(inst); task.wait(0.7); if check() then return i end end; return nil end
local out = {}
-- the door starts open at server start (first-look fix)
assert(studio.Shell.SlidingDoor:GetAttribute("Open") == true, "door should start open")
table.insert(out, "door starts open")
-- count XP toasts seen by this client
local toasts = {}
local tconn = RS.OK.Remotes.InteractionEvent.OnClientEvent:Connect(function(kind, payload) if kind == "Toast" then table.insert(toasts, payload.text or "") end end)
local xp0 = RS.OK.Remotes.ProfileFunction:InvokeServer().xp or 0
local console = studio.ControlRoom.Console; standAt(72.3, 3.5, 1.2, console)
local s0 = console:GetAttribute("Powered") == true
assert(until_(console, function() return (console:GetAttribute("Powered") == true) ~= s0 end), "console did not toggle")
assert(until_(console, function() return (console:GetAttribute("Powered") == true) == s0 end), "console did not toggle back")
for i = 1, 10 do trigger(console); task.wait(0.1) end
task.wait(2.5)
local profC = RS.OK.Remotes.ProfileFunction:InvokeServer()
local plus5 = 0; for _, t in ipairs(toasts) do if t:find("+5 XP", 1, true) then plus5 += 1 end end
assert((profC.xp or 0) - xp0 == 5, "console XP should rise by exactly 5 in total, rose by " .. tostring((profC.xp or 0) - xp0))
assert(plus5 == 1, "expected exactly one '+5 XP' toast, saw " .. plus5)
assert(player:GetAttribute("XP") == profC.xp and player:GetAttribute("Level") == profC.level, "Level/XP attributes do not match the profile")
table.insert(out, string.format("console: toggles, 10 fast presses, XP +5 exactly once (one toast), Level %d / XP %d attributes match", profC.level, profC.xp))
local mic = studio.VocalBooth.Mic; standAt(88.5, 3.5, -2, mic)
local rec = studio.VocalBooth.REC_Sign
assert(until_(mic, function() return rec:GetAttribute("On") == true end), "REC did not turn on"); local recAt = os.clock()
table.insert(out, "mic: REC on")
local door = studio.Shell.SlidingDoor; standAt(40.5, 3.5, 0, door)
local z0 = door.Position.Z; local open0 = door:GetAttribute("Open") == true
assert(until_(door, function() return (door:GetAttribute("Open") == true) ~= open0 end), "door prompt did not reach the server")
task.wait(1.5)
assert(math.abs(door.Position.Z - z0) > 4, string.format("door did not slide (z %.1f -> %.1f)", z0, door.Position.Z))
table.insert(out, string.format("door slid %.1f -> %.1f", z0, door.Position.Z))
local sw = studio.ControlRoom.LightSwitch
-- from the lounge side of the wall the switch must not be offered (line of sight)
local PPS = game:GetService("ProximityPromptService"); local seenThroughWall = false
local sconn = PPS.PromptShown:Connect(function(pr) if pr.Parent == sw then seenThroughWall = true end end)
standAt(41.5, 3.5, -4.1, sw); task.wait(1.0); sconn:Disconnect()
assert(not seenThroughWall, "light switch prompt showed through the wall from the lounge")
table.insert(out, "light switch not offered through the wall")
standAt(47.5, 3.5, -4.1, sw)
local preset0 = studio:GetAttribute("LightPreset")
assert(until_(sw, function() return studio:GetAttribute("LightPreset") ~= preset0 end), "light preset unchanged")
table.insert(out, "lights: " .. tostring(preset0) .. " -> " .. tostring(studio:GetAttribute("LightPreset")))
local prof = RS.OK.Remotes.ProfileFunction:InvokeServer()
assert(type(prof) == "table" and prof.level and prof.visits, "profile invalid")
table.insert(out, string.format("profile level=%d xp=%d visits=%d", prof.level, prof.xp or 0, prof.visits))
local tv = studio.Lounge.TV_Screen; standAt(30, 3.5, -6.5, tv)
local i0 = tv:GetAttribute("ScreenIndex")
assert(until_(tv, function() return tv:GetAttribute("ScreenIndex") ~= i0 end), "tv screen did not change")
table.insert(out, "tv screen " .. tostring(i0) .. " -> " .. tostring(tv:GetAttribute("ScreenIndex")))
local remaining = 9.0 - (os.clock() - recAt); if remaining > 0 then task.wait(remaining) end
assert(rec:GetAttribute("On") == false, "REC did not turn off after the timer")
table.insert(out, "mic: REC off after timer")
tconn:Disconnect()
cam.CameraType = Enum.CameraType.Custom
return "T07 PLAY OK\n" .. table.concat(out, "\n")
