local R = require("./WalkInRules"); local W = require("./WalkIns"); local Cfg = require("./Config"); local CR = require("./CareerRules")
local P = require("./profs")
local O = Cfg.WalkIns.Odds
local out = {}
for pi, p in ipairs(P) do
	local career = { money=p.money, aura=p.aura, followers=p.followers, placements=p.placements, hits=p.hits, sponsors=p.sponsors, level=p.level, visits=p.visits }
	local beat = p.stars ~= nil and { stars=p.stars, fires=p.fires } or nil
	local bq = R.BeatQuality(beat)
	for _, list in ipairs({ W.Cards, W.Followups }) do for _, c in ipairs(list) do
		local phone = c.source == "phone"
		local parts = { c.id, R.GateOk(c, career, p.visits, p.rel) and "1" or "0" }
		for _, ch in ipairs(c.choices or {}) do
			local tilt = 0
			if not phone then local e = p.rel[c.visitor]; tilt += R.RelTilt(e and e.score or 0, O) end
			if ch.beat then tilt += R.BeatTilt(bq, O) end
			table.insert(parts, tostring(R.RollChance(ch, career, O, tilt, bq)))
		end
		if c.resolve then table.insert(parts, "n" .. R.Chance(c.resolve.odds or 50, career, O)) end
		table.insert(out, pi .. ":" .. table.concat(parts, ","))
	end end
end
-- cold step table
for _, a in ipairs({-80,-51,-50,-30,-25,0}) do for _, gap in ipairs({0,2,3}) do for _, rearm in ipairs({false,true}) do for _, cold in ipairs({"n","aura","quiet"}) do for _, e in ipairs({"check","fire","delivery3"}) do
	local c0 = cold ~= "n" and { since=1, reason=cold } or nil
	local c, r, ch = CR.ColdStep(c0, rearm, a, 5, 5-gap, e, Cfg.WalkIns.Cold)
	table.insert(out, ("cold:%d,%d,%s,%s,%s=%s,%s,%s"):format(a,gap,tostring(rearm),cold,e, c and c.reason or "n", tostring(r), tostring(ch)))
end end end end end
print(table.concat(out, "\n"))
