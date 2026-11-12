-- Edit: the fiction fallback still swaps every name (Wave 3 Task 5b, fix round 1, 2026-11-11). The user kept the parody
-- names for now, and the parody's jokes are back in the card text by design. So the fiction switch is names-only again:
-- the 10-23 report's "half a fallback" (WALKINS_REPORT.md item 5). research/fiction_pass_2026-11-06.md is the parked
-- patch that would also clean the lines for a later switch.
-- Each roster is forced inside its own scope: Config.WalkIns.Roster is set on a fresh Config copy and the names are read
-- from it. The configured roster is put back afterwards, as t70 does. Nothing here asserts the live roster's value.
-- (a) Fiction forced: every visitor and sponsor gets a fiction name of its own, unlike its parody one. No rendered display
--     name holds a parody name or a REAL token. That covers visitors (filled with each sponsor), sponsors, and every
--     {name:<id>} fill in the card, follow-up, waiting and parting text, which holds no parody name.
-- (b) Each roster forced in turn: no shipped string holds a REAL token (whole words), because a real name must never
--     appear anywhere. The strings are: display names and styles; every card and follow-up string, filled with that
--     roster's names, each of its sponsors and a best beat; the waiting and parting lines; every LifeRules.Copy string
--     and every story, discography and banner line in that roster's names; the Config strings players read (unlock
--     lines, hints, gear, ranks, the gates); and the session-request artists (names, styles, quotes, titles).
-- (c) The Task 5 review's F6 (review Minor 2: both rosters): sponsor_warning's result text takes at most two lines of
--     the result card's text label for every sponsor name in both rosters. The label is 312 px wide at TextSize 12 in
--     Theme.font GothamBold (WalkInUI's resText), measured by TextService:GetTextSize. Controls: a one-line string the
--     game showed at about 283 px measures 240..330 px, and the old text with the longest sponsor name measures 3 lines,
--     so the measurement can see the failure it guards. Before the fix's sync the place holds the old text: (c) is red.
local RS = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local function freshRequire(mod) -- edit-mode require caches modules across runs; load a clone so edits take effect
  local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name
  local ok, res = pcall(require, c); c:Destroy(); if not ok then error(res) end; return res
end
local Config = freshRequire(RS.OK.Config)
local W = freshRequire(RS.OK.Data.WalkIns)
local Rules = freshRequire(RS.OK.Modules.WalkInRules)
local L = freshRequire(RS.OK.Modules.LifeRules)
local A = freshRequire(RS.OK.Data.Artists)
local out = {}
local ROSTERS = { "parody", "fiction" }

-- real names and titles (whole words, lowercase): the nine artists the parody names sound like, the six brands its
-- sponsors parody, titles and events tied to them, and the platforms no card may name. A token an approved parody name
-- shares on purpose ("doja" in DOJA BAT, "kendrick" in KENDRICK LLAMA, "playdoh" in PLAYDOH CHARTI) is left out
local REAL = { "lil nas x", "lil nas", "nas x", "doja cat", "ice spice", "playboi carti", "playboi", "carti", "travis scott",
  "kendrick lamar", "lamar", "taylor swift", "swift", "drake", "billie eilish", "eilish", "finneas", "cardi b",
  "red bull", "nike", "air jordan", "beats by dre", "dr. dre", "spotify", "rolex", "prime hydration", "play-doh",
  "old town road", "rodeo", "montero", "industry baby", "astroworld", "cactus jack", "sicko mode", "whole lotta red",
  "eras tour", "taylor's version", "super bowl", "ovo", "hotline bling",
  "tiktok", "instagram", "youtube", "twitter", "soundcloud", "twitch", "pitchfork", "rolling stone" }
local function word(token) -- a whole-word pattern for a lowercase token (magic characters escaped)
  return "%f[%w]" .. string.gsub(token, "[%-%.%+%[%]%(%)%$%^%%%?%*]", "%%%0") .. "%f[%W]"
end
local parody = {}
for _, v in ipairs(W.Visitors) do table.insert(parody, string.lower(v.names.parody)) end
for _, s in ipairs(W.Sponsors) do table.insert(parody, string.lower(s.names.parody)) end

-- the roster scope: Config.WalkIns.Roster forced to `roster` on this fresh copy while fn runs, then put back
local ROSTER0 = Config.WalkIns.Roster
local function withRoster(roster, fn)
  Config.WalkIns.Roster = roster
  local ok, err = pcall(fn, roster)
  Config.WalkIns.Roster = ROSTER0
  if not ok then error(err, 0) end
end
local function namesNow() return W.Names(Config.WalkIns.Roster) end
local function sponsorsNow()
  local t = {}
  for _, s in ipairs(W.Sponsors) do t[s.id] = W.SponsorName(s.id, Config.WalkIns.Roster) end
  return t
end
-- every card, follow-up, waiting and parting string, each handed to fn(where, s)
local function eachCardString(fn)
  local function outcome(where, o)
    if type(o) ~= "table" then return end
    for _, k in ipairs({ "headline", "text", "line", "note" }) do if type(o[k]) == "string" then fn(where .. "." .. k, o[k]) end end
  end
  local function item(kind, it)
    local where = kind .. " " .. it.id
    fn(where .. ".tag", it.tag); fn(where .. ".line", it.line)
    if type(it.resolve) == "table" then outcome(where .. ".resolve.good", it.resolve.good); outcome(where .. ".resolve.bad", it.resolve.bad) end
    for i, c in ipairs(it.choices or {}) do
      fn(where .. " choice " .. i .. ".text", c.text)
      for _, k in ipairs({ "good", "bad", "rare" }) do outcome(where .. " choice " .. i .. "." .. k, c[k]) end
    end
  end
  for _, c in ipairs(W.Cards) do item("card", c) end
  for _, f in ipairs(W.Followups) do item("followup", f) end
  for i, line in ipairs(W.WaitLines) do fn("WaitLines[" .. i .. "]", line) end
  for i, line in ipairs(W.NoteLines) do fn("NoteLines[" .. i .. "]", line) end
end
local bad = {}
local function hasReal(where, text)
  if type(text) ~= "string" or text == "" then return 0 end
  local low = string.lower(text)
  for _, t in ipairs(REAL) do
    if string.find(low, word(t)) then table.insert(bad, where .. ": real name '" .. t .. "' in '" .. text .. "'"); break end
  end
  return 1
end
local function hasParody(where, text)
  local low = string.lower(text)
  for _, p in ipairs(parody) do
    if string.find(low, p, 1, true) then table.insert(bad, where .. ": parody name '" .. p .. "' in '" .. text .. "'"); return end
  end
end

-- (a) fiction forced: every name swapped, none holding a parody or a real name
local named, fills = 0, 0
withRoster("fiction", function(roster)
  local names, sponsors = namesNow(), sponsorsNow()
  for _, v in ipairs(W.Visitors) do
    local n = names[v.id]
    if not (type(n) == "string" and n ~= "" and string.lower(n) ~= string.lower(v.names.parody)) then
      table.insert(bad, "visitor " .. v.id .. ": the fiction roster shows '" .. tostring(n) .. "', not a fiction name of its own")
    end
    for _, s in ipairs(W.Sponsors) do
      local shown = Rules.Fill(n or "", names, sponsors[s.id])
      named += hasReal("fiction visitor " .. v.id, shown); hasParody("fiction visitor " .. v.id, shown)
    end
  end
  for _, s in ipairs(W.Sponsors) do
    local n = sponsors[s.id]
    if not (type(n) == "string" and n ~= "" and string.lower(n) ~= string.lower(s.names.parody)) then
      table.insert(bad, "sponsor " .. s.id .. ": the fiction roster shows '" .. tostring(n) .. "', not a fiction name of its own")
    end
    named += hasReal("fiction sponsor " .. s.id, n or ""); hasParody("fiction sponsor " .. s.id, n or "")
  end
  -- the {name:<id>} fills: with fiction names in, no card or follow-up string shows a parody name
  eachCardString(function(where, s)
    if type(s) ~= "string" then return end
    for _, sp in ipairs(W.Sponsors) do fills += 1; hasParody(roster .. " " .. where, Rules.Fill(s, names, sponsors[sp.id], 142)) end
  end)
end)
assert(#bad == 0, #bad .. " fiction-roster name problem(s):\n" .. table.concat(bad, "\n", 1, math.min(#bad, 20)))
assert(fills >= 6000, "the fill scan saw only " .. fills .. " filled strings: wrong module?")
table.insert(out, string.format("(a) fiction: all %d visitors and %d sponsors swapped; %d rendered names, no parody or real name; %d filled strings, no parody name",
  #W.Visitors, #W.Sponsors, named, fills))

-- (b) each roster forced in turn: no real name in any shipped string
local artists = {}
for _, a in ipairs(A.Artists) do artists[a.id] = a.name end
local scanned = {}
for _, roster in ipairs(ROSTERS) do
  withRoster(roster, function()
    local names, sponsors = namesNow(), sponsorsNow()
    local n = 0
    for _, v in ipairs(W.Visitors) do
      for _, s in ipairs(W.Sponsors) do n += hasReal(roster .. " visitor " .. v.id .. " name", Rules.Fill(names[v.id] or "", names, sponsors[s.id])) end
      n += hasReal(roster .. " visitor " .. v.id .. " style", v.style)
    end
    for id, sn in pairs(sponsors) do n += hasReal(roster .. " sponsor " .. id, sn) end
    eachCardString(function(where, s)
      if type(s) ~= "string" then return end
      for _, sp in ipairs(W.Sponsors) do n += hasReal(roster .. " " .. where, Rules.Fill(s, names, sponsors[sp.id], 142)) end
    end)
    local function leaves(where, x, seen)
      if type(x) == "string" then n += hasReal(where, x)
      elseif type(x) == "table" and not seen[x] then
        seen[x] = true
        for k, v in pairs(x) do leaves(where .. "." .. tostring(k), v, seen) end
      end
    end
    leaves(roster .. " LifeRules.Copy", L.Copy, {})
    local storyNames = { visitors = names, artists = artists, sponsors = sponsors, ranks = Config.Ranks, tiers = Config.Life.Tiers }
    for _, k in ipairs(L.KINDS) do
      for _, first in ipairs({ false, true }) do
        local entries = {}
        if k == "placement" or k == "hit" then for id in pairs(names) do table.insert(entries, { d = 3, k = k, v = id }) end
        elseif k == "delivery" or k == "delivery3" then for id in pairs(artists) do table.insert(entries, { d = 3, k = k, v = id }) end
        elseif k == "sponsor" or k == "sponsor_drop" then for id in pairs(sponsors) do table.insert(entries, { d = 3, k = k, s = id }) end
        elseif k == "level" then for lv = 1, #Config.Ranks do table.insert(entries, { d = 3, k = k, n = lv }) end
        elseif k == "tier" then for _, t in ipairs(Config.Life.Tiers) do table.insert(entries, { d = 3, k = k, key = t.id }) end
        else table.insert(entries, { d = 3, k = k }) end
        for _, e in ipairs(entries) do
          e.first = first or nil
          local line = L.StoryText(e, storyNames)
          if line then n += hasReal(roster .. " story " .. k, line) end
        end
      end
    end
    for id in pairs(names) do
      for kind in pairs(L.Copy.DiscoKinds) do
        local line = L.DiscoText({ d = 3, kind = kind, v = id }, storyNames)
        if line then n += hasReal(roster .. " disco " .. id, line) end
      end
    end
    for _, t in ipairs(Config.Life.Tiers) do
      n += hasReal(roster .. " banner " .. t.id, L.BannerText(t.id, true)); n += hasReal(roster .. " banner " .. t.id .. " (no visit)", L.BannerText(t.id, false))
    end
    for lvl, text in pairs(Config.Unlocks) do n += hasReal("Config.Unlocks[" .. lvl .. "]", text) end
    for _, h in ipairs(Config.Hints) do n += hasReal("Config.Hints " .. h.term, h.text) end
    for _, g in ipairs(Config.Gear) do n += hasReal("Config.Gear " .. g.id, g.name); n += hasReal("Config.Gear " .. g.id .. " desc", g.desc) end
    for i, r in ipairs(Config.Ranks) do n += hasReal("Config.Ranks[" .. i .. "]", r) end
    for _, g in ipairs(Config.Career.Gates) do n += hasReal("Config.Career.Gates " .. g.id, g.name); n += hasReal("Config.Career.Gates " .. g.id .. " desc", g.desc) end
    for _, a in ipairs(A.Artists) do
      n += hasReal("artist " .. a.id .. " name", a.name); n += hasReal("artist " .. a.id .. " style", a.style)
      for q, text in pairs(a.quotes or {}) do n += hasReal("artist " .. a.id .. " quote " .. q, text) end
    end
    for _, b in ipairs(A.Briefs) do n += hasReal("brief " .. b.id .. " title", b.title) end
    scanned[roster] = n
  end)
end
assert(Config.WalkIns.Roster == ROSTER0, "the roster scopes did not put the configured roster back")
assert(#bad == 0, #bad .. " string(s) name a real artist, brand, title or platform:\n" .. table.concat(bad, "\n", 1, math.min(#bad, 20)))
assert(scanned.parody >= 10000 and scanned.fiction >= 10000, "the real-name scan saw too little: wrong modules?")
table.insert(out, string.format("(b) no real name in any shipped string: %d strings with the parody roster, %d with the fiction roster (%d tokens)",
  scanned.parody, scanned.fiction, #REAL))

-- (c) F6: sponsor_warning's result text in two lines for every sponsor name in both rosters (resText: 312 x 30 px)
local FONT, SIZE, WIDTH = Enum.Font.GothamBold, 12, 312
local function measure(text, width)
  local ok, v = pcall(function() return TextService:GetTextSize(text, SIZE, FONT, Vector2.new(width, 10000)) end)
  assert(ok, "TextService:GetTextSize failed in Edit: " .. tostring(v))
  return v
end
local lineH = measure("Ag", 10000).Y
assert(lineH > 0, "a one-line string measures " .. tostring(lineH) .. " px tall")
local function linesOf(text) return math.floor(measure(text, WIDTH).Y / lineH + 0.5) end
local known = measure("You ate, you laughed, and you came back to the beat", 10000).X
assert(known >= 240 and known <= 330, string.format("calibration: a line the game shows at about 283 px measures %.0f px (want 240..330): the font metrics are off", known))
local warn = W.FollowupById.sponsor_warning
assert(warn and warn.resolve.good.text == warn.resolve.bad.text, "sponsor_warning's two sides should read the same")
local OLD = "{sponsor} warned you instead of dropping you. Get your aura back over their bar before they check again."
local longest, worst, worstName, measured = nil, 0, nil, 0
for _, roster in ipairs(ROSTERS) do
  withRoster(roster, function()
    local names, sponsors = namesNow(), sponsorsNow()
    for _, s in ipairs(W.Sponsors) do
      local nm = sponsors[s.id]
      if not longest or #nm > #longest then longest = nm end
      local text = Rules.Fill(warn.resolve.good.text, names, nm)
      local n = linesOf(text)
      measured += 1
      assert(n <= 2, string.format("F6 (%s roster): sponsor_warning with %s takes %d lines of the %d px label: '%s' (before the fix's sync the place"
        .. " holds the old text: the expected red)", roster, nm, n, WIDTH, text))
      if n > worst then worst, worstName = n, nm end
    end
  end)
end
local control = linesOf(Rules.Fill(OLD, W.Names("fiction"), longest))
assert(control >= 3, string.format("control: the old warning with %s measures %d line(s), want 3 (the measurement can't see the failure)", longest, control))
table.insert(out, string.format("(c) F6: sponsor_warning fits %d line(s) for all %d sponsor names in both rosters (widest %s; the old text with %s: %d lines;"
  .. " calibration %.0f px)", worst, measured, tostring(worstName), longest, control, known))

return "T80 OK: " .. table.concat(out, "; ")
