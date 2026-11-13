# People and Progression Implementation Plan

> **Revised 11-12 ~21:30 for the approved endless-play design** (`specs/2026-11-12-endless-play-design.md` §4.4, §8):
> - **Task 4 (the hometown pool) is SUPERSEDED.** Do not run it. Roles and generated people replace it in `plans/2026-11-12-endless-2-story-web.md`, which also owns `BindOutcome` and `W.Roles`.
> - **Task 0 §6 is dropped.**
> - **Task 3's set of people is an argument,** so generated ids survive the repair.
> - **Task 5's `homekid2` case is removed.**
> - **Run order:** the rooms plan's R-T8..R-T16, then this plan without Task 4, then the endless plans 1, 2 and 3.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Implementers write files and run CLI specs only; the controller is the only Studio client.

**Goal:** A career that reads like one.
- Titles from BEDROOM PRODUCER up, not INTERN.
- Nobody goes cold from low Aura in their first week.
- The people you've met, on your phone with a 7-step bond and an honest memory line.
- ~~A hometown kid who can be a different kid each time.~~ (Moved to endless plan 2: roles and generated people.)
- Big names who wait for your home studio and FAMOUS.
- Early money kept by local cards, all proven by a pacing run that reports every number.

**Architecture:**
- **Pure rules first:**
  - `CareerRules.ColdStep` gains the grace rule.
  - `WalkInRules` gains the met record, the role bind (`@hometown`), the star entry rule and the star stage.
  - `Modules/ContactRules` (new, pure) builds the CONTACTS rows and owns their copy.
  - `Data/WalkIns` gains `People` (`Roles` and the pool moved to endless plan 2).
  - `CareerSim` models room unlocks, the first monitors, the solo producer, early income and the gate, so `spec/pacing_spec.lua` guards every target.
- **Server:**
  - WalkIns writes `met` and binds roles.
  - Phone and WalkIns pass `stars`.
  - `Systems/Contacts` (new) serves `Contacts_Get`.
- **Client:** PhoneUI's CONTACTS view.

**Tech Stack:** Luau (Roblox), Roblox Studio via the built-in Studio MCP (`tools/mcp_call.py`), `tools/sync.py`, `tools/test.py`, `sh tools/spec.sh`, the `luau` CLI, Python 3.

**Spec:** `specs/2026-11-12-progression-and-rooms-design.md`:
- §4.10: big names and local cards
- §4.11: titles
- §4.12: the met record and contacts
- §7: D1 (the hometown pool), D5, D6, D11, D13
- §8: pacing
- the §6 pacing line: first monitors in session 1; larger rooms take sustained progress

The rooms plan (`plans/2026-11-12-your-rooms.md`) owns the gates `home_studio` / `real_studio` and the gear `spk_monitors`.

## Global Constraints

- **No git.** Every commit step is `sh .superpowers/g add -A src build spec specs plans research README.md && sh .superpowers/g commit -q -m "<task>: <what>"`. Add `tools` when a tool changes. Every message ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Task prefix `P-T<n>`.
- **One Studio client.** Implementers never call `tools/sync.py`, `tools/test.py`, `tools/mcp_call.py`, a build script or any `mcp__Roblox_Studio__*` tool. The controller does all of that under the Studio lease, in this order: red, then the build scripts listed, then the sync, then green. Load under 30 before a suite; one rerun per flake.
- **Scoped syncs only:** `python3 -I tools/sync.py --dry`, then each task's parent-qualified patterns. Never `--force`.
- **Selectors are substrings.** `t13` also matches t130–t139. Use the full selectors given (`t130_`, `t131a`).
- **Pure modules** (`WalkInRules`, `CareerRules`, `CareerSim`, `LifeRules`, `Format`, `VisitorLooks`, `ContactRules` (new), `Data/WalkIns`) never touch Roblox globals and never `require`.
  - CLI specs keep literal Config copies (`spec/economy_fixture.lua`).
  - t46 (`build/t46_check.lua`) pins every new literal: `WALKINS.Cold.graceDays`, `WALKINS.Stars`, the new GATES, `RANKS`.
- **The money guardrail.** It is checked by `spec/pacing_spec.lua` after every task, on the 20 seeds and the recorded 200:
  - the random steady share ≥ 0.3412 on the 200 seeds (`FLOOR_200`), and every policy ≤ 0.50
  - THE HALL median day 4–6, p10 ≥ 3, p90 ≤ 7
  - Legend ≥ day 15
  - phone Aura ≤ 15

  If a task's tuning, within the ranges it states, can't meet them, stop that task and bring the numbers to the user. THE HALL's 20-seed p90 already sits at 7.
- **Saves:** schema stays **v5**.
  - New fields are lazily defaulted and repaired in WalkIns' `state()`: `prof.walkins.met`.
  - t41's 6 walkins keys after a bare load stay 6.
  - Old saves keep everything: `homekid` stays the written first `@hometown` (endless plan 2), and a queued follow-up is never removed.
- **Content:**
  - New cards and lines come from Task 0's file and go on its approval list.
  - Rules: CAPS headlines, lowercase bubbles, names only through `{name:<id>}`.
  - Banned: OK branding (t50; the plain word "ok" is fine), CRED/Cred (t40), BLOCK words.
  - No bond label reuses "COLD" or "BUSY DAY" (the HUD chips).
- **Phone first:** every new control is ≥ 44 px, inside the viewport and not overlapping, at 667×375, 771×390 and 844×390.
- **Test numbers:** t130–t139. Edit checks are `tNNN_check.lua` with marker `T130 OK`. Play files are `tNNNa_play_server` / `tNNNb_play_client` with markers `T131A PLAY OK`. Each play file:
  - starts with its own `fresh()`: unseat, teleport to the lounge (24, 3, 0), Phone `Quiet` + `Reset`, WalkIns `Reset`, Career `Reset`, Life `Reset`, `ResetHints`
  - runs in a pcall with cleanup and a rethrow
  - finishes in under 90 s
