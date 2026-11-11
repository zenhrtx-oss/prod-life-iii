-- Client, during play (Wave 2 Task 4; after t72a; A6, A7, A8; Review Focus 4). (1) The credits wall, as t08 opens it, with
-- no tab switch: the OpenPanel payload carries no life, Credits draws a Loading line, then the fetch re-renders it with
-- Disco_ rows, newest first, in the parody roster, above "Your credits". ProfileFunction carries no life. (1b) The Profile
-- tab as the OS button opens it: your own title, tier, year and ribbons. (2) Story: First_ cells in the Firsts grid with a
-- tick and "DAY n" (or NOT YET, no tick), then Story_ rows newest first, every name from the roster the server sent, no
-- "{", and the entry StoryText can't render left out. (3) The card: title, tier, year and ribbons; opening it fetches no
-- career. (4) Career, straight from the card: the arrival fetches, the three bars read with fractions that match their
-- lines (Bar_level within the level), and a banner re-renders the open panel. (4b) A career with no life: Story and Credits
-- read Copy.LifeFailed. (5) The nameplate shows YEAR 2. (6) Ruling 8, real paths: a real DAW_Save reports beat, and a real
-- delivery of the starter j1 at 2 stars reports delivery; both read back through Career_Get. t72c and t72d go on from here.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui", 10)
local ui = pg:WaitForChild("OK_UI", 10); assert(ui, "no OK_UI")
local panel = ui:WaitForChild("Panel", 5); assert(panel, "no Panel")
local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart"); local hum = char:WaitForChild("Humanoid"); local cam = workspace.CurrentCamera
local Content = require(RS.OK.Data.WalkIns)
local LifeRules = require(RS.OK.Modules.LifeRules)
local Cfg = require(RS.OK.Config)
local DAWCfg = require(RS.OK.Modules.DAWConfig); local Check = require(RS.OK.Modules.BriefCheck)
local Artists = require(RS.OK.Data.Artists)
local Remotes = RS.OK.Remotes
local NAMES = Content.Names("parody")
local SPONSOR = Content.SponsorName("energy", "parody")
local out = {}
local T0 = os.clock()

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function command(c, t)
	ui:SetAttribute("PanelCommand", c)
	assert(waitFor(function() return ui:GetAttribute("PanelCommand") == "" end, t or 6), "PanelCommand '" .. c .. "' was not taken (Studio seam missing?)")
