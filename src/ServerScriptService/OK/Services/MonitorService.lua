-- OK Studio MonitorService: the studio monitors' play queue ("Room for three").
-- One beat airs at a time through ReplicatedStorage.OK.NowPlaying, whose attributes every client's room listener reads
-- (Active, Token, Beat, BPM, Swing, OwnerId, OwnerName, StartAt, Loops, EndsAt, Kit, Voice) plus UpNext / QueueCount for screens.
-- Up to Config.Monitors.QueueSize producers hold a place (the beat on air counts), one place each. An airing is whole
-- bars lasting MinSeconds..MaxSeconds (M.LoopsFor), with GapSeconds of silence between airings.
-- Owners are Players, or plain tables { UserId, DisplayName } in Studio tests. Config.Monitors.Enabled = false turns
-- the monitors off. Instances (M.new) take an injectable clock and scheduler so the queue is unit-testable.
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.OK.Config)
local DAWCfg = require(RS.OK.Modules.DAWConfig)

local M = {}
local Monitor = {}
Monitor.__index = Monitor

local function mcfg(o) return o.mcfg or Config.Monitors or {} end

-- whole bars (Steps sixteenths) closest to TargetSeconds, kept inside MinSeconds..MaxSeconds
function M.LoopsFor(bpm, steps, mc)
	mc = mc or Config.Monitors or {}
	steps = steps or DAWCfg.Steps
	local bar = steps * 60 / bpm / 4
	local lo = math.max(1, math.ceil((mc.MinSeconds or 12) / bar - 1e-9))
	local hi = math.max(lo, math.floor((mc.MaxSeconds or 20) / bar + 1e-9))
	local loops = math.clamp(math.floor((mc.TargetSeconds or 16) / bar + 0.5), lo, hi)
	return loops, loops * bar
end

function M.new(o)
	local self = setmetatable({}, Monitor)
	self.o = o
	self.np = o.np
	self.now = o.now or function() return workspace:GetServerTimeNow() end
	self.delay = o.delay or function(s, fn) task.delay(s, fn) end
	self.onChange = o.onChange -- function(state) for screens
	self.queue = {}             -- waiting entries, in order
	self.history = {}           -- recent airings { token, uid, name, pattern } (newest last) for flips and copy checks
	self.current = nil          -- entry on air (or in its lead-in)
	self.token = 0
	self.idleUntil = 0          -- end of the silence after the last airing
	local ev = Instance.new("BindableEvent"); self._aired = ev; self.Aired = ev.Event       -- (entry)
	local ev2 = Instance.new("BindableEvent"); self._ended = ev2; self.Ended = ev2.Event    -- (entry, stopped)
	self.np:SetAttribute("Active", false)
	self.np:SetAttribute("UpNext", "")
	self.np:SetAttribute("QueueIds", "")
	self.np:SetAttribute("QueueCount", 0)
	return self
end

function Monitor:_find(uid)
	if self.current and self.current.uid == uid then return 0 end
	for i, e in ipairs(self.queue) do if e.uid == uid then return i end end
	return nil
end

