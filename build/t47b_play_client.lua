-- Client, during play (after t47a spawned LIL NAV X's single follow-up, navx_single, with its news rolled HIT): the
-- card opens by itself (beat maker closed, no cutaway, cypher idle), its header reads "1 OF 8 TODAY" and it shows the
-- HIT news strip. At the real viewport every choice and WALK AWAY is at least 44 px tall with its text fitting, the card
-- is inside the gui, and the Waiting chip's spot (shown for the check, with the cypher bar held shown and FIRE under it)
-- clears the HUD, the career pills, the daily/tour pill, the bar and FIRE. Forced to the safe area of an 844x390 and a
-- 667x375 phone (the screen minus this gui's real insets: OK_WalkIn is CoreUISafeInsets, shorter than the screen by the
-- top bar) the buttons stay 44 px, the card fits inside (0, 0)-vp with 16 px sides, and the news strip and all three
-- choices sit inside the Scroll rect (nothing needs scrolling). Choice 3 (a sure one) is OWN YOUR MASTERS, shown on a
-- result card at the bottom centre. Then the beat maker opens and stays open for t47d.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character; local root = char:WaitForChild("HumanoidRootPart", 5); local hum = char:WaitForChild("Humanoid", 5); local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui", 10)
local gui = pg:WaitForChild("OK_WalkIn", 10); assert(gui, "no OK_WalkIn gui (WalkInUI.Build did not run?)")
local ui = pg:WaitForChild("OK_UI", 10)
local dawGui = pg:WaitForChild("OK_DAW", 10); local daw = dawGui and dawGui:WaitForChild("DAW", 10); assert(daw, "no beat maker gui")
local bar, fire = pg.OK_Cypher.Bar, pg.OK_Fire.FireButton
local navx = require(RS.OK.Data.WalkIns).FollowupById.navx_single
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
-- rects in the walk-in gui's own space: (0, 0) is its top-left, so a forced viewport's box is (0, 0)-vp
local function rel(g) local p, s = g.AbsolutePosition - gui.AbsolutePosition, g.AbsoluteSize; return { x0 = p.X, y0 = p.Y, x1 = p.X + s.X, y1 = p.Y + s.Y } end
local function overlaps(a, b) return a.x0 < b.x1 and b.x0 < a.x1 and a.y0 < b.y1 and b.y0 < a.y1 end
local function fmt(r) return string.format("(%d,%d)-(%d,%d)", r.x0, r.y0, r.x1, r.y1) end
-- never inherit a forced size, a held bar or an open beat maker from an earlier failed run
gui:SetAttribute("ForceViewport", nil); ui:SetAttribute("ForceViewport", nil); bar:SetAttribute("ForceShow", nil)
daw:SetAttribute("CompactForced", nil); daw:SetAttribute("ViewportOverride", nil)
if daw.Visible then daw:SetAttribute("Command", "close"); task.wait(0.4) end
if hum.Sit then hum.Sit = false; task.wait(0.4) end
cam.CameraType = Enum.CameraType.Custom
local out = {}

-- 1. the card opens by itself
assert(waitFor(function() return gui:GetAttribute("Open") == true end, 15), "the card did not open within 15 s (Token '"
  .. tostring(gui:GetAttribute("Token")) .. "', Deferred " .. tostring(gui:GetAttribute("Deferred")) .. ")")
local card = gui:FindFirstChild("Card", true)
assert(card and card.Visible, "Card frame missing or hidden while Open")
assert(gui:GetAttribute("Card") == "navx_single", "card id " .. tostring(gui:GetAttribute("Card")))
local n = gui:GetAttribute("Choices")
assert(n == #navx.choices, "Choices " .. tostring(n) .. ", the card has " .. #navx.choices)
local header = card:FindFirstChild("Header", true)
assert(header and header.Text == "1 OF 8 TODAY", "header reads '" .. tostring(header and header.Text) .. "'")
local scroll, newsF = card:FindFirstChild("Scroll"), card:FindFirstChild("News", true)
assert(scroll and newsF and newsF.Visible, "no news strip on a follow-up with news (Scroll / News missing or hidden)")
local newsHead = newsF:FindFirstChild("Headline")
assert(newsHead and newsHead.Text == "HIT", "news headline reads '" .. tostring(newsHead and newsHead.Text) .. "' (t47a forced the roll to 1: HIT)")
table.insert(out, "card opened: navx_single, " .. header.Text .. ", " .. n .. " choices, news " .. newsHead.Text)
task.wait(0.3) -- the labels were filled while the card was hidden: let it render once so TextFits and the rects are current

local function buttons(where)
  for i = 1, n do
    local b = card:FindFirstChild("Choice" .. i, true)
    assert(b and b.Visible and b.AbsoluteSize.Y >= 44, where .. ": Choice" .. i .. " missing, hidden or under 44 px")
    local l = b:FindFirstChild("Label")
    assert(l and l.TextFits, where .. ": Choice" .. i .. " text doesn't fit: '" .. tostring(l and l.Text) .. "'")
  end
  local w = card:FindFirstChild("WalkAway", true)
  assert(w and w.Visible and w.AbsoluteSize.Y >= 44, where .. ": WALK AWAY missing or under 44 px")
end
-- the news strip and every choice inside the Scroll rect: all of it readable without scrolling
local function unscrolled(where)
  local sr = rel(scroll)
  local list = { News = newsF }
  for i = 1, n do list["Choice" .. i] = card:FindFirstChild("Choice" .. i, true) end
  for name, g in pairs(list) do
    local r = rel(g)
    assert(r.y0 >= sr.y0 and r.y1 <= sr.y1, where .. ": " .. name .. " " .. fmt(r) .. " is outside the Scroll " .. fmt(sr) .. " (it needs scrolling)")
  end
end
local function inside(where, vp)
  local r = rel(card)
  assert(r.x0 >= 0 and r.y0 >= 0 and r.x1 <= vp.X and r.y1 <= vp.Y, where .. ": card " .. fmt(r) .. " outside (0,0)-(" .. vp.X .. "," .. vp.Y .. ")")
end

-- 2. real viewport
local real = gui.AbsoluteSize
buttons("real " .. real.X .. "x" .. real.Y)
inside("real " .. real.X .. "x" .. real.Y, real)
local chip = gui:FindFirstChild("Waiting", true); assert(chip, "no Waiting chip")
bar:SetAttribute("ForceShow", true)
local shown = waitFor(function() return bar.Visible end, 2)
task.wait(0.6) -- CypherUI places the bar (0.2 s), FIRE moves under it (0.15 s), WalkInUI re-places the chip (0.2 s)
chip.Visible = true; fire.Visible = true
local c = rel(chip)
local others = { HUD = ui.HUD, Career = ui.Career, Bar = bar, FIRE = fire }
for _, name in ipairs({ "Daily", "Tour" }) do local g = ui:FindFirstChild(name); if g and g.Visible then others[name] = g end end
local hits = {}
for name, g in pairs(others) do if overlaps(c, rel(g)) then table.insert(hits, name .. " " .. fmt(rel(g))) end end
local chipH = chip.AbsoluteSize.Y
chip.Visible = false
bar:SetAttribute("ForceShow", nil)
assert(shown, "the cypher bar did not show with ForceShow (Studio seam missing?)")
assert(chipH >= 44, "Waiting chip under 44 px")
assert(#hits == 0, "Waiting chip " .. fmt(c) .. " covers " .. table.concat(hits, ", "))
table.insert(out, string.format("real %dx%d: buttons >= 44 px, card %s inside, chip %s clear of HUD/pills/bar/FIRE", real.X, real.Y, fmt(rel(card)), fmt(c)))

-- 3. forced phone sizes: a phone's screen minus the insets this gui really has (the top bar; side insets on notched
-- phones are not modelled), so the box is what OK_WalkIn gets on that phone
local inset = cam.ViewportSize - gui.AbsoluteSize
inset = Vector2.new(math.max(0, inset.X), math.max(0, inset.Y))
for _, screen in ipairs({ Vector2.new(844, 390), Vector2.new(667, 375) }) do
  local vp = screen - inset
  gui:SetAttribute("ForceViewport", vp); task.wait(0.4)
  local where = vp.X .. "x" .. vp.Y .. " (" .. screen.X .. "x" .. screen.Y .. " less " .. inset.X .. "x" .. inset.Y .. ")"
  buttons(where); inside(where, vp); unscrolled(where)
  assert(card.AbsoluteSize.X <= vp.X - 32, where .. ": card " .. card.AbsoluteSize.X .. " px wide, more than vp - 32")
  table.insert(out, where .. ": buttons >= 44 px, card " .. fmt(rel(card)) .. " inside, news and choices unscrolled in " .. fmt(rel(scroll)))
end
gui:SetAttribute("ForceViewport", nil); task.wait(0.4)

-- 4. choice 3 (sure, no roll): OWN YOUR MASTERS on a result card at the bottom centre
gui:SetAttribute("ResultKey", ""); gui:SetAttribute("LastChoose", "")
gui:SetAttribute("Command", "choose:3")
assert(waitFor(function() return gui:GetAttribute("ResultKey") == "masters" end, 6), "choice 3 is sure: ResultKey should be 'masters', is '"
  .. tostring(gui:GetAttribute("ResultKey")) .. "', LastChoose '" .. tostring(gui:GetAttribute("LastChoose")) .. "'")
local res = gui:FindFirstChild("Result", true)
assert(res and res.Visible, "result card not shown")
assert(gui:GetAttribute("Open") == false and not card.Visible, "the choice card is still open after choosing")
local r, H = rel(res), gui.AbsoluteSize.Y
assert(math.abs(r.y1 - H) <= 20, "result bottom " .. r.y1 .. " not within 20 px of the gui bottom " .. H)
assert(r.y0 > H * 0.5, "result top " .. r.y0 .. " is above half the height (" .. H .. ")")
table.insert(out, "choice 3: " .. tostring(gui:GetAttribute("ResultKey")) .. " (" .. tostring(gui:GetAttribute("ResultTone")) .. "), result " .. fmt(r) .. " in a " .. H .. " px gui")

-- 5. open the beat maker and leave it open (t47d checks the card defers to it)
local screen = workspace.OKStudio.ControlRoom.Screen_Main
local pos = Vector3.new(72.0, 3.5, -5.5)
root.CFrame = CFrame.lookAt(pos, Vector3.new(screen.Position.X, pos.Y, screen.Position.Z)); task.wait(1.0)
cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(-4, 3, 0), screen.Position); task.wait(1.5)
local prompt = screen:FindFirstChildWhichIsA("ProximityPrompt", true)
for _ = 1, 4 do prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); task.wait(0.8); if daw.Visible then break end end
assert(daw.Visible, "beat maker did not open")
table.insert(out, "beat maker open for t47d")
return "T47B PLAY OK\n" .. table.concat(out, "\n")
