# Progression and your space: design (2026-11-12)

**Status:** decided. On 11-12 at 02:10 the user answered the decisions in §7 and said "rest whatever you think" for the others. §7 records each answer and the call taken. The 11-12 calls override any draft text below that differs from them. Next: the build plan. This is plan Task 5g ("your own room"), widened into progression because the user asked to think about rooms, careers and relationships together.

**The user's one-line intent for rooms:** "Its to upgrade and custimize and the story should add to that."

**Inputs:**
- the user's calls (tracker, "Already decided")
- the ideas log (`../../IDEAS.md`, about 110 ideas with sources)
- the Aku call (11-11)
- ChatGPT's master plan and code audit (11-11)
- a design review of the cast and career model (11-12)
- the current code, checked on 11-12 (§9)

## 1. Why

The user wants real progression, "not just some shit where like you hop on and then play for a day":
- You start producing in **your bedroom at home** and your space grows.
- Choices have consequences. "You could be a fire beat maker and not make that much progression."
- People remember you.
- Careers branch.
- Big names only find you later.

Today the game has a shared hub and three ladders running side by side, none of them in charge:
- **XP levels** with ranks (INTERN → STUDIO LEGEND)
- **fame tiers** by followers (LOCAL → ICON)
- **six career stats**

Your rooms (5g) are on the launch list (11-10), and Day One (5e) waits for them.

**Principles (from the user):**
- The room is the visible measure of your career: "your environment physically represents how far you've come".
- Every room has working things to do: "I don't want a beautiful room where nothing happens".
- Making beats is the main thing you do. Life decisions run around it.

## 2. Goals, non-goals, anti-goals

**Goals for launch:**
- You wake up in your own bedroom, every time you join.
- Your space grows a room per unlock, the bedroom stays, and you place your own things.
- Visitors and phone cards come to you in your room.
- A room unlock feels earned: money plus a career milestone.
- Your walls show your career.
- Friends can visit.
- It runs smoothly on phones.

**Non-goals for launch** (direction in §6):
- the connected commission
- career lanes with lane-only stories
- numbered rare items
- trading
- the store (the monetization is decided, but the store comes after launch)
- events and venues

**Anti-goals:**
- **A beautiful room where nothing happens.**
- **A new player stalled** because they can't afford the next room: smaller jobs and relationships must keep moving while you save. From the 11-12 design review.
- **The money guardrail moving.** Re-tune on purpose with a pacing run (§8). The guardrail:
  - the random player's card share ≥ 0.3412 on the 200 recorded seeds
  - every policy ≤ 0.50
  - THE HALL's median day 4–6, with p10 ≥ 3 and p90 ≤ 7
  - Legend never before day 15
  - phone Aura ≤ 15
- **Phones dropping frames** or loading rooms they can't see.
- **A career that changes when you buy something.** Who you are comes from what you did, not from your wallet (11-12 review).

## 3. The loop a player lives in

| Step | What happens | Where it lives |
|---|---|---|
| 1. Wake up in your room | Your bedroom, then the rooms you've added; your walls show your career | §4.1, 4.6, 4.7 |
| 2. Someone reaches out | Walk-ins at your door, phone DMs, requests. Every player meets different people: different encounters within an authored cast. Big names later. | §4.2, 4.10 |
| 3. Pick the terms | The friend's session or the one-hit wonder's placement; every choice costs something | built ("two sessions, same day"); §6 for deal terms |
| 4. Make the beat | The beat maker: Aku's design (5f, due 11-17) | outside this design |
| 5. The result | Money, Aura, followers, placements; your beat moves the odds (Wave 3) | built |
| 6. People remember | Six recurring people today; meters you can see | §4.12, 7 (D1) |
| 7. You grow | Rooms, gear, fits, a title that isn't "INTERN" | §4.5, 4.11 |
| 8. New people find you | Bigger names, friends visiting your studio, cyphers | §4.8, 4.10 |

## 4. Part 1: what launch needs

The **Size** row is a rough build effort for each section: S = about a day of agent work with tests, M = a few days, L = a week or more. Every code fact was checked on 11-12 (§9).

### 4.0 What the shared hub is for, once you wake up in your own room (D10, the biggest open decision)

