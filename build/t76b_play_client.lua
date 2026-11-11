-- Client, during play (Wave 3 Task 2 and its fix round 1; design 4.4 and 4.5), after t76a's staging: the first-ever visit
-- (tier_known, planted and walked in by the real first-ever timer with the tour not done, hint followers) and the phone
-- DM two_sessions with hit unseen (the hinted DM players get at visit 10), popped a second after he arrived, so the
-- client holds it behind the walk-in card. The player attributes _T76Reset and _T76Arrived are t76a's server times of
-- the reset and the arrival.
-- (1) The card is on screen within 35 s of the reset: arrival - reset <= 35 s on the server's clock, the card Open here
-- with Card tier_known, and when it opens while this file watches, the open itself within 35 s of the reset.
-- (2) Its hint line (Hint, found under the card; Mark "i", Label the Config.Hints text for followers), shown, at the
-- real viewport and forced to the safe area of an 844x390 and a 667x375 phone (the screen minus this gui's real insets,
-- as t47b): a card with no choices keeps the hint as its last footer line, so it is the card's child, under WALK
-- AWAY's row and the Aura footer; Label.TextFits, the line inside the card, the footer still fits, WALK AWAY shown,
-- 44 px or more and inside the card, and the card inside (0, 0)-vp. WALK AWAY closes it.
-- (3) The DM, with OK_UI forced to 667x375, 771x390 and 844x390 less the insets (771x332 and 844x332 in Studio, as t66b):
-- the hint (OK_Phone.Root.Card.Scroll.Hint, the hit text) is the last item in the scrolling middle, its top at or under
-- Choice2's bottom (the controller's ruling: a hint never pushes a choice under the fold); with CanvasPosition (0, 0)
-- both choices are fully visible at 771 and 844, and at 667 Choice1 is, with Choice2's top in view (the middle scrolls
-- there for every DM, hint or none: t66b's rule); scrolled to its end the hint is fully in view and its Label fits;
-- Choices 2, each choice and DISMISS 44 px or more, DISMISS and the card inside the box. DISMISS closes it.
-- The two cards are checked in the order they open: a beat maker left open by an earlier file holds both, and once it
-- closes either may open first (each holds the other). Everything this file changed is set back: the forced sizes,
-- no card left open, and the tour t76a left unfinished is skipped (Tour_Skip, what the SKIP button sends).
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character; local hum = char:WaitForChild("Humanoid", 5); local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui", 10)
local wg = pg:WaitForChild("OK_WalkIn", 10); assert(wg, "no OK_WalkIn gui (WalkInUI.Build did not run?)")
local phone = pg:WaitForChild("OK_Phone", 10); assert(phone, "no OK_Phone gui (PhoneUI.Build did not run?)")
local ui = pg:WaitForChild("OK_UI", 10); assert(ui, "no OK_UI")
local daw = pg:WaitForChild("OK_DAW", 10):WaitForChild("DAW", 10); assert(daw, "no beat maker gui")
local Config = require(RS.OK.Config)
local STAGE, DM = "tier_known", "two_sessions"
local function hintText(term) for _, h in ipairs(Config.Hints) do if h.term == term then return h.text end end; return nil end
local FOLLOWERS, HIT = hintText("followers"), hintText("hit")
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
-- rects in a gui's own space: (0, 0) is its top-left, so a forced viewport's box is (0, 0)-vp
local function rel(g, base) local p, s = g.AbsolutePosition - base.AbsolutePosition, g.AbsoluteSize; return { x0 = p.X, y0 = p.Y, x1 = p.X + s.X, y1 = p.Y + s.Y } end
local function within(a, b) return a.x0 >= b.x0 and a.y0 >= b.y0 and a.x1 <= b.x1 and a.y1 <= b.y1 end
local function fmt(r) return string.format("(%d,%d)-(%d,%d)", r.x0, r.y0, r.x1, r.y1) end
local function inset(g) local d = cam.ViewportSize - g.AbsoluteSize; return Vector2.new(math.max(0, d.X), math.max(0, d.Y)) end
-- a card's hint line, found under it: Hint with Mark ("i") and Label
local function hintOf(card, where)
	local h = card:FindFirstChild("Hint", true)
	local l, i = h and h:FindFirstChild("Label"), h and h:FindFirstChild("Mark")
	assert(h and l and i and l:IsA("TextLabel") and i:IsA("TextLabel"), where .. ": no Hint with Mark and Label under " .. card:GetFullName()
		.. " (before the Task 2 sync of the card modules: the expected red)")
	return h, l, i
