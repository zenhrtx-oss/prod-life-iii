-- OK Studio system: DAW (OK Beat Maker, beat format v3: drums + the keys lane).
-- The studio PC seats the player in the producer chair and opens the beat maker; saves are validated here
-- (per-track alphabets, level unlocks, 3 slots). ON MONITORS queues the beat on the studio speakers for everyone
-- through ctx.Monitors (Services/MonitorService: one beat airs at a time, the rest wait in line). The studio PC and
-- the studio laptops (Systems/Stations) all open the same beat maker through M.OpenFor.
-- A save answers persistent (the server has a store) and saving (DataService.Saving: this profile is written; false
-- once its load failed, the lock was lost or a newer build wrote it, launch audit A7), so the client never says "Saved"
-- for a session that can't save. A send to the monitors from a producer already on air or in line is "inline", one
-- inside Cfg.BroadcastCooldown of their last send that went in is "cooldown", and so is one inside
-- Cfg.FlipCheckCooldown of their last send that reached the flip check, which diffs the beat against every recent
-- airing: all three come before it, so it runs at most once a FlipCheckCooldown per producer (launch audit A5/A12).
-- Your rooms (the Your Rooms plan, Task 6): M.StationOf(player) -> inst?, room? is the beat-making spot the player is at,
-- the hub's for anyone and a room's laptop for its owner only (the room Model's OwnerId, InteractionService.MayUse's rule);
-- AtStation (deliveries in Contracts, ON MONITORS here) is StationOf ~= nil. The OpenDAW payload's `room` is the laptop's
-- room kind (RoomKind: "bedroom", "home", "real"), nil in the hub.
-- Task 7: ON MONITORS at your own room's laptop (StationOf's room) plays the beat on that room's speakers instead
-- (Systems/Rooms.PlayLocal: no queue, no NowPlaying, so no FIRE): checked after the beat (kit, voice, pattern, empty) and
-- before the cypher reservation, so a cypher in the hub never blocks your speakers, and it stamps neither the send nor
-- the flip-check cooldown. Its answers carry room = true, and DAW_Broadcast fires no BroadcastTried for them (that
-- feeds Funnel step 6, an airing). DAW_Stop also ends your room play (Rooms.StopLocal). M._Broadcast and M._Stop are
-- the two remotes' own handlers, for the Studio rooms hook's Play and Stop.
local RS, Players = game:GetService("ReplicatedStorage"), game:GetService("Players")
local Cfg = require(RS.OK.Modules.DAWConfig)
local Check = require(RS.OK.Modules.BriefCheck)
local RoomScope = require(RS.OK.Modules.RoomScope)
local M = { Enabled = true, Version = 4 }
local savedEv, triedEv, openedEv = Instance.new("BindableEvent"), Instance.new("BindableEvent"), Instance.new("BindableEvent")
M.Opened = openedEv.Event         -- (player, inst) the beat maker opened at the PC or a laptop
M.Saved = savedEv.Event           -- (player, slot)
M.BroadcastTried = triedEv.Event  -- (player, ok, reason)
function M._SetConfigForTest(cfg, check) Cfg = cfg; if check then Check = check end end -- edit-mode tests: the require cache can hold older modules
local lastSave = {}
local lastSend = {} -- [player] = os.clock() of their last send that went on the monitors or into the line
local lastFlipCheck = {} -- [player] = os.clock() of their last send that reached the flip check
function M._ClearFlipCheck(player) lastFlipCheck[player] = nil; return true end -- Studio tests (the monitor hook): no wait for the next check

local ALPHABET = { hit = "^[01]+$", roll = "^[0-3]+$", bass = "^[0a-y]+$" }

-- returns pattern, bpm, swing  or  nil, reason
-- unlocked (optional) enforces the unlocks (808 notes, hat rolls, swing): a function(feature) -> bool (gear, live),
-- or a level number (legacy: DAWConfig.Unlocks thresholds, kept for old tests)
function M.Validate(pattern, bpm, swing, unlocked)
	local level = nil
	if type(unlocked) == "number" then level = unlocked; unlocked = function(f) return level >= (Cfg.Unlocks[f] or 1) end end
	pattern = Cfg.Upgrade(pattern)
	if type(pattern) ~= "string" or #pattern ~= (Cfg.Length or #Cfg.Tracks * Cfg.Steps) then return nil, "invalid" end
	if type(bpm) ~= "number" or bpm ~= bpm or bpm == math.huge or bpm == -math.huge then return nil, "invalid" end
	if swing == nil then swing = 0 end
	if type(swing) ~= "number" or swing ~= swing or swing < 0 or swing > Cfg.Swing.Max then return nil, "invalid" end
	local n = Cfg.Steps
	for t, tr in ipairs(Cfg.Tracks) do
		local seg = pattern:sub((t - 1) * n + 1, t * n)
		if not seg:match(ALPHABET[tr.Kind] or "^[01]+$") then return nil, "invalid" end
		if unlocked then
			if tr.Kind == "bass" and seg:find("[^0]") and not unlocked("Bass") then return nil, "locked" end
			if tr.Kind == "roll" and seg:find("[23]") and not unlocked("Rolls") then return nil, "locked" end
		end
	end
	if Cfg.KeysValid and not Cfg.KeysValid(Cfg.KeysSeg(pattern)) then return nil, "invalid" end
	swing = math.floor(swing + 0.5)
	if unlocked and swing > 0 and not unlocked("Swing") then return nil, "locked" end
	return pattern, math.clamp(math.floor(bpm + 0.5), Cfg.BPM.Min, Cfg.BPM.Max), swing
