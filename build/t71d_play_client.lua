-- Client, during play (Wave 2 Task 4; A2; after t71c): the real tier banner, then the real LEVEL UP: BannerLog ends with
-- the BUZZING banner's text and then LEVEL n (the queue never replaced one with the other), and LastLevelUp is n. At the top
-- level, only the banner. The queue then drains.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui", 10)
local ui = pg:WaitForChild("OK_UI", 10); assert(ui, "no OK_UI")
local banner = pg:WaitForChild("OK_LevelUp", 10):WaitForChild("LevelUp", 5); assert(banner, "no OK_LevelUp.LevelUp")
local LifeRules = require(RS.OK.Modules.LifeRules)
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function log() return string.split(ui:GetAttribute("BannerLog") or "", "|") end
local tier = LifeRules.Copy.Banners.BUZZING
assert(waitFor(function() return player:GetAttribute("_T71Level") ~= nil end, 3), "t71c left no _T71Level")
local level = player:GetAttribute("_T71Level")
local function done()
	local e = log()
	if level == 0 then return e[#e] == tier end
	return e[#e - 1] == tier and e[#e]:find("^LEVEL " .. level .. "%f[%D]") ~= nil
end
assert(waitFor(done, 12), "BannerLog should end with the tier banner, then LEVEL " .. level .. ": " .. tostring(ui:GetAttribute("BannerLog")))
if level > 0 then assert(ui:GetAttribute("LastLevelUp") == level, "LastLevelUp is " .. tostring(ui:GetAttribute("LastLevelUp")) .. ", want " .. level) end
assert(waitFor(function() return not banner.Visible end, 5), "the last banner did not end")
player:SetAttribute("_T71Level", nil)
return "T71D PLAY OK: the tier banner, then " .. (level > 0 and ("LEVEL " .. level) or "no level (the top level)") .. ", in order"
