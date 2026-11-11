**OK Studio: Roblox platform constraints for new gameplay (checked 2026-10-22)**

Read-only research. I changed no files and made no MCP calls. Source codes in [brackets] are listed at the end. "Unverified" means I found no primary statement.

## 1. New Audio API
- **Status:** the Audio API left beta on 10 Sep 2024 [A7]. Roblox now "discourages" Sound, SoundGroup and SoundEffect [A0]. Acoustic simulation (occlusion, diffraction, reverb) is still a Client Beta (live since 29 Jan 2026). It "may work differently (or be completely disabled...) on some lower-end devices" [A9]. Whether the core API fully works on mobile isn't documented (unverified); test on a phone.
- **Sequencer timing:** `AudioPlayer:Play(atTime)` and `Stop(atTime)` schedule against `SoundService:GetMixerTime()` for "sample-accurate, framerate-independent timing" [A1]. GetMixerTime "starts at an arbitrary value, and can differ between machines" [A2]. So keep the current server-time sync to set a shared bar start, then convert it to each client's mixer clock for exact step timing.
- **Meters:** AudioAnalyzer gives PeakLevel, RmsLevel and `GetSpectrum` (RMS bins from 0 to 24 kHz). It only works on the client; on the server the levels are always 0 and the spectrum is empty. GetSpectrum is also empty whenever an input comes from AudioDeviceInput. Setting `SpectrumEnabled=false` "dramatically" reduces CPU [A3]. Real per-track VU meters and a spectrum display are feasible on the client.
- **Mixer and per-track effects:** available effects are AudioFader, Equalizer, Compressor (can duck), Reverb, Chorus, Distortion, Echo, Flanger, PitchShifter and Tremolo [A5], plus AudioFilter [A7] and AudioLimiter [A8]. A per-row chain of player → effects → fader → master → emitter is buildable.
- **Melodic notes from one sample:** use `AudioPlayer.PlaybackSpeed` (0–20), "directly controlling its perceived pitch" [A1]. It resamples, so pitch and length change together (2^(n/12) per semitone). AudioPitchShifter only covers 0.5–2, "may introduce artifacts", and larger windows add latency [A4]. Use it as an effect, not for playing notes.
- **Sound that stays in its room:** a listener only hears emitters that share its `AudioInteractionGroup` [A6]. To use this, switch the local listener's group when the player enters a room. The listener Roblox creates by default has an empty group [A2], so once speakers are grouped, a script has to manage the listener (and voice). Unverified: whether one listener can belong to more than one group.
- **Limit on simultaneous sounds:** no number is documented. A Roblox staff member (2 Dec 2024) said a cap exists. Old Sounds hit it too and drop the least audible ones. They offered to raise it to 400 [A8b]. The "~300" figure comes from a user report.
- **Memory:** a loaded asset can still be unloaded "if there is extreme memory pressure" (`IsReady` goes false) [A1].
- **Enables / blocks:** this enables a sample-accurate sequencer, real meters, an effects mixer, one pitched instrument and room-isolated audio. Nothing hard is blocked, but acoustic simulation isn't ready for production.

## 2. Voice chat
- **Who can use it:** players 13+ who have passed an age check (ID or facial age estimation). Phone verification no longer counts. This came from a search snippet of the Voice FAQ; the page itself returned 403 to me [V4]. Voice is on by default for new games with up to 100 players [V2].
- **Age grouping:** age-grouped chat has been enforced worldwide since Jan 2026 [V5a]. `VoiceChatService:GetChatGroupsAsync` (server only) and `IsVoiceEnabledForUserIdAsync` exist [V2b]. The Feb 2026 post called the grouping call "GetVoiceGroupsAsync" [V5b]; the docs name it GetChatGroupsAsync.
- **Vocal booth effects:** with `UseAudioApi=Enabled`, each voice is an AudioDeviceInput that can be rewired through effects, for example room reverb [A13, V2b]. A chain of AudioDeviceInput → Reverb/Echo/PitchShifter → booth emitter is feasible. Set `Player` and `AccessType` from the server [V1].
- **No real autotune:** GetSpectrum returns nothing for voice, so there's no pitch detection. Only a fixed pitch shift is possible.
- **Recording is confirmed impossible.** AudioRecorder is "in development and is not available yet". It has a 60 s limit, its output only lasts the session, and "AudioDeviceInput cannot be recorded". Its `GetUnrecordableInstancesAsync` traces back through the graph [A10], so routing voice through effects to get around it is likely blocked (my inference).
- **Enables / blocks:** this enables a live-effects booth for eligible players. It blocks recorded takes and autotune. Many players can't use voice at all, so the booth needs a mode that works without it.

## 3. Player text and player-made content
- **Filtering:** you must filter any user text you display. Do it on the server: `TextService:FilterStringAsync(text, userId)`, then `GetNonChatStringForBroadcastAsync` (everyone) or `GetNonChatStringForUserAsync` (one viewer). Filter stored text again when it's loaded. Roblox can remove games that don't filter [T1].
- **2026 chat rules:**
  - "All text-based player-to-player communication is required to go through TextChatService" [V5a].
  - Systems "must not facilitate unrestricted, real-time communication between players of different age groups" [V5b].
  - Custom presets: at most 12 per universe, each passed through FilterStringAsync, rate-limited to one send per 10 s; the deadline was 26 Apr 2026 [V5c].
  - My inference: filtered beat titles and bios are fine. Free-text comment boxes or collab invites would count as chat and must go through TextChatService.
