-- OK Beat Maker client (v3): window, seated view, controls, local preview, slots, unlocks, kits and keys voices, saves, and the room listener.
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CP = game:GetService("ContentProvider")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local PPS = game:GetService("ProximityPromptService")
local CAS = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Cfg = require(RS.OK.Modules.DAWConfig)
local Theme = require(RS.OK.Modules.UITheme)
local Engine = require(RS.OK.Modules.DAWEngine)
local UI = require(RS.OK.Modules.DAWUI)
local Bus = require(RS.OK.Modules.BeatBus)
local Artists = require(RS.OK.Data.Artists)
local Check = require(RS.OK.Modules.BriefCheck)
local RequestUI = require(RS.OK.Modules.RequestUI)
local Booth = require(RS.OK.Modules.BoothArtist)
local DR = require(RS.OK.Modules.DailyRequests)
local Briefs = { Artists = Artists.Artists, ArtistById = Artists.ArtistById, BriefById = DR.Index(Artists) } -- regular + daily requests
local Remotes = RS.OK.Remotes
local Event = Remotes.InteractionEvent
local SaveFn = Remotes:WaitForChild("DAW_Save")
local BroadcastFn = Remotes:WaitForChild("DAW_Broadcast")
local StopEv = Remotes:WaitForChild("DAW_Stop")
local NP = RS.OK:WaitForChild("NowPlaying")
local samples = RS.OK:WaitForChild("Samples")
task.spawn(function() pcall(function() CP:PreloadAsync(samples:GetDescendants()) end) end)

local gui = Instance.new("ScreenGui")
gui.Name = "OK_DAW"
gui.ResetOnSpawn = false
gui.DisplayOrder = 5
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.Parent = player:WaitForChild("PlayerGui")
local ui = UI.Build(gui, Theme, Cfg)
local root = ui.Root
local preview = Engine.new(Cfg, samples)
-- kits you own (from your gear) and the kit the preview plays
local function syncKits()
	local have, kits = "," .. (player:GetAttribute("Gear") or "") .. ",", { "studio" }
	for _, k in ipairs(Cfg.Kits or {}) do
		if k.gear and string.find(have, "," .. k.gear .. ",", 1, true) then table.insert(kits, k.id) end
	end
	root:SetAttribute("Kits", table.concat(kits, ","))
	if not string.find("," .. table.concat(kits, ",") .. ",", "," .. (root:GetAttribute("Kit") or "studio") .. ",", 1, true) then root:SetAttribute("Kit", "studio") end
end
player:GetAttributeChangedSignal("Gear"):Connect(syncKits)
syncKits()
root:GetAttributeChangedSignal("Kit"):Connect(function() preview:SetKit(root:GetAttribute("Kit")) end)
preview:SetKit(root:GetAttribute("Kit"))
-- keys voices you own (the first is free) and the voice the preview plays
local function syncVoices()
	local have, voices = "," .. (player:GetAttribute("Gear") or "") .. ",", {}
	for _, v in ipairs(Cfg.Voices or {}) do
		if not v.gear or string.find(have, "," .. v.gear .. ",", 1, true) then table.insert(voices, v.id) end
	end
	root:SetAttribute("Voices", table.concat(voices, ","))
	if not string.find("," .. table.concat(voices, ",") .. ",", "," .. (root:GetAttribute("Voice") or "") .. ",", 1, true) then root:SetAttribute("Voice", voices[1]) end
end
player:GetAttributeChangedSignal("Gear"):Connect(syncVoices)
syncVoices()
root:GetAttributeChangedSignal("Voice"):Connect(function() preview:SetVoice(root:GetAttribute("Voice")) end)
preview:SetVoice(root:GetAttribute("Voice"))
-- a slot's voice comes back with it (or the free voice when it has none / you no longer own it)
local function applyVoice(voice)
	voice = type(voice) == "string" and voice or Cfg.Voices[1].id
	if not string.find("," .. (root:GetAttribute("Voices") or Cfg.Voices[1].id) .. ",", "," .. voice .. ",", 1, true) then voice = Cfg.Voices[1].id end
	root:SetAttribute("Voice", voice)
