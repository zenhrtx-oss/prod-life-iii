# Wave 1b sound shortlist (2026-10-28)

## Verified picks (copy into Config.SFX)

| Key | id | name | creator | creator id | length s | suggested volume |
|---|---|---|---|---|---|---|
| CardOpen | rbxassetid://9125805579 | Rising Whoosh Hissing Build Up Ascending Swo (SFX) | ProSoundEffects | 7462895450 | 1.141 | 0.3 |
| Win | rbxassetid://9126071452 | Synth Sparkle Tone High Pitch Bell Tone Burs (SFX) | ProSoundEffects | 7462895450 | 0.872 | 0.3 |
| Loss | rbxassetid://9120885415 | Wood Hit Giant Wood Beam Dull Thuds Knocks 5 (SFX) | ProSoundEffects | 7462895450 | 0.518 | 0.45 |
| Money | rbxassetid://9113848780 | Coins Drop Wood Table Hits Brass Gear 1 (SFX) | ProSoundEffects | 7462895450 | 0.887 | 0.4 |
| Plant | rbxassetid://9120131970 | Tone Clusters Classic Synth Switch Tones 18 (SFX) | ProSoundEffects | 7462895450 | 0.451 | 0.35 |
| PhoneBuzz | rbxassetid://9119715399 | Switch Blurt Single Short Synth Buzzes 6 (SFX) | ProSoundEffects | 7462895450 | 0.470 | 0.4 |

This is Task 0 Step 3 of `plans/2026-10-28-wave1b-feel.md`. Task 3 copies the table above into `Config.SFX` as `{ id = "rbxassetid://N", volume = V }`. Every sound is **pending your listen**.

**Verified keys (6):** CardOpen, Win, Loss, Money, Plant, PhoneBuzz. The t11 pin becomes 11 + 6 = 17.

Each pick passed both gates:
- **Creator:** `MarketplaceService:GetProductInfo(id, Enum.InfoType.Asset).Creator.CreatorTargetId` is 7462895450 (ProSoundEffects). This is t14's call, run in Edit.
- **Length:** the `TimeLength` measured on the Play client is within the key's limit.

Each id was returned by a search in this session. None is from memory. Every name above is the GetProductInfo `Name`, which Roblox cuts to 50 characters.

Two picks are stand-ins:
- **Money is a coin clink, not a register ching.** The only two cash register sounds are 1.717 s and 2.112 s, both over the 1.5 s limit, and both are drawer sounds. `Config.SFX` has no trim field, so neither can be used.
- **PhoneBuzz is a short, low synth buzz, not a recorded phone vibration.** No licensed recording of a phone vibrating came in under 1 s.

If you would rather have silence than either stand-in, leave that key out of Config. CardFeel then plays nothing for it, and the t11 pin drops by one.

Volumes: the riser and the ding play on every card, so they start low at 0.3. The other four start at 0.35–0.45.

## Alternates

Each alternate passed the same two gates.

| Key | id | name | length s | why it is second |
|---|---|---|---|---|
| CardOpen | rbxassetid://9118193186 | Rizzy Synth Swells Various Pitches 6 (SFX) | 0.977 | A synth swell, more UI than riser. Shorter, so it may be the subtler one |
| Win | rbxassetid://9126076118 | Synth Sparkle Tone High Pitch Tone Burst Din (SFX) | 0.744 | Same family as the pick, shorter |
| Loss | rbxassetid://9126267413 | Wood Hit Giant Wood Beam Dull Thuds Knocks 1 (SFX) | 0.626 | Same family as the pick, a slightly longer tail |
| Money | rbxassetid://9117244563 | Pay Phone Dropping Dimes Into Coin Slot 6 (SFX) | 0.626 | Coins rattling into a slot. Brighter and busier than the pick |
| Plant | rbxassetid://9126114231 | Tone Clusters Bursts Of High Pitch Beeps Ui  (SFX) | 0.355 | A burst of beeps rather than one tone |
| PhoneBuzz | rbxassetid://9114646693 | Graphic Buzzes Short Fuzzy Bursts Ui 8 (SFX) | 0.453 | A fuzzier UI buzz. Also a stand-in |

All alternates are ProSoundEffects (7462895450).

## Search log

### Method

1. **Search:** the Studio MCP `search_asset` tool, with `scope = "creator_store"`, `assetType = "Audio"` and `maxResults = 20`. It ran through `tools/mcp_call.py` one call at a time. There were 124 queries. The raw results are in the session scratchpad (`wave1b-t0/search_raw.jsonl`).
2. **First filter:** a result whose `creatorName` was not APMOfficial or ProSoundEffects was dropped there.
3. **Creator check:** every candidate kept was checked with GetProductInfo in Edit. All 55 returned AssetTypeId 3 (Audio) and creator id 7462895450.
4. **Control:** three dropped results were also checked with GetProductInfo, to confirm the creator gate rejects them:
   - 118533595987397 "ES_Riser_Reverse_-_SFX_Producer": wuboyone, cid 1551548122 → REJECT
   - 15674975792 "Roblox_UI_Whoosh_03": Roblox, cid 1 → REJECT
   - 137298617974043 "SS_wobbleboxx_rewards_Rise03_bcebae29": RBLXEssentials, cid 10485748272 → REJECT
