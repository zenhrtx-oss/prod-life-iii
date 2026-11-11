-- Studio Sessions grader: one pure function used live on the client (green ticks) and for the real grade on the
-- server (Systems/Contracts). A beat is the beat maker's pattern string (track-major, DAWConfig.Tracks), bpm, swing.
-- Required asks met = 2 stars; plus the bonus = 3 stars. Delivery also needs the beat to be "yours":
-- at least M.MinChanged pads different from the default beat, every preset and your last delivery (M.Changed).
local M = {}
M.MinChanged = 8

local function trackIndex(cfg, name)
	for i, tr in ipairs(cfg.Tracks) do if tr.Name == name then return i end end
	return nil
end
local function segment(cfg, pattern, name)
	local i = trackIndex(cfg, name)
	if not i then return "" end
	return pattern:sub((i - 1) * cfg.Steps + 1, i * cfg.Steps)
end
local function hits(seg) return select(2, seg:gsub("[^0]", "")) end
local function on(seg, step) local c = seg:sub(step, step); return c ~= "" and c ~= "0" end

-- short label for an ask, shown next to its tick
function M.Text(ask)
	local k = ask.k
	if k == "bpm" then return string.format("BPM %d–%d", ask.min, ask.max) end
	if k == "backbeat" then return "Snare or clap on 2 & 4" end
	if k == "on" then
		if ask.track == "Kick" and #ask.steps == 1 and ask.steps[1] == 1 then return "Kick on the 1" end
		if ask.track == "Snare" and #ask.steps == 1 and ask.steps[1] == 9 then return "Snare on beat 3" end
		if ask.track == "Hat" and #ask.steps == 4 and ask.steps[1] == 3 then return "Hats on the offbeats" end
		return ask.track .. " on steps " .. table.concat(ask.steps, ", ")
	end
	if k == "min" then return string.format("%d+ %s", ask.n, ask.track == "808" and "808 notes" or (ask.track:lower() .. "s")) end
	if k == "max" then
		if ask.n == 0 then return "No " .. ask.track:lower() end
		return string.format("%d %s max", ask.n, ask.track:lower() .. "s")
	end
	if k == "notes" then return string.format("808 uses %d+ different notes", ask.n) end
	if k == "rolls" then return string.format("%d+ hat rolls", ask.n) end
	if k == "swing" then return string.format("Swing %d%%+", ask.n) end
	if k == "melody" then return string.format("Keys: %d+ notes", ask.n) end
	if k == "melnotes" then return string.format("Keys use %d+ different notes", ask.n) end
	if k == "chord" then return "A chord on the keys (2+ notes together)" end
	return "?"
end

-- the unlock an ask needs (nil = none): "Bass", "Rolls" or "Swing"
function M.Needs(ask)
	if ask.k == "notes" then return "Bass" end
	if ask.k == "rolls" then return "Rolls" end
	if ask.k == "swing" then return "Swing" end
	if (ask.k == "min" or ask.k == "on") and ask.track == "808" then return "Bass" end
	return nil
end
-- unlocks the REQUIRED asks need (the bonus is optional)
function M.Requires(brief)
	local need = {}
	for _, a in ipairs(brief.asks) do local n = M.Needs(a); if n then need[n] = true end end
	return need
end

function M.Ask(cfg, ask, pattern, bpm, swing)
	local k = ask.k
	if k == "bpm" then return bpm >= ask.min and bpm <= ask.max end
	if k == "backbeat" then
		local sn, cl = segment(cfg, pattern, "Snare"), segment(cfg, pattern, "Clap")
		return (on(sn, 5) or on(cl, 5)) and (on(sn, 13) or on(cl, 13))
	end
	if k == "on" then
		local seg = segment(cfg, pattern, ask.track)
		for _, s in ipairs(ask.steps) do if not on(seg, s) then return false end end
		return true
	end
	if k == "min" then return hits(segment(cfg, pattern, ask.track)) >= ask.n end
	if k == "max" then return hits(segment(cfg, pattern, ask.track)) <= ask.n end
	if k == "notes" then
		local seen, n = {}, 0
		for ch in segment(cfg, pattern, "808"):gmatch("[^0]") do if not seen[ch] then seen[ch] = true; n += 1 end end
		return n >= ask.n
	end
	if k == "rolls" then return select(2, segment(cfg, pattern, "Hat"):gsub("[23]", "")) >= ask.n end
	if k == "swing" then return (swing or 0) >= ask.n end
	-- keys lane (piano roll): notes come from DAWConfig.Notes; a beat without a keys lane has none
	if k == "melody" or k == "melnotes" or k == "chord" then
		local notes = cfg.Notes and cfg.Notes(pattern) or {}
		if k == "melody" then return #notes >= ask.n end
		if k == "chord" then -- two notes sounding on the same step, held ones included
			local at = {}
			for _, n in ipairs(notes) do
				for s = n.step, n.step + n.len - 1 do at[s] = (at[s] or 0) + 1; if at[s] >= 2 then return true end end
			end
			return false
		end
		local seen, n = {}, 0
		for _, note in ipairs(notes) do if not seen[note.semi] then seen[note.semi] = true; n += 1 end end
		return n >= ask.n
	end
	return false
end

-- returns { asks = { {text, ok} }, bonus = {text, ok} | nil, met, total, passed, stars }
function M.Check(cfg, brief, pattern, bpm, swing)
	local res = { asks = {}, met = 0, total = #brief.asks }
	for _, a in ipairs(brief.asks) do
		local ok = type(pattern) == "string" and M.Ask(cfg, a, pattern, bpm or 0, swing or 0)
		table.insert(res.asks, { text = M.Text(a), ok = ok })
		if ok then res.met += 1 end
	end
	if brief.bonus then
		local ok = type(pattern) == "string" and M.Ask(cfg, brief.bonus, pattern, bpm or 0, swing or 0)
		res.bonus = { text = M.Text(brief.bonus), ok = ok }
	end
	res.passed = res.met == res.total
	res.stars = res.passed and ((res.bonus and res.bonus.ok) and 3 or 2) or 0
	return res
end

-- pads that differ between two beats. A shorter beat (an older format: 64 or 80 characters) counts as zeros in the
-- lanes it lacks, the way DAWConfig.Upgrade reads it, so old airings and saves still work as references. A held keys
-- note is one pad and an accent is the same note: ties and letter case never count, so stretching notes or painting
-- accents across the velocity lane cannot make a copied beat "yours" (drum cells are digits, so lowercasing is safe).
function M.Diff(a, b)
	a, b = a:gsub("%-", "0"):lower(), b:gsub("%-", "0"):lower()
	local n, m = 0, math.min(#a, #b)
	for i = 1, m do if a:byte(i) ~= b:byte(i) then n += 1 end end
	local longer = #a > #b and a or b
	for i = m + 1, #longer do if longer:byte(i) ~= 48 then n += 1 end end -- 48 = "0"
	return n
end
-- fewest pads changed against any reference beat (default beat, presets, your last delivery, the beat on air)
function M.Changed(pattern, refs)
	local best = math.huge
	for _, r in ipairs(refs) do
		if type(r) == "string" then
			local n = M.Diff(pattern, r)
			if n < best then best = n end
		end
	end
	return best == math.huge and #pattern or best
end
function M.References(cfg, extra)
	local refs = { cfg.DefaultPattern }
	for _, p in ipairs(cfg.Presets or {}) do table.insert(refs, p.pattern) end
	for _, e in ipairs(extra or {}) do table.insert(refs, e) end
	return refs
end

return M
