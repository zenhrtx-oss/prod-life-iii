-- Client, during play: every interactable carries its licensed sound, it loads, and triggering the door makes it audible.
local Players, RS, CS, CP = game:GetService("Players"), game:GetService("ReplicatedStorage"), game:GetService("CollectionService"), game:GetService("ContentProvider")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character; local root = char:WaitForChild("HumanoidRootPart"); local hum = char:WaitForChild("Humanoid"); local cam = workspace.CurrentCamera
local Config = require(RS.OK.Config)
local out, sounds = {}, {}
for _, inst in ipairs(CS:GetTagged("OK_Interactable")) do
  if inst:IsDescendantOf(workspace) then
    local s = inst:FindFirstChild("SFX"); local def = Config.SFX[inst:GetAttribute("Kind")]
    assert(s and s:IsA("Sound") and def and s.SoundId == def.id, "missing or wrong SFX on " .. inst.Name)
    table.insert(sounds, s)
  end
end
CP:PreloadAsync(sounds)
local t1 = os.clock(); while os.clock() - t1 < 6 do local all = true; for _, s in ipairs(sounds) do if not s.IsLoaded then all = false end end; if all then break end; task.wait(0.1) end
for _, s in ipairs(sounds) do assert(s.IsLoaded and s.TimeLength > 0, "SFX did not load on " .. s.Parent.Name) end
table.insert(out, #sounds .. " interaction sounds present and loaded")
-- trigger the light switch and listen to its sound on this client
local sw = workspace.OKStudio.ControlRoom.LightSwitch; local p = sw:FindFirstChildWhichIsA("ProximityPrompt", true)
if hum.Sit then hum.Sit = false; task.wait(0.4) end
local pos = Vector3.new(47.5, 3.5, -4.1)
root.CFrame = CFrame.lookAt(pos, Vector3.new(sw.Position.X, pos.Y, sw.Position.Z)); task.wait(1.0)
cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(5, 3, 0), sw.Position); task.wait(1.5)
local peak = 0
for i = 1, 4 do
  p:InputHoldBegin(); task.wait(0.05); p:InputHoldEnd()
  local t2 = os.clock(); while os.clock() - t2 < 0.8 do peak = math.max(peak, sw.SFX.PlaybackLoudness); task.wait() end
  if peak > 0 then break end
  task.wait(3.2)
end
cam.CameraType = Enum.CameraType.Custom
assert(peak > 0, "light switch sound was not audible on the client")
table.insert(out, string.format("light switch click audible on the client (peak %.0f)", peak))
return "T11 PLAY OK\n" .. table.concat(out, "\n")
