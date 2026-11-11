# Overnight build report (2026-10-22)

Started 05:19 EDT. You said "go" for Milestones 1 and 2, and Milestone 3 if time allows.
Place state at start: unsaved (PlaceId 0), Studio in Edit mode, Mac on battery at 63%.

## Status
- [x] Step 0: code moved into src/ files, sync tool, tests prove no change (12/12)
- [x] M1.1 Beat maker at the desk
- [x] M1.2 Feels like an instrument
- [x] M1.3 Play it for the room (licensed hi-hat first)
- [x] M1.4 First-look fixes
- [x] M1.5 Studio sounds
- [x] M2 Safe saves (trusted saves, fair XP, no spamming, sound check, titles switch) · [ ] light zoning: reverted, see 06:45
- [x] M3: better beats, unlocks, progress on screen, richer surfaces, Studio Tour
- [ ] M4: not started (agreed: not tonight)

## Log
- 05:30 Step 0 done. 22 scripts pulled from Studio into src/, tools/sync.py + tools/test.py + tools/checkpoint.sh added, 06 and 10 reduced to structure only (old versions kept as _legacy_*.txt), streaming turned off. Full suite 12/12 before any feature work. Checkpoint step0.
- 05:55 Milestone 1 done, full suite 17/17. Snapshot v6_m1_2026-10-22, checkpoint m1. Screenshots in captures/m1/.
  - Desk: F at the studio PC seats you in the producer chair, camera over the console (checked by projecting the meters and screen into the frame: they sit above the window). Space/X play-stop, Backspace/B close, prompts and touch controls hidden while open, all restored on close, stand-up, death or respawn (tested by killing the player with the window open).
  - Phone layout: full-screen window, transport column, 1-8 / 9-16 pager you control (it never flips on its own; a dot shows where the playhead is). Every pad and control measured at 44 px or more at 844x390 and 667x375. Not yet tried on a real phone.
  - Instrument: tapping a pad plays it, hits flash white on the playhead, a beat ruler with a moving dot, drag along a row to fill it, CLEAR turns into UNDO for 4 s, SAVE moved to the far end, console meters now peak on kicks (measured: kick steps avg 6 vs 2 on other steps).
  - On monitors: a beat plays through Speaker_L/R for everyone in range, timed from server time (every client computes the same step; test measured within 1 step). One slot, busy and 20 s author cooldown, empty or malformed beats refused, the side screen and lounge TV show NOW PLAYING · prod. <display name>. Your own preview stops while your beat is on the monitors. Two-player hearing still needs your Local Server test.
  - Hi-hat is now Pro Sound Effects "Metal Spice Shaker 1" (licensed), cut to 0.12 s. Product-info check: APMOfficial = creator 7462718749, ProSoundEffects = 7462895450; the old hat was kyleamida (1180860872). Listen to whether the shaker works as a hat.
  - First look: door starts open, posters no longer overlap each other or the plant, plaque reads OK STUDIO · EST. 2023, PC screen and side screen show real info, TV third screen points to the beat maker, mic toast says 'Take done', console toast shows +5 XP.
  - Sounds: 7 licensed Pro Sound Effects sounds on the light switch, door, console, mic, TV, PC and credits wall, played from the part so people nearby hear them.
