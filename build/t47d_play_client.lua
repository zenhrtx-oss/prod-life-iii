-- Client, during play (after t47c): "defers while beat maker open". The cypher is idle and the beat maker is still
-- open from t47b, so when LIL NAV X arrives the card stays hidden and the Waiting chip shows instead. Then the beat
-- maker goes phone-sized (CompactForced): the card still waits, and the chip hides or at least covers no visible pad
-- (a tap there would open the card mid-beat); back to the desktop beat maker, the chip returns. The beat maker stays
-- open and the visit waiting for t47e / t47f.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui", 10)
local gui = pg:WaitForChild("OK_WalkIn", 10); assert(gui, "no OK_WalkIn gui")
local daw = pg.OK_DAW.DAW
local function waitFor(fn, t) local t1 = os.clock(); while os.clock() - t1 < (t or 5) do if fn() then return true end; task.wait(0.05) end; return fn() end
local function rect(g) local p, s = g.AbsolutePosition, g.AbsoluteSize; return { x0 = p.X, y0 = p.Y, x1 = p.X + s.X, y1 = p.Y + s.Y } end
local function overlaps(a, b) return a.x0 < b.x1 and b.x0 < a.x1 and a.y0 < b.y1 and b.y0 < a.y1 end
gui:SetAttribute("ForceViewport", nil); daw:SetAttribute("CompactForced", nil)
assert((RS.OK.Cypher:GetAttribute("Phase") or "idle") == "idle", "cypher phase " .. tostring(RS.OK.Cypher:GetAttribute("Phase")) .. ": this case needs only the beat maker")
assert(daw.Visible, "the beat maker should still be open from t47b")
-- he walks ~75 studs to the studio PC (about 9.4 s at WalkSpeed 8); arrival waits are capped at 15 s
assert(waitFor(function() return (gui:GetAttribute("Token") or "") ~= "" end, 15), "no visitor arrived within 15 s")
task.wait(0.5) -- one deferral check
local chip, card = gui:FindFirstChild("Waiting", true), gui:FindFirstChild("Card", true)
assert(gui:GetAttribute("Deferred") == true, "card not deferred while the beat maker is open (Deferred " .. tostring(gui:GetAttribute("Deferred")) .. ")")
assert(gui:GetAttribute("Open") == false and card and not card.Visible, "the card opened over the beat maker")
assert(chip and chip.Visible and chip.AbsoluteSize.Y >= 44, "Waiting chip not shown (or under 44 px)")
assert(chip.Text:find("IS WAITING", 1, true), "chip reads '" .. chip.Text .. "'")
local out = { "defers while beat maker open: card hidden, chip '" .. chip.Text .. "'" }

-- the phone beat maker: read everything while it is compact, then put it back before asserting
daw:SetAttribute("CompactForced", true)
task.wait(0.6) -- DAWUI re-lays out at once; the deferral check runs every 0.2 s
local compact, deferred, open = daw:GetAttribute("Compact") == true, gui:GetAttribute("Deferred"), gui:GetAttribute("Open")
local chipShown, covered = chip.Visible, {}
if chipShown then
  local c = rect(chip)
  for _, d in ipairs(daw:GetDescendants()) do
    if d:IsA("GuiObject") and d.Name:match("^Cell_") and d.Visible and d.AbsoluteSize.X > 0 and overlaps(c, rect(d)) then table.insert(covered, d.Name) end
  end
end
daw:SetAttribute("CompactForced", nil)
assert(compact, "CompactForced did not make the beat maker compact (DAWClient seam missing?)")
assert(deferred == true and open == false, "phone beat maker: the card should still wait (Deferred " .. tostring(deferred) .. ", Open " .. tostring(open) .. ")")
assert(#covered == 0, "phone beat maker: the Waiting chip covers pads " .. table.concat(covered, ", "))
table.insert(out, "phone beat maker: card still waiting, chip " .. (chipShown and "clear of every pad" or "hidden"))
assert(waitFor(function() return daw:GetAttribute("Compact") ~= true and chip.Visible end, 2), "the Waiting chip did not come back with the desktop beat maker")
assert(daw.Visible and gui:GetAttribute("Deferred") == true, "after phone mode: beat maker closed or the card no longer waiting")
table.insert(out, "desktop beat maker again: chip back")
return "T47D PLAY OK\n" .. table.concat(out, "\n")
