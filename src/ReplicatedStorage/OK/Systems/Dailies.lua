-- OK Studio system: daily requests + streak. Today's three (Modules/DailyRequests) join the session offers
-- (Systems/Contracts handles taking and delivering them). Each pays once a day (Config.Daily, x1.5 for 3 stars).
-- A delivery on consecutive UTC days grows the streak; a missed day resets it; streaks of 3 and 7 pay a Cred bonus.
-- prof.daily = { day = last day delivered (yyyymmdd), streak = n, done = { [dailyId] = stars } (today only) }
-- Weekly Single: prof.weekly = { week = n, stars = n } (this week's result); prof.plaques = { { w, t, a } } (3-star weeklies);
-- a plaque also feeds Aura and Followers (Config.Career.Sources.Plaque, Systems/Career)
local RS, Players = game:GetService("ReplicatedStorage"), game:GetService("Players")
local Config = require(RS.OK.Config)
local DR = require(RS.OK.Modules.DailyRequests)
local Format = require(RS.OK.Modules.Format)
local M = { Enabled = true, Version = 1 }
local ctx

function M.Today() return DR.Day(ctx and ctx.Data._now and ctx.Data._now() or os.time()) end
function M.ThisWeek() return DR.Week(ctx and ctx.Data._now and ctx.Data._now() or os.time()) end
local function state(prof)
	local d = prof.daily
	if type(d) ~= "table" then d = { streak = 0, done = {} }; prof.daily = d end
	if type(d.done) ~= "table" then d.done = {} end
	d.streak = tonumber(d.streak) or 0
	return d
end

-- pure streak step: returns the new streak after a delivery on `today`
function M.NextStreak(lastDay, streak, today)
	if lastDay == today then return math.max(streak, 1) end
	if lastDay and DR.PrevDay(today) == lastDay then return streak + 1 end
	return 1
end
-- the streak as it stands today (0 if the last delivery is older than yesterday)
function M.CurrentStreak(prof, today)
	local d = state(prof)
	if d.day == today or (d.day and DR.PrevDay(today) == d.day) then return d.streak end
	return 0
end

function M.Offers(player)
	local prof = ctx.Data.GetProfile(player)
	local d = state(prof)
	local out = {}
	for _, b in ipairs(DR.ForDay(M.Today())) do
		if not d.done[b.id] then table.insert(out, { id = b.id, daily = true }) end
	end
	return out
end

function M.WeeklyOffer(player)
	local prof = ctx.Data.GetProfile(player)
	local wk = M.ThisWeek()
	if type(prof.weekly) == "table" and prof.weekly.week == wk then return nil end
	return { id = "w" .. wk, weekly = true }
end

-- this week's single was delivered: pays once a week; 3 stars adds a plaque. returns firstThisWeek, xp, cred, plaque
function M.RecordWeekly(player, brief, stars)
	local prof = ctx.Data.GetProfile(player)
	local wk = M.ThisWeek()
	if type(prof.weekly) == "table" and prof.weekly.week == wk then return false, 0, 0, false end
	prof.weekly = { week = wk, stars = stars }
	local mult = stars >= 3 and 1.5 or 1
	local W = Config.Weekly or { XP = 50, Cred = 800 }
	local xp = ctx.Data.AddXP(player, math.floor(W.XP * mult + 0.5), "Weekly")
	local cred = ctx.Data.AddCred(player, math.floor(W.Cred * mult + 0.5), "Weekly")
	local plaque = false
	if stars >= 3 then
		if type(prof.plaques) ~= "table" then prof.plaques = {} end
		local Artists = require(RS.OK.Data.Artists)
		local a = Artists.ArtistById[brief.artist]
		table.insert(prof.plaques, { w = wk, t = brief.title, a = a and a.name or "" })
		while #prof.plaques > 52 do table.remove(prof.plaques, 1) end
		player:SetAttribute("Plaques", #prof.plaques)
		plaque = true
		local ok, err = pcall(function()
			local Career, feed = require(RS.OK.Systems.Career), Config.Career.Sources.Plaque
			Career.Add(player, "aura", feed.aura.amount, "Plaque")
			Career.Add(player, "followers", feed.followers.amount, "Plaque")
		end)
		if not ok then warn("[OK][ERR] career feed: " .. tostring(err)) end
		RS.OK.Remotes.InteractionEvent:FireClient(player, "Toast", { text = "🏆 Plaque: " .. brief.title .. " (Weekly Single)" })
	end
	ctx.Data.MarkDirty(player)
	return true, xp, cred, plaque
end

function M.Push(player)
	if not player.Parent then return end
	local prof = ctx.Data.GetProfile(player)
	local d = state(prof)
	local today = M.Today()
	local n = 0
	for _, b in ipairs(DR.ForDay(today)) do if d.done[b.id] then n += 1 end end
	RS.OK.Remotes.InteractionEvent:FireClient(player, "Daily", { count = n, total = DR.Count, streak = M.CurrentStreak(prof, today) })
end

-- a daily was delivered with `stars`: returns firstToday, xp, cred
function M.Record(player, brief, stars)
	local prof = ctx.Data.GetProfile(player)
	local d = state(prof)
	local today = M.Today()
	if d.done[brief.id] then return false, 0, 0 end
	for id in pairs(d.done) do if not id:find("^d" .. today .. "_") then d.done[id] = nil end end
	d.done[brief.id] = stars
	local before = M.CurrentStreak(prof, today)
	d.streak = M.NextStreak(d.day, d.streak, today)
	d.day = today
	local mult = stars >= 3 and 1.5 or 1
	local D = Config.Daily or { XP = 15, Cred = 200 }
	local xp = ctx.Data.AddXP(player, math.floor(D.XP * mult + 0.5), "Daily")
	local cred = ctx.Data.AddCred(player, math.floor(D.Cred * mult + 0.5), "Daily")
	local bonus = D.StreakBonus and D.StreakBonus[d.streak]
	if bonus and d.streak > before then
		local got = ctx.Data.AddCred(player, bonus, "Streak")
		if (got or 0) > 0 then RS.OK.Remotes.InteractionEvent:FireClient(player, "Toast", { text = string.format("%d-day streak! %s", d.streak, Format.SignedMoney(got)) }) end
	end
	if d.streak == 7 and d.streak > before then pcall(function() require(RS.OK.Systems.Life).Event(player, "streak7") end) end -- the day it reaches 7
	ctx.Data.MarkDirty(player)
	M.Push(player)
	return true, xp, cred
end

function M.Init(c)
	ctx = c
	local function onJoin(p) task.spawn(function()
		local prof = ctx.Data.GetProfile(p)
		p:SetAttribute("Plaques", type(prof.plaques) == "table" and #prof.plaques or 0)
		task.wait(1); M.Push(p)
	end) end
	Players.PlayerAdded:Connect(onJoin)
	for _, p in ipairs(Players:GetPlayers()) do onJoin(p) end
	-- a new UTC day: everyone's pill resets (count 0, streak as it stands today)
	task.spawn(function()
		local last = M.Today()
		while true do
			task.wait(15)
			local t = M.Today()
			if t ~= last then
				last = t
				for _, p in ipairs(Players:GetPlayers()) do task.spawn(M.Push, p) end
			end
		end
	end)
end

return M
