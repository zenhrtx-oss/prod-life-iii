local Lighting = game:GetService("Lighting")
local function freshRequire(mod) -- edit-mode require caches modules across runs; load a clone so edits take effect
  local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name
  local ok, res = pcall(require, c); c:Destroy(); if not ok then error(res) end; return res
end
local RoomScope = freshRequire(game:GetService("ReplicatedStorage").OK.Modules.RoomScope)
assert(Lighting.ClockTime == 0, "clocktime")
local n, _, roomOver = RoomScope.Lights(workspace) -- n = the hub's lights: a room's own bulb is held to RoomScope.MaxLightsPerRoom instead
assert(n <= 61, "too many lights: " .. n) -- cap raised 36 → 61 by the user, 2026-11-05
assert(roomOver == nil, roomOver)
assert(Lighting:FindFirstChildOfClass("BloomEffect") and Lighting:FindFirstChildOfClass("ColorCorrectionEffect"), "effects missing")
return "T03 OK: lights=" .. n
