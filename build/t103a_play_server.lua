-- Server, during play (the Your Rooms plan, Task 4): the home studio and the real studio unlock through Config.Career.Gates.
-- Buying a gate in the Career tab (Career.Unlock; the hook's Unlock is the same call) puts it in prof.career.gates and moves
-- CareerGates; Systems/Rooms' one listener then rebuilds your plot with the new room, and the landing's door for it turns from
-- the locked sign into a working door (RoomBuild.Landing is built from the owned kinds; hookPlot hooks the new RoomPrompt).
-- Every price and need comes from live Config.Career.Gates (preflight F8: a later plan retunes them): the profile is staged at
-- exactly the gate's needs with money = cost, and what is spent must equal the cost. The body runs held (WalkInsPaused true)
-- and starts from the file's fresh(): unseated in the lounge, Quiet on, the phone, WalkIns, Career and Life reset, no hint
-- seen, and the rooms hook's Reset (a slot claimed, the plot rebuilt). The hook's Counts reads how many times Rooms.Rebuilt
-- fired for the player since the last read.
-- (0) the config: Config.Career.Gates lists home_studio and real_studio first (then THE HALL, studio_two, and sponsor_tv); each
--     ladder gate has kind "room" and a `room` field whose Config.Rooms.Kinds entry names it as its gate; THE HALL has none.
-- (1) a fresh plot is the bedroom only: Plot rooms = { bedroom }; the landing's home and real doors have no RoomPrompt and
--     read the locked sign (copy 2.8, 2.9 and 2.10).
-- (2) home_studio, refused: with one need short by 1 (money = cost) Unlock answers "needs"; with the needs met and the money 1
--     short it answers "money". Neither spends, publishes the gate, rebuilds (Rebuilt count 0, the same Plot_01) or opens
--     the door.
-- (3) home_studio, bought while you stand in your bedroom (the Career tab opens anywhere), with a saved bedroom rug: Unlock is
--     ok, the money spent is the gate's cost, CareerGates holds it, the plot's rooms read bedroom,home with exactly one
--     Rebuilt, exactly one Plot_01 in Workspace.OK_Plots (no Plot_01_old left over, the old model gone), you are still on the
--     bedroom's floor, and the rug is still in the saved home. Room_home carries OwnerId, OwnerName, RoomKind and Plot, its
--     Station is hooked. The landing's home door now has an enabled RoomPrompt ("Go in" / "Home studio"), its Out marker and
--     the sign reads HOME STUDIO; the real door is still locked. GoIn("home") (the real handler of that prompt) puts you
--     within 3 studs of the home room's Spawn (PlaceOf 1/home) and Exit("home") on the landing outside its door. Buying it
--     again answers "owned" with no spend and no rebuild.
-- (4) real_studio likewise, from the lounge: "needs" with no rebuild; then ok, one Rebuilt, rooms bedroom,home,real, one
--     Plot_01, Room_real owned, its door open, home's still open, GoIn / Exit through it.
-- (5) gates that are not rungs of your ladder move CareerGates and rebuild nothing: THE HALL (studio_two) bought, then the
--     sponsor deal (sponsor_tv on) and its toggle off; Rebuilt count 0 and the very same Plot_01 instance each time.
-- (6) a Career Reset (the gates go): the plot is rebuilt once back to the bedroom only, one Plot_01, and both doors read the
--     locked sign again.
-- On any error: unseated in the lounge, Career Reset (the listener rebuilds to the bedroom), the rooms Reset, and everything
-- else reset (hold on, Quiet off); the error is rethrown after.
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
local RoomBuild = require(RS.OK.Modules.RoomBuild)
local Copy = RoomBuild.Copy
local Cfg = Config.Rooms
local LOUNGE = Vector3.new(24, 3, 0)
local STATS = { "aura", "followers", "placements", "hits", "sponsors" }
local RED = " (before the R-T4 sync of OK/Config and Systems/Rooms: the expected red)"
local out = {}
local T0 = os.clock()

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function root() local c = p.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = p.Character; return c and c:FindFirstChildOfClass("Humanoid") end
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
local function listHas(attr, id) return ("," .. tostring(p:GetAttribute(attr) or "") .. ","):find("," .. id .. ",", 1, true) ~= nil end
local function show(v) local okJ, js = pcall(function() return game:GetService("HttpService"):JSONEncode(v) end); return okJ and js or tostring(v) end

-- plots and doors (Plot_01 and its landing are replaced by every rebuild, so each is fetched again when it is needed)
local function plotModels() -- every model in OK_Plots whose name starts with Plot_01 (the plot, or a leftover Plot_01_old)
	local f = workspace:FindFirstChild("OK_Plots")
	local list = {}
	if f then for _, c in ipairs(f:GetChildren()) do if string.sub(c.Name, 1, 7) == "Plot_01" then table.insert(list, c) end end end
	return list
end
local function onePlot(label) -- exactly one, named Plot_01
	local list = plotModels()
	local names = {}
	for _, m in ipairs(list) do table.insert(names, m.Name) end
	assert(#list == 1 and list[1].Name == "Plot_01", label .. ": Workspace.OK_Plots holds " .. #list .. " Plot_01* model(s) [" .. table.concat(names, ", ")
		.. "], want exactly Plot_01 (a leftover Plot_01_old means the rebuild did not clean up)")
	return list[1]
end
local function roomModel(kind) local m = plotModels()[1]; return m and m:FindFirstChild("Room_" .. kind) end
local function landingOf() local m = plotModels()[1]; return m and m:FindFirstChild("Landing") end
local function roomKinds() local i = call("Plot"); return type(i) == "table" and table.concat(i.rooms, ",") or tostring(i) end
local function waitRooms(want, label)
	assert(waitFor(function() return roomKinds() == want end, 5), label .. ": the plot's rooms read '" .. roomKinds() .. "', want '" .. want .. "' (the CareerGates listener did not rebuild)")
end
local function signText(kind)
	local l = landingOf()
	local s = l and l:FindFirstChild("Sign_" .. kind)
	local g = s and s:FindFirstChild("Text")
	local lbl = g and g:FindFirstChild("Label")
	return lbl and lbl.Text
end
local function doorOf(kind)
	local l = landingOf()
	local d = l and l:FindFirstChild("Door_" .. kind)
	assert(d, "the landing has no Door_" .. kind)
	return d
end
local function assertLocked(kind, label)
	local d = doorOf(kind)
	assert(d:FindFirstChild("RoomPrompt") == nil, label .. ": the landing's " .. kind .. " door has a RoomPrompt, want none while the gate is not owned")
	local want = Copy.LockedSign[kind] .. "\n" .. Copy.LockedHint
	assert(signText(kind) == want, label .. ": the " .. kind .. " sign reads '" .. tostring(signText(kind)) .. "', want the locked sign '" .. want .. "'")
end
local function assertOpen(kind, label)
	local d = doorOf(kind)
	local pp = d:FindFirstChild("RoomPrompt")
	assert(pp and pp:IsA("ProximityPrompt") and pp.Enabled == true, label .. ": the landing's " .. kind .. " door has no enabled RoomPrompt")
	assert(pp.ActionText == Copy.GoIn and pp.ObjectText == Copy.Objects[kind], label .. ": the " .. kind .. " RoomPrompt reads '" .. pp.ActionText .. "' / '"
		.. pp.ObjectText .. "', want '" .. Copy.GoIn .. "' / '" .. tostring(Copy.Objects[kind]) .. "'")
	local out1 = d:FindFirstChild("Out")
	assert(out1 and out1:IsA("Attachment"), label .. ": the " .. kind .. " door has no Out marker")
	assert(signText(kind) == Copy.Names[kind], label .. ": the " .. kind .. " sign reads '" .. tostring(signText(kind)) .. "', want '" .. tostring(Copy.Names[kind]) .. "'")
end
-- moves
local function arrive(pos, label, tol)
	tol = tol or 3
	local ok = waitFor(function() local r = root(); return r ~= nil and flat(r.Position - pos) < tol end, 3)
	local r = root()
	assert(ok, label .. ": want the player within " .. tol .. " studs of " .. str(pos) .. ", got " .. (r and str(r.Position) or "no character")
		.. (r and string.format(" (%.1f away)", flat(r.Position - pos)) or ""))
end
local function inPlot(want, label)
	local v = call("InPlot")
	assert(v == want, label .. ": InPlot reads " .. tostring(v) .. ", want " .. want)
end
local function placeIs(want, label)
	local pl = call("PlaceOf")
	local got = type(pl) == "table" and (tostring(pl.slot) .. "/" .. tostring(pl.kind)) or tostring(pl)
	assert(got == want, label .. ": PlaceOf is " .. got .. ", want " .. want)
end
-- through the room's door and back out: GoIn is the landing prompt's own handler, Exit the room door's
local function throughDoor(kind, label)
	local sp = RoomBuild.SpawnOf(roomModel(kind))
	assert(sp, label .. ": Room_" .. kind .. " has no Spawn")
	assert(call("GoIn", kind) == true, label .. ": GoIn(" .. kind .. ") returned false")
	arrive(sp.Position, label .. ": GoIn(" .. kind .. ")")
	inPlot(1, label .. ": GoIn(" .. kind .. ")")
	placeIs("1/" .. kind, label .. ": GoIn(" .. kind .. ")")
	assert(call("Exit", kind) == true, label .. ": Exit(" .. kind .. ") returned false")
	local out1 = doorOf(kind):FindFirstChild("Out")
	arrive(out1.WorldPosition, label .. ": Exit(" .. kind .. ")")
	placeIs("1/landing", label .. ": Exit(" .. kind .. ")")
end

-- the career: gates read live, the profile staged at exactly a gate's needs
local function gateOf(id) for _, g in ipairs(Config.Career.Gates) do if g.id == id then return g end end end
local function have() local h = career:Invoke("Get", uid); assert(type(h) == "table", "Career Get answered " .. tostring(h)); return h end
-- the first stat in STATS order a gate needs at least 1 of
local function shortStat(g)
	for _, stat in ipairs(STATS) do if ((g.needs or {})[stat] or 0) >= 1 then return stat end end
	error("premise: " .. g.id .. " has no need of 1 or more, so there is no need to hold short")
end
-- Career Set: every stat at the gate's need (none: 0), `short` one under its need, money as given, `extra` merged in
local function stage(g, money, short, extra)
	local s = { money = money }
	for _, stat in ipairs(STATS) do
		local need = (g.needs or {})[stat] or 0
		if stat == short then need -= 1 end
		s[stat] = need
	end
	for k, v in pairs(extra or {}) do s[k] = v end
	assert(career:Invoke("Set", uid, s) == true, "Career Set " .. show(s) .. " failed")
	assert(have().money == money, "after Set the money reads " .. tostring(have().money) .. ", want " .. money)
end
-- the hook's Counts: Rebuilt fires since the last read. Summed until `want` have come (under deferred signals the handler
-- can run a frame after the call that fired it), then once more after `settle` seconds, so a late extra fire counts too
local function counts()
	local c = call("Counts")
	assert(type(c) == "table" and type(c.rebuilt) == "number", "the rooms hook's Counts answered " .. show(c) .. ", want { played, tried, rebuilt }" .. RED)
	return c.rebuilt
