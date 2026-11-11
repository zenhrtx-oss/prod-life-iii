-- Client, during play (Wave 3 Task 3; design 4.1; Review Focus 1), after t77c: navx_placement open with no recent beat.
-- (1) The beat line (OK_WalkIn.Root.Card.BeatLine) reads "No beat delivered yet. Your odds are lower." (CardFeel.BeatLine
-- of false) and the Aura line (Root.Card.Footer) is still CardFeel.Footer. (2) At the real viewport and forced to the
-- safe area of an 844x390, a 771x390 and a 667x375 phone (less this gui's real insets, as t47b): the line shows, fits,
-- sits under WALK AWAY's row inside the card, clear of the Aura line; every choice and WALK AWAY is 44 px or more, and
-- with the Scroll at the top every choice is fully inside the Scroll's rect; the card is inside the box. WALK AWAY closes
-- it, and the forced size is set back.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui", 10)
local wg = pg:WaitForChild("OK_WalkIn", 10); assert(wg, "no OK_WalkIn gui (WalkInUI.Build did not run?)")
local daw = pg:WaitForChild("OK_DAW", 10):WaitForChild("DAW", 10); assert(daw, "no beat maker gui")
local CardFeel = require(RS.OK.Modules.CardFeel)
local CARD = "navx_placement"
local WANT = "No beat delivered yet. Your odds are lower."
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
		.. tostring(wg:GetAttribute("Card")) .. "', Deferred " .. tostring(wg:GetAttribute("Deferred")) .. ")")
	task.wait(0.3)
	local card = wg.Root.Card
	local scroll, footer, walk = card:FindFirstChild("Scroll"), card:FindFirstChild("Footer"), card:FindFirstChild("WalkAway")
	local beat = card:FindFirstChild("BeatLine")
	assert(beat, "no Card.BeatLine (before the Task 3 sync of Modules/WalkInUI: the expected red)")
	local n = wg:GetAttribute("Choices")
	assert(n == 3, "Choices " .. tostring(n) .. ", " .. CARD .. " has 3")

	-- 1. the words
	assert(beat.Visible and beat.Text == WANT, "the beat line is hidden or reads '" .. beat.Text .. "', want '" .. WANT .. "'")
	assert(CardFeel.BeatLine(false) == WANT and CardFeel.BeatLine(nil) == nil, "CardFeel.BeatLine(false) / (nil) read '"
		.. tostring(CardFeel.BeatLine(false)) .. "' / '" .. tostring(CardFeel.BeatLine(nil)) .. "'")
	assert(footer.Text == CardFeel.Footer(), "the Aura line reads '" .. footer.Text .. "', want '" .. CardFeel.Footer() .. "'")
	table.insert(out, "1 " .. CARD .. " with no beat: beat line '" .. beat.Text .. "'; Aura line '" .. footer.Text .. "'")

	-- 2. it fits at each size, every choice in view
	local function check(where, vp)
		task.wait(0.4)
		scroll.CanvasPosition = Vector2.new(0, 0)
		task.wait(0.1)
		local cr, sr, wr, fr, br = rel(card), rel(scroll), rel(walk), rel(footer), rel(beat)
		assert(cr.x0 >= 0 and cr.y0 >= 0 and cr.x1 <= vp.X and cr.y1 <= vp.Y, where .. ": the card " .. fmt(cr) .. " is outside (0,0)-(" .. vp.X .. "," .. vp.Y .. ")")
		for i = 1, n do
			local b = card:FindFirstChild("Choice" .. i, true)
			assert(b and b.Visible and b.AbsoluteSize.Y >= 44, where .. ": Choice" .. i .. " missing, hidden or under 44 px")
			local l = b:FindFirstChild("Label")
			assert(l and l.TextFits, where .. ": Choice" .. i .. " text doesn't fit: '" .. tostring(l and l.Text) .. "'")
			local r = rel(b)
			assert(r.y0 >= sr.y0 - 1 and r.y1 <= sr.y1 + 1, where .. ": Choice" .. i .. " " .. fmt(r) .. " is outside the Scroll " .. fmt(sr))
		end
		assert(walk.Visible and walk.AbsoluteSize.Y >= 44 and within(wr, cr), where .. ": WALK AWAY " .. fmt(wr) .. " hidden, under 44 px or outside the card")
		assert(beat.Visible and beat.Text == WANT and beat.TextFits, where .. ": the beat line is hidden, reads '" .. beat.Text .. "' or doesn't fit")
		assert(within(br, cr) and br.y0 >= wr.y1 and not overlaps(br, fr) and not overlaps(br, wr), where .. ": the beat line " .. fmt(br)
			.. " is not under WALK AWAY " .. fmt(wr) .. " inside the card " .. fmt(cr) .. ", clear of the Aura line " .. fmt(fr))
		table.insert(out, string.format("2 %s: choices >= 44 px and in view in %s, beat line %s fits under WALK AWAY %s, card %s", where, fmt(sr), fmt(br), fmt(wr), fmt(cr)))
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
return "T77D PLAY OK\n" .. table.concat(out, "\n")
