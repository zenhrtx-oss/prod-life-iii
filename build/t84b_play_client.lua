-- Client, during play (Wave 3 Task 5c-2; launch audit A5/A12), after t84a (the spy on Flips.Judge armed, your flip-check
-- stamp cleared): standing in reach of the studio PC's screen (DAW_Broadcast's station check), the monitors free, the
-- default beat at 140 BPM. Every flip token here is one no airing has; t84c counts the flip checks by token.
-- (A12) Two sends 0.2 s apart, neither on air nor in line, each with its own unknown flip token (…301, …302): the first
--     reaches the flip check ("gone"); the second answers "cooldown" (DAWConfig.FlipCheckCooldown, 1 s) and never reaches
--     it (t84c: …302 checked 0 times).
-- (1) FlipCheckCooldown later, a send goes on air (position 0).
-- (2) On air, a send with token …303 answers "inline" at position 0, before the flip check (t84c: …303 checked 0 times).
-- (3) Stopped (DAW_Stop), and sent again once the 1 s check limit has passed: "cooldown" from DAWConfig.BroadcastCooldown
--     (8 s from the last send that went in; a stop doesn't reset it), which only that rule can answer by then.
-- (4) BroadcastCooldown seconds after (1) a send goes in again; DAW_Stop ends it.
-- Everything this file changed is set back (nothing of yours on the monitors).
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character; local root = char:WaitForChild("HumanoidRootPart"); local hum = char:WaitForChild("Humanoid")
local R = RS.OK.Remotes; local NP = RS.OK.NowPlaying
local Cfg = require(RS.OK.Modules.DAWConfig)
local pg = player:WaitForChild("PlayerGui", 10)
local daw = pg:WaitForChild("OK_DAW", 10):WaitForChild("DAW", 10); assert(daw, "no beat maker gui")
local T_FIRST, T_SECOND, T_INLINE = 987654301, 987654302, 987654303
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function free() return NP:GetAttribute("Active") ~= true and (NP:GetAttribute("QueueCount") or 0) == 0 end
local function says(r) return type(r) == "table" and string.format("ok %s, reason %s, position %s", tostring(r.ok), tostring(r.reason), tostring(r.position)) or tostring(r) end
local function untilAfter(t, s) local left = s - (os.clock() - t); if left > 0 then task.wait(left) end end
-- the file's own fresh(): the beat maker closed, standing at the studio PC's screen (as t21d)
if daw.Visible then daw:SetAttribute("Command", "close"); task.wait(0.4) end
if hum.Sit then hum.Sit = false; task.wait(0.4) end
root.CFrame = CFrame.new(72.0, 3.5, -5.5); task.wait(0.8)
local out = {}

local function run()
	assert(NP:GetAttribute("Reserved") ~= true, "the monitors are reserved for a cypher round (t84a's fresh is missing)")
	assert(waitFor(free, 25), "the monitors are not free after 25 s (Active " .. tostring(NP:GetAttribute("Active")) .. ", QueueCount "
		.. tostring(NP:GetAttribute("QueueCount")) .. ")")
	task.wait(3.2) -- the gap after the last airing
	local pat = Cfg.DefaultPattern

	-- A12. one flip check a second: the second of two sends 0.2 s apart never reaches it
	local first = R.DAW_Broadcast:InvokeServer(pat, 140, 0, T_FIRST)
	local checkedAt = os.clock()
	assert(type(first) == "table" and first.ok == false and first.reason == "gone", "the first send with an unknown flip token: " .. says(first) .. ", want gone")
	task.wait(0.2)
	local second = R.DAW_Broadcast:InvokeServer(pat, 140, 0, T_SECOND)
	assert(type(second) == "table" and second.ok == false and second.reason == "cooldown", string.format("the second send %.2f s after the first answered %s, want"
		.. " cooldown (one flip check a FlipCheckCooldown)", os.clock() - checkedAt, says(second)))
	local checkGap = Cfg.FlipCheckCooldown
	assert(checkGap == 1, "DAWConfig.FlipCheckCooldown is " .. tostring(checkGap) .. ", want 1")
	table.insert(out, "A12 two sends 0.2 s apart: gone, then cooldown (t84c counts the flip checks)")

	-- 1. on air
	untilAfter(checkedAt, checkGap + 0.2)
	local a = R.DAW_Broadcast:InvokeServer(pat, 140, 0)
	local sentAt = os.clock()
	assert(type(a) == "table" and a.ok == true and a.position == 0, "the first send: " .. says(a) .. ", want on air (position 0)")
	assert(waitFor(function() return NP:GetAttribute("Active") == true and NP:GetAttribute("OwnerId") == player.UserId end, 3), "your beat is not on air")
	table.insert(out, "1 a send went on air")

	-- 2. on air already: "inline" before the flip check
	local b = R.DAW_Broadcast:InvokeServer(pat, 140, 0, T_INLINE)
	assert(type(b) == "table" and b.ok == false and b.reason == "inline" and b.position == 0, "on air, a send with a flip token no airing has answered "
		.. says(b) .. ": want inline (your place), before the flip check, which says gone")
	table.insert(out, "2 on air, a send with an unknown flip token: inline at position 0 (no flip check)")

	-- 3. stopped, and sent again once the 1 s check limit is past: the 8 s cooldown
	local cooldown = Cfg.BroadcastCooldown
	assert(cooldown == 8, "DAWConfig.BroadcastCooldown is " .. tostring(cooldown) .. ", want 8")
	R.DAW_Stop:FireServer()
	assert(waitFor(function() return NP:GetAttribute("Active") == false end, 3), "STOP did not end your airing")
	untilAfter(sentAt, checkGap + 0.3)
	local c = R.DAW_Broadcast:InvokeServer(pat, 140, 0)
	local cAt = os.clock() - sentAt
	assert(type(c) == "table" and c.ok == false and c.reason == "cooldown", string.format("a send %.1f s after your last one went in answered %s, want cooldown (%d s)",
		cAt, says(c), cooldown))
	table.insert(out, string.format("3 stopped, sent again %.1f s after the first (past the 1 s check limit): cooldown", cAt))

	-- 4. the cooldown over: it goes in again
	untilAfter(sentAt, cooldown + 0.3)
	local d = R.DAW_Broadcast:InvokeServer(pat, 140, 0)
	local dAt = os.clock() - sentAt
	assert(type(d) == "table" and d.ok == true, string.format("a send %.1f s after the first answered %s, want it in", dAt, says(d)))
	R.DAW_Stop:FireServer()
	assert(waitFor(function() return NP:GetAttribute("OwnerId") ~= player.UserId or NP:GetAttribute("Active") == false end, 3), "STOP did not end the second airing")
	table.insert(out, string.format("4 %.1f s after the first send one went in again (position %d); STOP ended it", dAt, d.position))
end

local ok, err = pcall(run)
pcall(function() R.DAW_Stop:FireServer() end) -- nothing of yours left on air or in line
if not ok then error(err, 0) end
return "T84B PLAY OK\n" .. table.concat(out, "\n")
