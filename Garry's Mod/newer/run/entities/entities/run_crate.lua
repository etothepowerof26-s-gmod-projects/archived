AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Type = "anim"

local RADIUS = 200
local TIME = 5

if SERVER then
	util.AddNetworkString( "run_crate_start" )
	function ENT:Initialize()
		self:SetModel("models/Items/item_item_crate.mdl")
		self:SetSolid(SOLID_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetUseType(SIMPLE_USE)
		self:SetCustomCollisionCheck(true)
	end

	function ENT:Use( activator, caller )
		GAMEMODE:CrateStart( activator )
	end

	function GAMEMODE:CrateStart( ply )
		if ( ply.InCrate || ply:GetNWBool( "run_crate_used", false ) ) then return end

		net.Start( "run_crate_start" )
			net.WriteBit( 1 )
		net.Send( ply )

		ply.UsePos = ply:GetPos()
		ply.InCrate = true
		ply:Freeze( true )
		
		local start = SysTime()
		local ident = "run_crate_" .. tostring(ply)
		hook.Add( "Think", ident, function()
			if ( !IsValid(ply) or !ply:Alive() or !ply.InCrate ) then
				hook.Remove( "Think", ident )
				return
			end

			ply:SetPos( ply.UsePos )

			if ( SysTime() > start + TIME ) then
				hook.Remove( "Think", ident )
				self:CrateEnd( ply, true )
				return
			end
		end )
	end

	function GAMEMODE:CrateEnd( ply, fin, silent )
		if ( !IsValid(ply) ) then return end

		net.Start( "run_crate_start" )
			net.WriteBit( 0 )
		net.Send( ply )

		ply.InCrate = nil
		ply.UsePos = nil
		ply:Freeze( false )

		ply:SetNWBool( "run_crate_used", true )

		if ( !fin ) then
			if ( !silent ) then
				ply:ChatPrintColor( team.GetColor(0), "Stopped supply crate pickup." )
			end
			return ply:SetNWBool( "run_crate_used", false )
		end
		
		ply:PS2_AddStandardPoints( 250, "supply crate pickup", false )

		ply:ChatPrintColor( Color(255, 0, 0), "You picked up the supply crate, but at what cost?" )

		for i = 1, math.random(1, 3) do
			self:CreateRunners(ply)
		end
	end

	net.Receive( "run_crate_start", function( len, ply )
		if ( !ply.InCrate ) then return end
		local release = ( net.ReadBit() == 1 )
		if ( release ) then
			GAMEMODE:CrateEnd( ply )
		end
	end )

	hook.Add( "PlayerDeath", "run_crate", function( vic )
		-- remove the crate hook just in case
		if ( !vic.InCrate ) then return end

		local ident = "run_crate_" .. tostring( vic )
		hook.Remove( "Think", ident )
		GAMEMODE:CrateEnd( vic )
	end )

else
	local c = Color(255, 208, 0, 60)
	local star = Material"icon16/star.png"
	
	function ENT:Draw()
		if ( LocalPlayer():GetNWBool( "run_crate_used", false ) ) then return end 

		self:DrawModel()

		local a = math.abs( math.sin( CurTime() ) )
		c.a = 60 * a
		render.SetColorMaterial()
		render.DrawSphere( self:GetPos(), -RADIUS, 50, 50, c )


		if ( !GAMEMODE.SupplyCrate ) then
			GAMEMODE.SupplyCrate = self
		end
	end

	hook.Add( "HUDPaint", "run_crate", function()
		if ( GAMEMODE.SupplyCrate && IsValid( GAMEMODE.SupplyCrate ) ) then
			local pos = ( GAMEMODE.SupplyCrate:GetPos() + Vector( 0, 0, GAMEMODE.SupplyCrate:OBBCenter().z ) ):ToScreen()
			if ( !pos.visible ) then return end

			surface.SetMaterial( star )
			surface.SetDrawColor( 255, 255, 255, 255 )
			surface.DrawTexturedRect( pos.x-8, pos.y-8, 16, 16 )
		else
			if ( !IsValid( GAMEMODE.SupplyCrate ) ) then
				GAMEMODE.SupplyCrate = nil
			end
		end
	end )

	net.Receive( "run_crate_start", function()
		local isrunning = ( net.ReadBit() == 1 )
		if ( isrunning ) then
			local bar_width = 300
			local bar_height = 10
			local margin = 1
			local x, y = ScrW() / 2 - bar_width / 2, ScrH() / 2 - bar_height / 2
			local start = SysTime()
			hook.Add( "HUDPaint", "run_crate_display", function()
				surface.SetDrawColor( 0, 0, 0, 255 )
				surface.DrawRect( x, y, bar_width, bar_height )
				surface.SetDrawColor( 0, 255, 0, 255 )
				local perc = ( SysTime() - start ) / TIME
				surface.DrawRect( x+margin, y+margin, ( bar_width-margin*2 ) * perc, bar_height-margin*2 )

				surface.SetFont("TargetID")
				local txt = "Opening supply package..."
				local tw, th = surface.GetTextSize( txt )
				surface.SetTextPos( ScrW() / 2 - tw / 2, ScrH() / 2 - bar_height - th/2 - 3 )
				surface.SetTextColor( 255, 255, 255, 255 )
				surface.DrawText(txt)

				txt = "(Left Click to release)"
				tw, th = surface.GetTextSize( txt )
				surface.SetTextPos( ScrW() / 2 - tw / 2, ScrH() / 2 - bar_height + th/2 + 3 )
				surface.DrawText(txt)
			
				if ( input.IsMouseDown( MOUSE_LEFT ) ) then
					net.Start( "run_crate_start" )
						net.WriteBit( 1 )
					net.SendToServer()
					hook.Remove( "HUDPaint", "run_crate_display" )
					return
				end
			end )
		else
			hook.Remove( "HUDPaint", "run_crate_display" )
			GAMEMODE.SupplyCrate = nil
		end
	end )
end

function GAMEMODE:ShouldCollide( ent1, ent2 )
	if ( ent2:GetClass() == "run_crate" || ent1:GetClass() == "run_crate" ) then
		local ply = ( ent2:GetClass() == "run_crate" and ent1 or ent2 )
		if ( ply:IsPlayer() && ply:GetNWBool( "run_crate_used", false ) ) then
			return false
		end
	end
	return true
end