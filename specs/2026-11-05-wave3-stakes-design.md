# Wave 3 "Stakes": design

November 5, 2026. Written from the user's approval of ten design critiques the same evening ("I love these so do what u gotta do to make em happen") and three calls made by AskUserQuestion (cold streak: earn it back; arcs: all six; beat quality: stars as the base, FIRE as a bonus). Systems facts come from the read-only audit `research/wave3/systems_2026-11-05.md`. A builder check (fresh reviewer, 11-05) found seven gaps and six contradictions with the code; this revision settles all of them (§9 lists what changed). Wave 2's conventions hold: no new parts, lights or sounds; licensed audio only; no OK branding; the walk-in copy stays on the user's approval list.

## 1. Intent

Prod Life III has a beat maker and a career, and today they run side by side. You make a beat, then a visitor rolls dice that never look at the beat. Nothing can go badly in a way you remember, and most visitors are one-off cards. Wave 3 makes the game remember you in three ways: **your beat is what gets placed**, **a bad run has a shape you climb out of**, and **six people remember what you did to them**. Two small pieces come with it: the first card arrives before the first beat, and the game explains its own words once.

The promise this wave keeps: *things happen to a person, not to a number.*

## 2. Goals, non-goals, anti-goals

**Goals**
- A placement choice refers to your best recent beat, and that beat's quality moves the roll.
- A cold streak that is visible, earned, and escaped only by making something people hear.
- Six visitor arcs (A RIVAL PRODUCER, YOUR MOM, A KID FROM BACK HOME, LIL NAV X, your sponsor's rep, THE TEA BLOGGER) whose later cards depend on your earlier choices.
- A new player's first walk-in card on screen within about 35 seconds of first spawning.
- A one-line explainer the first time a card shows each of eight words.

**Non-goals (later waves)**: reach out from the phone, A/B patterns, money sinks and rent, the producer card and co-produce, seasons. No new tabs or panels. No change to the beat format. No phone follow-up gains choices in this wave.

**Anti-goals (a failure even if it works)**
- A regular player going cold in their first career week.
- The money pacing floor moving: the random player's card share on the 200 recorded seeds stays ≥ 0.3412 (`spec/pacing_spec.lua`), THE HALL's median day stays 4–6 with p90 ≤ 7, Legend never before day 15.
- A new player who never delivered seeing a text that reads as broken ("the one at nil").
- Arcs that feel like fetch quests: every arc card is playable as a stand-alone card for someone who never saw the earlier ones (its gate just keeps it from arriving).

## 3. Constraints

- Save format stays v5. Every new field is a sub-field of a table a system already defaults lazily in its own `state()` (`prof.sessions`, `prof.walkins`, `prof.career`), plus one new small top-level table `prof.hints` added by a repair line in `DataService.migrate` (no bump). `ClientProfile` keeps `prof.hints` out of the client copy, like `life`.
- `Config.Life` numbers and any copy are mirrored in `spec/economy_fixture.lua` (t46 pins it) and scanned by t40.
- `CareerSim` models every change that moves money, placements or odds, using the same pure functions the game uses; `pacing_spec` and `t46` keep their floors.
- The only clock cards have is the walk-in visit count (plants, cooldowns, queue). Durations in this wave are counted in visits; no new timers.
- Studio hooks only in Studio; nothing here changes DataService's save paths.
- Never flip `Config.Data.UseStoreInStudio`; never touch the light cap.

## 4. The pieces

### 4.1 Your beat feeds the cards

**"Your beat" is what you delivered or played on the monitors**, not what you saved. Deliver sends the live grid and never saves (`DAWClient`), and each delivery must differ from the last by 8 pads (`Contracts`, `Check.MinChanged`), so save slots don't track the beats players actually use.

**Recent beats.** `prof.sessions.recent`, lazily defaulted by Contracts' `state()`: newest first, at most 3 entries `{ pattern = <128 chars>, bpm, stars = 0..3, fires = n, day = careerDay }`.
- `Contracts.Deliver` (on a passed delivery, first or repeat, any brief including dailies and the weekly): if an entry with the same `pattern` exists, `stars = max(stars, new)` and move it to the front; else push `{ pattern, bpm, stars, fires = 0, day }` and drop the oldest past 3.
- `Reactions.Give` (a FIRE to the producer): find the producer's entry whose `pattern` equals the airing's pattern (`Monitor.history`/`NowPlaying` carries it); if none (a beat aired without delivering), push `{ pattern, bpm, stars = 0, fires = 0, day }` first. Then `fires += 1`. Credited only when the producer is online, as FIRE already is.

**Quality.** `WalkInRules.BeatQuality(entry) -> 0..4` = `stars + (fires >= 3 and 1 or 0)`; no entry = 0. **Best beat** = the entry with the highest quality, ties to the newest. The FIRE bonus is one step only, so the sim's 4 FIRE a day can't run it away.

**Tilt.** Choices marked `beat = true` add `WalkInRules.BeatTilt(q) = (q - Config.WalkIns.Odds.beatCenter) * Config.WalkIns.Odds.beatPer` to the base chance before the Aura and Followers tilt, inside the same `min..max` clamp. Starting values `beatCenter = 3`, `beatPer = 4`: no beat −12, 2★ −4, 3★ 0, 3★ with 3+ FIRE +4. The builder tunes both (center 2..3, per 3..6) so the existing sim personas average a tilt near zero and every floor holds; the change reads as a penalty for not delivering plus a small bonus for FIRE.

**Which choices.** The flag is on the choice, not the card, and only on walk-in card choices whose `good` outcome pays a placement. From the data today (10 cards): `navx_placement` choice 1; the eight `*_pitch` cards' placement choice (dojabat, icespike, charti, scoot, llama, drift, drizzle, eyelash); `rival_beat` "Split the cost of a beat with him." Follow-ups (news rolled on arrival) and cards that pay hits are untouched, which protects the Legend floor and the follow-up line handling. New arc cards that pay a placement get the flag too (§4.3).

**Templating.** `WalkInRules.Fill` gains a `beat` argument: `{beat}` → `"the one at " .. bpm` when the best beat exists, else `"something"`. `WalkIns.filler` passes the best entry's bpm or nil. The 10 cards' `line` (or the flagged choice's `text`, where the line has no natural slot) gains a `{beat}`; `walkins_data_spec` checks every card with a `beat = true` choice has `{beat}` in its line or that choice's text. Phone cards never use it; Fill substitutes "something" when the argument is nil, so no `{beat}` ever shows raw.

**Payload.** The walk-in card payload gains `beat = { stars, fires, bpm } | false` when any choice is flagged; `CardFeel.Footer` adds a second line: "Your best beat: ★★★ · 🔥 4" or "No beat delivered yet. Your odds are lower."

### 4.2 The cold streak

**Rule.** `prof.career.cold = { since = careerDay, reason = "aura" | "quiet", news = bool } | nil`, plus `prof.career.rearm = bool` and `prof.sessions.lastDay` (career day of the last passed delivery of any brief, written by `Contracts.Deliver`; defaulted to the current career day when first read, so nobody arrives cold).
- **Enter** when `aura < -50` (reason "aura", only if not `rearm`), or `careerDay - lastDay >= 3` (reason "quiet"). Checked after any Aura change and at the career-day step. Career days count days played, so not logging in never makes you cold.
- **Exit ("earn it back")**: a FIRE on a beat you put on the monitors (`Reactions.Give` to you), or a 3-star delivery of any brief (`Contracts.Delivered`, stars ≥ 3, first or repeat). Nothing else ends it.
- **Re-arm**: on exit `lastDay = exit day`; if the reason was "aura", `rearm = true` until Aura has been ≥ −25 once.
- Pure rule `CareerRules.ColdStep(state, aura, careerDay, lastDay, event) -> state', changed`, used by `Career` and `CareerSim` alike.

**While cold.**
- Walk-ins: `DailyMax` 2 (`Rules.CanSchedule` takes the max from `WalkIns.DailyMaxFor(p)`); bursts never start.
- Phone: no pops (`Phone.canSend` false). One NEWS card, `cold_news` ("STUDIO · QUIET", "your phone hasn't buzzed in days. make something people hear.", `sure`, no deltas), sent through a dedicated `Phone.SendSystem(p, id)` path once per streak (`cold.news` marks it), after the tour, counted in that day's phone total, never refused for having been seen before.
- HUD: a grey "COLD" chip in the BUSY DAY chip's place (same component, `Theme.muted`; the two can't show together because bursts don't start while cold), driven by the player attribute `Cold`. Nothing on the nameplate.
- Story: new kinds `cold` ("DAY n · Nobody was calling.") and `thaw` ("DAY n · You got people talking again."), every streak logged; no firsts, titles or ribbons.
- Banner on exit: "YOU'RE BACK · people are calling again" through the existing `LifeBanner` path. No banner on entry (the NEWS card is the moment).

**Pacing.** A new sim persona, `neglect` (plays and airs beats but never delivers after day 1, receives no FIRE), must go cold on day 4 and thaw on its first 3-star delivery when the script lets it deliver again. `random`, `greedy`, `chaser` and `spendDown` never go cold in days 1–7 on the 200 seeds; `climber` and `homer` pins unchanged.

### 4.3 They remember you: relationship memory and six arcs

**Mechanism.** `prof.walkins.rel[visitorId] = { score = -3..3, flags = { [flag] = careerDay } }`, lazily defaulted.
- Outcomes gain `rel = { who = "<visitorId>", score = ±n, flag = "<name>", clear = "<name>" }`. `who` is explicit (it defaults to the card's own visitor), so a card from one sender can move another person's memory: `two_sessions` (visitor `bookings`) writes to `homekid`. `WalkIns.apply` and `Phone.apply` write it; NEWS resolutions write it too.
- Card and follow-up gates gain `needs.flags = { "who.flag", ... }` (all present), `under.flags = { ... }` (none present), and `needs.rel` / `under.rel` on the card's own visitor's score. `Rules.GateOk` reads them; an unknown flag means never eligible, as today. The sponsor arc also uses the existing `when = "sponsored"`.
- Chance: the card's visitor score tilts every rolled choice on that card by `score * Config.WalkIns.Odds.relPer` (`relPer = 4`, so −12..+12), inside the clamp, after the beat tilt.
- Durations are visits: "stops coming" is a flag that gates the visitor's cards (`under.flags`), and a follow-up planted N visits out clears it. Due follow-ups skip caps, so caps are never used for this.
- `WalkIns.Reset` clears `rel`. Signing a new sponsor resets `rel.rep` (a new deal is a new relationship).

**The arcs.** Each extends cards that exist today. Copy for new cards is drafted by the builder in `research/wave3/copy_2026-11-xx.md` for the user's approval, as in Wave 2.

| Visitor | Triggers on existing cards | New cards (gate → what happens) |
|---|---|---|
| A RIVAL PRODUCER | `rival_beat`: "Respect. Dap him up" → flag `respect`, +1; "Post a side-by-side" → flag `posted`, −1; "Split the cost" → +1. `rival_steal` foiled → −1. | `rival_collab` (needs rival.respect, rel ≥ 1; a two-name beat: placement, `beat = true`) · `rival_war` (needs rival.posted; his diss track: a choice to answer it wins with a 3★ best beat, else −30 Aura) · `rival_truce` (follow-up to `rival_war` at {3,5}; score ±1 by your choice, clears `posted`) |
| YOUR MOM | `mom_food`: "Eat with her" → flag `fed`, +1; "Eat at the desk" → −1. `mom_busy`: "Promise to call more" → +1; "Tell her you're slammed" → −1. | `mom_aunt` (needs rel ≥ 2; she brings the aunt: +15 Aura, +300 followers) · `mom_quiet` (needs rel ≤ −2; she stops coming: sets `quiet`, every mom card gains `under.flags = mom.quiet`, plants `mom_return` at {6,9}) · `mom_return` (follow-up; "call her back" clears `quiet`, +1, +10 Aura) |
| A KID FROM BACK HOME | `two_sessions` (writes `who = homekid`): hometown → +1; one-hit wonder → flag `passed`. `payback_homekid` HE BLEW UP → flag `blew_up`. | `homekid_show` (needs homekid.blew_up; his first show: on stage +800 followers, or stay home −1) · `homekid_album` (needs homekid.blew_up, rel ≥ 2; "I want you on the album": placement, disco TRACK ONE, `beat = true`) · `homekid_forgot` (needs homekid.passed, followers ≥ 5,000; he's famous and you had no time: −20 Aura, clears `passed`) |
| LIL NAV X | `navx_placement`: "Give him the beat for free" → +1; "Post that he's in your studio" → −1. `navx_album` hit → flag `album_hit`. | `navx_tour` (needs navx.album_hit; tour DJ: +$600, +1,500 followers, or pass) · `navx_tv` (needs rel ≥ 2; a shout-out on late-night: +2,000 followers, +20 Aura) · `navx_replaced` (needs rel ≤ −1, placements ≥ 2; he works with a bigger producer now: −10 Aura, cooldown 6) |
| Your sponsor's rep (`rep`, whichever deal you hold) | Signing (any `rep_*` signed outcome) resets `rel.rep` to 0. | `sponsor_duty` (`when = "sponsored"`; shoot the ad: +$400, +1; refuse: −1) · `sponsor_renew` (`when = "sponsored"`, rel ≥ 2; the bigger deal: +$800, +20 Aura) · `sponsor_warning` (system-planted instead of `sponsor_drop` when Aura falls under the floor and rel ≥ 1: "fix it"; plants `sponsor_drop` at {2,3}, which drops you only if Aura is still under the floor when it arrives) |
| THE TEA BLOGGER | `blogger_interview`: "Tell every studio story" → +1; "Keep it short" → −1. `ghost_out` and `rumour` (her cards) write to her as their outcomes say. | `blogger_exclusive` (needs rel ≥ 1; she kills the rumour or runs the cover early: +15 Aura) · `blogger_expose` (needs rel ≤ −1; the hit piece: −25 Aura, or +200 followers if your Aura ≥ 300) |

Eighteen new cards. Every one is also a plain card. Two pay a placement (`rival_collab`, `homekid_album`) and carry `beat = true`; both are gated behind flags a regular player reaches around day 5–8, and the builder confirms THE HALL's day with the sim. `mishap_owe` stays a phone NEWS follow-up with no choices and no relationship write.

### 4.4 The first card

- `Config.WalkIns.FirstEver = { 15, 20 }`: when `prof.walkins.count == 0`, the first timer uses it instead of `FirstDelay`, and the tour gate is not required for that one visit. Every later visit keeps today's rules.
- The first pick stays `gentle_first` (the superfan; no `{beat}`).
- Acceptance: on a fresh profile, the card is on screen within about 35 seconds of first spawning (timer, walk from the spawn pad, and the server-wide walking cap).
- The walk-in UI already defers behind the beat maker and cutaways: a player who sat at the PC in the first seconds sees the IS WAITING chip and the card when they close it.
- The phone's first pop still waits for the tour.

### 4.5 Explainers

- `Config.Hints`: eight entries `{ term, text }`, one line ≤ 70 characters: `aura` "AURA · your reputation. It tilts the odds and can go negative.", `followers` "FOLLOWERS · your audience. They set your fame tier.", `placement` "PLACEMENT · your beat on an artist's record.", `hit` "HIT · a placement that charts. Rare, and it pays.", `sponsor` "SPONSOR · a brand deal. Keep your Aura over their bar.", `flip` "FLIP · someone's beat, 8 or more pads changed, aired again.", `cypher` "CYPHER · two or more producers, one brief. Two go head-to-head; three or more vote.", `fire` "FIRE · the room liked your beat. Money and followers." (final copy on the approval list).
- `prof.hints = { [term] = careerDay }`, top-level, added by a repair line in `migrate`, stripped from `ClientProfile`.
- Server side, deterministic: when a walk-in or phone card payload is built, the server scans the card's visible text (tag, line, choice texts) for each unseen term (whole word, case-insensitive) and attaches the first as `hint = { term, text }`, marking it seen on send. One hint per card. Result payloads do the same for outcome headline and text.
- The card UI shows it as a muted third footer line with a small "i". Nothing to tap.
- A Studio hook `ResetHints(uid)`.

## 5. Decided (the user's calls)

- Cold streak: **earn it back**. Ends on FIRE from a beat on the monitors or a 3-star delivery; never on its own.
- Arcs: **all six** visitors above.
- Beat quality: **stars as the base, FIRE as a bonus**.
- The ten critiques are the direction; Waves 4 and 5 hold the rest.

## 6. Claude's calls (switchable, listed so they can be rejected)

- **"Your beat" means what you delivered or played on the monitors, not what you saved** (deliver never saves, so saved slots don't track real play).
- The FIRE bonus is one quality step, and the tilt is centered so today's players average about zero: it punishes not delivering more than it rewards anything.
- The beat tilt is on placement choices of walk-in cards only, never on follow-up news or hits.
- Relationship writes name their target (`two_sessions` writes to the kid); the sponsor arc follows whichever deal you hold and resets on a new signing.
- Durations count walk-in visits; "stops coming" is a flag that a later follow-up clears.
- `prof.hints` and every other new field need no schema bump.
- The cold chip is private (no nameplate change); `cold_news` comes once per streak.
- The relationship score is clamped to ±3 and tilts by 4 per point.
- Eighteen new cards, not more.

## 7. Left to the builder

- Exact `beatCenter`, `beatPer` and `relPer` after the sim, within the floors.
- Copy for the 18 cards, `cold_news`, the two story lines, the exit banner and the eight hints, drafted for approval.
- The sim's beat model (recent beats from its own deliveries and FIRE through `BeatQuality`) and the `neglect` persona.
- Tests: `walkin_rules_spec` (BeatQuality, BeatTilt, rel gates and tilt, Fill `{beat}`), `career_rules_spec` (ColdStep), `life_rules_spec` (two kinds), `walkins_data_spec` (every `beat = true` choice's card carries `{beat}`; every `needs.flags` names a flag some outcome sets; every `rel.who` is a visitor), `pacing_spec` (floors, `neglect`), and Edit/Play checks for the recent-beats record, the first-ever timer, the hint payload, the cold chip, `cold_news` and the exit banner.

## 8. Order

4.4 and 4.5 first (small, independent). Then 4.1 (recent beats, quality, tilt, templating). Then 4.2 (it reads 4.1's FIRE crediting). Then 4.3 (memory, then the six arcs as content). Pacing floors run after 4.1, 4.2 and 4.3 each.

## 9. What the builder check changed (11-05)

- "Your beat" moved from saved slots to delivered or aired beats (`prof.sessions.recent`); deliver never saves, and slot fields would not default lazily.
- The beat tilt is per choice on 10 walk-in cards (counted from the data), not on follow-ups or hit-paying cards; the FIRE bonus is capped at one step and the tilt is centered.
- `rel` names its target; `two_sessions` writes to the kid; the `mishap_owe` and "dismiss twice" triggers were dropped (neither exists); `ghost_out` writes to the blogger.
- The sponsor arc follows whichever deal you hold (one `rep` visitor serves every sponsor; gates can't test a sponsor id).
- Day durations became visit counts with flags; `navx_tour` lost its "away" effect.
- `cold_news` arrives through its own send path once per streak.
- "Within 20 seconds" became "the card on screen within about 35 seconds".
- The cypher explainer says two or more; the card count is 18.