end
local daw = { v = 2, slots = {}, active = 1 } -- last known copy of the player's beats
local draft = nil -- unsaved beat kept across closes this session: {pattern, bpm, swing, slot}
local dirty = false
local loading = false
for _, a in ipairs({ "Pattern", "BPM", "Swing" }) do root:GetAttributeChangedSignal(a):Connect(function() if not loading and root.Visible then dirty = true end end) end
local myBroadcast = false
local myQueued = false -- waiting in the monitors' line

-- SAMPLE IT: copy the beat on the monitors into your beat maker; changed 8+ pads it airs as "flip of <producer>" --------
local sampleBtn = Instance.new("TextButton")
sampleBtn.Name = "SampleButton"; sampleBtn.AnchorPoint = Vector2.new(1, 0); sampleBtn.Position = UDim2.new(1, -16, 0, 124)
sampleBtn.Size = UDim2.fromOffset(136, 48); sampleBtn.ZIndex = 20; sampleBtn.Visible = false
sampleBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 90); sampleBtn.TextColor3 = Theme.text; sampleBtn.Font = Theme.fontBlack; sampleBtn.TextSize = 16
sampleBtn.Text = "🔁 SAMPLE IT"; sampleBtn:SetAttribute("Command", "")
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = sampleBtn end
sampleBtn.Parent = gui
local function nearSpeakers()
	local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local cr = workspace:FindFirstChild("OKStudio") and workspace.OKStudio:FindFirstChild("ControlRoom")
	if not (r and cr) then return false end
	for _, n in ipairs({ "Speaker_L", "Speaker_R" }) do local sp = cr:FindFirstChild(n); if sp and (sp.Position - r.Position).Magnitude <= 45 then return true end end
	return false
end
local function canSample()
	return NP:GetAttribute("Active") == true and NP:GetAttribute("OwnerId") ~= player.UserId and NP:GetAttribute("System") ~= true and nearSpeakers()
		and not (root.Visible and root:GetAttribute("Compact") == true)
end
task.spawn(function()
	while true do
		task.wait(0.2)
		sampleBtn.Visible = canSample()
		local fg = player.PlayerGui:FindFirstChild("OK_Fire"); local fb = fg and fg:FindFirstChild("FireButton")
		sampleBtn.Position = UDim2.new(1, -16, 0, ((fb and fb:GetAttribute("Top")) or 60) + 64)
	end
end)
-- keep only what your gear can play (rolls become single hats, 808 notes need the 808, swing needs the Swing Unit; the keys lane needs nothing)
local function playable(pattern, swing)
	pattern = Cfg.Upgrade(pattern)
	local u = "," .. (root:GetAttribute("Unlocked") or "") .. ","
	local has = function(f) return string.find(u, "," .. f .. ",", 1, true) ~= nil end
	local out = {}
	for t, tr in ipairs(Cfg.Tracks) do
		local seg = pattern:sub((t - 1) * Cfg.Steps + 1, t * Cfg.Steps)
		if tr.Kind == "roll" and not has("Rolls") then seg = seg:gsub("[23]", "1") end
		if tr.Kind == "bass" and not has("Bass") then seg = string.rep("0", Cfg.Steps) end
		table.insert(out, seg)
	end
	table.insert(out, Cfg.KeysSeg(pattern))
	return table.concat(out), has("Swing") and (swing or 0) or 0
end
local function doSample()
	if not canSample() then root:SetAttribute("LastSample", "unavailable"); return end
	local beat, bpm, sw = NP:GetAttribute("Beat"), NP:GetAttribute("BPM"), NP:GetAttribute("Swing") or 0
	local p, s = playable(beat, sw)
	root:SetAttribute("FlipToken", NP:GetAttribute("Token")); root:SetAttribute("FlipOf", NP:GetAttribute("OwnerName"))
	applyVoice(NP:GetAttribute("Voice")) -- the sampled melody keeps its instrument when you own it
	if ui.IsOpen() then
		loading = true; ui.Stop(); ui.Load(p, bpm, s); loading = false
		dirty = true
	else
		draft = { pattern = p, bpm = bpm, swing = s, slot = root:GetAttribute("Slot") or 1 }
	end
	root:SetAttribute("Status", "Sampled " .. tostring(NP:GetAttribute("OwnerName")) .. "'s beat · change " .. require(RS.OK.Modules.BriefCheck).MinChanged .. "+ pads, then ON MONITORS")
	root:SetAttribute("LastSample", "ok")
