local function esc(s)
	return '"' .. s:gsub('[%c"\\]', function(c)
		if c == '"' then return '\\"' elseif c == '\\' then return '\\\\' elseif c == '\n' then return '\\n' elseif c == '\t' then return '\\t' end
		return string.format('\\u%04x', string.byte(c)) end) .. '"'
end
local function ser(v, out)
	local t = type(v)
	if t == "table" then
		local n = #v
		local isArr = n > 0
		if isArr then for k in pairs(v) do if type(k) ~= "number" then isArr = false break end end end
		if isArr then
			out[#out+1] = "["
			for i = 1, n do if i > 1 then out[#out+1] = "," end ser(v[i], out) end
			out[#out+1] = "]"
		else
			local keys = {}
			for k in pairs(v) do keys[#keys+1] = tostring(k) end
			table.sort(keys)
			out[#out+1] = "{"
			local first = true
			for _, k in ipairs(keys) do
				local val = v[k]; if val == nil then val = v[tonumber(k)] end
				if type(val) ~= "function" then
					if not first then out[#out+1] = "," end; first = false
					out[#out+1] = esc(k) .. ":"; ser(val, out)
				end
			end
			out[#out+1] = "}"
		end
	elseif t == "string" then out[#out+1] = esc(v)
	elseif t == "number" or t == "boolean" then out[#out+1] = tostring(v)
	else out[#out+1] = "null" end
end
local W = require("./WalkIns")
local res = { visitors = W.Visitors, sponsors = W.Sponsors, cards = W.Cards, followups = W.Followups, waitLines = W.WaitLines, noteLines = W.NoteLines, relFlags = W.RelFlags }
local okA, A = pcall(require, "./Artists")
if okA then res.artists = A else res.artistsErr = tostring(A) end
local okC, C = pcall(require, "./Config")
if okC then res.config = C else res.configErr = tostring(C) end
local out = {}; ser(res, out); print(table.concat(out))
