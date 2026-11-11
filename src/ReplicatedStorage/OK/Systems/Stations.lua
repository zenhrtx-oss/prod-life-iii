-- OK Studio system: studio laptops ("Room for three"). Every OK_Interactable part with Kind = "Station" opens the
-- same beat maker as the studio PC (no chair, no desk camera); saves and ON MONITORS work from it (DAW.AtStation).
-- Parts are built by build/14_stations.lua; StationName names the spot in the window title.
local RS = game:GetService("ReplicatedStorage")
local DAW = require(RS.OK.Systems.DAW)
local M = { Enabled = true, Version = 1 }

function M.Init(ctx)
	ctx.Interaction.Register("Station", function(player, inst)
		DAW.OpenFor(player, inst, nil)
	end)
end

return M
