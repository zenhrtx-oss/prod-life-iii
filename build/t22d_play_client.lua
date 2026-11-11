-- Client, during play (after t22c): no FIRE button and no FIRE on your own beat; your nameplate shows the FIRE count.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local NP = RS.OK.NowPlaying
local btn = player.PlayerGui.OK_Fire.FireButton
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
task.wait(2.2)
assert(not btn.Visible, "FIRE button shown on your own beat")
local r = RS.OK.Remotes.Fire_Send:InvokeServer(NP:GetAttribute("Token")); assert(not r.ok and r.reason == "self", "FIRE on your own beat: " .. tostring(r.reason))
local plate = player.Character.Head.OK_Nameplate
assert(waitFor(function() return plate.StatsText.Text:find("🔥 " .. player:GetAttribute("FireTotal")) end, 2), "nameplate FIRE count: " .. plate.StatsText.Text)
RS.OK.Remotes.DAW_Stop:FireServer()
assert(waitFor(function() return NP:GetAttribute("Active") == false end, 3), "could not stop the airing")
return "T22D PLAY OK: own beat has no FIRE button and refuses FIRE; nameplate reads " .. plate.StatsText.Text
