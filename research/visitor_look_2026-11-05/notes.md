# Walk-in visitors: a look of our own (concept options, 2026-11-05)

This is a proposal only. Nothing in the project was edited. The user decided on "our own stylized look, not Roblox avatars and not the blocks", and approves one direction before anything is built.

## Files (all in this folder)

| File | What it is |
|---|---|
| `lineup.lua` | An Edit-mode Studio script: it builds `workspace.OK_LookLineup` and returns a one-line summary. |
| `lineup_remove.lua` | Removes `workspace.OK_LookLineup`. That is all `lineup.lua` creates. |
| `portraits_card_size.png` | The A (rows 1 and 3) and B (rows 2 and 4) portraits shrunk to the real card sizes, 44 px and 36 px (36 is the tight layout on short screens), then enlarged so the pixels show. |
| `lineup_preview.png` | A Blender re-render of `lineup.lua`'s exact part data from the same cameras, lit like the hub with its lamps on. It is a stand-in until the Studio captures exist. Signs, cards and name plates aren't drawn. |
| `mesh_concept.png`, `mesh_concept.py` | Direction C, the modelled mesh, rendered in Blender 5.2: `blender -b -P mesh_concept.py -- out.png`. |
| `_work/` | My check tools: a Roblox mock (`mock.lua`) that runs `lineup.lua` under the luau CLI, part exports and the preview scripts. |

### How `lineup.lua` works

**Rooms.** It builds four closed rooms at world X −926..−704, Y −4..32, Z −34..16. That is about 700 studs west of the hub (X 0..94). The rooms are clear of:
- the West Suite (near X −4, Z −41)
- Studio Two (near X 11, Z 60..100)
- the room test (far out at +X)

**Before it builds.** It scans the workspace for any other part in that box. If it finds one, it builds nothing and returns `ABORT…`.

**Folder.** Everything goes in one Folder with `Archivable = false`, so it never saves with the place. It touches no setting and no Lighting. Re-running it replaces the old folder.

**Remove it before any build, test or snapshot script runs.** Two scripts would be affected:
- `build/01_backup_scaffold.lua` moves every workspace child that isn't on its keep list into ServerStorage.
- `build/room_test.lua` works out the hub's bounds from every workspace Folder, so the lineup at X −926 would throw them off.

The light-count and script checks (`09_qa`, `t01`..`t05`) are unaffected, because the lineup adds no Light and no script.

**Why the rooms are closed.** `03_lighting.lua` sets ClockTime 0 and OutdoorAmbient to (8, 8, 12), so open sky renders black. Indoors gets Ambient (78, 72, 88), the same as the hub's edit view. Expect the captures to look dim. ViewportFrames light themselves, so the portraits look brighter than the rooms, and that is how the card would look.

**Cameras.** Set `workspace.CurrentCamera.CFrame` to one of these. They assume FieldOfView 70 and were checked to fit 1.43–1.78 aspect viewports.

| Shot | CFrame |
|---|---|
| Whole lineup | `CFrame.lookAt(Vector3.new(-900, 18, -24), Vector3.new(-900, 8.5, 1))` |
| Row A close | `CFrame.lookAt(Vector3.new(-840, 4.9, -13.5), Vector3.new(-840, 4.3, 0))` |
| Row B close | `CFrame.lookAt(Vector3.new(-780, 5.4, -14), Vector3.new(-780, 4.8, 0))` |
| Portraits | `CFrame.lookAt(Vector3.new(-720, 7.2, -4.5), Vector3.new(-720, 7.2, 6))` |

**What each shot shows:**
- **Whole lineup:** the GROUP room. Bleacher tiers run front to back: TODAY, A · VINYL TOY, B · LANKY SHAPES. Each row has the same five visitors in the same order, a sign at its left end and a card mock at its right end.
- **Row A close / Row B close:** stage rooms, one row each.
  - STIRRUP PEONY wears the name plate and a speech bubble, built as Visitor's `decorate()` builds them, with the offset proposed below.
  - The names are on the stage front, and the row's card mock is on the back wall.
- **Portraits:** for each direction, the five visitors framed as the card would frame them (240 px tiles), each with a small copy beside it.
  - TODAY's tiles show what the card shows today: a skin square on the visitor's colour.

