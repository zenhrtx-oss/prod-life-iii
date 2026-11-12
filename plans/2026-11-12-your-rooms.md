# Your Rooms Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Implementers write files and run CLI specs only; the controller is the only Studio client.

**Goal:** You wake up in your own bedroom behind your own door in the shared building. Your space grows a room per unlock (bedroom → home studio → real studio). Visitors find you there. You place your own things, your walls show your career, and you play beats on speakers you earn and upgrade. The hub stays the public stage.

**Architecture:**
- **Pure rules first.** `Modules/RoomRules` (new, pure) holds plot geometry, presence boxes, the item grid, save repair, plaques, speaker tiers, door access and poster checks. `Data/RoomCatalog` (new, pure data) holds the launch catalog. `WalkInRules.Present` is the one presence rule. All of them are CLI-tested with Config values passed in.
- **One server owner.** `Systems/Rooms` (new) owns plots, the wake-up, doors, `prof.career.home`, room plays, plaques and edits.
  - Builders: `Modules/RoomBuild` (plots, landing, stand-ins, anchors) and `Modules/RoomItems` (items, speakers, plaques, posters, closet). Both are built from parts, so there are no uploads.
- **Existing systems change at named seams:**
  - InteractionService: `Adopt` and the owner rule
  - DAW: `StationOf` and room plays
  - WalkIns and Visitor: room presence and routes
  - Gear: speakers and `Grant`
  - Tour: `Rooms.Played`
  - DAWClient: the speakers label and the booth
  - PanelUI: closet mode
- **The client.** `RoomClient` (new LocalScript): the room-speaker listener, edit mode and the poster designer, with `Modules/RoomUI` as its bar.

**Tech Stack:** Luau (Roblox), Roblox Studio via the built-in Studio MCP (`tools/mcp_call.py`), `tools/sync.py`, `tools/test.py`, `sh tools/spec.sh`, the `luau` CLI, Python 3.

**Spec:** `specs/2026-11-12-progression-and-rooms-design.md`. Sections §4.0–4.9 and §4.13 as decided in §7 (D7, D9, D10, D12), plus the §6 pacing line: "the first monitors are reachable during the first session; larger rooms take sustained progress". Bedroom asset: `../ok_assets/environments/bedroom_starter/README.md` and its `bedroom_setup.lua`. The people plan (`plans/2026-11-12-people-and-progression.md`) owns the pacing run (§8), titles, contacts and the big-names gate.

## Global Constraints

- **No git.** Every commit step is `sh .superpowers/g add -A src build spec specs plans research README.md && sh .superpowers/g commit -q -m "<task>: <what>"`. Add `tools` when a tool changes. Every message ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Task prefix `R-T<n>`.
- **One Studio client.** Implementers never call `tools/sync.py`, `tools/test.py`, `tools/mcp_call.py`, `tools/snapshot.sh`, `tools/export_rbxm.py`, a build script or any `mcp__Roblox_Studio__*` tool.
  - The controller does all of that under the Studio lease: message every live OK session before, "done with Studio" after.
  - Per task: the red run, then the listed Edit build scripts, then the sync, then the green run.
  - Load under 30 before a suite. Suites run under `caffeinate -d`. One rerun per flake.
- **Scoped syncs only:** `python3 -I tools/sync.py --dry`, then the parent-qualified patterns in each task's sync list. Never `--force`.
- **Selectors are substrings.** `t10` also matches t100–t109, and `t13` matches t130+. This plan's selectors are written to match only their own files (`t100_`, `t101a`). An older task's selector may now also run these files, which is harmless.
- **Pure modules** never touch Roblox globals and never `require`: `Modules/WalkInRules`, `CareerRules`, `CareerSim`, `LifeRules`, `Format`, `RoomScope`, `VisitorLooks`, `RoomRules` (new), and `Data/WalkIns`, `Data/RoomCatalog` (new). CLI specs keep literal Config copies (`spec/economy_fixture.lua`, pinned by t46).
- **Money:** `sh tools/spec.sh` (pacing included) stays green after every task.
  - This plan adds no walk-in money and no deck cards.
  - Speaker gear has no `feature`, so it never enters the sim's gear (`economy_fixture.gear`).
  - The room gates' prices are first guesses. The people plan's Task 6 tunes them with the pacing run.
- **Saves:** schema stays **v5**.
  - The one new field is `prof.career.home`, lazily defaulted and repaired in `Systems/Rooms`' `state()`. DataService doesn't change, and t41's 8 career keys after a bare load stay 8.
  - Room ownership is `prof.career.gates` (Career.Unlock is its one writer), never a second list.
  - The `_StudioCareerHook` `Reset` that every fresh() calls replaces `prof.career`, so it also wipes `home`. Rooms rebuilds when it sees that.
- **Budgets:**
  - The hub keeps ≤ 61 lights, exactly 12 tagged interactables and 2 Stations (`Modules/RoomScope`; t03, t04, t05, t07, 09_qa, 14_stations, t88).
  - Each room holds ≤ 1 light: the stand-ins' one bulb. Items, plaques, speakers, posters, the landing and the hall add 0 lights.
  - `Config.SFX` stays 17 keys (t11_check :19). New prompts (doors, Decorate, the closet) are **not** tagged `OK_Interactable`: `Systems/Rooms` hooks them itself. The room door sound reuses `Config.SFX.Door`'s id.
  - Only the room's Station and the rack spot are tagged. They sit inside an `OK_Room` model, so the hub counts never see them.
- **Every floor top is y 0** (hub, hall, landing, rooms). The visitor walker poses at a fixed floor y.
- **Copy:**
  - Every new player-facing line comes from Task 0's file and goes on its approval list. Build with the drafts.
  - Rules: CAPS headlines and tags, lowercase bubble lines, display names only through `{name:<id>}`.
  - Banned: OK branding (t50; the plain word "ok" is fine), CRED/Cred (t40), STUDIO TWO, and the BLOCK words.
  - **No player-typed text.** Posters use preset words only, and there is no TextBox anywhere.
- **Phone first:** every new control is ≥ 44 px and inside the viewport at 667×375, 771×390 and 844×390, with no two visible buttons overlapping.
- **Test numbers:** t100–t114. Edit checks are `tNNN_check.lua` with marker `T100 OK`. Play pairs are `tNNNa_play_server` / `tNNNb_play_client` with markers `T101A PLAY OK` and `T101B PLAY OK`.
  - Each play file starts with its own `fresh()`: unseat; teleport to the lounge (24, 3, 0); Phone `Quiet` and `Reset`; WalkIns `Reset`; Career `Reset`; Life `Reset`; `ResetHints`; `_StudioRoomsHook` `Reset`.
  - Each runs in a pcall with cleanup and a rethrow, and finishes in under 90 s.
  - Edit checks `task.wait()` every ~4,000 items in a long walk.
- **The test hold:** while `ReplicatedStorage.OK` has the `WalkInsPaused` attribute (true or false), the join wake-up and the respawn-in-room rule don't move anyone, so the existing suite keeps starting at the hub spawn. Tests drive the wake-up through the hook's `WakeUp`.
- **Inputs, not edits:**
  - The bedroom comes from the bedroom pipeline: `Env_bedroom_starter`, assembled at (4000, 0, 0), with `Bedroom_Setup`'s Spawn, Sockets, Station and `bd_room__bd_door` + `ExitPrompt`. Never edit `../ok_assets` or the imported parts. Rooms clones it.
  - The home and real studio assets are the user's imports. This plan builds against code-built stand-ins (Task 2) that honour the asset contract below.
  - Task 15 waits for the bedroom import.
- **Standing limits:** never save or publish the place; no uploads; no Robux; no free-model scripts; don't change the light cap or another session's imports; never flip `Config.Data.UseStoreInStudio`. Streaming is a place setting: Task 2's build script sets it in Edit, and the user's save keeps it.

## Review Focus

