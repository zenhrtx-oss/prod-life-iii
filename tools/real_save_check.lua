-- Edit or Play (Server): reads the real-save trial's stored profile with GetAsync (read only; plans/2026-11-03-save-safety.md)
-- for the player in the session, or in Edit the signed-in Studio user, and reports what the store holds.
local RS, Players = game:GetService("ReplicatedStorage"), game:GetService("Players")
local DSS, Http = game:GetService("DataStoreService"), game:GetService("HttpService")
local name = RS.OK:GetAttribute("RealSaveTrial")
if type(name) ~= "string" or name == "" then return "REAL SAVE CHECK: the trial is off (tools/real_save_on.lua)" end
local p = Players:GetPlayers()[1]
local uid = p and p.UserId
if not uid then
	local ok, id = pcall(function() return game:GetService("StudioService"):GetUserId() end)
	uid = ok and id or nil
end
if not uid or uid == 0 then return "REAL SAVE CHECK: no player and no Studio user id" end
local ok, doc = pcall(function() return DSS:GetDataStore(name):GetAsync("u_" .. uid) end)
if not ok then return "REAL SAVE CHECK: GetAsync failed: " .. tostring(doc) end
if doc == nil then return "REAL SAVE CHECK " .. name .. " u_" .. uid .. ": nothing stored" end
local function count(t) local n = 0; if type(t) == "table" then for _ in pairs(t) do n += 1 end end; return n end
local life = type(doc.life) == "table" and doc.life or {}
local career = type(doc.career) == "table" and doc.career or {}
local lines = {
	"REAL SAVE CHECK " .. name .. " u_" .. uid .. (p and " (Play)" or " (Edit)"),
	"v " .. tostring(doc.v) .. ", visits " .. tostring(doc.visits) .. ", Money " .. tostring(doc.cred) .. ", XP " .. tostring(doc.xp)
		.. ", level " .. tostring(doc.level) .. ", Followers " .. tostring(career.followers),
	"lock " .. (type(doc.lock) == "table" and (tostring(doc.lock.id):sub(1, 8) .. " at " .. tostring(doc.lock.at)) or "released"),
	"writer " .. (type(doc.writer) == "string" and doc.writer:sub(1, 8) or tostring(doc.writer)),
	"life day " .. tostring(life.day) .. ", story " .. count(life.story) .. ", discography " .. count(life.disco) .. ", firsts "
		.. count(life.firsts) .. ", ribbons " .. count(life.ribbons) .. ", tier " .. tostring(life.tier),
	"JSON " .. #Http:JSONEncode(doc) .. " bytes, updatedAt " .. tostring(doc.updatedAt),
}
if p then
	table.insert(lines, "this session: Money " .. tostring(p:GetAttribute("Cred")) .. ", Followers " .. tostring(p:GetAttribute("Followers"))
		.. ", level " .. tostring(p:GetAttribute("Level")))
end
return table.concat(lines, "\n")
