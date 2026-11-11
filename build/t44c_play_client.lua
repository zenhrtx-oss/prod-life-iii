-- Client, during play (after t44b, which leaves studio_two owned): the Studio Two door is open for this player only.
-- Locally it stops colliding, turns see-through and hides its prompt (GatesClient); walking north from the corridor
-- (6, 3, 7) to the passage (6, 3, 14) gets through within 6 s. Ends back in the lounge at (24, 3, 0).
-- t44b cleared only the sponsor and the fit; the next test that needs a clean career (t45a) calls Reset.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 and player.Character:FindFirstChild("HumanoidRootPart") then break end; task.wait(0.2) end
local char = player.Character; local root = char:WaitForChild("HumanoidRootPart", 5); local hum = char:WaitForChild("Humanoid", 5)
assert(root and hum, "no live character (t44b respawned it)")
local gates = workspace:WaitForChild("OK_Gates", 5); assert(gates, "Workspace.OK_Gates missing")
local door = gates:WaitForChild("StudioTwoDoor", 5); assert(door, "OK_Gates.StudioTwoDoor missing")
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local out = {}
local owned = player:GetAttribute("CareerGates") or ""
assert(("," .. owned .. ","):find(",studio_two,", 1, true), "studio_two is not owned (t44b should leave it): CareerGates '" .. owned .. "'")
local prompt = door:FindFirstChildWhichIsA("ProximityPrompt", true); assert(prompt, "the door has no prompt")
assert(waitFor(function() return door.CanCollide == false and prompt.Enabled == false end, 3),
  "the door did not open locally: CanCollide " .. tostring(door.CanCollide) .. ", prompt " .. tostring(prompt.Enabled))
assert(math.abs(door.Transparency - 0.85) < 0.01, "an open door should be 0.85 transparent locally, is " .. door.Transparency)
table.insert(out, "open for me: the local door doesn't collide, is 0.85 transparent, prompt hidden")
if hum.Sit then hum.Sit = false; task.wait(0.4) end
root.CFrame = CFrame.lookAt(Vector3.new(6, 3, 7), Vector3.new(6, 3, 14)); task.wait(0.8)
hum:MoveTo(Vector3.new(6, 3, 14))
local through = waitFor(function() return root.Position.Z >= 13 end, 6)
local reached = root.Position
root.CFrame = CFrame.new(24, 3, 0); task.wait(0.5)
assert(through, string.format("did not walk through the doorway within 6 s: stopped at (%.1f, %.1f, %.1f)", reached.X, reached.Y, reached.Z))
table.insert(out, string.format("walked (6, 3, 7) -> (%.1f, %.1f, %.1f) through the doorway; back at (24, 3, 0)", reached.X, reached.Y, reached.Z))
return "T44C PLAY OK\n" .. table.concat(out, "\n")
