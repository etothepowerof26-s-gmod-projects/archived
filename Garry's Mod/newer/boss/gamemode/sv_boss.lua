-- Boss module.
-- Handles most things.

module('boss', package.seeall)

Spawnpoints = {
	["gm_construct"] = {
		[1] = Vector(0, 0, 0)
	}
}

-- Hooks --
hook.Add("SelectBossSpawn", "boss", function()
	if not Spawnpoints[game.GetMap()] then
		return Vector(0, 0, 0)
	end
	
	return Spawnpoints[math.random(#Spawnpoints)]
end)