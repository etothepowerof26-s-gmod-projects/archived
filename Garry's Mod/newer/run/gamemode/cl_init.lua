include( "shared.lua" )

function GM:SetupWorldFog( scale )
	render.FogStart( 600 )

	render.FogEnd( 1200 )
	render.FogColor( 60, 60, 60 )
	render.FogMaxDensity( 1 )
	render.FogMode( MATERIAL_FOG_LINEAR )

	return true
end

local huds = {
	
	["CHudHealth"] = true,
	["CHudBattery"] = true,
	["CHudAmmo"] = true,
	["CHudWeaponSelection"] = true

}
function GM:HUDShouldDraw( name )
	if huds[name] then return false end 
	return true
end

local lerp = 0
local str = "$pp_colour_"
local delay = 3000
local start = SysTime()

local tab = {
	[ str.."addr" ] = 0,
	[ str.."addg" ] = 0,
	[ str.."addb" ] = 0,
	[ str.."brightness" ] = 0,
	[ str.."contrast" ] = .9,
	[ str.."colour" ] = 0.1,
	[ str.."mulr" ] = 0.5,
	[ str.."mulg" ] = 0.5,
	[ str.."mulb" ] = 0.5
}

hook.Add( "RenderScreenspaceEffects", "LightningEffect", function( )
	DrawColorModify( tab )
	tab[ "$pp_colour_colour" ] = lerp
end )

net.Receive("run_clear_fog", function()

	chat.AddText("Your fog has been cleared.")
	hook.Remove("RenderScreenspaceEffects", "LightningEffect")
	function GAMEMODE:SetupWorldFog()
		return
	end


end)

local old_va
local LookLerp
local new_va_offset = Angle()
local function doview()
	return input.IsMouseDown( MOUSE_RIGHT )
end
hook.Add( "CalcView", "LookRust", function( ply, origin, angles, fov, zn, zf )
	local view = {}

	view.origin = origin
	view.angles = angles
	view.fov = 90
	view.drawviewer = false

	if ( doview() ) then
		if ( !LookLerp ) then
			LookLerp = 0
			new_va_offset = Angle()
		end
		LookLerp = Lerp( FrameTime() * 15, LookLerp, 80 )
		view.drawviewer = true
		local oo = view.origin  
		local no = oo  - ( angles - new_va_offset ):Forward() * LookLerp  
		local tr = util.TraceLine( {
			start = oo,
			endpos = no,
			filter = function( ent )
				if ( ent:EntIndex() == LocalPlayer():EntIndex() ) then
					return false
				end
				return true
			end
		} ).HitPos
		view.origin = tr
		view.angles = ( oo - view.origin ):Angle()
	end
	
	return view
end )

hook.Add( "InputMouseApply", "LookRust", function( cmd, x, y, angle )
	if ( doview() && LocalPlayer():Alive() ) then
		if ( !old_va ) then
			old_va = cmd:GetViewAngles()
		end
		if ( old_va ) then
			cmd:SetViewAngles( old_va )
			new_va_offset.y = math.Clamp( new_va_offset.y + x / 85, -150, 150)
			new_va_offset.p = math.Clamp( new_va_offset.p + -y / 85, -80, 80)
		end
		return true
		
	else
		old_va = nil
		LookLerp = nil
	end
end )