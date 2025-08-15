AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("sh_indicators.lua")
AddCSLuaFile("sh_actions.lua")
include("shared.lua")
include("sh_indicators.lua")
include("sh_actions.lua")

-- Server
module("gmodrts", package.seeall)

-- Gamemode file specific network receivers
util.AddNetworkString("grts_teammenu")
util.AddNetworkString("grts_teamupdate")
util.AddNetworkString("grts_selectteam")

local pmeta = FindMetaTable("Player")

MaxPlayers = CreateConVar("grts_max_team_players", "3", FCVAR_ARCHIVE)
StartInterval = CreateConVar("grts_game_start_interval", "20", FCVAR_ARCHIVE)

-- TODO: Playermodels


-- Prevent anyone from picking up the weapons the NPCs are carrying.
hook.Add("PlayerCanPickupWeapon", "gmodrts", function(ply, wep)
	local parent = wep:GetParent()
	if IsValid(parent)
	and parent:GetClass():find("grts_") then
		return false	
	end
end)