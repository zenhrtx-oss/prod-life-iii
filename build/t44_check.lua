-- Edit: world unlocks (walk-ins Task 8) that need no play session. Run build/18_gates.lua first.
-- (a) Workspace.OK_Gates.StudioTwoDoor: an anchored, colliding glass part in the corridor's north doorway (x 6), tagged
--     StudioTwoDoor, marked by 18_gates, with its prompt (E / ButtonX, the interaction distance, "Enter" / "The Hall")
--     and its licensed sound (the SFX child once InteractionService ran, else the Config.SFX entry) and cooldown;
-- (b) Fits.Apply on a fake R15 and a fake R6 character: cuban (10 links on the torso), snapback (accent colour) and
--     shades (head) build as OK_Fit_<fit> models of massless, non-colliding, non-queryable, welded parts; an unknown fit
--     is skipped; a new list takes the old fits off, an empty one takes them all off;
-- (c) Unlocks.DoorText: missing needs and money, money only, a need only, all met (Career tab), owned;
-- (d) Unlocks._TickerStep on a fake TV: the first write saves the original in TickerSaved, the rotation, no write while
--     a beat airs, the beat-over-ticker handoff into SavedText, the restore once no sponsored producer is left (never
--     while Active), and no start while SavedText is set.
local RS, CS = game:GetService("ReplicatedStorage"), game:GetService("CollectionService")
local function freshRequire(mod) local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name; local ok, r = pcall(require, c); c:Destroy(); if not ok then error(r) end; return r end
local Config = freshRequire(RS.OK.Config)
local Defs = freshRequire(RS.OK.Modules.Interactions)
local Theme = freshRequire(RS.OK.Modules.UITheme)
local out = {}

-- a) the door
local gates = workspace:FindFirstChild("OK_Gates"); assert(gates, "Workspace.OK_Gates missing: run build/18_gates.lua")
local door = gates:FindFirstChild("StudioTwoDoor")
assert(door and door:IsA("BasePart"), "OK_Gates.StudioTwoDoor missing or not a part")
assert(CS:HasTag(door, "OK_Interactable") and door:GetAttribute("Kind") == "StudioTwoDoor", "door is not tagged OK_Interactable / StudioTwoDoor")
assert(door:GetAttribute("OK_Build") == "18_gates", "door not marked by 18_gates: " .. tostring(door:GetAttribute("OK_Build")))
assert(door.Anchored == true and door.CanCollide == true, "door must be anchored and collidable")
assert(math.abs(door.Position.X - 6) <= 1, "door x " .. door.Position.X .. " is not within 1 stud of 6")
local shell = workspace.OKStudio.Shell
local cut = shell:FindFirstChild("Wall_Corr_N_Top") or shell:FindFirstChild("Wall_Corr_N_L") or shell:FindFirstChild("Wall_Corr_N_R")
assert(cut and math.abs(door.Position.Z - cut.Position.Z) < 0.5, "door is not in the doorway cut in Wall_Corr_N")
local def = Defs.StudioTwoDoor
assert(def and def.Action == "Enter" and def.Object == "The Hall", "Interactions.StudioTwoDoor copy wrong")
local prompt = door:FindFirstChildWhichIsA("ProximityPrompt", true)
assert(prompt and prompt.Enabled, "door has no enabled prompt")
assert(prompt.MaxActivationDistance == Config.Interaction.MaxDistance, "door prompt distance " .. prompt.MaxActivationDistance)
assert(prompt.ActionText == def.Action and prompt.ObjectText == def.Object, "door prompt copy: " .. prompt.ActionText .. " / " .. prompt.ObjectText)
assert(prompt.KeyboardKeyCode == Enum.KeyCode.E and prompt.GamepadKeyCode == Enum.KeyCode.ButtonX, "door prompt keys should be E / ButtonX")
local sfxDef = Config.SFX.StudioTwoDoor
assert(sfxDef and sfxDef.id == "rbxassetid://9119203830" and sfxDef.volume == 0.6, "Config.SFX.StudioTwoDoor should be the licensed Door sound at 0.6")
local sfx = door:FindFirstChild("SFX")
assert(sfx == nil or (sfx:IsA("Sound") and sfx.SoundId == sfxDef.id), "door SFX is not the configured sound")
assert(Config.Cooldowns.StudioTwoDoor == 1, "Config.Cooldowns.StudioTwoDoor should be 1")
table.insert(out, string.format("(a) door at (%.1f, %.1f, %.1f): anchored, collides, tagged StudioTwoDoor, prompt E 'Enter' / 'Studio Two', sound %s",
  door.Position.X, door.Position.Y, door.Position.Z, sfx and "attached" or "configured"))

