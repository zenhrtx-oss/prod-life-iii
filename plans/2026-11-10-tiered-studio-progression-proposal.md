# Proposal: bedroom → studio → legendary rooms, as a tiered personal space

**Status:** proposal, not yet built. Written up after a chat session exploring reference games and platform choice; saved here so it isn't lost and so the next session (or you) can react to it before any code changes.

**Correction (2026-11-10, via the session holding the build):** this proposal was written against stale facts — it's now 201/201 tests at the Task 4 checkpoint, not 186/190, and the save-safety prerequisite below is already done, not pending: DataService v3 ships a session lock, generation counter, writer token and single-flight loads, and a real-store trial passed on 2026-11-05 (a leave save loaded correctly in a second and third session). See the "Frameworks worth evaluating" and "How to actually build this" sections below for what that changes. Separately, as of today the room concept moved onto the pre-launch list rather than waiting for a post-launch update — see `OK_GAME_TRACKER.md`.

## The idea, in one paragraph

Every player starts in a bare, personal space — a bedroom, not a finished studio. Through career choices (the existing Walk-ins/Phone career loop), they earn money and Aura, and spend it to **decorate and upgrade** that space: better gear, then a real studio, then eventually THE HALL and THE WEST SUITE. The space is **personal and persistent** (saved per player) but **not solitary** — other players can walk into it when they're online, same as the shared studio today. This is not a single-player-vs-multiplayer tradeoff; it's the standard Roblox tycoon/house model (Bloxburg, Adopt Me): your own growing space, inside a shared world.

## Why this doesn't require a rebuild

`SPEC.md` (v1, 2026-10-22) already states the goal: *"every system is modular so a DAW, tycoon progression, customizable studios... can be added without rebuilding."* That promise mostly held — `ReplicatedStorage.OK.Systems` already has `Tycoon.lua`, `Unlocks.lua`, `Career.lua`, `WalkIns.lua`, `Life.lua`, `Gear.lua`, `Stations.lua`, and THE HALL / THE WEST SUITE are already gated by Aura + money + a placement (`18_gates.lua`). The tiered-room ladder this proposes is an **extension of a pattern that's already half-built**, not a new idea for the codebase.

The one genuinely new system is **player-placed decoration** — today's studio is hand-built and fixed (`SPEC.md`: "non-goals: customizable studios"). That's the real net-new piece, not the tiering.

**Recommendation: do not rebuild. Extend.** A rebuild risks the 186/190 passing test suite and the multiple approved milestones for no reason — the architecture was built to take this.

## Reference games, and specifically what to take from each

| Game | What to study | Where it plugs into Prod Life III |
|---|---|---|
| **Bloxburg / Adopt Me** (Roblox) | The exact pattern proposed here: a personal plot/house that grows through earned currency, inside a shared server. Proof this works at Roblox's scale and on mobile. | The tier ladder itself (bedroom → house studio → HALL → WEST SUITE) and the "others can visit" model. |
| **Any Roblox tycoon** | Plot-unlock-by-currency as a UI/data pattern — dropper-style progress bars, buy buttons, instant visual payoff per purchase. | The *moment* of upgrading a room — make each tier change feel immediate, not just a stat flip. |
| **The Sims 4 (build mode)** | Grid/snap placement, rotate, catalog-by-category, cost-per-item, room-value scoring. | The actual decoration system: furniture catalog, placement rules, part-budget-aware item costs (ties to the existing 6,000-part / 24-light budget in `SPEC.md`). |
| **Crusader Kings 3 (events)** | Weighted event pool, conditions, options, effects, chaining — already the shape of `WalkIns.lua`/`Phone.lua`. | New tier-specific unlock events (a producer offers to co-sign your upgrade; a rival visits your new room) using the exact pattern already in the career system. |
| **RimWorld (needs/mood)** | An aggregate score built from weighted need-deficits, not a single flat number. | Optional depth for the 6 career stats or Aura: instead of one flat value, model it as a few weighted inputs, the way RimWorld's mood is built from need gaps. Not required for v1 of this proposal — a "could deepen later" item. |
| **BitLife** (already fully mapped in `bitlife-recon/REPORT.md`) | Weighted-pool event picker, 2-year repeat cooldown, per-life caps. | Already adopted in `WalkIns`/`Career`; reuse directly for tier-unlock events rather than inventing a new picker. |

## Frameworks worth evaluating (Roblox ecosystem, not game-design patterns)

Two separate categories — don't conflate them:

1. **Save-data safety — already done, not a blocker.** ~~The tracker flags DataStore as untested on real storage~~ — that was true when this was written; it no longer is. DataService v3 ships exactly the session-locked pattern this point used to recommend (a session lock, generation counter, writer token, single-flight loads, release-on-leave), and a real-store trial passed 2026-11-05: a leave save wrote a v5 profile, a second session loaded it under a new lock, and a third session saw the change. This proposal still **increases what's saved per player** (room tier, every placed item's position/rotation), so re-verify the real-store trial once decoration ships — but there's no save-layer prerequisite left to build first.
2. **Server/client code organization — optional, lower priority.** The project already has a working `Services/`+`Systems/` split with a `SystemLoader`. A formal framework like **Knit** is the common alternative in larger Roblox codebases, but adopting it mid-project *is* a mini-rebuild of working code for an organizational preference, not a capability you're missing. **Not recommended now** — the existing pattern is already doing the job; revisit only if the codebase outgrows it.
3. **State replication for "others see your decorated room."** If visitors need to see your furniture placement live, that's a replication problem (a pattern like **ReplicaService** solves this cleanly). Worth a short investigation when decoration is actually being built, not before.

## How to actually build this (staged, not a rebuild)

1. ~~Harden saves first~~ — already done (DataService v3, session-locked; real-store trial passed 2026-11-05). Re-run the real-store trial once decoration adds to what's saved, but it's no longer a gate on starting.
2. **Data model**: add a `StudioTier` field and a `PlacedItems` list to the existing player profile shape — additive, not a schema rewrite.
3. **New systems, following the existing `Systems/*` convention**: `Systems/StudioTiers.lua` (the ladder + gate logic, extending `Unlocks.lua`/`Tycoon.lua` rather than replacing them) and `Systems/Decoration.lua` (catalog, placement, cost) — net new, but additive.
4. **Bedroom shell**: one small, cheap room (fits easily in the existing part budget), built the same way the current studio was (`build/*.lua`, re-runnable, versioned into `OK_Versions`).
5. **Rewire the existing gates**: THE HALL / WEST SUITE already sit behind Aura+money+placement — slot them in as the top tiers of the same ladder instead of a separate gate system.
6. **Playtest before adding the next tier.** Same discipline as every milestone so far — this is exactly the project's own stated risk ("nobody has played it yet"); don't stack a bigger system on an unplayed one.

## Also flagged while writing this

`ROADMAP.md` (last touched 2026-10-22) is **stale** relative to `OK_GAME_TRACKER.md` (2026-11-06) — it still describes a 4-room, no-saving, no-career-system state that's 13 milestones out of date, and explicitly lists "City, tycoon, custom studios" under **Not now**. Worth either deleting it or rewriting it to point at the tracker, so a future session doesn't read it and think tiered progression was already ruled out.
