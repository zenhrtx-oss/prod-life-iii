-- Edit: the Day One plan, Task 2 (card 1, the test hold and the walk-in hold). On the place after build/20_day_one.lua
-- and the sync of Systems/DayOne, Modules/DayOneRules, Data/DayOne, OK/Config, Systems/Tour, Systems/WalkIns and
-- Systems/DAW:
-- (1) the remotes: ReplicatedStorage.OK.Remotes.DayOne (RemoteEvent), DayOne_Choose and DayOne_Get (RemoteFunctions),
--     each marked OK_Build "20_day_one".
-- (2) Config.DayOne equals the literal copy below (spec/day_one_spec.lua holds the same one: an Edit check can't read
--     spec/ from disk; t100's way, rooms ledger F6), field by field.
-- (3) Systems/DayOne, Modules/DayOneRules and Data/DayOne load (fresh clones); DayOne exposes Choose, Get and Running
--     and its Enabled follows Config.DayOne.Enabled.
-- (4) DayOneRules.Starter(Data/Artists' briefs) is j1, and its artist is juno (JUNO VALE, a Color3 colour).
-- (5) Systems/Tour (a fresh clone): the step ids are still open, take, deliver, monitors and gear, in that order;
--     RewardXP is 50; each step's text is Data/DayOne's hub line for it with {artist} filled with the starter artist's
--     name (ruling B2), no "{" left in any of them, and the take step names JUNO VALE; each step's roomText (D1-T4: the
--     DAY ONE pill's line in your own plot, sent in the client payload) is Data/DayOne's room line filled the same way,
--     no "{" either; Tour exposes Changed (an event) and Finish.
-- Nothing is parented into the place but the fresh clones, which are destroyed at once. Marker "T120 OK".
-- The expected red, before build/20_day_one.lua: (1) "ReplicatedStorage.OK.Remotes.DayOne missing".
local RS = game:GetService("ReplicatedStorage")
local function freshRequire(mod) -- edit-mode require caches modules across runs; load a clone so edits take effect
	local c = mod:Clone(); c.Parent = mod.Parent; c.Name = "_fresh_" .. mod.Name
	local ok, res = pcall(require, c); c:Destroy(); if not ok then error(res) end; return res
end
local out = {}

-- a literal copy of Config.DayOne (src/ReplicatedStorage/OK/Config.lua); spec/day_one_spec.lua holds the same
local FIXTURE = { Enabled = true, FirstCard = 1, WakeWait = 20, LookAround = 30, ReturnMin = 15, HoldMax = 70, CardSeconds = 180,
	AfterDeliver = 3, AfterSpeakers = 4, VisitAfter = { 5, 7 }, HaggleOdds = 50, HaggleBonus = 50, PrivateXP = 10 }

-- (1) the remotes ----------------------------------------------------------------------------------------------------
local Remotes = RS.OK:FindFirstChild("Remotes")
assert(Remotes, "ReplicatedStorage.OK.Remotes missing")
for _, want in ipairs({ { "DayOne", "RemoteEvent" }, { "DayOne_Choose", "RemoteFunction" }, { "DayOne_Get", "RemoteFunction" } }) do
	local r = Remotes:FindFirstChild(want[1])
	assert(r, "ReplicatedStorage.OK.Remotes." .. want[1] .. " missing (run build/20_day_one.lua in Edit)")
	assert(r.ClassName == want[2], want[1] .. " is a " .. r.ClassName .. ", want a " .. want[2])
	assert(r:GetAttribute("OK_Build") == "20_day_one", want[1] .. " carries OK_Build " .. tostring(r:GetAttribute("OK_Build")) .. ", want 20_day_one")
end
table.insert(out, "remotes: DayOne (RemoteEvent), DayOne_Choose and DayOne_Get (RemoteFunction), OK_Build 20_day_one")

-- (2) the literal copy equals live Config.DayOne ---------------------------------------------------------------------
local Config = freshRequire(RS.OK.Config)
local live = Config.DayOne
assert(type(live) == "table", "Config.DayOne missing (sync OK/Config)")
local function same(a, b, path)
	if type(a) ~= type(b) then return path .. ": the copy has a " .. type(a) .. ", live Config a " .. type(b) end
	if type(a) ~= "table" then
		if a ~= b then return path .. ": the copy has " .. tostring(a) .. ", live Config " .. tostring(b) end
		return nil
	end
	for k, v in pairs(a) do
		local d = same(v, b[k], path .. "." .. tostring(k))
		if d then return d end
	end
	for k in pairs(b) do
		if a[k] == nil then return path .. "." .. tostring(k) .. ": in live Config, missing from the copy" end
	end
	return nil
end
local diff = same(FIXTURE, live, "Config.DayOne")
assert(diff == nil, "the literal Config.DayOne (t120 and spec/day_one_spec.lua) differs from live Config: " .. tostring(diff))
table.insert(out, "the literal Config.DayOne equals live Config")

-- (3) the modules load -----------------------------------------------------------------------------------------------
assert(RS.OK.Modules:FindFirstChild("DayOneRules"), "ReplicatedStorage.OK.Modules.DayOneRules missing (sync Modules/DayOneRules)")
assert(RS.OK.Data:FindFirstChild("DayOne"), "ReplicatedStorage.OK.Data.DayOne missing (sync Data/DayOne)")
assert(RS.OK.Systems:FindFirstChild("DayOne"), "ReplicatedStorage.OK.Systems.DayOne missing (sync Systems/DayOne)")
local Rules = freshRequire(RS.OK.Modules.DayOneRules)
local D = freshRequire(RS.OK.Data.DayOne)
local DayOne = freshRequire(RS.OK.Systems.DayOne)
for _, fn in ipairs({ "Choose", "Get", "Running", "Init" }) do
	assert(type(DayOne[fn]) == "function", "Systems.DayOne has no " .. fn .. " function")
end
assert(DayOne.Enabled == (FIXTURE.Enabled ~= false), "Systems.DayOne.Enabled is " .. tostring(DayOne.Enabled) .. ", want " .. tostring(FIXTURE.Enabled))
for _, fn in ipairs({ "Next", "Stale", "Starter", "Haggle", "Bonus", "Holds", "Due", "Tool", "Fill", "Card", "Repair" }) do
	assert(type(Rules[fn]) == "function", "Modules.DayOneRules has no " .. fn .. " function")
end
table.insert(out, "Systems.DayOne (Choose, Get, Running; Enabled " .. tostring(DayOne.Enabled) .. "), Modules.DayOneRules and Data.DayOne load")

-- (4) the starter ----------------------------------------------------------------------------------------------------
local Artists = freshRequire(RS.OK.Data.Artists)
local starter = Rules.Starter(Artists.Briefs)
assert(type(starter) == "table", "DayOneRules.Starter(Artists.Briefs) found no single starter brief")
assert(starter.id == "j1", "the starter brief is " .. tostring(starter.id) .. ", want j1")
assert(starter.artist == "juno", "the starter brief's artist is " .. tostring(starter.artist) .. ", want juno")
local juno = Artists.ArtistById.juno
assert(juno and juno.name == "JUNO VALE", "Data/Artists' juno is named " .. tostring(juno and juno.name) .. ", want JUNO VALE")
assert(typeof(juno.color) == "Color3", "juno's colour is a " .. typeof(juno.color) .. ", want a Color3 (Systems/DayOne converts it to { r, g, b })")
table.insert(out, string.format("starter j1 (juno, JUNO VALE, pays $%s)", tostring(starter.reward and starter.reward.cred)))

-- (5) the tour -------------------------------------------------------------------------------------------------------
local Tour = freshRequire(RS.OK.Systems.Tour)
local IDS = { "open", "take", "deliver", "monitors", "gear" }
assert(#Tour.Steps == #IDS, "Tour has " .. #Tour.Steps .. " steps, want " .. #IDS)
for i, id in ipairs(IDS) do
	local s = Tour.Steps[i]
	assert(s.id == id, "Tour step " .. i .. " is " .. tostring(s.id) .. ", want " .. id)
	local want = Rules.Fill(D.Steps[id].hub, { artist = juno.name })
	assert(s.text == want, "Tour step " .. id .. " reads '" .. tostring(s.text) .. "', want Data/DayOne's hub line filled: '" .. want .. "'")
	assert(not tostring(s.text):find("{", 1, true), "Tour step " .. id .. " still holds a '{': " .. tostring(s.text))
	-- D1-T4: the room line the client payload carries (roomText), filled the same way
	local wantRoom = Rules.Fill(D.Steps[id].room, { artist = juno.name })
	assert(s.roomText == wantRoom, "Tour step " .. id .. "'s roomText reads '" .. tostring(s.roomText) .. "', want Data/DayOne's room line filled: '" .. wantRoom
		.. "' (before the D1-T4 sync of Systems/Tour: the expected red)")
	assert(not tostring(s.roomText):find("{", 1, true), "Tour step " .. id .. "'s roomText still holds a '{': " .. tostring(s.roomText))
end
assert(Tour.Steps[2].roomText:find("JUNO VALE", 1, true), "the take step's room line doesn't name JUNO VALE: " .. Tour.Steps[2].roomText)
assert(Tour.Steps[2].text:find("JUNO VALE", 1, true), "the take step doesn't name JUNO VALE: " .. Tour.Steps[2].text)
assert(Tour.RewardXP == 50, "Tour.RewardXP is " .. tostring(Tour.RewardXP) .. ", want 50")
assert(typeof(Tour.Changed) == "RBXScriptSignal", "Tour.Changed is a " .. typeof(Tour.Changed) .. ", want an event (RBXScriptSignal)")
assert(type(Tour.Finish) == "function", "Tour.Finish is a " .. type(Tour.Finish) .. ", want a function")
table.insert(out, "Tour: open, take, deliver, monitors, gear; RewardXP 50; texts are Data/DayOne's hub lines and roomTexts its room lines, no '{'; Changed and Finish")

return "T120 OK\n" .. table.concat(out, "\n")
