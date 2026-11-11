-- Client, during play (after t57a popped dm_navx then news_spedup with Quiet off): the phone card (design 4.1). No
-- carry-over: the card that opens by itself within 5 s is dm_navx and Pending is 2 (what t57a sent, nothing older). Its
-- three choices and DISMISS are at least 44 px with their text fitting, and the card is inside the gui. At the real
-- viewport it covers none of the HUD, the career pills, the daily / tour pill or the cypher bar (held shown with
-- ForceShow: a bar beside the pills that reaches the card's column pushes the card 8 px under it, as FIRE sits under
-- it, and the card is back at top 58 once the bar hides); FIRE and SAMPLE IT share its right column while it is open
-- (documented: the card draws over them, and both hide while the beat maker fills a phone screen). The icon covers nothing on that list, FIRE and SAMPLE IT
-- included, in either spot: "pills" with OK_UI forced to 844x390 (pills side by side) and "corner" at 667x375 (the
-- stacked pills leave it no room beside them). Forced to those phones' safe areas (the screen minus this gui's real
-- insets) the buttons stay 44 px, the card, 240-300 px wide, stays inside (0, 0)-vp and clears the career pills in both
-- spots (stacked at 667 they end at y 66: the card starts 8 px under them), and in the corner spot FIRE's top (its Top
-- attribute) clears the icon's bottom by 8 px, bar or no bar (the icon sits in FIRE's column there). choose:1 (sure,
-- free: SENT) shows the result inline in the same card. Then the beat maker opens at the studio PC with that result on
-- screen (the card hides behind it; a pre-check says so: Open, Card dm_navx, ResultKey sent) and OK closes it: the
-- NEWS waits behind the beat maker instead of opening by itself. The icon opens it over the beat maker (Command open)
-- and a dismiss sent at once is ignored (a NEWS has nothing to choose: LastChoose stays ""): its result (SPED UP)
-- shows with the card open and it closes by itself within NewsCloseSeconds + 1 s, leaving Pending 0. The beat maker
-- stays open for t57c.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character; local root = char:WaitForChild("HumanoidRootPart", 5); local hum = char:WaitForChild("Humanoid", 5); local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui", 10)
local gui = pg:WaitForChild("OK_Phone", 10); assert(gui, "no OK_Phone gui (PhoneUI.Build did not run?)")
local ui = pg:WaitForChild("OK_UI", 10)
local wg = pg:WaitForChild("OK_WalkIn", 10)
local dawGui = pg:WaitForChild("OK_DAW", 10); local daw = dawGui and dawGui:WaitForChild("DAW", 10); assert(daw, "no beat maker gui")
local bar, fire, sample = pg.OK_Cypher.Bar, pg.OK_Fire.FireButton, dawGui:FindFirstChild("SampleButton")
assert(sample, "no SAMPLE IT button under OK_DAW")
local Content = require(RS.OK.Data.WalkIns)
local P = require(RS.OK.Config).Phone
local navx = Content.CardById.dm_navx
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
-- rects in the phone gui's own space: (0, 0) is its top-left, so a forced viewport's box is (0, 0)-vp
local function rel(g) local p, s = g.AbsolutePosition - gui.AbsolutePosition, g.AbsoluteSize; return { x0 = p.X, y0 = p.Y, x1 = p.X + s.X, y1 = p.Y + s.Y } end
local function overlaps(a, b) return a.x0 < b.x1 and b.x0 < a.x1 and a.y0 < b.y1 and b.y0 < a.y1 end
local function fmt(r) return string.format("(%d,%d)-(%d,%d)", r.x0, r.y0, r.x1, r.y1) end
-- never inherit a forced size, a held bar or an open beat maker from an earlier failed run
gui:SetAttribute("ForceViewport", nil); ui:SetAttribute("ForceViewport", nil); wg:SetAttribute("ForceViewport", nil); bar:SetAttribute("ForceShow", nil)
daw:SetAttribute("CompactForced", nil); daw:SetAttribute("ViewportOverride", nil)
if daw.Visible then daw:SetAttribute("Command", "close"); task.wait(0.4) end
if hum.Sit then hum.Sit = false; task.wait(0.4) end
cam.CameraType = Enum.CameraType.Custom
local out = {}

-- 1. the DM opens by itself; no older pop is held
assert(waitFor(function() return gui:GetAttribute("Open") == true end, 5), "no phone card opened within 5 s (Pending " .. tostring(gui:GetAttribute("Pending"))
	.. ", Deferred " .. tostring(gui:GetAttribute("Deferred")) .. ", Token '" .. tostring(gui:GetAttribute("Token")) .. "')")
