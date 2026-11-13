# Endless Play 3: People's Own Lives, the Ten Arcs and Rewards from People — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Implementers write files and run CLI specs only; the controller is the only Studio client.

**Goal:** The people you work with have lives with each other, and those lives pull you in:
- They know each other: friends, crews, exes, collaborators, rivals, mentors.
- They care about different things.
- They read how the internet sees you.
- They can change, but a switch-up always comes after warning signs.
- Ten long arcs play out over weeks or months of played days.
- What people give you follows §4.8's rules, so nothing is minted twice or rewritten.

**Architecture:**
- **Pure first.** `Modules/PeopleRules` (new) holds values, public image, reactions and warning signs. `Modules/TieRules` (new) holds ties and tension. `Modules/GrantRules` (new) holds the "once" keys and keepsakes. `WebRules` gains named chain slots and the new gates.
- **Data.** `Data/Web` gains the written people's values, the reaction table, and the arcs.
- **Server.** Everything moves through plan 2's `Systems/Web`: its events, its day step, and the outcome writes in WalkIns and Phone `apply`.
- **Client.** The public-image label on the Career tab, ties in CONTACTS' memory lines, and keepsakes in the discography.

**Tech Stack:** Luau (Roblox), Roblox Studio via the built-in Studio MCP (`tools/mcp_call.py`), `tools/sync.py`, `tools/test.py`, `sh tools/spec.sh`, the `luau` CLI, Python 3.

**Spec:** `specs/2026-11-12-endless-play-design.md`:
- §4.6, people's own relationships and people who change
- §4.8, rewards from people
- §6, "Launch must leave room for": the era number in the save, and gear kept apart from career state
- §7's anti-goals
- §10

Codex's `design_input/codex/generated_cast_rewards_contract_2026-11-12.txt` is the source of §4.8.

**Execution order:** rooms R-T8..R-T16 → the people plan without Task 4 → endless plan 1 → endless plan 2 → **this plan**. Its pre-flight scan re-reads plan 2's Interfaces blocks against the code as built. Wherever plan 2's built names differ, this plan follows the code, and each difference is ledgered as a ruling.

## Global Constraints

- **No git, one Studio client, scoped syncs, substring selectors.** These are exactly as in plan 2. Task prefix `E3-T<n>`.
- **Pure modules never touch Roblox globals and never `require`.** They are `PeopleRules`, `TieRules`, `GrantRules`, `WebRules`, `CastRules`, `CareerSim`, `Data/Web` and `Data/Cast`.
- **Draws.** Every reaction, warning and tie roll draws from plan 2's `castRng` stream (the sim's `Lcg(seed + 200003)`), never the pick stream.
- **Spec §4.6, verbatim:**
  - "A **switch-up** (a friend turning on you) needs at least two warning signs first"
  - "You can sometimes win them back"
  - "**Nothing bought sets it**" (the public image)
  - "Gifts you earned stay yours after a later fallout, and new gifts come only from new outcomes"
  - "A keepsake records only what truly happened"
  - "Backing one person can cost you with another. Staying neutral has its own cost"
- **Spec §4.8, verbatim:**
  - "existing slots are never re-drawn"
  - "A later written introduction can bind a NEW slot once"
  - "Changed credits or terms are an explicit revised agreement"
  - "A joint keepsake records the story's people separately from the people actually credited on the music"
  - "A pair or group achievement happens once per participant set; swapping the order doesn't repeat it"
  - "an event resolves once"
  - "an achievement is granted once per person, era, arc family and tier"
  - "an account owns an item once"
  - "A keepsake that promises your track keeps its origin and the beat version as it was"
  - "Archived people keep what they claimed and completed"
  - "People with an active promise, callback or pinned goal aren't archived"
- **The pacing guardrails stay green after every task:** every assertion from the people plan and plans 1 and 2. If an arc batch can't hold them within its stated ranges, stop that task and bring the numbers.
- **Saves:** schema stays **v5**. These fields are lazy and repaired:
  - `prof.walkins.image`, `prof.walkins.ties`, `prof.walkins.chains`
  - `rel[id].w`, `P.v`
  - `prof.grants`, `prof.keepsakes`, `prof.era` (default 1)
