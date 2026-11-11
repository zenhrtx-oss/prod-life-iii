-- Clone Workspace.OKStudio into ServerStorage.OK_Versions as a named snapshot (geometry + prompts, no runtime scripts live there anyway).
local name = "SNAPSHOT_NAME"
local SS = game:GetService("ServerStorage")
local folder = SS:FindFirstChild("OK_Versions") or Instance.new("Folder"); folder.Name = "OK_Versions"; folder.Parent = SS
local old = folder:FindFirstChild(name); if old then old:Destroy() end
local clone = workspace.OKStudio:Clone(); clone.Name = name; clone.Parent = folder
local CS = game:GetService("CollectionService"); for _, d in ipairs(clone:GetDescendants()) do if CS:HasTag(d, "OK_Interactable") then CS:RemoveTag(d, "OK_Interactable") end; local p = d:FindFirstChildOfClass("ProximityPrompt"); if p then p:Destroy() end end
local rt = Instance.new("Folder"); rt.Name = "_runtime_copy"; rt.Parent = clone
for _, src in ipairs({game.ReplicatedStorage.OK, game.ServerScriptService.OK, game.StarterPlayer.StarterPlayerScripts.OK}) do local c = src:Clone(); c.Name = src:GetFullName():gsub("%.", "_"); for _, d in ipairs(c:GetDescendants()) do if d:IsA("BaseScript") then d.Disabled = true end end; c.Parent = rt end
return "snapshot " .. name .. " parts=" .. #clone:GetDescendants()
