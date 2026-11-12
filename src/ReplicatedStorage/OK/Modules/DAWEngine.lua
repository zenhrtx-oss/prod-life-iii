-- OK Beat Maker playback engine (client), beat format v3.
-- Local preview: steps advance on Heartbeat from os.clock(); a late frame drops steps instead of bunching them.
-- Synced (monitors): every client computes the step from server time, so all listeners hear the same step.
-- Per step: hit tracks fire once; roll tracks fire 1-3 times across the step; the bass track is pitched per note;
-- keys notes play the voice sample repitched, held for their length then faded; swing delays every second 16th by
-- swing% of half a step.
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local E = {}
E.__index = E

-- opts.parentFor(track) -> Instance; opts.volumeScale; opts.rolloff = {min, max}; opts.muted() -> bool;
-- opts.soundGroup = a SoundGroup every sound plays through (a room's speaker tier, StarterPlayerScripts/OK/RoomClient).
-- Every sound reads opts as it is made, so a caller may change them between plays
function E.new(cfg, samples, opts)
	opts = opts or {}
	local self = setmetatable({ cfg = cfg, samples = samples, playing = false, step = 0, hits = 0, opts = opts }, E)
	self:SetVoice(nil)
	return self
end

-- choose a drum kit by id ("studio"/nil = default samples); missing kit sounds fall back to the default
function E:SetKit(id)
	local kits = self.samples:FindFirstChild("Kits")
	self.kit = (id and id ~= "studio" and kits) and kits:FindFirstChild(id) or nil
	self.kitId = self.kit and id or "studio"
end

-- choose the keys instrument by id (nil/unknown = the first voice)
function E:SetVoice(id)
	local voices = self.samples:FindFirstChild("Voices")
	local def = self.cfg.Voices and self.cfg.Voices[1]
	local s = voices and id and voices:FindFirstChild(id)
	self.voice = s or (voices and def and voices:FindFirstChild(def.id)) or nil
	self.voiceId = (s and id) or (def and def.id) or nil
end

local function setup(self, tmpl, t)
	local s = tmpl:Clone()
	local parent = self.opts.parentFor and self.opts.parentFor(t) or SoundService
	if self.opts.volumeScale then s.Volume = s.Volume * self.opts.volumeScale end
	if self.opts.rolloff then
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = self.opts.rolloff[1]
		s.RollOffMaxDistance = self.opts.rolloff[2]
	end
	if self.opts.soundGroup then s.SoundGroup = self.opts.soundGroup end
	s.Parent = parent
	return s
end

function E:Trigger(t, semitones)
	local tr = self.cfg.Tracks[t]
	local tmpl = tr and ((self.kit and self.kit:FindFirstChild(tr.Name)) or self.samples:FindFirstChild(tr.Name))
	if not tmpl then return end
	if self.opts.muted and self.opts.muted() then self.hits += 1; return end
	local s = setup(self, tmpl, t)
	if semitones then s.PlaybackSpeed = 2 ^ (semitones / 12) end
	s:Play()
	Debris:AddItem(s, tr.Gate)
	self.hits += 1
	return s
end

-- a keys note: the voice sample repitched, held lenSteps steps (stepLen seconds each) and faded out at the end;
-- an accent (uppercase letter) plays Keys.Accent times louder
function E:PlayNote(semi, lenSteps, stepLen, delay, accent)
	local tmpl = self.voice
	if not tmpl then return end
	local function go()
		if self.opts.muted and self.opts.muted() then self.hits += 1; return end
		local vc = self.cfg.VoiceById and self.cfg.VoiceById(self.voiceId)
		local s = setup(self, tmpl, #self.cfg.Tracks + 1)
		s.PlaybackSpeed = 2 ^ ((semi + (vc and vc.Tune or 0)) / 12)
		if accent then s.Volume = s.Volume * (self.cfg.Keys and self.cfg.Keys.Accent or 1.35) end
		s:Play()
		local gate = math.max(1, lenSteps or 1) * stepLen
		local rel = self.cfg.Keys and self.cfg.Keys.Release or 0.08
		task.delay(math.max(0, gate - rel), function()
			if s.Parent then TweenService:Create(s, TweenInfo.new(rel, Enum.EasingStyle.Linear), { Volume = 0 }):Play() end
		end)
		Debris:AddItem(s, gate + 0.15)
		self.hits += 1
	end
	if delay and delay > 0 then task.delay(delay, go) else go() end
end

-- play one cell value for track t; `delay` shifts it (swing); `stepLen` is the step duration in seconds
function E:PlayCell(t, ch, stepLen, delay)
	local tr = self.cfg.Tracks[t]
	if ch == "0" or not tr then return false end
	local function fire(semi) if delay and delay > 0 then task.delay(delay, function() self:Trigger(t, semi) end) else self:Trigger(t, semi) end end
	if tr.Kind == "bass" then
		fire(self.cfg.Semitones(ch))
	elseif tr.Kind == "roll" then
		local n = tonumber(ch) or 1
		for k = 0, n - 1 do
			local d = (delay or 0) + k * stepLen / n
			if d > 0 then task.delay(d, function() self:Trigger(t) end) else self:Trigger(t) end
		end
	else
		fire(nil)
	end
	return true
end

local function fireStep(self, stepIdx, getPattern, getSwing, interval, onStep)
	self.step = stepIdx
	local cfg = self.cfg
	local n = cfg.Steps
	local p = getPattern()
	local swing = getSwing and getSwing() or 0
	local delay = (stepIdx % 2 == 0) and (interval * 0.5 * swing / 100) or 0
	local hitTracks = {}
	for t = 1, #cfg.Tracks do
		local i = (t - 1) * n + stepIdx
		local ch = p:sub(i, i)
		if ch ~= "" and ch ~= "0" then
			self:PlayCell(t, ch, interval, delay)
			hitTracks[cfg.Tracks[t].Name] = true -- keyed by name: survives BindableEvent copying
		end
	end
	-- keys lane: a note starts where its letter sits and lasts through its ties
	if cfg.Keys and cfg.Length and #p >= cfg.Length then
		for v = 1, cfg.Keys.Voices do
			local i = cfg.KeyIdx(v, stepIdx)
			local ch = p:sub(i, i)
			if ch ~= "0" and ch ~= "-" then
				local len = 1
				while stepIdx + len <= n and p:sub(cfg.KeyIdx(v, stepIdx + len), cfg.KeyIdx(v, stepIdx + len)) == "-" do len += 1 end
				self:PlayNote(cfg.Semitones(ch), len, interval, delay, cfg.Accent and cfg.Accent(ch))
				hitTracks.Keys = true
			end
		end
	end
	if onStep then onStep(stepIdx, self.hits, hitTracks) end
end

-- sync = nil for local preview, or {clock = fn, startAt = number, maxSteps = number?, onDone = fn?}
function E:Start(getPattern, getBPM, onStep, sync, getSwing)
	if self.playing then return end
	self.playing = true
	self.step = 0
	local n = self.cfg.Steps
	if sync then
		local lastK = -1
		self.conn = RunService.Heartbeat:Connect(function()
			local now = sync.clock()
			if now < sync.startAt then return end
			local interval = 60 / getBPM() / 4
			local k = math.floor((now - sync.startAt) / interval)
			if sync.maxSteps and k >= sync.maxSteps then
				self:Stop()
				if sync.onDone then sync.onDone() end
				return
			end
			if k > lastK then
				lastK = k
				fireStep(self, k % n + 1, getPattern, getSwing, interval, onStep)
			end
		end)
	else
		local nextT = os.clock()
		self.conn = RunService.Heartbeat:Connect(function()
			local now = os.clock()
			if now < nextT then return end
			local interval = 60 / getBPM() / 4
			if now - nextT > interval then nextT = now end -- fell behind: drop late steps
			nextT += interval
			fireStep(self, self.step % n + 1, getPattern, getSwing, interval, onStep)
		end)
	end
end

function E:Stop()
	self.playing = false
	if self.conn then self.conn:Disconnect(); self.conn = nil end
	self.step = 0
end

return E
