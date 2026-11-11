# Launch-readiness audit — 2026-11-05 (read-only, adversarially verified)

Workflow wf_1d355da6-366: five auditors (remotes, Studio-only surfaces, real saves, live runtime, phone + content), each finding checked by a skeptic. Studio-only surfaces: clean. Below: every confirmed finding, verbatim, most severe first. Line numbers are as read on 2026-11-05, before Wave 3 Tasks 2–4 changed WalkIns, Phone, Contracts and Career.

## A1 — Blocker — src/ReplicatedStorage/OK/Modules/DAWUI.lua:196-225 (header placement, compact branch); src/StarterPlayer/StarterPlayerScripts/OK/DAWClient.client.lua:37 (OK_DAW uses DeviceSafeInsets)

**Problem:** On phones, the compact beat maker's header row is drawn inside the 58 px Roblox top-bar strip, under the core Roblox-menu button and the unibar pill. CoreGui is drawn above PlayerGui and its buttons take the tap.

Positions in the safe area:
- page button 1–8: x 16–76, y 10–54
- page button 9–16: x 82–142, under the unibar
- possibly slot 1 (x 160–204), depending on the unibar's collapsed width (chat and voice change it)

Page 2 can only be reached by tapping the 9–16 button. Drag-paint is clamped to the visible page (DAWUI.lua:500-505), and there is no swipe, auto-page or other touch path. So a phone player cannot edit steps 9–16 in either the drums view or the KEYS view.

This breaks the core money loop on the main platform:
- `backbeat` (snare/clap on step 13, BriefCheck.lua:65) is a required ask in most regular and daily briefs (Artists.lua:43,47,51,63,67; DailyRequests.lua:11,13,16,18).
- OFFHATS needs steps 11 and 15.
- Hat n=12 needs page 2.
- Cypher briefs come from the same templates.

**Fix (verifier):** State the fix as a layout constraint, not a shift.

Neither offered fix fits at 667×375:
- Shifting the whole header right by TopbarInset.Min.X (about 150 px or more) pushes KEYS from 434–504 to about 584–654. That collides with the REQUESTS chip (465–589) and the close button (605–649).
- Dropping root to TopbarInset.Max.Y gives H ≈ 311, so avail = 311−52−20 = 239. The transport column needs 6×44 + 6×4 ≈ 288, so SAVE would sit about 49 px outside the window and t30's containment check fails.

The constraint, in compact layout:
- No visible GuiButton may intersect the rect from x 0 to (TopbarInset.Min.X − gui.AbsolutePosition.X) and from y 0 to (TopbarInset.Max.Y − gui.AbsolutePosition.Y).
- Every header item must stay clear of the chip and the close button at 640 and 667 widths.

Practical layout:
- Start the header row at the top-left exclusion's right edge (read GuiService.TopbarInset live and re-layout on its change).
- Move the page buttons out of the top row, into the transport column or a pager under the ruler, and shrink KIT (112 → ~80).
- Fit-check together with the chip/KEYS overlap finding.

Add a t30/t57-style assert that no visible OK_DAW button intersects the top-left core-UI rect taken from GuiService.TopbarInset.

**Verifier:** Reachable on every phone.
- compactWanted() is `UIS.TouchEnabled and vp.Y < 600` (DAWClient.client.lua:285), true for any phone in landscape.
- In compact mode, root sits at (6, 6) in a DeviceSafeInsets GUI (DAWUI.lua:198) and the header at (pad 10, 4) (DAWUI.lua:224). That puts the 44 px buttons at y 10–54.
- The project itself measures the top bar as 58 px: WalkInUI.lua:46 says "667x375 phone under a 58 px top bar"; t57b asserts the CoreUISafe card top is 58; FIRE is placed at y 60 in its DeviceSafe GUI to clear it.

Nothing guards it.
- No code in src calls SetCore("TopbarEnabled"), SetCoreGuiEnabled, TopbarInset or GetGuiInset.
- restore()/enter() only toggle TouchControlsEnabled, which hides the thumbstick, not the top bar.
- The t30 phone check forces ViewportOverride/CompactForced. It asserts only size ≥ 44 and containment in the window, never clearance from the core UI.

The finding's own severity (High, Blocker if confirmed) undersells it, because page 2 carries required brief asks.

Falsifier: in Studio's phone emulator at 667×375, read GuiService.TopbarInset.Min.X converted into OK_DAW's space (subtract gui.AbsolutePosition.X). If it is at or left of x 82, the 9–16 button is not covered, and this drops to the 1–8 button only (Medium). The mechanism is otherwise standard Roblox behaviour.

## A2 — High — src/ReplicatedStorage/OK/Systems/BeatBattles.lua:259 (M.Join idle branch 86-94, cancel 78-84, lobby end 303-308); hold checks via cypherIdle() at src/ReplicatedStorage/OK/Systems/WalkIns.lua:116-120, :563, :656 and src/ReplicatedStorage/OK/Systems/Phone.lua:73-77, :370