-- b) fits on fake rigs
local Fits = freshRequire(RS.OK.Modules.Fits)
local function rig(r15)
  local m = Instance.new("Model"); m.Name = "_t44_rig"
  local torso = Instance.new("Part"); torso.Name = r15 and "UpperTorso" or "Torso"; torso.Anchored = true
  torso.Size = r15 and Vector3.new(2, 1.6, 1) or Vector3.new(2, 2, 1); torso.CFrame = CFrame.new(300, 60, 300); torso.Parent = m
  local head = Instance.new("Part"); head.Name = "Head"; head.Anchored = true
  head.Size = r15 and Vector3.new(1.2, 1.2, 1.2) or Vector3.new(2, 1, 1)
  head.CFrame = torso.CFrame * CFrame.new(0, torso.Size.Y / 2 + head.Size.Y / 2, 0); head.Parent = m
  return m, torso, head
end
local function fitModels(m)
  local names = {}
  for _, c in ipairs(m:GetChildren()) do if c.Name:sub(1, 7) == "OK_Fit_" then table.insert(names, c.Name) end end
  table.sort(names); return names
end
-- every part massless, non-colliding, non-queryable, unanchored and welded to `anchor`; returns the part count
local function wornOn(model, anchor, what)
  local n = 0
  for _, d in ipairs(model:GetDescendants()) do
    if d:IsA("BasePart") then
      n += 1
      assert(d.Massless and not d.CanCollide and not d.CanQuery and not d.Anchored, what .. " part " .. d.Name .. " must be massless, non-colliding, non-queryable, unanchored")
      local w = d:FindFirstChildWhichIsA("WeldConstraint")
      assert(w and w.Part0 == anchor and w.Part1 == d, what .. " part " .. d.Name .. " is not welded to " .. anchor.Name)
    end
  end
  return n
end
for _, r15 in ipairs({ true, false }) do
  local kind = r15 and "R15" or "R6"
  local m, torso, head = rig(r15)
  Fits.Apply(m, { "cuban", "snapback", "shades", "t44_nope" })
  assert(table.concat(fitModels(m), ",") == "OK_Fit_cuban,OK_Fit_shades,OK_Fit_snapback", kind .. " fits built: " .. table.concat(fitModels(m), ","))
  assert(wornOn(m.OK_Fit_cuban, torso, kind .. " cuban") == 10, kind .. " cuban should be 10 links")
  local capParts = wornOn(m.OK_Fit_snapback, head, kind .. " snapback")
  assert(capParts >= 2, kind .. " snapback should be a cap and a brim")
  for _, d in ipairs(m.OK_Fit_snapback:GetDescendants()) do if d:IsA("BasePart") then assert(d.Color == Theme.accent, kind .. " snapback part " .. d.Name .. " not in Theme.accent") end end
  assert(wornOn(m.OK_Fit_shades, head, kind .. " shades") == 3, kind .. " shades should be two lenses and a bridge")
  Fits.Apply(m, { "shades" })
  assert(table.concat(fitModels(m), ",") == "OK_Fit_shades", kind .. " a new list should leave only the shades: " .. table.concat(fitModels(m), ","))
  Fits.Apply(m, {})
  assert(#fitModels(m) == 0, kind .. " an empty list should take every fit off")
  m:Destroy()
end
table.insert(out, "(b) Fits on R15 and R6 rigs: cuban 10 links on the torso, snapback in the accent colour and shades (3 parts) on the head; all massless, non-colliding, non-queryable, welded; re-apply replaces, empty removes")

-- c) the door's toast
local Unlocks = freshRequire(RS.OK.Systems.Unlocks)
local gate
for _, g in ipairs(Config.Career.Gates) do if g.id == "studio_two" then gate = g end end
assert(gate and gate.kind == "room" and gate.cost == 5000, "Config.Career.Gates studio_two missing")
local function have(t)
  local h = { money = 0, aura = 0, followers = 0, placements = 0, hits = 0, sponsors = 0, showSponsor = true, gates = {} }
  for k, v in pairs(t) do h[k] = v end
  return h
end
local function door1(t, g) local text, owned = Unlocks.DoorText(have(t), g or gate); return text, owned end
local cases = {
  { {}, "NEEDS 1 PLACEMENT · 300 AURA · $5,000", false },
  { { placements = 1, aura = 300, money = 4999 }, "NEEDS $5,000", false },
  { { placements = 1, aura = 299, money = 5000 }, "NEEDS 300 AURA", false },
  { { placements = 1, aura = 300, money = 5000 }, "Unlock it in the Career tab · $5,000", false },
  { { gates = { studio_two = true } }, "The Hall is open for you", true },
}
for _, c in ipairs(cases) do
  local text, owned = door1(c[1])
  assert(text == c[2] and owned == c[3], "door toast: expected '" .. c[2] .. "', got '" .. tostring(text) .. "' (owned " .. tostring(owned) .. ")")
