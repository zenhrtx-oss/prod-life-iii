-- OK Studio system: Studio Tour (first session). Four skippable steps through the Studio Sessions loop:
-- open a beat maker, take the starter request, deliver it, put it on the monitors, buy your first gear.
-- Steps can be finished in any order; the tracker always points at the first one left.
-- Progress lives in the profile: prof.tour = { got = {credits=true, ...}, done = bool, skipped = bool }.
-- The client gets "Tour" events { done, count, total, text, target } and highlights the target.
-- "monitors" counts when the beat goes on air or into the line, or the line is full, so a newcomer is never
-- stuck waiting for someone else's beat. Finishing pays a one-time +RewardXP; skipping pays nothing.
local RS, Players = game:GetService("ReplicatedStorage"), game:GetService("Players")
local DAW = require(RS.OK.Systems.DAW)
local Contracts = require(RS.OK.Systems.Contracts)
local Gear = require(RS.OK.Systems.Gear)
local M = { Enabled = true, Version = 1 }
M.RewardXP = 50
M.Steps = {
	{ id = "open",     text = "Open the studio PC or a studio laptop",          target = "Workspace.OKStudio.ControlRoom.Screen_Main" },
	{ id = "take",     text = "Take the starter request from JUNO VALE",        target = "Workspace.OKStudio.ControlRoom.Screen_Main" },
	{ id = "deliver",  text = "Make every ask tick green, then press DELIVER",  target = "Workspace.OKStudio.ControlRoom.Screen_Main" },
	{ id = "monitors", text = "Press ON MONITORS so the room hears it",         target = "Workspace.OKStudio.ControlRoom.Screen_Main" },
	{ id = "gear",     text = "Spend your money at the gear rack",              target = "Workspace.OKStudio.ControlRoom.GearRack.Panel" },
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
	return true
end
function M.Skip(player)
	local t = state(ctx.Data.GetProfile(player))
	if t.done then return end
	t.done = true; t.skipped = true
	ctx.Data.MarkDirty(player)
	send(player)
end
function M.Reset(player) -- Studio test hook only
	ctx.Data.GetProfile(player).tour = { got = {} }
	send(player)
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
	RS.OK.Remotes.Tour_Skip.OnServerEvent:Connect(M.Skip)
	local function onJoin(p) task.spawn(function() ctx.Data.GetProfile(p); send(p) end) end
	Players.PlayerAdded:Connect(onJoin)
	for _, p in ipairs(Players:GetPlayers()) do onJoin(p) end
end

return M