end
-- never inherit a forced size or an open beat maker from an earlier failed run
wg:SetAttribute("ForceViewport", nil); ui:SetAttribute("ForceViewport", nil); phone:SetAttribute("ForceViewport", nil)
local resetAt, arrivedAt = player:GetAttribute("_T76Reset"), player:GetAttribute("_T76Arrived")
local openAtStart = wg:GetAttribute("Open") == true
if daw.Visible then daw:SetAttribute("Command", "close"); task.wait(0.4) end
if hum.Sit then hum.Sit = false; task.wait(0.4) end
local out = {}

-- the walk-in card: the first-ever visit, its hint line at three sizes, then WALK AWAY
local function walkIn(first)
	local card = wg.Root.Card
	assert(waitFor(function() return wg:GetAttribute("Open") == true end, first and math.max(2, 36 - (workspace:GetServerTimeNow() - resetAt)) or 10),
		"the walk-in card did not open (Open " .. tostring(wg:GetAttribute("Open")) .. ", Deferred " .. tostring(wg:GetAttribute("Deferred"))
		.. ", Card '" .. tostring(wg:GetAttribute("Card")) .. "')")
	local seen = workspace:GetServerTimeNow() - resetAt
	assert(wg:GetAttribute("Card") == STAGE and card.Visible, "the open card is '" .. tostring(wg:GetAttribute("Card")) .. "', want t76a's " .. STAGE)
	if first and not openAtStart then assert(seen <= 35, string.format("the card opened here %.1f s after the reset, want 35 or less", seen)) end
	table.insert(out, string.format("1 %s on screen: arrived %.1f s after the reset (server clock), open here at %.1f s%s", STAGE, arrivedAt - resetAt,
		seen, openAtStart and " (already open when this file started)" or ""))
	local h, l, i = hintOf(card, "walk-in")
	local footer, walk = card:FindFirstChild("Footer"), card:FindFirstChild("WalkAway")
	assert(footer and walk, "walk-in: no Footer or WalkAway on the card")
	local function fits(where, vp)
		task.wait(0.3) -- one render, so TextFits and the rects are current
		local cr = rel(card, wg)
		assert(cr.x0 >= 0 and cr.y0 >= 0 and cr.x1 <= vp.X and cr.y1 <= vp.Y, where .. ": the card " .. fmt(cr) .. " is outside (0,0)-(" .. vp.X .. "," .. vp.Y .. ")")
		assert(h.Visible and l.Visible and i.Visible, where .. ": the hint line is hidden")
		assert(h.Parent == card, where .. ": the hint sits in " .. h.Parent.Name .. ": a card with no choices should keep it as its footer line")
		assert(l.Text == FOLLOWERS and i.Text == "i", where .. ": the hint reads '" .. l.Text .. "' with mark '" .. i.Text .. "', want '" .. tostring(FOLLOWERS) .. "' and 'i'")
		assert(l.TextFits, where .. ": the hint '" .. l.Text .. "' doesn't fit its " .. l.AbsoluteSize.X .. "x" .. l.AbsoluteSize.Y .. " box")
		local hr, lr, wr, fr = rel(h, wg), rel(l, wg), rel(walk, wg), rel(footer, wg)
		assert(within(hr, cr) and within(lr, cr), where .. ": the hint " .. fmt(hr) .. " is outside the card " .. fmt(cr))
		assert(walk.Visible and walk.AbsoluteSize.X >= 44 and walk.AbsoluteSize.Y >= 44 and within(wr, cr), where .. ": WALK AWAY " .. fmt(wr)
			.. " is hidden, under 44 px or outside the card " .. fmt(cr))
		assert(hr.y0 >= wr.y1 and hr.y0 >= fr.y1, where .. ": the hint " .. fmt(hr) .. " is not under WALK AWAY " .. fmt(wr) .. " and the footer " .. fmt(fr))
		assert(footer.TextFits, where .. ": the Aura footer '" .. footer.Text .. "' no longer fits")
		table.insert(out, string.format("2 walk-in %s: hint %s (%dx%d, fits) under WALK AWAY %s (%dx%d), card %s inside", where, fmt(hr), l.AbsoluteSize.X,
			l.AbsoluteSize.Y, fmt(wr), walk.AbsoluteSize.X, walk.AbsoluteSize.Y, fmt(cr)))
	end
	fits("real " .. wg.AbsoluteSize.X .. "x" .. wg.AbsoluteSize.Y, wg.AbsoluteSize)
	local ins = inset(wg)
	for _, screen in ipairs({ Vector2.new(844, 390), Vector2.new(667, 375) }) do
		local vp = screen - ins
		wg:SetAttribute("ForceViewport", vp); task.wait(0.2)
		fits(vp.X .. "x" .. vp.Y .. " (" .. screen.X .. "x" .. screen.Y .. " less " .. ins.X .. "x" .. ins.Y .. ")", vp)
	end
	wg:SetAttribute("ForceViewport", nil); task.wait(0.2)
	wg:SetAttribute("Command", "walkaway")
	assert(waitFor(function() return wg:GetAttribute("Open") == false end, 5), "WALK AWAY did not close the card")
	table.insert(out, "2 WALK AWAY closed it")
