-- Server, during play (Wave 3 Task 5c-2; launch audit A12), after t84b: what the spy t84a put on Flips.Judge counted, by
-- flip token. The first of t84b's two sends 0.2 s apart (…301) reached the flip check once; the second (…302), answered
-- "cooldown", never did; and the send made while on air (…303), answered "inline", never did. So a client spamming sends
-- pays for at most one flip check a FlipCheckCooldown. Then the spy comes off and the flip-check stamp is cleared.
-- This file continues t84a/t84b, like t82c, so it has no fresh() of its own.
local Players, SSS = game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local mon = SSS.OK:WaitForChild("_StudioMonitorHook", 5); assert(mon, "no _StudioMonitorHook")
local T_FIRST, T_SECOND, T_INLINE = 987654301, 987654302, 987654303

local function run()
	local first, second, inline = mon:Invoke("Judged", T_FIRST), mon:Invoke("Judged", T_SECOND), mon:Invoke("Judged", T_INLINE)
	assert(type(first) == "number", "the monitor hook has no spy on Flips.Judge (t84a, the 5c-2 fix1 Main)")
	assert(first == 1, "the first send's flip check ran " .. tostring(first) .. " times, want 1 (t84b's A12 case did not run?)")
	assert(second == 0, "the second send, 0.2 s after the first, reached the flip check " .. tostring(second) .. " time(s): want 0, answered cooldown before it")
	assert(inline == 0, "the send made while on air reached the flip check " .. tostring(inline) .. " time(s): want 0, answered inline before it")
	return string.format("flip checks by token: …301 %d, …302 %d, …303 %d", first, second, inline)
end

local ok, msg = pcall(run)
pcall(function() mon:Invoke("UnspyJudge"); mon:Invoke("ClearFlipCheck", p.UserId) end)
if not ok then error(msg, 0) end
return "T84C PLAY OK: " .. msg .. "; the spy off, the stamp cleared"
