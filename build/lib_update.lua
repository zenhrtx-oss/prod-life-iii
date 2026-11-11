--@@BUILDLIB@@
local lib = game:GetService("ReplicatedStorage").OK.BuildLib
lib.Source = BUILDLIB_SRC
-- strip build tags from room containers and make sure every container exists
local studio = workspace.OKStudio
for _, n in ipairs({"Shell", "Corridor", "Lounge", "ControlRoom", "VocalBooth", "Lighting", "Props", "Interactables"}) do
  local m = studio:FindFirstChild(n)
  if not m then m = Instance.new("Model"); m.Name = n; m.Parent = studio end
  m:SetAttribute("OK_Build", nil)
end
return "lib updated; containers=" .. #studio:GetChildren()
