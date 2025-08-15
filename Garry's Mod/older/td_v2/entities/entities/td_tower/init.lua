AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_circles.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:InitVars()
	-- we have a target radius of 500 units
	self:SetTargetDistance(500 ^ 2)
	self:SetTargetType(TARGETING_FIRST)

	-- enable the reload mechanism which takes 2 seconds and has 20 bullets
	self:SetDoReloadMechanism(true)
	self:SetBullets(20)
	self:SetDefaultClip(20)
	self:SetReloadTimer(2.5)
end

function ENT:PreInit()
	-- set all your variables here.
	self:InitVars()

	self:SetModel( "models/props_combine/breenglobe.mdl" )
	self:PhysicsInit( SOLID_NONE )      -- Make us work with physics,
	self:SetMoveType( MOVETYPE_NONE )   -- after all, gmod is a physics
	self:SetSolid( SOLID_NONE )         -- Toolbox

	self:SetPos( self:GetPos() + Vector(0, 0, self:OBBMaxs().z) )
end

function ENT:PostInit()
	self:CreateGun()
end

function ENT:Initialize()

	self:PreInit()
	self:PostInit()

	self:CallOnRemove( "RemoveGun", function( ent )
		SafeRemoveEntity( ent:GetGun() )
	end )

end

function ENT:CreateGun()
	local gun = ents.Create( "prop_physics" )
	local gmodel, gtrans, gyoffs = self:GetGunModel()

	gun:SetModel(gmodel)
	gun:SetPos(self:GetPos() + Vector(0, 0, gyoffs))
	gun:SetAngles(Angle())
	gun:Spawn()
	gun:SetMoveType(MOVETYPE_NONE)
	gun:PhysicsInit(SOLID_NONE)
	gun:SetSolid(SOLID_NONE)
	gun:Activate()

	self:SetGun( gun )
end

function ENT:Think()
	if not self.LastShoot then
		self.LastShoot = CurTime()
	end

	local a = ents.FindByClass("td_base_enemy")

	if self:GetBullets() < 1 and not self:GetIsReloading() then
		self:SetReloadTime(CurTime())
		self:SetIsReloading(true)
		self:GetGun():EmitSound("weapons/smg1/smg1_reload.wav")
	end

	if self:GetIsReloading() and CurTime() >= self:GetReloadTime() + self:GetReloadTimer() then
		self:SetIsReloading(false)
		self:SetBullets(self:GetDefaultClip())
		
	end

	if CurTime() >= self.LastShoot + self:GetDamageDelay() and not self:GetIsReloading() then
		
		self.LastShoot = CurTime()
		-- print("SHOOT", CurTime(), self:GetDamageDelay(), self.LastShoot)
		local target = a[#a]

		self:Shoot(target)
		-- PrintMessage(3, "Shooting " .. self:GetDamageDelay())
	end

	self:NextThink(CurTime())
	return true
end

function ENT:Shoot(target)
	if self:GetDoReloadMechanism() and self:GetIsReloading() then
		return
	end

	target:TakeDamage( self:GetDamage(), self, self )
	CreateIndicator( player.GetHumans(), self:GetDamage(), Color(255, 0, 0), target:GetPos() )
	self:GetGun():EmitSound( "weapons/smg1/smg1_fire1.wav" )

	if self:GetDoReloadMechanism() then
		self:SetBullets((self:GetBullets() or 1) - 1)
	end
end
