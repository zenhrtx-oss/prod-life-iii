-- Client, during play (after t58a: LIL NAV X expired behind the open beat maker, his note on the "leave"): the note
-- card. Closing the beat maker (Command close) shows the note through the walk-in result card within 3 s: the headline
-- "<NAME> LEFT", the text "waited 5 minutes", his parting line as the note, neutral tone (ResultKey note); the three
-- labels fit and sit inside the frame; no choice card, chip or phone card is open; it hides by itself within 10 s.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui", 10)
local wg = pg:WaitForChild("OK_WalkIn", 10); assert(wg, "no OK_WalkIn gui")
local gui = pg:WaitForChild("OK_Phone", 10); assert(gui, "no OK_Phone gui")
local daw = pg.OK_DAW.DAW
local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); local cam = workspace.CurrentCamera
local Content = require(RS.OK.Data.WalkIns)
local name = Content.Names(require(RS.OK.Config).WalkIns.Roster).navx
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function rect(g) local p, s = g.AbsolutePosition, g.AbsoluteSize; return { x0 = p.X, y0 = p.Y, x1 = p.X + s.X, y1 = p.Y + s.Y } end
local function fmt(r) return string.format("(%d,%d)-(%d,%d)", r.x0, r.y0, r.x1, r.y1) end
wg:SetAttribute("ForceViewport", nil); daw:SetAttribute("CompactForced", nil)
assert(daw.Visible, "the beat maker should still be open from t57f")
local res, card, chip = wg:FindFirstChild("Result", true), wg:FindFirstChild("Card", true), wg:FindFirstChild("Waiting", true)
assert(res and card and chip, "Result, Card or Waiting missing")
assert(not res.Visible, "the result card is already showing with the beat maker open")
assert((wg:GetAttribute("Token") or "") == "", "the visit is still on the client (Token '" .. tostring(wg:GetAttribute("Token")) .. "'): t58a should have expired it")

daw:SetAttribute("Command", "close")
assert(waitFor(function() return not daw.Visible end, 3), "beat maker did not close")
if hum and hum.Sit then hum.Sit = false end
cam.CameraType = Enum.CameraType.Custom
local t0 = os.clock()
assert(waitFor(function() return res.Visible end, 3), "the note did not show within 3 s of closing the beat maker")
local shownAfter = os.clock() - t0
task.wait(0.3) -- let it render once so TextFits is current
local head, text, note = res:FindFirstChild("Headline"), res:FindFirstChild("Text"), res:FindFirstChild("Note")
assert(head and text and note, "Headline, Text or Note missing on the result card")
assert(head.Text == string.upper(name) .. " LEFT", "the headline reads '" .. tostring(head.Text) .. "' (want '" .. string.upper(name) .. " LEFT')")
assert(text.Text == "waited 5 minutes", "the text reads '" .. tostring(text.Text) .. "' (want 'waited 5 minutes')")
assert(note.Text ~= "" and note.Text:sub(1, 3) == "“", "the note (his line) reads '" .. tostring(note.Text) .. "'")
assert(wg:GetAttribute("ResultKey") == "note" and wg:GetAttribute("ResultTone") == "neutral",
	"ResultKey '" .. tostring(wg:GetAttribute("ResultKey")) .. "', ResultTone '" .. tostring(wg:GetAttribute("ResultTone")) .. "' (want note, neutral)")
local fr = rect(res)
for _, l in ipairs({ head, text, note }) do
	assert(l.TextFits, l.Name .. " doesn't fit the result frame: '" .. l.Text .. "'")
	local r = rect(l)
	assert(r.x0 >= fr.x0 and r.y0 >= fr.y0 and r.x1 <= fr.x1 and r.y1 <= fr.y1, l.Name .. " " .. fmt(r) .. " is outside the result frame " .. fmt(fr))
end
assert(wg:GetAttribute("Open") == false and not card.Visible and not chip.Visible, "a choice card or the chip is open with the note")
assert(gui:GetAttribute("Open") == false and gui:GetAttribute("Pending") == 0, "a phone card is open or a pop is held")
local out = { string.format("note %.1f s after closing the beat maker: %q / %q / %q, fits %s", shownAfter, head.Text, text.Text, note.Text, fmt(fr)) }
assert(waitFor(function() return not res.Visible end, 10), "the note did not hide by itself within 10 s")
table.insert(out, string.format("hid by itself %.1f s after showing", os.clock() - t0))
return "T58B PLAY OK\n" .. table.concat(out, "\n")
