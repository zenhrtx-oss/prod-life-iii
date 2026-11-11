# Wave 3 "Stakes" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Implementers write files and run CLI specs only; the orchestrator is the only Studio client.

**Goal:** Things happen to a person, not to a number:
- your delivered or aired beat moves placement odds
- a cold streak you climb out of
- six visitors who remember what you did (18 new cards)
- the first card on screen within about 35 s
- one-line explainers for the game's words

**Architecture:**
- **Pure rules first.** `Modules/WalkInRules` gains beat quality, the beat and relationship tilts, relationship gates, `{beat}` templating and hint picking; `Modules/CareerRules` gains the cold-streak step. All CLI-tested, with `Config` values passed in.
- **The data.** `Data/WalkIns` carries the flags (`beat` on choices, `rel` on outcomes, `needs.flags`/`under.flags`/`needs.rel`/`under.rel` on cards), the 18 arc cards and `cold_news`.
- **The sim.** `Modules/CareerSim` models all of it, so `spec/pacing_spec.lua` guards the money floors after every piece.
- **Server owners:**
  - Contracts: recent beats and `lastDay`
  - Career: the cold state
  - WalkIns and Phone: tilts, relationship writes, payload `beat` and `hint`
  - DataService: one repair line for `prof.hints`
- **The client:**
  - a second and third footer line on cards
  - the COLD chip in the BUSY DAY chip's place
  - the exit banner through the existing queue

**Tech Stack:** Luau (Roblox), Roblox Studio via the built-in Studio MCP (`tools/mcp_call.py`), `tools/sync.py`, `tools/test.py`, `sh tools/spec.sh`, the `luau` CLI at `/opt/homebrew/bin/luau`, Python 3.

**Spec:** `specs/2026-11-05-wave3-stakes-design.md` (approved 2026-11-05 after a builder check). Systems audit: `research/wave3/systems_2026-11-05.md` (line numbers there are the code map). The Wave 2 plan (`plans/2026-10-30-wave2-career-remembers.md`) is the pattern for test files, hooks and commits.

## Global Constraints

- **No git.** Every "commit" step is `sh .superpowers/g add -A src build spec specs plans research README.md && sh .superpowers/g commit -q -m "<task>: <what>"`. Add `tools` when a tool changes. Every message ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- **One Studio client.** Only the orchestrator calls `tools/sync.py`, `tools/test.py`, `tools/mcp_call.py`, `tools/snapshot.sh`, `tools/export_rbxm.py` or any `mcp__Roblox_Studio__*` tool, one at a time, under the lease:
  - Message every live OK session (today `ok-projects-82`) before Studio work and "ok-projects-01: done with Studio" after.
  - Load under 30 before a suite; suites under `caffeinate -d`; one rerun per flake.
  - `tools/sync.py` and `tools/test.py` have no `--help`; with no patterns or selectors they run everything.
  - **Precondition:** the room test is out (`build/room_test_remove.lua` run, streaming back off, suite 186/190) before Task 2's Studio step.
- **Scoped syncs only:** `python3 -I tools/sync.py --dry`, then parent-qualified patterns. Never `--force`.
- **Pure modules** (`Modules/WalkInRules`, `Modules/CareerRules`, `Modules/CareerSim`, `Modules/LifeRules`, `Modules/Format`, `Data/WalkIns`) never touch Roblox globals and never `require`. CLI specs keep literal copies of Config values (`spec/economy_fixture.lua`, pinned by t46).
- **Money guardrail** (checked after Tasks 3, 4 and 5 on 20 seeds and the recorded 200):
  - random card share ≥ 0.3412 on 200 seeds; every policy ≤ 0.50
  - THE HALL median 4–6, p10 ≥ 3, p90 ≤ 7
  - Legend ≥ 15 (random and homer); climber THE HALL; phone Aura ≤ 15 (random and climber)
  - If tuning `beatCenter`, `beatPer` or `relPer` within the design's ranges can't meet them, stop that task and bring the numbers to the user.
- **Saves:** schema stays **v5**.
  - New fields are lazily defaulted sub-fields in the owning system's `state()`: `prof.sessions.recent`, `prof.sessions.lastDay`, `prof.career.cold`, `prof.career.rearm`, `prof.walkins.rel`.
  - The one new top-level table, `prof.hints`, gets a repair line in `DataService.migrate` and is stripped by `ClientProfile`.
  - `prof.career` and `prof.walkins` keep every existing key (t41 pins them).
- **No new audio, lights or parts:** `Config.SFX` stays 17; 0 new lights; tagged interactables stay 12; the 4 light-cap checks stay the known baseline.
- **Copy:**
  - Every new line goes on the user's approval list (Task 0's file). Build with the drafts; the user approves after, as in Wave 2.
  - Rules: CAPS headlines; lowercase bubble lines; display names only through `{name:<id>}`; `{beat}` only in the 10 flagged cards and new placement cards.
  - Banned: OK, CRED/Cred (t40), STUDIO TWO (t50), BLOCK words.
- **Phone first:** new footer lines and the COLD chip fit at 844×390, 771×390 and 667×375 with every control ≥ 44 px.
- **Test numbers:** Studio `t75`–`t79`. `t75_check` (Edit); play pairs `t76a_play_server` / `t76b_play_client` … `t79a`/`t79b`. Markers `T75 OK`, `T76A PLAY OK`. Each play file starts with its own `fresh()` (unseat, teleport, Phone `Quiet`, WalkIns `Reset`, Career `Reset`, Life `Reset`, and the new `ResetHints`), runs in a pcall with cleanup and a rethrow, and finishes in under 90 s.
- **Standing limits:** never save or publish the place; no uploads; no Robux; no free-model scripts; no player-typed text; don't change the light cap or another session's imports; never flip `Config.Data.UseStoreInStudio`.

