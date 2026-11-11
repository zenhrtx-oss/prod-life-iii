-- Server, during play: the pigeon (design 4.3) through the WalkIns Studio hook, paused throughout. From the control
-- room (in front of the studio PC, where t47b stands), Spawn weird_pigeon: its figure appears on the lounge coffee
-- table's top face (under OK_Visitors, at most 12 parts, no lights) and holds a walking slot; the card arrives within
-- 2 s with the pigeon as the sender and the fixed tag that names the lounge (no token in the tag or the line); a real
-- choice (not WALK AWAY) gets its result and the pigeon is gone within 5 s: the 2 s result delay, the 1 s flight and
-- slack. Not tightened by cutting the delay or the flight.
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
local LOUNGE = Vector3.new(24, 3, 0)
local CONTROL = Vector3.new(72, 3.5, -5.5) -- in front of the studio PC (build/04_control_booth.lua's desk; t47b stands here)
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
local function pending() return wi:Invoke("Pending", uid) end
local function arrived() local r = pending(); return r ~= nil and r.arrived == true end
local function advanceTour() for _, s in ipairs(Tour.Steps) do test:Invoke("TourAdvance", uid, s.id) end end
local function fresh(label)
	assert(wi:Invoke("Reset", uid) == true, label .. ": Reset failed")
	advanceTour()
end
local function pigeon() -- the player's pigeon model under OK_Visitors
	local f = workspace:FindFirstChild("OK_Visitors")
	for _, m in ipairs(f and f:GetChildren() or {}) do
		if m:GetAttribute("Target") == uid and m:GetAttribute("VisitorId") == "pigeon" then return m end
	end
	return nil
end

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh("pigeon")
	local card = Content.CardById.weird_pigeon
	local v = card and Content.VisitorById[card.visitor]
	assert(card and v and v.kind == "critter", "weird_pigeon is not a card from a critter")
	assert(string.find(card.tag, "LOUNGE", 1, true) ~= nil, "the pigeon card's tag does not name the lounge: " .. tostring(card.tag))
	assert(not string.find(card.tag, "{", 1, true) and not string.find(card.line, "{", 1, true), "the pigeon card's tag or line holds a token")
	local names = Content.Names(W.Roster)
	local top = workspace.OKStudio.Lounge.Coffee_Top
	local topY = top.Position.Y + top.Size.Y / 2
	assert(math.abs(topY - 1.5) < 0.05, "Coffee_Top's top face is at y " .. topY .. " (want 1.5)")
	local r0 = teleport(CONTROL)
	assert(Rules.RoomOf(r0.Position.X) == "Control" and Rules.InHub(r0.Position.X, r0.Position.Y, r0.Position.Z), "not standing in the control room")
	wi:Invoke("Sent", uid) -- read and clear
	local walking0 = wi:Invoke("Walking")

	-- spawn: the figure on the table, the card from the pigeon
	local t0 = os.clock()
	assert(wi:Invoke("Spawn", uid, "weird_pigeon") == true, "Spawn(weird_pigeon) refused")
	assert(waitFor(arrived, 2), "the pigeon card did not arrive within 2 s")
	local took = os.clock() - t0
	local r = pending()
	local m = pigeon()
	assert(m and m.Archivable == false, "no pigeon model under OK_Visitors")
	assert(m:GetAttribute("Visitor") == names.pigeon, "the pigeon model is named " .. tostring(m:GetAttribute("Visitor")) .. " (want " .. tostring(names.pigeon) .. ")")
	local n, lo = 0, math.huge
	for _, d in ipairs(m:GetDescendants()) do
		assert(not d:IsA("Light"), "the pigeon has a Light: " .. d.Name)
		if d:IsA("BasePart") then
			n += 1
			lo = math.min(lo, d.Position.Y - d.Size.Y / 2)
			assert(d.Anchored and not d.CanCollide and not d.CanQuery, "pigeon part " .. d.Name .. " is not anchored/non-colliding/non-query")
		end
	end
	assert(n >= 1 and n <= 12, "the pigeon has " .. n .. " parts (want 1..12)")
	local at = m:GetPivot().Position
	assert(math.abs(at.X - top.Position.X) <= top.Size.X / 2 and math.abs(at.Z - top.Position.Z) <= top.Size.Z / 2,
		string.format("the pigeon is at (%.1f, %.1f), off the coffee table (x %.1f +- %.1f, z %.1f +- %.1f)", at.X, at.Z, top.Position.X, top.Size.X / 2, top.Position.Z, top.Size.Z / 2))
	assert(math.abs(lo - topY) <= 0.3, string.format("the pigeon's feet are at y %.2f, the table top at %.2f", lo, topY))
	assert(wi:Invoke("Walking") == walking0 + 1, "the pigeon does not hold a walking slot (Walking " .. tostring(wi:Invoke("Walking")) .. ", was " .. walking0 .. ")")
	local arrive
	for _, s in ipairs(wi:Invoke("Sent", uid)) do if s.kind == "arrive" and s.payload.token == r.token then arrive = s.payload end end
	assert(arrive and arrive.card.id == "weird_pigeon", "no arrive was sent for the pigeon card")
	assert(arrive.card.visitor.name == names.pigeon and arrive.card.tag == card.tag and arrive.card.line == card.line,
		string.format("the card shows %s / %s / %s", tostring(arrive.card.visitor.name), tostring(arrive.card.tag), tostring(arrive.card.line)))
	assert(Rules.RoomOf(root().Position.X) == "Control", "the player is no longer in the control room")
	assert(m.Bubble.Enabled and m.Bubble.Line.Text == card.line, "the pigeon's bubble does not say its line: " .. tostring(m.Bubble.Line.Text))
	table.insert(out, string.format("from the control room: pigeon on the table at (%.1f, %.1f, %.1f), %d parts, no lights, a walking slot held; card in %.1f s from %s, tag %q",
		at.X, at.Y, at.Z, n, took, arrive.card.visitor.name, card.tag))

	-- a real choice: its result, then the pigeon flies off (2 s result delay + 1 s flight)
	local idx
	for i, c in ipairs(card.choices) do if c.sure then idx = i; break end end
	assert(idx, "weird_pigeon has no sure choice")
	local t1 = os.clock()
	local res = wi:Invoke("Choose", uid, r.token, idx)
	assert(res and res.ok == true and res.result and res.result.key == card.choices[idx].good.key,
		"choice " .. idx .. " refused: " .. tostring(res and (res.reason or (res.result and res.result.key))))
	assert(waitFor(function() return m.Parent == nil end, 5), "the pigeon is still there 5 s after the choice")
	local goneAfter = os.clock() - t1
	assert(goneAfter >= 2.8, string.format("the pigeon was gone %.1f s after the choice (want the 2 s result delay plus the 1 s flight)", goneAfter))
	assert(waitFor(function() return wi:Invoke("Walking") == walking0 end, 1), "the walking slot was not given back")
	assert(pending() == nil and not pigeon(), "the visit is still pending, or a pigeon is left")
	table.insert(out, string.format("choice %d -> %s; the pigeon gone %.1f s later, the slot given back", idx, res.result.key, goneAfter))
	return "T56 PLAY OK\n" .. table.concat(out, "\n")
end

local ok, msg = pcall(run)
pcall(function() wi:Invoke("Reset", uid); wi:Invoke("Pause", uid, true) end)
pcall(teleport, LOUNGE)
if not ok then error(msg, 0) end
return msg
