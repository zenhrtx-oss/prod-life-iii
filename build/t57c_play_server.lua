-- Server, during play (after t57b left the beat maker open; Review Focus 2): two DMs wait behind it and one of them
-- expires. Pop scam_curator (A), Age 400, Pop scam_label (B), Age 201: Age takes no token, so A reaches 601 s and
-- expires (ExpireSeconds 600) while B is at 201 s. Age runs the sweep at once: Pending holds only B, A got its expire
-- (the client drops it: t57d), A logged no PhoneOpen (the beat maker kept the client from opening it) and moved no
-- phone count, and PhoneBusy is clear.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local test = SOK._StudioTestHook
local P = require(RS.OK.Config).Phone
local A, B = "scam_curator", "scam_label"

local function pops() return ph:Invoke("Pending", uid) end
local function ids() local t = {}; for _, e in ipairs(pops()) do table.insert(t, e.id .. (e.opened and "(open)" or "")) end; return table.concat(t, ", ") end
-- the player's phone telemetry entries named `name` (and, when given, with that detail)
local function events(name, detail)
	local n = 0
	for _, e in ipairs(test:Invoke("FunnelEvents", uid)) do
		local f = e.fields or {}
		if e.name == name and f.source == "phone" and (detail == nil or f.detail == detail) then n += 1 end
	end
	return n
end
local function has(sent, kind, token)
	for _, s in ipairs(sent) do if s.kind == kind and s.token == token then return true end end
	return false
end

assert(#pops() == 0 and ph:Invoke("Busy", uid) == false, "pops or PhoneBusy left from t57b: " .. ids())
assert(test:Invoke("ResetFunnelEvents", uid) == true, "ResetFunnelEvents failed")
ph:Invoke("Sent", uid) -- read and clear
local st0 = ph:Invoke("State", uid)
local a = ph:Invoke("Pop", uid, A); assert(type(a) == "string", "Pop(" .. A .. ") did not send")
assert(ph:Invoke("Age", uid, 400) == 0, "A expired at 400 s (ExpireSeconds " .. tostring(P.ExpireSeconds) .. ")")
local b = ph:Invoke("Pop", uid, B); assert(type(b) == "string", "Pop(" .. B .. ") did not send (" .. ids() .. ")")
local dropped = ph:Invoke("Age", uid, 201)
assert(dropped == 1, "Age 201 dropped " .. tostring(dropped) .. " pops (want 1: A at 601 s)")
local pend = pops()
assert(#pend == 1 and pend[1].token == b and pend[1].id == B and not pend[1].opened, "pending after the ages: " .. ids() .. " (want only " .. B .. ", un-opened)")
local sent = ph:Invoke("Sent", uid)
assert(has(sent, "expire", a) and not has(sent, "expire", b), "no expire for A, or one for B (" .. #sent .. " sends)")
assert(events("PhoneOpen") == 0, "PhoneOpen logged " .. events("PhoneOpen") .. " times: a card opened behind the beat maker")
assert(events("PhoneExpire", "waited") == 1, "PhoneExpire waited logged " .. events("PhoneExpire", "waited") .. " times (want 1)")
local st1 = ph:Invoke("State", uid)
assert(st1.today == st0.today and st1.count == st0.count, string.format("the phone count moved %d/%d -> %d/%d", st0.today, st0.count, st1.today, st1.count))
assert(ph:Invoke("Busy", uid) == false and p:GetAttribute("PhoneBusy") == nil, "PhoneBusy is set with nothing open")
return string.format("T57C PLAY OK: %s expired at 601 s behind the beat maker (expire sent, no PhoneOpen, today %d count %d kept); %s waits at 201 s", A, st1.today, st1.count, B)
