-- Server, during play (after t44): the Studio Two gate, a fit and the sponsor ticker through the Studio hooks only.
-- With the needs and the money met the door points to the Career tab; Unlock puts studio_two in CareerGates while the
-- server's door keeps colliding (it opens on the owner's client only). fit_cuban builds OK_Fit_cuban (10 massless,
-- non-colliding links) and is back within 5 s of LoadCharacter. A sponsor deal puts "SPONSORED BY" on the lounge TV
-- within 10 s, the TV's own prompt is refused while the ticker owns it, and dropping the deal restores the TV's text
-- within 10 s. Leaves studio_two owned (t44c walks through the door) and clears the sponsor and the fit.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local SOK = game:GetService("ServerScriptService").OK
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook (did Career.Init run?)")
local hook = SOK:WaitForChild("_StudioUnlocksHook", 5); assert(hook, "no _StudioUnlocksHook (did Unlocks.Init run?)")
local test = SOK._StudioTestHook
local uid = p.UserId
local out = {}
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.1) end; return fn() end
local function listHas(attr, id) return ("," .. (p:GetAttribute(attr) or "") .. ","):find("," .. id .. ",", 1, true) ~= nil end

-- the gate: Career tab, Unlock, the server's door stays shut
assert(career:Invoke("Reset", uid) == true, "career reset failed")
assert(career:Invoke("Set", uid, { placements = 1, aura = 300, money = 5000 }) == true, "career Set failed")
local d1 = hook:Invoke("Door", uid)
assert(type(d1) == "string" and d1:find("Career tab", 1, true), "needs and money met: the door should point to the Career tab, said " .. tostring(d1))
local u = career:Invoke("Unlock", uid, "studio_two")
assert(type(u) == "table" and u.ok, "Unlock studio_two failed: " .. tostring(u and u.reason))
assert(listHas("CareerGates", "studio_two"), "CareerGates lacks studio_two: " .. tostring(p:GetAttribute("CareerGates")))
local door = workspace.OK_Gates.StudioTwoDoor
assert(door.CanCollide == true, "the server's door must keep colliding (it opens on the owner's client only)")
local d2 = hook:Invoke("Door", uid)
assert(d2 == "The Hall is open for you", "an owner's door toast: " .. tostring(d2))
table.insert(out, "door: '" .. d1 .. "'; Unlock -> CareerGates '" .. tostring(p:GetAttribute("CareerGates")) .. "', the server's door still collides; then '" .. d2 .. "'")

-- a fit: built on the character, back after a respawn
local function fitOn(char)
  local m = char and char:FindFirstChild("OK_Fit_cuban")
  if not m then return false end
  local n = 0
  for _, d in ipairs(m:GetDescendants()) do
    if d:IsA("BasePart") then n += 1; if not d.Massless or d.CanCollide then return false end end
  end
  return n == 10
end
assert(test:Invoke("GrantGear", uid, "fit_cuban") == true, "GrantGear fit_cuban failed")
if not listHas("Fits", "fit_cuban") then
  local e = hook:Invoke("Equip", uid, "fit_cuban")
  assert(type(e) == "table" and e.ok, "Equip fit_cuban failed: " .. tostring(e and e.reason))
end
assert(listHas("Fits", "fit_cuban"), "Fits attribute lacks fit_cuban: " .. tostring(p:GetAttribute("Fits")))
assert(waitFor(function() return fitOn(p.Character) end, 3), "OK_Fit_cuban (10 massless, non-colliding links) not on the character")
local before = p.Character
p:LoadCharacter()
assert(waitFor(function() return p.Character ~= nil and p.Character ~= before and fitOn(p.Character) end, 5), "the fit did not come back within 5 s of LoadCharacter")
table.insert(out, "fit_cuban: 10 massless, non-colliding links on the character, back after LoadCharacter")

-- the sponsor ticker on the lounge TV
local NP = RS.OK.NowPlaying
local tv = workspace.OKStudio.Lounge.TV_Screen; local lbl = tv.ScreenText.Label
assert(waitFor(function() return NP:GetAttribute("Active") ~= true and tv:GetAttribute("SavedText") == nil and tv:GetAttribute("TickerSaved") == nil end, 25),
  "the TV is still busy (Active " .. tostring(NP:GetAttribute("Active")) .. ", SavedText " .. tostring(tv:GetAttribute("SavedText")) .. ", TickerSaved " .. tostring(tv:GetAttribute("TickerSaved")) .. ")")
local root = p.Character:WaitForChild("HumanoidRootPart", 5)
assert(root and root.Position.X >= 0 and root.Position.X <= 94 and math.abs(root.Position.Z) <= 12, "the player should be in the hub after the respawn")
local original = lbl.Text
local sponsor = require(RS.OK.Data.WalkIns).Sponsors[1]
assert(career:Invoke("Set", uid, { sponsor = sponsor.id, sponsors = 1 }) == true, "career Set sponsor failed")
local name = p:GetAttribute("Sponsor")
assert(type(name) == "string" and name ~= "" and listHas("CareerGates", "sponsor_tv"), "the deal is not published: Sponsor " .. tostring(name) .. ", CareerGates " .. tostring(p:GetAttribute("CareerGates")))
local shown
assert(waitFor(function() shown = hook:Invoke("Ticker"); return type(shown) == "string" and shown:find("SPONSORED BY", 1, true) ~= nil end, 10),
  "the ticker did not show SPONSORED BY within 10 s; the TV says " .. tostring(shown))
assert(shown == "SPONSORED BY\n" .. name .. "\nprod. " .. p.DisplayName, "ticker text: " .. shown)
assert(tv:GetAttribute("TickerSaved") == original, "TickerSaved should hold the TV's own text")
table.insert(out, "ticker: '" .. shown:gsub("\n", " / ") .. "' within 10 s; TickerSaved keeps the TV's text")
local now = lbl.Text
local acted, said = hook:Invoke("TV", uid)
assert(acted == false, "the TV prompt should be refused while the ticker owns the TV")
assert(type(said) == "string" and said:lower():find("sponsors", 1, true), "the refusal toast should mention sponsors: " .. tostring(said))
assert(lbl.Text == now, "the refused TV prompt changed the screen")
table.insert(out, "TV prompt refused: '" .. said .. "', screen unchanged")
assert(career:Invoke("Set", uid, { sponsor = false }) == true, "career Set sponsor = false failed")
assert(waitFor(function() return lbl.Text == original and tv:GetAttribute("TickerSaved") == nil end, 10),
  "the TV's own text did not come back within 10 s: '" .. lbl.Text .. "', TickerSaved " .. tostring(tv:GetAttribute("TickerSaved")))
table.insert(out, "deal dropped: the TV's own text is back and TickerSaved is clear")

-- clean up: the fit off and gone, the gate kept for t44c
local e2 = hook:Invoke("Equip", uid, "fit_cuban")
assert(type(e2) == "table" and e2.ok and not listHas("Fits", "fit_cuban"), "a second Equip did not take the fit off")
assert(waitFor(function() return p.Character ~= nil and p.Character:FindFirstChild("OK_Fit_cuban") == nil end, 2), "OK_Fit_cuban is still on the character")
assert(test:Invoke("ResetGear", uid) == true, "ResetGear failed")
assert(listHas("CareerGates", "studio_two"), "studio_two must stay owned for t44c")
table.insert(out, "cleanup: fit off (Equip toggles), gear reset, studio_two kept for t44c")
return "T44B PLAY OK\n" .. table.concat(out, "\n")
