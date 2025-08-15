include("shared.lua")
include("abilities.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("outline.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("abilities.lua")
util.AddNetworkString("slap_visible_ply")
resource.AddFile("models/glove/glove.mdl")
resource.AddSingleFile("sound/slapcentral/reverb_fart.ogg")
resource.AddSingleFile("sound/slapcentral/slap.ogg")
local slap_min_ragdoll_dur = CreateConVar("slap_min_ragdoll_dur", 2, FCVAR_ARCHIVE, "Minimum ragdoll duration")
local slap_base_power = CreateConVar("slap_base_power", 13 + 2 / 3, FCVAR_ARCHIVE, "Base power of slap to source velocity units")
local slap_ragdoll_ping_thresh = CreateConVar("slap_ragdoll_ping_thresh", 0.2, FCVAR_ARCHIVE, "Threshold in 100ms where you would be able to slap the dude while you're ragdolled.")

function GetSlapRagdollDuration(pwr)
    return math.min(math.max(slap_min_ragdoll_dur:GetFloat(), pwr / 10), 4)
end

function TransferVelocityToPlayer(rag, ply)
    local num = rag:GetPhysicsObjectCount() - 1

    for i = 0, num do
        local bone = rag:GetPhysicsObjectNum(i)

        if IsValid(bone) then
            -- find first valid bone, then apply velocity from bone to player
            local velocity = bone:GetVelocity()
            ply:SetVelocity(velocity)
            timer.Simple(0.05, function()
                print(ply:GetVelocity(), velocity)
            end)

            return
        end
    end
end


function ApplyRagdollVelocity(rag, vel)
    local ply = rag.ply
    if not IsValid(ply) then return end
    local num = rag:GetPhysicsObjectCount() - 1

    for i = 0, num do
        local bone = rag:GetPhysicsObjectNum(i)

        if IsValid(bone) then
            local bp, ba = ply:GetBonePosition(rag:TranslatePhysBoneToBone(i))

            if bp and ba then
                bone:SetPos(bp)
                bone:SetAngles(ba)
            end

            -- not sure if this will work:
            bone:SetVelocity(vel)
            -- apply some angular velocity to it too.
            local angular = VectorRand(-2000, 2000) -- vel * 5
            bone:SetAngleVelocity(angular)
        end
    end
end

-- timer.Simple(0, function() end) ent:Spectate(OBS_MODE_FIXED) -- ent:SpectateEntity(rag)
function InitRagdollVars(ent, rag)
    -- ent:Flashlight(false)
    ent:Extinguish()
    -- ent:StripWeapons()
    ent:SetNWEntity("Ragdoll", rag)

    ent:SetRagdollStartTime(CurTime())

    timer.Simple(0, function()
        if not IsValid(ent) then return end

        ent:SetMoveType(MOVETYPE_OBSERVER)

        -- ent:Spectate(OBS_MODE_FIXED)
    end)

    -- ent:Freeze(true)
    -- ent:SetNoCollideWithTeammates(true)

    net.Start("slap_visible_ply")
        net.WriteEntity(ent)
        net.WriteBit(0)
    net.SendPVS(ent:GetPos())
end

function UnfuckRagdoll(ply)
    if not IsValid(ply) or not ply.Ragdoll then return end
    local rag = ply.Ragdoll
    -- ply:Freeze(false)
    -- ply:UnSpectate()


    -- ply:Spawn()
    ply:SetMoveType(MOVETYPE_WALK)
    ply:SetPos(rag:GetPos())
    -- ply:SetNoCollideWithTeammates(false)

    net.Start("slap_visible_ply")
    net.WriteEntity(ply)
    net.WriteBit(1)
    net.SendPVS(ply:GetPos())

    TryUnstuck(ply)
    TransferVelocityToPlayer(rag, ply)

    rag:Remove()
    ply.Ragdoll = nil
    ply:SetRagdollStartTime(-1)
    -- hook.Run("PlayerLoadout", ply)
end

function MakeRagdoll(ply)
    -- garrysmod/gamemodes/terrortown/gamemode/corpse.lua
    if ply.Ragdoll and IsValid(ply.Ragdoll) then return false end
    local rag = ents.Create("prop_ragdoll")
    if not IsValid(rag) then return false end
    ply.Ragdoll = rag
    rag:SetPos(ply:GetPos())
    rag:SetModel(ply:GetModel())
    rag:SetSkin(ply:GetSkin())

    for _, v in pairs(ply:GetBodyGroups()) do
        rag:SetBodygroup(v.id, ply:GetBodygroup(v.id))
    end

    rag:SetAngles(ply:GetAngles())
    rag:SetColor(ply:GetColor())
    rag:Spawn()
    rag:Activate()
    -- nonsolid to players, but can be picked up and shot
    rag:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    -- flag this ragdoll as being a player's
    rag.ply = ply
    -- tenty: We return here because we're gonna be applying velocity in our own slap battles take damage hook.

    return rag
end

local hull_offsets = {
    {0.0, 0.0, 0.0},
    {0.0, 0.0, 1.0},
    {0.0, 0.0, -1.0},
    {0.0, 1.0, 0.0},
    {0.0, -1.0, 0.0},
    {1.0, 0.0, 0.0},
    {-1.0, 0.0, 0.0},
    {-1.0, 1.0, 1.0},
    {1.0, 1.0, 1.0},
    {1.0, -1.0, 1.0},
    {1.0, 1.0, -1.0},
    {-1.0, -1.0, 1.0},
    {1.0, -1.0, -1.0},
    {-1.0, 1.0, -1.0},
    {-1.0, -1.0, -1.0},
    {0.0, 0.0, 2.0},
    {0.0, 0.0, -2.0},
    {0.0, 2.0, 0.0},
    {0.0, -2.0, 0.0},
    {2.0, 0.0, 0.0},
    {-2.0, 0.0, 0.0},
    {-2.0, 2.0, 2.0},
    {2.0, 2.0, 2.0},
    {2.0, -2.0, 2.0},
    {2.0, 2.0, -2.0},
    {-2.0, -2.0, 2.0},
    {2.0, -2.0, -2.0},
    {-2.0, 2.0, -2.0},
    {-2.0, -2.0, -2.0},
    {0.0, 0.0, 3.0},
    {0.0, 0.0, -3.0},
    {0.0, 3.0, 0.0},
    {0.0, -3.0, 0.0},
    {3.0, 0.0, 0.0},
    {-3.0, 0.0, 0.0},
    {-3.0, 3.0, 3.0},
    {3.0, 3.0, 3.0},
    {3.0, -3.0, 3.0},
    {3.0, 3.0, -3.0},
    {-3.0, -3.0, 3.0},
    {3.0, -3.0, -3.0},
    {-3.0, 3.0, -3.0},
    {-3.0, -3.0, -3.0},
    {0.0, 0.0, 4.0},
    {0.0, 0.0, -4.0},
    {0.0, 4.0, 0.0},
    {0.0, -4.0, 0.0},
    {4.0, 0.0, 0.0},
    {-4.0, 0.0, 0.0},
    {-4.0, 4.0, 4.0},
    {4.0, 4.0, 4.0},
    {4.0, -4.0, 4.0},
    {4.0, 4.0, -4.0},
    {-4.0, -4.0, 4.0},
    {4.0, -4.0, -4.0},
    {-4.0, 4.0, -4.0},
    {-4.0, -4.0, -4.0},
    {0.0, 0.0, 5.0},
    {0.0, 0.0, -5.0},
    {0.0, 5.0, 0.0},
    {0.0, -5.0, 0.0},
    {5.0, 0.0, 0.0},
    {-5.0, 0.0, 0.0},
    {-5.0, 5.0, 5.0},
    {5.0, 5.0, 5.0},
    {5.0, -5.0, 5.0},
    {5.0, 5.0, -5.0},
    {-5.0, -5.0, 5.0},
    {5.0, -5.0, -5.0},
    {-5.0, 5.0, -5.0},
    {-5.0, -5.0, -5.0}
}

local thick = Vector(32, 32, 72) -- * Vector(2, 2, 2)

function TryUnstuck(ply, callback)
    callback = callback or function(ent, tr)
        ent:SetPos(tr.StartPos)
    end
    for i = 1, #hull_offsets do
        local hullPos = Vector(unpack(hull_offsets[i])) * thick
        local realPos = hullPos + ply:GetPos() + Vector(0, 0, thick.z / 2)
        local tr = util.TraceBoundingBox(ply, realPos)
        if tr.Hit then
            -- print("OH NO")
            continue
        end
        -- print("Trace did not hit.")
        pcall(callback, ply, tr.StartPos)
        break
    end
end

function GM:PlayerInitialSpawn(ply)
    ply:SetModel("models/player/kleiner.mdl")
    player_manager.SetPlayerClass(ply, "player_slap")
    ply:SetTeam(1)
end

function GM:PlayerLoadout(ply)
    player_manager.RunClass(ply, "Loadout")
end

function GM:PlayerSpawn(ply)
    player_manager.OnPlayerSpawn(ply)
    hook.Run("PlayerLoadout", ply)
end

function GM:PlayerCanSlapWhileRagdolled(victim, inflictor)
    if inflictor == victim then return false end
    if not inflictor.SampledPing then
        inflictor.SampledPing = inflictor.Ping and inflictor:Ping() or 0
    end
    local end_time = (slap_ragdoll_ping_thresh:GetFloat() + inflictor.SampledPing / 1000)
    if inflictor.Ragdoll and CurTime() > inflictor:GetRagdollStartTime() + end_time then
        print("Player cannot slap anymore", inflictor)
        return false
    end
    return true
end

function GM:EntityTakeDamage(ent, dmg)
    local do_rag

    if not ent:IsPlayer() or ent.Ragdoll then
        do_rag = true
    end

    if dmg:GetDamageType() == DMG_FALL then
        dmg:SetDamage(0)
        do_rag = true
    end

    local inflictor = dmg:GetAttacker()
    if not IsValid(inflictor) or inflictor:GetClass() == "prop_ragdoll" or not IsFirstTimePredicted() then return end

    if not hook.Run("PlayerCanSlapWhileRagdolled", ent, inflictor) then return end

    -- todo: StoreDamageVars(ply)
    ent.LastInflictor = inflictor

    local weapon = inflictor:GetActiveWeapon()
    local data = weapon:GetGloveData()

    -- for gloves like Reverse, where they need to call their own ragdoll function.
    local can_continue = hook.Call("GloveCanRagdoll", data, ent, inflictor) or true
    if not can_continue then return end

    local power = 20

    if not data then
        ErrorNoHalt("Invalid slap data for ", inflictor, "(", weapon:GetGlove(), "). Using default power (20).\n")
    else
        -- glove should have it's own power hook, if there is no power variable.
        -- use default variables if possible.
        power = (isnumber(data.Power) and data.Power) or hook.Call("GloveModifyPower", data) or power
    end

    -- print(power)
    local speed = slap_base_power:GetFloat() * power --[[GetGlove().Power]]

    -- todo: ply:Fling(inflictor:GetAimVector(), speed)

    if not do_rag then
        local rag = MakeRagdoll(ent)

        if rag then
            InitRagdollVars(ent, rag)
            ApplyRagdollVelocity(rag, inflictor:GetAimVector() * speed)
        end

        -- timer.Simple(0, function() end) ent:Spectate(OBS_MODE_FIXED) -- ent:SpectateEntity(rag)

        timer.Simple(GetSlapRagdollDuration(power), function()
            if not IsValid(ent) then return end
            inflictor.SampledPing = nil;
            UnfuckRagdoll(ent)
        end)
    end
end

function GM:Think()
    for k, v in pairs(player.GetAll()) do
        if not v.Ragdoll then continue end

        -- v:SetPos(v.Ragdoll:GetPos())
    end
end

concommand.Add("slap_debug_fill_bots", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    game.ConsoleCommand("bot_zombie 1\n")

    for i = 1, 20 do
        game.ConsoleCommand("bot\n")
    end
end)

concommand.Add("slap_debug_killall", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    for k, v in pairs(player.GetAll()) do
        v:Kill()
    end
end)

concommand.Add("slap_debug_respawnall", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    for k, v in pairs(player.GetAll()) do
        v:Spawn()
    end
end)

concommand.Add("slap_debug_kickall", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    for k, v in pairs(player.GetBots()) do
        v:Kick()
    end
end)