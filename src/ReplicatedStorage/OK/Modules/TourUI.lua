-- OK Studio tour tracker: the DAY ONE pill under the HUD ("DAY ONE  1/5", the step, SKIP) and an outline Highlight on
-- the step's target. Driven only by the server's "Tour" events ({ done, count, total, step, text, target, roomText });
-- it never decides progress itself.
-- Day One (the Day One plan, Task 4): the heading is Data/DayOne's Header, as "%s  %d/%d". Where you stand picks the
-- line and the outline: in your own plot (the player attributes InPlot == PlotSlot ~= 0) the pill shows the payload's
-- roomText (Data/DayOne's room line, {artist} filled by Systems/Tour) and outlines your bedroom's laptop
-- (Workspace.OK_Plots[RoomBuild.PlotName(PlotSlot)][RoomBuild.RoomName("bedroom")], RoomBuild.StationOf) for every step,
-- even gear (the rack beside it is a 0.4-stud invisible RackSpot); anywhere else it shows the hub line (text) and
-- outlines the payload's target. It lays out again when InPlot or PlotSlot changes, and while a step shows with no
-- target on this client (streaming, or a plot rebuilt under you) it looks again every second. In your plot the open
-- and take steps pulse the outline (OutlineTransparency 0.1 <-> 0.6). The pill's frame hides while a walk-in or Day One
-- card is open (PlayerGui.OK_WalkIn's Open attribute) and comes back when it closes; TourVisible keeps meaning "a step
-- to show", so ClientMain's daily pill stays hidden meanwhile (preflight m15).
-- gui attributes for tests: TourVisible, TourCount, TourStep, TourTarget (the outlined part's full name, "" for none),
-- TourPulse (the outline pulses).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local M = {}
-- RoomBuild (the plot and room names, StationOf), loaded so a broken rooms edit can't take the pill, the panels and the
-- toasts down with it (ClientMain builds TourUI unguarded; fix 1, review minor 1): reported, and the pill then shows the
-- hub's line and target everywhere
local okRooms, RoomBuild = pcall(function() return require(RS.OK.Modules.RoomBuild) end)
if not okRooms then
	warn("[OK][ERR] TourUI: Modules/RoomBuild failed to load: " .. tostring(RoomBuild))
	RoomBuild = nil
end
local PULSE_STEPS = { open = true, take = true } -- in your plot these steps' outline pulses
local REST, FAR = 0.1, 0.6 -- the outline's transparency at rest, and the pulse's other end
local PULSE = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

-- the pill's heading: Data/DayOne's Header (a failure is reported; the words fall back)
local function heading()
	local ok, D = pcall(function() return require(RS.OK.Data.DayOne) end)
	if ok and type(D) == "table" and type(D.Header) == "string" and D.Header ~= "" then return D.Header end
	warn("[OK][ERR] TourUI: Data/DayOne has no Header: " .. tostring(ok and "missing" or D))
	return "DAY ONE"
end

function M.Build(gui, Theme, below)
	local player = Players.LocalPlayer
	local HEADER = heading()
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
		BackgroundTransparency = 1, Text = HEADER, TextColor3 = Theme.accent, Font = Theme.fontBlack, TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left }, card)
	local step = new("TextLabel", { Name = "Step", Position = UDim2.fromOffset(12, 24), Size = UDim2.fromOffset(172, 36),
		BackgroundTransparency = 1, Text = "", TextColor3 = Theme.text, Font = Theme.font, TextSize = 13, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, card)
	local skip = new("TextButton", { Name = "Skip", Position = UDim2.fromOffset(192, 11), Size = UDim2.fromOffset(50, 44), -- 44 px touch target
		BackgroundColor3 = Theme.line, Text = "SKIP", TextColor3 = Theme.muted, Font = Theme.fontBlack, TextSize = 11 }, card)
	new("UICorner", { CornerRadius = UDim.new(0, 6) }, skip)

	local hl = Instance.new("Highlight")
	hl.Name = "OK_TourHighlight"; hl.FillTransparency = 1; hl.OutlineColor = Theme.accent; hl.OutlineTransparency = REST
	hl.DepthMode = Enum.HighlightDepthMode.Occluded; hl.Enabled = false
	hl.Parent = gui

	local function resolve(fullName)
		local node = game
		for seg in string.gmatch(fullName or "", "[^%.]+") do node = node and node:FindFirstChild(seg) end
		return node ~= game and node or nil
	end
	-- in your own plot: true and the slot (InPlot == PlotSlot ~= 0); never without RoomBuild (the hub's line and target)
	local function home()
		if not RoomBuild then return false, nil end
		local k = player:GetAttribute("PlotSlot")
		if type(k) ~= "number" or k == 0 then return false, nil end
		return player:GetAttribute("InPlot") == k, k
	end
	-- your bedroom's laptop on this client, or nil (not streamed in yet)
	local function bedroomLaptop(k)
		local plots = workspace:FindFirstChild("OK_Plots")
		local plot = plots and plots:FindFirstChild(RoomBuild.PlotName(k))
		local room = plot and plot:FindFirstChild(RoomBuild.RoomName("bedroom"))
		return room and RoomBuild.StationOf(room) or nil
	end
	local function cardOpen() -- a walk-in or Day One card is on screen
		local pg = player:FindFirstChildOfClass("PlayerGui")
		local w = pg and pg:FindFirstChild("OK_WalkIn")
		return w ~= nil and w:GetAttribute("Open") == true
	end

	local last = nil  -- the last Tour payload
	local pulse = nil -- the outline's running tween
	local function setPulse(on)
		if gui:GetAttribute("TourPulse") ~= on then gui:SetAttribute("TourPulse", on) end
		if on and not pulse then
			hl.OutlineTransparency = REST
			pulse = TweenService:Create(hl, PULSE, { OutlineTransparency = FAR })
			pulse:Play()
		elseif not on then
			if pulse then pulse:Cancel(); pulse = nil end
			hl.OutlineTransparency = REST
		end
	end
	local function shown(s) return s ~= nil and not s.done and (s.text or "") ~= "" end
	-- the pill and the outline from the last payload and where you stand now
	local function lay()
		local s = last
		local show = shown(s)
		card.Visible = show and not cardOpen()
		gui:SetAttribute("TourVisible", show)
		gui:SetAttribute("TourCount", s and s.count or 0)
		gui:SetAttribute("TourStep", show and s.step or "")
		local target, pulsing = nil, false
		if show then
			local inPlot, k = home()
			head.Text = string.format("%s  %d/%d", HEADER, (s.count or 0) + 1, s.total or 5)
			local roomLine = (type(s.roomText) == "string" and s.roomText ~= "") and s.roomText or nil
			step.Text = (inPlot and roomLine) or s.text
			if inPlot then target = bedroomLaptop(k) else target = resolve(s.target) end
			pulsing = inPlot and target ~= nil and PULSE_STEPS[s.step] == true
		end
		hl.Adornee = target; hl.Enabled = target ~= nil
		gui:SetAttribute("TourTarget", target and target:GetFullName() or "")
		setPulse(pulsing)
	end

	local C = { Card = card, Highlight = hl }
	function C.Set(s)
		last = type(s) == "table" and s or nil
		lay()
	end
	skip.MouseButton1Click:Connect(function() RS.OK.Remotes.Tour_Skip:FireServer() end)
	-- where you stand: your plot or not, a slot claimed or released
	player:GetAttributeChangedSignal("InPlot"):Connect(lay)
	player:GetAttributeChangedSignal("PlotSlot"):Connect(lay)
	-- the walk-in card's Open: the frame hides under it and comes back after
	local function watch(w)
		w:GetAttributeChangedSignal("Open"):Connect(function() card.Visible = shown(last) and w:GetAttribute("Open") ~= true end)
	end
	local pg = player:FindFirstChildOfClass("PlayerGui")
	local wg = pg and pg:FindFirstChild("OK_WalkIn")
	if wg then
		watch(wg)
	elseif pg then
		local conn
		conn = pg.ChildAdded:Connect(function(c)
			if c.Name ~= "OK_WalkIn" then return end
			conn:Disconnect()
			watch(c)
			lay()
		end)
	end
	-- a step shown with no target here (not streamed in, or the part was rebuilt): looked for again every second
	task.spawn(function()
		while gui.Parent do
			task.wait(1)
			if shown(last) and not (hl.Adornee and hl.Adornee:IsDescendantOf(workspace)) then lay() end
		end
	end)
	return C
end

return M
