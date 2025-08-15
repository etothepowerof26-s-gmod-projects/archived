ENT.Base = "base_nextbot"
ENT.PrintName = "RPG Enemy Base"

ENT.AutomaticFrameAdvance  = true;

ENT.ModEnabled = true

-- networked variables for enemies
function ENT:SetupDataTables()
	-- variable for controlling if we should wander, or we should attack
	self:NetworkVar("Int", 0, "EnemyState")
	-- type of enemy
	-- 0: passive
	-- 1: semi-passive (will attack if you attack)
	-- 2: aggressive (will always find ways to attack)
	self:NetworkVar("Int", 1, "EnemyType")
	-- how far away can it find people
	self:NetworkVar("Int", 2, "SearchRadius")
	-- how far away people can get if they dont wanna be aggroed
	self:NetworkVar("Int", 3, "LoseTargetRadius")
	-- mob level controller
	self:NetworkVar("Int", 4, "MobLevel")
	-- base health
	self:NetworkVar("Int", 5, "MobBaseHealth")
	-- health modifier per level
	self:NetworkVar("Int", 6, "MobHealthPerLevel")

	-- self:NetworkVar("Int", 5, "ModAmount")
	
	-- target entity
	self:NetworkVar("Entity", 0, "Target")
end

-- this function for default variables
function ENT:SetupDefaultVars()
	self:SetEnemyState(0) -- wander
	self:SetEnemyType(1) -- semi-passive enemy
	self:SetSearchRadius(2500 ^ 2) -- 2500 units (DistToSqr) to search
	self:SetLoseTargetRadius(3500 ^ 2) -- 3500 units (^) to search
	self:SetMobLevel(1) -- level 1 zombie
	self:SetMobBaseHealth(100) -- that has a base 100 hp
	self:SetMobHealthPerLevel(0) -- that gains 0 health per level
end

if (SERVER) then return end

language.Add("rpg_base_enemy", "Zombie")