local L = require(game:GetService("ReplicatedStorage").OK.BuildLib)
local CR, VB = workspace.OKStudio.ControlRoom, workspace.OKStudio.VocalBooth
for _, n in ipairs({"Screen_Main", "Speaker_L", "Speaker_R", "Chair_Seat", "LightSwitch", "OK_Sign", "Console"}) do assert(CR:FindFirstChild(n), "missing " .. n) end
for _, n in ipairs({"Mic", "REC_Sign", "BoothLamp"}) do assert(VB:FindFirstChild(n), "missing " .. n) end
local meters = 0; for _, d in ipairs(CR:GetChildren()) do if d.Name:match("^Meter_") then meters += 1 end end
assert(meters == 48, "meters != 48: " .. meters)
local seats = L.count(CR, "Seat"); assert(seats >= 4, "seats < 4: " .. seats)
local total = L.count(workspace.OKStudio); assert(total < 3500, "too many parts: " .. total)
local lights = 0; for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("Light") then lights += 1 end end
assert(lights <= 61, "lights > 61: " .. lights) -- cap raised 36 → 61 by the user, 2026-11-05
return string.format("T04 OK: parts=%d seats=%d meters=%d lights=%d", total, seats, meters, lights)
