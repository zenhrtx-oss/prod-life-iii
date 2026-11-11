# Walk-in names: web check (2026-10-23)

Task 4 of the walk-ins plan. Every fiction artist name and every sponsor name (both rosters) was web-checked before it went into `src/ReplicatedStorage/OK/Data/WalkIns.lua`. The nine parody artist names are user-approved as they are (LIL NAV X, DOJA BAT, ICE SPIKE, PLAYDOH CHARTI, TRAVIS SCOOT, KENDRICK LLAMA, TAYLOR DRIFT, DRIZZLE, BILLIE EYELASH) and were not re-checked.

## Verdict rule (written before searching)

- Every name gets two WebSearch queries: `"<NAME>" rapper OR singer OR band` and `"<NAME>" company OR brand`.
- **Replace** a fiction artist name when the exact name (ignoring case and spacing) belongs to a real performing act (artist, band, DJ, producer with releases) that the results show.
- **Replace** a sponsor name (either roster) when the exact name (ignoring case and spacing) is a real, operating company or brand that the results show.
- **Keep** a name when the results show only partial matches (one word of the name, a longer name containing it, a different spelling), dictionary or place uses, or nothing.
- Every replacement is checked again with both queries and recorded below.
- These are the builder's proposals. The user approves the sponsor names (both sets) and the fiction artist names in Task 10.
- **Added after review (fix round 1, 2026-10-23):** also replace a fiction artist name when any word in it is a title (song, album) or name tied to one of the nine parodied artists. The fiction roster exists as moderation cover, so it must not point back at the real people it replaces. How the words were checked is described under "Catalogue check" below.

## Fiction artist names (drafted in Task 4)