- **Content:** every line comes from `research/endless/copy_2026-11-12.md` §C and goes on its approval list.
  - Plan 2's copy rules apply.
  - No crime storylines.
  - The arcs never state a real person did anything: they use generated people, the written core, or a parody star only once `StarsOpen` holds.
- **Test numbers:** t160–t167, in plan 2's file and marker style.
- **Standing limits:** as in plan 2.

## Review Focus

1. **A switch-up needs two warning signs, always.** This holds across:
   - an old save whose `rel` has no `w`
   - a person archived and brought back (their `w` is packed in `A`)
   - a written person and a generated one alike

   A turn situation gated `needs.warn = 2` is never eligible at `w = 1`.

   Test: `people_rules_spec` and t162a.
2. **One pair, once.** A pair achievement for (g3, g7) and the same family and tier for (g7, g3) grant once. Replaying the same chain for the same people mints no second keepsake or grant. A new chain with a new person grants again. Test: `grant_rules_spec` and t164a.
3. **Nothing bought moves the image.** Buying a fit, gear or a room, and equipping one, leaves `prof.walkins.image` exactly as it was. Only outcomes, FIRE and daily decay move it. Test: t160a.
4. **A ripple that touches someone archived** updates their packed score (`A.sc`, held to −3..3) without bringing them back. A ripple naming nobody known changes nothing and reports nothing. Test: `people_rules_spec` and t163a.
5. **A chain whose lead was archived mid-arc.** That can't happen: an open chain record makes its people busy. A chain record left from an old save with no people in it is closed quietly. Test: `cast_rules_spec` (ArchiveOrder's busy) and t164a.

---

## Shared shapes

- **Values:**
  - `Data/Web.Values = { [writtenId] = { v1, v2? } }` for every written person and parody star, from §C1's table.
  - A generated person's values are `P.v` when set, else `Face(P).values`.
  - `PeopleRules.ValuesOf(id, cast, parts, Web) -> { values }`.
- **Public image:** `prof.walkins.image = { h = hype −10..10, m = mess 0..10, r = respect 0..10 }`.
  - An outcome's `image = { h?, m?, r? }` adds to it. Each FIRE adds `h` +1, at most 3 a day.
  - On every `"day"`: `h` moves 1 toward 0, `m` falls 1, and `r` is unchanged.
  - `PeopleRules.Label(image) -> "MESSY" | "HYPED" | "RESPECTED" | "QUIET"`, the first that holds of:
    - `m >= 5`
    - `h >= 4`
    - `r >= 5`
    - otherwise QUIET

    The words come from §C1.
- **Reactions:**
  - `Data/Web.Reacts = { [value] = { [event] = { s = scoreDelta, w = warn 0|1 } } }`.
  - The reaction events are:
    - the label each `"day"` (`"HYPED"`, …)
    - `"rise:self"` (they rose)
    - `"fall:self"`
    - `"seen:rival"` (you were seen with their rival)
    - `"skip"` (you passed on their request or listen-back)
  - `PeopleRules.React(values, event, Reacts) -> s, w`: the sum over their values, with `w` held to 0..1.
  - Each `"day"`, reactions run for **close people**: score ≥ 1, or seen in the last 14 played days. At most 40 a day, oldest `ls` last.
- **Warnings:** `rel[id].w`, 0..5.
  - `React`'s `w` adds to it.
  - A win-back outcome's `rel.clearWarn = true` sets it to 0.
  - Gates: `needs.warn = n` and `under.warn = n` on the bound person.
