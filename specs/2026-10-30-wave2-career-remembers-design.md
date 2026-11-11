# Wave 2 "the career remembers": design

October 30, 2026. Your scope, chosen October 30: **core memory** (a career clock, a story log, fame tiers, your discography) plus **firsts and flex** (a firsts checklist, an auto nameplate title, ribbons, milestone bars). The room reacting (TV headlines, greetings) and "things happen to you" (off-stage news, scouts, paparazzi) wait for a later wave. Background: `research/bitlife_ideas_2026-10-24.md` (the wave 2 list), the vision page, and the code map `research/wave2/codemap_2026-10-30.md`. Nothing here is built; building waits for your yes on this document.

## Intent

Today the game forgets. You can land a placement for a big artist, sign a sponsor, open THE HALL, and nothing remembers when or how. BitLife works because your life reads like a story: "Age 23: you met…". Wave 2 makes the career read like a life: how long you've been at it, what happened, who you worked with, how famous you are, and what you've done first.

## Goals, non-goals, anti-goals

- **Goals:** a visible career age; a readable story of your career; fame tiers that feel like moments and open new doors; a discography you'd want to show; firsts and small flex that reward exploring.
- **Non-goals:** the room reacting, off-stage news, relationships (Wave 3), anything players type, Roblox badges (they need uploaded icons), retirement.
- **Anti-goals:**
  - memory that pays: none of this may move money or odds past your limits (firsts and ribbons are cosmetic unless you say otherwise)
  - a story log that reads like a database dump; every entry is a short sentence in the game's voice
  - a clock that punishes you for not playing: missed days don't age you

## What the player sees

1. **The clock.** Each real day you play adds one career day, and every 7 career days is a career year. Your nameplate gains your year and keeps your FIRE count: `YEAR 2 · LV 6 · PRODUCER · 🔥 12`. The first time you join on a new career day, a small toast says `DAY 12`.
2. **The story.** A new **STORY** tab in the panel (a sixth tab; the tab bar is re-laid out to fit phones) lists your career newest first, one line each, with the career day:
   - `DAY 3 · You landed your first placement, with {artist}.`
   - `DAY 5 · THE HALL opened for you.`
   - `DAY 9 · You hit BUZZING.`
   It keeps the last 100 lines. Lines come only from the server's own templates; no player text.
3. **Fame tiers.** By Followers: **LOCAL** 0, **BUZZING** 1,000, **KNOWN** 5,000, **FAMOUS** 20,000, **ICON** 100,000 (the lines the Wave 1 design already used). The first time you reach a tier:
   - a banner moment (`YOU'RE BUZZING`), using the LEVEL UP banner's spot, queued so it never replaces a level-up
   - a story line
   - your tier on your profile card
   - **new people:** reaching BUZZING, KNOWN, FAMOUS or ICON books one special visitor who walks in once, ever (for example the talk-show booker at KNOWN, a label scout at FAMOUS). It's a one-time follow-up visit, so it doesn't water down the deck. Because Followers can fall, the game remembers the highest tier you've reached, and neither the banner nor the visit ever repeats.
4. **Your discography.** The **CREDITS** page (it already lists your session deliveries) gains every walk-in placement and hit: the artist, what it was (PLACEMENT, HIT, TRACK ONE), and the career day. Newest first, up to 200 entries.
5. **Firsts.** At the top of the STORY tab, a **FIRSTS** checklist with about 12 entries, each ticked with the career day it happened: first beat saved, first delivery, first 3-star delivery, first placement, first hit, first sponsor, THE HALL, first cypher win, LEVEL 5, BUZZING, KNOWN, a 7-day streak.
6. **Auto title.** Your profile card (the one other players can open) shows a title from your career, picked by a fixed rule from your firsts and tier (for example `BUZZING`, or `HIT MAKER` once you have a hit). It never repeats a rank word (HITMAKER and STUDIO LEGEND are ranks already), so the hit title is worded differently, such as `CHART MAKER`.
7. **Ribbons.** Small cosmetic ribbons on your profile card for career feats: a 7-day streak, 10 placements, a hit, a sponsor, ICON. In-game only, not Roblox badges.
8. **Milestone bars.** On the Career page, three bars: Followers to the next tier, XP to the next level, and THE HALL's three needs.

