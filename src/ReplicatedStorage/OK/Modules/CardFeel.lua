-- OK Studio card feel (client; design 4.5): what the walk-in card (WalkInUI) and the phone card (PhoneUI) share in 1b.
-- Built once by its first caller: the six UI sounds are made on first use, nothing runs at require time.
-- * Footer(): the local player's Aura band line (Format.AuraFooter: in the red, 0-299, 300 and up).
-- * BeatLine(beat): the walk-in card's second footer line (Wave 3 design 4.1) for its payload's `beat`: a { stars, fires }
--   reads "Your best beat: ★★★ · 🔥 3" (the stars out of three, the FIRE part only once it has FIRE), false reads "No
--   beat delivered yet. Your odds are lower."; nil (no choice on the card goes by your beat) gives nil: no line.
-- * Opened(token): the CardOpen riser, once per token (a card hidden and shown again by the beat maker stays quiet).
-- * Pop(token): the PhoneBuzz, once per token (the icon's re-shake never buzzes).
-- * Result(payload, dawUp): Win or Loss at once (a neutral result has neither), Money 0.25 s later when a chip of kind
--   "money" reads "+...", Plant 0.5 s later when `planted` is set, then the avatar reaction in task.spawn. It never
--   yields and never dedupes (a visit's arrival news and its choice result share a token): its callers call it once
--   per result, last, after the result shows and its auto-close is scheduled. dawUp: the caller's beat maker or
--   listen-back cutaway is up, or went down within the last second.
-- * Sound(key): plays the Config.SFX UI key locally (SoundService:PlayLocalSound, never from a world part) unless the
--   HUD mute (the player attribute MuteMonitors) is on; a key absent from Config plays nothing. Only a sound that plays
--   is logged.
-- The reaction runs on your own character (an owner's emote and Sit replicate to everyone). The first match wins:
-- skip:off (that half switched off here), skip:dead, skip:seated (a seat holds you: hum.SeatPart), skip:daw (dawUp),
-- skip:r6 (R6 gets only the walk-in tag), skip:moving (airborne: FloorMaterial Air, or Jumping / Freefall /
-- GettingUp); then a win cheers through the default Animate script (PlayEmote:Invoke("cheer"), the /e cheer path that
-- plays Roblox's CheerAnim; a refusal or an error is skip:moving) and a loss sits you down where you stand for 2 s.
-- Only the reaction that set Sit releases it, only on the character it started on while that lives (Health above 0
-- and not in the Dead state: a client ChangeState(Dead) can leave Health up until the respawn), and only when no seat
-- holds you.
-- Attributes on OK_UI (tests): LastSound (a Config.SFX key), Sounds (count), SoundLog (the last 12 keys joined by ","),
-- LastReaction ("cheer" | "sit" | "skip:off" | "skip:dead" | "skip:seated" | "skip:daw" | "skip:r6" | "skip:moving").
local Players, RS, SoundService = game:GetService("Players"), game:GetService("ReplicatedStorage"), game:GetService("SoundService")
local Config = require(RS.OK.Config)
local Format = require(RS.OK.Modules.Format)

local M = {}
local UI_KEYS = { "CardOpen", "Win", "Loss", "Money", "Plant", "PhoneBuzz" } -- the Config.SFX keys played here
local LOG_MAX = 12
local MONEY_AFTER, PLANT_AFTER = 0.25, 0.5
local SIT_SECONDS = 2
-- each half of the reaction (Task 0: both work on R15; the cheer through the Animate script, P2). false = skip:off
local REACT = { win = true, loss = true }
local AIRBORNE = { [Enum.HumanoidStateType.Jumping] = true, [Enum.HumanoidStateType.Freefall] = true,
	[Enum.HumanoidStateType.GettingUp] = true }

local sounds = nil         -- [key] = Sound, made on the first Sound()
local opened, popped = {}, {} -- tokens already given their riser / buzz
local soundLog = {}
local reactSerial, sitBy = 0, nil -- the latest reaction's token; the token whose Sit is on

local function okUI()
	local pg = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	return pg and pg:FindFirstChild("OK_UI")
end

-- the UI sounds, once: a Sound per key in a Folder under SoundService (parented last: one ChildAdded, a Folder)
local function build()
	if sounds then return sounds end
	sounds = {}
	local ok, err = pcall(function()
		local folder = Instance.new("Folder")
		folder.Name = "OK_UISounds"
		for _, key in ipairs(UI_KEYS) do
			local def = type(Config.SFX) == "table" and Config.SFX[key] or nil
			if type(def) == "table" and type(def.id) == "string" then
				local s = Instance.new("Sound")
				s.Name = key; s.SoundId = def.id; s.Volume = tonumber(def.volume) or 0.5
				s.Parent = folder
				sounds[key] = s
			end
		end
		folder.Parent = SoundService
	end)
	if not ok then warn("[OK][ERR] CardFeel: sounds: " .. tostring(err)) end
	return sounds
end

function M.Sound(key)
	if Players.LocalPlayer:GetAttribute("MuteMonitors") == true then return end
	local s = build()[key]
	if not s then return end
	local ok, err = pcall(function() SoundService:PlayLocalSound(s) end)
	if not ok then warn("[OK][ERR] CardFeel: play " .. key .. ": " .. tostring(err)); return end
	table.insert(soundLog, key)
	if #soundLog > LOG_MAX then table.remove(soundLog, 1) end
	local ui = okUI()
	if ui then
		ui:SetAttribute("LastSound", key)
		ui:SetAttribute("Sounds", (tonumber(ui:GetAttribute("Sounds")) or 0) + 1)
		ui:SetAttribute("SoundLog", table.concat(soundLog, ","))
	end
end

function M.Footer()
	return Format.AuraFooter(Players.LocalPlayer:GetAttribute("Aura"))
end

M.NoBeat = "No beat delivered yet. Your odds are lower."
function M.BeatLine(beat)
	if beat == nil then return nil end
	if type(beat) ~= "table" then return M.NoBeat end
	local stars = math.clamp(math.floor(tonumber(beat.stars) or 0), 0, 3)
	local fires = math.max(0, math.floor(tonumber(beat.fires) or 0))
	local line = "Your best beat: " .. string.rep("★", stars) .. string.rep("☆", 3 - stars)
	if fires > 0 then line ..= " · 🔥 " .. fires end
	return line
end

function M.Opened(token)
	local k = tostring(token)
	if opened[k] then return end
	opened[k] = true
	M.Sound("CardOpen")
end

function M.Pop(token)
	local k = tostring(token)
	if popped[k] then return end
	popped[k] = true
	M.Sound("PhoneBuzz")
end

local function setReaction(r)
	local ui = okUI()
	if ui then ui:SetAttribute("LastReaction", r) end
end
-- the first skip that applies (Shared shapes order), or nil
local function skipOf(tone, char, hum, dawUp)
	if not REACT[tone] then return "skip:off" end
	if not (char and hum and hum.Parent and hum.Health > 0) or hum:GetState() == Enum.HumanoidStateType.Dead then return "skip:dead" end
	if hum.SeatPart ~= nil then return "skip:seated" end
	if dawUp then return "skip:daw" end
	if hum.RigType == Enum.HumanoidRigType.R6 then return "skip:r6" end
	if hum.FloorMaterial == Enum.Material.Air or AIRBORNE[hum:GetState()] then return "skip:moving" end
	return nil
end
local function react(tone, dawUp)
	reactSerial += 1
	local my = reactSerial
	local char = Players.LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local skip = skipOf(tone, char, hum, dawUp)
	if skip then setReaction(skip); return end
	if tone == "win" then
		-- the Animate script plays it only while standing; nil, false or an error (no such script) reads as moving
		local ok, played = pcall(function() return char.Animate.PlayEmote:Invoke("cheer") end)
		setReaction((ok and played) and "cheer" or "skip:moving")
		return
	end
	hum.Sit = true
	sitBy = my
	setReaction("sit")
	task.wait(SIT_SECONDS)
	if sitBy ~= my then return end -- a later sit owns it now
	sitBy = nil
	if Players.LocalPlayer.Character == char and hum.Parent and hum.Health > 0 and hum:GetState() ~= Enum.HumanoidStateType.Dead
		and hum.SeatPart == nil and hum.Sit then
		hum.Sit = false
	end
end

function M.Result(r, dawUp)
	if type(r) ~= "table" then return end
	local tone = r.tone
	if tone == "win" then M.Sound("Win") elseif tone == "loss" then M.Sound("Loss") end
	for _, c in ipairs(type(r.chips) == "table" and r.chips or {}) do
		if type(c) == "table" and c.kind == "money" and tostring(c.label or ""):sub(1, 1) == "+" then
			task.delay(MONEY_AFTER, M.Sound, "Money")
			break
		end
	end
	if r.planted then task.delay(PLANT_AFTER, M.Sound, "Plant") end
	if tone == "win" or tone == "loss" then
		task.spawn(function()
			local ok, err = pcall(react, tone, dawUp == true)
			if not ok then warn("[OK][ERR] CardFeel: reaction: " .. tostring(err)) end
		end)
	end
end

return M
