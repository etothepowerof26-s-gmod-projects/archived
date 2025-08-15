AddCSLuaFile()

SWEP.HoldType              = "ar2"

if CLIENT then
   SWEP.PrintName          = "M249"
   SWEP.Slot               = 2

   SWEP.ViewModelFlip      = false
   SWEP.ViewModelFOV       = 64
end

SWEP.Base                  = "weapon_bbattles_base"

SWEP.Primary.Delay         = 0.05
SWEP.Primary.Recoil        = 2
SWEP.Primary.Automatic     = true
SWEP.Primary.Ammo          = "Pistol"
SWEP.Primary.Damage        = 10
SWEP.Primary.Cone          = 0.05
SWEP.Primary.ClipSize      = 100
SWEP.Primary.ClipMax       = 100
SWEP.Primary.DefaultClip   = 100
SWEP.Primary.Sound         = Sound( "Weapon_SMG1.Single" )

SWEP.UseHands              = true
SWEP.ViewModel             = "models/weapons/v_mach_m249para.mdl"
SWEP.WorldModel            = "models/weapons/w_mach_m249para.mdl"

SWEP.IronSightsPos         = Vector(-4.5, 3.2, 0.55)
SWEP.IronSightsAng         = Vector(0, 0, 0)-- Vector(2.599, -1.3, -3.6)

SWEP.Modifiers = {
	mobility = .85
}

function SWEP:SetZoom(state)
   if not (IsValid(self:GetOwner()) and self:GetOwner():IsPlayer()) then return end
   if state then
      self:GetOwner():SetFOV(55, 0.5)
   else
      self:GetOwner():SetFOV(0, 0.2)
   end
end

-- Add some zoom to ironsights for this gun
function SWEP:SecondaryAttack()
   if not self.IronSightsPos then return end
   if self:GetNextSecondaryFire() > CurTime() then return end

   local bIronsights = not self:GetIronsights()

   self:SetIronsights( bIronsights )

   self:SetZoom( bIronsights )

   self:SetNextSecondaryFire( CurTime() + 0.3 )
end

function SWEP:PreDrop()
   self:SetZoom(false)
   self:SetIronsights(false)
   return self.BaseClass.PreDrop(self)
end

function SWEP:Reload()
    if (self:Clip1() == self.Primary.ClipSize or
        self:GetOwner():GetAmmoCount(self.Primary.Ammo) <= 0) then
       return
    end
    self:DefaultReload(ACT_VM_RELOAD)
    --self:SetIronsights(false)
    --self:SetZoom(false)
end

function SWEP:Holster()
   self:SetIronsights(false)
   self:SetZoom(false)
   return true
end
