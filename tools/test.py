#!/usr/bin/env python3
"""Run the OK Studio test suite against the open Studio place.
  python3 tools/test.py            # edit checks + play tests
  python3 tools/test.py --edit     # edit checks only
  python3 tools/test.py --play t10 # play tests whose name contains t10
  python3 tools/test.py --spec     # CLI luau specs only (tools/spec.sh), no Studio calls
Every run except --play first runs the CLI specs (spec/*_spec.lua) with the same selectors.
Exit code 0 only if everything passes."""
import pathlib, signal, subprocess, sys, time
ROOT = pathlib.Path(__file__).resolve().parent.parent
PAUSE_OFF = ROOT / "tools" / "walkins_pause_off.lua"
B = ROOT / "build"; MCP = ROOT / "tools" / "mcp_call.py"
EDIT = ["t01_check.lua", "t02_check.lua", "t03_check.lua", "t04_check.lua", "t05_check.lua", "t06_check.lua", "t07_check.lua", "t10_check.lua"]
EDIT += sorted(p.name for p in B.glob("t*_check.lua") if p.name not in EDIT) + ["09_qa.lua"]  # every check file, none skipped
PLAY = sorted(p.name for p in B.glob("t*_play_client.lua")) + sorted(p.name for p in B.glob("t*_play_server.lua"))
PLAY = sorted(PLAY)
def mcp(*a, timeout=400):
    r = subprocess.run([sys.executable, "-I", str(MCP), *a], capture_output=True, text=True, timeout=timeout); return r.stdout.strip()
def clean(out): return out.split("CommandExecution:54: ", 1)[-1] if "CommandExecution:54" in out else out
import re
OK_RE = re.compile(r"^(T\d+[A-Z]?( PLAY)?|QA) OK\b")
BENIGN = ("not authorized to access Asset", "failed due to: User is not authorized")
def run(kind, files):
    res = []
    for f in files:
        raw = mcp({"edit": "--luau", "client": "--luauc", "server": "--luaus"}[kind], str(B / f))
        out = clean(raw)
        first = out.split("\n")[0]
        # strict: the script itself must return its own success marker; any error text fails
        ok = bool(OK_RE.match(first)) and "CommandExecution" not in raw and "AssistantCommand" not in raw
        res.append((f, ok, out)); print(("PASS " if ok else "FAIL ") + f + ("" if ok else "  ->  " + out[:400]))
        if ok and "-v" in sys.argv: print("     " + out.replace("\n", "\n     "))
    return res
def specs(sel):
    r = subprocess.run(["sh", str(ROOT / "tools" / "spec.sh"), *sel], capture_output=True, text=True, timeout=400)
    res = []
    for line in r.stdout.splitlines():
        if not line.startswith(("PASS ", "FAIL ")): continue
        ok = line.startswith("PASS "); f, _, out = line[5:].partition(" -> ")
        res.append((f, ok, out)); print(("PASS " if ok else "FAIL ") + f + ("" if ok else "  ->  " + out[:400]))
    if r.returncode != 0 and all(ok for _, ok, _ in res):  # the runner itself broke: never read as green
        out = (r.stderr.strip() or r.stdout.strip() or f"exit {r.returncode}")[-400:]
        res.append(("tools/spec.sh", False, out)); print("FAIL tools/spec.sh  ->  " + out)
    return res
def done(results):
    bad = [r for r in results if not r[1]]
    print(f"\n{len(results) - len(bad)}/{len(results)} passed")
    sys.exit(1 if bad else 0)
def main():
    signal.signal(signal.SIGTERM, lambda *a: sys.exit(143))  # a kill still runs the finally blocks (WalkInsPaused cleared)
    sel = [a for a in sys.argv[1:] if not a.startswith("-")]
    results = [] if "--play" in sys.argv else specs(sel)  # CLI only: runs before the guard and any mcp() call
    if "--spec" in sys.argv: done(results)
    g = mcp("--luau", str(ROOT / "tools" / "guard.lua"))
    if not g.startswith("GUARD OK"): print("REFUSING:", g); sys.exit(2)
    state = mcp("get_studio_state", '{"studio_id":"x"}')
    if "Mode: Play" in state or "Mode: Run" in state: mcp("start_stop_play", '{"studio_id":"x","is_start":false}'); time.sleep(5)
    # in Edit, every Studio run: clear a WalkInsPaused an earlier run left behind (it is saved with the place and would
    # silence walk-ins in every later Studio Play)
    off = mcp("--luau", str(PAUSE_OFF))
    if not off.startswith("WALKINS UNPAUSED"): print("WARNING: could not clear WalkInsPaused: " + off[:200])
    if "--play" not in sys.argv: results += run("edit", [f for f in EDIT if not sel or any(s in f for s in sel)])
    if "--edit" not in sys.argv:
        plays = [f for f in PLAY if not sel or any(s in f for s in sel)]
        if plays:
            try:
                # in Edit: the walk-in scheduler stays paused through Play (Systems/WalkIns honours it in Studio only)
                paused = mcp("--luau", str(ROOT / "tools" / "walkins_pause_on.lua"))
                if not paused.startswith("WALKINS PAUSED"): print("WARNING: walk-ins not paused for Play: " + paused[:200])
                mcp("start_stop_play", '{"studio_id":"x","is_start":true}'); time.sleep(11)
                try:
                    for f in plays: results += run("server" if f.endswith("_play_server.lua") else "client", [f])
                finally:
                    log = mcp("get_console_output", '{"studio_id":"x"}')
                    errs = [l for l in log.splitlines() if (("rror" in l and "[OK]" not in l) or "[OK][ERR]" in l or "nfinite yield" in l or "Stack Begin" in l) and not any(b in l for b in BENIGN)]
                    if errs:
                        print("CONSOLE ERRORS (fail the run):\n  " + "\n  ".join(errs[-8:]))
                        results.append(("console", False, "\n".join(errs[-8:])))
                    mcp("start_stop_play", '{"studio_id":"x","is_start":false}'); time.sleep(5)
            finally:
                # back in Edit: clear it; the run can't pass with the attribute left on
                off = mcp("--luau", str(PAUSE_OFF))
                if not off.startswith("WALKINS UNPAUSED"):
                    results.append(("walkins_pause_off", False, off)); print("FAIL walkins_pause_off  ->  " + off[:400])
    done(results)
main()