- **No new audio, lights or parts in the hub.** `Config.SFX` stays 17.
- **Standing limits:** never save or publish the place; no uploads; no Robux; no player-typed text; never flip `Config.Data.UseStoreInStudio`.

## Review Focus

1. **Old saves under the pool and the gate.** Take a profile with `homekid` history: rel, flags, a queued `payback_homekid`, and a stored `next` pick of a star entry card.
   - It loads without error.
   - The kid's arc continues as `homekid`.
   - The stored star pick is re-picked (`Revalidate`), and nothing leaves the queue.

   Test: t135a (the stored pick). The legacy kid's case moved to endless plan 2 with the roles.
2. **The stage in either order, and the high-water mark.** FAMOUS before the home studio, or the home studio before FAMOUS: the gate opens exactly when both hold. A player whose Followers fall back under 20,000 keeps access, because `prof.life.tier` is the high-water mark. Test: `walkin_rules_spec` (StarsOpen) and t135a.
3. **CONTACTS with nobody in it.**
   - A brand-new player sees §5's honest empty line.
   - A player with a sponsor but no people sees only the deal row.
   - Neither ever sees a blank card or an error.

   Test: `contact_rules_spec` and t134b.
4. **The grace boundary.**
   - Career day 7 at Aura −60 stays warm; day 8 goes cold "aura".
   - A quiet spell during grace still starts and ends normally.
   - A profile already cold "aura" on day 3 (saved before the rule) stays cold until a FIRE or a 3-star delivery.

   Test: `career_rules_spec` and t131a.
5. ~~The role draw when every kid is known.~~ Moved to endless plan 2 with Task 4.

---

## Shared shapes

- **Titles** (Task 1): `Config.Ranks = { "BEDROOM PRODUCER", "BEATMAKER", "LOCAL PRODUCER", "PRODUCER", "RISING PRODUCER", "IN DEMAND", "HITMAKER", "HEAD PRODUCER", "EXEC PRODUCER", "STUDIO LEGEND" }`. `Config.Unlocks[4]` = "Rank up: PRODUCER" and `[6]` = "Rank up: IN DEMAND". `[8]` and `[10]` keep their text.
- **Grace** (Task 2): `Config.WalkIns.Cold = { aura = -50, quietDays = 3, rearmAura = -25, dailyMax = 2, graceDays = 7 }`. ColdStep enters "aura" only when `careerDay > (cfg.graceDays or 0)`. Quiet entry, exits and rearm are unchanged.
- **The met record** (Task 3): `prof.walkins.met = { [personId] = career day first met }`.
  - Only ids in the player's set of people are kept: `W.PeopleSet` today. Endless plan 2 adds the player's generated ids, so the set is always passed in as an argument (`peopleSet`), never read from `W.PeopleSet` inside the rule or the repair.
  - It is written at a walk-in arrival and at any phone open (DM or NEWS) whose item's visitor is a person.
  - It is never written by `Seed`, `Pick` or `seen`.
  - **Met means** `met[id] ~= nil or rel[id] ~= nil`. The `rel` half is the old-save rule, and it also covers a kid you worked with through two_sessions.
- **People and roles** (Task 4, SUPERSEDED; endless plan 2 owns roles. Only `W.People` and `W.PeopleSet` below are built, in Task 3, without the pool kids):
  - `W.People = { "rival", "mom", "navx", "blogger", "homekid" }` and `W.PeopleSet` (built in Task 3; no pool kids).
  - ~~`W.Roles = { hometown = { "homekid", "homekid2", "homekid3" } }`~~ — endless plan 2 defines `W.Roles`.
  - The token `"@hometown"` may appear only in an outcome's `rel.who` and as `"@hometown"` inside a `plant.id` (`"payback_@hometown"`).
  - The sponsor's rep (`rel.rep`) is deal standing, not a person.
- **WalkInRules (pure), new:**
  - `MarkMet(met, id, day, peopleSet) -> bool`: true when it wrote; keeps the first day; refuses ids not in `peopleSet`.
  - `IsMet(walkins, id) -> bool`.
  - `BindOutcome(outcome, roles, rel, rng) -> outcome, boundId?`:
    - With no `@` token, it returns the same table and draws nothing.
    - Otherwise it draws among the role's members with no `rel` entry (deck order, `rng(1, n)`), or among all of them when every member has one.
    - It returns a copy with every token replaced.
  - `StarEntry(card, deck) -> bool`: the card's visitor has kind "artist", and it has none of `needs.rel`, `under.rel`, or a `needs.flags` id whose who is its own visitor.
    - Today's 34 star cards hold 31 entries (including `dm_navx`, `dm_dojabat`, `dm_eyelash` and `dm_drift`) and 3 chain cards: `navx_tour`, `navx_tv` and `navx_replaced`.
    - Follow-ups are never entries: `Pick`'s due follow-up path never asks.
  - `StarsOpen(gates, tierId, stars, tiers) -> bool`: `gates[stars.room] == true` and the index of `tierId` in `tiers` ≥ the index of `stars.tier`, read locally (no LifeRules).
  - `cardEligible` (:324-340): `opts.stars == false and StarEntry(card, deck)` → ineligible. `opts.stars == nil` means no gate, for old callers and fixtures.
