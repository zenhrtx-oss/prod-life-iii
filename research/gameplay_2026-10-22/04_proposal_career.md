## 1. Pitch
You're the new kid at an underground studio. Fictional artists send session requests ("NOVA KAY needs a 145 BPM bounce, kick on the one"). You build the beat at the studio PC while a checklist ticks green, then deliver it for Cred, XP and a credit: "Night Shift · NOVA KAY · prod. you". Cred buys rack gear that unlocks sounds. Your title (Intern up to Studio Legend) floats overhead. OK's wall shows a real career; yours starts empty. For 10-16 year olds that's the tycoon pull: clear goals, a win every few minutes and a visible title. But the grind is beat-making, so getting better at the game means getting better at beats. It works solo, which matters in servers with only 1-3 players.

## 2. First session story
- **0:00** Spawn: INTERN · 0 Cred. The tour card says "1 session request · go to the studio PC".
- **1:00** Sit at the PC. A blank session opens under a brief strip: NOVA KAY · 140-150 BPM · kick on step 1 · snare or clap on 2 and 4.
- **1:00-3:00** Each ask ticks green as you tap. You can still preview the locked 808 row: "808 Module at the gear rack".
- **3:00** DELIVER. A 4-bar listen-back plays while NOVA KAY stands in the booth (only you see her). ★★ "that bounce is hard" · +40 Cred · +30 XP (starting values) · credit added.
- **4:00** Buy the 808 Module at the rack, and its unit lights up.
- **5:00-8:00** DUSKBOY's request (808 on 4+ steps, 2+ notes) earns ★★★. Level 2: "BEATMAKER · new artist unlocked".
- **8:00-10:00** ON MONITORS. Listeners tap FIRE: you get Cred and they get a little XP.
- **10:00-15:00** The daily board shows 3 requests, 1 done, streak 1. Roll FX costs 120 Cred, so it becomes tomorrow's goal.

## 3. Return hooks
- **Tomorrow:** three new requests picked by the UTC date (the same in every server), a streak bonus, and the gear you were saving for.
- **This week:** a harder Weekly Single brief. 3 stars earns a plaque on your profile.
- **Ladder:** each of the 10 levels gets a rank and a new artist, so levels 5-10 finally have content.
- **Cheap weekly updates:** adding an artist only takes a table entry in Data/Artists.lua.

## 4. Milestone A (next build, 1-2 nights)
No profile has been saved yet (PlaceId 0), so schema v2, the save lock and Cred can all go in before the first publish with nothing to migrate. New remotes go in build/06_runtime.lua or build/10_daw.lua.

**A1. Career save layer.** DataService schema v2 adds:
- a session lock in UpdateAsync;
- `AddCred(p, n, source)`, which reuses the AddXP gate;
- a Cred attribute and a HUD counter;
- `Config.Ranks`, rank names over the unchanged `Config.Levels`.

Done when: fake-store tests show a second server can't overwrite a locked profile, AddCred honours its caps, and a level-up shows the rank.

**A2. Session requests.** New `Modules/BriefCheck.lua` (pure: beat + brief → met, stars, failed asks), `Data/Artists.lua` (4 fictional artists, about 15 briefs) and `Systems/Contracts.lua`.
- A delivery runs DAW.Validate, then BriefCheck, then CellsDiffer ≥ 8 against both DefaultPattern and your last delivery.
- A new `Contract` entry in Config.XP.Sources has a dailyMax. Starter requests pay out only once ever.
- Tour step 3 becomes "deliver a request". That closes the exploit where saving an untouched beat completed the step.

Done when: 20 fixture beats give the expected results, a repeat delivery pays 0, and the untouched default is refused.

**A3. Brief strip.** DAWUI gets:
- live ticks (the same BriefCheck runs on the client);
- a blank "New session";
- DELIVER, which plays a listen-back through DAWEngine, then shows a reaction card and a client-only NPC rig built from parts.

Locked rows can be previewed but not saved.

Done when: tapping pads flips the ticks, every control is ≥44 px at 844×390, and the server refuses a locked row.

**A4. Gear rack** (Tycoon stub).
- The rack registers Kind "Gear" through InteractionService.Register.
- PanelUI tabs become data-driven, and a Gear tab is added.
- DAW.Validate gates on `prof.gear` instead of level.
- When someone sits at the desk, the rack units they own glow (Neon material, no lights).

Done when: the server refuses a purchase you can't afford, owning the 808 Module makes the server accept bass, the unlock tests are rewritten for gear and pass, and the light count stays at 21.

