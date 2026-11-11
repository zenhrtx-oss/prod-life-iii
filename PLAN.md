# OK Studio v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the OK Studio hub described in SPEC.md inside the open Roblox place, with working interactions and a modular architecture, preserving the originals and versions.

**Architecture:** Re-runnable Luau build scripts (one file per room or system) executed through the Studio MCP `execute_luau`, each requiring a shared builder library stored as ReplicatedStorage.OK.BuildLib. Runtime code is created as Script/ModuleScript instances with Source set by the build scripts. Verification is Luau assertion scripts plus viewport captures.

**Tech Stack:** Roblox Studio 0.744 + built-in MCP (execute_luau, insert_asset, screen_capture, start_stop_play), Luau, CollectionService tags, ProximityPrompt, TweenService, DataStoreService (stub). Driver: scratchpad mcp_call.py (`--luau file.lua`), one call at a time.

**Spec:** OK ROBLOX/roblox_studio_notes/ok_studio/SPEC.md

## Global Constraints
- Part budget 6,000; lights at most 24; Lighting.Technology ShadowMap.
- No image uploads; all signage is SurfaceGui text. No audio assets.
- Every Creator Store insert is script-stripped before it stays; originals preserved in ServerStorage.OK_Backup_2026-10-22 with scripts disabled.
- Each build script removes its own previous output first (idempotent), tagged by attribute `OK_Build = "<script name>"`.
- Studio must be told to save after Tasks 1, 4, 7 and 9 (the user presses Save; the MCP cannot).

## Review Focus
1. A phone player on a slow device: part count and light count must stay under budget (Task 9 asserts counts).
2. Two players triggering the console or door at once: server owns the state attribute; the second trigger toggles from the latest state, never desyncs (Task 7 play test fires twice fast).
3. A player who walks away mid-prompt: prompts have MaxActivationDistance 8 and RequiresLineOfSight false; nothing leaves a stuck UI (Task 8 closes the panel on distance).
4. DataStore unavailable in Studio or API off: DataService must return a default profile without erroring (Task 7 asserts pcall path).
5. Re-running a build script after a manual edit: the script deletes only instances carrying its own OK_Build attribute (Task 2 asserts no collateral deletion).

---

### Task 1: Backup originals and scaffold the project
**Files:** Create build/01_backup_scaffold.lua
**Produces:** ServerStorage.OK_Backup_2026-10-22 (original models moved, all LuaSourceContainers Disabled or kept as-is for ModuleScripts), folders per SPEC Architecture, ReplicatedStorage.OK.BuildLib ModuleScript with: `L.part(name, size, cframe, props) -> BasePart`, `L.box(parent, name, pos, size, props)`, `L.wall(parent, name, x0,z0,x1,z1, h, thickness, props)`, `L.textFace(part, face, text, props)` (SurfaceGui TextLabel), `L.light(part, color, brightness, range, kind)`, `L.neonStrip(parent, name, cframe, length, color)`, `L.tag(inst, kind, title)`, `L.clear(buildName)` (deletes instances whose attribute OK_Build == buildName), `L.mark(inst, buildName)`.
- [ ] Step 1: Write the assertion script build/t01_check.lua: asserts backup folder has 4 children, Workspace has no scripts outside OKStudio, BuildLib requires without error, and `L.part` returns an anchored part.
- [ ] Step 2: Run 01_backup_scaffold.lua via mcp_call.py --luau; then run t01_check.lua; expected output "T01 OK".
- [ ] Step 3: Tell the user to Save to Roblox As "test".

