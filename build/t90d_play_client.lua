-- Client, during play (Wave 3 Task 5d), after t90c popped dm_navx then news_spedup with Quiet off: the phone card's
-- portrait. The DM opens by itself: a person's card, so Card.Portrait is shown at the header row's left, 44 px square,
-- holding exactly one ViewportFrame "View" (today the phone card shows no face) whose Figure is LIL NAV X's (VisitorId
-- navx: from the payload's sender.id) with 8-16 parts and a Head, and whose CurrentCamera is its own child Camera; the
-- app label and the sender's name start right of it, clear of it; his head, through the portrait's camera, is inside
-- the frame and at least 45% of its height. Checked at the real viewport and forced to the safe area of an 844x390 and a
-- 667x375 phone (OK_UI forced too, as t57b), every choice and DISMISS still 44 px. DISMISS closes it and the copy goes
-- (no View); news_spedup opens next: from NEWS PING, a phone-only sender, so no face (Portrait hidden, no View) and the
-- app label back at the card's 12 px padding. Its result shows inline and OK closes it. The forced sizes are set back.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui", 10)
local gui = pg:WaitForChild("OK_Phone", 10); assert(gui, "no OK_Phone gui (PhoneUI.Build did not run?)")
local ui = pg:WaitForChild("OK_UI", 10)
local daw = pg:WaitForChild("OK_DAW", 10):WaitForChild("DAW", 10); assert(daw, "no beat maker gui")
local PAD = 12 -- PhoneUI's card padding
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function rel(g) local p, s = g.AbsolutePosition - gui.AbsolutePosition, g.AbsoluteSize; return { x0 = p.X, y0 = p.Y, x1 = p.X + s.X, y1 = p.Y + s.Y } end
local function within(a, b) return a.x0 >= b.x0 - 1 and a.y0 >= b.y0 - 1 and a.x1 <= b.x1 + 1 and a.y1 <= b.y1 + 1 end
local function overlaps(a, b) return a.x0 < b.x1 - 1 and b.x0 < a.x1 - 1 and a.y0 < b.y1 - 1 and b.y0 < a.y1 - 1 end
local function fmt(r) return string.format("(%d,%d)-(%d,%d)", r.x0, r.y0, r.x1, r.y1) end
gui:SetAttribute("ForceViewport", nil); ui:SetAttribute("ForceViewport", nil)
if daw.Visible then daw:SetAttribute("Command", "close"); task.wait(0.4) end
local out = {}

local function headShare(vf) -- as t90b: the head's share of the portrait's height, and its extent in -1..1
	local c, head = vf.CurrentCamera, vf.Figure:FindFirstChild("Head")
	local t = math.tan(math.rad(c.FieldOfView / 2))
	local x0, x1, y0, y1 = math.huge, -math.huge, math.huge, -math.huge
	for _, sx in ipairs({ -1, 1 }) do for _, sy in ipairs({ -1, 1 }) do for _, sz in ipairs({ -1, 1 }) do
		local lp = c.CFrame:PointToObjectSpace(head.CFrame * Vector3.new(sx * head.Size.X / 2, sy * head.Size.Y / 2, sz * head.Size.Z / 2))
		local x, y = lp.X / (-lp.Z * t), lp.Y / (-lp.Z * t)
		x0, x1, y0, y1 = math.min(x0, x), math.max(x1, x), math.min(y0, y), math.max(y1, y)
	end end end
	return (y1 - y0) / 2, x0, x1, y0, y1
end