**Problem:** Any client can open a cypher round from idle by invoking Cypher_Join. The remote has no phase check, distance check, cooldown or IsStudio gate. The real UI never does this: CypherUI.lua:166 shows JOIN only in the lobby, and the board goes through InteractionService, which checks distance and has a 1 s per-player cooldown. One exploiter (or a griefer who keeps pressing the board when it's idle) gets the exploiter alone into each lobby. That lobby is cancelled after 20 s, sits in a 4 s 'reveal', goes idle, and the exploiter reopens it. While the phase isn't idle, the walk-in and phone schedulers hold for every player on the server:
- **Phone:** `eligible()` is false, so the phone timer doesn't run at all.
- **Walk-ins:** the timer still counts down in `tick`, but `schedule()` is refused and then retried once a second at 0. A script that invokes Cypher_Join every frame reopens the lobby within about one frame of `toIdle`, so the 1 s tick almost never lands in an idle window and walk-ins effectively stop.
- **Toasts:** every player also gets two server-wide toasts every ~24 s ('A cypher is starting', then 'not enough joined').

The board-only version needs no exploit but still holds the server for ~24 of every ~25 s. Monitors are not affected: `SetReserved` only runs in `toListen`.

**Fix (verifier):** BeatBattles.lua:259: `R.Cypher_Join.OnServerInvoke = function(player) if S.phase == "idle" then return { ok = false, reason = "busy" } end; return M.Join(player) end`. "busy" already maps to a UI string, and the real UI never joins from idle. To also cover the board griefer, pick one:
- In the Interaction "Cypher" handler, refuse a new lobby from a UserId whose last opened lobby was cancelled less than ~120 s ago.
- Or have WalkIns/Phone cypherIdle() treat "lobby" as idle, so the hold starts only at "build", which needs 2 real entrants, and have cancel() go straight to toIdle instead of a 4 s reveal.

**Verifier:** Nothing upstream stops this. Cypher_Join is created unconditionally (build/10_daw.lua:7), and BeatBattles starts through SystemLoader on live servers. `M.Join` opens a lobby whenever `S.phase == "idle"`, with no caller or location check. Both hold sites read the replicated Phase attribute: WalkIns.lua:563 has `... or not cypherIdle() then return false end`, Phone.lua:370 has `if not Tour.State(p).done or not cypherIdle() then return false end`, and cypherIdle is `phase == nil or phase == "idle"`. Cancel sets `S.phase = "reveal"; S.endsAt = now() + 4` (line 82), so the hold also covers those 4 s. A trivial script can grief the core loop (walk-ins and phone) for a whole server and spam server-wide toasts. That makes it High. It is not a Blocker: no saves are touched and the server doesn't crash.

## A3 — High — src/ReplicatedStorage/OK/Modules/RequestUI.lua:60-61,107-109 vs src/ReplicatedStorage/OK/Modules/DAWUI.lua:212-225

**Problem:** In the compact beat maker, the REQUESTS chip covers the KEYS/DRUMS toggle whenever the GUI is narrower than about 706 px. The chip is at ZIndex 4 and the header buttons at ZIndex 1, so the chip takes the tap.

At 667×375 (iPhone SE/8, the project's own test size):
- the chip spans 465–589 and KEYS spans 434–504
- only a 31 px strip of KEYS still responds
- the centre of the label (x 469) falls on the chip, so tapping the word opens the request card

At 640×360 (older 16:9 Android), only 4 px of KEYS stays tappable.

Phones have no K key, so the KEYS view (the melody lane, PLUCK/CHIME voices, and briefs with `melody`/`melnotes`/`chord` asks, e.g. DailyRequests.lua:18) is unreachable or unreliable on those devices.

**Fix (verifier):** Fix this and the top-bar finding together: any right-shift of the header to clear the core UI makes this overlap worse.

Keep the compact header's right edge at most chipLeft − 6 at every width:
- shrink the page buttons (60 → 48) and KIT (112 → ~80), or move the pager out of the header, and
- make RequestUI place the chip at max(W − 190, header right edge + 6), with TextScaled/narrower text when space is short.

Add a t30 assert that no two visible GuiButtons in OK_DAW overlap at 640×360 and 667×375 (and at the real TopbarInset).

**Verifier:** Verified the arithmetic.

The header is a horizontal UIListLayout with Padding 6 starting at pad 10. Its items are Page1 60, Page2 60, Gap 6, Cfg.Slots=3 × 44, Gap2 6, KIT 112 and KEYS 70 (DAWConfig.lua:18 has Slots=3). That puts KEYS at 434–504 in root coordinates.

The chip is at `UDim2.new(1, -(44+14+8+124), 0, 4)`, i.e. W−190, with W = vp.X − 12. So:
- 667 gives 465–589
- 640 gives 438–562
- the overlap starts when W − 190 < 504, i.e. a safe-area width below 706

The chip is drawn on top. With ZIndex 4 against the default 1, it wins under both Sibling and Global ZIndexBehavior (chip and header are siblings under root).

On notched iPhones (safe width ≥ ~712), KEYS stays clear. So the impact is limited to SE-class iPhones and narrow Androids, but there the toggle is effectively broken.

t30 checks only size and containment, not overlap. The y range (10–54) also sits in the top-bar strip, but on the right side, which is normally free of core UI.

## A4 — High — src/ReplicatedStorage/OK/Systems/BeatBattles.lua:86-94 (Join's idle branch) and 78-84 (cancel); gates at WalkIns.lua:116-120, 563, 656 and Phone.lua:73-77, 370; client mirrors at Modules/WalkInUI.lua:369-373 (used at 392, 557) and Modules/PhoneUI.lua:407-411 (via blocked() at 422)

**Problem:** Walk-ins and phone pops are held for the whole server whenever the single global cypher Phase is not idle. One player can keep it non-idle almost all the time and toast every player twice per cycle.

**Fix (verifier):** Smallest anti-grief fix: in BeatBattles, record the time of a cancel caused by 'not enough joined' (cancel at l.308). In Join's idle branch, refuse a new lobby for about 60 s after it, returning reason 'busy' (the board and bar already have copy for it). Make it server-wide, not per uid, because a per-uid limit is beaten by alternating with an alt account. For scale (fix soon after): hold everyone only in 'listen' and 'vote', which need 2+ real submitted entries and are when the room should be listening or voting. In 'lobby', 'build' and 'reveal', hold only entrants, i.e. p:GetAttribute('CypherIn') == RS.OK.Cypher:GetAttribute('Round'). Apply the same rule in all four places: WalkIns schedule (563) and DueWithin (656), Phone eligible (370), WalkInUI.cypherBusy (369) and PhoneUI.cypherBusy (407). Otherwise non-entrants' cards are still held on the client.

**Verifier:** Confirmed, and easier to reach than the finding says: no modified client is needed. The lounge board prompt (Interaction 'Cypher', Config.Cooldowns.Cypher = 1 s, InteractionService allowed()) calls the same M.Join. The idle branch starts a lobby and calls toastAll('A cypher is starting...'). After LobbySeconds 20 with fewer than 2 entrants, cancel() calls toastAll again and holds Phase='reveal' for 4 s before toIdle(). A lone player who presses the board again about 1 s after idle keeps Phase non-idle about 96% of the time. During that time Phone.eligible() (l.370) returns false, so the pop timer only drains in the sub-second idle gaps and phone pops effectively stop server-wide. The WalkIns timer sits at 0 and schedule() retries every second, so walk-ins are delayed rather than lost (some get through in idle gaps). Their cards are still held on every client, because WalkInUI.cypherBusy() reads the global Phase. Every player also gets 2 toasts per ~24 s cycle. Organic play has the same shape: any curious tap on the board pauses everyone for 24 s. Location corrected to include the client gates. The 'only tested solo' claim can't be verified and doesn't change the verdict. I dropped the 'pcall the phase loop' clause because I found no erroring path: reveal() guards owners with isPlayer(o) and o.Parent, the Career and Life calls are pcall'd, and toListen/toIdle only set attributes and queue entries.

## A5 — Medium — src/ReplicatedStorage/OK/Systems/DAW.lua:183-216 (tryBroadcast, DAW_Broadcast 210-214, DAW_Stop 216); src/ServerScriptService/OK/Services/MonitorService.lua:100-101, 116-121, 194; src/ReplicatedStorage/OK/Systems/Flips.lua:37-38

**Problem:** DAW_Broadcast has no per-player cooldown, and DAW_Stop cancels instantly, even during the 0.5 s lead-in. A client standing at the station can loop broadcast, stop, broadcast. Each `_start` appends a history entry. `_finish` sets a 3 s gap, so the loop runs about one airing per ~3 s plus RTT. History keeps only the last 20 entries.

When nobody else is in line, one spammer flushes every other producer's airings out of history in about 60-70 s. When others are waiting, Enqueue's one-place-each ('inline') rule and the FIFO queue limit the spammer to one entry per turn of the line, so the eviction is much slower. Effects of a flush:
- SAMPLE IT flips of a beat sampled more than ~1 minute ago are refused with "gone".
- The Flips copy guard and the cypher KnownBeats copy check stop seeing evicted beats, so the spammer can launder another producer's recent beat and air it as their own.
- NowPlaying attributes (Active/Token/Beat etc.) churn and the screens flicker. Little or no audio plays: the client listener starts at StartAt and `listener:Stop()`s when Active goes false, so a stop inside the lead-in is near-silent.

**Fix (verifier):** In tryBroadcast, keep a `lastSend[player]` table like DAW_Save's `lastSave`. Refuse with `{ ok = false, reason = "cooldown" }` if less than ~8-10 s have passed since that player's last successful enqueue. Set it when `r.ok`, and clear it in the existing `Players.PlayerRemoving` handler at DAW.lua:224. Don't skip recording early-stopped airings in history: that would let a quickly stopped beat escape the copy guards.

**Verifier:** The path is reachable. tryBroadcast checks locked kit/voice, Validate, empty, `M.AtStation` (DAW.lua:72-86, a seat or within-reach-of-a-station position check that the exploiter meets by standing at a station), reserved and flip, but has no cooldown. DAW_Stop goes straight to `ctx.Monitors:Cancel(player.UserId)`, which stops as soon as `self.current.uid == uid` (MonitorService:194). `_start` always does `table.insert(self.history, ...)` and then `while #self.history > 20 do table.remove(self.history, 1) end`, and Flips.Judge only accepts a token still in history (`if not src then return nil, "gone" end`). The effects are griefing of one feature and minor credit laundering. No saves, crash or moderation risk, and it is weakest when the line is busy. Medium (fix soon after launch) is right.

## A6 — Medium — src/ReplicatedStorage/OK/Systems/Career.lua:276-279 (remote), 193-217 (M.Unlock; 212 toggle flip, 215 changed(), 216 M.State); 155-188 (lifeView/State)

**Problem:** Career_Unlock has no rate limit. Every call with a valid gate id (the ids are public in Config.Career.Gates) runs, even when it's refused as owned/needs/money:
- `changed()`: MarkDirty, which only flags the profile for the next autosave and costs no DataStore budget, then Publish (7 SetAttribute calls plus sponsorName plus Life.Publish).
- An uncached `M.State`: the gates/gear checks and `lifeView`, which clones up to 100 story and 200 discography rows (StoryMax/DiscoMax) and the roster, sponsor and artist name maps.

The whole state is then serialized back to the caller. A client spamming this (many parallel invokes) costs server CPU and outbound bandwidth on every call, which can lag the server for everyone. On refusals the attribute values don't change, so nothing replicates to other players. The exception is a player whose sponsor_tv toggle needs are met: each call flips `showSponsor`, so CareerGates replicates to every client, and the polled TV ticker (Unlocks.SponsoredLines) reads it. Publish's `built[uid] = nil` only clears the caller's own Career_Get cache, so it has no effect on other players. Gear_Equip has a token bucket (Gear.lua:144-161) and this remote has none. ProfileFunction, Session_Get, Gear_Get and Card_Get are also unlimited, so this is the heaviest case of a general missing per-player limiter.

**Fix (verifier):** Put Gear's token bucket (a burst of 3, then one every 0.25 s) in front of Career_Unlock and return `{ ok = false, reason = "busy" }` without building State when it's empty. In M.Unlock, call `changed(player)` and build `res.state` only when a room was bought or the toggle flipped (`res.ok`). On refusals return `res.state = M.Fetch(player)` so the 0.25 s cache applies. Better still, wrap every OnServerInvoke (ProfileFunction, Session_Get, Gear_Get, Card_Get, Career_Get) in one shared per-player limiter.

**Verifier:** The remote only checks `type(id) == "string" and #id <= 24`. `M.Unlock` then always runs `changed(player)` (line 215) and `res.state = M.State(player)` (line 216) on every branch. A scratch benchmark of LifeRules.View on a full life (100 story / 200 disco rows), run with the luau CLI, took ~0.16 ms per call for View alone, before Publish, Life.Publish, the gear and gates checks and serializing the reply. Spam can therefore cost real server CPU, but it is a generic remote-spam DoS, not a save-loss, crash-on-its-own or cheat. Medium (fix soon after launch) is right, not higher.

## A7 — Medium — src/ReplicatedStorage/OK/Systems/DAW.lua:179 -> src/StarterPlayer/StarterPlayerScripts/OK/DAWClient.client.lua:476 (live path); flags set in src/ServerScriptService/OK/Services/DataService.lua:231-234 (_loadFailed), :339 (_lockLost), :240-243 (_newerSchema). DAW.lua:131 also sends `persistent` in the OpenDAW payload, but no client code reads it (DAWClient only reads `persistent` at :476), so :131 is secondary. Line numbers are as read on 2026-11-05; no half-edits were seen.

**Problem:** A session that will never save still tells the player "Saved". This happens when the load fails (every UpdateAsync attempt errors during a DataStore incident), when the server lost the lock (_lockLost), or when a newer build wrote the profile (_newerSchema). In each case Save refuses to write (DataService:308-310), but the DAW save remote still returns `persistent = ctx.Data.Persistent == true`. That is the server-wide store flag, which is true on every live server, so DAWClient:476 shows "Saved" (+XP) on every beat save. The only warning is a single toast. PanelUI.lua:494 hides it after 2.5 s (`task.delay(2.5, ...)`), and because of `toastToken`, any later toast replaces it, including the DAY toast shown at join (ClientMain:139-140). Nothing in src calls Kick, and the client has no lasting banner (grep for `:Kick(` and `loadFailed` on the client found nothing). For _newerSchema and _lockLost the player is on their real profile, so a whole session of "Saved" disappears on rejoin. For _loadFailed the HUD shows level 1 / $0, which looks like a wipe, and the DAW still says "Saved".

**Fix (verifier):** 1) In DataService, add `function M.Saving(prof) return M.Persistent and not (prof._loadFailed or prof._lockLost or prof._newerSchema) end`. 2) At DAW.lua:179 (and :131 for consistency) send `persistent = ctx.Data.Persistent == true, saving = ctx.Data.Saving(prof)`. 3) DAWClient:476 must change too. If you only flip `persistent` to false, the client shows "Saved for this session (place not published yet)", which is also wrong on a published place. Use `res.saving == false and res.persistent and ("Kept for this session only - progress isn't saving right now" .. xp)`, falling back to the current branches. Optional: on _loadFailed / _newerSchema / _lockLost, set a player attribute (e.g. `p:SetAttribute("NotSaving", reason)`) and have the HUD show a banner that stays on screen. Alternatively, on _loadFailed, call `p:Kick("Your save couldn't load. Rejoin in a minute; nothing was lost.")`.

