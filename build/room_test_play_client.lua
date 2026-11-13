-- Client, during play: checks the THROWAWAY room test's plumbing (not part of tools/test.py; the name doesn't start with
-- t). Run it with build/room_test.lua built (and removed after: every rooms Play test needs a plot of its own). Runs the
-- tour in fast mode: every plot streams in whole and each of its rooms is visited and measured, all 12 are loaded
-- afterwards, the card shows, the camera is the normal one again and the player is back at the hub. And Systems/Rooms
-- held (its throwaway-test seam): this player has no slot and Workspace.OK_Plots holds no plot. Studio's frame rates
-- mean nothing.
local Players, Http = game:GetService("Players"), game:GetService("HttpService")
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("RoomTestUI", 15); assert(gui, "no RoomTestUI")
local run = gui:WaitForChild("Run", 5); assert(run, "no Run")
-- Systems/Rooms' seam: no slot claimed and no plot built while Workspace.RoomTest stands
assert((player:GetAttribute("PlotSlot") or 0) == 0, "Systems/Rooms claimed slot " .. tostring(player:GetAttribute("PlotSlot")) .. " while RoomTest stands")
local live = workspace:FindFirstChild("OK_Plots")
assert(not live or #live:GetChildren() == 0, "Systems/Rooms built " .. (live and #live:GetChildren() or 0) .. " plot(s) while RoomTest stands")
local t0 = os.clock()
local r = Http:JSONDecode(run:Invoke(true))
assert(not r.error, "tour stopped: " .. tostring(r.error))
assert(#r.plots == 12, "plots visited: " .. #r.plots)
assert(type(r.kinds) == "table" and #r.kinds >= 1, "no room kinds on the result")
local loads = {}
for k, e in ipairs(r.plots) do
  assert(e.load >= 0, "plot " .. k .. " never loaded")
  for _, kind in ipairs(r.kinds) do
    local m = e.rooms and e.rooms[kind]
    assert(m and m.fps and m.fps > 0, "plot " .. k .. "'s " .. kind .. " has no fps")
  end
  table.insert(loads, e.load)
end
assert(r.loaded == 12, "loaded after pass 1: " .. tostring(r.loaded))
assert(r.again.plot1 and r.again.hub, "pass 2 incomplete")
assert(gui.Frame.Visible, "no card")
local cam = workspace.CurrentCamera
assert(cam.CameraType == Enum.CameraType.Custom, "camera left " .. tostring(cam.CameraType))
local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); assert(hrp, "no character")
local sp = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
assert(sp and (hrp.Position - sp.Position).Magnitude < 40, "not back at the hub")
gui.Frame.Visible = false
return ("ROOMTEST PLAY OK: 12 plots (%s) streamed and visited in %.1f s; loads %s s; %d/12 loaded after; card shown; camera and player back; no live plot or slot; mem %d MB")
  :format(table.concat(r.kinds, ", "), os.clock() - t0, table.concat(loads, " "), r.loaded, r.again.hub.mem)