local function run()
	assert(waitFor(function() return gui:GetAttribute("Open") == true and gui:GetAttribute("Card") == "dm_navx" end, 6), "dm_navx did not open within 6 s (Card '"
		.. tostring(gui:GetAttribute("Card")) .. "', Pending " .. tostring(gui:GetAttribute("Pending")) .. ", Deferred " .. tostring(gui:GetAttribute("Deferred")) .. ")")
	task.wait(0.3)
	local card = gui.Root.Card
	local header, sender, portrait = card:FindFirstChild("Header"), card:FindFirstChild("Sender"), card:FindFirstChild("Portrait")
	assert(header and sender, "the phone card has no Header or Sender")
	assert(portrait, "the DM card has no Portrait (today the phone card shows no face)")
	local view = portrait:FindFirstChild("View")
	assert(portrait.Visible and view and view:IsA("ViewportFrame"), "the DM card's Portrait is hidden or holds no ViewportFrame 'View'")
	local n = 0
	for _, d in ipairs(portrait:GetChildren()) do if d:IsA("ViewportFrame") then n += 1 end end
	assert(n == 1, "the DM card's Portrait holds " .. n .. " ViewportFrames (one copy per card)")
	local fig = view:FindFirstChild("Figure")
	assert(fig and fig:GetAttribute("VisitorId") == "navx", "the DM's portrait shows " .. tostring(fig and fig:GetAttribute("VisitorId")) .. ", want navx (the payload's sender.id)")
	local parts = 0
	for _, d in ipairs(fig:GetDescendants()) do if d:IsA("BasePart") then parts += 1 end end
	assert(parts >= 8 and parts <= 16 and fig:FindFirstChild("Head"), "the DM portrait's figure has " .. parts .. " parts, or no Head")
	assert(view.CurrentCamera and view.CurrentCamera.Parent == view, "the View's CurrentCamera is not its own child Camera")
	table.insert(out, "dm_navx: Portrait.View shows navx (" .. parts .. " parts), its own camera")

	local function check(where, vp)
		task.wait(0.6)
		local cr, pr, hr, sr = rel(card), rel(portrait), rel(header), rel(sender)
		assert(cr.x0 >= 0 and cr.y0 >= 0 and cr.x1 <= vp.X and cr.y1 <= vp.Y, where .. ": card " .. fmt(cr) .. " outside (0,0)-(" .. vp.X .. "," .. vp.Y .. ")")
		assert(portrait.Visible and portrait.AbsoluteSize.X >= 43.5 and portrait.AbsoluteSize.Y >= 43.5, where .. ": the portrait is hidden or under 44 px (" .. portrait.AbsoluteSize.X .. ")")
		assert(within(pr, cr), where .. ": the portrait " .. fmt(pr) .. " is outside the card " .. fmt(cr))
		assert(math.abs(pr.x0 - (cr.x0 + PAD)) <= 1 and math.abs(pr.y0 - (cr.y0 + PAD)) <= 1, where .. ": the portrait " .. fmt(pr) .. " is not at the header row's left " .. (cr.x0 + PAD) .. "," .. (cr.y0 + PAD))
		assert(hr.x0 >= pr.x1 + 4 and sr.x0 >= pr.x1 + 4 and not overlaps(pr, hr) and not overlaps(pr, sr),
			where .. ": the app label " .. fmt(hr) .. " or the name " .. fmt(sr) .. " is not right of the portrait " .. fmt(pr))
		assert(hr.x1 <= cr.x1 and sr.x1 <= cr.x1 - PAD + 1, where .. ": the app label " .. fmt(hr) .. " or the name " .. fmt(sr) .. " runs past the card " .. fmt(cr))
		for i = 1, gui:GetAttribute("Choices") do
			local b = card:FindFirstChild("Choice" .. i, true)
			assert(b and b.Visible and b.AbsoluteSize.Y >= 44, where .. ": Choice" .. i .. " missing, hidden or under 44 px")
		end
		local d = card:FindFirstChild("Dismiss", true)
		assert(d and d.Visible and d.AbsoluteSize.Y >= 44, where .. ": DISMISS missing, hidden or under 44 px")
		local share, x0, x1, y0, y1 = headShare(view)
		assert(x0 >= -1 and x1 <= 1 and y0 >= -1 and y1 <= 1, string.format("%s: his head leaves the portrait (x %.2f..%.2f, y %.2f..%.2f)", where, x0, x1, y0, y1))
		assert(share >= 0.45, string.format("%s: his head is %.0f%% of the portrait (want 45%% or more)", where, share * 100))
		table.insert(out, string.format("%s: portrait %s at the row's left, label %s and name %s beside it; card %s; his head %.0f%%", where, fmt(pr), fmt(hr), fmt(sr), fmt(cr), share * 100))
	end
	check("real " .. gui.AbsoluteSize.X .. "x" .. gui.AbsoluteSize.Y, gui.AbsoluteSize)
	local inset = cam.ViewportSize - gui.AbsoluteSize
	inset = Vector2.new(math.max(0, inset.X), math.max(0, inset.Y))
	for _, screen in ipairs({ Vector2.new(844, 390), Vector2.new(667, 375) }) do
		local vp = screen - inset
		gui:SetAttribute("ForceViewport", vp); ui:SetAttribute("ForceViewport", vp)
		check(vp.X .. "x" .. vp.Y .. " (" .. screen.X .. "x" .. screen.Y .. " less " .. inset.X .. "x" .. inset.Y .. ")", vp)
	end
	gui:SetAttribute("ForceViewport", nil); ui:SetAttribute("ForceViewport", nil)

	-- DISMISS: the copy goes; the NEWS from a phone-only sender opens next, with no face
	gui:SetAttribute("Command", "dismiss")
	assert(waitFor(function() return gui:GetAttribute("Card") ~= "dm_navx" end, 4), "DISMISS did not close dm_navx")
	assert(portrait:FindFirstChild("View") == nil, "the DM's portrait copy is still there after its card closed")
	assert(waitFor(function() return gui:GetAttribute("Open") == true and gui:GetAttribute("Card") == "news_spedup" end, 4), "news_spedup did not open after the DM closed")
	task.wait(0.3)
	assert(not portrait.Visible and portrait:FindFirstChild("View") == nil, "news_spedup (NEWS PING, a phone-only sender) shows a face")
	local cr, hr = rel(card), rel(header)
	assert(math.abs(hr.x0 - (cr.x0 + PAD)) <= 1, "news_spedup's app label starts at " .. hr.x0 .. ", want the card's padding " .. (cr.x0 + PAD))
	table.insert(out, "DISMISS: the copy went; news_spedup (NEWS PING): no face, the label at the card's padding")
	assert(waitFor(function() return gui:GetAttribute("ResultKey") ~= "" end, 5), "news_spedup's result did not show")
	gui:SetAttribute("Command", "ok")
	assert(waitFor(function() return gui:GetAttribute("Open") == false end, 4), "OK did not close news_spedup")
	table.insert(out, "its result showed; OK closed it")
end

local okRun, err = pcall(run)
gui:SetAttribute("ForceViewport", nil); ui:SetAttribute("ForceViewport", nil)
if gui:GetAttribute("Open") == true then gui:SetAttribute("Command", "dismiss"); task.wait(0.3) end
if gui:GetAttribute("Open") == true then gui:SetAttribute("Command", "ok") end
if not okRun then error(err, 0) end
return "T90D PLAY OK\n" .. table.concat(out, "\n")