## Review Focus

1. **A player who never delivered.** `{beat}` reads "something", the footer reads "No beat delivered yet. Your odds are lower.", and no card or payload ever shows `nil`. Test: `walkin_rules_spec` (Fill with nil bpm) and t77a (empty `recent` → payload `beat = false`).
2. **The same beat twice, an aired-only beat, a fourth beat.** Delivering an identical pattern merges into one entry (stars keep the max); a FIRE on an aired beat that was never delivered creates an entry with `stars = 0`; a fourth distinct beat drops the oldest. Test: `walkin_rules_spec` (RecentPush) and t77a.
3. **Days not played never make anyone cold.** A player away ten real days comes back warm (career days count only days played), and a profile with no `lastDay` is never cold on its first read. Test: `career_rules_spec` (ColdStep) and t78a.
4. **Hints never repeat, one per card, and survive a rejoin.** Test: `walkin_rules_spec` (HintFor) and t75 (a v5 profile with `hints` round-trips through `HttpService` JSON and `ClientProfile` drops it).
5. **Bad relationship data never crashes or unlocks.** An unknown flag or visitor makes a card ineligible; scores stay within ±3 after any number of writes; a new sponsor signing resets the rep. Test: `walkin_rules_spec` (GateOk, RelWrite) and t79a.

---

## Shared shapes

- **Config additions** (`Config.WalkIns`):
  - `Odds.beatCenter = 3`, `Odds.beatPer = 4`, `Odds.relPer = 4` (tuned in Tasks 3 and 5 within center 2..4, per 3..6, rel 3..5)
  - `FirstEver = { 15, 20 }`
  - `Cold = { aura = -50, quietDays = 3, rearmAura = -25, dailyMax = 2 }`
  - `RecentMax = 3`
- **Config addition:** `Config.Hints = { { term = "aura", text = "…" }, … }` (8 entries, Task 0 copy, ≤ 70 chars each).
- **Recent beat entry:** `{ pattern = string(128), bpm = n, stars = 0..3, fires = n, day = careerDay }`; `prof.sessions.recent` newest first.
- **Cold state:** `prof.career.cold = { since = day, reason = "aura" | "quiet", news = bool } | nil`; `prof.career.rearm = bool`; `prof.sessions.lastDay = careerDay`.
- **Relationship:** `prof.walkins.rel[visitorId] = { score = -3..3, flags = { [flag] = careerDay } }`. Outcome field `rel = { who?, score?, flag?, clear? }`. Card gates `needs.flags = { "who.flag" }`, `under.flags = { "who.flag" }`, `needs.rel = n`, `under.rel = n`.
- **WalkInRules (pure), new and changed:**
  - `BeatQuality(entry?) -> 0..4`
  - `BestBeat(recent) -> entry?`
  - `RecentPush(recent, entry, max) -> recent` (merge by pattern, stars max, move to front, cap)
  - `RecentFire(recent, pattern, bpm, day, max) -> recent` (find or create with `stars = 0`, then `fires += 1`)
  - `BeatTilt(q, odds) -> number` = `(q - odds.beatCenter) * odds.beatPer`
  - `RelTilt(score, odds) -> number` = `score * odds.relPer`
  - `RelWrite(rel, write, ownVisitor, day) -> rel` (score clamp ±3; flag set; clear removes)
  - `Chance(base, career, odds, tilt?)`, `ChoiceChance(choice, career, odds, tilt?)`, `RollChance(choice, career, odds, tilt?)` and `Resolve(choice, career, odds, rng, tilt?)`: `tilt` (default 0) is added before the `min..max` clamp, including for `ready` choices. `ResolveNews` is unchanged (no tilt).
  - `GateOk(card, career, visits, rel?)` reads `needs.flags`, `under.flags`, `needs.rel`, `under.rel`; with `rel` nil, a card with any of them is ineligible.
  - `Fill(text, names, sponsorName, beatBpm?)`: `{beat}` → `"the one at " .. beatBpm` or `"something"`.
  - `HintFor(texts, seen, hints) -> { term, text }?` (whole-word, case-insensitive, first unseen term in `hints` order)
  - `Pick` / `Seed` / `Revalidate` pass `opts.rel` through to `GateOk`.
- **CareerRules (pure):** `ColdStep(cold, rearm, aura, careerDay, lastDay, event, cfg) -> cold', rearm', changed`, where `event ∈ { "check", "fire", "delivery3" }`; `lastDay` nil means warm.
- **Server:**
  - `Contracts.RecordDelivery(player, pattern, bpm, stars)` (called by Deliver on a pass; also hook-reachable)
  - `Contracts.CreditFire(player, pattern, bpm)` (called by `Reactions.Give`)
  - `Contracts.BestBeat(player) -> entry?`
  - `Career.ColdCheck(player, event)`
  - `WalkIns.DailyMaxFor(player)`
  - `Phone.SendSystem(player, id)`
- **Hooks (Studio only):**
  - `_StudioTestHook`: `RecordDelivery(uid, pattern, bpm, stars)`, `CreditFire(uid, pattern, bpm)`, `Recent(uid)`, `SetRecent(uid, list)`, `ResetHints(uid)`, `Hints(uid)`
  - `_StudioCareerHook`: `Cold(uid)`, `SetCold(uid, cold, rearm)`, `SetLastDay(uid, day)`, `ColdCheck(uid, event)`
  - `_StudioWalkInHook`: `Rel(uid)`, `SetRel(uid, rel)`
