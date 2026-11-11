-- Client, during play (after t26c): the card counts the flip; stop the airing and close.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local NP = RS.OK.NowPlaying
local daw = player.PlayerGui.OK_DAW.DAW
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local c = RS.OK.Remotes.Card_Get:InvokeServer(player.UserId)
assert(c.ok and c.card.flips == player:GetAttribute("Flips") and c.card.flips >= 1, "card flips " .. tostring(c.card and c.card.flips))
RS.OK.Remotes.DAW_Stop:FireServer()
assert(waitFor(function() return NP:GetAttribute("Active") == false end, 3), "could not stop")
daw:SetAttribute("Command", "close"); task.wait(0.4); workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
return "T26D PLAY OK: card shows " .. c.card.flips .. " flip(s)"
