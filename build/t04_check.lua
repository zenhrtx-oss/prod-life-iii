local function freshRequire(mod) -- edit-mode require caches modules across runs; load a clone so edits take effect
  local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name
  local ok, res = pcall(require, c); c:Destroy(); if not ok then error(res) end; return res
end
local L = require(game:GetService("ReplicatedStorage").OK.BuildLib)
local RoomScope = freshRequire(game:GetService("ReplicatedStorage").OK.Modules.RoomScope)
local CR, VB = workspace.OKStudio.ControlRoom, workspace.OKStudio.VocalBooth
for _, n in ipairs({"Screen_Main", "Speaker_L", "Speaker_R", "Chair_Seat", "LightSwitch", "OK_Sign", "Console"}) do assert(CR:FindFirstChild(n), "missing " .. n) end
for _, n in ipairs({"Mic", "REC_Sign", "BoothLamp"}) do assert(VB:FindFirstChild(n), "missing " .. n) end
local meters = 0; for _, d in ipairs(CR:GetChildren()) do if d.Name:match("^Meter_") then meters += 1 end end
assert(meters == 48, "meters != 48: " .. meters)
local seats = L.count(CR, "Seat"); assert(seats >= 4, "seats < 4: " .. seats)
local total = L.count(workspace.OKStudio); assert(total < 3500, "too many parts: " .. total)
local lights, _, roomOver = RoomScope.Lights(workspace) -- the hub's lights; a room's bulb is held to RoomScope.MaxLightsPerRoom instead
assert(lights <= 61, "lights > 61: " .. lights) -- cap raised 36 → 61 by the user, 2026-11-05
assert(roomOver == nil, roomOver)
return string.format("T04 OK: parts=%d seats=%d meters=%d lights=%d", total, seats, meters, lights)
