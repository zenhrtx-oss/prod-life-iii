# Wave 1 "Life Happens": the phone, cards that fit your life, and a career that feels alive

> Design written 2026-10-26 for **Prod Life III** (the game was OK Studio until that morning; see README "Milestone 9").
> Sources:
> - the user's answers in the walk-ins session on 2026-10-24
> - the Wave 1 mockup: https://claude.ai/artifact/HAd2jULCrqeQTy52NQoTnc (nine boards at 844×390)
> - the idea catalog: `research/bitlife_ideas_2026-10-24.md` ("Suggested order", Wave 1)
> - the game vision: `specs/2026-10-26-game-vision.html`
>
> It builds on Milestone 8 "Walk-ins" (`specs/2026-10-23-walk-ins-design.md`, whose rules all still hold) and on the live code in `src/`. Nothing here publishes, saves the place or uploads anything.
>
> Marks: **(user)** = decided by the user. **(call)** = my call; the user can override. **(builder)** = left to whoever builds it. **(catalog)** = from the 122-idea catalog, whose verifier read the code for it.

## 1. Intent

Walk-ins gave the game BitLife's core: someone walks in, you choose, hidden odds decide, your career moves. Three things still make it feel less like BitLife.

1. **Life only happens when someone walks in.** Nothing reaches you between visits.
2. **Every producer gets the same pitches.** A rookie with 180 followers and a famous producer with 21K see the same cards.
3. **Results land flat.** No sound, no float on the stat that moved, no reaction from your avatar or the room.

Wave 1 fixes all three:
- a **phone** that pops by itself between visits
- cards **gated by your life**, so the deck fits your career
- a batch of new people and stories that ride on that gate
- a **feel layer** that makes every result land: floats, sounds, your avatar's reaction, visits in lumps

Making beats stays the spine. Nothing in Wave 1 pays more for tapping cards than for making beats.

## 2. Goals, non-goals, anti-goals

**Goals**
- **The phone (user).** About 6 phone moments a day on top of the 8 walk-ins. A DM, a scam, news, an offer: each pops up by itself as a phone-shaped card.
  - In the beat maker, the phone icon shakes with a red count instead, and the card opens when you close the beat maker.
- **Cards that fit your life (user scope, catalog `life-gated-cards`).** A card can require or exclude a range of followers, aura, money, placements, hits, sponsors or lifetime visits, so a rookie and a famous producer live different lives.
- **New people and decks (user scope, catalog).**
  - Your mom.
  - The talk-show booker.
  - A youth music programme's coordinator.
  - The weird deck: a pigeon in the lounge, a nine-year-old who says he's next, a man selling aura in a jar.
  - Studio mishaps, your beat leaking, your page getting hacked, scam DMs, the trending blogger.
- **Threads (user scope, catalog).** The rival's rumour, day-one payback, the ghost-producing gig, the sponsor's interview question.
- **Visits that behave like people (user scope "small fixes", catalog).**
  - A gentle first visitor who can't cost you money.
  - "He left a note" when you ignore someone.
  - Waiting lines in his bubble while you're in the beat maker.
- **Feel (user scope, catalog).**
  - Every stat move floats and its pill pops.
  - Sounds on the card and the result.
  - Your avatar cheers or sits down for the room.
  - A footer that reads your aura.
  - Visits that come in lumps.
  - Negative aura that heals a little each day.
- **Choice tracking (catalog `choice-telemetry`).** Every choice and outcome is logged, so later waves are tuned from what people actually pick.

**Non-goals (Wave 1)**
- **No save-format bump.** The schema v5 bump (day counter, story log, per-artist history, firsts) stays at the start of Wave 2, as the catalog planned. Wave 1 adds only fields that default when missing (§5).
- **Not in Wave 1 without the user's yes (§10):** sponsor ad gigs, fits that change the odds, the room features (toasts, TV charts, net worth, streak freeze) and artists arriving with a crew. They weren't in the scope the user approved on 2026-10-24. The walk-ins session, which ran that conversation, flagged this on 2026-10-26.
- **Left for later waves:**
  - relationships, bonds, contacts and DMs that remember you
  - HEAT
  - fame tiers as named titles
  - the story log and recap
  - retirement
  - personal studios
  - the CLOUT social app
  - posting as an action you start yourself

  Wave 1's phone only receives.