end
local many = door1({ placements = 1 }, { id = "t44_gate", needs = { placements = 2, followers = 5000, hits = 1 }, cost = 0 })
assert(many == "NEEDS 2 PLACEMENTS · 1 HIT · 5K FOLLOWERS", "plural needs: " .. tostring(many))
table.insert(out, "(c) door toasts: 'NEEDS 1 PLACEMENT · 300 AURA · $5,000', money only, aura only, 'Unlock it in the Career tab · $5,000', open; plurals '" .. many .. "'")

-- d) the ticker on a fake TV
local tv = Instance.new("Part"); tv.Name = "_t44_tv"
local gui = Instance.new("SurfaceGui"); gui.Name = "ScreenText"; gui.Parent = tv
local lbl = Instance.new("TextLabel"); lbl.Name = "Label"; lbl.Text = "ORIGINAL"; lbl.Parent = gui
local A, B = Unlocks.TickerText("GLOW GUM", "Maya"), Unlocks.TickerText("STACKS BANK", "Ola") -- pure formatting: any sponsor name will do, whatever the roster
assert(A == "SPONSORED BY\nGLOW GUM\nprod. Maya", "ticker text: " .. A)
local function saved() return tv:GetAttribute("TickerSaved") end
Unlocks._TickerStep(tv, false, { A })
assert(lbl.Text == A and saved() == "ORIGINAL", "the first write should show the sponsor and keep the original in TickerSaved")
Unlocks._TickerStep(tv, false, { A, B }); local s1 = lbl.Text
Unlocks._TickerStep(tv, false, { A, B }); local s2 = lbl.Text
assert(s1 ~= s2 and (s1 == A or s1 == B) and (s2 == A or s2 == B), "two producers should alternate")
assert(saved() == "ORIGINAL", "later writes must keep the first original")
-- a beat airs: MonitorService keeps the label in SavedText and writes NOW PLAYING; the ticker stays off the screen
local shown = lbl.Text
tv:SetAttribute("SavedText", shown); lbl.Text = "NOW PLAYING"
Unlocks._TickerStep(tv, true, { A, B })
assert(lbl.Text == "NOW PLAYING" and tv:GetAttribute("SavedText") == shown and saved() == "ORIGINAL", "the ticker wrote over a beat on the monitors")
-- the airing ends with the producer still here: MonitorService restores the sponsor line, the ticker carries on
lbl.Text = tv:GetAttribute("SavedText"); tv:SetAttribute("SavedText", nil)
Unlocks._TickerStep(tv, false, { A })
assert(lbl.Text == A and saved() == "ORIGINAL", "the ticker should carry on after the airing")
-- another beat, and the producer leaves during it: the original moves into SavedText so MonitorService restores it
tv:SetAttribute("SavedText", lbl.Text); lbl.Text = "NOW PLAYING"
Unlocks._TickerStep(tv, true, {})
assert(tv:GetAttribute("SavedText") == "ORIGINAL" and saved() == nil and lbl.Text == "NOW PLAYING", "beat over the ticker: the original should move into SavedText")
lbl.Text = tv:GetAttribute("SavedText"); tv:SetAttribute("SavedText", nil)
Unlocks._TickerStep(tv, false, {})
assert(lbl.Text == "ORIGINAL" and saved() == nil, "after the airing the TV should show its original text")
-- the plain restore, which waits while a beat is Active
Unlocks._TickerStep(tv, false, { B })
assert(lbl.Text == B and saved() == "ORIGINAL", "the ticker did not start again")
Unlocks._TickerStep(tv, true, {})
assert(lbl.Text == B and saved() == "ORIGINAL", "the restore must wait while NowPlaying is Active")
Unlocks._TickerStep(tv, false, {})
assert(lbl.Text == "ORIGINAL" and saved() == nil, "no sponsored producer left: the original should come back and TickerSaved clear")
-- never starts while SavedText is set
tv:SetAttribute("SavedText", "ORIGINAL"); lbl.Text = "NOW PLAYING"
Unlocks._TickerStep(tv, false, { A })
assert(lbl.Text == "NOW PLAYING" and saved() == nil, "the ticker started while the monitors own the TV")
tv:Destroy()
table.insert(out, "(d) ticker: saves the original once, alternates two producers, stays off a beat, hands the original to SavedText when the producer leaves mid-beat, restores (never while Active), never starts under SavedText")

return "T44 OK\n" .. table.concat(out, "\n")
