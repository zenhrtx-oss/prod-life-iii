# Life Happens 1b: build report

October 29, 2026. This covers Wave 1b of "Life Happens", the feel half. Every stat change now shows on screen. Cards sound and react. Negative Aura heals a little each day, and now and then visitors come in bursts. You said "go" on October 28; the build ran overnight, with your pause from 17:28 to 01:34.

## Try it

1. In Studio, press Play. Finish or skip the tour. If a test run was interrupted, run `tools/walkins_pause_off.lua` once so visitors and the phone aren't paused.
2. **Watch the pills.** Every change to Aura or Followers floats its amount under that pill in the stat's colour, and the pill gives a quick ring pop. Placements, hits and sponsors have no pill, so they float under the Aura pill. Money and XP still float as before.
3. **Read the card footer.** The line at the bottom of a walk-in or phone card now follows your Aura:
   - below 0: "Your Aura's in the red. People hesitate. Odds stay hidden."
   - 0 to 299: "Your Aura and Followers tilt the odds. You never see them." (as before)
   - 300 and up: "Your Aura's loud. People lean in. Odds stay hidden."
4. **Listen.** A card opening plays a rising whoosh. A win plays a bell ding, a loss a dull thud, money a coin clink, and a planted follow-up a short synth tone. A phone message arriving plays a short buzz. The HUD's mute button silences these too.
5. **Watch your avatar.** On a win it cheers; on a loss it sits on the floor for two seconds. It skips the reaction when you're already seated, in the beat maker or its listen-back, moving, dead, or on an R6 avatar.
6. **BUSY DAY.** Now and then, when a visit ends, two or three more visitors come 10–20 seconds apart, and a gold BUSY DAY chip shows under the pills. The quiet after a burst is longer by the time the burst saved.
7. **The daily heal.** If your Aura is below 0, five seconds in the hub moves it up to 5 points toward 0, once a UTC day: "the internet forgot. +N AURA".
8. **The phone icon** now pulses every 12 seconds while a message waits, instead of every 4.

## What's in the game now

- **Server** (`Systems/WalkIns`, `Systems/Phone`, `Config`):
  - rush bursts on the walk-in timer (`Config.WalkIns.Rush`: a 15% chance per visit, 2–3 short gaps of 10–20 s, the saved time added to the next quiet gap, never past the daily cap), shown through the player attribute `BusyDay`
  - the daily Aura heal (`Config.Career.Sources.AuraHeal`: up to 5, once a day through the reward gate)
  - a `planted` flag on every result that queued a follow-up
  - the six UI sounds in `Config.SFX`
- **Pure rules, spec-tested** (`Modules/WalkInRules.RushGap`, `Modules/CareerRules.HealAmount`, `Modules/Format.AuraFooter`), and the pacing sim models the heal (`Modules/CareerSim`).
- **HUD** (`Modules/HUD`, `Modules/UITheme`): per-stat floats in two columns, the pill pop, the BUSY DAY chip. On wide screens a long float in the Aura column shrinks to fit rather than running into a Followers float beside it.
- **Cards** (`Modules/CardFeel`, new, used by `Modules/WalkInUI` and `Modules/PhoneUI`): the footer by Aura band, the sounds, the avatar reaction, and result chips in the stat colours.

## How sure I am

- **Studio suite (final run, October 29):** 165 of 169 pass: 7 CLI specs, 30 Edit checks, the budget gate and 131 Play files. The only failures are the four light-cap checks, which wait on your light budget (item 1 under Needs you). There were no flaky runs and no reruns. After one last small follow-up, the HUD and phone-card tests ran again: 11 of 11.
- **New tests failed first where they could.** Before each change was synced, its new tests ran against the old code. They failed for the expected reason, then passed after the sync. Three exceptions:
  - Task 6's own changes (the 12 s pulse, the Config comment, the t57b pre-check) pass on correct old code too.
  - The cypher-bar float check never ran red, because its test stopped at the banner check first.
  - The 800 px cypher-bar check was added after the fix as extra coverage.
