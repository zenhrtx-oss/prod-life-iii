-- Server, during play (the Your Rooms plan, Task 14: door modes, friends only by default), through the Studio hooks (a
-- server test can't press a prompt: the rooms hook's Door runs the owner's DoorPrompt handler, Enter the hall door's). The
-- body runs held (WalkInsPaused true) from the file's fresh(): unseated in the lounge, Quiet on, the phone, WalkIns, Career and
-- Life reset, no hint seen, the rooms hook's Reset (a slot claimed, the plot rebuilt; the friend check's stub and cache gone).
-- Slot numbers are read (the player's from Plot, the stand-in owner's from the plot Fill builds), never assumed.
-- (1) a fresh home: Home and State read door "friends" (Config.Rooms.DoorDefault). The landing's FrontDoor holds the owner's
--     DoorPrompt: untagged, "Door: FRIENDS ONLY" / "Who can come in" (copy 10.4, 10.5), F / ButtonY (the LeavePrompt beside it
--     keeps E / ButtonX), the house style (instant, no line of sight, the interaction reach), OwnerId the player's, stacked
--     RoomBuild.RACK_UI_GAP px over the LeavePrompt; no other prompt of the plot on F or ButtonY stands within two reaches of
--     the front door (so no spot is in reach of both; a clashing prompt the scan can't place fails it: fix 1, M5). The hall plate reads "{player}\nSTUDIO nn · FRIENDS ONLY" (copy 1.9) in
--     the friends colour.
-- (2) the owner's cycle (the hook's Door, the prompt's own handler): friends -> locked -> open -> friends. After each press
--     Door answers the mode; Home and State read it (saved); the plate's words and colour and the prompt's ActionText show
--     it; one toast (copy 10.6 - 10.8) and a pushed "state" with that door. Then locked once more and Release: Door answers
--     false (no slot) and toasts nothing; Claim: the rebuilt plot's plate and prompt read LOCKED (the build reads the save);
--     two more presses come back to friends. The owner's presses are paced DOOR_GAP apart (Systems/Rooms ignores a press
--     within 0.25 s of the last cycle: R-T14 fix 1, M3), and two presses sent back to back (inside 0.25 s) cycle once: the
--     second answers false, toasts nothing and leaves the door as it was (up to three pairs, fix 2: skipped only if every
--     pair takes 0.25 s or more; the door ends locked either way).
-- (3) a stand-in owner's door (Fill(1); the hook's Door(slot, mode) sets its mode): its plate reads "Test nn ... FRIENDS
--     ONLY" in the friends colour, its DoorPrompt carries its own OwnerId; Door(own slot, mode) and Door(its slot, a junk
--     mode) answer false and change nothing. With the real check (FriendCheck(nil) -> "real"): friends + Enter(false) ->
--     refused with copy 1.17; friends + Enter(nil) -> refused at once (a stand-in's made-up id is nobody's friend, and
--     IsFriendsWith never runs on it); friends + Enter(true) -> on its landing, then Leave. With a stub that says friend
--     (FriendCheck({ kind = "answer", value = true })): locked + Enter(true) and locked + Enter(nil) -> refused with copy
--     1.16; open + Enter(false) and open + Enter(nil) -> in; the stub never ran (only a "friends" door asks).
--     Every stub is a named spec built server-side by the rooms hook (fix 1, I1: no function crosses the BindableFunction),
--     and its calls are read from the hook's FriendCalls ({ calls, done }, the stub's own counter).
-- (4) the friend check stubbed. (a) { kind = "error" }: two presses, each refused well under 2 s, two stub calls (an error
--     is never cached), two 1.17 toasts. (b) { kind = "sleep", seconds = 5, value = true }: a press is refused at about 2 s
--     (1.7 - 3.0); a second press 0.5 s later shares that check (one stub call), is refused within 1.7 - 3.0 s of its own
--     press and 2.2 - 3.0 s after the first; two 1.17 toasts (the timeouts' not-a-friend is never cached). Once the stub's
--     late "friend" is in (FriendCalls' done), a third press enters from the cache (fix 1, I2: a late real answer is cached;
--     still one call, no toast), then Leave. (c) { kind = "answer", value = true } (FriendCheck clears the cache, b's late
--     true with it): in (one call), Leave, in again from the cache (no second call). (d) { kind = "answer", value = false }:
--     two presses refused, one call (a real false is cached too). (e) { kind = "sleep", seconds = 1, value = true }, and the
--     owner locks the door 0.3 s into the check (fix 1, M1): the press reads the mode again and is refused with copy 1.16.
-- (5) the owner always enters: their own door locked, a counting stub installed: Enter(own slot, nil) and Enter(own slot,
--     false) put them on their landing; the stub never ran.
-- (6) a visit lasts only while the owner is online: the stand-in's door open, the player on its landing; Unfill (its owner
--     leaves) -> the player at the hall's HallSpawn, InPlot 0, the toast "Test nn left the server" (copy 1.19); the plate free
--     again ("STUDIO nn" in its own colour), the plot gone.
-- (7) the owner leaves while a press waits for the check (fix 1, M2): a new stand-in (Fill(1)), { kind = "sleep", seconds = 1,
--     value = true }, Unfill 0.3 s into the press -> refused, and told "Test nn left the server" (copy 1.19), nothing else.
-- On any error, and after success: unseated in the lounge, the real friend check back, Unfill, everything else reset (hold on,
-- Quiet off), the rooms Reset (after the career Reset, which replaces prof.career), then the home as the file found it (its
-- door mode with it); the error is rethrown.
local RS, Players, SSS = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("ServerScriptService")
local CS = game:GetService("CollectionService")
local p = Players:GetPlayers()[1]; assert(p, "no player")
local uid = p.UserId
local SOK = SSS.OK
local rooms = SOK:WaitForChild("_StudioRoomsHook", 5); assert(rooms, "no _StudioRoomsHook (is Systems/Rooms synced and started?)")
local wi = SOK:WaitForChild("_StudioWalkInHook", 5); assert(wi, "no _StudioWalkInHook (did WalkIns.Init run?)")
local ph = SOK:WaitForChild("_StudioPhoneHook", 5); assert(ph, "no _StudioPhoneHook (did Phone.Init run?)")
local career = SOK:WaitForChild("_StudioCareerHook", 5); assert(career, "no _StudioCareerHook")
local life = SOK:WaitForChild("_StudioLifeHook", 5); assert(life, "no _StudioLifeHook (did Life.Init run?)")
local test = SOK:WaitForChild("_StudioTestHook", 5); assert(test, "no _StudioTestHook (is Main running in Studio?)")
local Config = require(RS.OK.Config)
local Rules = require(RS.OK.Modules.RoomRules)
local RoomBuild = require(RS.OK.Modules.RoomBuild)
local Copy = RoomBuild.Copy
local Cfg = Config.Rooms
local LOUNGE = Vector3.new(24, 3, 0)
local RED = " (before the R-T14 sync of Systems/Rooms and OK/RoomClient: the expected red)"
-- research/rooms/copy_2026-11-12.md §10, literal: the test holds Systems/Rooms to the doc
local DOOR_ACTION, DOOR_OBJECT = "Door: {MODE}", "Who can come in" -- 10.4, 10.5
local DOOR_TOAST = { -- 10.6 - 10.8
	open = "door open. anyone can come in.",
	friends = "friends only. your friends can come in.",
	locked = "door locked. only you can come in.",
}
-- the plate's colour by mode (the controller's R-T14 ruling; Systems/Rooms' PLATE_COLORS)
local COLORS = { open = Color3.fromRGB(90, 200, 120), friends = Color3.fromRGB(240, 190, 70), locked = Color3.fromRGB(230, 80, 80) }
local out = {}
local T0 = os.clock()
local homeBefore -- the saved home as the file found it, put back at the end

