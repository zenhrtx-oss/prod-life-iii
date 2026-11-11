-- A plain data table (the server requires it too). aura is the Aura purple; stat maps each career stat (and money) to
-- its colour, the per-kind chip colours of the result cards: the HUD's floats and pill pops use it. stat.xp (two
-- sessions, 2026-10-30) is the result card's "+N XP" chip: an orange of its own, neither the gold an unknown kind
-- falls back to nor the cold accent2 a loss reads in (the HUD's own +XP float stays ledOn, as before).
local T = {
  bg = Color3.fromRGB(10, 10, 14), panel = Color3.fromRGB(18, 18, 24), line = Color3.fromRGB(40, 40, 52),
  text = Color3.fromRGB(235, 235, 235), muted = Color3.fromRGB(150, 150, 165), accent = Color3.fromRGB(255, 60, 160), accent2 = Color3.fromRGB(0, 170, 255),
  gold = Color3.fromRGB(225, 200, 140), ledOn = Color3.fromRGB(0, 255, 140), ledOff = Color3.fromRGB(70, 70, 80),
  font = Enum.Font.GothamBold, fontBlack = Enum.Font.GothamBlack, mono = Enum.Font.Code,
  aura = Color3.fromRGB(200, 75, 255),
}
T.stat = { money = T.ledOn, aura = T.aura, followers = T.accent2, placements = T.gold, hits = T.gold, sponsors = T.accent,
  xp = Color3.fromRGB(255, 160, 40) }
return T