- **No typed text, no images, no uploads, no new lights, no Robux.**

**Anti-goals (a failure even if it works)**
- **Tapping cards out-earns making beats.** The walk-in share of a player's money stays at or under 50%. Phone pops and the new cards must not push it over. Today the greedy test player sits at 48.3%, so there is only **1.7 points of headroom** (§4.8).
- **Too much happens at once.** Two cards on screen, a pop over a walk-in, a pop during the tour or mid-cypher.
- **A line that breaks Roblox's rules or names a real person or company.** The account has a strike. Every new name is web-checked.
- **The phone nags.** It never opens over the beat maker, and an ignored pop goes away quietly.

## 3. Constraints

Everything in the walk-ins design §3 still holds:
- `src/` is the source of truth, synced with `tools/sync.py`, and `tools/test.py` stays strict.
- 44 px controls at 844×390 and 667×375, and gamepad support.
- No saving or publishing, no uploads, licensed audio only (APMOfficial 7462718749 / ProSoundEffects 7462895450), no free-model scripts.
- Systems use `{ Enabled, Version, Init(ctx) }` through SystemLoader.
- Rewards go through the gates in `DataService` and `Career`.
- Studio-only test hooks.
- The Studio lease with other sessions.

New or changed since then:
- **Name.** Player-facing text says Prod Life III or neutral words; `build/t50_check.lua` fails on OK or real-studio names. The legendary rooms are **THE HALL** and **THE WEST SUITE**, and the gate id stays `studio_two`.
- **Test numbers.** Wave 1 uses `t51`–`t59` for Studio tests (t50 is the rename check), plus new or extended CLI specs in `spec/`.
- **Lights.** Wave 1 adds **no lights**. The place sits at 61 against the cap of 36 (the user's open decision), so the 4 light-cap checks fail before and after Wave 1. Every other test must pass.
- **Sounds.** Every new sound is a licensed ID that the builder shortlists and `t14` verifies by creator. The user still has to listen, so each one is marked pending in the report.

## 4. The experience

### 4.1 The phone (1a)

**What you see.**
- A phone icon sits beside the Aura and Followers pills on the HUD, at least 44 px.
- When a pop comes in, a phone-shaped card slides up on the right side of the screen: taller and narrower than the walk-in card, as in mockup boards 1–2. The room stays visible on the left. **(call: the mockup's shape. The user was offered "match the walk-in card" and the recommended "as mocked"; this design takes the recommendation. One flag in `Config.Phone.Layout` switches to the walk-in card's frame.)**
- The card shows:
  - a header with the sender: an app-style label (MESSAGES / NEWS / STUDIO) and the sender's name in the visitor's colour
  - the message, in the sender's voice
  - 0–4 choices, at least 44 px tall
  - the same footer as walk-ins

**Two kinds of pop.**
- **DM (has choices).** Scams, offers, the trending blogger, page hacked, beat leaked, studio mishaps. Choosing works exactly like a walk-in card: same `Resolve`, same hidden odds, same result card. The result card sits under the phone card's position, not centred.
- **NEWS (no choice).** "YOUR BEAT'S IN A DANCE TREND · 40k people are doing the shoulder thing to it." The effects apply on arrival. The card shows the result chips with one OK button and closes by itself after 8 s.

**When it pops (user: "pops up by itself"; about 6 a day).**
- **Pace.**
  - `Config.Phone.DailyMax = 6` pops per UTC day.
  - The first pop arrives 90–150 s after the player joined or finished the tour, whichever is later. It doesn't wait for a walk-in, and if a walk-in is due within 60 s it waits for that card to close (§8.4).
  - After that, one every 120–180 s of eligible time. **(user: "roughly every 2–3 minutes"; the exact numbers are my call)**
- **Eligible time is the time you're in the game and none of these is true (call):**
  - the tour isn't done
  - a cypher round is running on the server, as for walk-ins
  - you're in the booth listen-back cutaway
  - a walk-in card, phone card, result card or note card is open for you
  - a walk-in visitor is walking to you
- **Location (call).** The phone works anywhere, including THE HALL and THE WEST SUITE, because nothing has to walk there; walk-ins stay hub-only as before.
- **One card at a time (call).** A player has one card slot. A walk-in who arrives while a phone card is open waits at the edge of the room with his "IS WAITING" chip, the same behaviour as for the beat maker. A pop never fires while a walk-in is on his way.
- **In the beat maker (mockup board 3).** The pop doesn't open. The phone icon shakes with a red count, and the card opens when the beat maker closes. At most **2 pops wait** (call). A pop that has waited 10 minutes expires quietly, with no stats change and no count against the day. **(call: an expired pop isn't "used", so the beat maker never costs you phone moments.)**
- A pop counts toward the 6 when it opens.

