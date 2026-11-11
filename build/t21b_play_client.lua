-- Client, during play (after t21): rack refusals (level, Cred, owned) and the beat maker's locks follow owned gear.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local Buy, Get = RS.OK.Remotes.Gear_Buy, RS.OK.Remotes.Gear_Get
local daw = player.PlayerGui:WaitForChild("OK_DAW"):WaitForChild("DAW")
local out = {}
local st = Get:InvokeServer()
local function item(id) for _, it in ipairs(st.items) do if it.id == id then return it end end end
assert(item("808").owned and item("rollfx").owned and not item("swing").owned, "gear state wrong")
local r1 = Buy:InvokeServer("plate_legend"); assert(not r1.ok and r1.reason == "level", "level-10 gear sold early: " .. tostring(r1.reason))
local r2 = Buy:InvokeServer("neon_ice"); assert(not r2.ok and (r2.reason == "cred" or r2.reason == "level"), "neon sold without enough Cred: " .. tostring(r2.reason))
local r3 = Buy:InvokeServer("rollfx"); assert(not r3.ok and r3.reason == "owned", "bought owned gear twice")
local r4 = Buy:InvokeServer("nope"); assert(not r4.ok and r4.reason == "invalid", "unknown gear accepted")
table.insert(out, "refused: level-10 gear (level), Ice neon (" .. r2.reason .. "), Roll FX again (owned), unknown id")
local u = daw:GetAttribute("Unlocked") or ""
assert(u:find("Bass") and u:find("Rolls") and not u:find("Swing"), "beat maker locks do not follow gear: " .. u)
table.insert(out, "beat maker unlocks follow gear: " .. u)
return "T21B PLAY OK\n" .. table.concat(out, "\n")
