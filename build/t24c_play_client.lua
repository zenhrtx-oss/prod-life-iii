-- Client, during play (after t24b): yesterday's daily cannot be delivered; it is cleared and today's offers stay.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local root = player.Character.HumanoidRootPart
root.CFrame = CFrame.new(72.0, 3.5, -5.5); task.wait(0.6)
task.wait(2.1)
local r = RS.OK.Remotes.Session_Deliver:InvokeServer(require(RS.OK.Modules.DAWConfig).DefaultPattern, 140, 0)
assert(not r.ok and r.reason == "expired", "yesterday's daily: " .. tostring(r.reason))
local st = RS.OK.Remotes.Session_Get:InvokeServer()
assert(st.active == nil, "stale daily still active")
return "T24C PLAY OK: yesterday's daily refused as expired and cleared"
