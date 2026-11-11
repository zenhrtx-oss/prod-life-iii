-- Server, during play (after t58f: nothing open; Review Focus 4; last server file of the suite, so no later file
-- inherits the respawn): a respawn with a DM open and one waiting. Pop scam_curator; the live client opens it by
-- itself (PhoneBusy within 5 s); Pop scam_label (it waits); then p:LoadCharacter(). The deferred CharacterAdded handler
-- drops both (Pending empty within 5 s, an expire each, PhoneBusy clear); the new character is put back in the lounge
-- at (24, 3, 0), where t57a started. t58h checks the client's card and count went and nothing opens again.
local Players, SSS = game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local LOUNGE = Vector3.new(24, 3, 0)
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
local function has(sent, kind, token)
	for _, s in ipairs(sent) do if s.kind == kind and s.token == token then return true end end
	return false
end
assert(#ph:Invoke("Pending", uid) == 0 and ph:Invoke("Busy", uid) == false, "pops or PhoneBusy left from t58f")
local a = ph:Invoke("Pop", uid, "scam_curator"); assert(type(a) == "string", "Pop(scam_curator) did not send")
assert(waitFor(function() return p:GetAttribute("PhoneBusy") == true end, 5), "the client did not open the DM by itself within 5 s (PhoneBusy never set)")
local b = ph:Invoke("Pop", uid, "scam_label"); assert(type(b) == "string", "Pop(scam_label) did not send")
task.wait(0.5) -- the second pop reaches the client and waits
assert(#ph:Invoke("Pending", uid) == 2, "want two pops pending before the respawn")
ph:Invoke("Sent", uid) -- read and clear: the asserts below read the drops
local old = p.Character
p:LoadCharacter()
assert(waitFor(function() local c = p.Character; return c ~= nil and c ~= old and c:FindFirstChild("HumanoidRootPart") ~= nil end, 10), "the character did not respawn")
assert(waitFor(function() return #ph:Invoke("Pending", uid) == 0 end, 5), "the pops were not dropped within 5 s of the respawn")
assert(ph:Invoke("Busy", uid) == false and p:GetAttribute("PhoneBusy") == nil, "PhoneBusy is still set after the respawn")
local sent = ph:Invoke("Sent", uid)
assert(has(sent, "expire", a) and has(sent, "expire", b), "no expire for both tokens (" .. #sent .. " sends)")
teleport(LOUNGE)
return "T58G PLAY OK: a DM open and one waiting; the respawn dropped both with an expire each, PhoneBusy clear; back in the lounge"
