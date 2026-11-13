-- Server, during play (the Your Rooms plan, Task 11: your walls show your career), through the Studio hooks. The body runs
-- held (WalkInsPaused true) from the file's fresh(): unseated in the lounge, Quiet on, the phone, WalkIns, Career and Life
-- reset, no hint seen, the rooms hook's Reset (a slot claimed, the plot rebuilt). The plaques are read from the world (the
-- server's Room_<kind>.Plaques folders), and checked against RoomRules.Plaques over the profile's own disco and weekly lists
-- (the test hook's GetProfile copy), so the order and the words are the live data's, never hard-coded; the room and slot of
-- the nth plaque come from Config.Rooms.Kinds.<kind>.plaques in ladder order, and each model's pivot from the rooms hook's
-- Anchor(kind, "Plaque_n"). A career event is driven the way production does it (Systems/WalkIns.apply): the Career hook's Add
-- (the stat, which sets the Placements or Hits attribute) and then the Life hook's Event (the discography row). Those are two
-- hook calls, not production's one thread, so the deferred rebuild the attribute queues may read the lists before the row lands:
-- Systems/Rooms' 1 s signature check then catches the row up, which every wait below (2 s or more) allows for.
-- (0) RoomItems.Plaque exists. Fresh: no plaques (the weekly list is cleared first: nothing in fresh() clears prof.plaques,
--     and an earlier test, t25's weekly single, may have left one).
-- (1) one placement (Career Add placements, Life Event placement { v = navx, key = navx_placement }, the parody roster): one
--     plaque in the bedroom's slot 1 within 2 s, silver, reading LifeRules.DiscoText's line, which has "LIL NAV X"; the model is
--     a RoomItems.Plaque (<= 3 parts, one SurfaceGui, anchored, no collide, touch or raycast, no light, mesh or script), pivoted
--     on the Plaque_1 anchor.
-- (2) two more placements and two hits (5 earned, the bedroom's 3 slots): 3 plaques, the two hits first (gold, the newest
--     first), then the newest placement (silver); each plaque on its Plaque_n anchor.
-- (3) the home studio, bought for real (Career Set at the live gate's needs and price, Unlock home_studio; the numbers are read
--     from Config.Career.Gates): all 5 hang, the first three unchanged in the bedroom and the other two in home's slots 1 and 2.
-- (4) weekly singles (SetWeekly: prof.plaques and its Plaques attribute): one -> a 6th plaque, blue, in home's slot 3, reading
--     copy 7.4 "WEEKLY SINGLE · GOLD TAPE"; three entries, the middle one with no title -> two plaques, the newest first, no gap.
-- (5) the item limit is unchanged: with 7 plaques hung the bedroom still takes exactly Config limit items through the real edit
--     path (State used = limit), the next is refused "limit", the plaques are the same models after the edits, none is in Items,
--     and home's limit and used are untouched.
-- (6) a rejoin (Release and Claim): the rebuilt plot hangs the same plaques in the same slots (the build path, not the listener's).
-- On any error, and after success: unseated in the lounge, Unfill, the career Reset (the plot back to the bedroom), everything
-- else reset (hold on, Quiet off), then the rooms Reset and the noted home put back, the weekly list put back, then the profile
-- as ProfileMark noted it and the career hook's Publish; the error is rethrown.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
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
local LifeRules = require(RS.OK.Modules.LifeRules)
local Catalog = require(RS.OK.Data.RoomCatalog)
local Items = require(RS.OK.Modules.RoomItems)
local W = require(RS.OK.Data.WalkIns)
local Cfg = Config.Rooms
local LOUNGE = Vector3.new(24, 3, 0)
local STATS = { "aura", "followers", "placements", "hits", "sponsors" }
local RED = " (before the R-T11 sync of Modules/RoomItems, Modules/RoomBuild, Systems/Rooms and Systems/Career: the expected red)"
local EVERY = Cfg.Edit.every
local out = {}
local T0 = os.clock()
local homeBefore -- the saved home as the file found it, put back at the end
local weeklyBefore -- prof.plaques as the file found it, put back at the end
local lastEdit = 0

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function root() local c = p.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = p.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function str(v) return typeof(v) == "Vector3" and string.format("(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z) or tostring(v) end
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
local function gateOf(id) for _, g in ipairs(Config.Career.Gates) do if g.id == id then return g end end end

-- the plot, its rooms and what hangs in them
local function plotModel()
	local info = call("Plot")
	local f = workspace:FindFirstChild("OK_Plots")
	return info and f and f:FindFirstChild(string.format("Plot_%02d", info.slot)) or nil
end
local function roomKinds() local i = call("Plot"); return type(i) == "table" and table.concat(i.rooms, ",") or tostring(i) end
local function ownedKinds() local i = call("Plot"); return type(i) == "table" and i.rooms or {} end
local function roomOf(kind) local m = plotModel(); return m and m:FindFirstChild("Room_" .. kind) end
local function labelOf(m) -- the plaque's words
	local board = m:FindFirstChild("Board")
	local gui = board and board:FindFirstChild("Face")
	local label = gui and gui:FindFirstChild("Label")
	return label and label.Text or nil
end
-- every plaque model of the rooms you own, ladder order then slot order: { room, slot, model, text }
local function hung()
	local list = {}
	for _, kind in ipairs(ownedKinds()) do
		local room = roomOf(kind)
		local folder = room and room:FindFirstChild("Plaques")
		if folder then
			local ms = {}
			for _, m in ipairs(folder:GetChildren()) do if m:IsA("Model") then table.insert(ms, m) end end
			table.sort(ms, function(a, b) return (a:GetAttribute("Slot") or 0) < (b:GetAttribute("Slot") or 0) end)
			for _, m in ipairs(ms) do table.insert(list, { room = kind, slot = m:GetAttribute("Slot"), model = m, text = labelOf(m) }) end
		end
	end
	return list
end
local function slotsOf(kinds) -- the (room, slot) of the nth plaque, ladder order, from Config
	local plan = {}
	for _, kind in ipairs(kinds) do
		for slot = 1, Cfg.Kinds[kind].plaques do table.insert(plan, { room = kind, slot = slot }) end
	end
	return plan
end
-- what the profile earns, as Rules.Plaques lists it with the words the copy doc fixes: { { kind, text } }
local function expected()
	local kinds = ownedKinds()
	local plan = slotsOf(kinds)
	local prof = test:Invoke("GetProfile", uid)
	assert(type(prof) == "table", "the test hook's GetProfile answered " .. tostring(prof))
	local weekly = {}
	for _, w in ipairs(prof.plaques or {}) do if type(w.t) == "string" and w.t ~= "" then table.insert(weekly, w) end end -- a plaque with no title reads nothing
	local names = { visitors = W.Names("parody") }
	local rows = {}
	for _, row in ipairs(Rules.Plaques((prof.life or {}).disco, weekly, #plan)) do
		local text = row.kind == "weekly" and ("WEEKLY SINGLE · " .. string.upper(row.entry.t)) or LifeRules.DiscoText(row.entry, names)
		table.insert(rows, { kind = row.kind, text = text })
	end
	return rows, plan
end
-- does the world hang what the profile earns? (true) or why not (false, why)
local function wallState()
	local rows, plan = expected()
	local got = hung()
	if #got ~= #rows then return false, string.format("%d plaques hang, the career earns %d", #got, #rows) end
	for i, row in ipairs(rows) do
		local g, want = got[i], plan[i]
		if g.room ~= want.room or g.slot ~= want.slot then
			return false, string.format("plaque %d hangs in %s slot %s, want %s slot %d", i, tostring(g.room), tostring(g.slot), want.room, want.slot)
		end
		if g.text ~= row.text then return false, string.format("plaque %d reads '%s', want '%s'", i, tostring(g.text), tostring(row.text)) end
		if g.model:GetAttribute("PlaqueKind") ~= row.kind then
			return false, string.format("plaque %d is a '%s' plaque, want '%s'", i, tostring(g.model:GetAttribute("PlaqueKind")), row.kind)
		end
	end
	return true
end
local function expectWall(label, secs)
	local good, why
	waitFor(function() good, why = wallState(); return good end, secs or 2)
	good, why = wallState()
	assert(good, label .. ": " .. tostring(why) .. RED)
	return hung()
end
local function sig(list) -- the words and the places, for "the same plaques"
	local parts = {}
	for _, g in ipairs(list) do table.insert(parts, g.room .. "/" .. tostring(g.slot) .. "=" .. tostring(g.text)) end
	return table.concat(parts, " | ")
end
local function classOf(c) -- the frame's colour as gold, silver or blue
	if c.B - c.R > 0.3 then return "blue" end
	if c.R > 0.6 and c.R - c.B > 0.4 and c.G - c.B > 0.3 then return "gold" end
	if math.abs(c.R - c.G) < 0.1 and math.abs(c.G - c.B) < 0.1 and c.R > 0.6 then return "silver" end
	return "other"
end
local COLOUR = { hit = "gold", placement = "silver", trackone = "silver", weekly = "blue" }
-- one plaque model, as RoomItems.Plaque promises, on its anchor, in the colour of its kind
local function checkPlaque(g, label)
	local m = g.model
	assert(m.Name == "RoomPlaque_" .. g.slot and m:GetAttribute("RoomItem") == "plaque", label .. ": " .. m:GetFullName() .. " is not a RoomPlaque_" .. g.slot)
	assert(m.Parent and m.Parent.Name == "Plaques" and m.Parent:GetAttribute("RoomPlaques") == true and not m:FindFirstAncestor("Items"),
		label .. ": the plaque is in " .. tostring(m.Parent and m.Parent:GetFullName()) .. ", want the room's Plaques folder, outside Items")
	local parts, guis = 0, 0
	for _, d in ipairs(m:GetDescendants()) do
		assert(not d:IsA("Light") and not d:IsA("MeshPart") and not d:IsA("BaseScript") and not d:IsA("Sound"), label .. ": " .. d:GetFullName() .. " is a " .. d.ClassName)
		if d:IsA("BasePart") then
			parts += 1
			assert(d.Anchored and not d.CanCollide and not d.CanTouch and not d.CanQuery, string.format("%s: %s Anchored %s, CanCollide %s, CanTouch %s, CanQuery %s; want anchored and none of the rest",
				label, d:GetFullName(), tostring(d.Anchored), tostring(d.CanCollide), tostring(d.CanTouch), tostring(d.CanQuery)))
			assert(not d.CastShadow or math.max(d.Size.X, d.Size.Y, d.Size.Z) >= Items.SMALL, label .. ": " .. d:GetFullName() .. " casts a shadow though it is small")
		elseif d:IsA("SurfaceGui") then
			guis += 1
		end
	end
	assert(parts >= 1 and parts <= 3 and guis == 1, label .. ": the plaque has " .. parts .. " parts and " .. guis .. " SurfaceGuis, want at most 3 and 1")
	local frame = m:FindFirstChild("Frame")
	assert(frame and frame:IsA("BasePart"), label .. ": the plaque has no Frame part")
	local want = COLOUR[m:GetAttribute("PlaqueKind")]
	assert(classOf(frame.Color) == want, string.format("%s: a %s plaque's frame reads as %s (%s), want %s", label, tostring(m:GetAttribute("PlaqueKind")), classOf(frame.Color), tostring(frame.Color), tostring(want)))
	local a = call("Anchor", g.room, "Plaque_" .. g.slot)
	assert(typeof(a) == "CFrame", label .. ": the rooms hook has no " .. g.room .. " Plaque_" .. g.slot .. " anchor")
	local pv = m:GetPivot()
	assert((pv.Position - a.Position).Magnitude < 0.02, label .. ": the plaque's pivot is at " .. str(pv.Position) .. ", want the anchor " .. str(a.Position))
	assert(pv.LookVector:Dot(a.LookVector) > 0.999, label .. ": the plaque faces " .. str(pv.LookVector) .. ", the anchor faces " .. str(a.LookVector))
	local text = labelOf(m)
	assert(type(text) == "string" and text ~= "", label .. ": the plaque has no words")
end

-- the edit bar's State, and the free cells for a plant (the live grid and keep areas; RoomRules.Fits itself)
local function state()
	local s = call("State")
	assert(type(s) == "table" and type(s.rooms) == "table" and type(s.unlocked) == "table", "the rooms hook's State answered " .. show(s))
	return s
end
local function scan(kind, id)
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
					if Rules.Fits(rm.items, { id = id, x = cx, z = cz, r = 0 }, kc, Catalog, set, kind, nil, Cfg) then table.insert(found, { cx, cz }) end
				end
			end
		end
	end
	return found
end
local function edit(action) -- an edit through the remote's own handler, paced so the bucket never runs dry
	local gap = EVERY + 0.03 - (os.clock() - lastEdit)
	if gap > 0 then task.wait(gap) end
	lastEdit = os.clock()
	return call("Edit", action)
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
-- a career event as production drives it (Systems/WalkIns.apply): the stat first (its attribute), then the discography row
local function earn(stat, kind, visitor, key)
	local gained = career:Invoke("Add", uid, stat, 1, "WalkIn")
	assert(gained == 1, "Career Add " .. stat .. " answered " .. tostring(gained) .. ", want 1")
	local res = life:Invoke("Event", uid, kind, { v = visitor, key = key })
	assert(type(res) == "table" and type(res.disco) == "table" and res.disco.kind == kind, "Life Event " .. kind .. " answered " .. show(res) .. ", want a discography row")
	return res.disco
end

local function run()
	local mk = test:Invoke("ProfileMark", uid) -- first, before anything changes (the cleanup's ProfileRestore)
	assert(mk == true, "the test hook's ProfileMark answered " .. tostring(mk) .. ", want true")
	homeBefore = call("Home")
	local prof0 = test:Invoke("GetProfile", uid)
	weeklyBefore = type(prof0) == "table" and prof0.plaques or {}
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	assert(call("SetWeekly", {}) ~= nil, "the rooms hook has no SetWeekly" .. RED)
	fresh("plaques")
	assert(life:Invoke("SetRoster", uid, "parody") ~= nil, "Life SetRoster(parody) failed")

	-- 0. a fresh career hangs nothing
	assert(type(Items.Plaque) == "function", "RoomItems has no Plaque" .. RED)
	assert(roomKinds() == "bedroom", "premise: the fresh plot's rooms read '" .. roomKinds() .. "', want bedroom")
	for slot = 1, Cfg.Kinds.bedroom.plaques do
		assert(typeof(call("Anchor", "bedroom", "Plaque_" .. slot)) == "CFrame", "premise: the bedroom has no Plaque_" .. slot .. " anchor")
	end
	assert(#hung() == 0, "0: a fresh career hangs " .. #hung() .. " plaques, want none")
	table.insert(out, "0 fresh: the weekly list cleared, Career and Life reset: no plaques hang; RoomItems.Plaque exists; the bedroom has its " .. Cfg.Kinds.bedroom.plaques .. " Plaque anchors")

	-- 1. one placement
	local d1 = earn("placements", "placement", "navx", "navx_placement")
	local line1 = LifeRules.DiscoText(d1, { visitors = W.Names("parody") })
	assert(type(line1) == "string" and string.find(line1, "LIL NAV X", 1, true) and string.find(line1, "PLACEMENT", 1, true), "premise: DiscoText reads '" .. tostring(line1) .. "', want LIL NAV X and PLACEMENT")
	local t1 = os.clock()
	local got1 = expectWall("1 one placement", 2)
	local took = os.clock() - t1
	assert(#got1 == 1 and got1[1].room == "bedroom" and got1[1].slot == 1 and got1[1].text == line1, "1: the wall reads " .. sig(got1) .. ", want bedroom/1 '" .. line1 .. "'")
	checkPlaque(got1[1], "1 plaque")
	table.insert(out, string.format("1 one placement (Career Add, then Life Event): bedroom Plaque_1 hangs in %.2f s reading '%s' (silver, on its anchor, <= 3 parts and one SurfaceGui)", took, line1))

	-- 2. five earned, three slots: the hits first
	local others = {}
	for _, v in ipairs(W.Visitors) do if v.id ~= "navx" and #others < 4 then table.insert(others, v.id) end end
	assert(#others == 4, "premise: Data/WalkIns has fewer than 5 visitors")
	earn("placements", "placement", others[1], others[1] .. "_placement")
	earn("placements", "placement", others[2], others[2] .. "_placement")
	earn("hits", "hit", others[3], others[3] .. "_hit")
	earn("hits", "hit", others[4], others[4] .. "_hit")
	local got2 = expectWall("2 two hits and three placements", 2)
	assert(#got2 == Cfg.Kinds.bedroom.plaques, "2: " .. #got2 .. " plaques hang with only the bedroom, want " .. Cfg.Kinds.bedroom.plaques)
	assert(got2[1].model:GetAttribute("PlaqueKind") == "hit" and got2[2].model:GetAttribute("PlaqueKind") == "hit" and got2[3].model:GetAttribute("PlaqueKind") == "placement",
		"2: the plaques are " .. sig(got2) .. ", want the two hits first, then a placement")
	assert(string.find(got2[1].text, "HIT", 1, true) and string.find(got2[2].text, "HIT", 1, true), "2: the hits read '" .. got2[1].text .. "' and '" .. got2[2].text .. "', want HIT lines")
	for _, g in ipairs(got2) do checkPlaque(g, "2 plaque " .. g.slot) end
	local classes = {}
	for _, g in ipairs(got2) do classes[#classes + 1] = classOf(g.model.Frame.Color) end
	assert(table.concat(classes, ",") == "gold,gold,silver", "2: the frames read " .. table.concat(classes, ",") .. ", want gold,gold,silver")
	local sig2 = sig(got2)
	table.insert(out, "2 five earned, three slots: the bedroom hangs " .. sig2)

	-- 3. the home studio takes the rest
	local g = gateOf("home_studio")
	assert(g and type(g.cost) == "number", "premise: no home_studio gate with a price in Config.Career.Gates")
	local have = career:Invoke("Get", uid)
	local stage = { money = g.cost }
	for _, stat in ipairs(STATS) do stage[stat] = math.max(have[stat] or 0, (g.needs or {})[stat] or 0) end
	assert(career:Invoke("Set", uid, stage) == true, "3: Career Set " .. show(stage) .. " failed")
	local u = career:Invoke("Unlock", uid, "home_studio")
	assert(type(u) == "table" and u.ok == true, "3: Unlock(home_studio) answered " .. show(u))
	assert(waitFor(function() return roomKinds() == "bedroom,home" end, 5), "3: the plot's rooms read '" .. roomKinds() .. "', want bedroom,home")
	local got3 = expectWall("3 the home studio", 3)
	assert(#got3 == 5 and got3[4].room == "home" and got3[4].slot == 1 and got3[5].room == "home" and got3[5].slot == 2, "3: the wall reads " .. sig(got3) .. ", want 3 in the bedroom and 2 in home")
	for i = 1, 3 do assert(got3[i].text == got2[i].text and got3[i].room == "bedroom", "3: bedroom plaque " .. i .. " moved or changed when home opened: '" .. got3[i].text .. "'") end
	for _, x in ipairs(got3) do checkPlaque(x, "3 plaque " .. x.room .. "/" .. x.slot) end
	table.insert(out, "3 home studio (bought for $" .. g.cost .. " at the live gate's needs): all 5 hang, the bedroom's 3 unchanged and the other 2 in home's slots 1 and 2")

	-- 4. weekly singles
	assert(type(call("SetWeekly", { { w = 1, t = "Gold Tape", a = "" } })) == "table", "4: SetWeekly failed")
	local got4 = expectWall("4 a weekly single", 2)
	assert(#got4 == 6 and got4[6].room == "home" and got4[6].slot == 3 and got4[6].text == "WEEKLY SINGLE · GOLD TAPE" and got4[6].model:GetAttribute("PlaqueKind") == "weekly",
		"4: the wall reads " .. sig(got4) .. ", want the weekly single 'WEEKLY SINGLE · GOLD TAPE' as home's slot 3")
	checkPlaque(got4[6], "4 weekly plaque")
	assert(classOf(got4[6].model.Frame.Color) == "blue", "4: the weekly plaque's frame is not blue")
	for i = 1, 5 do assert(got4[i].text == got3[i].text, "4: plaque " .. i .. " changed when the weekly one came") end
	assert(type(call("SetWeekly", { { w = 1, t = "Gold Tape", a = "" }, { w = 2, t = "", a = "" }, { w = 3, t = "Main Stage", a = "" } })) == "table", "4: SetWeekly (3) failed")
	local got4b = expectWall("4 three weekly entries", 2)
	assert(#got4b == 7 and got4b[6].text == "WEEKLY SINGLE · MAIN STAGE" and got4b[7].text == "WEEKLY SINGLE · GOLD TAPE",
		"4: the wall reads " .. sig(got4b) .. ", want the newest weekly first (MAIN STAGE, then GOLD TAPE) and the one with no title dropped with no gap")
	table.insert(out, "4 weekly singles: one hangs as home's slot 3, blue, 'WEEKLY SINGLE · GOLD TAPE' (copy 7.4); three entries (the middle one with no title) hang the newest first with no gap")

	-- 5. the item limit is unchanged (an edit needs you inside your plot: woken in the bedroom)
	assert(call("WakeUp") == true, "5: WakeUp returned false")
	assert(waitFor(function()
		local pl = call("PlaceOf")
		return type(pl) == "table" and pl.kind == "bedroom" and pl.slot == call("Plot").slot
	end, 4), "5: WakeUp did not put you in your bedroom")
	local bed, home = state().rooms.bedroom, state().rooms.home
	assert(bed and bed.limit == Cfg.Kinds.bedroom.limit and bed.used == 0 and #bed.items == 0 and home and home.limit == Cfg.Kinds.home.limit and home.used == 0,
		"5: State reads bedroom " .. show(bed) .. ", home " .. show(home) .. " with " .. #got4b .. " plaques hung, want limits " .. Cfg.Kinds.bedroom.limit .. " and " .. Cfg.Kinds.home.limit .. ", nothing used")
	local before5 = hung()
	-- the free cells, scanned once from the empty bedroom (RoomRules.Fits itself, as t108a): a scan at the limit finds none, since
	-- Fits answers "limit" before it looks at the floor. Plants are 1 x 1, so lim + 1 distinct cells never overlap each other
	local lim = Cfg.Kinds.bedroom.limit
	local cells = scan("bedroom", "plant")
	assert(#cells >= lim + 1, "premise: the bedroom's free floor has " .. #cells .. " cells, want " .. (lim + 1) .. " or more (the limit step needs them)")
	for i = 1, lim do
		local res = edit({ op = "place", kind = "bedroom", id = "plant", x = cells[i][1], z = cells[i][2], r = 0 })
		assert(type(res) == "table" and res.ok == true, "5: plant " .. i .. " of " .. lim .. " answered " .. show(res) .. " (the plaques must not count against the limit)")
	end
	local over = edit({ op = "place", kind = "bedroom", id = "plant", x = cells[lim + 1][1], z = cells[lim + 1][2], r = 0 })
	assert(type(over) == "table" and over.ok == false and over.reason == "limit", "5: a plant past the limit answered " .. show(over) .. ", want refused 'limit'")
	local s5 = state().rooms
	assert(s5.bedroom.used == Cfg.Kinds.bedroom.limit and s5.bedroom.limit == Cfg.Kinds.bedroom.limit and s5.home.used == 0 and s5.home.limit == Cfg.Kinds.home.limit,
		"5: State reads bedroom used " .. s5.bedroom.used .. " of " .. s5.bedroom.limit .. ", home used " .. s5.home.used .. " of " .. s5.home.limit)
	local itemsF = roomOf("bedroom"):FindFirstChild("Items")
	local nItems = 0
	for _, c in ipairs(itemsF:GetChildren()) do if c:IsA("Model") then nItems += 1 end end
	assert(nItems == Cfg.Kinds.bedroom.limit, "5: the bedroom's Items hold " .. nItems .. " models, want " .. Cfg.Kinds.bedroom.limit .. " (no plaque among them)")
	local after5 = hung()
	assert(#after5 == #before5 and sig(after5) == sig(before5), "5: the plaques changed while items were placed: " .. sig(before5) .. " -> " .. sig(after5))
	for i, x in ipairs(after5) do assert(x.model == before5[i].model, "5: plaque " .. i .. " was rebuilt by an item edit") end
	table.insert(out, string.format("5 item limit: with %d plaques hung the bedroom took exactly %d items (the next 'limit'), State used %d of %d (home %d of %d), the Items folder holds %d models and no plaque; the plaque models stayed the same instances",
		#after5, Cfg.Kinds.bedroom.limit, s5.bedroom.used, s5.bedroom.limit, s5.home.used, s5.home.limit, nItems))

	-- 6. a rejoin hangs the same wall (the build path)
	local before6 = sig(hung())
	local slot6 = call("Plot").slot
	teleport(LOUNGE)
	assert(call("Release") == true, "6: Release returned false")
	assert(call("Plot") == nil, "6: the plot is still there after Release")
	assert(call("Claim") == slot6, "6: Claim did not give slot " .. slot6 .. " again")
	assert(waitFor(function() return roomKinds() == "bedroom,home" end, 5), "6: the rebuilt plot's rooms read '" .. roomKinds() .. "', want bedroom,home")
	local got6 = expectWall("6 rejoin", 2)
	assert(sig(got6) == before6, "6: the rejoined plot's plaques differ:\n  before " .. before6 .. "\n  after  " .. sig(got6))
	for _, x in ipairs(got6) do checkPlaque(x, "6 plaque " .. x.room .. "/" .. x.slot) end
	table.insert(out, "6 rejoin: Release and Claim rebuilt the plot with the same " .. #got6 .. " plaques in the same slots (the build path hangs them, not the attribute listener)")

	return "T110A PLAY OK\n" .. table.concat(out, "\n") .. string.format("\nelapsed %.1f s", os.clock() - T0)
end

local okRun, msg = pcall(run)
pcall(unseat)
pcall(teleport, LOUNGE) -- first, so the rebuild below never happens under the player
pcall(function() rooms:Invoke("Unfill", uid) end)
pcall(function()
	career:Invoke("Reset", uid) -- the gate goes; the CareerGates listener rebuilds the plot to the bedroom
	waitFor(function() return roomKinds() == "bedroom" end, 5)
end)
pcall(function()
	wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
	test:Invoke("ResetHints", uid); ph:Invoke("Quiet", uid, false)
end)
-- the home last: a career Reset replaces prof.career (the home with it), so the Reset and the noted home go after the one above
pcall(function() rooms:Invoke("Reset", uid) end)
pcall(function() if homeBefore then rooms:Invoke("SetHome", uid, homeBefore) end end)
pcall(function() if weeklyBefore then rooms:Invoke("SetWeekly", uid, weeklyBefore) end end) -- the weekly plaques as the file found them
-- the profile as ProfileMark noted it (the gate's money, the gear)
local restored
pcall(function() restored = test:Invoke("ProfileRestore", uid) end)
pcall(function() career:Invoke("Publish", uid) end) -- Career_Get's cached Money dropped, the career attributes sent again
if not okRun then error(msg, 0) end
assert(restored == true, "cleanup: the test hook's ProfileRestore answered " .. tostring(restored) .. ", want true")
return msg
