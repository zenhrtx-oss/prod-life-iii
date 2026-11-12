-- Server, during play (Wave 3 Task 5d), before t90b: stages the walk-in card for the portrait check. The file's own
-- fresh() (unseated in the lounge, Quiet on, the phone's pops dropped, WalkIns, Career and Life reset, ResetHints,
-- SetRecent({}): no recent beat), the scheduler held; then LIL NAV X's navx_placement is spawned, arrives and is left open
-- for t90b. Its "arrive" payload must carry his id and sig (visitor.id = "navx", visitor.sig his data sig: the card builds
-- his portrait from them, as his walker is built). That
-- check runs after the staging and leaves the card open when it fails, so t90b's red stays its own; an error before
-- the staging is done resets everything (Quiet stays on) and is rethrown.
local Players, SSS = game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local Content = require(game:GetService("ReplicatedStorage").OK.Data.WalkIns)
local LOUNGE = Vector3.new(24, 3, 0)
local CARD = "navx_placement"
local T0 = os.clock()

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
local function arrived() local r = wi:Invoke("Pending", uid); return r ~= nil and r.arrived == true end
-- the file's own fresh(): unseated and in the lounge, Quiet on, no pops, WalkIns, Career and Life reset, hints and recent beats cleared
local function fresh(label)
	local c = p.Character; local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum and hum.Sit then hum.Sit = false; task.wait(0.4) end
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, label .. ": Quiet(true) failed")
	assert(ph:Invoke("Reset", uid) == true, label .. ": phone Reset failed")
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	assert(life:Invoke("Reset", uid) == true, label .. ": Life Reset failed")
	assert(test:Invoke("ResetHints", uid) == true, label .. ": ResetHints failed")
	assert(type(test:Invoke("SetRecent", uid, {})) == "table", label .. ": SetRecent({}) failed")
end

local function stage()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh("stage")
	wi:Invoke("Sent", uid) -- read and clear
	assert(wi:Invoke("Spawn", uid, CARD) == true, "Spawn(" .. CARD .. ") refused")
	assert(waitFor(arrived, 15), CARD .. ": he did not arrive within 15 s")
	local arrive
	for _, e in ipairs(wi:Invoke("Sent", uid)) do if e.kind == "arrive" then arrive = e.payload end end
	assert(type(arrive) == "table" and type(arrive.card) == "table" and arrive.card.id == CARD, "no arrive payload for " .. CARD)
	return arrive
end

local ok, arrive = pcall(stage)
if not ok then
	pcall(function()
		wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
		test:Invoke("ResetHints", uid); test:Invoke("SetRecent", uid, {})
	end)
	pcall(teleport, LOUNGE)
	error(arrive, 0)
end
-- after the staging (the card stays open for t90b either way): the card names the visitor it shows
local v = arrive.card.visitor
assert(type(v) == "table" and v.id == "navx", "the arrive payload's visitor carries id " .. tostring(type(v) == "table" and v.id or nil)
	.. ", want navx: the card can't build his portrait without it (card staged for t90b)")
assert(v.sig == Content.VisitorById.navx.sig, "the arrive payload's visitor carries sig " .. tostring(v.sig) .. ", want " .. Content.VisitorById.navx.sig
	.. ": a card for an id with no recipe would not match its walker (card staged for t90b)")
return string.format("T90A PLAY OK: %s arrived and open for t90b; its payload's visitor { id = %s, sig = %s, name = %s }; elapsed %.1f s", CARD, v.id, v.sig, tostring(v.name), os.clock() - T0)
