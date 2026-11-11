local was = game.ReplicatedStorage.OK:GetAttribute("RealSaveTrial")
game.ReplicatedStorage.OK:SetAttribute("RealSaveTrial", nil)
return "REAL SAVE OFF" .. (was ~= nil and (" (was " .. tostring(was) .. ")") or " (it was already off)")
