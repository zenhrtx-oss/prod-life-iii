-- OK Studio room listener (the Your Rooms plan, Task 7). A room play (Systems/Rooms.PlayLocal: ON SPEAKERS at your own
-- room's laptop) plays on that room's own speakers for everyone standing in the plot. This client plays the folder
-- ReplicatedStorage.OK.RoomPlaying.Plot_<k> of the plot it stands in (the server's InPlot attribute; 0 outside every
-- plot) with one DAWEngine, timed from server time as DAWClient's monitors listener is, so everyone in the room hears the
-- same step. The play's Tier (the owner's speakers when it started) picks Config.Rooms.Speakers[Tier]:
-- * where it comes from: tier 1 (the laptop's own speakers) from the room's Station; tier 2 and 3 from the Cabinet parts
--   of the room's RoomSpeaker_L / _R models (Modules/RoomItems; odd tracks left, even right), from the Station while those
--   are missing. Nothing plays while the room itself isn't on this client: never a 2D sound heard everywhere;
-- * how loud and how far: every sample's own volume times the tier's volume, and the tier's rolloff { min, max }
--   (InverseTapered);
-- * how it sounds: the tier's SoundGroup SoundService.OK_RoomTier<n>, with an EqualizerSoundEffect "EQ" at the tier's
--   eq = { low, mid, high } dB.
-- The HUD's mute (the player attribute MuteMonitors) mutes it. It stops when InPlot changes (and picks up the new plot's
-- play, part-way through, when there is one), and when the play ends, is stopped or is replaced (a new Token).
-- State, for tests, on the Folder SoundService.OK_RoomListener: Playing, Plot, Token, Tier, Room, Step, Hits (the steps'
-- hits, muted ones included), Made (sounds made) and LastParent (the full name of the last sound's parent).
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local OK = RS:WaitForChild("OK", 30)
local playing = OK and OK:WaitForChild("RoomPlaying", 30)
local samples = OK and OK:WaitForChild("Samples", 30)
if not (playing and samples) then
	warn("[OK][ERR] room listener: ReplicatedStorage.OK.RoomPlaying or Samples missing (run build/19_rooms.lua and build/10_daw.lua in Edit)")
	return
end
local Config = require(OK.Config)
local Cfg = require(OK.Modules.DAWConfig)
local Engine = require(OK.Modules.DAWEngine)
local SPEAKERS = (Config.Rooms and Config.Rooms.Speakers) or {}
if #SPEAKERS == 0 then return end

-- one SoundGroup a tier, each with its EQ
local groups = {}
for i, t in ipairs(SPEAKERS) do
	local name = "OK_RoomTier" .. i
	local g = SoundService:FindFirstChild(name)
	if not (g and g:IsA("SoundGroup")) then
		g = Instance.new("SoundGroup")
		g.Name = name
	end
	g.Volume = 1
	local eq = g:FindFirstChild("EQ")
	if not (eq and eq:IsA("EqualizerSoundEffect")) then
		eq = Instance.new("EqualizerSoundEffect")
		eq.Name = "EQ"
	end
	eq.LowGain, eq.MidGain, eq.HighGain = t.eq[1], t.eq[2], t.eq[3]
	eq.Enabled = true
	eq.Parent = g
	g.Parent = SoundService
	groups[i] = g
end
local state = SoundService:FindFirstChild("OK_RoomListener")
if not (state and state:IsA("Folder")) then
	state = Instance.new("Folder")
	state.Name = "OK_RoomListener"
	state.Parent = SoundService
end
state:SetAttribute("Playing", false)
state:SetAttribute("Made", 0)

-- the play this client is on: its plot, Token, tier and room kind, and the parts its sounds come from
local cur = { plot = 0, token = nil, tier = 1, room = "bedroom", emit = nil }
local made = 0

local function plotName(k) return string.format("Plot_%02d", k) end
local function roomModel()
	local plots = workspace:FindFirstChild("OK_Plots")
	local pm = plots and cur.plot > 0 and plots:FindFirstChild(plotName(cur.plot))
	return pm and pm:FindFirstChild("Room_" .. tostring(cur.room)) or nil
end
local function stationOf(room)
	for _, d in ipairs(room:GetDescendants()) do
		if d:IsA("BasePart") and d:GetAttribute("Kind") == "Station" then return d end
	end
	return nil
end
local function cabinet(room, side)
	local m = room:FindFirstChild("RoomSpeaker_" .. side)
	local c = m and m:FindFirstChild("Cabinet")
	return (c and c:IsA("BasePart")) and c or nil
end
local function live(part) return part ~= nil and part:IsDescendantOf(workspace) end
-- { left, right }: kept while both parts stay in Workspace, looked up again once one has gone (a speaker refit, streaming)
local function emitters()
	local e = cur.emit
	if e and live(e[1]) and live(e[2]) then return e end
	cur.emit = nil
	local room = roomModel()
	if not room then return nil end
	local L, R
	if cur.tier >= 2 then L, R = cabinet(room, "L"), cabinet(room, "R") end
	if not (L or R) then
		local st = stationOf(room)
		L, R = st, st
	end
	if not (L or R) then return nil end
	cur.emit = { L or R, R or L }
	return cur.emit
end

local engine = Engine.new(Cfg, samples, {
	-- called only for a sound that will play (muted is asked first)
	parentFor = function(t)
		local e = emitters()
		local part = e and e[(t % 2 == 1) and 1 or 2]
		made += 1
		state:SetAttribute("Made", made)
		state:SetAttribute("LastParent", part and part:GetFullName() or "")
		return part
	end,
	muted = function() return player:GetAttribute("MuteMonitors") == true or emitters() == nil end,
})

local function stop()
	if engine.playing then engine:Stop() end
	cur.token, cur.emit = nil, nil
	state:SetAttribute("Playing", false)
end

local function start(f, k)
	engine:Stop()
	local beat, bpm, sw = f:GetAttribute("Beat"), f:GetAttribute("BPM"), f:GetAttribute("Swing") or 0
	local tier = math.clamp(math.floor(tonumber(f:GetAttribute("Tier")) or 1), 1, #SPEAKERS)
	local spec = SPEAKERS[tier]
	cur.plot, cur.token, cur.tier, cur.emit = k, f:GetAttribute("Token"), tier, nil
	cur.room = type(f:GetAttribute("Room")) == "string" and f:GetAttribute("Room") or "bedroom"
	state:SetAttribute("Plot", k); state:SetAttribute("Token", cur.token); state:SetAttribute("Tier", tier)
	state:SetAttribute("Room", cur.room); state:SetAttribute("Step", 0); state:SetAttribute("Hits", 0)
	if type(beat) ~= "string" or type(bpm) ~= "number" or bpm <= 0 then
		state:SetAttribute("Playing", false)
		return
	end
	engine.opts.rolloff = spec.rolloff
	engine.opts.volumeScale = spec.volume
	engine.opts.soundGroup = groups[tier]
	engine:SetKit(f:GetAttribute("Kit"))
	engine:SetVoice(f:GetAttribute("Voice"))
	engine.hits = 0
	engine:Start(function() return beat end, function() return bpm end, function(step, hits)
		state:SetAttribute("Step", step)
		state:SetAttribute("Hits", hits)
	end, {
		clock = function() return workspace:GetServerTimeNow() end,
		startAt = tonumber(f:GetAttribute("StartAt")) or 0,
		maxSteps = (tonumber(f:GetAttribute("Loops")) or 4) * Cfg.Steps,
		onDone = function() state:SetAttribute("Playing", false) end, -- ran its course: the same Token is never restarted
	}, function() return sw end)
	state:SetAttribute("Playing", true)
end

-- the plot this client stands in, and its play: on when Active (a new plot or Token starts it), off when not
local function refresh()
	local k = player:GetAttribute("InPlot")
	k = type(k) == "number" and k or 0
	local f = k > 0 and playing:FindFirstChild(plotName(k)) or nil
	if not (f and f:GetAttribute("Active") == true) then
		if cur.token ~= nil or engine.playing then stop() end
		cur.plot = k
		return
	end
	if k == cur.plot and f:GetAttribute("Token") == cur.token then return end -- on already, or it ran its course
	start(f, k)
end

local function watch(f)
	if not f:IsA("Folder") then return end
	f:GetAttributeChangedSignal("Token"):Connect(refresh)
	f:GetAttributeChangedSignal("Active"):Connect(refresh)
end
for _, f in ipairs(playing:GetChildren()) do watch(f) end
playing.ChildAdded:Connect(watch)
player:GetAttributeChangedSignal("InPlot"):Connect(function()
	stop() -- a new place: whatever played here stops, and the new plot's play (if any) starts part-way
	refresh()
end)
refresh()
