GLOVE.Name = "Normal Glove"
GLOVE.Speed = 20
GLOVE.Power = 30
GLOVE.Ability = "Fart Blast"
GLOVE.AbilityCooldown = 5
GLOVE.AbilityType = ABILITY_RIGHTCLICK

function GLOVE:Initialize(wep)
end

function GLOVE:AbilityUse(ply)
    -- fart
    if GAMEMODE:IsOnCooldown(ply, self.Ability) then return end
    local startTime, endTime = GAMEMODE:Cooldown(ply, self.Ability, self.AbilityCooldown)
    ply:EmitSound("slapcentral/reverb_fart.ogg")
    local increasedSpeed = 600
    local decay = self.AbilityCooldown / 5
    local tick = 0.1
    local oldSpeed = ply:GetWalkSpeed()
    local amountTicks = decay / tick
    local i = 0

    timer.Create("AbilityDecay" .. tostring(ply), tick, amountTicks, function()
        if not IsValid(ply) then return end
        i = i + 1

        if i > amountTicks - 1 then
            ply:SetWalkSpeed(oldSpeed)
            ply:SetRunSpeed(oldSpeed)

            return
        end

        local time = math.max(startTime + decay - CurTime(), 0)
        local frac = time / decay
        -- print(time, frac)
        local newSpeed = math.Remap(frac, 1, 0, increasedSpeed, oldSpeed)
        ply:SetWalkSpeed(newSpeed)
        ply:SetRunSpeed(newSpeed)
    end)
end