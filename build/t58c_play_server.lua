-- Server, during play (after t58b: nothing open on the client; Review Focus 4): an opened DM expires. Pop scam_curator;
-- the live client opens it by itself (PhoneBusy within 5 s: the client's Phone_Open landed); then Age 301
-- (OpenExpireSeconds 300) drops it as a dismiss: an expire to the client, no pop pending, PhoneBusy clear. t58d checks
-- the client's card went.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local P = require(RS.OK.Config).Phone
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function has(sent, kind, token)
	for _, s in ipairs(sent) do if s.kind == kind and s.token == token then return true end end
	return false
end
assert(#ph:Invoke("Pending", uid) == 0 and ph:Invoke("Busy", uid) == false, "pops or PhoneBusy left from t58b")
assert(P.OpenExpireSeconds == 300, "OpenExpireSeconds is " .. tostring(P.OpenExpireSeconds) .. ": this case ages 301 s")
ph:Invoke("Sent", uid) -- read and clear
local a = ph:Invoke("Pop", uid, "scam_curator"); assert(type(a) == "string", "Pop(scam_curator) did not send")
local t0 = os.clock()
assert(waitFor(function() return p:GetAttribute("PhoneBusy") == true end, 5), "the client did not open the DM by itself within 5 s (PhoneBusy never set)")
local openedIn = os.clock() - t0
local pend = ph:Invoke("Pending", uid)
assert(#pend == 1 and pend[1].token == a and pend[1].opened, "the opened DM is not the one pending")
local dropped = ph:Invoke("Age", uid, 301)
assert(dropped == 1, "Age 301 dropped " .. tostring(dropped) .. " pops (want 1: the opened DM)")
assert(#ph:Invoke("Pending", uid) == 0 and ph:Invoke("Busy", uid) == false and p:GetAttribute("PhoneBusy") == nil, "the pop or PhoneBusy is still there after the expiry")
assert(has(ph:Invoke("Sent", uid), "expire", a), "no expire went to the client for the opened DM")
return string.format("T58C PLAY OK: scam_curator opened by the client in %.1f s, expired at 301 s open (expire sent, PhoneBusy clear)", openedIn)