**Verifier:** Reachable on a live server. _loadFailed needs only a DataStore outage during a join. _newerSchema happens after a publish that bumps SchemaVersion, while old servers are still up. _lockLost needs the forced takeover covered in the second finding. No upstream guard exists: DAW_Save never checks the profile's flags, and the client's only signal is a toast that lasts 2.5 s and can be replaced. The stored save is never corrupted, and the progress lost is inherent to the failure. The defect is the false "Saved" message, which turns an outage into lost trust and a support problem. That fits Medium, not a Blocker.

## A8 — Medium — src/ReplicatedStorage/OK/Config.lua:14 (`LockWaits = { 1, 2, 3, 6 }`); src/ServerScriptService/OK/Services/DataService.lua:204, 209, 222-224 (forced takeover), 172-189 (releaseSave retries), 325-329 (refused save). Line numbers are as read on 2026-11-05.

**Problem:** The takeover window can be shorter than a slow leave save. A player leaves server A, and A's PlayerRemoving starts releaseSave. The player then joins server B. B's load is blocked by A's fresh lock on attempts 1-4 and waits 1+2+3+6 s between them. On the 5th attempt `force = lockTries >= #waits` is true, so B takes the profile as of A's last autosave. A's release can arrive later than that if it is queued behind an in-flight autosave on the same key or behind the per-key write cooldown, if it is retrying errors (1+2+4 s), or if the store is slow or throttled. When it lands, its UpdateAsync sees B's lock (`foreignLock(old.lock)`), sets lost = true, and returns nil. Everything since A's last autosave is dropped (up to AutosaveSeconds = 120 s), and B keeps playing on the older copy. Nothing is corrupted or rolled back, but progress is lost.