local card, icon = gui:FindFirstChild("Card", true), gui:FindFirstChild("Icon", true)
assert(card and card.Visible and icon, "Card frame missing or hidden while Open, or no Icon")
assert(gui:GetAttribute("Card") == "dm_navx", "the card that opened is '" .. tostring(gui:GetAttribute("Card")) .. "', not t57a's dm_navx (a pop carried over?)")
assert(gui:GetAttribute("Pending") == 2, "Pending " .. tostring(gui:GetAttribute("Pending")) .. ": t57a sent 2 (an earlier file's pop is held, or one was lost)")
assert((gui:GetAttribute("Token") or "") ~= "", "no Token while Open")
local n = gui:GetAttribute("Choices")
assert(n == #navx.choices, "Choices " .. tostring(n) .. ", the card has " .. #navx.choices)
local header, sender = card:FindFirstChild("Header", true), card:FindFirstChild("Sender", true)
assert(header and header.Text == "MESSAGES", "the app label reads '" .. tostring(header and header.Text) .. "'")
assert(sender and sender.Text == Content.Names(require(RS.OK.Config).WalkIns.Roster).navx, "the sender reads '" .. tostring(sender and sender.Text) .. "'")
table.insert(out, "dm_navx opened by itself: " .. header.Text .. " from " .. sender.Text .. ", " .. n .. " choices, Pending 2")
task.wait(0.3) -- the labels were filled while the card was hidden: let it render once so TextFits and the rects are current

local function buttons(where)
	for i = 1, n do
		local b = card:FindFirstChild("Choice" .. i, true)
		assert(b and b.Visible and b.AbsoluteSize.Y >= 44, where .. ": Choice" .. i .. " missing, hidden or under 44 px")
		local l = b:FindFirstChild("Label")
		assert(l and l.TextFits, where .. ": Choice" .. i .. " text doesn't fit: '" .. tostring(l and l.Text) .. "'")
	end
	local d = card:FindFirstChild("Dismiss", true)
	assert(d and d.Visible and d.AbsoluteSize.Y >= 44 and d.TextFits, where .. ": DISMISS missing, under 44 px or its text doesn't fit")
end
local function inside(where, vp)
	local r = rel(card)
	assert(r.x0 >= 0 and r.y0 >= 0 and r.x1 <= vp.X and r.y1 <= vp.Y, where .. ": card " .. fmt(r) .. " outside (0,0)-(" .. vp.X .. "," .. vp.Y .. ")")
	assert(card.AbsoluteSize.X >= 240 and card.AbsoluteSize.X <= 300, where .. ": card " .. card.AbsoluteSize.X .. " px wide (want 240..300)")
end
-- the top-bar pieces the card and the icon must clear (the bar held shown; FIRE's and SAMPLE IT's spots are valid hidden)
local function pieces()
	local list = { HUD = ui.HUD, Career = ui.Career, Bar = bar, FIRE = fire, ["SAMPLE IT"] = sample }
	for _, name in ipairs({ "Daily", "Tour" }) do local g = ui:FindFirstChild(name); if g and g.Visible then list[name] = g end end
	return list
end
local function hitsOf(r, list, skip)
	local hits = {}
	for name, g in pairs(list) do if not (skip and skip[name]) and overlaps(r, rel(g)) then table.insert(hits, name .. " " .. fmt(rel(g))) end end
	table.sort(hits)
	return hits
end

-- 2. real viewport: buttons, inside, the card clear of the top bar (FIRE / SAMPLE IT excepted), the icon clear of all
local real = gui.AbsoluteSize
local where = "real " .. real.X .. "x" .. real.Y
buttons(where); inside(where, real)
bar:SetAttribute("ForceShow", true)
local shown = waitFor(function() return bar.Visible end, 2)
task.wait(0.6) -- CypherUI places the bar (0.2 s), FIRE moves under it (0.15 s), PhoneUI re-places the icon (0.2 s)
local list = pieces()
local iconR, barR, cardR, spot = rel(icon), rel(bar), rel(card), gui:GetAttribute("IconSpot")
-- the bar beside the pills (y 10) must clear the card: when it reaches the card's column the card sits 8 px under it
-- (PhoneUI.cardTop, as FIRE sits under the bar), else the card keeps its top of 58. Dropped under the pills (y 74,
-- under 932 px wide) it shares the card's rows by design, like FIRE and SAMPLE IT in the card's column: both are documented
local barBeside = barR.y0 < iconR.y1
local barInColumn = barBeside and barR.x0 < cardR.x1 and barR.x1 > cardR.x0
local skip = { FIRE = true, ["SAMPLE IT"] = true, Bar = not barBeside or nil }
local cardHits = hitsOf(cardR, list, skip)
local cardColumn = hitsOf(cardR, { FIRE = fire, ["SAMPLE IT"] = sample, Bar = (not barBeside) and bar or nil })
local iconHits = hitsOf(rel(icon), list)
bar:SetAttribute("ForceShow", nil)
assert(shown, "the cypher bar did not show with ForceShow (Studio seam missing?)")
assert(icon.Visible and icon.AbsoluteSize.X >= 44 and icon.AbsoluteSize.Y >= 44, "the phone icon is hidden or under 44 px")
assert(#cardHits == 0, where .. ": card " .. fmt(cardR) .. " covers " .. table.concat(cardHits, ", "))
assert(#iconHits == 0, where .. ": icon " .. fmt(iconR) .. " (" .. tostring(spot) .. ") covers " .. table.concat(iconHits, ", "))
if spot == "pills" and barBeside then -- the bar beside the pills starts after the icon
	assert(barR.x0 >= iconR.x1, where .. ": the cypher bar " .. fmt(barR) .. " starts before the icon's right edge " .. iconR.x1)
end
if barInColumn then -- the card dropped under the bar beside the pills, 8 px clear of it
	assert(cardR.y0 >= barR.y1 + 8, where .. ": card " .. fmt(cardR) .. " should sit 8 px under the bar " .. fmt(barR) .. " beside the pills")
else
	assert(cardR.y0 == 58, where .. ": card top " .. cardR.y0 .. ", want 58 (no bar beside the pills reaches its column)")
end
-- the bar is hidden again: the card is back at top 58 within a PhoneUI check (0.2 s) of CypherUI's (0.2 s)
assert(waitFor(function() return rel(card).y0 == 58 end, 1.5), where .. ": card top " .. rel(card).y0 .. " after the bar hid, want 58")
table.insert(out, string.format("%s: buttons >= 44 px, card %s inside, clear of HUD/pills/daily/tour%s (in its column, documented: %s); icon %s at %s clear of all; card top 58 again once the bar hid",
	where, fmt(cardR), barBeside and (barInColumn and "/bar (card 8 px under the bar " .. fmt(barR) .. ")" or "/bar") or "",
	#cardColumn > 0 and table.concat(cardColumn, ", ") or "none", fmt(iconR), tostring(spot)))

-- 3. forced phone sizes: a phone's screen minus the insets this gui really has (the top bar; side insets on notched
-- phones are not modelled). OK_UI gets the same box, so the pills (and with them the icon's spot) lay out for that
-- phone: side by side at 844 (the icon fits beside them), stacked at 667 (the icon goes to the corner)
local inset = cam.ViewportSize - gui.AbsoluteSize
inset = Vector2.new(math.max(0, inset.X), math.max(0, inset.Y))
for _, case in ipairs({ { screen = Vector2.new(844, 390), spot = "pills" }, { screen = Vector2.new(667, 375), spot = "corner" } }) do
	local vp = case.screen - inset
	gui:SetAttribute("ForceViewport", vp); ui:SetAttribute("ForceViewport", vp)
	bar:SetAttribute("ForceShow", true)
	task.wait(0.6)
	local w2 = vp.X .. "x" .. vp.Y .. " (" .. case.screen.X .. "x" .. case.screen.Y .. " less " .. inset.X .. "x" .. inset.Y .. ")"
	local ok, err = pcall(function()
		buttons(w2); inside(w2, vp)
		assert(gui:GetAttribute("IconSpot") == case.spot, w2 .. ": IconSpot '" .. tostring(gui:GetAttribute("IconSpot")) .. "', want '" .. case.spot .. "'")
		local r = rel(icon)
		assert(r.x0 >= 0 and r.y0 >= 0 and r.x1 <= vp.X and r.y1 <= vp.Y, w2 .. ": icon " .. fmt(r) .. " outside (0,0)-(" .. vp.X .. "," .. vp.Y .. ")")
		local hits = hitsOf(r, pieces())
		assert(#hits == 0, w2 .. ": icon " .. fmt(r) .. " (" .. case.spot .. ") covers " .. table.concat(hits, ", "))
		-- the card clears the career pills in both spots: side by side (844) they end at y 36, stacked (667) at y 66 and
		-- reach the card's column, so the card starts 8 px under them (PhoneUI.cardTop); buttons / inside above say it
		-- still fits the box with its buttons at 44 px
		local cr, careerR = rel(card), rel(ui.Career)
		assert(not overlaps(cr, careerR), w2 .. ": card " .. fmt(cr) .. " covers the career pills " .. fmt(careerR))
		-- in the corner spot the icon sits in FIRE's column (OK_Phone draws over OK_Fire): FIRE's top clears the icon's
		-- bottom by 8 px, bar or no bar. FIRE has no show seam, so its Top attribute (an offset in OK_Fire, published
		-- while hidden; FireButton) is read as an absolute y against the icon's absolute rect; the forced x never matters
		local function fireClear(state)
			local top = fire:GetAttribute("Top")
			assert(type(top) == "number", w2 .. ", " .. state .. ": FIRE's Top attribute is " .. tostring(top))
			local fireTop, iconBottom = top + pg.OK_Fire.AbsolutePosition.Y, icon.AbsolutePosition.Y + icon.AbsoluteSize.Y
			assert(fireTop >= iconBottom + 8, string.format("%s, %s: FIRE's top %d (Top %d) is above the corner icon's bottom %d + 8", w2, state, fireTop, top, iconBottom))
		end
		if case.spot == "corner" then
			fireClear("bar shown")
			bar:SetAttribute("ForceShow", nil)
			task.wait(0.6) -- CypherUI hides the bar (0.2 s), FIRE re-places itself (0.15 s): the icon alone must hold it down
			fireClear("bar hidden")
		end
		table.insert(out, w2 .. ": buttons >= 44 px, card " .. fmt(cr) .. " inside and clear of the pills " .. fmt(careerR) .. "; icon " .. fmt(r) .. " at " .. case.spot .. " clear of all"
			.. (case.spot == "corner" and ("; FIRE's Top " .. tostring(fire:GetAttribute("Top")) .. " clears the icon with the bar hidden") or ""))
	end)
	bar:SetAttribute("ForceShow", nil)
	gui:SetAttribute("ForceViewport", nil); ui:SetAttribute("ForceViewport", nil)
	if not ok then error(err, 0) end
	task.wait(0.4)
end

-- 4. choice 1 (sure, free): SENT, inline in the same card
gui:SetAttribute("ResultKey", ""); gui:SetAttribute("LastChoose", "")
gui:SetAttribute("Command", "choose:1")
assert(waitFor(function() return gui:GetAttribute("ResultKey") == "sent" end, 6), "choice 1 is sure: ResultKey should be 'sent', is '"
	.. tostring(gui:GetAttribute("ResultKey")) .. "', LastChoose '" .. tostring(gui:GetAttribute("LastChoose")) .. "'")
local res = card:FindFirstChild("Result", true)
assert(res and res.Visible and card.Visible and gui:GetAttribute("Open") == true, "the result is not inline in the open card")
assert(overlaps(rel(res), rel(card)) and rel(res).x0 >= rel(card).x0 and rel(res).x1 <= rel(card).x1, "the result block " .. fmt(rel(res)) .. " is not inside the card " .. fmt(rel(card)))
local wres = wg:FindFirstChild("Result", true)
assert(wres and not wres.Visible, "the walk-in result card showed for a phone result")
assert(gui:GetAttribute("Choices") == 0 and gui:GetAttribute("Pending") == 1, "after the choice: Choices " .. tostring(gui:GetAttribute("Choices")) .. ", Pending " .. tostring(gui:GetAttribute("Pending")) .. " (want 0 and 1: the NEWS still waits)")
table.insert(out, "choice 1: " .. tostring(gui:GetAttribute("ResultKey")) .. " (" .. tostring(gui:GetAttribute("ResultTone")) .. ") inline, result " .. fmt(rel(res)) .. " in the card " .. fmt(rel(card)))

-- 5. the beat maker opens at the studio PC with the DM's result on screen (the card hides behind it; the result closes
--    by itself 8 s after it showed, and the beat maker is open within ~6 s even if the prompt needs its four tries:
--    the pre-check fails as a timing miss if it closed first); OK closes it. The NEWS, held behind the open beat maker,
--    waits (Deferred) instead of opening by itself: the beat maker stays open from here for t57c
local screen = workspace.OKStudio.ControlRoom.Screen_Main
local pos = Vector3.new(72.0, 3.5, -5.5)
root.CFrame = CFrame.lookAt(pos, Vector3.new(screen.Position.X, pos.Y, screen.Position.Z)); task.wait(1.0)
cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(-4, 3, 0), screen.Position); task.wait(1.5)
local prompt = screen:FindFirstChildWhichIsA("ProximityPrompt", true)
for _ = 1, 4 do prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); task.wait(0.8); if daw.Visible then break end end
assert(daw.Visible, "beat maker did not open")
assert(gui:GetAttribute("Open") == true and gui:GetAttribute("Card") == "dm_navx" and gui:GetAttribute("ResultKey") == "sent",
	"the DM's result auto-closed (8 s) before the beat maker opened: a timing miss in this step, not a deferral bug (Open "
	.. tostring(gui:GetAttribute("Open")) .. ", Card '" .. tostring(gui:GetAttribute("Card")) .. "', ResultKey '" .. tostring(gui:GetAttribute("ResultKey")) .. "')")
gui:SetAttribute("Command", "ok")
assert(waitFor(function() return gui:GetAttribute("Open") == false end, 2), "OK did not close the DM's result (Open " .. tostring(gui:GetAttribute("Open")) .. ", Card '" .. tostring(gui:GetAttribute("Card")) .. "')")
task.wait(0.5) -- two deferral checks: the NEWS stays behind the beat maker
assert(gui:GetAttribute("Open") == false and gui:GetAttribute("Pending") == 1 and gui:GetAttribute("Deferred") == true and not card.Visible,
	"the NEWS did not wait behind the beat maker (Open " .. tostring(gui:GetAttribute("Open")) .. ", Pending " .. tostring(gui:GetAttribute("Pending")) .. ", Deferred " .. tostring(gui:GetAttribute("Deferred")) .. ")")
table.insert(out, "beat maker open; OK closed the DM: the NEWS waits behind it (Pending 1, Deferred)")

-- 6. the icon opens the NEWS over the beat maker; a dismiss sent at once (the same frame as the open, inside the server
--    round trip, whatever workspace.SignalBehavior: task.defer runs after the open's own handler) is ignored. A NEWS
--    has nothing to choose, so no Phone_Choose goes out and LastChoose stays ""; a reply would read stale (the opened
--    NEWS is already gone on the server) and close the card the moment its result drew. Its result shows with the
--    card open and it closes by itself within NewsCloseSeconds + 1 s
gui:SetAttribute("ResultKey", ""); gui:SetAttribute("LastChoose", "")
gui:SetAttribute("Command", "open")
task.defer(function() gui:SetAttribute("Command", "dismiss") end)
local tNews = os.clock()
assert(waitFor(function() return gui:GetAttribute("ResultKey") == "spedup" end, 3), "the NEWS result did not arrive (ResultKey '" .. tostring(gui:GetAttribute("ResultKey"))
	.. "', Open " .. tostring(gui:GetAttribute("Open")) .. ", Card '" .. tostring(gui:GetAttribute("Card")) .. "', LastChoose '" .. tostring(gui:GetAttribute("LastChoose")) .. "': a dismiss on a NEWS went to the server?)")
task.wait(0.5) -- a Phone_Choose reply, had one gone out, has landed by now (stale: the card would be closed)
assert(gui:GetAttribute("LastChoose") == "", "the dismiss on the NEWS went to the server (LastChoose '" .. tostring(gui:GetAttribute("LastChoose")) .. "'): a NEWS has nothing to choose")
assert(gui:GetAttribute("Open") == true and card.Visible and res.Visible and gui:GetAttribute("Card") == "news_spedup",
	"the NEWS result did not stay on screen (Open " .. tostring(gui:GetAttribute("Open")) .. ", Card '" .. tostring(gui:GetAttribute("Card")) .. "', LastChoose '" .. tostring(gui:GetAttribute("LastChoose")) .. "')")
assert(gui:GetAttribute("Choices") == 0, "a NEWS shows " .. tostring(gui:GetAttribute("Choices")) .. " choices")
assert(waitFor(function() return gui:GetAttribute("Open") == false end, P.NewsCloseSeconds + 1 - (os.clock() - tNews)), "the NEWS did not close by itself within " .. (P.NewsCloseSeconds + 1) .. " s")
local closedAfter = os.clock() - tNews
assert(gui:GetAttribute("Pending") == 0 and (gui:GetAttribute("Token") or "") == "" and not card.Visible, "after the NEWS: Pending " .. tostring(gui:GetAttribute("Pending")) .. ", Token '" .. tostring(gui:GetAttribute("Token")) .. "'")
assert(daw.Visible, "the beat maker closed")
table.insert(out, string.format("NEWS news_spedup opened from the icon over the beat maker, the dismiss ignored (LastChoose ''), result %s shown, closed by itself %.1f s after opening; Pending 0; beat maker open for t57c", tostring(gui:GetAttribute("ResultKey")), closedAfter))
return "T57B PLAY OK\n" .. table.concat(out, "\n")
