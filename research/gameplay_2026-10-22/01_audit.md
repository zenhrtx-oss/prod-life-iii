# OK Studio gameplay audit (code as of v11_m3_final)

**This comes before any of the gaps:** nothing carries over to "tomorrow" yet. With PlaceId 0 there is no DataStore (DataService.lua:181, MORNING_REPORT.md:64). The user has to publish the place and turn on API access before any retention work can matter.

## 1. The player loop

**Minutes 0-2.** You spawn in a silent corridor, because music beds aren't allowed yet. The tour card asks you to read the credits wall, which is 21 rows of text you can't do anything with. Then you power the console: +5 XP and the meters wobble.

**Minutes 2-10.** At the studio PC, slot 1 opens already filled with DefaultPattern (DAWClient.lua:195).
- **The "make a beat" tour step needs no beat-making.** Pressing SAVE without touching a pad completes the step and pays +10 XP, because CellsDiffer(nil, p) returns 80 (DAW.lua:40,138,144 → Tour.lua:74).
- **ON MONITORS lasts 6.8 s.** It plays 4 loops of one bar, which is 6.8 s at 142 BPM (DAWConfig.lua:41, DAW.lua:172). A 20 s cooldown follows.
- **The tour ends quickly** and pays +50.
- **First impression is the weakest part.** At level 1 the 808, hat rolls and swing are locked (DAWConfig.lua:27). Those three are what make a beat sound like OK's genre.

**Minutes 10-30.** The day's XP runs out around minute 12.
- Mic pays 10 XP every 2 minutes into a shared Activity cap of 60 a day.
- Beat saves pay 10 XP, five times a day (Config.lua:28-33).
- The best XP strategy is spamming a mic that records nothing (InteractionService.lua:46-56).
- After that nothing moves: no goal, no currency, no new content. The instrument (1 bar × 5 sounds) has been fully explored.

**Why come back tomorrow?** Only to refill the XP cap.
- Day 1 tops out around 160 XP and later days give about 110.
- That puts level 3 (rolls) on day 2 and level 4 (swing) on day 4.
- Levels 5-10 unlock nothing (Config.lua:37), and level 10 arrives around day 29.
- XP buys nothing. There are no streaks, dailies, events, charts or friends.

**Spaces with nothing to do:**
- The booth is one button that turns on a red light for 8 s.
- The lounge has a TV with 3 static screens, a text panel and seats.
- The light switch and door are toys.

## 2. Single-player vs social

**Single-player in a shared room:**
- Beat making. The preview plays 2D in SoundService, so only you hear it (DAWClient.lua:35, DAWEngine.lua:25).
- Saves and slots, XP and levels, the tour, the credits panel.
- The profile. ProfileFunction only ever returns your own (InteractionService.lua:169).
- Banners and toasts, which all go to you alone through FireClient.
- There are no nameplates or leaderstats, so nobody sees your level.

**Shared but contested, so a second player is an obstacle:**
- One NowPlaying slot. "Busy" means you are refused, and there is no queue (DAW.lua:162).
- The booth's `recBusy` lock (InteractionService.lua:28,47).
- One Chair_Seat (DAW.lua:204-207).
- The console, light and door toggles change the room for everyone. The console has no room-wide cooldown (Config.lua:41).

**Truly social: exactly one thing.** You can hear someone's beat with "prod. <name>" on the side screen and TV (DAW.lua:177).
- A listener's only option is Mute (HUD.lua:86).
- There are no reactions, no "save this beat", no reply and no collab.
- A grep finds no MessagingService, MemoryStore, OrderedDataStore, BadgeService, TextService or BillboardGui. A server with 1-2 players has no audience at all.

## 3. Cheap extension points

