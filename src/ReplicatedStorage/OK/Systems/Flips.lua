-- OK Studio system: SAMPLE IT / flips. A listener can sample the beat on the monitors into their beat maker; once it
-- differs by Check.MinChanged+ pads it can go on the monitors as "flip of <producer>", and the original producer gets
-- +1 flip (card), a little Cred (Config.Cred.Sources.Flip, capped daily) and Followers (Systems/Career). Putting
-- someone's recent airing on the monitors WITHOUT sampling it (or barely changed) is refused, unless that beat is
-- itself the default beat or a preset.
local RS, Players = game:GetService("ReplicatedStorage"), game:GetService("Players")
local Config = require(RS.OK.Config)
local Format = require(RS.OK.Modules.Format)
local Cfg = require(RS.OK.Modules.DAWConfig)
local Check = require(RS.OK.Modules.BriefCheck)
local M = { Enabled = true, Version = 1 }
local ctx
function M._SetConfigForTest(cfg, check) Cfg = cfg; if check then Check = check end end -- edit-mode tests: the require cache can hold older modules

local function diff(a, b) return Check.Diff(a, b) end -- an older, shorter beat counts as zeros in the lanes it lacks
-- what SAMPLE IT gives a flipper without the gear (mirrors DAWClient playable): rolls become hats, no 808 without Bass
function M.Sampled(pattern, unlocked)
	if not unlocked then return pattern end
	local out = {}
	for t, tr in ipairs(Cfg.Tracks) do
		local seg = pattern:sub((t - 1) * Cfg.Steps + 1, t * Cfg.Steps)
		if tr.Kind == "roll" and not unlocked("Rolls") then seg = seg:gsub("[23]", "1") end
		if tr.Kind == "bass" and not unlocked("Bass") then seg = string.rep("0", Cfg.Steps) end
		table.insert(out, seg)
	end
	if Cfg.KeysSeg then table.insert(out, Cfg.KeysSeg(pattern)) end -- the keys lane needs no gear
	return table.concat(out)
end

-- pure. history = { { token, uid, name, pattern } } (recent airings), flipToken = token the client says it sampled (or nil)
-- returns flipOf (history entry or nil)  or  nil, reason ("gone" | "own" | "flipcopy" | "copy"), changed
-- unlocked (optional) = the flipper's unlock function: the 8 changes are counted from what their sample held
function M.Judge(history, playerId, pattern, flipToken, unlocked)
	local refs = Check.References(Cfg)
	local src
	if flipToken ~= nil then
		for _, h in ipairs(history) do if h.token == flipToken then src = h end end
		if not src then return nil, "gone" end
		if src.uid == playerId then return nil, "own" end
		local changed = diff(M.Sampled(src.pattern, unlocked), pattern)
		if changed < Check.MinChanged then return nil, "flipcopy", changed end
	end
	-- a flip of one beat must still not be a copy of ANOTHER producer's airing
	for _, h in ipairs(history) do
		if h ~= src and h.uid ~= playerId and Check.Changed(h.pattern, refs) >= Check.MinChanged and diff(h.pattern, pattern) < Check.MinChanged then
			return nil, "copy", diff(h.pattern, pattern)
		end
	end
	return src
end

-- the original producer's side (also used by the Studio test hook with a pretend flipper)
function M.Credit(authorId, flipperName)
	local author = Players:GetPlayerByUserId(authorId)
	if not author then return 0 end
	local prof = ctx.Data.GetProfile(author)
	prof.flipsReceived = (tonumber(prof.flipsReceived) or 0) + 1
	author:SetAttribute("Flips", prof.flipsReceived)
	ctx.Data.MarkDirty(author)
	local cred = ctx.Data.AddCred(author, Config.Cred.Sources.Flip.amount, "Flip")
	local ok, err = pcall(function() require(RS.OK.Systems.Career).Add(author, "followers", Config.Career.Sources.Flip.followers.amount, "Flip") end)
	if not ok then warn("[OK][ERR] career feed: " .. tostring(err)) end
	RS.OK.Remotes.InteractionEvent:FireClient(author, "Toast", { text = "🔁 " .. tostring(flipperName) .. " flipped your beat" .. ((cred or 0) > 0 and (" · " .. Format.SignedMoney(cred)) or "") })
	return cred
end

function M.Init(c)
	ctx = c
	local function onJoin(p) task.spawn(function() local prof = ctx.Data.GetProfile(p); p:SetAttribute("Flips", tonumber(prof.flipsReceived) or 0) end) end
	Players.PlayerAdded:Connect(onJoin)
	for _, p in ipairs(Players:GetPlayers()) do onJoin(p) end
end

return M