**Who sends what.** Pops are cards in the same deck as walk-ins, with `source = "phone"` (§5). The sender is a visitor id: an artist, a role visitor, or one of the new phone-only senders (§4.3). An artist's DM never replaces his walk-in. The artist cooldown applies across both sources, so the same artist doesn't DM you and then walk in a minute later. **(call)**

### 4.2 Cards that fit your life (1a)

- **Gates (catalog).** Any card or pop can carry `needs` and `under`, using the six career stats plus `visits` (lifetime walk-ins) and `money`.
  - Example: `needs = { followers = 10000 }`, `under = { money = 200 }`.
  - A card is in the pool only when every `needs` value is met and every `under` value is not reached.
  - `when = "sponsored" | "unsponsored"` stays as it is.
- **Rookie cards and famous cards (mockup board 4).**
  - Under 1K followers, a rookie can get "a kid from the block" cards.
  - At 5K, the talk-show booker.
  - At 10K, the trending blogger.
  - At 20K, cards that are only for the famous.

  The exact thresholds are for the builder, but they line up with the fame tiers the vision page names (LOCAL 0 · BUZZING 1K · KNOWN 5K · FAMOUS 20K · ICON 100K), so Wave 2's tier names fall on the same lines.
- **Weights.** Gated cards join the normal pick. **(call)**
- **No burst when a gate opens (call).** Pick prefers the least-seen card. Every card that unlocks when a player crosses 5K, 10K or 20K followers has been seen 0 times, so without a rule they would win the next draws back to back. When a gated card first becomes eligible for a player, its seen count is set to the lowest seen count already in that player's pool, so it joins the rotation evenly.

### 4.3 New people and stories (1a)

All names are role names or animals: no real people, no brands. Each one is web-checked before it goes in. The lines are lowercase and in the voice of the existing cards. The amounts are bands for the pacing sim, not final numbers.

| Id | Source | Who / what | Gate | Money | Thread |
|---|---|---|---|---|---|
| `gentle_first` | walk-in | the superfan, as your very first visitor ever ("omg it's you!! can i get a photo??") | `visits` = 0 (first walk-in only) | none; can't lose | none |
| `mom_*` (3 cards) | walk-in | **YOUR MOM** (user: "your mom", the recommended option) brings food, asks what a placement is, and turns up the day after your first HIT to see the plaque | none; at most twice a week | **never costs, never loses** (catalog) | the HIT visit plants on the HIT |
| `booker_*` (2) | walk-in | **THE TALK SHOW BOOKER**: a late-night interview where one answer can go wrong | followers ≥ 5K | none | "clip out of context" comes back as a phone NEWS 2–4 visits later |
| `giveback_*` (2) | walk-in | **THE COORDINATOR** from a fictional youth music programme (name web-checked by the builder) | money ≥ $500 | costs only: donate gear for Aura | a thank-you letter as phone NEWS |
| `weird_*` (4) | walk-in | the weird deck: **A PIGEON** (stands on the lounge coffee table, "coo."), **A KID WHO SAYS HE'S NEXT** (he's nine), **A MAN SELLING AURA** (in a jar, $20), **A STRANGER** (says your beat is huge somewhere far away) | none; at most one a day | tiny or none | none |
| `rumour` | follow-up | after losing to the rival, the blogger walks in for your side of his rumour | planted by a rival loss | none | none |
| `payback_*` | follow-up | an artist you helped for free comes back big ("album's out. track one is yours") | planted by a free or respect choice, long fuse: 15–25 visits | none; +1 Placement, Aura, Followers | none |
| `ghost_gig` | walk-in | the rival brings a secret job: drums for a bigger producer, your name off it | placements ≥ 1 | **pays ~$200 (pacing sim)** | sometimes the internet finds out later (Aura) |
| `sponsor_quiz` | walk-in | before signing you, the rep asks one question about his brand; get it wrong and he walks | (the existing sign card) | none | none |
| `scam_*` (3) | phone | fake playlist curators and label execs asking for money up front | none | **costs only** (the fee is the trap; reporting is the smart move) | none |
| `hacked` | phone | your page is posting fake giveaways and followers are draining. "Turn on two-step" is the good choice | followers ≥ 2K | costs only (recovery service) | none |
| `leaked` | phone | the beat you aired last is everywhere with someone else's tag: claim it, let it ride, or pay to pull it | you aired a beat this session | costs only | none |
| `trending` | phone | the blogger: "you're trending rn. one line from you. go" | followers ≥ 10K | none | none |
| `mishap_*` (3) | phone, from STUDIO | a monitor pops, the MIDI keyboard walks off, the AC dies: pay to fix, try it yourself, or borrow from the rival | none | costs only | borrowing plants "you owe the rival" |
| `news_*` (6+) | phone NEWS | offstage news: dance trend, sped-up version, a playlist add, a review, a comment storm | some gated by followers | **none** | none |

