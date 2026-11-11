-- Client, during play (Wave 3 Task 3; design 4.1; Review Focus 1), after t77a's staging: navx_placement open with your
-- best beat (3 stars, 3 FIRE) and the hint placement unseen, the hardest footer: the Aura line, the beat line and the
-- hint. The card arrived with no beat and the beat came after, through "beat" updates (fix round 1): the client rebuilt
-- the beat line and his line in place (BeatUpdates counted on the gui; Card.Scroll.Line reads "the one at 142"). Each
-- line is read by its path: OK_WalkIn.Root.Card.Footer (the Aura line, CardFeel.Footer), Root.Card.BeatLine and the
-- Hint row (the card's child while the body fits above it, else Card.Scroll.Hint after the last choice).
-- (1) The beat line reads "Your best beat: ★★★ · 🔥 3" (CardFeel.BeatLine), the Footer still reads the Aura line, and the
--     hint the Config.Hints text for placement.
-- (2) At the real viewport and forced to the safe area of an 844x390, a 771x390 (an 844x390 phone less a 73 px notch) and
--     a 667x375 phone (the screen minus this gui's real insets, as t47b), and a roomy 1280x720 (less the insets): every
--     choice and WALK AWAY is shown, 44 px or
--     more, its text fitting; with the Scroll at the top every choice sits fully inside the Scroll's rect (no choice
--     pushed out of view); the footer rows run Aura line, then the beat line, then the hint: the beat line is under WALK
--     AWAY's row, inside the card, its text fitting and clear of the Aura line and WALK AWAY; a footer hint is under the
--     beat line, inside the card; a scroll hint's top is at or under the last choice's bottom; the card is inside the box.
--     On a box 420 px tall or more (ROOMY spacing: this three-choice card's body, beat line and hint all fit above the
--     fold) the hint must be in the footer, not the scroll (fix round 1).
-- WALK AWAY closes it, and everything this file changed is set back (the forced size).
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui", 10)
local wg = pg:WaitForChild("OK_WalkIn", 10); assert(wg, "no OK_WalkIn gui (WalkInUI.Build did not run?)")
local daw = pg:WaitForChild("OK_DAW", 10):WaitForChild("DAW", 10); assert(daw, "no beat maker gui")
local Config = require(RS.OK.Config)
local CardFeel = require(RS.OK.Modules.CardFeel)
local CARD = "navx_placement"
local WANT = "Your best beat: ★★★ · 🔥 3"
local PLACEMENT
for _, h in ipairs(Config.Hints) do if h.term == "placement" then PLACEMENT = h.text end end
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
	task.wait(0.3) -- the labels were filled while the card was hidden: let it render once so TextFits and the rects are current
	local card = wg.Root.Card
	local scroll = card:FindFirstChild("Scroll")
	local footer, walk = card:FindFirstChild("Footer"), card:FindFirstChild("WalkAway")
	local beat = card:FindFirstChild("BeatLine")
	assert(beat, "no Card.BeatLine (before the Task 3 sync of Modules/WalkInUI: the expected red)")
	local n = wg:GetAttribute("Choices")
	assert(n == 3, "Choices " .. tostring(n) .. ", " .. CARD .. " has 3")

	-- 1. the three lines' words
	assert(beat.Visible and beat.Text == WANT, "the beat line is hidden or reads '" .. beat.Text .. "', want '" .. WANT .. "'")
	assert(CardFeel.BeatLine({ stars = 3, fires = 3, bpm = 142 }) == WANT, "CardFeel.BeatLine({3, 3}) reads '" .. tostring(CardFeel.BeatLine({ stars = 3, fires = 3 })) .. "'")
	assert(footer and footer.Text == CardFeel.Footer(), "the Aura line reads '" .. tostring(footer and footer.Text) .. "', want '" .. CardFeel.Footer() .. "'")
	local hint = card:FindFirstChild("Hint", true)
	local hl = hint and hint:FindFirstChild("Label")
	assert(hint and hint.Visible and hl and hl.Text == PLACEMENT, "the hint is missing, hidden or reads '" .. tostring(hl and hl.Text) .. "', want the placement text")
	-- the beat came after the arrival: the client applied "beat" updates and rebuilt his line with it
	local updates = tonumber(wg:GetAttribute("BeatUpdates")) or 0
	assert(updates >= 1, "no \"beat\" update reached the card (BeatUpdates " .. tostring(wg:GetAttribute("BeatUpdates")) .. "; before the fix-round sync of Modules/WalkInUI)")
	local line = scroll:FindFirstChild("Line")
	assert(line and string.find(line.Text, "the one at 142", 1, true), "his line on the card reads '" .. tostring(line and line.Text) .. "', want 'the one at 142' in it")
	table.insert(out, string.format("1 %s: Aura line '%s'; beat line '%s' (BeatUpdates %d); line '%s'; hint '%s'", CARD, footer.Text, beat.Text, updates, line.Text, hl.Text))

	-- 2. the layout at each size
	local function check(where, vp)
		task.wait(0.4)
		scroll.CanvasPosition = Vector2.new(0, 0)
		task.wait(0.1)
		local cr, sr, wr, fr, br = rel(card), rel(scroll), rel(walk), rel(footer), rel(beat)
		assert(cr.x0 >= 0 and cr.y0 >= 0 and cr.x1 <= vp.X and cr.y1 <= vp.Y, where .. ": the card " .. fmt(cr) .. " is outside (0,0)-(" .. vp.X .. "," .. vp.Y .. ")")
		local lastBottom = 0
		for i = 1, n do
			local b = card:FindFirstChild("Choice" .. i, true)
			assert(b and b.Visible and b.AbsoluteSize.Y >= 44, where .. ": Choice" .. i .. " missing, hidden or under 44 px")
			local l = b:FindFirstChild("Label")
			assert(l and l.TextFits, where .. ": Choice" .. i .. " text doesn't fit: '" .. tostring(l and l.Text) .. "'")
			local r = rel(b)
			assert(r.y0 >= sr.y0 - 1 and r.y1 <= sr.y1 + 1, where .. ": Choice" .. i .. " " .. fmt(r) .. " is outside the Scroll " .. fmt(sr)
				.. " with the Scroll at the top (a footer line pushed it out of view)")
			lastBottom = math.max(lastBottom, r.y1)
		end
		assert(walk.Visible and walk.AbsoluteSize.Y >= 44 and within(wr, cr), where .. ": WALK AWAY " .. fmt(wr) .. " hidden, under 44 px or outside the card")
		assert(footer.TextFits, where .. ": the Aura line doesn't fit its " .. footer.AbsoluteSize.X .. "x" .. footer.AbsoluteSize.Y .. " box")
		-- the beat line: under WALK AWAY's row, inside the card, fitting, clear of the Aura line and WALK AWAY
		assert(beat.Visible and beat.Text == WANT, where .. ": the beat line is hidden or reads '" .. beat.Text .. "'")
		assert(beat.TextFits, where .. ": the beat line doesn't fit its " .. beat.AbsoluteSize.X .. "x" .. beat.AbsoluteSize.Y .. " box")
		assert(within(br, cr), where .. ": the beat line " .. fmt(br) .. " is outside the card " .. fmt(cr))
		assert(br.y0 >= wr.y1 and br.y0 >= fr.y1, where .. ": the beat line " .. fmt(br) .. " is not under WALK AWAY " .. fmt(wr) .. " and the Aura line " .. fmt(fr))
		assert(not overlaps(br, wr) and not overlaps(br, fr), where .. ": the beat line overlaps WALK AWAY or the Aura line")
		-- the hint: last, under the beat line in the footer, or after the last choice in the scroll
		local hr = rel(hint)
		local place
		if vp.Y >= 420 then
			assert(hint.Parent == card, where .. ": on a box " .. vp.Y .. " px tall the body, the beat line and the hint fit, but the hint went to the scroll")
		end
		if hint.Parent == card then
			place = "footer"
			assert(hr.y0 >= br.y1 and within(hr, cr), where .. ": the footer hint " .. fmt(hr) .. " is not under the beat line " .. fmt(br) .. " inside the card " .. fmt(cr))
		else
			place = "scroll"
			assert(hint.Parent == scroll, where .. ": the hint sits under " .. hint.Parent:GetFullName())
			assert(hr.y0 >= lastBottom, where .. ": the scroll hint's top " .. hr.y0 .. " is above the last choice's bottom " .. lastBottom)
		end
		assert(hl.TextFits, where .. ": the hint doesn't fit its box")
		table.insert(out, string.format("2 %s: choices >= 44 px and in view in the Scroll %s, beat line %s under WALK AWAY %s, hint in the %s %s, card %s",
			where, fmt(sr), fmt(br), fmt(wr), place, fmt(hr), fmt(cr)))
	end
	check("real " .. wg.AbsoluteSize.X .. "x" .. wg.AbsoluteSize.Y, wg.AbsoluteSize)
	local d = cam.ViewportSize - wg.AbsoluteSize
	local inset = Vector2.new(math.max(0, d.X), math.max(0, d.Y))
	for _, screen in ipairs({ Vector2.new(1280, 720), Vector2.new(844, 390), Vector2.new(771, 390), Vector2.new(667, 375) }) do
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
return "T77B PLAY OK\n" .. table.concat(out, "\n")