5. **Length:** measured on the Play client.
   - Each candidate became a `Sound` under SoundService (Volume 0, never played), loaded with `ContentProvider:PreloadAsync`, then its `TimeLength` and `IsLoaded` were read.
   - All 55 loaded with `AssetFetchStatus.Success`.
   - The folder was destroyed after each batch. Play data is never saved.
6. **APMOfficial:** nothing from APM passed. Its results were kicks, drones, swells and music stings, mostly listed at 1–2 s or more, and none fit a key better than the PSE sounds.

Notes on the search tool:
- **Duration in the description is rounded.** PSE gives one decimal, APM whole seconds. The measured length decides. For example, 9126073064 is listed at 1.1 s and measured 1.120 s.
- **`audioMaxDuration` is loose.** A whole-number cap still returned longer sounds; with a cap of 2, results of 2.5 s came back. A decimal cap (1.6) returned no results at all.

### CardOpen (soft riser, ≤ 1.5 s)

Terms: riser, whoosh, swell, rise, reverse cymbal, whoosh rise, ProSoundEffects whoosh, build up, ascending, rising whoosh, synth swell, riser short. A 1.6 s cap on six of these returned nothing, so they were rerun with a 2 s cap.

| id | name | length s | verdict |
|---|---|---|---|
| 9125805579 | Rising Whoosh Hissing Build Up Ascending Swo (SFX) | 1.141 | **pick**: a plain rising whoosh, "sharp and airy" |
| 9118193186 | Rizzy Synth Swells Various Pitches 6 (SFX) | 0.977 | **alternate** |
| 9125806031 | Rising Whoosh Hissing Build Up Ascending Swo (SFX) | 1.408 | passes; a longer take of the pick |
| 9125805759 | Rising Whoosh Hissing Build Up Ascending Swo (SFX) | 1.472 | passes, but sits right at the limit |
| 9125807267 | Rising Whoosh Hissing Suck Burst Swooshing I (SFX) | 1.312 | passes; a "suck burst" ending, less soft |
| 9125807311 | Rising Whoosh Hissing Suck Burst Swooshing I (SFX) | 1.195 | passes; same reason |
| 9126089635 | Synth Zip Short High Pitch Ascending Bursts  (SFX) | 0.794 | passes; "zip, spin" may read as cartoonish |
| 9126086053 | Synth Tone Multi Pitch Short Waa Tone Swell  (SFX) | 0.321 | passes; too short to read as a riser |
| 9126085511 | Synth Tone High Pitch Short Waa Tone Swell U (SFX) | 0.354 | passes; same reason |
| 9125527144 | Electro Bubbles Synthy Spins Ascending Tones (SFX) | 1.088 | passes; "bubbles, squeaks", cartoonish |

Rejected from the search metadata, not measured:
- Over the limit: 9125805781 and the other long "Rising Whoosh" takes (1.6–2.1 s), "Wind Suck Backwards" (2.1+ s), "Whooshy Magic Sucks" (2.3+ s), "Shaft Of Light" (2.2+ s), "Rumble Deep Whomping Swells" (1.7+ s).
- Wrong character: "Spirit Pass Bys" (vocal whooshes), "Electric Car Pass By", "Time Warp … Explosion", the APM kicks and drones, and "Synth Roar Growly".

### Win (bright ding, ≤ 1 s)

Terms: ding, bell, chime, success, UI positive, notification chime, bell tone ding, UI ding, ping, glass ding, positive tone UI, synth tone UI, sparkle tone, glockenspiel, triangle hit, bell hit, marimba, pluck. Six of these returned no licensed result.

| id | name | length s | verdict |
|---|---|---|---|
| 9126071452 | Synth Sparkle Tone High Pitch Bell Tone Burs (SFX) | 0.872 | **pick**: "bell tone burst, ding" |
| 9126076118 | Synth Sparkle Tone High Pitch Tone Burst Din (SFX) | 0.744 | **alternate** |
| 9126074189 | Synth Sparkle Tone High Pitch Tone Burst Din (SFX) | 0.875 | passes |
| 9126073953 | Synth Sparkle Tone High Pitch Tone Burst Din (SFX) | 0.686 | passes ("glassy") |
| 9126073644 | Synth Sparkle Tone High Pitch Tone Burst Din (SFX) | 0.686 | passes ("glassy") |
| 9126076030 | Synth Sparkle Tone High Pitch Tone Burst Pin (SFX) | 0.878 | passes ("ping") |
| 9119834079 | Synth Sparkle Tone High Pitch Tone Burst 10 (SFX) | 0.694 | passes |
| 9119834248 | Synth Sparkle Tone High Pitch Tone Burst 4 (SFX) | 0.686 | passes |
| 9126073064 | Synth Sparkle Tone High Pitch Bell Tone Ding (SFX) | 1.120 | **rejected: over 1 s** |