**The pigeon (call).** It doesn't walk the route. A small parts-built pigeon appears on the lounge coffee table when its card is due. The card opens wherever you are in the hub, with the pigeon named as the sender. It flies off (it's removed) after the result. If you're in the control room or the booth, the card says it's in the lounge.

### 4.4 Visits that behave like people (1a)

- **He left a note (catalog).** When a walk-in card expires unanswered (today: after 5 minutes, or 90 s on a busy server), a small note card shows instead of nothing, with no stats change. The visit already counts:
  - "HE LEFT · LIL NAV X waited 5 minutes. 'hit me when you're done cooking.'"
- **Waiting lines (catalog, mockup board 3).** While he waits for you to close the beat maker, his bubble says a new fixed line every 45 s ("yo you almost done? no rush. kinda rush"), and everyone in the room sees him waiting.

### 4.5 Feel (1b)

- **Stat deltas (catalog).** Every career stat move floats under its pill in the stat's colour, and the pill pops (1.0 → 1.08 → 1.0). That covers Aura, Followers, Placements, Hits and Sponsors, on top of today's +XP and +$ floats. Client only.
- **Footer that reads your aura (catalog).** The card footer keeps hiding the odds but reads your situation in three fixed lines by Aura band: under 0, 0–299, and 300 and up. For example: "your aura's in the red. people hesitate. you still never see the odds."
- **Aura heals (catalog).** Negative Aura moves 5 toward 0 on your first hub entry of a new UTC day, with the toast "the internet forgot. +5 AURA". Positive Aura never decays. It goes through `Career.Add` with its own source.
- **Outcome sounds (catalog `gap-1`).** A soft riser as a card opens, a ding on a win, a thud on a loss, a register ching when money lands, a blip when a follow-up is planted, a buzz when the phone pops. **Licensed IDs only, pending the user's listen.**
- **Your avatar reacts (catalog `gap-3`).** On a win your character cheers (R15 emote); on a loss it sits down where it stands for 2 s. R6 avatars only get the tag. Everyone sees it.
- **Rush hour (catalog `gap-4`).**
  - Walk-ins come in lumps: sometimes 2–3 back to back under a BUSY DAY chip on the HUD (mockup board 6), then a longer quiet gap.
  - The daily cap and the average pace stay the same.
  - "Back to back" means a near-zero gap after the previous card closes, since one card at a time still holds.

### 4.6 The room reacts

Moved out of Wave 1 until the user says yes (§10).

### 4.7 Choice tracking (1a, task 0)

Every resolved card logs one AnalyticsService custom event through `Systems/Funnel` with:
- the source (walk-in or phone)
- the card id
- the choice index
- the outcome key
- WALK AWAY, expiry and note events

Nothing is saved to the profile. It goes first in the build, so every later card is tracked from the start. **(catalog: "choice-telemetry first of all")**