end
sampleBtn.MouseButton1Click:Connect(function() sampleBtn:SetAttribute("Command", "sample") end)
sampleBtn:GetAttributeChangedSignal("Command"):Connect(function()
	if sampleBtn:GetAttribute("Command") ~= "sample" then return end
	sampleBtn:SetAttribute("Command", "")
	doSample()
end)

-- Studio Sessions: request card, picker, presets, delivery and listen-back -------------------------
local SessGet, SessPick, SessDeliver = Remotes:WaitForChild("Session_Get"), Remotes:WaitForChild("Session_Pick"), Remotes:WaitForChild("Session_Deliver")
local req = RequestUI.Build(gui, Theme, Cfg, root, Briefs, Check)
local sess = { offers = {}, done = {}, deliveries = 0 }
local function extraRefs()
	local t = { sess.last }
	if NP:GetAttribute("Active") and NP:GetAttribute("OwnerId") ~= player.UserId then table.insert(t, NP:GetAttribute("Beat")) end
	return t
end
local function refreshTicks()
	if root.Visible then req.Update(root:GetAttribute("Pattern"), root:GetAttribute("BPM"), root:GetAttribute("Swing"), extraRefs()) end
end
for _, a in ipairs({ "Pattern", "BPM", "Swing" }) do root:GetAttributeChangedSignal(a):Connect(refreshTicks) end
local function setSessions(st)
	if type(st) ~= "table" then return end
	sess = st
	req.SetState(st)
	refreshTicks()
end
local function fetchSessions()
	local ok, st = pcall(function() return SessGet:InvokeServer() end)
	if ok then setSessions(st) end
	return ok
end
req.OnOpenPicker = function() fetchSessions(); req.ShowPicker() end
req.OnNext = function() fetchSessions(); req.ShowPicker() end
req.OnTake = function(id)
	local ok, res = pcall(function() return SessPick:InvokeServer(id) end)
	if ok and type(res) == "table" and res.ok then
		setSessions(res.state)
		req.SetMessage("")
		req.ShowPresets()
	else
		req.SetMessage("Couldn't take that request (" .. tostring(ok and res and res.reason or "error") .. ")")
		req.CloseOverlays()
	end
