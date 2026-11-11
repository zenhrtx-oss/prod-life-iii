-- Client, during play (after t21c): buying a look auto-equips it (NeonColor), the rack LEDs light, equip toggles it,
-- and a beat on the monitors carries the owner's neon colour.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local studio = workspace.OKStudio
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local out = {}
local lit0 = studio:GetAttribute("RackLit") or 0
local cred0 = player:GetAttribute("Cred") or 0
local r = RS.OK.Remotes.Gear_Buy:InvokeServer("neon_ice")
assert(r.ok, "buying the Ice neon failed: " .. tostring(r.reason))
assert(waitFor(function() return typeof(player:GetAttribute("NeonColor")) == "Color3" and (studio:GetAttribute("RackLit") or 0) == lit0 + 1 end, 3), "neon not equipped or rack LED not lit")
assert(waitFor(function() return player:GetAttribute("Cred") == cred0 - 900 end, 2), "money not spent: " .. tostring(player:GetAttribute("Cred")))
table.insert(out, "Ice neon bought for $900: auto-equipped, one more rack LED lit")
local e = RS.OK.Remotes.Gear_Equip:InvokeServer("neon_ice")
assert(e.ok and waitFor(function() return player:GetAttribute("NeonColor") == nil end, 2), "unequip failed")
local e2 = RS.OK.Remotes.Gear_Equip:InvokeServer("neon_ice")
assert(e2.ok and waitFor(function() return player:GetAttribute("NeonColor") ~= nil end, 2), "re-equip failed")
local bad = RS.OK.Remotes.Gear_Equip:InvokeServer("plate_gold"); assert(not bad.ok, "equipped gear not owned")
table.insert(out, "equip toggles the look; unowned looks refused")
-- the owner's neon rides along with their beat on the monitors
local char = player.Character; local root = char.HumanoidRootPart
if char.Humanoid.Sit then char.Humanoid.Sit = false; task.wait(0.4) end
root.CFrame = CFrame.new(72.0, 3.5, -5.5); task.wait(0.8)
local NP = RS.OK.NowPlaying
local t0 = os.clock(); while NP:GetAttribute("Active") and os.clock() - t0 < 25 do task.wait(0.2) end
task.wait(3.2)
local b = RS.OK.Remotes.DAW_Broadcast:InvokeServer(require(RS.OK.Modules.DAWConfig).DefaultPattern, 140, 0)
assert(b.ok, "broadcast failed: " .. tostring(b.reason))
assert(waitFor(function() return NP:GetAttribute("Active") and NP:GetAttribute("NeonColor") == player:GetAttribute("NeonColor") end, 3), "on-air neon colour not set")
RS.OK.Remotes.DAW_Stop:FireServer()
table.insert(out, "a beat on the monitors carries its owner's neon colour")
return "T21D PLAY OK\n" .. table.concat(out, "\n")
