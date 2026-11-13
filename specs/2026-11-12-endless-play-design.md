# Endless play: a story web, a cast that never runs out, no daily walls

2026-11-12. **APPROVED by the user 11-12 21:09 ("yes").** Design for Prod Life III, from a chat with the user (Zenji) on 11-12 20:19–21:08, plus one builder check and Codex's companion (`design_input/codex/generated_cast_rewards_contract_2026-11-12.txt`). It covers what has to be true for people to play "infinitly", what goes in at launch, and what comes after. What the user said is quoted. Everything else is marked **Claude's call** and can be switched.

## 1. Why

The user, 11-12 20:19: "should we even have days? wont that make problems weher there could only be a fixed amt of days players can play? shouldnt it just be houndreds of charecters and mapped out scenarios so people can play infinitly?"

What the code and other games showed:
- **Career days don't end anything.** A career day is a real day you played (`Systems/Life.lua`, `Life.Tick`).
- **Daily caps limit almost every reward** (`Config.Career.Sources`, about 16 sources with `dailyMax`).
- **For a solo player, the first walls hit are lower down** (from the builder check):
  - **Each artist request pays only the first time, ever.** `Systems/Contracts.lua` ~:270 does this, and there are 21 briefs in `Data/Artists.lua`, so request money runs out in about a week.
  - **The visits run out.** Walk-ins stop at `Config.WalkIns.DailyMax = 8` a day, and phone pops stop at `Config.Phone.DailyMax = 6`. A solo player uses them up in the first hour.
- **Content is finite.** There are about 200 cards and follow-ups, with a fixed cast.
- **There's nothing after the top.** The pacing sim puts Legend at about day 17.
- **Other games:**
  - Roblox tycoons and idle games run on real time, rising prices and rebirth.
  - BitLife runs on random events, choices that compound, many paths, new lives and constant updates.

## 2. What the user decided