**The five visitors.** They use fiction names, because the launch uses the fiction roster:

| Visitor (fiction name) | id |
|---|---|
| STIRRUP PEONY | `navx` |
| YOUR MOTHER | `mom` |
| A KID FROM YOUR OLD BLOCK | `homekid` |
| THE GOSSIP BLOGGER | `blogger` |
| A REP FROM NITE OWL ENERGY | `rep` |

The kid is posed mid-stride in every row (swing 0.45 rad), to show the limbs are separate parts that the existing walk swing can move.

### Checks done (no Studio)

- **Syntax:** `luau-compile` and `luau-analyze` are clean, apart from Roblox globals.
- **Full run in the luau mock.** The mock does real CFrame maths and checks property types. It confirmed:
  - 49 figures are built: 15 in the group, 10 on the stages and 24 in viewports.
  - Every figure part is Anchored, with CanCollide, CanQuery, CanTouch and CastShadow all false.
  - Every part is SmoothPlastic or Neon, and there is no Light, Humanoid or Sound.
  - Every figure has 8–16 parts and a PrimaryPart.
  - Feet sit on their stands.
  - Re-running replaces the folder.
  - Remove works.
  - A stranger part in the box triggers ABORT.
- **Not verified:** how Studio renders the SurfaceGuis, the ViewportFrames inside SurfaceGuis (24 of them) and the BillboardGuis. I also assumed WedgePart's slope faces −Z and up. Only B's nose and the rep's quiff use wedges, and they look slightly wrong if that assumption is off.

## The constraint every direction meets

`build/t42_play_server.lua` asserts that every walker has **8 to 16 BaseParts**, all of them Anchored, with CanCollide, CanQuery and CastShadow false. A and B are designed to fit that limit, so t42 passes without a limit change.

Part counts, in the order Peony / mom / kid / blogger / rep:

| Direction | Parts | Note |
|---|---|---|
| Today | 11 / 11 / 11 / 8 / 10 | |
| A | 16 / 16 / 16 / 15 / 15 | |
| B | 16 / 16 / 16 / 16 / 16 | |
| C (mesh) | about 5k–8k triangles a character | As decimated here. A proper retopology would probably land around 2–3k; that is an estimate, not measured. |

Other test surfaces a new look must keep. Neither A nor B changes them:

| Surface | What it must keep |
|---|---|
| The visitor Model | Named `Visitor_<id>`, `Archivable = false`. Attributes `Visitor`, `VisitorId` and `Target`. Parented under the Folder `workspace.OK_Visitors`. |
| `NamePlate` billboard | `Plate.NameText` inside it. MaxDistance 80, LightInfluence 0, Adornee set. |
| `Bubble` billboard | `Line` inside it, Enabled false at spawn. MaxDistance 80, LightInfluence 0, Adornee set. |
| Facing check | t42 reads `GetPivot().LookVector` and needs facing > 0.9. The PrimaryPart must be unrotated, or rotated only about Z. A uses `Hips` (a ball) and B uses `Torso` (a block). Both are unrotated. |
| The pigeon (t42 §11, t56) | Has its own limit of 12 parts or fewer. Leave it as it is. |
| t43b, t43c, t55 | They only read attributes and `Bubble.Line`. |
| `spec/walkins_data_spec.lua` | Doesn't read `sig`. |

---

## TODAY (baseline, copied from `Visitor.lua`)

Each visitor is a box body, a ball head, two slit eyes and one signature piece. Every visitor has the same skin and the same proportions, and the card shows a skin square on the visitor's colour.

Two problems for the launch:
- The cowboy hat on `navx` is the parody's likeness cue (pink plus a western hat), so the fiction roster can't keep it.
- The blogger has no signature at all.

---

## A · VINYL TOY

**Pitch.** The visitors look like designer vinyl collectibles.
- A big round head (2.2 across), a capsule body (a cylinder on a ball), stubby legs and ball hands.
- Glossy bead eyes and one or two chunky props each.
- Every part is a Ball or a Cylinder, plus one or two blocks.

The head is the character. It carries the face across a room and fills the card's square on its own. It is round, so it isn't "the blocks", and toy-like, so it isn't a Roblox avatar.