end
req.OnPreset = function(name)
	req.CloseOverlays()
	if name == "KEEP" then return end
	local pattern, bpm
	if name == "BLANK" then
		pattern, bpm = string.rep("0", #Cfg.Tracks * Cfg.Steps), root:GetAttribute("BPM")
	else
		for _, p in ipairs(Cfg.Presets) do if p.name == name then pattern, bpm = p.pattern, p.bpm end end
	end
	if not pattern then return end
	ui.Stop()
	ui.Load(pattern, bpm, 0)
	dirty = true
	root:SetAttribute("FlipToken", nil); root:SetAttribute("FlipOf", nil) -- a preset is not a flip
	root:SetAttribute("Status", "Started from " .. (name == "BLANK" and "a blank grid" or name) .. " · make it yours")
	refreshTicks()
end
local listenToken = 0
local cutPrev = nil -- camera state saved while the listen-back cutaway owns the camera
local function endCutaway()
	gui.Enabled = true
	req.Card:SetAttribute("Cutaway", false)
	if cutPrev then
		local cam = workspace.CurrentCamera
		cam.CameraType = cutPrev.type
		if cutPrev.type == Enum.CameraType.Scriptable then cam.CFrame = cutPrev.cf end
		cutPrev = nil
	end
end
req.OnDeliver = function()
	if (req.Card:GetAttribute("Active") or "") == "" then fetchSessions(); req.ShowPicker(); return end
	req.SetMessage("Delivering…")
	local pattern, bpm, sw = root:GetAttribute("Pattern"), root:GetAttribute("BPM"), root:GetAttribute("Swing")
	local ok, res = pcall(function() return SessDeliver:InvokeServer(pattern, bpm, sw) end)
	if not (ok and type(res) == "table") then req.SetMessage("Couldn't deliver right now"); req.Card:SetAttribute("LastDeliver", "error"); return end
	req.Card:SetAttribute("LastDeliver", res.ok and "ok" or tostring(res.reason))
	if not res.ok then
		local r = res.reason
		local m = r == "missing" and ("Not yet: " .. table.concat(res.missing or {}, ", "))
			or r == "copy" and string.format("Make it yours: change %d more pads", math.max(1, Check.MinChanged - (res.changed or 0)))
			or r == "away" and "Deliver from the studio PC or a studio laptop"
			or r == "locked" and "That beat uses something you haven't unlocked yet"
			or r == "noactive" and "Take a request first"
			or r == "expired" and "That daily request was yesterday's · take one of today's"
			or r == "cooldown" and "One moment…"
			or ("Couldn't deliver (" .. tostring(r) .. ")")
		req.SetMessage(m)
		return
	end
	req.SetMessage("")
	setSessions(res.state)
	-- listen-back: the camera cuts to the vocal booth, where the artist nods to two bars of your beat with their
	-- reaction overhead; then the camera comes back and the result screen shows the stars, pay and credit
	listenToken += 1
	local my = listenToken
	local brief = Briefs.BriefById[res.brief]; local artist = brief and Artists.ArtistById[brief.artist]
	local cam = workspace.CurrentCamera
	local fig = artist and Booth.Show(artist, res.stars, res.reaction, 9)
	local mineOnAir = NP:GetAttribute("Active") and NP:GetAttribute("OwnerId") == player.UserId
	local bars = 2 * Cfg.Steps * 60 / (bpm or 120) / 4
	local cut = math.clamp(bars, 3, 5)
	if fig and ui.IsOpen() then
		cutPrev = cutPrev or { type = cam.CameraType, cf = cam.CFrame }
		req.Card:SetAttribute("Cutaway", true)
		gui.Enabled = false
		cam.CameraType = Enum.CameraType.Scriptable
		local head = fig:FindFirstChild("Head")
		local look = head and head.Position or Vector3.new(83.6, 4.2, -2)
		-- just inside the booth glass (the tinted pane would wash the shot out), angled so the artist and the
		-- reaction above them both fit
		local aim = look - Vector3.new(0, 0.9, 0)
		cam.CFrame = CFrame.lookAt(Vector3.new(80.5, 4.6, look.Z + 4.5), aim)
		cam.Focus = CFrame.new(aim)
		if not mineOnAir then ui.Play() end
		task.delay(cut, function()
			if listenToken ~= my then return end
			if not mineOnAir and ui.IsOpen() then ui.Stop() end
			endCutaway()
			if ui.IsOpen() then req.ShowResult(res) end
		end)
	else
		req.ShowResult(res)
	end
end
-- place in the waiting line (1 = next): "Up next", then "#2 in line", ...
local function placeText(pos, wait)
	local s = pos == 1 and "Up next on the monitors" or string.format("#%d in line for the monitors", pos)
	return (wait and wait > 0) and (s .. string.format(" · about %ds", wait)) or s
end
local function syncLevel() root:SetAttribute("Level", player:GetAttribute("Level") or 1) end
player:GetAttributeChangedSignal("Level"):Connect(syncLevel)
syncLevel()
-- locks follow the gear you own (server-set player attribute Unlocked = "Bass,Rolls,Swing")
local function syncUnlocked() local u = player:GetAttribute("Unlocked"); if u ~= nil then root:SetAttribute("Unlocked", u) end end
player:GetAttributeChangedSignal("Unlocked"):Connect(syncUnlocked)
syncUnlocked()

-- phone layout ----------------------------------------------------------------
local function compactWanted()
	local forced = root:GetAttribute("CompactForced")
	if forced ~= nil then return forced end
	local vp = workspace.CurrentCamera.ViewportSize
	return UIS.TouchEnabled and vp.Y < 600
end
local function refreshCompact() root:SetAttribute("Compact", compactWanted()) end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshCompact)
root:GetAttributeChangedSignal("CompactForced"):Connect(refreshCompact)
refreshCompact()

