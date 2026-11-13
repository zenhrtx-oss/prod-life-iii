# Endless Play 2: The Story Web, Generated People and Endless Requests — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Implementers write files and run CLI specs only; the controller is the only Studio client.

**Goal:** People and situations that never run out.
- **The story web.** A choice plants who shows up, when and in what mood, and one event triggers others.
- **Roles.** Cards and requests written for a role, such as `@hometown`, are filled by people you've met or by new generated people.
- **People with a life of their own.** Generated people rise and fall, and they remember who helped them.
- **Endless requests.** People keep asking for beats.
- **Everyday life.** A producer's ordinary life fills the quiet stretches.
- **No daily visit limits.**
- **The archive.** Nobody is ever deleted, and the save stays bounded.

**Architecture:**
- **Pure first:**
  - `Modules/CastRules` (new) makes and grows generated people from a seed.
  - `Modules/WebRules` (new) holds the content merge, role binding, triggers and the trigger queue's due rule.
  - `WalkInRules` gains the queue-entry fields and the `$` gate token.
  - `Data/Cast` (new) holds the pieces generated people are made from.
  - `Data/Web` (new) holds roles, role cards, life situations, chains, triggers and request templates.
- **One merged deck.** Every consumer reads `WebRules.Merge(Data/WalkIns, Data/Web)` instead of `Data/WalkIns` alone: Systems/WalkIns, Systems/Phone, Systems/Career, the specs and t46.
- **Server:**
  - `Systems/Web` (new) takes events from Life, Contracts, Reactions, BeatBattles, Career and Gear, plants triggered situations, and runs people's daily lives.
  - WalkIns and Phone bind role cards when they pick.
  - Contracts keeps promised requests.
  - DataService gains archive pages.
- **Client:** generated faces on the walk-in card, the phone and CONTACTS; promised requests in REQUESTS.

**Tech Stack:** Luau (Roblox), Roblox Studio via the built-in Studio MCP (`tools/mcp_call.py`), `tools/sync.py`, `tools/test.py`, `sh tools/spec.sh`, the `luau` CLI, Python 3.

**Spec:** `specs/2026-11-12-endless-play-design.md`:
- §4.1 the story web
- §4.2 endless requests
- §4.3 two kinds of people
- §4.4 roles
- §4.5 memory, growth and the archive
- §4.7 where the words come from
- §8, and §10's "The story web" and "People" lines

§4.6 and §4.8 are plan 3's, which builds on this plan's Interfaces.

**Execution order:**
1. The rooms plan's R-T8..R-T16.
2. The people plan without its Task 4.
3. Endless plan 1 (`plans/2026-11-12-endless-1-long-sessions.md`).
4. **This plan.**
5. Plan 3 (`plans/2026-11-12-endless-3-people-lives.md`).

**What this plan relies on from earlier plans:**
- **The people plan:**
  - `prof.walkins.met`, `MarkMet` / `IsMet` with a `peopleSet` argument, and `peopleFor(st)` in Systems/WalkIns (Task 3)
  - `ContactRules` / `Systems/Contacts` (Task 5)
  - `StarEntry` / `StarsOpen` (Task 9)
- **Plan 1:**
  - `RewardGate`, the curve, `LONG` and the five-hour personas
  - the `Delivery` source being curved

Line numbers are from 11-12; the pre-flight scan re-reads them.

## Global Constraints

- **No git.** Every commit step is `sh .superpowers/g add -A src build spec specs plans research README.md && sh .superpowers/g commit -q -m "<task>: <what>"`.
  - Add `tools` when a tool changes.
  - Every message ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
  - Task prefix `E2-T<n>`.
- **One Studio client.** Implementers never call `tools/sync.py`, `tools/test.py`, `tools/mcp_call.py`, a build script or any `mcp__Roblox_Studio__*` tool. The controller does all of that under the Studio lease: red, sync, the module refresh, then green. Run suites only with load under 30; one rerun per flake.
- **Scoped syncs only** (`--dry` first, parent-qualified patterns, never `--force`). **Selectors are substrings** (`t150_`, `t151a`).
- **Pure modules never touch Roblox globals and never `require`:** `CastRules`, `WebRules`, `WalkInRules`, `CareerSim`, `Data/Cast`, `Data/Web`, `Data/WalkIns`.
  - CLI specs require them by relative path.
  - Literal Config copies stay in `spec/economy_fixture.lua`, pinned by `build/t46_check.lua`.
- **Spec §4, verbatim:**
  - "a fiction-safe name (never a real person)"
  - "a code-built look (no uploads)"
  - "Each player's generated people are their own"
  - "A chain keeps its person … never re-drawn from the role"
  - "The original `homekid` stays as the written first one"
  - "The 21 hand-written briefs stay as written; their 'pays the first time only' rule still applies to them"
  - "The one-active-request slot … stays"
  - "Arrivals stay spaced by today's gap timer (4–6 minutes) … with triggered situations first"
  - "About **150 people stay active** per player"
  - "Nobody is ever deleted"
  - "Schema stays v5 with lazy fields"
  - "no line is invented at run time"
  - "No crime storylines"
- **The draws.** Binding a role, making a person and every trigger's chance draw from their own stream, never the pick stream:
  - the server: `castRng`, a second `Random` per player
  - the sim: `Lcg(seed + 200003)`

  That way today's walk-in and phone picks are unchanged until role content joins the deck.
- **The pacing guardrails stay green after every task.** That covers every assertion in `spec/pacing_spec.lua` from the people plan and plan 1:
  - the early game
  - the steady-share floor and ceiling for the existing policies
  - phone Aura ≤ 15
  - plan 1's bounds for `solo5h` and `social5h`
  - the climb

  If a content batch can't hold them within its stated ranges, stop that task and bring the numbers.
- **Saves:** schema stays **v5**. Every new field is lazily defaulted and repaired in WalkIns' `state()` or Contracts' `state()`:
  - `prof.walkins.cast`, `prof.walkins.arc`, `prof.walkins.arcIdx`
  - queue entries' `who`, `day`, `on`, `pri`
  - `prof.sessions.promises`, `prof.sessions.qNext`

  Old saves load unchanged. t41's walkins keys after a bare load stay as they are (lazy fields are absent until written).
- **Content:** every line players see comes from `research/endless/copy_2026-11-12.md` §B and goes on its approval list.
  - Rules: CAPS headlines and tags, lowercase bubbles, names only through `{name:<id>}` and `{name:$}` (the bound person).
  - Banned: OK branding (t50; the plain word "ok" is fine), CRED/Cred (t40), the BLOCK words, crime storylines.
  - No bond or level label reuses "COLD" or "BUSY DAY".
- **Phone first:** every new control is ≥ 44 px, inside the viewport and not overlapping, at 667×375, 771×390 and 844×390.
- **Test numbers:** t150–t159.
  - Edit checks are `tNNN_check.lua` (marker `T150 OK`).
  - Play files are `tNNNa_play_server` / `tNNNb_play_client` (marker `T151A PLAY OK`). Each play file:
    - starts with its own `fresh()`: unseat, the lounge, Phone `Quiet` + `Reset`, WalkIns `Reset`, Career `Reset`, Life `Reset`, Web `Reset`, `ResetHints`
    - runs in a pcall with cleanup and a rethrow
    - finishes in under 90 s
- **Standing limits:** never save or publish the place; no uploads; no Robux; no player-typed text; never flip `Config.Data.UseStoreInStudio`. `Config.SFX` stays 17. No new lights or parts in the hub.

## Review Focus

