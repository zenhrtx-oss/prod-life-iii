# Wave 1b engine probes (2026-10-28)

This is Task 0 Step 2 of `plans/2026-10-28-wave1b-feel.md`. Tasks 4 and 5 rely on these results.

## How it ran

- **Studio:** one instance, "ok studio beta" (placeId 139218961436722). Its live id was `bd927f71-3e95-4b1a-98b7-759733a81405`, not the `1685c642…` last seen. `tools/mcp_call.py` switched to it on its own.
- **Guard:** `GUARD OK PlaceId=139218961436722 streaming=false`. `WalkInsPaused` was nil before the run.
- **Test hold:** `WalkInsPaused` was set true in Edit before Play. The client read it as `true` during Play.
- **Code:** probes ran through the Studio MCP `execute_luau` tool, with `datamodel_type` Edit, Client or Server. This is what `tools/test.py` does with `--luau`, `--luauc` and `--luaus`.
- **Session:** one Play session for P1–P4. The account was zenspot003, standing on the spawn at (6, 3.1, 5).
- **Finish:**
  - Play was stopped and Studio was back in Edit.
  - `python3 -I tools/mcp_call.py --luau tools/walkins_pause_off.lua` printed `WALKINS UNPAUSED`.
  - Nothing was saved, published, uploaded or inserted.
- **Scripts:** nothing went into `build/` or `src/`.
  - P5's script and the search helper are in the session scratchpad (`wave1b-t0/`).
  - The P1–P4 code was passed inline to `execute_luau`. What each probe ran is described below.
- **Console:** the only lines were the known "not authorized to access Asset" lines that `tools/test.py` treats as benign. No probe wrote an error.

## Results at a glance

| Probe | Result | For Task 5 |
|---|---|---|
| P1 rig | R15 | Both halves are testable on this avatar |
| P2 cheer | **FAIL** | `Humanoid:PlayEmote("cheer")` throws. The cheer half becomes `skip:off` (see the diagnostic) |
| P3 sit | PASS | The loss sit stays |
| P4 client death | PASS | t64g can kill on the client. The fallback is not needed |
| P5 spawns | PASS | The one spawn is inside the hub |

## P1 (Play, client): RigType

**What ran:** wait for Character, Humanoid and HumanoidRootPart, then read `Humanoid.RigType`.

**Raw output:**
```
P1 RigType=Enum.HumanoidRigType.R15 | waited=3.0s | hasAnimator=true | AnimateScript=LocalScript | UpperTorso=true Torso=false | Health=100 | pos=6, 3.0963194370269775, 5 | WalkInsPaused=true
```

**Result:** PASS. The rig is R15.

**For Task 5:**
- This is the test account's avatar. Other players can be R6, so `skip:r6` is still needed.
- On this avatar every play test reaches the cheer and sit code, not `skip:r6`.

## P2 (Play, client): `hum:PlayEmote("cheer")` while standing still

**What ran:**
1. Wait until `MoveDirection` is zero and `FloorMaterial` is not Air.
2. List the playing tracks.
3. Call `hum:PlayEmote("cheer")` inside a pcall.
4. List the tracks every 0.1 s for 0.5 s.

**Raw output:**
```
P2 returned=No emote exists with name cheer grewWithin0.5s=true
gate: MoveDirection=0, 0, 0 FloorMaterial=Enum.Material.Concrete State=Enum.HumanoidStateType.Running Sit=false after 0.00s
before #2: Animation1=http://www.roblox.com/asset/?id=507766388, Animation1=rbxassetid://114302219876492
PlayEmote("cheer") pcall=false return=No emote exists with name cheer (call took 0.001s)
t+0.11s #2: Animation1=http://www.roblox.com/asset/?id=507766388, Animation1=rbxassetid://114302219876492
t+0.23s #3: Animation1=http://www.roblox.com/asset/?id=507766388, Animation1=rbxassetid://114302219876492, Animation2=http://www.roblox.com/asset/?id=507766666
t+0.33s #3: Animation1=http://www.roblox.com/asset/?id=507766388, Animation1=rbxassetid://114302219876492, Animation2=http://www.roblox.com/asset/?id=507766666
t+0.45s #2: Animation1=rbxassetid://114302219876492, Animation2=http://www.roblox.com/asset/?id=507766666
t+0.56s #2: Animation1=rbxassetid://114302219876492, Animation2=http://www.roblox.com/asset/?id=507766666
settle after 0.0s #2: Animation1=rbxassetid://114302219876492, Animation2=http://www.roblox.com/asset/?id=507766666
HumanoidDescription emotes: true
```