| Question | The user's answer |
|---|---|
| Long play sessions | "Whatever u think" → §3 |
| After Legend | "Slower climb, Keep climbing, New era (rebirth), Start your own label … but start own label might come post launch" |
| Earning while offline | "No" |
| The cast | "Whatever u think" → §4: a hand-written core plus generated people |
| A new era keeps | "Unlocked gear/sounds, A Hall of Fame, A legacy perk" (people don't carry over) |
| When a new era starts | "Your choice, after a milestone" |
| Repeated situations | "Mix of new and if yes it feels new" |
| Above Legend, players chase | "Your people, Awards and records, Bigger collaborations, Your empire" |
| Generated people grow | "Yes, they rise and fall" |
| Who keeps stories coming | "Claude writes, you approve, A tool for you and Aku" |
| In launch | "No daily walls, Generated cast" (later: the slower climb too, see below) |
| What pays on your 100th beat | "Endless new requests, but I want to integrate a lot of interactions that are not just production oreinted, like typical life of producer scnearios that can efffect other reltatiosnops or ingame things that all knit together" |
| Visits | "I want visitors to come after certain events get triggered so its like bitlife like worktree of certain things can trigger other or certain charecers to come or situations to occuer" (Claude's playback, §4.1: "Yes, that's it") |
| People you haven't seen in a long time | "Archive, never delete" |
| The slower climb to Legend | "Yes, at launch" |

Already decided earlier, and still binding:
- Every person you meet persists (D1). §4.5 keeps it through the archive.
- Contacts with relationship meters ship at launch (D6).
- Big names wait for the home studio and FAMOUS (D11).
- No crime storylines (11-12).
- Monetization follows ChatGPT's plan §7: never sell odds, capability or achievements.
- The integration direction (11-12 ~19:10): a delivered beat → a person remembers → an item with that story → show it → a callback.

**In launch:**
- no daily walls
- the story web with a generated cast and endless requests
- the archive
- the slower climb

**After launch:**
- goals above Legend
- new eras
- your own label
- the content tool's interface

## 3. No daily walls (launch)

**Goal.** A five-hour session keeps paying, through things worth doing. Normal players' first weeks feel as they do today.

**Claude's calls:**
- **Story rewards curve; button presses stay capped.**
  - The money, XP, Followers and Aura from deliveries, visits, phone outcomes, cypher wins, beat saves and FIRE received use today's `dailyMax` as the **full-pay count**.
  - After that, each further award pays a smaller share, shrinking to a **25% floor**.
  - Small whole-number awards carry their fractions over, so they never round down to nothing (the gate floors awards today, `DataService.lua` ~:437).
  - Press-a-button XP keeps its hard daily caps: Console, Mic, FireTap, CypherVote. Otherwise a player could out-level the story by tapping.
- **Event counts aren't curved.** Placements, hits and sponsor signings are story events, so a story event counts in full.
- **Item gifts and signature rewards aren't curved either** (from Codex's review). They're granted once per real chain and person, and they're stored apart from career state. Many generated people draw from authored reward families with personal variants, so 150 people don't all mint the same kit.
- **The cold streak's 2-visits-a-day stays.** It's a penalty with a way out, not a wall.
- **Abuse guards stay:**
  - cooldowns
  - the copy check on deliveries (`MinChanged`)
  - the delivery cooldown
  - the cypher and broadcast rate limits

  Where a cap was the only thing stopping a two-player farm (e.g. FIRE between two friends), the builder adds a per-pair limit.
- **No offline earnings.**
- **The bounds the pacing run must meet** for a 5-hour-a-day solo player and a 5-hour player with others around:
  - Money a day is at most **2×** the random player's.
  - The player reaches THE HALL no earlier than **day 3**.
  - The player reaches Legend no earlier than **day 30**.

  Every number is reported. Any change to a decided guardrail goes to the user first.

## 4. The story web and the cast (launch)

### 4.1 The story web (the user's "worktree")
- **The main engine of what happens to you. Every choice can plant something:** who shows up, when and in what mood. One event can trigger others.
  - Example: a late session the night of your cousin's party → your cousin is upset → mom calls two days later → you show up with a beat → a rapper there starts sending requests → months later he blows up and remembers you.
- **Triggers include:**
  - your choices and their outcomes
  - your deliveries and how good they were
  - FIRE and cypher results
  - buying a room or gear
  - a relationship crossing a line
  - your fame tier
  - played days passing
  - **generated people living their own lives** (blowing up, falling off, getting signed, needing help)
- **The parts that already exist:**
  - planted follow-ups (`plant = { id, at }`)
  - story flags and gates
  - Wave 3's arcs (mom's silence, the kid who blew up)
  - Day One's chain

  The web generalises them: a **queue of triggered situations** per player, each with a who (a person or a role), a when (after N visits, N played days, or an event), conditions and a priority.
