-- Server, during play: WalkIns when the target respawns, and the server-wide walking limit. Paused throughout.
-- A respawn before he arrives sends him out, clears the record, counts nothing, and the next spawn brings the same
-- pick (no reroll); a respawn with the card open sends him out with no stat change and leaves no visitor behind.
-- Four decoys against MaxWalking: three walk, one waits, and it is admitted once one of the three has left.
-- Busy expiry: a card standing open past ExpireBusySeconds stays while no visit waits for a walking slot, and closes
-- (giving up the slot) once one does. The hook's Age moves the arrival back, so the case doesn't wait 90 s.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local test = SOK._StudioTestHook
local W = require(RS.OK.Config).WalkIns
local LOUNGE = Vector3.new(24, 3, 0)
local STATS = { "money", "aura", "followers", "placements", "hits", "sponsors" }
local out = {}

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function root() local c = p.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function teleport(pos) -- server-side; checked, and tried once more if the client's position won
	for _ = 1, 2 do
		local c = p.Character or p.CharacterAdded:Wait()
		c:WaitForChild("HumanoidRootPart", 5)
		c:PivotTo(CFrame.new(pos))
		task.wait(0.3)
		local r = root()
		if r and flat(r.Position - pos) < 2 then return r end
	end
	error("teleport to " .. tostring(pos) .. " did not take")
end
local function walkins() return test:Invoke("GetProfile", uid).walkins end
local function stats() return career:Invoke("Get", uid) end
local function pending() return wi:Invoke("Pending", uid) end
local function arrived() local r = pending(); return r ~= nil and r.arrived == true end
local function visitorHere()
	local f = workspace:FindFirstChild("OK_Visitors")
	for _, m in ipairs(f and f:GetChildren() or {}) do if m:GetAttribute("Target") == uid then return true end end
	return false
end
-- respawn and wait for the new character's root part
local function respawn()
	local old = p.Character
	p:LoadCharacter()
	assert(waitFor(function() local c = p.Character; return c ~= nil and c ~= old and c:FindFirstChild("HumanoidRootPart") ~= nil end, 10), "the character did not respawn")