end

function M.CellsDiffer(a, b)
	if type(a) ~= "string" then return #b end
	return Check.Diff(a, b) -- a slot saved in an older format still compares cell for cell
end

-- prof.daw (v2) = { v = 2, slots = { s1 = {pattern, bpm, swing}, s2 = ..., s3 = ... }, active = 1, saves = n }
-- Slot keys are strings: a sparse numeric table ({[2] = ...}) changes key type across remotes and DataStore JSON.
function M.SlotKey(n) return "s" .. tostring(n) end
function M.GetSlot(daw, n)
	if type(daw) ~= "table" or type(daw.slots) ~= "table" then return nil end
	return daw.slots[M.SlotKey(n)] or daw.slots[n] or daw.slots[tostring(n)]
end
function M.Migrate(daw)
	if type(daw) ~= "table" then return { v = 2, slots = {}, active = 1, saves = 0 } end
	if daw.v == 2 then return daw end
	local out = { v = 2, slots = {}, active = 1, saves = tonumber(daw.saves) or 0 }
	if type(daw.pattern) == "string" then
		out.slots[M.SlotKey(1)] = { pattern = Cfg.Upgrade(daw.pattern), bpm = tonumber(daw.bpm) or Cfg.BPM.Default, swing = 0 }
	end
	return out
end

local function studio() return workspace:FindFirstChild("OKStudio") end

-- the monitors are controlled from a beat-making spot: seated in the producer chair, near the studio PC, or near a
-- studio laptop (OK_Interactable parts with Kind = "Station"). A laptop inside a room (RoomScope.RoomOf) counts only for
-- the player in its room Model's OwnerId; a room with none counts for nobody. Returns the spot (the chair, the PC's
-- screen or the laptop) and the room Model it is in (nil in the hub), or nil when the player is at none.
local CS = game:GetService("CollectionService")
function M.StationOf(player)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not (hum and root) then return nil end
	local reach = Cfg.CloseDistance + 4
	local s = studio(); local cr = s and s:FindFirstChild("ControlRoom")
	if cr then
		local chair, screen = cr:FindFirstChild("Chair_Seat"), cr:FindFirstChild("Screen_Main")
		if chair and chair.Occupant == hum then return chair, nil end
		if screen and (root.Position - screen.Position).Magnitude <= reach then return screen, nil end
	end
	for _, inst in ipairs(CS:GetTagged("OK_Interactable")) do
		if inst:GetAttribute("Kind") == "Station" and inst:IsA("BasePart") and inst:IsDescendantOf(workspace)
			and (root.Position - inst.Position).Magnitude <= reach then
			local room = RoomScope.RoomOf(inst)
			if room == nil then return inst, nil end
			local owner = room:GetAttribute("OwnerId")
			if owner ~= nil and owner == player.UserId then return inst, room end
		end
	end
	return nil
end
function M.AtStation(player) return M.StationOf(player) ~= nil end

local ctxRef
-- has the player unlocked a beat-maker feature ("Bass", "Rolls", "Swing")? Owning the gear for it (Systems/Gear).
function M.Unlocked(player, feature)
	return require(RS.OK.Systems.Gear).Has(player, feature)
end
function M.UnlockFn(player) return function(f) return M.Unlocked(player, f) end end
-- opens the beat maker for a player at a spot; seat = the producer chair to sit in (studio PC only)
-- a kit id the player may use: "studio" always, others only with their gear; returns the id or nil
function M.KitFor(player, kit)
	if kit == nil or kit == "studio" then return "studio" end
	if type(kit) ~= "string" then return nil end
	local k = Cfg.KitById and Cfg.KitById(kit)
	if not (k and k.gear) then return nil end
	return require(RS.OK.Systems.Gear).Owns(player, k.gear) and kit or nil
