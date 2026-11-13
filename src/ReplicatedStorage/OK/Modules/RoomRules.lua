-- OK Studio RoomRules (the Your Rooms plan, Task 1): the rules behind every player's own rooms. Plot origins and slot
-- claims, which rooms you own, a room's box in the world, the item grid (Cells, Centre, Fits), the save's repair on
-- load, item unlocks, plaques, speaker tiers, door access and modes, and poster designs. Pure: no Roblox globals and no
-- require; Config.Rooms (cfg), its Kinds rows (kindCfg), Data/RoomCatalog (catalog) and Config.Life.Tiers (tiers) come
-- in as arguments, so the server (Systems/Rooms), the client's decorate mode and the luau CLI
-- (spec/room_rules_spec.lua) run the same file.
--
-- Room-local coordinates have their origin on the floor at the room's centre, north -Z. The floor is a grid of 1-stud
--   cells: cell (cx, cz) covers [cx, cx+1) x [cz, cz+1). A grid or keep area is { x0, z0, x1, z1 } in room-local studs.
--   A floor item fits only where every one of its cells lies wholly inside some grid area and touches no keep area
--   (a strict, positive-area overlap: an area's edge on a cell line doesn't block the cell beside it).
-- A saved floor entry is { id = <catalog id>, x = cx, z = cz, r = 0..3 }: (x, z) is the lowest cell of its footprint
--   AFTER turning (an odd r swaps the item's w and d), and it covers cells x .. x+w-1, z .. z+d-1. A builder puts the
--   item's origin (its footprint's centre on the floor; parts face -Z) at Centre(item, entry) and turns it
--   CFrame.Angles(0, r * math.pi / 2, 0): +Y yaw, so r = 1 turns its front from -Z to -X.
-- A saved wall entry (a poster) is { id = "poster", slot = n, w = word, c = colour, s = style } (indices into
--   Config.Rooms.PosterWords, PosterColors, and 1..PosterStyles). Named fields only, never positional (preflight m8:
--   HttpService can't JSON-encode a mixed table).
-- prof.career.home = { v = 1, door = "open" | "friends" | "locked", items = { [kind] = { entry, ... } } }.
local R = {}

-- the door mode a junk or missing mode reads as; equals Config.Rooms.DoorDefault (the spec checks it)
R.DOOR_FALLBACK = "friends"

-- a whole number (finite, not NaN), the only kind of coordinate, turn or index the rules accept
local function isInt(v) return type(v) == "number" and v == v and v % 1 == 0 and v >= -1e6 and v <= 1e6 end
local function inRange(v, n) return isInt(v) and v >= 1 and v <= n end
local function tbl(v) return type(v) == "table" and v or nil end
-- a set from a set ({ [k] = true }) or a list ({ k, ... }) or both
local function asSet(v)
	local s = {}
	if type(v) ~= "table" then return s end
	for _, k in ipairs(v) do s[k] = true end
	for k, on in pairs(v) do if type(k) == "string" and on ~= nil and on ~= false then s[k] = true end end
	return s
end
local function contains(list, v)
	for _, x in ipairs(list) do if x == v then return true end end
	return false
end

-- plots ------------------------------------------------------------------------------------------------------------
-- slot k's plot origin (its landing's front door end): PlotOrigin + ((k-1) % PlotCols, (k-1) // PlotCols) * PlotSpacing
function R.PlotOrigin(k, cfg)
	local o, cols, gap = cfg.PlotOrigin, cfg.PlotCols, cfg.PlotSpacing
	return o[1] + ((k - 1) % cols) * gap, o[2], o[3] + ((k - 1) // cols) * gap
end

-- the lowest free slot in 1..n (slots[k] = the owner's user id, or nil when free; a freed slot leaves a hole), or nil
function R.Claim(slots, n)
	slots = tbl(slots) or {}
	for k = 1, n do
		if slots[k] == nil then return k end
	end
	return nil
end

-- the room kinds owned, in ladder order: every kind with no `gate` (the bedroom), plus each whose gate is held
-- (gates = prof.career.gates, { [gateId] = true }; kinds = Config.Rooms.Kinds)
function R.Owned(gates, kinds)
	gates = tbl(gates) or {}
	local list = {}
	for kind, k in pairs(kinds) do
		if k.gate == nil or (gates[k.gate] ~= nil and gates[k.gate] ~= false) then table.insert(list, kind) end
	end
	table.sort(list, function(a, b) return (kinds[a].order or 0) < (kinds[b].order or 0) end)
	return list
end

-- a room's interior in world studs, { x0, z0, x1, z1 }: slot k's plot origin + the kind's `at`, +- its size / 2; nil
-- for an unknown kind
function R.Box(kind, cfg, k)
	local kc = cfg.Kinds[kind]
	if not kc then return nil end
	local ox, _, oz = R.PlotOrigin(k, cfg)
	local x, z = ox + kc.at[1], oz + kc.at[2]
	local hw, hd = kc.size[1] / 2, kc.size[2] / 2
	return { x - hw, z - hd, x + hw, z + hd }
end

-- the item grid ----------------------------------------------------------------------------------------------------
-- the item's footprint after its turn, (w, d) in cells
local function turned(item, r)
	local w, d = item.size[1], item.size[2]
	if r % 2 == 1 then w, d = d, w end
	return w, d
end

-- the cells a floor entry covers, { { cx, cz }, ... } (rows north to south, each west to east); {} for a wall item or
-- an entry with junk coordinates or turn
function R.Cells(item, entry)
	local out = {}
	if type(item) ~= "table" or item.kind ~= "floor" or type(entry) ~= "table" then return out end
	local r = entry.r or 0
	if not isInt(entry.x) or not isInt(entry.z) or not isInt(r) or r < 0 or r > 3 then return out end
	local w, d = turned(item, r)
	for dz = 0, d - 1 do
		for dx = 0, w - 1 do table.insert(out, { entry.x + dx, entry.z + dz }) end
	end
	return out
end

-- the room-local centre (x, z) of a floor entry's footprint, where a builder puts the item's origin; nil for junk
function R.Centre(item, entry)
	if type(item) ~= "table" or item.kind ~= "floor" or type(entry) ~= "table" then return nil end
	local r = entry.r or 0
	if not isInt(entry.x) or not isInt(entry.z) or not isInt(r) or r < 0 or r > 3 then return nil end
	local w, d = turned(item, r)
	return entry.x + w / 2, entry.z + d / 2
end

-- an area's bounds, low to high; nil for a junk area
local function area(a)
	if type(a) ~= "table" then return nil end
	local x0, z0, x1, z1 = a[1], a[2], a[3], a[4]
	if type(x0) ~= "number" or type(z0) ~= "number" or type(x1) ~= "number" or type(z1) ~= "number" then return nil end
	return math.min(x0, x1), math.min(z0, z1), math.max(x0, x1), math.max(z0, z1)
end
-- is the cell wholly inside one of the grid's areas?
local function onGrid(cx, cz, grid)
	for _, a in ipairs(tbl(grid) or {}) do
		local x0, z0, x1, z1 = area(a)
		if x0 and cx >= x0 and cx + 1 <= x1 and cz >= z0 and cz + 1 <= z1 then return true end
	end
	return false
end
-- does the cell overlap (with positive area) any keep area?
local function inKeep(cx, cz, keep)
	for _, a in ipairs(tbl(keep) or {}) do
		local x0, z0, x1, z1 = area(a)
		if x0 and cx < x1 and cx + 1 > x0 and cz < z1 and cz + 1 > z0 then return true end
	end
	return false
end
-- may the item stand in this kind of room?
local function allowedIn(item, kind)
	return item.rooms == nil or contains(item.rooms, kind)
end
-- is the item open to this player? (an item with no unlock rule always is, whatever `unlocked` holds)
local function isOpen(item, unlocked)
	return item.unlock == nil or (type(unlocked) == "table" and unlocked[item.id] == true)
end

-- may `entry` go into `items` (the room's saved list) in a room of `kind` (kindCfg = Config.Rooms.Kinds[kind])?
-- -> true, or false and the reason, in this order of checks:
--   "unknown" (no such catalog id, or a junk entry), "locked" (an unlock rule not held), "room" (a kind the item isn't
--   allowed in, or no kindCfg), "max" (that many of this id already), "limit" (the room is full: posters count),
--   then for a floor item "rot" (r isn't a whole 0..3), "bounds" (junk coordinates, a cell off the grid or touching a
--   keep area), "overlap" (a cell another item covers); for a wall item "design" (PosterOk fails) and "slot" (outside
--   1..kindCfg.posters, or another poster hangs there).
-- An existing entry that is unknown, locked (Repair keeps those, unbuilt) or not allowed in this kind takes no cell or
-- slot and doesn't count; ignoreIndex (moving or redesigning items[ignoreIndex]) leaves that entry out of every check.
-- rooms = Config.Rooms (an argument past the plan's list: kindCfg has no poster words, colours or styles); without it
-- every wall item fails "design", so a caller that forgets it fails loudly.
-- held (R-T10 fix 1, the 11-12 unbuilt-cells ruling; optional, last) = more cells { { cx, cz }, ... } that count as taken
-- for a floor item ("overlap"): the cells of the room's entries Repair keeps unbuilt (UnbuiltCells), so a placement never
-- lands on an item that comes back once you own its gear again. They don't count toward the limit. Without it, as before.
function R.Fits(items, entry, kindCfg, catalog, unlocked, kind, ignoreIndex, rooms, held)
	if type(entry) ~= "table" or type(entry.id) ~= "string" then return false, "unknown" end
	local byId = type(catalog) == "table" and tbl(catalog.ById) or {}
	local item = byId[entry.id]
	if type(item) ~= "table" then return false, "unknown" end
	if not isOpen(item, unlocked) then return false, "locked" end
	if type(kindCfg) ~= "table" or not allowedIn(item, kind) then return false, "room" end
	-- the entries already in the room that count
	local others, count, same = {}, 0, 0
	for i, e in ipairs(tbl(items) or {}) do
		if i ~= ignoreIndex and type(e) == "table" and type(e.id) == "string" then
			local it = byId[e.id]
			if type(it) == "table" and isOpen(it, unlocked) and allowedIn(it, kind) then
				count += 1
				if e.id == entry.id then same += 1 end
				table.insert(others, { e = e, item = it })
			end
		end
	end
	if item.max ~= nil and same >= item.max then return false, "max" end
	if count >= (tonumber(kindCfg.limit) or 0) then return false, "limit" end
	if item.kind == "wall" then
		if not R.PosterOk(entry, rooms) then return false, "design" end
		if not inRange(entry.slot, tonumber(kindCfg.posters) or 0) then return false, "slot" end
		for _, o in ipairs(others) do
			if o.item.kind == "wall" and o.e.slot == entry.slot then return false, "slot" end
		end
		return true
	end
	local r = entry.r or 0
	if not isInt(r) or r < 0 or r > 3 then return false, "rot" end
	if not isInt(entry.x) or not isInt(entry.z) then return false, "bounds" end
	local cells = R.Cells(item, entry)
	for _, c in ipairs(cells) do
		if not onGrid(c[1], c[2], kindCfg.grid) or inKeep(c[1], c[2], kindCfg.keep) then return false, "bounds" end
	end
	local taken = {}
	for _, o in ipairs(others) do
		for _, c in ipairs(R.Cells(o.item, o.e)) do taken[c[1] .. ":" .. c[2]] = true end
	end
	for _, c in ipairs(tbl(held) or {}) do
		if type(c) == "table" and isInt(c[1]) and isInt(c[2]) then taken[c[1] .. ":" .. c[2]] = true end
	end
	for _, c in ipairs(cells) do
		if taken[c[1] .. ":" .. c[2]] then return false, "overlap" end
	end
	return true
end

-- the cells of the floor entries items[i] for every i in `indexes` (a list of indexes, or a set { [i] = true }), Fits'
-- `held`: Repair's unbuilt entries of one room (its `unbuilt` rows of that kind give the indexes). Unknown ids, wall items
-- and junk give no cell; skip (optional) is an index left out (an item being moved)
function R.UnbuiltCells(items, indexes, catalog, skip)
	local out = {}
	local byId = type(catalog) == "table" and tbl(catalog.ById) or {}
	local list = tbl(items) or {}
	local seen = {}
	for k, v in pairs(tbl(indexes) or {}) do
		local i = (type(k) == "number" and v == true) and k or v
		if isInt(i) and i ~= skip and not seen[i] then
			seen[i] = true
			local e = list[i]
			local item = type(e) == "table" and byId[e.id] or nil
			for _, c in ipairs(R.Cells(item, e)) do table.insert(out, c) end
		end
	end
	return out
end

-- the save's repair on load ----------------------------------------------------------------------------------------
-- a clean copy of a saved entry (named fields only), or nil and why: "malformed" (not a table, a non-string id, junk
-- coordinates or poster fields) or "unknown" (no such catalog id)
local function clean(e, byId)
	if type(e) ~= "table" or type(e.id) ~= "string" then return nil, "malformed" end
	local item = byId[e.id]
	if type(item) ~= "table" then return nil, "unknown" end
	if item.kind == "wall" then
		if type(e.slot) ~= "number" or type(e.w) ~= "number" or type(e.c) ~= "number" or type(e.s) ~= "number" then return nil, "malformed" end
		return { id = e.id, slot = e.slot, w = e.w, c = e.c, s = e.s }, item
	end
	if not isInt(e.x) or not isInt(e.z) or (e.r ~= nil and type(e.r) ~= "number") then return nil, "malformed" end
	return { id = e.id, x = e.x, z = e.z, r = e.r or 0 }, item
end
-- the checks that hang on the entry alone, never on ownership, unlocks or the room's other items: "room", "rot",
-- "design" (an entry failing one can never be built where it is)
local function standalone(entry, item, kind, rooms)
	if not allowedIn(item, kind) then return "room" end
	if item.kind == "wall" then
		if not R.PosterOk(entry, rooms) then return "design" end
	elseif not isInt(entry.r) or entry.r < 0 or entry.r > 3 then
		return "rot"
	end
	return nil
end

-- repair a saved home (preflight ruling R8): owned = the kinds you own (Owned's list, or a set); cfg = Config.Rooms;
-- unlocked = Unlocked's set. Returns a fresh home (the input is never changed), dropped and unbuilt.
-- * The junk goes, named in `dropped` as { kind?, index? (the input's key), field?, id?, reason }: a home that isn't a
--   table (field "home"), a junk door or items (field "door" / "items", the default comes back), a kind Config doesn't
--   know (field "items", reason "kind"), a kind's list that isn't a table (field "items"), and each malformed entry
--   (junk types, string or fractional coordinates), unknown id, or entry in a kind it isn't allowed in ("room"), with
--   a bad turn ("rot") or a bad poster design ("design").
-- * An entry in a room you don't own, or a locked one (its gear not owned, its first, tier or room not held), stays
--   in the home but isn't built: named in `unbuilt` as { kind, index (in the returned list), id, reason = "unowned" |
--   "locked" }. It takes no cell or slot, doesn't count toward the limit, and gets no geometry check, so a transient
--   read (Gear or Life not ready, gates read as {}) never deletes a placed item.
-- * Every other entry goes through Fits against the entries kept before it (list order wins): one that is out of
--   bounds, overlapping, over the limit or the max, or on a taken slot is dropped with Fits' reason. So an unbuilt item
--   that becomes buildable again rejoins on the next load, and whatever it then collides with later in the list goes.
-- Kinds are walked in ladder order (then the unknown ones, sorted), so both lists come out in a fixed order.
function R.Repair(home, owned, cfg, catalog, unlocked)
	local out = { v = 1, door = cfg.DoorDefault, items = {} }
	local dropped, unbuilt = {}, {}
	if home == nil then return out, dropped, unbuilt end
	if type(home) ~= "table" then
		table.insert(dropped, { field = "home", reason = "malformed" })
		return out, dropped, unbuilt
	end
	if home.door ~= nil then
		if contains(cfg.DoorModes, home.door) then out.door = home.door
		else table.insert(dropped, { field = "door", reason = "malformed" }) end
	end
	local items = home.items
	if items == nil then return out, dropped, unbuilt end
	if type(items) ~= "table" then
		table.insert(dropped, { field = "items", reason = "malformed" })
		return out, dropped, unbuilt
	end
	local byId = type(catalog) == "table" and tbl(catalog.ById) or {}
	local own = asSet(owned)
	local known, unknown = {}, {}
	for kind in pairs(items) do
		if type(kind) == "string" and cfg.Kinds[kind] then table.insert(known, kind) else table.insert(unknown, kind) end
	end
	table.sort(known, function(a, b) return (cfg.Kinds[a].order or 0) < (cfg.Kinds[b].order or 0) end)
	table.sort(unknown, function(a, b) return tostring(a) < tostring(b) end)
	for _, kind in ipairs(known) do
		local list, kc = items[kind], cfg.Kinds[kind]
		if type(list) ~= "table" then
			table.insert(dropped, { kind = kind, field = "items", reason = "malformed" })
		else
			local kept = {}
			local n = #list
			for i = 1, n do
				local raw = list[i]
				local e, item = clean(raw, byId)
				local reason = e == nil and item or standalone(e, item, kind, cfg)
				if reason == nil and not own[kind] then
					table.insert(kept, e)
					table.insert(unbuilt, { kind = kind, index = #kept, id = e.id, reason = "unowned" })
				elseif reason == nil and not isOpen(item, unlocked) then
					table.insert(kept, e)
					table.insert(unbuilt, { kind = kind, index = #kept, id = e.id, reason = "locked" })
				else
					if reason == nil then
						local fit, why = R.Fits(kept, e, kc, catalog, unlocked, kind, nil, cfg)
						if not fit then reason = why end
					end
					if reason == nil then
						table.insert(kept, e)
					else
						table.insert(dropped, { kind = kind, index = i, id = type(raw) == "table" and raw.id or nil, reason = reason })
					end
				end
			end
			-- anything outside the list's array part is junk too
			local extra = {}
			for key in pairs(list) do
				if not (isInt(key) and key >= 1 and key <= n) then table.insert(extra, key) end
			end
			table.sort(extra, function(a, b) return tostring(a) < tostring(b) end)
			for _, key in ipairs(extra) do
				local raw = list[key]
				table.insert(dropped, { kind = kind, index = key, id = type(raw) == "table" and raw.id or nil, reason = "malformed" })
			end
			if #kept > 0 then out.items[kind] = kept end
		end
	end
	for _, kind in ipairs(unknown) do
		table.insert(dropped, { kind = kind, field = "items", reason = "kind" })
	end
	return out, dropped, unbuilt
end

-- unlocks ------------------------------------------------------------------------------------------------------------
-- the catalog items open to a player, { [id] = true }. have = { gear = set (or list) of owned gear ids, firsts =
-- prof.life.firsts ({ [firstId] = career day | 0 }: a backfilled 0 counts), tier = the highest fame tier index reached,
-- rooms = the kinds owned (Owned's list, or a set) }. tiers = Config.Life.Tiers: an item's { tier = <tier id> } opens
-- when have.tier >= that id's index there (preflight m16); without tiers, or for an id it doesn't list, it stays shut.
-- Every key of an item's unlock rule must hold, and a rule with no key this knows stays shut; an item with no rule is
-- always open.
function R.Unlocked(catalog, have, tiers)
	have = tbl(have) or {}
	local gear, rooms, firsts = asSet(have.gear), asSet(have.rooms), tbl(have.firsts) or {}
	local tier = tonumber(have.tier) or 0
	local tierIndex = {}
	for i, t in ipairs(tbl(tiers) or {}) do
		if type(t) == "table" and t.id ~= nil then tierIndex[t.id] = i end
	end
	local out = {}
	for _, item in ipairs(type(catalog) == "table" and tbl(catalog.Items) or {}) do
		local rule, open = item.unlock, true
		if rule ~= nil then
			open = type(rule) == "table" and next(rule) ~= nil
			if open then
				for key, v in pairs(rule) do
					local holds = false
					if key == "gear" then holds = gear[v] == true
					elseif key == "first" then holds = firsts[v] ~= nil and firsts[v] ~= false
					elseif key == "tier" then holds = tierIndex[v] ~= nil and tier >= tierIndex[v]
					elseif key == "room" then holds = rooms[v] == true end
					if not holds then open = false end
				end
			end
		end
		if open then out[item.id] = true end
	end
	return out
end

-- plaques ------------------------------------------------------------------------------------------------------------
-- the plaques to hang, at most n, as { kind = "hit" | "placement" | "trackone" | "weekly", entry = the source row }:
-- the hits newest first, then the placements and track ones newest first, then the weekly singles newest first.
-- disco = prof.life.disco ({ d, kind, v, key }, oldest first); weekly = prof.plaques ({ w, t, a }, oldest first).
-- Newest = latest in its list (both lists only ever append). Junk rows and other disco kinds are skipped.
function R.Plaques(disco, weekly, n)
	n = tonumber(n) or 0
	local out = {}
	if n < 1 then return out end
	local hits, rest, weeks = {}, {}, {}
	local d = tbl(disco) or {}
	for i = #d, 1, -1 do
		local e = d[i]
		if type(e) == "table" then
			if e.kind == "hit" then table.insert(hits, { kind = "hit", entry = e })
			elseif e.kind == "placement" or e.kind == "trackone" then table.insert(rest, { kind = e.kind, entry = e }) end
		end
	end
	local w = tbl(weekly) or {}
	for i = #w, 1, -1 do
		if type(w[i]) == "table" then table.insert(weeks, { kind = "weekly", entry = w[i] }) end
	end
	for _, group in ipairs({ hits, rest, weeks }) do
		for _, p in ipairs(group) do
			if #out >= n then return out end
			table.insert(out, p)
		end
	end
	return out
end

-- speakers -----------------------------------------------------------------------------------------------------------
-- the speaker tier a player's gear gives (gear = { [gearId] = true }; speakers = Config.Rooms.Speakers): the highest
-- tier whose gear is owned or needs none, so at least 1 (the laptop's own speakers)
function R.SpeakerTier(gear, speakers)
	local owned = asSet(gear)
	local best = 1
	for i, s in ipairs(speakers) do
		if s.gear == nil or owned[s.gear] then best = i end
	end
	return best
end

-- doors --------------------------------------------------------------------------------------------------------------
-- may someone go in? The owner always; "open" admits anyone, "friends" only friends, "locked" only the owner. A junk
-- mode reads as "friends", and only isFriend == true is a friend (a friend check that errored or timed out is not)
function R.CanEnter(mode, isOwner, isFriend)
	if isOwner == true then return true end
	if mode == "open" then return true end
	if mode == "locked" then return false end
	return isFriend == true
end

-- the mode after `mode` in modes (Config.Rooms.DoorModes), wrapping; a junk mode moves to DOOR_FALLBACK
function R.NextDoorMode(mode, modes)
	for i, m in ipairs(modes) do
		if m == mode then return modes[i % #modes + 1] end
	end
	return R.DOOR_FALLBACK
end

-- posters ------------------------------------------------------------------------------------------------------------
-- is a poster design in range? design = { w, c, s } (a poster entry will do); cfg = Config.Rooms
function R.PosterOk(design, cfg)
	if type(design) ~= "table" or type(cfg) ~= "table" then return false end
	local words, colors = tbl(cfg.PosterWords), tbl(cfg.PosterColors)
	return inRange(design.w, words and #words or 0) and inRange(design.c, colors and #colors or 0)
		and inRange(design.s, tonumber(cfg.PosterStyles) or 0)
end

return R