end
local function count(prefix)
	local n = 0
	for _, c in ipairs(panel.Content:GetChildren()) do if c.Name:sub(1, #prefix) == prefix then n += 1 end end
	return n
end
local function text(name)
	local c = panel.Content:FindFirstChild(name)
	return c and c.Text or nil
end
local function rows(prefix, want)
	for i, line in ipairs(want) do
		assert(text(prefix .. i) == line, prefix .. i .. " reads '" .. tostring(text(prefix .. i)) .. "', want '" .. line .. "'")
	end
	assert(count(prefix) == #want, "want " .. #want .. " " .. prefix .. " rows, have " .. count(prefix))
end
local function near(a, b) return math.abs(a - b) < 0.001 end
local function lifeNow() return Remotes.Career_Get:InvokeServer().life end
local function entries(life, k, key)
	local list = {}
	for _, e in ipairs(life.story) do if e.k == k and (key == nil or e.key == key) then table.insert(list, e) end end
	return list
end
-- builds a beat that meets every ask of a request and is "yours" (8+ pads changed), padding with `fillers` (as t25b)
local function solve(brief, fillers, extraRefs)
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
	local refs = Check.References(DAWCfg, extraRefs)
	for _, filler in ipairs(fillers) do
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
	ui:SetAttribute("PanelCommand", ""); ui:SetAttribute("ForceViewport", nil); panel.Visible = false

	-- 1: the wall's OpenPanel: no life in the payload, Loading, then the rows with no tab switch
	local wall = workspace.OKStudio.Lounge.CreditsWall
	local prompt = wall:FindFirstChildWhichIsA("ProximityPrompt", true); assert(prompt, "credits prompt missing")
	local apos = prompt.Parent:IsA("Attachment") and prompt.Parent.WorldPosition or prompt.Parent.Position
	local pos = Vector3.new(21.5, 3.5, 8.0)
	if hum.Sit then hum.Sit = false; task.wait(0.4) end
	root.CFrame = CFrame.lookAt(pos, Vector3.new(apos.X, pos.Y, apos.Z)); task.wait(1.0)
	local back = (pos - apos) * Vector3.new(1, 0, 1); back = back.Magnitude > 0.1 and back.Unit * 4 or Vector3.new(-4, 0, 0)
	cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + back + Vector3.new(0, 3, 0), apos); task.wait(1.5)
	local opened, sawLoading = nil, false
	local c1 = Remotes.InteractionEvent.OnClientEvent:Connect(function(kind, payload) if kind == "OpenPanel" then opened = payload end end)
	local c2 = panel.Content.ChildAdded:Connect(function(c)
		if c:IsA("TextLabel") and c.Text == LifeRules.Copy.Loading then sawLoading = true end
	end)
	prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd()
	local gotRows = waitFor(function() return count("Disco_") > 0 end, 6)
	c1:Disconnect(); c2:Disconnect()
	cam.CameraType = Enum.CameraType.Custom
	assert(opened and opened.tab == "Credits", "the credits wall sent no OpenPanel")
	assert(opened.life == nil and type(opened.profile) == "table" and opened.profile.life == nil, "the credits wall payload carries the life")
	assert(gotRows, "no Disco_ rows landed on the Credits tab without a tab switch")
	assert(sawLoading, "Credits never read '" .. LifeRules.Copy.Loading .. "' before the career landed")
	rows("Disco_", { "DAY 9 · " .. NAMES.navx .. " · HIT", "DAY 9 · " .. NAMES.homekid .. " · TRACK ONE", "DAY 3 · " .. NAMES.navx .. " · PLACEMENT" })
	local header
	for _, c in ipairs(panel.Content:GetChildren()) do
		if c:IsA("TextLabel") and c.Text == LifeRules.Copy.DiscoHeader then header = c end
	end
	assert(header and panel.Content.Disco_1.LayoutOrder > header.LayoutOrder, "the discography should sit under its header")
	local creditsHeader
	for _, c in ipairs(panel.Content:GetChildren()) do
		if c:IsA("TextLabel") and c.Text == "Your credits" then creditsHeader = c end
	end
	assert(creditsHeader and creditsHeader.LayoutOrder > panel.Content.Disco_3.LayoutOrder, "the discography should sit above Your credits")
	assert(panel.Content:FindFirstChild("LifeStatus") == nil, "the Loading line stayed after the career landed")
	panel.Visible = false
	local prof = Remotes.ProfileFunction:InvokeServer()
	assert(type(prof) == "table" and prof.life == nil, "ProfileFunction carries the life")
	table.insert(out, "credits wall: Loading, then 3 Disco_ rows (HIT, TRACK ONE, PLACEMENT) with no tab switch; no life in its payload or ProfileFunction")

	-- 1b: your own title, on the tab the OS button opens: the real tab, never card:self
	command("os")
	assert(panel.Visible, "PanelCommand os did not open the panel")
	assert(waitFor(function() return panel.Content:FindFirstChild("LifeLine") ~= nil end, 5), "the Profile tab has no LifeLine")
	local ownLine, ownRibbons = text("LifeLine"), text("Ribbons")
	assert(ownLine == "CHART MAKER · KNOWN · YEAR 2", "the Profile's life line reads '" .. tostring(ownLine) .. "'")
	assert(ownRibbons == LifeRules.Copy.RibbonPrefix .. "CHARTED · BRAND DEAL", "the Profile's ribbons read '" .. tostring(ownRibbons) .. "'")
	table.insert(out, "Profile tab: " .. ownLine .. "; " .. ownRibbons)

	-- 2: STORY
	command("tab:Story")
	assert(waitFor(function() return panel.Content:FindFirstChild("Firsts") ~= nil end, 5), "STORY did not render (no Firsts grid)")
	local grid = panel.Content.Firsts
	local cells = 0
	for _, c in ipairs(grid:GetChildren()) do if c.Name:sub(1, 6) == "First_" then cells += 1 end end
	assert(cells == #Cfg.Life.Firsts, "want " .. #Cfg.Life.Firsts .. " First_ cells, have " .. cells)
	local function cellText(id)
		local c = grid:FindFirstChild("First_" .. id)
		return c and c.Text or nil
	end
	local firsts = { placement = "DAY 3", hit = "DAY 9", sponsor = "DAY 9", buzzing = "DAY 1", known = "DAY 1", level5 = "DAY 9" }
	for id, day in pairs(firsts) do
		local line = cellText(id)
		assert(line and line:find("✓", 1, true) and line:find(LifeRules.Copy.FirstLabels[id], 1, true) and line:find(day .. "<", 1, true), "First_" .. id .. " reads '" .. tostring(line) .. "', want a tick and " .. day)
	end
	local beat = cellText("beat")
	assert(beat and not beat:find("✓", 1, true) and beat:find("NOT YET", 1, true), "First_beat reads '" .. tostring(beat) .. "'")
	assert(grid.LayoutOrder < panel.Content.Story_1.LayoutOrder, "the firsts should sit above the story")
	rows("Story_", {
		"DAY 9 · You signed your first sponsor: " .. SPONSOR .. ".",
		"DAY 9 · You got your first HIT, with " .. NAMES.navx .. ".",
		"DAY 9 · You landed a placement with " .. NAMES.homekid .. ".",
		"DAY 3 · You landed your first placement, with " .. NAMES.navx .. ".",
		"DAY 1 · You hit KNOWN at 5,000 followers.",
		"DAY 1 · You hit BUZZING at 1,000 followers.",
	})
	assert(panel.Content.Story_1.LayoutOrder < panel.Content.Story_2.LayoutOrder, "Story_1 should sit above Story_2")
	table.insert(out, "STORY: 12 First_ cells (ticks with DAY n, NOT YET unticked), 6 Story_ rows newest first in the roster's names; the level with no rank left out")

	-- 3: the card
	command("card:self")
	assert(ui:GetAttribute("CareerOut") == false, "opening a card fetched the career")
	assert(waitFor(function() return panel.Content:FindFirstChild("LifeLine") ~= nil end, 3), "the card has no LifeLine")
	local cardLine, ribbons = text("LifeLine"), text("Ribbons")
	assert(cardLine == "CHART MAKER · KNOWN · YEAR 2", "the card's life line reads '" .. tostring(cardLine) .. "'")
	assert(ribbons and ribbons:find("CHARTED", 1, true) and ribbons:find("BRAND DEAL", 1, true) and ribbons:find("CHARTED", 1, true) < ribbons:find("BRAND DEAL", 1, true), "the card's ribbons read '" .. tostring(ribbons) .. "'")
	assert(panel.Content:FindFirstChild("CareerLine"), "the card lost its CareerLine")
	local res = Remotes.Card_Get:InvokeServer(player.UserId)
	assert(res.ok and res.card.story == nil and res.card.disco == nil and res.card.life == nil and res.card.firsts == nil, "Card_Get leaks the story")
	table.insert(out, "card: " .. cardLine .. "; " .. ribbons)

	-- 4: the bars, straight from the card, which fetched nothing: arriving at the tab fetches
	command("tab:Career")
	assert(waitFor(function() return panel.Content:FindFirstChild("Bar_tier") ~= nil end, 5), "Career has no Bar_tier")
	assert(count("Bar_") == 3, "want 3 Bar_ rows, have " .. count("Bar_"))
	local function barOf(id, wantText, wantFraction)
		local b = panel.Content["Bar_" .. id]
		local f = b:GetAttribute("Fraction")
		assert(b.Label.Text == wantText, "Bar_" .. id .. " reads '" .. b.Label.Text .. "', want '" .. wantText .. "'")
		assert(type(f) == "number" and near(f, wantFraction), "Bar_" .. id .. " fraction " .. tostring(f) .. ", want " .. wantFraction)
		assert(near(b.Back.Fill.Size.X.Scale, wantFraction), "Bar_" .. id .. "'s fill is at " .. b.Back.Fill.Size.X.Scale)
		return f
	end
	barOf("tier", "NEXT TIER: FAMOUS · 6,000 / 20,000 followers", 0.3)
	local level, xp = player:GetAttribute("Level"), player:GetAttribute("XP")
	local lo, hi = Cfg.Levels[level], Cfg.Levels[level + 1]
	if hi then barOf("level", string.format("NEXT LEVEL: %d · %s / %s XP", level + 1, LifeRules.Commas(xp - lo), LifeRules.Commas(hi - lo)), (xp - lo) / (hi - lo))
	else barOf("level", "LEVEL 10 · the top level", 1) end
	barOf("hall", "THE HALL · 300 AURA · 1 PLACEMENT · $5,000", 2 / 3)
	assert(panel.Content.Bar_hall.LayoutOrder < panel.Content.Gate_studio_two.LayoutOrder, "the bars should sit above the gates")
	local barBefore = panel.Content.Bar_tier
	command("banner:T72B")
	assert(waitFor(function() return barBefore.Parent == nil and panel.Content:FindFirstChild("Bar_tier") ~= nil end, 3), "a banner did not refresh the open panel")
	table.insert(out, "Career: from the card, Bar_tier 0.3, Bar_level, Bar_hall 2/3, each fill at its fraction; a banner re-rendered the open panel")

	-- 4b: a career that came back without its life
	command("nolife")
	assert(text("LifeStatus") == LifeRules.Copy.LifeFailed, "Story with no life reads '" .. tostring(text("LifeStatus")) .. "'")
	command("tab:Credits")
	assert(text("LifeStatus") == LifeRules.Copy.LifeFailed, "Credits with no life reads '" .. tostring(text("LifeStatus")) .. "'")
	panel.Visible = false
	table.insert(out, "no life: Story and Credits read '" .. LifeRules.Copy.LifeFailed .. "'")

	-- 5: the nameplate
	local plate = player.Character.Head:WaitForChild("OK_Nameplate", 3)
	assert(plate and waitFor(function() return plate.StatsText.Text:find("^YEAR 2 · ") ~= nil end, 3), "the nameplate reads '" .. tostring(plate and plate.StatsText.Text) .. "'")
	table.insert(out, "nameplate: " .. plate.StatsText.Text)

	-- 6: real paths: a saved beat, a delivery at 2 stars
	root.CFrame = CFrame.new(72.0, 3.5, -5.5); task.wait(0.6)
	local brief = Artists.BriefById.j1
	assert(brief, "no brief j1")
	local st = Remotes.Session_Get:InvokeServer()
	local refs = {} -- what the server's copy check compares with; st.last is nil after ResetSessions
	if st.last then table.insert(refs, st.last) end
	local airing = RS.OK.NowPlaying:GetAttribute("Beat")
	if airing then table.insert(refs, airing) end
	local pattern, bpm = solve(brief, { "Clap", "Snare", "Kick" }, refs)
	assert(Check.Check(DAWCfg, brief, pattern, bpm, 0).stars == 2, "the solver's beat should be 2 stars")
	local saved = Remotes.DAW_Save:InvokeServer(pattern, bpm, 0, 1)
	if saved.reason == "cooldown" then task.wait(DAWCfg.SaveCooldown + 0.2); saved = Remotes.DAW_Save:InvokeServer(pattern, bpm, 0, 1) end
	assert(saved.ok, "the beat did not save: " .. tostring(saved.reason))
	local l1 = lifeNow()
	local beats = entries(l1, "beat")
	assert(l1.firsts.beat == 9 and #beats == 1 and beats[1].first == true, "a real save should report beat: firsts.beat " .. tostring(l1.firsts.beat) .. ", " .. #beats .. " lines")
	local pick = Remotes.Session_Pick:InvokeServer("j1")
	assert(pick.ok, "could not take j1: " .. tostring(pick.reason))
	task.wait(2.1)
	local del = Remotes.Session_Deliver:InvokeServer(pattern, bpm, 0)
	assert(del.ok and del.stars == 2, "the delivery: " .. tostring(del.reason) .. ", stars " .. tostring(del.stars))
	local l2 = lifeNow()
	local lines = entries(l2, "delivery", "j1")
	assert(l2.firsts.delivery == 9 and #lines == 1 and lines[1].first == true and lines[1].v == "juno", "a real delivery should report delivery: " .. #lines .. " lines")
	assert(l2.firsts.delivery3 == nil, "a 2-star delivery ticked delivery3")
	table.insert(out, "real paths: DAW_Save reports beat, a 2-star j1 reports delivery (first, juno)")
	return string.format("T72B PLAY OK\n%s\nelapsed %.1f s", table.concat(out, "\n"), os.clock() - T0)
end

local ok, msg = pcall(run)
cam.CameraType = Enum.CameraType.Custom
panel.Visible = false
if not ok then error(msg, 0) end
return msg
