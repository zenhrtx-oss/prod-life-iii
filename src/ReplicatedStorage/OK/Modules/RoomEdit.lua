-- OK Studio RoomEdit (the Your Rooms plan, Task 9): the parts of placing your things that Systems/Rooms hands off, so
-- Rooms (already long) keeps only the doors, the plots, the saved home and the entry points Edit / State. Server side
-- in use, but nothing here touches a player's data or the world on its own: Systems/Rooms calls it with the saved home
-- and the room Model in hand.
-- * Take(p, edit): a per-player token bucket (Config.Rooms.Edit = { burst, every }): a player starts with `burst` tokens
--   and earns one back every `every` seconds, up to `burst`; every call takes one, a call finding none is refused.
--   Forget(p) drops a player's bucket (they left).
-- * Check(action): the client's action table type-checked and COPIED into one of ours (the client's table is never kept):
--   { op = "place" | "move" | "remove" | "poster", kind = string, id? (place), index? (move, remove: a whole number), x?, z?, r?
--   (place and move: numbers; r is quarter turns, RoomRules' scheme: 0..3, and nil means 0 for a place, the item's own turn for
--   a move), slot, w, c, s (poster, Task 13: whole numbers, the wall spot and the design's word, colour and style) }, or nil,
--   "invalid" for anything else. It checks types only: ranges, bounds, slots and designs are RoomRules.Fits' call.
-- * Apply(home, a, owned, unlocked, cfg, catalog): the checked action `a` on the saved home (prof.career.home; the one
--   table is changed in place, and only when the action is allowed). owned = the room kinds you own (Rules.Owned's list),
--   unlocked = Rules.Unlocked's set, cfg = Config.Rooms. Returns { ok = true, op, kind, index, item? } or { ok = false,
--   reason }, the reason being "room" (a kind you don't own, or none), "unknown" (a move or remove of an index nothing is
--   at: a stale view) or one of RoomRules.Fits' ("unknown" for an id, "locked", "room", "bounds", "overlap", "limit",
--   "max", "rot", "slot", "design"). A move leaves the item out of its own overlap check (ignoreIndex), so a rotation in
--   place is a move to the same cell with a new r. A remove closes the list (no hole) and drops an emptied list, as
--   Repair would. Entries are built from named fields only: { id, x, z, r }, a poster { id = "poster", slot, w, c, s }.
--   "poster" (Task 13) hangs a poster you designed on wall spot `slot`: the room's poster already on that slot, if any, is
--   replaced in place (a redesign: Fits leaves it out of every check, so a full room still takes it, and its index stays),
--   else a new entry goes at the end. The answer's op is "poster" and its index the entry's. "slot" then only means a spot
--   out of range (the op carries no index, so a taken spot is redesigned, never refused). unbuilt (optional, last; R-T10 fix 1, the 11-12
--   unbuilt-cells ruling) = Repair's `unbuilt` list: that room's entries kept unbuilt (locked) still hold their cells, so
--   a place or a move onto them is "overlap" (RoomRules.UnbuiltCells into Fits' `held`); removing one stays allowed.
-- * Fit(room, list, skip, catalog, cfg): makes the room's `Items` Folder (created once, attribute RoomItemsFolder) show
--   `list` (that room's saved entries): one RoomItems.Build model per built floor entry, named Item_<index>, attributes ItemId,
--   Index (its place in the saved list) and Sig (id:x:z:r), at Rules.Centre of its footprint turned r quarter turns about
--   +Y, so r = 1 turns its front from -Z to -X (RoomRules' scheme); and (Task 13) one RoomItems.Poster model per wall entry,
--   Item_<index> too (Sig id@slot:w:c:s, attribute Slot), pivoted onto the room's Poster_<slot> Attachment (found by name
--   like every anchor: an import's own, else Config's), so it hangs flush on the wall facing in. cfg = Config.Rooms (the
--   poster words, colours and styles); without it, or without the slot's anchor (reported), a poster isn't built.
--   skip = { [index] = true } for the entries that stay
--   unbuilt (locked ones: Repair keeps them in the save). A model already standing exactly as an entry says (same Sig) is
--   kept, so a remove, a move or a redesign rebuilds only what changed. Only models this made (ItemId and Sig) are ever
--   replaced or destroyed; anything else in the folder is left alone.
local RS = game:GetService("ReplicatedStorage")
local Rules = require(RS.OK.Modules.RoomRules)
local Items = require(RS.OK.Modules.RoomItems)

local E = {}

-- the token bucket -----------------------------------------------------------------------------------------------------
local buckets = {} -- [player] = { n = tokens, t = os.clock() at the last refill }

function E.Take(p, edit, now)
	local burst = tonumber(edit and edit.burst) or 5
	local every = tonumber(edit and edit.every) or 0.2
	now = now or os.clock()
	local b = buckets[p]
	if not b then
		b = { n = burst, t = now }
		buckets[p] = b
	end
	b.n = math.min(burst, b.n + (now - b.t) / every)
	b.t = now
	if b.n < 1 then return false end
	b.n -= 1
	return true
end

function E.Forget(p) buckets[p] = nil end

-- the action ---------------------------------------------------------------------------------------------------------------
local OPS = { place = true, move = true, remove = true, poster = true }
local POSTER_FIELDS = { "slot", "w", "c", "s" }
local function isInt(v) return type(v) == "number" and v == v and v % 1 == 0 and v >= -1e6 and v <= 1e6 end

function E.Check(action)
	if type(action) ~= "table" then return nil, "invalid" end
	local op, kind = action.op, action.kind
	if type(op) ~= "string" or OPS[op] ~= true or type(kind) ~= "string" or #kind > 24 then return nil, "invalid" end
	local a = { op = op, kind = kind }
	if op == "poster" then
		for _, f in ipairs(POSTER_FIELDS) do
			if not isInt(action[f]) then return nil, "invalid" end
			a[f] = action[f] + 0
		end
		return a
	end
	if op == "place" then
		if type(action.id) ~= "string" or #action.id > 32 then return nil, "invalid" end
		a.id = action.id
	else
		if not isInt(action.index) then return nil, "invalid" end
		a.index = action.index
	end
	if op ~= "remove" then
		local x, z, r = action.x, action.z, action.r
		if type(x) ~= "number" or type(z) ~= "number" or (r ~= nil and type(r) ~= "number") then return nil, "invalid" end
		a.x, a.z = x + 0, z + 0 -- + 0: a negative zero is saved as 0
		if r ~= nil then a.r = r + 0 end
	end
	return a
end

local function refuse(reason) return { ok = false, reason = reason } end
local function copyEntry(e)
	if e.slot ~= nil then return { id = e.id, slot = e.slot, w = e.w, c = e.c, s = e.s } end
	return { id = e.id, x = e.x, z = e.z, r = e.r }
end
-- the index of the wall entry (a poster) hanging on wall spot `slot` in `list`, or nil
local function wallAt(list, slot, catalog)
	for i, e in ipairs(list or {}) do
		local item = type(e) == "table" and catalog.ById[e.id] or nil
		if type(item) == "table" and item.kind == "wall" and e.slot == slot then return i end
	end
	return nil
end

function E.Apply(home, a, owned, unlocked, cfg, catalog, unbuilt)
	local kc = cfg.Kinds[a.kind]
	local mine = false
	for _, kind in ipairs(owned) do if kind == a.kind then mine = true; break end end
	if not (kc and mine) then return refuse("room") end
	local items = home.items
	local list = items[a.kind]
	-- the indexes of this room's entries Repair keeps unbuilt: their cells stay taken
	local idx = {}
	for _, u in ipairs(type(unbuilt) == "table" and unbuilt or {}) do
		if type(u) == "table" and u.kind == a.kind then table.insert(idx, u.index) end
	end
	if a.op == "poster" then
		local entry = { id = "poster", slot = a.slot, w = a.w, c = a.c, s = a.s }
		local at = wallAt(list, a.slot, catalog)
		local ok, why = Rules.Fits(list or {}, entry, kc, catalog, unlocked, a.kind, at, cfg)
		if not ok then return refuse(why) end
		if at then
			list[at] = entry
		else
			if not list then
				list = {}
				items[a.kind] = list
			end
			table.insert(list, entry)
			at = #list
		end
		return { ok = true, op = "poster", kind = a.kind, index = at, item = copyEntry(entry) }
	end
	if a.op == "place" then
		local entry = { id = a.id, x = a.x, z = a.z, r = a.r or 0 }
		local held = Rules.UnbuiltCells(list, idx, catalog)
		local ok, why = Rules.Fits(list or {}, entry, kc, catalog, unlocked, a.kind, nil, cfg, held)
		if not ok then return refuse(why) end
		if not list then
			list = {}
			items[a.kind] = list
		end
		table.insert(list, entry)
		return { ok = true, op = "place", kind = a.kind, index = #list, item = copyEntry(entry) }
	end
	local old = list and list[a.index]
	if type(old) ~= "table" then return refuse("unknown") end
	if a.op == "move" then
		local entry = { id = old.id, x = a.x, z = a.z, r = a.r ~= nil and a.r or old.r or 0 }
		local held = Rules.UnbuiltCells(list, idx, catalog, a.index)
		local ok, why = Rules.Fits(list, entry, kc, catalog, unlocked, a.kind, a.index, cfg, held)
		if not ok then return refuse(why) end
		list[a.index] = entry
		return { ok = true, op = "move", kind = a.kind, index = a.index, item = copyEntry(entry) }
	end
	table.remove(list, a.index)
	if #list == 0 then items[a.kind] = nil end
	return { ok = true, op = "remove", kind = a.kind, index = a.index }
end

-- the models ---------------------------------------------------------------------------------------------------------------
local MARK = "RoomItemsFolder"
local function folderOf(room)
	for _, c in ipairs(room:GetChildren()) do
		if c.Name == "Items" and c:IsA("Folder") and c:GetAttribute(MARK) == true then return c end
	end
	if room:FindFirstChild("Items") then
		warn("[OK][ERR] rooms: " .. room:GetFullName() .. " already has a child named Items that Rooms did not make")
	end
	local f = Instance.new("Folder")
	f.Name = "Items"
	f:SetAttribute(MARK, true)
	f.Parent = room
	return f
end

local function sig(e)
	if e.slot ~= nil then -- a wall entry: its spot and its design (two posters on two spots never share one)
		return tostring(e.id) .. "@" .. tostring(e.slot) .. ":" .. tostring(e.w) .. ":" .. tostring(e.c) .. ":" .. tostring(e.s)
	end
	return tostring(e.id) .. ":" .. tostring(e.x) .. ":" .. tostring(e.z) .. ":" .. tostring(e.r or 0)
end

-- a wall entry's model on its spot, unparented; nil without cfg, for a design RoomItems.Poster refuses, or for a spot whose
-- anchor the room lacks (reported: the asset contract names Poster_1..n)
local function posterFor(room, e, cfg)
	if type(cfg) ~= "table" then return nil end
	local a = room:FindFirstChild("Poster_" .. tostring(e.slot), true)
	if not (a and a:IsA("Attachment")) then
		warn("[OK][ERR] rooms: " .. room:GetFullName() .. " has no Poster_" .. tostring(e.slot) .. " anchor for a poster")
		return nil
	end
	local m = Items.Poster(e, cfg)
	if not m then return nil end
	m:PivotTo(a.WorldCFrame)
	m:SetAttribute("Sig", sig(e))
	m:SetAttribute("Slot", e.slot)
	return m
end

-- one entry's model at its cell (a floor item) or on its spot (a wall item), unparented; nil for an unknown id or junk
local function modelFor(room, e, catalog, cfg)
	local item = catalog.ById[e.id]
	if type(item) == "table" and item.kind == "wall" then return posterFor(room, e, cfg) end
	if type(item) ~= "table" or item.kind ~= "floor" then return nil end
	local cx, cz = Rules.Centre(item, e)
	if not cx then return nil end
	local m = Items.Build(e.id, catalog)
	if not m then return nil end
	m:PivotTo(room:GetPivot() * CFrame.new(cx, 0, cz) * CFrame.Angles(0, (e.r or 0) * math.pi / 2, 0))
	m:SetAttribute("Sig", sig(e))
	return m
end

function E.Fit(room, list, skip, catalog, cfg)
	local folder = folderOf(room)
	local have, stale = {}, {}
	for _, m in ipairs(folder:GetChildren()) do
		local s = m:IsA("Model") and m:GetAttribute("ItemId") ~= nil and m:GetAttribute("Sig") or nil
		if type(s) == "string" then
			if have[s] == nil then have[s] = m else table.insert(stale, m) end
		end
	end
	for i, e in ipairs(list or {}) do
		if not (skip and skip[i]) and type(e) == "table" and type(e.id) == "string" then
			local s = sig(e)
			local m = have[s]
			if m then have[s] = nil else m = modelFor(room, e, catalog, cfg) end
			if m then
				m.Name = "Item_" .. i
				m:SetAttribute("Index", i)
				m.Parent = folder
			end
		end
	end
	for _, m in pairs(have) do m:Destroy() end
	for _, m in ipairs(stale) do m:Destroy() end
	return folder
end

return E
