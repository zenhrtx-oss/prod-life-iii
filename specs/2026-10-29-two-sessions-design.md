# Two sessions, same day: design

October 29, 2026. Source: your voice memo "voice memo 11" (transcript and notes in `~/Downloads/voice_memo_11_*.md`), your four answers the same day, and a code map of XP, cards, follow-ups and the economy (`research/two_sessions/codemap_2026-10-29.json`). Nothing here is built. It ships in the content wave after Wave 1b, and building waits for your yes on this document.

## Intent

A text offers you two sessions on the same day, and you can only take one:

- **A kid from back home.** Small and raw, but he's from your hometown. You learn more working with him, and he remembers who helped him early.
- **A one-hit wonder.** He had one big single years ago and nobody rates him now, but he still has a little shine.

The lesson you put in the memo is what makes this a real choice: working where you belong teaches you more, and walking into a session above your level gains you nothing and makes you look stupid. So the celebrity pick is a trap early and a fair deal later, and the hometown pick always teaches you something and pays off down the line.

## Goals, non-goals, anti-goals

- **Goals:**
  - one phone card with two choices that read as a real dilemma
  - cards can grant XP (a first for the game)
  - a readiness check built from several stats decides how the celebrity session goes
  - the kid comes back bigger later
  - the money and pacing guardrails still hold
- **Non-goals:** a general "level gate" system for every card, a days-played counter, a new save format, new rooms or sounds.
- **Anti-goals (a failure even if it works):**
  - XP from cards that lets someone skip making beats; levels stay earned in the beat maker
  - a celebrity pick that's always right or always wrong
  - copy that reads as mean about poor neighbourhoods; the game is for ages 13 and up, so "the projects" and the memo's swearing become "back home" and plain words

## What the player sees

1. **The text.** A phone DM from a new sender, **SESSION BOOKINGS**, arrives like any other pop:
   > two sessions came in for today. the kid from back home wants you on his first tape. a one-hit wonder wants a comeback beat. you can only do one.

   Choices:
   1. **Work with the kid from back home.**
   2. **Work with the one-hit wonder.**

   DISMISS works as usual: you took neither, and nothing changes.
2. **Kid from back home** (always the same result, no roll):
   - headline **YOU WENT HOME**; "he's raw, but he listens. you learned more tonight than a month of tutorials."
   - **+40 XP** and +100 Followers; the note says he'll remember this
   - he is booked to walk into your studio later (step 4)
3. **One-hit wonder** (one hidden roll; readiness sets the odds, see below):
   - **It went off:** headline **THE SESSION WENT OFF**; "he brought his old fans with him. people noticed you." **+40 Aura, +10 XP.**
   - **You weren't ready:** headline **YOU WEREN'T READY**; "he played his one hit four times and left. people saw." **−30 Aura, no XP.**
4. **The comeback.** About 10–16 walk-ins later, the kid walks into the studio himself:
   > tape's out. the first beat is yours. remember back home?

   - **Good** (most of the time): headline **HE BLEW UP**; **+$400, +1 PLACEMENT, +800 Followers, +10 Aura.**
   - **Smaller:** headline **LOCAL HIT**; +$150, +300 Followers.

   This is the same pattern as the existing "Artists remember who helped them early" threads (`payback_*`).

## The readiness blend

You said "not at that level" should be a blend of several things. Proposal: four stats, equal weight, each capped where an engaged player gets comfortable.

```
readiness = average of:
  min(LV / 7, 1)
  min(Placements / 5, 1)
  min(Followers / 30,000, 1)
  min(max(Aura, 0) / 600, 1)

chance the celebrity session goes off = 10% + 80% × readiness   (so 10% to 90%)
```

What that gives, using the pacing sim's engaged player (medians) and a slower player, Claude's guess:

| | LV | Placements | Followers | Aura | Readiness | Goes off |
|---|---|---|---|---|---|---|
| Engaged, day 1 | 2 | 0 | 3.3K | 63 | 0.13 | 20% |
| Engaged, day 5 | 6 | 3 | 25K | 400 | 0.74 | 69% |
| Engaged, day 15 | 9 | 10 | 80K | 1.3K | 1.00 | 90% |
| Slower player, day 5 | 4 | 1 | 8K | 150 | 0.32 | 36% |

Why these four: LV is your beat-making level, which is the most literal reading of "not at that level". Placements are your track record. Followers and Aura are how big you are right now. Aura and Followers alone stop meaning anything after day 4 or so (the existing hidden odds max out at 300 Aura and 10K Followers), so the blend uses its own, higher scales. Hits and sponsors are left out because most players have 0 or 1 of each for weeks.

The roll uses the game's existing single hidden roll with a different chance and never adds a second draw. Adding the card still changes which cards get picked on each sim seed, so the pacing numbers move a little with any new card, whatever it pays.

