-- Client, during play (the Day One plan, Task 5: coach marks and the first delivery in your bedroom), after t124a left
-- card 1 (JUNO VALE's request) open with the tour reset, the player at their bedroom laptop's stand spot. The whole first
-- minute, from the client, through the guis' own Command attributes. The file's own fresh(): no forced size on
-- OK_WalkIn or the beat maker, the beat maker closed (card 1 isn't shown over it), the camera given back. MuteMonitors
-- must be off (else the room listener makes no sound: a stray click on the HUD's speaker button?). A Toast listener is
-- connected first: the done toast comes inside Tour.Finish.
-- (1) Card 1 opens by itself (OK_WalkIn Open, Card day1_dayone). Command "choose:1" (On it. Make it now.): LastChoose
--     "ok", the card closes, and the beat maker (OK_DAW.DAW) opens at the bedroom laptop, its Monitors button reading
--     "🔊 ON SPEAKERS" (the OpenDAW payload's room), the Request card's Active the starter brief (j1) and its Overlay
--     "presets" (the OpenDAW payload's presets: DAWClient shows the preset chooser once the request is active). The
--     card's Command "preset:BOUNCE": BOUNCE's pattern and BPM loaded, Overlay "none".
-- (2) The coach mark (PlayerGui.OK_Coach, Modules/CoachUI): CoachStep "deliver" and, at the real size (desktop, not
--     Compact; the Request card's Message empty), CoachVisible true on CoachAnchor "Deliver". The pill (OK_Coach.Mark)
--     reads Data/DayOne's Marks.deliver, is Active false and isn't a GuiButton, and OK_Coach holds no GuiButton at all.
--     The mark's rule (fix 1, review Important 1), at the real size and then with the beat maker forced to a phone
--     (CompactForced, ViewportOverride = the phone's size, as t123d) at 667x375, 771x390 and 844x390: while CoachVisible
--     the pill is inside the screen box (OK_Coach's rect, and the forced box at OK_DAW's corner while forced) and covers
--     none of: a GuiButton on screen in OK_DAW (itself and its ancestors visible; its rect clipped to scrolling or
--     clipping frames), the Request card's Msg line, the beat maker's StatusText, the DAY ONE pill (OK_UI.Tour) while it
--     shows. Rects are absolute, so OK_Coach's CoreUISafeInsets and OK_DAW's DeviceSafeInsets need no conversion. A
--     hidden mark passes (the rule hides it where every spot covers something: the phone's REQUESTS chip in the header);
--     each size's outcome is reported. Unforced, the mark comes back on Deliver.
-- (3) Made yours with t17b's 8 pads (4 snares, 2 claps, 2 hats over BOUNCE: 3 stars on j1); Command "deliver":
--     LastDeliver "ok". With a Cutaway watcher started before the press: Overlay "result" shows at once (ResultStars 3),
--     and Cutaway never turns true, OK_DAW stays enabled and no new OK_BoothArtist appears under the camera, polled for
--     2 s (no listen-back cutaway at a room laptop: the hub's booth is ~6,000 studs away). OK_WalkIn gets Card
--     day1_speakers within Config.DayOne.AfterDeliver + 3 s of the delivery, but Deferred stays true (Open false) while
--     Overlay is "result" (checked for 1 s); CoachStep is "monitors" and the mark hidden behind the result screen. The
--     card's Command "close": card 2 opens over the still-open beat maker (Open true, Deferred false), and the coach mark
--     stays hidden under it.
-- (4) Command "choose:1" (On my speakers): LastChoose "ok", the card closes; the plot's RoomPlaying folder is this
--     player's play in the bedroom, and the room listener (StarterPlayerScripts/OK/RoomClient, SoundService.
--     OK_RoomListener) plays it: Playing, this plot, its Token; a track Sound is added under the plot (t106b's check).
-- (5) Card 3 (day1_spend) within AfterSpeakers + 3 s of card 2's choice returning (fix 1, review minor 5), shown over the beat maker (Open, not Deferred); CoachStep "" (gear
--     has no mark). Command "choose:2" (Save it for the monitors.): LastChoose "ok"; TourVisible false (the tour done),
--     CoachVisible false and CoachStep "", and the done toast (Data/DayOne Toasts.done's opening words) was shown.
-- On any error, and after success: the forced sizes off, the beat maker closed, the camera given back, the listeners
-- disconnected; then the error is rethrown. Any card still open is left for t124c's DayOne Reset (SKIP would skip the
-- tour); t124c checks the server's side and puts everything back.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui", 10)
local wg = pg:WaitForChild("OK_WalkIn", 10); assert(wg, "no OK_WalkIn gui (WalkInUI.Build did not run?)")
local ui = pg:WaitForChild("OK_UI", 10); assert(ui, "no OK_UI")
local dawGui = pg:WaitForChild("OK_DAW", 10)
local daw = dawGui and dawGui:WaitForChild("DAW", 10); assert(daw, "no beat maker gui (PlayerGui.OK_DAW.DAW)")
local req = daw:WaitForChild("Request", 5); assert(req, "no Request card in the beat maker (RequestUI)")
local Config = require(RS.OK.Config)
local C = Config.DayOne; assert(type(C) == "table", "Config.DayOne missing")
local D = require(RS.OK.Data.DayOne)
local Rules = require(RS.OK.Modules.DayOneRules)
local Artists = require(RS.OK.Data.Artists)
local DAWCfg = require(RS.OK.Modules.DAWConfig)
local RED = " (before the D1-T5 sync of Modules/CoachUI, OK/ClientMain and OK/DAWClient: the expected red)"
local RED1 = " (before the D1-T5 fix 1 sync of Modules/CoachUI: the expected red)"
local SPEAKERS = "🔊 ON SPEAKERS" -- the Monitors button at a room's laptop (rooms copy §4.5)
local STARTER = Rules.Starter(Artists.Briefs)
local BOUNCE
for _, pr in ipairs(DAWCfg.Presets) do if pr.name == "BOUNCE" then BOUNCE = pr end end
-- the done toast's opening words: Data/DayOne's Toasts.done up to its first token, trimmed ("DAY ONE DONE"), as t17b
local DONE = (D.Toasts.done:match("^[^{]*") or ""):match("^(.-%w)[^%w]*$")
local TRACKS = {} -- the sample names a beat's sounds carry
for _, tr in ipairs(DAWCfg.Tracks) do TRACKS[tr.Name] = true end
local T0 = os.clock()
local out = {}
local toasts = {}
local conns = {}
table.insert(conns, RS.OK.Remotes.InteractionEvent.OnClientEvent:Connect(function(kind, payload)
	if kind == "Toast" and type(payload) == "table" then table.insert(toasts, tostring(payload.text or "")) end
end))

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function abs(g) local p, s = g.AbsolutePosition, g.AbsoluteSize; return { x0 = p.X, y0 = p.Y, x1 = p.X + s.X, y1 = p.Y + s.Y } end
local function overlaps(a, b) return a.x0 < b.x1 - 1 and b.x0 < a.x1 - 1 and a.y0 < b.y1 - 1 and b.y0 < a.y1 - 1 end
local function fmt(r) return string.format("(%d,%d)-(%d,%d)", r.x0, r.y0, r.x1, r.y1) end
local function cmd(c) req:SetAttribute("Command", c); task.wait(0.15) end
local function choose(label, n)
	wg:SetAttribute("LastChoose", "")
	wg:SetAttribute("Command", "choose:" .. n)
	assert(waitFor(function() return wg:GetAttribute("LastChoose") ~= "" end, 5), label .. ": choose:" .. n .. " got no answer within 5 s (LastChoose empty)")
	assert(wg:GetAttribute("LastChoose") == "ok", label .. ": choose:" .. n .. " answered '" .. tostring(wg:GetAttribute("LastChoose")) .. "', want ok (DayOne_Choose)")
	assert(waitFor(function() return wg:GetAttribute("Open") == false end, 3), label .. ": the card is still open after choose:" .. n)
end
local function cardState() return string.format("Card '%s', Open %s, Deferred %s", tostring(wg:GetAttribute("Card")), tostring(wg:GetAttribute("Open")), tostring(wg:GetAttribute("Deferred"))) end
local function unforce()
	wg:SetAttribute("ForceViewport", nil)
	daw:SetAttribute("CompactForced", nil); daw:SetAttribute("ViewportOverride", nil)
end
local SCREENS = { Vector2.new(667, 375), Vector2.new(771, 390), Vector2.new(844, 390) }
local function clip(a, b) return { x0 = math.max(a.x0, b.x0), y0 = math.max(a.y0, b.y0), x1 = math.min(a.x1, b.x1), y1 = math.min(a.y1, b.y1) } end
-- on screen in ScreenGui g: g enabled, x and every GuiObject above it Visible; its absolute rect clipped to every
-- scrolling or clipping frame above it, or nil when that leaves nothing
local function shownRect(x, g)
	if not (x and g and g.Enabled and x:IsA("GuiObject")) then return nil end
	local r = abs(x)
	local n = x
	while n and n ~= g do
		if n:IsA("GuiObject") then
			if not n.Visible then return nil end
			if n ~= x and (n:IsA("ScrollingFrame") or n.ClipsDescendants) then r = clip(r, abs(n)) end
		end
		n = n.Parent
	end
	if n ~= g or r.x1 - r.x0 < 1 or r.y1 - r.y0 < 1 then return nil end
	return r
end
-- the coach mark's rule (see (2)): hidden, or inside `box` and clear of every control and feedback line; what it found
local function markClear(where, coach, box)
	if coach:GetAttribute("CoachVisible") ~= true then return "hidden" end
	local mark = coach:FindFirstChild("Mark")
	assert(mark and mark.Visible, where .. ": CoachVisible is true but OK_Coach.Mark is " .. (mark and "hidden" or "missing"))
	local m = abs(mark)
	assert(m.x1 - m.x0 >= 1 and m.y1 - m.y0 >= 1, where .. ": the mark is empty: " .. fmt(m))
	assert(m.x0 >= box.x0 - 1 and m.y0 >= box.y0 - 1 and m.x1 <= box.x1 + 1 and m.y1 <= box.y1 + 1, where .. ": the mark " .. fmt(m)
		.. " is outside the screen " .. fmt(box))
	local hit = {}
	for _, d in ipairs(dawGui:GetDescendants()) do
		if d:IsA("GuiButton") then
			local r = shownRect(d, dawGui)
			if r and overlaps(m, r) then table.insert(hit, d.Name .. " " .. fmt(r)) end
		end
	end
	for _, lbl in ipairs({ req:FindFirstChild("Msg") or false, daw:FindFirstChild("StatusText", true) or false }) do
		local r = lbl and shownRect(lbl, dawGui)
		if r and overlaps(m, r) then table.insert(hit, lbl.Name .. " " .. fmt(r)) end
	end
	local tp = ui:FindFirstChild("Tour")
	local tr = tp and shownRect(tp, ui)
	if tr and overlaps(m, tr) then table.insert(hit, "the DAY ONE pill " .. fmt(tr)) end
	assert(#hit == 0, where .. ": the mark " .. fmt(m) .. " on " .. tostring(coach:GetAttribute("CoachAnchor")) .. " covers " .. table.concat(hit, ", ", 1, math.min(#hit, 5))
		.. (#hit > 5 and " …" or "") .. "; want it clear of every control (review Important 1)" .. RED1)
	return "on " .. tostring(coach:GetAttribute("CoachAnchor")) .. " at " .. fmt(m)
end
local function fresh()
	unforce()
	if daw.Visible then daw:SetAttribute("Command", "close"); waitFor(function() return not daw.Visible end, 3) end
	cam.CameraType = Enum.CameraType.Custom
end

local function run()
	assert(STARTER and STARTER.id == "j1", "Data/Artists' starter brief is " .. tostring(STARTER and STARTER.id) .. ", want j1")
	assert(BOUNCE, "DAWConfig.Presets has no BOUNCE")
	assert(DONE and #DONE >= 4, "Data/DayOne Toasts.done has no opening words: " .. tostring(D.Toasts.done))
	assert(player:GetAttribute("MuteMonitors") ~= true, "MuteMonitors is on at the start (a stray click on the HUD's speaker button?): the room listener would make no sound")
	fresh()

	-- 1. card 1: Make it now opens the beat maker at the bedroom laptop on its preset chooser
	assert(waitFor(function() return wg:GetAttribute("Open") == true and wg:GetAttribute("Card") == "day1_dayone" end, 10),
		"no Day One card 1 open within 10 s: " .. cardState() .. "; want day1_dayone open (t124a's Start sent it)")
	choose("1 card 1", 1)
	assert(waitFor(function() return daw.Visible end, 5), "1: the beat maker didn't open within 5 s of Make it now (DayOne's make: DAW.OpenFor at the bedroom laptop, t124a's stand spot)")
	local mon = daw:FindFirstChild("Monitors", true)
	assert(mon and mon:IsA("GuiButton") and waitFor(function() return mon.Text == SPEAKERS end, 3), "1: the Monitors button reads '" .. tostring(mon and mon.Text)
		.. "', want '" .. SPEAKERS .. "' (opened at a room's laptop: the OpenDAW payload's room)")
	assert(waitFor(function() return req:GetAttribute("Active") == STARTER.id end, 5), "1: the Request card's Active is '" .. tostring(req:GetAttribute("Active"))
		.. "', want " .. STARTER.id .. " (Make it now took the starter request)")
	assert(waitFor(function() return req:GetAttribute("Overlay") == "presets" end, 5), "1: the Request card's Overlay is '" .. tostring(req:GetAttribute("Overlay"))
		.. "', want presets (the OpenDAW payload's presets, the request active)" .. RED)
	cmd("preset:BOUNCE")
	assert(waitFor(function() return daw:GetAttribute("Pattern") == BOUNCE.pattern and daw:GetAttribute("BPM") == BOUNCE.bpm and req:GetAttribute("Overlay") == "none" end, 3),
		"1: preset:BOUNCE: Overlay '" .. tostring(req:GetAttribute("Overlay")) .. "', BPM " .. tostring(daw:GetAttribute("BPM")) .. "; want BOUNCE loaded and Overlay none")
	table.insert(out, string.format("1 Make it now: ok; the beat maker open at the bedroom laptop (%s), Active %s, Overlay presets; BOUNCE loaded, Overlay none", mon.Text, STARTER.id))

	-- 2. the coach mark on DELIVER (desktop) or the request chip (phones)
	local coach = pg:WaitForChild("OK_Coach", 5)
	assert(coach and coach:IsA("ScreenGui"), "2: no PlayerGui.OK_Coach ScreenGui (Modules/CoachUI built by ClientMain)" .. RED)
	assert(waitFor(function() return coach:GetAttribute("CoachStep") == "deliver" end, 3), "2: CoachStep is '" .. tostring(coach:GetAttribute("CoachStep"))
		.. "', want deliver (the tour's step after the take)")
	local compact = daw:GetAttribute("Compact") == true
	assert(not compact, "2: the beat maker is Compact at the real size (a phone-sized game view?): this file wants the desktop layout, as t17b")
	local want = "Deliver"
	assert(waitFor(function() return coach:GetAttribute("CoachVisible") == true and coach:GetAttribute("CoachAnchor") == want end, 3), string.format(
		"2: CoachVisible %s, CoachAnchor '%s'; want true on %s (the Request card's Message '%s': a message hides the deliver mark)", tostring(coach:GetAttribute("CoachVisible")),
		tostring(coach:GetAttribute("CoachAnchor")), want, tostring(req:GetAttribute("Message"))) .. RED)
	local mark = coach:FindFirstChild("Mark")
	assert(mark and mark:IsA("GuiObject") and mark.Visible, "2: OK_Coach.Mark is " .. (mark and (mark.Visible and "shown" or "hidden") or "missing") .. " while CoachVisible, want shown")
	assert(not mark:IsA("GuiButton") and mark.Active == false, "2: the mark is a " .. mark.ClassName .. " with Active " .. tostring(mark.Active) .. ", want a label (no button, Active false)")
	for _, d in ipairs(coach:GetDescendants()) do assert(not d:IsA("GuiButton"), "2: OK_Coach holds a button: " .. d:GetFullName()) end
	assert(mark:IsA("TextLabel") and mark.Text == D.Marks.deliver, "2: the mark reads '" .. tostring(mark:IsA("TextLabel") and mark.Text) .. "', want '" .. D.Marks.deliver .. "'")
	task.wait(0.3) -- one more placement pass, so the rects are current
	local function coachBox() return abs(coach) end -- OK_Coach's own rect (absolute)
	local real = markClear("2 real size", coach, coachBox())
	assert(real ~= "hidden", "2: the mark hid again at the real size")
	local phones = {}
	for _, screen in ipairs(SCREENS) do
		daw:SetAttribute("CompactForced", true)
		daw:SetAttribute("ViewportOverride", screen)
		local where = string.format("2 forced %dx%d", screen.X, screen.Y)
		assert(waitFor(function() return daw:GetAttribute("Compact") == true end, 3), where .. ": the beat maker's Compact is " .. tostring(daw:GetAttribute("Compact"))
			.. " with CompactForced and ViewportOverride set, want true")
		task.wait(0.6) -- the window's layout, then two of the mark's 0.2 s passes
		assert(daw.Visible and req:GetAttribute("Overlay") == "none", where .. ": the beat maker closed or an overlay opened (Overlay '" .. tostring(req:GetAttribute("Overlay")) .. "')")
		local d = dawGui.AbsolutePosition
		local box = clip(coachBox(), { x0 = d.X, y0 = d.Y, x1 = d.X + screen.X, y1 = d.Y + screen.Y })
		table.insert(phones, string.format("%dx%d %s", screen.X, screen.Y, markClear(where, coach, box)))
	end
	unforce()
	assert(waitFor(function() return daw:GetAttribute("Compact") ~= true end, 3), "2: the beat maker stayed Compact after the forced sizes were cleared")
	assert(waitFor(function() return coach:GetAttribute("CoachVisible") == true and coach:GetAttribute("CoachAnchor") == want end, 3), "2: back at the real size the mark is "
		.. (coach:GetAttribute("CoachVisible") and ("on " .. tostring(coach:GetAttribute("CoachAnchor"))) or "hidden") .. ", want it on " .. want)
	task.wait(0.3)
	markClear("2 real size again", coach, coachBox())
	table.insert(out, string.format("2 coach mark '%s' (a label; no button in OK_Coach): real size %s, clear of every control; phones (forced): %s",
		mark.Text, real, table.concat(phones, "; ")))

	-- 3. made yours and delivered: the result at once, no cutaway; card 2 waits for the result screen
	local pat = BOUNCE.pattern
	local function set(s, track, step, ch) local i = (track - 1) * DAWCfg.Steps + step; return s:sub(1, i - 1) .. ch .. s:sub(i + 1) end
	for _, s in ipairs({ 3, 7, 11, 15 }) do pat = set(pat, 2, s, "1") end
	for _, s in ipairs({ 2, 10 }) do pat = set(pat, 3, s, "1") end
	for _, s in ipairs({ 8, 16 }) do pat = set(pat, 4, s, "1") end
	daw:SetAttribute("Pattern", pat)
	assert(waitFor(function() return (req:GetAttribute("Changed") or 0) >= 8 and req:GetAttribute("Stars") == 3 end, 3), "3: the ticks didn't reach 3 stars: changed "
		.. tostring(req:GetAttribute("Changed")) .. ", stars " .. tostring(req:GetAttribute("Stars")))
	local cutSeen = false
	local cutConn = req:GetAttributeChangedSignal("Cutaway"):Connect(function() if req:GetAttribute("Cutaway") == true then cutSeen = true end end)
	table.insert(conns, cutConn)
	local boothBefore = cam:FindFirstChild("OK_BoothArtist")
	req:SetAttribute("LastDeliver", "")
	cmd("deliver")
	assert(waitFor(function() return (req:GetAttribute("LastDeliver") or "") ~= "" end, 8), "3: deliver got no answer within 8 s (LastDeliver empty)")
	local tDeliver = os.clock()
	assert(req:GetAttribute("LastDeliver") == "ok", "3: deliver answered '" .. tostring(req:GetAttribute("LastDeliver")) .. "' (" .. tostring(req:GetAttribute("Message")) .. "), want ok")
	assert(waitFor(function() return req:GetAttribute("Overlay") == "result" end, 1), "3: Overlay is '" .. tostring(req:GetAttribute("Overlay")) .. "', Cutaway "
		.. tostring(req:GetAttribute("Cutaway")) .. " right after the delivery; want the result at once (no listen-back at a room laptop)" .. RED)
	assert(req:GetAttribute("ResultStars") == 3, "3: the result shows " .. tostring(req:GetAttribute("ResultStars")) .. " stars, want 3")
	local cut = waitFor(function() return cutSeen or req:GetAttribute("Cutaway") == true or not dawGui.Enabled end, 2)
	cutConn:Disconnect()
	assert(not cut, "3: a listen-back cutaway ran at the bedroom laptop (Cutaway seen " .. tostring(cutSeen) .. ", OK_DAW enabled " .. tostring(dawGui.Enabled) .. "), want none" .. RED)
	local fig = cam:FindFirstChild("OK_BoothArtist")
	assert(fig == nil or fig == boothBefore, "3: the booth artist " .. (fig and tostring(fig:GetAttribute("Artist")) or "") .. " appeared under the camera, want none at a room laptop" .. RED)
	assert(req:GetAttribute("Overlay") == "result", "3: the result screen closed by itself (Overlay '" .. tostring(req:GetAttribute("Overlay")) .. "')")
	local wait2 = C.AfterDeliver + 3 - (os.clock() - tDeliver)
	assert(waitFor(function() return wg:GetAttribute("Card") == "day1_speakers" end, math.max(wait2, 0.5)), string.format(
		"3: card 2 didn't come within %d s of the delivery (AfterDeliver %d + 3): %s", C.AfterDeliver + 3, C.AfterDeliver, cardState()))
	assert(req:GetAttribute("Overlay") == "result", "3: the result screen closed before card 2 came (Overlay '" .. tostring(req:GetAttribute("Overlay")) .. "')")
	assert(wg:GetAttribute("Deferred") == true and wg:GetAttribute("Open") == false, "3: card 2 over the result screen: " .. cardState() .. "; want Deferred true, Open false")
	local broke = waitFor(function() return wg:GetAttribute("Deferred") ~= true or wg:GetAttribute("Open") == true end, 1)
	assert(not broke and req:GetAttribute("Overlay") == "result", "3: while the result screen shows card 2 went " .. cardState() .. " (Overlay '"
		.. tostring(req:GetAttribute("Overlay")) .. "'), want it deferred")
	assert(waitFor(function() return coach:GetAttribute("CoachStep") == "monitors" end, 3), "3: CoachStep is '" .. tostring(coach:GetAttribute("CoachStep"))
		.. "' after the delivery, want monitors")
	assert(coach:GetAttribute("CoachVisible") == false, "3: the coach mark shows over the result screen (on '" .. tostring(coach:GetAttribute("CoachAnchor")) .. "')")
	cmd("close")
	assert(waitFor(function() return wg:GetAttribute("Open") == true and wg:GetAttribute("Deferred") == false end, 3), "3: after closing the result screen card 2 is "
		.. cardState() .. "; want it open over the beat maker (now = true)")
	assert(daw.Visible and wg:GetAttribute("Card") == "day1_speakers", "3: the beat maker closed, or the open card is " .. tostring(wg:GetAttribute("Card")))
	assert(waitFor(function() return coach:GetAttribute("CoachVisible") == false end, 2), "3: the coach mark shows over card 2 (on '"
		.. tostring(coach:GetAttribute("CoachAnchor")) .. "'), want it hidden while OK_WalkIn is Open")
	table.insert(out, string.format("3 delivered (8 pads, 3 stars): the result at once, no cutaway or booth artist in 2 s; card 2 came %.1f s after it, deferred under the result; open after close; coach on monitors, hidden",
		os.clock() - tDeliver))

	-- 4. On my speakers: the room listener plays it in the plot
	local slot = player:GetAttribute("PlotSlot")
	assert(type(slot) == "number" and slot > 0 and player:GetAttribute("InPlot") == slot, "4: PlotSlot " .. tostring(slot) .. ", InPlot "
		.. tostring(player:GetAttribute("InPlot")) .. ": not in your own plot (t124a's WakeUp)")
	local plotName = string.format("Plot_%02d", slot)
	local plots = workspace:FindFirstChild("OK_Plots")
	local plot = plots and plots:FindFirstChild(plotName)
	assert(plot, "4: Workspace.OK_Plots." .. plotName .. " is not on this client")
	local folder = RS.OK:FindFirstChild("RoomPlaying")
	local f = folder and folder:FindFirstChild(plotName)
	assert(f, "4: ReplicatedStorage.OK.RoomPlaying." .. plotName .. " is not on this client")
	local listener = SoundService:FindFirstChild("OK_RoomListener")
	assert(listener, "4: no SoundService.OK_RoomListener (StarterPlayerScripts/OK/RoomClient not running?)")
	local sounds = {}
	table.insert(conns, plot.DescendantAdded:Connect(function(d) if d:IsA("Sound") and TRACKS[d.Name] then table.insert(sounds, d) end end))
	local tok0 = f:GetAttribute("Token") or 0
	choose("4 card 2", 1)
	local tChoose = os.clock()
	assert(waitFor(function() return f:GetAttribute("Active") == true and (f:GetAttribute("Token") or 0) > tok0 and f:GetAttribute("OwnerId") == player.UserId end, 5),
		string.format("4: %s reads Active %s, Token %s (was %s), OwnerId %s; want this player's new play", plotName, tostring(f:GetAttribute("Active")),
			tostring(f:GetAttribute("Token")), tostring(tok0), tostring(f:GetAttribute("OwnerId"))))
	assert(f:GetAttribute("Room") == "bedroom", "4: the play's Room is " .. tostring(f:GetAttribute("Room")) .. ", want bedroom")
	local token = f:GetAttribute("Token")
	assert(waitFor(function() return listener:GetAttribute("Playing") == true and listener:GetAttribute("Plot") == slot and listener:GetAttribute("Token") == token end, 8),
		string.format("4: the listener reads Playing %s, Plot %s, Token %s; want this plot's play (%d, %s)", tostring(listener:GetAttribute("Playing")),
			tostring(listener:GetAttribute("Plot")), tostring(listener:GetAttribute("Token")), slot, tostring(token)))
	assert(waitFor(function() return #sounds >= 1 end, 8), string.format("4: in 8 s the listener added no track sound under %s (Made %s, last from '%s')",
		plotName, tostring(listener:GetAttribute("Made")), tostring(listener:GetAttribute("LastParent"))))
	local lastParent = tostring(listener:GetAttribute("LastParent") or "")
	assert(lastParent:find(plot:GetFullName(), 1, true) == 1, "4: the listener's last sound came from '" .. lastParent .. "', want a part of " .. plot:GetFullName())
	table.insert(out, string.format("4 On my speakers: ok; %s Token %s in the bedroom (Tier %s); the listener on it, %d track sound(s) under the plot, the last from %s",
		plotName, tostring(token), tostring(f:GetAttribute("Tier")), #sounds, lastParent))

	-- 5. card 3, then Save it: the tour done, the pill and the mark gone, the done toast
	local wait3 = C.AfterSpeakers + 3
	assert(waitFor(function() return wg:GetAttribute("Card") == "day1_spend" end, math.max(wait3 - (os.clock() - tChoose), 0.5)), string.format(
		"5: card 3 didn't come within %d s of card 2's choice (AfterSpeakers %d + 3): %s", wait3, C.AfterSpeakers, cardState()))
	assert(waitFor(function() return wg:GetAttribute("Open") == true and wg:GetAttribute("Deferred") == false end, 3), "5: card 3 isn't shown over the beat maker: " .. cardState())
	assert(coach:GetAttribute("CoachStep") == "", "5: CoachStep is '" .. tostring(coach:GetAttribute("CoachStep")) .. "' on the gear step, want '' (gear has no mark)")
	choose("5 card 3", 2)
	assert(waitFor(function() return ui:GetAttribute("TourVisible") == false end, 4), "5: TourVisible is " .. tostring(ui:GetAttribute("TourVisible")) .. " after Save it, want false (the tour done)")
	assert(waitFor(function() return coach:GetAttribute("CoachVisible") == false end, 2) and coach:GetAttribute("CoachStep") == "", "5: after the tour CoachVisible "
		.. tostring(coach:GetAttribute("CoachVisible")) .. ", CoachStep '" .. tostring(coach:GetAttribute("CoachStep")) .. "'; want false and ''")
	local function doneToast() for _, t in ipairs(toasts) do if t:find(DONE, 1, true) then return t end end; return nil end
	assert(waitFor(function() return doneToast() ~= nil end, 3), "5: no toast starting '" .. DONE .. "' (got: " .. (#toasts > 0 and table.concat(toasts, " | ") or "none") .. ")")
	table.insert(out, string.format("5 card 3 over the beat maker; Save it: ok; the tour done (TourVisible false), the coach mark off; toast '%s'", doneToast()))
	return table.concat(out, "\n")
end

local ok, msg = pcall(run)
for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
pcall(unforce)
pcall(function() if daw.Visible then daw:SetAttribute("Command", "close") end end)
pcall(function() cam.CameraType = Enum.CameraType.Custom end)
if not ok then error(msg, 0) end
return string.format("T124B PLAY OK (%.1f s)\n", os.clock() - T0) .. msg
