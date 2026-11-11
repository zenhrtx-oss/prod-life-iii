# Two sessions, same day: build report

October 30, 2026. This is your voice-memo card, built from your design answers of October 29 (notoriety is Aura, XP now plus a later comeback, a blended readiness check, a new kid each time, and a money floor of "no worse than today").

## Try it

1. In Studio, press Play and finish or skip the tour. If a test run was interrupted, run `tools/walkins_pause_off.lua` once.
2. The card needs 10 walk-ins in your career first, so it never comes in your first few minutes. After that it can arrive by phone, at most twice a week:
   > SESSION BOOKINGS: "two sessions, one day. pick one."
   - **Work with the kid from your hometown.** Always: +40 XP and +100 Followers. "He's raw, but he listens." About 10–16 walk-ins later he walks into your studio himself: most of the time his tape blew up (+$400, +1 placement, +800 Followers, +10 Aura), otherwise it was a local hit (+$150, +300 Followers).
   - **Work with the one-hit wonder.** One hidden roll. If you're ready, it went off (+20 Aura, +10 XP). If you're not, you weren't ready (−30 Aura, no XP).
3. **What "ready" means:** your level, placements, Followers and Aura, averaged. The chance runs from about 20% on day 1 to about 70% around day 5 for a regular player, and up to 90%. The odds stay hidden.
4. A level-up from this card's XP now shows the LEVEL UP banner above the phone card instead of behind it.

## How sure I am

- **Studio suite (final run):** 171 of 175 pass (7 CLI specs, the Edit checks and every Play file). Five files (the beat maker's t10 and the flip tests t26b–d) timed out while the Mac was busy and all passed on one rerun. The only failures are the four light-cap checks (61 lights against your cap of 36).
- **Every new Studio test failed first** on the old code, then passed after the sync.
- **On a phone:** at 771 and 844 px wide (a notched and an unnotched 844×390 phone), both choices show without scrolling. At 667 px the first choice shows whole and the second one's top shows; the card scrolls, like every phone message at that size.
- **Reviews:** every task had its own review. A final review ran four angles plus a senior reviewer (verdict "ready"). It found two real problems, both fixed and re-tested: the message was too long for phones, and the one-hit wonder's Aura pushed an always-celebrity player over the phone's Aura budget.
- **Money and pacing** (20 simulated players, and 200 more on recorded seeds), all inside your limits:

| Check | 20 seeds | 200 seeds | Limit |
|---|---|---|---|
| Cards' share of a typical player's money | 35.9% | 35.8% | ≥ 34.1% (your "no worse than today" floor) |
| Most for a player who always takes the best pay | 44.8% | 47.2% | ≤ 50% |
| THE HALL opens (typical day, worst 10%) | day 4, 6 | day 4, 5 | days 4–6, by day 7 |
| Legend, earliest (any player) | day 17 | day 17 | day 15 or later |
| Phone Aura a day (typical / always the one-hit wonder) | 12.3 / 14.2 | 12.3 / 13.9 | ≤ 15 |

- **Honest headroom:** if phone messages are spread through the day instead of after the walk-ins, the best-pay player reaches about 48.7% (still under 50%). Legend now comes at day 17 instead of 18, because of the card's XP.

## Needs you

1. **Approve the new names:** SESSION BOOKINGS / BOOKING DESK (the sender), and A KID FROM BACK HOME / A KID FROM YOUR OLD BLOCK (the kid). The web checks were clean. The second is close to the existing A KID FROM THE BLOCK.
2. **Approve the new lines:** "two sessions, one day. pick one."; the two choices; YOU WENT HOME ("He's raw, but he listens. You learned more tonight than a month of tutorials."); THE SESSION WENT OFF ("He brought his old fans with him. People noticed you."); YOU WEREN'T READY ("He played his one hit four times and left. People saw."); the comeback's HE BLEW UP and LOCAL HIT. "One-hit wonder" is just a phrase; the press often ties it to one real artist, so the copy never pairs it with that artist's parody.
3. **Approve the calls I made (each switchable):**
   - the one-hit wonder's win is +20 Aura (the design said +40; +40 put an always-celebrity player at 18 Aura a day, over the phone budget of 15)
   - the message is one short line, because a longer one hid the second choice on phones
   - the readiness blend and its scales (level 7, 5 placements, 30,000 Followers, 600 Aura)
   - the XP chip is orange
   - the LEVEL UP banner now draws over everything for its 3.5 seconds, including the beat maker and the panel (taps still go through)
   - the sender's hidden style label is "studio sessions"
4. **Known limits, not fixed:**
   - "Never on your first day" counts walk-ins, and walk-ins reset at midnight UTC. A first session that crosses midnight UTC (US evening) can see the card after about 50 minutes and get +40 XP.
   - "A new kid each time" is in the words and the booking, but the kid looks the same on every visit.
5. **Still yours from before:** save the place, listen to the six Wave 1b sounds, the 1a names and lines, and the light budget.

## Rulings I made for you

Every call is in the plan (`plans/2026-10-29-two-sessions.md`, Rulings and amendments) and the build ledger (`plans/2026-10-29-two-sessions-ledger.md`), each with why and what it costs if wrong. Besides the ones above: taking neither session (DISMISS) costs nothing; a second kid pick while the first is still on his way gives the XP but books no second visit; the card's XP goes through the same daily XP limit as every other source.

## Where things are

- **Code:** `src/ReplicatedStorage/OK/Data/WalkIns.lua` (the card, the kid, the comeback), `Modules/WalkInRules.lua` (readiness), `Systems/Phone.lua` (XP, readiness at the server), `Systems/WalkIns.lua` (the chip), `Modules/CareerSim.lua`, `Modules/HUD.lua` and `Modules/UITheme.lua`, `Config.lua`.
- **Tests:** `spec/` (7 CLI specs), `build/t66a`–`t69`.
- **Design and plan:** `specs/2026-10-29-two-sessions-design.md`, `plans/2026-10-29-two-sessions.md`, `research/two_sessions/`.
- **Snapshot:** `v35_two_sessions` in the place (`ServerStorage.OK_Versions`, 725 parts); offline export `places/export_2026-10-30_0402`; code checkpoint `checkpoints/T6_0403`.
- **Tracker:** `../OK_GAME_TRACKER.md`.
