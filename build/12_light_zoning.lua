-- EXPERIMENTAL, NOT IN THE REBUILD ORDER: under ShadowMap these narrow downward spotlights stopped the bleed through walls
-- but left the rooms nearly black (captures/m3/focus_*.jpg vs reverted_*.jpg). Kept for reference; Future lighting is the real fix.
-- 12: keep each room's light in its room. Run after 03, 04, 05 (they recreate the fixtures) and before tests.
-- Under ShadowMap, local lights do not cast shadows, so they shine straight through the 1-stud walls.
-- Rules (shared walls at x = 12, 44, 80; their faces are 0.5 studs either side):
--   * ceiling cans, pendants, the corridor strip and the couch lamp become downward SpotLights whose cone,
--     at floor level, never reaches the nearest shared wall: h * tan(Angle/2) <= distance
--     (Angle is the full cone width; measured in Studio, see SPOT_FULL_CONE below).
--   * sign glows and the REC light become SurfaceLights facing into their own room.
--   * every remaining PointLight gets Range <= distance to the nearest shared wall face.
-- The light count does not change.
local SPOT_FULL_CONE = true -- measured 2026-10-22: a 60° SpotLight 10 studs up lit a disk of radius ~5.8 (10·tan 30°), not ~17 (10·tan 60°)
local B = "12_light_zoning"
local S = workspace.OKStudio
local WALLS = { 12, 44, 80 }

local function roomBounds(x)
	if x < 12 then return 0, 12 elseif x < 44 then return 12, 44 elseif x < 80 then return 44, 80 else return 80, 94 end
end
-- distance from a point to the nearest SHARED wall face of the room it is in (outer walls do not count)
local function wallDist(x)
	local lo, hi = roomBounds(x)
	local d = math.huge
	for _, w in ipairs(WALLS) do
		if w == lo then d = math.min(d, x - (w + 0.5)) end
		if w == hi then d = math.min(d, (w - 0.5) - x) end
	end
	return d
end

local DOWN = { Spot_Console_1_Lens = true, Spot_Console_2_Lens = true, Spot_Couch_Lens = true, Spot_Booth_Lens = true,
	Pendant_Lounge_1_Bulb = true, Pendant_Lounge_2_Bulb = true, Pendant_Bar_Bulb = true, Strip_Corridor = true, Lamp_Bulb = true,
	Sconce_Corridor_Bulb = true }
local SURFACE = { Neon_Sign_Glow = true, OK_Sign_Glow = true, REC_Sign = true }

local function replaceLight(old, class)
	local n = Instance.new(class)
	n.Color = old.Color; n.Brightness = old.Brightness; n.Enabled = old.Enabled; n.Shadows = old.Shadows
	n.Name = old.Name; n:SetAttribute("OK_Build", B)
	local parent = old.Parent
	old:Destroy()
	n.Parent = parent
	return n
end

local report = {}
for _, part in ipairs(S:GetDescendants()) do
	if part:IsA("BasePart") then
		local light = part:FindFirstChildWhichIsA("Light")
		if light then
			local x = part.Position.X
			local d = wallDist(x)
			local floorY = 0
			local h = part.Position.Y - floorY
			if DOWN[part.Name] then
				local range0 = light.Range
				local s = light:IsA("SpotLight") and light or replaceLight(light, "SpotLight")
				s.Face = Enum.NormalId.Bottom
				local half = math.deg(math.atan((d - 0.3) / h))
				local angle = SPOT_FULL_CONE and math.clamp(2 * half, 20, 120) or math.clamp(half, 10, 60)
				s.Angle = angle
				local halfUsed = SPOT_FULL_CONE and angle / 2 or angle
				s.Range = math.max(range0, h / math.cos(math.rad(halfUsed)) + 1)
				local base = s:GetAttribute("BaseBrightness") or s.Brightness
				s:SetAttribute("BaseBrightness", base)
				s.Brightness = base * 1.25
				table.insert(report, string.format("%s spot angle=%.0f h=%.1f wallDist=%.1f", part.Name, angle, h, d))
			elseif SURFACE[part.Name] then
				local range0, enabled = light.Range, light.Enabled
				local s = light:IsA("SurfaceLight") and light or replaceLight(light, "SurfaceLight")
				-- face into the room: the glow strip sits against a wall at x = 44 or 80
				local lo, hi = roomBounds(x)
				s.Face = (math.abs(x - hi) < math.abs(x - lo)) and Enum.NormalId.Left or Enum.NormalId.Right
				s.Angle = 90; s.Range = math.min(range0, 12); s.Enabled = enabled
				table.insert(report, string.format("%s surface face=%s", part.Name, s.Face.Name))
			elseif light:IsA("PointLight") then
				local r = math.min(light.Range, math.max(2, d - 0.2))
				if r < light.Range then
					table.insert(report, string.format("%s range %.1f -> %.1f", part.Name, light.Range, r))
					light.Range = r
				end
			end
		end
	end
end
local n = 0
for _, l in ipairs(workspace:GetDescendants()) do if l:IsA("Light") then n += 1 end end
return "light zoning: lights=" .. n .. "\n" .. table.concat(report, "\n")