**Fix (verifier):** Lengthen the wait before a forced takeover, e.g. `Config.Data.LockWaits = { 1, 2, 3, 6, 8, 10 }` (about 30 s). Optionally lower `Config.AutosaveSeconds` to 60 to halve the worst-case loss. Cost to state: a crashed server never releases its lock, so every rejoin after a crash waits the whole LockWaits before forcing (30 s instead of 12 s), and GetProfile blocks gameplay for that player until then. Callers waiting on the same load stop after 60 s (DataService:265) and get a `detached()` throwaway profile. Keep LockWaits + error retries (1+2+4) + round trips well under 60 s. About 30 s fits; going much past 40 s would start turning slow loads into detached sessions.

**Verifier:** The trace is right: force is set only on the 5th claim, about 12 s plus round trips after B's first attempt, and an unconditional foreign-lock refusal drops A's late release. It is not guarded elsewhere, since the design deliberately prefers losing A's tail to rolling back B. It needs a degraded or throttled store, or an unusually slow release. In a healthy store A releases within about 0-6 s, and rejoin time adds slack before B even starts. The loss is bounded (at most the time since A's last autosave) and the store stays consistent, so this is Medium, not High.

## A9 — Medium — src/ServerScriptService/OK/Services/DataService.lua:357-373 (_Shutdown: shared t0 at :360, first waitIdle at :362, release spawn at :369, second waitIdle at :371); :376-389 (_Autosave ignores `closing`); :528 (BindToClose -> _Shutdown(25)). Line numbers are as read on 2026-11-05.

