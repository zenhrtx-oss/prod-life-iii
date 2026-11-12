-- Client, during play (Wave 3 Task 5d), after t90a left LIL NAV X's navx_placement open: the walk-in card's portrait.
-- Card.Portrait (the 44 px square, scaled down with the header row on short screens) holds exactly one ViewportFrame,
-- "View" (today the card draws a brown Face square on his Shirt colour there), whose Figure is his (VisitorId navx: built
-- from the payload's id) with 8-16 parts, a Head and a WedgePart Nose, and whose CurrentCamera is its own child Camera at
-- VisitorLooks.Frame's fov, from and at. At the real viewport and forced to the safe area of an 844x390 and a 667x375
-- phone (the screen minus this gui's real insets, as t47b): the portrait is shown, at least 36 px square, inside the card
-- and clear of the name and the tag; the View fills it; and his head, projected through the portrait's own camera, is
-- inside the frame and at least 45% of its height (16 px or more at 36 px: a face, not a block). WALK AWAY closes the card
-- and his copy goes with it (no View left). Everything this file changed is set back (the forced size).
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui", 10)
local wg = pg:WaitForChild("OK_WalkIn", 10); assert(wg, "no OK_WalkIn gui (WalkInUI.Build did not run?)")
local daw = pg:WaitForChild("OK_DAW", 10):WaitForChild("DAW", 10); assert(daw, "no beat maker gui")
local CARD, WHO = "navx_placement", "navx"
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function rel(g) local p, s = g.AbsolutePosition - wg.AbsolutePosition, g.AbsoluteSize; return { x0 = p.X, y0 = p.Y, x1 = p.X + s.X, y1 = p.Y + s.Y } end
local function within(a, b) return a.x0 >= b.x0 - 1 and a.y0 >= b.y0 - 1 and a.x1 <= b.x1 + 1 and a.y1 <= b.y1 + 1 end
local function overlaps(a, b) return a.x0 < b.x1 - 1 and b.x0 < a.x1 - 1 and a.y0 < b.y1 - 1 and b.y0 < a.y1 - 1 end
local function fmt(r) return string.format("(%d,%d)-(%d,%d)", r.x0, r.y0, r.x1, r.y1) end
wg:SetAttribute("ForceViewport", nil)
if daw.Visible then daw:SetAttribute("Command", "close"); task.wait(0.4) end
local out = {}

-- the head's eight corners through the portrait's camera (a square frame): its share of the frame's height, and its
-- extent in -1..1 units of the frame
local function headShare(vf)
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
	assert(waitFor(function() return wg:GetAttribute("Open") == true and wg:GetAttribute("Card") == CARD end, 20), "the card did not open within 20 s (Card '"
		.. tostring(wg:GetAttribute("Card")) .. "', Deferred " .. tostring(wg:GetAttribute("Deferred")) .. ")")
	task.wait(0.3) -- let it render once so the rects are current
	local card = wg.Root.Card
	local portrait = card:FindFirstChild("Portrait")
	assert(portrait, "the card has no Portrait square")
	local view = portrait:FindFirstChild("View")
	assert(view and view:IsA("ViewportFrame"), "Card.Portrait holds no ViewportFrame 'View' (today's card draws a brown Face square on his Shirt colour there)")
	local n = 0
	for _, d in ipairs(portrait:GetChildren()) do if d:IsA("ViewportFrame") then n += 1 end end
	assert(n == 1, "Card.Portrait holds " .. n .. " ViewportFrames (one copy per card)")
	-- whose figure, and its camera (the recipe module is in the place once the View is)
	local Looks = require(RS.OK.Modules.VisitorLooks)
	local fig = view:FindFirstChild("Figure")
	assert(fig and fig:GetAttribute("VisitorId") == WHO, "the portrait shows " .. tostring(fig and fig:GetAttribute("VisitorId")) .. ", want " .. WHO .. " (the payload's visitor.id)")
	local parts = 0
	for _, d in ipairs(fig:GetDescendants()) do if d:IsA("BasePart") then parts += 1 end end
	assert(parts >= 8 and parts <= 16, "the portrait's figure has " .. parts .. " parts (want 8..16)")
	assert(fig:FindFirstChild("Head") and fig:FindFirstChild("Nose") and fig.Nose:IsA("WedgePart"), "the portrait's figure has no Head or no WedgePart Nose")
	local fr = Looks.Frame(Looks.For(WHO))
	local c = view.CurrentCamera
	assert(c and c:IsA("Camera") and c.Parent == view, "the View's CurrentCamera is not its own child Camera")
	assert(math.abs(c.FieldOfView - fr.fov) < 1e-3, "the portrait camera's fov is " .. c.FieldOfView .. ", want " .. fr.fov)
	local want = CFrame.lookAt(Vector3.new(table.unpack(fr.from)), Vector3.new(table.unpack(fr.at)))
	assert((c.CFrame.Position - want.Position).Magnitude < 1e-3 and c.CFrame.LookVector:Dot(want.LookVector) > 0.9999, "the portrait camera is not at VisitorLooks.Frame's from / at")
	table.insert(out, string.format("Portrait.View: %s's figure (%d parts, wedge nose), its own camera at fov %g", WHO, parts, c.FieldOfView))

	local function check(where, vp)
		task.wait(0.4)
		local cr, pr, vr = rel(card), rel(portrait), rel(view)
		assert(portrait.Visible and view.Visible, where .. ": the portrait is hidden")
		assert(portrait.AbsoluteSize.X >= 35.5 and portrait.AbsoluteSize.Y >= 35.5, where .. ": the portrait is " .. portrait.AbsoluteSize.X .. "x" .. portrait.AbsoluteSize.Y .. " px (want 36 or more)")
		assert(math.abs(vr.x0 - pr.x0) <= 1 and math.abs(vr.y0 - pr.y0) <= 1 and math.abs(vr.x1 - pr.x1) <= 1 and math.abs(vr.y1 - pr.y1) <= 1, where .. ": the View " .. fmt(vr) .. " does not fill the portrait " .. fmt(pr))
		assert(within(pr, cr), where .. ": the portrait " .. fmt(pr) .. " is outside the card " .. fmt(cr))
		assert(cr.x0 >= 0 and cr.y0 >= 0 and cr.x1 <= vp.X and cr.y1 <= vp.Y, where .. ": the card " .. fmt(cr) .. " is outside (0,0)-(" .. vp.X .. "," .. vp.Y .. ")")
		for _, name in ipairs({ "Name", "Tag" }) do
			local l = card:FindFirstChild(name)
			assert(l and not overlaps(pr, rel(l)), where .. ": the portrait " .. fmt(pr) .. " overlaps the " .. name .. " " .. (l and fmt(rel(l)) or "(missing)"))
		end
		local share, x0, x1, y0, y1 = headShare(view)
		assert(x0 >= -1 and x1 <= 1 and y0 >= -1 and y1 <= 1, string.format("%s: his head leaves the portrait (x %.2f..%.2f, y %.2f..%.2f)", where, x0, x1, y0, y1))
		local px = share * view.AbsoluteSize.Y
		assert(share >= 0.45 and px >= 16, string.format("%s: his head is %.0f%% of the portrait (%.1f px of %d): want 45%% and 16 px or more", where, share * 100, px, view.AbsoluteSize.Y))
		table.insert(out, string.format("%s: portrait %dx%d inside the card %s, clear of the name and tag; his head %.0f%% (%.1f px)",
			where, portrait.AbsoluteSize.X, portrait.AbsoluteSize.Y, fmt(cr), share * 100, px))
	end
	check("real " .. wg.AbsoluteSize.X .. "x" .. wg.AbsoluteSize.Y, wg.AbsoluteSize)
	local d = cam.ViewportSize - wg.AbsoluteSize
	local inset = Vector2.new(math.max(0, d.X), math.max(0, d.Y))
	for _, screen in ipairs({ Vector2.new(844, 390), Vector2.new(667, 375) }) do
		local vp = screen - inset
		wg:SetAttribute("ForceViewport", vp)
		check(vp.X .. "x" .. vp.Y .. " (" .. screen.X .. "x" .. screen.Y .. " less " .. inset.X .. "x" .. inset.Y .. ")", vp)
	end
	wg:SetAttribute("ForceViewport", nil)
	wg:SetAttribute("Command", "walkaway")
	assert(waitFor(function() return wg:GetAttribute("Open") == false end, 4), "WALK AWAY did not close the card")
	assert(portrait:FindFirstChild("View") == nil, "his portrait copy is still there after the card closed")
	table.insert(out, "WALK AWAY closed it; his copy went with it")
end

local okRun, err = pcall(run)
wg:SetAttribute("ForceViewport", nil)
if wg:GetAttribute("Open") == true then wg:SetAttribute("Command", "walkaway") end
if not okRun then error(err, 0) end
return "T90B PLAY OK\n" .. table.concat(out, "\n")