### Task 2: Shell (floors, walls, ceilings, openings, glass, spawn)
**Files:** Create build/02_shell.lua, build/t02_check.lua
**Consumes:** BuildLib. **Produces:** Workspace.OKStudio.Shell with named parts: Floor_Lounge, Floor_Control, Floor_Booth, Floor_Corridor, Wall_*, Ceiling_*, BoothGlass, Door frames; SpawnLocation moved to (6,0.5,5) facing +X; Baseplate removed.
- [ ] Step 1: t02_check.lua asserts floor tops at y=0, BoothGlass Transparency 0.35, the three doorways are free of collidable parts (raycasts), part count under 400.
- [ ] Step 2: Run 02_shell.lua, then t02_check.lua: "T02 OK". Capture a plan view (roof parts hidden by setting Transparency inside the capture script) and read it.
- [ ] Step 3: Re-run 02_shell.lua; assert part count unchanged (idempotency).

### Task 3: Lighting and atmosphere
**Files:** Create build/03_lighting.lua, build/t03_check.lua
**Produces:** Lighting settings per SPEC, ColorCorrection, Bloom, fog; Workspace.OKStudio.Lighting with lamp fixtures (parts + PointLight) and ceiling neon strips; `LightingService` presets Warm and Neon stored in ReplicatedStorage.OK.Config.LightPresets.
- [ ] Step 1: t03_check asserts Technology == ShadowMap, light count <= 24, ClockTime == 0.
- [ ] Step 2: Run and check; capture from the control room looking at the booth.

### Task 4: Control room and vocal booth furniture
**Files:** Create build/04_control_booth.lua, build/t04_check.lua
**Produces:** console desk with LED meter parts named Meter_1..Meter_8 (tagged for animation), monitors with screens, MIDI keyboard, studio monitors Speaker_L/R, racks, chair (Seat), couch (Seats), rug, plaques, neon "OK" sign; booth mic (insert_asset 136651054470620 then strip, or primitives), stand, REC sign part named REC_Sign, booth lamp BoothLamp.
- [ ] Step 1: t04_check asserts those named parts exist, seats count >= 4 in ControlRoom, total part count under 3,500.
- [ ] Step 2: Run, check, capture three views (console, booth window, couch). Fix anything that reads wrong. Save version clone v2_rooms to ServerStorage.OK_Versions.
- [ ] Step 3: Tell the user to Save.

### Task 5: Lounge and corridor furniture
**Files:** Create build/05_lounge_corridor.lua, build/t05_check.lua
**Produces:** sofa (Seats), coffee table, crates, bar + 3 stools (Seats), TV wall part TV_Screen with SurfaceGui, credits wall with plaque parts Plaque_1..N from ReplicatedStorage.OK.Data.Credits, neon "WEGONEBEOK" sign, plants, posters (text), corridor sign and strip.
- [ ] Step 1: t05_check asserts plaques == number of credit entries, seats >= 6 in Lounge, part count under 5,200 total.
- [ ] Step 2: Run, check, capture two views.

### Task 6: Data and runtime modules
**Files:** Create build/06_runtime.lua
**Produces:** ReplicatedStorage.OK.{Config, Data.Credits, Remotes.InteractionEvent, Remotes.ProfileFunction, Modules.UITheme, Systems.*}; ServerScriptService.OK.{Main, Services.InteractionService, Services.LightingService, Services.DataService}; StarterPlayerScripts.OK.ClientMain; StarterGui.OK_UI. Interfaces: InteractionService `Register(kind: string, handler: (player, instance) -> ())`, `Toggle(instance, attr: string) -> boolean`; LightingService `Apply(presetName: "Warm"|"Neon")`; DataService `GetProfile(player) -> {level:number, visits:number}`; client receives InteractionEvent(kind: string, payload: table).
- [ ] Step 1: t06_check asserts every module `require`s without error in Edit mode and Credits has >= 15 entries.
- [ ] Step 2: Run and check.

