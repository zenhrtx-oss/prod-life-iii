-- Client, during play: checks the THROWAWAY room test's plumbing (not part of tools/test.py; the name doesn't start
-- with t). Runs the tour in fast mode: every room streams in whole and is visited, all 12 are loaded afterwards, the
-- card shows, the camera is the normal one again and the player is back at the hub. Studio's frame rates mean nothing.
local Players, Http = game:GetService("Players"), game:GetService("HttpService")
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("RoomTestUI", 15); assert(gui, "no RoomTestUI")
local run = gui:WaitForChild("Run", 5); assert(run, "no Run")
local t0 = os.clock()
local r = Http:JSONDecode(run:Invoke(true))
assert(not r.error, "tour stopped: " .. tostring(r.error))
assert(#r.rooms == 12, "rooms visited: " .. #r.rooms)
local loads = {}
for k, e in ipairs(r.rooms) do assert(e.load >= 0, "room " .. k .. " never loaded"); assert(e.fps and e.fps > 0, "room " .. k .. " no fps"); table.insert(loads, e.load) end
assert(r.loaded == 12, "loaded after pass 1: " .. tostring(r.loaded))
assert(r.again.room1 and r.again.hall and r.again.hub, "pass 2 incomplete")
assert(gui.Frame.Visible, "no card")
local cam = workspace.CurrentCamera
assert(cam.CameraType == Enum.CameraType.Custom, "camera left " .. tostring(cam.CameraType))
local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart"); assert(hrp, "no character")
local sp = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
assert(sp and (hrp.Position - sp.Position).Magnitude < 40, "not back at the hub")
gui.Frame.Visible = false
return ("ROOMTEST PLAY OK: 12 rooms streamed and visited in %.1f s; loads %s s; %d/12 loaded after; card shown; camera and player back; mem %d MB")
	:format(os.clock() - t0, table.concat(loads, " "), r.loaded, r.again.hub.mem)
