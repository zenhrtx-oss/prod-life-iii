# Your rooms: build report

November 12 to 13, 2026. Built from the rooms design (`specs/2026-11-12-progression-and-rooms-design.md` §4.0 to §4.9 and §4.13, with your 11-12 answers D7, D10 and D12) and the plan `plans/2026-11-12-your-rooms.md`, Tasks 0 to 16. Every player gets a plot in a shared building: a landing with a front door, and their rooms behind it. The bedroom is yours from the start, and a home studio and a real studio join it as you buy them. You wake up in your bedroom, visitors find you there, the laptop and the speakers are yours, you place furniture and posters, your walls show your career, and your door is friends-only until you change it. The studio stays the public stage (airing, FIRE, cyphers). The home and real studios are code-built stand-ins until your imports land: right doors, anchors and prompts, but plain boxes.

## Try it

1. **Press Play in Studio.** Every Play starts a fresh career, and nothing carries over between Plays (Studio's save store is off). You spawn in your bedroom straight away, and Day One's first card (JUNO VALE) arrives about a second later. If you land at the studio hub instead, either a test run's pause was left on (run `tools/walkins_pause_off.lua` once in Edit) or the 12-room phone test is still in the place (run `build/room_test_remove.lua`; `09_qa` fails loudly while it is in).
2. **Get the home and real studios.** Players buy them in the Career tab, where they are listed first. Home needs 1 placement and 1,000 followers and costs $1,500. Real needs 3 placements and 20,000 followers, costs $8,000, and needs home first: until then its row shows a "× HOME STUDIO" chip and the button reads LOCKED. In Studio, ask me to stage it: I set your stats and money through the Career hook (`Set`), then `Unlock("home_studio")` and `Unlock("real_studio")`, as `t103a` does. Speakers come from the test hook's `GrantGear` (`spk_monitors`, `spk_studio`), which skips the price. On your landing, a locked room's door reads "HOME STUDIO · LOCKED / SEE THE CAREER TAB" and becomes a working "Go in" door the moment you own it.
3. **Answer or SKIP the Day One card first.** Decorate mode is refused while any card is open, and ends if one opens.
4. **Your laptop and the rack.** The bedroom laptop's prompt is E (ButtonX) and opens the beat maker. Beside it, "Open gear rack / Your laptop" is F (ButtonY) and opens the Gear tab. Both are yours only: anyone else gets "{name}'s laptop. only they can use it." A delivery at the bedroom laptop shows its result at once, with no booth cut.
5. **Decorate.** Walk to your room's door. "Decorate / Your room" sits above "Leave" and is R (D-pad down). The camera turns straight down over the room and your movement locks.
   - The bar: ◀ ▶ browse what you've unlocked with "used / limit", ADD puts it down as a ghost, tap the floor to move it (red = refused, and the line above says why), ⟳ ROTATE, ✓ PLACE, 🗑 REMOVE, ✕ CANCEL, DONE. Keyboard: WASD or arrows move the ghost, R turns, Enter places, Delete removes, Backspace cancels.
   - Open from the start: the rug and the plant. Later: beanbag (first delivery), record crate (first placement), low shelf (first 3-star delivery), floor lamp (BUZZING, 1,000 followers), keyboard stand (once you own home), and the tape machine, drum machine, pluck synth and chime bells with the TAPE kit, IRON kit, Pluck voice and Chime voice.
   - Limits: 6 things in the bedroom, 16 in home, 24 in real. Things never block you. The bedroom's free floor is small (28 one-stud cells; home 274, real 637).
6. **Plaques.** They hang by themselves and sit outside the item limit: hits first (gold, newest first), then placements and track ones (silver), then weekly singles (blue, "WEEKLY SINGLE · title"). The bedroom holds 3, home 6, real 10, filled in that order. A line reads "DAY 1 · LIL NAV X · PLACEMENT". To see one fast, ask me to stage a placement (`t110a` does it through the Career and Life hooks).
7. **Home studio: closet and booth.** In decorate, place a Closet (home and real only, one a room). Its bubble "Open closet / Your closet" is C (D-pad right) and opens YOUR CLOSET: your owned fits, each with EQUIP to wear or take off. Up to 5 hangers show on it; the panel lists every fit. Deliver a beat at the home laptop and the artist stands in that room's booth, with the camera cut to them for the listen-back.
8. **Posters** (home and real). In decorate, a pale plate lies on the floor under each empty wall spot (4 in home, 6 in real). Tap one and the camera turns to the wall: WORD ◀ ▶ (LOUD, GRIND, DREAM, BASS, VIBES, FIRE, GOLD, NIGHT, FOCUS, HUSTLE, RISE, SOON), COLOR ◀ ▶ (RED, ORANGE, YELLOW, GREEN, BLUE, PURPLE, PINK, BLACK), STYLE ◀ ▶ (BOLD, FRAMED, STACKED), HANG. Tap a hung poster to redesign or REMOVE it. Posters count toward the limit. Nobody types anything.
9. **Door modes.** Inside your front door, on the landing: "Door: FRIENDS ONLY / Who can come in" is F (ButtonY), above "Leave". Each press cycles FRIENDS ONLY → LOCKED → OPEN → FRIENDS ONLY, saves it, and tells you ("door locked. only you can come in."). The hall's plate for your door shows your name and the mode in its colour: green OPEN, amber FRIENDS ONLY, red LOCKED.
10. **Your speakers.** Open the beat maker at your laptop and press "🔊 ON SPEAKERS". It plays in your room only: no queue, no FIRE, no Aura, one play a second, and it counts for the tour's "monitors" step. Tier 1 (the laptop's own) is quiet and only people beside you hear it. Desk monitors ($500, level 2, 200 followers) put two cabinets on your desk and fill the room. Studio monitors ($3,000, level 5, 2 placements, 5,000 followers) are louder and brighter. Three story outcomes also give Desk monitors free, once, with the toast "NEW GEAR: DESK MONITORS": `mom_busy` "Give her the full tour.", `rep_headphones` "Sign it. $300.", and the STUDIO ALERT card `mishap_keys` "Ask around the building."
11. **Friends visiting.** The corridor door "THE BUILDING / Go inside" leads to a hall of twelve doors, plates "STUDIO 01" to "STUDIO 12" (an owner's name and mode once someone is in). Press Enter. LOCKED: "{name}'s door is locked". FRIENDS ONLY and not a Roblox friend: "{name}'s door is friends only" (the check gets 2 seconds; an error or timeout counts as not a friend). Otherwise you land on their landing and can walk into their rooms. Guests hear their speakers but can't use their laptop, rack, closet or Decorate. If the owner leaves, guests are moved to the hall: "{name} left the server". A 13th player gets no plot and stays in the studio: "the building is full. stay in the studio." Walk-in visitors arrive only while you are in your own rooms (or the studio). I have only run this with stand-in guests.
12. **Phone size.** Pick a phone in Studio's device emulator and repeat steps 4 to 9. Every new button is at least 44 px, measured at 667×375, 771×390 and 844×390 inside Studio's window. A true phone look still needs a phone.

## How sure I am

- **Outside Studio:** `sh tools/spec.sh` is 13 of 13 (the final re-review reran it on the fix pass's code). Pacing is unchanged: rooms add no walk-in money and no deck cards. `spec/room_rules_spec.lua` (about 1,070 lines) runs the same `RoomRules` the server and the client use.
- **Studio, task by task** (Edit checks, then Play files; every task showed its new checks red on the old code for the predicted reason before its sync, then green after):

  | Task | What | Edit | Play |
  |---|---|---|---|
  | R-T2 | plots, the building, waking up, streaming | 7 of 7 | 2 of 2; full suite with streaming on 236 of 237 (t10 only: window height 491) |
  | R-T3 | saving your rooms | 4 of 4 | 14 of 14 |
  | R-T4 | home and real as career gates | 7 of 7 | 28 of 28 |
  | R-T5 | visitors in your rooms | | 18 of 18 |
  | R-T6 | your laptop is yours, the rack | 5 of 5 | 22 of 28 first run (the Mac's screen was locked and Studio's client ran near 2 fps: t10, t12, t19d, t84b, t84c); later runs passed them |
  | R-T7 | speakers and tiers | 9 of 9 | 47 of 48 (t10 only) |
  | R-T8 | three story gifts | 3 of 3 | 14 of 14 |
  | R-T9 | placing things, server side | 1 of 1 | 8 of 8 |
  | R-T10 | decorate mode | 4 of 4 | 21 of 21, then 13 of 13 after the last hardening. A grid capture found 0 cells inside furniture |
  | R-T11 | plaques | 6 of 6 | 27 of 28; the miss was a test's own staging, fixed, then pass |
  | R-T12 to R-T14 | closet and booth, posters, door modes | 14 of 14 | 69 of 72 on 11-13 16:11: t20b "target not reachable" under a heavy render load, plus knock-ons; `--play t17 t20` reran 8 of 8 |
  | R-T15 | 12-plot phone test | 3 of 3 | 7 of 7 |
  | R-T16 fix | the final review's fixes | 13 of 13 (`09_qa` flaked once, passed on its rerun) | 64 of 65; the miss (t108a step 8) was a test artifact, fixed in the test, then pass |

**FULL SUITE (11-13 19:29–19:55, final code f3b0e5c): 277 of 277.** It covers every CLI spec (13), the guard, every Edit check and every Play file in the game, and the walk-in hold switched back off cleanly, with no console errors. Then, separately, `--play t109c t109d t111` 7 of 7. That order matters: the full suite sorts the hub beat-maker tests (t10_play, t10b, t10c) between t109d and t110a/t111, which hid a test problem until a shorter run put t111 straight after t109d. The problem was t109d's case 3 pointing the camera from the test and only half undoing it, after which no prompt showed at all. It was fixed in the test. Decorate mode's own camera cycle, with the beat maker or a card interrupting it, leaves the laptop working; both were checked.

- **The 12-plot test (R-T15, Studio):** 12 plots × 469 parts each (5,628 in all), each with bedroom, home and real full to their limits, every plaque and poster spot filled, tier-3 speakers, and 3 lights (one bulb a room), beside the hub's 61. The tour in Play streamed and visited all 12 in 30.8 s, and each loaded in about 0.1 s (0.08 to 0.13). **Studio's frame rate means nothing here, and 0.1 s says nothing about a phone's download.**
- **Captures** (`captures/rooms_2026-11-13/`), before and after the two visual fixes. The full home studio was nearly black with its one bulb (`r-t15_full_home_studio.jpg`) and is evenly lit with warm walls after (`r-t16_full_home_studio_after.jpg`). Poster words were a few percent of the poster's height (`r-t15_posters_close.jpg`); GRIND, LOUD and SOON now fill their posters (`r-t16_posters_close_after.jpg`). Brightness 1.4 looks right to me, maybe a touch washed out. Also `r-t11_bedroom_plaques.jpg`.
- **Reviews:** every task was reviewed, with a fix round and a scoped re-review wherever something was found. The final whole-branch review said "ready after fixes": 0 critical, 7 important, 7 minor to fix now. The important ones: decorate mode fought the beat maker and cards over prompts and touch controls; anything in Workspace named RoomTest could leave every joiner without a plot; poster words rendered at 8 px; the stand-in's light couldn't reach its floor; a guest moving in as the owner left could fall into the void; Repair deleted placed items when a room's geometry changed; real could be bought before home. All seven are fixed. The re-review (`final-rereview.md`) confirmed 13 of 14 and found one new important, N1 (below).
- **After the final review: N1, N2, N3 and R1, all in the full suite above.** N1: Repair keeps every item still standing where it was saved, and moves only the ones that no longer fit, into the space left and never onto a locked item's cells. R1, from the last re-check: a locked item keeps its place under the room's limit when Repair moves things, so a quick incomplete read at join can't cost a placed item later. 20,000-case random checks found 0 losses. N2 (a test wait) and N3 (a test counter) are fixed. N4 (the same-frame double press) was moot: the red run already read "opened the closet 2 times". N5 (a second re-pivot after a plot is destroyed) is left on purpose: every door move checks the plot is still there.
- **Saves:** schema is still v5. The one new field is `prof.career.home` (door mode, placed things, posters), defaulted lazily and repaired on every read by `Systems/Rooms`, its only writer. t102 round-trips it through JSON on a fake store. It has not met a real DataStore; there is no record of one. Room ownership stays in `prof.career.gates`.
- **Budgets held:** 0 new sounds (doors reuse the existing door sound; `Config.SFX` is still 17 keys), 0 uploads, no text box anywhere, no new asset ids. One light a room; the hub keeps 61 lights, 12 tagged interactables and 2 stations. A banned-word scan of every new string was clean.
- **Not proven:**
  - **Real phone frame rate and memory** with 12 real bedrooms (spec §8's acceptance). The whole-plot triangle count was not measured (Luau can't read it); the bedroom's 19,566 is the asset's own manifest figure.
  - **The viewport sizes on a device.** The 44 px and no-overlap checks ran inside Studio's window.
  - **Gamepad keys:** C and D-pad right (closet), D-pad down (Decorate), F and Y (rack, door), and the D-pad moving the ghost. The tests read the key bindings back and drive the same handlers; no controller has been used.
  - **A second real player.** No one has walked through a door, so the real `IsFriendsWith` path is untried (tests use named stand-ins for an error, a slow answer and a yes or no). A guest staying after you lock the door, and a "friend" staying one for the session after an unfriend, are by design and unseen.
  - **How it sounds.** The tests check each tier's reach, volume and EQ values; no listen is recorded.
  - **Never looked at:** the hall (no lights, never captured), the longest plaque line from where you'd stand, posters across the room, the booth's mic stand against poster spot 1, and whether ⟳ ✓ ✕ 🗑 draw as symbols on a phone. Stand-in corners also read dimmer than their middles.
  - **Untested defensive paths** (traced by reviewers): a failed refit after a saved edit, a friend check hung past 10 s, the full-room hints, the closet's "couldn't reach" toast.
  - **A real DataStore run and a published two-player build.** I never save or publish.

## Needs you

1. **The phone tour** (`research/rooms/phone_tour_checklist.md`).
   - **Part A**, the 12-room test: tell me, and I build the test rooms in Studio. While it is in, your own rooms are off and everyone starts in the studio, so don't make the game public. You publish privately, open it on two phones, tap ROOM TOUR, and send me the results card. PASS means 30+ frames a second, a worst moment of 20+, and loaded within 2 seconds. Then NEXT PLOT: read the longest plaque, find the two desk speakers, time the doors, and look at all three poster styles.
   - **Part B**, your own rooms: I take the test out first. You need the home and real studios bought on your own save, so tell me before this part if you don't have them. It covers the F and Y bubbles at three screen sizes, Decorate above Leave, the bar's symbols, a card popping up over the bar, the poster camera turn, the C key and D-pad, and decorating with a controller.
2. **The copy approval list:** `research/rooms/copy_2026-11-12.md` §11 (146 rows when written, plus 8.7), and:
   - **1.12 "Go to your room" and 1.13 "Your door" were never built.** Your own door still reads "Enter / {your name}'s door". Building them fights the plate code that rewrites that prompt on every claim, build and door cycle.
   - **6.39** "That wall spot is taken." no longer names its only cause (redesigning a spot replaces the poster), so players shouldn't see it. Reword or leave.
   - **The gear rack's SPEAKERS tag.** The rack shows each item's kind in capitals, so the two rows read "Desk monitors SPEAKERS". It is not in §11.
   - **8.7** "Couldn't reach your closet", added in the last review round.
   - **Optional lines you can drop:** 2.10 "SEE THE CAREER TAB", and 4.9 to 4.11 (the refused-play line, the "sending" line, the tour's "Press ON SPEAKERS" step).
   - **5.5** still says "under a lounge couch cushion" (`Data/WalkIns.lua` :2064). The final review's table says it was reworded, but the data and §11 both still have it, and a bedroom player has no lounge.
   - The choices at the end of §11: THE BUILDING for the hall, all three gifts giving Desk monitors, COLOR not COLOUR, the poster words, colours and styles, and names cut to 10 characters in a toast.
3. **Your home and real studio imports, before launch.** See the contract below. Changing a room's floor after launch moves players' things, and a plain import also needs one small change from me.
4. **Save the place** (Ctrl+S, File > Save to Roblox) after the last sync. Streaming (on, minimum radius 64, target 1024, low-memory stream-out) and the Persistent models are place settings, and a place closed unsaved loses the sync with them. First check that no test pause (`tools/walkins_pause_off.lua`), no real-save switch (`tools/real_save_off.lua`) and no 12-room test is left in.
5. **Look at the lighting on a phone.** The stand-in rooms' bulbs are 1.4, 1.4 and 1.5 bright: right in Studio, maybe a little washed out. Your real bedroom keeps its own light; this matters for home and real until your imports.
6. **Say yes or no on Claude's calls below.** Look hardest at 1 (door default), 7 (which saved items win when a room changes), 11 (room prices) and 13 (speaker numbers).
7. **Before any publish:** a real save round trip of `prof.career.home`, and the two-player test on a published build (a friend through your door).
8. **Left on purpose:** `Systems/Rooms.lua` is about 1,900 lines and gets split (plays, doors and friends, the saved home) the next time it's touched; a few helpers are written twice; the catalog's `poster.parts` is unused; the snapshot step is the controller's.

## The asset contract (for your home and real studio imports)

What any room's 3D model must provide so the game can use it. The stand-ins provide all of it, and so does the bedroom import (`Env_bedroom_starter`, set up by `Bedroom_Setup`). The game only clones your import and never edits it.

**What a room model must have** (the plan's contract, `RoomBuild`'s header and the stand-in's own build):

- A Model with the attribute `OK_Room` (any value; the bedroom's is "bedroom_starter"), `ModelStreamingMode` Atomic, its pivot at the middle of the floor, north along −Z, its floor top at y 0.
- One part with the attribute `RoomDoor = true` on the south wall, holding a ProximityPrompt named `ExitPrompt` (the game turns it on and hooks it).
- One Station: a part tagged `OK_Interactable` with `Kind = "Station"` and a `StationName` (the laptop). The game adds the gear rack bubble (`RackSpot`) beside it.
- A part named `Spawn`, facing into the room.
- These Attachments, each found by name: `Entrance`, `VisitorSpot`, `CritterSpot`, `Desk_Speaker_L`, `Desk_Speaker_R`, `Plaque_1` to `Plaque_n` (n = 3 bedroom, 6 home, 10 real), and for home and real also `Poster_1` to `Poster_n` (4 and 6), `BoothSpot` and `BoothCam`. An anchor's facing is its horizontal look direction; plaques and posters sit flush on a wall facing into the room.
  - `Entrance` is where visitors appear and start walking toward `VisitorSpot`; its x added to the room's `at` x sets where that room's door sits on the landing, and the Decorate prompt sits on the door part near it. `VisitorSpot` is where a visitor stops, facing you. `CritterSpot` is the pigeon's. `BoothSpot` and `BoothCam` are where the artist stands and the camera goes; a booth room missing either shows no cutaway and logs it.
  - Any the model lacks, the game fills from `Config.Rooms.Kinds.<kind>.anchors`. Those are the stand-ins' placeholders, not a promise to match your art.
- At most 1 Light, at most 56 MeshParts, at most 30,000 triangles.
- The room's measurements go in `Config.Rooms.Kinds.<kind>` when the asset lands: `at`, `size`, `grid` (the free floor), `keep` (the spawn, the Entrance-to-VisitorSpot walkway, the pigeon's spot, in front of the door), `limit`, `plaques`, `posters`, `booth`. That table has three copies that must stay equal (`Config.lua`, `spec/room_rules_spec.lua`, `build/t100_check.lua`); I edit all three.
- **Wiring, not built yet:** `Systems/Rooms`' Init only looks for the bedroom's template (`Config.Rooms.Template`). `RoomBuild.Plot` can already take one model per room kind, but Rooms never finds a home or real model, so a plain import would be ignored and the stand-in built. Landing either import takes a small code change to tell Rooms where it is. I haven't named it or added a Config key for it.

**When a room's floor changes after launch.** Any import, or any Config retune, that changes a room's `at`, `size`, `grid`, `keep`, `limit` or `posters` after launch changes what every player's saved home can hold.

On each player's next load, `RoomRules.Repair` checks every saved item and writes the result back to the save, permanently:

- An item still standing where it was saved keeps its place. Only items that no longer fit are moved, into the space left, and never onto a locked item's cells. Items in place win the room's limit over moved ones, and list order decides within each group.
- A locked item keeps its place under the limit when Repair moves things. A locked item is one whose gear, first or tier the read didn't find, as on a join before Gear is ready. A move needs the room's built items plus its locked ones under the limit, so a move made during a partial read can never cost an item its slot once the read is whole again. Edit's own limit is unchanged: there a locked item takes its cells but no slot.
- An item that no longer fits (off the new grid, on a new keep area, or on cells another item now holds) moves to the first place it fits: turn 0 then turn 1, rows north to south, each row west to east, over the grid's bounding box. It is dropped only when no place in the room takes it.
- An item over a lowered `limit`, or over an item's own `max`, is dropped, list order deciding within each group (in place first, then moved).
- A poster on a wall spot past a lowered `posters` count is dropped. Posters are never moved.

So land the home and real imports, with their measured `grid`, `keep`, `size`, `limit` and `posters`, **before launch**, or ship a migration with them. Never lower a room's `limit` or `posters` after launch without one.

**Reserved child names.** `Systems/Rooms` makes and owns these in a room model, so an import must not ship them:

- `Items` (Rooms' own carries the attribute `RoomItemsFolder`).
- `Plaques` (Rooms' own carries `RoomPlaques`; an import's own `Plaques` is left alone with a notice and Rooms makes its own beside it).
- `RoomSpeaker_L` and `RoomSpeaker_R` (Rooms replaces only models it made, marked `RoomItem = "speaker"`).
- `RackSpot`, and `Hangers` (inside a closet), and `OK_DecoratePreview` (client only).
- The prompts `DecoratePrompt` (on the room's door part), `ClosetPrompt` (on a closet's `Body`) and `DoorPrompt` (on the landing's `FrontDoor`).

A child with one of these names that Rooms did not make is at best ignored; at worst a lookup by name finds the wrong one.

**≤ 1 Light a room.** A room model holds at most one Light (your 11-11 rule). Each stand-in has one: a PointLight in its ceiling bulb, whose range reaches the room's far floor corner. Items, plaques, speakers, posters, hangers, the landing and the hall add none. The hub keeps its 61 lights, 12 tagged interactables and 2 stations, because a room (a model with `OK_Room`) is outside the hub's counts.

## Claude's calls

Each is switchable. The cost of changing one is a number, a flag or a line of copy. The three copies of `Config.Rooms` change together.

1. **A new door starts on FRIENDS ONLY.** `Config.Rooms.DoorDefault` (and `RoomRules.DOOR_FALLBACK`, which the spec checks equals it). Why: my §4.8 suggestion, kept because open would let strangers into every new player's bedroom.
2. **Doors cycle FRIENDS ONLY → LOCKED → OPEN, and the hall plate's words take the mode's colour, name included** (green 90,200,120; amber 240,190,70; red 230,80,80). `PLATE_COLORS` in `Systems/Rooms`, order in `RoomRules.NextDoorMode`. Why: the safest mode is one press from the default.
3. **The owner's door bubble is F / ButtonY, 88 px above Leave (E).** `DOOR_KEY, DOOR_PAD` in `Systems/Rooms`, `RoomBuild.RACK_UI_GAP`. Why: E is already Leave; the phone tour decides if the stack taps cleanly.
4. **The closet is C / D-pad right.** `CLOSET_KEY, CLOSET_PAD` in `Systems/Rooms`. Why: it must not take the laptop's E or the rack's F. Whether C clashes with a Roblox default key is unchecked.
5. **A press of the same prompt within 0.25 s is ignored, per player and prompt; a door cycle has its own 0.25 s.** `PRESS_DEBOUNCE`, `DOOR_COOLDOWN` in `Systems/Rooms`. Why: the closet's whole-profile message must not run once a frame.
6. **The friend check waits 2 s; an error or timeout counts as not a friend; a late real answer is kept for the session.** `FRIEND_SECONDS`, `FRIEND_DEAD` (10 s) in `Systems/Rooms`. Why: a slow answer must neither lock a friend out for good nor hold up everyone else.
7. **Items still standing where they were saved keep their place and win the limit over moved ones** (the N1 ruling). `RoomRules.Repair`. Why: never worse than the old drop-only rule; cost: a moved item can be dropped where strict list order would have dropped a later in-place one.
8. **One bulb a room is your rule; the brightness is mine:** 1.4 (bedroom stand-in), 1.4 (home), 1.5 (real), range = bulb to the far floor corner + 4. `SHELL` rows' `light` in `Modules/RoomBuild`. Why: 0.25 left the stand-ins nearly black; the phone decides.
9. **Poster text sizes itself from its box** (at most 90% of its height and 100, shrunk to the word's width, `TextScaled` off). `RoomItems.PosterTextSize`. Why: `TextScaled` collapsed to its 8 px minimum.
10. **Placed things never collide, and you decorate only inside your own plot.** `RoomItems.Build` (`CanCollide` off) and `Rooms.Edit` ("away", "owner"). Why: no thing can block a door or the laptop.
11. **Room prices are first guesses; real needs home first** (your decided ladder, enforced by `after = "home_studio"`). Home: 1 placement, 1,000 followers, $1,500. Real: 3 placements, 20,000 followers, $8,000. `Config.Career.Gates`. Why: the people plan's pacing run tunes them.
12. **Limits: bedroom 6 things / 3 plaques / 0 posters; home 16 / 6 / 4; real 24 / 10 / 6** (posters count toward the limit). `Config.Rooms.Kinds`. Why: the bedroom shell uses 55 of 56 MeshParts, and the phone test measured 469 parts a plot.
13. **Speakers:** reach 2-8, 6-24 and 10-45 studs, volume 0.5, 1.0 and 1.4, the lows cut at tier 1. `Config.Rooms.Speakers`, prices in `Config.Gear`'s `spk_*` rows. Why: guesses nobody has listened to; the first session's floor ($625, 280 followers, level 2) reaches Desk monitors, not Studio monitors.
14. **All three story gifts give Desk monitors, never Studio monitors.** `gift = "spk_monitors"` on three `Data/WalkIns` outcomes. Why: a Studio monitors gift would skip its needs on day two.
15. **The throwaway-test seam.** `roomTest()` in `Systems/Rooms`: while `Workspace.RoomTest` is a Folder carrying `Throwaway`, no slot, no plot, no moves; `09_qa` fails a place that has one. Why: your private phone-tour publish must start everyone in the studio, and a player or import named "RoomTest" must never trip it.

## Where things are

- **Code** (under `src/ReplicatedStorage/OK/`):
  - **Server owner:** `Systems/Rooms.lua` (plots, the building, doors and door modes, the wake-up, your saved home, room plays, plaques, the closet and booth, edits, and the Studio-only `_StudioRoomsHook`).
  - **Modules:** `RoomRules` (pure rules), `RoomBuild` (plots, landing, stand-ins, anchors, rack spot, the test's full plot), `RoomItems` (things, speakers, plaques, posters, hangers), `RoomEdit` (checks, rate limit, fitting), `RoomUI` (the edit bar and poster designer), `RoomScope` (pure: what counts as inside a room).
  - **Data and numbers:** `Data/RoomCatalog`, `Config.Rooms`, the two room gates in `Config.Career.Gates`, the two speaker rows in `Config.Gear`.
  - **Client:** `StarterPlayer/StarterPlayerScripts/OK/RoomClient.client.lua` (the speaker listener, decorate mode, the poster designer).
  - **Changed seams:** `InteractionService` (`Adopt`, `MayUse`), `Systems/DAW`, `Stations`, `Gear` (`Grant`), `Career` (`after`), `Tour`, `WalkIns`, `Phone`, `Modules/WalkInRules`, `Visitor`, `DAWEngine`, `BoothArtist`, `PanelUI`, `DAWClient`, `ClientMain`.
- **Build:** `build/19_rooms.lua` (Edit, idempotent, after `18_gates` and before `20_day_one`): the remotes, the hall with 12 doors, the corridor's door, streaming on. Run it again after `18_gates` or an import script rebuilds `OK_Gates` or the passages: they drop their Persistent setting, and `t100_check` goes red.
- **Tests** (`build/`, plus one CLI file), in game terms:
  - `spec/room_rules_spec.lua` (CLI): the rules, including saved-item repair.
  - `t100_check`: the building has its 12 doors, streaming is on, each stand-in has every contract part and a light that reaches its floor.
  - `t101a`/`b`: you wake in your bedroom, every door takes you where it should, a seated player is unseated, a 13th player is told the building is full, an owner leaving moves guests out safely, and a model named RoomTest doesn't stop anyone getting a plot.
  - `t102_check`: your saved rooms default, repair and survive a save.
  - `t103a`: home and real unlock through the Career tab, real needs home first, and the landing's door becomes a working one.
  - `t104a`: visitors walk from your Entrance to your VisitorSpot, and the pigeon sits at its spot.
  - `t105a` to `e`: only you can use your laptop and rack; the rack bubble works at three phone sizes; someone else's laptop answers with the owner's name.
  - `t106a` to `c`: room speakers play at the right tier, in your room only, and the beat maker button reads ON SPEAKERS.
  - `t107a`: each of the three story outcomes gives Desk monitors once.
  - `t108a`: placing, moving, turning and removing things, every refusal, the rate limit, and a rejoin rebuilding the same things.
  - `t109a` to `d`: decorate mode on a phone, and decorate mode stepping aside for the beat maker and for cards.
  - `t110a`: plaques appear for hits, placements and weekly singles, in order.
  - `t111a` to `e`: the closet's hangers match your fits, EQUIP works, a home delivery shows the booth, a bedroom delivery shows no cutaway.
  - `t112a` to `c`: posters hang and redesign, bad designs are refused, poster words fill their posters at three phone sizes.
  - `t113a`: the door test checks a friend gets in and a stranger doesn't, and an error or slow friend check counts as "not a friend" within 2 seconds.
  - `t114_check`: one full plot stays inside the light, part and hub budgets.
  - Edited for rooms: `t41_check` and the t41 pair, `t45b`, `09_qa` (the RoomTest guard), and files that count gates and gear.
- **The throwaway phone test:** `build/room_test.lua` (12 full plots and the ROOM TOUR), `room_test_remove.lua`, `room_test_play_client.lua` (checks its plumbing in Play). `tools/test.py` never runs them. Remove it before any suite: every rooms Play test needs a plot of its own.
- **Phone tour:** `research/rooms/phone_tour_checklist.md`. **Copy:** `research/rooms/copy_2026-11-12.md`.
- **Captures:** `captures/rooms_2026-11-13/` (`r-t11_bedroom_plaques.jpg`, `r-t15_full_home_studio.jpg`, `r-t15_posters_close.jpg`, `r-t16_full_home_studio_after.jpg`, `r-t16_posters_close_after.jpg`).
- **Design, plan, ledger and reviews:** `specs/2026-11-12-progression-and-rooms-design.md`, `plans/2026-11-12-your-rooms.md`, `.superpowers/sdd/2026-11-12-your-rooms/` (`progress.md`, `preflight-scan.md`, a brief, report and review per task, `final-review.md`, `final-fix-report.md`, `final-rereview.md`).
- **Commits:** 98636bc (R-T0) to f3b0e5c (the last test fix), plus this report's final edit. Snapshot in the place: `ServerStorage.OK_Versions.v43_rooms` (762 parts). Offline export: `places/export_2026-11-13_1955/`. Pushed to the private GitHub copy (prod-life-iii).
- **Tracker:** `../OK_GAME_TRACKER.md`, the controller's to update.
