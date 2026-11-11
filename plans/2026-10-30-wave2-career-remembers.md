# Wave 2 "the career remembers" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Tasks run as Agent-tool subagents (implementer, then reviewer); the orchestrator runs Studio.

**Goal:** The career reads like a life:
- a career clock (one day per UTC day played, 7 days a year) on the nameplate
- a STORY tab with the firsts checklist and the story log
- fame tiers with a one-time banner and one special visit each
- the discography in CREDITS
- an auto title, ribbons and the tier on the profile card
- milestone bars on the Career tab

**Architecture:**
- **Pure rules** in a new `Modules/LifeRules`: tier from Followers, year and day labels, the clock step, the title, the ribbons, story-entry building, capped list pushes. They are CLI-tested.
- **One server system,** `Systems/Life`, owns the saved `prof.life` table (save schema **v5**). Other systems report events to it through `Life.Event(player, kind, fields)`. It publishes `Year`, `Tier` and `Title` player attributes, plants the one-time tier visits, and notifies the client for banners and the day toast.
- **The client** gets a sixth panel tab (STORY), new Credits, Card and Career sections, a YEAR on the nameplate, and a banner queue.
- No new remotes beyond the existing career data call's payload. No new sounds, lights or parts.

**Tech Stack:** Luau (Roblox), Roblox Studio via the built-in Studio MCP (`tools/mcp_call.py`), `tools/sync.py`, `tools/test.py`, the `luau` CLI at `/opt/homebrew/bin/luau`, Python 3.

