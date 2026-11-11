# "C · MODELLED MESH": the five lineup visitors as smooth sculpted low-poly meshes, i.e. what a Blender -> Import 3D
# route could give (one mesh pack per look, uploaded under the user's account; every look change is a re-import).
# Concept render only: nothing here is exported or uploaded.
#   /opt/homebrew/bin/blender -b -P mesh_concept.py -- <out.png>
# Bodies are metaballs (one family per colour region, so regions don't merge into each other), polygonised, decimated
# to a low-poly budget and smooth shaded; props are beveled primitives. Prints the triangle count per character.
import bpy, bmesh, math, sys
from mathutils import Vector, Quaternion

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else "/tmp/mesh_concept.png"
TRI_BUDGET = 4000            # triangles per character after decimation (a phone-friendly Import 3D target)
K = 1 / 0.575                # metaball radius for a wanted visible radius (stiffness 2, threshold 0.6; measured)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
coll = scene.collection
engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
scene.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in engines else ("BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in engines else "CYCLES")
if scene.render.engine == "CYCLES":
    scene.cycles.samples = 64
    scene.cycles.use_denoising = True
scene.render.resolution_x, scene.render.resolution_y = 1600, 900
scene.view_settings.view_transform = "Standard"

def rgb(r, g, b): return ((r / 255) ** 2.2, (g / 255) ** 2.2, (b / 255) ** 2.2, 1)
MATS = {}
def mat(name, col, rough=0.5, emit=0.0):
    if name in MATS: return MATS[name]
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = col
    b.inputs["Roughness"].default_value = rough
    if emit:
        b.inputs["Emission Color"].default_value = col
        b.inputs["Emission Strength"].default_value = emit
    MATS[name] = m
    return m

# metaball elements ---------------------------------------------------------------------------------------------------
def ball(co, r): return ("BALL", Vector(co), r, (1, 1, 1), None)
def ell(co, r, size, rot=None): return ("ELLIPSOID", Vector(co), r, size, rot)
def limb(p0, p1, r):
    p0, p1 = Vector(p0), Vector(p1)
    d = p1 - p0
    q = Vector((1, 0, 0)).rotation_difference(d.normalized())
    return ("CAPSULE", (p0 + p1) / 2, r, (d.length / 2, 1, 1), q)

char_objs = {}
def region(char, name, col, elems, rough=0.5, res=0.05):
    mb = bpy.data.metaballs.new(char + "_" + name)
    mb.resolution = res; mb.render_resolution = res; mb.threshold = 0.6
    for t, co, r, size, rot in elems:
        e = mb.elements.new(type=t)
        e.co = co; e.radius = r * K; e.stiffness = 2.0
        if t == "ELLIPSOID":
            e.size_x, e.size_y, e.size_z = size
        elif t == "CAPSULE":
            e.size_x = size[0]
        if rot is not None:
            e.rotation = rot
    ob = bpy.data.objects.new(char + "_" + name + "_mb", mb)
    coll.objects.link(ob)
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
    bpy.data.objects.remove(ob)
    mo = bpy.data.objects.new(char + "_" + name, me)
    coll.objects.link(mo)
    me.materials.append(mat(char + name, col, rough))
    for p in me.polygons: p.use_smooth = True
    char_objs.setdefault(char, []).append(mo)
    return mo

def prim(char, kind, loc, scale, col, rot=(0, 0, 0), bevel=0.0, emit=0.0, rough=0.4, **kw):
    if kind == "cube": bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    elif kind == "cyl": bpy.ops.mesh.primitive_cylinder_add(vertices=kw.get("verts", 24), radius=0.5, depth=1, location=loc, rotation=rot)
    elif kind == "sphere": bpy.ops.mesh.primitive_uv_sphere_add(segments=kw.get("seg", 20), ring_count=kw.get("rings", 12), radius=0.5, location=loc, rotation=rot)
    elif kind == "torus": bpy.ops.mesh.primitive_torus_add(major_radius=kw["R"], minor_radius=kw["r"], major_segments=28, minor_segments=10, location=loc, rotation=rot)
    elif kind == "cone": bpy.ops.mesh.primitive_cone_add(vertices=3, radius1=0.5, radius2=0, depth=1, location=loc, rotation=rot)
    ob = bpy.context.active_object
    ob.scale = scale
    if bevel:
        m = ob.modifiers.new("bevel", "BEVEL"); m.width = bevel; m.segments = 3
    ob.data.materials.append(mat(char + kind + str(len(MATS)), col, rough, emit))
    for p in ob.data.polygons: p.use_smooth = kind != "cone"
    char_objs.setdefault(char, []).append(ob)
    return ob

# a face: glossy eyes with a catchlight, brows, a small mouth. f = head centre, hr = head radius, x0 = character x
def face(char, f, hr, brow=0.0, mouth=True, eyes=True, eye_col=rgb(18, 18, 24)):
    for sx in (-1, 1):
        e = Vector((f.x + sx * 0.33 * hr / 0.8, f.y - hr * 0.9, f.z + 0.02))
        if eyes:
            prim(char, "sphere", e, (0.2, 0.12, 0.26), eye_col, rough=0.15)
            prim(char, "sphere", e + Vector((sx * 0.03 + 0.03, -0.06, 0.07)), (0.06, 0.04, 0.06), rgb(255, 255, 255), emit=1.5)
        prim(char, "cube", (e.x, e.y + 0.04, e.z + 0.27 + brow), (0.22, 0.06, 0.05), rgb(40, 28, 24), rot=(0, sx * 0.18, 0), bevel=0.02)
    if mouth:  # a smile: the lower half of a thin ring, facing forward
        ob = prim(char, "torus", (f.x, f.y - hr * 0.84, f.z - 0.3), (1, 1, 1), rgb(110, 45, 45), rot=(math.radians(90), 0, 0), R=0.13, r=0.028)
        bm = bmesh.new(); bm.from_mesh(ob.data)
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.y > -0.03], context="VERTS")
        bm.to_mesh(ob.data); bm.free()

