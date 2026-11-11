local L = require(game:GetService("ReplicatedStorage").OK.BuildLib)
local S = workspace.OKStudio.Shell
for _, n in ipairs({"Floor_Corridor", "Floor_Lounge", "Floor_Control", "Floor_Booth"}) do
  local f = S:FindFirstChild(n); assert(f, n .. " missing"); assert(math.abs(f.Position.Y + f.Size.Y / 2) < 0.01, n .. " top not at y=0")
end
assert(math.abs(S.BoothGlass.Transparency - 0.35) < 0.001, "glass transparency")
local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances = {S.SlidingDoor, workspace.SpawnLocation}
local function clear(name, from, dir)
  local h = workspace:Raycast(from, dir, params)
  assert(not h, name .. " blocked by " .. (h and h.Instance.Name or "?"))
end
clear("corridor->lounge", Vector3.new(6, 3, 5), Vector3.new(10, 0, 0))
clear("lounge->control", Vector3.new(40, 3, 0), Vector3.new(8, 0, 0))
clear("control->booth", Vector3.new(76, 3, 6), Vector3.new(8, 0, 0))
local hit = workspace:Raycast(Vector3.new(77.5, 5, -2), Vector3.new(6, 0, 0), params)
assert(hit and hit.Instance.Name == "BoothGlass", "window ray should hit glass, got " .. (hit and hit.Instance.Name or "nothing"))
assert(not workspace:FindFirstChild("Baseplate"), "baseplate still present")
local n = L.count(S); assert(n < 400, "too many shell parts: " .. n)
return "T02 OK: shell parts=" .. n
