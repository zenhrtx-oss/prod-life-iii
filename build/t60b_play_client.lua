-- Client, during play (Wave 1b Task 4; Review Focus 2), after t60a's tail: a burst under way (BusyDay true, set by the
-- server) and scam_curator popped with Quiet off, so the phone card opens by itself. (1) Career.Busy shows and reads
-- "BUSY DAY", inside Career's rect 4 px under the pills and clear of both, and Career ends 24 px under the pills. (2) The
-- same with OK_UI and OK_Phone forced to 667x375 and 844x390 minus this gui's insets; at 667 the DM's card stays inside
-- the box, its buttons are 44 px or more and its top is Career's bottom + 8 (98: the stacked pills end at 66, the chip
-- at 90). (Task H) Still at 667, the DM armed: BusyDay set false here moves the card up within 0.5 s, and the moved
-- card is re-armed (OK_Phone's Armed false when it is seen moved, true again 0.7 s later); BusyDay set back true.
-- DISMISS closes it. (3) RS.OK.Cypher's Phase set to "lobby" here (a local change) hides the chip and Career shrinks
-- back to the pills; set back, the chip returns. (4) BusyDay set false here, then Aura - 10 and BusyDay true in one
-- frame: every 0.05 s for 1.2 s the new float's rect stays clear of the chip's. (5) BusyDay false here hides it within
-- 0.5 s. Everything this file changed is set back (BusyDay and Phase to their replicated values, Aura to the value read
-- just before step 4's write, the forced sizes cleared, the DM dismissed).
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui", 10)
local ui = pg:WaitForChild("OK_UI", 10); assert(ui, "no OK_UI")
local phone = pg:WaitForChild("OK_Phone", 10); assert(phone, "no OK_Phone gui (PhoneUI.Build did not run?)")
local career = ui:WaitForChild("Career", 5); assert(career, "no Career pills")
local aura, followers, busy = career:FindFirstChild("Aura"), career:FindFirstChild("Followers"), career:FindFirstChild("Busy")
assert(aura and followers, "Career pills Aura / Followers missing")
assert(busy and busy:IsA("TextLabel"), "no Career.Busy label (the BUSY DAY chip)")
local cy = RS.OK:WaitForChild("Cypher", 5); assert(cy, "no RS.OK.Cypher")
local cam = workspace.CurrentCamera
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
-- rects in a gui's own space (OK_UI's unless given): OK_UI and OK_Phone share CoreUISafeInsets
local function rect(g, space) local p, s = g.AbsolutePosition - (space or ui).AbsolutePosition, g.AbsoluteSize; return { x0 = p.X, y0 = p.Y, x1 = p.X + s.X, y1 = p.Y + s.Y } end
local function overlaps(a, b) return a.x0 < b.x1 and b.x0 < a.x1 and a.y0 < b.y1 and b.y0 < a.y1 end
local function fmt(r) return string.format("(%d,%d)-(%d,%d)", r.x0, r.y0, r.x1, r.y1) end
local function pillsBottom() return math.max(rect(aura).y1, rect(followers).y1) end
local function live() local o = {}; for _, c in ipairs(ui:GetChildren()) do if c.Name == "Float" and c:IsA("TextLabel") then table.insert(o, c) end end; return o end
-- never inherit a forced size from an earlier failed run
ui:SetAttribute("ForceViewport", nil); phone:SetAttribute("ForceViewport", nil)
local was = { busy = player:GetAttribute("BusyDay"), aura = nil, phase = cy:GetAttribute("Phase") } -- aura: read at step 4
local out = {}

-- the chip's rules at the current layout
local function chipHolds(where)
	local rc, rb, ra, rf = rect(career), rect(busy), rect(aura), rect(followers)
	local pills = math.max(ra.y1, rf.y1)
	assert(busy.Visible, where .. ": the chip is hidden with BusyDay true")
	assert(busy.Text == "BUSY DAY", where .. ": the chip reads '" .. busy.Text .. "'")
	assert(rb.y0 == pills + 4, where .. ": the chip " .. fmt(rb) .. " should start 4 px under the pills (they end at " .. pills .. ")")
	assert(rb.x0 >= rc.x0 and rb.y0 >= rc.y0 and rb.x1 <= rc.x1 and rb.y1 <= rc.y1, where .. ": the chip " .. fmt(rb) .. " is outside Career " .. fmt(rc))
	assert(not overlaps(rb, ra) and not overlaps(rb, rf), where .. ": the chip " .. fmt(rb) .. " overlaps a pill (Aura " .. fmt(ra) .. ", Followers " .. fmt(rf) .. ")")
	assert(rc.y1 == pills + 24, where .. ": Career " .. fmt(rc) .. " should end 24 px under the pills (they end at " .. pills .. ")")
	return rc, rb
end
-- the DM card's buttons: every choice and DISMISS at least 44 px
local function buttons(card, where)
	local n = phone:GetAttribute("Choices")
	assert(type(n) == "number" and n > 0, where .. ": the DM shows no choices (Choices " .. tostring(n) .. ")")
	for i = 1, n do
		local b = card:FindFirstChild("Choice" .. i, true)
		assert(b and b.Visible and b.AbsoluteSize.X >= 44 and b.AbsoluteSize.Y >= 44, where .. ": Choice" .. i .. " missing, hidden or under 44 px")
	end
	local d = card:FindFirstChild("Dismiss", true)
	assert(d and d.Visible and d.AbsoluteSize.X >= 44 and d.AbsoluteSize.Y >= 44, where .. ": DISMISS missing, hidden or under 44 px")
end

local function run()
	-- 1. the replicated BusyDay shows the chip
	assert(waitFor(function() return player:GetAttribute("BusyDay") == true end, 3), "BusyDay is " .. tostring(player:GetAttribute("BusyDay"))
		.. " (t60a's tail leaves a burst running)")
	was.busy = true -- the replicated value, set back at the end
	assert(waitFor(function() return busy.Visible end, 1), "the chip did not show with BusyDay true")
	task.wait(0.1)
	local rc, rb = chipHolds("real " .. ui.AbsoluteSize.X .. "x" .. ui.AbsoluteSize.Y)
	table.insert(out, "real viewport: BUSY DAY " .. fmt(rb) .. " inside Career " .. fmt(rc) .. ", 4 px under the pills")

	-- 2. forced phone sizes (the screen minus this gui's real insets), with the DM open
	assert(waitFor(function() return phone:GetAttribute("Open") == true end, 5), "the DM did not open by itself within 5 s (Pending "
		.. tostring(phone:GetAttribute("Pending")) .. ", Deferred " .. tostring(phone:GetAttribute("Deferred")) .. ")")
	assert(phone:GetAttribute("Card") == "scam_curator", "the open card is '" .. tostring(phone:GetAttribute("Card")) .. "', not t60a's scam_curator")
	local card = phone:FindFirstChild("Card", true)
	assert(card and card.Visible, "the phone's Card frame is missing or hidden while Open")
	local inset = cam.ViewportSize - ui.AbsoluteSize
	inset = Vector2.new(math.max(0, inset.X), math.max(0, inset.Y))
	for _, screen in ipairs({ Vector2.new(667, 375), Vector2.new(844, 390) }) do
		local vp = screen - inset
		local where = vp.X .. "x" .. vp.Y .. " (" .. screen.X .. "x" .. screen.Y .. " less " .. inset.X .. "x" .. inset.Y .. ")"
		ui:SetAttribute("ForceViewport", vp); phone:SetAttribute("ForceViewport", vp)
		task.wait(0.6) -- the HUD re-lays the pills at once; PhoneUI re-lays the card when its top changes (0.2 s)
		local ok, err = pcall(function()
			local rc2, rb2 = chipHolds(where)
			local line = where .. ": BUSY DAY " .. fmt(rb2) .. " inside Career " .. fmt(rc2)
			if screen.X == 667 then
				local cr, careerR = rect(card, phone), rect(career, phone)
				assert(cr.x0 >= 0 and cr.y0 >= 0 and cr.x1 <= vp.X and cr.y1 <= vp.Y, where .. ": the DM card " .. fmt(cr) .. " is outside (0,0)-(" .. vp.X .. "," .. vp.Y .. ")")
				buttons(card, where)
				assert(cr.y0 == careerR.y1 + 8 and cr.y0 == 98, where .. ": the DM card's top is " .. cr.y0 .. ", want Career's bottom " .. careerR.y1 .. " + 8 (98)")
				line = line .. "; the DM card " .. fmt(cr) .. " inside, buttons >= 44 px, top " .. cr.y0 .. " = Career's bottom + 8"
				-- (Task H) the chip going moves the card up under a finger: it re-arms, then arms again after ARM_SECONDS
				assert(waitFor(function() return phone:GetAttribute("Armed") == true end, 1), where .. ": the open DM is not armed before the chip goes (Armed "
					.. tostring(phone:GetAttribute("Armed")) .. ")")
				local top0 = cr.y0
				player:SetAttribute("BusyDay", false)
				local tFlip, seenAt, armedThen = os.clock(), nil, nil
				while os.clock() - tFlip < 0.5 do -- every frame: the moment the card is seen moved, and Armed then
					if rect(card, phone).y0 < top0 then seenAt = os.clock(); armedThen = phone:GetAttribute("Armed"); break end
					task.wait()
				end
				if not seenAt and rect(card, phone).y0 < top0 then seenAt = os.clock(); armedThen = phone:GetAttribute("Armed") end
				assert(seenAt, string.format("%s: 0.5 s after BusyDay went false the DM card's top is %d, want it above %d (moved up)", where, rect(card, phone).y0, top0))
				local top1 = rect(card, phone).y0
				assert(armedThen == false, string.format("%s: the card moved up (%d -> %d, %.2f s after the flip) but Armed is %s, want false (re-armed)",
					where, top0, top1, seenAt - tFlip, tostring(armedThen)))
				task.wait(math.max(0, seenAt + 0.7 - os.clock()))
				assert(phone:GetAttribute("Armed") == true, where .. ": Armed is " .. tostring(phone:GetAttribute("Armed")) .. " 0.7 s after the card moved, want true")
				player:SetAttribute("BusyDay", true)
				assert(waitFor(function() return busy.Visible end, 0.5), where .. ": the chip did not come back with BusyDay set back true")
				line = line .. string.format("; BusyDay false moved it up %d -> %d (seen %.2f s after the flip) and re-armed it (Armed false, true 0.7 s later)",
					top0, top1, seenAt - tFlip)
			end
			table.insert(out, line)
		end)
		ui:SetAttribute("ForceViewport", nil); phone:SetAttribute("ForceViewport", nil)
		if not ok then error(err, 0) end
		task.wait(0.4)
	end
	phone:SetAttribute("LastChoose", "")
	phone:SetAttribute("Command", "dismiss")
	assert(waitFor(function() return phone:GetAttribute("Open") == false and phone:GetAttribute("LastChoose") == "ok" end, 5),
		"dismiss did not close the DM (Open " .. tostring(phone:GetAttribute("Open")) .. ", LastChoose " .. tostring(phone:GetAttribute("LastChoose")) .. ")")
	table.insert(out, "DISMISS closed the DM")

	-- 3. a cypher round hides the chip and Career shrinks back; idle again, it returns
	cy:SetAttribute("Phase", "lobby")
	assert(waitFor(function() return not busy.Visible end, 0.5), "the chip still shows with the cypher in its lobby")
	task.wait(0.1)
	assert(rect(career).y1 == pillsBottom(), "Career " .. fmt(rect(career)) .. " did not shrink back to the pills (they end at " .. pillsBottom() .. ")")
	cy:SetAttribute("Phase", was.phase)
	assert(waitFor(function() return busy.Visible end, 0.5), "the chip did not come back with the cypher idle (Phase " .. tostring(was.phase) .. ")")
	task.wait(0.1)
	chipHolds("cypher idle again")
	table.insert(out, "cypher lobby: the chip hid and Career shrank to the pills; idle again: back")

	-- 4. a float and the chip appearing in one frame: the float never lands on the chip
	player:SetAttribute("BusyDay", false)
	assert(waitFor(function() return not busy.Visible end, 0.5), "the chip still shows with BusyDay false")
	assert(waitFor(function() return #live() == 0 end, 2), #live() .. " floats still on screen after 2 s")
	local c = ui:GetAttribute("Floats") or 0
	was.aura = player:GetAttribute("Aura") -- the value set back at the end (read just before this file writes it)
	player:SetAttribute("Aura", was.aura - 10)
	player:SetAttribute("BusyDay", true)
	assert(waitFor(function() return (ui:GetAttribute("Floats") or 0) > c end, 1), "no float for Aura - 10")
	local f -- the only float on screen: none showed before the change
	for _, x in ipairs(live()) do if x:GetAttribute("Stat") == "aura" then f = x end end
	assert(f, "no live aura float after Aura - 10")
	assert(waitFor(function() return busy.Visible end, 0.5), "the chip did not show with BusyDay true")
	local t1, samples = os.clock(), 0
	while os.clock() - t1 < 1.2 do
		if f.Parent and busy.Visible then
			local rf, rb = rect(f), rect(busy)
			assert(not overlaps(rf, rb), string.format("%.2f s: the float '%s' %s overlaps the chip %s", os.clock() - t1, f.Text, fmt(rf), fmt(rb)))
			samples += 1
		end
		task.wait(0.05)
	end
	assert(samples >= 10, "only " .. samples .. " samples of the float beside the chip")
	table.insert(out, "Aura - 10 with the chip: the float '" .. f.Text .. "' stayed clear of the chip " .. fmt(rect(busy)) .. " (" .. samples .. " samples)")

	-- 5. BusyDay false hides it
	player:SetAttribute("BusyDay", false)
	assert(waitFor(function() return not busy.Visible end, 0.5), "the chip still shows 0.5 s after BusyDay went false")
	task.wait(0.1)
	assert(rect(career).y1 == pillsBottom(), "Career " .. fmt(rect(career)) .. " did not shrink back to the pills")
	table.insert(out, "BusyDay false: the chip hid")
end

local ok, err = pcall(run)
ui:SetAttribute("ForceViewport", nil); phone:SetAttribute("ForceViewport", nil)
if phone:GetAttribute("Open") == true then phone:SetAttribute("Command", "dismiss") end
cy:SetAttribute("Phase", was.phase)
if was.aura ~= nil then player:SetAttribute("Aura", was.aura) end
player:SetAttribute("BusyDay", was.busy)
if not ok then error(err, 0) end
return "T60B PLAY OK\n" .. table.concat(out, "\n")