- **Free-form user creation:** this makes a game 13+ only. The definition excludes creations "players assemble with 3D assets" and anything that passes moderation [M1]. Whether a fixed-sample step sequencer counts isn't addressed (judgment call; unverified).
- **Sharing beats:** a pattern is just data (step grid plus asset IDs) and needs no upload. I found no rule about player-made "music" built from library audio (unverified).

## 4. Cross-server features
| Service | Limits | Fit |
|---|---|---|
| MemoryStore [X1] | Memory quota 64 KB + 1.2 KB × CCU for the whole experience. Requests 1000 + 120 × CCU per minute. 100k request units/min per structure. About 30k per partition on the memory-stores page, but the best-practices page uses 150k RPM as an example; both are backend-configured. 32 KB per value, expiry ≤45 days, sorted map ≤1M items / 100 MB, GetRangeAsync ≤200 | At 12 CCU: about 78 KB memory and 2,440 requests/min. Memory is the binding limit, so keep only IDs and scores for a live chart here and full patterns in DataStore |
| MessagingService [X2] | 1 kB per message. Sends: 600 + 240 × players per minute per server. Receives per topic: 40 + 80 × servers per minute. Best effort, usually 1–2 s | A packed 16×5 pattern is a few bytes, so cross-server "beat drops" work, but delivery isn't guaranteed |
| OrderedDataStore [X3] | Integer values only, page size ≤100. GetSortedAsync 5 + 2 × players per minute per server (29/min at 12 players) | Weekly board: use a new store name each week and cache the top 100 |

**Licensed Music Terms of Use:** "Creator may not use Licensed Music to create a streaming service or music library within an Experience". This comes from a devforum user quoting the Terms; the Terms page returned 403 to me [L2]. A browsable global chart or jukebox built on APM audio may fall under this. Whether it applies to PSE sound effects is unverified, so ask the user before building library features.

## 5. Maturity label and IP
- **Experience Guidelines:**
  - Any depiction or reference of alcohol makes the game "only available to verified players that are at least 17", with no lighter tier. Strong language is also 17+.
  - Social hangouts are 13+, and free-form creation is 13+.
  - An experience without a completed questionnaire is treated as 13+ and can't contain 17+ content [M1].
- **Community Standards:**
  - They ban depicting "controlled substances such as pharmaceutical products and recreational drugs, as well as alcohol" and "intoxicated behavior".
  - They ban swearing in "any language, text, images, or uploaded audio", including "profane lyrics".
  - They point to a Restricted Content Policy for 17+ games, which I did not read [M2].
- **What this means:**
  - "Perc Soda" breaks the Community Standards; a 17+ label doesn't fix it.
  - Explicit song titles mean either a 17+-only game or a violation.
  - On an account that already has a strike, both are high risk.
- **Real artists:** impersonation is banned "in ways that may damage their reputation". Rights holders can file takedowns, and Roblox may remove content on its own [M2]. A famous person's likeness rights are "separate" from Roblox's rules, and giving credit doesn't grant rights [M3]. I found no explicit rule on fan-made games (unverified). OK's written permission is the safe route.

## 6. Licensed audio library
- **Finding sounds:** in Studio, go to Toolbox → Creator Store → Audio, then use the advanced filter by creator username or verification. Use "Copy Asset ID" for AudioPlayer [L1]. PSE asset names end in "(SFX)" [L3].
- **What my sample search found:** about 10 queries on the public search endpoint, first page only (its creator filter was ignored), so absence isn't proven [L4].
  - **APMOfficial:** stings, tags and hits, plus synth stabs such as "Thrive Synth Stab" (9040544052). These are phrases in a key, so pitching them will clash. It also has booms: "SUB BOOM 01" (9043342211) and "SINE BOOM 01" (9043341776), which might work as 808-style sounds after auditioning.
  - **ProSoundEffects:** "Crash Cymbal Metal Hit" (9113966034), finger cymbals, bells, "Tibetan Instrument 4" (9120032991) and impacts.
  - **Clean chromatic notes** ("piano note c4", etc.) only came from a non-partner user (I_AmKota), so the partner-only rule excludes them.
  - **Not found:** partner piano, guitar or synth single notes, and partner kick, snare or hat one-shots.
- **APM terms:** usable only on Roblox. Derivative versions made with Studio sound properties are allowed "solely within your game on Roblox". Up to 250 licensed tracks per game. This came from a search snippet; the help page returned 403 [L2]. I found no other limit on using APM audio inside player-made beats (unverified).
- **Music-bed warning:** the SoundEffect/Music label doesn't settle whether something is a bed. "Funk Bed (c)" is labelled SoundEffect, and "Kick It Drums And Bass Only" is a 122 s Music track. Looping an APM sting also effectively makes a bed. This is the user's call under the pending audio question.