AnalyticsService only reports from a published place, so the user sees nothing in Roblox's dashboard until the private publish. Before that, the events show only in Studio's Output.

### 4.8 Money

The share rule is authoritative, as in walk-ins §4.8.
- **Phone pops never pay Money (call).** They move Aura and Followers only. Money appears on a pop only as a cost the player chooses: a scam fee, a recovery service, a repair, a donation.
- **The only new income** is `ghost_gig` (about $200), a walk-in card, so it counts in the walk-in share.
- **The pacing sim has to be taught about phone pops and the new cards before any money line is written.** That means `spec/pacing_spec.lua` and `build/t46_check.lua`. It reports the same four numbers as today:
  - random-player median share
  - greedy max share
  - Studio Two (The Hall) median unlock day
  - the Legend nameplate's earliest day
- **If the greedy share passes 50%, the paying cards get trimmed, not the ceiling (call).** The bigger risk is the other way: non-paying cards dilute the deck (§8.1).
- **Mom's cards never cost and never lose (catalog).** Give-back cards turn money into Aura only.
- **Sinks don't change the share.** The share counts money in, so new costs make players poorer without moving it. The sim still reports the effect on The Hall's unlock day, which must stay in day 3–7.

### 4.9 Scope and order

Wave 1 has grown past walk-ins' size because the phone came in (the catalog had the phone in Wave 3). It ships in two parts. Each part is a milestone with its own suite run, snapshot and report. **(call)**
- **1a: phone and content.**
  - task 0 (telemetry and a content validator)
  - the life gate
  - the phone scheduler and card
  - the new people and threads
  - the visit behaviours
  - the pacing sim update
- **1b: feel.** Deltas, footer, aura heals, sounds, avatar, rush hour. The room features join 1b only if the user says yes (§10).

## 5. Data model and code shape (builder owns the details)

**Deck.**
- One deck. Cards in `Data/WalkIns.lua` gain optional fields:
  - `source = "walkin" | "phone"` (default `"walkin"`)
  - `app = "MESSAGES" | "NEWS" | "STUDIO"` (phone only)
  - `news = true` (no choices; the effects sit on the card)
  - `needs`, `under`
  - `weekly` / `daily` caps for mom and the weird deck
- New visitors join `W.Visitors`: mom, booker, coordinator, the four weird ones, plus `kind = "critter"` for the pigeon. A phone-only sender (the STUDIO app) has no figure. **(call: one deck, so Resolve, Fill, the roster switch, the data spec and the content validator cover phone and walk-ins with no second path)**
- `WalkInRules.Pick` takes `opts.source` and filters by `needs`/`under`/`source`.

**Systems.**
- **New `Systems/Phone.lua`:**
  - the scheduler (§4.1), running on the same per-player loop style as `Systems/WalkIns`
  - remotes `Phone_Card` and `Phone_Choose`. It may share `WalkIn_Choose`'s server path and `WalkIn_Result`. **(builder)**
  - it reads and writes the card slot that `Systems/WalkIns` already keeps, so the two never open cards at once
- **Rules modules:**
  - `Modules/WalkInRules`: the gate filter, the seen-count seeding for newly eligible cards (§4.2), the rush-hour gap and long-fuse plants (`plant.at` beyond `Config.WalkIns.FollowupAt`)
  - `Modules/CareerSim`: phone pops, the new cards, the gated existing cards

**UI.**
- **New `Modules/PhoneUI.lua`** (client): the phone card, the HUD phone icon with its red count and shake, and NEWS auto-close. Its test attributes mirror WalkInUI's (`Open`, `Card`, `Choices`, `Result`, `Command`).
- **WalkInUI:**
  - the note card
  - the aura footer lines
  - the result card's position when it came from the phone
- **HUD:**
  - the phone icon
  - deltas for every career stat
  - the BUSY DAY chip
- **Visitor:**
  - waiting lines
  - the pigeon (a spot figure, not a walker)

**Other systems.**
- **Systems/Funnel** handles the telemetry events.
- **Config:** `Config.Phone`, `Config.WalkIns.Rush`, `Config.Career.Sources.AuraHeal`, and new `Config.SFX` entries.

