-- Server, during play: the live career system through its Studio hooks only (no system is required and called here).
-- Delivery feeds (first 2/3-star only), attributes after Take and Publish, State's shape, and a fit equipped through
-- the live Gear (Gear_Get's state and the Fits attribute). Leaves the career and the gear reset.
local p = game:GetService("Players"):GetPlayers()[1]; assert(p, "no player")
local SOK = game:GetService("ServerScriptService").OK
local hook = SOK:WaitForChild("_StudioCareerHook", 5); assert(hook, "no _StudioCareerHook (did Career.Init run?)")
local test = SOK._StudioTestHook
local uid = p.UserId
local out = {}
local function stats() return hook:Invoke("Get", uid) end

assert(hook:Invoke("Reset", uid) == true, "career reset failed")
local c0 = stats()
assert(c0.aura == 0 and c0.followers == 0 and p:GetAttribute("Aura") == 0 and p:GetAttribute("Followers") == 0, "reset left stats behind")
-- delivery feeds: a first 3-star, a 3-star repeat, a first 2-star, a first 1-star
hook:Invoke("FeedDelivered", uid, 3, true)
local c1 = stats(); assert(c1.followers == 120 and c1.aura == 10, "first 3-star delivery should pay +120 followers +10 aura, got " .. c1.followers .. "/" .. c1.aura)
hook:Invoke("FeedDelivered", uid, 3, false)
local c2 = stats(); assert(c2.followers == 120 and c2.aura == 10, "a repeat delivery fed the career")
hook:Invoke("FeedDelivered", uid, 2, true)
local c3 = stats(); assert(c3.followers == 160 and c3.aura == 15, "first 2-star delivery should pay +40 followers +5 aura, got " .. c3.followers .. "/" .. c3.aura)
hook:Invoke("FeedDelivered", uid, 1, true)
local c4 = stats(); assert(c4.followers == 160 and c4.aura == 15, "a 1-star delivery fed the career")
assert(p:GetAttribute("Followers") == 160 and p:GetAttribute("Aura") == 15, "Followers/Aura attributes don't match the career")
table.insert(out, "delivery feeds: first 3-star +120/+10, repeat nothing, first 2-star +40/+5, 1-star nothing; attributes match")
-- Take publishes
assert(hook:Invoke("Set", uid, { aura = 100 }) == true and p:GetAttribute("Aura") == 100, "Set did not publish Aura")
assert(hook:Invoke("Take", uid, "aura", 30) == 30 and p:GetAttribute("Aura") == 70, "Take did not publish: Aura " .. tostring(p:GetAttribute("Aura")))
table.insert(out, "Set aura 100, Take 30 -> Aura attribute 70")
-- State
local st = hook:Invoke("State", uid)
assert(st and #st.gates == 2 and #st.gear == 7 and st.stats.aura == 70, "State should hold 2 gates and 7 gear rows")
table.insert(out, "State: 2 gates, 7 gear rows")
-- Publish restores Sponsor and CareerGates
assert(hook:Invoke("Set", uid, { sponsors = 1, sponsor = "t41_brand" }) == true, "Set sponsor failed")
local sp0, cg0 = p:GetAttribute("Sponsor"), p:GetAttribute("CareerGates")
assert(type(sp0) == "string" and sp0 ~= "" and type(cg0) == "string" and cg0:find("sponsor_tv"), "sponsor attributes not published: " .. tostring(sp0) .. " / " .. tostring(cg0))
p:SetAttribute("Sponsor", nil); p:SetAttribute("CareerGates", nil)
assert(hook:Invoke("Publish", uid) == true and p:GetAttribute("Sponsor") == sp0 and p:GetAttribute("CareerGates") == cg0, "Publish did not restore Sponsor/CareerGates")
assert(hook:Invoke("Set", uid, { sponsor = false }) == true and p:GetAttribute("Sponsor") == nil, "sponsor = false did not clear the Sponsor attribute")
table.insert(out, "Publish restores Sponsor '" .. sp0 .. "' and CareerGates '" .. cg0 .. "'; sponsor = false clears Sponsor")
-- a fit through the live Gear
assert(test:Invoke("GrantGear", uid, "fit_cuban") == true, "GrantGear failed")
local function item(state, id) for _, it in ipairs(state.items) do if it.id == id then return it end end; return nil end
local e1 = hook:Invoke("Equip", uid, "fit_cuban")
assert(e1 and e1.ok and item(e1.state, "fit_cuban").equipped == true, "fit_cuban not equipped: " .. tostring(e1 and e1.reason))
assert((p:GetAttribute("Fits") or ""):find("fit_cuban"), "Fits attribute lacks fit_cuban: " .. tostring(p:GetAttribute("Fits")))
local e2 = hook:Invoke("Equip", uid, "fit_cuban")
assert(e2 and e2.ok and item(e2.state, "fit_cuban").equipped == false and (p:GetAttribute("Fits") or "") == "", "second Equip did not take the fit off")
table.insert(out, "fit_cuban equips (Gear_Get state equipped, Fits attribute) and toggles off")
assert(test:Invoke("ResetGear", uid) == true and hook:Invoke("Reset", uid) == true, "cleanup failed")
return "T41 PLAY OK\n" .. table.concat(out, "\n")
