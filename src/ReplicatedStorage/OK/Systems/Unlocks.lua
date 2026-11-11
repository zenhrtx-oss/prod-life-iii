-- OK Studio system: world unlocks (walk-ins). The Studio Two door and the sponsor ticker on the lounge TV; the fits are
-- Systems/Gear with Modules/Fits.
-- * The door: Workspace.OK_Gates.StudioTwoDoor (build/18_gates.lua, interaction kind StudioTwoDoor). It opens on the
--   owner's client only (StarterPlayerScripts/OK/GatesClient reads CareerGates); the server's door always collides.
--   Pressing it toasts where you stand: "The Hall is open for you"; "Unlock it in the Career tab · $5,000" once the
--   needs and the money are met; else "NEEDS " and what you lack ("NEEDS 1 PLACEMENT · 300 AURA · $5,000"). Unlocking
--   itself is Career_Unlock (Systems/Career). A refused press makes no sound.
-- * The sponsor ticker: every TickSeconds the lounge TV (OKStudio.Lounge.TV_Screen.ScreenText.Label) shows the next
--   sponsored producer in the hub as "SPONSORED BY\n<SPONSOR>\nprod. <DisplayName>". Sponsored means CareerGates holds
--   sponsor_tv (Sponsors >= 1 and showSponsor on) and the Sponsor attribute names a current deal. The first write keeps
--   the TV's own text in the TV's TickerSaved attribute; it comes back once no sponsored producer is left. The monitors
--   win: nothing is written while NowPlaying.Active or the TV's SavedText (MonitorService) is set, and if a beat started
--   over the ticker the original moves into SavedText so MonitorService restores it after the airing. InteractionService
--   refuses the TV's own prompt while TickerSaved is set.
-- * Studio-only hook ServerScriptService.OK._StudioUnlocksHook (Studio + running), hook:Invoke(cmd, userId, ...):
--   Door(userId) -> toastText, owned; Equip(userId, gearId) -> Gear.Equip's result; Ticker() -> the TV's text;
--   TV(userId) -> acted, toastText (the real TV handler through InteractionService._RunHandler).
local RS, Players = game:GetService("ReplicatedStorage"), game:GetService("Players")
local Config = require(RS.OK.Config)
local Rules = require(RS.OK.Modules.CareerRules)
local Format = require(RS.OK.Modules.Format)
local WalkInRules = require(RS.OK.Modules.WalkInRules)
local Career = require(RS.OK.Systems.Career)
local M = { Enabled = true, Version = 1 }
M.TickSeconds = 8
M.OPEN_TEXT = "The Hall is open for you"
local DOOR_GATE, TV_GATE = "studio_two", "sponsor_tv"
local ctx
-- the needs in a NEEDS toast: the rarer stats first, each { one, many }
local ORDER = { "placements", "hits", "sponsors", "followers", "aura" }
local WORDS = { placements = { "PLACEMENT", "PLACEMENTS" }, hits = { "HIT", "HITS" }, sponsors = { "SPONSOR", "SPONSORS" },
	followers = { "FOLLOWER", "FOLLOWERS" }, aura = { "AURA", "AURA" } }

local function listHas(list, id) return type(list) == "string" and string.find("," .. list .. ",", "," .. id .. ",", 1, true) ~= nil end
local function gateById(id)
	for _, g in ipairs((Config.Career or {}).Gates or {}) do if g.id == id then return g end end
	return nil
end

-- the door's toast for a Career (`have`, as CareerRules.Have makes it) and a room gate; returns text, owned
function M.DoorText(have, g)
	if have.gates and have.gates[g.id] then return M.OPEN_TEXT, true end
	local check = Rules.Check(have, g.needs, g.cost)
	if check.ok then return "Unlock it in the Career tab · " .. Format.Money(g.cost or 0), false end
	local rows = {}
	for _, row in ipairs(check.rows) do rows[row.stat] = row end
	local missing = {}
	for _, stat in ipairs(ORDER) do
		local row = rows[stat]
		if row and not row.ok then
			local w = WORDS[stat]
			table.insert(missing, Format.Count(row.need) .. " " .. (row.need == 1 and w[1] or w[2]))
		end
	end
	if not check.money.ok then table.insert(missing, Format.Money(check.money.need)) end
	return "NEEDS " .. table.concat(missing, " · "), false
