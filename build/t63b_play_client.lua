-- Client, during play (Wave 1b Task 5; Review Focus 5), after t63a's tail: Aura 0, money 0 and scam_curator popped with
-- Quiet off, so the DM opens by itself. Each card's footer is read by its path, OK_Phone.Root.Card.Footer and
-- OK_WalkIn.Root.Card.Footer (never a recursive "Footer": PanelUI has its own); the walk-in card is not on screen, its
-- footer follows all the same. (1) At Aura 0 both read today's line; Aura set here (a local change) to -10, 100 and 400
-- and both follow within 0.5 s: the red line, today's line, the loud line. (2) With OK_UI and OK_Phone forced to
-- 667x375 minus this gui's insets and the DM open, for each band (the Aura changed while the card is open): the phone
-- footer follows within 0.5 s, the card stays inside the box, every choice and DISMISS is 44 px or more, and
-- Footer.TextFits. (3) Still at 667: "Pay the fee." ($200 at money 0) shows the can't-afford note; an Aura change while
-- the note shows leaves the note; about 4 s after the tap the footer reads the new Aura's band line again, and still
-- fits. DISMISS closes the DM. Everything this file changed is set back (Aura to its replicated value, the forced sizes
-- cleared, the DM dismissed).
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character; local hum = char:WaitForChild("Humanoid", 5); local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui", 10)
local phone = pg:WaitForChild("OK_Phone", 10); assert(phone, "no OK_Phone gui (PhoneUI.Build did not run?)")
local wg = pg:WaitForChild("OK_WalkIn", 10); assert(wg, "no OK_WalkIn gui")
local ui = pg:WaitForChild("OK_UI", 10); assert(ui, "no OK_UI")
local daw = pg:WaitForChild("OK_DAW", 10):WaitForChild("DAW", 10); assert(daw, "no beat maker gui")
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function rect(g) local p, s = g.AbsolutePosition - phone.AbsolutePosition, g.AbsoluteSize; return { x0 = p.X, y0 = p.Y, x1 = p.X + s.X, y1 = p.Y + s.Y } end
local function fmt(r) return string.format("(%d,%d)-(%d,%d)", r.x0, r.y0, r.x1, r.y1) end
local function footerOf(g) -- Root.Card.Footer, by its path
	local root = g:FindFirstChild("Root"); local card = root and root:FindFirstChild("Card")
	local f = card and card:FindFirstChild("Footer")
	assert(f and f:IsA("TextLabel"), g.Name .. ": no Root.Card.Footer label")
	return f, card
end
local RED = "Your Aura's in the red. People hesitate. Odds stay hidden."
local TODAY = "Your Aura and Followers tilt the odds. You never see them."
local LOUD = "Your Aura's loud. People lean in. Odds stay hidden."
local NOTE = "Not enough money for that one yet"
local BANDS = { { aura = -10, line = RED, name = "red" }, { aura = 100, line = TODAY, name = "today's" }, { aura = 400, line = LOUD, name = "loud" } }
local DM = "scam_curator"
-- never inherit a forced size or an open beat maker from an earlier failed run
ui:SetAttribute("ForceViewport", nil); phone:SetAttribute("ForceViewport", nil); wg:SetAttribute("ForceViewport", nil)
if daw.Visible then daw:SetAttribute("Command", "close"); task.wait(0.4) end
if hum.Sit then hum.Sit = false; task.wait(0.4) end
local was = { aura = player:GetAttribute("Aura") }
local out = {}

