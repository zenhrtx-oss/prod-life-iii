-- Client, during play (Wave 2 Task 4; A2, A14; after t71a, whose banners may still be coming): the banner queue on
-- OK_LevelUp.LevelUp, driven through the Studio seams PanelCommand "banner:<text>" (C.Banner) and "level:<n>" (C.LevelUp).
-- First it waits for t71a's banners and cards to finish. (1) Queue order: a banner and a LEVEL UP sent in a row: the
-- banner shows at once and is still up 2.5 s later, with LastLevelUp not yet moved; then the LEVEL UP shows and sets
-- LastLevelUp; BannerLog ends banner, LEVEL. (2) The longest tier banner's two lines fit the 420x64 box. (3) A14: with
-- OK_WalkIn's Card forced visible here, a banner is held: not shown and not logged; a LEVEL UP keeps its timing and passes
-- it; the banner shows only when the card closes. (4) The same hold for OK_WalkIn's Result and OK_Phone's Card.
-- t71c and t71d then run the order through the real path. A forced card is always put back.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui", 10)
local ui = pg:WaitForChild("OK_UI", 10); assert(ui, "no OK_UI")
local lv = pg:WaitForChild("OK_LevelUp", 10); assert(lv, "no OK_LevelUp")
local banner = lv:WaitForChild("LevelUp", 5); assert(banner, "no OK_LevelUp.LevelUp")
local wg, phone = pg:WaitForChild("OK_WalkIn", 10), pg:WaitForChild("OK_Phone", 10)
assert(wg and phone, "no OK_WalkIn or OK_Phone gui")
local wCard, wResult, pCard = wg.Root:WaitForChild("Card", 5), wg.Root:WaitForChild("Result", 5), phone.Root:WaitForChild("Card", 5)
assert(wCard and wResult and pCard, "a card frame is missing")
local LifeRules = require(RS.OK.Modules.LifeRules)
local out = {}
local T0 = os.clock()

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function command(c, t)
	ui:SetAttribute("PanelCommand", c)
	assert(waitFor(function() return ui:GetAttribute("PanelCommand") == "" end, t or 6), "PanelCommand '" .. c .. "' was not taken (Studio seam missing?)")
end
local function log() return string.split(ui:GetAttribute("BannerLog") or "", "|") end
local function last(n) local e = log(); return e[#e - (n or 0)] end
local function shows(text) return banner.Visible and banner.Text == text end
-- nothing showing, nothing held: no banner and no card for a full second (a held banner looks every 0.2 s)
local function drained(t)
	local since = nil
	local function idle()
		if banner.Visible or wCard.Visible or wResult.Visible or pCard.Visible then since = nil; return false end
		since = since or os.clock()
		return os.clock() - since >= 1
	end
	assert(waitFor(idle, t or 8), "the queue did not drain: showing '" .. banner.Text .. "', log " .. tostring(ui:GetAttribute("BannerLog")))
end

local function run()
	ui:SetAttribute("PanelCommand", "")
	drained(40)
	table.insert(out, string.format("t71a's banners done after %.1f s", os.clock() - T0))

	-- 1: the queue's order: the second waits, the first is not replaced
	local level = (tonumber(ui:GetAttribute("LastLevelUp")) or 0) + 70
	command("banner:T71B FIRST")
	command("level:" .. level)
	assert(shows("T71B FIRST"), "the first banner did not show at once: showing '" .. banner.Text .. "', visible " .. tostring(banner.Visible))
	task.wait(2.5)
	assert(shows("T71B FIRST"), "the first banner was replaced within 2.5 s by '" .. banner.Text .. "'")
	assert(ui:GetAttribute("LastLevelUp") ~= level, "LastLevelUp moved before the LEVEL banner showed")
	assert(waitFor(function() return shows("LEVEL " .. level) end, 2), "the LEVEL UP did not follow: showing '" .. banner.Text .. "'")
	assert(ui:GetAttribute("LastLevelUp") == level, "LastLevelUp should be " .. level .. " when the LEVEL banner shows, is " .. tostring(ui:GetAttribute("LastLevelUp")))
	assert(last(1) == "T71B FIRST" and last() == "LEVEL " .. level, "BannerLog ends '" .. tostring(last(1)) .. "' | '" .. tostring(last()) .. "'")
	drained()
	table.insert(out, "order: the banner stays 2.5 s and more, then LEVEL " .. level .. " (LastLevelUp set then); BannerLog in that order")

	-- 2: the longest tier banner fits the box
	local known = LifeRules.Copy.Banners.KNOWN
	command("banner:" .. known)
	assert(waitFor(function() return shows(known) end, 1), "the KNOWN banner did not show")
	task.wait(0.1)
	assert(banner.TextBounds.Y <= banner.AbsoluteSize.Y and banner.TextBounds.X <= banner.AbsoluteSize.X, string.format("the KNOWN banner's text is %dx%d in a %dx%d box",
		banner.TextBounds.X, banner.TextBounds.Y, banner.AbsoluteSize.X, banner.AbsoluteSize.Y))
	table.insert(out, string.format("the KNOWN banner fits: text %dx%d in %dx%d", banner.TextBounds.X, banner.TextBounds.Y, banner.AbsoluteSize.X, banner.AbsoluteSize.Y))
	drained()

	-- 3: A14: held by the walk-in card; a LEVEL UP is not
	local mark = ui:GetAttribute("BannerLog")
	wCard.Visible = true
	command("banner:T71B HELD")
	task.wait(1.2)
	assert(not banner.Visible and ui:GetAttribute("BannerLog") == mark, "a banner showed over the walk-in card: '" .. banner.Text .. "'")
	command("level:" .. (level + 1))
	assert(waitFor(function() return shows("LEVEL " .. (level + 1)) end, 1), "a LEVEL UP waited for the card: showing '" .. banner.Text .. "'")
	assert(waitFor(function() return not banner.Visible end, 4.5), "the LEVEL banner did not end")
	task.wait(0.5)
	assert(not banner.Visible and last() == "LEVEL " .. (level + 1), "the held banner came while the card was still up")
	wCard.Visible = false
	assert(waitFor(function() return shows("T71B HELD") end, 1), "the held banner did not show when the card closed")
	drained()
	table.insert(out, "hold: held by the walk-in card, a LEVEL UP passes it, it shows when the card closes")

	-- 4: the result card and the phone card hold it too
	for _, c in ipairs({ { wResult, "T71B RESULT" }, { pCard, "T71B PHONE" } }) do
		local before = ui:GetAttribute("BannerLog")
		c[1].Visible = true
		command("banner:" .. c[2])
		task.wait(0.8)
		assert(not banner.Visible and ui:GetAttribute("BannerLog") == before, c[2] .. ": a banner showed over the card")
		c[1].Visible = false
		assert(waitFor(function() return shows(c[2]) end, 1), c[2] .. ": the held banner did not show when the card closed")
		drained()
	end
	table.insert(out, "hold: the walk-in's result card and the phone card hold it the same way")
	return string.format("T71B PLAY OK\n%s\nelapsed %.1f s", table.concat(out, "\n"), os.clock() - T0)
end

local ok, msg = pcall(run)
wCard.Visible, wResult.Visible, pCard.Visible = false, false, false
if not ok then error(msg, 0) end
return msg