**Problem:** BindToClose can run out of time before the shutdown releases finish, but only for players who are not already releasing when it fires. _Shutdown sets closing, then waits for inflight == 0 under a 25 s budget measured from one t0. Only then does it spawn release saves for profiles where `_releasing` is false. The second waitIdle reuses the same t0. _Autosave saves players one after another and never checks `closing`. Save decrements inflight (l.335) and returns without yielding, and the loop's next Save increments it again (l.313) before UpdateAsync yields, so waitIdle never sees 0 during a pass. If players are still connected and not releasing when BindToClose fires (a developer shutdown, or an update shutdown that runs BindToClose before kicking players, which is the behaviour soft-shutdown scripts rely on), and that coincides with an autosave pass on a slow store (e.g. 12 dirty players at about 1.5-2 s per UpdateAsync), the first wait uses most of the 25 s. The releases spawned at l.369 then also wait behind the key that autosave just wrote. They are cut off when _Shutdown returns and the server closes. For those players, changes since their last successful save (at most about AutosaveSeconds, usually much less) are lost, and the lock stays fresh, so their next join waits about 12 s and force-takes, the same as after a crash. Players whose PlayerRemoving releaseSave already started are not affected: Save sets `_releasing = true` before it yields (l.312), so their autosave Save returns "releasing" at once and _Shutdown skips them.

**Fix (verifier):** In _Shutdown, set `closing = true`, immediately spawn `releaseSave(p); forget(uid)` for every cached profile with `_releasing` false (Roblox queues same-key requests in call order, so a release issued behind an in-flight autosave lands after it), then call waitIdle(deadline) once. Add `if closing then return 0 end` at the top of _Autosave, and in Save return early (`return false, "closing"`) when `closing and not release`, so the shutdown never waits behind an autosave pass.

**Verifier:** The shared t0 and the non-yielding gap between autosave saves are confirmed from the code. The failure needs players still connected and not yet releasing when BindToClose fires, an autosave pass (or a load stuck in a lock wait) in flight, and a slow store. That combination is uncommon but reachable on a live server. The impact matches a server crash: bounded progress loss plus a 12 s forced takeover on the next join, with no corruption. That justifies Medium, not higher.

## A10 — Medium — src/ReplicatedStorage/OK/Modules/CypherUI.lua:21-23,63-72,153

**Problem:** MiniSubmit is meant to sit over the beat maker's REQUESTS chip. It is placed in OK_Cypher, which uses CoreUISafeInsets, while the chip is in OK_DAW, which uses DeviceSafeInsets. On screen it therefore lands one top-bar height (58 px) lower, at about y 68–112 instead of 10–54. The x position matches.

At 667×375 it covers:
- the bottom of the step ruler
- the top of the KICK row's pads 6–7 and part of pad 5 (14–15 and part of 13 on page 2)
- in KEYS view, part of the piano roll's control bar

OK_Cypher has DisplayOrder 6 and the DAW has 5, so MiniSubmit takes those taps.

What a tap does depends on the phase:
- **Build phase, asks not yet met:** the tap is swallowed and a "Not yet" note appears.
- **Build phase, asks met:** the entry is submitted early and can no longer be changed (reason `submitted`).
- **Listen/vote/reveal phases:** the tap closes the beat maker.

Meanwhile the real REQUESTS chip stays uncovered.

**Fix (verifier):** Place MiniSubmit from the chip's on-screen rect on each 0.2 s refresh:
`mini.Position = UDim2.fromOffset(chip.AbsolutePosition.X - gui.AbsolutePosition.X + chip.AbsoluteSize.X, chip.AbsolutePosition.Y - gui.AbsolutePosition.Y)`, keeping AnchorPoint (1, 0). Alternatively, parent MiniSubmit into OK_DAW.

