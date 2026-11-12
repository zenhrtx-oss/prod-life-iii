# Fiction pass and the starter pool (Wave 3 Tasks 5b and 5b+, built 2026-11-11)

> **Parked 2026-11-11: the user kept the parody names for now. This doc is the ready patch for a later switch to fiction. The names are built (the fiction column). The clean lines are not built; re-apply them from d33d69a's sweep.**

Task 5b and Task 5b+ of `plans/2026-11-05-wave3-stakes.md` ("Launch amendments") were built as one task, because both edit `Data/WalkIns.lua`.
- **The user's call (2026-11-11 19:49):** "keep real names for now". The controller read "real names" as the sound-alike parody roster already in the game, not the stars' own names.
- **What came back:** the parody jokes in the card text, together with the names (Task 5b fix round 1).
- **Not this round:** the user's other point, "big names shoudlnt come until later in the game", is a design question for the room design (Task 5g).

Everything here is the builder's draft. Following the copy rule, the game ships with these drafts and the user approves them afterwards. § Approval list at the end is split in two: what is live now, and what waits for a switch to fiction.

## 1. What is live, and what is parked

**Live now (built):**
- **The parody roster stays the launch roster.** `Config.WalkIns.Roster = "parody"`, unchanged from base 15ff936. Every card keeps base's text, the parody jokes included.
- **The fiction column's names, after the web check** (§ 3). PEONY ROLLER, HEX VELOUR, DUSK CASTELLO and SOLEPOP SNEAKERS replace STIRRUP PEONY, VELVET FANG, HOOT CASTELLO and KICKFLIP FOOTWEAR. They show only once the roster is switched to fiction.
- **F6** (§ 5). `sponsor_warning`'s result text fits two lines for every sponsor name in both rosters.
- **The starter pool** (§ 7). The very first walk-in is drawn at random from six `first` cards, and each of their outcomes pays +5 Aura. The superfan's fixed first visit (`gentle_first`) is retired; the fan still arrives through the BUZZING tier visit (`tier_buzzing`).

**Parked (not built): the nod sweep** (§ 4). This is the patch that gives the fiction cast lines of their own. Card text is shared by both rosters, so the sweep can't go live while the parody names stay. When the roster switches to fiction:
- re-apply d33d69a's sweep (§ 4 lists every line, old → new);
- then work through § 4's to-do list.

