-- OK Studio nameplate: a BillboardGui over a character's head ("NAME" / "YEAR 2 · LV 4 · ENGINEER · 🔥 37"), coloured by
-- the player's nameplate gear (PlateColor). Built by the server (Systems/Reactions) so every player sees the same one;
-- it reads the player's Year attribute (Systems/Life) itself and follows it. 220 wide: the longest line, YEAR 15 · LV 10 ·
-- STUDIO LEGEND · 🔥 1234, measures 203 px at 11 px (t22b checks it). The 48 px height is what WalkIns' tag stacks on.
local M = {}
M.MaxDistance = 40
M.Width = 220

-- year nil (before Systems/Life has set it): the line has no year yet
function M.Text(level, rank, fires, year)
	local s = string.format("LV %d · %s", level or 1, rank or "")
	if year then s = string.format("YEAR %d · ", year) .. s end
	if (fires or 0) > 0 then s = s .. string.format(" · 🔥 %d", fires) end
	return s
end

function M.Attach(character, player, rankFor)
	local head = character:WaitForChild("Head", 10)
	if not head then return nil end
	local hum = character:FindFirstChildOfClass("Humanoid")
	if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end -- the plate replaces the default name
	local old = head:FindFirstChild("OK_Nameplate"); if old then old:Destroy() end
	local bb = Instance.new("BillboardGui")
	bb.Name = "OK_Nameplate"; bb.Size = UDim2.fromOffset(M.Width, 48); bb.StudsOffset = Vector3.new(0, 2.4, 0)
	bb.MaxDistance = M.MaxDistance; bb.LightInfluence = 0
	bb.PlayerToHideFrom = player -- others see it; you don't (a visitor's plate beside you, the plate over your monitor)
	local name = Instance.new("TextLabel")
	name.Name = "NameText"; name.Size = UDim2.new(1, 0, 0.55, 0); name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBlack; name.TextScaled = true; name.TextStrokeTransparency = 0.4
	name.Parent = bb
	local stats = Instance.new("TextLabel")
	stats.Name = "StatsText"; stats.Size = UDim2.new(1, 0, 0.45, 0); stats.Position = UDim2.fromScale(0, 0.55)
	stats.BackgroundTransparency = 1; stats.Font = Enum.Font.GothamBold; stats.TextScaled = true
	stats.TextColor3 = Color3.fromRGB(200, 200, 210); stats.TextStrokeTransparency = 0.5
	stats.Parent = bb
	bb.Adornee = head
	bb.Parent = head
	local function refresh()
		if not bb.Parent then return end
		local lv = player:GetAttribute("Level") or 1
		name.Text = player.DisplayName
		name.TextColor3 = player:GetAttribute("PlateColor") or Color3.fromRGB(240, 240, 240)
		stats.Text = M.Text(lv, rankFor(lv), player:GetAttribute("FireTotal") or 0, player:GetAttribute("Year"))
	end
	local conns = {}
	for _, a in ipairs({ "Level", "FireTotal", "PlateColor", "Year" }) do table.insert(conns, player:GetAttributeChangedSignal(a):Connect(refresh)) end
	bb.Destroying:Connect(function() for _, c in ipairs(conns) do c:Disconnect() end end)
	refresh()
	return bb
end

return M