local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function root() local c = p.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = p.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function flat(v) return math.sqrt(v.X * v.X + v.Z * v.Z) end
local function str(v) return typeof(v) == "Vector3" and string.format("(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z) or tostring(v) end
local function teleport(pos) -- the test's own move; checked, and tried once more if the client's position won
	for _ = 1, 2 do
		local c = p.Character or p.CharacterAdded:Wait()
		c:WaitForChild("HumanoidRootPart", 5)
		c:PivotTo(CFrame.new(pos))
		task.wait(0.3)
		local r = root()
		if r and flat(r.Position - pos) < 2 then return r end
	end
	error("teleport to " .. tostring(pos) .. " did not take")
end
local function unseat()
	local h = hum()
	if h and (h.Sit or h.SeatPart) then h.Sit = false; task.wait(0.4) end
end
local function call(cmd, a, b) return rooms:Invoke(cmd, uid, a, b) end
local function show(v) local okJ, js = pcall(function() return game:GetService("HttpService"):JSONEncode(v) end); return okJ and js or tostring(v) end
local function fill(line, t) -- Systems/Rooms' own fill: {key} from t, an unknown key left as it is
	return (string.gsub(line, "{(%w+)}", function(key)
		local v = t[key]
		if v == nil then return nil end
		return tostring(v)
	end))
end
local function nn(k) return string.format("%02d", k) end
local function rgb(c) return string.format("(%d, %d, %d)", math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255)) end
local function sameColor(a, b) return math.abs(a.R - b.R) < 0.01 and math.abs(a.G - b.G) < 0.01 and math.abs(a.B - b.B) < 0.01 end
local function sent() local s = call("Sent"); return type(s) == "table" and s or {} end -- the rooms toasts since the last read
local function count(list, text) local n = 0; for _, t in ipairs(list) do if t == text then n += 1 end end; return n end
local function plotModel(k) local f = workspace:FindFirstChild("OK_Plots"); return f and f:FindFirstChild("Plot_" .. nn(k)) end
local function hall() local r = workspace:FindFirstChild("OK_Rooms"); return r and r:FindFirstChild("Hall") end
local function attachment(parent, name)
	local a = parent and parent:FindFirstChild(name)
	assert(a and a:IsA("Attachment"), "no Attachment " .. name .. " under " .. tostring(parent and parent:GetFullName()))
	return a.WorldPosition
end
local function hallLabel(k)
	local h = hall()
	local pl = h and h:FindFirstChild("Plate_" .. nn(k))
	local gui = pl and pl:FindFirstChild("Text")
	local label = gui and gui:FindFirstChild("Label")
	assert(label and label:IsA("TextLabel"), "the hall has no Plate_" .. nn(k) .. ".Text.Label (run build/19_rooms.lua in Edit)")
	return label
end
local function hallDoor(k) local h = hall(); return h and h:FindFirstChild("Door_" .. nn(k)) end
local function frontDoor(k)
	local m = plotModel(k)
	local l = m and m:FindFirstChild("Landing")
	local f = l and l:FindFirstChild("FrontDoor")
	assert(f and f:IsA("BasePart"), "Plot_" .. nn(k) .. " has no Landing.FrontDoor")
	return f
end
local function doorPrompt(k, label)
	local pp = frontDoor(k):FindFirstChild("DoorPrompt")
	assert(pp and pp:IsA("ProximityPrompt"), label .. ": plot " .. nn(k) .. "'s landing FrontDoor has no DoorPrompt" .. RED)
	return pp
end
-- where a prompt's parent stands: a part's position, an attachment's, a model's pivot; nil for anything else (fix 1, M5)
local function where(inst)
	if inst and inst:IsA("BasePart") then return inst.Position end
	if inst and inst:IsA("Attachment") then return inst.WorldPosition end
	if inst and inst:IsA("Model") then return inst:GetPivot().Position end
	return nil
