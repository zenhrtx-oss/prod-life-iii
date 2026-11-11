## 1. Pitch
You're the new producer in an underground studio. Within a minute you tap a starter beat, make it yours and hit ON MONITORS: the room hears it with "prod. you" on the screens. Someone taps SAMPLE IT, flips it, and the screen reads "prod. Maya · flip of you". A 10-16 year old makes something that sounds like the trap and rage they already play, on a phone, with no skill wall, and gets public credit when others react or build on it. Caveat: pure music makers stay niche on Roblox (no current tracker presence for Splash or BeatMerger), so this adds goals (daily cards) and an audience loop (fires, flips), not just knobs.

## 2. First session story
- **0:00** The tour starts at the studio PC (credits wall moves last).
- **0:40** Seated. Three starter presets (Dark 142, Bounce 160, Slow 75); tap one, it plays. 808, rolls and swing work at level 1.
- **2:00** Card 1: "Change 8 cells, add two 808 notes." SAVE pays +30 XP; an untouched preset no longer counts.
- **4:00** ON MONITORS, or join the queue if busy. Listeners tap FIRE.
- **6:00** Level 2 unlocks Pattern B and the chain: copy A to B, drop the kick, chain AABA.
- **9:00** Card 2: "Only 3 sounds, under 90 BPM." Swap the kick in the kit picker.
- **12:00** Someone's song airs. SAMPLE IT, change 8+ cells, air it as "flip of Maya"; Maya gets XP.
- **15:00** Level 3 adds the Perc row. Card 3 waits: "Streak 1 · new cards tomorrow".

## 3. Return hooks
- **Tomorrow:** three new cards (date-seeded, the same in every server), your streak, your songs, a kit one level away.
- **Next week (B):** the Weekly Flip: one seed song, booth voting, Sunday results on the lounge TV. Kit drops are config-driven weekly content.
- **Ladder:** L2 Pattern B + chain, L3 Perc, L4 Tape kit, L5 4th slot, L6 Metal kit, L7 8-bar chains, L8 Glass kit, L9 5th slot, L10 gold console neon.
- **XP pays for music:** cards 30 ×3/day, fires received 2 each (cap 20), flips of you 15 (cap 45); mic/console cap drops to 30.
- Nothing persists until the place is published with API access.

## 4. Milestone A
**A1. Format v3 + song mode** (first; the rest depends on it). Slot `{v=3, pats={A,B}, chain≤4 bars, bpm, swing, kit}`, six rows (new Perc). Airings play the chain up to twice, capped at 20 s (a bar is 4 s at 60 BPM).
Reuses DAW.Validate/Migrate, DAWConfig.Upgrade, DAWEngine.Start (pattern per bar from the server-time step), NowPlaying, DAWUI pager, PanelUI Sessions. New: DAW.MigrateV3, per-pattern Validate.
Done when: stored 64- and 80-char beats both upgrade losslessly; an AABA song plays locally and on monitors; two clients agree on bar and step within 1 step.

**A2. Instant start + ladder.** Presets, PC-first tour, genre at level 1, levels 2-10 filled.
Reuses Tour.Steps/Advance, CellsDiffer, Config.Unlocks, Validate gating. New: DAWConfig.Presets.
Done when: a fresh level-1 profile saves an 808 note, a roll and swing; SAVE on an untouched preset (compared with every preset and DefaultPattern, not the previous slot) doesn't advance the tour; a scripted client hears a sound within 60 s.

**A3. Sound bank + kits.** 2-4 licensed one-shots per row; Perc pitched under a minor-pentatonic lock so every tap is in key; kits level-gated. Research found no partner chromatic notes, so the agent shortlists candidates for your audition (APM SINE/SUB BOOM 01, PSE bells, finger cymbals, Tibetan Instrument 4). If none sound tonal, Perc ships unpitched and melody waits.
Reuses DAWEngine.Trigger (PlaybackSpeed), Config.LicensedCreators, t14. New: DAWConfig.Bank, kit samples in build/10_daw.lua.
Done when: t14 passes on every bank ID; the lock keeps taps in scale; the server refuses a locked kit. User check: headphone audition.

