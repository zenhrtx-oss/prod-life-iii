-- Client, during play (Wave 3 Task 5c-2; launch audit A2/A4), after t83a: the cypher idle with no lobby cooldown, Quiet on.
-- (1) Cypher_Join (the bar's JOIN, a remote any client can call) from idle is refused "busy" and opens nothing.
-- (2) The lounge cypher board's prompt opens a lobby with you in it (its toast says so).
-- (3) In that lobby Cypher_Join answers "joined": the remote still joins a round under way.
-- (4) Alone, the lobby is cancelled for too few entrants when it closes (Config.Cypher.LobbySeconds), then idles after
--     its 4 s reveal.
-- (5) Right after, inside Config.Cypher.CancelCooldown, the board opens nothing (its toast: "A cypher is under way · join
--     the next one") and neither does Cypher_Join ("busy").
-- t83c checks the cooldown on the server and lifts it. Everything this file changed is set back (the camera, the toast
-- listener).
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local t0 = os.clock(); while os.clock() - t0 < 12 do local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then break end; task.wait(0.2) end
local char = player.Character; local root = char:WaitForChild("HumanoidRootPart"); local hum = char:WaitForChild("Humanoid"); local cam = workspace.CurrentCamera
local R = RS.OK.Remotes
local CY = RS.OK:WaitForChild("Cypher", 5); assert(CY, "no RS.OK.Cypher")
local Config = require(RS.OK.Config)
local pg = player:WaitForChild("PlayerGui", 10)
local daw = pg:WaitForChild("OK_DAW", 10):WaitForChild("DAW", 10); assert(daw, "no beat maker gui")
local board = workspace.OKStudio.Lounge:WaitForChild("CypherBoard", 5); assert(board, "no CypherBoard in the lounge")
local sign = board:WaitForChild("Sign", 5)
local prompt = sign and sign:FindFirstChildWhichIsA("ProximityPrompt", true); assert(prompt, "no prompt on the cypher board")
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local toasts = {}
local conn = R.InteractionEvent.OnClientEvent:Connect(function(kind, payload)
	if kind == "Toast" and type(payload) == "table" then table.insert(toasts, tostring(payload.text)) end
end)
local function toastWith(text, from)
	for i = from or 1, #toasts do if string.find(toasts[i], text, 1, true) then return toasts[i] end end
	return nil
end
local function since(n) local o = {}; for i = n + 1, #toasts do table.insert(o, toasts[i]) end; return "'" .. table.concat(o, "' | '") .. "'" end
-- the file's own fresh(): the beat maker closed (it turns the prompts off), standing, the camera free
if daw.Visible then daw:SetAttribute("Command", "close"); task.wait(0.4) end
if hum.Sit then hum.Sit = false; task.wait(0.4) end
cam.CameraType = Enum.CameraType.Custom
local out = {}

-- presses the board's prompt (standing 2.6 studs in front of it, the camera on it) until `done` holds, at most 4 times;
-- the board's per-player cooldown is 1 s, so each try waits 1.2 s
local function press(done)
	local pos = Vector3.new(18.0, 3.5, -4.0)
	root.CFrame = CFrame.lookAt(pos, Vector3.new(15.4, 3.5, -4.0)); task.wait(0.8)
	cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = CFrame.lookAt(pos + Vector3.new(3, 2.5, 0), sign.Position); task.wait(0.5)
	for _ = 1, 4 do
		prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd()
		if waitFor(done, 1.2) then return true end
	end
	return false
end

local function run()
	assert(CY:GetAttribute("Phase") == "idle" and player:GetAttribute("CypherIn") == nil, "t83a's fresh is missing: Phase "
		.. tostring(CY:GetAttribute("Phase")) .. ", CypherIn " .. tostring(player:GetAttribute("CypherIn")))

	-- 1. the remote opens nothing
	local r1 = R.Cypher_Join:InvokeServer()
	task.wait(0.3)
	assert(type(r1) == "table" and r1.ok == false and r1.reason == "busy" and CY:GetAttribute("Phase") == "idle", "Cypher_Join from idle answered ok "
		.. tostring(type(r1) == "table" and r1.ok) .. ", reason " .. tostring(type(r1) == "table" and r1.reason) .. ", and the cypher is at "
		.. tostring(CY:GetAttribute("Phase")) .. ": only the board may open a lobby")
	table.insert(out, "1 Cypher_Join from idle: busy, the cypher still idle")

	-- 2. the board opens a lobby, with you in it
	local round0, n0 = CY:GetAttribute("Round") or 0, #toasts
	assert(press(function() return CY:GetAttribute("Phase") == "lobby" end), "the board's prompt opened no lobby (Phase " .. tostring(CY:GetAttribute("Phase"))
		.. "; toasts " .. since(n0) .. ")")
	assert(CY:GetAttribute("Round") == round0 + 1 and player:GetAttribute("CypherIn") == CY:GetAttribute("Round"), "the board's lobby is round "
		.. tostring(CY:GetAttribute("Round")) .. " with CypherIn " .. tostring(player:GetAttribute("CypherIn")) .. ", want round " .. (round0 + 1) .. " with you in")
	assert(waitFor(function() return toastWith("You're in the cypher", n0 + 1) ~= nil end, 2), "no 'You're in the cypher' toast from the board: " .. since(n0))
	table.insert(out, "2 the board opened round " .. CY:GetAttribute("Round") .. " with you in it")

	-- 3. in the lobby the remote still joins: you're in already
	local r3 = R.Cypher_Join:InvokeServer()
	assert(type(r3) == "table" and r3.ok == false and r3.reason == "joined", "Cypher_Join in your own lobby answered "
		.. tostring(type(r3) == "table" and r3.reason) .. ", want joined")
	table.insert(out, "3 Cypher_Join in the lobby: joined")

	-- 4. alone: cancelled for too few when the lobby closes, idle after its reveal
	local lobby = (Config.Cypher or {}).LobbySeconds or 20
	assert(waitFor(function() return CY:GetAttribute("Phase") == "reveal" end, lobby + 5), "the lobby did not end within " .. (lobby + 5) .. " s (Phase "
		.. tostring(CY:GetAttribute("Phase")) .. ")")
	local result = CY:GetAttribute("Result") or ""
	assert(string.find(result, "not enough joined", 1, true), "the lobby ended with '" .. result .. "', want the cancel for too few entrants")
	assert(waitFor(function() return CY:GetAttribute("Phase") == "idle" end, 8), "the cypher did not idle after the cancel's reveal")
	table.insert(out, "4 alone, the lobby was cancelled ('" .. result .. "') and idled")

	-- 5. inside the cooldown neither the board nor the remote opens a lobby
	local n5 = #toasts
	assert(press(function() return toastWith("A cypher is under way", n5 + 1) ~= nil end), "the board gave no 'A cypher is under way' toast right after a lobby was"
		.. " cancelled for too few (toasts " .. since(n5) .. ", Phase " .. tostring(CY:GetAttribute("Phase")) .. ")")
	task.wait(0.3)
	assert(CY:GetAttribute("Phase") == "idle" and player:GetAttribute("CypherIn") == nil, "the board opened a lobby right after one was cancelled for too few (Phase "
		.. tostring(CY:GetAttribute("Phase")) .. ")")
	local r5 = R.Cypher_Join:InvokeServer()
	assert(type(r5) == "table" and r5.ok == false and r5.reason == "busy" and CY:GetAttribute("Phase") == "idle", "Cypher_Join in the cooldown answered "
		.. tostring(type(r5) == "table" and r5.reason) .. ", want busy")
	table.insert(out, "5 in the cooldown: the board said '" .. toastWith("A cypher is under way", n5 + 1) .. "', Cypher_Join busy, the cypher idle")
end

local ok, err = pcall(run)
conn:Disconnect()
cam.CameraType = Enum.CameraType.Custom
if not ok then error(err, 0) end
return "T83B PLAY OK\n" .. table.concat(out, "\n")
