-- OK Studio system: FIRE reactions + nameplates. While someone else's beat airs on the monitors and you're in the room,
-- tap FIRE (once per airing, after the first bar). The producer gets +1 FIRE (profile fireTotal, shown on their
-- nameplate) and a little Cred (Config.Cred.Sources.Fire, capped daily); the listener gets a little XP for the tap
-- (Config.XP.Sources.FireTap). Never for standing nearby, never on your own beat, at most Config.Fire.PairDaily FIRE
-- from one listener to one producer per UTC day (prof.fireLog). Each FIRE also feeds the producer's Followers
-- (Systems/Career) and goes on the aired beat in the producer's recent beats (Wave 3, design 4.1: Contracts.CreditFire,
-- the one writer of prof.sessions; the pattern and bpm come from NowPlaying while it still airs that token). A FIRE to an
-- online producer also ends their cold spell (Wave 3, design 4.2: Career.ColdCheck "fire"), whatever the beat credit did,
-- and counts as being heard: it moves their lastDay to today, warm or cold (final review I1, CareerRules.LastDayStep).
local RS, Players = game:GetService("ReplicatedStorage"), game:GetService("Players")
local Config = require(RS.OK.Config)
local DAWCfg = require(RS.OK.Modules.DAWConfig)
local Nameplate = require(RS.OK.Modules.Nameplate)
local Format = require(RS.OK.Modules.Format)
local M = { Enabled = true, Version = 1 }
local ctx
local fired = {} -- [token] = { [listenerId] = true }

local function fireCfg() return Config.Fire or { Range = 45, PairDaily = 3 } end
function M.Rank(level) return (Config.Ranks and Config.Ranks[level]) or "" end

-- pure rule check. s = { active, token, ownerId, startAt, barLen, now, fired = set, pairCount }, a = { listenerId, token, dist }
function M.Judge(s, a)
	if not s.active then return false, "noair" end
	if s.cypher then return false, "cypher" end -- anonymous cypher entries take votes, not FIRE
	if a.token ~= s.token then return false, "stale" end
	if a.listenerId == s.ownerId then return false, "self" end
	if (s.now - s.startAt) < s.barLen then return false, "early" end
	if s.fired and s.fired[a.listenerId] then return false, "again" end
	if (a.dist or math.huge) > fireCfg().Range then return false, "far" end
	if (s.pairCount or 0) >= fireCfg().PairDaily then return false, "pair" end
	return true
end

local function speakerDist(pos)
	local s = workspace:FindFirstChild("OKStudio"); local cr = s and s:FindFirstChild("ControlRoom")
	local best = math.huge
	for _, n in ipairs({ "Speaker_L", "Speaker_R" }) do
		local sp = cr and cr:FindFirstChild(n)
		if sp then best = math.min(best, (sp.Position - pos).Magnitude) end
	end
	return best
end
local function today() return tonumber(os.date("!%Y%m%d", ctx.Data._now and ctx.Data._now() or os.time())) end
local function pairCount(prof, authorId)
	local log = prof.fireLog
	if type(log) ~= "table" or log.day ~= today() then log = { day = today(), given = {} }; prof.fireLog = log end
	log.given = log.given or {}
	return log.given[tostring(authorId)] or 0, log
end