Do not switch OK_Cypher to DeviceSafeInsets. It must stay on CoreUISafeInsets so the bar lines up with the HUD (CypherUI.lua:23).

Tracking the chip also keeps the button correct after the top-bar and chip/KEYS fixes move the chip.

Assert in t28d that MiniSubmit's AbsolutePosition and AbsoluteSize equal RequestChip's.

**Verifier:** Reachable during any cypher round for a phone player with the compact beat maker open:
- `mini.Visible = compactOpen and phase ~= "idle" and (inRound or phase == "vote")`
- Position `UDim2.new(1, -72, 0, 10)` with AnchorPoint (1, 0) gives x = guiW−196..guiW−72, identical to the chip's 6 + (vp.X−12) − 190.
- The CoreUISafe origin is 58 px below DeviceSafe (the project's own tests: card top 58; WalkInUI.lua:46).
- The compact grid starts at screen y 76 (gridY = headerH + 18 = 70, plus root y 6). With 5 tracks, KICK cells sit at about y 79–127.

Correction to the original claim: it does not submit an *unfinished* entry. BeatBattles.lua:106-123 refuses unmet asks (`missing`) and repeat submits (`submitted`). The harm is an early, irrevocable submit once the asks pass, plus pads made untappable.

This is a UX defect in an optional mode, not data loss or an exploit, so Medium is correct.

## A11 — Medium — src/StarterPlayer/StarterPlayerScripts/OK/DAWClient.client.lua:281-286; src/ReplicatedStorage/OK/Modules/DAWUI.lua:206-216,260-263; src/ReplicatedStorage/OK/Modules/PianoRoll.lua:107,115,138

**Problem:** Tablets get the desktop beat-maker layout, sized for a mouse. Compact mode only switches on when `TouchEnabled and vp.Y < 600`, so every iPad, and Android tablets at 1024×600 and up, gets:
- a 32×32 close button
- 32 px transport buttons
- 34×30 slot buttons and a 30 px header
- a 26 px roll control bar
- piano-roll rows clamped to 18–34 px

On an iPad the roll has about 166–206 px for 11 minor-pentatonic rows. That clamps rows to 18 px, so note cells are about 14 px tall, and placing or removing notes by touch is unreliable. The drum cells stay large (about 50×48), so drums are usable.

**Fix (verifier):** Pass a touch flag (`UIS.TouchEnabled and not UIS.KeyboardEnabled`, or simply TouchEnabled) into the layout. Whenever it is set, regardless of compact:
- use MIN_TOUCH (44) for the close, transport, header and slot heights and the roll's barH/laneH
- floor piano-roll rowH at 44 and let the rows scroll, as compact already does

Avoid the `vp.Y < 900` shortcut. It would force iPads into the paged 8-step full-screen layout and also flip touchscreen laptops.

**Verifier:** Verified the numbers.

At iPad 1024×768:
- H = clamp(floor(768×0.47), 280, 400) = 360
- gridH = 360 − 96 − 24 = 240
- roll avail = 240 − 34 − 30 − 10 = 166
- 166 / 11 rows = 15, clamped to 18, giving cells of 18 − 4 = 14 px

At 1366×1024: avail = 206, so rows are 18 px again.

No test covers touch without compact.

Everything remains reachable; it is only harder to hit. So this is not a Blocker. Medium (fix soon after launch) is right.

## A12 — Medium — src/ReplicatedStorage/OK/Systems/DAW.lua:210 (tryBroadcast 186-196; Flips.Judge at 195) with Systems/Flips.lua:44-46

**Problem:** DAW_Broadcast has no per-player rate limit. Each call runs Flips.Judge, which with a full history is up to 20 airings x (4 reference diffs + 1), about 100 BriefCheck.Diff calls. It runs before the cheap 'inline' refusal in Monitor:Enqueue, so a spamming client pays the full cost on every call.

**Fix (verifier):** In the DAW_Broadcast handler (l.210), add a per-player cooldown in the lastSave/SaveCooldown style (about 1 s; clear it on PlayerRemoving like lastSave) that returns { ok = false, reason = 'cooldown' } before tryBroadcast. In tryBroadcast, check ctx.Monitors:_find(player.UserId) and return 'inline' before Flips.Judge, so a producer already on air or in line never pays for the diff loop. Career_Unlock needs no launch change.

**Verifier:** The DAW half is confirmed. Preconditions: a modified client invoking the remote in a loop while standing at a station (AtStation: in the producer chair or within reach of the PC or a laptop), with any level-1 pattern that passes Validate. My scratch probe (luau CLI, 20 history entries, 4 refs) measured 1.02 ms per call, which matches the claimed 1.06 ms. History holds only the last 20 airings (MonitorService.lua:100-101), and the inner diff runs only for other producers' airings, so the cost starts near 0 on a fresh server and reaches ~1 ms only after ~20 airings. Arithmetic: taking ~50% of the server's Lua time needs ~500 invokes/s from one client, about 100 KB/s upstream. An exploit script can do that, but it is the generic remote-spam class: it causes server-wide lag while the attacker keeps going, with no cheating or save damage. That makes it Medium (fix soon after), not High. I dropped the Career_Unlock half. MarkDirty -> touch() only sets dirty[uid], which the 120 s autosave consumes (DataService.lua:60, 381-387, 529-530), so there is no DataStore write per call. Invalid ids return early, and State for a launch-day account has almost no life rows. Note: DataService.lua's touch() moved from line 58 to 60 between two of my reads, so that file is being edited live (Wave 3 Task 2).

## A13 — Medium — src/ReplicatedStorage/OK/Modules/Nameplate.lua:45-47 (attached per spawn at Systems/Reactions.lua:98-99)

**Problem:** Each spawn connects 4 Player attribute signals whose refresh closure holds the BillboardGui, its labels and the head. They are disconnected only on bb.Destroying, so under legacy character removal every respawn leaves the old character alive and refreshing until the player leaves.

**Fix (verifier):** In Nameplate.Attach, also disconnect conns when this character goes away. For example, connect player.CharacterRemoving and disconnect when the removed character == character (or use character.AncestryChanged with character.Parent == nil), alongside bb.Destroying. Setting Workspace.PlayerCharacterDestroyBehavior = Enabled also fixes it, but check first that the leave save and the BeatBattles rejoin path don't need the old Player or character instances.

**Verifier:** Conditionally real. The leak only happens if Workspace.PlayerCharacterDestroyBehavior is not Enabled, and that can't be checked from the repo. Nothing in src sets it, and the place exports (places/export_*/README.txt) hold only each service's children, so the absent property name means 'unreadable here', not 'at default'. No exploit is needed to reach it: the built-in Roblox reset button respawns the character, and Phone.lua:404 already expects respawns. Under legacy behaviour the old character is parented to nil without Destroy, so bb.Destroying never fires. The closures then keep the old character tree in server memory, and every Level/FireTotal/PlateColor/Year change re-runs refresh on each stale plate (bb.Parent is still the detached head, so the guard passes). The leak is server memory only (detached instances don't replicate), grows with resets, and ends when the player leaves, so Medium is right and it is not a blocker. I cut the side claim that the Gear/WalkIns/Phone/Profiles CharacterAdded connections keep departed Players alive: those closures capture p, not characters, and nothing here shows a retained Player.

## A14 — Medium — src/ReplicatedStorage/OK/Modules/Visitor.lua:306-321 (_pose), 323-326 (_stride), driven every Heartbeat from 252 via _tick (leaving and walking branches)

**Problem:** While a visitor walks in or out, the server rewrites the CFrame of every anchored figure part (8 body + up to 4 signature) on every Heartbeat, and every client receives the replicated writes.

**Fix (verifier):** Smallest fix: in _stride, accumulate dt and call _pose at about 15-20 Hz (every 0.05-0.066 s) instead of every frame, keeping _walk per frame. _pose is also what moves the figure, so 10 Hz would look visibly steppy. Before and after, check Developer Console > Network 'Data Received' on a phone with 3 visitors walking. Later: pose on the clients from a replicated position, heading and phase attribute set at a low rate.

**Verifier:** Mechanism confirmed. The parts are Anchored (newPart l.166), and _tick calls _stride -> _pose every Heartbeat in both the walking and leaving states. Only arrived visitors re-pose at the slower 0.5 s CHECK_EVERY. The figure is up to 12 parts x 60 Hz x MaxWalking 3, so up to ~2,160 CFrame writes/s at peak, if every Heartbeat write is replicated. If the replicator sends only the latest value per network step, the real rate is lower, so this is an upper bound. Walks are short bursts (WalkSpeed 8 studs/s over the corridor-to-hub route, capped by WalkTimeout 40), and visits come every 4-6 min per player, so average traffic is far below the peak. This is a lag and jitter risk on weak phone connections, not a demonstrated failure: measure first, and it is not a blocker. Correction to the fix: welding to the PrimaryPart only works if the non-root parts are unanchored (welds don't move anchored parts), and it loses the limb swing unless the limbs use Motor6Ds.

## Auditor summaries

- This dimension is clean. No test or Studio-only surface can be reached or exploited on a live server, and no paused-walk-in or fake-store behaviour reaches the live game. I found no Blocker, High or Medium findings.  **Checked against source, read-only:** - **Studio hooks.** All eight `_Studio*Hook` BindableFunctions are created only on a Studio server. The three in `Main.server.lua:16-107` (TestHook, CypherHook, MonitorHook) sit under `RunService:IsStudio()`. The five others are made only when both `IsStudio()` and `IsRunning()` are true: Life :271, Unlocks :155, Career :290, WalkIns :884, and Phone :507 through its cached `STUDIO` flag. All live in ServerScriptService, which clients can't see, and a client can't invoke a server BindableFunction anyway. - **Trusted grants.** `GrantXP` and `GrantCred` are called only by `Tour.Advance` (once per profile, guarded by `t.done` and `t.got[id]`) and inside the Studio hooks (Main :22-23, Career :263). No remote path reaches them. - **Other test-only functions.** `_Skip`, `_State`, `_TickerStep`, `_SetStoreForTest` and `_SetConfigForTest` are server-side module functions. No remote calls them. `InteractionService._RunHandler` is only defined under `IsStudio()` (:148). - **WalkInsPaused.** Every read goes through `IsStudio()` first: WalkIns :101/:104, Phone :62, Life :48. A live server never pauses walk-ins, the phone or the Life day loop, even if the attribute is published with the place. No client code reads it. - **RealSaveTrial.**

- Client-to-server trust audit of Prod Life III (read-only; no sync, test, MCP or Studio tools were used). I mapped every remote: those created by build/06_runtime.lua, build/10_daw.lua and build/17_career_remotes.lua, and every OnServerInvoke/OnServerEvent in src. I then checked every handler: ProfileFunction, DAW_Save, DAW_Broadcast, DAW_Stop, Session_Get/Pick/Deliver, Gear_Get/Buy/Equip, Fire_Send, Card_Get, Cypher_Join/Submit/Vote, Career_Get/Unlock, WalkIn_Choose, WalkIn_Deferred, Phone_Open, Phone_Choose and Tour_Skip. The economy side is solid. Three findings remain: one High (any one player can freeze walk-ins and phone pops for the whole server through the cypher) and two Medium (no rate limit on the monitors queue or on Career_Unlock).  Verified clean: - **The server never waits on a client.** There is no InvokeClient or OnClientInvoke anywhere. - **Every handler type-checks its arguments.**   - A pattern must be exactly 128 characters after Upgrade, with a per-track alphabet and a keys lane checked by KeysValid.   - BPM and swing reject NaN and ±inf, and BPM is clamped to 60–200. Slot must be an integer from 1 to 3.   - Ids are either capped at 24 characters (Session_Pick, Career_Unlock) or must match a server table (Gear, kit, voice, cypher letter).   - WalkIn and Phone choice indices must be integers within range, which rejects NaN. flipToken must be a number. Phone_Open and WalkIn_Deferred tokens must be strings. - **Players can only act on their own cards.** Walk

- No Blockers in the save dimension, and no path writes a blank profile over real data. When every load attempt errors, the profile is flagged _loadFailed (DataService.lua:231-234). After that, both Save (l.308) and releaseSave (l.178/184) refuse to write it. The session lock, the per-load writer token and the stored-v check (l.326-329) also stop a stale or queued server write from overwriting a newer save. I read DataService.lua in full and every MarkDirty/GetProfile caller (Contracts, Dailies, DAW, Reactions, Flips, Funnel, Tour, Gear, Career, Life, WalkIns, Phone, BeatBattles, Profiles, Main hooks).  What I checked and found clean: - **Growth (4 MB limit):** every list or map stays bounded:   - credits capped at 50 (Contracts:18/160) and plaques at 52 (Dailies:70).   - life.story 100 and disco 200 (Config:224, LifeRules.Push).   - DAW keeps 3 slots under string keys, and xpLog.paid is written only when BeatSave paid (dailyMax 5) and resets daily.   - fireLog resets daily, daily.done is pruned to today, and sessions.done uses static brief ids.   - walkins seen/last/caps/queue are keyed by deck ids or repaired in state().   - funnel and tour use fixed step ids, gear and gates are validated against Config.   - A full profile is about 30 KB. - **Wave 3 `rel` and hints:** they are only read in WalkInRules so far. Check them again when Task 2 lands. I saw no half-edited files: WalkIns/Phone were last modified Oct 30 and DataService Nov 3. - **Values JSON-safe:** dictionary keys ar

- Phone fitness and moderation/compliance audit, read-only. I found 5 issues: 3 High and 2 Medium. Four are about the beat maker on touch devices. The fifth is the live parody roster.  Phone. The card UIs avoid the Roblox top bar correctly: HUD/OK_UI, the walk-in and phone cards, the cypher bar and the panel all use CoreUISafeInsets, and tests cover them at 667x375 minus the inset. The beat maker (OK_DAW) is the exception. It uses DeviceSafeInsets, so on a phone its button header sits in the top-bar strip, and nothing in src reads GuiService.TopbarInset. - Header under Roblox's own buttons (High). Cause: DeviceSafeInsets plus no TopbarInset check. - Header collides with the game's own REQUESTS chip (High). Plain arithmetic, so certain: it happens on any screen narrower than about 706 px, including the 667x375 size the tests use. - Cypher MiniSubmit lands over the beat grid (Medium). Its x lines up with the REQUESTS chip but its y does not. - Tablets get desktop-sized controls under 44 px (Medium). Clean on phones: no hover-only interactions. Every keyboard or gamepad binding (Space/K/Backspace, Backspace for the panel) also has an on-screen button. All 12 world prompts plus the "View card" prompt are default style, so they can be tapped.  Moderation. There is no TextBox anywhere, so no player-typed text and nothing that needs TextService. Text shown to other players only uses DisplayName, which Roblox already moderates (monitors, "prod." credits, ticker, FIRE toast, nameplates)

- Live-server runtime stability audit (read-only, no Studio/MCP/sync). I read Main, SystemLoader, DataService, InteractionService, MonitorService, LightingService, every enabled system (WalkIns, Phone, BeatBattles, Career, Life, Contracts, Dailies, DAW, Flips, Funnel, Gear, Profiles, Reactions, Stations, Tour, Unlocks), Visitor, Nameplate, Fits, WalkInRules, BriefCheck, DailyRequests, DAWEngine and the client loops (ClientMain, DAWClient, GatesClient, and the Heartbeat handlers in PhoneUI, WalkInUI, FireButton and CypherUI).  What I checked and found clean: - **Per-player cleanup:** every per-player table is cleared on PlayerRemoving (lastUse, lastSave, lastDeliver, equipTokens, built, rosters/sentLog, WalkIns ready/remaining/pending/rush/heals/forced/aired, Phone pending/ready/remaining/quiet, Monitors:Cancel). - **Loops:** every server loop yields (0.25 s, 1 s, 8 s, 15 s, 60 s, 120 s), and the WalkIns, Phone and Unlocks loops pcall each step. - **Players leaving mid-action:** handled with Parent checks, detached profiles and the left_server path. - **Join before the profile loads:** systems block in GetProfile, which is single-flight with timeouts. Client HUD reads have defaults. StreamingEnabled is off (06_runtime). - **Fresh and large profiles:** a fresh profile migrates to v5. Growth is capped: credits 50, plaques 52, story 100, disco 200, and daily logs reset. - **Instances and sounds:** visitors self-destroy within WalkTimeout, tags are destroyed after TagSeconds, server