### Task 7: Wire interactions and play-test
**Files:** Create build/07_interactables.lua, build/t07_play.lua
**Produces:** ProximityPrompts on Computer, Console, Mic, LightSwitch, Door, CreditsWall, TV with tag OK_Interactable; server handlers per SPEC Interactions.
- [ ] Step 1: Run 07_interactables.lua; t07 (Edit) asserts 7 tagged interactables with prompts.
- [ ] Step 2: start_stop_play; execute t07_play.lua with datamodel_type Server: fires the Console prompt twice fast and asserts the attribute ends in the state of the last toggle; fires Mic and asserts REC on then off after 8 s; calls DataService.GetProfile and asserts defaults; stops play. Save clone v3_interactions.
- [ ] Step 3: Tell the user to Save.

### Task 8: Client UI
**Files:** Modify build/06_runtime.lua (UI builder section), build/t08_play.lua
**Produces:** OK_UI panel with tabs Credits, Sessions, Profile; opens on InteractionEvent; closes with X, Escape, or when the player moves more than 12 studs from the source instance.
- [ ] Step 1: In play mode, execute (Client) a script that fires the Computer handler and asserts OK_UI.Panel.Visible == true, then moves the character 20 studs and asserts Visible == false.
- [ ] Step 2: screen_capture in play mode of the open panel; read it; fix layout.

### Task 9: Polish, performance gate, versions
**Files:** Create build/09_qa.lua
- [ ] Step 1: 09_qa.lua asserts total BasePart count in Workspace.OKStudio <= 6,000, light count <= 24, zero LuaSourceContainers outside the OK folders, zero scripts enabled in ServerStorage.OK_Backup_2026-10-22, every Seat Anchored, every interactable has a prompt. Prints "QA OK" with the numbers.
- [ ] Step 2: Captures: corridor entry, lounge wide, control room from couch, booth from console, plan view. Read them; fix the worst three issues; re-capture.
- [ ] Step 3: Save clone v4_polish; tell the user to Save and Publish.

---
## Status 2026-10-22 03:50 EDT
Tasks 1–9 complete and verified in this session: T01–T07 edit checks pass, T07 and T08 play tests pass (server log shows every interaction), 09_qa passes (487 parts, 19 lights, 12 seats, 7 interactables), snapshot v4_polish_2026-10-22 in ServerStorage.OK_Versions. Harness lessons folded into the tests: unsit the character before moving, aim the camera at the prompt (prompt visibility follows the camera), and give neighbouring prompts different keys. Outstanding manual steps: the user saves the place and sets Lighting.Technology.

## Status 2026-10-22 04:20 EDT: Beat Maker v0
Done and verified in play: studio PC opens a 4×16 beat maker with three licensed samples and one public hat; save validated server-side, rate-limited, +10 XP; credits-wall prompt made reachable; booth and corridor each got a warm light; lounge pendant moved off the doorway sightline. Snapshot v5_beatmaker_2026-10-22. Persistence needs a published place with API access on.

## Status 2026-10-22 06:55 EDT: Roadmap Milestones 1-3
Milestones 1, 2 and 3 from ROADMAP.md are built and verified: 29/29 tests under the strict runner, final snapshot v11_m3_final_2026-10-22, checkpoints m3_tour_0652 and m3_final. The light-zoning part of Milestone 2 was reverted after screenshots showed dark rooms; Future lighting is the user's call. Milestone 4 not started. Full log and the user's to-do list: MORNING_REPORT.md.

## Status 2026-10-22 16:45 EDT: Milestone 4 "Studio Sessions" built
All six steps of GAMEPLAY_NEXT.md Milestone 4 are in and verified. Two independent read-only reviews (save lock; steps 2-6) found 14 distinct real issues, all fixed with regression tests, including a forged-id server freeze, a stuck cutaway camera, stale dailies across UTC midnight and lost saves at shutdown. 59/59 tests under the strict runner, final snapshot v18_m4_reviewed_2026-10-22, checkpoint m4_reviewed. The user approved the artist names, titles, quotes, ranks and gear names at 17:19. Milestone 5 not started.