**Result:** FAIL.
- `PlayEmote` did not return true. It threw "No emote exists with name cheer".
- The track count did go from 2 to 3. The new track was the Animate script's second idle animation (507766666, under `Animate.idle`), not a cheer. The `grewWithin0.5s=true` flag is a false positive.
- The last line of the raw output is a probe bug: it printed only pcall's first value. The diagnostic below reads the emote list properly.

**Diagnostic (not part of the pass rule):**

What ran: read the applied HumanoidDescription's emotes, list the Animate script's children, then call `Animate.PlayEmote:Invoke("cheer")`. That BindableFunction is the path the `/e cheer` chat command uses.

```
P2-diag
AppliedDescription emotes (4): Hello, Point2, Shrug, Stadium
equipped (4): 1:Hello, 2:Stadium, 3:Point2, 4:Shrug
Animate children: cheer(StringValue), climb(StringValue), dance(StringValue), dance2(StringValue), dance3(StringValue), fall(StringValue), idle(StringValue), jump(StringValue), laugh(StringValue), point(StringValue), sit(StringValue), toollunge(StringValue), toolnone(StringValue), toolslash(StringValue), wave(StringValue), ScaleDampeningPercent(NumberValue), run(StringValue), swim(StringValue), swimidle(StringValue), walk(StringValue), PlayEmote(BindableFunction), mood(StringValue)
playing: Animation1 id=rbxassetid://114302219876492 parent=Workspace.zenspot003.Animate.mood prio=Enum.AnimationPriority.Idle looped=false
playing: Animation1 id=http://www.roblox.com/asset/?id=507766388 parent=Workspace.zenspot003.Animate.idle prio=Enum.AnimationPriority.Core looped=true
Animate.PlayEmote:Invoke("cheer") pcall=true return=true before#=2
  t+0.11s #3: Animation1=rbxassetid://114302219876492, Animation1=http://www.roblox.com/asset/?id=507766388, CheerAnim=http://www.roblox.com/asset/?id=507770677
  t+0.23s #2: Animation1=rbxassetid://114302219876492, CheerAnim=http://www.roblox.com/asset/?id=507770677
  t+0.33s #2: Animation1=rbxassetid://114302219876492, CheerAnim=http://www.roblox.com/asset/?id=507770677
  t+0.43s #2: Animation1=rbxassetid://114302219876492, CheerAnim=http://www.roblox.com/asset/?id=507770677
  t+0.55s #2: Animation1=rbxassetid://114302219876492, CheerAnim=http://www.roblox.com/asset/?id=507770677
```

What this shows:
- `Humanoid:PlayEmote(name)` looks only at the applied HumanoidDescription's emotes. This avatar has Hello, Stadium, Point2 and Shrug, and no "cheer". Other avatars will differ.
- `Animate.PlayEmote:Invoke("cheer")` returned true, and `CheerAnim` (507770677) was playing at +0.11 s.
- Once the cheer started, the track count stayed at 2, because the idle track stopped. "The track count grows" is therefore not a reliable test signal. The track name `CheerAnim` or the id 507770677 is.

**For Task 5:**
- By the brief's rule, P2 failed, so the cheer half becomes `skip:off`, and the report says so.
- `Animate.PlayEmote:Invoke("cheer")` works on this R15 avatar. Using it would be a change to the plan's ruling ("Win: `Humanoid:PlayEmote("cheer")` on R15"). The orchestrator or the user decides. This probe does not.
- If any code ever calls `Humanoid:PlayEmote`, it must use a pcall. It throws; it does not return false. The plan's "`PlayEmote` returned false" case would never be reached.

