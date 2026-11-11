-- OK Studio tour tracker: a small card under the HUD ("STUDIO TOUR 1/4", the step, SKIP) and an outline
-- Highlight on the current target. Driven only by server "Tour" events; it never decides progress itself.
-- gui attributes for tests: TourVisible, TourCount, TourStep.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local M = {}

function M.Build(gui, Theme, below)
	local function new(class, props, parent)
		local i = Instance.new(class)
		for k, v in pairs(props) do i[k] = v end
		i.Parent = parent
		return i
	end
	local y = below and (below.Position.Y.Offset + below.Size.Y.Offset + 8) or 66
	local card = new("Frame", { Name = "Tour", Position = UDim2.fromOffset(12, y), Size = UDim2.fromOffset(250, 66),
		BackgroundColor3 = Theme.panel, BackgroundTransparency = 0.1, BorderSizePixel = 0, Visible = false }, gui)
	new("UICorner", { CornerRadius = UDim.new(0, 12) }, card)
	new("UIStroke", { Color = Theme.accent, Thickness = 1, Transparency = 0.3 }, card)
	local head = new("TextLabel", { Name = "Head", Position = UDim2.fromOffset(12, 6), Size = UDim2.fromOffset(170, 16),
		BackgroundTransparency = 1, Text = "STUDIO TOUR", TextColor3 = Theme.accent, Font = Theme.fontBlack, TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left }, card)
	local step = new("TextLabel", { Name = "Step", Position = UDim2.fromOffset(12, 24), Size = UDim2.fromOffset(172, 36),
		BackgroundTransparency = 1, Text = "", TextColor3 = Theme.text, Font = Theme.font, TextSize = 13, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, card)
	local skip = new("TextButton", { Name = "Skip", Position = UDim2.fromOffset(192, 11), Size = UDim2.fromOffset(50, 44), -- 44 px touch target
		BackgroundColor3 = Theme.line, Text = "SKIP", TextColor3 = Theme.muted, Font = Theme.fontBlack, TextSize = 11 }, card)
	new("UICorner", { CornerRadius = UDim.new(0, 6) }, skip)

	local hl = Instance.new("Highlight")
	hl.Name = "OK_TourHighlight"; hl.FillTransparency = 1; hl.OutlineColor = Theme.accent; hl.OutlineTransparency = 0.1
	hl.DepthMode = Enum.HighlightDepthMode.Occluded; hl.Enabled = false
	hl.Parent = gui

	local function resolve(fullName)
		local node = game
		for seg in string.gmatch(fullName or "", "[^%.]+") do node = node and node:FindFirstChild(seg) end
		return node ~= game and node or nil
	end

	local C = { Card = card, Highlight = hl }
	function C.Set(s)
		local show = s and not s.done and (s.text or "") ~= ""
		card.Visible = show and true or false
		gui:SetAttribute("TourVisible", card.Visible)
		gui:SetAttribute("TourCount", s and s.count or 0)
		gui:SetAttribute("TourStep", show and s.step or "")
		if show then
			head.Text = string.format("STUDIO TOUR  %d/%d", (s.count or 0) + 1, s.total or 4)
			step.Text = s.text
			local target = resolve(s.target)
			hl.Adornee = target; hl.Enabled = target ~= nil
		else
			hl.Adornee = nil; hl.Enabled = false
		end
	end
	skip.MouseButton1Click:Connect(function() RS.OK.Remotes.Tour_Skip:FireServer() end)
	return C
end

return M
