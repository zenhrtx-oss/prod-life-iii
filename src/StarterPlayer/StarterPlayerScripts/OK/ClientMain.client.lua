-- OK Studio client (v1): panel UI, toasts, console meter animation, panel auto-close, the walk-in card (WalkInUI), the
-- tour's coach marks (CoachUI).
-- Studio-only test seam: the OK_UI attribute PanelCommand = "os" | "tab:<Name>" | "unlock:<id>" | "card:self" |
-- "banner:<text>" (as a LifeBanner) | "level:<n>" (a LEVEL UP banner, nothing else) | "nolife" (Story, on a career that came
-- back without its life) | "dayjoin" (the DAY toast's read as a client whose UI is built only now: DayToasts = the toasts a
-- new reader and the live one made between them) runs that action and is cleared to "" when it has finished (tests wait for
-- the "" as the acknowledgement; "os" and "tab:" also wait, up to 5 s, for the panel's background career fetch). CareerOut =
-- a fetch still out at the acknowledgement.
local RS, Players, RunService, UIS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("RunService"), game:GetService("UserInputService")
local player = Players.LocalPlayer
local Config = require(RS.OK.Config); local Theme = require(RS.OK.Modules.UITheme)
local Format = require(RS.OK.Modules.Format)
local LifeRules = require(RS.OK.Modules.LifeRules)
local Event = RS.OK.Remotes.InteractionEvent
-- OK_UI is cloned in from StarterGui at the first spawn, which can take a while at Play start: wait up to 60 s
local playerGui = player:WaitForChild("PlayerGui", 60)
local gui = playerGui and playerGui:WaitForChild("OK_UI", 60)
if not gui then error("[OK][ERR] OK_UI did not reach PlayerGui within 60 s; the HUD and panels cannot start") end
local panel = require(RS.OK.Modules.PanelUI).Build(gui, Theme)
local sourcePos = nil
local function resolve(fullName)
  local node = game
  for seg in string.gmatch(fullName, "[^%.]+") do node = node and node:FindFirstChild(seg) end
  return node
end
-- HUD: level, XP bar, money, OS button (opens your profile anywhere), mute monitors, +XP / +$ floats, level-up banner
local function gearState()
  local ok, st = pcall(function() return RS.OK.Remotes.Gear_Get:InvokeServer() end)
  return ok and st or nil
end
local function careerState()
  local ok, st = pcall(function() return RS.OK.Remotes.Career_Get:InvokeServer() end)
  return (ok and type(st) == "table") and st or nil
end
local function profileState()
  local ok, prof = pcall(function() return RS.OK.Remotes.ProfileFunction:InvokeServer() end)
  return ok and prof or nil
end
-- every panel opens without its career; PanelUI fetches it in the background through this (see PanelUI's header)
panel.FetchCareer = careerState
local function openOS()
  sourcePos = nil
  panel.Open("Profile", { profile = profileState(), gear = gearState() })
end
local hud = require(RS.OK.Modules.HUD).Build(gui, Theme, { onOS = openOS })
-- gear rack: buy / equip from the Gear tab, then re-render it with the server's answer
local function gearAction(remote, id, verb)
  local ok, res = pcall(function() return remote:InvokeServer(id) end)
  if not (ok and type(res) == "table") then panel.Toast("Couldn't reach the rack"); return end
  gui:SetAttribute("LastGear", res.ok and "ok" or tostring(res.reason))
  if res.ok then
    local Cfg = require(RS.OK.Config)
    local name = id
    for _, it in ipairs(Cfg.Gear) do if it.id == id then name = it.name end end
    if verb == "buy" then panel.Toast("Bought " .. name) end
  else
    local why = { cred = "Not enough money yet · take a session request", level = "That one opens at a higher level", owned = "You already own that",
      needs = "Not there yet · check the Career tab", busy = "One sec" }
    panel.Toast(why[res.reason] or ("Couldn't " .. verb .. " (" .. tostring(res.reason) .. ")"))
  end
  -- a purchase can change the Career tab too (stat-gated gear, Money): its career is fetched again in the background
  panel.Refresh({ gear = res.state or gearState(), profile = profileState() }, verb == "buy")
end
panel.OnBuy = function(id) gearAction(RS.OK.Remotes.Gear_Buy, id, "buy") end
panel.OnEquip = function(id) gearAction(RS.OK.Remotes.Gear_Equip, id, "equip") end
-- career gates: UNLOCK a room or switch the sponsor-on-the-TV toggle from the Career tab, then re-render it
panel.OnUnlock = function(id)
  local ok, res = pcall(function() return RS.OK.Remotes.Career_Unlock:InvokeServer(id) end)
  if not (ok and type(res) == "table") then panel.Toast("Couldn't reach the studio"); return end
  gui:SetAttribute("LastUnlock", res.ok and "ok" or tostring(res.reason))
  if res.ok and res.on == nil then -- a room (a toggle answers with on = true / false and its button says so)
    local name = id
    for _, g in ipairs((Config.Career or {}).Gates or {}) do if g.id == id then name = g.name end end
    panel.Toast("Unlocked " .. name)
  elseif not res.ok then
    local why = { needs = "Not there yet · check the Career tab", money = "Not enough money yet", owned = "You already have that" }
    panel.Toast(why[res.reason] or ("Couldn't unlock that (" .. tostring(res.reason) .. ")"))
  end
  panel.Refresh({ career = res.state or careerState(), gear = gearState(), profile = profileState() })
end
-- your own "View card" prompt is for others: hide it for yourself
local function hideOwnCardPrompt(char)
  local root = char:WaitForChild("HumanoidRootPart", 10)
  local pr = root and root:WaitForChild("OK_CardPrompt", 10)
  if pr then pr.Enabled = false end
end
player.CharacterAdded:Connect(hideOwnCardPrompt)
if player.Character then task.spawn(hideOwnCardPrompt, player.Character) end
-- FIRE for other producers' beats on the monitors (its own ScreenGui above the beat maker)
require(RS.OK.Modules.FireButton).Build(Theme)
-- cypher rounds: phase bar with JOIN / SUBMIT / VOTE
require(RS.OK.Modules.CypherUI).Build(Theme)
-- walk-ins: the visitor's choice card, the result card and the Waiting chip (its own ScreenGui; listens to WalkIn itself)
require(RS.OK.Modules.WalkInUI).Build(Theme)
-- the phone: the icon beside the career pills, the pop card with its inline result (its own ScreenGui; listens to Phone
-- itself). A failure here must not take the tour, the dailies, toasts or floats with it
do
  local ok, err = pcall(function() require(RS.OK.Modules.PhoneUI).Build(Theme) end)
  if not ok then warn("[OK][ERR] PhoneUI: " .. tostring(err)) end
end
-- studio tour card under the HUD + outline on the current target (server decides progress)
local tour = require(RS.OK.Modules.TourUI).Build(gui, Theme, hud.Chip)
-- coach marks on the live beat-maker controls for the tour's take, deliver and monitors steps (its own ScreenGui, OK_Coach;
-- the Day One plan, Task 5); it gets every Tour payload. A failure here must not take the pill, the dailies or the toasts
-- with it
local coach = nil
do
  local ok, res = pcall(function() return require(RS.OK.Modules.CoachUI).Build(Theme) end)
  if ok then coach = res else warn("[OK][ERR] CoachUI: " .. tostring(res)) end
end
-- daily requests pill under the HUD (shown when the tour card is not)
local daily = Instance.new("TextLabel")
daily.Name = "Daily"; daily.Position = UDim2.fromOffset(12, 66); daily.Size = UDim2.fromOffset(312, 30)
daily.BackgroundColor3 = Theme.panel; daily.BackgroundTransparency = 0.1; daily.TextColor3 = Theme.ledOn
daily.Font = Theme.fontBlack; daily.TextSize = 13; daily.Text = ""; daily.Visible = false
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = daily end
daily.Parent = gui
local ui = gui
-- a tier banner: an open panel follows it, so the new tier and title show at once
local function lifeBanner(text)
  hud.Banner(text)
  if panel.IsOpen() then panel.Refresh({}, true) end
end
Event.OnClientEvent:Connect(function(kind, payload)
  if kind == "OpenPanel" then
    local src = payload.source and resolve(payload.source)
    sourcePos = (src and src:IsA("BasePart")) and src.Position or nil
    panel.Open(payload.tab, payload) -- opens at once; the Career tab's data follows in the background
  elseif kind == "Toast" then panel.Toast(payload.text or "")
  elseif kind == "Tour" then
    tour.Set(payload)
    if coach then coach.Set(payload) end
    daily.Visible = ui:GetAttribute("TourVisible") ~= true and daily.Text ~= ""
  elseif kind == "Daily" then
    daily.Text = string.format("DAILY REQUESTS %d/%d%s", payload.count or 0, payload.total or 3, (payload.streak or 0) > 0 and ("  ·  🔥 STREAK " .. payload.streak) or "")
    ui:SetAttribute("DailyCount", payload.count or 0); ui:SetAttribute("DailyStreak", payload.streak or 0)
    daily.Visible = ui:GetAttribute("TourVisible") ~= true
  elseif kind == "Cred" then
    if (payload.gained or 0) > 0 then hud.Float(Format.SignedMoney(payload.gained)) end
  elseif kind == "Progress" then
    if (payload.gained or 0) > 0 then hud.Float("+" .. payload.gained .. " XP") end
    if payload.levelUp then hud.LevelUp(payload.level, Config.Unlocks and Config.Unlocks[payload.level]) end
  elseif kind == "LifeBanner" then lifeBanner(payload.text)
  end
end)
-- the DAY toast: Systems/Life sets LifeDayToast on a new career day, possibly before this script got here, so it's read
-- once now as well as on each change; a reader toasts a value once. Returns whether it toasted
local function dayReader()
  local read = LifeRules.DayToastOnce(Config.Life.DaysPerYear)
  return function()
    local text = read(player:GetAttribute("LifeDayToast"))
    if text then panel.Toast(text) end
    return text ~= nil
  end
end
local readDay = dayReader()
player:GetAttributeChangedSignal("LifeDayToast"):Connect(readDay)
readDay()
if RunService:IsStudio() then
  gui:GetAttributeChangedSignal("PanelCommand"):Connect(function()
    local c = gui:GetAttribute("PanelCommand")
    if type(c) ~= "string" or c == "" then return end
    -- the career follows the panel: ack once it has landed, as the panel used to open with it (at most 5 s, so the
    -- tests' 6 s ack wait still gets an answer while the Career system is switched off)
    local function careerLanded()
      local t = os.clock()
      while panel.CareerLoading() and os.clock() - t < 5 do task.wait(0.05) end
    end
    if c == "os" then
      openOS()
      careerLanded()
    elseif c:sub(1, 4) == "tab:" then
      panel.Select(c:sub(5))
      careerLanded()
    elseif c:sub(1, 7) == "unlock:" then panel.OnUnlock(c:sub(8))
    elseif c == "card:self" then
      local ok, res = pcall(function() return RS.OK.Remotes.Card_Get:InvokeServer(player.UserId) end)
      sourcePos = nil
      panel.Open("Card", { card = (ok and type(res) == "table") and res.card or nil })
    elseif c:sub(1, 7) == "banner:" then lifeBanner(c:sub(8))
    elseif c:sub(1, 6) == "level:" then hud.LevelUp(tonumber(c:sub(7)) or 1)
    elseif c == "nolife" then
      sourcePos = nil
      panel.Open("Story", { career = {} })
    elseif c == "dayjoin" then
      local fresh = dayReader()
      gui:SetAttribute("DayToasts", (fresh() and 1 or 0) + (fresh() and 1 or 0) + (readDay() and 1 or 0))
    end
    gui:SetAttribute("CareerOut", panel.CareerLoading())
    gui:SetAttribute("PanelCommand", "")
  end)
end
UIS.InputBegan:Connect(function(input, gp)
  if gp then return end
  if (input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.ButtonB) and panel.IsOpen() then panel.Close() end
end)
RunService.Heartbeat:Connect(function()
  if panel.IsOpen() and sourcePos then
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root and (root.Position - sourcePos).Magnitude > Config.Interaction.PanelCloseDistance then panel.Close() end
  end
end)
-- console meters + speaker LEDs follow the server-owned Powered attribute
local studio = workspace:WaitForChild("OKStudio"); local CR = studio:WaitForChild("ControlRoom"); local console = CR:WaitForChild("Console")
local meters, leds = {}, {}
for _, d in ipairs(CR:GetChildren()) do if d.Name:match("^Meter_") then table.insert(meters, d) elseif d:GetAttribute("SpeakerLED") then table.insert(leds, d) end end
-- meters: on the beat while a beat plays (local preview or the monitors), idle wobble when only powered
local Bus = require(RS.OK.Modules.BeatBus)
local DAWCfg = require(RS.OK.Modules.DAWConfig)
local beatLevel = 0
Bus.Step:Connect(function(_, hitTracks, source)
  if hitTracks.Kick or hitTracks["808"] then beatLevel = 6
  elseif hitTracks.Snare or hitTracks.Clap then beatLevel = math.max(beatLevel, 5)
  elseif next(hitTracks) then beatLevel = math.max(beatLevel, 3) end
  if next(hitTracks) then console:SetAttribute("BeatSource", source) end -- client-local, read by tests
end)
local acc = 0
RunService.Heartbeat:Connect(function(dt)
  beatLevel = math.max(0, beatLevel - dt * 14)
  acc += dt; if acc < 0.03 then return end; acc = 0
  local beating = os.clock() - Bus.LastAt < 0.6
  local powered = console:GetAttribute("Powered") == true
  local t = os.clock()
  local top = 0
  for _, m in ipairs(meters) do
    local seg, ch = m:GetAttribute("Seg") or 1, m:GetAttribute("Channel") or 1
    local level
    if beating then
      level = math.clamp(math.floor(beatLevel - ((ch * 7) % 3) * 0.5 + 0.5), 0, 6)
    elseif powered then
      level = math.clamp(math.floor(3.5 + 2.4 * math.sin(t * (1.3 + ch * 0.41)) + math.random(0, 1)), 0, 6)
    else
      level = 0
    end
    if level > top then top = level end
    m.Transparency = (seg <= level) and 0 or 0.85
  end
  console:SetAttribute("MeterLevel", top) -- client-local, read by tests
  local lit = powered or beating
  for _, l in ipairs(leds) do l.Color = lit and Theme.ledOn or Theme.ledOff end
end)
-- neon pulses on the kick while a beat plays on the monitors (client-only colour, no lights added)
local pulseParts = {}
for _, path in ipairs({ { "Lounge", "Neon_Sign_Glow" }, { "Lounge", "TV_Glow" }, { "Lounge", "Bar_LED" }, { "ControlRoom", "Desk_LED" } }) do
  local room = studio:FindFirstChild(path[1]); local p = room and room:FindFirstChild(path[2])
  if p and p:IsA("BasePart") then table.insert(pulseParts, { part = p, base = p.Color }) end
end
local NowPlaying = RS.OK:WaitForChild("NowPlaying")
local pulse, pulsing = 0, false
Bus.Step:Connect(function(_, hitTracks, source)
  if source == "monitors" and (hitTracks.Kick or hitTracks["808"]) then
    if not pulsing then for _, e in ipairs(pulseParts) do e.base = e.part.Color end end -- current colours (light switch)
    pulse = 1
    studio:SetAttribute("NeonPulses", (studio:GetAttribute("NeonPulses") or 0) + 1) -- client-local, read by tests
  end
end)
RunService.Heartbeat:Connect(function(dt)
  if pulse <= 0 and not pulsing then return end
  pulse = math.max(0, pulse - dt * 6)
  pulsing = pulse > 0
  local flash = NowPlaying:GetAttribute("NeonColor") or Color3.new(1, 1, 1) -- the on-air producer's neon gear, if any
  for _, e in ipairs(pulseParts) do e.part.Color = e.base:Lerp(flash, pulse * (flash == Color3.new(1, 1, 1) and 0.55 or 0.85)) end
end)
-- the gear rack's LEDs show the gear YOU own (client-only colours, no lights): one LED row per paid item, bottom up
local rackLeds = {}
do
  local rows = {}
  for _, p in ipairs(CR:GetChildren()) do
    if p:IsA("BasePart") and (p.Name == "Rack_B_LED" or p.Name == "Rack_B_LED2") then table.insert(rows, p) end
  end
  table.sort(rows, function(a, b) if math.abs(a.Position.Y - b.Position.Y) > 0.05 then return a.Position.Y < b.Position.Y end; return a.Position.X < b.Position.X end)
  for i = 1, #rows, 2 do table.insert(rackLeds, { rows[i], rows[i + 1] }) end
end
local function paintRack()
  local Cfg = require(RS.OK.Config)
  local have = "," .. (player:GetAttribute("Gear") or "") .. ","
  local row, lit = 0, 0
  for _, it in ipairs(Cfg.Gear) do
    if it.price > 0 then
      row += 1
      local leds = rackLeds[row]
      local on = string.find(have, "," .. it.id .. ",", 1, true) ~= nil
      if on then lit += 1 end
      if leds then for _, l in ipairs(leds) do if l then l.Color = on and (it.color or Theme.ledOn) or Color3.fromRGB(40, 40, 46) end end end
    end
  end
  studio:SetAttribute("RackLit", lit) -- client-local, read by tests
end
player:GetAttributeChangedSignal("Gear"):Connect(paintRack)
paintRack()
