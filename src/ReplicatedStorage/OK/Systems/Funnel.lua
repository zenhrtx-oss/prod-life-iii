-- OK Studio system: drop-off funnel. Logs where new players stop, through AnalyticsService's onboarding funnel:
-- each step once per player EVER (prof.funnel remembers logged steps across sessions). Plus a few custom events
-- (deliveries, FIRE, flips, cypher entries, and the card telemetry: CardChoice, CardWalkAway, CardNews, CardExpire,
-- CardNote, PhoneOpen, PhoneExpire, whose fields carry the source, the card id and a detail). Analytics never breaks
-- gameplay: every call is wrapped in pcall. Analytics reports only from a published place, so in Studio every event
-- is also printed ("[OK] telemetry ...") and kept in M._events.
local RS, Players = game:GetService("ReplicatedStorage"), game:GetService("Players")
local Analytics = game:GetService("AnalyticsService")
local STUDIO = game:GetService("RunService"):IsStudio()
local M = { Enabled = true, Version = 1 }
M.Steps = { "Joined", "Used something", "Opened a beat maker", "Took a request", "Delivered a request", "Played on the monitors", "Bought gear" }
M._log = {} -- { { uid, step } } this server session (tests read it through the Studio hook)
M._events = {} -- Studio only: { { uid, name, value, fields } } this session, oldest first (_StudioTestHook FunnelEvents)
local FIELDS = { -- an event's fields -> AnalyticsService's three custom fields (string values)
	{ "source", Enum.AnalyticsCustomFieldKeys.CustomField01.Name },
	{ "card", Enum.AnalyticsCustomFieldKeys.CustomField02.Name },
	{ "detail", Enum.AnalyticsCustomFieldKeys.CustomField03.Name },
}
local ctx

function M.Step(player, n)
	if typeof(player) ~= "Instance" or not player.Parent or not M.Steps[n] then return false end
	local prof = ctx.Data.GetProfile(player)
	if prof._detached then return false end
	if type(prof.funnel) ~= "table" then prof.funnel = {} end
	if prof.funnel[tostring(n)] then return false end
	prof.funnel[tostring(n)] = true
	ctx.Data.MarkDirty(player)
	pcall(function() Analytics:LogOnboardingFunnelStepEvent(player, n, M.Steps[n]) end)
	table.insert(M._log, { uid = player.UserId, step = n })
	player:SetAttribute("FunnelStep", math.max(player:GetAttribute("FunnelStep") or 0, n))
	return true
end

-- { source, card, detail } -> the customFields table LogCustomEvent takes: CustomField01..03 = each value as a string
-- (a missing value is left out); nil for no fields
function M._customFields(fields)
	if type(fields) ~= "table" then return nil end
	local out = {}
	for _, f in ipairs(FIELDS) do
		if fields[f[1]] ~= nil then out[f[2]] = tostring(fields[f[1]]) end
	end
	return out
end

-- a custom event: value defaults to 1; fields = { source = "walkin"|"phone", card = id, detail = string }?
function M.Event(player, name, value, fields)
	value = value or 1
	if STUDIO then -- before the guard below, so a test's fake player ({ UserId = n }) is logged too
		local uid = player and player.UserId
		table.insert(M._events, { uid = uid, name = name, value = value, fields = fields })
		local f = type(fields) == "table" and fields or {}
		print(string.format("[OK] telemetry %s uid=%s value=%s source=%s card=%s detail=%s", tostring(name),
			tostring(uid), tostring(value), tostring(f.source), tostring(f.card), tostring(f.detail)))
	end
	if typeof(player) ~= "Instance" or not player.Parent then return end
	local custom = M._customFields(fields)
	pcall(function()
		if custom then Analytics:LogCustomEvent(player, name, value, custom) else Analytics:LogCustomEvent(player, name, value) end
	end)
end

function M.Init(c)
	ctx = c
	local DAW = require(RS.OK.Systems.DAW)
	local Contracts = require(RS.OK.Systems.Contracts)
	local Gear = require(RS.OK.Systems.Gear)
	Players.PlayerAdded:Connect(function(p) task.spawn(M.Step, p, 1) end)
	for _, p in ipairs(Players:GetPlayers()) do task.spawn(M.Step, p, 1) end
	c.Interaction.Used:Connect(function(p) M.Step(p, 2) end)
	DAW.Opened:Connect(function(p) M.Step(p, 3) end)
	Contracts.Picked:Connect(function(p) M.Step(p, 4) end)
	Contracts.Delivered:Connect(function(p, brief, stars) M.Step(p, 5); M.Event(p, "Delivery", stars) end)
	DAW.BroadcastTried:Connect(function(p, ok) if ok then M.Step(p, 6) end end)
	Gear.Bought:Connect(function(p) M.Step(p, 7) end)
end

return M
