-- 06: runtime STRUCTURE only. Script sources now live in ../src and are written by tools/sync.py.
-- (The pre-src version of this file is kept as _legacy_06_runtime_pre_src.lua.txt for reference; do not run it.)
local RS, SSS, SG, SP = game:GetService("ReplicatedStorage"), game:GetService("ServerScriptService"), game:GetService("StarterGui"), game:GetService("StarterPlayer")
local function ensure(parent, class, name) local i = parent:FindFirstChild(name); if not i or i.ClassName ~= class then if i then i:Destroy() end; i = Instance.new(class); i.Name = name; i.Parent = parent end; return i end
local OK = ensure(RS, "Folder", "OK")
ensure(OK, "Folder", "Modules"); ensure(OK, "Folder", "Systems"); ensure(OK, "Folder", "Data")
local Remotes = ensure(OK, "Folder", "Remotes")
ensure(Remotes, "RemoteEvent", "InteractionEvent"); ensure(Remotes, "RemoteFunction", "ProfileFunction"); ensure(Remotes, "RemoteEvent", "Tour_Skip")
local SOK = ensure(SSS, "Folder", "OK"); ensure(SOK, "Folder", "Services")
ensure(SP:WaitForChild("StarterPlayerScripts"), "Folder", "OK")
local UI = ensure(SG, "ScreenGui", "OK_UI"); UI.ResetOnSpawn = false; UI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
-- small place: streaming off so every client has the whole studio (meters, speakers, signs) from the start
workspace.StreamingEnabled = false
return "06 structure ok (sources: run tools/sync.py), streaming=" .. tostring(workspace.StreamingEnabled)
