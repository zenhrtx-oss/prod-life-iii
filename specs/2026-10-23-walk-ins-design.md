# Walk-ins: BitLife-style career events for OK Studio

> Design written 2026-10-23 from the user's answers that night. Mockup: https://claude.ai/artifact/KNxV5DWJxZkoeGrSBXQre5 (six boards at 844×390; the user said "right idea, let's go with it for now, we will probably improve the design soon"). Builds on the live code in `src/` (Milestones 1–7, see README.md); nothing here changes approval status, publishes, or saves the place.
>
> Marks: **(user)** = decided by the user in the conversation. **(call)** = my call; the user can override. **(builder)** = left to whoever builds it.

## 1. Intent

Right now OK Studio has one loop: a fictional artist sends a brief, you build the beat, you deliver it, you earn XP and Cred, Cred buys gear. The user wants a second layer on top, in the spirit of BitLife: life happens *to* you in the studio. "Lil Nav X has entered the room, he wants a placement." You make a choice, you don't know how it lands, your career stats move, and some of those choices come back around later. The payoff is a career you can feel: money, aura, followers, placements, hits, sponsors, and things in the studio that stay locked until your career says otherwise.

The beat maker stays the spine. Walk-ins add drama, stakes and a reason to come back; they must never become a better way to earn than making beats.

## 2. Goals, non-goals, anti-goals

**Goals**
- A few times a day, a parody artist walks into the studio and up to you. Everyone sees him arrive. Only you get the card. **(user)**
- Cards are pure BitLife: 2–4 choices, tap one, stats change at once, no beat required. **(user)**
- Outcomes are hidden gambles; your Aura and Followers tilt the odds. **(user)**
- Six career stats: Money ($), Aura, Followers, Placements, Hits, Sponsors. Money is the only one you spend; the others are milestones. **(user)**
- Milestones + Money gate unlocks: the Studio Two door, fits built from parts, stat-gated gear, and sponsor logos on the lounge TV. **(user)**
- Follow-ups: a choice can plant a later event, which resolves the old choice (Hit or flop, refund demand, sponsor drop) and then offers a new, bigger choice. **(user)**
- Wins and losses both show to the room (a tag floats over your head). **(user)**

**Non-goals (v1)**
- No new audio, images, decals, or Robux products.
- No player-typed text anywhere (all lines are fixed strings in a data file).
- No charts or leaderboards across servers.
- No changes to how beats are made, graded or aired.
- No personal studios; "Studio Two" is the shared room already imported, nothing more.

**Anti-goals (what would make this a failure even if it works)**
- Tapping cards out-earns making beats. At the daily cap, walk-ins supply at most half of a day's Money and none of the XP that levels you.
- The room fills with NPCs or the part budget gate fails because of them.
- A real artist's name or likeness ends up in the game, or a line that breaks Roblox's rules (drugs, alcohol, sex, weapons, gambling with real money). The account already has one strike.
- The card interrupts someone mid-beat.

## 3. Constraints (from the project, not negotiable here)

- `src/` is the source of truth; `tools/sync.py` writes it into the open place; `tools/test.py` must pass (edit checks + play tests, strict). New checks follow the `build/tNN_check.lua` / `tNN_play_*.lua` pattern with the next free numbers at build time (t30 is taken by the piano-roll session).
- Phone first: every tappable control is at least 44 px at 844×390 and 667×375, and works by gamepad.
- The user's standing limits: never save or publish the place, never upload images or audio, never run free-model scripts, no Robux sales, no OK name/sounds/logo, audio only from APMOfficial / ProSoundEffects (none needed here).
- The Studio place is shared with another Claude session (piano roll). Take turns in Studio; message before syncing or playing. Note: Env_studio_two + OK_Passage_StudioTwo brought the place to 32 lights against the QA cap of 24, so `tools/test.py` fails at the gate today. **(user, 2026-10-23)** Raise the cap to 36 in `build/09_qa.lua` and `t03/t04/t05`; walk-ins add zero lights. The build plan starts with that so the suite is green before anything else lands.
- Systems are ModuleScripts in `ReplicatedStorage.OK.Systems` with `{ Enabled, Version, Init(ctx) }`, started by `Services/SystemLoader`; `ctx = { Data, Lighting, Interaction, Monitors }`. Rewards go through `DataService`'s gate (`Config.XP.Sources`, `Config.Cred.Sources`): an unknown source pays 0 and reports `[OK][ERR]`.
- Saves: `DataService` profile with `SchemaVersion` + `migrate`; fields starting with `_` are never stored; Studio sessions never touch the live DataStore unless `Config.Data.UseStoreInStudio`.
- Studio-only test hooks live in `ServerScriptService.OK._StudioTestHook` and never exist outside Studio.

