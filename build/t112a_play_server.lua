-- Server, during play (the Your Rooms plan, Task 13: posters you design, the server's side), through the Studio hooks.
-- First, before anything changes, the test hook's ProfileMark notes the profile and the player attribute _T112Mark says so:
-- t112c, the group's tail, puts it back after t112b. Then held (WalkInsPaused true), the file's fresh(): unseated in the
-- lounge, Quiet on, the phone, WalkIns, Career and Life reset, no hint seen, the rooms hook's Reset (a slot claimed, the plot
-- rebuilt); then ResetGear. Edits go through the rooms hook's Edit (the Room_Edit remote's own handler), paced one
-- Config.Rooms.Edit.every + 0.03 s apart.
-- (1) home_studio bought for real: Career Set at the gate's needs and its price, both read from the live Config.Career.Gates
--     (preflight F8), then Unlock("home_studio"): the plot's rooms read bedroom,home. WakeUp (the player in their bedroom:
--     an edit works from anywhere in your own plot). Room_home has an Attachment Poster_1..n (n = Config.Rooms.Kinds.home
--     .posters) on the west wall's plane (room-local x = -size/2, R-T12's leftover moved in all three Config copies), facing
--     into the room (+x).
-- (2) Edit { op = "poster", kind = "home", slot = 1, w = 2, c = 3, s = 1 } -> ok, op "poster", index 1, item = that design.
--     The saved home (the hook's Home) holds exactly that entry; State's home reads used 1, slots n. Room_home.Items holds
--     one poster Model (Item_1, ItemId "poster", Index 1): its Label reads PosterWords[2] in PosterColorInk[3] on a Face in
--     PosterColors[3]; its pivot is the Poster_1 anchor (0.01 stud, the same facing); the Face is the catalog poster's size
--     (3 x 4), thin (0.1 or less), its back on the wall plane and its front in the room, its SurfaceGui on the Front;
--     every part anchored, not colliding or touching, queryable (a tap in decorate mode picks it), casting no shadow, at
--     most Config.Rooms.ItemParts of them; nothing in it is a Light, a MeshPart, a script, an image (Decal, Texture,
--     ImageLabel, ImageButton, VideoFrame, ViewportFrame) or a TextBox. BOLD: one TextLabel, no Border.
-- (3) Refusals, each with nothing changed (the saved home and the very same model): w 99 -> "design"; c 9 -> "design";
--     s 4 -> "design"; slot 9 -> "slot"; kind "bedroom" -> "room"; w 2.5 and slot "1" -> "invalid" (all four fields are
--     whole numbers: RoomEdit.Check).
-- (4) A redesign of the same slot replaces it: Edit poster slot 1 { w = 5, c = 8, s = 3 } -> ok at index 1; the saved home
--     holds one poster, slot 1, 5/8/3; Items holds one poster model (a new one; the old one is gone) reading VIBES three
--     times (STACKED: Label_Top, Label, Label_Bottom) on PosterColors[8].
-- (5) RoomItems.Poster's three styles (its own call): BOLD one TextLabel; FRAMED a Border Frame with a UIStroke in the ink
--     and one TextLabel smaller than BOLD's; STACKED three, the middle one the biggest; a junk design (w 0, w 13, c 9, s 4,
--     w 2.5, a string, nil) -> nil.
-- (6) Posters count toward home's limit: SetHome with the slot 1 poster and limit - 2 plants (free cells, RoomRules.Fits on
--     State) keeps them all (State used limit - 1); a poster on slot 2 -> ok (used = limit); a poster on slot 3 -> "limit"; a
--     plant on a free cell -> "limit"; a redesign of slot 2 at the limit -> ok (a redesign doesn't count itself) and used is
--     still the limit; removing the slot 2 poster (the "remove" op at its index) -> ok, used limit - 1, Items holds one poster.
-- (7) No player-typed text: no TextBox anywhere in the plot, StarterGui, the player's PlayerGui as the server sees it (Roblox's
--     own Chat, BubbleChat, TouchGui and Freecam skipped), or ReplicatedStorage.OK (t112b checks the client's own PlayerGui: a
--     server can't see a gui the client built).
-- (8) Room_home holds at most 1 light (posters add none).
-- On any error: the full put-back (t112c's: unseated in the lounge, WalkIns, the phone, Career and Life reset, no hint seen,
-- the rooms Reset, Quiet off, ProfileRestore and the career hook's Publish; _T112Mark cleared) and the error rethrown.
-- Tail for t112b, only on success, nothing reset: home still owned, its saved items emptied (SetHome), and the player in
-- Room_home (the hook's GoIn).
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
local Catalog = require(RS.OK.Data.RoomCatalog)
local RoomItems = require(RS.OK.Modules.RoomItems)
local RoomBuild = require(RS.OK.Modules.RoomBuild)
local Cfg = Config.Rooms
local LOUNGE = Vector3.new(24, 3, 0)
local STATS = { "aura", "followers", "placements", "hits", "sponsors" }
local RED = " (before the R-T13 sync of Modules/RoomItems, Modules/RoomEdit, Systems/Rooms and OK/Config: the expected red)"
local EVERY = Cfg.Edit.every
local IMAGES = { "Decal", "Texture", "ImageLabel", "ImageButton", "VideoFrame", "ViewportFrame" }
local out = {}
local T0 = os.clock()
local lastEdit = 0

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
local function rgbIs(c, t) return c and t and math.abs(c.R * 255 - t[1]) < 1.5 and math.abs(c.G * 255 - t[2]) < 1.5 and math.abs(c.B * 255 - t[3]) < 1.5 end
local function placeIs(want)
	return waitFor(function()
		local pl = call("PlaceOf")
		return type(pl) == "table" and (tostring(pl.slot) .. "/" .. tostring(pl.kind)) == want
	end, 4)
end
local function state()
	local s = call("State")
	assert(type(s) == "table" and type(s.rooms) == "table" and type(s.unlocked) == "table", "the rooms hook's State answered " .. show(s))
	return s
end
local function homeItems() local h = call("Home"); return type(h) == "table" and type(h.items) == "table" and h.items.home or nil end
-- every lowest cell where `id` fits the room now (RoomRules.Fits on State, as t108a's scan)
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
local function edit(action)
	local gap = EVERY + 0.03 - (os.clock() - lastEdit)
	if gap > 0 then task.wait(gap) end
	lastEdit = os.clock()
	return call("Edit", action)
end
local function poster(slot, w, c, s, kind) return { op = "poster", kind = kind or "home", slot = slot, w = w, c = c, s = s } end
local function refused(res, want, label)
	assert(type(res) == "table" and res.ok == false and res.reason == want, label .. ": Edit answered " .. show(res) .. ", want refused '" .. want .. "'" .. RED)
end
local function postersIn(room)
	local list = {}
	local items = room and room:FindFirstChild("Items")
	for _, m in ipairs(items and items:GetChildren() or {}) do
		if m:IsA("Model") and m:GetAttribute("ItemId") == "poster" then table.insert(list, m) end
	end
	return list
end
local function labels(m)
	local list = {}
	for _, d in ipairs(m:GetDescendants()) do if d:IsA("TextLabel") then table.insert(list, d) end end
	table.sort(list, function(a, b) return a.Name < b.Name end)
	return list
end
local ROBLOX_GUIS = { Chat = true, BubbleChat = true, TouchGui = true, Freecam = true } -- Roblox's own guis, not the game's
local function textBoxes(inst)
	local list = {}
	for _, top in ipairs(inst:GetChildren()) do
		if not (inst:IsA("PlayerGui") and ROBLOX_GUIS[top.Name]) then
			if top:IsA("TextBox") then table.insert(list, top:GetFullName()) end
			for _, d in ipairs(top:GetDescendants()) do if d:IsA("TextBox") then table.insert(list, d:GetFullName()) end end
		end
	end
	return list
end

-- the full put-back (t112c's), every step tried; returns ProfileRestore's answer and the steps that threw
local function putBack()
	local steps = {}
	local function try(label, fn)
		local good, err = pcall(fn)
		if not good then table.insert(steps, label .. ": " .. tostring(err)) end
	end
	try("hold", function() wi:Invoke("Pause", uid, true) end)
	try("unseat", unseat)
	try("lounge", function() teleport(LOUNGE) end) -- first, so the rebuild below never happens under the player
	try("resets", function()
		wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
		test:Invoke("ResetHints", uid)
	end)
	try("rooms Reset", function() rooms:Invoke("Reset", uid) end) -- after the career Reset (it replaces prof.career, the home with it)
	try("Quiet off", function() ph:Invoke("Quiet", uid, false) end)
	local restored
	try("ProfileRestore", function() restored = test:Invoke("ProfileRestore", uid) end)
	try("Publish", function() career:Invoke("Publish", uid) end)
	p:SetAttribute("_T112Mark", nil)
	return restored, steps
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

-- the checks every hung poster model passes; returns its Face
local function checkModel(m, slot, w, c, s, label)
	local face = m:FindFirstChild("Face")
	assert(face and face:IsA("BasePart"), label .. ": the poster model has no Face part" .. RED)
	local parts = 0
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			parts += 1
			assert(d.Anchored and not d.CanCollide and not d.CanTouch and d.CanQuery and not d.CastShadow, label .. ": " .. d:GetFullName()
				.. " should be anchored, not colliding or touching, queryable, casting no shadow")
		end
		assert(not d:IsA("Light") and not d:IsA("MeshPart") and not d:IsA("BaseScript") and not d:IsA("TextBox"), label .. ": " .. d:GetFullName() .. " is a " .. d.ClassName)
		for _, cls in ipairs(IMAGES) do assert(not d:IsA(cls), label .. ": " .. d:GetFullName() .. " is a " .. d.ClassName .. " (no images)") end
	end
	assert(parts <= Cfg.ItemParts, label .. ": the poster holds " .. parts .. " parts, over Config.Rooms.ItemParts " .. Cfg.ItemParts)
	local size = Catalog.ById.poster.size
	assert(math.abs(face.Size.X - size[1]) < 0.01 and math.abs(face.Size.Y - size[2]) < 0.01 and face.Size.Z <= 0.1, label .. ": the Face is "
		.. str(face.Size) .. ", want " .. size[1] .. " x " .. size[2] .. " (the catalog poster) and 0.1 or less thick")
	local a = call("Anchor", "home", "Poster_" .. slot)
	assert(typeof(a) == "CFrame", label .. ": no Poster_" .. slot .. " anchor in home (the hook's Anchor)")
	local pv = m:GetPivot()
	assert((pv.Position - a.Position).Magnitude < 0.01 and pv.LookVector:Dot(a.LookVector) > 0.999, label .. ": the poster's pivot " .. str(pv.Position)
		.. " is not the Poster_" .. slot .. " anchor " .. str(a.Position) .. " (or faces another way)")
	local lp = a:PointToObjectSpace(face.Position)
	assert(lp.Z - face.Size.Z / 2 >= -0.2 and lp.Z + face.Size.Z / 2 <= 0.01, label .. ": the Face sits " .. string.format("%.3f", lp.Z)
		.. " studs along the anchor's back axis: its back must be on the wall plane and its front in the room")
	local gui = face:FindFirstChildWhichIsA("SurfaceGui")
	assert(gui and gui.Face == Enum.NormalId.Front, label .. ": the Face has no SurfaceGui on its Front")
	local main = m:FindFirstChild("Label", true)
	assert(main and main:IsA("TextLabel") and main.Text == Cfg.PosterWords[w], label .. ": the poster's Label reads '" .. tostring(main and main.Text)
		.. "', want PosterWords[" .. w .. "] '" .. Cfg.PosterWords[w] .. "'")
	assert(rgbIs(main.TextColor3, Cfg.PosterColorInk[c]), label .. ": the Label's ink is " .. tostring(main.TextColor3) .. ", want PosterColorInk[" .. c .. "]")
	assert(rgbIs(face.Color, Cfg.PosterColors[c]), label .. ": the Face is " .. tostring(face.Color) .. ", want PosterColors[" .. c .. "]")
	assert(m:GetAttribute("PosterWord") == w and m:GetAttribute("PosterColor") == c and m:GetAttribute("PosterStyle") == s, label .. ": the model's design attributes read "
		.. tostring(m:GetAttribute("PosterWord")) .. "/" .. tostring(m:GetAttribute("PosterColor")) .. "/" .. tostring(m:GetAttribute("PosterStyle")) .. ", want " .. w .. "/" .. c .. "/" .. s)
	return face
end

local function run()
	local mk = test:Invoke("ProfileMark", uid) -- first, before anything changes (t112c's ProfileRestore)
	assert(mk == true, "the test hook's ProfileMark answered " .. tostring(mk) .. ", want true")
	p:SetAttribute("_T112Mark", true)
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh("posters")
	assert(test:Invoke("ResetGear", uid) == true, "ResetGear failed")
	local n = Cfg.Kinds.home.posters
	assert(type(n) == "number" and n >= 3, "premise: Config.Rooms.Kinds.home.posters is " .. tostring(n) .. ", want 3 or more")

	-- 1. home_studio bought, needs and price read live (F8); the poster anchors on the wall plane
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
	local pivot = home:GetPivot()
	local hw = Cfg.Kinds.home.size[1] / 2
	for i = 1, n do
		local a = home:FindFirstChild("Poster_" .. i, true)
		assert(a and a:IsA("Attachment"), "1: Room_home has no Attachment Poster_" .. i)
		local want = pivot * RoomBuild.AnchorCFrame(Cfg.Kinds.home.anchors["Poster_" .. i])
		assert((a.WorldPosition - want.Position).Magnitude < 0.01, "1: Poster_" .. i .. " is at " .. str(a.WorldPosition) .. ", want Config's " .. str(want.Position) .. RED)
		local lp = pivot:PointToObjectSpace(a.WorldPosition)
		assert(math.abs(lp.X + hw) < 0.01, string.format("1: Poster_%d sits at room-local x %.2f, want %.2f (the west wall's plane)%s", i, lp.X, -hw, RED))
		assert(pivot:VectorToObjectSpace(a.WorldCFrame.LookVector):Dot(Vector3.xAxis) > 0.999, "1: Poster_" .. i .. " doesn't face into the room (+x)")
	end
	table.insert(out, string.format("1 home_studio bought (needs %s, $%d, read live): rooms bedroom,home; Poster_1..%d on the west wall's plane (x %.1f), facing in", show(g.needs or {}), g.cost, n, -hw))

	-- 2. a poster hung on slot 1
	local res = edit(poster(1, 2, 3, 1))
	assert(type(res) == "table" and res.ok == true and res.op == "poster" and res.index == 1, "2: Edit poster slot 1 { 2, 3, 1 } answered " .. show(res) .. ", want ok, op poster, index 1" .. RED)
	assert(type(res.item) == "table" and canon(res.item) == canon({ id = "poster", slot = 1, w = 2, c = 3, s = 1 }), "2: the answer's item is " .. show(res.item) .. ", want the poster entry")
	local saved = homeItems()
	assert(type(saved) == "table" and #saved == 1 and canon(saved[1]) == canon({ id = "poster", slot = 1, w = 2, c = 3, s = 1 }), "2: the saved home's items read " .. show(saved) .. ", want the one poster")
	local st2 = state().rooms.home
	assert(st2.used == 1 and st2.slots == n and #st2.items == 1, "2: State's home reads used " .. tostring(st2.used) .. ", slots " .. tostring(st2.slots) .. ", items " .. #st2.items .. "; want 1, " .. n .. ", 1")
	local ps = postersIn(home)
	assert(#ps == 1, "2: Room_home.Items holds " .. #ps .. " poster models, want 1" .. RED)
	local m1 = ps[1]
	assert(m1.Name == "Item_1" and m1:GetAttribute("Index") == 1, "2: the poster model is " .. m1.Name .. " (Index " .. tostring(m1:GetAttribute("Index")) .. "), want Item_1 / 1")
	checkModel(m1, 1, 2, 3, 1, "2")
	local l1 = labels(m1)
	assert(#l1 == 1 and m1:FindFirstChild("Border", true) == nil, "2: a BOLD poster holds " .. #l1 .. " TextLabels and " .. (m1:FindFirstChild("Border", true) and "a" or "no") .. " Border, want 1 and none")
	table.insert(out, string.format("2 poster slot 1 { 2, 3, 1 }: ok, saved; Item_1 reads '%s' in its ink on %s, pivoted on Poster_1, one thin %dx%d Face, no light, mesh, image or TextBox; State used 1",
		Cfg.PosterWords[2], Cfg.PosterColorNames[3], Catalog.ById.poster.size[1], Catalog.ById.poster.size[2]))

	-- 3. refusals change nothing
	local before = canon(homeItems())
	refused(edit(poster(1, 99, 1, 1)), "design", "3 word 99")
	refused(edit(poster(1, 1, 9, 1)), "design", "3 color 9")
	refused(edit(poster(1, 1, 1, 4)), "design", "3 style 4")
	refused(edit(poster(9, 1, 1, 1)), "slot", "3 slot 9")
	refused(edit(poster(1, 1, 1, 1, "bedroom")), "room", "3 in the bedroom")
	refused(edit(poster(1, 2.5, 1, 1)), "invalid", "3 word 2.5")
	refused(edit({ op = "poster", kind = "home", slot = "1", w = 1, c = 1, s = 1 }), "invalid", "3 slot '1'")
	assert(canon(homeItems()) == before, "3: a refused poster changed the saved home: " .. show(homeItems()))
	local ps3 = postersIn(home)
	assert(#ps3 == 1 and ps3[1] == m1, "3: a refused poster changed Room_home.Items (" .. #ps3 .. " poster models)")
	table.insert(out, "3 refusals: word 99, color 9, style 4 -> design; slot 9 -> slot; bedroom -> room; word 2.5, slot '1' -> invalid; nothing changed")

	-- 4. a redesign of the same slot replaces it
	local res4 = edit(poster(1, 5, 8, 3))
	assert(type(res4) == "table" and res4.ok == true and res4.index == 1, "4: the redesign of slot 1 answered " .. show(res4) .. ", want ok at index 1")
	local saved4 = homeItems()
	assert(type(saved4) == "table" and #saved4 == 1 and canon(saved4[1]) == canon({ id = "poster", slot = 1, w = 5, c = 8, s = 3 }), "4: the saved home reads " .. show(saved4) .. ", want one poster, slot 1, 5/8/3")
	local ps4
	assert(waitFor(function() ps4 = postersIn(home); return #ps4 == 1 and ps4[1] ~= m1 end, 3), "4: Room_home.Items holds " .. #postersIn(home) .. " poster models after the redesign, want one new one")
	assert(m1.Parent == nil, "4: the old poster model is still standing")
	checkModel(ps4[1], 1, 5, 8, 3, "4")
	local l4 = labels(ps4[1])
	local names4 = {}
	for _, l in ipairs(l4) do
		table.insert(names4, l.Name)
		assert(l.Text == Cfg.PosterWords[5], "4: the STACKED poster's " .. l.Name .. " reads '" .. l.Text .. "', want '" .. Cfg.PosterWords[5] .. "'")
	end
	assert(table.concat(names4, ",") == "Label,Label_Bottom,Label_Top", "4: the STACKED poster's labels are " .. table.concat(names4, ",") .. ", want Label, Label_Bottom, Label_Top")
	table.insert(out, string.format("4 redesign slot 1 { 5, 8, 3 }: ok at index 1; one poster saved and one model ('%s' three times on %s)", Cfg.PosterWords[5], Cfg.PosterColorNames[8]))

	-- 5. RoomItems.Poster's styles and its junk
	local function styled(s)
		local m = RoomItems.Poster({ w = 1, c = 1, s = s }, Cfg)
		assert(m and m:IsA("Model"), "5: RoomItems.Poster(style " .. s .. ") answered " .. tostring(m))
		return m, labels(m)
	end
	local bold, lb = styled(1)
	local framed, lf = styled(2)
	local stacked, ls = styled(3)
	assert(#lb == 1 and bold:FindFirstChild("Border", true) == nil, "5: BOLD holds " .. #lb .. " labels" .. (bold:FindFirstChild("Border", true) and " and a Border" or "") .. ", want 1 and no Border")
	local border = framed:FindFirstChild("Border", true)
	local stroke = border and border:FindFirstChildWhichIsA("UIStroke")
	assert(border and border:IsA("Frame") and stroke and rgbIs(stroke.Color, Cfg.PosterColorInk[1]), "5: FRAMED has no Border Frame with a UIStroke in the ink")
	assert(#lf == 1 and lf[1].Size.Y.Scale < lb[1].Size.Y.Scale and lf[1].Size.X.Scale < lb[1].Size.X.Scale, "5: FRAMED's word should be one label, smaller than BOLD's")
	local byName = {}
	for _, l in ipairs(ls) do byName[l.Name] = l end
	assert(#ls == 3 and byName.Label and byName.Label_Top and byName.Label_Bottom, "5: STACKED holds " .. #ls .. " labels, want Label_Top, Label, Label_Bottom")
	assert(byName.Label.Size.Y.Scale > byName.Label_Top.Size.Y.Scale and byName.Label.Size.Y.Scale > byName.Label_Bottom.Size.Y.Scale, "5: STACKED's middle word is not the biggest")
	assert(byName.Label_Top.Position.Y.Scale < byName.Label.Position.Y.Scale and byName.Label.Position.Y.Scale < byName.Label_Bottom.Position.Y.Scale, "5: STACKED's words are not top, middle, bottom")
	bold:Destroy(); framed:Destroy(); stacked:Destroy()
	for _, junk in ipairs({ { w = 0, c = 1, s = 1 }, { w = 13, c = 1, s = 1 }, { w = 1, c = 9, s = 1 }, { w = 1, c = 1, s = 4 }, { w = 2.5, c = 1, s = 1 }, { w = "1", c = 1, s = 1 } }) do
		local m = RoomItems.Poster(junk, Cfg)
		assert(m == nil, "5: RoomItems.Poster(" .. show(junk) .. ") built a model, want nil")
	end
	assert(RoomItems.Poster(nil, Cfg) == nil, "5: RoomItems.Poster(nil) built a model, want nil")
	table.insert(out, "5 styles: BOLD one word; FRAMED a Border in the ink and a smaller word; STACKED three, the middle biggest; junk designs build nothing")

	-- 6. posters count toward home's limit
	local limit = Cfg.Kinds.home.limit
	local cells = scan("home", "plant")
	assert(#cells >= limit - 2, "premise: home has " .. #cells .. " free cells for a plant, want " .. (limit - 2))
	local list = { { id = "poster", slot = 1, w = 5, c = 8, s = 3 } }
	for i = 1, limit - 2 do table.insert(list, { id = "plant", x = cells[i][1], z = cells[i][2], r = 0 }) end
	local kept = call("SetHome", { v = 1, door = Cfg.DoorDefault, items = { home = list } })
	assert(type(kept) == "table" and type(kept.items) == "table" and type(kept.items.home) == "table" and #kept.items.home == limit - 1, "6: SetHome kept " .. show(kept) .. ", want all " .. (limit - 1) .. " home items")
	assert(state().rooms.home.used == limit - 1, "6: State's home used " .. tostring(state().rooms.home.used) .. " after SetHome, want " .. (limit - 1))
	local free = scan("home", "plant")
	assert(#free >= 1, "premise: no free cell left for a plant in home")
	local res6 = edit(poster(2, 1, 1, 1))
	assert(type(res6) == "table" and res6.ok == true, "6: a poster on slot 2 as item " .. limit .. " answered " .. show(res6) .. ", want ok")
	local idx2 = res6.index
	assert(state().rooms.home.used == limit, "6: State's home used " .. tostring(state().rooms.home.used) .. ", want " .. limit .. " (posters count)")
	refused(edit(poster(3, 1, 1, 1)), "limit", "6 a poster on slot 3 past the limit")
	refused(edit({ op = "place", kind = "home", id = "plant", x = free[1][1], z = free[1][2], r = 0 }), "limit", "6 a plant past the limit (posters count)")
	local res6b = edit(poster(2, 3, 2, 2))
	assert(type(res6b) == "table" and res6b.ok == true and res6b.index == idx2, "6: a redesign of slot 2 at the limit answered " .. show(res6b) .. ", want ok at index " .. tostring(idx2))
	local st6 = state().rooms.home
	assert(st6.used == limit and #st6.items == limit, "6: after the redesign State's home reads used " .. tostring(st6.used) .. ", items " .. #st6.items .. "; want " .. limit .. " and " .. limit)
	local e2 = st6.items[idx2]
	assert(type(e2) == "table" and e2.id == "poster" and e2.slot == 2 and e2.w == 3 and e2.c == 2 and e2.s == 2, "6: the slot 2 poster reads " .. show(e2) .. ", want 3/2/2")
	local res6c = edit({ op = "remove", kind = "home", index = idx2 })
	assert(type(res6c) == "table" and res6c.ok == true, "6: removing the slot 2 poster answered " .. show(res6c))
	assert(state().rooms.home.used == limit - 1, "6: State's home used " .. tostring(state().rooms.home.used) .. " after the remove, want " .. (limit - 1))
	assert(waitFor(function() return #postersIn(home) == 1 end, 3), "6: Room_home.Items holds " .. #postersIn(home) .. " poster models after the remove, want 1")
	table.insert(out, string.format("6 limit %d: %d plants + the slot 1 poster kept; a poster on slot 2 fills it; slot 3 and a plant -> limit; a redesign at the limit -> ok; remove -> used %d",
		limit, limit - 2, limit - 1))

	-- 7. no player-typed text
	local plot = plotModel()
	local found = {}
	for _, where in ipairs({ plot, game:GetService("StarterGui"), p:FindFirstChildOfClass("PlayerGui"), RS.OK }) do
		if where then for _, f in ipairs(textBoxes(where)) do table.insert(found, f) end end
	end
	assert(#found == 0, "7: TextBox found: " .. table.concat(found, ", ") .. " (no player-typed text anywhere)")
	table.insert(out, "7 no TextBox in the plot, StarterGui, the server's view of PlayerGui or ReplicatedStorage.OK")

	-- 8. budgets
	assert(lights(home) <= 1, "8: Room_home holds " .. lights(home) .. " lights, want at most 1")
	table.insert(out, string.format("8 Room_home %d light", lights(home)))
	return "T112A PLAY OK\n" .. table.concat(out, "\n") .. string.format("\nelapsed %.1f s", os.clock() - T0)
end

local ok, msg = pcall(run)
if not ok then
	local restored, steps = putBack()
	error(msg .. (#steps > 0 and ("\n(the put-back also hit: " .. table.concat(steps, "; ") .. ")") or "")
		.. (restored ~= true and "\n(ProfileRestore answered " .. tostring(restored) .. ")" or ""), 0)
end
-- tail for t112b, nothing reset: home still owned, its items emptied, the player in Room_home
local kept = rooms:Invoke("SetHome", uid, { v = 1, door = Cfg.DoorDefault, items = {} })
assert(type(kept) == "table", "tail: SetHome (empty) failed")
assert(rooms:Invoke("GoIn", uid, "home") == true, "tail: GoIn(home) returned false")
local info = rooms:Invoke("Plot", uid)
assert(type(info) == "table" and placeIs(tostring(info.slot) .. "/home"), "tail: the player is not in Room_home (PlaceOf " .. show(rooms:Invoke("PlaceOf", uid)) .. ")")
local st = rooms:Invoke("State", uid)
local hm = type(st) == "table" and type(st.rooms) == "table" and st.rooms.home
assert(type(hm) == "table" and #hm.items == 0 and hm.used == 0 and st.inside == "home", "tail: State reads " .. show(st) .. ", want an empty home with the player inside")
return msg
