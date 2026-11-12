-- Client, during play (after t47e: the cypher idle, the walk-in card waiting behind the open beat maker): "defers during
-- cypher". The cypher's Phase and your CypherIn are set here, on this client only, and put back on every path; the
-- server's never change.
-- (1) Phase "listen" (it holds everyone), then the beat maker closed: the card stays deferred, and the Waiting chip
--     stays up, clear of the live cypher bar.
-- (2) Phase "lobby" with your CypherIn at the cypher's Round: a lobby holds its entrants, so the card still waits.
-- (3) CypherIn gone: a lobby holds nobody else (launch audit A2/A4), so the card opens by itself, and stays open for t47h.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui", 10)
local gui = pg:WaitForChild("OK_WalkIn", 10); assert(gui, "no OK_WalkIn gui")
local daw = pg.OK_DAW.DAW; local bar = pg.OK_Cypher.Bar
local CY = RS.OK.Cypher
local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); local cam = workspace.CurrentCamera
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function rel(g) local p, s = g.AbsolutePosition - gui.AbsolutePosition, g.AbsoluteSize; return { x0 = p.X, y0 = p.Y, x1 = p.X + s.X, y1 = p.Y + s.Y } end
local function overlaps(a, b) return a.x0 < b.x1 and b.x0 < a.x1 and a.y0 < b.y1 and b.y0 < a.y1 end
local function fmt(r) return string.format("(%d,%d)-(%d,%d)", r.x0, r.y0, r.x1, r.y1) end
local was = { phase = CY:GetAttribute("Phase"), cypherIn = player:GetAttribute("CypherIn") }
local out = {}

local function run()
	assert((was.phase or "idle") == "idle", "the cypher is at " .. tostring(was.phase) .. ": this case needs t47e's idle cypher")
	-- 1. listening holds everyone: closing the beat maker (open since t47b) leaves the card deferred
	CY:SetAttribute("Phase", "listen")
	if daw.Visible then daw:SetAttribute("Command", "close") end
	assert(waitFor(function() return not daw.Visible end, 3), "beat maker did not close")
	if hum and hum.Sit then hum.Sit = false; task.wait(0.4) end
	cam.CameraType = Enum.CameraType.Custom
	task.wait(0.6) -- deferral re-check and chip placement (0.2 s each)
	local chip, card = gui:FindFirstChild("Waiting", true), gui:FindFirstChild("Card", true)
	assert(gui:GetAttribute("Deferred") == true, "card not deferred while the cypher listens (Deferred " .. tostring(gui:GetAttribute("Deferred")) .. ")")
	assert(gui:GetAttribute("Open") == false and not card.Visible, "the card opened while the cypher listens")
	assert(chip.Visible, "Waiting chip hidden during the cypher")
	assert(waitFor(function() return bar.Visible end, 2), "cypher bar hidden while it listens")
	task.wait(0.3)
	assert(not overlaps(rel(chip), rel(bar)), "Waiting chip " .. fmt(rel(chip)) .. " covers the cypher bar " .. fmt(rel(bar)))
	table.insert(out, "1 defers while the cypher listens (beat maker closed); chip " .. fmt(rel(chip)) .. " under the bar " .. fmt(rel(bar)))

	-- 2. a lobby holds its entrants
	local round = CY:GetAttribute("Round") or 0
	player:SetAttribute("CypherIn", round)
	CY:SetAttribute("Phase", "lobby")
	task.wait(0.6)
	assert(gui:GetAttribute("Deferred") == true and gui:GetAttribute("Open") == false, "the card opened for an entrant of the cypher's lobby (CypherIn "
		.. round .. "; Open " .. tostring(gui:GetAttribute("Open")) .. ", Deferred " .. tostring(gui:GetAttribute("Deferred")) .. ")")
	table.insert(out, "2 in the lobby as its entrant (CypherIn " .. round .. "): still deferred")

	-- 3. and nobody else: the card opens by itself
	player:SetAttribute("CypherIn", was.cypherIn)
	assert(waitFor(function() return gui:GetAttribute("Open") == true and gui:GetAttribute("Deferred") == false end, 2),
		"the card did not open with the cypher in its lobby and you not in it, which holds no walk-in card (Open " .. tostring(gui:GetAttribute("Open"))
		.. ", Deferred " .. tostring(gui:GetAttribute("Deferred")) .. ")")
	assert(card.Visible and not chip.Visible, "card hidden or chip still shown after opening in the lobby")
	table.insert(out, "3 in the lobby, not in it: the card opened by itself")
end

local ok, err = pcall(run)
CY:SetAttribute("Phase", was.phase)
player:SetAttribute("CypherIn", was.cypherIn)
if not ok then error(err, 0) end
return "T47F PLAY OK\n" .. table.concat(out, "\n")
