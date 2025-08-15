GLOVE.Name = "RNG"
GLOVE.Speed = 14
GLOVE.Power = "5 - 100"
GLOVE.Ability = "RNG"
GLOVE.AbilityCooldown = 0
GLOVE.AbilityType = ABILITY_PASSIVE

function GLOVE:GloveModifyPower()
    -- math.randomseed(os.clock() + SysTime())
    return math.Round(math.Remap(math.random(), 0, 1, 5, 100))
end