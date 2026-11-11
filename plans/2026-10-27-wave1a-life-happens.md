# Wave 1a "Life Happens" (phone and content) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Ultracode is on for this session: the orchestrator runs each wave as a Workflow (implementer → spec-and-quality review → fix), with one integrator owning every Studio call.

**Goal:** Ship Wave 1a of Prod Life III:
- a phone that pops DMs and news between walk-ins
- cards gated by your career
- new people and threads
- visits that behave like people (gentle first visitor, he left a note, waiting lines)
- choice telemetry
- a content validator
- a pacing sim that models all of it

**Architecture:** The rules stay pure and CLI-tested (`WalkInRules`, `CareerSim`, `Format`, `Data/WalkIns`), and the server and the sim call the same rules. The phone is a new server system (`Systems/Phone`) with its own in-memory pending pops and its own remotes. It never writes the walk-ins card slot (`pending[uid]` in `Systems/WalkIns`). The two coordinate in two places:
- **On the server:** WalkIns exports `Busy`/`DueWithin`, and Phone sets a `PhoneBusy` player attribute that WalkIns reads.
- **On the client:** `PhoneUI` and `WalkInUI` each read the other's gui attributes.

The client tells the server what only it knows (a phone card opened; the beat maker is hiding a walk-in card) through two new client-to-server remotes.

**Tech Stack:** Luau (Roblox), Roblox Studio via the built-in Studio MCP (`tools/mcp_call.py`), `tools/sync.py` (src → place), `tools/test.py` (suite), `luau` CLI at `/opt/homebrew/bin/luau`, Python 3.

**Spec:** `specs/2026-10-26-wave1-life-happens-design.md`. Read §4.1–4.4, 4.7, 4.8, 5, 6, 8, 9 and 10; § refs below point into it. The approved scope is §2 Goals, minus §10. Part 1b (feel) gets its own plan after 1a ships. Background code map: `.superpowers/sdd/2026-10-27-wave1a/codemap.md` (copied from the mapping workflow; file:line refs are from 2026-10-27).

All paths are relative to `/Users/work/Desktop/OK projects/OK ROBLOX/roblox_studio_notes/ok_studio/` unless absolute.

## Global Constraints

- **No git.** Every "commit" step is `sh .superpowers/g add -A src build spec specs plans research README.md && sh .superpowers/g commit -q -m "<task>: <what>"` plus `sh tools/checkpoint.sh <task-id>`. Task 7's commit also adds `WAVE1A_REPORT.md` (git refuses a path that doesn't exist yet, so it stays out of the shared list). Milestone snapshots: `sh tools/snapshot.sh <name>` (Studio).
- **One Studio client.** Only the integrator calls `tools/sync.py`, `tools/test.py`, `tools/mcp_call.py`, `tools/snapshot.sh`, `tools/export_rbxm.py` or any `mcp__Roblox_Studio__*` tool, one call at a time, under the lease:
  - Message `ok-projects-0c` "ok-projects-0d: syncing/testing now", wait for the ack, then send "done with Studio".
  - Run suites under `caffeinate -d`.
  - Implementers write files and run CLI specs only.
- **Scoped syncs only:** `python3 -I tools/sync.py --dry` first, then parent-qualified patterns (`Systems/Phone`, `Modules/WalkInRules`, …). Never `--force`. New remotes: run `build/17_career_remotes.lua` before syncing any system that indexes them.
- **Pure modules** (`Modules/Format`, `Modules/CareerRules`, `Modules/WalkInRules`, `Modules/CareerSim`, `Data/WalkIns`) never touch Roblox globals (`game`, `workspace`, `Color3`, `Vector3`, `Enum`, `Instance`, `task`, `Random`, `os.clock`) and never `require` anything (except `Data/WalkIns`' index helpers already in it). Config values come in as arguments. `spec/pacing_spec.lua` keeps literal copies, which `build/t46_check.lua` diffs against live Config.
- **Rewards:**
  - Positive money only via `DataService.AddCred(p, n, source)` with a registered `Config.Cred.Sources` entry; the phone registers **none** (§4.8: pops never pay money).
  - Positive career stats only via `Career.Add(p, stat, n, source)` with a registered `Config.Career.Sources` entry. New source: `Phone`.
  - An unknown source pays 0 and logs `[OK][ERR]`, which fails `tools/test.py`.
- **Money guardrail (§4.8, §8.1):** the existing pacing targets stay:
  - random median walk-in share 0.35–0.50
  - every policy ≤ 0.50 on every seed
  - The Hall median day 4–6, p10 ≥ 3, p90 ≤ 7
  - Legend nil or ≥ day 15

  Targets are never relaxed. Levers, in order: rate-limit non-paying walk-in cards → move non-paying stories to the phone → small sure payouts ($100–200) on one or two new walk-in cards (report it).
- **Phone Aura budget:** net phone Aura across a day stays ≤ +15 on average (code map probe: +15/day passes, +60/day breaks p10).
  - Measured as the random player's mean over seeds of `phoneAura / days` (Task 2's result key).
  - pacing_spec and t46 print it and assert it once the deck has a phone card (Task 2). It is held like the targets above.
- **Saves:** schema stays **v4**. New fields default lazily in one accessor per side: `WalkIns.state()` on the server (exported as `WalkIns.State(p)`, which Phone uses; Phone has no accessor of its own) and `CareerSim.newSim` in the sim. `DataService.newWalkins` is unchanged. Never fill fields inside an existing `walkins` in `DataService.migrate`. Server-only state lives in module memory, not in `prof`.
- **Names and copy:**
  - Player-facing text says Prod Life III, THE HALL, THE WEST SUITE, "$". Never OK, CRED or a real studio (`t40_check` (d), `t50_check`).
  - Visitor and sender text never types a display name: use `{name:<id>}` / `{sponsor}`.
  - Bubbles (`line`) are lowercase; headlines and tags are caps.
  - Every new name is web-checked and recorded in `research/wave1_names_2026-10-27.md`; the user approves names and lines in the report.
