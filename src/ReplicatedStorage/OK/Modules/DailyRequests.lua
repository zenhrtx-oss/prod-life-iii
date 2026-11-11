-- Studio Sessions daily requests: 3 a UTC day, picked from fixed templates by the date alone, so every server (and the
-- client) builds the same three. Dailies need no gear (anyone can do them). Ids are "d<yyyymmdd>_<n>".
-- Weekly Single: one harder request a UTC week (weeks since 1970-01-01, a Thursday), id "w<week>"; 3 stars earns a plaque.
local RS = game:GetService("ReplicatedStorage")
local M = {}
M.Count = 3
local KICK1 = { k = "on", track = "Kick", steps = { 1 } }
local OFFHATS = { k = "on", track = "Hat", steps = { 3, 7, 11, 15 } }
M.Templates = {
	{ asks = { { k = "bpm", min = 130, max = 150 }, KICK1, { k = "min", track = "Hat", n = 8 } }, bonus = { k = "backbeat" } },
	{ asks = { { k = "bpm", min = 90, max = 110 }, { k = "backbeat" }, { k = "min", track = "Kick", n = 5 } }, bonus = OFFHATS },
	{ asks = { { k = "bpm", min = 150, max = 170 }, { k = "min", track = "Clap", n = 2 }, OFFHATS }, bonus = KICK1 },
	{ asks = { { k = "bpm", min = 70, max = 90 }, { k = "backbeat" }, { k = "max", track = "Kick", n = 3 } }, bonus = { k = "max", track = "Clap", n = 0 } },
	{ asks = { { k = "bpm", min = 140, max = 150 }, { k = "on", track = "Snare", steps = { 9 } }, { k = "max", track = "Clap", n = 0 } }, bonus = { k = "min", track = "Hat", n = 12 } },
	{ asks = { { k = "bpm", min = 120, max = 140 }, KICK1, { k = "min", track = "Clap", n = 4 } }, bonus = { k = "min", track = "Hat", n = 8 } },
	{ asks = { { k = "bpm", min = 160, max = 180 }, { k = "min", track = "Hat", n = 12 }, { k = "backbeat" } }, bonus = { k = "max", track = "Kick", n = 3 } },
	{ asks = { { k = "bpm", min = 100, max = 120 }, OFFHATS, { k = "max", track = "Kick", n = 4 } }, bonus = { k = "backbeat" } },
	{ asks = { { k = "bpm", min = 120, max = 140 }, { k = "backbeat" }, { k = "melody", n = 4 } }, bonus = { k = "melnotes", n = 3 } }, -- keys (piano roll), from 2026-10-23
}
-- ids are seeded by the date, so a template added later must not remap days already generated: gate it by date
function M.TemplateCount(day) return day >= 20261023 and #M.Templates or 8 end
M.Titles = { "Morning Shift", "Daily Grind", "Night Bus", "Coffee Run", "Rooftop", "Late Check-in", "Neon Walk",
	"Street Lights", "Quick Sketch", "Warm Up", "Fresh Pads", "Studio Loop" }
M.ArtistIds = { "juno", "tavi" }

function M.Day(t) return tonumber(os.date("!%Y%m%d", t)) end
function M.PrevDay(day)
	local y, m, d = math.floor(day / 10000), math.floor(day / 100) % 100, day % 100
	return tonumber(os.date("!%Y%m%d", os.time({ year = y, month = m, day = d, hour = 12 }) - 86400))
end

