-- Client, during play (Wave 3 Task 4; design 4.2), after t78a's staging: the player is cold (the server's Cold attribute
-- true, BusyDay false, Quiet on, so no card shows). (1) Career.Cold, the COLD chip, shows: a TextLabel (nothing to tap)
-- reading "COLD" on Theme.muted, in the BUSY DAY chip's slot (Career.Busy's rect, Busy itself hidden), 4 px under the
-- pills, inside Career, clear of both pills and the HUD chip, and Career ends 24 px under the pills, as with BUSY DAY.
-- (2) The same with OK_UI forced to 667x375, 771x390 and 844x390 less this gui's insets, the chip inside the screen.
-- (3) At each of those sizes an Aura and a Followers move set here (local changes, set back after each) float under the
-- pills: every 0.05 s for 1.2 s neither float's rect overlaps the chip's (touching its edge is not overlap). (4) BusyDay set true here while Cold: BUSY DAY stays hidden and COLD shows (the two never
-- share the slot). (5) A cypher lobby (Phase set here) hides the chip and Career shrinks to the pills; idle, it is back.
-- (6) Cold set false here (warm) hides it within 0.5 s and Career shrinks; set back true, it returns. (7) The exit banner
-- t78a's thaws sent, LifeRules.Copy.ThawBanner, is in OK_UI's BannerLog. Everything this file changed is set back (Cold,
-- BusyDay and Phase to their replicated values, Aura and Followers to the values read just before step 3's writes, the
-- forced size cleared).
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui", 10)
local ui = pg:WaitForChild("OK_UI", 10); assert(ui, "no OK_UI")
local career = ui:WaitForChild("Career", 5); assert(career, "no Career pills")
local aura, followers, busy = career:FindFirstChild("Aura"), career:FindFirstChild("Followers"), career:FindFirstChild("Busy")
assert(aura and followers and busy, "Career pills Aura / Followers or the Busy chip missing")
local chip = career:FindFirstChild("Cold")
assert(chip and chip:IsA("TextLabel"), "no Career.Cold label, the COLD chip (before the Task 4 sync of Modules/HUD there is none: the expected red)")
local hudChip = ui:FindFirstChild("HUD")
local Theme = require(RS.OK.Modules.UITheme)
local THAW = require(RS.OK.Modules.LifeRules).Copy.ThawBanner
assert(type(THAW) == "string", "LifeRules.Copy.ThawBanner missing")
local cy = RS.OK:WaitForChild("Cypher", 5); assert(cy, "no RS.OK.Cypher")
local cam = workspace.CurrentCamera
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function rect(g) local p, s = g.AbsolutePosition - ui.AbsolutePosition, g.AbsoluteSize; return { x0 = p.X, y0 = p.Y, x1 = p.X + s.X, y1 = p.Y + s.Y } end
local function overlaps(a, b) return a.x0 < b.x1 and b.x0 < a.x1 and a.y0 < b.y1 and b.y0 < a.y1 end
local function fmt(r) return string.format("(%d,%d)-(%d,%d)", r.x0, r.y0, r.x1, r.y1) end
local function pillsBottom() return math.max(rect(aura).y1, rect(followers).y1) end
local function live() local o = {}; for _, c in ipairs(ui:GetChildren()) do if c.Name == "Float" and c:IsA("TextLabel") then table.insert(o, c) end end; return o end
ui:SetAttribute("ForceViewport", nil) -- never inherit a forced size from an earlier failed run
local was = { cold = nil, busy = player:GetAttribute("BusyDay"), phase = cy:GetAttribute("Phase"), aura = nil, followers = nil }
local out = {}

