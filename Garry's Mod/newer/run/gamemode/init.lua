AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )
include( 'ulx_commands.lua' )

resource.AddWorkshop( 2798330829 )

local fs = "+%s EXPERIENCE: "
local col_green = Color( 0, 255, 0, 255 )
local col_white = color_white
local col_red = Color( 255, 0, 0, 255 )
local function Give( vic, exp, typ )
	if ( not vic or not IsValid(vic) ) then
		return
	end

	if not typ then
		exp = math.floor( ( SysTime() - vic.AliveTime ) / 2 )
		if exp == 0 then return end 
		typ = {col_green, string.format( fs, tostring(exp) ),
				col_white, "Living for ",
				tostring( math.Round( SysTime() - vic.AliveTime, 1 ) ), " seconds!"}
	else
		if exp < 1 then
			typ = { col_red, string.format( '-%s EXPERIENCE: ', tostring(exp) ), col_white, typ }
		else
			typ = { col_green, string.format( fs, tostring(exp) ), col_white, typ }
		end
	end

	if ( vic and vic.ChatPrintColor ) then
		vic:ChatPrintColor( unpack( typ ) )
	end

	hook.Run( "xpsys_xpupdate", vic, exp, 1 )
	timer.Simple( 0, function()
		if ( !IsValid(vic) ) then return end
		vic:UpdateExp()
	end )
end

function GM:PlayerInitialSpawn( ply )
	ply:SetModel "models/player/charple.mdl"
	timer.Create( tostring(ply) .. "s", 60, 0, function()
		if ( !IsValid(ply) ) then return end
		Give( ply, 5 * math.random( 5, 9 ), "Playtime bonus!" )
	end )
	if ( ply:GetPData( "deaths", -1 ) == -1 ) then
		ply:SetPData( "deaths", 0 )
	else
		ply:SetDeaths( tonumber( ply:GetPData( 'deaths', 0 ) ) )
	end
end

