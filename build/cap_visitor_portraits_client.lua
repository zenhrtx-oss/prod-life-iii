-- Capture (Play, client; Wave 3 Task 5d): the card portraits of every look, as the cards build them (VisitorFigure.Portrait
-- with VisitorLooks.Frame), on one sheet for the user's capture: ViewportFrames don't draw in Studio's Edit mode. Each
-- tile: the portrait at 72 px, then at the two card sizes, 44 px (the walk-in card on taller screens and the phone card)
-- and 36 px (the walk-in card on phones held sideways), and the name. Not a test; test.py never runs it. Run it again to
-- take the sheet down (it toggles PlayerGui.OK_PortraitSheet).
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
local old = pg:FindFirstChild("OK_PortraitSheet")
if old then old:Destroy(); return "OK_PortraitSheet removed" end
local Looks = require(RS.OK.Modules.VisitorLooks)
local Figure = require(RS.OK.Modules.VisitorFigure)
local Content = require(RS.OK.Data.WalkIns)
local Config = require(RS.OK.Config)
local Theme = require(RS.OK.Modules.UITheme)
local names = Content.Names(Config.WalkIns.Roster)
local looks = {}
for _, v in ipairs(Content.Visitors) do
	if Looks.IsPerson(v.id) then table.insert(looks, { look = Looks.For(v.id), label = (string.gsub(names[v.id] or v.id, "{sponsor}", "A SPONSOR")) }) end
end
table.insert(looks, { look = Looks.Pigeon(), label = names.pigeon or "pigeon" })
table.insert(looks, { look = Looks.Generic("cap", { 255, 60, 160 }), label = "FALLBACK" })
local gui = Instance.new("ScreenGui")
gui.Name = "OK_PortraitSheet"; gui.ResetOnSpawn = false; gui.DisplayOrder = 50; gui.IgnoreGuiInset = true
local bg = Instance.new("Frame")
bg.Size = UDim2.fromScale(1, 1); bg.BackgroundColor3 = Color3.fromRGB(40, 40, 48); bg.BorderSizePixel = 0; bg.Parent = gui
local TW, TH = 180, 110
local vp = workspace.CurrentCamera.ViewportSize
local COLS = math.max(1, math.floor((vp.X - 16) / (TW + 6)))
for i, e in ipairs(looks) do
	local c, r = (i - 1) % COLS, (i - 1) // COLS
	local tile = Instance.new("Frame")
	tile.Position = UDim2.fromOffset(8 + c * (TW + 6), 8 + r * (TH + 6)); tile.Size = UDim2.fromOffset(TW, TH)
	tile.BackgroundColor3 = Theme.panel; tile.BorderSizePixel = 0; tile.Parent = bg
	local x = 6
	for _, px in ipairs({ 72, 44, 36 }) do
		local holder = Instance.new("Frame")
		holder.Position = UDim2.fromOffset(x, 6); holder.Size = UDim2.fromOffset(px, px); holder.BackgroundColor3 = Theme.bg
		holder.BorderSizePixel = 0; holder.ClipsDescendants = true; holder.Parent = tile
		local vf = Figure.Portrait(e.look, Looks.Frame(e.look), { name = "View", bg = Theme.bg, corner = 8 })
		vf.Parent = holder
		x += px + 6
	end
	local l = Instance.new("TextLabel")
	l.Position = UDim2.fromOffset(6, 82); l.Size = UDim2.fromOffset(TW - 12, 22); l.BackgroundTransparency = 1
	l.Font = Theme.fontBlack; l.TextScaled = true; l.TextWrapped = true; l.TextColor3 = Theme.text; l.Text = e.label; l.Parent = tile
end
gui.Parent = pg
return "OK_PortraitSheet shown: " .. #looks .. " looks at 72, 44 and 36 px, " .. COLS .. " a row (run again to remove)"