-- the chip's rules at the current layout; vp = the viewport the layout is for (nil: OK_UI's own size)
local function chipHolds(where, vp)
	local rc, rk, ra, rf = rect(career), rect(chip), rect(aura), rect(followers)
	local pills = math.max(ra.y1, rf.y1)
	assert(chip.Visible, where .. ": the COLD chip is hidden with Cold true")
	assert(chip.Text == "COLD", where .. ": the chip reads '" .. chip.Text .. "'")
	assert(chip.BackgroundColor3 == Theme.muted, where .. ": the chip is not Theme.muted")
	assert(not busy.Visible, where .. ": BUSY DAY shows beside COLD")
	-- BUSY DAY's slot: the same parent, position, size and anchor as Career.Busy (hidden, so its layout props, not its rect)
	assert(chip.Parent == busy.Parent and chip.Position == busy.Position and chip.Size == busy.Size and chip.AnchorPoint == busy.AnchorPoint,
		where .. ": the chip (" .. tostring(chip.Position) .. ", " .. tostring(chip.Size) .. ") is not in BUSY DAY's slot (" .. tostring(busy.Position) .. ", " .. tostring(busy.Size) .. ")")
	assert(rk.y0 == pills + 4, where .. ": the chip " .. fmt(rk) .. " should start 4 px under the pills (they end at " .. pills .. ")")
	assert(rk.x0 >= rc.x0 and rk.y0 >= rc.y0 and rk.x1 <= rc.x1 and rk.y1 <= rc.y1, where .. ": the chip " .. fmt(rk) .. " is outside Career " .. fmt(rc))
	assert(not overlaps(rk, ra) and not overlaps(rk, rf), where .. ": the chip " .. fmt(rk) .. " overlaps a pill (Aura " .. fmt(ra) .. ", Followers " .. fmt(rf) .. ")")
	if hudChip then assert(not overlaps(rk, rect(hudChip)), where .. ": the chip " .. fmt(rk) .. " overlaps the HUD " .. fmt(rect(hudChip))) end
	assert(rc.y1 == pills + 24, where .. ": Career " .. fmt(rc) .. " should end 24 px under the pills (they end at " .. pills .. ")")
	local size = vp or ui.AbsoluteSize
	assert(rk.x0 >= 0 and rk.y0 >= 0 and rk.x1 <= size.X and rk.y1 <= size.Y, where .. ": the chip " .. fmt(rk) .. " is off the screen (0,0)-(" .. size.X .. "," .. size.Y .. ")")
	return rc, rk
end

