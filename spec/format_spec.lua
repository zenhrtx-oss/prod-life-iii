-- CLI spec for Modules/Format (pure money, count, duration, Aura footer and beat bar text). Run: sh tools/spec.sh format
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


-- BeatBar (Wave 3 final review M3, ruling E): the walk-in card's beat line on a card a beatMin choice decides names the
-- bar and your best beat's quality in stars (WalkInRules.BeatQuality, three shown at most) with its FIRE; nil quality =
-- no beat delivered. Checked on rival_war's real beatMin choice, below and at the bar, and against the rule itself: the
-- line shows the bar met exactly when the choice is sure to land good (WalkInRules.ChoiceChance 100)
do
	local W = require("../src/ReplicatedStorage/OK/Data/WalkIns")
	local R = require("../src/ReplicatedStorage/OK/Modules/WalkInRules")
	local war
	for _, c in ipairs(W.CardById.rival_war.choices) do if c.beatMin then war = c end end
	assert(war and war.beatMin == 3, "rival_war's beatMin choice is gone or moved off 3: update these cases")
	local function bar(beat)
		if beat == nil then return Format.BeatBar(war.beatMin, nil, nil) end
		return Format.BeatBar(war.beatMin, R.BeatQuality(beat), beat.fires)
	end
	local function want(name, got, line)
		if got ~= line then table.insert(fails, string.format("BeatBar %s: expected %q, got %q", name, line, tostring(got))) end
	end
	want("rival_war, no beat", bar(nil), "Needs a 3★ best beat. Yours: none yet.")
	want("rival_war, below (2 stars)", bar({ stars = 2, fires = 0 }), "Needs a 3★ best beat. Yours: ★★☆.")
	want("rival_war, below (0 stars, 1 FIRE: aired only)", bar({ stars = 0, fires = 1 }), "Needs a 3★ best beat. Yours: ☆☆☆ · 🔥 1.")
	want("rival_war, at the bar (3 stars)", bar({ stars = 3, fires = 0 }), "Needs a 3★ best beat. Yours: ★★★.")
	want("rival_war, FIRE lifts 2 stars to the bar", bar({ stars = 2, fires = 3 }), "Needs a 3★ best beat. Yours: ★★★ · 🔥 3.")
	want("rival_war, over the bar (quality 4)", bar({ stars = 3, fires = 5 }), "Needs a 3★ best beat. Yours: ★★★ · 🔥 5.")
	local odds = { auraPer = 20, auraCap = 15, followersPer = 1000, followersCap = 10, min = 10, max = 90 }
	for _, b in ipairs({ { stars = 0, fires = 0 }, { stars = 1, fires = 0 }, { stars = 2, fires = 0 }, { stars = 2, fires = 3 },
		{ stars = 3, fires = 0 }, { stars = 3, fires = 3 } }) do
		local line = bar(b)
		local _, filled = string.gsub(string.match(line, "Yours: (.*)$") or "", "★", "")
		local sure = R.ChoiceChance(war, { aura = 0, followers = 0 }, odds, 0, R.BeatQuality(b)) == 100
		if (filled >= war.beatMin) ~= sure then
			table.insert(fails, string.format("BeatBar %d stars %d FIRE: the line shows %d of %d but the choice is %s", b.stars, b.fires, filled, war.beatMin, sure and "sure" or "lost"))
		end
		-- no longer than the no-beat line it stands in for, so it never takes more lines on the phone card
		if utf8.len(line) > utf8.len("No beat delivered yet. Your odds are lower.") then
			table.insert(fails, string.format("BeatBar %q: %d characters, longer than the no-beat line", line, utf8.len(line)))
		end
	end
	want("whole numbers", Format.BeatBar(2.9, 1.7, 0.4), "Needs a 2★ best beat. Yours: ★☆☆.")
end

if #fails > 0 then error(#fails .. " format case(s) failed: " .. table.concat(fails, "; ")) end
print("SPEC OK: format")