- 06:20 Milestone 2 done, full suite 21/21 under a stricter test runner (a review found the old runner could count a failed test as passed; it now requires each test's own success line and fails on any play-session console error). Snapshot v7_m2_2026-10-22, checkpoint m2.
  - Saves: a profile load retries 3 times; if it still fails the player is told and that profile is never written. Saves go through UpdateAsync with a schema version and timestamp, changed profiles autosave every 2 minutes, everyone saves in parallel at shutdown. Unit-tested with fake stores (t13): a failing store gets zero writes.
  - Fair XP: one gate for every source. Console 5 XP once per 10 min, mic 10 XP once per 2 min, both capped at 60 a day; beat saves pay 10 XP only for a beat with 4+ hits that changed by 4+ cells, never the same beat twice a day, at most 5 a day. Fixed level ladder 0/100/250/450/700/1000/1400/1900/2500/3200. Messages mention XP only when it was really awarded (t07: ten fast console presses = exactly +5 XP and one '+5 XP' message).
  - No spamming: per-player cooldowns on every prompt, plus room-wide cooldowns on the door and lights. The light switch can no longer be used through the wall from the lounge.
  - Light stays in its room: measured that a spotlight's Angle is its full cone (test scene, captures/_spot_test.jpg). Ceiling cans, pendants, the couch lamp and corridor lights are now downward spotlights whose cones stop short of the shared walls; signs light only their own room; every other light's range stops at the wall. Still 21 lights. QA asserts all of it.
  - Sound check (t14): all 11 sounds belong to APMOfficial or ProSoundEffects per Roblox's product info. Pending you: publish, API access, MaxPlayers (currently above 12), titles decision.
  - Titles switch: Config.Content.ShowExplicitTitles (left true, as now). False hides F*CK SWAG and the 9 BAD ASS F*CKING KID titles from the wall, the panel and the poster.
  - Also shipped early from Milestone 3: the HUD (level badge, XP bar, +XP floats, LEVEL UP banner, OS button for your profile, mute-monitors toggle), tested in play.
- 06:35 Milestone 1 review fixes + most of Milestone 3, full suite 24/24 (strict). Snapshot v8_m3_beats_2026-10-22, checkpoint m3_beats.
  - Review fixes (a 3-agent read-only review of the Milestone 1 code; every finding checked against the code before changing anything):
    - Monitors cooldown bypass closed: a beat whose time is up is finished before any new request is judged, so the author's 20 s cooldown is always recorded. Playing on the monitors now requires being at the studio PC.
    - Unsaved beats are no longer lost: closing, standing up or respawning keeps the draft; reopening shows it with 'Unsaved beat kept'.
    - Phone layout sizes itself from the safe area (notched phones), the status line gets its own row on phones, SAVE and CLEAR are a control apart, an invisible modal button frees the mouse in first person.
    - The meters now react to snare and clap too (beat signals keyed by track name; a sparse numeric table was being turned into string keys).
    - Status updates when your beat finishes on the monitors or when PLAY stops it; empty beats can't be saved over a slot.
    - Interaction sounds only play when something actually happened; the TV says when the monitors own it; controller selection and 'Backspace / B to close' on the panel; copy fixes (no '[F]' baked into world text, Sessions tab wording, version label).
    - The test runner was the review's most important catch: it now fails on any console error and only accepts each test's own success line.
  - Better beats (format v2): 5 rows (Kick, Snare, Clap, Hat, 808). Hat pads cycle hit, x2, x3 (rolls); 808 pads cycle root, +3, +5, +7, -2 and play the sub boom at that pitch; swing 0/25/50%; three beat slots (keys s1-s3) with old beats migrated into slot 1. 808 sound: APM 'BOOM-Sub Boom 01' (licensed; listen to it).
  - Unlocks, enforced by the server: level 2 808, level 3 hat rolls, level 4 swing. Locked rows and buttons say which level unlocks them; the server refuses a locked beat even from a modified client.
  - Progress on screen: the HUD from earlier plus level-up banners that name the unlock.
  - Richer surfaces: lit charcoal ceilings with wood beams, cooler walls against the warm floors, leather seating, carpet in the control room and booth, foam tiles at two depths. Built-in materials only, no lights added (21), 502 parts.
- 06:45 CORRECTION on Milestone 2 'light stays in its room': I marked it done at 06:20 on the strength of the QA geometry check, without looking at the rooms. Screenshots taken at 06:40 showed the narrowed spotlights left the lounge and control room nearly black under ShadowMap (captures/m3/focus_lounge.jpg, focus_control.jpg); four times the brightness didn't fix it (boost_*.jpg). I reverted to the original lights (reverted_*.jpg look right again). Light still bleeds through the thin walls under ShadowMap. The real fix is your lighting decision: set Lighting > Technology to Future, which renders the lamps with proper shadows (heavier on phones). The QA gate now checks every room has its own lights instead.
- 06:50 Corridor brighter: the corridor strip, sconce and uplight were turned up so the floor reads in the dark corridor (captures/m3/lit_corridor.jpg). Still moody, still 21 lights.
- 06:52 Studio Tour done, Milestone 3 complete. Full suite 29/29 (strict). Snapshot v10_m3_tour_2026-10-22, checkpoint m3_tour_0652.
- 06:59 SKIP made a 44 px touch target, outline verified, full suite 29/29 again. Final snapshot v11_m3_final_2026-10-22 and a final checkpoint in checkpoints/.
  - A small card under the level badge: STUDIO TOUR 1/4, the step, and a SKIP button 44 px tall for thumbs. A pink outline marks the thing to use next. Checked with a same-frame pair, outline off and on (captures/m3/tour_outline_off.jpg, tour_outline_on.jpg); at the PC step it frames the left monitor (tour_desk_step3.jpg).
  - Four steps: check the credits wall, power the console, save a beat at the studio PC, press ON MONITORS. They count in any order; the card always points at the first one left.
  - The monitors step counts even when someone else's beat is playing or your cooldown is running, so nobody gets stuck waiting.
  - Finishing pays +50 XP once, with a 'Studio tour complete' message. Skipping pays nothing. Both are stored in the profile, so the card doesn't come back next visit once saves work.
  - Tests (t17): reset, out-of-order steps, outline moves with each step, card stays up with the beat maker open, completion hides card and outline, reward paid once, skip hides everything and pays nothing. The card and outline also survive a respawn.

## Where things stand
- Milestones 1, 2 and 3 are built and tested; 29 of 29 tests pass. Nothing was saved or published to Roblox, no images were uploaded, the titles switch is unchanged, and all sounds come from APMOfficial or ProSoundEffects.
- Working versions inside the place: ServerStorage.OK_Versions has v6_m1, v7_m2, v8_m3_beats, v9_m3_lit, v10_m3_tour and v11_m3_final (latest). The original is in ServerStorage.OK_Backup_2026-10-22. File checkpoints are in checkpoints/.
- Known limits:
  - Light still bleeds through the thin walls under ShadowMap (see 06:45).
  - On phones the beat maker window covers the console view, so the over-the-desk camera framing only shows on desktop.
  - Profiles only last for the session until the place is published with API access on.

## Needs you
1. Save the place. It is still unsaved (PlaceId 0); File > Save to File keeps a local copy, and saving to Roblox is your call.
2. Lighting: try Lighting > Technology = Future to stop the bleed, and check it on a phone.
3. Titles: keep or hide the explicit titles (Config.Content.ShowExplicitTitles, currently true).
4. Publishing: publish, turn on Studio Access to API Services so saves persist, and set MaxPlayers to 12 or fewer.
5. Listen with headphones: the shaker used as a hi-hat, and the APM sub boom used as the 808.
6. Test on a real phone, and run a two-player Local Server test to hear a beat on the monitors from another player.
7. Tell me what 'you have permission' covered. I've only treated it as permission to keep working, not to use OK's own name, sounds or logo.