Rejected from the search metadata, not measured:
- Over the limit: "Magic Glows … Chiming Hits" (2.1+ s), "Large Metal Triangle" (1.7+ s), "Tuning Fork 5" (1.3 s), and the "Bell Tone Ding" takes listed at 1.2–2.3 s.
- Wrong character: "Glass Smashes", "Metal Impacts", "Ping Pong Ball", "Violin String Pluck" and "Mouth Drips … Pluck".

### Loss (dull thud, ≤ 1 s)

Terms: thud, low hit, soft impact, dull thud, bass thump, muffled hit, low boom short, tonal thud, synth thud, low synth hit, sub drop, kick drum, door thud, low impacts deep hits, deep hit, cardboard thud, pillow hit.

| id | name | length s | verdict |
|---|---|---|---|
| 9120885415 | Wood Hit Giant Wood Beam Dull Thuds Knocks 5 (SFX) | 0.518 | **pick**: the shortest "dull thud" |
| 9126267413 | Wood Hit Giant Wood Beam Dull Thuds Knocks 1 (SFX) | 0.626 | **alternate** |
| 9120885656 | Wood Hit Giant Wood Beam Dull Thuds Knocks 9 (SFX) | 0.605 | passes |
| 9120885138 | Wood Hit Giant Wood Beam Dull Thuds Knocks 2 (SFX) | 0.689 | passes |
| 9126267607 | Wood Hit Giant Wood Beam Dull Thuds Knocks 1 (SFX) | 0.733 | passes |
| 9126267639 | Wood Hit Giant Wood Beam Dull Thuds Knocks 1 (SFX) | 0.764 | passes |
| 9120885006 | Wood Hit Giant Wood Beam Dull Thuds Knocks 1 (SFX) | 0.787 | passes |
| 9126267420 | Wood Hit Giant Wood Beam Dull Thuds Knocks 1 (SFX) | 0.795 | passes |
| 9113437465 | Big Thuds Wall Impact 1 (SFX) | 0.934 | passes; longer, close to the limit |

Rejected from the search metadata, not measured:
- Over the limit, or wrong character: "Body Impact" (car interior, 1.5+ s), "Massive Footstep Impact" (1.4+ s), "Explosions", "Statue Put Down" and "Snow Impact".
- Too physical: "Body Hit" and "Body Kicks" read as violence.
- Not a thud: "Towel Cracks" (slaps) and "Drips Pillow Hits Wet".
- No licensed synth or tonal thud under 1 s turned up.

### Money (cash-register ching, ≤ 1.5 s)

Terms: cash register, register ching, coin, ka-ching, coins drop, cash drawer, cash register (no cap), cash register bell, register, money, coins jingle, coin hit, coin clink, slot machine, service bell, counter bell, coins handful, coins counting, quarters, metallic clink, coin slot, cha-ching, cash, coins, ching, coin flip, coin single, coin toss, coins drop wood table. Searches for ching, ka-ching, cha-ching, register ching, cash, coin, coins, money and cash drawer returned no licensed sound that fits.

| id | name | length s | verdict |
|---|---|---|---|
| 9113848780 | Coins Drop Wood Table Hits Brass Gear 1 (SFX) | 0.887 | **pick (stand-in)**: a coin clink on wood |
| 9117244563 | Pay Phone Dropping Dimes Into Coin Slot 6 (SFX) | 0.626 | **alternate (stand-in)** |
| 9125444951 | Coins Drop 3 Inch Medallions Metal Hits To W (SFX) | 1.112 | passes; a heavier medallion hit |
| 9117245599 | Pay Phone Dropping Nickels Into Coin Slot 4 (SFX) | 1.364 | passes; longer |
| 9113850466 | Coin Toss Large Metal Flipped 4 (SFX) | 1.152 | passes; "dropped to grass", so a dull landing |
| 9113728049 | Cash Register 2 (SFX) | 1.717 | **rejected: over 1.5 s**; also a drawer, not a ching |
| 9113728042 | Cash Register 1 (SFX) | 2.112 | **rejected: over 1.5 s**; same |
| 9119221922 | Slot Machine 4 (SFX) | 0.920 | **rejected: a casino sound**, wrong for a studio |
| 9113848518 | Coin Large Metal Toss Dropped To Grass 1 (SFX) | 0.867 | **rejected: "Distant Traffic"** in the background |

