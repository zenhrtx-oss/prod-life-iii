-- Client, during play (the Your Rooms plan, Task 13: posters you design, phone first), after t112a's tail: home owned, its
-- saved items empty, the player in Room_home. Every step waits for its state (an attribute, a property, a server answer)
-- with a generous timeout, never for a frame count (the locked-screen ruling). Commands go through the edit bar's own seam
-- (PlayerGui.OK_Room's Command attribute, what its buttons set), each awaited until RoomClient clears it; the server is
-- read through the real Room_Get remote, and every edit goes through the real Room_Edit.
-- (1) Room_home (Workspace.OK_Plots.Plot_<PlotSlot>, owned by this player) is on this client with its Poster_1..n
--     Attachments (n = Config.Rooms.Kinds.home.posters) and its door's DecoratePrompt on.
-- (2) In: standing at the Entrance facing the door, the DecoratePrompt pressed (InputHoldBegin / End, as t109b) -> Editing,
--     Kind home, the camera Scriptable and straight down. With nothing picked the hint reads copy 6.13 then 9.29 ("Pick a
--     thing, then tap ADD. Tap an empty wall spot to hang a poster."). The wall spots (preflight m21: the Poster_n anchors
--     are Attachments, which no tap can hit): OK_DecoratePreview.PosterSlots holds one Part Slot_<i> per anchor, client
--     only, see-through (0.5 or more), queryable, never colliding or touching, within 3 studs (flat) of its anchor, on
--     the screen above the bar (both read in the camera's viewport space: the bar's top is its AbsolutePosition plus the gui
--     inset, the plates' points are WorldToViewportPoint's), and floating 0.055 stud or more above the floor, clear of the
--     booth mat's top at y 0.05 (the R-T13 review's M2a).
-- (3) A tap (the "tap:x,y" seam: a real tap's own path) on Slot_2's centre opens the designer for a new poster on slot 2:
--     Selected "slot:2", Poster "2,1,1,1"; the bar's Mode reads "POSTER" (copy 9.24) and its hint "Pick a word, a color and a
--     style." (9.30); the rows read WORD / LOUD, COLOR / RED, STYLE / BOLD (9.25-9.27, §9's names), HANG (9.28), ✕ CANCEL
--     and DONE show, 🗑 REMOVE doesn't (nothing hangs there yet). The camera faces the wall spot (Scriptable, looking along
--     the anchor's back axis within 0.99), and the live preview OK_DecoratePreview.PosterPreview (a RoomItems.Poster,
--     client only: never queryable) hangs on Poster_2 reading LOUD. Room_Get's home is still empty.
-- (4) No player-typed text: no TextBox anywhere in this client's PlayerGui (the game's guis; Roblox's own Chat, BubbleChat,
--     TouchGui and Freecam are skipped), with the designer open.
-- (5) The design: "word:-1" wraps to word 12 (SOON); "word:+1" twice -> 2 (GRIND); "color:+1" twice -> 3 (YELLOW: the
--     preview's Face in PosterColors[3]); "style:+1" -> 2 (FRAMED: the preview has a Border); "style:-1" twice wraps to 3
--     (STACKED: Label_Top in the preview). Each step: the Poster attribute, the row's value and the preview's Label follow.
--     Room_Get still holds no poster (the preview is client only).
-- (5b) R-T16 fix, I3 (the poster words were drawn at TextScaled's 8 px floor): "word:+8" -> 10, HUSTLE, the widest word; then
--     in each style (STACKED, "style:+1" -> BOLD, "style:+1" -> FRAMED, "style:+1" -> STACKED again) every label of the preview
--     reads TextBounds.Y at its floor or more and TextFits: BOLD's Label and STACKED's middle 28 px (about 12% of the 240 px
--     design), FRAMED's Label and STACKED's top and bottom 18 px. "word:-8" back to GRIND. The expected red, before the sync of
--     Modules/RoomItems: 8 px. (7) checks the hung poster's labels the same way.
-- (6) Phone first: OK_Room forced (ForceViewport) to 667x375, 771x390 and 844x390 less this gui's insets, and to 640x360:
--     every visible control of the designer (its buttons and the WORD, COLOR and STYLE value boxes) is 44 px or more both
--     ways, inside (0, 0)-vp, and overlaps no other.
-- (7) "hang" -> LastEdit ok; Room_Get's home holds exactly { poster, slot 2, 2/3/3 } (used 1); Room_home.Items shows its
--     model on Poster_2 reading GRIND; the designer closes (Selected "", Poster ""), the preview goes and the camera is
--     straight down again.
-- (8) A redesign: a tap on Slot_2 (now holding the poster) picks it: Selected "item:1", Poster "2,2,3,3", 🗑 REMOVE shows,
--     and the hung poster's own design is turned off on this client while the preview stands in front; the phone check
--     again in this state. "cancel" puts the hung poster's design back on. "slot:2" picks it again; "color:+1" -> 4,
--     "hang" -> ok; Room_Get still holds one poster, slot 2, now 2/4/3 (replaced, not added).
-- (9) Remove: "slot:2", "remove" -> ok; Room_Get's home holds nothing and Room_home.Items no model.
-- (10) "slot:3" opens a new design; "cancel" closes it, decorating goes on (Editing, the camera straight down). "done" ->
--     Editing false (LeftBy done), the camera Custom, the controls back (ControlsOn), no OK_DecoratePreview left.
-- On any error, and after success: the force off, decorate mode left (DONE), the camera given back (Custom); then the error
-- is rethrown. t112c puts the profile, the career and the rooms back.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character
local root = char and char:WaitForChild("HumanoidRootPart", 5)
local hum = char and char:WaitForChild("Humanoid", 5)
assert(root and hum, "no live character")
local cam = workspace.CurrentCamera
local pg = player:WaitForChild("PlayerGui", 10)
local RED = " (before the R-T13 sync of Modules/RoomUI, OK/RoomClient, Modules/RoomItems, Modules/RoomEdit and Systems/Rooms, and the R-T12/13 review fixes' sync of OK/RoomClient (the lifted plates): the expected red)"
local gui = pg and pg:WaitForChild("OK_Room", 10)
assert(gui, "no PlayerGui.OK_Room (RoomUI.Build did not run)")
local bar = gui:WaitForChild("Root", 5) and gui.Root:WaitForChild("Bar", 5)
assert(bar, "OK_Room has no Root.Bar")
local Config = require(RS.OK.Config)
local RoomGet = RS.OK.Remotes:WaitForChild("Room_Get", 5)
assert(RoomGet, "no Remotes.Room_Get")
local Cfg = Config.Rooms
local ROBLOX_GUIS = { Chat = true, BubbleChat = true, TouchGui = true, Freecam = true } -- Roblox's own, not the game's
local HINT_NONE = "Pick a thing, then tap ADD. Tap an empty wall spot to hang a poster." -- copy 6.13, 9.29
local HINT_DESIGN = "Pick a word, a color and a style." -- copy 9.30
local out = {}

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function str(v) return string.format("(%.2f, %.2f, %.2f)", v.X, v.Y, v.Z) end
local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function attr(name) return gui:GetAttribute(name) end
local function show(v) local okJ, js = pcall(function() return game:GetService("HttpService"):JSONEncode(v) end); return okJ and js or tostring(v) end
local function rootNow() return player.Character and player.Character:FindFirstChild("HumanoidRootPart") end
local function rgbIs(c, t) return c and t and math.abs(c.R * 255 - t[1]) < 1.5 and math.abs(c.G * 255 - t[2]) < 1.5 and math.abs(c.B * 255 - t[3]) < 1.5 end
local function state()
	return string.format("Selected %s, Poster %s, GhostOk %s, LastEdit %s, Mode '%s', hint '%s'", tostring(attr("Selected")), tostring(attr("Poster")),
		tostring(attr("GhostOk")), tostring(attr("LastEdit")), tostring(bar:FindFirstChild("Mode") and bar.Mode.Text), tostring(bar:FindFirstChild("Hint") and bar.Hint.Text))
end
-- one command through the bar's seam: set, wait until RoomClient took it (cleared), then for `want` (a function)
local function cmd(c, want, label, t)
	gui:SetAttribute("Command", c)
	assert(waitFor(function() return attr("Command") == "" end, 5), label .. ": the Command '" .. c .. "' was not taken within 5 s (RoomClient's decorate mode)")
	if want then assert(waitFor(want, t or 6), label .. ": after '" .. c .. "' " .. state() .. RED) end
end
local function serverHome()
	local ok, st = pcall(function() return RoomGet:InvokeServer() end)
	assert(ok and type(st) == "table" and type(st.rooms) == "table" and type(st.rooms.home) == "table", "Room_Get answered " .. show(st) .. ", want a home room")
	return st.rooms.home
end
local function rect(g, box) local p = g.AbsolutePosition - box; return { x0 = p.X, y0 = p.Y, x1 = p.X + g.AbsoluteSize.X, y1 = p.Y + g.AbsoluteSize.Y } end
local function overlaps(a, b) return a.x0 < b.x1 - 0.5 and b.x0 < a.x1 - 0.5 and a.y0 < b.y1 - 0.5 and b.y0 < a.y1 - 0.5 end
-- the designer's controls on show: every visible button in the bar, and the WORD, COLOR and STYLE value boxes
local function controls()
	local list = {}
	for _, d in ipairs(bar:GetChildren()) do
		if d:IsA("GuiObject") and d.Visible and (d:IsA("GuiButton") or d.Name == "Word" or d.Name == "Color" or d.Name == "Style") then table.insert(list, d) end
	end
	table.sort(list, function(a, b) return a.Name < b.Name end)
	return list
end
local function checkLayout(where, vp)
	local box = gui.Root.AbsolutePosition
	assert(bar.Visible, where .. ": the bar is hidden")
	local cs = controls()
	local names = {}
	for _, b in ipairs(cs) do
		local r = rect(b, box)
		assert(b.AbsoluteSize.X >= 44 and b.AbsoluteSize.Y >= 44, string.format("%s: %s is %.0fx%.0f, want 44x44 or more", where, b.Name, b.AbsoluteSize.X, b.AbsoluteSize.Y))
		assert(r.x0 >= -0.5 and r.y0 >= -0.5 and r.x1 <= vp.X + 0.5 and r.y1 <= vp.Y + 0.5, string.format("%s: %s at (%.0f,%.0f)-(%.0f,%.0f) is outside (0,0)-(%.0f,%.0f)",
			where, b.Name, r.x0, r.y0, r.x1, r.y1, vp.X, vp.Y))
		table.insert(names, b.Name)
	end
	for i = 1, #cs do
		for j = i + 1, #cs do
			assert(not overlaps(rect(cs[i], box), rect(cs[j], box)), where .. ": " .. cs[i].Name .. " overlaps " .. cs[j].Name)
		end
	end
	return table.concat(names, ","), #cs
end
local function textBoxes()
	local list = {}
	for _, g in ipairs(pg:GetChildren()) do
		if not ROBLOX_GUIS[g.Name] then
			if g:IsA("TextBox") then table.insert(list, g:GetFullName()) end
			for _, d in ipairs(g:GetDescendants()) do if d:IsA("TextBox") then table.insert(list, d:GetFullName()) end end
		end
	end
	return list
end
local function value(row) local f = bar:FindFirstChild(row); local v = f and f:FindFirstChild("Value"); return v and v.Text end
local function caption(row) local f = bar:FindFirstChild(row); local v = f and f:FindFirstChild("Caption"); return v and v.Text end
local function visible(name) local b = bar:FindFirstChild(name); return b ~= nil and b.Visible end

local home, preview
local function slotPart(i) local f = preview and preview:FindFirstChild("PosterSlots"); return f and f:FindFirstChild("Slot_" .. i) end
local function anchor(i)
	for _, d in ipairs(home:GetDescendants()) do if d:IsA("Attachment") and d.Name == "Poster_" .. i then return d end end
end
local function previewModel() return preview and preview:FindFirstChild("PosterPreview") end
local function previewLabel() local m = previewModel(); local l = m and m:FindFirstChild("Label", true); return l and l.Text end
local function topDown() return cam.CameraType == Enum.CameraType.Scriptable and cam.CFrame.LookVector:Dot(-home:GetPivot().UpVector) > 0.99 end
local function facing(i) local a = anchor(i); return a ~= nil and cam.CameraType == Enum.CameraType.Scriptable and cam.CFrame.LookVector:Dot(-a.WorldCFrame.LookVector) > 0.99 end
local function tapAt(part, label, want)
	local sp, onScreen = cam:WorldToScreenPoint(part.Position)
	assert(onScreen, label .. ": " .. part.Name .. " is off the screen")
	cmd(string.format("tap:%.1f,%.1f", sp.X, sp.Y), want, label)
end
-- R-T16 fix, I3: every label of a poster model `m` in `style` reads at least its floor (TextBounds.Y, px of the 240 px design)
-- and fits its box (TextFits); waited for (a fresh label's bounds come a frame late). Returns what it read
local TEXT_FLOORS = { [1] = { Label = 28 }, [2] = { Label = 18 }, [3] = { Label_Top = 18, Label = 28, Label_Bottom = 18 } }
local RED_I3 = " (before the R-T16 fix sync of Modules/RoomItems: TextScaled's 8 px floor, the expected red)"
local function textCheck(m, style, label)
	local want = TEXT_FLOORS[style]
	local good = waitFor(function()
		for name, floor in pairs(want) do
			local l = m and m.Parent and m:FindFirstChild(name, true)
			if not (l and l:IsA("TextLabel") and l.TextBounds.Y >= floor and l.TextFits) then return false end
		end
		return true
	end, 3)
	local seen = {}
	for name, floor in pairs(want) do
		local l = m and m:FindFirstChild(name, true)
		table.insert(seen, string.format("%s '%s' %s px tall (want %d+), TextFits %s, TextSize %s, TextScaled %s", name, l and l.Text or "?",
			l and tostring(math.floor(l.TextBounds.Y + 0.5)) or "none", floor, tostring(l and l.TextFits), tostring(l and l.TextSize), tostring(l and l.TextScaled)))
	end
	table.sort(seen)
	assert(good, label .. ": " .. table.concat(seen, "; ") .. RED_I3)
	return table.concat(seen, "; ")
end
local function postersIn()
	local f = home:FindFirstChild("Items")
	local list = {}
	for _, m in ipairs(f and f:GetChildren() or {}) do if m:IsA("Model") and m:GetAttribute("ItemId") == "poster" then table.insert(list, m) end end
	return list
end

local function run()
	-- 1. Room_home, its anchors and its DecoratePrompt
	local slot
	assert(waitFor(function() slot = player:GetAttribute("PlotSlot"); return type(slot) == "number" and slot > 0 end, 3), "PlotSlot is " .. tostring(slot) .. " (t112a's tail leaves the player in home)")
	local plots = workspace:WaitForChild("OK_Plots", 5)
	assert(plots, "Workspace.OK_Plots is not on this client")
	local name = string.format("Plot_%02d", slot)
	local door, decor
	assert(waitFor(function()
		local pm = plots:FindFirstChild(name)
		home = pm and pm:FindFirstChild("Room_home")
		if not home then return false end
		for _, d in ipairs(home:GetDescendants()) do if d:IsA("BasePart") and d:GetAttribute("RoomDoor") == true then door = d; break end end
		decor = door and door:FindFirstChild("DecoratePrompt")
		return decor ~= nil
	end, 5), name .. ".Room_home (with its door's DecoratePrompt) is not on this client (t112a's tail buys home: did t112a fail?)")
	assert(home:GetAttribute("OwnerId") == player.UserId and decor.Enabled, "Room_home is not this player's, or its DecoratePrompt is off here")
	local n = Cfg.Kinds.home.posters
	for i = 1, n do assert(anchor(i), "Room_home has no Poster_" .. i .. " Attachment on this client") end
	assert(#serverHome().items == 0, "premise: t112a's tail should leave home empty, got " .. show(serverHome().items))
	table.insert(out, "1 " .. name .. ".Room_home on this client: " .. n .. " Poster anchors, the DecoratePrompt on")

	-- 2. in, by the prompt; the wall spots
	local entrance
	for _, d in ipairs(home:GetDescendants()) do if d:IsA("Attachment") and d.Name == "Entrance" then entrance = d; break end end
	assert(entrance, "Room_home has no Entrance attachment")
	local stand = entrance.WorldPosition + Vector3.new(0, 3, 0)
	local r = rootNow()
	r.CFrame = CFrame.lookAt(stand, Vector3.new(door.Position.X, stand.Y, door.Position.Z))
	task.wait(0.8)
	r = rootNow()
	local dist = (r.Position - door.Position).Magnitude
	assert(dist < decor.MaxActivationDistance, string.format("2: standing %.1f studs from the door, past the prompt's reach %.1f", dist, decor.MaxActivationDistance))
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.lookAt(r.Position + Vector3.new(0, 2, 0) - (door.Position - r.Position) * Vector3.new(1, 0, 1) * 0.4, door.Position)
	task.wait(0.4)
	local entered = false
	for _ = 1, 4 do
		decor:InputHoldBegin(); task.wait(0.05); decor:InputHoldEnd()
		if waitFor(function() return attr("Editing") == true end, 3) then entered = true; break end
	end
	assert(entered, "2: pressing home's DecoratePrompt did not put the client in decorate mode (Editing " .. tostring(attr("Editing")) .. ")")
	assert(attr("Kind") == "home", "2: decorating Kind " .. tostring(attr("Kind")) .. ", want home")
	assert(waitFor(topDown, 3), "2: the camera is " .. tostring(cam.CameraType) .. " looking along " .. str(cam.CFrame.LookVector) .. ", want Scriptable and straight down")
	assert(waitFor(function() return bar.Hint.Text == HINT_NONE end, 3), "2: with nothing picked the hint reads '" .. bar.Hint.Text .. "', want '" .. HINT_NONE .. "' (copy 6.13, 9.29)" .. RED)
	preview = home:FindFirstChild("OK_DecoratePreview")
	assert(waitFor(function() preview = home:FindFirstChild("OK_DecoratePreview"); return slotPart(n) ~= nil end, 3), "2: no OK_DecoratePreview.PosterSlots.Slot_1.." .. n .. " (the wall spots' hit parts, m21)" .. RED)
	-- both in the camera's viewport space (R-T13 review, M4): the bar's top is its AbsolutePosition (the gui's space, which has
	-- no top inset) plus the inset, as RoomUI.Reserved converts it; the plates' points come from WorldToViewportPoint. (tapAt
	-- keeps WorldToScreenPoint, which pairs with the tap seam's ScreenPointToRay)
	local barTop = bar.AbsolutePosition.Y + game:GetService("GuiService"):GetGuiInset().Y
	local V = cam.ViewportSize
	local floorY = home:GetPivot().Position.Y
	for i = 1, n do
		local s = slotPart(i)
		assert(s and s:IsA("BasePart"), "2: no Slot_" .. i)
		assert(s.CanQuery and not s.CanCollide and not s.CanTouch and s.Transparency >= 0.5, "2: Slot_" .. i .. " should be queryable, not colliding or touching, see-through")
		local d = flat(s.Position - anchor(i).WorldPosition)
		assert(d <= 3, string.format("2: Slot_%d is %.1f studs (flat) from Poster_%d, want 3 or less", i, d, i))
		local sp, onScreen = cam:WorldToViewportPoint(s.Position)
		assert(onScreen and sp.X >= 0 and sp.X <= V.X and sp.Y >= 0 and sp.Y <= barTop, string.format("2: Slot_%d shows at (%.0f, %.0f), want on the screen above the bar (top %.0f)", i, sp.X, sp.Y, barTop))
		-- lifted off the floor (R-T13 review, M2a): its underside clears the booth mat's top, y 0.05, so no face is coplanar with it
		local under = s.Position.Y - s.Size.Y / 2 - floorY
		assert(under >= 0.055, string.format("2: Slot_%d's underside is %.3f studs above the floor, want 0.055 or more (the booth mat's top is 0.05)", i, under) .. RED)
	end
	table.insert(out, "2 in by the prompt, straight down; hint 6.13 + 9.29; " .. n .. " wall spots' hit parts (see-through, queryable), each by its anchor and on screen")

	-- 3. a tap on a free wall spot opens the designer
	tapAt(slotPart(2), "3 tap Slot_2", function() return attr("Selected") == "slot:2" and attr("Poster") == "2,1,1,1" end)
	assert(waitFor(function() return bar.Mode.Text == "POSTER" and bar.Hint.Text == HINT_DESIGN end, 3), "3: the designer's head reads '" .. bar.Mode.Text .. "' / '" .. bar.Hint.Text .. "', want POSTER / " .. HINT_DESIGN)
	assert(caption("Word") == "WORD" and caption("Color") == "COLOR" and caption("Style") == "STYLE", "3: the rows' captions read " .. tostring(caption("Word")) .. ", "
		.. tostring(caption("Color")) .. ", " .. tostring(caption("Style")) .. "; want WORD, COLOR, STYLE (copy 9.25-9.27)")
	assert(value("Word") == Cfg.PosterWords[1] and value("Color") == Cfg.PosterColorNames[1] and value("Style") == Cfg.PosterStyleNames[1], "3: the rows read "
		.. tostring(value("Word")) .. ", " .. tostring(value("Color")) .. ", " .. tostring(value("Style")) .. "; want " .. Cfg.PosterWords[1] .. ", " .. Cfg.PosterColorNames[1] .. ", " .. Cfg.PosterStyleNames[1])
	for _, b in ipairs({ "WordPrev", "WordNext", "ColorPrev", "ColorNext", "StylePrev", "StyleNext", "Hang", "Cancel", "Done" }) do
		assert(visible(b), "3: the designer's " .. b .. " is not on show")
	end
	assert(bar.Hang.Text == "HANG" and bar.Cancel.Text == "✕ CANCEL" and bar.WordPrev.Text == "◀" and bar.WordNext.Text == "▶", "3: the designer's buttons read '"
		.. bar.Hang.Text .. "', '" .. bar.Cancel.Text .. "', '" .. bar.WordPrev.Text .. "', '" .. bar.WordNext.Text .. "'")
	assert(not visible("Remove") and not visible("Add") and not visible("Place") and not visible("Rotate"), "3: REMOVE, ADD, PLACE or ROTATE shows in the designer for a new poster")
	assert(waitFor(function() return facing(2) end, 3), "3: the camera looks along " .. str(cam.CFrame.LookVector) .. ", want facing the Poster_2 wall spot")
	assert(waitFor(function() return previewLabel() == Cfg.PosterWords[1] end, 3), "3: the preview (OK_DecoratePreview.PosterPreview) reads " .. tostring(previewLabel()) .. ", want " .. Cfg.PosterWords[1])
	local pm = previewModel()
	assert((pm:GetPivot().Position - anchor(2).WorldPosition).Magnitude < 0.1, "3: the preview hangs at " .. str(pm:GetPivot().Position) .. ", not on Poster_2 " .. str(anchor(2).WorldPosition))
	for _, d in ipairs(pm:GetDescendants()) do
		if d:IsA("BasePart") then assert(not d.CanQuery and not d.CanCollide and not d.CanTouch, "3: the preview's " .. d.Name .. " answers a ray, collides or touches") end
	end
	assert(#serverHome().items == 0, "3: the server's home changed while designing")
	table.insert(out, "3 a tap on Slot_2: the designer (POSTER, 9.30; WORD LOUD, COLOR RED, STYLE BOLD; HANG, CANCEL, DONE; no REMOVE), the camera on the wall spot, the preview on Poster_2")

	-- 4. no TextBox anywhere in the game's guis
	local tb = textBoxes()
	assert(#tb == 0, "4: TextBox in the client's PlayerGui: " .. table.concat(tb, ", ") .. " (no player-typed text)")
	table.insert(out, "4 no TextBox in this client's PlayerGui (the designer open)")

	-- 5. the design, with wrapping
	cmd("word:-1", function() return attr("Poster") == "2,12,1,1" and value("Word") == Cfg.PosterWords[12] and previewLabel() == Cfg.PosterWords[12] end, "5 word -1 (wraps)")
	cmd("word:+1", function() return attr("Poster") == "2,1,1,1" end, "5 word +1")
	cmd("word:+1", function() return attr("Poster") == "2,2,1,1" and previewLabel() == Cfg.PosterWords[2] end, "5 word +1 again")
	cmd("color:+1", function() return attr("Poster") == "2,2,2,1" end, "5 color +1")
	cmd("color:+1", function() return attr("Poster") == "2,2,3,1" and value("Color") == Cfg.PosterColorNames[3] end, "5 color +1 again")
	assert(waitFor(function() local m = previewModel(); local f = m and m:FindFirstChild("Face"); return f ~= nil and rgbIs(f.Color, Cfg.PosterColors[3]) end, 3), "5: the preview's Face is not PosterColors[3]")
	cmd("style:+1", function() local m = previewModel(); return attr("Poster") == "2,2,3,2" and value("Style") == Cfg.PosterStyleNames[2] and m ~= nil and m:FindFirstChild("Border", true) ~= nil end, "5 style +1 (FRAMED)")
	cmd("style:-1", function() return attr("Poster") == "2,2,3,1" end, "5 style -1")
	cmd("style:-1", function() local m = previewModel(); return attr("Poster") == "2,2,3,3" and value("Style") == Cfg.PosterStyleNames[3] and m ~= nil and m:FindFirstChild("Label_Top", true) ~= nil end, "5 style -1 (wraps to STACKED)")
	assert(#serverHome().items == 0, "5: the server's home changed while designing (the preview is client only)")
	table.insert(out, string.format("5 design: word wraps to %s and back to %s, color %s, style FRAMED then wraps to %s; the preview follows; the server untouched",
		Cfg.PosterWords[12], Cfg.PosterWords[2], Cfg.PosterColorNames[3], Cfg.PosterStyleNames[3]))

	-- 5b. R-T16 fix, I3: the words' size, the widest word in every style (the preview: the same RoomItems.Poster the wall gets)
	assert(Cfg.PosterWords[10] == "HUSTLE", "premise: PosterWords[10] is " .. tostring(Cfg.PosterWords[10]) .. ", the widest word HUSTLE expected there")
	cmd("word:+8", function() return attr("Poster") == "2,10,3,3" and previewLabel() == "HUSTLE" end, "5b word +8 (HUSTLE)")
	local sizes = {}
	for _, st in ipairs({ { nil, 3 }, { "style:+1", 1 }, { "style:+1", 2 }, { "style:+1", 3 } }) do
		if st[1] then cmd(st[1], function() return attr("Poster") == "2,10,3," .. st[2] end, "5b " .. st[1] .. " (" .. Cfg.PosterStyleNames[st[2]] .. ")") end
		local styleName = Cfg.PosterStyleNames[st[2]]
		assert(waitFor(function() local m = previewModel(); return m ~= nil and m:GetAttribute("PosterStyle") == st[2] end, 3), "5b: the preview is not in style " .. styleName)
		sizes[styleName] = textCheck(previewModel(), st[2], "5b the preview, HUSTLE in " .. styleName)
	end
	cmd("word:-8", function() return attr("Poster") == "2,2,3,3" and previewLabel() == Cfg.PosterWords[2] end, "5b word -8 (back to " .. Cfg.PosterWords[2] .. ")")
	table.insert(out, "5b the widest word in each style (the preview): BOLD [" .. sizes.BOLD .. "]; FRAMED [" .. sizes.FRAMED .. "]; STACKED [" .. sizes.STACKED .. "]")

	-- 6. phone first, a new poster
	local inset = cam.ViewportSize - gui.AbsoluteSize
	inset = Vector2.new(math.max(0, inset.X), math.max(0, inset.Y))
	local SCREENS = { Vector2.new(667, 375), Vector2.new(771, 390), Vector2.new(844, 390), Vector2.new(640, 360) }
	local function phones(label)
		local seen = {}
		for _, screen in ipairs(SCREENS) do
			local vp = screen - inset
			local where = label .. " " .. vp.X .. "x" .. vp.Y .. " (" .. screen.X .. "x" .. screen.Y .. " less " .. inset.X .. "x" .. inset.Y .. ")"
			gui:SetAttribute("ForceViewport", vp)
			local key = string.format("%dx%d", math.floor(vp.X + 0.5), math.floor(vp.Y + 0.5))
			assert(waitFor(function() return attr("Layout") == key end, 5), where .. ": the bar was not laid out for the forced size (Layout " .. tostring(attr("Layout")) .. ")")
			task.wait(0.1)
			local names, count = checkLayout(where, vp)
			assert(count >= 12, where .. ": only " .. count .. " designer controls on show (" .. names .. ")")
			table.insert(seen, string.format("%dx%d %s row(s), %d controls", vp.X, vp.Y, tostring(attr("Rows")), count))
		end
		gui:SetAttribute("ForceViewport", nil)
		return table.concat(seen, "; ")
	end
	table.insert(out, "6 phone first, a new poster: " .. phones("6"))

	-- 7. hang
	cmd("hang", function() return attr("LastEdit") == "ok" and attr("Selected") == "" and attr("Poster") == "" end, "7 hang", 8)
	local h7 = serverHome()
	assert(#h7.items == 1 and h7.used == 1, "7: Room_get's home reads " .. show(h7.items) .. " (used " .. tostring(h7.used) .. "), want one poster")
	local e7 = h7.items[1]
	assert(e7.id == "poster" and e7.slot == 2 and e7.w == 2 and e7.c == 3 and e7.s == 3, "7: the server's poster reads " .. show(e7) .. ", want slot 2, 2/3/3")
	assert(waitFor(function()
		local ps = postersIn()
		local l = ps[1] and ps[1]:FindFirstChild("Label", true)
		return #ps == 1 and l ~= nil and l.Text == Cfg.PosterWords[2] and (ps[1]:GetPivot().Position - anchor(2).WorldPosition).Magnitude < 0.05
	end, 4), "7: Room_home.Items on this client holds no poster reading " .. Cfg.PosterWords[2] .. " on Poster_2")
	assert(waitFor(function() return previewModel() == nil and topDown() end, 3), "7: after HANG the preview is still up or the camera isn't straight down")
	local hungSizes = textCheck(postersIn()[1], 3, "7 the hung poster (" .. Cfg.PosterWords[2] .. ", STACKED, built by the server)") -- R-T16 fix, I3
	table.insert(out, "7 hang: ok; Room_Get holds { poster, slot 2, 2/3/3 }; its model reads " .. Cfg.PosterWords[2] .. " on Poster_2 [" .. hungSizes .. "]; the camera straight down again")

	-- 8. a redesign of the hung poster
	local hung = postersIn()[1]
	local design = hung:FindFirstChildWhichIsA("SurfaceGui", true)
	assert(design, "8: the hung poster has no SurfaceGui")
	tapAt(slotPart(2), "8 tap the hung Slot_2", function() return attr("Selected") == "item:1" and attr("Poster") == "2,2,3,3" end)
	assert(visible("Remove") and visible("Hang"), "8: REMOVE or HANG is not on show for a hung poster")
	assert(waitFor(function() return design.Enabled == false and previewModel() ~= nil end, 3), "8: while it is redesigned the hung poster's own design still shows (or no preview)")
	table.insert(out, "8 phone first, a hung poster: " .. phones("8"))
	cmd("cancel", function() return attr("Selected") == "" end, "8 cancel")
	assert(waitFor(function() return design.Enabled == true end, 3), "8: CANCEL did not put the hung poster's design back on")
	cmd("slot:2", function() return attr("Selected") == "item:1" and attr("Poster") == "2,2,3,3" end, "8 slot:2 (the hung one)")
	cmd("color:+1", function() return attr("Poster") == "2,2,4,3" end, "8 color +1")
	cmd("hang", function() return attr("LastEdit") == "ok" and attr("Selected") == "" end, "8 hang the redesign", 8)
	local h8 = serverHome()
	local e8 = h8.items[1]
	assert(#h8.items == 1 and h8.used == 1 and e8.slot == 2 and e8.w == 2 and e8.c == 4 and e8.s == 3, "8: Room_Get's home reads " .. show(h8.items) .. ", want one poster, slot 2, 2/4/3 (replaced, not added)")
	table.insert(out, "8 redesign: a tap on the hung spot picks it (REMOVE shows, its own design off under the preview, back on after CANCEL); color +1, HANG -> one poster, 2/4/3")

	-- 9. remove
	cmd("slot:2", function() return attr("Selected") == "item:1" end, "9 slot:2")
	cmd("remove", function() return attr("LastEdit") == "ok" and attr("Selected") == "" end, "9 remove", 8)
	assert(#serverHome().items == 0, "9: Room_Get's home still holds " .. show(serverHome().items))
	assert(waitFor(function() return #postersIn() == 0 end, 4), "9: Room_home.Items still shows a poster on this client")
	table.insert(out, "9 remove: ok; Room_Get's home empty, no poster model")

	-- 10. cancel, then done
	cmd("slot:3", function() return attr("Selected") == "slot:3" and attr("Poster") == "3,1,1,1" end, "10 slot:3")
	cmd("cancel", function() return attr("Selected") == "" and attr("Poster") == "" end, "10 cancel")
	assert(attr("Editing") == true and waitFor(topDown, 3), "10: after CANCEL decorate mode ended or the camera isn't straight down")
	cmd("done", function() return attr("Editing") == false end, "10 done")
	assert(attr("LeftBy") == "done", "10: LeftBy reads " .. tostring(attr("LeftBy")) .. ", want done")
	assert(waitFor(function() return cam.CameraType == Enum.CameraType.Custom and attr("ControlsOn") == true end, 3), "10: after DONE the camera is " .. tostring(cam.CameraType) .. ", ControlsOn " .. tostring(attr("ControlsOn")))
	assert(home:FindFirstChild("OK_DecoratePreview") == nil, "10: OK_DecoratePreview is left after DONE")
	table.insert(out, "10 cancel closes the designer and decorating goes on; done -> the camera Custom, the controls back, no preview left")

	return "T112B PLAY OK\n" .. table.concat(out, "\n")
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
if not ok then error(msg, 0) end
return msg
