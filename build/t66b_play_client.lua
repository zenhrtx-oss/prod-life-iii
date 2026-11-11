-- Client, during play (two sessions Task 5; Review Focus 1), after t66a's tail: the Phone XP count cleared, Quiet off,
-- two_sessions popped and opened on the server, the DM left open. Sounds are read from OK_UI's SoundLog / Sounds /
-- LastSound (CardFeel), floats from OK_UI's Floats / FloatLog (HUD). (1) The DM opens here: t66a's tail pops right after
-- the hometown kid's walk-in card was walked away, and PhoneUI holds a pop while a walk-in card or its result shows
-- (about 8 s), so this waits up to 20 s for Open with Card two_sessions; Quiet was on through t66a's body, so the
-- phone holds exactly this one pop (Pending 1). (2) With OK_UI and OK_Phone forced to 667x375, 771x390 (an 844x390
-- phone less a 73 px notch; 771x332 in Studio) and 844x390, each minus this gui's insets: Choices 2, Choice1 and
-- Choice2 shown and 44 px or more, Choice3 and Choice4 hidden, DISMISS 44 px or more and inside the box, and the card
-- inside the box; and, with Scroll.CanvasPosition at (0,0) (the final review, 2026-10-30: the 146-character line
-- pushed choice 2 below the fold): at 771x332 and 844x332 both choices are fully visible without scrolling (top at or
-- under Scroll's top, bottom at or above its visible bottom); at 667x317 the middle scrolls, as for every DM (a PhoneUI
-- layout change is out of scope), so Choice1 is fully visible and Choice2's top is inside Scroll's visible rect.
-- (3) Back at the real viewport, choice 1 (the hometown kid, sure): ResultKey
-- home; the inline result's chips, read by their path OK_Phone.Root.Card.Scroll.Result.Chips, are exactly
-- Chip1 "+40 XP" and Chip2 "+100 FOLLOWERS", and Chip1's TextColor3 is Theme.stat.xp (an orange of its own, not the
-- gold an unknown kind falls back to); the SoundLog ends Win,Plant within 1.5 s (Plant 0.5 s after the result: the
-- tail's WalkIns Reset emptied the queue, so the kid is planted again); the HUD's FloatLog gains an entry
-- "|+40 XP|x|y" (stat empty: the +XP float) within 2 s of the choice. Then, forced to 667x375 minus the insets with
-- Scroll.CanvasPosition at (0,0), the result's Note label (OK_Phone.Root.Card.Scroll.Result.Note) is shown, and whether
-- its bottom is at or above Scroll's visible bottom is recorded as a measurement only (reported, never failed); the
-- real viewport again. OK closes the result. The six choice checks (three sizes x two choices) are recorded as they
-- run and asserted together at the end, so a failing run still reports every measurement.
-- Everything this file changed is set back (the forced sizes, MuteMonitors, no card left open).
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character; local hum = char:WaitForChild("Humanoid", 5); local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui", 10)
local phone = pg:WaitForChild("OK_Phone", 10); assert(phone, "no OK_Phone gui (PhoneUI.Build did not run?)")
local ui = pg:WaitForChild("OK_UI", 10); assert(ui, "no OK_UI")
local daw = pg:WaitForChild("OK_DAW", 10):WaitForChild("DAW", 10); assert(daw, "no beat maker gui")
local Theme = require(RS.OK.Modules.UITheme)
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function rect(g) local p, s = g.AbsolutePosition - phone.AbsolutePosition, g.AbsoluteSize; return { x0 = p.X, y0 = p.Y, x1 = p.X + s.X, y1 = p.Y + s.Y } end
local function fmt(r) return string.format("(%d,%d)-(%d,%d)", r.x0, r.y0, r.x1, r.y1) end
local function soundLog() local o = {}; for k in string.gmatch(ui:GetAttribute("SoundLog") or "", "[^,]+") do table.insert(o, k) end; return o end
local function sounds() return tonumber(ui:GetAttribute("Sounds")) or 0 end
local function newest(n) local l = soundLog(); local o = {}; for i = math.max(1, #l - n + 1), #l do table.insert(o, l[i]) end; return o end
local function floats() return ui:GetAttribute("Floats") or 0 end
-- the FloatLog entries added since the Floats count was `since` (t62's reading: every float is counted and logged; the
-- log keeps 12)
local function added(since)
	local log = {}
	for item in string.gmatch(ui:GetAttribute("FloatLog") or "", "[^;]+") do
		local stat, text, x, y = string.match(item, "^([^|]*)|([^|]*)|(%-?%d+)|(%-?%d+)$")
		assert(stat, "FloatLog entry '" .. item .. "' is not stat|text|x|y")
		table.insert(log, { stat = stat, text = text, x = tonumber(x), y = tonumber(y) })
	end
	local n = math.min(floats() - since, #log)
	local out = {}
	for i = #log - n + 1, #log do table.insert(out, log[i]) end
	return out
end
local function show(list) local s = {}; for _, e in ipairs(list) do table.insert(s, e.stat .. "|" .. e.text) end; return table.concat(s, "; ") end
local CARD = "two_sessions"
-- never inherit a forced size or an open beat maker from an earlier failed run
ui:SetAttribute("ForceViewport", nil); phone:SetAttribute("ForceViewport", nil)
if daw.Visible then daw:SetAttribute("Command", "close"); task.wait(0.4) end
if hum.Sit then hum.Sit = false; task.wait(0.4) end
local was = { mute = player:GetAttribute("MuteMonitors") }
local out = {}

-- the card's buttons and rect at the current (forced) viewport vp
local function holds(where, vp)
	local card = phone.Root.Card
	local r = rect(card)
	assert(r.x0 >= 0 and r.y0 >= 0 and r.x1 <= vp.X and r.y1 <= vp.Y, where .. ": the card " .. fmt(r) .. " is outside (0,0)-(" .. vp.X .. "," .. vp.Y .. ")")
	assert(phone:GetAttribute("Choices") == 2, where .. ": Choices is " .. tostring(phone:GetAttribute("Choices")) .. ", want 2")
	for i = 1, 4 do
		local b = card:FindFirstChild("Choice" .. i, true)
		assert(b and b:IsA("GuiButton"), where .. ": no Choice" .. i .. " button")
		if i <= 2 then
			assert(b.Visible and b.AbsoluteSize.X >= 44 and b.AbsoluteSize.Y >= 44, string.format("%s: Choice%d is %s, %dx%d (want shown, 44 px or more)",
				where, i, b.Visible and "shown" or "hidden", b.AbsoluteSize.X, b.AbsoluteSize.Y))
		else
			assert(not b.Visible, where .. ": Choice" .. i .. " shows on a two-choice card")
		end
	end
	local d = card:FindFirstChild("Dismiss")
	assert(d and d.Visible and d.AbsoluteSize.X >= 44 and d.AbsoluteSize.Y >= 44, where .. ": DISMISS missing, hidden or under 44 px")
	assert(d.Text == "DISMISS", where .. ": the footer button reads '" .. d.Text .. "', want DISMISS")
	local rd = rect(d)
	assert(rd.x0 >= 0 and rd.y0 >= 0 and rd.x1 <= vp.X and rd.y1 <= vp.Y, where .. ": DISMISS " .. fmt(rd) .. " is outside the box")
	return r
end

-- with the scrolling middle at the top (CanvasPosition (0,0)), the GuiObject `g` (named `what`) against Scroll's
-- visible rect. `need` "full": its top at or under Scroll's top and its bottom at or above Scroll's visible bottom;
-- "top": its top inside the visible rect (at or under Scroll's top, above its bottom); "measure": recorded only. Every
-- "full" / "top" check goes into `visible` (not asserted on the spot), so one run measures every size; run() asserts
-- them all at its end
local visible = {}
local function unscrolled(where, scroll, what, g, need)
	scroll.CanvasPosition = Vector2.new(0, 0)
	task.wait(0.1)
	local rs, rg = rect(scroll), rect(g)
	local full = rg.y0 >= rs.y0 and rg.y1 <= rs.y1
	local held = full
	if need == "top" then held = rg.y0 >= rs.y0 and rg.y0 < rs.y1 end
	local verdict = full and "fully visible" or (rg.y0 >= rs.y0 and rg.y0 < rs.y1) and "top visible, bottom below the fold"
		or "NOT visible without scrolling"
	local detail = string.format("%s %s, Scroll %s (visible %d..%d), CanvasSize.Y %d, CanvasPosition.Y %d: %s (want %s)", what, fmt(rg), fmt(rs),
		rs.y0, rs.y1, scroll.AbsoluteCanvasSize.Y, scroll.CanvasPosition.Y, verdict, need)
	if need ~= "measure" then table.insert(visible, { held = held, text = where .. ": " .. detail }) end
	return held, detail
end

local function run()
	assert(was.mute ~= true, "MuteMonitors is on at the start: the result's sounds would not log")
	-- 1. the DM opens here once the walk-in's card has gone
	assert(waitFor(function() return phone:GetAttribute("Open") == true and phone:GetAttribute("Card") == CARD end, 20), "the DM did not open"
		.. " within 20 s (Open " .. tostring(phone:GetAttribute("Open")) .. ", Card '" .. tostring(phone:GetAttribute("Card")) .. "', Pending "
		.. tostring(phone:GetAttribute("Pending")) .. ", Deferred " .. tostring(phone:GetAttribute("Deferred")) .. ")")
	assert(phone:GetAttribute("Pending") == 1, "Pending is " .. tostring(phone:GetAttribute("Pending")) .. ", want 1 (only t66a's tail pop)")
	assert(phone.Root.Card.Visible, "the phone's Card is hidden while Open")
	table.insert(out, "the DM opened (" .. CARD .. ", Pending 1, token " .. tostring(phone:GetAttribute("Token")) .. ")")

	-- 2. three phone sizes: two choices plus DISMISS, 44 px or more, inside the box; both choices visible unscrolled
	local inset = cam.ViewportSize - ui.AbsoluteSize
	inset = Vector2.new(math.max(0, inset.X), math.max(0, inset.Y))
	local scroll = phone.Root.Card.Scroll
	-- 771x390 is an 844x390 phone less a 73 px notch (771x332 in Studio). At 667 the middle scrolls (as for every DM):
	-- choice 1 fully visible, choice 2's top in view; at the two wider sizes both choices fully visible
	for _, screen in ipairs({ Vector2.new(667, 375), Vector2.new(771, 390), Vector2.new(844, 390) }) do
		local vp = screen - inset
		local where = vp.X .. "x" .. vp.Y .. " (" .. screen.X .. "x" .. screen.Y .. " less " .. inset.X .. "x" .. inset.Y .. ")"
		ui:SetAttribute("ForceViewport", vp); phone:SetAttribute("ForceViewport", vp)
		task.wait(0.6) -- the HUD re-lays the pills at once; PhoneUI re-lays the card when its top changes (0.2 s)
		local r = holds(where, vp)
		local _, d1 = unscrolled(where, scroll, "Choice1", scroll:FindFirstChild("Choice1"), "full")
		local _, d2 = unscrolled(where, scroll, "Choice2", scroll:FindFirstChild("Choice2"), screen.X == 667 and "top" or "full")
		table.insert(out, string.format("%s: two choices and DISMISS, each 44 px or more, card %s inside; unscrolled: %s; %s", where,
			fmt(r), d1, d2))
	end
	ui:SetAttribute("ForceViewport", nil); phone:SetAttribute("ForceViewport", nil)
	task.wait(0.6)

	-- 3. choice 1: the +40 XP chip in Theme.stat.xp, Win then Plant, the +40 XP float
	assert(typeof(Theme.stat.xp) == "Color3", "UITheme has no stat.xp colour (before the Task 5 sync of Modules/UITheme: the expected red)")
	assert(Theme.stat.xp ~= Theme.gold and Theme.stat.xp ~= Theme.accent2, "Theme.stat.xp is the gold fallback or the cold loss colour")
	local s0, f0 = sounds(), floats()
	phone:SetAttribute("ResultKey", ""); phone:SetAttribute("LastChoose", "")
	phone:SetAttribute("Command", "choose:1")
	assert(waitFor(function() return phone:GetAttribute("ResultKey") == "home" end, 6), "choice 1: ResultKey '" .. tostring(phone:GetAttribute("ResultKey"))
		.. "', LastChoose '" .. tostring(phone:GetAttribute("LastChoose")) .. "', want home")
	local chips = phone.Root.Card.Scroll.Result.Chips
	local c1, c2 = chips:FindFirstChild("Chip1"), chips:FindFirstChild("Chip2")
	local list = {}
	for i = 1, 8 do local c = chips:FindFirstChild("Chip" .. i); if c then table.insert(list, c.Text) end end
	assert(c1 and c2 and c1.Text == "+40 XP" and c2.Text == "+100 FOLLOWERS" and #list == 2, "the inline result's chips are ["
		.. table.concat(list, ", ") .. "], want [+40 XP, +100 FOLLOWERS]")
	assert(c1.TextColor3 == Theme.stat.xp, "the +40 XP chip is " .. tostring(c1.TextColor3) .. ", want Theme.stat.xp " .. tostring(Theme.stat.xp))
	assert(c1.Visible and c1.AbsoluteSize.X > 0, "the +40 XP chip is not on screen")
	table.insert(out, "choice 1: home, chips [" .. table.concat(list, ", ") .. "], +40 XP in Theme.stat.xp " .. tostring(Theme.stat.xp))
	assert(waitFor(function() return sounds() >= s0 + 2 and table.concat(newest(2), ",") == "Win,Plant" end, 1.5), "within 1.5 s of the result the"
		.. " log ends '" .. table.concat(newest(3), ",") .. "' (" .. (sounds() - s0) .. " new sounds), want Win,Plant")
	table.insert(out, "sounds since the choice: " .. table.concat(newest(sounds() - s0), ","))
	local xpFloat
	assert(waitFor(function()
		for _, e in ipairs(added(f0)) do if e.stat == "" and e.text == "+40 XP" then xpFloat = e; return true end end
		return false
	end, 2), "no '+40 XP' float within 2 s of the choice: FloatLog gained " .. show(added(f0)))
	table.insert(out, string.format("the HUD floated '+40 XP' at (%d, %d); floats since the choice: %s", xpFloat.x, xpFloat.y, show(added(f0))))

	-- the result's note at 667x375 (minus the insets), unscrolled: a measurement (reported, never failed)
	local vp = Vector2.new(667, 375) - inset
	local where = vp.X .. "x" .. vp.Y .. " (667x375 less " .. inset.X .. "x" .. inset.Y .. "), the result"
	ui:SetAttribute("ForceViewport", vp); phone:SetAttribute("ForceViewport", vp)
	task.wait(0.6)
	local noteL = scroll.Result.Note
	assert(phone:GetAttribute("ResultKey") == "home" and phone:GetAttribute("Open") == true, where .. ": the result closed before the note check")
	assert(noteL.Visible and noteL.Text ~= "", where .. ": the result's Note is hidden or empty ('" .. noteL.Text .. "')")
	local _, noteDetail = unscrolled(where, scroll, "the Note '" .. noteL.Text .. "'", noteL, "measure")
	table.insert(out, where .. " (measured, not asserted): " .. noteDetail)
	ui:SetAttribute("ForceViewport", nil); phone:SetAttribute("ForceViewport", nil)
	task.wait(0.6)

	phone:SetAttribute("Command", "ok")
	assert(waitFor(function() return phone:GetAttribute("Open") == false end, 2), "OK did not close the result")

	-- every choice check (three sizes x two choices), asserted together so one run reports all
	local missed = {}
	for _, v in ipairs(visible) do if not v.held then table.insert(missed, v.text) end end
	assert(#visible == 6, "want 6 unscrolled choice checks (3 sizes x 2 choices), made " .. #visible)
	local all = {}
	for _, v in ipairs(visible) do table.insert(all, v.text) end
	assert(#missed == 0, #missed .. " of " .. #visible .. " unscrolled checks failed: " .. table.concat(missed, " || ") .. " || ALL: " .. table.concat(all, " || "))
end

local ok, err = pcall(run)
ui:SetAttribute("ForceViewport", nil); phone:SetAttribute("ForceViewport", nil)
player:SetAttribute("MuteMonitors", was.mute)
if phone:GetAttribute("Open") == true then phone:SetAttribute("Command", "ok") end
if not ok then error(err, 0) end
return "T66B PLAY OK\n" .. table.concat(out, "\n")