## P3 (Play, client, then server): Sit with no seat

**What ran:** three separate calls.
1. Client: stand-still gate, then `hum.Sit = true`. Sample `GetState()` every 0.05 s for about 0.6 s and log StateChanged. The call returns with the humanoid still sitting.
2. Server: read the same player's Humanoid `Sit`, `GetState()` and `SeatPart`.
3. Client: `hum.Sit = false`. Sample `GetState()` every 0.05 s for about 1.2 s and log StateChanged.

**Raw output, step 1 (client):**
```
P3a seatedWithin0.5s=true (first Seated at 0.06s)
pre: State=Enum.HumanoidStateType.Running Sit=false SeatPart=nil FloorMaterial=Enum.Material.Concrete
t+0.06s State=Enum.HumanoidStateType.Seated Sit=true
t+0.11s State=Enum.HumanoidStateType.Seated Sit=true
t+0.18s State=Enum.HumanoidStateType.Seated Sit=true
t+0.25s State=Enum.HumanoidStateType.Seated Sit=true
t+0.30s State=Enum.HumanoidStateType.Seated Sit=true
t+0.36s State=Enum.HumanoidStateType.Seated Sit=true
t+0.41s State=Enum.HumanoidStateType.Seated Sit=true
t+0.48s State=Enum.HumanoidStateType.Seated Sit=true
t+0.54s State=Enum.HumanoidStateType.Seated Sit=true
t+0.60s State=Enum.HumanoidStateType.Seated Sit=true
StateChanged: 0.015s Enum.HumanoidStateType.Running->Enum.HumanoidStateType.Seated
```

**Raw output, step 2 (server):**
```
P3b server: player=zenspot003 players=1 Sit=true GetState=Enum.HumanoidStateType.Seated SeatPart=nil
```

**Raw output, step 3 (client):**
```
P3c standingWithin0.5s=true (first Running/Landed at 0.06s)
pre: State=Enum.HumanoidStateType.Seated Sit=true
t+0.06s State=Enum.HumanoidStateType.Running Sit=false FloorMaterial=Enum.Material.Concrete
t+0.13s State=Enum.HumanoidStateType.Running Sit=false FloorMaterial=Enum.Material.Concrete
t+0.20s State=Enum.HumanoidStateType.Running Sit=false FloorMaterial=Enum.Material.Concrete
t+0.26s State=Enum.HumanoidStateType.Running Sit=false FloorMaterial=Enum.Material.Concrete
t+0.33s State=Enum.HumanoidStateType.Running Sit=false FloorMaterial=Enum.Material.Concrete
t+0.38s State=Enum.HumanoidStateType.Running Sit=false FloorMaterial=Enum.Material.Concrete
t+0.43s State=Enum.HumanoidStateType.Running Sit=false FloorMaterial=Enum.Material.Concrete
t+0.48s State=Enum.HumanoidStateType.Running Sit=false FloorMaterial=Enum.Material.Concrete
t+0.55s State=Enum.HumanoidStateType.Running Sit=false FloorMaterial=Enum.Material.Concrete
t+0.60s State=Enum.HumanoidStateType.Running Sit=false FloorMaterial=Enum.Material.Concrete
t+0.66s State=Enum.HumanoidStateType.Running Sit=false FloorMaterial=Enum.Material.Concrete
t+0.71s State=Enum.HumanoidStateType.Running Sit=false FloorMaterial=Enum.Material.Concrete
t+0.78s State=Enum.HumanoidStateType.Running Sit=false FloorMaterial=Enum.Material.Concrete
t+0.85s State=Enum.HumanoidStateType.Running Sit=false FloorMaterial=Enum.Material.Concrete
t+0.91s State=Enum.HumanoidStateType.Running Sit=false FloorMaterial=Enum.Material.Concrete
t+0.96s State=Enum.HumanoidStateType.Running Sit=false FloorMaterial=Enum.Material.Concrete
t+1.03s State=Enum.HumanoidStateType.Running Sit=false FloorMaterial=Enum.Material.Concrete
t+1.08s State=Enum.HumanoidStateType.Running Sit=false FloorMaterial=Enum.Material.Concrete
t+1.15s State=Enum.HumanoidStateType.Running Sit=false FloorMaterial=Enum.Material.Concrete
t+1.21s State=Enum.HumanoidStateType.Running Sit=false FloorMaterial=Enum.Material.Concrete
```

