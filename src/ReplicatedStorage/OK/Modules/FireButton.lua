-- FIRE button for listeners: its own ScreenGui above the beat maker, top-right. Shows while someone else's beat airs on
-- the monitors, you're within Config.Fire.Range of a speaker, the first bar has played, and you haven't sent one for
-- this airing. Hidden while your own beat maker fills a phone screen. Attributes (tests): Command ("fire"), LastFire,
-- Top (FIRE's top as an offset inside OK_Fire: 60, or 8 px under the cypher bar while it shows and under the phone icon
-- while it sits in its corner spot (OK_Phone's IconSpot "corner": the top right, this column), never above absolute y 60).
local Players, RS, RunService = game:GetService("Players"), game:GetService("ReplicatedStorage"), game:GetService("RunService")
local M = {}

function M.Build(Theme)
	local player = Players.LocalPlayer
	local Config = require(RS.OK.Config)
	local DAWCfg = require(RS.OK.Modules.DAWConfig)
	local NP = RS.OK:WaitForChild("NowPlaying")
	local gui = Instance.new("ScreenGui")
	gui.Name = "OK_Fire"; gui.ResetOnSpawn = false; gui.DisplayOrder = 7; gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	gui.Parent = player:WaitForChild("PlayerGui")
	local btn = Instance.new("TextButton")
	btn.Name = "FireButton"; btn.AnchorPoint = Vector2.new(1, 0); btn.Position = UDim2.new(1, -16, 0, 60); btn.Size = UDim2.fromOffset(136, 56)
	btn.BackgroundColor3 = Color3.fromRGB(255, 90, 40); btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.Font = Theme.fontBlack; btn.TextSize = 20
	btn.Text = "🔥 FIRE"; btn.Visible = false; btn.AutoButtonColor = true
	btn:SetAttribute("Command", ""); btn:SetAttribute("LastFire", "")
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = btn
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255, 200, 120); s.Thickness = 2; s.Parent = btn
	btn.Parent = gui
	local sent, maxed = {}, {} -- maxed[ownerId] = UTC day the listener->producer daily limit was reached
	local function day() return os.date("!%Y%m%d", math.floor(workspace:GetServerTimeNow())) end
	local function speakerDist()
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local st = workspace:FindFirstChild("OKStudio"); local cr = st and st:FindFirstChild("ControlRoom")
		if not (root and cr) then return math.huge end
		local best = math.huge
		for _, n in ipairs({ "Speaker_L", "Speaker_R" }) do local sp = cr:FindFirstChild(n); if sp then best = math.min(best, (sp.Position - root.Position).Magnitude) end end
		return best
	end
	local function dawCoversScreen()
		local d = player.PlayerGui:FindFirstChild("OK_DAW"); local w = d and d:FindFirstChild("DAW")
		return w and w.Visible and w:GetAttribute("Compact") == true
	end
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt; if acc < 0.15 then return end; acc = 0
		local tok = NP:GetAttribute("Token")
		local bar = DAWCfg.Steps * 60 / (NP:GetAttribute("BPM") or 120) / 4
		local can = NP:GetAttribute("Active") == true and NP:GetAttribute("OwnerId") ~= player.UserId and NP:GetAttribute("System") ~= true
			and workspace:GetServerTimeNow() - (NP:GetAttribute("StartAt") or 0) >= bar
			and speakerDist() <= (Config.Fire and Config.Fire.Range or 45) and not dawCoversScreen()
		btn.Visible = can
		-- while the cypher bar shows, or the phone icon sits in its corner spot (OK_Phone's IconSpot "corner": the top right,
		-- inside this column; OK_Phone draws over this gui), sit 8 px under the lower of them on screen, never above absolute
		-- y 60. Their guis (OK_Cypher, OK_Phone) use other insets than this one, so all are converted the same way: absolute
		-- y minus this gui's own AbsolutePosition.Y = offset in OK_Fire
		local cy = player.PlayerGui:FindFirstChild("OK_Cypher"); local cbar = cy and cy:FindFirstChild("Bar")
		local ph = player.PlayerGui:FindFirstChild("OK_Phone")
		local picon = ph and ph:GetAttribute("IconSpot") == "corner" and ph:FindFirstChild("Icon", true) or nil
		local under = nil -- the lowest bottom edge + 8 among what shows in this column
		if cbar and cbar.Visible then under = cbar.AbsolutePosition.Y + cbar.AbsoluteSize.Y + 8 end
		if picon and picon:IsA("GuiObject") and picon.Visible then under = math.max(under or 0, picon.AbsolutePosition.Y + picon.AbsoluteSize.Y + 8) end
		local top = under and (math.max(60, under) - gui.AbsolutePosition.Y) or 60
		btn.Position = UDim2.new(1, -16, 0, top)
		btn:SetAttribute("Top", top)
		local n = NP:GetAttribute("Fires") or 0
		if maxed[NP:GetAttribute("OwnerId")] == day() then btn.Text = "🔥 MAXED TODAY"; btn.AutoButtonColor = false; btn.BackgroundColor3 = Theme.line
		elseif sent[tok] then btn.Text = "🔥 SENT" .. (n > 0 and (" · " .. n) or ""); btn.AutoButtonColor = false; btn.BackgroundColor3 = Theme.line
		else btn.Text = "🔥 FIRE" .. (n > 0 and (" · " .. n) or ""); btn.AutoButtonColor = true; btn.BackgroundColor3 = Color3.fromRGB(255, 90, 40) end
	end)
	local function send()
		local tok = NP:GetAttribute("Token")
		if sent[tok] then btn:SetAttribute("LastFire", "again"); return end
		local ok, res = pcall(function() return RS.OK.Remotes.Fire_Send:InvokeServer(tok) end)
		local r = (ok and type(res) == "table") and res or { ok = false, reason = "error" }
		if r.ok or r.reason == "again" then sent[tok] = true end
		if r.reason == "pair" then maxed[NP:GetAttribute("OwnerId")] = day() end
		btn:SetAttribute("LastFire", r.ok and "ok" or tostring(r.reason))
	end
	btn.MouseButton1Click:Connect(function() btn:SetAttribute("Command", "fire") end)
	btn:GetAttributeChangedSignal("Command"):Connect(function()
		if btn:GetAttribute("Command") ~= "fire" then return end
		btn:SetAttribute("Command", "")
		send()
	end)
	return { Button = btn, Gui = gui }
end

return M
