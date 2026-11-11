-- CLI spec for Modules/Format (pure money, count, duration and Aura footer text). Run: sh tools/spec.sh format
local Format = require("../src/ReplicatedStorage/OK/Modules/Format")

local fails = {}
local function check(fn, n, want)
	local got = Format[fn](n)
	if got ~= want then table.insert(fails, string.format("%s(%s): expected %q, got %q", fn, tostring(n), want, tostring(got))) end
end

-- Money: "$" and thousands commas, truncated toward zero
check("Money", 1040, "$1,040")
check("Money", 0, "$0")
check("Money", -300, "-$300")
check("Money", 1234567, "$1,234,567")
check("Money", 999, "$999")
check("Money", 1000, "$1,000")
check("Money", 1040.9, "$1,040")
check("Money", -300.9, "-$300")
check("Money", -0.5, "$0")

-- SignedMoney: "+" for gains, "-" for losses, bare "$0"
check("SignedMoney", 400, "+$400")
check("SignedMoney", -300, "-$300")
check("SignedMoney", 0, "$0")
check("SignedMoney", 1200, "+$1,200")
check("SignedMoney", 0.5, "$0")
check("SignedMoney", -0.5, "$0")

-- CompactMoney: under 10,000 as Money; one decimal for K, two for M, trailing zeros trimmed, truncated
check("CompactMoney", 9999, "$9,999")
check("CompactMoney", 320, "$320")
check("CompactMoney", 0, "$0")
check("CompactMoney", 10000, "$10K")
check("CompactMoney", 12450, "$12.4K")
check("CompactMoney", 20000, "$20K")
check("CompactMoney", 999999, "$999.9K")
check("CompactMoney", 1000000, "$1M")
check("CompactMoney", 1250000, "$1.25M")
check("CompactMoney", 1500000, "$1.5M")
check("CompactMoney", 1050000, "$1.05M")

-- Count: plain under 1,000; one decimal for K and M, trailing zeros trimmed, truncated; negative = "-" .. Count(-n)
check("Count", 950, "950")
check("Count", 0, "0")
check("Count", 1000, "1K")
check("Count", 1200, "1.2K")
check("Count", 9400, "9.4K")
check("Count", 20000, "20K")
check("Count", 1500000, "1.5M")
check("Count", -1200, "-1.2K")
check("Count", -950, "-950")
check("Count", -0.5, "0")

-- Signed: "+" for positive, "-" for negative, bare "0"
check("Signed", 40, "+40")
check("Signed", -60, "-60")
check("Signed", 0, "0")
check("Signed", 0.5, "0")

-- Duration: how long a visitor waited, for the note card. Under 60 s in seconds; from 60 s whole minutes, rounded down
check("Duration", 90, "1 minute")
check("Duration", 300, "5 minutes")
check("Duration", 59, "59 seconds")
check("Duration", 60, "1 minute")
check("Duration", 1, "1 second")
check("Duration", 119, "1 minute")
check("Duration", 59.9, "59 seconds")
check("Duration", 0, "0 seconds")
check("Duration", -5, "0 seconds")

-- AuraFooter: the card footer line by Aura band (under 0, 0..299, 300 and up); nil reads as 0
local RED = "Your Aura's in the red. People hesitate. Odds stay hidden."
local TODAY = "Your Aura and Followers tilt the odds. You never see them."
local LOUD = "Your Aura's loud. People lean in. Odds stay hidden."
check("AuraFooter", -1, RED)
check("AuraFooter", -500, RED)
check("AuraFooter", 0, TODAY)
check("AuraFooter", 299, TODAY)
check("AuraFooter", nil, TODAY)
check("AuraFooter", 300, LOUD)
-- every line fits the phone footer beside DISMISS: at most 58 characters, today's line's length
for _, aura in ipairs({ -1, 0, 300 }) do
	local line = Format.AuraFooter(aura)
	if #line > 58 then table.insert(fails, string.format("AuraFooter(%d): %d characters > 58", aura, #line)) end
end

if #fails > 0 then error(#fails .. " format case(s) failed: " .. table.concat(fails, "; ")) end
print("SPEC OK: format")
