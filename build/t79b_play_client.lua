-- Client, during play (Wave 3 Task 5; design 4.3), after t79a's staging: navx_tv, a new arc card (LIL NAV X's late-night
-- TV shout-out, two choices), open. Each line is read by its path: OK_WalkIn.Root.Card.Footer (the Aura line,
-- CardFeel.Footer, beside WALK AWAY), Root.Card.BeatLine (none here: no choice of this card is decided by your beat) and
-- the Hint row if the card has one (the card's child while the body fits above it, else Card.Scroll.Hint after the last
-- choice).
-- (1) Two choices, his line and tag filled (no "{"), the Aura line reads CardFeel.Footer(), no beat line.
-- (2) At the real viewport and forced to the safe area of an 844x390, a 771x390 (an 844x390 phone less a 73 px notch) and
--     a 667x375 phone (the screen minus this gui's real insets, as t47b and t77b): every choice and WALK AWAY is shown,
--     44 px or more, its text fitting; with the Scroll at the top every choice sits fully inside the Scroll's rect; his
--     line fits when it shows; the footer lines don't overlap: the Aura line and WALK AWAY share their row without
--     touching, a footer hint is under them, a scroll hint's top is at or under the last choice's bottom; the card is
--     inside the box.
-- WALK AWAY closes it, and everything this file changed is set back (the forced size).
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui", 10)
local wg = pg:WaitForChild("OK_WalkIn", 10); assert(wg, "no OK_WalkIn gui (WalkInUI.Build did not run?)")
local daw = pg:WaitForChild("OK_DAW", 10):WaitForChild("DAW", 10); assert(daw, "no beat maker gui")
local CardFeel = require(RS.OK.Modules.CardFeel)
local CARD = "navx_tv"
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function rel(g) local p, s = g.AbsolutePosition - wg.AbsolutePosition, g.AbsoluteSize; return { x0 = p.X, y0 = p.Y, x1 = p.X + s.X, y1 = p.Y + s.Y } end
local function within(a, b) return a.x0 >= b.x0 - 1 and a.y0 >= b.y0 - 1 and a.x1 <= b.x1 + 1 and a.y1 <= b.y1 + 1 end
local function overlaps(a, b) return a.x0 < b.x1 - 1 and b.x0 < a.x1 - 1 and a.y0 < b.y1 - 1 and b.y0 < a.y1 - 1 end
local function fmt(r) return string.format("(%d,%d)-(%d,%d)", r.x0, r.y0, r.x1, r.y1) end
wg:SetAttribute("ForceViewport", nil)
if daw.Visible then daw:SetAttribute("Command", "close"); task.wait(0.4) end
local out = {}

local function run()
	assert(waitFor(function() return wg:GetAttribute("Open") == true and wg:GetAttribute("Card") == CARD end, 20), "the card did not open within 20 s (Card '"
		.. tostring(wg:GetAttribute("Card")) .. "', Deferred " .. tostring(wg:GetAttribute("Deferred")) .. "; before the Task 5 sync of Data/WalkIns there is no navx_tv)")
	task.wait(0.3) -- let it render once so TextFits and the rects are current
	local card = wg.Root.Card
	local scroll = card:FindFirstChild("Scroll")
	local footer, walk = card:FindFirstChild("Footer"), card:FindFirstChild("WalkAway")
	local beat = card:FindFirstChild("BeatLine")
	assert(scroll and footer and walk, "the card has no Scroll, Footer or WalkAway")
	local n = wg:GetAttribute("Choices")
	assert(n == 2, "Choices " .. tostring(n) .. ", " .. CARD .. " has 2")

	-- 1. the words
	assert(footer.Text == CardFeel.Footer(), "the Aura line reads '" .. footer.Text .. "', want '" .. CardFeel.Footer() .. "'")
	assert(not (beat and beat.Visible and beat.Text ~= ""), "a beat line shows ('" .. tostring(beat and beat.Text) .. "') on a card your beat doesn't decide")
	local line = scroll:FindFirstChild("Line")
	for _, g in ipairs({ line, card:FindFirstChild("Tag", true) }) do
		if g and g:IsA("TextLabel") then assert(not string.find(g.Text, "{", 1, true), g.Name .. " has an unfilled token: '" .. g.Text .. "'") end
	end
	local hint = card:FindFirstChild("Hint", true)
	local hl = hint and hint:FindFirstChild("Label")
	local hasHint = hint ~= nil and hint.Visible and hl ~= nil and hl.Text ~= ""
	table.insert(out, string.format("1 %s: 2 choices; Aura line '%s'; no beat line; line '%s'; hint %s", CARD, footer.Text,
		tostring(line and line.Text), hasHint and ("'" .. hl.Text .. "'") or "none"))

	-- 2. the layout at each size
	local function check(where, vp)
		task.wait(0.4)
		scroll.CanvasPosition = Vector2.new(0, 0)
		task.wait(0.1)
		local cr, sr, wr, fr = rel(card), rel(scroll), rel(walk), rel(footer)
		assert(cr.x0 >= 0 and cr.y0 >= 0 and cr.x1 <= vp.X and cr.y1 <= vp.Y, where .. ": the card " .. fmt(cr) .. " is outside (0,0)-(" .. vp.X .. "," .. vp.Y .. ")")
		local lastBottom = 0
		for i = 1, n do
			local b = card:FindFirstChild("Choice" .. i, true)
			assert(b and b.Visible and b.AbsoluteSize.Y >= 44, where .. ": Choice" .. i .. " missing, hidden or under 44 px")
			local l = b:FindFirstChild("Label")
			assert(l and l.TextFits, where .. ": Choice" .. i .. " text doesn't fit: '" .. tostring(l and l.Text) .. "'")
			local r = rel(b)
			assert(r.y0 >= sr.y0 - 1 and r.y1 <= sr.y1 + 1, where .. ": Choice" .. i .. " " .. fmt(r) .. " is outside the Scroll " .. fmt(sr)
				.. " with the Scroll at the top (pushed out of view)")
			lastBottom = math.max(lastBottom, r.y1)
		end
		if line and line.Visible then assert(line.TextFits, where .. ": his line doesn't fit its box") end
		assert(walk.Visible and walk.AbsoluteSize.Y >= 44 and within(wr, cr), where .. ": WALK AWAY " .. fmt(wr) .. " hidden, under 44 px or outside the card")
		assert(footer.TextFits, where .. ": the Aura line doesn't fit its " .. footer.AbsoluteSize.X .. "x" .. footer.AbsoluteSize.Y .. " box")
		assert(within(fr, cr), where .. ": the Aura line " .. fmt(fr) .. " is outside the card " .. fmt(cr))
		assert(not overlaps(fr, wr), where .. ": the Aura line " .. fmt(fr) .. " overlaps WALK AWAY " .. fmt(wr))
		assert(fr.y0 >= sr.y1 - 1 and wr.y0 >= sr.y1 - 1, where .. ": the footer row is not under the Scroll " .. fmt(sr))
		assert(not (beat and beat.Visible and beat.AbsoluteSize.Y > 0), where .. ": a beat line takes room on a card with no beat choice")
		local place = "none"
		if hasHint then
			local hr = rel(hint)
			if hint.Parent == card then
				place = "footer " .. fmt(hr)
				assert(hr.y0 >= wr.y1 and hr.y0 >= fr.y1 and within(hr, cr), where .. ": the footer hint " .. fmt(hr) .. " is not under the Aura line and WALK AWAY, inside the card")
			else
				place = "scroll " .. fmt(hr)
				assert(hint.Parent == scroll and hr.y0 >= lastBottom, where .. ": the scroll hint " .. fmt(hr) .. " is above the last choice's bottom " .. lastBottom)
			end
			assert(hl.TextFits, where .. ": the hint doesn't fit its box")
		end
		table.insert(out, string.format("2 %s: 2 choices >= 44 px, fitting, in view in the Scroll %s; Aura line %s beside WALK AWAY %s; hint %s; card %s",
			where, fmt(sr), fmt(fr), fmt(wr), place, fmt(cr)))
	end
	check("real " .. wg.AbsoluteSize.X .. "x" .. wg.AbsoluteSize.Y, wg.AbsoluteSize)
	local d = cam.ViewportSize - wg.AbsoluteSize
	local inset = Vector2.new(math.max(0, d.X), math.max(0, d.Y))
	for _, screen in ipairs({ Vector2.new(844, 390), Vector2.new(771, 390), Vector2.new(667, 375) }) do
		local vp = screen - inset
		wg:SetAttribute("ForceViewport", vp)
		check(vp.X .. "x" .. vp.Y .. " (" .. screen.X .. "x" .. screen.Y .. " less " .. inset.X .. "x" .. inset.Y .. ")", vp)
	end
	wg:SetAttribute("ForceViewport", nil)
	wg:SetAttribute("Command", "walkaway")
	assert(waitFor(function() return wg:GetAttribute("Open") == false end, 4), "WALK AWAY did not close the card")
	table.insert(out, "WALK AWAY closed it")
end

local okRun, err = pcall(run)
wg:SetAttribute("ForceViewport", nil)
if wg:GetAttribute("Open") == true then wg:SetAttribute("Command", "walkaway") end
if not okRun then error(err, 0) end
return "T79B PLAY OK\n" .. table.concat(out, "\n")