end

-- the hinted DM: the choices above the fold, the hint after them, at three sizes; then DISMISS
local function dm()
	local card = phone.Root.Card
	assert(waitFor(function() return phone:GetAttribute("Open") == true end, 10), "the DM did not open (Open " .. tostring(phone:GetAttribute("Open"))
		.. ", Pending " .. tostring(phone:GetAttribute("Pending")) .. ", Deferred " .. tostring(phone:GetAttribute("Deferred")) .. ")")
	assert(phone:GetAttribute("Card") == DM and card.Visible, "the open DM is '" .. tostring(phone:GetAttribute("Card")) .. "', want t76a's " .. DM)
	assert(phone:GetAttribute("Choices") == 2, "the DM shows " .. tostring(phone:GetAttribute("Choices")) .. " choices, want 2")
	local scroll = card:FindFirstChild("Scroll")
	assert(scroll and scroll:IsA("ScrollingFrame"), "phone: no Scroll in the card")
	local h, l, i = hintOf(card, "phone")
	assert(h.Parent == scroll, "phone: the hint sits in " .. h.Parent.Name .. ", want the scrolling middle (fix round 1; before its sync: the card)")
	local dismiss = card:FindFirstChild("Dismiss")
	local c1, c2 = scroll:FindFirstChild("Choice1"), scroll:FindFirstChild("Choice2")
	assert(dismiss and c1 and c2, "phone: no Dismiss, Choice1 or Choice2")
	local ins = inset(ui)
	for _, screen in ipairs({ Vector2.new(667, 375), Vector2.new(771, 390), Vector2.new(844, 390) }) do
		local vp = screen - ins
		local where = vp.X .. "x" .. vp.Y .. " (" .. screen.X .. "x" .. screen.Y .. " less " .. ins.X .. "x" .. ins.Y .. ")"
		ui:SetAttribute("ForceViewport", vp); phone:SetAttribute("ForceViewport", vp)
		task.wait(0.6) -- the HUD re-lays the pills at once; PhoneUI re-lays the card when its top changes (0.2 s)
		scroll.CanvasPosition = Vector2.new(0, 0)
		task.wait(0.15)
		local cr, sr = rel(card, phone), rel(scroll, phone)
		assert(cr.x0 >= 0 and cr.y0 >= 0 and cr.x1 <= vp.X and cr.y1 <= vp.Y, where .. ": the DM " .. fmt(cr) .. " is outside (0,0)-(" .. vp.X .. "," .. vp.Y .. ")")
		for k, b in ipairs({ c1, c2 }) do
			assert(b.Visible and b.AbsoluteSize.X >= 44 and b.AbsoluteSize.Y >= 44, where .. ": Choice" .. k .. " hidden or under 44 px")
		end
		local dr = rel(dismiss, phone)
		assert(dismiss.Visible and dismiss.AbsoluteSize.X >= 44 and dismiss.AbsoluteSize.Y >= 44 and dr.y1 <= vp.Y and dr.x1 <= vp.X,
			where .. ": DISMISS " .. fmt(dr) .. " is hidden, under 44 px or outside the box")
		-- the choices above the fold (unscrolled), the hint after them
		local r1, r2, hr = rel(c1, phone), rel(c2, phone), rel(h, phone)
		local full1 = r1.y0 >= sr.y0 and r1.y1 <= sr.y1
		local full2 = r2.y0 >= sr.y0 and r2.y1 <= sr.y1
		local top2 = r2.y0 >= sr.y0 and r2.y0 < sr.y1
		local detail = string.format("Scroll %s, Choice1 %s, Choice2 %s, hint %s", fmt(sr), fmt(r1), fmt(r2), fmt(hr))
		assert(h.Visible and l.Text == HIT and i.Text == "i", where .. ": the DM's hint is hidden or reads '" .. l.Text .. "', want '" .. tostring(HIT) .. "'")
		assert(hr.y0 >= r2.y1, where .. ": the hint is not after the last choice: " .. detail)
		assert(full1, where .. ": Choice1 is not fully visible without scrolling: " .. detail)
		if screen.X == 667 then
			assert(top2, where .. ": Choice2's top is not in view without scrolling: " .. detail)
		else
			assert(full2, where .. ": Choice2 is not fully visible without scrolling (the hint pushed it under the fold?): " .. detail)
		end
		-- scrolled to the end, the hint is in view and fits
		scroll.CanvasPosition = Vector2.new(0, math.max(0, scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteWindowSize.Y))
		task.wait(0.15)
		local hs, ss = rel(h, phone), rel(scroll, phone)
		assert(hs.y0 >= ss.y0 and hs.y1 <= ss.y1 and hs.x0 >= ss.x0 and hs.x1 <= ss.x1, string.format("%s: scrolled to its end the hint %s is not inside the Scroll %s", where, fmt(hs), fmt(ss)))
		assert(l.TextFits, where .. ": the DM's hint doesn't fit its " .. l.AbsoluteSize.X .. "x" .. l.AbsoluteSize.Y .. " box")
		scroll.CanvasPosition = Vector2.new(0, 0)
		table.insert(out, string.format("3 phone %s: %s; Choice1 %s, Choice2 %s; scrolled to the end the hint %s is in view and fits; card %s inside",
			where, detail, full1 and "fully visible" or "cut", full2 and "fully visible" or (top2 and "top in view" or "under the fold"), fmt(hs), fmt(cr)))
	end
	ui:SetAttribute("ForceViewport", nil); phone:SetAttribute("ForceViewport", nil)
	task.wait(0.6)
	phone:SetAttribute("LastChoose", "")
	phone:SetAttribute("Command", "dismiss")
	assert(waitFor(function() return phone:GetAttribute("Open") == false and phone:GetAttribute("LastChoose") == "ok" end, 5), "DISMISS did not close the DM")
	table.insert(out, "3 DISMISS closed the DM")
