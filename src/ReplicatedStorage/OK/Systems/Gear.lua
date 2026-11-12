-- OK Studio system: the gear rack (tycoon-lite inside the one studio). Cred from session requests buys gear:
-- tools unlock beat-maker features (Roll FX = hat rolls, Swing Unit = swing; the 808 is free), looks change how you
-- show up (on-air neon colour, nameplate colour), fits are worn (kind "fit", one per slot). Rack tiers open with your
-- level (Config.Gear[i].level); an item with needs also wants career stats first (Modules/CareerRules.Check).
-- prof.gear = { [id] = true }, prof.equip = { neon = id, plate = id, [fit slot] = id } (key = it.slot or it.kind).
-- Player attributes (for the client): Gear = "808,rollfx", Unlocked = "Bass,Rolls", NeonColor / PlateColor (Color3 or nil),
-- Fits = "fit_cuban,fit_shades" (equipped fits).
-- Buying plate_legend reports "legend" to Systems/Life (ctx.Life in edit tests, the live module otherwise).
-- Equipped fits are built on the character (Modules/Fits, server-side so everyone sees them) by a Publish that changes
-- them (not by a neon or nameplate toggle) and again on every respawn (CharacterAdded, CharacterAppearanceLoaded).
-- Buying a look puts it on when its slot is empty. Gear_Equip from a client is rate limited (EQUIP_BURST calls, then one
-- per EQUIP_EVERY s; refused with reason "busy"), so a modified client can't make the server rebuild fits nonstop.
local RS, Players = game:GetService("ReplicatedStorage"), game:GetService("Players")
local Config = require(RS.OK.Config)
local Rules = require(RS.OK.Modules.CareerRules)
local Fits = require(RS.OK.Modules.Fits)
local M = { Enabled = true, Version = 1 }
local boughtEv = Instance.new("BindableEvent")
M.Bought = boughtEv.Event -- (player, item)
local ctx
local byId = {}
local function index() byId = {}; for _, it in ipairs(Config.Gear or {}) do byId[it.id] = it end end
index()
function M.Item(id) return byId[id] end
-- edit-mode tests: a fake ctx ({ Data = DataService copy }) and a fresh Config (rebuilds the id index)
function M._SetCtxForTest(c) ctx = c end
function M._SetConfigForTest(cfg) Config = cfg; index() end
local LOOKS = { neon = true, plate = true, fit = true } -- kinds you equip
local function slotOf(it) return it.slot or it.kind end
local EQUIP_EVERY, EQUIP_BURST = 0.25, 3 -- Gear_Equip from a client: a burst of 3, then at most 4 a second
local equipTokens = {} -- [player] = { n = calls left, at = os.clock() when n was counted }

local function state(prof)
	if type(prof.gear) ~= "table" then prof.gear = {} end
	if type(prof.equip) ~= "table" then prof.equip = {} end
	-- once per profile: tools a player already had by level before the rack existed stay theirs
	if not prof.gearV then
		prof.gearV = 1
		if (prof.level or 1) >= 3 then prof.gear.rollfx = true end
		if (prof.level or 1) >= 4 then prof.gear.swing = true end
	end
	return prof
end

function M.Owns(player, id)
	local it = byId[id]
	if not it then return false end
	if it.price == 0 then return true end
	return state(ctx.Data.GetProfile(player)).gear[id] == true
end
function M.Has(player, feature)
	for _, it in ipairs(Config.Gear or {}) do
		if it.feature == feature and M.Owns(player, it.id) then return true end
	end
	return false
end

-- the fits a player has on, in rack order: their gear ids (the Fits attribute) and their fit keys (Modules/Fits)
local function wornFits(player, prof)
	local ids, keys = {}, {}
	for _, it in ipairs(Config.Gear or {}) do
		if it.kind == "fit" and prof.equip[slotOf(it)] == it.id and M.Owns(player, it.id) then
			table.insert(ids, it.id); table.insert(keys, it.fit)
		end
	end
	return ids, keys
end
-- builds the worn fits on a character; a failure is reported, never thrown (it must not break a buy or an equip)
local function dress(player, character, keys)
	if not character then return end
	local ok, err = pcall(Fits.Apply, character, keys)
	if not ok then warn("[OK][ERR] fits for " .. tostring(player.Name) .. ": " .. tostring(err)) end
end

function M.Publish(player)
	if not player.Parent then return end
	local prof = state(ctx.Data.GetProfile(player))
	local owned, feats = {}, {}
	for _, it in ipairs(Config.Gear or {}) do
		if M.Owns(player, it.id) then
			table.insert(owned, it.id)
			if it.feature then table.insert(feats, it.feature) end
		end
	end
	local fitIds, fitKeys = wornFits(player, prof)
	player:SetAttribute("Gear", table.concat(owned, ","))
	player:SetAttribute("Unlocked", table.concat(feats, ","))
	local neon, plate = byId[prof.equip.neon], byId[prof.equip.plate]
	player:SetAttribute("NeonColor", neon and neon.color or nil)
	player:SetAttribute("PlateColor", plate and plate.color or nil)
	local fits = table.concat(fitIds, ",")
	local changed = fits ~= (player:GetAttribute("Fits") or "")
	player:SetAttribute("Fits", fits)
	if changed then dress(player, player.Character, fitKeys) end -- a respawn redresses on its own (Init)
