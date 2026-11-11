-- Server, during play (after t26b): when the flip airs it says "flip of Maya Test"; a pretend producer flipping the
-- player's beat gives the player +1 flip and Config.Cred.Sources.Flip.amount ($50).
local SSS, RS = game:GetService("ServerScriptService"), game:GetService("ReplicatedStorage")
local mon = SSS.OK._StudioMonitorHook; local NP = RS.OK.NowPlaying
local hook = SSS.OK._StudioTestHook
local Config = require(RS.OK.Config)
local p = game:GetService("Players"):GetPlayers()[1]
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
assert(mon:Invoke("Cancel", -2601) == "stopped", "Maya was not on air")
assert(waitFor(function() return NP:GetAttribute("Active") and NP:GetAttribute("OwnerId") == p.UserId end, 5), "the flip did not air")
assert(NP:GetAttribute("FlipOf") == "Maya Test", "FlipOf attribute: " .. tostring(NP:GetAttribute("FlipOf")))
local side = workspace.OKStudio.ControlRoom.Screen_Side.Text.Label.Text
assert(side:find("flip of Maya Test"), "screen does not say flip of: " .. side)
local hist = mon:Invoke("History")
local maya
for _, h in ipairs(hist) do if h.name == "Maya Test" then maya = h end end
-- (the table crossed a BindableFunction, so its numeric keys arrive as strings)
assert(maya and maya.creditedBy and (maya.creditedBy[p.UserId] or maya.creditedBy[tostring(p.UserId)]), "the flip credit was not recorded once on Maya's airing")
local flips0, cred0 = p:GetAttribute("Flips") or 0, hook:Invoke("GetProfile", p.UserId).cred
local got = mon:Invoke("FlipAs", 0, "Flip Test")
assert(p:GetAttribute("Flips") == flips0 + 1 and hook:Invoke("GetProfile", p.UserId).cred == cred0 + Config.Cred.Sources.Flip.amount and got == Config.Cred.Sources.Flip.amount, "original producer's side wrong")
local c = hook:Invoke("GetProfile", p.UserId)
return "T26C OK: the flip airs as 'flip of Maya Test' (screens too); being flipped gives +1 flip and +$" .. Config.Cred.Sources.Flip.amount .. " (flips " .. (flips0 + 1) .. ")"
