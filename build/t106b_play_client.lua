-- Client, during play (the Your Rooms plan, Task 7: your room's speakers), after t106a's tail: the player woke up in
-- their bedroom and owns spk_monitors, so the bedroom holds tier 2 speakers. Every assertion is about state (labels,
-- attributes, parents, properties, sizes), and every wait has a generous timeout: the Mac's locked screen can hold this
-- client near 2 fps. "The stand spot" is room-local (2, 0, -3), t105b's.
-- (1) The bedroom (Workspace.OK_Plots.Plot_<PlotSlot>.Room_bedroom) is on this client with its laptop and its tier 2
--     RoomSpeaker_L / _R (each with a Cabinet part), and InPlot reads the slot. MuteMonitors is off.
-- (2) At the stand spot, the laptop's prompt (InputHoldBegin / End) opens the beat maker with the OpenDAW payload's room
--     "bedroom", and the Monitors button reads "🔊 ON SPEAKERS" (copy §4.5; DAWClient sets it, DAWUI is untouched).
-- (3) The default beat at 120 BPM, the local preview playing; pressing the button (its Command "monitors", the click's
--     own path) answers ok: LastBroadcast "ok", the status reads tier 2's line (copy §4.7), the preview has stopped, and
--     NowPlaying's Token hasn't moved. The plot's RoomPlaying folder is Active at Tier 2, this player's. A FIRE for its
--     Token through the real remote (Fire_Send) is refused "noair": nothing airs.
-- (4) The listener (StarterPlayerScripts/OK/RoomClient; its state on SoundService.OK_RoomListener) is on this plot's play
--     at tier 2. SoundService holds OK_RoomTier1..3, each a SoundGroup whose EqualizerSoundEffect EQ has its tier's gains.
--     Its sounds (each one seen as it was added under the plot) come from the bedroom's RoomSpeaker_L and _R Cabinets,
--     both sides, with tier 2's RollOffMinDistance / MaxDistance (InverseTapered), the SoundGroup OK_RoomTier2 and each
--     sample's own volume times tier 2's volume.
-- (5) MuteMonitors on: the steps go on (Hits rises) and no sound is made (Made and the sounds seen stay put); off again,
--     sounds come back.
-- (6) Forced to the phone layout (CompactForced, ViewportOverride = the screen less this gui's insets) at 667x375,
--     771x390 and 844x390: the button still reads "🔊 ON SPEAKERS", is 44 px or more both ways, its text fits, it sits
--     inside the viewport, and no other visible button of the window overlaps it.
-- (7) DAW_Stop ends the play: the folder and the listener go quiet.
-- On any error, and after success: MuteMonitors as it was, the phone force off, DAW_Stop, the beat maker closed, the camera
-- given back, the character moved to the lounge; then the error is rethrown. t106c puts the gear back.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character
local root = char and char:WaitForChild("HumanoidRootPart", 5)
local hum = char and char:WaitForChild("Humanoid", 5)
assert(root and hum, "no live character")
local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui", 10)
local dawGui = pg and pg:WaitForChild("OK_DAW", 10)
local daw = dawGui and dawGui:WaitForChild("DAW", 10)
assert(daw, "no beat maker gui (PlayerGui.OK_DAW.DAW)")
local Config = require(RS.OK.Config)
local DAWCfg = require(RS.OK.Modules.DAWConfig)
local Remotes = RS.OK.Remotes
local NP = RS.OK.NowPlaying
local samples = RS.OK:WaitForChild("Samples", 10)
local SPK = Config.Rooms.Speakers
local TIER = 2 -- t106a's tail grants spk_monitors
local LABEL = "🔊 ON SPEAKERS" -- copy §4.5
local STATUS = "On your desk monitors · everyone in your room hears it" -- copy §4.7
local LOUNGE = Vector3.new(24, 3, 0)
local RED = " (before the R-T7 sync of OK/DAWClient, OK/RoomClient, Systems/Rooms and the rest: the expected red)"
local out = {}
local events = {} -- every InteractionEvent this client got: { kind, payload, t }
local conn = Remotes.InteractionEvent.OnClientEvent:Connect(function(kind, payload) table.insert(events, { kind = kind, payload = payload, t = os.clock() }) end)
local soundConn
local wasMute = player:GetAttribute("MuteMonitors")
local TRACKS = {} -- the sample names a beat's sounds carry
for _, tr in ipairs(DAWCfg.Tracks) do TRACKS[tr.Name] = true end
local sounds = {} -- every track sound added under the plot: { sound, parent, min, max, mode, group, volume }

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function name(inst) return typeof(inst) == "Instance" and inst:GetFullName() or tostring(inst) end
local function eventSince(kind, since)
	for i = #events, 1, -1 do
		local e = events[i]
		if e.kind == kind and e.t >= since then return e end
	end
	return nil
end
-- rects in the beat maker gui's own space: (0, 0) is its top-left, so a forced viewport's box is (0, 0)-vp
local function rel(g) local p, s = g.AbsolutePosition - dawGui.AbsolutePosition, g.AbsoluteSize; return { x0 = p.X, y0 = p.Y, x1 = p.X + s.X, y1 = p.Y + s.Y } end
local function overlaps(a, b) return a.x0 < b.x1 - 0.5 and b.x0 < a.x1 - 0.5 and a.y0 < b.y1 - 0.5 and b.y0 < a.y1 - 0.5 end
local function fmt(r) return string.format("(%d,%d)-(%d,%d)", r.x0, r.y0, r.x1, r.y1) end
-- visible, and every GuiObject above it in the window visible too
local function shown(g)
	if not g.Visible then return false end
	local n = g.Parent
	while n and n ~= dawGui do
		if n:IsA("GuiObject") and not n.Visible then return false end
		n = n.Parent
	end
	return true
end
local function closeDaw()
	if daw.Visible then daw:SetAttribute("Command", "close") end
	assert(waitFor(function() return not daw.Visible end, 5), "the beat maker would not close (its Command 'close')")
end
-- presses `pp` (InputHoldBegin / End) up to 4 times until done() holds, `each` seconds a try
local function press(pp, done, each)
	for _ = 1, 4 do
		pp:InputHoldBegin(); task.wait(0.05); pp:InputHoldEnd()
		if waitFor(done, each or 2) then return true end
	end
	return false
end

local function run()
	-- 1. the bedroom, its laptop and its tier 2 speakers on this client
	assert(wasMute ~= true, "MuteMonitors is on at the start (a stray click on the HUD's speaker button?): the listener would make no sound")
	local slot = player:GetAttribute("PlotSlot")
	assert(waitFor(function() slot = player:GetAttribute("PlotSlot"); return type(slot) == "number" and slot > 0 end, 5),
		"PlotSlot is " .. tostring(slot) .. ", want the player's slot (t106a's tail wakes the player up in their bedroom)")
	local plots = workspace:WaitForChild("OK_Plots", 5)
	assert(plots, "Workspace.OK_Plots is not on this client")
	local plotName = string.format("Plot_%02d", slot)
	local plot, bedroom, station, spL, spR
	assert(waitFor(function()
		plot = plots:FindFirstChild(plotName)
		bedroom = plot and plot:FindFirstChild("Room_bedroom")
		if not bedroom then return false end
		station = nil
		for _, d in ipairs(bedroom:GetDescendants()) do
			if d:IsA("BasePart") and d:GetAttribute("Kind") == "Station" then station = d; break end
		end
		return station ~= nil
	end, 8), plotName .. ".Room_bedroom with its laptop is not on this client 8 s into the test")
	local got = waitFor(function()
		local L, R = bedroom:FindFirstChild("RoomSpeaker_L"), bedroom:FindFirstChild("RoomSpeaker_R")
		spL = L and L:GetAttribute("Tier") == TIER and L:FindFirstChild("Cabinet") or nil
		spR = R and R:GetAttribute("Tier") == TIER and R:FindFirstChild("Cabinet") or nil
		return spL ~= nil and spR ~= nil
	end, 8)
	assert(got, plotName .. ".Room_bedroom has no tier " .. TIER .. " RoomSpeaker_L / _R with a Cabinet on this client 8 s in (t106a's tail grants spk_monitors)" .. RED)
	assert(waitFor(function() return player:GetAttribute("InPlot") == slot end, 5), "InPlot reads " .. tostring(player:GetAttribute("InPlot")) .. ", want " .. slot)
	local folder = RS.OK:WaitForChild("RoomPlaying", 5)
	local f = folder and folder:FindFirstChild(plotName)
	assert(f, "ReplicatedStorage.OK.RoomPlaying." .. plotName .. " is not on this client")
	soundConn = plot.DescendantAdded:Connect(function(d)
		if d:IsA("Sound") and TRACKS[d.Name] then
			table.insert(sounds, { sound = d, parent = d.Parent, min = d.RollOffMinDistance, max = d.RollOffMaxDistance, mode = d.RollOffMode,
				group = d.SoundGroup, volume = d.Volume })
		end
	end)
	table.insert(out, string.format("1 %s.Room_bedroom on this client with its laptop and tier %d speakers; InPlot %d", plotName, TIER, slot))

	-- 2. your laptop: the beat maker opens with the room, and the button reads ON SPEAKERS
	closeDaw()
	if hum.Sit then hum.Sit = false; task.wait(0.4) end
	local stand = (bedroom:GetPivot() * CFrame.new(2, 0, -3)).Position + Vector3.new(0, 3, 0)
	local sp = station:FindFirstChildWhichIsA("ProximityPrompt")
	assert(sp and sp.Enabled, "the bedroom's laptop has no enabled prompt")
	root.CFrame = CFrame.lookAt(stand, Vector3.new(station.Position.X, stand.Y, station.Position.Z)); task.wait(1.0)
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.lookAt(stand + Vector3.new(0, 2.5, 0) + (stand - station.Position) * Vector3.new(1, 0, 1) * 0.3, station.Position)
	task.wait(1.0)
	daw:SetAttribute("CompactForced", nil); daw:SetAttribute("ViewportOverride", nil) -- never inherit phone mode from an earlier failed test
	local t2 = os.clock()
	assert(press(sp, function() return daw.Visible end, 2), "the beat maker did not open from your own laptop's prompt")
	local od = eventSince("OpenDAW", t2)
	local room = od and type(od.payload) == "table" and od.payload.room
	assert(room == "bedroom", "the OpenDAW payload's room is " .. tostring(room) .. ", want bedroom")
	local btn = daw:FindFirstChild("Monitors", true)
	assert(btn and btn:IsA("GuiButton"), "the beat maker has no Monitors button")
	assert(waitFor(function() return btn.Text == LABEL end, 3), "at your own laptop the Monitors button reads '" .. btn.Text .. "', want '" .. LABEL .. "'" .. RED)
	table.insert(out, "2 your laptop opens the beat maker (OpenDAW room bedroom); the button reads " .. LABEL)

	-- 3. ON SPEAKERS
	local npToken = NP:GetAttribute("Token")
	daw:SetAttribute("Kit", "studio") -- the samples' own volumes below (a kit's are its own)
	daw:SetAttribute("Pattern", DAWCfg.DefaultPattern); daw:SetAttribute("BPM", 120); daw:SetAttribute("Swing", 0)
	daw:SetAttribute("Command", "play")
	assert(waitFor(function() return daw:GetAttribute("Playing") == true end, 3), "the local preview did not start (Command 'play')")
	daw:SetAttribute("LastBroadcast", "")
	daw:SetAttribute("Command", "monitors")
	assert(waitFor(function() return (daw:GetAttribute("LastBroadcast") or "") ~= "" end, 10), "pressing the button got no answer in 10 s (LastBroadcast empty)")
	assert(daw:GetAttribute("LastBroadcast") == "ok", "pressing the button answered '" .. tostring(daw:GetAttribute("LastBroadcast")) .. "' (status '"
		.. tostring(daw:GetAttribute("Status")) .. "'), want ok")
	assert(waitFor(function() return daw:GetAttribute("Status") == STATUS end, 3), "the status reads '" .. tostring(daw:GetAttribute("Status")) .. "', want '" .. STATUS .. "'" .. RED)
	assert(waitFor(function() return daw:GetAttribute("Playing") == false and player:GetAttribute("DAWPlaying") == false end, 3), "the local preview kept playing after ON SPEAKERS")
	assert(waitFor(function() return f:GetAttribute("Active") == true and f:GetAttribute("Tier") == TIER and f:GetAttribute("OwnerId") == player.UserId end, 5),
		plotName .. "'s RoomPlaying reads Active " .. tostring(f:GetAttribute("Active")) .. ", Tier " .. tostring(f:GetAttribute("Tier")) .. ", OwnerId "
		.. tostring(f:GetAttribute("OwnerId")) .. "; want this player's play at tier " .. TIER)
	assert(NP:GetAttribute("Token") == npToken and not (NP:GetAttribute("Active") == true and NP:GetAttribute("OwnerId") == player.UserId),
		"ON SPEAKERS reached NowPlaying (Token " .. tostring(npToken) .. " -> " .. tostring(NP:GetAttribute("Token")) .. ")")
	local token = f:GetAttribute("Token")
	local fire = Remotes.Fire_Send:InvokeServer(token)
	assert(type(fire) == "table" and fire.ok == false and fire.reason == "noair", "a FIRE for the room play's Token answered " .. tostring(fire and fire.ok) .. " / "
		.. tostring(fire and fire.reason) .. ", want refused: noair")
	table.insert(out, string.format("3 ON SPEAKERS: ok, status '%s', preview stopped, Plot folder Token %s at tier %d, NowPlaying untouched; FIRE noair", STATUS, tostring(token), TIER))

	-- 4. the listener: this plot's play at tier 2, from the speakers, through the tier's group
	local state = SoundService:WaitForChild("OK_RoomListener", 5)
	assert(state, "no SoundService.OK_RoomListener (StarterPlayerScripts/OK/RoomClient not running?)" .. RED)
	assert(waitFor(function()
		return state:GetAttribute("Playing") == true and state:GetAttribute("Plot") == slot and state:GetAttribute("Token") == token and state:GetAttribute("Tier") == TIER
	end, 10), string.format("the listener reads Playing %s, Plot %s, Token %s, Tier %s; want this plot's play (%d, %s) at tier %d", tostring(state:GetAttribute("Playing")),
		tostring(state:GetAttribute("Plot")), tostring(state:GetAttribute("Token")), tostring(state:GetAttribute("Tier")), slot, tostring(token), TIER))
	local groups = {}
	for i, t in ipairs(SPK) do
		local g = SoundService:FindFirstChild("OK_RoomTier" .. i)
		assert(g and g:IsA("SoundGroup"), "no SoundGroup SoundService.OK_RoomTier" .. i)
		local eq = g:FindFirstChild("EQ")
		assert(eq and eq:IsA("EqualizerSoundEffect") and eq.Enabled, "OK_RoomTier" .. i .. " has no enabled EqualizerSoundEffect EQ")
		assert(math.abs(eq.LowGain - t.eq[1]) < 1e-3 and math.abs(eq.MidGain - t.eq[2]) < 1e-3 and math.abs(eq.HighGain - t.eq[3]) < 1e-3,
			string.format("OK_RoomTier%d's EQ is %s / %s / %s dB, want %s / %s / %s", i, eq.LowGain, eq.MidGain, eq.HighGain, t.eq[1], t.eq[2], t.eq[3]))
		groups[i] = g
	end
	local function sides()
		local l, r = 0, 0
		for _, s in ipairs(sounds) do if s.parent == spL then l += 1 elseif s.parent == spR then r += 1 end end
		return l, r
	end
	assert(waitFor(function() local l, r = sides(); return #sounds >= 3 and l > 0 and r > 0 end, 10), string.format("in 10 s the listener made %d sounds under the plot (%d left, %d right; Made %s, last from %s), want 3 or more from both speakers",
		#sounds, select(1, sides()), select(2, sides()), tostring(state:GetAttribute("Made")), tostring(state:GetAttribute("LastParent"))))
	local spec = SPK[TIER]
	for i, s in ipairs(sounds) do
		local what = string.format("sound %d (%s)", i, s.sound.Name)
		assert(s.parent == spL or s.parent == spR, what .. " came from " .. name(s.parent) .. ", want the bedroom's RoomSpeaker_L or _R Cabinet")
		assert(s.parent:IsDescendantOf(plot), what .. "'s parent is outside the plot")
		assert(s.mode == Enum.RollOffMode.InverseTapered and math.abs(s.min - spec.rolloff[1]) < 1e-3 and math.abs(s.max - spec.rolloff[2]) < 1e-3,
			string.format("%s: rolloff %s %.1f..%.1f, want InverseTapered %d..%d (tier %d)", what, tostring(s.mode), s.min, s.max, spec.rolloff[1], spec.rolloff[2], TIER))
		assert(s.group == groups[TIER], what .. " plays through " .. name(s.group) .. ", want SoundService.OK_RoomTier" .. TIER)
		local kit = f:GetAttribute("Kit")
		local kits = samples and samples:FindFirstChild("Kits")
		local kitDir = kit and kit ~= "studio" and kits and kits:FindFirstChild(kit)
		local tmpl = (kitDir and kitDir:FindFirstChild(s.sound.Name)) or (samples and samples:FindFirstChild(s.sound.Name))
		if tmpl and tmpl:IsA("Sound") then
			assert(math.abs(s.volume - tmpl.Volume * spec.volume) < 1e-3, string.format("%s: volume %.3f, want the sample's %.3f x tier %d's %.2f", what, s.volume, tmpl.Volume, TIER, spec.volume))
		end
	end
	local lastParent = state:GetAttribute("LastParent") or ""
	assert(lastParent == spL:GetFullName() or lastParent == spR:GetFullName(), "the listener's last sound came from '" .. lastParent .. "', want a speaker's Cabinet")
	local l0, r0 = sides()
	table.insert(out, string.format("4 the listener on %s Token %s at tier %d: %d sounds (%d left, %d right) from the Cabinets, rolloff %d..%d, OK_RoomTier%d (EQ %s/%s/%s dB), volume x%.1f; the three groups' EQs match",
		plotName, tostring(token), TIER, #sounds, l0, r0, spec.rolloff[1], spec.rolloff[2], TIER, spec.eq[1], spec.eq[2], spec.eq[3], spec.volume))

	-- 5. MuteMonitors silences it
	player:SetAttribute("MuteMonitors", true)
	local made0, hits0 = state:GetAttribute("Made") or 0, state:GetAttribute("Hits") or 0
	task.wait(0.3) -- a sound made just before the mute may still be on its way to the watcher
	local n0 = #sounds
	local stepped = waitFor(function() return (state:GetAttribute("Hits") or 0) >= hits0 + 3 or state:GetAttribute("Playing") ~= true end, 8)
	assert(stepped and state:GetAttribute("Playing") == true, "muted: the play stopped or the steps stalled (Hits " .. tostring(hits0) .. " -> "
		.. tostring(state:GetAttribute("Hits")) .. ", Playing " .. tostring(state:GetAttribute("Playing")) .. ")")
	assert((state:GetAttribute("Made") or 0) == made0 and #sounds == n0, string.format("muted: the listener still made sounds (Made %d -> %d, seen %d -> %d) while Hits went %d -> %d",
		made0, state:GetAttribute("Made") or 0, n0, #sounds, hits0, state:GetAttribute("Hits") or 0))
	player:SetAttribute("MuteMonitors", wasMute)
	assert(waitFor(function() return (state:GetAttribute("Made") or 0) > made0 end, 6), "unmuted: no sound came back in 6 s (Playing " .. tostring(state:GetAttribute("Playing")) .. ")")
	table.insert(out, string.format("5 MuteMonitors: Hits %d -> %d with no sound made; unmuted, sounds again", hits0, state:GetAttribute("Hits") or 0))

	-- 6. the button on three phones
	cam.CameraType = Enum.CameraType.Custom
	local inset = cam.ViewportSize - dawGui.AbsoluteSize
	inset = Vector2.new(math.max(0, inset.X), math.max(0, inset.Y))
	for _, screen in ipairs({ Vector2.new(667, 375), Vector2.new(771, 390), Vector2.new(844, 390) }) do
		local vp = screen - inset
		local where = vp.X .. "x" .. vp.Y .. " (" .. screen.X .. "x" .. screen.Y .. " less " .. inset.X .. "x" .. inset.Y .. ")"
		-- the request card's overlays (a first-timer's picker opens by itself) and its phone card are modal: closed first
		local card = daw:FindFirstChild("Request")
		if card then card:SetAttribute("Command", ""); card:SetAttribute("Command", "close"); card:SetAttribute("CardOpen", false) end
		assert(not card or waitFor(function() return card:GetAttribute("Overlay") == "none" end, 3), where .. ": the request card's overlay '"
			.. tostring(card and card:GetAttribute("Overlay")) .. "' would not close")
		daw:SetAttribute("CompactForced", true); daw:SetAttribute("ViewportOverride", vp)
		assert(waitFor(function()
			return daw:GetAttribute("Compact") == true and math.abs(daw.AbsoluteSize.X - (vp.X - 12)) < 1 and math.abs(daw.AbsoluteSize.Y - (vp.Y - 12)) < 1
		end, 5), where .. ": the window did not take the phone layout (Compact " .. tostring(daw:GetAttribute("Compact")) .. ", " .. tostring(daw.AbsoluteSize) .. ")")
		task.wait(0.3) -- one layout pass for the transport column
		assert(shown(btn) and btn.Text == LABEL, where .. ": the button is hidden or reads '" .. btn.Text .. "'")
		local r = rel(btn)
		assert(btn.AbsoluteSize.X >= 44 and btn.AbsoluteSize.Y >= 44, where .. ": the button is " .. btn.AbsoluteSize.X .. "x" .. btn.AbsoluteSize.Y .. ", under 44 px")
		assert(btn.TextFits, where .. ": '" .. btn.Text .. "' doesn't fit its " .. btn.AbsoluteSize.X .. " px button")
		assert(r.x0 >= -0.5 and r.y0 >= -0.5 and r.x1 <= vp.X + 0.5 and r.y1 <= vp.Y + 0.5, where .. ": the button " .. fmt(r) .. " is outside (0,0)-(" .. vp.X .. "," .. vp.Y .. ")")
		local hits = {}
		for _, d in ipairs(daw:GetDescendants()) do
			if d:IsA("GuiButton") and d ~= btn and not d:IsDescendantOf(btn) and d.Name ~= "ModalCatcher" and shown(d) and overlaps(r, rel(d)) then
				table.insert(hits, d.Name .. " " .. fmt(rel(d)))
			end
		end
		assert(#hits == 0, where .. ": the button " .. fmt(r) .. " overlaps " .. table.concat(hits, ", "))
		table.insert(out, string.format("6 %s: the button %dx%d at %s, text fits, inside, overlaps nothing", where, btn.AbsoluteSize.X, btn.AbsoluteSize.Y, fmt(r)))
	end
	daw:SetAttribute("CompactForced", nil); daw:SetAttribute("ViewportOverride", nil)

	-- 7. DAW_Stop ends it
	Remotes.DAW_Stop:FireServer()
	assert(waitFor(function() return f:GetAttribute("Active") ~= true and state:GetAttribute("Playing") ~= true end, 8), "DAW_Stop: the folder reads Active "
		.. tostring(f:GetAttribute("Active")) .. " and the listener Playing " .. tostring(state:GetAttribute("Playing")) .. ", want both off")
	table.insert(out, "7 DAW_Stop: the play and the listener off")

	closeDaw()
	root.CFrame = CFrame.new(LOUNGE)
	return "T106B PLAY OK\n" .. table.concat(out, "\n")
end

local ok, msg = pcall(run)
conn:Disconnect()
if soundConn then soundConn:Disconnect() end
pcall(function() player:SetAttribute("MuteMonitors", wasMute) end)
pcall(function() daw:SetAttribute("CompactForced", nil); daw:SetAttribute("ViewportOverride", nil) end)
pcall(function() Remotes.DAW_Stop:FireServer() end)
pcall(function() if daw.Visible then daw:SetAttribute("Command", "close") end end)
pcall(function() cam.CameraType = Enum.CameraType.Custom end)
if not ok then
	pcall(function()
		local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if h and h.Sit then h.Sit = false; task.wait(0.4) end
		if r then r.CFrame = CFrame.new(LOUNGE) end
	end)
	error(msg, 0)
end
return msg