end

function M.State(player)
	local prof = state(ctx.Data.GetProfile(player))
	local have = Rules.Have(prof)
	local items = {}
	for _, it in ipairs(Config.Gear or {}) do
		table.insert(items, { id = it.id, owned = M.Owns(player, it.id), equipped = prof.equip[slotOf(it)] == it.id,
			needs = it.needs, meets = Rules.Check(have, it.needs).ok })
	end
	return { items = items, cred = prof.cred or 0, level = prof.level or 1 }
end

-- returns { ok, reason = "invalid" | "owned" | "level" | "needs" | "cred", state }
function M.Buy(player, id)
	local it = type(id) == "string" and byId[id]
	if not it then return { ok = false, reason = "invalid" } end
	local prof = state(ctx.Data.GetProfile(player))
	if M.Owns(player, id) then return { ok = false, reason = "owned", state = M.State(player) } end
	if (prof.level or 1) < it.level then return { ok = false, reason = "level", state = M.State(player) } end
	if it.needs and not Rules.Check(Rules.Have(prof), it.needs).ok then return { ok = false, reason = "needs", state = M.State(player) } end
	if not ctx.Data.SpendCred(player, it.price) then return { ok = false, reason = "cred", state = M.State(player) } end
	prof.gear[id] = true
	if LOOKS[it.kind] then -- a new look goes on when nothing is in its slot (Publish below builds a fit)
		local slot = slotOf(it)
		if not prof.equip[slot] then prof.equip[slot] = id end
	end
	ctx.Data.MarkDirty(player)
	M.Publish(player)
	print(string.format("[OK] %s bought %s for $%d", player.Name, it.name, it.price))
	boughtEv:Fire(player, it)
	if id == "plate_legend" then pcall(function() (ctx.Life or require(RS.OK.Systems.Life)).Event(player, "legend") end) end -- never fails the buy
	return { ok = true, item = id, state = M.State(player) }
end

-- toggles a look you own: neon / nameplate colour (one each), or a fit (one per slot)
function M.Equip(player, id)
	local it = type(id) == "string" and byId[id]
	if not it or not LOOKS[it.kind] then return { ok = false, reason = "invalid" } end
	if not M.Owns(player, id) then return { ok = false, reason = "notowned" } end
	local prof = state(ctx.Data.GetProfile(player))
	local slot = slotOf(it)
	prof.equip[slot] = (prof.equip[slot] ~= id) and id or nil
	ctx.Data.MarkDirty(player)
	M.Publish(player)
	return { ok = true, state = M.State(player) }
end

-- the Gear tab opened for the player at the rack `inst` (the hub's GearRack panel or a room's RackSpot): its full name
-- is the panel's source, so the client closes the panel past Config.Interaction.PanelCloseDistance from it. The
-- GearRack handler, and Day One's card 3 ("Hit the gear rack", Systems/DayOne)
function M.OpenFor(player, inst)
	RS.OK.Remotes.InteractionEvent:FireClient(player, "OpenPanel", { tab = "Gear", source = inst:GetFullName(), profile = ctx.Data.ClientProfile(ctx.Data.GetProfile(player)), gear = M.State(player) })
end

-- may this player's client equip now? A token bucket: EQUIP_BURST calls, then one more every EQUIP_EVERY s
local function equipAllowed(player)
	local now = os.clock()
	local b = equipTokens[player]
	if not b then b = { n = EQUIP_BURST, at = now }; equipTokens[player] = b end
	b.n, b.at = math.min(EQUIP_BURST, b.n + (now - b.at) / EQUIP_EVERY), now
	if b.n < 1 then return false end
	b.n -= 1
	return true
end

function M.Init(c)
	ctx = c
	local R = RS.OK.Remotes
	R.Gear_Get.OnServerInvoke = function(player) return M.State(player) end
	R.Gear_Buy.OnServerInvoke = function(player, id) return M.Buy(player, id) end
	R.Gear_Equip.OnServerInvoke = function(player, id)
		if not equipAllowed(player) then return { ok = false, reason = "busy", state = M.State(player) } end
		return M.Equip(player, id)
	end
	c.Interaction.Register("GearRack", function(player, inst) M.OpenFor(player, inst) end)
	-- a new character gets the fits back once its head is in (body parts can follow CharacterAdded)
	local function redress(p, char)
		char:WaitForChild("Head", 5)
		if p.Character ~= char or not p.Parent then return end
		local _, keys = wornFits(p, state(ctx.Data.GetProfile(p)))
		dress(p, char, keys)
	end
	local function onJoin(p)
		p.CharacterAdded:Connect(function(char) task.spawn(redress, p, char) end)
		p.CharacterAppearanceLoaded:Connect(function(char) task.spawn(redress, p, char) end)
		task.spawn(function() ctx.Data.GetProfile(p); M.Publish(p) end)
	end
	Players.PlayerAdded:Connect(onJoin)
	Players.PlayerRemoving:Connect(function(p) equipTokens[p] = nil end)
	for _, p in ipairs(Players:GetPlayers()) do onJoin(p) end
end

return M