# the shared body: a stylised human about 5.6 tall (s scales it; the kid is s 0.78 with a bigger head) -----------------
def body(char, x0, col, s=1.0, head=0.82, arms=None, skirt=None):
    P = lambda x, y, z: Vector((x0 + x * s, y * s, z * s))
    hipZ = 2.35
    skin = []; top = []; bottom = []; shoes = []
    bottom.append(ell(P(0, 0, hipZ + 0.2), 0.6 * s, (1.2, 0.85, 0.75)))
    for sx in (-1, 1):
        bottom.append(limb(P(sx * 0.3, 0, hipZ), P(sx * 0.33, -0.02, 1.25), 0.27 * s))
        bottom.append(limb(P(sx * 0.33, -0.02, 1.25), P(sx * 0.35, 0.02, 0.42), 0.22 * s))
        shoes.append(ell(P(sx * 0.36, -0.16, 0.2), 0.26 * s, (1.05, 1.6, 0.8)))
    if skirt:
        bottom.append(ell(P(0, 0, skirt[0]), skirt[1] * s, (1.2, 0.95, 1.0)))
    top.append(ell(P(0, 0, 3.45), 0.68 * s, (1.25, 0.78, 1.0)))
    top.append(ell(P(0, 0, 2.85), 0.55 * s, (1.1, 0.75, 0.9)))
    hands = {}
    arms = arms or {}
    for sx in (-1, 1):
        sh = P(sx * 0.82, 0, 3.8)
        el, wr = arms.get(sx, (P(sx * 0.98, 0.04, 3.0), P(sx * 1.02, -0.04, 2.3)))
        top.append(limb(sh, el, 0.24 * s)); top.append(limb(el, wr, 0.2 * s))
        hand = wr + (wr - el).normalized() * 0.2 * s
        skin.append(ell(hand, 0.2 * s, (0.95, 0.8, 1.15)))
        hands[sx] = hand
    skin.append(limb(P(0, 0, 3.9), P(0, 0, 4.35), 0.2 * s))
    f = P(0, 0, 4.85) + Vector((0, 0, (head - 0.82) * 0.8))
    skin.append(ell(f, head * s, (0.95, 0.92, 1.05)))
    region(char, "skin", col["skin"], skin)
    region(char, "top", col["top"], top)
    region(char, "bottom", col["bottom"], bottom)
    region(char, "shoes", col["shoes"], shoes, rough=0.35)
    HEADS[char] = (f.copy(), head * s * 1.05)  # head centre and its visible half-height (the ellipsoid is 1.05 tall)
    return f, head * s, hands, P