local function hintText()
	local last = UIS:GetLastInputType().Name
	if last:find("Gamepad") then return "X play/stop  ·  Y keys/drums  ·  B close  ·  A toggles a pad" end
	if UIS.TouchEnabled and not UIS.KeyboardEnabled then return "Tap a pad  ·  slide along a row to fill it" end
	return "Space play/stop  ·  K keys/drums  ·  Backspace close  ·  click and drag along a row"
end

-- modal state: everything the window changes is undone in restore() --------------
local modal = { active = false, seated = false, camChanged = false }
local sourcePos = nil

local inputConn = nil
local function restore()
	listenToken += 1
	endCutaway()
	if not modal.active then return end
	modal.active = false
	if dirty then
		draft = { pattern = root:GetAttribute("Pattern"), bpm = root:GetAttribute("BPM"), swing = root:GetAttribute("Swing"), slot = root:GetAttribute("Slot") }
	end
	if inputConn then inputConn:Disconnect(); inputConn = nil end
	CAS:UnbindAction("OK_DAW_PlayStop")
	CAS:UnbindAction("OK_DAW_Close")
	CAS:UnbindAction("OK_DAW_Keys")
	preview:Stop()
	root.Visible = false
	root:SetAttribute("Playing", false)
	root:SetAttribute("Step", 0)
	player:SetAttribute("DAWPlaying", false)
	PPS.Enabled = true
	pcall(function() GuiService.TouchControlsEnabled = true end)
	if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(gui) then GuiService.SelectedObject = nil end
	if modal.camChanged then
		workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
		modal.camChanged = false
	end
	if modal.seated then
		modal.seated = false
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum and hum.SeatPart then hum.Sit = false end
	end
	root:SetAttribute("Seated", false)
	sourcePos = nil
end
ui.OnHide = function(...)
	listenToken += 1
	endCutaway() -- closing mid-cutaway (Backspace / B / walking off) must still give the camera back
	req.Hide(); Booth.Hide()
	return restore(...)
end

local function playStopAction(_, state)
	if state == Enum.UserInputState.Begin then
		if root:GetAttribute("Playing") then ui.Stop() else ui.Play() end
	end
	return Enum.ContextActionResult.Sink
end
local function closeAction(_, state)
	if state == Enum.UserInputState.Begin then ui.Hide() end
	return Enum.ContextActionResult.Sink
end
local function keysAction(_, state)
	if state == Enum.UserInputState.Begin then ui.ToggleView() end
	return Enum.ContextActionResult.Sink
end

local function seatCameraCFrame()
	local s = workspace:FindFirstChild("OKStudio")
	local chair = s and s.ControlRoom:FindFirstChild("Chair_Seat")
	if not chair then return nil end
	local base = chair.Position
	return CFrame.lookAt(base + Cfg.SeatCamera.Offset, base + Cfg.SeatCamera.LookOffset)
end

local function enter(seated)
	if not modal.active then
		modal.active = true
		PPS.Enabled = false
		pcall(function() GuiService.TouchControlsEnabled = false end)
		local prio = Enum.ContextActionPriority.High.Value + 50
		CAS:BindActionAtPriority("OK_DAW_PlayStop", playStopAction, false, prio, Enum.KeyCode.Space, Enum.KeyCode.ButtonX)
		CAS:BindActionAtPriority("OK_DAW_Close", closeAction, false, prio, Enum.KeyCode.Backspace, Enum.KeyCode.ButtonB)
		CAS:BindActionAtPriority("OK_DAW_Keys", keysAction, false, prio, Enum.KeyCode.K, Enum.KeyCode.ButtonY)
	end
	ui.SetHint(hintText())
	if not inputConn then
		inputConn = UIS.LastInputTypeChanged:Connect(function(t)
			ui.SetHint(hintText())
			if t.Name:find("Gamepad") and not GuiService.SelectedObject then GuiService.SelectedObject = ui.FirstCell() end
		end)
	end
	if seated and not modal.seated then
		modal.seated = true
		root:SetAttribute("Seated", true)
		local cf = seatCameraCFrame()
		if cf then
			local cam = workspace.CurrentCamera
			cam.CameraType = Enum.CameraType.Scriptable
			modal.camChanged = true
			TweenService:Create(cam, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = cf }):Play()
		end
	end
	if UIS:GetLastInputType().Name:find("Gamepad") then GuiService.SelectedObject = ui.FirstCell() end