- **Pacing (Claude's call):**
  - The daily visit limits (`Config.WalkIns.DailyMax`, `Config.Phone.DailyMax`) go away.
  - Arrivals stay spaced by today's gap timer (4–6 minutes) so nothing floods, with triggered situations first.
  - When nothing is triggered, **everyday life** fills in: ambient situations drawn for your career stage and the people around you.
- **Not only production** (the user's words): the everyday life of a producer:
  - rent, roommates, a breakup, family events
  - a fan DM, a blog rumor, a show at a local spot, a sponsor lunch
  - a friend who needs help, a party you skip

  Each one moves Money, Aura, Followers, relationships, your room, your gear, and what comes next. No crime storylines.

### 4.2 Endless requests
- Beat requests come out of the web.
  - **People you meet want beats:** the hometown friend, the local artist, the promoter.
  - **A generated person can send requests again and again,** each a new request written from approved templates (artist, mood, asks, pay by their career level).
- The 21 hand-written briefs stay as written; their "pays the first time only" rule still applies to them.
- The one-active-request slot (`Contracts.lua` ~:166) stays. The builder decides how a waiting request is offered: a phone message, or a card that holds until you're free.
- **The seam from Codex's blueprint §7 is part of this.** Choosing a request replaces your active one, so an accepted promise needs a saved project record, or a hand-over, before the web relies on it.

### 4.3 Two kinds of people
- **The hand-written core is unchanged:**
  - family
  - the rival
  - the six remembered people
  - the starter visitors
  - the parody stars
- **Generated people** are built from pieces when the web needs someone for a role:
  - a fiction-safe name (never a real person)
  - a code-built look (no uploads)
  - one or two traits
  - a genre
  - what they want
  - a career level that rises and falls ("Yes, they rise and fall")

  Each player's generated people are their own.

### 4.4 Roles
- Cards and requests can be written for a **role** instead of a person. The words fit whoever plays the part, through the existing `{name:<id>}` tokens. Example roles:
  - `@hometown`
  - `@local_artist`
  - `@promoter`
  - `@producer_peer`
  - `@blogger_type`
  - `@label_scout`

  The builder settles the first list.
- A role card binds to someone you've met in that role, weighted by your history with them, or to a new generated person.
- **This replaces the people plan's Task 4 hometown pool,** which hand-copies three kids. `@hometown` becomes the first role. The original `homekid` stays as the written first one. The people plan's `BindOutcome` and `W.Roles` seam extends to generated people.
- **A chain keeps its person** (from Codex's review). Once a role card binds to someone, every follow-up, request and reward from that chain stays with that exact person in that era. It is never re-drawn from the role.
- **Repeats** ("Mix of new and if yes it feels new"):
  - A situation shape can come back with a different person after a cooldown (the builder tunes it; roughly a week of played days).
  - The web prefers situations you haven't seen.
  - New written situations join in every content batch.
- **Share of visits (Claude's call):** after the first week, about half of visits involve generated people. The written core keeps its arcs.

### 4.5 Memory, growth and the archive
- **Everyone you meet keeps their memory:**
  - a met record (people plan Task 3)
  - a relationship score and flags (Wave 3)
  - a contact row with a meter (people plan Task 5)
- **Rise and fall changes what they bring.** A friend who blew up brings bigger jobs; one who fell off asks for help. They remember who helped them.
- **Archive, never delete** (the user):
  - About **150 people stay active** per player, stored as a seed plus their changing state.
  - People you haven't seen in a long time move to an **archive**, stored compactly: id, seed, score, key flags and last seen.
  - They can return through the web (an old friend calls), and they show in CONTACTS under "old contacts".
  - Nobody is lost. The archive still grows slowly, so it gets a **measured byte budget** inside the profile (the builder measures the real size per archived person; Roblox allows up to 4 MB per saved value). Past that budget, the oldest archived people move to separate save pages that load only when one of them comes back. Nobody is ever deleted. (From Codex's review.)
  - Schema stays v5 with lazy fields.

### 4.6 People's own relationships, and people who change (launch)

The user, 11-12 21:01: "there should be deep relationships and scenarios taht go out for long periods of tiem between the relatipships of some of the peeople u interact with. Like two artits u work with end up beefing, or u fall out withsomeone because of socail media interactins or they value clout over genuiness, people can cahnge based off there interactions as ell for example someone might switch up on u in certain scenarios". Confirmed after Claude's playback ("Yes add it and think of scenarios like these"), at launch.

**What it adds** (Claude's calls on the shape):
- **People know each other.** Characters, written and generated, have ties to each other: friends, crews, exes, collaborators, rivals, a mentor. Each tie has a tension level that events push up or down. What happens between them pulls you in.
- **Values drive behavior.** Each person cares about one or two things:
  - clout
  - loyalty
  - money
  - the art
  - family
  - fame

  Values decide how they react to your choices, to their own rise and fall, and to what happens online. These replace the plain "traits" in §4.3, or sit beside them.
- **Your public image.** A simple read of how the internet sees you right now: hyped, quiet, messy, respected. It moves with your posts, FIRE, who you're seen with, rumors and blog stories. People react to it through their values: a clout-chaser cares a lot, a genuine friend barely. **Nothing bought sets it** (from Codex): a premium look can't buy hype, clout, loyalty or an affiliation. Gifts you earned stay yours after a later fallout, and new gifts come only from new outcomes. A keepsake records only what truly happened.
- **People change, with warning signs.** Success, a fall, a scandal or your help can shift what someone values or how they treat you. A **switch-up** (a friend turning on you) needs at least two warning signs first, such as shorter replies, skipping your listen-back, or being seen with your rival, so it feels earned, not random. You can sometimes win them back.
- **Long arcs.** These play out over weeks or months of played days, through the story web (§4.1). The ties, tensions, values and public image are simply more triggers and conditions.
- **Choices ripple.** Backing one person can cost you with another. Staying neutral has its own cost.

**First scenarios** (Claude's drafts; the words go through the copy approval):
1. **The same-week drop.** Two artists you produce for release the same week. Fans compare, one subtweets, a beef starts, and both DM you. You can back one, stay quiet, or try to bring them together on a track (risky). Weeks later, the one you didn't back is cold to you, or the joint track ends the beef.
2. **The clout switch-up.** An artist you helped early blows up. If they value clout and you go quiet, the replies get shorter, they skip your listen-back, and then they credit someone else in an interview. A genuine one shouts you out by name instead.
3. **The screenshot.** A DM of yours gets screenshotted and posted out of context. People react by their values: a loyal friend defends you, a clout-chaser piles on, and the blogger keeps it going. How you respond (clap back, explain, ignore) moves your public image.
4. **The beat that went to the wrong song.** A beat you sent one artist shows up on another's track; a mutual friend passed it along. Both feel wronged, and a credit dispute starts. Your relationship with both depends on how you settle it.
5. **The crew split.** The crew you came up with splits when one member gets a deal and asks you to produce the solo project. The others call it betrayal. Saying yes, saying no, or doing both changes all of them.
6. **The mentor who gets jealous.** An older producer who helped you starts competing as you rise. If they value fame, they undercut you for a placement. If they value the art, they're proud, and they bring you a big job.
7. **The brand-safety ask.** Your sponsor rep wants you to drop a collaborator after their messy week online. Keep them and risk the deal, or cut them and they remember.
8. **The fake friend.** Someone who always hyped you is caught talking down on you in a group chat. The warning signs were there for weeks. Confront them, ghost them, or keep them close.
9. **The comeback.** Someone who fell off asks for a beat, and most people won't work with them. Helping them can pay off big when they come back, or cost you with the people who dropped them.
10. **The breakup album.** Two artists who were dating break up, and both want you on their album. Whichever side you take, the other side's friends notice.

**Launch volume** (Claude's call, switchable): these 10 long arcs, plus the tie, value and public-image rules for every generated person. More arcs come in later content batches.

### 4.7 Where the words come from
- Every line players see comes from templates Claude writes and the user approves, in batches. Generated names, traits and goals fill the slots, and no line is invented at run time.
- At launch the content format is a table anyone can fill: a role card, a life situation, a request template, a trait. The user's and Aku's **tool** for adding to it comes after launch.
- **Launch content volume (Claude's call, switchable):**
  - 6 roles with about 12 situations each
  - about 40 everyday-life situations
  - about 20 request templates
  - about 30 traits
  - about 6 web chains in the style of the cousin example
  - the 10 long relationship arcs in §4.6

### 4.8 Rewards from people (from Codex's companion)

Codex's `design_input/codex/generated_cast_rewards_contract_2026-11-12.txt` sets the rules for items from people. These go into the launch build:
- **A chain fixes its people.** A chain fixes its person, era and participants when it starts, and existing slots are never re-drawn. A later written introduction can bind a NEW slot once, like the rapper at the cousin's party. Changed credits or terms are an explicit revised agreement.
- **Story people and credited people are separate.** A joint keepsake records the story's people separately from the people actually credited on the music. A manager or an ex in a dispute isn't an author. A pair or group achievement happens once per participant set; swapping the order doesn't repeat it.
- **Three "once" rules:**
  - an event resolves once
  - an achievement is granted once per person, era, arc family and tier
  - an account owns an item once

  A replay or a fresh chain can't mint a duplicate.
- **Keepsakes never change.** A keepsake that promises your track keeps its origin and the beat version as it was. Today's three-beat recent list isn't an archive.
- **The archive keeps its facts.** Archived people keep what they claimed and completed, so returning can't re-grant. People with an active promise, callback or pinned goal aren't archived.

The item families, prices and the 20-item map stay proposals for the later reward plan. New-era carryover details (§6) belong to the after-launch plan, including keeping furniture unlocked through first/tier rules before a reset.

## 5. The slower climb (launch)

- **Legend should take about two months of played days for a typical player,** not about 17.
  - Today's levels 1–10 can't move (`Config.lua` ~:46: "fixed now so levels never shift").
  - So the climb adds levels above 10, and Legend's gate moves up accordingly.
- **The early game stays as it is:**
  - first monitors in session 1
  - THE HALL around day 4–6
  - Day One unchanged
- **The pacing run sets the new numbers;** the user sees them before shipping. Claude's call: Legend median about day 60 for the random player.

## 6. After launch (recorded so launch doesn't block it)

- **Goals above Legend:**
  - "Your people": raising the friends you helped
  - "Awards and records"
  - "Bigger collaborations"
  - "Your empire"
- **New era:**
  - It starts by "Your choice, after a milestone".
  - It keeps "Unlocked gear/sounds, A Hall of Fame, A legacy perk".
  - People don't carry over.
- **Your own label.**
- **The content tool's interface.**
- **Launch must leave room for:**
  - an era number in the save
  - a Hall of Fame built from today's discography
  - unlocked gear, sounds and cosmetics kept apart from career state (a new era keeps them)
  - item origins that still read fine after people reset (Codex's item map follows this)

## 7. Goals, non-goals, anti-goals

- **Goals:**
  - A five-hour session keeps paying through things worth doing.
  - A month-long player keeps meeting people and seeing new situations, and helped friends come back changed.
  - Everyday-life events knit into relationships and the career.
  - The early game is unchanged.
  - Legend is a two-month goal.
- **Non-goals at launch:**
  - new eras, the label, award shows, goals above Legend
  - offline earnings
  - the content tool's interface
- **Anti-goals:**
  - generated people who feel like reskins
  - grinding that beats playing the story (§3's bounds)
  - a save that grows without bound
  - pay-to-win
  - an unapproved line reaching players
  - a decided guardrail moving silently
  - crime storylines

## 8. Constraints and plans this changes

- **Building:**
  - Pure rules first, CLI-tested; Studio work by the controller under the lease.
  - Schema v5 with lazy fields. No uploads; licensed audio only.
  - Parody names for stars; generated names avoid real people.
  - Phone-first UI. Copy rules as in every copy doc.
- **The people plan:**
  - Task 4 becomes roles + generated people.
  - Tasks 6–10 (pacing) add the long-session policies, the new levels and Legend's new gate.
  - Tasks 1–3 and 5 stand, and Task 5's CONTACTS gains "old contacts".
- **The rooms plan's remaining tasks:** unaffected.
- **Day One:** unaffected.
- **Codex's 20-item map:** stays a proposal. Its hometown rewards follow the `@hometown` role (whoever fills it), and owned items stay separate from career state.

## 9. Left to the builder

- the shrinking-share step size (the 25% floor is the call)
- the first role list and the trait list
- the fiction-safe name lists
- the repeat cooldown
- how a generated person's level moves
- the trigger queue's priorities
- how a waiting request is offered while one is active
- the archive rule's timing
- the exact new levels

## 10. Done means

- **Long sessions:**
  - A solo player keeps earning in hour five.
  - The pacing spec passes with the long-session policies inside §3's bounds.
  - Legend's median is about day 60.
  - The early-game numbers are unchanged. Every number is reported.
- **The story web:**
  - A choice can plant a situation that arrives days later with the right person.
  - At least six chains work end to end.
  - Everyday-life situations move relationships and stats.
- **People:**
  - After the first week, about half of visits involve generated people.
  - A helped generated friend who later blew up comes back and says so.
  - An archived person can come back.
  - The save stays bounded after 200 simulated played days.
- **Words:** every line players see is on an approved list.
