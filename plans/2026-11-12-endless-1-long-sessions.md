# Endless Play 1: Long Sessions and the Slower Climb — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Implementers write files and run CLI specs only; the controller is the only Studio client.

**Goal:** A five-hour session keeps paying through things worth doing, without beating the story.
- Story rewards shrink to a 25% floor after today's daily count instead of stopping.
- Button presses stay capped.
- Legend becomes a two-month goal through new levels above 10.
- The early game stays as it is.
- A pacing run with two five-hour players proves §3's bounds, and every number is reported.

**Architecture:**
- **Pure first.** `Modules/RewardGate` (new, pure) holds today's reward gate, moved out of DataService, plus the shrinking share, the fraction carry and a per-pair round counter.
  - DataService's gate becomes a thin wrapper around it.
  - `Systems/Career` already calls the DataService gate, so it changes nothing.
  - `CareerSim` routes every award it models through the same `RewardGate.Step`, using the fixture's literal copy of the sources.
- **Measure before wiring.** The sim gains two five-hour personas. A measurement picks the step size, or stops this plan, before any server code changes.
- **The climb.** `Config.Levels` grows from 10 to 20 entries. Levels 1–10 keep their thresholds. STUDIO LEGEND and the Legend nameplate move to level 20.

**Tech Stack:** Luau (Roblox), Roblox Studio via the built-in Studio MCP (`tools/mcp_call.py`), `tools/sync.py`, `tools/test.py`, `sh tools/spec.sh`, the `luau` CLI, Python 3.

**Spec:** `specs/2026-11-12-endless-play-design.md`:
- §3 no daily walls (all of it)
- §5 the slower climb
- §7 goals and anti-goals
- §8 building constraints
- §10's "Long sessions" lines

**One of three plans.** The spec splits into three plans:
1. **This plan:** the economy.
2. **`plans/2026-11-12-endless-2-story-web.md`:** the story web, roles and generated people, endless requests, everyday life, lifting the daily visit limits, and the archive.
3. **`plans/2026-11-12-endless-3-people-lives.md`:** ties, values, public image, switch-ups, the 10 arcs and the §4.8 grant ledger.

**Execution order:**
1. The rooms plan's R-T8..R-T16.
2. The people plan (`plans/2026-11-12-people-and-progression.md`) **without its Task 4**, which plan 2 supersedes.
3. This plan.
4. Plan 2.
5. Plan 3.

**Where the people plan already stands:**
- Its Task 1 titles are in Config: ten ranks, BEDROOM PRODUCER to STUDIO LEGEND.
- Its Task 8 gives CareerSim `input.persona = "solo"` and the `earned` output.
- Its Tasks 6–9 assertions are in `spec/pacing_spec.lua`.

**Line numbers** below are from 11-12, before the people plan ran. The pre-flight scan re-reads each one.

## Global Constraints

- **No git.** Every commit step is `sh .superpowers/g add -A src build spec specs plans research README.md && sh .superpowers/g commit -q -m "<task>: <what>"`.
  - Add `tools` when a tool changes.
  - Every message ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
  - Task prefix `E1-T<n>`.
- **One Studio client.** Implementers never call `tools/sync.py`, `tools/test.py`, `tools/mcp_call.py`, a build script or any `mcp__Roblox_Studio__*` tool. The controller does all of that under the Studio lease, in this order: red, sync, the module refresh, then green.
  - Run suites only with load under 30; one rerun per flake.
- **Scoped syncs only:** `python3 -I tools/sync.py --dry`, then each task's parent-qualified patterns. Never `--force`.
- **Selectors are substrings.** Use the full selectors given (`t140_`, `t142a`).
- **Pure modules** never touch Roblox globals and never `require`: `RewardGate` (new), `CareerSim`, `WalkInRules`, `CareerRules`, `LifeRules`.
  - CLI specs keep literal Config copies in `spec/economy_fixture.lua`.
  - `build/t46_check.lua` pins every literal to live Config.
- **Spec §3, verbatim:**
  - "today's `dailyMax` as the **full-pay count**"
  - "each further award pays a smaller share, shrinking to a **25% floor**"
  - "Press-a-button XP keeps its hard daily caps: Console, Mic, FireTap, CypherVote"
  - "Event counts aren't curved"
  - "The cold spell's 2-visits-a-day stays"
  - "No offline earnings"