| | |
|---|---|
| **Today** | Everything social and "studio" lives in the hub:<br>- the monitors: one server-wide queue, played on the hub's speakers (`DAWClient.client.lua:595`)<br>- FIRE: listeners within 45 studs of the hub speakers (`Systems/Reactions.lua:29,34`)<br>- SAMPLE IT, within the same range (`DAWClient.client.lua:107`)<br>- cypher voting (`Systems/BeatBattles.lua:235`)<br>- the artist listen-back in the hub's vocal booth (`Modules/BoothArtist.lua`)<br>- the gear rack (`build/15_gear_rack.lua`)<br><br>A beat put ON MONITORS from the bedroom laptop plays on the hub's speakers, where nobody in your bedroom hears it. |
| **Why it matters** | FIRE is one of only two ways out of the cold streak, and the pacing sim assumes about 4 FIRE a day. Day One's decided "play it for the room?" and "spend it?" both happen at the hub's speakers and gear rack today. |
| **Options** | **A. The hub is the public stage.** Your rooms are where you make beats, decorate and get visitors; airing, FIRE, cyphers, the booth and the gear rack stay in the hub. Your laptop's ON MONITORS says it plays in the studio. Small, but your room does less.<br>**B. Every room is a full studio.** Each room runs its own monitors, FIRE from visitors in your room, and its own listen-back. L-sized: it touches the monitor queue, the FIRE range, flips, the cypher reservation, the tour and the `aired` card gate.<br>**C. A mix.** Your rooms get local speakers: you and your visitors hear your beat, with no FIRE and no queue. The home studio adds a small booth for artist sessions. The hub stays the public stage for airing, FIRE, cyphers and the gear rack, and the rack also opens from your laptop so Day One's "spend it?" works in the bedroom. M–L. |
| **Claude's recommendation** | **C.** Your space grows in what it can do: a bedroom for beats, then a home studio with a booth. The hub stays where the server meets: cyphers, FIRE, showing off. Day One's "play it for the room?" becomes "play it on your speakers"; airing it in the studio comes next. |

### 4.1 Your plot and your door

| | |
|---|---|
| **DECIDED** (11-04, 11-11) | Per-server plots. A door per player in the shared building leads to that player's rooms, built off to the side so a phone only loads what it's near (streaming). Others in your server walk in through your door; friends elsewhere use Roblox's Join. |
| **Claude's call** | Plots sit in a fixed grid of slots far from the hub, one per player slot (the server size from Config). A slot is claimed on join and released on leave. |
| **Size** | M. A slot allocator, room spawning from your save, door wiring. |

### 4.2 Visitors find you in your room

| | |
|---|---|
| **Today** | Walk-ins count down only while you're inside the hub's rooms, a fixed box (`WalkInRules.InHub`, x 12..94 and z −12..12; `Systems/WalkIns.lua:157`). Visitors walk a hub route. |
| **Change** | The countdown runs while you're in the hub **or in your own rooms**. A visitor walks to your door, then to a visitor spot in the room you're in. Each room carries named anchors (`Entrance`, `VisitorSpot`) so content doesn't hard-code coordinates. |
| **Size** | M. It touches WalkIns' spawn, walk and arrive steps and the hold rules. |

### 4.3 Your station

| | |
|---|---|
| **Today** | `DAW.AtStation` returns false unless the hub's `ControlRoom` exists, then accepts any `OK_Interactable` with `Kind = "Station"` within reach (`Systems/DAW.lua:81-92`). The imported bedroom's laptop is a Station. |
| **Claude's call** | Only the room's owner can open the beat maker at their own room's station. Visitors can listen to the monitors. |
| **Size** | S. |

### 4.4 Saving your rooms

| | |
|---|---|
| **Rule** | Schema v5, no bump. Rooms and placed items are a nested field of a table the career system already defaults lazily (for example `prof.career.home = { rooms = { "bedroom", … }, items = { [roomId] = { {id, x, z, rot}, … } } }`). |
| **Rule** | Every item is validated against the catalog and the room's bounds on load, and on every move, server-side. |
| **Size** | M. Includes save-size limits and migration tests with existing profiles. |

### 4.5 Unlocking a room

| | |
|---|---|
| **DECIDED** (11-11) | A room unlocks with money plus a career milestone. The order is **bedroom → home studio → a real studio**, said twice on the 11-11 call. The home studio's launch benefit is what the user asked for: "more space, more customization, more room to add things", meaning a bigger floor and a higher item limit. Hosting people and bigger jobs (§6) are direction, not part of the launch room. |
| **Claude's call** | Reuse `Config.Career.Gates`, the same rule THE HALL uses today (`needs` + `cost`, `Systems/Career.lua:318`). The home studio's milestone and price come from the pacing run (§8). A first guess to test: 1 placement + 1,000 followers, around day 2–4. |
| **Open** | Only THE HALL and THE WEST SUITE's role at the top (§7, D8). The first three rooms are settled. |
| **Size** | S for the gate; M for building the home studio asset (the Abbey Road method, like the bedroom). |

