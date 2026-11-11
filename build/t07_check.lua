local CS = game:GetService("CollectionService")
local tagged = {}; for _, t in ipairs(CS:GetTagged("OK_Interactable")) do if t:IsDescendantOf(workspace) then table.insert(tagged, t) end end
assert(#tagged == 12, "tagged != 12 (7 + 2 laptops + gear rack + cypher board + Studio Two door): " .. #tagged)
local kinds = {}
for _, inst in ipairs(tagged) do
  assert(inst:FindFirstChildWhichIsA("ProximityPrompt", true), "no prompt on " .. inst:GetFullName())
  kinds[inst:GetAttribute("Kind")] = true
end
for _, k in ipairs({"Computer", "Console", "Mic", "LightSwitch", "Door", "CreditsWall", "TV", "Station", "GearRack", "Cypher", "StudioTwoDoor"}) do assert(kinds[k], "kind missing " .. k) end
return "T07 OK: 12 interactables with prompts (7 kinds + 2 laptops + gear rack + cypher board + Studio Two door)"
