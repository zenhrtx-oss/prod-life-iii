# Wave 2 "the career remembers": build report

October 30, 2026. Built from your nine design answers and your go on the plan (`specs/2026-10-30-wave2-career-remembers-design.md`, `plans/2026-10-30-wave2-career-remembers.md`). The game now remembers your career: how long you've been at it, what happened, who you worked with, and how famous you got.

## Try it

1. In Studio, press Play and finish or skip the tour. If a test run was interrupted, run `tools/walkins_pause_off.lua` once.
2. **Your nameplate** now starts with your career year: `YEAR 1 · LV 1 · INTERN`. Your FIRE count stays at the end.
3. **Open the panel (OS) and pick Story,** the new sixth tab. FIRSTS is at the top, 12 ticks with the career day each happened. Your career follows, newest first, one line each.
4. **Credits** now lists every placement and hit above your session credits.
5. **Profile** shows your title, tier, year and ribbons. Other players see the same line on your card.
6. **Career** has three bars: Followers to the next tier, XP to the next level, and THE HALL's needs.
7. **Reach 1,000 Followers.** A `YOU'RE BUZZING` banner appears, and one or two walk-ins later a superfan comes by, once ever. KNOWN, FAMOUS and ICON work the same way, each with their own visitor.
8. **Come back on a new day.** Each real day you play adds one career day, and a `DAY 8 · YEAR 2` toast shows when you join. Days you miss don't age you.

## How sure I am

- **Studio suite (final run):** 185 of 189 pass, counting 8 CLI specs, the Edit checks and every Play file. The only failures are the four light-cap checks (61 lights against your cap of 36).
- **One rerun:** t65b failed once and passed on its rerun. It's a timing check on the phone card's reaction, in a stretch when the Mac's load was over 30. None of the files changed in the last fix round touch it. That cause fits, but I didn't prove it.
- **After the last fixes:** 9 of the 12 test files I ran failed on the old code first, then passed. One of them, t72c, stopped at its setup rather than at its own check, so the new DAY toast check was never shown failing on its own.
- **One gap in that:** Task 3 (the server wiring) never had its failing run, because its implementer synced the code too early by accident. Its tests have passed on the real code ever since.
- **On screen:** I looked at captures of the Story and Profile tabs at normal size, and Story at phone size (667×317). Six tabs fit, and FIRSTS reads cleanly in two columns. On that phone size the first story line sits 249 px down, under two scrolls of the short panel. Before the fix it was more than four.
- **Reviews:** every task had its own review. The final review ran four angles plus a senior reviewer ("ready with fixes") and found four real problems, all fixed and retested:
  - you couldn't see your own title and ribbons
  - STORY and the discography were buried on phones
  - the DAY toast could get lost on join
  - a tier visit could take your first-ever walk-in from the gentle first visitor
- **Nothing added to the world:** 0 new parts, 0 new lights, 0 new sounds.
- **Saves:** tested with fake stores only. The new `prof.life` data has never touched real Roblox storage, so one real save and load is needed before any publish.

**Money and pacing** (20 simulated players, and 200 more on recorded seeds), all inside your limits:

| Check | 20 seeds | 200 seeds | Limit |
|---|---|---|---|
| Cards' share of a typical player's money | 36.5% | 36.5% | ≥ 34.1% (your floor) |
| Most for a player who always takes the best pay | 46.6% | 47.2% | ≤ 50% |
| THE HALL opens (typical day, worst 10%) | day 4, 5 | day 4, 6 | days 4–6, by day 7 |
| Legend, earliest (any player) | day 17 | day 17 | day 15 or later |
| Phone Aura a day (typical / always the one-hit wonder) | 12.7 / 14.0 | 12.2 / 13.9 | ≤ 15 |

