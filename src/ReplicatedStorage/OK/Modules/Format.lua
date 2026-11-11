-- OK Studio Format: how money, counts and durations read on screen ("$1,040", "$12.4K", "+$400", "1.2K", "+40",
-- "5 minutes"), and the card footer line by Aura band.
-- Pure: no Roblox globals and no require, so it loads in Studio (require(RS.OK.Modules.Format)) and in the luau CLI
-- (spec/format_spec.lua). Every function truncates toward zero first; anything that is not a finite number reads as 0.
local M = {}

-- whole number, truncated toward zero (never -0); nil, NaN and infinities give 0
local function whole(n)
	n = tonumber(n) or 0
	if n ~= n or n == math.huge or n == -math.huge then return 0 end
	local i = n < 0 and -math.floor(-n) or math.floor(n)
	return i == 0 and 0 or i
end

local function digits(i) return string.format("%.0f", i) end

-- a non-negative whole number with thousands commas: 1234567 -> "1,234,567"
local function commas(i)
	local s, k = digits(i), 0
	repeat s, k = s:gsub("^(%d+)(%d%d%d)", "%1,%2") until k == 0
	return s
end

-- a non-negative whole number in units (1000 or 1000000) with up to `places` decimals, truncated, trailing zeros
-- trimmed: (12450, 1000, 1) -> "12.4", (1250000, 1000000, 2) -> "1.25", (20000, 1000, 1) -> "20"
local function scaled(i, unit, places)
	local f = 10 ^ places
	local v = i // (unit // f)
	local int, frac = v // f, v % f
	if frac == 0 then return digits(int) end
	return digits(int) .. "." .. (string.format("%0" .. places .. "d", frac):gsub("0+$", ""))
end

-- 1040 -> "$1,040", 0 -> "$0", -300 -> "-$300"
function M.Money(n)
	local i = whole(n)
	if i < 0 then return "-$" .. commas(-i) end
	return "$" .. commas(i)
end

-- 400 -> "+$400", -300 -> "-$300", 0 -> "$0"
function M.SignedMoney(n)
	local i = whole(n)
	return (i > 0 and "+" or "") .. M.Money(i)
end

-- under 10,000 as Money; then "$12.4K" (one decimal) and "$1.25M" (two decimals); a negative amount gets a leading "-"
function M.CompactMoney(n)
	local i = whole(n)
	if i < 0 then return "-" .. M.CompactMoney(-i) end
	if i < 10000 then return M.Money(i) end
	if i < 1000000 then return "$" .. scaled(i, 1000, 1) .. "K" end
	return "$" .. scaled(i, 1000000, 2) .. "M"
end

-- 950 -> "950", 1200 -> "1.2K", 20000 -> "20K", 1500000 -> "1.5M" (one decimal for K and M); negative -> "-" .. Count(-n)
function M.Count(n)
	local i = whole(n)
	if i < 0 then return "-" .. M.Count(-i) end
	if i < 1000 then return digits(i) end
	if i < 1000000 then return scaled(i, 1000, 1) .. "K" end
	return scaled(i, 1000000, 1) .. "M"
end

-- 40 -> "+40", -60 -> "-60", 0 -> "0"
function M.Signed(n)
	local i = whole(n)
	return (i > 0 and "+" or "") .. digits(i)
end

-- how long something took: under 60 s in seconds, from 60 s whole minutes rounded down. 59 -> "59 seconds",
-- 1 -> "1 second", 90 -> "1 minute", 300 -> "5 minutes"; a negative time reads as "0 seconds"
function M.Duration(seconds)
	local s = math.max(0, whole(seconds))
	local n, unit = s, "second"
	if s >= 60 then n, unit = s // 60, "minute" end
	return digits(n) .. " " .. unit .. (n == 1 and "" or "s")
end

-- the walk-in and phone card footer by Aura band; every line keeps the odds hidden and fits beside DISMISS (<= 58
-- characters). Under 0 -> in the red, 0..299 -> the tilt line, 300 and up -> loud
function M.AuraFooter(aura)
	local a = whole(aura)
	if a < 0 then return "Your Aura's in the red. People hesitate. Odds stay hidden." end
	if a >= 300 then return "Your Aura's loud. People lean in. Odds stay hidden." end
	return "Your Aura and Followers tilt the odds. You never see them."
end

return M