- **The star stage** (Task 9): `Config.WalkIns.Stars = { room = "home_studio", tier = "FAMOUS" }`.
- **ContactRules (pure)** (Task 5): `Rows(input) -> { rows, sponsor?, empty }`, where `input = { walkins, sponsorId?, people, relFlags, waiting = { [id] = "door" | "message" } }`.
  - A row is `{ id, bond = -3..3, label, memory, flag?, next = "door" | "message" | nil, nextText }`, for met people only, ordered by first-met day then `People` order.
  - `memory` is the line for the flag with the latest day (ties: flag name order), else `Copy.JustMet`.
  - `sponsor = { id, standing = rel.rep score or 0, label }` appears only with a deal.
  - `Copy` holds `Labels[-3..3]`, `Memory[personId][flag]`, `JustMet`, `Empty`, `Next.door`, `Next.message`, `Next.none`, `Header` and `Deal`.
- **Server:** `WalkIns.PendingFrom(p) -> visitorId?` (a visit in flight, walking or arrived); `Phone.WaitingFrom(p) -> { [visitorId] = true }` (pending pops). `Systems/Contacts.State(p)` is ContactRules' Rows with roster names and colours. Remote `Contacts_Get`: a RemoteFunction made by `build/17_career_remotes.lua`, with a 0.25 s per-player cooldown.
- **Hooks:**
  - `_StudioWalkInHook` gains `Met(uid)` (a copy), `SetMet(uid, met)` (a copy through the repair) and `Peek(uid, source, n)`. `Peek` returns the ids of n picks, each made with a fresh rng on a deep copy of the walk-in state with the live opts for `source` ("walkin" | "phone"), and changes nothing.
  - `_StudioContactsHook`: `State(uid)`.
- **CareerSim, new input and output** (Tasks 6–9):
  - `input.gates` gains `spk_monitors`, `home_studio` and `real_studio`. Each `{ needs, cost, level? }` is bought the first day its check passes, in the order `spk_monitors`, `home_studio`, `studio_two`, `real_studio`, `plate_legend`.
  - `input.persona = "solo"`: no FIRE, no cypher wins, and `aired = false`.
  - `input.stars = { room, tier }`: the gate, with the stage = `homeDay ~= nil` and `tierIndex ≥ index(tier)`.
  - Results gain `monitorsDay`, `homeDay`, `realDay`, `earned` (the total money gained), `earlyShare` (the walk-in share of days 1–7's gained money), `zeroDays` (days that gained no money) and `starsDay` (the first day the stage held).

---

### Task 0: Copy

**Files:**
- Create: `research/people/copy_2026-11-12.md`

**Interfaces:**
- Produces: the copy doc's sections §1–§8, which every later task cites by number.

- [ ] **Step 1: Write the sections.**
  - §1 Titles: the ten ranks, and the two "Rank up" lines.
  - §2 Bond labels for −3..3 (seven, none "COLD").
  - §3 Memory lines. One per flag the content sets:
    - blogger exposed
    - mom aunt / fed / quiet
    - navx album_hit / replaced / toured / tv
    - rival posted / respect
    - the hometown kids' blew_up / passed / show (kid 1's lines, reused by each pool kid)

    Plus `JustMet` and the empty state.
  - §4 Next steps: "at your door", "a message is waiting", "nothing right now".
  - §5 The CONTACTS header and the deal row ("YOUR DEAL · {sponsor}").
  - ~~§6 The pool: `homekid2` and `homekid3`.~~ DROPPED (endless plan 2 replaces the pool with roles and generated people).
    - For each: parody and fiction names (web-checked), style, colour, sig, and recipe notes for `VisitorLooks` (kid proportions).
    - Each kid's four entries (`payback_<id>`, `<id>_show`, `<id>_album`, `<id>_forgot`) in their own voice. The numbers, gates and choices are kid 1's; only `tag`, `line`, `text`, `headline` and `note` change.
  - §7 Eight local cards for week 1, using the existing local cast (blockkid, rapper, cousin, neighbor, host, landlord), so there are no new looks.
    - Walk-in source, no `first`.
    - Money within the existing local cards' range; every Data rule met.
    - Numbered L1–L8 in the order Task 9 adds them.
  - §8 The approval list.
- [ ] **Step 2: Scan** against t40, t50 and the BLOCK words; every `{name:<id>}` names a visitor.
- [ ] **Step 3: Commit** `P-T0: people copy`.

### Task 1: Titles that don't start at INTERN (§4.11, D5)

**Files:**
- Modify: `Config.lua` `Config.Ranks` (:97) and `Config.Unlocks[4]`, `[6]` (:80-85); `spec/economy_fixture.lua` `RANKS` (:94); `build/t46_check.lua` `RANKS` (:115); `build/t25_check.lua:27` (`card.rank == "ENGINEER"` → "PRODUCER"); the example text in the `Modules/Nameplate.lua:1` comment.
- Create: `build/t130_check.lua`

**Interfaces:**
- Produces: the new `Config.Ranks` and `Config.Unlocks[4]`, `[6]`. The fixture's `RANKS` and t46's `RANKS` equal them.

- [ ] **Step 1: Write the failing test** `t130_check` (Edit):
  - `Config.Ranks` equals the Shared shapes list; `#Ranks == #Levels`
  - `Unlocks[4]` and `[6]` name the new ranks
  - no `Config` string contains "INTERN", "RUNNER", "ASSISTANT" or "ENGINEER"
  - `Reactions.Rank(1) == "BEDROOM PRODUCER"`
  - `Profiles.CardFrom` at level 4 gives rank "PRODUCER"
  - marker `T130 OK`
- [ ] **Step 2:** Controller red `--edit t130_` → FAIL.
- [ ] **Step 3: Implement.** `spec/life_rules_spec.lua`'s rank-word check (:179-201) must stay green: no title or ribbon contains a new rank.
- [ ] **Step 4:** `sh tools/spec.sh` → PASS. Controller: sync `OK/Config`; `--edit t130_ t21_ t25_ t46 t80` and `--play t22 t71` → PASS.
- [ ] **Step 5: Commit** `P-T1: titles from BEDROOM PRODUCER to STUDIO LEGEND`.

