local function freshRequire(mod) -- edit-mode require caches modules across runs; load a clone so edits take effect
  local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name
  local ok, res = pcall(require, c); c:Destroy(); if not ok then error(res) end; return res
end
local RoomScope = freshRequire(game:GetService("ReplicatedStorage").OK.Modules.RoomScope)
local CS = game:GetService("CollectionService")
local inWorkspace = {}; for _, t in ipairs(CS:GetTagged("OK_Interactable")) do if t:IsDescendantOf(workspace) then table.insert(inWorkspace, t) end end
local tagged = RoomScope.Split(inWorkspace) -- the hub's own interactables: a room's laptop is not counted
assert(#tagged == 12, "tagged != 12 (7 + 2 laptops + gear rack + cypher board + Studio Two door): " .. #tagged)
local kinds = {}
for _, inst in ipairs(tagged) do
  assert(inst:FindFirstChildWhichIsA("ProximityPrompt", true), "no prompt on " .. inst:GetFullName())
  kinds[inst:GetAttribute("Kind")] = true
end
for _, k in ipairs({"Computer", "Console", "Mic", "LightSwitch", "Door", "CreditsWall", "TV", "Station", "GearRack", "Cypher", "StudioTwoDoor"}) do assert(kinds[k], "kind missing " .. k) end
return "T07 OK: 12 interactables with prompts (7 kinds + 2 laptops + gear rack + cypher board + Studio Two door)"