**Result:** PASS on all four checks.
- The humanoid was Seated at 0.06 s; StateChanged fired at 0.015 s.
- The server saw `Sit=true` and Seated, with `SeatPart=nil`.
- After `Sit = false`, it was Running at 0.06 s.

**For Task 5:**
- The loss half (`Sit = true` for 2 s on the client, with no seat) works.
- `Sit` set on the client replicates to the server, so P4's fallback (a server one-shot listener on `Sit`) would also work.
- The release went straight from Seated to Running, with no GettingUp state, and `FloorMaterial` stayed Concrete. A reaction that runs right after a sit release would not hit `skip:moving` on flat floor.
- This was on the flat spawn floor. A sit on stairs or a slope was not probed.

## P4 (Play, client): `ChangeState(Dead)` on the client

**What ran:**
1. Server: read `Players.RespawnTime` and `Players.CharacterAutoLoads`.
2. Client: connect `Died` and `CharacterAdded` first, then call `hum:ChangeState(Enum.HumanoidStateType.Dead)`. Wait up to `RespawnTime + 2 + 3` s and timestamp both events.

**Raw output, server:**
```
P4pre server: RespawnTime=5 CharacterAutoLoads=true Health=100 BreakJointsOnDeath=false RequiresNeck=true
```

**Raw output, client:**
```
P4 killed=true respawnedWithinLimit=true
pre: client RespawnTime=5 char=zenspot003 Health=100 State=Enum.HumanoidStateType.Running
ChangeState(Dead) pcall=true 
t+0.32s Health=0 State=Enum.HumanoidStateType.Dead
StateChanged: 0.019s Enum.HumanoidStateType.Running->Enum.HumanoidStateType.Dead
Died fired at 0.02s; CharacterAdded at 6.01s (limit 7.0s); newChar~=old=true; old.Parent=nil
after: char=zenspot003 Health=100 State=Enum.HumanoidStateType.Running pos=6, 3.0963194370269775, 5
```

**Result:** PASS.
- The character died (Health 0, `Died` fired at 0.02 s).
- A new character was added at 6.01 s. The limit was 7.0 s.
- The new character spawned on the hub spawn.

**For Task 5:**
- `t64g` can kill the character from the client. The fallback (a server one-shot listener on `Sit` that calls `p:LoadCharacter()`) is not needed.
- The respawn took 6.01 s against a 7.0 s limit, so there is about 1 s of slack. A test that waits for the new character should allow `RespawnTime + 2`, not less.

## P5 (Edit): every SpawnLocation is inside `WalkInRules.InHub`

**What ran:**
1. A fresh require of `RS.OK.Modules.WalkInRules`, using t14's clone pattern.
2. For every `SpawnLocation` under Workspace, check six points with `InHub`: the centre, the standing point (top + 3) and the four top corners (+3).

**Raw output:**
```
P5 spawns=1 notAllInHub=0
Workspace.SpawnLocation Enabled=true Size=(6.0,1.0,6.0) Neutral=true | center=(6.0,0.5,5.0) InHub=true stand=(6.0,4.0,5.0) InHub=true corner1=(9.0,4.0,2.0) InHub=true corner2=(3.0,4.0,2.0) InHub=true corner3=(9.0,4.0,8.0) InHub=true corner4=(3.0,4.0,8.0) InHub=true
```

**Result:** PASS. There is one SpawnLocation, at (6, 0.5, 5). It lies inside the corridor box (x 0..12, z 0..10) at every point checked.

**For Task 5 and the heal (Task 3):**
- A joining or respawning player starts in the hub.
- The heal's "first 5 s of hub presence" therefore also covers joining, as the ruling assumed.
- P4's new character appeared on this spawn.