**Saves (no schema bump; every field defaults when missing).**
- `prof.walkins.phone = { day = yyyymmdd, today = n }`. Pending pops aren't saved: a pop waiting in the beat maker is lost on leave, and it was never counted. **(call)**
- Long-fuse plants use the existing saved follow-up queue.
- The first-visit card reads `prof.walkins.count == 0`.
- Aura heals reuses the walk-in day rollover.
- Everything else (rush hour, leaks "this session") lives in server memory.

## 6. Done when (the plan expands this)

**CLI specs (no Studio)**
- **Content validator.** Every card's odds sit within 10–90. Money amounts stay inside the bands in §4.3. Every `$N` in a choice's text matches its numbers. Every visitor and sender exists in both rosters. No line contains a word on the blocklist. Phone cards never pay money. Mom never costs. Every new name carries a web-check note. An unknown key in `needs` or `under` is an error, so a typo can't quietly make a card unreachable.
- **Gates.** `needs`/`under` include and exclude correctly at the edges, `source` filtering works, and a 180-follower and a 21K-follower profile draw from different pools. A card that just became eligible doesn't win several draws in a row.
- **Pacing.** The existing pacing targets still hold: random median share 35–50%, greedy max ≤ 50%, The Hall median day 4–6 (p10 ≥ 3, p90 ≤ 7), Legend not before week 3. The sim covers phone pops, the new cards and the gated existing cards (§8.1).
- **Rush hour and pace.** The daily cap and the average gap hold over 1,000 simulated days.

**Studio tests (t51–t59)**
- **Phone pace.** A pop opens on its own 90–150 s after joining or finishing the tour, whichever is later, even with no walk-in that session. It never opens during the tour, a cypher, the listen-back or another card. In the beat maker the icon shows the count and the card opens on close. The day caps at 6. A pop that waits 10 minutes expires without counting.
- **The card slot.** A walk-in arriving during a phone card waits. A pop never fires while a walk-in walks to you.
- **NEWS** applies its effects, shows chips and auto-closes.
- **Gentle first visitor.** A new profile's first walk-in is the superfan, and no choice can cost money.
- **Mom** never costs or loses.
- **The pigeon** appears on the coffee table and is removed after the result.
- **He left a note** after expiry, and the visit still counts once.
- **Waiting lines** change while the beat maker is open, and a second client sees them.
- **Feel:**
  - deltas float for all five career stats
  - the footer line matches the Aura band
  - aura heals once a day only when negative
  - avatar reaction on R15
  - the BUSY DAY chip during a burst
- **Telemetry** logs one event per resolved card, WALK AWAY and expiry, from both sources.
- **t14** finds every new sound under the two licensed creators.
- **t50** still passes (no OK or real-studio names in any new line).

Then the user's 10-minute solo play and a two-player play.

## 7. Left to the builder
- Every card's text, odds and weights, inside the bands, in the existing voice. The user approves the lines, as with walk-ins.
- The fictional youth programme's name and the four weird visitors' looks, after web checks.
- The pigeon's shape, and the phone card's exact size below 844 px.
- The sound shortlist.
- Task order inside 1a and 1b, and test numbering.

## 8. Builder check (2026-10-26)

A fresh agent read this document against `src/`, `spec/` and the walk-ins design as the engineer who would plan it. It asked four questions and measured the first one. All four are settled here: the project answers them, or they are my calls.

1. **Which pacing targets bind, and what gives way? (call; answered by the project)**
   - **The measurement.** The agent added 12 placeholder walk-in cards to a scratch copy of the sim: 9 that pay nothing and 3 costing $200–300.
     - Random-player share fell from 39.5% to **33.2%**.
     - The Hall's p90 day rose from 6 to **8**.
     - Greedy max fell to 43.8%.

     New non-paying cards dilute the paying ones, because Pick prefers the least-seen card.
   - **The binding targets stay the ones `spec/pacing_spec.lua` and `build/t46_check.lua` already enforce:** random median share 35–50%, The Hall median day 4–6 with p10 ≥ 3 and p90 ≤ 7, greedy max ≤ 50%, Legend not before week 3. §6's shorter list is replaced by these. **The targets are not relaxed.**
   - **The levers, in order:**
     1. Keep the non-paying walk-in cards rate-limited: mom twice a week, the weird deck once a day, gentle_first once ever, the booker and the rumour by their gates.
     2. Move non-paying stories to the phone where they fit. The phone has its own daily cap and doesn't take walk-in slots, so it doesn't dilute the walk-in deck.
     3. Only then give one or two of the new walk-in cards a small sure payout ($100–200), noted in the report as a change to "the only new income is ghost_gig".
   - **The sim models phone pops too.** They pay no money but do cost it (§4.8), so they can move The Hall's day.
