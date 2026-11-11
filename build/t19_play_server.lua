-- Server, during play: two pretend producers queue on the live monitors (Studio-only hook, fake ids -1901/-1902):
-- the first airs, the second waits, screens show UP NEXT, a duplicate is refused. Left in place for t19b.
local SSS, RS = game:GetService("ServerScriptService"), game:GetService("ReplicatedStorage")
local mon = SSS.OK._StudioMonitorHook
local NP = RS.OK.NowPlaying
local DAWCfg = require(RS.OK.Modules.DAWConfig)
local pat = DAWCfg.DefaultPattern
mon:Invoke("Cancel", -1901); mon:Invoke("Cancel", -1902)
local t0 = os.clock(); while NP:GetAttribute("Active") and os.clock() - t0 < 25 do task.wait(0.2) end
assert(not NP:GetAttribute("Active"), "monitors still busy from an earlier test")
task.wait(3.2)
local a = mon:Invoke("Enqueue", -1901, "Ava Test", pat, 120)
local b = mon:Invoke("Enqueue", -1902, "Bo Test", pat, 90)
assert(a.ok and a.position == 0 and b.ok and b.position == 1, "pretend producers not queued: " .. tostring(a.reason) .. "/" .. tostring(b.reason))
assert(NP:GetAttribute("Active") and NP:GetAttribute("OwnerName") == "Ava Test" and NP:GetAttribute("UpNext") == "Bo Test", "NowPlaying/UpNext wrong")
local dup = mon:Invoke("Enqueue", -1902, "Bo Test", pat, 90)
assert(not dup.ok and dup.reason == "inline" and dup.position == 1, "duplicate place allowed")
local side = workspace.OKStudio.ControlRoom.Screen_Side.Text.Label.Text
assert(side:find("NOW PLAYING") and side:find("Ava Test") and side:find("UP NEXT: Bo Test"), "side screen missing NOW PLAYING / UP NEXT: " .. side)
return "T19 PLAY OK: Ava Test on air, Bo Test up next on the screens, duplicate refused"
