-- Server, during play (Wave 3 Task 2 fix round 1; design 4.5), after t76b and before t76d: a walk-in card without a hint
-- whose result carries one. The file's own fresh() (unseated in the lounge, Quiet on, WalkIns Reset, Career Reset, Life
-- Reset, ResetHints), held. Then ResetHints with placement (so navx_placement's only term is seen), Followers set to 1,200
-- by a silent Set (the CLOUT's +1,500 crosses no tier) and the walk-in rng forced to 1 (the client's choice 3 rolls
-- good: CLOUT, whose text says "followers"), then navx_placement spawned: its arrive payload carries no hint (WalkInRules
-- HintFor on its own texts with placement seen gives none). The card is left open for t76d, which picks choice 3 itself.
-- On any error everything is reset (hold true, Quiet off) and the error rethrown.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local Config = require(RS.OK.Config)
local Rules = require(RS.OK.Modules.WalkInRules)
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
local function pending() return wi:Invoke("Pending", uid) end
local function arrived() local r = pending(); return r ~= nil and r.arrived == true end
local function add(list, s) if type(s) == "string" and s ~= "" then table.insert(list, s) end end
local function fresh(label)
	local c = p.Character; local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum and hum.Sit then hum.Sit = false; task.wait(0.4) end
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, label .. ": Quiet(true) failed")
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	assert(life:Invoke("Reset", uid) == true, label .. ": Life Reset failed")
	assert(test:Invoke("ResetHints", uid) == true, label .. ": ResetHints did not return true (before the Task 2 sync of OK/Main: nil)")
end

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh("result hint")
	assert(test:Invoke("ResetHints", uid, { "placement" }) == true, "ResetHints with placement failed")
	local seen = test:Invoke("Hints", uid)
	assert(type(seen) == "table" and seen.placement == 0 and seen.followers == nil, "Hints should hold placement (day 0) only")
	assert(career:Invoke("Set", uid, { followers = 1200 }) == true, "Career Set followers failed")
	assert(wi:Invoke("SetRng", uid, { 1 }) == true, "SetRng failed") -- the client's choice 3 rolls good
	wi:Invoke("Sent", uid)
	assert(wi:Invoke("Spawn", uid, CARD) == true, "Spawn(" .. CARD .. ") refused")
	assert(waitFor(arrived, 15), "he did not arrive within 15 s")
	local a
	for _, e in ipairs(wi:Invoke("Sent", uid)) do if e.kind == "arrive" then a = e.payload end end
	assert(type(a) == "table" and type(a.card) == "table" and a.card.id == CARD, "no arrive payload for " .. CARD)
	local texts = {}
	add(texts, a.card.tag); add(texts, a.card.line)
	for _, c in ipairs(a.card.choices or {}) do add(texts, c.text) end
	assert(Rules.HintFor(texts, seen, Config.Hints) == nil, CARD .. "'s texts carry an unseen term with placement seen: pick another card")
	assert(a.card.hint == nil, CARD .. " carries a hint with placement seen")
	assert(ph:Invoke("Quiet", uid, false) == true, "Quiet(false) failed")
	return string.format("T76C PLAY OK: %s open without a hint (placement seen), choice 3's roll forced good for t76d; elapsed %.1f s", CARD, os.clock() - T0)
end

local ok, msg = pcall(run)
if not ok then
	pcall(function() wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); test:Invoke("ResetHints", uid); ph:Invoke("Quiet", uid, false) end)
	pcall(teleport, LOUNGE)
	error(msg, 0)
end
return msg
