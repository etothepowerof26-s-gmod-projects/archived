GM.Name = "Slap Central"
GM.Author = "twentysix"
GM.Email = "N/A"
GM.Website = "N/A"
team.SetUp(1, "Slappers", Color(0, 120, 255), false)
team.SetUp(400, "Spectators", Color(120, 120, 120), false)
GM.Gloves = GM.Gloves or {}

--  debugoverlay.Cross( Vector position, number size, number lifetime = 1, table color = Color( 255, 255, 255 ), boolean ignoreZ = false )
--  debugoverlay.Line( Vector pos1, Vector pos2, number lifetime = 1, table color = Color( 255, 255, 255 ), boolean ignoreZ = false )
function GM.Trace_Slap(ent)
    if ent:IsPlayer() then return false end
    if ent:GetClass() == "prop_ragdoll" then return false end

    return true
end

ABILITY_RIGHTCLICK = 1
ABILITY_PASSIVE = 2
local files, _ = file.Find(GM.FolderName .. "/gamemode/gloves/*.lua", "LUA")

for i = 1, #files do
    GLOVE = {}
    AddCSLuaFile(GM.FolderName .. "/gamemode/gloves/" .. files[i])
    include(GM.FolderName .. "/gamemode/gloves/" .. files[i])
    GM.Gloves[GLOVE.Name] = GLOVE
    print("Registered glove...", GLOVE.Name)
    GLOVE = nil
end

local PLAYER = {}
PLAYER.DisplayName = "Default Class"
PLAYER.SlowWalkSpeed = 112 -- How fast to move when slow-walking (+WALK)
PLAYER.WalkSpeed = 225 -- How fast to move when not running
PLAYER.RunSpeed = 225 -- How fast to move when running
PLAYER.CrouchedWalkSpeed = 0.3 -- Multiply move speed by this when crouching
PLAYER.DuckSpeed = 0.3 -- How fast to go from not ducking, to ducking
PLAYER.UnDuckSpeed = 0.3 -- How fast to go from ducking, to not ducking
PLAYER.JumpPower = 200 -- How powerful our jump should be
PLAYER.CanUseFlashlight = true -- Can we use the flashlight
PLAYER.MaxHealth = 100 -- Max health we can have
PLAYER.MaxArmor = 100 -- Max armor we can have
PLAYER.StartHealth = 100 -- How much health we start with
PLAYER.StartArmor = 0 -- How much armour we start with
PLAYER.DropWeaponOnDie = false -- Do we drop our weapon when we die
PLAYER.TeammateNoCollide = true -- Do we collide with teammates or run straight through them
PLAYER.AvoidPlayers = true -- Automatically swerves around other players
PLAYER.UseVMHands = true -- Uses viewmodel hands

--
-- Name: PLAYER:SetupDataTables
-- Desc: Set up the network table accessors
-- Arg1:
-- Ret1:
--
function PLAYER:SetupDataTables()
    print("Set up data tables... ", self.Player)
    self.Player:NetworkVar("Float", 5, "RagdollStartTime")
end

--
-- Name: PLAYER:Init
-- Desc: Called when the class object is created (shared)
-- Arg1:
-- Ret1:
--
function PLAYER:Init()
end

--
-- Name: PLAYER:Spawn
-- Desc: Called serverside only when the player spawns
-- Arg1:
-- Ret1:
--
function PLAYER:Spawn()
    self.Player:AllowFlashlight(true)
    self.Player:SetTeam(1)
end

--
-- Name: PLAYER:Loadout
-- Desc: Called on spawn to give the player their default loadout
-- Arg1:
-- Ret1:
--
function PLAYER:Loadout()
    self.Player:Give("glove"):SetGlove("Normal Glove")
end

function PLAYER:SetModel()
    local cl_playermodel = self.Player:GetInfo("cl_playermodel")
    local modelname = player_manager.TranslatePlayerModel(cl_playermodel)
    util.PrecacheModel(modelname)
    self.Player:SetModel(modelname)
end

function PLAYER:Death(inflictor, attacker)
end

-- Clientside only
-- Setup the player's view
function PLAYER:CalcView(view)
end

-- Creates the user command on the client
function PLAYER:CreateMove(cmd)
end

-- Return true if we should draw the local player
function PLAYER:ShouldDrawLocal()
end

-- Shared
-- Copies from the user command to the move
function PLAYER:StartMove(cmd, mv)
end

-- Runs the move (can run multiple times for the same client)
function PLAYER:Move(mv)
end

-- Copy the results of the move back to the Player
function PLAYER:FinishMove(mv)
end

--
-- Name: PLAYER:ViewModelChanged
-- Desc: Called when the player changes their weapon to another one causing their viewmodel model to change
-- Arg1: Entity|viewmodel|The viewmodel that is changing
-- Arg2: string|old|The old model
-- Arg3: string|new|The new model
-- Ret1:
--
function PLAYER:ViewModelChanged(vm, old, new)
end

--
-- Name: PLAYER:PreDrawViewmodel
-- Desc: Called before the viewmodel is being drawn (clientside)
-- Arg1: Entity|viewmodel|The viewmodel
-- Arg2: Entity|weapon|The weapon
-- Ret1:
--
function PLAYER:PreDrawViewModel(vm, weapon)
end

--
-- Name: PLAYER:PostDrawViewModel
-- Desc: Called after the viewmodel has been drawn (clientside)
-- Arg1: Entity|viewmodel|The viewmodel
-- Arg2: Entity|weapon|The weapon
-- Ret1:
--
function PLAYER:PostDrawViewModel(vm, weapon)
end

--
-- Name: PLAYER:GetHandsModel
-- Desc: Called on player spawn to determine which hand model to use
-- Arg1:
-- Ret1: table|info|A table containing model, skin and body
--
function PLAYER:GetHandsModel()
    -- return { model = "models/weapons/c_arms_cstrike.mdl", skin = 1, body = "0100000" }
    local playermodel = player_manager.TranslateToPlayerModelName(self.Player:GetModel())

    return player_manager.TranslatePlayerHands(playermodel)
end

player_manager.RegisterClass("player_slap", PLAYER, "player_default")

function util.TraceBoundingBox(ply, pos)
    local maxs = Vector(ply:OBBMaxs().X / ply:GetModelScale(), ply:OBBMaxs().Y / ply:GetModelScale(), ply:OBBMaxs().Z / ply:GetModelScale())
    local mins = -maxs
    mins.z = 0
    pos = pos or ply:GetPos()

    return util.TraceHull({
        start = pos,
        endpos = pos,
        maxs = maxs,
        mins = mins,
        collisiongroup = COLLISION_GROUP_PLAYER,
        mask = MASK_PLAYERSOLID,
        filter = function(ent)
            if ent:IsNPC() or ent.Type == "nextbot" then return true end
            if ent:GetClass() == "prop_ragdoll" then return false end
            if ent:GetCollisionGroup() ~= COLLISION_GROUP_WORLD and (ent ~= ply or ent:IsPlayer()) then return true end
            if ent:IsWorld() then return true end

            return true
        end
    })
end

function GetRagdoll(ent)
    return SERVER and ent.Ragdoll or ent:GetNWEntity("Ragdoll", nil)
end