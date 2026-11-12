-- OK Studio Data/DayOne (the Day One plan, Task 1): every word of Day One, the opening chain in your bedroom. The
-- lines are research/day_one/copy_2026-11-12.md's rows (§1-§6), verbatim, with their tokens; drafts on that doc's
-- approval list (§9). Pure: no Roblox globals and no require; Modules/DayOneRules fills and builds them (Fill, Card).
--
-- Tokens (the doc's token table; a money token carries its own "$"): {artist} the starter's CAPS name, {pay} its pay,
--   {ask} pay + Config.DayOne.HaggleBonus, {money} your money, {tool} and {toolprice} DayOneRules.Tool's row,
--   {goal}, {goalprice} and {goalfollowers} the Desk monitors (spk_monitors), {xp} Config.DayOne.PrivateXP, {reward}
--   Tour.RewardXP, {reason} a Rooms.PlayLocal refusal code. The starter artist's name comes only through {artist}.
-- Cards[id] = { name, tag, line (or lines = { tool, none }), face (a portrait of the starter's artist), now (shown over
--   the beat maker: cards 2 and 3; D1-T4 fix 1 for card 3), choices = { { key, text } } }. A choice's index is its key's order; index 0 is Skip.
-- Steps[id] = { hub, room }: the DAY ONE pill's line per Tour step, at the hub and in your own plot (§5).
-- Marks[id]: the coach marks over the live beat-maker controls (§6); labels with no token.
local D = {}

D.Header = "DAY ONE" -- 1.7: the card's header row and the pill's heading
D.Skip = "SKIP" -- 1.8: the card's bottom button (index 0)

D.Cards = {
	-- §1 Card 1: the starter's beat request, a few seconds after you wake up
	dayone = {
		name = "{artist}", -- 1.1
		tag = "FIRST REQUEST · BY TONIGHT", -- 1.2
		line = "i need a beat by tonight and i have exactly zero. {pay} if you can make one?", -- 1.3
		face = true,
		choices = {
			{ key = "make", text = "On it. Make it now." }, -- 1.4
			{ key = "haggle", text = "Haggle: ask for {ask}." }, -- 1.5
			{ key = "look", text = "Look around first." }, -- 1.6
		},
	},
	-- §2 Card 2: play it on your speakers? (after the first delivery at your own laptop; over the beat maker)
	speakers = {
		name = "YOUR BEAT", -- 2.1
		tag = "YOUR SPEAKERS · FIRST LISTEN", -- 2.2
		line = "first beat done. want to hear it on your speakers?", -- 2.3
		face = false,
		now = true,
		choices = {
			{ key = "speakers", text = "On my speakers. Let's hear it." }, -- 2.4
			{ key = "private", text = "Keep it private. Headphones on." }, -- 2.5
		},
	},
	-- §3 Card 3: you've got money. spend it? (over the beat maker too, D1-T4 fix 1: on a phone the compact beat maker would
	-- hide it, and it holds the first visitor while it waits)
	spend = {
		name = "YOUR MONEY", -- 3.1
		tag = "FIRST PAYDAY · THE GEAR RACK", -- 3.2
		lines = {
			tool = "you've got {money}. spend it? {tool} is {toolprice}. next goal: {goal}, {goalprice} and {goalfollowers} followers.", -- 3.3
			none = "you've got {money}. the rack can wait. next goal: {goal}, {goalprice} and {goalfollowers} followers.", -- 3.4
		},
		face = false,
		now = true,
		choices = {
			{ key = "rack", text = "Hit the gear rack." }, -- 3.5
			{ key = "save", text = "Save it for the monitors." }, -- 3.6
		},
	},
}

-- §4 the toasts
D.Toasts = {
	haggleGood = "she said yes. {ask} when it's done.", -- 4.1
	haggleBad = "she won't budge. {pay}, final.", -- 4.2
	far = "got it. your laptop's on the desk.", -- 4.3
	farHub = "got it. head to the studio PC.", -- 4.4
	speakers = "sounds good. air it in the studio next.", -- 4.5
	private = "your secret's safe · +{xp} XP", -- 4.6
	rackFar = "the gear rack is by your laptop", -- 4.7
	done = "DAY ONE DONE · +{reward} XP", -- 4.8: the tour-complete toast
	speakersRefused = "Couldn't play on your speakers ({reason})", -- 4.9: the rooms copy's 4.9, word for word
}

-- §5 the DAY ONE pill: the hub line (Tour's words, JUNO VALE through {artist}) and the room line, per step
D.Steps = {
	open = { hub = "Open the studio PC or a studio laptop", room = "Open your laptop to make a beat" }, -- 5.1, 5.2
	take = { hub = "Take the starter request from {artist}", room = "Take {artist}'s request on your laptop" }, -- 5.3, 5.4
	deliver = { hub = "Make every ask tick green, then press DELIVER", room = "Make every ask tick green, then press DELIVER" }, -- 5.5, 5.6
	monitors = { hub = "Press ON MONITORS so the room hears it", room = "Press ON SPEAKERS so the room hears it" }, -- 5.7, 5.8
	gear = { hub = "Spend your money at the gear rack", room = "Spend your money at your laptop's gear rack" }, -- 5.9, 5.10
}

-- §6 the coach marks
D.Marks = {
	deliver = "All green? Press DELIVER", -- 6.1
	take = "Tap the request to take it", -- 6.2
	monitors = "Press this to play it out loud", -- 6.3
}

return D
