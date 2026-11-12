-- Client, during play (the Your Rooms plan, Task 6; preflight F3: someone else's laptop), after t105c's staging: the
-- player is in their bedroom, which is staged as another owner's (OwnerId -10501, OwnerName "Test Owner 7"), with request
-- j1 active. Every step waits for its state, with a timeout. "The stand spot" is room-local (2, 0, -3), as in t105b.
-- (1) The bedroom with its laptop and RackSpot is on this client, and the staged OwnerId has replicated to it.
-- (2) Anything left open (the beat maker, the panel) is closed first, and checked closed.
-- (3) At the stand spot, pressing the laptop's prompt (InputHoldBegin / End) sends the owner toast "Test Owner 7's laptop.
--     only they can use it." (copy §3.1, the whole name) and no OpenDAW, and the beat maker stays shut for 1 s more.
--     The toast label (OK_UI.Toast) reads it, read one frame after it lands, within its 2.5 s: it wraps (TextWrapped), the
--     text fits (TextFits, its bounds inside the label) in two lines at most, and the label fits a 667x375 phone less this
--     gui's insets (its width inside the phone's, its height plus its 24 px bottom margin inside the phone's). The toast
--     ignores ForceViewport (it is laid out against the real window), so its size, not its position, is what is checked.
-- (4) Pressing the rack's prompt sends the same toast again and no OpenPanel, and the panel stays shut.
-- (5) The remotes answer "away" at someone else's laptop: Session_Deliver (DAWConfig.DefaultPattern, 140, 0) and
--     DAW_Broadcast (the same beat): DAW.StationOf counts a room's laptop for its owner only.
-- Then (and on any error, before the rethrow) the panel and the beat maker are closed, the camera is given back and the
-- character goes to the lounge. t105e puts the staging back.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character
local root = char and char:WaitForChild("HumanoidRootPart", 5)
local hum = char and char:WaitForChild("Humanoid", 5)
assert(root and hum, "no live character")
local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui", 10)
local ui = pg and pg:WaitForChild("OK_UI", 10); assert(ui, "no OK_UI")
local panel = ui:WaitForChild("Panel", 5); assert(panel, "no Panel")
local toast = ui:WaitForChild("Toast", 5); assert(toast, "no Toast label in OK_UI (PanelUI)")
local dawGui = pg:WaitForChild("OK_DAW", 10)
local daw = dawGui and dawGui:WaitForChild("DAW", 10)
assert(daw, "no beat maker gui (PlayerGui.OK_DAW.DAW)")
local DAWCfg = require(RS.OK.Modules.DAWConfig)
local Remotes = RS.OK.Remotes
local LOUNGE = Vector3.new(24, 3, 0)
local OTHER_ID = -10501 -- t105c's staging
local TOAST = "Test Owner 7's laptop. only they can use it." -- copy §3.1 with t105c's OwnerName, whole
local PHONE = Vector2.new(667, 375)
local RED = " (before the R-T6 sync: the expected red)"
local out = {}
local events = {} -- every InteractionEvent this client got: { kind, payload, t }
local conn = Remotes.InteractionEvent.OnClientEvent:Connect(function(kind, payload) table.insert(events, { kind = kind, payload = payload, t = os.clock() }) end)

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function str(v) return string.format("(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z) end
-- the events of `kind` (and toast text) that came at or after `since`
local function since(kind, t, text)
	local n = 0
	for _, e in ipairs(events) do
		if e.kind == kind and e.t >= t and (text == nil or (type(e.payload) == "table" and e.payload.text == text)) then n += 1 end
	end
	return n
end
local function toastsSince(t)
	local list = {}
	for _, e in ipairs(events) do
		if e.kind == "Toast" and e.t >= t then table.insert(list, type(e.payload) == "table" and tostring(e.payload.text) or "?") end
	end
	return table.concat(list, " | ")
end
local function closeAll()
	if daw.Visible then daw:SetAttribute("Command", "close") end
	assert(waitFor(function() return not daw.Visible end, 3), "the beat maker would not close (its Command 'close')")
	panel.Visible = false
end
-- presses `pp` (InputHoldBegin / End) up to 4 times until done() holds, `each` seconds a try
local function press(pp, done, each)
	for _ = 1, 4 do
		pp:InputHoldBegin(); task.wait(0.05); pp:InputHoldEnd()
		if waitFor(done, each or 1.5) then return true end
	end
	return false
end

local function run()
	-- 1. the staged bedroom on this client
	local slot = player:GetAttribute("PlotSlot")
	assert(waitFor(function() slot = player:GetAttribute("PlotSlot"); return type(slot) == "number" and slot > 0 end, 3),
		"PlotSlot is " .. tostring(slot) .. ", want the player's slot (t105c wakes the player up in their bedroom)")
	local plots = workspace:WaitForChild("OK_Plots", 5)
	assert(plots, "Workspace.OK_Plots is not on this client")
	local name = string.format("Plot_%02d", slot)
	local bedroom, station, rack
	local got = waitFor(function()
		local pm = plots:FindFirstChild(name)
		bedroom = pm and pm:FindFirstChild("Room_bedroom")
		if not bedroom then return false end
		station = nil
		for _, d in ipairs(bedroom:GetDescendants()) do
			if d:IsA("BasePart") and d:GetAttribute("Kind") == "Station" then station = d; break end
		end
		rack = bedroom:FindFirstChild("RackSpot")
		return station ~= nil and rack ~= nil
	end, 5)
	assert(got, name .. ".Room_bedroom with its laptop and RackSpot is not on this client 5 s into the test" .. RED)
	assert(waitFor(function() return bedroom:GetAttribute("OwnerId") == OTHER_ID end, 3), "the bedroom's OwnerId reads "
		.. tostring(bedroom:GetAttribute("OwnerId")) .. " on this client, want t105c's staged " .. OTHER_ID)
	local sp = station:FindFirstChildWhichIsA("ProximityPrompt")
	local rp = rack:FindFirstChildWhichIsA("ProximityPrompt")
	assert(sp and sp.Enabled and rp and rp.Enabled, "the laptop's or the rack's prompt is missing or off")
	table.insert(out, string.format("1 %s.Room_bedroom on this client, staged as OwnerId %d", name, OTHER_ID))

	-- 2. nothing open
	closeAll()
	assert(not daw.Visible and not panel.Visible, "the beat maker or the panel is still open before the first press")

	-- 3. the laptop's prompt: the owner toast, no beat maker
	if hum.Sit then hum.Sit = false; task.wait(0.4) end
	local stand = (bedroom:GetPivot() * CFrame.new(2, 0, -3)).Position + Vector3.new(0, 3, 0)
	local dd = (stand - station.Position).Magnitude
	assert(dd < sp.MaxActivationDistance - 1, string.format("the stand spot %s is %.1f studs from the laptop, past its prompt's reach %.1f", str(stand), dd, sp.MaxActivationDistance))
	root.CFrame = CFrame.lookAt(stand, Vector3.new(station.Position.X, stand.Y, station.Position.Z)); task.wait(1.0)
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.lookAt(stand + Vector3.new(0, 2.5, 0) + (stand - station.Position) * Vector3.new(1, 0, 1) * 0.3, station.Position)
	task.wait(1.0)
	local t3 = os.clock()
	local told = press(sp, function() return since("Toast", t3, TOAST) > 0 end, 1.5)
	assert(told, "pressing someone else's laptop sent no '" .. TOAST .. "' toast; toasts: " .. toastsSince(t3) .. RED)
	-- the label, one frame after the text lands (AutomaticSize grows it), within its 2.5 s
	assert(waitFor(function() return toast.Text == TOAST and toast.Visible end, 1), "the toast label reads '" .. toast.Text .. "' (visible "
		.. tostring(toast.Visible) .. "), want '" .. TOAST .. "'")
	task.wait()
	task.wait()
	local inset = cam.ViewportSize - ui.AbsoluteSize
	inset = Vector2.new(math.max(0, inset.X), math.max(0, inset.Y))
	local box = PHONE - inset
	local size, bounds = toast.AbsoluteSize, toast.TextBounds
	local lineH = TextService:GetTextSize("Ag", toast.TextSize, toast.Font, Vector2.new(1000, 1000)).Y
	local lines = math.max(1, math.floor(bounds.Y / lineH + 0.5))
	assert(toast.TextWrapped == true, "the toast label doesn't wrap (TextWrapped false): a long name would be cut")
	assert(toast.TextFits, string.format("the toast's text doesn't fit: bounds %dx%d in %dx%d", bounds.X, bounds.Y, size.X, size.Y))
	assert(bounds.X <= size.X + 0.5 and bounds.Y <= size.Y + 0.5, string.format("the toast's text runs past its label: bounds %dx%d in %dx%d", bounds.X, bounds.Y, size.X, size.Y))
	assert(lines <= 2, string.format("the toast runs to %d lines (bounds %d px tall, a line %d px), want 2 at most", lines, bounds.Y, lineH))
	assert(size.X <= box.X and size.Y + 24 <= box.Y, string.format("the toast label is %dx%d: past a %dx%d phone (667x375 less %dx%d) with its 24 px margin",
		size.X, size.Y, box.X, box.Y, inset.X, inset.Y))
	assert(since("OpenDAW", t3) == 0, "pressing someone else's laptop sent OpenDAW")
	task.wait(1)
	assert(not daw.Visible and since("OpenDAW", t3) == 0, "the beat maker opened at someone else's laptop")
	table.insert(out, string.format("3 someone else's laptop: '%s', no beat maker; the toast %dx%d, %d line(s), fits a %dx%d phone", TOAST, size.X, size.Y, lines, box.X, box.Y))

	-- 4. the rack's prompt: the toast again, no panel
	local t4 = os.clock()
	local again = press(rp, function() return since("Toast", t4, TOAST) > 0 end, 1.5)
	assert(again, "pressing someone else's rack sent no '" .. TOAST .. "' toast; toasts: " .. toastsSince(t4))
	task.wait(1)
	assert(not panel.Visible and since("OpenPanel", t4) == 0, "the panel opened from someone else's rack")
	table.insert(out, "4 someone else's rack: the same toast, no panel")

	-- 5. the remotes answer away at someone else's laptop
	local del = Remotes.Session_Deliver:InvokeServer(DAWCfg.DefaultPattern, 140, 0)
	assert(type(del) == "table" and del.ok ~= true and del.reason == "away", "Session_Deliver at someone else's laptop answered "
		.. tostring(del and del.ok) .. " / " .. tostring(del and del.reason) .. ", want false / away" .. RED)
	local air = Remotes.DAW_Broadcast:InvokeServer(DAWCfg.DefaultPattern, 140, 0)
	assert(type(air) == "table" and air.ok ~= true and air.reason == "away", "DAW_Broadcast at someone else's laptop answered "
		.. tostring(air and air.ok) .. " / " .. tostring(air and air.reason) .. ", want false / away" .. RED)
	table.insert(out, "5 at someone else's laptop: Session_Deliver away, DAW_Broadcast away")

	cam.CameraType = Enum.CameraType.Custom
	root.CFrame = CFrame.new(LOUNGE)
	return "T105D PLAY OK\n" .. table.concat(out, "\n")
end

local ok, msg = pcall(run)
conn:Disconnect()
pcall(function() panel.Visible = false end)
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
