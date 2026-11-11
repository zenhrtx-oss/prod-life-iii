-- OK Studio GatesClient: the Studio Two door (Workspace.OK_Gates.StudioTwoDoor) opens for you once you own the
-- studio_two gate (the CareerGates attribute, Systems/Career). Only on this client: the door stops colliding, turns
-- see-through and hides its prompt, while everyone else's door stays shut. Re-applies when CareerGates changes and
-- whenever the door (or its prompt) appears. Never waits without a timeout.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local GATE = "studio_two"
local OPEN_TRANSPARENCY = 0.85
local closedLook = setmetatable({}, { __mode = "k" }) -- door -> its own transparency, to put back if the gate goes

local function owns()
	local list = player:GetAttribute("CareerGates")
	return type(list) == "string" and string.find("," .. list .. ",", "," .. GATE .. ",", 1, true) ~= nil
end

local function apply()
	local gates = workspace:FindFirstChild("OK_Gates")
	local door = gates and gates:FindFirstChild("StudioTwoDoor")
	if not (door and door:IsA("BasePart")) then return end
	if closedLook[door] == nil then closedLook[door] = door.Transparency end
	local open = owns()
	door.CanCollide = not open
	door.Transparency = open and OPEN_TRANSPARENCY or closedLook[door]
	local prompt = door:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then prompt.Enabled = not open end
end

local function watch(gates)
	gates.DescendantAdded:Connect(function(d)
		if d.Name == "StudioTwoDoor" or d:IsA("ProximityPrompt") then apply() end
	end)
	apply()
end

player:GetAttributeChangedSignal("CareerGates"):Connect(apply)
workspace.ChildAdded:Connect(function(c) if c.Name == "OK_Gates" then watch(c) end end)
local existing = workspace:FindFirstChild("OK_Gates")
if existing then watch(existing) end
