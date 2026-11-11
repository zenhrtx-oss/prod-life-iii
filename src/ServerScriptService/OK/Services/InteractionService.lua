-- OK Studio InteractionService (v2).
-- Hooks every ProximityPrompt on parts tagged OK_Interactable (attribute Kind), plays the part's licensed SFX,
-- enforces per-player and server-wide cooldowns (Config.Cooldowns / Config.GlobalCooldowns), runs the registered
-- handler, then fires M.Used(player, kind, inst) for the tour and analytics.
-- In Studio only, M._RunHandler(kind, player, inst) runs a registered handler directly for tests.
local CS, TS, Players = game:GetService("CollectionService"), game:GetService("TweenService"), game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.OK.Config)
local Event, ProfileFn = RS.OK.Remotes.InteractionEvent, RS.OK.Remotes.ProfileFunction

local M = {}
local handlers = {}
local ctx
local usedEvent = Instance.new("BindableEvent")
M.Used = usedEvent.Event

function M.Register(kind, fn) handlers[kind] = fn end
function M.Toggle(inst, attr) local v = not inst:GetAttribute(attr); inst:SetAttribute(attr, v); return v end
local capture -- Studio-only: while _RunHandler runs a handler, the last toast it sends that player
local function send(player, kind, payload)
	payload = payload or {}
	if capture and capture.player == player and kind == "Toast" then capture.toast = payload.text end
	Event:FireClient(player, kind, payload)
end
local function xpText(n) return (n and n > 0) and (" · +" .. n .. " XP") or "" end

-- handlers -------------------------------------------------------------------------
local function consolePower(player, inst)
	local on = M.Toggle(inst, "Powered")
	local gained = on and ctx.Data.AddXP(player, Config.XP.Console, "Console") or 0
	send(player, "Toast", { text = on and ("Console on" .. xpText(gained)) or "Console off" })
end

local recBusy = false
local function setRec(on)
	local VB = workspace.OKStudio.VocalBooth
	local rec, lamp, backing = VB:FindFirstChild("REC_Sign"), VB:FindFirstChild("BoothLamp"), VB:FindFirstChild("REC_Backing")
	if rec then
		rec:SetAttribute("On", on)
		rec.Color = on and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(80, 10, 10)
		local l = rec:FindFirstChildWhichIsA("Light"); if l then l.Enabled = on end
	end
	if lamp then
		lamp.Color = on and Color3.fromRGB(255, 60, 60) or Config.Colors.warm
		local l = lamp:FindFirstChildWhichIsA("Light"); if l then l.Color = lamp.Color end
	end
	if backing then
		local t = backing:FindFirstChild("RecText"); local lbl = t and t:FindFirstChild("Label")
		if lbl then lbl.TextColor3 = on and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(120, 20, 20) end
	end
end
local function micTake(player, inst)
	if recBusy then send(player, "Toast", { text = "Booth is recording, wait for the light" }) return false end
	recBusy = true
	setRec(true)
	local gained = ctx.Data.AddXP(player, Config.XP.Take, "Mic")
	send(player, "Toast", { text = "REC · " .. Config.Interaction.RecSeconds .. "s" .. xpText(gained) })
	task.delay(Config.Interaction.RecSeconds, function()
		setRec(false); recBusy = false
		if player.Parent then send(player, "Toast", { text = "Take done" }) end
	end)
end

local function lightSwitch(player, inst)
	local name = ctx.Lighting.Toggle()
	send(player, "Toast", { text = "Lighting: " .. name })
end

local function door(player, inst)
	local open = M.Toggle(inst, "Open")
	local z = open and (inst:GetAttribute("OpenZ") or 6.3) or (inst:GetAttribute("ClosedZ") or 0)
	TS:Create(inst, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = CFrame.new(inst.Position.X, inst.Position.Y, z) }):Play()
	local prompt = inst:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then prompt.ActionText = open and "Close" or "Open" end
end

local function computer(player, inst)
	send(player, "OpenPanel", { tab = "Sessions", source = inst:GetFullName(), profile = ctx.Data.ClientProfile(ctx.Data.GetProfile(player)) })
end
local function creditsWall(player, inst)
	send(player, "OpenPanel", { tab = "Credits", source = inst:GetFullName(), profile = ctx.Data.ClientProfile(ctx.Data.GetProfile(player)) })
end