- **Ties:** `prof.walkins.ties = { [TieRules.Key(a, b)] = { k, t } }`.
  - The key is `a .. "|" .. b`, with the two ids sorted.
  - `k` is one of `"friend" | "crew" | "ex" | "collab" | "rival" | "mentor" | "dating"`, and `t` is tension 0..10.
  - An outcome's `tie = { a, b, k?, t? }` sets the kind and adds to the tension. `a` and `b` may be `"$"`, `"$b"` or a written id.
  - Gates: `needs.tie = { a, b, k?, t? }` and `under.tie`.
  - Crossing `t >= 6` raises `"tie:<key>:hot"`, and falling under 3 raises `":cool"`.
  - `CastRules.Make` ties a new person to one existing close person with chance `Config.People.TieAtBirth = 30`, kind from their role (local_artist → crew or friend, producer_peer → rival or collab, and so on, per §C1).
- **Ripples:** an outcome's `rels = { { who, score?, flag?, clear?, clearWarn? }, … }` is written in order through `RelWrite`. A `who` that is archived updates `A.sc` only.
- **Chain slots:** an arc's items carry `chain = "<arcId>"`. Their text and gates may use `$` (the lead, the queue entry's `who`) and `$b` / `$c`.
  - `prof.walkins.chains[arcId .. ":" .. lead] = { era, start, slots = { b = id, c = id }, done = false }`.
  - A slot is bound once, the first time an item needs it (`WebRules.BindSlot`), and is never re-drawn.
  - An item with `newSlot = "c"` may bind `c` once, when `c` is unset.
  - An item with `revise = true` is an explicit revised agreement. It may change the chain's `terms` and `credits` (`chains[k].terms`, `chains[k].credits`) and records `revised = day`.
    - It **never changes `slots`**: the people stay the same.
    - A new person joins a chain only through `newSlot` (a real introduction), once.
  - **The project beat.** When plan 2's promise delivery raises `"request:<who>"`, it passes `fields = { promise, beat = { pattern, bpm, stars } }`. Every open chain record whose lead or slot is `who` then stores `lastBeat`: a copy of that beat, the project actually delivered.
- **Grants:** `prof.grants = { [key] = day }`. `GrantRules`:
  - `EventKey(itemId, lead, era) -> "e:" .. …`. A follow-up of a chain resolves once. Pick skips a due entry whose key is granted, and removes it.
  - `AchKey(ids, era, family, tier) -> "a:" .. sorted(ids) .. …`
  - `ItemKey(itemId) -> "i:" .. itemId`
  - `Grant(grants, key, day) -> boolean`: true only the first time.
- **Keepsakes:** `prof.keepsakes = { { id, chain, era, day, story = { ids }, credits = { ids }, beat = { pattern, bpm, stars }? } }`.
  - They are never changed or removed.
  - An outcome's `keepsake = { family, story = { "$", "$b" }, credits = { "$" }, beat = "project" | nil }` mints one through `GrantRules` (`AchKey` on the story people).
    - With `beat = "project"`, the record pins the chain's `lastBeat`. With no `lastBeat`, it has no beat.
    - A keepsake never takes your current best beat, so it can't name a beat that wasn't the project. Copy that promises "your track" is used only with `beat = "project"` (a `walkins_data_spec` rule).
  - The discography shows it, in words from §C1.
- **The era:** `prof.era`, default 1. Every chain record, grant key and keepsake carries it. Gear, fits and rooms already live outside `prof.career` (`prof.gear`, `prof.career.gates`); §6's "kept apart" needs no move now. This plan records which fields a new era must keep (`research/endless/era_fields_2026-11-12.md`).
- **Config:** `Config.People = { CloseDays = 14, ReactMax = 40, TieAtBirth = 30, FireHypeMax = 3 }`.

---

### Task 1: Values and your public image (§4.6)

**Files:**
- Create: `research/endless/copy_2026-11-12.md` §C1:
  - the four image labels and the Career tab line ("THE INTERNET: {label}")
  - every written person's values
  - the tie kinds' words and the birth-tie table by role
  - the discography's keepsake line
  - the warning-sign line variants (short replies)