## How often

- **At most twice a week** (a new cap group).
- **Never on your first day.** It needs 10 walk-ins ever, so it first shows up around day 2. Any XP on day 1 would unlock level 3 (and its requests) on day 1.
- **The phone must be on.** With `Config.Phone.Enabled = false` the card never shows.
- A second "kid from back home" pick while his comeback is still on its way gives the XP but doesn't book a second comeback. That pick's note says so, and never promises a visit that won't come.

## XP from cards

This is the first time cards grant XP, and the code map shows it has to be plumbed end to end or it silently pays nothing:

- **One way in:** a new XP source `Phone` in `Config.XP.Sources`, paid through `DataService.AddXP`, the same gate every other XP source uses. It has `max = 60` and a small `dailyMax`. Never `GrantXP`, which skips the gate. Phone items still never pay money.
- **Validation:** the data spec rejects any unknown outcome key, so content can't promise XP that the code doesn't pay. An `xp` band of 0–60 applies on phone items.
- **On screen:** the result card shows a **+40 XP** chip with the amount actually paid. The HUD's existing **+N XP** float shows too. A level-up from a card shows the LEVEL UP banner as usual; checking that it isn't hidden behind the open phone card is a test item.
- **The sim:** CareerSim learns card XP and levels up straight away, so the pacing checks see it.

## Money and pacing guardrails

These are the targets you set or approved. The plan must show each one still holds, on the spec's 20 seeds and on 200 more:

- **The money ceiling:** cards never pay more than half a player's money, for every modelled player (random, greedy, chaser, spend-down).
- **The money floor (your call, October 29): no worse than today.**
  - The check moves to a fixed, recorded set of 200 sim seeds.
  - On that set the card may lower the typical player's share by at most half a point from today's 34.6%.
  - The ceiling check (50% for every modelled player) stays as it is.
  - Background:
    - On the spec's 20 seeds, adding any card, even one that does nothing, moves the share from 35.4% to about 34.4%: the card changes which cards get picked.
    - On a recorded set of 200 seeds, today's game already sits at 34.6%. The 1a report's "35.0% on 200 other seeds" used seeds nobody recorded, so it can't be reproduced.
- **Legend never before day 15:** checked for the random player as today, and also for a player who always takes the kid (the XP chaser). Card XP moves Legend about a day earlier at most at these amounts. Two picks a week at 40 XP adds about 160 XP in two weeks, against about 420 of room. The "Legend never before day 18" line in the reports may become 17.
- **THE HALL around day 4–6:** also checked for a player who always takes the celebrity. Early losses of 30 Aura hold back THE HALL's 300-Aura door a little.
- **The phone's Aura budget:** about +15 a day net, as today.

## Names and copy

- **New names:** the sender **SESSION BOOKINGS** (fiction roster: **BOOKING DESK**), the walk-in visitor **A KID FROM BACK HOME** (fiction: **A KID FROM YOUR OLD BLOCK**), a different kid each time, and **A ONE-HIT WONDER** (fiction: **A FORMER CHART ACT**), who only appears in the text, never as a figure.
- **Checks:** each new name is web-checked like the 1a names, and none is a real person or song.
- **The kid's kind:** he is a "local" visitor, like the kid from the block, so the artist cooldown doesn't apply to him.
- **Style:** the game's usual rules: CAPS headlines, lowercase lines, odds kept hidden.

## Decided by you (October 29)

1. Notoriety is Aura.
2. The kid pays XP now, and comes back bigger later.
3. "Not at that level" is a blend of several stats.
4. It ships in the next content wave after Wave 1b.
5. The money floor is no worse than today, on a recorded 200-seed set.
6. A new kid each time.
7. The design is right enough to plan from. Building still waits for your go on the plan.

## Claude's calls (each switchable)

- the readiness blend and its scales (above)
- the amounts: +40 XP for the kid; +40 Aura and +10 XP, or −30 Aura and no XP, for the celebrity; the comeback's +$400, placement and followers
- the celebrity's backfire is immediate (the same text), not a later surprise
- at most twice a week, never on day 1
- DISMISS is allowed: taking neither costs nothing
- XP past level 10 does nothing (the level curve is fixed); the comeback still pays late-game players
- the new names and the "back home" wording

## Answered after the builder check (October 29)

1. **The money floor:** no worse than today, on a recorded 200-seed set (above).
2. **The comeback:** a new kid each time. Every hometown pick is a different kid from back home, and each can come back once. A pick made while an earlier kid's comeback is still on its way gives the XP but books no second comeback. Its note doesn't promise one.

## Left to the builder

The exact card and follow-up ids, the sender's colour, the visitor's look (from the existing sig list), test file numbers, the XP source's `dailyMax`, and where the readiness rule lives. It goes in `WalkInRules` as a pure function that both the server and the sim call.