## 4. The experience

### 4.1 He walks in
1. A visitor spawns at the corridor mouth (the real floor plan: Corridor x 0–12 / z 0–10 with the spawn at (6, 0.5, 5); the Lounge x 12–44 behind the entry opening at x = 12, z 3–7; Control Room x 44–80 behind the sliding door at x ≈ 43, z −3–3; Booth x 80–94). The mockup drew the door on the right; the build uses the real plan. **(call)**
2. He walks along the corridor arrows, through the entry, into whichever room the target producer is in, and stops about 4 studs from them, facing them. Anchored parts tweened along fixed waypoints, re-aimed at each waypoint if the player moved; no Humanoid, no PathfindingService. **(call)** If the player leaves the studio rooms or disconnects, the visitor turns around and leaves.
3. Overhead he carries his name (pink plate) and a speech bubble with his line. Both are server-built BillboardGuis, so the whole server sees them. **(user)**
4. The card opens for the target producer when he arrives. If the beat maker is open, the card does not open: a chip in the beat maker header ("LIL NAV X is waiting") lets the producer open it, and it opens by itself when the beat maker closes. Unanswered for 5 minutes, he leaves; no stats change. **(call)** A visit counts toward the 8 a day as soon as he arrives, even if the card is then ignored, so ignoring cards can't be used to fish for better ones (changed while planning, 2026-10-23). A visitor who never arrives (you left the hub or the game) counts nothing.

### 4.2 The card
- Header: his blocky portrait (parts, no image), name, a tag line ("POP-RAP · WANTS A PLACEMENT"), and "N OF 8 TODAY".
- His line, in his voice.
- 2–4 choice buttons, 44 px tall, plain text with the money shown when a choice costs or pays a fixed amount ("Full rate or nothing. $400."). A choice you cannot afford is greyed with "can't afford".
- Footer: "Your Aura and Followers tilt the odds. You never see them." and WALK AWAY (no stats change, counts as a visit). **(call)**

### 4.3 The outcome
- The server rolls, applies the effects, and sends the result. A small result card sits low so the room stays visible **(user)**: a headline (PLACEMENT / HE WALKED / SPONSORED / DRAGGED…), a one-liner, stat chips (+$400, +40 AURA, +1,200 FOLLOWERS, +1 PLACEMENT), a note when a follow-up was planted ("The single drops in a few visits. Could chart. Could flop."), one button.
- Walk-ins pay **no XP**: levels, artists and rack tiers stay earned by making beats, so there is no `Config.XP.Sources.WalkIn` and no XP chip on the result card. **(call)**
- Public, for the whole room **(user)**: the visitor's bubble changes to his reaction line, a tag floats over the producer's head for ~3 s ("+1 PLACEMENT" in gold, "−60 AURA" in blue), and the visitor walks out. The on-air neon strip flashes gold on a placement and cold blue on a loss if that is cheap to add; otherwise cut. **(call)**