local function run()
	-- 1. the replicated Cold shows the chip
	assert(waitFor(function() return player:GetAttribute("Cold") == true end, 3), "Cold is " .. tostring(player:GetAttribute("Cold")) .. " (t78a's staging leaves the player cold)")
	was.cold = true -- the replicated value, set back at the end
	assert(waitFor(function() return chip.Visible end, 1), "the COLD chip did not show with Cold true")
	task.wait(0.1)
	local rc, rk = chipHolds("real " .. ui.AbsoluteSize.X .. "x" .. ui.AbsoluteSize.Y)
	table.insert(out, "real viewport: COLD " .. fmt(rk) .. " in BUSY DAY's slot inside Career " .. fmt(rc) .. ", 4 px under the pills, Theme.muted")

	-- 2 and 3. phone sizes (the screen minus this gui's real insets); at each the floats stay off the chip (touching its
	-- edge is not overlap: side by side, a float's rise ends exactly at the chip row's bottom, as t60b has it for BUSY DAY)
	local inset = cam.ViewportSize - ui.AbsoluteSize
	inset = Vector2.new(math.max(0, inset.X), math.max(0, inset.Y))
	assert(waitFor(function() return #live() == 0 end, 3), #live() .. " floats still on screen after 3 s")
	was.aura, was.followers = player:GetAttribute("Aura"), player:GetAttribute("Followers") -- the replicated values, set back
	for _, screen in ipairs({ Vector2.new(667, 375), Vector2.new(771, 390), Vector2.new(844, 390) }) do
		local vp = screen - inset
		local where = vp.X .. "x" .. vp.Y .. " (" .. screen.X .. "x" .. screen.Y .. " less " .. inset.X .. "x" .. inset.Y .. ")"
		ui:SetAttribute("ForceViewport", vp)
		task.wait(0.4)
		local ok, err = pcall(function()
			local rc2, rk2 = chipHolds(where, vp)
			assert(waitFor(function() return #live() == 0 end, 3), where .. ": " .. #live() .. " floats still on screen after 3 s")
			local n0 = ui:GetAttribute("Floats") or 0
			player:SetAttribute("Aura", (was.aura or 0) - 10)
			player:SetAttribute("Followers", (was.followers or 0) + 100)
			assert(waitFor(function() return (ui:GetAttribute("Floats") or 0) >= n0 + 2 end, 1), where .. ": no floats for Aura - 10 and Followers + 100")
			local floats = live()
			assert(#floats >= 2, where .. ": want 2 live floats, have " .. #floats)
			local t1, samples = os.clock(), 0
			while os.clock() - t1 < 1.2 do
				local rk3 = rect(chip)
				for _, f in ipairs(floats) do
					if f.Parent and chip.Visible then
						assert(not overlaps(rect(f), rk3), string.format("%s, %.2f s: the float '%s' %s overlaps the COLD chip %s", where, os.clock() - t1, f.Text, fmt(rect(f)), fmt(rk3)))
						samples += 1
					end
				end
				task.wait(0.05)
			end
			assert(samples >= 20, where .. ": only " .. samples .. " float samples beside the chip")
			table.insert(out, where .. ": COLD " .. fmt(rk2) .. " inside Career " .. fmt(rc2) .. "; the Aura and Followers floats stayed clear of it (" .. samples .. " samples)")
		end)
		-- set back here (the next size starts with no float on screen); a restore float rises too and is cleared above
		player:SetAttribute("Aura", was.aura)
		player:SetAttribute("Followers", was.followers)
		ui:SetAttribute("ForceViewport", nil)
		if not ok then error(err, 0) end
		task.wait(0.3)
	end

	-- 4. BusyDay true while cold: BUSY DAY stays hidden, COLD keeps the slot
	player:SetAttribute("BusyDay", true)
	task.wait(0.3)
	assert(chip.Visible and not busy.Visible, "BusyDay true while Cold: want COLD shown and BUSY DAY hidden (COLD " .. tostring(chip.Visible) .. ", BUSY DAY " .. tostring(busy.Visible) .. ")")
	player:SetAttribute("BusyDay", was.busy)
	table.insert(out, "BusyDay true while Cold: COLD keeps the slot, BUSY DAY hidden")

	-- 5. a cypher round hides it and Career shrinks back; idle again, it returns
	cy:SetAttribute("Phase", "lobby")
	assert(waitFor(function() return not chip.Visible end, 0.5), "the COLD chip still shows with the cypher in its lobby")
	task.wait(0.1)
	assert(rect(career).y1 == pillsBottom(), "Career " .. fmt(rect(career)) .. " did not shrink back to the pills (they end at " .. pillsBottom() .. ")")
	cy:SetAttribute("Phase", was.phase)
	assert(waitFor(function() return chip.Visible end, 0.5), "the COLD chip did not come back with the cypher idle")
	table.insert(out, "cypher lobby: the chip hid and Career shrank to the pills; idle again: back")

	-- 6. warm hides it
	player:SetAttribute("Cold", false)
	assert(waitFor(function() return not chip.Visible end, 0.5), "the COLD chip still shows 0.5 s after Cold went false")
	task.wait(0.1)
	assert(rect(career).y1 == pillsBottom(), "Career " .. fmt(rect(career)) .. " did not shrink back to the pills once warm")
	player:SetAttribute("Cold", true)
	assert(waitFor(function() return chip.Visible end, 0.5), "the COLD chip did not come back with Cold set back true")
	table.insert(out, "Cold false: the chip hid and Career shrank to the pills; true again: back")

	-- 7. the exit banner t78a's thaws sent went through the banner queue
	assert(waitFor(function() return string.find(ui:GetAttribute("BannerLog") or "", THAW, 1, true) ~= nil end, 12),
		"the exit banner '" .. string.gsub(THAW, "\n", " / ") .. "' is not in BannerLog: " .. string.gsub(tostring(ui:GetAttribute("BannerLog")), "\n", " / "))
	table.insert(out, "BannerLog holds the exit banner '" .. string.gsub(THAW, "\n", " / ") .. "'")
end

local ok, err = pcall(run)
ui:SetAttribute("ForceViewport", nil)
cy:SetAttribute("Phase", was.phase)
if was.aura ~= nil then player:SetAttribute("Aura", was.aura) end
if was.followers ~= nil then player:SetAttribute("Followers", was.followers) end
player:SetAttribute("BusyDay", was.busy)
if was.cold ~= nil then player:SetAttribute("Cold", was.cold) end
if not ok then error(err, 0) end
return "T78B PLAY OK\n" .. table.concat(out, "\n")
