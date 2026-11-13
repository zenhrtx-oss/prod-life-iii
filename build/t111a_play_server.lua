-- Server, during play (the Your Rooms plan, Task 12: the home studio's closet and booth), through the Studio hooks. First,
-- before anything changes, the test hook's ProfileMark notes the profile (money, XP and level, gear, the gate logs, the
-- tour, the hints, the sessions) and the tour's steps go into the player attribute _T111Tour ("<got ids>|done|skipped"):
-- t111e, the group's tail, puts both back (two real deliveries happen in t111b and t111d). Then held (WalkInsPaused true),
-- the file's fresh(): unseated in the lounge, Quiet on, the phone, WalkIns, Career and Life reset, no hint seen, the rooms
-- hook's Reset (a slot claimed, the plot rebuilt); then ResetGear (no fit owned) and ResetSessions (no last beat).
-- (1) home_studio bought for real: Career Set at the gate's needs and its price, both read from the live
--     Config.Career.Gates (preflight F8), then Unlock("home_studio"): the plot's rooms read bedroom,home. WakeUp.
-- (2) a closet placed in home through the rooms hook's Edit (the Room_Edit remote's own handler), from the bedroom, at the
--     free cell (RoomRules.Fits on State, every turn) whose front stand spot (2.6 studs ahead of it) is clearest of the
--     room's other E prompts (the laptop, the door; 9.5 studs at least), with the closet's centre outside the booth corner
--     (x >= -3) and 3+ studs from the laptop's stand spot: ok. Room_home.Items holds one closet Model; its Body holds one
--     enabled ProximityPrompt "ClosetPrompt", "Open closet" / "Your closet" (copy 8.1, 8.2), C / DPadRight (its own pair, the
--     R-T12 review's M2: it shares neither key with any other prompt in the room, so a closet beside the desk can't take the
--     laptop's E; nor G, the card prompt's), untagged (not OK_Interactable: Systems/Rooms hooks it), and its Hangers Folder
--     is empty: no fit owned, no hanger.
-- (3) GrantGear("fit_cuban,fit_shades"): within 3 s the same closet Model holds exactly two hangers, Hanger_fit_cuban and
--     Hanger_fit_shades (the owned fits; its Hangers attribute "fit_cuban,fit_shades"), each one bare Part (fix 1: one part
--     a hanger) in Modules/Fits' colour for that fit, anchored, not colliding or touching, queryable, casting no shadow,
--     inside the closet's 3 x 2 cells; no light or MeshPart; the closet's parts are its recipe's plus one a hanger, within
--     Config.Rooms.ItemParts. The Closet prompt is still the one (one ClosetPrompt). GrantGear("fit_snapback"): all three
--     launch fits hang (the Hangers attribute in Config.Gear order: fit_cuban,fit_snapback,fit_shades), the same checks, the
--     closet still within ItemParts (spec/room_rules_spec.lua's HangerCount checks hold it for any number of fits). Then
--     ResetGear and GrantGear("fit_cuban,fit_shades") again: back to those two hangers, for steps 4 on and t111b.
-- (4) the hook's Closet (the prompt's handler) for the owner: acted, the OpenPanel payload sent has tab "Gear", closet
--     true, the closet's Body as its source, and gear (Gear.State) with fit_cuban and fit_shades owned, fit_snapback not;
--     no toast sent.
-- (5) another owner, staged by setting Room_home's OwnerId to -11101 and OwnerName to "Test Owner 7" (preflight m19, as
--     t105a): the hook's Closet doesn't act and sends the toast "Test Owne…'s closet. only they can use it." (copy 8.6, the
--     12-character name cut to 9 plus "…" as every Rooms toast); then no OwnerId at all: it doesn't act and sends nothing.
--     The owner is put back.
-- (6) Booth (the hook's: Systems/Rooms.Booth): of the home Station a table whose spot and cam are Room_home's BoothSpot and
--     BoothCam WorldCFrames (within 0.01 stud, the same facing); of the bedroom's Station false; of the studio PC's screen
--     and a hub laptop (Station_Side.Screen) nil.
-- (7) the budgets: Room_home holds at most 1 light; the hub keeps 12 tagged interactables and 2 Stations (RoomScope.Split).
-- On any error: the full put-back (t111e's: the staged owner back, any play stopped, unseated in the lounge, WalkIns, the
-- phone, Career and Life reset, no hint seen, ResetSessions, the rooms Reset, the tour's noted steps done again, Quiet
-- off, ProfileRestore and the career hook's Publish) and the error rethrown. Tail for t111b, only on success, nothing
-- reset: the staged owner back, GoIn("home") and the player moved to the home stand spot (room-local (3, 0, -6.6): east of
-- the stand-in's chair, clear of its desk, within reach of the laptop, where DAW.StationOf names the home laptop), and
-- request j1 active (SetActiveRequest).
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
local RoomScope = require(RS.OK.Modules.RoomScope)
local Fits = require(RS.OK.Modules.Fits)
local DAWCfg = require(RS.OK.Modules.DAWConfig)
local Tour = require(RS.OK.Systems.Tour) -- its Steps only
local Cfg = Config.Rooms
local LOUNGE = Vector3.new(24, 3, 0)
local STATS = { "aura", "followers", "placements", "hits", "sponsors" }
local GRANT = { "fit_cuban", "fit_shades" } -- the plan's two fits
local HOME_STAND = Vector3.new(3, 0, -6.6) -- room-local (t111b's too)
local OTHER_ID, OTHER_NAME = -11101, "Test Owner 7" -- a 12-character name, not the player's
local TOAST = "Test Owne…'s closet. only they can use it." -- copy 8.6 with OTHER_NAME cut
local RED = " (before the R-T12 sync of Modules/RoomItems, Modules/RoomRules, Modules/Fits, Systems/Rooms and Systems/DAW, and the R-T12/13 review fixes' sync of Systems/Rooms (the closet's C / DPadRight): the expected red)"
local out = {}
local T0 = os.clock()
local staged -- { room, id, name } while another owner is staged on Room_home

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function str(v) return string.format("(%.2f, %.2f, %.2f)", v.X, v.Y, v.Z) end
local function show(v) local okJ, js = pcall(function() return game:GetService("HttpService"):JSONEncode(v) end); return okJ and js or tostring(v) end
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
local function plotModel() local i = call("Plot"); local f = workspace:FindFirstChild("OK_Plots"); return type(i) == "table" and f and f:FindFirstChild(string.format("Plot_%02d", i.slot)) or nil end
local function roomOf(kind) local m = plotModel(); return m and m:FindFirstChild("Room_" .. kind) end
local function roomKinds() local i = call("Plot"); return type(i) == "table" and table.concat(i.rooms, ",") or tostring(i) end
local function gateOf(id) for _, g in ipairs(Config.Career.Gates) do if g.id == id then return g end end end
local function lights(inst) local n = 0; for _, d in ipairs(inst:GetDescendants()) do if d:IsA("Light") then n += 1 end end; return n end
-- the tour, read from the profile, and its note ("<got ids>|done|skipped"), as t124a writes it
local function tourNow()
	local prof = test:Invoke("GetProfile", uid)
	local t = type(prof) == "table" and type(prof.tour) == "table" and prof.tour or {}
	return { done = t.done == true, skipped = t.skipped == true, got = type(t.got) == "table" and t.got or {} }
end
local function tourNote(t)
	local ids = {}
	for _, s in ipairs(Tour.Steps) do if t.got[s.id] then table.insert(ids, s.id) end end
	return table.concat(ids, ",") .. "|" .. (t.done and "done" or "") .. "|" .. (t.skipped and "skipped" or "")
end
local function parseTour(note)
	if type(note) ~= "string" then return nil end
	local ids, done, skipped = string.match(note, "^([^|]*)|([^|]*)|([^|]*)$")
	if not ids then return nil end
	local got = {}
	for id in string.gmatch(ids, "[^,]+") do got[id] = true end
	return { got = got, done = done == "done", skipped = skipped == "skipped" }
end
-- the noted tour on the client's pill again: reset, then its steps done again (or skipped), as t124c
local function restoreTour(before)
	test:Invoke("ResetTour", uid)
	if not before then return end
	if before.skipped then test:Invoke("TourSkip", uid); return end
	for _, s in ipairs(Tour.Steps) do
		if before.done or before.got[s.id] then test:Invoke("TourAdvance", uid, s.id) end
	end
end
local function restoreOwner()
	local s = staged
	staged = nil
	if s and s.room.Parent then s.room:SetAttribute("OwnerId", s.id); s.room:SetAttribute("OwnerName", s.name) end
end
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
-- the edit bar's State and the cells where `id` turned r fits a room now (RoomRules.Fits on it, as t108a's scan)
local function state()
	local s = call("State")
	assert(type(s) == "table" and type(s.rooms) == "table" and type(s.unlocked) == "table", "the rooms hook's State answered " .. show(s))
	return s
end
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
					if Rules.Fits(rm.items, { id = id, x = cx, z = cz, r = r }, kc, Catalog, set, kind, nil, Cfg) then table.insert(found, { cx, cz }) end
				end
			end
		end
	end
	return found
end
local function closetsIn(room)
	local list = {}
	local items = room and room:FindFirstChild("Items")
	for _, m in ipairs(items and items:GetChildren() or {}) do
		if m:IsA("Model") and m:GetAttribute("ItemId") == "closet" then table.insert(list, m) end
	end
	return list
end
local function hangersOf(m)
	local f = m and m:FindFirstChild("Hangers")
	local list = {}
	for _, h in ipairs((f and f:IsA("Folder")) and f:GetChildren() or {}) do table.insert(list, h) end
	table.sort(list, function(a, b) return a.Name < b.Name end)
	return list, f
end
local function prompts(m)
	local list = {}
	for _, d in ipairs(m:GetDescendants()) do if d:IsA("ProximityPrompt") and d.Name == "ClosetPrompt" then table.insert(list, d) end end
	return list
end

-- the full put-back (t111e's), every step tried; returns ProfileRestore's answer and the steps that threw
local function putBack()
	local steps = {}
	local function try(label, fn)
		local good, err = pcall(fn)
		if not good then table.insert(steps, label .. ": " .. tostring(err)) end
	end
	try("hold", function() wi:Invoke("Pause", uid, true) end)
	try("owner", restoreOwner)
	try("stop", function() rooms:Invoke("Stop", uid) end)
	try("unseat", unseat)
	try("lounge", function() teleport(LOUNGE) end) -- first, so the rebuild below never happens under the player
	try("resets", function()
		wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
		test:Invoke("ResetHints", uid); test:Invoke("ResetSessions", uid)
	end)
	try("rooms Reset", function() rooms:Invoke("Reset", uid) end)
	try("tour", function() restoreTour(parseTour(p:GetAttribute("_T111Tour"))) end)
	try("Quiet off", function() ph:Invoke("Quiet", uid, false) end)
	local restored
	try("ProfileRestore", function() restored = test:Invoke("ProfileRestore", uid) end)
	try("Publish", function() career:Invoke("Publish", uid) end)
	p:SetAttribute("_T111Tour", nil)
	return restored, steps
end

local function run()
	local mk = test:Invoke("ProfileMark", uid) -- first, before anything changes (t111e's ProfileRestore)
	assert(mk == true, "the test hook's ProfileMark answered " .. tostring(mk) .. ", want true")
	p:SetAttribute("_T111Tour", tourNote(tourNow()))
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh("closet")
	assert(test:Invoke("ResetGear", uid) == true, "ResetGear failed")
	assert(test:Invoke("ResetSessions", uid) == true, "ResetSessions failed")
	for _, id in ipairs(GRANT) do
		local it
		for _, g in ipairs(Config.Gear) do if g.id == id then it = g end end
		assert(it and it.kind == "fit" and Fits.Colors[it.fit], "premise: Config.Gear has no fit " .. id .. " with a Modules/Fits colour" .. RED)
	end

	-- 1. home_studio bought, needs and price read live (F8)
	local g = gateOf("home_studio")
	assert(g and type(g.cost) == "number", "premise: no home_studio gate with a price in Config.Career.Gates")
	local stage = { money = g.cost }
	for _, stat in ipairs(STATS) do stage[stat] = (g.needs or {})[stat] or 0 end
	assert(career:Invoke("Set", uid, stage) == true, "1: Career Set " .. show(stage) .. " failed")
	local u = career:Invoke("Unlock", uid, "home_studio")
	assert(type(u) == "table" and u.ok == true, "1: Unlock(home_studio) answered " .. show(u))
	assert(waitFor(function() return roomKinds() == "bedroom,home" end, 5), "1: the plot's rooms read '" .. roomKinds() .. "', want bedroom,home")
	assert(call("WakeUp") == true, "1: WakeUp returned false")
	local home = roomOf("home")
	assert(home, "1: the plot has no Room_home")
	table.insert(out, string.format("1 home_studio bought (needs %s, $%d, read live): rooms bedroom,home; woken in the bedroom", show(g.needs or {}), g.cost))

	-- 2. a closet in home, at the free cell whose stand spot is clearest of the laptop's and the door's prompts
	local item = Catalog.ById.closet
	assert(item, "premise: Data/RoomCatalog has no closet")
	local pivot = home:GetPivot()
	local station = call("Station", "home")
	assert(typeof(station) == "Instance" and station:IsDescendantOf(home), "2: the hook's Station(home) is " .. tostring(station) .. ", want the home laptop")
	local door
	for _, d in ipairs(home:GetDescendants()) do if d:IsA("BasePart") and d:GetAttribute("RoomDoor") == true then door = d end end
	assert(door, "2: Room_home has no RoomDoor part")
	local sLocal, dLocal = pivot:PointToObjectSpace(station.Position), pivot:PointToObjectSpace(door.Position)
	local hw, hd = Cfg.Kinds.home.size[1] / 2, Cfg.Kinds.home.size[2] / 2
	local best, bestScore
	for _, r in ipairs({ 0, 1, 2, 3 }) do
		for _, c in ipairs(scan("home", "closet", r)) do
			local cx, cz = Rules.Centre(item, { x = c[1], z = c[2], r = r })
			if cx then
				local front = CFrame.Angles(0, r * math.pi / 2, 0).LookVector
				local stand = Vector3.new(cx, 0, cz) + front * 2.6
				local inside = math.abs(stand.X) <= hw - 1.5 and math.abs(stand.Z) <= hd - 1.5
				local score = math.min(flat(stand - sLocal), flat(stand - dLocal))
				local clearOfDesk = flat(Vector3.new(cx, 0, cz) - HOME_STAND) >= 3 -- the laptop's stand spot stays free
				if inside and clearOfDesk and cx >= -3 and score >= 9.5 and (not bestScore or score > bestScore) then best, bestScore = { x = c[1], z = c[2], r = r }, score end
			end
		end
	end
	assert(best, "premise: no free cell in home puts a closet's front stand spot 9.5+ studs from the laptop and the door, outside the booth corner")
	local res = call("Edit", { op = "place", kind = "home", id = "closet", x = best.x, z = best.z, r = best.r })
	assert(type(res) == "table" and res.ok == true, "2: Edit place closet " .. show(best) .. " answered " .. show(res))
	local list = closetsIn(home)
	assert(#list == 1, "2: Room_home.Items holds " .. #list .. " closets, want 1")
	local closet = list[1]
	local pp = prompts(closet)
	assert(#pp == 1, "2: the closet holds " .. #pp .. " ClosetPrompts, want 1" .. RED)
	local cp = pp[1]
	assert(cp.Parent and cp.Parent.Name == "Body" and cp.Parent.Parent == closet, "2: the ClosetPrompt sits on " .. cp.Parent:GetFullName() .. ", want the closet's Body")
	assert(cp.Enabled and cp.ActionText == "Open closet" and cp.ObjectText == "Your closet", "2: the ClosetPrompt reads '" .. cp.ActionText .. "' / '" .. cp.ObjectText
		.. "' (Enabled " .. tostring(cp.Enabled) .. "), want 'Open closet' / 'Your closet'")
	assert(cp.KeyboardKeyCode == Enum.KeyCode.C and cp.GamepadKeyCode == Enum.KeyCode.DPadRight, "2: the ClosetPrompt's keys are " .. tostring(cp.KeyboardKeyCode) .. " / " .. tostring(cp.GamepadKeyCode)
		.. ", want C / DPadRight" .. RED)
	-- its own pair: no other prompt in the room (the laptop's E, the exit's, the rack's F, decorate's R) shares either key (as t109a's
	-- decorate-vs-exit check), and the card prompt on every character is G / DPadUp
	for _, d in ipairs(home:GetDescendants()) do
		if d:IsA("ProximityPrompt") and d ~= cp then
			assert(d.KeyboardKeyCode ~= cp.KeyboardKeyCode and d.GamepadKeyCode ~= cp.GamepadKeyCode, "2: the ClosetPrompt shares a key with " .. d:GetFullName() .. " ("
				.. tostring(d.KeyboardKeyCode) .. " / " .. tostring(d.GamepadKeyCode) .. ")")
		end
	end
	assert(cp.KeyboardKeyCode ~= Enum.KeyCode.G and cp.GamepadKeyCode ~= Enum.KeyCode.DPadUp, "2: the ClosetPrompt shares a key with the card prompt (G / DPadUp)")
	assert(not CS:HasTag(cp.Parent, "OK_Interactable") and not CS:HasTag(closet, "OK_Interactable"), "2: the closet is tagged OK_Interactable, want untagged (Systems/Rooms hooks it)")
	local hs0, folder0 = hangersOf(closet)
	assert(folder0 and #hs0 == 0, "2: with no fit owned the closet's Hangers " .. (folder0 and ("holds " .. #hs0) or "folder is missing") .. ", want an empty Hangers folder" .. RED)
	table.insert(out, string.format("2 a closet placed in home at %s (its stand spot %.1f+ studs from the laptop and the door): one untagged ClosetPrompt 'Open closet' / 'Your closet' on its Body (C / DPadRight, sharing no key with another prompt in the room); 0 hangers with no fit owned", show(best), bestScore))

	-- 3. fits granted: one one-part hanger each, in its colour, in Config.Gear order; all three launch fits stay within
	--    Config.Rooms.ItemParts (fix 1); then back to the two t111b wants
	local base = #Catalog.ById.closet.parts
	local function grantAndWait(ids, label)
		assert(test:Invoke("GrantGear", uid, table.concat(ids, ",")) == true, label .. ": GrantGear(" .. table.concat(ids, ",") .. ") failed")
	end
	local function hungAre(want, label)
		local hs
		assert(waitFor(function()
			hs = hangersOf(closet)
			local names = {}
			for _, h in ipairs(hs) do table.insert(names, h.Name) end
			return table.concat(names, ",") == want and closet:GetAttribute("Hangers") ~= nil
		end, 3), label .. ": 3 s on the closet's hangers read '" .. (function() local n = {}; for _, h in ipairs(hangersOf(closet)) do table.insert(n, h.Name) end; return table.concat(n, ",") end)()
			.. "', want '" .. want .. "' (the Gear attribute's listener rehangs them)" .. RED)
		return hs
	end
	local cpv = closet:GetPivot()
	local function checkHangers(hs, label)
		for _, h in ipairs(hs) do
			local id = h:GetAttribute("FitId")
			assert(h:IsA("BasePart") and h.Name == "Hanger_" .. tostring(id), label .. ": " .. h:GetFullName() .. " is a " .. h.ClassName .. " (FitId " .. tostring(id) .. "), want one Part Hanger_<id>")
			assert(#h:GetChildren() == 0, label .. ": " .. h.Name .. " has children, want a bare part (one part a hanger)")
			assert(h.Anchored and not h.CanCollide and not h.CanTouch and h.CanQuery and not h.CastShadow, label .. ": " .. h:GetFullName() .. " should be anchored, not colliding or touching, queryable, casting no shadow")
			for _, sx in ipairs({ -1, 1 }) do
				for _, sz in ipairs({ -1, 1 }) do
					local l = cpv:PointToObjectSpace(h.CFrame:PointToWorldSpace(Vector3.new(h.Size.X / 2 * sx, 0, h.Size.Z / 2 * sz)))
					assert(math.abs(l.X) <= 1.5 + 0.01 and math.abs(l.Z) <= 1 + 0.01, label .. ": " .. h.Name .. " reaches " .. str(l) .. " closet-local, outside its 3 x 2 cells")
				end
			end
			local fit
			for _, gr in ipairs(Config.Gear) do if gr.id == id then fit = gr.fit end end
			local want = Fits.Colors[fit]
			local c = h.Color
			assert(want and math.abs(c.R - want.R) + math.abs(c.G - want.G) + math.abs(c.B - want.B) < 0.02, label .. ": " .. h.Name .. " is " .. tostring(c) .. ", want Fits.Colors." .. tostring(fit))
		end
		local parts = 0
		for _, d in ipairs(closet:GetDescendants()) do
			if d:IsA("BasePart") then parts += 1 end
			assert(not d:IsA("Light") and not d:IsA("MeshPart") and not d:IsA("BaseScript"), label .. ": " .. d:GetFullName() .. " is a " .. d.ClassName)
		end
		assert(parts == base + #hs, label .. ": the closet holds " .. parts .. " parts, want its recipe's " .. base .. " + " .. #hs .. " hangers")
		assert(parts <= Cfg.ItemParts, label .. ": the closet holds " .. parts .. " parts, over Config.Rooms.ItemParts " .. Cfg.ItemParts .. " (fix 1)")
		return parts
	end
	grantAndWait(GRANT, "3")
	local hs2 = hungAre("Hanger_fit_cuban,Hanger_fit_shades", "3 two fits")
	assert(closet.Parent ~= nil and #closetsIn(home) == 1 and closetsIn(home)[1] == closet, "3: the closet model was rebuilt by the grant, want the same one kept")
	assert(closet:GetAttribute("Hangers") == "fit_cuban,fit_shades", "3: the closet's Hangers attribute is " .. tostring(closet:GetAttribute("Hangers")) .. ", want fit_cuban,fit_shades")
	assert(#prompts(closet) == 1, "3: the closet holds " .. #prompts(closet) .. " ClosetPrompts after the rehang, want 1")
	local parts2 = checkHangers(hs2, "3 two fits")
	grantAndWait({ "fit_snapback" }, "3")
	local hs3 = hungAre("Hanger_fit_cuban,Hanger_fit_shades,Hanger_fit_snapback", "3 all three fits")
	assert(closet:GetAttribute("Hangers") == "fit_cuban,fit_snapback,fit_shades", "3: with all three fits the Hangers attribute is " .. tostring(closet:GetAttribute("Hangers"))
		.. ", want fit_cuban,fit_snapback,fit_shades (Config.Gear order)")
	local parts3 = checkHangers(hs3, "3 all three fits")
	assert(test:Invoke("ResetGear", uid) == true, "3: ResetGear failed")
	grantAndWait(GRANT, "3")
	hungAre("Hanger_fit_cuban,Hanger_fit_shades", "3 back to two fits")
	assert(closet:GetAttribute("Hangers") == "fit_cuban,fit_shades", "3: back to two fits the Hangers attribute is " .. tostring(closet:GetAttribute("Hangers")))
	table.insert(out, string.format("3 GrantGear(fit_cuban,fit_shades): within 3 s the same closet holds Hanger_fit_cuban and Hanger_fit_shades, one part each in the fit's colour, inside its cells (%d parts); with fit_snapback too, three in Config.Gear order (%d parts <= ItemParts %d); back to the two; still one prompt",
		parts2, parts3, Cfg.ItemParts))

	-- 4. the owner's press: the closet panel
	call("Sent") -- drops what is pending
	local o = call("Closet", "home")
	assert(type(o) == "table", "4: the hook's Closet answered " .. show(o) .. ", want { acted, payload }" .. RED)
	local pay = type(o.payload) == "table" and o.payload or {}
	assert(o.acted == true and pay.tab == "Gear" and pay.closet == true, "4: the owner's Closet: acted " .. tostring(o.acted) .. ", payload tab " .. tostring(pay.tab)
		.. ", closet " .. tostring(pay.closet) .. "; want acted, Gear, true")
	assert(type(pay.source) == "string" and pay.source == closet.Body:GetFullName(), "4: the payload's source is " .. tostring(pay.source) .. ", want " .. closet.Body:GetFullName())
	local owned = {}
	for _, it in ipairs(type(pay.gear) == "table" and type(pay.gear.items) == "table" and pay.gear.items or {}) do owned[it.id] = it.owned end
	assert(owned.fit_cuban == true and owned.fit_shades == true and owned.fit_snapback == false, "4: the payload's gear reads fit_cuban " .. tostring(owned.fit_cuban)
		.. ", fit_shades " .. tostring(owned.fit_shades) .. ", fit_snapback " .. tostring(owned.fit_snapback) .. "; want true, true, false (Gear.State)")
	local sent = call("Sent")
	assert(type(sent) == "table" and #sent == 0 and o.toast == nil, "4: the owner's Closet sent toasts: " .. show(sent))
	table.insert(out, "4 the owner's Closet: OpenPanel { tab Gear, closet true, source the Body, gear: cuban and shades owned, snapback not }; no toast")

	-- 5. another owner, then none
	staged = { room = home, id = home:GetAttribute("OwnerId"), name = home:GetAttribute("OwnerName") }
	assert(staged.id == uid, "5: Room_home's OwnerId is " .. tostring(staged.id) .. " before the staging, want " .. uid)
	home:SetAttribute("OwnerId", OTHER_ID); home:SetAttribute("OwnerName", OTHER_NAME)
	local o2 = call("Closet", "home")
	assert(type(o2) == "table" and o2.acted == false and o2.toast == TOAST and o2.payload == nil, "5: another owner's Closet answered " .. show(o2) .. ", want not acted with '" .. TOAST .. "'")
	local sent2 = call("Sent")
	assert(type(sent2) == "table" and #sent2 == 1 and sent2[1] == TOAST, "5: the toasts sent are " .. show(sent2) .. ", want just '" .. TOAST .. "'")
	home:SetAttribute("OwnerId", nil)
	local o3 = call("Closet", "home")
	assert(type(o3) == "table" and o3.acted == false and o3.toast == nil, "5: with no OwnerId the Closet answered " .. show(o3) .. ", want not acted, no toast")
	local sent3 = call("Sent")
	assert(type(sent3) == "table" and #sent3 == 0, "5: with no OwnerId toasts were sent: " .. show(sent3))
	restoreOwner()
	assert(home:GetAttribute("OwnerId") == uid, "5: the owner was not put back")
	table.insert(out, "5 OwnerId " .. OTHER_ID .. " / '" .. OTHER_NAME .. "': not acted, toast '" .. TOAST .. "'; no OwnerId: not acted, nothing sent; owner put back")

	-- 6. Booth of each place
	local b = call("Booth", station)
	assert(type(b) == "table" and typeof(b.spot) == "CFrame" and typeof(b.cam) == "CFrame", "6: Booth(home laptop) answered " .. show(b) .. ", want { spot, cam }" .. RED)
	local spotA, camA = call("Anchor", "home", "BoothSpot"), call("Anchor", "home", "BoothCam")
	assert(typeof(spotA) == "CFrame" and typeof(camA) == "CFrame", "6: Room_home has no BoothSpot / BoothCam anchor (the hook's Anchor)")
	assert((b.spot.Position - spotA.Position).Magnitude < 0.01 and b.spot.LookVector:Dot(spotA.LookVector) > 0.999, "6: Booth's spot " .. str(b.spot.Position) .. " is not BoothSpot " .. str(spotA.Position))
	assert((b.cam.Position - camA.Position).Magnitude < 0.01 and b.cam.LookVector:Dot(camA.LookVector) > 0.999, "6: Booth's cam " .. str(b.cam.Position) .. " is not BoothCam " .. str(camA.Position))
	local bedSt = call("Station", "bedroom")
	assert(typeof(bedSt) == "Instance", "6: the hook's Station(bedroom) answered " .. tostring(bedSt))
	local bb = call("Booth", bedSt)
	assert(bb == false, "6: Booth(bedroom laptop) answered " .. show(bb) .. ", want false (a room with no booth)")
	local cr = workspace.OKStudio.ControlRoom
	local pc = cr:FindFirstChild("Screen_Main")
	assert(pc, "no OKStudio.ControlRoom.Screen_Main")
	assert(call("Booth", pc) == nil, "6: Booth(the studio PC's screen) should be nil (the hub)")
	local side = cr:FindFirstChild("Station_Side") and cr.Station_Side:FindFirstChild("Screen")
	if side then assert(call("Booth", side) == nil, "6: Booth(the hub laptop) should be nil (the hub)") end
	table.insert(out, string.format("6 Booth: home laptop -> spot %s, cam %s (its anchors); bedroom laptop -> false; the studio PC%s -> nil", str(b.spot.Position), str(b.cam.Position), side and " and a hub laptop" or ""))

	-- 7. budgets
	assert(lights(home) <= 1, "7: Room_home holds " .. lights(home) .. " lights, want at most 1")
	local inWs = {}
	for _, t in ipairs(CS:GetTagged("OK_Interactable")) do if t:IsDescendantOf(workspace) then table.insert(inWs, t) end end
	local hub = RoomScope.Split(inWs)
	local hubStations = 0
	for _, t in ipairs(hub) do if t:GetAttribute("Kind") == "Station" then hubStations += 1 end end
	assert(#hub == 12 and hubStations == 2, "7: the hub holds " .. #hub .. " tagged interactables and " .. hubStations .. " Stations, want 12 and 2")
	table.insert(out, string.format("7 Room_home %d light; the hub %d tagged, %d Stations", lights(home), #hub, hubStations))
	return "T111A PLAY OK\n" .. table.concat(out, "\n") .. string.format("\nelapsed %.1f s", os.clock() - T0)
end

local ok, msg = pcall(run)
if not ok then
	local restored, steps = putBack()
	error(msg .. (#steps > 0 and ("\n(the put-back also hit: " .. table.concat(steps, "; ") .. ")") or "")
		.. (restored ~= true and "\n(ProfileRestore answered " .. tostring(restored) .. ")" or ""), 0)
end
-- tail for t111b, nothing reset: the owner (put back in step 5), the player at the home laptop, request j1 active
pcall(restoreOwner)
assert(rooms:Invoke("GoIn", uid, "home") == true, "tail: GoIn(home) returned false")
local home = roomOf("home")
assert(home, "tail: no Room_home")
local st = rooms:Invoke("Station", uid, "home")
teleport((home:GetPivot() * CFrame.new(HOME_STAND)).Position + Vector3.new(0, 3, 0))
local reach = DAWCfg.CloseDistance + 4
assert(typeof(st) == "Instance" and (root().Position - st.Position).Magnitude <= reach, "tail: the home stand spot is not within " .. reach .. " studs of the home laptop")
local so = rooms:Invoke("StationOf", uid)
assert(type(so) == "table" and so.inst == st and so.room == home, "tail: StationOf at the home stand spot is " .. show(so) .. ", want the home laptop")
assert(test:Invoke("SetActiveRequest", uid, "j1") == true, "tail: SetActiveRequest(j1) failed")
return msg