### 4.4 Follow-ups
- Some outcomes plant a follow-up: `{ id, at = visitCount + 2..4, ctx }`. It fires as that numbered walk-in (across days if needed) and takes priority over random cards. **(call)**
- A follow-up card first resolves the old thread on its own (the single charted → **HIT**, +1 Hit, royalties, followers, aura; or it flopped → he wants a refund), then offers a new choice with higher stakes (exclusive album deal vs. points on the single). **(user)** Follow-ups can chain once more (an album deal has its own follow-up) and then stop. **(call)**
- Other threads: a sponsor drops you if Aura falls below their floor at the next visit; a producer you shaded steals a placement; a fan you were kind to turns out to run a page and posts your beat.

### 4.5 Pace
- First walk-in 60–120 s after you enter the studio rooms, then one every 4–6 minutes of presence, capped at **8 per UTC day** (`Config.WalkIns.DailyMax`), never during a cypher round, never while a card or result is open. **(user: a few times a day; numbers are my call)**
- Server-wide at most 3 visitors walking at once; others wait in a queue. **(call)**
- Each artist waits at least 3 of your visits before returning unless a follow-up brings him. **(call)**
- Walk-ins happen in the hub rooms only (Corridor, Lounge, Control Room, Booth). In Studio Two the presence timer pauses, visitors never walk the passage or the stairs, a visit that comes due waits until you are back in the hub, and sponsors show on the lounge TV only. Studio Two gets its own visitors when it has stations. **(call)**

### 4.6 Stats
| Stat | Starts | Range | Where it comes from | Shown |
|---|---|---|---|---|
| Money ($) | today's Cred (same field, same gate) | ≥ 0 | sessions, dailies, cyphers, FIRE, flips, **walk-ins** | HUD chip "$320", Gear prices, Career tab |
| Aura | 0 | any integer, **negative allowed** **(call)** | walk-ins, 3-star deliveries, cypher wins, weekly plaque | HUD pill, Career tab, producer card |
| Followers | 0 | ≥ 0 | walk-ins, deliveries, FIRE received, flips of your beat | HUD pill, Career tab, producer card |
| Placements | 0 | ≥ 0 | walk-ins only | Career tab, producer card |
| Hits | 0 | ≥ 0 | follow-ups only (a Placement that charted) **(call)** | Career tab, producer card |
| Sponsors | 0 | ≥ 0 | sponsor walk-ins; can be lost | Career tab, producer card, lounge TV |

Everything the beat loop already pays keeps paying; it also feeds the new stats so making beats improves your odds **(call)**: 2-star delivery +40 Followers / +5 Aura, 3-star +120 Followers / +10 Aura; each FIRE received +10 Followers; cypher win +25 Aura; weekly plaque +40 Aura / +300 Followers. All through a gate with daily caps, like Cred.

"Cred" becomes "Money" everywhere a player can read it (HUD, Gear tab, request results, cypher UI, tour copy, banners): the chip reads "$320", prices read "$25". Internal names (`prof.cred`, `DataService.AddCred`, `Config.Cred`) stay. **(user: "Cred shows up on screen as $")** **Rescale ×10 (user, 2026-10-23):** every Money constant is multiplied by 10 at build time so the numbers read like money: session rewards in `Data/Artists.lua` (25–65 → 250–650), `Config.Cred.Sources` amounts and caps, `Config.Daily` / `Config.Weekly` / `Config.Cypher` Cred, Gear prices (Roll FX $250 … Legend nameplate $4,000), and a migrate step that multiplies a stored `prof.cred` by 10 once (no live profiles exist yet; the step still runs). Balance is unchanged; the tests that pin these numbers (`t21_check` pacing among them) are updated in the same pass as the Cred → $ rename.

### 4.7 Odds
Each choice lists outcomes with weights. The "good" outcome's chance `p` is shifted by career: `+1 point per 20 Aura` (clamped ±15) and `+1 point per 1,000 Followers` (clamped +10), then clamped to 10–90 %. Negative Aura hurts. Rolls happen on the server with an injectable RNG so tests are deterministic. **(call)**

