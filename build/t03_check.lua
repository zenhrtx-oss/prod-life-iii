local Lighting = game:GetService("Lighting")
assert(Lighting.ClockTime == 0, "clocktime")
local n = 0; for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("Light") then n += 1 end end
assert(n <= 61, "too many lights: " .. n) -- cap raised 36 → 61 by the user, 2026-11-05
assert(Lighting:FindFirstChildOfClass("BloomEffect") and Lighting:FindFirstChildOfClass("ColorCorrectionEffect"), "effects missing")
return "T03 OK: lights=" .. n
