-- OK Studio SystemLoader: starts every enabled system module in a folder (Systems.*: Enabled = true, Init(ctx)).
-- A system that fails to load or start is reported as "[OK][ERR]" (tools/test.py fails on it), marked on the
-- folder's SystemsFailed attribute, and never silently skipped. Started systems get InitOK = true.
local M = {}

function M.Run(folder, ctx, opts)
	opts = opts or {}
	local started, failed = {}, {}
	local function report(msg) if not opts.quiet then warn("[OK][ERR] " .. msg) end end
	for _, m in ipairs(folder:GetChildren()) do
		if m:IsA("ModuleScript") and m.Name ~= "README" then
			m:SetAttribute("InitOK", nil)
			local ok, sys = pcall(require, m)
			if not ok then
				table.insert(failed, m.Name); report("system " .. m.Name .. " failed to load: " .. tostring(sys))
			elseif type(sys) == "table" and sys.Enabled and type(sys.Init) == "function" then
				local ok2, err = pcall(sys.Init, ctx)
				if ok2 then
					m:SetAttribute("InitOK", true); table.insert(started, m.Name)
				else
					table.insert(failed, m.Name); report("system " .. m.Name .. " failed to start: " .. tostring(err))
				end
			end
		end
	end
	table.sort(started); table.sort(failed)
	folder:SetAttribute("SystemsStarted", table.concat(started, ","))
	folder:SetAttribute("SystemsFailed", table.concat(failed, ","))
	return started, failed
end

return M
