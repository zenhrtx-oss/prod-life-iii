-- Edit: Wave 3 Task 5c-3, hub-scoped counts. An imported room (a Model with an OK_Room attribute, such as the bedroom) holds
-- one warm bulb and one beat-maker Station of its own. The place checks count only the hub: t03, t04, t05 and 09_qa hold
-- its lights to 61, t07 and 09_qa its interactables to 12, 14_stations its Stations to 2; a room is held to its own one
-- light (Modules/RoomScope). This builds a temporary room under Workspace and reads the counts as those checks take them:
-- (0) control: the old unscoped counts (every Light, every tagged interactable, every Station in Workspace) do see the
--     room, so the fixture can fail the old logic; (1) the hub's three counts do not move; (2) the room is counted as a
--     room (its light, its Station and its tagged part, found by RoomOf and in Split's rooms), one bulb within budget;
-- (3) a 2nd light in the room, under a Folder and a Part, puts it over its budget, and the line names the room by full name
--     and OK_Room value; the hub is unmoved, and with the light gone the room is within budget again; (4) a light outside
--     any room still counts against the hub (+1; at 61 it would be 62, over the cap, which the checks' <= 61 refuses).
-- Counts are read against a baseline taken first, so this passes on today's place (no rooms) and on one with rooms in it.
-- Without Modules/RoomScope in the place (before the 5c-3 sync) the require below fails: the expected red. Its own red,
-- the old counting logic: swap that one require line for a stub that counts every Light and every tagged part in
-- Workspace (Split returns every item as the hub's), and (1) fails with "hub lights ... moved". The cleanup runs in a
-- pcall and the error is rethrown after it; a leftover fixture from a dropped connection is swept first.
local RS, CS = game:GetService("ReplicatedStorage"), game:GetService("CollectionService")
local function freshRequire(mod) -- edit-mode require caches modules across runs; load a clone so edits take effect
  local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name
  local ok, res = pcall(require, c); c:Destroy(); if not ok then error(res) end; return res
end
local RoomScope = freshRequire(RS.OK.Modules.RoomScope)
local TAG, ROOM_NAME, STRAY_NAME, ROOM_KIND = "OK_Interactable", "OK_T88_TempRoom", "OK_T88_StrayLight", "test_room"
local CAP = 61 -- the hub's light cap, as t03, t04, t05 and 09_qa hold it

-- the counts as the six checks take them: raw (old) and the hub's (new), with the rooms they leave out
local function snapshot()
  local s = {}
  s.rawLights = 0
  for i, d in ipairs(workspace:GetDescendants()) do
    if d:IsA("Light") then s.rawLights += 1 end
    if i % 4000 == 0 then task.wait() end -- a long scan never goes unyielded (the same walk t03 makes in one go)
  end
  local tagged = {}
  for _, t in ipairs(CS:GetTagged(TAG)) do if t:IsDescendantOf(workspace) then table.insert(tagged, t) end end
  local stations = {}
  for _, t in ipairs(tagged) do if t:GetAttribute("Kind") == "Station" then table.insert(stations, t) end end
  s.rawTagged, s.rawStations = #tagged, #stations
  local hubTagged, hubStations
  s.hubLights, s.lightRooms, s.over = RoomScope.Lights(workspace) -- t03, t04, t05, 09_qa
  hubTagged, s.taggedRooms = RoomScope.Split(tagged) -- t07, 09_qa
  hubStations, s.stationRooms = RoomScope.Split(stations) -- 14_stations
  s.hubTagged, s.hubStations = #hubTagged, #hubStations
  return s
end
local function entryFor(rooms, room)
  for _, e in ipairs(rooms) do if e.room == room then return e end end
  return nil
end
local function newPart(name, parent) local p = Instance.new("Part"); p.Name = name; p.Anchored = true; p.Parent = parent; return p end
local function newLight(parent) local l = Instance.new("PointLight"); l.Name = "Bulb"; l.Brightness = 0.25; l.Range = 14; l.Parent = parent; return l end
local function sweep() -- remove this test's fixtures; true when it found any
  local found = false
  for _, c in ipairs(workspace:GetChildren()) do
    if c.Name == ROOM_NAME or c.Name == STRAY_NAME then found = true; c:Destroy() end
  end
  return found
end

local swept = sweep()
local base = snapshot()
assert(base.over == nil, "precondition: a room in the place already holds more lights than its budget: " .. tostring(base.over))
task.wait()

local result
local ok, err = pcall(function()
  -- the temporary room: one bulb on a part, one Station (a tagged, prompted part), shaped like the bedroom's
  local room = Instance.new("Model"); room.Name = ROOM_NAME; room.Archivable = false
  room:SetAttribute("OK_Room", ROOM_KIND)
  local bulb = newLight(newPart("bd_room__bd_bulb", room))
  local screen = newPart("Screen", room)
  screen:SetAttribute("Kind", "Station"); screen:SetAttribute("StationName", "TEST ROOM")
  CS:AddTag(screen, TAG)
  Instance.new("ProximityPrompt").Parent = screen
  room.Parent = workspace
  local s1 = snapshot()
  task.wait()

  -- (0) control: the old unscoped counts see the room (else this fixture proves nothing)
  assert(s1.rawLights == base.rawLights + 1 and s1.rawTagged == base.rawTagged + 1 and s1.rawStations == base.rawStations + 1,
    string.format("control: the unscoped counts should each see the temp room (lights %d -> %d, tagged %d -> %d, stations %d -> %d)",
      base.rawLights, s1.rawLights, base.rawTagged, s1.rawTagged, base.rawStations, s1.rawStations))
  -- (1) the hub's counts do not move
  assert(s1.hubLights == base.hubLights, string.format("hub lights moved %d -> %d with a room in the place: a room's bulb must not count against the hub's %d", base.hubLights, s1.hubLights, CAP))
  assert(s1.hubTagged == base.hubTagged, string.format("hub interactables moved %d -> %d with a room in the place: a room's laptop must not count", base.hubTagged, s1.hubTagged))
  assert(s1.hubStations == base.hubStations, string.format("hub stations moved %d -> %d with a room in the place: a room's laptop must not count", base.hubStations, s1.hubStations))
  -- (2) the room is counted as a room
  assert(RoomScope.RoomOf(bulb) == room, "the bulb should be inside the temp room")
  assert(RoomScope.RoomOf(screen) == room, "the Station should be inside the temp room")
  assert(RoomScope.RoomOf(room) == nil, "a room directly under Workspace is not inside another room")
  assert(#s1.lightRooms == #base.lightRooms + 1, "the temp room should be one more room holding lights: " .. #base.lightRooms .. " -> " .. #s1.lightRooms)
  local lightEntry = entryFor(s1.lightRooms, room)
  assert(lightEntry and #lightEntry.items == 1 and lightEntry.items[1] == bulb, "the room's one light should be tallied to the room")
  local stationEntry, taggedEntry = entryFor(s1.stationRooms, room), entryFor(s1.taggedRooms, room)
  assert(stationEntry and #stationEntry.items == 1 and stationEntry.items[1] == screen, "the room's Station should be tallied to the room")
  assert(taggedEntry and #taggedEntry.items == 1 and taggedEntry.items[1] == screen, "the room's tagged part should be tallied to the room")
  assert(s1.over == nil, "one bulb is within the room's budget: " .. tostring(s1.over))

  -- (3) a 2nd light in the room, deeper in it (Folder > Part > light): over its budget, named
  local props = Instance.new("Folder"); props.Name = "Props"; props.Parent = room
  local lamp = newLight(newPart("Lamp", props))
  local s2 = snapshot()
  task.wait()
  assert(RoomScope.RoomOf(lamp) == room, "a light under a Folder and a Part of the room should be inside the room")
  assert(s2.over ~= nil, "a 2nd light in the room should be over its budget of " .. RoomScope.MaxLightsPerRoom)
  assert(s2.over:find(room:GetFullName(), 1, true), "the over-budget line should name the room by full name: " .. s2.over)
  assert(s2.over:find(ROOM_KIND, 1, true), "the over-budget line should carry the room's OK_Room value: " .. s2.over)
  assert(s2.hubLights == base.hubLights, string.format("hub lights moved %d -> %d with a 2nd light in the room", base.hubLights, s2.hubLights))
  local entry2 = entryFor(s2.lightRooms, room)
  assert(entry2 and #entry2.items == 2, "the room should hold 2 lights")
  props:Destroy()
  local s2b = snapshot()
  task.wait()
  assert(s2b.over == nil, "with the 2nd light gone the room should be within budget: " .. tostring(s2b.over))

  -- (4) a light outside any room still counts against the hub
  local strayPart = newPart(STRAY_NAME, workspace)
  strayPart.Archivable = false -- like the room fixture: a dropped connection can't leave a 62nd hub light in a save
  local stray = newLight(strayPart)
  local s3 = snapshot()
  assert(RoomScope.RoomOf(stray) == nil, "a light directly under Workspace is in no room")
  assert(s3.hubLights == base.hubLights + 1, string.format("a light outside any room should count against the hub: %d -> %d, want +1", base.hubLights, s3.hubLights))
  if base.hubLights == CAP then assert(not (s3.hubLights <= CAP), "at the hub's cap, a hub light should trip the checks' <= " .. CAP) end
  assert(s3.over == nil, "a hub light is no room's budget: " .. tostring(s3.over))
  assert(s3.hubTagged == base.hubTagged and s3.hubStations == base.hubStations, "a hub light should not move the interactable counts")
  result = { s1 = s1, s3 = s3 }
end)
sweep() -- the fixtures go whether the body passed or not
if not ok then error(err, 0) end
task.wait()
local after = snapshot()
assert(workspace:FindFirstChild(ROOM_NAME) == nil and workspace:FindFirstChild(STRAY_NAME) == nil, "the temp room was not removed")
assert(after.rawLights == base.rawLights and after.rawTagged == base.rawTagged and after.rawStations == base.rawStations
  and after.hubLights == base.hubLights and after.hubTagged == base.hubTagged and after.hubStations == base.hubStations,
  "the counts did not return to the baseline after the cleanup")

return string.format("T88 OK: a temp room (OK_Room = %s, 1 bulb, 1 Station) leaves the hub's counts alone: lights %d, interactables %d, stations %d"
  .. " (the old unscoped counts read %d, %d, %d); counted as a room; a 2nd light named over its %d, then back within budget;"
  .. " a hub light moves the hub %d -> %d (cap %d); cleaned up, counts back at baseline%s",
  ROOM_KIND, base.hubLights, base.hubTagged, base.hubStations, result.s1.rawLights, result.s1.rawTagged, result.s1.rawStations,
  RoomScope.MaxLightsPerRoom, base.hubLights, result.s3.hubLights, CAP, swept and " (swept a leftover fixture first)" or "")
