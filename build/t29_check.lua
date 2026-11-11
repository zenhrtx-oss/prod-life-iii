-- Edit: the drop-off funnel's steps are named and in onboarding order.
local RS = game:GetService("ReplicatedStorage")
local function freshRequire(mod) local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name; local ok, r = pcall(require, c); c:Destroy(); if not ok then error(r) end; return r end
local F = freshRequire(RS.OK.Systems.Funnel)
assert(#F.Steps == 7 and F.Steps[1] == "Joined" and F.Steps[3] == "Opened a beat maker" and F.Steps[5] == "Delivered a request", "funnel steps")
return "T29 OK: " .. #F.Steps .. " funnel steps: " .. table.concat(F.Steps, " > ")
