-- OK Studio system: Studio Tour (first session). Four skippable steps through the Studio Sessions loop:
-- open a beat maker, take the starter request, deliver it, put it on the monitors, buy your first gear.
-- Steps can be finished in any order; the tracker always points at the first one left.
-- Progress lives in the profile: prof.tour = { got = {credits=true, ...}, done = bool, skipped = bool, d1 = Day One's
-- saved state (Systems/DayOne writes it; this module never reads it) }.
-- The client gets "Tour" events { done, count, total, text, target } and highlights the target.
-- "monitors" counts when the beat goes on air or into the line, or the line is full, so a newcomer is never
-- stuck waiting for someone else's beat. Finishing pays a one-time +RewardXP; skipping pays nothing.
-- A room play (ON SPEAKERS at your own room's laptop, Systems/Rooms.Played; the Your Rooms plan, Task 7) counts for
-- "monitors" too, so a player who wakes up in their bedroom can finish the tour there.
-- Day One (the Day One plan, Task 2): the step texts are Data/DayOne's hub lines (Steps[id].hub), with {artist} filled at
-- load from the starter brief's artist (DayOneRules.Starter on Data/Artists' briefs: JUNO VALE), so no "{" ever reaches
-- the pill (ruling B2); a missing line, a token left unfilled or a module that fails to load falls back to the step's
-- pre-Day One words (reported when a module fails). M.Changed (player, what) fires after every write: the step id from Advance (after `done` is
-- written, ruling F4), then "done" when that step finished the tour; "skip" from Skip; "reset" from Reset. A third
-- argument is the server's os.clock() at the fire, so a listener whose handler runs late (deferred signals) can tell an
-- event from before its own state began. Systems/DayOne listens (it acts only on a chain it runs, ruling F3).
-- M.Finish(p) advances every missing step in order (card 3).
local RS, Players = game:GetService("ReplicatedStorage"), game:GetService("Players")
local DAW = require(RS.OK.Systems.DAW)
local Rooms = require(RS.OK.Systems.Rooms)
local Contracts = require(RS.OK.Systems.Contracts)
local Gear = require(RS.OK.Systems.Gear)
local Artists = require(RS.OK.Data.Artists)
local M = { Enabled = true, Version = 1 }
M.RewardXP = 50
local changedEv = Instance.new("BindableEvent")
M.Changed = changedEv.Event -- (player, what, at): a step id, "done", "skip" or "reset"; at = os.clock() at the fire
-- the words: Day One's rules and copy, loaded so a broken copy edit can't take Tour (and WalkIns and Phone, which require
-- it) down with it: reported, and the step falls back to its pre-Day One line (FALLBACK, the same words, filled)
local function loadWords(folder, name)
	local ok, res = pcall(function() return require(RS.OK[folder][name]) end)
	if ok and type(res) == "table" then return res end
	warn("[OK][ERR] tour: " .. folder .. "/" .. name .. " failed to load: " .. tostring(res))
	return nil
end
local DayOneRules = loadWords("Modules", "DayOneRules")
local DayOne = loadWords("Data", "DayOne")
local FALLBACK = {
	open = "Open the studio PC or a studio laptop", take = "Take the starter request from JUNO VALE",
	deliver = "Make every ask tick green, then press DELIVER", monitors = "Press ON MONITORS so the room hears it",
	gear = "Spend your money at the gear rack",
}
-- the starter brief's artist's name for {artist} (JUNO VALE); none (so the fallback) if Data/Artists has no single starter
local starter = DayOneRules and DayOneRules.Starter(Artists.Briefs)
local starterArtist = starter and Artists.ArtistById[starter.artist]
local WORDS = { artist = starterArtist and starterArtist.name or nil }
local function hub(id)
	local step = DayOne and type(DayOne.Steps) == "table" and DayOne.Steps[id]
	if not (DayOneRules and type(step) == "table" and type(step.hub) == "string") then return FALLBACK[id] end
	local text, left = DayOneRules.Fill(step.hub, WORDS)
	if left then return FALLBACK[id] end -- a token with no value: never a "{" on the pill (B2)
	return text
