-- Client, during play (first of the t44 group; studio_two not owned yet): the Studio Two door is locked for this player.
-- It collides and offers its prompt locally, and pressing it from the corridor toasts the needs line ("NEEDS ...").
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character; local root = char:WaitForChild("HumanoidRootPart", 5); local hum = char:WaitForChild("Humanoid", 5); local cam = workspace.CurrentCamera
assert(root and hum, "no live character")
local gates = workspace:WaitForChild("OK_Gates", 5); assert(gates, "Workspace.OK_Gates missing: run build/18_gates.lua in Edit before Play")
local door = gates:WaitForChild("StudioTwoDoor", 5); assert(door, "OK_Gates.StudioTwoDoor missing")
local out = {}
local owned = player:GetAttribute("CareerGates") or ""
assert(not ("," .. owned .. ","):find(",studio_two,", 1, true), "studio_two is already owned (CareerGates '" .. owned .. "'): an earlier test left the gate unlocked")
local prompt = door:FindFirstChildWhichIsA("ProximityPrompt", true); assert(prompt, "the door has no prompt")
assert(door.CanCollide == true and prompt.Enabled == true, "a locked door should collide and offer its prompt (CanCollide " .. tostring(door.CanCollide) .. ", prompt " .. tostring(prompt.Enabled) .. ")")
table.insert(out, "locked: the door collides and offers '" .. prompt.ActionText .. "' (CareerGates '" .. owned .. "')")
local toasts = {}
local conn = RS.OK.Remotes.InteractionEvent.OnClientEvent:Connect(function(kind, payload)
  if kind == "Toast" and type(payload) == "table" then table.insert(toasts, tostring(payload.text)) end
end)
if hum.Sit then hum.Sit = false; task.wait(0.4) end
local pos = Vector3.new(6, 3.5, 6.5)
root.CFrame = CFrame.lookAt(pos, Vector3.new(door.Position.X, pos.Y, door.Position.Z)); task.wait(1.0)
cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(0, 3, -5), door.Position); task.wait(1.0)
local needs
for _ = 1, 4 do -- presses 1.3 s apart: the door's per-player cooldown is 1 s
  prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd()
  local t1 = os.clock()
  while not needs and os.clock() - t1 < 1.3 do
    for _, t in ipairs(toasts) do if t:find("NEEDS", 1, true) then needs = t end end
    task.wait(0.05)
  end
  if needs then break end
end
conn:Disconnect(); cam.CameraType = Enum.CameraType.Custom
assert(needs, "no NEEDS toast from the locked door; toasts seen: " .. table.concat(toasts, " | "))
assert(door.CanCollide == true, "pressing the locked door opened it")
table.insert(out, "pressing it toasts '" .. needs .. "' and the door stays shut")
return "T44 PLAY OK\n" .. table.concat(out, "\n")
