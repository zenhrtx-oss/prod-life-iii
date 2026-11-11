-- Removes the visitor-look lineup that lineup.lua built: workspace.OK_LookLineup and everything in it (lineup.lua puts
-- nothing anywhere else and changes no setting). Edit mode, through the Studio MCP execute tool. Safe to run twice.
-- Returns a one-line summary.
local FOLDER = "OK_LookLineup"
local folders, parts = 0, 0
local f = workspace:FindFirstChild(FOLDER)
while f do
	for _, d in ipairs(f:GetDescendants()) do if d:IsA("BasePart") then parts += 1 end end
	f:Destroy()
	folders += 1
	f = workspace:FindFirstChild(FOLDER)
end
if folders == 0 then return "OK_LookLineup: nothing to remove" end
return string.format("OK_LookLineup removed: %d folder(s), %d parts (incl. viewport copies); nothing else was created", folders, parts)
