# Prod Life III · live demo run sheet (2026-11-10)

A tour you give through the real build in Roblox Studio, about 10 minutes. Nothing here is a separate version of the game. Written against the place as of 11-10 (Wave 3 through Task 5 in; Day One and the beat-maker pass not built yet, so the opening is still the tour).

## Before you start (2 minutes)

1. Studio open on `ok studio beta`, in Edit. Tell a Claude session "demo prep" if you want the prep step (below); otherwise skip it.
2. Press **Play** (the big Play button, not Run). Wait for the room to load (~10 s).
3. Check the speaker icon top-left of the game screen reads **🔊**. If it reads 🔇, click it once. (Muted = no card sounds, no beat on the monitors.)
4. Make sure the window is wide; the beat maker's compact layout kicks in on narrow windows.
5. Every Play is a fresh career in Studio (saves go to a fake store here), so the demo starts from zero each time. That's fine; it's the new-player experience.

## The tour (what to do, what to say)

| # | Do | Say | Watch for |
|---|---|---|---|
| 1 | Look around the control room. Point at the tracker at the top: "Open the studio PC or a studio laptop". | "You start as a producer with a room and nothing else. The game tells you the first five things to do, then gets out of the way." | The HUD: level, XP bar, money, the OS button, the 🔊. |
| 2 | **Within about 30 s a visitor walks in** (the first timer is 15–20 s, then he walks over from the corridor; rehearsed 11-10: card pending by 30 s). Read the card out loud. Pick a choice. | "This is the BitLife half. People walk in with offers, you choose, and the choice moves your money, your reputation (Aura) and your followers. Every card has a cost or a risk." | The result card, the stat floats, the footer line reading your Aura. The grey "i" line is a one-line explainer the first time a word like Aura appears. |
| 3 | Walk to the **Studio PC** (the big screen). Press **F** on the prompt "Make a beat". | "This is the other half: you actually make the music." | The beat maker opens with the starter request from JUNO VALE on the right. |
| 4 | Take the request. Tap pads on the grid until every ask ticks green (kick, snare, hat…). Press **KEYS** for the piano roll, drop a few notes. Press **DELIVER**. | "Requests are briefs: hit the asks and you get paid and rated. Stars matter later: a 3-star beat makes the artists trust you." | Money and XP floats, the stars. |
| 5 | Press **ON MONITORS**. | "Now the whole room hears it. If another player fires it, that's FIRE: your beat getting a reaction." | The beat through the speakers; the FIRE button near the monitors. |
| 6 | Open the **OS** button (top-left HUD). Click through **Career → STORY → Discography → Firsts**. | "The career remembers everything: a career clock, fame tiers from LOCAL to ICON, every first, your records, titles." | Your first story line is already there. |
| 7 | Tap the **phone** icon when it pulses (first text 1.5–2.5 min after the tour ends; if it hasn't yet, say "and your phone fills up with DMs and news as you go" and move on). | "DMs and news. Same choices, same consequences, from your pocket." | A DM card. |
| 8 | Walk to the lounge: the **gear rack** ("Open gear rack"), the **cypher board** ("Join cypher"), the credits wall, the TV. | "Gear unlocks sounds. The cypher is the multiplayer hook: a beat battle when friends are on." | Don't start a cypher solo (it needs 2). |
| 9 | Walk to **THE HALL** door ("Enter · The Hall"). | "Top of the career: two legendary rooms rebuilt from real studios. This one is Abbey Road's Studio Two. It needs a placement, 300 Aura and $5,000, which a normal player reaches around day 4." | Locked on a fresh profile unless you ran the prep. |
| 10 | (Prep only) Walk in, then south to **THE WEST SUITE** (Interscope LA, open to all). | "Both rooms are the destination. Soon they'll sit beside your own room, which grows with your career." | The scale of the rooms. |

## The optional prep (makes the tour land harder)

Ask a session for "demo prep" **after** you press Play and spawn. It runs server-side, during Play, and does three things to your demo character only: gives $6,000, 300 Aura and one placement (so THE HALL door opens at step 9), and sets followers to 1,000 after your first delivery (so the YOU'RE BUZZING banner fires and the superfan comes by). Script: `tools/demo_prep.lua` (Studio only; a live server has no hooks).

## Honest lines (say these if asked; don't claim more)

- **Saves:** real saves work (proven on Roblox's live store on 11-05). In this Studio demo they go to a practice store, so each Play starts fresh.
- **Published?** Not yet. No outside player has touched it. That's the biggest open risk.
- **Phones:** every screen is built for phone widths and checked in tests; it has not yet been played on a real phone.
- **Multiplayer:** built (shared room, FIRE, cyphers), tested only in Studio, never with strangers.
- **Not in yet:** the Day One opening (choices from second 1), fiction names, the new visitor look, the six recurring characters' fixes, the beat-maker upgrade (two-bar patterns, better sounds, per-track volume), your own room. All on the launch list.
- **The beat maker** is a one-bar sequencer plus a piano roll, not a DAW. Say so before a producer says it for you.

## If something stalls

- No visitor by 30 s: walk a few steps (the timer counts presence in the hub) or ask a session to spawn one.
- The card hides behind the beat maker: close the beat maker; the card chip is at the top.
- The door won't open: the prep didn't run, or you haven't delivered once (the placement).
- Sound gone: the 🔊 button.