Rejected from the search metadata, not measured:
- Wrong character: the other "Slot Machine" takes (jackpot music), "Blacksmith Anvil", "Alarm Buzzer", "Coins Or Keys Jingle" (2.0+ s), "Coin Throws" (2.0+ s) and "Drop Bronze Gear Giant Coin" (1.4–3.4 s, a heavy hit).

### Plant (short blip, ≤ 0.5 s)

Terms: blip, beep, pop, UI click, short beep, synth blip, notification, computer beep, keyboard beep, soft beep tones, tone clusters, bubble pop, synth pop, high pitch tone burst.

| id | name | length s | verdict |
|---|---|---|---|
| 9120131970 | Tone Clusters Classic Synth Switch Tones 18 (SFX) | 0.451 | **pick**: a short classic-synth UI tone |
| 9126114231 | Tone Clusters Bursts Of High Pitch Beeps Ui  (SFX) | 0.355 | **alternate** |
| 9120138888 | Tone Clusters Classic Synth Switch Tones 25 (SFX) | 0.462 | passes; a sibling of the pick |
| 9126131392 | Tone Clusters Raspy High Pitch Tones And Bee (SFX) | 0.419 | passes; "raspy" |
| 9125933460 | Sharp Beeps High Pitch Descending Short Burs (SFX) | 0.359 | passes; it falls in pitch, which may read as a loss |
| 9120150200 | Tone Clusters Mostly High Pitch Tones 16 (SFX) | 0.345 | passes; "blurp, squelch" |
| 9113462855 | Blitz Riffs Electronic Computer Tones 27 (SFX) | 0.301 | passes; sped-up beeps |
| 9126086045 | Synth Tone Multi Pitch Short Waa Tone Swell  (SFX) | 0.313 | passes; a "waa" swell, not a blip |
| 9113880400 | Computer Keyboard Beep 1 (SFX) | 0.374 | **rejected:** a sibling of 9113880475, which is already `Computer` and `Station`. Plant would sound like a PC click |

Rejected from the search metadata, not measured:
- Over the limit: "Blip Tone Single High Pitch Synth Blip" (1.2–2.0 s), "Tone Clusters Short Burst Of Soft Beep Tones" (0.6+ s) and "Computer Beeps And Tones" (0.6+ s).
- Cartoonish: "Balloon Pop" and "Boink Wet Suction Pop".
- Not a blip: "Small Bubbles" (water).

### PhoneBuzz (phone vibrate, ≤ 1 s)

Terms: phone vibrate, vibration, cell phone buzz, phone buzz, vibrate, mobile phone, smartphone, pager, pager vibrate, vibrating, buzz, buzzing short, cell phone vibrating table, electric buzz short, phone, electric toothbrush, massager, motor buzz short, rattle buzz, phone ring, haptic, UI buzz, low buzz, switch blurt, graphic buzzes, buzzer short.

| id | name | length s | verdict |
|---|---|---|---|
| 9119715399 | Switch Blurt Single Short Synth Buzzes 6 (SFX) | 0.470 | **pick (stand-in)**: one short, lower-pitch buzz |
| 9114646693 | Graphic Buzzes Short Fuzzy Bursts Ui 8 (SFX) | 0.453 | **alternate (stand-in)** |
| 9114646885 | Graphic Buzzes Short Fuzzy Bursts Ui 11 (SFX) | 0.441 | passes |
| 9114647624 | Graphic Buzzes Short Fuzzy Bursts Ui 11 (SFX) | 0.463 | passes |
| 9119715581 | Switch Blurt Single Short Synth Buzzes 8 (SFX) | 0.493 | passes |
| 9119715178 | Switch Blurt Single Short Synth Buzzes 1 (SFX) | 0.531 | passes |
| 9119715276 | Switch Blurt Single Short Synth Buzzes 4 (SFX) | 0.563 | passes |
| 9120283130 | Tubular Synth Blasts Short Buzzes 2 (SFX) | 0.688 | passes; "stuttering electric burst", harsher |
| 9113932236 | Cordless Phone Ringing Beeps 11 (SFX) | 1.577 | **rejected: over 1 s**. Its description mentions "Pager Phone Vibrates in Distant" |

Rejected from the search metadata, not measured:
- Over 1 s or wrong character: "Pneumatic Drill", "Pneumatic Rivet Gun", "Electric Shaver", "Servo Motor", "Robot Servo", "Nose Hair Trimmer" and "DC Motor". These are motors and power tools, and most are 1.1–2.5 s.
- Harsh: "Static Rough" (static noise).
- Insects: "Bug Legs Vibrate" and "Sprite Chitter".
- Rings, not buzzes: "Phone Ring", "Cell Phone Ring", "Spectra Phone" and "Flip Phone".
- Found no licensed recording of a phone vibrating that is 1 s or shorter.
