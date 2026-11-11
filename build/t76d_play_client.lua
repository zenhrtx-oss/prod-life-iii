-- Client, during play (Wave 3 Task 2 fix round 1; design 4.5), after t76c: navx_placement open without a hint, its
-- choice 3's roll forced good. (1) The card's hint line (Hint, found under the card) is hidden at zero size and takes no
-- space: the card ends its top padding under its last footer row (12 px, 6 on a screen under 420 px tall): WALK AWAY's,
-- or, since Wave 3 Task 3, the beat line (Card.BeatLine) under it, which navx_placement carries. (2) choose:3 lands
-- clout (CLOUT: "New followers"), and the result card shows its hint, OK_WalkIn.Root.Result.Hint: shown, Mark "i", Label
-- the Config.Hints text for followers, Label.TextFits, the line inside the result card and under OK, the result card
-- inside the gui, at the real viewport and forced to 667x375 less this gui's insets. OK closes it. Everything this file
-- changed is set back (the forced size; nothing left open).
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui", 10)
local wg = pg:WaitForChild("OK_WalkIn", 10); assert(wg, "no OK_WalkIn gui (WalkInUI.Build did not run?)")
local daw = pg:WaitForChild("OK_DAW", 10):WaitForChild("DAW", 10); assert(daw, "no beat maker gui")
local Config = require(RS.OK.Config)
local CARD = "navx_placement"
local FOLLOWERS
for _, h in ipairs(Config.Hints) do if h.term == "followers" then FOLLOWERS = h.text end end
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function rel(g) local p, s = g.AbsolutePosition - wg.AbsolutePosition, g.AbsoluteSize; return { x0 = p.X, y0 = p.Y, x1 = p.X + s.X, y1 = p.Y + s.Y } end
local function within(a, b) return a.x0 >= b.x0 and a.y0 >= b.y0 and a.x1 <= b.x1 and a.y1 <= b.y1 end
local function fmt(r) return string.format("(%d,%d)-(%d,%d)", r.x0, r.y0, r.x1, r.y1) end
wg:SetAttribute("ForceViewport", nil)
if daw.Visible then daw:SetAttribute("Command", "close"); task.wait(0.4) end
local out = {}

local function run()
	-- 1. no hint: hidden, zero size, no space
	assert(waitFor(function() return wg:GetAttribute("Open") == true end, 15), "the card did not open within 15 s (Deferred "
		.. tostring(wg:GetAttribute("Deferred")) .. ")")
	assert(wg:GetAttribute("Card") == CARD, "the open card is '" .. tostring(wg:GetAttribute("Card")) .. "', want t76c's " .. CARD)
	task.wait(0.3)
	local card = wg.Root.Card
	local h = card:FindFirstChild("Hint", true)
	assert(h, "no Hint row under the card (before the Task 2 sync of Modules/WalkInUI: the expected red)")
	assert(not h.Visible and h.AbsoluteSize.Y == 0, string.format("a card without a hint shows its hint row (Visible %s, %dx%d)", tostring(h.Visible),
		h.AbsoluteSize.X, h.AbsoluteSize.Y))
	local walk = card:FindFirstChild("WalkAway")
	-- the last footer row: the beat line when it shows (Wave 3 Task 3), else WALK AWAY's row
	local last, lastName = walk, "WALK AWAY"
	local beatRow = card:FindFirstChild("BeatLine")
	if beatRow and beatRow.Visible and beatRow.AbsoluteSize.Y > 0 then last, lastName = beatRow, "the beat line" end
	local pad = wg.AbsoluteSize.Y < 420 and 6 or 12
	local below = (card.AbsolutePosition.Y + card.AbsoluteSize.Y) - (last.AbsolutePosition.Y + last.AbsoluteSize.Y)
	assert(math.abs(below - pad) <= 1, "the card ends " .. below .. " px under " .. lastName .. ", want its " .. pad .. " px padding: the hidden hint took space")
	table.insert(out, string.format("1 %s without a hint: Hint hidden at %dx%d, the card ends %d px under %s", CARD, h.AbsoluteSize.X, h.AbsoluteSize.Y, below, lastName))

	-- 2. the result's hint on the result card
	wg:SetAttribute("ResultKey", ""); wg:SetAttribute("LastChoose", "")
	wg:SetAttribute("Command", "choose:3")
	assert(waitFor(function() return wg:GetAttribute("ResultKey") == "clout" end, 6), "choice 3: ResultKey is '" .. tostring(wg:GetAttribute("ResultKey"))
		.. "', LastChoose '" .. tostring(wg:GetAttribute("LastChoose")) .. "', want clout (t76c forced the roll to 1)")
	local res = wg.Root:FindFirstChild("Result")
	local rh = res and res:FindFirstChild("Hint")
	local l, i, ok = rh and rh:FindFirstChild("Label"), rh and rh:FindFirstChild("Mark"), res and res:FindFirstChild("Ok")
	assert(res and res.Visible and rh and l and i and ok, "no shown Result with Hint (Mark, Label) and Ok")
	local function check(where, vp)
		task.wait(0.3)
		local fr, hr, lr, okr = rel(res), rel(rh), rel(l), rel(ok)
		assert(fr.x0 >= 0 and fr.y0 >= 0 and fr.x1 <= vp.X and fr.y1 <= vp.Y, where .. ": the result card " .. fmt(fr) .. " is outside (0,0)-(" .. vp.X .. "," .. vp.Y .. ")")
		assert(rh.Visible and l.Text == FOLLOWERS and i.Text == "i", where .. ": the result's hint is hidden or reads '" .. l.Text .. "', want '" .. tostring(FOLLOWERS) .. "'")
		assert(l.TextFits, where .. ": the result's hint doesn't fit its " .. l.AbsoluteSize.X .. "x" .. l.AbsoluteSize.Y .. " box")
		assert(within(hr, fr) and within(lr, fr), where .. ": the hint " .. fmt(hr) .. " is outside the result card " .. fmt(fr))
		assert(hr.y0 >= okr.y1, where .. ": the hint " .. fmt(hr) .. " is not under OK " .. fmt(okr))
		table.insert(out, string.format("2 result %s: hint %s (fits) under OK %s, result card %s inside", where, fmt(hr), fmt(okr), fmt(fr)))
	end
	check("real " .. wg.AbsoluteSize.X .. "x" .. wg.AbsoluteSize.Y, wg.AbsoluteSize)
	local d = cam.ViewportSize - wg.AbsoluteSize
	local vp = Vector2.new(667, 375) - Vector2.new(math.max(0, d.X), math.max(0, d.Y))
	wg:SetAttribute("ForceViewport", vp)
	check(vp.X .. "x" .. vp.Y .. " (667x375 less the insets)", vp)
	wg:SetAttribute("ForceViewport", nil)
	wg:SetAttribute("Command", "ok")
	assert(waitFor(function() return not res.Visible end, 2), "OK did not close the result card")
	table.insert(out, "2 OK closed the result card")
end

local okRun, err = pcall(run)
wg:SetAttribute("ForceViewport", nil)
if wg:GetAttribute("Open") == true then wg:SetAttribute("Command", "walkaway") end
if not okRun then error(err, 0) end
return "T76D PLAY OK\n" .. table.concat(out, "\n")
