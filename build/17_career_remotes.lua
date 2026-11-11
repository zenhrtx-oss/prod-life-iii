-- 17: the career, walk-in and phone remotes (Systems/Career, Systems/WalkIns, Systems/Phone). STRUCTURE only,
-- idempotent: run in Edit after 10_daw and before syncing those systems (their Init indexes these remotes).
-- RemoteFunctions Career_Get, Career_Unlock, WalkIn_Choose, Phone_Choose; RemoteEvents WalkIn, WalkIn_Deferred, Phone,
-- Phone_Open.
local RS = game:GetService("ReplicatedStorage")
local Remotes = RS.OK.Remotes
local function ensure(parent, class, name) local i = parent:FindFirstChild(name); if not i or i.ClassName ~= class then if i then i:Destroy() end; i = Instance.new(class); i.Name = name; i.Parent = parent end; return i end
for _, n in ipairs({ "Career_Get", "Career_Unlock", "WalkIn_Choose", "Phone_Choose" }) do ensure(Remotes, "RemoteFunction", n) end
for _, n in ipairs({ "WalkIn", "WalkIn_Deferred", "Phone", "Phone_Open" }) do ensure(Remotes, "RemoteEvent", n) end
return "17 remotes ok"