| Visitor id | Parody (approved) | Fiction draft | `"<NAME>" rapper OR singer OR band` | `"<NAME>" company OR brand` | Verdict |
|---|---|---|---|---|---|
| navx | LIL NAV X | RODEO HALO | no act by that name (only Travis Scott's album *Rodeo*, a Finnish band RODEO, singers called Halo) | none (Smarty Rodeo, Rodeo Life, the HALO grill brand) | kept in round 1; **replaced in fix round 1 → STIRRUP PEONY**. "Rodeo" is the parodied artist's own song (with Cardi B, on the 2019 EP *7*; a Nas remix was released as a single in January 2020 after they performed it at the Grammys). It is also the title of Travis Scott's album, and TRAVIS SCOOT is in this roster. The cowboy-hat, country-trap visitor would carry the real artist's own title under `Roster = "fiction"`. |
| dojabat | DOJA BAT | VELVET FANG | none (Latino Velvet, Velvet, Fang, Ice Fang) | none (apparel brands called Velvet) | keep |
| icespike | ICE SPIKE | SLEET VANTA | none (several acts called Vanta, VANTA01, Vanta Black) | none (Vanta the security software company) | keep |
| charti | PLAYDOH CHARTI | STATIC GOBLIN | none (Static & Ben El, Static-X, Kid Static, Goblin Band) | none (Goblin Gaming, goblin toy lines) | keep |
| scoot | TRAVIS SCOOT | ORBIT DUNE | none (Orbit, Dune, Orbit Culture) | none (Orbit Irrigation, Orbit Baby, Dune London) | keep |
| llama | KENDRICK LLAMA | QUILL MESA | none (Quill, Kid Quill, Lil Quill) | none (Quill Corporation, Mesa Supplies) | keep |
| drift | TAYLOR DRIFT | SEQUIN MAPLE | none (Sequin, Maple, Sequence) | none (maple syrup brands) | keep |
| drizzle | DRIZZLE | HOOT CASTELLO | none (Marco Castello, Chris Castello, Myles Castello) | none (Castello pipes, Castello d'Oro) | keep |
| eyelash | BILLIE EYELASH | MOSS LULLABY | none (George Moss, Fresh Moss, Moss) | none (Moss & Fawn, Moss Studio, Lullaby baby goods) | keep |

Replacement for RODEO HALO (fix round 1). Every candidate got both queries. The shipped name's words were also checked against the nine parodied artists' catalogues (see "Catalogue check"):

| Candidate | rapper/singer/band query | company/brand query | Title/name check | Verdict |
|---|---|---|---|---|
| SADDLE NEON | none by that exact name (Saddles, Se So Neon, Neon Dreams, NEON) | none (a Decathlon saddle pad with neon piping, neon sign makers) | a follow-up search found **Neon Saddle**, a cover band whose set list includes the parodied artist's breakout song | **rejected**: the same words in reverse order name a band that plays the real artist's song |
| STIRRUP PIXEL | none (Pixel Grip, Star Pixel, Pixels) | none (PIXEL, Pix, stirrup makers); a reverse-order search found nothing | not checked against the catalogues (dropped first) | clean, **not used**: "Pixel" is a well-known phone product line |
| STIRRUP PEONY | none (Birthing Stirrups, St47ic, STi) | none (stirrup leather brands, a stirrup buckle earring) | neither word appears anywhere in the nine artists' discography wikitext (see "Catalogue check") | **keep** (shipped) |

### Catalogue check (fix round 1)

- **Method.** A combined WebSearch, a song called "Peony" or "Stirrup" by any of the nine artists, returned only museum pages about stirrups, so it settled nothing. I then downloaded the raw wikitext of the artists' English Wikipedia discography and song-list pages and searched each one for the words, case-insensitive. The pages: Lil Nas X discography; Doja Cat discography; Ice Spice discography; Playboi Carti discography; Travis Scott discography; Kendrick Lamar albums discography, singles discography and list of songs recorded; Taylor Swift albums discography, singles discography and list of songs; Drake albums discography and singles discography; Billie Eilish discography and list of songs recorded. That is 15 pages for the nine artists, all checked as real wikitext. Three other song-list URLs returned an error page and two Drake URLs were redirects to his main article; none of those five were used.
- **Control.** The same grep finds "rodeo" (8 hits on Lil Nas X's page, 14 on Travis Scott's), "old town road" (7, Lil Nas X) and "halley" (3, Billie Eilish), so the method sees titles when they are there.
- **Result for STIRRUP PEONY.** No page contains "peony" or "stirrup".
- **The other eight fiction names, same pages, whole-word search.** No page has velvet, fang, sleet, vanta, goblin, orbit, dune, quill, mesa, sequin, maple, hoot, castello, moss or lullaby. "Static" appears only in billboard.com reference URLs (`static.billboard.com`) and once as the name of a guest singer on a Drake single ("After Dark", featuring Static Major). It is not in any title. STATIC GOBLIN stays; the user may still weigh this in Task 10.
- **Limits.** Wikipedia lists charted, certified and album songs. Deep cuts, leaks, features on other artists' albums and anything after the pages' last edit may be missing.

## Sponsors: parody roster (proposed: RED BULB, NYKE, BEETS BY DRAY, SPOTIFLY, ROLEKS, PRYME)

| Name | rapper/singer/band query | company/brand query | Verdict |
|---|---|---|---|
| RED BULB | none (REDi, RED., Red aka Tha Rising Sun) | no company named Red Bulb; results were Red Bull and red light bulbs | keep |
| NYKE | Denver rapper **Nyke Nitti** (formerly Nyke Loc), a longer name | no company; every result was Nike | keep (no exact company/brand) |
| BEETS BY DRAY | none (Dray10, Dray Yard) | none (beet food brands) | keep |
| SPOTIFLY | none | **an app called "Spotifly – музыка онлайн" on RuStore** (a music player built to look like Spotify; ~9,000 downloads); Spotify also sues look-alike names | **replace → SPOTIFRY** |
| ROLEKS | none | **"Roleks" is how Rolex is spelled in Serbian**; a Serbian news headline names Rolex "Roleks" | **replace → ROWLECKS** |
| PRYME | **Pryme**, a Nigerian Afropop singer; Pryme Kingz (UK); Its Pryme Tyme | **Pryme N.V.** (listed cleantech company, Euronext Growth Oslo), Pryme Group Limited (UK) | **replace → PRIYME** |

Replacements, checked again with both queries:

| Name | rapper/singer/band query | company/brand query | Verdict |
|---|---|---|---|
| SPOTIFRY | none (results only about Spotify charts) | none (results only about Spotify) | keep |
| ROWLECKS | none (Rowdy Superstar, Rowlan, Rowlene) | none (Rowlett Rutland, Rowleys Ltd) | keep |
| PRIYME | none (PRhyme, Pryme Kingz) | none (Prym, Priam, Primo Brands) | keep |

## Sponsors: fiction roster (proposed: NITE OWL ENERGY, KICKFLIP FOOTWEAR, LOUD HEADPHONES, GLOW GUM, STACKS BANK, DRIP WATER)

| Name | rapper/singer/band query | company/brand query | Verdict |
|---|---|---|---|
| NITE OWL ENERGY | rapper **Nite Owl** (St. Louis); no act with "Energy" | none (Green Owl Energy Solutions, White Owl Energy Services, Night Owl Optics) | keep |
| KICKFLIP FOOTWEAR | K-pop group **KickFlip** (JYP); no footwear link | none; a "KICKFLIPS" trademark (KICKFLIPS LLC) covers footwear, and Airwalk sells a "Kickflip" sneaker model | keep (no exact company/brand; the user may still prefer to rename it) |
| LOUD HEADPHONES | none | **Loud Headphones**, a headphone brand founded in 2013 by skateboarders Mike Anderson and David Broach (also Loudheadphones LLC) | **replace → THUMPCAN HEADPHONES** |
| GLOW GUM | none (Glow, GUM, The Gum) | none (Glee Gum, Ford Gum, Sour Patch Kids Glow Ups) | keep |
| STACKS BANK | none (MoStack, Stack Bundles) | none (software companies called Stacks; STACK Fintech) | keep |
| DRIP WATER | (results were about the brand) | **Drip Water**, a UK canned mineral water brand co-founded in 2023 by the rapper Big Zuu, sold in Morrisons | **replace → SIPWAVE WATER** |

Replacements, checked again with both queries:

| Name | rapper/singer/band query | company/brand query | Verdict |
|---|---|---|---|
| THUMPCAN HEADPHONES | none | none (Thump Bluetooth headsets, Oakley Thump, Mackie THUMP speakers, Dandycan) | keep |
| SIPWAVE WATER | none (Syps, Aitch's water brand) | none (SportWave vitamin water, discontinued) | keep |

## As shipped in `Data/WalkIns.lua`

Sponsor slots pair one parody name with one fiction name. Ids are neutral, so a rename touches only `names`.

| Sponsor id | Parody | Fiction | Note |
|---|---|---|---|
| energy | RED BULB | NITE OWL ENERGY | |
| sneakers | NYKE | KICKFLIP FOOTWEAR | |
| headphones | BEETS BY DRAY | THUMPCAN HEADPHONES | |
| streaming | SPOTIFRY | GLOW GUM | The proposed fiction set has no streaming brand, so rep card text never names a product category. |
| watches | ROWLECKS | STACKS BANK | Same pairing note. |
| water | PRIYME | SIPWAVE WATER | |

Fiction artist names: STIRRUP PEONY, VELVET FANG, SLEET VANTA, STATIC GOBLIN, ORBIT DUNE, QUILL MESA, SEQUIN MAPLE, HOOT CASTELLO, MOSS LULLABY. (STIRRUP PEONY replaced RODEO HALO in fix round 1; see the navx row.)

Fiction role names: the five non-artist visitors are worded differently in each roster, so no fiction display name equals a parody one.

## Limits of this check

- These were US web searches on 2026-10-23, not trademark searches. A small or unindexed business may still use one of these names.
- The parody names point at real people and brands on purpose; that is the user's call (design §4.10). The `Config.WalkIns.Roster = "fiction"` switch is the fallback.

## Sources

- Rodeo Halo: https://en.wikipedia.org/wiki/Rodeo_(Travis_Scott_album), https://www.dallasmarketcenter.com/exhibitors/smarty-rodeo/, https://rodeolife.com/?p=5462
- Rodeo, the replacement reason: https://en.wikipedia.org/wiki/Rodeo_(Lil_Nas_X_and_Cardi_B_song), https://en.wikipedia.org/wiki/7_(Lil_Nas_X_EP), https://www.rollingstone.com/music/music-news/lil-nas-x-rodeo-remix-nas-943753/
- Saddle Neon: https://en.wikipedia.org/wiki/Neon_Dreams, https://www.phoenixnewtimes.com/?p=40549050, https://www.decathlon.ch/en/p/mp/saddle-pad-onion-quilt-leather-neon-jumping-blue/ad4683e4-81f3-4a01-8a29-860d0cb18a8d/c148, https://www.bookece.com/artists/neon-saddle/songs/
- Stirrup Pixel: https://en.wikipedia.org/wiki/Pixel_Grip, https://soundcloud.com/starpixelmusic, https://www.cbinsights.com/company/pix
- Stirrup Peony: https://birthingstirrups.bandcamp.com/, https://episteme.tllm.fr/wiki/St47ic, https://shop.app/products/6739708248273/stirrup-buckle-earring, https://trademark.justia.com/owners/equestrian-international-products-651427
- Catalogue check (raw wikitext, `https://en.wikipedia.org/w/index.php?title=<page>&action=raw`): Lil_Nas_X_discography, Doja_Cat_discography, Ice_Spice_discography, Playboi_Carti_discography, Travis_Scott_discography, Kendrick_Lamar_albums_discography, Kendrick_Lamar_singles_discography, List_of_songs_recorded_by_Kendrick_Lamar, Taylor_Swift_albums_discography, Taylor_Swift_singles_discography, List_of_songs_by_Taylor_Swift, Drake_albums_discography, Drake_singles_discography, Billie_Eilish_discography, List_of_songs_recorded_by_Billie_Eilish
- Velvet Fang: https://www.wikipedia.com/wiki/Velvet_City, https://Www.wikipedia.org/wiki/Fang_(band), https://apparelnews.net/news/2017/apr/03/velvet-acquired-japanese-company
- Sleet Vanta: https://ra.co/dj/vanta-de/biography, https://sonicbids.com/vanta-black, https://en.wikipedia.org/wiki/Vanta_(company)
- Static Goblin: https://en.wikipedia.org/wiki/Goblin_Band, https://www.qobuz.com/ca-en/interpreter/kid-static/901148, https://open.endole.co.uk/insight/brand/236104-goblin-gaming
- Orbit Dune: https://en.wikipedia.org/wiki/Orbit_(American_band), https://en.wikipedia.org/wiki/Dune_(band), https://Www.wikipedia.org/wiki/Dune_London
- Quill Mesa: https://en.wikipedia.org/wiki/Quill_(band), https://en.wikipedia.org/wiki/Kid_Quill, https://en.wikipedia.org/wiki/Quill_Corporation
- Sequin Maple: https://sequinsequin.bandcamp.com/community, https://www.last.fm/music/Maple/+wiki
- Hoot Castello: https://en.wikipedia.org/wiki/Marco_Castello, https://www.sonicbids.com/band/chris-castello/
- Moss Lullaby: https://en.wikipedia.org/wiki/George_Moss_(rapper), https://www.wikipedia.org/wiki/Fresh_Moss
- Red Bulb: https://www.redbull.com/mea-en/energydrink/questions/, https://www.bulbs.com/Red+Bulb-Color/results.aspx
- Nyke: https://www.westword.com/music/friday-rap-up-nyke-nitti-dr-dre-the-game-dmx-5692626/, https://digital.fidelity.com/prgw/digital/research/quote/dashboard/summary?symbol=nke
- Beets by Dray: https://www.thedailymeal.com/1317743/store-bought-beet-brands-ranked
- Spotifly: https://www.rustore.ru/catalog/app/com.harsh.shah.saavnmp3, https://www.tramatm.com/trademark-hall-of-fame/spotify
- Roleks: https://www.021.rs/info/biznis-i-ekonomija/212734/roleks-cetvrtu-godinu-najuglednija-kompanija-na-svetu, https://en.wikipedia.org/wiki/Rolex
- Pryme: https://en.wikipedia.org/wiki/Pryme, https://live.euronext.com/en/products/equities/company-news/2024-09-12-pryme-nv-investor-presentation-12-september-2024, https://pay.company-information.service.gov.uk/company/01242917
- Spotifry / Rowlecks / Priyme: https://www.sec.gov/Archives/edgar/data/1639920/000163992025000003/Financial_Report.xlsx, https://en.wikipedia.org/wiki/Rowlett_Rutland, https://en.wikipedia.org/wiki/PRhyme, https://en.wikipedia.org/wiki/Prym
- Nite Owl Energy: https://www.stlamerican.com/entertainment/living-it/nite-owl-swoops-the-duck-room/, https://www.owler.com/company/niteanddaypower/competitors
- Kickflip Footwear: https://www.koreatimes.co.kr/amp/entertainment/k-pop/20250120/kickflip-debuts-as-jyps-new-spin, https://trademark.justia.com/owners/kickflips-llc-2224309, https://www.walmart.com/ip/14998623656
- Loud Headphones: https://routeone.eu/blogs/news/loud-headphones-benefiting-the-deaf, https://trustburn.com/reviews/loudheadphones-com
- Glow Gum: https://www.nombase.com/companies/glee-gum, https://en.wikipedia.org/wiki/Ford_Gum
- Stacks Bank: https://en.wikipedia.org/wiki/MoStack, https://trademarks.justia.com/owners/stack-fintech-inc-3399251
- Drip Water: https://www.foodmanufacture.co.uk/Article/2025/01/31/drip-water-4m-investment-to-fund-expansion-into-the-middle-east, https://www.wateronline.com/doc/drip-water-valued-at-m-following-investment-from-raya-holding-0001
- Thumpcan Headphones: https://sponsorpitch.com/sponsors/thump, https://www.oakleyforum.com/threads/anyone-tried-the-oakley-thumps.145296/post-1938177
- Sipwave Water: https://www.bevnet.com/brands/sportwavewater, https://www.grocerygazette.co.uk/2024/01/30/aitch-syps-fizzy-water-iceland/