- **Reviews:**
  - Every task had a spec-and-quality review. Task 2 got one small fix from its review, Tasks 1, 3, 4 and 5 passed with none, and Task 6 needed one fix round.
  - At the end, a whole-wave review ran four adversarial angles (server exploits, economy and pacing, the screens at both phone sizes, and regressions in older systems) plus a senior reviewer. A second reviewer then tried to disprove every finding.
  - The server-exploit angle found nothing. Seven small findings survived (two were the same) and two were refuted. The senior verdict was "ready with fixes".
  - All of them were fixed, each with its own regression test, in one last pass. A probe in Studio settled the one engine question behind them.
- **Fixed in that pass:**
  - A burst no longer starts when only one visit is left before the daily cap.
  - A phone card that moves under your finger ignores taps for 0.6 seconds.
  - The LEVEL UP banner draws over floats.
  - Floats start below the cypher bar while it covers them.
  - Opening the studio PC during the 2-second floor sit no longer closes the beat maker when you stand.
  - Config now says the heal switches off with walk-ins.
  - Six small test and safety items, including a test that a phone result planting a follow-up plays its sound.
- **Economy, unchanged from 1a** (20 simulated players over 60 days):
  - THE HALL opens around day 4 (days 4 to 5 for most players).
  - Legend never comes before day 18.
  - Cards supply 35.4% of a typical player's money (floor 35%, ceiling 50%), and 42.6% for a player who always takes the best pay.
  - The phone sends 6.0 messages a day and adds about +11 Aura a day.
  - The daily heal doesn't move these, because the modelled players almost never start a day in the red (1 of 4,800 player-days).
- **Rush, measured over 1,000 simulated days:**
  - With an hour in the hub a day, visits stay at 8 a day with or without bursts, because the cap binds.
  - With 30 minutes a day, visits go from 6.16 to 6.53 a day (+6%).
  - Bursts that finish bring two or three visitors (289 of two, 261 of three).
- **Not tested:** a real phone, two players, a gamepad, and an R6 avatar; the R6 skip is checked by reading only, because the test avatar is R15. No person has heard the sounds yet. I picked them by library, name and length, and Studio checks each one's creator.

## Needs you

1. **Save the place** (File > Save to Roblox). The tools can't save. The light budget (61 lights against your cap of 36) still waits on you; this wave added none.
2. **Listen to the six sounds.** All are from Roblox's licensed ProSoundEffects library, and no sound was uploaded. Two are stand-ins because nothing licensed fit better:

   | Plays on | Sound | Id | Note |
   |---|---|---|---|
   | a card opening | Rising Whoosh Hissing Build Up Ascending | 9125805579 | |
   | a win | Synth Sparkle Tone High Pitch Bell Tone Burst | 9126071452 | |
   | a loss | Wood Hit Giant Wood Beam Dull Thuds Knocks 5 | 9120885415 | |
   | money | Coins Drop Wood Table Hits Brass Gear 1 | 9113848780 | stand-in: both cash-register sounds run over 1.5 s |
   | a planted follow-up | Tone Clusters Classic Synth Switch Tones 18 | 9120131970 | |
   | a phone message | Switch Blurt Single Short Synth Buzzes 6 | 9119715399 | stand-in: no licensed phone vibration is 1 s or shorter |

   Each key has a checked alternate in `research/wave1b_sounds_2026-10-28.md`; swapping one is a single id in `Config.SFX`.
3. **New words: approved (October 29).** You approved the three footer lines, the heal toast "the internet forgot. +N AURA" and "BUSY DAY" as written.
4. **The calls I made.** On October 29 you kept the four that change what the design said: the burst spacing, floats under cards on phones, and the mute covering the card sounds, with the short-session lift that comes with bursts. The rest, under "Rulings I made for you", stand unless you say otherwise.
5. **Room features that could join with a yes** (design §10, still out): sponsor ad gigs, fits that change the odds, the room features (toasts, TV charts, net worth, a streak freeze), and the entourage.
6. **Next:** your "two sessions, same day" card from the voice memo, planned right after this wave with the answers you gave.

