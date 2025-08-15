AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("modifiers.lua")
include("shared.lua")
include("modifiers.lua")

function ENT:Initialize()
	self:SetupDefaultVars()

	self:SetModel("models/zombie/classic.mdl")
	self:SetHealth(self:GetMobBaseHealth() + (self:GetMobHealthPerLevel() * (self:GetMobLevel() - 1)))
	self:SetMaxHealth(self:Health())
end
