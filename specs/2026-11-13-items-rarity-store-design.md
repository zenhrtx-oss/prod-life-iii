# Items, rarity and the store

2026-11-13. **DRAFT for the user's approval.** This is the design for Prod Life III's items layer: more clothing, furniture, studio gear and sound upgrades, rarity tiers, showing off stats, and what Robux buys. It comes from a chat with the user (Zenji) on 11-13 03:11–03:26.
- What the user said is quoted.
- Everything else is marked **Claude's call** and can be switched.
- The user chose "Design it now, build later". The build takes its turn in the agreed order: rooms → first 20 minutes → people → endless play.
- A small store must exist at launch, so this design's launch part is built before launch.
- **What "the launch part" is** (the user, 11-13 ~03:33, chose "Store slice + the earned basics"):
  - **At launch:** the small store (looks and the VIP pass); about 100 new items, as a target and not a hard gate; the stats wall and the profile card; the "this server" leaderboard.
  - **After launch:** global NUMBERED drops (a numbered run shared by every server needs a cross-server counter); the global leaderboard; records and awards (endless play §6 already lists them after launch); the season pass; Robux sound packs (§5).

## 1. Why

The user, 11-13 03:11: "What about designing more items, furniture, clothing, studio gear, sound upgrades, tiers of rarity,, specific monetization".

A player a month in should be proud to show a friend their studio. The user's answer to "what are they proudest of?" was all of these:
- "Something only they earned"
- "A numbered rare drop"
- "A fit or studio look they picked"
- "Their gear and sound"
- "There stats, maybe exclusive sounds or soundkits, or outfits"

## 2. What the user decided

