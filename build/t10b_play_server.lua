-- Server, during play: kill the test player's character while the beat maker is open (t10c checks the restore).
local p = game:GetService("Players"):GetPlayers()[1]
assert(p and p.Character and p.Character:FindFirstChildOfClass("Humanoid"), "no character")
p.Character:FindFirstChildOfClass("Humanoid").Health = 0
return "T10B OK: killed " .. p.Name