### 4.6 Placing your things

| | |
|---|---|
| **DECIDED** (11-04, 11-11) | Furniture you place from day one. Each room has an item limit. The bedroom stays editable. |
| **Claude's call for launch** | A small catalog: decor plus the gear you already own showing up physically. Grid placement with move, rotate and remove, one item at a time, phone-first (44 px controls). The limit per room fits its part budget. |
| **Content** | Items come from what you already earn: the gear rack, career milestones, people's gifts. Paid decor waits for the store. |
| **Claude's call: built by code at launch** | Launch catalog items are built from parts by code, the way the visitors' look is. That means no uploads and no Import 3D waits. Imported hero pieces come later through the Abbey Road pipeline, with the user's import. Placed items get their own budget per room, separate from the room shell: the bedroom shell already uses 55 of its 56 MeshParts. |
| **Size** | L. The placement UI, validation, replication to visitors and the catalog. It's the biggest launch item. |

### 4.7 Your walls show your career

| | |
|---|---|
| **DECIDED** (11-04) | "Your career on the walls." |
| **Claude's call** | Plaques for your placements and hits, drawn from the discography the game already saves (`LifeRules`), plus Weekly Single plaques. They hang automatically in fixed wall slots, outside the item limit. |
| **Size** | M. |

### 4.8 Visits and your door

| | |
|---|---|
| **DECIDED** (11-04/11) | Friends in the server walk in; friends elsewhere join. |
| **Claude's suggestion, not yet asked** | Door modes: open, friends only, locked. Default: friends only. |
| **Claude's guess** | Visits only while the owner is online, for launch. |
| **Size** | S–M. |

### 4.9 Day One starts in your bedroom

| | |
|---|---|
| **DECIDED** (11-06) | Day One opens with choices from the first second: JUNO VALE needs a beat by tonight, $50, then "play it for the room?", then "spend it?". After that comes the random starter visitor (built 11-11). |
| **Change** | All of it happens in your bedroom: the first card, the laptop, the first visitor at your door. Design and build stay Task 5e, after this design is approved. |
| **Open** | D3 (choice card vs. beats first). |

### 4.10 Big names later

| | |
|---|---|
| **DECIDED** (11-11) | "big names shoudlnt come until later in the game". |
| **Today** | Nothing gates the nine star artists. Any of them can walk in from visit 2 on day 1. |
| **Claude's call** | Gate **new star access** on a career stage. The stage is the high-water fame tier: a tier counts once reached, ever, the way `LifeRules` already treats tiers. Today's followers count doesn't decide it. The recommended stage (D11) is: you've unlocked the home studio **and** reached FAMOUS. The pacing run tunes it. |
| **Already promised callbacks** | A queued star follow-up skips the ordinary gates today: `WalkInRules` returns a due follow-up before ordinary cards. Examples are `navx_single` and `navx_album`. Claude's call: **a star chain you've already entered finishes, whatever your stage.** The gate decides only whether you can *enter* a star chain, through a new star card. Inside a chain, every choice stays open. That includes `navx_single`'s new album-deal choice, which pays an advance and promises `navx_album`, and a promised follow-up is always planted. Nothing promised is deleted, and old profiles keep their queue. This exemption covers only the new stage gate: a chain card's other checks still apply (affordability, outcome rules). |
| **Acceptance** | Four cases:<br>- a clean new profile never meets a star before the stage<br>- a qualified profile does<br>- a low-stage profile with a pending `navx_single` still gets it<br>- that profile takes the album deal, reconnects, and still gets `navx_album` |
| **How late, and who** | Open (D11). An old 10-30 sim had the random player reaching KNOWN on day 2, FAMOUS on day 4.5 and ICON on day 19. KNOWN would open in week 1, so it's barely "later". 46 entries in `Data/WalkIns.lua` belong to the nine stars, including 4 phone DMs and LIL NAV X's Wave 3 arc. LIL NAV X is one of the six recurring people, so his arc would start later too. |
| **Content need** | Stars bring the biggest early paydays. Early days need enough local cards (locals, rising artists, the starter cast) for the card share to stay ≥ 0.3412. The pacing run decides how many new local cards that takes. |
| **Size** | S for the gate; M for the local cards. |

### 4.11 Titles that don't start at INTERN

