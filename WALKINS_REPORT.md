# Walk-ins: build report

October 23, 2026. This covers the BitLife-style walk-ins you asked for: parody artists walk into the studio, you get a choice card, a hidden roll changes your career stats, and the stats unlock things.

## Try it

1. In Studio, press Play. Every Studio session starts with a fresh profile, so finish or skip the Studio Tour first.
2. Stay in the hub (corridor, lounge, control room or booth). About one to two minutes later a visitor (LIL NAV X, DOJA BAT, a sponsor rep, a rival…) walks in from the corridor to you. Everyone in the server sees him, his speech bubble, and the tag that pops over your head after you choose. Only you get the card.
3. Pick a choice. You don't see the odds; your Aura and Followers tilt them. Some choices plant a follow-up that comes back a few visits later: the single charts (a HIT) or flops, then a bigger choice.
4. Your Aura and Followers are the pills next to the HUD. The full Career tab is in the OS panel: six stats, the Studio Two door (1 placement, 300 Aura, $5,000), the sponsor TV toggle, and the gear and fits that need stats.

To play without visitors, run `tools/walkins_pause_on.lua` before pressing Play and `tools/walkins_pause_off.lua` afterwards.

Screenshots from Studio: `captures/walkins/1_card.jpeg` (the card), `2_result.jpeg` (a win and the tag), `3_career_tab.jpeg` and `4_career_unlocks.jpeg`.

## What's in the game now

- **Money shows as "$"** everywhere, and every price and reward is ×10. A session pays $250–$650, Roll FX costs $250, the Legend nameplate $4,000.
- **Career stats:** Money (the only thing you spend), Aura (can go negative), Followers, Placements, Hits, Sponsors. Beats feed them too: a first-time 3-star delivery gives +120 Followers and +10 Aura.
- **Walk-ins:** up to 8 a day, one every 4–6 minutes you spend in the hub, at most 3 visitors walking at once. Never before the tour is done or during a cypher round. If the beat maker is open, the visitor waits and a small "IS WAITING" chip shows; the card opens when you close it.
- **Content:** 9 sound-alike artists, 5 role visitors (sponsor rep, blogger, fan, rival, manager), 6 sponsors, about 45 cards and their follow-ups. One switch, `Config.WalkIns.Roster = "fiction"`, swaps every name for made-up ones.
- **Unlocks:**
  - The Studio Two door at the corridor (you walked in freely before; now you earn it).
  - Three fits built from parts: a Cuban link, a sponsor snapback and shades.
  - The IRON kit and Legend nameplate now need stats as well as money.
  - Your sponsor's name on the lounge TV.
- **A bug fix you'll notice in cypher rounds:** the FIRE button used to sit on top of the cypher bar. It now sits under it.

## How sure I am

- **Studio test suite (final run, October 24):** 117 of 121 pass. That's 114 in the full run plus 3 Edit checks re-run after the Mac's sleep interrupted them. The only failures are the 4 light-cap checks, which are waiting on your decision (item 2 below). Every walk-in test passed in real Studio.
- **CLI specs:** 6 of 6 pass. Rules, content and pacing are tested without Studio.
- **Reviews:**
  - Every task had a spec-and-quality review, plus fix rounds where needed.
  - A final four-angle review covered server exploits, economy and content, phone UI, and regressions. Every finding was checked by a second reviewer told to disprove it. 22 issues survived, and all 22 are fixed or written up below.
- **Economy, measured across 20 simulated players over 60 days:**
  - Studio Two unlocks around day 5 (day 3 to 6).
  - The Legend nameplate never comes before day 18.
  - Walk-ins supply 39.5% of a typical player's money, and at most 48.3% for a player who always picks the best-paying choice. The design's ceiling is 50%.

## Needs you