-- the reward half, shared by the remote (a real listener) and the Studio test hook (a fake listener id)
function M.Give(listenerId, listener, authorId, token)
	fired[token] = fired[token] or {}
	fired[token][listenerId] = true
	ctx.Monitors:AddFire()
	local xp = 0
	if listener then xp = ctx.Data.AddXP(listener, 2, "FireTap") end
	local author = Players:GetPlayerByUserId(authorId)
	local cred = 0
	if author then
		local aprof = ctx.Data.GetProfile(author)
		aprof.fireTotal = (tonumber(aprof.fireTotal) or 0) + 1
		author:SetAttribute("FireTotal", aprof.fireTotal)
		ctx.Data.MarkDirty(author)
		cred = ctx.Data.AddCred(author, Config.Cred.Sources.Fire.amount, "Fire")
		local ok, err = pcall(function() require(RS.OK.Systems.Career).Add(author, "followers", Config.Career.Sources.Fire.followers.amount, "Fire") end)
		if not ok then warn("[OK][ERR] career feed: " .. tostring(err)) end
		-- your beat (Wave 3): the FIRE goes on the beat on air, read only while NowPlaying still airs this token; a failure
		-- here never touches the FIRE itself
		local okB, errB = pcall(function()
			local NP = RS.OK:FindFirstChild("NowPlaying")
			local beat = NP and NP:GetAttribute("Token") == token and NP:GetAttribute("Beat") or nil
			if type(beat) == "string" and beat ~= "" then require(RS.OK.Systems.Contracts).CreditFire(author, beat, NP:GetAttribute("BPM")) end
		end)
		if not okB then warn("[OK][ERR] beat FIRE credit: " .. tostring(errB)) end
		-- the cold spell: a FIRE on a beat you put on the monitors is one of its two ways out, and keeps a warm producer's
		-- lastDay at today (being heard, final review I1); never touches the FIRE
		local okC, errC = pcall(function() require(RS.OK.Systems.Career).ColdCheck(author, "fire") end)
		if not okC then warn("[OK][ERR] cold FIRE: " .. tostring(errC)) end
		RS.OK.Remotes.InteractionEvent:FireClient(author, "Toast", { text = "🔥 FIRE from " .. (listener and listener.DisplayName or "a listener") .. ((cred or 0) > 0 and (" · " .. Format.SignedMoney(cred)) or "") })
	end
	return xp, cred
end

function M.Send(player, token)
	local NP = RS.OK.NowPlaying
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local prof = ctx.Data.GetProfile(player)
	local ownerId = NP:GetAttribute("OwnerId")
	local count, log = pairCount(prof, ownerId)
	local bpm = NP:GetAttribute("BPM") or 120
	local ok, why = M.Judge({ active = NP:GetAttribute("Active") == true, cypher = NP:GetAttribute("System") == true, token = NP:GetAttribute("Token"), ownerId = ownerId,
		startAt = NP:GetAttribute("StartAt") or 0, barLen = DAWCfg.Steps * 60 / bpm / 4, now = workspace:GetServerTimeNow(),
		fired = fired[NP:GetAttribute("Token")], pairCount = count },
		{ listenerId = player.UserId, token = token, dist = root and speakerDist(root.Position) or math.huge })
	if not ok then return { ok = false, reason = why } end
	log.given[tostring(ownerId)] = count + 1
	ctx.Data.MarkDirty(player)
	local xp = M.Give(player.UserId, player, ownerId, token)
	pcall(function() require(RS.OK.Systems.Funnel).Event(player, "FireGiven", 1) end)
	return { ok = true, xp = xp, fires = NP:GetAttribute("Fires") }
end

function M.Init(c)
	ctx = c
	RS.OK.Remotes.Fire_Send.OnServerInvoke = function(player, token) return M.Send(player, token) end
	local function onPlayer(p)
		task.spawn(function()
			local prof = ctx.Data.GetProfile(p)
			p:SetAttribute("FireTotal", tonumber(prof.fireTotal) or 0)
		end)
		local function onChar(char) Nameplate.Attach(char, p, M.Rank) end
		p.CharacterAdded:Connect(onChar)
		if p.Character then task.spawn(onChar, p.Character) end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in ipairs(Players:GetPlayers()) do onPlayer(p) end
	-- forget old airings' FIRE sets
	task.spawn(function()
		while true do
			task.wait(60)
			local cur = RS.OK.NowPlaying:GetAttribute("Token")
			for tok in pairs(fired) do if tok ~= cur then fired[tok] = nil end end
		end
	end)
end

return M