1. **Old saves and the hometown kid.**
   - A queued `payback_homekid` with no `who` arrives as `homekid`.
   - The first `@hometown` bind on any profile is `homekid`.
   - A stored `next` pick of a card that is now a role card is re-picked.
   - Queue entries with only `at` stay due as today.
   - `state()` keeps entries that have `day` or `on` instead of `at`.

   Test: t150a (legacy) and `web_rules_spec`.
2. **Two chains of one follow-up for two people.** `payback_hometown` queued for `homekid` and for `g3` at once: both are kept (Plant is unique on id + who), each arrives with its own person and name, and taking one leaves the other. Test: `walkin_rules_spec` (Plant) and t150a.
3. **A role card nobody can play.** With no candidate whose `$` gates hold, and minting off for that card, the card is never picked. A stored pick whose person was archived since is re-bound or re-picked, never shown with a blank name. Test: `web_rules_spec` and t155a.
4. **The archive never takes someone the web still needs:** anyone with an open promise, a queued entry naming them, a visit in flight, or a waiting pop from them. Test: `cast_rules_spec` (`ArchiveOrder`) and t155a.
5. **Names.**
   - No generated name equals an entry of `Data/Cast.Blocked` (real artists, producers and the parody stars' real counterparts) or any written visitor's name in either roster.
   - Two people in one player's cast never share a name.

   Test: `cast_rules_spec` over every name the parts can make.

---

## Shared shapes

- **A generated person** (state, saved): `prof.walkins.cast = { next = n, people = { [id] = P } }`. Ids are `"g" .. n`, from `next`.
  - `P = { s = seed, r = roleId, lv = 1..5, pk = peak lv, b = born day, ls = last seen day, h = times you delivered for them }`.
  - Plan 3 adds its fields (`v`, `w`) lazily.
- **A face** (derived, never saved): `CastRules.Face(P, parts) -> { name, color = {r,g,b}, sig, style, genre, goal, values = {v1, v2?}, traits = {t1, t2?}, look = { body, skin, color, accent, sig } }`.
  - It is deterministic from `P.s` through `CastRules.Lcg(P.s)`.
  - `parts` is `Data/Cast`.
- **Levels:** `Data/Cast.Levels = { "LOCAL", "BUZZING", "UNDERGROUND", "SIGNED", "BLOWN UP" }` (words in §B3). A role's `lv` range is the levels a new person in it starts at.
- **Roles** (`Data/Web.Roles`, the first list per spec §4.4 and §9, Claude's call):
  - `hometown` (written first: `homekid`)
  - `local_artist`
  - `promoter`
  - `producer_peer`
  - `scene_blogger`
  - `label_scout`

  Each is `{ id, kind, lv = { lo, hi }, mint = 0..100 }`:
  - `kind` is the visitor kind used for the UI
  - `mint` is the percent chance a bind makes a new person when someone already fits
- **Role cards and follow-ups** have `visitor = "@<role>"`. Their gates may use `$` for the bound person:
  - `needs.flags = { "$.helped" }`
  - `needs.rel = n` (the bound person's score)
  - `needs.lv = n` / `under.lv = n` (the bound person's level)

  Text uses `{name:$}`. An outcome's `rel.who` may be `"$"`.
- **A queue entry** (`prof.walkins.queue[i]`): `{ id, at?, day?, on?, who?, pri?, ctx? }`.
  - **Due** when `at <= count + 1`, or `day <= today` (the career day).
  - An `on` entry is never due until `WebRules.Fire` turns it into `at = count + 1`.
  - Order: higher `pri` first (nil = 0), then the smaller of `at` / `day`.
  - `WalkInRules.Plant(state, plant, defaultAt, rng, ctx, opts)`:
    - `plant` is `{ id, at? | day? | on?, pri? }`
    - `opts = { who?, today? }`
    - a `day` range is drawn from `opts.today`
    - it refuses only an entry with the **same id and the same who**
- **WebRules (pure):**
  - `Merge(W, Web) -> Content`. `Content` has every field `Data/WalkIns` has today (`Visitors`, `Cards`, `Followups`, the indexes, `RelFlags`, `Deck`, `Names`, `SponsorName`, `WaitLines`, `NoteLines`), with Web's lists appended in order, plus `Roles`, `RoleById`, `Triggers` and `Requests`. `Deck` gains `roles`.
  - `Candidates(item, opts) -> { ids }`, where `opts = { cast, rel, met, roles, today, career }`.
    - These are the role's members (written first, then `cast.people` of that role, in id order) for whom the item's gates hold with `$` replaced by the id.
    - A role's written members are `Web.Roles[i].written` (`{ "homekid" }` for hometown).
  - `Bind(item, opts, rng) -> who, made`:
    - the first `@hometown` bind with `homekid` not yet in `rel` or `met` returns `"homekid"`
    - otherwise `rng(1, 100) <= role.mint`, or no candidates while `item.mint ~= false`, makes a new person (`made = true`; the caller calls `CastRules.Make`)
    - otherwise the candidate is drawn with weights `1 + max(score, 0) + (seen within 7 days ? 1 : 0)`
  - `Resolve(item, who) -> item copy`, with `"$"` and the item's `@role` visitor replaced by `who` in `visitor`, `rel.who` and every gate.
  - `NamesFor(baseNames, cast, parts) -> names`: base, plus each generated id's face name.
  - `Triggered(triggers, event, fields, career, rng) -> { { plant, who } }`.
  - `Fire(state, event) -> n`.
- **Events** (strings; `Systems/Web.Event(p, name, fields)`):
  - `"delivery"`, `"delivery3"`, `"fire"`, `"cypher_win"`, `"day"`
  - `"buy:<gateOrGearId>"`, `"tier:<TIER>"`
  - `"rel:<who>:up"` / `"rel:<who>:down"` (a score crossing +2 or −2)
  - `"cast:<id>:rise"` / `"cast:<id>:fall"`
  - `"request:<who>"` (a promised beat delivered)
- **A trigger** (`Data/Web.Triggers`): `{ on = event | prefix .. "*", needs?, under?, chance = 1..100, plant = { id, at?|day?, pri? }, who = "@role" | "$event" | nil }`. `"$event"` is the person the event names, from `fields.who`.
- **A promise** (`prof.sessions.promises`, at most `Config.Web.MaxPromises = 3`): `{ id = "q" .. n, who, tpl, lv, day, t }`, where `t` is a title index.
  - Its brief is `WebRules.BriefFor(promise, Web.Requests, names)`:
    - `{ id, artist = who, title, asks, bonus, reward = { cred = tpl.pay[lv], xp = tpl.xp[lv] }, promise = true }`
    - the starting pay table, Claude's call: `pay = { 250, 350, 450, 550, 650 }` and `xp = { 20, 25, 30, 35, 40 }` by level
  - Delivering it pays once, through `Delivery`, and removes it.
- **Config** (this plan's additions):
  - `Config.Web = { MaxPromises = 3, RepeatDays = 7, Generated = { share = 0.5 } }`
  - `Config.Cast = { Active = 150, ArchiveDays = 30, Budget = <E2-T12's measured bytes>, PageBytes = 200000, Grow = { rise = 8, fall = 5, helped = 4 } }`, in percent a played day
  - `Config.WalkIns.DailyMax = 120` and `Config.Phone.DailyMax = 150`: backstops, not walls (E2-T8)
- **Server hooks:**
  - `_StudioWebHook`:
    - `Event(uid, name, fields)`, `Cast(uid)` (a copy), `SetCast(uid, cast)` (through the repair), `Make(uid, role, seed)`, `DayStep(uid)`
    - `Archive(uid)` (runs the archive rule now), `Arc(uid)`, `Reset(uid)`
  - `_StudioWalkInHook` gains `Queue(uid)` (a copy) and `Bound(uid)` (the in-flight visit's `who`).
  - `_StudioContractsHook` gains `Promises(uid)` and `Promise(uid, who, tpl, lv)`.

---

### Task 1: One merged deck (the seam)

**Files:**
- Create: `src/ReplicatedStorage/OK/Modules/WebRules.lua`, with `Merge` only for now. Create: `src/ReplicatedStorage/OK/Data/Web.lua`, the empty skeleton `{ Roles = {}, Visitors = {}, Cards = {}, Followups = {}, Triggers = {}, Requests = {} }`.
- Create: `spec/web_rules_spec.lua`.
- Modify every **runtime and pacing** consumer to read `WebRules.Merge(W, Web)`. Each requires `Data/Web` and `Modules/WebRules` beside Data/WalkIns. The list comes from `grep -rln "Data.WalkIns\|Data/WalkIns" src build spec`, run at the task's start. On 11-12 it was:
  - `Systems/WalkIns.lua` :130, `Systems/Phone.lua` :62, `Systems/Career.lua` :266, `Modules/Visitor.lua`
  - any client module the grep finds that reads `Names`, `WaitLines`, `NoteLines` or `VisitorById`; a missed one would show a generated visitor as a raw token
  - `spec/pacing_spec.lua`, `spec/walkins_data_spec.lua`, `spec/career_sim_spec.lua`, `spec/life_rules_spec.lua`, `spec/format_spec.lua`, `spec/visitor_looks_spec.lua` wherever they read the deck
  - `build/t46_check.lua`

  The ~50 `build/t4x`–`t12x` play files that check today's written content may keep requiring `Data/WalkIns` directly. Any test of Web content reads the merged deck. Record the final list in the ledger.
- Modify the word scans so new content can't slip past them:
  - `build/t40_check.lua` (d) and `build/t50_check.lua` add `ReplicatedStorage.OK.Data` to their scan roots (Data/Web now, Data/Cast from Task 2)
  - `spec/walkins_data_spec.lua` checks the BLOCK words and CRED/Cred over the merged deck's text
- Modify `spec/walkins_data_spec.lua`: every rule it checks runs over the merged deck. Content from both files obeys the same rules.

**Interfaces:**
- Produces: `WebRules.Merge` and the `Content` shape (Shared shapes). Every later task adds content to `Data/Web`, never to `Data/WalkIns`, except the `two_sessions` edit in Task 3.

- [ ] **Step 1: Write the failing spec:**
  - `Merge(W, emptyWeb)` has every key of `W`, and its lists equal `W`'s element for element.
  - Its indexes equal `W`'s.
  - `Names("parody")` and `Names("fiction")` equal `W.Names(…)`.
  - `Merge(W, { Cards = { x } })` appends `x` last, indexes it, and leaves `W.Cards` unchanged (Merge copies).
  - A Web card whose id collides with a W id makes Merge raise, naming the id.
- [ ] **Step 2:** `sh tools/spec.sh web_rules` → FAIL.
- [ ] **Step 3: Implement,** then switch the consumers.
- [ ] **Step 4:** `sh tools/spec.sh` → PASS; pacing prints the same numbers as before (an empty Web changes no draw). Controller: sync `Modules/WebRules`, `Data/Web`, `Systems/WalkIns`, `Systems/Phone` and `Systems/Career`, then the refresh; `--edit t46 t41_ t69` and `--play t43 t51 t79` → PASS.
- [ ] **Step 5: Commit** `E2-T1: one merged deck from Data/WalkIns and Data/Web`.

### Task 2: Generated people, pure (§4.3)

**Files:**
- Create: `research/endless/copy_2026-11-12.md` §B1–§B3:
  - **B1, name pieces.** About 60 stage-name pieces in two lists (a front and a back, e.g. "LIL" / "NOVA"), so a name is `front .. " " .. back` or `back` alone.
    - **The blocklist:** about 300 real artist and producer stage names, the nine parody stars' real counterparts, and every written visitor name in both rosters.
    - A web check of 20 sample names, recorded.
  - **B2, the character pieces.** Values (the six words of spec §4.6), about 30 traits (one or two words each), genres, and about 12 goals ("wants a first single out").
  - **B3, the five levels' words.**
- Create: `src/ReplicatedStorage/OK/Data/Cast.lua` (pure data: `Front`, `Back`, `Blocked`, `Values`, `Traits`, `Genres`, `Goals`, `Levels`, `Looks = { bodies = 3, skins = {…}, colors = {…}, sigs = {…existing VisitorLooks piece names…} }`).
- Create: `src/ReplicatedStorage/OK/Modules/CastRules.lua`:
  - `Lcg(seed)` (CareerSim's Park-Miller)
  - `Make(seed, role, lvRange, day, rng) -> P`
  - `Face(P, parts) -> face`
  - `NameOf(P, parts, taken?) -> name`: on a blocked or taken name it steps to the next back piece deterministically
  - `Grow(P, cfg, rng, helpedToday) -> P, "rise" | "fall" | nil`: implemented in Task 6, a stub returning `P, nil` here
  - `ArchiveOrder(people, busy, today, cfg) -> { ids }`: implemented in Task 11, a stub returning `{}` here
- Modify: `src/ReplicatedStorage/OK/Modules/VisitorLooks.lua`. Add `L.Generated(look) -> look`: the lanky B body with `look.body`'s height and width variant, the skin, the primary and accent colours, and one sig piece. ≤ `L.MAX_PARTS`, faces −Z, feet at y 0.
- Create: `spec/cast_rules_spec.lua`. Modify: `spec/visitor_looks_spec.lua`.

**Interfaces:**
- Produces: `Data/Cast`, the P and face shapes, `CastRules.Make` / `Face` / `NameOf`, and `VisitorLooks.Generated`. Task 3 binds with them, Task 4 draws them, and plan 3 reads `face.values`.

- [ ] **Step 1: Write §B1–§B3** and scan them (t40, t50, BLOCK).
- [ ] **Step 2: Write the failing tests.**
  - **cast_rules_spec:**
    - `Face` is the same for the same seed on two calls, and differs in name or colour for seeds 1..50 at least 45 times
    - over every front/back pair (and every back alone), no name is in `Blocked`; the spec builds the set of names the pieces can make and intersects it
    - `NameOf` with `taken` holding a seed's name returns a different one
    - every face has 1–2 values from `Values` and 1–2 traits
    - `Make(7, "local_artist", {1, 2}, 4, rng)` has `lv` in 1..2, `pk == lv`, `b == ls == 4` and `h == 0`
  - **visitor_looks_spec:** `L.Generated` for 200 seeds' looks stays ≤ `MAX_PARTS` parts with feet at 0, and `L.Frame` works on each.
- [ ] **Step 3:** `sh tools/spec.sh cast_rules visitor_looks` → FAIL.
- [ ] **Step 4: Implement.** `sh tools/spec.sh` → PASS. Controller: sync `Data/Cast`, `Modules/CastRules` and `Modules/VisitorLooks`; `--edit t40_ t50_` → PASS (they scan Data/Cast's words).
- [ ] **Step 5: Commit** `E2-T2: generated people from a seed, fiction-safe names, code-built looks`.

### Task 3: Roles and binding, pure, and in the sim (§4.4)

**Files:**
- Modify: `Modules/WalkInRules.lua`:
  - `Plant` (:177): the queue entry's `who`, `day`, `on` and `pri`; unique on id + who
  - `dueEntry` (:308): due by `at` or `day`; never `on`; the order by `pri`
  - `cardEligible` (:325): a card with `visitor` starting `"@"` is eligible only when `opts.bindable` (a function the caller passes) returns true for it; otherwise every check as today. `opts.today` joins the opts.
  - `GateOk` (:232) gains a fifth argument, `extra = { lvOf? }` (plan 3 adds `ties` and `warn` to the same table). With `extra.lvOf` it reads `needs.lv` / `under.lv` for the card's visitor. Callers pass `opts.extra`, and every existing call is unchanged with `extra` nil
  - `M.Pick`'s result for a due entry carries `entry.who`
- Modify: `Modules/WebRules.lua`: `Candidates`, `Bind`, `Resolve`, `NamesFor` (Shared shapes).
- Modify: `Data/Web.lua`: `Roles` (the six). Add three role follow-ups that carry `homekid`'s chain to every *other* hometown friend:
  - `payback_hometown`, from `payback_homekid`'s text with `{name:$}`
  - `hometown_show`
  - `hometown_album`

  They are copies of kid 1's, with `visitor = "@hometown"`, `$` gates and `notWritten = true`, so their candidates leave out the role's written members (§B4's first three).
  - **`homekid` keeps his own written chain.** When a bind gives `homekid`, the plant goes to `payback_homekid`, and `homekid_show` / `_album` / `_forgot` stay his.
  - The written chain and the role chain never both run for him.
  - Outcomes express this as `plant = { id = "payback_hometown", byWho = { homekid = "payback_homekid" } }`, which `WebRules.Resolve` turns into the written id.
- Modify: `Data/WalkIns.lua` `two_sessions` (:2006-2022):
  - choice 1's `rel.who = "@hometown"` and `plant = { id = "payback_hometown", at = { 10, 16 }, byWho = { homekid = "payback_homekid" } }`
  - `payback_homekid` stays, both for queued legacy entries and for every bind that gives `homekid`
- Modify: `Modules/CareerSim.lua`. `sim.cast` and `sim.castRng = Lcg(seed + 200003)`. `pickNext` passes `bindable`, `today` and `lvOf`. A role pick is bound with `WebRules.Bind` (making through `CastRules.Make`) and resolved before `arrive`. A bound person's `ls` is the day; `Run` returns `cast` and `generatedVisits`, the visits and opened pops whose resolved visitor is a `g` id, by day.
- Modify: `spec/walkin_rules_spec.lua`, `spec/web_rules_spec.lua`, `spec/career_sim_spec.lua`, `spec/walkins_data_spec.lua`:
  - every `@role` visitor names a declared role
  - `$` only in role items
  - `{name:$}` only in role items
  - `rel.who` may be `"$"` or a role in role items only
- Modify: `spec/pacing_spec.lua`. "homer runs to an album" counts `homekid_album` or `hometown_album`, and arc reach accepts either family.

**Interfaces:**
- Consumes: Task 1's Merge, and Task 2's CastRules.
- Produces: the queue entry shape, `Plant`'s `opts`, `opts.bindable` / `today` / `lvOf`, `Bind` / `Resolve` / `Candidates`, and the sim's `cast` / `generatedVisits`.
  - Task 4 calls the same functions on the server.
  - Task 5 plants with `on` and `day`.

- [ ] **Step 1: Write the failing tests.**
  - **walkin_rules_spec:**
    - `Plant` of `payback_hometown` for `homekid`, then for `g3`, gives 2 entries; a second for `g3` gives nil
    - a `day` entry with `today = 9` and `day = { 2, 2 }` has `day == 11`, is due at today 11 and not at 10
    - an `on` entry is never due
    - with two entries due, `pri = 5` comes before `pri = nil` even with a later `at`
    - a role card with `bindable` returning false is never picked; returning true, it is
  - **web_rules_spec (Bind):**
    - on a fresh state `Bind(two_sessions' role item)` returns `"homekid"`, and `Resolve` with `homekid` turns the plant into `payback_homekid`
    - a `notWritten` item's candidates never include `homekid`
    - once `homekid` is in `rel`: with candidates `{ "homekid", "g1" }` and a counting rng, the weights are as in Shared shapes
    - `mint = 100` always gives `made = true`
    - no candidates with `item.mint == false` returns nil
  - **web_rules_spec (Resolve):**
    - a role card with `needs.flags = { "$.helped" }` resolved to `g2` gives `needs.flags = { "g2.helped" }` and `visitor = "g2"`
    - the input is unchanged
  - **career_sim_spec:**
    - a homer run binds `homekid` first: its `rel.homekid` exists, and its queue or firstSeen shows `payback_homekid` (via `byWho`), never `payback_hometown` for `homekid`
    - a second hometown bind on that run is a generated kid, whose chain is `payback_hometown`
    - `rel["@hometown"]` and `rel["$"]` never exist
    - **exact equality:** on every seed whose run makes at most one hometown bind, random's results equal plan 1's final numbers. The ledger records how many seeds that is. On every seed, every pacing guardrail holds.
- [ ] **Step 2:** `sh tools/spec.sh walkin_rules web_rules career_sim walkins_data pacing` → FAIL.
- [ ] **Step 3: Implement.** Pacing must pass, with the numbers in the commit.
- [ ] **Step 4:** `sh tools/spec.sh` → PASS. Controller: sync `Modules/WalkInRules`, `Modules/WebRules`, `Data/Web`, `Data/WalkIns` and `Modules/CareerSim`, then the refresh; `--edit t46 t69` → PASS (t69's `two_sessions` asserts move to `payback_hometown` and `@hometown`: update them in this task).
- [ ] **Step 5: Commit** `E2-T3: role cards bind people; chains keep their person; homekid is the first hometown`.

### Task 4: Roles on the server and on screen (§4.3, §4.4)

**Files:**
- Modify: `Systems/WalkIns.lua`:
  - `state()` (:268-292):
    - repairs `cast` (its people keep only well-formed P rows, `next` a whole number) and the queue entries' new fields
    - an entry is kept with any of `at`, `day` or `on`
    - `who` must be a written visitor or a cast id
  - `peopleFor(st)` returns `Content.PeopleSet` plus every cast id
  - `repairRel` (:248) keeps entries for cast ids, with flags from the role's `RelFlags` (Task 1's Merge indexes `RelFlags["@role"]`)
  - `pickOpts` (:616):
    - `bindable` = the item has at least one candidate, or may mint
    - `today` = `careerDay(p)`
    - `lvOf` = the cast's `lv`
  - `nextPick` (:627) binds a role pick with `WebRules.Bind` on `castRng(uid)`, makes the person when asked (`cast.next += 1`), stores `next = { kind, id, who }` and resolves the item
  - `newRecord` (:647):
    - `def` for a `g` id is built from `CastRules.Face`: name, colour, sig, style, and `look` (the look params)
    - `NAMES` lookups go through `WebRules.NamesFor`
  - `apply` (:543):
    - writes `rel` for `who` when `rel.who == "$"`
    - plants with `opts = { who = rec.who, today }`
    - sets the bound person's `ls`
- Modify: `Systems/Phone.lua`, `pickOpts` (:347), `popOf` (:165) and `apply` (:185): the same bind, resolve, names and `who` plant.
- Modify: `Modules/Visitor.lua` and `Modules/VisitorFigure.lua`: a def with `look` builds `VisitorLooks.Generated(def.look)`.
- Modify: `Modules/WalkInUI.lua` and `Modules/PhoneUI.lua`: the card and DM portraits use the payload's `look` when present.
- Modify: `Systems/Contacts.lua` (the people plan's): rows for met `g` ids with the face's name and colour; `ContactRules.Rows`' `input.people` includes them.
- Create: `src/ReplicatedStorage/OK/Systems/Web.lua`, with `Init`, the hook, `Cast` / `SetCast` / `Make` / `Reset`, and `castRng(uid)`. Events come in Task 5.
- Create: `build/t150a_play_server.lua`, `build/t150b_play_client.lua`.

**Interfaces:**
- Consumes: Task 3's pure functions; the people plan's `peopleFor`, `MarkMet`, `Contacts.State`.
- Produces: `prof.walkins.cast` on the server, the walk-in record's `who`, the arrive payload's `look`, and `Systems/Web` (Task 5 adds `Event`).

- [ ] **Step 1: Write the failing tests.**
  - **t150a:**
    - fresh; `two_sessions` choice 1 (the phone hook): `Rel(uid).homekid.score == 1`, and `Queue(uid)` holds `payback_hometown` with `who = "homekid"`
    - **legacy:** `Plant("payback_homekid")` with no `who` arrives as `homekid`
    - `Web.Make(uid, "local_artist", 7)` gives `g1`. `Spawn` of a `local_artist` role card (a Task 3 test card in Data/Web, `test = true`, never drawn outside Studio) arrives with `Bound(uid) == "g1"` and a name equal to `Face`'s.
      - Its outcome `rel.who = "$"` writes `Rel(uid).g1`.
      - `Met(uid).g1` is the career day.
    - `prof.walkins` through HttpService JSON and back plus `state()` keeps `cast`, the queue's `who` and `day`, and `rel.g1`
    - `SetCast` with junk keeps only well-formed rows
    - marker `T150A PLAY OK`
  - **t150b:** at the three viewports, the walk-in card for `g1` shows its name in its colour with a portrait that has parts. A DM from `g1` does the same. CONTACTS lists `g1`.
- [ ] **Step 2:** Controller red `--play t150` → FAIL.
- [ ] **Step 3: Implement.** The `test = true` card is skipped by every `Pick` unless `opts.tests` (set only by the Studio hooks) is true.
- [ ] **Step 4:** Specs PASS. Controller:
  1. Sync `Systems/WalkIns`, `Systems/Phone`, `Systems/Web`, `Systems/Contacts`, `Modules/Visitor`, `Modules/VisitorFigure`, `Modules/WalkInUI`, `Modules/PhoneUI` and `Data/Web`; run `build/17_career_remotes.lua` if Web adds a remote (it shouldn't).
  2. The refresh.
  3. `--play t150 t43 t51 t66 t79 t132 t134` → PASS.
- [ ] **Step 5: Commit** `E2-T4: generated people walk in, text you and show in CONTACTS`.

### Task 5: The story web: triggers and events (§4.1)

**Files:**
- Modify: `Modules/WebRules.lua`: `Triggered`, `Fire`.
- Modify: `Systems/Web.lua`: `M.Event(p, name, fields)`. It:
  1. runs `Fire(st, name)`
  2. runs `Triggered(Content.Triggers, name, fields, Career.Get(p), castRng)`
  3. plants each result with `opts = { who = bound, today }`, where `who = "@role"` binds now through `WebRules.Bind`
  4. sends nothing to the client

  It never errors into its caller: it runs in a pcall that reports.
- Modify the event sources (each a one-line `pcall` call into `Systems/Web.Event`):
  - `Systems/Life.lua` `Event` (:146), which forwards every Life event kind as its own name
  - `Systems/Life.lua` `Tick` (:167): `"day"`
  - `Systems/Contracts.lua` `Deliver` (:236): `"delivery"`, and `"delivery3"` at 3 stars
  - `Systems/Reactions.lua` (:66): `"fire"` to the author
  - `Systems/BeatBattles.lua`: `"cypher_win"`
  - `Systems/Career.lua` `Unlock` (:309): `"buy:" .. gateId`
  - `Systems/Gear.lua` (:126): `"buy:" .. itemId`
  - `Systems/WalkIns.lua` `WriteRel` (:300): `"rel:<who>:up"` / `":down"` when the score crosses +2 or −2
  - `Systems/Life.lua`'s tier crossing: `"tier:" .. id`
- Modify: `Modules/CareerSim.lua`: the same events at the same moments it models (delivery, delivery3, fire, cypher_win, day, the gates it buys, tiers, rel crossings), through the same pure calls on `castRng`.
- Modify: `Data/Web.lua`: one test trigger and one test follow-up (`test = true`).
- Create: `build/t151a_play_server.lua`.

**Interfaces:**
- Consumes: Task 3's queue fields, and Task 4's `Systems/Web`.
- Produces: `Web.Event` and the event names (Shared shapes); `Triggered` / `Fire`. Tasks 6, 7, 9 and 10 and plan 3 add triggers as data only.

- [ ] **Step 1: Write the failing tests.**
  - **web_rules_spec:**
    - a trigger `{ on = "delivery3", chance = 100, plant = { id = "x", day = { 2, 2 } } }` on `"delivery3"` gives one plant
    - on `"delivery"`, none
    - `on = "buy:*"` matches `"buy:home_studio"`
    - `chance = 0` never plants
    - `who = "$event"` takes `fields.who`
    - `Fire` turns a queued `on = "fire"` entry into `at = count + 1` and returns 1
  - **t151a:**
    - with the test trigger (`on = "delivery3"`, `who = "@local_artist"`, `day = { 2, 2 }`), a 3-star delivery through the Contracts hook queues the test follow-up with a bound `who` and `day = today + 2`
    - Life `AdvanceDay` twice, then `Spawn()`, brings it with that person
    - a queued `on = "fire"` entry arrives after a FIRE through the Reactions hook
    - a failing trigger (a bad role) reports `[OK][ERR]` and the delivery still pays
    - marker `T151A PLAY OK`
- [ ] **Step 2:** Spec FAIL. Controller red `--play t151a` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4:** Specs PASS (pacing unchanged: no real triggers yet). Controller:
  1. Sync `Modules/WebRules`, `Modules/CareerSim`, `Systems/Web`, `Systems/Life`, `Systems/Contracts`, `Systems/Reactions`, `Systems/BeatBattles`, `Systems/Career`, `Systems/Gear`, `Systems/WalkIns` and `Data/Web`, then the refresh.
  2. `--play t151a t21 t28 t41 t52 t66 t78` → PASS.
- [ ] **Step 5: Commit** `E2-T5: events plant situations; the web's queue waits on days and events`.

### Task 6: People live their own lives (§4.5)

**Files:**
- Modify: `Modules/CastRules.lua`, `Grow`. Once a played day, a person's `lv` rises with `cfg.rise + cfg.helped * min(h, 3)` percent, or falls with `cfg.fall` percent (never below 1 or above 5).
  - `pk` keeps the highest `lv`.
  - It returns `"rise"` or `"fall"` on a change.
- Modify: `Systems/Web.lua`. On `"day"`, `Grow` runs for every active person on `castRng`. Each change raises `"cast:<id>:rise"` / `":fall"`. Delivering a promise (Task 7) adds 1 to `h`.
- Modify: `Data/Web.lua`: two triggers and their follow-ups (§B4):
  - **"blew up and remembers you":** on `"cast:*:rise"`, needs `$.lv >= 4` and `$.h >= 1`, `who = "$event"`, `day = { 1, 3 }`
  - **"fell off and asks for help":** on `"cast:*:fall"`, needs `$.pk >= 3`

  Their lines say so.
- Modify: `Modules/CareerSim.lua`: the same day step.
- Modify: `spec/cast_rules_spec.lua`, `spec/career_sim_spec.lua`, `spec/pacing_spec.lua` (the 200 seeds print how many runs see each callback and its median day; at least one random run reaches "blew up and remembers you").
- Create: `build/t152a_play_server.lua`.

**Interfaces:**
- Consumes: Tasks 2–5.
- Produces: `Grow`, the `cast:*` events, and `h`. Plan 3's switch-ups and values read `lv`, `pk` and `h`.

- [ ] **Step 1: Write the failing tests.**
  - **cast_rules_spec:**
    - `Grow` with a forced rng `{ 1 }` rises; with `{ 100, 1 }`, falls
    - `lv` stays in 1..5, and `pk` never drops
  - **t152a:**
    - `Make` g1 with `lv` 3 and `h` 1
    - `SetRng` forces a rise, then `DayStep`: g1 at 4, and the "blew up" follow-up queued for g1
    - `AdvanceDay`; `Spawn` brings it, its text names g1, and the line matches §B4's
    - marker `T152A PLAY OK`
- [ ] **Step 2:** Spec FAIL; controller red → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4:** Specs PASS; controller syncs `Modules/CastRules`, `Systems/Web`, `Data/Web` and `Modules/CareerSim`; `--play t152a t151a` → PASS.
- [ ] **Step 5: Commit** `E2-T6: generated people rise and fall, and the ones you helped come back`.

### Task 7: Endless requests (§4.2)

**Files:**
- Create §B6's first five request templates in `research/endless/copy_2026-11-12.md`: title words, the person's line, and asks from DailyRequests' ask kinds.
- Modify: `Data/Web.lua`: `Requests`, the five templates `{ id, asks, bonus, titles, line, pay, xp, needs? }`.
  - Add one request card per template's role (§B4): a role card whose choice 1, "Make it", has `good.request = <tpl id>`.
- Modify: `Modules/WebRules.lua`: `BriefFor(promise, requests, names)`.
- Modify: `Systems/Contracts.lua`:
  - `state()` (:58) defaults `promises = {}` and `qNext = 0`, keeping only well-formed rows whose `tpl` is known
  - `M.Promise(player, who, tpl, lv)` adds one (refused at `MaxPromises`)
  - `Offers` (:116) lists promises first, each with `brief = BriefFor(...)` and `promise = true`
  - `Pick` (:160) accepts a promise id
  - `Deliver` (:236): a promise brief pays once through `Delivery` at its reward, × 1.5 for 3 stars as today. It then removes the promise, raises `"request:<who>"` and adds 1 to the person's `h`.
  - `M.Drop(player, id)`: a promise let go writes `rel` −1 for its person and raises `"rel"` as WriteRel does
  - `M.State` sends `promises`
  - Picking another request leaves an accepted promise in `promises` (the §4.2 seam).
- Modify: `Systems/WalkIns.lua` / `Systems/Phone.lua` `apply`: an outcome's `request` calls `Contracts.Promise(p, who, tpl, lv)`. `cardEligible` gets `opts.promisesFull`, which makes a card with any `request` outcome ineligible.
- Modify: `StarterPlayerScripts/OK/DAWClient.client.lua` (:25): a brief the server sent with an offer joins `BriefById` for that session.
- Modify: `Modules/RequestUI.lua`: a promise row shows "FOR {name}" and a LET GO button (≥ 44 px), which sends `Command = "drop"`. The words are §B8's.
- Modify: `build/17_career_remotes.lua`: the drop remote, or a `kind` on the existing pick remote, whichever 17's pattern uses.
- Modify: `Modules/CareerSim.lua`:
  - `sim.promises`
  - a `request` outcome adds a promise
  - after first-time briefs, the day's `requestsPerDay` deliveries come from promises, oldest first, paid at their brief's reward through plan 1's `award(sim, "cred", "Delivery", n)`
- Modify: `spec/pacing_spec.lua`:
  - print the money a day each policy gains from promises
  - plan 1's `LONG` bounds hold with requests in
  - the random player's steady share and `earlyShare` stay inside their guardrails
- Create: `build/t153a_play_server.lua`, `build/t153b_play_client.lua`.

**Interfaces:**
- Consumes: Tasks 3–6, and plan 1's curve.
- Produces: promises, `Contracts.Promise` / `Drop`, `BriefFor`, `"request:<who>"`. Plan 3's "beat on the wrong song" and keepsakes read a delivered promise's record.

- [ ] **Step 1: Write the failing tests.**
  - **web_rules_spec:** `BriefFor` at `lv` 3 gives `reward.cred == 450` and a title from the template, and the same promise gives the same brief.
  - **career_sim_spec:**
    - after the 21 briefs are done, a day with 2 promises delivers 2 and pays their rewards
    - `MaxPromises` holds
  - **t153a:**
    - `Promise(uid, "g1", "<tpl>", 2)` puts it in `Offers` first with its brief
    - `Pick`, then `Deliver` a beat that meets it: pays `pay[2]` once, `h` 1, removed, `"request:g1"` raised (a test trigger on it plants)
    - a second promise, then picking a regular brief, leaves it in `promises`
    - `Drop` lowers `rel.g1` by 1
    - a 4th promise is refused
    - marker `T153A PLAY OK`
  - **t153b:** at the three viewports, the promise row shows FOR + the name, LET GO is ≥ 44 px, inside the viewport and not overlapping, and the DAW's asks tick for the promise's brief.
- [ ] **Step 2:** Spec FAIL; controller red → FAIL.
- [ ] **Step 3: Implement.** If the bounds fail with requests in, tune only `pay` and `xp` within −30%..+0% of Shared shapes' table. Past that, stop and bring the numbers.
- [ ] **Step 4:** Specs PASS. Controller:
  1. Sync `Data/Web`, `Modules/WebRules`, `Systems/Contracts`, `Systems/WalkIns`, `Systems/Phone`, `Modules/RequestUI` and `Modules/CareerSim`; the DAWClient script by its pattern; `build/17_career_remotes.lua` if changed.
  2. The refresh.
  3. `--play t153 t21 t22 t66 t120 t121` → PASS.
- [ ] **Step 5: Commit** `E2-T7: people send requests again and again; promises survive picking another`.

### Task 8: No daily visit limits (§4.1 pacing)

**Files:**
- Modify: `Config.lua`:
  - `Config.WalkIns.DailyMax = 120` and `Config.Phone.DailyMax = 150`, each commented as "a backstop for a broken timer or an idle loop, not a wall: the gap timer spaces visits"
  - `Config.Career.Sources.Phone`'s `dailyMax` becomes the literal 7, its full-pay count, no longer `DailyMax + 1`
  - the header comments at :159-233 updated
- Modify: `Modules/WalkInUI.lua` (:634): the "%d OF %d TODAY" line goes. Nothing replaces it (§B8 records the removal for the approval list).
- Modify: `build/t46_check.lua`:
  - `walkinsPerDay` and `phonePerDay` become the random player's literals 8 and 6 ("the random player's day", no longer Config)
  - `RUSH_SPEC.DailyMax = 120`
  - the Phone `+ 1` assertion becomes `dailyMax == 7`
- Modify: `spec/rush_spec.lua` (literals), `build/t41_check.lua:45` (`DailyMax == 120`), and `build/t52_play_server.lua` (`N = 7`).
  - t43b, t51 and t60a read `W.DailyMax` / `P.DailyMax` and keep working. Their comments say "the backstop".
  - The cold cap (`Cold.dailyMax = 2`) is unchanged.
- Create: `build/t154a_play_server.lua`.

**Interfaces:**
- Consumes: Task 7 (requests) and the content to come. Plan 1's curve pays visits past the old caps.
- Produces: no daily visit limits.

- [ ] **Step 1: Write the failing test** t154a:
  - `SetToday(uid, 8)`, then `Poke`: a visit is scheduled (no cap at 8)
  - the phone at 6 opened sends another
  - cold: `DailyMaxFor == 2`
  - the arrive payload's text has no "OF … TODAY"
  - marker `T154A PLAY OK`
- [ ] **Step 2:** Controller red `--play t154a` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4:** `sh tools/spec.sh` → PASS. Controller: sync `OK/Config` and `Modules/WalkInUI`, then the refresh; `--edit t41_ t46` and `--play t154a t43 t51 t52 t60 t78` → PASS.
- [ ] **Step 5: Commit** `E2-T8: no daily visit limits; the gap timer spaces visits`.

### Task 9: Content batch 1: the six roles and the six chains (§4.4, §4.7)

**Files:**
- Modify: `research/endless/copy_2026-11-12.md`:
  - **§B4:** about 12 situations for each of the six roles (72 in all, including Tasks 3, 6 and 7's), for every career stage, each with its choices, outcomes, any plant or trigger, and the line each person says
  - **§B7:** six web chains in the style of the cousin example (spec §4.1), each 3–5 linked situations across days, with at least one everyday-life link, one bound person kept through the chain and one later callback
  - **§B9:** the approval list so far
- Modify: `Data/Web.lua`. Add them in four sub-batches, each followed by the full pacing run:
  1. hometown and local_artist
  2. promoter and producer_peer
  3. scene_blogger and label_scout
  4. the six chains
- Modify: `spec/walkins_data_spec.lua`:
  - every chain's links resolve (every `plant.id` and trigger `plant.id` exists)
  - every chain item names `$` or a fixed person
  - no chain can plant itself in a loop without a played-day gap
- Modify: `spec/pacing_spec.lua`:
  - **The generated share:** on the 200 seeds, the random player's visits and opened pops in days 8–60 whose person is generated make up **0.35–0.65** of all (spec §4.4, "about half").
  - **The chains:** each of the six reaches its last link on some random run, and its median length in played days is printed.
  - **Repeats:** a situation comes back with a different person no sooner than `Config.Web.RepeatDays` played days (WebRules' seen-by-day rule: Pick prefers the least seen; a role card seen within `RepeatDays` for the same `who` isn't bound to that person again).
- Create: `build/t156a_play_server.lua`. It plays one chain end to end: its first card, the days, its middle links through `AdvanceDay` and `Spawn`, the same person throughout, and the callback.

**Interfaces:**
- Consumes: Tasks 3–8.
- Produces: the launch role content and chains. Plan 3's arcs use the same shapes.

- [ ] **Step 1: Write §B4 and §B7,** and scan them.
- [ ] **Step 2: Write the failing tests** (the data rules, the share, the chains, t156a).
- [ ] **Step 3: Implement** the four sub-batches. After each, `sh tools/spec.sh` (pacing included) must hold every guardrail.
  - If the generated share misses 0.35–0.65 after all four, tune only the roles' `mint` (0..100) and the role cards' `weight` (1..3).
  - If that can't reach it, stop and bring the numbers.
- [ ] **Step 4:** Specs PASS. Controller: sync `Data/Web`, then the refresh; `--edit t40_ t50_ t46` and `--play t156a t150a t43 t79` → PASS.
- [ ] **Step 5: Commit** `E2-T9: six roles with their situations, and six chains`.

### Task 10: Content batch 2: everyday life and the request templates (§4.1, §4.2, §4.7)

**Files:**
- Modify: `research/endless/copy_2026-11-12.md`:
  - **§B5:** about 40 everyday-life situations (spec §4.1's list: rent, roommates, a breakup, family events, a fan DM, a blog rumor, a show at a local spot, a sponsor lunch, a friend who needs help, a party you skip). Each moves at least one of Money, Aura, Followers, a relationship, your room, your gear or what comes next. No crime storylines.
  - **§B6:** the remaining 15 request templates (20 in all).
- Modify: `Data/Web.lua`. Add them in two sub-batches, each followed by the full pacing run:
  1. life 1–20 and requests 6–12
  2. life 21–40 and requests 13–20

  Life situations use the existing written cast (mom, cousin, landlord, neighbor, host, blockkid, rapper) and the roles. The 5b+ "+5 Aura on every starter" rule stays as it is.
- Modify: `spec/walkins_data_spec.lua`: every life situation moves something (a non-zero delta, a `rel`, a plant or a trigger), and `crime` words from §B5's banned list never appear.
- Modify: `spec/pacing_spec.lua`:
  - every guardrail, plan 1's bounds and the generated share hold
  - print the share of visits that are everyday life

**Interfaces:**
- Consumes: Task 9.
- Produces: the launch everyday-life content and all 20 request templates.

- [ ] **Step 1: Write §B5 and §B6,** and scan them.
- [ ] **Step 2: Write the failing data rules.**
- [ ] **Step 3: Implement** the two sub-batches; pacing after each. The stop rule is the same as Task 9's.
- [ ] **Step 4:** Specs PASS. Controller: sync `Data/Web`, then the refresh; `--edit t40_ t50_ t46` and `--play t153a t156a t43` → PASS.
- [ ] **Step 5: Commit** `E2-T10: everyday life and twenty request templates`.

### Task 11: The archive (§4.5)

**Files:**
- Modify: `Modules/CastRules.lua`:
  - **`ArchiveOrder(people, busy, today, cfg) -> { ids }`:** while more than `cfg.Active` people are active, it gives the ones not seen in `cfg.ArchiveDays` played days, oldest `ls` first. It never gives anyone in `busy`.
  - **`Pack(P, relEntry, metDay) -> A`**, with `A = { s, r, lv, pk, ls, h, sc = score, f = { key flags }, m = met day }`, and **`Unpack(A) -> P, relEntry, metDay`.**
- Modify: `Systems/Web.lua`.
  - On `"day"`, the archive rule runs. `busy` is everyone with:
    - an open promise
    - a queued entry naming them
    - the visit in flight
    - a waiting pop
  - Archived people move to `prof.walkins.arc[id] = A`, out of `cast.people`, `rel` and `met`.
  - A Web trigger with `who = "@old"` binds an archived person and unpacks them back to active:
    - "an old friend calls": §B4's old-contact situations, three of them
    - `Bind` gains the `old` role: any archived person, weighted by `sc`
- Modify: `Systems/WalkIns.lua` `state()`: repair `arc`.
- Modify: `Modules/ContactRules.lua` and `Systems/Contacts.lua`:
  - an **OLD CONTACTS** section (§B8's header) after the rows, listing archived people with their name, last bond and memory line
  - a count line for paged people (Task 12)
- Modify: `Modules/PhoneUI.lua`: the section in the CONTACTS list.
- Modify: `Modules/CareerSim.lua`: the archive rule on its day step. `Run` returns `arcCount`.
- Create: `build/t155a_play_server.lua`, `build/t155b_play_client.lua`.

**Interfaces:**
- Consumes: Tasks 2–10.
- Produces: `prof.walkins.arc`, `Pack` / `Unpack`, `ArchiveOrder`, the `@old` role and OLD CONTACTS. Task 12 pages it. Plan 3 keeps claimed facts in `A`.

- [ ] **Step 1: Write the failing tests.**
  - **cast_rules_spec:**
    - 152 people, two over `Active`: the two oldest unseen are given
    - one of them with a promise (in `busy`) is skipped for the next oldest
    - `Unpack(Pack(P, rel, met))` equals the inputs
  - **t155a:**
    - `Make` g1..g152 with `ls` 1; `SetDay(40)`; `Archive(uid)`
    - `#Cast.people == 150` and `Arc(uid)` holds two
    - their `rel` and `met` are gone from active, and their facts are in `A`
    - a promise for g1 keeps g1 active
    - the `@old` test trigger brings an archived person back with their score and flags restored, and the `Spawn` shows them
    - marker `T155A PLAY OK`
  - **t155b:** OLD CONTACTS shows at the three viewports, fits, and scrolls.
- [ ] **Step 2:** Spec FAIL; controller red → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4:** Specs PASS. Controller: sync `Modules/CastRules`, `Systems/Web`, `Systems/WalkIns`, `Modules/ContactRules`, `Systems/Contacts`, `Modules/PhoneUI` and `Modules/CareerSim`, then the refresh; `--play t155 t134 t150a` → PASS.
- [ ] **Step 5: Commit** `E2-T11: people you haven't seen in a month move to the archive and can come back`.

### Task 12: Archive pages and a bounded save (§4.5)

**Files:**
- Create: `research/endless/save_size_2026-11-12.md`. It measures the bytes per archived person (HttpService JSON of 100 `A` rows from a 200-day sim profile, in Studio) and the whole profile's JSON size after 200 sim days for random, `solo5h` and `social5h`.
  - From those it sets `Config.Cast.Budget`, the archive's in-profile byte budget (Claude's call: 25% of the 200-day `social5h` archive's size, at least 32 KB).
- Modify: `src/ServerScriptService/OK/Services/DataService.lua`:
  - `M.LoadPage(p, n) -> table?` and `M.SavePage(p, n, data) -> ok, why` on the same store, key `key(p) .. "_arc" .. n`
  - `SavePage` writes only while `M.Saving(prof)` (the lock is this server's)
  - each page is `{ v = 1, people = { [id] = A } }`, at most `Config.Cast.PageBytes` encoded
- Modify: `Systems/Web.lua`:
  - **At save time,** when `arc`'s encoded size passes `Budget`, the oldest archived people move into the newest page (a new page when it is full), and `prof.walkins.arcIdx[id] = n` records where.
  - **Returning a paged person** loads their page first (`LoadPage`, async), unpacks them, rewrites the page without them, then plants their situation. A failed load leaves them paged and reports it; the situation goes to someone else.
- Modify: `Modules/CareerSim.lua`: `Run` returns `saveBytes`, from a pure size estimate `WebRules.Bytes(value)` (JSON length rules: strings with quotes and escapes, numbers by `%.14g`, tables as objects or arrays).
- Modify: `spec/pacing_spec.lua`, a 200-day block for random and `social5h` on 20 seeds:
  - `saveBytes` stays under 1 MB
  - the in-profile archive stays under `Budget` + one person
  - the printed numbers go into the research doc
- Create: `build/t157_check.lua` (Edit: `WebRules.Bytes` within ±2% of `HttpService:JSONEncode` on 20 sample values, and the fake store's pages).
- Create: `build/t157a_play_server.lua`.

**Interfaces:**
- Consumes: Task 11.
- Produces: `LoadPage` / `SavePage`, `arcIdx`, `WebRules.Bytes` and `Config.Cast.Budget`. Nobody is ever deleted.

- [ ] **Step 1: Measure** (the controller runs the Studio half), and write the doc and `Budget`.
- [ ] **Step 2: Write the failing tests.**
  - **t157_check** (Edit, with t69's fake store seam):
    - `SavePage` / `LoadPage` round-trip a page
    - `SavePage` refuses while the profile's lock is lost
    - `WebRules.Bytes` is within ±2%
    - marker `T157 OK`
  - **t157a:**
    - with `Budget` set low through the hook, archiving 20 people pages the oldest
    - `arcIdx` names their page
    - the `@old` trigger forced to a paged person loads the page and brings them back
    - their page no longer holds them
    - marker `T157A PLAY OK`
- [ ] **Step 3:** Controller red → FAIL. **Implement.**
- [ ] **Step 4:** Specs PASS. Controller: sync `Services/DataService`, `Systems/Web`, `OK/Config` and `Modules/CareerSim`, then the refresh; `--edit t157_ t13 t41_` and `--play t157a t155a` → PASS.
- [ ] **Step 5: Commit** `E2-T12: archive pages; the save stays bounded after 200 played days`.

### Task 13: Report and integration

**Interfaces:** Produces none. It reports on Tasks 1–12.

**Files:**
- Create: `research/endless/web_report_2026-11-12.md`:
  - every pacing number before and after (20 and 200 seeds)
  - the generated share, the chains' reach and lengths, the callbacks, the promise income, plan 1's bounds with requests
  - the save sizes
  - the user's list:
    - §B9's approval list
    - the backstop numbers
    - the role list
    - the five levels' words, and their tie to the underground stage that Codex relayed (to confirm)
- [ ] **Step 1:** `sh tools/spec.sh` → every spec PASSES. Paste the numbers.
- [ ] **Step 2:** The full Studio suite with no failures (one rerun per flake), `walkins_pause_off`, guard green.
- [ ] **Step 3:** A whole-branch final review on the most capable model against this plan and spec §4.1–§4.5 and §4.7. One fix dispatch, then a scoped re-review.
- [ ] **Step 4:**
  - README: a "The story web" section (roles, generated people, the queue, events, requests, no daily visit limits, the archive, tests t150–t157)
  - the tracker (Now, Needs you, Done log)
  - IDEAS.md
  - snapshot `v45_story_web`; export; push to GitHub
- [ ] **Step 5: Commit** `E2-T13: story web report and integration`.

---

## Claude's calls (plan)

1. **New content goes in `Data/Web`, merged by a pure function, not appended to `Data/WalkIns`.** Why: Data/WalkIns is 2,628 lines, and pure data modules can't require one another, so the merge lives in the consumers.
   - Cost if wrong: one more call in each consumer.
2. **Follow-ups are generic per role and carry their person on the queue entry (`who`).** Pool kids no longer get their own copies. Plant is unique on id + who. Why: one written chain then serves every person who plays the part, and "a chain keeps its person" holds by construction.
3. **The first `@hometown` is always `homekid`.** Why: the spec keeps him as the written first one, and homer's pacing reach stays meaningful.
4. **Binds, makes and trigger chances draw from their own stream.** Why: today's pick draws don't move until role content enters the deck, so each task's pacing change is attributable.
5. **The visit limits become backstops** (120 walk-ins and 150 pops a UTC day) instead of being deleted. Why: the gap timer already spaces visits (about 53 in five hours); a backstop keeps a broken timer or an idle loop bounded; and every check that reads the key keeps working.
   - Cost if wrong: an 11-hour player meets it.
6. **A promise is how a waiting request is offered** (spec §4.2 leaves it to the builder): at most 3 open, kept until delivered or let go, and request cards hold back while 3 are open. Why: it fixes the "choosing a request replaces your active one" seam with the smallest UI change (a row and a button in REQUESTS).
7. **Five generated levels: LOCAL, BUZZING, UNDERGROUND, SIGNED, BLOWN UP.** Why: rise and fall need a ladder. "Underground" also gives Codex's relayed underground-before-mainstream direction a place to land without deciding it: authored underground parodies, if the user confirms them, are their own written visitors of kind `underground`, outside the people plan's `StarEntry` gate.
8. **Archived people leave `rel` and `met` and keep their facts in `A`.** Why: `rel` is read on every pick, and the archive's point is that the active save stays small. `Unpack` restores them exactly.
9. **The archive's budget is measured, not guessed** (Task 12). Pages load only when someone in them comes back.
