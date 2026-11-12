-- OK Studio server bootstrap (v1)
local RS = game:GetService("ReplicatedStorage")
local Services = script.Parent.Services
local Data = require(Services.DataService)
local Lighting = require(Services.LightingService)
local Interaction = require(Services.InteractionService)
Data.Init(); Lighting.Init()
local ctx = { Data = Data, Lighting = Lighting, Interaction = Interaction }
Interaction.Init(ctx)
local Monitors = require(Services.MonitorService)
Monitors.Init(ctx) -- sets ctx.Monitors before any system starts
-- every enabled system starts here; a failure is reported as [OK][ERR] (fails tools/test.py) and listed in
-- the Systems folder's SystemsFailed attribute
require(Services.SystemLoader).Run(RS.OK.Systems, ctx)
-- Studio-only test seam: lets edit/play tests reach the LIVE services (clients cannot see BindableFunctions).
if game:GetService("RunService"):IsStudio() then
  local hook = script.Parent:FindFirstChild("_StudioTestHook") or Instance.new("BindableFunction")
  hook.Name = "_StudioTestHook"; hook.Parent = script.Parent
  hook.OnInvoke = function(cmd, userId, a, b, c)
    local p = game:GetService("Players"):GetPlayerByUserId(userId)
    if not p then return nil end
    if cmd == "AddXP" then if b == nil then return Data.GrantXP(p, a, "Test") end; return Data.AddXP(p, a, b) end
    if cmd == "GrantCred" then return Data.GrantCred(p, a, "Test") end
    if cmd == "GetProfile" then return Data.GetProfile(p) end
    if cmd == "ResetTour" then require(RS.OK.Systems.Tour).Reset(p); return true end
    if cmd == "TourAdvance" then return require(RS.OK.Systems.Tour).Advance(p, a) end
    if cmd == "ResetSessions" then local prof = Data.GetProfile(p); prof.sessions = nil; prof.credits = {}; return true end
    if cmd == "GrantGear" then
      local Gear = require(RS.OK.Systems.Gear); local prof = Data.GetProfile(p); prof.gear = prof.gear or {}
      for id in string.gmatch(a or "", "[^,]+") do prof.gear[id] = true end
      Gear.Publish(p); return true
    end
    if cmd == "ResetGear" then
      local prof = Data.GetProfile(p); prof.gear = {}; prof.equip = {}; prof.gearV = 1
      require(RS.OK.Systems.Gear).Publish(p); return true
    end
    if cmd == "ResetDaily" then local prof = Data.GetProfile(p); prof.daily = { streak = a or 0, day = b, done = {} }; require(RS.OK.Systems.Dailies).Push(p); return true end
    if cmd == "ResetWeekly" then local prof = Data.GetProfile(p); prof.weekly = nil; prof.plaques = {}; p:SetAttribute("Plaques", 0); return true end
    if cmd == "ResetFunnel" then local prof = Data.GetProfile(p); prof.funnel = {}; p:SetAttribute("FunnelStep", 0); return true end
    if cmd == "FunnelStep" then return require(RS.OK.Systems.Funnel).Step(p, a) end
    if cmd == "FunnelLog" then
      local n = {}
      for _, e in ipairs(require(RS.OK.Systems.Funnel)._log) do if e.uid == p.UserId then n[e.step] = (n[e.step] or 0) + 1 end end
      return n
    end
    -- the player's custom events this session (Funnel._events, kept in Studio only), oldest first; a test that asserts
    -- telemetry calls ResetFunnelEvents first
    if cmd == "FunnelEvents" then
      local out = {}
      for _, e in ipairs(require(RS.OK.Systems.Funnel)._events) do
        if e.uid == p.UserId then table.insert(out, { name = e.name, value = e.value, fields = e.fields }) end
      end
      return out
    end
    if cmd == "ResetFunnelEvents" then
      local events = require(RS.OK.Systems.Funnel)._events
      for i = #events, 1, -1 do if events[i].uid == p.UserId then table.remove(events, i) end end
      return true
    end
    -- the XP gate's per-day count for source `a` cleared for today, so a Play run can pay that source again the same UTC
    -- day (Career Reset leaves prof.xpLog alone); another day's log is reset by the gate itself. When the source has a
    -- group, the group's whole sum for today is cleared too (every source in that group, not just `a`'s share). `a` must
    -- be a source name (a string): anything else returns false and clears nothing
    if cmd == "ResetXPCount" then
      if type(a) ~= "string" then return false end
      local log = Data.GetProfile(p).xpLog
      if type(log) == "table" and log.day == Data._day() then
        if type(log.count) == "table" then log.count[a] = nil end
        local rule = require(RS.OK.Config).XP.Sources[a]
        if rule and rule.group and type(log.group) == "table" then log.group[rule.group] = nil end
      end
      return true
    end
    if cmd == "SetActiveRequest" then local prof = Data.GetProfile(p); prof.sessions = prof.sessions or { done = {} }; prof.sessions.active = a; return true end
    -- the explainers seen (prof.hints, Wave 3): ResetHints empties it, or with `a` a list of terms marks those seen (day
    -- 0, "before day 1"), so a layout test can show a card with no hint line; Hints returns a copy { [term] = day }
    if cmd == "ResetHints" then
      local seen = {}
      if type(a) == "table" then for _, term in ipairs(a) do if type(term) == "string" then seen[term] = 0 end end end
      Data.GetProfile(p).hints = seen; Data.MarkDirty(p); return true
    end
    if cmd == "Hints" then local h = Data.GetProfile(p).hints; return type(h) == "table" and table.clone(h) or {} end
    -- a session that can't save (launch audit A7), with no store: a = { loadFailed = bool, persistent = bool } flags this
    -- player's profile _loadFailed and sets DataService.Persistent (a field left out stays as it is; Studio Play has no
    -- store, so nothing is written either way). Returns { was = both as they were, saving = DataService.Saving after },
    -- so a test can put them back
    if cmd == "SaveFlags" then
      local prof = Data.GetProfile(p)
      local was = { loadFailed = prof._loadFailed == true, persistent = Data.Persistent == true }
      if type(a) == "table" then
        if a.loadFailed ~= nil then prof._loadFailed = a.loadFailed == true or nil end
        if a.persistent ~= nil then Data.Persistent = a.persistent == true end
      end
      return { was = was, saving = Data.Saving(prof) }
    end
    -- your beat (Wave 3): prof.sessions.recent through Contracts, its one writer. RecordDelivery(pattern, bpm, stars) and
    -- CreditFire(pattern, bpm) as a passed delivery and a FIRE record them; Recent and BestBeat return copies; SetRecent(list)
    -- replaces the list (its whole beats, at most RecentMax) and returns what it kept
    if cmd == "RecordDelivery" then return require(RS.OK.Systems.Contracts).RecordDelivery(p, a, b, c) end
    if cmd == "CreditFire" then return require(RS.OK.Systems.Contracts).CreditFire(p, a, b) end
    if cmd == "Recent" then return require(RS.OK.Systems.Contracts).Recent(p) end
    if cmd == "SetRecent" then return require(RS.OK.Systems.Contracts).SetRecent(p, a) end
    if cmd == "BestBeat" then return require(RS.OK.Systems.Contracts).BestBeat(p) end
    return nil
  end
  -- cypher hooks: pretend producers join / submit / vote; Skip ends the current phase (or the entry on air); State
  -- (cooldown = seconds before a lobby may open again); ClearCooldown lets one open at once (launch audit A4)
  local cyHook = script.Parent:FindFirstChild("_StudioCypherHook") or Instance.new("BindableFunction")
  cyHook.Name = "_StudioCypherHook"; cyHook.Parent = script.Parent
  cyHook.OnInvoke = function(cmd, fakeId, a, b)
    local BB = require(RS.OK.Systems.BeatBattles)
    local fake = { UserId = fakeId, DisplayName = type(a) == "string" and a or "Fake" }
    if cmd == "Join" then return BB.Join(fake) end
    if cmd == "Submit" then return BB.Submit(fake, a, b, 0) end
    if cmd == "Vote" then return BB.Vote(fake, a) end
    if cmd == "Skip" then return BB._Skip() end
    if cmd == "State" then return BB._State() end
    if cmd == "ClearCooldown" then return BB._ClearCooldown() end
    return nil
  end
  -- monitor hooks take a fake owner id (negative) instead of a player, so queue tests need no second player.
  -- (launch audit A12) SpyJudge wraps Flips.Judge to count its calls by flip token, from zero; Judged(token) in the id's
  -- place gives that count; UnspyJudge puts the real one back. ClearFlipCheck(userId) lets that player's next send reach
  -- the flip check at once
  local judgeReal, judged = nil, {}
  local monHook = script.Parent:FindFirstChild("_StudioMonitorHook") or Instance.new("BindableFunction")
  monHook.Name = "_StudioMonitorHook"; monHook.Parent = script.Parent
  monHook.OnInvoke = function(cmd, fakeId, name, pattern, bpm)
    if cmd == "Enqueue" then return ctx.Monitors:Enqueue({ UserId = fakeId, DisplayName = name }, pattern, bpm, 0) end
    if cmd == "Cancel" then return ctx.Monitors:Cancel(fakeId) end
    if cmd == "State" then local st = ctx.Monitors:State(); return { current = st.current and st.current.name, upNext = st.upNext, count = st.count } end
    if cmd == "History" then return ctx.Monitors:History() end
    if cmd == "SpyJudge" then
      local Flips = require(RS.OK.Systems.Flips)
      if not judgeReal then
        judgeReal = Flips.Judge
        Flips.Judge = function(history, playerId, pattern, flipToken, unlocked)
          local k = flipToken or "none"
          judged[k] = (judged[k] or 0) + 1
          return judgeReal(history, playerId, pattern, flipToken, unlocked)
        end
      end
      judged = {}
      return true
    end
    if cmd == "Judged" then return judged[fakeId] or 0 end
    if cmd == "UnspyJudge" then
      if judgeReal then require(RS.OK.Systems.Flips).Judge = judgeReal; judgeReal = nil end
      return true
    end
    if cmd == "ClearFlipCheck" then
      local pl = game:GetService("Players"):GetPlayerByUserId(fakeId)
      return pl ~= nil and require(RS.OK.Systems.DAW)._ClearFlipCheck(pl)
    end
    -- a pretend listener (fakeId) gives FIRE to whoever is on air now: tests the producer's side with one player
    -- a pretend producer (name) flips whoever is on air now: tests the original producer's side with one player
    if cmd == "FlipAs" then return require(RS.OK.Systems.Flips).Credit(RS.OK.NowPlaying:GetAttribute("OwnerId"), name) end
    if cmd == "FireAs" then
      local NP = RS.OK.NowPlaying
      return { require(RS.OK.Systems.Reactions).Give(fakeId, nil, NP:GetAttribute("OwnerId"), NP:GetAttribute("Token")) }
    end
    return nil
  end
end
workspace.OKStudio:SetAttribute("ServerReady", true)
print("[OK] studio server ready")
