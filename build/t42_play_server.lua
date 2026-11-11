-- Server, during play: the walk-in visitor NPC (Modules/Visitor) on its own, without the WalkIns scheduler.
-- Every signature stays a safe figure of at most 16 parts under Workspace.OK_Visitors; a visitor walks from the corridor
-- mouth to the player in the lounge, faces them and arrives once; talks in his bubble; walks out and is destroyed with
-- onGone once. A target who leaves the hub sends him away unarrived; Destroy twice is harmless; with no waypoints for
-- the room he still walks straight in; the walk timeout snaps him in; a target who moves gets re-aimed at; a def
-- without its id or display name is refused before anything is built. The spot figure (SpawnSpot, the pigeon) sits on
-- the lounge coffee table with at most 12 parts and no lights, arrives on the next Heartbeat, flies off on Leave.
local RS, Players = game:GetService("ReplicatedStorage"), game:GetService("Players")
local Visitor = require(RS.OK.Modules.Visitor)
-- Config.WalkIns lands with Task 3; until then this literal copy of the plan's Task 3 values stands in
local W = require(RS.OK.Config).WalkIns or {
	ArriveDistance = 4, WalkSpeed = 8, WalkTimeout = 40, Spawn = { 1.5, 5 },
	Waypoints = {
		Corridor = { { 1.5, 5 }, { 9, 5 } },
		Lounge = { { 1.5, 5 }, { 9, 5 }, { 16, 5 } },
		Control = { { 1.5, 5 }, { 9, 5 }, { 16, 5 }, { 40, 0 }, { 47, 0 } },
		Booth = { { 1.5, 5 }, { 9, 5 }, { 16, 5 }, { 40, 0 }, { 47, 0 }, { 77, 6 }, { 83, 6 } },
	},
}
local SIGS = { "cowboy_hat", "bat_ears", "spiky_hair", "blob_hat", "helmet", "llama_ears", "sparkle_cape", "owl_hood",
	"green_roots", "suit", "cap", "headphones", "apron", "headset", "lanyard", "none" }
local LOUNGE = Vector3.new(24, 3, 0)
local p = Players:GetPlayers()[1]
local handles = {}

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
local function with(over) -- a copy of W with some values replaced
	local w = table.clone(W)
	for k, v in pairs(over) do w[k] = v end
	return w
end
local function spawn(sig, walkins)
	local log = { arrive = 0, gone = 0 }
	local def = { id = "t42_" .. sig, name = "T42 " .. string.upper(sig), style = "test visitor", color = { 255, 60, 160 }, sig = sig }
	local h = Visitor.Spawn(def, p, { walkins = walkins or W,
		onArrive = function() log.arrive += 1 end, onGone = function() log.gone += 1 end })
	table.insert(handles, h)
	return h, log, def
end
local function gap(h) local r = root(); return r and flat(h.Model:GetPivot().Position - r.Position) or math.huge end
local function facing(h) -- the visitor's look direction against the direction to the player, flattened (1 = straight at)
	local cf, r = h.Model:GetPivot(), root()
	local to = r.Position - cf.Position
	local look = cf.LookVector
	return (look.X * to.X + look.Z * to.Z) / (flat(look) * flat(to))
end
local function gone(h) return h.Model.Parent == nil end