function Monitor:State()
	local names = {}
	for _, e in ipairs(self.queue) do table.insert(names, e.name) end
	return { current = self.current, queue = self.queue, upNext = names, count = #self.queue + (self.current and 1 or 0) }
end

function Monitor:_publish()
	local st = self:State()
	local ids = {}
	for _, e in ipairs(self.queue) do table.insert(ids, tostring(e.uid)) end
	self.np:SetAttribute("QueueIds", table.concat(ids, ","))
	self.np:SetAttribute("UpNext", table.concat(st.upNext, " · "))
	self.np:SetAttribute("QueueCount", st.count)
	if self.onChange then self.onChange(st) end
end

-- seconds until the entry at queue index i starts (estimate)
function Monitor:_waitFor(i)
	local now = self.now()
	local t = 0
	if self.current then t = math.max(0, (self.current.endsAt or now) - now) + (mcfg(self.o).GapSeconds or 3)
	else t = math.max(0, self.idleUntil - now) end
	for k = 1, i - 1 do t += self.queue[k].dur + (mcfg(self.o).GapSeconds or 3) end
	return math.ceil(t)
end

function Monitor:_start(entry)
	local mc = mcfg(self.o)
	self.token += 1
	local my = self.token
	local startAt = self.now() + (mc.LeadSeconds or 0.5)
	entry.startAt = startAt; entry.endsAt = startAt + entry.dur; entry.token = my
	self.current = entry
	local np = self.np
	np:SetAttribute("Beat", entry.pattern); np:SetAttribute("BPM", entry.bpm); np:SetAttribute("Swing", entry.swing)
	np:SetAttribute("OwnerId", entry.uid); np:SetAttribute("OwnerName", entry.name)
	np:SetAttribute("NeonColor", entry.neon) -- the producer's on-air neon gear (nil = white flash)
	np:SetAttribute("StartAt", startAt); np:SetAttribute("Loops", entry.loops); np:SetAttribute("EndsAt", entry.endsAt)
	np:SetAttribute("Fires", 0)
	np:SetAttribute("FlipOf", entry.flipOf and entry.flipOf.name or nil)
	np:SetAttribute("Kit", entry.kit or "studio")
	np:SetAttribute("Voice", entry.voice or (DAWCfg.Voices and DAWCfg.Voices[1].id) or "")
	np:SetAttribute("System", entry.system == true) -- a cypher entry (anonymous): no FIRE, no SAMPLE IT
	-- history keeps the REAL producer (a cypher entry airs anonymously but is still its producer's own beat)
	table.insert(self.history, { token = my, uid = entry.realUid or entry.uid, name = entry.realName or entry.name, pattern = entry.pattern })
	while #self.history > 20 do table.remove(self.history, 1) end
	np:SetAttribute("Token", my); np:SetAttribute("Active", true)
	self:_publish()
	self._aired:Fire(entry)
	self.delay((mc.LeadSeconds or 0.5) + entry.dur + 0.1, function()
		if self.token == my and self.current == entry then self:_finish(false) end
	end)
end

function Monitor:_finish(stopped)
	local entry = self.current
	if not entry then return end
	self.current = nil
	self.token += 1
	self.np:SetAttribute("Active", false)
	local gap = mcfg(self.o).GapSeconds or 3
	self.idleUntil = self.now() + gap
	self:_publish()
	self._ended:Fire(entry, stopped)
	local my = self.token
	self.delay(gap, function() if self.token == my and not self.current then self:_next() end end)
end

function Monitor:_next()
	if self.current or #self.queue == 0 then return end
	if self.now() < self.idleUntil - 1e-6 then
		local my = self.token
		self.delay(self.idleUntil - self.now(), function() if self.token == my then self:_next() end end)
		return
	end
	local entry = table.remove(self.queue, 1)
	self:_start(entry)
end

-- the "inline" refusal for an owner already on air (position 0) or in line (position n, wait in s), else nil. Enqueue
-- answers with it, and Systems/DAW asks first, before its flip check walks the history (launch audit A12)
function Monitor:InLine(uid)
	local at = self:_find(uid)
	if not at then return nil end
	return { ok = false, reason = "inline", position = at, wait = at > 0 and self:_waitFor(at) or 0 }
end

-- returns { ok = true, position = 0 (on air) / n (place in line), wait = seconds }  or  { ok = false, reason }
-- reasons: "off", "inline" (already on air or in line; position given), "full"
function Monitor:History() return self.history end
-- every beat the monitors know about: recent airings, the one on air and the ones waiting (real producers, not ENTRY ids)
function Monitor:KnownBeats()
	local out = {}
	for _, h in ipairs(self.history) do table.insert(out, { uid = h.uid, pattern = h.pattern }) end
	for _, e in ipairs(self.queue) do table.insert(out, { uid = e.realUid or e.uid, pattern = e.pattern }) end
	if self.current then table.insert(out, { uid = self.current.realUid or self.current.uid, pattern = self.current.pattern }) end
	return out
end

-- a cypher round owns the monitors: players' sends are refused (reason "cypher") until it ends
function Monitor:SetReserved(on) self.reserved = on and true or nil; self.np:SetAttribute("Reserved", self.reserved or false) end

-- system entries (cypher): go to the FRONT of the line in the order given, past the size limit and the reservation
function Monitor:EnqueueSystem(owner, pattern, bpm, swing, kit, position, realUid, realName, voice)
	local loops, dur = M.LoopsFor(bpm, DAWCfg.Steps, mcfg(self.o))
	local entry = { uid = owner.UserId, name = owner.DisplayName or ("Entry " .. tostring(owner.UserId)), pattern = pattern, bpm = bpm,
		swing = swing or 0, loops = loops, dur = dur, kit = kit or "studio", voice = voice, system = true, realUid = realUid, realName = realName }
	table.insert(self.queue, math.clamp(position or 1, 1, #self.queue + 1), entry)
	if not self.current then self:_next() end
	self:_publish()
	return { ok = true }
end
function Monitor:Current() return self.current end

function Monitor:Enqueue(owner, pattern, bpm, swing, flipOf, kit, voice)
	local mc = mcfg(self.o)
	if mc.Enabled == false then return { ok = false, reason = "off" } end
	if self.reserved then return { ok = false, reason = "cypher" } end
	local uid = owner.UserId
	local inline = self:InLine(uid)
	if inline then return inline end
	if #self.queue + (self.current and 1 or 0) >= (mc.QueueSize or 4) then return { ok = false, reason = "full" } end
	local loops, dur = M.LoopsFor(bpm, DAWCfg.Steps, mc)
	local neon = typeof(owner) == "Instance" and owner:GetAttribute("NeonColor") or nil
	local entry = { uid = uid, neon = neon, name = owner.DisplayName or owner.Name or ("Player " .. tostring(uid)), pattern = pattern,
		bpm = bpm, swing = swing or 0, loops = loops, dur = dur, flipOf = flipOf, kit = kit or "studio", voice = voice }
	table.insert(self.queue, entry)
	local pos = #self.queue
	local wait = self:_waitFor(pos)
	if not self.current then self:_next() end
	local now = self:_find(uid)
	self:_publish()
	return { ok = true, position = now or pos, wait = (now == 0) and 0 or wait }
end

-- a FIRE for the beat on air (Systems/Reactions); the screens show the count
function Monitor:AddFire()
	if not self.current then return 0 end
	self.current.fires = (self.current.fires or 0) + 1
	self.np:SetAttribute("Fires", self.current.fires)
	self:_publish()
	return self.current.fires
end

-- removes the owner's beat from the line, or stops it if it is on air; returns "stopped", "removed" or nil
function Monitor:Cancel(uid)
	if self.current and self.current.uid == uid then self:_finish(true); return "stopped" end
	for i, e in ipairs(self.queue) do
		if e.uid == uid then table.remove(self.queue, i); self:_publish(); return "removed" end
	end
	return nil
end

-- the live service ------------------------------------------------------------------------
local function studio() return workspace:FindFirstChild("OKStudio") end
local function label(part, guiName)
	local g = part and part:FindFirstChild(guiName or "Text")
	return g and g:FindFirstChild("Label")
end
M.IDLE_SIDE = "MONITORS\n\nIDLE\n\nPLAY A BEAT\nON THE MONITORS"
-- side screen in the control room and the lounge TV (the TV's own text is kept and restored)
function M.SetScreens(text, tvText)
	local s = studio(); if not s then return end
	local l = label(s.ControlRoom:FindFirstChild("Screen_Side")); if l then l.Text = text end
	local tv = s.Lounge:FindFirstChild("TV_Screen")
	local tl = label(tv, "ScreenText")
	if tl then
		if tvText then
			if not tv:GetAttribute("SavedText") then tv:SetAttribute("SavedText", tl.Text) end
			tl.Text = tvText
		elseif tv:GetAttribute("SavedText") then
			tl.Text = tv:GetAttribute("SavedText"); tv:SetAttribute("SavedText", nil)
		end
	end
end
local function screenText(st)
	local up = (#st.upNext > 0) and ("\nUP NEXT: " .. table.concat(st.upNext, ", ")) or ""
	if st.current then
		local fire = (st.current.fires or 0) > 0 and string.format("  🔥 %d", st.current.fires) or ""
		local flip = st.current.flipOf and ("\nflip of " .. st.current.flipOf.name) or ""
		local now = string.format("NOW PLAYING\n\nprod. %s%s\n%d BPM%s", st.current.name, flip, st.current.bpm, fire)
		return now .. up, now .. up
	end
	if #st.upNext > 0 then return "MONITORS\n\nNEXT BEAT IN A MOMENT" .. up, nil end
	return M.IDLE_SIDE, nil
end

function M.Init(ctx)
	local svc = M.new({ np = RS.OK.NowPlaying, onChange = function(st) local a, b = screenText(st); M.SetScreens(a, b) end })
	M.Service = svc
	ctx.Monitors = svc
	M.SetScreens(M.IDLE_SIDE, nil)
	game:GetService("Players").PlayerRemoving:Connect(function(p) svc:Cancel(p.UserId) end)
	return svc
end

return M