1. **The owner leaves while guests or a visitor are in their rooms.**
   - Guests are moved to the hall spawn before the plot is destroyed.
   - The owner's in-flight walk-in ends with no stat change.
   - The slot frees, and the next joiner gets a clean plot.
   - Test: t101a (the hook's `Release` with a stand-in guest) and t104a (Release mid-walk).
2. **A 13th player, or two joins in the same tick.**
   - Each player gets a distinct slot.
   - A player arriving when every slot is taken gets no plot, wakes at the hub spawn with the "building is full" toast, and nothing errors.
   - Test: `room_rules_spec` (Claim) and t101a (Release the player, `Fill(12)`, then their Claim answers nil and they stay at the hub).
3. **Saved items that no longer fit:**
   - an unknown id
   - a gear item no longer owned
   - out of bounds
   - overlapping
   - over the limit
   - a string coordinate
   - a room you don't own

   Each one is dropped quietly on load and never breaks the build or counts against the limit. Test: `room_rules_spec` (Repair) and t102_check.
4. **Friends-only when `IsFriendsWith` errors or takes long.** It counts as not a friend; the press answers "friends only" within 2 s; other presses aren't blocked. Test: `room_rules_spec` (CanEnter) and t113a (the friend check stubbed to error and to sleep).
5. **A door, death or respawn while seated or with the beat maker open.**
   - A door press unseats first.
   - A respawn while inside your plot puts you back in your bedroom.
   - The beat maker closes when you teleport (CloseDistance).
   - Test: t101a (seated door press, respawn in the plot) and t101b (the DAW window is gone after the door).

---

## Shared shapes

- **Config.Rooms** (Task 1). Room-local coordinates have their origin on the floor at the room's centre, with north as −Z. An anchor is `{ x, y, z, nx, nz }`: a position and a horizontal facing.
  ```
  Config.Rooms = {
    Slots = 12, PlotOrigin = { 6000, 0, -2000 }, PlotCols = 4, PlotSpacing = 2000,
    Template = "Env_bedroom_starter", PlayCooldown = 1, Edit = { burst = 5, every = 0.2 }, ItemParts = 12,
    Landing = { length = 110, width = 8 },             -- plot-local x 0..110, z 0..8; its front door at x 0
    DoorModes = { "open", "friends", "locked" }, DoorDefault = "friends",
    Kinds = {                                          -- ladder order; `gate` = the Config.Career.Gates id (none: always owned)
      bedroom = { order = 1, at = { 10, -8 }, size = { 12.36, 14.83 }, limit = 6, plaques = 3, posters = 0, booth = false,
        grid = { { -1, -0.5, 2, 2 }, { 3, 0.5, 5.8, 3 }, { -6, -7, -3, -1 } },   -- first guesses, tuned in Task 9's capture
        anchors = { Entrance = { 4.1, 0, 5.6, 0, -1 }, VisitorSpot = { 1.6, 0, -0.8, -1, 0 }, CritterSpot = { -0.2, 0, 0.6, 0, -1 },
          Plaque_1 = { 6.1, 5.4, -4.4, -1, 0 }, Plaque_2 = { 6.1, 5.4, -2.2, -1, 0 }, Plaque_3 = { 6.1, 5.4, 0, -1, 0 } } },
      home = { order = 2, gate = "home_studio", at = { 40, -10.6 }, size = { 24, 20 }, limit = 16, plaques = 6, posters = 4, booth = true },
      real = { order = 3, gate = "real_studio", at = { 85, -14.6 }, size = { 36, 28 }, limit = 24, plaques = 10, posters = 6, booth = true },
    },
    Speakers = {   -- tier 1 = the laptop's own speakers (no gear); eq = { low, mid, high } dB on an EqualizerSoundEffect
      { gear = nil,            rolloff = { 2, 8 },   volume = 0.5, eq = { -20, -4, 0 } },
      { gear = "spk_monitors", rolloff = { 6, 24 },  volume = 1.0, eq = { -6, 0, 0 } },
      { gear = "spk_studio",   rolloff = { 10, 45 }, volume = 1.4, eq = { 0, 0, 2 } } },
    PosterWords = { ... }, PosterColors = { ... }, PosterStyles = 3,   -- Task 0 §9 (12 words, 8 colours)
  }
  ```
  `home` and `real` also carry `grid` and `anchors` for their stand-ins (Task 2 writes them). An imported asset brings its own anchors, and the Config ones fill only the gaps.
- **The asset contract.** It is what any room kind's model must provide, and the stand-ins provide all of it.
  - A `Model` with `OK_Room` set, `ModelStreamingMode` Atomic, its pivot at the floor centre, north −Z, and its floor top at y 0.
  - One `BasePart` with attribute `RoomDoor = true` and a child `ProximityPrompt` named `ExitPrompt` on its south wall.
  - One Station: `OK_Interactable`, `Kind = "Station"`, `StationName`.
  - A `BasePart` named `Spawn` facing into the room.
  - Attachments, each found by name: `Entrance`, `VisitorSpot`, `CritterSpot`, `Desk_Speaker_L`, `Desk_Speaker_R`, `Plaque_1..n`, and for the home and real rooms `Poster_1..n`, `BoothSpot` and `BoothCam`.
  - At most 1 light, and a budget of ≤ 56 MeshParts and ≤ 30,000 triangles.
  - The room's free floor goes into `Config.Rooms.Kinds.<kind>.grid` when the asset lands.
- **`prof.career.home`** (Task 3) = `{ v = 1, door = "open" | "friends" | "locked", items = { [kind] = { item, ... } } }`.
  - A floor item is `{ id, x, z, r }`: whole room-local cells, with `r` 0..3 quarter turns.
  - A wall item (a poster) is `{ id = "poster", slot = n, w, c, s }`: word, colour and style indices.
  - Defaults: `{ v = 1, door = Config.Rooms.DoorDefault, items = {} }`.
- **Data/RoomCatalog** (Task 1). An item is `{ id, kind = "floor" | "wall", size = { w, d } (cells), rooms = { kinds }? (nil = any), max = n?, unlock = { gear = id } | { first = id } | { tier = id } | { room = kind } | nil (always), parts = { Part } }`, where a Part has VisitorLooks' shape (`n, s, cf, c, sh, m`) and there are at most 12 parts. Launch items, with their names in Task 0 §6:
  - decor: rug, plant, beanbag, crate of records, low shelf, floor lamp (a Neon shade, no Light), keyboard stand
  - gear-linked: `kit_tape` tape machine, `kit_iron` drum machine, `voice_pluck` pluck synth, `voice_chime` chime bells
  - home and real only: `closet` (max 1 a room), `poster` (wall), couch, mic stand
- **RoomRules (pure; Task 1 unless noted):**
  - `PlotOrigin(k, cfg) -> x, y, z`, which is `(6000 + ((k-1) % 4) * 2000, 0, -2000 + ((k-1) // 4) * 2000)`
  - `Claim(slots, n) -> k?`, the lowest free slot, where `slots[k]` is a user id or nil
  - `Owned(gates, kinds) -> { kind, ... }`: in ladder order, the bedroom always, plus each kind whose `gate` is true
  - `Box(kind, cfg, k) -> { x0, z0, x1, z1 }` (world, the interior)
  - `Cells(item, entry) -> { { cx, cz } }`
  - `Fits(items, item, kindCfg, catalog, unlocked, kind, ignoreIndex?) -> ok, reason`. Reasons:
    - "unknown"
    - "locked"
    - "room" (a kind the item isn't allowed in)
    - "bounds"
    - "overlap"
    - "limit" (counting posters)
    - "max"
    - "rot"
    - "slot" (a wall item's slot is out of range or taken)
    - "design"
  - `Repair(home, owned, cfg, catalog, unlocked) -> home, dropped`
  - `Unlocked(catalog, have) -> { [id] = true }`, where `have = { gear = set, firsts = set, tier = index, rooms = set }`
  - `Plaques(disco, weekly, n) -> { entry }`, newest first: hits, then trackone and placements, then weekly ones
  - `SpeakerTier(gear, speakers) -> 1..3`
  - `CanEnter(mode, isOwner, isFriend) -> bool`
  - `NextDoorMode(mode, modes) -> mode`
  - `PosterOk(design, cfg) -> bool`
  - `DayOneFloor(economy) -> { money, followers, level }` (Task 7)
- **WalkInRules.Present(x, y, z, boxes) -> "hub" | "room" | nil, index?** (Task 5): `InHub` first; else inside `boxes[i]` with `0 <= y < 20`.
- **Systems/Rooms (server):**
  - `PlotOf(p) -> k?`, `Owner(k) -> Player?`
  - `BoxesFor(p) -> { box }`: own rooms only, each box carrying its `kind`
  - `PlaceOf(p) -> "hub" | { slot, kind } | nil`
  - `Anchor(p, kind, name) -> CFrame?`, `Station(p, kind?) -> BasePart?` (the bedroom's by default; Day One uses it)
  - `PlayLocal(p, pattern, bpm, swing, kit, voice) -> res` and `StopLocal(p)`
  - Events `Played` (player) and `Rebuilt` (player, k)
  - `Edit(p, action) -> res` and `State(p) -> state` (Task 9)
  - `Booth(inst) -> { spot = CFrame, cam = CFrame } | false | nil` (Task 12: false = a room with no booth, nil = the hub)
- **Player attributes:** `InPlot` (the slot whose plot you stand in, else 0), `PlotSlot` (your own, else 0). **Room model attributes:** `OwnerId`, `OwnerName`, `RoomKind`, `Plot`.
- **Remotes** (`build/19_rooms.lua`): RemoteFunction `Room_Get` and `Room_Edit`, RemoteEvent `Room` (server → client: `"state"`, `"refused"`). Runtime folder `ReplicatedStorage.OK.RoomPlaying` holds one Folder `Plot_01`..`Plot_12` per slot, with NowPlaying's attribute names plus `Tier` and `Room`.
- **Hook** `ServerScriptService.OK._StudioRoomsHook` (Studio, running). `hook:Invoke(cmd, uid, a, b)`:
  - `Plot` → `{ slot, origin = { x, y, z }, rooms = { kind } }`
  - `Home`, `SetHome(home)` (a copy, through Repair; returns what it kept), `Reset` (home defaults, plot rebuilt)
  - `WakeUp`, `Enter(slot, asFriend)` (the hall door's path), `Exit(kind)`, `Respawn`
  - Every untagged Rooms prompt has a command that runs its real handler, because a server test can't press a prompt: `Exit` (RoomExit), `Door` (the owner's cycle, Task 14), `Closet` (Task 12), `Decorate` (Task 10)
  - `MayUse(inst)`, which returns `InteractionService.MayUse(player, inst)` (Task 6)
  - `Release`, `Claim`, `Fill(n)` (claims and builds stand-in plots for fake owners in n free slots), `Unfill`
  - `Edit(action)`, `Play(pattern, bpm)`, `Anchor(kind, name)` → CFrame, `InPlot`, `Guest(slot)` (a stand-in Model as a pretend guest in that plot; returns it)
  - `FriendCheck(fn | nil)` (Task 14 stub)

## Rulings in this plan

The full list of Claude's calls (plan) is at the end. Each line carries its reason.

---

### Task 0: Copy

**Files:**
- Create: `research/rooms/copy_2026-11-12.md`

**Interfaces:**
- Produces: the copy doc's sections §1–§11, which every later task cites by number.

- [ ] **Step 1: Write the doc, one section per task area.**
  - §1 The building: the hub door sign and prompt, the hall sign, the empty door plate ("STUDIO 07"), the prompts Enter, Leave and Go to your room, and the toasts: locked, friends only, building full, "{name} left the server".
  - §2 Room names and gate descs: BEDROOM, HOME STUDIO, REAL STUDIO (draft names), and the landing's locked-door sign "HOME STUDIO · LOCKED".
  - §3 The station owner toast ("{name}'s laptop. only they can use it.") and the rack prompt (Action "Open gear rack", Object "Your laptop").
  - §4 Speaker gear names and descs; "🔊 ON SPEAKERS"; one status line per tier ("On your laptop speakers · only people right next to you hear it", …).
  - §5 Gifts: three existing outcomes (one sponsor signing = a deal, one family outcome = a gift, one STUDIO ALERT phone outcome = a find) with their ids, the old text, the new text naming the monitors, and the toast "NEW GEAR: {gear}".
  - §6 Catalog item names (Shared shapes list), the Decorate prompt, edit-bar labels, and every refusal reason as a sentence.
  - §7 Plaque formats (hit, placement, trackone through `LifeRules.DiscoText`; "WEEKLY SINGLE · {title}").
  - §8 The closet prompt, the "YOUR CLOSET" header and the empty-closet line.
  - §9 `PosterWords` (12 short CAPS words), 8 poster colours (RGB), 3 style names, and the designer labels.
  - §10 Door modes OPEN / FRIENDS ONLY / LOCKED and the owner's prompt "Door: {MODE}".
  - §11 The approval list: one table of every line above.
- [ ] **Step 2: Scan** against t40, t50 and the BLOCK words. CAPS headlines; no name typed outside `{name:<id>}`; every gift outcome id exists in `Data/WalkIns`.
- [ ] **Step 3: Commit** `R-T0: rooms copy`.

### Task 1: Pure rules, Config and the catalog

**Files:**
- Create: `src/ReplicatedStorage/OK/Modules/RoomRules.lua`, `src/ReplicatedStorage/OK/Data/RoomCatalog.lua`, `spec/room_rules_spec.lua`
- Modify: `src/ReplicatedStorage/OK/Config.lua` (add `Config.Rooms` after `Config.Monitors`, `:261`)

**Interfaces:**
- Produces: every RoomRules function in Shared shapes except `DayOneFloor`; `Data/RoomCatalog` with `Items` and `ById`; `Config.Rooms`.

- [ ] **Step 1: Write the failing spec** `spec/room_rules_spec.lua`. It holds a literal copy of `Config.Rooms` (Task 2's t100_check pins it to live Config).
  - **PlotOrigin:** k 1 → (6000, 0, −2000); 4 → (12000, 0, −2000); 5 → (6000, 0, 0); 12 → (12000, 0, 2000). Any two slots are ≥ 2000 apart.
  - **Claim:** `{}` with n 12 → 1; slots 1..3 taken → 4; slot 2 freed → 2; all 12 taken → nil.
  - **Owned:** gates `{}` → `{ "bedroom" }`; `{ home_studio = true }` → `{ "bedroom", "home" }`; `{ real_studio = true }` without home → `{ "bedroom", "real" }`; `{ studio_two = true }` changes nothing.
  - **Fits** (bedroom, catalog rug 2×2, plant 1×1):
    - an item inside grid area 1 → ok
    - one cell outside every area → "bounds"
    - on another item's cell → "overlap"
    - the 7th bedroom item → "limit"
    - `r = 4` or 1.5 → "rot"
    - an unknown id → "unknown"
    - `tape_machine` without `kit_tape` → "locked"
    - `closet` in the bedroom → "room"
    - a 2nd closet in home → "max"
    - poster slot 5 in home (posters 4) → "slot"
    - a poster word index 13 → "design"
    - a rotated 2×1 item occupies swapped cells
  - **Repair:** every case below is dropped and named in `dropped`, and the rest are kept in order.
    - a home with junk (`items = "x"`, `door = "wide"`) → defaults
    - an item list mixing a good item with a string coordinate, an unknown id, a locked gear item, an overlapping second item, items past the limit, and items in `home` while home isn't owned
  - **Size bound:** a maximal home (24 real items, 6 posters) JSON-encodes (a minimal encoder in the spec) under 4,096 bytes.
  - **Unlocked:** gear `{ kit_tape = true }` opens `tape_machine`; a `first`, a `tier` and a `room` rule each open only when held.
  - **Plaques:**
    - disco with 2 hits, 3 placements and 1 trackone plus 2 weekly, n 3 → the 2 hits (newest first), then the newest placement or trackone
    - n 10 → all 8 in that order
    - nil inputs → `{}`
  - **SpeakerTier:** `{}` → 1; `{ spk_monitors = true }` → 2; `{ spk_studio = true }` → 3; both → 3.
  - **CanEnter:** the full table of `{ open, friends, locked }` × owner × friend. The owner always enters; open admits anyone; friends admits friends; locked admits only the owner.
  - **NextDoorMode:** open → friends → locked → open; junk → friends.
  - **PosterOk:** in-range indices only.
  - **Catalog:** every item has 1..12 parts, ≤ 1 Neon part and no Light; its size matches its parts' footprint within 0.5 stud; ids are unique; every `unlock.gear` names a gear id in a literal list kept in the spec.
- [ ] **Step 2: Run** `sh tools/spec.sh room_rules` → FAIL (no module).
- [ ] **Step 3: Implement** the functions, `Config.Rooms` (Shared shapes; Task 0's words and colours) and the catalog recipes (built from parts, in VisitorLooks' flat-array style).
- [ ] **Step 4: Run** `sh tools/spec.sh` → every spec PASSES.
- [ ] **Step 5: Commit** `R-T1: room rules, Config.Rooms and the launch catalog`.

*Studio: none.*

### Task 2: Plots, the shared building, the wake-up and streaming (§4.1, §4.13)

**Files:**
- Create: `build/19_rooms.lua` (Edit, STRUCTURE, idempotent, `OK_Build = "19_rooms"`). It makes:
  - the remotes and `RS.OK.RoomPlaying.Plot_01..12`
  - `Workspace.OK_Rooms.Hall`: 12 doors with a name plate, a neon strip and an untagged `EnterPrompt` each, a `HallSpawn` and a `HubDoor`. Its origin is computed like `room_test.lua:295` (east of every top-level Model's box + 40). Every part is anchored, with 0 lights.
  - the corridor's `RoomsDoor` on the inside face of `Wall_Corr_W` at (0.3, 4, 5) with an untagged prompt
  - `workspace.StreamingEnabled = true`, `StreamingMinRadius 64`, `StreamingTargetRadius 1024`, `StreamOutBehavior LowMemory`
  - every top-level Model already in Workspace except `Env_bedroom_starter` set to `Persistent`, with `OK_Rooms` Persistent too
- Create: `src/ReplicatedStorage/OK/Modules/RoomBuild.lua`:
  - `StandIn(kind, kindCfg) -> Model`: a code-built shell with every contract item and one PointLight (0.25, range 14)
  - `Landing(cfg, owned, kinds) -> Model`: a front door with an untagged `LeavePrompt`, and per kind a door frame with an untagged `RoomPrompt` (or the locked sign); `OK_Room = "landing"`, 0 lights
  - `Anchors(room, kindCfg)`: adds each missing contract Attachment from `kindCfg.anchors`
  - `Plot(k, owned, cfg, template) -> Model`
- Create: `src/ReplicatedStorage/OK/Systems/Rooms.lua`:
  - slot claim on join and release on leave
  - the plot under `Workspace.OK_Plots`
  - the wake-up and the respawn rule
  - the hall door, the landing doors, the room exit and the hub door
  - the presence loop (1 s) that sets `InPlot` / `PlotSlot`
  - the hook
- Modify: `src/ServerScriptService/OK/Services/InteractionService.lua`: add `M.Adopt(root)`. It clears `OK_Hooked` on every tagged BasePart under `root` and attaches the kind's SFX, as `attachSfx` does (:105-116). Rooms builds each plot with Parent nil, calls `Adopt`, then parents it **once**, straight into `Workspace.OK_Plots`, so the added-tag signal (:193) hooks each part. Parenting anywhere outside Workspace first would make `hook` return early (:162) and never run again. Today a clone keeps `OK_Hooked` and is never hooked (:164-165).
- Create: `build/t100_check.lua`, `build/t101a_play_server.lua`, `build/t101b_play_client.lua`

**Interfaces:**
- Consumes: `RoomRules.PlotOrigin`, `Claim`, `Owned`, `Box`; `Config.Rooms` (Task 1).
- Produces: `Rooms.PlotOf`, `Owner`, `BoxesFor`, `PlaceOf`, `Anchor`, `Station`, `Rebuilt`; `InteractionService.Adopt(root)`; the attributes `InPlot` and `PlotSlot`; the room attributes; the hook commands `Plot`, `Reset`, `WakeUp`, `Enter`, `Exit`, `Respawn`, `Release`, `Claim`, `Fill`, `Unfill`, `Anchor`, `InPlot`, `Guest`.

The template is `ServerStorage.<Config.Rooms.Template>`, else `Workspace.<Config.Rooms.Template>`, which Rooms' Init reparents to ServerStorage. With neither, the bedroom is `RoomBuild.StandIn("bedroom")`. A plot is:
- the landing at the plot origin
- each owned kind cloned or stood-in at `origin + at`, with `OwnerId`, `OwnerName`, `RoomKind` and `Plot` set, `RoomBuild.Anchors` run, then `InteractionService.Adopt`, and the `ExitPrompt` enabled
- parented to `Workspace.OK_Plots`, Atomic

Every teleport does the same three things: `RequestStreamAroundAsync(target, 10)` in a pcall, unseats first (`Humanoid.Sit = false`, wait 0.3 s), then `PivotTo(target + 3 up)`. A refusal toasts (copy §1).

- [ ] **Step 1: Write the failing tests.**
  - **t100_check (Edit):**
    - `OK_Rooms.Hall` has `Config.Rooms.Slots` doors, each with an `EnterPrompt`, plus `HallSpawn` and `HubDoor`; the corridor `RoomsDoor` has its prompt; 0 Lights under `OK_Rooms`; every part anchored
    - the remotes `Room_Get`, `Room_Edit` and `Room` exist; `RoomPlaying` has 12 folders
    - streaming is on with the four values; `OKStudio`, `OK_Gates` and `OK_Rooms` are Persistent
    - each `RoomBuild.StandIn(kind)` for bedroom, home and real carries every contract item by name, `OK_Room`, ≤ 1 Light and Atomic
    - `RoomBuild.Anchors` on a bare Model adds exactly the missing ones
    - the hub counts are unmoved: `RoomScope` lights ≤ 61, 12 interactables, 2 stations
    - the spec's literal `Config.Rooms` equals live Config
    - marker `T100 OK`
  - **t101a_play_server:**
    - `Plot(uid)` gives slot 1, its origin `PlotOrigin(1)` and rooms `{ "bedroom" }`; the plot model has a landing and a bedroom with `OwnerId == uid`
    - the bedroom's Station has its `SFX` (Adopt) and its prompt opens the beat maker (`InteractionService._RunHandler("Station", p, station)` returns acted)
    - `WakeUp` → the player stands within 3 studs of the bedroom `Spawn`, `InPlot == 1`
    - `Exit("bedroom")` → the landing
    - the landing's `LeavePrompt` path → `HallSpawn`'s door 1
    - `Enter(1)` → the landing
    - the hub door → the corridor
    - seated in the bedroom chair, a door press unseats and moves
    - `Respawn` while in the plot → the bedroom Spawn; `Respawn` in the hub → the hub spawn
    - `Guest(1)` placed in the plot, then `Release` → the guest model is at the hall spawn, and `Plot(uid)` is nil; then `Claim` → slot 1 again, rebuilt
    - Release the player, `Fill(12)`, then `Claim` → nil, the player gets the "full" toast and stays at the hub, and nothing errors; `Unfill`, then `Claim` → slot 1
    - `Unfill`
    - marker `T101A PLAY OK`
  - **t101b_play_client:** after a server door move, the client's `OK_DAW` window is closed; `InPlot` reads 1 inside the plot and 0 at the hub; the plot's bedroom model has streamed in within 3 s of the move (`RequestStreamAroundAsync`).
- [ ] **Step 2: Controller red:** `--edit t100_` and `--play t101` → FAIL.
- [ ] **Step 3: Implement** the files above.
- [ ] **Step 4: Controller.**
  1. Run `build/19_rooms.lua` in Edit.
  2. Sync `Modules/RoomRules`, `Data/RoomCatalog`, `Modules/RoomBuild`, `Systems/Rooms`, `Services/InteractionService` and `OK/Config`.
  3. `--edit t100_ t03 t04 t05 t07 t88 09_qa` and `--play t101` → PASS.
  4. Then the **full suite with streaming on**: no new failures; one rerun per flake.
- [ ] **Step 5: Commit** `R-T2: plots, the shared building, waking up in your bedroom, streaming`.

### Task 3: Saving your rooms (§4.4)

**Files:**
- Modify: `src/ReplicatedStorage/OK/Systems/Rooms.lua`:
  - `state(p)`: `prof.career.home` defaulted and repaired through `RoomRules.Repair` with the owned rooms and `Unlocked(have)`, on load and on every rebuild
  - the hooks `Home` and `SetHome`
  - a rebuild when the player's `CareerGates` attribute changes the owned set. A Career Reset that keeps the gates is covered by the hook's `Reset`, and `state()` re-defaults a missing `home` on its next read
- Create: `build/t102_check.lua` (Edit: fresh `DataService` with a fake store, as t70/t75 do, plus Rooms' `_SetCtxForTest`)

**Interfaces:**
- Produces: `Rooms.state` (internal), the hooks `Home` and `SetHome`. Nothing else writes `prof.career.home`.

- [ ] **Step 1: Write the failing test** `t102_check`:
  - **(a)** a bare v5 profile loaded through DataService has 8 career keys and no `home`; after Rooms' state it has `home = { v = 1, door = "friends", items = {} }`
  - **(b)** a profile with `home.items.bedroom` holding 2 good items and 1 junk item survives HttpService JSON key for key; the junk is dropped on load and `dropped` names it
  - **(c)** items under `home` while `career.gates.home_studio` is missing are dropped
  - **(d)** `ClientProfile` keeps `career.home`, and `prof.life` / `prof.hints` stay out as before
  - **(e)** `SchemaVersion == 5`
  - **(f)** a Career Reset (`prof.career = Rules.Defaults()`) makes the next state() default it again
  - marker `T102 OK`
- [ ] **Step 2: Controller red** `--edit t102_` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Controller:** sync `Systems/Rooms`; `--edit t102_ t41 t70 t75` and `--play t101` → PASS.
- [ ] **Step 5: Commit** `R-T3: rooms saved nested in prof.career (v5)`.

### Task 4: Unlocking rooms through the career gates (§4.5)

**Files:**
- Modify: `Config.lua`, `Config.Career.Gates` (:142-145). Two new room gates go **first**, so the Career tab lists your ladder before THE HALL:
  - `{ id = "home_studio", kind = "room", room = "home", name = <§2>, desc = <§2>, needs = { placements = 1, followers = 1000 }, cost = 1500 }`
  - `{ id = "real_studio", kind = "room", room = "real", name = <§2>, desc = <§2>, needs = { placements = 3, followers = 20000 }, cost = 8000 }`

  The `room` field marks a gate as a rung of your own ladder. THE HALL has none.
- Modify: `Systems/Rooms.lua`: on the `CareerGates` change, rebuild the plot with the new room, and the landing door turns from the locked sign to `RoomPrompt`.
- Modify: `build/t41_play_server.lua:32` and `t41b_play_client.lua:15` (`#st.gates == 2` → 4), `t41_check.lua:169` (→ 4), `t45b_play_client.lua:73` (`count("Gate_") == 2` → 4).
- Create: `build/t103a_play_server.lua`

**Interfaces:**
- Consumes: `Career.Unlock` unchanged (`Systems/Career.lua:308-334`: needs + cost through `CareerRules.Check`; ownership `prof.career.gates[id] = true`).
- Produces: the gate ids `home_studio` and `real_studio`. The people plan's Task 6 (sim) and Task 9 (big-names gate) read `prof.career.gates.home_studio` through `Career.Get`.

- [ ] **Step 1: Write the failing test** t103a:
  - `Career Set` with `{ placements = 1, followers = 1000, money = 1500 }`, then `Unlock("home_studio")` → ok
  - `Plot(uid).rooms` = `{ "bedroom", "home" }`, and the home model (a stand-in) has `OwnerId`
  - the landing's home door has a `RoomPrompt` and its path moves you into home's `Spawn`
  - money spent 1500
  - with the needs unmet → "needs", with no rebuild (the `Rebuilt` count is unchanged)
  - `real_studio` likewise
  - `Career Reset` → the plot is back to the bedroom only
  - marker `T103A PLAY OK`
- [ ] **Step 2: Controller red** `--play t103a` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Controller:** sync `OK/Config` and `Systems/Rooms`; `--edit t41_ t46` and `--play t103a t41 t45 t73` → PASS.
- [ ] **Step 5: Commit** `R-T4: the home studio and real studio unlock through Config.Career.Gates`.

### Task 5: Visitors find you in your rooms (§4.2)

**Files:**
- Modify: `Modules/WalkInRules.lua`: add `M.Present(x, y, z, boxes)`. `InHub` (:568-572) stays.
- Modify: `spec/walkin_rules_spec.lua`.
- Modify: `Systems/WalkIns.lua`. `inHub(p)` (:151-158) becomes `present(p)` (Rooms' `PlaceOf`). It is used at:
  - `walkIn` :738
  - `schedule` :831
  - `tick` :878, including the heal
  - `DueWithin` :926
  - `upkeep` :948
  - `spawnNow` :1006
  - `spawnExtra` :1021

  The rest of the change:
  - `rec.place` holds the place the visit started in.
  - Upkeep ends the visit "left_hub" when the target is no longer in that place.
  - In a room, `walkIn` spawns with `opts.route = { Entrance, VisitorSpot }` (Rooms' `Anchor`), `opts.present` and `opts.floorY = 0`.
  - A critter spawns with `opts.at` = `CritterSpot`.
- Modify: `Modules/Visitor.lua`. It is 5d's rewrite, so cite by function name. Lines are as on disk 11-12.
  - `M.Spawn` (:121) gains `opts.route`: when it is given, he starts at `route[1]` and walks the chain, arriving at its last point facing the player.
  - `Handle:_aim` (:157) isn't used on a route, because it routes by `WalkInRules.RoomOf(x)`, which reads x ≥ 80 as the hub booth.
  - `Leave` walks the route back and vanishes at `route[1]`.
  - `Handle:_tick` (:227) and `Spot:_tick` (:355) call `opts.present(pos)` instead of `InHub` when it is given.
  - `M.SpawnSpot` (:312) gains `opts.at`, a CFrame: the critter sits there instead of on `Coffee_Top`.
- Create: `build/t104a_play_server.lua`

**Interfaces:**
- Consumes: `Rooms.PlaceOf`, `BoxesFor`, `Anchor` (Task 2). Rooms is required lazily, inside functions.
- Produces: `WalkInRules.Present`; `Visitor.Spawn` opts `route`, `present` and `floorY`; `SpawnSpot` opts `at`.

- [ ] **Step 1: Write the failing tests.**
  - **walkin_rules_spec:** `Present(30, 3, 0, {})` → "hub"; inside box 2 at y 3 → "room", 2; y 25 inside the box → nil; outside both → nil; the hub wins over an overlapping box.
  - **t104a (play, held, through the hooks):**
    - `WakeUp`; `SetRemaining(0)` and `Poke` → a visit starts while the player is in the bedroom (presence counts there)
    - the visitor model's first pose is within 1 stud of `Entrance`, and he arrives within 1 stud of `VisitorSpot` within 15 s
    - the `arrive` payload is sent
    - the player walks (teleports) to the landing → the visit ends and a `leave` is sent
    - the pigeon card (`Spawn` with its id) → the figure is within 1 stud of `CritterSpot`
    - the heal pays in the bedroom (`Heal` hook after Aura −20)
    - `Release` mid-walk → the visit ends with no stat change
    - the player teleported into another plot (`Fill(1)` builds one for a fake owner) → `DueWithin` false
    - marker `T104A PLAY OK`
- [ ] **Step 2:** `sh tools/spec.sh walkin_rules` → FAIL. Controller red: `--play t104a` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4:** Specs PASS. Controller: sync `Modules/WalkInRules`, `Systems/WalkIns`, `Modules/Visitor` and `Systems/Rooms`; `--play t104a t42 t43 t52 t55 t56 t61 t76 t81` → PASS.
- [ ] **Step 5: Commit** `R-T5: walk-ins count down and walk in to your rooms`.

### Task 6: Your station and the rack from your laptop (§4.3, §4.0 C)

**Files:**
- Modify: `InteractionService.lua`: add `M.MayUse(player, inst) -> bool, ownerName?`. A tagged interactable inside a room (`RoomScope.RoomOf(inst)`) answers only that room's `OwnerId`; everything else is true. `hook` (:161-186) calls it before the handler, and on false sends the §3 toast with `OwnerName`, with no sound and no `Used`.
- Modify: `Systems/DAW.lua`:
  - Add `M.StationOf(player) -> inst?, room?`, the same reach as `AtStation` (:81-95). It accepts the hub chair, the hub screen and hub Stations, plus Stations in a room whose `OwnerId` is the player.
  - `AtStation` becomes `StationOf(player) ~= nil`. Contracts :247 and DAW :200 are unchanged.
  - `OpenFor` (:127-142) adds `room = <kind or nil>` to the `OpenDAW` payload.
- Modify: `Systems/Stations.lua` (:9-11): refuse a non-owner, as a second guard.
- Modify: `Modules/RoomBuild.lua`: each room gets an invisible part `RackSpot` beside its Station, tagged `Kind = "GearRack"`, with a prompt (§3; KeyboardKeyCode F, GamepadKeyCode ButtonY). Gear's handler (`Gear.lua:163-165`) opens the Gear tab.
- Create: `build/t105a_play_server.lua`, `build/t105b_play_client.lua`

**Interfaces:**
- Produces: `InteractionService.MayUse`; `DAW.StationOf`; the `OpenDAW` payload field `room`; `Rooms.Station(p, kind?)`, for Day One.

- [ ] **Step 1: Write the failing tests.**
  - **t105a:**
    - the owner at their bedroom Station: `StationOf` returns it with the bedroom model; `_RunHandler("Station")` acts; `_RunHandler("GearRack", p, rackSpot)` acts and sends `OpenPanel` with tab Gear
    - with `OwnerId` set to another id (the hook staging): the hook's `MayUse` on the Station and the RackSpot answers false with the owner's name, and `StationOf` is nil within reach of that laptop
    - `Contracts` Deliver answers "away"; `DAW_Broadcast` answers "away"
    - the hub PC still counts for anyone
    - the hub interactable count is still 12 (RackSpot is inside the room)
    - marker `T105A PLAY OK`
  - **t105b,** at 667×375, 771×390 and 844×390:
    - pressing the rack prompt (`InputHoldBegin` / `InputHoldEnd`) opens the panel on the Gear tab, and the prompt uses F / ButtonY
    - with the server staging `OwnerId` as another id, pressing the Station's prompt opens no beat maker, and the owner toast shows
- [ ] **Step 2: Controller red** `--play t105` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Controller:** sync `Services/InteractionService`, `Systems/DAW`, `Systems/Stations`, `Modules/RoomBuild` and `Systems/Rooms`; `--edit t07 09_qa t14_` and `--play t105 t10 t12 t19 t41c t84` → PASS.
- [ ] **Step 5: Commit** `R-T6: your station is yours; the gear rack opens from your laptop`.

### Task 7: Room speakers and the monitor upgrade track (§7 D10, §6 pacing)

**Files:**
- Modify: `Config.lua` `Config.Gear`. Two rows go **before `fit_cuban`**, because t41_check :46-48 keeps the fits just before `plate_legend`:
  - `{ id = "spk_monitors", name = <§4>, kind = "speakers", tier = 2, price = 500, level = 2, needs = { followers = 200 }, desc = <§4> }`
  - `{ id = "spk_studio", name = <§4>, kind = "speakers", tier = 3, price = 3000, level = 5, needs = { placements = 2, followers = 5000 }, desc = <§4> }`

  Neither has a `feature`.
- Modify: `build/t41_play_server.lua:32` and `t41b_play_client.lua:15` (`#st.gear == 5` → 7).
- Modify: `Modules/RoomRules.lua`: add `DayOneFloor`. Modify `spec/room_rules_spec.lua`.
- Modify: `Systems/Rooms.lua`:
  - `PlayLocal`: writes `RoomPlaying.Plot_<k>` (Active, Token, Beat, BPM, Swing, Kit, Voice, StartAt = server time + 0.5, Loops and EndsAt from `MonitorService.LoopsFor` (:19-27), OwnerId, Room, Tier). It ends itself at EndsAt and replaces any play under way. The cooldown is `PlayCooldown`.
  - `StopLocal`; the `Played` event.
  - Speaker models (`RoomItems.Speakers(tier)`) on `Desk_Speaker_L/R` for tier ≥ 2, rebuilt on the `Gear` attribute change.
- Create: `src/ReplicatedStorage/OK/Modules/RoomItems.lua` (`Speakers(tier) -> Model?` now; Task 9 adds `Build`).
- Modify: `Systems/DAW.lua` `tryBroadcast` (:192-225). The room branch replaces the `AtStation` check at :200, after the pattern checks and **before** the cypher reservation at :201, so a cypher in the hub never blocks your speakers. A room station (`StationOf`'s room) returns `Rooms.PlayLocal(...)`: `{ ok = true, room = true, tier, position = 0 }`. `DAW_Broadcast` doesn't fire `BroadcastTried` for a room play (:226-230), because that feeds Funnel step 6, airing. `DAW_Stop` (:232) also calls `Rooms.StopLocal`.
- Modify: `Systems/Tour.lua` Init (:73-82): `Rooms.Played` → `Advance(player, "monitors")`, so a bedroom player can finish the tour before Day One replaces it.
- Modify: `Modules/DAWEngine.lua` `setup` (:39-49): add `opts.soundGroup` → `s.SoundGroup`.
- Create: `src/StarterPlayer/StarterPlayerScripts/OK/RoomClient.client.lua`, with the room listener.
  - One Engine. It plays the `RoomPlaying` folder of the plot in `InPlot` from the server time, as DAWClient's listener does (:594-641).
  - Sounds parent to the speaker parts, or the room's Station at tier 1.
  - It uses the tier's `rolloff` and `volume`, and a per-tier `SoundGroup` under SoundService with an `EqualizerSoundEffect` (`eq`).
  - `MuteMonitors` mutes it. It stops when `InPlot` changes.
- Modify: `DAWClient.client.lua`:
  - With `payload.room`, the `Monitors` button reads §4's "🔊 ON SPEAKERS". The button is found by name; `Modules/DAWUI` is untouched, since it is Aku's design area.
  - `OnMonitors` (:518-535) shows §4's tier status for `res.room` and stops the local preview.
- Create: `build/t106a_play_server.lua`, `build/t106b_play_client.lua`

**Interfaces:**
- Consumes: `DAW.StationOf` (Task 6), `RoomRules.SpeakerTier` (Task 1).
- Produces: `Rooms.PlayLocal`, `StopLocal`, `Played`; `RoomItems.Speakers`; `RoomRules.DayOneFloor(economy) -> { money, followers, level }`; the gear ids `spk_monitors` and `spk_studio`.

- [ ] **Step 1: Write the failing tests.**
  - **room_rules_spec, DayOneFloor:** a **short first session** is the economy_fixture's three level-1 starter requests and nothing else: no daily, walk-in, phone card or FIRE. It uses the sim's 3, 2, 3 star alternation, the delivery feeds, tourXP, activity and beatSave XP, and buys Roll FX + Swing Unit. It ends with money ≥ 500 (1,225 − 600 = 625), followers ≥ 200 (120 + 40 + 120 = 280) and level ≥ 2. So `spk_monitors` (spec literal: price 500, needs followers 200, level 2) is affordable in session 1, and `spk_studio` is out of reach (its needs exceed the floor). This is the §6 pacing line. The people plan's Task 6 measures the same on the 200 recorded careers, with sim day 1 standing in for session 1.
  - **t106a:**
    - in the bedroom with no speaker gear, `Play(P, 120)` → `RoomPlaying.Plot_01` Active with Tier 1 and Room "bedroom"; `Played` fired once; the tour's "monitors" step done; NowPlaying untouched; FIRE for it refused (`Reactions` has nothing airing); no `BroadcastTried`
    - a second play replaces the first (new Token)
    - Stop clears it
    - `GrantGear("spk_monitors")` → two speaker models on the desk sockets and the next play is Tier 2; `spk_studio` → Tier 3
    - a play from the hub laptop goes on the monitors as before
    - marker `T106A PLAY OK`
  - **t106b:**
    - the window opened at the bedroom laptop shows "🔊 ON SPEAKERS"
    - pressing it shows the tier status
    - the listener's sounds parent inside the plot, with the tier's RollOffMaxDistance and a SoundGroup whose EqualizerSoundEffect has the tier's gains
    - each tier's rolloff max is strictly larger than the one before
    - `MuteMonitors` silences it
    - the button is ≥ 44 px, inside the viewport and not overlapping at 667×375, 771×390 and 844×390
- [ ] **Step 2:** Spec FAIL. Controller red `--play t106` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4:** Specs PASS. Controller:
  1. Sync `OK/Config`, `Modules/RoomRules`, `Modules/RoomItems`, `Systems/Rooms`, `Systems/DAW`, `Systems/Tour`, `Modules/DAWEngine`, `OK/RoomClient` and `OK/DAWClient`.
  2. `--edit t21_ t27_ t30_ t40_ t41_ t46` and `--play t106 t10 t12 t16 t19 t22 t23 t41 t84` → PASS.
- [ ] **Step 5: Commit** `R-T7: your room's speakers, from laptop to studio monitors`.

### Task 8: The story hands you upgrades (§7 D10)

**Files:**
- Modify: `Data/WalkIns.lua`: `gift = "spk_monitors"` (or `"spk_studio"`) on the three outcomes in Task 0 §5, with their new text. There are no new cards, so the deck and the pacing are unchanged.
- Modify: `spec/walkins_data_spec.lua`:
  - `gift` is an allowed outcome key, a string from the literal `GIFTS = { spk_monitors = true, spk_studio = true }`, on walk-in and phone outcomes alike
  - exactly the three §5 outcomes carry one
- Modify: `Systems/Gear.lua`: add `M.Grant(player, id) -> bool` (false when owned or unknown; no money; Publish).
- Modify: `Systems/WalkIns.lua` `apply` (:445-478) and `Systems/Phone.lua` `apply` (:182-203): a `gift` → `Gear.Grant`, and when it granted, the "Toast" "NEW GEAR: {name}" (§5).
- Create: `build/t107a_play_server.lua`

**Interfaces:**
- Produces: `Gear.Grant`; the outcome field `gift`.

- [ ] **Step 1: Write the failing tests.**
  - **Data spec:** the rules above.
  - **t107a:**
    - each §5 card forced to its gift outcome (`SetRng`; walk-in `Spawn` + `Choose`, phone `Pop` / `Open` / `Choose`) → `Gear(uid)` owns the gear, the Toast was sent, and money is unchanged by the gift
    - the same outcome again → no second toast, still owned
    - the room's speakers rebuild to the gift's tier
    - t46 still green (no money moved)
    - marker `T107A PLAY OK`
- [ ] **Step 2:** Spec FAIL. Controller red `--play t107a` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4:** Specs PASS. Controller: sync `Data/WalkIns`, `Systems/Gear`, `Systems/WalkIns` and `Systems/Phone`; `--edit t46 t69 t80` and `--play t107a t47 t51 t79` → PASS.
- [ ] **Step 5: Commit** `R-T8: a deal, a gift and a find can hand you monitors`.

### Task 9: Placing your things, server side (§4.6)

**Files:**
- Modify: `Modules/RoomItems.lua`: add `Build(id, catalog) -> Model`. Every part is anchored with `CanCollide = false`, `CanTouch = false`, `CanQuery = true` and `CastShadow` off for small parts. The model has the attribute `ItemId`.
- Modify: `Systems/Rooms.lua`:
  - `Edit(p, action)` with `action = { op = "place" | "move" | "remove", kind, index?, id?, x?, z?, r? }`
  - only the owner, only while inside their own plot (`PlaceOf`), behind the `Config.Rooms.Edit` token bucket
  - validation through `RoomRules.Fits` with the live `Unlocked`, then a save (`MarkDirty`) and that one item rebuilt in the room's `Items` folder
  - `State(p)`, and the `Room_Get` / `Room_Edit` handlers
- Create: `build/t108a_play_server.lua`

**Interfaces:**
- Consumes: `Fits`, `Unlocked`, `Repair` (Task 1); `state` (Task 3).
- Produces: `Rooms.Edit` and `Rooms.State`. `State` = `{ rooms = { kind = { limit, used, items, grid, slots } }, unlocked = { id }, door, inside = kind? }`. `RoomItems.Build`. Refusal reasons are the `Fits` reasons plus "busy", "away" and "owner".

- [ ] **Step 1: Write the failing test** t108a:
  - inside the bedroom, place a rug at a grid cell → ok; the model is in `Items` and non-colliding; `Home(uid)` has it
  - move it → one model, at the new cell
  - rotate an item with odd dimensions → swapped footprint
  - an overlap, out of bounds, the 7th item, a locked item and a closet in the bedroom are each refused with their reason and nothing changes
  - from the hub → "away"
  - 8 calls in 0.1 s → some answer "busy"
  - remove → gone and saved
  - `SetHome` with junk → the plot rebuilds from the repaired home
  - a Release and Claim (a rejoin) rebuilds the same items in the same cells
  - each room's `Items` part count ≤ limit × 12
  - marker `T108A PLAY OK`
- [ ] **Step 2: Controller red** `--play t108a` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Controller:** sync `Modules/RoomItems` and `Systems/Rooms`; `--play t108a t101 t103a` → PASS.
- [ ] **Step 5: Commit** `R-T9: place, move and remove your things (server)`.

### Task 10: The placement UI (§4.6, §10)

**Files:**
- Create: `src/ReplicatedStorage/OK/Modules/RoomUI.lua`, the edit bar. Its own ScreenGui `OK_Room` (DisplayOrder 7, CoreUISafeInsets) holds:
  - ◀ / ▶ to browse your unlocked items, with the item name and "USED / LIMIT" between them
  - ADD
  - for a selected item: ⟳ ROTATE, ✓ PLACE, 🗑 REMOVE, ✕ CANCEL
  - DONE

  Every button is ≥ 44 px. The bar sits at the bottom centre with two rows under 667 px wide. The test attributes are `Editing`, `Selected`, `Ghost`, `GhostOk` and `LastEdit`, with `Command` = `"next"`, `"prev"`, `"add"`, `"cell:x,z"`, `"pick:index"`, `"rotate"`, `"place"`, `"remove"`, `"cancel"`, `"done"`.
- Modify: `RoomClient.client.lua`: edit mode.
  - It enters from the room's untagged `DecoratePrompt` (Rooms; owner only; near `Entrance`).
  - The camera is Scriptable top-down over the room, sized to fit it.
  - Movement is disabled through the PlayerModule controls, and the character stays put.
  - A tap on the floor raycasts to a grid cell; a tap on an item selects it.
  - The ghost is a `RoomItems.Build` copy at transparency 0.5, red when the client's `RoomRules.Fits` refuses.
  - ✓ sends `Room_Edit`. A refusal shows §6's sentence.
  - DONE, a teleport or a respawn restores the camera and the controls.
- Modify: `Systems/Rooms.lua`: the `DecoratePrompt` per owned room, and `Room` "state" pushes.
- Create: `build/t109a_play_server.lua` (stages: WakeUp, unlocks the rug and plant, `Unfill`), `build/t109b_play_client.lua`

**Interfaces:**
- Consumes: `Room_Get` / `Room_Edit` (Task 9); `RoomItems.Build`; `RoomRules.Fits` client-side.

- [ ] **Step 1: Write the failing test** t109b, at 667×375, 771×390 and 844×390 (`ForceViewport` on `OK_Room`):
  - after the Decorate prompt (`InputHoldBegin` and `InputHoldEnd`), `Editing` is true and the camera is Scriptable above the room
  - every visible button is ≥ 44 px, inside the viewport, and overlaps no other
  - `Command` `"add"` then `"cell:<a free cell>"` → `GhostOk`; `"place"` → `LastEdit == "ok"`, and the server's item (read via `Room_Get`) is at that cell
  - `"cell:<the same cell>"` with a second item → `GhostOk` false, and `"place"` shows the overlap sentence
  - `"done"` → the camera is Custom and the controls are back
  - marker `T109B PLAY OK`
- [ ] **Step 2: Controller red** `--play t109` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4:** Controller:
  1. Sync `Modules/RoomUI`, `OK/RoomClient` and `Systems/Rooms`.
  2. `--play t109 t108a t62 t57b` → PASS.
  3. Capture each room kind's grid in Studio, and adjust only `Config.Rooms.Kinds.*.grid` if a cell sits inside furniture.
- [ ] **Step 5: Commit** `R-T10: decorate mode, phone first`.

### Task 11: Your walls show your career (§4.7)

**Files:**
- Modify: `Modules/RoomItems.lua`: add `Plaque(entry, text) -> Model` (≤ 3 parts and a SurfaceGui; hits gold, placements silver, weekly blue).
- Modify: `Systems/Rooms.lua`:
  - plaques hang in each owned room's `Plaque_1..n` slots, filled from one `RoomRules.Plaques(prof.life.disco, prof.plaques, total slots)` list: the bedroom first, then home, then real
  - the text comes from `LifeRules.DiscoText` with roster names (as `Career` `lifeView` builds them, `Career.lua:261-273`), and the weekly ones from §7
  - they rebuild when the `Placements`, `Hits` or `Plaques` attribute changes
  - they're outside the item limit
- Create: `build/t110a_play_server.lua`

**Interfaces:**
- Consumes: `RoomRules.Plaques` (Task 1); `LifeRules.DiscoText`.

- [ ] **Step 1: Write the failing test** t110a:
  - fresh → 0 plaques
  - `Life` `Event("placement", { v = "navx", key = "navx_placement" })` → one plaque in `Plaque_1` within 2 s, reading `DiscoText`'s line with "LIL NAV X"
  - 2 hits and 3 placements with only the bedroom → 3 plaques, the hits first
  - after `Unlock("home_studio")` → all 5, the rest hung in home
  - a weekly plaque (`prof.plaques` entry) → its §7 line
  - the item limit is unchanged
  - marker `T110A PLAY OK`
- [ ] **Step 2: Controller red** `--play t110a` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Controller:** sync `Modules/RoomItems` and `Systems/Rooms`; `--play t110a t71 t72` → PASS.
- [ ] **Step 5: Commit** `R-T11: plaques for your placements, hits and weekly singles`.

### Task 12: The home studio: closet and booth (§7 D12)

**Files:**
- Modify: `Modules/RoomItems.lua`. The closet build hangs one 2-part hanger per owned fit in that fit's colour; it rebuilds on the `Gear` attribute.
- Modify: `Systems/Rooms.lua`: a placed `closet` gets an untagged `ClosetPrompt` (§8; owner only) → `InteractionEvent` `OpenPanel { tab = "Gear", closet = true, gear = Gear.State(p) }`.
- Modify: `Modules/PanelUI.lua`: the Gear renderer (:246-280) with `payload.closet` lists only your owned `kind == "fit"` rows, each with its EQUIP (wear or take off, through the existing `C.OnEquip`), under §8's "YOUR CLOSET". With none owned it shows the §8 empty line.
- Modify: `Modules/BoothArtist.lua`: `Show(artist, stars, quote, seconds, spot?)` (:16), where `spot` is a CFrame. When it is nil, he stands at the hub booth as today.
- Modify: `Systems/DAW.lua` `OpenFor`: the payload gets `booth = Rooms.Booth(inst)`.
- Modify: `DAWClient.client.lua` `req.OnDeliver` (:229-283):
  - `booth == false`: a room with no booth (the bedroom) shows the result at once, with no cutaway
  - a table: the artist stands at `booth.spot` and the camera uses `booth.cam`
  - nil: the hub booth as today
- Create: `build/t111a_play_server.lua`, `build/t111b_play_client.lua`

**Interfaces:**
- Produces: `Rooms.Booth`; `BoothArtist.Show`'s `spot`; PanelUI's `closet` payload.

- [ ] **Step 1: Write the failing tests.**
  - **t111a:**
    - after `Unlock("home_studio")` and placing a closet in home, its hangers equal the owned fits (0, then 2 after `GrantGear("fit_cuban,fit_shades")`)
    - the hook's `Closet` (the prompt's handler) sends `OpenPanel` with `closet = true`, and a non-owner gets the owner toast instead
    - `Rooms.Booth` of the home Station → a table with `spot` near `BoothSpot`; of the bedroom Station → false; of the hub PC → nil
    - marker `T111A PLAY OK`
  - **t111b:**
    - the closet panel lists exactly the owned fits, and EQUIP toggles `Fits`
    - at 667×375 every row button is ≥ 44 px
    - a delivery from the home studio (the deliver path with `SetActiveRequest`) shows `OK_BoothArtist` near home's `BoothSpot`, and the camera returns afterwards
    - a delivery from the bedroom shows the result with `Cutaway` never true
- [ ] **Step 2: Controller red** `--play t111` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Controller:** sync `Modules/RoomItems`, `Systems/Rooms`, `Modules/PanelUI`, `Modules/BoothArtist`, `Systems/DAW` and `OK/DAWClient`; `--play t111 t44 t45 t20 t28 t72` → PASS.
- [ ] **Step 5: Commit** `R-T12: the home studio's closet and booth`.

### Task 13: Posters you design (§7 D12)

**Files:**
- Modify: `Modules/RoomItems.lua`: add `Poster(design, cfg) -> Model`. It is a thin part with a SurfaceGui using `PosterWords[w]`, `PosterColors[c]` and style s (3 layouts), with no images.
- Modify: `RoomUI.lua` / `RoomClient.client.lua`: in edit mode, a tap on a free `Poster_n` slot opens the designer: WORD ◀▶, COLOUR ◀▶, STYLE ◀▶, HANG. The same `Command` scheme applies: `"slot:n"`, `"word:+1"`, `"color:+1"`, `"style:+1"`, `"hang"`. A tap on a hung poster selects it for REMOVE or redesign.
- Modify: `Systems/Rooms.lua`: the `Edit` op `"poster"` = `{ op, kind, slot, w, c, s }`, through `Fits` (`"slot"`, `"design"`, `"limit"`).
- Create: `build/t112a_play_server.lua`, `build/t112b_play_client.lua`

**Interfaces:**
- Consumes: `Rooms.Edit` (Task 9), the edit mode (Task 10), `Config.Rooms.PosterWords`, `PosterColors` and `PosterStyles`.
- Produces: `RoomItems.Poster`; the `Edit` op `"poster"`.

- [ ] **Step 1: Write the failing tests.**
  - **t112a:**
    - poster slot 1 in home with `{ w = 2, c = 3, s = 1 }` → saved, and the model's label reads `PosterWords[2]`
    - word 99 → "design"; slot 9 → "slot"; in the bedroom → "room"
    - a redesign of the same slot replaces it
    - posters count toward home's limit
    - no `TextBox` exists anywhere in the plot or the client GUI
    - marker `T112A PLAY OK`
  - **t112b:** the designer at the three viewports has every control ≥ 44 px, inside the viewport and not overlapping; the `Command` flow hangs a poster that the server confirms.
- [ ] **Step 2: Controller red** `--play t112` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Controller:** sync `Modules/RoomItems`, `Modules/RoomUI`, `OK/RoomClient` and `Systems/Rooms`; `--play t112 t109` → PASS.
- [ ] **Step 5: Commit** `R-T13: posters designed in the game`.

### Task 14: Door modes (§4.8, D9)

**Files:**
- Modify: `Systems/Rooms.lua`:
  - The hall door's `EnterPrompt` uses `RoomRules.CanEnter(home.door, isOwner, isFriend)`.
  - `isFriend` is `Player:IsFriendsWith(ownerId)` in a pcall, cached per (guest, owner) for the session, with a 2 s limit (an error or a timeout counts as not a friend).
  - The owner's untagged `DoorPrompt` on the landing's front door, inside, reads §10 "Door: {MODE}" and cycles with `NextDoorMode`, saving `home.door`.
  - Visits last only while the owner is online (Task 2's Release).
  - The plate shows the mode's colour.
- Create: `build/t113a_play_server.lua`

**Interfaces:**
- Consumes: `RoomRules.CanEnter` and `NextDoorMode` (Task 1); `Release` (Task 2).
- Produces: `home.door` written by the owner's prompt; the hook commands `Door` and `FriendCheck`.

- [ ] **Step 1: Write the failing test** t113a:
  - a fresh home's door is "friends"
  - the hook's `Door` (the owner prompt's handler) cycles it: friends → locked → open → friends, saved each time
  - a pretend guest through `Enter(slot, asFriend)`: friends + not friend → refused with §1's toast; friends + friend → enters; locked + friend → refused; open → enters
  - `FriendCheck` stubbed to error → refused within 2 s; stubbed to sleep 5 s → refused at about 2 s, and a second press meanwhile answers too
  - the owner always enters
  - marker `T113A PLAY OK`
- [ ] **Step 2: Controller red** `--play t113a` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Controller:** sync `Systems/Rooms`; `--play t113a t101` → PASS.
- [ ] **Step 5: Commit** `R-T14: door modes, friends only by default`.

### Task 15: The 12-plot phone test with the real bedroom (§4.13)

**Interfaces:**
- Consumes: `RoomBuild.Plot` (Task 2), `RoomItems` (Tasks 7, 9, 11, 12, 13), `Data/RoomCatalog`.
- Produces: `RoomBuild.Plot`'s full-plot option (every room unlocked and filled), used only by the test.

**Precondition:** the user has imported the bedroom (`Env_bedroom_starter` exists with `Bedroom_Setup`). Until then this task waits.

**Files:**
- Modify (rewrite): `build/room_test.lua`. It is still a throwaway (`OK_Build = "room_test"`), kept out of `src/` and out of `tools/test.py`. It builds 12 plots through `RoomBuild.Plot` at the real slot origins, with fake owners "STUDIO 01".."STUDIO 12", from the real bedroom template. Each plot has:
  - home and real unlocked
  - every room at its item limit, from `Data/RoomCatalog`
  - all its plaque slots and poster slots filled
  - tier-3 speakers

  It also builds the ROOM TOUR client as before. The live game's streaming settings stay as they are.
- Modify: `build/room_test_remove.lua` (removes only `OK_Build = "room_test"`) and `build/room_test_play_client.lua`.
- Create: `build/t114_check.lua` (Edit). It builds one full plot with `RoomBuild.Plot` under a temporary Model, then checks:
  - each room ≤ 1 light
  - the bedroom shell ≤ 56 MeshParts
  - each room's `Items` ≤ limit × 12 parts
  - the plot's total parts and triangles are printed
  - the hub counts are unmoved

  It removes the temporary Model in a pcall cleanup. Marker `T114 OK`.
- [ ] **Step 1: Write t114_check.** Controller red: `--edit t114_` (before the rewrite, `RoomBuild.Plot` has no full-plot path) → FAIL.
- [ ] **Step 2: Implement.**
- [ ] **Step 3: Controller:**
  1. Sync `Modules/RoomBuild`.
  2. `--edit t114_ 09_qa t88` → PASS.
  3. Run `build/room_test.lua` once in Edit and check its print (12 plots, equal part counts), then run `room_test_remove.lua`.
  4. Message the bedroom session that `ok_assets/scripts/bedroom_room_test.py` reads the old `room_test.lua` text, so its generator shouldn't be re-run against this version.
  5. Then "Needs you": publish privately, ROOM TOUR on both phones, screenshots. The pass rule: every plot at 30+ fps, low 20+, loaded within 2 s.
- [ ] **Step 4: Commit** `R-T15: the 12-plot phone test with real bedrooms`.

### Task 16: Integration, review and report

**Interfaces:** Produces none. It reports on Tasks 0–15.

- [ ] **Step 1:** The full suite with no failures (one rerun per flake), `walkins_pause_off`, guard green, and `sh tools/spec.sh` all PASS.
- [ ] **Step 2:** A whole-branch final review on the most capable model, against this plan and the spec. One fix dispatch, then one scoped re-review.
- [ ] **Step 3:**
  - `sh tools/snapshot.sh v42_rooms`; `python3 -I tools/export_rbxm.py`
  - README "Your rooms" (systems, remotes, hooks, tests t100–t114, the build order with `19_rooms` after `18_gates`)
  - `ROOMS_REPORT.md`: try it, how sure, the asset contract for the user's home and real studio imports, and what needs you (the copy approval list, the phone test, saving the place for the streaming setting)
  - the tracker (Now, Needs you, Done log)
- [ ] **Step 4: Commit** `R-T16: rooms integration and report`.

---

## Order and dependencies

- **Base:**
  - Wave 3's Task 6 (integration) is done.
  - Task 5d is committed: Visitor, VisitorLooks, VisitorFigure, WalkIns and PhoneUI are 5d's working copy on disk 11-12. Re-read them; the line numbers here are from that copy.
- **Order:**
  - Tasks 0 and 1 need no Studio and can run first, beside other work.
  - Then 2 → 3 → 4.
  - 5, 6 and 7 each need only 2 (7 also needs 6).
  - 8 needs 7. 9 needs 3; 10 needs 9; 11 needs 3 and 4; 12 needs 4 and 9; 13 needs 10 and 12. 14 needs 2.
  - 15 needs 9–13 and the user's bedroom import. 16 is last.
- **The rooms core that Day One (Wave 3 Task 5e) waits on:** Tasks 2, 3, 5, 6 and 7. That is waking up in your bedroom, saved rooms, the first visitor at your door, your laptop and the rack, and "play it on your speakers". 5e runs after Task 7. Until 5e lands:
  - the tour still highlights the hub PC
  - a bedroom player can still finish it: open at the laptop, take, deliver, a speaker play counts as "monitors", and a rack buy counts as gear
- **Where the plans meet:**
  - The people plan's Task 6 (the sim's room unlocks and the first-monitors day) needs Tasks 4 and 7's gate and gear numbers.
  - Its Task 9 (the big-names gate) needs Task 4's `home_studio` gate. It reads it through `Career.Get`, never through Rooms.
  - The people plan's Task 6 may retune `home_studio`'s `cost` (and `needs` within its stated range). It owns those numbers after Task 4.

## Claude's calls (plan)

1. **Plots are a 4×3 grid** at (6000 + 2000·col, 0, −2000 + 2000·row). Each is a code-built landing (x 0..110) with the rooms north of it. The shared building is a 12-door hall east of every hub model, reached by teleport doors. Why: 2,000 studs keeps plots beyond the streaming radius of each other, and teleport doors cut nothing out of the hub shell.
2. **Owned rooms come from `prof.career.gates`** (a `room` field marks a ladder gate). `prof.career.home` holds only the door, the items and the posters. Why: one writer, and no list to drift.
3. **The bedroom template, or a stand-in.** The bedroom is `Env_bedroom_starter`, moved to ServerStorage at runtime and cloned. Its missing anchors (Entrance, VisitorSpot, CritterSpot, Plaque_n) come from Config. Every kind has a code-built stand-in with the full asset contract until its import. Why: we can't edit the pipeline's asset, and tests must run before the import.
4. **The test hold.** Under it (`WalkInsPaused` present), the wake-up and the room respawn don't move anyone. Why: ~220 existing play tests assume the hub spawn.
5. **Untagged room prompts.** Room prompts (doors, Decorate, the closet) are untagged and hooked by Rooms. Only the Station and the RackSpot are tagged, and `InteractionService.Adopt` gives clones their SFX. Why: t11 pins 17 SFX keys and checks every tagged part's sound.
6. **One owner rule** in `InteractionService.hook` for every tagged part in a room, plus `DAW.StationOf` for the broadcast and deliver checks. Why: the opening, the rack, airing and delivering all follow one ownership rule.
7. **Visitors in your room** appear at its `Entrance` and walk to `VisitorSpot`. The pigeon sits at `CritterSpot`. Why: the walker has no doors or pathfinding, and a walk through the landing would cross walls.
8. **Louder and better.** "Louder" is the rolloff and volume per tier. "Better" is an `EqualizerSoundEffect` on a per-tier SoundGroup (the laptop cuts the lows). The first monitors cost $500 and need 200 followers at level 2, which three starter deliveries reach (a short first session; 300 would need the dailies too). Why: the built-in effects need no upload, and the user's session-1 pacing line.
9. **A room play** goes through `DAW_Broadcast`, but it isn't an airing: no queue, no FIRE, no `BroadcastTried`. `Rooms.Played` counts the tour's "monitors" step. Why: Funnel step 6 means airing.
10. **The bedroom has no booth**, so its deliveries show the result with no cutaway. The home and real rooms use their booth anchors. Why: "a bedroom for beats, then a home studio with a booth".
11. **Placed items never collide.** You edit only while inside your own plot. One `Room_Edit` remote carries ops behind a token bucket. Why: no item can block a door or the laptop, and one rate limit covers every op.
12. **Posters** are 12 preset words × 8 colours × 3 styles, with no TextBox. Why: the standing rule against player-typed text.
13. **The closet** is a placeable item (home and real, one a room) that shows hangers for your owned fits. It opens the Gear tab in closet mode, with wear and take off. Why: it reuses `Gear.Equip`, and a closet with nothing to do would break "nothing happens" rooms.
14. **The real studio** ships its gate (needs 3 placements and 20,000 followers, $8,000) and a stand-in shell until its import. It adds no new actions (§6). Why: the user's ladder has three rungs, and the asset is the user's import.
15. **Gifts** are a new `gift` outcome key on three existing outcomes, so there are no new cards. Why: no deck change keeps the pacing as it is.
16. **Item limits** are bedroom 6, home 16 and real 24, at ≤ 12 parts an item. Plaques are 3, 6 and 10; posters are 0, 4 and 6. Why: the bedroom shell already uses 55 of 56 MeshParts, and the phone test measures the rest.
17. **Two hub door paths.** A 13th player gets no plot and starts at the hub. An owner who leaves moves their guests to the hall first. Why: the spec doesn't say, and both must fail softly.
18. **Streaming is on from Task 2,** with the hub's top-level Models Persistent, so the whole suite runs under it from then on. Why: plots need it, and the 11-04 room test passed the suite that way.
