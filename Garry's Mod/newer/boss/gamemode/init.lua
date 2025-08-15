AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_healthbar.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("sh_rune_modifiers.lua")
include("sv_boss.lua")
include("sh_rune_modifiers.lua")
include("shared.lua")

util.AddNetworkString('boss.SendSound')

function GM:PlayerInitialSpawn(player)
	player_manager.SetPlayerClass(player, "player_boss")
	player_manager.RunClass(player, "SetModel")
	player_manager.RunClass(player, "SetupDataTables")
end

function GM:PlayerLoadout() end

concommand.Add("h",function()
	local e=ents.Create"boss_test"
	e:SetPos(Vector(0,0,1000))
	e:Spawn()
end)