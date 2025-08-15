AddCSLuaFile()

local PLAYER = {}

PLAYER.DisplayName			= "Player"
PLAYER.WalkSpeed			= 300		-- How fast to move when not running
PLAYER.RunSpeed				= 450		-- How fast to move when running
PLAYER.CrouchedWalkSpeed	= 0.3		-- Multiply move speed by this when crouching
PLAYER.DuckSpeed			= 0.3		-- How fast to go from not ducking, to ducking
PLAYER.UnDuckSpeed			= 0.3		-- How fast to go from ducking, to not ducking
PLAYER.JumpPower			= 200		-- How powerful our jump should be
PLAYER.CanUseFlashlight		= true		-- Can we use the flashlight
PLAYER.MaxHealth			= 100		-- Max health we can have
PLAYER.StartHealth			= 100		-- How much health we start with
PLAYER.StartArmor			= 0			-- How much armour we start with
PLAYER.DropWeaponOnDie		= false		-- Do we drop our weapon when we die
PLAYER.TeammateNoCollide	= true		-- Do we collide with teammates or run straight through them
PLAYER.AvoidPlayers			= true		-- Automatically swerves around other players
PLAYER.UseVMHands			= true		-- Uses viewmodel hands

function PLAYER:SetupDataTables()
	self.Player:NetworkVar("Int", 0, "Mana")
	self.Player:NetworkVar("Int", 1, "Level")
	self.Player:NetworkVar("Float", 0, "Cash")
	self.Player:NetworkVar("Float", 1, "Experience")
end
function PLAYER:Init() end
function PLAYER:Spawn()
	self:Loadout()
end
function PLAYER:Loadout()
	self.Player:Give("weapon_bbattles_glock")
	self.Player:Give("weapon_bbattles_m16")
	self.Player:Give("weapon_bbattles_m249")
	self.Player:GiveAmmo(9999, "Pistol", true)
end

player_manager.RegisterClass("player_boss", PLAYER, "player_default")