HEADS = {}
# exec'd by the send-ready image scripts with COLS_OVERRIDE / BUILD_ONLY set; standalone it renders the concept image
COLS = globals().get("COLS_OVERRIDE", [-5.8, -2.9, 0.0, 2.9, 5.8])

# STIRRUP PEONY -------------------------------------------------------------------------------------------------------
def peony(x0):
    c = "peony"
    f, hr, hands, P = body(c, x0, {"skin": rgb(232, 177, 130), "top": rgb(130, 214, 170), "bottom": rgb(64, 98, 158), "shoes": rgb(176, 118, 66)})
    region(c, "hair", rgb(58, 38, 30), [ell(f + Vector((0, 0.12, 0.22)), hr * 1.02, (1.0, 0.98, 0.9)),
                                        ell(f + Vector((0.15, -0.35, 0.62)), 0.38, (1.5, 0.9, 0.7))])
    # the bloom: petals round a heart, pinned at the left of the hair
    bc = f + Vector((-0.6, -0.42, 0.62))
    for i in range(8):  # two rings of petals round a heart, facing forward
        a = i * math.tau / 8
        rr, dy = (0.3, 0.0) if i % 2 == 0 else (0.2, -0.07)
        prim(c, "sphere", bc + Vector((rr * math.cos(a), dy, rr * math.sin(a))), (0.34, 0.14, 0.24),
             rgb(255, 105, 170) if i % 2 == 0 else rgb(255, 150, 200), rot=(0, -a, 0), rough=0.6)
    prim(c, "sphere", bc + Vector((0, -0.14, 0)), (0.22, 0.16, 0.22), rgb(196, 30, 110))
    region(c, "tee", rgb(245, 240, 230), [ell(P(0, -0.42, 3.4), 0.3, (0.9, 0.35, 1.3))])
    prim(c, "cone", P(0, -0.62, 3.45), (0.9, 0.9, 0.08), rgb(255, 196, 48), rot=(math.radians(90), math.radians(180), 0))
    face(c, f, hr)

# YOUR MOTHER ---------------------------------------------------------------------------------------------------------
def mom(x0):
    c = "mom"
    s = 1.0
    P0 = lambda x, y, z: Vector((x0 + x, y, z))
    arms = {-1: (P0(-0.85, -0.45, 3.05), P0(-0.5, -0.95, 2.85)), 1: (P0(0.85, -0.45, 3.05), P0(0.5, -0.95, 2.85))}
    f, hr, hands, P = body(c, x0, {"skin": rgb(156, 102, 68), "top": rgb(255, 150, 110), "bottom": rgb(122, 62, 96), "shoes": rgb(70, 52, 52)},
                           arms=arms, skirt=(1.75, 0.62))
    region(c, "hair", rgb(46, 32, 28), [ell(f + Vector((0, 0.1, 0.2)), hr * 1.02, (1.0, 1.0, 0.92)), ball(f + Vector((0, 0.35, 0.95)), 0.36)])
    region(c, "apron", rgb(245, 238, 220), [ell(P(0, -0.5, 2.6), 0.5, (1.0, 0.2, 1.9))], rough=0.7)
    dish = (hands[-1] + hands[1]) / 2 + Vector((0, -0.12, 0.12))
    prim(c, "cyl", dish, (1.15, 1.15, 0.32), rgb(205, 55, 45), bevel=0.04, rough=0.3)
    prim(c, "sphere", dish + Vector((0, 0, 0.14)), (0.95, 0.95, 0.5), rgb(205, 205, 215), rough=0.2)
    face(c, f, hr, brow=0.03)