| Question | The user's answer |
|---|---|
| Proudest of | "Something only they earned, A numbered rare drop, A fit or studio look they picked, Their gear and sound, There stats, maybe exclusive sounds or soundkits, or outfits" |
| Robux can buy | "Clothes and accessories, Furniture and studio themes, Sound kits and banks, Producer tags and passes" |
| Rarity | "Whatever you think", then after the playback: "Robux can buy some legendary" |
| Kits (the rack sells kits for Money; the money plan lists paid kits) | "Whatever you think" |
| Showing stats | "A stats wall in the studio, A profile card, Leaderboards, Records and awards" |
| When the store opens | "Small store at launch" (this replaces 11-05's "the store isn't on the launch list") |
| Robux-only exclusives | "Whatever you think" |
| Sound and gear upgrades | "Speakers and monitors, Sound kits and instruments, Mics, interfaces, outboard, Room acoustics / vibe" |
| New items at launch | "100+" |
| Passes | "Both": a VIP pass at launch and a season pass in a later update |
| Real fashion brands (the CELINE hoodie) | "Keep them in for now" |
| Earned vs Robux | "Mostly earned" |
| What ships at launch | "Store slice + the earned basics" |
| Real-brand items sold for Robux? | "Earn only never sold for now maybe we well them with slitly diffrent renders so people know what its mimicking obviusly." |
| How items get made | "Mix: Blender + code-built" |
| Leaderboards: who they compare | "Whatever you think" |

**Already decided, and still binding:**
- **Monetization (11-12):** ChatGPT's plan §7, `external_briefs/2026-11-11-chatgpt-master-plan.md`, as the tracker's "Already decided" records it.
  - **Sell:** creativity, identity, style and how prestige is shown.
  - **Keep free:** a strong free toolkit, every career path, the basic instruments, and a fair shot in competitions.
  - **Never:**
    - better odds on cards
    - paywalling a music feature you need
    - pay-to-win contests
    - selling during a story failure
    - fake scarcity
    - gambling loops
    - Robux mystery boxes at launch
    - selling the achievement itself: "a plaque frame, yes; the plaque, no"
- **Aura-giving fits are earn-only; paid fits are looks only** (Claude's note on that plan, kept).
- **Licensed audio only.** APMOfficial or ProSoundEffects, checked by t13/t14. Claude never uploads anything. Real Robux products (game passes, developer products) are set up by the user in Creator Hub; Claude builds the code with placeholders.
- **Aku owns the beat maker's design** (due 11-17): how kits, voices and sounds plug in, and any sound taxonomy.
- **Endless play §4.8:** items are granted once, keepsakes never change, and owned items are stored apart from career state (a new era keeps them). Plan 3's grant ledger and `ItemKey`.
- **Brand marks stay a swappable layer** (a takedown risk). Kept in for now by the user.

## 3. The item families

About **100+ new items** (the user's number; at launch it's a target of about 100, not a gate), on top of today's gear rack (tools, two voices, two kits, neons, plates, three fits, two speaker tiers) and the 12-piece room catalog. **Claude's call:** the target split, which a builder may move by ±10 per family:

| Family | Launch target | What it is |
|---|---|---|
| Clothes and accessories | ~30 | Tops, bottoms, hats, chains, glasses, shoes. Includes Codex's pilot hoodie, the CELINE-style hoodie and the graffiti set |
| Furniture and decor | ~30 | Seating, desks, shelves, rugs, lamps, plants, crates, art. Beyond the 12 starters |
| Studio themes | ~6 | A whole-room look: wall colour, floor, trim, light colour. Applied per room |
| Studio gear: placed | ~15 | Mics, mic stands, interfaces, outboard racks, keyboards, turntables, acoustic panels and bass traps. Mostly looks; a later vocal-booth feature may read them |
| Speakers and monitors | +2 tiers | Above today's desk monitors (tier 2) and studio monitors (tier 3). Louder, fuller playback of your beat in your room |
| Room vibe | ~6 | Light strips, neon signs, smoke or haze, a lava lamp: changes how the room looks while your beat plays |
| Sound kits and instruments | ~8 | New drum kits, 808 packs and keys voices. **Aku decides how they plug in**; until then each is a `Config.Gear` kit or voice row like today's |
| Producer tags and frames | ~6 | Nameplate styles, a producer tag look, profile-card frames |

**How they get made (the user: "Mix: Blender + code-built"):**
- **Blender, by Codex.** Hero pieces: all clothes, signature items, key studio gear. Built with the `ok_assets` pipeline, then imported by the user.
- **Code-built from parts, by Claude.** Simple furniture, decor and panels, with no uploads, like today's room catalog. Each item is at most `Config.Rooms.ItemParts` parts.

## 4. Rarity (Claude's call, with the user's change)

- **The tiers, lowest first:**
  - STANDARD
  - RARE
  - LEGENDARY
  - **NUMBERED** on top. A NUMBERED item is a LEGENDARY item with a serial and a history, for example "Phantom 808 #042/300, earned day 31".
- **Robux can buy STANDARD, RARE and some LEGENDARY looks** (the user: "Robux can buy some legendary").
  - Looks only: clothes, furniture, themes, frames.
  - A bought LEGENDARY says so in its origin line ("from the store"). An earned one names how it was earned. Nobody is misled about which is which.
- **Earned-only (Claude's call):**
  - every NUMBERED item
  - LEGENDARY sounds (kits and voices)
  - signature kits from people you've worked with
  - record awards

  This follows "never selling the achievement itself" and the user's "Something only they earned".
- **NUMBERED comes after launch.** A run like "#042/300" is shared by every player on every server, so it needs a cross-server counter that never hands out the same number twice.
- **NUMBERED runs are real limits, earned by skill or story, never sold.** They count toward the "fake scarcity" rule only if sold, and they aren't. A run's size is fixed when it is announced.
- **No trading at launch (Claude's call).** Trading invites scams and real-money markets. It is recorded as after launch.
- **How rarity shows:** a coloured frame in the gear rack, the closet and the decorate bar, plus the origin line (§8). The colours and words go to the copy approval.

## 5. Earning and buying

- **"Mostly earned"** (the user). **Claude's call:** about 70% of the 100+ items are earnable with in-game Money, story, records or skill; about 30% are in the store.
- **Money buys function, Robux buys a different look (Claude's call).**
  - Things that change what you can do or hear are earnable with Money or story: core kits, speaker tiers, beat-maker tools.
  - Robux sells visual variants and style packs.
- **Kits, three kinds (Claude's call; this settles the rack-vs-paid-kits conflict):**
  1. **Core kits:** on the rack for Money, as today. They're your sound growing with your career.
  2. **Robux style packs:** different flavours, never better sounding, never required by any request.
  3. **Signature kits:** earned-only, from people you've worked with and records.

  Aku's design decides where each sits in the beat maker.
- **An item is either earned or sold, never both (Claude's call, from the builder check).** Earned items are never in the store, and store items are never earned. Robux can't skip a Money or story unlock, and plan 3's one key per item (`ItemKey`) stays simple. A look sold in the store and an earned look are different catalog rows.
- **Robux sound packs wait (Claude's call).** They join the store only after Aku's beat-maker design lands (due 11-17) and each paid pack's licensed audio is checked. A test also proves no request ever needs a paid pack. The launch store is looks and the VIP pass.
- **Exclusives (Claude's call):**
  - Some outfits, room themes and sound style packs are Robux-only (never better, just different).
  - Earned-only exclusives are §4's list.
  - Nothing that affects how well you play is Robux-only.
- **Prices:** chosen by the user from Codex's bands in `design_input/codex/catalog_options_2026-11-13.txt`, three Money bands and three Robux bands per family. Today's prices and gates don't change (speakers $500 / $3,000).

## 6. Showing off your stats

The user chose all four:
1. **A stats wall in your studio.** A placeable board showing your hits, placements, followers, cypher wins and records, read live. Visitors see it.
2. **A profile card.** What others see when they look at you: rank, top stats, best keepsakes and your producer tag.
3. **Leaderboards.** **Claude's call:** both kinds. At launch, only the "this server" board; the global board comes after launch.
   - A global top 100 for followers, hits and cypher wins, saved in an OrderedDataStore and refreshed every few minutes. It's empty in Studio, where the store is off.
   - A "this server" board in the hub.
4. **Records and awards** (after launch). Named records ("most hits", "longest cypher streak") become plaques or items when you set them. Earned-only.

Stats are only ever what really happened. No paid item adds to them (the user's rule against selling achievements).

## 7. The store

- **A small store at launch** (the user), growing with updates.
- **Real-brand items** (the CELINE-style hoodie and the like) **are earn-only, never sold, for now** (the user). The user's later idea: sell them in slightly different renders, so people can tell what they're mimicking. That would be a separate look-alike item, decided later.
- **Claude's call on the launch assortment:**
  - about 30 store items across the families
  - the VIP pass
  - a featured row (Codex's eight-entry featured assortment as a starting point)
- **The VIP pass (launch).** A one-time game pass: a VIP look, a producer-tag style and a cosmetic bonus. No gameplay edge.
- **The season pass (after launch).** A free and a paid track of cosmetic rewards, earned by playing over a season.
- **Where it lives (Claude's call):** a STORE tab beside the gear rack's tabs, plus "buy" on a store item seen in the closet or decorate bar. Phone first (≥ 44 px), like every panel.
- **Purchases:** Roblox `MarketplaceService`, with game passes for passes and developer products for single items.
  - The server grants on `ProcessReceipt` and records the item once (`ItemKey`).
  - Ownership is saved apart from career state.
  - Claude builds the flow; the user creates the products and their ids.
- **Never during a story failure** (§2): the store doesn't pop up after a loss.

## 8. Ownership and origins

- **Every owned item records how you got it:** bought, earned (Money), a story gift (who, which chain), a record, or a skill drop (with its serial). This uses plan 3's grant ledger, `ItemKey`, so an item is owned once.
- **The origin line reads true after a new era resets people,** for example "from your first era".
- **Owned items live outside `prof.career`,** so a new era keeps them (endless play §6).

## 9. Goals, non-goals, anti-goals

- **Goals:**
  - A month-in studio is proud and personal.
  - Rarity means something.
  - Basic players enjoy the game free.
  - Producers find gear and sounds worth chasing.
  - A small store at launch earns without breaking any "never".
- **Non-goals at launch:**
  - trading
  - the season pass
  - mystery boxes
  - real-money markets
  - a content tool for adding items
- **Anti-goals:**
  - pay-to-win or paid odds
  - a paid stat or record
  - a bought item passed off as earned
  - fake scarcity
  - a store push after a loss
  - an upload or Robux setup done by Claude
  - unlicensed audio

## 10. Constraints and plans this touches

- **Building:**
  - Pure rules first, CLI-tested; Studio by the controller under the lease.
  - Schema v5 with lazy fields. Each room item stays within `ItemParts`.
  - Phone first. Words go through copy approval.
- **The rooms plan:** the decorate bar and the closet gain rarity frames and store items. The closet already caps hangers by budget.
- **Endless plan 3:** keepsakes and the grant ledger are the ownership record. Items key on `ItemKey`.
- **Plan 1:** levels 11–20 can gate higher-tier gear.
- **The people plan:** contacts and records feed the profile card.
- **Aku:** the sound kits' and voices' place in the beat maker is his. The items design only names them as rack, store or signature entries.
- **Codex:**
  - the catalog options and price bands
  - the 20-item earned map (`starter_catalog_and_prestige_2026-11-12.txt`)
  - the Blender pipeline for hero pieces

## 11. Left to the builder

- the exact 100+ item list, from Codex's options and the targets in §3; each line goes to the copy approval
- the rarity frame colours and words
- the leaderboard refresh rate and stat list beyond the three named
- the stats wall's layout
- the store tab's layout
- the NUMBERED run sizes and how each is earned (skill challenges, records, story)
- the order of the build tasks, within the agreed build order

## 12. Done means

**At launch** (the store slice and the earned basics):
- A player can earn, buy, place, wear and show items across all families, and each shows its rarity and an honest origin.
- The store sells the launch assortment and the VIP pass through real Roblox products the user created. Purchases are granted once, saved, and survive a rejoin.
- The stats wall, profile card, leaderboards and records show only real stats.
- No "never" rule is broken (each one has a test).
- Every new line is on an approved copy list.

**After launch:** global NUMBERED drops with serials; the global leaderboard; records and awards; the season pass; Robux sound packs; possibly sold look-alike versions of brand items.