- **Payloads:**
  - walk-in `arrive` card gains `beat = { stars, fires, bpm } | false` (only when a choice is flagged) and `hint = { term, text }?`
  - phone pop and every result payload gain `hint`
- **Player attribute:** `Cold` (bool). **Life kinds:** `cold`, `thaw`. **Banner:** the exit text via `"LifeBanner"`.

## Rulings in this plan

- **The tilt is an optional argument, not a career field:** `Resolve(..., tilt)` — cost if wrong: signature churn in two callers (sim, WalkIns, Phone).
- **Contracts owns recent beats; Reactions calls `Contracts.CreditFire`:** one writer for `prof.sessions` — cost if wrong: none.
- **Career owns the cold state; Contracts and Reactions only report events** (`Career.ColdCheck`) — cost if wrong: none.
- **Hints are picked in the pure `WalkInRules.HintFor` and stored by the server in `prof.hints`** — cost if wrong: a move to another module.
- **`cold_news` goes through `Phone.SendSystem`**, a send path that skips `canSend` and the seen check but counts toward the day's phone total and waits for the tour — cost if wrong: one extra card a day while cold.
- **The 18 arc cards build with draft copy** and go to the user's approval list, as Wave 2 did — cost if wrong: copy edits after review.

## Execution waves

| Wave | Task | Studio |
|---|---|---|
| A | 0 (copy) | none |
| B | 1 (pure rules, Config, specs) | none |
| C | 2 (first card, explainers) | sync; t13, t41, t75, t76 |
| D | 3 (your beat) | sync; t46, t47, t77 |
| E | 4 (cold streak) | sync; t46, t71, t78 |
| F | 5 (relationships, arcs) | sync; t42, t46, t56, t79 |
| G | 6 (integration, final review, report) | full suite, snapshot, report |

---

### Task 0: Copy

**Files:**
- Create: `research/wave3/copy_2026-11-05.md`

- [ ] **Step 1: The `{beat}` edits.** For each of the 10 flagged cards (`navx_placement`, the eight `*_pitch` cards, `rival_beat`), write the revised `line`, or the flagged choice's `text` where the line has no natural slot, with exactly one `{beat}`. Each must read naturally with both "the one at 142" and "something".
- [ ] **Step 2: The 18 arc cards** (design §4.3 table): id, visitor, tag, line, 2–3 choices with outcomes (headline, text, line, note), deltas within the design's numbers, `rel` writes and gates as specified. Plus `cold_news`, the story lines for `cold` and `thaw`, the exit banner ("YOU'RE BACK · people are calling again" as the draft), and the eight hints (≤ 70 chars; the cypher hint says two or more).
- [ ] **Step 3: Scan.** Check the file against t40, t50 and the BLOCK words; check that every visitor exists in `Data/WalkIns`'s `W.Visitors` (no new visitors this wave).
- [ ] **Step 4: The orchestrator commits** `W3-T0: copy`.

### Task 1: Pure rules, Config and specs

**Files:**
- Modify: `src/ReplicatedStorage/OK/Modules/WalkInRules.lua`, `src/ReplicatedStorage/OK/Modules/CareerRules.lua`, `src/ReplicatedStorage/OK/Config.lua` (the Shared shapes additions, `Config.Hints` from Task 0)
- Modify: `spec/walkin_rules_spec.lua`, `spec/career_rules_spec.lua`, `spec/economy_fixture.lua` (literal copies of the new `Config.WalkIns` numbers)

**Interfaces:**
- Produces: every WalkInRules and CareerRules function in Shared shapes, with exactly those signatures.

- [ ] **Step 1: Write the failing tests.**
  - **BeatQuality:** nil → 0; `{stars=0, fires=0}` → 0; `{stars=2, fires=2}` → 2; `{stars=3, fires=3}` → 4; `{stars=3, fires=40}` → 4.
  - **BestBeat:** picks the highest quality; ties go to the first (newest); `{}` → nil.
  - **RecentPush** (max 3): a new pattern goes to the front; the same pattern with stars 2 then 3 gives one entry with stars 3 at the front; then stars 1 keeps 3; a 4th distinct pattern drops the last.
  - **RecentFire:** on an unknown pattern it creates `{stars=0, fires=1}` at the front; three calls on a known pattern give `fires = 3` and the same position.
  - **BeatTilt** with `{beatCenter=3, beatPer=4}`: q 0 → −12, 2 → −4, 3 → 0, 4 → +4. **RelTilt** with `relPer=4`: −3 → −12, 3 → 12.
  - **Chance with tilt:** `Chance(50, {aura=0, followers=0}, odds, 15)` = 65; a tilt that pushes past `max` clamps to 90; past `min` clamps to 10. **Resolve** with `rng` returning 64 and `tilt=15` on a base-50 choice → good, and without the tilt → bad. A `ready` choice's chance moves by the tilt too.
  - **RelWrite:** five `+1` writes give score 3; `who` overrides the own visitor; `flag` sets `flags[flag] = day`; `clear` removes it; a write with no fields is a no-op.
  - **GateOk:** `needs.flags = {"homekid.blew_up"}` is ineligible without that flag, and eligible with it; `under.flags` the reverse; `needs.rel = 2` checks the card's own visitor's score; an unknown visitor or flag is ineligible; `rel = nil` with any relationship gate is ineligible; cards without relationship gates behave exactly as before (the existing spec cases stay green).
  - **Fill:** `"you got {beat}?"` with bpm 142 → "you got the one at 142?"; with nil → "you got something?"; existing `{name:id}` and `{sponsor}` cases stay green.
  - **HintFor** with hints `{aura, placement}`: texts `{"Your Aura tilts it", "a placement"}` and seen `{}` → aura; seen `{aura=1}` → placement; seen both → nil; "auras" or "plaurall" don't match (whole words only).
  - **ColdStep** (`cfg = {aura=-50, quietDays=3, rearmAura=-25}`):
    - `lastDay` nil → warm, unchanged
    - aura −51 with `rearm` false → cold "aura"; with `rearm` true → warm
    - `careerDay - lastDay = 3` → cold "quiet"; `= 2` → warm
    - while cold, "check" keeps it cold whatever the aura; "fire" and "delivery3" thaw it
    - a thaw with reason "aura" sets `rearm`; aura −20 on a later "check" clears `rearm`
