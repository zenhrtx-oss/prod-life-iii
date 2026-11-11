-- Client, during play: after a death with the beat maker open, the respawned player has a normal camera, prompts,
-- touch controls and no window or playback left over.
local Players, PPS, GuiService, CAS = game:GetService("Players"), game:GetService("ProximityPromptService"), game:GetService("GuiService"), game:GetService("ContextActionService")
local player = Players.LocalPlayer
local t0 = os.clock()
while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 and os.clock() - t0 > 1 then break end; task.wait(0.2) end
task.wait(1.0)
local hum = player.Character:FindFirstChildOfClass("Humanoid"); assert(hum and hum.Health > 0, "did not respawn")
local daw = player.PlayerGui.OK_DAW.DAW
assert(not daw.Visible, "window still open after respawn")
assert(daw:GetAttribute("Playing") == false and player:GetAttribute("DAWPlaying") == false, "playback survived death")
assert(workspace.CurrentCamera.CameraType == Enum.CameraType.Custom, "camera stuck in the seated view")
assert(PPS.Enabled == true and GuiService.TouchControlsEnabled == true, "prompts or touch controls not restored")
assert(next(CAS:GetBoundActionInfo("OK_DAW_PlayStop")) == nil, "play action still bound")
return "T10C PLAY OK: after death the window is gone, playback stopped, camera/prompts/touch controls restored"
