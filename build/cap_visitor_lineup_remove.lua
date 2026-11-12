-- Capture cleanup (Edit mode; Wave 3 Task 5d): removes workspace.OK_LookLineup, everything build/cap_visitor_lineup.lua
-- builds. Run it before any build, test or snapshot script.
local n = 0
local f = workspace:FindFirstChild("OK_LookLineup")
while f do f:Destroy(); n += 1; f = workspace:FindFirstChild("OK_LookLineup") end
return "OK_LookLineup removed: " .. n