## How it's saved

- **One save-format change (v5)**, at the start of the wave, adding one new top-level table, `prof.life`: the career day and the last UTC day counted, the story ring, the discography, the firsts (career day per id), the highest tier reached, and the ribbons. Every list is a plain array; every key is a string; nothing uses number keys, so a real DataStore stores it exactly as tested.
- **The name `life`** keeps it clear of the reward gate's existing `careerLog`.
- **Size:** about 100 story lines and 200 discography entries at about 80 bytes each stay under 30 KB, far inside a DataStore entry's 4 MB.
- **Old profiles:** the game has never been published, so the only existing profiles are Studio test ones. A v4 profile becomes v5 with: career day 1 starting now; your current tier recorded as reached without a banner; firsts you obviously have (a placement, a hit, a sponsor, THE HALL) ticked as "before the clock" with no day; an empty story and discography.
- **The rolling-publish rule stays:** an old server never overwrites a newer save.

## How it's built (Claude's calls)

- **One server module, `Systems/Life`**, owns the clock, the story, the discography, the firsts, the tier and the ribbons. Other systems call it at the moment something happens: `Life.Event(player, kind, fields)`.
  - Placements and the tier: walk-in apply.
  - Hits: a follow-up's arrival.
  - Sponsors, THE HALL and Legend: their existing unlock points.
  - Deliveries: Contracts. Cypher wins: BeatBattles. Level-ups: DataService's XP path (it gains one server-side hook; today a level-up only notifies the client).
  - The streak: Dailies.
- **The clock** ticks at join and at UTC midnight for players online, through `ctx.Data._day()` so tests can move it.
- **Pure rules** (tier from Followers, title from firsts, year from day, story text from templates) live in a pure module with CLI specs, like the other rules.
- **The client** reads the story and discography through the existing career data call, not by sending the whole profile more often.
- **No new lights, parts or sounds;** the tier banner reuses the LEVEL UP banner and its existing sound (if any).

## Money and pacing

- The clock, story, discography, title, ribbons and bars pay nothing.
- **Firsts pay nothing** (your call).
- **The four tier visits** are one-time follow-ups; their payouts still go through the same pacing checks as the two-sessions card: the 200-seed money floor (no worse than 34.12%), the 50% ceiling, THE HALL, Legend and the phone Aura budget. The money floor has about 1.7 points of headroom, so tier cards should pay at least as much as an average card, or the plan sizes them to fit.
- The sim learns Followers per day so the report can say when players reach each tier.

## Decided by you (October 30)

1. Scope: core memory plus firsts and flex.
2. The clock: one career day per real day you play; 7 days make a career year.
3. Tiers: a banner moment plus new people at each tier.

4. Firsts are cosmetic only: a tick, a story line, sometimes a ribbon. No XP or money.
5. The nameplate shows `YEAR 2 · LV 6 · PRODUCER`.
6. The story lives on a STORY page in the panel.
7. The auto title shows on your profile card only; the nameplate is `YEAR · LV · RANK · FIRE`.
8. Each tier brings one special visit, once ever (not repeating cards).
9. STORY is a sixth tab, with the tab bar re-laid out for phones.

## Left to the builder

Exact story templates and the full firsts list (within the voice rules: CAPS headlines, lowercase lines, no OK/CRED/STUDIO TWO, display names only through `{name:id}`), the ribbon art (made from UI shapes, no uploads), the tier visitors' exact copy and which existing visitor each tier reuses (on your approval list), the auto-title words (on your approval list), test numbers (t70 onward).
