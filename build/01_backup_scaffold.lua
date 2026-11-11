--@@BUILDLIB@@
local RS, SSS, SG, SP, SS = game:GetService("ReplicatedStorage"), game:GetService("ServerScriptService"), game:GetService("StarterGui"), game:GetService("StarterPlayer"), game:GetService("ServerStorage")
local out = {}
-- 1) backup originals
local keep = {Baseplate = true, SpawnLocation = true, Terrain = true, Camera = true, OKStudio = true}
local backup = SS:FindFirstChild("OK_Backup_2026-10-22")
if not backup then backup = Instance.new("Folder"); backup.Name = "OK_Backup_2026-10-22"; backup.Parent = SS end
local moved, disabled = 0, 0
for _, c in ipairs(workspace:GetChildren()) do
  if not keep[c.Name] then
    for _, d in ipairs(c:GetDescendants()) do if d:IsA("BaseScript") then d.Disabled = true; disabled += 1 end end
    c:SetAttribute("OK_BackupOriginal", true); c.Parent = backup; moved += 1
  end
end
table.insert(out, string.format("backup: moved=%d scripts_disabled=%d children=%d", moved, disabled, #backup:GetChildren()))
-- 2) scaffold
local function folder(parent, name) local f = parent:FindFirstChild(name); if not f then f = Instance.new("Folder"); f.Name = name; f.Parent = parent end; return f end
local function model(parent, name) local m = parent:FindFirstChild(name); if not m then m = Instance.new("Model"); m.Name = name; m.Parent = parent end; return m end
local studio = model(workspace, "OKStudio")
for _, n in ipairs({"Shell", "Corridor", "Lounge", "ControlRoom", "VocalBooth", "Lighting", "Props", "Interactables"}) do model(studio, n) end
local ok = folder(RS, "OK"); folder(ok, "Data"); folder(ok, "Modules"); folder(ok, "Systems")
local remotes = folder(ok, "Remotes")
if not remotes:FindFirstChild("InteractionEvent") then local e = Instance.new("RemoteEvent"); e.Name = "InteractionEvent"; e.Parent = remotes end
if not remotes:FindFirstChild("ProfileFunction") then local f = Instance.new("RemoteFunction"); f.Name = "ProfileFunction"; f.Parent = remotes end
local sok = folder(SSS, "OK"); folder(sok, "Services")
folder(SP:WaitForChild("StarterPlayerScripts"), "OK")
if not SG:FindFirstChild("OK_UI") then local g = Instance.new("ScreenGui"); g.Name = "OK_UI"; g.Enabled = true; g.ResetOnSpawn = false; g.Parent = SG end
folder(SS, "OK_Versions"); folder(SS, "OK_Reference")
-- 3) BuildLib module
local lib = ok:FindFirstChild("BuildLib")
if not lib then lib = Instance.new("ModuleScript"); lib.Name = "BuildLib"; lib.Parent = ok end
local okSrc, err = pcall(function() lib.Source = BUILDLIB_SRC end)
table.insert(out, "buildlib_source_write=" .. tostring(okSrc) .. (okSrc and "" or (" " .. tostring(err))))
return table.concat(out, "\n")
