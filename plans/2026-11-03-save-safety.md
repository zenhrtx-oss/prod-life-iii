# Save safety: plan

November 3, 2026. The user's pick for the next build ("Save fixes", 11-03): fix the two rare save-loss cases older than Wave 2, found by the Wave 2 final review's save lens (findings 3 and 5), and get ready for one real save and load. Small enough to need no design document: this plan records the calls, and the build ledger (`plans/2026-11-03-save-safety-ledger.md`; the workspace with the review is archived in `checkpoints/sdd-2026-11-03-save-safety.tar.gz`) records the run.

## The two problems

1. **A change during a save's wait loses its dirty flag** (`Services/DataService.lua`, Save).
   - `clean()` copies only the top level. Money and XP are frozen when the save starts, while `career`, `walkins` and `life` stay live until the store runs the save.
   - After the write, Save clears `dirty` whatever happened in the meantime. A change made while the store was busy then waits for the 180 s heartbeat.
   - Effect: only a hard crash in that window loses anything. The stored document can also mix moments: a visit gone from the queue, but its Money missing.
2. **A stale server can overwrite a newer save** (Save's UpdateAsync callback).
   - Save refuses only a foreign lock. A server S whose save sat in the store's queue while server T took the profile over and released it finds no lock, so it writes S's older progress over T's.
   - Load's `_newerSchema` flag doesn't help, because S loaded before T existed.

## Rulings

- **One generation per player.** Every write that marks a profile dirty goes through one helper, `touch(p)`, which also bumps `gen[uid]`: Load, MarkDirty, applyXP, applyCred, SpendCred and TakeCred. Save reads the generation before it copies the profile and clears `dirty` only if nothing moved. `forget` and `_SetStoreForTest` clear `gen`.
  - Cost if wrong: one missed site keeps the old behaviour at that site. The build greps that no raw `dirty[...] = p` write is left.
- **A deep copy, so a save is one moment.** `clean()` copies the whole profile, so a change during the wait is in neither the stored document nor lost. The generation guarantees the next autosave writes it.
  - Cost: one table walk per save, at most about 30 KB, every 120 s per player.
- **A writer token.** Each load makes a GUID and writes it as `writer` in the stored document at the lock claim, a forced takeover included. Save puts it on every write, release included; release clears only the lock.
  - The save callback refuses, treating it as a lost lock, when any of these is true: the lock is foreign; the stored `writer` is present and isn't ours; or the stored `v` is newer than ours.
  - A stored document with no `writer` is accepted. The game has never been published, so no older server exists to carry tokens forward wrongly.
  - The token stays out of the profile, the way `lock` does, so it never reaches the client.
- **The real-save trial switch isn't in Config.** Flipping `Config.Data.UseStoreInStudio` would make the test suite's hooks (Followers set to 100,000, Life resets) write the real store. Instead:
  - an Edit-time attribute, `ReplicatedStorage.OK.RealSaveTrial`, names a separate trial store (`ProdLife_trial_v1`), so `OKStudio_v1` stays clean
  - `tools/real_save_on.lua` and `tools/real_save_off.lua` set and clear it
  - `tools/guard.lua` refuses test runs and syncs while it's set
  - `tools/real_save_check.lua` reads the stored document with GetAsync (read only) and reports `v`, the lock, the writer, visits, Money, XP, the life rings and the JSON size
  - only a Studio session reads the attribute; a live server ignores it

## Tests

- **`build/t74_check.lua`, a new Edit file.** Its fake store round-trips JSON like a real DataStore, so the profile and the "store" never share tables. It also has an optional hook that runs before the transform, standing in for the store's wait.
- **Cases:**
  - a grant during the wait keeps `dirty`, and `_Autosave()` then writes it
  - a nested change plus a Money change during the wait leaves the first stored document consistent, with neither change in it
  - S and T: T takes over, plays and releases, then S's queued save is refused, T's values are kept and S gets `_lockLost`
  - a stored `v` of 6 makes a save refuse
  - leaving and reloading on the same server saves with a new token
  - a document with no token saves, and then carries ours
  - the token appears neither in the profile nor in ClientProfile
- **Order:** t74 red on the old code, sync, green. Then `--edit t13 t41 t60 t69 t70`, then the full suite, because every reward path marks profiles dirty.

## The real save and load (after the user turns on API access)

1. The user: Game Settings > Security > Enable Studio Access to API Services.
2. `real_save_on`. Play: the check shows the trial document with our lock and writer. Make a few changes through the test hooks; it's the trial store, so nothing real is touched. Stop.
3. In Edit, the check shows the lock released and the changes stored.
4. Play again: `visits` is one higher and the life is unchanged. Stop.
5. `real_save_off`.