end
local function rebuilds(want, settle)
	local n = 0
	waitFor(function() n += counts(); return n >= want end, 3)
	task.wait(settle or 0.5)
	return n + counts()
end
local function quiet() task.wait(0.4); counts() end -- reads and drops what is already pending

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
	-- 0. the config (read live: a later plan retunes the prices)
	local home, real, hall, tv = gateOf("home_studio"), gateOf("real_studio"), gateOf("studio_two"), gateOf("sponsor_tv")
	assert(home, "Config.Career.Gates has no home_studio" .. RED)
	assert(real, "Config.Career.Gates has no real_studio" .. RED)
	assert(hall and tv, "Config.Career.Gates lost studio_two or sponsor_tv")
	local order = {}
	for _, g in ipairs(Config.Career.Gates) do table.insert(order, g.id) end
	assert(order[1] == "home_studio" and order[2] == "real_studio",
		"Config.Career.Gates order is [" .. table.concat(order, ", ") .. "], want home_studio, real_studio first (the ladder before THE HALL)")
	for _, pair in ipairs({ { home, "home" }, { real, "real" } }) do
		local g, kind = pair[1], pair[2]
		assert(g.kind == "room" and g.room == kind, g.id .. ": kind '" .. tostring(g.kind) .. "' / room '" .. tostring(g.room) .. "', want room / " .. kind)
		assert(Cfg.Kinds[kind].gate == g.id, "Config.Rooms.Kinds." .. kind .. ".gate is " .. tostring(Cfg.Kinds[kind].gate) .. ", want " .. g.id)
		assert(type(g.name) == "string" and g.name ~= "" and type(g.desc) == "string" and g.desc ~= "", g.id .. " has no name or desc")
		assert(type(g.cost) == "number" and g.cost > 0, g.id .. ": cost is " .. tostring(g.cost) .. ", the test needs a price above 0")
		shortStat(g)
	end
	assert(hall.room == nil and tv.room == nil, "THE HALL and sponsor_tv are not rungs of your ladder: no `room` field (" .. tostring(hall.room) .. ", " .. tostring(tv.room) .. ")")
	assert(hall.kind == "room" and (hall.cost or 0) > 0 and tv.kind == "toggle", "studio_two should be a priced room gate and sponsor_tv a toggle")
	table.insert(out, string.format("0 config: gates [%s]; home_studio needs %s for $%d (room home), real_studio needs %s for $%d (room real); THE HALL has no `room`",
		table.concat(order, ", "), show(home.needs), home.cost, show(real.needs), real.cost))

	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh("gates")
	quiet()

	-- 1. a fresh plot: the bedroom only, the two doors locked
	assert(roomKinds() == "bedroom", "a fresh plot's rooms read '" .. roomKinds() .. "', want bedroom")
	local plot0 = onePlot("fresh")
	assertLocked("home", "fresh")
	assertLocked("real", "fresh")
	assert(roomModel("home") == nil and roomModel("real") == nil, "fresh: the plot already has a home or real room")
	table.insert(out, "1 fresh: rooms bedroom; the home and real doors have no RoomPrompt and read the locked sign")

	-- 2. home_studio refused: needs short by 1, then money short by 1
	stage(home, home.cost, shortStat(home))
	local r1 = career:Invoke("Unlock", uid, "home_studio")
	assert(type(r1) == "table" and r1.ok == false and r1.reason == "needs", "Unlock(home_studio) one need short (money = cost): got ok " .. tostring(r1 and r1.ok)
		.. " / reason " .. tostring(r1 and r1.reason) .. ", want false / needs")
	assert(have().money == home.cost, "a refused unlock changed the money: " .. have().money .. ", want " .. home.cost)
	assert(not listHas("CareerGates", "home_studio"), "a refused unlock put home_studio in CareerGates: " .. tostring(p:GetAttribute("CareerGates")))
	local n = rebuilds(0, 0.8)
	assert(n == 0 and onePlot("needs") == plot0 and roomKinds() == "bedroom", "needs unmet: Rebuilt fired " .. n .. " time(s) (want 0), rooms '" .. roomKinds()
		.. "' (want bedroom), the plot is " .. (onePlot("needs") == plot0 and "the same" or "a new one") .. " model")
	assertLocked("home", "needs unmet")
	stage(home, home.cost - 1)
	local r2 = career:Invoke("Unlock", uid, "home_studio")
	assert(type(r2) == "table" and r2.ok == false and r2.reason == "money", "Unlock(home_studio) with the needs met and $" .. (home.cost - 1) .. ": got ok " .. tostring(r2 and r2.ok)
		.. " / reason " .. tostring(r2 and r2.reason) .. ", want false / money")
	assert(have().money == home.cost - 1, "a refused unlock spent money: " .. have().money .. ", want " .. (home.cost - 1))
	n = rebuilds(0, 0.8)
	assert(n == 0 and onePlot("money") == plot0, "money short: Rebuilt fired " .. n .. " time(s), want 0 and the same plot")
	assertLocked("home", "money short")
	table.insert(out, "2 home_studio refused: one need short -> 'needs', $" .. (home.cost - 1) .. " -> 'money'; no spend, no gate, Rebuilt 0, the same Plot_01, door still locked")

	-- 3. home_studio bought, standing in your bedroom, with a saved bedroom rug
	assert(call("WakeUp") == true, "WakeUp returned false")
	local bedSpawn = RoomBuild.SpawnOf(roomModel("bedroom"))
	assert(bedSpawn, "the bedroom has no Spawn")
	local bedPos = bedSpawn.Position
	arrive(bedPos, "WakeUp")
	placeIs("1/bedroom", "WakeUp")
	local rug
	for _, a in ipairs(Cfg.Kinds.bedroom.grid) do -- a spot the saved bedroom takes a rug on, from the live grid (areas { x0, z0, x1, z1 })
		local try = { id = "rug", x = math.ceil(a[1]), z = math.ceil(a[2]), r = 0 }
		local kept = call("SetHome", { v = 1, door = Cfg.DoorDefault, items = { bedroom = { try } } })
		if type(kept) == "table" and type(kept.items) == "table" and type(kept.items.bedroom) == "table" and #kept.items.bedroom == 1 and kept.items.bedroom[1].id == "rug" then rug = try; break end
	end
	assert(rug, "premise: no area of Config.Rooms.Kinds.bedroom.grid took a saved rug")
	stage(home, home.cost)
	quiet()
	local before = have().money
	local u = career:Invoke("Unlock", uid, "home_studio")
	assert(type(u) == "table" and u.ok == true and u.gate == "home_studio", "Unlock(home_studio) with exactly the needs and $" .. home.cost .. ": got ok " .. tostring(u and u.ok)
		.. " / reason " .. tostring(u and u.reason) .. ", want ok")
	assert(before - have().money == home.cost, "Unlock(home_studio) spent $" .. (before - have().money) .. ", want the cost $" .. home.cost)
	assert(listHas("CareerGates", "home_studio"), "CareerGates lacks home_studio: " .. tostring(p:GetAttribute("CareerGates")))
	waitRooms("bedroom,home", "home_studio bought")
	n = rebuilds(1, 0.6)
	assert(n == 1, "home_studio bought: Rebuilt fired " .. n .. " time(s), want exactly 1")
	local plot1 = onePlot("home_studio bought")
	assert(plot1 ~= plot0 and plot0.Parent == nil, "home_studio bought: the plot is " .. (plot1 == plot0 and "the old model, not rebuilt" or "new") .. " and the old model's Parent is " .. tostring(plot0.Parent) .. " (want nil: destroyed)")
	local r = root()
	assert(r and r.Position.Y > -2 and flat(r.Position - bedPos) < 3, "home_studio bought while standing in the bedroom: the player is at " .. (r and str(r.Position) or "nowhere")
		.. ", want still on the bedroom floor near " .. str(bedPos) .. " (the new plot should stand where the old one was). If this is the only red, it is Task 3's rebuild-under-the-player claim, not the gate")
	placeIs("1/bedroom", "home_studio bought")
	local h = call("Home")
	assert(type(h) == "table" and type(h.items) == "table" and type(h.items.bedroom) == "table" and #h.items.bedroom == 1 and h.items.bedroom[1].id == "rug"
		and h.items.bedroom[1].x == rug.x and h.items.bedroom[1].z == rug.z, "the saved bedroom rug did not survive the rebuild: Home reads " .. show(h))
	local homeRoom = roomModel("home")
	assert(homeRoom, "home_studio bought: Plot_01 has no Room_home")
	assert(homeRoom:GetAttribute("OwnerId") == uid and homeRoom:GetAttribute("OwnerName") == p.DisplayName and homeRoom:GetAttribute("RoomKind") == "home" and homeRoom:GetAttribute("Plot") == 1,
		string.format("Room_home attributes: OwnerId %s / OwnerName %s / RoomKind %s / Plot %s, want %d / %s / home / 1", tostring(homeRoom:GetAttribute("OwnerId")),
			tostring(homeRoom:GetAttribute("OwnerName")), tostring(homeRoom:GetAttribute("RoomKind")), tostring(homeRoom:GetAttribute("Plot")), uid, p.DisplayName))
	local bed = roomModel("bedroom")
	assert(bed and bed:GetAttribute("OwnerId") == uid and bed:GetAttribute("RoomKind") == "bedroom", "the rebuilt plot's bedroom lost its owner or kind")
	local st = call("Station", "home")
	assert(typeof(st) == "Instance" and st:IsDescendantOf(homeRoom), "the hook's Station('home') is " .. tostring(st) .. ", want Room_home's Station")
	assert(waitFor(function() return st:GetAttribute("OK_Hooked") == true end, 3), "Room_home's Station is not hooked (OK_Hooked " .. tostring(st:GetAttribute("OK_Hooked")) .. ")")
	assertOpen("home", "home_studio bought")
	assertLocked("real", "home_studio bought")
	local u2 = career:Invoke("Unlock", uid, "home_studio")
	assert(type(u2) == "table" and u2.ok == false and u2.reason == "owned", "buying home_studio again: got ok " .. tostring(u2 and u2.ok) .. " / reason " .. tostring(u2 and u2.reason) .. ", want false / owned")
	assert(before - have().money == home.cost, "buying home_studio again spent more: $" .. (before - have().money) .. " in all, want $" .. home.cost)
	n = rebuilds(0, 0.8)
	assert(n == 0 and onePlot("owned") == plot1, "an owned gate bought again: Rebuilt fired " .. n .. " time(s), want 0 and the same plot")
	throughDoor("home", "home door")
	table.insert(out, string.format("3 home_studio bought in the bedroom: spent $%d, rooms bedroom,home, one Rebuilt, one Plot_01 (the old one gone), still on the bedroom floor, the saved rug kept, Room_home owned and hooked; "
		.. "its door has a RoomPrompt and reads HOME STUDIO, real still locked; GoIn -> home's Spawn, Exit -> the landing; again -> 'owned', no rebuild", home.cost))

	-- 4. real_studio, from the lounge
	teleport(LOUNGE)
	stage(real, real.cost, shortStat(real))
	local r3 = career:Invoke("Unlock", uid, "real_studio")
	assert(type(r3) == "table" and r3.ok == false and r3.reason == "needs", "Unlock(real_studio) one need short: got ok " .. tostring(r3 and r3.ok) .. " / reason " .. tostring(r3 and r3.reason) .. ", want false / needs")
	n = rebuilds(0, 0.8)
	assert(n == 0 and onePlot("real needs") == plot1 and roomKinds() == "bedroom,home", "real_studio needs unmet: Rebuilt fired " .. n .. " time(s), rooms '" .. roomKinds() .. "', want 0 and bedroom,home")
	assertLocked("real", "real needs unmet")
	stage(real, real.cost)
	quiet()
	before = have().money
	local ur = career:Invoke("Unlock", uid, "real_studio")
	assert(type(ur) == "table" and ur.ok == true and ur.gate == "real_studio", "Unlock(real_studio) with exactly the needs and $" .. real.cost .. ": got ok " .. tostring(ur and ur.ok)
		.. " / reason " .. tostring(ur and ur.reason) .. ", want ok")
	assert(before - have().money == real.cost, "Unlock(real_studio) spent $" .. (before - have().money) .. ", want the cost $" .. real.cost)
	assert(listHas("CareerGates", "real_studio"), "CareerGates lacks real_studio: " .. tostring(p:GetAttribute("CareerGates")))
	waitRooms("bedroom,home,real", "real_studio bought")
	n = rebuilds(1, 0.6)
	assert(n == 1, "real_studio bought: Rebuilt fired " .. n .. " time(s), want exactly 1")
	local plot2 = onePlot("real_studio bought")
	assert(plot2 ~= plot1 and plot1.Parent == nil, "real_studio bought: the plot is " .. (plot2 == plot1 and "the old model, not rebuilt" or "new") .. " and the previous model's Parent is " .. tostring(plot1.Parent) .. " (want nil)")
	local realRoom = roomModel("real")
	assert(realRoom and realRoom:GetAttribute("OwnerId") == uid and realRoom:GetAttribute("RoomKind") == "real" and realRoom:GetAttribute("Plot") == 1,
		"Room_real is missing or lost OwnerId / RoomKind / Plot")
	assert(roomModel("home") and roomModel("bedroom"), "real_studio bought: the plot lost Room_home or Room_bedroom")
	h = call("Home")
	assert(type(h) == "table" and type(h.items) == "table" and type(h.items.bedroom) == "table" and #h.items.bedroom == 1 and h.items.bedroom[1].id == "rug",
		"the saved bedroom rug did not survive the second rebuild: Home reads " .. show(h))
	assertOpen("real", "real_studio bought")
	assertOpen("home", "real_studio bought")
	throughDoor("real", "real door")
	table.insert(out, string.format("4 real_studio: one need short -> 'needs' (no rebuild); then bought for $%d, rooms bedroom,home,real, one Rebuilt, one Plot_01, Room_real owned; both doors open; GoIn -> real's Spawn, Exit -> the landing", real.cost))

	-- 5. gates that are not rungs of your ladder rebuild nothing
	teleport(LOUNGE)
	stage(hall, hall.cost)
	quiet()
	local uh = career:Invoke("Unlock", uid, "studio_two")
	assert(type(uh) == "table" and uh.ok == true, "Unlock(studio_two) with its live needs and $" .. hall.cost .. ": got ok " .. tostring(uh and uh.ok) .. " / reason " .. tostring(uh and uh.reason))
	assert(waitFor(function() return listHas("CareerGates", "studio_two") end, 2), "CareerGates lacks studio_two: " .. tostring(p:GetAttribute("CareerGates")))
	n = rebuilds(0, 1.2)
	assert(n == 0, "THE HALL (studio_two) bought: Rebuilt fired " .. n .. " time(s), want 0 (not a rung of your ladder)")
	assert(onePlot("studio_two") == plot2 and roomKinds() == "bedroom,home,real", "THE HALL bought: the plot was replaced or its rooms changed to '" .. roomKinds() .. "'")
	assert(tv.needs and (tv.needs.sponsors or 0) >= 1, "premise: sponsor_tv needs a sponsor")
	stage(tv, 0, nil, { sponsor = "t103a_brand" })
	assert(waitFor(function() return listHas("CareerGates", "sponsor_tv") end, 2), "a sponsor deal did not put sponsor_tv in CareerGates: " .. tostring(p:GetAttribute("CareerGates")))
	n = rebuilds(0, 1.0)
	assert(n == 0 and onePlot("sponsor_tv") == plot2, "the sponsor deal (CareerGates moved): Rebuilt fired " .. n .. " time(s), want 0 and the same plot")
	local ut = career:Invoke("Unlock", uid, "sponsor_tv")
	assert(type(ut) == "table" and ut.ok == true and ut.on == false, "Unlock(sponsor_tv) toggles it off: got ok " .. tostring(ut and ut.ok) .. " / on " .. tostring(ut and ut.on))
	assert(waitFor(function() return not listHas("CareerGates", "sponsor_tv") end, 2), "sponsor_tv still in CareerGates after its toggle off: " .. tostring(p:GetAttribute("CareerGates")))
	n = rebuilds(0, 1.0)
	assert(n == 0 and onePlot("sponsor_tv off") == plot2 and roomKinds() == "bedroom,home,real", "the sponsor toggle off: Rebuilt fired " .. n .. " time(s), rooms '" .. roomKinds() .. "', want 0 and the same plot")
	table.insert(out, "5 THE HALL bought, the sponsor deal on and its toggle off: CareerGates moved each time, Rebuilt 0, the very same Plot_01, rooms still bedroom,home,real")

	-- 6. a Career Reset takes the gates: the plot goes back to the bedroom, once
	teleport(LOUNGE) -- the rebuild replaces home and real: never under the player
	quiet()
	assert(career:Invoke("Reset", uid) == true, "Career Reset failed")
	waitRooms("bedroom", "Career Reset")
	n = rebuilds(1, 0.8)
	assert(n == 1, "Career Reset: Rebuilt fired " .. n .. " time(s), want exactly 1")
	local plot3 = onePlot("Career Reset")
	assert(plot3 ~= plot2 and plot2.Parent == nil, "Career Reset: the plot was not replaced")
	assert(roomModel("home") == nil and roomModel("real") == nil and roomModel("bedroom") ~= nil, "Career Reset: the plot should hold only Room_bedroom")
	assertLocked("home", "Career Reset")
	assertLocked("real", "Career Reset")
	table.insert(out, "6 Career Reset: rebuilt once to the bedroom only (one Plot_01), both doors locked again")

	return "T103A PLAY OK\n" .. table.concat(out, "\n") .. string.format("\nelapsed %.1f s", os.clock() - T0)
end

local ok, msg = pcall(run)
pcall(unseat)
pcall(teleport, LOUNGE) -- first, so the rebuild below never happens under the player
pcall(function()
	career:Invoke("Reset", uid) -- the gates go; the CareerGates listener rebuilds the plot to the bedroom
	waitFor(function() return roomKinds() == "bedroom" end, 5)
end)
pcall(function() rooms:Invoke("Unfill", uid) end)
pcall(function() rooms:Invoke("Reset", uid) end)
pcall(function()
	wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
	test:Invoke("ResetHints", uid); ph:Invoke("Quiet", uid, false)
end)
if not ok then error(msg, 0) end
return msg
