local function freshRequire(mod) -- edit-mode require caches modules across runs; load a clone so edits take effect
  local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name
  local ok, res = pcall(require, c); c:Destroy(); if not ok then error(res) end; return res
end
local L = require(game:GetService("ReplicatedStorage").OK.BuildLib)
local LO = workspace.OKStudio.Lounge
local RSx = game:GetService("ReplicatedStorage")
local roster = freshRequire(RSx.OK.Data.Artists).Artists -- the credits wall shows the house studio's artists
local RoomScope = freshRequire(RSx.OK.Modules.RoomScope)
local plaques = 0; for _, d in ipairs(LO:GetChildren()) do if d.Name:match("^Plaque_") then plaques += 1 end end
assert(plaques == #roster, "plaques " .. plaques .. " != house artists " .. #roster)
local seats = L.count(LO, "Seat"); assert(seats >= 6, "lounge seats < 6: " .. seats)
for _, n in ipairs({"TV_Screen", "CreditsWall", "Neon_Sign", "Bar_Top"}) do assert(LO:FindFirstChild(n), "missing " .. n) end
local total = L.count(workspace.OKStudio); assert(total < 5200, "too many parts: " .. total)
local lights, _, roomOver = RoomScope.Lights(workspace) -- the hub's lights; a room's bulb is held to RoomScope.MaxLightsPerRoom instead
assert(lights <= 61, "lights > 61: " .. lights) -- cap raised 36 → 61 by the user, 2026-11-05
assert(roomOver == nil, roomOver)
return string.format("T05 OK: plaques=%d seats=%d parts=%d lights=%d", plaques, seats, total, lights)
