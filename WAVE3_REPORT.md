# Wave 3 "Stakes": build report

November 12, 2026. Built from your approval of the Wave 3 design on 11-05 (`specs/2026-11-05-wave3-stakes-design.md`, `plans/2026-11-05-wave3-stakes.md`) and your launch calls since: everything needed at launch goes in, the sound-alike names stay, and every visitor gets look B. Things now happen to a person, not to a number: your beat decides placement cards, a bad run has a shape you climb out of, and six people remember what you did to them. Around that: a first card within seconds, six random first visitors, one-line explainers, a new look for every visitor, and the fixes from the launch audit.

## Try it

1. In Studio, press Play and spawn. Every Play starts a fresh career. If a test run was interrupted, run `tools/walkins_pause_off.lua` once.
2. **The first card.** Touch nothing. In about 20 to 35 seconds a visitor walks in, before the tour is done. It's one of six picked at random: A RAPPER WITH NO BEAT, YOUR BIG COUSIN, THE NEIGHBOR NEXT DOOR, THE OPEN-MIC HOST, THE STUDIO OWNER or A KID FROM THE BLOCK. Every answer pays at least +5 Aura, and each card teaches one thing.
3. **The new look.** The visitor is built from 15 to 16 lanky shapes: a block head, a wedge nose, thin arms and legs that swing as they walk. Their card has a small face window. A phone message from a person shows one too. Messages from things (the news, the booking desk) don't.
4. **The explainers.** At the bottom of a card, a small grey "i" line explains a word the first time a card uses it, for example "AURA · your reputation. It tilts the odds and can go negative." Eight words, once each. On a phone card the line sits after the choices.
5. **Your beat counts.** At the Studio PC, take a request, hit its asks and DELIVER. When an artist pitches for a placement, their line now says "the one at 142", and the card's second footer line reads "Your best beat: ★★★ · 🔥 3", or "No beat delivered yet. Your odds are lower." The odds move: no beat -9 points, 2 stars -3, 3 stars 0, 3 stars with 3 or more FIRE +3. Ten choices do this: LIL NAV X's, the eight artist pitches and the rival's "split the cost". Visitors are random, so ask me to force one.
6. **The rival's diss track.** After you post a side-by-side against the rival, a diss-track card from him comes later and names the bar: "Needs a 3★ best beat. Yours: ★★☆." Below the bar is a sure loss (-30 Aura), at it a sure win. There are no dice. Ask me to set it up.
7. **The cold streak.** It takes three played days with no delivery, no FIRE and no cypher win, or Aura under -50, so ask me to set it up. A grey COLD chip appears under the career pills. The phone goes silent except one message, "STUDIO · QUIET": "your phone hasn't buzzed in days. make something people hear." Visitors drop to 2 a day, and Story logs "DAY 4 · Nobody was calling." Two ways out: deliver a 3-star beat, or get a FIRE on a beat you put on the monitors. Then `YOU'RE BACK` shows, and Story logs "You got people talking again." A 2-star delivery doesn't end it.
8. **Six people remember you.** Your choices with the rival, your mom, the kid from back home, LIL NAV X, your sponsor's rep and the tea blogger now move a private score and flags. Those decide which of 18 new cards they bring later, and tilt the odds on their cards by 4 points a step. Try your mom: eat with her ("Eat with her. The beat can wait.") and promise to call more, and she brings your aunt ("FAMILY · SHE BROUGHT YOUR AUNT"). Brush her off twice and "FAMILY · CALL ME" arrives, after which she stays away until a "SHE CAME BACK" card. These take many visits, so ask me to set scores in Studio.
9. **Phone and tablet beat maker.** In Studio's device emulator pick a phone, press Play, and press F at the PC. Nothing sits under Roblox's top bar, the REQUESTS chip no longer covers KEYS, the three save slots now sit above SAVE, and CLEAR and SWING share a row.
10. **Behind the scenes** (you won't see these): a stray JOIN can't open a cypher lobby, and a cancelled lobby blocks a new one for 60 s. Beat sends to the monitors and UNLOCK taps are rate-limited. The beat maker never says "Saved" when progress isn't saving. A shutdown releases every save at once.

## How sure I am

- **Studio suite (final run, 11-12 05:03–05:23, after the last fixes):** 232 of 233 pass, counting the 11 rule checks, every Edit check and every Play file. The one failure is t10 (below).
- **The one known miss** (the same in the run before the last fixes, 231 of 232): t10, which checks the beat maker's meter is visible. It needs a game view at least 580 px tall, and Studio's is 491 px since it reopened. That's the window, not the game. I'll rerun it once the view is tall enough.
- **Outside Studio:** all 11 rule checks pass: money and pacing, the cold-streak rules, the cards' data, the visitor shapes, the phone layout, the room counts and the card footer text.
- **Red first, then green:** for each task I showed its new checks failing on the old code first (outside Studio for the rule checks, in Studio on the unsynced place for the rest), each for the predicted reason, then passing once the code was synced. Three exceptions:
  - The visitor-shape check (t89) could only fail with "module missing" in Studio. I saw its real failures in a stand-in run outside Studio.
  - The final round's stale-warning step guards behaviour that already worked, so it passes on old code.
  - One final-round check, t78c (a 2-star delivery doesn't end the cold spell), also failed before the sync, with a message nobody had predicted. It was knock-on damage: t78a stops partway on the old code and leaves the player in the wrong state. It passes after the sync, in the full run.
- **Reruns:**
  - t64n (you stand up 2.5 s after a bad card) failed once in a suite and passed 14 of 14 when its chain ran alone. It looks like chair-physics timing, and that task didn't touch it. I didn't prove it.
  - t46, the big money simulation, dropped its connection twice. It now pauses between simulated careers and passes in 7 s. No assertion changed.
  - On 11-06 a stray mouse click muted the monitors and failed 13 sound checks. The baseline rerun on 11-11 was clean (204 of 204).
- **On screen:** I have captures of the whole cast lined up and in side view (`captures/visitor_look_b_2026-11-12/`). The noses and the rep's quiff slope the right way. I haven't seen the card portraits on screen. The checks only measure that the head fills 51-64% of the portrait (18-23 px at the smallest size). The phone layouts were measured at test sizes from 640×360 to 1024×768, never on a real phone.
- **Reviews:** every task had its own review, and a fix round plus a scoped re-review wherever it found something. A last whole-branch review (one senior reviewer, 57 commits) said "needs fixes": 0 critical, 2 important, 11 minor. It found no way for a player to be left with nothing arriving. Both important problems are things the money simulation can't see, and both are fixed:
  - FIRE-earning players who skipped requests went cold every third day.
  - A FIRE on a beat you only aired could push your best delivered beat out of your recent three, so being liked lowered your odds.
- **The fixes were re-reviewed** (`final-rereview.md` in the build folder): all addressed, nothing new.
- **Nothing added to the world:** 0 new sounds and 0 new lights. The only new parts are the visitors' bodies, built by code each visit (16 parts at most, 3 walking at once). No uploads.
- **Saves:** schema is still v5, and every new field fills in lazily. A real save and load of the full v5 profile passed on 11-05 on a separate test store. Wave 3's newer fields (recent beats, the cold spell, relationships, last delivery day) and the 5c-2 save fixes have only met fake stores. One more real round trip before any publish.

**Money and pacing** (200 recorded seeds, after the last fixes; the numbers matched the run before them exactly):

| Check | Result | Limit |
|---|---|---|
| Cards' share of a typical player's money | 35.1% | ≥ 34.1% (your floor) |
| Most for a player who always takes the best pay | 49.0% | ≤ 50% |
| THE HALL opens (typical day, worst 10%) | day 4, 6 | days 4–6, by day 7 |
| Legend, earliest (any player) | day 17 | day 15 or later |
| Phone Aura a day (typical / always the one-hit wonder) | 12.14 / 13.89 | ≤ 15 |
| Players who go cold in 60 days (typical, best-pay, chaser, big spender) | 0 | none in week 1 |

- **Honest headroom:** the best-pay player is 1 point under 50%, and the typical player is 1 point over the floor. These are the tightest margins in the game. On the 20-seed set, THE HALL's worst 10% is day 7, exactly at the limit.
- **What the money checks can't see:** their players always deliver, so they roll the ten beat cards at +1.6 on average. A real player who skips delivering rolls them at -9. That's the point of the feature, but I haven't measured what it costs them.
- **The cold streak on purpose:** a player who never delivers after day 1 is cold on days 4 and 5 on every seed (195 of 200 by the quiet rule on day 4, 5 earlier by low Aura) and thaws on their day-6 delivery.

## Needs you

1. **Approve the words.** Everything new is in `research/wave3/copy_2026-11-05.md` §11 and `research/fiction_pass_2026-11-06.md` ("Live now"):
   - the ten `{beat}` lines, and the card's beat line (copy §1, §11)
   - the 18 arc cards' words, plus the numbers I picked beyond the design (§2, §8.2)
   - the cold-streak message (`cold_news`), the two story lines, the `YOU'RE BACK` banner and the word COLD on the chip (§3 to §5)
   - the eight explainers (§6)
   - the six starter cards: words, numbers, and the +5 AURA chip on seven results that are otherwise neutral
   - the five new people behind them: A RAPPER WITH NO BEAT, YOUR BIG COUSIN, THE NEIGHBOR NEXT DOOR, THE OPEN-MIC HOST, THE STUDIO OWNER
   - the random first visitor in place of the superfan, and whether the cousin's "FAMILY · YOUR FIRST FAN" clashes with the superfan's BUZZING visit
   - the sponsor rep's warning text, trimmed to two lines (§11.2)
   - the beat maker's "Kept for this session only · progress isn't saving right now", and three old lines that now show in new places (§11.3)
   - from the final review (§11.4): `rival_beat` now says "my beats hit harder than yours. everybody at the cypher knows it", the bar footers read "Needs a 3★ best beat. Yours: ★★☆.", and the HIT explainer skips words used in another sense, including the headlines VISUALS HIT and SERIES HIT
   - four build calls (§11.1): the blogger's memory on her two old cards, a write on a choice sits on every outcome of it, the odds tilt on phone messages from a person, the rep's warning chime
   - the design-changing rulings (§8.1): the rival's diss track decided by your best beat, the sponsor rep's warning getting two choices, a plaque hit ending mom's silence, "HE MADE IT ANYWAY" only if the kid never blew up with you, "call her back" at +2, and the exposé split. Also mom's silence clearing on her return (§8.3)
2. **Approve the look.** Four of the 28 designs (your mom, the kid from back home, the blogger, the rep) come from the lineup you picked from. The other 24 are mine. See `captures/visitor_look_b_2026-11-12/` and the three `task-5d-preview-*.png` sheets in the build folder. My judgment calls are in `task-5d-report.md`: LIL NAV X keeps the cowboy hat, the fan cheers with both arms up, the neighbor wears a sleep mask, and the rep is 6.58 studs, 0.02 under the other adults (a taller quiff fixes it). Phone-only senders have no face.
3. **Say yes or no on these calls (each switchable):**
   - **+5 Aura on every starter result,** so a new player can't go cold on day 1. The alternative is wins only, which needs another pacing run.
   - **The sound-alike names stay** (your 11-11 "keep real names for now", which reverses 11-05's fiction-at-launch). The made-up set is parked as a patch with four swaps a web check forced: HEX VELOUR, SOLEPOP SNEAKERS, PEONY ROLLER, DUSK CASTELLO.
   - **Being heard keeps you warm:** a FIRE or a cypher win resets the 3-day quiet clock. The design said only deliveries do.
   - **The rival's diss track has no dice,** as in step 6.
   - **The phone beat maker moved the save slots** and touch screens under 700 px tall get the phone layout. SAMPLE IT hides on them while the beat maker is open. Aku's beat-maker design may replace this screen anyway.
4. **Decisions:**
   - **The "never cold in week 1" check: decided, not built yet.** On fresh runs it fails about 8 in 8,000 by bad luck. Under your "rest whatever u think" (11-12), the rooms design's D13 chose a rule: low Aura can't make you cold in your first 7 played days (the quiet rule still applies). It gets built in the people-and-progression plan's Task 2. Until then, a card change can trip the check now and then.
   - **The "your beat leaked" phone message** no longer jumps the queue when you first air a beat. Keep that, or cap it at once a day so it follows an airing. I'd keep it.
5. **Known limits, not fixed:**
   - A player who only plays cyphers and goes cold stays cold until a 3-star delivery, because FIRE can't land on cypher entries.
   - The quiet rule counts a 10-second login as a played day. That's the design's rule.
   - The kid you broke can still blow up on a later hometown pick. It's story only. The people plan's hometown pool takes it.
   - Profiles from before Wave 3 start with no recent beats. Only test accounts are affected.
   - Any star can still walk in from visit 2 on day 1. The rooms plans gate them.
   - After a code sync, Studio's edit mode can keep reading an old copy of a module, so a check can pass or fail on stale code. I swap in fresh copies by hand before edit checks. The test runner should do it, and doesn't yet.
6. **Still open, and what's next:**
   - **Save the place** (File > Save to Roblox) after this session's last sync.
   - **Rerun t10** once Studio's game view is at least 580 px tall.
   - **A two-player test on a published build:** you publish it, and I test it with two players.
   - **Day One (5e)** runs in the bedroom after the rooms build's core. **5f** is Aku's beat-maker design, due Tue 11-17.
   - **Still yours from before:** rename the experience to Prod Life III and check the name is free, listen to the Wave 1b sounds, the 1a, two-sessions and Wave 2 approvals, a real phone test, the maturity questionnaire, MaxPlayers 12 or fewer, and the icon and thumbnails.

## Rulings I made for you

Every call is in the build ledger (`.superpowers/sdd/2026-11-05-wave3-stakes/progress.md`), each with why and what it costs if wrong. Besides the ones above:

- **Your beat is what you delivered or aired, not what you saved.** Delivering never saves, so saved slots don't track real play.
- **A plain 3-star beat is neutral, and FIRE is the bonus.** That's your "stars as the base". Centring on 3.5 would make a solo 3-star beat negative.
- **A FIRE on a beat you only aired can't push out your best delivered beat.** Otherwise being liked lowered your odds.
- **The blogger's exposé is two cards, split at 300 Aura,** using gates that already existed.
- **Seven cards come once only** (mom's aunt, the kid's show, the tour, late-night TV, "replaced", sponsor renewal once per deal, the exposé). Each sets its own flag so it can't repeat every rotation.
- **Mom's "call her back" is +2, not +1.** From the -3 floor, +1 left her at -2 and shut her out again at once.
- **A person's score tilts their phone messages too.** A message from mom is mom's card.
- **Explainers count only when you saw the card,** skip words used in another sense, and sit after the choices on a phone card. So none is wasted, and none pushes a choice off screen.
- **Touch screens under 700 px tall get the phone layout,** since no desktop-size window plus the request card fits under about 684 px.
- **Walk-ins hold only while a cypher listens or votes.** In the lobby, build and reveal, only that round's players are held. One idle lobby could hold everyone's visitors on the server.
- **Room counts ignore rooms.** The imported bedroom doesn't count toward the hub's 61 lights, 12 interactables and 2 stations, and each room may hold 1 light, as you approved.
- **Day One waits for the room, and the beat-maker pass is Aku's.** Day One's first minute happens in the bedroom, and Aku joined on 11-11 and owns the beat maker's design.

## Where things are

- **Code** (under `src/ReplicatedStorage/OK/`): rules in `Modules/WalkInRules.lua`, `CareerRules.lua`, `CareerSim.lua`, `Format.lua`; server in `Systems/WalkIns.lua`, `Phone.lua`, `Career.lua`, `Contracts.lua`, `Reactions.lua`, `Life.lua`, `BeatBattles.lua`, `DAW.lua`; cards in `Data/WalkIns.lua`; numbers in `Config.lua`; screens in `Modules/WalkInUI.lua`, `PhoneUI.lua`, `CardFeel.lua`, `HUD.lua`; looks in `Modules/VisitorLooks.lua`, `VisitorFigure.lua`, `Visitor.lua`; beat maker layout in `Modules/DAWLayout.lua`, `DAWUI.lua`; room counts in `Modules/RoomScope.lua`. Saves are in `src/ServerScriptService/OK/Services/DataService.lua`.
- **Tests:** `spec/` (11 rule checks) and `build/t75` to `t92`.
- **Design, plan, copy:** `specs/2026-11-05-wave3-stakes-design.md`, `plans/2026-11-05-wave3-stakes.md`, `research/wave3/`, `research/fiction_pass_2026-11-06.md`, `research/launch_audit_2026-11-05.md`.
- **Reviews and ledger:** `.superpowers/sdd/2026-11-05-wave3-stakes/` (`progress.md`, `final-review-findings.md`, `final-fix1.md`, `final-fix1-report.md`, one report per task).
- **Next builds:** `plans/2026-11-12-your-rooms.md`, `plans/2026-11-12-people-and-progression.md`.
- **Snapshot:** `v41_wave3` in the place (`ServerStorage.OK_Versions`, 731 parts). Offline copy: `places/export_2026-11-12_0523/`. Last code commit `236b134`; this report's commit is "W3-T6: integration and report".
- **Tracker:** `../OK_GAME_TRACKER.md`.
