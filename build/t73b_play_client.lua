-- Client, during play (Wave 2 Task 4; Review Focus 5; after t73a's staging, t73c puts it back): six tabs fit a phone. OK_UI
-- forced (ForceViewport, which PanelUI's panel honours) to 667x375, 771x390 and 844x390 minus this gui's insets (667x317 is
-- the first). At each, on the Career tab: the panel fits the forced box; all six tab buttons are at least 44 px tall and
-- inside the panel, side by side with no overlap; each label fits (TextFits, and its bounds inside the button). Switching to
-- Story and back leaves the Career tab's Gate_ and CareerGear_ counts as they were, and the three Bar_ rows stay. The short
-- panel: the Footer is hidden and Content grown; on Story every First_ cell's text fits and the first Story_ row's top is
-- within 260 px of the canvas top; on Credits the discography's header sits above "Your credits"; a new tab and a reopened
-- panel start at the top. The force is always taken off.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui", 10)
local ui = pg:WaitForChild("OK_UI", 10); assert(ui, "no OK_UI")
local panel = ui:WaitForChild("Panel", 5); assert(panel, "no Panel")
local tabs = panel:WaitForChild("Tabs", 5); assert(tabs, "no Tabs")
local PanelUI = require(RS.OK.Modules.PanelUI)
local LifeRules = require(RS.OK.Modules.LifeRules)
local cam = workspace.CurrentCamera
local out = {}

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function command(c, t)
	ui:SetAttribute("PanelCommand", c)
	assert(waitFor(function() return ui:GetAttribute("PanelCommand") == "" end, t or 6), "PanelCommand '" .. c .. "' was not taken (Studio seam missing?)")
end
local function count(prefix)
	local n = 0
	for _, c in ipairs(panel.Content:GetChildren()) do if c.Name:sub(1, #prefix) == prefix then n += 1 end end
	return n
end
local function cells()
	local grid = panel.Content:FindFirstChild("Firsts")
	local list = {}
	for _, c in ipairs(grid and grid:GetChildren() or {}) do if c.Name:sub(1, 6) == "First_" then table.insert(list, c) end end
	return list
end
local function label(wanted)
	for _, c in ipairs(panel.Content:GetChildren()) do if c:IsA("TextLabel") and c.Text == wanted then return c end end
	return nil
end
local function inside(g, box)
	local a, b = g.AbsolutePosition, box.AbsolutePosition
	return a.X >= b.X - 0.5 and a.Y >= b.Y - 0.5 and a.X + g.AbsoluteSize.X <= b.X + box.AbsoluteSize.X + 0.5 and a.Y + g.AbsoluteSize.Y <= b.Y + box.AbsoluteSize.Y + 0.5
end

local function run()
	ui:SetAttribute("PanelCommand", ""); ui:SetAttribute("ForceViewport", nil); panel.Visible = false
	assert(#PanelUI.Tabs == 6, "M.Tabs should hold six tabs, holds " .. #PanelUI.Tabs)
	local inset = cam.ViewportSize - ui.AbsoluteSize
	inset = Vector2.new(math.max(0, inset.X), math.max(0, inset.Y))
	for _, screen in ipairs({ Vector2.new(667, 375), Vector2.new(771, 390), Vector2.new(844, 390) }) do
		local vp = screen - inset
		local where = vp.X .. "x" .. vp.Y .. " (" .. screen.X .. "x" .. screen.Y .. " less " .. inset.X .. "x" .. inset.Y .. ")"
		ui:SetAttribute("ForceViewport", vp)
		task.wait(0.3)
		command("os")
		assert(panel.Visible, where .. ": the panel did not open")
		command("tab:Career")
		assert(waitFor(function() return panel.Content:FindFirstChild("Gate_studio_two") ~= nil end, 5), where .. ": Career did not render")
		local size = panel.AbsoluteSize
		assert(size.X <= vp.X + 0.5 and size.Y <= vp.Y + 0.5, where .. ": the panel is " .. size.X .. "x" .. size.Y)
		local narrowest, smallest, x = math.huge, math.huge, -math.huge
		for _, name in ipairs(PanelUI.Tabs) do
			local b = tabs:FindFirstChild(name)
			assert(b and b.Visible, where .. ": no tab " .. name)
			assert(b.AbsoluteSize.Y >= 44, where .. ": tab " .. name .. " is " .. b.AbsoluteSize.Y .. " px tall")
			assert(inside(b, panel), where .. ": tab " .. name .. " sticks out of the panel")
			assert(b.AbsolutePosition.X >= x, where .. ": tab " .. name .. " overlaps the one before it")
			x = b.AbsolutePosition.X + b.AbsoluteSize.X
			assert(b.TextFits, where .. ": tab " .. name .. "'s label doesn't fit (" .. b.TextBounds.X .. " in " .. b.AbsoluteSize.X .. ")")
			assert(b.TextBounds.X <= b.AbsoluteSize.X, where .. ": tab " .. name .. "'s label is wider than the button")
			narrowest, smallest = math.min(narrowest, b.AbsoluteSize.X), math.min(smallest, b.TextBounds.Y)
		end
		local gates, gear = count("Gate_"), count("CareerGear_")
		assert(gates > 0 and gear > 0, where .. ": no gates or gear rows")
		command("tab:Story")
		assert(waitFor(function() return #cells() > 0 end, 5), where .. ": Story did not render")
		assert(count("Gate_") == 0, where .. ": Story left Career rows behind")
		task.wait(0.2) -- one layout pass
		assert(panel.Footer.Visible == false, where .. ": the short panel still shows the keyboard footer")
		assert(panel.Content.AbsoluteSize.Y >= 140, where .. ": Content is " .. panel.Content.AbsoluteSize.Y .. " px tall")
		for _, c in ipairs(cells()) do assert(c.TextFits, where .. ": " .. c.Name .. "'s text doesn't fit (" .. c.TextBounds.X .. "x" .. c.TextBounds.Y .. " in " .. c.AbsoluteSize.X .. "x" .. c.AbsoluteSize.Y .. ")") end
		local story1 = panel.Content:FindFirstChild("Story_1")
		assert(story1, where .. ": no Story_1 (did t73a stage?)")
		local storyTop = story1.AbsolutePosition.Y - panel.Content.AbsolutePosition.Y + panel.Content.CanvasPosition.Y
		assert(storyTop <= 260, where .. ": the first story line is " .. storyTop .. " px down the canvas")
		-- a new tab and a reopened panel start at the top
		panel.Content.CanvasPosition = Vector2.new(0, 60)
		assert(waitFor(function() return panel.Content.CanvasPosition.Y > 0 end, 1), where .. ": Story didn't scroll")
		command("tab:Credits")
		assert(panel.Content.CanvasPosition.Y == 0, where .. ": a new tab kept the scroll at " .. panel.Content.CanvasPosition.Y)
		assert(waitFor(function() return label("Your credits") ~= nil and count("Disco_") > 0 end, 5), where .. ": Credits did not render (did t73a stage?)")
		task.wait(0.2)
		local discoHeader, creditsHeader = label(LifeRules.Copy.DiscoHeader), label("Your credits")
		assert(discoHeader and discoHeader.AbsolutePosition.Y < creditsHeader.AbsolutePosition.Y, where .. ": the discography's header should sit above Your credits")
		command("tab:Story")
		assert(waitFor(function() return #cells() > 0 end, 5), where .. ": Story did not come back")
		task.wait(0.1)
		panel.Content.CanvasPosition = Vector2.new(0, 60)
		assert(waitFor(function() return panel.Content.CanvasPosition.Y > 0 end, 1), where .. ": Story didn't scroll again")
		panel.Visible = false
		command("nolife") -- opens Story again, the same tab
		assert(panel.Content.CanvasPosition.Y == 0, where .. ": a reopened panel kept the scroll at " .. panel.Content.CanvasPosition.Y)
		panel.Visible = false
		command("os") -- nolife's payload had no real career
		command("tab:Career")
		assert(waitFor(function() return count("Gate_") > 0 end, 5), where .. ": Career did not come back")
		assert(count("Gate_") == gates and count("CareerGear_") == gear, string.format("%s: Career had %d gates and %d gear rows, has %d and %d after Story", where, gates, gear, count("Gate_"), count("CareerGear_")))
		assert(count("Bar_") == 3, where .. ": want 3 Bar_ rows, have " .. count("Bar_"))
		table.insert(out, string.format("%s: panel %dx%d, six tabs 44 px tall, narrowest %d wide, labels fit (%d px tall); Career %d gates, %d gear rows, unchanged by Story; footer hidden, Content %d tall, first story line %d px down; discography above the credits; scroll resets",
			where, size.X, size.Y, narrowest, smallest, gates, gear, panel.Content.AbsoluteSize.Y, storyTop))
		panel.Visible = false
		ui:SetAttribute("ForceViewport", nil)
		task.wait(0.2)
	end
	return "T73B PLAY OK\n" .. table.concat(out, "\n")
end

local ok, msg = pcall(run)
ui:SetAttribute("ForceViewport", nil)
panel.Visible = false
if not ok then error(msg, 0) end
return msg
