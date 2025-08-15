include("shared.lua")
local bone_name = "ValveBiped.Bip01_R_Hand"

function SWEP:DrawWorldModel()
    local ply = self:GetOwner()

    if not IsValid(ply) then
        self:DrawModel()

        return
    else
        self:DrawShadow(false)

        if not self.Glove then
            self.Glove = ClientsideModel("models/glove/glove.mdl")
            self.Glove:SetNoDraw(true)
            self.Glove:DrawShadow(false)
            self.Glove:SetMaterial"models/debug/debugwhite"
            self.Glove:SetModelScale(1.5)
        end

        if IsValid(self.Glove) then
            local pos, ang = self:GetPos(), Angle()
            local bone_id = ply:LookupBone(bone_name)

            if bone_id then
                local matrix = ply:GetBoneMatrix(bone_id)

                if matrix then
                    ang = matrix:GetAngles()
                    pos = matrix:GetTranslation() + ang:Forward() * 10 + ang:Right() * 3 - ang:Up() * 3
                    ang:RotateAroundAxis(ang:Right(), -90)
                    ang:RotateAroundAxis(ang:Forward(), -90)
                end
            end

            self.Glove:SetPos(pos)
            self.Glove:SetAngles(ang)
            self.Glove:SetupBones()
            self.Glove:DrawModel()
        end
    end
end

function SWEP:OnRemove()
    print("ON remove.. ", self)

    if self.Glove then
        self.Glove:Remove()
    end
end

function SWEP:PrimaryAttack()
    return false
end

function SWEP:SecondaryAttack()
    return false
end