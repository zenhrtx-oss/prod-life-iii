-- Studio Sessions panel inside the beat maker window (OK_DAW).
-- Desktop: a card docked above the window's top-right edge, always up while the beat maker is open.
-- Phone (Compact): a 44 px chip in the window header opens the same card over the grid. The chip sits at
-- max(W − 190, header right + 6), clear of the close button (Modules/DAWLayout.Chip, from the window's HeaderRight and
-- CloseLeft attributes, which DAWUI publishes), its text scaled down when the band leaves it under 124 px; under 44 px
-- (an expanded unibar) it hides.
-- Overlays: Picker (up to 3 offers + FREE PLAY), Presets (start from a preset, blank, or keep your beat), Result.
-- State and test hooks live in attributes on the card ("Request"):
--   Cutaway (camera in the booth during the listen-back), Active (brief id or ""), Offers ("j1,t1,j2"), Ticks ("101"), BonusOk, Changed (pads changed), Stars (0/2/3 preview),
--   Overlay ("none" | "picker" | "presets" | "result"), CardOpen (phone), LastDeliver, ResultStars, Message
--   Command: requests | take:<id> | preset:<NAME|BLANK|KEEP> | deliver | next | close | card
local Format = require(game:GetService("ReplicatedStorage").OK.Modules.Format)
local DAWLayout = require(game:GetService("ReplicatedStorage").OK.Modules.DAWLayout)
local M = {}
local MIN_TOUCH = 44

