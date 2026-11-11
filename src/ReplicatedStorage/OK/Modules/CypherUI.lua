-- Cypher bar (client): its own ScreenGui. At the top, right of the HUD's career pills (OK_UI.Career) and the phone icon
-- beside them (OK_Phone's IconSpot "pills": the bar starts after the icon; "corner": the icon is at the top right and
-- the bar leaves it 64 px there) and centred when the screen is wide enough; when that leaves under 240 px (phones) it
-- drops under the pills (top 74), right-aligned and clear of the daily / tour pill. The viewport is OK_UI's
-- ForceViewport (tests, the one the pills follow) or this gui's size.
-- Shows the phase and time left; JOIN in the lobby; in the build the brief's asks tick
-- against your beat maker and SUBMIT sends it; during the listen which entry is on air; VOTE buttons (never your own
-- entry); then the result.
-- Attributes on the bar (tests): Command ("join" | "submit" | "vote:A"), LastAction; ForceShow (Studio only: true keeps
-- the bar shown while idle, so layout tests can measure it next to the HUD and FIRE).
local Players, RS, RunService = game:GetService("Players"), game:GetService("ReplicatedStorage"), game:GetService("RunService")
local M = {}
local MIN = 44

function M.Build(Theme)
	local player = Players.LocalPlayer
	local CY = RS.OK:WaitForChild("Cypher")
	local Cfg = require(RS.OK.Modules.DAWConfig)
	local Check = require(RS.OK.Modules.BriefCheck)
	local DR = require(RS.OK.Modules.DailyRequests)
	local gui = Instance.new("ScreenGui")
	gui.Name = "OK_Cypher"; gui.ResetOnSpawn = false; gui.DisplayOrder = 6
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets -- same insets as the HUD (OK_UI), so the two never overlap
	gui.Parent = player:WaitForChild("PlayerGui")
	local function new(class, props, parent) local i = Instance.new(class); for k, v in pairs(props) do i[k] = v end; i.Parent = parent; return i end
	local bar = new("Frame", { Name = "Bar", BackgroundColor3 = Theme.panel, BackgroundTransparency = 0.05, BorderSizePixel = 0, Visible = false,
		AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.fromOffset(420, 0) }, gui)
	new("UICorner", { CornerRadius = UDim.new(0, 12) }, bar)
	new("UIStroke", { Color = Theme.accent, Thickness = 1.5 }, bar)
	new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }, bar)
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, bar)
	bar:SetAttribute("Command", ""); bar:SetAttribute("LastAction", "")
	local title = new("TextLabel", { Name = "Title", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Font = Theme.fontBlack, TextSize = 15,
		TextColor3 = Theme.accent, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1, Text = "" }, bar)
	local info = new("TextLabel", { Name = "Info", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = Theme.font,
		TextSize = 13, TextColor3 = Theme.text, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, RichText = true, LayoutOrder = 2, Text = "" }, bar)
	local row = new("Frame", { Name = "Buttons", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, MIN), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3 }, bar)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, row)
	local function button(name, text, color, order)
		local b = new("TextButton", { Name = name, Text = text, BackgroundColor3 = color, TextColor3 = Theme.text, Font = Theme.fontBlack, TextSize = 15,
			Size = UDim2.fromOffset(110, MIN), LayoutOrder = order, AutoButtonColor = true, Visible = false }, row)
		new("UICorner", { CornerRadius = UDim.new(0, 8) }, b)
		return b
	end
	local join = button("Join", "JOIN", Theme.accent, 1)
	local submit = button("Submit", "SUBMIT", Theme.accent, 2)
	local votes = {}
	for i = 1, 6 do
		local l = string.char(64 + i)
		votes[l] = button("Vote" .. l, l, Theme.accent2, 10 + i)
		votes[l].Size = UDim2.fromOffset(MIN + 8, MIN)
		votes[l].MouseButton1Click:Connect(function() bar:SetAttribute("Command", "vote:" .. l) end)
	end
	join.MouseButton1Click:Connect(function() bar:SetAttribute("Command", "join") end)
	submit.MouseButton1Click:Connect(function() bar:SetAttribute("Command", "submit") end)
	local voted = {}
	-- why the last SUBMIT / VOTE failed, shown in the bar for a few seconds
	local note, noteUntil = "", 0
	local REASONS = { closed = "That phase is over", notin = "You're not in this cypher", submitted = "Already submitted",
		copy = "Too close to another beat · change more pads", own = "You can't vote for your own entry", again = "You already voted",
		far = "Come into the control room to vote", locked = "That beat uses gear you don't own", invalid = "That beat isn't valid",
		busy = "A cypher is under way · join the next one", full = "This cypher is full", joined = "You're already in" }
	-- phones: while the beat maker fills the screen, a 44 px SUBMIT / timer button sits over its REQUEST chip
	local mini = new("TextButton", { Name = "MiniSubmit", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -72, 0, 10), Size = UDim2.fromOffset(124, MIN),
		BackgroundColor3 = Theme.accent, TextColor3 = Theme.text, Font = Theme.fontBlack, TextSize = 14, Text = "", Visible = false, AutoButtonColor = true, ZIndex = 5 }, gui)
	new("UICorner", { CornerRadius = UDim.new(0, 8) }, mini)

	local function daw() local g = player.PlayerGui:FindFirstChild("OK_DAW"); return g and g:FindFirstChild("DAW") end
	mini.MouseButton1Click:Connect(function()
		if CY:GetAttribute("Phase") == "build" then bar:SetAttribute("Command", "submit")
		else local d = daw(); if d then d:SetAttribute("Command", "close") end end -- to vote, step out of the beat maker
	end)
	local function act(cmd)
		local ok, r
		if cmd == "join" then ok, r = pcall(function() return RS.OK.Remotes.Cypher_Join:InvokeServer() end)
		elseif cmd == "submit" then
			local d = daw()
			ok, r = pcall(function() return RS.OK.Remotes.Cypher_Submit:InvokeServer(d and d:GetAttribute("Pattern"), d and d:GetAttribute("BPM"), d and d:GetAttribute("Swing"), d and d:GetAttribute("Voice")) end)
		elseif cmd:sub(1, 5) == "vote:" then
			local l = cmd:sub(6)
			ok, r = pcall(function() return RS.OK.Remotes.Cypher_Vote:InvokeServer(l) end)
			if ok and type(r) == "table" and r.ok then voted[CY:GetAttribute("Round")] = l end
		end
		local res = (ok and type(r) == "table") and r or { ok = false, reason = "error" }
		bar:SetAttribute("LastAction", res.ok and "ok" or tostring(res.reason))
		if not res.ok and res.reason == "missing" then bar:SetAttribute("LastAction", "missing: " .. table.concat(res.missing or {}, ", ")) end
		if not res.ok then
			note = res.reason == "missing" and ("Not yet: " .. table.concat(res.missing or {}, ", ")) or (REASONS[res.reason] or ("Couldn't do that (" .. tostring(res.reason) .. ")"))
			noteUntil = os.clock() + 5
		end
	end
	bar:GetAttributeChangedSignal("Command"):Connect(function()
		local c = bar:GetAttribute("Command"); if c == "" then return end
		bar:SetAttribute("Command", ""); act(c)
	end)

	-- the phone icon's spot (PhoneUI publishes it; "pills" until the phone gui is up)
	local function iconSpot()
		local ph = player.PlayerGui:FindFirstChild("OK_Phone")
		return ph and ph:GetAttribute("IconSpot") or "pills"
	end
	-- the right edge of the HUD's career pills (else the HUD) in this gui's space, plus the phone icon beside them (8 px
	-- gap, 44 wide) while its spot is "pills"; both guis use CoreUISafeInsets
	local function pillsRight()
		local ui = player.PlayerGui:FindFirstChild("OK_UI")
		for _, n in ipairs({ "Career", "HUD" }) do
			local g = ui and ui:FindFirstChild(n)
			if g and g:IsA("GuiObject") and g.Visible and g.AbsoluteSize.X > 0 then
				local right = g.AbsolutePosition.X + g.AbsoluteSize.X - gui.AbsolutePosition.X
				return n == "Career" and iconSpot() == "pills" and (right + 8 + MIN) or right
			end
		end
		return 342 -- the HUD chip: x 12, 330 wide
	end
	local function viewport() -- the safe area: OK_UI's ForceViewport (tests) or this gui's size
		local ui = player.PlayerGui:FindFirstChild("OK_UI")
		local f = ui and ui:GetAttribute("ForceViewport")
		if typeof(f) == "Vector2" and f.X > 0 and f.Y > 0 then return f end
		return gui.AbsoluteSize.X > 0 and gui.AbsoluteSize or workspace.CurrentCamera.ViewportSize
	end
	local function layout()
		local vp = viewport()
		local left = math.floor(pillsRight() + 8)
		local room = vp.X - 12 - left - (iconSpot() == "corner" and 52 or 0) -- the corner icon keeps 64 px at the top right
		if room >= 240 then -- beside the pills, centred when the screen allows
			local w = math.min(440, room)
			bar.AnchorPoint = Vector2.new(0, 0)
			bar.Position = UDim2.fromOffset(math.max(left, math.floor((vp.X - w) / 2)), 10)
			bar.Size = UDim2.fromOffset(w, 0)
		else -- too narrow beside them: under the (stacked) pills, right-aligned, clear of the daily / tour pill (x <= 324)
			bar.AnchorPoint = Vector2.new(1, 0); bar.Position = UDim2.fromOffset(vp.X - 12, 74)
			bar.Size = UDim2.fromOffset(math.min(440, math.max(240, vp.X - 12 - 336)), 0)
		end
	end
	local testShow = RunService:IsStudio()
	local spotConn = nil -- the bar re-places itself the moment the phone icon's spot changes (PhoneUI is built after this)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt; if acc < 0.2 then return end; acc = 0
		if not spotConn then
			local ph = player.PlayerGui:FindFirstChild("OK_Phone")
			if ph then spotConn = ph:GetAttributeChangedSignal("IconSpot"):Connect(layout) end
		end
		layout()
		local phase = CY:GetAttribute("Phase") or "idle"
		local d = daw()
		local compactOpen = d and d.Visible and d:GetAttribute("Compact") == true
		local hidden = phase == "idle" or compactOpen
		bar.Visible = not hidden or (testShow and bar:GetAttribute("ForceShow") == true)
		local round = CY:GetAttribute("Round")
		local left0 = math.max(0, math.ceil((CY:GetAttribute("EndsAt") or 0) - workspace:GetServerTimeNow()))
		local inRound = player:GetAttribute("CypherIn") == round
		mini.Visible = compactOpen and phase ~= "idle" and (inRound or phase == "vote")
		if mini.Visible then
			local clock = string.format("%d:%02d", left0 // 60, left0 % 60)
			if phase == "build" and inRound and player:GetAttribute("CypherSubmitted") ~= round then mini.Text = "SUBMIT · " .. clock
			elseif phase == "vote" then mini.Text = "VOTE · " .. clock
			else mini.Text = "🎤 " .. string.upper(phase) .. " " .. clock end
		end
		if not bar.Visible then return end
		local left = math.max(0, math.ceil((CY:GetAttribute("EndsAt") or 0) - workspace:GetServerTimeNow()))
		local mmss = string.format("%d:%02d", left // 60, left % 60)
		local mine = player:GetAttribute("CypherIn") == round
		local sent = player:GetAttribute("CypherSubmitted") == round
		local myLetter = player.PlayerGui:GetAttribute("CypherLetter") -- only you can see your own letter
		join.Visible = phase == "lobby" and not mine
		submit.Visible = phase == "build" and mine and not sent
		for l, b in pairs(votes) do b.Visible = false end
		if phase == "lobby" then
			title.Text = "🎤 CYPHER · STARTS IN " .. mmss
			info.Text = string.format("%d producer%s in · needs %d · everyone builds to one brief, then the room picks", CY:GetAttribute("Entrants") or 0,
				(CY:GetAttribute("Entrants") or 0) == 1 and "" or "s", 2)
		elseif phase == "build" then
			title.Text = "🎤 CYPHER · BUILD · " .. mmss
			local t = DR.Templates[CY:GetAttribute("Template") or 1]
			local brief = { asks = t.asks, bonus = t.bonus }
			local lines = {}
			if d then
				local res = Check.Check(Cfg, brief, d:GetAttribute("Pattern"), d:GetAttribute("BPM"), d:GetAttribute("Swing"))
				for _, a in ipairs(res.asks) do table.insert(lines, (a.ok and '<font color="#00FF8C">✓</font> ' or "○ ") .. a.text) end
				local ch = Check.Changed(d:GetAttribute("Pattern"), Check.References(Cfg))
				table.insert(lines, (ch >= Check.MinChanged and '<font color="#00FF8C">✓</font> ' or "○ ") .. string.format("make it yours %d/%d", math.min(ch, Check.MinChanged), Check.MinChanged))
			else
				for _, a in ipairs(t.asks) do table.insert(lines, "○ " .. Check.Text(a)) end
			end
			info.Text = (mine and (sent and "Submitted · waiting for the others" or "Make it in a beat maker, then SUBMIT") or "Producers are building")
				.. "\n" .. table.concat(lines, "   ") .. string.format("\n%d/%d submitted", CY:GetAttribute("Submitted") or 0, CY:GetAttribute("Entrants") or 0)
		elseif phase == "listen" then
			title.Text = "🎤 CYPHER · LISTEN"
			local playing = CY:GetAttribute("Playing") or ""
			info.Text = (playing ~= "" and ("Now: ENTRY " .. playing) or "Entries coming up") .. (myLetter and ("   ·   yours is " .. myLetter) or "")
				.. ((CY:GetAttribute("Mode") == "h2h") and "\nHead-to-head: most stars wins" or "\nVoting opens after the last entry")
		elseif phase == "vote" then
			title.Text = "🎤 CYPHER · VOTE · " .. mmss
			info.Text = voted[round] and ("You voted " .. voted[round]) or ("Pick your favourite" .. (myLetter and (" (not your own, " .. myLetter .. ")") or ""))
			if not voted[round] then
				for l in string.gmatch(CY:GetAttribute("Letters") or "", "[^,]+") do if votes[l] and l ~= myLetter then votes[l].Visible = true end end
			end
		elseif phase == "reveal" then
			title.Text = "🎤 CYPHER"
			info.Text = (CY:GetAttribute("Result") or "") .. ((CY:GetAttribute("Reveal") or "") ~= "" and ("\n" .. (CY:GetAttribute("Reveal"):gsub(",", "   "))) or "")
		end
		row.Visible = join.Visible or submit.Visible or phase == "vote"
		if os.clock() < noteUntil and note ~= "" then info.Text = info.Text .. '\n<font color="#FF8080">' .. note .. "</font>" end
	end)
	return { Bar = bar, Gui = gui }
end

return M