| Hook | Where | What it can carry |
|---|---|---|
| `InteractionService.Register(kind, fn)` plus the `OK_Interactable` tag and `Kind` attribute | IS.lua:16,136 | New stations, such as a battle pad or a booth game. It silently overwrites an existing kind (DAW re-registers Computer). |
| Events `InteractionService.Used`, `DAW.Saved`, `DAW.BroadcastTried` | IS.lua:14,157; DAW.lua:8-10 | Quests, dailies, achievements, analytics. |
| Tour engine: steps table, `Advance`, server-driven card and highlight | Tour.lua:11-55, TourUI | Reusable for daily challenges and quest chains. |
| `DataService.AddXP(p, n, source)` with `Config.XP.Sources` rules | DataService.lua:138; Config.lua:28 | New XP sources by config only. The Progress event already drives the floats and banners. |
| `Config.Unlocks` with `DAW.Validate(..., level)` gating | DAW.lua:19-37 | Unlocks for levels 5-10. |
| `DAW.Validate` and `CellsDiffer` | DAW.lua:19,39 | Server checks on beats submitted to battles or challenges, including anti-copy. |
| `NowPlaying` attributes, `DAWEngine.Start(sync)` server-time playback, `parentFor` | DAW.lua:173-176; DAWEngine.lua:78-99; DAWClient.lua:296-326 | Battle rounds, queued listening, synced playback from any part. |
| `BeatBus.Step` | BeatBus.lua | Beat-reactive neon, crowd bounce, a timing minigame in the booth. |
| Replicated `Level` and `XP` player attributes | DataService.lua:33-36 | Overhead nameplates. |
| Profile table: any field not starting with `_` persists; `migrate()` and SchemaVersion | DataService.lua:49-66 | Fires received, battle record, streaks. |
| Systems loader `Init(ctx)` and `LightingService.Apply(preset)` | Main.server.lua:10-15 | Turning on the five stubs without touching Main; lighting for showcase moments. |
| Beats are 80-character strings from a fixed alphabet | — | Can be shared across servers with no text filtering, as long as beats have no titles. |

Caveats:
- Remotes are created in build scripts (06_runtime.lua:8, 10_daw.lua:7-9), not in src.
- PanelUI tabs are a hardcoded list and the renderers are local to PanelUI (PanelUI.lua:25,67).
- `ctx` carries no DAW or monitor service.

## 4. Technical debt that blocks bigger gameplay

1. **The beat format is rigid.** Each beat is one track-major string of Tracks × Steps (DAWConfig.lua:4-11).
   - Validate demands the exact length (DAW.lua:21).
   - Upgrade only knows 64 → 80 (DAWConfig.lua:35).
   - The phone pager is clamped to 2 pages (DAWUI.lua:398), and the Sessions tab loops over slots 1-3 (PanelUI.lua:42).
   - Slots carry no format version.
   - More bars, patterns, a song mode or a 6th track all need format v3 plus a migration.
2. **The monitors belong to DAW alone.** The token and cooldowns are module locals (DAW.lua:12-13), with no acquire/release or queue. BeatBattles can't book the speakers until that logic moves into a separate MonitorService.
3. **Beat state lives in the client GUI** as the root attribute "Pattern" (DAWUI.lua:342-344). Collab needs a server-owned pattern with a remote for each cell edit.
4. **Saves have no session lock.** UpdateAsync ignores `_old` (DataService.lua:119), so the last write wins when a player hops servers quickly. That blocks any soft currency, battle record or economy.
5. **There is no text filtering anywhere.** Beat names, producer tags, bios and invites all need TextService first.
6. **There is no cross-server layer:** no charts, feed, beat of the day, follows or reserved battle servers.
7. **The instrument has a low ceiling:** 5 samples and 1 bar. The 808 pad cycles through 5 notes, though the server accepts ±12. Pitched playback already works (DAWEngine.lua:32), so a melody row only needs a licensed pitched sample plus the v3 format.
8. **The broadcast is 4 bars** (DAWConfig.lua:41), too short to judge or vote on.

## 5. Top 5 gaps, ranked by retention damage

1. **The XP wall hits about 12 minutes into day 1, and the ladder is empty after level 4.** It hits every player, and XP rewards button presses, not music.
   - *Cheap fix:* use the Tour engine for daily beat challenges and add XP sources tied to music.
   - Fill levels 5-10 with unlocks: APM/PSE kits, more slots, a wider BPM range, neon cosmetics. No Robux needed.
2. **Nobody responds to your beat.** The payoff is a 6.8 s replay to people whose only option is mute.
   - *Cheap fix:* FIRE reactions on NowPlaying that pay XP to the author.
   - Show "fires received" on the profile, and add nameplates built from the `Level` attribute.
3. **Other players are obstacles, not partners.** One slot, no queue, one chair, one booth lock.
   - *Fix:* a MonitorService with a queue.
   - Then BeatBattles: two submitted beats, rounds played in sync through the `sync` path, a room vote, and Validate plus CellsDiffer for checks.
4. **The instrument is used up in about 15 minutes.** One bar, five sounds, no melody or arrangement.
   - *Fix:* format v3 with 2-4 bars or A/B patterns, a melody track and a kit choice.
   - Every sample stays APM or PSE, which the t14 test already checks.
5. **Nothing brings players back and nothing crosses servers.** No streaks, no daily, no charts, and an empty server has no audience.
   - *Fix:* a streak and a daily challenge stored in the profile, then an OrderedDataStore "beat of the day".
   - This needs publishing and session-locked saves first.

**Still waiting on the user:**
- The audio answer, before any music beds or background sound in the rooms.
- Fan-made or official, before any challenges branded with OK's name.
- Explicit titles, before any credits trivia.