end
-- waits until the root stands within `tol` studs (flat) of `pos`
local function arrive(pos, label, tol)
	tol = tol or 3
	local ok = waitFor(function() local r = root(); return r ~= nil and flat(r.Position - pos) < tol end, 3)
	local r = root()
	assert(ok, label .. ": want the player within " .. tol .. " studs of " .. str(pos) .. ", got " .. (r and str(r.Position) or "no character")
		.. (r and string.format(" (%.1f away)", flat(r.Position - pos)) or ""))
end
local function inPlot(want, label)
	local v = call("InPlot")
	assert(v == want, label .. ": InPlot reads " .. tostring(v) .. ", want " .. want)
end
-- plate k shows `name`'s door in `mode`: its words (copy 1.9) and their colour
local function plateShows(k, name, mode, label)
	local lbl = hallLabel(k)
	local want = fill(Copy.PlateOwned, { player = name, slot = nn(k), MODE = Copy.Modes[mode] })
	assert(lbl.Text == want, string.format("%s: plate %s reads %q, want %q%s", label, nn(k), lbl.Text, want, RED))
	assert(sameColor(lbl.TextColor3, COLORS[mode]), string.format("%s: plate %s's words are %s, want the %s colour %s%s",
		label, nn(k), rgb(lbl.TextColor3), mode, rgb(COLORS[mode]), RED))
end
-- plot k's DoorPrompt reads `mode` (copy 10.4)
local function promptShows(k, mode, label)
	local pp = doorPrompt(k, label)
	local want = fill(DOOR_ACTION, { MODE = Copy.Modes[mode] })
	assert(pp.ActionText == want, string.format("%s: plot %s's DoorPrompt reads %q, want %q%s", label, nn(k), pp.ActionText, want, RED))
end
-- a named stub for the friend check, built server-side by the rooms hook (R-T14 fix 1, I1): spec = { kind = "answer", value }
-- | { kind = "error" } | { kind = "sleep", seconds, value }; its own counter starts at { calls = 0, done = 0 }
local function stub(spec, label)
	local st = call("FriendCheck", spec)
	assert(st == "stub", label .. ": FriendCheck(" .. show(spec) .. ") answered " .. show(st) .. ", want 'stub'" .. RED)
end
-- the current stub's counter: calls made, calls finished
local function friendCalls(label)
	local c = call("FriendCalls")
	assert(type(c) == "table" and type(c.calls) == "number" and type(c.done) == "number", label .. ": FriendCalls answered " .. show(c) .. ", want { calls, done }" .. RED)
	return c
end
-- the owner's door press (the hook's Door), paced DOOR_GAP after the last one: Systems/Rooms ignores a press within its
-- 0.25 s DOOR_COOLDOWN of the last cycle (R-T14 fix 1, M3)
local DOOR_GAP = 0.35
local lastDoorCall = -math.huge
local function door()
	local pause = DOOR_GAP - (os.clock() - lastDoorCall)
	if pause > 0 then task.wait(pause) end
	local res = call("Door")
	lastDoorCall = os.clock()
	return res
end
local function homeDoor(label)
	local h = call("Home")
	assert(type(h) == "table", label .. ": Home answered " .. show(h))
	return h.door
end
local function stateDoor(label)
	local s = call("State")
	assert(type(s) == "table", label .. ": State answered " .. show(s))
	return s.door
end
-- a hall door press through the hook (Enter(slot, asFriend): true / false answers the friend check, nil runs it); the
-- answer and how long it took
local function enter(k, asFriend)
	local t = os.clock()
	local r = call("Enter", k, asFriend)
	return r, os.clock() - t
end
-- Leave from plot k's landing: in front of hall door k, InPlot 0
local function leaveTo(k, label)
	assert(call("Leave") == true, label .. ": Leave returned false")
	arrive(attachment(hallDoor(k), "Front"), label .. " (Leave)")
	inPlot(0, label .. " (Leave)")
end
-- the file's own fresh(): unseated in the lounge, Quiet on, the phone, WalkIns, Career and Life reset, no hint seen,
-- the rooms hook's Reset (slot claimed, plot rebuilt; the friend check's stub and cache gone)
local function fresh(label)
	unseat()
	teleport(LOUNGE)
	assert(ph:Invoke("Quiet", uid, true) == true, label .. ": Quiet(true) failed")
	assert(ph:Invoke("Reset", uid) == true, label .. ": phone Reset failed")
	assert(wi:Invoke("Reset", uid) == true, label .. ": WalkIns Reset failed")
	assert(career:Invoke("Reset", uid) == true, label .. ": Career Reset failed")
	assert(life:Invoke("Reset", uid) == true, label .. ": Life Reset failed")
	assert(test:Invoke("ResetHints", uid) == true, label .. ": ResetHints failed")
	assert(call("Reset") == true, label .. ": the rooms hook's Reset failed (no slot, or the plot did not build)")
end

