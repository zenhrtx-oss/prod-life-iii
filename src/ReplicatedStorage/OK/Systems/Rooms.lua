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
--   R-T16 fix, I5 (the release race): releaseSlot marks the owner's entry `releasing` before anything else, and from then
--   on the plot's doors move nobody (enterPlot, goRoom, exitRoom and leavePlot refuse; a guest pressing Enter is told copy
--   1.19). A move already on its way (a far plot's stream wait, the 0.3 s unseat) asks a `still()` check after each yield
--   and before every PivotTo, and gives up when the plot is going (Enter's guest is told 1.19 then). Last, with no yield
--   from there to the plot's Destroy, a final sweep moves anyone still standing in the plot (by position, before the slot
--   tables are cleared) to HallSpawn, unseated, and tells a guest not yet told.
-- * The wake-up: your first character goes to your bedroom's Spawn; a respawn after a death inside your own plot does
--   the same. Under the test hold (Studio, ReplicatedStorage.OK has WalkInsPaused, true or false: WalkIns' held()) neither
--   moves anyone, so the existing suite keeps starting at the hub spawn; tests drive them through the hook. Without the
--   building (Workspace.OK_Rooms' Hall and RoomsDoor: the only way out of a plot) neither moves anyone either.
-- * The throwaway-test seam (Task 15, build/room_test.lua; Studio or not, since the user tours a private publish): while
--   Workspace.RoomTest (the 12-plot phone test's root Folder, whose plots stand on the real slot origins) exists (R-T16
--   fix, I2: a Folder carrying the Throwaway attribute, as room_test.lua makes it; a player's character named RoomTest, a
--   Model, or anything else of that name never counts), Rooms
--   claims no slot (claim answers nil and PlotSlot reads 0; the hook's Fill claims none and answers 0), builds no plot, and moves no one on join or respawn (the
--   wake-up and the respawn rule hold, forced ones too, and nobody gets the "building is full" toast): everyone stays at
--   the hub spawn and the test's ROOM TOUR moves them. Nothing else changes; with no RoomTest (the whole suite, and every
--   real server) it does nothing. build/room_test_remove.lua deletes RoomTest, and this seam goes with the test.
-- * Untagged prompts (every one below) are hooked by onPrompt: a press from out of reach does nothing, and (R-T16 fix, M1) a
--   player's press of the same prompt within PRESS_DEBOUNCE (0.25 s) of their last one is ignored: a weak-keyed table per
--   prompt instance (many prompts share a name: 12 EnterPrompts, a RoomPrompt per door), so the closet's whole-profile
--   payload, Decorate's push and a "friends" door's check can't be run once a frame. busy[] still guards the moves.
-- * Doors (untagged prompts, hooked here; each press is checked for reach, as InteractionService does): the corridor's
--   RoomsDoor -> the hall's HallSpawn; the hall's door k -> plot k's landing (RoomRules.CanEnter on the owner's saved
--   door mode, Task 14 below; the owner always enters; a refusal toasts copy 1.16 / 1.17); the landing's
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
--   (1.9, the owner's door mode, its words in the mode's colour: Task 14) and "Enter" / "{player}'s door" (1.10, 1.11)
--   when owned. "Go to your room" / "Your door" (1.12, 1.13) are per viewer: a client line, not built yet.
-- * API: PlotOf(p), Owner(k), BoxesFor(p) (your rooms' world boxes, RoomRules.Box, each with .kind), PlaceOf(p) ("hub",
--   { slot, kind } with kind a room kind or "landing", or nil), Anchor(p, kind, name) -> CFrame?, Station(p, kind?) ->
--   BasePart?, Edit(p, action) and State(p) (Task 9), the event Rebuilt (player, k).
-- * Studio-only hook ServerScriptService.OK._StudioRoomsHook (Studio and running): hook:Invoke(cmd, userId, a, b). Plot,
--   Reset (the home back to its defaults, claim if needed and rebuild; Task 14: the friend check's stub and cache go too), WakeUp,
--   Enter(slot, asFriend) (true / false answers the friend check, nil runs it), Exit(kind), GoIn(kind), Leave, HubDoor, RoomsDoor
--   (each the real handler of its prompt), Respawn (LoadCharacter, then the respawn rule past the hold), Release, Claim
--   (nil when no slot is free; the full toast is the wake-up's), Fill(n) / Unfill (stand-in plots for fake owners), Anchor(kind, name),
--   InPlot, PlaceOf, Home (a copy of the saved home, repaired), SetHome(home) (a copy, through Repair, saved; returns what it
--   kept; the plot's Items folders follow it, the plot itself isn't rebuilt), Guest(slot) (a stand-in Model in that plot, moved like a guest on Release), Station(kind?),
--   RunStation(kind?) (InteractionService._RunHandler("Station") on it: { acted, toast }), Sent (the toasts sent this
--   player since the last read), OnOpen(cmd, a) (the next time this player's beat maker opens at a laptop in a plot,
--   run hook command cmd(a) 2 s later: a client test's server-side move; disarmed after 30 s), OnDecorate(cmd, a) (R-T16
--   fix, I1: the next time this player's decorate push goes out, run cmd(a) at their second Room_Get after it, the client
--   test's knock once it reads Editing; disarmed after 30 s; see armDecorate). Task 6: MayUse(inst)
--   (InteractionService.MayUse(player, inst): ok, ownerName?), StationOf (DAW.StationOf: { inst, room }), Run(kind, inst)
--   (InteractionService._RunHandler(kind) on inst: { acted, toast }; the RackSpot's GearRack, say).
-- * Placing your things (Task 9). Each room Model holds an `Items` Folder (attribute RoomItemsFolder; made by build(k) for every
--   room, before the plot goes into Workspace, so it streams with the Atomic room) with one RoomItems.Build model per built
--   floor item of the saved home (Modules/RoomEdit.Fit: Item_<index>, attributes ItemId, Index, Sig; placed at the footprint's
--   centre, turned r quarter turns). Edit(p, action) and State(p) are the entry points, bound to the remotes Room_Edit and
--   Room_Get in Init (the remotes are made by build/19_rooms.lua; their handlers are the local roomEdit / roomGet, which
--   pcall them); the token bucket, the action check and the Fits step live in Modules/RoomEdit, see M.Edit. After a SetHome,
--   or a change of your Gear attribute (an item saved while its gear read as unowned stands once the gear is, and goes
--   when it isn't), your plot's Items follow your saved home again; the plot is not rebuilt and Rebuilt does not fire.
--   Studio hook: Edit(action) and State (the remotes' own handlers, for the hook's player).
--   Task 9's review, folded into Task 10: a refit that throws after a saved edit is reported and the edit still answers ok
--   (M2); an unusable profile (a failed load, a detached one) answers "error", not "away" (M3).
-- * Decorate mode (Task 10; StarterPlayerScripts/OK/RoomClient and Modules/RoomUI are the client). Every room of a plot
--   gets an untagged DecoratePrompt ("Decorate" / "Your room", copy 6.1, 6.2) on its door part beside the ExitPrompt, so
--   near Entrance: R / DPadDown (the door's own prompt is E), its UI stacked Build.RACK_UI_GAP px above the ExitPrompt's
--   (they share the door part, as the rack's prompt sits over the laptop's). A fake owner's rooms get one too; every client
--   turns off each DecoratePrompt it doesn't own (RoomClient), so only the owner sees theirs. A press by the plot's owner
--   (within reach, as every Rooms prompt) sends the Room remote's "decorate" { kind } to them, and their client goes into
--   decorate mode; anyone else's press does nothing. The Room remote also carries "state" (State(p)'s answer) to the owner
--   whenever their rooms change: after a saved Edit, after their Items follow a SetHome or a Gear change, and after every
--   (re)build of their plot. Room_Get (M1 of Task 9's review) answers from a per-player cache of State, VIEW_SECONDS old at
--   most, dropped whenever the rooms change (a saved Edit, SetHome, Reset, a Gear change's refit, a (re)build, a Decorate
--   press); only `inside` is read fresh on every call (it moves as you walk). Studio hook: Decorate(kind) (the prompt's
--   handler, for the plot the player stands in), Pushed (the Room remote's messages to the player since the last read:
--   { kind, payload }), and Counts' `views` (Room_Get's fresh computes since the last read).
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
-- * Your walls show your career (Task 11). Each room Model holds a `Plaques` Folder (attribute RoomPlaques; R-T16 fix, M2:
--   only a Folder with that mark is reused and emptied, and an import's own child named Plaques is left alone) with one
--   RoomItems.Plaque model per hung plaque, RoomPlaque_<n> on the room's Plaque_<n> Attachment (found by name like every
--   anchor: the bedroom's are the asset's own Sockets, the home and real stand-ins' come from Config; the models are named
--   RoomPlaque_<n> so a recursive FindFirstChild("Plaque_<n>") can never meet one). One list for the whole plot,
--   RoomRules.Plaques(prof.life.disco, prof.plaques, the slots of the rooms you own), hangs bedroom first, then home, then real:
--   the hits newest first, then the placements and track ones, then the weekly singles (a bedroom's three slots hold your best
--   three; unlocking a room only adds its slots after them, so nothing already hung moves). The words: a disco row is
--   LifeRules.DiscoText with Career.KnownNames(p) (the very names Career.State's life uses; copy 7.1-7.3, no new words) and a
--   weekly row is copy 7.4, Build.Copy.WeeklyPlate with the title upper-cased; a row that reads nothing (a weekly with no
--   title) is dropped before the list is cut, so it leaves no gap. build(k) hangs them for the real owner before the plot goes
--   into Workspace, so a rebuild (a gate, a Release and Claim) shows them again; and your Placements, Hits and Plaques
--   attributes (Career.Publish sets the first two, Systems/Dailies the third) rebuild the standing plot's plaques once per
--   change (task.defer: production adds the stat, which sets the attribute, before it pushes the disco row, so the read comes
--   after both). A backstop in the 1 s presence loop compares a signature of the two lists (their lengths and newest rows) with
--   what the last hang read and queues the same rebuild when they differ: it catches a disco row that lands after the attribute's
--   read, a row with no stat move, and a weekly plaque at Dailies' 52 cap, where the attribute can't move. Plaques are not items: they sit outside Items, outside the limit, and write no part of prof.career.home, so
--   no forgetView is needed. Studio hook: SetWeekly(list) (replaces prof.plaques, sets the Plaques attribute: a test's seam).
-- * The home studio's closet and booth (Task 12). A placed `closet` (Data/RoomCatalog: home and real only, one a room) is an
--   item like any other, built and kept by RoomEdit.Fit; after every Fit of a room (a plot's build, a saved Edit, a SetHome,
--   a Gear change: the same fitRoom) each closet model in its Items is dressed, in a pcall (a throw is reported and never
--   costs the plot): it gets an untagged ClosetPrompt ("Open closet" / "Your closet", copy 8.1, 8.2, C / DPadRight: its own keys, so a closet
--   beside the desk never takes the laptop's E / ButtonX under OnePerButton) on its Body
--   when it has none (a kept model keeps its prompt and its one connection; a moved or new closet is a new model), and
--   RoomItems.Hangers hangs one one-part hanger per fit you own (Config.Gear kind "fit", read through the Gear system; a
--   failed read counts as not owned), each in its colour (Modules/Fits' Colors), the first RoomRules.HangerCount of them
--   in Config.Gear order (fix 1: as many as the closet's own parts leave of Config.Rooms.ItemParts, so a closet never
--   passes its part budget; the panel still lists every fit), whenever the closet's Hangers attribute differs from that
--   set: so your Gear attribute's listener (syncItems) rehangs them. A press (within reach, as every Rooms
--   prompt) by the room's owner (the room Model's OwnerId, as InteractionService.MayUse reads it) sends InteractionEvent
--   OpenPanel { tab = "Gear", closet = true, gear = Gear.State(p), source = the closet's Body, profile } (PanelUI's closet
--   mode; the source closes the panel past Config.Interaction.PanelCloseDistance, as the rack's); anyone else gets the toast
--   "{player}'s closet. only they can use it." (copy 8.6, the owner's name cut as every Rooms toast). The closet writes no
--   part of prof.career.home (placing it is Edit's), so it needs no forgetView. Booth(inst) -> { spot, cam } (the
--   WorldCFrames of the BoothSpot and BoothCam Attachments of the room `inst` is in, found by name like every anchor: an
--   import's own, else Config's through the room's pivot) for a room whose kind has a booth (home, real); false for a room
--   without one (the bedroom; a booth room missing either anchor is reported and answers false too); nil outside every room
--   (the hub). Systems/DAW puts it on the OpenDAW payload; DAWClient plays the listen-back there. Studio hook: Closet(kind)
--   (the prompt's handler for the closet in room `kind`, default home, of the plot the player stands in, else their own:
--   { acted, toast?, payload? }, nil with no closet there) and Booth(inst).
-- * Posters you design (Task 13). A poster is a wall item of the saved home, { id = "poster", slot, w, c, s } (a word, a colour
--   and a style from Config.Rooms' PosterWords, PosterColors and PosterStyles: no typed text, no images), hung in one of a home
--   or real studio's Poster_1..n wall spots. Edit's op "poster" { op, kind, slot, w, c, s } hangs one, or redesigns the one
--   already on that spot (RoomEdit.Apply: RoomRules.Fits' "room", "limit" (posters count), "design" and "slot"), through the
--   same path as every edit: the token bucket, "away" / "owner", the save, forgetView and pushState; "remove" takes one down
--   by its index. The room's Items folder shows it (RoomEdit.Fit with Config.Rooms: a RoomItems.Poster model, Item_<index>,
--   on the spot's Poster_<slot> Attachment, flush on the wall facing in), so every path that fits a room (a build, an Edit, a
--   SetHome, a Gear change) hangs posters too. The client's decorate mode is the designer (Modules/RoomUI, OK/RoomClient).
-- * Door modes (Task 14). prof.career.home.door is "friends" by default (Config.Rooms.DoorDefault; RoomRules.Repair keeps a
--   valid one). The hall's door k reads the owner's saved mode on every press (doorMode: state(), the one read path; a fake
--   owner from the hook's Fill has the default unless the hook's Door set one) and decides with RoomRules.CanEnter: the
--   owner always enters, "open" lets anyone in, "locked" nobody else (copy 1.16), "friends" only a friend (copy 1.17 for
--   the rest). Only "friends" asks the friend check (friendAnswer): Player:IsFriendsWith(ownerId) in a pcall, in its own
--   thread, and a press waits for it at most FRIEND_SECONDS; an error, a non-boolean or a timeout counts as not a friend.
--   A real answer (true or false) is cached, per (guest, owner) for the session, whenever it comes, even after the presses
--   waiting on it timed out (R-T14 fix 1, I2: a friend whose check is always slow gets in on a later press); an error or a
--   timeout's not-a-friend is never cached, so the next press asks again. A press while the same guest's check for the
--   same owner is in flight shares that check (no second call) and still answers within FRIEND_SECONDS of its own press;
--   a check in flight for more than FRIEND_DEAD seconds is dead, and the next press starts a fresh one (fix 1, M4; the dead
--   one's late answer may fill an empty cache entry but never replaces the fresh one's: fix 2). After a
--   check that waited, the mode is read again (fix 1, M1: a door locked meanwhile refuses with copy 1.16), and an owner who
--   left meanwhile gets the press copy 1.19 (fix 1, M2). Every press gets the toast or the
--   move (busy[] guards the move only). A fake owner's made-up id never reaches IsFriendsWith: with no stub it is nobody's
--   friend. The owner's own DoorPrompt ("Door: {MODE}" / "Who can come in", copy 10.4, 10.5; F / ButtonY, since the
--   LeavePrompt on the same FrontDoor part has E; stacked Build.RACK_UI_GAP px above it) is untagged, on the landing's
--   FrontDoor (so pressed from inside), stamped with the plot's OwnerId: RoomClient turns off every DoorPrompt this player
--   doesn't own, and the handler (cycleDoor) does nothing for anyone but the plot's owner, nor for a press within
--   DOOR_COOLDOWN of the owner's last cycle (fix 1, M3: no toast, no write, no push). A press moves the mode on one
--   (RoomRules.NextDoorMode over Config.Rooms.DoorModes: friends -> locked -> open -> friends), saves it (MarkDirty), drops
--   Room_Get's cache (forgetView), shows it on the hall plate (its words in PLATE_COLORS' colour) and the prompt, tells the
--   owner (copy 10.6 - 10.8) and pushes the new State. Every state() read of an owner's home also brings the plate and the
--   prompt up to the saved mode (a SetHome, a Reset, a Career Reset that wiped the home). A visit lasts only while the
--   owner is online: their leaving runs releaseSlot, which moves everyone in the plot to the hall first ("{player} left the
--   server", copy 1.19). Studio hook: Door() (the prompt's handler for the player's own slot: the new mode, false with no
--   slot), Door(slot, mode) (a fake owner's mode, for tests: the mode, false for anything else), FriendCheck(spec | nil)
--   (fix 1, I1: a named stub built here, server-side, in place of IsFriendsWith: { kind = "answer", value = bool },
--   { kind = "error" } or { kind = "sleep", seconds = n, value = bool }; nil puts the real check back; both clear the cache;
--   answers "stub", "real", or false for anything else, changing nothing), FriendCalls (a copy of the current stub's own
--   counter { calls, done }: calls made, calls that returned; { calls = 0, done = 0 } with no stub).
local RS, Players = game:GetService("ReplicatedStorage"), game:GetService("Players")
local RunService = game:GetService("RunService")
local Config = require(RS.OK.Config)
local Rules = require(RS.OK.Modules.RoomRules)
local Build = require(RS.OK.Modules.RoomBuild)
local WalkInRules = require(RS.OK.Modules.WalkInRules)
local LifeRules = require(RS.OK.Modules.LifeRules)
local Catalog = require(RS.OK.Data.RoomCatalog)
local Items = require(RS.OK.Modules.RoomItems)
local Edit = require(RS.OK.Modules.RoomEdit)
local RoomScope = require(RS.OK.Modules.RoomScope)
local Fits = require(RS.OK.Modules.Fits)
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
local plaqueConns = {} -- [player] = { the connections on their Placements, Hits and Plaques attributes } (Task 11)
local plaqueDirty = {} -- [player] = true while a plaque rebuild is already queued, so one change burst rebuilds once
local plaqueSig = {}   -- [player] = plaqueSignature of the lists their standing plot's plaques were last hung from
local lastPlay = {}   -- [player] = os.clock() of their last room play that went on (Config.Rooms.PlayCooldown)
local testGuests = {} -- [k] = { Model } (the hook's Guest)
local sent = {}       -- Studio: [userId] = { toast text }
local armed = {}      -- Studio: [player] = the hook's OnOpen entry
local decoArmed = {}  -- Studio: [player] = the hook's OnDecorate entry { cmd, a, pushed, gets } (R-T16 fix, I1's test seam)
local counts = {}     -- Studio: [userId] = { played = n, tried = n, rebuilt = n, views = n } since the hook's last Counts
local pushed = {}     -- Studio: [userId] = { { kind, payload } } the Room remote sent the player since the hook's last Pushed
local views = setmetatable({}, { __mode = "k" })   -- [player] = { t = os.clock(), v = State's answer } (Room_Get's cache)
local viewGen = setmetatable({}, { __mode = "k" }) -- [player] = bumped by every drop of that cache
local VIEW_SECONDS = 2 -- Room_Get's cache lives at most this long (a Life unlock, a first or a fame tier, drops nothing)
local template, plotsFolder, hall, roomsDoor, roomEvent
local dispatch -- the hook's command runner (OnOpen runs one later)
local doorMode, cycleDoor -- Task 14: an owner's saved door mode, and the DoorPrompt's handler (both with the saved home, below)
local plateFree = {}   -- [k] = hall plate k's own text colour (build/19_rooms.lua's), noted before its first colouring
local friendCache = {} -- [guest Player] = { [ownerId] = true | false }: the friend check's real answers, for the session
local friendAsks = {}  -- [guest Player] = { [ownerId] = ask }: the check in flight, shared by that guest's presses
local friendStub       -- Studio: the hook's FriendCheck(spec): a closure built in dispatch, standing in for Player:IsFriendsWith
local friendCalls      -- Studio: that stub's own counter { calls, done } (the hook's FriendCalls reads a copy)
local lastDoor = {}    -- [owner Player] = os.clock() of their last door cycle (DOOR_COOLDOWN)
local friendGen = 0    -- bumped by every clear of the cache: an answer to an ask from before it is never cached

local function report(msg) warn("[OK][ERR] rooms: " .. tostring(msg)) end
-- the test hold, as Systems/WalkIns' held(): Studio only, so a stray attribute in a published place never holds anyone
local function held() return RunService:IsStudio() and RS.OK:GetAttribute("WalkInsPaused") ~= nil end
-- the throwaway-test seam (see the header): the 12-plot phone test stands on the slots' origins. Only room_test.lua's own
-- root counts, a Folder with the Throwaway attribute (R-T16 fix, I2): a player named RoomTest puts a character Model of
-- that name in Workspace, and it must never hold every joiner's slot
local function roomTest()
	local t = workspace:FindFirstChild("RoomTest")
	return t ~= nil and t:IsA("Folder") and t:GetAttribute("Throwaway") ~= nil
end

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
-- again only when the root is still where it stood before (never when the player has gone somewhere else since).
-- still (optional; R-T16 fix, I5): asked after each yield and before every PivotTo. When it answers false the target is
-- going (its plot is being released): no move, and teleport answers false
local function teleport(p, target, still)
	local c = p.Character
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	if not (target and c and hum and hum.Health > 0 and c:FindFirstChild("HumanoidRootPart")) then return false end
	pcall(function() p:RequestStreamAroundAsync(target.Position, 10) end)
	if still and not still() then return false end
	if hum.Sit or hum.SeatPart then
		local seat = hum.SeatPart
		local weld = seat and seat:FindFirstChild("SeatWeld")
		hum.Sit = false
		if weld then weld:Destroy() end
		task.wait(0.3)
	end
	local r = c:FindFirstChild("HumanoidRootPart")
	if p.Character ~= c or not c.Parent or not r then return false end
	if still and not still() then return false end
	local from = r.Position
	local dest = target + Vector3.new(0, 3, 0)
	c:PivotTo(dest)
	task.wait(0.25)
	r = c:FindFirstChild("HumanoidRootPart")
	if r and p.Character == c and (r.Position - dest.Position).Magnitude > 8 and (r.Position - from).Magnitude < 8 and (still == nil or still()) then
		c:PivotTo(dest)
	end
	presence(p)
	return true
end
-- one move at a time per player; still: teleport's
local function move(p, target, door, still)
	if not target or busy[p] then return false end
	busy[p] = true
	playDoor(door)
	local ok, res = pcall(teleport, p, target, still)
	busy[p] = nil
	if not ok then report("move: " .. tostring(res)); return false end
	return res
end
-- is plot k still o's and standing, and not being released? (a move into it, or around it, goes on only while it is)
local function plotStill(k, o) return owners[k] == o and plots[k] ~= nil and not o.releasing end

-- your door (Task 14; see the header) ----------------------------------------------------------------------------------
local DOOR_ACTION, DOOR_OBJECT = "Door: {MODE}", "Who can come in" -- copy 10.4, 10.5 ({MODE}: Build.Copy.Modes, 10.1 - 10.3)
local DOOR_TOAST = { -- to the owner after a press, by the new mode: copy 10.6 - 10.8
	open = "door open. anyone can come in.",
	friends = "friends only. your friends can come in.",
	locked = "door locked. only you can come in.",
}
-- the DoorPrompt's own key pair (preflight m4): the LeavePrompt on the same FrontDoor part has E / ButtonX, and under
-- OnePerButton only one prompt a key shows. F / ButtonY is the rack's, which stands by a laptop inside a room, never in
-- reach of the landing's front door (the bedroom's rack is about 21 studs from it)
local DOOR_KEY, DOOR_PAD = Enum.KeyCode.F, Enum.KeyCode.ButtonY
-- the hall plate's words, by the owner's mode (a free plate keeps its own colour, plateFree)
local PLATE_COLORS = {
	open = Color3.fromRGB(90, 200, 120),
	friends = Color3.fromRGB(240, 190, 70),
	locked = Color3.fromRGB(230, 80, 80),
}
local FRIEND_SECONDS = 2 -- a press waits at most this long for the friend check (copy 1.17; Review Focus 4)
local FRIEND_DEAD = 10   -- a check in flight longer than this is dead: the next press starts a fresh one (R-T14 fix 1, M4)
local DOOR_COOLDOWN = 0.25 -- an owner's DoorPrompt press this soon after their last cycle is ignored (fix 1, M3)

-- the friend check: is `guest` a friend of owner `o`? Returns the answer and whether this press waited for it. A cached
-- real answer at once; else the guest's check for that owner in flight (one call per (guest, owner) at a time, in its own
-- thread: Player:IsFriendsWith, or the hook's stub; one older than FRIEND_DEAD is left to finish on its own and a fresh one
-- starts), waited for at most FRIEND_SECONDS from this press. An error, a non-boolean or a timeout reads as not a friend
-- and is never cached; a real answer is cached whenever it comes (fix 1, I2: after the presses waiting on it timed out
-- too), unless a clear came since (friendGen) or the guest has gone. A dead check superseded by a fresher one (FRIEND_DEAD)
-- may still fill an empty cache entry when it returns, but never replaces one (R-T14 fix 2: the fresher ask's answer
-- stands), and never unlinks the fresher ask. A fake owner (the hook's Fill: a made-up id) with no stub is nobody's
-- friend, and IsFriendsWith never sees the id
local function friendAnswer(guest, o)
	local c = friendCache[guest]
	if c and c[o.id] ~= nil then return c[o.id], false end
	if o.fake and not friendStub then return false, false end
	local asks = friendAsks[guest]
	if not asks then asks = {}; friendAsks[guest] = asks end
	local ask = asks[o.id]
	if ask and os.clock() - ask.t0 > FRIEND_DEAD then ask = nil end -- dead: its thread may still finish (and cache)
	if not ask then
		ask = { done = false, value = false, t0 = os.clock() }
		asks[o.id] = ask
		local gen, stub, ownerId = friendGen, friendStub, o.id
		task.spawn(function()
			local ok, res
			if stub then ok, res = pcall(stub, guest, ownerId)
			else ok, res = pcall(function() return guest:IsFriendsWith(ownerId) end) end
			local real = ok and type(res) == "boolean"
			ask.value = real and res or false
			ask.done = true
			local current = asks[ownerId] == ask -- false once a fresher ask superseded this dead one (FRIEND_DEAD)
			if current then asks[ownerId] = nil end
			if real and gen == friendGen and guest.Parent then
				local cc = friendCache[guest]
				if not cc then cc = {}; friendCache[guest] = cc end
				if current or cc[ownerId] == nil then cc[ownerId] = res end -- a superseded answer never replaces a newer one
			end
		end)
	end
	local t1, waited = os.clock(), false
	while not ask.done and os.clock() - t1 < FRIEND_SECONDS do waited = true; task.wait(0.05) end
	return ask.done and ask.value == true, waited
end
-- the cache and the checks in flight go (the hook's FriendCheck and Reset); a check still running finishes, uncached
local function clearFriends()
	friendGen += 1
	table.clear(friendCache)
	table.clear(friendAsks)
end

-- the handlers (each prompt's, and the hook's) ---------------------------------------------------------------------------
-- the hall's door k: onto plot k's landing, if the door lets you in. The owner always enters; anyone else meets the owner's
-- saved door mode (doorMode). asFriend true or false (the hook's) answers the friend check; nil (the EnterPrompt) runs it,
-- and only a "friends" door ever does. A refusal toasts copy 1.16 (locked) or 1.17 (friends only). A press that waited for
-- the check reads the mode again (fix 1, M1: a door locked meanwhile refuses with 1.16); one whose owner left meanwhile
-- (or whose slot moved on) is told copy 1.19 (fix 1, M2), so no press goes unanswered. R-T16 fix, I5: a plot being
-- released (o.releasing) lets nobody in (a guest is told 1.19), and the move itself gives up when the release starts
-- while it streams or unseats (plotStill after each yield; the guest is told 1.19 then too)
local function enterPlot(p, k, asFriend)
	k = tonumber(k)
	local o = k and owners[k]
	if not (o and plots[k]) then return false end
	local guest = o.id ~= p.UserId
	local function still() return plotStill(k, o) end
	local function gone()
		if still() then return false end
		if guest then toast(p, fill(Copy.OwnerLeft, { player = short(o.name) })) end
		return true
	end
	if gone() then return false end
	if guest then
		local mode = doorMode(o) -- the saved home.door (the owner's profile is loaded once their plot stands)
		local friend, waited = asFriend, false
		if mode == "friends" and friend == nil then friend, waited = friendAnswer(p, o) end -- waits FRIEND_SECONDS at most
		if waited then
			if gone() then return false end
			mode = doorMode(o) -- the owner may have cycled the door while the check ran
		end
		if not Rules.CanEnter(mode, false, friend == true) then
			toast(p, fill(mode == "locked" and Copy.Locked or Copy.FriendsOnly, { player = short(o.name) }))
			return false
		end
		if gone() then return false end -- a read of the saved mode can wait for the profile too
	end
	if move(p, landingInside(k), hallDoor(k), still) then return true end
	gone() -- the release began while the move streamed or unseated: no move, and a guest is told why
	return false
end
-- the landing's door for `kind`: into that room, at its Spawn (never while the plot is being released, I5)
local function goRoom(p, k, kind)
	local o = owners[k]
	if not (o and plotStill(k, o)) then return false end
	local door = landingOf(k) and landingOf(k):FindFirstChild("Door_" .. tostring(kind))
	return move(p, roomSpawn(k, kind), door, function() return plotStill(k, o) end)
end
-- a room's ExitPrompt: onto the landing outside that room's door (never while the plot is being released, I5)
local function exitRoom(p, k, kind)
	local o = owners[k]
	if not (o and plotStill(k, o)) then return false end
	local room = roomOf(k, kind)
	return move(p, landingOut(k, kind), room and Build.DoorOf(room), function() return plotStill(k, o) end)
end
-- the landing's LeavePrompt: into the hall, in front of door k (refused while the plot is being released, I5: the release
-- moves everyone in it to the hall itself)
local function leavePlot(p, k)
	local o = owners[k]
	if o and o.releasing then return false end
	local l = landingOf(k)
	return move(p, hallFront(k), l and l:FindFirstChild("FrontDoor"))
end
-- the hall's HubDoor: back to the studio's corridor
local function toCorridor(p) return move(p, corridor(), hall and hall:FindFirstChild("HubDoor")) end
-- the corridor's RoomsDoor: into the hall
local function toHall(p) return move(p, hallSpawn(), roomsDoor) end

-- decorate mode (Task 10) ----------------------------------------------------------------------------------------------
local DECORATE_ACTION, DECORATE_OBJECT = "Decorate", "Your room" -- copy 6.1, 6.2
-- a room's DecoratePrompt on its door part (see the header); nil for a room with no door part
local function addDecorate(room)
	local door = Build.DoorOf(room)
	if not door then return nil end
	local have = door:FindFirstChild("DecoratePrompt")
	if have then return have end
	local pp = Build.Prompt(door, "DecoratePrompt", DECORATE_ACTION, DECORATE_OBJECT)
	pp.KeyboardKeyCode = Enum.KeyCode.R; pp.GamepadKeyCode = Enum.KeyCode.DPadDown
	local exit = door:FindFirstChild("ExitPrompt")
	local base = (exit and exit:IsA("ProximityPrompt")) and exit.UIOffset or Vector2.zero
	pp.UIOffset = base + Vector2.new(0, -Build.RACK_UI_GAP)
	return pp
end
-- the Room remote to p: "decorate" { kind } or "state" (State's answer); logged in Studio for the hook's Pushed
local function push(p, kind, payload)
	if RunService:IsStudio() then
		local log = pushed[p.UserId] or {}
		pushed[p.UserId] = log
		table.insert(log, { kind = kind, payload = payload })
		while #log > 40 do table.remove(log, 1) end
	end
	if not (roomEvent and p.Parent) then return false end
	local ok, err = pcall(function() roomEvent:FireClient(p, kind, payload) end)
	if not ok then report("Room " .. tostring(kind) .. ": " .. tostring(err)) end
	return ok
end
-- the kind of the room of your own plot you stand in (nil on the landing, in another plot or outside): State's `inside`
local function insideOf(p)
	local place = M.PlaceOf(p)
	if type(place) == "table" and place.slot ~= nil and place.slot == slotOf[p] and place.kind ~= "landing" then return place.kind end
	return nil
end
-- Room_Get's cache (Task 9's review M1): State's answer for p, from the cache while it is under VIEW_SECONDS old and nothing
-- has dropped it (fresh = true always computes); `inside` is read now either way. Returns the view and whether it was cached.
-- FOR EVERY FUTURE WRITER of prof.career.home (R-T10 fix 3, review minor 8; Task 12's closet, Task 13's posters, Task 14's
-- door mode): call forgetView(p) after the write, so Room_Get can't answer the old home for up to VIEW_SECONDS, and
-- pushState(p) when the owner's open edit bar should see it (Edit, SetHome, Reset, syncItems and build do both today).
-- A change Rooms is never told of drops nothing and pushes nothing: a Life-only unlock (a first, a fame tier) reaches
-- Room_Get within VIEW_SECONDS, but an edit bar already open never hears of it (no push) until its next Room_Get (after an
-- edit) or the next push (any change above, or decorate mode entered again).
local function forgetView(p) views[p] = nil; viewGen[p] = (viewGen[p] or 0) + 1 end
local function viewFor(p, fresh)
	local c = views[p]
	if not fresh and c and os.clock() - c.t < VIEW_SECONDS then
		local v = table.clone(c.v)
		v.inside = insideOf(p)
		return v, true
	end
	local gen = viewGen[p]
	local v = M.State(p) -- may wait for the profile: a drop meanwhile keeps this answer out of the cache
	if viewGen[p] == gen then views[p] = { t = os.clock(), v = v } end
	return v, false
end
-- the owner's rooms changed: the cache goes and their client gets the new State (never throws)
local function pushState(p)
	if not (p and p.Parent) then return end
	forgetView(p)
	local ok, err = pcall(function() push(p, "state", (viewFor(p, true))) end)
	if not ok then report("Room state: " .. tostring(err)) end
end
-- a room's DecoratePrompt pressed (or the hook's Decorate): plot k's owner goes into decorate mode for that room on their
-- client; anyone else's press does nothing (their client never shows the prompt)
local function decorate(p, k, kind)
	if slotOf[p] == nil or slotOf[p] ~= k or not roomOf(k, kind) then return false end
	forgetView(p) -- the client asks Room_Get next: a fresh answer
	local pushedOk = push(p, "decorate", { kind = kind })
	local d = decoArmed[p] -- Studio: the hook's OnDecorate (R-T16 fix, I1's test seam): its push has gone out
	-- (round 2, N3: the Room_Get count starts again at every push, so only the knock after the last push fires it, never a
	-- second press's own fetch)
	if pushedOk and d then d.pushed = true; d.gets = 0 end
	return pushedOk
end

-- untagged prompts: a press from out of reach does nothing; a throw is reported, never a bare stack
local function near(p, part)
	local r = rootOf(p)
	return r ~= nil and part ~= nil and (r.Position - part.Position).Magnitude <= Config.Interaction.MaxDistance + 8
end
-- R-T16 fix, M1: a player's press of this very prompt within PRESS_DEBOUNCE of their last one does nothing (keyed by the
-- prompt instance through its own closure's table, never by name: 12 EnterPrompts and a RoomPrompt per door share names)
local PRESS_DEBOUNCE = 0.25
local function onPrompt(part, name, fn)
	local pp = part and part:FindFirstChild(name)
	if not (pp and pp:IsA("ProximityPrompt")) then return end
	local last = setmetatable({}, { __mode = "k" }) -- [player] = os.clock() of their last press of this prompt
	pp.Triggered:Connect(function(p)
		if not near(p, part) then return end
		local now = os.clock()
		if last[p] and now - last[p] < PRESS_DEBOUNCE then return end
		last[p] = now
		local ok, err = pcall(fn, p)
		if not ok then report(name .. ": " .. tostring(err)) end
	end)
end
local function hookPlot(plot, k)
	local landing = plot:FindFirstChild("Landing")
	if landing then
		onPrompt(landing:FindFirstChild("FrontDoor"), "LeavePrompt", function(p) leavePlot(p, k) end)
		onPrompt(landing:FindFirstChild("FrontDoor"), "DoorPrompt", function(p) cycleDoor(p, k) end) -- Task 14 (the owner's only)
		for _, d in ipairs(landing:GetChildren()) do
			local kind = d:GetAttribute("RoomKind")
			if kind then onPrompt(d, "RoomPrompt", function(p) goRoom(p, k, kind) end) end
		end
	end
	for _, room in ipairs(plot:GetChildren()) do
		local kind = room:GetAttribute("RoomKind")
		if kind then
			local door = Build.DoorOf(room)
			onPrompt(door, "ExitPrompt", function(p) exitRoom(p, k, kind) end)
			onPrompt(door, "DecoratePrompt", function(p) decorate(p, k, kind) end)
		end
	end
end

-- your closet (Task 12) ----------------------------------------------------------------------------------------------------
local CLOSET_ACTION, CLOSET_OBJECT = "Open closet", "Your closet" -- copy 8.1, 8.2
-- the closet's own key pair (R-T12 review, M2). Not E / ButtonX (the laptop's StationPrompt, the exit and the door: under
-- ProximityPrompt's default OnePerButton only the nearest prompt on a key shows, so a closet beside the desk would hide the
-- laptop's), nor F / ButtonY (the rack), R / DPadDown (decorate), G / DPadUp (a player's card, on every character) or ButtonB
-- (closes the panel, the beat maker and decorate mode). C for closet; DPadLeft / DPadRight are the pad directions no code binds
local CLOSET_KEY, CLOSET_PAD = Enum.KeyCode.C, Enum.KeyCode.DPadRight
local CLOSET_OWNER = "{player}'s closet. only they can use it." -- copy 8.6
-- the fits p owns, in Config.Gear order: { { id, color } } (RoomItems.Hangers' rows). Read through the Gear system (ctx.Gear,
-- else the live module); a read that fails counts as not owned. None for no player (a fake owner)
local function ownedFits(p)
	local out = {}
	if not p then return out end
	local okGear, Gear = pcall(function() return (ctx and ctx.Gear) or require(RS.OK.Systems.Gear) end)
	if not (okGear and type(Gear) == "table") then return out end
	for _, it in ipairs(Config.Gear or {}) do
		if it.kind == "fit" then
			local okOwn, owns = pcall(Gear.Owns, p, it.id)
			if okOwn and owns == true then table.insert(out, { id = it.id, color = Fits.Colors[it.fit] }) end
		end
	end
	return out
end
local function fitIds(fits)
	local ids = {}
	for _, f in ipairs(fits) do table.insert(ids, f.id) end
	return table.concat(ids, ",")
end
-- the part a closet's prompt stands on: its Body (the recipe's), else any of its parts
local function closetPart(m)
	local body = m:FindFirstChild("Body")
	if body and body:IsA("BasePart") then return body end
	return m:FindFirstChildWhichIsA("BasePart")
end
-- a closet's prompt pressed (or the hook's Closet) by p in `room`: the owner's closet panel, anyone else the owner toast.
-- Returns { acted, toast?, payload? } (what it sent)
local function openCloset(p, room, part)
	if not (room and room.Parent) then return { acted = false } end
	local owner = room:GetAttribute("OwnerId")
	if owner == nil then return { acted = false } end -- nobody's room: nothing to say
	if owner ~= p.UserId then
		local text = fill(CLOSET_OWNER, { player = short(room:GetAttribute("OwnerName")) })
		toast(p, text)
		return { acted = false, toast = text }
	end
	local Gear = (ctx and ctx.Gear) or require(RS.OK.Systems.Gear)
	local payload = { tab = "Gear", closet = true, gear = Gear.State(p), source = part and part:GetFullName() or nil,
		profile = ctx.Data.ClientProfile(ctx.Data.GetProfile(p)) }
	RS.OK.Remotes.InteractionEvent:FireClient(p, "OpenPanel", payload)
	return { acted = true, payload = payload }
end
-- every closet model in a room's Items `folder`: its prompt once (hooked here: Systems/Rooms' own, untagged) and its hangers
-- when the fits it should show differ from the ones hung: the first RoomRules.HangerCount of the fits owned (`fits`,
-- ownedFits', Config.Gear order), as many as the closet's own parts leave of Config.Rooms.ItemParts (fix 1: the closet never
-- passes its part budget, however many fits; the closet panel still lists them all)
local function dressClosets(room, folder, fits)
	if not folder then return end
	for _, m in ipairs(folder:GetChildren()) do
		if m:IsA("Model") and m:GetAttribute("ItemId") == "closet" then
			local part = closetPart(m)
			if part and not part:FindFirstChild("ClosetPrompt") then
				local cp = Build.Prompt(part, "ClosetPrompt", CLOSET_ACTION, CLOSET_OBJECT)
				cp.KeyboardKeyCode = CLOSET_KEY; cp.GamepadKeyCode = CLOSET_PAD
				onPrompt(part, "ClosetPrompt", function(p) openCloset(p, room, part) end)
			end
			local hung = m:FindFirstChild("Hangers")
			local base = 0
			for _, d in ipairs(m:GetDescendants()) do
				if d:IsA("BasePart") and not (hung and d:IsDescendantOf(hung)) then base += 1 end
			end
			local max = Rules.HangerCount(#fits, base, Cfg.ItemParts, Items.HANGER_PARTS)
			local shown = table.move(fits, 1, max, 1, {})
			if not (hung and hung:IsA("Folder")) or m:GetAttribute("Hangers") ~= fitIds(shown) then Items.Hangers(m, shown, max) end
		end
	end
end

-- the hall's plates ----------------------------------------------------------------------------------------------------
-- plate k (and its door's EnterPrompt) shows slot k now: free, or its owner with their door mode (owners[k].door: the mode
-- the last state() read or cycleDoor wrote; the default until then), the words in PLATE_COLORS' colour (Task 14); and the
-- owner's DoorPrompt on plot k's front door reads the same mode. Never yields
local function plate(k)
	local o = owners[k]
	local num = string.format("%02d", k)
	local mode = o and (o.door or Cfg.DoorDefault)
	local pl = hall and hall:FindFirstChild("Plate_" .. num)
	local gui = pl and pl:FindFirstChild("Text")
	local label = gui and gui:FindFirstChild("Label")
	if label and label:IsA("TextLabel") then
		if plateFree[k] == nil then plateFree[k] = label.TextColor3 end
		label.Text = o and fill(Copy.PlateOwned, { player = o.name, slot = num, MODE = Copy.Modes[mode] or "" })
			or fill(Copy.PlateEmpty, { slot = num })
		label.TextColor3 = (o and PLATE_COLORS[mode]) or plateFree[k]
	end
	local plot = plots[k]
	local landing = plot and plot:FindFirstChild("Landing")
	local front = landing and landing:FindFirstChild("FrontDoor")
	local dp = front and front:FindFirstChild("DoorPrompt")
	if o and dp and dp:IsA("ProximityPrompt") then dp.ActionText = fill(DOOR_ACTION, { MODE = Copy.Modes[mode] or "" }) end
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
	return home, dropped, unbuilt, owned, unlocked
end
-- p's saved home, defaulted and repaired, and written back when that changed it (the profile's own table stays when
-- nothing did, so a held reference stays good). Returns { home = the saved table, owned = the kinds owned in ladder order,
-- dropped, unbuilt = Repair's lists, unlocked = RoomRules.Unlocked's set (Task 9: what Edit checks against), saved = true when
-- the profile is a real one }. A throwaway profile gets the defaults and nothing is written. Yields while the profile loads.
-- Anything dropped is dropped quietly: nothing here is reported.
local function state(p)
	local prof = ctx.Data.GetProfile(p)
	if not usable(prof) then
		return { home = defaultHome(), owned = Rules.Owned(nil, Cfg.Kinds), dropped = {}, unbuilt = {}, unlocked = {}, saved = false }
	end
	local career = prof.career
	local home, dropped, unbuilt, owned, unlocked = repairedFor(p, prof, career.home)
	if sameTree(career.home, home) then
		home = career.home
	else
		career.home = home
		ctx.Data.MarkDirty(p)
	end
	-- the hall plate and the DoorPrompt follow the saved door (Task 14: a SetHome, a Reset, a Career Reset that wiped the home)
	local k = slotOf[p]
	local o = k and owners[k]
	if o and o.player == p and o.door ~= home.door then
		o.door = home.door
		plate(k)
	end
	return { home = home, owned = owned, dropped = dropped, unbuilt = unbuilt, unlocked = unlocked, saved = true }
end
-- the hook's SetHome: `raw` through Repair, saved; returns a copy of what was kept (nil without a usable profile)
local function setHome(p, raw)
	local prof = ctx.Data.GetProfile(p)
	if not usable(prof) then return nil end
	local home = repairedFor(p, prof, raw)
	prof.career.home = home
	ctx.Data.MarkDirty(p)
	forgetView(p)
	return deepCopy(home)
end
-- the hook's Reset: the home back to its defaults
local function resetHome(p)
	local prof = ctx.Data.GetProfile(p)
	if not usable(prof) then return false end
	prof.career.home = defaultHome()
	ctx.Data.MarkDirty(p)
	forgetView(p)
	return true
end

-- your door's mode (Task 14; see the header) ---------------------------------------------------------------------------
-- owner o's door mode: a player's saved home.door, read through state() (repaired: a junk one reads as the default; a
-- failed read is the default too); a fake owner's (the hook's Fill) is the one the hook's Door set, else the default
doorMode = function(o)
	if not o.player then return o.door or Cfg.DoorDefault end
	local ok, st = pcall(state, o.player)
	if not ok then report("door: " .. tostring(st)); return Cfg.DoorDefault end
	return st.home.door
end
-- the owner's DoorPrompt on plot `plot`'s landing FrontDoor (made once; a rebuilt plot is a new one), stamped with the
-- owner's id for RoomClient's gate. Before the plot is parented, so that gate sees the stamp as it streams in
local function addDoorPrompt(plot, o)
	local landing = plot:FindFirstChild("Landing")
	local front = landing and landing:FindFirstChild("FrontDoor")
	if not (front and front:IsA("BasePart")) then return nil end
	local pp = front:FindFirstChild("DoorPrompt")
	if not (pp and pp:IsA("ProximityPrompt")) then pp = Build.Prompt(front, "DoorPrompt", "", DOOR_OBJECT) end
	pp.ActionText = fill(DOOR_ACTION, { MODE = Copy.Modes[o.door or Cfg.DoorDefault] or "" })
	pp.KeyboardKeyCode = DOOR_KEY; pp.GamepadKeyCode = DOOR_PAD
	local leave = front:FindFirstChild("LeavePrompt")
	local base = (leave and leave:IsA("ProximityPrompt")) and leave.UIOffset or Vector2.zero
	pp.UIOffset = base + Vector2.new(0, -Build.RACK_UI_GAP) -- stacked over the LeavePrompt, as DecoratePrompt over the exit
	pp:SetAttribute("OwnerId", o.id)
	return pp
end
-- the DoorPrompt pressed (or the hook's Door) by p for plot k: plot k's owner moves their door on one mode and saves it;
-- anyone else's press does nothing, and so does the owner's within DOOR_COOLDOWN of their last cycle (R-T14 fix 1, M3: no
-- toast, no write, no push; each cycle costs a Repair, a State and a plate change every client sees). Returns the new mode,
-- or false
cycleDoor = function(p, k)
	local o = k and owners[k]
	if not (o and o.player == p and slotOf[p] == k) then return false end
	if lastDoor[p] and os.clock() - lastDoor[p] < DOOR_COOLDOWN then return false end
	local st = state(p) -- the profile is cached by now: no wait between the read and the write
	if not st.saved or owners[k] ~= o then return false end -- a profile that can't hold a home saves nothing
	local mode = Rules.NextDoorMode(st.home.door, Cfg.DoorModes)
	st.home.door = mode -- st.home is prof.career.home itself (state() hands back the profile's own table)
	lastDoor[p] = os.clock()
	ctx.Data.MarkDirty(p)
	forgetView(p)
	o.door = mode
	plate(k)
	toast(p, DOOR_TOAST[mode] or "")
	pushState(p)
	return mode
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

-- your plaques (Task 11) -------------------------------------------------------------------------------------------------
local PLAQUE_FOLDER = "Plaques"
-- how many plaques the rooms in `owned` hold (Config.Rooms.Kinds.<kind>.plaques each)
local function plaqueSlots(owned)
	local n = 0
	for _, kind in ipairs(owned) do n += (Cfg.Kinds[kind] or {}).plaques or 0 end
	return n
end
-- the names a plaque's {artist} is read from: Career's (a failure reads as no names: LifeRules' fallback, never an id)
local function plaqueNames(p)
	local ok, known = pcall(function() return ((ctx and ctx.Career) or require(RS.OK.Systems.Career)).KnownNames(p) end)
	if ok and type(known) == "table" then return known end
	report("plaque names: " .. tostring(known))
	return {}
end
-- what the plaques are read from, as one string: the discography's and the weekly list's lengths and newest rows. Both lists are
-- capped (DiscoMax, 52), so a count alone can stop moving while the newest row changes
local function plaqueSignature(prof)
	local life = type(prof.life) == "table" and prof.life or {}
	local d = type(life.disco) == "table" and life.disco or {}
	local w = type(prof.plaques) == "table" and prof.plaques or {}
	local ld, lw = d[#d], w[#w]
	if type(ld) ~= "table" then ld = {} end
	if type(lw) ~= "table" then lw = {} end
	return table.concat({ #d, tostring(ld.d), tostring(ld.kind), tostring(ld.v), tostring(ld.key), #w, tostring(lw.w), tostring(lw.t) }, "|")
end
-- the plaques p's career earns, at most `total`, in hang order: { { kind, text } }, and the signature of what they were read
-- from (nil for a throwaway or unreadable profile, which gives none). Reads the profile (may wait for it to load: build()
-- calls this before its generation check)
local function plaqueRows(p, total)
	local ok, rows, sig = pcall(function()
		local prof = ctx.Data.GetProfile(p)
		if type(prof) ~= "table" or prof._detached then return {} end
		local life = type(prof.life) == "table" and prof.life or {}
		local weekly = {}
		for _, w in ipairs(type(prof.plaques) == "table" and prof.plaques or {}) do
			if type(w) == "table" and type(w.t) == "string" and w.t ~= "" then table.insert(weekly, w) end
		end
		local names -- read once, and only when a discography row needs it
		local out = {}
		for _, row in ipairs(Rules.Plaques(life.disco, weekly, total)) do
			local text
			if row.kind == "weekly" then text = fill(Copy.WeeklyPlate, { title = string.upper(row.entry.t) })
			else
				names = names or plaqueNames(p)
				text = LifeRules.DiscoText(row.entry, names)
			end
			if type(text) == "string" and text ~= "" then table.insert(out, { kind = row.kind, text = text }) end
		end
		return out, plaqueSignature(prof)
	end)
	if not ok then report("plaques: " .. tostring(rows)); return {}, nil end
	return rows, sig
end
-- the room's own Plaques folder (R-T16 fix, M2, as RoomEdit's folderOf finds Items): only a Folder carrying RoomPlaques is
-- ever reused (and so emptied); a child named Plaques that Rooms did not make (an import that ships its own) is left as
-- it is, with a notice, and Rooms makes its own beside it. Never yields
local function plaqueFolder(room)
	for _, c in ipairs(room:GetChildren()) do
		if c.Name == PLAQUE_FOLDER and c:IsA("Folder") and c:GetAttribute("RoomPlaques") == true then return c end
	end
	if room:FindFirstChild(PLAQUE_FOLDER) then
		-- a notice, not an [OK][ERR]: the room still gets its plaques, and nothing of the import's is touched
		warn("[OK] rooms: " .. room:GetFullName() .. " has a child named " .. PLAQUE_FOLDER .. " that Rooms did not make; it is left alone")
	end
	local f = Instance.new("Folder")
	f.Name = PLAQUE_FOLDER
	f:SetAttribute("RoomPlaques", true)
	f.Parent = room
	return f
end
-- hangs `rows` ({ { kind, text } }, in order) in the rooms of `plot` that are in `owned` (ladder order): each room's Plaques
-- folder (plaqueFolder: Rooms' own only) is emptied, then filled from its Plaque_1..n anchors, the next row going to the
-- next anchor; the rooms after the last row stay empty. A slot with no anchor is reported and skipped (its row goes to the
-- next slot). Never yields
local function hangPlaques(plot, owned, rows)
	local at = 0
	for _, kind in ipairs(owned) do
		local room = plot:FindFirstChild(Build.RoomName(kind))
		if room then
			local folder = plaqueFolder(room)
			folder:ClearAllChildren()
			for slot = 1, (Cfg.Kinds[kind] or {}).plaques or 0 do
				local row = rows[at + 1]
				if not row then break end
				local a = room:FindFirstChild("Plaque_" .. slot, true)
				if a and a:IsA("Attachment") then
					local m = Items.Plaque(row, row.text)
					if m then
						m.Name = "RoomPlaque_" .. slot
						m:SetAttribute("Slot", slot)
						m:PivotTo(a.WorldCFrame)
						m.Parent = folder
						at += 1
					end
				else
					report("plaques: room " .. kind .. " has no Plaque_" .. slot .. " anchor")
				end
			end
		end
	end
end
-- the owner's Placements, Hits or Plaques changed: their standing plot's plaques are read and hung again. No plot yet: its
-- build hangs them. May wait for the profile; a rebuild or a release meanwhile drops this one (the build hung its own)
local function syncPlaques(p)
	local k = slotOf[p]
	local o = k and owners[k]
	local plot = k and plots[k]
	local owned = k and kindsOf[k]
	if not (o and o.player == p and plot and owned) then return false end
	local rows, sig = plaqueRows(p, plaqueSlots(owned))
	if not (slotOf[p] == k and owners[k] == o and plots[k] == plot and kindsOf[k] == owned and plot.Parent) then return false end
	hangPlaques(plot, owned, rows)
	plaqueSig[p] = sig
	return true
end
-- one rebuild per burst of changes, after the writer has finished (see the header)
local function queuePlaques(p)
	if plaqueDirty[p] then return end
	plaqueDirty[p] = true
	task.defer(function()
		plaqueDirty[p] = nil
		local ok, err = pcall(syncPlaques, p)
		if not ok then report("plaques after a career change: " .. tostring(err)) end
	end)
end
-- the backstop, run by the presence loop once a second for a player whose plot is built (its profile is cached by then, so this
-- doesn't yield): if the lists the plaques hang from differ from what the last hang read, queue a rebuild. It catches what the
-- attributes can't: a discography row that lands after the stat's attribute was already read (the deferred read can run between
-- two writers that aren't one thread, as a test's two hook calls aren't), a row pushed with no stat move, and a weekly plaque at
-- Dailies' 52 cap, where the count and so the attribute stay put. Up to a second of lag on those paths
local function checkPlaqueSignature(p)
	local k = slotOf[p]
	local o = k and owners[k]
	if not (o and o.player == p and plots[k] and plaqueSig[p] ~= nil) then return end
	local prof = ctx.Data.GetProfile(p)
	if type(prof) ~= "table" or prof._detached then return end
	if plaqueSignature(prof) ~= plaqueSig[p] then queuePlaques(p) end
end

-- plots ------------------------------------------------------------------------------------------------------------------
-- an owner's saved state (state()), ladder order owned: a fake owner from the hook's Fill has the bedroom and no items. Reading
-- it repairs the saved home too, which may wait for the profile: build() calls this before its generation check
local function stateFor(o)
	local blank = { home = defaultHome(), owned = Rules.Owned(nil, Cfg.Kinds), dropped = {}, unbuilt = {}, unlocked = {}, saved = false }
	if not o.player then return blank end
	local ok, st = pcall(state, o.player)
	if not ok then report("home: " .. tostring(st)); return blank end
	return st
end
-- your things (Task 9): the room's Items folder shows kind's saved list (RoomEdit.Fit; st = state()'s answer; the entries
-- Repair keeps unbuilt stay out); then its closets are dressed for `fits` (ownedFits' rows; Task 12), never throwing
local function fitRoom(room, kind, st, fits)
	local skip = {}
	for _, u in ipairs(st.unbuilt) do if u.kind == kind then skip[u.index] = true end end
	local folder = Edit.Fit(room, st.home.items[kind], skip, Catalog, Cfg) -- Cfg: the posters' words, colours and styles (Task 13)
	local ok, err = pcall(dressClosets, room, folder, fits or {})
	if not ok then report("closet: " .. tostring(err)) end
	return folder
end
-- every room of plot `plot` (a Model) shows its saved items, or just `only` (a kind)
local function fitPlot(plot, st, only, fits)
	for _, room in ipairs(plot:GetChildren()) do
		local kind = room:GetAttribute("RoomKind")
		if kind and (only == nil or only == kind) then fitRoom(room, kind, st, fits) end
	end
end
-- (re)builds plot k for its owner; an old plot goes only once the new one stands (same place, so nobody falls)
local function build(k)
	local o = owners[k]
	if not o or roomTest() then return nil end -- the phone test's plot stands on this slot's origin
	buildGen[k] = (buildGen[k] or 0) + 1
	local gen = buildGen[k]
	local st = stateFor(o) -- may wait for the profile
	local owned = st.owned
	local tier = o.player and speakerTier(o.player) or 1 -- a fake owner (the hook's Fill) has the laptop's own
	local rows, sig = {}, nil -- a fake owner has no career
	if o.player then rows, sig = plaqueRows(o.player, plaqueSlots(owned)) end -- (the profile is loaded by now)
	local fits = ownedFits(o.player) -- the closets' hangers (Task 12; a fake owner: none)
	if buildGen[k] ~= gen or owners[k] ~= o then return nil end -- released or rebuilt meanwhile
	local plot = Build.Plot(k, owned, Cfg, template, { id = o.id, name = o.name })
	fitPlotSpeakers(plot, tier)
	hangPlaques(plot, owned, rows) -- your walls (Task 11), before the plot goes into Workspace
	if o.player then plaqueSig[o.player] = sig end
	fitPlot(plot, st, nil, fits) -- each room's Items folder, built from the saved home, before the plot goes into Workspace
	for _, room in ipairs(plot:GetChildren()) do
		if room:GetAttribute("RoomKind") then addDecorate(room) end -- before hookPlot hooks it (Task 10)
	end
	addDoorPrompt(plot, o) -- the owner's door mode (Task 14; o.door: stateFor's read above noted it), before hookPlot hooks it
	ctx.Interaction.Adopt(plot)
	hookPlot(plot, k)
	local old = plots[k]
	if old then old.Name = old.Name .. "_old" end
	plot.Parent = plotsFolder -- once, straight into Workspace: the added-tag signal hooks the room's Station
	plots[k], kindsOf[k] = plot, owned
	if old then old:Destroy() end
	plate(k) -- the hall plate shows the mode this build read (Task 14)
	if o.player then
		rebuiltEv:Fire(o.player, k)
		pushState(o.player) -- the edit bar's view follows the new plot (Task 10)
	end
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
-- p's standing plot shows their saved items again (Task 9: after a SetHome, and when their Gear changes: a gear item saved
-- while its gear read as not owned stands once the gear is, and goes when it isn't); `only` = one kind. False without a plot
local function syncItems(p, only)
	local k = slotOf[p]
	local o = k and owners[k]
	local plot = k and plots[k]
	if not (o and o.player == p and plot) then return false end
	forgetView(p)
	local st = state(p) -- may wait for the profile
	local fits = ownedFits(p)
	if not (slotOf[p] == k and plots[k] == plot and plot.Parent) then return false end
	fitPlot(plot, st, only, fits) -- the closets rehang for the fits owned now (Task 12: this is the Gear listener's path too)
	pushState(p) -- the edit bar's view follows (Task 10)
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
	if roomTest() then -- the phone test's 12 plots hold every slot's spot
		p:SetAttribute("PlotSlot", 0)
		return nil
	end
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
-- they are the one leaving), then the plot goes. R-T16 fix, I5: o.releasing is set first (no door moves anyone into or
-- around the plot from then on; a second release of the same owner answers false), and a final sweep with no yield before
-- the Destroy moves anyone still in the plot (a guest whose door move landed after the scan, a mover whose move didn't take)
local function releaseSlot(k, leaving)
	local o = owners[k]
	if not o or o.releasing then return false end
	o.releasing = true
	local target = hallSpawn()
	local leftLine = fill(Copy.OwnerLeft, { player = short(o.name) })
	local told = {} -- [player] = told copy 1.19 already
	local movers = {}
	for _, q in ipairs(Players:GetPlayers()) do
		local r = rootOf(q)
		if r and plotAt(r.Position) == k and not (leaving and q == o.player) then table.insert(movers, q) end
	end
	if target then
		local left = #movers
		for _, q in ipairs(movers) do
			if q ~= o.player then toast(q, leftLine); told[q] = true end
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
	-- the final sweep: NOTHING below yields until plot:Destroy() (plotAt reads slots[k], so it runs before that is cleared)
	local swept = {}
	if target then
		for _, q in ipairs(Players:GetPlayers()) do
			local r = rootOf(q)
			if r and plotAt(r.Position) == k and not (leaving and q == o.player) then
				local ok, err = pcall(function()
					local c = q.Character
					local hum = c:FindFirstChildOfClass("Humanoid")
					local seat = hum and hum.SeatPart
					local weld = seat and seat:FindFirstChild("SeatWeld")
					if hum then hum.Sit = false end
					if weld then weld:Destroy() end
					c:PivotTo(target + Vector3.new(0, 3, 0))
				end)
				if not ok then report("release sweep: " .. tostring(err)) end
				if q ~= o.player and not told[q] then toast(q, leftLine); told[q] = true end
				table.insert(swept, q)
			end
		end
	end
	testGuests[k] = nil
	local plot = plots[k]
	plots[k], kindsOf[k], slots[k], owners[k] = nil, nil, nil, nil
	buildGen[k] = (buildGen[k] or 0) + 1
	if o.player then
		slotOf[o.player] = nil
		plaqueSig[o.player] = nil
		forgetView(o.player)
		if o.player.Parent then o.player:SetAttribute("PlotSlot", 0) end
	end
	if plot then plot:Destroy() end
	endPlay(k) -- its speakers are gone with it
	plate(k)
	for _, q in ipairs(movers) do pcall(presence, q) end
	for _, q in ipairs(swept) do pcall(presence, q) end
	return true
end

-- the wake-up and the respawn rule ----------------------------------------------------------------------------------------
-- your bedroom's Spawn (forced: past the test hold); no slot: the full toast, and you stay in the studio
local function wakeUp(p, forced)
	if roomTest() then return false end -- before the full toast: the phone test's server has no plots to be full of
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
	if roomTest() then return "held" end
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
		ok, err = pcall(syncItems, p)
		if not ok then report("items after a gear change: " .. tostring(err)) end
	end)
	local pq = {}
	for _, attr in ipairs({ "Placements", "Hits", "Plaques" }) do
		table.insert(pq, p:GetAttributeChangedSignal(attr):Connect(function() queuePlaques(p) end))
	end
	plaqueConns[p] = pq
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
	sent[p.UserId], counts[p.UserId], pushed[p.UserId] = nil, nil, nil
	views[p], viewGen[p] = nil, nil
	friendCache[p], friendAsks[p], lastDoor[p] = nil, nil, nil -- a check still in flight finishes uncached (the guest has gone)
	Edit.Forget(p)
	local gc = gateConns[p]
	if gc then gc:Disconnect(); gateConns[p] = nil end
	local gr = gearConns[p]
	if gr then gr:Disconnect(); gearConns[p] = nil end
	for _, c in ipairs(plaqueConns[p] or {}) do c:Disconnect() end
	plaqueConns[p], plaqueDirty[p], plaqueSig[p] = nil, nil, nil
	local a = armed[p]
	if a then a.conn:Disconnect(); armed[p] = nil end
	decoArmed[p] = nil
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
-- where a delivery made at `inst` (a Station, the PC's screen or chair) plays its listen-back (Task 12; see the header):
-- { spot, cam } in a room with a booth, false in a room without one, nil in the hub
function M.Booth(inst)
	if typeof(inst) ~= "Instance" then return nil end
	local room = RoomScope.RoomOf(inst)
	if not room then return nil end
	local kind = room:GetAttribute("RoomKind")
	local kc = type(kind) == "string" and Cfg.Kinds[kind] or nil
	if not (kc and kc.booth) then return false end
	local function anchor(name)
		local a = room:FindFirstChild(name, true)
		return (a and a:IsA("Attachment")) and a.WorldCFrame or nil
	end
	local spot, cam = anchor("BoothSpot"), anchor("BoothCam")
	if not (spot and cam) then
		report("booth: " .. room:GetFullName() .. " has no BoothSpot / BoothCam anchor")
		return false
	end
	return { spot = spot, cam = cam }
end
-- placing your things (Task 9) ---------------------------------------------------------------------------------------------
-- Edit(p, action): action = { op = "place" | "move" | "remove" | "poster", kind, index? (move, remove: the item's place in your saved
-- list for that room), id? (place), x?, z?, r? (place, move: the footprint's lowest cell after its turn, and the turn in quarter
-- turns 0..3; RoomRules' scheme), slot, w, c, s (poster, Task 13: a wall spot and a design, whole numbers; a poster already on
-- that spot is redesigned in place, see the header) }. Every call takes a token from the player's bucket first (Config.Rooms.Edit; RoomEdit.Take):
-- none left -> "busy". Then where you stand: outside any plot (the hub, the hall, the corridor, between places) -> "away"; in
-- someone else's plot -> "owner"; your own plot, a room or the landing, goes on (a room you own may be edited from anywhere in
-- your plot: the edit bar tells the server which room it means). The action is type-checked and copied (RoomEdit.Check:
-- "invalid"), `kind` must be a room you own ("room"), then RoomRules.Fits decides with the live Unlocked (its reasons come
-- through as they are: "unknown", "locked", "room", "bounds", "overlap", "limit", "max", "rot", "slot", "design"; a stale index
-- is "unknown"; the cells of an entry Repair keeps unbuilt, a locked one, are "overlap": R-T10 fix 1). A profile that can't hold a home (a failed load, a detached one) is "error" (Task 9's review M3). Only a
-- passing action changes anything: the saved home (prof.career.home) is changed, marked for saving, and that room's Items
-- folder follows (RoomEdit.Fit rebuilds only the models that changed; a refit that throws is reported and the saved edit
-- still answers ok, M2), and the owner's client gets the new State (the Room remote's "state", Task 10). Returns { ok = true,
-- op, kind, index, item? } or { ok = false, reason }. It never throws on a client's input.
function M.Edit(p, action)
	if not Edit.Take(p, Cfg.Edit) then return { ok = false, reason = "busy" } end
	local place = M.PlaceOf(p)
	if type(place) ~= "table" then return { ok = false, reason = "away" } end
	local k = slotOf[p]
	if k == nil or place.slot ~= k then return { ok = false, reason = "owner" } end
	local a, why = Edit.Check(action)
	if not a then return { ok = false, reason = why } end
	local st = state(p) -- may wait for the profile
	if not st.saved then return { ok = false, reason = "error" } end
	local plot = plots[k]
	if not (slotOf[p] == k and plot and plot.Parent) then return { ok = false, reason = "away" } end
	local room = plot:FindFirstChild(Build.RoomName(a.kind))
	local res = Edit.Apply(st.home, a, st.owned, st.unlocked, Cfg, Catalog, st.unbuilt) -- unbuilt entries hold their cells (R-T10 fix 1)
	if not res.ok then return res end
	ctx.Data.MarkDirty(p)
	forgetView(p)
	local okFit, err = pcall(function()
		local after = state(p) -- the saved list as Repair keeps it (it equals what Apply wrote, or a repaired form of it)
		if room and room.Parent then fitRoom(room, a.kind, after, ownedFits(p)) end -- a placed closet is dressed (Task 12)
	end)
	if not okFit then report("edit refit (the edit is saved): " .. tostring(err)) end
	pushState(p)
	return res
end
-- State(p): the edit bar's whole view of your rooms: { rooms = { [kind] = { limit, used (what counts toward the limit: the
-- entries that are built, posters included), items (a copy of your saved list, in order: an index here is the index Edit
-- takes; entries whose gear you don't own are in it but unbuilt), grid, keep (the free floor and the keep-out areas, room-local
-- { x0, z0, x1, z1 }: what RoomRules.Fits reads on the client), slots (the room's poster slots) } for each room you own },
-- unlocked = { catalog ids open to you, sorted }, door = your door mode, inside = the kind of the room you stand in (nil on the
-- landing, in another plot or outside) }.
function M.State(p)
	local st = state(p)
	local rooms = {}
	for _, kind in ipairs(st.owned) do
		local kc = Cfg.Kinds[kind]
		if kc then
			local list = st.home.items[kind] or {}
			local unbuilt = 0
			for _, u in ipairs(st.unbuilt) do if u.kind == kind then unbuilt += 1 end end
			rooms[kind] = { limit = kc.limit, used = #list - unbuilt, items = deepCopy(list), grid = deepCopy(kc.grid),
				keep = deepCopy(kc.keep or {}), slots = kc.posters or 0 }
		end
	end
	local ids = {}
	for id, on in pairs(st.unlocked) do if on == true then table.insert(ids, id) end end
	table.sort(ids)
	return { rooms = rooms, unlocked = ids, door = st.home.door, inside = insideOf(p) }
end
-- the remotes' own handlers (Room_Get, Room_Edit: bound in Init; the hook's Edit and State run the same functions): a throw is
-- reported and answered, never passed to the client's InvokeServer. Room_Get answers from the cache (viewFor; Task 9's review
-- M1: it is unthrottled, so a client calling it often costs one State a VIEW_SECONDS, not a Repair a call)
local function roomGet(player)
	-- Studio: the hook's OnDecorate (R-T16 fix, I1's test seam). Once its decorate push has gone out, the client's first
	-- Room_Get is decorate mode's own fetch (RoomClient's enter); the second is the client test's knock, sent once it reads
	-- Editing: the armed command runs then (deferred, after this answer), while decorate mode is on, with no timing guess
	local d = decoArmed[player]
	if d and d.pushed then
		d.gets += 1
		if d.gets >= 2 then
			decoArmed[player] = nil
			task.defer(function()
				local okRun, errRun = pcall(dispatch, d.cmd, player.UserId, d.a)
				if not okRun then report("OnDecorate " .. tostring(d.cmd) .. ": " .. tostring(errRun)) end
			end)
		end
	end
	local ok, res, cached = pcall(viewFor, player)
	if ok then
		if not cached and RunService:IsStudio() then
			local c = counts[player.UserId] or {}
			counts[player.UserId] = c
			c.views = (c.views or 0) + 1
		end
		return res
	end
	report("Room_Get: " .. tostring(res))
	return nil
end
local function roomEdit(player, action)
	local ok, res = pcall(M.Edit, player, action)
	if ok then return res end
	report("Room_Edit: " .. tostring(res))
	return { ok = false, reason = "error" }
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
	if roomTest() then return 0 end -- the throwaway-test seam: no slot is claimed, not even a fake owner's
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
-- the hook's OnDecorate(cmd, a) (R-T16 fix, I1's test seam; Studio only, one shot): the next time this player's decorate push
-- goes out (a DecoratePrompt press, or the hook's Decorate), hook command cmd(a) runs at their second Room_Get after it (after
-- the LAST push: each push starts the count again, round 2 N3)
-- (roomGet: the first is decorate mode's own fetch, the second the client test's knock once it reads Editing). Disarmed
-- after 30 s, or by a new arm
local function armDecorate(p, cmd, a)
	if type(cmd) ~= "string" then return false end
	local entry = { cmd = cmd, a = a, pushed = false, gets = 0 }
	decoArmed[p] = entry
	task.delay(30, function() if decoArmed[p] == entry then decoArmed[p] = nil end end)
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
		friendStub, friendCalls = nil, nil -- Task 14: the real friend check again, nothing cached
		clearFriends()
		resetHome(p) -- every test's fresh(): one test's saved items never reach the next
		local k = claim(p)
		return k ~= nil and build(k) ~= nil
	end
	if cmd == "Home" then local st = state(p); return deepCopy(st.home) end
	if cmd == "SetHome" then
		local kept = setHome(p, a)
		if kept ~= nil then
			local ok, err = pcall(syncItems, p) -- the plot's items follow the repaired home (Task 9)
			if not ok then report("SetHome items: " .. tostring(err)) end
		end
		return kept
	end
	if cmd == "Edit" then return roomEdit(p, a) end -- the Room_Edit remote's own handler (Task 9)
	if cmd == "State" then return roomGet(p) end -- the Room_Get remote's (Task 9; its cache, Task 10)
	-- Task 10: Decorate(kind) runs the DecoratePrompt's handler, decorate(p, k, kind), for room `kind` (default the bedroom)
	-- with k = here(p): the plot the player stands in, or their own slot when they stand in no plot at all (the hub, the hall).
	-- So it answers false in someone else's plot, for a room the plot lacks, or with no slot; true (and pushes "decorate")
	-- for the owner, inside their plot or outside every plot. Pushed: the Room remote's messages to the player since the last
	-- read, { { kind, payload } }
	if cmd == "Decorate" then local k = here(p); return k ~= nil and decorate(p, k, a or "bedroom") end
	if cmd == "Pushed" then local log = pushed[p.UserId] or {}; pushed[p.UserId] = nil; return log end
	if cmd == "WakeUp" then return wakeUp(p, true) end
	if cmd == "Enter" then -- b true or false answers the friend check; anything else (nil) runs it, as the EnterPrompt does
		local asFriend = nil
		if b == true or b == false then asFriend = b end
		return enterPlot(p, a, asFriend)
	end
	-- Task 14: Door() runs the DoorPrompt's handler for the player's own slot (the new mode; false with no slot); Door(slot,
	-- mode) sets a fake owner's (the hook's Fill) mode, for a test (the mode; false for a real owner's slot, a free one or a
	-- junk mode; false too for the owner's press within DOOR_COOLDOWN of their last cycle). FriendCheck(spec | nil) (fix 1, I1:
	-- no function crosses the BindableFunction, only a spec table, copied): the stub is built here, server-side, around a
	-- fresh counter c = { calls, done } (so a late sleeper of an earlier stub never counts toward this one): { kind = "answer",
	-- value = bool } answers at once; { kind = "error" } raises; { kind = "sleep", seconds = n (0 - 30), value = bool } waits n
	-- s, then answers. calls counts the calls, done the ones that finished (returned or raised). nil puts the real check back.
	-- Both clear the cache; answers "stub" or "real", false for anything else (nothing changed). FriendCalls: a copy of the
	-- current stub's counter, { calls = 0, done = 0 } with no stub
	if cmd == "Door" then
		if a == nil then
			local k = slotOf[p]
			if not k then return false end
			return cycleDoor(p, k)
		end
		local k = tonumber(a)
		local o = k and owners[k]
		if not (o and o.fake and type(b) == "string" and table.find(Cfg.DoorModes, b)) then return false end
		o.door = b
		plate(k)
		return b
	end
	if cmd == "FriendCheck" then
		local stub, c = nil, nil
		if a ~= nil then
			if type(a) ~= "table" then return false end
			local counter = { calls = 0, done = 0 }
			local v, secs = a.value, tonumber(a.seconds)
			if a.kind == "answer" and type(v) == "boolean" then
				stub = function() counter.calls += 1; counter.done += 1; return v end
			elseif a.kind == "error" then
				stub = function() counter.calls += 1; counter.done += 1; error("the hook's friend check stub, on purpose") end
			elseif a.kind == "sleep" and type(v) == "boolean" and secs and secs == secs then
				local pause = math.clamp(secs, 0, 30)
				stub = function() counter.calls += 1; task.wait(pause); counter.done += 1; return v end
			else
				return false
			end
			c = counter
		end
		friendStub, friendCalls = stub, c
		clearFriends()
		return stub ~= nil and "stub" or "real"
	end
	if cmd == "FriendCalls" then
		return friendCalls and table.clone(friendCalls) or { calls = 0, done = 0 }
	end
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
	if cmd == "OnDecorate" then return armDecorate(p, a, b) end -- R-T16 fix, I1's test seam (see armDecorate)
	-- Task 7: DAW_Broadcast's and DAW_Stop's own handlers for this player (the remote's path: the room branch, the
	-- BroadcastTried rule); Counts since the last read; the speaker tier; the live FIRE rule for a token
	if cmd == "Play" then return require(RS.OK.Systems.DAW)._Broadcast(p, a, b, 0) end
	if cmd == "Stop" then require(RS.OK.Systems.DAW)._Stop(p); return true end
	if cmd == "Counts" then
		local c = counts[p.UserId] or {}
		counts[p.UserId] = nil
		return { played = c.played or 0, tried = c.tried or 0, rebuilt = c.rebuilt or 0, views = c.views or 0 }
	end
	-- Task 11: SetWeekly(list) replaces prof.plaques (the weekly singles' plaques, { { w, t, a } }; nil = none) with a copy and
	-- sets the Plaques attribute as Systems/Dailies does, so a test can seed, clear and put back the list (nothing else writes it
	-- without a delivery). Returns a copy of what it saved, nil without a usable profile
	if cmd == "SetWeekly" then
		local prof = ctx.Data.GetProfile(p)
		if type(prof) ~= "table" or prof._detached then return nil end
		local list = {}
		for _, w in ipairs(type(a) == "table" and a or {}) do
			if type(w) == "table" then table.insert(list, { w = tonumber(w.w) or 0, t = tostring(w.t or ""), a = tostring(w.a or "") }) end
		end
		prof.plaques = list
		ctx.Data.MarkDirty(p)
		p:SetAttribute("Plaques", #list)
		return deepCopy(list)
	end
	if cmd == "SpeakerTier" then return speakerTier(p) end
	if cmd == "Fire" then return require(RS.OK.Systems.Reactions).Send(p, a) end
	-- Task 12: Closet(kind) runs the ClosetPrompt's handler (openCloset, no reach check, as Decorate) for the closet in room
	-- `kind` (default home) of here(p): { acted, toast?, payload? }, nil when that room has no closet; Booth(inst) is M.Booth
	if cmd == "Closet" then
		local k = here(p)
		local room = k and roomOf(k, a or "home")
		local items = room and room:FindFirstChild("Items")
		for _, m in ipairs(items and items:GetChildren() or {}) do
			if m:IsA("Model") and m:GetAttribute("ItemId") == "closet" then return openCloset(p, room, closetPart(m)) end
		end
		return nil
	end
	if cmd == "Booth" then return M.Booth(a) end
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
			if plaqueSig[p] ~= nil then -- the plaques' backstop (Task 11), in its own thread: one player's wait never stalls the rest
				task.spawn(function()
					local okP, errP = pcall(checkPlaqueSignature, p)
					if not okP then report("plaque check: " .. tostring(errP)) end
				end)
			end
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
		onPrompt(door, "EnterPrompt", function(p) enterPlot(p, k, nil) end) -- nil: the friend check decides (Task 14)
		plate(k)
	end
	onPrompt(hall and hall:FindFirstChild("HubDoor"), "HubPrompt", toCorridor)
	onPrompt(roomsDoor, "RoomsPrompt", toHall)
	local remotes = RS.OK:FindFirstChild("Remotes")
	local get, edit = remotes and remotes:FindFirstChild("Room_Get"), remotes and remotes:FindFirstChild("Room_Edit")
	if get and get:IsA("RemoteFunction") and edit and edit:IsA("RemoteFunction") then
		get.OnServerInvoke = roomGet
		edit.OnServerInvoke = roomEdit
	else
		report("Remotes.Room_Get / Room_Edit missing: run build/19_rooms.lua in Edit")
	end
	local ev = remotes and remotes:FindFirstChild("Room")
	if ev and ev:IsA("RemoteEvent") then
		roomEvent = ev
		-- the Room remote is server -> client only ("decorate", "state"). R-T16 fix, M4: an empty listener, so a client firing
		-- it at the server is dropped here instead of filling the remote's queue ("queue exhausted" warnings)
		ev.OnServerEvent:Connect(function() end)
	else
		report("Remotes.Room missing: run build/19_rooms.lua in Edit")
	end
	Players.PlayerAdded:Connect(onJoin)
	Players.PlayerRemoving:Connect(onLeave)
	for _, p in ipairs(Players:GetPlayers()) do onJoin(p) end
	task.spawn(loop)
	if RunService:IsStudio() and RunService:IsRunning() then makeHook() end
end

return M
