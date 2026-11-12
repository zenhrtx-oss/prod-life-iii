-- OK Studio DayOneRules (the Day One plan, Task 1): the rules behind Day One, the opening chain of cards in your own
-- bedroom (JUNO VALE's beat request, then "play it on your speakers?", then "spend it?", then the first visitor at the
-- door). Which card comes next from the saved tour, the stale-card check at send time, the card a delivery queues, the
-- starter brief, the haggle and its one-time bonus, the first walk-in's hold, the loop's clock, the tool card 3 names,
-- the fills, the card payload and the saved d1's repair. Pure: no Roblox globals and no require; Config.DayOne (cfg),
-- Data/DayOne (data), Config.Gear and Data/Artists' briefs come in as arguments, so the server (Systems/DayOne) and the
-- luau CLI (spec/day_one_spec.lua) run the same file.
--
-- The saved tour is Systems/Tour's prof.tour = { got = { [step id] = true }, done, skipped, d1 }, its five steps open,
--   take, deliver, monitors, gear. d1 = { v = 1, haggle = "good" | "bad" | nil, paid = bool, private = bool } (Repair).
-- The chain is Systems/DayOne's per-player memory, never saved: { started, card = { token, id, at }?, pending = { id,
--   at, beat? }?, returnAt?, returned, room?, beat?, done }. Times are seconds on one clock (the server's os.clock);
--   card.id and pending.id are bare card ids ("dayone", "speakers", "spend"), as Next names them.
local M = {}

-- a finite number, else nil
local function num(v)
	if type(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge then return nil end
	return v
end
-- the tour's got set (junk reads as nothing got)
local function gotOf(tour)
	local g = type(tour) == "table" and tour.got or nil
	return type(g) == "table" and g or {}
end
-- a set from a set ({ [id] = true }) or a list ({ id, ... })
local function asSet(v)
	local s = {}
	if type(v) ~= "table" then return s end
	for _, k in ipairs(v) do s[k] = true end
	for k, on in pairs(v) do if type(k) == "string" and on then s[k] = true end end
	return s
end

-- the card the saved tour names: nil once the tour is done or skipped (either flag read as truthy, the way
-- Tour.Advance reads done, so no chain runs on a tour Tour won't advance); else the first missing of take -> "dayone",
-- deliver -> nil (you're making the beat), monitors -> "speakers", gear -> "spend", and with none of them missing (only
-- "open" can be, or a junk save) -> "spend" (preflight m2). "open" is never read. A junk tour reads as nothing got ->
-- "dayone".
function M.Next(tour)
	if type(tour) == "table" and (tour.done or tour.skipped) then return nil end
	local g = gotOf(tour)
	if not g.take then return "dayone" end
	if not g.deliver then return nil end
	if not g.monitors then return "speakers" end
	return "spend"
end

-- ruling B1: true when a queued or returned card `id` is no longer the card Next(tour) names. The server checks it at
-- send time (Due's "send" and "return") and drops a stale card unsent; a staged Show doesn't ask
function M.Stale(tour, id)
	return id ~= M.Next(tour)
end

-- ruling B3: the card a delivery queues, read after Tour has written "deliver" (Systems/DayOne advances it first, so
-- the connection order never matters): whatever Next names, "speakers" only from your own room's laptop
-- (`ownLaptop == true`), "spend" from anywhere (an old { take, monitors } save reaches "spend"); else nil
function M.Delivered(tour, ownLaptop)
	local n = M.Next(tour)
	if n == "spend" then return n end
	if n == "speakers" and ownLaptop == true then return n end
	return nil
end

-- the one brief with starter = true (Data/Artists' j1); two starters or none -> nil
function M.Starter(briefs)
	if type(briefs) ~= "table" then return nil end
	local found
	for _, b in ipairs(briefs) do
		if type(b) == "table" and b.starter == true then
			if found then return nil end
			found = b
		end
	end
	return found
end

-- "good" when roll * 100 < odds (roll in [0, 1), odds a percentage), else "bad"; junk reads as "bad"
function M.Haggle(roll, odds)
	local r, o = num(roll), num(odds)
	if r and o and r * 100 < o then return "good" end
	return "bad"
end

-- the haggle's bonus on a delivery: `amount` (Config.DayOne.HaggleBonus) only for a good haggle not yet paid, on the
-- starter brief's first delivery; else 0. The server pays it through GrantCred and then sets d1.paid
function M.Bonus(d1, briefId, starterId, first, amount)
	if type(d1) ~= "table" or d1.haggle ~= "good" or d1.paid == true then return 0 end
	if briefId == nil or briefId ~= starterId or first ~= true then return 0 end
	local n = num(amount)
	return (n and n > 0) and n or 0
end

-- true while Day One holds the first-ever walk-in (the DayOneBusy attribute): the chain isn't done, and a card is open
-- or queued, or fewer than cfg.HoldMax seconds have passed since the chain started
function M.Holds(chain, now, cfg)
	if type(chain) ~= "table" or chain.done then return false end
	if type(chain.card) == "table" or type(chain.pending) == "table" then return true end
	local t, s = num(now), num(chain.started)
	return (t ~= nil and s ~= nil and t - s < cfg.HoldMax)
end

-- what the loop does now, the first that holds:
--   "expire": the open card is at least cfg.CardSeconds old, or it is the returned card 1 and cfg.HoldMax has passed
--     since the chain started (a wanderer's first visit isn't held past ~90 s)
--   "send": the queued card is due (pending.at <= now), even over an open card: an open card that isn't Next any more
--     (card 2 left open after ON SPEAKERS) mustn't hold the next one back, so the server closes the open card first
--   "return": card 1 comes back (returnAt <= now, not yet returned) when its return leaves at least cfg.ReturnMin
--     seconds before HoldMax (started + HoldMax - returnAt >= ReturnMin; fix 1: no flash of a card), and only while
--     fewer than cfg.HoldMax seconds have passed since the chain started (ruling F1). A look pressed too late never
--     brings it back: the chain falls through to the first visitor at HoldMax
-- nil for a missing or done chain, or when nothing is due. Due never writes to the chain: the server's sender sets
-- chain.returned = true in the same step as it sends a "return" (else Due gives "return" again on every tick, and the
-- returned card 1 is never closed at HoldMax)
function M.Due(chain, now, cfg)
	if type(chain) ~= "table" or chain.done then return nil end
	local t = num(now)
	if not t then return nil end
	local started = num(chain.started)
	local card = type(chain.card) == "table" and chain.card or nil
	if card then
		local at = num(card.at)
		if at and t - at >= cfg.CardSeconds then return "expire" end
		if card.id == "dayone" and chain.returned == true and started and t - started >= cfg.HoldMax then return "expire" end
	end
	local pending = type(chain.pending) == "table" and chain.pending or nil
	local due = pending and num(pending.at)
	if due and due <= t then return "send" end
	local back = num(chain.returnAt)
	if back and back <= t and chain.returned ~= true and started and t - started < cfg.HoldMax
		and started + cfg.HoldMax - back >= cfg.ReturnMin then
		return "return"
	end
	return nil
end

-- the tool card 3 names: the cheapest row of `gear` (Config.Gear) with a `feature`, a price above 0 (ruling F2: a
-- price-0 row is everyone's, as Gear.Owns has it), no `needs` (fix 1: Gear.Buy would refuse a player short of them),
-- not in `owned` (prof.gear: a set, or a list of ids), price <= money and level <= level; the first such row on a tie;
-- nil when none. DayOneFloor's buying rule
function M.Tool(gear, owned, money, level)
	if type(gear) ~= "table" then return nil end
	local have, cash, lv = asSet(owned), num(money) or 0, num(level) or 1
	local best
	for _, row in ipairs(gear) do
		local price = type(row) == "table" and num(row.price) or nil
		if price and price > 0 and type(row.feature) == "string" and row.needs == nil and not have[row.id] and price <= cash
			and (num(row.level) or 1) <= lv and (not best or price < best.price) then
			best = row
		end
	end
	return best
end

-- every {token} (letters and digits) filled from vars (a function replacement, so a "%" in a value stays); `left` is
-- true when a token had no value and stays. Anything else in braces, such as a walk-in's {name:<id>}, passes through
-- untouched and doesn't count. Junk text reads as ""
function M.Fill(text, vars)
	if type(text) ~= "string" then return "", false end
	local left = false
	local out = string.gsub(text, "{(%w+)}", function(k)
		local v = type(vars) == "table" and vars[k] or nil
		if v == nil then
			left = true
			return nil
		end
		return tostring(v)
	end)
	return out, left
end

-- the "arrive" payload for card `id` of Data/DayOne (`data`), every text filled from vars:
--   { token = nil (the server sets it), source = "dayone", header = data.Header, walk = data.Skip, now = card.now,
--     card = { id = "day1_" .. id, visitor = { id?, name, style, color? }, tag, line, choices = { { text } } } }
-- vars holds the copy's tokens, plus two that aren't: artistId (the starter brief's artist, "juno") and color (her
-- Data/Artists colour as { r, g, b } 0-255). A `face` card puts both on its visitor, so VisitorFigure draws a generic
-- figure in her colour; other cards have neither. visitor.style repeats the tag (WalkInUI shows the tag). "spend" uses
-- lines.tool when vars has a tool, else lines.none. nil for an unknown id
function M.Card(id, data, vars)
	local cards = type(data) == "table" and type(data.Cards) == "table" and data.Cards or nil
	local c = cards and cards[id]
	if type(c) ~= "table" then return nil end
	vars = type(vars) == "table" and vars or {}
	local function fill(s) return (M.Fill(s, vars)) end
	local line = c.line
	if type(c.lines) == "table" then line = vars.tool ~= nil and c.lines.tool or c.lines.none end
	local choices = {}
	for i, ch in ipairs(type(c.choices) == "table" and c.choices or {}) do choices[i] = { text = fill(ch.text) } end
	local tag = fill(c.tag)
	local visitor = { name = fill(c.name), style = tag }
	if c.face == true then
		visitor.id = type(vars.artistId) == "string" and vars.artistId or nil
		local col = vars.color
		if type(col) == "table" and num(col[1]) and num(col[2]) and num(col[3]) then visitor.color = { col[1], col[2], col[3] } end
	end
	return { source = "dayone", header = fill(data.Header), walk = fill(data.Skip), now = c.now == true,
		card = { id = "day1_" .. tostring(id), visitor = visitor, tag = tag, line = fill(line), choices = choices } }
end

-- the saved d1 made whole: { v = 1, haggle = "good" | "bad" | nil, paid = bool, private = bool }, a fresh table with
-- named fields only (unknown keys dropped); junk reads as nothing haggled, nothing paid
function M.Repair(d1)
	local t = type(d1) == "table" and d1 or {}
	local haggle = (t.haggle == "good" or t.haggle == "bad") and t.haggle or nil
	return { v = 1, haggle = haggle, paid = t.paid == true, private = t.private == true }
end

return M