function M.Build(gui, Theme, Cfg, dawRoot, Artists, Check)
	local function new(class, props, parent)
		local i = Instance.new(class)
		for k, v in pairs(props) do i[k] = v end
		i.Parent = parent
		return i
	end
	local function corner(p, r) new("UICorner", { CornerRadius = UDim.new(0, r or 10) }, p) end
	local function button(parent, name, text, color, order)
		local b = new("TextButton", { Name = name, Text = text, BackgroundColor3 = color or Theme.line, TextColor3 = Theme.text,
			Font = Theme.fontBlack, TextSize = 14, AutoButtonColor = true, LayoutOrder = order or 0, Size = UDim2.new(1, 0, 0, MIN_TOUCH) }, parent)
		corner(b, 8)
		return b
	end
	local C = {}
	C.OnOpenPicker, C.OnTake, C.OnPreset, C.OnDeliver, C.OnNext = function() end, function() end, function() end, function() end, function() end
	local state = { offers = {}, active = nil, done = {} }

	-- card -------------------------------------------------------------------------------
	local card = new("Frame", { Name = "Request", BackgroundColor3 = Theme.panel, BorderSizePixel = 0, Visible = false, ZIndex = 5 }, dawRoot)
	corner(card, 12); new("UIStroke", { Color = Theme.accent, Thickness = 1.5, Transparency = 0.2 }, card)
	new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }, card)
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, card)
	for k, v in pairs({ Active = "", Offers = "", Ticks = "", BonusOk = false, Changed = 0, Stars = 0, Overlay = "none", CardOpen = false,
		LastDeliver = "", ResultStars = 0, Message = "", Command = "", Cutaway = false }) do card:SetAttribute(k, v) end
	local head = new("TextLabel", { Name = "Head", Text = "SESSION REQUESTS", Font = Theme.fontBlack, TextSize = 14, TextColor3 = Theme.accent,
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1, ZIndex = 5,
		TextTruncate = Enum.TextTruncate.AtEnd }, card)
	local sub = new("TextLabel", { Name = "Sub", Text = "", Font = Theme.font, TextSize = 13, TextColor3 = Theme.text, BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2, ZIndex = 5, TextTruncate = Enum.TextTruncate.AtEnd }, card)
	local askRows = {}
	for i = 1, 5 do
		askRows[i] = new("TextLabel", { Name = "Ask" .. i, Text = "", Font = Theme.font, TextSize = 13, TextColor3 = Theme.muted,
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 10 + i,
			Visible = false, ZIndex = 5, RichText = true }, card)
	end
	local msg = new("TextLabel", { Name = "Msg", Text = "", Font = Theme.font, TextSize = 12, TextColor3 = Theme.muted, BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true,
		LayoutOrder = 30, ZIndex = 5 }, card)
	local btnRow = new("Frame", { Name = "Buttons", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, MIN_TOUCH), LayoutOrder = 40, ZIndex = 5 }, card)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, btnRow)
	local deliver = button(btnRow, "Deliver", "DELIVER", Theme.accent, 1)
	local requests = button(btnRow, "Requests", "REQUESTS", Theme.line, 2)
	local back = button(btnRow, "Back", "BACK", Theme.line, 3)
	for _, b in ipairs({ deliver, requests, back }) do b.ZIndex = 5 end

	-- phone chip ---------------------------------------------------------------------------
	local chip = new("TextButton", { Name = "RequestChip", Text = "REQUESTS", BackgroundColor3 = Color3.fromRGB(60, 40, 90), TextColor3 = Theme.text,
		Font = Theme.fontBlack, TextSize = 13, Visible = false, AutoButtonColor = true, ZIndex = 4 }, dawRoot)
	corner(chip, 8)
	new("UITextSizeConstraint", { MaxTextSize = 13 }, chip)

	-- overlays (picker, presets, result) ---------------------------------------------------
	local function overlay(name)
		local o = new("Frame", { Name = name, BackgroundColor3 = Theme.bg, BackgroundTransparency = 0.05, BorderSizePixel = 0, Visible = false,
			ZIndex = 10, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) }, dawRoot)
		corner(o, 12); new("UIStroke", { Color = Theme.line, Thickness = 1.5 }, o)
		new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }, o)
		local sc = new("ScrollingFrame", { Name = "List", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4, BorderSizePixel = 0, ZIndex = 10 }, o)
		new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, sc)
		return o, sc
	end
	local picker, pickerList = overlay("Picker")
	local presets, presetList = overlay("Presets")
	local result, resultList = overlay("Result")
	local function clearList(list) for _, ch in ipairs(list:GetChildren()) do if ch:IsA("GuiObject") then ch:Destroy() end end end
	local function label(parent, text, size, color, order, font, h)
		return new("TextLabel", { Text = text, Font = font or Theme.font, TextSize = size, TextColor3 = color or Theme.text, BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, h or (size + 6)), TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, LayoutOrder = order, ZIndex = 10 }, parent)
	end

	-- helpers ---------------------------------------------------------------------------------
	local function briefOf(id) return id and Artists.BriefById[id] end
	local function rewardText(b, again)
		if again then return "Done before · credit only, no pay" end
		if b.daily then return string.format("+%d XP · +%s today · keeps your streak going", b.reward.xp, Format.Money(b.reward.cred)) end
		if b.weekly then return string.format("+%d XP · +%s this week · 3 stars earns a plaque", b.reward.xp, Format.Money(b.reward.cred)) end
		return string.format("+%d XP · +%s (x1.5 with the bonus)", b.reward.xp, Format.Money(b.reward.cred))
	end
	local function setOverlay(name)
		picker.Visible = name == "picker"; presets.Visible = name == "presets"; result.Visible = name == "result"
		card:SetAttribute("Overlay", name)
	end
	local function compact() return dawRoot:GetAttribute("Compact") == true end

	function C.Layout()
		local W, H = dawRoot.AbsoluteSize.X, dawRoot.AbsoluteSize.Y
		local cmp = compact()
		local ow = math.min(W - 24, 460)
		for _, o in ipairs({ picker, presets, result }) do o.Size = UDim2.fromOffset(ow, math.min(H - 24, cmp and H - 24 or 360)) end
		local active = briefOf(card:GetAttribute("Active") ~= "" and card:GetAttribute("Active") or nil)
		local rows = active and (#active.asks + (active.bonus and 1 or 0) + 1) or 0
		local h = 16 + 18 + 4 + 16 + 4 + rows * 22 + 34 + MIN_TOUCH + 8
		if cmp then
			-- until the window publishes its band: the chip at home (W − 190), the close button at W − 50; a band too short
			-- for a 44 px chip (an expanded unibar) hides it, and MiniSubmit with it (CypherUI)
			local x, w = DAWLayout.Chip(dawRoot:GetAttribute("HeaderRight") or 0, dawRoot:GetAttribute("CloseLeft") or (W - 50))
			chip.Visible = w >= DAWLayout.MIN
			chip.Size = UDim2.fromOffset(w, MIN_TOUCH)
			chip.Position = UDim2.fromOffset(x, 4)
			chip.TextScaled = w < DAWLayout.CHIP
			card.AnchorPoint = Vector2.new(0.5, 0.5); card.Position = UDim2.fromScale(0.5, 0.5)
			card.Size = UDim2.fromOffset(math.min(W - 24, 420), h)
			card.Visible = card:GetAttribute("CardOpen") == true
			back.Visible = true
		else
			chip.Visible = false
			card.AnchorPoint = Vector2.new(1, 1); card.Position = UDim2.new(1, 0, 0, -8)
			card.Size = UDim2.fromOffset(360, h)
			card.Visible = dawRoot.Visible
			back.Visible = false
		end
		local n = (deliver.Visible and 1 or 0) + 1 + (back.Visible and 1 or 0)
		local bw = math.floor(((card.Size.X.Offset - 20) - (n - 1) * 6) / n)
		for _, b in ipairs({ deliver, requests, back }) do b.Size = UDim2.fromOffset(bw, MIN_TOUCH) end
	end

	-- live ticks: call with the beat maker's current beat
	function C.Update(pattern, bpm, swing, extraRefs)
		local id = card:GetAttribute("Active")
		local b = briefOf(id ~= "" and id or nil)
		for i = 1, 5 do askRows[i].Visible = false end
		if not b then
			head.Text = "SESSION REQUESTS"; head.TextColor3 = Theme.accent
			sub.Text = "Artists want beats. Take a request to earn money."
			deliver.Visible = false; requests.Text = "SEE REQUESTS"
			chip.Text = "REQUESTS"
			card:SetAttribute("Ticks", ""); card:SetAttribute("Stars", 0)
			C.Layout()
			return
		end
		local a = Artists.ArtistById[b.artist]
		head.Text = a.name .. " · " .. string.upper(b.title); head.TextColor3 = a.color
		sub.Text = a.style
		local res = Check.Check(Cfg, b, pattern, bpm, swing)
		local ticks = {}
		for i, r in ipairs(res.asks) do
			askRows[i].Visible = true
			askRows[i].Text = (r.ok and '<font color="#00FF8C">✓</font>  ' or "○  ") .. r.text
			askRows[i].TextColor3 = r.ok and Theme.text or Theme.muted
			table.insert(ticks, r.ok and "1" or "0")
		end
		local i = #res.asks
		if res.bonus then
			i += 1
			askRows[i].Visible = true
			askRows[i].Text = (res.bonus.ok and '<font color="#FFD24A">★</font>  ' or "☆  ") .. "Bonus: " .. res.bonus.text
			askRows[i].TextColor3 = res.bonus.ok and Theme.text or Theme.muted
		end
		local changed = Check.Changed(pattern, Check.References(Cfg, extraRefs))
		i += 1
		askRows[i].Visible = true
		local yours = changed >= Check.MinChanged
		askRows[i].Text = (yours and '<font color="#00FF8C">✓</font>  ' or "○  ") .. string.format("Make it yours: %d/%d pads changed", math.min(changed, Check.MinChanged), Check.MinChanged)
		askRows[i].TextColor3 = yours and Theme.text or Theme.muted
		local ready = res.passed and yours
		deliver.Visible = true
		deliver.BackgroundColor3 = ready and Theme.accent or Theme.line
		deliver.Text = ready and ("DELIVER " .. string.rep("★", res.stars)) or "DELIVER"
		requests.Text = "SWITCH"
		chip.Text = string.format("REQUEST %d/%d%s", res.met, res.total, ready and " ✓" or "")
		card:SetAttribute("Ticks", table.concat(ticks)); card:SetAttribute("BonusOk", res.bonus and res.bonus.ok or false)
		card:SetAttribute("Changed", changed); card:SetAttribute("Stars", yours and res.stars or 0)
		C.Layout()
	end

	function C.SetMessage(text) msg.Text = text or ""; card:SetAttribute("Message", text or "") end
	function C.SetState(st)
		state = st or state
		card:SetAttribute("Active", state.active or "")
		local ids = {}
		for _, o in ipairs(state.offers or {}) do table.insert(ids, o.id) end
		card:SetAttribute("Offers", table.concat(ids, ","))
	end

	function C.ShowPicker()
		clearList(pickerList)
		label(pickerList, "SESSION REQUESTS", 16, Theme.accent, 0, Theme.fontBlack)
		for i, o in ipairs(state.offers or {}) do
			local b = briefOf(o.id); local a = b and Artists.ArtistById[b.artist]
			if b and a then
				local f = new("Frame", { Name = "Offer_" .. b.id, BackgroundColor3 = Theme.panel, Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
					LayoutOrder = i, ZIndex = 10 }, pickerList)
				corner(f, 10)
				new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }, f)
				new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, f)
				label(f, a.name .. (b.starter and "  ·  STARTER" or "") .. (b.daily and "  ·  DAILY" or "") .. (b.weekly and "  ·  WEEKLY SINGLE" or ""), 14, a.color, 1, Theme.fontBlack)
				label(f, "“" .. b.title .. "” · " .. a.style, 13, Theme.text, 2)
				local asks = {}
				for _, ask in ipairs(b.asks) do table.insert(asks, Check.Text(ask)) end
				label(f, table.concat(asks, " · "), 12, Theme.muted, 3, nil, 32)
				label(f, rewardText(b, o.again), 12, Theme.ledOn, 4)
				local take = button(f, "Take_" .. b.id, "TAKE", Theme.accent, 5)
				take.ZIndex = 10
				take.MouseButton1Click:Connect(function() card:SetAttribute("Command", "take:" .. b.id) end)
			end
		end
		local free = button(pickerList, "FreePlay", "FREE PLAY", Theme.line, 99); free.ZIndex = 10
		free.MouseButton1Click:Connect(function() card:SetAttribute("Command", "close") end)
		setOverlay("picker")
	end
	function C.ShowPresets()
		clearList(presetList)
		label(presetList, "START FROM", 16, Theme.accent, 0, Theme.fontBlack)
		label(presetList, "Change at least " .. Check.MinChanged .. " pads to make it yours.", 12, Theme.muted, 1)
		for i, p in ipairs(Cfg.Presets or {}) do
			local b = button(presetList, "Preset_" .. p.name, p.name .. "  ·  " .. p.bpm .. " BPM", Theme.line, 1 + i); b.ZIndex = 10
			b.MouseButton1Click:Connect(function() card:SetAttribute("Command", "preset:" .. p.name) end)
		end
		local blank = button(presetList, "Preset_BLANK", "BLANK GRID", Theme.line, 10); blank.ZIndex = 10
		blank.MouseButton1Click:Connect(function() card:SetAttribute("Command", "preset:BLANK") end)
		local keep = button(presetList, "Preset_KEEP", "KEEP MY BEAT", Theme.accent2, 11); keep.ZIndex = 10
		keep.MouseButton1Click:Connect(function() card:SetAttribute("Command", "preset:KEEP") end)
		setOverlay("presets")
	end
	function C.ShowResult(res)
		clearList(resultList)
		local b = briefOf(res.brief); local a = b and Artists.ArtistById[b.artist]
		label(resultList, string.rep("★", res.stars or 0) .. string.rep("☆", 3 - (res.stars or 0)), 30, Color3.fromRGB(255, 210, 74), 0, Theme.fontBlack, 38)
		if a then label(resultList, a.name .. ": “" .. (res.reaction or "") .. "”", 15, a.color, 1, Theme.fontBlack, 40) end
		label(resultList, res.again and "Done before: credit added, no pay this time" or string.format("+%d XP  ·  +%s", res.xp or 0, Format.Money(res.cred or 0)), 15, Theme.ledOn, 2, Theme.fontBlack)
		label(resultList, "Credit: " .. (res.credit or ""), 13, Theme.text, 3)
		if res.plaque then label(resultList, "🏆 PLAQUE EARNED · it's on your producer card", 15, Color3.fromRGB(255, 210, 74), 3, Theme.fontBlack) end
		local nxt = button(resultList, "Next", "NEXT REQUEST", Theme.accent, 4); nxt.ZIndex = 10
		nxt.MouseButton1Click:Connect(function() card:SetAttribute("Command", "next") end)
		local cl = button(resultList, "CloseResult", "BACK TO THE BEAT", Theme.line, 5); cl.ZIndex = 10
		cl.MouseButton1Click:Connect(function() card:SetAttribute("Command", "close") end)
		card:SetAttribute("ResultStars", res.stars or 0)
		setOverlay("result")
	end
	function C.CloseOverlays() setOverlay("none") end
	function C.IsOverlayOpen() return card:GetAttribute("Overlay") ~= "none" end
	function C.SetCardOpen(on) card:SetAttribute("CardOpen", on and true or false); C.Layout() end
	function C.Hide() setOverlay("none"); card:SetAttribute("CardOpen", false); card.Visible = false; chip.Visible = false end

	-- input --------------------------------------------------------------------------------------
	deliver.MouseButton1Click:Connect(function() card:SetAttribute("Command", "deliver") end)
	requests.MouseButton1Click:Connect(function() card:SetAttribute("Command", "requests") end)
	back.MouseButton1Click:Connect(function() card:SetAttribute("Command", "card") end)
	chip.MouseButton1Click:Connect(function() card:SetAttribute("Command", "card") end)
	card:GetAttributeChangedSignal("Command"):Connect(function()
		local cmd = card:GetAttribute("Command")
		if cmd == "" then return end
		card:SetAttribute("Command", "")
		if cmd == "requests" then C.OnOpenPicker()
		elseif cmd:sub(1, 5) == "take:" then C.OnTake(cmd:sub(6))
		elseif cmd:sub(1, 7) == "preset:" then C.OnPreset(cmd:sub(8))
		elseif cmd == "deliver" then C.OnDeliver()
		elseif cmd == "next" then C.OnNext()
		elseif cmd == "close" then setOverlay("none")
		elseif cmd == "card" then C.SetCardOpen(not card:GetAttribute("CardOpen"))
		end
	end)
	dawRoot:GetPropertyChangedSignal("AbsoluteSize"):Connect(C.Layout)
	for _, a in ipairs({ "Compact", "HeaderRight", "CloseLeft" }) do dawRoot:GetAttributeChangedSignal(a):Connect(C.Layout) end
	C.Card, C.Chip = card, chip
	return C
end

return M