**A5. Dailies and streak.** New `Systems/Dailies.lua` runs 3 briefs per UTC day, a weekly single and the streak. Its card reuses the Tour engine and TourUI. It also adds AnalyticsService funnel and economy events (exact calls still to verify).

Done when: with `DataService._now` mocked over 3 days, the briefs rotate, the streak grows and resets after a missed day, and each day pays once.

**A6. FIRE and rank nameplates.**
- Listeners in range of the NowPlaying beat can FIRE after loop 1.
- The author's Cred from fires has a daily cap, plus a cap of 3 per listener per day.
- Listeners earn capped `Listen` XP.
- Firing your own beat is refused.
- A BillboardGui shows the rank from the Level attribute and never shows player-typed text.

Done when: in a two-player test the pair's 4th fire of the day pays 0, a self-fire is refused, and the nameplate updates on level-up.

## 5. Milestone B (after A)
**B1. MonitorService queue.** The monitors' token and cooldowns move out of DAW into `Services/MonitorService` (acquire, release, queue of 4).
Done when: three players' beats all play in order and the DAW tests still pass.

**B2. Kits as gear.** Slots get a `kit` field (the beat format is unchanged), NowPlaying gets a Kit attribute, and DAWEngine gets a sample folder per kit. Beat slots 4-6 also become gear.
Done when: t14 passes for every kit sample and a remote listener hears the author's kit.

**B3. Public producer card** (Profiles stub). A new remote returns only rank, credits, plaques and fires. ProfileFunction still returns only your own profile.
Done when: another player's card shows only public fields.

**B4. Your colour on air.** Neon Finish gear recolours the existing neon strips through LightingService while your beat plays.
Done when: the colour is right during and after the beat, and the light count is unchanged.

**B5. Artist chains.** Artists for levels 5-10, each with 3-5 linked briefs ending in a plaque.
Done when: every level has an artist, and a generated beat satisfies every brief.

Later: duo sessions, a 2-bar beat format (v3), a cross-server board.

## 6. What it cuts or postpones from the current ROADMAP Milestone 4
- **Fire reactions:** kept (A6). A graded brief can't judge taste, but players can.
- **Nameplates:** kept (A6), showing rank.
- **Neon tube signs:** postponed. B4 gives neon a gameplay purpose first.
- **Readable credits wall:** postponed until the titles decision. Players get their own credits list.
- **Lived-in furniture:** postponed, apart from the rack units.
- **Launch kit:** drop-off tracking is kept (A5). The trailer and stills wait until the loop is worth filming, and thumbnails are uploads that need your approval.

Honest call: unlocking new rooms tycoon-style doesn't work when 12 players share one studio. The gear rack is the tycoon, and new rooms wait.

## 7. Risks and constraint check
- **No Robux:** Cred can only be earned. There are no passes or products.
- **Licensed audio:** A adds no sounds. B2 kits are APM/PSE only, and t14 checks them. No backing tracks. Credits are text only and beats only play inside one server, so nothing works like a "music library".
- **OK's IP:** the artists are fictional, and OK's name, sounds and logo aren't used.
- **Images:** none. Everything is parts and text; artist portraits would need your approval.
- **Free models:** none. All code is in src.
- **Performance:** about 80 parts, 0 new lights (21 of 24), nameplate MaxDistance 40.
- **Explicit titles:** NPC song titles are clean, and the wall is untouched.
- **Modular:** new modules plug into the existing stubs and InteractionService.Register.

Top risks:
1. **Fun:** briefs can feel like homework, and players will hunt for the minimum beat that passes. Keep 2-3 asks per brief, give extra stars for optional asks, and judge it in the 10-minute play test.
2. **Technical:** the save lock can only be tested with fake stores until the place is published, and a bug could lose currency. Publish privately and test with two servers.
3. **Moderation:** fictional names could match real artists, and the explicit titles on the wall still block a Public release.

## 8. Decisions the user must make before or during it
1. Publish privately, turn on API access and set MaxPlayers ≤12, once A1 is done. Until then nothing is saved between sessions.
2. Approve the 4 artist names and about 15 song titles.
3. Should the 808, rolls and swing move from levels to gear? I recommend it, so new players have the 808 by minute 5.
4. Choose names for the currency and the ranks.
5. For B2, listen to the candidate kit samples.
6. Still waiting on you:
   - Fan-made or official. A request from OK himself would need his team's written approval.
   - The explicit titles.
   - The audio question. Nothing in this plan needs music beds.