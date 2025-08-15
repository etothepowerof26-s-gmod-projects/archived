AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

include( 'rounds.lua' )

include( 'sv_diffvote.lua' )
AddCSLuaFile( 'cl_diffvote.lua' )

AddCSLuaFile( 'indicator.lua' )

AddCSLuaFile( 'skills.lua' )
include( 'skills.lua' )

resource.AddFile( "materials/daglow.png" )

AddCSLuaFile( 'ulib_integration.lua' )



function GM:PlayerInitialSpawn(ply)
	ply:SetModel("models/player/kleiner.mdl")

	ply:SetVar("NotFullyLoaded", true)
	ply:SetVar("StartLoadTime", SysTime())
end

function GM:PlayerSpawn(ply)
	ply:SetHealth(1)
	ply:SetMaxHealth(1)
	ply:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
end

function GM:PlayerDeathThink(ply)
	ply:Spawn()
	return false
end

function GM:GetFallDamage()
	return 0
end

function GM:IsSpawnpointSuitable()
	return true
end

util.AddNetworkString( "ChatPrintColor" )

---
-- Modified version of
-- https://github.com/yumi-xx/gmod-streamstage/blob/master/gamemodes/stream/gamemode/init.lua#L7
---

function GM:SetupMove(ply, mv, cmd)
	if ply:GetVar("NotFullyLoaded", true) and not cmd:IsForced() then
		ply:SetVar("NotFullyLoaded", false)
		hook.Call("PlayerFullLoad", self, ply, SysTime() - ply:GetVar("StartLoadTime", SysTime()))
		ply:SetVar("StartLoadTime", nil)
	end

	return self.BaseClass.SetupMove(self, ply, mv, cmd)
end
