-- Builds the PROD LIFE III panel (the in-game OS) inside a ScreenGui and returns a controller.
-- The Credits tab lists the discography (rows Disco_<n>, newest first, n the row's place on screen), then the player's own
-- credits (payload.profile.credits, newest first); the credits wall opens it.
-- Tabs come from M.Tabs (data-driven). The Gear tab lists Config.Gear with BUY / EQUIP buttons (an item whose career
-- needs aren't met shows NEEDS and what it needs); buying and equipping go through C.OnBuy(id) / C.OnEquip(id), which
-- the client wires to the Gear remotes and then calls C.Refresh(payload). The Career tab (payload.career = Career_Get)
-- shows the six stats, the gates (UNLOCK / SHOWING / HIDDEN through C.OnUnlock(id)) and the stat-gated gear (BUY
-- through C.OnBuy(id)). Rows are named Gear_<id>, Gate_<id> and CareerGear_<id>; each has an "Action" button. Above the
-- gates sit the milestone bars Bar_tier, Bar_level and Bar_hall (a Label, a Back with a Fill, and a Fraction attribute 0..1).
-- The Story tab lists the FIRSTS (cells First_<id> in the two-column grid Firsts, Config.Life.Firsts order) and the story
-- (rows Story_<n>, newest first, n the row's place on screen). The Profile tab and the Card share the LifeLine and Ribbons
-- rows. Story, discography, bars and the Profile's rows read payload.career.life (Career.State; LifeRules.View) and every
-- word comes from LifeRules; a line LifeRules can't render cleanly is skipped.
-- The career comes after the panel is open: when a payload has none and the tab shows it (CAREER_TABS), C.FetchCareer (the
-- client sets it to a blocking Career_Get) runs in the background, so a slow or switched-off Career system never holds a
-- panel up. Arriving at such a tab fetches too; a re-render never does, so a fetch that failed doesn't loop. The Career, Story
-- and Credits tabs read "Loading" meanwhile, and all four re-render when it lands (no other tab does). A re-render after a
-- purchase or unlock keeps a gamepad's place on the row it was on, and the scroll position; a new tab or an opening panel
-- starts at the top. On a short panel (a phone) the keyboard footer gives its room to Content. OK_UI's ForceViewport
-- attribute (tests) sizes the panel as that viewport would.
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Format = require(RS.OK.Modules.Format)
local CareerRules = require(RS.OK.Modules.CareerRules)
local LifeRules = require(RS.OK.Modules.LifeRules)
local Copy = LifeRules.Copy
local M = {}
M.Tabs = { "Credits", "Sessions", "Gear", "Career", "Story", "Profile" }
local CAREER_TABS = { Career = true, Story = true, Credits = true, Profile = true } -- the tabs that show the career
local TAB_GAP = 4 -- six tabs share a phone-wide panel: a small gap and small button padding leave the labels room
local COULD_NOT_LOAD = "Couldn't load your career right now. Close the panel and open it again."
local CONTENT_INSET, CONTENT_INSET_SHORT = 160, 118 -- how much shorter than the panel Content is, with the footer and without
local SHORT_CONTENT = 160 -- Content under this, with the footer, gets the footer's room
local FIRST_H, FIRST_GAP = 25, 3 -- a FIRSTS cell (two lines), so a phone reaches the story within a few swipes
local CREDITS_ORDER = 300 -- under the discography's rows (Config.Life.DiscoMax at most)
local AURA = Color3.fromRGB(200, 75, 255) -- the Aura purple (UITheme has none)
local WORDS = { aura = { "AURA", "AURA" }, followers = { "FOLLOWER", "FOLLOWERS" }, placements = { "PLACEMENT", "PLACEMENTS" },
  hits = { "HIT", "HITS" }, sponsors = { "SPONSOR", "SPONSORS" } }
-- "1 PLACEMENT", "300 AURA", "5K FOLLOWERS"
local function needLabel(stat, n)
  local w = WORDS[stat] or { string.upper(stat), string.upper(stat) }
  return Format.Count(n) .. " " .. (n == 1 and w[1] or w[2])
end
-- an item's needs in stat order: "2 PLACEMENTS · 5K FOLLOWERS"
local function needsText(needs)
  local out = {}
  for _, stat in ipairs(CareerRules.STATS) do if needs and needs[stat] then table.insert(out, needLabel(stat, needs[stat])) end end
  return table.concat(out, " · ")
end
M.Title = "PROD LIFE III"
function M.Build(gui, Theme)
  local function new(class, props, parent) local i = Instance.new(class); for k, v in pairs(props) do i[k] = v end; i.Parent = parent; return i end
  local function corner(p, r) new("UICorner", {CornerRadius = UDim.new(0, r or 10)}, p) end
  local PANEL_W, PANEL_H = 0.62, 0.7
  local panel = new("Frame", {Name = "Panel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(PANEL_W, PANEL_H), BackgroundColor3 = Theme.panel, BorderSizePixel = 0, Visible = false}, gui)
  corner(panel, 14); new("UIStroke", {Color = Theme.line, Thickness = 1.5}, panel)
  new("UISizeConstraint", {MinSize = Vector2.new(320, 260), MaxSize = Vector2.new(900, 640)}, panel)
  local function sizePanel()
    local vp = gui:GetAttribute("ForceViewport")
    panel.Size = typeof(vp) == "Vector2" and UDim2.fromOffset(vp.X * PANEL_W, vp.Y * PANEL_H) or UDim2.fromScale(PANEL_W, PANEL_H)
  end
  gui:GetAttributeChangedSignal("ForceViewport"):Connect(sizePanel)
  sizePanel()
  local header = new("TextLabel", {Name = "Header", Size = UDim2.new(1, -60, 0, 44), Position = UDim2.fromOffset(18, 6), BackgroundTransparency = 1, Text = M.Title, TextColor3 = Theme.accent, Font = Theme.fontBlack, TextSize = 24, TextXAlignment = Enum.TextXAlignment.Left}, panel)
  local close = new("TextButton", {Name = "Close", Size = UDim2.fromOffset(44, 44), Position = UDim2.new(1, -52, 0, 6), BackgroundColor3 = Theme.line, Text = "X", TextColor3 = Theme.text, Font = Theme.fontBlack, TextSize = 18}, panel); corner(close, 8)
  local tabs = new("Frame", {Name = "Tabs", Size = UDim2.new(1, -36, 0, 44), Position = UDim2.fromOffset(18, 54), BackgroundTransparency = 1}, panel)
  new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, TAB_GAP), SortOrder = Enum.SortOrder.LayoutOrder}, tabs)
  local content = new("ScrollingFrame", {Name = "Content", Size = UDim2.new(1, -36, 1, -CONTENT_INSET), Position = UDim2.fromOffset(18, 106), BackgroundColor3 = Theme.bg, BorderSizePixel = 0, ScrollBarThickness = 6, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y}, panel)
  corner(content, 10)
  local list = new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, content)
  new("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10)}, content)
  -- the toast wraps rather than cut a line: 360 wide, at least 40 tall, growing upward from its bottom edge (the rooms
  -- plan's Task 6: copy §3.1 with a long owner name runs to two lines)
  local toast = new("TextLabel", {Name = "Toast", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24), Size = UDim2.fromOffset(360, 40), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, BackgroundColor3 = Theme.panel, TextColor3 = Theme.text, Font = Theme.font, TextSize = 16, Text = "", Visible = false}, gui)
  corner(toast, 10); new("UIStroke", {Color = Theme.accent2, Thickness = 1}, toast)
  new("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6)}, toast)
  local footer = new("TextLabel", {Name = "Footer", Size = UDim2.new(1, -36, 0, 36), Position = UDim2.new(0, 18, 1, -48), BackgroundTransparency = 1, Text = "", TextColor3 = Theme.muted, Font = Theme.font, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left}, panel)
  -- measured from the panel, never from Content, which this resizes
  local function fitContent()
    local short = panel.AbsoluteSize.Y - CONTENT_INSET < SHORT_CONTENT
    footer.Visible = not short
    content.Size = UDim2.new(1, -36, 1, -(short and CONTENT_INSET_SHORT or CONTENT_INSET))
  end
  panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitContent)
  fitContent()
  local C = {}; local current = nil; local tabButtons = {}; local lastPayload = {}
  -- the background career fetch: careerSince = os.clock() when the one that counts went out (nil = none out);
  -- careerSerial drops an answer that newer career data (another fetch, an Open, a Refresh) has overtaken
  local CAREER_WAIT = 10 -- after this a fetch that never answered reads as "couldn't load"
  local careerSerial, careerSince = 0, nil
  local function line(text, color, size, font, order)
    return new("TextLabel", {Size = UDim2.new(1, 0, 0, size + 10), BackgroundTransparency = 1, Text = text, TextColor3 = color or Theme.text, Font = font or Theme.font, TextSize = size or 15, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order or 0, RichText = true}, content)
  end
  -- a named row of plain text (names are data, so no rich text)
  local function row(name, text, color, size, order)
    local l = line(text, color, size, Theme.font, order)
    l.Name = name; l.RichText = false
    return l
  end
  local function clear() for _, c in ipairs(content:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end end
  C.OnBuy, C.OnEquip, C.OnUnlock = function() end, function() end, function() end
  local function careerPending() return careerSince ~= nil and os.clock() - careerSince < CAREER_WAIT end
  -- the career's life part, nil until the career lands (or when Career.State could not build it)
  local function lifeOf(payload)
    local cr = payload and payload.career
    return type(cr) == "table" and type(cr.life) == "table" and cr.life or nil
  end
  -- what StoryText and DiscoText read: the names Career.State sent for this life's ids (the server's roster), plus Config's
  local function namesOf(life)
    local Config = require(RS.OK.Config)
    local n = type(life.names) == "table" and life.names or {}
    return {visitors = n.visitors, artists = n.artists, sponsors = n.sponsors, ranks = Config.Ranks, tiers = Config.Life.Tiers}
  end
  -- rows from `list` (oldest first), newest first; a nil text is skipped, so n counts only rows on screen. Returns how many
  local function newestRows(list, prefix, order, text)
    local n = 0
    for i = #list, 1, -1 do
      local t = text(list[i])
      if t then n += 1; row(prefix .. n, t, Theme.text, 14, order + n) end
    end
    return n
  end
  -- the life line and the ribbons row, for the card and the Profile tab: pub is a LifeRules.Public, or the card's fields of
  -- the same names (the title can be the tier's own word, and the ribbons are ids in Config.Life.Ribbons order)
  local function lifeRows(pub, order)
    local parts = {}
    if pub.title then table.insert(parts, tostring(pub.title)) end
    if pub.tier and pub.tier ~= pub.title then table.insert(parts, tostring(pub.tier)) end
    if pub.year then table.insert(parts, LifeRules.Fill(Copy.CardYear, {year = pub.year})) end
    if #parts > 0 then row("LifeLine", table.concat(parts, " · "), Theme.gold, 15, order) end
    local ribbons = {}
    for _, id in ipairs(type(pub.ribbons) == "table" and pub.ribbons or {}) do
      if Copy.Ribbons[id] then table.insert(ribbons, Copy.Ribbons[id]) end
    end
    if #ribbons > 0 then row("Ribbons", Copy.RibbonPrefix .. table.concat(ribbons, " · "), Theme.text, 14, order + 1) end
  end
  local renderers = {}
  renderers.Credits = function(payload)
    local p = (payload and payload.profile) or {}
    local credits = type(p.credits) == "table" and p.credits or {}
    -- the discography first, once the career lands: on a phone the credits' lines would push it far down
    local life = lifeOf(payload)
    if life then
      local disco = type(life.disco) == "table" and life.disco or {}
      local names = namesOf(life)
      if #disco > 0 then line(Copy.DiscoHeader, Theme.gold, 18, Theme.fontBlack, 0) end
      newestRows(disco, "Disco_", 0, function(e) return LifeRules.DiscoText(e, names) end)
    elseif careerPending() then
      line(Copy.DiscoHeader, Theme.gold, 18, Theme.fontBlack, 0)
      row("LifeStatus", Copy.Loading, Theme.muted, 14, 1)
    else
      row("LifeStatus", Copy.LifeFailed, Theme.muted, 14, 1)
    end
    line("Your credits", Theme.gold, 18, Theme.fontBlack, CREDITS_ORDER)
    if #credits == 0 then
      line("No credits yet. Take a session request in the beat maker and deliver it: the song goes here with your name on it.", Theme.text, 15, Theme.font, CREDITS_ORDER + 1)
    else
      line(#credits .. (#credits == 1 and " song" or " songs") .. " with your beat on it, newest first.", Theme.muted, 13, Theme.font, CREDITS_ORDER + 1)
      for i = #credits, 1, -1 do
        local c = credits[i]
        line(string.format("<b>%s</b>  <font color='#9696a5'>%s · prod. you</font>  %s", c.t or "?", c.a or "?", string.rep("★", c.s or 0)), Theme.text, 15, Theme.font, CREDITS_ORDER + 2 + (#credits - i))
      end
    end
    footer.Text = "Your credits · Backspace / B to close"
  end
  -- the story: the FIRSTS checklist, then the career, newest first
  renderers.Story = function(payload)
    footer.Text = Copy.StoryFooter
    local life = lifeOf(payload)
    if not life then
      line(Copy.StoryHeader, Theme.gold, 18, Theme.fontBlack, 0)
      row("LifeStatus", careerPending() and Copy.Loading or Copy.LifeFailed, Theme.muted, 14, 1)
      return
    end
    local Config = require(RS.OK.Config)
    line(Copy.FirstsHeader, Theme.gold, 18, Theme.fontBlack, 0)
    -- two columns (the Stats tiles' pattern), each cell its label over its state
    local firsts = Config.Life.Firsts
    local gridRows = math.ceil(#firsts / 2)
    local grid = new("Frame", {Name = "Firsts", Size = UDim2.new(1, 0, 0, gridRows * FIRST_H + (gridRows - 1) * FIRST_GAP), BackgroundTransparency = 1, LayoutOrder = 1}, content)
    new("UIGridLayout", {CellSize = UDim2.new(0.5, -6, 0, FIRST_H), CellPadding = UDim2.fromOffset(6, FIRST_GAP), SortOrder = Enum.SortOrder.LayoutOrder}, grid)
    for i, id in ipairs(firsts) do
      local done = type(life.firsts) == "table" and life.firsts[id] ~= nil
      local cell = new("TextLabel", {Name = "First_" .. id, BackgroundTransparency = 1, RichText = true, TextScaled = true, Font = Theme.font, TextColor3 = done and Theme.text or Theme.muted,
        TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = i,
        Text = (done and '<font color="#00FF8C">✓</font> ' or "") .. tostring(Copy.FirstLabels[id] or id) .. "\n<font color='#9696a5'>" .. LifeRules.FirstText(life.firsts, id) .. "</font>"}, grid)
      new("UITextSizeConstraint", {MaxTextSize = 11, MinTextSize = 8}, cell)
    end
    line(Copy.StoryHeader, Theme.gold, 18, Theme.fontBlack, 100)
    local names = namesOf(life)
    local n = newestRows(type(life.story) == "table" and life.story or {}, "Story_", 100, function(e) return LifeRules.StoryText(e, names) end)
    if n == 0 then line(Copy.StoryEmpty, Theme.muted, 14, Theme.font, 101) end
  end
  renderers.Sessions = function(payload)
    line("Sessions", Theme.gold, 18, Theme.fontBlack, 0)
    local d = payload and payload.profile and payload.profile.daw
    if d and d.v == 2 and d.slots then
      local n = 0
      for i = 1, 3 do local sl = d.slots["s" .. i] or d.slots[i] or d.slots[tostring(i)]; if sl then n += 1; local hits = select(2, sl.pattern:gsub("[^0%-]", "")); line(string.format("Slot %d  <b>%d BPM</b>   %d hits%s", i, sl.bpm or 0, hits, (sl.swing or 0) > 0 and ("   swing " .. sl.swing .. "%") or ""), Theme.text, 15, Theme.mono, i) end end
      if n == 0 then line("No beat saved yet. Walk up to a laptop or PC and use Make a beat.", Theme.text, 15, Theme.font, 1) end
    elseif d and d.pattern then
      local hits = select(2, d.pattern:gsub("1", ""))
      line(string.format("Your beat  <b>%d BPM</b>   %d hits   save #%d", d.bpm or 0, hits, d.saves or 1), Theme.text, 15, Theme.mono, 1)
    else
      line("No beat saved yet. Walk up to a laptop or PC and use Make a beat.", Theme.text, 15, Theme.font, 1)
    end
    line("Walk up to a laptop or PC and use Make a beat. Press the speaker button so people nearby hear it.", Theme.text, 14, Theme.font, 2)
    line("Session requests pay money. Spend it at the gear rack: Roll FX for hat rolls, the Swing Unit for swing, voices for the keys. The 808 and the music box are free. Three beat slots.", Theme.muted, 14, Theme.font, 4)
    footer.Text = "Beat Maker · Backspace / B to close"
  end
  renderers.Profile = function(payload)
    local p = (payload and payload.profile) or {}
    local Config = require(RS.OK.Config)
    local rank = Config.Ranks and Config.Ranks[p.level or 1] or ""
    line("Producer profile", Theme.gold, 18, Theme.fontBlack, 0)
    line("<b>" .. (game:GetService("Players").LocalPlayer.DisplayName or "") .. "</b>   " .. rank, Theme.text, 16, Theme.font, 1)
    local life = lifeOf(payload)
    if life then lifeRows(LifeRules.Public(life, Config.Life), 2) end
    line(string.format("Level %d   ·   XP %d   ·   Money %s   ·   Beats saved %d", p.level or 1, p.xp or 0, Format.Money(p.cred or 0), (p.daw and p.daw.saves) or 0), Theme.accent2, 15, Theme.mono, 4)
    local credits = type(p.credits) == "table" and p.credits or {}
    line(#credits == 0 and "No credits yet. Take a session request in the beat maker." or ("Your credits (" .. #credits .. ")"), Theme.text, 15, Theme.fontBlack, 5)
    for i = #credits, math.max(1, #credits - 7), -1 do
      local c = credits[i]
      line(string.format("%s  <font color='#9696a5'>%s · prod. you</font>  %s", c.t or "?", c.a or "?", string.rep("★", c.s or 0)), Theme.text, 14, Theme.font, 10 + (#credits - i))
    end
    local pl = type(p.plaques) == "table" and p.plaques or {}
    line(#pl > 0 and ("🏆 Plaques: " .. #pl .. " (3-star Weekly Singles)") or "No plaques yet · 3 stars on a Weekly Single earns one", Theme.text, 14, Theme.font, 9)
    footer.Text = "Profile · Backspace / B to close"
  end
  -- another producer's public card (opened by walking up to them; not a tab)
  renderers.Card = function(payload)
    local c = (payload and payload.card) or {}
    line("Producer card", Theme.gold, 18, Theme.fontBlack, 0)
    line("<b>" .. tostring(c.name or "?") .. "</b>   " .. tostring(c.rank or ""), Theme.text, 18, Theme.font, 1)
    lifeRows(c, 2)
    line(string.format("Level %d   ·   🔥 %d FIRE   ·   %d credits   ·   %d deliveries%s", c.level or 1, c.fires or 0, c.credits or 0, c.deliveries or 0,
      (c.streak or 0) > 0 and ("   ·   streak " .. c.streak) or ""), Theme.accent2, 15, Theme.mono, 4)
    local career = line(Format.Signed(c.aura) .. " AURA · " .. Format.Count(c.followers) .. " FOLLOWERS · " .. tostring(c.placements or 0) .. " PLACEMENTS · "
      .. tostring(c.hits or 0) .. " HITS · " .. tostring(c.sponsors or 0) .. " SPONSORS", AURA, 14, Theme.mono, 5)
    career.Name = "CareerLine"
    if (c.flips or 0) > 0 then line(string.format("Flipped by other producers %d time%s", c.flips, c.flips == 1 and "" or "s"), Theme.muted, 14, Theme.font, 6) end
    line((c.plaqueCount or 0) > 0 and ("🏆 Plaques (" .. c.plaqueCount .. ")") or "No plaques yet", Theme.text, 15, Theme.fontBlack, 7)
    for i, p in ipairs(c.plaques or {}) do line("🏆 " .. p.t .. "  <font color='#9696a5'>" .. p.a .. "</font>", Theme.text, 14, Theme.font, 10 + i) end
    line("Latest credits", Theme.text, 15, Theme.fontBlack, 40)
    for i, r in ipairs(c.recent or {}) do line(string.format("%s  <font color='#9696a5'>%s · prod. %s</font>  %s", r.t, r.a, tostring(c.name or ""), string.rep("★", r.s or 0)), Theme.text, 14, Theme.font, 40 + i) end
    footer.Text = "Producer card · Backspace / B to close"
  end
  -- gear rack: one row per item, BUY / EQUIP / OWNED / locked
  renderers.Gear = function(payload)
    local Config = require(RS.OK.Config)
    local g = (payload and payload.gear) or { items = {}, cred = 0, level = 1 }
    local owned, equipped, meets = {}, {}, {}
    for _, it in ipairs(g.items or {}) do owned[it.id] = it.owned; equipped[it.id] = it.equipped; meets[it.id] = it.meets end
    line("Gear rack", Theme.gold, 18, Theme.fontBlack, 0)
    line(string.format("You have <b>%s</b>. Session requests pay money; tools unlock beat-maker features, looks change how you show up.", Format.Money(g.cred or 0)), Theme.muted, 13, Theme.font, 1)
    for i, it in ipairs(Config.Gear) do
      local row = new("Frame", {Name = "Gear_" .. it.id, Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = Theme.panel, LayoutOrder = 10 + i}, content)
      corner(row, 8)
      local swatch = it.color or Theme.accent2
      new("Frame", {Name = "Swatch", Size = UDim2.fromOffset(6, 40), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = swatch, BorderSizePixel = 0}, row)
      new("TextLabel", {Name = "Name", Size = UDim2.new(1, -150, 0, 22), Position = UDim2.fromOffset(22, 6), BackgroundTransparency = 1, Text = it.name .. "  <font color='#9696a5'>" .. string.upper(it.kind) .. "</font>", RichText = true,
        TextColor3 = Theme.text, Font = Theme.fontBlack, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left}, row)
      -- needs met unless the server says otherwise (meets == false); an unmet item says what it needs instead of its desc
      local needy = not owned[it.id] and it.needs ~= nil and meets[it.id] == false
      new("TextLabel", {Name = "Desc", Size = UDim2.new(1, -150, 0, 20), Position = UDim2.fromOffset(22, 28), BackgroundTransparency = 1,
        Text = needy and ("Needs " .. needsText(it.needs)) or it.desc, TextColor3 = needy and Theme.accent or Theme.muted,
        Font = Theme.font, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, row)
      local text, color, action
      if owned[it.id] then
        if it.kind == "neon" or it.kind == "plate" or it.kind == "fit" then
          text, color, action = equipped[it.id] and "EQUIPPED" or "EQUIP", equipped[it.id] and Theme.accent2 or Theme.line, "equip"
        else text, color = it.price == 0 and "FREE" or "OWNED", Theme.line end
      elseif (g.level or 1) < it.level then text, color = "LV " .. it.level, Theme.line
      elseif needy then text, color = "NEEDS", Theme.line
      else text, color, action = "BUY " .. Format.Money(it.price), (g.cred or 0) >= it.price and Theme.accent or Theme.line, "buy" end
      local b = new("TextButton", {Name = "Action", Size = UDim2.fromOffset(120, 44), Position = UDim2.new(1, -128, 0, 6), BackgroundColor3 = color, Text = text,
        TextColor3 = Theme.text, Font = Theme.fontBlack, TextSize = 14, AutoButtonColor = action ~= nil}, row)
      corner(b, 8)
      b:SetAttribute("Action", action or "")
      if action == "buy" then b.MouseButton1Click:Connect(function() C.OnBuy(it.id) end)
      elseif action == "equip" then b.MouseButton1Click:Connect(function() C.OnEquip(it.id) end) end
    end
    footer.Text = "Gear rack · Backspace / B to close"
  end
  -- the Career tab: six stats, the gates and the stat-gated gear, each need ticked against what you have
  local function chipRow(parent, check, cost)
    local holder = new("Frame", {Name = "Needs", Size = UDim2.new(1, 0, 0, 20), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 3}, parent)
    new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, holder)
    local function chip(text, color, order)
      local l = new("TextLabel", {Name = "Chip" .. order, Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Theme.panel,
        Text = text, RichText = true, TextColor3 = color, Font = Theme.fontBlack, TextSize = 11, LayoutOrder = order}, holder)
      corner(l, 5); new("UIPadding", {PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7)}, l)
    end
    for i, r in ipairs(check and check.rows or {}) do
      chip((r.ok and '<font color="#00FF8C">✓</font> ' or '<font color="#FF3CA0">×</font> ') .. needLabel(r.stat, r.need), r.ok and Theme.text or Theme.muted, i)
    end
    if (cost or 0) > 0 then chip(Format.Money(cost), (check and check.money and check.money.ok) and Theme.ledOn or Theme.muted, 99) end
  end
  local function careerRow(name, order, title, desc, check, cost, text, ready, onClick)
    local row = new("Frame", {Name = name, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.bg, LayoutOrder = order}, content)
    corner(row, 9)
    new("UIStroke", {Color = ready and Theme.ledOn or Theme.line, Thickness = 1}, row)
    new("UISizeConstraint", {MinSize = Vector2.new(0, 60)}, row)
    local info = new("Frame", {Name = "Info", Position = UDim2.fromOffset(10, 8), Size = UDim2.new(1, -156, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, row)
    new("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder}, info)
    new("UIPadding", {PaddingBottom = UDim.new(0, 8)}, info)
    new("TextLabel", {Name = "Name", Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = title, TextColor3 = Theme.text, Font = Theme.fontBlack,
      TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = 1}, info)
    new("TextLabel", {Name = "Desc", Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Text = desc or "", TextColor3 = Theme.muted, Font = Theme.font,
      TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = 2}, info)
    chipRow(info, check, cost)
    local b = new("TextButton", {Name = "Action", Size = UDim2.fromOffset(136, 44), Position = UDim2.new(1, -144, 0, 8), BackgroundColor3 = ready and Theme.ledOn or Theme.line,
      Text = text, TextColor3 = ready and Theme.bg or Theme.text, Font = Theme.fontBlack, TextSize = 13, AutoButtonColor = onClick ~= nil}, row)
    corner(b, 8)
    b:SetAttribute("Action", onClick and "act" or "")
    if onClick then b.MouseButton1Click:Connect(onClick) end
    return row
  end
  -- a milestone bar: its line (scaled down to fit a phone), a track and a fill at `fraction` of it
  local function bar(id, order, text, fraction, color)
    local f = math.clamp(fraction, 0, 1)
    local holder = new("Frame", {Name = "Bar_" .. id, Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, LayoutOrder = order}, content)
    holder:SetAttribute("Fraction", f)
    local label = new("TextLabel", {Name = "Label", Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = text, TextColor3 = Theme.text, Font = Theme.fontBlack,
      TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left}, holder)
    new("UITextSizeConstraint", {MaxTextSize = 12, MinTextSize = 9}, label)
    local back = new("Frame", {Name = "Back", Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 8), BackgroundColor3 = Theme.line, BorderSizePixel = 0}, holder)
    corner(back, 4)
    corner(new("Frame", {Name = "Fill", Size = UDim2.fromScale(f, 1), BackgroundColor3 = color, BorderSizePixel = 0}, back), 4)
  end
  -- Followers to the next tier above the highest reached, XP to the next level (the replicated attributes the HUD reads),
  -- THE HALL's needs and money (each counts the same; the fraction is their mean)
  local function careerBars(cr)
    local Config = require(RS.OK.Config)
    local s, tiers = cr.stats, Config.Life.Tiers
    local life = cr.life
    local _, reached = LifeRules.TierFor(s.followers, tiers)
    local nextTier = tiers[(type(life) == "table" and life.tierIndex or reached) + 1]
    if nextTier then
      bar("tier", 2, LifeRules.Fill(Copy.Bars.tier, {tier = nextTier.id, have = LifeRules.Commas(s.followers), need = LifeRules.Commas(nextTier.followers)}),
        s.followers / nextTier.followers, Theme.accent2)
    else bar("tier", 2, Copy.Bars.tierTop, 1, Theme.accent2) end
    -- within the level, as the HUD's bar: from Config, because NextLevelXP reads as the player's XP at the top level
    local player = Players.LocalPlayer
    local level, xp = player:GetAttribute("Level") or 1, player:GetAttribute("XP") or 0
    local lo, hi = Config.Levels[level] or 0, Config.Levels[level + 1]
    if hi then
      bar("level", 3, LifeRules.Fill(Copy.Bars.level, {level = level + 1, have = LifeRules.Commas(xp - lo), need = LifeRules.Commas(hi - lo)}), (xp - lo) / (hi - lo), Theme.ledOn)
    else bar("level", 3, Copy.Bars.levelTop, 1, Theme.ledOn) end
    for _, g in ipairs(cr.gates or {}) do
      if g.id == LifeRules.HALL_GATE and g.owned then bar("hall", 4, Copy.Bars.hallOpen, 1, Theme.gold)
      elseif g.id == LifeRules.HALL_GATE then
        local check = type(g.check) == "table" and g.check or {rows = {}, money = {have = 0}}
        local sum, parts = 0, 0
        for _, r in ipairs(check.rows) do sum += math.clamp(r.have / r.need, 0, 1); parts += 1 end
        local needs = needsText(g.needs)
        if (g.cost or 0) > 0 then
          sum += math.clamp(check.money.have / g.cost, 0, 1); parts += 1
          needs ..= " · " .. Format.Money(g.cost)
        end
        bar("hall", 4, LifeRules.Fill(Copy.Bars.hall, {needs = needs}), parts > 0 and sum / parts or 1, Theme.gold)
      end
    end
  end
  renderers.Career = function(payload)
    local cr = payload and payload.career
    line("Career", Theme.gold, 18, Theme.fontBlack, 0)
    if type(cr) ~= "table" or type(cr.stats) ~= "table" then
      line(careerPending() and "Loading your career..." or COULD_NOT_LOAD, Theme.muted, 14, Theme.font, 1)
      footer.Text = "Career · Backspace / B to close"
      return
    end
    local s = cr.stats
    local cols = content.AbsoluteSize.X >= 520 and 6 or 3
    local tiles = new("Frame", {Name = "Stats", Size = UDim2.new(1, 0, 0, cols == 6 and 54 or 114), BackgroundTransparency = 1, LayoutOrder = 1}, content)
    new("UIGridLayout", {CellSize = UDim2.new(1 / cols, -6, 0, 54), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder}, tiles)
    local TILES = {
      {"money", "MONEY", Format.CompactMoney(s.money), Theme.ledOn}, {"aura", "AURA", Format.Signed(s.aura), AURA},
      {"followers", "FOLLOWERS", Format.Count(s.followers), Theme.accent2}, {"placements", "PLACEMENTS", Format.Count(s.placements), Theme.gold},
      {"hits", "HITS", Format.Count(s.hits), Theme.gold}, {"sponsors", "SPONSORS", Format.Count(s.sponsors), Theme.accent},
    }
    for i, t in ipairs(TILES) do
      local f = new("Frame", {Name = "Stat_" .. t[1], BackgroundColor3 = Theme.bg, LayoutOrder = i}, tiles)
      corner(f, 9)
      new("TextLabel", {Name = "Label", Position = UDim2.fromOffset(8, 6), Size = UDim2.new(1, -16, 0, 12), BackgroundTransparency = 1, Text = t[2],
        TextColor3 = Theme.muted, Font = Theme.fontBlack, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left}, f)
      new("TextLabel", {Name = "Value", Position = UDim2.fromOffset(8, 22), Size = UDim2.new(1, -16, 0, 24), BackgroundTransparency = 1, Text = t[3],
        TextColor3 = t[4], Font = Theme.fontBlack, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, f)
    end
    careerBars(cr)
    line("UNLOCKS  <font color='#9696a5'>Money is spent. Everything else you have to earn.</font>", Theme.text, 13, Theme.fontBlack, 5)
    for i, g in ipairs(cr.gates or {}) do
      local check = type(g.check) == "table" and g.check or {rows = {}, money = {ok = false}, ok = false}
      local text, ready, click
      if g.kind == "toggle" then -- owned is always false for a toggle: it is on or off once its needs are met
        if check.ok then text, click = g.on and "SHOWING" or "HIDDEN", function() C.OnUnlock(g.id) end
        else text = "LOCKED" end
      elseif g.owned then text = "OWNED"
      elseif check.ok then text, ready, click = "UNLOCK " .. Format.Money(g.cost or 0), true, function() C.OnUnlock(g.id) end
      else text = "LOCKED" end
      careerRow("Gate_" .. g.id, 10 + i, tostring(g.name or g.id), g.desc, check, g.cost, text, ready, click)
    end
    local Config = require(RS.OK.Config)
    local byId = {}
    for _, it in ipairs(Config.Gear or {}) do byId[it.id] = it end
    for i, it in ipairs(cr.gear or {}) do
      local check = type(it.check) == "table" and it.check or {rows = {}, money = {ok = false}, ok = false}
      local text, ready, click
      if it.owned then text = "OWNED"
      elseif not it.levelOk then text = "LV " .. tostring(it.level)
      elseif check.ok then text, ready, click = "BUY " .. Format.Money(it.price or 0), true, function() C.OnBuy(it.id) end
      else text = "LOCKED" end
      local def = byId[it.id]
      careerRow("CareerGear_" .. it.id, 30 + i, tostring(it.name or it.id), def and (string.upper(def.kind) .. " · " .. def.desc) or "", check, it.price, text, ready, click)
    end
    footer.Text = "Career · Backspace / B to close"
  end
  local function select(tab)
    if tab ~= current then content.CanvasPosition = Vector2.new(0, 0) end
    current = tab; clear()
    for name, b in pairs(tabButtons) do b.BackgroundColor3 = (name == tab) and Theme.accent or Theme.line; b.TextColor3 = (name == tab) and Theme.bg or Theme.text end
    if renderers[tab] then renderers[tab](lastPayload) end
  end
  -- re-render the current tab where a gamepad may be on a row's Action button: re-rendering destroys that button, so
  -- the new one in the same row (rows are named by id) gets the selection back, else the tab button
  local function rerender()
    local GS = game:GetService("GuiService")
    local row = GS.SelectedObject
    if row and not row:IsDescendantOf(content) then row = nil end
    while row and row.Parent ~= content do row = row.Parent end
    local rowName = row and row.Name
    select(current)
    if rowName then
      local r = content:FindFirstChild(rowName)
      GS.SelectedObject = (r and r:FindFirstChild("Action")) or tabButtons[current]
    end
  end
  -- fetch the career in the background for the payload on screen (see the header)
  local function fetchCareer()
    if not C.FetchCareer then return end
    careerSerial += 1
    local my = careerSerial
    careerSince = os.clock()
    task.spawn(function()
      local ok, cr = pcall(C.FetchCareer)
      if my ~= careerSerial then return end
      careerSince = nil
      if ok and type(cr) == "table" then lastPayload.career = cr end
      if panel.Visible and CAREER_TABS[current] then rerender() end
    end)
    task.delay(CAREER_WAIT, function() -- never answered: stop reading "Loading"
      if my == careerSerial and careerSince ~= nil and panel.Visible and CAREER_TABS[current] then rerender() end
    end)
  end
  -- arriving at a tab that shows the career when there is none yet (see the header)
  local function careerFor(tab)
    if CAREER_TABS[tab] and lastPayload.career == nil and not careerPending() then fetchCareer() end
  end
  for i, name in ipairs(M.Tabs) do
    local b = new("TextButton", {Name = name, Size = UDim2.new(1 / #M.Tabs, -TAB_GAP * (#M.Tabs - 1) / #M.Tabs, 1, 0), BackgroundColor3 = Theme.line, Text = name, TextColor3 = Theme.text, Font = Theme.font, TextSize = 15, TextScaled = true, LayoutOrder = i}, tabs)
    new("UITextSizeConstraint", {MaxTextSize = 15, MinTextSize = 9}, b)
    new("UIPadding", {PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2)}, b)
    corner(b, 8); tabButtons[name] = b; b.MouseButton1Click:Connect(function() careerFor(name); select(name) end)
  end
  close.MouseButton1Click:Connect(function() C.Close() end)
  function C.Open(tab, payload)
    tab = tab or "Credits"
    lastPayload = payload or {}
    careerSerial += 1; careerSince = nil -- an earlier fetch was for an earlier payload
    careerFor(tab)
    if not panel.Visible then content.CanvasPosition = Vector2.new(0, 0) end -- select resets a new tab; this, the same tab reopened
    fitContent() -- a hidden panel may not have seen its size change
    panel.Visible = true; select(tab)
    local UIS, GS = game:GetService("UserInputService"), game:GetService("GuiService")
    if UIS:GetLastInputType().Name:find("Gamepad") then GS.SelectedObject = tabButtons[tab] end
  end
  function C.Close()
    panel.Visible = false
    local GS = game:GetService("GuiService")
    if GS.SelectedObject and GS.SelectedObject:IsDescendantOf(panel) then GS.SelectedObject = nil end
  end
  function C.IsOpen() return panel.Visible end
  -- switch the open panel to a tab (the client's Studio test seam; players click the tab buttons)
  function C.Select(tab) if panel.Visible and tabButtons[tab] then careerFor(tab); select(tab) end end
  function C.Current() return panel.Visible and current or nil end
  -- re-render the open tab with fresh data (after a purchase); keeps keys the new payload doesn't carry. refetchCareer:
  -- the career changed too and comes again in the background; a tab that shows it waits instead of re-rendering twice
  function C.Refresh(payload, refetchCareer)
    for k, v in pairs(payload or {}) do lastPayload[k] = v end
    if type(payload) == "table" and payload.career ~= nil then careerSerial += 1; careerSince = nil end
    if refetchCareer then fetchCareer() end
    if panel.Visible and current and not (refetchCareer and CAREER_TABS[current]) then rerender() end
  end
  -- a background career fetch is out (the client's Studio test seam waits on it)
  function C.CareerLoading() return careerSince ~= nil end
  local toastToken = 0
  function C.Toast(text) toastToken += 1; local my = toastToken; toast.Text = text; toast.Visible = true; task.delay(2.5, function() if toastToken == my then toast.Visible = false end end) end
  return C
end
return M
