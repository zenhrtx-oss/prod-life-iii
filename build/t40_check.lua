-- Edit: Money x10 and "$" on screen (walk-ins Task 1).
-- (a) the rescaled Money constants, XP untouched; (b) gear prices on the x10 grid; (c) session rewards x10;
-- (d) copy: no double-quoted string under ReplicatedStorage.OK.Modules, ReplicatedStorage.OK.Systems or
-- StarterPlayer.StarterPlayerScripts.OK says CRED or the word Cred. The exact literal "Cred" stays allowed: it is the
-- player attribute, an instance name or a notify kind, never text a player reads.
-- (e) in-world copy: no sign, screen or prompt under Workspace.OKStudio says the word CRED or Cred.
local RS, SP = game:GetService("ReplicatedStorage"), game:GetService("StarterPlayer")
local function freshRequire(mod) local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name; local ok, r = pcall(require, c); c:Destroy(); if not ok then error(r) end; return r end
local Cfg = freshRequire(RS.OK.Config)
local A = freshRequire(RS.OK.Data.Artists)
local out = {}

-- a) Money constants x10; XP stays as it was
local S = Cfg.Cred.Sources
local pins = {
  { "Cred.Sources.Delivery.max", S.Delivery and S.Delivery.max, 980 },
  { "Cred.Sources.Fire.amount", S.Fire and S.Fire.amount, 30 },
  { "Cred.Sources.Flip.amount", S.Flip and S.Flip.amount, 50 },
  { "Daily.Cred", Cfg.Daily.Cred, 200 },
  { "Daily.StreakBonus[3]", Cfg.Daily.StreakBonus[3], 300 },
  { "Weekly.Cred", Cfg.Weekly.Cred, 800 },
  { "Cypher.Reward.WinCred", Cfg.Cypher.Reward.WinCred, 500 },
  { "XP.Sources.Delivery.max (XP is not rescaled)", Cfg.XP.Sources.Delivery.max, 60 },
}
for _, p in ipairs(pins) do assert(p[2] == p[3], string.format("Config.%s should be %d, is %s", p[1], p[3], tostring(p[2]))) end
table.insert(out, "Money x10: delivery cap 980, FIRE 30, flip 50, daily 200, 3-day streak 300, weekly 800, cypher win 500; XP delivery cap still 60")

-- b) gear prices: 0 or a multiple of 10; Roll FX 250
local rollfx
for _, it in ipairs(Cfg.Gear) do
  assert(type(it.price) == "number" and it.price % 10 == 0, "gear price not on the x10 grid: " .. tostring(it.id) .. " = " .. tostring(it.price))
  if it.id == "rollfx" then rollfx = it end
end
assert(rollfx and rollfx.price == 250, "Roll FX should cost 250, costs " .. tostring(rollfx and rollfx.price))
table.insert(out, #Cfg.Gear .. " gear prices on the x10 grid; Roll FX 250")

-- c) every session request pays a multiple of 10, at least 250
for _, b in ipairs(A.Briefs) do
  local c = b.reward and b.reward.cred
  assert(type(c) == "number" and c % 10 == 0 and c >= 250, "session reward not x10: " .. tostring(b.id) .. " = " .. tostring(c))
end
table.insert(out, #A.Briefs .. " session rewards x10 (>= 250)")

-- d) copy scan. The double-quoted literals on one line of source: a "--" comment ends the line, single-quoted strings
-- are skipped whole (a " inside one starts nothing), and backslash escapes stay inside their literal.
local function literals(line)
  local found, i, n = {}, 1, #line
  while i <= n do
    local c = line:sub(i, i)
    if c == "-" and line:sub(i + 1, i + 1) == "-" then break end
    if c == "\"" or c == "'" then
      local j, buf = i + 1, {}
      while j <= n do
        local d = line:sub(j, j)
        if d == "\\" then table.insert(buf, line:sub(j, j + 1)); j += 2
        elseif d == c then break
        else table.insert(buf, d); j += 1 end
      end
      if c == "\"" then table.insert(found, table.concat(buf)) end
      i = j + 1
    else
      i += 1
    end
  end
  return found
end
local roots = { RS.OK.Modules, RS.OK.Systems, SP.StarterPlayerScripts.OK }
local scripts, lits, bad = 0, 0, {}
for _, root in ipairs(roots) do
  for _, s in ipairs(root:GetDescendants()) do
    if s:IsA("ModuleScript") or s:IsA("LocalScript") then
      scripts += 1
      local ln = 0
      for line in (s.Source .. "\n"):gmatch("([^\n]*)\n") do
        ln += 1
        for _, lit in ipairs(literals(line)) do
          lits += 1
          if lit ~= "Cred" and (lit:find("CRED", 1, true) or lit:find("%f[%a]Cred%f[%A]")) then
            table.insert(bad, string.format("%s:%d \"%s\"", s:GetFullName(), ln, lit))
          end
        end
      end
    end
  end
end
assert(scripts >= 20 and lits >= 500, "copy scan saw too little (" .. scripts .. " scripts, " .. lits .. " strings): wrong folders?")
assert(#bad == 0, #bad .. " player-facing CRED/Cred string(s) left: " .. table.concat(bad, "; "))
table.insert(out, string.format("copy: %d strings in %d scripts, none says CRED/Cred", lits, scripts))

-- e) in-world copy: the text the build scripts put on signs and screens (TextLabel/TextButton/TextBox .Text) and on
-- prompts (ProximityPrompt ActionText/ObjectText) under Workspace.OKStudio. Whole words only: "PRODUCTION CREDITS" on
-- the credits wall is about song credits and stays allowed.
local function saysCred(text) return type(text) == "string" and (text:find("%f[%a]CRED%f[%A]") or text:find("%f[%a]Cred%f[%A]")) ~= nil end
local texts, prompts, worldBad = 0, 0, {}
for _, d in ipairs(workspace.OKStudio:GetDescendants()) do
  if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
    texts += 1
    if saysCred(d.Text) then table.insert(worldBad, string.format("%s.Text \"%s\"", d:GetFullName(), d.Text)) end
  elseif d:IsA("ProximityPrompt") then
    prompts += 1
    for _, k in ipairs({ "ActionText", "ObjectText" }) do
      if saysCred(d[k]) then table.insert(worldBad, string.format("%s.%s \"%s\"", d:GetFullName(), k, d[k])) end
    end
  end
end
assert(texts >= 10 and prompts >= 5, "world copy scan saw too little (" .. texts .. " texts, " .. prompts .. " prompts): wrong root?")
assert(#worldBad == 0, #worldBad .. " in-world CRED/Cred text(s) left: " .. table.concat(worldBad, "; "))
table.insert(out, string.format("world: %d texts and %d prompts under Workspace.OKStudio, none says CRED/Cred", texts, prompts))

return "T40 OK: " .. table.concat(out, "; ")
