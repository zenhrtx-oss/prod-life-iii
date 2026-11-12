-- Client, during play (Wave 3 Task 5c-2; launch audit A7), after t86a: a session that can't save (the profile flagged
-- _loadFailed on a server with a store). The lounge-bar laptop opens the beat maker (no chair), and:
-- (1) SAVE goes through (LastSave "ok"), but the status never says "Saved": it reads "Kept for this session only ·
--     progress isn't saving right now", with any XP after it.
-- (2) DAW_Save's own answer carries persistent true and saving false.
-- Everything this file changed is set back (the beat maker closed, the camera free); t86c puts the flags back.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character; local root = char:WaitForChild("HumanoidRootPart"); local hum = char:WaitForChild("Humanoid"); local cam = workspace.CurrentCamera
local R = RS.OK.Remotes
local Cfg = require(RS.OK.Modules.DAWConfig)
local pg = player:WaitForChild("PlayerGui", 10)
local daw = pg:WaitForChild("OK_DAW", 10):WaitForChild("DAW", 10); assert(daw, "no beat maker gui")
local laptop = workspace.OKStudio.Lounge:WaitForChild("Station_Bar", 5):WaitForChild("Screen", 5)
local prompt = laptop and laptop:FindFirstChildWhichIsA("ProximityPrompt"); assert(prompt, "no prompt on the lounge-bar laptop")
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local KEPT = "Kept for this session only · progress isn't saving right now"
-- the file's own fresh(): no forced phone layout, the beat maker closed, standing, the camera free
daw:SetAttribute("CompactForced", nil); daw:SetAttribute("ViewportOverride", nil)
if daw.Visible then daw:SetAttribute("Command", "close"); task.wait(0.4) end
if hum.Sit then hum.Sit = false; task.wait(0.4) end
cam.CameraType = Enum.CameraType.Custom
local out = {}

local function run()
	-- the lounge-bar laptop opens the beat maker standing (as t19b)
	local pos = Vector3.new(18.0, 3.5, -4.8)
	root.CFrame = CFrame.lookAt(pos, Vector3.new(laptop.Position.X, pos.Y, laptop.Position.Z)); task.wait(1.0)
	cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(0, 2.5, 4), laptop.Position); task.wait(1.0)
	for _ = 1, 4 do prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd(); task.wait(0.8); if daw.Visible then break end end
	assert(daw.Visible, "the beat maker did not open from the lounge-bar laptop")

	-- 1. SAVE: kept, never "Saved"
	task.wait(3.2) -- DAWConfig.SaveCooldown since any earlier save
	daw:SetAttribute("Pattern", Cfg.DefaultPattern); daw:SetAttribute("Swing", 0); daw:SetAttribute("LastSave", "")
	daw:SetAttribute("Command", "save")
	assert(waitFor(function() return (daw:GetAttribute("LastSave") or "") ~= "" end, 5) and daw:GetAttribute("LastSave") == "ok", "the save failed: "
		.. tostring(daw:GetAttribute("LastSave")))
	local status = daw:GetAttribute("Status") or ""
	assert(string.sub(status, 1, #KEPT) == KEPT and not string.find(status, "Saved", 1, true), "a session that can't save said '" .. status .. "', want '" .. KEPT .. "'")
	table.insert(out, "1 SAVE: '" .. status .. "'")

	-- 2. the reply itself
	task.wait(3.2)
	local r = R.DAW_Save:InvokeServer(Cfg.DefaultPattern, daw:GetAttribute("BPM") or Cfg.BPM.Default, 0, daw:GetAttribute("Slot") or 1)
	assert(type(r) == "table" and r.ok == true and r.persistent == true and r.saving == false, "DAW_Save answered ok " .. tostring(type(r) == "table" and r.ok)
		.. ", persistent " .. tostring(type(r) == "table" and r.persistent) .. ", saving " .. tostring(type(r) == "table" and r.saving) .. ", want ok, true, false")
	table.insert(out, "2 DAW_Save: persistent true, saving false")
end

local ok, err = pcall(run)
if daw.Visible then daw:SetAttribute("Command", "close"); task.wait(0.4) end
cam.CameraType = Enum.CameraType.Custom
if not ok then error(err, 0) end
return "T86B PLAY OK\n" .. table.concat(out, "\n")