- [ ] **Step 2: Run** `sh tools/spec.sh walkin_rules career_rules` → FAIL on the new cases.
- [ ] **Step 3: Implement** the Shared shapes functions (pure; values as arguments) and the Config additions; mirror the numbers in `economy_fixture.lua`.
- [ ] **Step 4: Run** `sh tools/spec.sh` → all 8 specs PASS (existing cases unchanged).
- [ ] **Step 5: Commit** `W3-T1: rules for beat, rel, hints and cold`.

### Task 2: The first card and the explainers (design §4.4, §4.5)

**Files:**
- Modify: `src/ServerScriptService/OK/Services/DataService.lua` (repair line `if type(prof.hints) ~= "table" then prof.hints = {} end` after the v5 lines; `ClientProfile` sets `out.hints = nil`)
- Modify: `src/ReplicatedStorage/OK/Systems/WalkIns.lua` (`FirstEver` timer and the tour bypass when `count == 0`; the hint on `arrive` and result payloads), `src/ReplicatedStorage/OK/Systems/Phone.lua` (the hint on pop and result payloads), `src/ServerScriptService/OK/Main.server.lua` (hooks `ResetHints`, `Hints`)
- Modify: `src/ReplicatedStorage/OK/Modules/WalkInUI.lua` and `Modules/PhoneUI.lua` (a third footer line under the one `CardFeel.Footer()` fills, muted, with "i", shown only when `hint` is present)
- Create: `build/t75_check.lua`, `build/t76a_play_server.lua`, `build/t76b_play_client.lua`

**Interfaces:**
- Consumes: `WalkInRules.HintFor`, `Config.Hints`, `Config.WalkIns.FirstEver` (Task 1).
- Produces: payload field `hint = { term, text }?`; `prof.hints`; hooks `ResetHints(uid)`, `Hints(uid)`.

- [ ] **Step 1: Write the failing tests.**
  - **t75_check** (Edit, fresh DataService as in t70):
    - a v5 profile without `hints` gets `{}`
    - a profile with `hints = { aura = 3 }` survives `HttpService` JSON key for key
    - `ClientProfile` has no `hints`
    - `SchemaVersion == 5`
    - marker `T75 OK`
  - **t76a_play_server:**
    - `fresh()` plus `ResetTour`
    - WalkIns `Reset` leaves `count == 0`
    - the walk-in hold off for this file only
    - a pending visit exists within 25 s of the reset, with the tour not done
    - its `arrive` payload's `hint.term` is the first unseen term found in that card's text
    - `Hints(uid)` then contains it
    - a second card with the same term carries a different hint or none
    - marker `T76A PLAY OK`
  - **t76b_play_client:**
    - the card is on screen within 35 s of the reset
    - the hint line is visible, fits its box at 667×375 and 844×390, and doesn't push WALK AWAY under 44 px
    - marker `T76B PLAY OK`
- [ ] **Step 2: Integrator red run** `--edit t75` and `--play t76` → FAIL.
- [ ] **Step 3: Implement.** The timer: when `prof.walkins.count == 0`, the first arm uses `between(FirstEver)` and `schedule` skips only the tour check for that one visit. Hints: the server builds the visible text list (tag, line, choice texts; for results headline and text), calls `HintFor`, attaches the hint, and writes `prof.hints[term] = careerDay` with `MarkDirty`.
- [ ] **Step 4: Integrator.**
  1. Sync `Services/DataService`, `Systems/WalkIns`, `Systems/Phone`, `OK/Main`, `Modules/WalkInRules`, `Modules/CareerRules`, `OK/Config` `Modules/WalkInUI` and `Modules/PhoneUI`.
  2. `--edit t13 t41 t75` and `--play t76 t47 t63` → PASS.
- [ ] **Step 5: Commit** `W3-T2: first card in 20 s and explainers`.

### Task 3: Your beat (design §4.1)

