AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")
util.PrecacheModel("models/glove/glove.mdl")

function SWEP:PrimaryAttack()
    local now = CurTime()
    self:SetHoldType("melee")
    self:SetNextPrimaryFire(now + self.Primary.Delay)
    self:SetNextSecondaryFire(now + self.Primary.Delay)
    local ply = self:GetOwner()
    if ply.Ragdoll then end -- print("Player tried to swing while ragdolled", ply)

    timer.Simple(0, function()
        ply:SetAnimation(PLAYER_ATTACK1)
    end)

    local _ = SERVER and ply:LagCompensation(true)

    local tr = util.TraceHull({
        start = ply:GetShootPos(),
        endpos = ply:GetShootPos() + (ply:GetAimVector() * 80),
        filter = function(ent)
            if ent == ply then return false end
            if ent:GetClass() == "prop_ragdoll" then return false end
            if ent.Ragdoll then return false end

            return true
        end,
        mins = Vector(-4, -4, -4),
        maxs = Vector(4, 4, 4),
        mask = MASK_SHOT_HULL
    })

    local v = tr.Entity
    local _ = SERVER and ply:LagCompensation(false)

    if SERVER then
        if tr.Hit then
            local dmg = DamageInfo()
            dmg:SetAttacker(ply)
            dmg:SetInflictor(self)
            dmg:SetDamage(self.Primary.Damage)
            dmg:SetDamageType(DMG_GENERIC)
            dmg:SetDamageForce(ply:GetAimVector() * (175 * self.Primary.Damage))
            dmg:SetDamagePosition(tr.HitPos)
            v:TakeDamageInfo(dmg)
            local mscale = pac and (pac.GetPlayerSize and pac.GetPlayerSize(ply)) or ply:GetModelScale()
            local ptch = 100 + (math.Clamp(1 - mscale, -0.5, 1) * 100)
            ply:EmitSound(self.Sound, 100, math.random(ptch - 7, ptch + 7))
        else
            ply:EmitSound(self.SwingSound, 75, math.random(99, 105), 0.6)
        end
    end

    ply:ViewPunch(tr.Hit and Angle(0.5, 1.5, 0) or Angle(0.3, 0.5, 0))

    timer.Simple(.15, function()
        if not IsValid(self) then return end
        self:SetHoldType("pistol")
    end)
end

function SWEP:SecondaryAttack()
    local ply = self:GetOwner()
    local data = self:GetGloveData()
    if not data then return false end

    -- if GAMEMODE:IsOnCooldown(ply, data.Ability) then print("Dont update...") return false end
    if data.AbilityType == ABILITY_RIGHTCLICK then
        self:SetNextSecondaryFire(CurTime() + data.AbilityCooldown)

        if IsFirstTimePredicted() and SERVER then
            data:AbilityUse(ply)
        end

        return true
    end
end