-- Client, during play (two sessions Task 5; nothing is changed or set back): the LEVEL UP banner lives in its
-- own ScreenGui, PlayerGui.OK_LevelUp, above the cards. (1) OK_LevelUp is a ScreenGui whose DisplayOrder is above
-- OK_Phone's (9), OK_WalkIn's (8) and OK_UI's; ResetOnSpawn is false. (2) It has OK_UI's IgnoreGuiInset and
-- ScreenInsets, and the same AbsolutePosition and AbsoluteSize as OK_UI, so the banner lands where it did inside
-- OK_UI. (3) Its banner, the TextLabel OK_LevelUp.LevelUp, keeps its 420x64 size, its AnchorPoint (0.5, 0) and its
-- Position (0.5, 0, 0, 70); OK_UI holds no LevelUp of its own. That LastLevelUp still updates on OK_UI is proven by
-- t15/t15b. (4, Wave 2) Two C.Banner calls in a row show in order, one at a time, on that same banner and geometry; each
-- leaves it where it was (a Studio PanelCommand "banner:<text>", and BannerLog on OK_UI; t71b has the queue's other rules).
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui", 10); assert(pg, "no PlayerGui")
local ui = pg:WaitForChild("OK_UI", 10); assert(ui, "no OK_UI")
local phone = pg:WaitForChild("OK_Phone", 10); assert(phone, "no OK_Phone gui (PhoneUI.Build did not run?)")
local wg = pg:WaitForChild("OK_WalkIn", 10); assert(wg, "no OK_WalkIn gui")
local lv = pg:WaitForChild("OK_LevelUp", 10)
assert(lv, "no PlayerGui.OK_LevelUp (before the Task 5 sync of Modules/HUD the banner is OK_UI.LevelUp: the expected red)")
assert(lv:IsA("ScreenGui"), "OK_LevelUp is a " .. lv.ClassName .. ", not a ScreenGui")
local out = {}
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function command(c)
	ui:SetAttribute("PanelCommand", c)
	assert(waitFor(function() return ui:GetAttribute("PanelCommand") == "" end, 6), "PanelCommand '" .. c .. "' was not taken (Studio seam missing?)")
end

-- 1. above the cards and OK_UI; kept through a respawn
assert(lv.DisplayOrder > phone.DisplayOrder and lv.DisplayOrder > wg.DisplayOrder and lv.DisplayOrder > ui.DisplayOrder, string.format(
	"OK_LevelUp's DisplayOrder %d is not above OK_Phone's %d, OK_WalkIn's %d and OK_UI's %d", lv.DisplayOrder, phone.DisplayOrder,
	wg.DisplayOrder, ui.DisplayOrder))
assert(lv.ResetOnSpawn == false, "OK_LevelUp.ResetOnSpawn is true: a respawn would lose the banner")
table.insert(out, string.format("OK_LevelUp DisplayOrder %d over OK_Phone %d, OK_WalkIn %d, OK_UI %d; ResetOnSpawn false", lv.DisplayOrder,
	phone.DisplayOrder, wg.DisplayOrder, ui.DisplayOrder))

-- 2. OK_UI's insets: the same box
assert(lv.IgnoreGuiInset == ui.IgnoreGuiInset and lv.ScreenInsets == ui.ScreenInsets, string.format("OK_LevelUp's IgnoreGuiInset %s / ScreenInsets %s"
	.. " differ from OK_UI's %s / %s", tostring(lv.IgnoreGuiInset), tostring(lv.ScreenInsets), tostring(ui.IgnoreGuiInset), tostring(ui.ScreenInsets)))
assert(lv.AbsolutePosition == ui.AbsolutePosition and lv.AbsoluteSize == ui.AbsoluteSize, string.format("OK_LevelUp's box %s + %s differs from"
	.. " OK_UI's %s + %s", tostring(lv.AbsolutePosition), tostring(lv.AbsoluteSize), tostring(ui.AbsolutePosition), tostring(ui.AbsoluteSize)))
table.insert(out, string.format("OK_UI's insets (IgnoreGuiInset %s, %s) and box %s + %s", tostring(lv.IgnoreGuiInset), tostring(lv.ScreenInsets),
	tostring(lv.AbsolutePosition), tostring(lv.AbsoluteSize)))

-- 3. the banner itself, unchanged
local banner = lv:FindFirstChild("LevelUp")
assert(banner and banner:IsA("TextLabel"), "no OK_LevelUp.LevelUp TextLabel")
assert(banner.Size == UDim2.fromOffset(420, 64), "the banner's Size is " .. tostring(banner.Size) .. ", want 420x64 offset")
assert(banner.AnchorPoint == Vector2.new(0.5, 0), "the banner's AnchorPoint is " .. tostring(banner.AnchorPoint) .. ", want (0.5, 0)")
assert(banner.Position == UDim2.new(0.5, 0, 0, 70), "the banner's Position is " .. tostring(banner.Position) .. ", want {0.5, 0}, {0, 70}")
assert(ui:FindFirstChild("LevelUp") == nil, "OK_UI still holds a LevelUp beside OK_LevelUp's")
local stroke = banner:FindFirstChildOfClass("UIStroke")
assert(stroke and stroke.ApplyStrokeMode == Enum.ApplyStrokeMode.Border, "the banner's outline strokes its letters (ApplyStrokeMode " .. tostring(stroke and stroke.ApplyStrokeMode) .. "), want Border")
table.insert(out, string.format("banner OK_LevelUp.LevelUp: Size %s, AnchorPoint %s, Position %s; OK_UI has no LevelUp", tostring(banner.Size),
	tostring(banner.AnchorPoint), tostring(banner.Position)))

-- 4. two banners in a row, in order, on the same banner
assert(waitFor(function() return not banner.Visible end, 8), "a banner is still showing before the two: " .. banner.Text)
command("banner:T68 FIRST")
command("banner:T68 SECOND")
assert(banner.Visible and banner.Text == "T68 FIRST", "the first banner did not show at once: '" .. banner.Text .. "'")
assert(banner.Size == UDim2.fromOffset(420, 64) and banner.Position == UDim2.new(0.5, 0, 0, 70) and banner.Parent == lv, "a queued banner moved or changed size")
assert(waitFor(function() return banner.Text == "T68 SECOND" end, 4.5) and banner.Visible, "the second banner did not follow: '" .. banner.Text .. "'")
local log = string.split(ui:GetAttribute("BannerLog") or "", "|")
assert(log[#log - 1] == "T68 FIRST" and log[#log] == "T68 SECOND", "BannerLog: " .. tostring(ui:GetAttribute("BannerLog")))
assert(waitFor(function() return not banner.Visible end, 4.5), "the second banner did not end")
table.insert(out, "two banners in a row: FIRST, then SECOND, on the same 420x64 banner; BannerLog in order")
return "T68 PLAY OK\n" .. table.concat(out, "\n")
