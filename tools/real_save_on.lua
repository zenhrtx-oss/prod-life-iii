-- Edit: turns the real-save trial on (plans/2026-11-03-save-safety.md). Studio Play sessions then save profiles to the
-- trial DataStore named here, never OKStudio_v1, and tools/guard.lua refuses test runs and syncs until
-- tools/real_save_off.lua. Needs Game Settings > Security > Enable Studio Access to API Services (the user's switch).
local NAME = "ProdLife_trial_v1"
if game.PlaceId == 0 then return "REAL SAVE NOT ON: this place has no PlaceId" end
game.ReplicatedStorage.OK:SetAttribute("RealSaveTrial", NAME)
return "REAL SAVE ON: Play sessions save to " .. NAME .. "; run tools/real_save_off.lua before tests, syncs or saving the place"
