ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Tower"

TARGETING_CLOSEST = 0
TARGETING_FURTHEST = 1
TARGETING_LAST = 2
TARGETING_FIRST = 3
TARGETING_RANDOM = 4

function ENT:SetupDataTables()
	
	self:NetworkVar("Int", 0, "TargetDistance")
	self:NetworkVar("Int", 1, "TargetType")
	self:NetworkVar("Int", 2, "TotalDamage")

	self:NetworkVar("Entity", 0, "Target")
	self:NetworkVar("Entity", 1, "Placer")
	self:NetworkVar("Entity", 2, "Gun")

	self:NetworkVar("Float", 0, "ReloadTimer")
	self:NetworkVar("Bool", 0, "DoReloadMechanism")
	self:NetworkVar("Bool", 1, "IsReloading")
	self:NetworkVar("Int", 3, "Bullets")
	self:NetworkVar("Int", 4, "ReloadTime")
	self:NetworkVar("Int", 5, "DefaultClip")
	
end

function ENT:GetDamageDelay()
	return 0.15
end

function ENT:GetDamage( target )
	return 1
end

function ENT:GetGunModel()
	return "models/weapons/w_smg1.mdl" --[[model for the turrets gun]],
		   0--[[transparency 1=full 0=none]],
		   12--[[offset y axis]]
end