# A KID FROM YOUR OLD BLOCK -------------------------------------------------------------------------------------------
def kid(x0):
    c = "kid"
    s = 0.78
    f, hr, hands, P = body(c, x0, {"skin": rgb(198, 134, 90), "top": rgb(60, 180, 160), "bottom": rgb(52, 52, 62), "shoes": rgb(240, 240, 245)}, s=s, head=1.0)
    orange = rgb(255, 140, 40)
    region(c, "cap", orange, [ell(f + Vector((0, 0.08, 0.3)), hr * 1.0, (1.0, 1.0, 0.78))])
    prim(c, "cyl", f + Vector((0, -hr * 0.95, hr * 0.42)), (0.95, 0.75, 0.08), orange, rot=(math.radians(-8), 0, 0), bevel=0.02)
    region(c, "hood", rgb(48, 160, 140), [ell(P(0, 0.45, 3.95), 0.42, (1.5, 0.8, 0.6))])
    neck = P(0, 0, 3.88)
    prim(c, "torus", neck + Vector((0, -0.05, 0)), (1, 1, 1), rgb(40, 40, 48), R=0.42, r=0.06)
    for sx in (-1, 1):
        prim(c, "cyl", neck + Vector((sx * 0.4, -0.25, -0.05)), (0.42, 0.42, 0.16), orange, rot=(math.radians(90), 0, sx * math.radians(25)), bevel=0.03)
    prim(c, "cube", P(0, 0.62, 3.0), (1.05, 0.5, 1.2), orange, bevel=0.15)
    face(c, f, hr, brow=-0.02)

# THE GOSSIP BLOGGER --------------------------------------------------------------------------------------------------
def blogger(x0):
    c = "blogger"
    P0 = lambda x, y, z: Vector((x0 + x, y, z))
    arms = {1: (P0(1.35, -0.2, 4.15), P0(1.25, -0.55, 5.0))}
    f, hr, hands, P = body(c, x0, {"skin": rgb(255, 214, 180), "top": rgb(255, 200, 0), "bottom": rgb(255, 200, 0), "shoes": rgb(30, 30, 36)},
                           arms=arms, skirt=(2.0, 0.62))
    region(c, "hair", rgb(120, 60, 180), [ell(f + Vector((0, 0.2, 0.1)), hr * 1.06, (1.06, 1.0, 1.0)),
                                         ell(f + Vector((0.1, -0.5, 0.58)), 0.28, (2.0, 0.5, 0.5))])
    for sx in (-1, 1):
        prim(c, "cyl", f + Vector((sx * 0.33, -hr * 0.98, 0.05)), (0.42, 0.42, 0.06), rgb(16, 16, 22), rot=(math.radians(90), 0, 0), rough=0.1)
    prim(c, "cube", f + Vector((0, -hr * 0.99, 0.12)), (0.24, 0.05, 0.05), rgb(16, 16, 22))
    ph = hands[1] + Vector((0, -0.08, 0.38))
    prim(c, "cube", ph, (0.42, 0.07, 0.8), rgb(255, 70, 150), rot=(0, 0, math.radians(-15)), bevel=0.06)
    prim(c, "sphere", ph + Vector((-0.12, -0.06, 0.28)), (0.08, 0.04, 0.08), rgb(255, 255, 255), emit=4)
    face(c, f, hr, eyes=False)

# A REP FROM {sponsor} ------------------------------------------------------------------------------------------------
def rep(x0):
    c = "rep"
    f, hr, hands, P = body(c, x0, {"skin": rgb(110, 70, 48), "top": rgb(176, 180, 190), "bottom": rgb(150, 154, 166), "shoes": rgb(30, 30, 34)})
    region(c, "hair", rgb(22, 20, 22), [ell(f + Vector((0.05, 0.1, 0.3)), hr * 1.0, (1.0, 0.98, 0.78)), ell(f + Vector((0.2, -0.25, 0.65)), 0.32, (1.6, 1.0, 0.6))])
    region(c, "shirt", rgb(240, 240, 245), [ell(P(0, -0.42, 3.5), 0.24, (0.95, 0.3, 1.6))])
    for sx in (-1, 1):
        prim(c, "cube", P(sx * 0.26, -0.5, 3.45), (0.2, 0.05, 0.8), rgb(120, 124, 136), rot=(0, sx * math.radians(-16), 0), bevel=0.03)
    prim(c, "cube", P(0, -0.62, 3.35), (0.14, 0.05, 0.72), rgb(180, 110, 255), bevel=0.03, emit=1.5)
    bag = hands[-1] + Vector((-0.08, 0, -0.55))
    prim(c, "cube", bag, (0.3, 0.8, 0.8), rgb(120, 60, 210), bevel=0.05)
    prim(c, "torus", hands[-1] + Vector((-0.08, 0, -0.1)), (1, 1, 1), rgb(120, 60, 210), rot=(0, math.radians(90), 0), R=0.2, r=0.035)
    face(c, f, hr, brow=0.04)

for fn, x in zip((peony, mom, kid, blogger, rep), COLS):
    fn(x)