- **When players reach each tier** (typical player): BUZZING day 1, KNOWN day 2, FAMOUS day 4–5, ICON day 19.
- **Honest headroom:** the best-pay player has about 2 points left before 50% on 2,000 fresh seeds (1.2 at the worst I saw). The floor has about 2 points.
- **What the money checks can't see:** they only start counting on day 8, so they barely see the first three tier visits. Those visits pay little: $300–$500 plus Followers.

## Needs you

1. **Approve the words.** Everything new is listed in `research/wave2/copy_2026-10-30.md` §11:
   - the four tier visits and their payouts
   - the new visitor, THE LABEL BOSS / A LABEL CHAIRMAN
   - 13 story lines and 7 first-time versions
   - the 12 firsts, 10 titles and 5 ribbons
   - the DAY toast, the 4 banners and the bar text
   - from the final review: "You bought the Legend nameplate.", `RIBBON: {label}`, the 🎗 mark, the Story footer, and "Your career history didn't load this time."
2. **Say yes or no on these calls (each switchable):**
   - **Titles:** `NEW IN TOWN` for a brand-new player, or no title at all. `CHART MAKER` is the hit title, because HITMAKER is already a rank.
   - **SPONSORED / BRAND DEAL** stay after a sponsor drops you. That's fine for a ribbon, but as a present-tense title it may read oddly.
   - **The profile line** is `title · tier · YEAR n`. When both are the same word it shows once (`FAMOUS · YEAR 2`), but near matches double up: `WELL KNOWN · KNOWN`.
   - **The banner** draws over everything for its few seconds, and waits behind a result card.
   - **The tier names** live in Config.
   - **Ribbon toasts** have no sound, and several landing together share one toast.
   - **Which story events log every time,** and which only the first time (copy §4 notes).
3. **Slower players, your call:** visits take walk-in slots, so at the lowest pace (2 walk-ins and 2 phone pops a day) THE HALL moves from a median of day 7 to day 8, and the slowest 10% from day 16 to day 17. If you want that day back, a small Aura bump on the tier visits does it.
4. **Known limits, not fixed:**
   - A tier visit can delay your mom's plaque or a sponsor drop by a visit or two.
   - "Once ever" means at most once. If walk-ins are switched off when you cross a tier, that visit doesn't come back.
   - From another producer's card, the Profile tab shows the real title above `Level 1 · XP 0 · Money $0`. That zero line is older than this wave.
   - A ribbon toast can replace another toast, including DAY. The ribbon itself is still earned.
   - Two rare save-loss cases older than this wave came up in the save review. They should be fixed before a real publish, and I've kept them on the list.
5. **Still yours from before:** save the place, listen to the six Wave 1b sounds, the 1a and two-sessions approvals, the light budget, a real solo play, a phone test and a two-player test.

## Rulings I made for you

Every call is in the plan's amendment sections and the build ledger (`plans/2026-10-30-wave2-ledger.md`), each with why and what it costs if wrong. Besides the ones above: FAMOUS sends the blogger rather than a second manager visit; only ICON's visit pays Aura; tier visits pay no Placement or XP; old test profiles start at career day 1 with firsts they obviously have marked `BEFORE DAY 1`.

## Where things are

- **Code:** `Modules/LifeRules.lua` (the rules), `Systems/Life.lua` (the server side), `Modules/PanelUI.lua`, `Modules/HUD.lua`, `Modules/Nameplate.lua`, `Config.lua` (`Config.Life`), `Data/WalkIns.lua`.
- **Tests:** `spec/life_rules_spec.lua` and `build/t70`–`t73c`.
- **Design and plan:** `specs/2026-10-30-wave2-career-remembers-design.md`, `plans/2026-10-30-wave2-career-remembers.md`, `research/wave2/`.
- **Snapshot:** `v36_wave2` in the place (`ServerStorage.OK_Versions`); offline export `places/export_2026-10-30_2146`; code checkpoint `checkpoints/W2T5_2146`.
- **Tracker:** `../OK_GAME_TRACKER.md`.
