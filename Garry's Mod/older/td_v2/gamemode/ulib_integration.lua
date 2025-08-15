

if ( !ulx or !ULib ) then
	ErrorNoHalt( "[td] ULX integration isn't possible. ULX based chat commands wont work!\n" )
end


local CAT = "GMOD Tower Defense"


function GM.ULX_HealServer( call, amnt )
	SetGlobalInt( "td_lives", GetGlobalInt( "td_lives", 0 ) + amnt )
	ulx.fancyLogAdmin( call, "#A healed the server for #i lives", amnt )
end
local heal = ulx.command( CAT, "ulx healserv", GM.ULX_HealServer, "!healserv", true )
heal:addParam{ type=ULib.cmds.NumArg, hint="Lives to add", min=1, max=999999 }
heal:defaultAccess( ULib.ACCESS_ADMIN )
heal:help( "Adds lives the server." )


function GM.ULX_Summon( call, class )
	local e = ents.Create( class )
	e:Spawn()
	e:SetPos( GAMEMODE.Waypoints["_1"].pos )
	e:UpdateCurrentWaypointInformation()

	ulx.fancyLogAdmin( call, "#A summoned a " .. class  )
end
local heal = ulx.command( CAT, "ulx summon", GM.ULX_Summon, "!summon", true )
heal:addParam{ type=ULib.cmds.StringArg, hint="Enemy Classname" }
heal:defaultAccess( ULib.ACCESS_ADMIN )
heal:help( "Summons an enemy." )


function GM.ULX_OpenPalette( call, class )
	concommand.Run( call, "td_open_palette" )
end
local pal = ulx.command( CAT, "ulx palette", GM.ULX_OpenPalette, { "!palette", "!pal", "!p" }, true )
pal:defaultAccess( ULib.ACCESS_ALL )
pal:help( "Opens the Skill Palette menu." )


function GM.ULX_Donate( call, targ, amnt )
	if (#targ > 1) then
		ULib.tsayError( call, "[td] You can only donate to one person.", true )
		return 
	end
	ulx.fancyLogAdmin( call, "#A donated $#i to #T", amnt, targ )
end
local donate = ulx.command( CAT, "ulx donate", GM.ULX_Donate, { '!donate', '!don' } )
donate:addParam{ type=ULib.cmds.PlayersArg }
donate:addParam{ type=ULib.cmds.NumArg, min=0, max=10000, default=100, hint="Money", ULib.cmds.round }
donate:defaultAccess( ULib.ACCESS_ALL )
donate:help( "Donates money to people." )