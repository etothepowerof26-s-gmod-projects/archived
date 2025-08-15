if GM.Waypoints and next(GM.Waypoints) != nil then
	-- todo
else
	GM.Waypoints = {}
end

function GM:LoadWaypoints()
	if next(self.Waypoints) != nil then
		print("Not loading checkpoints a second time")
		return
	end

	if not file.Exists("tdwaypoints/" .. game.GetMap() .. ".txt", "DATA") then
		print("Waypoints dont exist for " .. game.GetMap())
		return
	end

	self.Waypoints = util.JSONToTable(file.Read("tdwaypoints/" .. game.GetMap() .. ".txt", "DATA"))
	print("Loaded " .. table.Count(self.Waypoints) .. " waypoints for " .. game.GetMap())
end


SetGlobalInt( "td_lives", 20 )
