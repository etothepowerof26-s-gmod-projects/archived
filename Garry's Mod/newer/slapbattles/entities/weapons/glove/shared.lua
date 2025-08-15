SWEP.Base = "weapon_base"
SWEP.PrintName = "Slap"
SWEP.Slot = 1
SWEP.SlotPos = 4
SWEP.ViewModel = "models/weapons/c_arms_citizen.mdl"
SWEP.WorldModel = "models/weapons/w_stunbaton.mdl"
SWEP.ViewModelFOV = 72
SWEP.ViewModelFlip = false
SWEP.Primary = {}
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = ""
SWEP.Primary.Delay = 1
SWEP.Primary.Damage = 3
SWEP.Secondary = {}
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = ""
SWEP.Secondary.Delay = 1
SWEP.Sound = Sound("slapcentral/slap.ogg")
SWEP.Sound2 = Sound("chatsounds/autoadd/cartoon_sfx/slap2.ogg")
SWEP.SwingSound = Sound("weapons/iceaxe/iceaxe_swing1.wav")

function SWEP:SetupDataTables()
    self:NetworkVar("String", 0, "Glove")
end

function SWEP:GetGloveData()
    return GAMEMODE.Gloves[self:GetGlove()]
end

function SWEP:Initialize()
    timer.Simple(0, function()
        if not IsValid(self) then return end
        local data = self:GetGloveData()

        if data and data.Initialize then
            data:Initialize(self)
        end
    end)
end

function SWEP:Reload()
end