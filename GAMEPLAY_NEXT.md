> Recommendation from a 9-agent read-only workflow on 2026-10-22 (code audit, market research, platform research, 3 design directions, 2 judges, synthesis). Source reports: research/gameplay_2026-10-22/.
> Status: the user said go at 15:09; Milestone 4 (all six steps) was built, independently reviewed and fixed by 17:15 the same day (59/59 tests). Deviations: levels 6, 8 and 10 add gear or rank only (artists arrive at 1, 3, 5, 7, 9); beat slots stay at 3 (slots 4-6 would crowd the phone header); the listen-back is a short camera cut into the vocal booth.

# OK Studio: what to build next

## 1. The core idea

Fictional artists send you session requests ("NOVA KAY: 140-150 BPM, kick on the one"). You build the beat while a checklist ticks green, then DELIVER it for stars, a reaction, Cred and a credit line ("Night Shift · NOVA KAY · prod. you"). Cred buys studio gear, and your rank floats overhead. Anyone in the room hears your beat on the monitors and can tap FIRE, but the loop works alone.

## 2. Milestone 4 (revised): "Studio Sessions"

About two nights. **Cut line:** if night 2 runs long, #6 slips to M5.
- **Budget:** no images, no new lights (21/24), about 150 parts.
- **No player-typed text:** generated song names and display names only, so text filtering can wait.
- **Free play stays.** New controls work by touch (≥44 px at 844×390 and 667×375) and by gamepad.
- **(your check)** marks checks that need two players or your ears. Everything else is an automated Studio test.

**1. Safe foundation (M).** Progress can't roll back.
- **Save lock:** today UpdateAsync ignores `_old`. Add a server ID and timestamp lock, taken over only when stale.
- **Schema v2:** adds Cred, gear, and credits capped at 50. There are no real profiles yet, so nothing needs migrating.
- **Reward gate:** today an unknown source pays uncapped XP, and a rule with no cooldown crashes. Fix both, and give Cred its own log.
- **XP rebalance:** Mic and Console share a cap of 30 a day.
- **Visible failures:** a failed system is silent today, and test.py hides "[OK]" warnings. Each system sets `InitOK`, and a test checks it.
- *Uses:* t13 fake stores, DataService._now.
- *Done when:* a locked fake store gets zero writes, a misspelled source pays 0, a broken system fails the suite, and the 29 tests pass.

**2. Room for three (M).** "#2 in line" replaces "busy", and UP NEXT shows on the screens.
- Two extra laptops let three people build at once.
- Airings run 12-20 s with 3 s of silence between them. The existing neon pulses on the beat.
- *Uses:* NowPlaying, the DAWEngine `sync` path, BeatBus, Register.
- *New:*
  - `Services/MonitorService.lua` on `ctx`: a queue of 4, one per player, with a Config off switch.
  - `Systems/Stations.lua`.
  - Fake-player test hooks (`_StudioTestHook` needs a real Player today).
- *Done when:* three fake owners air in order, a duplicate is refused, airings at 60 and 200 BPM both last 12-20 s, every station saves and queues, and the updated "busy" tests pass.

**3. Session requests + new tour (L).**
- **Building:** start from a preset (Dark 142, Bounce 160, Slow 75) or a blank grid. 2-3 asks tick green as you go. A bonus ask earns the 3rd star, and a near miss names the missing ask.
- **DELIVER:** plays a listen-back while the artist reacts in the vocal booth, so the booth finally has a job. The artist is built from parts and only you see them.
- **New tour:** station, an easy starter request, air it, first gear. The credits wall becomes optional.
- **One grader:** a pure `Modules/BriefCheck.lua` ticks on the client and grades on the server. Dailies and cyphers reuse it.
- **Fair offers:** only requests your gear can satisfy.
- **Anti-copy:** a delivery must differ by 8+ cells from DefaultPattern, every preset, your last delivery and the beat on air. Raw beat strings are never shown.
- *Uses:* Validate, CellsDiffer, DAWEngine, the Tour engine.
- *New:* `Data/Artists.lua` (4 artists, about 15 briefs), `Systems/Contracts.lua`, and a Deliver remote in `build/10_daw.lua`.
- *Done when:* 20 fixture beats grade correctly, an untouched preset is refused and doesn't advance the tour, a repeat pays 0, and tapping pads flips the ticks.

**4. Cred, ranks, gear rack (M).**
- **Ranks** sit over the levels, Intern up to Studio Legend.
- **Rack:** glows with neon and uses no lights. The 808 is free. Roll FX and Swing are the first buys, and session one pays for both.
- **Levels 5-10** each add an artist and a rack tier: slots 4-6, an on-air neon colour, a nameplate colour.
- **Gating:** the `DAWConfig.Unlocks` gate moves from level to gear. PanelUI tabs become data-driven and gain a Gear tab.
- *Uses:* the Tycoon stub. *New:* `Config.Ranks`, `Config.Gear`.
- *Done when:*
  - an unaffordable buy is refused;
  - owning Roll FX lets rolls pass;
  - the rewritten unlock tests pass and lights stay at 21;
  - a pacing simulation at 3 deliveries a day owns the basics on day 1 and reaches the top tier no sooner than week 3.

