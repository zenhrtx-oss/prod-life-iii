-- OK Studio CareerRules: the five career stats, their clamps, the prof.career defaults, the Career view of a profile,
-- the needs + money check every gate and stat-gated gear item uses, and the daily Aura heal's amount.
-- Pure: no Roblox globals and no other modules, so Studio and the luau CLI (spec/career_rules_spec.lua) load the same file.
local M = {}

-- the career stats in display and row order (Money lives in prof.cred, not here)
M.STATS = { "aura", "followers", "placements", "hits", "sponsors" }

-- a stat value as stored: whole (floored); Aura may go negative, every other stat stops at 0
function M.Clamp(stat, value)
	local v = math.floor(value)
	if stat == "aura" then return v end
	return math.max(0, v)
end

-- a fresh prof.career
function M.Defaults()
	return { aura = 0, followers = 0, placements = 0, hits = 0, sponsors = 0, sponsor = nil, showSponsor = true, gates = {}, careerLog = {} }
end

-- the Career a profile has: Money from prof.cred, the stats, the current sponsor, the TV toggle and owned gates (a copy)
function M.Have(prof)
	local c = prof.career or {}
	local have = { money = prof.cred or 0, sponsor = c.sponsor, showSponsor = c.showSponsor ~= false, gates = {} }
	for _, stat in ipairs(M.STATS) do have[stat] = c[stat] or 0 end
	for id, on in pairs(c.gates or {}) do have.gates[id] = on end
	return have
end

-- does `have` meet `needs` ({ [stat] = n }) and afford `cost`? rows follow STATS order, one per stat in needs
function M.Check(have, needs, cost)
	local rows, ok = {}, true
	for _, stat in ipairs(M.STATS) do
		local need = needs and needs[stat]
		if need then
			local got = have[stat] or 0
			local row = { stat = stat, need = need, have = got, ok = got >= need }
			ok = ok and row.ok
			table.insert(rows, row)
		end
	end
	local money = { need = cost or 0, have = have.money or 0 }
	money.ok = money.have >= money.need
	return { ok = ok and money.ok, rows = rows, money = money }
end

-- the daily Aura heal (Config.Career.Sources.AuraHeal): negative Aura moves up to `max` toward 0 and never past it;
-- 0 and above heal nothing
function M.HealAmount(aura, max)
	if aura < 0 then return math.min(max, -aura) end
	return 0
end

-- the cold spell (Wave 3): cold = { since, reason = "aura" | "quiet", news } or nil (warm). `event` is "check" (a moment to
-- look), or "fire" / "delivery3" (a 3-star delivery), which thaw; any other event changes nothing. Warm and checking:
-- Aura at or above cfg.rearmAura clears `rearm`; Aura under cfg.aura (and not `rearm`) goes cold "aura";
-- careerDay - lastDay reaching cfg.quietDays goes cold "quiet". Cold and checking stays cold (a `rearm` still clears at
-- rearmAura). A thaw acts even with lastDay nil. A thaw sets `rearm` when the spell was "aura" or when Aura is under
-- cfg.aura at that moment (Task 4 fix round 1, ruling C: a quiet spell that ends deep in the red can't re-chill "aura" on
-- the next check), so it can't re-chill by Aura until Aura has climbed to rearmAura; a check with lastDay nil changes
-- nothing.
-- The caller moves prof.sessions.lastDay after each step by LastDayStep (below); ColdStep never reads more than it is given.
-- Returns cold', rearm', changed; never changes `cold`
function M.ColdStep(cold, rearm, aura, careerDay, lastDay, event, cfg)
	if event == "fire" or event == "delivery3" then
		if not cold then return cold, rearm, false end
		return nil, rearm == true or cold.reason == "aura" or aura < cfg.aura, true
	end
	if event ~= "check" or lastDay == nil then return cold, rearm, false end
	local changed = false
	if rearm and aura >= cfg.rearmAura then rearm, changed = false, true end
	if cold then return cold, rearm, changed end
	if aura < cfg.aura and not rearm then
		return { since = careerDay, reason = "aura", news = false }, rearm, true
	end
	if careerDay - lastDay >= cfg.quietDays then
		return { since = careerDay, reason = "quiet", news = false }, rearm, true
	end
	return nil, rearm, changed
end

-- the cold spell's lastDay after one ColdStep (`thawed`: that step ended a spell). careerDay when the step found none (a
-- first read: the next check counts from today, and this one read none, so nobody is cold on a first read), on a thaw
-- (design 4.2 "on exit lastDay = exit day"; without it the next check re-chills "quiet"), and when the player was heard:
-- a FIRE to them ("fire") or a cypher win ("cypher"), warm or cold (Wave 3 final review I1, ruling A of 2026-11-12: the
-- quiet rule catches players nobody hears, and a FIRE or a win is being heard). A cypher win never thaws (ColdStep: any
-- other event changes nothing). Any other step keeps lastDay; a passed delivery sets it itself (Contracts.RecordDelivery).
-- Systems/Career.ColdCheck and CareerSim run it after every step
function M.LastDayStep(lastDay, careerDay, event, thawed)
	if lastDay == nil or thawed or event == "fire" or event == "cypher" then return careerDay end
	return lastDay
end

return M