## 7. Mobile and performance
- **Highlights:** a client shows at most 255; extra ones are silently ignored, and disabled ones still use a slot [P1].
- **SurfaceGui:** its appearance is cached until it changes, and a high PixelsPerStud hurts performance. Buttons only take input when the SurfaceGui sits in PlayerGui with an Adornee [P2]. My inference: animated meters re-render on every change, so keep them few and at low resolution.
- **Particles and lights:** "property changes to ParticleEmitters can have a dramatic impact on performance". Shadows are expensive, so turn `Light.Shadows` off where it isn't needed; Roblox disables shadows below quality level 4. Audio can be a "surprising contributor to memory usage" [P3]. Mobile devices have "severe memory limitations" [P4].
- **Many AudioPlayers:** performance reportedly drops even when they aren't wired (a user bug report I saw only in a search snippet) [P5]. My recommendation: keep a pool of one AudioPlayer per row per client and re-trigger it, rather than one per step.

## Sources
- A0 https://create.roblox.com/docs/audio/objects
- A1 https://create.roblox.com/docs/en-us/reference/engine/classes/AudioPlayer.md
- A2 https://create.roblox.com/docs/en-us/reference/engine/classes/SoundService.md
- A3 https://create.roblox.com/docs/en-us/reference/engine/classes/AudioAnalyzer.md
- A4 https://create.roblox.com/docs/en-us/reference/engine/classes/AudioPitchShifter.md
- A5 https://create.roblox.com/docs/en-us/audio/effects.md
- A6 https://create.roblox.com/docs/en-us/reference/engine/classes/AudioEmitter.md and https://create.roblox.com/docs/en-us/reference/engine/classes/AudioListener.md
- A7 https://devforum.roblox.com/t/roblox-audio-api-exits-beta-enhanced-sound-controls-now-available/3153454
- A8 https://devforum.roblox.com/t/new-audio-api-features-directional-audio-audiolimiter-and-more/3282100
- A8b https://devforum.roblox.com/t/new-audio-api-beta-elevate-sound-and-voice-in-your-experiences/2848873?page=23
- A9 https://devforum.roblox.com/t/beta-acoustic-simulation/3634265
- A10 https://create.roblox.com/docs/en-us/reference/engine/classes/AudioRecorder.md
- A13 https://devforum.roblox.com/t/2848873
- V1 https://create.roblox.com/docs/en-us/reference/engine/classes/AudioDeviceInput.md
- V2 https://create.roblox.com/docs/en-us/chat/voice-chat.md
- V2b https://create.roblox.com/docs/en-us/reference/engine/classes/VoiceChatService.md
- V4 https://en.help.roblox.com/hc/en-us/articles/4405807645972-Voice-FAQ (403; search snippet only)
- V5a https://devforum.roblox.com/t/age-check-requirement-to-chat-now-live-globally/4226101
- V5b https://devforum.roblox.com/t/february-6-2026-an-update-on-our-age-check-to-chat-fast-follow-roadmap/4340230
- V5c https://devforum.roblox.com/t/march-26-2026-an-update-on-our-age-check-to-chat-fast-follow-roadmap/4539685
- T1 https://create.roblox.com/docs/en-us/ui/text-filtering.md
- X1 https://create.roblox.com/docs/en-us/cloud-services/memory-stores.md, https://create.roblox.com/docs/en-us/cloud-services/memory-stores/best-practices and https://create.roblox.com/docs/en-us/reference/engine/classes/MemoryStoreSortedMap.md
- X2 https://create.roblox.com/docs/en-us/reference/engine/classes/MessagingService.md
- X3 https://create.roblox.com/docs/en-us/cloud-services/data-stores/error-codes-and-limits.md and https://create.roblox.com/docs/en-us/reference/engine/classes/OrderedDataStore.md
- M1 https://create.roblox.com/docs/en-us/production/promotion/experience-guidelines.md
- M2 https://about.roblox.com/community-standards
- M3 https://devforum.roblox.com/t/protecting-creativity-by-understanding-intellectual-property/2559638
- L1 https://create.roblox.com/docs/en-us/audio/assets.md and https://create.roblox.com/docs/en-us/production/creator-store.md
- L2 https://en.help.roblox.com/hc/articles/360000927163 (403; search snippet only) and the Terms of Use quote at https://devforum.roblox.com/t/bloxtunesco-spotify-like-app-for-roblox-music/3784402
- L3 https://www.moguravr.com/?p=163858
- L4 https://apis.roblox.com/toolbox-service/v2/assets:search?searchCategoryType=Audio
- P1 https://create.roblox.com/docs/en-us/reference/engine/classes/Highlight.md
- P2 https://create.roblox.com/docs/en-us/reference/engine/classes/SurfaceGui.md
- P3 https://create.roblox.com/docs/en-us/performance-optimization/improve.md
- P4 https://create.roblox.com/docs/en-us/performance-optimization/design.md
- P5 https://devforum.roblox.com/t/audio-api-performance-issue/3928632 (search snippet only)