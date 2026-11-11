-- Edit: choice telemetry (Wave 1a Task 0). Funnel.Event(player, name, value?, fields?) keeps every event in
-- Funnel._events in Studio (before its player guard, so a fake player is logged too) and packs the fields into
-- AnalyticsService's three custom fields with Funnel._customFields: source -> CustomField01, card -> CustomField02,
-- detail -> CustomField03, each as a string. A fake player never reaches LogCustomEvent (the guard), so no stub.
local RS = game:GetService("ReplicatedStorage")
local function freshRequire(mod) local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name; local ok, r = pcall(require, c); c:Destroy(); if not ok then error(r) end; return r end
local F = freshRequire(RS.OK.Systems.Funnel)
local K = Enum.AnalyticsCustomFieldKeys
local FAKE = { UserId = -4401 }

-- (a) one event with fields lands in _events as { uid, name, value, fields }; value defaults to 1
assert(type(F._events) == "table" and #F._events == 0, "a fresh Funnel should start with no events, has " .. tostring(F._events and #F._events))
local fields = { source = "walkin", card = "navx_placement", detail = "1:placement" }
F.Event(FAKE, "CardChoice", nil, fields)
assert(#F._events == 1, "Event should append one entry, _events has " .. #F._events)
local e = F._events[1]
assert(e.uid == -4401 and e.name == "CardChoice" and e.value == 1,
	string.format("entry should be uid -4401, CardChoice, value 1; is %s, %s, %s", tostring(e.uid), tostring(e.name), tostring(e.value)))
assert(type(e.fields) == "table" and e.fields.source == "walkin" and e.fields.card == "navx_placement" and e.fields.detail == "1:placement",
	"entry fields should be the ones passed")
F.Event(FAKE, "CardWalkAway", 3, { source = "phone", card = "scam_curator" })
assert(#F._events == 2 and F._events[2].name == "CardWalkAway" and F._events[2].value == 3, "a second event should append after the first")

-- (b) _customFields: exactly the three CustomField keys, strings; a missing value is left out; no fields -> nil
local cf = F._customFields(fields)
local n = 0
for k, v in pairs(cf) do n += 1; assert(type(k) == "string" and type(v) == "string", "custom field " .. tostring(k) .. " should be a string") end
assert(n == 3, "_customFields should give 3 keys, gave " .. n)
assert(cf[K.CustomField01.Name] == "walkin", "CustomField01 should be the source, is " .. tostring(cf[K.CustomField01.Name]))
assert(cf[K.CustomField02.Name] == "navx_placement", "CustomField02 should be the card, is " .. tostring(cf[K.CustomField02.Name]))
assert(cf[K.CustomField03.Name] == "1:placement", "CustomField03 should be the detail, is " .. tostring(cf[K.CustomField03.Name]))
local two = F._customFields({ source = "phone", card = 7 })
assert(two[K.CustomField02.Name] == "7" and two[K.CustomField03.Name] == nil, "a number becomes a string and a missing detail is left out")
assert(F._customFields(nil) == nil, "no fields should give nil (LogCustomEvent is called without custom fields)")

return string.format("T59 OK: Funnel.Event logs %d events for a fake player; _customFields packs source, card, detail into %s, %s, %s",
	#F._events, K.CustomField01.Name, K.CustomField02.Name, K.CustomField03.Name)
