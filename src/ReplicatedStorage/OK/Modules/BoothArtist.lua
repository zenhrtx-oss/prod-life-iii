-- Studio Sessions listen-back: the requesting artist appears in the vocal booth (client-only, only the producer
-- who delivered sees it), turned towards the control-room window, nodding to the beat with their reaction overhead.
-- Built from a few parts (no images); removed after a few seconds. Lives under the camera so it never replicates.
-- Show(artist, stars, quote, seconds, spot?): with `spot` (a CFrame: a room's BoothSpot, the Your Rooms plan, Task 12) the
-- artist stands on it, feet at its position, facing its horizontal LookVector (towards the room's BoothCam); without it,
-- in the hub's vocal booth as before, turned towards the control-room window (-X). Returns the model, or nil when the
-- hub booth isn't there.
local RunService = game:GetService("RunService")
local M = {}
local current

function M.Hide()
	if current then
		if current.conn then current.conn:Disconnect() end
		current.model:Destroy()
		current = nil
	end
end

function M.Show(artist, stars, quote, seconds, spot)
	M.Hide()
	-- the body is laid out with its front along -X (offsets in the frame `at`, each part turned by `face`); at the hub `at`
	-- is a plain position, in a room it is turned so that front looks along the spot's facing
	local face = CFrame.Angles(0, math.rad(90), 0)                       -- turned towards the control room (-X)
	local at
	if typeof(spot) == "CFrame" then
		local look = Vector3.new(spot.LookVector.X, 0, spot.LookVector.Z)
		if look.Magnitude < 1e-3 then look = -Vector3.zAxis end
		local pos = spot.Position + Vector3.new(0, 0.1, 0)
		at = CFrame.lookAt(pos, pos + look.Unit) * CFrame.Angles(0, -math.rad(90), 0)
	else
		local s = workspace:FindFirstChild("OKStudio")
		local booth = s and s:FindFirstChild("VocalBooth")
		local mic = booth and booth:FindFirstChild("Mic")
		if not mic then return nil end
		at = CFrame.new(mic.Position.X - 2.3, 0.1, mic.Position.Z) -- between the window and the mic
	end
	local model = Instance.new("Model"); model.Name = "OK_BoothArtist"
	model:SetAttribute("Artist", artist.name)
	model:SetAttribute("InRoom", typeof(spot) == "CFrame")
	local parts = {}
	local function part(name, size, offset, color, shape)
		local p = Instance.new("Part")
		p.Name = name; p.Size = size; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CastShadow = false
		p.Material = Enum.Material.SmoothPlastic; p.Color = color
		if shape then p.Shape = shape end
		p.CFrame = at * CFrame.new(offset) * face
		p.Parent = model
		table.insert(parts, { part = p, base = p.CFrame, nod = offset.Y > 2.1 })
		return p
	end
	local dark, skin = Color3.fromRGB(30, 30, 36), Color3.fromRGB(150, 110, 85)
	part("LegL", Vector3.new(0.6, 2.2, 0.6), Vector3.new(0, 1.1, -0.35), dark)
	part("LegR", Vector3.new(0.6, 2.2, 0.6), Vector3.new(0, 1.1, 0.35), dark)
	part("Torso", Vector3.new(1.6, 2.0, 0.9), Vector3.new(0, 3.2, 0), artist.color)
	part("ArmL", Vector3.new(0.5, 1.9, 0.5), Vector3.new(0, 3.15, -1.05), artist.color)
	part("ArmR", Vector3.new(0.5, 1.9, 0.5), Vector3.new(0, 3.15, 1.05), artist.color)
	local head = part("Head", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 4.85, 0), skin, Enum.PartType.Ball)
	part("EyeL", Vector3.new(0.1, 0.2, 0.14), Vector3.new(-0.57, 4.95, -0.22), Color3.fromRGB(12, 12, 14)) -- eyes on the window side
	part("EyeR", Vector3.new(0.1, 0.2, 0.14), Vector3.new(-0.57, 4.95, 0.22), Color3.fromRGB(12, 12, 14))
	local bb = Instance.new("BillboardGui")
	bb.Name = "Reaction"; bb.Size = UDim2.fromOffset(240, 74); bb.StudsOffset = Vector3.new(0, 2.2, 0); bb.MaxDistance = 80
	bb.LightInfluence = 0; bb.Adornee = head; bb.Parent = model
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1); lbl.BackgroundTransparency = 0.25; lbl.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
	lbl.TextColor3 = Color3.fromRGB(240, 240, 240); lbl.Font = Enum.Font.GothamBold; lbl.TextScaled = true; lbl.TextWrapped = true
	lbl.RichText = true
	lbl.Text = string.format('<font color="#FFD24A">%s</font>\n%s: “%s”', string.rep("★", stars or 0), artist.name, quote or "")
	lbl.Parent = bb
	Instance.new("UICorner").Parent = lbl
	model.Parent = workspace.CurrentCamera
	local t0 = os.clock()
	local conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		local nod = math.abs(math.sin(t * 7)) * 0.18
		for _, e in ipairs(parts) do
			if e.nod then e.part.CFrame = e.base * CFrame.new(0, -nod, 0) end
		end
	end)
	current = { model = model, conn = conn }
	local mine = current
	task.delay(seconds or 8, function() if current == mine then M.Hide() end end)
	return model
end

return M
