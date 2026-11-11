-- Server, during play (after t57f left the beat maker open at the studio PC): the note (design 4.4). Spawn
-- navx_placement: he walks to the player and waits behind the beat maker (the client reports the deferral). Once he
-- has arrived, Age 301: the card stood for the whole ExpireSeconds (300), so the next upkeep (within 5 s) expires him
-- with a note on the "leave" ({ name, waited "5 minutes", line }) and nothing stays pending. t58b reads the note card.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local W = require(RS.OK.Config).WalkIns
local Content = require(RS.OK.Data.WalkIns)
local names = Content.Names(W.Roster)

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function pending() return wi:Invoke("Pending", uid) end
local function arrived() local r = pending(); return r ~= nil and r.arrived == true end

assert(#ph:Invoke("Pending", uid) == 0 and ph:Invoke("Busy", uid) == false, "pops or PhoneBusy left from t57f")
assert(pending() == nil, "a visit is still in flight from t57f")
assert(W.ExpireSeconds == 300, "ExpireSeconds is " .. tostring(W.ExpireSeconds) .. ": this case ages 301 s for '5 minutes'")
assert(wi:Invoke("Spawn", uid, "navx_placement") == true, "Spawn(navx_placement) refused (is the player in the hub?)")
-- he walks ~75 studs to the studio PC (about 9.4 s at WalkSpeed 8); arrival waits are capped at 15 s
assert(waitFor(arrived, 15), "he did not arrive within 15 s")
local rec = pending()
wi:Invoke("Sent", uid) -- read and clear: the asserts below read the leave
assert(wi:Invoke("Age", uid, 301) == true, "Age(301) refused")
assert(waitFor(function() return pending() == nil end, 5), "the visit did not expire within 5 s of ageing 301 s")
local leave
for _, s in ipairs(wi:Invoke("Sent", uid)) do if s.kind == "leave" and s.payload.token == rec.token then leave = s.payload end end
assert(leave, "no leave was sent for his token")
local note = leave.note
assert(type(note) == "table", "the leave carries no note (he should have expired, not left for another reason)")
assert(note.name == names.navx, "the note names " .. tostring(note.name) .. " (want " .. tostring(names.navx) .. ")")
assert(note.waited == "5 minutes", "the note says he waited '" .. tostring(note.waited) .. "' (want '5 minutes')")
assert(type(note.line) == "string" and note.line ~= "" and not note.line:find("{", 1, true), "the note's line is empty or holds a token: " .. tostring(note.line))
return string.format("T58A PLAY OK: %s arrived behind the beat maker, expired at 301 s with a note (waited %s, %q)", note.name, note.waited, note.line)