**A4. Daily cards.** Three date-seeded cards (no cross-server service), rules checked on save: BPM range, required/banned rows, "only these 3 sounds", 4+ 808 notes, a roll on step 16, B differs from A by 6+ cells. New "Challenge" XP source (30, dailyMax 3); streak in the profile.
Reuses TourUI card, DAW.Saved, DataService.AddXP. New: Systems/Challenges.lua, Modules/ChallengeRules.lua (pure, unit-tested).
Done when: with a faked date, two servers pick identical cards; a qualifying beat pays once; a near miss names the unmet rule; the streak advances on a faked day change.

**A5. Monitor queue + listener bar.** Token and cooldowns move from DAW into a MonitorService on ctx (FIFO of 4, one entry per player). Listeners get FIRE and SAMPLE IT, which copies the airing song into an empty slot tagged with its author. A sample airs only after 8+ changed cells; the author earns capped Fire/Flip XP.
Reuses NowPlaying, DAWEngine sync path, CellsDiffer, HUD. New: Services/MonitorService.lua, two remotes, HUD listener bar.
Done when: in a 2-player Local Server test, P2 queues and airs automatically, then samples, edits and airs with "flip of P1" shown; P1 gains XP once; an unchanged sample is refused.

## 5. Milestone B
**B1. Session-locked saves.** UpdateAsync honours `_old` via a stealable lock; needed before trusting streaks or going cross-server.
Done when: a fake-store test shows two servers can't both write.

**B2. Audio API engine + mixer** (flagged). One AudioPlayer per row, scheduled with `Play(atTime)` on GetMixerTime aligned to the server bar; row faders; a Vibe knob (Clean, Lo-fi filter+distortion, Hall reverb); AudioAnalyzer meters.
New: Modules/DAWEngineAudio.lua behind the DAWEngine interface. Done when: sync holds within 1 step and Vibe changes analyzer readings on both clients. User check: phone frame rate.

**B3. Weekly Flip** (BeatBattles stub; needs your library answer). One seed song, one entry each; a booth Listening Station hides authors; a vote counts only after a full play, no self-votes, trimmed mean; voters earn XP. Entries in a weekly DataStore, IDs in a MemoryStore sorted map.
Done when: fake-store tests rank 10 entries correctly and reject self and early votes.

**B4. Producer profiles + tags.** Titles (Intern to Platinum), an overhead tag from the Level attribute, and a discography (airings, fires, flips, streak); tap a player to audition their songs.
Reuses ProfileFunction (opened to others), Profiles stub, PanelUI. Done when: P2 sees P1's tag and correct counts.

## 6. What it cuts or postpones from the current ROADMAP Milestone 4
- **Fire reactions:** kept, inside A5.
- **Nameplates:** moved to B4. A level number means little until the ladder has content.
- **Neon tube signs:** postponed. Polish that costs lights and parts; they can pulse on BeatBus later.
- **Readable credits wall:** postponed until your titles decision.
- **Lived-in furniture:** postponed. Spend parts once the loop holds players.
- **Launch kit:** drop-off tracking stays as a small A task (AnalyticsService funnel: PC, first sound, save, airing, card). Trailer and stills wait for a loop worth filming; stills need your approval.

## 7. Risks and constraint check
- **Robux:** none; unlocks come from XP.
- **Audio:** every ID goes in DAWConfig.Bank; t14 fails anything not APM or PSE.
- **Beds:** one-shots only, played only when a player airs them, 20 s max. Whether that counts as a bed is your call.
- **OK's name and sounds:** unused; everything is generic.
- **Images:** no uploads.
- **Free-model scripts:** none.
- **Mobile:** about 60 parts (B3 station), no new lights (21/24), one AudioPlayer per row.
- **Explicit titles:** untouched.

Top risks:
- **Fun:** kids may not want to compose. Presets, tight cards, an in-key Perc row and flips lower the bar; the funnel will tell.
- **Technical:** v3 touches about 850 lines of DAWUI/DAWClient and every DAW test, and the queue refactor could break sync. Migration tests first; Audio API behind a flag.
- **Moderation:** raw beat strings are never shown (the 808 alphabet a-y can spell words); songs get auto names ("Song 2 · 142 · AABA"); free-form creation may force 13+.

## 8. Decisions the user must make
- Publish privately, turn on API access, set MaxPlayers to 12.
- Approve the genre at level 1 and the new ladder.
- Audition the shortlisted sounds.
- Do player loops on the monitors or at the B3 station count as "music beds"?
- A global beat library or chart may breach the Licensed Music "music library within an Experience" clause (unverified). Stay in-server until you check?
- Fan-made or official, before any branded card or event.
- Accept a possible 13+ rating?