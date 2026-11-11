-- Server, during play: waiting lines (design 4.4) through the WalkIns Studio hook, paused throughout. While the client
-- reports the arrived card deferred (WalkIn_Deferred; here the hook's SetDeferred, the same path) the visitor's bubble
-- says a new W.WaitLines line every WaitLineSeconds, the first that long after the deferral began (Age moves those
-- clocks back, so nothing waits 45 s), cycling through the list; a foreign token is ignored; nothing comes in the first
-- seconds; once un-deferred the bubble stays as it is for 5 s and the card stays open.
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
local CARD = "navx_placement"
local LOUNGE = Vector3.new(24, 3, 0)
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
local function bubble() -- the text in the bubble of the player's visitor (nil while hidden or with no visitor)
	local f = workspace:FindFirstChild("OK_Visitors")
	for _, m in ipairs(f and f:GetChildren() or {}) do
		if m:GetAttribute("Target") == uid then
			local b = m:FindFirstChild("Bubble")
			return (b and b.Enabled) and b.Line.Text or nil
		end
	end
	return nil
end

local function run()
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	teleport(LOUNGE)
	assert(type(W.WaitLineSeconds) == "number" and W.WaitLineSeconds <= 46 and W.ExpireSeconds > 3 * 46,
		"Config.WalkIns.WaitLineSeconds " .. tostring(W.WaitLineSeconds) .. " / ExpireSeconds " .. tostring(W.ExpireSeconds) .. ": this file ages the card 46 s three times")
	local names = Content.Names(W.Roster)
	local waitLines, nLines = {}, 0
	for _, l in ipairs(Content.WaitLines) do waitLines[Rules.Fill(l, names, nil)] = true; nLines += 1 end
	assert(nLines >= 2, "W.WaitLines needs at least two lines for the cycling check")

	fresh("lines")
	assert(wi:Invoke("Spawn", uid, CARD) == true, "Spawn(" .. CARD .. ") refused")
	assert(waitFor(arrived, 15), "he did not arrive within 15 s")
	local token = pending().token
	local line0 = bubble()
	assert(type(line0) == "string" and not waitLines[line0], "the card's own line is missing, or is a waiting line: " .. tostring(line0))
	assert(wi:Invoke("Waiting") == 0, "a visit is waiting for a slot (the busy expiry would end the card)")
	-- a foreign token changes nothing
	assert(wi:Invoke("SetDeferred", uid, "not-" .. token, true) == false, "SetDeferred took a foreign token")
	-- deferred: nothing in the first seconds, then the first line once 46 s have passed (Age)
	assert(wi:Invoke("SetDeferred", uid, token, true) == true, "SetDeferred(true) refused")
	task.wait(1.5)
	assert(bubble() == line0, "a waiting line came within 1.5 s of the deferral: " .. tostring(bubble()))
	assert(wi:Invoke("Age", uid, 46) == true, "Age(46) refused")
	assert(waitFor(function() return waitLines[bubble() or ""] == true end, 2), "no waiting line within 2 s of Age(46); the bubble says " .. tostring(bubble()))
	local first = bubble()
	-- the next line after another 46 s: a different one (they cycle)
	assert(wi:Invoke("Age", uid, 46) == true, "second Age(46) refused")
	assert(waitFor(function() local b = bubble(); return b ~= first and waitLines[b or ""] == true end, 2),
		"no second waiting line within 2 s of the next Age(46); the bubble says " .. tostring(bubble()))
	local second = bubble()
	table.insert(out, string.format("deferred: nothing in 1.5 s; Age 46 -> %q; Age 46 -> %q", first, second))
	-- un-deferred: another 46 s change nothing for 5 s, and the card is still open (138 s < ExpireSeconds)
	assert(wi:Invoke("SetDeferred", uid, token, false) == true, "SetDeferred(false) refused")
	assert(wi:Invoke("Age", uid, 46) == true, "third Age(46) refused")
	task.wait(5)
	assert(bubble() == second, "un-deferred, the bubble changed within 5 s: " .. tostring(bubble()))
	local r = pending()
	assert(r and r.token == token, "the card closed")
	table.insert(out, "un-deferred: Age 46, the bubble unchanged for 5 s, the card still open")
	assert(wi:Invoke("Choose", uid, token, 0).ok == true, "walk away failed")
	return "T55 PLAY OK\n" .. table.concat(out, "\n")
end

local ok, msg = pcall(run)
pcall(function() wi:Invoke("Reset", uid); wi:Invoke("Pause", uid, true) end)
pcall(teleport, LOUNGE)
if not ok then error(msg, 0) end
return msg
