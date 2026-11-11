# OK Studio proposal: "The room is the game"

## 1. Pitch
You don't decorate a studio, you perform in one. Every few minutes the control room calls a **Cypher**: a brief drops ("90-110 BPM, no clap"), everyone grabs a beat station, and three minutes later the speakers play each entry anonymously while the room picks a favourite. The winner's name hits the screens, their title glows over their head, and the next round is counting down. A 10-16 year old cares because it's the Dress to Impress runway loop with beats instead of outfits: short, judged by real people, status everyone can see.

## 2. First session story
- **0:00** Spawn. HUD: "CYPHER IN 2:40 · 3 PRODUCERS HERE". The tour card (reordered: station first, credits wall last) points at the nearest beat station.
- **0:30** The beat maker opens (808 unlocked if you approve decision 4). The tour step completes only after 4+ cells differ from the starter beat.
- **2:00** ON MONITORS. Someone is playing, so you're "#2 in line", not refused. You FIRE their beat; their nameplate count ticks.
- **3:00** Your beat plays under your name. Someone fires it: "+5 XP · 1 FIRE". Tour 3/4.
- **4:00** Cypher brief. Three minutes at any station; SUBMIT checks the brief live ("BPM must be 90-110").
- **7:30** Listening: BEAT A, B, C, authors hidden. One favourite pick, never your own.
- **9:00** Reveal: names, Neon lighting preset, podium. You lost but still earn entry and vote XP.
- **10-15** Queue again, fire others, round two, credits wall (tour 4/4). Alone? The round runs as a **Solo Brief**, graded 1-3 stars by the same rule checker.

## 3. Return hooks
- **Tomorrow:** your title and lifetime FIRE count are public, and the next title is a few rounds away (levels 5-10 become titles and cosmetics, not locked sounds). A **Daily Brief** streak (B2).
- **Next week:** **Friday Night Cypher** (B4), a scheduled bracket with an event-only nameplate frame and a Roblox "Notify Me" RSVP, plus a weekly licensed sound or brief pack.
- All of it needs decision 2 and A6.

## 4. Milestone A
A1 goes first. New remotes and geometry go in a new `build/14_social.lua`. Multiplayer checks use new `_StudioTestHook` commands (`EnqueueAs`, `FakeFire`, `FakeVote`, `FakeEntry`); the feel check is your 2-player Local Server test.

- **A1 MonitorService + queue.** Move `token`, `lastBroadcastEnd`, `finish`, `setScreens` from DAW.lua into `Services/MonitorService.lua` (`Enqueue/Release`, `anonymous` flag), passed as `ctx.Monitor`. Queue of 6, one per player; "busy" becomes "#n in line"; plays last ~14 s. Reuses NowPlaying, DAWEngine `sync`, `DAW.Validate`.
  *Done when:* three `EnqueueAs` owners play in order with gaps under 1 s, a duplicate is refused, screens show UP NEXT, and existing tests pass (updated where they asserted "busy").
