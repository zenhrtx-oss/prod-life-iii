# "Two sessions, same day" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Ultracode is on for this session: the orchestrator runs each task as a Workflow (implementer → review → fix loop → Studio integrator), as in Waves 1a and 1b.

**Goal:** One phone DM, "two sessions came in for today", with two choices:
- **The kid from your hometown** always pays XP now and books his comeback walk-in, where he pays you, credits you a placement and brings followers.
- **The one-hit wonder** rolls once, with odds set by a readiness blend of LV, placements, Followers and Aura: +Aura and a little XP when you're ready, −Aura when you're not.

**Architecture:**
- **Pure rules** stay CLI-tested: `WalkInRules.Readiness` and `WalkInRules.ChoiceChance`. `Resolve` keeps its single roll and only changes the chance for a `ready` choice. `deltasOf` carries `xp`.
- **The sim** learns card XP, levels up at once, and gains two policy variants.
- **The pacing spec** moves the money floor to a recorded 200-seed set, "no worse than today" (the user's call, 2026-10-29).
- **The server's** `Systems/Phone` pays card XP through `DataService.AddXP(p, n, "Phone")` and passes the player's level into `Resolve`.
- **The client** shows an XP chip and lifts the LEVEL UP banner above the cards.
- No new remotes and no save-format change.

**Tech Stack:** Luau (Roblox), Roblox Studio via the built-in Studio MCP (`tools/mcp_call.py`), `tools/sync.py`, `tools/test.py`, the `luau` CLI at `/opt/homebrew/bin/luau`, Python 3.

**Spec:** `specs/2026-10-29-two-sessions-design.md` (approved for planning on 2026-10-29), with the code map in `research/two_sessions/codemap_2026-10-29.json`. The older `specs/2026-10-26-wave1-life-happens-design.md` still binds the card, copy and naming rules it set (§4.3, §4.8, §8).

## Global Constraints

- **No git.** Every "commit" step is `sh .superpowers/g add -A src build spec specs plans research README.md && sh .superpowers/g commit -q -m "<task>: <what>"` plus `sh tools/checkpoint.sh <task-id>`.
  - Add `tools` to the list in a commit that changes a tool.
  - Every commit message ends with the line `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- **One Studio client.** Only the integrator calls `tools/sync.py`, `tools/test.py`, `tools/mcp_call.py`, `tools/snapshot.sh`, `tools/export_rbxm.py` or any `mcp__Roblox_Studio__*` tool, one call at a time, under the lease:
  - Before a task's first Studio call, list the live sessions (ListAgents) and message every other OK session (today `ok-projects-0c`, `ok-projects-d9`, `ok-projects-1a`): "ok-projects-0d: syncing/testing now". Wait for each ack, and send "ok-projects-0d: done with Studio" at the end.
  - Run suites under `caffeinate -d`.
  - `tools/sync.py` and `tools/test.py` have no `--help`: without patterns or selectors they run a full sync or the full suite.
  - Implementers write files and run CLI specs only.
- **Scoped syncs only:** `python3 -I tools/sync.py --dry` first, then parent-qualified patterns (`Systems/Phone`, `Modules/WalkInRules`, …). Never `--force`. No new remotes.
- **Pure modules** (`Modules/Format`, `Modules/CareerRules`, `Modules/WalkInRules`, `Modules/CareerSim`, `Data/WalkIns`) never touch Roblox globals and never `require` anything. Config values come in as arguments. CLI specs keep literal copies of Config values, and `build/t46_check.lua` diffs them against live Config.
- **Rewards:** XP from cards only through `ctx.Data.AddXP(p, n, "Phone")`, with the registered rule `Config.XP.Sources.Phone = { max = 60, dailyMax = 3 }`. Never `GrantXP`. Career stats keep going through `Career.Add`/`Career.Take`. Phone items still never pay money; the comeback's money is a walk-in follow-up's, through `AddCred(p, n, "WalkIn")`.
- **Money guardrail** (the user's call on the floor, 2026-10-29). These are measured in `spec/pacing_spec.lua` on the random player unless named:
  - **floor:** the median steady share on the recorded 200-seed set (`100000 + 7919 * i`, `i = 0..199`) is ≥ `BASELINE_SHARE_200 − 0.005`. Task 0 measures `BASELINE_SHARE_200` on today's deck (about 0.346) and pins it.
  - **ceiling:** every policy ≤ 0.50 on every seed of the spec's 20, and the 20-seed median ≤ 0.50
  - **THE HALL:** median day 4–6, p10 ≥ 3, p90 ≤ 7 (20 seeds)
  - **Legend:** nil or ≥ day 15 on every seed, for the random player and for the new "homer" policy (always the hometown kid)
  - **THE HALL for the "climber" policy** (always the one-hit wonder): median 4–6, p90 ≤ 7
  - **phone Aura:** ≤ +15 a day net
  - Targets are never relaxed beyond the user's floor call. If the content can't meet them, stop at Task 3 and bring the numbers to the user.
- **Saves:** schema stays **v4**, and nothing is added to `prof`. Card XP lives in the existing `prof.xpLog` (the gate's own `count["Phone"]`).
- **No new audio.** CardFeel plays Win, Loss and Plant as today; an XP chip plays nothing new. `Config.SFX` stays at 17.
- **Names and copy:**
  - **New names:** the sender `bookings` (SESSION BOOKINGS / BOOKING DESK) and the visitor `homekid` (A KID FROM BACK HOME / A KID FROM YOUR OLD BLOCK).
  - **The one-hit wonder** is never a visitor; he lives only in copy as "a one-hit wonder".
  - **Web checks:** every name and the phrase are web-checked in Task 0 and anchored in `research/wave1_names_2026-10-27.md` (the spec's check pattern).
  - **Banned words:** copy never types a display name in lowercase (use `{name:<id>}`), never uses a BLOCK word (shoot, bet, lean, kill, …), never says OK, CRED, STUDIO TWO or a real studio, and never says "the projects".
  - **Approval:** all new copy goes on the user's approval list.
- **Phone first:** every tappable control ≥ 44 px at 844×390 and 667×375, inside the gui's safe-area box.
- **Budget:** 0 new lights, 0 new parts under `Workspace.OKStudio`, and tagged interactables stay 12. The 4 light-cap checks (61 lights vs 36) stay the known baseline.
- **Test hold:** as in 1b. `tools/test.py` sets `WalkInsPaused` for the suite, and only `tools/walkins_pause_off.lua` removes it.
- **Test numbers:** Studio `t66`–`t69`.
  - Edit check: `t69_check`.
  - Play pairs by suffix letter, with the server file first: `t66a_play_server` / `t66b_play_client`, and `t67a` / `t67b`.
  - The client-only case is `t68_play_client`.
  - Markers: `T69 OK`, `T66A PLAY OK`.
  - Each play file finishes in under 90 s and starts with its own `fresh()` (unseat, teleport, Phone `Quiet`, WalkIns `Reset`, Career `Reset`, body in a pcall with cleanup and rethrow).
  - Staging for a client file goes after the server file's cleanup.
- **Standing limits:** never save or publish the place; no uploads; no Robux; no free-model scripts; no player-typed text; Abbey Road photos reference only; don't change the light cap or another session's imports.

## Review Focus

1. **The chip shows what was paid.**
   - The input: an XP award the gate refuses or trims ('daily', a `max` trim).
   - The expectation: the result card's XP chip shows the XP actually paid, and no chip when it was 0. It never shows the content's number.
   - The test: t66a's fourth pick, after `dailyMax` 3 is used up, pays 0 and shows no XP chip.
2. **One roll, always.**
   - The input: a `ready` choice.
   - The expectation: `Resolve` makes exactly one `rng` draw, as for any non-sure choice, so the sim's seeds and every SetRng-forced test keep their sequences.
   - The test: walkin_rules_spec counts the draws.
3. **Level comes from the server.**
   - The input: a client that sets its own `Level` attribute.
   - The expectation: readiness reads `prof.level` on the server and is unchanged.
   - The test: t67a sets the player's `Level` attribute to 10 on the server, and `ReadyChance` is unchanged, because it reads `prof.level`. A client's own attribute writes never reach the server at all.
4. **A second kid while the first is on his way.**
   - The input: a second hometown pick while `payback_homekid` is still queued.
   - The expectation: it pays the XP, books nothing, sets `planted` nil (no Plant sound), and its note promises no visit.
   - The test: t66a.
5. **The edges of the card.**
   - The phone switched off: the card never shows.
   - DISMISS or an opened DM timing out: nothing applies.
   - Fewer than 10 walk-ins ever: the timer never sends it.
   - The tests: t69_check (the card's gates and Config), t66a (DISMISS), and Task 3's CLI cases (the visits gate and the weekly cap through `WalkInRules.Pick`).

## Shared shapes

- **`WalkInRules.Readiness(career, level, cfg) -> number`** (0..1):
  - It averages `min(level / cfg.level, 1)`, `min(career.placements / cfg.placements, 1)`, `min(career.followers / cfg.followers, 1)` and `min(max(career.aura, 0) / cfg.aura, 1)`.
  - A missing stat counts as 0, and a missing level as 1.
- **`WalkInRules.ChoiceChance(choice, career, odds) -> number`:**
  - For `choice.ready`, it returns `math.floor(odds.min + (odds.max - odds.min) * Readiness(career, career.level, odds.ready) + 0.5)`, clamped to `odds.min..odds.max`.
  - Otherwise it returns `Chance(choice.odds or 50, career, odds)`.
  - `Resolve` and CareerSim's greedy `expectedMoney` both call it.
- **`Resolve`** keeps its draws exactly: rare first when set, then sure, then one `rng(1, 100) <= ChoiceChance(...)`. Its `deltas` gain `xp = outcome.xp or 0`.
- **Config:**
  - `Config.XP.Sources.Phone = { max = 60, dailyMax = 3 }`
  - `Config.WalkIns.Odds.ready = { level = 7, placements = 5, followers = 30000, aura = 600 }`, which reuses `Odds.min` 10 and `Odds.max` 90
- **Content fields:**
  - An outcome may carry `xp` (a whole number), only on a phone card's outcome, `0..60`.
  - A choice may carry `ready = true`, with no `odds`, no `sure`, no `rare`, and both `good` and `bad`.
  - `walkins_data_spec` rejects any unknown outcome key and any unknown choice key.
- **Ids:**
  - the sender `bookings` (kind `sender`, sig `none`)
  - the visitor `homekid` (kind `local`)
  - the card `two_sessions` (`source = "phone"`, `app = "MESSAGES"`, `needs = { visits = 10 }`, `cap = { group = "sessions", per = "week", max = 2 }`)
  - the follow-up `payback_homekid` (walk-in)
  - outcome keys `home`, `wentoff`, `notready`, `blewup` and `localhit`
- **Result payload:** `chips` gains kind `"xp"`, label `"+N XP"`, from what `AddXP` returned, between money and Aura in chip order. There's no tag change: every win and loss outcome here also moves a tagged stat.
- **Telemetry:** for a `ready` choice, `CardChoice`'s `value` is `math.floor(readiness * 100 + 0.5)`.
- **Hooks:**
  - `_StudioPhoneHook` `ReadyChance(uid, cardId, index) -> number`: the chance the server would use right now (it reads `prof.level`).
  - `_StudioTestHook` `ResetXPCount(uid, source)`: clears `xpLog.count[source]` (and the source's group sum) for the current UTC day, so a Play run can pay card XP again on the same day. It is Studio only, like every hook.
- **Sim:**
  - `apply` adds `d.xp` to `sim.xp` and calls `refreshLevel` at once.
  - Every `Resolve` and `expectedMoney` call gets a career copy with `level = sim.level`.
  - `Run` returns `cardXP`.
  - `input.prefer = { [cardId] = choiceIndex }` makes the random policy always take that choice on that card.

## Rulings in this plan

- **XP only on phone items.** The validator rejects `xp` on walk-in outcomes until a later wave wires `WalkIns.apply`. Only this card uses it — YAGNI — cost if wrong: a later card that wants walk-in XP adds the WalkIns half.
- **The banner goes above the cards.** It moves into its own ScreenGui, `OK_LevelUp`, with DisplayOrder 10, above `OK_WalkIn` (8) and `OK_Phone` (9), so a card's level-up is never hidden. Its position, size, timing and `LastLevelUp` attribute are unchanged — cost if wrong: for 3.5 s the banner covers the top of an open card on phones.
- **The one-hit wonder is a phrase, not a name.** Both rosters show "a one-hit wonder" in the card's line and choice 2. The design's fiction name A FORMER CHART ACT isn't used, because he has no figure and no visitor id — cost if wrong: the fiction roster reads like the parody one on this card; the fix is a no-figure name entry with `{name:<id>}` in the copy.
- **DISMISS stays.** Taking neither applies nothing, as with every DM — cost if wrong: a player can sidestep the dilemma.
- **The hometown note is generic.** "The ones you help early remember you." It promises no visit, so it stays true when the comeback is already queued — cost if wrong: a little less anticipation.
- **The money floor is checked in the CLI only.** `t46` keeps the 20-seed targets and the Config diffs, and prints the 20-seed share without asserting the floor, because 200 seeds would outrun Studio's call limit. `pacing_spec` asserts the 200-seed floor — cost if wrong: Studio never re-checks the floor; the CLI does every run.
- **The hometown kid is listed first.** Greedy and chaser take him, the new "homer" policy pins the Legend floor for that player, and the "climber" policy covers the opposite player — cost if wrong: none; both extremes are measured.
- **The XP count reset.** The phone's XP allowance is a per-day count in the profile that Career `Reset` doesn't touch, so a second run the same day would find it used up. `ResetXPCount` is the test seam, and each two-sessions server file's `fresh()` calls it — cost if wrong: none outside Studio.
- **The readiness hook.** Tests read the chance through `ReadyChance` and force the roll on either side of it, because no hook can lower a test player's level — cost if wrong: a hook bug hides a readiness bug; t67's two runs at different stats also check that the chance moves.

## Execution waves

| Wave | Task | Studio |
|---|---|---|
| A | 0 (names, baseline) | none |
| B | 1 (pure rules, validator, Config) | none |
| C | 2 (sim and pacing) | none |
| D | 3 (content) | none |
| E | 4 (server) | sync (incl. OK/Main and Modules/CareerSim); t69, t46, t40; play t43 t51–t53 t57 t58 t65 t66 t67 |
| F | 5 (client) | sync; play t15 t45 t57 t58 t62 t65 t66 t67 t68 |
| G | 6 (integration, review, report) | full suite, final review, snapshot, report |

Tasks run one at a time: one implementer at a time, and one Studio. Every task runs implementer → spec and quality review → fixes → Studio integrator where it has one. Task 6 runs one whole-branch review with four lenses (server exploits, economy and pacing, the client at both phone sizes, regressions in t40–t65) plus the senior reviewer, a skeptic per finding, then one fix dispatch.

---

### Task 0: Names and the 200-seed baseline

**Files:**
- Modify: `research/wave1_names_2026-10-27.md` (new section "## Two sessions (2026-10-29)" with anchors `#bookings` and `#homekid`, plus a note on "one-hit wonder")
- Create: `research/two_sessions/baseline_2026-10-29.md`

- [ ] **Step 1: Web-check the names.**
  - **What to check:** SESSION BOOKINGS, BOOKING DESK, A KID FROM BACK HOME, A KID FROM YOUR OLD BLOCK, and the phrase "one-hit wonder". Check each against real artists, labels, songs, albums, shows and companies, the way the 1a section records its checks.
  - **What to record:** the search terms, what came back, and the verdict, as clear, flagged or replace.
  - **If a name is flagged:** propose a replacement and check it the same way. A flagged name is a report item, not a blocker.
- [ ] **Step 2: Measure the baseline.**
  - **The script:** a scratch script (in the scratchpad, never in `spec/`) runs today's `pacing_spec` policies on the 200 seeds `100000 + 7919 * i`, `i = 0..199`.
  - **What to record:** the random player's median steady share to 4 decimals, plus greedy, chaser and spend-down maxima, THE HALL median, p10 and p90, and the earliest Legend day.
  - **Where:** in `baseline_2026-10-29.md`, together with the exact seed rule and the deck's commit.
  - **Expect:** about 0.3459 (the code map's run). If it's off by more than 0.002, say so and record the measured value; the measured value is what Task 2 pins.
- [ ] **Step 3: Commit** `T0: names checked, 200-seed baseline`.

### Task 1: Pure rules, validator, Config

**Files:**
- Modify: `src/ReplicatedStorage/OK/Modules/WalkInRules.lua`, `src/ReplicatedStorage/OK/Config.lua`, `spec/economy_fixture.lua`
- Modify: `spec/walkin_rules_spec.lua`, `spec/walkins_data_spec.lua`

**Interfaces:**
- Produces: `Readiness`, `ChoiceChance`, the `xp` in `deltas`, the two Config entries, and the validator rules (Shared shapes).

- [ ] **Step 1: Write the failing tests.**
  - **walkin_rules_spec, `Readiness`:** with `cfg = { level = 7, placements = 5, followers = 30000, aura = 600 }`:
    - (LV 2, 0 placements, 3,300 followers, Aura 63) → 0.126 ± 0.001
    - (6, 3, 25000, 400) → 0.739 ± 0.001
    - (10, 12, 90000, 1500) → 1
    - Aura −200 counts as 0
    - a nil level counts as 1
  - **walkin_rules_spec, `ChoiceChance`:**
    - a `ready` choice at readiness 0 → 10, at 1 → 90, and at the day-5 career above → 69
    - a non-ready choice equals `Chance(odds or 50, …)`
  - **walkin_rules_spec, `Resolve` with a `ready` choice:**
    - a counting `rng` stub sees exactly one call (two with `rare` set)
    - `rng → chance` gives "good" and `chance + 1` gives "bad"
    - `deltas.xp` equals the outcome's `xp`, and is 0 when absent
  - **walkins_data_spec, scratch cards.** The spec has no scratch harness yet: move the card-loop body (`checkChoices`, `checkOutcome`, `checkPhoneChoices`) into `checkCard(card)` and run it over the live deck as now. For each scratch card, note `#fails`, call `checkCard`, assert the new failures contain the named message (none for the valid DM), then truncate `fails` back. The cases:
    - `xp` on a walk-in outcome fails "xp only on phone items"
    - `xp = 61` on a phone outcome fails "xp <= 60"
    - an unknown outcome key (`xpp = 5`) fails "unknown outcome key xpp"
    - an unknown choice key fails
    - a `ready` choice with `odds` fails
    - a `ready` choice without `bad` fails
    - the valid two-choice ready DM passes
  - **economy_fixture:** `XP_PHONE = { max = 60, dailyMax = 3 }` and `READY = { level = 7, placements = 5, followers = 30000, aura = 600 }`.
- [ ] **Step 2: Run the specs** (`sh tools/spec.sh walkin_rules walkins_data`) → FAIL for the missing functions and rules.
- [ ] **Step 3: Implement** the Shared shapes in `WalkInRules`, add the two Config entries, and add the validator rules. The live deck must still pass, because no live outcome uses an unknown key; if one does, report it rather than renaming it.
- [ ] **Step 4: Run** `sh tools/spec.sh` → all PASS.
- [ ] **Step 5: Commit** `T1: readiness, choice chance, xp deltas, validator`.

### Task 2: The sim and the pacing spec

**Files:**
- Modify: `src/ReplicatedStorage/OK/Modules/CareerSim.lua`, `spec/pacing_spec.lua`, `spec/career_sim_spec.lua`, `build/t46_check.lua`

**Interfaces:**
- Consumes: `ChoiceChance` and `deltas.xp` (Task 1), and `BASELINE_SHARE_200` (Task 0).
- Produces: `cardXP`, `input.prefer`, and the policies "homer" and "climber".

- [ ] **Step 1: Write the failing tests.**
  - **career_sim_spec:**
    - a scratch phone card with `xp = 40` raises `sim.xp` by 40 and the level at once, within the same day
    - `cardXP` sums it
    - `prefer = { two = 2 }` makes the random policy pick choice 2 on card `two`
    - greedy's `expectedMoney` on a `ready` choice uses `ChoiceChance`, checked with a stub career at readiness 1, so 90%
  - **pacing_spec:**
    - `SEEDS_200` and `BASELINE_SHARE_200` (the Task 0 literal)
    - the random 200-seed median steady share ≥ `BASELINE_SHARE_200 − 0.005`
    - every other guardrail also runs on `SEEDS_200` with the same asserts as on the 20 seeds (the per-seed ceiling for all policies; THE HALL, Legend and phone Aura for random; Legend for homer; THE HALL for climber), with a second summary line for the 200 seeds. A guardrail that today's deck already fails on 200 seeds (Task 0's baseline shows which) is asserted as "no worse than the baseline" and named in the report.
    - the 20-seed median floor assert is removed; its ceiling stays
    - a "homer" block (`prefer = { two_sessions = 1 }`): Legend nil or ≥ 15 on each of the 20 seeds
    - a "climber" block (`prefer = { two_sessions = 2 }`): THE HALL median 4–6 and p90 ≤ 7
    - every existing assertion stays
  - **t46:**
    - mirrors the new literals both ways: `FIXTURE` (a literal copy of economy_fixture) gains `XP_PHONE` and `READY`, and the live `economy` table gains `XP_PHONE = copy(Cfg.XP.Sources.Phone)` and `READY = copy(Cfg.WalkIns.Odds.ready)` (use `Cfg.WalkIns`, because `WI` is declared later); `PACING.odds.ready` matches `Config.WalkIns.Odds.ready`
    - drops only the 20-seed floor assert, and prints the 20-seed share in its OK line
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** the sim changes (Shared shapes, Sim) and the spec blocks. pacing_spec's own odds table `ODDS` gains `ready = E.READY` (the sim passes it to `Resolve` and `ChoiceChance`), career_sim_spec's `ODDS` gains `ready` for its ready-choice case, and t46's `PACING.odds` gains `ready` to match the live `Config.WalkIns.Odds.ready`.
  - Runtime: the whole pacing spec must finish in under 90 s in the CLI. If it's slower, stop and report the timing; don't drop a policy.
- [ ] **Step 4: Run** `sh tools/spec.sh` → PASS on today's deck, which has no `two_sessions` card yet: "homer" and "climber" equal random, and the floor holds against its own baseline.
- [ ] **Step 5: Commit** `T2: card XP in the sim; 200-seed floor; homer and climber`.

### Task 3: The content

**Files:**
- Modify: `src/ReplicatedStorage/OK/Data/WalkIns.lua` (the visitors `bookings` and `homekid`, the card `two_sessions` in the phone section, and the follow-up `payback_homekid`)

**Interfaces:**
- Consumes: the Task 0 names (use replacements if any were flagged), the Task 1 fields, and the Task 2 pacing.

- [ ] **Step 1: The visitors.**
  - `bookings`: kind `sender`, names SESSION BOOKINGS / BOOKING DESK, style "session bookings", sig `none`, a colour clear of the other senders, and `check` `#bookings`.
  - `homekid`: kind `local`, names A KID FROM BACK HOME / A KID FROM YOUR OLD BLOCK, style "up and coming", a sig from `Visitor.SIGS` other than blockkid's `cap`, and `check` `#homekid`.
- [ ] **Step 2: The card** (copy is exact).
  - **The card:** `two_sessions`, `visitor = "bookings"`, `source = "phone"`, `app = "MESSAGES"`, tag "TWO SESSIONS · TODAY ONLY" (a tag never types a display name), `needs = { visits = 10 }`, `cap = { group = "sessions", per = "week", max = 2 }`.
  - **line:** "two sessions came in for today. a kid from your hometown wants you on his first tape. a one-hit wonder wants a comeback beat. you can only do one."
  - **Choice 1:** "Work with the kid from your hometown." `sure = true`, `good`:
    - key `home`, headline "YOU WENT HOME", tone win, `xp = 40`, `followers = 100`
    - text "He's raw, but he listens. You learned more tonight than a month of tutorials."
    - line "you actually came. i won't forget it"
    - note "The ones you help early remember you."
    - `plant = { id = "payback_homekid", at = { 10, 16 } }`
  - **Choice 2:** "Work with the one-hit wonder." `ready = true`.
    - `good`: key `wentoff`, headline "THE SESSION WENT OFF", tone win, `aura = 40`, `xp = 10`, text "He brought his old fans with him. People noticed you.", line "told you i still got it".
    - `bad`: key `notready`, headline "YOU WEREN'T READY", tone loss, `aura = -30`, text "He played his one hit four times and left. People saw.", line "call me when you're ready".
- [ ] **Step 3: The follow-up** `payback_homekid`.
  - `visitor = "homekid"`, tag "HOMETOWN · FIRST TAPE", line "tape's out. the first beat is yours. remember back home?"
  - `resolve = { odds = 70, … }`
  - `good`: key `blewup`, headline "HE BLEW UP", tone win, `money = 400`, `placements = 1`, `followers = 800`, `aura = 10`, text "His first tape took off, and your beat opens it.", line "you were there before anybody. this one's yours".
  - `bad`: key `localhit`, headline "LOCAL HIT", tone neutral, `money = 150`, `followers = 300`, text "The tape stayed local. It still plays back home.", line "it's big back home at least".
- [ ] **Step 4: Add the gate cases and run.**
  - **The gate cases** (in walkins_data_spec, against the live deck). Each `Pick` uses a fresh state and opts like `CareerSim.pickNext`'s, including `day` and `week` (CapOk refuses a capped card when its key is nil); the visits 9 and 10 runs differ only in `visits`. `WalkInRules.Pick` for `source = "phone"` never returns `two_sessions` with `opts.career.visits = 9`, across 500 seeded picks. It can return it with `visits = 10`. After two `CountCap` calls in one week, `CapOk` refuses it, and in the next week it allows it again.
  - **Run** `sh tools/spec.sh` → `walkins_data` PASS, and `pacing` against every guardrail in Global Constraints, with the 200-seed floor included.
  - **On a PASS:** record the pacing line in the report.
  - **On a FAIL:** don't tune the copy or the numbers past the design. Stop and report BLOCKED with the failing numbers and the levers the design names: the comeback's money, the cap, the XP. The orchestrator takes them to the user.
- [ ] **Step 5: Commit** `T3: two sessions, same day (card, kid, comeback)`.

### Task 4: The server

**Files:**
- Modify: `src/ReplicatedStorage/OK/Systems/Phone.lua`, `src/ReplicatedStorage/OK/Systems/WalkIns.lua` (`Chips` gains xp; `Choose` passes level; header), `src/ServerScriptService/OK/Main.server.lua` (the `_StudioTestHook` command `ResetXPCount`); in `Phone.lua`, `track()` gains a `value` argument that the choice path passes for a ready choice (`Funnel.Event` already takes `value`)
- Create: `build/t69_check.lua`, `build/t66a_play_server.lua`, `build/t67a_play_server.lua`
- Modify: `build/t40_check.lua` (only if it enumerates something this changes), `build/t46_check.lua` (Task 2's literals)

**Interfaces:**
- Consumes: Tasks 1–3.
- Produces: the `xp` chip, the `ReadyChance` hook and the telemetry `value`.

- [ ] **Step 1: Write the failing tests.**
  - **`t69_check` (Edit):**
    - `Config.XP.Sources.Phone` equals `{ max = 60, dailyMax = 3 }`
    - `Config.WalkIns.Odds.ready` equals READY
    - the `two_sessions` card is a phone card with `needs.visits = 10` and cap `sessions`/week/2
    - `payback_homekid` exists
    - Marker `T69 OK`.
  - **`t66a_play_server`** (hometown):
    1. `fresh()` (which also calls `ResetXPCount(uid, "Phone")`). Turn Phone `Quiet` off only around each Pop and Open, and back on right after, so no timer pop lands mid-test.
    2. Read the player's XP through `_StudioTestHook` GetProfile.
    3. Pop `two_sessions`, Open, Choose 1.
    4. XP rose by 40. The result chips include `"+40 XP"` and `"+100 FOLLOWERS"`. `planted` is true, and `payback_homekid` is queued.
    5. A second Pop, Open and Choose 1 the same day: XP +40 (`dailyMax` 3 allows it), `planted` nil, and the queue still holds one `payback_homekid`.
    6. A third and a fourth pick use up `dailyMax`: the fourth pays 0, and its chips have no XP chip.
    7. DISMISS on a fifth pop changes nothing.
    8. WalkIns `AdvanceVisits` to the entry's `at`, with SetRng forcing good. The kid walks in, and `blewup` pays $400, +1 placement and +800 followers.
    9. Tail for t66b, after the cleanup: `ResetXPCount(uid, "Phone")`, `Quiet(uid, false)`, then Pop and Open `two_sessions`, leaving the DM open.
  - **`t67a_play_server`** (one-hit wonder):
    1. `fresh()` (with `ResetXPCount`), then Career `Set { placements = 0, followers = 0, aura = 0 }`.
    2. `c1 = ReadyChance(uid, "two_sessions", 2)`. It must be in 10..90 and equal `ChoiceChance` for the player's level, computed from the server's `prof.level` in the test.
    3. SetRng to `c1 + 1` (clamped to 100), then Pop, Open and Choose 2 → `notready`: Aura −30 and no XP chip.
    4. Set the player's `Level` attribute to 10 on the server: `ReadyChance` still returns `c1`. Restore the attribute.
    5. Career `Set { placements = 12, followers = 90000, aura = 1500 }` → `c2 = ReadyChance(...)` > `c1`. SetRng to `c2`, then Choose 2 on a new pop → `wentoff`: Aura +40 and XP +10.
    6. The gates are proven in the CLI (Task 3, Step 4), not here: the phone's random ticks can't show a card is ever eligible.
    7. Tail for t67b, after the cleanup: Career `Set { placements = 0, followers = 0, aura = 0 }`, SetRng to 100 (a sure miss), `Quiet(uid, false)`, then Pop and Open `two_sessions`, leaving the DM open.
  - **The Funnel value** is checked in t67a step 5: call `_StudioTestHook` `ResetFunnelEvents(uid)` before that Choose 2. Afterwards `FunnelEvents` holds exactly one `CardChoice`, whose `value` equals `math.floor(Readiness(career, level, READY) * 100 + 0.5)`, computed from the stats and level read through the hooks just before the choice.
- [ ] **Step 2: Integrator red run** (before syncing): `--edit t69` and `--play t66 t67` → FAIL.
- [ ] **Step 3: Implement.**
  - **Choose paths:** `Phone.Choose` and `WalkIns.Choose` pass `Resolve` a copy of `Career.Get(p)` with `level = prof.level`.
  - **Paying XP:** `Phone.apply` calls `ctx.Data.AddXP(p, deltas.xp, "Phone")` when `xp > 0`, and sets `applied.xp` to what it returned.
  - **Chips:** `WalkIns.Chips` adds the `xp` chip only when `(applied.xp or 0) > 0`. Walk-in results never set `applied.xp`, so they keep their chips exactly.
  - **The hooks:** `ReadyChance(uid, cardId, index)` on the phone hook, and `ResetXPCount(uid, source)` on `_StudioTestHook`.
  - **Telemetry:** `CardChoice`'s `value` for a ready choice.
  - **Headers:** WalkIns' "No XP" line becomes "No XP from walk-ins; phone items may pay XP through Config.XP.Sources.Phone", and the Data phone section's rule line adds "and XP up to 60 (Config.XP.Sources.Phone)".
- [ ] **Step 4: Integrator.**
  1. Sync `OK/Config`, `OK/Main` (the `ResetXPCount` hook), `Modules/WalkInRules`, `Modules/CareerSim` (Task 2's sim, which t46 loads live), `Systems/Phone`, `Systems/WalkIns` and `Data/WalkIns`. The `--dry` run must list nothing else under src as changed; report anything extra instead of syncing it.
  2. `--edit t40 t46 t69` → PASS.
  3. `--play t43 t51 t52 t53 t57 t58 t65 t66 t67` → PASS. The t66b/t67b client halves come in Task 5, so a run without them only stages.
  4. Run `walkins_pause_off`, and commit the manifest.
- [ ] **Step 5: Commit** `T4: phone XP, readiness at the server, xp chip, hook`.

### Task 5: The client

**Files:**
- Modify: `src/ReplicatedStorage/OK/Modules/UITheme.lua` (`stat.xp`), `src/ReplicatedStorage/OK/Modules/HUD.lua` (the banner moves into its own ScreenGui `OK_LevelUp`: DisplayOrder 10, `ResetOnSpawn = false`, `IgnoreGuiInset` and insets as OK_UI; `LastLevelUp` stays an attribute of OK_UI), `build/t62_play_client.lua` (step 9 only)
- Create: `build/t66b_play_client.lua`, `build/t67b_play_client.lua`, `build/t68_play_client.lua`
- Modify: `build/t62_play_client.lua` (step 9: find the banner at `OK_LevelUp.LevelUp`, and replace the ZIndex comparison with `OK_LevelUp.DisplayOrder > OK_UI.DisplayOrder`; header comment to match)

- [ ] **Step 1: Write the failing tests.**
  - **`t66b`** (after t66a's tail): at forced 667×375 and 844×390 minus the inset, the open DM shows two choices plus DISMISS, every button ≥ 44 px, inside the box. Choose 1, then:
    - the inline result shows the chip "+40 XP" in `Theme.stat.xp`
    - `SoundLog` ends with `Win,Plant`
    - the HUD float log gains an entry whose text is "+40 XP"
  - **`t67b`** (after t67a's tail): Choose 2 on the open DM. The inline result shows headline "YOU WEREN'T READY" and the chip "-30 AURA" in the cold colour, with no XP chip. `SoundLog` ends with `Loss`, and on R15 `LastReaction` is "sit".
  - **`t68`** (static): `PlayerGui.OK_LevelUp.DisplayOrder` > `OK_Phone.DisplayOrder` and > `OK_WalkIn.DisplayOrder`; `OK_LevelUp.ResetOnSpawn == false`; the banner label keeps its 420×64 size and its position. That `LastLevelUp` still updates on OK_UI is proven by t15/t15b in Step 4.
- [ ] **Step 2: Integrator red run** `--play t66 t67 t68` → the client files FAIL.
- [ ] **Step 3: Implement** the theme colour, the chip colour in both card UIs' `chipColor` (the per-kind branch reads `Theme.stat`, which now has `xp`), and the banner's own ScreenGui.
- [ ] **Step 4: Integrator.**
  1. Sync `Modules/UITheme` and `Modules/HUD`, plus `Modules/PhoneUI` and `Modules/WalkInUI` if they changed.
  2. `--play t15 t45 t57 t58 t62 t65 t66 t67 t68` → PASS.
  3. Run `walkins_pause_off`, and commit the manifest.
- [ ] **Step 5: Commit** `T5: xp chip, banner above the cards`.

### Task 6: Integration, review and report

**Files:**
- Modify: `README.md` ("Milestone 12 'Two sessions'"), `../OK_GAME_TRACKER.md`
- Create: `TWO_SESSIONS_REPORT.md`

- [ ] **Step 1: Integrator.** Run the full suite with `caffeinate -d python3 -I tools/test.py -v` → only the 4 light-cap checks fail.
- [ ] **Step 2: Final review** (Execution waves). Fix the survivors in one dispatch, each with a regression test.
- [ ] **Step 3: Close out.**
  1. Snapshot `v35_two_sessions`, then `python3 -I tools/export_rbxm.py`, then checkpoint.
  2. Write the README section, the report and the tracker update.
     - The report covers what's in, how sure, the pacing line on 20 and 200 seeds against the baseline, the Legend day for random and homer, THE HALL for climber, and Needs you.
     - Needs you lists:
       - every new name, with the Task 0 verdicts
       - every new line
       - the amounts, as switchable calls
       - the rulings above
  3. Release the Studio lease, and run `walkins_pause_off`.
- [ ] **Step 4: Commit** `T6: two sessions done`, adding `TWO_SESSIONS_REPORT.md`.

## Plan-check amendments (2026-10-29)

Four lens reviewers (test staging, fit to the code, the economy and the player, regressions) read the first draft against the code and the design, and a skeptic tried to disprove each finding: 30 survived (16 distinct after duplicates), 7 were refuted. Each change is written into the section an implementer reads; this list is the index.

- **The card's tag (blocker, 3 reports):** a tag never types a display name, so it is "TWO SESSIONS · TODAY ONLY".
- **The sync list (blocker, 2 reports):** Task 4 also syncs `OK/Main` (the `ResetXPCount` hook) and `Modules/CareerSim` (Task 2's sim, loaded live by t46).
- **The banner (3 reports):** t62 step 9 moves to `OK_LevelUp` and compares DisplayOrder; `LastLevelUp` stays on OK_UI; `OK_LevelUp.ResetOnSpawn = false`; t68 is a static check, and t15/t15b prove the level-up path.
- **pacing_spec's odds table** is `ODDS`, not `PACING.odds`; t46's fixture gains `XP_PHONE` and `READY` both ways.
- **The 200-seed set** runs every guardrail, not only the floor; the climber also checks THE HALL's median; the runtime limit stops the task instead of dropping a policy.
- **The scratch-card harness** in walkins_data_spec is new (`checkCard`).
- **The gate cases** carry `day` and `week` in the Pick opts.
- **Quiet** is off only around each Pop and in the client tails.
- **The Funnel value** is checked in t67a, through `track()` gaining `value`.
- **The xp chip** treats a missing `applied.xp` as 0.
- **Review Focus 1** names t66a's fourth pick.
- **The one-hit wonder** is a phrase, not a name (new ruling).
- **Refuted:** 7 findings; see `.superpowers/sdd/2026-10-29-two-sessions/plancheck_result.json`.
