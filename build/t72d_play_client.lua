-- Client, during play (Wave 2 Task 4; after t72c; A8, ruling 2, ruling 8). (1) LifeDayToast: the toast reads DAY 15 · YEAR 3,
-- and the nameplate follows the Year attribute to YEAR 3. A client that reads the attribute after it was set (the "dayjoin"
-- seam, the same reader ClientMain runs at UI build) still toasts once, and the same value never toasts twice. (2) The fiction
-- roster: Story_ and Disco_ rows name the same ids in the fiction names, and no parody name is left; the Career tab's
-- Bar_hall reads open, and Bar_tier reads the top tier with Fraction 1. (3) A real repeat of j1 at 3 stars: a delivery3 line,
-- first, because it ticks its own first (ruling 2). (4) A real daily at streak 6: streak7 is ticked and logged, its ribbon
-- toasts, and the daily logs no delivery line of its own (ruling 2). All read back through Career_Get.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui", 10)
local ui = pg:WaitForChild("OK_UI", 10); assert(ui, "no OK_UI")
local panel = ui:WaitForChild("Panel", 5); assert(panel, "no Panel")
local toast = ui:WaitForChild("Toast", 5); assert(toast, "no Toast")
local root = player.Character:WaitForChild("HumanoidRootPart"); local hum = player.Character:WaitForChild("Humanoid")
local Content = require(RS.OK.Data.WalkIns)
local LifeRules = require(RS.OK.Modules.LifeRules)
local DAWCfg = require(RS.OK.Modules.DAWConfig); local Check = require(RS.OK.Modules.BriefCheck); local DR = require(RS.OK.Modules.DailyRequests)
local Artists = require(RS.OK.Data.Artists)
local Remotes = RS.OK.Remotes
local FICTION, PARODY = Content.Names("fiction"), Content.Names("parody")
local SPONSOR = Content.SponsorName("energy", "fiction")
local out = {}
local T0 = os.clock()

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function command(c, t)
	ui:SetAttribute("PanelCommand", c)
	assert(waitFor(function() return ui:GetAttribute("PanelCommand") == "" end, t or 6), "PanelCommand '" .. c .. "' was not taken (Studio seam missing?)")