**Files:**
- Modify: `src/ReplicatedStorage/OK/Data/WalkIns.lua` (`beat = true` on the 10 choices; Task 0's `{beat}` lines)
- Modify: `spec/walkins_data_spec.lua` (every card with a `beat = true` choice has `{beat}` in its line or that choice's text; exactly the 10 cards today)
- Modify: `src/ReplicatedStorage/OK/Modules/CareerSim.lua`, `spec/pacing_spec.lua`, `spec/career_sim_spec.lua`
- Modify: `src/ReplicatedStorage/OK/Systems/Contracts.lua` (`state()` defaults `recent = {}`; `RecordDelivery`, `CreditFire`, `BestBeat`)
- Modify: `src/ReplicatedStorage/OK/Systems/Reactions.lua` (`Give` calls `Contracts.CreditFire` with the airing's pattern and bpm)
- Modify: `src/ReplicatedStorage/OK/Systems/WalkIns.lua` (the tilt on flagged choices; `filler` passes the best bpm; payload `beat`)
- Modify: `Main.server.lua` (hooks `RecordDelivery`, `CreditFire`, `Recent`, `SetRecent`); `Modules/CardFeel.lua` (`BeatLine(beat) -> string`) and `Modules/WalkInUI.lua` (the second footer line)
- Create: `build/t77a_play_server.lua`, `build/t77b_play_client.lua`

**Interfaces:**
- Consumes: `RecentPush`, `RecentFire`, `BestBeat`, `BeatQuality`, `BeatTilt`, the tilted `Resolve` and `Fill` (Task 1).
- Produces: `Contracts.RecordDelivery(player, pattern, bpm, stars)`, `Contracts.CreditFire(player, pattern, bpm)`, `Contracts.BestBeat(player) -> entry?`; payload `beat`.

- [ ] **Step 1: Write the failing tests.**
  - **Specs:**
    - the data spec's 10-card rule
    - `career_sim_spec`: a sim day's deliveries push recent beats with the sim's stars, and its FIRE credits the newest
    - `pacing_spec`: the guardrail floors with the beat tilt on
  - **t77a_play_server:**
    - an empty `recent` gives `navx_placement`'s payload `beat = false` and a line with "something"
    - `RecordDelivery(p, P1, 142, 3)` then `CreditFire` three times gives `Recent` = one entry `{stars=3, fires=3}`, and `BestBeat` quality 4
    - the card's line has "the one at 142"
    - a forced roll (`SetRng`) of `base + 4` succeeds only with the tilt
    - an aired-only pattern gets `stars 0`
    - a 4th pattern drops the oldest
    - marker `T77A PLAY OK`
  - **t77b_play_client:** the footer's second line reads "Your best beat: ★★★ · 🔥 3" and, after `SetRecent({})`, "No beat delivered yet. Your odds are lower."; both fit at 667×375.
- [ ] **Step 2: Run** `sh tools/spec.sh` → FAIL. **Integrator red run** `--play t77` → FAIL.
- [ ] **Step 3: Implement.**
  - **Contracts.Deliver:** on a pass, call `RecordDelivery` with the career day from Life.
  - **The sim:** keep `sim.recent` with the same pure functions; deliveries push their stars; `receiveFire` credits the newest; flagged choices roll with `BeatTilt`.
  - **Tuning:** set `beatCenter` and `beatPer` within their ranges so the existing personas average about zero tilt and the guardrail holds; record the chosen values and the sim numbers in the commit message.
- [ ] **Step 4: Run** `sh tools/spec.sh` → PASS. **Integrator:**
  1. Sync `Data/WalkIns`, `Systems/Contracts`, `Systems/Reactions`, `Systems/WalkIns`, `Modules/CardFeel`, `Modules/WalkInUI`, `OK/Main`, `Modules/CareerSim` and `OK/Config`.
  2. `--edit t46` and `--play t77 t47 t42 t22` → PASS.
- [ ] **Step 5: Commit** `W3-T3: your beat feeds the cards`.

### Task 4: The cold streak (design §4.2)

**Files:**
- Modify: `src/ReplicatedStorage/OK/Systems/Career.lua` (`state` defaults; `ColdCheck`; the `Cold` attribute; the hooks `Cold`, `SetCold`, `SetLastDay`, `ColdCheck`)
- Modify: `Contracts.lua` (`lastDay` on every pass; `ColdCheck(p, "delivery3")` on 3 stars), `Reactions.lua` (`ColdCheck(p, "fire")` on a FIRE to the producer)
- Modify: `WalkIns.lua` (`DailyMaxFor`; no burst while cold), `Phone.lua` (`canSend` false while cold; `SendSystem`)
- Modify: `Life.lua`, `Modules/LifeRules.lua`, `Config.lua` (`Config.Life` story copy; kinds `cold`, `thaw`; `Life.Tick` calls `ColdCheck(p, "check")`), `spec/life_rules_spec.lua`, `spec/economy_fixture.lua`
- Modify: `Data/WalkIns.lua` (`cold_news`), `Modules/HUD.lua` (the COLD chip in the BUSY DAY chip's slot)
- Modify: `CareerSim.lua` (cold step, the cold daily max, the `neglect` persona: delivers on day 1, then none until `input.resumeDay`, no FIRE), `spec/pacing_spec.lua`
- Create: `build/t78a_play_server.lua`, `build/t78b_play_client.lua`

**Interfaces:**
- Consumes: `CareerRules.ColdStep` (Task 1); `Contracts.RecordDelivery` (Task 3).
- Produces: `Career.ColdCheck(player, event)`, `WalkIns.DailyMaxFor(player)`, `Phone.SendSystem(player, id)`, the `Cold` attribute, Life kinds `cold` and `thaw`.

- [ ] **Step 1: Write the failing tests.**
  - **Specs:**
    - `life_rules_spec`: story text for `cold` and `thaw`; every streak logs (not first-only)
    - `pacing_spec`:
      - `neglect` (resumeDay 6) is cold on day 4 and warm after its day-6 3-star delivery
      - random, greedy, chaser and spendDown are never cold in days 1–7 on the 200 seeds
      - the guardrail holds
  - **t78a_play_server:**
    - `SetLastDay(uid, day - 3)` then `ColdCheck("check")` → `Cold` is true and reason "quiet"
    - `DailyMaxFor` → 2
    - the phone `canSend` refuses, while `cold_news` arrives once via `SendSystem`, and a second `ColdCheck` doesn't resend it
    - the story ends with `cold`
    - `CreditFire` on the player's beat → warm, a `thaw` story line, and a `LifeBanner` sent
    - `SetCold(nil)` with aura −60 → cold "aura"; a 3-star `RecordDelivery` → warm with `rearm` true; aura −60 again stays warm until aura −20 has been seen
    - a profile with `lastDay` nil is warm after `ColdCheck`
    - marker `T78A PLAY OK`
  - **t78b_play_client:** the COLD chip shows while `Cold` is true, sits where BUSY DAY does, never overlaps the pills or floats at 667×375, and hides when warm; the exit banner text appears in `BannerLog`.
- [ ] **Step 2: Run** specs → FAIL; **integrator red run** `--play t78` → FAIL.
- [ ] **Step 3: Implement** as the design §4.2 says, every rule through `ColdStep`. The career day comes from Life; `ColdCheck` runs after any Aura change through `Career.Add`/`Take`, at `Life.Tick`'s day step, and on the two exit events.
- [ ] **Step 4: Run** specs → PASS. **Integrator:**
  1. Sync `Systems/Career`, `Systems/Contracts`, `Systems/Reactions`, `Systems/WalkIns`, `Systems/Phone`, `Systems/Life`, `Modules/LifeRules`, `Modules/HUD`, `Data/WalkIns`, `Modules/CareerSim`, `OK/Config` and `OK/Main`.
  2. `--edit t46 t60` and `--play t78 t71 t63 t66` → PASS.
- [ ] **Step 5: Commit** `W3-T4: the cold streak`.

### Task 5: They remember you (design §4.3)

**Files:**
- Modify: `Data/WalkIns.lua` (the `rel` writes on the trigger outcomes in the design's table; the 18 cards with Task 0 copy; `under.flags = {"mom.quiet"}` on every mom card except `mom_return`)
- Modify: `spec/walkins_data_spec.lua`:
  - every `needs.flags`/`under.flags` entry names a flag some outcome sets
  - every `rel.who` is a visitor
  - every new card passes the existing data rules
  - the two new placement cards carry `beat = true` and `{beat}`
- Modify: `WalkIns.lua` (`state` defaults `rel`; `RelWrite` on apply; `opts.rel` into Pick/Seed/Revalidate; `RelTilt` added to the beat tilt; `rel.rep` reset on any sponsor signing; `sponsor_warning` planted instead of `sponsor_drop` when `rel.rep.score >= 1`, with `sponsor_drop` then planted at {2,3}; `Reset` clears `rel`; hooks `Rel`, `SetRel`), `Phone.lua` (`RelWrite` on apply and on NEWS resolutions)
- Modify: `CareerSim.lua` (relationship state through the same pure functions; arcs in the deck), `spec/pacing_spec.lua`
- Create: `build/t79a_play_server.lua`, `build/t79b_play_client.lua`

**Interfaces:**
- Consumes: `RelWrite`, `RelTilt`, `GateOk(..., rel)` (Task 1); the tilt plumbing (Task 3).

- [ ] **Step 1: Write the failing tests.**
  - **Specs:** the data spec rules above; `pacing_spec` with the arcs in the deck (guardrail; THE HALL p90 ≤ 7).
  - **t79a_play_server:**
    - choosing "Eat with her" on `mom_food` gives `Rel(uid).mom = {score=1, flags={fed=day}}`
    - `two_sessions` hometown writes to `homekid`, not `bookings`
    - with `SetRel` giving `homekid.blew_up` and score 2, `homekid_album` becomes eligible (Pick with forced deck order) and its payload carries `beat`
    - `mom_quiet` sets `quiet`, and every mom card except `mom_return` becomes ineligible until `mom_return` clears it
    - signing `rep_energy` resets `rel.rep`
    - with `rel.rep.score = 1` and Aura under the floor, the system plants `sponsor_warning`, not `sponsor_drop`
    - an unknown flag in `SetRel` changes nothing and crashes nothing
    - marker `T79A PLAY OK`
  - **t79b_play_client:** one new arc card (`navx_tv`) at 667×375: every choice ≥ 44 px, text fits, and the footer lines don't overlap.
- [ ] **Step 2: Run** specs → FAIL; **integrator red run** `--play t79` → FAIL.
- [ ] **Step 3: Implement.** Tune `relPer` within 3..5 against the guardrail; record it and the sim numbers in the commit message.
- [ ] **Step 4: Run** specs → PASS. **Integrator:**
  1. Sync `Data/WalkIns`, `Systems/WalkIns`, `Systems/Phone`, `Modules/CareerSim`, `OK/Config` and `OK/Main`.
  2. `--edit t46` and `--play t79 t42 t56 t47 t69` → PASS.
- [ ] **Step 5: Commit** `W3-T5: six people remember you`.

### Task 6: Integration, review and report

- [ ] **Step 1:** The full suite (186 + the new files, only the 4 light-cap checks failing; one rerun per flake), `walkins_pause_off`, and guard green.
- [ ] **Step 2:** A whole-branch final review on the most capable model, against this plan and the design; one fix dispatch; one scoped re-review.
- [ ] **Step 3:** `sh tools/snapshot.sh v39_wave3`; `python3 -I tools/export_rbxm.py`; README "Milestone 14 Wave 3 'Stakes'"; `WAVE3_REPORT.md` (try it, how sure, the sim numbers, what needs you: the copy approval list); the tracker (Now, Needs you, Done log); memory.
- [ ] **Step 4: Commit** `W3-T6: integration and report`; send "ok-projects-01: done with Studio".

---

## Launch amendments (2026-11-06)

The user narrowed the goal on 2026-11-05 ~21:00 to "everything 100% needed at launch": all of Wave 3, fiction names, the launch audit's fixes and the new visitor look (B · Lanky shapes, OK's pick). These tasks run after Task 5 and before Task 6, one at a time, with the same per-task review loop. The light cap is 61 (the user's call, commit 84304f2), so the full suite has no known failures.

### Task 5b: Fiction names for launch

**Files:** `Config.lua` (`Config.WalkIns.Roster = "fiction"`), `Data/WalkIns.lua`, `Data/Artists.lua` (if it carries real-artist cues), `Modules/LifeRules.lua` (`Copy`), any other shipped string that names or nods at a real artist or brand; `spec/walkins_data_spec.lua`; new `build/t80_check.lua` (Edit); a copy doc `research/fiction_pass_2026-11-06.md`.

- Flip the roster to fiction (parody stays a switch, untouched).
- Sweep every shipped string — walk-in and phone cards (lines, choices, outcomes, follow-ups, news), Wave 3's 18 arc cards and the 10 `{beat}` edits, `cold_news`, story copy, banners, sponsor names and style tags — for nods at real artists, songs or brands (e.g. "country trap" + cowboy cues for the navx fiction identity; a sponsor name that collides with a real brand). Rewrite each in the game's voice; keep caps/lowercase rules and `{name:<id>}` usage. Web-check every fiction artist and sponsor name for a real-brand or real-artist collision and propose an alternate where one exists.
- List every change old → new in `research/fiction_pass_2026-11-06.md` with a §Approval list; it joins the user's approval list (copy rule).
- Visitor signature pieces in `Modules/Visitor.lua` that cue a real artist (e.g. the cowboy hat) are listed for Task 5d, not changed here.
- **Tests:** `t80_check` (Edit): with the roster on fiction, no display name, card text or story line contains any parody name or any entry of a banned real-name token list kept in the test; grep existing tests for hard-coded parody names and update them; walkins_data_spec keeps passing.

### Task 5b+: The starter pool (the user, 2026-11-06 03:15)

The user: "If it was bitlife mechanics wouldn't it be a bunch of randomized options that would work within that scenario?" Today `gentle_first` (the superfan, `first = true`) is every new player's fixed first walk-in, which reads wrong for a producer with no music yet.
- About 6 starter cards with `first = true`, each fitting a nobody producer and low-risk, each teaching one thing (Claude's drafts: a local artist with $50 who needs a beat tonight — points at the beat maker; your cousin, your first "fan"; the neighbor banging on the wall about the noise; a kid from the block who wants to learn; the open-mic host offering a Friday slot; a studio owner offering cheap late-night hours). The very first walk-in draws one at random; the rest never come back as a "first" (under visits 1).
- `gentle_first`'s superfan stays out of the first slot; the real superfan keeps arriving through the BUZZING tier visit.
- New lines go on the approval list (same copy rules; fiction names only).
- **Tests:** the data spec (every `first` card is gated under visits 1, no cost, no loss); a play check that the first-ever arrival is a `first` card and that over a forced RNG sweep more than one starter can be drawn.

### Task 5e: Day One — choices from the first second (the user, 2026-11-06 03:20)

The user, playing: "it's not clear enough what you are supposed to do, no tutorial or engaging things off rip, u should start making choices off rip." Picked "Day One choice chain" over "instant first card only". The passive Tour tracker (Systems/Tour.lua: open → take JUNO VALE's starter request → deliver → monitors → gear) becomes a chain of choice cards on the existing card UI, starting about 1 s after a new player's character loads.
- **Card 1, DAY ONE** (story + the starter request): "You spent every dollar on a tiny studio. The phone buzzes: JUNO VALE needs a beat by tonight. $50." Choices: *Make it now* (opens the beat maker with the request taken; the old tour texts become short coach marks on the live controls); *Ask for $100* (a haggle roll: good = the request pays $100, bad = "$50, final" — never a loss; then the beat maker opens); *Look around first* (closes; the PC pulses and JUNO's card returns after ~60 s).
- **Card 2, on the first delivery:** "It's done. Play it for the room?" *On the monitors* (airs it; counts the monitors step) / *Keep it private* (+small XP).
- **Card 3, after:** "You've got $X. Spend it?" *Hit the gear rack* (points at the rack; counts the gear step) / *Save it*.
- **Then** the random starter visitor (Task 5b+) arrives within ~10 s, and the normal game runs. If the player wanders, the FirstEver visit still comes by ~90 s so nobody waits with nothing to choose.
- Players whose tour is done never see it; a SKIP stays available (pays nothing, as today). The tour's reward and its `prof.tour` record keep working (schema v5).
- Money: the haggle's +$50 is one-time; pacing_spec must still pass.
- Every new line goes on the approval list (fiction names only).
- **Tests:** a play pair: a fresh player gets card 1 within 3 s of spawning; each choice leads where it says; delivering shows card 2; card 3 follows; the starter visitor follows within ~10 s; a done-tour player gets none of it; every control ≥ 44 px at 667×375 / 771×390 / 844×390.

### Task 5f: Beat maker quality pass (the user, 2026-11-06 03:22) — DESIGN FIRST

The user asked whether the beat maker is FL-level for producers (honest answer: no; a one-bar 16-step toy-grade sequencer with a scale-locked melody lane, a thin licensed sound set, no mixing, Roblox-clock timing) and chose "before launch" over "after launch". Scope as offered: **two-bar patterns, a sound upgrade (a real hi-hat, 808 pitch) and per-track volume**. Two-bar patterns change the beat format (today a 128-char one-bar pattern read by saves, briefs/stars, monitors, flips, cyphers, Wave 3's recent beats) — the parked "song mode needs a beat-format migration" — so this needs a short design (format + save migration + how bar 2 is edited on a phone) and the user's calls before any build. Sounds come only from the licensed APMOfficial / ProSoundEffects catalogs, never from memory, and the user approves each by listening.

### Task 5g: Your own room (the user, 2026-11-10 ~14:50) — DESIGN FIRST

Reacting to `plans/2026-11-10-tiered-studio-progression-proposal.md` (written by session work-0b), the user moved "your room" INTO the launch list. The 11-04 decisions stand: one room that grows (Your Room → Pro Room → Your Suite) behind your own door in the shared building; friends walk in; your name and neon on the door; furniture you place from day one; your career on the walls; visitors come to you. Two questions the proposal raised are DEFERRED to the room design, not decided: start in a bedroom instead of a tiny studio (would change Day One's story), and THE HALL / WEST SUITE as the top rungs of your own ladder instead of shared legendary rooms. Also open: doors open / friends-only / locked by default; the $1,500 price on the vision page is a proposal, not a decision. Prerequisites already met: saves are session-locked and proven on the real store (11-05). Needs: the room design (the brainstorming skill, a builder check, the user's calls), then a plan; rebuild the phone room test (`build/room_test.lua`) when the room's part budget is known. Net-new system: player-placed decoration (catalog, placement, cost, per-player persistence, replication to visitors).

### Order after Task 5's fix round (the user's launch list)
5b fiction names + 5b+ starter pool → 5e Day One → 5c-1 → 5c-2 → 5d → **5f design → the user's calls → 5f build** → **5g design → the user's calls → 5g build** → Task 6.

### Task 5c-1: Launch fixes — phone and tablet UI (audit A1, A3, A10, A11)

Source: `research/launch_audit_2026-11-05.md` (verbatim findings and verifier fixes; re-read the current code, line numbers have moved).
- **A1 (Blocker) + A3 (High):** in the compact beat maker, no control sits inside the Roblox top bar (`GuiService.TopbarInset`), and the header's right edge stays ≤ the REQUESTS chip's left − 6 at every width (shrink the page buttons and KIT, or move the pager out of the header; RequestUI places the chip at max(W − 190, header right + 6)). Every control ≥ 44 px.
- **A10:** MiniSubmit follows the chip's on-screen rect on each refresh (keep OK_Cypher on CoreUISafeInsets).
- **A11:** on touch devices (`TouchEnabled`) the beat maker uses ≥ 44 px close/transport/header/slot controls and piano-roll rows ≥ 44 px (rows scroll), regardless of compact.
- **Tests:** a t30-style assert at 640×360, 667×375 and an iPad size (1024×768, touch): no two visible GuiButtons in OK_DAW overlap, none intersects the top-bar inset, every button ≥ 44 px; MiniSubmit sits over the chip.

### Task 5c-2: Launch fixes — server abuse and saves (audit A2/A4, A5/A12, A6, A7, A8, A9, A13)

- **A2/A4 (High):** `Cypher_Join` refuses from idle ("busy"); only the board interaction opens a lobby; after a lobby is cancelled for too few entrants, no new lobby for 60 s server-wide; walk-ins and phone pops hold only in the cypher's listen and vote phases (not lobby).
- **A5/A12:** `DAW_Broadcast` per-player cooldown (≈ 8 s after a successful enqueue, cleared on leave) and the "inline" check before `Flips.Judge`.
- **A6:** a token bucket in front of `Career_Unlock` (burst 3, one per 0.25 s); refusals return the cached state.
- **A7:** `DataService.Saving(prof)`; the DAW save reply carries `saving`; the client never says "Saved" when the session can't save.
- **A8:** `Config.Data.LockWaits = { 1, 2, 3, 6, 8, 10 }` (mirror any fixture copy).
- **A9:** `_Shutdown` spawns every release at once and waits once; `_Autosave` and non-release saves stop when closing.
- **A13:** Nameplate disconnects its attribute signals when its character is removed.
- **Tests:** play checks for the cypher refusal and cooldown, the broadcast cooldown, the unlock limiter, the "can't save" message (a profile flagged `_loadFailed`), and the nameplate disconnect; t74's fake store covers the shutdown order.

### Task 5d: The visitors' new look (B · Lanky shapes) and the card portrait

Source: `research/visitor_look_2026-11-05/` (`lineup.lua` B recipes for five visitors, `notes.md`), the comparison page https://claude.ai/artifact/AtAQGuTZnVtVvyNiWSvs57 and `captures/visitor_looks_2026-11-05/clear/`.
- Rebuild `Modules/Visitor.lua`'s figures to B for EVERY visitor id (the fiction cast after 5b, Wave 3's arc visitors, the tier visitors, the rep); new recipes in the same style (tall thin body ~6.6–7 studs, small block head with a wedge nose, long block limbs, big shoes, one bold outline colour, one or two signature pieces, no real-artist cues). The pigeon stays a critter.
- Keep the surfaces t42/t43/t55/t56 rely on (Handle, part naming, OK_Visitors), ≤ 16 parts, separate limbs for the walk swing; name plate and bubble offsets per notes.md.
- **A14:** pose the figure at ≈ 15–20 Hz while walking (accumulate dt), not every Heartbeat.
- **The card portrait:** the walk-in card's brown square becomes a live head-and-shoulders view of that visitor (a ViewportFrame with a client-built copy from the same recipe), framed tight so the small square head reads as a face at the card's size; same for any phone card that shows a person.
- **Tests:** every visitor id builds within the part budget with the required names; the card shows a non-empty portrait at 667×375 and 844×390; the orchestrator captures the lineup in Studio for the user before the commit is final (check the wedge slope).

### Task 6 (amended)

Full suite with **no** failures (one rerun per flake), `walkins_pause_off`, guard green; the whole-branch final review (most capable model) over b178a37..HEAD; snapshot `v41_launch_candidate`; export; README Milestone 14; `WAVE3_REPORT.md` with the launch checklist (the user's Studio steps: rename, name check, maturity questionnaire, MaxPlayers ≤ 12, private publish, phone + two-player test, icon and thumbnails) and one merged approval list (Task 0 §11, the fiction pass, "COLD", the beat line copy, the look).
