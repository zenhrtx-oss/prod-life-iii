import json, re, sys
S = sys.argv[1]
d = json.load(open(S + "/x/raw.json"))
src = open("/Users/work/Desktop/OK projects/OK ROBLOX/roblox_studio_notes/ok_studio/src/ReplicatedStorage/OK/Data/WalkIns.lua", encoding="utf-8").read().split("\n")
line_of = {}
for i, l in enumerate(src, 1):
    m = re.search(r'\{ id = "([a-z0-9_]+)", visitor', l)
    if m: line_of.setdefault(m.group(1), i)
cards = []
for c in d["cards"]:
    c = dict(c); c["fu"] = False; cards.append(c)
for c in d["followups"]:
    c = dict(c); c["fu"] = True; cards.append(c)
missing = [c["id"] for c in cards if c["id"] not in line_of]
planted = {}
def outs(c):
    for i, ch in enumerate(c.get("choices", [])):
        for k in ("good", "bad", "rare"):
            if ch.get(k): yield ("c", i, k, ch[k])
    if "resolve" in c:
        for k in ("good", "bad"):
            if c["resolve"].get(k): yield ("n", -1, k, c["resolve"][k])
for c in cards:
    for kind, i, k, o in outs(c):
        if "plant" in o:
            planted.setdefault(o["plant"]["id"], []).append({"card": c["id"], "choice": i, "out": k})
SYSTEM = {
 "sponsor_drop": "The game plants this when you arrive at a visit with Aura under your sponsor's floor.",
 "sponsor_warning": "Planted instead of the drop when the rep likes you (relationship 1 or more).",
 "mom_plaque": "The game plants this when your first HIT lands.",
 "tier_buzzing": "Planted the first time you cross 1,000 followers.",
 "tier_known": "Planted the first time you cross 5,000 followers.",
 "tier_famous": "Planted the first time you cross 20,000 followers.",
 "tier_icon": "Planted the first time you cross 100,000 followers.",
 "cold_news": "Sent once when you go cold. The normal pick never draws it.",
}
for c in cards:
    c["src"] = line_of.get(c["id"])
    if c["id"] in planted: c["from"] = planted[c["id"]]
    if c["id"] in SYSTEM: c["sys"] = SYSTEM[c["id"]]
cfg = d["config"]
keep = {k: cfg[k] for k in ["Career", "Phone", "Life", "Gear", "Levels", "Ranks", "Hints", "Daily", "Weekly", "Cypher", "Fire", "Unlocks"]}
w = dict(cfg["WalkIns"]); w.pop("Waypoints", None); keep["WalkIns"] = w
keep["Cred"] = cfg["Cred"]; keep["XP"] = cfg["XP"]
out = {"visitors": d["visitors"], "sponsors": d["sponsors"], "cards": cards, "relFlags": d["relFlags"],
       "waitLines": d["waitLines"], "noteLines": d["noteLines"], "artists": d["artists"]["Artists"], "briefs": d["artists"]["Briefs"],
       "config": keep, "meta": {"file": "src/ReplicatedStorage/OK/Data/WalkIns.lua", "extracted": "2026-11-10",
       "cards": len(d["cards"]), "followups": len(d["followups"])}}
open(S + "/site/data.js", "w", encoding="utf-8").write("window.PL=" + json.dumps(out, ensure_ascii=False, separators=(",", ":")) + ";")
print("cards", len(cards), "missing line:", missing, "size KB", len(json.dumps(out)) // 1024)
print("no origin followups:", [c["id"] for c in cards if c["fu"] and "from" not in c and "sys" not in c])
print(len(d["artists"]["Briefs"]), [ (a.get('k')) for b in d["artists"]["Briefs"] for a in b["asks"]+([b["bonus"]] if b.get("bonus") else [])].__len__())
print(sorted({a['k'] for b in d["artists"]["Briefs"] for a in b["asks"]+([b["bonus"]] if b.get("bonus") else [])}))
print(json.dumps(cfg["Gear"][9:]))
