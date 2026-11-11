# Life Happens 1a: build report

October 28, 2026. This covers Wave 1a of "Life Happens", the part you approved on October 27: the phone, the new people and cards, and visits that behave more like people. Wave 1b (feel: the room reacting, small fixes) gets its own plan next.

## Try it

1. In Studio, press Play. Every Studio session starts with a fresh profile, so finish or skip the tour first. If a test run was interrupted, run `tools/walkins_pause_off.lua` once so visitors and the phone are not paused.
2. **The phone icon** sits beside your Aura and Followers pills (top right on narrow phones). About two minutes in, the first message opens by itself, as long as the beat maker is closed, no visitor card is up and no cypher round is on. After that, one every two to three minutes, up to six a day, at most two waiting at a time.
3. **Two kinds of message.** A DM (MESSAGES from an artist, UNKNOWN NUMBER, STUDIO ALERT, PAGE WARNING) gives you up to four choices and DISMISS; your Aura and Followers tilt the hidden odds, and some choices cost money. NEWS ALERT just tells you something happened and closes itself after eight seconds. Phone items never pay money; they only move Aura and Followers.
4. **If you are in the beat maker,** the phone waits: the badge counts what is waiting and the icon shakes. The card opens when you close the beat maker. A message you never open is gone after ten minutes. A DM you opened but did not answer closes after five.
5. **Visitors.** While a visitor waits for you behind the beat maker, he says a waiting line now and then. If he gives up (five minutes), a note card tells you who left, how long he waited and what he said on the way out. A city pigeon sometimes lands on the lounge coffee table; a nine-year-old who says he is next, a man selling aura, a stranger from abroad, a kid from down the street, a talk-show booker, a youth coordinator and your mom can all walk in now.

## What's in the game now

