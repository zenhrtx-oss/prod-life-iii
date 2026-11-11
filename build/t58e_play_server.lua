-- Server, during play (after t58d: nothing open; Review Focus 4): a WalkIns Reset with a DM open and one waiting. Pop
-- scam_curator; the live client opens it by itself (PhoneBusy within 5 s); Pop scam_label (it waits behind the open
-- DM); then the WalkIns hook Reset: synchronously (through OnReset) both pops go with an expire each and PhoneBusy
-- clears. t58f checks the client's card and count went.
local Players, SSS = game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function has(sent, kind, token)
	for _, s in ipairs(sent) do if s.kind == kind and s.token == token then return true end end
	return false
end
assert(#ph:Invoke("Pending", uid) == 0 and ph:Invoke("Busy", uid) == false, "pops or PhoneBusy left from t58d")
local a = ph:Invoke("Pop", uid, "scam_curator"); assert(type(a) == "string", "Pop(scam_curator) did not send")
assert(waitFor(function() return p:GetAttribute("PhoneBusy") == true end, 5), "the client did not open the DM by itself within 5 s (PhoneBusy never set)")
local b = ph:Invoke("Pop", uid, "scam_label"); assert(type(b) == "string", "Pop(scam_label) did not send")
task.wait(0.5) -- the second pop reaches the client and waits
local pend = ph:Invoke("Pending", uid)
assert(#pend == 2 and pend[1].opened and not pend[2].opened, "want the first DM open and the second waiting: " .. #pend .. " pending")
ph:Invoke("Sent", uid) -- read and clear: the asserts below read the drops
assert(wi:Invoke("Reset", uid) == true, "Reset failed")
assert(#ph:Invoke("Pending", uid) == 0 and ph:Invoke("Busy", uid) == false and p:GetAttribute("PhoneBusy") == nil, "pops or PhoneBusy left right after the WalkIns Reset")
local sent = ph:Invoke("Sent", uid)
assert(has(sent, "expire", a) and has(sent, "expire", b), "no expire for both tokens (" .. #sent .. " sends)")
return "T58E PLAY OK: a DM open and one waiting; the WalkIns Reset dropped both with an expire each, PhoneBusy clear"