## Status 2026-10-22 18:50 EDT: Milestone 5 built
Weekly Single + plaques, producer cards, SAMPLE IT / flips, licensed drum kits as gear, Cypher rounds and the drop-off funnel are in: 83/83 tests, snapshot v23_m5_complete_2026-10-22, checkpoint m5_complete. The user kept the flagged content for now, approved the names, and saved the place to Roblox (PlaceId 139218961436722). A 25-agent independent review found 14 distinct real issues (cypher anonymity leak, cypher entries copied from the monitors, forged flip tokens, repeat flip credit, slot kits not restored, phone layout gaps and more); all fixed with regression tests. 83/83 tests, final snapshot v24_m5_reviewed_2026-10-22, checkpoint m5_reviewed.

## Status 2026-10-22 23:25 EDT: Milestone 6 "Piano roll" built
The beat maker has a KEYS view (Modules/PianoRoll): beat format v3 adds a 3-voice x 16-step keys lane (128 characters), notes are placed by tap, stretched by drag, capped at 3 per step, locked to a scale (minor pentatonic by default), auditioned and played in time with the drums, and carried through saves, the monitors, SAMPLE IT, cyphers and session requests (new asks melody / melnotes / chord). Voices are licensed single notes repitched per note: MUSIC BOX free, PLUCK and CHIME on the rack; tuning measured in Studio with AudioAnalyzer against the 808. Older 64/80-character beats upgrade on load and on the server, and the pad diff is length-tolerant so old airings still count as references. 87/87 tests under the strict runner, snapshot v25_m6_pianoroll_2026-10-22, checkpoint m6_pianoroll. The user still has to listen to the three voices (and may want other samples), and to approve the two new rack names ("Pluck voice", "Chime voice").
An independent read-only review (23:29) found 7 real issues, all fixed with regression checks: phone scroll swipes placed or removed notes, ties counted as changed pads (a stretch could pass "make it yours"), the same pitch could sound in three voices at once (3x volume from a crafted lane), notes outside the scale lock vanished but kept playing, the chord ask ignored held notes, gamepad selection was lost on the view switch, and new daily/weekly templates remapped already-generated ids (now date-gated). 87/87 after the fixes, snapshot v26_m6_reviewed_2026-10-22, checkpoint m6_reviewed, .rbxm export refreshed.

## Status 2026-10-23 03:00 EDT: Milestone 7 "FL-style piano roll" built
The KEYS view was remade in FL Studio's style (user: "look up fl studio piano roll and try to remake it" / "ok do it"): keyboard column, scale shading, beat lines, playhead line, green note bars with names and grab handles, 808 ghost notes, move/stretch/right-click editing (fingers move in time only, swipes still scroll), a velocity lane with accents (UPPERCASE note letters; format v3 stays 128 chars), and a CHORD stamp (1-3-5 triads from the scale). Ties and letter case never count as changed pads. t30/t30b/t30c and every other piano-roll check pass; checkpoint m7_flroll.
Suite 82/87: the 5 failures are outside M7. t03/t04/t05/09_qa count 32 lights against the 24 budget because Env_studio_two + OK_Passage_StudioTwo (another session's Studio Two import) added 11 lamps; t10's seated-view check fails because the Studio viewport is 955x452 (needs a taller window). Both are the user's call; nothing was removed or re-budgeted. Another session (ok-projects-c1) is working in the same place: Studio turns are being coordinated before the last sync, captures, snapshot and export.
03:23: after coordinating with ok-projects-c1 (it made no Studio calls; the Play session that interrupted a run was the user's own), synced the accent-case fix (BriefCheck.Diff lowercases the lane: an accent swipe never counts as changed pads), re-ran t20/t26/t30 edit checks and the t26 + t30 play tests (all pass), captured captures/m7 (desktop, all notes, phone), snapshot v27_m7_flroll_2026-10-23, checkpoint m7_final, .rbxm export places/export_2026-10-23_0323. The full suite was not re-run after that one-line fix; it only changes letters in the keys lane (every older cell is a digit or a lowercase 808 letter).