2. **Does the life gate touch the 37 existing cards? (call)**
   - Yes, but narrowly. Existing cards get `needs`/`under` only where their text already implies a career stage: the manager's and label-sized offers become famous-only (followers ≥ 20K), and nothing that pays a Placement is gated, so The Hall's path is untouched.
   - **New for the gate:** 3 rookie cards (followers under 1K, "a kid from the block") and 3 famous-only cards (followers ≥ 20K). They're rate-limited like the other non-paying cards.
   - The gate spec's "different pools" test compares a 180-follower and a 21K-follower profile on exactly these.
3. **Does `sponsor_quiz` replace the sure "Sign it" choice? (call)**
   - No. It's an added variant of the rep's visit, and the existing six rep cards stay as they are.
   - In the quiz variant, the right answer signs you with the same bonus as "Sign it"; a wrong answer means he walks.
   - The question never depends on what the brand sells, because the fiction and parody sets sell different things. It's always about the deal, for example "what's the one thing you never do in a {sponsor} post?" with the answer "tag a competitor".
4. **What starts the phone if no walk-in comes this session? (call)**
   - The first pop comes 90–150 s after the player joined **or** finished the tour, whichever is later. It doesn't depend on a walk-in.
   - If a walk-in is due within 60 s, the pop waits until that card closes.
   - So a player who used up today's 8 walk-ins, or who went straight to THE HALL, still gets their phone moments.

## 9. Calls in this design the user may want to change
1. **The phone card's shape:** taller, as mocked (the recommended option), switchable by one flag.
2. **Who brings food:** your mom (the recommended option). Grandma can join later as more data.
3. **Phone pops never pay money,** only Aura and Followers, with money only as costs.
4. **The phone works everywhere,** including the legendary rooms. Walk-ins stay hub-only.
5. **At most 2 pops wait** while you're in the beat maker. They expire after 10 minutes without counting.
6. **The split into 1a (phone and content) and 1b (feel),** each its own milestone.
7. **No save-format bump** until Wave 2.
8. **No burst when a follower gate opens:** a newly eligible card joins the rotation evenly.
9. **The 8.1–8.4 answers to the builder check:** the pacing targets are kept, existing cards are gated narrowly, the sponsor quiz is added rather than replacing anything, and the phone starts without a walk-in.

## 10. Proposed but not in Wave 1 (each needs the user's yes)

These came from the catalog but weren't in the scope the user approved on 2026-10-24. Each one is a decision, not a builder's call.

| Idea | What it adds | Why it needs the user |
|---|---|---|
| **Sponsor ad gigs** (catalog `sponsor-gigs`) | Your sponsor's rep comes back with a job: do it straight for sure money, make it weird for a viral gamble, or pass. | Players' avatars holding parody-brand products in ads is a moderation question. The catalog's verifier rated it medium on moderation and medium on economy, and it adds money to the walk-in share. |
| **Fits that change the odds** (catalog `gap-9`) | An equipped fit adds 1–2 points to hidden odds on camera-facing cards. | It reverses the walk-ins design's "fits are cosmetic", and it moves the pacing numbers. |
| **The room reacts** (catalog `room-toasts`, `room-charts`, `net-worth`, `streak-freeze`) | Room-wide toasts and a HIT banner, this server's top three on the lounge TV, net worth on the Career tab, a one-time streak freeze. | It was left out of the approved Wave 1. All four are small and low risk, and they could join 1b with one yes. |
| **Pulled up with the crew** (catalog `entourage`) | Some artists walk in with two extra figures. | It was left out of the approved Wave 1, and it adds parts to the server's budget. |
