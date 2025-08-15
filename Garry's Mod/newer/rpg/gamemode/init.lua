AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua") 


function GM:PlayerInitialSpawn(ply)
	ply:SetModel("models/player/kleiner.mdl")
end

local function resp()

	local e = ents.Create"rpg_base_enemy"
	e:Spawn()
	GAMEMODE:RollModifiers(e, true)

end

function GM:InitPostEntity()

	resp()

end

function GM:PlayerLoadout(ply)

	local w = ply:Give("weapon_smg1")
	ply:GiveAmmo(1000, w:GetPrimaryAmmoType(), true)

end

function GM:PlayerSay(sender, text, team)
	
	resp()
	return text

end