### Task 2: The week-1 grace rule (D13)

**Files:**
- Modify: `Modules/CareerRules.lua` `ColdStep` (:65-81); `Config.lua` `Config.WalkIns.Cold` (:181) `graceDays = 7`; `spec/economy_fixture.lua` `WALKINS.Cold`; `build/t46_check.lua` `FIXTURE.WALKINS.Cold`.
- Modify: `spec/career_rules_spec.lua`, `spec/career_sim_spec.lua`, `spec/pacing_spec.lua` (header comment: the week-1 check now holds by rule for Aura).
- Create: `build/t131a_play_server.lua`

**Interfaces:**
- Produces: `ColdStep`'s `cfg.graceDays` (nil = 0). `Systems/Career.ColdCheck` and the sim pass the same table, so neither changes.

- [ ] **Step 1: Write the failing tests.**
  - **career_rules_spec:**
    - With graceDays 7 and lastDay present, a check at Aura −60, rearm false:
      - day 1 → warm; day 7 → warm; day 8 → cold "aura"
      - day 4 with `careerDay - lastDay = 3` → cold "quiet"
    - Already cold "aura" on day 3 → stays cold on a check, thaws on "delivery3".
    - `graceDays` nil → day 1 at −60 → cold "aura" (the old rule).
  - **career_sim_spec:** a run whose day-1 Aura drops under −50 (a fixture deck with one −80 card) isn't cold before day 8, and `neglect` is still cold "quiet" on day 4.
  - **t131a:**
    - Life `SetDay(3)`, Career `Set { aura = -60 }`, `ColdCheck("check")` → warm, `Cold` false
    - `SetDay(8)` → cold "aura"
    - `Reset`; `SetDay(4)`, `SetLastDay(1)`, check → cold "quiet"
    - marker `T131A PLAY OK`
- [ ] **Step 2:** `sh tools/spec.sh career_rules career_sim` → FAIL. Controller red `--play t131a` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4:** `sh tools/spec.sh` → PASS (pacing included). Controller: sync `Modules/CareerRules` and `OK/Config`; `--edit t46` and `--play t131a t78` → PASS.
- [ ] **Step 5: Commit** `P-T2: no cold from low Aura in the first 7 played days`.

### Task 3: The met record (§4.12)

**Files:**
- Modify: `Modules/WalkInRules.lua` (`MarkMet`, `IsMet`); `Data/WalkIns.lua` (`W.People`, `W.PeopleSet`: the five people today; endless plan 2 adds generated people per player, not to this list).
- Modify: `Systems/WalkIns.lua`:
  - `state()` (:212-233) repairs `st.met`: a table holding only ids in `peopleFor(st)` with number values. `peopleFor(st)` is a local function that returns `Content.PeopleSet` now; endless plan 2 widens it to include the player's generated people
  - `onArrive` (:675) calls `MarkMet(st.met, rec.item.visitor, careerDay(p), peopleFor(st))` after the count
  - the hooks `Met`, `SetMet` and `Peek`
- Modify: `Systems/Phone.lua` `open` (:233-264): the same `MarkMet` after the count, through `WalkIns.State(p)`.
- Modify: `spec/walkin_rules_spec.lua`.
- Create: `build/t132a_play_server.lua`

**Interfaces:**
- Produces: `MarkMet`, `IsMet`, `prof.walkins.met`, the hooks `Met`, `SetMet` and `Peek`. Contacts (Task 5) and the third plan read only `IsMet` and `met`.

