-- OK Studio system: public producer cards. Walk up to another producer and press G (prompt on their character) to
-- see their card; Card_Get(userId) returns the same thing. A card holds ONLY the public fields in M.PUBLIC, built
-- here from game data (no player-typed text exists anywhere); ProfileFunction still returns only your own profile.
local RS, Players = game:GetService("ReplicatedStorage"), game:GetService("Players")
local Config = require(RS.OK.Config)
local LifeRules = require(RS.OK.Modules.LifeRules)
local M = { Enabled = true, Version = 1 }
M.PUBLIC = { "name", "level", "rank", "fires", "flips", "deliveries", "streak", "credits", "recent", "plaques", "plaqueCount", "userId",
	"aura", "followers", "placements", "hits", "sponsors", -- career stats (Systems/Career); never Money or the sponsor deal
	"year", "tier", "title", "ribbons" } -- from prof.life (Systems/Life); ribbons = ids in Config.Life.Ribbons order; never the story
local ctx
-- Edit-mode tests: a fresh Config and LifeRules, because a clone's require returns the copy cached before a sync
function M._SetConfigForTest(c, rules) Config = c; LifeRules = rules or LifeRules end

-- pure: the public card from a profile (also used by tests with fake profiles)
function M.CardFrom(prof, displayName, userId, streak)
	local credits = type(prof.credits) == "table" and prof.credits or {}
	local recent = {}
	for i = #credits, math.max(1, #credits - 2), -1 do
		local c = credits[i]
		table.insert(recent, { t = tostring(c.t or ""), a = tostring(c.a or ""), s = tonumber(c.s) or 0 })
	end
	local plaques = {}
	local pl = type(prof.plaques) == "table" and prof.plaques or {}
	for i = #pl, math.max(1, #pl - 4), -1 do table.insert(plaques, { t = tostring(pl[i].t or ""), a = tostring(pl[i].a or "") }) end
	local level = tonumber(prof.level) or 1
	local career = type(prof.career) == "table" and prof.career or {}
	local pub = LifeRules.Public(prof.life, Config.Life) -- a profile with no life reads as a new one
	return {
		userId = userId, name = displayName, level = level, rank = (Config.Ranks and Config.Ranks[level]) or "",
		fires = tonumber(prof.fireTotal) or 0, flips = tonumber(prof.flipsReceived) or 0,
		deliveries = type(prof.sessions) == "table" and tonumber(prof.sessions.deliveries) or 0, streak = streak or 0,
		credits = #credits, recent = recent, plaques = plaques, plaqueCount = #pl,
		aura = tonumber(career.aura) or 0, followers = tonumber(career.followers) or 0, placements = tonumber(career.placements) or 0,
		hits = tonumber(career.hits) or 0, sponsors = tonumber(career.sponsors) or 0,
		year = pub.year, tier = pub.tier, title = pub.title, ribbons = pub.ribbons,
	}
end

function M.Card(target)
	local prof = ctx.Data.GetProfile(target)
	local Dailies = require(RS.OK.Systems.Dailies)
	return M.CardFrom(prof, target.DisplayName, target.UserId, Dailies.CurrentStreak(prof, Dailies.Today()))
end

local function attachPrompt(char, owner)
	local root = char:WaitForChild("HumanoidRootPart", 10)
	if not root then return end
	local old = root:FindFirstChild("OK_CardPrompt"); if old then old:Destroy() end
	local p = Instance.new("ProximityPrompt")
	p.Name = "OK_CardPrompt"; p.ActionText = "View card"; p.ObjectText = owner.DisplayName
	p.KeyboardKeyCode = Enum.KeyCode.G; p.GamepadKeyCode = Enum.KeyCode.DPadUp
	p.MaxActivationDistance = 8; p.HoldDuration = 0; p.RequiresLineOfSight = false
	p.Parent = root
	p.Triggered:Connect(function(viewer)
		if viewer == owner or not owner.Parent then return end
		local okG, gear = pcall(function() return require(RS.OK.Systems.Gear).State(viewer) end)
		RS.OK.Remotes.InteractionEvent:FireClient(viewer, "OpenPanel", { tab = "Card", card = M.Card(owner),
			profile = ctx.Data.ClientProfile(ctx.Data.GetProfile(viewer)), gear = okG and gear or nil }) -- your own tabs stay right
	end)
end

function M.Init(c)
	ctx = c
	RS.OK.Remotes.Card_Get.OnServerInvoke = function(player, userId)
		local target = type(userId) == "number" and Players:GetPlayerByUserId(userId) or nil
		if not target then return { ok = false, reason = "notfound" } end
		return { ok = true, card = M.Card(target) }
	end
	local function onPlayer(p)
		p.CharacterAdded:Connect(function(ch) attachPrompt(ch, p) end)
		if p.Character then task.spawn(attachPrompt, p.Character, p) end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in ipairs(Players:GetPlayers()) do onPlayer(p) end
end

return M
