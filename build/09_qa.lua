local function freshRequire(mod) -- edit-mode require caches modules across runs; load a clone so edits take effect
  local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name
  local ok, res = pcall(require, c); c:Destroy(); if not ok then error(res) end; return res
end
local L = require(game:GetService("ReplicatedStorage").OK.BuildLib)
local RoomScope = freshRequire(game:GetService("ReplicatedStorage").OK.Modules.RoomScope)
local CS = game:GetService("CollectionService")
local studio = workspace.OKStudio
local parts = L.count(studio); assert(parts <= 6000, "parts over budget: " .. parts)
local lights, _, roomOver = RoomScope.Lights(workspace) -- the hub's lights; a room's bulb is held to RoomScope.MaxLightsPerRoom instead
assert(lights <= 61, "lights over budget: " .. lights) -- the user raised the cap from 36 to 61 on 2026-11-05 (keep every lamp)
assert(roomOver == nil, roomOver)
for _, d in ipairs(workspace:GetDescendants()) do assert(not d:IsA("LuaSourceContainer"), "script in workspace: " .. d:GetFullName()) end
-- the throwaway 12-plot phone test (build/room_test.lua) is not left in the place (R-T16 fix, I2): while Workspace.RoomTest
-- stands, Systems/Rooms gives nobody a plot, so a place saved with it fails here, before any public publish. (The private
-- phone-tour publish is the one deliberate exception, and its checklist removes the test first: build/room_test_remove.lua)
local SP = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
for _, at in ipairs({ { workspace, "Workspace" }, { game:GetService("ReplicatedStorage"), "ReplicatedStorage" },
  { game:GetService("ServerScriptService"), "ServerScriptService" }, { SP, "StarterPlayerScripts" } }) do
  assert(not (at[1] and at[1]:FindFirstChild("RoomTest")), at[2] .. ".RoomTest is in the place: the throwaway room test is still in (run build/room_test_remove.lua)")
end
local backup = game.ServerStorage:FindFirstChild("OK_Backup_2026-10-22")
if backup then for _, d in ipairs(backup:GetDescendants()) do if d:IsA("BaseScript") then assert(d.Disabled, "enabled script in backup: " .. d:GetFullName()) end end end
local seats, unanchored = 0, 0
for _, d in ipairs(studio:GetDescendants()) do
  if d:IsA("Seat") then seats += 1 end
  if d:IsA("BasePart") and not d.Anchored then unanchored += 1 end
end
assert(unanchored == 0, "unanchored parts: " .. unanchored)
local inWorkspace = {}; for _, t in ipairs(CS:GetTagged("OK_Interactable")) do if t:IsDescendantOf(workspace) then table.insert(inWorkspace, t) end end
local tagged = RoomScope.Split(inWorkspace) -- the hub's own interactables: a room's laptop is not counted
assert(#tagged == 12, "interactables != 12 (7 + 2 laptops + gear rack + cypher board + Studio Two door): " .. #tagged)
for _, t in ipairs(tagged) do assert(t:FindFirstChildWhichIsA("ProximityPrompt", true), "prompt missing on " .. t.Name) end
-- every room keeps its own light sources (the 12_light_zoning experiment made rooms too dark under ShadowMap and was reverted)
local function roomOf(x) if x < 12 then return "Corridor" elseif x < 44 then return "Lounge" elseif x < 80 then return "Control" else return "Booth" end end
local perRoom = {}
for _, l in ipairs(studio:GetDescendants()) do if l:IsA("Light") and l.Enabled then local r = roomOf(l.Parent.Position.X); perRoom[r] = (perRoom[r] or 0) + 1 end end
for _, r in ipairs({"Corridor", "Lounge", "Control", "Booth"}) do assert((perRoom[r] or 0) >= 2, r .. " has fewer than 2 lights") end
return string.format("QA OK: parts=%d lights=%d seats=%d interactables=%d, every room lit", parts, lights, seats, #tagged)