# decimate every character's meshes down to TRI_BUDGET, then report ----------------------------------------------------
def tris(ob):
    dg = bpy.context.evaluated_depsgraph_get()
    me = ob.evaluated_get(dg).to_mesh()
    n = sum(len(p.vertices) - 2 for p in me.polygons)
    ob.evaluated_get(dg).to_mesh_clear()
    return n
report = []
for c, obs in char_objs.items():
    before = sum(tris(o) for o in obs)
    ratio = min(1.0, TRI_BUDGET / max(1, before))
    for o in obs:
        if tris(o) > 300:
            d = o.modifiers.new("dec", "DECIMATE"); d.ratio = max(ratio, 300 / tris(o))
    after = sum(tris(o) for o in obs)
    report.append((c, before, after, len(obs)))
for r in report:
    print("TRIS %-8s before %6d  after %5d  objects %d" % r)

if not globals().get("BUILD_ONLY"):
    # names, title, floor, light, camera ----------------------------------------------------------------------------------
    def text(body_, loc, size, col, align="CENTER", bold=False, emit=0.0):
        cu = bpy.data.curves.new("t", "FONT"); cu.body = body_; cu.size = size; cu.align_x = align
        ob = bpy.data.objects.new("t", cu); ob.location = loc; ob.rotation_euler = (math.radians(90), 0, 0)
        cu.materials.append(mat("txt" + body_[:8], col, 0.8, emit)); coll.objects.link(ob)
        if bold: cu.offset = 0.012
        return ob
    NAMES = ["STIRRUP PEONY", "YOUR MOTHER", "A KID FROM\nYOUR OLD BLOCK", "THE GOSSIP\nBLOGGER", "A REP FROM\nNITE OWL ENERGY"]
    for x, n in zip(COLS, NAMES):  # above the heads, where the game's name plate sits
        text(n.replace("\n", " "), (x, -0.4, 6.55), 0.22, rgb(225, 30, 130), emit=0.35)
    lo, hi = min(r[2] for r in report), max(r[2] for r in report)
    text("C · MODELLED MESH", (-8.4, 2.5, 8.25), 0.62, rgb(255, 60, 160), align="LEFT")
    text("Blender -> Import 3D: smooth sculpted shapes, real petals, rings, lapels. Each look pack is an upload under your account;"
         "\nevery look change is a re-import. About %d-%d triangles a character after decimation. Concept render, not in the game." % (lo, hi), (-8.4, 2.5, 7.6), 0.25, rgb(70, 70, 82), align="LEFT")

    bpy.ops.mesh.primitive_plane_add(size=80, location=(0, 0, 0))
    floor = bpy.context.active_object; floor.data.materials.append(mat("floor", rgb(214, 210, 204), 0.9))
    bpy.ops.mesh.primitive_plane_add(size=80, location=(0, 12, 0), rotation=(math.radians(90), 0, 0))
    wall = bpy.context.active_object; wall.data.materials.append(mat("wall", rgb(214, 210, 204), 0.9))
    w = bpy.data.worlds.new("w"); w.use_nodes = True
    w.node_tree.nodes["Background"].inputs["Color"].default_value = rgb(214, 210, 204)
    w.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.6
    scene.world = w
    def area(loc, energy, size, rot):
        l = bpy.data.lights.new("a", "AREA"); l.energy = energy; l.size = size
        ob = bpy.data.objects.new("a", l); ob.location = loc; ob.rotation_euler = rot; coll.objects.link(ob)
    area((-6, -12, 12), 2600, 10, (math.radians(50), 0, math.radians(-25)))
    area((9, -8, 6), 900, 8, (math.radians(70), 0, math.radians(50)))
    area((0, 8, 10), 900, 10, (math.radians(-40), 0, 0))
    cd = bpy.data.cameras.new("cam"); cd.lens = 50
    cam = bpy.data.objects.new("cam", cd); coll.objects.link(cam)
    cam.location = (0, -28.5, 4.4)
    cam.rotation_euler = (Vector((0, 0, 3.75)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    if scene.render.engine != "CYCLES":
        try:
            scene.eevee.taa_render_samples = 64
        except Exception:
            pass
    scene.render.filepath = OUT
    bpy.ops.render.render(write_still=True)
    print("MESH CONCEPT DONE", OUT, scene.render.engine)