end

-- a keys voice the player may use: the first voice always, others only with their gear; returns the id or nil
function M.VoiceFor(player, voice)
	local def = Cfg.Voices and Cfg.Voices[1]
	if not def then return nil end
	if voice == nil or voice == def.id then return def.id end
	if type(voice) ~= "string" then return nil end
	local v = Cfg.VoiceById(voice)
	if not v then return nil end
	if not v.gear then return voice end
	return require(RS.OK.Systems.Gear).Owns(player, v.gear) and voice or nil
end
-- what a hit is for saves and the empty check: drum hits and notes, never ties
local function hits(p) return Cfg.Hits and Cfg.Hits(p) or select(2, p:gsub("[^0]", "")) end

function M.OpenFor(player, inst, seat)
	local ctx = ctxRef
	local prof = ctx.Data.GetProfile(player)
	prof.daw = M.Migrate(prof.daw)
	local seated = false
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if seat and hum and hum.Health > 0 then
		-- seated only when the chair really took you: a standing humanoid sits on the same frame, but one already sitting
		-- on the floor (a loss reaction's seatless Sit) stays put, and then the beat maker opens as a laptop's
		if seat.Occupant == hum then seated = true
		elseif seat.Occupant == nil then seat:Sit(hum); seated = seat.Occupant == hum end
	end
	local room = RoomScope.RoomOf(inst)
	local kind = room and room:GetAttribute("RoomKind") -- the room's kind; its OK_Room is the asset's own ("bedroom_starter")
	RS.OK.Remotes.InteractionEvent:FireClient(player, "OpenDAW", { source = inst:GetFullName(), daw = prof.daw, seated = seated,
		persistent = ctx.Data.Persistent == true, level = prof.level, station = inst:GetAttribute("StationName") or "STUDIO PC",
		room = type(kind) == "string" and kind or nil })
	openedEv:Fire(player, inst)
end

function M.Init(ctx)
	ctxRef = ctx
	local Remotes = RS.OK.Remotes
	assert(ctx.Monitors, "DAW needs ctx.Monitors (Services/MonitorService)")

	Remotes.DAW_Save.OnServerInvoke = function(player, pattern, bpm, swing, slot, kit, voice)
		local kitId = M.KitFor(player, kit)
		if not kitId then return { ok = false, reason = "locked" } end
		local voiceId = M.VoiceFor(player, voice)
		if not voiceId then return { ok = false, reason = "locked" } end
		local p, b, sw = M.Validate(pattern, bpm, swing, M.UnlockFn(player))
		if not p then return { ok = false, reason = b } end
		if hits(p) == 0 then return { ok = false, reason = "empty" } end
		if slot == nil then slot = 1 end
		if type(slot) ~= "number" or slot ~= math.floor(slot) or slot < 1 or slot > Cfg.Slots then return { ok = false, reason = "invalid" } end
		local now = os.clock()
		if lastSave[player] and now - lastSave[player] < Cfg.SaveCooldown then return { ok = false, reason = "cooldown" } end
		lastSave[player] = now
		local prof = ctx.Data.GetProfile(player)
		prof.daw = M.Migrate(prof.daw)
		local prevSlot = M.GetSlot(prof.daw, slot)
		local prev = prevSlot and prevSlot.pattern
		prof.daw.slots[slot] = nil; prof.daw.slots[tostring(slot)] = nil
		prof.daw.slots[M.SlotKey(slot)] = { pattern = p, bpm = b, swing = sw, kit = kitId ~= "studio" and kitId or nil,
			voice = voiceId ~= Cfg.Voices[1].id and voiceId or nil }
		prof.daw.active = slot
		prof.daw.saves = (prof.daw.saves or 0) + 1
		if ctx.Data.MarkDirty then ctx.Data.MarkDirty(player) end
		-- XP only for a real new beat: 4+ hits, 4+ cells different from this slot's last save, not already paid today
		local nHits = hits(p)
		local changed = M.CellsDiffer(prev, p)
		local log = prof.xpLog or {}
		local today = os.date("!%Y%m%d")
		if log.paidDay ~= today then log.paidDay = today; log.paid = {} end
		log.paid = log.paid or {}
		local xp = 0
		if nHits >= 4 and changed >= 4 and not log.paid[p] then
			xp = ctx.Data.AddXP(player, Cfg.XPPerSave, "BeatSave")
			if type(xp) ~= "number" then xp = 0 end
			if xp > 0 then log.paid[p] = true; prof.xpLog = log end
		end
		print(string.format("[OK] %s saved slot %d (%d BPM, swing %d, save #%d, +%d XP)", player.Name, slot, b, sw, prof.daw.saves, xp))
		pcall(function() require(RS.OK.Systems.Life).Event(player, "beat") end) -- logs the first beat only
		savedEv:Fire(player, slot)
		return { ok = true, xp = xp, persistent = ctx.Data.Persistent == true, saving = ctx.Data.Saving(prof), profile = ctx.Data.ClientProfile(prof) }
	end

	-- ON MONITORS: queue the beat; ok = on air now (position 0) or in line (position n, wait in s)
	local function tryBroadcast(player, pattern, bpm, swing, flipToken, kit, voice)
		local kitId = M.KitFor(player, kit)
		if not kitId then return { ok = false, reason = "locked" } end
		local voiceId = M.VoiceFor(player, voice)
		if not voiceId then return { ok = false, reason = "locked" } end
		local p, b, sw = M.Validate(pattern, bpm, swing, M.UnlockFn(player))
		if not p then return { ok = false, reason = b } end
		if hits(p) == 0 then return { ok = false, reason = "empty" } end
		local spot, room = M.StationOf(player)
		if not spot then return { ok = false, reason = "away" } end
		-- your own room's laptop: that room's speakers, never the monitors' line (Task 7)
		if room then return require(RS.OK.Systems.Rooms).PlayLocal(player, p, b, sw, kitId, voiceId, room) end
		if ctx.Monitors.reserved then return { ok = false, reason = "cypher" } end -- a cypher round holds the monitors
		if flipToken ~= nil and type(flipToken) ~= "number" then return { ok = false, reason = "invalid" } end
		local inline = ctx.Monitors:InLine(player.UserId) -- on air or in line already: your place, no flip check
		if inline then return inline end
		if lastSend[player] and os.clock() - lastSend[player] < Cfg.BroadcastCooldown then return { ok = false, reason = "cooldown" } end
		local now = os.clock() -- a send let past here is stamped, whatever the flip check answers: one check a FlipCheckCooldown
		if lastFlipCheck[player] and now - lastFlipCheck[player] < Cfg.FlipCheckCooldown then return { ok = false, reason = "cooldown" } end
		lastFlipCheck[player] = now
		local Flips = require(RS.OK.Systems.Flips)
		local flipOf, why, changed = Flips.Judge(ctx.Monitors:History(), player.UserId, p, flipToken, M.UnlockFn(player))
		if why then return { ok = false, reason = why, changed = changed } end
		local r = ctx.Monitors:Enqueue(player, p, b, sw, flipOf and { uid = flipOf.uid, name = flipOf.name } or nil, kitId, voiceId)
		if r.ok then lastSend[player] = os.clock() end
		if r.ok and flipOf then
			r.flipOf = flipOf.name
			flipOf.creditedBy = flipOf.creditedBy or {} -- flipOf is the live history entry of that airing
			if not flipOf.creditedBy[player.UserId] then
				flipOf.creditedBy[player.UserId] = true
				Flips.Credit(flipOf.uid, player.DisplayName)
				pcall(function() require(RS.OK.Systems.Funnel).Event(player, "Flip", 1) end)
			end
		end
		if r.ok then print(string.format("[OK] %s queued a beat on the monitors (%d BPM, place %d)", player.Name, b, r.position)) end
		return r
	end
	-- DAW_Broadcast's handler: a room play (res.room) isn't an airing, so it fires no BroadcastTried (Funnel step 6, the
	-- tour's monitors step: Rooms.Played finishes that one)
	local function broadcast(player, pattern, bpm, swing, flipToken, kit, voice)
		local res = tryBroadcast(player, pattern, bpm, swing, flipToken, kit, voice)
		if not res.room then triedEv:Fire(player, res.ok == true, res.reason) end
		return res
	end
	Remotes.DAW_Broadcast.OnServerInvoke = broadcast

	-- DAW_Stop's handler: your beat off the monitors (or out of their line), and your room play ended
	local function stop(player)
		ctx.Monitors:Cancel(player.UserId)
		local ok, err = pcall(function() require(RS.OK.Systems.Rooms).StopLocal(player) end)
		if not ok then warn("[OK][ERR] room stop: " .. tostring(err)) end
	end
	Remotes.DAW_Stop.OnServerEvent:Connect(stop)
	M._Broadcast, M._Stop = broadcast, stop -- the Studio rooms hook's Play and Stop (the remotes' own path)

	ctx.Interaction.Register("Computer", function(player, inst)
		local s = studio()
		M.OpenFor(player, inst, s and s.ControlRoom:FindFirstChild("Chair_Seat"))
	end)

	Players.PlayerRemoving:Connect(function(p) lastSave[p] = nil; lastSend[p] = nil; lastFlipCheck[p] = nil end)
end

return M