end

local function hookCharacter(char)
	local hum = char:WaitForChild("Humanoid", 10)
	if not hum then return end
	hum.Died:Connect(restore)
	hum.Seated:Connect(function(active)
		if not active and modal.seated and modal.active then ui.Hide() end
	end)
end
player.CharacterAdded:Connect(function(c) restore(); hookCharacter(c) end)
player.CharacterRemoving:Connect(restore)
if player.Character then task.spawn(hookCharacter, player.Character) end

-- local preview ------------------------------------------------------------------
ui.OnPlayChanged = function(on)
	if on then
		if NP:GetAttribute("Active") and NP:GetAttribute("OwnerId") == player.UserId then
			StopEv:FireServer()
			root:SetAttribute("Status", "Stopped your beat on the monitors")
		end
		preview:Start(function() return root:GetAttribute("Pattern") end, function() return root:GetAttribute("BPM") end,
			function(step, hits, hitTracks)
				root:SetAttribute("Step", step)
				root:SetAttribute("Hits", hits)
				Bus.Fire(step, hitTracks, "local")
			end, nil, function() return root:GetAttribute("Swing") or 0 end)
	else
		preview:Stop()
		root:SetAttribute("Step", 0)
	end
	player:SetAttribute("DAWPlaying", on)
end
ui.OnAudition = function(t, ch)
	local tr = Cfg.Tracks[t]
	if not ch then ch = tr.Kind == "bass" and Cfg.NoteChar(0) or "1" end
	preview:PlayCell(t, ch, 60 / (root:GetAttribute("BPM") or Cfg.BPM.Default) / 4, 0)
	root:SetAttribute("Hits", preview.hits)
	Bus.Fire(0, { [tr.Name] = true }, "audition")
end
ui.OnNote = function(semi, len, accent)
	preview:PlayNote(semi, len or 1, 60 / (root:GetAttribute("BPM") or Cfg.BPM.Default) / 4, 0, accent)
	root:SetAttribute("Hits", preview.hits)
	Bus.Fire(0, { Keys = true }, "audition")
end
local function getSlot(d, n)
	if type(d) ~= "table" or type(d.slots) ~= "table" then return nil end
	return d.slots["s" .. n] or d.slots[n] or d.slots[tostring(n)]
