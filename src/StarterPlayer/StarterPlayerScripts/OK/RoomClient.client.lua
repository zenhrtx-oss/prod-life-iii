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
-- Task 10 (R-T7's review M9): at tier 2 and 3 the emitters fall back to the Station while the cabinets are missing; that
-- fallback is never kept once a cabinet is there (a refit, or streaming, can bring them after the play started).
--
-- Decorate mode (Task 10; the bar is Modules/RoomUI, PlayerGui.OK_Room; the server is Systems/Rooms):
-- * Only the owner sees a room's DecoratePrompt: this client turns off every DecoratePrompt under Workspace.OK_Plots whose
--   room (the ancestor Model with RoomKind) has another OwnerId, as it streams in. That rule starts first, on its own, so
--   nothing the edit bar waits on can hold it back. Task 14: the same rule turns off every landing DoorPrompt (the owner's
--   door mode) whose own OwnerId attribute isn't this player's.
-- * In: the server's Room remote "decorate" { kind } (the owner pressed that room's DecoratePrompt). Not while the beat
--   maker is open, nor (R-T16 fix, I1) while a walk-in or Day One card is (PlayerGui.OK_WalkIn's Open; either refusal sets
--   OK_Room's Refused to "daw" or "card"), and only for this player's own room (Plot_<PlotSlot>.Room_<kind>, OwnerId this player) once Room_Get has
--   answered with that room and, after that wait, the same live character still stands in their own plot (InPlot =
--   PlotSlot). Then, all in one pcall (a throw leaves at once, LeftBy "error"): the camera goes Scriptable, straight down over the room with its north at the top,
--   high enough that the room's floor (Config.Rooms.Kinds[kind].size, half a stud each side) fits the screen between the top
--   bar and the edit bar (refitted when the viewport changes or the bar's rows do); the room's parts whose bottom is
--   CEILING_MIN studs or more above its floor (the ceiling, its lamp) are hidden locally (LocalTransparencyModifier 1); the
--   controls are disabled (the ControlModule: PlayerScripts.PlayerModule's GetControls(), or StarterPlayer.PlayerModule's
--   ControlModule in Roblox's newer layout; with no PlayerModule at all, the humanoid's WalkSpeed and jump at 0 on this
--   client), so the character stays put; the touch controls and every ProximityPrompt (ProximityPromptService.Enabled)
--   are off; the bar shows.
-- * The bar browses this room's floor items that are open to you (State's unlocked; catalog order; a wall item, the poster,
--   is Task 13's). ADD puts the shown item down as a ghost (a RoomItems.Build copy at transparency 0.5, with a footprint
--   plate under it) on the first free cell (RoomRules.Fits on State's own grid, keep, limit and items), or the room's centre
--   when none is free. A tap on the room: on a placed item (a raycast against the room's Items) picks it (its ghost on its own
--   cell, the item itself dimmed); on the floor (the floor plane) moves the ghost so its footprint is centred under the tap;
--   a drag keeps moving it. Keyboard: WASD / arrows move it a cell, R turns it, Enter places it, Delete removes a placed one,
--   Backspace cancels (or leaves, with nothing picked). The ghost and its plate are red while the client's RoomRules.Fits
--   refuses, run as the server's Edit runs it: a saved item that doesn't stand still holds its cells (Fits' `held`, R-T10
--   fix 1), so the ghost is red over a faint ghost. ⟳ ROTATE turns it a quarter (its lowest cell stays); ✓ PLACE sends Room_Edit ("place" for a new item, "move" for
--   a placed one), 🗑 REMOVE sends "remove"; ✕ CANCEL lets go. A refusal (the server's reason) shows its copy §6.3 sentence in
--   the bar's hint line until the next action. An item saved but not standing (locked: RoomRules.Repair keeps it unbuilt)
--   shows as a faint grey ghost at its cell. Ghosts, plates and faint ghosts live only on this client, in a Folder
--   OK_DecoratePreview inside the room.
-- * Out: DONE; a teleport or any move of 3 studs or more, InPlot changing, the room going (a rebuild); a death or a respawn;
--   a throw while setting up; (R-T16 fix, I1) the beat maker's window showing (PlayerGui.OK_DAW.DAW Visible: LeftBy "daw")
--   or a walk-in or Day One card opening (OK_WalkIn's Open turning true: LeftBy "card"), so the two never fight over the
--   prompts, the touch controls, Backspace / ButtonB or the screen.
--   Each puts back the camera (Custom, on the humanoid), the controls, the touch controls, the prompts and the hidden parts,
--   and destroys the preview; except that the "daw" way out leaves the prompts (ProximityPromptService) and the touch
--   controls alone: DAWClient owns them while the beat maker is open (it turned them off when it opened and turns them on
--   when it closes). A room laptop's beat maker is never seated, so DAWClient never takes the camera there and it is safe
--   to give back.
-- * The Room remote's "state" (the server's State after any change to your rooms) refreshes the view while decorating; after
--   a Room_Edit that answers ok this client also asks Room_Get, so the view never waits on the push.
-- * Posters you design (Task 13). In a room with wall spots (Config.Rooms.Kinds.<kind>.posters: home and real) the Poster_n
--   anchors are Attachments, which no tap can hit, and from straight above a poster on the wall is a line (preflight m21).
--   So each spot gets a client-only hit part, OK_DecoratePreview.PosterSlots.Slot_<n>: a see-through plate on the floor
--   against the wall under the spot (SLOT_W along the wall, SLOT_D into the room), queryable, never colliding or touching;
--   pale while free, in the hung poster's colour while one hangs there; hidden (LocalTransparencyModifier 1, and left out of
--   the tap) while a floor item or the designer is picked. With nothing picked the hint reads 6.13 then 9.29 while a spot is
--   free and the room isn't full (used < limit; posters count), and in the designer 9.30 while the design can be hung, else the
--   sentence for why not (RoomUI.Sentence, e.g. 6.36 for a full room). A tap on a free spot (or Command "slot:n") opens the designer (RoomUI's "poster" face) for a new poster, word 1,
--   colour 1, style 1; a tap on a spot holding a poster, or on the poster itself, picks it for a redesign (🗑 REMOVE shows; its
--   own design is turned off on this client under the preview). While designing, the camera stands level in front of the
--   spot, the poster and a margin between the top bar and the bar; the live preview (OK_DecoratePreview.PosterPreview, a
--   RoomItems.Poster that answers no ray) hangs on the spot; GhostOk is the client's RoomRules.Fits for the design (a
--   redesign leaves itself out). WORD / COLOR / STYLE ◀ ▶ ("word:-1", "word:+1", ...; wrapping) change it; HANG ("hang", or
--   Enter) sends Room_Edit { op = "poster", kind, slot, w, c, s } (the server redesigns a spot that holds one); 🗑 REMOVE
--   (Delete) sends "remove" at its index; ✕ CANCEL (Backspace) closes the designer and the camera goes back over the room.
--   World taps are ignored while designing. No TextBox anywhere: the words are preset.
-- Test attributes on OK_Room (RoomUI writes Rows and Layout): Editing, Kind, Item (the id the bar shows), Selected ("",
-- "new:<id>" or "item:<index>"), Ghost ("x,z,r" of the ghost's lowest cell and turn, or ""), GhostOk, LastEdit ("" on the way
-- in, "sending", then "ok" or the refusal: "error" for a failed call), LeftBy (why the last session ended: "done", "moved",
-- "died", "respawn", "room", "error": a throw while setting up, "daw", "card": R-T16 fix, I1), Refused (R-T16 fix, I1: "daw"
-- or "card" when a "decorate" was refused for the beat maker or a card; a test clears it to "" first), Poster ("slot,w,c,s"
-- of the design on show, or ""; Task 13),
-- ControlsOn (the ControlModule's own controlsEnabled, else its active controller's `enabled`,
-- read back right after this client disabled or enabled it; nil when neither can be read; in a game with no PlayerModule,
-- this client's own flag for the WalkSpeed / jump fallback. A test can't require the ControlModule itself: from its own VM
-- that would be a second copy); Command = "next" | "prev" | "add" | "cell:x,z" | "pick:index" | "rotate" | "place" | "remove" |
-- "cancel" | "done" | "tap:x,y" (a tap at that screen point, as a real tap's own path) | "slot:n" | "word:+1" | "word:-1" |
-- "color:+1" | "color:-1" | "style:+1" | "style:-1" | "hang" (Task 13) | "key:<KeyCode name>" (R-T16 fix, M5: that key's
-- press through the keyboard / gamepad action's own handler, keyAction), cleared to "" once taken. Keys: WASD, the arrows
-- and (M5) DPadUp / DPadDown / DPadLeft / DPadRight move the ghost a cell (prompts are off in decorate mode, so the pad's
-- DPadDown (Decorate) and DPadRight (the closet) never clash). Selected also reads
-- "slot:<n>" while a new poster is designed for spot n (a hung one is "item:<index>").
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local OK = RS:WaitForChild("OK", 30)

-- decorate mode (Task 10) ------------------------------------------------------------------------------------------------
-- only the owner sees a room's DecoratePrompt: installed first, on its own (R-T10 fix 3, review minor 3), so nothing the
-- edit bar waits on (the remotes, RoomUI.Build, the requires) can keep a visitor from seeing another owner's prompt.
-- The same for the landing's DoorPrompt (Task 14: the owner's door mode), which Systems/Rooms stamps with its owner's id
-- (the Landing model has no RoomKind or OwnerId of its own)
task.spawn(function()
	local function gate(d)
		if not d:IsA("ProximityPrompt") then return end
		if d.Name == "DoorPrompt" then
			if d:GetAttribute("OwnerId") ~= player.UserId then d.Enabled = false end
			return
		end
		if d.Name ~= "DecoratePrompt" then return end
		local a = d.Parent
		while a and a ~= workspace and not (a:IsA("Model") and a:GetAttribute("RoomKind") ~= nil) do a = a.Parent end
		if not (a and a ~= workspace and a:GetAttribute("OwnerId") == player.UserId) then d.Enabled = false end
	end
	local plotsF = workspace:WaitForChild("OK_Plots", 60)
	if not plotsF then return end
	plotsF.DescendantAdded:Connect(gate)
	for _, d in ipairs(plotsF:GetDescendants()) do gate(d) end
end)
task.spawn(function()
	local Remotes = OK and OK:WaitForChild("Remotes", 30)
	local RoomEv = Remotes and Remotes:WaitForChild("Room", 30)
	local RoomGet = Remotes and Remotes:WaitForChild("Room_Get", 30)
	local RoomEditRF = Remotes and Remotes:WaitForChild("Room_Edit", 30)
	if not (RoomEv and RoomGet and RoomEditRF) then
		warn("[OK][ERR] decorate mode: Remotes.Room, Room_Get or Room_Edit missing (run build/19_rooms.lua in Edit)")
		return
	end
	local RunService = game:GetService("RunService")
	local UIS = game:GetService("UserInputService")
	local CAS = game:GetService("ContextActionService")
	local GuiService = game:GetService("GuiService")
	local PPS = game:GetService("ProximityPromptService")
	local RoomsCfg = require(OK.Config).Rooms
	local Rules = require(OK.Modules.RoomRules)
	local Catalog = require(OK.Data.RoomCatalog)
	local Items = require(OK.Modules.RoomItems)
	local RoomUI = require(OK.Modules.RoomUI)
	local Theme = require(OK.Modules.UITheme)
	local ui = RoomUI.Build(Theme, RoomsCfg)
	local gui = ui.gui
	local Copy = RoomUI.Copy
	local CEILING_MIN = 7 -- studs above the floor: a part whose bottom is this high is hidden while decorating
	local MOVED = 3       -- studs: the character moved this far (a teleport): decorate mode ends
	local RED, GREEN = Color3.fromRGB(230, 60, 60), Color3.fromRGB(70, 200, 120)
	local ACT = "OK_Decorate"
	-- posters (Task 13)
	local POSTER_N = { w = #(RoomsCfg.PosterWords or {}), c = #(RoomsCfg.PosterColors or {}), s = tonumber(RoomsCfg.PosterStyles) or 0 }
	local POSTER_KEY = { word = "w", color = "c", style = "s" }
	local SLOT_W, SLOT_D, SLOT_T = 3.6, 2.5, 0.04 -- studs: a wall spot's hit plate along the wall, into the room, thick
	local SLOT_LIFT = 0.06 -- studs the plate's underside floats above the floor: clear of the booth mat's top (y 0.05, RoomBuild), so no face is coplanar with it
	local SLOT_FREE = Color3.fromRGB(235, 235, 235)
	local WALL_MARGIN = 1 -- studs the designer's camera keeps round the poster
	local PREVIEW_OUT = 0.02 -- studs the preview stands proud of the wall (over a hung poster being redesigned)

	local function hum() local c = player.Character; return c and c:FindFirstChildOfClass("Humanoid") end
	local function rootPart() local c = player.Character; return c and c:FindFirstChild("HumanoidRootPart") end
	local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
	local function asSet(list) local s = {}; for _, id in ipairs(type(list) == "table" and list or {}) do s[id] = true end; return s end
	local function allowed(item, kind) return item.rooms == nil or table.find(item.rooms, kind) ~= nil end
	local function isOpen(item, set) return item.unlock == nil or set[item.id] == true end
	-- the player's controls, the ControlModule (nil when the game has none; looked for again on the next call). Two layouts
	-- (R-T10 fix 2): the legacy PlayerScripts.PlayerModule, whose GetControls() answers it, and Roblox's newer
	-- StarterPlayer.PlayerModule, whose ControlModule child is the live singleton (its parent's module has no GetControls).
	-- Found with FindFirstChild only: a path that isn't there never appears, so nothing waits on it
	local ctlCache
	local function controls()
		if ctlCache then return ctlCache end
		local ok, c = pcall(function()
			local ps = player:FindFirstChild("PlayerScripts")
			local pm = ps and ps:FindFirstChild("PlayerModule")
			if pm and pm:IsA("ModuleScript") then
				local m = require(pm)
				if type(m) == "table" and type(m.GetControls) == "function" then return m:GetControls() end
			end
			local sp = game:GetService("StarterPlayer"):FindFirstChild("PlayerModule")
			local cm = sp and sp:FindFirstChild("ControlModule")
			if cm and cm:IsA("ModuleScript") then
				local m = require(cm)
				if type(m) == "table" and type(m.Disable) == "function" and type(m.Enable) == "function" then return m end
			end
			return nil
		end)
		if ok and type(c) == "table" then ctlCache = c end
		return ctlCache
	end
	-- whether the controls are on, as the ControlModule reads itself: its controlsEnabled (Disable / Enable set it; the
	-- active controller's own `enabled` doesn't move with them in the newer layout), else the active controller's
	-- `enabled`; nil when neither can be read. The gui's ControlsOn
	local function controlsState()
		local ctl = ctlCache
		if not ctl then return nil end
		local ok, v = pcall(function()
			if type(ctl.controlsEnabled) == "boolean" then return ctl.controlsEnabled end
			local c = type(ctl.GetActiveController) == "function" and ctl:GetActiveController() or ctl.activeController
			if type(c) == "table" and type(c.enabled) == "boolean" then return c.enabled end
			return nil
		end)
		if ok then return v end
		return nil
	end
	-- the movement lock: the ControlModule off; in a game with no PlayerModule at all, the humanoid's own WalkSpeed,
	-- JumpPower and JumpHeight at 0 on this client (put back as they were), with ControlsOn from this client's own flag
	local function lock(e, h)
		local ctl = controls()
		if ctl then
			pcall(function() ctl:Disable() end)
			gui:SetAttribute("ControlsOn", controlsState())
			return
		end
		e.frozen = { hum = h, ws = h.WalkSpeed, jp = h.JumpPower, jh = h.JumpHeight }
		h.WalkSpeed, h.JumpPower, h.JumpHeight = 0, 0, 0
		gui:SetAttribute("ControlsOn", false)
	end
	local function unlock(e)
		local f = e.frozen
		if f then
			e.frozen = nil
			if f.hum.Parent then f.hum.WalkSpeed, f.hum.JumpPower, f.hum.JumpHeight = f.ws, f.jp, f.jh end
			gui:SetAttribute("ControlsOn", true)
			return
		end
		local ctl = controls()
		if ctl then pcall(function() ctl:Enable() end) end
		gui:SetAttribute("ControlsOn", controlsState())
	end
	-- this player's own room of `kind` on this client
	local function myRoom(kind)
		local k = player:GetAttribute("PlotSlot")
		local plots = workspace:FindFirstChild("OK_Plots")
		local pm = plots and type(k) == "number" and k > 0 and plots:FindFirstChild(string.format("Plot_%02d", k)) or nil
		local room = pm and pm:FindFirstChild("Room_" .. tostring(kind))
		return (room and room:IsA("Model") and room:GetAttribute("OwnerId") == player.UserId) and room or nil
	end
	local function fetch()
		local ok, v = pcall(function() return RoomGet:InvokeServer() end)
		return (ok and type(v) == "table" and type(v.rooms) == "table") and v or nil
	end

	-- the session: { kind, room, pivot, view (State), rv (view.rooms[kind]), set (unlocked), list (browse ids), browse, sel = nil |
	-- { id, index? (a placed item), x, z, r }, poster = nil | { slot, w, c, s, index? (a hung one) } (the designer, Task 13; never
	-- both sel and poster), busy, msg (a refusal's sentence on show), at (where the character stood),
	-- folder (OK_DecoratePreview), ghost, plate, faint, preview (the poster's), hidden / dimmed ({ [part] = its
	-- LocalTransparencyModifier before }), guiOff ({ [SurfaceGui] = its Enabled before }), aimed ("top" | "wall:<n>"), anchors
	-- ({ [n] = the Poster_n Attachment, or false }),
	-- conns, saved, rows }
	local ed = nil
	local leave -- (why)
	local setup -- (session, humanoid, view): enter()'s part that turns things off and on, run in a pcall
	local keyAction -- (name, state, input): the keyboard / gamepad action (below); the Command seam's "key:" runs it too

	-- what owns the screen besides decorate mode (R-T16 fix, I1): the beat maker's window and the walk-in / Day One card
	local function dawWindow()
		local pg = player:FindFirstChild("PlayerGui")
		local g = pg and pg:FindFirstChild("OK_DAW")
		local w = g and g:FindFirstChild("DAW")
		return (w and w:IsA("GuiObject")) and w or nil
	end
	local function cardGui() local pg = player:FindFirstChild("PlayerGui"); return pg and pg:FindFirstChild("OK_WalkIn") or nil end
	local function dawOpen() local w = dawWindow(); return w ~= nil and w.Visible end
	local function cardOpen() local g = cardGui(); return g ~= nil and g:GetAttribute("Open") == true end

	local function kindCfg() local rv = ed.rv; return { limit = rv.limit, grid = rv.grid, keep = rv.keep, posters = rv.slots } end
	-- the client's Fits, as the server's Edit runs it: the saved items that don't stand (locked) still hold their cells
	local function fits(id, x, z, r, index)
		return Rules.Fits(ed.rv.items, { id = id, x = x, z = z, r = r }, kindCfg(), Catalog, ed.set, ed.kind, index, RoomsCfg, ed.held)
	end
	local function footprint(item, r)
		local w, d = item.size[1], item.size[2]
		if r % 2 == 1 then w, d = d, w end
		return w, d
	end
	-- the first lowest cell where `id` (turned r) fits now, scanning State's grid areas in order; else the room's centre
	local function firstCell(id, r)
		local seen = {}
		for _, a in ipairs(ed.rv.grid or {}) do
			for cz = math.floor(math.min(a[2], a[4])), math.ceil(math.max(a[2], a[4])) do
				for cx = math.floor(math.min(a[1], a[3])), math.ceil(math.max(a[1], a[3])) do
					local key = cx .. ":" .. cz
					if not seen[key] then
						seen[key] = true
						if fits(id, cx, cz, r, nil) then return cx, cz end
					end
				end
			end
		end
		local w, d = footprint(Catalog.ById[id], r)
		return math.floor(-w / 2 + 0.5), math.floor(-d / 2 + 0.5)
	end
	local function previewFolder()
		if ed.folder and ed.folder.Parent then return ed.folder end
		local f = Instance.new("Folder")
		f.Name = "OK_DecoratePreview"; f.Archivable = false
		f.Parent = ed.room
		ed.folder = f
		return f
	end
	-- a see-through RoomItems.Build copy that no tap, touch, collision or shadow ever meets
	local function ghostModel(id, transparency)
		local m = Items.Build(id, Catalog)
		if not m then return nil end
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Transparency = math.max(d.Transparency, transparency)
				d.CanQuery, d.CanCollide, d.CanTouch, d.CastShadow = false, false, false, false
				d:SetAttribute("BaseColor", d.Color)
			end
		end
		return m
	end
	-- an item's origin at the footprint whose lowest cell is (x, z), turned r (as RoomEdit.Fit stands the real one)
	local function cellCF(item, x, z, r)
		local cx, cz = Rules.Centre(item, { x = x, z = z, r = r })
		if not cx then return nil end
		return ed.pivot * CFrame.new(cx, 0, cz) * CFrame.Angles(0, r * math.pi / 2, 0)
	end
	local function clearGhost()
		if ed.ghost then ed.ghost:Destroy(); ed.ghost = nil end
		if ed.plate then ed.plate:Destroy(); ed.plate = nil end
	end
	local function showGhost()
		local s = ed.sel
		local item = s and Catalog.ById[s.id]
		if not item then
			clearGhost()
			gui:SetAttribute("Ghost", ""); gui:SetAttribute("GhostOk", false)
			return
		end
		if not (ed.ghost and ed.ghost.Parent and ed.ghost:GetAttribute("ItemId") == s.id) then
			clearGhost()
			ed.ghost = ghostModel(s.id, 0.5)
			if ed.ghost then ed.ghost.Name = "Ghost"; ed.ghost.Parent = previewFolder() end
			local plate = Instance.new("Part")
			plate.Name = "Footprint"; plate.Anchored = true; plate.Material = Enum.Material.SmoothPlastic; plate.Transparency = 0.45
			plate.CanCollide, plate.CanQuery, plate.CanTouch, plate.CastShadow = false, false, false, false
			plate.TopSurface, plate.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
			plate.Parent = previewFolder()
			ed.plate = plate
		end
		local ok = fits(s.id, s.x, s.z, s.r, s.index) == true
		local cf = cellCF(item, s.x, s.z, s.r)
		local w, d = footprint(item, s.r)
		if cf then
			if ed.ghost then ed.ghost:PivotTo(cf + ed.pivot.UpVector * 0.02) end
			ed.plate.Size = Vector3.new(math.max(0.2, w - 0.08), 0.06, math.max(0.2, d - 0.08))
			ed.plate.CFrame = ed.pivot * CFrame.new(s.x + w / 2, 0.04, s.z + d / 2)
		end
		ed.plate.Color = ok and GREEN or RED
		if ed.ghost then
			for _, p in ipairs(ed.ghost:GetDescendants()) do
				if p:IsA("BasePart") then p.Color = ok and (p:GetAttribute("BaseColor") or p.Color) or RED end
			end
		end
		gui:SetAttribute("Ghost", string.format("%d,%d,%d", s.x, s.z, s.r))
		gui:SetAttribute("GhostOk", ok)
	end
	-- the saved items that don't stand (locked: Repair keeps them unbuilt), as faint grey ghosts
	local function showUnbuilt()
		for _, m in ipairs(ed.faint or {}) do m:Destroy() end
		ed.faint = {}
		for i, e in ipairs(ed.rv.items) do
			local it = type(e) == "table" and Catalog.ById[e.id] or nil
			if it and it.kind == "floor" and not isOpen(it, ed.set) then
				local m = ghostModel(e.id, 0.8)
				local cf = m and cellCF(it, e.x, e.z, e.r or 0)
				if m and cf then
					for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then p.Color = Theme.muted end end
					m.Name = "Unbuilt_" .. i
					m:PivotTo(cf)
					m.Parent = previewFolder()
					table.insert(ed.faint, m)
				elseif m then
					m:Destroy()
				end
			end
		end
	end
	-- the placed item at `index` (its model in the room's Items), dimmed while it is picked
	-- (a picked poster's own design, its SurfaceGui, is turned off too: the preview stands in front of it)
	local function undim()
		for part, v in pairs(ed.dimmed) do if part.Parent then part.LocalTransparencyModifier = v end end
		ed.dimmed = {}
		for g, on in pairs(ed.guiOff) do if g.Parent then g.Enabled = on end end
		ed.guiOff = {}
	end
	local function dim(index)
		undim()
		local f = ed.room:FindFirstChild("Items")
		for _, m in ipairs(f and f:GetChildren() or {}) do
			if m:IsA("Model") and m:GetAttribute("Index") == index then
				for _, p in ipairs(m:GetDescendants()) do
					if p:IsA("BasePart") then ed.dimmed[p] = p.LocalTransparencyModifier; p.LocalTransparencyModifier = 0.7
					elseif p:IsA("SurfaceGui") then ed.guiOff[p] = p.Enabled; p.Enabled = false end
				end
			end
		end
	end

	-- posters (Task 13) ---------------------------------------------------------------------------------------------------
	-- the room's Poster_<n> Attachment (found by name like every anchor, once a session: the room doesn't change under it), or nil
	local function anchorOf(n)
		local c = ed.anchors[n]
		if c == nil then
			local a = ed.room:FindFirstChild("Poster_" .. tostring(n), true)
			c = (a and a:IsA("Attachment")) and a or false
			ed.anchors[n] = c
		end
		return (c and c.Parent) and c or nil
	end
	-- the index of the poster State says hangs on spot n, or nil
	local function hungAt(n)
		for i, e in ipairs(ed.rv.items) do
			local it = type(e) == "table" and Catalog.ById[e.id] or nil
			if it and it.kind == "wall" and e.slot == n then return i end
		end
		return nil
	end
	local function spots() return math.max(0, math.floor(tonumber(ed.rv.slots) or 0)) end
	local function freeSpot()
		for n = 1, spots() do if not hungAt(n) and anchorOf(n) then return true end end
		return false
	end
	-- the client's Fits for the design on show, as the server's Edit runs it (a redesign leaves itself out)
	local function posterFits(pd)
		return Rules.Fits(ed.rv.items, { id = "poster", slot = pd.slot, w = pd.w, c = pd.c, s = pd.s }, kindCfg(), Catalog, ed.set, ed.kind,
			pd.index, RoomsCfg)
	end
	-- the wall spots' hit plates (m21): one per Poster_n anchor, on the floor against the wall under it
	local function showSlots()
		local n = spots()
		local have = ed.folder and ed.folder:FindFirstChild("PosterSlots")
		if n < 1 and not have then return end
		local root = previewFolder()
		local f = root:FindFirstChild("PosterSlots")
		if not f then
			f = Instance.new("Folder")
			f.Name = "PosterSlots"
			f.Parent = root
		end
		local hide = ed.sel ~= nil or ed.poster ~= nil
		local up = ed.pivot.UpVector
		for i = 1, n do
			local a = anchorOf(i)
			local plate = f:FindFirstChild("Slot_" .. i)
			if a then
				if not plate then
					plate = Instance.new("Part")
					plate.Name = "Slot_" .. i
					plate.Anchored = true; plate.Material = Enum.Material.SmoothPlastic
					plate.CanCollide, plate.CanQuery, plate.CanTouch, plate.CastShadow = false, true, false, false
					plate.TopSurface, plate.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
					plate.Size = Vector3.new(SLOT_W, SLOT_T, SLOT_D)
					plate:SetAttribute("PosterSlot", i)
					plate.Parent = f
				end
				local cf = a.WorldCFrame
				local into = (cf.LookVector - up * cf.LookVector:Dot(up)).Unit
				local base = a.WorldPosition - up * up:Dot(a.WorldPosition - ed.pivot.Position) -- on the floor under the spot
				local at = base + into * (SLOT_D / 2) + up * (SLOT_T / 2 + SLOT_LIFT) -- the plate's centre 0.08 up, its top 0.10
				plate.CFrame = CFrame.lookAt(at, at + into, up)
				local h = hungAt(i)
				local e = h and ed.rv.items[h]
				local col = e and (RoomsCfg.PosterColors or {})[e.c]
				plate.Color = col and Color3.fromRGB(col[1], col[2], col[3]) or SLOT_FREE
				plate.Transparency = col and 0.5 or 0.6
				plate.LocalTransparencyModifier = hide and 1 or 0
			elseif plate then
				plate:Destroy()
			end
		end
	end
	-- the designer's live preview on its spot (client only, answers no ray), and the Poster / GhostOk attributes
	local function showPoster()
		if ed.preview then ed.preview:Destroy(); ed.preview = nil end
		local pd = ed.poster
		if not pd then
			gui:SetAttribute("Poster", "")
			return
		end
		local a = anchorOf(pd.slot)
		local m = a and Items.Poster(pd, RoomsCfg)
		if m then
			for _, d in ipairs(m:GetDescendants()) do
				if d:IsA("BasePart") then d.CanQuery, d.CanCollide, d.CanTouch, d.CastShadow = false, false, false, false end
			end
			m.Name = "PosterPreview"
			m:PivotTo(a.WorldCFrame * CFrame.new(0, 0, -PREVIEW_OUT))
			m.Parent = previewFolder()
			ed.preview = m
		end
		gui:SetAttribute("GhostOk", posterFits(pd) == true)
		gui:SetAttribute("Poster", string.format("%d,%d,%d,%d", pd.slot, pd.w, pd.c, pd.s))
	end

	-- the camera: straight down over the room, north at the top, the floor between the top bar and the edit bar; while the
	-- poster designer is open (Task 13), level in front of its wall spot instead, the poster and WALL_MARGIN round it in that band
	local function fitCamera()
		if not ed then return end
		local cam = workspace.CurrentCamera
		local V = cam.ViewportSize
		if V.X <= 0 or V.Y <= 0 then return end
		local size = (RoomsCfg.Kinds[ed.kind] or {}).size or { 12, 12 }
		local f = (V.Y / 2) / math.tan(math.rad(cam.FieldOfView) / 2)
		local top = GuiService:GetGuiInset().Y + 12
		local bottom = math.max(top + 80, V.Y - ui.Reserved() - 12)
		local wall = ed.poster and anchorOf(ed.poster.slot)
		if wall then
			local acf = wall.WorldCFrame
			local up = ed.pivot.UpVector
			local into = (acf.LookVector - up * acf.LookVector:Dot(up)).Unit
			local PW, PH = Items.POSTER_W + 2 * WALL_MARGIN, Items.POSTER_H + 2 * WALL_MARGIN
			local d = math.max(f * PW / math.max(80, V.X - 24), f * PH / (bottom - top))
			local oyw = (top + bottom) / 2 - V.Y / 2
			local look = acf.Position + up * (oyw * d / f) -- the poster's centre shows at the free band's centre
			cam.CameraType = Enum.CameraType.Scriptable
			cam.CFrame = CFrame.lookAt(look + into * d, look, up)
			cam.Focus = CFrame.new(acf.Position)
			ed.aimed = "wall:" .. ed.poster.slot
			return
		end
		ed.aimed = "top"
		local W, D = size[1] + 1, size[2] + 1
		local h = math.max(f * W / math.max(80, V.X - 24), f * D / (bottom - top))
		local oy = (top + bottom) / 2 - V.Y / 2 -- px: the free band's centre off the screen's centre (up is negative)
		local south = ed.pivot:VectorToWorldSpace(Vector3.zAxis)
		local ground = ed.pivot.Position - south * (oy * h / f)
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = CFrame.lookAt(ground + ed.pivot.UpVector * h, ground, ed.pivot.LookVector)
		cam.Focus = CFrame.new(ground)
	end
	-- the room's parts at ceiling height go see-through on this client (the camera looks down through them)
	local function hideTop()
		local floorY = ed.pivot.Position.Y
		local items = ed.room:FindFirstChild("Items")
		for _, d in ipairs(ed.room:GetDescendants()) do
			if d:IsA("BasePart") and not (items and d:IsDescendantOf(items)) then
				local cf, s = d.CFrame, d.Size
				local halfY = (math.abs(cf.RightVector.Y) * s.X + math.abs(cf.UpVector.Y) * s.Y + math.abs(cf.LookVector.Y) * s.Z) / 2
				if d.Position.Y - halfY - floorY >= CEILING_MIN then
					ed.hidden[d] = d.LocalTransparencyModifier
					d.LocalTransparencyModifier = 1
				end
			end
		end
	end

	-- the camera follows what is picked: over the room, or (the designer) at a wall spot
	local function aim()
		local want = ed.poster and ("wall:" .. ed.poster.slot) or "top"
		if ed.aimed ~= want then fitCamera() end
	end
	local function paint()
		if not ed then return end
		local s, rv, pd = ed.sel, ed.rv, ed.poster
		if pd then
			-- 9.30 while the design can be hung; else the sentence for why not (a full room says so before HANG is pressed: a
			-- redesign of a hung spot leaves itself out of the count, so it never reads "full")
			local fitsOk, why = posterFits(pd)
			ui.Paint({ mode = "poster", word = (RoomsCfg.PosterWords or {})[pd.w] or "", color = (RoomsCfg.PosterColorNames or {})[pd.c] or "",
				style = (RoomsCfg.PosterStyleNames or {})[pd.s] or "", hung = pd.index ~= nil, ok = gui:GetAttribute("GhostOk") == true,
				hint = ed.msg or (fitsOk ~= true and RoomUI.Sentence(why)) or Copy.HintDesign })
			gui:SetAttribute("Item", ed.list[ed.browse] or "")
			gui:SetAttribute("Selected", pd.index and ("item:" .. pd.index) or ("slot:" .. pd.slot))
		else
			local id = s and s.id or ed.list[ed.browse]
			local item = id and Catalog.ById[id]
			-- 6.13, then 9.29 (Task 13) while a wall spot is free and the room has space to hang a poster in (a full room
			-- advertises no spot: the limit counts posters)
			local limit = tonumber(rv.limit)
			local full = limit ~= nil and (tonumber(rv.used) or 0) >= limit
			local none = (freeSpot() and not full) and (Copy.HintPick .. " " .. Copy.HintWall) or Copy.HintPick
			local hint = ed.msg or (s == nil and none) or (s.index and Copy.HintItem) or Copy.HintNew
			ui.Paint({ mode = s == nil and "none" or (s.index and "item" or "new"), name = item and item.name or "",
				used = tonumber(rv.used) or 0, limit = tonumber(rv.limit) or 0, canAdd = #ed.list > 0, canBrowse = #ed.list > 1,
				ok = s == nil or gui:GetAttribute("GhostOk") == true, hint = hint })
			gui:SetAttribute("Item", ed.list[ed.browse] or "")
			gui:SetAttribute("Selected", s == nil and "" or (s.index and ("item:" .. s.index) or ("new:" .. s.id)))
		end
		local rows = gui:GetAttribute("Rows")
		if rows ~= ed.rows then ed.rows = rows; fitCamera() end
	end
	-- the server's State (Room_Get's answer, or the Room remote's "state")
	local function applyView(view)
		if not ed then return end
		local rv = type(view) == "table" and type(view.rooms) == "table" and view.rooms[ed.kind] or nil
		if type(rv) ~= "table" then leave("room"); return end
		rv.items = type(rv.items) == "table" and rv.items or {}
		ed.view, ed.rv = view, rv
		ed.set = asSet(view.unlocked)
		local unbuilt = {} -- the saved floor items that don't stand (locked: Repair keeps them unbuilt)
		for i, e in ipairs(rv.items) do
			local it = type(e) == "table" and Catalog.ById[e.id] or nil
			if it and it.kind == "floor" and not isOpen(it, ed.set) then table.insert(unbuilt, i) end
		end
		ed.held = Rules.UnbuiltCells(rv.items, unbuilt, Catalog)
		local shown = ed.list[ed.browse]
		ed.list = {}
		for _, it in ipairs(Catalog.Items) do
			if it.kind == "floor" and allowed(it, ed.kind) and ed.set[it.id] then table.insert(ed.list, it.id) end
		end
		ed.browse = table.find(ed.list, shown) or math.clamp(ed.browse, 1, math.max(1, #ed.list))
		local s = ed.sel
		if s and s.index then
			local e = rv.items[s.index]
			if type(e) == "table" and e.id == s.id then dim(s.index) else ed.sel = nil; undim() end
		end
		local pd = ed.poster -- the designer's spot: a hung poster's index follows the list, a new one becomes a redesign
		if pd then
			local at = hungAt(pd.slot)
			if pd.index ~= at then
				pd.index = at
				if at then dim(at) else undim() end
			end
		end
		showUnbuilt()
		showGhost()
		showPoster()
		showSlots()
		paint()
		if ed then aim() end
	end
	-- what is picked: a floor item (s), or nil (nothing); either closes the poster designer
	local function choose(s)
		ed.sel = s
		ed.poster = nil
		ed.msg = nil
		if s and s.index then dim(s.index) else undim() end
		showGhost()
		showPoster()
		showSlots()
		paint()
		aim()
	end
	-- the poster designer opened on a design { slot, w, c, s, index? } (Task 13)
	local function design(pd)
		ed.sel = nil
		ed.poster = pd
		ed.msg = nil
		if pd.index then dim(pd.index) else undim() end
		showGhost()
		showPoster()
		showSlots()
		paint()
		aim()
	end
	local function pick(index)
		local e = ed.rv.items[index]
		local it = type(e) == "table" and Catalog.ById[e.id] or nil
		if it and it.kind == "wall" and allowed(it, ed.kind) and Rules.PosterOk(e, RoomsCfg) and anchorOf(e.slot) then
			if not (ed.poster and ed.poster.index == index) then design({ slot = e.slot, w = e.w, c = e.c, s = e.s, index = index }) end
			return
		end
		if not (it and it.kind == "floor" and isOpen(it, ed.set) and allowed(it, ed.kind)) then return end
		choose({ id = e.id, index = index, x = e.x, z = e.z, r = e.r or 0 })
	end
	-- wall spot n tapped: the poster on it picked, or the designer opened there for a new one
	local function spot(n)
		if not (type(n) == "number" and n >= 1 and n <= spots() and anchorOf(n)) then return end
		if ed.poster and ed.poster.slot == n then return end -- open on it already
		local at = hungAt(n)
		if at then pick(at); return end
		design({ slot = n, w = 1, c = 1, s = 1 })
	end
	local function moveGhost(x, z)
		if not ed.sel then return end
		ed.sel.x, ed.sel.z = x, z
		ed.msg = nil
		showGhost()
		paint()
	end
	-- the floor cell under a screen point (the floor plane, room-local y 0), as the picked item's lowest cell
	local function floorAt(pos)
		local s = ed.sel
		if not s then return end
		local ray = workspace.CurrentCamera:ScreenPointToRay(pos.X, pos.Y)
		local up = ed.pivot.UpVector
		local denom = ray.Direction:Dot(up)
		if math.abs(denom) < 1e-4 then return end
		local t = (ed.pivot.Position - ray.Origin):Dot(up) / denom
		if t <= 0 then return end
		local lp = ed.pivot:PointToObjectSpace(ray.Origin + ray.Direction * t)
		local w, d = footprint(Catalog.ById[s.id], s.r)
		moveGhost(math.floor(lp.X - w / 2 + 0.5), math.floor(lp.Z - d / 2 + 0.5))
	end
	-- a tap: on a placed item it picks it; on the floor it moves the ghost
	local function tap(pos)
		if not ed or ed.busy then return end
		if ed.poster then return end -- the designer: its own buttons only (the camera faces the wall)
		local ray = workspace.CurrentCamera:ScreenPointToRay(pos.X, pos.Y)
		local items = ed.room:FindFirstChild("Items")
		if items then
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Include
			params.FilterDescendantsInstances = { items }
			local hit = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
			local m = hit and hit.Instance
			while m and m.Parent ~= items do m = m.Parent end
			local index = m and m:GetAttribute("Index")
			if type(index) == "number" then
				if not (ed.sel and ed.sel.index == index) then pick(index) end
				return
			end
		end
		-- nothing picked: a wall spot's plate (Task 13; with a floor item picked the plates are out of the way)
		local plates = not ed.sel and ed.folder and ed.folder:FindFirstChild("PosterSlots")
		if plates then
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Include
			params.FilterDescendantsInstances = { plates }
			local hit = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
			local n = hit and hit.Instance:GetAttribute("PosterSlot")
			if type(n) == "number" then spot(n) end
			return
		end
		floorAt(pos)
	end
	local function send(action)
		if ed.busy then return end
		local my = ed
		my.busy = true
		gui:SetAttribute("LastEdit", "sending")
		local ok, res = pcall(function() return RoomEditRF:InvokeServer(action) end)
		if ed ~= my then return end -- left meanwhile
		my.busy = false
		local reason = (ok and type(res) == "table") and (res.ok == true and "ok" or tostring(res.reason)) or "error"
		if reason == "ok" then
			my.msg = nil
			choose(nil)
			local v = fetch()
			if ed ~= my then return end
			if v then applyView(v) end
		else
			my.msg = RoomUI.Sentence(reason)
			paint()
		end
		gui:SetAttribute("LastEdit", reason)
	end
	local function command(c)
		if not ed then return end
		-- "key:<KeyCode name>": that key's press through keyAction itself (R-T16 fix, M5: a test's gamepad press)
		local kn = string.match(c, "^key:(%w+)$")
		if kn then
			local okKey, kc = pcall(function() return Enum.KeyCode[kn] end)
			if okKey and kc then keyAction(ACT, Enum.UserInputState.Begin, { KeyCode = kc }) end
			return
		end
		if c == "done" then leave("done"); return end
		if c == "cancel" then choose(nil); return end
		if ed.busy then return end
		-- the poster designer (Task 13)
		local pd = ed.poster
		if c == "hang" or (c == "place" and pd) then
			if pd then send({ op = "poster", kind = ed.kind, slot = pd.slot, w = pd.w, c = pd.c, s = pd.s }) end
			return
		end
		if c == "remove" and pd then
			if pd.index then send({ op = "remove", kind = ed.kind, index = pd.index }) end
			return
		end
		local field, sign, num = string.match(c, "^(%a+):([%+%-])(%d+)$")
		if field and POSTER_KEY[field] then
			if not pd then return end
			local key = POSTER_KEY[field]
			local n = POSTER_N[key]
			if n < 1 then return end
			pd[key] = (pd[key] - 1 + (sign == "-" and -1 or 1) * tonumber(num)) % n + 1
			ed.msg = nil
			showPoster()
			paint()
			return
		end
		local sn = string.match(c, "^slot:(%d+)$")
		if sn then spot(tonumber(sn)); return end
		if pd then return end -- nothing else while designing (rotate, the floor's browse and add)
		if c == "next" or c == "prev" then
			if ed.sel or #ed.list == 0 then return end
			ed.browse = (ed.browse - 1 + (c == "next" and 1 or -1)) % #ed.list + 1
			ed.msg = nil
			paint()
			return
		end
		if c == "add" then
			local id = ed.list[ed.browse]
			if ed.sel or not id then return end
			local x, z = firstCell(id, 0)
			choose({ id = id, x = x, z = z, r = 0 })
			return
		end
		if c == "rotate" then
			if ed.sel then ed.sel.r = (ed.sel.r + 1) % 4; ed.msg = nil; showGhost(); paint() end
			return
		end
		if c == "place" then
			local s = ed.sel
			if not s then return end
			if s.index then send({ op = "move", kind = ed.kind, index = s.index, x = s.x, z = s.z, r = s.r })
			else send({ op = "place", kind = ed.kind, id = s.id, x = s.x, z = s.z, r = s.r }) end
			return
		end
		if c == "remove" then
			local s = ed.sel
			if s and s.index then send({ op = "remove", kind = ed.kind, index = s.index }) end
			return
		end
		local cx, cz = string.match(c, "^cell:(%-?%d+),(%-?%d+)$")
		if cx then moveGhost(tonumber(cx), tonumber(cz)); return end
		local pi = string.match(c, "^pick:(%d+)$")
		if pi then pick(tonumber(pi)); return end
		local tx, ty = string.match(c, "^tap:(%-?[%d%.]+),(%-?[%d%.]+)$")
		if tx then tap(Vector2.new(tonumber(tx), tonumber(ty))) end
	end
	gui:GetAttributeChangedSignal("Command"):Connect(function()
		local c = gui:GetAttribute("Command")
		if type(c) ~= "string" or c == "" then return end
		gui:SetAttribute("Command", "")
		task.spawn(command, c) -- a place or a remove waits on the server
	end)

	-- keyboard and gamepad: a cell at a time, a turn, place, remove, cancel / leave (the bar's own Command seam). R-T16 fix, M5:
	-- the D-pad moves the ghost too (prompts are off in decorate mode, so DPadDown and DPadRight press no prompt)
	local KEYS = {
		[Enum.KeyCode.W] = { 0, -1 }, [Enum.KeyCode.Up] = { 0, -1 }, [Enum.KeyCode.S] = { 0, 1 }, [Enum.KeyCode.Down] = { 0, 1 },
		[Enum.KeyCode.A] = { -1, 0 }, [Enum.KeyCode.Left] = { -1, 0 }, [Enum.KeyCode.D] = { 1, 0 }, [Enum.KeyCode.Right] = { 1, 0 },
		[Enum.KeyCode.DPadUp] = { 0, -1 }, [Enum.KeyCode.DPadDown] = { 0, 1 }, [Enum.KeyCode.DPadLeft] = { -1, 0 }, [Enum.KeyCode.DPadRight] = { 1, 0 },
	}
	keyAction = function(_, st, input)
		if st ~= Enum.UserInputState.Begin or not ed then return Enum.ContextActionResult.Pass end
		local k = input.KeyCode
		local step = KEYS[k]
		if step then
			if ed.sel and not ed.busy then moveGhost(ed.sel.x + step[1], ed.sel.z + step[2]) end
		elseif k == Enum.KeyCode.R or k == Enum.KeyCode.ButtonY then gui:SetAttribute("Command", "rotate")
		elseif k == Enum.KeyCode.Return or k == Enum.KeyCode.KeypadEnter then gui:SetAttribute("Command", "place")
		elseif k == Enum.KeyCode.Delete then gui:SetAttribute("Command", "remove")
		elseif k == Enum.KeyCode.Backspace or k == Enum.KeyCode.ButtonB then gui:SetAttribute("Command", (ed.sel or ed.poster) and "cancel" or "done")
		end
		return Enum.ContextActionResult.Sink
	end

	-- taps and drags on the room (never the ones that began on a gui)
	local held = nil
	UIS.InputBegan:Connect(function(input, processed)
		if not ed or processed then return end
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
			held = input
			tap(Vector2.new(input.Position.X, input.Position.Y))
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if not (ed and ed.sel and held and not ed.busy) then return end
		local t = input.UserInputType
		if (t == Enum.UserInputType.Touch and input == held) or (t == Enum.UserInputType.MouseMovement and held.UserInputType == Enum.UserInputType.MouseButton1) then
			floorAt(Vector2.new(input.Position.X, input.Position.Y))
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if held and (input == held or input.UserInputType == Enum.UserInputType.MouseButton1) then held = nil end
	end)

	local function enter(kind)
		if ed then return end
		local room = myRoom(kind)
		local h, r = hum(), rootPart()
		if not (room and h and h.Health > 0 and r) then return end
		-- the beat maker or a walk-in / Day One card owns the screen (R-T16 fix, I1: the card too): no decorate mode under it
		local function busyScreen()
			local why = (dawOpen() and "daw") or (cardOpen() and "card") or nil
			if why then gui:SetAttribute("Refused", why) end
			return why ~= nil
		end
		if busyScreen() then return end
		local view = fetch()
		if ed or not (view and type(view.rooms[kind]) == "table") or not room:IsDescendantOf(workspace) then return end
		-- fetch() yielded: still alive, still this character, still in your own plot (a door may have moved you meanwhile),
		-- and nothing else took the screen meanwhile
		r = rootPart()
		local slot = player:GetAttribute("PlotSlot")
		if not (r and hum() == h and h.Health > 0 and type(slot) == "number" and slot > 0 and player:GetAttribute("InPlot") == slot) then return end
		if busyScreen() then return end
		ed = { kind = kind, room = room, pivot = room:GetPivot(), at = r.Position, browse = 1, list = {}, faint = {},
			hidden = {}, dimmed = {}, guiOff = {}, anchors = {}, conns = {}, saved = { pps = PPS.Enabled, touch = GuiService.TouchControlsEnabled } }
		local my = ed
		-- the setup in one pcall (R-T10 fix 3, review minor 2): a throw anywhere in it leaves at once ("error"), so nothing is
		-- ever left off with no bar and no way out
		local okSetup, err = pcall(setup, my, h, view)
		if not okSetup then
			warn("[OK][ERR] decorate mode: " .. tostring(err))
			if ed == my then leave("error") end
		end
	end
	setup = function(my, h, view)
		local kind = my.kind
		PPS.Enabled = false
		pcall(function() GuiService.TouchControlsEnabled = false end)
		lock(my, h)
		h:Move(Vector3.zero)
		hideTop()
		gui:SetAttribute("Kind", kind)
		gui:SetAttribute("LastEdit", "")
		ui.Show(true)
		applyView(view)
		if ed ~= my then return end
		fitCamera()
		local cam = workspace.CurrentCamera
		table.insert(my.conns, RunService.Heartbeat:Connect(function()
			if not ed then return end
			local rr = rootPart()
			if not rr or flat(rr.Position - ed.at) >= MOVED then leave("moved")
			elseif not ed.room:IsDescendantOf(workspace) then leave("room") end
		end))
		table.insert(my.conns, h.Died:Connect(function() leave("died") end))
		table.insert(my.conns, player.CharacterAdded:Connect(function() leave("respawn") end))
		table.insert(my.conns, player:GetAttributeChangedSignal("InPlot"):Connect(function() leave("moved") end))
		table.insert(my.conns, cam:GetPropertyChangedSignal("ViewportSize"):Connect(fitCamera))
		-- R-T16 fix, I1: the beat maker's window showing (Day One's "Make it now", a laptop) or a walk-in / Day One card opening
		-- (OK_WalkIn's Open, which WalkInUI sets) ends decorate mode, so the two never share the screen, the prompts or ButtonB
		local daw = dawWindow()
		if daw then
			table.insert(my.conns, daw:GetPropertyChangedSignal("Visible"):Connect(function()
				if daw.Visible and ed == my then leave("daw") end
			end))
		end
		local card = cardGui()
		if card then
			table.insert(my.conns, card:GetAttributeChangedSignal("Open"):Connect(function()
				if card:GetAttribute("Open") == true and ed == my then leave("card") end
			end))
		end
		CAS:BindActionAtPriority(ACT, keyAction, false, Enum.ContextActionPriority.High.Value + 60, Enum.KeyCode.W, Enum.KeyCode.A,
			Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right, Enum.KeyCode.R,
			Enum.KeyCode.Return, Enum.KeyCode.KeypadEnter, Enum.KeyCode.Delete, Enum.KeyCode.Backspace, Enum.KeyCode.ButtonY,
			Enum.KeyCode.ButtonB, Enum.KeyCode.DPadUp, Enum.KeyCode.DPadDown, Enum.KeyCode.DPadLeft, Enum.KeyCode.DPadRight)
		gui:SetAttribute("Editing", true)
		-- either may have come up while this was setting up (nothing above yields, but a card's Open can land in between frames)
		if ed == my and dawOpen() then leave("daw") elseif ed == my and cardOpen() then leave("card") end
	end
	leave = function(why)
		local e = ed
		if not e then return end
		ed = nil
		for _, c in ipairs(e.conns) do c:Disconnect() end
		CAS:UnbindAction(ACT)
		for part, v in pairs(e.hidden) do if part.Parent then part.LocalTransparencyModifier = v end end
		for part, v in pairs(e.dimmed) do if part.Parent then part.LocalTransparencyModifier = v end end
		for g, on in pairs(e.guiOff) do if g.Parent then g.Enabled = on end end
		if e.folder then e.folder:Destroy() end
		ui.Show(false)
		local cam = workspace.CurrentCamera
		cam.CameraType = Enum.CameraType.Custom
		local h = hum()
		if h then cam.CameraSubject = h end
		unlock(e)
		-- R-T16 fix, I1: on the "daw" way out the beat maker is open, and DAWClient owns the prompts and the touch controls (it
		-- turned them off when it opened and turns them on when it closes): putting decorate mode's saved "on" back here would
		-- light the prompts under the open beat maker. Every other way out puts them back as decorate mode found them
		if why ~= "daw" then
			PPS.Enabled = e.saved.pps
			pcall(function() GuiService.TouchControlsEnabled = e.saved.touch end)
		end
		for k, v in pairs({ Editing = false, Kind = "", Item = "", Selected = "", Ghost = "", GhostOk = false, Poster = "" }) do gui:SetAttribute(k, v) end
		gui:SetAttribute("LeftBy", tostring(why))
	end

	RoomEv.OnClientEvent:Connect(function(kind, payload)
		if kind == "decorate" and type(payload) == "table" and type(payload.kind) == "string" then
			task.spawn(enter, payload.kind)
		elseif kind == "state" and ed and type(payload) == "table" then
			applyView(payload)
		end
	end)
	task.spawn(controls) -- found once, before the first press
end)

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

-- the play this client is on: its plot, Token, tier and room kind, the parts its sounds come from, and whether those are
-- the Station standing in for missing cabinets (tier 2 and 3)
local cur = { plot = 0, token = nil, tier = 1, room = "bedroom", emit = nil, emitFallback = false }
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
-- { left, right }: kept while both parts stay in Workspace, looked up again once one has gone (a speaker refit, streaming),
-- and, while the Station stands in for missing cabinets, as soon as a cabinet is there (R-T7's review M9)
local function emitters()
	local e = cur.emit
	if e and live(e[1]) and live(e[2]) then
		if not cur.emitFallback then return e end
		local room = roomModel()
		if not (room and (cabinet(room, "L") or cabinet(room, "R"))) then return e end
	end
	cur.emit, cur.emitFallback = nil, false
	local room = roomModel()
	if not room then return nil end
	local L, R
	if cur.tier >= 2 then L, R = cabinet(room, "L"), cabinet(room, "R") end
	local fallback = false
	if not (L or R) then
		local st = stationOf(room)
		L, R = st, st
		fallback = cur.tier >= 2
	end
	if not (L or R) then return nil end
	cur.emit, cur.emitFallback = { L or R, R or L }, fallback
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
