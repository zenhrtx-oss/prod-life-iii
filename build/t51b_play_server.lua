-- Server, during play: the phone's drop paths (Review Focus 4). Two DMs wait, one of them open: a respawn drops both
-- (an expire each, no PhoneExpire, nothing counted, PhoneBusy cleared) once the deferred CharacterAdded handler lands;
-- and the WalkIns hook Reset drops both synchronously through WalkIns.OnReset, asserted with no wait. Quiet keeps the
-- pops off the client.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local test = SOK._StudioTestHook
local Tour = require(RS.OK.Systems.Tour)
local LOUNGE = Vector3.new(24, 3, 0)
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
local function pops() return ph:Invoke("Pending", uid) end
local function state() return ph:Invoke("State", uid) end
local function advanceTour() for _, s in ipairs(Tour.Steps) do test:Invoke("TourAdvance", uid, s.id) end end
local function fresh(label)
	assert(wi:Invoke("Reset", uid) == true, label .. ": Reset failed")
	advanceTour()
	assert(ph:Invoke("Reset", uid) == true, label .. ": phone Reset failed")
	assert(ph:Invoke("SetToday", uid, 0) == true, label .. ": SetToday failed")
	assert(test:Invoke("ResetFunnelEvents", uid) == true, label .. ": ResetFunnelEvents failed")
end
-- the player's phone telemetry entries named `name`
local function events(name)
	local n = 0
	for _, e in ipairs(test:Invoke("FunnelEvents", uid)) do
		if e.name == name and e.fields and e.fields.source == "phone" then n += 1 end
	end
	return n
end
local function has(sent, kind, token)
	for _, s in ipairs(sent) do if s.kind == kind and s.token == token then return true end end
	return false
end
-- respawn and wait for the new character's root part
local function respawn()
	local old = p.Character
	p:LoadCharacter()
	assert(waitFor(function() local c = p.Character; return c ~= nil and c ~= old and c:FindFirstChild("HumanoidRootPart") ~= nil end, 10), "the character did not respawn")
end
-- two DMs pending, the first opened; returns their tokens and the phone state after the open
local function twoOpenOne(label)
	local a, b = ph:Invoke("Pop", uid, "scam_curator"), ph:Invoke("Pop", uid, "scam_label")
	assert(type(a) == "string" and type(b) == "string", label .. ": two DMs did not pop")
	assert(ph:Invoke("Open", uid, a) == true, label .. ": Open failed")
	assert(p:GetAttribute("PhoneBusy") == true and #pops() == 2, label .. ": want PhoneBusy and 2 pending after the open")
	ph:Invoke("Sent", uid) -- clear the pop sends: the asserts below read the drops
	return a, b, state()
end

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	assert(ph:Invoke("Quiet", uid, true) == true, "Quiet(true) failed")
	teleport(LOUNGE)

	-- respawn: the deferred CharacterAdded handler drops both, nothing counted or logged
	fresh("respawn")
	local a, b, st0 = twoOpenOne("respawn")
	respawn()
	assert(waitFor(function() return #pops() == 0 end, 5), "respawn: the pops were not dropped within 5 s of the respawn")
	assert(p:GetAttribute("PhoneBusy") == nil and ph:Invoke("Busy", uid) == false, "respawn: PhoneBusy is still set")
	local sent = ph:Invoke("Sent", uid)
	assert(has(sent, "expire", a) and has(sent, "expire", b), "respawn: no expire for both tokens (" .. #sent .. " sends)")
	assert(events("PhoneExpire") == 0, "respawn: a respawn logged PhoneExpire")
	local st1 = state()
	assert(st1.today == st0.today and st1.count == st0.count, string.format("respawn: today/count moved %d/%d -> %d/%d", st0.today, st0.count, st1.today, st1.count))
	teleport(LOUNGE)
	table.insert(out, "respawn: 2 DMs (1 open) dropped, expire x2, no PhoneExpire, PhoneBusy nil, today " .. st1.today .. " count " .. st1.count .. " kept")

	-- the reset seam is synchronous: the WalkIns hook Reset runs Phone's reset before it returns
	fresh("reset")
	local c, d = twoOpenOne("reset")
	assert(wi:Invoke("Reset", uid) == true, "reset: Reset failed")
	assert(ph:Invoke("Busy", uid) == false, "reset: Busy still true right after the WalkIns Reset")
	assert(#pops() == 0, "reset: pops still pending right after the WalkIns Reset")
	assert(p:GetAttribute("PhoneBusy") == nil, "reset: PhoneBusy still set right after the WalkIns Reset")
	local sent2 = ph:Invoke("Sent", uid)
	assert(has(sent2, "expire", c) and has(sent2, "expire", d), "reset: no expire for both tokens (" .. #sent2 .. " sends)")
	assert(events("PhoneExpire") == 0, "reset: the Reset logged PhoneExpire")
	table.insert(out, "WalkIns Reset: with no wait, Busy false, no pops, PhoneBusy nil, expire x2")

	return "T51B PLAY OK\n" .. table.concat(out, "\n")
end

local ok, msg = pcall(run)
pcall(function() wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); ph:Invoke("Quiet", uid, false); wi:Invoke("Pause", uid, true) end)
pcall(teleport, LOUNGE)
if not ok then error(msg, 0) end
return msg