end
local function slotBeat(n)
	local sl = getSlot(daw, n)
	if sl then return Cfg.Upgrade(sl.pattern), sl.bpm or Cfg.BPM.Default, sl.swing or 0, sl.kit, sl.voice end
	if n == 1 then return Cfg.DefaultPattern, Cfg.BPM.Default, 0 end
	return string.rep("0", #Cfg.Tracks * Cfg.Steps), Cfg.BPM.Default, 0
end
local function endFlip() root:SetAttribute("FlipToken", nil); root:SetAttribute("FlipOf", nil) end
-- a slot's kit comes back with it (or STUDIO when it has none / you no longer own it)
local function applyKit(kit)
	kit = type(kit) == "string" and kit or "studio"
	if not string.find("," .. (root:GetAttribute("Kits") or "studio") .. ",", "," .. kit .. ",", 1, true) then kit = "studio" end
	root:SetAttribute("Kit", kit)
end
ui.OnSlot = function(n)
	endFlip()
	local p, b, sw, kit, voice = slotBeat(n)
	loading = true
	ui.Load(p, b, sw)
	applyKit(kit)
	applyVoice(voice)
	loading = false
	dirty = false; draft = nil
	root:SetAttribute("Status", "Slot " .. n .. (getSlot(daw, n) and "" or " · empty"))
end

ui.OnSave = function()
	root:SetAttribute("Status", "Saving…")
	local ok, res = pcall(function() return SaveFn:InvokeServer(root:GetAttribute("Pattern"), root:GetAttribute("BPM"), root:GetAttribute("Swing"), root:GetAttribute("Slot"), root:GetAttribute("Kit"), root:GetAttribute("Voice")) end)
	if ok and type(res) == "table" and res.ok then
		if res.profile and res.profile.daw then daw = res.profile.daw end
		dirty = false; draft = nil
		local xp = (tonumber(res.xp) or 0) > 0 and (" · +" .. res.xp .. " XP") or ""
		root:SetAttribute("Status", res.persistent and ("Saved" .. xp) or ("Saved for this session (place not published yet)" .. xp))
		root:SetAttribute("LastSave", "ok")
	else
		local reason = (ok and type(res) == "table" and res.reason) or "error"
		local msg = reason == "cooldown" and "Wait a moment before saving again"
			or reason == "locked" and "That beat uses something you haven't unlocked yet"
			or reason == "empty" and "Nothing to save · add some hits first"
			or ("Not saved (" .. reason .. ")")
		root:SetAttribute("Status", msg)
		root:SetAttribute("LastSave", reason)
	end
end

ui.OnMonitors = function()
	root:SetAttribute("Status", "Sending to the monitors…")
	local ok, res = pcall(function() return BroadcastFn:InvokeServer(root:GetAttribute("Pattern"), root:GetAttribute("BPM"), root:GetAttribute("Swing"), root:GetAttribute("FlipToken"), root:GetAttribute("Kit"), root:GetAttribute("Voice")) end)
	if ok and type(res) == "table" and res.ok then
		root:SetAttribute("QueuePos", res.position or 0)
		root:SetAttribute("LastBroadcast", "ok")
		if (res.position or 0) == 0 then
			ui.Stop()
			myBroadcast = true
			root:SetAttribute("Status", "On the monitors · everyone nearby hears it")
		else
			myQueued = true
			root:SetAttribute("Status", placeText(res.position, res.wait))
		end
	else
		local reason = (ok and type(res) == "table" and res.reason) or "error"
		local msg
		if reason == "inline" then
			local pos = res.position or 0
			msg = pos == 0 and "Your beat is on the monitors now" or pos == 1 and "You're already up next" or string.format("You're already #%d in line", pos)
		elseif reason == "full" then msg = "The line for the monitors is full · try again in a bit"
		elseif reason == "cypher" then msg = "A cypher round has the monitors · try again after the reveal"
		elseif reason == "flipcopy" then msg = string.format("Make the flip yours: change %d more pads", math.max(1, 8 - (res.changed or 0)))
		elseif reason == "copy" then msg = "That's someone else's beat · use SAMPLE IT and change 8+ pads to flip it"
		elseif reason == "gone" then msg = "That sample is too old now · sample a beat that's on the monitors"; root:SetAttribute("FlipToken", nil); root:SetAttribute("FlipOf", nil)
		elseif reason == "off" then msg = "The monitors are switched off"
		elseif reason == "empty" then msg = "Add a few hits first"
		elseif reason == "locked" then msg = "That beat uses something you haven't unlocked yet"
		elseif reason == "away" then msg = "Use the studio PC or a studio laptop for the monitors"
		else msg = "Couldn't play on the monitors (" .. tostring(reason) .. ")" end
		root:SetAttribute("Status", msg)
		root:SetAttribute("LastBroadcast", reason)
	end
end

-- open --------------------------------------------------------------------------
local function resolve(fullName)
	local node = game
	for seg in string.gmatch(fullName, "[^%.]+") do node = node and node:FindFirstChild(seg) end
	return node
end
Event.OnClientEvent:Connect(function(kind, payload)
	if kind ~= "OpenDAW" then return end
	local src = payload.source and resolve(payload.source)
	sourcePos = (src and src:IsA("BasePart")) and src.Position or nil
	if type(payload.daw) == "table" then daw = payload.daw end
	if payload.level then root:SetAttribute("Level", payload.level) end
	refreshCompact()
	if not ui.IsOpen() then
		loading = true
		if draft then
			ui.Show(draft.pattern, draft.bpm, draft.swing, draft.slot)
			root:SetAttribute("Status", "Unsaved beat kept · press SAVE to keep it")
		else
			local slot = (daw and daw.active) or 1
			local p, b, sw, kit, voice = slotBeat(slot)
			ui.Show(p, b, sw, slot)
			applyKit(kit)
			applyVoice(voice)
		end
		loading = false
	end
	enter(payload.seated == true)
	-- sessions: refresh the card; a first-timer with nothing taken sees the requests straight away
	task.spawn(function()
		if fetchSessions() and not sess.active and (sess.deliveries or 0) == 0 and #(sess.offers or {}) > 0 then req.ShowPicker() end
	end)
end)

RunService.Heartbeat:Connect(function()
	if ui.IsOpen() and modal.active and not modal.seated and sourcePos then
		local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if r and (r.Position - sourcePos).Magnitude > Cfg.CloseDistance then ui.Hide() end
	end
end)

-- room listener: every client plays the monitors' beat from the speakers, timed from server time --------
local function speakerFor(t)
	local s = workspace:FindFirstChild("OKStudio")
	local cr = s and s:FindFirstChild("ControlRoom")
	local L = cr and cr:FindFirstChild("Speaker_L")
	local R = cr and cr:FindFirstChild("Speaker_R")
	if t % 2 == 1 then return L or R end
	return R or L
end
local listener = Engine.new(Cfg, samples, { parentFor = speakerFor, volumeScale = Cfg.Broadcast.VolumeScale, rolloff = Cfg.Broadcast.Rolloff,
	muted = function() return player:GetAttribute("MuteMonitors") == true end })
local listenerToken = nil
local function onNowPlaying()
	local active = NP:GetAttribute("Active") == true
	local tok = NP:GetAttribute("Token")
	if active and tok ~= listenerToken then
		listener:Stop()
		listenerToken = tok
		local beat, bpm, sw = NP:GetAttribute("Beat"), NP:GetAttribute("BPM"), NP:GetAttribute("Swing") or 0
		listener:SetKit(NP:GetAttribute("Kit")) -- everyone hears the producer's kit
		listener:SetVoice(NP:GetAttribute("Voice")) -- and their keys voice
		listener.hits = 0
		gui:SetAttribute("ListenerHits", 0)
		listener:Start(function() return beat end, function() return bpm end, function(step, hits, hitTracks)
			gui:SetAttribute("ListenerStep", step)
			gui:SetAttribute("ListenerHits", hits)
			Bus.Fire(step, hitTracks, "monitors")
		end, {
			clock = function() return workspace:GetServerTimeNow() end,
			startAt = NP:GetAttribute("StartAt"),
			maxSteps = (NP:GetAttribute("Loops") or 4) * Cfg.Steps,
		}, function() return sw end)
	elseif not active and listener.playing then
		listener:Stop()
		listenerToken = nil
	end
	local mine = active and NP:GetAttribute("OwnerId") == player.UserId
	if mine and not myBroadcast then -- your turn came up: the room plays it, so your own preview stops
		myBroadcast = true; myQueued = false
		root:SetAttribute("QueuePos", 0)
		if ui.IsOpen() then ui.Stop(); root:SetAttribute("Status", "On the monitors · everyone nearby hears it") end
	elseif not mine and myBroadcast then
		myBroadcast = false
		root:SetAttribute("QueuePos", -1)
		if ui.IsOpen() then root:SetAttribute("Status", "Done on the monitors") end
	end
	gui:SetAttribute("ListenerPlaying", listener.playing)
end
-- your place in line follows the server's queue (QueueIds = waiting producers in order)
local function onQueue()
	if not myQueued then return end
	local pos = 0
	local i = 0
	for id in string.gmatch(NP:GetAttribute("QueueIds") or "", "[^,]+") do
		i += 1
		if tonumber(id) == player.UserId then pos = i end
	end
	if pos == 0 then
		if not (NP:GetAttribute("Active") and NP:GetAttribute("OwnerId") == player.UserId) then
			myQueued = false; root:SetAttribute("QueuePos", -1)
			if ui.IsOpen() then root:SetAttribute("Status", "Taken out of the line") end
		end
		return
	end
	root:SetAttribute("QueuePos", pos)
	if ui.IsOpen() then root:SetAttribute("Status", placeText(pos)) end
end
NP:GetAttributeChangedSignal("QueueIds"):Connect(onQueue)
NP:GetAttributeChangedSignal("Active"):Connect(onNowPlaying)
NP:GetAttributeChangedSignal("Token"):Connect(onNowPlaying)
onNowPlaying()