local cache = {}
function M.ForDay(day)
	if cache[day] then return cache[day] end
	local Config = require(RS.OK.Config)
	local D = Config.Daily or { XP = 15, Cred = 200 }
	local s = (day * 7919 + 17) % 2147483647
	if s == 0 then s = 1 end
	local function rnd() s = (s * 48271) % 2147483647; return s end
	local guard = 0
	local tpls, titles, out = {}, {}, {}
	while #out < M.Count do
		guard += 1
		assert(guard < 1000, "daily generator stuck")
		local ti = rnd() % M.TemplateCount(day) + 1
		if not tpls[ti] then
			tpls[ti] = true
			local title
			repeat title = M.Titles[rnd() % #M.Titles + 1] until not titles[title]
			titles[title] = true
			local i = #out + 1
			local t = M.Templates[ti]
			table.insert(out, { id = string.format("d%d_%d", day, i), artist = M.ArtistIds[(day + i) % #M.ArtistIds + 1], title = title,
				daily = true, template = ti, reward = { xp = D.XP, cred = D.Cred }, asks = t.asks, bonus = t.bonus })
		end
	end
	cache[day] = out
	return out
end

-- the Weekly Single ------------------------------------------------------------------
M.WeeklyTemplates = {
	{ asks = { { k = "bpm", min = 140, max = 145 }, KICK1, { k = "on", track = "Snare", steps = { 9 } } }, bonus = { k = "min", track = "Hat", n = 12 } },
	{ asks = { { k = "bpm", min = 95, max = 100 }, { k = "backbeat" }, { k = "min", track = "Kick", n = 6 } }, bonus = OFFHATS },
	{ asks = { { k = "bpm", min = 160, max = 165 }, OFFHATS, { k = "min", track = "Clap", n = 4 } }, bonus = { k = "max", track = "Kick", n = 2 } },
	{ asks = { { k = "bpm", min = 75, max = 80 }, { k = "backbeat" }, { k = "max", track = "Kick", n = 2 } }, bonus = { k = "min", track = "Hat", n = 8 } },
	{ asks = { { k = "bpm", min = 125, max = 130 }, KICK1, { k = "min", track = "Hat", n = 16 } }, bonus = { k = "max", track = "Clap", n = 0 } },
	{ asks = { { k = "bpm", min = 150, max = 155 }, { k = "max", track = "Clap", n = 0 }, { k = "min", track = "Snare", n = 4 } }, bonus = KICK1 },
	{ asks = { { k = "bpm", min = 85, max = 90 }, { k = "backbeat" }, { k = "melody", n = 6 } }, bonus = { k = "chord" } }, -- keys (piano roll), from week 2965
}
function M.WeeklyCount(week) return week >= 2965 and #M.WeeklyTemplates or 6 end -- same date gate as TemplateCount
M.WeeklyTitles = { "Headline", "Main Stage", "Radio Edit", "Lead Track", "Night Drive", "Gold Tape", "Big Room", "Encore" }
function M.Week(t) return math.floor(math.floor(t / 86400) / 7) end
local weekCache = {}
function M.ForWeek(week)
	if weekCache[week] then return weekCache[week] end
	local Config = require(RS.OK.Config)
	local W = Config.Weekly or { XP = 50, Cred = 800 }
	local ti = week % M.WeeklyCount(week) + 1
	local t = M.WeeklyTemplates[ti]
	local b = { id = "w" .. week, artist = M.ArtistIds[week % #M.ArtistIds + 1], title = M.WeeklyTitles[(week * 3) % #M.WeeklyTitles + 1],
		weekly = true, template = ti, reward = { xp = W.XP, cred = W.Cred }, asks = t.asks, bonus = t.bonus }
	weekCache[week] = b
	return b
end

function M.Brief(id)
	if type(id) ~= "string" then return nil end
	local wk = id:match("^w(%d%d%d%d)$") -- 4-digit week numbers only (weeks since 1970: 2913 in 2026)
	if wk then return M.ForWeek(tonumber(wk)) end
	local day, i = id:match("^d(%d%d%d%d%d%d%d%d)_([1-3])$") -- yyyymmdd only: keeps the seed exact and non-zero
	if not day then return nil end
	return M.ForDay(tonumber(day))[tonumber(i)]
end

-- a BriefById that also knows the dailies
function M.Index(Artists)
	return setmetatable({}, { __index = function(_, id) return Artists.BriefById[id] or M.Brief(id) end })
end

return M