end
M.Steps = {
	{ id = "open",     text = hub("open"),     target = "Workspace.OKStudio.ControlRoom.Screen_Main" },
	{ id = "take",     text = hub("take"),     target = "Workspace.OKStudio.ControlRoom.Screen_Main" },
	{ id = "deliver",  text = hub("deliver"),  target = "Workspace.OKStudio.ControlRoom.Screen_Main" },
	{ id = "monitors", text = hub("monitors"), target = "Workspace.OKStudio.ControlRoom.Screen_Main" },
	{ id = "gear",     text = hub("gear"),     target = "Workspace.OKStudio.ControlRoom.GearRack.Panel" },
}
local ctx

local function state(prof)
	local t = prof.tour
	if type(t) ~= "table" then t = {}; prof.tour = t end
	if type(t.got) ~= "table" then t.got = {} end
	return t
end
local function current(t)
	local n = 0
	local first
	for _, s in ipairs(M.Steps) do
		if t.got[s.id] then n += 1 elseif not first then first = s end
	end
	return first, n
end
function M.State(player)
	local t = state(ctx.Data.GetProfile(player))
	local s, n = current(t)
	return { done = t.done == true, skipped = t.skipped == true, count = n, total = #M.Steps,
		text = s and s.text or "", target = s and s.target or "", step = s and s.id or "" }
end
local function send(player)
	if player.Parent then RS.OK.Remotes.InteractionEvent:FireClient(player, "Tour", M.State(player)) end
end
function M.Advance(player, id)
	local t = state(ctx.Data.GetProfile(player))
	if t.done or t.got[id] then return false end
	t.got[id] = true
	ctx.Data.MarkDirty(player)
	local s = current(t)
	if not s then
		t.done = true
		ctx.Data.GrantXP(player, M.RewardXP, "Tour")
		RS.OK.Remotes.InteractionEvent:FireClient(player, "Toast", { text = "Studio tour complete · +" .. M.RewardXP .. " XP" })
	end
	send(player)
	local at = os.clock()
	changedEv:Fire(player, id, at) -- after `done` is written (F4): a listener never sees all five got and not done
	if t.done then changedEv:Fire(player, "done", at) end
	return true
end
-- every missing step advanced in order (the last one finishes the tour and pays the reward once); Day One's card 3
function M.Finish(player)
	for _, s in ipairs(M.Steps) do M.Advance(player, s.id) end
end
function M.Skip(player)
	local t = state(ctx.Data.GetProfile(player))
	if t.done then return end
	t.done = true; t.skipped = true
	ctx.Data.MarkDirty(player)
	send(player)
	changedEv:Fire(player, "skip", os.clock())
end
function M.Reset(player) -- Studio test hook only (prof.tour.d1, Day One's saved state, goes with it)
	ctx.Data.GetProfile(player).tour = { got = {} }
	send(player)
	changedEv:Fire(player, "reset", os.clock())
end

function M.Init(c)
	ctx = c
	DAW.Opened:Connect(function(player) M.Advance(player, "open") end)
	Contracts.Picked:Connect(function(player) M.Advance(player, "take") end)
	Contracts.Delivered:Connect(function(player) M.Advance(player, "deliver") end)
	Gear.Bought:Connect(function(player) M.Advance(player, "gear") end)
	DAW.BroadcastTried:Connect(function(player, ok, reason)
		-- on air, already in line, or the line is full all count: a newcomer is never stuck waiting on others
		if ok or reason == "inline" or reason == "full" or reason == "cypher" then M.Advance(player, "monitors") end
	end)
	Rooms.Played:Connect(function(player) M.Advance(player, "monitors") end) -- your room's speakers (no BroadcastTried)
	RS.OK.Remotes.Tour_Skip.OnServerEvent:Connect(M.Skip)
	local function onJoin(p) task.spawn(function() ctx.Data.GetProfile(p); send(p) end) end
	Players.PlayerAdded:Connect(onJoin)
	for _, p in ipairs(Players:GetPlayers()) do onJoin(p) end
end

return M