local function run()
	teleport(LOUNGE)
	-- 1. every signature: a safe, small figure with a name plate and a hidden bubble, filed under OK_Visitors
	local most = 0
	for _, sig in ipairs(SIGS) do
		local h, log, def = spawn(sig)
		local m = h.Model
		local folder = workspace:FindFirstChild("OK_Visitors")
		assert(folder and folder:IsA("Folder") and m.Parent == folder, sig .. ": not under Workspace.OK_Visitors")
		assert(m.Archivable == false, sig .. ": model is archivable")
		assert(m:GetAttribute("Visitor") == def.name and m:GetAttribute("VisitorId") == def.id, sig .. ": Visitor/VisitorId attributes wrong")
		assert(m:GetAttribute("Target") == p.UserId, sig .. ": Target attribute is not the player's UserId")
		local n = 0
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") then
				n += 1
				assert(d.Anchored and not d.CanCollide and not d.CanQuery and not d.CastShadow, sig .. ": part " .. d.Name .. " is not anchored/non-colliding/non-query/shadowless")
			end
		end
		assert(n >= 8 and n <= 16, sig .. ": " .. n .. " parts (want 8..16)")
		most = math.max(most, n)
		for _, name in ipairs({ "NamePlate", "Bubble" }) do
			local bb = m:FindFirstChild(name)
			assert(bb and bb:IsA("BillboardGui") and bb.MaxDistance == 80 and bb.LightInfluence == 0 and bb.Adornee, sig .. ": " .. name .. " billboard wrong")
		end
		assert(m.NamePlate.Plate.NameText.Text == def.name, sig .. ": name plate does not show the name")
		assert(m.Bubble.Enabled == false, sig .. ": bubble shows before he says anything")
		h:Destroy()
		assert(gone(h) and log.gone == 1 and log.arrive == 0, sig .. ": Destroy did not remove him with onGone once")
	end
	-- 2. arrive: walks from the corridor mouth to the player in the lounge, stops close, faces them, onArrive once
	local h, log = spawn("cowboy_hat")
	assert(not h.Arrived, "arrived at the spawn")
	assert(waitFor(function() return h.Arrived end, 15), "did not arrive within 15 s")
	assert(log.arrive == 1, "onArrive called " .. log.arrive .. " times")
	assert(gap(h) <= 5, string.format("arrived %.1f studs from the player (want <= 5)", gap(h)))
	assert(facing(h) > 0.9, string.format("not facing the player (%.2f)", facing(h)))
	-- 3. say: the bubble shows the line
	h:Say("yo")
	assert(h.Model.Bubble.Enabled and h.Model.Bubble.Line.Text == "yo", "bubble does not say yo")
	-- 4. leave: walks out and is destroyed, onGone once
	h:Leave()
	assert(waitFor(function() return gone(h) end, 20), "still here 20 s after Leave")
	task.wait(0.3)
	assert(log.gone == 1 and log.arrive == 1, "onGone " .. log.gone .. " / onArrive " .. log.arrive .. " after leaving")
	-- 5. the target leaves the hub (Studio Two passage) before he arrives: he walks out unarrived
	h, log = spawn("bat_ears")
	task.wait(0.5)
	teleport(Vector3.new(11.2, 3, 60))
	teleport(LOUNGE)
	assert(waitFor(function() return gone(h) end, 20), "still here 20 s after the target left the hub")
	assert(not h.Arrived and log.arrive == 0 and log.gone == 1, "left the hub: arrived " .. tostring(h.Arrived) .. ", onArrive " .. log.arrive .. ", onGone " .. log.gone)
	-- 6. Destroy twice (and Leave/Say after it): no error, onGone once
	h, log = spawn("spiky_hair")
	local first, second = pcall(h.Destroy, h), pcall(h.Destroy, h)
	assert(first and second and pcall(h.Leave, h) and pcall(h.Say, h, "late"), "Destroy twice, or Leave/Say after it, errored")
	task.wait(0.3)
	assert(gone(h) and log.gone == 1, "double Destroy: onGone " .. log.gone)
	-- 7. no waypoints for the target's room (Route returns {}): he walks straight from the spawn and arrives
	h, log = spawn("helmet", with({ Waypoints = {} }))
	assert(waitFor(function() return h.Arrived end, 15), "empty route: did not arrive within 15 s")
	assert(gap(h) <= 5, string.format("empty route: arrived %.1f studs away", gap(h)))
	h:Destroy()
	-- 8. walk timeout: too slow to get there, he snaps to the arrival point after WalkTimeout
	h, log = spawn("cap", with({ WalkSpeed = 0.5, WalkTimeout = 2 }))
	task.wait(1)
	assert(not h.Arrived, "timeout case arrived before the timeout")
	assert(waitFor(function() return h.Arrived end, 5), "did not snap in after WalkTimeout")
	assert(log.arrive == 1 and gap(h) <= 5, string.format("timeout snap: onArrive %d, %.1f studs away", log.arrive, gap(h)))
	h:Destroy()
	-- 9. re-aim: the player moves while he walks; he arrives at the new spot
	h, log = spawn("headphones")
	task.wait(0.8)
	assert(not h.Arrived, "re-aim case arrived too early")
	teleport(Vector3.new(28, 3, -4))
	assert(waitFor(function() return h.Arrived end, 15), "re-aim: did not arrive within 15 s")
	assert(gap(h) <= 5, string.format("re-aim: arrived %.1f studs from the moved player", gap(h)))
	h:Destroy()
	-- 10. a def without its id or display name is refused up front (VisitorId/Visitor would silently drop), and builds nothing
	local before = #workspace.OK_Visitors:GetChildren()
	for label, bad in pairs({
		["no id"] = { name = "T42 NO ID", style = "test visitor", color = { 255, 60, 160 }, sig = "none" },
		["no name"] = { id = "t42_noname", style = "test visitor", color = { 255, 60, 160 }, sig = "none" },
		["numeric id"] = { id = 42, name = "T42 NUM", style = "test visitor", color = { 255, 60, 160 }, sig = "none" },
		["no def"] = false,
	}) do
		local ok, res = pcall(Visitor.Spawn, bad or nil, p, { walkins = W })
		if ok then table.insert(handles, res) end
		assert(not ok and string.find(tostring(res), "def.id and def.name", 1, true), "bad def (" .. label .. ") was not refused: " .. tostring(res))
	end
	assert(#workspace.OK_Visitors:GetChildren() == before, "a refused def still built a visitor")
	-- 11. the spot figure (the pigeon): at most 12 parts and no lights on the lounge coffee table's top face, arrived on
	-- the next Heartbeat (never inside the call) with onArrive once; a second one sits 1.5 studs along the table; Say
	-- works; Leave is a 1 s flight up, then gone with onGone once; a spot freed by one that left is taken again while
	-- another still stands (the slots are a set, not a count: the next one lands on the first's spot, 1.5 studs from
	-- the second, never inside it); a target who leaves the hub sends it off
	local top = workspace.OKStudio.Lounge.Coffee_Top
	local topY = top.Position.Y + top.Size.Y / 2
	local function onTable(h) -- the pivot within the table's x/z footprint, the lowest part on its top face
		local at = h.Model:GetPivot().Position
		local lo = math.huge
		for _, d in ipairs(h.Model:GetDescendants()) do
			if d:IsA("BasePart") then lo = math.min(lo, d.Position.Y - d.Size.Y / 2) end
		end
		local on = math.abs(at.X - top.Position.X) <= top.Size.X / 2 and math.abs(at.Z - top.Position.Z) <= top.Size.Z / 2 and math.abs(lo - topY) <= 0.3
		return on, at, lo
	end
	local sdef = { id = "t42_spot", name = "T42 SPOT", style = "test critter", color = { 130, 135, 145 }, sig = "none" }
	local function spot()
		local slog = { arrive = 0, gone = 0 }
		local s = Visitor.SpawnSpot(sdef, p, { walkins = W, onArrive = function() slog.arrive += 1 end, onGone = function() slog.gone += 1 end })
		table.insert(handles, s)
		return s, slog
	end
	local s, slog = spot()
	assert(not s.Arrived and slog.arrive == 0, "spot: arrived inside SpawnSpot")
	assert(s.Model.Parent == workspace.OK_Visitors and s.Model.Archivable == false and s.Model:GetAttribute("Target") == p.UserId, "spot: not under OK_Visitors, archivable, or Target wrong")
	local sn = 0
	for _, d in ipairs(s.Model:GetDescendants()) do
		assert(not d:IsA("Light"), "spot: a Light instance " .. d.Name)
		if d:IsA("BasePart") then
			sn += 1
			assert(d.Anchored and not d.CanCollide and not d.CanQuery and not d.CastShadow, "spot: part " .. d.Name .. " is not anchored/non-colliding/non-query/shadowless")
		end
	end
	assert(sn >= 1 and sn <= 12, "spot: " .. sn .. " parts (want 1..12)")
	assert(waitFor(function() return s.Arrived end, 1), "spot: not arrived within 1 s")
	task.wait(0.1)
	assert(slog.arrive == 1, "spot: onArrive called " .. slog.arrive .. " times")
	local on, at, lo = onTable(s)
	assert(on, string.format("spot: not on the coffee table (pivot %.1f, %.1f, %.1f; lowest part %.2f, top face %.2f)", at.X, at.Y, at.Z, lo, topY))
	assert(s.Model.NamePlate.Plate.NameText.Text == sdef.name and s.Model.Bubble.Enabled == false, "spot: name plate / hidden bubble wrong")
	s:Say("coo.")
	assert(s.Model.Bubble.Enabled and s.Model.Bubble.Line.Text == "coo.", "spot: bubble does not say coo.")
	local s2 = spot()
	assert(waitFor(function() return s2.Arrived end, 1), "spot: the second one did not arrive within 1 s")
	local on2, at2 = onTable(s2)
	local apart = flat(at2 - at)
	assert(on2 and math.abs(apart - 1.5) <= 0.1, string.format("spot: the second one is %.2f studs from the first (want 1.5), on the table: %s", apart, tostring(on2)))
	local t0 = os.clock()
	s:Leave() -- the first leaves while the second still stands: its spot is free, the second's is not
	task.wait(0.5)
	assert(not gone(s) and s.Model:GetPivot().Position.Y > at.Y + 1, "spot: not flying up 0.5 s after Leave")
	assert(waitFor(function() return gone(s) end, 2), "spot: still here 2 s after Leave")
	local flew = os.clock() - t0
	task.wait(0.3)
	assert(slog.gone == 1 and slog.arrive == 1 and flew >= 0.9, string.format("spot: after Leave onGone %d, onArrive %d, gone after %.1f s (want a 1 s flight)", slog.gone, slog.arrive, flew))
	-- the third takes the freed spot (the first's), 1.5 studs from the second that still stands, never inside it (a
	-- live count instead of a slot set would put it on the second's spot)
	local s3, slog3 = spot()
	assert(waitFor(function() return s3.Arrived end, 1), "spot: the third one did not arrive within 1 s")
	assert(not gone(s2), "spot: the second one went before the third spawned")
	local on3, at3 = onTable(s3)
	local apart3, fromFirst = flat(at3 - at2), flat(at3 - at)
	assert(on3 and apart3 > 0.1 and math.abs(apart3 - 1.5) <= 0.1 and fromFirst <= 0.2,
		string.format("spot: the third one is %.2f studs from the second still standing and %.2f from the first's freed spot (want 1.5 and 0: the freed slot is taken again), on the table: %s", apart3, fromFirst, tostring(on3)))
	s2:Destroy()
	teleport(Vector3.new(11.2, 3, 60))
	teleport(LOUNGE)
	assert(waitFor(function() return gone(s3) end, 3), "spot: still here 3 s after the target left the hub")
	assert(pcall(s3.Destroy, s3) and pcall(s3.Say, s3, "late") and slog3.gone == 1, "spot: Destroy/Say after it is gone errored, or onGone " .. slog3.gone)
	-- nothing of ours is left behind
	for _, m in ipairs(workspace.OK_Visitors:GetChildren()) do
		assert(m:GetAttribute("Target") ~= p.UserId, "orphan visitor left under OK_Visitors: " .. m.Name)
	end
	return string.format("T42 PLAY OK: %d sigs <= %d parts, all anchored/non-colliding; arrived, said yo, left; left-hub, double Destroy, empty route, timeout snap, re-aim, bad def refused; spot figure on the coffee table (%d parts, no lights), 1.5 studs apart, flew off, freed spot taken again", #SIGS, most, sn)
end

local ok, msg = pcall(run)
for _, h in ipairs(handles) do pcall(h.Destroy, h) end
pcall(teleport, LOUNGE)
if not ok then error(msg, 0) end
return msg