- **The bounds** (spec §3). They hold for each five-hour persona on the 200 seeds:
  - its median money gained a day ≤ **2×** the random player's median
  - THE HALL on day ≥ **3** on every seed
  - Legend on day ≥ **30** on every seed

  If the tuning ranges here can't meet them, stop and bring every number to the user. The floor and these bounds are decided numbers.
- **The early game is unchanged.** Every assertion in `spec/pacing_spec.lua` before this plan stays green on both seed sets. That covers THE HALL 4–6 / p10 ≥ 3 / p90 ≤ 7, the people plan's first-monitors, home-studio, `earlyShare`, solo and cold blocks, the steady-share floor, and phone Aura ≤ 15.
- **Saves:** schema stays **v5**. The new log field `frac` is created lazily inside the gate.
- **Content:** new words come from `research/endless/copy_2026-11-12.md` §A and go on its approval list.
  - Rules: CAPS ranks.
  - Banned: OK branding (t50; the plain word "ok" is fine), CRED/Cred (t40), and BLOCK words.
  - No rank word may appear in a title or ribbon (`spec/life_rules_spec.lua`).
- **Test numbers:** t140–t143.
  - Edit checks are `tNNN_check.lua` with marker `T140 OK`.
  - Play files are `tNNNa_play_server.lua` with marker `T142A PLAY OK`. Each starts with its own `fresh()` and runs in a pcall with cleanup and a rethrow.
- **Standing limits:** never save or publish the place; no uploads; no Robux; no player-typed text; never flip `Config.Data.UseStoreInStudio`; no new audio, lights or parts.

## Review Focus

1. **The fraction carry at the floor.** A 1-point award past the full-pay count pays 0, 0, 0, 1, 0, 0, 0, 1… at the 25% floor. It never pays 0 forever and never more than one point at a time. An award of 0 (n ≤ 0) is refused "cap" and isn't counted. Test: `reward_gate_spec`.
2. **A new UTC day in the middle of the curve.** The first award of the next day pays in full, and the counts and fractions start again. Test: `reward_gate_spec` and t140.
3. **The hard caps still refuse "daily".** That means Console and Mic (the Activity group cap), FireTap, CypherVote, Daily, Weekly, Streak, Flip, Plaque and AuraHeal. A FireTap past 15 pays 0 "daily" exactly as today. Test: t140 and `reward_gate_spec`.
4. **The cypher farm.** Two friends alternate wins all evening. The same opponent set pays its round rewards (enter XP, win XP, money, Aura) only `Config.Cypher.PairDaily` times a UTC day. A round with a different set pays again. The win still counts in `prof.cypher.wins` and the Life event. Test: `reward_gate_spec` (PairStep) and t142a.
5. **A save from before the climb** with XP above 3,200 loads at its new level (≥ 10). It keeps a Legend nameplate it already owns. Nothing it owns is taken away. Test: t141 (LevelFor against stored XP; an owned `plate_legend` stays owned through `migrate`).

---

## Shared shapes