local function run()
	homeBefore = call("Home") -- first, before anything changes (put back at the end)
	assert(wi:Invoke("Pause", uid, true) == true, "Pause(true) failed")
	fresh("doors")
	local info = call("Plot")
	assert(type(info) == "table" and type(info.slot) == "number", "Plot answered " .. show(info) .. ", want { slot, ... }")
	local k1 = info.slot
	local me = p.DisplayName
	assert(Cfg.DoorDefault == "friends", "premise: Config.Rooms.DoorDefault is " .. tostring(Cfg.DoorDefault) .. ", want friends")
	assert(Rules.NextDoorMode("friends", Cfg.DoorModes) == "locked" and Rules.NextDoorMode("locked", Cfg.DoorModes) == "open"
		and Rules.NextDoorMode("open", Cfg.DoorModes) == "friends", "premise: RoomRules.NextDoorMode over Config.Rooms.DoorModes is not friends -> locked -> open -> friends")

	-- 1. a fresh home: friends only, the owner's DoorPrompt, the plate
	assert(homeDoor("1") == "friends", "1: a fresh home's door reads " .. tostring(homeDoor("1")) .. ", want friends")
	assert(stateDoor("1") == "friends", "1: State's door reads " .. tostring(stateDoor("1")) .. ", want friends")
	local front = frontDoor(k1)
	local dp = doorPrompt(k1, "1")
	assert(not CS:HasTag(front, "OK_Interactable") and not CS:HasTag(dp, "OK_Interactable"), "1: the FrontDoor or its DoorPrompt is tagged OK_Interactable, want untagged (Systems/Rooms hooks it)")
	assert(dp.ActionText == fill(DOOR_ACTION, { MODE = Copy.Modes.friends }) and dp.ObjectText == DOOR_OBJECT,
		string.format("1: the DoorPrompt reads %q / %q, want %q / %q", dp.ActionText, dp.ObjectText, fill(DOOR_ACTION, { MODE = Copy.Modes.friends }), DOOR_OBJECT))
	assert(dp.KeyboardKeyCode == Enum.KeyCode.F and dp.GamepadKeyCode == Enum.KeyCode.ButtonY,
		"1: the DoorPrompt's keys are " .. tostring(dp.KeyboardKeyCode) .. " / " .. tostring(dp.GamepadKeyCode) .. ", want F / ButtonY (the LeavePrompt beside it has E)")
	assert(dp.Enabled and dp.HoldDuration == 0 and dp.RequiresLineOfSight == false and dp.MaxActivationDistance == Config.Interaction.MaxDistance,
		string.format("1: the DoorPrompt is Enabled %s, hold %s, line of sight %s, reach %s; want on, 0, false, %s (the house style)",
			tostring(dp.Enabled), tostring(dp.HoldDuration), tostring(dp.RequiresLineOfSight), tostring(dp.MaxActivationDistance), tostring(Config.Interaction.MaxDistance)))
	assert(dp:GetAttribute("OwnerId") == uid, "1: the DoorPrompt's OwnerId is " .. tostring(dp:GetAttribute("OwnerId")) .. ", want " .. uid .. " (RoomClient turns off the ones you don't own)")
	local lp = front:FindFirstChild("LeavePrompt")
	assert(lp and lp:IsA("ProximityPrompt") and lp.KeyboardKeyCode == Enum.KeyCode.E and lp.GamepadKeyCode == Enum.KeyCode.ButtonX,
		"1: the FrontDoor's LeavePrompt is missing or no longer on E / ButtonX")
	local gap = lp.UIOffset - dp.UIOffset
	assert(math.abs(gap.X) < 0.5 and math.abs(gap.Y - RoomBuild.RACK_UI_GAP) < 0.5, string.format(
		"1: the DoorPrompt sits (%.0f, %.0f) px from the LeavePrompt, want (0, -%d): stacked over it, the two tap targets apart", -gap.X, -gap.Y, RoomBuild.RACK_UI_GAP))
	local reach = Config.Interaction.MaxDistance
	local nearest = math.huge
	for _, d in ipairs(plotModel(k1):GetDescendants()) do
		if d:IsA("ProximityPrompt") and d ~= dp and (d.KeyboardKeyCode == dp.KeyboardKeyCode or d.GamepadKeyCode == dp.GamepadKeyCode) then
			local at = where(d.Parent)
			assert(at, "1: " .. d:GetFullName() .. " shares the DoorPrompt's key, and its parent (a " .. tostring(d.Parent and d.Parent.ClassName) .. ") can't be placed")
			local dist = (at - front.Position).Magnitude
			nearest = math.min(nearest, dist)
			assert(dist > 2 * reach, string.format("1: %s shares the DoorPrompt's key and stands %.1f studs from the front door, want more than %d (never both in reach)",
				d:GetFullName(), dist, 2 * reach))
		end
	end
	plateShows(k1, me, "friends", "1")
	table.insert(out, string.format("1 fresh home: door friends (Home, State); FrontDoor DoorPrompt 'Door: FRIENDS ONLY' / 'Who can come in' on F / ButtonY, untagged, OwnerId the player's, %d px over the LeavePrompt (E); the nearest other F / ButtonY prompt in the plot is %.1f studs from the front door; plate %s '%s' in the friends colour",
		RoomBuild.RACK_UI_GAP, nearest, nn(k1), (string.gsub(hallLabel(k1).Text, "\n", " / "))))

	-- 2. the owner's cycle, saved each time
	sent(); call("Pushed")
	for i, want in ipairs({ "locked", "open", "friends" }) do
		local label = "2." .. i .. " " .. want
		local got = door()
		assert(got == want, label .. ": Door answered " .. show(got) .. ", want '" .. want .. "'" .. RED)
		assert(homeDoor(label) == want, label .. ": Home's door reads " .. tostring(homeDoor(label)) .. ", want " .. want .. " (saved)")
		assert(stateDoor(label) == want, label .. ": State's door reads " .. tostring(stateDoor(label)) .. ", want " .. want .. " (Room_Get's cache dropped)")
		plateShows(k1, me, want, label)
		promptShows(k1, want, label)
		local ts = sent()
		assert(#ts == 1 and ts[1] == DOOR_TOAST[want], label .. ": the toasts were " .. show(ts) .. ", want only " .. show(DOOR_TOAST[want]))
		local log = call("Pushed")
		local last
		for _, e in ipairs(type(log) == "table" and log or {}) do if e.kind == "state" then last = e.payload end end
		assert(type(last) == "table" and last.door == want, label .. ": the last pushed state's door is " .. tostring(type(last) == "table" and last.door or last) .. ", want " .. want)
	end
	-- two presses back to back: the second is inside the cooldown (fix 1, M3) and does nothing. Up to three pairs (fix 2): a
	-- pair that takes 0.25 s or more can't tell the cooldown apart, so the door goes back to locked and a pair runs again; the
	-- check is skipped only when all three pairs are that slow. The pair's first press cycles from wherever the door stands
	local function toLocked(label)
		for _ = 1, 3 do
			if homeDoor(label) == "locked" then break end
			door()
		end
		assert(homeDoor(label) == "locked", label .. ": could not bring the door back to locked")
	end
	local quickNote
	local spans = {}
	for try = 1, 3 do
		local label = "2 pair " .. try
		local want = Rules.NextDoorMode(homeDoor(label), Cfg.DoorModes)
		sent()
		task.wait(DOOR_GAP)
		local tq = os.clock()
		local press1 = call("Door")
		local quick = call("Door")
		local span = os.clock() - tq
		lastDoorCall = os.clock()
		table.insert(spans, string.format("%.2f", span))
		assert(press1 == want, label .. ": the pair's first press answered " .. show(press1) .. ", want '" .. want .. "'")
		if span < 0.25 then -- both presses inside 0.25 s, so the second came within the cooldown of the first's cycle
			assert(quick == false, string.format("%s: a press sent straight after a cycle (both inside %.2f s) answered %s, want false (ignored: the 0.25 s cooldown)%s", label, span, show(quick), RED))
			assert(homeDoor(label) == want, label .. ": the ignored press moved the door to " .. tostring(homeDoor(label)) .. ", want it still " .. want)
			local tsq = sent()
			assert(#tsq == 1 and tsq[1] == DOOR_TOAST[want], label .. ": the two quick presses toasted " .. show(tsq) .. ", want only the first's '" .. DOOR_TOAST[want] .. "'")
			quickNote = string.format("pair %d sent straight after a cycle (both within %.2f s): the second answered false, no toast, the door still %s", try, span, want)
			break
		end
		toLocked(label .. " (slow)") -- a slow pair: its second press may have cycled too
	end
	toLocked("2 after the pairs")
	sent()
	quickNote = quickNote or ("all three back-to-back pairs took 0.25 s or more (" .. table.concat(spans, ", ") .. " s: a slow server): the cooldown check was skipped")
	call("Pushed")
	assert(call("Release") == true, "2: Release returned false")
	local noSlot = door()
	assert(noSlot == false, "2: Door with no slot answered " .. show(noSlot) .. ", want false")
	assert(#sent() == 0, "2: Door with no slot toasted something")
	assert(call("Claim") == k1, "2: Claim did not give slot " .. k1 .. " back")
	assert(waitFor(function() return plotModel(k1) ~= nil end, 5), "2: no Plot_" .. nn(k1) .. " after Claim")
	assert(homeDoor("2 rebuilt") == "locked", "2: after Release and Claim Home's door reads " .. tostring(homeDoor("2 rebuilt")) .. ", want locked (saved)")
	plateShows(k1, me, "locked", "2 rebuilt")
	promptShows(k1, "locked", "2 rebuilt")
	assert(doorPrompt(k1, "2 rebuilt"):GetAttribute("OwnerId") == uid, "2: the rebuilt plot's DoorPrompt is not stamped with the player's id")
	assert(door() == "open" and door() == "friends", "2: two more presses did not come back to friends")
	assert(homeDoor("2 back") == "friends", "2: Home's door reads " .. tostring(homeDoor("2 back")) .. " after the full cycle, want friends")
	sent(); call("Pushed")
	table.insert(out, "2 Door: friends -> locked -> open -> friends, each saved (Home, State), on the plate (words and colour) and the prompt, one copy 10.6-10.8 toast and a pushed state each; locked again, and " .. quickNote .. "; with no slot Door answers false; Release + Claim rebuilt the plot with the saved LOCKED")

	-- 3. a stand-in owner's door
	local freeColor = {}
	for k = 1, Cfg.Slots do
		local lbl = hallLabel(k)
		if lbl.Text == fill(Copy.PlateEmpty, { slot = nn(k) }) then freeColor[k] = lbl.TextColor3 end
	end
	assert(call("Fill", 1) == 1, "3: Fill(1) did not build a plot for a stand-in owner")
	local k2, other
	for k = 1, Cfg.Slots do
		local m = plotModel(k)
		if m and k ~= k1 and m:GetAttribute("OwnerId") ~= uid then k2, other = k, m; break end
	end
	assert(k2, "3: no plot for the stand-in owner after Fill(1)")
	local fakeId, fakeName = other:GetAttribute("OwnerId"), other:GetAttribute("OwnerName")
	assert(type(fakeId) == "number" and fakeId ~= uid and type(fakeName) == "string" and utf8.len(fakeName) <= 10,
		"premise: the stand-in's OwnerId / OwnerName are " .. tostring(fakeId) .. " / " .. tostring(fakeName) .. " (a name of 10 characters or fewer, so the toast's {player} is whole)")
	assert(freeColor[k2], "premise: plate " .. nn(k2) .. " was not free before Fill")
	plateShows(k2, fakeName, "friends", "3 stand-in")
	promptShows(k2, "friends", "3 stand-in")
	assert(doorPrompt(k2, "3 stand-in"):GetAttribute("OwnerId") == fakeId, "3: the stand-in's DoorPrompt is not stamped with its owner's id " .. tostring(fakeId))
	local d1 = call("Door", k1, "open")
	assert(d1 == false, "3: Door(own slot, open) answered " .. show(d1) .. ", want false (only a stand-in's mode is set that way)")
	local d2 = call("Door", k2, "ajar")
	assert(d2 == false, "3: Door(" .. k2 .. ", ajar) answered " .. show(d2) .. ", want false (a junk mode)")
	assert(homeDoor("3") == "friends", "3: the refused Door calls moved the player's door")
	plateShows(k2, fakeName, "friends", "3 after the refused Door calls")
	local toastFriends = fill(Copy.FriendsOnly, { player = fakeName })
	local toastLocked = fill(Copy.Locked, { player = fakeName })
	local inside2 = attachment(frontDoor(k2), "Inside")
	local real = call("FriendCheck", nil)
	assert(real == "real", "3: FriendCheck(nil) answered " .. show(real) .. ", want 'real'" .. RED)
	sent()
	local r = call("Enter", k2, false)
	assert(r == false, "3a: friends + not a friend: Enter answered " .. show(r) .. ", want false")
	local ts = sent()
	assert(#ts == 1 and ts[1] == toastFriends, "3a: the toasts were " .. show(ts) .. ", want only '" .. toastFriends .. "' (copy 1.17)")
	inPlot(0, "3a")
	local r3b, dt3b = enter(k2, nil)
	assert(r3b == false and dt3b < 0.5, string.format("3b: friends + the real check for a stand-in: Enter answered %s after %.2f s, want false at once (a made-up id is nobody's friend)%s", show(r3b), dt3b, RED))
	ts = sent()
	assert(#ts == 1 and ts[1] == toastFriends, "3b: the toasts were " .. show(ts) .. ", want only '" .. toastFriends .. "'")
	r = call("Enter", k2, true)
	assert(r == true, "3c: friends + a friend: Enter answered " .. show(r) .. ", want true")
	arrive(inside2, "3c: Enter as a friend")
	inPlot(k2, "3c")
	leaveTo(k2, "3c")
	stub({ kind = "answer", value = true }, "3")
	assert(call("Door", k2, "locked") == "locked", "3d: Door(" .. k2 .. ", locked) did not answer locked" .. RED)
	plateShows(k2, fakeName, "locked", "3d")
	promptShows(k2, "locked", "3d")
	sent()
	r = call("Enter", k2, true)
	assert(r == false, "3d: locked + a friend: Enter answered " .. show(r) .. ", want false")
	r = call("Enter", k2, nil)
	assert(r == false, "3d: locked + the (friendly) stub: Enter answered " .. show(r) .. ", want false")
	ts = sent()
	assert(#ts == 2 and ts[1] == toastLocked and ts[2] == toastLocked, "3d: the toasts were " .. show(ts) .. ", want '" .. toastLocked .. "' twice (copy 1.16)")
	assert(call("Door", k2, "open") == "open", "3e: Door(" .. k2 .. ", open) did not answer open")
	plateShows(k2, fakeName, "open", "3e")
	promptShows(k2, "open", "3e")
	r = call("Enter", k2, false)
	assert(r == true, "3e: open + not a friend: Enter answered " .. show(r) .. ", want true")
	arrive(inside2, "3e: Enter(false) at an open door")
	leaveTo(k2, "3e")
	r = call("Enter", k2, nil)
	assert(r == true, "3e: open + the check: Enter answered " .. show(r) .. ", want true")
	arrive(inside2, "3e: Enter(nil) at an open door")
	leaveTo(k2, "3e again")
	local never = friendCalls("3").calls
	assert(never == 0, "3: the friend check ran " .. never .. " times at a locked or open door, want never (only friends asks)")
	ts = sent()
	assert(#ts == 0, "3e: an open door toasted " .. show(ts))
	assert(call("Door", k2, "friends") == "friends", "3: Door(" .. k2 .. ", friends) did not answer friends")
	table.insert(out, string.format("3 stand-in %s (slot %s, id %d): plate and prompt FRIENDS ONLY; Door(own, open) and Door(%d, ajar) false; real check: Enter(false) and Enter(nil) refused '%s' (nil in %.2f s, no IsFriendsWith on a made-up id), Enter(true) in; locked: refused '%s' as a friend and through the stub; open: in with false and nil; the stub never ran",
		fakeName, nn(k2), fakeId, k2, toastFriends, dt3b, toastLocked))

	-- 4. the friend check, stubbed
	-- (a) an erroring check: refused at once, never cached
	stub({ kind = "error" }, "4a")
	sent()
	local errTimes = {}
	for i = 1, 2 do
		local dt
		r, dt = enter(k2, nil)
		assert(r == false and dt < 0.5, string.format("4a press %d: an erroring check: Enter answered %s after %.2f s, want refused well under 2 s", i, show(r), dt))
		local n = friendCalls("4a").calls
		assert(n == i, string.format("4a press %d: the stub ran %d times, want %d (an error is never cached: the next press asks again)", i, n, i))
		table.insert(errTimes, string.format("%.2f", dt))
	end
	ts = sent()
	assert(#ts == 2 and count(ts, toastFriends) == 2, "4a: the toasts were " .. show(ts) .. ", want '" .. toastFriends .. "' twice")
	inPlot(0, "4a")
	table.insert(out, "4a erroring check: two presses refused in " .. table.concat(errTimes, " and ") .. " s, two stub calls (not cached), two friends-only toasts")
	-- (b) a check that sleeps 5 s: refused at about 2 s; a second press shares it; the late real answer is cached (fix 1, I2)
	stub({ kind = "sleep", seconds = 5, value = true }, "4b")
	sent()
	local first = {}
	local t0 = os.clock()
	task.spawn(function()
		local ok, res = pcall(call, "Enter", k2, nil)
		first.ok, first.r, first.at = ok, res, os.clock() - t0
	end)
	task.wait(0.5)
	local t2 = os.clock()
	local ok2, r2 = pcall(call, "Enter", k2, nil)
	local own2, from1 = os.clock() - t2, os.clock() - t0
	assert(waitFor(function() return first.at ~= nil end, 4), "4b: the first press never answered")
	assert(first.ok and ok2, "4b: a press threw: " .. tostring(first.r) .. " / " .. tostring(r2))
	assert(first.r == false and first.at >= 1.7 and first.at <= 3.0, string.format("4b: the first press answered %s after %.2f s, want refused at about 2 s (1.7 - 3.0)%s", show(first.r), first.at, RED))
	assert(r2 == false and own2 >= 1.7 and own2 <= 3.0 and from1 >= 2.2 and from1 <= 3.0, string.format(
		"4b: the second press (made %.2f s after the first) answered %s %.2f s after it was made, %.2f s after the first press; want refused within 1.7 - 3.0 s of its own press and 2.2 - 3.0 s of the first",
		t2 - t0, show(r2), own2, from1))
	local nb = friendCalls("4b").calls
	assert(nb == 1, string.format("4b: the stub ran %d times for two overlapping presses, want 1 (the second shares the check in flight)", nb))
	ts = sent()
	assert(#ts == 2 and count(ts, toastFriends) == 2, "4b: the toasts were " .. show(ts) .. ", want '" .. toastFriends .. "' twice (no press dropped)")
	inPlot(0, "4b")
	assert(waitFor(function() return friendCalls("4b").done >= 1 end, 4), "4b: the sleeping stub never returned")
	task.wait(0.1)
	local r3, dt3 = enter(k2, nil)
	assert(r3 == true, string.format("4b: after the stub's late 'friend', a third press answered %s after %.2f s, want true from the cache (a late real answer is cached)%s", show(r3), dt3, RED))
	local n3 = friendCalls("4b").calls
	assert(n3 == 1, "4b: the third press asked again: the stub ran " .. n3 .. " times, want 1 (the late answer should have been cached)" .. RED)
	arrive(inside2, "4b: the third press")
	inPlot(k2, "4b third press")
	ts = sent()
	assert(#ts == 0, "4b: the third press toasted " .. show(ts))
	leaveTo(k2, "4b")
	table.insert(out, string.format("4b sleeping check (5 s): the first press refused at %.2f s; the second, made %.2f s later, refused %.2f s after its own press (%.2f s after the first); one stub call for both, two toasts; once the late 'friend' was in, a third press entered from the cache (%.2f s with the move, still one call)",
		first.at, t2 - t0, own2, from1, dt3))
	-- (c) a friend: in, cached for the next press
	stub({ kind = "answer", value = true }, "4c") -- clears the cache: 4b's late true goes with it, so the first press asks
	sent()
	for i = 1, 2 do
		r = call("Enter", k2, nil)
		assert(r == true, "4c press " .. i .. ": a friend (the stub says so): Enter answered " .. show(r) .. ", want true")
		arrive(inside2, "4c press " .. i)
		inPlot(k2, "4c press " .. i)
		leaveTo(k2, "4c press " .. i)
	end
	local nc = friendCalls("4c").calls
	assert(nc == 1, "4c: the stub ran " .. nc .. " times for two presses, want 1 (a real answer is cached for the session; FriendCheck must clear 4b's)")
	ts = sent()
	assert(#ts == 0, "4c: a friend's presses toasted " .. show(ts))
	-- (d) not a friend: FriendCheck cleared (c)'s true; the real false is cached
	stub({ kind = "answer", value = false }, "4d")
	for i = 1, 2 do
		r = call("Enter", k2, nil)
		assert(r == false, "4d press " .. i .. ": not a friend (the stub says so): Enter answered " .. show(r) .. ", want false (FriendCheck must clear the cached true)")
	end
	local nd = friendCalls("4d").calls
	assert(nd == 1, "4d: the stub ran " .. nd .. " times for two presses, want 1 (a real false is cached too)")
	ts = sent()
	assert(#ts == 2 and count(ts, toastFriends) == 2, "4d: the toasts were " .. show(ts) .. ", want '" .. toastFriends .. "' twice")
	table.insert(out, "4c a friend: in twice, one stub call (cached); 4d after FriendCheck cleared it, not a friend: refused twice, one call (a real false cached too)")
	-- (e) the owner locks the door while a friend's check runs (fix 1, M1): the press reads the mode again
	stub({ kind = "sleep", seconds = 1, value = true }, "4e")
	sent()
	local e = {}
	local te = os.clock()
	task.spawn(function()
		local ok, res = pcall(call, "Enter", k2, nil)
		e.ok, e.r, e.at = ok, res, os.clock() - te
	end)
	task.wait(0.3)
	assert(call("Door", k2, "locked") == "locked", "4e: Door(" .. k2 .. ", locked) did not answer locked")
	assert(waitFor(function() return e.at ~= nil end, 3), "4e: the press never answered")
	assert(e.ok and e.r == false, string.format("4e: the press answered %s after %.2f s, want false: the check said friend, but the door was locked while it ran%s", tostring(e.r), e.at, RED))
	ts = sent()
	assert(#ts == 1 and ts[1] == toastLocked, "4e: the toasts were " .. show(ts) .. ", want only '" .. toastLocked .. "' (copy 1.16)" .. RED)
	assert(friendCalls("4e").calls == 1, "4e: the stub ran " .. friendCalls("4e").calls .. " times, want 1")
	inPlot(0, "4e")
	assert(call("Door", k2, "friends") == "friends", "4e: Door(" .. k2 .. ", friends) did not answer friends")
	assert(call("FriendCheck", nil) == "real", "4: FriendCheck(nil) did not put the real check back")
	table.insert(out, string.format("4e the door locked 0.3 s into a friend's 1 s check: the press refused at %.2f s with '%s'", e.at, toastLocked))

	-- 5. the owner always enters
	stub({ kind = "answer", value = false }, "5")
	sent()
	local lockedOwn = door()
	assert(lockedOwn == "locked", "5: Door answered " .. show(lockedOwn) .. ", want 'locked'" .. RED)
	local inside1 = attachment(frontDoor(k1), "Inside")
	r = call("Enter", k1, nil)
	assert(r == true, "5: the owner at their own locked door: Enter(nil) answered " .. show(r) .. ", want true (the owner always enters)")
	arrive(inside1, "5: the owner's Enter(nil)")
	inPlot(k1, "5")
	r = call("Enter", k1, false)
	assert(r == true, "5: the owner at their own locked door: Enter(false) answered " .. show(r) .. ", want true")
	local nown = friendCalls("5").calls
	assert(nown == 0, "5: the friend check ran " .. nown .. " times for the owner, want never")
	ts = sent()
	assert(#ts == 1 and ts[1] == DOOR_TOAST.locked, "5: the toasts were " .. show(ts) .. ", want only the lock's '" .. DOOR_TOAST.locked .. "'")
	leaveTo(k1, "5")
	assert(door() == "open" and door() == "friends", "5: two presses did not bring the player's door back to friends")
	assert(call("FriendCheck", nil) == "real", "5: FriendCheck(nil) did not put the real check back")
	sent(); call("Pushed")
	table.insert(out, "5 the owner at their own locked door: Enter(nil) and Enter(false) in, the friend check never ran")

	-- 6. a visit lasts only while the owner is online
	assert(call("Door", k2, "open") == "open", "6: Door(" .. k2 .. ", open) did not answer open" .. RED)
	r = call("Enter", k2, nil)
	assert(r == true, "6: the open stand-in door: Enter answered " .. show(r) .. ", want true")
	arrive(inside2, "6: on the stand-in's landing")
	inPlot(k2, "6")
	sent()
	local h = hall()
	local hs = h and h:FindFirstChild("HallSpawn")
	assert(hs and hs:IsA("BasePart"), "6: the hall has no HallSpawn")
	local gone = call("Unfill")
	assert(gone == 1, "6: Unfill released " .. show(gone) .. " stand-in plots, want 1")
	arrive(hs.Position, "6: the stand-in owner left")
	inPlot(0, "6 after the owner left")
	ts = sent()
	local leftToast = fill(Copy.OwnerLeft, { player = fakeName })
	assert(count(ts, leftToast) == 1, "6: the toasts were " .. show(ts) .. ", want one '" .. leftToast .. "' (copy 1.19)")
	assert(plotModel(k2) == nil, "6: Plot_" .. nn(k2) .. " is still there after its owner left")
	local lbl = hallLabel(k2)
	assert(lbl.Text == fill(Copy.PlateEmpty, { slot = nn(k2) }) and sameColor(lbl.TextColor3, freeColor[k2]), string.format(
		"6: plate %s reads %q in %s after its owner left, want %q in its own %s", nn(k2), lbl.Text, rgb(lbl.TextColor3), fill(Copy.PlateEmpty, { slot = nn(k2) }), rgb(freeColor[k2])))
	table.insert(out, string.format("6 the stand-in owner left with the player on its landing: the player at HallSpawn, InPlot 0, toast '%s'; plate %s free again in its own colour %s, the plot gone",
		leftToast, nn(k2), rgb(freeColor[k2])))

	-- 7. the owner leaves while a press waits for the friend check (fix 1, M2): the press is answered with copy 1.19
	assert(call("Fill", 1) == 1, "7: Fill(1) did not build a plot for a stand-in owner")
	local k3, other3
	for k = 1, Cfg.Slots do
		local m = plotModel(k)
		if m and k ~= k1 and m:GetAttribute("OwnerId") ~= uid then k3, other3 = k, m; break end
	end
	assert(k3, "7: no plot for the stand-in owner after Fill(1)")
	local name3 = other3:GetAttribute("OwnerName")
	assert(type(name3) == "string" and utf8.len(name3) <= 10, "premise: the stand-in's OwnerName is " .. tostring(name3) .. " (10 characters or fewer)")
	stub({ kind = "sleep", seconds = 1, value = true }, "7")
	sent()
	local g = {}
	local tg = os.clock()
	task.spawn(function()
		local ok, res = pcall(call, "Enter", k3, nil)
		g.ok, g.r, g.at = ok, res, os.clock() - tg
	end)
	task.wait(0.3)
	local gone3 = call("Unfill")
	assert(gone3 == 1, "7: Unfill released " .. show(gone3) .. " stand-in plots, want 1")
	assert(waitFor(function() return g.at ~= nil end, 3), "7: the press never answered")
	assert(g.ok and g.r == false, string.format("7: the press answered %s after %.2f s, want false (its owner left while it was asked)", tostring(g.r), g.at))
	ts = sent()
	local left3 = fill(Copy.OwnerLeft, { player = name3 })
	assert(#ts == 1 and ts[1] == left3, "7: the toasts were " .. show(ts) .. ", want only '" .. left3 .. "' (copy 1.19: the press is answered, not dropped)" .. RED)
	inPlot(0, "7")
	assert(call("FriendCheck", nil) == "real", "7: FriendCheck(nil) did not put the real check back")
	table.insert(out, string.format("7 the stand-in owner left 0.3 s into a friend's 1 s check: the press refused at %.2f s with '%s'", g.at, left3))

	return "T113A PLAY OK\n" .. table.concat(out, "\n") .. string.format("\nelapsed %.1f s", os.clock() - T0)
end

local okRun, msg = pcall(run)
pcall(unseat)
pcall(teleport, LOUNGE) -- first, so no release or rebuild below happens under the player
pcall(function() rooms:Invoke("FriendCheck", uid, nil) end) -- the real friend check, nothing cached
pcall(function() rooms:Invoke("Unfill", uid) end)
pcall(function()
	wi:Invoke("Pause", uid, true); wi:Invoke("Reset", uid); ph:Invoke("Reset", uid); career:Invoke("Reset", uid); life:Invoke("Reset", uid)
	test:Invoke("ResetHints", uid); ph:Invoke("Quiet", uid, false)
end)
pcall(function() rooms:Invoke("Reset", uid) end) -- after the career Reset (it replaces prof.career, the home with it)
pcall(function() if homeBefore then rooms:Invoke("SetHome", uid, homeBefore) end end) -- the home (its door mode) as the file found it
if not okRun then error(msg, 0) end
return msg