end
local function doorFor(player)
	local g = gateById(DOOR_GATE)
	assert(g, "Config.Career.Gates has no " .. DOOR_GATE)
	return M.DoorText(Career.Get(player), g)
end

-- the sponsor ticker ------------------------------------------------------------------------------------------------
local function tvPart()
	local s = workspace:FindFirstChild("OKStudio")
	local lounge = s and s:FindFirstChild("Lounge")
	return lounge and lounge:FindFirstChild("TV_Screen")
end
local function tvLabel(tv)
	local gui = tv and tv:FindFirstChild("ScreenText")
	return gui and gui:FindFirstChild("Label")
end

function M.TickerText(sponsorName, displayName) return string.format("SPONSORED BY\n%s\nprod. %s", sponsorName, displayName) end

-- one line per sponsored producer in the hub, ordered by UserId so the rotation keeps its place
function M.SponsoredLines()
	local rows = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local name = p:GetAttribute("Sponsor")
		local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if type(name) == "string" and name ~= "" and listHas(p:GetAttribute("CareerGates"), TV_GATE) and root then
			local pos = root.Position
			if WalkInRules.InHub(pos.X, pos.Y, pos.Z) then table.insert(rows, { uid = p.UserId, text = M.TickerText(name, p.DisplayName) }) end
		end
	end
	table.sort(rows, function(a, b) return a.uid < b.uid end)
	local lines = {}
	for i, r in ipairs(rows) do lines[i] = r.text end
	return lines
end

local rot = 0 -- the line shown last
-- one ticker step on `tv` (a part with ScreenText.Label): `active` = NowPlaying.Active, `lines` = SponsoredLines()
function M._TickerStep(tv, active, lines)
	local lbl = tvLabel(tv)
	if not lbl then return end
	local saved, mine = tv:GetAttribute("SavedText"), tv:GetAttribute("TickerSaved")
	if #lines == 0 then
		if mine == nil then return end
		if saved ~= nil then
			-- a beat started over the ticker: MonitorService will put SavedText back after the airing, so hand it the original
			tv:SetAttribute("SavedText", mine); tv:SetAttribute("TickerSaved", nil)
		elseif not active then
			lbl.Text = mine; tv:SetAttribute("TickerSaved", nil)
		end
		return
	end
	if active or saved ~= nil then return end -- the monitors own the TV
	if mine == nil then tv:SetAttribute("TickerSaved", lbl.Text) end
	rot = rot % #lines + 1
	lbl.Text = lines[rot]
end

local function tick()
	local tv = tvPart()
	if not tv then return end
	local np = RS.OK:FindFirstChild("NowPlaying")
	M._TickerStep(tv, np ~= nil and np:GetAttribute("Active") == true, M.SponsoredLines())
end

-- Studio-only test seam (Studio + running) ----------------------------------------------------------------------------
local function makeHook()
	local SOK = game:GetService("ServerScriptService"):FindFirstChild("OK")
	if not SOK then return end
	local hook = SOK:FindFirstChild("_StudioUnlocksHook") or Instance.new("BindableFunction")
	hook.Name = "_StudioUnlocksHook"; hook.Parent = SOK
	hook.OnInvoke = function(cmd, userId, a)
		if cmd == "Ticker" then local lbl = tvLabel(tvPart()); return lbl and lbl.Text end
		local p = Players:GetPlayerByUserId(userId)
		if not p then return nil end
		if cmd == "Door" then return doorFor(p) end
		if cmd == "Equip" then return require(RS.OK.Systems.Gear).Equip(p, a) end
		if cmd == "TV" then return ctx.Interaction._RunHandler("TV", p, tvPart()) end
		return nil
	end
end

function M.Init(c)
	ctx = c
	c.Interaction.Register("StudioTwoDoor", function(player)
		local text, owned = doorFor(player)
		RS.OK.Remotes.InteractionEvent:FireClient(player, "Toast", { text = text })
		return owned -- a refused press plays no door sound
	end)
	task.spawn(function()
		while true do
			task.wait(M.TickSeconds)
			local ok, err = pcall(tick)
			if not ok then warn("[OK][ERR] sponsor ticker: " .. tostring(err)) end
		end
	end)
	local Run = game:GetService("RunService")
	if Run:IsStudio() and Run:IsRunning() then makeHook() end
end

return M
