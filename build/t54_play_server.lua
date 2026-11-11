-- Server, during play: "he left a note" (design 4.4) through the WalkIns Studio hook, paused throughout. A card that
-- stands open for ExpireSeconds closes with a note on its "leave" payload (who, how long he waited, his parting line),
-- read through the hook's Sent (Age moves the arrival back, so nothing waits 5 minutes); the visit counted once, at
-- arrival, and the expiry logs CardExpire and CardNote. WALK AWAY and the hook's Expire (reason hook) close the card
-- with no note and no expiry telemetry.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local test = SOK._StudioTestHook
local W = require(RS.OK.Config).WalkIns
local Tour = require(RS.OK.Systems.Tour)
local Content = require(RS.OK.Data.WalkIns)
local Rules = require(RS.OK.Modules.WalkInRules)
local CARD = "navx_placement" -- an artist card with no sponsor: its visitor's display name is the roster's, as is
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
local function walkins() return test:Invoke("GetProfile", uid).walkins end
local function pending() return wi:Invoke("Pending", uid) end
local function arrived() local r = pending(); return r ~= nil and r.arrived == true end
local function advanceTour() for _, s in ipairs(Tour.Steps) do test:Invoke("TourAdvance", uid, s.id) end end
-- WalkIns state back to defaults, the tour done, the telemetry and the send log empty
local function fresh(label)
	assert(wi:Invoke("Reset", uid) == true, label .. ": Reset failed")
	advanceTour()
	assert(test:Invoke("ResetFunnelEvents", uid) == true, label .. ": ResetFunnelEvents failed")
	wi:Invoke("Sent", uid) -- read and clear
end
-- the "leave" sends since the last read, polled for up to t seconds until there is one
local function leaves(t)
	local got = {}
	waitFor(function()
		for _, s in ipairs(wi:Invoke("Sent", uid)) do if s.kind == "leave" then table.insert(got, s) end end
		return #got > 0
	end, t)
	return got
end
-- the player's walk-in telemetry entries named `name` (and, when given, for that card)
local function events(name, card)
	local n = 0
	for _, e in ipairs(test:Invoke("FunnelEvents", uid)) do
		local f = e.fields or {}
		if e.name == name and f.source == "walkin" and (card == nil or f.card == card) then n += 1 end
	end
	return n
end
local function spawnArrived(label)
	assert(wi:Invoke("Spawn", uid, CARD) == true, label .. ": Spawn(" .. CARD .. ") refused")
	assert(waitFor(arrived, 15), label .. ": he did not arrive within 15 s")
	wi:Invoke("Sent", uid) -- drop the arrive
	return pending()
end

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	teleport(LOUNGE)
	assert(W.ExpireSeconds == 300, "Config.WalkIns.ExpireSeconds is " .. tostring(W.ExpireSeconds) .. "; the note case ages the card 301 s for '5 minutes'")
	local card = Content.CardById[CARD]
	assert(card and card.sponsor == nil, CARD .. " is not a sponsor-free card")
	local names = Content.Names(W.Roster)
	local noteLines = {}
	for _, l in ipairs(Content.NoteLines) do noteLines[Rules.Fill(l, names, nil)] = true end

	-- expired: one leave with the note, the count unchanged, CardExpire and CardNote
	fresh("expired")
	local c0 = walkins().count
	local r1 = spawnArrived("expired")
	assert(walkins().count == c0 + 1, "expired: the arrival did not count once (" .. c0 .. " -> " .. walkins().count .. ")")
	assert(wi:Invoke("Waiting") == 0, "expired: a visit is waiting for a slot (the busy limit would apply)")
	assert(wi:Invoke("Age", uid, 301) == true, "expired: Age(301) refused")
	local got = leaves(2)
	assert(#got == 1 and got[1].payload.token == r1.token, "expired: want one leave for the card within 2 s of Age(301), got " .. #got)
	local note = got[1].payload.note
	assert(type(note) == "table", "expired: the leave carries no note")
	assert(note.waited == "5 minutes", "expired: note.waited is " .. tostring(note.waited) .. " (want '5 minutes')")
	assert(note.name == names[card.visitor], "expired: note.name is " .. tostring(note.name) .. " (want " .. tostring(names[card.visitor]) .. ")")
	assert(noteLines[note.line] == true, "expired: note.line is not a filled W.NoteLines line: " .. tostring(note.line))
	assert(walkins().count == c0 + 1 and pending() == nil, "expired: the visit counted again (" .. walkins().count .. ") or stayed open")
	assert(events("CardExpire", CARD) == 1 and events("CardNote", CARD) == 1,
		"expired: want one CardExpire and one CardNote for " .. CARD .. ", got " .. events("CardExpire") .. " / " .. events("CardNote"))
	table.insert(out, string.format("expired: %s aged 301 s -> leave with note { %s, %s, %q }; count %d -> %d once; CardExpire + CardNote",
		CARD, note.name, note.waited, note.line, c0, walkins().count))

	-- walk away: the leave has no note, nothing logged as an expiry
	fresh("walk away")
	local r2 = spawnArrived("walk away")
	assert(wi:Invoke("Choose", uid, r2.token, 0).ok == true, "walk away: Choose(0) failed")
	got = leaves(2)
	assert(#got == 1 and got[1].payload.token == r2.token and got[1].payload.note == nil,
		"walk away: want one leave with no note, got " .. #got .. ((got[1] and got[1].payload.note) and " with a note" or ""))
	assert(events("CardExpire") == 0 and events("CardNote") == 0 and events("CardWalkAway", CARD) == 1,
		"walk away: want CardWalkAway only, got CardExpire " .. events("CardExpire") .. ", CardNote " .. events("CardNote"))
	table.insert(out, "walk away: leave with no note, CardWalkAway only")

	-- the hook's Expire (reason hook): no note either
	fresh("hook expire")
	local r3 = spawnArrived("hook expire")
	assert(wi:Invoke("Expire", uid) == true, "hook expire: Expire refused")
	got = leaves(2)
	assert(#got == 1 and got[1].payload.token == r3.token and got[1].payload.note == nil, "hook expire: want one leave with no note, got " .. #got)
	assert(pending() == nil and events("CardExpire") == 0 and events("CardNote") == 0, "hook expire: the card stayed open or an expiry was logged")
	table.insert(out, "hook Expire: leave with no note, nothing logged")
	return "T54 PLAY OK\n" .. table.concat(out, "\n")
end

local ok, msg = pcall(run)
pcall(function() wi:Invoke("Reset", uid); wi:Invoke("Pause", uid, true) end)
pcall(teleport, LOUNGE)
if not ok then error(msg, 0) end
return msg