- **RewardGate** (Task 1), pure, in `src/ReplicatedStorage/OK/Modules/RewardGate.lua`:
  - `Step(log, rules, caps, source, n, now, day, curve) -> gained, why?`. This is today's DataService `gate` body (DataService.lua :427-451), with `M._now()` and `M._day()` passed in as `now` and `day`.
    - `log` is the table the gate keeps today: `{ day, count, group, last }`. It gains `frac = { [source] = number }`, reset with the day like the rest.
    - The reasons stay exactly as today: `"unknown"`, `"cooldown"`, `"daily"` and `"cap"`. One is new: `"frac"`, for a curved award that banked a fraction and paid 0.
  - **A rule with `curve = true` and a `curve` argument given:**
    - its `dailyMax` is the full-pay count
    - the award numbered `count + 1` pays `base * Share(count, dailyMax, curve) + frac[source]`, floored; the remainder goes back to `frac[source]`
    - it is counted even when it pays 0, and is never refused "daily"
    - before the full-pay count it pays `base` exactly as today
  - **A rule without `curve`, or `curve` nil:** behaves exactly as today.
  - `Share(paid, fullPay, curve) -> number`:
    - 1 when `paid < fullPay`
    - otherwise `math.max(curve.floor, 1 - curve.step * (paid - fullPay + 1))`
  - `PairStep(log, key, day, max) -> boolean`:
    - `log = { day, n = { [key] = count } }`, and the `n` counts start again on a new day
    - true while `n[key] < max`, counting the step
    - false once it reaches `max` (that step isn't counted)
    - mutates `log`
- **Config** (Task 3):
  - `Config.Rewards = { Curve = { step = <Task 2's pick>, floor = 0.25 } }`
  - `curve = true` on exactly these rules:
    - XP: `BeatSave`, `Delivery`, `Cypher`, `Phone`
    - Cred: `Delivery`, `Fire`, `Cypher`, `WalkIn`
    - Career:
      - `Delivery.followers`, `Delivery.aura`
      - `Fire.followers`
      - `Cypher.aura`
      - `WalkIn.aura`, `WalkIn.followers`
      - `Phone.aura`, `Phone.followers`
  - `Config.Career.Sources.WalkIn.placements`, `.hits` and `.sponsors` lose `dailyMax` (event counts, ruling 2). They keep `max = 1`.
  - `Config.Cypher.PairDaily = 4`.
- **The five-hour personas** (Task 2), as `spec/pacing_spec.lua`'s `LONG` table. These are Claude's calls, derived in the Task 2 header comment:

  | Field | Value | Derivation |
  |---|---|---|
  | `walkinsPerDay` | 53 | first visit at `FirstDelay`'s mean of 90 s, then one per `Gap` mean of 300 s plus a 40 s visit: 1 + ⌊(18000 − 90 − 40) / 340⌋ |
  | `phonePerDay` | 75 | each 340 s walk-in cycle leaves 240 s outside the visit and the 60 s `WalkInDueSeconds` window; at one pop per `Gap` mean of 150 s plus 15 s reading, that is ≈ 1.45 pops a cycle, × 53 ≈ 77, rounded down |
  | `requestsPerDay` | 8 | while the 21 first-time briefs last |
  | `beatSavesPerDay` | 20 | |

  The two personas:
  - **`solo5h`:** `persona = "solo"` (the people plan's Task 8: no FIRE, no cypher, not aired), plus `LONG`.
  - **`social5h`:** `LONG`, plus `firePerDay = 30` and `cypherWinsPerDay = 6`.
- **CareerSim inputs** (Task 2). Each is optional, and nil gives today's behavior:
  - `input.requestsPerDay` (default 3, today's `REQUESTS_PER_DAY`)
  - `input.firePerDay` (default `economy.firePerDay`)
  - `input.cypherWinsPerDay` (nil = today's one win on even days)
  - `input.beatSavesPerDay` (nil = today's lump `economy.beatSaveXP`)
  - `input.curve` (`false` forces the hard caps)
  - `economy.SOURCES = { xp = …, cred = …, career = … }`, literal copies of `Config.XP.Sources`, `Config.Cred.Sources` and `Config.Career.Sources` (flattened `"<source>.<stat>"`, as Career does)
  - `economy.CURVE`
- **Levels** (Task 4): `Config.Levels` has 20 entries. The first ten are exactly today's `{ 0, 100, 250, 450, 700, 1000, 1400, 1900, 2500, 3200 }`.
  - `Config.Ranks` has 20 entries. 1–9 are the people plan's, 10–19 are §A's new ranks, and 20 is `"STUDIO LEGEND"`.
  - `Config.Unlocks[20] = "STUDIO LEGEND · Legend nameplate on the rack"`, and `[10]`, `[12]`, `[14]`, `[16]` and `[18]` are §A's rank-up lines.
  - `plate_legend.level = 20`.

---

### Task 1: RewardGate, the pure gate (§3)

**Files:**
- Create: `src/ReplicatedStorage/OK/Modules/RewardGate.lua`, `spec/reward_gate_spec.lua`

**Interfaces:**
- Produces: `RewardGate.Step`, `RewardGate.Share` and `RewardGate.PairStep`, exactly as in Shared shapes. Tasks 2 and 3 call them; plan 2's request pay goes through `Step` via DataService.

- [ ] **Step 1: Write the failing spec** `spec/reward_gate_spec.lua`. It requires `../src/ReplicatedStorage/OK/Modules/RewardGate`, uses `CURVE = { step = 0.15, floor = 0.25 }` (a fixture value; Task 2 picks the real one) and ends by printing `SPEC OK`.
  - **Today's gate is unchanged** with rules `{ X = { amount = 10, dailyMax = 2 }, A = { xp = 5, cooldown = 600, group = "Activity" } }` and caps `{ Activity = 8 }`:
    - X pays 10, 10, then `0, "daily"`
    - A pays 5, then `0, "cooldown"` at now + 1, then 3 at now + 601 (the group cap), then `0, "cap"`
    - an unknown source gives `0, "unknown"`
    - n = −5 with `max` gives `0, "cap"`, not counted
  - **Curved:** rule `{ max = 100, dailyMax = 2, curve = true }`, n = 100:
    - awards pay 100, 100, 85, 70, 55, 40, 25, 25
    - `log.count` reaches 8
    - the result is never "daily"
  - **The fraction carry:** rule `{ amount = 1, dailyMax = 1, curve = true }`. Twelve awards after the first pay a total of 3 at the floor once the share reaches 0.25. Every 0 comes with `"frac"`, and `log.frac` stays in [0, 1).
  - **The new day:** after 8 curved awards, an award with `day + 1` pays 100, and `count`, `frac` and `group` start again.
  - **`curve` argument nil** with a `curve = true` rule: the third award gives `0, "daily"` (the hard cap stays when no curve is configured).
  - **Share:** `Share(0, 2, CURVE) == 1`, `Share(2, 2, CURVE) == 0.85`, and `Share(50, 2, CURVE) == 0.25`.
  - **PairStep:** with max 4, key `"7|9"` steps true four times, then false. `"7"` is true. A new day makes `"7|9"` true again.
- [ ] **Step 2:** `sh tools/spec.sh reward_gate` → FAIL (module missing).
- [ ] **Step 3: Implement** `RewardGate.lua`.
  - The non-curve path is DataService's `gate` body moved verbatim, with `now` and `day` as arguments.
  - The header comment states that it is pure, that DataService and CareerSim both run it, and the meaning of `frac`.
- [ ] **Step 4:** `sh tools/spec.sh reward_gate` → PASS. `sh tools/spec.sh` → PASS (nothing else uses it yet).
- [ ] **Step 5: Commit** `E1-T1: the reward gate as a pure module, with the shrinking share`.

### Task 2: The five-hour players in the sim, and the step size (§3 bounds; measure first)

**Files:**
- Modify: `src/ReplicatedStorage/OK/Modules/CareerSim.lua`. Every award the sim models goes through one helper, `award(sim, kind, source, n) -> gained`, which runs `RewardGate.Step` (passed in as `input.gate`) on `sim.logs[kind]`.
  - The sim's day number is `day`. Its clock `now` advances 120 s per award, so no curved source's cooldown (BeatSave, 60 s) ever refuses.
  - **Money:**
    - `earn` callers pass their source: walk-in money `"WalkIn"`, requests `"Delivery"`, dailies `"Daily"`, the streak `"Streak"`, the weekly `"Weekly"`, FIRE `"Fire"`, cypher `"Cypher"`.
    - Negative walk-in money and costs stay ungated, as today.
  - **XP:**
    - deliveries `"Delivery"`, the weekly `"Weekly"`, dailies `"Daily"`, phone card XP `"Phone"` (replacing `gateXP`, :332)
    - the cypher as **two** `"Cypher"` awards, entry XP then win XP (`economy.cypherEnterXP` 10 and `cypherWinXP` 30 replace the lumped `cypherXP` 40), as BeatBattles pays them. Each entered round without a win pays entry XP only.
    - beat saves `"BeatSave"` × `beatSavesPerDay` when given
    - the activity lump stays as it is
  - **Stats:** `addStat` callers that model an award pass `"<source>.<stat>"`: the feeds, walk-in and phone outcomes, and the plaque. The heal keeps its own path.
  - **New inputs** per Shared shapes: `requestsPerDay`, `firePerDay`, `cypherWinsPerDay`, `beatSavesPerDay`, `curve`.
  - `Run` also returns `moneyPerDay = earned / days`.
- Modify: `spec/economy_fixture.lua` (`SOURCES`, `CURVE`); `build/t46_check.lua`, whose FIXTURE pins `SOURCES` against live Config (every rule, every key) and `CURVE` (added in Task 3: until then t46 accepts a missing `Config.Rewards`).
- Create: `spec/golden/sim_random_20.lua`, written in Step 1 from **today's** code. It returns, per seed of `CareerSim.Seeds`, the random player's `{ studioTwoDay, legendDay, steadyShare (rounded to 1e-6), earned, cardXP, phonePops }`.
- Modify: `spec/career_sim_spec.lua`, `spec/pacing_spec.lua` (the `LONG` block), `src/ReplicatedStorage/OK/Modules/CareerSim.lua`'s header comment.
- Create: `research/endless/pacing_2026-11-12.md` §1.

**Interfaces:**
- Consumes: `RewardGate.Step` (Task 1); the people plan's `persona = "solo"` and `earned`.
- Produces:
  - `input.gate` (required once `economy.SOURCES` is given)
  - the new inputs, and `moneyPerDay`
  - `LONG` and the two personas in `pacing_spec`
  - the chosen `CURVE.step`, which Task 3 copies into Config

  Plan 2 adds request income to the same personas.

- [ ] **Step 1: Pin today.** Before any CareerSim edit, write a short script, run with `luau`, that produces `spec/golden/sim_random_20.lua` from the current sim and pacing inputs. Commit it alone: `E1-T2: golden random runs before the gate`.
- [ ] **Step 2: Write the failing tests.**
  - **career_sim_spec:**
    - **Hard caps, golden match:** with `input.curve = false` and `SOURCES` given, the random player on all 20 seeds equals the golden file field by field (the route through the gate changes nothing).
      - Routing every award through the gate can expose a cap the sim never modeled before. For example, a walk-in outcome above `WalkIn.max`, or cypher XP paid as one lump where the server pays two awards.
      - A mismatch traced to such a difference that was already there before this plan is a **ruling, not a stop**. The ledger records the field that moved and why. The golden file is then re-pinned with that fix alone, before the curve goes in.
    - **The curve on a fixture:** one curved source `{ amount = 100, dailyMax = 1, curve = true }` and a 3-visit day paying 100 each gains 100 + 85 + 70 at step 0.15.
    - **The new inputs:** `requestsPerDay = 8` delivers 8 first-time briefs on day 1 when 8 are takeable; `cypherWinsPerDay = 6` pays 6 wins on day 1.
  - **pacing_spec, the `LONG` block** (both seed sets; the bounds asserted on the 200):
    - print, for random, `solo5h` and `social5h`: the median `moneyPerDay` and its ratio to random's, THE HALL min / median, and Legend min / median
    - assert the money bound and THE HALL bound for both personas
    - Legend is printed only. With today's 10 levels a five-hour player reaches it well before day 30, and Task 4's climb is what fixes that, so Task 4 asserts it.
    - every early-game assertion already in the file stays green
- [ ] **Step 3:** `sh tools/spec.sh career_sim pacing` → FAIL.
- [ ] **Step 4: Implement**, then **measure.** For `CURVE.step` in {0.05, 0.10, 0.15, 0.25, 0.50, 0.75}, run the `LONG` block and write one row per step into `research/endless/pacing_2026-11-12.md` §1 (step, each persona's ratio, THE HALL min, Legend min).
  - **Pick the gentlest step that holds the money bound and THE HALL bound for both personas.**
  - **If even 0.75 fails, stop this plan** and bring §1's table to the user. The floor (0.25) and the bounds are decided. Neither moves without them.
  - THE HALL needs Aura 300, a placement and $5,000. If THE HALL bound fails at every step, the curve isn't the cause, so that is a stop too.
- [ ] **Step 5:** `sh tools/spec.sh` → PASS. Controller: sync `Modules/CareerSim` and `Modules/RewardGate`; `--edit t46` → PASS.
- [ ] **Step 6: Commit** `E1-T2: five-hour players in the sim; curve step <pick> holds the bounds` with §1's table in the message.

### Task 3: The server pays on the curve (§3)

**Files:**
- Modify: `src/ServerScriptService/OK/Services/DataService.lua`.
  - `gate` (:427-451) becomes `RewardGate.Step(log, rules, caps, source, n, M._now(), M._day(), (Config.Rewards or {}).Curve)`, after the same `prof[logKey]` table fetch.
  - `M._gate` keeps its signature, so `Systems/Career.Add` (:139-153) is unchanged.
- Modify: `src/ReplicatedStorage/OK/Config.lua` per Shared shapes:
  - `Config.Rewards`
  - `curve = true` on the listed rules, with each comment saying "full pay for the first dailyMax awards a day, then a shrinking share to 25%"
  - the three WalkIn event counts lose `dailyMax`
  - `Config.Cypher.PairDaily`
- Modify: `src/ReplicatedStorage/OK/Systems/BeatBattles.lua` `reveal` (:182-210). For each player entrant, `key` = the sorted other entrants' ids joined by `"|"`.
  - A player's id is `UserId`. Any other owner's is `"n:" .. name`.
  - A round pays that entrant (EnterXP, WinXP, WinCred, the Cypher Aura) only when `RewardGate.PairStep(prof.cypher.pairs, key, Data._day(), Config.Cypher.PairDaily)` is true.
  - `prof.cypher.pairs` is created lazily: `{ day = 0, n = {} }`.
  - `entered`, `wins`, `CypherWins`, `ColdCheck` and the Life event run either way.
  - Add the Studio-only seam `M._PayRound(entries, winnerEntry)`: the payout loop factored out of `reveal`, and called by it.
- Modify `build/t69_check.lua` (d): the 4th Phone XP award pays `math.floor(40 * Share(3, 3, Cfg.Rewards.Curve))` with no "daily". Its header comment says so.
- Modify `build/t46_check.lua`: `CURVE` is pinned, and the curve flags are listed and pinned.
- Modify `build/t52_play_server.lua`: its seven-awards note says awards past the count now pay a share. The assertion stays.
- Modify `spec/economy_fixture.lua`: `CURVE` gets Task 2's step, and `SOURCES` the flags and the event-count change.
- Create: `build/t140_check.lua`, `build/t142a_play_server.lua`.

**Interfaces:**
- Consumes: Task 1, and Task 2's step.
- Produces: the live curve. Plan 2's request pay and lifted visit limits rely on `Delivery`, `WalkIn` and `Phone` being curved.

- [ ] **Step 1: Write the failing tests.**
  - **t140_check** (Edit). It uses t69's seam: a fake store, a fake clock and a fake player.
    - **(a)** Fifteen `AddCred(p, 100, "Delivery")` each pay 100. The 16th pays `floor(100 * Share(15, 15, curve))`. The pay falls to 25 and stays there, and nothing returns "daily".
    - **(b)** The next day, the first award pays 100.
    - **(c)** Hard caps hold:
      - the 16th `AddXP(p, 2, "FireTap")` gives `0, "daily"`
      - Console then Mic hit the Activity group cap of 30 as today
      - the 2nd `AddCred(p, 600, "Streak")` gives `0, "daily"`
      - the 7th `AddCred(p, 50, "Flip")` gives `0, "daily"`
    - **(d)** `Career.Add` through the same seam:
      - nine `WalkIn` placements of 1 all pay 1 (event counts, no cap)
      - the 8th `Phone` Aura of 10 pays its share
    - **(e)** Config:
      - the set of rules with `curve = true` equals Shared shapes' list exactly
      - `Config.Rewards.Curve.floor == 0.25`
      - `Config.Cypher.PairDaily == 4`
    - Marker `T140 OK`.
  - **t142a_play_server** (Play): `fresh()`, then through `BeatBattles._PayRound`, with entries for the test player and two non-player owners `"n:BOT1"` and `"n:BOT2"`, the test player winning.
    - Five rounds against the same two: the first four pay `WinCred`. The fifth pays none (money unchanged), and `prof.cypher.wins` still rises by 5.
    - A round against `"n:BOT3"` alone pays.
    - Cleanup restores money, XP and `prof.cypher`.
    - Marker `T142A PLAY OK`.
- [ ] **Step 2:** Controller red `--edit t140_` and `--play t142a` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4:** `sh tools/spec.sh` → PASS. Controller:
  1. Sync `Modules/RewardGate`, `OK/Config`, `Services/DataService` and `Systems/BeatBattles`.
  2. Run the module refresh.
  3. `--edit t140_ t46 t69 t60 t41_` and `--play t142a t52 t28 t43 t78` → PASS.
- [ ] **Step 5: Commit** `E1-T3: story rewards shrink to a 25% floor; presses stay capped; cypher pairs capped`.

### Task 4: The slower climb (§5)

**Files:**
- Create: `research/endless/copy_2026-11-12.md` §A. It holds:
  - **A1.** Ten new ranks for levels 10–19, CAPS, rising in order.
    - None reuses a word from a title, ribbon or another rank.
    - Each must fit the nameplate. The width rule: measured at t22b's 11 px, a rank may be no wider than `"STUDIO LEGEND"` unless t22b's WORST line is re-measured.
  - **A2.** Five rank-up lines for `Unlocks[10]`, `[12]`, `[14]`, `[16]` and `[18]`, in the style "Rank up: <RANK>".
  - **A3.** The approval list.
- Modify: `Config.lua`:
  - `Config.Levels` (:78): ten new thresholds, tuned in Step 3
  - `Config.Ranks` (:97) and `Config.Unlocks` (:80-85): per Shared shapes; `[10]`'s old Legend line moves to `[20]`
  - `plate_legend.level` (:124): 20
- Modify the copies and pins:
  - `spec/economy_fixture.lua`: `levels`, `RANKS`
  - `build/t46_check.lua`: `RANKS` (:115), `PACING.gates.plate_legend.level` (:125)
  - `spec/pacing_spec.lua`: `GATES` (:61-64)
  - `spec/career_sim_spec.lua`: `GATES` (:19)
  - `spec/day_one_spec.lua`: its gear copy (:47)
  - `build/t130_check.lua`: the people plan's ranks list, now 20 entries
  - `build/t41_check.lua` (f): the fake profile's level comes from `Config`'s `plate_legend.level`, not 10; the text says "at its level"
  - `build/t21b_play_client.lua`: comment only
  - `build/t22b_play_client.lua` and the `Modules/Nameplate.lua:4` comment: WORST becomes `"YEAR 15 · LV 20 · <longest rank> · 🔥 1234"`
- Modify: `spec/pacing_spec.lua`, the climb block. `LONG_DAYS = 120`, run for random, `solo5h` and `social5h` on both seed sets:
  - random's Legend median in **55..65** on the 200 seeds (spec §5: "about day 60"), and p10 ≥ 40
  - each five-hour persona's Legend ≥ 30 on every seed
  - the old line "Legend ≥ day 15" stays and is now loose
  - printed: Legend min / p10 / median / p90 per policy, and the day each policy reaches levels 10, 15 and 20
- Create: `build/t141_check.lua`.

**Interfaces:**
- Consumes: Task 2's curve in the sim; the people plan's ranks.
- Produces: 20 levels; `plate_legend.level = 20`. Plan 2's generated people use career levels of their own (not these). After-launch goals above Legend start from level 20.

- [ ] **Step 1: Write §A** (copy doc). Scan it against t40, t50, the BLOCK words and `life_rules_spec`'s rank-word rule.
- [ ] **Step 2: Write the failing tests.**
  - **t141_check** (Edit):
    - `#Config.Levels == 20`; the first ten equal today's; strictly increasing
    - `#Ranks == #Levels`; `Ranks[20] == "STUDIO LEGEND"`; `Ranks[1..9]` unchanged from the people plan
    - `Unlocks[20]` is the Legend line; `plate_legend.level == 20`
    - `DataService.LevelFor(Config.Levels[20]) == 20`; `LevelFor(3200) == 10`
    - `migrate` on a stored `{ xp = Config.Levels[13] + 1, gear = { plate_legend = true }, v = 5 }` → level 13, and `gear.plate_legend` still true
    - no rank or Unlocks line contains "CRED" or "Cred", or OK branding (t40 and t50 don't scan Config's ranks)
    - marker `T141 OK`
  - **pacing_spec:** the climb block, as above.
- [ ] **Step 3:** Controller red `--edit t141_` → FAIL. `sh tools/spec.sh pacing` → FAIL.
- [ ] **Step 4: Implement, then tune.** Thresholds for levels 11–20 follow `Levels[i] = Levels[i-1] + G + (i - 11) * D`, with G in {800, 1000, 1200, 1500} and D in {0, 100, 200, 300}. Pick the pair whose random Legend median is closest to 60 while every assertion holds.
  - If no pair does, widen G up to 2,500 in steps of 250.
  - If Legend is held by `plate_legend`'s stat needs instead of its level (random's median doesn't move with G), **stop** and bring the numbers. Moving the stat needs is a guardrail change.
  - Record the pair and every printed number in the commit and in pacing §2.
- [ ] **Step 5:** `sh tools/spec.sh` → PASS. Controller:
  1. Sync `OK/Config`, then the refresh.
  2. `--edit t141_ t130_ t46 t41_ t27 t30 t80` and `--play t21 t22 t71` → PASS.
- [ ] **Step 6: Commit** `E1-T4: levels 11-20; Legend is a two-month goal`.

### Task 5: Report and integration

**Interfaces:** Produces none. It reports on Tasks 1–4.

**Files:**
- Modify: `research/endless/pacing_2026-11-12.md`:
  - §1 (Task 2's table)
  - §2 (the climb)
  - §3: every pacing number on 20 and 200 seeds, before this plan (the golden file and the people plan's report) and after. For random, the people plan's policies, `solo5h` and `social5h`:
    - money a day and its ratio
    - THE HALL, Legend, the level 10 / 15 / 20 days
    - steady shares, the phone Aura, cold counts
  - §4: the user's list:
    1. the bounds as measured
    2. the step chosen
    3. **the steady-share ceiling (≤ 0.50) now applies to the existing policies only.** The five-hour personas are over it by design (most of their extra money comes from visits). Asserting the ceiling for them, or a new ceiling, is the user's call.
    4. the new ranks and lines (§A3)
- [ ] **Step 1:** `sh tools/spec.sh` → every spec PASSES. Paste the printed lines into §3.
- [ ] **Step 2:** The full Studio suite with no failures (one rerun per flake), `walkins_pause_off`, guard green.
- [ ] **Step 3:** A whole-branch final review on the most capable model against this plan and spec §3 and §5. One fix dispatch, then a scoped re-review.
- [ ] **Step 4:**
  - README: a "Long sessions" section (the curve, the hard caps, the cypher pair cap, levels 11–20, tests t140–t142)
  - the tracker: Now, Needs you (§4's list), Done log
  - IDEAS.md (the endless-play entry: "plan 1 BUILT")
  - snapshot `v44_long_sessions`; export; push to GitHub
- [ ] **Step 5: Commit** `E1-T5: long sessions report and integration`.

---

## Claude's calls (plan)

1. **The gate moves into a pure module, and the sim runs it too.** Why: §3's bounds are only worth anything if the sim pays exactly what the server pays. Today's sim models one gated source; five-hour players hit them all.
2. **Event counts lose their daily cap.** WalkIn placements, hits and sponsors no longer have `dailyMax`, and `max = 1` stays. Why: §3 says "a story event counts in full", and a cap would be a daily wall that only long sessions hit.
   - Cost if wrong: a five-hour player gains more placements a day. The bounds still hold money, THE HALL and Legend.
3. **Flip stays hard-capped.** So do Daily, Weekly, Streak, Plaque and AuraHeal. Why: none is in §3's list. Daily and Weekly are once-a-day or once-a-week requests by design, and Flip is paid by other players' actions, a two-player farm with no per-pair limit.
4. **Cypher rounds are limited per opponent set** (`PairDaily = 4`, today's win cap). The limit applies to everything a round pays, entering included. Why: §3 asks for a per-pair limit wherever a cap was the only thing stopping a two-player farm. With the curve, two friends could cypher for 100 rounds a night. FIRE already has `Config.Fire.PairDaily`.
5. **The five-hour personas' numbers are derived from the timers, not guessed.** The derivation is in Shared shapes, and the visits and pops are a little under a real session's ceiling. Plan 2 re-checks the bounds once requests are endless.
6. **The step is the only knob.** The floor and the bounds are decided, so a failed measurement stops this plan instead of moving them.
7. **Ten new levels (11–20), Legend at 20.** Why: about one level every four played days over the second month, against five bigger jumps. The early ladder (1–10) is untouched.
8. **The visit limits (`Config.WalkIns.DailyMax`, `Config.Phone.DailyMax`) are plan 2's.** Why: lifting them before everyday life and generated people exist would make a long session cycle today's ~200 cards.