**Size and name plate.**
- Adults are about 5.3–5.5 studs tall, like a player avatar. The kid is about 4.2.
- The plate goes at the figure's top + 1.2, the same clearance it has above today's cowboy hat. That gives `StudsOffset` of 2.55 / 2.8 / 2.4 / 2.58 / 2.54. Today's is 2.4 for everyone.

**Body.** 12 parts: LegL, LegR, Hips, Torso, ArmL, ArmR, HandL, HandR, Head, Hair, EyeL, EyeR. That leaves up to 4 for the signature.

| Visitor | How they read (silhouette, colours, signature) | Parts |
|---|---|---|
| STIRRUP PEONY (country trap) | A pink peony bloom (two petals and a magenta heart) on the left of dark hair, and a sunflower-yellow neckerchief. Mint jacket, denim, tan boots. The country cue is denim, boots and the neckerchief only. There is no hat, no fringe and no pink-plus-western pairing; the flower carries the name. | 16 |
| YOUR MOTHER (home cooking) | A big bun, a cream apron and a pear shape (wider hips). She carries a red casserole with a silver lid in both hands, so her arms are held still and only her legs swing. Coral cardigan, plum skirt. | 16 |
| A KID FROM YOUR OLD BLOCK | Clearly shorter. Orange cap with a forward bill, teal hoodie, dark headphones round his neck and an orange backpack, which reads side-on as he walks past. | 16 |
| THE GOSSIP BLOGGER | A purple bob, big round shades and a yellow dress. She holds her phone up beside her face, with a pink case and a Neon "recording" light. The one raised arm is her silhouette. | 15 |
| A REP FROM {sponsor} | Light grey suit (it reads under dim light, where navy goes black), white shirt and a Neon violet tie. A purple swag bag swings with his arm. Nothing on him names a brand, so he works for any of the six sponsors. | 15 |

**What `Visitor.lua` would need:**
1. Replace the fixed 8-part body and `SIGS` with a look table keyed per visitor. Put it in a new pure module (no Roblox calls beyond CFrame/Vector3), because the client needs it for the portrait. The part-entry format is the one in `lineup.lua`.
2. Generalise the limb entry from `{ swing, len }` to `{ swing, hang = CFrame, rot = CFrame }`.
   - The pose becomes `base * cf * Angles(swing * sw, 0, 0) * hang * (rot or identity)`. Today's formula ends at `* hang`.
   - `rot` stands a Cylinder limb upright: a Cylinder runs along X.
   - A hand or a carried bag shares its arm's pivot, with a longer `hang`.
   - Arms that hold something just have no `swing`.
3. `decorate()` takes the plate offset from the figure's top (top − head.Y + 1.2), not a fixed 2.4.
4. Set PrimaryPart = Hips.

**Tests.**
- t42's 8..16 limit passes unchanged.
- t42 §1 loops over the 16 sig names hard-coded in the test. That list has to become the new look keys, or Visitor should export the list and t42 iterate over it.

**The card.** WalkInUI's `Face` and `Shirt` frames become a ViewportFrame showing a head-and-shoulders copy built from the same look data, with its camera inside it.
- The arrive payload has to carry the visitor id. `Systems/WalkIns.lua:256` sends `visitor = { name, style, color }` only.
- The 44 px portrait is basically the head here. Checked at 44 px and 36 px (`portraits_card_size.png`): the eyes, hair colour, bloom and shades all survive.

---

## B · LANKY SHAPES

**Pitch.** Tall, thin, angular figures, like streetwear poster art.
- Small block heads with a wedge nose and bar eyes.
- Long block limbs, big shoes, flat colour blocking.
- Each character is one strong outline: the long coat, the bun and long dress, the wide hoodie, the raised phone, the broad suit.

B reads best from across the room and while walking side-on, because the nose and big shoes give a profile.

**Size and name plate.**
- Adults are about 6.6–7.0 studs tall, taller than a player. The kid is about 4.9. Doors are 8 studs high.
- `StudsOffset`: 2.34 / 2.47 / 2.13 / 2.49 / 2.09, about today's value.

**Body.** 13 parts: LegL, LegR, ShoeL, ShoeR, Torso, Neck, Head, Hair, EyeL, EyeR, Nose (a wedge), ArmL, ArmR. That leaves 3 for the signature. There are no hands; the arm is the hand.

