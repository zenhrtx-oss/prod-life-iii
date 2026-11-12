import subprocess, json, sys, time, select
# usage: mcp_call.py <tool> '<json args>'   |  mcp_call.py --schemas name1,name2
p = subprocess.Popen(['/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
def send(o): p.stdin.write(json.dumps(o)+'\n'); p.stdin.flush()
def recv(id_, timeout=60):
    end=time.time()+timeout
    while time.time()<end:
        r,_,_=select.select([p.stdout],[],[],0.5)
        if r:
            line=p.stdout.readline()
            if not line: return None
            try: m=json.loads(line)
            except: continue
            if m.get("id")==id_: return m
    return None
send({"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"claude-probe","version":"0"}}}); recv(1)
send({"jsonrpc":"2.0","method":"notifications/initialized"})
if sys.argv[1]=="--schemas":
    send({"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}); m=recv(2)
    want=sys.argv[2].split(",")
    for t in m["result"]["tools"]:
        if t["name"] in want:
            print("##", t["name"], "::", t.get("description","")[:400].replace("\n"," "))
            print(json.dumps(t.get("inputSchema",{}).get("properties",{}))[:1200]); print("required:", t.get("inputSchema",{}).get("required")); print()
elif sys.argv[1] in ("--luau","--luauc","--luaus"):
    dm = {"--luau":"Edit","--luauc":"Client","--luaus":"Server"}[sys.argv[1]]
    sys.argv=[sys.argv[0],"execute_luau",json.dumps({"studio_id":"x","datamodel_type":dm,"code":open(sys.argv[2]).read()})]
if sys.argv[1]!="--schemas":
    # wait for Studio to attach to this proxy (Studio retries its websocket every ~3s)
    studios=[]
    for i in range(30):
        send({"jsonrpc":"2.0","id":100+i,"method":"tools/call","params":{"name":"list_roblox_studios","arguments":{}}}); m=recv(100+i, timeout=10)
        try: studios=json.loads(m["result"]["content"][0]["text"]).get("studios",[])
        except Exception: studios=[]
        if studios: break
        time.sleep(1)
    args=json.loads(sys.argv[2]) if len(sys.argv)>2 else {}
    if "studio_id" in args and args["studio_id"] not in [s["id"] for s in studios]:
        pick = studios[0] if len(studios) == 1 else None
        if pick is None:
            # several Studios open (e.g. a scratch Baseplate): pick the game place by its placeId, never guess
            import os
            want = os.environ.get("OK_PLACE_ID", "139218961436722")
            match = [s for s in studios if str(s.get("placeId")) == want]
            if len(match) == 1: pick = match[0]
        if pick is None:
            print("GUARD: %d Studio instances connected and none (or several) is place %s; refusing to pick one automatically" % (len(studios), os.environ.get("OK_PLACE_ID", "139218961436722") if len(studios) != 1 else "?")); p.terminate(); sys.exit(3)
        sys.stderr.write("STUDIO_ID switched to %s (%s)\n" % (pick["id"], pick.get("name")))
        args["studio_id"]=pick["id"]
    sys.stderr.write("studios=%s\n" % json.dumps(studios))
    send({"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":sys.argv[1],"arguments":args}}); m=recv(3, timeout=120)
    if m is None: print("TIMEOUT/no response")
    else:
        res=m.get("result") or m.get("error")
        for c in (res.get("content",[]) if isinstance(res,dict) else []):
            if c.get("type")=="image":
                import base64; fn=f"capture_{int(time.time())}.{c.get('mimeType','image/png').split('/')[-1]}"; open(fn,"wb").write(base64.b64decode(c["data"])); print("IMAGE saved:", fn)
            else: print(c.get("text") if c.get("type")=="text" else json.dumps(c)[:300])
        if not isinstance(res,dict) or "content" not in res: print(json.dumps(res)[:3000])
p.terminate()
