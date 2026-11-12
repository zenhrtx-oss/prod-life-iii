-- Client, during play (after t45a: Aura 380, Followers 9,400, no placements). The HUD's career pills read "+380 AURA"
-- and "9.4K FOLLOWERS". At the real viewport the HUD, both pills, the cypher bar and FIRE don't overlap (the bar is
-- held shown with its Studio-only ForceShow attribute, so FIRE moves under it as in a real round). With OK_UI forced to
-- 667x375, or to 750x332 (a notched 844x390 phone's safe area: too narrow for the pair to clear FIRE's column side by
-- side), the pills stack and end left of FIRE (x < vp.X - 152). The OS panel opens first and its career comes after
-- (the "os" seam acks once it has landed); the Career tab then lists 4 gates (Studio Two LOCKED) and the 5 stat-gated
-- gear rows; your own producer card carries the career line.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui", 10)
local ui = pg:WaitForChild("OK_UI", 10); assert(ui, "no OK_UI")
local hud, career, panel = ui:WaitForChild("HUD", 5), ui:WaitForChild("Career", 5), ui:WaitForChild("Panel", 5)
assert(hud and career and panel, "HUD, career pills or panel missing")
local cyGui, fireGui = pg:WaitForChild("OK_Cypher", 5), pg:WaitForChild("OK_Fire", 5)
local bar = cyGui and cyGui:WaitForChild("Bar", 5); local fire = fireGui and fireGui:WaitForChild("FireButton", 5)
assert(bar and fire, "cypher bar or FIRE button missing")
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
-- rects in OK_UI's space (every gui shares the screen's absolute space; subtracting OK_UI's origin keeps them comparable)
local function rect(g) local p, s = g.AbsolutePosition - ui.AbsolutePosition, g.AbsoluteSize; return { x0 = p.X, y0 = p.Y, x1 = p.X + s.X, y1 = p.Y + s.Y } end
local function overlaps(a, b) return a.x0 < b.x1 and b.x0 < a.x1 and a.y0 < b.y1 and b.y0 < a.y1 end
local function fmt(r) return string.format("(%d,%d)-(%d,%d)", r.x0, r.y0, r.x1, r.y1) end
local function command(c, t)
  ui:SetAttribute("PanelCommand", c)
  assert(waitFor(function() return ui:GetAttribute("PanelCommand") == "" end, t or 6), "PanelCommand '" .. c .. "' was not taken (Studio seam missing?)")
end
local function count(prefix) local n = 0; for _, c in ipairs(panel.Content:GetChildren()) do if c.Name:sub(1, #prefix) == prefix then n += 1 end end; return n end
-- never inherit a forced size, a held bar or a half-sent command from an earlier failed run
ui:SetAttribute("ForceViewport", nil); bar:SetAttribute("ForceShow", nil); ui:SetAttribute("PanelCommand", "")
local out = {}

-- 1. the pills
local aura, followers = career:FindFirstChild("Aura"), career:FindFirstChild("Followers")
assert(aura and followers, "Career pills Aura / Followers missing")
assert(waitFor(function() return aura.Text == "+380 AURA" and followers.Text == "9.4K FOLLOWERS" end, 3),
  "pills read '" .. aura.Text .. "' / '" .. followers.Text .. "'")
table.insert(out, "pills: " .. aura.Text .. " · " .. followers.Text)

-- 2. real viewport: nothing at the top overlaps (bar held shown; FIRE's spot is valid while it is hidden)
bar:SetAttribute("ForceShow", true)
local shown = waitFor(function() return bar.Visible end, 2)
task.wait(0.6) -- CypherUI re-places the bar (0.2 s), FIRE moves under it (0.15 s)
fire.Visible = true
local items = { HUD = rect(hud), Aura = rect(aura), Followers = rect(followers), Bar = rect(bar), FIRE = rect(fire) }
bar:SetAttribute("ForceShow", nil)
assert(shown, "the cypher bar did not show with ForceShow (Studio seam missing?)")
local names, hits = { "HUD", "Aura", "Followers", "Bar", "FIRE" }, {}
for i = 1, #names do
  for j = i + 1, #names do
    local a, b = names[i], names[j]
    if overlaps(items[a], items[b]) then table.insert(hits, a .. " " .. fmt(items[a]) .. " x " .. b .. " " .. fmt(items[b])) end
  end
end
assert(#hits == 0, "top-bar overlap at " .. ui.AbsoluteSize.X .. "x" .. ui.AbsoluteSize.Y .. ": " .. table.concat(hits, "; "))
table.insert(out, string.format("no overlap at %dx%d: HUD %s, pills %s %s, bar %s, FIRE %s", ui.AbsoluteSize.X, ui.AbsoluteSize.Y,
  fmt(items.HUD), fmt(items.Aura), fmt(items.Followers), fmt(items.Bar), fmt(items.FIRE)))

-- 3. forced 667x375 and 750x332: the pills stack and end left of FIRE
for _, vp in ipairs({ Vector2.new(667, 375), Vector2.new(750, 332) }) do
  ui:SetAttribute("ForceViewport", vp); task.wait(0.4)
  local ra, rf = rect(aura), rect(followers)
  ui:SetAttribute("ForceViewport", nil)
  local where, fireX = vp.X .. "x" .. vp.Y, vp.X - 152
  assert(ra.x1 < fireX and rf.x1 < fireX, where .. ": pills end at x " .. ra.x1 .. " / " .. rf.x1 .. ", FIRE starts at " .. fireX)
  assert(rf.y0 >= ra.y1, where .. ": pills should stack (Aura " .. fmt(ra) .. ", Followers " .. fmt(rf) .. ")")
  table.insert(out, where .. ": pills stacked, right edges " .. ra.x1 .. " / " .. rf.x1 .. " < " .. fireX)
end

-- 4. the Career tab
command("os")
assert(panel.Visible, "PanelCommand os did not open the panel")
command("tab:Career")
assert(waitFor(function() return panel.Content:FindFirstChild("Gate_studio_two") ~= nil end, 5), "Career tab did not render (no Gate_studio_two row)")
assert(count("Gate_") == 4, "Career tab should list 4 gates, lists " .. count("Gate_"))
assert(count("CareerGear_") == 7, "Career tab should list 7 gear rows, lists " .. count("CareerGear_"))
local act = panel.Content.Gate_studio_two:FindFirstChild("Action")
assert(act and act.Text == "LOCKED", "Studio Two should read LOCKED with no placements, reads '" .. tostring(act and act.Text) .. "'")
assert(act.AbsoluteSize.Y >= 44, "gate button under 44 px")
local tile = panel.Content:FindFirstChild("Stats") and panel.Content.Stats:FindFirstChild("Stat_aura")
local tileValue = tile and tile:FindFirstChild("Value")
assert(tileValue and tileValue.Text == "+380", "Aura tile reads '" .. tostring(tileValue and tileValue.Text) .. "'")
table.insert(out, "Career tab: 4 gates (Studio Two LOCKED), 7 gear rows, Aura tile +380")

-- 5. your own producer card
command("card:self")
local cl = panel.Content:FindFirstChild("CareerLine")
assert(cl, "producer card has no CareerLine")
assert(cl.Text:find("+380 AURA", 1, true) and cl.Text:find("9.4K FOLLOWERS", 1, true), "career line reads '" .. cl.Text .. "'")
table.insert(out, "producer card: " .. cl.Text)
panel.Visible = false
return "T45B PLAY OK\n" .. table.concat(out, "\n")
