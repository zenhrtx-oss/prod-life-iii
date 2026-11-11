local SS, RS = game:GetService("ServerStorage"), game:GetService("ReplicatedStorage")
local b = SS:FindFirstChild("OK_Backup_2026-10-22"); assert(b, "backup missing")
assert(#b:GetChildren() == 4, "backup children != 4: " .. #b:GetChildren())
for _, d in ipairs(b:GetDescendants()) do if d:IsA("BaseScript") then assert(d.Disabled, "enabled script in backup: " .. d:GetFullName()) end end
for _, d in ipairs(workspace:GetDescendants()) do assert(not d:IsA("LuaSourceContainer"), "script left in workspace: " .. d:GetFullName()) end
local L = require(RS.OK.BuildLib)
local p = L.part("t", Vector3.new(1, 1, 1), CFrame.new(0, 0, 0)); assert(p.Anchored, "part not anchored"); p:Destroy()
assert(workspace.OKStudio.Shell and RS.OK.Remotes.InteractionEvent and game.ServerScriptService.OK.Services, "scaffold incomplete")
return "T01 OK: backup=" .. #b:GetChildren() .. " workspace_children=" .. #workspace:GetChildren()