| | |
|---|---|
| **IDEA** (11-12) | "u shouildnt start off as an intern". |
| **Today** | `Config.Ranks` sits over the 10 XP levels: INTERN, RUNNER, ASSISTANT, ENGINEER, BEATMAKER, PRODUCER, HITMAKER, HEAD PRODUCER, EXEC PRODUCER, STUDIO LEGEND. The levels run unlocks, the gear rack's tiers and several tests. |
| **Claude's call** | Keep the levels and rename the titles to a producer's climb. Draft: BEDROOM PRODUCER, BEATMAKER, LOCAL PRODUCER, PRODUCER, RISING PRODUCER, IN DEMAND, HITMAKER, HEAD PRODUCER, EXEC PRODUCER, STUDIO LEGEND. The "Rank up" unlock lines change to match. |
| **Size** | S (copy). The draft goes on the approval list. |

### 4.12 Relationship meters (launch-sized)

| | |
|---|---|
| **IDEA** (11-12) | "relationship meters". |
| **Today** | Six recurring subjects have hidden scores, clamped to −3..3 (`Modules/WalkInRules.lua` RelWrite), plus flags. Anything the card data doesn't declare is dropped on load (WalkIns' `state()` repair). |
| **Who they are** | Not all six are people you have a bond with. **The rival, your mom, LIL NAV X and the tea blogger are people.** The hometown kid is a person under D1 option A (see D1). **The sponsor's rep is deal standing:** `rel.rep` resets on every new signing (`Systems/WalkIns.lua:462`), so it shows with your sponsor deal, not as a friend who forgot you. Senders of alerts and news aren't contacts. |
| **"Met" has to be saved** | Nothing records it today. `walkins.seen` is seeded before you meet anyone, and `rel` is written only by some outcomes. A phone DM you open may write neither. Claude's call: a small, bounded `met` fact, written when you actually encounter someone: the visitor arrives at your door, or you open their DM. It lives nested in the walk-ins table (schema v5). **Old saves:** a person counts as met if their `rel` entry or one of their flags exists. |
| **Claude's call (launch version, informational)** | A CONTACTS view on the phone listing the people above once you've met them. It shows:<br>- each person's 7-step bond (the −3..3 score)<br>- one memory line written for a flag the game already saves ("you chose my session"), or an honest "you've just met" line when no flag exists yet<br>- **only real next steps:** an offer that is actually waiting from them, or "nothing right now"<br><br>No "Call" or "Send a beat" button: reaching out is direction (§6), not launch. No raw flag names. Not every stranger becomes a contact. |
| **Acceptance (if D6 puts it in launch)** | - a new contact appears after the first real encounter<br>- the seeded rotation never makes anyone "met"<br>- a DM that writes no `rel` still makes its sender met, across save and reload<br>- the bond stays inside its 7 steps<br>- every memory line traces to a saved flag<br>- an offer that's waiting shows; "nothing right now" shows otherwise<br>- it survives save and reload<br>- signing a new sponsor doesn't change a person's bond<br>- under D1-A, the hometown friend's line comes from the existing `homekid` facts, and no other person inherits them |
| **Open** | Which hometown person is meant depends on D1. |
| **Size** | M. |

### 4.13 Phones and budget

| | |
|---|---|
| **DECIDED** (11-12) | The bedroom: 55 MeshParts, 19,566 triangles, 1 light. Each room is allowed 1 light; the hub keeps ≤ 61. The checks are already scoped (Task 5c-3, `Modules/RoomScope`). |
| **Rule** | Streaming on, so a phone loads only nearby plots. The 12-plot phone test (`build/room_test.lua`) comes back with the real bedroom before launch. |
| **Size** | M. |

## 5. Launch boundary (proposed)

| In launch (proposed) | Why |
|---|---|
| 4.0 | The hub's role, whatever D10 picks; it changes what every room needs |
| 4.1–4.9, 4.13 | The room itself and Day One |
| 4.10, the big-names gate and local cards | The user said "regardless" |
| 4.11, titles | It's copy, and the user named it |
| 4.12, contacts and meters | **DECIDED in launch** (D6), with the hometown pool (D1) |
| Monitor upgrades, the closet, posters | **DECIDED in launch** (D10, D12) |
| The cold-streak grace rule | Claude's call (D13), S |

**After launch:** everything in §6.

With D6, D10 and D12 the launch list grows. The build plan stages it, and Wave 3's last task (Task 6) runs first. Anything from §6 stays after launch unless the user moves it.