end

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	assert(wi:Invoke("Reset", uid) == true, "Reset failed")
	assert(career:Invoke("Set", uid, { sponsor = false }) == true, "could not clear the sponsor deal")
	teleport(LOUNGE)

	-- respawn before arrival keeps the pick
	local count0 = walkins().count
	assert(wi:Invoke("Spawn", uid) == true, "before arrival: Spawn() refused")
	local r0 = pending()
	assert(r0 and r0.arrived == false and type(r0.id) == "string", "before arrival: no unarrived record")
	local id = r0.id
	respawn()
	assert(waitFor(function() return pending() == nil end, 15), "before arrival: the record was not cleared after the respawn")
	assert(waitFor(function() return not visitorHere() end, 15), "before arrival: the visitor is still here 15 s after the respawn")
	assert(walkins().count == count0, "before arrival: an unarrived visit counted")
	teleport(LOUNGE)
	assert(wi:Invoke("Spawn", uid) == true, "before arrival: the second Spawn() was refused")
	assert(pending().id == id, "before arrival: the pick was rerolled (" .. id .. " -> " .. tostring(pending().id) .. ")")
	table.insert(out, "respawn before arrival: record cleared, visitor gone, count unchanged; next spawn is " .. id .. " again")

	-- respawn with the card open
	assert(waitFor(arrived, 15), "card open: he did not arrive within 15 s")
	local before, count1 = stats(), walkins().count
	assert(count1 == count0 + 1, "card open: the arrival did not count")
	respawn()
	assert(waitFor(function() return pending() == nil end, 5), "card open: the record was not cleared after the respawn")
	local after = stats()
	for _, s in ipairs(STATS) do assert(after[s] == before[s], "card open: " .. s .. " changed " .. before[s] .. " -> " .. after[s]) end
	assert(walkins().count == count1, "card open: the visit should stay counted")
	assert(waitFor(function() return not visitorHere() end, 20), "card open: a visitor with Target == player is still under OK_Visitors 20 s after the respawn")
	teleport(LOUNGE)
	table.insert(out, "respawn with the card open: record cleared, no stat change, visit counted, no visitor left after he walked out")

	-- MaxWalking queue
	assert(wi:Invoke("Reset", uid) == true, "queue: Reset failed")
	assert(wi:Invoke("Walking") == 0 and wi:Invoke("Waiting") == 0, "queue: visitors left over before the case")
	assert(wi:Invoke("SpawnExtra", uid, W.MaxWalking + 1) == W.MaxWalking + 1, "queue: SpawnExtra refused")
	assert(waitFor(function() return wi:Invoke("Walking") == W.MaxWalking and wi:Invoke("Waiting") == 1 end, 2),
		"queue: want " .. W.MaxWalking .. " walking and 1 waiting, got " .. tostring(wi:Invoke("Walking")) .. " / " .. tostring(wi:Invoke("Waiting")))
	assert(waitFor(function() return wi:Invoke("Waiting") == 0 end, 20), "queue: the last decoy was not admitted within 20 s")
	assert(wi:Invoke("Walking") <= W.MaxWalking, "queue: more than MaxWalking walking")
	assert(wi:Invoke("Reset", uid) == true and wi:Invoke("Walking") == 0 and wi:Invoke("Waiting") == 0, "queue: Reset left visitors walking")
	table.insert(out, string.format("MaxWalking: %d decoys -> %d walking, 1 waiting; admitted after one left; Reset -> 0 walking", W.MaxWalking + 1, W.MaxWalking))

	-- busy expiry: his own card holds one slot; MaxWalking decoys fill the rest and leave one waiting
	local busy = W.ExpireBusySeconds
	assert(type(busy) == "number" and busy < W.ExpireSeconds, "busy expiry: Config.WalkIns.ExpireBusySeconds should be a number under ExpireSeconds")
	assert(wi:Invoke("Spawn", uid) == true, "busy expiry: Spawn() refused")
	assert(waitFor(arrived, 15), "busy expiry: he did not arrive within 15 s")
	local token = pending().token
	assert(wi:Invoke("Age", uid, busy + 1) == true, "busy expiry: Age refused")
	task.wait(2.5) -- the 1 s upkeep runs at least twice
	local still = pending()
	assert(still and still.token == token and wi:Invoke("Waiting") == 0, "busy expiry: with no visit waiting, the card closed " .. (busy + 1) .. " s after arrival (ExpireSeconds is " .. W.ExpireSeconds .. ")")
	assert(wi:Invoke("SpawnExtra", uid, W.MaxWalking) == W.MaxWalking, "busy expiry: SpawnExtra refused")
	assert(wi:Invoke("Walking") == W.MaxWalking and wi:Invoke("Waiting") == 1,
		"busy expiry: want " .. W.MaxWalking .. " walking and 1 waiting, got " .. tostring(wi:Invoke("Walking")) .. " / " .. tostring(wi:Invoke("Waiting")))
	assert(waitFor(function() return pending() == nil end, 2.5), "busy expiry: the card stayed open past ExpireBusySeconds while a visit waited for a slot")
	assert(waitFor(function() return wi:Invoke("Waiting") == 0 end, 15), "busy expiry: the waiting visit was not admitted within 15 s")
	assert(wi:Invoke("Walking") <= W.MaxWalking, "busy expiry: more than MaxWalking walking")
	assert(wi:Invoke("Reset", uid) == true and wi:Invoke("Walking") == 0 and wi:Invoke("Waiting") == 0, "busy expiry: Reset left visitors walking")
	table.insert(out, string.format("busy expiry: open card %ds old stays with no one waiting; with 1 waiting it closes (ExpireBusySeconds %d) and the visit is admitted", busy + 1, busy))

	return "T43C PLAY OK\n" .. table.concat(out, "\n")
end

local ok, msg = pcall(run)
pcall(function() wi:Invoke("Reset", uid); wi:Invoke("Pause", uid, true) end)
pcall(teleport, LOUNGE)
if not ok then error(msg, 0) end
return msg
