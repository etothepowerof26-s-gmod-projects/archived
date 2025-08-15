AddCSLuaFile()

-- this is for legacy compatibility with the old td_* maps.

ENT.PrintName = "I hate fun"
ENT.Base      = "base_anim"
ENT.Type      = "anim"

if SERVER then
		
	function ENT:Initialize()
		self:Remove()
	end
	
end
