local L = require(game:GetService("ReplicatedStorage").OK.BuildLib)
local CS = game:GetService("CollectionService")
local studio = workspace.OKStudio
local parts = L.count(studio); assert(parts <= 6000, "parts over budget: " .. parts)
local lights = 0; for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("Light") then lights += 1 end end
assert(lights <= 61, "lights over budget: " .. lights) -- the user raised the cap from 36 to 61 on 2026-11-05 (keep every lamp)
for _, d in ipairs(workspace:GetDescendants()) do assert(not d:IsA("LuaSourceContainer"), "script in workspace: " .. d:GetFullName()) end
local backup = game.ServerStorage:FindFirstChild("OK_Backup_2026-10-22")
if backup then for _, d in ipairs(backup:GetDescendants()) do if d:IsA("BaseScript") then assert(d.Disabled, "enabled script in backup: " .. d:GetFullName()) end end end
local seats, unanchored = 0, 0
for _, d in ipairs(studio:GetDescendants()) do
  if d:IsA("Seat") then seats += 1 end
  if d:IsA("BasePart") and not d.Anchored then unanchored += 1 end
end
assert(unanchored == 0, "unanchored parts: " .. unanchored)
local tagged = {}; for _, t in ipairs(CS:GetTagged("OK_Interactable")) do if t:IsDescendantOf(workspace) then table.insert(tagged, t) end end
assert(#tagged == 12, "interactables != 12 (7 + 2 laptops + gear rack + cypher board + Studio Two door): " .. #tagged)
for _, t in ipairs(tagged) do assert(t:FindFirstChildWhichIsA("ProximityPrompt", true), "prompt missing on " .. t.Name) end
-- every room keeps its own light sources (the 12_light_zoning experiment made rooms too dark under ShadowMap and was reverted)
local function roomOf(x) if x < 12 then return "Corridor" elseif x < 44 then return "Lounge" elseif x < 80 then return "Control" else return "Booth" end end
local perRoom = {}
for _, l in ipairs(studio:GetDescendants()) do if l:IsA("Light") and l.Enabled then local r = roomOf(l.Parent.Position.X); perRoom[r] = (perRoom[r] or 0) + 1 end end
for _, r in ipairs({"Corridor", "Lounge", "Control", "Booth"}) do assert((perRoom[r] or 0) >= 2, r .. " has fewer than 2 lights") end
return string.format("QA OK: parts=%d lights=%d seats=%d interactables=%d, every room lit", parts, lights, seats, #tagged)