## 6. Part 2: direction after launch (short)

- **Careers from what you did.** Who you are comes from your history, not your wallet or room. Reputations overlap, and switching is allowed. Lanes to explore: underground, hitmaker, ghost, artist-producer, label owner, comeback. (ChatGPT plan §3; 11-12 review.) What the game saves today is thinner than it looks:
  - **Durable now:**
    - firsts and completed regular briefs
    - the relationship flags the cards write (whose session you chose, the show you skipped…)
    - placements, hits and sponsors as counts
    - cypher entries
  - **Saved but incomplete:**
    - The story and discography logs survive reconnects but are capped at 100 and 200 entries, and the story leaves out repeat and daily work on purpose.
    - Credits add one entry for each passed delivery, capped at 50.
  - **Not a record of choices at all:** `walkins.seen` is rotation bookkeeping.
  - **Missing:** deal terms, ownership and no-credit records.

  So the first two or three directions should read from the durable facts. Ghost, ownership, label and comeback careers need new saved history and new gameplay before they can be claimed. Lifetime achievements stay separate from current standing.
- **The connected commission.** A person you know offers a job; you pick terms, make and submit a specific beat, and get specific feedback. Later someone names that beat. The smallest proof is one person across the whole loop. It needs:
  - a saved project list (today Contracts keeps one active request, and picking another replaces it, `Systems/Contracts.lua:166`)
  - an agreed "submitted beat" with Aku (5f)
  - relationship memory that can hold new kinds of facts
- **One list of people.** Story visitors (`Data/WalkIns`) and request artists (`Data/Artists`) are separate lists today. Link them by stable id first; merge later.
- **Offers that follow your history.** Today's picker narrows to the least-seen cards before weights apply. Reserve a relevant-opportunity slot.
- **Rooms that add actions.** The home studio hosts someone; a pro room takes bigger projects. Prestige rooms: THE HALL, THE WEST SUITE, more Abbey Road-quality rebuilds.
- **The store** under the decided model: kits, sound banks, themes, skins, passes. Never odds, pay-to-win or a paywalled essential music feature.
- **Rare finds and collectibles,** events and venues, recap cards.

## 7. Decisions (the user, 2026-11-12 02:10)

**The user's answers.** Each is quoted, with the design that follows from it.

1. **D10, the hub: the mix (C), with monitors you earn and upgrade.**
   - The user: "ITs to upgrade and custimize and the story should add to that, like u should be able to earn your way to even unlcok montiers, and u can get better and louder moniters but yea ur mix is good."
   - **Monitors are an upgrade track, not a given.**
     - The bedroom starts with the laptop's own speakers: you hear your beat, quietly.
     - You earn your first monitors, then better and louder ones.
     - Louder means more people in your room hear your beat; better means it sounds better.
     - Story outcomes can hand you upgrades, such as a gift, a deal or a find.
   - The hub stays where the server meets: airing, FIRE, cyphers. The gear rack also opens from your laptop.
2. **D1, who persists: Claude's call.** The user: "Whatever u think but I want every player experince to feel diffrent and have diffrent charecters with so many diffrent outcomes that effect diffrent thigns in good and bad ways."
   - **Claude's call: an authored pool per role, every person you meet persists.**
   - The hometown role draws from a small pool of authored kids. Each pick can be a different kid, which keeps the spirit of 10-29. Every kid you meet is a lasting person with their own meter, memory and contact entry, which meets the meters ask.
   - The arc follows the kid you actually worked with.
   - The rival, your mom, the tea blogger and LIL NAV X stay single characters at launch. More pools come with the decided "content as seasons".
   - **Different players, different characters:** which pool members you meet, the random starter visitor, which rising artists find you, and the outcomes you pick. All of it stays inside an authored cast, not generated people.
   - **Old saves:** the existing `homekid` history becomes the first pool kid's history.
   - Every memory line still traces to one saved person and the event that wrote it.
   - Size: M–L. The homekid arc cards bind to "the kid you met in this role" instead of one fixed visitor id.
3. **D11, big names: agreed.** The user: "agree". Stars, LIL NAV X's arc included, need the home studio unlocked **and** FAMOUS reached. Star chains already entered still finish (§4.10).
4. **D12, the home studio: cooler, and where customizing opens up.** The user: "sure but just a lot cooler shit and thats when we make furniture and clothign closetsa and posters and stuff like that".
   - At launch the home studio is bigger and holds more.
   - It has local speakers and a small booth (the relocated listen-back).
   - **It opens new item types:**
     - more furniture
     - **a clothing closet** to keep and change your fits
     - **posters** for your walls
   - Claude's call: posters at launch are designed in the game, as a SurfaceGui with text and color, so they need no image uploads. Image posters wait for the user's upload approval, as the textured bedroom did.