- **Content safety:** `spec/walkins_data_spec.lua`'s REAL (substring) and BLOCK (whole word) lists apply to every new string. No gambling or bet framing, no drugs or alcohol, no real people or brands.
- **Audio:** none in 1a.
- **Phone first:** every tappable control ≥ 44 px at 844×390 and 667×375 (inside the gui's safe-area box); gamepad reachable (`Selectable`, a self-opening card focuses a non-committing header and arms its buttons after 0.6 s).
- **Budget:** 0 new lights. Nothing new under `Workspace.OKStudio`; visitors and the pigeon live in `Workspace.OK_Visitors` during Play only. Tagged interactables stay 12; `Config.SFX` stays 11.
- **Test pause:** the phone honours `ReplicatedStorage.OK:GetAttribute("WalkInsPaused")` (Studio only), exactly as `Systems/WalkIns` does, so `tools/test.py` needs no change. The pause gates the phone's timer only; its 1 s expiry sweep runs while paused, like WalkIns' upkeep.
- **Phone test isolation (Quiet):** `tools/test.py` runs every play file in one Play session, so from Task 6 on the live PhoneUI would open pops that server tests stage.
  - Every server-only test file that Pops or Ticks the phone (Task 4's t51, t51b, t52, t53) calls `_StudioPhoneHook` `Quiet(uid, true)` first. Task 6's chained files (t57*, t58c–t58h) run with Quiet off, because their client steps must see the pops.
  - Its body runs in a pcall. The cleanup runs WalkIns `Reset(uid)`, then Phone `Reset(uid)`, then `Quiet(uid, false)`, then rethrows any error. The WalkIns Reset ends any walk-in, sets the walk-in timer to 1e6 and runs Phone's reset through OnReset, so no walk-in, walk-in timer or pop carries into the next file.
  - While Quiet is on, Phone sends no `"pop"` or `"result"` to that client and drops its `Phone_Open`/`Phone_Choose`. `"expire"` always goes out (PhoneUI ignores tokens it doesn't hold). The hooks still act on server state.
  - Quiet lives in Phone module memory (no attribute), so nothing is saved with the place. Reset never clears it; leaving does. PhoneUI has no test-only branch.
  - Task 6's `t57a` sets `Quiet(uid, false)` explicitly before its Pops.
- **Test numbers:** Studio `t51`–`t59` (letter suffixes for chained files; marker `T51 OK` / `T51B PLAY OK`). Each play file finishes in under 90 s; arrival waits ≤ 15 s, "nothing happens" waits ≤ 5 s.
- **Standing limits:** never save or publish the place; no uploads; no Robux; no free-model scripts; no player-typed text.

## Review Focus

1. **A pop and a walk-in land at the same moment** (the server checks pass for both within one second). The player must never see two cards. One waits (chip or red count), and the other opens when the first closes. Test: Task 6 `t57e_play_server` / `t57f_play_client`, which force both through the hooks within 0.2 s.
2. **Pops wait behind the beat maker for more than 10 minutes, then it closes.** Expired pops never open, never apply effects, never count toward the 6, and the icon count drops. Tests: Task 4 `t52_play_server` (Age past ExpireSeconds) and Task 6 `t57c_play_server` / `t57d_play_client` (one of two waiting DMs expires; the badge drops to 1 and only the survivor opens).
3. **A gate opens mid-session.** A pop takes followers from 4,950 to 5,100, so the booker becomes eligible. He does not win the next draws back to back. A stored walk-in pick (`st.next`) whose gate has since closed, or whose artist has since DMed, is re-picked, not delivered. Tests: Task 1 spec `seed: newly eligible joins evenly`, `stored pick re-validated` and `markSent: …`; Task 4 `t53_play_server`.
4. **Respawn, leaving the server or a hook Reset with a phone card open or pops waiting.** No double count, no orphaned `PhoneBusy` attribute blocking walk-ins, no pop opening after the player has left, and no card left on the client for a token the server dropped (every drop sends `"expire"`; the reset seam is synchronous). Tests: Task 4 `t51b_play_server`; Task 6 `t58c`–`t58h` (an opened DM expiring, a walk-ins Reset and a respawn each close the client's card and clear its count).
5. **The suite's own fresh profiles.** Every Play starts at walk-in count 0, so `gentle_first` becomes the scheduler's default pick after any walk-ins Reset. `t43`, `t43b`, `t43c` and `t47*` must still pass, and their "some card arrives" assertions must hold for the superfan. Test: Task 4 runs the full `t43*`/`t47*` group and fixes assertions that named a specific default pick.
6. **Two pops wait at once** (the beat maker stays open across two Gaps). They never carry the same card or the same follow-up; a phone follow-up applies once; the day never passes 6 (a waiting pop holds its slot); an artist who DMed doesn't walk in within the cooldown. Tests: Task 1 spec `exclude: …` and `markSent: …`; Task 4 `t51` step 6, `t52`, `t53`.

---

## Shared shapes (every task uses these names)

```text
-- Data/WalkIns additions (all optional; absent = today's behaviour)
Card.source  = "walkin" | "phone"                -- default "walkin"
Card.app     = "MESSAGES" | "NEWS" | "STUDIO"     -- phone cards only (required on them)
Card.news    = true                               -- phone NEWS: exactly one choice { sure = true, good = Outcome }, no cost, no rare
Card.needs   = { [GateKey] = n }                  -- eligible only when have[k] >= n
Card.under   = { [GateKey] = n }                  -- eligible only when have[k] <  n
Card.first   = true                               -- the gentle first visitor: wins Pick when visits == 0
Card.cap     = { group = string, per = "day" | "week", max = n }   -- per group, not per card
Card.aired   = true                               -- eligible only when opts.aired (beat aired this session)
Card.camera  = nil                                -- reserved for §10 (not in 1a)
GateKey      = "aura" | "followers" | "placements" | "hits" | "sponsors" | "money" | "visits"
Followup.source = "walkin" | "phone"              -- default "walkin"; a due phone follow-up is only picked by the phone
                                                  -- a phone follow-up pops as NEWS: its PopPayload card.app is always "NEWS" (no Followup.app field)
Visitor.kind adds "mom" | "booker" | "coordinator" | "weird" | "critter" | "local" | "sender"
Visitor.check = "research/wave1_names_2026-10-27.md#<anchor>"     -- required on every visitor added in 1a
W.WaitLines  = { string }                          -- lowercase, may use {name:<id>}
W.NoteLines  = { string }                          -- lowercase parting lines for the note card
W.Deck.visitors = W.VisitorById                    -- (Task 1) so pure rules can read a sender's kind; a deck without it has no artists

-- Pick opts (server nextPick, Phone, CareerSim.pickNext all pass the same shape)
opts = { cooldown, rng, sponsored, aura,          -- existing; cooldown = Config.WalkIns.ArtistCooldown for BOTH sources (Pick errors on nil)
         source = "walkin" | "phone",
         career = CareerRules.Have-shaped table + visits = prof.walkins.count,
         day = whole UTC days since epoch (server: floor(Data._now()/86400); sim: day),
         week = floor(day / 7),
         aired = boolean,
         exclude = { [id] = true } }               -- phone only: the ids of every pending pop, opened or not; nil = today's behaviour
-- Two day numbers, never mixed:
--   cap keys and opts.day/week: Rules.CapKeys(Data._now()) on the server (WalkIns and Phone); the sim passes its day and day // 7
--   prof.walkins.day and prof.walkins.phone.day: yyyymmdd (Data._day(), WalkIns' utcDay()) for Rollover and CanSchedule
-- New pure rules (Task 1)
Rules.MarkSent(state, item, deck)                  -- sender kind "artist" only: state.last[item.visitor] = max(last or count, count)
Rules.Revalidate(state, deck, opts, card) -> boolean   -- card = the stored pick's Card (pick.kind == "card" and pick.item or nil); nil -> true
Rules.CapKeys(nowSeconds) -> day, week             -- day = math.floor(nowSeconds / 86400), week = day // 7

-- Saved, lazily defaulted (schema v4 unchanged)
prof.walkins.phone = { day = yyyymmdd, today = n, count = n }   -- opened pops: this UTC day / lifetime
prof.walkins.caps  = { [group] = { key = n (day or week number), n = n } }
-- Server memory only
Phone pending[uid] = { { token, id, kind = "dm" | "news", item, entry?, sentAt, openedAt?, opened = bool } }   -- entry = a phone follow-up's queue entry
Player attribute PhoneBusy = true while an opened DM awaits a choice (a NEWS holds it only until its result is sent; set and cleared by the server)

-- Phone rules: the server (Task 4) and the sim (Task 2) follow the same ones
-- Send gate:  after Rules.Rollover(st.phone, utcDay()): st.phone.today + unopened < Config.Phone.DailyMax (a waiting pop holds its
--             day slot until it opens or is dropped), and unopened < Config.Phone.MaxWaiting. unopened = pending with opened == false (0 in the sim)
-- At send:    Rules.MarkSent(st, item, deck): the artist cooldown runs across both sources from the moment a pop is sent
-- First open: a follow-up pop calls Rules.TakeQueued(st, entry) first; nil = dropped quietly (no count, no seen/caps, no PhoneBusy, no apply).
--             Then Rules.Rollover(st.phone, utcDay()), st.phone.today += 1, st.phone.count += 1, st.seen[id] += 1, Rules.CountCap(st, item, day, week).
--             Never st.count or st.today (the walk-in counters). An expired or dropped pop counts nothing.
-- Outcomes:   a phone card or phone follow-up moves Aura and Followers only. Outcome money is 0 (money only as a choice cost);
--             placements, hits and sponsors are 0; no sponsor; positive aura <= 60 and positive followers <= 2000
--             (= Config.Career.Sources.Phone maxes = PHONE_CAPS in spec/walkins_data_spec.lua). Losses go through Career.Take.
-- Draws:      the server's Phone owns its own Random plus a per-uid SetRng list (never WalkIns' rngFor/forced);
--             the sim draws a whole pop (pick, policy, Resolve, ResolveNews, Plant) from Lcg(phoneSeed + 100003)

-- CareerSim.Run (Task 2)
input  adds phonePerDay (required number), phoneSeed (required number when phonePerDay > 0)
result adds phonePops (pops opened), phoneAura (net Aura phone pops applied, after the clamps)

-- Remotes (build/17_career_remotes.lua ensures them)
RemoteEvent    Phone            server→client: ("pop", PopPayload) | ("result", PhoneResult) | ("expire", {token})
                                -- "expire" = this token is gone on the server, opened or not: expired, a follow-up already taken,
                                -- respawn, Reset, or an unknown token sent to Phone_Open. The client closes or drops it.
RemoteFunction Phone_Choose     client→server: (token, index) → { ok, result? } | { ok = false, reason = "stale"|"invalid"|"afford" }
RemoteEvent    Phone_Open       client→server: (token)   -- the card is now on screen
RemoteEvent    WalkIn_Deferred  client→server: (token, deferred: boolean)   -- the beat maker hides this walk-in card
PopPayload  = { token, card = { id, app, sender = { name, color }, line, choices = {{text, cost?}}, news = boolean }, today, max }
                                -- app = Card.app, or "NEWS" for a phone follow-up
PhoneResult = { token, key, headline, text, tone, chips = {{label, kind}}, note, source = "phone" }
WalkIn "leave" payload gains: note = { name, waited = Format.Duration(seconds), line }?  -- only on true expiry

-- WalkIns exports (Task 4; WalkIns never requires Phone)
WalkIns.Busy(p) -> boolean;  WalkIns.DueWithin(p, s, ignorePause?) -> boolean
WalkIns.OnReset(fn: (Player) -> ())   -- a module-level list; the hook Reset calls every fn inline, pcall-wrapped, before it returns
WalkIns.State(p) -> prof.walkins      -- the repaired state (phone/caps defaulted); needs WalkIns' ctx, so call it from player and loop paths, never in Init
WalkIns.Filler(sponsorId) -> (text) -> text   -- fills {name:<id>} and {sponsor}
WalkIns.Chips(applied) -> { {label, kind} }   -- the result chips for what was applied
WalkIns.Names                         -- { [visitorId] = display name } for Config.WalkIns.Roster

-- Studio hooks (Studio Play only)
-- _StudioTestHook additions (Task 0, Main.server.lua)
FunnelEvents(uid) -> { { name, value, fields } }   -- uid's entries in Funnel._events, oldest first
ResetFunnelEvents(uid)                              -- drops uid's entries; a case that asserts telemetry calls it first
-- _StudioPhoneHook:Invoke(cmd, uid, a, b)  (Task 4)
Quiet(uid, on)            -- see Global Constraints; Reset never clears it
Reset(uid)                -- drops every pending pop (an "expire" each), clears PhoneBusy, the timer, the tour stamp and the SetRng list; prof.walkins untouched
Pop(uid, id?) -> token?   -- sends now: skips the timers, the eligibility gates and DailyMax, never MaxWaiting. No id = Seed + Pick with exclude;
                          -- id = that phone card, or that phone follow-up if it is queued (else nil); a forced id ignores exclude
Tick(uid, s)              -- the scheduler's checks, then its timer advances by s, even while WalkInsPaused (an unset timer is armed with FirstDelay first)
Pending(uid) -> { { token, id, kind, opened } }
Open(uid, token); Choose(uid, token, i)     -- the Phone_Open / Phone_Choose paths; Quiet never drops these
Age(uid, s) -> n          -- sentAt and openedAt of every pending pop move s back, then uid's expiry sweep runs at once; n = pops dropped
SetRemaining(uid, s); GetRemaining(uid)     -- the phone timer
SetToday(uid, n)          -- st.phone.today = n, st.phone.day = utcDay();   SetDay(uid, d) -- st.phone.day = d (yyyymmdd)
State(uid) -> copy of prof.walkins.phone;   Busy(uid) -> PhoneBusy;   SetRng(uid, list)
Sent(uid) -> { { kind, token } }            -- every send for uid since the last Sent call, Quiet-suppressed ones included (read and clear)
-- _StudioWalkInHook additions (Task 4 unless marked)
Plant(uid, id)            -- Rules.Plant(st, { id = id, at = {0, 0} }, …): that follow-up is due now
SetCaps(uid, { [group] = { key, n } });   Caps(uid) -> copy of st.caps
SetDeferred(uid, token, bool)               -- (Task 5) same path as the WalkIn_Deferred remote
Sent(uid) -> { { kind, payload } }          -- (Task 5) every WalkIn send to uid since the last Sent call, payload included (read and clear);
                                            -- Phone's Sent carries only { kind, token }
Age(uid, s)               -- existing (moves arrivedAt back s); (Task 5) also moves the deferral start and the last waiting-line time back s
Reset(uid)                -- existing; newState also clears st.phone/st.caps, and it runs the OnReset list (Phone's reset) before returning

-- Config additions
Config.Phone = { Enabled = true, DailyMax = 6, FirstDelay = {90, 150}, Gap = {120, 180}, MaxWaiting = 2,
                 ExpireSeconds = 600, OpenExpireSeconds = 300, NewsCloseSeconds = 8, WalkInDueSeconds = 60, Layout = "phone" }
                 -- OpenExpireSeconds: an opened DM left unanswered closes as a dismiss. Server only; not a sim input, t46 doesn't pin it
Config.WalkIns.WaitLineSeconds = 45
Config.Career.Sources.Phone = { aura = { max = 60, dailyMax = 7 }, followers = { max = 2000, dailyMax = 7 } }   -- no other stat; dailyMax = Config.Phone.DailyMax + 1 (E3): a DM opened before UTC midnight and answered after it is counted on the old day but awarded on the new
```

---

## Execution waves

| Wave | Tasks | Runs | Studio |
|---|---|---|---|
| A | 0 | one implementer | integrator: sync Funnel + WalkIns telemetry, run t29*, t43*, t51-new t59 telemetry check |
| B | 1 | one implementer | none (CLI only) |
| C | 2 | one implementer | integrator: t46 |
| D | 3 | web-check researcher → content writer → pacing tuner, in sequence (the writer needs vetted names) | integrator: t46, t50 |
| E | 4 | one implementer | integrator: remotes, sync, t43*/t47*/t51–t53 |
| F | 5 and 6 in parallel (file-disjoint: 5 owns `Systems/WalkIns`, `Modules/Visitor`, `Data/WalkIns` (the pigeon only), the pigeon's anchor in `research/wave1_names_2026-10-27.md`, `build/t42`, `t54`–`t56`; 6 owns `Modules/PhoneUI`, `Modules/WalkInUI`, `Modules/CypherUI`, `ClientMain`, `t57*`, `t58*`; nobody edits `Modules/HUD`) | two implementers | integrator: sync both, then `--play t42 t43 t45 t47 t51 t52 t53 t54 t55 t56 t57 t58` (the new clients against every phone and walk-in server test, in suite order) |
| G | 7 | integrator | full suite, snapshot, export, report |

Every task: implementer → spec reviewer → quality reviewer → fixes. At the end of the wave, one adversarial reviewer per lens (server exploits, economy, phone UI, regressions), each finding verified by a second agent told to disprove it.

---

### Task 0: Choice telemetry and the content validator

**Files:**
- Modify: `src/ReplicatedStorage/OK/Systems/Funnel.lua` (`M.Event`)
- Modify: `src/ReplicatedStorage/OK/Systems/WalkIns.lua` (telemetry calls only, in `M.Choose` and onArrive's news path)
- Modify: `src/ServerScriptService/OK/Main.server.lua` (`_StudioTestHook` commands `FunnelEvents`, `ResetFunnelEvents`)
- Modify: `src/ReplicatedStorage/OK/Modules/Format.lua` (`Duration`)
- Modify: `spec/walkins_data_spec.lua`, `spec/format_spec.lua`
- Create: `build/t59_check.lua` (Edit: Funnel field packing)

**Interfaces:**
- Produces: `Funnel.Event(player, name: string, value: number?, fields: {source: string, card: string, detail: string}?)`.
  - `fields` map to `Enum.AnalyticsCustomFieldKeys.CustomField01/02/03.Name` as strings. The pure helper `Funnel._customFields(fields) -> { [CustomField01.Name] = source, [CustomField02.Name] = card, [CustomField03.Name] = detail }` builds the table `LogCustomEvent` receives.
  - In Studio only (`RunService:IsStudio()`), every call appends `{ uid = player.UserId, name, value, fields }` to `Funnel._events` and prints one line starting `[OK] telemetry`. A live server keeps no list.
  - The append and the print come before the Instance/Parent guard. The guard covers only the `LogCustomEvent` call.
- Produces: event names `CardChoice` (detail = `"<index>:<outcomeKey>"`), `CardWalkAway`, `CardNews` (detail = outcome key), `CardExpire`, `CardNote`, `PhoneOpen`, `PhoneExpire` (detail = `waited` | `opened` | `taken`; Task 4 logs it, and never for a respawn or Reset drop). Source is `"walkin"` or `"phone"`; Task 4 logs `CardChoice`, `CardWalkAway` and `CardNews` with source `"phone"` too.
- Produces: `_StudioTestHook` `FunnelEvents(uid)` and `ResetFunnelEvents(uid)` (Shared shapes).
- Produces: `Format.Duration(seconds: number) -> string`: `"59 seconds"`, `"1 minute"`, `"5 minutes"` (whole minutes from 60 s, rounded down; under 60 → seconds).
- Produces: the validator rules below, which every later content task must satisfy.

- [ ] **Step 1: Write the failing specs.**
  - `format_spec`: `Duration(90) == "1 minute"`, `Duration(300) == "5 minutes"`, `Duration(59) == "59 seconds"`, `Duration(60) == "1 minute"`, `Duration(1) == "1 second"`.
  - `walkins_data_spec` new rules:
    - `choice.odds` and `resolve.odds` in 10..90 (not `rareOdds`)
    - `source`/`app`/`news`/`cap` enums and shapes (`cap.per` in day|week, `cap.max` ≥ 1, `cap.group` a string)
    - `needs`/`under` keys ⊆ GateKey, values whole ≥ 0; an unknown key fails, naming the card
    - **phone outcomes (Shared shapes "Outcomes", §4.8 "Aura and Followers only"):** every outcome a `source = "phone"` card or follow-up can apply holds to these. That is every choice's `good`, `bad` and `rare`, and a phone follow-up's `resolve.good`/`resolve.bad` (checked in the follow-up loop, so `clip_context` and `giveback_letter` are covered).
      - `money` nil or 0: money moves only through `choice.cost`. Don't plan a `TakeCred` path instead; the live phone apply has none.
      - `placements`, `hits`, `sponsors` nil or 0 (the Phone source registers no such stat, so `Career.Add` would log `[OK][ERR]` and pay 0)
      - `sponsor` nil (no signing, no drop)
      - positive `aura` ≤ 60 and positive `followers` ≤ 2000. Losses keep the existing ±500 / ±20000 bands (they go through `Career.Take`).
      - the caps live in one commented table, `PHONE_CAPS = { aura = 60, followers = 2000 }`, citing `Config.Career.Sources.Phone`; Task 2's `t46` asserts live Config equals it
      - name each rule after the source so a failure points at the card, e.g. `card <id> (phone) followers <= Phone.max 2000`
    - a news card has exactly one sure choice with no cost and no `rare`
    - every visitor of kind `mom` has no choice cost and no outcome with money < 0 or tone "loss"
    - every card with `first = true` follows the same rule: no choice cost, no outcome with money < 0 or tone "loss" (§2, §4.3: the gentle first visitor can't cost you money). Vacuous on today's deck.
    - `W.WaitLines` and `W.NoteLines` (iterate `W.WaitLines or {}` and `W.NoteLines or {}`, so today's deck passes): every line is a non-empty string, lowercase (`bare`), has no `{` left after `R.Fill`, names no display name from either roster, and passes REAL, TITLES and BLOCK, as card text does
    - every visitor id not in the 14 originals carries `check`
    - replace the hard counts:
      - "14 visitors" becomes "≥ 14 and every original id present"
      - KINDS adds `mom`, `booker`, `coordinator`, `weird`, `critter`, `local`, `sender`
      - SIGS adds `apron`, `headset`, `lanyard` (`cap` and `none` are already there; Task 5 adds the three to `Visitor.SIGS`)
      - a visitor of kind `sender` has sig `none`
      - Task 0 is the only task that edits KINDS and SIGS
      - "one of each role" applies only to the five originals
      - Names covers every visitor in both rosters
  - Keep every existing rule.
- [ ] **Step 2: Run them:** `sh tools/spec.sh format walkins_data` → FAIL on `Duration` (missing), PASS on the data rules for today's deck.
- [ ] **Step 3: Implement `Format.Duration`, the spec rules and `Funnel.Event` fields.**
  - **WalkIns call sites**, each through the existing lazy `pcall(function() require(RS.OK.Systems.Funnel).Event(...) end)`:
    - `CardChoice` after a resolved choose
    - `CardWalkAway` on index 0
    - `CardNews` when a follow-up's news is applied on arrival
  - **`_StudioTestHook`** (Main.server.lua): `FunnelEvents(uid)` returns uid's `Funnel._events` entries as `{ { name, value, fields } }`, oldest first; `ResetFunnelEvents(uid)` removes them.
  - **`t59_check`:** require a fresh Funnel, call `Event` with fields on a fake player table (`{ UserId = -4401 }`). Assert the `_events` entry, and that `Funnel._customFields(fields)` returns the three CustomField keys with those strings. No AnalyticsService stub: the guard skips `LogCustomEvent` for a fake player.
- [ ] **Step 4: Verify:** `sh tools/spec.sh` → all PASS (the current deck satisfies the new rules); `luau` prints `SPEC OK` for both.
- [ ] **Step 5: Integrator.** Sync `Systems/Funnel`, `Systems/WalkIns`, `OK/Main`, `Modules/Format`, then run `python3 -I tools/test.py t29 t43 t59`. Expected: all PASS, with Output lines `[OK] telemetry CardChoice …` and no `[OK][ERR]`.
- [ ] **Step 6: Commit** `T0: telemetry + content validator`.

### Task 1: Pure rules: gates, source, first card, caps, seeding

**Files:**
- Modify: `src/ReplicatedStorage/OK/Modules/WalkInRules.lua`
- Modify: `spec/walkin_rules_spec.lua`
- Modify: `src/ReplicatedStorage/OK/Data/WalkIns.lua`: one line in the index block, `W.Deck = { cards, followups, sponsors, visitors = W.VisitorById }`; nothing else
- Modify: `spec/walkins_data_spec.lua`: one assertion next to the existing Deck checks, `Deck.visitors is VisitorById`; nothing else

**Interfaces:**
- Consumes: Shared shapes (Card fields, opts, `W.Deck.visitors`).
- Produces:
  - **`M.GateOk(card, career, visits) -> boolean`**
    - `needs`: `have[k] >= n`; `under`: `have[k] < n`.
    - Keys come from GateKey (`money` = `career.money`, `visits` = the argument).
    - An unknown key returns false.
  - **`M.CapOk(card, caps, day, week) -> boolean`** and **`M.CountCap(state, card, day, week)`**
    - CountCap mutates `state.caps[group]`; a new key (day or week) resets `n` to 0.
  - **`M.Seed(state, deck, opts) -> number`** (cards changed)
    - For every card eligible under `opts` whose `state.seen[id] == nil`, sets `seen[id]` = the lowest `seen` among eligible cards that already have one (0 if none).
    - Mutating; called by the caller before `Pick`.
  - **`M.Pick(state, deck, opts)`** stays pure and keeps its current rng contract when no new field is present. New eligibility, inserted **before** the `when` early returns:
    1. source match: `(card.source or "walkin") == (opts.source or "walkin")`
    2. `GateOk` against `opts.career` (nil career → only cards without needs/under are eligible)
    3. `CapOk` with `state.caps`, `opts.day`, `opts.week`
    4. `card.aired` → `opts.aired`
    5. `opts.exclude[card.id]` → ineligible (checked inside `cardEligible`, so the least-seen pool, the `first` return and `Seed`'s eligible set all honour it)
  - **The walk-in → DM direction of the artist cooldown needs no new rule.** An arrival sets `last[visitor] = count`, and `cardEligible`'s existing cooldown check applies to phone Picks too, because every caller passes `opts.cooldown` (Shared shapes). There is no `lastWalkIn` field.
  - **`dueEntry`** filters by the follow-up's `source` against `opts.source`, and skips ids in `opts.exclude` (the next due entry, or a card, is taken instead).
  - **First card:** when `opts.career` and `opts.career.visits == 0`, an eligible card with `first = true` is returned before the least-seen draw (no rng draw).
  - **`M.Revalidate(state, deck, opts, card) -> boolean`:** `card` is the stored pick's Card; the caller passes `pick.kind == "card" and pick.item or nil` (WalkIns' stored pick is `{ kind, id, item, entry }`). True when the card still passes the full `cardEligible` with the same opts: minCount, the artist cooldown, the sponsor floor, `when`, source, gates, caps and `aired` (`exclude` is ignored). `nil` (a follow-up pick) → true.
  - **`M.CapKeys(nowSeconds) -> day, week`:** `day = math.floor(nowSeconds / 86400)`, `week = day // 7`. WalkIns and Phone both use it for the Pick opts and every `CountCap` (Task 4).
  - **`M.MarkSent(state, item, deck)`** (mutating, like `CountCap`): when `deck.visitors` names `item.visitor` with `kind == "artist"`, sets `state.last[item.visitor] = math.max(state.last[item.visitor] or state.count, state.count)`, so an outcome cooldown is never shortened. Any other sender (the phone-only senders, role visitors) and a deck without `visitors` leave `last` alone. It never touches `count`, `today`, `seen`, `caps` or `queue`.
    - The server calls it when a phone pop is sent; the sim calls it for each phone pop (Shared shapes "Phone rules").
    - Consequence (accepted, design §4.1 "(call)"): the phone Pick applies the cooldown too, so an artist who DMs can neither DM again nor walk in until `cooldown` more walk-ins arrive. In THE HALL, or after the walk-in DailyMax, that is one DM per artist until walk-ins resume.

- [ ] **Step 1: Write the failing spec cases** (scripted rng as today; `unchanged()` purity still asserted on every Pick):
  - `gate: needs followers 5000 excludes 4999 and includes 5000`
  - `gate: under visits 1 only at count 0`
  - `gate: unknown key is never eligible`
  - `source: a phone card never comes back from a walk-in Pick, and a walk-in card never from a phone Pick`
  - `source: a due phone follow-up is skipped by a walk-in Pick and taken by a phone Pick`
  - `first: count 0 returns the first card with no rng draw; count 1 never returns it`
  - `cap: mom group max 2 per week refuses the third in week 0 and allows it in week 1`
  - `cap: CountCap resets n when the key changes`
  - `seed: newly eligible joins evenly`: pool seen {a=3, b=3, c=4}, new card d nil → Seed sets d=3; then over 6 Picks d is drawn at most twice
  - `seed: no eligible seen yet → 0`
  - `aired: needs opts.aired`
  - `phone: an artist who just walked in can't DM for cooldown walk-ins` (the existing cooldown check, `source = "phone"`)
  - `stored pick re-validated`: Revalidate false when the stored card's `under.money` is now reached (a fixture card; the live case is t53's rookie gate)
  - `stored pick re-validated: cooldown`: Revalidate false when the stored card's artist has `last` within `opts.cooldown`
  - `stored pick re-validated: nil card (a follow-up pick) → true`
  - `capKeys: CapKeys(86399) == 0, 0 and CapKeys(7 * 86400) == 7, 1`
  - `exclude: an excluded card is left out of the least-seen pool, so the next tier is drawn when it was the only one left`
  - `exclude: an excluded due follow-up is skipped and the next due one, or a card, is taken`
  - `exclude: absent → identical rng draw count` (keeps the scripted-rng contract)
  - `markSent: after MarkSent(dm from artist X), a walk-in Pick never returns an X card until opts.cooldown more arrivals, and Revalidate rejects a stored X pick`
  - `markSent: a phone-only sender (kind "sender") leaves last unchanged`
  - `markSent: an existing outcome cooldown (last > count) is never shortened`
  - Every existing case still passes unchanged
- [ ] **Step 2: Run** `sh tools/spec.sh walkin_rules` → FAIL on each new case.
- [ ] **Step 3: Implement** the functions above in `WalkInRules.lua`, and the `W.Deck.visitors` line. Keep `Pick`'s rng draw count identical for opts that carry none of the new fields.
- [ ] **Step 4: Run** `sh tools/spec.sh` → all PASS.
- [ ] **Step 5: Commit** `T1: gates, source, first, caps, seed, exclude, MarkSent, CapKeys`.

### Task 2: The pacing sim models the phone and the new rules

**Files:**
- Modify: `src/ReplicatedStorage/OK/Modules/CareerSim.lua`
- Modify: `spec/career_sim_spec.lua`, `spec/pacing_spec.lua`
- Modify: `build/t46_check.lua` (PACING + input + `run()` + the Phone caps check)
- Modify: `src/ReplicatedStorage/OK/Config.lua` (add `Config.Phone`, `Config.WalkIns.WaitLineSeconds`, `Config.Career.Sources.Phone`; values from Shared shapes)

**Interfaces:**
- Consumes: Task 1's `Seed`, `CountCap`, `MarkSent`, opts shape; Shared shapes "Phone rules".
- Produces new `CareerSim.Run` input keys. Both are **required**: `Run` asserts `phonePerDay` is a number, and `phoneSeed` is a number whenever `phonePerDay > 0`. No silent default, so a caller that drops a key errors instead of running with no phone.
  - `phonePerDay` (6, pinned in t46 to `Config.Phone.DailyMax`)
  - `phoneSeed`: the caller passes its seed; `Run` builds `sim.phoneRng = Lcg(phoneSeed + 100003)`. Every draw of a phone pop comes from it, so with no phone cards in the deck the walk-in draws are exactly those of a `phonePerDay = 0` run. `phoneSeed` is per seed, not a Config value, so it is not in t46's `PACING` or `input`.
- Produces two new result keys:
  - `phonePops` (total opened)
  - `phoneAura`: the net Aura phone pops actually applied over the run (gains minus losses, as applied after the stat clamps), the input to Global "Phone Aura budget"

- [ ] **Step 1: Write the failing `career_sim_spec` cases:**
  - `phone pops never add to walkGained` (a fixture phone card with a cost)
  - `phone pops don't advance walkins.count or today`
  - `pickNext passes career, visits, day, week, source, aired`
  - `phoneAura is the net Aura phone pops applied`: a fixture deck with one NEWS (aura +20) and one DM whose only choice is sure (aura −10), `walkinsPerDay = 0`, `phonePerDay = 2` (this case only; least-seen then draws each card once), one day → `phoneAura` equals the sum of the two amounts as `addStat` applied them
  - `first card arrives on visit 1 of day 1`
  - `mom cap holds over 14 days` (≤ 2 per sim week)
  - `seeded new card doesn't arrive twice in a row`
  - `NEWS resolves sure, with no policy draw`
  - `system plant: the first HIT plants mom_plaque once per run`
  - `phone draws never touch the main stream`: a phone-only fixture deck (a DM with a random-policy choice, a non-sure roll and a plant, plus one NEWS card), `walkinsPerDay = 0`, `input.rng` wrapped in a counting spy → the spy is called 0 times while `phonePops > 0`
  - `an artist DM blocks his walk-in for cooldown visits` (fixture deck with `visitors` naming an artist)
  - `a phone follow-up applies once`: TakeQueued comes first; a pick whose TakeQueued returns nil applies nothing
  - `phone outcome money is never applied`: only a choice cost moves money
  - `Run errors without phonePerDay, and without phoneSeed when phonePerDay > 0`

  `career_sim_spec`'s `input()` gets `phonePerDay = 0, phoneSeed = 42`; the phone cases override `phonePerDay = 6`.

  `pacing_spec`: `run()` passes `phonePerDay = 6, phoneSeed = seed`. Print the Legend earliest day, phone pops per day and the random player's phone Aura per day (mean over seeds of `phoneAura / days`) in the summary line. When the deck has any phone card, assert `phone pops per day > 0` (it catches a dropped key once Task 3 adds phone cards) and `phone Aura per day <= 15` (Global "Phone Aura budget"). Both are inactive on today's deck.
- [ ] **Step 2: Run** `sh tools/spec.sh career_sim pacing` → FAIL on the new cases.
- [ ] **Step 3: Implement:**
  - `newSim` adds `walkins.phone = {day=0, today=0, count=0}`, `walkins.caps = {}` and `phoneAura = 0`.
  - `pickNext(sim, source)` builds the opts and calls `rules.Seed` then `rules.Pick`. `aired = sim.economy.firePerDay > 0`: `runDay` calls `receiveFire` before `runVisits`, so a sim day with FIRE has aired a beat before any visit or pop.
  - `arrive` calls `rules.CountCap`.
  - A `runPhone(sim, day)` step runs after `runVisits`, up to `phonePerDay` pops. The gate is Shared shapes' send gate: `CanSchedule(walkins.phone, day, phonePerDay)` (nothing waits in the sim, so `unopened` is 0).
    - **The whole pop runs on the phone stream:** `local main = sim.rng; sim.rng = sim.phoneRng; …; sim.rng = main`, restored on every exit, including the early return when the phone Pick gives nil. That covers the Pick, `chooseByPolicy`'s random draw, Resolve, ResolveNews and any Plant inside `apply`. (Or thread an `rng` argument through those three; either way no phone draw touches `input.rng`.)
    - pick with `source="phone"` (`rules.Seed` then `rules.Pick`; no `exclude`, nothing waits); nil → no more pops that day
    - `rules.MarkSent(walkins, item, sim.deck)` for every pop (the cross-source artist cooldown, same call as the server)
    - DM → `chooseByPolicy` + `resolveChoice`; NEWS card → `Resolve(card.choices[1])`; a due phone follow-up (it wins over cards, like walk-in follow-ups) → `TakeQueued` **first**; when it returns nil the pop is dropped (nothing applied, nothing counted); otherwise `ResolveNews` and apply
    - phone outcomes carry no money (the validator guarantees it), so money moves only through a choice cost; never `walkGained`
    - counted like a server open: `walkins.phone.today += 1`, `walkins.phone.count += 1`, `seen[id] += 1`, `CountCap`. Never `walkins.count` or `walkins.today`.
    - adds the Aura it applied (after the clamp) to `sim.phoneAura`, which `Run` returns as `phoneAura`
    - no `checkSponsorFloor` (the server checks the floor only at a walk-in arrival)
  - `apply` system-plants `mom_plaque` at `{1, 2}` when `hits` goes 0 → >0 and the deck has that follow-up (as `sponsor_drop` is planted).
  - **t46:**
    - Pin the new Config literals in `PACING` + `input` and diff them both ways.
    - Its `run()` builds `Sim.Run` from named fields, so add `phonePerDay = input.phonePerDay, phoneSeed = seed` there too.
    - Print phone pops per day and the random player's phone Aura per day after the `T46 OK:` prefix. When the deck has any phone card, assert phone pops per day > 0 and phone Aura per day ≤ 15 (same guards as pacing_spec).
    - Assert `Config.Career.Sources.Phone.aura.max == 60`, `.followers.max == 2000`, and that the Phone source registers no other stat. These equal `PHONE_CAPS` in `spec/walkins_data_spec.lua` (Task 0), so a Config retune without a spec update fails here.
- [ ] **Step 4: Run** `sh tools/spec.sh` → all PASS.
  - Today's deck has no phone cards, so the only walk-in change is `Seed`. It seeds the six rep cards (sponsor floors 100–400) at the pool minimum when they unlock, instead of letting them win at seen 0. Expected pacing line: Studio Two median day 5 (p10 3, p90 6); random share median 0.391; greedy max 0.483; chaser max 0.408; spend-down max 0.285. These are expected values, not new targets; the guardrail targets are unchanged.
  - **The real criterion is a one-time differential:** run `pacing_spec` once with `R = setmetatable({ Seed = function() return 0 end }, { __index = R })` (a throwaway copy or a temporary local edit, then reverted). It must print today's line exactly: random 0.395, greedy 0.483, chaser 0.408, spend-down 0.283, Hall 5 (p10 3, p90 6). That proves Seed is the only change, even if an implementation detail moves the post-Seed decimals slightly.
  - Paste both lines into the commit message. Keep Seed general (every nil-seen eligible card, not only gated ones). Don't add a kept spec that pins these numbers on `W.Deck`; Task 3 changes the deck.
- [ ] **Step 5: Integrator:** sync `Modules/WalkInRules`, `Data/WalkIns` (Task 1's `W.Deck.visitors` line), `Modules/CareerSim`, `OK/Config`; run `python3 -I tools/test.py t46` → `T46 OK`. t46 loads the live WalkInRules, and the new CareerSim calls `rules.Seed`, so WalkInRules must be synced first.
- [ ] **Step 6: Commit** `T2: sim models phone, gates, caps, first card`.

### Task 3: Content: new people, cards, threads, phone decks

**Files:**
- Modify: `src/ReplicatedStorage/OK/Data/WalkIns.lua`
- Create: `research/wave1_names_2026-10-27.md` (one anchor per new name: the query, the result, the verdict)
- Modify: `spec/walkins_data_spec.lua`: the deliberate carve-outs listed below, the conditional mom/sender name carve-out (Interfaces, display names) and the gate-pools case; nothing else (Task 0 owns KINDS and SIGS)

**Interfaces:**
- Consumes: Task 0 validator, Task 1 fields, Task 2 sim.
- Produces: the ids later tasks and tests use:
  - **Visitors:** `mom` (kind mom, sig `apron`), `booker` (booker, `headset`), `coordinator` (coordinator, `lanyard`), `nextkid` (weird, `cap`), `jarman` (weird, `none`), `stranger` (weird, `none`), `blockkid` (local, `cap`), and senders `unknown`, `feed`, `studio`, `page` (kind sender, sig `none`). The pigeon (`pigeon`, kind critter) and its card `weird_pigeon` are added in Task 5 together with `SpawnSpot`, so it never walks in as a human figure in between.
  - **Display names must never occur inside other text.** The data spec bans every visitor and sponsor display name, in both rosters, as a plain substring of all other strings. "YOUR MOM" would also ban "your moment", and "THE STUDIO" would ban "leaving the studio". Pick names unlikely in prose: senders `UNKNOWN NUMBER` / `PRIVATE NUMBER`, `STUDIO ALERT` / `ROOM ALERT`, `NEWS ALERT` / `NEWS PING`, `PAGE ALERT` / `ACCOUNT ALERT`. Run the spec after each batch of lines. If a collision is unavoidable, add exactly one commented carve-out to the spec for kinds `mom` and `sender`, citing this line.
  - **Cards:**
    - `gentle_first` (fan, `first`, `under visits 1`; no choice cost, no money < 0, no tone loss: Task 0's `first` rule)
    - `mom_food`, `mom_placement`, `mom_busy` (cap mom/week/2)
    - `booker_couch`, `booker_clip` (needs followers 5000)
    - `giveback_laptop`, `giveback_session` (needs money 500)
    - `weird_nextkid`, `weird_jar`, `weird_stranger` (cap weird/day/1; `weird_pigeon` joins the group in Task 5)
    - `rookie_block`, `rookie_corner`, `rookie_open` (under followers 1000)
    - `famous_stadium`, `famous_doc`, `famous_label` (needs followers 20000)
    - `ghost_gig` (rival, needs placements 1, sure $200)
    - `quiz_energy`, `quiz_headphones`, `quiz_sneakers` (sponsor quiz, cap quiz/week/1). Shape (design §8.3):
      - `visitor = "rep"`, `sponsor = <id>`, `when = "unsponsored"`; three choices, all `sure`, none with a cost
      - one right answer: `sponsor = <id>`, `sponsors = 1`, `money = 300`, `aura = 10`, tone win ("the same bonus as 'Sign it'"). Its text carries no "$" and ends like the others.
      - two wrong answers: key `walked`, tone loss, `aura = -10` (as the existing walked outcome, so checkTag passes)
      - the card's `line` quotes the bonus, e.g. "one question and the $300 bonus is yours. what's the one thing you never do in a {sponsor} post?", so the bonus is visible without marking the right answer
  - **Phone:**
    - artist DMs `dm_navx`, `dm_dojabat`, `dm_eyelash`, `dm_drift`
    - `scam_curator`, `scam_label`, `scam_verify`
    - `hacked` (needs followers 2000, §4.3), `leaked` (`aired`), `trending` (needs followers 10000)
    - `mishap_monitor`, `mishap_keys`, `mishap_ac`
    - `news_dance`, `news_spedup`, `news_playlist`, `news_review`, `news_comments`, `news_remix`, `news_fanart`, `news_radio`. §4.3 says "some gated by followers": a news card whose copy names an audience size or a big reach gets `needs = { followers = 2000 }` or `{ followers = 5000 }` (for example `news_dance`, `news_radio`, `news_comments`). Keep at least four news cards ungated, so the day-1 phone pool stays varied. List the gates you chose in `research/wave1_names_2026-10-27.md` § Pacing.
    - **Every phone card and phone follow-up obeys Shared shapes "Outcomes"** (Task 0 enforces it): Aura and Followers only, no outcome money, no placements, no sponsor, positive aura ≤ 60, positive followers ≤ 2000. An artist DM never gives a placement.
  - **Follow-ups:**
    - `rumour` (planted by `rival_steal`'s stolen outcome)
    - `payback_<artist>` × 7 (planted by the free choice of `dojabat_pitch`, `icespike_pitch`, `charti_pitch`, `scoot_pitch`, `llama_pitch`, `drizzle_pitch`, `eyelash_pitch`, at `{15, 25}`). They stay `source = "walkin"`, so their +1 placement carve-out never reaches a phone item.
    - `ghost_out`
    - `clip_context` and `giveback_letter` (source phone, NEWS-style resolve)
    - `mishap_owe`
    - `mom_plaque` (system-planted, exempt like `sponsor_drop`)
  - **`W.WaitLines`** (6 lines), **`W.NoteLines`** (6 lines).
  - **Gated existing card:** `manager_offer` gets `needs = { followers = 20000 }` (§8.2).
- **Deliberate spec carve-outs** (comment each with the design § it comes from):
  - `payback_*` resolves may carry `placements = 1`
  - `mom_plaque` is planted by the system
  - news cards are exempt from "2..4 choices"
  - `quiz_*` cards are exempt from the sure-payout quote rule (spec :182-185), citing design §8.3: the answers must not give the right one away. In its place, one check: the quiz card's `line` contains `F.Money(right.good.money)`. The "$N equals good.money or cost" rule (:186-189) still applies, so no quiz answer types an amount. Add one line to the `Data/WalkIns.lua` header convention note recording this exception (§8.3).
- **Gate pools case** (design §6 "a 180-follower and a 21K-follower profile draw from different pools", §8.2), on the live `W.Deck` through `R.GateOk`:
  - career `{ aura = 0, followers = n, placements = 0, hits = 0, sponsors = 0, money = 0 }`, visits 10
  - at followers 180 the passing walk-in cards include `rookie_block`, `rookie_corner`, `rookie_open` and none of `famous_stadium`, `famous_doc`, `famous_label`, `manager_offer`
  - at followers 21000, the reverse

- [ ] **Step 1: Research the names.** One agent web-checks every new display name in both rosters, plus the youth programme's name, for a same-named real artist, company or programme, and writes `research/wave1_names_2026-10-27.md`. Anything that matches gets replaced.
- [ ] **Step 2: Write the content.**
  - Lines in the existing voice. Copy the shapes from today's cards; "line" is the visitor talking.
  - Mom: never a cost, never a loss.
  - Phone: Aura and Followers only (§4.8): no outcome money (costs only through `choice.cost`), no placements, at most +60 aura and +2000 followers per outcome.
  - Every `$N` in a choice's text equals its sure payout or cost (the quiz cards' exception is above).
  - New sigs (`apron`, `headset`, `lanyard`) are already in the data spec's SIGS (Task 0). Task 5 adds them to `Visitor.SIGS` and to t42's list.
- [ ] **Step 3: Run** `sh tools/spec.sh walkins_data walkin_rules career_sim pacing`.
  - Iterate the levers until pacing passes: random median share ≥ 0.35, The Hall p90 ≤ 7, greedy ≤ 0.50, phone Aura per day ≤ 15.
  - The quiz's $300 adds signing money to the greedy share (about 1.7 points of headroom); report it if it becomes the binding lever. Gating news cards moves early Phone Aura and Followers later, so read the phone Aura per day again after choosing the news gates.
  - pacing_spec and t46 now assert phone pops per day > 0 and phone Aura per day ≤ 15 once the deck has phone cards (Task 2). A 0 pops figure means a dropped Run key, not a content problem.
  - Record every lever used, the final summary line and the phone Aura per day in `research/wave1_names_2026-10-27.md` § Pacing.
- [ ] **Step 4: Integrator:** sync `Data/WalkIns`; run `python3 -I tools/test.py t46 t50`. Both PASS (`t50` scans every new string).
- [ ] **Step 5: Commit** `T3: wave 1a content (N cards, M follow-ups), pacing <summary>`.

### Task 4: The phone server and the walk-in scheduler changes

**Files:**
- Create: `src/ReplicatedStorage/OK/Systems/Phone.lua`
- Modify: `src/ReplicatedStorage/OK/Systems/WalkIns.lua`:
  - exports `M.Busy`, `M.DueWithin`, `M.OnReset`, and for Phone `M.State` (= `state`), `M.Filler` (= `filler`), `M.Chips` (= `chipsFor`), `M.Names` (= `NAMES`)
  - nextPick: opts (`day`, `week` from `Rules.CapKeys(ctx.Data._now())`), `Seed`, and `Rules.Revalidate(st, Content.Deck, opts, pick.kind == "card" and pick.item or nil)` on the stored pick (after `dropStale`; re-pick when false)
  - onArrive: `Rules.CountCap(st, rec.item, day, week)` next to the seen/last counters (WalkIns.lua:296-302); a no-op for items without `cap`
  - `PhoneBusy` check in `schedule`; `tick` returns early while `PhoneBusy` is set
  - `apply`: when `hits` goes from 0 to > 0, `Rules.Plant(st, { id = "mom_plaque", at = {1, 2} }, W.FollowupAt, rngFor(p.UserId))`, the sim's `at` (Task 2). Plant refuses a second while one is queued.
  - `state()` repairs `phone`/`caps`
  - `reset()` runs the OnReset list; hook commands `Plant`, `SetCaps`, `Caps`
- Modify: `build/17_career_remotes.lua` (Phone, Phone_Choose, Phone_Open, WalkIn_Deferred)
- Modify: `src/ReplicatedStorage/OK/Systems/Funnel.lua` (none if Task 0 covers it)
- Create: `build/t51_play_server.lua`, `build/t51b_play_server.lua`, `build/t52_play_server.lua`, `build/t53_play_server.lua`
- Modify: `build/t43_play_server.lua`, `build/t43b_play_server.lua`, `build/t43c_play_server.lua`, but only assertions that named a specific default pick (Review Focus 5)

**Interfaces:**
- Consumes: Task 1 rules (`Seed`, `Pick` with `exclude`, `Revalidate`, `CountCap`, `MarkSent`, `CapKeys`); Task 3 ids; Config.Phone; Funnel events; Shared shapes "Phone rules", the hooks and `"expire"`.
- Produces:
  - **`WalkIns.Busy(player) -> boolean`:** `pending[uid] ~= nil`. Safe before Init (false).
  - **`WalkIns.DueWithin(player, s, ignorePause: boolean?) -> boolean`:** `(ignorePause or not paused())`, `remaining[uid] ~= nil and <= s`, inHub, tour done, cypher idle, `today < DailyMax` after a Rollover. Phone's live loop passes nil (the loop doesn't run while paused anyway); the `Tick` hook passes true so tests can exercise the rule under the suite's pause.
  - **`WalkIns.OnReset(fn)`:** appends `fn` to a module-level list.
    - WalkIns' `reset(p)` (the hook Reset) calls every fn inline at its end, passing `p`, each in a pcall that warns `[OK][ERR] reset hook: …` on error.
    - `Phone.Init` registers its reset there. The list lives at module level, so Init order doesn't matter. WalkIns never requires Phone.
    - There is no attribute-bump seam: the place runs deferred signals, so a bumped attribute's handler would fire after the test's next Pops and wipe them.
  - **Cap keys:** WalkIns and Phone both call `Rules.CapKeys(ctx.Data._now())` (Task 1) for the Pick opts and every `CountCap`. Never `utcDay()` (yyyymmdd): those keys never match the ones `CapOk` sees, so no cap would hold.
  - **Phone reuses WalkIns' helpers** instead of copying them:
    - `WalkIns.State(p)` for `prof.walkins` (Phone has no accessor of its own)
    - `WalkIns.Filler(sponsorId)` for `{name:<id>}`/`{sponsor}`, and `WalkIns.Names` for the sender's name
    - `WalkIns.Chips(applied)` for `PhoneResult.chips`
    - `State` needs WalkIns' ctx, so Phone calls it only from player and loop paths, never inside `Init`
  - **Phone follow-ups** (`source = "phone"`, e.g. `clip_context`, `giveback_letter`): a due one is delivered by the phone as a NEWS pop (`kind = "news"`, PopPayload `card.app = "NEWS"`; the pending entry keeps its queue entry).
    - At its first open, `Rules.TakeQueued(st, entry)` runs **first**. Nil (already taken) → dropped quietly: `("expire", {token})`, `PhoneExpire` detail `taken`; no count, no seen/caps, no `PhoneBusy`, no apply.
    - Otherwise its `resolve` is rolled with `Rules.ResolveNews` (Phone's rng) and applied through the `Phone` source.
    - Task 2's `runPhone` follows the same order.
  - **`WalkIns.schedule`** refuses while the player attribute `PhoneBusy == true`. **`tick`** returns early while it is set (as it does for `pending[uid]`), so the walk-in timer doesn't run out behind an open DM.
  - **Phone scheduler:**
    - A per-player timer that runs only while all of these hold:
      - not paused
      - tour done (poll `Tour.State`, stamp the time the first time `done` is seen)
      - cypher idle
      - `not WalkIns.Busy(p)` and `not WalkIns.DueWithin(p, Config.Phone.WalkInDueSeconds)`
      - `PhoneBusy ~= true`: no opened DM awaiting a choice (§4.1 eligible time)
      - Shared shapes' send gate: un-opened pending < `MaxWaiting`, and after `Rules.Rollover(st.phone, utcDay())`, `st.phone.today + unopened < DailyMax`
    - First pop: `FirstDelay` after max(join, tour done). Then `Gap`.
    - Pick: `Rules.Seed` then `Rules.Pick` with:
      - `source = "phone"`
      - `cooldown = Config.WalkIns.ArtistCooldown`. Required: Pick errors on nil, and this check is what keeps an artist who just walked in from DMing.
      - `career`, and `day`/`week` from `Rules.CapKeys(ctx.Data._now())`
      - `aired` from `ctx.Monitors.Aired` (session memory keyed by uid; cypher system airings count for their real uid)
      - `exclude` = the ids of every entry in `pending[uid]`, opened or not, so two waiting pops never share a card or a follow-up
    - Sends `("pop", PopPayload)`, then calls `Rules.MarkSent(st, item, Content.Deck)` (the artist cooldown runs across both sources from the send).
    - Phone owns its own `Random.new()` plus a per-uid forced list (hook `SetRng`) for Pick, Resolve, ResolveNews and Plant. It never uses WalkIns' `rngFor`/`forced`.
  - **Phone's `send(p, kind, payload)`:** records `{ kind, token }` for hook `Sent` (Studio only), then fires the remote, except `"pop"` and `"result"` while Quiet is on for `p`. `"expire"` always fires.
  - **`Phone_Open(token)`** (the remote handler drops it while Quiet; hook `Open` calls the same path):
    - an unknown token from this player → `("expire", {token})` and nothing else (the client opened a pop the server just dropped)
    - first time only, in this order:
      1. a follow-up pop's TakeQueued check (above)
      2. `Rules.Rollover(st.phone, utcDay())`
      3. mark opened and set `openedAt = os.clock()`
      4. `st.phone.today += 1`, `st.phone.count += 1`, `seen[id] += 1`, `Rules.CountCap` (keys from `Rules.CapKeys`)
      5. `PhoneOpen` telemetry; a DM sets `PhoneBusy = true`
    - No DailyMax check at open. The send gate already reserved the slot, and the Rollover keeps a pop sent before UTC midnight on the new day.
    - NEWS (card or follow-up): apply its sure outcome now, send `("result", …)`, log `CardNews` (source `phone`, card = id, detail = outcome key), remove the pending entry. `PhoneBusy` is held only until the result is sent.
    - A second Open of the same token does nothing.
  - **`Phone_Choose(token, index)`** (the remote handler drops it while Quiet; hook `Choose` calls the same path):
    - DM only, after open. An unknown or foreign token → `{ ok = false, reason = "stale" }` (the client drops the card); a NEWS token or a DM not yet opened → `"invalid"` (the client keeps it).
    - index 0 = dismiss: no stats; logs `CardWalkAway` (source `phone`), then the same removal and `PhoneBusy` recompute as below, with no result
    - otherwise Resolve (Phone's rng) → `Data.SpendCred` for a cost → apply through `Career.Add(p, stat, n, "Phone")` / `Career.Take`; plant via `Rules.Plant` (Phone's rng) with the follow-up's source
    - Outcome money is never applied: no `AddCred`, no `TakeCred`. The validator guarantees phone outcomes carry no money and no placements, hits or sponsors. If live content ever has them, report `[OK][ERR]` and apply nothing for those fields; never route them through the WalkIn source.
    - sends the result; removes the entry; recomputes `PhoneBusy` (true only while another opened DM remains); `CardChoice` telemetry with source phone (index ≥ 1 only)
  - **Expiry sweep** (Phone's 1 s loop; it runs while paused, like WalkIns' upkeep; hook `Age` runs it at once for one player):
    - An un-opened pop older than `ExpireSeconds` is dropped: `("expire", {token})`, `PhoneExpire` detail `waited`, no count, no stats.
    - An opened DM unanswered for `OpenExpireSeconds` (from `openedAt`) closes as a dismiss: `("expire", {token})`, no stats, it stays counted (counted at open), the entry is removed, `PhoneBusy` is recomputed, `PhoneExpire` detail `opened`.
  - **Drop paths:** respawn (`CharacterAdded`), Phone hook `Reset`, and the WalkIns hook Reset through `OnReset`.
    - Each sends `("expire", {token})` for every entry in `pending[uid]`, opened or not, then clears `pending[uid]` and `PhoneBusy`.
    - These are not expiries: no `PhoneExpire`, no count.
    - The two reset paths also clear the timer and the tour stamp (FirstDelay applies again) and the SetRng list. Neither touches Quiet.
  - **Leave:** clear `pending[uid]`, `PhoneBusy`, Quiet, the SetRng list and the timer. Send nothing; the player is gone.
  - **Hook `_StudioPhoneHook`** (Studio and running only): the commands and semantics in Shared shapes. `Tick(uid, s)` is the only way the pace tests move the phone, because `tools/test.py` keeps the shared pause on for the whole Play session; it passes `ignorePause = true` to `DueWithin`.
  - **New WalkIns hook commands:** `Plant(uid, id)`, `SetCaps`, `Caps(uid)`, and (Task 5) `SetDeferred`, as in Shared shapes.
  - **WalkIns hook `Reset`** wipes `st.phone`/`st.caps` with the rest of `prof.walkins` (newState) and runs the OnReset list before returning, so Phone's pending pops, `PhoneBusy` and timer are cleared synchronously.
- [ ] **Step 1: Write the failing Studio tests.** Each file follows Global Constraints "Phone test isolation": `Quiet(uid, true)` first, the body in a pcall, then the cleanup there (WalkIns `Reset(uid)`, Phone `Reset(uid)`, `Quiet(uid, false)`), and rethrow. Each file first teleports the player to the lounge (24, 3, 0), as t43b does: Spawn, Poke and `DueWithin` all need the hub.
  - **Clean start `fresh()`** (t43b's helper, extended). Each numbered t51 step and each t51b, t52 and t53 case starts with it:
    1. WalkIns `Reset(uid)`. It ends any walk-in (so `WalkIns.Busy` is false), sets the walk-in timer to 1e6 (so `DueWithin` is false) and runs Phone's reset through OnReset. It also wipes `count`, `last`, `seen`, `queue`, `phone` and `caps`, so a case stages any walk-in state it needs itself.
    2. Advance the tour: `TourAdvance` for every `Tour.Steps` id through `_StudioTestHook` (t43b's `advanceTour`).
    3. Phone `Reset(uid)`, then `SetToday(uid, 0)` unless the step sets its own today.
    4. A case that asserts telemetry then calls `ResetFunnelEvents(uid)`.
    No step or case relies on state an earlier one left.
  - **`t51_play_server`** (the pause stays on; the test drives the phone with `Tick`). Step 1 is the positive control for steps 2-4: each differs from it by one blocker and Ticks 200 s, more than the longest FirstDelay (150 s).
    1. `SetRemaining(uid, 2)` then `Tick(uid, 3)` sends one pop
    2. No pop while `WalkIns.Busy`: Spawn a walk-in, then `Tick(uid, 200)` → none
    3. None while the tour isn't done: `ResetTour`, then `Tick(uid, 200)` → none
    4. None when a walk-in is due within 60 s: WalkIns `SetRemaining(uid, 30)` (in the lounge, tour done, cypher idle), then `Tick(uid, 200)` → none
    5. `MaxWaiting` holds at 2: at today 0, two `Tick(uid, 200)` send two pops, and a third sends none
    6. The day caps at 6, a waiting pop holds its slot, and an expired one gives it back. Every send here is a `Tick`, never a `Pop` (Pop skips DailyMax):
       1. `SetToday(uid, 5)`, `Tick(uid, 200)`: one pop (A)
       2. `Tick(uid, 200)` without opening A: none (5 + 1 waiting = 6)
       3. `Age(uid, 601)`: A expires (`Pending` empty)
       4. `Tick(uid, 200)`: one pop (B)
       5. `Open(B)` (then `Choose(B, 0)` if it is a DM, so `PhoneBusy` is clear): `State(uid).today == 6`
       6. `Tick(uid, 200)`: none
    7. Midnight:
       - `SetToday(uid, 3)`, then `day0 = State(uid).day` (today's yyyymmdd)
       - `Pop(uid)`, then `SetDay(uid, tonumber(os.date("!%Y%m%d", os.time() - 86400)))`, then `Open` it
       - → `State(uid).today == 1` and `State(uid).day == day0`. Without the Rollover at open it reads 4 and yesterday.
    8. An opened DM blocks both sides, with a positive control:
       - `Pop(uid, "scam_curator")`, `Open` it → `PhoneBusy` set; WalkIns `Poke` → false; `Tick(uid, 200)` → none
       - control: `Choose(uid, token, 0)` (PhoneBusy clears), then `Tick(uid, 200)` → one pop, then WalkIns `Poke` → true
       - Keep that order: a Poke first would set `WalkIns.Busy` and block the Tick.
    9. First-pop window (§6 "90–150 s"): `Tick(uid, 89)` → none; `Tick(uid, 61)` → one pop
    10. Cypher (§4.1): `_StudioCypherHook` `Join(-4302, "Phone Test")` opens a lobby (phase ≠ `"idle"`) → `Tick(uid, 200)` → none. Then `Skip` until the phase is idle (≤ 25 tries, 0.4 s apart, as t43b) → `Tick(uid, 200)` → one pop.
  - **`t51b_play_server`** (Review Focus 4):
    - Pop two DMs and `Open` the first. `p:LoadCharacter()`, wait for the new character, then poll until `Pending(uid)` is empty (≤ 5 s; the place runs deferred signals, so the `CharacterAdded` handler can land after the character appears). Then: `PhoneBusy` nil, `Pending` empty, `Sent(uid)` holds an `expire` for both tokens, no `PhoneExpire` logged, and `State(uid)` today/count unchanged from after the Open.
    - Pop two again and Open one. Then `_StudioWalkInHook:Invoke("Reset", uid)` and assert **with no wait**: Phone `Busy(uid) == false`, `Pending(uid)` empty, `p:GetAttribute("PhoneBusy") == nil`, and `Sent(uid)` holds an `expire` for both. This proves the reset seam is synchronous.
  - **`t52_play_server`:**
    - `Age(uid, 601)` expires an un-opened pop: no count, no stats, `PhoneExpire` logged with detail `waited`
    - NEWS applies only at `Open` and only once (two Opens of one token → one apply and one `CardNews`, source `phone`)
    - A DM choose pays no money. `Pop(uid, id)` a DM whose chosen index is `sure`, with no `rare` and no cost (or use Phone `SetRng`). Assert `Cred` unchanged, `Aura` rose through the `Phone` source (a bad outcome would go through `Career.Take` and fail this), and one `CardChoice` (source `phone`) was logged.
    - A dismiss (`Choose(uid, token, 0)` on an opened DM) logs one `CardWalkAway` (source `phone`) and no `CardChoice`.
    - A stale or foreign token is refused: `Choose` → stale; `Open` of an unknown token → `Sent` shows an `expire` for it
    - An opened DM expires: Pop a DM, `Open`, `Age(uid, 301)` → `PhoneBusy` false, `Pending` empty, Aura/Followers/Cred unchanged, `State` today/count unchanged from after the Open, `PhoneExpire` detail `opened`, and WalkIns `Poke` succeeds
    - One follow-up, one pop: WalkIns `Plant(uid, "clip_context")`, then `Pop(uid)` twice with no id → exactly one pending entry carries `clip_context` (exclude); the other is a different card or nothing
    - A follow-up applies once: `Plant(uid, "clip_context")`, Phone `SetRng(uid, {1})` (so ResolveNews rolls good), then `Pop(uid, "clip_context")` twice (forced, so two tokens).
      - Open the first: Aura/Followers move by exactly the good outcome, the career log gains one `Phone`-source entry per positive stat in that outcome, and the queue no longer holds `clip_context`.
      - Open the second: `Sent` shows its `expire`; no stat change, the career log unchanged, no count, `PhoneBusy` unset, `PhoneExpire` detail `taken`.
  - **`t53_play_server`:**
    - after `fresh()` (a walk-ins Reset), `Spawn()` brings `gentle_first`
    - mom's cap holds through `SetToday` and a forced week key (hook `SetCaps`)
    - A stored pick whose gate closed is re-picked (Review Focus 3), with a positive control. Read followers first and `Set` them back after. Two separate runs, each from its own `fresh()` (a pending walk-in makes `spawnNow` refuse):
      - staging, the same in both runs: `fresh()`, `AdvanceVisits(uid, 1)` (keeps `gentle_first` out of the re-pick), `_StudioCareerHook` `Set({ followers = 0 })`, `Spawn(uid, "rookie_block")`, then `Expire` before arrival (the stored pick stays in `st.next`)
      - run A, the control: staging, then `Set({ followers = 999 })`, `Spawn(uid)` → `Pending().id == "rookie_block"` (still under 1000, so it is reused)
      - run B, the gate closed: staging, then `Set({ followers = 1000 })`, `Spawn(uid)` → `Pending().id` is not a `rookie_*` card
    - the first HIT system-plants `mom_plaque` once
    - Caps count at arrival, not at pick:
      1. `fresh()`, then `AdvanceVisits(uid, 1)` (keeps `gentle_first` out of the way)
      2. `Spawn(uid, "weird_jar")`, then `Expire` before arrival
      3. `Spawn(uid)` (default, so nextPick reuses the stored pick through Revalidate) → `Pending().id == "weird_jar"`
      4. after arrival, `Caps(uid).weird.n == 1` with key = today's day number
      5. after it ends, one more `Spawn(uid)` brings no `weird_*` card
    - DM → walk-in cooldown (after `AdvanceVisits(uid, 1)`):
      - `Pop(uid, "dm_navx")` → `GetProfile` shows `walkins.last.navx == walkins.count`, and `Spawn(uid)` never brings a navx card
      - a stored navx pick (`Spawn(uid, <a navx card>)`, `Expire` before arrival), then `Pop(uid, "dm_navx")`, then `Spawn(uid)` → a non-navx card (Revalidate's cooldown)
- [ ] **Step 2: Integrator:** run `python3 -I tools/test.py --play t51 t52 t53` → FAIL (missing system).
- [ ] **Step 3: Implement** `Systems/Phone.lua`, the WalkIns changes and the remotes. Wrap `M.Choose`'s apply section in a pcall that restores the visitor's leave and `remaining` on error (the walk-ins ledger's deferred item).
- [ ] **Step 4: Integrator:**
  1. Run `build/17_career_remotes.lua`.
  2. Sync `Systems/Phone`, `Systems/WalkIns`, `Modules/WalkInRules`, `OK/Config`.
  3. Run `python3 -I tools/test.py --play t43 t47 t51 t52 t53` → all PASS.
  4. Then run `python3 -I tools/test.py --edit` → only the 4 light-cap checks fail.
- [ ] **Step 5: Commit** `T4: phone server + scheduler gates`.

### Task 5: Visits that behave like people (server)

**Files:**
- Modify: `src/ReplicatedStorage/OK/Systems/WalkIns.lua`:
  - `endVisit(rec, reason)`
  - expiry note payload
  - `WalkIn_Deferred` handler
  - waiting-line rotation in `upkeep`
  - pigeon dispatch in `walkIn`
  - hook commands `SetDeferred`, `Sent` and the extended `Age` (Shared shapes)
- Modify: `src/ReplicatedStorage/OK/Modules/Visitor.lua` (`SIGS.apron`, `headset`, `lanyard`; `M.SpawnSpot(def, target, opts)`)
- Modify: `build/t42_play_server.lua` (SIGS list + a spot case)
- Modify: `src/ReplicatedStorage/OK/Data/WalkIns.lua`, adding only the `pigeon` visitor and the `weird_pigeon` card (cap group weird; fixed tag and line, below); `research/wave1_names_2026-10-27.md` gets its web-check; re-run `sh tools/spec.sh walkins_data pacing`
- Create: `build/t54_play_server.lua` (note), `build/t55_play_server.lua` (waiting lines), `build/t56_play_server.lua` (pigeon)

**Interfaces:**
- Consumes: Task 3 `W.WaitLines`, `W.NoteLines`, the pigeon visitor; `Format.Duration`; Task 4's WalkIns state.
- Produces:
  - **`endVisit(rec, reason)`:** reason ∈ `expired | left_hub | respawn | left_server | error | gone | hook`. Only `expired` attaches `note = { name, waited, line }` to the `leave` payload, and logs `CardExpire` + `CardNote`.
  - **`WalkIn_Deferred(token, deferred)`:**
    - sets `rec.deferred` for the matching arrived record; others are ignored
    - while `rec.deferred`, `upkeep` calls `rec.handle:Say(rec.fill(W.WaitLines[i]))` every `Config.WalkIns.WaitLineSeconds`, cycling i
    - lines start after the first 45 s of deferral
  - **Hook `Sent(uid)`** (Studio only): WalkIns' `send` records `{ kind, payload }` for uid while the hook exists; `Sent` returns them and clears the list. Phone's `Sent` stays `{ kind, token }`.
  - **Hook `Age(uid, s)`** moves every clock on the open record back s: `arrivedAt` (as today), the deferral start and the last waiting-line time. The next 1 s upkeep applies expiry and the next line.
  - **`Visitor.SpawnSpot(def, target, opts) -> Handle`:**
    - same public surface (`Say`, `Leave`, `Destroy`, `Arrived`, `Model`) and onGone-once contract
    - places a ≤ 12-part pigeon on `workspace.OKStudio.Lounge.Coffee_Top`'s top face (read at runtime), offset 1.5 studs per live pigeon
    - parent `Workspace.OK_Visitors`
    - `Arrived = true` and `onArrive` fire on the next Heartbeat, never inside the call
    - `Leave` = a 1 s flight up then Destroy
    - leaves when the target leaves the hub
  - **`walkIn`** dispatches visitors of kind `critter` to `SpawnSpot`. The pigeon does take a `MaxWalking` slot.
  - **The pigeon card's text is fixed, with no token:** `weird_pigeon` has `tag = "THE LOUNGE · COFFEE TABLE"` and `line = "coo."`.
    - The tag always names the lounge, which meets §4.3 ("in the control room or the booth, the card says it's in the lounge") with no room check. The visitor name shows as the sender on the card.
    - Neither string contains a `{…}` token: `WalkInRules.Fill` fills only `{name:<id>}` and `{sponsor}`, and the data spec fails any text that still holds `{` after Fill.
    - Neither contains the pigeon's display name (A PIGEON, §4.3): the data spec bans display names in all other text. The tag is caps.
- [ ] **Step 1: Write the failing tests:**
  - **`t54_play_server`:**
    - Read `c0 = walkins.count` (`GetProfile`), Spawn, wait for arrival → `walkins.count == c0 + 1`. Call `Sent(uid)` to clear it, then `Age(uid, 301)`.
    - Within 2 s, `Sent(uid)` holds one `leave` whose `payload.note.waited == "5 minutes"`, and `walkins.count` is still `c0 + 1`: the visit counts once, at arrival (§6).
    - WALK AWAY → its `leave` has no `note`; Expire via hook → no `note` (reason hook).
  - **`t55_play_server`:**
    - Spawn, wait for arrival, then `SetDeferred(uid, token, true)` (the `WalkIn_Deferred` path) and `Age(uid, 46)` → within 2 s the bubble text is a filled `W.WaitLines` line.
    - `SetDeferred(uid, token, false)`, then `Age(uid, 46)` again → the bubble text is unchanged for 5 s (Global: "nothing happens" waits ≤ 5 s).
  - **`t56_play_server`:** from the control room, Spawn `weird_pigeon` → a model under OK_Visitors within Coffee_Top's x/z bounds at y ≈ 1.5, Arrived within 2 s; the card tag names the lounge (`string.find(Content.CardById.weird_pigeon.tag, "LOUNGE")`, and no `{` in tag or line); Choose (a real choice, not WALK AWAY) → the model is gone within 5 s (2 s result delay + 1 s flight + slack). Don't tighten this by cutting the delay or the flight.
  - **`t42`:** the new sigs build 8–16 parts; SpawnSpot case.
- [ ] **Step 2: Integrator:** run → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Integrator:** sync `Systems/WalkIns`, `Modules/Visitor`, `Data/WalkIns` (the pigeon and `weird_pigeon`, which t56 Spawns); run `--play t42 t43 t54 t55 t56` → PASS. Then, with Task 6 synced too, Wave F's combined run (Task 6 Step 4) covers these files against the new clients.
- [ ] **Step 5: Commit** `T5: note card, waiting lines, pigeon`.

### Task 6: The phone and the note on the client

**Files:**
- Create: `src/ReplicatedStorage/OK/Modules/PhoneUI.lua`
- Modify: `src/ReplicatedStorage/OK/Modules/WalkInUI.lua`:
  - `phoneOpen()` term in `refresh`'s deferral and the pendingNews gate
  - `WalkIn_Deferred` fire on flip
  - a note card through the result frame with neutral tone and a distinct token `"note:"..token`
  - a pending list instead of one slot
  - `placeChip` also takes `OK_Phone.Icon` (one more name in its list, WalkInUI.lua:319-322), so the IS WAITING chip sits under the icon too
- Modify: `src/ReplicatedStorage/OK/Modules/CypherUI.lua`: the Bar's `layout` reads `OK_Phone`'s `IconSpot` and re-runs when it changes. With `"pills"`, `pillsRight()` returns the icon's right edge (Career's right + 8 + 44), so the Bar starts after the icon. With `"corner"`, the beside-the-pills `room` leaves 64 px at the top right.
- Modify: `src/StarterPlayer/StarterPlayerScripts/OK/ClientMain.client.lua` (build PhoneUI after WalkInUI, in a pcall that reports `[OK][ERR]`)
- Create: `build/t57a_play_server.lua` … `build/t57f_play_client.lua` (alternating server/client, like t47a–h: client tests can't call BindableFunction hooks, so every staging step is a server file), `build/t58a_play_server.lua` … `build/t58h_play_client.lua` (t58a/b the note; t58c–h the drop paths on the client, last in the suite so no later file inherits a respawn)

**Interfaces:**
- Consumes: the remotes, payloads and `"expire"` meaning in Shared shapes; the hooks in Shared shapes (Task 4); Task 5 note payload.
- PhoneUI has no test-only branch. Server tests that stage pops turn on Phone's `Quiet` (Global Constraints), so the live client never sees their pops; `t57a` turns it off for this task's chain.
- Produces: `PlayerGui.OK_Phone` (DisplayOrder 9, ResetOnSpawn false, CoreUISafeInsets) with:
  - **Icon:** 44×44, red count badge, shake via a UIScale tween on a child. Hidden while the compact beat maker is open; the count shows again on close.
    - **Beside the pills** (design §4.1; mockup boards 1 and 3 draw it at x 628, y 6, 8 px right of the Followers pill): left = the right edge of `OK_UI.Career` + 8, top = Career's top − 4. Read Career's absolute rect, found the way WalkInUI.lua:320 finds it (HUD is not edited), and convert it into OK_Phone's space. Re-place it when that rect or OK_UI's `ForceViewport` changes.
    - **Fallback:** the top right (`right -16, top 8`), only when the icon would enter FIRE's column. That is when Career's right + 8 + 44 + 8 > vp.X − 152, with vp = OK_UI's `ForceViewport` or size, the clearance the pills keep (HUD.lua:66). CypherUI keeps that spot free.
    - The spot depends on Career and the viewport only, never on the cypher Bar (the Bar places itself after the icon), and it stays put while the icon is hidden. PhoneUI publishes it as the gui attribute `IconSpot` = `"pills"` | `"corner"`.
  - **Card:** right side, `right -16`, top 58 (under the icon in both spots); while the cypher Bar shows beside the pills and reaches the card's column, 8 px under the Bar instead (as FIRE sits under it; fix round 2), so the two never overlap. A Bar under the pills (phones, y 74) starts below the card's top and shares its rows (documented, like FIRE / SAMPLE IT):
    - width `min(300, vp.X*0.42)`, at least 240
    - header (app label + sender name in its colour), scrolling message, 0–4 choices of 44 px, footer with DISMISS
  - **Inline result:** in the same card, no centred result; NEWS auto-closes after `Config.Phone.NewsCloseSeconds`.
  - **Gui attributes:** `Open`, `Deferred`, `Pending` (count), `Token`, `Card`, `Choices`, `ResultKey`, `ResultTone`, `LastChoose`, `Command` (`choose:<n>` | `dismiss` | `open` | `ok`), `ForceViewport`, `IconSpot`.
  - **When a pop opens:** it opens by itself only when the beat maker is closed, no walk-in card or result is visible, and the cypher is idle. Then it fires `Phone_Open(token)`, arms after 0.6 s and focuses its header.
  - **On `("expire", {token})`** (the token is gone on the server, opened or not):
    - drop the token from the waiting list; update `Pending` and the red count badge
    - if it is the card on screen (a DM, armed or not, a NEWS card still waiting for its result, or a card hidden behind the beat maker): close it, clear `Open`, `Token` and `Card`, and cancel the 0.6 s arm timer and the NEWS auto-close timer; then the next waiting pop or walk-in card may open
    - never show it or fire `Phone_Open` for it again
    - an expire for a token PhoneUI doesn't hold is ignored
  - **A `Phone_Choose` reply `{ ok = false, reason = "stale" }`** closes and drops that card the same way (as WalkInUI does for `WalkIn_Choose`).
  - **`Config.Phone.Layout = "walkin"`** draws the card centred with the walk-in card's width instead (one branch in layout).
- [ ] **Step 1: Write the failing tests:**
  - **`t57a_play_server`:** `Quiet(uid, false)`; WalkIns `Reset` (it resets the phone synchronously, so no wait is needed); then hook Pop a DM and a NEWS.
  - **`t57b_play_client`:**
    - first assertion (no carry-over from earlier files): the card that opens by itself has `Card` == the DM id t57a popped, and `Pending` equals what t57a sent, with no earlier token
    - the DM opens by itself within 5 s; buttons ≥ 44 px with `TextFits`
    - the card is inside the box at the real viewport and at `ForceViewport` 844×390 and 667×375 (minus the real inset)
    - no overlap with HUD, Career, Daily, Tour, the cypher Bar, FIRE or SAMPLE IT, except FIRE/SAMPLE IT while the card is open (documented)
    - the icon overlaps nothing on the card's list (HUD, Career, Daily, Tour, the cypher Bar shown with its `ForceShow`, FIRE, SAMPLE IT) in either spot. `IconSpot` is `"pills"` when OK_UI's `ForceViewport` is 844×390 (pills side by side) and `"corner"` at 667×375.
    - `choose:1` → inline result; then NEWS opens, auto-closes within 9 s
    - finally opens the beat maker at the studio PC (as t47b does) and leaves it open
  - **`t57c_play_server`** (Review Focus 2), while the client's beat maker is open: `Pop(uid, "<dm_A>")`, `Age(uid, 400)`, `Pop(uid, "<dm_B>")`, `Age(uid, 201)`, using two different DM ids from Task 3. `Age` takes no token, so A reaches 601 s and expires while B is at 201 s. Assert `Pending(uid)` holds only B, and A logged no `PhoneOpen` and changed no count (`State`).
  - **`t57d_play_client`:**
    - before closing: `Pending == 1` (2 would mean the client ignored the expire), `Open == false`, the icon shakes
    - `Command = "close"` on the beat maker → the card opens within 2 s with `Card == "<dm_B>"`; sampled every 0.1 s, `Card` never equals `"<dm_A>"`
    - dismiss → `Pending == 0`
  - **`t57e_play_server`** (Review Focus 1): hook Pop a DM and WalkIns Spawn a walk-in in the same server call (back to back).
  - **`t57f_play_client`:** never both `OK_Phone.Open` and `OK_WalkIn.Open` at any 0.1 s sample; the second card opens after the first closes (drive the first with `dismiss` or `walkaway`); then close the second the same way, so nothing is open. Finally open the beat maker at the studio PC (as t57b does) and leave it open for t58a.
  - **`t58a_play_server` / `t58b_play_client`:** with the beat maker t57f left open, t58a Spawns a walk-in, waits for arrival and `Age(uid, 301)`, so he expires behind it. t58b: the note shows after closing the beat maker (`Command = "close"`), reads `<NAME> LEFT` / "waited 5 minutes", fits the result frame and auto-hides.
  - **The drop paths on the client** (Review Focus 4). Each server step waits for `p:GetAttribute("PhoneBusy") == true` (≤ 5 s), which shows the client opened the DM by itself.
    - **`t58c_play_server`:** Pop a DM; once it is open, `Age(uid, 301)` (the opened DM expires).
    - **`t58d_play_client`:** within 2 s `Open == false`, `Pending == 0`, `Token` cleared.
    - **`t58e_play_server`:** Pop a DM; once it is open, Pop a second (it waits); then WalkIns `Reset`.
    - **`t58f_play_client`:** within 2 s `Open == false` and `Pending == 0`.
    - **`t58g_play_server`:** Pop a DM; once it is open, Pop a second; `p:LoadCharacter()`, wait for the new character and poll until Phone `Pending(uid)` is empty (≤ 5 s; deferred signals), then teleport it back where t57a started.
    - **`t58h_play_client`:** within 2 s `Open == false` and `Pending == 0`, and no phone card opens in the next 5 s.
- [ ] **Step 2: Integrator:** run → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Integrator:** sync `Modules/PhoneUI`, `Modules/WalkInUI`, `Modules/CypherUI`, `OK/ClientMain` (and Task 5's files, synced in the same wave); run `--play t42 t43 t45 t47 t51 t52 t53 t54 t55 t56 t57 t58` → PASS. This runs the new PhoneUI and WalkInUI (with its `WalkIn_Deferred` remote) against every phone and walk-in server test in suite order, before Task 7. The `t51` selector also picks up `t51b`.
- [ ] **Step 5: Commit** `T6: PhoneUI, mutual exclusion, note card`.

### Task 7: Integration, review and report

**Files:**
- Modify: `README.md` ("Milestone 10 'Life Happens 1a'")
- Create: `WAVE1A_REPORT.md`
- Modify: `../OK_GAME_TRACKER.md`

- [ ] **Step 1: Integrator:** run `caffeinate -d python3 -I tools/test.py`.
  - Expected: every test passes except the 4 light-cap checks.
  - On any other failure: diagnose with superpowers:systematic-debugging before touching code. Studio overload shows as "Target is not reachable", so re-run that group alone before calling it a bug.
- [ ] **Step 2: Final review.** Four adversarial lenses (server exploits incl. token and remote spam on Phone_Open/Phone_Choose/WalkIn_Deferred; economy and pacing; phone UI at both phone sizes; regressions in t40–t50). Each finding gets a second agent told to disprove it. Fix the survivors with regression tests.
- [ ] **Step 3: Close out.**
  1. Snapshot `v33_wave1a`; `python3 -I tools/export_rbxm.py`; checkpoint.
  2. Write the README section, the report (what's in, how sure, the pacing summary, Needs you: names and lines to approve, things to listen to = none, the 1b plan next) and the tracker updates. The report's calls for the user also note:
     - the cross-source cooldown (§4.1) covers artists only, from the moment a DM is sent; other visitors who walk in can also send phone items (the blogger's `trending`, the booker's `clip_context`) and are left out, which the user can widen
     - an artist who DMs can't DM again or walk in until 3 more walk-ins (one DM per artist in THE HALL or after the walk-in cap)
     - the sponsor quiz keeps the $300 "Sign it" bonus (§8.3), quoted in the rep's line rather than on the right answer
     - `mom_plaque` is a follow-up, so it skips mom's twice-a-week cap (CountCap is a no-op without `cap`), and "the day after your first HIT" (§4.3) is approximated as 1–2 walk-ins later, which can fall on the same UTC day
     - the phone icon sits beside the pills (§4.1, mockup boards 1 and 3) only where it clears FIRE's column; at 667 px, and on notched phones whose OK_UI is under about 712 px wide, it uses the top-right fallback
  3. Release the Studio lease.
- [ ] **Step 4: Commit** `T7: wave 1a done`, adding `WAVE1A_REPORT.md` to the Global commit paths for this commit only.

## Plan-check amendments (2026-10-27)

Folded from `.superpowers/sdd/2026-10-27-wave1a/plancheck_findings.md` (23 confirmed findings). Every change is written into the sections its implementers read (Global Constraints, Review Focus, Shared shapes, the task itself); this list is the index. Scope, the money guardrail targets, schema v4, the standing limits and the §10 exclusions are unchanged.

- **F1** → Global Constraints "Phone test isolation (Quiet)"; Shared shapes hook `Quiet`; Task 4's `send()` and remote handlers; t51, t51b, t52 and t53 wrap themselves in Quiet + Reset; t57a turns Quiet off; Task 6 Step 4 and the Wave F row run `t42 t43 t45 t47 t51 t52 t53 t54 t55 t56 t57 t58`.
  Ruling: a server-side Quiet in Phone memory (no `"pop"`/`"result"` sends, that client's Phone_Open/Phone_Choose dropped, `"expire"` always sent, never cleared by Reset) instead of a client Hold — the client never receives staged pops, so nothing stale is waiting when the hold lifts, and PhoneUI needs no test branch — if wrong (a file forgets Quiet), the live client opens its pops, and the widened Task 6 run shows it before Task 7.
- **F2** → Shared shapes redefines `"expire"` as "this token is gone on the server, opened or not". Task 4 "Drop paths": respawn, Phone Reset and the WalkIns Reset send an expire for every pending pop, with no PhoneExpire and no count; leave clears silently. An unknown token on Phone_Open gets an expire. New hook `Sent`. Task 6 handles expire and a stale Choose. t51b asserts the sends; t57b checks for carry-over; t58c–t58h test the client end to end.
  Ruling: respawn stays a drop path (the plan's and Review Focus 4's reading) rather than keeping pops across a respawn — it mirrors walk-ins, and one client handler serves every drop — if wrong, a respawning player loses at most 2 waiting pops, which were never counted.
- **F3** → merged with F7: the send gate is `today + unopened < DailyMax`, and t51 step 6 is rewritten so the waiting pop is never opened before the second Tick.
  Ruling: same defect as F7, same gate; its "Rules.Rollover at open" and the release-on-expiry step come from F7's verified fix — if wrong, see F7.
- **F4** → Task 6 `t57c` pops two DMs behind the beat maker and ages them in steps (Age 400, Pop B, Age 201) so only A expires; `t57d` asserts Pending 1, that only B opens, and Pending 0 after dismiss. PhoneUI's expire contract is in Task 6. Review Focus 1 and 2 cite t57e/f and t57c/d.
  Ruling: extend the existing t57c/t57d (the verifier's version) instead of the claim's new pair — `Age` takes no token, so ageing "one of them" needs the staggered ages; the expire send and the sweep under pause already exist — if wrong, little is lost: Age runs the sweep inline, so the staggered steps can't race, and the cost is two extra hook calls.
- **F5** → `PhoneResetSerial` is gone. Shared shapes and Task 4 add `WalkIns.OnReset(fn)`: the hook Reset calls every fn inline (pcall, passing `p`), Phone.Init registers its reset there, and WalkIns still never requires Phone. t51b asserts the reset with no wait; t57a uses WalkIns Reset with no yield before its Pops. The claim's alternative (bump plus a Phone Reset) is not used.
- **F6** → Task 5 `t56`: a real choice (not WALK AWAY) → gone within 5 s (2 s result delay + 1 s flight + slack), with "don't tighten it by cutting the flight".
- **F7** → Shared shapes "Phone rules" and Task 4: after `Rules.Rollover(st.phone, utcDay())`, send only while `st.phone.today + unopened < DailyMax` (a waiting pop holds its slot; an expired one gives it back). Phone_Open calls Rollover before `today += 1`. Hook Pop skips DailyMax but not MaxWaiting. t51 step 6 covers hold, release, open and the cap; step 7 covers midnight (new hook `SetDay`, and `State` to read the day). Task 2's runPhone uses the same gate.
  Ruling: no expire-at-open branch for `today >= DailyMax` (the claim's extra) — with the reservation and Rollover at open it can't trigger for scheduler pops, and it would silently drop forced hook Pops — if wrong, a path not yet seen could open a 7th pop in a day; no money is involved.
- **F8** → Task 1 adds `opts.exclude` (checked in `cardEligible`, so the pool, `first` and Seed honour it, and in `dueEntry`; absent = identical draws), with three spec cases. Task 4 excludes every pending id. At open a follow-up pop calls `TakeQueued` first, and nil drops it quietly (expire, PhoneExpire `taken`, nothing counted or applied). Task 2's runPhone takes it first too. New WalkIns hook `Plant(uid, id)`. t52 covers one follow-up → one pop and a forced second token → expire.
  Ruling: this is the cluster's decision for duplicates (F8, F20) — a pop is picked at send but counted at open, so the waiting pops' ids are excluded from the next Pick, and the queue entry is the single proof a follow-up may apply — the claim's "Phone.aura log count" assertion becomes "exactly one Phone-source career log entry" — if wrong, a second token for one follow-up could apply its news twice.
- **F9** → merged with F1. From its better fix: Phone `Age` moves `sentAt`/`openedAt` and runs that player's expiry sweep at once, so no test yields between Age and its asserts.
  Ruling: no `PhoneClientHold` attribute and no PhoneUI hold branch — Quiet on the server covers it without a replicated test flag — and Reset never clears Quiet, the bug the verifier found in this claim's fix — if wrong, see F1.
- **F10** → Config.Phone gains `OpenExpireSeconds = 300` (server only). Task 4: the phone timer also needs `PhoneBusy ~= true`; an opened DM unanswered that long closes as a dismiss (expire, stays counted, PhoneExpire `opened`, `PhoneBusy` recomputed); `openedAt` is stamped at open and shifted by Age; WalkIns `tick` returns early while `PhoneBusy`. Tests are t52 (opened DM expires, then Poke succeeds), t51 step 8 (no pop behind an open DM), and t58c/t58d on the client.
  Ruling: `Config.Phone.OpenExpireSeconds` rather than `Config.WalkIns.ExpireSeconds`, plus the `tick` skip the verifier recommended — the phone's own bound keeps the tables separate, and the skip stops a walk-in firing the moment a DM closes — if wrong, a slow reader loses an open DM after 5 minutes, or walk-in pacing shifts slightly while DMs are open.
- **F11** → merged with F2. Also from its better fix: Phone_Open's unknown-token expire reply, and the client chain (moved to t58e–t58h, after t58b, so no later file inherits a respawn).
  Ruling: F2's decision covers it; respawn is kept as a drop path, not the "simpler alternative" of keeping pops across a respawn, so Review Focus 4 and t51b keep their meaning, and the client chain uses no beat maker (DAWClient closes it on respawn) — if wrong, a respawning player loses up to 2 waiting pops, which were never counted.
- **F12** → Task 1 adds `Rules.MarkSent(state, item, deck)` (artist senders only, `max()`, so an outcome cooldown is never shortened). Data/WalkIns adds `W.Deck.visitors` (Task 1). Revalidate runs the full `cardEligible`, cooldown included. Task 4 calls MarkSent when a pop is sent; Task 2's runPhone calls it for each pop. Spec cases are in Task 1 and Task 2; t53 checks a DM followed by a walk-in, and a stored pick.
  Ruling: cooldown at send (not at open) and `lastWalkIn`/`LastVisitor` removed — a DM waiting unopened behind the beat maker is exactly when the same artist could otherwise walk in, and the existing count cooldown in `cardEligible` already blocks walk-in → DM because every caller passes `cooldown` — if wrong, an artist whose DM expired unread is still held off for 3 walk-ins (no stat or count is lost).
- **F13** → Task 5: `weird_pigeon` has `tag = "THE LOUNGE · COFFEE TABLE"` and `line = "coo."`, with no token and no RoomOf/`{where}`. t56 checks that the tag names the lounge.
  Ruling: the verifier's tag, not the claim's `A PIGEON · IN THE LOUNGE` — the data spec bans display names in all other text, and a tag that always names the lounge meets §4.3 without a room check — if wrong, a player standing in the lounge reads "THE LOUNGE" on a card about the table in front of him.
- **F14** → Task 3 states the quiz shape (rep, `when = "unsponsored"`, three sure choices; right answer sponsors +1, $300, aura +10; wrong answers `walked`, aura −10). The carve-out exempts `quiz_*` from the sure-payout quote rule, but the card's `line` must quote `F.Money(300)`. Data/WalkIns' header note records the exception. Task 7's report mentions it.
  Ruling: the bonus is quoted in the rep's line, not dropped from the text — §8.3 keeps "the same bonus as Sign it" and walk-ins §4.2 promises money is shown, without marking the right answer — if wrong, the quiz's $300 eats into the greedy share's 1.7 points; Task 3 says to report it if it binds.
- **F15** → merged with F21: the phone rules cover choice outcomes and a phone follow-up's `resolve.good`/`resolve.bad`, and Task 3 Step 2 says "Aura and Followers only".
  Ruling: placements must be 0, not "≤ 0" — §4.8 says Aura and Followers only — if wrong, a phone item could never take a placement, which no planned card does.
- **F16** → Task 3: `hacked` needs followers 2000. A news card whose copy names an audience size or a big reach gets a 2000 or 5000 follower gate, at least four news cards stay ungated, the writer records the gates, and pacing plus the +15 Aura check are re-run.
  Ruling: the writer picks the news gates by rule rather than the plan fixing ids — §4.3 says only "some gated by followers" — if wrong, a day-1 player can still see a mid-sized news card.
- **F17** → Task 2 Step 4: the expected line is random 0.391, greedy 0.483, chaser 0.408, spend-down 0.285, Hall 5/3/6, and the binding criterion is a one-time no-op-Seed run that reproduces today's line exactly. Task 2's :247 wording is fixed. Seed stays general.
  Ruling: no kept spec pinning today's numbers (the claim's second half) — career_sim_spec runs on fixtures, and Task 3 changes W.Deck — and only the expected values moved, not the guardrail targets — if wrong, an implementer could chase small decimal drift, but the differential run settles it.
- **F18** → Task 2: `phonePerDay` and `phoneSeed` are required (Run asserts them); career_sim_spec `input()` gets `phonePerDay = 0, phoneSeed = 42`; pacing_spec `run()` passes `phonePerDay = 6, phoneSeed = seed`; t46's Files become PACING + input + `run()`, with `phoneSeed = seed` passed in run; both print phone pops per day, and both assert > 0 once the deck has a phone card. The sim adds the +100003 offset.
  Ruling: assert, don't default nil to 0, and use a "> 0 when the deck has phone cards" guard (written in Task 2, so Task 3's files don't grow) instead of a 3..6 band — a silent default is exactly what let t46 run phoneless, and the band would be invented — if wrong, a pacing run that legitimately has 0 phone pops on some seeds would fail and need the guard loosened.
- **F19** → Task 2: the whole pop runs on `sim.phoneRng`, restored on every exit (Pick, the policy draw, Resolve, ResolveNews, Plant); the spec case is a counting spy on `input.rng` with a phone-only deck and `walkinsPerDay = 0`. Task 4 and Shared shapes: Phone owns its own Random and a SetRng list, never WalkIns'. t52's Aura case uses a sure, rare-free, cost-free choice or SetRng. Task 0: a news card carries no `rare`.
  Ruling: the counting-spy test, not the claim's "same walk-in pick sequence" test — phone effects change walk-in pools causally, so that test fails even when the fix is right — if wrong, the spy proves stream isolation but not that phone effects leave walk-ins alone, which they aren't meant to.
- **F20** → merged with F8 (exclude, TakeQueued first) and F7 (the reservation gate); t52 and t51 carry its tests.
  Ruling: no Revalidate, GateOk or CapOk re-check at Phone_Open or in the sweep — Phone_Open means the card is already on screen, so failing it there makes a visible card vanish; Revalidate would also reject an artist DM on the cooldown its own send set; and no 1a phone card carries a cap — if wrong, a waiting pop whose gate closed in its ≤ 10-minute wait (for example `trending` after `hacked` drained followers) still opens once.
- **F21** → Task 0 Step 1 and Shared shapes "Outcomes": every phone outcome (choice good/bad/rare and a follow-up's resolve) has money 0, placements/hits/sponsors 0, no `sponsor`, positive aura ≤ 60 and positive followers ≤ 2000, from a commented `PHONE_CAPS` table, with rule names after the source. Task 2's t46 asserts Config equals PHONE_CAPS and that Phone registers no other stat. Task 4 never applies outcome money (no AddCred, no TakeCred). Task 2's runPhone moves money only through costs. Task 3: Aura and Followers only, and `payback_*` stay walk-in.
  Ruling: the strict version (0, not ≤ 0) plus a Studio guard on the literals — §4.8 is "Aura and Followers only", and the spec can't load Config — if wrong, a later Config retune of the Phone caps fails t46 until PHONE_CAPS is updated, which is the intent.
- **F22** → Task 4's WalkIns bullets: nextPick does opts, Seed and Revalidate of the stored pick; onArrive calls `CountCap` next to seen/last. A `capKeys()` helper (day = `floor(_now()/86400)`, week = `day // 7`, never yyyymmdd) appears in Task 4 and in Shared shapes "Two day numbers" (the second check moved it to `Rules.CapKeys`, C5). New hook `Caps(uid)`. t53 covers an interrupted capped visit and checks that it counts once at arrival.
  Ruling: the verifier's version, with explicit keys and the hook — reusing `utcDay()` would make every CountCap reset `n` — if wrong (a cap should be spent at pick), an interrupted capped visit is delivered once more than intended; the sim counts at `arrive` the same way.
- **F23** → merged with F12: one shared rule (`MarkSent`) for the server and the sim, scoped to `kind == "artist"`, with its side effect stated in Task 1 and in Task 7's report.
  Ruling: no `CountPhone` helper, and `last` is set at send, not at the first open (F12 wins) — seen and caps stay two explicit calls listed once in Shared shapes "Phone rules", and the unopened window is the case §4.1 rules out — if wrong, the server and the sim could drift on seen/caps bookkeeping; the career_sim_spec and t53 cases cover the cooldown half.

**Second check (2026-10-27).** Two coverage gaps (F7 with F3, and F10) and 22 preflight conflicts (C1–C22 in `.superpowers/sdd/2026-10-27-wave1a/preflight_scan.md`), folded the same way. Scope, the guardrail targets, schema v4 and the §10 exclusions are unchanged.

- **F7/F3, F10, C9** → Task 4 Step 1: a clean start `fresh()` for every t51 step and every t51b, t52 and t53 case; each file teleports to the lounge first. The Global cleanup adds WalkIns `Reset`. Steps 2-4 Tick 200 s against step 1's control. Step 6 sends only by `Tick`. Step 7 starts at today 3 and asserts today 1 and today's day. Step 8 gains the Choose-0 → Tick → Poke control.
  Ruling: the clean start is WalkIns `Reset` plus the tour advance (t43b's `fresh()`), not Expire + `SetRemaining(nil)` — one existing synchronous call ends the walk-in, sets the timer to 1e6 and resets the phone through OnReset — if wrong (a case needed walk-in state an earlier one left), that case stages it itself; every case now does, because Reset also wipes count, last, seen, queue, phone and caps.
- **C1, C2** → sync lists: Task 2 Step 5 adds `Modules/WalkInRules` and `Data/WalkIns`; Task 4 Step 4 adds `Modules/WalkInRules`; Task 5 Step 4 adds `Data/WalkIns`.
- **C3** → Shared shapes and Task 1: `Revalidate(state, deck, opts, card)`; Task 4 passes `pick.kind == "card" and pick.item or nil`.
- **C4** → t53: the rookie gate, with a followers-999 control before the 1000 run.
- **C5** → `Rules.CapKeys` (Task 1). WalkIns exports `State`, `Filler`, `Chips` and `Names`, and Phone uses them. Global Saves names one accessor and marks `DataService.newWalkins` unchanged.
- **C6** → Task 2's `phoneAura` result key. pacing_spec and t46 print the random player's per-day mean and assert ≤ 15 once the deck has a phone card. Global gets its own "Phone Aura budget" bullet; Task 3 records the figure.
  Ruling: assert it in Task 2's spec code (guarded like the pops > 0 check), not only record it in Task 3, and measure the random player — Global already says the budget "stays", and the Hall targets it protects are measured on the random player — if wrong, Task 3 trims phone Aura the Hall targets would have allowed; other policies' phone Aura is not held.
- **C7, C8** → Shared shapes and Task 5: WalkIns hook `Sent(uid) -> { { kind, payload } }`, and `Age` moves the deferral and line clocks too (both Task 5). t54 reads the note through `Sent`. t55 ages 46 s twice and waits 5 s.
- **C10** → the `Format.Duration` example is `"59 seconds"`.
- **C11** → Shared shapes and Task 0 Step 3: `FunnelEvents(uid)` and `ResetFunnelEvents(uid)`; `fresh()` step 4 calls the reset.
- **C12** → Task 4: a NEWS open logs `CardNews` (source phone). Phone_Choose index 0 logs `CardWalkAway`, and `CardChoice` is only for index ≥ 1. t52 asserts all three.
- **C13** → Task 0: the append and print come before the guard, and only in Studio; `Funnel._customFields` builds the CustomField table.
  Ruling: t59 checks `_customFields(fields)` instead of an `_analytics` stub, and appends are Studio-only rather than a 500-entry ring — with the guard on `LogCustomEvent` only, a fake player never reaches a stub, and nothing on a live server reads `_events` — if wrong, the real `LogCustomEvent` call goes untested until the private publish, as it is today.
- **C14** → t57f ends by opening the beat maker; t58a Spawns behind it.
- **C15** → the Wave F row is corrected (nobody edits HUD). The icon sits beside the Career pills, with a top-right fallback, published as `IconSpot`. CypherUI's Bar, which already places itself right of Career (CypherUI.lua:94-118), starts after the icon, and WalkInUI's IS WAITING chip counts the icon. t57b checks both spots against the card's full overlap list. Task 7 reports the fallback.
  Ruling: beside the pills with a fallback, not either branch alone — the design (§4.1) and mockup boards 1 and 3 put it beside the pills, so the "user call" branch's condition fails; but the pills stack under 780 px and must clear FIRE's column (HUD.lua:66), so a 44 px icon there fits only from about 712 px — if wrong, the user wants one fixed spot, which is one layout branch in PhoneUI plus the matching `IconSpot` branch in CypherUI.
- **C16** → Task 2: `aired = sim.economy.firePerDay > 0`, and the pickNext case includes `aired`.
- **C17** → Task 4 pins the `mom_plaque` plant at `{1, 2}` with `rngFor(uid)`. Task 7 reports the cap exemption and the visit-count approximation.
- **C18** → Task 0: a `first` rule, and WaitLines/NoteLines text rules. Task 3: the 180/21K gate-pools case. t51: step 9 (Tick 89 → none, then 61 → one) and step 10 (a cypher lobby, with a control). t54: the count rises once.
- **C19** → Shared shapes: a phone follow-up's pop always shows app `"NEWS"`.
- **C20** → t52: Phone `SetRng(uid, {1})`, one award per positive stat, and the log unchanged on the second token.
- **C21** → Task 0 is the only owner of KINDS and SIGS (named) and adds "a sender uses sig none". Task 3's Files list the conditional name carve-out and the pools case.
- **C22** → the Global commit adds `research README.md`.
  Ruling: `WAVE1A_REPORT.md` goes only into Task 7's commit, not the shared list — `git add` with a path that doesn't exist fails, so every commit before Task 7 would fail — if wrong, nothing is lost: the report exists only from Task 7 on.

## Wave E lens review amendments (2026-10-27)

Three lenses (server exploits, economy, regressions) over Task 4 (43cbbfd..74981e3); every finding handed to a skeptic. Four survived, all minor; two were refuted. Fixes run as Task E (`.superpowers/sdd/2026-10-27-wave1a/task-E-brief.md`) before Task 5.

- **E1** → Task 4 Phone_Open: a second DM cannot be opened while one is held (`PhoneBusy`); it stays un-opened and uncounted and opens once the first resolves or expires. t52 gains "one open DM at a time".
  Ruling: refuse at open rather than bound total busy time — it matches WalkIns' one-card-at-a-time rule and Task 6's client, which never opens a second card — if wrong, a client that opened two DMs at once (none planned) sees the second refuse until the first closes.
- **E2** → Task 4 WalkIns `tick`: while `PhoneBusy`, a timer that already sits at 0 (it ran out behind a cypher lobby or the daily cap) is re-armed with a fresh Gap, so a DM close never lands on a stale 0. t52 gains "DM holds a run-out timer".
  Ruling: re-arm in `tick`, not a cypher-phase listener — one line in the path F10 already owns — if wrong, a walk-in after a DM that closed over a run-out timer waits one extra Gap (120–180 s).
- **E3** → Global Constraints and Shared shapes: `Config.Career.Sources.Phone` dailyMax 6 → 7 for aura and followers (max unchanged). A pop is counted at open but awarded at Choose, and a DM that straddles UTC midnight is counted on the old day and awarded on the new, so the new day's 6th award was refused while its result card promised the gain. t52 gains "seven awards in a day".
  Ruling: one slot of headroom in Config instead of a gate bypass keyed by the open day — no API change, t46 and PHONE_CAPS pin only `max` — if wrong, the phone can award 7 × 10 Aura instead of 6 on a day (the sim has no per-source daily cap; measured phone Aura is +11/day).
- **E4** (recorded, no code): MarkSent's cross-source artist cooldown holds for cards only; a queued story follow-up (navx_single after navx_placement) still walks in when due even inside the cooldown after a dm_navx, as it already did after a walk-in. Task 7's report states this under Review Focus 6.
  Ruling: a story coming back when due is the design's intent; the cooldown stops repeats, not sequels — if wrong, the fix is phone-side (an artist with a queued walk-in follow-up doesn't DM) plus one spec case and one t53 case.
- Refuted: "a throwing WalkIns Reset leaves Quiet on for the session" (the plan's Global isolation rule has Task 6's t57a turn Quiet off explicitly); "Phone's 1 s loop spams [OK][ERR] if WalkIns failed to start" (WalkIns' ctx is set on the first line of Init, before anything can throw).


## Final review amendments (2026-10-28)

Nine findings survived their skeptics in the whole-branch final review (`ready: Yes`); eight are fixed as Task G (`.superpowers/sdd/2026-10-27-wave1a/task-G-brief.md`), the ninth (the icon re-shaking every 4 s) is parked with the other 1b items.

- **G1** (S4, important) → `Modules/FireButton`: FIRE's `Top` also sits 8 px under the phone icon while `OK_Phone.IconSpot == "corner"` and the icon is visible, in the same `math.max(60, …)` as the cypher bar; SAMPLE IT follows `Top + 64` as before. t57b's forced 667 case asserts FIRE's absolute top ≥ the icon's bottom + 8 with the bar shown and hidden (FIRE has no show seam: `Top` is read while hidden). Ruling: FIRE moves, not the icon.
- **G2** (S5) → `PhoneUI.cardTop` reads `OK_UI.Career` as `placeIcon` does: when the pills stack and reach the card's column the base is their bottom + 8 (74 on phones); side by side it stays 58, so t57b's real-viewport `y0 == 58` holds. t57b's two forced cases assert the card overlaps neither pill and still fits with 44 px buttons.
- **G3** (S6) → `WalkInUI.placeChip` shifts, then only if needed narrows, the chip so it ends 8 px left of a shown `OK_Phone.Card`. t57f step 1 asserts it at the real viewport and with OK_Phone, OK_UI and OK_WalkIn forced to 667×375 minus the real inset.
- **G4** (S1) → `PhoneUI.choose` returns early for a NEWS (`if cur.news then return end`). Pinned in t57b (a client file cannot Pop and t57a cannot pop a third under MaxWaiting, so t57d could not host it): the beat maker opens before OK closes the DM, the NEWS waits behind it, the icon opens it and a same-frame dismiss leaves `LastChoose` "" with the result on screen until the NewsCloseSeconds auto-close; the file still ends with the beat maker open for t57c.
- **G5** (S7) → `WalkInUI` Command `"open"` latches `forced` only when no phone card shows. t57f: a chip tap during the DM leaves Open false / Deferred true; the DM dismissed behind the beat maker leaves the walk-in card deferred; closing the beat maker opens it by itself. Task 6's "armed at once" note (task-6-report.md:72) becomes "armed as a self-opened card" (the Command seam acts at once by design, so the arm itself is pinned through the deferral, not a refused `choose:1`).
- **G6** (S2) → t46's PHONE_CAPS loop asserts `rule.dailyMax == Config.Phone.DailyMax + 1` (E3 message); t52's "seven awards" loops `Config.Phone.DailyMax + 1` and asserts the gain, the awards, `today` and CardChoice against that count. No Config value changed.
- **G7** (S3 + S8) → (a) the `Config.Phone` comment records what `Enabled = false` does (icon hidden, phone-only follow-ups not planted, the pacing sim still assumes DailyMax); (b) `WalkIns.apply` skips `Rules.Plant` for a follow-up whose deck entry has `source == "phone"` while `Config.Phone.Enabled == false`; (c) `PhoneUI.Build` returns before building any gui when the phone or the walk-ins are off (Phone.lua:39's rule). Ruling: guard the plant, not `state()`; verification is luau-compile plus the suite with `Enabled` true (the switch cannot be flipped from the suite).
- **G8** (S9) → `Visitor.SpawnSpot` keeps a set of taken slot indices, takes the lowest free one and `_gone` frees it (the offset formula is unchanged on that index). t42's spot case: the first leaves while the second stands and the third lands on the freed slot, 1.5 studs from the second.
