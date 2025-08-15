GM.EnemyModTable = {
	{
		modifier = "fire",
		name = "Fiery",
		onspawn = function( ent )
			ent:Ignite(9999)
		end
	},
	{
		modifier = "toxic",
		name = "Poisoned"
	},
	{
		modifier = "phys",
		name = "Armored",
		onspawn = function( ent )
			ent:SetNWBool("phys", true)
		end
	},
	{
		modifier = "faste",
		name = "Speedy",
		onspawn = function( ent )
		
		end
	},
	{
		modifier = "berserk",
		name = "Berserking",
		onspawn = function( ent )
			ent:SetNWBool("berserk", true)
		end
	},
	{
		modifier = "stronge",
		name = "Strengthened"
	},
	{
		modifier = "regen",
		name = "Regenerating"
	},
	{
		modifier = "nrg",
		name = "Electric"
	},
	{
		modifier = "darke",
		name = "Ghostly"
	},
	{
		modifier = "acid",
		name = "Acidic"
	}
}

if CLIENT then
	return
end

GM.ModCap = 3
GM.ModChance = 0--1/10
GM.ExtraModChance = 1/4
GM.ExtraModLevelInfluence = 1/110

function GM:RollModifiers(entity, force, overrideLevel, overrideChance)
	local entLevel = overrideLevel or (entity.GetMobLevel and entity:GetMobLevel() or 1)
	-- no mods if the entity doesn't want
	if (!entity.ModEnabled && !force) then return end
	-- initial rng
	if math.random() <= self.ModChance then return end
	-- 3 maximum mods per enemy
	for i = 1, 3 do
		local chance = overrideChance or (self.ExtraModChance + (self.ExtraModLevelInfluence * entLevel))
		print(self.ExtraModChance, entLevel, chance)
		if math.random() < 1 then--chance then
			-- pick a random mod
			local a = 2500
			while true do
				a = a - 1
				if a <= 0 then
					print("!!! The entity modifier loop couldn't break out in 2500 attempts. Something's wrong")
					print(debug.traceback())
					return
				end

				local idx = math.random(1, #self.EnemyModTable)
				local mod = self.EnemyModTable[idx]

				if (entity.ModTable[idx]) then
					continue
				end

				entity.ModTable[idx] = true
				break
			end
		else
			return
		end
	end
end