5. **D6, contacts: in launch, with relationship meters.** The user: "We want them with laucnh want relationsip meter." §4.12 is in launch as specified, informational: bonds, memory lines and real offers only.
6. **D7, placing things: yes.** The user: "yea". The small grid catalog at launch (§4.6).

**"Rest whatever you think": Claude's calls.**

7. **D2, kits:** rare and unique kits come from people and discovery, and packs are bought. This is consistent with the 11-12 monetization decision.
8. **D3, Day One:** the first card is JUNO VALE's $50 beat request. You choose, then you're straight in the beat maker.
9. **D5, titles:** the §4.11 draft list. It goes on the approval list as copy.
10. **D8, THE HALL and THE WEST SUITE:** shared prestige spaces you unlock access to. Your own ladder is bedroom → home studio → real studio.
11. **D9, door default:** friends only.
12. **D13, the week-1 cold check: a grace rule.** Nobody goes cold from low Aura in their first 7 played days.
    - The "quiet" reason (3 played days without a delivery) still applies, so the `neglect` persona still goes cold on day 4.
    - This makes the design's anti-goal ("a regular player going cold in their first career week") true by rule, not by luck. The per-seed pacing check stops tripping on harmless card reshuffles.
    - Size: S. Touches `CareerRules.ColdStep`, the sim and the cold tests.

(D4 was dropped: the bedroom → home studio → real studio order is the user's own call from the 11-11 call.)

## 8. Pacing and acceptance

The design is accepted only if a pacing run (CareerSim on the recorded seeds, extended for room unlocks) shows all of these:
- the money guardrail holds (§2)
- THE HALL's timing holds
- Legend ≥ day 15
- the home studio unlocks in a target window. Claude's guess for the target: median day 2–4, p90 ≤ 6.
- no week-1 cold rise, by whichever check D13 picks
- with the big-names gate on, the card share stays ≥ 0.3412
- **a solo bedroom producer with zero FIRE** (no cypher assumed) still makes progress: a 3-star delivery can end a cold streak, beat work is always available, and the money earned and the room unlock days come out reasonable next to a matched baseline. The sim's assumed 4 FIRE a day isn't guaranteed under D10-A or C. This case is separate from the `neglect` persona.
- **an early-game income check** (Claude's call): the card share for days 1–7 is reported and held near today's. The 0.3412 floor only counts days 8 and later (`Modules/CareerSim.lua:30`), so on its own it can't see a gate that bites in week 1.

New local cards are tuned until it does.

Phone acceptance:
- the 12-plot test on a phone holds frame rate and memory with real bedrooms
- every new control is ≥ 44 px at 667×375, 771×390 and 844×390

## 9. Code facts this design rests on (checked 2026-11-12)

- **Walk-ins only count down in the hub:** `Modules/WalkInRules.lua` `InHub` (fixed box) and `Systems/WalkIns.lua:157`.
- **Stations:** `Systems/DAW.lua:81-92` (`AtStation` needs `OKStudio.ControlRoom`, then accepts any tagged Station in reach).
- **One active request:** `Systems/Contracts.lua:166` (`state(prof).active = id`).
- **Relationship repair** keeps only declared visitors and flags: `Systems/WalkIns.lua` `state()`.
- **Scores clamp −3..3:** `Modules/WalkInRules.lua` RelWrite.
- **One currency:** `prof.cred`, shown to players as Money since schema v3 (`ServerScriptService/OK/Services/DataService.lua:123`).
- **Room gates:** `Config.Career.Gates` and `Systems/Career.lua:318`.
- **Ranks over levels:** `Config.Ranks`. **Fame tiers by followers:** `Config.Life.Tiers`.
- **Two lists of people:** `Data/WalkIns.lua` and `Data/Artists.lua`.
- **Room-scoped counts:** `Modules/RoomScope.lua` (a room is a Model with a non-nil `OK_Room` attribute).

## 10. Left to the builder

These details don't change what gets built. The plan settles them:
- **Plot slot geometry** and door placement in the building.
- **Anchor naming** inside room assets.
- **Contacts:** the 7-step bond labels and the exact memory lines. The copy goes on the approval list.
- **The grid** size and snap rules.
- **Placement UI layout**, within the 44 px rule.
