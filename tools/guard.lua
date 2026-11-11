local ok1 = workspace:FindFirstChild("OKStudio") ~= nil
local ok2 = game:GetService("ServerStorage"):FindFirstChild("OK_Backup_2026-10-22") ~= nil
local ok3 = game:GetService("ReplicatedStorage"):FindFirstChild("OK") ~= nil
local trial = ok3 and game:GetService("ReplicatedStorage").OK:GetAttribute("RealSaveTrial") or nil
-- the real-save trial (tools/real_save_on.lua) points Play at a real store: no test run or sync until it is off
if trial ~= nil then return "GUARD FAIL real-save trial is on (RealSaveTrial = " .. tostring(trial) .. "): run tools/real_save_off.lua first" end
return (ok1 and ok2 and ok3) and ("GUARD OK PlaceId=" .. game.PlaceId .. " streaming=" .. tostring(workspace.StreamingEnabled)) or ("GUARD FAIL studio=" .. tostring(ok1) .. " backup=" .. tostring(ok2) .. " rs=" .. tostring(ok3))