local tvScreens = {
	"PROD LIFE III\n\nHOUSE STUDIO · LOUNGE\n[ CHANGE SCREEN ]",
	"SESSIONS OPEN\n\nARTISTS NEED BEATS\nSTUDIO PC · LAPTOPS",
	"BEAT MAKER\n\nCONTROL ROOM · STUDIO PC\nPLAY IT ON THE MONITORS",
}
local function tv(player, inst)
	if inst:GetAttribute("SavedText") then -- the monitors own the TV while a beat is playing
		send(player, "Toast", { text = "The TV is showing the monitors right now" })
		return false
	end
	if inst:GetAttribute("TickerSaved") then -- the sponsor ticker (Systems/Unlocks) owns the TV while a sponsored producer is in
		send(player, "Toast", { text = "The TV is showing sponsors right now" })
		return false
	end
	local i = ((inst:GetAttribute("ScreenIndex") or 1) % #tvScreens) + 1
	inst:SetAttribute("ScreenIndex", i)
	local gui = inst:FindFirstChild("ScreenText"); local lbl = gui and gui:FindFirstChild("Label")
	if lbl then lbl.Text = tvScreens[i] end
end

-- sounds, door at start ------------------------------------------------------------
local function attachSfx()
	for kind, def in pairs(Config.SFX or {}) do
		for _, inst in ipairs(CS:GetTagged("OK_Interactable")) do
			if inst:IsDescendantOf(workspace) and inst:GetAttribute("Kind") == kind and inst:IsA("BasePart") then
				local s = inst:FindFirstChild("SFX") or Instance.new("Sound")
				s.Name = "SFX"; s.SoundId = def.id; s.Volume = def.volume or 0.6
				s.RollOffMode = Enum.RollOffMode.InverseTapered; s.RollOffMinDistance = 6; s.RollOffMaxDistance = 40
				s.Parent = inst
			end
		end
	end
end
local function playSfx(inst)
	local s = inst:FindFirstChild("SFX")
	if s and s:IsA("Sound") then s.TimePosition = 0; s:Play() end
end
local function openDoorAtStart()
	local s = workspace:FindFirstChild("OKStudio"); local d = s and s.Shell:FindFirstChild("SlidingDoor")
	if not d or d:GetAttribute("Open") then return end
	d:SetAttribute("Open", true)
	d.CFrame = CFrame.new(d.Position.X, d.Position.Y, d:GetAttribute("OpenZ") or 6.3)
	local prompt = d:FindFirstChildWhichIsA("ProximityPrompt", true); if prompt then prompt.ActionText = "Close" end
end

-- cooldowns ------------------------------------------------------------------------
local lastUse = {}    -- [player] = {[kind] = os.clock()}
local lastGlobal = {} -- [kind] = os.clock()
local function allowed(player, kind)
	local now = os.clock()
	local mine = lastUse[player]; if not mine then mine = {}; lastUse[player] = mine end
	local cd = Config.Cooldowns and Config.Cooldowns[kind]
	if cd and mine[kind] and now - mine[kind] < cd then return false, "player" end
	local g = Config.GlobalCooldowns and Config.GlobalCooldowns[kind]
	if g and lastGlobal[kind] and now - lastGlobal[kind] < g then return false, "global" end
	mine[kind] = now
	if g then lastGlobal[kind] = now end
	return true
end
M._allowed = allowed

-- Studio-only test seam: runs the handler registered for `kind` as `player` on `inst`, with no distance check, cooldown,
-- sound or Used event. Returns acted (false when the handler refused, as the prompt path reads it) and the text of the
-- last toast the handler sent that player while it ran (nil if none).
if game:GetService("RunService"):IsStudio() then
	function M._RunHandler(kind, player, inst)
		local h = handlers[kind]
		if not h then return false, nil end
		local mine = { player = player }
		capture = mine
		local ok, res = pcall(h, player, inst)
		if capture == mine then capture = nil end
		if not ok then error(res, 0) end
		return res ~= false, mine.toast
	end
end

local function hook(inst)
	if not inst:IsDescendantOf(workspace) then return end
	local prompt = inst:FindFirstChildWhichIsA("ProximityPrompt", true)
	if not prompt or inst:GetAttribute("OK_Hooked") then return end
	inst:SetAttribute("OK_Hooked", true)
	prompt.Triggered:Connect(function(player)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root or (root.Position - inst.Position).Magnitude > Config.Interaction.MaxDistance + 8 then return end
		local kind = inst:GetAttribute("Kind")
		local ok, why = allowed(player, kind)
		if not ok then
			if why == "global" then send(player, "Toast", { text = "Someone just used that · try again in a moment" }) end
			return
		end
		print(string.format("[OK] %s used %s", player.Name, tostring(kind)))
		local h = handlers[kind]
		if h then
			-- handlers return false when they did nothing; only real actions make a sound for the room
			local acted = h(player, inst)
			if acted ~= false then
				playSfx(inst)
				usedEvent:Fire(player, kind, inst)
			end
		end
	end)
end

function M.Init(c)
	ctx = c
	M.Register("Console", consolePower); M.Register("Mic", micTake); M.Register("LightSwitch", lightSwitch); M.Register("Door", door)
	M.Register("Computer", computer); M.Register("CreditsWall", creditsWall); M.Register("TV", tv)
	for _, inst in ipairs(CS:GetTagged("OK_Interactable")) do hook(inst) end
	CS:GetInstanceAddedSignal("OK_Interactable"):Connect(hook)
	ProfileFn.OnServerInvoke = function(player) return ctx.Data.ClientProfile(ctx.Data.GetProfile(player)) end
	Players.PlayerRemoving:Connect(function(p) lastUse[p] = nil end)
	attachSfx()
	openDoorAtStart()
end

return M
