-- Server, during play (after t25c): a pretend producer airs a distinctive beat.
local SSS, RS = game:GetService("ServerScriptService"), game:GetService("ReplicatedStorage")
local mon = SSS.OK._StudioMonitorHook; local NP = RS.OK.NowPlaying
local Check = require(RS.OK.Modules.BriefCheck); local Cfg = require(RS.OK.Modules.DAWConfig)
local maya = "1001001001001000" .. "0000100100001000" .. "0010000000100000" .. "1111000011110000" .. string.rep("0", 16)
assert(Check.Changed(maya, Check.References(Cfg)) >= 8, "test beat not distinctive")
local t0 = os.clock(); while NP:GetAttribute("Active") and os.clock() - t0 < 25 do task.wait(0.2) end
task.wait(3.2)
local r = mon:Invoke("Enqueue", -2601, "Maya Test", maya, 100)
assert(r.ok and r.position == 0, "airing failed")
return "T26 PLAY OK: Maya Test on air"