**5. FIRE + rank nameplates (M).**
- While a beat airs nearby, tap FIRE. The author gets "+1 FIRE" and a little Cred.
- **Limits:** once per airing, only after loop 1, never on your own beat. At most 3 per listener-author pair a day, plus a daily author cap.
- **Listener XP:** for the tap only, never for standing nearby.
- **Nameplate:** "LV 4 · ENGINEER · 37 FIRE", MaxDistance 40.
- *Uses:* AddXP, the NowPlaying token. *New:* `Systems/Reactions.lua`, `Modules/Nameplate.lua`.
- *Done when:* a double FIRE counts once, a pair's 4th FIRE pays 0, a self-FIRE is refused, and the nameplate updates on level-up.

**6. Daily requests + streak (S, first to slip).** 3 requests picked by UTC date, the same in every server, plus a streak.
- *Uses:* BriefCheck, the TourUI card. *New:* `Systems/Dailies.lua`.
- *Done when:* on a faked clock, two servers pick the same 3, each pays once, and a missed day resets the streak.

Then your 10-minute play test, solo and with two players **(your check)**.

## 3. Milestone 5 (after the private publish) · BUILT 2026-10-22 evening (83/83 tests)

1. **Weekly Single + producer card (M).** 3 stars earns a plaque. Tapping a player shows a public card through a new remote, and ProfileFunction stays private. *Done when:* only public fields come back.
2. **SAMPLE IT / flips (M).** Copy the beat on air. It airs after 8+ changed cells as "flip of Maya", and Maya earns capped Cred. *Done when:* an unchanged flip is refused.
3. **Licensed kits as gear (M).** APM/PSE one-shots that you audition. *Done when:* t14 passes and remote listeners hear the author's kit.
4. **Head-to-head and Cypher (L).** With 2 players, most stars wins. With 3+, there's an opt-in anonymous vote after a full listen, with no self-votes. There's never a vote with only 2. *Done when:* fake entries finish a round.
5. **Drop-off funnel (S).** AnalyticsService steps from Used, Saved, Deliver and Fire. *Done when:* each step logs once.

## 4. Later

- **Custom studios:** decor in the shared studio first. Personal studios wait on reserved servers.
- **Collabs:** wait on a server-owned beat.
- **Melody:** BUILT 2026-10-22 night as Milestone 6, the piano roll (format v3, KEYS view, licensed music box / pluck / chime voices; README "Milestone 6"), then remade in FL Studio's style on 2026-10-23 as Milestone 7 (keyboard, ghost notes, move/stretch editing, velocity lane with accents, chord stamp; README "Milestone 7"). **Song mode** (more than one bar) still waits on a longer-pattern migration.
- **Charts and async battles:** wait on the "music library" licence answer.
- **Titles, bios, invites, networking:** wait on TextService filtering.
- **City:** waits on funnel retention data.
- **Audio API mixer and booth voice FX:** wait on a real-phone test.
- **OK in the game:** waits on fan-made vs official, plus written approval.

## 5. Moved or cut from the old Milestone 4

- **Fire + nameplates:** kept (#5), showing rank.
- **Neon tube signs:** cut. The existing neon pulses on the beat for free.
- **Readable credits wall:** waits on the titles decision and adds no play.
- **Lived-in furniture:** postponed, except the stations and rack.
- **Launch kit:** the funnel moves to M5. The trailer and stills wait; stills need upload approval.

## 6. Decisions you need to make

1. **Explicit titles, "Perc Soda" and the bar bottles, before any friend joins.** *Default:* hide them (`ShowExplicitTitles` is `true` today) and remove the bottles.
2. **Private publish, API access, MaxPlayers 12, after M4 #1.** *Default:* yes.
3. **Override the ROADMAP "Not now" for daily challenges and battles?** *Default:* dailies now, battles in M5.
4. **808 free at level 1, with cheap rolls and swing?** *Default:* yes.
5. **Do queued airings count as "music beds"?** *Default:* allowed at 20 s or less, with gaps and an off switch.
6. **Artist names, about 15 clean song titles, currency and ranks.** *Default:* "Cred" and Intern to Studio Legend, checked against real artists.
7. **Fan-made or official.** *Default:* generic, no OK name.
8. **The "music library" clause.** *Default:* keep everything in one server.
9. **The maturity questionnaire.** *Default:* answer it before Public, and expect 13+.
10. **Kit audition (M5).** *Default:* the agent shortlists, you listen.

## 7. Risks to watch

1. **Requests feel like homework.** Watch whether you're skimming the asks by your third delivery.
2. **Saves and Cred are untested on real storage until you publish.** Run a private two-server test before friends join.
3. **Moderation on an account that already has a strike:** explicit titles, invented names that match real artists, and a 13+ rating against a 10-16 pitch.

## 8. Scorecard

- **CAREER:** fun 8, feasibility 8. The winner and the spine of the plan.
- **SOCIAL:** fun 6, feasibility 7. Supplies the queue, stations, test hooks and the later Cypher.
- **CREATIVE:** fun 6, feasibility 5. Supplies the presets, early 808, XP rebalance and flips.

Where the judges split:
- **SOCIAL ahead of CREATIVE:** SOCIAL fixes multiplayer cheaply, while CREATIVE's format rewrite delays the gameplay.
- **No XP for standing nearby:** it would repeat the mic-spam exploit.
- **Nameplates in M4:** they're cheap, and ranks give them meaning.
- **A free 808:** the first minute sounds right, and the rack still has a first purchase.