### 4.8 Economy targets
Tuned by a pacing simulation (like Gear's), run as an edit check **(call)**:
- **The share rule is authoritative:** at the daily cap, walk-ins supply at most 50 % (target 35–50 %) of a day's Money and all Placements/Hits/Sponsors. The per-card figures below are targets the simulation confirms or the builder trims; card texts that quote money are written only after the numbers pass. **(call)**
- The simulated player: first-time session requests while they last (the 21 in `Data/Artists.lua`, 3 a day), then the steady state of 3 dailies + the weekly + a cypher win every other day + some FIRE; roughly $700–1,000 a day from beats at the ×10 scale.
- A typical card moves Money by −$300…+$400, and many cards move only Aura or Followers; rare outcomes to +$1,500; follow-up Hit royalties +$1,000…$2,000 (a few a week at most). A card never takes Money below 0 (a loss takes what you have).
- Studio Two ($5,000) unlocks between day 3 and day 7 (median day 5); the Legend nameplate (needs a Hit) not before week 3, as `t21_check` already asserts. Gear prices only scale ×10; they do not otherwise move.

### 4.9 Unlocks (`Config.Career.Gates`)
| Id | Kind | Needs | Costs | What happens |
|---|---|---|---|---|
| `studio_two` | room | 1 Placement, 300 Aura | $5,000 | A door into the Studio Two passage opens for you (interaction kind `StudioTwoDoor`: server checks the gate, the client slides the door and drops collision for that player only; locked players get "NEEDS 1 PLACEMENT · 300 AURA · $5,000"). **(user picked, knowing the room is open to everyone today and becomes locked until earned; numbers are my call)** |
| `fit_cuban` | fit (gear kind "fit") | 2 Placements, 5K Followers | $3,500 | A chain of parts welded to the torso, server-built, re-attached on respawn, everyone sees it. |
| `fit_snapback` | fit | 1 Sponsor | $1,500 | A cap built from parts. |
| `fit_shades` | fit | 500 Aura | $2,000 | Shades built from parts. |
| `kit_iron` (existing) | gear | +1 Placement | $2,000 (today's price ×10) | Existing rack items gain an optional `needs` table. |
| `plate_legend` (existing) | gear | +1 Hit, 20K Followers, 1,000 Aura | $4,000 (today's price ×10) | |
| `sponsor_tv` | toggle | 1 Sponsor | free | Your sponsor's name cycles on the lounge TV ticker while you're in the room (shared TV: 8 s per present sponsored producer). The lounge banner is a cut line. **(call)** |

**Where the door lives (call):** there is no door today; `OK_Passage_StudioTwo` is an open corridor (Floor, walls, ceiling, skirting, three lamps, a sign) and `ok_assets/scripts/connect_studio_two.py` destroys and rebuilds that whole model on every run, so nothing of ours may live inside it, nor inside `OKStudio`. The door part and its prompt go in a new model `Workspace.OK_Gates`, placed in the hub-side doorway cut in `Wall_Corr_N` (x 4–8, z ≈ 10), built by their own idempotent build script. `build/09_qa.lua`'s tagged-interactable count goes up by one. Known pre-existing issue, not ours to fix: re-running `build/02_shell.lua` restores the solid corridor wall over the doorway.

Fits are regular gear with `kind = "fit"` and `needs`, so the rack, BUY/EQUIP and the Gear tab already handle them; `needs` applies to any gear item. The Career tab lists every gate with ✓/✗ chips per requirement and an UNLOCK button when all pass.

### 4.10 Roster and content
Visitors **(user approved the names; parody of real artists is the user's call, with the Charti rename to avoid an adult brand name)**:
LIL NAV X · DOJA BAT · ICE SPIKE · PLAYDOH CHARTI · TRAVIS SCOOT · KENDRICK LLAMA · TAYLOR DRIFT · DRIZZLE · BILLIE EYELASH.

Each artist: id, display name, style tag, body colour, a signature built from 1–3 parts (pink cowboy hat, bat ears, spiky hair, blob hat, helmet, llama ears, sparkle cape, owl hoodie, neon-green roots) **(builder designs; no images)**, 3 cards, 1–2 follow-ups, reaction lines for win/loss.

Non-artist visitors **(call)**: sponsor reps ("a suit from RED BULB"), a blogger, a superfan, a rival producer, a manager.

Sponsors are sound-alike brands, like the artists **(user: "make the sponsors sound like actual sponsors too, differently spelled"; the picks are my call)**: RED BULB (energy drink), NYKE (sneakers), BEETS BY DRAY (headphones), SPOTIFLY (streaming), ROLEKS (watches), PRYME (hydration). The same `Roster` switch swaps them for the fictional fallback set NITE OWL ENERGY, KICKFLIP FOOTWEAR, LOUD HEADPHONES, GLOW GUM, STACKS BANK, DRIP WATER. No real logo, slogan or trade dress is used: a sponsor is a name in the game's own type on the lounge TV. The builder web-checks every name for a same-named real company or artist before it goes in, as was done for the artist roster.

Volume v1: ~27 artist cards + ~9 follow-ups + ~6 sponsor cards + ~4 drama cards ≈ 45. Lines in the user's voice (lowercase, slang), clean under Roblox rules.

**Moderation risk and switch (call):** parody names that point at real people carry a moderation risk under Roblox's real-people / impersonation rules, and this account already has a strike. The roster is data: `Config.WalkIns.Roster = "parody" | "fiction"` picks between the approved parody set and a fictional fallback set the builder drafts for the user to approve. One line flips it. No real name, lyric, album title or likeness is used anywhere; "signatures" are abstract shapes.

## 5. Data model

Bump `DataService.SchemaVersion` and add a migrate step. **(builder)**
```
prof.career  = { aura = 0, followers = 0, placements = 0, hits = 0, sponsors = 0,
                 sponsor = nil|brandId, careerLog = {}, gates = { [gateId] = true } }
prof.walkins = { day = yyyymmdd, today = 0, count = 0,
                 queue = { { id = followupId, at = count + n, ctx = {...} }, ... },
                 seen = { [cardId] = times }, cooldown = { [artistId] = countWhenLastSeen } }
prof.cred stays the Money balance.
```
Player attributes for the client (like `Cred`, `Gear`): `Aura`, `Followers`, `Placements`, `Hits`, `Sponsors`, `Sponsor`.

Public card (`Profiles.PUBLIC`) gains `aura, followers, placements, hits, sponsors`. **(call)**

## 6. Code shape (builder owns the details)

New:
- `Data/WalkIns.lua`: artists, visitors, sponsors, cards, follow-ups, both rosters. Pure data + an index.
- `Systems/Career.lua`: stats with a gated `Career.Add(player, stat, n, source)` (`Config.Career.Sources`, daily caps, log), gates (`Config.Career.Gates`, `Career.Check`, `Career.Unlock` spends Money once), feeds from Contracts.Delivered / Reactions / BeatBattles / Dailies events, the `Career_Get` and `Career_Unlock` remotes, attributes, the Studio Two door kind, fits attach on spawn, sponsor TV ticker.
- `Systems/WalkIns.lua`: scheduler (presence timer, daily cap, queue, cooldowns, concurrency), `Resolve(prof, card, choice, rng)` pure, remotes `WalkIn_Card`, `WalkIn_Choose`, `WalkIn_Result`, public tags.
- `Modules/Visitor.lua` (server): builds the parts figure + signature + name + bubble under `Workspace.OK_Visitors` (outside `OKStudio`, `Archivable = false`), walks the waypoints, says a line, leaves, destroys itself.
- `Modules/WalkInUI.lua` (client): card, result card, waiting chip in the beat maker header, phone layout; attributes for tests (`Open`, `Card`, `Choices`, `Result`, `Command`).
- Career tab in `PanelUI.Tabs` (stat tiles + gates list); HUD pills for Aura and Followers.

Touched: `Config.lua` (`Config.WalkIns`, `Config.Career`, `Config.Cred.Sources.WalkIn`, `needs` on Gear items, three fits), `DataService` (schema, migrate), `HUD`/`PanelUI`/`RequestUI`/`CypherUI`/`TourUI`/`Interactions` copy (Cred → $), `Gear.lua` (`needs`, kind "fit"), `Profiles.lua` (public fields), `Main.server.lua` (test hooks: `SpawnWalkIn`, `ChooseAs`, `SetCareer`, `ResetWalkIns`, `AdvanceVisits`), `build/07_interactables.lua` or a new build script for the Studio Two door part and prompt, `build/09_qa.lua` if the budget gate needs to ignore `OK_Visitors`.

Visuals reuse `Modules/BoothArtist`'s part recipe and `Modules/Nameplate`'s billboard style. Theme stays `UITheme` (gold for placements/hits, accent2 blue for losses, ledOn green for money, a purple for Aura, accent2 for Followers).

## 7. Done when (the test list the plan expands)

Edit checks (pure):
- `Resolve` with a seeded rng applies the listed effects; `p` clamps to 10–90; negative Aura lowers `p`; Money never goes below 0; an unaffordable choice is refused; WALK AWAY changes nothing but counts a visit.
- Daily cap: the 9th walk-in of a UTC day does not schedule; a new day resets `today`.
- A planted follow-up fires at visit `count + 2..4`, before any random card, and survives a save/load round trip through `migrate`.
- Gates: `Career.Check` reports each requirement; `Unlock` spends once and refuses twice; Gear `needs` refuses BUY and the Gear tab shows the need; fits are kind "fit".
- Feeds: a 3-star delivery adds Followers/Aura through the gate; the daily cap holds; an unknown source pays 0.
- Pacing simulation (§4.8) passes its three targets.
- No user-facing "Cred"/"CRED" string remains in `src/` UI text.
- Roster switch: both rosters load, every card references an existing visitor, every follow-up id exists, no line contains a word on the builder's Roblox blocklist.

Play tests (Studio, fake players where possible):
- A spawned visitor appears under `OK_Visitors`, reaches within 5 studs of the target within 40 s, shows name + bubble to a second client, and is destroyed after the result; 4 requested at once → 3 walking, 1 queued; the part budget gate still passes.
- Card buttons are ≥ 44 px at 844×390 and 667×375; the card does not open while the beat maker is open, the chip does; the result card leaves the room visible.
- The overhead tag appears over the producer for a second client on a win and on a loss.
- Studio Two door: locked player refused with the needs line; unlocked player's door opens on their client only.
- A fit shows on a second client and comes back after respawn.
- Sponsor name shows on the lounge TV for a sponsored producer in the room.

Then the user's own 10-minute play test, solo and with two players.

## 8. Left to the builder
- Exact waypoints, walk speed, bubble sizes, signature shapes, portrait recipe.
- The 45 card texts and their weights (drafted in the user's voice; names and brands web-checked; user approves the roster, sponsor names and any line they want changed).
- The fictional fallback roster.
- Phone layout details below 844 px, gamepad focus order.
- Whether the neon flash is cheap enough to keep.
- Test numbering and the order of the build steps (the plan).

## 9. Builder check (2026-10-23)

A fresh agent read this document against `src/`, `build/`, `tools/` and the Studio Two import notes, as the engineer who would plan it. It found the system contract, reward gate, migrate path, BindableEvents, PanelUI tabs, test hooks, BoothArtist recipe and Nameplate style all as described, and raised five questions. Resolutions:

1. **The Studio Two door does not exist; where does it go, and is locking an open room acceptable?** Door in a new `Workspace.OK_Gates` model at the hub doorway (§4.9, call). Locking the room is the user's decision, made when they picked the unlock.
2. **The money numbers could not all hold at once.** The ≤ 50 % share rule is authoritative, per-card figures are simulation targets, the simulated player runs out of first-time requests, gear prices only scale (§4.8, call). Scale ×10 is the user's decision (§4.6).
3. **Does Studio Two count as "the studio rooms"?** No, in v1: hub only; the timer pauses in Studio Two (§4.5, call).
4. **The light cap blocks step one.** Raise to 36 (§3, user).
5. **Do walk-ins pay XP?** No (§4.3, call).

Everything else the reviewer said it would decide itself (R6/R15 torso naming for fits, pausing the 5-minute visitor timer while the beat maker is open, no cards during the tour or the listen-back cutaway, MonitorService's `SavedText` keeps the TV over the sponsor ticker, unlocks are permanent even if a placement is later "stolen", t31+ numbering, updating the ~20 tests that pin "CRED", the 09_qa interactable count).

## 10. Decisions made during the build (2026-10-23)

These calls were made while building; each is recorded with its reason in `.superpowers/sdd/2026-10-23-walk-ins/progress.md`.

- **A visit counts when the visitor arrives** (§4.1), even if the card is then ignored or expires, so ignoring cards can't be used to fish for better ones. A visitor who never arrives (you left the hub or the game, or respawned) counts nothing and the same card comes back next time.
- **Expiry:** an unanswered card closes after 5 minutes (not paused while it waits behind the beat maker). When another visit is queued for a free walking slot, cards older than 90 s close instead (`ExpireBusySeconds`), so three idle producers can't hold every slot.
- **Hub presence** follows the real rooms (corridor x 0-12 / z 0-10, rooms x 12-94 / z -12..12). The Studio Two and Interscope passages (built by another session) are outside it, so walk-ins never follow you into either.
- **Sponsors:** a sponsor's rep only walks in once your Aura meets that sponsor's floor (100-400). Signing below the floor and being dropped the next visit was a loop for new players. A drop is re-checked at pick and arrival, so an Aura recovery cancels it.
- **Overhead tag** shows the amount that matches the outcome's tone (a CLOUT win no longer shows a blue "-5 AURA") and stacks above the name plate.
- **Economy:** money that should hurt is a `cost` (refused when you can't afford it), not a loss on a free choice; a loss on a free choice or in follow-up news takes at most $300. To keep a follow-up-aware money maximiser at or below half of a day's money, Hit royalties stay in the §4.8 band ($1,000-$1,200) but Hits are rarer: the follow-up news roll's base odds are 12-20% (about 37-45% once a typical player's Aura and Followers bonus applies). Measured on 20 seeds x 60 days: Studio Two median day 5 (p10 day 3, p90 day 6); Legend nameplate not before day 15 (min day 18); walk-in share of money: random player median 39.5%, greedy max 48.3%, career-chaser max 40.8%, spend-to-$0 max 28.3%; a random player gets about 4-5 Hits in 60 days, a greedy one about 1.7 a week.
- **Names as shipped:** parody sponsors RED BULB, NYKE, BEETS BY DRAY, SPOTIFRY, ROWLECKS, PRIYME (web checks replaced SPOTIFLY, ROLEKS and PRYME, which matched real companies); fiction sponsors NITE OWL ENERGY, KICKFLIP FOOTWEAR, THUMPCAN HEADPHONES, GLOW GUM, STACKS BANK, SIPWAVE WATER; fiction artists STIRRUP PEONY, VELVET FANG, SLEET VANTA, STATIC GOBLIN, ORBIT DUNE, QUILL MESA, SEQUIN MAPLE, HOOT CASTELLO, MOSS LULLABY. All pending the user's approval.
- **Roster switch limits:** `Roster = "fiction"` renames visitors and sponsors only. Card text still nods at the real artists (re-recordings, friendship bracelets, a halftime show, a vault of unreleased songs, banjo trap, a sneaker launch, stitched beats), and each visitor's signature shape and colour stay the same. A full fallback would need per-roster text and neutral signatures.
- **Turning walk-ins off** (`Config.WalkIns.Enabled = false`) also leaves Studio Two locked and kit_iron, the three fits and the Legend nameplate unbuyable for players without the stats, because only walk-ins pay Placements, Hits and Sponsors.