- Create: `src/ReplicatedStorage/OK/Modules/PeopleRules.lua` (`ValuesOf`, `Label`, `React`, `ImageStep(image, fireToday)`) and `spec/people_rules_spec.lua`.
- Modify: `Data/Web.lua` (`Values`, `Reacts`); `Config.lua` (`Config.People`).
- Modify: `Systems/Web.lua`:
  - On `"day"`:
    - `ImageStep` runs
    - `React` runs for close people with the day's label, with score and `w` applied through `WalkIns.WriteRel`
    - their own `cast:<id>:rise` / `:fall` events react with `"rise:self"` / `"fall:self"`
  - On `"fire"`: `h` +1, up to `FireHypeMax` a day.
- Modify: `Systems/WalkIns.lua` and `Systems/Phone.lua` `apply`: an outcome's `image`. `repairRel` keeps `w` (0..5).
- Modify: `Systems/Career.lua` `State`, `Modules/PanelUI.lua` (the Career tab line).
- Modify: `Modules/CareerSim.lua`: the same image, decay and reactions.
- Create: `build/t160a_play_server.lua`, `build/t160b_play_client.lua`.

**Interfaces:**
- Produces: `PeopleRules.*`, `prof.walkins.image`, `rel[id].w`, the reaction step. Tasks 3, 6 and 7 gate on the label and `w`.

- [ ] **Step 1: Write §C1** and scan it.
- [ ] **Step 2: Write the failing tests.**
  - **people_rules_spec:**
    - `Label` for `{ m = 5, h = 9 }` is MESSY, for `{ h = 4 }` HYPED, for `{ r = 5 }` RESPECTED, and for `{}` QUIET
    - `ImageStep({ h = 3, m = 2, r = 4 }, 0)` gives `{ h = 2, m = 1, r = 4 }`
    - `ImageStep({ h = -2 }, 0)` gives `h = -1`
    - `React({ "clout" }, "QUIET", Reacts)` gives §C1's table entry, and `{ "loyalty", "clout" }` gives the sum
  - **t160a:**
    - an outcome with `image = { h = 5 }` gives HYPED
    - 3 FIRE through the Reactions hook add 3, and a 4th adds 0
    - a day step moves `h` down 1
    - buying gear, a fit and a room, and equipping the fit, leave `image` unchanged
    - a close clout-valuing generated person gets `w` +1 on a QUIET day
    - marker `T160A PLAY OK`
  - **t160b:** the Career tab line shows the label at the three viewports, inside the viewport.
- [ ] **Step 3:** Spec FAIL; controller red → FAIL. **Implement.**
- [ ] **Step 4:** Specs PASS (pacing printed). Controller:
  1. Sync `Modules/PeopleRules`, `Data/Web`, `OK/Config`, `Systems/Web`, `Systems/WalkIns`, `Systems/Phone`, `Systems/Career`, `Modules/PanelUI` and `Modules/CareerSim`.
  2. The refresh.
  3. `--play t160 t41 t21 t28` → PASS.
- [ ] **Step 5: Commit** `E3-T1: people care about different things and read how the internet sees you`.

### Task 2: People know each other (§4.6 ties)

