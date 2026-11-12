-- OK Studio system: your rooms (the Your Rooms plan, Task 2: plots, the shared building, the wake-up). Every player
-- gets a plot: a landing with a front door and a door per room, and their rooms north of it (the bedroom always; the
-- home and real studio once their career gates are owned: RoomRules.Owned on prof.career.gates). The hub stays the
-- public stage.
-- * Slots: a player claims the lowest free slot (RoomRules.Claim) at once on join, so two joins in the same tick get two
--   slots; a 13th player gets none, stays in the studio and is told "the building is full" (copy 1.18) once their
--   character is up. The plot is built (Modules/RoomBuild.Plot) once the profile is ready: unparented, then
--   InteractionService.Adopt, then parented once, straight into Workspace.OK_Plots (a Folder), so the room's Station is
--   hooked like any other. The bedroom is a clone of the template ServerStorage.<Config.Rooms.Template> (Init moves it
--   there from Workspace), or RoomBuild's stand-in when there is none; home and real are stand-ins until their imports.
-- * Leaving frees the slot: everyone standing in the plot (the owner too, when present, preflight F5) is moved to the
--   building's HallSpawn first, guests with the toast "{player} left the server" (copy 1.19), then the plot goes.
-- * The wake-up: your first character goes to your bedroom's Spawn; a respawn after a death inside your own plot does
--   the same. Under the test hold (Studio, ReplicatedStorage.OK has WalkInsPaused, true or false: WalkIns' held()) neither
--   moves anyone, so the existing suite keeps starting at the hub spawn; tests drive them through the hook. Without the
--   building (Workspace.OK_Rooms' Hall and RoomsDoor: the only way out of a plot) neither moves anyone either.
-- * Doors (untagged prompts, hooked here; each press is checked for reach, as InteractionService does): the corridor's
--   RoomsDoor -> the hall's HallSpawn; the hall's door k -> plot k's landing (RoomRules.CanEnter on the door mode:
--   Config.Rooms.DoorDefault until Task 14; the owner always enters; a refusal toasts copy 1.16 / 1.17); the landing's
--   RoomPrompt -> that room's Spawn; a room's ExitPrompt -> the landing outside its door; the landing's LeavePrompt -> the
--   hall in front of door k; the hall's HubDoor -> the corridor. Every move: RequestStreamAroundAsync(target, 10) in a
--   pcall, unseat (Sit false, the seat weld cut, 0.3 s), PivotTo(target + 3 up), checked once.
-- * The saved home (Task 3): prof.career.home = { v = 1, door, items = { [kind] = { entry } } } (schema stays v5; DataService
--   doesn't know it). Rooms is its one writer, through state(p): a missing or junk home is defaulted, the rest is repaired by
--   RoomRules.Repair against the kinds you own (Owned(prof.career.gates)) and what you have unlocked (gear through the Gear
--   system, firsts and the highest fame tier from prof.life), and written back (MarkDirty only when it changed), so what was
--   dropped doesn't come back on the next load. An entry in a room you don't own, or a locked one, stays in the save but
--   unbuilt (ruling R8): a read that comes up short never deletes a placed item. build(k) reads it on every (re)build.
--   Room ownership is prof.career.gates, never a second list. When the owner's CareerGates attribute changes, the owned set is
--   recomputed from the gates and the plot is rebuilt once if the set moved (a sponsor toggle moves the attribute, not the
--   rooms). A Career Reset replaces prof.career (home included): state() defaults it again on its next read, and the hook's
--   Reset does it at once.
-- * Presence: every 1 s (and after every move) the player attributes InPlot (the slot whose plot you stand in, else 0)
--   and PlotSlot (your own, else 0). Rooms carry OwnerId, OwnerName, RoomKind and Plot (RoomBuild.Plot sets them).
-- * The hall's plates and door prompts follow the slots: "STUDIO 07" (copy 1.8) when free; "{player}\nSTUDIO 07 · {MODE}"
--   (1.9) and "Enter" / "{player}'s door" (1.10, 1.11) when owned. "Go to your room" / "Your door" (1.12, 1.13) are per
--   viewer: a client line, not built yet.
-- * API: PlotOf(p), Owner(k), BoxesFor(p) (your rooms' world boxes, RoomRules.Box, each with .kind), PlaceOf(p) ("hub",
--   { slot, kind } with kind a room kind or "landing", or nil), Anchor(p, kind, name) -> CFrame?, Station(p, kind?) ->
--   BasePart?, the event Rebuilt (player, k).
-- * Studio-only hook ServerScriptService.OK._StudioRoomsHook (Studio and running): hook:Invoke(cmd, userId, a, b). Plot,
--   Reset (the home back to its defaults, claim if needed and rebuild), WakeUp, Enter(slot, asFriend), Exit(kind), GoIn(kind), Leave, HubDoor, RoomsDoor
--   (each the real handler of its prompt), Respawn (LoadCharacter, then the respawn rule past the hold), Release, Claim
--   (nil when no slot is free; the full toast is the wake-up's), Fill(n) / Unfill (stand-in plots for fake owners), Anchor(kind, name),
--   InPlot, PlaceOf, Home (a copy of the saved home, repaired), SetHome(home) (a copy, through Repair, saved; returns what it
--   kept; no rebuild), Guest(slot) (a stand-in Model in that plot, moved like a guest on Release), Station(kind?),
--   RunStation(kind?) (InteractionService._RunHandler("Station") on it: { acted, toast }), Sent (the toasts sent this
--   player since the last read), OnOpen(cmd, a) (the next time this player's beat maker opens at a laptop in a plot,
--   run hook command cmd(a) 2 s later: a client test's server-side move; disarmed after 30 s). Task 6: MayUse(inst)
--   (InteractionService.MayUse(player, inst): ok, ownerName?), StationOf (DAW.StationOf: { inst, room }), Run(kind, inst)
--   (InteractionService._RunHandler(kind) on inst: { acted, toast }; the RackSpot's GearRack, say).
-- * Each room's laptop and its RackSpot (RoomBuild.RackSpot, Task 6) are tagged and are their owner's only
--   (InteractionService's owner rule reads the room Model's OwnerId).
-- * Your room's speakers (Task 7). The tier is RoomRules.SpeakerTier over the Config.Rooms.Speakers gear you own (read
--   through the Gear system; a failed read counts as not owned): 1 = the laptop's own speakers, 2 = spk_monitors, 3 =
--   spk_studio. At tier 2 and 3 every room of your plot holds a pair of RoomItems.Speakers models, RoomSpeaker_L and
--   RoomSpeaker_R, on its Desk_Speaker_L / _R anchors: built with the plot, and refitted when your Gear attribute
--   changes (a pair already at your tier stays; only models Rooms made, RoomItem = "speaker", are replaced).
--   PlayLocal(p, pattern, bpm, swing, kit, voice, room?) is ON SPEAKERS at your own room's laptop (Systems/DAW's room
--   branch; pattern, bpm, swing, kit and voice already checked there): it writes ReplicatedStorage.OK.RoomPlaying.Plot_<k>
--   (Beat, BPM, Swing, Kit, Voice, OwnerId, OwnerName, Room = the room's kind, Tier, StartAt = server time +
--   Config.Monitors.LeadSeconds, Loops and EndsAt from MonitorService.LoopsFor, then Token = its last + 1, then Active),
--   replacing any play under way, and ends itself at EndsAt (only the play with that Token). No queue, no NowPlaying, no
--   FIRE, no BroadcastTried: it isn't an airing. One play a Config.Rooms.PlayCooldown per player ("cooldown"); no slot or
--   plot is "away", no RoomPlaying folder "off"; every answer carries room = true. It fires Played (player, tier, kind),
--   which finishes the tour's "monitors" step (Systems/Tour). StopLocal(p) ends your plot's play (DAW_Stop runs it); a
--   released slot's play ends with its plot. StarterPlayerScripts/OK/RoomClient plays it for everyone in the plot.
--   Hook (Studio): Play(pattern, bpm) and Stop run DAW_Broadcast's and DAW_Stop's own handlers for the player (DAW._Broadcast,
--   DAW._Stop: the remote's path, the room branch included); Counts ({ played, tried, rebuilt }: Played, DAW.BroadcastTried
--   and Rebuilt fires for the player since the last read); SpeakerTier; Fire(token) (Systems/Reactions.Send for the player:
--   the live FIRE rule, which reads only NowPlaying).
-- * The career gates (Task 4): home_studio and real_studio (Config.Career.Gates, each with a `room` field) are bought in the
--   Career tab through Career.Unlock, whose publish moves CareerGates: the listener above rebuilds your plot once with the
--   new room. The landing needs nothing more: RoomBuild.Landing is built from the owned kinds, so a door you now own is a
--   working one (its RoomPrompt, its name sign and its Out marker) and the rest keep the locked sign; hookPlot hooks every
--   RoomPrompt the new plot has, so the swap is the rebuild's (one writer: this module's single CareerGates listener).
local RS, Players = game:GetService("ReplicatedStorage"), game:GetService("Players")
local RunService = game:GetService("RunService")
local Config = require(RS.OK.Config)
local Rules = require(RS.OK.Modules.RoomRules)
local Build = require(RS.OK.Modules.RoomBuild)
local WalkInRules = require(RS.OK.Modules.WalkInRules)
local LifeRules = require(RS.OK.Modules.LifeRules)
local Catalog = require(RS.OK.Data.RoomCatalog)
local Items = require(RS.OK.Modules.RoomItems)
local Copy = Build.Copy

local M = { Enabled = true, Version = 1 }
local rebuiltEv = Instance.new("BindableEvent")
M.Rebuilt = rebuiltEv.Event -- (player, k) after a player's plot is (re)built
local playedEv = Instance.new("BindableEvent")
M.Played = playedEv.Event -- (player, tier, kind) after a room play went on (Task 7)

local ctx
local Cfg = Config.Rooms
local slots = {}      -- [k] = the owner's user id (RoomRules.Claim's input)
local owners = {}     -- [k] = { id, name, player = Player? (nil for a fake owner), fake = bool }
local plots = {}      -- [k] = the plot Model in Workspace.OK_Plots
local kindsOf = {}    -- [k] = the kinds built in plot k, ladder order
local buildGen = {}   -- [k] = bumped by every build and release, so a slow build for a slot that moved on is dropped
local slotOf = {}     -- [player] = k
local woken = {}      -- [player] = true once the first character came
local respawnHome = {} -- [player] = was the player inside their own plot when their last character went
local busy = {}       -- [player] = a door move under way (a mashed prompt moves once)
local gateConns = {}  -- [player] = the connection on their CareerGates attribute
local gearConns = {}  -- [player] = the connection on their Gear attribute (their speakers follow it)
local lastPlay = {}   -- [player] = os.clock() of their last room play that went on (Config.Rooms.PlayCooldown)
local testGuests = {} -- [k] = { Model } (the hook's Guest)
local sent = {}       -- Studio: [userId] = { toast text }
local armed = {}      -- Studio: [player] = the hook's OnOpen entry
local counts = {}     -- Studio: [userId] = { played = n, tried = n } since the hook's last Counts
local template, plotsFolder, hall, roomsDoor
local dispatch -- the hook's command runner (OnOpen runs one later)

local function report(msg) warn("[OK][ERR] rooms: " .. tostring(msg)) end
-- the test hold, as Systems/WalkIns' held(): Studio only, so a stray attribute in a published place never holds anyone
local function held() return RunService:IsStudio() and RS.OK:GetAttribute("WalkInsPaused") ~= nil end

-- copy ---------------------------------------------------------------------------------------------------------------
-- a {player} in a toast: past 10 characters it is cut to 9 plus "…" (copy §1, tokens)
local function short(name)
	name = tostring(name or "")
	local n = utf8.len(name)
	if n == nil then return #name > 10 and (string.sub(name, 1, 9) .. "…") or name end
	if n <= 10 then return name end
	return string.sub(name, 1, utf8.offset(name, 10) - 1) .. "…"
end
local function fill(line, t)
	return (string.gsub(line, "{(%w+)}", function(key)
		local v = t[key]
		if v == nil then return nil end
		return tostring(v)
	end))
end
local function toast(p, text)
	if RunService:IsStudio() then
		local log = sent[p.UserId] or {}
		sent[p.UserId] = log
		table.insert(log, text)
	end
	local ok, err = pcall(function() RS.OK.Remotes.InteractionEvent:FireClient(p, "Toast", { text = text }) end)
	if not ok then report("toast: " .. tostring(err)) end
end

-- geometry -----------------------------------------------------------------------------------------------------------
local function origin(k) local x, y, z = Rules.PlotOrigin(k, Cfg); return Vector3.new(x, y, z) end
-- the claimed slot whose plot stands at pos (x and z only: plots are PlotSpacing apart, and a fall keeps its column)
local function plotAt(pos)
	for k in pairs(slots) do
		local o = origin(k)
		local dx, dz = pos.X - o.X, pos.Z - o.Z
		if dx >= -40 and dx <= Cfg.Landing.length + 40 and dz >= -80 and dz <= Cfg.Landing.width + 40 then return k end
	end
	return nil
end
local function rootOf(p) local c = p.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local homeOf = setmetatable({}, { __mode = "k" }) -- [character] = was it inside its player's own plot at its last read
-- the InPlot attribute, read now (no character: the last value stands)
local function presence(p)
	local c = p.Character
	local r = c and c:FindFirstChild("HumanoidRootPart")
	if not r then return p:GetAttribute("InPlot") or 0 end
	local v = plotAt(r.Position) or 0
	if p:GetAttribute("InPlot") ~= v then p:SetAttribute("InPlot", v) end
	homeOf[c] = slotOf[p] ~= nil and v == slotOf[p]
	return v
end
-- was `char` (default: p's current character) inside p's own plot? Read from its root while it has one, else from its
-- last presence read: CharacterRemoving's handler can run after the character is gone and p.Character is the new one
-- (deferred signals), so it must never read p.Character
local function homeNow(p, char)
	local k = slotOf[p]
	if not k then return false end
	local c = char or p.Character
	local r = c and c:FindFirstChild("HumanoidRootPart")
	if r then return plotAt(r.Position) == k end
	if c and homeOf[c] ~= nil then return homeOf[c] end
	return (p:GetAttribute("InPlot") or 0) == k
end

-- targets: CFrames on the floor (y = its top), facing the way you should face on arrival
local function onFloor(part)
	local pos = part.Position
	return CFrame.new(pos.X, pos.Y - part.Size.Y / 2, pos.Z) * part.CFrame.Rotation
end
local function markerCF(parent, name)
	local a = parent and parent:FindFirstChild(name)
	return (a and a:IsA("Attachment")) and a.WorldCFrame or nil
end
local function roomOf(k, kind) local plot = plots[k]; return plot and plot:FindFirstChild(Build.RoomName(kind)) or nil end
local function landingOf(k) local plot = plots[k]; return plot and plot:FindFirstChild("Landing") or nil end
local function roomSpawn(k, kind)
	local room = roomOf(k, kind or "bedroom")
	local s = room and Build.SpawnOf(room)
	return s and onFloor(s) or nil
end
local function landingInside(k) local l = landingOf(k); return l and markerCF(l:FindFirstChild("FrontDoor"), "Inside") end
local function landingOut(k, kind) local l = landingOf(k); return l and markerCF(l:FindFirstChild("Door_" .. tostring(kind)), "Out") end
local function hallDoor(k) return hall and hall:FindFirstChild(string.format("Door_%02d", k)) or nil end
local function hallFront(k) return markerCF(hallDoor(k), "Front") end
local function hallSpawn() local s = hall and hall:FindFirstChild("HallSpawn"); return s and onFloor(s) or nil end
local function corridor() return markerCF(roomsDoor, "Front") end

-- moves --------------------------------------------------------------------------------------------------------------
local function playDoor(part)
	local s = part and part:FindFirstChild("DoorSFX")
	if s and s:IsA("Sound") then s.TimePosition = 0; s:Play() end
end
-- stream the target in, unseat, move 3 up; checked once, since the client's own physics can win the first move: moved
-- again only when the root is still where it stood before (never when the player has gone somewhere else since)
local function teleport(p, target)
	local c = p.Character
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	if not (target and c and hum and hum.Health > 0 and c:FindFirstChild("HumanoidRootPart")) then return false end
	pcall(function() p:RequestStreamAroundAsync(target.Position, 10) end)
	if hum.Sit or hum.SeatPart then
		local seat = hum.SeatPart
		local weld = seat and seat:FindFirstChild("SeatWeld")
		hum.Sit = false
		if weld then weld:Destroy() end
		task.wait(0.3)
	end
	local r = c:FindFirstChild("HumanoidRootPart")
	if p.Character ~= c or not c.Parent or not r then return false end
	local from = r.Position
	local dest = target + Vector3.new(0, 3, 0)
	c:PivotTo(dest)
	task.wait(0.25)
	r = c:FindFirstChild("HumanoidRootPart")
	if r and p.Character == c and (r.Position - dest.Position).Magnitude > 8 and (r.Position - from).Magnitude < 8 then c:PivotTo(dest) end
	presence(p)
	return true
end
-- one move at a time per player
local function move(p, target, door)
	if not target or busy[p] then return false end
	busy[p] = true
	playDoor(door)
	local ok, res = pcall(teleport, p, target)
	busy[p] = nil
	if not ok then report("move: " .. tostring(res)); return false end
	return res
end

-- the handlers (each prompt's, and the hook's) ---------------------------------------------------------------------------
-- the hall's door k: onto plot k's landing, if the door lets you in
local function enterPlot(p, k, asFriend)
	k = tonumber(k)
	local o = k and owners[k]
	if not (o and plots[k]) then return false end
	local mode = Cfg.DoorDefault -- Task 14 reads the saved home.door (Task 3 keeps it) and cycles it; the default until then
	if not Rules.CanEnter(mode, o.id == p.UserId, asFriend == true) then
		toast(p, fill(mode == "locked" and Copy.Locked or Copy.FriendsOnly, { player = short(o.name) }))
		return false
	end
	return move(p, landingInside(k), hallDoor(k))
end
-- the landing's door for `kind`: into that room, at its Spawn
local function goRoom(p, k, kind)
	local door = landingOf(k) and landingOf(k):FindFirstChild("Door_" .. tostring(kind))
	return move(p, roomSpawn(k, kind), door)
end
-- a room's ExitPrompt: onto the landing outside that room's door
local function exitRoom(p, k, kind)
	local room = roomOf(k, kind)
	return move(p, landingOut(k, kind), room and Build.DoorOf(room))
end
-- the landing's LeavePrompt: into the hall, in front of door k
local function leavePlot(p, k)
	local l = landingOf(k)
	return move(p, hallFront(k), l and l:FindFirstChild("FrontDoor"))
end
-- the hall's HubDoor: back to the studio's corridor
local function toCorridor(p) return move(p, corridor(), hall and hall:FindFirstChild("HubDoor")) end
-- the corridor's RoomsDoor: into the hall
local function toHall(p) return move(p, hallSpawn(), roomsDoor) end

-- untagged prompts: a press from out of reach does nothing; a throw is reported, never a bare stack
local function near(p, part)
	local r = rootOf(p)
	return r ~= nil and part ~= nil and (r.Position - part.Position).Magnitude <= Config.Interaction.MaxDistance + 8
end
local function onPrompt(part, name, fn)
	local pp = part and part:FindFirstChild(name)
	if not (pp and pp:IsA("ProximityPrompt")) then return end
	pp.Triggered:Connect(function(p)
		if not near(p, part) then return end
		local ok, err = pcall(fn, p)
		if not ok then report(name .. ": " .. tostring(err)) end
	end)
end
local function hookPlot(plot, k)
	local landing = plot:FindFirstChild("Landing")
	if landing then
		onPrompt(landing:FindFirstChild("FrontDoor"), "LeavePrompt", function(p) leavePlot(p, k) end)
		for _, d in ipairs(landing:GetChildren()) do
			local kind = d:GetAttribute("RoomKind")
			if kind then onPrompt(d, "RoomPrompt", function(p) goRoom(p, k, kind) end) end
		end
	end
	for _, room in ipairs(plot:GetChildren()) do
		local kind = room:GetAttribute("RoomKind")
		if kind then onPrompt(Build.DoorOf(room), "ExitPrompt", function(p) exitRoom(p, k, kind) end) end
	end
end

-- the hall's plates ----------------------------------------------------------------------------------------------------
local function plate(k)
	local o = owners[k]
	local num = string.format("%02d", k)
	local pl = hall and hall:FindFirstChild("Plate_" .. num)
	local gui = pl and pl:FindFirstChild("Text")
	local label = gui and gui:FindFirstChild("Label")
	if label then
		label.Text = o and fill(Copy.PlateOwned, { player = o.name, slot = num, MODE = Copy.Modes[Cfg.DoorDefault] or "" })
			or fill(Copy.PlateEmpty, { slot = num })
	end
	local door = hallDoor(k)
	local pp = door and door:FindFirstChild("EnterPrompt")
	if pp then
		pp.Enabled = o ~= nil
		pp.ActionText = Copy.EnterAction
		pp.ObjectText = o and fill(Copy.EnterObject, { player = o.name }) or fill(Copy.PlateEmpty, { slot = num })
	end
	if door then door:SetAttribute("OwnerId", o and o.id or nil) end
end

-- the saved home (prof.career.home; Rooms is its one writer) -------------------------------------------------------------
local function defaultHome() return { v = 1, door = Cfg.DoorDefault, items = {} } end
local function deepCopy(v)
	if type(v) ~= "table" then return v end
	local out = {}
	for k, x in pairs(v) do out[k] = deepCopy(x) end
	return out
end
-- key for key, both ways
local function sameTree(a, b)
	if type(a) ~= type(b) then return false end
	if type(a) ~= "table" then return a == b end
	for k, v in pairs(a) do if not sameTree(v, b[k]) then return false end end
	for k in pairs(b) do if a[k] == nil then return false end end
	return true
end
local function sameList(a, b)
	if #a ~= #b then return false end
	for i, v in ipairs(a) do if b[i] ~= v then return false end end
	return true
end
-- the facts RoomRules.Unlocked reads. Gear goes through the Gear system (ctx.Gear, else the live module); a read that
-- fails (Gear not started yet on an early join) leaves it unowned, so its items stay unbuilt and are never deleted (R8).
-- Firsts and the highest fame tier come straight from prof.life (read only), the rooms from the kinds owned.
local function haveFor(p, prof, owned)
	local gear = {}
	local okGear, Gear = pcall(function() return (ctx and ctx.Gear) or require(RS.OK.Systems.Gear) end)
	if okGear and type(Gear) == "table" then
		for _, it in ipairs(Config.Gear or {}) do
			local okOwn, owns = pcall(Gear.Owns, p, it.id)
			if okOwn and owns == true then gear[it.id] = true end
		end
	end
	local life = type(prof.life) == "table" and prof.life or {}
	return { gear = gear, firsts = type(life.firsts) == "table" and life.firsts or {},
		tier = LifeRules.TierIndex(life.tier, Config.Life.Tiers), rooms = owned }
end
-- a profile whose career can hold a home: not a throwaway (a player who left, a load that failed), career a table
local function usable(prof) return type(prof) == "table" and not prof._detached and type(prof.career) == "table" end
-- `raw` (a saved home, or nil) repaired for p: home, dropped, unbuilt (RoomRules.Repair's) and the kinds owned
local function repairedFor(p, prof, raw)
	local owned = Rules.Owned(prof.career.gates, Cfg.Kinds)
	local unlocked = Rules.Unlocked(Catalog, haveFor(p, prof, owned), Config.Life.Tiers)
	local home, dropped, unbuilt = Rules.Repair(raw, owned, Cfg, Catalog, unlocked)
	return home, dropped, unbuilt, owned
end
-- p's saved home, defaulted and repaired, and written back when that changed it (the profile's own table stays when
-- nothing did, so a held reference stays good). Returns { home = the saved table, owned = the kinds owned in ladder order,
-- dropped, unbuilt = Repair's lists }. A throwaway profile gets the defaults and nothing is written. Yields while the
-- profile loads. Anything dropped is dropped quietly: nothing here is reported.
local function state(p)
	local prof = ctx.Data.GetProfile(p)
	if not usable(prof) then
		return { home = defaultHome(), owned = Rules.Owned(nil, Cfg.Kinds), dropped = {}, unbuilt = {} }
	end
	local career = prof.career
	local home, dropped, unbuilt, owned = repairedFor(p, prof, career.home)
	if sameTree(career.home, home) then
		home = career.home
	else
		career.home = home
		ctx.Data.MarkDirty(p)
	end
	return { home = home, owned = owned, dropped = dropped, unbuilt = unbuilt }
end
-- the hook's SetHome: `raw` through Repair, saved; returns a copy of what was kept (nil without a usable profile)
local function setHome(p, raw)
	local prof = ctx.Data.GetProfile(p)
	if not usable(prof) then return nil end
	local home = repairedFor(p, prof, raw)
	prof.career.home = home
	ctx.Data.MarkDirty(p)
	return deepCopy(home)
end
-- the hook's Reset: the home back to its defaults
local function resetHome(p)
	local prof = ctx.Data.GetProfile(p)
	if not usable(prof) then return false end
	prof.career.home = defaultHome()
	ctx.Data.MarkDirty(p)
	return true
end

-- your speakers (Task 7) -------------------------------------------------------------------------------------------------
-- the speaker tier p's gear gives: RoomRules.SpeakerTier over the Config.Rooms.Speakers gear they own, read through the
-- Gear system (ctx.Gear, else the live module). A read that fails counts as not owned: the tier only ever falls back to 1
local function speakerTier(p)
	local speakers = Cfg.Speakers or {}
	local owned = {}
	local okGear, Gear = pcall(function() return (ctx and ctx.Gear) or require(RS.OK.Systems.Gear) end)
	if p and okGear and type(Gear) == "table" then
		for _, s in ipairs(speakers) do
			if s.gear then
				local okOwn, owns = pcall(Gear.Owns, p, s.gear)
				if okOwn and owns == true then owned[s.gear] = true end
			end
		end
	end
	return Rules.SpeakerTier(owned, speakers)
end
-- a room's desk speakers at `tier`: a RoomItems.Speakers model RoomSpeaker_L / _R on each Desk_Speaker_L / _R anchor at
-- tier 2 and up, none at tier 1. A model already at that tier stays; only models Rooms made (RoomItem "speaker") go
local function fitSpeakers(room, tier)
	for _, side in ipairs({ "L", "R" }) do
		local name = "RoomSpeaker_" .. side
		local have = room:FindFirstChild(name)
		if have and have:GetAttribute("RoomItem") ~= "speaker" then have = nil end
		if not (have and have:GetAttribute("Tier") == tier) then
			if have then have:Destroy() end
			local a = room:FindFirstChild("Desk_Speaker_" .. side, true)
			local m = (tier >= 2 and a and a:IsA("Attachment")) and Items.Speakers(tier) or nil
			if m then
				m.Name = name
				m:PivotTo(a.WorldCFrame)
				m.Parent = room
			end
		end
	end
end
local function fitPlotSpeakers(plot, tier)
	for _, room in ipairs(plot:GetChildren()) do
		if room:GetAttribute("RoomKind") then fitSpeakers(room, tier) end
	end
end

-- plots ------------------------------------------------------------------------------------------------------------------
-- the kinds an owner has, ladder order (a fake owner from the hook's Fill: the bedroom). Reading it repairs the saved home too
-- (state), which may wait for the profile: build() calls this before its generation check
local function ownedFor(o)
	local bedroom = Rules.Owned(nil, Cfg.Kinds)
	if not o.player then return bedroom end
	local ok, st = pcall(state, o.player)
	if not ok then report("home: " .. tostring(st)); return bedroom end
	return st.owned
end
-- (re)builds plot k for its owner; an old plot goes only once the new one stands (same place, so nobody falls)
local function build(k)
	local o = owners[k]
	if not o then return nil end
	buildGen[k] = (buildGen[k] or 0) + 1
	local gen = buildGen[k]
	local owned = ownedFor(o) -- may wait for the profile
	local tier = o.player and speakerTier(o.player) or 1 -- a fake owner (the hook's Fill) has the laptop's own
	if buildGen[k] ~= gen or owners[k] ~= o then return nil end -- released or rebuilt meanwhile
	local plot = Build.Plot(k, owned, Cfg, template, { id = o.id, name = o.name })
	fitPlotSpeakers(plot, tier)
	ctx.Interaction.Adopt(plot)
	hookPlot(plot, k)
	local old = plots[k]
	if old then old.Name = old.Name .. "_old" end
	plot.Parent = plotsFolder -- once, straight into Workspace: the added-tag signal hooks the room's Station
	plots[k], kindsOf[k] = plot, owned
	if old then old:Destroy() end
	if o.player then rebuiltEv:Fire(o.player, k) end
	return plot
end
-- the owner's owned rooms may have moved (their CareerGates attribute changed): rebuild their plot once if the set differs from
-- what stands. The set is read from prof.career.gates (state), never from the attribute: a sponsor toggle changes the
-- attribute and not the rooms. No plot yet means the first build is still to read the gates itself; and build() drops a
-- build that another one overtook, so two changes close together can't build twice or leave an old plot standing.
local function syncRooms(p)
	local k = slotOf[p]
	local o = k and owners[k]
	if not (o and o.player == p and plots[k]) then return false end
	local st = state(p)
	if slotOf[p] ~= k or owners[k] ~= o or not plots[k] then return false end -- released while the profile was read
	if sameList(st.owned, kindsOf[k] or {}) then return false end
	return build(k) ~= nil
end
-- the owner's Gear attribute changed: their plot's speakers follow their tier (no plot yet: its build fits them)
local function syncSpeakers(p)
	local k = slotOf[p]
	local o = k and owners[k]
	if not (o and o.player == p and plots[k]) then return false end
	local tier = speakerTier(p)
	local plot = plots[k]
	if not (plot and plot.Parent and slotOf[p] == k) then return false end
	fitPlotSpeakers(plot, tier)
	return true
end

-- room plays (Task 7) ------------------------------------------------------------------------------------------------------
local function playFolder(k)
	local rp = RS.OK:FindFirstChild("RoomPlaying")
	local f = rp and rp:FindFirstChild(string.format("Plot_%02d", k))
	return (f and f:IsA("Folder")) and f or nil
end
-- slot k's play ends (its plot is going, or its owner stopped it); true when one was on
local function endPlay(k)
	local f = playFolder(k)
	if f and f:GetAttribute("Active") == true then f:SetAttribute("Active", false); return true end
	return false
end
local function claim(p)
	local k = slotOf[p]
	if k then return k end
	k = Rules.Claim(slots, Cfg.Slots)
	if not k then
		p:SetAttribute("PlotSlot", 0)
		return nil
	end
	slots[k] = p.UserId
	owners[k] = { id = p.UserId, name = p.DisplayName, player = p }
	slotOf[p] = k
	p:SetAttribute("PlotSlot", k)
	plate(k)
	return k
end
-- frees slot k: everyone standing in the plot goes to the hall's spawn first (guests told why; the owner too unless
-- they are the one leaving), then the plot goes
local function releaseSlot(k, leaving)
	local o = owners[k]
	if not o then return false end
	local target = hallSpawn()
	local movers = {}
	for _, q in ipairs(Players:GetPlayers()) do
		local r = rootOf(q)
		if r and plotAt(r.Position) == k and not (leaving and q == o.player) then table.insert(movers, q) end
	end
	if target then
		local left = #movers
		for _, q in ipairs(movers) do
			if q ~= o.player then toast(q, fill(Copy.OwnerLeft, { player = short(o.name) })) end
			task.spawn(function()
				local ok, err = pcall(teleport, q, target)
				if not ok then report("release move: " .. tostring(err)) end
				left -= 1
			end)
		end
		for _, g in ipairs(testGuests[k] or {}) do
			if g.Parent then g:PivotTo(target + Vector3.new(0, 3, 0)) end
		end
		local t0 = os.clock()
		while left > 0 and os.clock() - t0 < 11 do task.wait(0.05) end -- past teleport's 10 s stream wait
	end
	if owners[k] ~= o then return false end -- released or claimed again while the movers moved
	testGuests[k] = nil
	local plot = plots[k]
	plots[k], kindsOf[k], slots[k], owners[k] = nil, nil, nil, nil
	buildGen[k] = (buildGen[k] or 0) + 1
	if o.player then
		slotOf[o.player] = nil
		if o.player.Parent then o.player:SetAttribute("PlotSlot", 0) end
	end
	if plot then plot:Destroy() end
	endPlay(k) -- its speakers are gone with it
	plate(k)
	for _, q in ipairs(movers) do pcall(presence, q) end
	return true
end

-- the wake-up and the respawn rule ----------------------------------------------------------------------------------------
-- your bedroom's Spawn (forced: past the test hold); no slot: the full toast, and you stay in the studio
local function wakeUp(p, forced)
	if not forced and held() then return false end
	local k = slotOf[p]
	if not k then
		if not forced then task.wait(2) end -- the client's toast label is up by then
		if p.Parent then toast(p, Copy.Full) end
		return false
	end
	if not (hall and roomsDoor) then return false end -- no building, no way out of the plot: stay in the studio
	local t0 = os.clock()
	while not plots[k] and slotOf[p] == k and os.clock() - t0 < 15 do task.wait(0.1) end
	if slotOf[p] ~= k then return false end
	return move(p, roomSpawn(k, "bedroom"), nil)
end
-- after a respawn: back to your bedroom if your last character went inside your own plot; returns "room", "hub" or "held"
local function respawnRule(p, forced)
	if not forced and held() then return "held" end
	local k = slotOf[p]
	if k and respawnHome[p] and hall and roomsDoor then
		local t = roomSpawn(k, "bedroom")
		if t and move(p, t, nil) then return "room" end
	end
	return "hub"
end
local function onCharacter(p, char)
	if not woken[p] then
		woken[p] = true
		task.spawn(function()
			char:WaitForChild("HumanoidRootPart", 5)
			local ok, err = pcall(wakeUp, p, false)
			if not ok then report("wake-up: " .. tostring(err)) end
		end)
		return
	end
	if respawnHome[p] and not held() then
		task.spawn(function()
			char:WaitForChild("HumanoidRootPart", 5)
			local ok, err = pcall(respawnRule, p, false)
			if not ok then report("respawn: " .. tostring(err)) end
		end)
	end
end
local function onJoin(p)
	if slotOf[p] or woken[p] ~= nil then return end
	woken[p] = false
	p:SetAttribute("InPlot", 0)
	local k = claim(p) -- at once: two joins in one tick get two slots
	p.CharacterRemoving:Connect(function(old) respawnHome[p] = homeNow(p, old) end)
	p.CharacterAdded:Connect(function(char) onCharacter(p, char) end)
	gateConns[p] = p:GetAttributeChangedSignal("CareerGates"):Connect(function()
		local ok, err = pcall(syncRooms, p)
		if not ok then report("rooms after a gate change: " .. tostring(err)) end
	end)
	gearConns[p] = p:GetAttributeChangedSignal("Gear"):Connect(function()
		local ok, err = pcall(syncSpeakers, p)
		if not ok then report("speakers after a gear change: " .. tostring(err)) end
	end)
	if p.Character then onCharacter(p, p.Character) end
	if k then
		task.spawn(function()
			local ok, err = pcall(build, k)
			if not ok then report("plot " .. k .. ": " .. tostring(err)) end
		end)
	end
end
local function onLeave(p)
	local k = slotOf[p]
	if k then
		local ok, err = pcall(releaseSlot, k, true)
		if not ok then report("release: " .. tostring(err)) end
	end
	woken[p], respawnHome[p], busy[p], slotOf[p], lastPlay[p] = nil, nil, nil, nil, nil
	sent[p.UserId], counts[p.UserId] = nil, nil
	local gc = gateConns[p]
	if gc then gc:Disconnect(); gateConns[p] = nil end
	local gr = gearConns[p]
	if gr then gr:Disconnect(); gearConns[p] = nil end
	local a = armed[p]
	if a then a.conn:Disconnect(); armed[p] = nil end
end

-- API ------------------------------------------------------------------------------------------------------------------
function M.PlotOf(p) return slotOf[p] end
function M.Owner(k) local o = owners[k]; return o and o.player or nil end
-- your own rooms' world boxes { x0, z0, x1, z1 } (RoomRules.Box), each with its .kind
function M.BoxesFor(p)
	local out = {}
	local k = slotOf[p]
	if not k then return out end
	for _, kind in ipairs(kindsOf[k] or {}) do
		local b = Rules.Box(kind, Cfg, k)
		if b then b.kind = kind; table.insert(out, b) end
	end
	return out
end
-- where p stands: "hub" (WalkInRules.InHub), { slot, kind } in a plot (a room kind, 0 <= y < 20 in its box, else
-- "landing"), or nil (the hall, or between places)
function M.PlaceOf(p)
	local r = rootOf(p)
	if not r then return nil end
	local pos = r.Position
	if WalkInRules.InHub(pos.X, pos.Y, pos.Z) then return "hub" end
	local k = plotAt(pos)
	if not k then return nil end
	for _, kind in ipairs(kindsOf[k] or {}) do
		local b = Rules.Box(kind, Cfg, k)
		if b and pos.X >= b[1] and pos.X <= b[3] and pos.Z >= b[2] and pos.Z <= b[4] and pos.Y >= 0 and pos.Y < 20 then
			return { slot = k, kind = kind }
		end
	end
	return { slot = k, kind = "landing" }
end
function M.Anchor(p, kind, name)
	local k = slotOf[p]
	local room = k and roomOf(k, kind or "bedroom")
	local a = room and room:FindFirstChild(tostring(name), true)
	return (a and a:IsA("Attachment")) and a.WorldCFrame or nil
end
function M.Station(p, kind)
	local k = slotOf[p]
	local room = k and roomOf(k, kind or "bedroom")
	return room and Build.StationOf(room) or nil
end
-- ON SPEAKERS at your own room's laptop (Systems/DAW's room branch, which checked the beat, kit and voice first): the beat
-- plays on that room's speakers. `room` is the laptop's room Model (or a kind; default the bedroom). Returns { ok = true,
-- room = true, tier, kind, position = 0 } or { ok = false, room = true, reason = "away" | "cooldown" | "off" | "invalid" }
function M.PlayLocal(p, pattern, bpm, swing, kit, voice, room)
	local k = slotOf[p]
	if not (k and plots[k]) then return { ok = false, room = true, reason = "away" } end
	if type(pattern) ~= "string" or type(bpm) ~= "number" or bpm ~= bpm or bpm <= 0 or bpm == math.huge then
		return { ok = false, room = true, reason = "invalid" }
	end
	local kind = typeof(room) == "Instance" and room:GetAttribute("RoomKind") or room
	if type(kind) ~= "string" or not Cfg.Kinds[kind] then kind = "bedroom" end
	local now = os.clock()
	if lastPlay[p] and now - lastPlay[p] < (Cfg.PlayCooldown or 1) then return { ok = false, room = true, reason = "cooldown" } end
	local f = playFolder(k)
	if not f then return { ok = false, room = true, reason = "off" } end -- no ReplicatedStorage.OK.RoomPlaying (build/19_rooms.lua)
	local DAWCfg = require(RS.OK.Modules.DAWConfig)
	local Mon = require(game:GetService("ServerScriptService").OK.Services.MonitorService)
	local loops, dur = Mon.LoopsFor(bpm, DAWCfg.Steps, Config.Monitors)
	local tier = speakerTier(p)
	lastPlay[p] = now
	local lead = (Config.Monitors and Config.Monitors.LeadSeconds) or 0.5
	local startAt = workspace:GetServerTimeNow() + lead
	local token = math.floor(tonumber(f:GetAttribute("Token")) or 0) + 1
	f:SetAttribute("Beat", pattern); f:SetAttribute("BPM", bpm); f:SetAttribute("Swing", tonumber(swing) or 0)
	f:SetAttribute("Kit", type(kit) == "string" and kit or "studio")
	f:SetAttribute("Voice", type(voice) == "string" and voice or (DAWCfg.Voices and DAWCfg.Voices[1].id) or "")
	f:SetAttribute("OwnerId", p.UserId); f:SetAttribute("OwnerName", p.DisplayName)
	f:SetAttribute("Room", kind); f:SetAttribute("Tier", tier)
	f:SetAttribute("StartAt", startAt); f:SetAttribute("Loops", loops); f:SetAttribute("EndsAt", startAt + dur)
	f:SetAttribute("Token", token); f:SetAttribute("Active", true) -- last: a listener reads the whole play on these
	task.delay(lead + dur + 0.1, function()
		if f.Parent and f:GetAttribute("Token") == token and f:GetAttribute("Active") == true then f:SetAttribute("Active", false) end
	end)
	playedEv:Fire(p, tier, kind)
	return { ok = true, room = true, tier = tier, kind = kind, position = 0 }
end
-- ends p's own room play (DAW_Stop); true when one was on
function M.StopLocal(p)
	local k = slotOf[p]
	local f = k and playFolder(k)
	if not (f and f:GetAttribute("Active") == true and f:GetAttribute("OwnerId") == p.UserId) then return false end
	f:SetAttribute("Active", false)
	return true
end
-- edit-mode tests (build/t102_check.lua): a fake ctx ({ Data = DataService copy, Gear = Gear copy }) and a fresh Config; no
-- Init needed. _State(p) is state(p) as the plot's build reads it: home (the saved table), dropped, unbuilt, owned.
function M._SetCtxForTest(c) ctx = c end
function M._SetConfigForTest(cfg) Config = cfg; Cfg = cfg.Rooms end
function M._State(p) local st = state(p); return st.home, st.dropped, st.unbuilt, st.owned end

-- the Studio hook --------------------------------------------------------------------------------------------------------
local function fillSlots(n)
	local made = 0
	for _ = 1, math.clamp(math.floor(tonumber(n) or 0), 0, Cfg.Slots) do
		local k = Rules.Claim(slots, Cfg.Slots)
		if not k then break end
		local id = -(900 + k)
		slots[k] = id
		owners[k] = { id = id, name = string.format("Test %02d", k), fake = true }
		plate(k)
		build(k)
		made += 1
	end
	return made
end
local function unfill()
	local fakes = {}
	for k, o in pairs(owners) do if o.fake then table.insert(fakes, k) end end
	for _, k in ipairs(fakes) do releaseSlot(k, false) end
	return #fakes
end
local function guest(k)
	k = tonumber(k)
	local t = k and (roomSpawn(k, "bedroom") or landingInside(k))
	if not t then return nil end
	local m = Instance.new("Model")
	m.Name = string.format("OK_TestGuest_%02d", k)
	m.Archivable = false
	local r = Instance.new("Part")
	r.Name = "HumanoidRootPart"; r.Size = Vector3.new(2, 2, 1); r.Anchored = true; r.CanCollide = false
	r.CanTouch = false; r.CanQuery = false; r.Transparency = 0.5
	r.Parent = m
	m.PrimaryPart = r
	m:PivotTo(t + Vector3.new(0, 3, 0))
	m.Parent = workspace
	testGuests[k] = testGuests[k] or {}
	table.insert(testGuests[k], m)
	return m
end
local function arm(p, cmd, a)
	local DAW = require(RS.OK.Systems.DAW)
	local old = armed[p]
	if old then old.conn:Disconnect() end
	local entry = {}
	entry.conn = DAW.Opened:Connect(function(q, inst)
		if q ~= p or typeof(inst) ~= "Instance" or not (plotsFolder and inst:IsDescendantOf(plotsFolder)) then return end
		entry.conn:Disconnect()
		if armed[p] == entry then armed[p] = nil end
		task.delay(2, function()
			local ok, err = pcall(dispatch, cmd, p.UserId, a)
			if not ok then report("OnOpen " .. tostring(cmd) .. ": " .. tostring(err)) end
		end)
	end)
	armed[p] = entry
	task.delay(30, function()
		if armed[p] == entry then entry.conn:Disconnect(); armed[p] = nil end
	end)
	return true
end
-- the plot the player stands in, else their own
local function here(p)
	local r = rootOf(p)
	return (r and plotAt(r.Position)) or slotOf[p]
end
dispatch = function(cmd, userId, a, b)
	if cmd == "Fill" then return fillSlots(a) end
	if cmd == "Unfill" then return unfill() end
	local p = Players:GetPlayerByUserId(userId)
	if not p then return nil end
	if cmd == "Plot" then
		local k = slotOf[p]
		if not k then return nil end
		local o = origin(k)
		return { slot = k, origin = { o.X, o.Y, o.Z }, rooms = table.clone(kindsOf[k] or {}) }
	end
	if cmd == "Reset" then
		resetHome(p) -- every test's fresh(): one test's saved items never reach the next
		local k = claim(p)
		return k ~= nil and build(k) ~= nil
	end
	if cmd == "Home" then local st = state(p); return deepCopy(st.home) end
	if cmd == "SetHome" then return setHome(p, a) end
	if cmd == "WakeUp" then return wakeUp(p, true) end
	if cmd == "Enter" then return enterPlot(p, a, b == true) end
	if cmd == "Exit" then local k = here(p); return k ~= nil and exitRoom(p, k, a or "bedroom") end
	if cmd == "GoIn" then local k = here(p); return k ~= nil and goRoom(p, k, a or "bedroom") end
	if cmd == "Leave" then local k = here(p); return k ~= nil and leavePlot(p, k) end
	if cmd == "HubDoor" then return toCorridor(p) end
	if cmd == "RoomsDoor" then return toHall(p) end
	if cmd == "Respawn" then
		respawnHome[p] = homeNow(p)
		p:LoadCharacter()
		return respawnRule(p, true)
	end
	if cmd == "Release" then local k = slotOf[p]; return k ~= nil and releaseSlot(k, false) end
	if cmd == "Claim" then
		local k = claim(p)
		if k then build(k) end -- no slot: nil, and no toast (the full toast is the wake-up's: the hook's WakeUp runs it)
		return k
	end
	if cmd == "Anchor" then return M.Anchor(p, a, b) end
	if cmd == "InPlot" then return presence(p) end
	if cmd == "PlaceOf" then
		local place = M.PlaceOf(p)
		return type(place) == "table" and table.clone(place) or place
	end
	if cmd == "Guest" then return guest(a) end
	if cmd == "Station" then return M.Station(p, a) end
	if cmd == "RunStation" then
		local st = M.Station(p, a)
		if not st then return nil end
		local acted, text = ctx.Interaction._RunHandler("Station", p, st)
		return { acted = acted, toast = text }
	end
	if cmd == "Sent" then local log = sent[p.UserId] or {}; sent[p.UserId] = nil; return log end
	if cmd == "MayUse" then return ctx.Interaction.MayUse(p, a) end
	if cmd == "StationOf" then
		local inst, room = require(RS.OK.Systems.DAW).StationOf(p)
		return { inst = inst, room = room }
	end
	if cmd == "Run" then
		if typeof(b) ~= "Instance" then return nil end
		local acted, text = ctx.Interaction._RunHandler(a, p, b)
		return { acted = acted, toast = text }
	end
	if cmd == "OnOpen" then return arm(p, a, b) end
	-- Task 7: DAW_Broadcast's and DAW_Stop's own handlers for this player (the remote's path: the room branch, the
	-- BroadcastTried rule); Counts since the last read; the speaker tier; the live FIRE rule for a token
	if cmd == "Play" then return require(RS.OK.Systems.DAW)._Broadcast(p, a, b, 0) end
	if cmd == "Stop" then require(RS.OK.Systems.DAW)._Stop(p); return true end
	if cmd == "Counts" then
		local c = counts[p.UserId] or {}
		counts[p.UserId] = nil
		return { played = c.played or 0, tried = c.tried or 0, rebuilt = c.rebuilt or 0 }
	end
	if cmd == "SpeakerTier" then return speakerTier(p) end
	if cmd == "Fire" then return require(RS.OK.Systems.Reactions).Send(p, a) end
	return nil
end
local function bump(p, key)
	if typeof(p) ~= "Instance" then return end
	local c = counts[p.UserId] or {}
	counts[p.UserId] = c
	c[key] = (c[key] or 0) + 1
end
local function makeHook()
	local SOK = game:GetService("ServerScriptService"):FindFirstChild("OK")
	if not SOK then return end
	local hook = SOK:FindFirstChild("_StudioRoomsHook") or Instance.new("BindableFunction")
	hook.Name = "_StudioRoomsHook"; hook.Parent = SOK
	hook.OnInvoke = dispatch
	M.Played:Connect(function(p) bump(p, "played") end)
	M.Rebuilt:Connect(function(p) bump(p, "rebuilt") end)
	local okDAW, DAW = pcall(require, RS.OK.Systems.DAW)
	if okDAW and type(DAW) == "table" and DAW.BroadcastTried then DAW.BroadcastTried:Connect(function(p) bump(p, "tried") end) end
end

-- start ------------------------------------------------------------------------------------------------------------------
local function loop()
	while true do
		task.wait(1)
		for _, p in ipairs(Players:GetPlayers()) do
			local ok, err = pcall(presence, p)
			if not ok then report("presence: " .. tostring(err)) end
		end
	end
end

function M.Init(c)
	ctx = c
	Cfg = Config.Rooms
	local SS = game:GetService("ServerStorage")
	-- the bedroom template: ServerStorage's, else Workspace's (moved to ServerStorage: plots clone it, nobody visits it)
	template = SS:FindFirstChild(Cfg.Template)
	if not template then
		local inWs = workspace:FindFirstChild(Cfg.Template)
		if inWs then inWs.Parent = SS; template = inWs end
	end
	if template and not template:IsA("Model") then template = nil end
	plotsFolder = workspace:FindFirstChild("OK_Plots")
	if not plotsFolder then
		plotsFolder = Instance.new("Folder")
		plotsFolder.Name = "OK_Plots"
		plotsFolder.Parent = workspace
	end
	local rooms = workspace:FindFirstChild("OK_Rooms")
	hall = rooms and rooms:FindFirstChild("Hall")
	roomsDoor = rooms and rooms:FindFirstChild("RoomsDoor")
	if not (hall and roomsDoor) then report("Workspace.OK_Rooms (Hall, RoomsDoor) missing: run build/19_rooms.lua in Edit") end
	for k = 1, Cfg.Slots do
		local door = hallDoor(k)
		onPrompt(door, "EnterPrompt", function(p) enterPlot(p, k, false) end)
		plate(k)
	end
	onPrompt(hall and hall:FindFirstChild("HubDoor"), "HubPrompt", toCorridor)
	onPrompt(roomsDoor, "RoomsPrompt", toHall)
	Players.PlayerAdded:Connect(onJoin)
	Players.PlayerRemoving:Connect(onLeave)
	for _, p in ipairs(Players:GetPlayers()) do onJoin(p) end
	task.spawn(loop)
	if RunService:IsStudio() and RunService:IsRunning() then makeHook() end
end

return M
