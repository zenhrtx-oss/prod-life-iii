-- Edit: Prod Life III (2026-10-26). Nothing a player reads names OK, wegonebeok or the real studios the legendary
-- rooms were rebuilt from: world text (TextLabels in Workspace and StarterGui) and every quoted string in the game's
-- scripts. Internal names stay (ReplicatedStorage.OK, OK_UI, OK_Gates, studio_two): the patterns only match whole
-- words, so "OK_Passage_Interscope" or "studio_two" never count.
local function freshRequire(mod) -- edit-mode require caches modules across runs; load a clone so edits take effect
  local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name
  local ok, res = pcall(require, c); c:Destroy(); if not ok then error(res) end; return res
end
local RS = game:GetService("ReplicatedStorage")
local NAME = "PROD LIFE III"
local BANNED = { "WEGONEBEOK", "OK STUDIO", "OK BEAT MAKER", "PROD%. OK", "NETTSPEND", "OSAMASON", "STUDIO TWO",
  "ABBEY ROAD", "%f[%w_]INTERSCOPE%f[^%w_]", "GEFFEN", "A&M", "SANTA MONICA" }
-- drop --[[ ]] blocks and -- line comments (a "--" inside a quoted string stays)
local function stripComments(src)
  src = string.gsub(src, "%-%-%[(=*)%[.-%]%1%]", "")
  local out = {}
  for line in string.gmatch(src .. "\n", "([^\n]*)\n") do
    local inq, cut, i = nil, nil, 1
    while i <= #line do
      local ch = string.sub(line, i, i)
      if inq then
        if ch == "\\" then i += 1 elseif ch == inq then inq = nil end
      elseif ch == '"' or ch == "'" then inq = ch
      elseif string.sub(line, i, i + 1) == "--" then cut = i; break end
      i += 1
    end
    table.insert(out, cut and string.sub(line, 1, cut - 1) or line)
  end
  return table.concat(out, "\n")
end
local bad = {}
local function scan(text, where)
  local up = string.upper(text)
  for _, pat in ipairs(BANNED) do
    if string.find(up, pat) then table.insert(bad, where .. ": '" .. string.gsub(text, "\n", " / ") .. "'"); return end
  end
end

-- 1. world and GUI text
local labels = 0
for _, root in ipairs({ workspace, game:GetService("StarterGui") }) do
  for _, d in ipairs(root:GetDescendants()) do
    if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then labels += 1; scan(d.Text, d:GetFullName())
    elseif d:IsA("ProximityPrompt") then labels += 1; scan(d.ActionText .. " / " .. d.ObjectText, d:GetFullName()) end
  end
end

-- 2. quoted strings in the game's scripts (comments are free to mention history)
local scripts = 0
local roots = { RS.OK, game.ServerScriptService.OK, game.StarterPlayer.StarterPlayerScripts.OK }
for _, root in ipairs(roots) do
  for _, s in ipairs(root:GetDescendants()) do
    if s:IsA("LuaSourceContainer") and not s.Name:match("^_fresh_") then
      scripts += 1
      local src = stripComments(s.Source)
      for q in string.gmatch(src, '"([^"\n]*)"') do scan(q, s:GetFullName()) end
    end
  end
end
assert(#bad == 0, #bad .. " branded string(s) left:\n" .. table.concat(bad, "\n"))

-- 3. the new names are in place
local Config = freshRequire(RS.OK.Config)
local gate; for _, g in ipairs(Config.Career.Gates) do if g.id == "studio_two" then gate = g end end
assert(gate and gate.name == "THE HALL", "the studio_two gate should read THE HALL, reads " .. tostring(gate and gate.name))
assert(freshRequire(RS.OK.Modules.Interactions).StudioTwoDoor.Object == "The Hall", "the door prompt should name The Hall")
local plaque = workspace.OKStudio.ControlRoom.Plaque_B.Text.Label.Text
assert(string.find(plaque, NAME, 1, true), "Plaque_B should carry the game's name, reads " .. plaque)
local entry = workspace.OKStudio.Corridor.Entry_Sign.Text.Label.Text
assert(string.find(entry, NAME, 1, true), "the corridor sign should carry the game's name, reads " .. entry)
assert(#freshRequire(RS.OK.Data.Credits) == 0, "Data.Credits still lists OK's credits")
return string.format("T50 OK: no OK, wegonebeok or real-studio names in %d labels and %d scripts; THE HALL door, %s on the signs", labels, scripts, NAME)
