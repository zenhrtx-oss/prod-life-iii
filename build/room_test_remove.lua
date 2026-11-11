-- Removes the THROWAWAY room test (build/room_test.lua): everything tagged OK_Build = "room_test", then puts streaming
-- and every top-level Model's ModelStreamingMode back from ServerStorage.RoomTest_Orig, and deletes that record.
local RS, SS = game:GetService("ReplicatedStorage"), game:GetService("ServerStorage")
local Http = game:GetService("HttpService")
local L = require(RS.OK.BuildLib)
local n = L.clear("room_test")
local orig = SS:FindFirstChild("RoomTest_Orig")
if not orig then
	workspace.StreamingEnabled = false -- build/06_runtime.lua's setting
	return ("ROOM TEST REMOVED: %d instances; no RoomTest_Orig, so streaming set off (06's setting); model modes untouched"):format(n)
end
local o = Http:JSONDecode(orig.Value)
workspace.StreamingEnabled = o.enabled
workspace.StreamingTargetRadius = o.target
workspace.StreamingMinRadius = o.min
workspace.StreamOutBehavior = Enum.StreamOutBehavior[o.out]
local restored, missing = 0, {}
for _, c in ipairs(workspace:GetChildren()) do
	if c:IsA("Model") then
		local mode = o.modes[c:GetFullName()]
		if mode then c.ModelStreamingMode = Enum.ModelStreamingMode[mode]; restored += 1 end
	end
end
for name in pairs(o.modes) do if not workspace:FindFirstChild((name:gsub("^Workspace%.", ""))) then table.insert(missing, name) end end
orig:Destroy()
return ("ROOM TEST REMOVED: %d instances; streaming=%s target=%d min=%d out=%s; %d model modes restored%s")
	:format(n, tostring(workspace.StreamingEnabled), workspace.StreamingTargetRadius, workspace.StreamingMinRadius,
		workspace.StreamOutBehavior.Name, restored, #missing > 0 and ("; missing: " .. table.concat(missing, ", ")) or "")