- [ ] **Step 1: Write the failing tests.**
  - **walkin_rules_spec:**
    - `MarkMet({}, "mom", 3, set)` → true, `{ mom = 3 }`
    - again on day 5 → false, still 3
    - `"feed"` → false
    - `IsMet` true with only a `rel` entry, true with only `met`, false with neither
    - `Seed` and `Pick` leave `met` untouched
  - **t132a:**
    - the real scheduler path writes no `met` before an arrival: `Spawn()` then `Expire` before he arrives leaves `Met(uid)` empty (as t79a's stored-pick probe does)
    - a walk-in from the rival arrives → `Met(uid).rival` = the career day
    - the blogger's DM `trending` (no `rel` write) through the phone hook (`Pop`, `Open`) → `Met(uid).blogger` set and `Rel(uid).blogger` nil
    - `prof.walkins` through HttpService JSON and back plus `state()` → `met` is the same
    - `SetMet` with junk (`{ feed = 1, mom = "x" }`) keeps `{}`
    - WalkIns `Reset` clears it
    - marker `T132A PLAY OK`
- [ ] **Step 2:** Spec FAIL. Controller red `--play t132a` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4:** Specs PASS. Controller: sync `Modules/WalkInRules`, `Data/WalkIns`, `Systems/WalkIns` and `Systems/Phone`; `--edit t41_` and `--play t132a t43 t51 t79` → PASS.
- [ ] **Step 5: Commit** `P-T3: the people you've actually met are remembered`.

### Task 4: The hometown pool (D1) — SUPERSEDED, do not run

> Replaced by `plans/2026-11-12-endless-2-story-web.md` (roles + generated people, spec §4.4). This text is kept only as a record. The ledger marks this task "Task 4: superseded (endless plan 2)".

**Files:**
- Modify: `Data/WalkIns.lua`:
  - `homekid2` and `homekid3` in `W.Visitors`, after `homekid` (:76)
  - their eight entries from §6, after kid 1's: the cards after `homekid_forgot` (:1662), the follow-ups after `payback_homekid` (:2378)
  - `W.Roles`; `W.People` += the two kids; `W.Deck.roles`
  - `two_sessions` (:2006-2022): every `rel.who = "homekid"` → `"@hometown"`, and `plant = { id = "payback_@hometown", at = { 10, 16 } }`
  - `indexFlag` (:2587-2593): a `who` naming a role indexes the flag for each member
- Modify: `Modules/WalkInRules.lua` (`BindOutcome`). Call it at the top of `Systems/WalkIns.lua` `apply` (:445), `Systems/Phone.lua` `apply` (:182) and `Modules/CareerSim.lua` `apply` (:344), with the player's (or `sim`'s) `rel` and the same rng each one already passes to `Plant`.
- Modify: `Modules/VisitorLooks.lua` (5d's module): recipes for the two kids (`kid = true`). Modify `spec/visitor_looks_spec.lua` `KIDS` (+2).
- Modify: `spec/walkins_data_spec.lua`:
  - **pool parity:** each member's entries equal kid 1's in every field but `id`, `visitor`, `tag`, `line`, `text`, `headline` and `note`, with each `homekid.` flag id renamed to `<member>.`
  - `@` tokens only where Shared shapes allows, and only for a declared role
  - every member is a `local` visitor
  - `rel.who` may be a role
- Modify: `spec/pacing_spec.lua`:
  - the arc reach accepts any member for `homekid_show`, `homekid_album` and `homekid_forgot` (a family table)
  - "homer runs to an album" counts any member's album
- Modify: `build/t66a_play_server.lua` and `build/t79a_play_server.lua`: the `two_sessions` choice's `SetRng` lists gain the kid index first (1 = `homekid`). This keeps their assertions.
- Create: `build/t133a_play_server.lua`

**Interfaces:**
- Consumes: `IsMet` and `People` (Task 3).
- Produces: `BindOutcome`, `W.Roles`, the ids `homekid2` and `homekid3`. The third plan's hometown project loop builds on these ids and on `BindOutcome`.

- [ ] **Step 1: Write the failing tests.**
  - **walkin_rules_spec (BindOutcome):**
    - an outcome with no token → the same table and no rng call (a counting rng)
    - `rel = {}` and rng → 2 → `homekid2` in both `rel.who` and `plant.id` (`"payback_homekid2"`)
    - `homekid` already in `rel` → the draw is among `homekid2` and `homekid3` only
    - all three in `rel` → among all three
    - the input outcome is unchanged (a copy)
  - **career_sim_spec:** a homer run's `rel` holds a pool kid, and its queue or firstSeen shows that kid's payback; `rel["@hometown"]` never exists.
  - **t133a:**
    - fresh; `SetRng { 2, ... }`; `two_sessions` choice 1 (the phone hook) → `Rel(uid).homekid2.score == 1`, the queue holds `payback_homekid2`, and nothing is under `homekid`
    - choice 2 with `SetRng { 3, ... }` → `homekid3.passed`
    - **legacy:** `SetRel { homekid = { score = 2, flags = { blew_up = 4 } } }` + `Plant("payback_homekid")` → it arrives as `homekid`, and `homekid_album` is eligible (its stored pick stands, as in t79a)
    - `homekid2_album` isn't eligible
    - marker `T133A PLAY OK`
- [ ] **Step 2:** `sh tools/spec.sh walkin_rules walkins_data visitor_looks career_sim pacing` → FAIL. Controller red `--play t133a` → FAIL.
- [ ] **Step 3: Implement.** Re-run pacing; record the numbers in the commit message (the bind draw moves the phone stream).
- [ ] **Step 4:** Specs PASS. Controller: sync `Data/WalkIns`, `Modules/WalkInRules`, `Systems/WalkIns`, `Systems/Phone`, `Modules/VisitorLooks` and `Modules/CareerSim`; `--edit t46 t69 t80` and `--play t133a t66 t79 t42 t55` → PASS.
- [ ] **Step 5: Commit** `P-T4: a hometown pool, and every kid you meet persists`.

### Task 5: CONTACTS with relationship meters (§4.12, D6)

**Files:**
- Create: `src/ReplicatedStorage/OK/Modules/ContactRules.lua` (pure, its `Copy` from §2–§5), `spec/contact_rules_spec.lua`, `src/ReplicatedStorage/OK/Systems/Contacts.lua`.
- Modify: `build/17_career_remotes.lua` (+ `Contacts_Get`); `Systems/WalkIns.lua` (`PendingFrom`); `Systems/Phone.lua` (`WaitingFrom`).
- Modify: `Modules/PhoneUI.lua` (5d's working copy). Tapping the icon with **no** pop waiting opens the CONTACTS card in the pop card's spot:
  - the header and CLOSE (≥ 44 px)
  - a scrolling list: a row is the name in the visitor's colour, 7 pips with the label, the memory line and the next-step line
  - the deal row last
  - the empty line when there are no rows

  While a pop waits, the tap opens the pop as today. The test attributes are `ContactsOpen` and `ContactRows`, with `Command = "contacts"` / `"close"`. Its text is in `ContactRules.Copy`, which t40/t50 scan.
- Create: `build/t134a_play_server.lua`, `build/t134b_play_client.lua`

**Interfaces:**
- Consumes: `IsMet` and `met` (Task 3); `W.People`, `W.RelFlags`.
- Produces: `ContactRules.Rows`, `Contacts.State`, `Contacts_Get`. The third plan reads `Contacts.State` rows by `id` and `bond`.

- [ ] **Step 1: Write the failing tests.**
  - **contact_rules_spec:** each §4.12 acceptance case that is pure:
    - no met people → `empty`, no rows
    - the seeded rotation's `seen` alone → no row
    - met with no flag → `memory == Copy.JustMet`
    - flags `{ fed = 2, quiet = 5 }` → the `quiet` line and `flag == "quiet"`
    - every `Copy.Memory[id][flag]` is a key of `W.RelFlags[id]`, and every `RelFlags` flag of a person has a line
    - scores −3..3 map to seven distinct labels; a score of 9 (bad data) reads as 3's label
    - waiting `{ mom = "message" }` → mom's `next == "message"`; else `nextText == Copy.Next.none`
    - a sponsor with `rel.rep` 2 → the deal row with standing 2 and **no** rep person row
    - no raw flag name appears in any output string
  - **t134a:**
    - after the rival's arrival, `State` has a rival row with his bond
    - a DM from the blogger (`trending`) → a blogger row with `JustMet`, which survives a JSON round trip of `prof.walkins`
    - with mom's DM popped and unopened → mom's `next == "message"`
    - signing a sponsor (`rep_energy` "Sign it") doesn't change any person's bond
    - **D1:** `homekid` with `blew_up` → a row whose memory line is kid 1's `blew_up` line
    - marker `T134A PLAY OK`
  - **t134b:**
    - at the three viewports: the icon with no pop waiting opens CONTACTS
    - rows fit their width, the pips show the bond, and CLOSE is ≥ 44 px, inside the viewport and not overlapping
    - with a pop waiting, the icon opens the pop instead
    - with no contacts, the empty line shows
- [ ] **Step 2:** Spec FAIL. Controller red `--play t134` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4:** Specs PASS. Controller:
  1. Run `build/17_career_remotes.lua` in Edit.
  2. Sync `Modules/ContactRules`, `Systems/Contacts`, `Systems/WalkIns`, `Systems/Phone` and `Modules/PhoneUI`.
  3. `--edit t40_ t50_` and `--play t134 t57 t58 t65` → PASS.
- [ ] **Step 5: Commit** `P-T5: CONTACTS with relationship meters`.

### Task 6: Pacing 1: room unlocks and the first monitors in the sim (§8, §6 pacing line)

**Files:**
- Modify: `Modules/CareerSim.lua`:
  - `unlockGates` (:636-641) runs the Shared shapes order and records `monitorsDay`, `homeDay` and `realDay`
  - `tryUnlock` (:629) is unchanged
  - `Run` (:693) returns them
- Modify: `spec/pacing_spec.lua` `GATES` (:58-61). It gains `spk_monitors = { needs = { followers = 200 }, cost = 500, level = 2 }`, `home_studio` and `real_studio`, as literals of the rooms plan's Config.
- Modify: `build/t46_check.lua`: `PACING.gates` gains the three from live `Config.Career.Gates` and `Config.Gear`.
- Modify: `spec/career_sim_spec.lua`.

**Interfaces:**
- Consumes: the rooms plan's Task 4 (gates) and Task 7 (`spk_monitors`).
- Produces: the sim outputs `monitorsDay`, `homeDay` and `realDay`. Tasks 8 and 9 read `homeDay`.

- [ ] **Step 1: Write the failing tests.**
  - **career_sim_spec:**
    - With a fixture where the monitors and the home studio become affordable the same evening, both unlock that day, in order.
    - Money falls by both costs.
    - THE HALL then waits for the money.
  - **pacing_spec,** on the 20 seeds and the 200:
    - **First monitors in session 1:** the random player's `monitorsDay == 1` on ≥ 90% of runs, and ≤ 2 on every run.
    - **Home studio, a multi-day goal:** median day 2–4, p10 ≥ 2, p90 ≤ 6.
    - The guardrail is unchanged: THE HALL median 4–6 / p10 ≥ 3 / p90 ≤ 7, Legend ≥ 15, the shares.
    - Print every policy's monitors, home, THE HALL and real days.
- [ ] **Step 2:** `sh tools/spec.sh career_sim pacing` → FAIL.
- [ ] **Step 3: Implement, then tune** only `home_studio`'s `cost` in {1000, 1250, 1500, 1750, 2000} and `needs.followers` in {500, 1000, 2000}, mirrored in Config, `pacing_spec` and t46.
  - If no pair holds every target, stop and bring the numbers.
  - Record the chosen pair and every printed number in the commit message.
- [ ] **Step 4:** Specs PASS. Controller: sync `Modules/CareerSim` and `OK/Config`; `--edit t46` → PASS.
- [ ] **Step 5: Commit** `P-T6: the sim buys monitors and rooms; first monitors on day 1`.

### Task 7: Pacing 2: the early-game income check (§8)

**Files:**
- Modify: `Modules/CareerSim.lua`: `recordShares` (:643) also sums days 1–7, and `Run` returns `earlyShare`.
- Modify: `spec/pacing_spec.lua`:
  - `BASELINE_EARLY_200` = the random median `earlyShare` on the 200 seeds, measured **now, before the big-names gate**, and pinned with its date
  - an assertion that it stays within ±0.03 of the baseline
  - every policy's early median printed
- Modify: `spec/career_sim_spec.lua`.

**Interfaces:**
- Consumes: Task 6's sim.
- Produces: the sim output `earlyShare`, and `BASELINE_EARLY_200` in `pacing_spec`. Task 9 must hold it.

- [ ] **Step 1: Write the failing tests.**
  - **career_sim_spec:** a 7-day run whose day 1 gains 100 walk-in and 100 total, and days 2–7 gain 0 walk-in and 100 each → `earlyShare == 100 / 700`.
  - **pacing_spec:** the `earlyShare` assertion, failing until the baseline is pinned.
- [ ] **Step 2:** `sh tools/spec.sh career_sim pacing` → FAIL.
- [ ] **Step 3: Implement,** then measure and pin the baseline. Its value and the 20-seed number go in the commit message and `research/people/pacing_2026-11-12.md` §1.
- [ ] **Step 4:** Specs PASS. Controller: sync `Modules/CareerSim`; `--edit t46` → PASS.
- [ ] **Step 5: Commit** `P-T7: days 1-7 income is measured and held`.

### Task 8: Pacing 3: the zero-FIRE solo producer (§8)

**Files:**
- Modify: `Modules/CareerSim.lua`:
  - `persona = "solo"`: `receiveFire` (:294) and `winCypher` (:285) return early, and `pickNext` (:533) passes `aired = false`
  - `Run` returns `earned` and `zeroDays`
- Modify: `spec/pacing_spec.lua` (the solo block) and `spec/career_sim_spec.lua`.

**Interfaces:**
- Consumes: Task 6's `homeDay`.
- Produces: `input.persona = "solo"`, and the outputs `earned` and `zeroDays`. Task 9 must keep the solo block green.

- [ ] **Step 1: Write the failing tests.**
  - **career_sim_spec:** a solo run gets 0 FIRE (its `recent` beats all have `fires == 0`) and no cypher money.
  - **pacing_spec,** solo against random on the same seeds (200):
    - solo median `earned` ≥ 0.75 × random's
    - solo median `homeDay` ≤ random's + 2
    - `zeroDays == 0` on every solo run (beat work is always there)
    - every solo thaw's event is "delivery3"
    - solo is never cold in days 1–7
    - solo's THE HALL and Legend days are printed
- [ ] **Step 2:** `sh tools/spec.sh career_sim pacing` → FAIL.
- [ ] **Step 3: Implement.** If solo misses 0.75 or +2 days, stop and bring the numbers. Content isn't tuned for solo in this task.
- [ ] **Step 4:** Specs PASS. Controller: sync `Modules/CareerSim`; `--edit t46` → PASS.
- [ ] **Step 5: Commit** `P-T8: a solo bedroom producer with no FIRE still progresses`.

### Task 9: Big names later, and the local cards that keep early income (§4.10, D11)

**Files:**
- Modify: `Modules/WalkInRules.lua`: `StarEntry`, `StarsOpen`, and `cardEligible`'s gate (:324-340). `Revalidate` (:425) inherits the gate.
- Modify: `Config.lua`: `Config.WalkIns.Stars`, plus `spec/economy_fixture.lua` `WALKINS.Stars` and t46's FIXTURE.
- Modify: `Systems/WalkIns.lua` `pickOpts` (:518-524) and `Systems/Phone.lua` `pickOpts` (:343-354): `stars = Rules.StarsOpen(have.gates, prof.life.tier, W.Stars, Config.Life.Tiers)`.
- Modify: `Modules/CareerSim.lua`: `pickNext` passes `stars` when `input.stars` is given, and `Run` returns `starsDay`.
- Modify: `Data/WalkIns.lua`: §7's local cards L1..Ln, added in order four at a time. Modify `spec/walkins_data_spec.lua` (their rules: walk-in, local cast, no `first`).
- Modify: `spec/pacing_spec.lua`:
  - every run passes `stars = E.WALKINS.Stars`
  - a new assertion: no random run's `firstSeen` holds a `StarEntry` card before its `starsDay`
- Create: `build/t135a_play_server.lua`

**Interfaces:**
- Consumes: `prof.career.gates.home_studio` through `Career.Get` (rooms plan Task 4); `homeDay` (Task 6); the early baseline (Task 7); solo (Task 8).

- [ ] **Step 1: Write the failing tests.**
  - **walkin_rules_spec:**
    - `StarEntry`: `navx_placement` and `dm_navx` true; `navx_tv`, `navx_tour` and `navx_replaced` false; `mom_food` false; every follow-up false
    - `StarsOpen`:
      - home + FAMOUS → true
      - home + KNOWN → false
      - FAMOUS without home → false
      - home + ICON → true
      - an unknown tier → false
    - `Pick` with `stars = false` never returns an entry, but still returns a due `navx_single` follow-up
    - `stars = nil` → unchanged behaviour (the existing cases)
  - **t135a, the four acceptance cases and the old save:**
    1. Fresh (LOCAL, no home): `Peek(uid, "walkin", 200)` and `Peek(uid, "phone", 200)` contain no `StarEntry` card.
    2. With `home_studio` owned (Career `Set` + `Unlock`) and `SetTier("FAMOUS")`: some peek is a star entry.
    3. Low stage with `Plant("navx_single")`: `Spawn()` brings `navx_single`.
    4. Choose its album deal → `navx_album` is queued. A reconnect is staged as `prof.walkins` through HttpService JSON and `state()`; `navx_album` is still queued and arrives on `Spawn()`.
    5. A stored `next` of `navx_placement` on a low-stage profile is re-picked.
    6. Followers set back to 0 after FAMOUS (the high-water tier stays) → the stars stay open.
    7. With navx `rel` 2 at low stage, `navx_tv` stays eligible.

    Marker `T135A PLAY OK`.
- [ ] **Step 2:** Specs FAIL. Controller red `--play t135a` → FAIL.
- [ ] **Step 3: Implement.** Then add §7's cards four at a time (L1–L4, then L5–L8) until **every** pacing assertion holds on both seed sets. That covers:
  - the guardrail, every policy ≤ 0.50
  - `earlyShare` within ±0.03 of `BASELINE_EARLY_200`
  - the home window and first monitors
  - solo
  - week-1 cold

  Record which cards went in and every number. If all eight don't hold it, stop and bring the numbers to the user.
- [ ] **Step 4:** Specs PASS. Controller: sync `Modules/WalkInRules`, `OK/Config`, `Systems/WalkIns`, `Systems/Phone`, `Modules/CareerSim` and `Data/WalkIns`; `--edit t46 t69 t80` and `--play t135a t43 t51 t77 t79 t81` → PASS.
- [ ] **Step 5: Commit** `P-T9: big names wait for the home studio and FAMOUS; local cards hold early income`.

### Task 10: The guardrail on 200 seeds, every number reported; integration

**Interfaces:** Produces none. It reports on Tasks 0–9.

**Files:**
- Create: `research/people/pacing_2026-11-12.md`. Every pacing number on 20 and 200 seeds, before (Task 7's §1) and after:
  - the steady share of each policy (random, greedy, chaser, spend-down, homer, climber, solo)
  - early shares
  - THE HALL median, p10 and p90; Legend
  - the first-monitors, home studio and real studio days
  - `starsDay`
  - phone Aura
  - cold counts
  - the arc reach
  - the local cards added, and the home studio price chosen
- [ ] **Step 1:** `sh tools/spec.sh` → every spec PASSES. Paste the printed lines into the report.
- [ ] **Step 2:** The full Studio suite with no failures (one rerun per flake), `walkins_pause_off`, guard green.
- [ ] **Step 3:** A whole-branch final review on the most capable model against this plan and the spec. One fix dispatch, then a scoped re-review.
- [ ] **Step 4:**
  - README "People and progression" (titles, grace, met, contacts, the gate, the tests t130–t132 and t134–t135; the pool is endless plan 2's)
  - the tracker (Now, Needs you: the copy approval list and any numbers brought back; Done log)
  - snapshot `v43_people`; export
- [ ] **Step 5: Commit** `P-T10: pacing report and integration`.

---

## Order and dependencies

- **No rooms needed:** Tasks 0–5 need nothing from the rooms plan and can run before it, or between its tasks.
  - Task 4 waits for Wave 3's 5d to be committed (VisitorLooks, `visitor_looks_spec`). The PhoneUI, Phone and WalkIns lines cited here are from 5d's working copy on disk, 11-12.
  - Task 5 needs Task 3 (Task 4 is superseded).
- **Pacing in order:** Task 6 needs the rooms plan's Task 4 (`home_studio`, `real_studio`) and Task 7 (`spk_monitors`). Tasks 7 and 8 need 6. The early baseline is pinned **before** the gate.
- **The gate:** Task 9 needs the rooms plan's Task 4, plus Tasks 6, 7 and 8. It reads home-studio ownership as `prof.career.gates.home_studio` through `Career.Get`, never through the Rooms system.
- **The last task:** Task 10 is last.
- **Day One:** Day One (Wave 3 Task 5e) needs only Task 1's titles from this plan. It follows the rooms plan's core.
- **The third plan:** it covers the seven deeper-career directions the user moved into launch on 11-12 at 02:43 (spec §6). It builds on this plan's met record, CONTACTS and the hometown pool. Keep these interfaces stable and documented:
  - the person ids in `W.People` and `W.Roles`
  - `prof.walkins.met` and `WalkInRules.IsMet`
  - `WalkInRules.BindOutcome`
  - the bond read: `rel[id].score` through `ContactRules.Rows` / `Contacts.State`

## Claude's calls (plan)

1. **Pool kids get their own written entries** (four each, kid 1's numbers and gates under their own ids). Only `two_sessions` carries the `@hometown` token, bound at apply time by one pure rule. Why: a single role-bound arc can't hold two kids at once, and "every kid you meet persists" needs concurrent arcs. Each kid's entries keep Pick, gates, RelWrite, names and contacts unchanged.
2. **The kid draw prefers kids you've never worked with** (no `rel` entry), else any kid. It uses the same rng as the plant. Why: "a new kid each time", and the server and the sim agree without a `met` read.
3. **Met means a `met` entry or a `rel` entry.** Every phone open from a person counts, DM or NEWS. Why: it is the old-save rule with no backfill step, and a text from the rival is an encounter.
4. **A star *entry* card** is one with no relationship gate on its own star: no `needs.rel`, no `under.rel`, no own `needs.flags`. Follow-ups are never gated. The gate is `opts.stars == false`, and nil means ungated. Why: chains already entered finish, and old callers and fixtures keep their behaviour.
5. **CONTACTS opens from the phone icon when no pop waits.** Why: a seventh panel tab doesn't fit at 667 px, and the spec puts contacts on the phone.
6. **Grace is `graceDays = 7` inside ColdStep,** so the server and the sim share it. The 5b+ "+5 Aura on every starter" cushion stays. Why: one rule, and changing content is out of scope.
7. **"Most careers" means ≥ 90%.** Sim day 1 stands in for session 1, so the first monitors arrive on day 1 on ≥ 90% of the 200 recorded careers. The rooms plan's `DayOneFloor` proves a shorter session (three starter deliveries) already clears them. The home studio is a multi-day goal: p10 ≥ 2 on top of §8's median 2–4 and p90 ≤ 6. Why: the user's session-1 line made measurable.
8. **The early-income check** is ±0.03 of the random median days 1–7 share, pinned before the gate. Why: §8 says "near today's" and names no width.
9. **The solo check against random on the same seeds:** earned ≥ 0.75×, the home studio ≤ +2 days, no zero-money day, and only 3-star thaws. Why: §8 says "reasonable next to a matched baseline" and names no numbers.
10. **Local cards use the existing local cast,** are added four at a time up to eight, and the task stops past that. Why: no new figures, and the stop rule keeps a content flood from hiding a broken gate.
11. **Bond labels never reuse COLD or BUSY DAY.** The memory line comes from the flag with the latest day. Why: those words are HUD states, and the latest event is the honest one.