local function run()
	assert(waitFor(function() return player:GetAttribute("Cred") == 0 end, 3), "Cred is " .. tostring(player:GetAttribute("Cred")) .. " (t63a sets money 0)")
	assert(waitFor(function() return phone:GetAttribute("Open") == true end, 5), "the DM did not open by itself within 5 s (Pending "
		.. tostring(phone:GetAttribute("Pending")) .. ", Deferred " .. tostring(phone:GetAttribute("Deferred")) .. ")")
	assert(phone:GetAttribute("Card") == DM, "the open card is '" .. tostring(phone:GetAttribute("Card")) .. "', not t63a's " .. DM)
	local pf, card = footerOf(phone)
	local wf = footerOf(wg)
	assert(card.Visible, "the phone's Card is hidden while Open")

	-- 1. both footers by band, at the real viewport
	assert(waitFor(function() return pf.Text == TODAY and wf.Text == TODAY end, 0.5), "at Aura " .. tostring(player:GetAttribute("Aura"))
		.. " the footers read '" .. pf.Text .. "' (phone) and '" .. wf.Text .. "' (walk-in), want today's line")
	for _, b in ipairs(BANDS) do
		player:SetAttribute("Aura", b.aura)
		assert(waitFor(function() return pf.Text == b.line and wf.Text == b.line end, 0.5), "Aura " .. b.aura .. ": the footers read '"
			.. pf.Text .. "' (phone) and '" .. wf.Text .. "' (walk-in) after 0.5 s, want the " .. b.name .. " line")
	end
	table.insert(out, "real viewport: at Aura 0 both footers read today's line; -10, 100, 400 -> red, today's, loud in both within 0.5 s")

	-- 2. at 667x375 less the insets, the DM open: each band fits
	local inset = cam.ViewportSize - ui.AbsoluteSize
	inset = Vector2.new(math.max(0, inset.X), math.max(0, inset.Y))
	local vp = Vector2.new(667, 375) - inset
	local where = vp.X .. "x" .. vp.Y .. " (667x375 less " .. inset.X .. "x" .. inset.Y .. ")"
	ui:SetAttribute("ForceViewport", vp); phone:SetAttribute("ForceViewport", vp)
	task.wait(0.6) -- the HUD re-lays the pills at once; PhoneUI re-lays the card when its top changes (0.2 s)
	local function holds(label)
		local r = rect(card)
		assert(r.x0 >= 0 and r.y0 >= 0 and r.x1 <= vp.X and r.y1 <= vp.Y, label .. ": the card " .. fmt(r) .. " is outside (0,0)-(" .. vp.X .. "," .. vp.Y .. ")")
		local n = phone:GetAttribute("Choices")
		assert(type(n) == "number" and n > 0, label .. ": the DM shows no choices (Choices " .. tostring(n) .. ")")
		for i = 1, n do
			local b = card:FindFirstChild("Choice" .. i, true)
			assert(b and b.Visible and b.AbsoluteSize.X >= 44 and b.AbsoluteSize.Y >= 44, label .. ": Choice" .. i .. " missing, hidden or under 44 px")
		end
		local d = card:FindFirstChild("Dismiss")
		assert(d and d.Visible and d.AbsoluteSize.X >= 44 and d.AbsoluteSize.Y >= 44, label .. ": DISMISS missing, hidden or under 44 px")
		assert(pf.TextFits, label .. ": the footer '" .. pf.Text .. "' doesn't fit its " .. pf.AbsoluteSize.X .. "x" .. pf.AbsoluteSize.Y .. " box")
		return r
	end
	for _, b in ipairs(BANDS) do
		player:SetAttribute("Aura", b.aura)
		assert(waitFor(function() return pf.Text == b.line end, 0.5), where .. ", Aura " .. b.aura .. ": the open card's footer reads '" .. pf.Text
			.. "' after 0.5 s, want the " .. b.name .. " line")
		task.wait(0.2) -- one render, so TextFits and the rects are current
		local r = holds(where .. ", Aura " .. b.aura)
		table.insert(out, string.format("%s, Aura %d: the %s line fits (%dx%d), card %s inside, buttons >= 44 px", where, b.aura, b.name,
			pf.AbsoluteSize.X, pf.AbsoluteSize.Y, fmt(r)))
	end

	-- 3. the refusal note, then the band line again (Aura is 400 now; it changes to -10 under the note)
	phone:SetAttribute("LastChoose", "")
	local tTap = os.clock()
	phone:SetAttribute("Command", "choose:1")
	assert(waitFor(function() return phone:GetAttribute("LastChoose") == "afford" end, 1), "'Pay the fee.' at money 0: LastChoose is '"
		.. tostring(phone:GetAttribute("LastChoose")) .. "', want 'afford'")
	assert(pf.Text == NOTE, "the can't-afford note did not show: the footer reads '" .. pf.Text .. "'")
	player:SetAttribute("Aura", -10)
	task.wait(0.3)
	assert(pf.Text == NOTE, "an Aura change replaced the note: the footer reads '" .. pf.Text .. "'")
	assert(waitFor(function() return pf.Text == RED end, 5), "5 s after the tap the footer reads '" .. pf.Text .. "', want the red line (Aura -10)")
	local back = os.clock() - tTap
	assert(back >= 3.5, string.format("the band line came back %.1f s after the tap: the note should hold about 4 s", back))
	task.wait(0.2)
	local r = holds(where .. ", after the note")
	table.insert(out, string.format("%s: 'Pay the fee.' -> the note; Aura -10 under it kept the note; the red line back %.1f s after the tap, fits, card %s inside",
		where, back, fmt(r)))

	ui:SetAttribute("ForceViewport", nil); phone:SetAttribute("ForceViewport", nil)
	phone:SetAttribute("LastChoose", "")
	phone:SetAttribute("Command", "dismiss")
	assert(waitFor(function() return phone:GetAttribute("Open") == false and phone:GetAttribute("LastChoose") == "ok" end, 5),
		"dismiss did not close the DM (Open " .. tostring(phone:GetAttribute("Open")) .. ", LastChoose " .. tostring(phone:GetAttribute("LastChoose")) .. ")")
	table.insert(out, "DISMISS closed the DM")
end

local ok, err = pcall(run)
ui:SetAttribute("ForceViewport", nil); phone:SetAttribute("ForceViewport", nil)
if phone:GetAttribute("Open") == true then phone:SetAttribute("Command", "dismiss") end
player:SetAttribute("Aura", was.aura)
if not ok then error(err, 0) end
return "T63B PLAY OK\n" .. table.concat(out, "\n")
