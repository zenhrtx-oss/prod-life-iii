-- Client, during play (Wave 3 Task 5c-2; launch audit A6), after t85a's reset career (no placement, so studio_two is
-- refused for its needs). Career_Unlock sits behind a token bucket per player: a burst of 3, then one every 0.25 s.
-- (1) After 1 s with no unlock (the bucket full), 8 unlocks sent at once: 3 (a 4th if one refilled while they landed) are
--     answered by the gate ("needs"), each with a career state (Fetch's), and the rest "busy" with none: no state is
--     built or sent for a refused spam call (the panel fetches its own).
-- (2) 0.3 s later one more is answered by the gate again, with a state.
-- Nothing changes: every unlock is refused. Nothing on this client needs resetting first: the file only calls a remote.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local R = RS.OK.Remotes
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function isState(st) return type(st) == "table" and type(st.stats) == "table" and type(st.gates) == "table" end
local N = 8
local out = {}

local function run()
	task.wait(1.0) -- the bucket refills to its burst of 3
	local res, back = {}, 0
	for i = 1, N do
		task.spawn(function()
			local ok, r = pcall(function() return R.Career_Unlock:InvokeServer("studio_two") end)
			res[i] = ok and r or { error = tostring(r) }
			back += 1
		end)
	end
	assert(waitFor(function() return back == N end, 10), back .. " of " .. N .. " unlocks came back within 10 s")
	local needs, busy, other = 0, 0, {}
	for i = 1, N do
		local r = res[i]
		if type(r) == "table" and r.ok == false and r.reason == "needs" then needs += 1
		elseif type(r) == "table" and r.ok == false and r.reason == "busy" then busy += 1
		else table.insert(other, i .. ": " .. (type(r) == "table" and (tostring(r.ok) .. "/" .. tostring(r.reason or r.error)) or tostring(r))) end
		if type(r) == "table" and r.reason == "needs" then assert(isState(r.state), "unlock " .. i .. " (needs) came back without a career state") end
		if type(r) == "table" and r.reason == "busy" then assert(r.state == nil, "unlock " .. i .. " (busy) came back with a career state: a refused spam call must cost nothing more") end
	end
	assert(#other == 0, "unexpected answers: " .. table.concat(other, "; "))
	assert(needs >= 3 and needs <= 4 and busy == N - needs, string.format("%d unlocks at once: %d answered by the gate (needs) and %d busy, want 3 (or 4) and the rest busy",
		N, needs, busy))
	table.insert(out, string.format("1 %d unlocks at once: %d answered by the gate (needs, each with a career state), %d busy with none", N, needs, busy))

	task.wait(0.3)
	local r2 = R.Career_Unlock:InvokeServer("studio_two")
	assert(type(r2) == "table" and r2.ok == false and r2.reason == "needs" and isState(r2.state), "0.3 s later an unlock answered "
		.. tostring(type(r2) == "table" and r2.reason) .. ", want needs (the bucket refilled one)")
	table.insert(out, "2 0.3 s later: answered by the gate again (needs)")
end

local ok, err = pcall(run) -- nothing of this file's to put back: every unlock was refused
if not ok then error(err, 0) end
return "T85B PLAY OK\n" .. table.concat(out, "\n")
