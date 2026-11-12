-- 20: Day One's remotes (the Day One plan, Task 2: Systems/DayOne). STRUCTURE only, idempotent (OK_Build = "20_day_one"
-- on each): run in Edit after 17_career_remotes and before syncing Systems/DayOne (its Init indexes these remotes).
-- RemoteEvent DayOne (server -> client: "arrive" with a card payload, "leave" with { token }); RemoteFunctions
-- DayOne_Choose(token, index) and DayOne_Get().
local RS = game:GetService("ReplicatedStorage")
local Remotes = RS.OK.Remotes
local B = "20_day_one"
local function ensure(parent, class, name)
	local i = parent:FindFirstChild(name)
	if not i or i.ClassName ~= class then
		if i then i:Destroy() end
		i = Instance.new(class); i.Name = name; i.Parent = parent
	end
	i:SetAttribute("OK_Build", B)
	return i
end
ensure(Remotes, "RemoteEvent", "DayOne")
ensure(Remotes, "RemoteFunction", "DayOne_Choose")
ensure(Remotes, "RemoteFunction", "DayOne_Get")
return "20 day one remotes ok"