1. **Save the place** (File > Save to Roblox). The tools can't save.
2. **Lights:** the place has 61 lights against the cap of 36 you set this morning. The extra ones came from the Interscope LA import (another session, 26 lights); walk-ins added none. Raise the cap, or have the asset session trim lamps. Until then 4 QA tests fail.
3. **Studio window and sleep:** t10 (the beat maker's seated view) passes at your current 955×580 window and fails if the window gets as short as 452. Test runs also need the Mac awake: with the display asleep, Studio's client stops drawing, so prompts and sounds fail and about 45 tests go red. Running the suite under `caffeinate -d` avoids that.
4. **Approve the names** in `Data/WalkIns.lua`:
   - **Sponsors (parody):** RED BULB, NYKE, BEETS BY DRAY, SPOTIFRY, ROWLECKS, PRIYME. My web checks replaced three names that turned out to be real companies.
   - **Sponsors (fiction):** NITE OWL ENERGY, KICKFLIP FOOTWEAR, THUMPCAN HEADPHONES, GLOW GUM, STACKS BANK, SIPWAVE WATER.
   - **Fiction artists:** STIRRUP PEONY, VELVET FANG, SLEET VANTA, STATIC GOBLIN, ORBIT DUNE, QUILL MESA, SEQUIN MAPLE, HOOT CASTELLO, MOSS LULLABY.
   - **Close to real names:** NYKE, NITE OWL ENERGY and KICKFLIP FOOTWEAR each partly match a real act or brand.
5. **The "fiction" switch is only half a fallback.** It renames every visitor and sponsor, but the card text still nods at the real artists: re-recordings, friendship bracelets, a halftime show, a vault of unreleased songs, banjo trap, a sneaker launch, stitched beats. Each visitor's look and colour also stay the same. If you want it to work as a real moderation fallback, that's a follow-up job.
6. **Economy change to approve.** To keep a money-maximising player under the 50% rule, HITs got rarer instead of cheaper. The royalties stay $1,000–$1,200, but the base chance of a HIT dropped to 12–20%, about 37–45% for a player with decent Aura and Followers. A typical player gets 4–5 HITs in 60 days. The alternative is smaller, more frequent HITs ($500–$900).
7. **Design calls I left alone:**
   - **Cypher rounds:** any cypher round on the server holds new cards back for everyone, not just the players in it.
   - **Busy servers:** at the planned 12 players, an unanswered card closes after 90 seconds once another visitor is waiting.
   - **Daily cap:** 8 walk-ins a day.
8. **Read the cards** in `Data/WalkIns.lua` and change any line you don't like. Then do a 10-minute solo play and a two-player play.
9. **Optional polish:**
   - When the visitor stands next to you, his name plate and bubble overlap yours. Hiding his name plate once he arrives would clean that up.
   - The "DAILY REQUESTS" pill draws over the OS panel's title on short windows. That's older layout, not walk-ins.
   - Turning walk-ins off (`Enabled = false`) also keeps Studio Two locked and some gear unbuyable for players without the stats. Use the Roster switch for names instead.

## Rulings I made for you

Each one says what it costs if I got it wrong.

1. **Hidden diff history.** Your project isn't a git repo and you never asked for one, so I kept the diff history in `ok_studio/.superpowers/` instead. Cost if wrong: delete that folder; nothing else changes.
2. **Parallel agents.** I ran agents in parallel on separate files, where the process normally runs one at a time. Cost if wrong: a commit could bundle a neighbour's file. The reviews would have shown that, and none did.
3. **One Studio client.** I ran every Studio sync and test myself, and took turns with the other Claude sessions on a lease. Cost if wrong: slower integration, nothing else.
4. **t10 counted as a known failure.** You didn't answer about the window size. Cost if wrong: none; a bigger window passes it.
5. **Task 0 started early,** while the second plan check was still running. Cost if wrong: one redo of a small task.
6. **One baseline suite run** instead of before-and-after runs. Cost if wrong: one extra run.
7. **The cypher bar's HUD reserve went into Task 1,** because Task 1's wider HUD created the overlap. Cost if wrong: none visible.
8. **The pacing target went back to the design's,** after the plan had loosened it without saying so. Cost if wrong: a looser target recorded in the design.
9. **The gear rack sign now reads "SPEND YOUR MONEY"** instead of "CRED". Cost if wrong: one string.
10. **Sponsor reps only walk in once your Aura meets that sponsor's floor.** New players were signing at 0 Aura and getting dropped the next visit, in a loop. Cost if wrong: sponsor deals come later than you'd like; one condition to remove.
11. **The intermittent "infinite yield" warning was Studio start-up timing, not walk-ins,** and the fix was a timeout on that wait. Cost if wrong: none; the warning is gone.
12. **FireButton went to the UI fixer.** Nobody owned that file, and FIRE overlapping the cypher bar was a visible bug. Cost if wrong: a one-line revert.
13. **The light-cap failures weren't from walk-ins,** so I left the cap to you. Cost if wrong: none; nothing changed.
14. **The final fixes went to 3 agents in parallel** on separate files, instead of one. Cost if wrong: a mismatch where their work meets. The final Studio run would catch that.
15. **Documentation versus decisions:** the fiction-roster note and the README prices went into docs. Cypher scope, server size and the daily cap are your decisions, so they're listed above, not changed.
16. **HITs got rarer, not cheaper,** to keep the 50% walk-in share. Cost if wrong: you'd rather have smaller, more frequent HITs.
17. **Visitor routes re-tuned.** The first routes walked through the lounge sofa, the coffee table, the desk and the MIDI keyboard. A path probe now shows zero overlaps across 6 targets. Cost if wrong: slightly longer walks.
18. **A visit counts when the visitor arrives,** even if you ignore the card, so ignoring cards can't fish for better ones. This was changed while planning and is recorded in the design. Cost if wrong: one rule to flip.

## Where things are

- Design: `specs/2026-10-23-walk-ins-design.md`, with section 10 covering decisions made during the build.
- Plan: `plans/2026-10-23-walk-ins.md`.
- Build ledger: `.superpowers/sdd/2026-10-23-walk-ins/progress.md`, with every ruling and deferred note.
- Code: `src/ReplicatedStorage/OK/Systems/{WalkIns,Career,Unlocks}.lua`, `Modules/{WalkInRules,CareerRules,CareerSim,Visitor,WalkInUI,Fits,Format}.lua` and `Data/WalkIns.lua`.
- README section: "Added in Milestone 8 'Walk-ins'".
- Studio snapshots: `v28_walkins_waveB`, `v29_walkins_waveC` and `v30_walkins` (final). File checkpoints are in `checkpoints/`. An `.rbxm` backup is in `places/`.