## Rulings I made for you

The build didn't stop for questions. Every call is in the plan (`plans/2026-10-28-wave1b-feel.md`, "Rulings in this plan" and the amendment sections) and in the build ledger, each with why and what it costs if wrong. These are the ones a player can see, and each can be switched.

**Where the design said something else:**
- **Burst visitors come 10–20 seconds apart, not back to back.** After you close a card, a short timer runs, then the visitor walks in, so the next card opens about 17–32 seconds after your choice.
- **Short sessions see a few more walk-ins.** A burst pulls visits forward: at 30 minutes in the hub, about 6.5 a day instead of 6.2. Over a full day the pace and the cap of 8 are unchanged.
- **On phones, floats draw under an open card.** The card's own result chips show the same amounts at the same moment, and the pill pop shows above the card.
- **The HUD mute also silences the new card sounds.**

**Other calls:**
- No burst starts when no card could come, or when fewer than two visits are left before the day's cap.
- The BUSY DAY chip stays up while you're out of the hub, for example in THE HALL, although visitors only come in the hub.
- A phone message opened between burst visitors still leaves at least 10 seconds after you close it.
- Floats rise 6 px instead of 14, so they stop above the BUSY DAY chip's row.
- Placements, hits and sponsors float under the Aura pill. On wide screens a long one shrinks to fit beside a Followers float.
- On phones, while the cypher bar is up, floats start below it so a cypher win's +25 AURA stays visible.
- The LEVEL UP banner draws over any float passing under it.
- The heal tries once a UTC day, after 5 seconds in the hub. Its message names the amount actually healed (1–5). It stops when walk-ins are switched off in Config.
- The cheer is Roblox's standard `/e cheer` animation, because the avatar's own emote list has no cheer. A loss sits you on the floor for 2 seconds.
- If you open the studio PC during that floor sit, the beat maker opens without the chair view, rather than closing again when you stand.
- A phone card that moves (for example when the BUSY DAY chip appears) ignores taps for 0.6 seconds, so a tap meant for one row can't land on another.
- The Money and Plant sounds follow what happened, whatever the card's tone. A neutral result that plants a follow-up plays the Plant tone.
- The phone icon pulses every 12 seconds while a message waits, instead of 4.

## Where things are

- **Code:** `src/ReplicatedStorage/OK/Systems/WalkIns.lua`, `Systems/Phone.lua`, `Systems/DAW.lua` (one line), `Config.lua`, `Modules/CardFeel.lua` (new), `Modules/HUD.lua`, `Modules/UITheme.lua`, `Modules/WalkInUI.lua`, `Modules/PhoneUI.lua`, `Modules/WalkInRules.lua`, `Modules/CareerRules.lua`, `Modules/Format.lua`, `Modules/CareerSim.lua`.
- **Tests:** `spec/` (7 CLI specs, `rush_spec` new), `build/t60`–`t65` (rush, heal, floats, footer, reactions with the PC-from-a-floor-sit case in `t64m`/`t64n`, phone sounds), and the updated `t11`, `t46`, `t57b`, `t57d`.
- **Design and plan:** `specs/2026-10-26-wave1-life-happens-design.md` §4.5, `plans/2026-10-28-wave1b-feel.md` (rulings and amendments at the end), `research/wave1b_probes_2026-10-28.md`, `research/wave1b_sounds_2026-10-28.md`.
- **Snapshot:** `v34_wave1b` in the place (`ServerStorage.OK_Versions`, 725 parts); offline export `places/export_2026-10-29_0618`; code checkpoint `checkpoints/T7_0618`.
- **Tracker:** `../OK_GAME_TRACKER.md`.
