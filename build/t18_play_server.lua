-- Server, during play: every enabled system started (none failed) and the reward gate is live.
local RS = game:GetService("ReplicatedStorage")
local Sys = RS.OK.Systems
local failed, started = Sys:GetAttribute("SystemsFailed"), Sys:GetAttribute("SystemsStarted") or ""
assert(failed == "", "systems failed: " .. tostring(failed))
for _, name in ipairs({ "DAW", "Tour" }) do
  assert(("," .. started .. ","):find("," .. name .. ",", 1, true) and Sys[name]:GetAttribute("InitOK") == true, name .. " did not start")
end
local p = game:GetService("Players"):GetPlayers()[1]; assert(p, "no player")
assert(type(p:GetAttribute("Cred")) == "number", "Cred attribute missing")
return "T18 PLAY OK: systems started (" .. started .. "), none failed; Cred attribute live"
