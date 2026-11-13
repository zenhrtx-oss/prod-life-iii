# Day One in your bedroom: build report

November 12, 2026. Built from your decided chain (`plans/2026-11-05-wave3-stakes.md` Task 5e, 11-06) and the rooms design (`specs/2026-11-12-progression-and-rooms-design.md` §4.9 "it all happens in your bedroom", D3 and D10 option C), on top of the rooms core (your bedroom, doors, your laptop's rack, your speakers). Your first minute is now a chain of choices in your own room: you wake up, JUNO VALE asks for a beat by tonight, you make it at your laptop, "play it on your speakers?", "spend it?", then the first visitor knocks. It replaces the passive tour as the way in. The old tour stays as a small DAY ONE pill with SKIP.

## Try it

1. **Press Play.** Every Play starts a fresh career. (If no card comes, a test run's pause may have been left on: run `tools/walkins_pause_off.lua` once in Edit mode, or ask me. Nothing is left on as of tonight.)
2. **Wake up in your bedroom.** About a second later the first card arrives: header DAY ONE, JUNO VALE with a portrait in her colour, tag "FIRST REQUEST · BY TONIGHT", bottom button SKIP. Her line: "i need a beat by tonight and i have exactly zero. $400 if you can make one?" The DAY ONE pill shows "1/5: Open your laptop to make a beat", and your laptop pulses.
3. **Each choice on card 1.**
   - **On it. Make it now.** takes her request and opens the beat maker at your laptop on the starter-beat chooser.
   - **Haggle: ask for $450.** is a 50% roll. "she said yes. $450 when it's done." means +$50 on top of her pay, once. "she won't budge. $400, final." means no bonus. Then it goes on as Make it now. Ask me to fix the roll to see both.
   - **Look around first.** closes the card. JUNO comes back once, 30 s later, but only if you pressed it in your first 25 s. A second Look around brings no third card.
   - If you're more than 14 studs from your laptop: "got it. your laptop's on the desk.", and the pill points at it.
4. **The beat maker and the coach mark.** Pick a starter beat (BOUNCE, say), then change it until every ask ticks green. In a desktop-size window a small label "All green? Press DELIVER" sits left of DELIVER. On a phone no label shows: it hides rather than cover a button. The "Tap the request to take it" label only shows if you open the request list yourself (after Look around). The monitors label never shows; the pill's line guides that step.
5. **Deliver.** JUNO pays $400 ($600 at 3 stars), plus the $50 if the haggle won, even if you pressed SKIP in between. A bedroom laptop has no cut to the studio booth: the result screen shows at once. Close it.
6. **"Play it on your speakers?"** About 3 s after you deliver (it waits for the result screen to close), card 2 opens over the beat maker: YOUR BEAT, tag "YOUR SPEAKERS · FIRST LISTEN". "On my speakers. Let's hear it." plays your beat on your bedroom speakers: "sounds good. air it in the studio next." "Keep it private. Headphones on." gives +10 XP once: "your secret's safe · +10 XP". Neither pays Money or Aura.
7. **"Spend it?"** About 4 s later, card 3: "you've got $… spend it? Roll FX is $250. next goal: Desk monitors, $500 and 200 followers." "Hit the gear rack." closes the beat maker and opens the Gear tab (within 12 studs of the rack by your laptop; farther: "the gear rack is by your laptop"). "Save it for the monitors." just closes. Either one ends Day One: "DAY ONE DONE · +50 XP", and the pill goes away.
8. **The first visitor.** 5 to 7 s later someone knocks: one of the six random starters from Wave 3 (they walk in, every answer pays at least +5 Aura).
9. **SKIP** on any card, or on the pill, ends Day One at once with no XP. The first visitor still comes 5 to 7 s later.
10. **The wander path.** Look around and never take the request, and the first visitor still finds you about 85 to 90 s after you woke. The pill stays, and no more visitors or phone messages come until you finish or press SKIP.
11. **The hub path.** After Look around, walk out: your bedroom's "Leave" door, the landing's "Front door", the hall's "Go back / The studio" door. Take JUNO's request at the studio PC and deliver there. No card 2 comes. The pill says "Press ON MONITORS so the room hears it", and pressing it brings card 3 about 4 s later. "Hit the gear rack." there only shows the "by your laptop" line, then ends Day One.
12. **Phone size.** Pick a phone in the device emulator and repeat. Card 1 comes before the beat maker opens, and cards 2 and 3 show over it. Every button is at least 44 px. Screenshots: `captures/day_one_2026-11-12/`: card 1 in your bedroom and "Make it now" opening the beat maker at your laptop, both taken in a normal Play at Studio's 1151×741 view. A true phone-size look still needs a phone or Studio's device emulator.

## How sure I am

- **Studio suite (final run, 11-12 19:17–19:40, the finished code):** 260 of 260 pass: every rule check, every Edit check and every Play file, t10 included. It's the first fully clean full run. Before the last fixes the full run was 259 of 260. The one miss, t16, was a test leaving XP behind and is fixed. After the last fixes the affected files re-ran clean: 5 of 5 Edit checks and 86 of 86 Play checks, t16 after the rooms tests that caused it among them. t10 (the beat maker's meter) now passes too, because Studio's game view is 1151×741.
- **Outside Studio:** all 13 rule checks pass. The money simulation's output was byte-identical after every task, since nothing in Day One feeds it. So the money table in `WAVE3_REPORT.md` still holds. Day One itself pays only +$50 once (the haggle), +10 XP once (keep it private) and the tour's existing +50 XP once.
- **Red first, then green:** for every task I showed its new checks failing on the old code for the predicted reason, then passing after the code was synced. The words task has no checks. Three hiccups were not game bugs: a connection drop while another session was loading the machine (t47 and t57 passed 14 of 14 once the load fell), a test run in a custom order that skipped a purchase it needed (t21), and the known chair-timing flake t64n (passes alone).
- **What the checks cover:**
  - t121a: the first card, the hold that keeps the first visitor away, Look around, SKIP, and no card at all in the old tests.
  - t122a: cards 2 and 3, the $50 paid once, the hub path, an old half-done save, and the phone path (the first visitor hidden under the beat maker).
  - t123: the card and the pill on screen at three phone sizes, with no button under 44 px or overlapping.
  - t124: the whole first minute from the player's side, with the haggle's answer shown above the beat maker.
- **Reviews:** each task was reviewed, with a fix round and a scoped re-review wherever something was found. A final whole-branch review said "needs fixes": 0 critical, 2 important, 6 minor. Both important ones are fixed:
  - On a phone, after Make it now, the first visitor could walk in mid-beat, hidden under the beat maker, and cards 2 and 3 then waited up to 5 minutes behind them.
  - The pop-up lines, including whether JUNO said yes to the haggle, showed under the beat maker.
- **The fixes were re-reviewed** (`final-rereview.md`): all addressed, nothing critical or important new, three minors:
  - A burst of pop-ups can arrive late, and a fifth waiting one drops the oldest.
  - A 0.2 s race can put a Day One card over a visitor's card the player had just started reading; the visitor's card comes back after.
  - One test assertion can't tell why it holds.
- **No path pays twice.** Each one-time payment is marked before it is paid. The Studio test commands can't be reached on a live server.
- **Nothing added to the world:** 0 new parts, lights, sounds or uploads. New on screen: the coach label layer and the pop-up layer.
- **Saves:** schema is still v5. The one new field is the Day One state (haggle result, bonus paid, private used), filled in lazily and wiped with the tour. It has only met fake stores. One more real save and load before any publish, together with Wave 3's newer fields.
- **Not covered by any check:** the card parking on a phone (a visitor's card put aside under a Day One card and brought back; the checks only run it, they don't assert what shows), a real phone (layouts were measured at 667×375, 771×390 and 844×390 only), and how late pop-ups feel after a burst. Timing in the tests is fast-forwarded, so the real first minute is for you to feel.

## Needs you

1. **Approve the words.** `research/day_one/copy_2026-11-12.md` §9 (57 rows), plus these that §9 doesn't have or that changed:
   - JUNO's real $400, the $450 ask and the +$50 size (rows 1.3, 1.5, 4.1, 4.2; call 1).
   - Three chip lines made from the card names: "JUNO VALE IS WAITING · OPEN", "YOUR BEAT IS WAITING · OPEN", "YOUR MONEY IS WAITING · OPEN". They show when a Day One card is waiting behind something.
   - Three "couch" lines the review found (`Data/WalkIns.lua` :390, :1296 and the waiting line at :2568). The bedroom has no couch. My own grep also finds one at :2579, "had to go before i fell asleep on the couch".
   - Row 4.7 "the gear rack is by your laptop" reads wrong for a hub player, who has no laptop.
   - Row 5.8 "Press ON SPEAKERS so the room hears it" overclaims: at tier 1 only people next to you hear it.
   - Row 8.6 "Shoo it out the door." is optional. Row 6.1's "All green? Press DELIVER" sits on a chip that reads REQUESTS on a phone, but there it hides anyway.
2. **Say yes or no on the calls below.** Look hardest at 1 (JUNO's pay and the haggle size), 6 (how long the first visitor waits for your first beat) and 17 (every pop-up in the game moved to a new layer).
3. **Play Day One once yourself, phone size too, and don't publish before that.** The standing rule holds: I never save or publish.
4. **Save the place** (Ctrl+S, File > Save to Roblox) after this session's last sync. First check no test pause or real-save switch is left on (`tools/walkins_pause_off.lua`, `tools/real_save_off.lua`).
5. **Before any publish:** one more real save round trip, and the two-player test on a published build (Wave 3's list still stands).
6. **Next:**
   - The rest of the rooms plan, R-T8 to R-T16: story upgrades, placing your things, the placement screen, your walls, the home studio, posters, door modes, and the 12-plot phone test.
   - The people plan (`plans/2026-11-12-people-and-progression.md`), including its Task 2, the "never cold in week 1" rule decided for Wave 3 and not built yet.
   - Aku's beat-maker design (5f, due Tue 11-17 per the Wave 3 report) may replace the beat maker's layout. Day One's labels find its controls by name, so they need a recheck then.
7. **Codex's integration proposal is on your desk:** `../design_input/codex/integration_blueprint_2026-11-12.txt`. Its §7 names a seam: choosing a request replaces your active one, so a promise you had accepted would be erased by the next pick. The deeper-careers plan needs a saved project record or a clear hand-over.

## Claude's calls

Each is switchable. The cost of changing one is a number, a flag or a line of copy.

1. **JUNO's pay on card 1 is her real $400 ($600 at 3 stars), and the haggle asks $450.** The +$50 is paid once, on her first request's first delivery, even after SKIP. Why: she really pays $400, so the 11-06 text's "$50" would be wrong by $350 and would cut the first session's floor from $625 to $75, losing the first monitors in session 1. Say if you want a different bonus (+$100) or the old text.
2. **The haggle is a flat 50% roll.** Why: a new player's stats are all zero, so a tilt changes nothing.
3. **Look around brings JUNO back once, 30 s later, and only if pressed in the first 25 s. The returned card closes at 70 s.** Why: 11-06's "about 60 s" would land after the first visitor is due (70 s plus 15 to 20). Two numbers.
4. **An ignored card 1 stays up 180 s and holds the first visitor meanwhile.** Why: someone with a card open has something to choose, and an AFK player still ends up finished.
5. **Never taking the request keeps the old rule:** first visitor at about 90 s, then no visitors or phone until you finish or press SKIP. Why: an unfinished tour blocks them today. To switch: end Day One, skipped and unpaid, when the first visitor's card closes.
6. **While you've taken a request but not delivered it, the first visitor waits, up to 240 s after waking.** An abandoned beat means the first visitor at about 255 to 260 s. It holds for any request you take, not only JUNO's. Why: on a phone they used to walk in mid-beat and hold cards 2 and 3 for up to 5 minutes. One number.
7. **Cards 2 and 3 can open over a visitor's card that is hidden under the beat maker.** The visitor's card is put aside and comes back after. Why: the same stall, as a backstop. Still only one card on screen.
8. **Card 2 appears only after a delivery at your own bedroom laptop.** It plays that beat on your room speakers (studio kit, first voice): no airing, no FIRE, no Aura. A hub delivery skips it and keeps the pill's ON MONITORS step. Why: it all happens in your bedroom, and a new player owns no other kit.
9. **Cards 2 and 3 show over the beat maker, and card 2 waits for the result screen to close.** No room laptop has the listen-back cut until the rooms plan's R-T12. Why: the phone beat maker hides the waiting chip, and the old cut aims at the hub booth about 6,000 studs away.
10. **A returned or resumed card 1 stays hidden behind the phone beat maker** until it closes or 70 s pass. Switch: show it over the beat maker too (one flag).
11. **Every choice on cards 2 and 3 finishes its step, and card 3 finishes the whole tour (+50 XP once, with no gear purchase needed).** SKIP pays nothing. Why: an unfinished tour blocks visitors, the phone and the cold news.
12. **"On my speakers" plays in your bedroom wherever you stand,** a resumed card included. Why: it's your room's speakers. Parked as polish.
13. **Card 3 offers the cheapest tool you can afford and names Desk monitors as the next goal,** not something to buy. It skips free items and anything with a follower requirement. Why: monitors need 200 followers and level 2, and after one delivery you'd have 40 to 120 and level 1.
14. **"Hit the gear rack" opens the Gear tab only within 12 studs of the rack.** Opening the Gear tab from the server now closes an open beat maker for every player. Why: the tab would draw under it, and only card 3 can trigger this today.
15. **"Make it now" opens the beat maker only within 14 studs of your laptop.** Why: no teleports, and the beat maker closes past 14.
16. **Coach labels:** only the desktop DELIVER label and the request label can show. The monitors label and the phone DELIVER label hide whenever they'd cover a button, a message or the pill. Why: Aku owns the beat maker's design, and a label must never block a pad. Switch: a spot outside the window.
17. **Pop-up lines (toasts) moved to their own layer above the beat maker, shown 2.5 s each, 4 waiting at most.** This changes every pop-up in the game. Why: Day One's, including whether JUNO said yes, were drawn under the beat maker. Cost: after a burst one can arrive seconds late.
18. **A rejoin restarts the hold** (70 s, or 240 s with the request taken). Why: fixing it needs a saved timestamp, and the saved Day One state is fixed at four fields. Only someone rejoining over and over delays their own first visitor.
19. **Old saves resume from their tour progress:** the card their progress names, card 2 playing their newest recent beat, no migration. Only test accounts exist.
20. **JUNO's card shows a generic figure in her colour, and cards 2 and 3 show none.** Her name comes from the artist list, so it doesn't switch with the parody or fiction names. Why: no art uploads, and she isn't in the walk-in cast.
21. **The DAY ONE pill follows where you are:** your laptop (pulsing) in your room, the studio PC elsewhere, hidden under a card. Why: no extra server messages.
22. **Room-neutral words.** Seven hub-worded lines (panel tabs, two beat maker messages) and seven walk-in lines (the pigeon, mom's plate) lose "lounge" and "studio PC". The keyboard phone card's "lounge couch" waits for the rooms plan's R-T8. Why: you read them in a bedroom, so one text for both places.

## Where things are

- **Code** (under `src/ReplicatedStorage/OK/`): the chain is `Systems/DayOne.lua`; rules `Modules/DayOneRules.lua` (pure); words `Data/DayOne.lua`; numbers `Config.lua` (`Config.DayOne`); screens `Modules/WalkInUI.lua` (the cards), `TourUI.lua` (the pill), `CoachUI.lua` (the labels, new) and `PanelUI.lua` (the pop-up layer). Changed seams: `Systems/Tour`, `WalkIns`, `Contracts`, `Gear`, `DAW`, `Data/WalkIns`, `OK/DAWClient`, `OK/ClientMain`. `Systems/Rooms.lua` is untouched.
- **Build:** `build/20_day_one.lua` makes the three remotes. Run it in Edit after `19_rooms` and before syncing `Systems/DayOne`.
- **Tests:** `spec/day_one_spec.lua` (13 rule checks in all), `build/t120_check` (Edit), `t121a`, `t122a`, `t123a` to `e`, `t124a` to `c`. Edited for Day One: t17b, t56, t61b, t72d, t104a, t105d, t106a.
- **Design, plan, words:** `plans/2026-11-12-day-one.md`, `research/day_one/copy_2026-11-12.md`.
- **Reviews and ledger:** `.superpowers/sdd/2026-11-12-day-one/` (`progress.md`, `final-review-findings.md`, `final-fix1-report.md`, `final-rereview.md`, one report and review per task).
- **Snapshot:** `v42_rooms_and_day_one` in the place (`ServerStorage.OK_Versions`, 760 parts); offline copy `places/export_2026-11-12_1912/`. Commits 90a57a4 to 5e1d6f4; this report's commit is "D1-T7: Day One integration and report".
- **Tracker:** `../OK_GAME_TRACKER.md`.
