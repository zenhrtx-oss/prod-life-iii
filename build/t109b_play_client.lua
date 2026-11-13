-- Client, during play (the Your Rooms plan, Task 10: decorate mode, phone first), after t109a's tail: the player woke up
-- in their bedroom, whose home holds only a floor lamp kept unbuilt (locked: the BUZZING tier isn't held; R-T10 fix 1). Every step waits for its state (an attribute, a property, a server answer) with a
-- generous timeout, never for a frame count: a locked Mac can hold this client near 2 fps. Commands go through the edit
-- bar's own seam (PlayerGui.OK_Room's Command attribute, what its buttons set), each awaited until RoomClient clears it;
-- the server is read through the real Room_Get remote, and every edit goes through the real Room_Edit.
-- (1) The bedroom (Workspace.OK_Plots.Plot_<PlotSlot>.Room_bedroom, owned by this player) is on this client; its door's
--     DecoratePrompt is on here and reads "Decorate" / "Your room". The visitor rule: a DecoratePrompt in a room Model
--     owned by someone else, added under OK_Plots (a local stand-in), is turned off by RoomClient within 3 s; one in a room
--     this player owns stays on. OK_Room is DisplayOrder 7 with CoreUISafeInsets, not editing, its bar hidden.
-- (2) In: standing at the Entrance facing the door, the DecoratePrompt pressed (InputHoldBegin / End, as t101b) puts the
--     client in decorate mode (Editing, Kind bedroom). The camera is Scriptable and straight down (both together: the press
--     itself left the camera Scriptable, aimed level at the door), above the room (inside its
--     box, 8 studs up or more), and the room's four floor corners are on the screen above the bar. The ControlModule reads
--     itself disabled (OK_Room's ControlsOn false: RoomClient reads its controlsEnabled back, R-T10 fix 2; this file can't
--     require it, from its own VM that would be a second copy) and every prompt is off (ProximityPromptService); the
--     character stays put for 1 s. The
--     room's parts 7 studs or more above its floor (the ceiling) are hidden on this client. The bar shows "Pick a thing,
--     then tap ADD." (copy 6.13) and the rug (the first open item, catalog order).
-- (3) The unbuilt floor lamp (R-T10 fix 1): it shows as a faint ghost (OK_DecoratePreview.Unbuilt_1, transparency 0.8 or
--     more) and still holds its cell: "next" -> the plant, "add", "cell:<the lamp's cell>" -> GhostOk false; "place" ->
--     LastEdit overlap (the server refuses it too), the overlap sentence, Room_Get unchanged; "cancel", "prev" -> the rug.
--     The edit flow at the real screen (the rug becomes item 2, after the lamp): "add" -> Selected new:rug, a see-through ghost (transparency 0.5 or more, never
--     queried or colliding) in the room's OK_DecoratePreview; "cell:<a free cell>" (RoomRules.Fits on Room_Get's answer) ->
--     Ghost at that cell, GhostOk; "place" -> LastEdit ok, and Room_Get's bedroom holds the rug at that cell (the room's Items
--     shows its model); the ghost goes. "next" -> the plant; "add", "cell:<the rug's cell>" -> GhostOk false and the ghost
--     red; "place" -> LastEdit overlap, the hint reads "Something's already there." (copy 6.35) and Room_Get still holds
--     one item. A tap (the "tap:x,y" seam: a real tap's own path) on a free cell's centre moves the ghost there (GhostOk);
--     "cancel"; a tap on the rug's model picks it (Selected item:2, copy 6.15's hint); "rotate" turns its ghost (r 1).
--     Free cells come from RoomRules.Fits with the unbuilt lamp's cells held (UnbuiltCells), as the server's Edit runs it.
-- (4) Phone first: OK_Room forced (ForceViewport) to 667x375, 771x390 and 844x390 less this gui's insets, and to 640x360
--     (two rows there, under 667 px wide). In each of the three states (nothing picked, a new item, a placed item) every
--     visible button is 44 px or more both ways, inside (0, 0)-vp, and overlaps no other.
-- (5) Remove: "pick:2", "remove" -> LastEdit ok, Room_Get's bedroom holds only the floor lamp again and the room's Items hold
--     no model.
-- (6) "done" -> Editing false (LeftBy done), the camera Custom, the controls back, the prompts back, the hidden parts as
--     they were, no OK_DecoratePreview left, the bar hidden.
-- (7) A teleport ends it too: in again by the prompt, then the character moved 6 studs -> Editing false (LeftBy moved),
--     the camera Custom and the controls back.
-- On any error, and after success: decorate mode left (DONE: the controls come back with it), the force off, the camera
-- given back, the character moved to the lounge; the error is rethrown.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character
local root = char and char:WaitForChild("HumanoidRootPart", 5)
local hum = char and char:WaitForChild("Humanoid", 5)
assert(root and hum, "no live character")
local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui", 10)
local RED = " (before the R-T10 sync of Modules/RoomUI, OK/RoomClient and Systems/Rooms: the expected red)"
local gui = pg and pg:WaitForChild("OK_Room", 10)
assert(gui, "no PlayerGui.OK_Room (RoomUI.Build did not run)" .. RED)
local bar = gui:WaitForChild("Root", 5) and gui.Root:WaitForChild("Bar", 5)
assert(bar, "OK_Room has no Root.Bar")
local Config = require(RS.OK.Config)
local Rules = require(RS.OK.Modules.RoomRules)
local Catalog = require(RS.OK.Data.RoomCatalog)
local RoomGet = RS.OK.Remotes:WaitForChild("Room_Get", 5)
assert(RoomGet, "no Remotes.Room_Get")
local Cfg = Config.Rooms
local LOUNGE = Vector3.new(24, 3, 0)
local CEILING_MIN = 7
local out = {}

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function str(v) return string.format("(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z) end
local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function attr(name) return gui:GetAttribute(name) end
local function show(v) local okJ, js = pcall(function() return game:GetService("HttpService"):JSONEncode(v) end); return okJ and js or tostring(v) end
local function rootNow() return player.Character and player.Character:FindFirstChild("HumanoidRootPart") end
-- one command through the bar's seam: set, wait until RoomClient took it (cleared), then for `want` (a function)
local function cmd(c, want, label, t)
	gui:SetAttribute("Command", c)
	assert(waitFor(function() return attr("Command") == "" end, 5), label .. ": the Command '" .. c .. "' was not taken within 5 s (RoomClient's decorate mode)" .. RED)
	if want then
		assert(waitFor(want, t or 6), label .. ": after '" .. c .. "' Selected " .. tostring(attr("Selected")) .. ", Ghost " .. tostring(attr("Ghost"))
			.. ", GhostOk " .. tostring(attr("GhostOk")) .. ", LastEdit " .. tostring(attr("LastEdit")) .. ", Item " .. tostring(attr("Item")) .. ", hint '" .. tostring(bar.Hint.Text) .. "'")
	end
end
local function serverBedroom()
	local ok, st = pcall(function() return RoomGet:InvokeServer() end)
	assert(ok and type(st) == "table" and type(st.rooms) == "table" and type(st.rooms.bedroom) == "table", "Room_Get answered " .. show(st))
	return st.rooms.bedroom, st
end
-- every lowest cell where `id` (turned r) fits the server's bedroom now
local function freeCells(id, r)
	local bed, st = serverBedroom()
	local set = {}
	for _, u in ipairs(st.unlocked) do set[u] = true end
	local kc = { limit = bed.limit, grid = bed.grid, keep = bed.keep, posters = bed.slots }
	local unbuilt = {} -- the saved floor items that don't stand: their cells stay taken (R-T10 fix 1)
	for i, e in ipairs(bed.items) do
		local it = Catalog.ById[e.id]
		if it and it.kind == "floor" and it.unlock ~= nil and not set[e.id] then table.insert(unbuilt, i) end
	end
	local held = Rules.UnbuiltCells(bed.items, unbuilt, Catalog)
	local found, seen = {}, {}
	for _, a in ipairs(bed.grid) do
		for cx = math.floor(math.min(a[1], a[3])), math.ceil(math.max(a[1], a[3])) do
			for cz = math.floor(math.min(a[2], a[4])), math.ceil(math.max(a[2], a[4])) do
				local key = cx .. ":" .. cz
				if not seen[key] then
					seen[key] = true
					if Rules.Fits(bed.items, { id = id, x = cx, z = cz, r = r or 0 }, kc, Catalog, set, "bedroom", nil, Cfg, held) then table.insert(found, { cx, cz }) end
				end
			end
		end
	end
	return found
end
-- the ControlModule's own state (controlsEnabled, else its active controller's `enabled`), as RoomClient read it back right
-- after disabling or enabling it (OK_Room's ControlsOn; nil: unreadable). This file never requires the ControlModule: from
-- its own VM that would be a second copy
local function controlsOn() return attr("ControlsOn") end
local function rect(g, box) local p = g.AbsolutePosition - box; return { x0 = p.X, y0 = p.Y, x1 = p.X + g.AbsoluteSize.X, y1 = p.Y + g.AbsoluteSize.Y } end
local function overlaps(a, b) return a.x0 < b.x1 - 0.5 and b.x0 < a.x1 - 0.5 and a.y0 < b.y1 - 0.5 and b.y0 < a.y1 - 0.5 end
local function visibleButtons()
	local list = {}
	for _, d in ipairs(bar:GetDescendants()) do if d:IsA("GuiButton") and d.Visible then table.insert(list, d) end end
	table.sort(list, function(a, b) return a.Name < b.Name end)
	return list
end
local function checkLayout(where, vp)
	local box = gui.Root.AbsolutePosition
	assert(bar.Visible, where .. ": the bar is hidden")
	local bs = visibleButtons()
	assert(#bs >= 2, where .. ": only " .. #bs .. " visible buttons")
	local names = {}
	for _, b in ipairs(bs) do
		local r = rect(b, box)
		assert(b.AbsoluteSize.X >= 44 and b.AbsoluteSize.Y >= 44, string.format("%s: %s is %.0fx%.0f, want 44x44 or more", where, b.Name, b.AbsoluteSize.X, b.AbsoluteSize.Y))
		assert(r.x0 >= -0.5 and r.y0 >= -0.5 and r.x1 <= vp.X + 0.5 and r.y1 <= vp.Y + 0.5, string.format("%s: %s at (%.0f,%.0f)-(%.0f,%.0f) is outside (0,0)-(%.0f,%.0f)",
			where, b.Name, r.x0, r.y0, r.x1, r.y1, vp.X, vp.Y))
		table.insert(names, b.Name)
	end
	for i = 1, #bs do
		for j = i + 1, #bs do
			assert(not overlaps(rect(bs[i], box), rect(bs[j], box)), where .. ": " .. bs[i].Name .. " overlaps " .. bs[j].Name)
		end
	end
	return table.concat(names, ",")
end

local slot, bedroom, door, decor
local function run()
	-- 1. the bedroom, its DecoratePrompt, the visitor rule, the gui
	assert(waitFor(function() slot = player:GetAttribute("PlotSlot"); return type(slot) == "number" and slot > 0 end, 3), "PlotSlot is " .. tostring(slot) .. " (t109a's tail wakes the player up in their bedroom)")
	local plots = workspace:WaitForChild("OK_Plots", 5)
	assert(plots, "Workspace.OK_Plots is not on this client")
	local name = string.format("Plot_%02d", slot)
	assert(waitFor(function()
		local pm = plots:FindFirstChild(name)
		bedroom = pm and pm:FindFirstChild("Room_bedroom")
		if not bedroom then return false end
		door = nil
		for _, d in ipairs(bedroom:GetDescendants()) do if d:IsA("BasePart") and d:GetAttribute("RoomDoor") == true then door = d; break end end
		decor = door and door:FindFirstChild("DecoratePrompt")
		return decor ~= nil
	end, 5), name .. ".Room_bedroom (with its door's DecoratePrompt) is not on this client" .. RED)
	assert(bedroom:GetAttribute("OwnerId") == player.UserId, "Room_bedroom is owned by " .. tostring(bedroom:GetAttribute("OwnerId")) .. ", not this player")
	assert(decor:IsA("ProximityPrompt") and decor.Enabled and decor.ActionText == "Decorate" and decor.ObjectText == "Your room",
		"the owner's DecoratePrompt is off here or reads '" .. tostring(decor.ActionText) .. "' / '" .. tostring(decor.ObjectText) .. "'")
	local function fake(owner)
		local m = Instance.new("Model")
		m.Name = "OK_T109_Fake_" .. tostring(owner)
		m:SetAttribute("RoomKind", "bedroom"); m:SetAttribute("OwnerId", owner)
		local part = Instance.new("Part")
		part.Anchored = true; part.CanCollide = false; part.CanQuery = false; part.Transparency = 1
		part.CFrame = CFrame.new(0, -500, 0); part.Parent = m
		local pp = Instance.new("ProximityPrompt"); pp.Name = "DecoratePrompt"; pp.Parent = part
		m.Parent = plots
		return m, pp
	end
	local theirs, theirPP = fake(-12345)
	local mine, minePP = fake(player.UserId)
	local off = waitFor(function() return theirPP.Enabled == false end, 3)
	task.wait(0.3)
	local mineOn = minePP.Enabled
	theirs:Destroy(); mine:Destroy()
	assert(off, "a DecoratePrompt in someone else's room stayed on: RoomClient should turn off every one it doesn't own" .. RED)
	assert(mineOn, "a DecoratePrompt in this player's own room was turned off")
	assert(gui.DisplayOrder == 7 and gui.ScreenInsets == Enum.ScreenInsets.CoreUISafeInsets, "OK_Room is DisplayOrder " .. gui.DisplayOrder .. ", " .. tostring(gui.ScreenInsets) .. "; want 7, CoreUISafeInsets")
	assert(attr("Editing") == false and not bar.Visible, "decorate mode is on (or its bar shows) before the prompt is pressed")
	table.insert(out, "1 " .. name .. ".Room_bedroom: the door's DecoratePrompt on for its owner ('Decorate' / 'Your room'); someone else's turned off, one's own kept; OK_Room DisplayOrder 7, CoreUISafeInsets, idle")

	-- the parts at ceiling height, before
	local pivot = bedroom:GetPivot()
	local tops = {}
	local itemsF = bedroom:FindFirstChild("Items")
	for _, d in ipairs(bedroom:GetDescendants()) do
		if d:IsA("BasePart") and not (itemsF and d:IsDescendantOf(itemsF)) then
			local cf, s = d.CFrame, d.Size
			local halfY = (math.abs(cf.RightVector.Y) * s.X + math.abs(cf.UpVector.Y) * s.Y + math.abs(cf.LookVector.Y) * s.Z) / 2
			if d.Position.Y - halfY - pivot.Y >= CEILING_MIN then tops[d] = d.LocalTransparencyModifier end
		end
	end
	local nTops = 0
	for _ in pairs(tops) do nTops += 1 end
	assert(nTops >= 1, "premise: the bedroom has no part 7 studs or more above its floor (its ceiling)")

	-- 2. in, by the prompt
	local entrance
	for _, d in ipairs(bedroom:GetDescendants()) do if d:IsA("Attachment") and d.Name == "Entrance" then entrance = d; break end end
	assert(entrance, "the bedroom has no Entrance attachment")
	local function pressIn(label)
		local stand = entrance.WorldPosition + Vector3.new(0, 3, 0)
		local r = rootNow()
		r.CFrame = CFrame.lookAt(stand, Vector3.new(door.Position.X, stand.Y, door.Position.Z))
		task.wait(0.8)
		r = rootNow()
		local d = (r.Position - door.Position).Magnitude
		assert(d < decor.MaxActivationDistance, string.format("%s: standing %.1f studs from the door, past the prompt's reach %.1f", label, d, decor.MaxActivationDistance))
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = CFrame.lookAt(r.Position + Vector3.new(0, 2, 0) - (door.Position - r.Position) * Vector3.new(1, 0, 1) * 0.4, door.Position)
		task.wait(0.4)
		local entered = false
		for _ = 1, 4 do
			decor:InputHoldBegin(); task.wait(0.05); decor:InputHoldEnd()
			if waitFor(function() return attr("Editing") == true end, 3) then entered = true; break end
		end
		assert(entered, label .. ": pressing the DecoratePrompt did not put the client in decorate mode (Editing " .. tostring(attr("Editing")) .. ")" .. RED)
	end
	pressIn("2")
	assert(attr("Kind") == "bedroom", "2: decorating Kind " .. tostring(attr("Kind")) .. ", want bedroom")
	-- the press set the camera Scriptable itself (aimed level at the door), so the type alone proves nothing: wait for decorate
	-- mode's own camera, Scriptable AND straight down (R-T10 fix 3, review minor 4)
	assert(waitFor(function() return cam.CameraType == Enum.CameraType.Scriptable and cam.CFrame.LookVector:Dot(-bedroom:GetPivot().UpVector) > 0.99 end, 3),
		"2: the camera is " .. tostring(cam.CameraType) .. " looking along " .. str(cam.CFrame.LookVector) .. " in decorate mode, want Scriptable and straight down")
	local size = Cfg.Kinds.bedroom.size
	local cf = cam.CFrame
	local lp = pivot:PointToObjectSpace(cf.Position)
	assert(cf.LookVector:Dot(-pivot.UpVector) > 0.99, "2: the camera looks along " .. str(cf.LookVector) .. ", want straight down")
	assert(math.abs(lp.X) <= size[1] / 2 and math.abs(lp.Z) <= size[2] / 2 and lp.Y >= 8, string.format("2: the camera sits at room-local %s, want over the room (|x| <= %.1f, |z| <= %.1f) and 8 studs up or more",
		str(lp), size[1] / 2, size[2] / 2))
	local barTop = bar.AbsolutePosition.Y
	local V = cam.ViewportSize
	for _, c in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
		local w = pivot:PointToWorldSpace(Vector3.new(c[1] * size[1] / 2, 0, c[2] * size[2] / 2))
		local sp, onScreen = cam:WorldToScreenPoint(w)
		assert(onScreen and sp.X >= -1 and sp.X <= V.X + 1 and sp.Y >= -1 and sp.Y <= barTop + 1, string.format(
			"2: the floor corner (%d, %d) shows at (%.0f, %.0f), want on the screen above the bar (top %.0f) and inside %.0fx%.0f", c[1], c[2], sp.X, sp.Y, barTop, V.X, V.Y))
	end
	local con = controlsOn()
	assert(con == false, "2: OK_Room's ControlsOn (the ControlModule, read back) is " .. tostring(con) .. " in decorate mode, want false (nil: unreadable)")
	assert(PPS.Enabled == false, "2: ProximityPromptService is on in decorate mode")
	local at = rootNow().Position
	task.wait(1)
	assert(flat(rootNow().Position - at) < 0.5, "2: the character moved " .. string.format("%.2f", flat(rootNow().Position - at)) .. " studs in a second of decorate mode")
	for part in pairs(tops) do
		assert(part.LocalTransparencyModifier == 1, "2: " .. part:GetFullName() .. " (at ceiling height) is not hidden in decorate mode")
	end
	assert(bar.Visible and bar.Hint.Text == "Pick a thing, then tap ADD." and attr("Item") == "rug" and attr("Selected") == "",
		"2: the bar reads hint '" .. bar.Hint.Text .. "', Item " .. tostring(attr("Item")) .. ", Selected " .. tostring(attr("Selected")) .. "; want copy 6.13, rug, nothing picked")
	table.insert(out, string.format("2 in by the prompt: Scriptable straight down at %.1f studs over the room, its floor on screen above the bar; controls off, prompts off, still for 1 s; %d ceiling part(s) hidden; the bar shows 6.13 and the rug", lp.Y, nTops))

	-- 3. the unbuilt floor lamp (R-T10 fix 1), then the edit flow
	local bed0 = serverBedroom()
	assert(#bed0.items == 1 and bed0.items[1].id == "floor_lamp" and bed0.used == 0, "premise: the bedroom should hold only t109a's tail's unbuilt floor lamp, got "
		.. show(bed0.items) .. " (used " .. tostring(bed0.used) .. ")")
	local lamp = bed0.items[1]
	local preview = bedroom:FindFirstChild("OK_DecoratePreview")
	local faint = preview and preview:FindFirstChild("Unbuilt_1")
	assert(faint, "3: the unbuilt floor lamp has no faint ghost (OK_DecoratePreview.Unbuilt_1)")
	for _, d in ipairs(faint:GetDescendants()) do
		if d:IsA("BasePart") then assert(d.Transparency >= 0.8 and not d.CanQuery and not d.CanCollide, "3: the faint ghost's " .. d.Name .. " is not faint, or answers a ray or collides") end
	end
	local cellLamp = string.format("%d,%d,0", lamp.x, lamp.z)
	cmd("next", function() return attr("Item") == "plant" end, "3 next (to the plant, for the lamp)")
	cmd("add", function() return attr("Selected") == "new:plant" end, "3 add a plant (for the lamp)")
	cmd("cell:" .. lamp.x .. "," .. lamp.z, function() return attr("Ghost") == cellLamp and attr("GhostOk") == false end, "3 a plant over the unbuilt lamp")
	cmd("place", function() return attr("LastEdit") == "overlap" end, "3 place over the unbuilt lamp", 8)
	assert(bar.Hint.Text == "Something's already there.", "3: placing over the unbuilt lamp shows '" .. bar.Hint.Text .. "', want copy 6.35")
	assert(#serverBedroom().items == 1, "3: the refused place over the unbuilt lamp changed the server's bedroom")
	cmd("cancel", function() return attr("Selected") == "" end, "3 cancel (the lamp)")
	cmd("prev", function() return attr("Item") == "rug" end, "3 prev (back to the rug)")
	local rugCells = freeCells("rug")
	assert(#rugCells >= 1, "premise: the bedroom has no free cell for a rug")
	local c = rugCells[1]
	cmd("add", function() return attr("Selected") == "new:rug" and attr("Ghost") ~= "" end, "3 add")
	local ghost = preview:FindFirstChild("Ghost")
	assert(ghost and ghost:GetAttribute("ItemId") == "rug", "3: no rug ghost in the room's OK_DecoratePreview")
	for _, d in ipairs(ghost:GetDescendants()) do
		if d:IsA("BasePart") then
			assert(d.Transparency >= 0.5 and not d.CanQuery and not d.CanCollide and not d.CanTouch, "3: the ghost's " .. d.Name .. " is not see-through, or answers a ray, collides or touches")
		end
	end
	local cellRug = string.format("%d,%d,0", c[1], c[2])
	cmd("cell:" .. c[1] .. "," .. c[2], function() return attr("Ghost") == cellRug and attr("GhostOk") == true end, "3 cell (free)")
	cmd("place", function() return attr("LastEdit") == "ok" end, "3 place", 8)
	local bed1 = serverBedroom()
	local RUG = 2 -- after the unbuilt lamp
	local rugE = bed1.items[RUG]
	assert(#bed1.items == 2 and rugE and rugE.id == "rug" and rugE.x == c[1] and rugE.z == c[2] and (rugE.r or 0) == 0,
		"3: Room_Get's bedroom reads " .. show(bed1.items) .. ", want the lamp, then the rug at (" .. c[1] .. ", " .. c[2] .. ")")
	assert(waitFor(function() local f = bedroom:FindFirstChild("Items"); local m = f and f:FindFirstChild("Item_" .. RUG); return m ~= nil and m:GetAttribute("ItemId") == "rug" end, 4),
		"3: the rug's model is not in the room's Items on this client")
	assert(attr("Selected") == "" and attr("Ghost") == "", "3: after the place the ghost is still up (Selected " .. tostring(attr("Selected")) .. ")")
	cmd("next", function() return attr("Item") == "plant" end, "3 next")
	cmd("add", function() return attr("Selected") == "new:plant" end, "3 add a plant")
	local cellPlant = string.format("%d,%d,0", c[1], c[2])
	cmd("cell:" .. c[1] .. "," .. c[2], function() return attr("Ghost") == cellPlant and attr("GhostOk") == false end, "3 cell (the rug's)")
	ghost = preview:FindFirstChild("Ghost")
	local red = true
	for _, d in ipairs(ghost and ghost:GetDescendants() or {}) do
		if d:IsA("BasePart") then
			local col = d.Color
			if math.floor(col.R * 255 + 0.5) ~= 230 or math.floor(col.G * 255 + 0.5) ~= 60 or math.floor(col.B * 255 + 0.5) ~= 60 then red = false end
		end
	end
	assert(ghost and red, "3: the plant's ghost on the rug's cell is not red")
	cmd("place", function() return attr("LastEdit") == "overlap" end, "3 place on the rug", 8)
	assert(bar.Hint.Text == "Something's already there.", "3: the overlap shows '" .. bar.Hint.Text .. "', want copy 6.35 \"Something's already there.\"")
	assert(#serverBedroom().items == 2, "3: the refused place changed the server's bedroom")
	-- a real tap's path: a free cell's centre, then the rug
	local free = freeCells("plant")
	assert(#free >= 1, "premise: no free cell for a plant beside the rug")
	local fc = free[1]
	local sp = cam:WorldToScreenPoint(pivot:PointToWorldSpace(Vector3.new(fc[1] + 0.5, 0, fc[2] + 0.5)))
	local want = string.format("%d,%d,0", fc[1], fc[2])
	cmd(string.format("tap:%.1f,%.1f", sp.X, sp.Y), function() return attr("Ghost") == want and attr("GhostOk") == true end, "3 tap a free cell")
	cmd("cancel", function() return attr("Selected") == "" end, "3 cancel")
	local rugModel = bedroom.Items:FindFirstChild("Item_" .. RUG)
	local sr = cam:WorldToScreenPoint(rugModel:GetPivot().Position + pivot.UpVector * 0.05)
	cmd(string.format("tap:%.1f,%.1f", sr.X, sr.Y), function() return attr("Selected") == "item:" .. RUG end, "3 tap the rug")
	assert(bar.Hint.Text == "Move it, turn it or take it away." and attr("Ghost") == cellRug, "3: the picked rug shows hint '" .. bar.Hint.Text .. "', Ghost " .. tostring(attr("Ghost")) .. "; want copy 6.15, " .. cellRug)
	cmd("rotate", function() return attr("Ghost") == string.format("%d,%d,1", c[1], c[2]) end, "3 rotate")
	cmd("cancel", function() return attr("Selected") == "" end, "3 cancel again")
	table.insert(out, string.format("3 the unbuilt floor lamp: a faint ghost, a plant over it red and refused 'overlap' (6.35); edit: add -> a see-through rug ghost; cell (%d, %d) -> GhostOk; place -> ok, Room_Get holds the rug there; the plant on the rug's cell -> red, place -> 'overlap' and copy 6.35; a tap on free cell (%d, %d) moves the ghost; a tap on the rug picks it (6.15); rotate -> r 1",
		c[1], c[2], fc[1], fc[2]))

	-- 4. phone first
	local inset = cam.ViewportSize - gui.AbsoluteSize
	inset = Vector2.new(math.max(0, inset.X), math.max(0, inset.Y))
	local states = {
		{ "none", function() cmd("cancel", function() return attr("Selected") == "" end, "4 none") end },
		{ "new", function() cmd("add", function() return attr("Selected") == "new:plant" end, "4 new") end },
		{ "placed", function()
			cmd("cancel", function() return attr("Selected") == "" end, "4 placed (cancel)")
			cmd("pick:" .. RUG, function() return attr("Selected") == "item:" .. RUG end, "4 placed")
		end },
	}
	for _, screen in ipairs({ Vector2.new(667, 375), Vector2.new(771, 390), Vector2.new(844, 390), Vector2.new(640, 360) }) do
		local vp = screen - inset
		local where = vp.X .. "x" .. vp.Y .. " (" .. screen.X .. "x" .. screen.Y .. " less " .. inset.X .. "x" .. inset.Y .. ")"
		gui:SetAttribute("ForceViewport", vp)
		local layoutKey = string.format("%dx%d", math.floor(vp.X + 0.5), math.floor(vp.Y + 0.5))
		assert(waitFor(function() return attr("Layout") == layoutKey end, 5), where .. ": the bar was not laid out for the forced size (Layout " .. tostring(attr("Layout")) .. ")")
		local seen = {}
		for _, st in ipairs(states) do
			st[2]()
			task.wait(0.1)
			local names = checkLayout(where .. " " .. st[1], vp)
			if vp.X < 667 then assert(attr("Rows") == 2, where .. " " .. st[1] .. ": " .. tostring(attr("Rows")) .. " row(s), want 2 under 667 px wide") end
			table.insert(seen, st[1] .. " " .. tostring(attr("Rows")) .. " row(s) [" .. names .. "]")
		end
		table.insert(out, "4 " .. where .. ": " .. table.concat(seen, "; "))
	end
	gui:SetAttribute("ForceViewport", nil)
	cmd("cancel", function() return attr("Selected") == "" end, "4 cancel")

	-- 5. remove
	cmd("pick:" .. RUG, function() return attr("Selected") == "item:" .. RUG end, "5 pick")
	cmd("remove", function() return attr("LastEdit") == "ok" and attr("Selected") == "" end, "5 remove", 8)
	local left = serverBedroom().items
	assert(#left == 1 and left[1].id == "floor_lamp", "5: Room_Get's bedroom holds " .. show(left) .. " after the remove, want only the unbuilt floor lamp")
	assert(waitFor(function() local f = bedroom:FindFirstChild("Items"); return f == nil or #f:GetChildren() == 0 end, 4), "5: the room's Items still hold a model on this client")
	table.insert(out, "5 remove: ok; Room_Get's bedroom holds only the unbuilt lamp and its Items are empty")

	-- 6. done
	cmd("done", function() return attr("Editing") == false end, "6 done")
	assert(attr("LeftBy") == "done", "6: LeftBy reads " .. tostring(attr("LeftBy")) .. ", want done")
	assert(waitFor(function() return cam.CameraType == Enum.CameraType.Custom end, 3), "6: the camera is " .. tostring(cam.CameraType) .. " after DONE, want Custom")
	assert(waitFor(function() return controlsOn() == true end, 3), "6: OK_Room's ControlsOn (the ControlModule, read back) is " .. tostring(controlsOn()) .. " after DONE, want true")
	assert(PPS.Enabled == true, "6: ProximityPromptService is still off after DONE")
	for part, v in pairs(tops) do
		assert(part.LocalTransparencyModifier == v, "6: " .. part:GetFullName() .. " is still hidden after DONE")
	end
	assert(bedroom:FindFirstChild("OK_DecoratePreview") == nil and not bar.Visible, "6: a preview folder or the bar is left after DONE")
	table.insert(out, "6 done: Editing off, the camera Custom, the controls and the prompts back, the ceiling shown, no preview left, the bar hidden")

	-- 7. a teleport ends it too
	cam.CameraType = Enum.CameraType.Custom
	pressIn("7")
	local r = rootNow()
	r.CFrame = r.CFrame + pivot:VectorToWorldSpace(Vector3.new(0, 0, -6))
	assert(waitFor(function() return attr("Editing") == false end, 4), "7: moving the character 6 studs did not end decorate mode")
	assert(attr("LeftBy") == "moved", "7: LeftBy reads " .. tostring(attr("LeftBy")) .. ", want moved")
	assert(waitFor(function() return cam.CameraType == Enum.CameraType.Custom and controlsOn() == true end, 3), "7: after the move the camera is " .. tostring(cam.CameraType) .. " and the controls read " .. tostring(controlsOn()))
	table.insert(out, "7 a teleport: decorate mode ended (moved), the camera Custom and the controls back")

	return "T109B PLAY OK\n" .. table.concat(out, "\n")
end

local ok, msg = pcall(run)
pcall(function() gui:SetAttribute("ForceViewport", nil) end)
pcall(function()
	if gui:GetAttribute("Editing") == true then
		gui:SetAttribute("Command", "done")
		waitFor(function() return gui:GetAttribute("Editing") == false end, 3)
	end
end)
pcall(function() cam.CameraType = Enum.CameraType.Custom end)
pcall(function()
	local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if h and h.Sit then h.Sit = false; task.wait(0.4) end
	if r then r.CFrame = CFrame.new(LOUNGE) end
end)
if not ok then error(msg, 0) end
return msg