- **A2 Beat stations.** Three laptops (bar, couch, booth), new `Kind="BeatStation"` handled in a new `Systems/Stations.lua` that sends `OpenDAW` with `seated=false` (DAWClient already handles standing opens; don't re-register `Computer`). `atStudioPC` becomes "at any station". ~60 parts, 0 lights.
  *Done when:* a play test opens, saves and queues from each station.
- **A3 FIRE + nameplates** (from M4). HUD FIRE button while a beat plays and you're in range; one per listener per play, never your own, 3 per listener-author pair a day. New `Fire` XP source (daily cap) pays the author via `DataService.AddXP`; profile keeps lifetime `fires`. BillboardGui "LV 4 · ENGINEER · 37 FIRE" from `Level` plus a new `Fires` attribute. Neon parts flash on `BeatBus.Step`. New: `Systems/Reactions.lua`, `Modules/Nameplate.lua`, `Config.Titles`.
  *Done when:* two `FakeFire` from one listener give 1 fire and one XP award, self-fire is refused, nameplate matches attributes.
- **A4 Cypher rounds** (enables the `BeatBattles` stub). Idle → Brief → Build 180 s → Listen → Reveal, triggered by 2+ players or a new Cypher board (`Register`). Briefs are preset server-checked rule tables (BPM range, banned or required rows, hit counts), drawn only from features every present entrant has unlocked. Entries pass `Validate`, the brief, and `CellsDiffer` ≥ 6 against `DefaultPattern` and other entries. Anonymous playback via MonitorService; one pick per voter, not own, in range only; ties go to brief score. Reveal uses `LightingService.Apply("Neon")` and a neon podium. XP for entering, voting, winning; profile `cypher = {entered, wins}`. Adds a DAWUI SUBMIT button and a HUD round timer.
  *Done when:* 1 real + 2 hook entries finish a round, a copy and an off-brief entry are rejected, a level-1 entrant can pass the brief, and the planted favourite wins.
- **A5 Solo fallback + first-session fixes.** One player: Solo Brief stars; two: head-to-head. `Tour.lua` steps reordered; beat step needs `CellsDiffer` ≥ 4 from `DefaultPattern`; `DAWConfig.Unlocks.Bass = 1` if you agree.
  *Done when:* a solo test gets a star grade and saving the untouched starter beat pays 0 XP.
- **A6 Session-locked saves.** `DataService.Save`'s `UpdateAsync` honours `_old` (JobId + timestamp lock, takeover only when stale).
  *Done when:* a fake store locked by another job gets zero writes and the player is told (t13 style).

## 5. Milestone B
- **B1 Live Set.** Perform your beat: tap lanes generated from your pattern, judged on the client against the server-time step clock, hit counts sanity-checked on the server, accuracy on the side screen. Reuses DAWEngine `sync`, `BeatBus`, MonitorService. New `Systems/LiveSet.lua`, `Modules/LiveSetUI.lua`.
  *Done when:* a scripted perfect run scores 100% and more taps than notes is rejected.
- **B2 Daily Brief + streak.** Date-seeded from the A4 brief pool, tracked like `Tour.lua` in the profile. New `Systems/DailyBrief.lua`.
  *Done when:* a hook-advanced clock shows streak 2, then 0 after a missed day.
- **B3 Producer tags (levels 5-10).** Pick an APM/PSE sting you've auditioned; MonitorService pre-rolls it before your beat. `Config.Unlocks`, nameplate neon colours.
  *Done when:* a level-5 profile's tag plays first and t14 passes.
- **B4 Friday Night Cypher.** `Config.Events` UTC slot switches `BeatBattles` to a 3-round bracket with an event-only frame.
  *Done when:* a hooked clock at the slot starts bracket mode.
- **B5 Drop-off funnel.** New `Systems/Funnel.lua` listens to `InteractionService.Used`, `DAW.Saved`, `DAW.BroadcastTried` and round events, logging AnalyticsService steps.
  *Done when:* each step logs once in a play test.

## 6. What it cuts or postpones from ROADMAP Milestone 4
- **Fire reactions, nameplates:** pulled into A; they are this direction.
- **Neon tube signs:** postponed; existing neon pulses on BeatBus (no parts, no lights).
- **Readable credits wall:** postponed; blocked on titles and adds no play.
- **Lived-in furniture:** postponed, except stations (furniture with a job).
- **Launch kit:** only the funnel survives (B5); trailer and stills wait, and stills need your image approval.

## 7. Risks and constraint check
- **No Robux:** nothing sold; everything earned.
- **Licensed audio:** A adds no samples; B3 stings are APM/PSE and pass t14. No music beds: monitors go silent when the queue empties, nothing loops between rounds.
- **OK's IP:** generic "Studio Cypher"; no OK name, tags or sounds.
- **No images:** BillboardGui/SurfaceGui text and Neon parts only.
- **No free-model scripts:** all code in src.
- **Mobile:** ~100 new parts (502 of 6000 now). Lights stay 21 of 24: effects are Neon colour and a LightingService preset. ≤12 nameplates with MaxDistance.
- **Explicit titles:** untouched; cyphers never show credits.
- **Modular:** MonitorService in `ctx`, systems via `Init(ctx)`, kinds via `Register`.
- **Text:** nothing player-written (icon reactions, "BEAT A", display names), so no TextService or TextChatService exposure.

Top risks:
1. **Fun, cold start.** Most servers will hold 1-3 players; voting-only games die empty (Auto Rap Battles had no running servers). Mitigation: Solo Brief, head-to-head, queue works at 2, invite prompt, Friday event.
2. **Technical.** One-station assumptions everywhere (`Chair_Seat`, `atStudioPC`, DAW-owned monitor state). Mitigation: A1 alone first, full suite after.
3. **Moderation and audience.** The pitch targets 10-16, but `ShowExplicitTitles=true` and "Perc Soda" break the Community Standards, and creation may mean 13+. Mitigation: positive-only reactions, anonymous entries, one pick each.

## 8. Decisions the user must make
1. Hide explicit titles and "Perc Soda" before any multiplayer or public test.
2. Publish privately, enable API access, MaxPlayers ≤ 12 (A6, B2 depend on it).
3. Battles and daily brief before launch, against ROADMAP "Not now"?
4. 808 at level 1; levels 5-10 as status unlocks?
5. Fan-made or official: can cyphers carry OK's name?
6. Licensed Music Terms "music library": until answered, no cross-server charts.
7. Audition B3 stings; pick the Friday slot; create Experience Events?
8. Maturity questionnaire: 13+ for creation?