-- Client, during play (Wave 1b Task 4; Review Focus 3: stats change in lumps): the HUD's per-stat floats and pill
-- pops, driven by this client setting its own stat attributes (a client's change never replicates); the server's
-- values are set back at the end. (1) The five stats are the baseline. (2) Aura -50 and Followers +1,500 in one frame:
-- FloatLog gains aura|-50 AURA at the Aura pill's x and followers|+1.5K FOLLOWERS at the Followers pill's x, and each
-- live float is in Theme.stat's colour for its stat. (3) Placements, Hits and Sponsors +1 each: +1 PLACEMENT, +1 HIT and
-- +1 SPONSOR in the Aura column; no two entries in one column share a y within 1.2 s. (4) Aura set to its own value:
-- no float within 1 s. (5) All five stats in one frame, Aura and Followers again 0.1 s later (seven floats inside
-- 1.2 s, the Weekly Single's density): seven entries, and no slot is reused within a chain while its float shows
-- (live labels sampled by their Slot attribute; a chain holds 6, so a seventh in one column takes the oldest's slot as
-- it goes). (6) A change pops its pill: Pops grows, Aura.Pop.UIScale.Scale passes 1.02 within 0.3 s, and the Aura and
-- Followers rects never change (sampled every 0.03 s). (7) OK_UI forced to 667x375 and 844x390 minus this gui's insets:
-- the floats after the force start at the pills' bottom + 30 or lower (96 stacked, 66 side by side), in that layout's
-- column (350 stacked; 350 and 470 side by side) and left of FIRE's (x < vp.X - 152); stacked, their labels are as
-- before Task 6 (140 wide, TextSize 16, not scaled, no UITextSizeConstraint). (8, Task 6) Side by side (the real
-- viewport, or 844x390 minus the insets when the real one stacks the pills), settled: Placements +2 and Followers
-- +1,500 in one frame put "+2 PLACEMENTS" and "+1.5K FOLLOWERS" in slot 0 of their columns on one y; the Aura-column
-- label's text ends at least 4 px left of the Followers label (AbsolutePosition.X + TextBounds.X) and fits its width
-- (TextBounds.X <= AbsoluteSize.X); that label is narrowed (Followers' x - Aura's x - 4 wide) and scaled
-- (TextScaled, UITextSizeConstraint MaxTextSize 16); the Followers label is as before Task 6. (9, Task H; two sessions
-- Task 5) The LEVEL UP banner draws over the floats: it is OK_LevelUp.LevelUp, in its own ScreenGui, and
-- OK_LevelUp.DisplayOrder is above OK_UI's, where the newest float lives (OK_UI has no LevelUp); a queued banner (Wave 2,
-- PanelCommand "banner:<text>") shows there while that float is live, at the box t68 pins. (10, Task H) At
-- 667x375 minus the insets, RS.OK.Cypher's Phase set to "reveal" here (a local change) drops the cypher bar under the stacked pills,
-- over the float column (checked: it reaches x 350..490 at the chain's y 96); Aura + 25 then floats under the bar:
-- the newest aura float's rect, read as it appears, doesn't intersect OK_Cypher.Bar's (a float rises 6 px through its
-- 1.3 s, so its start is what is checked). (11, Task H final read) At 800x450 minus the insets the pills sit side
-- by side but the bar still drops under them (CypherUI keeps it beside the pills only from about 932 px): Aura and
-- Followers + 25 in one frame both float under the bar, neither rect intersecting it. Phase and the stats are set back.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui", 10)
local ui = pg:WaitForChild("OK_UI", 10); assert(ui, "no OK_UI")
local career = ui:WaitForChild("Career", 5); assert(career, "no Career pills")
local aura, followers = career:FindFirstChild("Aura"), career:FindFirstChild("Followers")
assert(aura and followers, "Career pills Aura / Followers missing")
local Theme = require(RS.OK.Modules.UITheme)
assert(typeof(Theme.aura) == "Color3" and type(Theme.stat) == "table", "UITheme has no aura / stat colours")
local cy = RS.OK:WaitForChild("Cypher", 5); assert(cy, "no RS.OK.Cypher")
local cyGui = pg:WaitForChild("OK_Cypher", 10); assert(cyGui, "no OK_Cypher gui (CypherUI.Build did not run?)")
local cam = workspace.CurrentCamera
local STATS = { "Aura", "Followers", "Placements", "Hits", "Sponsors" }
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
-- rects in OK_UI's space
local function rect(g) local p, s = g.AbsolutePosition - ui.AbsolutePosition, g.AbsoluteSize; return { x0 = p.X, y0 = p.Y, x1 = p.X + s.X, y1 = p.Y + s.Y } end
local function same(a, b) return a.x0 == b.x0 and a.y0 == b.y0 and a.x1 == b.x1 and a.y1 == b.y1 end
local function overlaps(a, b) return a.x0 < b.x1 and b.x0 < a.x1 and a.y0 < b.y1 and b.y0 < a.y1 end
local function fmt(r) return string.format("(%d,%d)-(%d,%d)", r.x0, r.y0, r.x1, r.y1) end
local function get(k) return player:GetAttribute(k) end
-- stats set in one frame (no yield between them)
local function set(t) for _, k in ipairs(STATS) do if t[k] ~= nil then player:SetAttribute(k, t[k]) end end end
local function floats() return ui:GetAttribute("Floats") or 0 end
-- the FloatLog entries added since the Floats count was `since` (every float is counted and logged; the log keeps 12)
local function added(since)
	local log = {}
	for item in string.gmatch(ui:GetAttribute("FloatLog") or "", "[^;]+") do
		local stat, text, x, y = string.match(item, "^([^|]*)|([^|]*)|(%-?%d+)|(%-?%d+)$")
		assert(stat, "FloatLog entry '" .. item .. "' is not stat|text|x|y")
		table.insert(log, { stat = stat, text = text, x = tonumber(x), y = tonumber(y) })
	end
	local n = floats() - since
	assert(n <= #log, n .. " floats since the mark, but FloatLog holds " .. #log)
	local out = {}
	for i = #log - n + 1, #log do table.insert(out, log[i]) end
	return out
end
-- waits for n floats after the mark; their entries
local function expect(since, n, what, t)
	assert(waitFor(function() return floats() - since >= n end, t or 1), what .. ": want " .. n .. " floats, got " .. (floats() - since))
	return added(since)
end
local function entry(list, stat) for _, e in ipairs(list) do if e.stat == stat then return e end end end
local function show(list) local s = {}; for _, e in ipairs(list) do table.insert(s, e.stat .. "|" .. e.text .. "|" .. e.x .. "|" .. e.y) end; return table.concat(s, "; ") end
-- the float labels on screen
local function live() local o = {}; for _, c in ipairs(ui:GetChildren()) do if c.Name == "Float" and c:IsA("TextLabel") then table.insert(o, c) end end; return o end
local function settle() assert(waitFor(function() return #live() == 0 end, 2), #live() .. " floats still on screen after 2 s") end
-- nil when a float label is as before Task 6 (140 wide, TextSize 16, not scaled, no UITextSizeConstraint), else how not
local function unlike(f)
	local cap = f:FindFirstChildOfClass("UITextSizeConstraint")
	if f.Size.X.Offset == 140 and f.TextSize == 16 and not f.TextScaled and not cap then return nil end
	return string.format("'%s' is %s wide, TextSize %s, TextScaled %s, %s (want 140, 16, false, none)", f.Text,
		tostring(f.Size.X.Offset), tostring(f.TextSize), tostring(f.TextScaled), cap and "a UITextSizeConstraint" or "no constraint")
end
local function colours(what)
	for _, f in ipairs(live()) do
		local s = f:GetAttribute("Stat")
		if s then assert(f.TextColor3 == Theme.stat[s], what .. ": the " .. s .. " float '" .. f.Text .. "' is " .. tostring(f.TextColor3) .. ", want " .. tostring(Theme.stat[s])) end
	end
end
-- entries with the time they were seen: no two in one column share a y within 1.2 s
local seen = {}
local function note(list) local t = os.clock(); for _, e in ipairs(list) do e.t = t; table.insert(seen, e) end end
local function noSharedY(what)
	for i = 1, #seen do
		for j = i + 1, #seen do
			local a, b = seen[i], seen[j]
			if a.x == b.x and math.abs(a.t - b.t) < 1.2 then
				assert(a.y ~= b.y, what .. ": '" .. a.text .. "' and '" .. b.text .. "' share y " .. a.y .. " in column " .. a.x .. " within 1.2 s")
			end
		end
	end
end

-- 1. the baseline (the server's values, set back at the end)
local base = {}
for _, k in ipairs(STATS) do
	base[k] = get(k)
	assert(type(base[k]) == "number", k .. " is " .. tostring(base[k]) .. " (the profile has not published?)")
end
-- never inherit a forced size from an earlier failed run
ui:SetAttribute("ForceViewport", nil)
local phase0 = cy:GetAttribute("Phase") -- set back at the end
task.wait(0.4)
local out = {}

local function run()
	settle()
	local auraX, follX = rect(aura).x0, rect(followers).x0 -- the pill columns at the real viewport

	-- 2. Aura -50 and Followers +1,500 in one frame
	local c = floats()
	set({ Aura = base.Aura - 50, Followers = base.Followers + 1500 })
	local e = expect(c, 2, "Aura -50 / Followers +1500")
	note(e)
	local ea, ef = entry(e, "aura"), entry(e, "followers")
	assert(ea and ea.text == "-50 AURA" and ea.x == auraX, "want aura|-50 AURA at x " .. auraX .. ", got " .. show(e))
	assert(ef and ef.text == "+1.5K FOLLOWERS" and ef.x == follX, "want followers|+1.5K FOLLOWERS at x " .. follX .. ", got " .. show(e))
	local n = { aura = 0, followers = 0 }
	for _, f in ipairs(live()) do local s = f:GetAttribute("Stat"); if n[s] then n[s] += 1 end end
	assert(n.aura >= 1 and n.followers >= 1, "no live aura / followers float label (aura " .. n.aura .. ", followers " .. n.followers .. ")")
	colours("Aura / Followers")
	table.insert(out, "Aura -50, Followers +1500: " .. show(e) .. ", each in its stat colour")

	-- 3. the pill-less stats float in the Aura column
	c = floats()
	set({ Placements = base.Placements + 1, Hits = base.Hits + 1, Sponsors = base.Sponsors + 1 })
	e = expect(c, 3, "Placements / Hits / Sponsors +1")
	note(e)
	for _, want in ipairs({ { "placements", "+1 PLACEMENT" }, { "hits", "+1 HIT" }, { "sponsors", "+1 SPONSOR" } }) do
		local x = entry(e, want[1])
		assert(x and x.text == want[2] and x.x == auraX, "want " .. want[1] .. "|" .. want[2] .. " in the Aura column (x " .. auraX .. "), got " .. show(e))
	end
	colours("Placements / Hits / Sponsors")
	noSharedY("steps 2-3")
	table.insert(out, "Placements, Hits, Sponsors +1: " .. show(e) .. "; no column shares a y within 1.2 s")

	-- 4. a same-value write floats nothing
	settle()
	c = floats()
	player:SetAttribute("Aura", get("Aura"))
	task.wait(1)
	assert(floats() == c, "Aura set to its own value floated: " .. show(added(c)))
	table.insert(out, "Aura set to its own value: no float in 1 s")

	-- 5. seven floats inside 1.2 s
	c = floats()
	local t0 = os.clock()
	set({ Aura = get("Aura") - 20, Followers = get("Followers") + 20, Placements = get("Placements") + 1, Hits = get("Hits") + 1, Sponsors = get("Sponsors") + 1 })
	task.wait(0.1)
	set({ Aura = get("Aura") + 5, Followers = get("Followers") + 5 })
	e = expect(c, 7, "the Weekly Single's seven", math.max(0.1, 1.2 - (os.clock() - t0)))
	local took = os.clock() - t0
	assert(#e == 7, "want 7 new FloatLog entries, got " .. #e .. ": " .. show(e))
	local byX = {}
	for _, x in ipairs(e) do byX[x.x] = byX[x.x] or {}; table.insert(byX[x.x], x) end
	for x, list in pairs(byX) do -- a chain holds 6: past that the newest take the oldest's slots (as they go)
		local ys = {}
		for i = math.max(1, #list - 5), #list do
			assert(not ys[list[i].y], "column " .. x .. ": two of the seven share y " .. list[i].y .. " (" .. show(list) .. ")")
			ys[list[i].y] = true
		end
	end
	local samples, peak = 0, 0
	local t1 = os.clock()
	while os.clock() - t1 < 1.2 do
		local slots, count = {}, 0
		for _, f in ipairs(live()) do
			assert(f:GetAttribute("Slot") ~= nil, "the float '" .. f.Text .. "' has no Slot attribute")
			local k = f.Position.X.Offset .. ":" .. tostring(f:GetAttribute("Slot"))
			assert(not slots[k], string.format("%.2f s: two live floats share slot %s (column:slot)", os.clock() - t1, k))
			slots[k] = true; count += 1
		end
		samples += 1; peak = math.max(peak, count)
		task.wait(0.05)
	end
	table.insert(out, string.format("seven floats in %.2f s: %s; no live slot shared (%d samples, up to %d live)", took, show(e), samples, peak))

	-- 6. the pill pop: Pops grows, the ring scales, the pill rects stay put
	settle()
	local pop = aura:FindFirstChild("Pop")
	local scale = pop and pop:FindFirstChild("UIScale")
	assert(scale and scale:IsA("UIScale"), "the Aura pill has no Pop.UIScale")
	assert(followers:FindFirstChild("Pop"), "the Followers pill has no Pop")
	local ra0, rf0 = rect(aura), rect(followers)
	local p0 = ui:GetAttribute("Pops") or 0
	set({ Aura = get("Aura") + 7, Followers = get("Followers") + 7 })
	local tp, top, moved = os.clock(), 1, nil
	while os.clock() - tp < 0.6 do
		if os.clock() - tp <= 0.3 then top = math.max(top, scale.Scale) end
		local ra, rf = rect(aura), rect(followers)
		if not same(ra, ra0) then moved = "Aura " .. fmt(ra0) .. " -> " .. fmt(ra) end
		if not same(rf, rf0) then moved = "Followers " .. fmt(rf0) .. " -> " .. fmt(rf) end
		task.wait(0.03)
	end
	local pops = (ui:GetAttribute("Pops") or 0) - p0
	assert(pops >= 2, "Pops grew by " .. pops .. " for an Aura and a Followers change")
	local lp = ui:GetAttribute("LastPop")
	assert(lp == "aura" or lp == "followers", "LastPop is '" .. tostring(lp) .. "'")
	assert(top > 1.02, string.format("Aura.Pop.UIScale.Scale peaked at %.3f within 0.3 s (want > 1.02)", top))
	assert(not moved, "a pill's rect changed during the pop: " .. tostring(moved))
	assert(math.abs(scale.Scale - 1) < 0.001, string.format("Aura.Pop.UIScale.Scale is %.3f after the pop", scale.Scale))
	table.insert(out, string.format("pop: Pops +%d (LastPop %s), Aura ring peak %.3f in 0.3 s, back to 1; pills %s %s unchanged", pops, lp, top, fmt(ra0), fmt(rf0)))

	-- 7. forced phone sizes: a phone's screen minus the insets this gui really has
	local inset = cam.ViewportSize - ui.AbsoluteSize
	inset = Vector2.new(math.max(0, inset.X), math.max(0, inset.Y))
	for _, screen in ipairs({ Vector2.new(667, 375), Vector2.new(844, 390) }) do
		local vp = screen - inset
		local where = vp.X .. "x" .. vp.Y .. " (" .. screen.X .. "x" .. screen.Y .. " less " .. inset.X .. "x" .. inset.Y .. ")"
		ui:SetAttribute("ForceViewport", vp)
		task.wait(0.4)
		local ra, rf = rect(aura), rect(followers)
		local stacked = rf.y0 >= ra.y1
		local bottom = math.max(ra.y1, rf.y1)
		c = floats()
		set({ Aura = get("Aura") - 3, Followers = get("Followers") + 3 })
		e = expect(c, 2, where)
		for _, x in ipairs(e) do
			local col = (x.stat == "followers") and rf.x0 or ra.x0
			assert(x.y >= bottom + 30, where .. ": " .. x.text .. " starts at y " .. x.y .. ", want >= the pills' bottom " .. bottom .. " + 30")
			assert(x.x == col, where .. ": " .. x.text .. " at x " .. x.x .. ", want its column " .. col .. (stacked and " (stacked)" or " (side by side)"))
			assert(x.x < vp.X - 152, where .. ": " .. x.text .. " at x " .. x.x .. " is in FIRE's column (from " .. (vp.X - 152) .. ")")
		end
		if stacked then -- one column, nothing narrows: the new floats (by stat and text) are as before Task 6
			for _, x in ipairs(e) do
				local n = 0
				for _, f in ipairs(live()) do
					if f:GetAttribute("Stat") == x.stat and f.Text == x.text then
						n += 1
						local diff = unlike(f)
						assert(not diff, where .. " (stacked): " .. tostring(diff))
					end
				end
				assert(n >= 1, where .. ": no live label for '" .. x.text .. "'")
			end
		end
		table.insert(out, where .. ": pills " .. (stacked and "stacked" or "side by side") .. " (bottom " .. bottom .. "), floats " .. show(e)
			.. (stacked and " (140 wide, not scaled)" or ""))
		ui:SetAttribute("ForceViewport", nil)
		task.wait(0.4)
	end

	-- 8. side by side, an Aura-column float never runs into the Followers float on its row (at the real viewport, or
	--    the 844 phone when the real one stacks the pills)
	settle()
	local forced = nil
	if rect(followers).y0 >= rect(aura).y1 then
		forced = Vector2.new(844, 390) - inset
		ui:SetAttribute("ForceViewport", forced)
		task.wait(0.4)
	end
	local where = forced and (forced.X .. "x" .. forced.Y .. " (844x390 less " .. inset.X .. "x" .. inset.Y .. ")")
		or ("real " .. ui.AbsoluteSize.X .. "x" .. ui.AbsoluteSize.Y)
	local ra, rf = rect(aura), rect(followers)
	assert(rf.y0 < ra.y1, where .. ": the pills are stacked (Aura " .. fmt(ra) .. ", Followers " .. fmt(rf) .. "), want side by side")
	c = floats()
	set({ Placements = get("Placements") + 2, Followers = get("Followers") + 1500 })
	e = expect(c, 2, where .. ": Placements +2 / Followers +1500")
	local ep, ef = entry(e, "placements"), entry(e, "followers")
	assert(ep and ep.text == "+2 PLACEMENTS" and ep.x == ra.x0, where .. ": want placements|+2 PLACEMENTS at x " .. ra.x0 .. ", got " .. show(e))
	assert(ef and ef.text == "+1.5K FOLLOWERS" and ef.x == rf.x0, where .. ": want followers|+1.5K FOLLOWERS at x " .. rf.x0 .. ", got " .. show(e))
	assert(ep.y == ef.y, where .. ": the two floats are not on one row: " .. show(e))
	local lp, lf
	for _, f in ipairs(live()) do
		if f:GetAttribute("Stat") == "placements" and f.Text == ep.text then lp = f end
		if f:GetAttribute("Stat") == "followers" and f.Text == ef.text then lf = f end
	end
	assert(lp and lf, where .. ": no live label for '" .. ep.text .. "' or '" .. ef.text .. "'")
	assert(lp:GetAttribute("Slot") == 0 and lf:GetAttribute("Slot") == 0, where .. ": want both in slot 0, got " .. tostring(lp:GetAttribute("Slot"))
		.. " and " .. tostring(lf:GetAttribute("Slot")))
	task.wait(0.1) -- a scaled text's TextBounds settle a frame after the label draws
	assert(waitFor(function() return lp.TextBounds.X > 0 and lf.TextBounds.X > 0 end, 0.5), where .. ": the labels' TextBounds stayed 0")
	local pEnd, fX = lp.AbsolutePosition.X + lp.TextBounds.X, lf.AbsolutePosition.X
	assert(pEnd <= fX - 4, string.format("%s: '%s' (x %.1f, %.1f wide) ends at x %.1f, into '%s' at x %.1f (want <= %.1f)",
		where, lp.Text, lp.AbsolutePosition.X, lp.TextBounds.X, pEnd, lf.Text, fX, fX - 4))
	-- the Aura-column float is narrowed (to 4 px short of the Followers column) and scales, capped at 16, so its text
	-- fits; the Followers-column float is as before Task 6 (its text may still run past its 140 px)
	assert(lp.TextBounds.X <= lp.AbsoluteSize.X, string.format("%s: '%s' is %.1f px of text in a %.1f px label", where, lp.Text, lp.TextBounds.X, lp.AbsoluteSize.X))
	local cap = lp:FindFirstChildOfClass("UITextSizeConstraint")
	assert(lp.Size.X.Offset == ef.x - ep.x - 4 and lp.TextScaled and cap and cap.MaxTextSize == 16, string.format(
		"%s: '%s' is %s wide (want %d), TextScaled %s, UITextSizeConstraint MaxTextSize %s (want true, 16)", where, lp.Text,
		tostring(lp.Size.X.Offset), ef.x - ep.x - 4, tostring(lp.TextScaled), cap and tostring(cap.MaxTextSize) or "none"))
	local diff = unlike(lf)
	assert(not diff, where .. " (the Followers column): " .. tostring(diff))
	table.insert(out, string.format("%s: '%s' (label %.1f, text %.1f, scaled) ends %.1f px left of '%s' (label %.1f, text %.1f, not scaled), both in slot 0 at y %d",
		where, lp.Text, lp.AbsoluteSize.X, lp.TextBounds.X, fX - pEnd, lf.Text, lf.AbsoluteSize.X, lf.TextBounds.X, ep.y))
	if forced then ui:SetAttribute("ForceViewport", nil); task.wait(0.4) end

	-- 9. (Task H; two sessions Task 5) the LEVEL UP banner draws over the floats: its own ScreenGui is above OK_UI
	settle()
	local lv = pg:WaitForChild("OK_LevelUp", 5)
	assert(lv and lv:IsA("ScreenGui"), "no PlayerGui.OK_LevelUp ScreenGui (before the Task 5 sync of Modules/HUD the banner is OK_UI.LevelUp)")
	local banner = lv:FindFirstChild("LevelUp")
	assert(banner and banner:IsA("GuiObject"), "no OK_LevelUp.LevelUp banner")
	assert(ui:FindFirstChild("LevelUp") == nil, "OK_UI still holds a LevelUp banner beside OK_LevelUp's")
	c = floats()
	set({ Aura = get("Aura") + 1 })
	e = expect(c, 1, "Aura +1")
	local ef9 = entry(e, "aura")
	local f9
	for _, f in ipairs(live()) do if f:GetAttribute("Stat") == "aura" and ef9 and f.Text == ef9.text then f9 = f end end
	assert(f9 and f9:IsDescendantOf(ui), "no live label in OK_UI for the newest float (" .. show(e) .. ")")
	assert(lv.DisplayOrder > ui.DisplayOrder, string.format("OK_LevelUp's DisplayOrder %d is not above OK_UI's %d, where the newest float '%s' is",
		lv.DisplayOrder, ui.DisplayOrder, f9.Text))
	ui:SetAttribute("PanelCommand", "banner:T62 BANNER")
	assert(waitFor(function() return ui:GetAttribute("PanelCommand") == "" end, 6), "PanelCommand banner: was not taken (Studio seam missing?)")
	assert(waitFor(function() return banner.Visible and banner.Text == "T62 BANNER" end, 8), "a queued banner did not show: '" .. banner.Text .. "'")
	assert(banner.AbsoluteSize == Vector2.new(420, 64), "the banner's box is " .. tostring(banner.AbsoluteSize))
	table.insert(out, string.format("LEVEL UP banner in OK_LevelUp (DisplayOrder %d) over OK_UI (%d), where the newest float '%s' is; a queued banner shows there at 420x64",
		lv.DisplayOrder, ui.DisplayOrder, f9.Text))

	-- 10. (Task H) on a phone the cypher bar drops under the stacked pills, over the float column: a float starts under it
	settle()
	local vp = Vector2.new(667, 375) - inset
	local where10 = vp.X .. "x" .. vp.Y .. " (667x375 less " .. inset.X .. "x" .. inset.Y .. ")"
	ui:SetAttribute("ForceViewport", vp)
	cy:SetAttribute("Phase", "reveal")
	task.wait(0.4)
	local bar = cyGui:FindFirstChild("Bar")
	assert(bar and bar:IsA("GuiObject") and bar.Visible, where10 .. ": the cypher bar is missing or hidden with Phase reveal")
	local pa, pf = rect(aura), rect(followers)
	local rb = rect(bar)
	local y96 = math.max(pa.y1, pf.y1) + 30 -- the chain's first y without the bar
	assert(pf.y0 >= pa.y1, where10 .. ": the pills are side by side (Aura " .. fmt(pa) .. ", Followers " .. fmt(pf) .. "), want stacked")
	-- the bar must sit over the column (x pa.x0 .. pa.x0 + 140, the float's width stacked) at the chain's first y, or
	-- this step tests nothing
	assert(rb.x0 < pa.x0 + 140 and rb.x1 > pa.x0 and rb.y0 <= y96 and rb.y1 > y96, string.format("%s: the cypher bar %s isn't over the Aura"
		.. " column (x %d..%d) at y %d, so this step can't test the fix", where10, fmt(rb), pa.x0, pa.x0 + 140, y96))
	c = floats()
	set({ Aura = get("Aura") + 25 })
	e = expect(c, 1, where10 .. ": Aura +25")
	local ef10 = entry(e, "aura")
	local f10
	for _, f in ipairs(live()) do if f:GetAttribute("Stat") == "aura" and ef10 and f.Text == ef10.text then f10 = f end end
	assert(f10, where10 .. ": no live label for the newest aura float (" .. show(e) .. ")")
	local rf10 = rect(f10)
	assert(rf10.x1 > rf10.x0 and rf10.y1 > rf10.y0, where10 .. ": the float '" .. f10.Text .. "' has no size yet " .. fmt(rf10))
	assert(not overlaps(rf10, rect(bar)), string.format("%s: the float '%s' %s (logged at y %d) intersects the cypher bar %s", where10, f10.Text,
		fmt(rf10), ef10.y, fmt(rect(bar))))
	table.insert(out, string.format("%s, cypher bar %s (Phase reveal): '%s' starts at %s (logged y %d), under the bar, not on it",
		where10, fmt(rb), f10.Text, fmt(rf10), ef10.y))
	cy:SetAttribute("Phase", phase0)
	ui:SetAttribute("ForceViewport", nil)
	task.wait(0.4)

	-- 11. (Task H, final read) side by side below about 932 px the cypher bar also drops under the pills, over both
	-- columns: both chains start under it
	settle()
	local vp11 = Vector2.new(800, 450) - inset
	local where11 = vp11.X .. "x" .. vp11.Y .. " (800x450 less " .. inset.X .. "x" .. inset.Y .. ")"
	ui:SetAttribute("ForceViewport", vp11)
	cy:SetAttribute("Phase", "reveal")
	task.wait(0.4)
	local bar11 = cyGui:FindFirstChild("Bar")
	assert(bar11 and bar11:IsA("GuiObject") and bar11.Visible, where11 .. ": the cypher bar is missing or hidden with Phase reveal")
	local pa11, pf11, rb11 = rect(aura), rect(followers), rect(bar11)
	assert(pf11.y0 < pa11.y1, where11 .. ": the pills are stacked (Aura " .. fmt(pa11) .. ", Followers " .. fmt(pf11) .. "), want side by side")
	local yRow = math.max(pa11.y1, pf11.y1) + 30 -- the chains' first y without the bar
	-- the bar must lie over both columns' first row (y yRow .. yRow + 22, HUD's own test), or this step tests nothing
	assert(rb11.x0 < pa11.x0 + 116 and rb11.x1 > pf11.x0 and rb11.y0 < yRow + 22 and rb11.y1 > yRow, string.format("%s: the cypher bar %s"
		.. " isn't over both columns' first row (y %d..%d), so this step can't test the fix", where11, fmt(rb11), yRow, yRow + 22))
	c = floats()
	set({ Aura = get("Aura") + 25, Followers = get("Followers") + 25 })
	e = expect(c, 2, where11 .. ": Aura +25, Followers +25")
	local got = {}
	for _, stat in ipairs({ "aura", "followers" }) do
		local ef = entry(e, stat)
		local lf
		for _, f in ipairs(live()) do if f:GetAttribute("Stat") == stat and ef and f.Text == ef.text then lf = f end end
		assert(lf, where11 .. ": no live label for the newest " .. stat .. " float (" .. show(e) .. ")")
		local rf = rect(lf)
		assert(rf.x1 > rf.x0 and rf.y1 > rf.y0, where11 .. ": the float '" .. lf.Text .. "' has no size yet " .. fmt(rf))
		assert(not overlaps(rf, rect(bar11)), string.format("%s: the %s float '%s' %s intersects the cypher bar %s", where11, stat,
			lf.Text, fmt(rf), fmt(rect(bar11))))
		table.insert(got, string.format("'%s' at %s", lf.Text, fmt(rf)))
	end
	table.insert(out, string.format("%s, side by side, cypher bar %s under the pills: %s, both under the bar", where11, fmt(rb11),
		table.concat(got, "; ")))
	cy:SetAttribute("Phase", phase0)
	ui:SetAttribute("ForceViewport", nil)
	task.wait(0.4)
end

local ok, err = pcall(run)
cy:SetAttribute("Phase", phase0)
ui:SetAttribute("ForceViewport", nil)
task.wait(0.4)
set(base)
if not ok then error(err, 0) end
for _, k in ipairs(STATS) do assert(get(k) == base[k], k .. " was not set back to " .. base[k]) end
return "T62 PLAY OK\n" .. table.concat(out, "\n")
