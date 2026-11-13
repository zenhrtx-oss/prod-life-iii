-- Removes the THROWAWAY room test (build/room_test.lua): everything tagged OK_Build = "room_test" (Workspace.RoomTest and
-- its 12 plots, the remotes, the two scripts) and nothing else. With Workspace.RoomTest gone, Systems/Rooms claims, builds
-- and moves again (its throwaway-test seam). The place's streaming settings and every model's ModelStreamingMode stay as
-- they are: since build/19_rooms.lua they are the live game's own, and this never writes them. A stale
-- ServerStorage.RoomTest_Orig (the 11-04 version's record of the settings before it turned streaming on) is deleted
-- without being applied: putting it back would turn the live game's streaming off.
local RS, SS = game:GetService("ReplicatedStorage"), game:GetService("ServerStorage")
local L = require(RS.OK.BuildLib)
local n = L.clear("room_test")
local stale = SS:FindFirstChild("RoomTest_Orig")
if stale then stale:Destroy() end
local left = workspace:FindFirstChild("RoomTest")
return ("ROOM TEST REMOVED: %d instances%s; streaming untouched (%s, min %d, target %d, %s)%s")
	:format(n, stale and "; a stale ServerStorage.RoomTest_Orig (11-04) deleted, NOT applied" or "",
		tostring(workspace.StreamingEnabled), workspace.StreamingMinRadius, workspace.StreamingTargetRadius, tostring(workspace.StreamOutBehavior),
		left and "; WARNING: a Workspace.RoomTest without the room_test tag is still there, so Systems/Rooms still holds" or "")
