-- OK Studio system: Cypher rounds (head-to-head and voted battles).
-- Phases: idle -> lobby (join at the lounge cypher board or the cypher bar) -> build (everyone makes a beat to one
-- brief that needs no gear, SUBMIT) -> listen (entries air anonymously as ENTRY A, B, C... at the front of the
-- monitors' line, which is reserved for the round) -> vote (3+ entries only: one vote each, never your own, in the room)
-- -> reveal -> idle. Two entries: head-to-head, most stars wins (equal stars = draw). Never a vote with only two.
-- State for clients lives in attributes on ReplicatedStorage.OK.Cypher; entrants get CypherIn / CypherSubmitted player
-- attributes; an entrant's OWN letter goes on their PlayerGui (only they can see it) so entries stay anonymous. Rewards (Config.Cypher.Reward) go through the capped reward gate.
-- Launch audit A2/A4: Cypher_Join (the bar's JOIN) never opens a lobby from idle ("busy"), so only the board does. A
-- lobby that ends with too few entrants starts Config.Cypher.CancelCooldown seconds, server-wide, in which nobody opens
-- another ("busy"), so one producer can't keep the round's toasts coming. Walk-ins and phone pops wait for everyone while
-- a round listens or votes, and in a lobby, the build and the reveal only for that round's entrants (CypherIn = Round;
-- WalkInRules.CypherHolds).
local RS, Players = game:GetService("ReplicatedStorage"), game:GetService("Players")
local Config = require(RS.OK.Config)
local Cfg = require(RS.OK.Modules.DAWConfig)
local Check = require(RS.OK.Modules.BriefCheck)
local DR = require(RS.OK.Modules.DailyRequests)
local M = { Enabled = true, Version = 1 }
local ctx, folder
-- noLobbyUntil: server time before which no lobby opens (set when a lobby ends with too few entrants)
local S = { phase = "idle", round = 0, entrants = {}, byLetter = {}, lettersList = {}, voted = {}, fakeIds = {}, noLobbyUntil = 0 }

local function cc()
	return Config.Cypher or { LobbySeconds = 20, BuildSeconds = 120, VoteSeconds = 20, RevealSeconds = 10, MinEntrants = 2,
		MaxEntrants = 6, VoteRange = 45, CancelCooldown = 60, Reward = { EnterXP = 10, WinXP = 30, WinCred = 500, VoteXP = 3 } }
end
local function now() return workspace:GetServerTimeNow() end
local function isPlayer(o) return typeof(o) == "Instance" and o:IsA("Player") end

-- the round's brief: a daily template (no gear needed), picked by round number
function M.BriefFor(round)
	local i = round % #DR.Templates + 1
	local t = DR.Templates[i]
	return { id = "cypher", title = "CYPHER", artist = "tavi", cypher = true, template = i, asks = t.asks, bonus = t.bonus, reward = { xp = 0, cred = 0 } }
end

-- pure: entries = { { name, stars, votes, at } }, mode = "h2h" | "vote"  ->  the winner, or nil for a draw
function M.Decide(entries, mode)
	local best, tie = nil, false
	for _, e in ipairs(entries) do
		if not best then best = e
		elseif mode == "vote" then
			if e.votes > best.votes or (e.votes == best.votes and (e.stars > best.stars or (e.stars == best.stars and e.at < best.at))) then best = e end
		else
			if e.stars > best.stars then best = e; tie = false elseif e.stars == best.stars then tie = true end
		end
	end
	if mode == "h2h" and tie then return nil end
	return best
end

local function count()
	local n, sub = 0, 0
	for _, e in pairs(S.entrants) do n += 1; if e.entry then sub += 1 end end
	return n, sub
end
local function publish()
	if not folder then return end
	local n, sub = count()
	folder:SetAttribute("Phase", S.phase); folder:SetAttribute("EndsAt", S.endsAt or 0); folder:SetAttribute("Round", S.round)
	folder:SetAttribute("Template", S.brief and S.brief.template or 0)
	folder:SetAttribute("Entrants", n); folder:SetAttribute("Submitted", sub)
	folder:SetAttribute("Letters", table.concat(S.lettersList, ","))
	folder:SetAttribute("Mode", S.mode or ""); folder:SetAttribute("Result", S.result or ""); folder:SetAttribute("Winner", S.winner or "")
end
local function setLetter(p, letter)
	local pg = isPlayer(p) and p:FindFirstChildOfClass("PlayerGui")
	if pg then pg:SetAttribute("CypherLetter", letter) end
end
local function clearPlayerMarks()
	for _, p in ipairs(Players:GetPlayers()) do
		p:SetAttribute("CypherIn", nil); p:SetAttribute("CypherSubmitted", nil); setLetter(p, nil)
	end
end
local function toastAll(text) for _, p in ipairs(Players:GetPlayers()) do RS.OK.Remotes.InteractionEvent:FireClient(p, "Toast", { text = text }) end end

local function toIdle()
	S.phase = "idle"; S.endsAt = 0; S.entrants = {}; S.byLetter = {}; S.lettersList = {}; S.voted = {}; S.fakeIds = {}
	S.mode = nil; folder:SetAttribute("Playing", ""); folder:SetAttribute("Reveal", "")
	ctx.Monitors:SetReserved(false)
	clearPlayerMarks()
	publish()
end
local function cancel(msg)
	S.result = msg; S.winner = ""
	toastAll("🎤 " .. msg)
	ctx.Monitors:SetReserved(false)
	S.phase = "reveal"; S.endsAt = now() + 4
	publish()
end

-- joins the round, opening a lobby from idle (the board; the Cypher_Join remote refuses idle before this)
function M.Join(owner)
	local uid = owner.UserId
	if S.phase == "idle" then
		if now() < S.noLobbyUntil then return { ok = false, reason = "busy" } end -- a lobby just ended with too few
		S.round += 1
		S.phase = "lobby"; S.endsAt = now() + cc().LobbySeconds
		S.entrants, S.byLetter, S.lettersList, S.voted, S.fakeIds = {}, {}, {}, {}, {}
		S.mode, S.result, S.winner = nil, nil, nil
		S.brief = M.BriefFor(S.round)
		toastAll("🎤 A cypher is starting · join at the cypher board in the lounge")
	elseif not (S.phase == "lobby" or (S.phase == "build" and now() < (S.endsAt or 0) - cc().BuildSeconds / 2)) then
		return { ok = false, reason = "busy" }
	end
	if S.entrants[uid] then return { ok = false, reason = "joined" } end
	if count() >= cc().MaxEntrants then return { ok = false, reason = "full" } end
	S.entrants[uid] = { uid = uid, name = owner.DisplayName or owner.Name or "?", owner = owner }
	if isPlayer(owner) then owner:SetAttribute("CypherIn", S.round) end
	publish()
	return { ok = true, phase = S.phase, round = S.round }
end

function M.Submit(owner, pattern, bpm, swing, voice)
	if S.phase ~= "build" then return { ok = false, reason = "closed" } end
	local e = S.entrants[owner.UserId]
	if not e then return { ok = false, reason = "notin" } end
	if e.entry then return { ok = false, reason = "submitted" } end
	local DAW = require(RS.OK.Systems.DAW)
	local voiceId = Cfg.Voices and Cfg.Voices[1].id
	if isPlayer(owner) then
		voiceId = DAW.VoiceFor(owner, voice) -- an entry airs with its producer's keys voice; an unowned one is refused like a save
		if not voiceId then return { ok = false, reason = "locked" } end
	end
	local p, b, sw = DAW.Validate(pattern, bpm, swing, isPlayer(owner) and DAW.UnlockFn(owner) or nil)
	if not p then return { ok = false, reason = b } end
	local res = Check.Check(Cfg, S.brief, p, b, sw)
	if not res.passed then
		local miss = {}
		for _, a in ipairs(res.asks) do if not a.ok then table.insert(miss, a.text) end end
		return { ok = false, reason = "missing", missing = miss }
	end
	local refs = Check.References(Cfg)
	for _, o in pairs(S.entrants) do if o ~= e and o.entry then table.insert(refs, o.entry.pattern) end end
	-- nor can you enter someone else's recent airing (e.g. sampled while they tried it on the monitors)
	local base = Check.References(Cfg)
	for _, h in ipairs(ctx.Monitors:KnownBeats()) do
		if h.uid ~= owner.UserId and Check.Changed(h.pattern, base) >= Check.MinChanged then table.insert(refs, h.pattern) end
	end
	local changed = Check.Changed(p, refs)
	if changed < Check.MinChanged then return { ok = false, reason = "copy", changed = changed } end
	e.entry = { pattern = p, bpm = b, swing = sw, voice = voiceId, stars = res.stars, at = os.clock() }
	if isPlayer(owner) then
		owner:SetAttribute("CypherSubmitted", S.round)
		pcall(function() require(RS.OK.Systems.Funnel).Event(owner, "CypherEntry", res.stars) end)
	end
	local n, sub = count()
	if sub == n then S.endsAt = now() end -- everyone is in: start listening
	publish()
	return { ok = true, stars = res.stars }
end

local function maxAir() local mc = Config.Monitors or {}; return (mc.MaxSeconds or 20) + (mc.GapSeconds or 3) + (mc.LeadSeconds or 0.5) + 1 end

local function toListen()
	local entries = {}
	for _, e in pairs(S.entrants) do if e.entry then table.insert(entries, e) end end
	if #entries < cc().MinEntrants then return cancel("Cypher cancelled · not enough beats were submitted") end
	table.sort(entries, function(a, b) return a.uid < b.uid end)
	local rng = Random.new() -- unseeded: the order can't be worked out from public data
	for i = #entries, 2, -1 do local j = rng:NextInteger(1, i); entries[i], entries[j] = entries[j], entries[i] end
	S.byLetter, S.lettersList, S.fakeIds = {}, {}, {}
	ctx.Monitors:SetReserved(true)
	for i, e in ipairs(entries) do
		local letter = string.char(64 + i)
		e.letter, e.votes = letter, 0
		S.byLetter[letter] = e
		table.insert(S.lettersList, letter)
		setLetter(e.owner, letter)
		local fid = -(70000 + (S.round % 1000) * 10 + i)
		S.fakeIds[fid] = letter
		ctx.Monitors:EnqueueSystem({ UserId = fid, DisplayName = "ENTRY " .. letter }, e.entry.pattern, e.entry.bpm, e.entry.swing, "studio", i, e.uid, e.name, e.entry.voice)
	end
	S.remaining = #entries
	S.mode = #entries >= 3 and "vote" or "h2h"
	S.phase = "listen"; S.endsAt = now() + #entries * maxAir() + 15
	publish()
end

local function reveal()
	local entries = {}
	for _, l in ipairs(S.lettersList) do
		local e = S.byLetter[l]
		table.insert(entries, { name = e.name, stars = e.entry.stars, votes = e.votes or 0, at = e.entry.at, e = e })
	end
	local w = M.Decide(entries, S.mode)
	local R = cc().Reward
	for _, x in ipairs(entries) do
		local o = x.e.owner
		if isPlayer(o) and o.Parent then
			local prof = ctx.Data.GetProfile(o)
			if type(prof.cypher) ~= "table" then prof.cypher = { entered = 0, wins = 0 } end
			prof.cypher.entered += 1
			ctx.Data.AddXP(o, R.EnterXP, "Cypher")
			if w and w.e == x.e then
				prof.cypher.wins += 1
				ctx.Data.AddXP(o, R.WinXP, "Cypher")
				ctx.Data.AddCred(o, R.WinCred, "Cypher")
				local ok, err = pcall(function() require(RS.OK.Systems.Career).Add(o, "aura", Config.Career.Sources.Cypher.aura.amount, "Cypher") end)
				if not ok then warn("[OK][ERR] career feed: " .. tostring(err)) end
				pcall(function() require(RS.OK.Systems.Life).Event(o, "cypher_win") end) -- logs the first win only
			end
			o:SetAttribute("CypherWins", prof.cypher.wins)
			ctx.Data.MarkDirty(o)
		end
	end
	if w then
		S.winner = w.name
		S.result = string.format("WINNER: %s (ENTRY %s) · %s", w.name, w.e.letter,
			S.mode == "vote" and (w.votes .. " vote" .. (w.votes == 1 and "" or "s")) or (w.stars .. " stars"))
	else
		S.winner = ""; S.result = "DRAW · both beats got the same stars"
	end
	local names = {}
	for _, l in ipairs(S.lettersList) do table.insert(names, l .. "=" .. S.byLetter[l].name) end
	folder:SetAttribute("Reveal", table.concat(names, ","))
	toastAll("🎤 CYPHER " .. S.result)
	ctx.Monitors:SetReserved(false)
	S.phase = "reveal"; S.endsAt = now() + cc().RevealSeconds
	publish()
end

function M.Vote(owner, letter)
	if S.phase ~= "vote" then return { ok = false, reason = "closed" } end
	if type(letter) ~= "string" or not S.byLetter[letter] then return { ok = false, reason = "invalid" } end
	local mine = S.entrants[owner.UserId]
	if mine and mine.letter == letter then return { ok = false, reason = "own" } end
	if S.voted[owner.UserId] then return { ok = false, reason = "again" } end
	if isPlayer(owner) then
		local r = owner.Character and owner.Character:FindFirstChild("HumanoidRootPart")
		local cr = workspace:FindFirstChild("OKStudio") and workspace.OKStudio:FindFirstChild("ControlRoom")
		local near = false
		for _, n in ipairs({ "Speaker_L", "Speaker_R" }) do
			local sp = cr and cr:FindFirstChild(n)
			if r and sp and (sp.Position - r.Position).Magnitude <= cc().VoteRange then near = true end
		end
		if not near then return { ok = false, reason = "far" } end
	end
	S.voted[owner.UserId] = letter
	S.byLetter[letter].votes += 1
	if isPlayer(owner) then ctx.Data.AddXP(owner, cc().Reward.VoteXP, "CypherVote") end
	publish()
	return { ok = true }
end

-- Studio test hook support
function M._Skip()
	if S.phase == "listen" then
		local cur = ctx.Monitors:Current()
		if cur and S.fakeIds[cur.uid] then ctx.Monitors:Cancel(cur.uid); return "skipped " .. S.fakeIds[cur.uid] end
	end
	S.endsAt = 0
	return "ended " .. S.phase
end
-- cooldown: seconds left before a lobby may open again (0 = it may)
function M._State()
	local names = {}
	for l, e in pairs(S.byLetter) do names[l] = e.name end
	return { phase = S.phase, round = S.round, letters = S.lettersList, names = names, mode = S.mode, result = S.result, winner = S.winner,
		cooldown = math.max(0, S.noLobbyUntil - now()) }
end
function M._ClearCooldown() S.noLobbyUntil = 0; return true end

function M.Init(c)
	ctx = c
	folder = RS.OK:FindFirstChild("Cypher") or Instance.new("Folder")
	folder.Name = "Cypher"; folder.Parent = RS.OK
	publish()
	local R = RS.OK.Remotes
	-- the bar's JOIN, shown only in a lobby: it joins a round under way and never opens one (only the board below does)
	R.Cypher_Join.OnServerInvoke = function(player)
		if S.phase == "idle" then return { ok = false, reason = "busy" } end
		return M.Join(player)
	end
	R.Cypher_Submit.OnServerInvoke = function(player, pattern, bpm, swing, voice) return M.Submit(player, pattern, bpm, swing, voice) end
	R.Cypher_Vote.OnServerInvoke = function(player, letter) return M.Vote(player, letter) end
	c.Interaction.Register("Cypher", function(player)
		local r = M.Join(player)
		local msg = r.ok and (r.phase == "lobby" and "You're in the cypher · it starts when the lobby closes" or "You're in · build to the brief and SUBMIT")
			or r.reason == "joined" and "You're already in this cypher"
			or r.reason == "busy" and "A cypher is under way · join the next one"
			or r.reason == "full" and "This cypher is full"
			or "Couldn't join"
		R.InteractionEvent:FireClient(player, "Toast", { text = "🎤 " .. msg })
		return r.ok
	end)
	c.Monitors.Aired:Connect(function(entry)
		if S.phase == "listen" and S.fakeIds[entry.uid] then folder:SetAttribute("Playing", S.fakeIds[entry.uid]) end
	end)
	c.Monitors.Ended:Connect(function(entry)
		if S.phase == "listen" and S.fakeIds[entry.uid] then
			S.remaining -= 1
			if S.remaining <= 0 then S.endsAt = now() end
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		if (S.phase == "lobby" or S.phase == "build") and S.entrants[p.UserId] then
			S.entrants[p.UserId] = nil
			if S.phase == "build" then
				local n, sub = count()
				if n > 0 and sub == n then S.endsAt = now() end -- everyone still in has submitted
			end
			publish()
		end
	end)
	Players.PlayerAdded:Connect(function(p) -- rejoined mid-round: rewards and the bar follow the new Player
		local e = S.entrants[p.UserId]
		if not e or S.phase == "idle" then return end
		e.owner = p
		p:SetAttribute("CypherIn", S.round)
		if e.entry then p:SetAttribute("CypherSubmitted", S.round) end
		if e.letter then task.spawn(function() p:WaitForChild("PlayerGui", 10); setLetter(p, e.letter) end) end
	end)
	task.spawn(function()
		while true do
			task.wait(0.25)
			if S.phase ~= "idle" and now() >= (S.endsAt or 0) then
				if S.phase == "lobby" then
					if count() >= cc().MinEntrants then
						S.phase = "build"; S.endsAt = now() + cc().BuildSeconds; publish()
						for _, e in pairs(S.entrants) do if isPlayer(e.owner) then R.InteractionEvent:FireClient(e.owner, "Toast", { text = "🎤 Cypher on · build to the brief, then SUBMIT" }) end end
					else
						S.noLobbyUntil = now() + (cc().CancelCooldown or 60)
						cancel("Cypher needs " .. cc().MinEntrants .. " producers · not enough joined")
					end
				elseif S.phase == "build" then toListen()
				elseif S.phase == "listen" then
					if S.mode == "vote" then S.phase = "vote"; S.endsAt = now() + cc().VoteSeconds; folder:SetAttribute("Playing", ""); publish()
					else reveal() end
				elseif S.phase == "vote" then reveal()
				elseif S.phase == "reveal" then toIdle() end
			end
		end
	end)
end

return M