**Files:**
- Create: `src/ReplicatedStorage/OK/Modules/TieRules.lua` (`Key`, `Get`, `Set`, `Push(ties, a, b, k, dt) -> tie, crossed?`, `Close(ties, id) -> { ids }`) and `spec/tie_rules_spec.lua`.
- Modify: `Modules/WebRules.lua`:
  - the tie gates read `extra.ties` (plan 2's fifth `GateOk` argument); the warning gates read `extra.warn`
  - `Resolve` replaces `$`, `$b` and `$c` in `tie` writes and gates
- Modify: `Modules/CastRules.lua` `Make`: the birth tie, with chance `TieAtBirth`, through `castRng`. It returns `tie = { a, b, k }` for the caller to write.
- Modify: `Systems/Web.lua` and `Systems/WalkIns.lua` / `Systems/Phone.lua` `apply`:
  - an outcome's `tie`
  - the `"tie:*"` events
  - `state()` repairs `ties`: only known ids, `k` from the list, `t` 0..10
- Modify: `Modules/ContactRules.lua`: a person's memory line can come from their hottest tie ("FELL OUT WITH {name}", "CREW WITH {name}"; §C1). Modify: `Modules/CareerSim.lua`.
- Create: `build/t161a_play_server.lua`.

**Interfaces:**
- Consumes: Task 1.
- Produces: `TieRules.*`, `prof.walkins.ties`, the tie gates and `tie:*` events. Tasks 4, 6 and 7 use them.

- [ ] **Step 1: Write the failing tests.**
  - **tie_rules_spec:**
    - `Key("g7", "g3") == "g3|g7"`
    - `Push` to 6 from 5 returns `crossed = "hot"`, and down to 2 returns `"cool"`
    - `t` stays in 0..10
    - `Close` lists the other end of each of an id's ties
  - **t161a:**
    - `Make` with a forced tie roll ties g2 to the close g1 as `crew`
    - an outcome `tie = { a = "$", b = "g1", t = 6 }` bound to g2 raises `"tie:g1|g2:hot"`, and a test trigger on it plants
    - JSON round trip and `state()` keep `ties`; junk is dropped
    - CONTACTS' memory line for g2 names g1
    - marker `T161A PLAY OK`
- [ ] **Step 2:** Spec FAIL; controller red → FAIL. **Implement.**
- [ ] **Step 3:** Specs PASS. Controller: sync `Modules/TieRules`, `Modules/WebRules`, `Modules/CastRules`, `Systems/Web`, `Systems/WalkIns`, `Systems/Phone`, `Modules/ContactRules` and `Modules/CareerSim`, then the refresh; `--play t161a t150a t134` → PASS.
- [ ] **Step 4: Commit** `E3-T2: people have ties to each other, with tension that events push`.

### Task 3: Warning signs, switch-ups and winning people back (§4.6)

**Files:**
- Modify: `Modules/WalkInRules.lua` `GateOk`: `needs.warn` and `under.warn` on the card's own visitor, or on the bound `$` through `WebRules.Resolve`.
- Modify: `Modules/PeopleRules.lua`: `Signs(rel, id) -> n` (the `w` count). `LineFor(item, rel)`: an item's `lineWarn` is the bubble once `w >= 1` (a shorter reply, §C1).
- Modify: `Systems/WalkIns.lua` and `Systems/Phone.lua`:
  - the bubble line through `LineFor`
  - a declined request card or a passed listen-back raises `"skip"` for its person (React)
  - `rel.clearWarn`
- Modify: `Data/Web.lua`: one switch-up and one win-back as role follow-ups for `@local_artist` (§C1):
  - the turn: `needs.warn = 2`
  - the win-back: `needs.flags = { "$.turned" }`, choice 1 with `clearWarn`
- Modify: `spec/walkins_data_spec.lua`: every item flagged `turn = true` has `needs.warn >= 2` (the spec's rule, enforced on all content). Modify: `Modules/CareerSim.lua`.
- Create: `build/t162a_play_server.lua`.

**Interfaces:**
- Consumes: Task 1's `w`.
- Produces: `needs.warn`, `turn = true`, `lineWarn`, `"skip"`, `clearWarn`. The arcs (Tasks 6 and 7) use them.

- [ ] **Step 1: Write the failing tests.**
  - **people_rules_spec:** `LineFor` returns `lineWarn` at `w = 1` and `line` at 0.
  - **walkins_data_spec:** the rule above.
  - **t162a:**
    - g1 at `w = 1`: the turn isn't eligible (`Peek` 200)
    - a `"skip"` with a clout-valuing g1 makes `w = 2`, and the turn becomes eligible
    - it arrives, its bubble is the `lineWarn` text, and `turned` is set
    - the win-back arrives, and choice 1 gives `w = 0`
    - an old-save `rel.g1` with no `w` reads 0
    - an archived and returned g1 keeps `w`
    - marker `T162A PLAY OK`
- [ ] **Step 2:** Spec FAIL; controller red → FAIL. **Implement.**
- [ ] **Step 3:** Specs PASS. Controller syncs (as touched), then the refresh; `--play t162a t160a t155a` → PASS.
- [ ] **Step 4: Commit** `E3-T3: switch-ups come only after two warning signs; you can win people back`.

### Task 4: Choices ripple (§4.6)

**Files:**
- Modify: `Modules/WalkInRules.lua` (`RelWrite` stays), `Systems/WalkIns.lua` and `Systems/Phone.lua` `apply`, and `Modules/CareerSim.lua`: an outcome's `rels` list written in order. An archived `who` updates `arc[id].sc`.
- Modify: `Modules/WebRules.lua` `Resolve`: `$`, `$b` and `$c` in `rels`.
- Modify: `spec/walkins_data_spec.lua`:
  - the cost rules apply only to items marked `dispute = true` (two people at odds), never to cooperative scenes:
    - in a dispute item, a choice marked `side = "$"` (or `"$b"`) backs that person, and must lower the other's score
    - in a dispute item, a choice marked `neutral = true` (staying out of it) must have its own cost: a negative `rels` score, or a `tie` with `t > 0`
  - outside dispute items, `rels` may raise everyone, for example two collaborators both delivering on a shared project; a negotiated decline needs no penalty
- Create: `build/t163a_play_server.lua`.

**Interfaces:**
- Consumes: Tasks 2 and 3.
- Produces: `rels` and the ripple rules the arcs follow.

- [ ] **Step 1: Write the failing tests.**
  - **walkins_data_spec:** the two rules, on fixtures and then on all content.
  - **t163a:**
    - a test item with `rels = { { who = "$", score = 1 }, { who = "$b", score = -1 } }` bound to g1 and g2 moves both
    - with g2 archived, `arc.g2.sc` moves and g2 stays archived
    - `who = "nobody"` changes nothing and reports nothing
    - marker `T163A PLAY OK`
- [ ] **Step 2:** Spec FAIL; controller red → FAIL. **Implement.**
- [ ] **Step 3:** Specs PASS. Controller syncs, then the refresh; `--play t163a t150a` → PASS.
- [ ] **Step 4: Commit** `E3-T4: backing one person costs you with another; staying out has its own cost`.

### Task 5: Rewards from people: chain slots, grants once, keepsakes that never change (§4.8)

**Files:**
- Create: `src/ReplicatedStorage/OK/Modules/GrantRules.lua` (`EventKey`, `AchKey`, `ItemKey`, `Grant`, `Keepsake(spec, slots, beat, era, day) -> record`) and `spec/grant_rules_spec.lua`.
- Modify: `Modules/WebRules.lua`: `BindSlot(chains, arcId, lead, slot, item, opts, rng)`. It honours `newSlot` and `revise` per Shared shapes. `Resolve` reads the chain's slots.
- Modify: `Systems/Web.lua`, `Systems/WalkIns.lua` and `Systems/Phone.lua`:
  - `prof.walkins.chains`, `prof.grants`, `prof.keepsakes` and `prof.era` defaulted and repaired. Keepsakes are only appended, and a repair never edits one.
  - a chain follow-up's `EventKey` is granted on resolve; a granted one in the queue is removed, never shown
  - an outcome's `keepsake` mints once through `AchKey`
  - a chain's last link sets `done`
  - plan 2's archive `busy` adds every person in an open chain record
- Modify: `Systems/Life.lua` / `Modules/LifeRules.lua` `DiscoText`: a keepsake row, with credits shown apart from story people (§C1).
- Create: `research/endless/era_fields_2026-11-12.md`: which saved fields a new era keeps (gear, fits, sounds, room items, keepsakes, the Hall of Fame source in `life.disco`) and which reset (career, walkins, sessions). This is for the after-launch plan; no code.
- Modify: `Modules/CareerSim.lua`: the same keys, so a replayed sim chain can't double-grant.
- Create: `build/t164a_play_server.lua`.

**Interfaces:**
- Consumes: Tasks 1–4; plan 2's queue, its archive, and the `"request:<who>"` event's `fields.beat`. Plan 2 Task 7's `Deliver` passes `fields.beat`; if the built code doesn't, this task adds it.
- Produces: `GrantRules.*`, chain records and keepsakes. The after-launch reward plan and Codex's item map key items off `ItemKey` and keepsakes.

- [ ] **Step 1: Write the failing tests.**
  - **grant_rules_spec:**
    - `AchKey({ "g7", "g3" }, 1, "beef", 1) == AchKey({ "g3", "g7" }, 1, "beef", 1)`
    - `Grant` is true then false
    - era 2 gives a new key
    - `Keepsake`'s `story` and `credits` are separate copies; `beat` is copied, not referenced
  - **t164a:**
    - a test chain bound to g1 binds `$b` (g2) once; a later item asking `$b` gets g2 again
    - a `newSlot = "c"` item binds g3 once
    - a `revise` item changes the credits and records `revised`, while `slots` stay the same people
    - resolving the chain's follow-up twice (re-planted through the hook) grants once and shows once
    - a promise delivered for g1 in the chain sets `lastBeat`, and the keepsake pins it; the keepsake's `beat` stays the same after `SetRecent` changes the recent beats and after a better beat is delivered for someone else
    - a keepsake minted with no delivered project has no beat
    - archiving is refused for g1 to g3 while the chain is open
    - a JSON round trip keeps keepsakes byte for byte
    - marker `T164A PLAY OK`
- [ ] **Step 2:** Spec FAIL; controller red → FAIL. **Implement.**
- [ ] **Step 3:** Specs PASS. Controller: sync `Modules/GrantRules`, `Modules/WebRules`, `Systems/Web`, `Systems/WalkIns`, `Systems/Phone`, `Systems/Life`, `Modules/LifeRules` and `Modules/CareerSim`, then the refresh; `--play t164a t155a t66 t71` → PASS.
- [ ] **Step 4: Commit** `E3-T5: chains keep their people; every reward is granted once; keepsakes never change`.

### Task 6: The arcs, batch 1 (§4.6 scenarios 1–5)

**Files:**
- Modify: `research/endless/copy_2026-11-12.md` §C2. Arcs 1–5, each 4–8 linked items across weeks of played days, using slots, ties, values, the image, warnings and ripples:
  1. the same-week drop
  2. the clout switch-up
  3. the screenshot
  4. the beat that went to the wrong song (a promise's delivered record names the beat)
  5. the crew split
- Modify: `Data/Web.lua`: the five arcs as chains (`chain = "arc1"` … `"arc5"`), each started by a trigger (§C2 names it). Add them one arc at a time, with the full pacing run after each.
- Modify: `spec/walkins_data_spec.lua`:
  - each arc's links resolve
  - every `turn` follows the warning rule
  - every `dispute` item's `side` and `neutral` choices follow the ripple rules
- Modify: `spec/pacing_spec.lua`: on the 200 seeds, each arc is reached by some random run, its median length in played days is ≥ 14 ("weeks or months"), and every guardrail holds.
- Create: `build/t165a_play_server.lua`: arc 1 end to end through the hooks, with both artists and both endings (back one, then on a fresh run the joint track).

**Interfaces:**
- Consumes: Tasks 1–5.
- Produces: arcs 1–5.

- [ ] **Step 1: Write §C2** and scan it.
- [ ] **Step 2: Write the failing tests.**
- [ ] **Step 3: Implement** one arc at a time. If an arc can't be reached on the 200 seeds, tune only its trigger's `chance` (1..100) and its first item's `weight` (1..3). If that fails, stop and bring the numbers.
- [ ] **Step 4:** Specs PASS. Controller: sync `Data/Web`, then the refresh; `--edit t40_ t50_ t46` and `--play t165a t156a` → PASS.
- [ ] **Step 5: Commit** `E3-T6: arcs 1-5`.

### Task 7: The arcs, batch 2 (§4.6 scenarios 6–10)

**Files:**
- Modify: `research/endless/copy_2026-11-12.md` §C3 (arcs 6–10) and §C4 (the full approval list for plan 3):
  6. the mentor who gets jealous
  7. the brand-safety ask (the sponsor rep, `rel.rep`)
  8. the fake friend
  9. the comeback (a fallen person, `pk >= 3`, `lv <= 2`)
  10. the breakup album (a `dating` tie)
- Modify: `Data/Web.lua`, `spec/walkins_data_spec.lua` and `spec/pacing_spec.lua` as in Task 6.
- Create: `build/t166a_play_server.lua`: arc 8 end to end, with its warning signs over weeks, both the confront and the keep-close choices, and the keepsake rules.

**Interfaces:**
- Consumes: Task 6.
- Produces: arcs 6–10.

- [ ] **Steps 1–5:** as in Task 6. Commit `E3-T7: arcs 6-10`.

### Task 8: Report and integration

**Interfaces:** Produces none. It reports on Tasks 1–7.

**Files:**
- Create: `research/endless/lives_report_2026-11-12.md`:
  - every pacing number before and after
  - each arc's reach and length
  - switch-ups per 200 seeds, and their warning counts (every one ≥ 2)
  - win-backs
  - the image label's share of days per policy
  - the user's list: §C4's approval list, the values table, the reaction table and the birth-tie table
- [ ] **Step 1:** `sh tools/spec.sh` → every spec PASSES. Paste the numbers.
- [ ] **Step 2:** The full Studio suite with no failures (one rerun per flake), `walkins_pause_off`, guard green.
- [ ] **Step 3:** A whole-branch final review on the most capable model, against this plan and spec §4.6 and §4.8, **and** against the three endless plans together for spec §10's "Done means". One fix dispatch, then a scoped re-review.
- [ ] **Step 4:**
  - README "People's own lives"
  - the tracker (Now, Needs you, Done log; spec §10 ticked line by line with its evidence)
  - IDEAS.md
  - snapshot `v46_people_lives`; export; push to GitHub
- [ ] **Step 5: Commit** `E3-T8: people's lives report and integration`.

---

## Claude's calls (plan)

1. **Warnings live on the relationship entry (`rel[id].w`)** for written and generated people alike. Why: one rule for everyone, and `rel` is already what every gate reads. Archiving packs it.
2. **The image is three small numbers with a fixed label order, MESSY first.** Why: the spec asks for "a simple read", and messy has to win over hyped, or drama would read as hype.
3. **Reactions run once a played day, for close people only** (at most 40). Why: 150 people reacting to every event would be noise and a cost on every pick. "Close" is the people a player would notice.
4. **Multi-person chains use named slots (`$b`, `$c`) on a chain record, not a table-valued `who`.** Why: it keeps plan 2's queue entry shape, and §4.8's "bind a NEW slot once" and "revised agreement" then have exactly one place to live.
5. **Event-once applies to chain follow-ups, not to repeatable situation cards.** Why: the spec wants situations to come back with someone new ("Mix of new and if yes it feels new"), while a chain's links are history.
6. **No item catalog at launch.** Keepsakes are the only things people give, shown in the discography, and items wait for the reward plan (spec §4.8's last line). Why: the 20-item map and prices are still proposals.
7. **New-era carryover is written down, not built** (`era_fields`). Why: the spec puts new eras after launch, and asks launch only to leave room. `prof.era` and the era in every key are that room.
8. **The ripple cost applies only to authored disputes** (`dispute = true` items, their `side` and `neutral` choices). Why: in a real conflict, backing one person costs you with the other, and staying out has its own cost. A joint success or a polite decline isn't zero-sum, and a blanket rule would force penalties onto cooperative scenes. (From Codex's review, 11-12 21:49.)
