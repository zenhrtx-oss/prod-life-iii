-- Edit: the Your Rooms plan, Task 15 (the 12-plot phone test with the real bedroom, spec §4.13): one full plot, held to
-- the room budgets. Modules/RoomBuild.Plot with { full = true } (every room unlocked and furnished: RoomRules.FullHome's
-- things at each room's limit, every poster and plaque spot filled, a closet's hangers, tier-3 desk speakers), from the
-- real bedroom template (ServerStorage.<Config.Rooms.Template>, else Workspace's, as Systems/Rooms' Init finds it: the
-- user's Env_bedroom_starter import with its Bedroom_Setup; cloned, never moved), built under a temporary Model in
-- Workspace at a far origin (a copy of Config.Rooms whose PlotOrigin is FAR: away from the 12 slot origins, the room
-- test's plots and the hub).
-- (1) the plot is a full one: FullPlot set; every kind's room built, the bedroom the real asset (MeshParts, no StandIn);
--     each room's Items at its limit with every poster spot hung, one closet with hangers where the closet may stand; a
--     plaque on every Plaque_<n>; a tier-3 RoomSpeaker_L and _R.
-- (2) the budgets: each room <= 1 light (RoomScope.MaxLightsPerRoom), none on the landing (walked on its own: it is an
--     OK_Room, so RoomScope counts a light there as a room's) and none in the plot outside a room; the bedroom
--     shell <= 56 MeshParts; each room's Items <= limit x Config.Rooms.ItemParts parts, and every one item <= ItemParts.
-- (3) the hub's counts don't move with the plot in Workspace (Modules/RoomScope, as t03 / t04 / t05 / t07 / 09_qa /
--     14_stations take them): lights <= 61 and the same as before it, exactly 12 tagged interactables and 2 Stations.
-- (4) it prints the plot's parts in all and by kind of part, room by room, and its triangles as far as Luau can read them.
--     A MeshPart has no triangle count a script can read, so for the meshes it prints what is readable (how many MeshParts
--     and distinct meshes) beside the bedroom asset manifest's own figure (MANIFEST_TRIS: the manifest's, not measured
--     here); for the code-built parts it counts blocks (12 triangles each) and wedges (8) and says that cylinders and balls
--     (engine meshes) aren't readable either.
-- The temporary Model is removed in a pcall cleanup and any error rethrown after it; a leftover from a dropped run is swept
-- first. Long walks task.wait() every 4,000 items. Marker "T114 OK".
-- The expected red, before the Task 15 sync of Modules/RoomBuild (and Modules/RoomRules): "RoomBuild.Plot has no full-plot
-- path: ..." (Plot ignores opts, so the plot comes back with no FullPlot, no rooms and no things).
local RS, SS, CS = game:GetService("ReplicatedStorage"), game:GetService("ServerStorage"), game:GetService("CollectionService")
local function freshRequire(mod) -- edit-mode require caches modules across runs; load a clone so edits take effect
  local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name
  local ok, res = pcall(require, c); c:Destroy(); if not ok then error(res) end; return res
end
local TAG, CAP, TEMP = "OK_Interactable", 61, "OK_T114_TempPlot"
local FAR = { -6000, 0, 6000 } -- the temporary plot's origin: 8,000+ studs from the hub, 6,000+ from every slot origin
local MESH_BUDGET = 56 -- the asset contract's MeshParts a room
local MANIFEST_TRIS = 19566 -- the bedroom's meshes by its asset manifest (ok_assets environments/bedroom_starter/README.md)
local out = {}
local function str(v) return typeof(v) == "Vector3" and string.format("(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z) or tostring(v) end
local function eq(what, got, want) assert(got == want, what .. ": want " .. tostring(want) .. ", got " .. tostring(got)) end

local Config = freshRequire(RS.OK.Config)
local live = Config.Rooms
local RoomBuild = freshRequire(RS.OK.Modules.RoomBuild)
local RoomRules = freshRequire(RS.OK.Modules.RoomRules)
local RoomScope = freshRequire(RS.OK.Modules.RoomScope)
local Catalog = require(RS.OK.Data.RoomCatalog) -- data only

-- every descendant of root through fn, yielding every 4,000
local function walk(root, fn)
  for i, d in ipairs(root:GetDescendants()) do
    fn(d)
    if i % 4000 == 0 then task.wait() end
  end
end
-- the hub's counts, as the place checks take them
local function hubCounts()
  task.wait()
  local lights, _, over = RoomScope.Lights(workspace) -- one walk, as t03 / 09_qa take it
  task.wait()
  local tagged, stations = {}, {}
  for _, t in ipairs(CS:GetTagged(TAG)) do
    if t:IsDescendantOf(workspace) then
      table.insert(tagged, t)
      if t:GetAttribute("Kind") == "Station" then table.insert(stations, t) end
    end
  end
  return { lights = lights, over = over, tagged = #RoomScope.Split(tagged), stations = #RoomScope.Split(stations) }
end
local function sweep()
  local found = false
  for _, c in ipairs(workspace:GetChildren()) do
    if c.Name == TEMP then c:Destroy(); found = true end
  end
  return found
end

-- the bedroom template: Task 15's precondition (the user's import), found as Systems/Rooms' Init finds it
local template = SS:FindFirstChild(live.Template) or workspace:FindFirstChild(live.Template)
assert(template and template:IsA("Model"), "no bedroom template (ServerStorage or Workspace ." .. live.Template
  .. "): the user's bedroom import is Task 15's precondition")
assert(template:FindFirstChild("Bedroom_Setup"), live.Template .. " has no Bedroom_Setup: the bedroom pipeline's setup hasn't run on it")

-- a copy of Config.Rooms whose plots start at FAR; the full path must read only the cfg it is given
local cfg = table.clone(live)
cfg.PlotOrigin = FAR
local farV = Vector3.new(FAR[1], FAR[2], FAR[3])
assert(farV.Magnitude > 1500, "FAR is within 1,500 studs of the hub")
for k = 1, live.Slots do
  local x, y, z = RoomRules.PlotOrigin(k, live)
  assert((farV - Vector3.new(x, y, z)).Magnitude > 1500, "FAR is within 1,500 studs of slot " .. k .. "'s origin")
end

local swept = sweep()
local base = hubCounts()
local temp = Instance.new("Model")
temp.Name = TEMP
local ok, err = pcall(function()
  local plot = RoomBuild.Plot(1, nil, cfg, template, nil, { full = true })
  plot.Parent = temp
  assert(plot:GetAttribute("FullPlot") == true, "RoomBuild.Plot has no full-plot path: Plot(1, nil, cfg, template, nil, "
    .. "{ full = true }) came back without FullPlot (opts ignored), so no room is unlocked or furnished: sync Modules/RoomBuild and Modules/RoomRules")
  local piv = plot:GetPivot().Position
  assert((piv - farV).Magnitude < 0.01, "the plot stands at " .. str(piv) .. ", want FAR " .. str(farV) .. " (Plot read another cfg)")
  temp.Parent = workspace

  -- (1) and (2), room by room ----------------------------------------------------------------------------------------
  local kinds = RoomBuild.KindOrder(cfg)
  local closetRooms = {}
  for _, kind in ipairs((Catalog.ById.closet or {}).rooms or {}) do closetRooms[kind] = true end
  local roomLines = {}
  for _, kind in ipairs(kinds) do
    local kc = cfg.Kinds[kind]
    local room = plot:FindFirstChild(RoomBuild.RoomName(kind))
    assert(room and room:IsA("Model"), "the full plot has no " .. RoomBuild.RoomName(kind) .. ": every room is unlocked in a full plot")
    local lights, meshes, parts, meshIds, nIds = 0, 0, 0, {}, 0
    walk(room, function(d)
      if d:IsA("Light") then lights += 1 end
      if d:IsA("BasePart") then parts += 1 end
      if d:IsA("MeshPart") then
        meshes += 1
        if not meshIds[d.MeshId] then meshIds[d.MeshId] = true; nIds += 1 end
      end
    end)
    assert(lights <= RoomScope.MaxLightsPerRoom, kind .. " holds " .. lights .. " lights, over its " .. RoomScope.MaxLightsPerRoom)
    if kind == "bedroom" then
      assert(room:GetAttribute("StandIn") ~= true and meshes > 0, "the bedroom is RoomBuild's stand-in (" .. meshes
        .. " MeshParts), not a clone of " .. live.Template)
      assert(meshes <= MESH_BUDGET, "the bedroom shell holds " .. meshes .. " MeshParts, over " .. MESH_BUDGET)
    end
    -- the things: at the limit, every poster spot hung, each one within ItemParts, all within limit x ItemParts
    local items = room:FindFirstChild("Items")
    assert(items and items:IsA("Folder") and items:GetAttribute("RoomItemsFolder") == true, kind .. " has no Items folder (RoomEdit.Fit's)")
    local n, posters, itemParts, closets, hangers = 0, 0, 0, 0, 0
    for _, m in ipairs(items:GetChildren()) do
      local id = m:IsA("Model") and m:GetAttribute("ItemId") or nil
      if id then
        n += 1
        if id == "poster" then posters += 1 end
        local mp = 0
        for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then mp += 1 end end
        assert(mp <= cfg.ItemParts, kind .. ": " .. m.Name .. " (" .. tostring(id) .. ") is " .. mp .. " parts, over ItemParts " .. cfg.ItemParts)
        itemParts += mp
        if id == "closet" then
          closets += 1
          local h = m:FindFirstChild("Hangers")
          hangers += h and #h:GetChildren() or 0
        end
      end
    end
    eq(kind .. ": things in Items (the room's limit)", n, kc.limit)
    eq(kind .. ": posters hung (every wall spot)", posters, kc.posters or 0)
    assert(itemParts <= kc.limit * cfg.ItemParts, string.format("%s: Items holds %d parts, over its %d x %d = %d", kind, itemParts,
      kc.limit, cfg.ItemParts, kc.limit * cfg.ItemParts))
    eq(kind .. ": closets", closets, closetRooms[kind] and 1 or 0)
    if closets > 0 then assert(hangers >= 1, kind .. ": the closet has no hangers") end
    -- the walls: a plaque on every Plaque_<n>
    local pf = room:FindFirstChild("Plaques")
    assert(pf and pf:IsA("Folder") and pf:GetAttribute("RoomPlaques") == true, kind .. " has no Plaques folder")
    eq(kind .. ": plaques hung (every Plaque_<n>)", #pf:GetChildren(), kc.plaques or 0)
    for slot = 1, kc.plaques or 0 do
      local m = pf:FindFirstChild("RoomPlaque_" .. slot)
      local a = room:FindFirstChild("Plaque_" .. slot, true)
      assert(m and a and (m:GetPivot().Position - a.WorldPosition).Magnitude < 0.01, kind .. ": RoomPlaque_" .. slot .. " is not on its Plaque_" .. slot .. " anchor")
    end
    -- the desk: a tier-3 pair
    for _, side in ipairs({ "L", "R" }) do
      local sp = room:FindFirstChild("RoomSpeaker_" .. side)
      assert(sp and sp:GetAttribute("Tier") == RoomBuild.FULL_TIER, kind .. ": no tier-" .. RoomBuild.FULL_TIER .. " RoomSpeaker_" .. side)
    end
    table.insert(roomLines, string.format("%s: %d parts (%d MeshParts, %d distinct meshes), %d light; Items %d things (%d posters), %d parts of %d; %d plaques; tier-%d speakers%s",
      kind, parts, meshes, nIds, lights, n, posters, itemParts, kc.limit * cfg.ItemParts, kc.plaques or 0, RoomBuild.FULL_TIER,
      closets > 0 and string.format("; a closet with %d hangers", hangers) or ""))
  end
  local landing = plot:FindFirstChild("Landing")
  assert(landing and landing:IsA("Model"), "the full plot has no Landing")
  local landingLights = 0
  walk(landing, function(d) if d:IsA("Light") then landingLights += 1 end end)
  eq("lights on the landing (it adds none)", landingLights, 0)
  local plotHubLights, _, plotOver = RoomScope.Lights(temp)
  eq("lights in the plot outside every room (the landing included: 0)", plotHubLights, 0)
  assert(plotOver == nil, plotOver)
  table.insert(out, "a full plot at " .. str(farV) .. " from " .. live.Template .. " (" .. table.concat(kinds, ", ") .. ")")
  for _, l in ipairs(roomLines) do table.insert(out, "  " .. l) end

  -- (3) the hub ------------------------------------------------------------------------------------------------------
  local after = hubCounts()
  assert(after.over == nil, after.over)
  assert(after.lights <= CAP, "the hub holds " .. after.lights .. " lights, over its " .. CAP)
  eq("hub lights with the plot in Workspace (before it: " .. base.lights .. ")", after.lights, base.lights)
  eq("hub tagged interactables", after.tagged, 12)
  eq("hub Stations", after.stations, 2)
  eq("hub tagged interactables before the plot", base.tagged, 12)
  eq("hub Stations before the plot", base.stations, 2)
  table.insert(out, string.format("hub with the plot in Workspace: %d lights (cap %d, unmoved), %d interactables, %d stations", after.lights, CAP, after.tagged, after.stations))

  -- (4) the plot's parts and triangles ---------------------------------------------------------------------------------
  local total, meshes, blocks, wedges, cyl, balls, other, lightsN, guis, meshIds, nIds = 0, 0, 0, 0, 0, 0, 0, 0, 0, {}, 0
  walk(plot, function(d)
    if d:IsA("Light") then lightsN += 1 end
    if d:IsA("SurfaceGui") then guis += 1 end
    if not d:IsA("BasePart") then return end
    total += 1
    if d:IsA("MeshPart") then
      meshes += 1
      if not meshIds[d.MeshId] then meshIds[d.MeshId] = true; nIds += 1 end
    elseif d:IsA("WedgePart") then wedges += 1
    elseif d:IsA("Part") then
      if d.Shape == Enum.PartType.Block then blocks += 1
      elseif d.Shape == Enum.PartType.Cylinder then cyl += 1
      elseif d.Shape == Enum.PartType.Ball then balls += 1
      elseif d.Shape == Enum.PartType.Wedge then wedges += 1
      else other += 1 end
    else other += 1 end
  end)
  table.insert(out, string.format("plot total: %d parts (%d MeshParts, %d blocks, %d wedges, %d cylinders, %d balls, %d other), %d lights, %d SurfaceGuis",
    total, meshes, blocks, wedges, cyl, balls, other, lightsN, guis))
  table.insert(out, string.format("triangles: a MeshPart has no triangle count Luau can read. Readable: %d MeshParts over %d distinct meshes "
    .. "(the bedroom asset's manifest gives %d triangles for them: the manifest's figure, not measured here); the code-built "
    .. "blocks and wedges are 12 and 8 each, %d in all; the %d cylinders and %d balls are engine meshes, not readable either",
    meshes, nIds, MANIFEST_TRIS, blocks * 12 + wedges * 8, cyl, balls))
end)
local okClean, cleanErr = pcall(function() temp:Destroy(); sweep() end)
if not ok then error(err, 0) end
assert(okClean, "cleanup: " .. tostring(cleanErr))
assert(workspace:FindFirstChild(TEMP) == nil, "the temporary plot is still in Workspace after the cleanup")
if swept then table.insert(out, "(swept a leftover " .. TEMP .. " from a dropped run first)") end

return "T114 OK\n" .. table.concat(out, "\n")