util.AddNetworkString("run_clear_fog")
function GM:PlayerSpawn( ply )
	ply:SetCollisionGroup( COLLISION_GROUP_PASSABLE_DOOR )
	ply:SetCustomCollisionCheck( true )
	ply.AliveTime = SysTime()
	self:CreateRunners( ply )
	ply:ConCommand( "stopsound" )
	ply:SetActiveWeapon( ply:Give( 'parkourmod' ) )
	ply:SetupHands() 
	local hat = ply:PS2_GetItemInSlot("Hat")
	
	if (hat and hat.itempersistence_id == "59") then
		net.Start("run_clear_fog")
		net.Send(ply)
	end
	local i = 0
	timer.Create( tostring(ply), 1, 0, function()
		if ( !IsValid(ply) ) then return end
		
		if ( !ply.Runners ) then
			ply.Runners = {}
		end
		i = i + 1
		if ( i % ( 30 / ( math.min( #ply.Runners, 2 ) ) ) == 0 ) then
			self:CreateRunners( ply )
			Give( vic, 5 * #ply.Runners, "Running for your life!" )
		elseif ( i % 3 == 0 ) then
		
		else
			if ( ( !ply:HasWeapon( "parkourmod" ) || !IsValid( ply:GetActiveWeapon() ) ) && !ply:HasWeapon("run_plasmanet") ) then
				ply:SetActiveWeapon( ply:Give( "parkourmod" ) )
			
			end
		end
	end )
	if ( xpsys ) then
		ply:UpdateExp()
	end
	timer.Create( tostring(ply) .. "p", 90, 10, function()
		if ( !IsValid(ply) or !ply:Alive() ) then return end
		self:GivePlayerPlasmaNet( ply )
	end )
	if ( ply:GetPData( "exited", "nil" ) != "nil" ) then
		local cur = os.time() - tonumber( ply:GetPData( "exited", os.time() ) )
		local deaths = cur / 600 -- 10 minutes of afk gives deaths
		if ( math.floor( deaths ) > 0 ) then
			ply:ChatPrintColor(
				Color( 255, 115, 0), "[WARNING]",
				color_white, " Due to being offline for over 10 minutes, you have received ",
				team.GetColor(0), tostring( math.floor( deaths ) ), color_white, " deaths added to the counter."
			)
			ply:SetDeaths( ply:Deaths() + math.floor( deaths ) )
		end
		ply:SetPData( "exited", nil )
	end
end

function GM:PlayerLoadout( ply )
	ply:SetActiveWeapon( ply:Give( 'parkourmod' ) )
	return true 
end

local runners = {
	"npc_doge", "npc_obamid", "npc_obunga", "npc_pedobear", "npc_quandale", "npc_uncle", "npc_walter",
	"npc_miyamoto", "npc_trunga"--, "npc_putunga", "npc_kimjongunga",
}
local runners_names = {
	["npc_doge"] = "Giant Doge",
	["npc_obamid"] = "Obama Prism",
	["npc_obunga"] = "OBUNGA",
	["npc_pedobear"] = "Pedo Bear",
	["npc_quandale"] = "Quandale Dingle",
	["npc_uncle"] = "Quandale's Goofy Ahh Uncle",
	["npc_walter"] = "Walter",

	["npc_miyamoto"] = "Shigeru Miyamoto",
	["npc_trunga"] = "Donald TRUNGA",
	["npc_putunga"] = "Vladmir PUTUNGA",
	["npc_kimjongunga"] = "Kim JUNGA",

}
local col_grey = Color(80, 80, 80)
function GM:CreateRunners( ply )
	if ply.stopped then return end

	if not ply.Runners then
		ply.Runners = { }
	end
	local runner = runners[ math.random( 1, #runners ) ]
	local e = ents.Create( runner )
	if ( not IsValid(e) ) then
		ply:ChatPrint( "Failed to create runner for you. Report this (" .. runner .. ")" )
		return
	end
	e:Spawn()
	e.RUNForceTarget = ply
	e.loco:SetDesiredSpeed( 550 )

	local n = navmesh.GetNearestNavArea( ply:GetPos() + VectorRand() * 8000, false, 10000, false, true, 0 )
	if ( n ) then
		e:SetPos( n:GetRandomPoint() )
	else
		print( string.format( "%s has no available spawnpoint, sending it to Vector(0, 0, 0)", tostring(e) ) )
	end
	ply.Runners[ #ply.Runners + 1 ] = e
	if ( #ply.Runners == 1 ) then
		ply:ChatPrintColor(
			col_red, "!!! ",
			color_white, "You are being chased by: ",
			HSVToColor( math.random( 0, 360 ), 1, 1 ), ( runners_names[ runner ] or "???" ),
			col_red, " !!!"
		)
	else
		ply:ChatPrintColor(
			col_red, "!!! ",
			color_white, "You are being chased by: ",
			HSVToColor( math.random( 0, 360 ), 1, 1 ), ( runners_names[ runner ] or "???" ),
			col_grey, " (", tostring(#ply.Runners), ")",
			col_red, " !!!"
		)
	end
	print( string.format( "Added new runner to %s (%s): %s", ply:Name() .. "[" .. ply:SteamID() .. "]", #ply.Runners, runner ) )
	timer.Adjust( tostring( ply ), 60 / ( math.min( #ply.Runners, 6 ) ) )
end

function GM:ClearRunners( ply )
	if ( ply.Runners and next(ply.Runners) != nil ) then
		for k,v in pairs(ply.Runners) do
			if (IsValid(v)) then
				v:Remove()
			end
		end
		ply.Runners = nil
		print( "Cleared " .. tostring(ply) .. "'s runners" )
	end
end

function GM:PlayerDisconnected( ply )
	ply:SetPData( "exited", os.time() )
	self:ClearRunners( ply )
	timer.Remove( tostring(ply) )
	timer.Remove( tostring(ply) .. "s" )
	timer.Remove( tostring(ply) .. "p" )
end

function GM:IsSpawnpointSuitable( ply, spawn, suit )
	return true
end

function GM:PlayerDeath( vic, inf, atk )
	if ( inf:GetClass():find("^npc_") && ( inf.RUNForceTarget != vic ) ) then
		local dur = math.floor( ( SysTime() - vic.AliveTime ) / 2 ) + 1
		Give( inf.RUNForceTarget, dur, "Killing someone else with your runner" )
	end
	timer.Remove( tostring(vic) )
	timer.Remove( tostring(vic) .. "p" )
	self:ClearRunners( vic )
	vic:ConCommand( "stopsound" )
	vic:SetPData( "deaths", vic:Deaths() )
	vic.HasNet = false
	if ( xpsys ) then
		Give( vic, nil, nil )
	end
end

function GM:PlayerSay( ply, txt )
	if ( txt != "force" ) then return txt end
	self:CreateRunners( ply )
end

function GM:PlayerDeathThink( ply )
	if ( ply.DEAD == false ) then
		ply.DEAD = SysTime()
	end
	if ( ply:KeyPressed( IN_ATTACK ) || ply:KeyPressed( IN_ATTACK2 ) || ply:KeyPressed( IN_JUMP ) ) then
		ply:Spawn()
		ply.DEAD = false
	end
	if ( ply.DEAD && SysTime() > ( ply.DEAD or 0 ) + 120 && !ply:IsAdmin() ) then
		ply:Kick( "You spent 2 minutes dead. I will kick you to keep player space and to prevent farming of experience" )
		return
	end
	return false
end

function GM:PlayerShouldTakeDamage( ply, atk )
	if ( ply:GetClass() == "player" and atk:GetClass() == "player" ) then
		return false
	end
	return true
end

function GM:PlayerSetHandsModel( ply, ent )
	local simplemodel = player_manager.TranslateToPlayerModelName( ply:GetModel() )
	local info = player_manager.TranslatePlayerHands( simplemodel )
	if ( info ) then
		ent:SetModel( info.model )
		ent:SetSkin( info.skin )
		ent:SetBodyGroups( info.body )
	end
end

GM.lastCleanup = SysTime()
GM.lastSupplyCrate = SysTime()
local time = math.random( 160, 240 )
function GM:Think()
	if ( SysTime() > self.lastCleanup + 15 ) then
		for k,v in pairs( ents.FindByClass( "prop_physics" ) ) do
			if v.PlasmaNet then
				v:Remove()
				continue 
			end
		end
		self.lastCleanup = SysTime()
	end
	if ( SysTime() > self.lastSupplyCrate + time ) then
		if ( self.SupplyCrate && IsValid( self.SupplyCrate ) ) then
			self.SupplyCrate:Remove()
			self:ClearSupplyStatus()
		end

	
		self.lastSupplyCrate = SysTime()
		time = math.random( 160, 240 )

		timer.Simple( 0.1, function()
			self.SupplyCrate = ents.Create( "run_crate" )
			if ( !self.SupplyCrate || !IsValid( self.SupplyCrate ) ) then
				print( "Supply crate failed to spawn." )
				return
			end

			local plys = player.GetAll()
			local rply = plys[ math.random( 1, #plys ) ]
			if ( !rply || !IsValid(rply) ) then return end
			
			-- todo: create spawn positions as crates cannot get out of stuck spots, unlike npcs
			local n = navmesh.GetNearestNavArea( rply:GetPos() + VectorRand() * 2000, false, 10000, false, true, 0 )
			if ( n ) then
				self.SupplyCrate:SetPos( n:GetRandomPoint() )
				self.SupplyCrate:Spawn()
				self:ChatPrintColor( Color( 120, 120, 120 ), "A supply crate has spawned on the map." )
			else
				print( string.format( "%s has no available spawnpoint, deleting it", "Supply Crate" ) )
				self.SupplyCrate:Remove()
				return
			end
		end )
	end 
end

function GM:ClearSupplyStatus()
	for k,v in pairs( player.GetAll() ) do
		self:CrateEnd( v, false, true )
		v:SetNWBool( "run_crate_used", false )
	end
end

function GM:PlayerCanPickupWeapon( ply, weapon )
	if ( weapon:GetClass():find("^run_") && ply:HasWeapon( weapon:GetClass() ) ) then
		ply:StripWeapon( weapon:GetClass() )
	end
	return true
end
 


local ws = 250
local rws = 350
function GM:GivePlayerPlasmaNet( ply )
	if ( !IsValid(ply) or !ply:Alive() ) then return end
	ply.HasNet = true
	ply:StripWeapons()
	ply:SetWalkSpeed( rws * 1.5 )
	ply:SetRunSpeed( rws * 1.5 )
	ply:Give( "run_plasmanet" )
	ply:SelectWeapon( "run_plasmanet" )

	ply:ChatPrintColor( Color( 0, 127, 255 ), "You were given a one time use Plasma Net!" )
	ply:ChatPrintColor( Color( 0, 127, 255 ), "Use this opportunity as a saving grace." )
end
function GM:StopPlasma( ply )
	ply:SetWalkSpeed( ws ) 
	ply:SetRunSpeed( ws )
	ply:SetActiveWeapon( ply:Give( "parkourmod" ) )
	ply.HasNet = nil
end -- ambient/energy/weld2.wav
concommand.Add( "run_debug_plasmanet", function( ply )
	GAMEMODE:GivePlayerPlasmaNet( ply )
end )

function GM:PlayerCanPickupWeapon( ply, wep )
	return true
end