- **The phone** (`Systems/Phone` on the server, `Modules/PhoneUI` on screen): pops picked from the same deck as walk-ins, with its own timer (first 90–150 s, then 120–180 s), six a day, two waiting at most, ten-minute expiry, one open DM at a time. A DM open holds the walk-in timer, and a walk-in on screen holds the phone, so you never see two cards.
- **New content:** 21 walk-in cards, 21 phone cards and 13 follow-ups, six waiting lines and six parting lines, on top of the Milestone 8 deck. Seven new visitors (your mom, the booker, the coordinator, three weird ones, the kid from the block), four phone senders, a youth programme called HOMEROOM BEATS, and the pigeon. Every name was web-checked (`research/wave1_names_2026-10-27.md`); the fiction roster switch still swaps every name.
- **Rules** (`Modules/WalkInRules`, pure and spec-tested): stat gates (`needs` / `under`) on cards, a gentle first visitor that never costs money, per-day and per-week caps with groups, the artist cooldown across the phone and the door (an artist who DMs you can't DM or walk in again for three walk-ins), follower gates on the bigger news cards, a rookie gate.
- **Visits that behave like people** (`Systems/WalkIns`, `Modules/Visitor`): waiting lines, the note card, visitors standing apart from each other, three new looks (apron, headset, lanyard), the pigeon figure (11 parts, no lights).
- **Choice telemetry** (`Systems/Funnel`): every card choice, walk-away, news, expiry, note and phone open or expiry is logged with its source, card and detail, so a live server can tell you which cards people skip.
- **The pacing sim** (`Modules/CareerSim`) now models the phone, so the money guardrail is measured with it in.
- **On screen:** the phone icon with a badge, the phone card (header, message, up to four 44 px choices, DISMISS, the result inline), the "IS WAITING" list for visitors, the note card, and the cypher bar laying itself out after the icon.

## How sure I am

- **Studio suite (final run, October 28):** 140 of 144 pass (6 CLI specs, 30 Edit checks, 108 Play files; 139 in the full run plus t46 re-run once after a Studio "not reachable" flake). The only failures are the four light-cap checks, which wait on your light budget decision (item 1 under Needs you). The combined phone and walk-in run (t42–t58, 37 play files) passed 37 of 37 twice in a row.
- **CLI specs:** 6 of 6 pass (rules, data, sim, pacing, format).
- **Reviews:** every task had a spec-and-quality review with fix rounds where needed (Task 3: one, Task 6: two). After the phone server, a three-angle adversarial review (server exploits, economy, regressions) found four small things; three were fixed on the spot and one is written up below. At the end, a whole-branch review ran four adversarial angles (server exploits, economy, the phone screens at both phone sizes, regressions in the older systems) plus a senior reviewer over everything; every finding went to a second reviewer told to disprove it. The senior verdict was "ready". Nine findings survived (one important, eight small), two were refuted, and eight of the nine were fixed with their own regression tests in one last pass; the ninth (the phone icon keeps pulsing every four seconds while a message waits) is a feel item for 1b.
- **Fixed in that last pass:** on phones the icon in the corner no longer covers the FIRE button (FIRE moves under it); the phone card moves under the stacked pills instead of clipping them; the "IS WAITING" chip stays clear of an open phone card; a NEWS can't be dismissed while it is still loading; a chip tap made while a phone message is open is dropped rather than remembered; a second pigeon takes the first free spot on the table; the phone's seventh daily award is tied to its daily count in a test; switching the phone off in Config no longer strands two walk-in threads.
- **Economy, measured across 20 simulated players over 60 days** (the guardrail you set: walk-ins and the career layer never pay more than half of a player's money):
  - THE HALL opens around day 4 (day 4 to 5 for most players; the target is 4–6).
  - The Legend nameplate never comes before day 18.
  - Cards supply 35.4% of a typical player's money, and at most 42.6% for a player who always picks the best-paying choice. The ceiling is 50%; the floor for the typical player is 35%, and we sit just above it (item 4 below).
  - The phone sends 6.0 messages a day and adds about +11 Aura a day (budget +15).
- **Not tested:** a real phone, two players, a gamepad. There is nothing new to listen to: this wave adds no sounds.

## Needs you

1. **Save the place** (File > Save to Roblox). The tools can't save. The light budget (61 lights against your cap of 36) still waits on you; this wave added none.
2. **Approve the names.** Each has a parody and a fiction version:
   - YOUR MOM / YOUR MOTHER (you decided mom comes; the parody name is flagged only because it is a stock phrase)
   - THE TALK SHOW BOOKER / A LATE-NIGHT BOOKER
   - THE YOUTH COORDINATOR / THE OUTREACH COORDINATOR
   - A KID WHO SAYS HE'S NEXT / A VERY CONFIDENT NINE-YEAR-OLD
   - A MAN SELLING AURA / AN AURA SALESMAN
   - A STRANGER FROM ABROAD / A FARAWAY VISITOR
   - A KID FROM THE BLOCK / A KID FROM DOWN THE STREET
   - UNKNOWN NUMBER / PRIVATE NUMBER (flagged: "Unknown Number" is also the title of a 2025 Netflix documentary)
   - NEWS ALERT / NEWS PING, STUDIO ALERT / GEAR ALERT, PAGE WARNING / ACCOUNT ALERT
   - A PIGEON / A CITY PIGEON (flagged: the bare word names some small acts and companies)
   - HOMEROOM BEATS, the youth programme, in both rosters (flagged: a startup called Homeroom exists)
3. **Read the lines.** Every new card, choice, reply, waiting line and parting line is listed word for word in `research/wave1_names_2026-10-27.md` under "Lines", generated from the data file. Change anything you don't like in `src/ReplicatedStorage/OK/Data/WalkIns.lua`. Lines to look at first:
   - the UNKNOWN NUMBER scam: "Real badges are free. You deleted the message."
   - the hacked-page card: "Pay a recovery service." costs $300 and works half the time
   - the rival's text (he used to walk in to say you owe him; now he texts, and the bad ending costs 5 Aura instead of $100 and 5 Aura)
   - the pigeon speaks the same waiting lines as people ("yo you almost done?") when it waits behind the beat maker; the design doesn't say critters are silent, so I left it. Say if you want it to stay quiet.
4. **Economy changes to approve** (the design's own levers could not reach the 35% floor on their own):
   - **The big-visit cap.** The talk-show booker, the give-back visits and the three "famous" visits now share one visit a week. The design (§8.1) limited the booker by its stat gate only; with the booker uncapped, the typical player's share came out at 34.97%, just under the floor. Revert is one line per card; the next lever in line would be moving the rival's "ghost out" story to the phone.
   - **The rival's story moved to the phone** as NEWS, Aura only (above).
   - **Rookie cards** are limited by their gates only, not a cap; no rookie card shows up after day 8 anyway.
   - **The sponsor quiz** keeps the $300 "Sign it" bonus, quoted in the rep's line rather than marked on the right answer.
   - **Margin:** 35.4% on the spec's 20 seeds, 35.0% on 200 other seeds. A future content change that adds non-paying cards will need the next lever.
   - **Correction (October 29):** the "35.0% on 200 other seeds" can't be reproduced, because those seeds weren't recorded. A recorded 200-seed set gives 34.6% for the same game. On October 29 you set the floor for the next wave as "no worse than today" on that recorded set.
5. **Design calls I made inside the plan** (each switchable):
   - the artist cooldown covers artists only, from the moment a DM is sent; the blogger and the booker can both walk in and text, and are left out. You can widen it.
   - an artist who DMs you can't DM again or walk in until three more walk-ins have happened.
   - a story follow-up still walks in when due even inside that cooldown (a sequel is not a repeat).
   - your mom's plaque visit is a follow-up, so it skips her twice-a-week cap, and "the day after your first HIT" is one to two walk-ins later, which can land on the same day.
   - the phone icon sits beside the pills; at 667 px, and on notched phones narrower than about 712 px, it moves to the top right.
   - the phone card sits 8 px under the cypher bar on desktop widths; on phones the bar sits under the pills and shares the card's rows, like FIRE does.
   - a DM you opened and then hid by opening the beat maker still runs out after five minutes, counted as one of the day's six. The phone has no "I'm busy" pause the way visitors do.
   - a card you opened from the icon stays drawn if you open the beat maker afterwards (you asked for it); a card that opened by itself hides behind the beat maker and comes back when you close it.
   - the phone can award seven times a day instead of six: a DM opened just before midnight and answered after it counts on the old day and pays on the new.
   - the phone icon keeps pulsing every four seconds while a message waits behind the beat maker, for up to ten minutes. Easy to slow down in 1b if it annoys you.
   - `Config.Phone.Enabled = false` turns the phone off for a live server: the icon disappears and the two walk-in threads that continue on the phone (the booker's clip, the kids' letter) are not planted. The pacing numbers assume the phone is on.
6. **Things to listen to:** none.
7. **Next:** the Wave 1b plan (feel), then your open decisions (light budget, Robux, the parody names from Milestone 8).

## Rulings I made for you

The build ran without pausing on questions; every call is in the build ledger (`plans/2026-10-27-wave1a-ledger.md`, every line starting "Ruling:") with why and what it costs if wrong, and the plan's amendment sections carry the ones that changed the plan. The ones that change what a player sees:

- The big-visit weekly cap, the rival's story moving to the phone, the rookie gate and the quiz quote (item 4 above).
- Phone pops are picked when sent but counted when opened; a waiting pop holds one of the day's six slots and gives it back if it expires.
- A respawn drops waiting pops (never counted), like it drops a waiting visitor.
- An opened DM closes by itself after five minutes, and an unopened one after ten.
- An artist's cooldown starts when the DM is sent, not when it is opened.
- The server refuses a second DM while one is open, so a modified client can't hold the walk-in timer twice over.
- A DM closing never fires a visitor that was already due; the timer re-arms instead.
- The phone card follows the cypher bar down on desktop; on phones they share rows.
- A card opened from the icon stays over the beat maker; a card that opened by itself hides.
- The pigeon is "A CITY PIGEON" in the fiction roster and sits on the coffee table; its tag names the lounge.

## Where things are

- **Code:** `src/ReplicatedStorage/OK/Systems/Phone.lua`, `Systems/WalkIns.lua`, `Systems/Funnel.lua`, `Modules/WalkInRules.lua`, `Modules/CareerSim.lua`, `Modules/Visitor.lua`, `Modules/PhoneUI.lua`, `Modules/WalkInUI.lua`, `Modules/CypherUI.lua`, `Data/WalkIns.lua`, `Config.lua` (`Config.Phone`, `Config.Career.Sources.Phone`).
- **Tests:** `spec/` (6 CLI specs), `build/t46_check.lua` (pacing against live Config), `build/t51`–`t58` (phone and visits in Play), `build/t59_check.lua` (telemetry fields).
- **Design and plan:** `specs/2026-10-26-wave1-life-happens-design.md`, `plans/2026-10-27-wave1a-life-happens.md` (with the amendments at the end), `research/wave1_names_2026-10-27.md` (names, lines, pacing evidence).
- **Snapshot:** `v33_wave1a` in the place (`ServerStorage.OK_Versions`, 724 parts); offline export `places/export_2026-10-28_0213`; code checkpoint `checkpoints/T7_0214`.
- **Tracker:** `../OK_GAME_TRACKER.md`.