**Spec:** `specs/2026-10-30-wave2-career-remembers-design.md` (approved for planning 2026-10-30, with the user's nine decisions). Code map: `research/wave2/codemap_2026-10-30.md`. The Wave 1 design (`specs/2026-10-26-wave1-life-happens-design.md`) still binds the card, copy and naming rules (§4.3, §4.8, §8).

## Global Constraints

- **No git.** Every "commit" step is `sh .superpowers/g add -A src build spec specs plans research README.md && sh .superpowers/g commit -q -m "<task>: <what>"` plus `sh tools/checkpoint.sh <task-id>`.
  - Add `tools` to the list in a commit that changes a tool.
  - Every commit message ends with the line `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- **One Studio client.** Only the integrator (the orchestrator) calls `tools/sync.py`, `tools/test.py`, `tools/mcp_call.py`, `tools/snapshot.sh`, `tools/export_rbxm.py` or any `mcp__Roblox_Studio__*` tool, one call at a time, under the lease:
  - Before Studio work, list the live sessions and message every other OK session (today `ok-projects-dd`). Wait for the ack, and send "ok-projects-da: done with Studio" at the end.
  - Run suites under `caffeinate -d`.
  - `tools/sync.py` and `tools/test.py` have no `--help`; without patterns or selectors they run a full sync or the full suite.
  - Implementers write files and run CLI specs only.
- **Scoped syncs only:** `python3 -I tools/sync.py --dry` first, then parent-qualified patterns. Never `--force`. A new module is created by sync.
- **Pure modules** (`Modules/Format`, `Modules/CareerRules`, `Modules/WalkInRules`, `Modules/CareerSim`, `Modules/LifeRules`, `Data/WalkIns`) never touch Roblox globals and never `require` anything. Config values come in as arguments. CLI specs keep literal copies of Config values, and `build/t46_check.lua` diffs them against live Config.
- **Nothing in this wave pays except the four tier visits** (the user's call: firsts and ribbons are cosmetic).
  - Tier visits pay through the existing walk-in path (`AddCred(p, n, "WalkIn")`, `Career.Add(..., "WalkIn")`).
  - No new reward source. No XP, and no Placement (the Wave 1 §8.2 rule: nothing that pays a Placement is gated).
- **Money guardrail:**
  - All checks are as Milestone 12 left them, on 20 seeds and the recorded 200: the floor ≥ 0.3412 on 200 seeds; every policy ≤ 0.50; THE HALL median 4–6, p10 ≥ 3, p90 ≤ 7; Legend ≥ 15 (random and homer); climber THE HALL; phone Aura ≤ 15 (random and climber).
  - If the tier visits can't meet them, stop at Task 3 and bring the numbers to the user.
- **Saves:** schema **v5**, adding one top-level table `prof.life`.
  - Keys are strings, lists are dense arrays of small records, and nothing uses number keys or Instances.
  - `prof.career` and `prof.walkins` keep their exact shapes (t41 pins them).
  - Old (v4) profiles get the design's backfill.
  - An old server never overwrites a newer save (t13).
- **Payload:** the story, discography, firsts and ribbons reach the client through `Career.State` / `Career_Get`, not the whole-profile `OpenPanel` payload.
- **No new audio:** `Config.SFX` stays at 17 and t11 stays green. Tier banners are silent or reuse an existing key.
- **Names and copy:**
  - Every story line, first, title, ribbon and tier-visit line is new copy and goes on the user's approval list.
  - Copy rules: CAPS headlines; lowercase lines in card bubbles; display names only through `{name:<id>}` (cards) or roster lookup at render (story and discography).
  - Banned: OK, CRED/Cred (t40), STUDIO TWO (it's THE HALL, t50), BLOCK words, and the rank words HITMAKER and STUDIO LEGEND in titles.
  - Any new visitor is web-checked and anchored in `research/wave1_names_2026-10-27.md`.
- **Phone first:** every tappable control ≥ 44 px at 844×390, 771×390 and 667×375, inside the gui's safe-area box; the six tabs included.
- **Budget:** 0 new lights, 0 new parts under `Workspace.OKStudio`, and tagged interactables stay 12. The 4 light-cap checks stay the known baseline.
- **Test hold:** as before. `tools/test.py` sets `WalkInsPaused` for the suite; only `tools/walkins_pause_off.lua` removes it. Only Life's midnight loop skips while held. A tier crossing through `Career.Add` (a real `Changed`) plants and banners whatever the hold; a crossing through Publish alone (the hook's `Set`, a join) records the tier, the story line and the first silently, with no plant and no banner (amendment A3).
- **Test numbers:** Studio `t70`–`t79`.
  - Edit checks: `t70_check` and up.
  - Play pairs by suffix letter, with the server file first (`t71a_play_server` / `t71b_play_client`).
  - Markers: `T70 OK`, `T71A PLAY OK`.
  - Each play file finishes in under 90 s and starts with its own `fresh()`: unseat, teleport, Phone `Quiet`, WalkIns `Reset`, Career `Reset`, and the new `_StudioLifeHook` `Reset`; the body runs in a pcall with cleanup and a rethrow.
  - Quiet stays on through each body and goes off only in staging tails, after the cleanup.
- **Standing limits:** never save or publish the place; no uploads; no Robux; no free-model scripts; no player-typed text; Abbey Road photos reference only; don't change the light cap or another session's imports.

## Review Focus

1. **The clock counts days played, once each.**
   - The case: joining twice in one UTC day, staying online across UTC midnight, and rejoining after a three-day gap.
   - The expectation: +1, +1 (via the midnight loop), and +1. Missed days never count.
   - The tests: the LifeRules spec and t70.
2. **A tier banner and visit happen once, ever.**
   - The case: Followers falling below a line and crossing it again, or a hook `Set` that skips `Career.Changed`.
   - The expectation: the saved high-water tier means no second banner and no second visit, and a Set still records a tier reached through the publish path.
   - The tests: t71a and the LifeRules spec.
3. **v4 profiles migrate cleanly and v5 survives a real store.**
   - The checks: a v4 profile gets `prof.life` with the backfill; a v5 profile JSON round-trips unchanged; t41's career/walkins shapes are untouched.
   - The test: t70, with `HttpService:JSONEncode`/`JSONDecode`.
4. **Lists stay bounded and names stay roster-correct.**
   - The checks: the story is capped at 100 and the discography at 200, oldest dropped first; entries store visitor ids; the fiction roster renders fiction names.
   - The tests: the LifeRules spec and t72b.
5. **Six tabs fit a phone.**
   - The check: every tab button is ≥ 44 px tall and its label fits at 667, 771 and 844.
   - The test: t73b.

## Shared shapes

- **`Config.Life`:**
  - `Tiers = { { id = "LOCAL", followers = 0 }, { id = "BUZZING", followers = 1000 }, { id = "KNOWN", followers = 5000 }, { id = "FAMOUS", followers = 20000 }, { id = "ICON", followers = 100000 } }`
  - `DaysPerYear = 7`, `StoryMax = 100`, `DiscoMax = 200`
  - `Firsts`: the ordered id list (Task 0 fixes the copy)
  - `Ribbons`: id → rule
  - `Titles`: the ordered title rules
  - `TierVisits = { BUZZING = "<follow-up id>", KNOWN = …, FAMOUS = …, ICON = … }`
- **`prof.life`** (v5): `{ day = n, last = yyyymmdd, story = { {d, k, f…} }, disco = { {d, kind, v, key} }, firsts = { [id] = day | 0 }, tier = "<id>", ribbons = { [id] = day } }`.
  - `d` is the career day.
  - `0` in `firsts` means "before the clock" (backfilled).
  - Story entries store ids and small fields, never prose.
- **`LifeRules` (pure):**
  - `TierFor(followers, tiers) -> id, index`
  - `YearOf(day, perYear) -> year`
  - `Step(life, today) -> boolean`: advances `day` when `today ~= last`
  - `Push(list, entry, max)`: appends and drops the oldest
  - `TitleFor(firsts, tierIndex, titles) -> string?`
  - `RibbonsFor(life, counts, rules) -> list`
  - `StoryText(entry, names) -> string`: the client renders from ids
  - `Backfill(prof, today, tiers) -> life`
- **`Systems/Life` (server):**
  - `Life.Event(player, kind, fields)`, with kinds: `placement`, `hit`, `sponsor`, `sponsor_drop`, `delivery`, `delivery3`, `beat`, `hall`, `legend`, `cypher_win`, `level`, `streak7`, `tier`.
  - `Life.State(player)` feeds `Career.State`.
  - Attributes: `Year`, `Tier`, `Title`.
  - Notifies (InteractionEvent): `"LifeBanner" { text }` and `"LifeDay" { day }`.
  - Hook `_StudioLifeHook`: `Reset`, `State`, `SetDay(uid, day, last)`, `AdvanceDay(uid)`, `Event(uid, kind, fields)`.
- **`DataService`:** `SchemaVersion = 5`; a `LeveledUp` BindableEvent fired by `applyXP` on a level-up (server-side), which Life listens to.
- **The nameplate:** `Nameplate.Text(level, rank, fires, year)` gives `"YEAR %d · LV %d · %s"` plus `" · 🔥 %d"`. It listens to `Year`.
- **`Profiles.PUBLIC`** gains `year`, `tier`, `title` and `ribbons` (17 → 21).
- **The panel:** `M.Tabs = { "Credits", "Sessions", "Gear", "Career", "Story", "Profile" }`.
  - STORY shows `Firsts` rows (`First_<id>`) and then `Story` rows (`Story_<n>`).
  - Credits gains `Disco_<n>` rows below "Your credits".
  - Career gains `Bar_<id>` rows (tier, level, THE HALL).
  - New prefixes never start with `Gate_` or `CareerGear_`.
- **HUD:** `C.Banner(text)` queues banners on `OK_LevelUp.LevelUp` (one at a time, 3.5 s each). LEVEL UP uses it too, and t68's geometry is unchanged.

## Rulings in this plan

- **The save table is `prof.life`,** not `story`, so it can't be confused with `careerLog` or the `first` card flag — cost if wrong: a rename before publish.
- **Tier visits are system-planted follow-ups** (like `mom_plaque` and `sponsor_drop`), one per tier. They are planted at the first crossing, due on the next 1–2 walk-ins, and pay money, Aura or Followers only — cost if wrong: a player who never stands in the hub never sees them.
- **A level-up gets a server-side event** (`DataService.LeveledUp`), so Life can log it without reading the client — cost if wrong: none.
- **The firsts list lives in Config as ids, with its copy in LifeRules templates** — cost if wrong: a later move.
- **Backfill** (the design's): day 1 from now, the current tier recorded silently, obvious firsts marked 0 ("before the clock"), and an empty story and discography — cost if wrong: only Studio test profiles exist.
- **The banner queue:** the tier banner and LEVEL UP never replace each other; the second waits — cost if wrong: a 3.5 s delay on a rare double.

## Execution waves

| Wave | Task | Studio |
|---|---|---|
| A | 0 (copy, tier visitors, names) | none |
| B | 1 (LifeRules, Config.Life) | none |
| C | 2 (v5 save, Systems/Life, hooks) | sync; t13, t41, t70 |
| D | 3 (event wiring, tier visits, sim) | sync; t41, t46, t43, t51–t53, t66, t67, t71a |
| E | 4 (client: nameplate, STORY tab, credits, card, bars, banner queue) | sync; t08, t15, t22, t25, t45, t62, t68, t72, t73 |
| F | 5 (integration, final review, report) | full suite, snapshot, report |

---

### Task 0: Copy, tier visitors and names

**Files:**
- Create: `research/wave2/copy_2026-10-30.md`
- Modify: `research/wave1_names_2026-10-27.md` (a new section, if any new name)

- [ ] **Step 1: Choose the four tier visitors.** Reuse existing visitors where the design says so (the talk-show booker at KNOWN). For each tier, pick a visitor id (existing, or new with both roster names), a follow-up id (`tier_buzzing`, `tier_known`, `tier_famous`, `tier_icon`), its headline, text and line, and its payout (money ≤ $600, Aura ≤ 40, Followers ≤ 2,000; no Placement or XP).
- [ ] **Step 2: Write the copy.** Every story template (one per Life kind), the firsts list (about 12, in order), the title rules and words (disjoint from `Config.Ranks`), the ribbons (about 5), the DAY toast, and the tier banner text. Apply every copy rule in Global Constraints.
- [ ] **Step 3: Web-check any new name** (the 1a format), and run a local scan against REAL, TITLES, BLOCK, t40 and t50.
- [ ] **Step 4: The orchestrator commits** (the implementer doesn't).

### Task 1: LifeRules and Config.Life

**Files:**
- Create: `src/ReplicatedStorage/OK/Modules/LifeRules.lua`, `spec/life_rules_spec.lua`
- Modify: `src/ReplicatedStorage/OK/Config.lua` (`Config.Life`), `spec/economy_fixture.lua` (a `LIFE` literal copy), `tools/spec.sh` (only if it lists specs explicitly)

- [ ] **Step 1: Write the failing tests.**
  - **TierFor:** 0 → LOCAL; 999 → LOCAL; 1000 → BUZZING; 4999 → BUZZING; 5000 → KNOWN; 20000 → FAMOUS; 100000 → ICON; −50 → LOCAL.
  - **YearOf** with 7: day 1 → 1, day 7 → 1, day 8 → 2.
  - **Step:**
    - a new `today` advances `day` and sets `last`
    - the same `today` doesn't advance
    - a gap of three UTC days advances by 1 only
  - **Push:** at max 3, pushing a 4th drops the first; the list stays dense.
  - **TitleFor:** follows Task 0's rules, never returns a `Config.Ranks` word, and returns nil before any first.
  - **RibbonsFor:** each rule at its edge.
  - **StoryText** for each kind, with a names table, renders the visitor's display name and never types a raw id.
  - **Backfill:**
    - a v4-shaped profile with placements 3, hits 1, followers 25,000 and THE HALL unlocked gives day 1, tier FAMOUS, `firsts.placement = 0`, `firsts.hit = 0`, `firsts.hall = 0`, and an empty story and discography
    - a fresh profile gives day 1, LOCAL, and no firsts
- [ ] **Step 2: Run** `sh tools/spec.sh life_rules` → FAIL.
- [ ] **Step 3: Implement** LifeRules (pure, no requires) and `Config.Life` with Task 0's values.
- [ ] **Step 4: Run** `sh tools/spec.sh` → all PASS.
- [ ] **Step 5: Commit** `W2-T1: LifeRules and Config.Life`.

### Task 2: The v5 save and Systems/Life

**Files:**
- Modify: `src/ServerScriptService/OK/Services/DataService.lua` (SchemaVersion 5, the migrate step with `LifeRules.Backfill`, the type repair, the `LeveledUp` event)
- Create: `src/ReplicatedStorage/OK/Systems/Life.lua`
- Modify: `src/ReplicatedStorage/OK/Systems/Career.lua` (`Career.State` includes `Life.State`; `Publish` calls `Life.Publish`), `build/t06_check.lua` (the module list), `build/t13_check.lua` (a v4 → v5 case), `build/t41_check.lua` (v5 pins; the career and walkins shapes unchanged)
- Create: `build/t70_check.lua`

- [ ] **Step 1: Write the failing tests** (`t70_check`, Edit, a fake store and clock as in t41):
  1. A v4 profile loads as v5, and `prof.life` matches `Backfill`.
  2. `HttpService:JSONEncode`/`JSONDecode` of a v5 profile with 3 story entries, 2 disco entries, firsts and ribbons equals the original, key for key.
  3. A clock step through `_day`: the same day gives no change; the next day gives +1.
  4. `SchemaVersion == 5`.
  5. A newer-version profile (v6) is not overwritten (t13's pattern).
  6. Marker `T70 OK`.
- [ ] **Step 2: Integrator red run** `--edit t13 t41 t70` → t41 and t70 FAIL.
- [ ] **Step 3: Implement.**
  - **Life.Init:** on join, `Step` the clock; on a new day, notify `LifeDay` and log. A 15 s loop does the same for online players at UTC midnight (Dailies' pattern), skipped while `WalkInsPaused` is present in Studio.
  - **`Life.Event`:** pushes story and discography entries, ticks firsts, recomputes the title and ribbons, and publishes the attributes.
  - **The tier:** checked on `Career.Changed` and on Publish. A new high-water mark logs, notifies `LifeBanner`, plants the tier visit, and saves the tier.
  - **`_StudioLifeHook`:** as in Shared shapes.
- [ ] **Step 4: Integrator.**
  1. Sync `Services/DataService`, `Systems/Life`, `Systems/Career`, `Modules/LifeRules` and `OK/Config`.
  2. `--edit t06 t13 t41 t70` → PASS.
  3. Then `--play t43 t51 t52` → PASS (no regression).
- [ ] **Step 5: Commit** `W2-T2: v5 save, Systems/Life`.

### Task 3: Event wiring, tier visits and the sim

**Files:**
- Modify: `src/ReplicatedStorage/OK/Systems/WalkIns.lua` (apply: placement and sponsor events; onArrive: hit events and the tier-visit arrival), `Systems/Phone.lua` (deliver: phone events where they matter), `Systems/Contracts.lua` (delivery and delivery3), `Systems/Dailies.lua` (streak7), `Systems/BeatBattles.lua` (cypher_win), `Systems/Career.lua` (Unlock → hall), `Systems/Gear.lua` (plate_legend → legend), `Systems/DAW.lua` (the first beat saved)
- Modify: `src/ReplicatedStorage/OK/Data/WalkIns.lua` (the four tier follow-ups and any new visitor, from Task 0)
- Modify: `spec/walkins_data_spec.lua` (system-planted follow-ups include the four; tier visits pay no Placement or XP), `src/ReplicatedStorage/OK/Modules/CareerSim.lua` (track Followers per day; plant the tier visit at the first crossing; `Run` returns `tierDays`), `spec/pacing_spec.lua` and `spec/career_sim_spec.lua`
- Create: `build/t71a_play_server.lua`, `build/t71b_play_client.lua`

- [ ] **Step 1: Write the failing tests.**
  - **career_sim_spec:**
    - a scripted Followers rise across 1000 plants `tier_buzzing` once
    - falling to 900 and rising again plants nothing new
    - `tierDays.BUZZING` is that day
  - **pacing_spec:** every guardrail on both seed sets, unchanged, plus a printed tier-day line (median day of BUZZING, KNOWN, FAMOUS and ICON).
  - **walkins_data_spec:** the four tier follow-ups exist and are system-planted, and their outcomes have no `placements` or `xp`.
  - **t71a** (server):
    1. `fresh()`, then Career `Set { followers = 900 }`, then `Career.Add` followers +200 through a walk-in apply path (a forced card) → the `Tier` attribute is BUZZING, the Life story's newest entry is `tier`, `tier_buzzing` is queued, and one banner notify was sent (read through the hook's log).
    2. Set followers to 800 and add 300 again → no new entry and no second plant.
    3. Force a placement card → the discography's newest entry has kind `placement` and the visitor id; `firsts.placement` is today's career day.
    4. Advance the walk-in count → the tier visitor walks in and pays as Task 0 set.
    5. Tail: `_StudioLifeHook` Event `hall`, leaving a story entry for t71b.
  - **t71b** (client): `OK_LevelUp.LevelUp` showed the tier banner text (read from a `LastBanner` attribute the queue sets) and the LEVEL UP banner wasn't replaced (queue order).
- [ ] **Step 2: Integrator red run** `--play t71a` → FAIL (t71b is Task 4's: it needs the banner queue).
- [ ] **Step 3: Implement** the event calls (one line at each site; Life looked up lazily), the content, and the sim.
- [ ] **Step 4: Run** `sh tools/spec.sh`. Every guardrail must hold on 20 and 200 seeds.
  - **On a FAIL:** stop and report BLOCKED with the numbers. The levers are the tier visits' payouts.
  - **On a PASS:** record both pacing lines and the tier days.
- [ ] **Step 5: Integrator.**
  1. Sync the changed systems, `Data/WalkIns` and `Modules/CareerSim`.
  2. `--edit t46 t69` → PASS.
  3. `--play t43 t45 t47 t51 t52 t53 t60 t61 t64 t65 t66 t67 t71a` → PASS.
- [ ] **Step 6: Commit** `W2-T3: life events, tier visits, sim tiers`.

### Task 4: The client

**Files:**
- Modify: `src/ReplicatedStorage/OK/Modules/Nameplate.lua` and `Systems/Reactions.lua` (pass the year), `Modules/PanelUI.lua` (six tabs, STORY renderer, Credits discography, Card title/tier/ribbons, Career bars), `Systems/Profiles.lua` (PUBLIC + 4), `Modules/HUD.lua` (`C.Banner` queue; LEVEL UP through it), `StarterPlayer/StarterPlayerScripts/OK/ClientMain.client.lua` (handle `LifeBanner`, `LifeDay`)
- Modify: `build/t22_check.lua`, `build/t22b_play_client.lua`, `build/t25_check.lua`, `build/t41_check.lua` (card fields), `build/t45b_play_client.lua` (only if a renamed row moves), `build/t08_play_client.lua` (if the Credits layout moved)
- Create: `build/t72a_play_server.lua`, `build/t72b_play_client.lua`, `build/t73b_play_client.lua` (or `t73_play_client`)

- [ ] **Step 1: Write the failing tests.**
  - **t22:** `Nameplate.Text(4, "ENGINEER", nil, 2) == "YEAR 2 · LV 4 · ENGINEER"`, and the same with `· 🔥 37`.
  - **t25:** `#PUBLIC == 21`, and the new keys are present.
  - **t72a/b:**
    - The server stages 3 story events, 2 placements (visitors `navx` and `homekid`), firsts and a ribbon.
    - The client opens STORY: `First_*` rows show ticks with "DAY n", and `Story_*` rows are newest first, with display names from the current roster (the fiction roster tested by switching `Config.WalkIns.Roster` on the server between runs, or by the hook).
    - CREDITS shows `Disco_*` rows.
    - The card shows the title, the tier and the ribbons.
    - The Career tab shows the three `Bar_*` rows with sensible fractions.
  - **t73b:** at 667×375, 771×390 and 844×390 (minus the inset), all six tab buttons are ≥ 44 px tall and inside the panel, each label fits (`TextFits`), and switching to STORY and back leaves the Career tab's `Gate_` and `CareerGear_` counts unchanged.
  - **t62/t68:** the banner geometry is unchanged, and two `C.Banner` calls in a row show in order.
- [ ] **Step 2: Integrator red run** `--edit t22 t25` and `--play t72 t73` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Integrator.**
  1. Sync the changed client modules, `Systems/Profiles`, `Systems/Reactions` and `ClientMain`.
  2. `--edit t22 t25 t41` and `--play t08 t15 t22 t45 t57 t58 t62 t68 t71 t72 t73` → PASS.
- [ ] **Step 5: Commit** `W2-T4: nameplate year, STORY tab, discography, card, bars, banner queue`.

### Task 5: Integration, review and report

**Files:**
- Modify: `README.md` (Milestone 13, plus stale lines), `../OK_GAME_TRACKER.md`
- Create: `WAVE2_REPORT.md`

- [ ] **Step 1: Integrator.** Run the full suite → only the 4 light-cap checks fail. A "Target is not reachable" flake gets one rerun of that file.
- [ ] **Step 2: Final review:** four lenses (save and data safety, economy and pacing, the client at three phone widths, regressions in t06–t69) plus a senior reviewer. Each critical or important finding goes to a skeptic. Then one fix dispatch.
- [ ] **Step 3: Close out.**
  1. Snapshot `v36_wave2`, export, checkpoint.
  2. Write the README section, the report (what's in, how sure, the pacing line with tier days, Needs you with all new copy, rulings, and limits) and the tracker update.
  3. Release the lease.
- [ ] **Step 4: Commit** `W2-T5: wave 2 done`.


## Plan-check amendments (2026-10-30)

Two adversarial checkers (test staging and code fit; the player, economy, saves and regressions) read the draft against the code, confirming every finding in code or with a scratch run. They returned 24 findings, about 17 distinct. All are folded in below. **These amendments bind every task and override any task text they contradict.**

- **A1 (blocker): Life before Init.**
  - Every `Life` entry point is a no-op until `Life.Init` has run, and Life has `_SetCtxForTest`. `Career` and `Gear` look Life up as `ctx.Life or require(...)`.
  - `Career.State` builds its `life` part from `prof.life` through a pure LifeRules helper, never from `Life.State(player)`. `Life.Publish` runs after Career.Publish's non-Instance guard (Career.lua:78).
  - Life exposes `Life.Tick(player)`, the join and midnight step, and t70 step 3 drives it.
  - t41 joins Task 2's and Task 3's `--edit` lists.
- **A2 (blocker): the banner and panel seams.**
  - A Studio `PanelCommand` `banner:<text>` calls `C.Banner`. The queue writes an ordered `BannerLog` attribute on OK_UI (last 6, joined with `|`) and sets `LastLevelUp` **when a LEVEL banner shows** (t15b waits 4 s).
  - `_StudioLifeHook` gains `Sent(uid)`, which returns the notifies since its last call.
  - PanelUI sizes the panel from OK_UI's `ForceViewport` when it's set; t73b forces through it.
  - t71b and the queue's order check (a tier banner, then a LEVEL UP from `_StudioTestHook AddXP` with a nil source, as t15 does) live in Task 4. t62 and t68 join Task 4's Files.
- **A3 (important): the old suite.**
  - A crossing through Publish only (hook `Set`, join, backfill) is silent.
  - t45a, t53 and t67a cross tiers through `Set`, so they stay quiet. t66a's comeback crosses BUZZING through `Add`, and its plant and banner are expected and harmless.
  - t53's "gate closed" stage calls `_StudioLifeHook Reset` before its `Set 1000`.
  - Every new t7x `fresh()` calls the Life `Reset`.
- **A4 (important): several tiers in one move.** A move from tier i to tier j handles every tier i+1 through j in order: a story line, a first, a banner queued and a visit planted each, with distinct ids at `{1,2}`, `{2,3}` and so on. LifeRules and career_sim_spec get a 900 → 6,000 case (BUZZING and KNOWN both handled).
- **A5 (important): the tier visits' payouts are bound by THE HALL.**
  - BUZZING, KNOWN and FAMOUS pay **Aura 0**; they land on days 1, 2 and 5, before THE HALL's 300-Aura need. ICON (about day 20) may pay Aura.
  - Task 0 runs the scratch sim (`scratchpad/sim/tiers.lua`) with the chosen payouts **before** writing copy that quotes `$N`, and records THE HALL median and p90, greedy max, and the floor on both seed sets.
  - The binding checks are THE HALL median 4–6, p90 ≤ 7, and greedy ≤ 0.50. The floor isn't at risk: visits raise the share.
  - Task 3 Step 4's levers are the visits' money and Followers.
- **A6 (important): the payload.** `DataService.ClientProfile(prof)` is a shallow copy without `life`. The six whole-profile send sites use it: InteractionService :78, :81 and :194, Gear :162, Profiles :53, and DAW :178. t72a asserts that `ProfileFunction` and the CreditsWall payload carry no `life` key.
- **A7 (important): the client refreshes.**
  - The background career fetch re-renders when the current tab is Career, Story or Credits.
  - STORY and the discography show a Loading line until it lands.
  - t72b opens Credits through the credits-wall OpenPanel path (as t08 does) and waits for `Disco_` rows with no tab switch.
- **A8 (important): names at render.**
  - `Career.State`'s life part carries the display names for the ids it holds, from the server's roster, and the sponsor names.
  - Sponsor story entries store the sponsor id and render through the sponsor name, never the rep's `{sponsor}` template.
  - The LifeRules spec asserts that no rendered line contains `{`, for both rosters.
  - t72 switches the roster through a `_StudioLifeHook SetRoster` command that changes the names `Career.State` sends.
- **A9 (important): t46.** `build/t46_check.lua` joins Task 1's Files (`LIFE` in its literal FIXTURE, and `economy.LIFE` from `Cfg.Life`) and Task 3's (the tier input in `input`, `PACING` and `run`).
- **A10 (important): a fallible high-water test.** t71a runs the visit arrival (step 4) before the fall and re-rise (step 2). The re-rise then asserts no new queue entry, no new `tier` story entry and no new `Sent` banner.
- **A11 (important): the v5 step's place.**
  - The v5 migrate step runs **after** the career and walkins type repairs (DataService.lua:91-92). `Backfill` tolerates a non-table career.
  - Backfill cases for career nil and career junk; `last == today` after backfill.
  - Task 2's red run expects t13's new v4→v5 case red too.
- **A12 (minor): backfill derives every first it can.** It marks 0 for:
  - the tiers up to the recorded tier
  - LEVEL 5 when level ≥ 5
  - sponsor when sponsors > 0
  - delivery when there are credits
  - cypher win when `cypher.wins > 0`
  - beat when the DAW has a save
  - streak when the daily streak is ≥ 7
- **A13 (minor): planting.**
  - `WalkIns.PlantSystem(p, id, at)` uses `state()` and `rngFor`, so SetRng works.
  - Tier planting moves to Task 3, where the follow-ups exist; Task 2 only records the tier.
  - The sim plants inside its `addStat` for followers, at the moment of crossing.
- **A14 (minor): a held banner.** The queue holds a tier banner while the OK_WalkIn or OK_Phone card is visible, and shows it when the card closes. LEVEL UP keeps today's timing. t71b checks the hold.
- **A15 (minor): copy guards.**
  - All Life copy lives in `LifeRules` templates, which t40 scans.
  - Uppercase "CREDITS" or "INCREDIBLE" fails t40, so the tab and headers use "Credits" casing as today.
  - `TitleFor`'s spec compares against `Config.Ranks` with spaces removed (`HIT MAKER` is refused).
  - Story entries are named-field records (`{ d = , k = , v = , s = , key = }`), never positional.
- **A16 (minor): the nameplate fit.** t22b measures the worst case `YEAR 15 · LV 10 · STUDIO LEGEND · 🔥 1234` with `TextService:GetTextSize`, and if the text would scale below 11 px, the plate widens (only its width; the 48 px height that WalkIns and Visitor depend on stays).
- **A17 (note for the report): tier days.** The scratch sim's engaged player reaches BUZZING on day 1, KNOWN on day 2, FAMOUS on day 5 and ICON on day 20. Real players will be slower. Both go in Task 0's brief and the report.

## Final review amendments (2026-10-30)

The final review (four lenses plus a senior reviewer, verdict "ready with fixes", no critical findings) produced one fix dispatch: `.superpowers/sdd/2026-10-30-wave2/task-H-brief.md`, fixes F1–F15.

- **Important:** F1 a player can see their own title, tier and ribbons on the Profile tab; F2 the STORY and CREDITS tabs work at phone height; F3 the join DAY toast reads a player attribute, so it can't be lost; F4 a tier visit can never be the first walk-in, so the gentle first visit stays first.
- **Rulings:** the three-place year/tier/title computation becomes `LifeRules.Public`; a ribbon gets one silent toast; the walk-ins-off case stays quiet.
- **Not changed, reported instead:** slower players reach THE HALL about a day later at 2 walk-ins a day; a tier visit can delay mom_plaque or sponsor_drop by a visit or two; "once ever" means at most once if walk-ins are off at the crossing.