| Visitor | How they read (silhouette, colours, signature) | Parts |
|---|---|---|
| STIRRUP PEONY | Flat-top hair with the peony bloom on it, a long mint coat to mid-thigh, denim and tan boots, and the yellow neckerchief. | 16 |
| YOUR MOTHER | A ball bun on top of a small square head, a long coral dress with a cream apron, and a light-blue food box held low in both hands. A flat dish read as a belt when seen edge-on. | 16 |
| A KID FROM YOUR OLD BLOCK | Short, a wide teal hoodie, chunky white shoes, and tall orange headphone cups with a band. | 16 |
| THE GOSSIP BLOGGER | A long purple bob, black bar shades, a yellow jacket and pink skirt. Her long arm holds the pink phone high, the strongest outline in either set. | 16 |
| A REP FROM {sponsor} | A broad grey suit, a wedge quiff, a white shirt, the Neon tie and the swing bag. | 16 |

**What `Visitor.lua` would need:**
- The same changes as A.
- Wedges: `newPart` must create a `WedgePart`, or use `Part.Shape = Enum.PartType.Wedge`.
- PrimaryPart = Torso.

**Tests.** As for A. Every figure is at the 16-part limit, so there is no headroom.

**The card.** As for A. The portrait is a small cube head. Checked at 44 px and 36 px (`portraits_card_size.png`): the features shrink to a few pixels and the portrait reads as "the blocks" again. That is B's weak spot.

---

## C · MODELLED MESH (`mesh_concept.png`)

**Pitch.** The same five, as smooth sculpted meshes:
- seamless joints and tapered limbs
- mitten hands, eyebrows and smiles
- real peony petals, a neck ring for the headphones, lapels, the cap bill

This is the ceiling of the look: it reads as a commissioned character set.

**Cost.**
- Every look pack has to be imported with Import 3D, which is an upload under the user's account.
- Every change to a look is another re-import.
- New visitors need modelling, not data.
- Facial expressions or a rigged walk mean bones plus uploaded animations, or AnimationControllers.

**Phone cost.** About 5–8k triangles a character as decimated here (measured). A proper retopology would probably reach 2–3k (an estimate). Either is fine for at most 3 at once.

**Changes.**
- `Visitor.lua` would move MeshParts, possibly fewer parts than A or B.
- The tests' part count still applies.
- The upload and approval flow is the real cost.

---

## Phone performance (12 players)

**How many figures can exist.** `Systems/WalkIns` caps visitors at MaxWalking = 3 for the whole server, and t43c checks it. Its header says: "Server-wide at most MaxWalking visitors are out at once". The pigeon holds one of those slots. So the worst case is 3 figures in the whole server, not 12 × 3.

**Server and network cost.** The real cost is the server re-setting every part's CFrame on each Heartbeat, with each change replicated to all 12 clients:

| | Parts in the worst case | CFrame writes a second |
|---|---|---|
| Today | 11 × 3 = 33 | about 1,980 |
| A or B | 16 × 3 = 48 | about 2,880 (+45%) |

Two ways to cut this:
- A cheap win: `workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)` in `_pose`.
- If it ever matters: pose the limbs on the clients and replicate only the root.

**Rendering cost.** Trivial: 48 SmoothPlastic Ball, Cylinder and Block parts, instanced. There is no Light, CastShadow is false, and Neon is self-lit, not a Light.

**The card portrait.** One static ViewportFrame with no more than 16 parts, only while a card is open.

## Fiction and likeness

- No direction uses a real-artist cue. Peony drops the cowboy hat and the pink-plus-western pairing, and the rep shows no brand.
- Skin tones are spread across the cast on purpose and were **not** matched to the real people behind the parodies.
- Stylised non-human "vinyl" skin colours would remove the question entirely, if the user prefers. In A that is a one-line colour change per character.

## Recommendation: A · VINYL TOY

The big round head carries both the read across the room and the 44-px card portrait. That is exactly what the review said is missing, and it is the clearest break from both "the blocks" and Roblox avatars. A also fits today's 16-part test limit and needs no uploads.

What to take from B: the held-pose props, meaning the raised phone and the carried food.

C is the version to commission later, if the game earns it.
