-- Server, during play (the Your Rooms plan, Task 10: decorate mode, the server's side), through the Studio hooks. The body
-- runs held (WalkInsPaused true) from the file's fresh(): unseated in the lounge, Quiet on, the phone, WalkIns, Career and
-- Life reset, no hint seen, the rooms hook's Reset (a slot claimed, the plot rebuilt); then the profile is marked
-- (ProfileMark) and the gear dropped. No unlock is staged: the rug and the plant are open from day one (preflight F11).
-- Cells are found from State's live grid with RoomRules.Fits (as t108a), and edits are paced one Config.Rooms.Edit.every
-- + 0.03 s apart. The hook's State and Edit are the Room_Get / Room_Edit remotes' own handlers.
-- (1) WakeUp and Unfill. Every room of the plot has a DecoratePrompt on its door part (the RoomDoor part, beside the
--     ExitPrompt; the door is within 4 studs, flat, of the Entrance anchor): a ProximityPrompt, on, untagged (neither it nor
--     the door is OK_Interactable), ActionText "Decorate" and ObjectText "Your room" (copy 6.1, 6.2), keys R / DPadDown
--     (neither the ExitPrompt's), the house reach (Config.Interaction.MaxDistance, no hold, no line of sight), its UIOffset
--     at least a default prompt's height (72 px) off the ExitPrompt's.
-- (2) Room_Get's cache (Task 9's review M1). The hook's State 20 times back to back: every answer the same and at most one
--     fresh compute (Counts' views). An Edit (a rug) shows in the very next State (the cache is dropped). `inside` is never
--     cached: on the landing (the hook's Exit) it reads nil at once, back in the bedroom (GoIn) "bedroom". GrantGear(kit_tape):
--     tape_machine is in State's unlocked within 3 s (the Gear listener drops the cache). A change nobody tells Rooms of
--     (the Life hook's SetTier BUZZING: the floor lamp opens) shows within VIEW_SECONDS (2) + 1.5 s.
-- (3) The Room remote's "state" (the hook's Pushed): a saved Edit (a plant) pushes exactly one "state" whose bedroom row
--     holds the rug and the plant (used 2); a refused Edit (on the plant's cell: "overlap") pushes nothing; SetHome (empty)
--     pushes a "state" with no items; the hook's Reset (a rebuild) pushes a "state".
-- (4) The DecoratePrompt's handler (the hook's Decorate, the prompt's own path): for the owner, true, exactly one
--     "decorate" { kind = "bedroom" } pushed and nothing toasted; for a room the plot doesn't have ("attic"), false and
--     nothing pushed. (This client goes into decorate mode then; it leaves at the next move, in (5).)
-- (5) Someone else's room: Fill(1) builds plot 2 for a stand-in owner, and its rooms carry their own DecoratePrompt (every
--     client turns off the ones it doesn't own: t109b checks that rule). From plot 2's landing (Enter(2) as a friend) the
--     hook's Decorate answers false, and nothing is pushed or toasted.
-- On any error, and after success: unseated in the lounge, Unfill, everything reset (hold on, Quiet off), the rooms Reset
-- (an empty home), the profile as ProfileMark noted it (the gear) and the career hook's Publish; the error is rethrown.
-- Tail for t109b, after the cleanup and only on success: WakeUp, so the player stands in their bedroom, whose home is
-- empty (State: bedroom used 0, room for items); then (R-T10 fix 1) a floor lamp is saved there through SetHome while the
-- BUZZING tier it needs isn't held (the Life reset above), on a free cell that leaves room for a rug, so it is kept
-- unbuilt: State's bedroom holds it (items 1, used 0) and t109b finds a faint ghost that holds its cell. t109b presses
-- the Decorate prompt and drives the bar from the client.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local CS = game:GetService("CollectionService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local rooms = SOK:WaitForChild("_StudioRoomsHook", 5); assert(rooms, "no _StudioRoomsHook (is Systems/Rooms synced and started?)")
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local Config = require(RS.OK.Config)
local Rules = require(RS.OK.Modules.RoomRules)
local Catalog = require(RS.OK.Data.RoomCatalog)
local RoomBuild = require(RS.OK.Modules.RoomBuild)
local Cfg = Config.Rooms
local LOUNGE = Vector3.new(24, 3, 0)
local PROMPT_H = 72 -- a default ProximityPrompt is 72 px tall
local VIEW_SECONDS = 2 -- Systems/Rooms' Room_Get cache
local RED = " (before the R-T10 sync of Systems/Rooms and Modules/RoomEdit: the expected red)"
local EVERY = Cfg.Edit.every
local out = {}
local T0 = os.clock()
local lastEdit = 0

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function root() local c = p.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = p.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function teleport(pos) -- the test's own move; checked, and tried once more if the client's position won
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
local function unseat()
	local h = hum()
	if h and (h.Sit or h.SeatPart) then h.Sit = false; task.wait(0.4) end
end
local function call(cmd, a, b) return rooms:Invoke(cmd, uid, a, b) end
local function show(v) local okJ, js = pcall(function() return game:GetService("HttpService"):JSONEncode(v) end); return okJ and js or tostring(v) end
-- a table as text, keys sorted, so two equal tables read the same
local function canon(v)
	if type(v) ~= "table" then return tostring(v) end
	local keys = {}
	for k in pairs(v) do table.insert(keys, k) end
	table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
	local parts = {}
	for _, k in ipairs(keys) do table.insert(parts, tostring(k) .. "=" .. canon(v[k])) end
	return "{" .. table.concat(parts, ",") .. "}"
end
local function placeIs(want, label)
	local pl = call("PlaceOf")
	local got = type(pl) == "table" and (tostring(pl.slot) .. "/" .. tostring(pl.kind)) or tostring(pl)
	assert(got == want, label .. ": PlaceOf is " .. got .. ", want " .. want)
end
local function arrivePlace(want, label)
	local ok = waitFor(function()
		local pl = call("PlaceOf")
		return type(pl) == "table" and (tostring(pl.slot) .. "/" .. tostring(pl.kind)) == want
	end, 4)
	if not ok then placeIs(want, label) end
end
local function plotModel(k) local f = workspace:FindFirstChild("OK_Plots"); return f and f:FindFirstChild(string.format("Plot_%02d", k)) end
local function state()
	local s = call("State")
	assert(type(s) == "table" and type(s.rooms) == "table" and type(s.unlocked) == "table", "the rooms hook's State answered " .. show(s) .. ", want { rooms, unlocked, door, inside }")
	return s
end
local function has(list, id) for _, v in ipairs(list) do if v == id then return true end end return false end
-- every lowest cell { cx, cz } where `id` (turned r) fits the room now (t108a's scan)
local function scan(kind, id, r)
	local s = state()
	local set = {}
	for _, u in ipairs(s.unlocked) do set[u] = true end
	local rm = s.rooms[kind]
	assert(rm, "State has no room " .. kind)
	local kc = Cfg.Kinds[kind]
	local found, seen = {}, {}
	for _, a in ipairs(kc.grid) do
		for cx = math.floor(math.min(a[1], a[3])), math.ceil(math.max(a[1], a[3])) do
			for cz = math.floor(math.min(a[2], a[4])), math.ceil(math.max(a[2], a[4])) do
				local key = cx .. ":" .. cz
				if not seen[key] then
					seen[key] = true
					if Rules.Fits(rm.items, { id = id, x = cx, z = cz, r = r or 0 }, kc, Catalog, set, kind, nil, Cfg) then table.insert(found, { cx, cz }) end
				end
			end
		end
	end
	return found
end
local function edit(action)
	local gap = EVERY + 0.03 - (os.clock() - lastEdit)
	if gap > 0 then task.wait(gap) end
	lastEdit = os.clock()
	return call("Edit", action)
end
local function ok(res, label)
	assert(type(res) == "table" and res.ok == true, label .. ": Edit answered " .. show(res) .. ", want ok")
	return res
end
-- the Room remote's messages to the player since the last read
local function pushed(label)
	local log = call("Pushed")
	assert(type(log) == "table", label .. ": the rooms hook's Pushed answered " .. show(log) .. ", want a list" .. RED)
	return log
end
local function counts(label)
	local c = call("Counts")
	assert(type(c) == "table" and type(c.views) == "number", label .. ": the rooms hook's Counts answered " .. show(c) .. ", want { views = n, ... }" .. RED)
	return c
end
local function sent() local s = call("Sent"); return type(s) == "table" and s or {} end

-- the file's own fresh(): unseated in the lounge, Quiet on, the phone, WalkIns, Career and Life reset, no hint seen,
-- the rooms hook's Reset (slot claimed, plot rebuilt)
local function fresh(label)
	unseat()
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, label .. ": Quiet(true) failed")
	assert(ph:Invoke("Reset", uid) == true, label .. ": phone Reset failed")
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	assert(life:Invoke("Reset", uid) == true, label .. ": Life Reset failed")
	assert(test:Invoke("ResetHints", uid) == true, label .. ": ResetHints failed")
	assert(call("Reset") == true, label .. ": the rooms hook's Reset failed (no slot, or the plot did not build)")
end

local function run()
	local mk = test:Invoke("ProfileMark", uid) -- first, before anything changes (the cleanup's ProfileRestore)
	assert(mk == true, "the test hook's ProfileMark answered " .. tostring(mk) .. ", want true")
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh("decorate")
	assert(test:Invoke("ResetGear", uid) == true, "ResetGear failed")

	-- 1. WakeUp, Unfill, and every room's DecoratePrompt
	call("Unfill")
	assert(call("WakeUp") == true, "WakeUp returned false")
	placeIs("1/bedroom", "WakeUp")
	local info = call("Plot")
	assert(type(info) == "table" and info.slot, "the rooms hook's Plot answered " .. show(info))
	local k = info.slot
	local plot = plotModel(k)
	assert(plot, "Workspace.OK_Plots has no Plot_" .. string.format("%02d", k))
	local checked = {}
	for _, kind in ipairs(info.rooms) do
		local room = plot:FindFirstChild("Room_" .. kind)
		assert(room, "Plot_" .. k .. " has no Room_" .. kind)
		local door = RoomBuild.DoorOf(room)
		assert(door, "Room_" .. kind .. " has no RoomDoor part")
		local pp = door:FindFirstChild("DecoratePrompt")
		assert(pp and pp:IsA("ProximityPrompt"), "Room_" .. kind .. "'s door has no DecoratePrompt" .. RED)
		local exit = door:FindFirstChild("ExitPrompt")
		assert(exit and exit:IsA("ProximityPrompt"), "Room_" .. kind .. "'s door has no ExitPrompt")
		assert(pp.Enabled == true, "Room_" .. kind .. ": the DecoratePrompt is off on the server (each client turns off only the ones it doesn't own)")
		assert(pp.ActionText == "Decorate" and pp.ObjectText == "Your room", "Room_" .. kind .. ": the DecoratePrompt reads '" .. pp.ActionText .. "' / '" .. pp.ObjectText .. "', want 'Decorate' / 'Your room' (copy 6.1, 6.2)")
		assert(#CS:GetTags(pp) == 0 and not CS:HasTag(door, "OK_Interactable"), "Room_" .. kind .. ": the DecoratePrompt or its door is tagged (" .. table.concat(CS:GetTags(pp), ",") .. "); it must be untagged")
		assert(pp.KeyboardKeyCode == Enum.KeyCode.R and pp.GamepadKeyCode == Enum.KeyCode.DPadDown, "Room_" .. kind .. ": the DecoratePrompt's keys are "
			.. tostring(pp.KeyboardKeyCode) .. " / " .. tostring(pp.GamepadKeyCode) .. ", want R / DPadDown")
		assert(pp.KeyboardKeyCode ~= exit.KeyboardKeyCode and pp.GamepadKeyCode ~= exit.GamepadKeyCode, "Room_" .. kind .. ": the DecoratePrompt shares a key with the ExitPrompt beside it")
		assert(pp.MaxActivationDistance == Config.Interaction.MaxDistance and pp.HoldDuration == 0 and pp.RequiresLineOfSight == false, string.format(
			"Room_%s: the DecoratePrompt's reach %.1f, hold %.1f, line of sight %s; want %.1f, 0, false (the house style)", kind, pp.MaxActivationDistance, pp.HoldDuration, tostring(pp.RequiresLineOfSight), Config.Interaction.MaxDistance))
		local sep = math.abs(pp.UIOffset.Y - exit.UIOffset.Y)
		assert(sep >= PROMPT_H, string.format("Room_%s: the DecoratePrompt's UI sits %.0f px off the ExitPrompt's (UIOffset %s vs %s), want %d or more", kind, sep, tostring(pp.UIOffset), tostring(exit.UIOffset), PROMPT_H))
		local entrance = call("Anchor", kind, "Entrance")
		assert(typeof(entrance) == "CFrame", "Room_" .. kind .. " has no Entrance anchor")
		local d = flat(door.Position - entrance.Position)
		assert(d <= 4, string.format("Room_%s: the DecoratePrompt's door is %.1f studs from Entrance, want 4 or less (near the Entrance)", kind, d))
		table.insert(checked, string.format("%s (%.1f studs from Entrance, %.0f px over the ExitPrompt)", kind, d, sep))
	end
	table.insert(out, "1 DecoratePrompt on every room's door, untagged, 'Decorate' / 'Your room', R / DPadDown, the house reach: " .. table.concat(checked, "; "))

	-- 2. Room_Get's cache
	counts("2 clear")
	local first = canon(state())
	for i = 2, 20 do
		local again = canon(state())
		assert(again == first, "2: State's answer " .. i .. " of 20 differs from the first:\n  " .. first .. "\n  " .. again)
	end
	local v20 = counts("2").views
	assert(v20 <= 1, "2: 20 back-to-back State calls computed " .. v20 .. " fresh views, want at most 1 (Room_Get's cache)")
	local rugCells = scan("bedroom", "rug")
	assert(#rugCells >= 1, "premise: the bedroom's free floor has no cell where a rug fits")
	local rc = rugCells[1]
	ok(edit({ op = "place", kind = "bedroom", id = "rug", x = rc[1], z = rc[2], r = 0 }), "2 place a rug")
	local s2 = state()
	local items2 = s2.rooms.bedroom.items
	assert(#items2 == 1 and items2[1].id == "rug" and items2[1].x == rc[1] and items2[1].z == rc[2] and s2.rooms.bedroom.used == 1,
		"2: the State right after the Edit reads " .. show(s2.rooms.bedroom) .. ", want the rug at (" .. rc[1] .. ", " .. rc[2] .. ") (the Edit drops the cache)")
	state() -- warm
	local tExit = os.clock()
	assert(call("Exit", "bedroom") == true, "2: the hook's Exit(bedroom) returned false")
	arrivePlace("1/landing", "2 on the landing")
	counts("2 before the landing read")
	local s2l = state()
	local cachedRead = counts("2 landing").views == 0 and os.clock() - tExit < VIEW_SECONDS
	assert(s2l.inside == nil, "2: on the landing State.inside reads " .. tostring(s2l.inside) .. ", want nil (inside is read on every call, never cached)")
	assert(call("GoIn", "bedroom") == true, "2: the hook's GoIn(bedroom) returned false")
	arrivePlace("1/bedroom", "2 back in the bedroom")
	assert(state().inside == "bedroom", "2: back in the bedroom State.inside reads " .. tostring(state().inside) .. ", want bedroom")
	assert(not has(state().unlocked, "tape_machine"), "premise: the tape machine is open before kit_tape")
	assert(test:Invoke("GrantGear", uid, "kit_tape") == true, "2: GrantGear(kit_tape) failed")
	assert(waitFor(function() return has(state().unlocked, "tape_machine") end, 3), "2: the tape machine is not in State's unlocked 3 s after GrantGear(kit_tape) (the Gear listener drops the cache)")
	assert(not has(state().unlocked, "floor_lamp"), "premise: the floor lamp is open before the BUZZING tier")
	assert(life:Invoke("SetTier", uid, "BUZZING") == true, "2: the Life hook's SetTier(BUZZING) failed")
	local tTier = os.clock()
	assert(waitFor(function() return has(state().unlocked, "floor_lamp") end, VIEW_SECONDS + 1.5), "2: the floor lamp (fame tier BUZZING) is not in State's unlocked "
		.. (VIEW_SECONDS + 1.5) .. " s after SetTier: the cache must not outlive " .. VIEW_SECONDS .. " s")
	table.insert(out, string.format("2 Room_Get's cache: 20 back-to-back States the same, %d fresh; an Edit shows at once; inside nil on the landing (%s) and bedroom back in; kit_tape opens the tape machine at once; the BUZZING tier shows after %.1f s (at most %d + 1.5)",
		v20, cachedRead and "a cached read" or "a fresh read", os.clock() - tTier, VIEW_SECONDS))
	assert(life:Invoke("Reset", uid) == true, "2: Life Reset failed")

	-- 3. "state" pushes
	pushed("3 clear")
	local plantCells = {}
	for _, c in ipairs(scan("bedroom", "plant")) do table.insert(plantCells, c) end
	assert(#plantCells >= 1, "premise: no free cell for a plant beside the rug")
	local pc = plantCells[1]
	ok(edit({ op = "place", kind = "bedroom", id = "plant", x = pc[1], z = pc[2] }), "3 place a plant")
	local log3 = pushed("3 after the plant")
	assert(#log3 == 1 and log3[1].kind == "state", "3: a saved Edit pushed " .. show(log3) .. ", want exactly one \"state\"")
	local bed3 = type(log3[1].payload) == "table" and type(log3[1].payload.rooms) == "table" and log3[1].payload.rooms.bedroom
	assert(type(bed3) == "table" and #bed3.items == 2 and bed3.used == 2 and bed3.items[2].id == "plant" and bed3.items[2].x == pc[1] and bed3.items[2].z == pc[2],
		"3: the pushed state's bedroom reads " .. show(bed3) .. ", want the rug and the plant (used 2)")
	local res3 = edit({ op = "place", kind = "bedroom", id = "plant", x = pc[1], z = pc[2] })
	assert(type(res3) == "table" and res3.ok == false and res3.reason == "overlap", "3: a plant on the plant answered " .. show(res3) .. ", want refused 'overlap'")
	local log3b = pushed("3 after the refusal")
	assert(#log3b == 0, "3: a refused Edit pushed " .. show(log3b) .. ", want nothing")
	assert(type(call("SetHome", { v = 1, door = Cfg.DoorDefault, items = {} })) == "table", "3: SetHome failed")
	local log3c = pushed("3 after SetHome")
	local last3 = log3c[#log3c]
	assert(last3 and last3.kind == "state" and type(last3.payload) == "table" and last3.payload.rooms.bedroom and #last3.payload.rooms.bedroom.items == 0,
		"3: SetHome (empty) pushed " .. show(log3c) .. ", want a \"state\" with no bedroom items")
	assert(call("Reset") == true, "3: the rooms hook's Reset failed")
	local log3d = pushed("3 after Reset")
	local rebuiltPush = false
	for _, e in ipairs(log3d) do if e.kind == "state" then rebuiltPush = true end end
	assert(rebuiltPush, "3: the hook's Reset (a rebuild) pushed " .. show(log3d) .. ", want a \"state\"")
	assert(call("WakeUp") == true, "3: WakeUp returned false")
	placeIs("1/bedroom", "3 woken again")
	table.insert(out, "3 pushes: a saved Edit -> one \"state\" (the rug and the plant, used 2); a refused one -> nothing; SetHome -> \"state\" (no items); Reset -> \"state\"")

	-- 4. the DecoratePrompt's handler for the owner
	pushed("4 clear"); sent()
	assert(call("Decorate", "bedroom") == true, "4: the hook's Decorate(bedroom) answered false for the owner")
	local log4 = pushed("4")
	assert(#log4 == 1 and log4[1].kind == "decorate" and type(log4[1].payload) == "table" and log4[1].payload.kind == "bedroom",
		"4: the owner's Decorate pushed " .. show(log4) .. ", want exactly one \"decorate\" { kind = bedroom }")
	local toasts4 = sent()
	assert(#toasts4 == 0, "4: the owner's Decorate toasted " .. show(toasts4))
	assert(call("Decorate", "attic") == false, "4: the hook's Decorate(attic) should answer false (no such room)")
	assert(#pushed("4 attic") == 0, "4: Decorate(attic) pushed something")
	table.insert(out, "4 Decorate for the owner: true, one \"decorate\" { kind = bedroom } pushed, no toast; a room the plot lacks: false, nothing pushed")

	-- 5. someone else's room
	assert(call("Fill", 1) == 1, "5: Fill(1) did not build a stand-in plot")
	local other = plotModel(2)
	assert(other and other:GetAttribute("OwnerId") ~= uid, "5: no Plot_02 for a stand-in owner")
	local obed = other:FindFirstChild("Room_bedroom")
	local odoor = obed and RoomBuild.DoorOf(obed)
	local opp = odoor and odoor:FindFirstChild("DecoratePrompt")
	assert(opp and opp:IsA("ProximityPrompt") and obed:GetAttribute("OwnerId") ~= uid, "5: the stand-in's bedroom has no DecoratePrompt of its own")
	assert(call("Enter", 2, true) == true, "5: the hook's Enter(2) as a friend returned false")
	arrivePlace("2/landing", "5 on plot 2's landing")
	pushed("5 clear"); sent()
	assert(call("Decorate", "bedroom") == false, "5: Decorate from someone else's plot answered true, want false")
	local log5, toasts5 = pushed("5"), sent()
	assert(#log5 == 0 and #toasts5 == 0, "5: Decorate from someone else's plot pushed " .. show(log5) .. " and toasted " .. show(toasts5) .. ", want nothing")
	table.insert(out, "5 someone else's room: plot 2's bedroom has its own DecoratePrompt (OwnerId " .. tostring(obed:GetAttribute("OwnerId")) .. "); from its landing Decorate answers false, nothing pushed or toasted")

	return "T109A PLAY OK\n" .. table.concat(out, "\n") .. string.format("\nelapsed %.1f s", os.clock() - T0)
end

local okRun, msg = pcall(run)
pcall(unseat)
pcall(teleport, LOUNGE) -- first, so the rebuild below never happens under the player
pcall(function() rooms:Invoke("Unfill", uid) end)
pcall(function()
	wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
	test:Invoke("ResetHints", uid); ph:Invoke("Quiet", uid, false)
end)
pcall(function() rooms:Invoke("Reset", uid) end) -- after the career Reset (it replaces prof.career, the home with it)
-- the profile as ProfileMark noted it (the gear)
local restored
pcall(function() restored = test:Invoke("ProfileRestore", uid) end)
pcall(function() career:Invoke("Publish", uid) end)
if not okRun then error(msg, 0) end
assert(restored == true, "cleanup: the test hook's ProfileRestore answered " .. tostring(restored) .. ", want true")
-- tail for t109b, after the cleanup: the player in their bedroom, its home empty
assert(rooms:Invoke("WakeUp", uid) == true, "tail: WakeUp returned false")
local st = rooms:Invoke("State", uid)
local bed = type(st) == "table" and type(st.rooms) == "table" and st.rooms.bedroom
assert(type(bed) == "table" and bed.used == 0 and #bed.items == 0 and st.inside == "bedroom", "tail: State reads " .. show(st) .. ", want an empty bedroom with the player inside")
-- R-T10 fix 1: a floor lamp kept unbuilt (locked: the BUZZING tier isn't held), on a cell a rug can still avoid
assert(not has(st.unlocked, "floor_lamp"), "tail: the floor lamp is open; the Life reset should have taken the BUZZING tier away")
local rugs, lampCell = scan("bedroom", "rug"), nil
for _, c in ipairs(scan("bedroom", "plant")) do
	for _, rc in ipairs(rugs) do
		if not (c[1] >= rc[1] and c[1] < rc[1] + 2 and c[2] >= rc[2] and c[2] < rc[2] + 2) then lampCell = c; break end
	end
	if lampCell then break end
end
assert(lampCell, "tail premise: no free cell for a floor lamp that leaves room for a rug")
local kept = rooms:Invoke("SetHome", uid, { v = 1, door = Cfg.DoorDefault, items = { bedroom = { { id = "floor_lamp", x = lampCell[1], z = lampCell[2], r = 0 } } } })
assert(type(kept) == "table" and type(kept.items.bedroom) == "table" and #kept.items.bedroom == 1, "tail: SetHome did not keep the locked floor lamp: " .. show(kept))
local st2 = rooms:Invoke("State", uid)
local bed2 = type(st2) == "table" and type(st2.rooms) == "table" and st2.rooms.bedroom
assert(type(bed2) == "table" and #bed2.items == 1 and bed2.items[1].id == "floor_lamp" and bed2.used == 0, "tail: State's bedroom reads " .. show(bed2) .. ", want the floor lamp kept unbuilt (items 1, used 0)")
return msg