end

local function run()
	assert(type(resetAt) == "number" and type(arrivedAt) == "number", "no _T76Reset / _T76Arrived on the player (t76a's staging did not run)")
	assert(arrivedAt - resetAt <= 35, string.format("t76a: he arrived %.1f s after the reset, want 35 or less", arrivedAt - resetAt))
	-- whichever card opens first is checked first; the other opens once it closes
	assert(waitFor(function() return wg:GetAttribute("Open") == true or phone:GetAttribute("Open") == true end, math.max(2, 36 - (workspace:GetServerTimeNow() - resetAt))),
		"neither card opened (walk-in Open " .. tostring(wg:GetAttribute("Open")) .. ", Deferred " .. tostring(wg:GetAttribute("Deferred")) .. "; phone Pending "
		.. tostring(phone:GetAttribute("Pending")) .. ")")
	if wg:GetAttribute("Open") == true then
		walkIn(true); dm()
	else
		table.insert(out, "the DM opened first (a beat maker held both): the walk-in card waited behind it")
		dm(); walkIn(false)
	end
end

local ok, err = pcall(run)
wg:SetAttribute("ForceViewport", nil); ui:SetAttribute("ForceViewport", nil); phone:SetAttribute("ForceViewport", nil)
if wg:GetAttribute("Open") == true then wg:SetAttribute("Command", "walkaway") end
if phone:GetAttribute("Open") == true then phone:SetAttribute("Command", "dismiss") end
pcall(function() RS.OK.Remotes.Tour_Skip:FireServer() end) -- t76a left the tour unfinished for the first-ever visit
if not ok then error(err, 0) end
return "T76B PLAY OK\n" .. table.concat(out, "\n")
