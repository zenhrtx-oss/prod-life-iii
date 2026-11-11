-- Which credits and texts can be shown, per Config.Content.ShowExplicitTitles (the user's decision; default true).
local RS = game:GetService("ReplicatedStorage")
local M = {}
function M.ShowExplicit(config)
	config = config or require(RS.OK.Config)
	return not (config.Content and config.Content.ShowExplicitTitles == false)
end
function M.Credits(credits, config)
	if M.ShowExplicit(config) then return credits end
	local out = {}
	for _, c in ipairs(credits) do if not c.explicit then table.insert(out, c) end end
	return out
end
return M
