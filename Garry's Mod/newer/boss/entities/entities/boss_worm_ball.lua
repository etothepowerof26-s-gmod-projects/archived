AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

function ENT:SetupDataTables()
	self:NetworkVar("Vector", 0, "FallPos")
end

if SERVER then
	
	function ENT:Initialize()
	
		self:SetModel("models/pac/default.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		
		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			phys:SetMass(10000)
			phys:EnableGravity(false)
		end
		
	end
	
	function ENT:Think()
		
		if IsValid(self:GetPhysicsObject()) and not self.Setted then
			self:SetAngles( (self:GetPos() - self:GetFallPos()):Angle() )
			self:Spawn()
			self:Activate()
			
			local phys = self:GetPhysicsObject()
			if not phys:IsValid() then self:Remove() end
			
			phys:Wake()
			
			self.dir = (self:GetPos() - self:GetFallPos())
			self.dir:Normalize()
			self:StartMotionController()
			self:SetVelocity(self.dir*10000)
			
			self.Setted = true
		end
		
	end
	
	
else
	function ENT:Draw()
		self:DrawModel()
	end
end