end
local function rowsText(prefix)
	local parts = {}
	for _, c in ipairs(panel.Content:GetChildren()) do
		if c.Name:sub(1, #prefix) == prefix then table.insert(parts, c.Text) end
	end
	return table.concat(parts, "\n")
end
local function lifeNow() return Remotes.Career_Get:InvokeServer().life end
local function entries(life, k, key)
	local list = {}
	for _, e in ipairs(life.story) do if e.k == k and (key == nil or e.key == key) then table.insert(list, e) end end
	return list
end
-- builds a beat that meets every ask of a request and is "yours" (8+ pads changed) (as t25b)
local function solve(brief, extraRefs)
	local p = string.rep("0", #DAWCfg.Tracks * DAWCfg.Steps)
	local idx = {}; for i, tr in ipairs(DAWCfg.Tracks) do idx[tr.Name] = i end
	local function get(track, step) local i = (idx[track] - 1) * 16 + step; return p:sub(i, i) end
	local function set(track, step, ch) local i = (idx[track] - 1) * 16 + step; p = p:sub(1, i - 1) .. ch .. p:sub(i + 1) end
	local function tally(track) local n = 0; for s = 1, 16 do if get(track, s) ~= "0" then n += 1 end end; return n end
	local bpm, cap = 120, {}
	for _, a in ipairs(brief.asks) do if a.k == "max" then cap[a.track] = a.n end end
	for _, a in ipairs(brief.asks) do
		if a.k == "bpm" then bpm = math.ceil(a.min / 5) * 5
		elseif a.k == "on" then for _, s in ipairs(a.steps) do set(a.track, s, "1") end
		elseif a.k == "backbeat" then set("Snare", 5, "1"); set("Snare", 13, "1") end
	end
	for _, a in ipairs(brief.asks) do
		if a.k == "min" then for s = 1, 16 do if tally(a.track) >= a.n then break end; if get(a.track, s) == "0" then set(a.track, s, "1") end end end
	end
	-- keys asks (piano roll): pad to the v3 length and place notes, for the days a daily asks for them
	local keys = false
	for _, a in ipairs(brief.asks) do if a.k == "melody" or a.k == "melnotes" or a.k == "chord" then keys = true end end
	if keys then
		p = p .. string.rep("0", DAWCfg.Length - #p)
		for i, semi in ipairs({ 0, 3, 5, 7, 10, 12 }) do p = DAWCfg.PlaceNote(p, 1 + (i - 1) * 2, semi, 1) or p end
		p = DAWCfg.PlaceNote(p, 1, 7, 1) or p
	end
	local refs = Check.References(DAWCfg, extraRefs)
	for _, filler in ipairs({ "Hat", "Clap", "Snare", "Kick" }) do
		for s = 1, 16 do
			if Check.Changed(p, refs) >= Check.MinChanged then break end
			if get(filler, s) == "0" and (cap[filler] == nil or tally(filler) < cap[filler]) then
				local before = Check.Changed(p, refs)
				set(filler, s, "1")
				if Check.Changed(p, refs) <= before or not Check.Check(DAWCfg, brief, p, bpm, 0).passed then set(filler, s, "0") end
			end
		end
	end
	return p, bpm
end

local function run()
	ui:SetAttribute("PanelCommand", ""); panel.Visible = false

	-- 1: the new career day
	local want = LifeRules.DayToast(15, 7)
	assert(want == "DAY 15 · YEAR 3", "DayToast reads '" .. want .. "'")
	assert(waitFor(function() return toast.Text == want end, 3), "the toast reads '" .. toast.Text .. "', want '" .. want .. "'")
	local plate = player.Character.Head:WaitForChild("OK_Nameplate", 3)
	assert(plate and waitFor(function() return plate.StatsText.Text:find("^YEAR 3 · ") ~= nil end, 3), "the nameplate did not follow Year: '" .. tostring(plate and plate.StatsText.Text) .. "'")
	assert(player:GetAttribute("LifeDayToast") == 15, "LifeDayToast is " .. tostring(player:GetAttribute("LifeDayToast")))
	toast.Text = ""
	command("dayjoin")
	assert(ui:GetAttribute("DayToasts") == 1, "a late read should toast once between a new reader, read twice, and the live one; toasts " .. tostring(ui:GetAttribute("DayToasts")))
	assert(toast.Text == want and toast.Visible, "the late read's toast reads '" .. toast.Text .. "'")
	table.insert(out, "LifeDayToast: " .. toast.Text .. "; a late read toasts once, the same value not again; nameplate " .. plate.StatsText.Text)

	-- 2: the fiction roster, from the names the server sends
	command("os")
	command("tab:Story")
	assert(waitFor(function() return panel.Content:FindFirstChild("Story_1") ~= nil end, 5), "STORY did not render")
	local story = rowsText("Story_")
	for _, line in ipairs({ "DAY 3 · You landed your first placement, with " .. FICTION.navx .. ".", "DAY 9 · You got your first HIT, with " .. FICTION.navx .. ".",
		"DAY 9 · You landed a placement with " .. FICTION.homekid .. ".", "DAY 9 · You signed your first sponsor: " .. SPONSOR .. ".", "DAY 9 · THE HALL opened for you.",
		"DAY 9 · You won your first cypher." }) do
		assert(story:find(line, 1, true), "STORY has no line '" .. line .. "':\n" .. story)
	end
	assert(not story:find(PARODY.navx, 1, true) and not story:find(PARODY.homekid, 1, true) and not story:find("{", 1, true), "a parody name or a token in STORY:\n" .. story)
	local hall = panel.Content.Firsts:FindFirstChild("First_hall")
	assert(hall and hall.Text:find("DAY 9", 1, true), "First_hall reads '" .. tostring(hall and hall.Text) .. "'")
	command("tab:Credits")
	assert(waitFor(function() return panel.Content:FindFirstChild("Disco_1") ~= nil end, 5), "Credits has no Disco_ rows")
	assert(panel.Content.Disco_1.Text == "DAY 9 · " .. FICTION.navx .. " · HIT", "Disco_1 reads '" .. panel.Content.Disco_1.Text .. "'")
	assert(not rowsText("Disco_"):find(PARODY.navx, 1, true), "a parody name in the discography")
	command("tab:Career")
	assert(waitFor(function() return panel.Content:FindFirstChild("Bar_hall") ~= nil end, 5), "Career has no Bar_hall")
	assert(panel.Content.Bar_hall.Label.Text == "THE HALL · open" and panel.Content.Bar_hall:GetAttribute("Fraction") == 1, "Bar_hall reads '" .. panel.Content.Bar_hall.Label.Text .. "'")
	local tierBar = panel.Content.Bar_tier
	assert(tierBar.Label.Text == LifeRules.Copy.Bars.tierTop and tierBar.Label.Text == "ICON · the top tier", "Bar_tier reads '" .. tierBar.Label.Text .. "'")
	assert(tierBar:GetAttribute("Fraction") == 1 and tierBar.Back.Fill.Size.X.Scale == 1, "Bar_tier's fraction is " .. tostring(tierBar:GetAttribute("Fraction")))
	panel.Visible = false
	table.insert(out, "fiction roster: STORY and the discography in fiction names, no parody name, no token; Bar_hall open; Bar_tier at the top, fraction 1")

	-- 3: a real repeat of j1 at 3 stars ticks delivery3, so it logs
	if hum.Sit then hum.Sit = false; task.wait(0.4) end
	root.CFrame = CFrame.new(72.0, 3.5, -5.5); task.wait(0.6)
	local j1
	for _, b in ipairs(Artists.Briefs) do if b.id == "j1" then j1 = b end end
	local full = { asks = table.clone(j1.asks), bonus = j1.bonus }
	table.insert(full.asks, j1.bonus)
	local st = Remotes.Session_Get:InvokeServer()
	assert(st.active == "j1", "j1 is not the active request: " .. tostring(st.active))
	local pattern, bpm = solve(full, { st.last, RS.OK.NowPlaying:GetAttribute("Beat") })
	assert(Check.Check(DAWCfg, j1, pattern, bpm, 0).stars == 3, "the solver's beat should be 3 stars")
	task.wait(2.1)
	local r3 = Remotes.Session_Deliver:InvokeServer(pattern, bpm, 0)
	assert(r3.ok and r3.stars == 3 and r3.again == true, "the repeat: " .. tostring(r3.reason) .. ", stars " .. tostring(r3.stars) .. ", again " .. tostring(r3.again))
	local l3 = lifeNow()
	local three = entries(l3, "delivery3", "j1")
	assert(l3.firsts.delivery3 == 15 and #three == 1 and three[1].first == true and three[1].v == "juno", "a first 3-star on a repeat should log delivery3: " .. #three .. " lines, firsts.delivery3 " .. tostring(l3.firsts.delivery3))
	assert(#entries(l3, "delivery", "j1") == 1, "the repeat added a delivery line")
	table.insert(out, "real repeat of j1 at 3 stars: delivery3 logged, first (ruling 2)")

	-- 4: a real daily at streak 6: streak7, and no line for the daily itself
	local id = "d" .. DR.Day(workspace:GetServerTimeNow()) .. "_1"
	local brief = DR.Brief(id)
	assert(brief and brief.daily, "no daily " .. id)
	local before = lifeNow()
	local pick = Remotes.Session_Pick:InvokeServer(id)
	assert(pick.ok, "could not take the daily: " .. tostring(pick.reason))
	local st2 = Remotes.Session_Get:InvokeServer()
	local p2, bpm2 = solve(brief, { st2.last, RS.OK.NowPlaying:GetAttribute("Beat") })
	assert(Check.Check(DAWCfg, brief, p2, bpm2, 0).passed, "the solver's beat does not pass the daily")
	task.wait(2.1)
	local toasts = {}
	local cToast = Remotes.InteractionEvent.OnClientEvent:Connect(function(kind, payload) if kind == "Toast" then table.insert(toasts, payload.text) end end)
	local r4 = Remotes.Session_Deliver:InvokeServer(p2, bpm2, 0)
	assert(r4.ok, "the daily: " .. tostring(r4.reason))
	local ribbonLine = LifeRules.Fill(LifeRules.Copy.RibbonToast, { label = LifeRules.Copy.Ribbons.streak7 })
	local gotRibbon = waitFor(function() return table.find(toasts, ribbonLine) ~= nil end, 3)
	cToast:Disconnect()
	assert(gotRibbon, "a real 7th daily should toast '" .. ribbonLine .. "', toasts: " .. table.concat(toasts, "|"))
	local l4 = lifeNow()
	assert(l4.firsts.streak7 == 15 and #entries(l4, "streak7") == 1, "a real 7th daily should report streak7: firsts.streak7 " .. tostring(l4.firsts.streak7))
	for _, k in ipairs({ "delivery", "delivery3" }) do
		assert(#entries(l4, k, id) == 0, "the daily logged a " .. k .. " line")
		assert(#entries(l4, k) == #entries(before, k), "a " .. k .. " line was added by the daily")
	end
	table.insert(out, "real daily at streak 6: streak7 ticked and logged, its ribbon toasted; no delivery line for the daily (ruling 2)")
	return string.format("T72D PLAY OK\n%s\nelapsed %.1f s", table.concat(out, "\n"), os.clock() - T0)
end

local ok, msg = pcall(run)
panel.Visible = false
if not ok then error(msg, 0) end
return msg