**Fiction is a names-only fallback again** (WALKINS_REPORT.md item 5's "half a fallback"). `build/t80_check.lua` now checks that the switch still swaps every name and that no real name appears anywhere (§ 10).

**Copy-only.** Neither the sweep nor its revert moved a number: both pacing outputs are byte-identical to the ones before them. Only the starter pool moved the numbers (§ 8).

## 2. Verdict rule (written before searching)

This is the 2026-10-23 rule (`research/walkins_names_2026-10-23.md`) and the 2026-10-27 role-name rule (`research/wave1_names_2026-10-27.md`), with two additions for this task, marked NEW.

**Queries.** Every name got two standard-mode WebSearch queries: `"<NAME>" rapper OR singer OR band` and `"<NAME>" company OR brand`. A role name's second query also adds `OR app OR show`.

**Fiction artist names.** Replace a name when:
- the exact name is a real performing act (10-23).
- any of its words is a title or a name tied to one of the nine parodied artists (10-23 fix round). This is checked against those artists' Wikipedia discography wikitext (§ 3.4).
- NEW: the exact name is a live or filed trademark for games or music. The game is a game, so a character named exactly like a games mark collides.
- NEW (the nod sweep the brief asks for): one of its words cues the parodied artist's own identity.

**Sponsor names.** Replace a name when:
- the exact name is a real operating company or brand (10-23).
- NEW: its distinctive word is a live mark in the sponsor's own product category, or the name of a charted act.

**Role names.** These are made of common words. Replace one only when the exact phrase names a real act, company, brand, product, app or programme that a player could read the name as pointing to (10-27).

**Keep** a name when the results show only partial matches (one word, a longer or reordered name, a different spelling), dictionary or place uses, or works by unrelated artists.

## 3. Web check (2026-11-11)

These were US web searches, not trademark searches. A small or unindexed business can still use one of these names.

### 3.1 Fiction artists

| Visitor | Name | Rapper / singer / band | Company / brand | Verdict |
|---|---|---|---|---|
| navx | STIRRUP PEONY | no exact act ([Stirrup](https://stirrup.bandcamp.com/community), a Chicago trio) | not searched again | **replaced → PEONY ROLLER**. "Stirrup" is a rodeo word: the cowboy cue the brief names for the country-trap visitor, and pink with western cues is the parodied artist's look. The peony (the B look's bloom) stays. |
| dojabat | VELVET FANG | no exact act ([velvet fangs](https://velvetfangs.bandcamp.com/track/sucker), a small Bandcamp project, plural) | **Velvet Fang LLC** has filed VELVET FANG as a standard-character mark for board games, card games and game cards (serial 88957475, filed 2020) and for role-playing game manuals (serial 97747783, filed 2023): [owner](https://trademarks.justia.com/owners/velvet-fang-llc-4423564), [88957475](https://trademark.justia.com/889/57/velvet-88957475.html), [97747783](https://trademarks.justia.com/977/47/velvet-97747783.html) | **replaced → HEX VELOUR** (a games mark: rule NEW) |
| icespike | SLEET VANTA | none ([Sleet Mage](https://www.viberate.com/artist/sleet-mage), [Vanta Black](https://sonicbids.com/vanta-black)) | none (Vanta the security software company, [brand page](https://www.vanta.com/brand/logo)) | keep (flagged, § 6) |
| charti | STATIC GOBLIN | none ([Static the Prodigy](https://www.shazam.com/artist/static-the-prodigy/1262942044), [Static-X](https://tvtropes.org/pmwiki/pmwiki.php/Music/StaticX), [Nekrogoblikon](https://www.qobuz.com/us-en/interpreter/nekrogoblikon/2254900)) | none (goblin-themed game shops) | keep (flagged, § 6) |
| scoot | ORBIT DUNE | none ([Dune](https://ipfs.ssi.eecc.de/ipns/en.wikipedia-on-ipfs.org/wiki/Dune_(band)), [Orbit Culture](https://seelectronics.com/artists/orbit-culture)) | none ([Orbit irrigation](https://madegooddesigns.com/orbit-bhyve-brand-guidelines/), Dune design and data companies) | keep (flagged, § 6) |
| llama | QUILL MESA | none ([Kid Quill](https://Www.wikipedia.org/wiki/Kid_Quill), Quill, Lil Quill) | none ([Quill office supplies](https://www.cbinsights.com/company/quill-1), Mesa companies) | keep |
| drift | SEQUIN MAPLE | none ([The Sequins](https://wikipedia.com/wiki/The_Sequins)) | none ([Sequin jewelry](https://sequin-nyc.com/pages/about-sequin), maple brands) | keep (flagged, § 6) |
| drizzle | HOOT CASTELLO | no exact act ([Hoot](https://toolost.com/news/article/artist-spotlight-hoot), Hoot Gibson Band) | not searched again | **replaced → DUSK CASTELLO**. "Hoot" is an owl, and the owl is the emblem of the parodied artist's brand. The parody's owl hood points at the same emblem. Castello stays. |
| eyelash | MOSS LULLABY | none ([Moss](https://www.beatport.com/artist/moss/49433), whose debut single was "Lullabye") | none ([Lullaby Sleep Co](https://thingtesting.com/brands/lullaby-sleep-co), Moss baby goods) | keep (flagged, § 6) |

The alternates got the same two queries and the catalogue check:

| Name | Rapper / singer / band | Company / brand | Words in the nine catalogues | Verdict |
|---|---|---|---|---|
| PEONY ROLLER | none ([Roller Gang](https://profiles.sonicbids.com/roller-gang/), [Ester Peony](https://northsound.fm/artist/ester-peony-265719)) | none (peony scarves, a peony texture roller for clay) | none | **shipped** |
| HEX VELOUR | none ([HEX, a UK rapper](https://www.allmusic.com/artist/hex-mn0000991714/biography), [Tony Velour](https://schedule.sxsw.com/2022/artists/2057468)) | none ([Hex MCR streetwear](https://bd.fashionnetwork.com/news/Hex-MCR-expands-with-full-apparel-offer,1305658.html), Velour Garments) | none | **shipped** |
| DUSK CASTELLO | none ([Via Castello](https://music.apple.com/us/artist/via-castello/1790548868), several acts called Dusk) | none ([Dusk, a homeware retailer](https://insideretail.us/dusks-great-rejuvenation-and-how-its-building-brand-love-before-a-discount/), Castello beer and wine) | none | **shipped** |
| PEONY BOOGIE, PEONY PARADE, MOTH VELOUR | not searched | not searched | **boogie** is in A Boogie wit da Hoodie, who features beside the parodied rapper on a song on his page; **parade** is in "Parade on Cleveland" (featuring the parodied singer); **moth** is in "Moth Balls" (the parodied singer, 2025) | rejected before the web check |

### 3.2 Fiction sponsors

| Sponsor | Name | Rapper / singer / band | Company / brand | Verdict |
|---|---|---|---|---|
| energy | NITE OWL ENERGY | the St. Louis rapper [Nite Owl](https://niteowlhiphop.bandcamp.com/music), an independent act | no Nite Owl energy drink found. The live NITE OWL mark (reg. 7542642, Class 9) is a [nightlife-concierge app](https://trademarkregistration.app/Trademark/Details/98281964) from NITEOWL LLC, Chicago | keep (flagged, § 6) |
| sneakers | KICKFLIP FOOTWEAR | **KickFlip**, JYP's K-pop group, a charted act since its January 2025 debut ([Korea Times](https://www.koreatimes.co.kr/amp/entertainment/k-pop/20250120/kickflip-debuts-as-jyps-new-spin)) | the **KICKFLIPS** mark of KICKFLIPS LLC covers footwear and shoes ([owner](https://trademark.justia.com/owners/kickflips-llc-2224309), [mark](https://trademarks.justia.com/852/28/kickflips-85228412.html)), and Airwalk sells a "Kickflip" sneaker ([listing](https://www.walmart.com/ip/14998623656)) | **replaced → SOLEPOP SNEAKERS** (rule NEW: a live mark in its own category, and a charted act) |
| headphones | THUMPCAN HEADPHONES | none ([Thumpasaurus](https://app.ckord.com/artists/thumpasaurus)) | none ([Thump](https://sponsorpitch.com/sponsors/thump)) | keep |
| streaming | GLOW GUM | none (GUM, Glitch Gum, gglum) | none ([Glow, a discontinued drink](https://www.bevnet.com/brands/glow/allimages), [Glee Gum](https://www.nombase.com/companies/glee-gum)) | keep |
| watches | STACKS BANK | none ([Stacks, a rapper](https://ipfs.ssi.eecc.de/ipns/en.wikipedia-on-ipfs.org/wiki/Stacks_(rapper))) | none ([STACK Fintech](https://trademarks.justia.com/owners/stack-fintech-inc-3399251), once a digital bank called Stack) | keep |
| water | SIPWAVE WATER | none | none ([SIPWater](https://village.ai/company/sipwater), [SportWave water](https://www.bevnet.com/brands/sportwavewater)) | keep |
| sneakers (alternate) | SOLEPOP SNEAKERS | none ([Sole, a rapper](https://wikipedia.com/wiki/Sole_(artist))) | none ([solepropinc, an eBay reseller](https://www.ebay.com/str/solepropinc)). LACEBOLT was clean too, but not used | **shipped**: 16 characters, no longer than the old name, so no `{sponsor}` string grows |

### 3.3 The starter pool's people (Task 5b+)

| Visitor (`check` anchor) | Parody | Fiction | Found | Verdict |
|---|---|---|---|---|
| <a id="rapper"></a>`rapper` | A RAPPER WITH NO BEAT | A RAPPER WITH A NOTEBOOK | nothing exact in either roster ([Kiff No Beat](https://northsound.fm/genre/5285?page=40) and a [rhyme notebook](https://rhymebook.com/shop) are partials) | keep |
| <a id="cousin"></a>`cousin` | YOUR BIG COUSIN | YOUR OLDER COUSIN | [Big Cousin](https://earmilk.com/2019/10/03/big-cousin-and-evidence-team-up-on-bleed-respect) is a London-based emcee, and Hi-Tone has a song called ["Big Cousin"](https://www.xxlmag.com/hi-tone-big-cousin-video/). The fiction name matches nothing | keep. This is a partial in the parody name only, which the launch doesn't show. "YOUR COUSIN" alone would have failed the data spec, because "your cousins" is in an existing line |
| <a id="neighbor"></a>`neighbor` | THE NEIGHBOR NEXT DOOR | A SLEEPY NEIGHBOR | nothing exact. Partials: [The Neighbourhood](https://www.wikipedia.com/wiki/The_Neighbourhood), the [Nextdoor](https://apps.apple.com/app/640360962) app, [Sleepy Hallow](https://wikipedia.com/wiki/Sleepy_Hallow) | keep. "THE NEIGHBOR" alone would have failed the data spec ("the neighborhood" is in an existing line) |
| <a id="host"></a>`host` | THE OPEN-MIC HOST | THE BEAT-NIGHT HOST | the phrase in its plain sense, plus [open-mic apps](https://apps.apple.com/us/app/openmic-music-networking/id6475248760?l=en-US) with generic names | keep |
| <a id="landlord"></a>`landlord` | THE STUDIO OWNER | THE LATE-NIGHT LANDLORD | nothing exact ([Landlord Lo](https://www.viberate.com/artist/landlord-lo)) | keep. The first fiction draft, A STUDIO LANDLORD, was dropped: it reverses [Landlord Studio](https://www.landlordstudio.com/uk/careers), a property-management app |

Local checks on the new names:
- Every fiction name differs from every parody name.
- No fiction name contains a parody name.
- No card text types a display name of either roster.

The data spec enforces all three (`spec/walkins_data_spec.lua`).

### 3.4 Catalogue check

Method: on 2026-11-11 I fetched the same 15 English Wikipedia discography and song-list pages as on 10-23, as raw wikitext with `action=raw`. They cover the nine parodied artists. I searched each page for whole words, ignoring case.

Controls:
- "rodeo": 14 hits on one artist's page, 24 on another's, and 1 more.
- "old town road": 7.
- "halley": 3.

Results:
- peony, stirrup, velvet, fang, sleet, vanta, goblin, orbit, dune, quill, mesa, sequin, maple, moss, lullaby, hoot and castello: none.
- static: only in billboard.com URLs and a guest singer's name, the same as on 10-23.
- New words roller, velour, hex and dusk: none.
- Rejected words boogie, parade and moth: see § 3.1.

## 4. The nod sweep (the parked patch: not built)

**Not built.** Fix round 1 (2026-11-11) returned every line below to base 15ff936's text, because the parody names stayed. This section is the patch for a later switch to fiction: re-apply d33d69a's version of each string below. `sh .superpowers/g show d33d69a:src/ReplicatedStorage/OK/Data/WalkIns.lua` shows the whole swept file.

**Also to do at that switch.** These come from Task 5b's review (Minor 1), and the user approves each one:
- **STATIC GOBLIN's album that might never drop** is still in two bubbles: `charti_vault`'s choice 3 bad ("not ready yet. maybe never") and `payback_charti`'s bad ("it'll come out. one day. maybe").
- **SEQUIN MAPLE's re-record shape** is still in `drift_session`: "Rebuild it note for note. No shortcuts.", "It sounded exactly right, only cleaner." and "She booked you for the whole album."
- **MOSS LULLABY's breathing** is still in `eyelash_pitch`'s choice 2 good: "You could hear her breathing between words."
- **The two judgment calls** kept below: `drift_bracelets`' "Hide a tiny melody only fans would notice." and `navx_single`'s "OWN YOUR MASTERS".

The goal is that each fiction artist gets a genre and story of their own. WALKINS_REPORT.md item 5 listed the cues to start from: re-recordings, friendship bracelets, a halftime show, a vault of unreleased songs, banjo trap, a sneaker launch and stitched beats. Each artist's genre tag and style were added to that list. The style is the name plate's second line, and the genre is the first half of every tag on their cards.

Every change keeps:
- the card's ids and outcome keys.
- every number and choice order.
- every plant and relationship write.
- `{beat}` in the same ten places.
- `{name:<id>}` and the caps / lowercase rules.

New lines say no "bedroom" and no "your studio". No rewrite adds a hint term (aura, followers, placement, hit, sponsor, flip, cypher, fire). navx_placement's first term stays "placement", and navx_single's tag, line and choices stay term-free, as t76a needs.

Every changed string, old → new, by fiction artist:

#### PEONY ROLLER (`navx`; parody LIL NAV X): country trap, banjo and rodeo cues -> disco trap, strings, roller skates

| Where | Old | New |
|---|---|---|
| `card navx_placement.tag` | COUNTRY TRAP · WANTS A PLACEMENT | DISCO TRAP · WANTS A PLACEMENT |
| `card navx_session.tag` | COUNTRY TRAP · BANJO ON A TRAP BEAT | DISCO TRAP · STRINGS ON A TRAP BEAT |
| `card navx_session.line` | can you put a banjo on a trap beat? like actually make it slap | can you put strings on a trap beat? like actually make it slap |
| `card navx_session choice 1.text` | Learn the banjo pattern properly first. | Learn the string part properly first. |
| `card navx_session choice 2.text` | Sell him your banjo loop pack. | Sell him your loop pack. |
| `card navx_session choice 3.text` | Post a banjo trap test online. | Post a disco trap test online. |
| `card navx_session choice 3.good.text` | The clip took off. Banjo trap is a thing now. | The clip took off. Disco trap is a thing now. |
| `card navx_video.tag` | COUNTRY TRAP · MUSIC VIDEO | DISCO TRAP · MUSIC VIDEO |
| `card navx_video.line` | i want you in the video. mechanical bull. trust me | i want you in the video. roller skates. trust me |
| `card navx_video choice 1.text` | Ride the bull. Commit to the bit. | Skate in it. Commit to the bit. |
| `card navx_video choice 1.good.headline` | BULL RIDER | ROLLER STAR |
| `card navx_video choice 1.good.text` | You lasted eight seconds. The clip is everywhere. | You never fell once. The clip is everywhere. |
| `card navx_video choice 1.good.line` | eight seconds!! you're a natural fr | not one fall!! you're a natural fr |
| `card navx_video choice 1.bad.text` | You fell off in two seconds. The blooper reel is not kind. | You fell in two seconds. The blooper reel is not kind. |
| `card navx_tour.tag` | COUNTRY TRAP · TOUR DJ | DISCO TRAP · TOUR DJ |
| `card navx_tv.tag` | COUNTRY TRAP · LATE-NIGHT TV | DISCO TRAP · LATE-NIGHT TV |
| `card navx_replaced.tag` | COUNTRY TRAP · NEW PRODUCER | DISCO TRAP · NEW PRODUCER |
| `card dm_navx.tag` | COUNTRY TRAP · DM | DISCO TRAP · DM |
| `card dm_navx.line` | yo you got a banjo loop? need it for a freestyle tonight | yo you got a disco loop? need it for a freestyle tonight |
| `card dm_navx choice 1.good.line` | this banjo goes crazy. owe you one | this loop goes crazy. owe you one |
| `followup navx_single.tag` | COUNTRY TRAP · THE SINGLE IS OUT | DISCO TRAP · THE SINGLE IS OUT |
| `followup navx_album.tag` | COUNTRY TRAP · THE ALBUM IS OUT | DISCO TRAP · THE ALBUM IS OUT |

#### HEX VELOUR (`dojabat`; parody DOJA BAT): chaotic pop rap -> spooky pop

| Where | Old | New |
|---|---|---|
| `card dojabat_pitch.tag` | CHAOTIC POP RAP · WANTS A PLACEMENT | SPOOKY POP · WANTS A PLACEMENT |
| `card dojabat_session.tag` | CHAOTIC POP RAP · LATE NIGHT SESSION | SPOOKY POP · LATE NIGHT SESSION |
| `card dojabat_stream.tag` | CHAOTIC POP RAP · LIVESTREAM | SPOOKY POP · LIVESTREAM |
| `card dm_dojabat.tag` | CHAOTIC POP RAP · DM | SPOOKY POP · DM |
| `followup payback_dojabat.tag` | CHAOTIC POP RAP · TRACK ONE | SPOOKY POP · TRACK ONE |

#### SLEET VANTA (`icespike`; parody ICE SPIKE): drill pop -> phonk

| Where | Old | New |
|---|---|---|
| `card icespike_pitch.tag` | DRILL POP · WANTS A PLACEMENT | PHONK · WANTS A PLACEMENT |
| `card icespike_session.tag` | DRILL POP · JERSEY CLUB FLIP | PHONK · JERSEY CLUB FLIP |
| `card icespike_snippet.tag` | DRILL POP · SNIPPET SEASON | PHONK · SNIPPET SEASON |
| `followup payback_icespike.tag` | DRILL POP · TRACK ONE | PHONK · TRACK ONE |

#### STATIC GOBLIN (`charti`; parody PLAYDOH CHARTI): rage rap, the vault of unreleased songs, the album that might never drop -> noise rap, a shelf, a big year

| Where | Old | New |
|---|---|---|
| `card charti_pitch.tag` | RAGE RAP · WANTS A PLACEMENT | NOISE RAP · WANTS A PLACEMENT |
| `card charti_pitch choice 1.good.line` | this the one. album might drop. might not | this the one. the speakers ain't ready |
| `card charti_pitch choice 1.bad.headline` | IN THE VAULT | SHELVED |
| `card charti_pitch choice 1.bad.text` | His album got pushed back. Your beat is in the vault. | His album got shelved. Your beat went with it. |
| `card charti_pitch choice 1.bad.line` | it's in the vault. the vault is forever | it's shelved. that shelf is forever |
| `card charti_session.tag` | RAGE RAP · 4 AM SESSION | NOISE RAP · 4 AM SESSION |
| `card charti_vault.tag` | RAGE RAP · THE VAULT | NOISE RAP · THE BIG YEAR |
| `card charti_vault.line` | i got like 300 unreleased songs. want to hear one | i made like 300 songs this year. want to hear one |
| `card charti_vault choice 3.good.line` | first one out the vault in years. here | first one i ever finished. here |
| `card charti_vault choice 3.bad.headline` | BACK IN THE VAULT | BACK ON THE SHELF |
| `card charti_vault choice 3.bad.text` | It went straight back in the vault. | It went right back on the shelf. |
| `followup payback_charti.tag` | RAGE RAP · TRACK ONE | NOISE RAP · TRACK ONE |
| `followup payback_charti.line` | the album actually dropped. track one is yours. i'm shocked too | the album's out. track one is yours. loud like you said |
| `followup payback_charti.resolve.good.headline` | OUT OF THE VAULT | TRACK ONE |
| `followup payback_charti.resolve.good.line` | first one out the vault. it's yours | loudest track on it. it's yours |
| `followup payback_charti.resolve.bad.headline` | BACK IN THE VAULT | BACK ON THE SHELF |
| `followup payback_charti.resolve.bad.text` | Your beat went back in the vault, but a snippet leaked and people loved it. | Your beat stayed on the shelf, but a snippet leaked and people loved it. |

#### ORBIT DUNE (`scoot`; parody TRAVIS SCOOT): space trap, stacked vocals, five beats stitched with switch-ups, a sneaker launch -> synthwave, synth layers, a five-minute song, a planetarium laser show

| Where | Old | New |
|---|---|---|
| `card scoot_pitch.tag` | SPACE TRAP · WANTS A PLACEMENT | SYNTHWAVE · WANTS A PLACEMENT |
| `card scoot_pitch choice 1.good.text` | {name:scoot} stacked ten vocal layers on it. You're on the tape. | {name:scoot} put ten synth layers on it. You're on the tape. |
| `card scoot_session.tag` | SPACE TRAP · FIVE BEATS IN ONE | SYNTHWAVE · THE LONG SONG |
| `card scoot_session.line` | i want five beats stitched into one song. switch it up three times | i want a five-minute song that never gets boring |
| `card scoot_session choice 1.text` | Plan the switch-ups on paper first. | Plan every minute on paper first. |
| `card scoot_session choice 1.good.text` | Every switch landed where it should. He noticed. | Every minute landed where it should. He noticed. |
| `card scoot_session choice 2.text` | Charge per beat. | Charge per minute. |
| `card scoot_session choice 2.good.text` | Five beats, five invoices. | Five minutes, five invoices. |
| `card scoot_session choice 2.good.line` | fair. five beats, five payments | fair. five minutes, five payments |
| `card scoot_session choice 2.bad.text` | The switch-ups didn't land. You redid it and covered the room. | Minute four dragged. You redid it and covered the room. |
| `card scoot_session choice 2.bad.line` | switch three is off. run it back | minute four is off. run it back |
| `card scoot_session choice 3.text` | Rent extra synths and build all five. | Rent extra synths. Build all of it. |
| `card scoot_session choice 3.good.text` | Five beats, three switches, one song. He paid upfront. | Five minutes, not one dull second. He paid upfront. |
| `card scoot_launch.tag` | SPACE TRAP · SNEAKER LAUNCH | SYNTHWAVE · LASER SHOW |
| `card scoot_launch.line` | dropping sneakers next week. i need a beat for the launch video | planetarium laser show next week. i need a beat for the intro |
| `card scoot_launch choice 1.good.text` | The countdown beat is all over the launch clips. | The countdown beat is all over the show clips. |
| `card scoot_launch choice 3.text` | Pay for the countdown visuals yourself. | Pay for the countdown lasers yourself. |
| `card scoot_launch choice 3.good.headline` | VISUALS HIT | LASERS HIT |
| `card scoot_launch choice 3.good.text` | The visuals looked like a rocket launch. He paid you back and then some. | The lasers looked like a rocket launch. He paid you back and then some. |
| `card scoot_launch choice 3.good.line` | those visuals are crazy. your cut | those lasers are crazy. your cut |
| `card scoot_launch choice 3.bad.text` | His team used their own visuals instead. | His team used their own lasers instead. |
| `card scoot_launch choice 3.rare.text` | The sneakers sold out in a minute and your beat was the soundtrack. Big check. | The show sold out every night and your beat opened it. Big check. |
| `card scoot_launch choice 3.rare.line` | sold out in a minute!! you're getting paid | sold out every night!! you're getting paid |
| `followup scoot_refund.tag` | SPACE TRAP · LABEL REVIEW | SYNTHWAVE · LABEL REVIEW |
| `followup scoot_refund.line` | label heard the five-in-one. we need to talk | label heard the long one. we need to talk |
| `followup scoot_refund.resolve.good.text` | The label loved every switch-up. | The label loved every minute. |
| `followup scoot_refund.resolve.good.line` | they loved it. all five | they loved every minute |
| `followup payback_scoot.tag` | SPACE TRAP · TRACK ONE | SYNTHWAVE · TRACK ONE |

#### QUILL MESA (`llama`; parody KENDRICK LLAMA): lyrical rap, a jazz loop, a halftime show -> boom bap, a soul loop, a festival opener

| Where | Old | New |
|---|---|---|
| `card llama_pitch.tag` | LYRICAL RAP · WANTS A PLACEMENT | BOOM BAP · WANTS A PLACEMENT |
| `card llama_pitch choice 1.text` | Send a sparse beat with a jazz loop. Free. | Send a sparse beat with a soul loop. Free. |
| `card llama_session.tag` | LYRICAL RAP · STRIP IT DOWN | BOOM BAP · STRIP IT DOWN |
| `card llama_halftime.tag` | LYRICAL RAP · HALFTIME SHOW | BOOM BAP · FESTIVAL OPENER |
| `card llama_halftime.line` | big stage coming up. i need an intro that stops the whole stadium | big stage coming up. i need an intro that stops the whole field |
| `card llama_halftime choice 1.good.headline` | STADIUM WENT QUIET | THE FIELD WENT QUIET |
| `card llama_halftime choice 2.text` | License him a stadium intro you already made. $100. | License him an intro you already made. $100. |
| `card llama_halftime choice 3.good.text` | The drumline shook the stadium. He paid you back and then some. | The drumline shook the field. He paid you back and then some. |
| `followup payback_llama.tag` | LYRICAL RAP · TRACK ONE | BOOM BAP · TRACK ONE |

#### SEQUIN MAPLE (`drift`; parody TAYLOR DRIFT): sparkle pop, bridges, hidden clues, re-recordings, fan bracelets -> bubblegum pop, hooks and intros, a tease, karaoke versions, keychains

| Where | Old | New |
|---|---|---|
| `card drift_pitch.tag` | SPARKLE POP · WANTS A PLACEMENT | BUBBLEGUM POP · WANTS A PLACEMENT |
| `card drift_pitch.line` | i'm writing about a road trip. let me hear {beat}. i need a bridge | i'm writing about a road trip. let me hear {beat}. i need a hook |
| `card drift_pitch choice 1.text` | Send her a beat with a huge bridge. Free. | Send her a beat with a huge hook. Free. |
| `card drift_pitch choice 1.good.text` | {name:drift} wrote the whole song around your bridge. | {name:drift} wrote the whole song around your hook. |
| `card drift_pitch choice 1.good.line` | the bridge!! that's the song | the hook!! that's the song |
| `card drift_pitch choice 3.text` | Hide clues about the song in your posts. | Tease the hook in your posts. |
| `card drift_pitch choice 3.good.text` | Her fans decoded everything. Followers flooded in. | Her fans spread the tease. Followers flooded in. |
| `card drift_pitch choice 3.good.line` | they found the clues in an hour lol | they're humming it already lol |
| `card drift_pitch choice 3.bad.text` | The clues pointed to the wrong song. Her fans were not happy. A client left. | You teased the wrong hook. Her fans were not happy. A client left. |
| `card drift_pitch choice 3.bad.line` | wrong song bestie. they're confused | wrong hook bestie. they're confused |
| `card drift_session.tag` | SPARKLE POP · RE-RECORDING | BUBBLEGUM POP · KARAOKE VERSIONS |
| `card drift_session.line` | i'm re-recording my old songs. can you rebuild this beat exactly | i want karaoke versions of my songs. rebuild the beats exactly |
| `card drift_session choice 1.good.line` | it's perfect. like it never left | perfect. now everyone can sing it |
| `card drift_session choice 3.text` | Post a side-by-side of the old and new. | Post a sing-along clip. |
| `card drift_session choice 3.good.headline` | SIDE BY SIDE | SING-ALONG |
| `card drift_session choice 3.good.text` | Her fans played it a hundred times. | Her fans sang along a hundred times. |
| `card drift_session choice 3.good.line` | they can't stop comparing lol | they can't stop singing lol |
| `card drift_session choice 3.bad.headline` | CAN'T HEAR IT | NOBODY SANG |
| `card drift_session choice 3.bad.text` | People couldn't hear the difference. | People said it was too high to sing. |
| `card drift_session choice 3.bad.line` | that's kind of the point tho | we'll lower the key. maybe |
| `card drift_bracelets.tag` | SPARKLE POP · FAN BRACELETS | BUBBLEGUM POP · FAN KEYCHAINS |
| `card drift_bracelets.line` | my fans trade bracelets at every show. make a beat they can trade too | my fans trade keychains at every show. make a beat they can trade too |
| `card drift_bracelets choice 2.text` | Sell beat-themed bracelets. $100. | Sell beat-themed keychains. $100. |
| `card drift_bracelets choice 2.good.text` | You sold a box of bracelets. | You sold a box of keychains. |
| `card drift_bracelets choice 3.text` | Pay for a bracelet booth with your logo. | Pay for a keychain booth with your logo. |
| `card drift_bracelets choice 3.rare.text` | Your bracelets sold out and fans are trading them online. Big check. | Your keychains sold out and fans are trading them online. Big check. |
| `card drift_bracelets choice 3.rare.line` | they're trading your bracelets now lol | they're trading your keychains now lol |
| `card dm_drift.tag` | SPARKLE POP · DM | BUBBLEGUM POP · DM |
| `card dm_drift.line` | quick question. is it weird if the bridge is longer than the chorus | quick question. is it weird if the intro is longer than the chorus |
| `card dm_drift choice 1.text` | Tell her the bridge can be the song. | Tell her the intro can be the song. |
| `card dm_drift choice 1.good.text` | She took the advice. The bridge is now three minutes long. | She took the advice. The intro is now three minutes long. |
| `card dm_drift choice 2.text` | Send her a voice memo of a bridge idea. | Send her a voice memo of an intro idea. |
| `card dm_drift choice 2.good.line` | the bridge you sent!! it's in!! | the intro you sent!! it's in!! |
| `followup drift_single.tag` | SPARKLE POP · THE SINGLE IS OUT | BUBBLEGUM POP · THE SINGLE IS OUT |
| `followup drift_single.line` | the single's out!! the bridge is everyone's favorite part | the single's out!! the hook is everyone's favorite part |
| `followup drift_single.resolve.good.text` | The single charted and fans are singing your bridge. | The single charted and fans are singing your hook. |
| `followup drift_single.resolve.good.line` | they're singing the bridge!! hit!! | they're singing the hook!! hit!! |
| `followup drift_single.resolve.bad.text` | The single didn't chart. The bridge still has fans. | The single didn't chart. The hook still has fans. |
| `followup drift_single.resolve.bad.line` | not a hit. the bridge is still perfect tho | not a hit. the hook is still perfect tho |

#### DUSK CASTELLO (`drizzle`; parody DRIZZLE): late night r&b, 2 am, the night owls -> neo soul, candlelight, slow jams

| Where | Old | New |
|---|---|---|
| `card drizzle_pitch.tag` | LATE NIGHT R&B · WANTS A PLACEMENT | NEO SOUL · WANTS A PLACEMENT |
| `card drizzle_pitch.line` | make {beat} feel like 2 am. moody but you can still dance | make {beat} feel like candlelight. warm, but you can dance |
| `card drizzle_pitch choice 1.text` | Send a moody beat with a dance switch. Free. | Send a warm beat with a dance switch. Free. |
| `card drizzle_pitch choice 1.good.line` | this is the 2 am sound. it's on | this is the candlelight sound. it's on |
| `card drizzle_pitch choice 1.bad.text` | He said it was more 1 am than 2 am. | He said it was more lamp than candle. |
| `card drizzle_session.tag` | LATE NIGHT R&B · FEATURE | NEO SOUL · FEATURE |
| `card drizzle_fit.tag` | LATE NIGHT R&B · FIT CHECK | NEO SOUL · FIT CHECK |
| `followup drizzle_remix.tag` | LATE NIGHT R&B · THE REMIX IS OUT | NEO SOUL · THE REMIX IS OUT |
| `followup drizzle_remix.line` | remix is out. late night playlists picked it up | remix is out. slow-jam playlists picked it up |
| `followup drizzle_remix.resolve.good.line` | the remix is everywhere at 2 am. hit | the remix is everywhere tonight. hit |
| `followup payback_drizzle.tag` | LATE NIGHT R&B · TRACK ONE | NEO SOUL · TRACK ONE |
| `followup payback_drizzle.line` | album's out. track one is yours. 2 am, like we said | album's out. track one is yours. candlelight, like we said |
| `followup payback_drizzle.resolve.good.text` | {name:drizzle} opened the album with your beat. It's the late-night favorite. | {name:drizzle} opened the album with your beat. It's the slow-dance favorite. |
| `followup payback_drizzle.resolve.bad.text` | It landed on the deluxe edition. The night owls found it. | It landed on the deluxe edition. The slow dancers found it. |
| `followup payback_drizzle.resolve.bad.line` | deluxe. still counts at 2 am | deluxe. still counts by candlelight |

#### MOSS LULLABY (`eyelash`; parody BILLIE EYELASH): whisper pop, whispering -> lo-fi, humming, a lullaby beat

| Where | Old | New |
|---|---|---|
| `card eyelash_pitch.tag` | WHISPER POP · WANTS A PLACEMENT | LO-FI · WANTS A PLACEMENT |
| `card eyelash_pitch choice 1.good.text` | {name:eyelash} whispered a whole song over it. You're on it. | {name:eyelash} hummed a whole song over it. You're on it. |
| `card eyelash_session.tag` | WHISPER POP · BASS YOU FEEL | LO-FI · BASS YOU FEEL |
| `card eyelash_rain.tag` | WHISPER POP · FIELD RECORDING | LO-FI · FIELD RECORDING |
| `card dm_eyelash.tag` | WHISPER POP · DM | LO-FI · DM |
| `card dm_eyelash choice 2.good.headline` | WHISPER BEAT | LULLABY BEAT |
| `followup payback_eyelash.tag` | WHISPER POP · TRACK ONE | LO-FI · TRACK ONE |

**Checked and kept, judged generic or fitting the new genre:**
- HEX VELOUR's haunted arcade, cursed sounds, livestream with chat, "bestie" and "SHE LOGGED OFF".
- SLEET VANTA's ninety-second songs, jersey club flip and snippet season. These are broad trends once the genre and look change.
- STATIC GOBLIN's speakers breaking, 4 am sessions, cryptic posts and a surprise midnight drop.
- ORBIT DUNE's space, tape, liftoff and orbit, which now fit the synthwave genre.
- QUILL MESA's room for the words, the live sax player and the drumline.
- SEQUIN MAPLE's road trip, "saved for later" and the hidden melody only fans would notice. That last one is a judgment call: hidden melodies are a common producer trick.
- DUSK CASTELLO's hoodie, feature, fit check and dark room.
- MOSS LULLABY's quiet, bass you feel, headphones-only test, rain and 3 am.
- navx_single's "OWN YOUR MASTERS", which is generic industry advice.

**Everything else players read has no real names or cues.** That covers story copy (`LifeRules.Copy`), banners, the cold spell's card and lines, Config's unlock lines, hints, gear, ranks and gates, and the session-request artists (names, styles, quotes, titles). No change was needed there. `build/t80_check.lua` scans every shipped string in both rosters for real names. It has no cue scan while the parody jokes are live.

## 5. F6: sponsor_warning in two lines (live now)

The result card's text label is 312 × 30 px at TextSize 12, in GothamBold, which renders as Montserrat Bold. Task 5's review measured the real em at about 0.846 × TextSize. With the fiction names, the old text took three lines.

I measured with Studio's own `Montserrat-Bold.ttf` and greedy word wrap. The calibration matches the review: two in-game lines give 0.845 and 0.849.

| Text | Worst line count at em 0.80 / 0.846 / 0.88 / 0.92 |
|---|---|
| old: "{sponsor} warned you instead of dropping you. Get your aura back over their bar before they check again." | THUMPCAN HEADPHONES and KICKFLIP FOOTWEAR take 3 lines at 0.846. NITE OWL ENERGY and SIPWAVE WATER take 3 at 0.88 |
| new: "{sponsor} warned you. Get your aura back over their bar before they check again." | 2 lines for all 12 sponsor names (both rosters) at every ratio. Widest: THUMPCAN HEADPHONES, 571 px of 624 at 0.92 |

Both sides of the news read the same (the data spec pins them equal). The same measurement over every result text in the deck, in both rosters, gives at most 2 lines at 0.846 and 0.88. Every note fits 2 lines of its 232 px label at TextSize 10.

`t80_check` (c) measures the warning in Studio with `TextService:GetTextSize`, for every sponsor name in both rosters (review Minor 2). Its controls: a calibration line that must measure 240–330 px, and the old text with the longest name, which must measure 3 lines.

## 6. Kept, but flagged for your call (the fiction names)

These are the fiction column's names. They are built, but show only after a switch to fiction, and the Task 5d notes in them apply to that switch.

- **SLEET VANTA.** "Sleet" keeps the parody's ice. The genre is now phonk, and Task 5d removes the orange spiky hair, so nothing else points back. You may still prefer a word that isn't icy.
- **ORBIT DUNE.** The space words fit the new synthwave genre. The helmet goes to Task 5d.
- **SEQUIN MAPLE.** Sequins sparkle. The genre is now bubblegum pop, and the sparkle cape goes to Task 5d.
- **MOSS LULLABY.** Moss is green, and the parodied singer's look was green roots. The genre is now lo-fi. The green roots and green body colour go to Task 5d.
- **STATIC GOBLIN.** *Goblin* is also an album by Tyler, the Creator, who is not one of the nine, so the rule keeps it.
- **NITE OWL ENERGY.** Kept by the rule (an independent rapper; the NITE OWL mark is an app). It is the same owl the rename of HOOT avoided, but on a sponsor, not on the late-night singer.
- **YOUR BIG COUSIN.** A parody-roster name only (see § 3.3).

## 7. The starter pool (Task 5b+)

The user, 2026-11-06 03:15: "If it was bitlife mechanics wouldn't it be a bunch of randomized options that would work within that scenario?"

**Rules.**
- `WalkInRules.Pick` at visits 0 draws among the eligible `first` cards by weight, in deck order, with one `rng(1, total)` draw. This is the same draw as the least-seen pool's.
- Before, it returned the first such card in deck order with no draw.
- With no eligible `first` card, including every phone pick, the normal least-seen draw runs.
- Every starter is gated by exactly `under = { visits = 1 }`, so none of the six ever comes after your first walk-in.
- Every starter costs nothing, loses nothing, plants nothing, writes no relationship and pays no placement. The data spec pins all of this.
- **Every starter outcome pays +5 Aura on top of its draft** (the controller's ruling of 2026-11-11; § 8). It replaces the first-visit Aura cushion gentle_first gave: its wins paid +5 or +10 Aura, its neutral outcome 0. The drafts' own Aura stays: GOOD NEIGHBOR is +15, A FAN NEXT DOOR +10.
- **A copy question for you: seven neutral outcomes now show a +5 AURA chip under a neutral headline.** They are NOT YET, EARPLUGS, HEADPHONES ON, HE'S NOT SURE, OUT IN ROUND ONE, QUIET NIGHT and MAYBE NEXT WEEK. Their tones stay neutral, as the ruling says. Changing a tone to win would be your call on the copy.
- The server (`Systems/WalkIns` `nextPick`) and the sim (`CareerSim`) both call `Pick`, so they need no change of their own.

**The cards.** Each card fits a producer with nothing yet and teaches one thing. Five do it through their hint: the first card a player sees gets the explainer line for its term. The copy is room-neutral (no "bedroom", no "your studio") until the room (Task 5g) is built.

| Card (visitor) | Teaches | Tag | His or her line |
|---|---|---|---|
| `starter_rapper` (`rapper`) | beats pay; REQUESTS (in its note) | LOCAL RAPPER · NO BEAT YET | i wrote a whole verse on the bus and got nothing to rap it on. make me a beat? |
| `starter_cousin` (`cousin`) | FOLLOWERS | FAMILY · YOUR FIRST FAN | i followed you. that's one. how do we get you more followers? |
| `starter_neighbor` (`neighbor`) | AURA | NEXT DOOR · THE NOISE | your bass is coming through my wall and it's late. that's minus aura |
| `starter_kid` (`blockkid`) | PLACEMENT | THE BLOCK · TEACH ME | you make beats? for real? how do you get a placement on a real song? |
| `starter_host` (`host`) | CYPHER (it gives the cypher hint its first attach point; Task 0 had none) | BEAT NIGHT · ONE SLOT LEFT | friday's beat night has one slot left. it's a cypher. you in? |
| `starter_landlord` (`landlord`) | FIRE | AFTER MIDNIGHT · BIG SPEAKERS | my room's empty after midnight. play your beat loud. if people feel it, that's fire |

Every starter line as built:

**`starter_rapper`** (rapper). Tag "LOCAL RAPPER · NO BEAT YET". Line: "i wrote a whole verse on the bus and got nothing to rap it on. make me a beat?"

1. "Make him one right now. $40." (sure)
   - good: **FIRST PAYING JOB** (win, $40, +5 Aura): "You built it in an hour and he paid on the spot. Beats pay." Bubble: "this is it. i'm rapping on this tonight" Note: "Artists pay for beats. Check REQUESTS for more work."
2. "Make it free if he shouts you out." (sure)
   - good: **SHOUT-OUT** (win, +5 Aura, +100 Followers): "He shouted you out before his verse. A few people looked you up." Bubble: "i'm saying your name every time i rap it"
3. "Make two and let him pick." (odds 60)
   - good: **HE TOOK BOTH** (win, $80, +5 Aura): "He liked both and paid for both." Bubble: "can't pick. i'll take both. here"
   - bad: **HE TOOK ONE** (win, $40, +5 Aura): "He took one and paid for it. The other one's yours to keep." Bubble: "this one. the other one's hard too tho"

**`starter_cousin`** (cousin). Tag "FAMILY · YOUR FIRST FAN". Line: "i followed you. that's one. how do we get you more followers?"

1. "Make a beat for her page." (sure)
   - good: **ON HER PAGE** (win, +5 Aura, +150 Followers): "She posted it with your name on it. Her friends followed you." Bubble: "my friends keep asking who made it. you did"
2. "Ask her to share your page." (sure)
   - good: **SHARED** (win, +5 Aura, +100 Followers): "She sent your page to everyone she knows. The family group chat followed you." Bubble: "done. even grandma followed you"
3. "Play her something unfinished." (odds 60)
   - good: **SHE'S HOOKED** (win, +5 Aura, +200 Followers): "She filmed ten seconds of it. People want the full beat." Bubble: "finish this one. i'm serious"
   - bad: **NOT YET** (neutral, +5 Aura): "She nodded along politely. It's not done, and it showed." Bubble: "it's gonna be good when it's done"

**`starter_neighbor`** (neighbor). Tag "NEXT DOOR · THE NOISE". Line: "your bass is coming through my wall and it's late. that's minus aura"

1. "Turn it down and say sorry." (sure)
   - good: **GOOD NEIGHBOR** (win, +15 Aura): "You turned it down and said sorry. Word gets around that you're decent." Bubble: "thank you. was that so hard?"
2. "Invite him in to hear the beat." (odds 50)
   - good: **A FAN NEXT DOOR** (win, +10 Aura, +100 Followers): "He came in annoyed and left nodding. He followed you on the way out." Bubble: "ok. that's actually hard. keep it down tho"
   - bad: **EARPLUGS** (neutral, +5 Aura): "He listened, shrugged and went back to bed with earplugs in." Bubble: "it's fine. it's just loud"
3. "Put your headphones on and keep going." (sure)
   - good: **HEADPHONES ON** (neutral, +5 Aura): "You kept working, quietly. He never knocked again." Bubble: "much better. good night"

**`starter_kid`** (blockkid). Tag "THE BLOCK · TEACH ME". Line: "you make beats? for real? how do you get a placement on a real song?"

1. "Be honest. You're still working on yours." (sure)
   - good: **KEEPING IT REAL** (win, +15 Aura): "He liked that you didn't front. He says you'll get one before him. Barely." Bubble: "ok. you first. but barely"
2. "Show him your best beat." (odds 60)
   - good: **HE'S IMPRESSED** (win, +5 Aura, +100 Followers): "He played it for the whole block on his phone speaker." Bubble: "this is hard. i'm telling everybody"
   - bad: **HE'S NOT SURE** (neutral, +5 Aura): "He said it was ok. Kids are honest." Bubble: "it's ok. mine's gonna be better"
3. "Let him press a few pads." (sure)
   - good: **HIS FIRST BEAT** (win, +10 Aura): "He pressed every pad twice and called it his first beat." Bubble: "i'm a producer now. don't tell my mom"

**`starter_host`** (host). Tag "BEAT NIGHT · ONE SLOT LEFT". Line: "friday's beat night has one slot left. it's a cypher. you in?"

1. "Take the slot." (odds 55)
   - good: **MADE THE FINAL** (win, +10 Aura, +150 Followers): "You made it to the last round. People followed you on the way out." Bubble: "the final round? on your first night?"
   - bad: **OUT IN ROUND ONE** (neutral, +5 Aura): "You went out in round one and learned a lot from the winner." Bubble: "round one is where everybody starts. come back"
2. "Go and just watch this time." (sure)
   - good: **TOOK NOTES** (win, +10 Aura): "You watched every round and took notes on every winner." Bubble: "smart. watch first. next friday you play"
3. "Ask to play beats between rounds." (sure)
   - good: **BETWEEN ROUNDS** (win, +5 Aura, +50 Followers): "You played beats between rounds. A few people asked whose they were." Bubble: "people kept asking whose beats those were"

**`starter_landlord`** (landlord). Tag "AFTER MIDNIGHT · BIG SPEAKERS". Line: "my room's empty after midnight. play your beat loud. if people feel it, that's fire"

1. "Play your beat on his speakers." (odds 60)
   - good: **PEOPLE STOPPED** (win, +5 Aura, +150 Followers): "People walking by stopped to listen. Two of them followed you." Bubble: "see? loud and honest. that's how it starts"
   - bad: **QUIET NIGHT** (neutral, +5 Aura): "Nobody walked by tonight. He still said it sounded big." Bubble: "slow night. the beat's good tho"
2. "Ask him how he started." (sure)
   - good: **HIS STORY** (win, +10 Aura): "He started with one speaker and a borrowed laptop. Same as you." Bubble: "one speaker. one laptop. look at me now"
3. "Say thanks. Maybe next week." (sure)
   - good: **MAYBE NEXT WEEK** (neutral, +5 Aura): "He left you his number and the door code." Bubble: "after midnight. any night"

**The new people** (§ 3.3; kind `local`; existing signature pieces only, since Task 5d gives every visitor its B look):

| Id | Fiction (shown) | Parody | Style (name plate) | Signature | Colour |
|---|---|---|---|---|---|
| rapper | A RAPPER WITH A NOTEBOOK | A RAPPER WITH NO BEAT | needs a beat | headphones | 230, 90, 70 |
| cousin | YOUR OLDER COUSIN | YOUR BIG COUSIN | family | cap | 250, 140, 200 |
| neighbor | A SLEEPY NEIGHBOR | THE NEIGHBOR NEXT DOOR | next door | none | 120, 150, 190 |
| host | THE BEAT-NIGHT HOST | THE OPEN-MIC HOST | beat night | headset | 255, 200, 40 |
| landlord | THE LATE-NIGHT LANDLORD | THE STUDIO OWNER | late-night rooms | lanyard | 110, 85, 60 |

**Retired: `gentle_first`.**
- It was the superfan's first visit: "omg it's you!! can i get a photo?? i've been waiting outside all day", with FIRST FAN, SIGNED, and SNEAK PEEK / NOT DONE YET.
- Rather than leave a dead card, I removed it. Without `first` it could never be drawn: it is gated under visits 1, and the starters win visit 0.
- The cousin's third choice ("Play her something unfinished.") reuses its preview idea.
- A save whose stored next pick is `gentle_first` re-picks: an unknown card id gives no pick.

**The superfan's first appearance** (review Minor 4). With `gentle_first` retired, `tier_buzzing`'s "a thousand people follow you now. i was here first. never forget that" can now be the superfan's first appearance. When the cousin is drawn, `starter_cousin`'s tag "FAMILY · YOUR FIRST FAN" competes with it. Neither line is reworded; the question is on the approval list.

**Overlap with Day One (Task 5e).** 5e's first card is "JUNO VALE needs a beat by tonight. $50.", and the starter visitor follows the chain.
- I moved `starter_rapper` off that hook: he wrote a verse on the bus, and pays $40.
- He is still "an artist who needs a beat" right after one. 5e's design should decide whether he stays in the pool while Day One runs.

## 8. Pacing and the money guardrail

Fix round 1 (2026-11-11) only returned the sweep's lines to base's text. So the pacing output is byte-identical to 26542dc's (`cmp`), and every number below stands.

Every run uses `spec/pacing_spec.lua` (60 days, the fixture economy), on the 20-seed set and the recorded 200. The final column is what is built. "Starter drafts" is the pool before the controller's ruling of 2026-11-11, with no extra Aura; it is kept here because it explains the ruling.

| 200 seeds | Baseline (15ff936) | After the fiction pass | Starter drafts (superseded) | **Final: starters +5 Aura** |
|---|---|---|---|---|
| random share median (floor 0.3412) | 0.3592 | identical (the whole output byte-identical) | 0.3527 | **0.3514** |
| greedy / chaser / spend-down max (≤ 0.50) | 0.488 / 0.385 / 0.282 | identical | 0.490 / 0.393 / 0.293 | **0.490 / 0.387 / 0.284** |
| homer / climber max (≤ 0.50) | 0.428 / 0.429 | identical | 0.424 / 0.407 | **0.428 / 0.407** |
| THE HALL median (p10 ≥ 3, p90 ≤ 7) | 4 (3, 6) | identical | 4 (3, 6) | **4 (3, 6)** |
| Legend earliest, random / homer (≥ 15) | 17 / 17 | identical | 17 / 17 | **17 / 17** |
| climber THE HALL median (p90) | 4 (6) | identical | 4 (6) | **4 (6)** |
| phone Aura a day, random / climber (≤ 15) | 12.12 / 13.88 | identical | 12.29 / 13.85 | **12.14 / 13.89** |
| cold in 60 days (runs: random, greedy, chaser, spend-down) | 0, 0, 0, 0 | identical | 0, 0, 1, 0 | **0, 0, 0, 0** |
| cold check "never cold in days 1–7" | passes | passes | **fails** (chaser, seed 899819) | **passes** |

| 20 seeds | Baseline (15ff936) | Starter drafts (superseded) | **Final** |
|---|---|---|---|
| THE HALL median (p10, p90) | 4 (4, 5) | 4 (3, 6) | **4.5 (3, 7)**: the p90 sits at the ≤ 7 limit |
| random share median | 0.349 | 0.360 | **0.360** |
| greedy / chaser / spend-down max | 0.482 / 0.388 / 0.263 | 0.477 / 0.378 / 0.281 | **0.477 / 0.376 / 0.281** |
| homer max; Legend earliest | 0.394; 17 | 0.411; 17 | **0.410; 17** |
| climber THE HALL median (p90); max | 5 (6); 0.393 | 4.5 (6); 0.389 | **5 (6); 0.387** |
| phone Aura a day, random / climber | 12.14 / 13.81 | 12.00 / 13.86 | **12.41 / 14.28** |
| cold check "never cold in days 1–7" | passes | **fails** (chaser, seed 65537) | **passes** |

**Week-1 cold rate on 2,000 fresh seeds** (seed × 7919 + 13, 7 days), as random / greedy / chaser / spend-down:
- baseline: 4 / 0 / 0 / 7 (11 of 8,000).
- starter drafts: 2 / 2 / 2 / 9 (15 of 8,000).
- **final: 2 / 2 / 0 / 4 (8 of 8,000)**, under the baseline.

**Every money guardrail holds, and the full pacing spec passes.** `build/t46_check.lua` runs the same 20-seed assertions in Studio, and every one holds on the final numbers: THE HALL median 4..6, p10 ≥ 3, p90 ≤ 7, Legend ≥ 15, every share ≤ 0.50, phone pops > 0, phone Aura ≤ 15, every tier reached. t46 has no cold check and nothing tighter than pacing_spec.

**Why the starters pay +5 Aura (the controller's ruling of 2026-11-11).** The drafts tripped the cold check on one recorded seed in each set. In both runs the career chaser went cold on day 1, at −55:
- **Seed 65537.** It drew `starter_host`, which moved no Aura. Its walk-ins then cost −70 (−5, −15, −10, −30, −10). Six phone pops netted −45, three of them scams it paid for.
- **Seed 899819.** It drew `starter_kid` (+5), then lost −15, −30, −40, −15 and −10.
- **The cause.** A control run, the new `Pick` with the old deck (gentle_first the only `first` card), kept both seeds warm, though the sim's Lcg still steps once at visit 0. So the cause was the starters' own branch, not the extra draw.
- **The ruling.** The controller chose option (a), measured before it was chosen: +5 Aura on every one of the 24 starter outcomes, tones as drafted, no other number moved. That gives the starters the first-visit Aura cushion gentle_first gave: its wins paid +5 or +10, its neutral outcome 0.
- **Not variants.** A wins-only version and any other variant were ruled out: choosing values until seeds pass would be tuning to the test.
- **The open question.** Whether the per-seed check should become a rate is a spec change. The controller is taking it to you separately.

## 9. For Task 5d (listed, not changed): not needed while the parody names stay

This list was for a fiction launch. While the parody names stay, the parody looks are on purpose, so Task 5d needs none of it. Keep it for a later switch to fiction.

These signature pieces in `Modules/Visitor.lua`, and the body colours in `Data/WalkIns`, cue the real artist the parody name sounds like:

| Visitor | Piece and colour | The cue |
|---|---|---|
| navx (PEONY ROLLER) | `cowboy_hat`, pink body (255, 110, 180) | the parodied artist's pink-and-western look. The B recipe's peony bloom can stay; its denim, boots and neckerchief were the country cue (a roller-skate look fits disco trap) |
| drizzle (DUSK CASTELLO) | `owl_hood` | the owl emblem of the parodied artist's brand |
| eyelash (MOSS LULLABY) | `green_roots`, green body (120, 255, 120) | the parodied singer's green-root hair |
| icespike (SLEET VANTA) | `spiky_hair` in orange (255, 140, 50) | the parodied rapper's orange curls |
| drift (SEQUIN MAPLE) | `sparkle_cape` (gold neon sparkles) | the parodied singer's sequined tour costumes |
| scoot (ORBIT DUNE) | `helmet` with a visor | the parodied rapper's astronaut and space imagery |
| dojabat (HEX VELOUR), llama (QUILL MESA) | `bat_ears`; `llama_ears` and snout | puns on the parody names. In fiction they read as plain animal ears, but still echo the puns |

The five new starter visitors use existing pieces (headphones, cap, none, headset, lanyard), and Task 5d gives them B recipes too.

## 10. Tests

- **`build/t80_check.lua` (Edit): the fiction fallback still swaps every name** (fix round 1).
  - **How it runs.** Each roster is forced inside its own scope on a fresh Config copy, and the configured roster is put back afterwards, as t70 does. Nothing asserts the live roster's value.
  - (a) **Fiction.** Every visitor and sponsor gets a fiction name of its own, and no rendered name holds a parody or a real name. No `{name:<id>}` fill in any card, follow-up, waiting or parting string shows a parody name.
  - (b) **Both rosters.** No shipped string holds a real name: 47 whole-word tokens over about 12,900 strings a roster. The tokens skip the words the approved parody names share on purpose (doja, kendrick, playdoh).
  - (c) **F6**, for all 12 sponsor names in both rosters, by `TextService:GetTextSize`.
  - **Red and green.** A CLI replica of (a) and (b) passes on base 15ff936 and now. In Studio, (c) is red before the sync, because the place still has the old warning text.
- **`build/t81a_play_server.lua` (play, new):**
  - the real first-ever timer brings a starter.
  - forced draws 1..6 at count 0 reach every starter exactly once (`distinct == #STARTERS`, review Minor 7).
  - none comes at count 1.
- **Updated:**
  - `t41_check` is back to base (Roster is parody).
  - `t44_check`'s ticker literal: pure formatting, any name.
  - `t70_check` puts back the configured roster, not a literal.
  - `t53` and `t76a`: the first walk-in is any starter; t76a expects HintFor's hint on it, then clears the hints.
- **Specs:**
  - `walkin_rules_spec`: the pool draw, and starters all at weight 0 falling through to the least-seen pool (review Minor 6).
  - `career_sim_spec`: two starters; each comes first on some seed, never again.
  - `walkins_data_spec`:
    - the pool's rules, and every starter outcome paying at least +5 Aura (review Minor 5).
    - 600 live-deck draws at visits 0, all starters and all six reached; none at visits 1.
    - the `check` pattern also accepts this file.
  - `life_rules_spec`: PEONY ROLLER under the forced fiction roster.

## § Approval list

### Live now

**F6**
- [ ] `sponsor_warning`'s result text, both sides: "{sponsor} warned you instead of dropping you. Get your aura back over their bar before they check again." → "{sponsor} warned you. Get your aura back over their bar before they check again." (§ 5).

**The starter pool** (§ 7; every line is new)
- [ ] The six cards' words: tags, lines, choices, headlines, results, bubbles, and the rapper's note.
- [ ] Their numbers, with the +5 Aura on every outcome (the controller's ruling of 2026-11-11, § 8):
  - rapper: $40 and +5 Aura, sure; +100 Followers and +5 Aura; two beats at odds 60 for $80 and +5 Aura, or $40 and +5 Aura.
  - cousin: +150 Followers and +5 Aura; +100 Followers and +5 Aura; odds 60 for +200 Followers and +5 Aura, or NOT YET's +5 Aura.
  - neighbor: +15 Aura; odds 50 for +100 Followers and +10 Aura, or EARPLUGS' +5 Aura; HEADPHONES ON's +5 Aura.
  - kid: +15 Aura; odds 60 for +100 Followers and +5 Aura, or HE'S NOT SURE's +5 Aura; +10 Aura.
  - host: odds 55 for +150 Followers and +10 Aura, or OUT IN ROUND ONE's +5 Aura; +10 Aura; +50 Followers and +5 Aura.
  - landlord: odds 60 for +150 Followers and +5 Aura, or QUIET NIGHT's +5 Aura; +10 Aura; MAYBE NEXT WEEK's +5 Aura.
- [ ] The +5 AURA chip on the seven neutral outcomes (NOT YET, EARPLUGS, HEADPHONES ON, HE'S NOT SURE, OUT IN ROUND ONE, QUIET NIGHT, MAYBE NEXT WEEK): keep them neutral, or make them wins (§ 7).
- [ ] The starter pool's people, both names each (§ 3.3, § 7):
  - shown now (parody): A RAPPER WITH NO BEAT, YOUR BIG COUSIN, THE NEIGHBOR NEXT DOOR, THE OPEN-MIC HOST, THE STUDIO OWNER.
  - the fiction twins: A RAPPER WITH A NOTEBOOK, YOUR OLDER COUSIN, A SLEEPY NEIGHBOR, THE BEAT-NIGHT HOST, THE LATE-NIGHT LANDLORD.
  - their styles.
- [ ] The random first visitor, and retiring `gentle_first` (the superfan comes with BUZZING).
- [ ] The superfan note (§ 7; review Minor 4). `tier_buzzing`'s "i was here first" can now be the superfan's first appearance, and `starter_cousin`'s tag "FAMILY · YOUR FIRST FAN" competes with it. Neither is reworded.
- [ ] The cold check "never cold in days 1–7 on the recorded seeds". The controller kept it and built the +5 Aura. Whether it should become a rate is your call, and the controller is asking you separately (§ 8).

### When switching to fiction (parked)

**The switch**
- [ ] `Config.WalkIns.Roster = "fiction"`. Both rosters share the card text, so the clean lines below go in with it (§ 1).

**Names** (built in the fiction column, shown after the switch)
- [ ] navx: STIRRUP PEONY → **PEONY ROLLER** (§ 3.1: the rodeo cue).
- [ ] dojabat: VELVET FANG → **HEX VELOUR** (§ 3.1: the filed VELVET FANG games mark: [owner](https://trademarks.justia.com/owners/velvet-fang-llc-4423564), [88957475](https://trademark.justia.com/889/57/velvet-88957475.html), [97747783](https://trademarks.justia.com/977/47/velvet-97747783.html)).
- [ ] drizzle: HOOT CASTELLO → **DUSK CASTELLO** (§ 3.1: the owl cue).
- [ ] sneakers: KICKFLIP FOOTWEAR → **SOLEPOP SNEAKERS** (§ 3.2: the [KICKFLIPS footwear mark](https://trademarks.justia.com/852/28/kickflips-85228412.html) and [KickFlip, the K-pop group](https://www.koreatimes.co.kr/amp/entertainment/k-pop/20250120/kickflip-debuts-as-jyps-new-spin)).
- [ ] Kept and flagged (§ 6): SLEET VANTA, ORBIT DUNE, SEQUIN MAPLE, MOSS LULLABY, STATIC GOBLIN, NITE OWL ENERGY.

**Genres** (styles, and the first half of every tag)
- [ ] country trap → disco trap; chaotic pop rap → spooky pop; drill pop → phonk; rage rap → noise rap; space trap → synthwave; lyrical rap → boom bap; sparkle pop → bubblegum pop; late night r&b → neo soul; whisper pop → lo-fi.

**Card lines** (§ 4: every line old → new, to re-apply from d33d69a)
- [ ] PEONY ROLLER: strings in place of the banjo; the roller-skate video; the disco loop DM.
- [ ] HEX VELOUR, SLEET VANTA: the tags only.
- [ ] STATIC GOBLIN: the shelf in place of the vault; "THE BIG YEAR"; the payback's TRACK ONE headline.
- [ ] ORBIT DUNE: synth layers; the five-minute song; the planetarium laser show; the label review.
- [ ] QUILL MESA: the soul loop; the festival opener in place of the halftime show.
- [ ] SEQUIN MAPLE: hooks and intros in place of bridges; the tease; karaoke versions; fan keychains.
- [ ] DUSK CASTELLO: candlelight in place of 2 am; slow-jam playlists; the slow dancers.
- [ ] MOSS LULLABY: hummed; LULLABY BEAT.
- [ ] § 4's to-do list:
  - the residual cue lines: STATIC GOBLIN's "maybe never" and "one day. maybe"; `drift_session`'s re-record shape; MOSS LULLABY's breathing.
  - the two judgment calls: "Hide a tiny melody only fans would notice." and "OWN YOUR MASTERS".

**Task 5d**
- [ ] § 9's signature pieces, and the body colours that cue a real artist.
