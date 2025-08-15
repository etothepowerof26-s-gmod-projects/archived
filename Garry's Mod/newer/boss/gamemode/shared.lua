GM.Name = "Boss Battles"
GM.Author = ""
GM.Email = ""
GM.Website = ""

DeriveGamemode("base")
AddCSLuaFile("player_class/player_boss.lua")
include("player_class/player_boss.lua")

function GM:Initialize()
	self.BaseClass.Initialize(self)
end